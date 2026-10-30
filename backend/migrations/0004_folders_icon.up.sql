-- 0004_folders_icon up
--
-- 依据 docs/backend/data-model.md 第七点五节：
--   - icon 为可空文本，存单个 Emoji；
--   - NULL 表示使用前端默认文件夹图标。

ALTER TABLE folders
    ADD COLUMN icon text NULL;
