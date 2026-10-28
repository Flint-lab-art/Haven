<script setup lang="ts">
/** 搜索框：提交后切到当前域的 /search?q=。 */
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'

const props = withDefaults(
  defineProps<{
    modelValue?: string
    placeholder?: string
  }>(),
  { modelValue: '', placeholder: '搜索标题、正文或标签' },
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
  <form class="row" role="search" @submit.prevent="submit">
    <input
      v-model="q"
      class="input"
      type="search"
      :placeholder="placeholder"
      aria-label="搜索"
      autocomplete="off"
    />
    <button class="btn" type="submit">搜索</button>
  </form>
</template>
