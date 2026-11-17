-- 版本快照的合并窗口需要固定锚点，不能用会被刷新的 created_at（否则窗口无限滑动、历史版本永不归档）。
ALTER TABLE note_versions
    ADD COLUMN updated_at        timestamptz NULL,
    ADD COLUMN window_started_at timestamptz NULL;

-- 历史数据：以 created_at 作为窗口起点补齐
UPDATE note_versions SET updated_at = created_at, window_started_at = created_at;
