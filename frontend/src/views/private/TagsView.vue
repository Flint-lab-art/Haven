<script setup lang="ts">
/** 标签管理（docs/frontend/frontend.md 第四节）：只支持创建与删除，没有重命名。 */
import { onMounted, ref } from 'vue'
import PrivateHeader from '@/components/PrivateHeader.vue'
import { ApiError } from '@/api/client'
import { createTag, deleteTag, listTags, type Tag } from '@/api/tags'

const tags = ref<Tag[]>([])
const name = ref('')
const loading = ref(true)
const error = ref('')
const creating = ref(false)

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    tags.value = (await listTags()).items
  } catch {
    error.value = '标签加载失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

async function create(): Promise<void> {
  const value = name.value.trim()
  if (!value || creating.value) return

  creating.value = true
  error.value = ''
  try {
    await createTag(value)
    name.value = ''
    await load()
  } catch (err) {
    if (err instanceof ApiError && err.status === 409) {
      error.value = `标签「${value}」已存在`
    } else if (err instanceof ApiError) {
      error.value = err.message
    } else {
      error.value = '创建失败，请稍后重试'
    }
  } finally {
    creating.value = false
  }
}

async function remove(tag: Tag): Promise<void> {
  if (!window.confirm(`删除标签「${tag.name}」？笔记不会被删除，只解除关联。`)) return

  error.value = ''
  try {
    await deleteTag(tag.id)
    await load()
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '删除失败，请稍后重试'
  }
}

onMounted(load)
</script>

<template>
  <PrivateHeader />

  <main class="page">
    <h1 class="page-title" style="margin-bottom: 16px">标签</h1>

    <form class="row" @submit.prevent="create">
      <input
        v-model="name"
        class="input"
        type="text"
        placeholder="新标签名"
        aria-label="新标签名"
        maxlength="64"
      />
      <button class="btn btn--primary" type="submit" :disabled="creating">添加</button>
    </form>

    <p v-if="error" class="notice notice--error" style="margin-top: 16px">{{ error }}</p>

    <div v-if="loading" class="panel panel--padded" style="margin-top: 16px">
      <div class="skeleton" style="width: 40%"></div>
    </div>

    <div v-else-if="tags.length === 0" class="panel empty" style="margin-top: 16px">
      <p class="empty__title">还没有标签</p>
      <p>创建标签后，可以在编辑笔记时挂上去。</p>
    </div>

    <ul v-else class="panel list" style="margin-top: 16px">
      <li v-for="tag in tags" :key="tag.id" class="list__row">
        <div class="list__row-main">
          <div class="card__title">{{ tag.name }}</div>
          <div class="card__meta">{{ tag.note_count }} 篇笔记</div>
        </div>
        <button class="btn btn--small btn--danger" type="button" @click="remove(tag)">删除</button>
      </li>
    </ul>
  </main>
</template>
