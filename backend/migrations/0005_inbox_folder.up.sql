-- 0005_inbox_folder up
--
-- 依据 docs/backend/data-model.md 第七点五节：
--   - 每个用户有且只有一个 is_inbox = true 的文件夹；
--   - 收件箱固定在根目录，不可删除、不可移动；
--   - 现有 folder_id = NULL 的笔记迁入收件箱。

ALTER TABLE folders
    ADD COLUMN is_inbox boolean NOT NULL DEFAULT false;

CREATE UNIQUE INDEX idx_folders_inbox ON folders (user_id) WHERE is_inbox;

-- 优先复用根目录已有的“收件箱”，避免迁移后出现两个同名节点。
WITH candidates AS (
    SELECT DISTINCT ON (user_id) id
    FROM folders
    WHERE parent_id IS NULL AND name = '收件箱'
    ORDER BY user_id, created_at, id
)
UPDATE folders f
SET is_inbox = true
FROM candidates c
WHERE f.id = c.id;

-- 没有收件箱的用户补一个。
INSERT INTO folders (user_id, parent_id, name, sort_order, is_inbox)
SELECT u.id, NULL, '收件箱', 0, true
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM folders f WHERE f.user_id = u.id AND f.is_inbox
);

-- 历史未归类笔记归入收件箱。
UPDATE notes n
SET folder_id = f.id
FROM folders f
WHERE f.user_id = n.user_id
  AND f.is_inbox
  AND n.folder_id IS NULL;
