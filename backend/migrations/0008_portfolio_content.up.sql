-- 0008_portfolio_content up
--
-- 依据 docs/v3/api.md 第二节：
--   - 作品集条目新增正文（Markdown 源文本），用于公开详情页介绍这个作品是做什么的；
--   - 默认空串，与 notes.content 一致，应用层只读不写生成列（本表无生成列）。

ALTER TABLE portfolio_items
    ADD COLUMN content text NOT NULL DEFAULT '';
