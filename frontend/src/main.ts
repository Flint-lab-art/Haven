import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './style.css'
import App from './App.vue'
import { createHavenRouter } from './router'
import { useAuthStore } from './stores/auth'
import { useThemeStore } from './stores/theme'

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
