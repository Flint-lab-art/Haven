<script setup lang="ts">
/** 作品集管理（docs/frontend/frontend.md 第四节 /portfolio）。 */
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

const newItem = reactive({ title: '', description: '', sort_order: 0 })
const repoForm = reactive<Record<string, { platform: 'gogs' | 'github'; repo_path: string; is_primary: boolean }>>({})

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
  <PrivateHeader />

  <main class="page page--wide">
    <h1 class="page-title" style="margin-bottom: 16px">作品集</h1>

    <p v-if="error" class="notice notice--error">{{ error }}</p>

    <form class="panel panel--padded stack" @submit.prevent="create">
      <div class="field">
        <label class="field__label" for="item-title">作品标题</label>
        <input id="item-title" v-model="newItem.title" class="input" type="text" required />
      </div>
      <div class="field">
        <label class="field__label" for="item-desc">简介</label>
        <input id="item-desc" v-model="newItem.description" class="input" type="text" />
      </div>
      <div class="field">
        <label class="field__label" for="item-order">排序（小的在前）</label>
        <input id="item-order" v-model.number="newItem.sort_order" class="input" type="number" />
      </div>
      <button class="btn btn--primary" type="submit" :disabled="busy">添加作品</button>
    </form>

    <div v-if="loading" class="panel panel--padded" style="margin-top: 16px">
      <div class="skeleton" style="width: 40%"></div>
    </div>

    <div v-else-if="items.length === 0" class="panel empty" style="margin-top: 16px">
      <p class="empty__title">还没有作品</p>
      <p>添加作品后，公开首页会展示跳转链接。</p>
    </div>

    <div v-else class="stack" style="margin-top: 16px">
      <section v-for="item in items" :key="item.id" class="panel panel--padded">
        <div class="row" style="align-items: baseline">
          <h2 class="card__title" style="font: var(--text-title2)">{{ item.title }}</h2>
          <span class="field__hint">#{{ item.sort_order }}</span>
          <div class="spacer"></div>
          <button class="btn btn--small" type="button" @click="move(item, -1)">上移</button>
          <button class="btn btn--small" type="button" @click="move(item, 1)">下移</button>
          <button class="btn btn--small btn--danger" type="button" @click="remove(item)">删除</button>
        </div>

        <p v-if="item.description" class="page-subtitle">{{ item.description }}</p>

        <ul v-if="item.repos.length" class="list" style="margin-top: 12px">
          <li v-for="repo in item.repos" :key="repo.id" class="list__row">
            <div class="list__row-main">
              <div class="card__title" style="font: var(--text-subheadline)">
                {{ repo.platform === 'gogs' ? 'Gogs' : 'GitHub' }} · {{ repo.repo_path }}
                <span v-if="repo.is_primary" class="tag" style="margin-left: 6px">主链接</span>
              </div>
              <a :href="repo.url" target="_blank" rel="noopener noreferrer" class="field__hint">
                {{ repo.url }}
              </a>
            </div>
            <button
              class="btn btn--small btn--danger"
              type="button"
              @click="removeRepo(item, repo.id)"
            >
              移除
            </button>
          </li>
        </ul>
        <p v-else class="field__hint" style="margin-top: 12px">还没有关联仓库。</p>

        <form class="row" style="margin-top: 12px; flex-wrap: wrap" @submit.prevent="add(item)">
          <select v-model="repoDraft(item.id).platform" class="select" style="max-width: 120px" aria-label="平台">
            <option value="gogs">Gogs</option>
            <option value="github">GitHub</option>
          </select>
          <input
            v-model="repoDraft(item.id).repo_path"
            class="input"
            type="text"
            placeholder="kairo/haven"
            aria-label="仓库路径"
            style="flex: 1; min-width: 160px"
          />
          <label class="checkbox-row">
            <input v-model="repoDraft(item.id).is_primary" type="checkbox" />
            主链接
          </label>
          <button class="btn btn--small" type="submit" :disabled="busy">添加仓库</button>
        </form>
      </section>
    </div>
  </main>
</template>
