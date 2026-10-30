/**
 * 登录态 store（docs/frontend/frontend.md 第六节）。
 *
 * - 启动时调 GET /api/me 初始化；
 * - 401 统一清空并跳 /login（由 api/client 的全局回调触发）；
 * - 403 只提示，不跳转。
 */
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getMe, type MeResponse } from '@/api/me'
import { setUnauthorizedHandler } from '@/api/client'

/** 当前身份：匿名 / 会话 / Token。 */
export type AuthType = 'anonymous' | 'session' | 'token'

export const useAuthStore = defineStore('auth', () => {
  const initialized = ref(false)
  const userId = ref<string | null>(null)
  const username = ref<string | null>(null)
  const authType = ref<AuthType>('anonymous')
  const totpEnabled = ref(false)
  /** Token 身份才有 scope；会话身份为 null。 */
  const scope = ref<'read' | 'read_write' | null>(null)

  const isLoggedIn = computed(() => authType.value !== 'anonymous')
  const isSession = computed(() => authType.value === 'session')
  /** 只有 read_write 的 Token 才能写（docs/api.md 1.6）。 */
  const canWrite = computed(() => authType.value === 'session' || scope.value === 'read_write')

  function apply(me: MeResponse): void {
    if (me.anonymous) {
      clear()
      return
    }
    authType.value = me.auth_type ?? 'session'
    userId.value = me.user?.id ?? null
    username.value = me.user?.username ?? null
    totpEnabled.value = me.user?.totp_enabled ?? false
    scope.value = me.scope ?? null
  }

  function clear(): void {
    userId.value = null
    username.value = null
    authType.value = 'anonymous'
    totpEnabled.value = false
    scope.value = null
  }

  /** 启动或刷新登录态。失败不抛错，按未登录处理。 */
  async function refresh(): Promise<void> {
    try {
      apply(await getMe())
    } catch {
      clear()
    } finally {
      initialized.value = true
    }
  }

  /** 登录成功后调用，避免再打一次 /api/me。 */
  function markLoggedIn(user: { id: string; username: string }): void {
    authType.value = 'session'
    userId.value = user.id
    username.value = user.username
    scope.value = null
  }

  /**
   * 注册全局 401 处理：清空 store 并回登录页（保留当前路径供登录后跳回）。
   * 由 main.ts 在 router 就绪后调用一次。
   */
  function installUnauthorizedHandler(redirect: () => void): void {
    setUnauthorizedHandler(() => {
      const wasLoggedIn = isLoggedIn.value
      clear()
      if (wasLoggedIn) {
        redirect()
      }
    })
  }

  return {
    initialized,
    userId,
    username,
    authType,
    totpEnabled,
    scope,
    isLoggedIn,
    isSession,
    canWrite,
    refresh,
    clear,
    markLoggedIn,
    installUnauthorizedHandler,
  }
})
