package com.haven.backend.note.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.haven.backend.exception.BizException;
import com.haven.backend.note.entity.Notes;
import com.haven.backend.note.mapper.FoldersMapper;
import com.haven.backend.note.mapper.NoteTagsMapper;
import com.haven.backend.note.mapper.NoteVersionsMapper;
import com.haven.backend.note.mapper.NotesMapper;
import com.haven.backend.note.mapper.TagsMapper;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * 公开笔记可见性测试：软删除、未公开、未发布都不允许通过公开接口读取。
 */
@ExtendWith(MockitoExtension.class)
class NotesServiceImplTest {

    @Mock
    private NotesMapper notesMapper;

    @Mock
    private NoteTagsMapper noteTagsMapper;

    @Mock
    private TagsMapper tagsMapper;

    @Mock
    private NoteVersionsMapper noteVersionsMapper;

    @Mock
    private FoldersMapper foldersMapper;

    @InjectMocks
    private NotesServiceImpl notesService;

    @Test
    @DisplayName("已软删除的公开笔记不可见")
    void softDeletedPublicNoteIsNotFound() {
        Notes note = publicNote();
        note.setDeletedAt(OffsetDateTime.now());
        when(notesMapper.selectById(note.getId())).thenReturn(note);

        BizException ex = assertThrows(BizException.class, () -> notesService.getPublicNote(note.getId()));

        assertEquals(404, ex.getCode());
    }

    @Test
    @DisplayName("未发布的公开笔记不可见")
    void unpublishedNoteIsNotFound() {
        Notes note = publicNote();
        note.setPublishedAt(null);
        when(notesMapper.selectById(note.getId())).thenReturn(note);

        BizException ex = assertThrows(BizException.class, () -> notesService.getPublicNote(note.getId()));

        assertEquals(404, ex.getCode());
    }

    @Test
    @DisplayName("已发布的公开笔记正常返回")
    void publishedPublicNoteIsVisible() {
        Notes note = publicNote();
        when(notesMapper.selectById(note.getId())).thenReturn(note);
        when(noteTagsMapper.selectTagsForNotes(any(), any())).thenReturn(List.of());

        var body = notesService.getPublicNote(note.getId());

        assertEquals(note.getId(), body.id());
        assertEquals("公开笔记", body.title());
        assertEquals(List.of(), body.tags());
    }

    private Notes publicNote() {
        Notes note = new Notes();
        note.setId(UUID.randomUUID());
        note.setUserId(UUID.randomUUID());
        note.setTitle("公开笔记");
        note.setContent("内容");
        note.setVisibility("public");
        note.setPublishedAt(OffsetDateTime.now());
        note.setUpdatedAt(OffsetDateTime.now());
        return note;
    }
}
