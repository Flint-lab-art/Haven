<script setup lang="ts">
/**
 * 设置 · 外观。
 *
 * 主题切换是纯前端状态（localStorage + <html data-theme>），
 * 不调用任何接口，所以对 API Token 与非 Token 会话都可用。
 */
import { useThemeStore } from '@/stores/theme'

const theme = useThemeStore()
</script>

<template>
  <div class="detail-inner">
    <header class="detail-head">
      <h1 class="detail-title">外观</h1>
      <p class="detail-sub">选择界面配色，立即生效并记住选择</p>
    </header>

    <section class="panel panel--pad">
      <h2 class="row-item__title" style="font: var(--text-title3)">主题</h2>
      <p class="field__hint" style="margin-bottom: 16px">
        前四套为深色主题，适合夜间或长时间写作。切换后整个界面立即变化，刷新后保持。
      </p>

      <div class="theme-grid" role="radiogroup" aria-label="主题">
        <button
          v-for="option in theme.themes"
          :key="option.id"
          class="theme-card"
          :class="{ 'theme-card--active': theme.current === option.id }"
          type="button"
          role="radio"
          :aria-checked="theme.current === option.id"
          :style="{
            '--swatch-bg': option.swatch.bg,
            '--swatch-fg': option.swatch.fg,
            '--swatch-accent': option.swatch.accent,
          }"
          @click="theme.setTheme(option.id)"
        >
          <span class="theme-card__preview" aria-hidden="true">
            <span class="theme-card__bar"></span>
            <span class="theme-card__line theme-card__line--long"></span>
            <span class="theme-card__line"></span>
            <span class="theme-card__line theme-card__line--short"></span>
          </span>
          <span class="theme-card__name">{{ option.name }}</span>
          <span class="theme-card__check" aria-hidden="true">
            {{ theme.current === option.id ? '✓' : '' }}
          </span>
        </button>
      </div>
    </section>
  </div>
</template>
