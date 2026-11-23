<script setup lang="ts">
/**
 * 记账 · 右侧详情区（PC 三栏布局）。
 *
 * 明细移到中间栏（`LedgerListPanel`），这里只放「今天/本月怎么样」：
 * 结余、账户余额、预算、分类占比。
 *
 * 为什么这样分：记账页最高频的动作是浏览明细，其次是看「还剩多少」。
 * 两者放在同一列会互相挤；分到两栏后，明细能占满高度，汇总也常驻可见。
 */
import { computed, onMounted, ref } from 'vue'
import LedgerDonutChart from '@/components/LedgerDonutChart.vue'
import LedgerEntryDialog from '@/components/ledger/LedgerEntryDialog.vue'
import ConfirmDialog from '@/components/common/ConfirmDialog.vue'
import AccountAvatar from '@/components/ledger/AccountAvatar.vue'
import { useLedgerStore } from '@/stores/ledger'
import { formatYuan } from '@/utils/ledger'

const store = useLedgerStore()

// 对话框状态放在 store 里：中间栏点明细行要能在右侧打开编辑
const dialogOpen = computed({
  get: () => store.dialogOpen,
  set: (v: boolean) => (store.dialogOpen = v),
})
const editingId = computed({
  get: () => store.editingId,
  set: (v: string | null) => (store.editingId = v),
})

/** 待确认删除的目标。 */
const pendingDelete = ref<{ id: string; label: string } | null>(null)

const editingEntry = computed(() =>
  editingId.value ? (store.entries.find((e) => e.id === editingId.value) ?? null) : null,
)

/** 结余 = 收入 − 支出。 */
const balance = computed(
  () => (store.summary?.total_income_cents ?? 0) - (store.summary?.total_expense_cents ?? 0),
)

/** 圆环优先展示支出分类。 */
const donut = computed(() => {
  const s = store.summary
  if (!s) return { items: [], label: '支出' }
  if (s.expense_by_category.length > 0) return { items: s.expense_by_category, label: '支出' }
  return { items: s.income_by_category, label: '收入' }
})

function openCreate(): void {
  store.editingId = null
  store.dialogOpen = true
}

async function onSaved(): Promise<void> {
  store.dialogOpen = false
  store.editingId = null
  store.flash('已保存')
  await store.refresh()
}

function askDelete(): void {
  const entry = editingEntry.value
  if (!entry) return
  pendingDelete.value = {
    id: entry.id,
    label: `${entry.category_name ?? '转账'} ${formatYuan(entry.amount_cents)}`,
  }
}

async function confirmDelete(): Promise<void> {
  const target = pendingDelete.value
  if (!target) return
  pendingDelete.value = null
  store.dialogOpen = false
  store.editingId = null
  await store.remove({ id: target.id } as never)
}

onMounted(() => {
  void store.init()
})
</script>

<template>
  <div class="detail-inner ledger-detail-pane">
    <header class="detail-head">
      <div>
        <h1 class="detail-title">概览</h1>
        <p class="detail-sub">钱从哪出、花在哪、还剩多少</p>
      </div>
      <button class="btn btn--primary" type="button" @click="openCreate">记一笔</button>
    </header>

    <p v-if="store.error" class="notice notice--error">{{ store.error }}</p>
    <p v-if="store.toast" class="notice notice--success">{{ store.toast }}</p>

    <!-- 结余：整页的视觉锚点 -->
    <section class="ledger-hero" aria-label="本月结余">
      <span class="ledger-hero__label">本月结余</span>
      <span class="ledger-hero__value" :class="{ 'ledger-hero__value--negative': balance < 0 }">
        {{ balance < 0 ? '−' : '' }}{{ formatYuan(Math.abs(balance)) }}
      </span>
      <div class="ledger-hero__split">
        <div class="ledger-hero__item">
          <span class="ledger-hero__item-label">支出</span>
          <span class="ledger-hero__item-value">{{ formatYuan(store.summary?.total_expense_cents ?? 0) }}</span>
        </div>
        <div class="ledger-hero__item">
          <span class="ledger-hero__item-label">收入</span>
          <span class="ledger-hero__item-value ledger-hero__item-value--income">
            {{ formatYuan(store.summary?.total_income_cents ?? 0) }}
          </span>
        </div>
        <div class="ledger-hero__item">
          <span class="ledger-hero__item-label">笔数</span>
          <span class="ledger-hero__item-value">{{ store.summary?.total_count ?? 0 }}</span>
        </div>
      </div>
    </section>

    <!-- 账户余额：一行一个，像银行 App 的资产列表 -->
    <section class="panel panel--pad ledger-acc-block" aria-label="账户">
      <h2 class="ledger-block__title">账户</h2>
      <ul v-if="store.activeAccounts.length > 0" class="ledger-acc-list">
        <li v-for="acc in store.activeAccounts" :key="acc.id" class="ledger-acc-row">
          <span class="ledger-acc-row__name">
            <AccountAvatar :name="acc.name" :icon="acc.icon" />
            {{ acc.name }}
          </span>
          <span
            class="ledger-acc-row__balance"
            :class="{ 'ledger-acc-row__balance--debt': acc.balance_cents < 0 }"
          >
            {{ formatYuan(acc.balance_cents) }}
          </span>
        </li>
      </ul>
      <p v-else class="field__hint">
        还没有账户，先到「设置 · 账户」里建一个。
      </p>
    </section>

    <!-- 预算 -->
    <section v-if="store.budget && store.budget.total_budget_cents > 0" class="panel panel--pad ledger-block" aria-label="预算">
      <div class="ledger-block__head">
        <h2 class="ledger-block__title">本月预算</h2>
        <span class="ledger-block__meta" :class="{ 'is-over': store.budgetOver }">
          {{ formatYuan(store.budget.total_spent_cents) }} / {{ formatYuan(store.budget.total_budget_cents) }}
        </span>
      </div>
      <div class="ledger-budget__bar">
        <div
          class="ledger-budget__fill"
          :class="{ 'ledger-budget__fill--over': store.budgetOver }"
          :style="{ width: store.budgetPercent + '%' }"
        ></div>
      </div>
      <ul class="ledger-budget__items">
        <li
          v-for="item in store.budget.items"
          :key="item.category_id"
          class="ledger-budget__item"
        >
          <span>{{ item.category_name }}</span>
          <span :class="{ 'is-over': item.remaining_cents < 0 }">
            {{ formatYuan(item.spent_cents) }} / {{ formatYuan(item.amount_cents) }}
          </span>
        </li>
      </ul>
    </section>

    <!-- 分类占比 -->
    <section v-if="donut.items.length > 0" class="panel panel--pad ledger-block" aria-label="分类占比">
      <h2 class="ledger-block__title">钱花在哪</h2>
      <LedgerDonutChart :items="donut.items" :label="donut.label" />
    </section>

    <LedgerEntryDialog
      v-if="dialogOpen"
      :entry="editingEntry"
      :accounts="store.accounts"
      :categories="store.categories"
      @close="store.dialogOpen = false; store.editingId = null"
      @saved="onSaved"
      @delete="askDelete"
    />

    <ConfirmDialog
      v-if="pendingDelete"
      :open="true"
      title="删除这笔记录？"
      :message="`「${pendingDelete.label}」删除后不可恢复。`"
      @confirm="confirmDelete"
      @cancel="pendingDelete = null"
    />
  </div>
</template>
