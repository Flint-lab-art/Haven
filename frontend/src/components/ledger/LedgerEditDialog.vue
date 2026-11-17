<script setup lang="ts">
/**
 * 编辑单笔记账：分类、金额、发生时间。
 *
 * 表单状态（草稿值、错误、保存中）都在组件内部，
 * 父组件只关心「哪一笔」和「保存成功了吗」，不必持有表单字段。
 */
import { computed, reactive, ref, watch } from 'vue'
import type { LedgerCategory, LedgerEntry } from '@/api/ledger'
import { updateLedgerEntry } from '@/api/ledger'
import {
  categoriesForType,
  fromLocalDateTimeInput,
  parseYuanToCents,
  toLocalDateTimeInput,
} from '@/utils/ledger'

const props = defineProps<{
  /** 是否打开。由父组件控制。 */
  open: boolean
  /** 正在编辑的条目；为 null 时不渲染内容。 */
  entry: LedgerEntry | null
}>()

const emit = defineEmits<{
  /** 关闭（用户取消或保存成功）。 */
  'update:open': [value: boolean]
  /** 保存成功，带上服务端返回的最新条目。 */
  saved: [entry: LedgerEntry]
}>()

const form = reactive({ category: '未分类' as LedgerCategory, amount: '', occurredAt: '' })
const error = ref('')
const saving = ref(false)

/** 切到该条目时重置表单：每次打开都是一份干净草稿。 */
watch(
  () => props.entry,
  (entry) => {
    if (!entry) return
    form.category = entry.category
    form.amount = (entry.amount_cents / 100).toString()
    form.occurredAt = toLocalDateTimeInput(entry.occurred_at)
    error.value = ''
  },
  { immediate: true },
)

/** 收入与支出的可选分类不同。 */
const categories = computed(() =>
  categoriesForType(props.entry?.type ?? 'expense', props.entry?.category),
)

function close(): void {
  if (saving.value) return
  emit('update:open', false)
}

async function save(): Promise<void> {
  const entry = props.entry
  if (!entry || saving.value) return

  const cents = parseYuanToCents(form.amount)
  if (cents === null || cents <= 0) {
    error.value = '金额需为大于 0 的数字，最多两位小数'
    return
  }
  const occurredAt = fromLocalDateTimeInput(form.occurredAt)
  if (!occurredAt) {
    error.value = '时间格式不正确'
    return
  }

  // 只提交真正变化的字段，避免无谓的写库
  const patch: { category?: LedgerCategory; amount_cents?: number; occurred_at?: string } = {}
  if (form.category !== entry.category) patch.category = form.category
  if (cents !== entry.amount_cents) patch.amount_cents = cents
  if (occurredAt !== entry.occurred_at) patch.occurred_at = occurredAt

  if (Object.keys(patch).length === 0) {
    emit('update:open', false)
    return
  }

  saving.value = true
  error.value = ''
  try {
    const updated = await updateLedgerEntry(entry.id, patch)
    emit('saved', updated)
    emit('update:open', false)
  } catch (err) {
    error.value = err instanceof Error ? err.message : '保存失败'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div v-if="open && entry" class="modal-backdrop" role="presentation" @click.self="close">
    <section class="modal ledger-edit" role="dialog" aria-modal="true" aria-label="编辑记账">
      <header class="modal__head">
        <div>
          <h2 class="modal__title">编辑这一笔</h2>
          <p class="modal__sub">{{ entry.note || '（无备注）' }}</p>
        </div>
        <button class="icon-btn" type="button" aria-label="关闭" @click="close">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true">
            <path d="M6 6l12 12M18 6 6 18" />
          </svg>
        </button>
      </header>

      <p v-if="error" class="notice notice--error">{{ error }}</p>

      <label class="field">
        <span class="field__label">分类</span>
        <select v-model="form.category" class="select">
          <option v-for="category in categories" :key="category" :value="category">
            {{ category }}
          </option>
        </select>
      </label>

      <label class="field">
        <span class="field__label">金额（元）</span>
        <input v-model="form.amount" class="input" inputmode="decimal" autocomplete="off" />
      </label>

      <label class="field">
        <span class="field__label">发生时间</span>
        <input v-model="form.occurredAt" class="input" type="datetime-local" />
      </label>

      <div class="modal__actions">
        <button class="btn" type="button" :disabled="saving" @click="close">取消</button>
        <button class="btn btn--primary" type="button" :disabled="saving" @click="save">
          {{ saving ? '保存中…' : '保存' }}
        </button>
      </div>
    </section>
  </div>
</template>
