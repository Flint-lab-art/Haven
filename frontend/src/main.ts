import { createApp } from 'vue'
import { createPinia } from 'pinia'
// 代码块暗色主题（docs-ai/v7/frontend/frontend.md 第六节）
import 'highlight.js/styles/github-dark-dimmed.css'
import './style.css'
import App from './App.vue'
import { loadRuntimeConfig } from './config'
import { createHavenRouter } from './router'
import { useAuthStore } from './stores/auth'
import { useThemeStore } from './stores/theme'

async function bootstrap(): Promise<void> {
  // 先取运行时配置：同一份构建产物按域名决定加载公开路由还是私有路由
  await loadRuntimeConfig()

  const pinia = createPinia()
  const router = createHavenRouter()

  // 主题要在首次渲染前应用，否则深色主题会先闪一下白底
  useThemeStore(pinia).init()

  // 401 全局处理：清空登录态并回登录页（docs/frontend/frontend.md 第六节）
  const auth = useAuthStore(pinia)
  auth.installUnauthorizedHandler(() => {
    const current = router.currentRoute.value
    if (current.name === 'login') return
    void router.push({ name: 'login', query: { redirect: current.fullPath } })
  })

  const app = createApp(App)
  app.use(pinia)
  app.use(router)
  app.mount('#app')
}

void bootstrap()
