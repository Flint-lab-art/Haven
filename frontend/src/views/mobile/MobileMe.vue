<script setup lang="ts">
/**
 * 移动端「我的」。
 *
 * 版式：身份卡（头像 + 昵称 + 本月概况）→ 功能分组 → 退出。
 * 前面先给「我是谁、这个月怎么样」，后面才是操作入口，
 * 避免一进来就是一列纯功能行。
 */
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { logout } from '@/api/auth'
import { getSummary, type LedgerSummary } from '@/api/ledger'
import { useAuthStore } from '@/stores/auth'
import { formatYuan } from '@/utils/ledger'
import { ChevronRight } from 'lucide-vue-next'
import MobilePageHeader from '@/components/mobile/MobilePageHeader.vue'

const auth = useAuthStore()
const router = useRouter()

const summary = ref<LedgerSummary | null>(null)

/** 昵称首字做头像；没有用户名时用「H」。 */
const initial = computed(() => (auth.username ?? 'H').slice(0, 1).toUpperCase())

const groups = [
  {
    title: '记账',
    items: [{ name: 'm-budget', label: '预算', hint: '按月设各分类上限' }],
  },
  {
    title: '其他',
    items: [
      { name: 'm-issues', label: 'Issue', hint: '需求与 Bug' },
      { name: 'm-settings', label: '设置', hint: '外观、安全、会话、Token' },
    ],
  },
] as const

const monthExpense = computed(() => summary.value?.total_expense_cents ?? 0)
const monthIncome = computed(() => summary.value?.total_income_cents ?? 0)

async function signOut(): Promise<void> {
  if (!window.confirm('退出登录？')) return
  try {
    await logout()
  } catch {
    // 登出失败也清本地状态；后端会话到期会自然失效
  }
  auth.clear()
  await router.push({ name: 'login' })
}

onMounted(async () => {
  try {
    summary.value = await getSummary()
  } catch {
    // 概况拿不到不影响功能入口
  }
})
</script>

<template>
  <div class="m-page">
    <MobilePageHeader title="我的" />

    <!-- 身份卡：头像 + 昵称 + 本月收支 -->
    <section class="m-card m-profile">
      <div class="m-profile__head">
        <span class="m-profile__avatar" aria-hidden="true">{{ initial }}</span>
        <div class="m-profile__id">
          <span class="m-profile__name">{{ auth.username }}</span>
          <span class="m-profile__sub">
            {{ auth.authType === 'token' ? 'API Token' : '浏览器会话' }} · 双重验证{{
              auth.totpEnabled ? '已启用' : '未启用'
            }}
          </span>
        </div>
      </div>

      <div class="m-profile__stats">
        <div class="m-profile__stat">
          <span class="m-profile__stat-label">本月支出</span>
          <span class="m-profile__stat-value">{{ formatYuan(monthExpense) }}</span>
        </div>
        <div class="m-profile__stat">
          <span class="m-profile__stat-label">本月收入</span>
          <span class="m-profile__stat-value m-profile__stat-value--income">{{ formatYuan(monthIncome) }}</span>
        </div>
      </div>
    </section>

    <!-- 功能分组 -->
    <section v-for="group in groups" :key="group.title" class="m-group">
      <h2 class="m-group__title">{{ group.title }}</h2>
      <nav class="m-card m-menu" :aria-label="group.title">
        <RouterLink v-for="item in group.items" :key="item.name" :to="{ name: item.name }" class="m-menu__row">
          <span class="m-menu__label">{{ item.label }}</span>
          <span class="m-menu__hint">{{ item.hint }}</span>
          <ChevronRight aria-hidden="true" />
        </RouterLink>
      </nav>
    </section>

    <button class="m-danger-btn" type="button" @click="signOut">退出登录</button>
  </div>
</template>
