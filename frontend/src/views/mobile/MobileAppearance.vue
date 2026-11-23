<script setup lang="ts">
/**
 * 移动端设置 · 外观。
 *
 * 纯前端状态（localStorage + `<html data-theme>`），不调接口，
 * 所以 API Token 会话也能用。
 *
 * 与 PC 的区别只是版式：两列网格，卡片更矮——手机竖屏放不下 PC 的四列。
 */
import { useThemeStore } from '@/stores/theme'
import { Check } from 'lucide-vue-next'

const theme = useThemeStore()
</script>

<template>
  <div class="m-page">
    <MobilePageHeader title="外观" />

    <p class="m-hint">切换后立即生效，刷新后保持。</p>

    <div class="m-theme-grid" role="radiogroup" aria-label="主题">
      <button
        v-for="option in theme.themes"
        :key="option.id"
        type="button"
        class="m-theme-card"
        :class="{ 'm-theme-card--active': theme.current === option.id }"
        role="radio"
        :aria-checked="theme.current === option.id"
        :style="{
          '--swatch-bg': option.swatch.bg,
          '--swatch-fg': option.swatch.fg,
          '--swatch-accent': option.swatch.accent,
        }"
        @click="theme.setTheme(option.id)"
      >
        <!-- 缩略图：用该主题的色值画一个小界面示意 -->
        <span class="m-theme-card__preview" aria-hidden="true">
          <span class="m-theme-card__bar"></span>
          <span class="m-theme-card__line m-theme-card__line--long"></span>
          <span class="m-theme-card__line"></span>
          <span class="m-theme-card__line m-theme-card__line--short"></span>
        </span>

        <span class="m-theme-card__foot">
          <span class="m-theme-card__name">{{ option.name }}</span>
          <Check v-if="theme.current === option.id" class="m-theme-card__check" aria-hidden="true" />
        </span>
      </button>
    </div>
  </div>
</template>
