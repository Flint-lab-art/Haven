<script setup lang="ts">
/**
 * 移动端账户页（独立底部 tab）。
 *
 * 版式分三层：
 * 1. 顶部「总资产」——一张渐变卡，把所有未归档账户的余额合起来；
 * 2. 账户列表——每个账户一张卡片，图标 + 名称 + 余额；
 * 3. 底部抽屉——新建 / 编辑，含实时预览。
 *
 * 为什么合总资产：单看四张卡看不出「我有多少钱」，
 * 而这是打开账户页最想知道的第一个数。
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
import AccountAvatar from '@/components/ledger/AccountAvatar.vue'
import AccountIconPicker from '@/components/ledger/AccountIconPicker.vue'
import MobilePageHeader from '@/components/mobile/MobilePageHeader.vue'

const accounts = ref<Account[]>([])
const loading = ref(true)
const error = ref('')

/** 未归档账户：参与总资产计算。 */
const activeAccounts = computed(() => accounts.value.filter((a) => !a.archived))

/**
 * 总资产 = 未归档账户余额之和。
 *
 * 信用卡余额本身是负数（欠款），所以直接相加就是「净资产」：
 * 现金 + 卡里的钱 − 欠款。这正是用户关心的数。
 */
const totalBalance = computed(() =>
  activeAccounts.value.reduce((sum, a) => sum + a.balance_cents, 0),
)

/** 总负债 = 负余额账户的绝对值之和，单独给出便于判断。 */
const totalDebt = computed(() =>
  activeAccounts.value.filter((a) => a.balance_cents < 0).reduce((sum, a) => sum + -a.balance_cents, 0),
)

// ── 底部抽屉表单 ──

const sheetOpen = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')

const formName = ref('')
const formIcon = ref('')
const formType = ref<AccountType>('bank')
const formInitial = ref('')

/** 实时预览用：名称没填时显示占位。 */
const previewName = computed(() => formName.value.trim() || '新账户')

function openSheet(account?: Account): void {
  if (account) {
    editingId.value = account.id
    formName.value = account.name
    formIcon.value = account.icon
    formType.value = account.type
    formInitial.value = String(Math.abs(account.initial_balance_cents) / 100)
  } else {
    editingId.value = null
    formName.value = ''
    formIcon.value = ''
    formType.value = 'bank'
    formInitial.value = ''
  }
  formError.value = ''
  sheetOpen.value = true
}

function closeSheet(): void {
  sheetOpen.value = false
  editingId.value = null
}

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

async function submit(): Promise<void> {
  const name = formName.value.trim()
  if (!name) {
    formError.value = '账户名不能为空'
    return
  }
  const raw = formInitial.value.trim()
  const cents = raw ? parseYuanToCents(raw) : 0
  if (cents == null) {
    formError.value = '期初余额格式不对'
    return
  }

  saving.value = true
  formError.value = ''
  try {
    // credit 类期初余额表示欠款，输入正数时转成负数
    const initialCents = formType.value === 'credit' ? -Math.abs(cents) : cents
    const payload = { name, icon: formIcon.value, type: formType.value, initial_balance_cents: initialCents }
    if (editingId.value) {
      await updateAccount(editingId.value, payload)
    } else {
      await createAccount(payload)
    }
    closeSheet()
    await load()
  } catch (err) {
    formError.value = err instanceof ApiError ? err.message : '保存失败'
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
    closeSheet()
    await load()
  } catch (err) {
    formError.value = err instanceof ApiError ? err.message : '操作失败'
  }
}

async function remove(account: Account): Promise<void> {
  if (!window.confirm(`删除账户「${account.name}」？`)) return
  try {
    await deleteAccount(account.id)
    closeSheet()
    await load()
  } catch (err) {
    // 有流水的账户后端返回 409
    formError.value = err instanceof ApiError ? err.message : '删除失败'
  }
}

onMounted(load)
</script>

<template>
  <div class="m-page">
    <MobilePageHeader title="账户">
      <template #trail>
        <button class="m-text-btn" type="button" @click="openSheet()">新建</button>
      </template>
    </MobilePageHeader>

    <p v-if="error" class="m-notice m-notice--error">{{ error }}</p>

    <!-- 总资产：整页的视觉锚点 -->
    <section class="m-total" aria-label="总资产">
      <span class="m-total__label">总资产</span>
      <span class="m-total__value" :class="{ 'm-total__value--negative': totalBalance < 0 }">
        {{ totalBalance < 0 ? '−' : '' }}{{ formatYuan(Math.abs(totalBalance)) }}
      </span>
      <p class="m-total__meta">
        {{ activeAccounts.length }} 个账户
        <template v-if="totalDebt > 0">
          <span class="m-total__dot">·</span>
          欠款 {{ formatYuan(totalDebt) }}
        </template>
      </p>
    </section>

    <div v-if="loading" class="m-skeleton">
      <div class="skeleton skeleton--title" style="width: 60%"></div>
    </div>

    <p v-else-if="accounts.length === 0" class="m-hint">还没有账户，点右上角「新建」开始。</p>

    <!-- 账户卡片：点一张进入编辑抽屉 -->
    <ul v-else class="m-acc-cards">
      <li v-for="acc in accounts" :key="acc.id">
        <button type="button" class="m-acc-card" :class="{ 'm-acc-card--archived': acc.archived }" @click="openSheet(acc)">
          <AccountAvatar :name="acc.name" :icon="acc.icon" size="md" />
          <span class="m-acc-card__body">
            <span class="m-acc-card__name">
              {{ acc.name }}
              <span v-if="acc.archived" class="m-badge">已归档</span>
            </span>
            <span class="m-acc-card__type">{{ accountTypeLabel(acc.type) }}</span>
          </span>
          <span
            class="m-acc-card__balance"
            :class="{ 'm-acc-card__balance--debt': acc.balance_cents < 0 }"
          >
            {{ formatYuan(acc.balance_cents) }}
          </span>
        </button>
      </li>
    </ul>

    <!-- 底部抽屉：新建 / 编辑 -->
    <Teleport to="body">
      <div v-if="sheetOpen" class="m-sheet-backdrop" @click.self="closeSheet">
        <div class="m-sheet" role="dialog" aria-modal="true" :aria-label="editingId ? '编辑账户' : '新建账户'">
          <div class="m-sheet__grab"></div>

          <!-- 实时预览：改名字/图标立刻看到效果 -->
          <div class="m-acc-preview">
            <AccountAvatar :name="previewName" :icon="formIcon" size="md" />
            <div class="m-acc-preview__info">
              <span class="m-acc-preview__name">{{ previewName }}</span>
              <span class="m-acc-preview__type">{{ accountTypeLabel(formType) }}</span>
            </div>
          </div>

          <div class="m-field">
            <label class="m-label">名称</label>
            <input v-model="formName" class="m-input" type="text" maxlength="32" placeholder="如：招商银行" aria-label="账户名" />
          </div>

          <div class="m-field">
            <label class="m-label">图标</label>
            <AccountIconPicker v-model="formIcon" compact />
          </div>

          <div class="m-field">
            <label class="m-label">类型</label>
            <div class="m-segmented">
              <button
                v-for="t in (['cash', 'bank', 'credit', 'ewallet'] as AccountType[])"
                :key="t"
                type="button"
                class="m-segmented__btn"
                :class="{ 'is-active': formType === t }"
                @click="formType = t"
              >
                {{ accountTypeLabel(t) }}
              </button>
            </div>
          </div>

          <div class="m-field">
            <label class="m-label">期初余额</label>
            <input
              v-model="formInitial"
              class="m-input"
              type="text"
              inputmode="decimal"
              placeholder="0.00"
              :aria-label="'期初余额'"
              :disabled="editingId !== null"
            />
            <p v-if="formType === 'credit'" class="m-hint">信用卡填欠款金额，余额显示为负数。</p>
            <p v-else-if="editingId" class="m-hint">期初余额建好后不可改，避免和已有流水对不上。</p>
          </div>

          <p v-if="formError" class="m-notice m-notice--error">{{ formError }}</p>

          <button class="m-primary-btn" type="button" :disabled="saving" @click="submit">
            {{ saving ? '保存中…' : editingId ? '更新' : '保存' }}
          </button>

          <!-- 编辑时才有归档与删除 -->
          <div v-if="editingId" class="m-acc-sheet-actions">
            <button class="m-text-btn" type="button" @click="toggleArchive(accounts.find((a) => a.id === editingId)!)">
              {{ accounts.find((a) => a.id === editingId)?.archived ? '恢复' : '归档' }}
            </button>
            <button class="m-text-btn m-text-btn--danger" type="button" @click="remove(accounts.find((a) => a.id === editingId)!)">
              删除
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
