import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import IconPicker from '@/components/note/IconPicker.vue'

/**
 * 图标面板：能点开、能选、能恢复默认。
 *
 * 这个组件是从 NoteListPanel 抽出来的，抽完出现过「点了没反应」，
 * 所以用组件测试把交互链路固定下来：不是测 DOM 结构，而是测事件是否发出。
 */
vi.mock('@/api/uploads', () => ({
  listUploads: vi.fn(async () => ({ items: [], total: 0 })),
  uploadImage: vi.fn(),
  isUploadableImage: vi.fn(() => false),
}))

describe('IconPicker', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  function mountPicker() {
    return mount(IconPicker, { props: { open: true, disabled: false } })
  }

  it('默认停在「全部」页并展示 emoji', () => {
    const wrapper = mountPicker()

    // 「全部」是第一个 tab，且处于选中态
    const tabs = wrapper.findAll('[role="tab"]')
    expect(tabs.length).toBe(4)
    expect(tabs[0].attributes('aria-selected')).toBe('true')

    // emoji 按钮数量大于 0（数据源非空）
    expect(wrapper.findAll('.icon-picker__emoji-btn').length).toBeGreaterThan(0)
  })

  it('点击 emoji 发出 select 事件', async () => {
    const wrapper = mountPicker()

    const firstEmoji = wrapper.findAll('.icon-picker__emoji-btn')[0]
    await firstEmoji.trigger('click')

    const emitted = wrapper.emitted('select')
    expect(emitted).toBeTruthy()
    expect(emitted![0][0]).toBe(firstEmoji.text())
  })

  it('点「恢复默认」发出 select(null)', async () => {
    const wrapper = mountPicker()

    const restore = wrapper.findAll('.icon-picker__actions button')[0]
    await restore.trigger('click')

    expect(wrapper.emitted('select')![0][0]).toBeNull()
  })

  it('点「取消」发出 close', async () => {
    const wrapper = mountPicker()

    const cancel = wrapper.findAll('.icon-picker__actions button')[1]
    await cancel.trigger('click')

    expect(wrapper.emitted('close')).toBeTruthy()
  })

  it('切到 Emoji / 品牌 / 图片页都能渲染内容', async () => {
    const wrapper = mountPicker()
    const tabs = wrapper.findAll('[role="tab"]')

    await tabs[1].trigger('click')
    expect(wrapper.findAll('.icon-picker__choice').length).toBeGreaterThan(0)

    await tabs[2].trigger('click')
    expect(wrapper.findAll('.icon-picker__brand').length).toBeGreaterThan(0)

    await tabs[3].trigger('click')
    expect(wrapper.find('.icon-picker__images').exists()).toBe(true)
  })

  it('disabled 时上传按钮不可点', () => {
    const wrapper = mount(IconPicker, { props: { open: true, disabled: true } })

    const uploadBtn = wrapper.find('.icon-picker__upload-btn')
    expect(uploadBtn.attributes('disabled')).toBeDefined()
  })
})
