#!/usr/bin/env node
/**
 * E2E 启动脚本：准备一个隔离的数据库，然后起一个完整的后端实例。
 *
 * 隔离原则：**绝不使用开发库里的业务表**。
 * 每次运行都会 DROP + CREATE 独立数据库 `haven_e2e_db`，Flyway 在空库里跑一遍全部迁移，
 * 迁移结果与真实部署完全一致。
 *
 * 为什么是独立数据库而不是 schema：V16 起业务表分在 note / issue / ledger，
 * 而 PostgreSQL schema 不能嵌套——在 `haven_e2e` schema 里跑 `CREATE SCHEMA note`
 * 会把 module schema 建到 dev_db 顶层，污染开发库。
 *
 * 注意：重建数据库需要账号有 CREATEDB 权限，见 docs/testing.md。
 *
 * 可用环境变量覆盖：
 *   E2E_DB_HOST / E2E_DB_PORT / E2E_DB_USER / E2E_DB_PASSWORD / E2E_DB_NAME
 *   E2E_PORT
 */
import { execFileSync, spawn } from 'node:child_process'
import { existsSync, readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)))
const BACKEND = path.resolve(ROOT, '../backend')

/**
 * 产物名跟随根目录的 VERSION 文件，不要在脚本里写死版本号：
 * 升版后写死的路径会让 E2E 报「找不到产物」，看起来像构建失败。
 */
const VERSION = readFileSync(path.resolve(ROOT, '../VERSION'), 'utf8').trim()
const JAR = path.join(BACKEND, `target/haven-${VERSION}.jar`)

const DB_HOST = process.env.E2E_DB_HOST ?? '127.0.0.1'
const DB_PORT = process.env.E2E_DB_PORT ?? '5432'
const DB_USER = process.env.E2E_DB_USER ?? 'dev'
const DB_PASSWORD = process.env.E2E_DB_PASSWORD ?? '123456'
const DB_NAME = process.env.E2E_DB_NAME ?? 'dev_db'
const E2E_DB = process.env.E2E_DB_NAME ?? 'haven_e2e_db'
const PORT = process.env.E2E_PORT ?? '18099'

/** 在指定库里执行一段 SQL。 */
function psql(sql, database = DB_NAME) {
  execFileSync(
    'psql',
    ['-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', database, '-v', 'ON_ERROR_STOP=1', '-c', sql],
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

/**
 * 重建独立 E2E 数据库。
 *
 * psql 默认连 DB_NAME（维护库），这里显式切到维护库再动目标库，
 * 避免「数据库正在被访问」导致 DROP 失败。
 */
function prepareDatabase() {
  const admin = ['-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME, '-v', 'ON_ERROR_STOP=1', '-c']
  const run = (sql) =>
    execFileSync('psql', [...admin, sql], { env: { ...process.env, PGPASSWORD: DB_PASSWORD }, stdio: 'pipe' })
  run(`SELECT pg_terminate_backend(pid) FROM pg_stat_activity
       WHERE datname = '${E2E_DB}' AND pid <> pg_backend_pid()`)
  run(`DROP DATABASE IF EXISTS ${E2E_DB}`)
  run(`CREATE DATABASE ${E2E_DB}`)
  // 扩展要装在新库自己的 public 里，迁移里的 gin_trgm_ops 才能解析
  psql('CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA public', E2E_DB)
  console.log(`[e2e] 已重建独立测试库 ${E2E_DB}`)
}

checkArtifacts()
prepareDatabase()

const child = spawn(
  'java',
  ['-jar', JAR, `--server.port=${PORT}`, '--spring.profiles.active=dev'],
  {
    cwd: BACKEND,
    stdio: 'inherit',
    env: {
      ...process.env,
      // 直接指向独立库，不再用 currentSchema / search_path 切 schema
      DB_URL: `jdbc:postgresql://${DB_HOST}:${DB_PORT}/${E2E_DB}`,
      DB_USERNAME: DB_USER,
      DB_PASSWORD,
      // 关掉开发环境的 devtools 重启，避免测试中途进程退出
      SPRING_DEVTOOLS_RESTART_ENABLED: 'false',
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
