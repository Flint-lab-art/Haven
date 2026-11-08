<script setup lang="ts">
/** 公开搜索：只搜已公开笔记。 */
import { ref, watch } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import SearchBar from '@/components/SearchBar.vue'
import PublicEmpty from '@/components/PublicEmpty.vue'
import PublicNoteRow from '@/components/PublicNoteRow.vue'
import { searchPublic, type SearchNoteHit } from '@/api/search'

const route = useRoute()
const keyword = ref(String(route.query.q ?? ''))
const results = ref<SearchNoteHit[]>([])
const total = ref(0)
const loading = ref(false)
const error = ref('')
const searched = ref('')

async function run(q: string): Promise<void> {
  if (!q.trim()) {
    results.value = []
    total.value = 0
    searched.value = ''
    return
  }

  loading.value = true
  error.value = ''
  searched.value = q.trim()
  try {
    const result = await searchPublic(q)
    results.value = result.items
    total.value = result.total
  } catch {
    error.value = '搜索失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

watch(
  () => route.query.q,
  (q) => {
    keyword.value = String(q ?? '')
    void run(keyword.value)
  },
  { immediate: true },
)
</script>

<template>
  <main class="container">
    <header class="public-page-head">
      <h1 class="public-page-head__title">搜索</h1>
      <p class="public-page-head__sub">
        {{ searched ? `“${searched}” · ${total} 篇结果` : '按标题、正文或标签查找公开笔记' }}
      </p>
    </header>

    <SearchBar v-model="keyword" large />

    <p v-if="error" class="notice notice--error" style="margin-top: 24px">{{ error }}</p>

    <template v-if="searched">
      <div v-if="loading" class="public-list public-notes" style="margin-top: 24px">
        <div v-for="n in 2" :key="n" class="public-row">
          <div class="skeleton skeleton--title" style="width: 46%"></div>
          <div class="skeleton skeleton--line" style="width: 84%; margin-top: 12px"></div>
        </div>
      </div>

      <PublicEmpty
        v-else-if="results.length === 0"
        title="没有找到相关内容"
        text="换个关键词试试，或者回到全部笔记。"
      >
        <RouterLink :to="{ name: 'public-home' }" class="btn">返回笔记列表</RouterLink>
      </PublicEmpty>

      <div v-else class="public-list public-notes" style="margin-top: 24px">
        <PublicNoteRow
          v-for="hit in results"
          :key="hit.id"
          :id="hit.id"
          :title="hit.title"
          :preview="hit.content_preview"
          :published-at="hit.published_at"
        />
      </div>
    </template>

    <PublicEmpty
      v-else
      title="输入关键词开始搜索"
      text="支持标题、正文与标签。"
    />
  </main>
</template>
