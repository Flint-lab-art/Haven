/**
 * Caddyfile 语法高亮（highlight.js 自定义语言）。
 *
 * highlight.js 11.x 不带 Caddyfile 语言包，Caddy 在 nginx / apache 之外没有现成方案，
 * 所以这里按官方语法规范（https://caddyserver.com/docs/caddyfile/concepts）写一个最小实现：
 * 注释、花括号块、每行首词（站点地址 / 指令）、环境变量、运行时占位符、字符串、字面量、端口。
 *
 * 只做「看得清结构」，不做完整语义解析——Caddyfile 的指令名是开放的（插件可注册新指令），
 * 硬编码指令列表反而会漏。
 */
import type { Language } from 'highlight.js'

export default function caddyfile(): Language {
  return {
    name: 'Caddyfile',
    aliases: ['caddy'],
    contains: [
      // # 注释：必须行首或前面是空白（URI 里的 # 不算注释）
      {
        className: 'comment',
        begin: /(^|[\s])#/,
        end: /$/,
        relevance: 0,
      },
      // 引号 / 反引号字符串
      {
        className: 'string',
        begin: /"/,
        end: /"/,
        contains: [{ begin: /\\"/ }],
      },
      {
        className: 'string',
        begin: /`/,
        end: /`/,
      },
      // Caddyfile 环境变量：{$ENV} 或 {$ENV:默认值}
      {
        className: 'variable',
        begin: /\{\$[A-Za-z_]\w*/,
        end: /\}/,
      },
      // 运行时占位符：{host} {env.X} {args[0]} {http.request.uri.path}
      {
        className: 'template-variable',
        begin: /\{[A-Za-z_][\w.[\]]*(?::[^}\s]*)?\}/,
      },
      // 每行第一个词：站点地址或指令（不含行尾的逗号分隔符）
      {
        className: 'keyword',
        begin: /^[\t ]*(?!(?:\{|\}))[^\s{#},]+/,
        relevance: 0,
      },
      // 同一行里追加的站点地址，如 `a.com, b.com {`：
      // 只在后面紧跟（可选逗号后）行尾花括号、且看起来是域名时才算地址，
      // 避免把 `reverse_proxy localhost:8080 {` 这类参数也标成地址
      {
        className: 'keyword',
        begin: /[\t ]+(?=[a-z0-9*][\w.*-]*(?::\d+)?[,]?[\t ]*\{[\t ]*$)(?=[\w.*-]*[.*])[a-z0-9*][\w.*-]*(?::\d+)?/,
        relevance: 0,
      },
      // 指令块或地址块的花括号
      {
        className: 'punctuation',
        begin: /\{/,
        relevance: 0,
      },
      {
        className: 'punctuation',
        begin: /\}/,
        relevance: 0,
      },
      // 行内参数里的字面量
      {
        className: 'literal',
        begin: /\b(?:true|false|on|off)\b/,
        relevance: 0,
      },
      // 端口号 / 状态码等数字
      {
        className: 'number',
        begin: /\b\d{2,5}\b/,
        relevance: 0,
      },
    ],
  }
}
