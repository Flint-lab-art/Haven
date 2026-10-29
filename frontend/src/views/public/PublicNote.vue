<script setup lang="ts">
/** 公开笔记详情：Markdown 渲染 + 居中阅读列 + 宽屏大纲。 */
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import NoteOutline from '@/components/NoteOutline.vue'
import PublicEmpty from '@/components/PublicEmpty.vue'
import TagBadge from '@/components/TagBadge.vue'
import { getPublicNote, type PublicNote } from '@/api/notes'
import { renderMarkdown, decorateLinks } from '@/utils/markdown'
import { extractHeadings } from '@/utils/markdown-headings'
import { formatDate } from '@/utils/format'

const route = useRoute()
const note = ref<PublicNote | null>(null)
const loading = ref(true)
const error = ref('')
const articleRef = ref<HTMLElement | null>(null)
const activeHeading = ref(-1)

const rendered = computed(() => decorateLinks(renderMarkdown(note.value?.content ?? '')))
const outline = computed(() => extractHeadings(note.value?.content ?? ''))

function headingElements(): HTMLElement[] {
  return Array.from(articleRef.value?.querySelectorAll<HTMLElement>('.md-body h1, .md-body h2, .md-body h3') ?? [])
}

let activeFrame = 0

function scheduleActiveUpdate(): void {
  if (activeFrame) return
  activeFrame = requestAnimationFrame(() => {
    activeFrame = 0
    const elements = headingElements()
    if (elements.length === 0) {
      activeHeading.value = -1
      return
    }

    const threshold = 120
    let current = 0
    elements.forEach((element, index) => {
      if (element.getBoundingClientRect().top <= threshold) current = index
    })
    activeHeading.value = Math.min(current, outline.value.length - 1)
  })
}

function goToHeading(index: number): void {
  headingElements()[index]?.scrollIntoView({ behavior: 'smooth', block: 'start' })
  activeHeading.value = index
}

watch([outline, note], () => requestAnimationFrame(scheduleActiveUpdate))

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  note.value = null
  activeHeading.value = -1
  try {
    note.value = await getPublicNote(String(route.params.id))
  } catch {
    error.value = '这篇笔记不存在，或尚未公开'
  } finally {
    loading.value = false
  }
}

watch(() => route.params.id, () => void load(), { immediate: true })

onMounted(() => {
  window.addEventListener('scroll', scheduleActiveUpdate, { passive: true })
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', scheduleActiveUpdate)
  if (activeFrame) cancelAnimationFrame(activeFrame)
})
</script>

<template>
  <main v-if="loading" class="container">
    <div class="skeleton skeleton--title" style="width: 56%"></div>
    <div class="skeleton skeleton--line" style="width: 92%; margin-top: 20px"></div>
    <div class="skeleton skeleton--line" style="width: 88%"></div>
    <div class="skeleton skeleton--line" style="width: 64%"></div>
  </main>

  <main v-else-if="error" class="container">
    <PublicEmpty :title="error" text="链接可能已失效，或者作者撤回了公开。">
      <RouterLink :to="{ name: 'public-home' }" class="btn btn--primary">返回笔记列表</RouterLink>
    </PublicEmpty>
  </main>

  <main v-else-if="note" class="public-reading">
    <article ref="articleRef" class="public-article">
      <RouterLink :to="{ name: 'public-home' }" class="btn btn--quiet btn--sm" style="margin-bottom: 24px">
        ← 全部笔记
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

      <!-- eslint-disable-next-line vue/no-v-html -- 已经过 DOMPurify 过滤 -->
      <div v-if="rendered" class="md-body" v-html="rendered"></div>
      <p v-else class="field__hint">这篇笔记还没有正文。</p>
    </article>

    <aside v-if="outline.length" class="public-outline">
      <NoteOutline :items="outline" :active-index="activeHeading" @select="goToHeading" />
    </aside>
  </main>
</template>
