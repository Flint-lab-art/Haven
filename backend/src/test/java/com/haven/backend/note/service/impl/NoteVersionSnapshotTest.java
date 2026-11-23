package com.haven.backend.note.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.haven.backend.note.entity.NoteVersions;
import com.haven.backend.note.entity.Notes;
import com.haven.backend.note.mapper.FoldersMapper;
import com.haven.backend.note.mapper.NoteTagsMapper;
import com.haven.backend.note.mapper.NoteVersionsMapper;
import com.haven.backend.note.mapper.NotesMapper;
import com.haven.backend.note.mapper.TagsMapper;
import java.time.Clock;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

/**
 * 历史版本的快照语义。
 *
 * <p>核心约束：**快照保存的是「修改前」的内容**。
 * 若保存修改后的值，历史里最早的一版会退化成当前内容，用户永远回不到任何过去的状态。
 * 这类问题不会报错、接口也返回 200，只能靠测试钉住。
 *
 * <p>这里用宽松桩（LENIENT）：四个用例共享 setUp 里的查询桩，但并非每个用例都会走到全部查询。
 * 本类断言的是「写了什么」而非「调用了哪些查询」，严格桩只会制造无关噪音。
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class NoteVersionSnapshotTest {

    private static final OffsetDateTime NOW = OffsetDateTime.of(2026, 1, 1, 12, 0, 0, 0, ZoneOffset.UTC);

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

    private NotesServiceImpl service;
    private Notes note;
    private UUID userId;
    private String userIdText;

    @BeforeEach
    void setUp() {
        Clock clock = Clock.fixed(NOW.toInstant(), ZoneOffset.UTC);
        service =
                new NotesServiceImpl(notesMapper, clock, noteTagsMapper, tagsMapper, noteVersionsMapper, foldersMapper);

        userId = UUID.randomUUID();
        userIdText = userId.toString();
        note = new Notes();
        note.setId(UUID.randomUUID());
        note.setUserId(userId);
        note.setTitle("旧标题");
        note.setContent("旧正文");
        note.setSortOrder(1);
        note.setCreatedAt(NOW);
        note.setUpdatedAt(NOW);

        when(notesMapper.selectById(note.getId())).thenReturn(note);
        // 没有变化时不会产生版本
        when(noteVersionsMapper.selectOne(any())).thenReturn(null);
    }

    /** 只有走到 buildNoteDetail 的用例才需要这批桩，否则 Mockito 会报「多余桩」。 */
    private void stubDetailBuilding() {
        when(noteTagsMapper.selectList(any())).thenReturn(List.of());
        when(noteTagsMapper.selectTagsForNotes(any(), any())).thenReturn(List.of());
    }

    @Test
    @DisplayName("更新笔记时，快照里存的是修改前的内容")
    void snapshotKeepsPreviousContent() {
        stubDetailBuilding();
        // 没有历史版本时走 insert 分支（selectOne 在 setUp 里已桩成 null）

        service.updateNote(userIdText, note.getId(), "新标题", "新正文", null, null, false, null);

        ArgumentCaptor<NoteVersions> captor = ArgumentCaptor.forClass(NoteVersions.class);
        verify(noteVersionsMapper).insert(captor.capture());
        NoteVersions saved = captor.getValue();

        assertEquals("旧标题", saved.getTitle(), "快照应保存修改前的标题");
        assertEquals("旧正文", saved.getContent(), "快照应保存修改前的正文");

        // 笔记本体才是新内容
        assertEquals("新标题", note.getTitle());
        assertEquals("新正文", note.getContent());
    }

    @Test
    @DisplayName("内容没有变化时不产生版本（自动保存常发相同内容）")
    void unchangedPatchDoesNotCreateVersion() {
        service.updateNote(userIdText, note.getId(), "旧标题", "旧正文", null, null, false, null);

        verify(noteVersionsMapper, never()).insert(any(NoteVersions.class));
        // 内容没变就不该写库
        verify(notesMapper, never()).updateById(any(Notes.class));
    }

    @Test
    @DisplayName("还原旧版本时，先把当前内容存成快照，使还原本身可撤销")
    void restoreSnapshotsCurrentContentFirst() {
        stubDetailBuilding();
        note.setTitle("当前标题");
        note.setContent("当前正文");

        NoteVersions old = new NoteVersions();
        old.setId(UUID.randomUUID());
        old.setNoteId(note.getId());
        old.setUserId(userId);
        old.setTitle("很早的标题");
        old.setContent("很早的正文");
        old.setTagIds(List.of());
        when(noteVersionsMapper.selectById(old.getId())).thenReturn(old);

        service.restoreVersion(userIdText, note.getId(), old.getId());

        ArgumentCaptor<NoteVersions> captor = ArgumentCaptor.forClass(NoteVersions.class);
        verify(noteVersionsMapper).insert(captor.capture());
        assertEquals("当前标题", captor.getValue().getTitle(), "还原前应把当前内容存成快照");
        assertEquals("当前正文", captor.getValue().getContent());

        assertEquals("很早的标题", note.getTitle());
        assertEquals("很早的正文", note.getContent());
    }

    @Test
    @DisplayName("创建笔记时不产生版本（此时没有「之前」）")
    void createDoesNotCreateVersion() {
        when(notesMapper.selectOne(any())).thenReturn(null);
        stubDetailBuilding();

        service.createNote(userIdText, "新笔记", "", null, null);

        verify(noteVersionsMapper, never()).insert(any(NoteVersions.class));
    }

    @SuppressWarnings("unused")
    private static Instant unused() {
        return NOW.toInstant();
    }
}
