<script setup lang="ts">
/**
 * 编辑页的标签下拉（与新建弹窗的 `TagPicker` 是两套交互）。
 *
 * 编辑页只需要一个「添加标签」按钮：
 *   - 已选标签以胶囊显示在按钮左侧，点 × 解除本篇关联；
 *   - 点按钮向下展开面板，面板里列出「有笔记在用」的标签；
 *   - 在面板顶部输入字符时实时匹配（含 0 计数的标签，标注「未使用」）；
 *   - 回车可新建；空输入退格关闭面板；Esc / 点外部关闭。
 *
 * 标签语义跟随笔记生命周期（类思源）：不在这里做物理删除。
 */
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import { ApiError } from '@/api/client'
import { createTag, type Tag } from '@/api/tags'

const props = defineProps<{
  tags: Tag[]
  selected: string[]
}>()

const emit = defineEmits<{
  'update:selected': [value: string[]]
  changed: []
}>()

const open = ref(false)
const input = ref('')
const creating = ref(false)
const error = ref('')

const root = ref<HTMLElement | null>(null)
const inputRef = ref<HTMLInputElement | null>(null)
const buttonRef = ref<HTMLButtonElement | null>(null)

const selectedTags = computed(() =>
  props.selected
    .map((id) => props.tags.find((tag) => tag.id === id))
    .filter((tag): tag is Tag => Boolean(tag)),
)

/** 输入时按名称匹配全部标签（含 0 计数的）。 */
const matches = computed(() => {
  const keyword = input.value.trim().toLowerCase()
  const chosen = new Set(props.selected)
  const pool = props.tags.filter((tag) => !chosen.has(tag.id))
  if (!keyword) return pool.filter((tag) => tag.note_count > 0)
  return pool.filter((tag) => tag.name.toLowerCase().includes(keyword)).slice(0, 12)
})

const exactMatch = computed(() => {
  const keyword = input.value.trim().toLowerCase()
  if (!keyword) return undefined
  return props.tags.find((tag) => tag.name.toLowerCase() === keyword)
})

const canCreate = computed(
  () => Boolean(input.value.trim()) && !exactMatch.value && !creating.value,
)

function toggleSelected(id: string): void {
  const next = props.selected.includes(id)
    ? props.selected.filter((x) => x !== id)
    : [...props.selected, id]
  emit('update:selected', next)
}

async function openPanel(): Promise<void> {
  open.value = !open.value
  error.value = ''
  if (open.value) {
    input.value = ''
    await nextTick()
    inputRef.value?.focus()
  }
}

function closePanel(): void {
  open.value = false
  input.value = ''
  error.value = ''
}

/** 从面板点选：加入后保持面板展开，方便连续挑。 */
function pick(id: string): void {
  toggleSelected(id)
  input.value = ''
  void nextTick(() => inputRef.value?.focus())
}

/** 回车：有匹配就用第一个，否则新建。 */
async function submit(): Promise<void> {
  const name = input.value.trim()
  if (!name || creating.value) return

  if (exactMatch.value) {
    pick(exactMatch.value.id)
    return
  }
  if (matches.value.length) {
    pick(matches.value[0].id)
    input.value = name
    return
  }

  creating.value = true
  error.value = ''
  try {
    const created = await createTag(name)
    emit('update:selected', [...props.selected, created.id])
    emit('changed')
    input.value = ''
    void nextTick(() => inputRef.value?.focus())
  } catch (err) {
    if (err instanceof ApiError && err.status === 409) {
      const existing = props.tags.find((tag) => tag.name.toLowerCase() === name.toLowerCase())
      if (existing) {
        pick(existing.id)
        return
      }
    }
    error.value = err instanceof ApiError ? err.message : '新建标签失败'
  } finally {
    creating.value = false
  }
}

function onBackspace(): void {
  if (input.value === '') closePanel()
}

/** 点组件外部关闭面板。 */
function onDocumentPointerDown(event: PointerEvent): void {
  if (!open.value) return
  const target = event.target as Node | null
  if (target && root.value?.contains(target)) return
  closePanel()
}

onMounted(() => document.addEventListener('pointerdown', onDocumentPointerDown))
onBeforeUnmount(() => document.removeEventListener('pointerdown', onDocumentPointerDown))

defineExpose({
  /** 供父组件聚焦（例如快捷键触发时）。 */
  focusButton: () => buttonRef.value?.focus(),
})
</script>

<template>
  <div ref="root" class="tag-dropdown">
    <!-- 已选标签 + 唯一的操作入口 -->
    <div class="tag-dropdown__bar">
      <span
        v-for="tag in selectedTags"
        :key="tag.id"
        class="tag tag--selected"
        :title="`从这篇笔记移除「${tag.name}」`"
      >
        {{ tag.name }}
        <button
          class="tag__remove"
          type="button"
          :aria-label="`移除标签 ${tag.name}`"
          @click="toggleSelected(tag.id)"
        >
          ×
        </button>
      </span>

      <button
        ref="buttonRef"
        class="tag-dropdown__trigger"
        type="button"
        :aria-expanded="open"
        aria-haspopup="listbox"
        @click="openPanel"
      >
        <span aria-hidden="true">{{ open ? '×' : '+' }}</span>
        {{ open ? '收起' : '添加标签' }}
      </button>
    </div>

    <!-- 下拉面板 -->
    <div v-if="open" class="tag-dropdown__panel" role="listbox">
      <input
        ref="inputRef"
        v-model="input"
        class="input tag-dropdown__search"
        type="text"
        maxlength="64"
        :placeholder="creating ? '创建中…' : '搜索或输入新标签'"
        aria-label="搜索或输入新标签"
        :disabled="creating"
        @keydown.enter.prevent="submit"
        @keydown.backspace="onBackspace"
        @keydown.esc.prevent="closePanel"
      />

      <p v-if="error" class="field__error">{{ error }}</p>

      <ul class="tag-dropdown__list">
        <li v-for="tag in matches" :key="tag.id">
          <button
            class="tag-dropdown__item"
            type="button"
            role="option"
            :aria-selected="false"
            @click="pick(tag.id)"
          >
            <span>{{ tag.name }}</span>
            <span class="tag-dropdown__meta">
              {{ tag.note_count > 0 ? `${tag.note_count} 篇` : '未使用' }}
            </span>
          </button>
        </li>

        <li v-if="matches.length === 0 && !canCreate" class="tag-dropdown__empty">
          {{ input.trim() ? '没有匹配的标签' : '还没有标签' }}
        </li>

        <li v-if="canCreate">
          <button class="tag-dropdown__item tag-dropdown__item--create" type="button" @click="submit">
            <span>新建「{{ input.trim() }}」</span>
            <span class="tag-dropdown__meta">回车</span>
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>
