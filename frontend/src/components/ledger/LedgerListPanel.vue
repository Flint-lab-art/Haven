<script setup lang="ts">
/**
 * 记账 · 中间栏（明细列表）。
 *
 * 明细天生是「可滚动列表」，放中间栏比铺满详情区更合适：
 * 一屏能看 15+ 条，筛选栏常驻顶部，右侧详情区只负责汇总与账户。
 *
 * 数据来自 `useLedgerStore`，与右侧详情区共享同一份状态。
 */
import { computed } from 'vue'
import { useLedgerStore } from '@/stores/ledger'
import { groupByDay, relativeDayLabel } from '@/utils/ledger-group'
import { formatSignedYuan, formatYuan, monthLabel, shiftMonth } from '@/utils/ledger'
import { ChevronLeft, ChevronRight } from 'lucide-vue-next'


const store = useLedgerStore()

const dayGroups = computed(() => groupByDay(store.entries))

/** 筛选用的分类选项（含一级与二级）。 */
const filterCategoryOptions = computed(() => {
  const options: { id: number; label: string }[] = []
  for (const root of store.categories) {
    if (store.typeFilter && store.typeFilter !== root.kind) continue
    options.push({ id: root.id, label: `${root.icon} ${root.name}` })
    for (const child of root.children) {
      options.push({ id: child.id, label: `${root.name} · ${child.icon} ${child.name}` })
    }
  }
  return options
})

async function stepMonth(delta: number): Promise<void> {
  await store.setMonth(shiftMonth(store.month, delta))
}

/** 点明细行：在右侧打开编辑弹窗（store 驱动，不跳路由）。 */
function openEntry(entry: { id: string }): void {
  store.editingId = entry.id
  store.dialogOpen = true
}
</script>

<template>
  <div class="list-panel">
    <header class="panel-head">
      <h1 class="panel-title">记账</h1>
      <div class="row">
        <button class="icon-btn" type="button" aria-label="上个月" @click="stepMonth(-1)">
          <ChevronLeft aria-hidden="true" />
        </button>
        <span class="ledger-month__label">{{ monthLabel(store.month) }}</span>
        <button class="icon-btn" type="button" aria-label="下个月" @click="stepMonth(1)">
          <ChevronRight aria-hidden="true" />
        </button>
      </div>
    </header>

    <!-- 筛选：固定在列表上方，不随滚动走 -->
    <div class="ledger-filters ledger-filters--compact">
      <select
        v-model="store.typeFilter"
        class="select select--sm"
        aria-label="类型"
        @change="store.applyFilters()"
      >
        <option value="">全部</option>
        <option value="expense">支出</option>
        <option value="income">收入</option>
        <option value="transfer">转账</option>
      </select>
      <select
        :value="store.categoryId ?? ''"
        class="select select--sm"
        aria-label="分类"
        @change="
          store.categoryId = ($event.target as HTMLSelectElement).value
            ? Number(($event.target as HTMLSelectElement).value)
            : null;
          store.applyFilters()
        "
      >
        <option value="">全部分类</option>
        <option v-for="opt in filterCategoryOptions" :key="opt.id" :value="opt.id">{{ opt.label }}</option>
      </select>
      <select
        :value="store.accountId ?? ''"
        class="select select--sm"
        aria-label="账户"
        @change="
          store.accountId = ($event.target as HTMLSelectElement).value || null;
          store.applyFilters()
        "
      >
        <option value="">全部账户</option>
        <option v-for="acc in store.accounts" :key="acc.id" :value="acc.id">{{ acc.name }}</option>
      </select>
    </div>

    <div class="list-rows ledger-rows">
      <div v-if="store.loadingEntries && store.entries.length === 0" class="ledger-list-hint">
        <div class="skeleton skeleton--title" style="width: 60%"></div>
      </div>

      <div v-else-if="dayGroups.length === 0" class="ledger-list-hint">
        <p class="empty__title">这个月还没有记账</p>
        <p class="empty__text">点右上角「记一笔」，或者到「设置 · 账户」先建一个账户。</p>
      </div>

      <template v-else>
        <div v-for="group in dayGroups" :key="group.date" class="ledger-day-group">
          <div class="ledger-day-head">
            <span class="ledger-day-head__label">{{ relativeDayLabel(group.label, group.date) }}</span>
            <span class="ledger-day-head__weekday">{{ group.weekday }}</span>
            <span class="ledger-day-head__sum">
              <template v-if="group.expenseCents > 0">{{ formatYuan(group.expenseCents) }}</template>
              <template v-if="group.incomeCents > 0"> +{{ formatYuan(group.incomeCents) }}</template>
            </span>
          </div>

          <button
            v-for="entry in group.items"
            :key="entry.id"
            type="button"
            class="list-row ledger-list-row"
            @click="openEntry(entry)"
          >
            <span class="cat-icon ledger-list-row__icon" aria-hidden="true">
              {{ entry.category_id != null ? store.categoryMeta.get(entry.category_id)?.icon : '🔁' }}
            </span>
            <span class="ledger-list-row__body">
              <span class="ledger-list-row__title">
                {{ entry.type === 'transfer' ? '转账' : entry.category_name }}
              </span>
              <span class="ledger-list-row__sub">
                <template v-if="entry.type === 'transfer'">
                  {{ entry.account_name }} → {{ entry.to_account_name }}
                </template>
                <template v-else>
                  {{ entry.root_category_name }} · {{ entry.account_name }}
                  <template v-if="entry.note"> · {{ entry.note }}</template>
                </template>
              </span>
            </span>
            <span
              class="ledger-list-row__amount"
              :class="{
                'ledger-list-row__amount--income': entry.type === 'income',
                'ledger-list-row__amount--transfer': entry.type === 'transfer',
              }"
            >
              {{ formatSignedYuan(entry.type, entry.amount_cents) }}
            </span>
          </button>
        </div>
      </template>
    </div>

    <footer v-if="store.total > 0" class="ledger-list-foot">共 {{ store.total }} 条</footer>
  </div>
</template>
