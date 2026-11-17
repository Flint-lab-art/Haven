<script setup lang="ts">
/**
 * 账单导入：把银行/支付平台导出的 CSV 批量写进记账。
 *
 * 设计取舍：
 * - **不做文件上传**，纯前端解析后调现成的 `/api/ledger/entries/batch`。
 *   导入是一次性需求，没必要为它加一个后端上传端点与存储。
 * - **导入前必须预览**：账单里常混着提现、转账、退款、交易关闭，
 *   直接写入会污染统计，所以先让用户看清「要写多少、共多少钱」。
 * - **按批号幂等**：batch_id 由文件内容哈希得出，同一个文件重复导入不会翻倍。
 */
import { computed, ref } from 'vue'
import { createLedgerBatch, type CreateLedgerEntryInput, type LedgerCategory } from '@/api/ledger'
import { LEDGER_CATEGORIES } from '@/utils/ledger'

/** 解析出来的一行，字段与导出的 CSV 一致。 */
interface BillRow {
  date: string
  time: string
  type: string
  amount: string
  peer: string
  desc: string
  status: string
  source: string
  tradeNo: string
  category: string
}

interface ParsedRow extends BillRow {
  /** 是否会被导入。 */
  keep: boolean
  /** 不能导入的原因。 */
  reason: string
  /** 分类是否被用户改过（改过的不会被重新推断覆盖）。 */
  edited?: boolean
}

const fileInput = ref<HTMLInputElement | null>(null)
const fileName = ref('')
const rows = ref<ParsedRow[]>([])
const parseError = ref('')
const importing = ref(false)
const importResult = ref('')

const keptRows = computed(() => rows.value.filter((r) => r.keep))
const droppedCount = computed(() => rows.value.length - keptRows.value.length)

const totals = computed(() => {
  let expense = 0
  let income = 0
  for (const r of keptRows.value) {
    const cents = Math.round(Number(r.amount) * 100)
    if (r.type === '收入') income += cents
    else expense += cents
  }
  return { expense, income }
})

function yuan(cents: number): string {
  return `¥${(cents / 100).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
}

/**
 * 极简 CSV 解析：支持双引号包裹与转义双引号。
 *
 * 不引第三方库：账单文件的格式很简单，为一次性功能增加依赖不划算。
 */
function parseCsv(text: string): string[][] {
  const out: string[][] = []
  let row: string[] = []
  let field = ''
  let quoted = false

  // 去掉 BOM
  const src = text.replace(/^\uFEFF/, '')

  for (let i = 0; i < src.length; i++) {
    const ch = src[i]
    if (quoted) {
      if (ch === '"') {
        if (src[i + 1] === '"') {
          field += '"'
          i++
        } else {
          quoted = false
        }
      } else {
        field += ch
      }
    } else if (ch === '"') {
      quoted = true
    } else if (ch === ',') {
      row.push(field)
      field = ''
    } else if (ch === '\n') {
      row.push(field)
      out.push(row)
      row = []
      field = ''
    } else if (ch !== '\r') {
      field += ch
    }
  }
  if (field || row.length) {
    row.push(field)
    out.push(row)
  }
  return out.filter((r) => r.some((c) => c.trim() !== ''))
}

/** 判断这一行为什么不能导入。返回空串表示可以导入。 */
function rejectReason(row: BillRow): string {
  const amount = Number(row.amount)
  if (!Number.isFinite(amount) || amount <= 0) return '金额为 0 或无效'
  if (row.type !== '支出' && row.type !== '收入') return `类型为「${row.type || '空'}」`
  if (/关闭|解冻|失败/.test(row.status)) return `交易未成交（${row.status}）`
  return ''
}

async function onFile(event: Event): Promise<void> {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return
  parseError.value = ''
  importResult.value = ''
  fileName.value = file.name

  try {
    const text = await file.text()
    const table = parseCsv(text)
    if (table.length < 2) {
      parseError.value = '文件没有数据行'
      return
    }

    const header = table[0].map((h) => h.trim())
    const need = ['日期', '类型', '金额', '对方', '建议分类']
    const missing = need.filter((h) => !header.includes(h))
    if (missing.length) {
      parseError.value = `缺少列：${missing.join('、')}。请使用「账单汇总」的导出格式。`
      return
    }

    const idx = (name: string) => header.indexOf(name)
    rows.value = table.slice(1).map((cells) => {
      const pick = (name: string) => (cells[idx(name)] ?? '').trim()
      const base: BillRow = {
        date: pick('日期'),
        time: pick('时间'),
        type: pick('类型'),
        amount: pick('金额'),
        peer: pick('对方'),
        desc: pick('商品说明'),
        status: pick('状态'),
        source: pick('来源'),
        tradeNo: pick('交易单号'),
        category: pick('建议分类'),
      }
      const reason = rejectReason(base)
      return { ...base, keep: reason === '', reason }
    })
  } catch (err) {
    parseError.value = err instanceof Error ? err.message : '解析失败'
  }
}

/** 改分类：只允许账本里已存在的分类。 */
function setCategory(row: ParsedRow, value: string): void {
  row.category = value
  row.edited = true
}

/** 文件内容哈希作为 batch_id：同一个文件重复导入不会翻倍。 */
async function batchId(): Promise<string> {
  const payload = keptRows.value
    .map((r) => `${r.tradeNo}|${r.date}|${r.time}|${r.type}|${r.amount}`)
    .join('\n')
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(payload))
  return `import-${[...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('').slice(0, 40)}`
}

async function doImport(): Promise<void> {
  if (!keptRows.value.length || importing.value) return
  importing.value = true
  importResult.value = ''
  try {
    const items: CreateLedgerEntryInput[] = keptRows.value.map((r) => ({
      type: r.type === '收入' ? 'income' : 'expense',
      amount_cents: Math.round(Number(r.amount) * 100),
      category: r.category as LedgerCategory,
      note: [r.peer, r.desc].filter(Boolean).join(' ').slice(0, 120),
      occurred_at: `${r.date}T${r.time || '00:00:00'}+08:00`,
    }))

    const result = await createLedgerBatch({
      batch_id: await batchId(),
      raw_text: `导入 ${fileName.value}`,
      items,
    })
    importResult.value = result.created
      ? `已导入 ${result.total} 笔`
      : `这批数据之前已导入过（${result.total} 笔），未重复写入`
  } catch (err) {
    parseError.value = err instanceof Error ? err.message : '导入失败'
  } finally {
    importing.value = false
  }
}

function reset(): void {
  rows.value = []
  fileName.value = ''
  parseError.value = ''
  importResult.value = ''
  if (fileInput.value) fileInput.value.value = ''
}
</script>

<template>
  <div class="detail-inner">
    <header class="detail-head">
      <h1 class="detail-title">导入账单</h1>
      <p class="detail-sub">从支付平台导出的 CSV 批量写入记账；提现、转账、退款与未成交会自动排除。</p>
    </header>

    <section class="panel panel--pad">
      <div class="row" style="gap: var(--sp-3); align-items: center; flex-wrap: wrap">
        <input
          ref="fileInput"
          type="file"
          accept=".csv,text/csv"
          aria-label="选择账单文件"
          @change="onFile"
        />
        <button v-if="rows.length" class="btn btn--sm" type="button" @click="reset">重新选择</button>
      </div>

      <p v-if="parseError" class="notice notice--error" style="margin-top: var(--sp-3)">{{ parseError }}</p>
      <p v-if="importResult" class="notice notice--success" style="margin-top: var(--sp-3)">
        {{ importResult }}
      </p>

      <template v-if="rows.length">
        <div class="import-summary">
          <div class="ledger-stat">
            <span class="ledger-stat__label">将导入</span>
            <span class="ledger-stat__value">{{ keptRows.length }}</span>
          </div>
          <div class="ledger-stat">
            <span class="ledger-stat__label">排除</span>
            <span class="ledger-stat__value">{{ droppedCount }}</span>
          </div>
          <div class="ledger-stat">
            <span class="ledger-stat__label">支出</span>
            <span class="ledger-stat__value">{{ yuan(totals.expense) }}</span>
          </div>
          <div class="ledger-stat">
            <span class="ledger-stat__label">收入</span>
            <span class="ledger-stat__value ledger-stat__value--income">{{ yuan(totals.income) }}</span>
          </div>
        </div>

        <div class="row" style="justify-content: flex-end; margin-top: var(--sp-4)">
          <button
            class="btn btn--primary"
            type="button"
            :disabled="importing || !keptRows.length"
            @click="doImport"
          >
            {{ importing ? '导入中…' : `导入 ${keptRows.length} 笔` }}
          </button>
        </div>

        <div class="import-table-wrap">
          <table class="import-table">
            <thead>
              <tr>
                <th>日期</th>
                <th>类型</th>
                <th class="num">金额</th>
                <th>对方</th>
                <th>商品说明</th>
                <th>分类</th>
                <th>状态</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(row, i) in rows" :key="`${row.tradeNo}-${i}`" :class="{ 'is-skipped': !row.keep }">
                <td class="nowrap">{{ row.date }}</td>
                <td>{{ row.type }}</td>
                <td class="num">{{ row.amount }}</td>
                <td class="ellipsis" :title="row.peer">{{ row.peer }}</td>
                <td class="ellipsis" :title="row.desc">{{ row.desc || '—' }}</td>
                <td>
                  <select
                    v-if="row.keep"
                    class="select import-table__cat"
                    :value="row.category"
                    :aria-label="`${row.peer} 的分类`"
                    @change="setCategory(row, ($event.target as HTMLSelectElement).value)"
                  >
                    <option v-for="c in LEDGER_CATEGORIES" :key="c" :value="c">{{ c }}</option>
                  </select>
                  <span v-else class="muted">{{ row.reason }}</span>
                </td>
                <td class="muted nowrap">{{ row.status }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
    </section>
  </div>
</template>
