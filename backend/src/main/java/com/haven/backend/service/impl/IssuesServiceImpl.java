package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.entity.IssueStatusEvents;
import com.haven.backend.entity.Issues;
import com.haven.backend.exception.BizException;
import com.haven.backend.mapper.IssueStatusEventsMapper;
import com.haven.backend.mapper.IssuesMapper;
import com.haven.backend.service.IssuesService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class IssuesServiceImpl implements IssuesService {

    private final IssuesMapper issuesMapper;
    private final IssueStatusEventsMapper eventsMapper;

    @Override
    public Map<String, Object> listIssues(String userId, String status, int limit, int offset) {
        UUID uid = UUID.fromString(userId);
        int lim = Math.min(limit, 100);
        
        // 构建基础查询条件（不含 ORDER BY）
        var baseWrapper = new LambdaQueryWrapper<Issues>().eq(Issues::getUserId, uid);
        if (status != null && !status.isBlank()) baseWrapper.eq(Issues::getStatus, status);
        
        // 先查总数
        long total = issuesMapper.selectCount(baseWrapper);
        
        // 再查列表（带 ORDER BY 和分页）
        var listWrapper = new LambdaQueryWrapper<Issues>().eq(Issues::getUserId, uid);
        if (status != null && !status.isBlank()) listWrapper.eq(Issues::getStatus, status);
        listWrapper.orderByDesc(Issues::getUpdatedAt).last("LIMIT " + lim + " OFFSET " + offset);
        List<Issues> issues = issuesMapper.selectList(listWrapper);
        
        List<Map<String, Object>> items = issues.stream().map(this::toIssueMap).toList();
        return Map.of("items", items, "total", total);
    }

    @Override
    public Map<String, Object> getIssue(String userId, UUID issueId) {
        UUID uid = UUID.fromString(userId);
        Issues issue = getOwned(uid, issueId);
        Map<String, Object> m = toIssueMap(issue);

        // status events
        List<IssueStatusEvents> events = eventsMapper.selectList(
                new LambdaQueryWrapper<IssueStatusEvents>()
                        .eq(IssueStatusEvents::getIssueId, issueId).orderByAsc(IssueStatusEvents::getCreatedAt));
        m.put("status_events", events.stream().map(e -> {
            Map<String, Object> em = new LinkedHashMap<>();
            em.put("id", e.getId().toString());
            em.put("from_status", e.getFromStatus());
            em.put("to_status", e.getToStatus());
            em.put("created_at", e.getCreatedAt());
            return em;
        }).collect(Collectors.toList()));
        return m;
    }

    @Override
    @Transactional
    public Map<String, Object> createIssue(String userId, String title, String description,
                                           String type, String status, String priority) {
        UUID uid = UUID.fromString(userId);
        if (title == null || title.trim().isEmpty()) throw BizException.validation("标题不能为空");
        String t = type != null ? type : "feature";
        String s = status != null ? status : "todo";
        String p = priority != null ? priority : "medium";

        Issues issue = new Issues();
        issue.setId(UUID.randomUUID());
        issue.setUserId(uid);
        issue.setTitle(title.trim());
        issue.setDescription(description != null ? description : "");
        issue.setType(t);
        issue.setStatus(s);
        issue.setPriority(p);
        issue.setCreatedAt(OffsetDateTime.now());
        issue.setUpdatedAt(OffsetDateTime.now());
        issuesMapper.insert(issue);

        // 初始状态事件
        IssueStatusEvents event = new IssueStatusEvents();
        event.setId(UUID.randomUUID());
        event.setIssueId(issue.getId());
        event.setUserId(uid);
        event.setFromStatus(null);
        event.setToStatus(s);
        event.setCreatedAt(OffsetDateTime.now());
        eventsMapper.insert(event);

        return toIssueMap(issue);
    }

    @Override
    @Transactional
    public Map<String, Object> updateIssue(String userId, UUID issueId, String title, String description,
                                           String type, String status, String priority) {
        UUID uid = UUID.fromString(userId);
        Issues issue = getOwned(uid, issueId);
        String oldStatus = issue.getStatus();

        if (title != null) issue.setTitle(title.trim());
        if (description != null) issue.setDescription(description);
        if (type != null) issue.setType(type);
        if (priority != null) issue.setPriority(priority);

        if (status != null && !status.equals(oldStatus)) {
            issue.setStatus(status);
            IssueStatusEvents event = new IssueStatusEvents();
            event.setId(UUID.randomUUID());
            event.setIssueId(issue.getId());
            event.setUserId(uid);
            event.setFromStatus(oldStatus);
            event.setToStatus(status);
            event.setCreatedAt(OffsetDateTime.now());
            eventsMapper.insert(event);
        }
        issue.setUpdatedAt(OffsetDateTime.now());
        issuesMapper.updateById(issue);
        return toIssueMap(issue);
    }

    @Override
    @Transactional
    public void deleteIssue(String userId, UUID issueId) {
        UUID uid = UUID.fromString(userId);
        getOwned(uid, issueId);
        eventsMapper.delete(new LambdaQueryWrapper<IssueStatusEvents>().eq(IssueStatusEvents::getIssueId, issueId));
        issuesMapper.deleteById(issueId);
    }

    // ---- 内部 ----

    private Issues getOwned(UUID userId, UUID issueId) {
        Issues issue = issuesMapper.selectById(issueId);
        if (issue == null || !issue.getUserId().equals(userId)) throw BizException.notFound("需求不存在");
        return issue;
    }

    private Map<String, Object> toIssueMap(Issues i) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", i.getId().toString());
        m.put("title", i.getTitle());
        m.put("description", i.getDescription());
        m.put("type", i.getType());
        m.put("status", i.getStatus());
        m.put("priority", i.getPriority());
        m.put("created_at", i.getCreatedAt());
        m.put("updated_at", i.getUpdatedAt());
        return m;
    }
}
