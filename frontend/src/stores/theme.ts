/**
 * 主题状态 store。
 *
 * 主题只有一个来源：<html data-theme>。这个 store 负责读写它，
 * 并把选择持久化到 localStorage（与侧边栏折叠同一套做法）。
 */
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { THEMES, applyTheme, readStoredTheme, writeStoredTheme } from '@/utils/theme'

export const useThemeStore = defineStore('theme', () => {
  const current = ref(readStoredTheme())

  /** 把当前主题写进 DOM。应用启动时调用一次。 */
  function init(): void {
    applyTheme(current.value)
  }

  function setTheme(id: string): void {
    current.value = id
    applyTheme(id)
    writeStoredTheme(id)
  }

  return { current, themes: THEMES, init, setTheme }
})
