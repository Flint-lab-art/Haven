<script setup lang="ts">
/**
 * 新建 / 编辑 Issue 的共用弹窗。
 *
 * - 新建时 issue 为 null；
 * - 编辑时预填 issue，只提交发生变化的字段。
 */
import { reactive, ref, watch } from 'vue'
import { ApiError } from '@/api/client'
import {
  createIssue,
  updateIssue,
  type Issue,
  type IssuePriority,
  type IssueStatus,
  type IssueType,
  type UpdateIssueInput,
} from '@/api/issues'
import {
  ISSUE_PRIORITY_LABEL,
  ISSUE_STATUS_LABEL,
  ISSUE_TYPE_LABEL,
} from '@/utils/issues'

const props = withDefaults(
    defineProps<{
      open: boolean
      issue?: Issue | null
    }>(),
    { issue: null },
)

const emit = defineEmits<{
  close: []
  saved: []
}>()

const saving = ref(false)
const formError = ref('')

const form = reactive({
  title: '',
  description: '',
  type: 'bug' as IssueType,
  status: 'todo' as IssueStatus,
  priority: 'medium' as IssuePriority,
})

function reset(): void {
  const issue = props.issue
  form.title = issue?.title ?? ''
  form.description = issue?.description ?? ''
  form.type = issue?.type ?? 'bug'
  form.status = issue?.status ?? 'todo'
  form.priority = issue?.priority ?? 'medium'
  formError.value = ''
  saving.value = false
}

watch(
    () => [props.open, props.issue] as const,
    ([open]) => {
      if (open) reset()
    },
    { immediate: true },
)

function close(): void {
  if (saving.value) return
  emit('close')
}

function messageOf(err: unknown): string {
  if (err instanceof ApiError) {
    if (err.fields) return Object.values(err.fields).join('；')
    return err.message
  }
  return '保存失败，请稍后重试'
}

async function save(): Promise<void> {
  if (saving.value) return

  const title = form.title.trim()
  if (!title) {
    formError.value = '标题不能为空'
    return
  }

  saving.value = true
  formError.value = ''

  try {
    if (!props.issue) {
      await createIssue({
        title,
        description: form.description,
        type: form.type,
        status: form.status,
        priority: form.priority,
      })
    } else {
      const issue = props.issue
      const patch: UpdateIssueInput = {}
      if (title !== issue.title) patch.title = title
      if (form.description !== issue.description) patch.description = form.description
      if (form.type !== issue.type) patch.type = form.type
      if (form.status !== issue.status) patch.status = form.status
      if (form.priority !== issue.priority) patch.priority = form.priority

      if (Object.keys(patch).length > 0) {
        await updateIssue(issue.id, patch)
      }
    }

    emit('saved')
    emit('close')
  } catch (err) {
    formError.value = messageOf(err)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div v-if="open" class="modal-backdrop" role="presentation" @click.self="close">
    <section class="modal issues-modal" role="dialog" aria-modal="true" :aria-label="issue ? '编辑 Issue' : '新建 Issue'">
      <header class="modal__head">
        <h2 class="modal__title">{{ issue ? '编辑 Issue' : '新建 Issue' }}</h2>
        <button class="icon-btn" type="button" aria-label="关闭" @click="close">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true">
            <path d="M6 6l12 12M18 6 6 18" />
          </svg>
        </button>
      </header>

      <p v-if="formError" class="notice notice--error">{{ formError }}</p>

      <label class="field">
        <span class="field__label">标题</span>
        <input v-model="form.title" class="input" type="text" placeholder="例如：登录页在 Safari 下错位" />
      </label>

      <label class="field">
        <span class="field__label">描述</span>
        <textarea v-model="form.description" class="textarea" rows="4" placeholder="可选，补充复现步骤或验收标准；支持 Markdown"></textarea>
        <span class="field__hint">支持 Markdown：标题、列表、代码块、链接、表格等。</span>
      </label>

      <div class="field">
        <span class="field__label">类型</span>
        <div class="issue-segmented">
          <button
              v-for="item in (['bug', 'feature'] as const)"
              :key="item"
              type="button"
              class="issue-segmented__btn"
              :class="{ 'is-active': form.type === item }"
              @click="form.type = item"
          >
            {{ ISSUE_TYPE_LABEL[item] }}
          </button>
        </div>
      </div>

      <div class="field">
        <span class="field__label">优先级</span>
        <div class="issue-segmented">
          <button
              v-for="item in (['low', 'medium', 'high'] as const)"
              :key="item"
              type="button"
              class="issue-segmented__btn"
              :class="{ 'is-active': form.priority === item }"
              @click="form.priority = item"
          >
            {{ ISSUE_PRIORITY_LABEL[item] }}
          </button>
        </div>
      </div>

      <div class="field">
        <span class="field__label">状态</span>
        <div class="issue-segmented">
          <button
              v-for="item in (['todo', 'in_progress', 'done'] as const)"
              :key="item"
              type="button"
              class="issue-segmented__btn"
              :class="{ 'is-active': form.status === item }"
              @click="form.status = item"
          >
            {{ ISSUE_STATUS_LABEL[item] }}
          </button>
        </div>
      </div>

      <footer class="modal__actions issues-modal__actions">
        <span class="issues-modal__spacer"></span>
        <button class="btn" type="button" :disabled="saving" @click="close">取消</button>
        <button class="btn btn--primary" type="button" :disabled="saving" @click="save">
          {{ saving ? '保存中…' : '保存' }}
        </button>
      </footer>
    </section>
  </div>
</template>