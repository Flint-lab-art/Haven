package com.haven.backend.issue.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.exception.BizException;
import com.haven.backend.issue.dto.CreateIssueRequest;
import com.haven.backend.issue.dto.IssueDtos.IssueDetail;
import com.haven.backend.issue.dto.IssueDtos.IssuePage;
import com.haven.backend.issue.dto.IssueDtos.IssueResponse;
import com.haven.backend.issue.dto.IssueDtos.IssueStatusEvent;
import com.haven.backend.issue.dto.UpdateIssueRequest;
import com.haven.backend.issue.entity.IssueEnums;
import com.haven.backend.issue.entity.IssueStatusEvents;
import com.haven.backend.issue.entity.Issues;
import com.haven.backend.issue.mapper.IssueStatusEventsMapper;
import com.haven.backend.issue.mapper.IssuesMapper;
import com.haven.backend.issue.service.IssuesService;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class IssuesServiceImpl implements IssuesService {

    private final IssuesMapper issuesMapper;
    private final Clock clock;
    private final IssueStatusEventsMapper eventsMapper;

    @Override
    public IssuePage listIssues(String userId, String status, int limit, int offset) {
        UUID uid = UUID.fromString(userId);
        int lim = Math.clamp(limit, 1, 100);
        int off = Math.max(offset, 0);

        // 构建基础查询条件（不含 ORDER BY）
        var baseWrapper = new LambdaQueryWrapper<Issues>().eq(Issues::getUserId, uid);
        if (status != null && !status.isBlank()) {
            baseWrapper.eq(Issues::getStatus, status);
        }

        // 先查总数
        long total = issuesMapper.selectCount(baseWrapper);

        // 再查列表（带 ORDER BY 和分页）
        var listWrapper = new LambdaQueryWrapper<Issues>().eq(Issues::getUserId, uid);
        if (status != null && !status.isBlank()) {
            listWrapper.eq(Issues::getStatus, status);
        }
        listWrapper.orderByDesc(Issues::getUpdatedAt).last("LIMIT " + lim + " OFFSET " + off);
        List<Issues> issues = issuesMapper.selectList(listWrapper);

        List<IssueResponse> items = issues.stream().map(this::toResponse).toList();
        return new IssuePage(items, total);
    }

    @Override
    public IssueDetail getIssue(String userId, UUID issueId) {
        UUID uid = UUID.fromString(userId);
        Issues issue = getOwned(uid, issueId);
        List<IssueStatusEvents> events = eventsMapper.selectList(new LambdaQueryWrapper<IssueStatusEvents>()
                .eq(IssueStatusEvents::getIssueId, issueId)
                .orderByAsc(IssueStatusEvents::getCreatedAt));
        List<IssueStatusEvent> eventDtos = events.stream()
                .map(e -> new IssueStatusEvent(e.getId(), e.getFromStatus(), e.getToStatus(), e.getCreatedAt()))
                .toList();
        return new IssueDetail(toResponse(issue), eventDtos);
    }

    @Override
    @Transactional
    public IssueResponse createIssue(String userId, CreateIssueRequest req) {
        UUID uid = UUID.fromString(userId);
        String title = req.title();
        String description = req.description();
        String type = req.type();
        String status = req.status();
        String priority = req.priority();
        String t = type != null ? type : IssueEnums.Type.FEATURE;
        String s = status != null ? status : IssueEnums.Status.TODO;
        String p = priority != null ? priority : IssueEnums.Priority.MEDIUM;

        Issues issue = new Issues();
        issue.setId(UUID.randomUUID());
        issue.setUserId(uid);
        issue.setTitle(title.trim());
        issue.setDescription(description != null ? description : "");
        issue.setType(t);
        issue.setStatus(s);
        issue.setPriority(p);
        issue.setCreatedAt(OffsetDateTime.now(clock));
        issue.setUpdatedAt(OffsetDateTime.now(clock));
        issuesMapper.insert(issue);

        // 初始状态事件
        IssueStatusEvents event = new IssueStatusEvents();
        event.setId(UUID.randomUUID());
        event.setIssueId(issue.getId());
        event.setUserId(uid);
        event.setFromStatus(null);
        event.setToStatus(s);
        event.setCreatedAt(OffsetDateTime.now(clock));
        eventsMapper.insert(event);

        return toResponse(issue);
    }

    @Override
    @Transactional
    public IssueResponse updateIssue(String userId, UUID issueId, UpdateIssueRequest req) {
        UUID uid = UUID.fromString(userId);
        String title = req.title();
        String description = req.description();
        String type = req.type();
        String status = req.status();
        String priority = req.priority();
        Issues issue = getOwned(uid, issueId);
        String oldStatus = issue.getStatus();

        if (title != null) {
            issue.setTitle(title.trim());
        }
        if (description != null) {
            issue.setDescription(description);
        }
        if (type != null) {
            issue.setType(type);
        }
        if (priority != null) {
            issue.setPriority(priority);
        }

        if (status != null && !status.equals(oldStatus)) {
            issue.setStatus(status);
            IssueStatusEvents event = new IssueStatusEvents();
            event.setId(UUID.randomUUID());
            event.setIssueId(issue.getId());
            event.setUserId(uid);
            event.setFromStatus(oldStatus);
            event.setToStatus(status);
            event.setCreatedAt(OffsetDateTime.now(clock));
            eventsMapper.insert(event);
        }
        issue.setUpdatedAt(OffsetDateTime.now(clock));
        issuesMapper.updateById(issue);
        return toResponse(issue);
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
        if (issue == null || !issue.getUserId().equals(userId)) {
            throw BizException.notFound("需求不存在");
        }
        return issue;
    }

    private IssueResponse toResponse(Issues i) {
        return new IssueResponse(
                i.getId(),
                i.getTitle(),
                i.getDescription(),
                i.getType(),
                i.getStatus(),
                i.getPriority(),
                i.getCreatedAt(),
                i.getUpdatedAt());
    }
}
