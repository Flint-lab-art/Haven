package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.entity.Folders;
import com.haven.backend.entity.Issues;
import com.haven.backend.entity.Notes;
import com.haven.backend.mapper.FoldersMapper;
import com.haven.backend.mapper.IssuesMapper;
import com.haven.backend.mapper.NotesMapper;
import com.haven.backend.service.StatsService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StatsServiceImpl implements StatsService {

    private final NotesMapper notesMapper;
    private final FoldersMapper foldersMapper;
    private final IssuesMapper issuesMapper;

    @Override
    public Map<String, Object> getStats(String userId) {
        UUID uid = UUID.fromString(userId);
        OffsetDateTime now = OffsetDateTime.now();
        OffsetDateTime weekAgo = now.minusDays(7);

        // totals
        var activeNotes = new LambdaQueryWrapper<Notes>()
                .eq(Notes::getUserId, uid).isNull(Notes::getDeletedAt);
        long totalNotes = notesMapper.selectCount(activeNotes);

        List<Notes> allActive = notesMapper.selectList(
                new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid).isNull(Notes::getDeletedAt));
        long totalWords = allActive.stream()
                .mapToLong(n -> {
                    String c = n.getContent() != null ? n.getContent().replaceAll("<[^>]*>", "") : "";
                    return c.length();
                }).sum();
        long publicNotes = notesMapper.selectCount(
                new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid)
                        .eq(Notes::getVisibility, "public").isNotNull(Notes::getPublishedAt).isNull(Notes::getDeletedAt));

        Map<String, Object> totals = Map.of("notes", totalNotes, "words", totalWords, "public_notes", publicNotes);

        // week
        long createdWeek = notesMapper.selectCount(
                new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid)
                        .ge(Notes::getCreatedAt, weekAgo).isNull(Notes::getDeletedAt));
        long updatedWeek = notesMapper.selectCount(
                new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid)
                        .ge(Notes::getUpdatedAt, weekAgo).isNull(Notes::getDeletedAt));
        Map<String, Object> week = Map.of("created", createdWeek, "updated", updatedWeek);

        // heatmap (152 days)
        LocalDate today = now.toLocalDate();
        LocalDate start = today.minusDays(151);
        List<Map<String, Object>> heatmap = new ArrayList<>();
        for (int i = 0; i < 152; i++) {
            LocalDate day = start.plusDays(i);
            OffsetDateTime dayStart = day.atStartOfDay().atOffset(ZoneOffset.UTC);
            OffsetDateTime dayEnd = day.plusDays(1).atStartOfDay().atOffset(ZoneOffset.UTC);
            long count = notesMapper.selectCount(
                    new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid)
                            .ge(Notes::getUpdatedAt, dayStart).lt(Notes::getUpdatedAt, dayEnd)
                            .isNull(Notes::getDeletedAt));
            heatmap.add(Map.of("date", day.toString(), "count", count));
        }

        // recent (last 5 updated notes)
        List<Notes> recent = notesMapper.selectList(
                new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid).isNull(Notes::getDeletedAt)
                        .orderByDesc(Notes::getUpdatedAt).last("LIMIT 5"));
        List<Map<String, Object>> recentList = recent.stream().map(n -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", n.getId().toString());
            m.put("title", n.getTitle());
            m.put("updated_at", n.getUpdatedAt());
            m.put("visibility", n.getVisibility());
            return m;
        }).collect(Collectors.toList());

        // folders stat
        List<Folders> folders = foldersMapper.selectList(
                new LambdaQueryWrapper<Folders>().eq(Folders::getUserId, uid).orderByAsc(Folders::getSortOrder));
        List<Map<String, Object>> folderStats = folders.stream().map(f -> {
            long count = notesMapper.selectCount(
                    new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid)
                            .eq(Notes::getFolderId, f.getId()).isNull(Notes::getDeletedAt));
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", f.getId().toString());
            m.put("name", f.getName());
            m.put("count", count);
            return m;
        }).collect(Collectors.toList());

        // issues stat
        long issueTotal = issuesMapper.selectCount(new LambdaQueryWrapper<Issues>().eq(Issues::getUserId, uid));
        long todoCount = issuesMapper.selectCount(
                new LambdaQueryWrapper<Issues>().eq(Issues::getUserId, uid).eq(Issues::getStatus, "todo"));
        long inProgressCount = issuesMapper.selectCount(
                new LambdaQueryWrapper<Issues>().eq(Issues::getUserId, uid).eq(Issues::getStatus, "in_progress"));
        long doneCount = issuesMapper.selectCount(
                new LambdaQueryWrapper<Issues>().eq(Issues::getUserId, uid).eq(Issues::getStatus, "done"));
        List<Issues> recentIssues = issuesMapper.selectList(
                new LambdaQueryWrapper<Issues>().eq(Issues::getUserId, uid).ne(Issues::getStatus, "done")
                        .orderByDesc(Issues::getUpdatedAt).last("LIMIT 5"));
        List<Map<String, Object>> recentIssueList = recentIssues.stream().map(i -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", i.getId().toString());
            m.put("title", i.getTitle());
            m.put("type", i.getType());
            m.put("status", i.getStatus());
            m.put("priority", i.getPriority());
            m.put("updated_at", i.getUpdatedAt());
            m.put("parent_title", null); // 简化：不查 parent title
            return m;
        }).toList();
        Map<String, Object> issuesStat = Map.of(
                "total", issueTotal, "todo", todoCount, "in_progress", inProgressCount, "done", doneCount,
                "recent", recentIssueList);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("totals", totals);
        result.put("week", week);
        result.put("heatmap", heatmap);
        result.put("recent", recentList);
        result.put("folders", folderStats);
        result.put("issues", issuesStat);
        return result;
    }
}
