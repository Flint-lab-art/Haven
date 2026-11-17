<script setup lang="ts">
/** 斜杠命令候选列表（docs-ai/v7/frontend/ui-design.md 7.5.3）。 */
import { ref, watch } from 'vue'
import type { SlashItem } from '@/utils/slash-command'

const props = defineProps<{
  items: SlashItem[]
  command: (item: SlashItem) => void
  query: string
}>()

const active = ref(0)

watch(
  () => props.items,
  () => {
    active.value = 0
  },
)

function onKeyDown(event: KeyboardEvent): boolean {
  if (props.items.length === 0) return false

  if (event.key === 'ArrowUp') {
    active.value = (active.value + props.items.length - 1) % props.items.length
    return true
  }
  if (event.key === 'ArrowDown') {
    active.value = (active.value + 1) % props.items.length
    return true
  }
  if (event.key === 'Enter') {
    props.command(props.items[active.value])
    return true
  }
  return false
}

defineExpose({ onKeyDown })
</script>

<template>
  <div class="slash-menu" role="listbox" aria-label="插入内容">
    <div v-if="items.length === 0" class="slash-menu__empty">没有匹配的块</div>
    <button
      v-for="(item, index) in items"
      :key="item.title"
      type="button"
      class="slash-menu__item"
      :class="{ 'is-active': index === active }"
      role="option"
      :aria-selected="index === active"
      @mousedown.prevent
      @click="command(item)"
    >
      <span class="slash-menu__title">{{ item.title }}</span>
      <span class="slash-menu__hint">{{ item.hint }}</span>
    </button>
  </div>
</template>
