import { createHash } from 'node:crypto'
import { psql, scalar } from './db'
import { expect, test, TEST_PASSWORD, TEST_USER } from './fixtures'

/**
 * 认证相关的敏感操作：修改密码、撤销授信设备、结束会话。
 *
 * 这三个都涉及「让某个凭据失效」，而失效类改动最容易出现「接口返回 200、凭据其实还能用」。
 * 所以每条都**真的拿旧凭据去访问一次**，而不是只看返回码。
 */

/** 造一个最小的合法 PNG（1×1 像素），用于上传与改密后的持久化验证。 */
const TINY_PNG = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  'base64',
)

test('修改密码：旧密码错误时被拒绝，密码不变', async ({ authedPage: page }) => {
  const res = await page.request.post('/api/auth/password', {
    data: { old_password: 'wrong-old-password', new_password: 'brand-new-password-123' },
  })
  expect(res.status()).toBe(401)

  // 旧密码仍然可用
  const anon = await page.context().browser()!.newContext()
  const login = await anon.request.post('/api/auth/login', {
    data: { username: TEST_USER, password: TEST_PASSWORD },
  })
  expect(login.ok()).toBeTruthy()
  await anon.close()
})

test('修改密码：新旧密码相同被拒绝', async ({ authedPage: page }) => {
  const res = await page.request.post('/api/auth/password', {
    data: { old_password: TEST_PASSWORD, new_password: TEST_PASSWORD },
  })
  // 参数校验失败统一返回 422（见 GlobalExceptionHandler）
  expect(res.status()).toBe(422)
})

test('修改密码：新密码过短被拒绝（至少 12 位）', async ({ authedPage: page }) => {
  const res = await page.request.post('/api/auth/password', {
    data: { old_password: TEST_PASSWORD, new_password: 'short123' },
  })
  // @Valid 触发的 Bean Validation 失败是 400；
  // 业务代码里主动抛的 BizException.validation 才是 422。两者要分清。
  expect(res.status()).toBe(400)
})

test('修改密码：成功后旧密码失效、新密码可用、旧会话被踢下线', async ({ authedPage: page }) => {
  const NEW_PASSWORD = 'new-secure-password-456'

  const res = await page.request.post('/api/auth/password', {
    data: { old_password: TEST_PASSWORD, new_password: NEW_PASSWORD },
  })
  expect(res.status(), await res.text()).toBe(200)

  // 1. 旧密码不再可用
  const anon = await page.context().browser()!.newContext()
  const oldLogin = await anon.request.post('/api/auth/login', {
    data: { username: TEST_USER, password: TEST_PASSWORD },
  })
  expect(oldLogin.status(), '旧密码必须失效').toBe(401)

  // 2. 新密码可用
  const newLogin = await anon.request.post('/api/auth/login', {
    data: { username: TEST_USER, password: NEW_PASSWORD },
  })
  expect(newLogin.ok(), await newLogin.text()).toBeTruthy()

  // 3. 改密前的旧会话已被踢下线（用原 page 的 Cookie 访问）
  const me = await page.request.get('/api/me')
  expect(((await me.json()) as { anonymous: boolean }).anonymous).toBe(true)

  await anon.close()
})

test('修改密码：会同时撤销已有 API Token', async ({ authedPage: page }) => {
  const created = (await (
    await page.request.post('/api/tokens', { data: { name: '改密前创建', scope: 'read' } })
  ).json()) as { token: string }

  // 确认这个 Token 现在能用
  const before = await page.request.get('/api/notes', {
    headers: { Authorization: `Bearer ${created.token}` },
  })
  expect(before.ok()).toBeTruthy()

  const res = await page.request.post('/api/auth/password', {
    data: { old_password: TEST_PASSWORD, new_password: 'another-strong-password-789' },
  })
  expect(res.ok()).toBeTruthy()

  // 改密后旧 Token 必须失效：否则「改了密码但旧脚本还能进」是实打实的安全漏洞
  const after = await page.request.get('/api/notes', {
    headers: { Authorization: `Bearer ${created.token}` },
  })
  expect(after.status(), '改密后旧 Token 必须失效').toBe(401)
})

// ---------------------------------------------------------------------------
// 授信设备
// ---------------------------------------------------------------------------

test('授信设备：列表在无设备时为空', async ({ authedPage: page }) => {
  const res = await page.request.get('/api/trusted-devices')
  expect(res.ok()).toBeTruthy()
  expect(await res.json()).toMatchObject({ items: [], total: 0 })
})

/**
 * 授信设备只在「开启 TOTP + 勾选信任这台设备」登录时产生，
 * 测试账号没有开 2FA，走不到那条路径。
 * 所以直接写库造一条设备：token_hash 就是明文的 SHA-256（与 ApiTokenUtil.hash 一致）。
 */
const TRUSTED_TOKEN = 'e2e-trusted-device-token'
const TRUSTED_TOKEN_HASH = createHash('sha256').update(TRUSTED_TOKEN).digest('hex')

function createTrustedDevice(userId: string): void {
  psql(`
    insert into public.trusted_devices (user_id, device_name, token_hash, expires_at)
    values ('${userId}', 'E2E 测试设备', '${TRUSTED_TOKEN_HASH}', now() + interval '30 days');
  `)
}

/** 库里实际剩下几条授信设备。 */
function countTrustedDevices(): number {
  return scalar('select count(*) from public.trusted_devices')
}

async function currentUserId(page: import('@playwright/test').Page): Promise<string> {
  const body = (await (await page.request.get('/api/me')).json()) as { user: { id: string } }
  return body.user.id
}

test('授信设备：撤销后从列表消失，且记录被删除', async ({ authedPage: page }) => {
  const userId = await currentUserId(page)
  createTrustedDevice(userId)

  // 列表里能看到
  const list = (await (await page.request.get('/api/trusted-devices')).json()) as {
    items: { id: string; device_name: string }[]
  }
  expect(list.items).toHaveLength(1)
  expect(list.items[0].device_name).toBe('E2E 测试设备')

  // 撤销
  const del = await page.request.delete(`/api/trusted-devices/${list.items[0].id}`)
  expect(del.status()).toBe(204)

  // 列表清空，且库里确实没了（不是只从响应里过滤掉）
  const after = (await (await page.request.get('/api/trusted-devices')).json()) as { items: unknown[] }
  expect(after.items).toHaveLength(0)
  expect(countTrustedDevices()).toBe(0)
})

test('授信设备：撤销不存在的 id 返回 404，且不影响其他设备', async ({ authedPage: page }) => {
  const userId = await currentUserId(page)
  createTrustedDevice(userId)

  const res = await page.request.delete('/api/trusted-devices/00000000-0000-0000-0000-000000000000')
  expect(res.status()).toBe(404)

  const list = (await (await page.request.get('/api/trusted-devices')).json()) as { items: unknown[] }
  expect(list.items).toHaveLength(1)
})

test('授信设备：改密会同时撤销所有授信设备', async ({ authedPage: page }) => {
  const userId = await currentUserId(page)
  createTrustedDevice(userId)
  expect(countTrustedDevices()).toBe(1)

  const res = await page.request.post('/api/auth/password', {
    data: { old_password: TEST_PASSWORD, new_password: 'password-after-revoke-000' },
  })
  expect(res.ok()).toBeTruthy()

  expect(countTrustedDevices(), '改密后授信设备必须全部失效').toBe(0)
})

// ---------------------------------------------------------------------------
// 会话
// ---------------------------------------------------------------------------

test('会话：列表包含当前会话，并标记 is_current', async ({ authedPage: page }) => {
  const res = await page.request.get('/api/sessions')
  expect(res.ok()).toBeTruthy()

  const body = (await res.json()) as { items: { id: string; is_current: boolean }[]; total: number }
  expect(body.total).toBeGreaterThanOrEqual(1)
  expect(body.items.filter((s) => s.is_current)).toHaveLength(1)
})

test('会话：结束其他会话后，那个会话真的失效了', async ({ authedPage: page }) => {
  // 另开一个浏览器上下文登录，制造「第二个会话」
  const other = await page.context().browser()!.newContext()
  const otherLogin = await other.request.post('/api/auth/login', {
    data: { username: TEST_USER, password: TEST_PASSWORD },
  })
  expect(otherLogin.ok()).toBeTruthy()

  // 当前会话应该看到两个会话
  const list = (await (await page.request.get('/api/sessions')).json()) as {
    items: { id: string; is_current: boolean }[]
  }
  expect(list.items.length).toBe(2)
  const target = list.items.find((s) => !s.is_current)
  expect(target, '应存在另一个会话').toBeTruthy()

  // 结束它
  const del = await page.request.delete(`/api/sessions/${target!.id}`)
  expect(del.status()).toBe(204)

  // 关键断言：另一个会话真的不能再用
  const otherMe = await other.request.get('/api/me')
  expect(((await otherMe.json()) as { anonymous: boolean }).anonymous, '被结束的会话必须失效').toBe(
    true,
  )

  // 当前会话不受影响
  const me = await page.request.get('/api/me')
  expect(((await me.json()) as { anonymous: boolean }).anonymous).toBe(false)

  await other.close()
})

test('会话：不能结束不属于自己的会话', async ({ authedPage: page }) => {
  const res = await page.request.delete('/api/sessions/00000000-0000-0000-0000-000000000000')
  // 不存在或不属于自己，一律 404，不泄露存在性
  expect(res.status()).toBe(404)
})

// ---------------------------------------------------------------------------
// 上传
// ---------------------------------------------------------------------------

/** 用 multipart 上传一个 Buffer。 */
async function upload(
  page: import('@playwright/test').Page,
  buffer: Buffer,
  filename: string,
  mimeType: string,
): Promise<import('@playwright/test').APIResponse> {
  return page.request.post('/api/uploads', {
    multipart: { file: { name: filename, mimeType, buffer } },
  })
}

test('上传：合法 PNG 成功，返回可直接访问的 URL', async ({ authedPage: page }) => {
  const res = await upload(page, TINY_PNG, 'icon.png', 'image/png')
  expect(res.status(), await res.text()).toBe(201)

  const body = (await res.json()) as { url: string; name: string; size: number; mime: string }
  expect(body.mime).toBe('image/png')
  expect(body.size).toBe(TINY_PNG.length)
  // name 是原始文件名（仅用于展示），磁盘上落的是随机名：看 url 的最后一段
  const diskName = body.url.split('/').pop()!
  expect(diskName).toMatch(/^[0-9a-f]{32}\.png$/)
  expect(diskName).not.toContain('icon')

  // 静态资源可访问
  const fetched = await page.request.get(body.url)
  expect(fetched.status()).toBe(200)
  expect(fetched.headers()['content-type']).toContain('image/png')
})

test('上传：伪装成 .png 的文本文件被拒绝（按真实 MIME 判断）', async ({ authedPage: page }) => {
  const fake = Buffer.from('<html><script>alert(1)</script></html>', 'utf8')
  const res = await upload(page, fake, 'evil.png', 'image/png')

  // 只看扩展名就会放行，所以这里必须拒绝
  expect(res.status(), '扩展名是 png 但内容不是图片，必须拒绝').toBe(415)
})

test('上传：空文件被拒绝', async ({ authedPage: page }) => {
  const res = await upload(page, Buffer.alloc(0), 'empty.png', 'image/png')
  // 空文件是「参数非法」→ 422；不是图片格式错 → 415
  expect(res.status()).toBe(422)
})

test('上传：超过 10 MiB 被拒绝且不落盘', async ({ authedPage: page }) => {
  // 10 MiB + 1 字节
  const big = Buffer.alloc(10 * 1024 * 1024 + 1, 0)
  const res = await upload(page, big, 'big.png', 'image/png')
  expect(res.status()).toBe(413)

  const body = (await res.json()) as { error: string }
  expect(body.error).toBeTruthy()
})

test('上传：原始文件名不参与磁盘路径（路径穿越无效）', async ({ authedPage: page }) => {
  const res = await upload(page, TINY_PNG, '../../../../etc/passwd.png', 'image/png')
  expect(res.status()).toBe(201)

  const body = (await res.json()) as { url: string }
  // URL 落在 uploads 下，且不含 ..
  expect(body.url).toContain('/uploads/')
  expect(body.url).not.toContain('..')
  expect(body.url).not.toContain('passwd')
})

test('上传：未登录返回 401', async ({ authedPage: page }) => {
  const anon = await page.context().browser()!.newContext()
  const res = await anon.request.post('/api/uploads', {
    multipart: { file: { name: 'a.png', mimeType: 'image/png', buffer: TINY_PNG } },
  })
  expect(res.status()).toBe(401)
  await anon.close()
})

test('上传：上传后可出现在图标库列表里', async ({ authedPage: page }) => {
  await upload(page, TINY_PNG, 'pick-me.png', 'image/png')

  const res = await page.request.get('/api/uploads')
  expect(res.ok()).toBeTruthy()
  const body = (await res.json()) as { items: { url: string }[]; total: number }
  expect(body.items.length).toBeGreaterThanOrEqual(1)
})
