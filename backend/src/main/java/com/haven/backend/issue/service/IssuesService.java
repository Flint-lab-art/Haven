package com.haven.backend.issue.service;

import java.util.Map;
import java.util.UUID;

public interface IssuesService {
    Map<String, Object> listIssues(String userId, String status, int limit, int offset);
    Map<String, Object> getIssue(String userId, UUID issueId);
    Map<String, Object> createIssue(String userId, String title, String description, String type, String status, String priority);
    Map<String, Object> updateIssue(String userId, UUID issueId, String title, String description, String type, String status, String priority);
    void deleteIssue(String userId, UUID issueId);
}
