<script setup lang="ts">
import { computed } from 'vue'
import { RouterView, useRoute } from 'vue-router'
import SiteFooter from '@/components/SiteFooter.vue'
import { detectDomain } from '@/router/domain'

const route = useRoute()

// 私有域只在登录页悬挂备案；登录后的工作区不遮挡内容。
// 公开域在 PublicLayout 里用正常页脚展示。
const showFixedFooter = computed(
  () => detectDomain(window.location.hostname) === 'private' && route.name === 'login',
)
</script>

<template>
  <RouterView />
  <SiteFooter v-if="showFixedFooter" />
</template>
