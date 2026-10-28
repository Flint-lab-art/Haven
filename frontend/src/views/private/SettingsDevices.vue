<script setup lang="ts">
/** 授信设备管理（docs/frontend/frontend.md 第四节 /settings/devices）。 */
import { onMounted, ref } from 'vue'
import PrivateHeader from '@/components/PrivateHeader.vue'
import SettingsNav from '@/components/SettingsNav.vue'
import { ApiError } from '@/api/client'
import { listDevices, revokeDevice, type TrustedDeviceItem } from '@/api/devices'
import { formatDateTime, formatRelative } from '@/utils/format'

const devices = ref<TrustedDeviceItem[]>([])
const loading = ref(true)
const error = ref('')

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    devices.value = (await listDevices()).items
  } catch (err) {
    error.value = err instanceof ApiError && err.isForbidden
      ? 'API Token 无法查看授信设备，请用浏览器登录后查看'
      : '授信设备加载失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

async function revoke(item: TrustedDeviceItem): Promise<void> {
  if (!window.confirm(`撤销设备「${item.device_name || '未命名设备'}」？该设备下次登录需要动态码。`)) {
    return
  }

  error.value = ''
  try {
    await revokeDevice(item.id)
    await load()
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : '操作失败'
  }
}

onMounted(load)
</script>

<template>
  <PrivateHeader />

  <main class="page page--wide">
    <h1 class="page-title" style="margin-bottom: 24px">授信设备</h1>

    <div class="settings-layout">
      <SettingsNav />

      <div class="stack">
        <p class="field__hint">
          授信设备在 30 天内登录时免输动态码。它们只能在登录时勾选“信任这台设备”创建，
          不能在这里手动添加。
        </p>

        <p v-if="error" class="notice notice--error">{{ error }}</p>

        <div v-if="loading" class="panel panel--padded">
          <div class="skeleton" style="width: 50%"></div>
        </div>

        <div v-else-if="devices.length === 0" class="panel empty">
          <p class="empty__title">没有授信设备</p>
          <p>下次登录时勾选“信任这台设备”即可添加。</p>
        </div>

        <ul v-else class="panel list">
          <li v-for="item in devices" :key="item.id" class="list__row">
            <div class="list__row-main">
              <div class="card__title">{{ item.device_name || '未命名设备' }}</div>
              <div class="card__meta">
                <span>添加于 {{ formatDateTime(item.created_at) }}</span>
                <span>· 最近使用 {{ formatRelative(item.last_used_at) }}</span>
                <span>· 到期 {{ formatDateTime(item.expires_at) }}</span>
              </div>
            </div>
            <button class="btn btn--small btn--danger" type="button" @click="revoke(item)">
              撤销
            </button>
          </li>
        </ul>
      </div>
    </div>
  </main>
</template>
