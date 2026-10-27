import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'

export const routes: RouteRecordRaw[] = []

// History 模式，见 docs/architecture.md 第一节与 docs/frontend/frontend.md。
// 公开域与私有域的页面在后续任务中按 window.location.hostname 分表加入。
const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
