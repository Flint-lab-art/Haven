-- 0002_folders down
--
-- 与 up 对称：先解除 notes 的外键列，再删除 folders。

ALTER TABLE notes DROP COLUMN IF EXISTS folder_id;

DROP TABLE IF EXISTS folders;
