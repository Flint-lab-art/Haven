-- 0006_notes_recycle_bin down

DROP INDEX IF EXISTS idx_notes_deleted;

ALTER TABLE notes
    DROP COLUMN IF EXISTS deleted_at;
