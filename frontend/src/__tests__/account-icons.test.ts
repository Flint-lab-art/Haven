import { describe, expect, it } from 'vitest'
import fs from 'node:fs'
import path from 'node:path'
import { ACCOUNT_ICONS, findAccountIcon, iconSrc } from '@/utils/account-icons'

/**
 * 账户图标注册表与 `public/icons/` 的一致性。
 *
 * 这里曾经出过问题：图标文件放进去了，但没登记进 ACCOUNT_ICONS，选择面板里看不到；
 * 反过来登记了却没放文件，界面就是一个裂图（`<img>` 加载失败不报错，很容易漏）。
 * 两边都是「不报错但坏掉」，只能靠断言兜住。
 */

const ICONS_DIR = path.resolve(process.cwd(), 'public/icons')

describe('account-icons', () => {
  it('每个 key 都有对应的 svg 文件', () => {
    const missing = ACCOUNT_ICONS.filter(
      (icon) => !fs.existsSync(path.join(ICONS_DIR, `${icon.key}.svg`)),
    ).map((icon) => `${icon.key}.svg`)

    expect(missing).toEqual([])
  })

  it('目录里的每个 svg 都登记过（否则选择面板里永远选不到）', () => {
    const registered = new Set(ACCOUNT_ICONS.map((icon) => `${icon.key}.svg`))
    // 只有 .svg 归这套体系；目录里还有备份告警用的 bark-*.png，不算账户图标
    const onDisk = fs.readdirSync(ICONS_DIR).filter((file) => file.endsWith('.svg'))

    const unregistered = onDisk.filter((file) => !registered.has(file))
    expect(unregistered).toEqual([])
  })

  it('key 唯一，label 非空', () => {
    const keys = ACCOUNT_ICONS.map((icon) => icon.key)
    expect(new Set(keys).size).toBe(keys.length)
    for (const icon of ACCOUNT_ICONS) {
      expect(icon.label.trim()).not.toBe('')
    }
  })

  it('key 是不带扩展名的纯文件名（iconSrc 直接拼 /icons/<key>.svg）', () => {
    for (const icon of ACCOUNT_ICONS) {
      expect(icon.key).toMatch(/^[a-z0-9]+$/)
      expect(iconSrc(icon.key)).toBe(`/icons/${icon.key}.svg`)
    }
  })

  it('未知 key 返回 undefined，调用方回退到首字头像', () => {
    expect(findAccountIcon('')).toBeUndefined()
    expect(findAccountIcon(null)).toBeUndefined()
    expect(findAccountIcon('不存在')).toBeUndefined()
  })

  it('包含现金与存钱罐两枚储值图标', () => {
    expect(findAccountIcon('cash')?.label).toBe('现金')
    expect(findAccountIcon('piggybank')?.label).toBe('存钱罐')
  })
})