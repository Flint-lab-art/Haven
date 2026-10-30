<script setup lang="ts">
/** 中间栏标签列表。选中项交给右侧的标签详情处理。 */
import { onMounted, ref, watch } from 'vue'
import { listTags, type Tag } from '@/api/tags'
import { useUiStore } from '@/stores/ui'

const ui = useUiStore()

const tags = ref<Tag[]>([])
const loading = ref(true)
const error = ref('')

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    tags.value = (await listTags()).items
  } catch {
    error.value = '标签加载失败'
  } finally {
    loading.value = false
  }
}

watch(
  () => ui.tagsVersion,
  () => void load(),
)
onMounted(() => void load())
</script>

<template>
  <div class="list-panel">
    <header class="panel-head">
      <h1 class="panel-title">标签</h1>
      <span class="field__hint">{{ loading ? '' : `${tags.length} 个` }}</span>
    </header>

    <p v-if="error" class="notice notice--error" style="margin: 0 16px 12px">{{ error }}</p>

    <div v-if="loading && tags.length === 0" style="padding: 0 16px">
      <div class="skeleton skeleton--title" style="width: 40%"></div>
    </div>

    <div v-else-if="tags.length === 0" class="detail-empty" style="min-height: 40svh">
      <p class="detail-empty__title">还没有标签</p>
      <p class="detail-empty__text">在右侧新建，写笔记时就能挂上去。</p>
    </div>

    <div v-else class="list-rows">
      <button
        v-for="tag in tags"
        :key="tag.id"
        class="list-row"
        :class="{ 'list-row--active': ui.selectedTagId === tag.id }"
        type="button"
        @click="ui.selectTag(tag.id)"
      >
        <span class="list-row__title">{{ tag.name }}</span>
        <span class="list-row__meta">{{ tag.note_count }}</span>
      </button>
    </div>
  </div>
</template>
