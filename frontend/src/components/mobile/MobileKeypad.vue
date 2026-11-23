<script setup lang="ts">
/**
 * 记账用的数字键盘。
 *
 * 为什么不用系统键盘：`inputmode="decimal"` 在 iOS 上仍会推出整块键盘，
 * 把上面的分类、金额顶出屏幕；而且系统键盘没有「保存」键，
 * 用户填完还要去够屏幕上方的按钮。自定义键盘把「填完就点保存」捏在一只手上。
 *
 * 布局参考 iOS 收银类 App：左 3×4 数字区，右侧一列竖向功能键。
 */
import { X } from 'lucide-vue-next'

const props = defineProps<{
  /** 当前金额文本，如 `12.5`。 */
  modelValue: string
  /** 保存中禁用。 */
  busy?: boolean
  /** 保存按钮文案。 */
  saveLabel?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
  save: []
}>()

/** 只保留数字与一个小数点，最多两位小数、整数最多 9 位。 */
function update(next: string): void {
  let cleaned = next.replace(/[^\d.]/g, '')

  // 只允许一个小数点
  const firstDot = cleaned.indexOf('.')
  if (firstDot !== -1) {
    cleaned = cleaned.slice(0, firstDot + 1) + cleaned.slice(firstDot + 1).replace(/\./g, '')
  }

  const [intPart = '', decPart] = cleaned.split('.')
  // 整数去掉前导 0（但保留单个 0）
  const int = intPart.replace(/^0+(?=\d)/, '').slice(0, 9)
  const rebuilt = decPart === undefined ? int : `${int}.${decPart.slice(0, 2)}`

  emit('update:modelValue', rebuilt)
}

function digit(d: string): void {
  update(props.modelValue + d)
}

function dot(): void {
  if (props.modelValue.includes('.')) return
  update(props.modelValue === '' ? '0.' : `${props.modelValue}.`)
}

function backspace(): void {
  emit('update:modelValue', props.modelValue.slice(0, -1))
}

/** 清空：长按退格也可达到同样效果，但点一下更快。 */
function clear(): void {
  emit('update:modelValue', '')
}
</script>

<template>
  <div class="m-keypad" role="group" aria-label="数字键盘">
    <div class="m-keypad__digits">
      <!-- 第一行右侧是退格：拇指最常点的两个位置（9、⌫）挨在一起 -->
      <button type="button" class="m-key" @click="digit('1')">1</button>
      <button type="button" class="m-key" @click="digit('2')">2</button>
      <button type="button" class="m-key" @click="digit('3')">3</button>
      <button
        type="button"
        class="m-key m-key--muted m-key--back"
        aria-label="退格"
        @click="backspace"
        @dblclick="clear"
      >
        <X aria-hidden="true" />
      </button>

      <button type="button" class="m-key" @click="digit('4')">4</button>
      <button type="button" class="m-key" @click="digit('5')">5</button>
      <button type="button" class="m-key" @click="digit('6')">6</button>

      <button type="button" class="m-key" @click="digit('7')">7</button>
      <button type="button" class="m-key" @click="digit('8')">8</button>
      <button type="button" class="m-key" @click="digit('9')">9</button>

      <button type="button" class="m-key m-key--muted" @click="dot">.</button>
      <button type="button" class="m-key" @click="digit('0')">0</button>
    </div>

    <button type="button" class="m-keypad__save" :disabled="busy" @click="emit('save')">
      <span v-if="busy">保存中</span>
      <span v-else>{{ saveLabel ?? '保存' }}</span>
    </button>
  </div>
</template>
