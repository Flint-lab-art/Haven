<script setup lang="ts">
/**
 * Issue 详情页（docs-ai/v9/frontend/frontend.md 第六节）。
 *
 * Bug 与 Feature 共用；状态变化直接在这里完成，并刷新状态流转时间线。
 */
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import IssueFormDialog from '@/components/IssueFormDialog.vue'
import { ApiError } from '@/api/client'
import {
  deleteIssue,
  getIssue,
  updateIssue,
  type IssueDetail,
  type IssueStatus,
} from '@/api/issues'
import { formatDateTime } from '@/utils/format'
import { renderMarkdown } from '@/utils/markdown'
import {
  ISSUE_PRIORITY_LABEL,
  ISSUE_STATUS_LABEL,
  ISSUE_TYPE_LABEL,
  priorityTone,
} from '@/utils/issues'

const route = useRoute()
const router = useRouter()

const id = computed(() => String(route.params.id ?? ''))
const detail = ref<IssueDetail | null>(null)
const loading = ref(true)
const error = ref('')
const saving = ref(false)
const formOpen = ref(false)
const confirmDelete = ref(false)

const steps: { value: IssueStatus; label: string }[] = [
  { value: 'todo', label: '待办' },
  { value: 'in_progress', label: '进行中' },
  { value: 'done', label: '已完成' },
]

const currentIndex = computed(() => {
  const status = detail.value?.status
  return status ? steps.findIndex((step) => step.value === status) : -1
})

const deleteMessage = computed(
    () => `永久删除「${detail.value?.title ?? ''}」后无法恢复。`,
)

/** 描述按 Markdown 渲染：复用作品集正文的 marked + DOMPurify 管线，保留单个换行。 */
const renderedDescription = computed(() =>
  renderMarkdown(detail.value?.description ?? '', { breaks: true }),
)

function stepState(step: IssueStatus): 'current' | 'reached' | 'pending' {
  const index = steps.findIndex((item) => item.value === step)
  if (index === currentIndex.value) return 'current'
  if (index < currentIndex.value) return 'reached'
  return 'pending'
}

function eventText(from: IssueStatus | null, to: IssueStatus): string {
  if (!from) return `创建为${ISSUE_STATUS_LABEL[to]}`
  return `${ISSUE_STATUS_LABEL[from]} → ${ISSUE_STATUS_LABEL[to]}`
}

function messageOf(err: unknown, fallback: string): string {
  if (err instanceof ApiError) {
    if (err.fields) return Object.values(err.fields).join('；')
    return err.message
  }
  return fallback
}

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    detail.value = await getIssue(id.value)
  } catch (err) {
    detail.value = null
    error.value = err instanceof ApiError && err.isNotFound ? '这篇 Issue 不存在' : 'Issue 加载失败'
  } finally {
    loading.value = false
  }
}

function openEdit(): void {
  if (!detail.value) return
  formOpen.value = true
}

function onSaved(): void {
  formOpen.value = false
  void load()
}

async function changeStatus(status: IssueStatus): Promise<void> {
  if (!detail.value || detail.value.status === status || saving.value) return
  saving.value = true
  error.value = ''
  try {
    await updateIssue(detail.value.id, { status })
    await load()
  } catch (err) {
    error.value = messageOf(err, '更新状态失败')
  } finally {
    saving.value = false
  }
}

async function remove(): Promise<void> {
  if (!detail.value || saving.value) return
  saving.value = true
  try {
    await deleteIssue(detail.value.id)
    confirmDelete.value = false
    await router.push({ name: 'issues' })
  } catch (err) {
    error.value = messageOf(err, '删除失败')
    confirmDelete.value = false
  } finally {
    saving.value = false
  }
}

watch(id, () => void load())
onMounted(() => void load())
</script>

<template>
  <div class="issue-detail">
    <RouterLink :to="{ name: 'issues' }" class="issue-detail__back">← Issue</RouterLink>

    <p v-if="error" class="notice notice--error">
      {{ error }}
      <span class="notice__actions">
        <button class="btn btn--sm" type="button" @click="load">重试</button>
      </span>
    </p>

    <div v-if="loading" class="issue-detail__skeleton">
      <span class="skeleton skeleton--title" style="width: 58%; height: 32px"></span>
      <span class="skeleton skeleton--line" style="width: 92%; margin-top: 20px"></span>
      <span class="skeleton skeleton--line" style="width: 76%"></span>
    </div>

    <template v-else-if="detail">
      <header class="issue-detail__head">
        <div class="issue-detail__title-wrap">
          <h1 class="issue-detail__title" :class="{ 'is-done': detail.status === 'done' }">{{ detail.title }}</h1>
          <div class="issue-detail__badges">
            <span class="issue-type" :class="`issue-type--${detail.type}`">{{ ISSUE_TYPE_LABEL[detail.type] }}</span>
            <span class="issue-priority" :class="`issue-priority--${priorityTone(detail.priority)}`">
              <span class="issue-priority__dot" aria-hidden="true"></span>
              {{ ISSUE_PRIORITY_LABEL[detail.priority] }}
            </span>
            <span class="issue-detail__status">{{ ISSUE_STATUS_LABEL[detail.status] }}</span>
          </div>
        </div>
        <div class="issue-detail__actions">
          <button class="btn btn--sm" type="button" :disabled="saving" @click="openEdit">编辑</button>
          <button class="btn btn--sm btn--danger" type="button" :disabled="saving" @click="confirmDelete = true">删除</button>
        </div>
      </header>

      <p class="issue-detail__meta">
        创建于 {{ formatDateTime(detail.created_at) }} · 更新于 {{ formatDateTime(detail.updated_at) }}
      </p>

      <section class="issue-detail__section">
        <h2 class="issue-detail__section-title">描述</h2>
        <!-- eslint-disable-next-line vue/no-v-html -- 已经过 DOMPurify 过滤 -->
        <div v-if="detail.description" class="md-body issue-detail__description" v-html="renderedDescription"></div>
        <p v-else class="field__hint">没有填写描述。</p>
      </section>

      <section class="issue-detail__section">
        <h2 class="issue-detail__section-title">状态</h2>
        <div class="issue-stepper">
          <button
              v-for="(step, index) in steps"
              :key="step.value"
              type="button"
              class="issue-step"
              :class="`issue-step--${stepState(step.value)}`"
              :disabled="saving || step.value === detail.status"
              @click="changeStatus(step.value)"
          >
            <span class="issue-step__dot" aria-hidden="true"></span>
            <span class="issue-step__label">{{ step.label }}</span>
            <span v-if="index < steps.length - 1" class="issue-step__line" aria-hidden="true"></span>
          </button>
        </div>
      </section>

      <section class="issue-detail__section">
        <h2 class="issue-detail__section-title">状态流转</h2>
        <ul class="issue-timeline">
          <li v-for="event in detail.status_events" :key="event.id" class="issue-timeline__item">
            <span class="issue-timeline__dot" aria-hidden="true"></span>
            <div class="issue-timeline__body">
              <span class="issue-timeline__text">{{ eventText(event.from_status, event.to_status) }}</span>
              <span class="issue-timeline__time">{{ formatDateTime(event.created_at) }}</span>
            </div>
          </li>
          <li v-if="detail.status_events.length === 0" class="field__hint">暂无状态记录。</li>
        </ul>
      </section>
    </template>

    <IssueFormDialog
        :open="formOpen"
        :issue="detail"
        @close="formOpen = false"
        @saved="onSaved"
    />

    <ConfirmDialog
        :open="confirmDelete"
        title="删除 Issue"
        :message="deleteMessage"
        :busy="saving"
        @confirm="remove"
        @cancel="confirmDelete = false"
    />
  </div>
</template>