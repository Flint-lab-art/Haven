#!/usr/bin/env node
// 扫描 .vue：模板里出现的 PascalCase 标签，必须在 script 里有 import
// （或是 Vue 内置组件）。漏 import 时 Vue 会把它当原生标签渲染，
// vue-tsc 不报，只有运行期才会露馅。
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

/** 相对脚本自身定位，这样从仓库根目录或 frontend/ 下调用都一样。 */
const FRONTEND_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')

const BUILTINS = new Set([
  'Transition',
  'TransitionGroup',
  'KeepAlive',
  'Teleport',
  'Suspense',
  'Component',
  'RouterView',
  'RouterLink',
  'Slot',
])

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) =>
    entry.isDirectory() ? walk(path.join(dir, entry.name)) : [path.join(dir, entry.name)],
  )
}

const files = walk(path.join(FRONTEND_ROOT, 'src')).filter((file) => file.endsWith('.vue'))
let problems = 0

/** 报错里显示相对 frontend/ 的路径，两处调用点输出一致。 */
const rel = (file) => path.relative(FRONTEND_ROOT, file)

for (const file of files) {
  const source = fs.readFileSync(file, 'utf8')
  const templateStart = source.indexOf('<template>')
  const scriptEnd = source.indexOf('</script>')
  const script = source.slice(0, scriptEnd === -1 ? source.length : scriptEnd)
  const template = templateStart === -1 ? '' : source.slice(templateStart)

  const imported = new Set()
  const importRe = /import\s+(?:([\w$]+)\s*,?\s*)?(?:\{([^}]*)\})?\s*from\s*['"][^'"]+['"]/g
  let match
  while ((match = importRe.exec(script))) {
    if (match[1]) imported.add(match[1])
    if (match[2]) {
      for (const part of match[2].split(',')) {
        const name = part.trim().split(/\s+as\s+/).pop()
        if (name) imported.add(name)
      }
    }
  }

  const tagRe = /<([A-Z][\w]*)(?=[\s/>])/g
  const unknown = new Set()
  while ((match = tagRe.exec(template))) {
    const tag = match[1]
    if (BUILTINS.has(tag) || imported.has(tag)) continue
    unknown.add(tag)
  }

  if (unknown.size > 0) {
    problems += 1
    console.log(`${rel(file)}: 模板用到但未 import -> ${[...unknown].join(', ')}`)
  }
}

console.log(`checked ${files.length} .vue files; problems: ${problems}`)

/*
 * 第二类检查：Popover / DropdownMenu 必须有触发锚点。
 *
 * 迁移到 Reka 时出现过这种错：<PopoverRoot> 里放了 Panel 和一个普通 <button>，
 * 但那个 button 没包进 <PopoverTrigger>。它不是语法错误（button 本身合法），
 * vue-tsc 也不管，运行时就是「点了没反应」——aria-expanded 永远 false。
 *
 * 为什么只查这两类：Popover 是「点某个东西、贴着它弹一层」的控件，锚点本身就是
 * 语义的一部分，没有 Trigger/Anchor 就一定是漏了。Dialog / AlertDialog 不一样，
 * 它们常由父组件的 v-if 或 :open 驱动（确认框、表单弹窗），没有 Trigger 是正常的。
 */
const ANCHORED_ROOTS = [
  { root: 'PopoverRoot', anchor: ['PopoverTrigger', 'PopoverAnchor'] },
  { root: 'DropdownMenuRoot', anchor: ['DropdownMenuTrigger'] },
]
let triggerProblems = 0

for (const file of files) {
  const source = fs.readFileSync(file, 'utf8')
  for (const { root, anchor } of ANCHORED_ROOTS) {
    if (!source.includes(`<${root}`)) continue
    if (anchor.some((tag) => source.includes(`<${tag}`))) continue
    triggerProblems += 1
    console.log(
      `${rel(file)}: <${root}> 缺少 ${anchor.map((t) => `<${t}>`).join(' 或 ')}，点了不会有反应`,
    )
  }
}

console.log(`trigger check; problems: ${triggerProblems}`)
process.exit(problems > 0 || triggerProblems > 0 ? 1 : 0)