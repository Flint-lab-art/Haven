<script setup lang="ts">
/** 搜索框：占满内容宽度，左侧放大镜，回车触发（不再需要独立按钮）。 */
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { Search } from 'lucide-vue-next'


const props = withDefaults(
  defineProps<{
    modelValue?: string
    placeholder?: string
    /** 搜索页用大号输入框。 */
    large?: boolean
  }>(),
  { modelValue: '', placeholder: '搜索标题、正文或标签', large: false },
)

const emit = defineEmits<{ 'update:modelValue': [value: string] }>()

const router = useRouter()
const q = ref(props.modelValue)

watch(
  () => props.modelValue,
  (value) => {
    q.value = value
  },
)

function submit(): void {
  emit('update:modelValue', q.value)
  const query = q.value.trim()
  router.push({ path: '/search', query: query ? { q: query } : {} })
}
</script>

<template>
  <form class="search-bar" role="search" @submit.prevent="submit">
    <div class="search-field">
      <Search class="search-field__icon" aria-hidden="true" />
      <input
        v-model="q"
        class="input search-input"
        :class="{ 'search-input--hero': large }"
        type="search"
        :placeholder="placeholder"
        aria-label="搜索"
        autocomplete="off"
        spellcheck="false"
      />
    </div>
  </form>
</template>
