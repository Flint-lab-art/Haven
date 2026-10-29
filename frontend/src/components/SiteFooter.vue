<script setup lang="ts">
/** 全站备案信息：私有域固定悬挂右下角；公开域以正常页脚展示。 */
withDefaults(defineProps<{ inline?: boolean }>(), { inline: false })
</script>

<template>
  <footer class="site-footer" :class="{ 'site-footer--inline': inline }" aria-label="备案信息">
    <a href="https://beian.miit.gov.cn/" target="_blank" rel="noopener noreferrer">苏ICP备2026082406号</a>
    <span>苏公网安备 待审核</span>
  </footer>
</template>
