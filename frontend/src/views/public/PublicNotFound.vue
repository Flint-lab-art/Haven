<script setup lang="ts">
/** 公开域 404：不暴露后台入口。 */
import { RouterLink } from 'vue-router'
import PublicEmpty from '@/components/PublicEmpty.vue'
</script>

<template>
  <main class="container">
    <PublicEmpty title="页面不存在" text="检查一下地址是否输错。">
      <RouterLink :to="{ name: 'public-home' }" class="btn btn--primary">回到笔记</RouterLink>
    </PublicEmpty>
  </main>
</template>
