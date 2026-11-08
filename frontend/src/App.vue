<script setup lang="ts">
import { RouterView } from 'vue-router'
import SiteFooter from '@/components/SiteFooter.vue'
import { detectDomain } from '@/router/domain'

// 私有域保留右下角浮层；公开域在 PublicLayout 里用正常页脚
const showFixedFooter = detectDomain(window.location.hostname) === 'private'
</script>

<template>
  <RouterView />
  <SiteFooter v-if="showFixedFooter" />
</template>
