<script setup lang="ts">
/**
 * 公开域顶部导航（docs/frontend/frontend.md 第三节）。
 *
 * 这里的链接顺序即公开站点的全部入口：没有登录、没有设置、没有后台链接。
 */
import { RouterLink } from 'vue-router'
</script>

<template>
  <header class="topbar">
    <RouterLink :to="{ name: 'public-home' }" class="topbar__brand">Haven</RouterLink>

    <nav class="topbar__links" aria-label="主导航">
      <RouterLink :to="{ name: 'public-home' }" class="nav-link">笔记</RouterLink>
      <RouterLink :to="{ name: 'public-search' }" class="nav-link">搜索</RouterLink>
      <RouterLink :to="{ name: 'public-portfolio' }" class="nav-link">作品集</RouterLink>
    </nav>
  </header>
</template>
