<script setup lang="ts">
/** 私有域里的公开笔记预览：按公开接口取数据，避免把私有接口的草稿状态带进预览。 */
import { onMounted, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
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
  <div class="detail-inner">
    <div v-if="loading">
      <div class="skeleton skeleton--title" style="width: 56%"></div>
      <div class="skeleton skeleton--line" style="width: 92%; margin-top: 16px"></div>
      <div class="skeleton skeleton--line" style="width: 88%"></div>
      <div class="skeleton skeleton--line" style="width: 64%"></div>
    </div>

    <div v-else-if="error" class="detail-empty">
      <p class="detail-empty__title">{{ error }}</p>
      <p class="detail-empty__text">链接可能已失效，或者作者撤回了公开。</p>
    </div>

    <article v-else-if="note">
      <RouterLink :to="{ name: 'note-detail', params: { id: note.id } }" class="btn btn--quiet btn--sm" style="margin-bottom: 16px">
        ← 回到编辑
      </RouterLink>

      <header class="article">
        <h1 class="article__title">{{ note.title }}</h1>
        <div class="article__meta">
          <span>{{ formatDate(note.published_at) }}</span>
          <template v-if="note.tags.length">
            <span class="meta-dot"></span>
            <div class="tag-row">
              <TagBadge
                v-for="tag in note.tags"
                :key="tag.id"
                :name="tag.name"
                :to="`/search?q=${encodeURIComponent(tag.name)}`"
              />
            </div>
          </template>
        </div>
      </header>

      <div class="article__body">{{ note.content }}</div>
    </article>
  </div>
</template>
