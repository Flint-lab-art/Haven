<script setup lang="ts">
/**
 * Issue 面板列表。
 *
 * 后端返回平铺列表，直接按行渲染；点击行进入详情页，新建用弹窗。
 */
import { onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import IssueFormDialog from '@/components/IssueFormDialog.vue'
import { ApiError } from '@/api/client'
import {
  listIssues,
  updateIssue,
  type Issue,
  type IssueStatus,
} from '@/api/issues'
import { formatRelative } from '@/utils/format'
import {
  ISSUE_PRIORITY_LABEL,
  ISSUE_TYPE_LABEL,
  priorityTone,
} from '@/utils/issues'

type StatusFilter = 'all' | IssueStatus

const tabs: { value: StatusFilter; label: string }[] = [
  { value: 'all', label: '全部' },
  { value: 'todo', label: '待办' },
  { value: 'in_progress', label: '进行中' },
  { value: 'done', label: '已完成' },
]

const router = useRouter()
const issues = ref<Issue[]>([])
const total = ref(0)
const activeStatus = ref<StatusFilter>('all')
const loading = ref(false)
const error = ref('')
const busyId = ref<string | null>(null)

const formOpen = ref(false)

let requestSeq = 0

async function load(): Promise<void> {
  const seq = ++requestSeq
  loading.value = true
  error.value = ''
  try {
    const result = await listIssues({
      status: activeStatus.value === 'all' ? undefined : activeStatus.value,
      limit: 100,
      offset: 0,
    })
    if (seq !== requestSeq) return
    issues.value = result.items
    total.value = result.total
  } catch (err) {
    if (seq !== requestSeq) return
    error.value = err instanceof ApiError ? err.message : 'Issue 加载失败'
  } finally {
    if (seq === requestSeq) loading.value = false
  }
}

function openCreate(): void {
  formOpen.value = true
}

function openDetail(id: string): void {
  void router.push({ name: 'issue-detail', params: { id } })
}

async function toggleDone(issue: Issue): Promise<void> {
  if (busyId.value) return
  busyId.value = issue.id
  error.value = ''
  try {
    await updateIssue(issue.id, { status: issue.status === 'done' ? 'todo' : 'done' })
    await load()
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '更新状态失败'
  } finally {
    busyId.value = null
  }
}

function onSaved(): void {
  formOpen.value = false
  void load()
}

watch(activeStatus, () => void load())
onMounted(() => void load())
</script>

<template>
  <div class="issues-page">
    <header class="issues-header">
      <div>
        <h1 class="issues-title">Issue</h1>
        <p class="issues-sub">记录项目 Bug 与功能点，与笔记系统独立。</p>
      </div>
      <button class="btn btn--primary" type="button" @click="openCreate">新建 Issue</button>
    </header>

    <div class="issues-tabs" role="tablist" aria-label="Issue 状态">
      <button
          v-for="tab in tabs"
          :key="tab.value"
          type="button"
          class="issues-tab"
          :class="{ 'is-active': activeStatus === tab.value }"
          role="tab"
          :aria-selected="activeStatus === tab.value"
          @click="activeStatus = tab.value"
      >
        {{ tab.label }}
      </button>
      <span v-if="!loading" class="issues-total">{{ total }} 条</span>
    </div>

    <p v-if="error" class="notice notice--error issues-error">
      {{ error }}
      <button class="issues-retry" type="button" @click="load">重试</button>
    </p>

    <div v-if="loading" class="issue-list" aria-busy="true">
      <div v-for="i in 3" :key="i" class="issue-row issue-row--skeleton">
        <span class="skeleton" style="width: 20px; height: 20px; border-radius: 50%"></span>
        <span class="skeleton" style="width: 52%; height: 16px"></span>
      </div>
    </div>

    <div v-else-if="issues.length === 0" class="issue-empty">
      <p class="issue-empty__title">还没有 Issue</p>
      <p class="issue-empty__text">记录一个 Bug，或者先写下想做的功能。</p>
      <button class="btn btn--primary" type="button" @click="openCreate">新建 Issue</button>
    </div>

    <div v-else class="issue-list">
      <div
          v-for="issue in issues"
          :key="issue.id"
          class="issue-row"
          role="button"
          tabindex="0"
          @click="openDetail(issue.id)"
          @keydown.enter.prevent="openDetail(issue.id)"
          @keydown.space.prevent="openDetail(issue.id)"
      >
        <button
            class="issue-status"
            :class="`issue-status--${issue.status}`"
            type="button"
            :aria-label="issue.status === 'done' ? '标记为待办' : '标记为已完成'"
            :disabled="busyId === issue.id"
            @click.stop="toggleDone(issue)"
            @keydown.stop
        >
          <svg
              v-if="issue.status === 'done'"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2.4"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
          >
            <path d="m5 12.5 4.2 4.2L19 7" />
          </svg>
          <span
              v-else-if="issue.status === 'in_progress'"
              class="issue-status__dot"
              aria-hidden="true"
          ></span>
        </button>

        <span class="issue-title" :class="{ 'is-done': issue.status === 'done' }">
          {{ issue.title }}
        </span>

        <span class="issue-type" :class="`issue-type--${issue.type}`">
          {{ ISSUE_TYPE_LABEL[issue.type] }}
        </span>

        <span class="issue-priority" :class="`issue-priority--${priorityTone(issue.priority)}`">
          <span class="issue-priority__dot" aria-hidden="true"></span>
          {{ ISSUE_PRIORITY_LABEL[issue.priority] }}
        </span>

        <span class="issue-relative">{{ formatRelative(issue.updated_at) }}</span>
      </div>
    </div>

    <IssueFormDialog
        :open="formOpen"
        :issue="null"
        @close="formOpen = false"
        @saved="onSaved"
    />
  </div>
</template>