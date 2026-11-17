package com.haven.backend.issue.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 需求 / Bug 模块的响应契约。
 */
public final class IssueDtos {

    private IssueDtos() {}

    /** 状态流转事件。 */
    public record IssueStatusEvent(UUID id, String fromStatus, String toStatus, OffsetDateTime createdAt) {}

    /** 需求 / Bug。 */
    public record IssueResponse(
            UUID id,
            String title,
            String description,
            String type,
            String status,
            String priority,
            OffsetDateTime createdAt,
            OffsetDateTime updatedAt) {}

    /** 详情：附带状态流转历史。 */
    public record IssueDetail(IssueResponse issue, List<IssueStatusEvent> statusEvents) {}

    /** 分页列表。 */
    public record IssuePage(List<IssueResponse> items, long total) {}
}
