<script setup lang="ts">
/**
 * 公开域首页（docs/v3/frontend/frontend.md 第三节）：
 * 品牌标语 → 作品集（双列卡片）→ 近期笔记。
 *
 * 作品集是主位，笔记只显示最近若干篇；两者都受上限约束，
 * 只有内容超过上限时才显示「全部」链接。
 */
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import PublicNoteRow from '@/components/PublicNoteRow.vue'
import { listPublicNotes, type PublicNoteSummary } from '@/api/notes'
import { listPortfolio, type PortfolioItem } from '@/api/portfolio'

/**
 * 首页展示条数上限（docs/v3/conventions.md 第一节第 3 条）。
 * 这些是代码常量，不进文档也不进环境变量。
 */
const HOME_PORTFOLIO_LIMIT = 4
const HOME_NOTE_LIMIT = 5

const projects = ref<PortfolioItem[]>([])
const projectTotal = ref(0)
const notes = ref<PublicNoteSummary[]>([])
const noteTotal = ref(0)
const loading = ref(true)

const hasProjects = computed(() => projectTotal.value > 0)
const hasNotes = computed(() => noteTotal.value > 0)
const isEmpty = computed(() => !loading.value && !hasProjects.value && !hasNotes.value)

/** 仅当作品超过首页上限时才给「全部」入口。 */
const showAllProjects = computed(() => projectTotal.value > HOME_PORTFOLIO_LIMIT)
const showAllNotes = computed(() => noteTotal.value > HOME_NOTE_LIMIT)

/** 主仓库优先，其余按平台排列；首页卡片只展示文字，不做跳转排序以外的处理。 */
function sortedRepos(item: PortfolioItem) {
  return [...item.repos].sort((a, b) => Number(b.is_primary) - Number(a.is_primary))
}

async function load(): Promise<void> {
  loading.value = true
  try {
    // 两块互不阻塞：任一失败不影响另一块展示
    const [portfolio, notesResult] = await Promise.allSettled([
      listPortfolio(),
      listPublicNotes(HOME_NOTE_LIMIT, 0),
    ])

    if (portfolio.status === 'fulfilled') {
      projectTotal.value = portfolio.value.total
      projects.value = portfolio.value.items.slice(0, HOME_PORTFOLIO_LIMIT)
    }
    if (notesResult.status === 'fulfilled') {
      noteTotal.value = notesResult.value.total
      notes.value = notesResult.value.items.slice(0, HOME_NOTE_LIMIT)
    }
  } finally {
    loading.value = false
  }
}

onMounted(() => void load())
</script>

<template>
  <main class="home">
    <header class="home-hero">
      <h1 class="home-hero__title">正在做的事和写过的东西</h1>
      <p class="home-hero__sub">一些项目和零散的记录。</p>
    </header>

    <section v-if="hasProjects" class="home-section">
      <div class="home-section__head">
        <h2 class="home-section__title">作品集</h2>
        <RouterLink v-if="showAllProjects" :to="{ name: 'public-portfolio' }" class="home-section__more">
          全部 {{ projectTotal }} 个 →
        </RouterLink>
      </div>

      <div class="project-grid">
        <RouterLink
          v-for="item in projects"
          :key="item.id"
          :to="{ name: 'public-portfolio-detail', params: { id: item.id } }"
          class="project-card"
        >
          <h3 class="project-card__title">{{ item.title }}</h3>
          <p v-if="item.description" class="project-card__desc">{{ item.description }}</p>
          <div v-if="item.repos.length" class="project-card__repos">
            <span
              v-for="repo in sortedRepos(item)"
              :key="repo.id"
              class="repo-pill"
              :class="{ 'repo-pill--primary': repo.is_primary }"
            >
              {{ repo.kind === 'link' ? (repo.title || '链接') : repo.kind === 'gogs' ? 'Gogs' : 'GitHub' }}
            </span>
          </div>
        </RouterLink>
      </div>
    </section>

    <section v-if="hasNotes" class="home-section">
      <div class="home-section__head">
        <h2 class="home-section__title">近期笔记</h2>
        <RouterLink v-if="showAllNotes" :to="{ name: 'public-notes' }" class="home-section__more">
          全部 {{ noteTotal }} 篇 →
        </RouterLink>
      </div>

      <div class="home-notes">
        <PublicNoteRow
          v-for="note in notes"
          :key="note.id"
          :id="note.id"
          :title="note.title"
          :preview="note.content_preview"
          :published-at="note.published_at"
        />
      </div>
    </section>

    <p v-if="isEmpty" class="home-empty">这里还空空的</p>
  </main>
</template>
