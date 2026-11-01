-- 0010_notes_title_trgm up
--
-- 依据 docs/v6/backend/data-model.md 第一节：
--   - 命令面板按标题搜索（type=title），需要 title 自身的 trigram 索引；
--   - search_text 的索引覆盖「标题 + 正文」，两者服务不同查询，并存。

CREATE INDEX idx_notes_title_trgm ON notes USING gin (title gin_trgm_ops);
