<script setup lang="ts">
/** 公开域顶栏：只有只读入口，没有登录、设置、后台链接。 */
import { RouterLink } from 'vue-router'
import HavenMark from './HavenMark.vue'
</script>

<template>
  <header class="topbar">
    <div class="topbar__inner">
      <RouterLink :to="{ name: 'public-home' }" class="topbar__brand">
        <HavenMark class="brand-mark" :size="24" />
        Haven
      </RouterLink>

      <nav class="topbar__links" aria-label="主导航">
        <RouterLink :to="{ name: 'public-home' }" class="nav-link">笔记</RouterLink>
        <RouterLink :to="{ name: 'public-portfolio' }" class="nav-link">作品集</RouterLink>
      </nav>
    </div>
  </header>
</template>
