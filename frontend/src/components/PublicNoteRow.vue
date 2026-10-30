<script setup lang="ts">
/** 公开列表项：日期 → 标题 → 纯文本摘要，靠留白分隔，不使用分割线。 */
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { stripMarkdownPreview } from '@/utils/markdown-preview'
import { formatDate } from '@/utils/format'

const props = defineProps<{
  id: string
  title: string
  preview: string
  publishedAt: string | null
}>()

const plainPreview = computed(() => stripMarkdownPreview(props.preview))
</script>

<template>
  <RouterLink :to="`/notes/${id}`" class="public-row">
    <time v-if="publishedAt" class="public-row__date" :datetime="publishedAt">{{ formatDate(publishedAt) }}</time>
    <h2 class="public-row__title">{{ title }}</h2>
    <p v-if="plainPreview" class="public-row__preview">{{ plainPreview }}</p>
  </RouterLink>
</template>
