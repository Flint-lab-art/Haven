import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './style.css'
import App from './App.vue'
import { createHavenRouter } from './router'
import { useAuthStore } from './stores/auth'

const pinia = createPinia()
const router = createHavenRouter()

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
