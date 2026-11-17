package com.haven.backend.issue.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * 更新需求 / Bug 请求（PATCH /api/issues/{id}）；字段为 {@code null} 表示不修改。
 */
public record UpdateIssueRequest(
        @Size(min = 1, max = 200, message = "标题长度必须在 1-200 之间")
        String title,

        String description,

        @Pattern(regexp = "bug|feature", message = "type 只能是 bug 或 feature")
        String type,

        @Pattern(regexp = "todo|in_progress|done", message = "status 只能是 todo / in_progress / done")
        String status,

        @Pattern(regexp = "low|medium|high", message = "priority 只能是 low / medium / high")
        String priority) {}
