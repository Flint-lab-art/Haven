<script setup lang="ts">
/**
 * 中间栏：回收站列表（docs/v2/frontend/frontend.md 第三节）。
 *
 * 只回答「哪些笔记被删了」：按删除时间倒序，选中项交给右侧详情区还原或永久删除。
 * 不提供历史版本入口——历史版本只在编辑页出现。
 */
import { onMounted, ref, watch } from 'vue'
import ConfirmDialog from './ConfirmDialog.vue'
import { ApiError } from '@/api/client'
import { emptyTrash, listTrash, type TrashItem } from '@/api/notes'
import { useUiStore } from '@/stores/ui'
import { formatDate } from '@/utils/format'

const ui = useUiStore()

const items = ref<TrashItem[]>([])
const loading = ref(true)
const error = ref('')
const emptying = ref(false)
const confirmEmpty = ref(false)

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    const result = await listTrash(100, 0)
    items.value = result.items
    if (ui.selectedTrashId && !items.value.some((item) => item.id === ui.selectedTrashId)) {
      ui.selectTrash(null)
    }
  } catch {
    error.value = '回收站加载失败'
  } finally {
    loading.value = false
  }
}

async function confirmEmptyTrash(): Promise<void> {
  if (emptying.value) return
  emptying.value = true
  error.value = ''
  try {
    await emptyTrash()
    items.value = []
    ui.selectTrash(null)
    ui.trashChanged()
    ui.notesChanged()
    confirmEmpty.value = false
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '清空回收站失败'
    confirmEmpty.value = false
  } finally {
    emptying.value = false
  }
}

watch(
  () => ui.trashVersion,
  () => void load(),
)
onMounted(() => void load())
</script>

<template>
  <div class="list-panel">
    <header class="panel-head">
      <h1 class="panel-title">回收站</h1>
      <button
        v-if="items.length > 0"
        class="btn btn--sm btn--danger"
        type="button"
        :disabled="emptying"
        @click="confirmEmpty = true"
      >
        清空
      </button>
    </header>

    <p v-if="error" class="notice notice--error" style="margin: 0 16px 12px">{{ error }}</p>

    <div v-if="loading && items.length === 0" style="padding: 0 16px">
      <div class="skeleton skeleton--title" style="width: 40%"></div>
    </div>

    <div v-else-if="items.length === 0" class="detail-empty" style="min-height: 40svh">
      <p class="detail-empty__title">回收站是空的</p>
      <p class="detail-empty__text">删除的笔记会先放在这里，30 天内都可以还原。</p>
    </div>

    <div v-else class="list-rows">
      <button
        v-for="item in items"
        :key="item.id"
        class="list-row"
        :class="{ 'list-row--active': ui.selectedTrashId === item.id }"
        type="button"
        @click="ui.selectTrash(item.id)"
      >
        <span class="list-row__title">{{ item.title }}</span>
        <span class="list-row__meta">
          <template v-if="item.folder_path">{{ item.folder_path }} · </template>
          {{ formatDate(item.deleted_at) }}
        </span>
      </button>
    </div>

    <ConfirmDialog
      :open="confirmEmpty"
      title="清空回收站"
      message="回收站里的笔记会被永久删除，无法恢复。"
      :busy="emptying"
      @confirm="confirmEmptyTrash"
      @cancel="confirmEmpty = false"
    />
  </div>
</template>
