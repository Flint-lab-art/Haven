<script setup lang="ts">
/** 移动端新建 Issue。 */
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ApiError } from '@/api/client'
import { createIssue, type IssuePriority, type IssueType } from '@/api/issues'
import { ISSUE_TYPE_LABEL } from '@/utils/issues'
import { ChevronLeft } from 'lucide-vue-next'

const router = useRouter()

const title = ref('')
const description = ref('')
const type = ref<IssueType>('bug')
const priority = ref<IssuePriority>('medium')

const saving = ref(false)
const error = ref('')

const TYPES: IssueType[] = ['bug', 'feature']
const PRIORITIES: IssuePriority[] = ['low', 'medium', 'high']
const PRIORITY_LABEL: Record<IssuePriority, string> = { low: '低', medium: '中', high: '高' }

async function submit(): Promise<void> {
  if (saving.value) return
  if (!title.value.trim()) {
    error.value = '标题不能为空'
    return
  }

  saving.value = true
  error.value = ''
  try {
    const created = await createIssue({
      title: title.value.trim(),
      description: description.value,
      type: type.value,
      priority: priority.value,
    })
    // 建完直接进详情，方便接着改状态或补充描述
    await router.replace({ name: 'm-issue-detail', params: { id: created.id } })
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '创建失败'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="m-page">
    <MobilePageHeader title="新建 Issue">
      <template #lead>
        <button type="button" class="m-icon-btn" aria-label="返回" @click="router.back()">
        <ChevronLeft aria-hidden="true" />
        </button>
      </template>
    </MobilePageHeader>

    <p v-if="error" class="m-notice m-notice--error">{{ error }}</p>

    <div class="m-card m-form">
      <label class="m-label">标题</label>
      <input v-model="title" class="m-input" type="text" maxlength="200" placeholder="一句话说清问题" aria-label="标题" />

      <label class="m-label">描述</label>
      <textarea
        v-model="description"
        class="m-textarea"
        rows="6"
        placeholder="复现步骤、期望结果…"
        aria-label="描述"
      />

      <label class="m-label">类型</label>
      <div class="m-segmented">
        <button
          v-for="t in TYPES"
          :key="t"
          type="button"
          class="m-segmented__btn"
          :class="{ 'is-active': type === t }"
          @click="type = t"
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
          :class="{ 'is-active': priority === p }"
          @click="priority = p"
        >
          {{ PRIORITY_LABEL[p] }}
        </button>
      </div>
    </div>

    <button type="button" class="m-primary-btn" :disabled="saving" @click="submit">
      {{ saving ? '创建中…' : '创建' }}
    </button>
  </div>
</template>
