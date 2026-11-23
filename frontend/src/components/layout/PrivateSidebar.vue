<script setup lang="ts">
/**
 * 私有域左侧导航（ui-design.md 第二节、第八节）。
 *
 * - 中间只放全局功能：笔记、搜索、标签、作品集；
 * - 「设置 / 退出登录」收进底部用户信息区，点击后向上弹出；
 * - Mini 模式只留居中图标与头像，悬停显示 Tooltip；
 * - 折叠状态由 ui store 管理并持久化到 localStorage。
 */
import { computed, ref, watch } from 'vue'
import { PopoverContent, PopoverPortal, PopoverRoot, PopoverTrigger } from 'reka-ui'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { logout } from '@/api/auth'
import {
  ChevronUp,
  CircleDot,
  LayoutDashboard,
  LogOut,
  NotebookPen,
  PanelLeftClose,
  PanelLeftOpen,
  Search,
  Settings,
  Tag,
  Trash2,
  Wallet,
} from 'lucide-vue-next'
import HavenMark from '@/components/common/HavenMark.vue'

const auth = useAuthStore()
const ui = useUiStore()
const route = useRoute()
const router = useRouter()

const section = computed(() => route.meta.section ?? '')
const initial = computed(() => (auth.username ?? 'H').slice(0, 1).toUpperCase())
const mini = computed(() => ui.sidebarMini)

const userMenuOpen = ref(false)

function closeUserMenu(): void {
  userMenuOpen.value = false
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

// 点外部 / Esc 交给 Reka Popover；折叠或换页时仍然主动收起，避免菜单悬在半空
</script>

<template>
  <nav class="sidebar" :class="{ 'sidebar--mini': mini }" aria-label="主导航">
    <div class="sidebar__top">
      <RouterLink :to="{ name: 'home' }" class="sidebar__brand" data-tip="Haven" aria-label="Haven 首页">
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
        <PanelLeftOpen v-if="mini" aria-hidden="true" />
        <PanelLeftClose v-else aria-hidden="true" />
      </button>
    </div>

    <RouterLink
      :to="{ name: 'home' }"
      class="side-link"
      :class="{ 'side-link--active': section === 'home' }"
      data-tip="仪表盘"
      aria-label="仪表盘"
    >
      <LayoutDashboard aria-hidden="true" />
      <span>仪表盘</span>
    </RouterLink>

    <span class="sidebar__label">浏览</span>

    <RouterLink
      :to="{ name: 'workbench' }"
      class="side-link"
      :class="{ 'side-link--active': section === 'notes' }"
      data-tip="笔记"
      aria-label="笔记"
    >
      <NotebookPen aria-hidden="true" />
      <span>笔记</span>
    </RouterLink>

    <RouterLink
      :to="{ name: 'search' }"
      class="side-link"
      :class="{ 'side-link--active': section === 'search' }"
      data-tip="搜索"
      aria-label="搜索"
    >
      <Search aria-hidden="true" />
      <span>搜索</span>
    </RouterLink>

    <RouterLink
      :to="{ name: 'tags' }"
      class="side-link"
      :class="{ 'side-link--active': section === 'tags' }"
      data-tip="标签"
      aria-label="标签"
    >
      <Tag aria-hidden="true" />
      <span>标签</span>
    </RouterLink>

    <RouterLink
      :to="{ name: 'ledger' }"
      class="side-link"
      :class="{ 'side-link--active': section === 'ledger' }"
      data-tip="记账"
      aria-label="记账"
    >
      <Wallet aria-hidden="true" />
      <span>记账</span>
    </RouterLink>

    <RouterLink
      :to="{ name: 'issues' }"
      class="side-link"
      :class="{ 'side-link--active': section === 'issues' }"
      data-tip="Issue"
      aria-label="Issue"
    >
      <CircleDot aria-hidden="true" />
      <span>Issue</span>
    </RouterLink>

    <div class="sidebar__spacer"></div>

    <RouterLink
      :to="{ name: 'trash' }"
      class="side-link"
      :class="{ 'side-link--active': section === 'trash' }"
      data-tip="回收站"
      aria-label="回收站"
    >
      <Trash2 aria-hidden="true" />
      <span>回收站</span>
    </RouterLink>

    <PopoverRoot v-model:open="userMenuOpen">
    <div class="sidebar__user">
      <!-- 触发按钮必须包在 PopoverTrigger 里：否则它只是个普通 button，
           aria-expanded 永远是 false，点了没有任何反应。
           PopoverTrigger 自带 onClick 与 aria-expanded / aria-controls，
           这里不要再手写同名属性，避免覆盖它算出的值。 -->
      <PopoverTrigger as-child>
        <button
          class="user-trigger"
          type="button"
          :data-tip="mini ? '账户' : undefined"
          aria-haspopup="menu"
          aria-label="账户菜单"
        >
          <span class="avatar" aria-hidden="true">{{ initial }}</span>
          <span class="sidebar__user-info">
            <span>{{ auth.username ?? '未登录' }}</span>
            <span class="muted">个人空间</span>
          </span>
          <ChevronUp class="user-trigger__chevron" aria-hidden="true" />
        </button>
      </PopoverTrigger>

      <!-- 向上弹出的用户菜单：定位与关闭逻辑交给 Reka Popover -->
      <PopoverPortal>
        <PopoverContent class="user-menu" side="top" align="start" :side-offset="6" @open-auto-focus.prevent>
        <RouterLink :to="{ name: 'settings' }" class="user-menu__item" role="menuitem" @click="closeUserMenu">
          <Settings aria-hidden="true" />
          设置
        </RouterLink>

        <button class="user-menu__item user-menu__item--danger" type="button" role="menuitem" @click="signOut">
          <LogOut aria-hidden="true" />
          退出登录
        </button>
        </PopoverContent>
      </PopoverPortal>
    </div>
    </PopoverRoot>
  </nav>
</template>
