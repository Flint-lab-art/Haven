<script setup lang="ts">
/** 私有域顶部导航（只在私有域渲染，公开域不出现任何后台入口）。 */
import { RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { logout } from '@/api/auth'

const auth = useAuthStore()
const router = useRouter()

async function signOut(): Promise<void> {
  try {
    await logout()
  } catch {
    // 登出失败也把本地状态清掉，后端会话到期会自然失效
  }
  auth.clear()
  await router.push({ name: 'login' })
}
</script>

<template>
  <header class="topbar">
    <RouterLink :to="{ name: 'workbench' }" class="topbar__brand">Haven</RouterLink>

    <nav class="topbar__links" aria-label="主导航">
      <RouterLink :to="{ name: 'workbench' }" class="nav-link">笔记</RouterLink>
      <RouterLink :to="{ name: 'tags' }" class="nav-link">标签</RouterLink>
      <RouterLink :to="{ name: 'portfolio' }" class="nav-link">作品集</RouterLink>
      <RouterLink :to="{ name: 'settings' }" class="nav-link">设置</RouterLink>
    </nav>

    <div class="spacer"></div>
    <span class="field__hint">{{ auth.username }}</span>
    <button class="btn btn--small" type="button" @click="signOut">退出</button>
  </header>
</template>
