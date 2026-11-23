<script setup lang="ts">
/**
 * 移动端 Issue 列表。
 *
 * 版式按「状态」分组筛选，而不是一行一个纯文字——
 * Issue 的核心信息是「什么状态、多急」，这两点要在行里直接看到。
 */
import { computed, onMounted, ref } from 'vue'
import { ApiError } from '@/api/client'
import { listIssues, type Issue, type IssueStatus } from '@/api/issues'
import { ISSUE_TYPE_LABEL, priorityTone } from '@/utils/issues'
import MobilePageHeader from '@/components/mobile/MobilePageHeader.vue'

const issues = ref<Issue[]>([])
const loading = ref(true)
const error = ref('')

/** 状态筛选；空串表示全部。 */
const statusFilter = ref<'' | IssueStatus>('')

const STATUS_TABS: { value: '' | IssueStatus; label: string }[] = [
  { value: '', label: '全部' },
  { value: 'todo', label: '待办' },
  { value: 'in_progress', label: '进行中' },
  { value: 'done', label: '已完成' },
]

const STATUS_LABEL: Record<IssueStatus, string> = {
  todo: '待办',
  in_progress: '进行中',
  done: '已完成',
}

const PRIORITY_LABEL: Record<string, string> = {
  low: '低',
  medium: '中',
  high: '高',
}

const visible = computed(() =>
  statusFilter.value === ''
    ? issues.value
    : issues.value.filter((i) => i.status === statusFilter.value),
)

/** 各状态的条数，显示在 tab 上。 */
const counts = computed(() => {
  const out: Record<string, number> = { '': issues.value.length }
  for (const i of issues.value) out[i.status] = (out[i.status] ?? 0) + 1
  return out
})

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    const page = await listIssues({ limit: 100 })
    issues.value = page.items
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : 'Issue 加载失败'
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="m-page">
    <MobilePageHeader title="Issue">
      <template #trail>
        <RouterLink :to="{ name: 'm-issue-new' }" class="m-text-btn">新建</RouterLink>
      </template>
    </MobilePageHeader>

    <!-- 状态筛选：带条数，一眼看出各状态积压多少 -->
    <div class="m-segmented" role="tablist" aria-label="状态筛选">
      <button
        v-for="tab in STATUS_TABS"
        :key="tab.value"
        type="button"
        class="m-segmented__btn"
        :class="{ 'is-active': statusFilter === tab.value }"
        role="tab"
        :aria-selected="statusFilter === tab.value"
        @click="statusFilter = tab.value"
      >
        {{ tab.label }}
        <span v-if="counts[tab.value]" class="m-segmented__count">{{ counts[tab.value] }}</span>
      </button>
    </div>

    <p v-if="error" class="m-notice m-notice--error">{{ error }}</p>

    <div v-if="loading" class="m-skeleton">
      <div class="skeleton skeleton--title" style="width: 64%"></div>
      <div class="skeleton skeleton--title" style="width: 48%"></div>
    </div>

    <p v-else-if="visible.length === 0" class="m-hint">这个状态下没有 Issue。</p>

    <ul v-else class="m-card m-issue-list">
      <li v-for="issue in visible" :key="issue.id">
        <RouterLink :to="{ name: 'm-issue-detail', params: { id: issue.id } }" class="m-issue">
          <div class="m-issue__top">
            <span class="m-issue__type" :class="`m-issue__type--${issue.type}`">
              {{ ISSUE_TYPE_LABEL[issue.type] }}
            </span>
            <span class="m-issue__title">{{ issue.title }}</span>
          </div>
          <div class="m-issue__meta">
            <span class="m-issue__status" :class="`m-issue__status--${issue.status}`">
              {{ STATUS_LABEL[issue.status] }}
            </span>
            <span class="m-issue__priority" :class="`m-issue__priority--${priorityTone(issue.priority)}`">
              {{ PRIORITY_LABEL[issue.priority] ?? issue.priority }}
            </span>
          </div>
        </RouterLink>
      </li>
    </ul>
  </div>
</template>
