# changes — 第四期变更清单

> 本文件回答：v1/v2/v3 的哪些文件/节在第四期被改动或作废、由 v4 的哪个文件哪一节接管。
> 依赖：`../README.md`（覆盖规则）

本文件是 v4 的**入口**。规则见 `../README.md` 第二节：

> v4 中出现的节覆盖早期版本同名节；未被 v4 提及的内容继续有效。

## 一、四期范围

**主题：图片上传。**

编辑器现在粘贴图片会以 base64 内嵌进 Markdown 正文，一张截图就能让 `notes.content` 膨胀到几百 KB，同时污染 `search_text` 生成列与 trigram 索引。本期把图片改为上传到磁盘、正文只存 URL。

| 序 | 功能 | 说明 |
|---|---|---|
| **U1** | 上传基础设施 | `POST /api/uploads`、`/uploads/*` 静态托管、`HAVEN_UPLOAD_DIR` |
| **U2** | 笔记插图 | 编辑器粘贴图片走上传，正文插入 `![](url)`，不再内嵌 base64 |
| **U3** | 文件夹图标 | 上传图片作为文件夹图标，与现有 emoji 并存 |
| **U4** | 图标库 | 编程语言 / 工具 logo 的内联选择（可选，最后做） |

开发顺序：**U1 → U2 → U3 → U4**。U2 依赖 U1 的上传接口，U3 复用同一套。

不纳入四期：孤儿文件自动清理、SVG 上传、图片裁剪与压缩、附件（非图片文件）。

## 二、登记格式

| # | 文件 / 节 | 变更类型 | 变更说明 | v4 落点 |
|---|---|---|---|---|

- **变更类型**：`扩展`（原内容仍成立）/ `替换`（原结论被改掉）/ `作废`（整节不再适用）/ `解除禁令` / `新增`（原版本无对应节）。
- **v4 落点**：接管该节的 `文件#节`；无替代内容填 `—`。

## 三、清单

| # | 文件 / 节 | 变更类型 | 变更说明 | v4 落点 |
|---|---|---|---|---|
| 1 | `v1/architecture.md` 第四节「配置项清单」 | 扩展 | 新增 `HAVEN_UPLOAD_DIR`（可选，默认 `./uploads`） | `v4/api.md` 第一节 |
| 2 | `v1/architecture.md` 第七节「静态文件托管」 | 扩展 | 新增 `/uploads/*` 静态托管，与前端 `/assets` 并列 | `v4/api.md` 第二节 |
| 3 | `v1/api.md`（无对应章节） | 新增 | `POST /api/uploads` 上传图片 | `v4/api.md` 第三节 |
| 4 | `v1/backend/data-model.md` 第九节「folders」的 `icon` | 扩展 | `icon` 可以存图片路径（`/uploads/...`），不再只限 emoji 或图标名 | `v4/backend/data-model.md` 第一节 |
| 5 | `v1/frontend/ui-design.md` 第九节「文件夹图标面板」 | 扩展 | 图标面板增加「上传图片」入口，与内置 emoji 并列 | `v4/frontend/frontend.md` 第三节 |
| 6 | `v1/frontend/ui-design.md` 第七节「编辑器」 | 扩展 | 粘贴图片改为上传并插入 URL | `v4/frontend/frontend.md` 第二节 |
| 7 | `v1/conventions.md` 第四节「架构与部署」 | 扩展 | 明确「图片存磁盘、数据库只存路径」；文件不是真值源 | `v4/conventions.md` 第二节 |
| 8 | `deploy/haven.service` | 扩展 | 增加 `ReadWritePaths`，否则 `ProtectSystem=strict` 下无法写上传目录 | `v4/conventions.md` 第三节 |
| 9 | `deploy/deploy.sh` | 扩展 | 创建上传目录并设置属主 | `v4/conventions.md` 第三节 |

## 四、旧版本表述的时效说明

- v1 `architecture.md` 第七节的静态托管只覆盖前端构建产物，本期新增 `/uploads/*`，该节由 `v4/api.md` 第二节接管扩展部分。
- 本期**不解除**任何 v1 第四节禁令：图片不是真值源，数据库里的 URL 才是。
