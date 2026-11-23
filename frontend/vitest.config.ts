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
    /*
     * 路由用例会 vi.resetModules() 后重新 import 整张路由表，
     * 冷启动时连同 vue-router / pinia / 懒加载组件的转换一起算，很容易超过 5 秒默认值，
     * 表现为「路由用例偶尔超时」而不是断言失败。放宽到 20 秒，别把机器慢当成逻辑坏。
     */
    testTimeout: 20_000,
  },
})
