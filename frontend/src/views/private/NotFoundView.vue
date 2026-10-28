<script setup lang="ts">
/** 私有域 404。公开域不放后台链接，这里也不回指后台。 */
import { RouterLink } from 'vue-router'
</script>

<template>
  <main class="page" style="max-width: 480px; padding-top: 96px">
    <div class="panel empty">
      <p class="empty__title">页面不存在</p>
      <p style="margin-bottom: 16px">检查一下地址是否输错。</p>
      <RouterLink :to="{ name: 'workbench' }" class="btn">回到笔记</RouterLink>
    </div>
  </main>
</template>
