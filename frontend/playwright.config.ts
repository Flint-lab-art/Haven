import { defineConfig, devices } from '@playwright/test'

/**
 * 端到端测试。
 *
 * 为什么不只靠单元测试：这轮出现过 4 个「类型检查与单测都绿、功能却不可用」的 bug ——
 * Jackson 命名策略、updateById 跳过 null、组件漏 import、面板挂错 DOM 层级。
 * jsdom 不做布局计算，只能靠真实浏览器发现。
 *
 * 运行前提：
 * - 一个可写的 PostgreSQL（默认 127.0.0.1:5432，账号 dev / 123456，可用 E2E_DB_* 覆盖）
 * - 每次运行都会重建独立数据库 `haven_e2e_db`，不会碰 dev_db
 *
 * 命令：
 *   pnpm e2e           # 无头
 *   pnpm e2e:ui        # 可视化调试
 */
const PORT = Number(process.env.E2E_PORT ?? 18099)

export default defineConfig({
  testDir: './e2e',
  // 用例之间共享一个数据库，串行跑，避免互相干扰
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: 0,
  reporter: process.env.CI ? [['list'], ['html', { open: 'never' }]] : [['list']],
  timeout: 30_000,
  expect: { timeout: 8_000 },

  use: {
    baseURL: `http://localhost:${PORT}`,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  /**
   * 直接跑打包后的后端（自带前端静态资源），而不是 Vite dev server。
   * 这样测的就是真实部署形态：同源、无代理、CSP 与静态托管都一致。
   */
  webServer: {
    command: 'node e2e/start-server.mjs',
    url: `http://localhost:${PORT}/api/health`,
    reuseExistingServer: false,
    timeout: 180_000,
    stdout: 'pipe',
    stderr: 'pipe',
  },
})
