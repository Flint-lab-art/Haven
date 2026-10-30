<script setup lang="ts">
/** 公开域空状态：极淡的线条插画 + 文案，避免只有一行干巴巴的字。 */
defineProps<{
  title: string
  text?: string
}>()
</script>

<template>
  <div class="public-empty">
    <svg class="public-empty__art" viewBox="0 0 88 72" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M14 28h60v30a5 5 0 0 1-5 5H19a5 5 0 0 1-5-5z" />
      <path d="M14 28 22 12h44l8 16" />
      <path d="M35 28l3 8h12l3-8" />
      <path d="M59 16v6M56 19h6" />
      <path d="M26 50h9M26 56h14" />
    </svg>

    <p class="public-empty__title">{{ title }}</p>
    <p v-if="text" class="public-empty__text">{{ text }}</p>
    <slot />
  </div>
</template>
