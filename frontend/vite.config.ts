import { fileURLToPath, URL } from 'node:url'

import vue from '@vitejs/plugin-vue'
import { defineConfig } from 'vite'

// 开发服务器由 Caddy 反代到域名时置 HAVEN_DEV_PROXY=1：
// 放宽 Vite 的 Host 检查，并把热更新的 websocket 指到 443（HTTPS 反代）。
// 普通本地开发不设这个变量，行为不变。
const behindProxy = process.env.HAVEN_DEV_PROXY === '1'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    // 固定端口：被占用时直接报错，避免悄悄落到 5174 导致 Caddy 指错端口
    port: 5173,
    strictPort: true,
    // 由 Caddy 反代到域名时 Host 是 note.vorin.icu / www.vorin.icu，开发期全部放行
    allowedHosts: true,
    hmr: behindProxy ? { clientPort: 443 } : undefined,
    // 本地开发时 /api 转发到后端，避免跨域（生产由后端同源托管静态文件）
    proxy: {
      '/api': {
        target: process.env.HAVEN_API_TARGET ?? 'http://127.0.0.1:8080',
        changeOrigin: false,
      },
    },
  },
  build: {
    // 编辑器只在编辑页用到，已经通过路由懒加载单独成块
    chunkSizeWarningLimit: 600,
  },
})
