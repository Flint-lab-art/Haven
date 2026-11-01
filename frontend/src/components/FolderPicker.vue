<script setup lang="ts">
/**
 * 文件夹选择器（docs/v6/frontend/frontend.md 第三节）。
 *
 * Ranger 式单列导航：
 *   j/k 上下移动 · l/→ 进入文件夹 · h/← 返回上级 · Enter 确认 · Esc 取消
 *
 * `l` 是「进去看看」，`Enter` 才是「就存这里」——两者语义不同，不要合并。
 */
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import type { Folder } from '@/api/folders'

const props = defineProps<{
  open: boolean
  folders: Folder[]
}>()

const emit = defineEmits<{
  select: [folderId: string | null]
  cancel: []
}>()

const dialogRef = ref<HTMLElement | null>(null)
const listRef = ref<HTMLElement | null>(null)

/** 当前所在目录：null 表示根。 */
const currentId = ref<string | null>(null)
const activeIndex = ref(0)

const byId = computed(() => new Map(props.folders.map((f) => [f.id, f])))

/** 当前目录下的子文件夹，按名称排序。 */
const children = computed<Folder[]>(() => {
  const list = props.folders.filter((f) => (f.parent_id ?? null) === currentId.value)
  return list.sort((a, b) => a.name.localeCompare(b.name, 'zh-CN'))
})

/** 面包屑：根 / 项目 / 官网检索器。 */
const breadcrumb = computed(() => {
  const parts: string[] = []
  let id = currentId.value
  const seen = new Set<string>()
  while (id) {
    if (seen.has(id)) break
    seen.add(id)
    const folder = byId.value.get(id)
    if (!folder) break
    parts.unshift(folder.name)
    id = folder.parent_id ?? null
  }
  return parts.length ? parts.join(' / ') : '根目录'
})

/** 左列当前高亮项；Enter 确认的就是它。 */
const activeFolder = computed<Folder | null>(() => children.value[activeIndex.value] ?? null)

/** 右列预览：左列高亮项的子文件夹，只读。 */
const preview = computed<Folder[]>(() => {
  const target = activeFolder.value
  if (!target) return []
  const list = props.folders.filter((f) => (f.parent_id ?? null) === target.id)
  return list.sort((a, b) => a.name.localeCompare(b.name, 'zh-CN'))
})

/** 列表第一项在打开或切换目录时选中。 */
function resetActive(): void {
  activeIndex.value = 0
  void nextTick(scrollIntoView)
}

/** 让选中项保持在可视区。 */
function scrollIntoView(): void {
  const list = listRef.value
  if (!list) return
  const el = list.querySelector<HTMLElement>(`[data-index="${activeIndex.value}"]`)
  el?.scrollIntoView({ block: 'nearest' })
}

function move(delta: number): void {
  const len = children.value.length
  if (len === 0) return
  activeIndex.value = (activeIndex.value + delta + len) % len
  void nextTick(scrollIntoView)
}

/** l / →：进入当前高亮的文件夹。 */
function enterFolder(): void {
  const target = activeFolder.value
  if (!target) return
  currentId.value = target.id
  resetActive()
}

/** h / ←：返回上级；已在根目录时不动。 */
function goUp(): void {
  if (currentId.value === null) return
  const current = byId.value.get(currentId.value)
  const parent = current?.parent_id ?? null
  currentId.value = parent
  resetActive()
}

/**
 * Enter：确认左列高亮项；没有子项时确认当前目录。
 *
 * 这样选「项目 / 官网检索器」只需：l 进入项目 → j/k 选中 → Enter。
 */
function confirm(): void {
  const target = activeFolder.value
  emit('select', target ? target.id : currentId.value)
}

function onKeydown(event: KeyboardEvent): void {
  switch (event.key) {
    case 'j':
    case 'ArrowDown':
      event.preventDefault()
      move(1)
      return
    case 'k':
    case 'ArrowUp':
      event.preventDefault()
      move(-1)
      return
    case 'l':
    case 'ArrowRight':
      event.preventDefault()
      enterFolder()
      return
    case 'h':
    case 'ArrowLeft':
      event.preventDefault()
      goUp()
      return
    case 'Enter':
      event.preventDefault()
      confirm()
      return
    case 'Escape':
      event.preventDefault()
      emit('cancel')
      return
    default:
  }
}

function onPointerDown(event: PointerEvent): void {
  if (!props.open) return
  const target = event.target as Node | null
  if (dialogRef.value && target && dialogRef.value.contains(target)) return
  emit('cancel')
}

watch(
  () => props.open,
  (open) => {
    if (open) {
      // 打开时固定在根目录，从顶层开始选（docs/v6/frontend/frontend.md 3.3）
      currentId.value = null
      resetActive()
      void nextTick(() => dialogRef.value?.focus())
      document.addEventListener('pointerdown', onPointerDown, true)
    } else {
      document.removeEventListener('pointerdown', onPointerDown, true)
    }
  },
)

onMounted(() => {
  if (props.open) document.addEventListener('pointerdown', onPointerDown, true)
})

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', onPointerDown, true)
})
</script>

<template>
  <div v-if="open" class="folder-pick-backdrop" role="presentation">
    <div
      ref="dialogRef"
      class="folder-pick"
      role="dialog"
      aria-modal="true"
      aria-label="选择文件夹"
      tabindex="-1"
      @keydown="onKeydown"
    >
      <header class="folder-pick__head">
        <h2 class="folder-pick__title">选择文件夹</h2>
        <p class="folder-pick__path">{{ breadcrumb }}</p>
      </header>

      <div class="folder-pick__columns">
        <!-- 左列：当前目录的内容，j/k 在这里移动，Enter 确认高亮项 -->
        <div ref="listRef" class="folder-pick__col folder-pick__col--current">
          <p v-if="children.length === 0" class="field__hint" style="padding: 12px 8px">
            这里没有子文件夹。按 Enter 存到这里，或 h 返回上级。
          </p>
          <button
            v-for="(folder, index) in children"
            :key="folder.id"
            :data-index="index"
            class="folder-pick__item"
            :class="{ 'folder-pick__item--active': index === activeIndex }"
            type="button"
            @click="emit('select', folder.id)"
            @mouseenter="activeIndex = index"
          >
            <span class="folder-pick__icon" aria-hidden="true">📁</span>
            <span class="folder-pick__name">{{ folder.name }}</span>
          </button>
        </div>

        <!-- 右列：左列高亮项的子文件夹，只读预览 -->
        <div class="folder-pick__col folder-pick__col--preview">
          <p v-if="preview.length === 0" class="folder-pick__hint">
            {{ activeFolder ? '没有子文件夹' : '' }}
          </p>
          <div v-for="folder in preview" :key="folder.id" class="folder-pick__item folder-pick__item--dim">
            <span class="folder-pick__icon" aria-hidden="true">📁</span>
            <span class="folder-pick__name">{{ folder.name }}</span>
          </div>
        </div>
      </div>

      <footer class="folder-pick__foot">
        <span><kbd>j</kbd><kbd>k</kbd> 移动</span>
        <span><kbd>l</kbd> 进入</span>
        <span><kbd>h</kbd> 上级</span>
        <span><kbd>Enter</kbd> 存到这里</span>
        <span><kbd>Esc</kbd> 取消</span>
      </footer>
    </div>
  </div>
</template>
