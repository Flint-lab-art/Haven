<script setup lang="ts">
/**
 * 移动端记账页。
 *
 * iOS 风格：大标题 + 月度汇总 + 按天分组的流水列表 + 悬浮记账按钮。
 * 录入用底部抽屉，分类用一级行 + 二级折叠胶囊。
 */
import { computed, onMounted, ref } from 'vue'
import { DialogContent, DialogOverlay, DialogPortal, DialogRoot } from 'reka-ui'
import { RouterLink } from 'vue-router'
import MobileCategoryPicker from '@/components/mobile/MobileCategoryPicker.vue'
import MobileKeypad from '@/components/mobile/MobileKeypad.vue'
import SwipeRow from '@/components/mobile/SwipeRow.vue'
import MobileTimePicker from '@/components/mobile/MobileTimePicker.vue'
import AccountAvatar from '@/components/ledger/AccountAvatar.vue'
import { ApiError } from '@/api/client'
import { toast } from '@/composables/useToast'
import { useLedgerData } from '@/composables/useLedgerData'
import {
  createEntry,
  deleteEntry,
  listAccounts,
  listCategories,
  getBudget,
  updateEntry,
  type Account,
  type Budget,
  type Category,
  type EntryType,
  type LedgerEntry,
} from '@/api/ledger'
import { groupByDay, relativeDayLabel } from '@/utils/ledger-group'
import {
  currentMonth,
  formatSignedYuan,
  formatYuan,
  monthLabel,
  parseYuanToCents,
  shiftMonth,
  toLocalDateTimeInput,
  fromLocalDateTimeInput,
} from '@/utils/ledger'
import { AlignLeft, ChevronLeft, ChevronRight, History, Plus } from 'lucide-vue-next'
import MobilePageHeader from '@/components/mobile/MobilePageHeader.vue'


const month = ref(currentMonth())

/** 已经看到当前月时不再允许往未来翻：记账没有还没发生的月份。 */
const isCurrentMonth = computed(() => month.value >= currentMonth())
const typeFilter = ref<'' | EntryType>('')
const categoryId = ref<number | null>(null)
const accountId = ref<string | null>(null)

const error = ref('')
/** 当前左滑展开的流水 id；同一时间只允许一行展开。 */
const swipedId = ref<string | null>(null)

const accounts = ref<Account[]>([])
const categories = ref<Category[]>([])
const budget = ref<Budget | null>(null)

const {
  summary,
  entries,
  reload,
  removeEntry,
} = useLedgerData({
  month,
  typeFilter,
  categoryId,
  accountId,
  error,
  messageOf: (err, fallback) => (err instanceof ApiError ? err.message : fallback),
})

const dayGroups = computed(() => groupByDay(entries.value))

const categoryMeta = computed(() => {
  const map = new Map<number, { icon: string; name: string }>()
  for (const root of categories.value) {
    map.set(root.id, { icon: root.icon, name: root.name })
    for (const child of root.children) map.set(child.id, { icon: child.icon, name: child.name })
  }
  return map
})

const budgetPercent = computed(() => {
  const b = budget.value
  if (!b || b.total_budget_cents <= 0) return 0
  return Math.min(100, Math.round((b.total_spent_cents / b.total_budget_cents) * 100))
})
const budgetOver = computed(
  () => !!budget.value && budget.value.total_spent_cents > budget.value.total_budget_cents,
)

// ── 底部抽屉录入 ──────────────────────────────────

const sheetOpen = ref(false)

const editingId = ref<string | null>(null)
const formType = ref<EntryType>('expense')
const formAmount = ref('')
const formCategory = ref<number | null>(null)
const formAccount = ref<string | null>(null)
const formToAccount = ref<string | null>(null)
const formNote = ref('')
const formTime = ref(toLocalDateTimeInput(new Date()))
/** 时间选择弹窗开关。 */
const timePickerOpen = ref(false)

/** 折叠态显示的人话时间：今天 / 昨天 / 具体日期。 */
const timeLabel = computed(() => {
  const d = new Date(formTime.value)
  if (Number.isNaN(d.getTime())) return '选择时间'
  const hhmm = `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
  const today = new Date()
  const sameDay = (a: Date, b: Date) =>
    a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
  if (sameDay(d, today)) return `今天 ${hhmm}`
  const yesterday = new Date(today.getTime() - 86_400_000)
  if (sameDay(d, yesterday)) return `昨天 ${hhmm}`
  return `${d.getMonth() + 1} 月 ${d.getDate()} 日 ${hhmm}`
})
const saving = ref(false)
const formError = ref('')

const activeAccounts = computed(() => accounts.value.filter((a) => !a.archived))
/** 没有账户时记账无法进行，页面顶部给一条引导。 */
const noAccounts = computed(() => activeAccounts.value.length === 0)
const isTransfer = computed(() => formType.value === 'transfer')

function openCreate(): void {
  if (noAccounts.value) return
  editingId.value = null
  formType.value = 'expense'
  formAmount.value = ''
  formCategory.value = null
  formAccount.value = activeAccounts.value[0]?.id ?? null
  formToAccount.value = null
  formNote.value = ''
  formTime.value = toLocalDateTimeInput(new Date())
  formError.value = ''
  sheetOpen.value = true
}

function openEdit(entry: LedgerEntry): void {
  editingId.value = entry.id
  formType.value = entry.type
  formAmount.value = String(entry.amount_cents / 100)
  formCategory.value = entry.category_id
  formAccount.value = entry.account_id
  formToAccount.value = entry.to_account_id
  formNote.value = entry.note ?? ''
  formTime.value = toLocalDateTimeInput(entry.occurred_at)
  formError.value = ''
  sheetOpen.value = true
}

function setType(next: EntryType): void {
  formType.value = next
  if (next === 'transfer') {
    formCategory.value = null
    formToAccount.value = null
  } else {
    formToAccount.value = null
  }
}

async function save(): Promise<void> {
  const cents = parseYuanToCents(formAmount.value)
  if (cents == null) {
    formError.value = '金额格式不对'
    return
  }
  if (isTransfer.value) {
    if (!formAccount.value || !formToAccount.value) {
      formError.value = '请选择转出与转入账户'
      return
    }
    if (formAccount.value === formToAccount.value) {
      formError.value = '转出与转入不能是同一个账户'
      return
    }
  } else {
    if (formCategory.value == null) {
      formError.value = '请选择分类'
      return
    }
    if (!formAccount.value) {
      formError.value = '请选择账户'
      return
    }
  }

  saving.value = true
  formError.value = ''
  try {
    const payload = {
      type: formType.value,
      amount_cents: cents,
      category_id: isTransfer.value ? null : formCategory.value,
      account_id: formAccount.value,
      to_account_id: isTransfer.value ? formToAccount.value : null,
      note: formNote.value.trim() || null,
      occurred_at: fromLocalDateTimeInput(formTime.value),
    }
    const editing = editingId.value !== null
    if (editing) {
      await updateEntry(editingId.value as string, payload)
    } else {
      await createEntry(payload)
    }
    sheetOpen.value = false
    toast.success(editing ? '已更新' : '已记一笔')
    await refresh()
  } catch (err) {
    formError.value = err instanceof ApiError ? err.message : '保存失败'
  } finally {
    saving.value = false
  }
}

async function remove(entry: LedgerEntry): Promise<void> {
  if (!window.confirm('删除这一笔？')) return
  try {
    await deleteEntry(entry.id)
    removeEntry(entry.id)
    toast.success('已删除')
    await refresh()
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '删除失败'
  }
}

// ── 加载 ──────────────────────────────────────────

async function refresh(): Promise<void> {
  await reload()
  try {
    budget.value = await getBudget(month.value)
  } catch {
    budget.value = null
  }
}

async function changeMonth(delta: number): Promise<void> {
  // 双保险：UI 上已隐藏按钮，这里再挡一次，防止其他入口翻到未来
  if (delta > 0 && isCurrentMonth.value) return
  month.value = shiftMonth(month.value, delta)
  await refresh()
}

onMounted(async () => {
  try {
    const [accs, cats] = await Promise.all([listAccounts(), listCategories()])
    accounts.value = accs
    categories.value = cats
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '初始化失败'
  }
  await refresh()
})
</script>

<template>
  <div class="m-page">
    <MobilePageHeader title="记账">
      <template #trail>
        <div class="m-month">
          <button class="m-icon-btn" type="button" aria-label="上个月" @click="changeMonth(-1)">
            <ChevronLeft aria-hidden="true" />
          </button>
          <span class="m-month__label">{{ monthLabel(month) }}</span>
          <!-- 到当前月就藏起来：不能翻到还没有数据的未来月份 -->
          <button
            v-if="!isCurrentMonth"
            class="m-icon-btn"
            type="button"
            aria-label="下个月"
            @click="changeMonth(1)"
          >
            <ChevronRight aria-hidden="true" />
          </button>
      
          </div>
        </template>
      </MobilePageHeader>

      <p v-if="error" class="m-notice m-notice--error">{{ error }}</p>

      <RouterLink v-if="noAccounts" :to="{ name: 'm-accounts' }" class="m-notice m-notice--hint">
        还没有账户，先去建一个 →
      </RouterLink>

      <!-- 月度汇总 -->
      <section class="m-summary" aria-label="月度汇总">
        <div class="m-summary__cell">
          <span class="m-summary__label">支出</span>
          <span class="m-summary__value">{{ formatYuan(summary?.total_expense_cents ?? 0) }}</span>
        </div>
        <div class="m-summary__cell">
          <span class="m-summary__label">收入</span>
          <span class="m-summary__value m-summary__value--income">
            {{ formatYuan(summary?.total_income_cents ?? 0) }}
          </span>
        </div>
        <div class="m-summary__cell">
          <span class="m-summary__label">笔数</span>
          <span class="m-summary__value">{{ summary?.total_count ?? 0 }}</span>
        </div>
      </section>

      <!-- 预算 -->
      <section v-if="budget && budget.total_budget_cents > 0" class="m-card" aria-label="预算">
        <div class="m-budget__head">
          <span>本月预算</span>
          <span :class="{ 'm-over': budgetOver }">
            {{ formatYuan(budget.total_spent_cents) }} / {{ formatYuan(budget.total_budget_cents) }}
          </span>
        </div>
        <div class="m-budget__bar">
          <div
            class="m-budget__fill"
            :class="{ 'm-budget__fill--over': budgetOver }"
            :style="{ transform: `scaleX(${budgetPercent / 100})` }"
          ></div>
        </div>
      </section>

      <!-- 流水 -->
      <div v-if="dayGroups.length === 0" class="m-empty">
        <p class="m-empty__title">这个月还没有记录</p>
        <p class="m-empty__text">点右下角记一笔。</p>
      </div>

      <section v-else class="m-days">
        <div v-for="group in dayGroups" :key="group.date" class="m-day">
          <div class="m-day__head">
            <span>{{ relativeDayLabel(group.label, group.date) }}</span>
            <span class="m-day__weekday">{{ group.weekday }}</span>
            <span class="m-day__sum">
              <template v-if="group.expenseCents > 0">-{{ formatYuan(group.expenseCents) }}</template>
              <template v-if="group.incomeCents > 0"> +{{ formatYuan(group.incomeCents) }}</template>
            </span>
          </div>

          <ul class="m-list">
            <li v-for="entry in group.items" :key="entry.id">
              <SwipeRow
                :open="swipedId === entry.id"
                @toggle="(v) => (swipedId = v ? entry.id : null)"
                @remove="remove(entry)"
                @tap="openEdit(entry)"
              >
                <div class="m-row m-row--static">
                  <span class="cat-icon m-row__icon" aria-hidden="true">
                    {{ entry.category_id != null ? categoryMeta.get(entry.category_id)?.icon : '🔁' }}
                  </span>
                  <div class="m-row__main">
                    <span class="m-row__title">
                      {{ entry.type === 'transfer' ? '转账' : entry.category_name }}
                    </span>
                    <span class="m-row__sub">
                      <template v-if="entry.type === 'transfer'">
                        {{ entry.account_name }} → {{ entry.to_account_name }}
                      </template>
                      <template v-else>
                        {{ entry.root_category_name }} · {{ entry.account_name }}
                        <template v-if="entry.note"> · {{ entry.note }}</template>
                      </template>
                    </span>
                  </div>
                  <span
                    class="m-row__amount"
                    :class="{ 'm-row__amount--income': entry.type === 'income', 'm-row__amount--transfer': entry.type === 'transfer' }"
                  >
                    {{ formatSignedYuan(entry.type, entry.amount_cents) }}
                  </span>
                </div>
              </SwipeRow>
            </li>
          </ul>
        </div>
      </section>

      <button v-if="!noAccounts" class="m-fab" type="button" aria-label="记一笔" @click="openCreate">
        <Plus aria-hidden="true" />
      </button>

      <!--
        底部抽屉录入。挂到 body 是硬性要求：.m-main 有 overflow-y: auto，
        会创建新的层叠上下文，抽屉的 z-index 只在 .m-main 内部比较，
        压不住 fixed 的底部 tabbar。这里改用 Reka 的 Portal，效果相同。
      -->
      <DialogRoot :open="sheetOpen" @update:open="(value: boolean) => !value && (sheetOpen = false)">
        <DialogPortal>
          <DialogOverlay class="m-sheet-backdrop" />
          <DialogContent class="m-sheet" aria-label="记一笔">
            <div class="m-sheet__grab"></div>

            <!-- 类型：顶部胶囊，轻量 -->
            <div class="m-segmented">
              <button
                v-for="t in (['expense', 'income', 'transfer'] as EntryType[])"
                :key="t"
                type="button"
                class="m-segmented__btn"
                :class="{ 'is-active': formType === t }"
                @click="setType(t)"
              >
                {{ t === 'expense' ? '支出' : t === 'income' ? '收入' : '转账' }}
              </button>
        </div>

          <!-- 分类优先：先定性质，再填数额 -->
          <MobileCategoryPicker
            v-if="!isTransfer"
            v-model="formCategory"
            :categories="categories"
            :kind="formType === 'income' ? 'income' : 'expense'"
          />

          <!-- 金额大字居中，只读展示；输入走下方自定义键盘 -->
          <div class="m-amount" aria-live="polite">
            <span class="m-amount__currency">¥</span>
            <span class="m-amount__value" :class="{ 'm-amount__value--empty': !formAmount }">
              {{ formAmount || '0' }}
            </span>
          </div>

          <!-- 账户：胶囊横排，和分类网格同一视觉语言 -->
          <div class="m-accounts-row">
            <span class="m-accounts-row__label">{{ isTransfer ? '从' : '账户' }}</span>
            <div class="m-accounts-row__pills" role="radiogroup" aria-label="账户">
              <button
                v-for="acc in activeAccounts"
                :key="acc.id"
                type="button"
                class="m-acc-pill"
                :class="{ 'm-acc-pill--active': formAccount === acc.id }"
                role="radio"
                :aria-checked="formAccount === acc.id"
                @click="formAccount = acc.id"
              >
                <AccountAvatar :name="acc.name" :icon="acc.icon" />
                {{ acc.name }}
              </button>
            </div>
          </div>

          <!-- 转账：转入账户同样用胶囊 -->
          <div v-if="isTransfer" class="m-accounts-row">
            <span class="m-accounts-row__label">到</span>
            <div class="m-accounts-row__pills" role="radiogroup" aria-label="转入账户">
              <button
                v-for="acc in activeAccounts.filter((a) => a.id !== formAccount)"
                :key="acc.id"
                type="button"
                class="m-acc-pill"
                :class="{ 'm-acc-pill--active': formToAccount === acc.id }"
                role="radio"
                :aria-checked="formToAccount === acc.id"
                @click="formToAccount = acc.id"
              >
                <AccountAvatar :name="acc.name" :icon="acc.icon" />
                {{ acc.name }}
              </button>
            </div>
          </div>

          <!-- 备注与时间：同一行，备注占满剩余宽度，时间靠右 -->
          <div class="m-sheet__extras">
            <label class="m-extra-note">
              <AlignLeft aria-hidden="true" />
              <input
                v-model="formNote"
                class="m-extra-note__input"
                type="text"
                maxlength="500"
                placeholder="添加备注"
                aria-label="备注"
              />
            </label>

            <button
              type="button"
              class="m-extra-time"
              :class="{ 'm-extra-time--open': timePickerOpen }"
              :aria-label="`时间：${timeLabel}`"
              @click="timePickerOpen = true"
            >
              <History aria-hidden="true" />
              <span>{{ timeLabel }}</span>
            </button>
          </div>

          <p v-if="formError" class="m-notice m-notice--error">{{ formError }}</p>

          <!-- 数字键盘：数字 + 退格 + 保存，一只手能完成全部操作 -->
          <MobileKeypad v-model="formAmount" :busy="saving" :save-label="editingId ? '保存' : '记一笔'" @save="save" />
          </DialogContent>
        </DialogPortal>
      </DialogRoot>

      <!-- 时间选择弹窗自己也是 Reka Dialog + Portal，盖在抽屉之上 -->
      <MobileTimePicker v-model="formTime" :open="timePickerOpen" @close="timePickerOpen = false" />
  </div>
</template>
