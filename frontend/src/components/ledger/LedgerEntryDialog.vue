<script setup lang="ts">
/**
 * 记账录入 / 编辑对话框（PC 与移动端共用）。
 *
 * 按类型切换字段：
 * - 支出 / 收入：分类 + 账户
 * - 转账：转出账户 + 转入账户，无分类
 */
import { computed, ref, watch } from 'vue'
import {
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogOverlay,
  DialogPortal,
  DialogRoot,
  DialogTitle,
} from 'reka-ui'
import CategoryPicker from './CategoryPicker.vue'
import { ApiError } from '@/api/client'
import { createEntry, updateEntry, type Account, type Category, type EntryType, type LedgerEntry } from '@/api/ledger'
import { accountTypeLabel, fromLocalDateTimeInput, parseYuanToCents, toLocalDateTimeInput } from '@/utils/ledger'
import { X } from 'lucide-vue-next'


const props = defineProps<{
  /** 为 null 表示新建。 */
  entry: LedgerEntry | null
  accounts: Account[]
  categories: Category[]
}>()

const emit = defineEmits<{
  close: []
  saved: []
  /** 编辑已有流水时请求删除。 */
  delete: []
}>()

const type = ref<EntryType>(props.entry?.type ?? 'expense')
const amountInput = ref(props.entry ? String(props.entry.amount_cents / 100) : '')
const categoryId = ref<number | null>(props.entry?.category_id ?? null)
const accountId = ref<string | null>(props.entry?.account_id ?? null)
const toAccountId = ref<string | null>(props.entry?.to_account_id ?? null)
const note = ref(props.entry?.note ?? '')
const occurredAt = ref(toLocalDateTimeInput(props.entry?.occurred_at ?? new Date()))

const busy = ref(false)
const error = ref('')

/** 未归档账户；编辑时若原账户已归档，也要能选中。 */
const activeAccounts = computed(() => {
  const list = props.accounts.filter((a) => !a.archived)
  const current = props.entry?.account_id
  const archived = props.accounts.find((a) => a.id === current && a.archived)
  return archived ? [...list, archived] : list
})

const isTransfer = computed(() => type.value === 'transfer')

watch(type, (next) => {
  if (next === 'transfer') {
    categoryId.value = null
    if (!toAccountId.value) toAccountId.value = null
  } else if (accountId.value && toAccountId.value) {
    toAccountId.value = null
  }
})

function validate(): string {
  if (!parseYuanToCents(amountInput.value)) return '金额格式不对'
  if (isTransfer.value) {
    if (!accountId.value) return '请选择转出账户'
    if (!toAccountId.value) return '请选择转入账户'
    if (accountId.value === toAccountId.value) return '转出与转入不能是同一个账户'
  } else {
    if (categoryId.value == null) return '请选择分类'
    if (!accountId.value) return '请选择账户'
  }
  return ''
}

async function submit(): Promise<void> {
  error.value = validate()
  if (error.value) return

  const cents = parseYuanToCents(amountInput.value)
  if (cents == null) return

  busy.value = true
  try {
    const payload = {
      type: type.value,
      amount_cents: cents,
      category_id: isTransfer.value ? null : categoryId.value,
      account_id: accountId.value,
      to_account_id: isTransfer.value ? toAccountId.value : null,
      note: note.value.trim() || null,
      occurred_at: fromLocalDateTimeInput(occurredAt.value),
    }
    if (props.entry) {
      await updateEntry(props.entry.id, payload)
    } else {
      await createEntry(payload)
    }
    emit('saved')
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '保存失败'
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <!-- 开关由父组件的 v-if 控制，所以这里固定 open；Reka 负责焦点陷阱 / Esc / 关闭归还焦点 -->
  <DialogRoot :open="true" @update:open="(value: boolean) => !value && emit('close')">
    <DialogPortal>
      <DialogOverlay class="modal-backdrop" />
      <DialogContent class="modal ledger-entry-dialog">
        <header class="modal__head">
          <DialogTitle class="modal__title">{{ entry ? '编辑' : '记一笔' }}</DialogTitle>
          <DialogDescription class="sr-only">选择类型、金额、分类与账户，保存后回到流水列表。</DialogDescription>
          <DialogClose as-child>
            <button class="icon-btn" type="button" aria-label="关闭">
              <X aria-hidden="true" />
            </button>
          </DialogClose>
        </header>

      <div class="modal__body ledger-entry-dialog__body">
        <!-- 类型 -->
        <div class="segmented" role="tablist" aria-label="类型">
          <button
            v-for="t in (['expense', 'income', 'transfer'] as EntryType[])"
            :key="t"
            type="button"
            class="segmented__btn"
            :class="{ 'is-active': type === t }"
            role="tab"
            :aria-selected="type === t"
            @click="type = t"
          >
            {{ t === 'expense' ? '支出' : t === 'income' ? '收入' : '转账' }}
          </button>
        </div>

        <!-- 金额 -->
        <label class="field">
          <span class="field__label">金额</span>
          <input
            v-model="amountInput"
            class="input input--amount"
            type="text"
            inputmode="decimal"
            placeholder="0.00"
            aria-label="金额"
          />
        </label>

        <!-- 分类（转账时隐藏） -->
        <div v-if="!isTransfer" class="field">
          <span class="field__label">分类</span>
          <CategoryPicker
            v-model="categoryId"
            :categories="categories"
            :kind="type === 'income' ? 'income' : 'expense'"
          />
        </div>

        <!-- 账户 -->
        <label class="field">
          <span class="field__label">{{ isTransfer ? '转出账户' : '账户' }}</span>
          <select v-model="accountId" class="select" aria-label="账户">
            <option :value="null" disabled>请选择</option>
            <option v-for="acc in activeAccounts" :key="acc.id" :value="acc.id">
              {{ acc.name }}（{{ accountTypeLabel(acc.type) }}）
            </option>
          </select>
        </label>

        <label v-if="isTransfer" class="field">
          <span class="field__label">转入账户</span>
          <select v-model="toAccountId" class="select" aria-label="转入账户">
            <option :value="null" disabled>请选择</option>
            <option
              v-for="acc in activeAccounts.filter((a) => a.id !== accountId)"
              :key="acc.id"
              :value="acc.id"
            >
              {{ acc.name }}（{{ accountTypeLabel(acc.type) }}）
            </option>
          </select>
        </label>

        <!-- 备注与时间 -->
        <label class="field">
          <span class="field__label">备注</span>
          <input v-model="note" class="input" type="text" maxlength="500" placeholder="可留空" aria-label="备注" />
        </label>

        <label class="field">
          <span class="field__label">时间</span>
          <input v-model="occurredAt" class="input" type="datetime-local" aria-label="时间" />
        </label>

        <p v-if="error" class="notice notice--error">{{ error }}</p>
      </div>

        <footer class="modal__actions">
          <button
            v-if="entry"
            class="btn btn--danger modal__actions-lead"
            type="button"
            :disabled="busy"
            @click="emit('delete')"
          >
            删除
          </button>
          <DialogClose as-child>
            <button class="btn" type="button" :disabled="busy">取消</button>
          </DialogClose>
          <button class="btn btn--primary" type="button" :disabled="busy" @click="submit">
            {{ busy ? '保存中…' : '保存' }}
          </button>
        </footer>
      </DialogContent>
    </DialogPortal>
  </DialogRoot>
</template>
