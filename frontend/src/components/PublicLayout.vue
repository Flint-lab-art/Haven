<script setup lang="ts">
/** 公开域布局：顶栏 + 页面内容 + 页脚（备案信息在正常文档流里）。 */
import { RouterView } from 'vue-router'
import PublicHeader from '@/components/PublicHeader.vue'
import SiteFooter from '@/components/SiteFooter.vue'
</script>

<template>
  <div class="shell public-shell">
    <PublicHeader />
    <RouterView />
    <SiteFooter inline />
  </div>
</template>
