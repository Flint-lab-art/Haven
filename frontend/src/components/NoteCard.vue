<script setup lang="ts">
/** 笔记列表项。列表不返回正文，只展示后端截好的 content_preview。 */
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
    /** 公开域不传，私有域标记私有/已公开。 */
    visibility?: 'private' | 'public' | null
    to?: string
  }>(),
  { tags: () => [], meta: '', visibility: null, to: undefined },
)
</script>

<template>
  <RouterLink :to="to ?? `/notes/${id}`" class="note-item">
    <div class="note-item__head">
      <span class="note-item__title">{{ title }}</span>
      <span v-if="visibility === 'public'" class="badge badge--public">已公开</span>
      <span v-else-if="visibility === 'private'" class="badge badge--private">私有</span>
    </div>

    <p v-if="preview" class="note-item__preview">{{ preview }}</p>

    <div v-if="meta || (tags && tags.length)" class="note-item__meta">
      <span v-if="meta">{{ meta }}</span>
      <span v-if="meta && tags && tags.length" class="meta-dot"></span>
      <span v-if="tags && tags.length">{{ tags.length }} 个标签</span>
    </div>

    <div v-if="tags && tags.length" class="tag-row" style="margin-top: 10px">
      <TagBadge v-for="tag in tags" :key="tag.id" :name="tag.name" />
    </div>
  </RouterLink>
</template>
