package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.entity.NoteTags;
import com.haven.backend.entity.Notes;
import com.haven.backend.entity.Tags;
import com.haven.backend.mapper.NoteTagsMapper;
import com.haven.backend.mapper.NotesMapper;
import com.haven.backend.mapper.TagsMapper;
import com.haven.backend.service.SearchService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SearchServiceImpl implements SearchService {

    private final NotesMapper notesMapper;
    private final TagsMapper tagsMapper;
    private final NoteTagsMapper noteTagsMapper;

    @Override
    public Map<String, Object> searchPrivate(String userId, String q, int limit, int offset, String type) {
        UUID uid = UUID.fromString(userId);
        int lim = Math.min(limit, 100);
        String pattern = "%" + escapeLike(q) + "%";

        // 搜索笔记
        var noteWrapper = new LambdaQueryWrapper<Notes>()
                .eq(Notes::getUserId, uid).isNull(Notes::getDeletedAt);
        if ("title".equals(type)) {
            noteWrapper.like(Notes::getTitle, q);
        } else {
            noteWrapper.and(w -> w.like(Notes::getTitle, q).or().like(Notes::getSearchText, q));
        }
        long noteTotal = notesMapper.selectCount(noteWrapper);
        List<Notes> notes = notesMapper.selectList(
                noteWrapper.orderByDesc(Notes::getUpdatedAt).last("LIMIT " + lim + " OFFSET " + offset));

        List<Map<String, Object>> noteItems = notes.stream().map(n -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", n.getId().toString());
            m.put("title", n.getTitle());
            String c = n.getContent() != null ? n.getContent() : "";
            m.put("content_preview", c.length() > 200 ? c.substring(0, 200) : c);
            m.put("visibility", n.getVisibility());
            m.put("published_at", n.getPublishedAt());
            m.put("updated_at", n.getUpdatedAt());
            m.put("tags", getNoteTags(n.getId()));
            return m;
        }).collect(Collectors.toList());

        // 搜索标签
        List<Tags> tags = tagsMapper.selectList(
                new LambdaQueryWrapper<Tags>().eq(Tags::getUserId, uid).like(Tags::getName, q).orderByAsc(Tags::getName));
        List<Map<String, Object>> tagItems = tags.stream().map(t -> {
            long count = noteTagsMapper.selectCount(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getTagId, t.getId()));
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", t.getId().toString());
            m.put("name", t.getName());
            m.put("note_count", count);
            return m;
        }).collect(Collectors.toList());

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("notes", Map.of("items", noteItems, "total", noteTotal));
        result.put("tags", Map.of("items", tagItems, "total", tagItems.size()));
        return result;
    }

    @Override
    public Map<String, Object> searchPublic(String q, int limit, int offset) {
        int lim = Math.min(limit, 100);
        // 先查总数（不带 ORDER BY）
        var countWrapper = new LambdaQueryWrapper<Notes>()
                .eq(Notes::getVisibility, "public").isNotNull(Notes::getPublishedAt)
                .isNull(Notes::getDeletedAt).like(Notes::getSearchText, q);
        long total = notesMapper.selectCount(countWrapper);
        // 再查列表（带 ORDER BY 和分页）
        var listWrapper = new LambdaQueryWrapper<Notes>()
                .eq(Notes::getVisibility, "public").isNotNull(Notes::getPublishedAt)
                .isNull(Notes::getDeletedAt).like(Notes::getSearchText, q)
                .orderByDesc(Notes::getPublishedAt)
                .last("LIMIT " + lim + " OFFSET " + offset);
        List<Notes> notes = notesMapper.selectList(listWrapper);

        List<Map<String, Object>> items = notes.stream().map(n -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", n.getId().toString());
            m.put("title", n.getTitle());
            String c = n.getContent() != null ? n.getContent() : "";
            m.put("content_preview", c.length() > 200 ? c.substring(0, 200) : c);
            m.put("published_at", n.getPublishedAt());
            m.put("updated_at", n.getUpdatedAt());
            m.put("tags", getNoteTags(n.getId()));
            return m;
        }).collect(Collectors.toList());
        return Map.of("items", items, "total", total);
    }

    private List<Map<String, String>> getNoteTags(UUID noteId) {
        List<NoteTags> rels = noteTagsMapper.selectList(
                new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getNoteId, noteId));
        if (rels.isEmpty()) return List.of();
        List<UUID> tagIds = rels.stream().map(NoteTags::getTagId).collect(Collectors.toList());
        return tagsMapper.selectList(new LambdaQueryWrapper<Tags>().in(Tags::getId, tagIds))
                .stream().map(t -> Map.of("id", t.getId().toString(), "name", t.getName()))
                .collect(Collectors.toList());
    }

    private String escapeLike(String s) {
        return s.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }
}
