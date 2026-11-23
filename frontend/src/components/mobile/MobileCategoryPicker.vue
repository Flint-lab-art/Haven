<script setup lang="ts">
/**
 * 移动端分类选择：下钻式。
 *
 * 一级一排网格，点一个就整块换成它的二级，左上角可返回。
 * 不在一屏里同时铺两级：视线不用在上下两块之间来回跳，
 * 也让「选大类还是选细项」变成两个明确的步骤。
 *
 * **单一一级直接展开**：收入只有「收入」一个一级，再多一次点击毫无意义，
 * 所以只有一个一级时跳过上级、直接展示它的二级。
 */
import { computed, ref, watch } from 'vue'
import type { Category } from '@/api/ledger'
import { ChevronLeft } from 'lucide-vue-next'


const props = defineProps<{
  categories: Category[]
  kind: 'expense' | 'income'
  modelValue: number | null
}>()

const emit = defineEmits<{
  'update:modelValue': [value: number | null]
}>()

const roots = computed(() => props.categories.filter((c) => c.kind === props.kind))

/** 当前下钻到哪一级；null 表示在上级列表。 */
const drilledId = ref<number | null>(null)

/**
 * 实际要展示的二级所属一级。
 *
 * - 用户主动下钻过 → 用它选的；
 * - 只有一个一级（收入）→ 直接展开它，省掉一次点击；
 * - 否则 null，停在上级网格。
 */
const drilled = computed(() => {
  if (drilledId.value != null) {
    return roots.value.find((r) => r.id === drilledId.value) ?? null
  }
  if (roots.value.length === 1) return roots.value[0]
  return null
})

/** 是否可以返回上级：只有一个一级时没有上级可回。 */
const canGoBack = computed(() => roots.value.length > 1)

/** 选中项归属的一级，用于回到上级时高亮。 */
const activeRootId = computed(() => {
  if (props.modelValue == null) return null
  const root = roots.value.find(
    (r) => r.id === props.modelValue || r.children.some((c) => c.id === props.modelValue),
  )
  return root?.id ?? null
})

// 编辑已有流水时，直接下钻到它所属的一级
watch(
  () => [props.modelValue, roots.value] as const,
  () => {
    if (props.modelValue == null || drilledId.value != null) return
    const parent = roots.value.find((r) => r.children.some((c) => c.id === props.modelValue))
    if (parent) drilledId.value = parent.id
  },
  { immediate: true },
)

function pickRoot(root: Category): void {
  drilledId.value = root.id
  // 选一级本身是合法的（只知道大类）：先记成一级，
  // 用户再点二级就会覆盖；不点就是「其他 xx」的语义
  emit('update:modelValue', root.id)
}

function pickChild(child: Category): void {
  emit('update:modelValue', child.id)
}

function back(): void {
  if (!canGoBack.value) return
  drilledId.value = null
}
</script>

<template>
  <div class="m-cats">
    <!-- 上级：一级网格 -->
    <template v-if="!drilled">
      <div class="m-cats__grid" role="radiogroup" aria-label="一级分类">
        <button
          v-for="root in roots"
          :key="root.id"
          type="button"
          class="m-cat"
          :class="{ 'm-cat--active': modelValue === root.id || activeRootId === root.id }"
          role="radio"
          :aria-checked="modelValue === root.id"
          @click="pickRoot(root)"
        >
          <span class="m-cat__icon" aria-hidden="true">{{ root.icon }}</span>
          <span class="m-cat__name">{{ root.name }}</span>
        </button>
      </div>
    </template>

    <!-- 下级：某个一级的二级 -->
    <template v-else>
      <button v-if="canGoBack" type="button" class="m-cats__back" @click="back">
        <ChevronLeft aria-hidden="true" />
        <span class="m-cats__back-icon" aria-hidden="true">{{ drilled.icon }}</span>
        <span>{{ drilled.name }}</span>
      </button>

      <div class="m-cats__grid" role="radiogroup" :aria-label="`${drilled.name}的细分`">
        <!--
          「综合」= 只记大类，对应一级本身。
          收入只有一个一级时没有「大类」概念，多这一格反而让人犹豫，故隐藏。
        -->
        <button
          v-if="canGoBack"
          type="button"
          class="m-cat"
          :class="{ 'm-cat--active': modelValue === drilled.id }"
          role="radio"
          :aria-checked="modelValue === drilled.id"
          @click="pickChild(drilled)"
        >
          <span class="m-cat__icon" aria-hidden="true">{{ drilled.icon }}</span>
          <span class="m-cat__name">综合</span>
        </button>
        <button
          v-for="child in drilled.children"
          :key="child.id"
          type="button"
          class="m-cat"
          :class="{ 'm-cat--active': modelValue === child.id }"
          role="radio"
          :aria-checked="modelValue === child.id"
          @click="pickChild(child)"
        >
          <span class="m-cat__icon" aria-hidden="true">{{ child.icon }}</span>
          <span class="m-cat__name">{{ child.name }}</span>
        </button>
      </div>
    </template>
  </div>
</template>
