<script setup lang="ts">
import { computed } from 'vue'
import { RouterView, useRoute } from 'vue-router'
import SiteFooter from '@/components/layout/SiteFooter.vue'
import ToastHost from '@/components/common/ToastHost.vue'

const route = useRoute()

/**
 * 登录页悬挂备案号；登录后的工作区不遮挡内容。
 *
 * 从移动端（`/m/`）跳过来的登录页不显示——
 * 手机屏幕上这块灰字只会挡在输入框下面，且备案信息本就属于网站底部的内容。
 */
const showFixedFooter = computed(() => {
  if (route.name !== 'login') return false
  const redirect = route.query.redirect
  return !(typeof redirect === 'string' && redirect.startsWith('/m'))
})
</script>

<template>
  <RouterView />
  <SiteFooter v-if="showFixedFooter" />
  <ToastHost />
</template>
