/// <reference types="vite/client" />

interface ImportMetaEnv {
  /**
   * 私有域的主机名（如 app.example.com），可用逗号分隔多个。
   *
   * 仅作为兜底：优先使用后端 `GET /api/app-config` 下发的运行时配置，
   * 这样同一份构建产物换域名后不需要重新打包。见 src/config.ts。
   *
   * 未配置时：localhost / IP 视为私有域，其余视为公开域。
   * 见 src/router/domain.ts。
   */
  readonly VITE_PRIVATE_HOST?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
