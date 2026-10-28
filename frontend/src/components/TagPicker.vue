<script setup lang="ts">
/**
 * 标签选择器：多选 + 就地新建 + 删除。
 *
 * 弹窗与编辑页共用（docs/api.md 第八节：POST /api/tags 新建，DELETE 删除）。
 * 新建时若名字已存在（后端 409），自动选中已有那个而不是报错。
 */
import { computed, nextTick, ref } from 'vue'
import { ApiError } from '@/api/client'
import { createTag, deleteTag, type Tag } from '@/api/tags'

const props = defineProps<{
  /** 全部可选标签（由父组件加载，避免两处各拉一次）。 */
  tags: Tag[]
  /** 已选中的标签 id。 */
  selected: string[]
}>()

const emit = defineEmits<{
  'update:selected': [value: string[]]
  /** 标签列表发生变化（新建 / 删除后），父组件据此刷新。 */
  changed: []
}>()

const input = ref('')
const creating = ref(false)
const error = ref('')
const editing = ref(false)
const inputRef = ref<HTMLInputElement | null>(null)

/** 下拉候选：按输入过滤，排除已选。 */
const suggestions = computed(() => {
  const keyword = input.value.trim().toLowerCase()
  const chosen = new Set(props.selected)
  return props.tags
    .filter((tag) => !chosen.has(tag.id))
    .filter((tag) => !keyword || tag.name.toLowerCase().includes(keyword))
    .slice(0, 8)
})

/** 输入的名字是否已完全等于某个已有标签。 */
const exactMatch = computed(() => {
  const keyword = input.value.trim().toLowerCase()
  if (!keyword) return undefined
  return props.tags.find((tag) => tag.name.toLowerCase() === keyword)
})

function toggle(id: string): void {
  const next = props.selected.includes(id)
    ? props.selected.filter((x) => x !== id)
    : [...props.selected, id]
  emit('update:selected', next)
}

function toggleEditing(): void {
  editing.value = !editing.value
  error.value = ''
  if (editing.value) {
    void nextTick(() => inputRef.value?.focus())
  }
}

/** 新建标签；重名时自动选中已有标签。 */
async function create(): Promise<void> {
  const name = input.value.trim()
  if (!name || creating.value) return

  // 名字已存在：直接选中，不报错
  if (exactMatch.value) {
    if (!props.selected.includes(exactMatch.value.id)) {
      emit('update:selected', [...props.selected, exactMatch.value.id])
    }
    input.value = ''
    editing.value = false
    error.value = ''
    return
  }

  creating.value = true
  error.value = ''
  try {
    const created = await createTag(name)
    emit('update:selected', [...props.selected, created.id])
    input.value = ''
    editing.value = false
    emit('changed')
  } catch (err) {
    if (err instanceof ApiError && err.status === 409) {
      // 后端判重（大小写不同也算重名）：选中已有那个
      const existing = props.tags.find((tag) => tag.name.toLowerCase() === name.toLowerCase())
      if (existing) {
        if (!props.selected.includes(existing.id)) {
          emit('update:selected', [...props.selected, existing.id])
        }
        input.value = ''
        editing.value = false
        return
      }
    }
    error.value = err instanceof ApiError ? err.message : '新建标签失败'
  } finally {
    creating.value = false
  }
}

/** 删除标签（会解除所有笔记的关联，需二次确认）。 */
async function remove(tag: Tag): Promise<void> {
  if (!window.confirm(`删除标签「${tag.name}」？所有笔记上的这个标签都会被移除。`)) return

  error.value = ''
  try {
    await deleteTag(tag.id)
    if (props.selected.includes(tag.id)) {
      emit('update:selected', props.selected.filter((x) => x !== tag.id))
    }
    emit('changed')
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '删除标签失败'
  }
}

defineExpose({
  focusInput: async () => {
    editing.value = true
    await nextTick()
    inputRef.value?.focus()
  },
})
</script>

<template>
  <div class="tag-picker">
    <div class="tag-row">
      <button
        v-for="tag in tags"
        :key="tag.id"
        class="tag"
        type="button"
        :aria-pressed="selected.includes(tag.id)"
        @click="toggle(tag.id)"
      >
        {{ tag.name }}
      </button>

      <button class="tag tag--add" type="button" @click="toggleEditing">
        {{ editing ? '取消' : '+ 新建' }}
      </button>
    </div>

    <div v-if="editing" class="tag-picker__new">
      <input
        ref="inputRef"
        v-model="input"
        class="input"
        type="text"
        maxlength="64"
        placeholder="新标签名，回车创建"
        aria-label="新标签名"
        @keydown.enter.prevent="create"
        @keydown.esc="toggleEditing"
      />
      <button class="btn btn--sm btn--primary" type="button" :disabled="creating" @click="create">
        {{ creating ? '创建中…' : '创建' }}
      </button>
    </div>

    <p v-if="error" class="field__error">{{ error }}</p>

    <!-- 已有标签的联想与删除 -->
    <div v-if="editing && suggestions.length" class="tag-picker__suggest">
      <button
        v-for="tag in suggestions"
        :key="tag.id"
        class="tag-picker__suggest-item"
        type="button"
        @click="toggle(tag.id)"
      >
        <span>{{ tag.name }}</span>
        <span class="tag-picker__suggest-action">选择</span>
      </button>
    </div>

    <details v-if="tags.length" class="tag-picker__manage">
      <summary>管理标签（删除）</summary>
      <ul class="tag-picker__manage-list">
        <li v-for="tag in tags" :key="tag.id">
          <span>{{ tag.name }}</span>
          <button class="btn btn--sm btn--danger" type="button" @click="remove(tag)">删除</button>
        </li>
      </ul>
    </details>
  </div>
</template>
