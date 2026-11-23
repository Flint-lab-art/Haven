<script setup lang="ts">
/**
 * 两级分类选择：一级一行，二级折叠成胶囊。
 *
 * PC 与移动端共用。交互约定：
 * - 点一级：选中该一级（category_id 记一级），并展开它的二级；
 * - 点二级：选中该二级；
 * - 再点已展开的一级：收起。
 *
 * 为什么要允许选一级：记账时常常只知道大类（「这是餐饮，具体没细看」），
 * 强制选二级会让用户随便点一个凑数，统计反而更脏。
 */
import { computed, ref, watch } from 'vue'
import type { Category } from '@/api/ledger'
import { ChevronDown } from 'lucide-vue-next'


const props = defineProps<{
  /** 分类树（`GET /api/ledger/categories`）。 */
  categories: Category[]
  /** 只显示该方向的分类。 */
  kind: 'expense' | 'income'
  /** 当前选中的分类 id（一级或二级）。 */
  modelValue: number | null
}>()

const emit = defineEmits<{
  'update:modelValue': [value: number | null]
}>()

const roots = computed(() => props.categories.filter((c) => c.kind === props.kind))

/** 当前展开的一级 id；默认展开选中项所属的一级。 */
const expandedId = ref<number | null>(null)

watch(
  () => [props.modelValue, roots.value] as const,
  () => {
    if (props.modelValue == null) return
    const parent = roots.value.find(
      (r) => r.id === props.modelValue || r.children.some((c) => c.id === props.modelValue),
    )
    if (parent && expandedId.value == null) expandedId.value = parent.id
  },
  { immediate: true },
)

/** 选中项所属的一级，用于高亮。 */
const activeRootId = computed(() => {
  if (props.modelValue == null) return null
  const root = roots.value.find(
    (r) => r.id === props.modelValue || r.children.some((c) => c.id === props.modelValue),
  )
  return root?.id ?? null
})

function toggle(root: Category): void {
  const willExpand = expandedId.value !== root.id
  expandedId.value = willExpand ? root.id : null
  // 点一级本身就选中它：表示「只知道大类」
  emit('update:modelValue', root.id)
}

function pick(child: Category): void {
  emit('update:modelValue', child.id)
}
</script>

<template>
  <div class="cat-picker" role="radiogroup" aria-label="分类">
    <div v-for="root in roots" :key="root.id" class="cat-picker__group">
      <div class="cat-picker__head">
        <button
          type="button"
          class="cat-picker__root"
          :class="{
            'cat-picker__root--active': modelValue === root.id,
            'cat-picker__root--parent': activeRootId === root.id && modelValue !== root.id,
          }"
          role="radio"
          :aria-checked="modelValue === root.id"
          :aria-expanded="expandedId === root.id"
          @click="toggle(root)"
        >
          <span class="cat-icon" aria-hidden="true">{{ root.icon }}</span>
          <span class="cat-picker__name">{{ root.name }}</span>
          <ChevronDown
            v-if="root.children.length > 0"
            class="cat-picker__chevron"
            :class="{ 'cat-picker__chevron--open': expandedId === root.id }"
            aria-hidden="true"
          />
        </button>
      </div>

      <div v-if="expandedId === root.id && root.children.length > 0" class="cat-picker__children">
        <button
          v-for="child in root.children"
          :key="child.id"
          type="button"
          class="cat-pill"
          :class="{ 'cat-pill--active': modelValue === child.id }"
          role="radio"
          :aria-checked="modelValue === child.id"
          @click="pick(child)"
        >
          <span class="cat-icon" aria-hidden="true">{{ child.icon }}</span>
          <span>{{ child.name }}</span>
        </button>
      </div>
    </div>
  </div>
</template>
