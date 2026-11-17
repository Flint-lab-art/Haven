package com.haven.backend.portfolio.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 新增作品链接请求（POST /api/portfolio/{id}/repos）。
 */
public record AddRepoRequest(
        @NotBlank(message = "链接地址不能为空") @Size(max = 2048, message = "链接过长")
        String url,

        @Size(max = 200, message = "链接标题过长") String title,
        Boolean isPrimary) {}
