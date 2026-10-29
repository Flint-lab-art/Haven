<script setup lang="ts">
/** 中间栏笔记列表项（ui-design.md 4.1）：平铺行、标题 + 80 字摘要 + 更新时间与可见性图标。 */
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { stripMarkdownPreview } from '@/utils/markdown-preview'

const props = withDefaults(
  defineProps<{
    id: string
    title: string
    preview: string
    meta?: string
    visibility: 'private' | 'public'
    active?: boolean
  }>(),
  { meta: '', active: false },
)

/** 后端给的是 200 字 Markdown 预览：先剥掉标记，再按字符截到 80。 */
const shortPreview = computed(() => {
  const plain = stripMarkdownPreview(props.preview ?? '')
  const chars = Array.from(plain)
  if (chars.length <= 80) return plain
  return `${chars.slice(0, 80).join('')}…`
})
</script>

<template>
  <RouterLink
    :to="{ name: 'note-detail', params: { id } }"
    class="note-row"
    :class="{ 'note-row--active': active }"
    :aria-current="active ? 'page' : undefined"
  >
    <div class="note-row__head">
      <span class="note-row__title">{{ title }}</span>
      <svg
        v-if="visibility === 'public'"
        class="vis-icon vis-icon--public"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="1.7"
        aria-label="已公开"
      >
        <circle cx="12" cy="12" r="9" />
        <path d="M3 12h18M12 3c2.5 2.4 3.8 5.6 3.8 9S14.5 18.6 12 21c-2.5-2.4-3.8-5.6-3.8-9S9.5 5.4 12 3z" />
      </svg>
      <svg
        v-else
        class="vis-icon vis-icon--private"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="1.7"
        stroke-linejoin="round"
        aria-label="私有"
      >
        <rect x="5" y="10" width="14" height="10" rx="2" />
        <path d="M8 10V7a4 4 0 0 1 8 0v3" />
      </svg>
    </div>

    <p v-if="shortPreview" class="note-row__preview">{{ shortPreview }}</p>
    <div v-if="meta" class="note-row__meta">{{ meta }}</div>
  </RouterLink>
</template>
