# conventions — 四期约定与禁令变更

> 本文件回答：四期相对前几期约定做了哪些补充，以及哪些规则被放宽、哪些仍是硬约束。
> 依赖：`../v1/conventions.md`、`../v3/conventions.md`

覆盖规则见 `../README.md` 第二节。v1 第一至三、五节与 v3 第一节继续有效，本文件只写四期新增与变更。

## 一、四期约定补充

1. **图片存磁盘，数据库只存路径。** 图片文件**不是真值源**，真值源仍是 PostgreSQL 里的 URL 字符串。
2. **上传目录由 `HAVEN_UPLOAD_DIR` 指定**，默认 `./uploads`（相对后端工作目录）。生产建议 `/opt/haven/uploads`。
3. **文件名由服务端生成**，格式 `<日期目录>/<随机串>.<扩展名>`，不接受客户端提供的文件名，避免路径穿越。
4. **正文只存相对 URL**（`/uploads/...`），不存绝对域名，换域名不需要迁移数据。
5. **孤儿文件不自动删除**。删除笔记或文件夹时，磁盘上的图片保留；宁可占空间，也不能误删仍在引用的图片。
6. **上传大小上限 10 MiB**、**单个请求只接受一个文件**，都是代码常量。

## 二、禁令变更

### 2.1 放宽的约束

| v1 条目 | 四期处理 |
|---|---|
| `folders.icon` 只存「Emoji 或图标名」 | **改为可以存图片路径**：以 `/` 开头视为图片路径，否则仍按 emoji 渲染（向后兼容，无需迁移） |
| 编辑器粘贴图片以内嵌 base64 保存 | **改为上传后插入 URL**；正文里不再出现 `data:image/` |

### 2.2 仍然有效的禁令

- 不引入 PostgreSQL 之外的**真值源**：图片是附属资源，URL 才是真值；
- **不引入对象存储 / CDN**（S3、MinIO 等），只写本地磁盘；
- **不接受上传 SVG**：SVG 可以带脚本，静态托管同一域名下有 XSS 风险。图标库内联的 SVG 是构建期产物，不受此限；
- 不提供图片裁剪、压缩、多尺寸生成；
- 不接受图片以外的附件（PDF、压缩包等）。

## 三、部署约束（必须同步修改）

生产用 systemd 运行，`deploy/haven.service` 里有：

```
ProtectSystem=strict
ProtectHome=true
```

这两项会让**除显式声明外的整个文件系统只读**。因此：

1. `deploy/haven.service` 必须增加：

   ```
   ReadWritePaths=/opt/haven/uploads
   ```

2. `deploy/deploy.sh` 必须创建该目录并设置属主：

   ```
   install -d -o haven -g haven -m 0755 /opt/haven/uploads
   ```

3. `deploy/haven.env.example` 增加：

   ```
   HAVEN_UPLOAD_DIR=/opt/haven/uploads
   ```

**漏掉任何一条，上传都会因 `permission denied` 失败。**

## 四、文档归属

| 文件 | 归属 |
|---|---|
| `v4/changes.md` | 项目级 → v4 根 |
| `v4/conventions.md` | 项目级 → v4 根 |
| `v4/api.md` | 前后端共享 |
| `v4/backend/data-model.md` | 只约束后端 |
| `v4/frontend/frontend.md` | 只约束前端 |
