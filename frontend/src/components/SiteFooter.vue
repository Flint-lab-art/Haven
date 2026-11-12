<script setup lang="ts">
/** 全站备案信息：私有域固定悬挂右下角；公开域以正常页脚展示。 */
withDefaults(defineProps<{ inline?: boolean }>(), { inline: false })
</script>

<template>
  <footer class="site-footer" :class="{ 'site-footer--inline': inline }" aria-label="备案信息">
    <a href="https://beian.miit.gov.cn/" target="_blank" rel="noopener noreferrer">苏ICP备2026082406号</a>
    <a href="https://beian.mps.gov.cn/#/query/webSearch?code=32039102000739" rel="noreferrer" target="_blank">
      <img src="/FilingIcon.png" alt="" class="site-footer__gongan-icon" />
      苏公网安备32039102000739号
    </a>
  </footer>
</template>

<style>
.site-footer__gongan-icon {
  width: 16px;
  height: 16px;
  vertical-align: -3px;   /* 让图标和文字基线对齐，-2~-4px 视字体调 */
  margin-right: 4px;      /* 图标与文字留一点间隙 */
}
</style>