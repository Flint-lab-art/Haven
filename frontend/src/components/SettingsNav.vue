<script setup lang="ts">
/** 设置页左侧导航。 */
import { RouterLink } from 'vue-router'

const items = [
  { name: 'settings', label: '概览' },
  { name: 'settings-security', label: '账号安全' },
  { name: 'settings-sessions', label: '会话' },
  { name: 'settings-devices', label: '授信设备' },
  { name: 'settings-tokens', label: 'API Token' },
] as const
</script>

<template>
  <nav class="settings-nav" aria-label="设置">
    <RouterLink
      v-for="item in items"
      :key="item.name"
      :to="{ name: item.name }"
      :exact-active-class="'router-link-active'"
    >
      {{ item.label }}
    </RouterLink>
  </nav>
</template>
