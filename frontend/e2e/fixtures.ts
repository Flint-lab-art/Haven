import { expect, test as base, type APIRequestContext, type Page } from '@playwright/test'
import { psql, SCHEMA } from './db'

/**
 * E2E 共享夹具。
 *
 * 每个用例开始前重置数据库到已知状态：一个关闭 TOTP 的测试账号 + 他的收件箱。
 * 账号密码固定，哈希是 BCrypt cost 4（测试专用，真实环境用 12）。
 *
 * 所有 SQL 都带 schema 前缀，与 start-server.mjs 使用同一套连接参数。
 */

export const TEST_USER = 'e2e-user'
export const TEST_PASSWORD = 'e2e-password-123'

/** 预生成的 BCrypt 哈希；改密码要同步改这里。 */
const TEST_PASSWORD_HASH = '$2a$04$x7zXaN/18sMxL4mT37YaieUefx/zLJt0AWWZwb1BFLKoo53e07FaG'

/**
 * 清空业务表并重建测试账号。
 *
 * 直接用 psql 而不是走 API：没有注册接口，账号只能写库。
 * sa_token / pending_totp 没有指向 users 的外键，必须显式清，
 * 否则残留会话会让下一轮用例一开始就处于登录态。
 */
export async function resetDatabase(): Promise<void> {
  const sql = `
    delete from ${SCHEMA}.note_tags;
    delete from ${SCHEMA}.note_versions;
    delete from ${SCHEMA}.notes;
    delete from ${SCHEMA}.folders;
    delete from ${SCHEMA}.tags;
    delete from ${SCHEMA}.issue_status_events;
    delete from ${SCHEMA}.issues;
    delete from ${SCHEMA}.portfolio_repos;
    delete from ${SCHEMA}.portfolio_items;
    delete from ${SCHEMA}.ledger_entries;
    delete from ${SCHEMA}.ledger_batches;
    delete from ${SCHEMA}.ledger_aliases;
    delete from ${SCHEMA}.trusted_devices;
    delete from ${SCHEMA}.pending_totp;
    delete from ${SCHEMA}.sa_token;
    delete from ${SCHEMA}.audit_events;
    delete from ${SCHEMA}.tokens;
    delete from ${SCHEMA}.users;

    insert into ${SCHEMA}.users (id, username, password_hash, totp_enabled, created_at, updated_at)
    values (gen_random_uuid(), '${TEST_USER}', '${TEST_PASSWORD_HASH}', false, now(), now());

    insert into ${SCHEMA}.folders (user_id, parent_id, name, sort_order, is_inbox)
    select id, null, '收件箱', 0, true from ${SCHEMA}.users where username = '${TEST_USER}';
  `
  psql(sql)
}

/** 用 UI 登录（不走 API，确保登录页本身被测到）。 */
export async function loginViaUi(page: Page): Promise<void> {
  await page.goto('/login')
  await page.getByLabel('用户名').fill(TEST_USER)
  await page.getByLabel('密码').fill(TEST_PASSWORD)
  await page.getByRole('button', { name: '登录', exact: true }).click()
  // 登录后进仪表盘（登录页没有 redirect 参数时的默认落点），
  // 断言侧边栏出现，避免只靠 URL 判断（URL 可能先变、页面还没挂载）
  await expect(page.getByRole('button', { name: '账户菜单' })).toBeVisible()
  await expect(page).not.toHaveURL(/\/login/)
}

/**
 * 造一个已登录的 API 上下文，用于准备数据（比 UI 造数据快且稳）。
 *
 * 走 /api/auth/login 拿 Cookie，后续请求自动带凭证。
 */
export async function loginViaApi(request: APIRequestContext): Promise<void> {
  const res = await request.post('/api/auth/login', {
    data: { username: TEST_USER, password: TEST_PASSWORD },
  })
  expect(res.ok(), `登录失败：${res.status()} ${await res.text()}`).toBeTruthy()
}

/** 收件箱的 id：新建笔记不指定文件夹时落在收件箱，用例常需要它。 */
export async function getInboxId(request: APIRequestContext): Promise<string> {
  const res = await request.get('/api/folders')
  expect(res.ok()).toBeTruthy()
  const body = (await res.json()) as { items: { id: string; is_inbox: boolean }[] }
  const inbox = body.items.find((f) => f.is_inbox)
  expect(inbox, '缺少收件箱').toBeTruthy()
  return inbox!.id
}

export const test = base.extend<{ authedPage: Page }>({
  authedPage: async ({ page }, use) => {
    await resetDatabase()
    await loginViaUi(page)
    await use(page)
  },
})

export { expect }
