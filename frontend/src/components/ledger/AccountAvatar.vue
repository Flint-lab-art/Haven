<script setup lang="ts">
/**
 * 账户头像：有图标就显示图标，没有就显示名称首字。
 *
 * 首字底色由名称散列决定，保证同一个账户每次颜色一致；
 * 图标保持品牌原色——不做主题染色，深色模式下也是原图。
 */
import { computed } from 'vue'
import { findAccountIcon, iconSrc } from '@/utils/account-icons'

const props = withDefaults(
  defineProps<{
    name: string
    icon?: string
    /** 尺寸：sm 用在列表行，md 用在卡片。 */
    size?: 'sm' | 'md'
  }>(),
  { icon: '', size: 'sm' },
)

const option = computed(() => findAccountIcon(props.icon))

const initial = computed(() => (props.name || '?').trim().slice(0, 1).toUpperCase())

/** 名称散列出色相，保证同一个账户颜色稳定。 */
const hue = computed(() => {
  let hash = 0
  for (const ch of props.name) {
    hash = (hash * 31 + ch.codePointAt(0)!) % 360
  }
  return hash
})
</script>

<template>
  <span
    class="acc-avatar"
    :class="[`acc-avatar--${size}`, { 'acc-avatar--icon': option }]"
    :style="
      option
        ? undefined
        : { background: `hsl(${hue} 52% 92%)`, color: `hsl(${hue} 55% 34%)` }
    "
    aria-hidden="true"
  >
    <img
      v-if="option"
      :src="iconSrc(option.key)"
      alt=""
      loading="lazy"
      :style="{ transform: `scale(${option.scale ?? 1})` }"
    />
    <template v-else>{{ initial }}</template>
  </span>
</template>
