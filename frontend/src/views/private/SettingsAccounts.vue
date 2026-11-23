<script setup lang="ts">
/**
 * 设置 · 账户（PC）。
 *
 * 与移动端同一套接口，版式按大屏排：表格行 + 行内操作。
 * 余额不存库，由「期初 + 流水累计」实时算出，所以这里只读展示。
 */
import { computed, onMounted, ref } from 'vue'
import { ApiError } from '@/api/client'
import {
  createAccount,
  deleteAccount,
  listAccounts,
  updateAccount,
  type Account,
  type AccountType,
} from '@/api/ledger'
import { accountTypeLabel, formatYuan, parseYuanToCents } from '@/utils/ledger'
import AccountIconPicker from '@/components/ledger/AccountIconPicker.vue'
import AccountAvatar from '@/components/ledger/AccountAvatar.vue'

const accounts = ref<Account[]>([])
const loading = ref(true)
const error = ref('')
const toast = ref('')

/** 表单状态：editingId 为 null 表示新建。 */
const formOpen = ref(false)
const editingId = ref<string | null>(null)
const formName = ref('')
const formType = ref<AccountType>('bank')
const formIcon = ref('')
const formInitial = ref('')
const saving = ref(false)

const activeAccounts = computed(() => accounts.value.filter((a) => !a.archived))

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    accounts.value = await listAccounts()
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '账户加载失败'
  } finally {
    loading.value = false
  }
}

function resetForm(): void {
  formOpen.value = false
  editingId.value = null
  formName.value = ''
  formType.value = 'bank'
  formIcon.value = ''
  formInitial.value = ''
}

/** 打开表单：新建或编辑已有账户。 */
function openForm(account?: Account): void {
  if (account) {
    editingId.value = account.id
    formName.value = account.name
    formType.value = account.type
    formIcon.value = account.icon
    // 期初余额是「分」，编辑时转成元显示；信用卡是负数，取绝对值
    formInitial.value = String(Math.abs(account.initial_balance_cents) / 100)
  } else {
    editingId.value = null
    formName.value = ''
    formType.value = 'bank'
    formIcon.value = ''
    formInitial.value = ''
  }
  formOpen.value = true
}

async function submit(): Promise<void> {
  const name = formName.value.trim()
  if (!name) {
    error.value = '账户名不能为空'
    return
  }
  const initial = formInitial.value.trim()
  const cents = initial ? parseYuanToCents(initial) : 0
  if (cents == null) {
    error.value = '期初余额格式不对'
    return
  }

  saving.value = true
  error.value = ''
  try {
    // credit 类期初余额表示欠款，输入正数时转成负数
    const initialCents = formType.value === 'credit' ? -Math.abs(cents) : cents
    const payload = { name, icon: formIcon.value, type: formType.value, initial_balance_cents: initialCents }

    if (editingId.value) {
      await updateAccount(editingId.value, payload)
      toast.value = '账户已更新'
    } else {
      await createAccount(payload)
      toast.value = '账户已创建'
    }
    resetForm()
    setTimeout(() => (toast.value = ''), 2000)
    await load()
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '保存失败'
  } finally {
    saving.value = false
  }
}

async function toggleArchive(account: Account): Promise<void> {
  try {
    await updateAccount(account.id, {
      name: account.name,
      icon: account.icon,
      type: account.type,
      initial_balance_cents: account.initial_balance_cents,
      archived: !account.archived,
    })
    await load()
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '操作失败'
  }
}

async function remove(account: Account): Promise<void> {
  if (!window.confirm(`删除账户「${account.name}」？`)) return
  try {
    await deleteAccount(account.id)
    await load()
  } catch (err) {
    // 有流水的账户后端返回 409
    error.value = err instanceof ApiError ? err.message : '删除失败'
  }
}

onMounted(load)
</script>

<template>
  <div class="detail-inner">
    <header class="detail-head">
      <h1 class="detail-title">账户</h1>
      <p class="detail-sub">钱分别在哪、还剩多少；余额由期初与流水实时算出</p>
    </header>

    <div class="ledger-toolbar">
      <span class="field__hint">共 {{ accounts.length }} 个账户</span>
      <button v-if="!formOpen" class="btn btn--primary" type="button" @click="openForm()">新建账户</button>
    </div>

    <p v-if="error" class="notice notice--error ledger-notice">{{ error }}</p>
    <p v-if="toast" class="notice notice--success ledger-notice">{{ toast }}</p>

    <!-- 新建表单 -->
    <section v-if="formOpen" class="panel panel--pad ledger-account-form">
      <h2 class="ledger-block__title">{{ editingId ? '编辑账户' : '新建账户' }}</h2>
      <div class="ledger-account-form__fields">
        <label class="field">
          <span class="field__label">名称</span>
          <input v-model="formName" class="input" type="text" maxlength="32" placeholder="如：工资卡" aria-label="账户名" />
        </label>

        <label class="field">
          <span class="field__label">类型</span>
          <select v-model="formType" class="select" aria-label="账户类型">
            <option value="cash">现金</option>
            <option value="bank">储蓄卡</option>
            <option value="credit">信用卡 / 花呗</option>
            <option value="ewallet">微信 / 支付宝</option>
          </select>
        </label>

        <label class="field">
          <span class="field__label">期初余额</span>
          <input
            v-model="formInitial"
            class="input"
            type="text"
            inputmode="decimal"
            placeholder="0.00"
            aria-label="期初余额"
            :disabled="editingId !== null"
          />
        </label>
      </div>

      <AccountIconPicker v-model="formIcon" />

      <p v-if="formType === 'credit'" class="field__hint">信用卡填欠款金额，余额会显示为负数。</p>

      <div class="row">
        <button class="btn btn--primary" type="button" :disabled="saving" @click="submit">
          {{ saving ? '保存中…' : '保存' }}
        </button>
        <button class="btn" type="button" @click="resetForm">取消</button>
      </div>
    </section>

    <div v-if="loading" class="panel panel--pad">
      <div class="skeleton skeleton--title" style="width: 40%"></div>
    </div>

    <div v-else-if="accounts.length === 0" class="panel empty">
      <p class="empty__title">还没有账户</p>
      <p class="empty__text">先建一个账户，才能开始记账。</p>
    </div>

    <ul v-else class="panel rows">
      <li v-for="acc in accounts" :key="acc.id" class="row-item">
        <div class="row-item__main">
          <div class="row-item__title">
            <AccountAvatar :name="acc.name" :icon="acc.icon" />
            {{ acc.name }}
            <span v-if="acc.archived" class="badge badge--private">已归档</span>
          </div>
          <div class="row-item__sub">{{ accountTypeLabel(acc.type) }}</div>
        </div>

        <span
          class="ledger-account__balance"
          :class="{ 'ledger-account__balance--debt': acc.balance_cents < 0 }"
        >
          {{ formatYuan(acc.balance_cents) }}
        </span>

        <div class="row ledger-account-form__actions">
          <button class="btn btn--sm" type="button" @click="openForm(acc)">编辑</button>
          <button class="btn btn--sm" type="button" @click="toggleArchive(acc)">
            {{ acc.archived ? '恢复' : '归档' }}
          </button>
          <button
            v-if="!acc.archived && activeAccounts.length > 1"
            class="btn btn--sm btn--danger"
            type="button"
            @click="remove(acc)"
          >
            删除
          </button>
        </div>
      </li>
    </ul>
  </div>
</template>
