<script setup lang="ts">
/**
 * 命令面板（docs/v6/frontend/frontend.md 第一节）。
 *
 * Cmd/Ctrl+K 打开，输入规则：
 *   - `s ` + 关键词     搜笔记（只搜标题）
 *   - `n ` + 标题       新建笔记并预填标题
 *   - `d` / `w` / `t` / `g` / `p` / `,` 回车   打开对应页面
 *   - 其他              按命令名或 key 前缀匹配
 *
 * 命令固定七条，不做运行时注册（docs/v6/conventions.md 2.2）。
 */
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { searchPrivate, type SearchNoteHit } from '@/api/search'
import { listFolders, type Folder } from '@/api/folders'
import FolderPicker from './FolderPicker.vue'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  close: []
}>()

/** 搜索防抖：连续输入只在停顿后发一次请求（docs/v6/conventions.md 第一节第 5 条）。 */
const SEARCH_DEBOUNCE = 150

const router = useRouter()

const query = ref('')
const activeIndex = ref(0)
const results = ref<SearchNoteHit[]>([])
const searching = ref(false)
const dialogRef = ref<HTMLElement | null>(null)
const inputRef = ref<HTMLInputElement | null>(null)

/** 新建带标题时，先弹文件夹选择器（docs/v6/frontend/frontend.md 第三节）。 */
const pickingFolder = ref(false)
const pendingTitle = ref('')
const folders = ref<Folder[]>([])

let debounceTimer: ReturnType<typeof setTimeout> | undefined
/** 中文输入法是否处于组合状态：组合期间的 query 是拼音，不能拿去搜。 */
let composing = false
/** 请求序号：后发起的请求先返回时，丢弃旧响应。 */
let requestSeq = 0

type Command = {
  key: string
  /** 单字母别名：输入该字母即可匹配到这条命令。 */
  alias: string
  label: string
  icon: string
  run: () => void
}

/** 四条固定命令。 */
const commands = computed<Command[]>(() => [
  {
    key: 'new',
    alias: 'n',
    label: '新建笔记',
    icon: '✏️',
    run: () => go({ name: 'note-create' }),
  },
  {
    key: 'dashboard',
    alias: 'd',
    label: '打开仪表盘',
    icon: '📊',
    run: () => go({ name: 'home' }),
  },
  {
    key: 'workbench',
    alias: 'w',
    label: '打开工作台',
    icon: '📁',
    run: () => go({ name: 'workbench' }),
  },
  {
    key: 'tags',
    alias: 't',
    label: '打开标签',
    icon: '🏷️',
    run: () => go({ name: 'tags' }),
  },
  {
    key: 'trash',
    alias: 'g',
    label: '打开回收站',
    icon: '🗑️',
    run: () => go({ name: 'trash' }),
  },
  {
    key: 'portfolio',
    alias: 'p',
    label: '打开作品集',
    icon: '🗂️',
    run: () => go({ name: 'portfolio' }),
  },
  {
    key: 'settings',
    alias: ',',
    label: '打开设置',
    icon: '⚙️',
    run: () => go({ name: 'settings' }),
  },
])

/**
 * 前缀正则：s / n 后面跟空格或直接跟内容都算。
 *
 * 用中文输入法打 `s` 容易得到全角 `ｓ`，空格也常是全角 `　`，
 * 所以这里统一做全角归一化再匹配，避免前缀识别不到导致「搜什么都是命令列表」。
 */
const PREFIX = /^([sSnN])[\s\u3000]?(.*)$/

/** 全角字符转半角，只处理前缀相关的部分。 */
function normalizePrefix(raw: string): string {
  return raw
    .replace(/^ｓ/, 's')
    .replace(/^Ｓ/, 'S')
    .replace(/^ｎ/, 'n')
    .replace(/^Ｎ/, 'N')
}

/** 解析出的前缀模式。 */
const mode = computed<'idle' | 'search' | 'new-title' | 'command'>(() => {
  const m = PREFIX.exec(normalizePrefix(query.value))
  if (!m) return 'command'
  // 只有前缀、没有内容时，仍按命令处理（方便用 d / w 直接回车）
  if (m[2].trim() === '') return 'command'
  return m[1].toLowerCase() === 's' ? 'search' : 'new-title'
})

/** 去掉前缀后的实际参数。 */
const argument = computed(() => {
  const m = PREFIX.exec(normalizePrefix(query.value))
  if (!m) return ''
  return m[2].trim()
})

/** 命令模式下按前缀字母或名称过滤。 */
const visibleCommands = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (!q) return commands.value
  return commands.value.filter((c) => {
    // 单字母别名优先精确匹配，其次才是 key 前缀与中文标签
    if (c.alias === q) return true
    if (c.key.startsWith(q)) return true
    return c.label.toLowerCase().includes(q)
  })
})

/** 面板里展示的条目：数组顺序即上下键顺序。 */
interface Entry {
  kind: 'note' | 'command'
  id: string
  title: string
  icon: string
  run: () => void
}

const entries = computed<Entry[]>(() => {
  if (mode.value === 'search') {
    return results.value.map((n) => ({
      kind: 'note' as const,
      id: n.id,
      title: n.title,
      icon: '📄',
      run: () => go({ name: 'note-detail', params: { id: n.id } }),
    }))
  }
  if (mode.value === 'new-title') {
    const title = argument.value
    return [
      {
        kind: 'command' as const,
        id: 'create-with-title',
        title: title ? `新建笔记「${title}」` : '新建笔记（输入标题）',
        icon: '✏️',
        run: () => {
          void startCreateWithTitle(title)
        },
      },
    ]
  }
  return visibleCommands.value.map((c) => ({
    kind: 'command' as const,
    id: c.key,
    title: c.label,
    icon: c.icon,
    run: c.run,
  }))
})

/** 条目数量变化后把选中项夹在范围内，避免越界导致没有任何高亮。 */
watch(entries, (list) => {
  if (list.length === 0) {
    activeIndex.value = 0
  } else if (activeIndex.value >= list.length) {
    activeIndex.value = list.length - 1
  }
})

/** 空状态文案。 */
const emptyText = computed(() => {
  if (mode.value === 'search') {
    return argument.value ? '没有匹配的笔记' : '输入关键词搜索笔记'
  }
  if (mode.value === 'new-title') return ''
  return '没有匹配的命令'
})

function go(location: Parameters<typeof router.push>[0]): void {
  emit('close')
  void router.push(location)
}

/** 新建带标题：先拉文件夹列表并弹选择器，选完再跳转。 */
async function startCreateWithTitle(title: string): Promise<void> {
  pendingTitle.value = title
  try {
    folders.value = (await listFolders()).items
  } catch {
    // 拉取失败时退回收件箱，不让用户卡在这里
    folders.value = []
  }
  pickingFolder.value = true
}

/** 选中文件夹：带着标题与 folder_id 跳到新建页。 */
function onFolderSelected(folderId: string | null): void {
  const title = pendingTitle.value
  pickingFolder.value = false
  const query: Record<string, string> = {}
  if (title) query.title = title
  if (folderId) query.folder_id = folderId
  go({ name: 'note-create', query })
}

/** 取消选择：回到命令面板，保留输入。 */
function onFolderCancel(): void {
  pickingFolder.value = false
  void nextTick(() => inputRef.value?.focus())
}

/** 有输入时按标题搜索，带防抖与竞态保护。 */
function runSearch(keyword: string): void {
  if (debounceTimer) clearTimeout(debounceTimer)

  if (!keyword) {
    results.value = []
    searching.value = false
    return
  }

  searching.value = true
  debounceTimer = setTimeout(async () => {
    const seq = ++requestSeq
    try {
      const res = await searchPrivate(keyword, 20, 0, 'title')
      // 后发起的请求已经返回，丢弃这次旧响应
      if (seq !== requestSeq) return
      results.value = res.notes.items
    } catch {
      if (seq !== requestSeq) return
      results.value = []
    } finally {
      if (seq === requestSeq) searching.value = false
    }
  }, SEARCH_DEBOUNCE)
}

watch(
  () => query.value,
  (raw) => {
    // 输入法组合期间的值是拼音，等 compositionend 再搜（见 onCompositionEnd）
    if (composing) return
    activeIndex.value = 0
    const m = PREFIX.exec(normalizePrefix(raw))
    if (m && m[1].toLowerCase() === 's' && m[2].trim() !== '') {
      runSearch(m[2].trim())
    } else {
      if (debounceTimer) clearTimeout(debounceTimer)
      results.value = []
      searching.value = false
    }
  },
)

watch(
  () => props.open,
  (open) => {
    if (open) {
      query.value = ''
      results.value = []
      activeIndex.value = 0
      void nextTick(() => inputRef.value?.focus())
      document.addEventListener('keydown', onGlobalKeydown)
    } else {
      document.removeEventListener('keydown', onGlobalKeydown)
      if (debounceTimer) clearTimeout(debounceTimer)
    }
  },
)

/** 输入法开始组合：暂停搜索。 */
function onCompositionStart(): void {
  composing = true
}

/**
 * 输入法结束组合：用最终的中文值重新搜一次。
 *
 * Vue 的 v-model 在组合期间不更新，因此这里要手动按当前 query 触发。
 */
function onCompositionEnd(): void {
  composing = false
  const m = PREFIX.exec(normalizePrefix(query.value))
  if (m && m[1].toLowerCase() === 's' && m[2].trim() !== '') {
    runSearch(m[2].trim())
  }
}

/** 面板内的按键处理：上下移动与回车执行。 */
function onInputKeydown(event: KeyboardEvent): void {
  const list = entries.value
  if (event.key === 'ArrowDown') {
    event.preventDefault()
    if (list.length) activeIndex.value = (activeIndex.value + 1) % list.length
  } else if (event.key === 'ArrowUp') {
    event.preventDefault()
    if (list.length) activeIndex.value = (activeIndex.value - 1 + list.length) % list.length
  } else if (event.key === 'Enter') {
    event.preventDefault()
    list[activeIndex.value]?.run()
  }
}

/** Esc 关闭；Cmd+K 在全局处理成 toggle。 */
function onGlobalKeydown(event: KeyboardEvent): void {
  if (event.key === 'Escape' && props.open) {
    event.preventDefault()
    emit('close')
  }
}

function onPointerDown(event: PointerEvent): void {
  if (!props.open) return
  const target = event.target as Node | null
  if (dialogRef.value && target && dialogRef.value.contains(target)) return
  emit('close')
}

watch(
  () => props.open,
  (open) => {
    if (open) {
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
  document.removeEventListener('keydown', onGlobalKeydown)
  if (debounceTimer) clearTimeout(debounceTimer)
})
</script>

<template>
  <div v-if="open" class="cmdk-backdrop" role="presentation">
    <div ref="dialogRef" class="cmdk" role="dialog" aria-modal="true" aria-label="命令面板">
      <div class="cmdk__input-row">
        <span class="cmdk__hint">›</span>
        <input
          ref="inputRef"
          v-model="query"
          class="cmdk__input"
          type="text"
          autocomplete="off"
          autocorrect="off"
          autocapitalize="off"
          spellcheck="false"
          placeholder="s 搜索 · n 新建 · d 仪表盘 · w 工作台"
          aria-label="输入命令或关键词"
          @keydown="onInputKeydown"
          @compositionstart="onCompositionStart"
          @compositionend="onCompositionEnd"
        />
      </div>

      <div class="cmdk__body">
        <p v-if="searching && entries.length === 0" class="cmdk__empty">搜索中…</p>
        <p v-else-if="entries.length === 0" class="cmdk__empty">{{ emptyText }}</p>

        <ul v-else class="cmdk__list">
          <li v-for="(entry, index) in entries" :key="entry.id">
            <button
              class="cmdk__item"
              :class="{ 'cmdk__item--active': index === activeIndex }"
              type="button"
              @click="entry.run()"
              @mouseenter="activeIndex = index"
            >
              <span class="cmdk__item-icon" aria-hidden="true">{{ entry.icon }}</span>
              <span class="cmdk__item-title">{{ entry.title }}</span>
            </button>
          </li>
        </ul>
      </div>

      <FolderPicker
        :open="pickingFolder"
        :folders="folders"
        @select="onFolderSelected"
        @cancel="onFolderCancel"
      />

      <div class="cmdk__foot">
        <span><kbd>↑</kbd><kbd>↓</kbd> 选择</span>
        <span><kbd>Enter</kbd> 打开</span>
        <span><kbd>Esc</kbd> 关闭</span>
      </div>
    </div>
  </div>
</template>
