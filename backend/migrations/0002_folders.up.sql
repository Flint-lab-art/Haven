-- 0002_folders up
--
-- 依据 docs/backend/data-model.md 第三、七点五节：
--   - folders 通过 parent_id 自引用实现无限嵌套，删除父级时子级级联删除；
--   - notes.folder_id 指向 folders，删除文件夹时笔记回到未分类（SET NULL），绝不级联删除笔记。
-- 同父目录下文件夹重名由应用层校验，数据库不建唯一索引。

CREATE TABLE folders (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    parent_id  uuid        NULL REFERENCES folders (id) ON DELETE CASCADE,
    name       text        NOT NULL,
    sort_order int         NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_folders_user_parent ON folders (user_id, parent_id);

ALTER TABLE notes
    ADD COLUMN folder_id uuid NULL REFERENCES folders (id) ON DELETE SET NULL;
