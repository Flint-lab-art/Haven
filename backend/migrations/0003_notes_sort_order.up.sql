-- 0003_notes_sort_order up
--
-- 依据 docs/backend/data-model.md 第三节：
--   - notes.sort_order 只在同一文件夹内生效，小的在前；
--   - 列表按 sort_order ASC, updated_at DESC 排序；
--   - 仅调整 sort_order 时不更新 updated_at。

ALTER TABLE notes
    ADD COLUMN sort_order int NOT NULL DEFAULT 0;

CREATE INDEX idx_notes_folder_sort ON notes (user_id, folder_id, sort_order);
