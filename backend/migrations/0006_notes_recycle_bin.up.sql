-- 0006_notes_recycle_bin up
--
-- 依据 docs/v2/backend/data-model.md 第一节：
--   - deleted_at 非 NULL 表示已移入回收站；
--   - 删除笔记改为只写该列，folder_id 保留即「原位置」；
--   - 原文件夹被删除时 notes.folder_id 由 ON DELETE SET NULL 置空，还原时归入收件箱。

ALTER TABLE notes
    ADD COLUMN deleted_at timestamptz NULL DEFAULT NULL;

-- 回收站列表：按删除时间倒序，只索引已删除的行
CREATE INDEX idx_notes_deleted ON notes (user_id, deleted_at DESC)
    WHERE deleted_at IS NOT NULL;
