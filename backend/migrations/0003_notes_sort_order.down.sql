-- 0003_notes_sort_order down

DROP INDEX IF EXISTS idx_notes_folder_sort;

ALTER TABLE notes
    DROP COLUMN IF EXISTS sort_order;
