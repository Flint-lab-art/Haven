<script setup lang="ts">
/** 私有域 404。公开域放后台链接，这里也不回指后台。 */
import { RouterLink } from 'vue-router'
</script>

<template>
  <div class="shell">
    <main class="container container--narrow" style="padding-top: var(--sp-16)">
      <div class="panel empty">
        <p class="empty__title">页面不存在</p>
        <p class="empty__text">检查一下地址是否输错。</p>
        <RouterLink :to="{ name: 'workbench' }" class="btn">回到笔记</RouterLink>
      </div>
    </main>
  </div>
</template>
