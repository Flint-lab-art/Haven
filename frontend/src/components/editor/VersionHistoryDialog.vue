<script setup lang="ts">
/**
 * 历史版本浮层（docs/v2/frontend/frontend.md 第五节）。
 *
 * - 入口只在编辑页工具栏，新建笔记未创建时不显示；
 * - 左栏版本时间线，右栏为选中版本与「当前编辑器内容」的 DIFF；
 * - 不跳转路由，避免离开编辑页丢掉未保存的上下文。
 */
import { computed, ref, watch } from 'vue'
import {
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogOverlay,
  DialogPortal,
  DialogRoot,
  DialogTitle,
} from 'reka-ui'
import ConfirmDialog from '@/components/common/ConfirmDialog.vue'
import { ApiError } from '@/api/client'
import {
  getVersion,
  listVersions,
  restoreVersion,
  type VersionDetail,
  type VersionSummary,
} from '@/api/notes'
import { X } from 'lucide-vue-next'

import { diffLines, diffStats } from '@/utils/diff'
import { stripHtml } from '@/utils/html'
import { formatDateTime } from '@/utils/format'

const props = defineProps<{
  open: boolean
  noteId: string
  /** 当前编辑器正文，作为 DIFF 的新侧基准。 */
  currentContent: string
  /** 当前编辑器标题，用于提示标题是否也变了。 */
  currentTitle: string
}>()

const emit = defineEmits<{
  close: []
  /** 还原成功后通知父组件刷新编辑器内容。 */
  restored: []
}>()

const versions = ref<VersionSummary[]>([])
const selectedId = ref<string | null>(null)
const detail = ref<VersionDetail | null>(null)
const loading = ref(false)
const loadingDetail = ref(false)
const restoring = ref(false)
const error = ref('')
const confirmRestore = ref(false)

const selectedSummary = computed(
  () => versions.value.find((v) => v.id === selectedId.value) ?? null,
)

const lines = computed(() =>
  detail.value
    ? diffLines(stripHtml(detail.value.content), stripHtml(props.currentContent))
    : [],
)

/**
 * 给每条 diff 行补一个稳定 key。
 *
 * 行号在同一份 diff 内唯一（same 行两者都有，其余至少有一个），
 * 比数组下标更适合做 key：切换版本时 Vue 能正确复用而不是错位重绘。
 */
const diffRows = computed(() =>
  lines.value.map((line, index) => ({
    ...line,
    key: `${index}-${line.oldLine ?? 'x'}-${line.newLine ?? 'x'}`,
  })),
)

const stats = computed(() => diffStats(lines.value))

/** 标题与当前编辑器标题是否不同，供顶部单独提示。 */
const titleChanged = computed(
  () => Boolean(detail.value) && detail.value!.title !== props.currentTitle,
)

async function loadVersions(): Promise<void> {
  if (!props.noteId) return
  loading.value = true
  error.value = ''
  try {
    const result = await listVersions(props.noteId, 50, 0)
    versions.value = result.items
    if (versions.value.length > 0) {
      selectVersion(versions.value[0].id)
    } else {
      selectedId.value = null
      detail.value = null
    }
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '历史版本加载失败'
  } finally {
    loading.value = false
  }
}

async function selectVersion(id: string): Promise<void> {
  selectedId.value = id
  loadingDetail.value = true
  error.value = ''
  try {
    detail.value = await getVersion(props.noteId, id)
  } catch (err) {
    detail.value = null
    error.value = err instanceof ApiError ? err.message : '版本内容加载失败'
  } finally {
    loadingDetail.value = false
  }
}

async function doRestore(): Promise<void> {
  const id = selectedId.value
  if (!id || restoring.value) return

  restoring.value = true
  error.value = ''
  try {
    await restoreVersion(props.noteId, id)
    confirmRestore.value = false
    emit('restored')
    emit('close')
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '还原失败'
    confirmRestore.value = false
  } finally {
    restoring.value = false
  }
}

// 点外部 / Esc / 焦点陷阱交给 Reka Dialog：
// 确认框（AlertDialog）叠在上面时会自己吃掉点击，不用再判 confirmRestore。
watch(
  () => props.open,
  (open) => {
    if (open) {
      void loadVersions()
    } else {
      versions.value = []
      selectedId.value = null
      detail.value = null
      error.value = ''
    }
  },
)
</script>

<template>
  <DialogRoot :open="open" @update:open="(value: boolean) => !value && emit('close')">
    <DialogPortal>
      <DialogOverlay class="version-overlay" />
      <DialogContent class="version-dialog">
        <header class="version-dialog__head">
          <DialogTitle class="version-dialog__title">历史版本</DialogTitle>
          <DialogDescription class="sr-only">
            左侧选择版本，右侧查看与当前内容的差异，可还原到选中版本。
          </DialogDescription>
          <span v-if="stats.added || stats.removed" class="version-dialog__stats">
            <span class="diff-count diff-count--add">+{{ stats.added }}</span>
            <span class="diff-count diff-count--del">−{{ stats.removed }}</span>
          </span>
          <DialogClose as-child>
            <button class="icon-btn" type="button" aria-label="关闭">
              <X aria-hidden="true" />
            </button>
          </DialogClose>
        </header>

      <p v-if="error" class="notice notice--error" style="margin: 0 16px 12px">{{ error }}</p>

      <div class="version-dialog__body">
        <nav class="version-timeline" aria-label="版本时间线">
          <div v-if="loading" style="padding: 12px">
            <div class="skeleton skeleton--title" style="width: 60%"></div>
          </div>
          <p v-else-if="versions.length === 0" class="field__hint" style="padding: 12px">
            还没有历史版本。编辑并保存一次后就会出现。
          </p>
          <button
            v-for="version in versions"
            v-else
            :key="version.id"
            class="version-item"
            :class="{ 'version-item--active': selectedId === version.id }"
            type="button"
            @click="selectVersion(version.id)"
          >
            <span class="version-item__time">{{ formatDateTime(version.created_at) }}</span>
            <span class="version-item__title">{{ version.title }}</span>
          </button>
        </nav>

        <div class="version-diff">
          <p v-if="loadingDetail" class="field__hint" style="padding: 12px">加载中…</p>

          <template v-else-if="detail">
            <p v-if="titleChanged" class="version-diff__title-note">
              标题也变了：这一版是「{{ detail.title }}」，当前是「{{ currentTitle }}」。
            </p>

            <div v-if="lines.length === 0" class="field__hint" style="padding: 12px">
              这一版与当前内容完全一致。
            </div>

            <div v-else class="diff-view">
              <div
                v-for="line in diffRows"
                :key="line.key"
                class="diff-line"
                :class="`diff-line--${line.kind}`"
              >
                <span class="diff-line__no">{{ line.oldLine ?? '' }}</span>
                <span class="diff-line__no">{{ line.newLine ?? '' }}</span>
                <span class="diff-line__sign">
                  {{ line.kind === 'added' ? '+' : line.kind === 'removed' ? '−' : ' ' }}
                </span>
                <span class="diff-line__text">{{ line.text || '\u00a0' }}</span>
              </div>
            </div>
          </template>

          <p v-else class="field__hint" style="padding: 12px">从左侧选一个版本。</p>
        </div>
      </div>

      <footer class="version-dialog__foot">
        <span class="field__hint">
          对比的是该版本 ↔ 当前内容（未保存的修改也算在内）
        </span>
        <button
          class="btn btn--primary btn--sm"
          type="button"
          :disabled="!selectedSummary || restoring"
          @click="confirmRestore = true"
        >
          还原到此版本
        </button>
      </footer>

      </DialogContent>
    </DialogPortal>
  </DialogRoot>

  <!-- 确认框叠在版本浮层之上；它自己管理焦点与 Esc，所以与 Root 平级 -->
  <ConfirmDialog
    :open="confirmRestore"
    title="还原到此版本"
    message="当前内容会被覆盖，且仍可在历史版本中找回。确定继续吗？"
    :busy="restoring"
    @confirm="doRestore"
    @cancel="confirmRestore = false"
  />
</template>
