package com.haven.backend.portfolio.dto;

import jakarta.validation.constraints.Size;

/**
 * 更新作品链接请求（PATCH /api/portfolio/{id}/repos/{repoId}）。
 */
public record UpdateRepoRequest(
        @Size(max = 2048, message = "链接过长") String url,
        @Size(max = 200, message = "链接标题过长") String title,
        Boolean isPrimary) {}
