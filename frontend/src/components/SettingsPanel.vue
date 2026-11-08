<script setup lang="ts">
/** 中间栏设置导航。 */
import { RouterLink, useRoute } from 'vue-router'

const route = useRoute()

const items = [
  { name: 'settings', label: '概览' },
  { name: 'settings-appearance', label: '外观' },
  { name: 'settings-security', label: '账号安全' },
  { name: 'settings-sessions', label: '会话' },
  { name: 'settings-devices', label: '授信设备' },
  { name: 'settings-tokens', label: 'API Token' },
] as const
</script>

<template>
  <div class="list-panel">
    <header class="panel-head">
      <h1 class="panel-title">设置</h1>
    </header>

    <div class="list-rows">
      <RouterLink
        v-for="item in items"
        :key="item.name"
        :to="{ name: item.name }"
        class="list-row"
        :class="{ 'list-row--active': route.name === item.name }"
      >
        {{ item.label }}
      </RouterLink>
    </div>
  </div>
</template>
