package com.haven.backend.note.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.exception.BizException;
import com.haven.backend.note.dto.NoteDtos.NotePage;
import com.haven.backend.note.dto.NoteDtos.NoteSummary;
import com.haven.backend.note.dto.NoteDtos.TagSummary;
import com.haven.backend.note.entity.NoteTags;
import com.haven.backend.note.entity.Notes;
import com.haven.backend.note.entity.Tags;
import com.haven.backend.note.mapper.NoteTagsMapper;
import com.haven.backend.note.mapper.NotesMapper;
import com.haven.backend.note.mapper.TagsMapper;
import com.haven.backend.note.service.TagsService;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TagsServiceImpl implements TagsService {

    private final TagsMapper tagsMapper;
    private final Clock clock;
    private final NoteTagsMapper noteTagsMapper;
    private final NotesMapper notesMapper;

    @Override
    @Transactional(readOnly = true)
    public List<TagSummary> listTags(String userId) {
        UUID uid = UUID.fromString(userId);

        List<Tags> tags = tagsMapper.selectList(
                new LambdaQueryWrapper<Tags>().eq(Tags::getUserId, uid).orderByAsc(Tags::getName));

        return tags.stream()
                .map(t -> new TagSummary(
                        t.getId(),
                        t.getName(),
                        noteTagsMapper.selectCount(
                                new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getTagId, t.getId())),
                        t.getCreatedAt()))
                .collect(Collectors.toList());
    }

    @Override
    public Tags createTag(String userId, String name) {
        UUID uid = UUID.fromString(userId);
        if (name == null || name.trim().isEmpty()) {
            throw BizException.validation("标签名不能为空");
        }
        if (name.trim().length() > 64) {
            throw BizException.validation("标签名不能超过 64 个字符");
        }

        // 大小写不敏感唯一
        Tags existing = tagsMapper.selectOne(
                new LambdaQueryWrapper<Tags>().eq(Tags::getUserId, uid).apply("lower(name) = lower({0})", name.trim()));
        if (existing != null) {
            throw BizException.conflict("标签已存在");
        }

        Tags tag = new Tags();
        tag.setId(UUID.randomUUID());
        tag.setUserId(uid);
        tag.setName(name.trim());
        tag.setCreatedAt(OffsetDateTime.now(clock));
        tagsMapper.insert(tag);
        return tag;
    }

    @Override
    @Transactional
    public void deleteTag(String userId, UUID tagId) {
        UUID uid = UUID.fromString(userId);
        Tags tag = tagsMapper.selectById(tagId);
        if (tag == null || !tag.getUserId().equals(uid)) {
            throw BizException.notFound("标签不存在");
        }
        noteTagsMapper.delete(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getTagId, tagId));
        tagsMapper.deleteById(tagId);
    }

    @Override
    @Transactional(readOnly = true)
    public NotePage listTagNotes(String userId, UUID tagId, int limit, int offset) {
        UUID uid = UUID.fromString(userId);
        // 标签本身必须属于当前用户
        Tags tag = tagsMapper.selectById(tagId);
        if (tag == null || !tag.getUserId().equals(uid)) {
            throw BizException.notFound("标签不存在");
        }
        int lim = Math.clamp(limit, 1, 100);
        int off = Math.max(offset, 0);
        // 先查关联的 note_id
        List<NoteTags> rels =
                noteTagsMapper.selectList(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getTagId, tagId));
        List<UUID> noteIds = rels.stream().map(NoteTags::getNoteId).collect(Collectors.toList());
        if (noteIds.isEmpty()) {
            return new NotePage(List.of(), 0);
        }

        long total = notesMapper.selectCount(new LambdaQueryWrapper<Notes>()
                .in(Notes::getId, noteIds)
                .eq(Notes::getUserId, uid)
                .isNull(Notes::getDeletedAt));

        List<Notes> notes = notesMapper.selectList(new LambdaQueryWrapper<Notes>()
                .in(Notes::getId, noteIds)
                .eq(Notes::getUserId, uid)
                .isNull(Notes::getDeletedAt)
                .orderByDesc(Notes::getUpdatedAt)
                .last("LIMIT " + lim + " OFFSET " + off));

        List<NoteSummary> items =
                notes.stream().map(NotesServiceImpl::toSummary).collect(Collectors.toList());
        return new NotePage(items, total);
    }

    // ---- 内部 ----
}
