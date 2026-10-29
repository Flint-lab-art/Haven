<script setup lang="ts">
/** 会话管理。 */
import { onMounted, ref } from 'vue'
import PrivateHeader from '@/components/PrivateHeader.vue'
import SettingsNav from '@/components/SettingsNav.vue'
import { ApiError } from '@/api/client'
import { listSessions, revokeSession, type SessionItem } from '@/api/sessions'
import { formatDateTime, deviceLabel, formatRelative } from '@/utils/format'

const sessions = ref<SessionItem[]>([])
const loading = ref(true)
const error = ref('')

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    sessions.value = (await listSessions()).items
  } catch (err) {
    error.value =
      err instanceof ApiError && err.isForbidden
        ? 'API Token 无法查看会话列表，请用浏览器登录后查看'
        : '会话加载失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

async function revoke(item: SessionItem): Promise<void> {
  if (!window.confirm(`结束「${deviceLabel(item.user_agent)}」上的会话？`)) return

  error.value = ''
  try {
    await revokeSession(item.id)
    await load()
  } catch (err) {
    if (err instanceof ApiError && err.status === 422) {
      error.value = '当前会话请用右上角的“退出”结束'
    } else {
      error.value = err instanceof ApiError ? err.message : '操作失败'
    }
  }
}

onMounted(load)
</script>

<template>
  <div class="shell">
    <PrivateHeader />

    <main class="container">
      <header class="page-head">
        <div>
          <h1 class="page-title">会话</h1>
          <p class="page-sub">在公共电脑上用完登录后，可以在这里结束那台设备的会话</p>
        </div>
      </header>

      <div class="settings-layout">
        <SettingsNav />

        <div class="stack">
          <p v-if="error" class="notice notice--error">{{ error }}</p>

          <div v-if="loading" class="panel panel--pad">
            <div class="skeleton skeleton--title" style="width: 46%"></div>
          </div>

          <div v-else-if="sessions.length === 0" class="panel empty">
            <p class="empty__title">没有活跃会话</p>
            <p class="empty__text">当前设备上线后会出现在这里。</p>
          </div>

          <ul v-else class="panel rows">
            <li v-for="item in sessions" :key="item.id" class="row-item">
              <div class="row-item__main">
                <div class="row-item__title">
                  {{ deviceLabel(item.user_agent) }}
                  <span v-if="item.is_current" class="badge badge--public">当前设备</span>
                </div>
                <div class="row-item__sub">
                  登录于 {{ formatDateTime(item.created_at) }} · 最近使用 {{ formatRelative(item.last_used_at) }}
                </div>
              </div>
              <button
                v-if="!item.is_current"
                class="btn btn--sm btn--danger"
                type="button"
                @click="revoke(item)"
              >
                结束
              </button>
              <span v-else class="field__hint">不可从这里结束</span>
            </li>
          </ul>
        </div>
      </div>
    </main>
  </div>
</template>
