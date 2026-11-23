<script setup lang="ts">
/**
 * 移动端设置 · 登录日志。
 *
 * 只读当前账号的登录历史：成功、失败（密码 / 动态码）、登出。
 * 用户名输错时 `user_id` 为空，后端会按同名把这些失败尝试一并返回。
 *
 * 与 PC 同一套接口与文案映射，只是版式按手机重排：
 * 每条一行主信息 + 一行来源，不画卡片，靠分隔线区分。
 */
import { computed, onMounted, ref } from 'vue'
import { ApiError } from '@/api/client'
import { listLoginLogs, type LoginLogEventType, type LoginLogItem } from '@/api/login-logs'
import { deviceLabel, formatRelative } from '@/utils/format'

const PAGE_SIZE = 50

const logs = ref<LoginLogItem[]>([])
const total = ref(0)
const loading = ref(true)
const loadingMore = ref(false)
const error = ref('')

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

const hasMore = computed(() => logs.value.length < total.value)

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

onMounted(load)
</script>

<template>
  <div class="m-page">
    <MobilePageHeader title="登录日志" />

    <p v-if="error" class="m-notice m-notice--error">{{ error }}</p>

    <div v-if="loading" class="m-skeleton">
      <div class="skeleton skeleton--title" style="width: 52%"></div>
      <div class="skeleton skeleton--title" style="width: 38%"></div>
    </div>

    <p v-else-if="logs.length === 0" class="m-hint">还没有登录记录。</p>

    <template v-else>
      <ul class="m-card m-log-list">
        <li v-for="item in logs" :key="item.id" class="m-log">
          <div class="m-log__top">
            <span class="m-log__event" :class="{ 'm-log__event--fail': !item.success }">
              {{ eventLabel(item) }}
            </span>
            <span class="m-log__method">{{ methodLabel(item) }}</span>
            <span class="m-log__time">{{ formatRelative(item.created_at) }}</span>
          </div>
          <p class="m-log__meta">
            {{ deviceLabel(item.user_agent) }}
            <template v-if="item.ip"> · {{ item.ip }}</template>
            <template v-if="reasonLabel(item)"> · {{ reasonLabel(item) }}</template>
          </p>
        </li>
      </ul>

      <div class="m-log-more">
        <span class="m-hint">共 {{ total }} 条</span>
        <button v-if="hasMore" class="m-text-btn" type="button" :disabled="loadingMore" @click="loadMore">
          {{ loadingMore ? '加载中…' : '加载更多' }}
        </button>
      </div>
    </template>
  </div>
</template>
