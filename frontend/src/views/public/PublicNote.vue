<script setup lang="ts">
/** 公开笔记详情（docs/frontend/frontend.md 第三节）。 */
import { onMounted, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import PublicHeader from '@/components/PublicHeader.vue'
import TagBadge from '@/components/TagBadge.vue'
import { getPublicNote, type PublicNote } from '@/api/notes'
import { formatDate } from '@/utils/format'

const route = useRoute()
const note = ref<PublicNote | null>(null)
const loading = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    note.value = await getPublicNote(String(route.params.id))
  } catch {
    error.value = '这篇笔记不存在，或尚未公开'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <PublicHeader />

  <main class="page">
    <p v-if="loading" class="panel panel--padded">
      <span class="skeleton" style="display: block; width: 50%"></span>
      <span class="skeleton" style="display: block; width: 95%"></span>
    </p>

    <div v-else-if="error" class="panel empty">
      <p class="empty__title">{{ error }}</p>
      <RouterLink :to="{ name: 'public-home' }">返回笔记列表</RouterLink>
    </div>

    <article v-else-if="note" class="panel panel--padded">
      <h1 class="page-title" style="margin-bottom: 8px">{{ note.title }}</h1>
      <p class="field__hint">发布于 {{ formatDate(note.published_at) }}</p>

      <div v-if="note.tags.length" class="tag-row" style="margin-bottom: 24px">
        <TagBadge
          v-for="tag in note.tags"
          :key="tag.id"
          :name="tag.name"
          :to="`/search?q=${encodeURIComponent(tag.name)}`"
        />
      </div>

      <div class="content-body">{{ note.content }}</div>
    </article>
  </main>
</template>
