package com.haven.backend.portfolio.dto;

import jakarta.validation.constraints.Size;

/**
 * 更新作品请求（PATCH /api/portfolio/{id}）；字段为 {@code null} 表示不修改。
 */
public record UpdatePortfolioItemRequest(
        @Size(max = 200, message = "标题不能超过 200 个字符") String title,
        @Size(max = 500, message = "简介不能超过 500 个字符") String description,
        String content,
        Integer sortOrder,
        Boolean isPublic) {}
