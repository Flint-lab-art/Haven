-- 0005_inbox_folder down
--
-- 先把收件箱里的笔记回落到 NULL，再移除 is_inbox 标记。
-- 收件箱文件夹本身保留为普通文件夹。

UPDATE notes n
SET folder_id = NULL
FROM folders f
WHERE f.user_id = n.user_id
  AND f.is_inbox
  AND n.folder_id = f.id;

DROP INDEX IF EXISTS idx_folders_inbox;

ALTER TABLE folders
    DROP COLUMN IF EXISTS is_inbox;
