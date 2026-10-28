<script setup lang="ts">
/** 笔记卡片：列表里的一条笔记（不含正文，只用后端截好的 content_preview）。 */
import { RouterLink } from 'vue-router'
import TagBadge from './TagBadge.vue'
import type { TagBrief } from '@/api/notes'

withDefaults(
  defineProps<{
    id: string
    title: string
    preview: string
    tags?: TagBrief[]
    meta?: string
    /** 是否展示 visibility 标记（公开域不展示）。 */
    visibility?: 'private' | 'public' | null
    /** 详情链接目标，默认私有域 /notes/:id。 */
    to?: string
  }>(),
  { tags: () => [], meta: '', visibility: null, to: undefined },
)
</script>

<template>
  <RouterLink :to="to ?? `/notes/${id}`" class="card">
    <div class="card__title">{{ title }}</div>
    <div v-if="preview" class="card__preview">{{ preview }}</div>
    <div v-if="meta || visibility" class="card__meta">
      <span v-if="visibility === 'public'">已公开</span>
      <span v-else-if="visibility === 'private'">私有</span>
      <span v-if="meta">{{ meta }}</span>
    </div>
    <div v-if="tags && tags.length" class="tag-row">
      <TagBadge v-for="tag in tags" :key="tag.id" :name="tag.name" />
    </div>
  </RouterLink>
</template>
