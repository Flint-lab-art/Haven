import { describe, expect, it } from 'vitest'
import { detectDomain } from '@/router/domain'
import { ApiError } from '@/api/client'
import { deviceLabel, formatRelative, formatDateTime, formatDate } from '@/utils/format'

describe('detectDomain', () => {
  it('本地地址一律视为私有域', () => {
    expect(detectDomain('localhost')).toBe('private')
    expect(detectDomain('127.0.0.1')).toBe('private')
    expect(detectDomain('192.168.1.10')).toBe('private')
  })

  it('生产环境默认公开域（未配置 VITE_PRIVATE_HOST）', () => {
    expect(detectDomain('example.com')).toBe('public')
    expect(detectDomain('www.example.com')).toBe('public')
    expect(detectDomain('app.example.com')).toBe('public')
  })

  it('配置了 VITE_PRIVATE_HOST 时按主机名区分', () => {
    expect(detectDomain('app.example.com', 'app.example.com')).toBe('private')
    expect(detectDomain('example.com', 'app.example.com')).toBe('public')
    expect(detectDomain('www.example.com', 'app.example.com')).toBe('public')
  })
})

describe('ApiError', () => {
  it('携带 status / code / fields', () => {
    const err = new ApiError(422, {
      error: 'validation_failed',
      message: '字段校验失败',
      fields: { title: '不能为空' },
    })
    expect(err.status).toBe(422)
    expect(err.code).toBe('validation_failed')
    expect(err.fields?.title).toBe('不能为空')
    expect(err.message).toBe('字段校验失败')
  })

  it('识别常见状态码', () => {
    expect(new ApiError(401, { error: 'unauthorized', message: '' }).isUnauthorized).toBe(true)
    expect(new ApiError(403, { error: 'forbidden', message: '' }).isForbidden).toBe(true)
    expect(new ApiError(404, { error: 'not_found', message: '' }).isNotFound).toBe(true)
  })
})

describe('format', () => {
  it('formatDate 输出中文日期', () => {
    expect(formatDate('2026-10-28T12:00:00Z')).toMatch(/2026年10月2[78]日/)
    expect(formatDate(null)).toBe('')
    expect(formatDate('not-a-date')).toBe('')
  })

  it('formatDateTime 补零', () => {
    const value = new Date(2026, 9, 28, 9, 5, 0).toISOString()
    expect(formatDateTime(value)).toBe('10月28日 09:05')
  })

  it('formatRelative 给出相对时间', () => {
    const now = Date.now()
    expect(formatRelative(new Date(now - 30_000).toISOString())).toBe('刚刚')
    expect(formatRelative(new Date(now - 5 * 60_000).toISOString())).toBe('5 分钟前')
    expect(formatRelative(new Date(now - 3 * 3600_000).toISOString())).toBe('3 小时前')
    expect(formatRelative(new Date(now - 2 * 86400_000).toISOString())).toBe('2 天前')
  })

  it('deviceLabel 从 UA 推断设备', () => {
    expect(deviceLabel('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/130')).toBe('macOS · Chrome')
    expect(deviceLabel('Mozilla/5.0 (Windows NT 10.0) Firefox/120')).toBe('Windows · Firefox')
    expect(deviceLabel('curl/8.23.0')).toBe('curl')
    expect(deviceLabel(null)).toBe('未知设备')
  })
})
