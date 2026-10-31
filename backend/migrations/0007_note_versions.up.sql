-- 0007_note_versions up
--
-- 依据 docs/v2/backend/data-model.md 第二节：
--   - 每次实质性编辑之前写入一条内容快照；
--   - tag_ids 用 uuid[] 存，不另建关联表；
--   - 笔记被永久删除时快照级联清理。

CREATE TABLE note_versions (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id    uuid        NOT NULL REFERENCES notes (id) ON DELETE CASCADE,
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title      text        NOT NULL,
    content    text        NOT NULL DEFAULT '',
    folder_id  uuid        NULL,
    tag_ids    uuid[]      NOT NULL DEFAULT '{}',
    created_at timestamptz NOT NULL DEFAULT now()
);

-- 时间线：按笔记取最近的若干条
CREATE INDEX idx_note_versions_note ON note_versions (note_id, created_at DESC);
