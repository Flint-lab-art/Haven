import { execFileSync } from 'node:child_process'

/**
 * 直接操作 E2E 数据库的辅助。
 *
 * 绝大多数造数据应该走 API（更快、更贴近真实路径），这里只放
 * **API 走不到的情况**：比如授信设备只在「开 TOTP + 勾选信任本机」登录时才产生，
 * 而测试账号不开 2FA，只能写库造。
 *
 * 所有 SQL 都直接写在当前库里，与 start-server.mjs 使用同一套连接参数。
 */

const DB_HOST = process.env.E2E_DB_HOST ?? '127.0.0.1'
const DB_PORT = process.env.E2E_DB_PORT ?? '5432'
const DB_USER = process.env.E2E_DB_USER ?? 'dev'
const DB_PASSWORD = process.env.E2E_DB_PASSWORD ?? '123456'
/**
 * E2E 专用数据库，每次运行由 start-server.mjs 重建。
 *
 * V16 起业务表分在 note / issue / ledger，而 schema 不能嵌套，
 * 所以隔离单位从「schema」换成了「独立库」，SQL 里直接写模块 schema 前缀。
 */
const DB_NAME = process.env.E2E_DB_NAME ?? 'haven_e2e_db'

/** 执行一段 SQL（可含多条语句）。 */
export function psql(sql: string): string {
  return execFileSync(
    'psql',
    ['-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME, '-v', 'ON_ERROR_STOP=1', '-tA', '-c', sql],
    { env: { ...process.env, PGPASSWORD: DB_PASSWORD }, stdio: 'pipe' },
  ).toString()
}

/** 查一个整数（用于「库里确实删了」这类断言，比只看接口更可靠）。 */
export function scalar(sql: string): number {
  return Number(psql(sql).trim())
}
