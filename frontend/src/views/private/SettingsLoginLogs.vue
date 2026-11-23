<script setup lang="ts">
/**
 * 登录日志。
 *
 * 只读当前账号的登录历史：成功、失败（密码 / 动态码）、登出。
 * 用户名输错时 `user_id` 为空，后端会按同名把这些失败尝试一并返回。
 */
import { computed, onMounted, ref } from 'vue'
import { ApiError } from '@/api/client'
import { listLoginLogs, type LoginLogEventType, type LoginLogItem } from '@/api/login-logs'
import { deviceLabel, formatDateTime, formatRelative } from '@/utils/format'

const PAGE_SIZE = 50

const logs = ref<LoginLogItem[]>([])
const total = ref(0)
const loading = ref(true)
const loadingMore = ref(false)
const error = ref('')

function message(err: unknown): string {
  if (err instanceof ApiError && err.isForbidden) {
    return 'API Token 无法查看登录日志，请用浏览器登录后查看'
  }
  return err instanceof ApiError ? err.message : '登录日志加载失败，请稍后重试'
}

async function load(): Promise<void> {
  loading.value = true
  logs.value = []
  total.value = 0
  error.value = ''
  try {
    const page = await listLoginLogs(PAGE_SIZE, 0)
    logs.value = page.items
    total.value = page.total
  } catch (err) {
    error.value = message(err)
  } finally {
    loading.value = false
  }
}

/** 再加载一页，追加到列表尾部。 */
async function loadMore(): Promise<void> {
  loadingMore.value = true
  error.value = ''
  try {
    const page = await listLoginLogs(PAGE_SIZE, logs.value.length)
    logs.value = [...logs.value, ...page.items]
    total.value = page.total
  } catch (err) {
    error.value = message(err)
  } finally {
    loadingMore.value = false
  }
}

const EVENT_LABEL: Record<LoginLogEventType, string> = {
  login_success: '登录成功',
  login_failure: '登录失败',
  totp_failure: '动态码失败',
  logout: '登出',
}

const METHOD_LABEL: Record<string, string> = {
  password: '密码',
  totp: '动态码',
  session: '会话',
}

const REASON_LABEL: Record<string, string> = {
  unknown_user: '用户不存在',
  bad_password: '密码错误',
  bad_code: '动态码错误',
  expired: '验证超时',
  too_many_attempts: '尝试次数过多',
}

function eventLabel(item: LoginLogItem): string {
  return EVENT_LABEL[item.event_type] ?? item.event_type
}

function methodLabel(item: LoginLogItem): string {
  return METHOD_LABEL[item.method] ?? item.method
}

function reasonLabel(item: LoginLogItem): string {
  if (!item.failure_reason) return ''
  return REASON_LABEL[item.failure_reason] ?? item.failure_reason
}

const hasMore = computed(() => logs.value.length < total.value)

onMounted(() => void load())
</script>

<template>
  <div class="detail-inner">
    <header class="detail-head">
      <h1 class="detail-title">登录日志</h1>
      <p class="detail-sub">最近的登录、失败尝试与登出记录</p>
    </header>

    <div class="stack">
      <p v-if="error" class="notice notice--error">{{ error }}</p>

      <div v-if="loading" class="panel panel--pad">
        <div class="skeleton skeleton--title" style="width: 46%"></div>
      </div>

      <div v-else-if="logs.length === 0" class="panel empty">
        <p class="empty__title">还没有登录记录</p>
        <p class="empty__text">下次登录后，这里会记录时间、设备与来源 IP。</p>
      </div>

      <template v-else>
        <ul class="panel rows">
          <li v-for="item in logs" :key="item.id" class="row-item">
            <div class="row-item__main">
              <div class="row-item__title">
                {{ eventLabel(item) }}
                <span class="badge" :class="item.success ? 'badge--public' : 'badge--danger'">
                  {{ item.success ? '成功' : '失败' }}
                </span>
                <span class="field__hint">{{ methodLabel(item) }}</span>
              </div>
              <div class="row-item__sub">
                {{ formatDateTime(item.created_at) }} · {{ formatRelative(item.created_at) }}
                <template v-if="item.user_agent"> · {{ deviceLabel(item.user_agent) }}</template>
                <template v-if="item.ip"> · {{ item.ip }}</template>
              </div>
              <div v-if="reasonLabel(item)" class="row-item__sub">
                原因：{{ reasonLabel(item) }}
              </div>
            </div>
          </li>
        </ul>

        <div class="settings-more">
          <span class="field__hint">共 {{ total }} 条</span>
          <button
            v-if="hasMore"
            class="btn btn--sm"
            type="button"
            :disabled="loadingMore"
            @click="loadMore"
          >
            {{ loadingMore ? '加载中…' : '加载更多' }}
          </button>
        </div>
      </template>
    </div>
  </div>
</template>
