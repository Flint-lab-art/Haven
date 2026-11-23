<script setup lang="ts">
/**
 * 移动端设置。
 *
 * 「外观」和「登录日志」有移动原生页面（手机上真会看）；
 * 「账号安全」「会话」「API Token」仍跳 PC 页面——
 * 这三项都是低频操作，为它们各写一套移动端界面不划算。
 */
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { ChevronRight, ExternalLink } from 'lucide-vue-next'
import MobilePageHeader from '@/components/mobile/MobilePageHeader.vue'

const auth = useAuthStore()

/** 移动原生页面。 */
const nativeItems = [
  { name: 'm-budget', label: '预算', hint: '按月设各分类上限' },
  { name: 'm-appearance', label: '外观', hint: '主题配色' },
  { name: 'm-login-logs', label: '登录日志', hint: '最近的登录与失败尝试' },
] as const

/** 跳 PC 页面的项：低频操作，手机上也能用，只是没为小屏优化。 */
const pcItems = [
  { to: '/settings/security', label: '账号安全', hint: '密码与双重验证' },
  { to: '/settings/sessions', label: '会话', hint: '管理已登录设备' },
  { to: '/settings/tokens', label: 'API Token', hint: '给快捷指令用的凭证' },
] as const

const authLabel = computed(() => (auth.authType === 'token' ? 'API Token' : '浏览器会话'))
</script>

<template>
  <div class="m-page">
    <MobilePageHeader title="设置" />

    <div class="m-card m-account-head">
      <span class="m-account-head__name">{{ auth.username }}</span>
      <span class="m-account-head__sub">{{ authLabel }}</span>
    </div>

    <section class="m-group">
      <h2 class="m-group__title">常用</h2>
      <nav class="m-card m-menu" aria-label="常用设置">
        <RouterLink v-for="item in nativeItems" :key="item.name" :to="{ name: item.name }" class="m-menu__row">
          <span class="m-menu__label">{{ item.label }}</span>
          <span class="m-menu__hint">{{ item.hint }}</span>
          <ChevronRight aria-hidden="true" />
        </RouterLink>
      </nav>
    </section>

    <section class="m-group">
      <h2 class="m-group__title">在电脑上操作更方便</h2>
      <nav class="m-card m-menu" aria-label="其他设置">
        <a v-for="item in pcItems" :key="item.to" :href="item.to" class="m-menu__row">
          <span class="m-menu__label">{{ item.label }}</span>
          <span class="m-menu__hint">{{ item.hint }}</span>
          <ExternalLink aria-hidden="true" />
        </a>
      </nav>
      <p class="m-hint">这些页面是大屏布局，手机上可以横向滚动查看。</p>
    </section>
  </div>
</template>
