<script setup lang="ts">
/**
 * 文件夹图标选择面板。
 *
 * 四个来源页：全部（emoji + 品牌 + 已上传图片）、Emoji、品牌图标、已上传图片。
 * 面板本身不保存任何东西，选中后通过 `select` 把图标值交给调用方写库；
 * 上传与取消也由调用方决定（它持有 busy 状态与 refresh）。
 */
import { computed, nextTick, ref, watch } from 'vue'
import { isUploadableImage, listUploads, type UploadedFile } from '@/api/uploads'
import { BRAND_ICONS, brandColor, searchBrandGroups, type BrandIcon } from '@/utils/brand-icons'
import { searchEmojiGroups } from '@/utils/emoji'

type IconTab = 'all' | 'emoji' | 'brand' | 'image'

const props = defineProps<{
  /** 面板是否打开；@param 打开时由父组件控制。 */
  open: boolean
  /** 上传中时禁用上传与选择按钮。 */
  disabled?: boolean
}>()

const emit = defineEmits<{
  /** 选中一个图标值（emoji 字符、品牌 key 或图片 URL）；null 表示恢复默认。 */
  select: [value: string | null]
  /** 选了一张本地图片，交给父组件上传。 */
  upload: [file: File]
  /** 关闭面板。 */
  close: []
}>()

const ICON_TABS: { key: IconTab; label: string; emoji: string }[] = [
  { key: 'all', label: '全部', emoji: '✦' },
  { key: 'emoji', label: 'Emoji', emoji: '🙂' },
  { key: 'brand', label: '品牌', emoji: '◈' },
  { key: 'image', label: '图片', emoji: '🖼' },
]

const tab = ref<IconTab>('all')
/** 品牌图标与 Emoji 共用的搜索词。 */
const query = ref('')
/** 已上传的图片（来自 GET /api/uploads），打开「图片」页时拉取。 */
const uploadedImages = ref<UploadedFile[]>([])
const uploadsLoading = ref(false)

const brandGroups = computed(() => searchBrandGroups(query.value))
const brandIcons = computed(() => brandGroups.value.flatMap((g) => g.items))
const emojiGroups = computed(() => searchEmojiGroups(query.value))
/** 「全部」页里的 emoji 也跟随搜索（匹配分组名）。 */
const filteredEmoji = computed(() => emojiGroups.value.flatMap((g) => g.items))
/** 「全部」页里已上传图片不过滤（没有名字可搜）。 */
const filteredUploads = computed(() => (query.value.trim() ? [] : uploadedImages.value))

// 每次打开都重置到「全部」页
watch(
  () => props.open,
  (open) => {
    if (!open) return
    tab.value = 'all'
    query.value = ''
  },
)

/** 切换来源页；「图片」与「全部」页要先拉一次列表。 */
function selectTab(next: IconTab): void {
  tab.value = next
  if (next === 'image' || next === 'all') {
    void loadUploads()
    return
  }
  if (next === 'brand') {
    void nextTick(() => {
      document.querySelector<HTMLInputElement>('.icon-picker__search')?.focus()
    })
  }
}

/** 拉取已上传的图片列表。失败只影响「图片」页，不打断其他页。 */
async function loadUploads(): Promise<void> {
  if (uploadsLoading.value) return
  uploadsLoading.value = true
  try {
    uploadedImages.value = (await listUploads(60)).items
  } catch {
    uploadedImages.value = []
  } finally {
    uploadsLoading.value = false
  }
}

/** 选择一个本地图片作为图标：真正上传由父组件负责。 */
function pickImageFile(): void {
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/png,image/jpeg,image/gif,image/webp'
  input.addEventListener('change', () => {
    const file = input.files?.[0]
    if (file) emit('upload', file)
  })
  input.click()
}

/**
 * 面板内粘贴：图片走上传，短文本当作 Emoji。
 *
 * 只在内容像一个短图标时才接管，避免复制一段正文后误把整段文字设成图标。
 */
function onPaste(event: ClipboardEvent): void {
  const data = event.clipboardData
  if (!data) return

  const file = Array.from(data.files ?? []).find(isUploadableImage)
  if (file) {
    event.preventDefault()
    emit('upload', file)
    return
  }

  const text = data.getData('text/plain').trim()
  if (!text || text.length > 16) return
  event.preventDefault()
  emit('select', text)
}

/** 图标是不是品牌 logo 的 key（如 go / python）。 */
function asBrand(icon: string | null | undefined): BrandIcon | undefined {
  if (!icon || icon.startsWith('/')) return undefined
  return BRAND_ICONS.find((it) => it.key === icon)
}

/** 图片加载失败时退回默认图标，不显示破图。 */
function onImageError(event: Event): void {
  ;(event.target as HTMLImageElement).style.display = 'none'
}

defineExpose({ asBrand })
</script>

<template>
  <div
    class="icon-picker"
    role="dialog"
    aria-label="选择文件夹图标"
    @click.stop
    @paste="onPaste"
  >
    <div class="icon-picker__tabs" role="tablist" aria-label="图标来源">
      <button
        v-for="item in ICON_TABS"
        :key="item.key"
        class="icon-picker__tab"
        :class="{ 'icon-picker__tab--active': tab === item.key }"
        type="button"
        role="tab"
        :aria-selected="tab === item.key"
        @click="selectTab(item.key)"
      >
        <span aria-hidden="true">{{ item.emoji }}</span>
        {{ item.label }}
      </button>
    </div>

    <!-- 全部：emoji + 品牌 + 已上传图片，带搜索与上传入口 -->
    <div v-if="tab === 'all'" class="icon-picker__all">
      <div class="icon-picker__allbar">
        <input
          v-model="query"
          class="input icon-picker__search"
          type="search"
          placeholder="搜索图标"
          aria-label="搜索图标"
        />
        <button
          class="icon-picker__upload-btn"
          type="button"
          title="上传图片作为图标"
          aria-label="上传图片作为图标"
          :disabled="disabled"
          @click="pickImageFile"
        >
          +
        </button>
      </div>

      <div class="icon-picker__grid-scroll">
        <div class="icon-picker__brand-grid">
          <button
            v-for="emoji in filteredEmoji"
            :key="`e-${emoji}`"
            class="icon-picker__emoji-btn"
            type="button"
            :aria-label="`使用 ${emoji} 作为图标`"
            @click="emit('select', emoji)"
          >
            {{ emoji }}
          </button>
          <button
            v-for="icon in brandIcons"
            :key="icon.key"
            class="icon-picker__brand"
            type="button"
            :title="icon.label"
            :aria-label="`使用 ${icon.label} 图标`"
            :style="{ '--brand-color': brandColor(icon) }"
            @click="emit('select', icon.key)"
          >
            <!-- eslint-disable-next-line vue/no-v-html -- 构建期导入的可信 SVG -->
            <span class="icon-picker__brand-svg" v-html="icon.svg"></span>
          </button>
          <button
            v-for="file in filteredUploads"
            :key="file.url"
            class="icon-picker__image-btn"
            type="button"
            title="已上传的图片"
            @click="emit('select', file.url)"
          >
            <img :src="file.url" alt="" @error="onImageError" />
          </button>
        </div>
      </div>

      <p
        v-if="brandIcons.length === 0 && filteredUploads.length === 0 && filteredEmoji.length === 0"
        class="field__hint"
      >
        没有匹配的图标
      </p>
    </div>

    <!-- Emoji：按分组展示，可按分组名搜索 -->
    <div v-else-if="tab === 'emoji'" class="icon-picker__emojis">
      <input
        v-model="query"
        class="input icon-picker__search"
        type="search"
        placeholder="搜索分类：技术 / 文档 / 自然…"
        aria-label="搜索 emoji 分类"
      />
      <div class="icon-picker__emoji-scroll">
        <div v-for="group in emojiGroups" :key="group.label" class="icon-picker__emoji-group">
          <p class="icon-picker__emoji-label">{{ group.label }}</p>
          <div class="icon-picker__grid">
            <button
              v-for="emoji in group.items"
              :key="emoji"
              class="icon-picker__choice"
              type="button"
              :aria-label="`使用 ${emoji} 作为图标`"
              @click="emit('select', emoji)"
            >
              {{ emoji }}
            </button>
          </div>
        </div>
        <p v-if="emojiGroups.length === 0" class="field__hint">没有匹配的分类</p>
      </div>
    </div>

    <!-- 品牌图标：按分组展示，可按分类名或图标名搜索 -->
    <div v-else-if="tab === 'brand'" class="icon-picker__brands">
      <input
        v-model="query"
        class="input icon-picker__search"
        type="search"
        placeholder="搜索分类或图标：前端 / Go…"
        aria-label="搜索品牌图标"
      />
      <div class="icon-picker__brand-scroll">
        <div v-for="group in brandGroups" :key="group.label" class="icon-picker__brand-group">
          <p class="icon-picker__emoji-label">{{ group.label }}</p>
          <div class="icon-picker__brand-grid">
            <button
              v-for="icon in group.items"
              :key="icon.key"
              class="icon-picker__brand"
              type="button"
              :title="icon.label"
              :aria-label="`使用 ${icon.label} 图标`"
              :style="{ '--brand-color': brandColor(icon) }"
              @click="emit('select', icon.key)"
            >
              <!-- eslint-disable-next-line vue/no-v-html -- 构建期导入的可信 SVG -->
              <span class="icon-picker__brand-svg" v-html="icon.svg"></span>
            </button>
          </div>
        </div>
        <p v-if="brandGroups.length === 0" class="field__hint">没有匹配的图标</p>
      </div>
    </div>

    <!-- 已上传的图片 -->
    <div v-else class="icon-picker__images">
      <div v-if="uploadsLoading" class="field__hint">加载中…</div>
      <p v-else-if="uploadedImages.length === 0" class="field__hint">
        还没有上传过图片。在「全部」页点 + 上传，或直接粘贴。
      </p>
      <div v-else class="icon-picker__brand-grid">
        <button
          v-for="file in uploadedImages"
          :key="file.url"
          class="icon-picker__image-btn"
          type="button"
          title="使用这张图片作为图标"
          @click="emit('select', file.url)"
        >
          <img :src="file.url" alt="" @error="onImageError" />
        </button>
      </div>
    </div>

    <div class="icon-picker__actions">
      <button class="btn btn--sm" type="button" :disabled="disabled" @click="emit('select', null)">
        恢复默认
      </button>
      <button class="btn btn--sm" type="button" @click="emit('close')">取消</button>
    </div>
  </div>
</template>
