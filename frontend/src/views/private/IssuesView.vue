<script setup lang="ts">
/**
 * 简易 Issue 面板列表（docs-ai/v8/frontend/frontend.md、v9/frontend/frontend.md）。
 *
 * 后端返回平铺列表，这里组装成一级树：顶层 Feature + 子 Feature。
 * 点击行进入详情页；新建仍用弹窗。
 */
import { computed, onMounted, ref, watch } from 'vue'
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
  buildIssueTree,
  parentFeatureOptions,
  priorityTone,
  type IssueTreeItem,
} from '@/utils/issues'

type StatusFilter = 'all' | IssueStatus

interface RenderRow {
  issue: Issue
  depth: 0 | 1
  hasChildren: boolean
}

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

const expanded = ref<Record<string, boolean>>({})
const formOpen = ref(false)
const parentOptions = ref<Issue[]>([])

let requestSeq = 0

const tree = computed<IssueTreeItem[]>(() => buildIssueTree(issues.value))

const rows = computed<RenderRow[]>(() => {
  const out: RenderRow[] = []
  for (const root of tree.value) {
    const hasChildren = root.children.length > 0
    out.push({ issue: root, depth: 0, hasChildren })
    if (!hasChildren || !isExpanded(root.id)) continue
    for (const child of root.children) {
      out.push({ issue: child, depth: 1, hasChildren: false })
    }
  }
  return out
})

function isExpanded(id: string): boolean {
  return expanded.value[id] !== false
}

function toggleExpanded(id: string): void {
  expanded.value = { ...expanded.value, [id]: !isExpanded(id) }
}

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

    // 每次重新拉取都回到「全部展开」
    const next: Record<string, boolean> = {}
    for (const root of buildIssueTree(result.items)) {
      if (root.children.length > 0) next[root.id] = true
    }
    expanded.value = next
  } catch (err) {
    if (seq !== requestSeq) return
    error.value = err instanceof ApiError ? err.message : 'Issue 加载失败'
  } finally {
    if (seq === requestSeq) loading.value = false
  }
}

async function loadParentOptions(): Promise<void> {
  try {
    const result = await listIssues({ limit: 100, offset: 0 })
    parentOptions.value = parentFeatureOptions(result.items)
  } catch {
    parentOptions.value = []
  }
}

async function openCreate(): Promise<void> {
  await loadParentOptions()
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
        v-for="row in rows"
        :key="row.issue.id"
        class="issue-row"
        :class="{ 'issue-row--child': row.depth === 1 }"
        role="button"
        tabindex="0"
        @click="openDetail(row.issue.id)"
        @keydown.enter.prevent="openDetail(row.issue.id)"
        @keydown.space.prevent="openDetail(row.issue.id)"
      >
        <button
          v-if="row.depth === 0 && row.hasChildren"
          class="issue-expand"
          type="button"
          :aria-expanded="isExpanded(row.issue.id)"
          aria-label="展开或折叠子需求"
          @click.stop="toggleExpanded(row.issue.id)"
          @keydown.stop
        >
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
            :class="{ 'is-open': isExpanded(row.issue.id) }"
          >
            <path d="m9 6 6 6-6 6" />
          </svg>
        </button>
        <span v-else class="issue-expand issue-expand--placeholder" aria-hidden="true"></span>

        <button
          class="issue-status"
          :class="`issue-status--${row.issue.status}`"
          type="button"
          :aria-label="row.issue.status === 'done' ? '标记为待办' : '标记为已完成'"
          :disabled="busyId === row.issue.id"
          @click.stop="toggleDone(row.issue)"
          @keydown.stop
        >
          <svg v-if="row.issue.status === 'done'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="m5 12.5 4.2 4.2L19 7" />
          </svg>
          <span v-else-if="row.issue.status === 'in_progress'" class="issue-status__dot" aria-hidden="true"></span>
        </button>

        <span class="issue-title" :class="{ 'is-done': row.issue.status === 'done' }">{{ row.issue.title }}</span>

        <span class="issue-type" :class="`issue-type--${row.issue.type}`">{{ ISSUE_TYPE_LABEL[row.issue.type] }}</span>

        <span class="issue-priority" :class="`issue-priority--${priorityTone(row.issue.priority)}`">
          <span class="issue-priority__dot" aria-hidden="true"></span>
          {{ ISSUE_PRIORITY_LABEL[row.issue.priority] }}
        </span>

        <span class="issue-relative">{{ formatRelative(row.issue.updated_at) }}</span>
      </div>
    </div>

    <IssueFormDialog
      :open="formOpen"
      :issue="null"
      :parent-options="parentOptions"
      :child-count="0"
      @close="formOpen = false"
      @saved="onSaved"
    />
  </div>
</template>
