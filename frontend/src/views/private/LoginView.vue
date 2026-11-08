<script setup lang="ts">
/**
 * 登录页。temp_token 只放在内存里，刷新即失效（docs/frontend/frontend.md 第五节）。
 */
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import HavenMark from '@/components/HavenMark.vue'
import LoginForm from '@/components/LoginForm.vue'
import TotpForm from '@/components/TotpForm.vue'
import { useAuthStore } from '@/stores/auth'
import type { LoginResult } from '@/api/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const step = ref<'password' | 'totp'>('password')
const tempToken = ref('')
const expiredNotice = ref('')

function targetPath(): string {
  const redirect = route.query.redirect
  const path = typeof redirect === 'string' ? redirect : '/'
  // 只接受站内相对路径，避免开放重定向
  return path.startsWith('/') && !path.startsWith('//') ? path : '/'
}

async function goAfterLogin(result: LoginResult): Promise<void> {
  auth.markLoggedIn(result.user)
  step.value = 'password'
  tempToken.value = ''
  await router.replace(targetPath())
}

function onTotpRequired(result: LoginResult): void {
  tempToken.value = result.temp_token ?? ''
  step.value = 'totp'
}

function onExpired(): void {
  step.value = 'password'
  tempToken.value = ''
  expiredNotice.value = '登录已超时，请重新登录'
}
</script>

<template>
  <div class="auth-shell">
    <main class="auth-card">
      <HavenMark class="auth-card__mark brand-mark" :size="40" />

      <h1 class="auth-card__title">
        {{ step === 'password' ? '登录 Haven' : '两步验证' }}
      </h1>
      <p class="auth-card__sub">
        {{ step === 'password' ? '管理你的私有笔记' : '输入验证器 App 显示的动态码' }}
      </p>

      <p v-if="expiredNotice && step === 'password'" class="notice notice--info" style="margin-bottom: var(--sp-4)">
        {{ expiredNotice }}
      </p>

      <TotpForm
        v-if="step === 'totp'"
        :temp-token="tempToken"
        @success="goAfterLogin"
        @expired="onExpired"
      />
      <LoginForm v-else @success="goAfterLogin" @totp-required="onTotpRequired" />
    </main>
  </div>
</template>
