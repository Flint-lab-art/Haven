<script setup lang="ts">
/** 登录页（docs/frontend/frontend.md 第五节）。temp_token 只放内存，不落 localStorage。 */
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import LoginForm from '@/components/LoginForm.vue'
import TotpForm from '@/components/TotpForm.vue'
import { useAuthStore } from '@/stores/auth'
import type { LoginResult } from '@/api/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const step = ref<'password' | 'totp'>('password')
/** 第二步使用，页面刷新即丢失（符合“不落 localStorage”的要求）。 */
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
  <main class="page" style="max-width: 420px; padding-top: 64px">
    <div class="panel panel--padded">
      <h1 class="page-title" style="font: var(--text-title1); margin-bottom: 4px">Haven</h1>
      <p class="page-subtitle" style="margin-bottom: 24px">
        {{ step === 'password' ? '登录后管理你的笔记' : '输入动态码完成登录' }}
      </p>

      <p v-if="expiredNotice && step === 'password'" class="notice notice--info" style="margin-bottom: 16px">
        {{ expiredNotice }}
      </p>

      <TotpForm
        v-if="step === 'totp'"
        :temp-token="tempToken"
        @success="goAfterLogin"
        @expired="onExpired"
      />
      <LoginForm v-else @success="goAfterLogin" @totp-required="onTotpRequired" />
    </div>
  </main>
</template>
