package com.haven.backend.note.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.note.dto.NoteDtos.NotePage;
import com.haven.backend.note.dto.NoteDtos.NoteSummary;
import com.haven.backend.note.dto.NoteDtos.SearchResult;
import com.haven.backend.note.dto.NoteDtos.TagSummary;
import com.haven.backend.note.entity.NoteTags;
import com.haven.backend.note.entity.Notes;
import com.haven.backend.note.entity.Tags;
import com.haven.backend.note.mapper.NoteTagsMapper;
import com.haven.backend.note.mapper.NotesMapper;
import com.haven.backend.note.mapper.TagsMapper;
import com.haven.backend.note.service.SearchService;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 搜索实现。
 * <p>
 * 标签与笔记都用一次性批量查询，列表项复用 {@link NotesServiceImpl#toSummary} 的映射，
 * 避免同一份拼装逻辑散落在多个类里。
 */
@Service
@RequiredArgsConstructor
public class SearchServiceImpl implements SearchService {

    private final NotesMapper notesMapper;
    private final TagsMapper tagsMapper;
    private final NoteTagsMapper noteTagsMapper;

    @Override
    @Transactional(readOnly = true)
    public SearchResult searchPrivate(String userId, String q, int limit, int offset, String type) {
        UUID uid = UUID.fromString(userId);
        int lim = Math.clamp(limit, 1, 100);
        int off = Math.max(offset, 0);

        var noteWrapper =
                new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid).isNull(Notes::getDeletedAt);
        if ("title".equals(type)) {
            noteWrapper.like(Notes::getTitle, q);
        } else {
            noteWrapper.and(w -> w.like(Notes::getTitle, q).or().like(Notes::getSearchText, q));
        }
        long noteTotal = notesMapper.selectCount(noteWrapper);
        List<Notes> notes = notesMapper.selectList(
                noteWrapper.orderByDesc(Notes::getUpdatedAt).last("LIMIT " + lim + " OFFSET " + off));

        List<NoteSummary> noteItems =
                notes.stream().map(NotesServiceImpl::toSummary).collect(Collectors.toList());

        List<Tags> tags = tagsMapper.selectList(new LambdaQueryWrapper<Tags>()
                .eq(Tags::getUserId, uid)
                .like(Tags::getName, q)
                .orderByAsc(Tags::getName));
        List<TagSummary> tagItems = tags.stream()
                .map(t -> new TagSummary(
                        t.getId(),
                        t.getName(),
                        noteTagsMapper.selectCount(
                                new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getTagId, t.getId())),
                        t.getCreatedAt()))
                .collect(Collectors.toList());

        return new SearchResult(new NotePage(noteItems, noteTotal), tagItems, tagItems.size());
    }
}
