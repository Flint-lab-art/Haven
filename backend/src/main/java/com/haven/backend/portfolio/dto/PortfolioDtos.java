package com.haven.backend.portfolio.dto;

import java.util.List;
import java.util.UUID;

/**
 * 作品集模块的响应契约，与前端 {@code frontend/src/api/portfolio.ts} 字段保持一致。
 */
public final class PortfolioDtos {

    private PortfolioDtos() {}

    /** 作品链接。 */
    public record PortfolioRepoResponse(UUID id, String url, String title, String kind, boolean isPrimary) {}

    /** 作品列表项（不含正文）。 */
    public record PortfolioItemSummary(
            UUID id,
            String title,
            String description,
            int sortOrder,
            boolean isPublic,
            List<PortfolioRepoResponse> repos) {}

    /** 作品详情（含正文）。 */
    public record PortfolioItemDetail(
            UUID id,
            String title,
            String description,
            String content,
            int sortOrder,
            boolean isPublic,
            List<PortfolioRepoResponse> repos) {}

    /** 作品列表。 */
    public record PortfolioList(List<PortfolioItemSummary> items, long total) {}
}
