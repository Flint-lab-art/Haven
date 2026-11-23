<script setup lang="ts">
/** 中间栏笔记列表项（ui-design.md 4.1）：平铺行、标题 + 80 字摘要 + 更新时间。 */
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

const props = withDefaults(
  defineProps<{
    id: string
    title: string
    preview: string
    meta?: string
    active?: boolean
  }>(),
  { meta: '', active: false },
)

/** 后端给的是已经去过 HTML 的 200 字纯文本：直接按字符截到 80。 */
const shortPreview = computed(() => {
  const plain = (props.preview ?? '').trim()
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
    </div>

    <p v-if="shortPreview" class="note-row__preview">{{ shortPreview }}</p>
    <div v-if="meta" class="note-row__meta">{{ meta }}</div>
  </RouterLink>
</template>
