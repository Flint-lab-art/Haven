<script setup lang="ts">
/** 私有域顶栏：玻璃材质 + 紧凑导航，退出放在右侧次级位置。 */
import { RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { logout } from '@/api/auth'

const auth = useAuthStore()
const router = useRouter()

async function signOut(): Promise<void> {
  try {
    await logout()
  } catch {
    // 登出失败也清本地状态；后端会话到期会自然失效
  }
  auth.clear()
  await router.push({ name: 'login' })
}
</script>

<template>
  <header class="topbar">
    <div class="topbar__inner">
      <RouterLink :to="{ name: 'workbench' }" class="topbar__brand">
        <span class="topbar__mark" aria-hidden="true"></span>
        Haven
      </RouterLink>

      <nav class="topbar__links" aria-label="主导航">
        <RouterLink :to="{ name: 'workbench' }" class="nav-link">笔记</RouterLink>
        <RouterLink :to="{ name: 'tags' }" class="nav-link">标签</RouterLink>
        <RouterLink :to="{ name: 'portfolio' }" class="nav-link">作品集</RouterLink>
        <RouterLink :to="{ name: 'settings' }" class="nav-link">设置</RouterLink>
      </nav>

      <div class="spacer"></div>

      <span class="topbar__user">{{ auth.username }}</span>
      <button class="btn btn--sm" type="button" @click="signOut">退出</button>
    </div>
  </header>
</template>
