import { fileURLToPath, URL } from 'node:url'
import vue from '@vitejs/plugin-vue'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  // 路由表用 () => import('.vue') 懒加载，测试里加载路由也需要 vue 插件
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  test: {
    // DOMPurify 需要 DOM（浏览器与 jsdom 都行），因此用 jsdom
    environment: 'jsdom',
    include: ['src/**/*.test.ts'],
  },
})
