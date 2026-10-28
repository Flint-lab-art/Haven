<script setup lang="ts">
/** 登录第一步：账号密码。 */
import { ref } from 'vue'
import { ApiError } from '@/api/client'
import { login, type LoginResult } from '@/api/auth'

const emit = defineEmits<{
  success: [result: LoginResult]
  'totp-required': [result: LoginResult]
}>()

const username = ref('')
const password = ref('')
const trustDevice = ref(false)
const error = ref('')
const fieldErrors = ref<Record<string, string>>({})
const submitting = ref(false)

async function submit(): Promise<void> {
  if (submitting.value) return
  error.value = ''
  fieldErrors.value = {}
  submitting.value = true

  try {
    const result = await login(username.value.trim(), password.value, trustDevice.value)
    password.value = ''
    if (result.totp_required) {
      emit('totp-required', result)
    } else {
      emit('success', result)
    }
  } catch (err) {
    if (err instanceof ApiError) {
      error.value = err.message
      fieldErrors.value = err.fields ?? {}
    } else {
      error.value = '登录失败，请稍后重试'
    }
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <form class="stack" @submit.prevent="submit">
    <div class="field">
      <label class="field__label" for="login-username">用户名</label>
      <input
        id="login-username"
        v-model="username"
        class="input"
        type="text"
        autocomplete="username"
        autocapitalize="off"
        spellcheck="false"
        required
      />
      <span v-if="fieldErrors.username" class="field__error">{{ fieldErrors.username }}</span>
    </div>

    <div class="field">
      <label class="field__label" for="login-password">密码</label>
      <input
        id="login-password"
        v-model="password"
        class="input"
        type="password"
        autocomplete="current-password"
        required
      />
      <span v-if="fieldErrors.password" class="field__error">{{ fieldErrors.password }}</span>
    </div>

    <label class="checkbox-row">
      <input v-model="trustDevice" type="checkbox" />
      信任这台设备，30 天内免动态码
    </label>

    <p v-if="error" class="notice notice--error" role="alert">{{ error }}</p>

    <button class="btn btn--primary btn--block btn--lg" type="submit" :disabled="submitting">
      {{ submitting ? '登录中…' : '登录' }}
    </button>

    <p class="field__hint" style="text-align: center">公共电脑上请勿勾选“信任这台设备”。</p>
  </form>
</template>
