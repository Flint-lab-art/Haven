<script setup lang="ts">
/** 授信设备管理。 */
import { onMounted, ref } from 'vue'
import { ApiError } from '@/api/client'
import { listDevices, revokeDevice, type TrustedDeviceItem } from '@/api/devices'
import { formatDate, formatRelative } from '@/utils/format'

const devices = ref<TrustedDeviceItem[]>([])
const loading = ref(true)
const error = ref('')

async function load(): Promise<void> {
  loading.value = true
  error.value = ''
  try {
    devices.value = (await listDevices()).items
  } catch (err) {
    error.value =
      err instanceof ApiError && err.isForbidden
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
  <div class="detail-inner">
    <header class="detail-head">
      <h1 class="detail-title">授信设备</h1>
      <p class="detail-sub">30 天内登录免动态码；只能在登录时勾选“信任这台设备”创建</p>
    </header>

    <div class="stack">
          <p v-if="error" class="notice notice--error">{{ error }}</p>

          <div v-if="loading" class="panel panel--pad">
            <div class="skeleton skeleton--title" style="width: 46%"></div>
          </div>

          <div v-else-if="devices.length === 0" class="panel empty">
            <p class="empty__title">没有授信设备</p>
            <p class="empty__text">下次登录时勾选“信任这台设备”，30 天内就不用再输动态码。</p>
          </div>

          <ul v-else class="panel rows">
            <li v-for="item in devices" :key="item.id" class="row-item">
              <div class="row-item__main">
                <div class="row-item__title">{{ item.device_name || '未命名设备' }}</div>
                <div class="row-item__sub">
                  最近使用 {{ formatRelative(item.last_used_at) }} · {{ formatDate(item.expires_at) }}到期
                </div>
              </div>
              <button class="btn btn--sm btn--danger" type="button" @click="revoke(item)">撤销</button>
            </li>
          </ul>

          <p class="field__hint">
            网吧、酒店等公共电脑上不建议勾选“信任这台设备”；误勾选时可在这里撤销。
          </p>
    </div>
  </div>
</template>
