import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vitest/config'

export default defineConfig({
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
