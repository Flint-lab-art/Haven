<script setup lang="ts">
/** 公开域顶栏：只有只读入口，没有登录、设置、后台链接。 */
import { RouterLink } from 'vue-router'
</script>

<template>
  <header class="topbar">
    <div class="topbar__inner">
      <RouterLink :to="{ name: 'public-home' }" class="topbar__brand">
        <span class="topbar__mark" aria-hidden="true"></span>
        Haven
      </RouterLink>

      <nav class="topbar__links" aria-label="主导航">
        <RouterLink :to="{ name: 'public-home' }" class="nav-link">笔记</RouterLink>
        <RouterLink :to="{ name: 'public-search' }" class="nav-link">搜索</RouterLink>
        <RouterLink :to="{ name: 'public-portfolio' }" class="nav-link">作品集</RouterLink>
      </nav>
    </div>
  </header>
</template>
