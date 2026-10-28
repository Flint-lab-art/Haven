<script setup lang="ts">
/**
 * 标签选择器：多选 + 就地新建 + 从本篇笔记移除。
 *
 * 标签语义参考思源笔记：**标签本身不手动删除**，它跟着使用它的笔记走。
 *   - 只显示「至少被一篇笔记使用」的标签（note_count > 0）；
 *   - 从笔记上移除标签 = 解除关联，计数减到 0 时该标签自动从列表消失；
 *   - 想用没用过的标签，直接输入名字新建即可。
 *
 * 数据层面不做物理删除（docs/api.md 第八节已有 DELETE 接口，但本组件不调用）。
 */
import { computed, nextTick, ref } from 'vue'
import { ApiError } from '@/api/client'
import { createTag, type Tag } from '@/api/tags'

const props = defineProps<{
  /** 父组件加载的全部标签（含未被使用的）。 */
  tags: Tag[]
  /** 已选中的标签 id。 */
  selected: string[]
}>()

const emit = defineEmits<{
  'update:selected': [value: string[]]
  /** 标签列表发生变化（新建后），父组件据此刷新。 */
  changed: []
}>()

const input = ref('')
const creating = ref(false)
const error = ref('')
const editing = ref(false)
const inputRef = ref<HTMLInputElement | null>(null)

/** 已选中的标签对象，保证即使计数为 0 也仍然显示（正在编辑的这一篇用它）。 */
const selectedTags = computed(() =>
  props.selected
    .map((id) => props.tags.find((tag) => tag.id === id))
    .filter((tag): tag is Tag => Boolean(tag)),
)

/** 未选中、且有笔记在用的标签：直接平铺展示。 */
const visibleUnselected = computed(() => {
  const chosen = new Set(props.selected)
  return props.tags.filter((tag) => tag.note_count > 0 && !chosen.has(tag.id))
})

/**
 * 输入时的匹配结果：按名称包含过滤，范围是**所有**标签
 * （包括 0 计数的——选中它就会重新被使用）。
 */
const matches = computed(() => {
  const keyword = input.value.trim().toLowerCase()
  if (!keyword) return []
  const chosen = new Set(props.selected)
  return props.tags
    .filter((tag) => !chosen.has(tag.id))
    .filter((tag) => tag.name.toLowerCase().includes(keyword))
    .slice(0, 8)
})

/** 输入的名字是否已完全等于某个现有标签（不论计数）。 */
const exactMatch = computed(() => {
  const keyword = input.value.trim().toLowerCase()
  if (!keyword) return undefined
  return props.tags.find((tag) => tag.name.toLowerCase() === keyword)
})

/** 选中 / 取消选中（取消只影响本篇笔记的关联）。 */
function toggle(id: string): void {
  const next = props.selected.includes(id)
    ? props.selected.filter((x) => x !== id)
    : [...props.selected, id]
  emit('update:selected', next)
}

function toggleEditing(): void {
  if (editing.value) {
    closeInput()
    return
  }
  editing.value = true
  error.value = ''
  void nextTick(() => inputRef.value?.focus())
}

/** 收起输入框并清空草稿。 */
function closeInput(): void {
  editing.value = false
  input.value = ''
  error.value = ''
}

/** 输入框为空时按退格：关闭输入框。 */
function onBackspace(): void {
  if (input.value === '') {
    closeInput()
  }
}

/** 平铺标签点选：加入本篇。 */
function addTag(id: string): void {
  if (!props.selected.includes(id)) {
    emit('update:selected', [...props.selected, id])
  }
}

/** 从匹配列表点选：加入后保持输入框，方便连续添加。 */
function pickFromMatches(id: string): void {
  addTag(id)
  input.value = ''
  void nextTick(() => inputRef.value?.focus())
}

/**
 * 焦点移出整个组件时收起输入框。
 *
 * 用 focusout + 组合内判断，而不是 input 的 blur：
 * 点匹配列表里的项会先让 input 失焦，用 blur 会把列表立刻关掉。
 */
function onFocusOut(event: FocusEvent): void {
  const root = event.currentTarget as HTMLElement
  const next = event.relatedTarget as Node | null
  if (next && root.contains(next)) return
  if (creating.value) return
  if (input.value.trim()) {
    void create()
  } else {
    closeInput()
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
    closeInput()
    return
  }

  creating.value = true
  error.value = ''
  try {
    const created = await createTag(name)
    emit('update:selected', [...props.selected, created.id])
    // 新标签还没有任何笔记使用，需要父组件刷新后才会出现在列表里
    emit('changed')
    closeInput()
  } catch (err) {
    if (err instanceof ApiError && err.status === 409) {
      const existing = props.tags.find((tag) => tag.name.toLowerCase() === name.toLowerCase())
      if (existing) {
        if (!props.selected.includes(existing.id)) {
          emit('update:selected', [...props.selected, existing.id])
        }
        closeInput()
        return
      }
    }
    error.value = err instanceof ApiError ? err.message : '新建标签失败'
  } finally {
    creating.value = false
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
  <div class="tag-picker" @focusout="onFocusOut">
    <div class="tag-row">
      <!-- 已选：点 × 只解除本篇笔记的关联 -->
      <button
        v-for="tag in selectedTags"
        :key="tag.id"
        class="tag tag--selected"
        type="button"
        aria-pressed="true"
        :title="`从这篇笔记移除「${tag.name}」`"
        @click="toggle(tag.id)"
      >
        {{ tag.name }}<span class="tag__x" aria-hidden="true">×</span>
      </button>

      <!-- 未选的可用标签直接平铺，点一下即加入 -->
      <button
        v-for="tag in visibleUnselected"
        :key="tag.id"
        class="tag tag--pick"
        type="button"
        :title="`${tag.note_count} 篇笔记在用`"
        @click="addTag(tag.id)"
      >
        {{ tag.name }}
      </button>

      <!-- 末尾固定一个加号：展开输入框 -->
      <button
        class="tag tag--add"
        type="button"
        :aria-expanded="editing"
        aria-label="新建标签"
        :title="editing ? '收起输入框' : '新建标签'"
        @click="toggleEditing"
      >
        {{ editing ? '×' : '+' }}
      </button>
    </div>

    <div v-if="editing" class="tag-picker__input-row">
      <input
        ref="inputRef"
        v-model="input"
        class="tag-input"
        type="text"
        maxlength="64"
        :placeholder="creating ? '添加中…' : '输入标签名，回车创建'"
        aria-label="标签名"
        :disabled="creating"
        @keydown.enter.prevent="create"
        @keydown.backspace="onBackspace"
        @keydown.esc.prevent="closeInput"
      />
    </div>

    <p v-if="error" class="field__error">{{ error }}</p>

    <!-- 输入时才出现：匹配全部标签（含 0 计数的，选中后自动启用） -->
    <div v-if="editing && input.trim() && matches.length" class="tag-picker__suggest">
      <button
        v-for="tag in matches"
        :key="tag.id"
        class="tag-picker__suggest-item"
        type="button"
        @mousedown.prevent
        @click="pickFromMatches(tag.id)"
      >
        <span>{{ tag.name }}</span>
        <span class="tag-picker__suggest-action">
          {{ tag.note_count > 0 ? `${tag.note_count} 篇` : '未使用' }}
        </span>
      </button>
    </div>

    <p v-if="editing && input.trim() && !matches.length && !exactMatch" class="field__hint">
      回车新建「{{ input.trim() }}」
    </p>
  </div>
</template>
