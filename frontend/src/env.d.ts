/// <reference types="vite/client" />

interface ImportMetaEnv {
  /**
   * 私有域的主机名（如 app.example.com）。
   * 未设置时：localhost / IP 视为私有域，其余视为公开域。
   * 见 src/router/domain.ts。
   */
  readonly VITE_PRIVATE_HOST?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

/** 由 vite.config.ts 从 package.json 注入的发布版本。 */
declare const __APP_VERSION__: string
