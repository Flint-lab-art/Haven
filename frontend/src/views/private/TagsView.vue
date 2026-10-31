<script setup lang="ts">
/**
 * 标签页（docs/v3/frontend/frontend.md 第十节）。
 *
 * 只展示：按引用次数倒序列出全部标签，卡片大小一致、配色按引用次数分档。
 * 点击标签弹出居中窗口，列出引用它的笔记；窗口内不提供任何写操作。
 */
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import TagNotesDialog from '@/components/TagNotesDialog.vue'
import { listTags, type Tag } from '@/api/tags'

/**
 * 引用次数的分档阈值（docs/v3/conventions.md 第一节第 3 条）。
 * 数字是代码常量，调档只改这里。
 */
const TIER_HIGH = 10
const TIER_MID = 3

const router = useRouter()

const tags = ref<Tag[]>([])
const loading = ref(true)
const error = ref('')
const opened = ref<Tag | null>(null)

/** 引用多的排前面；次数相同时按名称排，保证顺序稳定。 */
const sorted = computed(() =>
  [...tags.value].sort((a, b) => b.note_count - a.note_count || a.name.localeCompare(b.name, 'zh-Hans-CN')),
)

function tier(tag: Tag): 'high' | 'mid' | 'low' {
  if (tag.note_count >= TIER_HIGH) return 'high'
  if (tag.note_count >= TIER_MID) return 'mid'
  return 'low'
}

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

/** 点笔记：先关窗口再跳转，避免返回时窗口还开着。 */
function openNote(id: string): void {
  opened.value = null
  void router.push({ name: 'note-detail', params: { id } })
}

onMounted(() => void load())
</script>

<template>
  <div class="detail-inner">
    <header class="detail-head">
      <h1 class="detail-title">标签</h1>
      <p class="detail-sub">按引用次数排列；点开标签查看引用了哪些笔记。</p>
    </header>

    <p v-if="error" class="notice notice--error">
      {{ error }}
      <span class="notice__actions">
        <button class="btn btn--sm" type="button" @click="load">重试</button>
      </span>
    </p>

    <div v-else-if="loading && tags.length === 0" class="tag-grid">
      <div v-for="n in 8" :key="n" class="tag-card tag-card--low">
        <div class="skeleton skeleton--title" style="width: 60%; margin: 0 auto"></div>
        <div class="skeleton skeleton--line" style="width: 40%; margin: 10px auto 0"></div>
      </div>
    </div>

    <div v-else-if="tags.length === 0" class="detail-empty" style="min-height: 40svh">
      <p class="detail-empty__title">还没有标签</p>
      <p class="detail-empty__text">写笔记时在顶部「添加标签」，标签会出现在这里。</p>
    </div>

    <div v-else class="tag-grid">
      <button
        v-for="tag in sorted"
        :key="tag.id"
        class="tag-card"
        :class="`tag-card--${tier(tag)}`"
        type="button"
        @click="opened = tag"
      >
        <span class="tag-card__name">{{ tag.name }}</span>
        <span class="tag-card__count">{{ tag.note_count }} 篇笔记</span>
      </button>
    </div>

    <TagNotesDialog
      :open="opened !== null"
      :tag="opened"
      @close="opened = null"
      @open-note="openNote"
    />
  </div>
</template>
