<script setup lang="ts">
/**
 * 移动端 Issue 详情。
 *
 * 手机上主要做两件事：**改状态**和**看描述**。
 * 标题/描述/类型的编辑做成「编辑模式」切换，避免一屏全是输入框。
 */
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ApiError } from '@/api/client'
import {
  deleteIssue,
  getIssue,
  updateIssue,
  type IssueDetail,
  type IssuePriority,
  type IssueStatus,
  type IssueType,
} from '@/api/issues'
import { ISSUE_TYPE_LABEL, priorityTone } from '@/utils/issues'
import { formatRelative } from '@/utils/format'
import { ChevronLeft } from 'lucide-vue-next'
import MobilePageHeader from '@/components/mobile/MobilePageHeader.vue'

const route = useRoute()
const router = useRouter()

const issue = ref<IssueDetail | null>(null)
const loading = ref(true)
const error = ref('')
const saving = ref(false)
const editing = ref(false)

/** 编辑态的草稿。 */
const draftTitle = ref('')
const draftDescription = ref('')
const draftType = ref<IssueType>('bug')
const draftPriority = ref<IssuePriority>('medium')

const STATUS_LABEL: Record<IssueStatus, string> = {
  todo: '待办',
  in_progress: '进行中',
  done: '已完成',
}
const STATUSES: IssueStatus[] = ['todo', 'in_progress', 'done']

const PRIORITY_LABEL: Record<IssuePriority, string> = {
  low: '低',
  medium: '中',
  high: '高',
}
const PRIORITIES: IssuePriority[] = ['low', 'medium', 'high']

const TYPES: IssueType[] = ['bug', 'feature']

const id = computed(() => String(route.params.id ?? ''))

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    issue.value = await getIssue(id.value)
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : 'Issue 加载失败'
  } finally {
    loading.value = false
  }
}

/** 只改一个字段（状态、优先级），保存后刷新。 */
async function patch(input: { status?: IssueStatus; priority?: IssuePriority }): Promise<void> {
  if (!issue.value || saving.value) return
  saving.value = true
  error.value = ''
  try {
    await updateIssue(issue.value.id, input)
    await load()
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '保存失败'
  } finally {
    saving.value = false
  }
}

function startEdit(): void {
  if (!issue.value) return
  draftTitle.value = issue.value.title
  draftDescription.value = issue.value.description ?? ''
  draftType.value = issue.value.type
  draftPriority.value = issue.value.priority
  editing.value = true
}

async function saveEdit(): Promise<void> {
  if (!issue.value || saving.value) return
  if (!draftTitle.value.trim()) {
    error.value = '标题不能为空'
    return
  }
  saving.value = true
  error.value = ''
  try {
    await updateIssue(issue.value.id, {
      title: draftTitle.value.trim(),
      description: draftDescription.value,
      type: draftType.value,
      priority: draftPriority.value,
    })
    editing.value = false
    await load()
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '保存失败'
  } finally {
    saving.value = false
  }
}

async function remove(): Promise<void> {
  if (!issue.value) return
  if (!window.confirm(`删除「${issue.value.title}」？`)) return
  try {
    await deleteIssue(issue.value.id)
    await router.replace({ name: 'm-issues' })
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '删除失败'
  }
}

onMounted(load)
</script>

<template>
  <div class="m-page">
    <MobilePageHeader title="Issue">
      <template #lead>
        <button type="button" class="m-icon-btn" aria-label="返回" @click="router.back()">
          <ChevronLeft aria-hidden="true" />
        </button>
      </template>
      <template #trail>
        <button v-if="issue && !editing" type="button" class="m-text-btn" @click="startEdit">编辑</button>
        <span v-else />
      </template>
    </MobilePageHeader>

    <p v-if="error" class="m-notice m-notice--error">{{ error }}</p>

    <div v-if="loading" class="m-skeleton">
      <div class="skeleton skeleton--title" style="width: 72%"></div>
      <div class="skeleton skeleton--title" style="width: 46%"></div>
    </div>

    <template v-else-if="issue">
      <!-- 编辑态 -->
      <template v-if="editing">
        <div class="m-card m-form">
          <label class="m-label">标题</label>
          <input v-model="draftTitle" class="m-input" type="text" maxlength="200" aria-label="标题" />

          <label class="m-label">描述</label>
          <textarea v-model="draftDescription" class="m-textarea" rows="6" aria-label="描述" />

          <label class="m-label">类型</label>
          <div class="m-segmented">
            <button
              v-for="t in TYPES"
              :key="t"
              type="button"
              class="m-segmented__btn"
              :class="{ 'is-active': draftType === t }"
              @click="draftType = t"
            >
              {{ ISSUE_TYPE_LABEL[t] }}
            </button>
          </div>

          <label class="m-label">优先级</label>
          <div class="m-segmented">
            <button
              v-for="p in PRIORITIES"
              :key="p"
              type="button"
              class="m-segmented__btn"
              :class="{ 'is-active': draftPriority === p }"
              @click="draftPriority = p"
            >
              {{ PRIORITY_LABEL[p] }}
            </button>
          </div>
        </div>

        <div class="m-actions">
          <button type="button" class="m-primary-btn" :disabled="saving" @click="saveEdit">
            {{ saving ? '保存中…' : '保存' }}
          </button>
          <button type="button" class="m-danger-btn" @click="editing = false">取消</button>
        </div>
      </template>

      <!-- 阅读态 -->
      <template v-else>
        <section class="m-card m-issue-detail">
          <div class="m-issue-detail__tags">
            <span class="m-issue__type" :class="`m-issue__type--${issue.type}`">
              {{ ISSUE_TYPE_LABEL[issue.type] }}
            </span>
            <span class="m-issue__priority" :class="`m-issue__priority--${priorityTone(issue.priority)}`">
              {{ PRIORITY_LABEL[issue.priority] ?? issue.priority }}
            </span>
            <span class="m-hint">更新于 {{ formatRelative(issue.updated_at) }}</span>
          </div>
          <h2 class="m-issue-detail__title">{{ issue.title }}</h2>
          <p v-if="issue.description" class="m-issue-detail__body">{{ issue.description }}</p>
          <p v-else class="m-hint">没有描述。</p>
        </section>

        <!-- 状态：三选一，点一下立刻保存 -->
        <section class="m-card m-stat-block" aria-label="状态">
          <h3 class="m-stat-block__title">状态</h3>
          <div class="m-segmented">
            <button
              v-for="s in STATUSES"
              :key="s"
              type="button"
              class="m-segmented__btn"
              :class="{ 'is-active': issue.status === s }"
              :disabled="saving"
              @click="patch({ status: s })"
            >
              {{ STATUS_LABEL[s] }}
            </button>
          </div>
        </section>

        <button type="button" class="m-danger-btn" @click="remove">删除</button>
      </template>
    </template>
  </div>
</template>
