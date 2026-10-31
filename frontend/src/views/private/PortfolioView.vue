<script setup lang="ts">
/**
 * 右侧作品集详情：新建作品、编辑作品信息、管理仓库链接。
 * 列表在中间栏，选中项与「正在新建」由 ui store 维护。
 */
import { computed, onMounted, reactive, ref, watch } from 'vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import { ApiError } from '@/api/client'
import {
  addRepo,
  createItem,
  getPortfolioItem,
  deleteItem,
  deleteRepo,
  listPortfolio,
  updateItem,
  type PortfolioItem,
} from '@/api/portfolio'
import { useUiStore } from '@/stores/ui'

const ui = useUiStore()

const items = ref<PortfolioItem[]>([])
const loading = ref(true)
const busy = ref(false)
const error = ref('')

const pendingItem = ref<PortfolioItem | null>(null)
const deleting = ref(false)

const draft = reactive({ title: '', description: '', content: '', sort_order: 0 })
const newItem = reactive({ title: '', description: '', content: '', sort_order: 0 })
const repoDraft = reactive({ platform: 'gogs' as 'gogs' | 'github', repo_path: '', is_primary: false })

const selected = computed(() => items.value.find((item) => item.id === ui.selectedPortfolioId) ?? null)

async function load(): Promise<void> {
  loading.value = true
  try {
    items.value = (await listPortfolio()).items
    if (ui.selectedPortfolioId && !items.value.some((item) => item.id === ui.selectedPortfolioId)) {
      ui.selectPortfolio(null)
    }
  } catch {
    error.value = '作品集加载失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

/**
 * 选中作品后拉一次详情。
 *
 * 列表走的是公开接口，不返回 content（docs/v3/api.md 2.1），
 * 所以正文必须单独取，否则保存后会被空串覆盖。
 */
async function syncDraft(item: PortfolioItem | null): Promise<void> {
  if (!item) return
  // 保存过程中列表会重新加载，此时不要把草稿覆盖回服务端旧值
  if (busy.value) return
  draft.title = item.title
  draft.description = item.description
  draft.sort_order = item.sort_order
  draft.content = item.content ?? ''

  try {
    const detail = await getPortfolioItem(item.id)
    // 期间用户可能已切到别的作品，避免把旧请求的结果写进来
    if (ui.selectedPortfolioId !== item.id) return
    draft.title = detail.title
    draft.description = detail.description
    draft.content = detail.content ?? ''
    draft.sort_order = detail.sort_order
  } catch {
    // 拉详情失败时保留列表里的字段，正文留空不报错
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
    const created = await createItem({
      title,
      description: newItem.description,
      content: newItem.content,
      sort_order: Number(newItem.sort_order) || 0,
    })
    newItem.title = ''
    newItem.description = ''
    newItem.content = ''
    newItem.sort_order = 0
    ui.selectPortfolio(created.id)
    ui.portfolioChanged()
    await load()
  } catch (err) {
    handleError(err)
  } finally {
    busy.value = false
  }
}

async function save(): Promise<void> {
  if (!selected.value || busy.value) return

  busy.value = true
  error.value = ''
  try {
    await updateItem(selected.value.id, {
      title: draft.title.trim(),
      description: draft.description,
      content: draft.content,
      sort_order: Number(draft.sort_order) || 0,
    })
    ui.portfolioChanged()
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
    ui.portfolioChanged()
    await load()
  } catch (err) {
    handleError(err)
  }
}

function remove(item: PortfolioItem): void {
  pendingItem.value = item
}

async function confirmRemove(): Promise<void> {
  const item = pendingItem.value
  if (!item || deleting.value) return

  deleting.value = true
  error.value = ''
  try {
    await deleteItem(item.id)
    ui.selectPortfolio(null)
    ui.portfolioChanged()
    await load()
    pendingItem.value = null
  } catch (err) {
    handleError(err)
    pendingItem.value = null
  } finally {
    deleting.value = false
  }
}

async function addLink(item: PortfolioItem): Promise<void> {
  if (!repoDraft.repo_path.trim() || busy.value) return

  busy.value = true
  error.value = ''
  try {
    await addRepo(item.id, {
      platform: repoDraft.platform,
      repo_path: repoDraft.repo_path.trim(),
      is_primary: repoDraft.is_primary,
    })
    repoDraft.repo_path = ''
    repoDraft.is_primary = false
    ui.portfolioChanged()
    await load()
  } catch (err) {
    handleError(err)
  } finally {
    busy.value = false
  }
}

async function removeLink(item: PortfolioItem, repoId: string): Promise<void> {
  error.value = ''
  try {
    await deleteRepo(item.id, repoId)
    ui.portfolioChanged()
    await load()
  } catch (err) {
    handleError(err)
  }
}

watch(
  () => ui.selectedPortfolioId,
  () => void syncDraft(selected.value),
)
watch(
  () => ui.portfolioVersion,
  () => void load(),
)
watch(selected, (value) => void syncDraft(value))

onMounted(load)
</script>

<template>
  <div class="detail-inner">
    <header class="detail-head">
      <h1 class="detail-title">作品集</h1>
      <p class="detail-sub">项目与代码仓库；公开首页会展示跳转链接。</p>
    </header>

    <p v-if="error" class="notice notice--error" style="margin-bottom: 16px">{{ error }}</p>

    <!-- 新建 -->
    <form v-if="ui.portfolioCreating" class="panel panel--pad" @submit.prevent="create">
      <h2 class="row-item__title">添加作品</h2>

      <div class="field" style="margin-top: 16px">
        <label class="field__label" for="item-title">作品标题</label>
        <input id="item-title" v-model="newItem.title" class="input" type="text" placeholder="Haven" required />
      </div>
      <div class="field" style="margin-top: 12px">
        <label class="field__label" for="item-desc">一句话简介</label>
        <input id="item-desc" v-model="newItem.description" class="input" type="text" placeholder="自托管的个人知识中台" />
      </div>
      <div class="field" style="margin-top: 12px">
        <label class="field__label" for="item-content">介绍正文（Markdown，公开详情页展示）</label>
        <textarea
          id="item-content"
          v-model="newItem.content"
          class="input textarea"
          rows="6"
          placeholder="这个作品是做什么的、解决了什么问题、有什么特性……"
        ></textarea>
      </div>
      <div class="field" style="margin-top: 12px; max-width: 160px">
        <label class="field__label" for="item-order">排序（小的在前）</label>
        <input id="item-order" v-model.number="newItem.sort_order" class="input" type="number" />
      </div>

      <div class="row" style="justify-content: flex-end; margin-top: 16px">
        <button class="btn" type="button" @click="ui.selectPortfolio(null)">取消</button>
        <button class="btn btn--primary" type="submit" :disabled="busy">添加</button>
      </div>
    </form>

    <!-- 编辑已有作品：基本信息在左、仓库链接在右，避免右侧留白 -->
    <template v-else-if="selected">
      <div class="portfolio-editor">
      <section class="panel panel--pad">
        <div class="row" style="justify-content: space-between; align-items: baseline">
          <h2 class="row-item__title">基本信息</h2>
          <div class="row">
            <button class="btn btn--sm" type="button" @click="move(selected, -1)" aria-label="上移">↑</button>
            <button class="btn btn--sm" type="button" @click="move(selected, 1)" aria-label="下移">↓</button>
          </div>
        </div>

        <div class="field" style="margin-top: 16px">
          <label class="field__label" for="edit-title">标题</label>
          <input id="edit-title" v-model="draft.title" class="input" type="text" />
        </div>
        <div class="field" style="margin-top: 12px">
          <label class="field__label" for="edit-desc">一句话简介</label>
          <input id="edit-desc" v-model="draft.description" class="input" type="text" />
        </div>
        <div class="field" style="margin-top: 12px">
          <label class="field__label" for="edit-content">介绍正文（Markdown，公开详情页展示）</label>
          <textarea
            id="edit-content"
            v-model="draft.content"
            class="input textarea"
            rows="10"
            placeholder="这个作品是做什么的、解决了什么问题、有什么特性……"
          ></textarea>
        </div>
        <div class="field" style="margin-top: 12px; max-width: 160px">
          <label class="field__label" for="edit-order">排序</label>
          <input id="edit-order" v-model.number="draft.sort_order" class="input" type="number" />
        </div>

        <div class="row" style="justify-content: space-between; margin-top: 16px">
          <button class="btn btn--danger btn--sm" type="button" @click="remove(selected)">删除作品</button>
          <button class="btn btn--primary" type="button" :disabled="busy" @click="save">保存</button>
        </div>
      </section>

      <section class="panel panel--pad">
        <h2 class="row-item__title">仓库链接</h2>

        <ul v-if="selected.repos.length" class="rows" style="margin-top: 12px">
          <li v-for="repo in selected.repos" :key="repo.id" class="row-item">
            <div class="row-item__main">
              <div class="row-item__title">
                {{ repo.platform === 'gogs' ? 'Gogs' : 'GitHub' }} · {{ repo.repo_path }}
                <span v-if="repo.is_primary" class="badge badge--public">主链接</span>
              </div>
              <a :href="repo.url" target="_blank" rel="noopener noreferrer" class="row-item__sub">
                {{ repo.url }}
              </a>
            </div>
            <button class="btn btn--sm btn--danger" type="button" @click="removeLink(selected, repo.id)">
              移除
            </button>
          </li>
        </ul>
        <p v-else class="field__hint" style="margin-top: 12px">还没有关联仓库。</p>

        <form class="row row--wrap" style="gap: 8px; margin-top: 16px" @submit.prevent="addLink(selected)">
          <select v-model="repoDraft.platform" class="select" style="max-width: 116px" aria-label="平台">
            <option value="gogs">Gogs</option>
            <option value="github">GitHub</option>
          </select>
          <input
            v-model="repoDraft.repo_path"
            class="input"
            type="text"
            placeholder="kairo/haven"
            aria-label="仓库路径"
            style="flex: 1; min-width: 150px"
          />
          <label class="checkbox-row">
            <input v-model="repoDraft.is_primary" type="checkbox" />
            主链接
          </label>
          <button class="btn btn--sm" type="submit" :disabled="busy">添加仓库</button>
        </form>
      </section>
      </div>
    </template>

    <ConfirmDialog
      :open="pendingItem !== null"
      title="删除作品"
      :message="`删除作品「${pendingItem?.title ?? ''}」及其所有仓库链接？`"
      :busy="deleting"
      @confirm="confirmRemove"
      @cancel="pendingItem = null"
    />
  </div>
</template>
