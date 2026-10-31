-- 0009_portfolio_repos_url up
--
-- 依据 docs/v3/backend/data-model.md 第二节：
--   - 仓库链接直接存完整 URL，不再由后端按 platform 拼接；
--   - 新增 title：非仓库链接在公开页展示标题，不展示 URL；
--   - 删除 platform：公开页按域名自行判断显示 GitHub / Gogs 图标。
--
-- 历史数据迁移：用旧规则（HAVEN_GOGS_BASE_URL / github.com）拼出完整地址；
-- gogs 的 base URL 在 SQL 里拿不到，因此 gogs 类型的旧行只保留 repo_path，
-- 由部署脚本按需要手工修正（本库目前没有该类数据）。

ALTER TABLE portfolio_repos
    ADD COLUMN url   text NOT NULL DEFAULT '',
    ADD COLUMN title text NOT NULL DEFAULT '';

-- github 类型可以直接拼出完整地址
UPDATE portfolio_repos
SET url = 'https://github.com/' || trim(both '/' from repo_path)
WHERE platform = 'github' AND url = '';

-- 其余（gogs）先保留相对路径，部署后按实际域名修正
UPDATE portfolio_repos
SET url = trim(both '/' from repo_path)
WHERE url = '';

-- 同一作品下 URL 不再重复
DROP INDEX IF EXISTS idx_portfolio_repos_unique;
CREATE UNIQUE INDEX idx_portfolio_repos_unique ON portfolio_repos (portfolio_item_id, url);

ALTER TABLE portfolio_repos
    DROP COLUMN IF EXISTS platform,
    DROP COLUMN IF EXISTS repo_path;
