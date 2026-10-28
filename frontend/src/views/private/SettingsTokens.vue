<script setup lang="ts">
/**
 * API Token 管理（docs/frontend/frontend.md 第四节 /settings/tokens）。
 *
 * 该页面需要「会话已通过过 TOTP」。若收到 403，只在页面内提示并引导去
 * /settings/security，不强制登出（docs/frontend/frontend.md 第四节规则最后一条）。
 */
import { onMounted, reactive, ref } from 'vue'
import { RouterLink } from 'vue-router'
import PrivateHeader from '@/components/PrivateHeader.vue'
import SettingsNav from '@/components/SettingsNav.vue'
import { ApiError } from '@/api/client'
import { createToken, listTokens, revokeToken, type CreatedToken, type TokenItem } from '@/api/tokens'
import { formatDateTime, formatRelative } from '@/utils/format'

const tokens = ref<TokenItem[]>([])
const loading = ref(true)
const forbidden = ref(false)
const error = ref('')
const creating = ref(false)
/** 新建后一次性展示的明文，刷新即丢失。 */
const created = ref<CreatedToken | null>(null)
const copied = ref(false)

const form = reactive({
  name: '',
  scope: 'read_write' as 'read' | 'read_write',
  neverExpires: true,
  expiresAt: '',
})

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  forbidden.value = false
  try {
    tokens.value = (await listTokens()).items
  } catch (err) {
    if (err instanceof ApiError && err.isForbidden) {
      forbidden.value = true
    } else {
      error.value = err instanceof ApiError ? err.message : 'Token 列表加载失败'
    }
  } finally {
    loading.value = false
  }
}

async function create(): Promise<void> {
  const name = form.name.trim()
  if (!name || creating.value) return

  creating.value = true
  error.value = ''
  copied.value = false
  try {
    created.value = await createToken({
      name,
      scope: form.scope,
      expires_at: form.neverExpires || !form.expiresAt ? null : new Date(form.expiresAt).toISOString(),
    })
    form.name = ''
    await load()
  } catch (err) {
    if (err instanceof ApiError && err.isForbidden) {
      forbidden.value = true
    } else {
      error.value = err instanceof ApiError ? err.message : '创建失败'
    }
  } finally {
    creating.value = false
  }
}

async function copy(): Promise<void> {
  if (!created.value) return
  try {
    await navigator.clipboard.writeText(created.value.token)
    copied.value = true
  } catch {
    // 剪贴板不可用时用户可手动选中复制
  }
}

async function revoke(item: TokenItem): Promise<void> {
  if (!window.confirm(`撤销 Token「${item.name}」？使用它的脚本会立即失效。`)) return

  error.value = ''
  try {
    await revokeToken(item.id)
    await load()
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '撤销失败'
  }
}

onMounted(load)
</script>

<template>
  <PrivateHeader />

  <main class="page page--wide">
    <h1 class="page-title" style="margin-bottom: 24px">API Token</h1>

    <div class="settings-layout">
      <SettingsNav />

      <div class="stack">
        <!-- 未通过 TOTP：引导而不是登出 -->
        <section v-if="forbidden" class="panel panel--padded stack">
          <h2 class="card__title">管理 Token 需要完成动态码验证</h2>
          <p class="field__hint">
            当前会话不是通过动态码建立的。请到「账号安全」完成验证后再回来。
          </p>
          <RouterLink :to="{ name: 'settings-security' }" class="btn btn--primary" style="align-self: flex-start">
            去账号安全
          </RouterLink>
        </section>

        <template v-else>
          <p v-if="error" class="notice notice--error">{{ error }}</p>

          <!-- 一次性明文 -->
          <section v-if="created" class="panel panel--padded stack">
            <h2 class="card__title">新 Token 已创建</h2>
            <p class="field__hint">明文只显示这一次，离开页面后无法再获取。</p>
            <code class="totp-uri">{{ created.token }}</code>
            <div class="row">
              <button class="btn btn--primary" type="button" @click="copy">
                {{ copied ? '已复制' : '复制' }}
              </button>
              <button class="btn" type="button" @click="created = null">已保存，关闭</button>
            </div>
          </section>

          <!-- 新建 -->
          <form class="panel panel--padded stack" @submit.prevent="create">
            <h2 class="card__title">新建 Token</h2>
            <div class="field">
              <label class="field__label" for="token-name">名称</label>
              <input id="token-name" v-model="form.name" class="input" type="text" placeholder="脚本 @ 家里" required />
            </div>
            <div class="field">
              <label class="field__label" for="token-scope">权限</label>
              <select id="token-scope" v-model="form.scope" class="select">
                <option value="read">只读（read）</option>
                <option value="read_write">读写（read_write）</option>
              </select>
            </div>
            <label class="checkbox-row">
              <input v-model="form.neverExpires" type="checkbox" />
              永不过期
            </label>
            <div v-if="!form.neverExpires" class="field">
              <label class="field__label" for="token-expiry">过期时间</label>
              <input id="token-expiry" v-model="form.expiresAt" class="input" type="datetime-local" />
            </div>
            <button class="btn btn--primary" type="submit" :disabled="creating">创建</button>
          </form>

          <!-- 列表 -->
          <div v-if="loading" class="panel panel--padded">
            <div class="skeleton" style="width: 50%"></div>
          </div>

          <div v-else-if="tokens.length === 0" class="panel empty">
            <p class="empty__title">还没有 Token</p>
            <p>给脚本或编辑器插件创建一个，避免直接使用密码。</p>
          </div>

          <ul v-else class="panel list">
            <li v-for="item in tokens" :key="item.id" class="list__row">
              <div class="list__row-main">
                <div class="card__title">
                  {{ item.name }}
                  <span v-if="item.revoked_at" class="tag" style="margin-left: 6px">已撤销</span>
                </div>
                <div class="card__meta">
                  <span class="mono">{{ item.token_prefix }}…</span>
                  <span>· {{ item.scope === 'read' ? '只读' : '读写' }}</span>
                  <span v-if="item.expires_at">· 到期 {{ formatDateTime(item.expires_at) }}</span>
                  <span v-else>· 永不过期</span>
                  <span v-if="item.last_used_at">· 最近使用 {{ formatRelative(item.last_used_at) }}</span>
                </div>
              </div>
              <button
                v-if="!item.revoked_at"
                class="btn btn--small btn--danger"
                type="button"
                @click="revoke(item)"
              >
                撤销
              </button>
            </li>
          </ul>
        </template>
      </div>
    </div>
  </main>
</template>
