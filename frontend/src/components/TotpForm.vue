<script setup lang="ts">
/** 登录第二步：6 位动态码。temp_token 只存在于父组件内存里。 */
import { ref } from 'vue'
import { ApiError } from '@/api/client'
import { loginTotp, type LoginResult } from '@/api/auth'

const props = defineProps<{ tempToken: string }>()
const emit = defineEmits<{
  success: [result: LoginResult]
  expired: []
}>()

const code = ref('')
const error = ref('')
const submitting = ref(false)

async function submit(): Promise<void> {
  if (submitting.value) return
  error.value = ''
  submitting.value = true

  try {
    const result = await loginTotp(props.tempToken, code.value.trim())
    code.value = ''
    emit('success', result)
  } catch (err) {
    if (err instanceof ApiError) {
      error.value = err.message
      // 临时 token 过期或无效 → 回到账号密码步骤
      if (err.status === 401 && err.message.includes('超时')) {
        emit('expired')
      }
    } else {
      error.value = '验证失败，请稍后重试'
    }
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <form class="stack" @submit.prevent="submit">
    <div class="field">
      <label class="field__label" for="totp-code">输入 6 位动态码</label>
      <input
        id="totp-code"
        v-model="code"
        class="input code-input"
        type="text"
        inputmode="numeric"
        autocomplete="one-time-code"
        maxlength="6"
        placeholder="······"
        required
      />
      <span class="field__hint">打开验证器 App，输入当前显示的 6 位数字。5 分钟内有效。</span>
    </div>

    <p v-if="error" class="notice notice--error" role="alert">{{ error }}</p>

    <button class="btn btn--primary btn--block btn--lg" type="submit" :disabled="submitting">
      {{ submitting ? '验证中…' : '验证并登录' }}
    </button>

    <button class="btn btn--quiet btn--block" type="button" @click="emit('expired')">
      返回重新输入密码
    </button>
  </form>
</template>
