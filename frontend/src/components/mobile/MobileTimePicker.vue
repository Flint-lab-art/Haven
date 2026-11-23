<script setup lang="ts">
/**
 * 时间选择弹窗：三列等宽滚轮（日 / 时 / 分）。
 *
 * 只列**当月**的日子：记账补记基本都在本月内，
 * 「月」这一列多数时候只有一个值，纯属占位。
 * 需要补记上个月的，目前直接改流水日期（后续可加）。
 *
 * 约束：只到「今天」为止，记账不记未来。
 */
import { computed, nextTick, ref, watch } from 'vue'

const props = defineProps<{
  /** ISO 时间字符串。 */
  modelValue: string
  open: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
  close: []
}>()

function pad(n: number): string {
  return String(n).padStart(2, '0')
}

interface DayOption {
  /** 用于定位：完整日期键。 */
  key: string
  /** 滚轮里显示的数字（两位）。 */
  day: string
}

/**
 * 可选日期：当月 1 号到今天。
 *
 * 如果当前流水的时间不在本月（编辑上月流水），把它的日子也补进来，
 * 否则打开弹窗会找不到当前值。
 */
const dayOptions = computed<DayOption[]>(() => {
  const today = new Date()
  const current = new Date(props.modelValue)
  const sameMonth =
    !Number.isNaN(current.getTime()) &&
    current.getFullYear() === today.getFullYear() &&
    current.getMonth() === today.getMonth()

  const lastDay = sameMonth ? Math.max(today.getDate(), current.getDate()) : today.getDate()

  const out: DayOption[] = []
  for (let d = 1; d <= lastDay; d++) {
    const date = new Date(today.getFullYear(), today.getMonth(), d)
    out.push({
      key: `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(d)}`,
      day: pad(d),
    })
  }
  return out
})

const HOURS = Array.from({ length: 24 }, (_, i) => pad(i))
const MINUTES = Array.from({ length: 60 }, (_, i) => pad(i))

// 弹窗内是临时值，点「确定」才写回
const pickedDayKey = ref('')
const pickedHour = ref('00')
const pickedMinute = ref('00')

const dayRef = ref<HTMLElement | null>(null)
const hourRef = ref<HTMLElement | null>(null)
const minuteRef = ref<HTMLElement | null>(null)

watch(
  () => props.open,
  async (isOpen) => {
    if (!isOpen) return
    const d = new Date(props.modelValue)
    const base = Number.isNaN(d.getTime()) ? new Date() : d
    pickedDayKey.value = `${base.getFullYear()}-${pad(base.getMonth() + 1)}-${pad(base.getDate())}`
    pickedHour.value = pad(base.getHours())
    pickedMinute.value = pad(base.getMinutes())

    // 等 DOM 渲染完再把四列滚到选中项，而不是停在最顶部
    await nextTick()
    await centerColumn(dayRef.value, '.m-wheel__item--active')
    await centerColumn(hourRef.value, '.m-wheel__item--active')
    await centerColumn(minuteRef.value, '.m-wheel__item--active')
  },
  { immediate: true },
)

/** 把某一列的选中项滚到视野中央。 */
async function centerColumn(el: HTMLElement | null, selector: string): Promise<void> {
  await nextTick()
  el?.querySelector<HTMLElement>(selector)?.scrollIntoView({ block: 'center', inline: 'nearest' })
}

function confirm(): void {
  const [y, m, d] = pickedDayKey.value.split('-').map(Number)
  const result = new Date(y, m - 1, d, Number(pickedHour.value), Number(pickedMinute.value), 0, 0)
  emit('update:modelValue', result.toISOString())
  emit('close')
}
</script>

<template>
  <div v-if="open" class="m-picker-backdrop" @click.self="emit('close')">
    <div class="m-picker" role="dialog" aria-modal="true" aria-label="选择时间">
      <div class="m-picker__grab"></div>

      <div class="m-picker__head">
        <button type="button" class="m-picker__action" @click="emit('close')">取消</button>
        <span class="m-picker__title">选择时间</span>
        <button type="button" class="m-picker__action m-picker__action--primary" @click="confirm">确定</button>
      </div>

      <!-- 三列等宽滚轮：日 / 时 / 分，每列顶部标单位 -->
      <div class="m-picker__wheels">
        <div class="m-wheel-col">
          <span class="m-wheel__unit">日</span>
          <div ref="dayRef" class="m-wheel" role="listbox" aria-label="日">
            <button
              v-for="opt in dayOptions"
              :key="opt.key"
              type="button"
              class="m-wheel__item"
              :class="{ 'm-wheel__item--active': pickedDayKey === opt.key }"
              role="option"
              :aria-selected="pickedDayKey === opt.key"
              @click="pickedDayKey = opt.key"
            >
              {{ opt.day }}
            </button>
          </div>
        </div>

        <div class="m-wheel-col">
          <span class="m-wheel__unit">时</span>
          <div ref="hourRef" class="m-wheel" role="listbox" aria-label="小时">
            <button
              v-for="h in HOURS"
              :key="h"
              type="button"
              class="m-wheel__item"
              :class="{ 'm-wheel__item--active': pickedHour === h }"
              role="option"
              :aria-selected="pickedHour === h"
              @click="pickedHour = h"
            >
              {{ h }}
            </button>
          </div>
        </div>

        <div class="m-wheel-col">
          <span class="m-wheel__unit">分</span>
          <div ref="minuteRef" class="m-wheel" role="listbox" aria-label="分钟">
            <button
              v-for="m in MINUTES"
              :key="m"
              type="button"
              class="m-wheel__item"
              :class="{ 'm-wheel__item--active': pickedMinute === m }"
              role="option"
              :aria-selected="pickedMinute === m"
              @click="pickedMinute = m"
            >
              {{ m }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
