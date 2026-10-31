<script setup lang="ts">
/**
 * 历史版本浮层（docs/v2/frontend/frontend.md 第五节）。
 *
 * - 入口只在编辑页工具栏，新建笔记未创建时不显示；
 * - 左栏版本时间线，右栏为选中版本与「当前编辑器内容」的 DIFF；
 * - 不跳转路由，避免离开编辑页丢掉未保存的上下文。
 */
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import ConfirmDialog from './ConfirmDialog.vue'
import { ApiError } from '@/api/client'
import {
  getVersion,
  listVersions,
  restoreVersion,
  type VersionDetail,
  type VersionSummary,
} from '@/api/notes'
import { diffLines, diffStats } from '@/utils/diff'
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

const dialogRef = ref<HTMLElement | null>(null)

const selectedSummary = computed(
  () => versions.value.find((v) => v.id === selectedId.value) ?? null,
)

const lines = computed(() =>
  detail.value ? diffLines(detail.value.content, props.currentContent) : [],
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

function onPointerDown(event: PointerEvent): void {
  if (!props.open) return
  const target = event.target as Node | null
  // 确认框开着时不要把点击当成「点外部」，否则会先关浮层再关确认框
  if (confirmRestore.value) return
  if (dialogRef.value && target && dialogRef.value.contains(target)) return
  emit('close')
}

function onKeydown(event: KeyboardEvent): void {
  if (event.key === 'Escape' && props.open) {
    emit('close')
  }
}

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

// 用 pointerdown 判断点外部，不用 focusout / blur：
// 面板内部焦点转移会被 focusout 误判成移出组件（AGENTS.md 的踩坑记录）。
watch(
  () => props.open,
  (open) => {
    if (open) {
      document.addEventListener('pointerdown', onPointerDown, true)
      document.addEventListener('keydown', onKeydown)
    } else {
      document.removeEventListener('pointerdown', onPointerDown, true)
      document.removeEventListener('keydown', onKeydown)
    }
  },
)

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', onPointerDown, true)
  document.removeEventListener('keydown', onKeydown)
})
</script>

<template>
  <div v-if="open" class="version-overlay" role="presentation">
    <section ref="dialogRef" class="version-dialog" role="dialog" aria-label="历史版本">
      <header class="version-dialog__head">
        <h2 class="version-dialog__title">历史版本</h2>
        <span v-if="stats.added || stats.removed" class="version-dialog__stats">
          <span class="diff-count diff-count--add">+{{ stats.added }}</span>
          <span class="diff-count diff-count--del">−{{ stats.removed }}</span>
        </span>
        <button class="icon-btn" type="button" aria-label="关闭" @click="emit('close')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true">
            <path d="M6 6l12 12M18 6 6 18" />
          </svg>
        </button>
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
                v-for="(line, index) in lines"
                :key="index"
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

      <ConfirmDialog
        :open="confirmRestore"
        title="还原到此版本"
        message="当前内容会被覆盖，且仍可在历史版本中找回。确定继续吗？"
        :busy="restoring"
        @confirm="doRestore"
        @cancel="confirmRestore = false"
      />
    </section>
  </div>
</template>
