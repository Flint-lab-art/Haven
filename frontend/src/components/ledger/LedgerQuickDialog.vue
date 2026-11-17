<script setup lang="ts">
/**
 * 快速记账弹窗：多行文本 → 解析预览 → 确认写入。
 *
 * 从记账页搬出来，因为「看流水」是高频动作、「记账」是低频动作：
 * 常驻一个大文本框会挤掉真正该被看见的明细。
 *
 * 输入格式与解析规则由后端决定，这里只负责展示结果与错误。
 */
import { computed, ref, watch } from 'vue'
import { quickParse, type QuickParseResult } from '@/api/ledger'
import { categoryTone, formatSignedYuan } from '@/utils/ledger'

const props = defineProps<{
  /** 是否打开。 */
  open: boolean
}>()

const emit = defineEmits<{
  'update:open': [value: boolean]
  /**
   * 用户确认写入。
   * 父组件负责真正的写库（它已经持有 batch id 与刷新逻辑），
   * 写出成功后把 `closed` 回调交给父组件，由父组件决定何时关闭。
   */
  commit: [items: QuickParseResult['items'], done: (ok: boolean) => void]
}>()

const text = ref('')
const parsing = ref(false)
const saving = ref(false)
const result = ref<QuickParseResult | null>(null)
const error = ref('')

const items = computed(() => result.value?.items ?? [])
const errors = computed(() => result.value?.errors ?? [])

/** 每次打开都是干净状态：上次的输入与预览不该带过来。 */
watch(
  () => props.open,
  (open) => {
    if (open) {
      text.value = ''
      result.value = null
      error.value = ''
    }
  },
)

function close(): void {
  if (saving.value) return
  emit('update:open', false)
}

async function parse(): Promise<void> {
  if (!text.value.trim() || parsing.value) return
  parsing.value = true
  error.value = ''
  try {
    result.value = await quickParse(text.value)
  } catch (err) {
    error.value = err instanceof Error ? err.message : '解析失败'
  } finally {
    parsing.value = false
  }
}

function commit(): void {
  if (!items.value.length || saving.value) return
  saving.value = true
  error.value = ''
  emit('commit', items.value, (ok: boolean) => {
    saving.value = false
    if (ok) emit('update:open', false)
  })
}

/** 解析预览里的日期，如「11月16日」。 */
function shortDate(value: string): string {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return `${date.getMonth() + 1}月${date.getDate()}日`
}
</script>

<template>
  <div v-if="open" class="modal-backdrop" role="presentation" @click.self="close">
    <section class="modal ledger-quick-modal" role="dialog" aria-modal="true" aria-label="快速记账">
      <header class="modal__head">
        <div>
          <h2 class="modal__title">快速记一笔</h2>
          <p class="modal__sub">一行一条，回车换行 · ⌘/Ctrl + Enter 解析</p>
        </div>
        <button class="icon-btn" type="button" aria-label="关闭" @click="close">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true">
            <path d="M6 6l12 12M18 6 6 18" />
          </svg>
        </button>
      </header>

      <p class="field__hint">
        [日期] 分类 [备注…] 金额。日期可写 11月16 / 2026-11-16 / 昨天，不写就是今天；
        金额支持 12 / 12.5 / 32元 / ¥32 / 二十五块，工资、奖金等自动判为收入。
      </p>

      <textarea
        v-model="text"
        class="textarea ledger-quick__input"
        placeholder="午饭12&#10;晚饭 20&#10;11月16 午餐 16&#10;昨天 打车 25&#10;工资 8000"
        aria-label="记账输入"
        :disabled="saving"
        @keydown.meta.enter.prevent="parse"
        @keydown.ctrl.enter.prevent="parse"
      ></textarea>

      <p v-if="error" class="notice notice--error">{{ error }}</p>

      <!-- 预览：确认写入前让用户看到「将变成什么样」 -->
      <div v-if="result" class="ledger-parse" aria-live="polite">
        <div v-for="item in items" :key="item.line" class="ledger-parse__row">
          <span class="ledger-parse__date">{{ shortDate(item.occurred_at) }}</span>
          <span class="ledger-cat" :class="`ledger-cat--${categoryTone(item.category)}`">
            {{ item.category }}
          </span>
          <span class="ledger-parse__note">{{ item.note || '（无备注）' }}</span>
          <span class="ledger-parse__amount" :class="{ 'is-income': item.type === 'income' }">
            {{ formatSignedYuan(item.type, item.amount_cents) }}
          </span>
        </div>
        <ul v-if="errors.length" class="ledger-parse__errors">
          <li v-for="err in errors" :key="err.line">
            第 {{ err.line }} 行：{{ err.message }}
            <span v-if="err.raw" class="muted">（{{ err.raw }}）</span>
          </li>
        </ul>
        <p v-if="!items.length && !errors.length" class="ledger-muted">没有可写入的内容。</p>
      </div>

      <div class="modal__actions">
        <button class="btn" type="button" :disabled="saving" @click="close">取消</button>
        <button class="btn" type="button" :disabled="parsing || !text.trim() || saving" @click="parse">
          {{ parsing ? '解析中…' : '解析预览' }}
        </button>
        <button
          v-if="items.length"
          class="btn btn--primary"
          type="button"
          :disabled="saving"
          @click="commit"
        >
          {{ saving ? '写入中…' : `确认写入 ${items.length} 笔` }}
        </button>
      </div>
    </section>
  </div>
</template>
