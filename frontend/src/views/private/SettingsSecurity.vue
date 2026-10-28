<script setup lang="ts">
/** 账号安全（docs/frontend/frontend.md 第四节 /settings/security）。 */
import { onMounted, reactive, ref } from 'vue'
import PrivateHeader from '@/components/PrivateHeader.vue'
import SettingsNav from '@/components/SettingsNav.vue'
import { ApiError } from '@/api/client'
import { changePassword, disableTotp, setupTotp, verifyTotp } from '@/api/auth'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()

// 修改密码
const pw = reactive({ oldPassword: '', newPassword: '', totpCode: '' })
const pwError = ref('')
const pwNotice = ref('')
const pwBusy = ref(false)

// 绑定 TOTP
const setup = ref<{ secret: string; otpauth_uri: string } | null>(null)
const bindCode = ref('')
const bindError = ref('')
const bindBusy = ref(false)

// 关闭 TOTP
const disableCode = ref('')
const disableError = ref('')

function describe(err: unknown, fallback: string): string {
  if (err instanceof ApiError) {
    if (err.fields) return Object.values(err.fields).join('；')
    return err.message
  }
  return fallback
}

async function submitPassword(): Promise<void> {
  if (pwBusy.value) return
  pwBusy.value = true
  pwError.value = ''
  pwNotice.value = ''

  try {
    await changePassword(pw.oldPassword, pw.newPassword, pw.totpCode)
    pw.oldPassword = ''
    pw.newPassword = ''
    pw.totpCode = ''
    auth.clear()
    pwNotice.value = '密码已修改，所有会话已失效，请重新登录'
  } catch (err) {
    pwError.value = describe(err, '修改失败，请稍后重试')
  } finally {
    pwBusy.value = false
  }
}

async function beginSetup(): Promise<void> {
  bindError.value = ''
  try {
    setup.value = await setupTotp()
  } catch (err) {
    bindError.value = describe(err, '获取密钥失败')
  }
}

async function confirmBind(): Promise<void> {
  if (!setup.value || bindBusy.value) return
  bindBusy.value = true
  bindError.value = ''

  try {
    await verifyTotp(setup.value.secret, bindCode.value.trim())
    setup.value = null
    bindCode.value = ''
    await auth.refresh()
  } catch (err) {
    bindError.value = describe(err, '验证失败')
  } finally {
    bindBusy.value = false
  }
}

async function confirmDisable(): Promise<void> {
  disableError.value = ''
  try {
    await disableTotp(disableCode.value.trim())
    disableCode.value = ''
    // 关闭 TOTP 会删掉全部授信设备，也会影响后续 Token 管理
    await auth.refresh()
  } catch (err) {
    disableError.value = describe(err, '关闭失败')
  }
}

onMounted(() => void auth.refresh())
</script>

<template>
  <PrivateHeader />

  <main class="page page--wide">
    <h1 class="page-title" style="margin-bottom: 24px">账号安全</h1>

    <div class="settings-layout">
      <SettingsNav />

      <div class="stack">
        <!-- 修改密码 -->
        <form class="panel panel--padded stack" @submit.prevent="submitPassword">
          <h2 class="card__title">修改密码</h2>
          <p class="field__hint">修改后所有会话与授信设备都会失效，API Token 不受影响。</p>

          <div class="field">
            <label class="field__label" for="old-password">原密码</label>
            <input id="old-password" v-model="pw.oldPassword" class="input" type="password" required />
          </div>
          <div class="field">
            <label class="field__label" for="new-password">新密码</label>
            <input
              id="new-password"
              v-model="pw.newPassword"
              class="input"
              type="password"
              autocomplete="new-password"
              minlength="12"
              required
            />
            <span class="field__hint">至少 12 位，且不能与原密码相同。</span>
          </div>
          <div v-if="auth.totpEnabled" class="field">
            <label class="field__label" for="pw-totp">动态码</label>
            <input id="pw-totp" v-model="pw.totpCode" class="input mono" inputmode="numeric" maxlength="6" />
          </div>

          <p v-if="pwError" class="notice notice--error">{{ pwError }}</p>
          <p v-if="pwNotice" class="notice notice--info">{{ pwNotice }}</p>

          <button class="btn btn--primary" type="submit" :disabled="pwBusy">修改密码</button>
        </form>

        <!-- 动态验证码 -->
        <section class="panel panel--padded stack">
          <h2 class="card__title">动态验证码</h2>
          <p class="field__hint">
            {{
              auth.totpEnabled
                ? '已启用。管理 API Token、修改密码等操作需要动态码。'
                : '尚未启用。绑定后登录需要第二步验证。'
            }}
          </p>

          <template v-if="!auth.totpEnabled">
            <button v-if="!setup" class="btn" type="button" @click="beginSetup">开始绑定</button>

            <template v-else>
              <p class="field__hint">
                在验证器 App 里添加以下密钥（或扫描 otpauth 链接），然后输入它显示的 6 位码。
              </p>
              <p class="totp-uri">{{ setup.secret }}</p>
              <p class="totp-uri">{{ setup.otpauth_uri }}</p>

              <div class="field">
                <label class="field__label" for="bind-code">6 位动态码</label>
                <input id="bind-code" v-model="bindCode" class="input mono" inputmode="numeric" maxlength="6" />
              </div>
              <p v-if="bindError" class="notice notice--error">{{ bindError }}</p>

              <div class="row">
                <button class="btn btn--primary" type="button" :disabled="bindBusy" @click="confirmBind">
                  确认绑定
                </button>
                <button class="btn" type="button" @click="setup = null">取消</button>
              </div>
            </template>
          </template>

          <template v-else>
            <div class="field">
              <label class="field__label" for="disable-code">输入当前动态码以关闭</label>
              <input id="disable-code" v-model="disableCode" class="input mono" inputmode="numeric" maxlength="6" />
            </div>
            <p v-if="disableError" class="notice notice--error">{{ disableError }}</p>
            <p class="field__hint">关闭后所有授信设备会被一并删除。</p>
            <button class="btn btn--danger" type="button" @click="confirmDisable">关闭动态验证码</button>
          </template>
        </section>
      </div>
    </div>
  </main>
</template>
