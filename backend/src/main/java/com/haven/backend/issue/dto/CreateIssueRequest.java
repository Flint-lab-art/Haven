package com.haven.backend.issue.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * 创建需求 / Bug 请求（POST /api/issues）。
 * <p>
 * type / status / priority 与数据库 CHECK 约束保持一致，非法值在 DTO 层就被拒绝。
 */
public record CreateIssueRequest(
        @NotBlank(message = "标题不能为空") @Size(max = 200, message = "标题不能超过 200 个字符")
        String title,

        String description,

        @Pattern(regexp = "bug|feature", message = "type 只能是 bug 或 feature")
        String type,

        @Pattern(regexp = "todo|in_progress|done", message = "status 只能是 todo / in_progress / done")
        String status,

        @Pattern(regexp = "low|medium|high", message = "priority 只能是 low / medium / high")
        String priority) {}
