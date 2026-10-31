-- 0008_portfolio_content down

ALTER TABLE portfolio_items
    DROP COLUMN IF EXISTS content;
