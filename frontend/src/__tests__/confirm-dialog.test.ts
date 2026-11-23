import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import ConfirmDialog from '@/components/common/ConfirmDialog.vue'

/**
 * 守住「确认」与「取消」互斥这条契约。
 *
 * 背景：Reka 的 AlertDialogAction 本身就是 DialogClose，点它会先触发
 * `update:open(false)`，再触发我们自己的 @click。迁移时 onOpenChange 里
 * 同步发 cancel，于是点「删除」会先 cancel 再 confirm —— 父组件在 cancel
 * 里把待处理目标清空，confirm 读到 null 直接返回，删除静默失效
 * （记账、笔记、文件夹、回收站、Issue、版本还原 6 处全部中招）。
 */
function buttonByText(text: string): HTMLButtonElement {
  const found = Array.from(document.querySelectorAll('button')).find(
    (b) => b.textContent?.trim() === text,
  )
  if (!found) throw new Error(`找不到按钮：${text}`)
  return found as HTMLButtonElement
}

async function mountDialog(props: Record<string, unknown> = {}) {
  const wrapper = mount(ConfirmDialog, {
    props: { open: true, title: '删除这笔记录？', message: '删除后不可恢复。', ...props },
    attachTo: document.body,
  })
  await nextTick()
  return wrapper
}

describe('ConfirmDialog 事件契约', () => {
  it('点「删除」只发 confirm，不发 cancel', async () => {
    const wrapper = await mountDialog()

    buttonByText('删除').click()
    await nextTick()
    await Promise.resolve()

    expect(wrapper.emitted('confirm')).toHaveLength(1)
    expect(wrapper.emitted('cancel')).toBeUndefined()
    wrapper.unmount()
  })

  it('点「取消」只发 cancel', async () => {
    const wrapper = await mountDialog()

    buttonByText('取消').click()
    await nextTick()
    await Promise.resolve()

    expect(wrapper.emitted('cancel')).toHaveLength(1)
    expect(wrapper.emitted('confirm')).toBeUndefined()
    wrapper.unmount()
  })

  it('busy 时确认不发事件，按钮显示处理中', async () => {
    const wrapper = await mountDialog({ busy: true })

    buttonByText('处理中…').click()
    await nextTick()
    await Promise.resolve()

    expect(wrapper.emitted('confirm')).toBeUndefined()
    expect(wrapper.emitted('cancel')).toBeUndefined()
    wrapper.unmount()
  })

  it('确认后重复点取消不会补发 cancel', async () => {
    const wrapper = await mountDialog()

    buttonByText('删除').click()
    await nextTick()
    await Promise.resolve()

    expect(wrapper.emitted('confirm')).toHaveLength(1)
    expect(wrapper.emitted('cancel')).toBeUndefined()
    wrapper.unmount()
  })
})