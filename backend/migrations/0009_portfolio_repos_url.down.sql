-- 0009_portfolio_repos_url down

ALTER TABLE portfolio_repos
    ADD COLUMN platform  text NOT NULL DEFAULT 'github',
    ADD COLUMN repo_path text NOT NULL DEFAULT '';

-- 尽力还原：github.com 的链接拆回 repo_path，其余按原样保存
UPDATE portfolio_repos
SET repo_path = CASE
        WHEN url LIKE 'https://github.com/%' THEN substring(url FROM 'https://github\.com/(.*)')
        ELSE url
    END,
    platform = CASE
        WHEN url LIKE 'https://github.com/%' THEN 'github'
        ELSE 'gogs'
    END;

DROP INDEX IF EXISTS idx_portfolio_repos_unique;
CREATE UNIQUE INDEX idx_portfolio_repos_unique ON portfolio_repos (portfolio_item_id, platform, repo_path);

ALTER TABLE portfolio_repos
    DROP COLUMN IF EXISTS url,
    DROP COLUMN IF EXISTS title;
