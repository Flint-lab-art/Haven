<script setup lang="ts">
/**
 * API Token 管理。需要「会话已通过过 TOTP」；403 时只在页面内引导，不登出
 * （docs/frontend/frontend.md 第四节规则最后一条）。
 */
import { onMounted, reactive, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { ApiError } from '@/api/client'
import { createToken, listTokens, revokeToken, type CreatedToken, type TokenItem } from '@/api/tokens'
import { formatDateTime, formatRelative } from '@/utils/format'

const tokens = ref<TokenItem[]>([])
const loading = ref(true)
const forbidden = ref(false)
const error = ref('')
const creating = ref(false)
const created = ref<CreatedToken | null>(null)
const copied = ref(false)
const showNew = ref(false)

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
    showNew.value = false
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
  <div class="detail-inner">
    <header class="detail-head row" style="justify-content: space-between; align-items: flex-end">
      <div>
        <h1 class="detail-title">API Token</h1>
        <p class="detail-sub">
          {{ loading ? '加载中…' : `${tokens.filter((t) => !t.revoked_at).length} 个有效凭证` }}
        </p>
      </div>
      <button
        v-if="!forbidden"
        class="btn btn--primary"
        type="button"
        @click="showNew = !showNew"
      >
        {{ showNew ? '收起' : '新建 Token' }}
      </button>
    </header>

    <div class="stack">
          <!-- 403：引导完成 TOTP 验证，不登出 -->
          <section v-if="forbidden" class="panel panel--pad">
            <h2 class="row-item__title" style="font: var(--text-title3)">管理 Token 需要完成动态码验证</h2>
            <p class="field__hint" style="margin-top: var(--sp-2)">
              当前会话不是通过动态码建立的。去「账号安全」绑定并验证后，重新登录即可管理 Token。
            </p>
            <RouterLink :to="{ name: 'settings-security' }" class="btn btn--primary" style="margin-top: var(--sp-4)">
              去账号安全
            </RouterLink>
          </section>

          <template v-else>
            <p v-if="error" class="notice notice--error">{{ error }}</p>

            <!-- 一次性明文 -->
            <section v-if="created" class="panel panel--pad" style="border: 1px solid var(--success)">
              <span class="badge badge--public">已创建</span>
              <p class="field__hint" style="margin-top: var(--sp-2)">
                明文只显示这一次，离开页面后无法再获取。现在就复制保存。
              </p>
              <p class="code-block" style="margin-top: var(--sp-3)">{{ created.token }}</p>
              <div class="row" style="margin-top: var(--sp-4)">
                <button class="btn btn--primary" type="button" @click="copy">
                  {{ copied ? '已复制' : '复制' }}
                </button>
                <button class="btn" type="button" @click="created = null">我已保存</button>
              </div>
            </section>

            <form v-if="showNew" class="panel panel--pad" @submit.prevent="create">
              <div class="field">
                <label class="field__label" for="token-name">名称</label>
                <input id="token-name" v-model="form.name" class="input" type="text" placeholder="脚本 @ 家里" required />
              </div>
              <div class="field" style="margin-top: var(--sp-3)">
                <label class="field__label" for="token-scope">权限</label>
                <select id="token-scope" v-model="form.scope" class="select">
                  <option value="read">只读 — 只能查看</option>
                  <option value="read_write">读写 — 可增删改</option>
                </select>
              </div>
              <label class="checkbox-row" style="margin-top: var(--sp-4)">
                <input v-model="form.neverExpires" type="checkbox" />
                永不过期
              </label>
              <div v-if="!form.neverExpires" class="field" style="margin-top: var(--sp-3)">
                <label class="field__label" for="token-expiry">过期时间</label>
                <input id="token-expiry" v-model="form.expiresAt" class="input" type="datetime-local" />
              </div>
              <div class="row" style="justify-content: flex-end; margin-top: var(--sp-4)">
                <button class="btn" type="button" @click="showNew = false">取消</button>
                <button class="btn btn--primary" type="submit" :disabled="creating">创建</button>
              </div>
            </form>

            <div v-if="loading" class="panel panel--pad">
              <div class="skeleton skeleton--title" style="width: 44%"></div>
            </div>

            <div v-else-if="tokens.length === 0" class="panel empty">
              <p class="empty__title">还没有 Token</p>
              <p class="empty__text">给脚本或编辑器插件创建一个，避免在任何地方直接使用密码。</p>
              <button class="btn btn--primary" type="button" @click="showNew = true">新建 Token</button>
            </div>

            <ul v-else class="panel rows">
              <li v-for="item in tokens" :key="item.id" class="row-item">
                <div class="row-item__main">
                  <div class="row-item__title">
                    {{ item.name }}
                    <span v-if="item.revoked_at" class="badge badge--private">已撤销</span>
                  </div>
                  <div class="row-item__sub">
                    <span class="mono">{{ item.token_prefix }}…</span>
                    · {{ item.scope === 'read' ? '只读' : '读写' }}
                    <template v-if="item.expires_at"> · {{ formatDateTime(item.expires_at) }} 到期</template>
                    <template v-else> · 永不过期</template>
                    <template v-if="item.last_used_at"> · 最近使用 {{ formatRelative(item.last_used_at) }}</template>
                  </div>
                </div>
                <button
                  v-if="!item.revoked_at"
                  class="btn btn--sm btn--danger"
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
</template>
