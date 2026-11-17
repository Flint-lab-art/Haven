-- 匿名作品集接口只能返回显式公开的作品。
-- 默认 false：保持现有数据不外泄，作者需主动公开。
ALTER TABLE portfolio_items
    ADD COLUMN is_public boolean NOT NULL DEFAULT false;

-- 支持公开列表按 sort_order 过滤排序
CREATE INDEX idx_portfolio_items_public_sort ON portfolio_items (is_public, sort_order) WHERE is_public;
