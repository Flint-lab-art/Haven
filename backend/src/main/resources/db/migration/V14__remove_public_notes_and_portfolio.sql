-- 删除公开站点与作品集：Haven 只保留登录后的私有工作台。
-- 作品集相关表整体移除；笔记不再有公开/私有一说。

DROP TABLE IF EXISTS portfolio_repos;
DROP TABLE IF EXISTS portfolio_items;

DROP INDEX IF EXISTS idx_notes_public;

ALTER TABLE notes DROP COLUMN IF EXISTS visibility;
ALTER TABLE notes DROP COLUMN IF EXISTS published_at;
