<script setup lang="ts">
/** 作品集管理：作品列表 + 每个作品的仓库链接编辑。 */
import { onMounted, reactive, ref } from 'vue'
import PrivateHeader from '@/components/PrivateHeader.vue'
import { ApiError } from '@/api/client'
import {
  addRepo,
  createItem,
  deleteItem,
  deleteRepo,
  listPortfolio,
  updateItem,
  type PortfolioItem,
} from '@/api/portfolio'

const items = ref<PortfolioItem[]>([])
const loading = ref(true)
const error = ref('')
const busy = ref(false)
const showNew = ref(false)

const newItem = reactive({ title: '', description: '', sort_order: 0 })
const repoForm = reactive<Record<string, { platform: 'gogs' | 'github'; repo_path: string; is_primary: boolean }>>({})
/** 展开仓库编辑的作品 id。 */
const expanded = ref<string | null>(null)

function repoDraft(itemId: string) {
  if (!repoForm[itemId]) {
    repoForm[itemId] = { platform: 'gogs', repo_path: '', is_primary: false }
  }
  return repoForm[itemId]
}

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    items.value = (await listPortfolio()).items
  } catch {
    error.value = '作品集加载失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

function handleError(err: unknown): void {
  if (err instanceof ApiError) {
    error.value = err.fields ? Object.values(err.fields).join('；') : err.message
  } else {
    error.value = '操作失败，请稍后重试'
  }
}

async function create(): Promise<void> {
  const title = newItem.title.trim()
  if (!title || busy.value) return

  busy.value = true
  error.value = ''
  try {
    await createItem({
      title,
      description: newItem.description,
      sort_order: Number(newItem.sort_order) || 0,
    })
    newItem.title = ''
    newItem.description = ''
    newItem.sort_order = 0
    showNew.value = false
    await load()
  } catch (err) {
    handleError(err)
  } finally {
    busy.value = false
  }
}

async function move(item: PortfolioItem, delta: number): Promise<void> {
  error.value = ''
  try {
    await updateItem(item.id, { sort_order: item.sort_order + delta })
    await load()
  } catch (err) {
    handleError(err)
  }
}

async function remove(item: PortfolioItem): Promise<void> {
  if (!window.confirm(`删除作品「${item.title}」及其仓库链接？`)) return

  error.value = ''
  try {
    await deleteItem(item.id)
    await load()
  } catch (err) {
    handleError(err)
  }
}

async function add(item: PortfolioItem): Promise<void> {
  const draft = repoDraft(item.id)
  if (!draft.repo_path.trim() || busy.value) return

  busy.value = true
  error.value = ''
  try {
    await addRepo(item.id, {
      platform: draft.platform,
      repo_path: draft.repo_path.trim(),
      is_primary: draft.is_primary,
    })
    draft.repo_path = ''
    draft.is_primary = false
    await load()
  } catch (err) {
    handleError(err)
  } finally {
    busy.value = false
  }
}

async function removeRepo(item: PortfolioItem, repoId: string): Promise<void> {
  error.value = ''
  try {
    await deleteRepo(item.id, repoId)
    await load()
  } catch (err) {
    handleError(err)
  }
}

onMounted(load)
</script>

<template>
  <div class="shell">
    <PrivateHeader />

    <main class="container">
      <header class="page-head">
        <div>
          <h1 class="page-title">作品集</h1>
          <p class="page-sub">
            {{ loading ? '加载中…' : `${items.length} 个项目 · 公开首页会展示跳转链接` }}
          </p>
        </div>
        <button class="btn btn--primary btn--lg" type="button" @click="showNew = !showNew">
          {{ showNew ? '收起' : '添加作品' }}
        </button>
      </header>

      <p v-if="error" class="notice notice--error">{{ error }}</p>

      <form v-if="showNew" class="panel panel--pad" style="margin-bottom: var(--sp-4)" @submit.prevent="create">
        <div class="field">
          <label class="field__label" for="item-title">作品标题</label>
          <input id="item-title" v-model="newItem.title" class="input" type="text" placeholder="Haven" required />
        </div>
        <div class="field">
          <label class="field__label" for="item-desc">一句话简介</label>
          <input id="item-desc" v-model="newItem.description" class="input" type="text" placeholder="自托管的个人知识中台" />
        </div>
        <div class="field">
          <label class="field__label" for="item-order">排序（小的在前）</label>
          <input id="item-order" v-model.number="newItem.sort_order" class="input" type="number" style="max-width: 140px" />
        </div>
        <div class="row" style="justify-content: flex-end">
          <button class="btn" type="button" @click="showNew = false">取消</button>
          <button class="btn btn--primary" type="submit" :disabled="busy">添加</button>
        </div>
      </form>

      <div v-if="loading" class="panel panel--pad">
        <div class="skeleton skeleton--title" style="width: 40%"></div>
      </div>

      <div v-else-if="items.length === 0" class="panel empty">
        <p class="empty__title">还没有作品</p>
        <p class="empty__text">添加作品和代码仓库链接后，公开首页会展示它们。</p>
        <button class="btn btn--primary" type="button" @click="showNew = true">添加作品</button>
      </div>

      <div v-else class="panel rows">
        <div v-for="item in items" :key="item.id" class="row-item" style="display: block; padding: var(--sp-5)">
          <div class="row row--wrap" style="align-items: baseline">
            <span class="row-item__title">{{ item.title }}</span>
            <span class="field__hint">#{{ item.sort_order }}</span>
            <div class="spacer"></div>
            <div class="row">
              <button class="btn btn--sm" type="button" @click="move(item, -1)" aria-label="上移">↑</button>
              <button class="btn btn--sm" type="button" @click="move(item, 1)" aria-label="下移">↓</button>
              <button class="btn btn--sm" type="button" @click="expanded = expanded === item.id ? null : item.id">
                {{ expanded === item.id ? '收起仓库' : '仓库' }}
              </button>
              <button class="btn btn--sm btn--danger" type="button" @click="remove(item)">删除</button>
            </div>
          </div>

          <p v-if="item.description" class="row-item__sub">{{ item.description }}</p>

          <div v-if="item.repos.length" class="tag-row" style="margin-top: 10px">
            <span v-for="repo in item.repos" :key="repo.id" class="repo-link" :class="{ 'repo-link--primary': repo.is_primary }">
              {{ repo.platform === 'gogs' ? 'Gogs' : 'GitHub' }}
              <span style="opacity: 0.7">{{ repo.repo_path }}</span>
            </span>
          </div>
          <p v-else class="field__hint" style="margin-top: 8px">还没有关联仓库。</p>

          <div v-if="expanded === item.id" style="margin-top: var(--sp-4)">
            <ul v-if="item.repos.length" class="rows" style="border: 1px solid var(--sep); border-radius: var(--r-md); overflow: hidden">
              <li v-for="repo in item.repos" :key="repo.id" class="row-item">
                <div class="row-item__main">
                  <div class="row-item__title" style="font: var(--text-subheadline)">
                    {{ repo.platform === 'gogs' ? 'Gogs' : 'GitHub' }} · {{ repo.repo_path }}
                    <span v-if="repo.is_primary" class="badge badge--public">主链接</span>
                  </div>
                  <a :href="repo.url" target="_blank" rel="noopener noreferrer" class="row-item__sub">
                    {{ repo.url }}
                  </a>
                </div>
                <button class="btn btn--sm btn--danger" type="button" @click="removeRepo(item, repo.id)">
                  移除
                </button>
              </li>
            </ul>

            <form class="row row--wrap" style="gap: var(--sp-2); margin-top: var(--sp-3)" @submit.prevent="add(item)">
              <select v-model="repoDraft(item.id).platform" class="select" style="max-width: 118px" aria-label="平台">
                <option value="gogs">Gogs</option>
                <option value="github">GitHub</option>
              </select>
              <input
                v-model="repoDraft(item.id).repo_path"
                class="input"
                type="text"
                placeholder="kairo/haven"
                aria-label="仓库路径"
                style="flex: 1; min-width: 150px"
              />
              <label class="checkbox-row">
                <input v-model="repoDraft(item.id).is_primary" type="checkbox" />
                主链接
              </label>
              <button class="btn btn--sm" type="submit" :disabled="busy">添加仓库</button>
            </form>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>
