package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.entity.NoteTags;
import com.haven.backend.entity.Notes;
import com.haven.backend.entity.Tags;
import com.haven.backend.exception.BizException;
import com.haven.backend.mapper.NoteTagsMapper;
import com.haven.backend.mapper.NotesMapper;
import com.haven.backend.mapper.TagsMapper;
import com.haven.backend.service.TagsService;
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
public class TagsServiceImpl implements TagsService {

    private final TagsMapper tagsMapper;
    private final NoteTagsMapper noteTagsMapper;
    private final NotesMapper notesMapper;

    @Override
    @Transactional
    public List<Map<String, Object>> listTags(String userId) {
        UUID uid = UUID.fromString(userId);
        // 自动清理无引用的标签
        pruneEmptyTags(uid);

        List<Tags> tags = tagsMapper.selectList(
                new LambdaQueryWrapper<Tags>().eq(Tags::getUserId, uid).orderByAsc(Tags::getName));

        return tags.stream().map(t -> {
            long count = noteTagsMapper.selectCount(
                    new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getTagId, t.getId()));
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", t.getId().toString());
            m.put("name", t.getName());
            m.put("note_count", count);
            m.put("created_at", t.getCreatedAt());
            return m;
        }).collect(Collectors.toList());
    }

    @Override
    public Tags createTag(String userId, String name) {
        UUID uid = UUID.fromString(userId);
        if (name == null || name.trim().isEmpty()) throw BizException.validation("标签名不能为空");
        if (name.trim().length() > 64) throw BizException.validation("标签名不能超过 64 个字符");

        // 大小写不敏感唯一
        Tags existing = tagsMapper.selectOne(
                new LambdaQueryWrapper<Tags>()
                        .eq(Tags::getUserId, uid)
                        .apply("lower(name) = lower({0})", name.trim()));
        if (existing != null) throw BizException.conflict("标签已存在");

        Tags tag = new Tags();
        tag.setId(UUID.randomUUID());
        tag.setUserId(uid);
        tag.setName(name.trim());
        tag.setCreatedAt(OffsetDateTime.now());
        tagsMapper.insert(tag);
        return tag;
    }

    @Override
    @Transactional
    public void deleteTag(String userId, UUID tagId) {
        UUID uid = UUID.fromString(userId);
        Tags tag = tagsMapper.selectById(tagId);
        if (tag == null || !tag.getUserId().equals(uid)) throw BizException.notFound("标签不存在");
        noteTagsMapper.delete(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getTagId, tagId));
        tagsMapper.deleteById(tagId);
    }

    @Override
    public Map<String, Object> listTagNotes(String userId, UUID tagId, int limit, int offset) {
        UUID uid = UUID.fromString(userId);
        // 先查关联的 note_id
        List<NoteTags> rels = noteTagsMapper.selectList(
                new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getTagId, tagId));
        List<UUID> noteIds = rels.stream().map(NoteTags::getNoteId).collect(Collectors.toList());
        if (noteIds.isEmpty()) return Map.of("items", List.of(), "total", 0);

        long total = notesMapper.selectCount(
                new LambdaQueryWrapper<Notes>()
                        .in(Notes::getId, noteIds)
                        .eq(Notes::getUserId, uid)
                        .isNull(Notes::getDeletedAt));

        List<Notes> notes = notesMapper.selectList(
                new LambdaQueryWrapper<Notes>()
                        .in(Notes::getId, noteIds)
                        .eq(Notes::getUserId, uid)
                        .isNull(Notes::getDeletedAt)
                        .orderByDesc(Notes::getUpdatedAt)
                        .last("LIMIT " + Math.min(limit, 100) + " OFFSET " + offset));

        List<Map<String, Object>> items = notes.stream()
                .map(n -> buildNoteSummary(n, uid))
                .collect(Collectors.toList());
        return Map.of("items", items, "total", total);
    }

    // ---- 内部 ----

    private void pruneEmptyTags(UUID userId) {
        List<Tags> allTags = tagsMapper.selectList(
                new LambdaQueryWrapper<Tags>().eq(Tags::getUserId, userId));
        for (Tags t : allTags) {
            long count = noteTagsMapper.selectCount(
                    new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getTagId, t.getId()));
            if (count == 0) tagsMapper.deleteById(t.getId());
        }
    }

    static Map<String, Object> buildNoteSummary(Notes n, UUID userId) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", n.getId().toString());
        m.put("folder_id", n.getFolderId() != null ? n.getFolderId().toString() : null);
        m.put("sort_order", n.getSortOrder());
        m.put("title", n.getTitle());
        String content = n.getContent() != null ? n.getContent() : "";
        m.put("content_preview", content.length() > 200 ? content.substring(0, 200) : content);
        m.put("visibility", n.getVisibility());
        m.put("published_at", n.getPublishedAt());
        m.put("created_at", n.getCreatedAt());
        m.put("updated_at", n.getUpdatedAt());
        m.put("tags", List.of()); // 调用方按需填充
        return m;
    }
}
