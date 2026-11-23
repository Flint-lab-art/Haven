<script setup lang="ts">
/**
 * 移动端布局：内容区 + 底部 tab。
 *
 * 三只 tab：统计 / 记账 / 我的。
 * 记账放中间——它是最高频的动作，落在拇指最容易够到的位置。
 * Issue 与设置仍在「我的」里，底部保持少而稳（iOS HIG：底栏不超过 5 项）。
 *
 * 高度用 `100dvh` 而不是 `100vh`：iOS Safari 地址栏收起/展开时，
 * `100vh` 会让内容被底栏盖住或留白。
 */
import { RouterView, useRoute } from 'vue-router'
import { ChartColumn, CircleUser, Wallet, WalletCards } from 'lucide-vue-next'


const route = useRoute()

/**
 * 顺序：统计 / 记账 / 账户 / 我的。
 *
 * 记账放正中——它是每天多次的动作，拇指自然落点在屏幕中央，
 * 放最边上要够一下。两侧是两类「查看」（统计看账、账户看钱），
 * 「我的」固定最右，符合 iOS 惯例。
 */
const tabs = [
  { name: 'm-stats', label: '统计', key: 'stats' },
  { name: 'm-ledger', label: '记账', key: 'ledger' },
  { name: 'm-accounts', label: '账户', key: 'accounts' },
  { name: 'm-me', label: '我的', key: 'me' },
] as const
</script>

<template>
  <div class="m-app">
    <main class="m-main">
      <RouterView />
    </main>

    <nav class="m-tabbar" aria-label="主导航">
      <RouterLink
        v-for="tab in tabs"
        :key="tab.key"
        :to="{ name: tab.name }"
        class="m-tab"
        :class="{ 'm-tab--active': route.meta.mTab === tab.key }"
      >
        <ChartColumn v-if="tab.key === 'stats'" aria-hidden="true" />
        <Wallet v-else-if="tab.key === 'ledger'" aria-hidden="true" />
        <WalletCards v-else-if="tab.key === 'accounts'" aria-hidden="true" />
        <CircleUser v-else aria-hidden="true" />
        <span>{{ tab.label }}</span>
      </RouterLink>
    </nav>
  </div>
</template>
