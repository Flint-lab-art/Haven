#!/usr/bin/env node
/**
 * E2E 启动脚本：准备一个隔离的表空间，然后起一个完整的后端实例。
 *
 * 隔离原则：**绝不使用开发库里的业务表**。
 * 用 PostgreSQL schema 隔离而不是独立数据库，原因：
 * 开发账号（dev）通常没有 CREATE DATABASE 权限，但在自己库里有 CREATE SCHEMA 权限。
 * schema 与数据库在「表、索引、外键」层面完全隔离，效果一样，且不需要管理员介入。
 *
 * 每次运行都会 DROP SCHEMA CASCADE 重建 `haven_e2e`，Flyway 在空 schema 里跑一遍全部迁移。
 *
 * 可用环境变量覆盖：
 *   E2E_DB_HOST / E2E_DB_PORT / E2E_DB_USER / E2E_DB_PASSWORD / E2E_DB_NAME / E2E_DB_SCHEMA
 *   E2E_PORT
 */
import { execFileSync, spawn } from 'node:child_process'
import { existsSync, readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)))
const BACKEND = path.resolve(ROOT, '../backend')
const JAR = path.join(BACKEND, 'target/haven-2.1.0.jar')

const DB_HOST = process.env.E2E_DB_HOST ?? '127.0.0.1'
const DB_PORT = process.env.E2E_DB_PORT ?? '5432'
const DB_USER = process.env.E2E_DB_USER ?? 'dev'
const DB_PASSWORD = process.env.E2E_DB_PASSWORD ?? '123456'
const DB_NAME = process.env.E2E_DB_NAME ?? 'dev_db'
const DB_SCHEMA = process.env.E2E_DB_SCHEMA ?? 'haven_e2e'
const PORT = process.env.E2E_PORT ?? '18099'

/**
 * 私有域宿主名。
 *
 * 前端按 hostname 在「公开域 / 私有域」两套路由表之间切换，私有域名来自后端
 * `GET /api/app-config`（dev 配置是 `private-hosts: localhost`）。
 * E2E 要同时覆盖两侧：
 * - `localhost`   → 私有域（工作台、设置）
 * - `127.0.0.1`   → 非私有域，派生出公开路由表（nginx / 本机直连 IP 的常见形态）
 */
const PRIVATE_HOSTS = 'localhost'

/** 后端起服务前要清空的表（顺序：子表在前）。夹具每次重置数据也复用这份清单。 */
export const E2E_TABLES = [
  'note_tags',
  'note_versions',
  'notes',
  'folders',
  'tags',
  'issue_status_events',
  'issues',
  'portfolio_repos',
  'portfolio_items',
  'ledger_entries',
  'ledger_batches',
  'ledger_aliases',
  'trusted_devices',
  'pending_totp',
  'sa_token',
  'audit_events',
  'tokens',
  'users',
]

function psql(sql) {
  execFileSync(
    'psql',
    ['-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME, '-v', 'ON_ERROR_STOP=1', '-c', sql],
    { env: { ...process.env, PGPASSWORD: DB_PASSWORD }, stdio: 'pipe' },
  )
}

/** 后端一启动就把 dist 打进 jar，这里先确认产物存在，免得启动到一半才失败。 */
function checkArtifacts() {
  if (!existsSync(JAR)) {
    console.error(`[e2e] 找不到后端产物：${JAR}`)
    console.error('[e2e] 先执行 ./scripts/build.sh all')
    process.exit(1)
  }
}

function prepareSchema() {
  // search_path 保留 public：pg_trgm 扩展装在 public，gin_trgm_ops 操作符类要能被解析到。
  // 业务表仍会建在 DB_SCHEMA 里，因为 currentSchema 决定了 DDL 的默认落点。
  psql(`DROP SCHEMA IF EXISTS ${DB_SCHEMA} CASCADE`)
  psql(`CREATE SCHEMA ${DB_SCHEMA}`)
  console.log(`[e2e] 已重建 schema ${DB_NAME}.${DB_SCHEMA}`)
}

checkArtifacts()
prepareSchema()

const child = spawn(
  'java',
  ['-jar', JAR, `--server.port=${PORT}`, '--spring.profiles.active=dev'],
  {
    cwd: BACKEND,
    stdio: 'inherit',
    env: {
      ...process.env,
      // currentSchema 让 Flyway 与所有业务 SQL 都落在 e2e schema 里，开发库其它 schema 不受影响。
      // search_path 带上 public 才能用 public 里的 pg_trgm 操作符类。
      DB_URL: `jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}?currentSchema=${DB_SCHEMA},public`,
      DB_USERNAME: DB_USER,
      DB_PASSWORD,
      // 关掉开发环境的 devtools 重启，避免测试中途进程退出
      SPRING_DEVTOOLS_RESTART_ENABLED: 'false',
      // 让同一个实例既能测私有域（localhost）也能测公开域（127.0.0.1）
      HAVEN_PRIVATE_HOSTS: PRIVATE_HOSTS,
    },
  },
)

const shutdown = () => {
  if (!child.killed) child.kill('SIGTERM')
}
process.on('SIGTERM', shutdown)
process.on('SIGINT', shutdown)
child.on('exit', (code) => process.exit(code ?? 0))

// 让 Playwright 能等到健康检查通过
void readFileSync
