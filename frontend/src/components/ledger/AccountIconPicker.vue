<script setup lang="ts">
/**
 * 账户图标选择器。
 *
 * 图标全部来自 `public/icons/`，用 `<img>` 渲染：
 * 彩色 SVG 原样显示，不做任何染色——银行与支付 logo 的配色是品牌资产。
 */
import { ACCOUNT_ICONS, iconSrc } from '@/utils/account-icons'

const props = withDefaults(
  defineProps<{
    modelValue: string
    /** 紧凑模式：移动端用，图标小一号。 */
    compact?: boolean
  }>(),
  { compact: false },
)

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

function pick(key: string): void {
  // 再点一次已选中的图标 = 取消选择
  emit('update:modelValue', props.modelValue === key ? '' : key)
}
</script>

<template>
  <div
    class="acc-icon-picker"
    :class="{ 'acc-icon-picker--compact': compact }"
    role="radiogroup"
    aria-label="账户图标"
  >
    <p class="acc-icon-picker__hint">可选，不选就只显示文字</p>
    <div class="acc-icon-picker__grid">
      <button
        v-for="opt in ACCOUNT_ICONS"
        :key="opt.key"
        type="button"
        class="acc-icon-picker__item"
        :class="{ 'acc-icon-picker__item--active': modelValue === opt.key }"
        role="radio"
        :aria-checked="modelValue === opt.key"
        :title="opt.label"
        :aria-label="opt.label"
        @click="pick(opt.key)"
      >
        <span class="acc-icon-picker__media">
          <img
            :src="iconSrc(opt.key)"
            :alt="opt.label"
            loading="lazy"
            :style="{ transform: `scale(${opt.scale ?? 1})` }"
          />
        </span>
        <span class="acc-icon-picker__label">{{ opt.label }}</span>
      </button>
    </div>
  </div>
</template>
