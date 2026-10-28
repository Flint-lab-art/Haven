<script setup lang="ts">
/** 账号安全：修改密码、绑定 / 关闭 TOTP。 */
import { onMounted, reactive, ref } from 'vue'
import PrivateHeader from '@/components/PrivateHeader.vue'
import SettingsNav from '@/components/SettingsNav.vue'
import { ApiError } from '@/api/client'
import { changePassword, disableTotp, setupTotp, verifyTotp } from '@/api/auth'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()

const pw = reactive({ oldPassword: '', newPassword: '', totpCode: '' })
const pwError = ref('')
const pwNotice = ref('')
const pwBusy = ref(false)

const setup = ref<{ secret: string; otpauth_uri: string } | null>(null)
const bindCode = ref('')
const bindError = ref('')
const bindBusy = ref(false)

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
    await auth.refresh()
  } catch (err) {
    disableError.value = describe(err, '关闭失败')
  }
}

onMounted(() => void auth.refresh())
</script>

<template>
  <div class="shell">
    <PrivateHeader />

    <main class="container">
      <header class="page-head">
        <div>
          <h1 class="page-title">账号安全</h1>
          <p class="page-sub">密码与双重验证</p>
        </div>
      </header>

      <div class="settings-layout">
        <SettingsNav />

        <div class="stack">
          <!-- 动态验证码（是否已启用是这页最重要的状态，放最前） -->
          <section class="panel panel--pad">
            <div class="row" style="justify-content: space-between; align-items: flex-start">
              <div>
                <h2 class="row-item__title" style="font: var(--text-title3)">动态验证码</h2>
                <p class="field__hint" style="margin-top: 4px">
                  {{
                    auth.totpEnabled
                      ? '已启用。管理 Token、修改密码等操作需要动态码。'
                      : '尚未启用。绑定后登录需要第二步验证，更安全。'
                  }}
                </p>
              </div>
              <span :class="auth.totpEnabled ? 'badge badge--public' : 'badge badge--private'">
                {{ auth.totpEnabled ? '已启用' : '未启用' }}
              </span>
            </div>

            <div class="divider"></div>

            <template v-if="!auth.totpEnabled">
              <button v-if="!setup" class="btn" type="button" @click="beginSetup">开始绑定</button>

              <template v-else>
                <p class="field__hint">
                  在验证器 App 里手动输入下面的密钥（或用 otpauth 链接导入），然后输入它显示的 6 位码。
                </p>
                <p class="code-block">{{ setup.secret }}</p>
                <p class="code-block" style="font-size: 11px; color: var(--label-2)">{{ setup.otpauth_uri }}</p>

                <div class="field" style="margin-top: var(--sp-4)">
                  <label class="field__label" for="bind-code">6 位动态码</label>
                  <input
                    id="bind-code"
                    v-model="bindCode"
                    class="input code-input"
                    inputmode="numeric"
                    maxlength="6"
                    placeholder="······"
                  />
                </div>
                <p v-if="bindError" class="notice notice--error" style="margin-top: var(--sp-3)">{{ bindError }}</p>

                <div class="row" style="margin-top: var(--sp-4)">
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
                <input
                  id="disable-code"
                  v-model="disableCode"
                  class="input code-input"
                  inputmode="numeric"
                  maxlength="6"
                  placeholder="······"
                  style="max-width: 220px"
                />
              </div>
              <p v-if="disableError" class="notice notice--error" style="margin-top: var(--sp-3)">{{ disableError }}</p>
              <p class="field__hint" style="margin-top: var(--sp-3)">关闭后所有授信设备会被一并删除。</p>
              <button class="btn btn--danger" type="button" style="margin-top: var(--sp-3)" @click="confirmDisable">
                关闭动态验证码
              </button>
            </template>
          </section>

          <!-- 修改密码 -->
          <form class="panel panel--pad" @submit.prevent="submitPassword">
            <h2 class="row-item__title" style="font: var(--text-title3)">修改密码</h2>
            <p class="field__hint" style="margin-top: 4px">
              修改后所有会话与授信设备都会失效；API Token 不受影响。
            </p>

            <div class="field" style="margin-top: var(--sp-4)">
              <label class="field__label" for="old-password">原密码</label>
              <input id="old-password" v-model="pw.oldPassword" class="input" type="password" autocomplete="current-password" required />
            </div>
            <div class="field" style="margin-top: var(--sp-3)">
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
            <div v-if="auth.totpEnabled" class="field" style="margin-top: var(--sp-3)">
              <label class="field__label" for="pw-totp">动态码</label>
              <input id="pw-totp" v-model="pw.totpCode" class="input code-input" inputmode="numeric" maxlength="6" placeholder="······" style="max-width: 220px" />
            </div>

            <p v-if="pwError" class="notice notice--error" style="margin-top: var(--sp-3)">{{ pwError }}</p>
            <p v-if="pwNotice" class="notice notice--success" style="margin-top: var(--sp-3)">{{ pwNotice }}</p>

            <button class="btn btn--primary" type="submit" :disabled="pwBusy" style="margin-top: var(--sp-4)">
              修改密码
            </button>
          </form>
        </div>
      </div>
    </main>
  </div>
</template>
