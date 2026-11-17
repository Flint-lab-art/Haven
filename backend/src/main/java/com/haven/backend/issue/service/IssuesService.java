package com.haven.backend.issue.service;

import com.haven.backend.issue.dto.CreateIssueRequest;
import com.haven.backend.issue.dto.IssueDtos.IssueDetail;
import com.haven.backend.issue.dto.IssueDtos.IssuePage;
import com.haven.backend.issue.dto.IssueDtos.IssueResponse;
import com.haven.backend.issue.dto.UpdateIssueRequest;
import java.util.UUID;

/**
 * 需求 / Bug 服务。
 */
public interface IssuesService {

    IssuePage listIssues(String userId, String status, int limit, int offset);

    IssueDetail getIssue(String userId, UUID issueId);

    IssueResponse createIssue(String userId, CreateIssueRequest req);

    IssueResponse updateIssue(String userId, UUID issueId, UpdateIssueRequest req);

    void deleteIssue(String userId, UUID issueId);
}
