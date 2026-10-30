<script setup lang="ts">
/**
 * 编辑页右侧大纲（ui-design.md 7.6）。
 *
 * 只在有 H1–H3 时显示；点击跳转到对应标题，滚动时高亮当前章节。
 * 由父组件负责解析标题和滚动定位，这里只负责展示。
 */
defineProps<{
  items: { level: number; text: string }[]
  activeIndex: number
}>()

defineEmits<{
  select: [index: number]
}>()
</script>

<template>
  <nav class="note-outline" aria-label="大纲">
    <p class="note-outline__title">大纲</p>
    <ul class="note-outline__list">
      <li v-for="(item, index) in items" :key="`${index}-${item.text}`">
        <button
          class="note-outline__item"
          :class="[
            `note-outline__item--h${item.level}`,
            { 'note-outline__item--active': index === activeIndex },
          ]"
          type="button"
          :title="item.text"
          @click="$emit('select', index)"
        >
          {{ item.text }}
        </button>
      </li>
    </ul>
  </nav>
</template>
