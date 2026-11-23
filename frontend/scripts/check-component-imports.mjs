#!/usr/bin/env node
// 扫描 .vue：模板里出现的 PascalCase 标签，必须在 script 里有 import
// （或是 Vue 内置组件）。漏 import 时 Vue 会把它当原生标签渲染，
// vue-tsc 不报，只有运行期才会露馅。
import fs from 'node:fs'
import path from 'node:path'

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

const files = walk('src').filter((file) => file.endsWith('.vue'))
let problems = 0

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
    console.log(`${file}: 模板用到但未 import -> ${[...unknown].join(', ')}`)
  }
}

console.log(`checked ${files.length} .vue files; problems: ${problems}`)
process.exit(problems > 0 ? 1 : 0)