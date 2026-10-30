<script setup lang="ts">
/**
 * 私有域左侧导航（ui-design.md 第二节、第八节）。
 *
 * - 中间只放全局功能：笔记、搜索、标签、作品集；
 * - 「设置 / 退出登录」收进底部用户信息区，点击后向上弹出；
 * - Mini 模式只留居中图标与头像，悬停显示 Tooltip；
 * - 折叠状态由 ui store 管理并持久化到 localStorage。
 */
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { logout } from '@/api/auth'
import HavenMark from './HavenMark.vue'

const auth = useAuthStore()
const ui = useUiStore()
const route = useRoute()
const router = useRouter()

const section = computed(() => (typeof route.meta.section === 'string' ? route.meta.section : ''))
const initial = computed(() => (auth.username ?? 'H').slice(0, 1).toUpperCase())
const mini = computed(() => ui.sidebarMini)

const userMenuOpen = ref(false)
const userArea = ref<HTMLElement | null>(null)

function toggleUserMenu(): void {
  userMenuOpen.value = !userMenuOpen.value
}

function closeUserMenu(): void {
  userMenuOpen.value = false
}

function onDocumentPointerDown(event: PointerEvent): void {
  if (!userMenuOpen.value) return
  const target = event.target as Node | null
  if (target && userArea.value?.contains(target)) return
  closeUserMenu()
}

function onDocumentKeydown(event: KeyboardEvent): void {
  if (event.key === 'Escape') closeUserMenu()
}

async function signOut(): Promise<void> {
  closeUserMenu()
  try {
    await logout()
  } catch {
    // 登出失败也清本地状态；后端会话到期会自然失效
  }
  auth.clear()
  await router.push({ name: 'login' })
}

// 折叠或换页时收起菜单，避免菜单悬在半空
watch(mini, closeUserMenu)
watch(
  () => route.fullPath,
  () => closeUserMenu(),
)

onMounted(() => {
  document.addEventListener('pointerdown', onDocumentPointerDown)
  document.addEventListener('keydown', onDocumentKeydown)
})

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', onDocumentPointerDown)
  document.removeEventListener('keydown', onDocumentKeydown)
})
</script>

<template>
  <nav class="sidebar" :class="{ 'sidebar--mini': mini }" aria-label="主导航">
    <div class="sidebar__top">
      <RouterLink :to="{ name: 'workbench' }" class="sidebar__brand" data-tip="Haven" aria-label="Haven 首页">
        <HavenMark
          class="brand-mark"
          :size="mini ? 22 : 28"
          :variant="mini ? 'compact' : 'standard'"
        />
        <span class="sidebar__brand-text">Haven</span>
      </RouterLink>

      <button
        class="icon-btn sidebar__toggle"
        type="button"
        :data-tip="mini ? '展开侧边栏' : '折叠侧边栏'"
        :aria-label="mini ? '展开侧边栏' : '折叠侧边栏'"
        :aria-expanded="!mini"
        @click="ui.toggleSidebar()"
      >
        <svg v-if="mini" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="m9 6 6 6-6 6" />
          <path d="m3 6 6 6-6 6" />
        </svg>
        <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="m15 6-6 6 6 6" />
          <path d="m21 6-6 6 6 6" />
        </svg>
      </button>
    </div>

    <span class="sidebar__label">浏览</span>

    <RouterLink
      :to="{ name: 'workbench' }"
      class="side-link"
      :class="{ 'side-link--active': section === 'notes' }"
      data-tip="笔记"
      aria-label="笔记"
    >
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" aria-hidden="true">
        <path d="M6 3h7l5 5v13H6z" />
        <path d="M13 3v5h5" />
        <path d="M9 13h6M9 17h6" />
      </svg>
      <span>笔记</span>
    </RouterLink>

    <RouterLink
      :to="{ name: 'search' }"
      class="side-link"
      :class="{ 'side-link--active': section === 'search' }"
      data-tip="搜索"
      aria-label="搜索"
    >
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" aria-hidden="true">
        <circle cx="11" cy="11" r="6" />
        <path d="m16 16 4 4" />
      </svg>
      <span>搜索</span>
    </RouterLink>

    <RouterLink
      :to="{ name: 'tags' }"
      class="side-link"
      :class="{ 'side-link--active': section === 'tags' }"
      data-tip="标签"
      aria-label="标签"
    >
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" aria-hidden="true">
        <path d="M3 12V5a2 2 0 0 1 2-2h7l9 9-9 9z" />
        <circle cx="7.5" cy="7.5" r="1.2" fill="currentColor" stroke="none" />
      </svg>
      <span>标签</span>
    </RouterLink>

    <RouterLink
      :to="{ name: 'portfolio' }"
      class="side-link"
      :class="{ 'side-link--active': section === 'portfolio' }"
      data-tip="作品集"
      aria-label="作品集"
    >
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" aria-hidden="true">
        <rect x="3" y="3" width="7" height="7" rx="1" />
        <rect x="14" y="3" width="7" height="7" rx="1" />
        <rect x="3" y="14" width="7" height="7" rx="1" />
        <rect x="14" y="14" width="7" height="7" rx="1" />
      </svg>
      <span>作品集</span>
    </RouterLink>

    <div class="sidebar__spacer"></div>

    <div ref="userArea" class="sidebar__user">
      <button
        class="user-trigger"
        type="button"
        :data-tip="mini ? '账户' : undefined"
        :aria-expanded="userMenuOpen"
        aria-haspopup="menu"
        aria-label="账户菜单"
        @click="toggleUserMenu"
      >
        <span class="avatar" aria-hidden="true">{{ initial }}</span>
        <span class="sidebar__user-info">
          <span>{{ auth.username ?? '未登录' }}</span>
          <span class="muted">个人空间</span>
        </span>
        <svg class="user-trigger__chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="m6 15 6-6 6 6" />
        </svg>
      </button>

      <div v-if="userMenuOpen" class="user-menu" role="menu" aria-label="账户">
        <RouterLink :to="{ name: 'settings' }" class="user-menu__item" role="menuitem" @click="closeUserMenu">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="3" />
            <path d="M19 12a7 7 0 0 0-.1-1.2l2-1.5-2-3.4-2.3.9a7 7 0 0 0-2-1.2L14.2 3h-4.4l-.4 2.6a7 7 0 0 0-2 1.2l-2.3-.9-2 3.4 2 1.5a7 7 0 0 0 0 2.4l-2 1.5 2 3.4 2.3-.9a7 7 0 0 0 2 1.2l.4 2.6h4.4l.4-2.6a7 7 0 0 0 2-1.2l2.3.9 2-3.4-2-1.5A7 7 0 0 0 19 12z" />
          </svg>
          设置
        </RouterLink>

        <button class="user-menu__item user-menu__item--danger" type="button" role="menuitem" @click="signOut">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3" />
            <path d="M10 8l-4 4 4 4" />
            <path d="M6 12h9" />
          </svg>
          退出登录
        </button>
      </div>
    </div>
  </nav>
</template>
