/**
 * 代码块语法高亮（编辑态与阅读态共用）。
 *
 * 用 highlight.js 的 common 语言集，不引入 full 构建。
 * 支持范围与别名见 docs/v6/frontend/frontend.md 第八节；
 * 主题在 style.css 里按 HIG 配色重写，不引入 highlight.js 自带的 CSS。
 */
import hljs from 'highlight.js/lib/common'
import dockerfile from 'highlight.js/lib/languages/dockerfile'
import nginx from 'highlight.js/lib/languages/nginx'
import powershell from 'highlight.js/lib/languages/powershell'
import haskell from 'highlight.js/lib/languages/haskell'
import elixir from 'highlight.js/lib/languages/elixir'
import erlang from 'highlight.js/lib/languages/erlang'
import scala from 'highlight.js/lib/languages/scala'
import dart from 'highlight.js/lib/languages/dart'
import protobuf from 'highlight.js/lib/languages/protobuf'
import latex from 'highlight.js/lib/languages/latex'
import julia from 'highlight.js/lib/languages/julia'
import groovy from 'highlight.js/lib/languages/groovy'
import vim from 'highlight.js/lib/languages/vim'
import cmake from 'highlight.js/lib/languages/cmake'
import clojure from 'highlight.js/lib/languages/clojure'
import ocaml from 'highlight.js/lib/languages/ocaml'
import elm from 'highlight.js/lib/languages/elm'
import lisp from 'highlight.js/lib/languages/lisp'
import scheme from 'highlight.js/lib/languages/scheme'
import matlab from 'highlight.js/lib/languages/matlab'
import fortran from 'highlight.js/lib/languages/fortran'
import verilog from 'highlight.js/lib/languages/verilog'
import nim from 'highlight.js/lib/languages/nim'
import crystal from 'highlight.js/lib/languages/crystal'
import fsharp from 'highlight.js/lib/languages/fsharp'
import gradle from 'highlight.js/lib/languages/gradle'
import caddyfile from './languages/caddyfile'

/**
 * common 集之外额外注册的常见语言（docs/v6/frontend/frontend.md 8.1）。
 *
 * 都是 highlight.js 自带的小语言包，逐个注册而不是换 full 构建：
 * full 会多带近 900KB，而这里 26 种合计约 145KB 源码（压缩后更小）。
 */
const EXTRA_LANGUAGES = {
  dockerfile,
  nginx,
  powershell,
  haskell,
  elixir,
  erlang,
  scala,
  dart,
  protobuf,
  latex,
  julia,
  groovy,
  vim,
  cmake,
  clojure,
  ocaml,
  elm,
  lisp,
  scheme,
  matlab,
  fortran,
  verilog,
  nim,
  crystal,
  fsharp,
  gradle,
  // highlight.js 没有 Caddyfile，本地最小实现（见 utils/languages/caddyfile.ts）
  caddyfile,
} as const

for (const [name, definition] of Object.entries(EXTRA_LANGUAGES)) {
  hljs.registerLanguage(name, definition)
}

/** 把一段代码高亮成 HTML；语言未知时按纯文本输出（不做自动猜测）。 */
export function highlightCode(code: string, language?: string | null): string {
  const lang = normalizeLanguage(language)

  if (!lang) return escapeHtml(code)

  if (hljs.getLanguage(lang)) {
    try {
      return hljs.highlight(code, { language: lang, ignoreIllegals: true }).value
    } catch {
      // 语言存在但解析失败：按纯文本，不要猜
      return escapeHtml(code)
    }
  }

  // 不认识的语言一律纯文本（docs/v6/frontend/frontend.md 8.3）。
  // 以前这里回退到 highlightAuto，会把 ```dockerfile 之类猜成别的语言，
  // 表现为「有些语言能高亮、有些不能」且无法预期。
  return escapeHtml(code)
}

/** 转义 HTML，作为兜底。 */
export function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

/** 语言别名归一：`js` → `javascript`，用于展示与高亮（docs/v6/frontend/frontend.md 8.2）。 */
export function normalizeLanguage(language?: string | null): string {
  // 去掉反引号里的多余空白与大小写差异，全角字母也一并归一
  const lang = (language ?? '')
    .trim()
    .toLowerCase()
    .replace(/[\uFF41-\uFF5A]/g, (ch) => String.fromCharCode(ch.charCodeAt(0) - 0xfee0))

  const aliases: Record<string, string> = {
    // Web 脚本
    js: 'javascript',
    mjs: 'javascript',
    cjs: 'javascript',
    jsx: 'javascript',
    ts: 'typescript',
    tsx: 'typescript',
    mts: 'typescript',
    // Shell
    sh: 'bash',
    zsh: 'bash',
    ksh: 'bash',
    shell: 'bash',
    // Python / Go
    py: 'python',
    py3: 'python',
    golang: 'go',
    // C 系
    'c++': 'cpp',
    cc: 'cpp',
    hpp: 'cpp',
    cxx: 'cpp',
    'c#': 'csharp',
    cs: 'csharp',
    objc: 'objectivec',
    'objective-c': 'objectivec',
    rs: 'rust',
    // 标记与配置：highlight.js 里 HTML 与 XML 共用同一个语法 `xml`
    html: 'xml',
    htm: 'xml',
    xhtml: 'xml',
    svg: 'xml',
    yml: 'yaml',
    conf: 'ini',
    cfg: 'ini',
    properties: 'ini',
    // 容器 / 服务器
    docker: 'dockerfile',
    'docker-compose': 'yaml',
    compose: 'yaml',
    confd: 'nginx',
    caddy: 'caddyfile',
    'caddy-file': 'caddyfile',
    // 脚本与语言别名
    ps1: 'powershell',
    pwsh: 'powershell',
    hs: 'haskell',
    ex: 'elixir',
    exs: 'elixir',
    erl: 'erlang',
    clj: 'clojure',
    cljs: 'clojure',
    ml: 'ocaml',
    fs: 'fsharp',
    fsx: 'fsharp',
    jl: 'julia',
    tex: 'latex',
    proto: 'protobuf',
    gql: 'graphql',
    vh: 'verilog',
    sv: 'verilog',
    svh: 'verilog',
    cr: 'crystal',
    bzl: 'python',
    // 杂项
    md: 'markdown',
    text: 'plaintext',
    txt: 'plaintext',
  }

  return aliases[lang] ?? lang
}

/**
 * 代码块左上角标签怎么写。
 *
 * 与 `normalizeLanguage` 分开：`html` 在高亮时归一到 `xml`（highlight.js 里二者共用一个语法），
 * 但标签上应该显示用户自己写的 `html`，不能显示成 `xml`。
 */
export function displayLanguage(language?: string | null): string {
  const raw = (language ?? '').trim().toLowerCase()
  const canonical: Record<string, string> = {
    js: 'javascript',
    ts: 'typescript',
    py: 'python',
    sh: 'bash',
    zsh: 'bash',
    golang: 'go',
    yml: 'yaml',
    'c++': 'c++',
    'c#': 'c#',
    objc: 'objectivec',
    docker: 'dockerfile',
    ps1: 'powershell',
    pwsh: 'powershell',
    hs: 'haskell',
    ex: 'elixir',
    exs: 'elixir',
    erl: 'erlang',
    clj: 'clojure',
    cljs: 'clojure',
    ml: 'ocaml',
    fs: 'fsharp',
    jl: 'julia',
    tex: 'latex',
    proto: 'protobuf',
    gql: 'graphql',
  }
  return canonical[raw] ?? raw
}
