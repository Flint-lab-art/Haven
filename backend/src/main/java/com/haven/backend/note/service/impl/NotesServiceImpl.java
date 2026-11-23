package com.haven.backend.note.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.haven.backend.exception.BizException;
import com.haven.backend.note.dto.NoteDtos.NoteDetail;
import com.haven.backend.note.dto.NoteDtos.NotePage;
import com.haven.backend.note.dto.NoteDtos.NoteSummary;
import com.haven.backend.note.dto.NoteDtos.NoteVersionDetail;
import com.haven.backend.note.dto.NoteDtos.NoteVersionPage;
import com.haven.backend.note.dto.NoteDtos.NoteVersionSummary;
import com.haven.backend.note.dto.NoteDtos.TagBrief;
import com.haven.backend.note.dto.NoteDtos.TrashNotePage;
import com.haven.backend.note.dto.NoteDtos.TrashNoteSummary;
import com.haven.backend.note.entity.Folders;
import com.haven.backend.note.entity.NoteTags;
import com.haven.backend.note.entity.NoteVersions;
import com.haven.backend.note.entity.Notes;
import com.haven.backend.note.entity.Tags;
import com.haven.backend.note.mapper.FoldersMapper;
import com.haven.backend.note.mapper.NoteTagsMapper;
import com.haven.backend.note.mapper.NoteVersionsMapper;
import com.haven.backend.note.mapper.NotesMapper;
import com.haven.backend.note.mapper.TagsMapper;
import com.haven.backend.note.service.NotesService;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NotesServiceImpl implements NotesService {

    private final NotesMapper notesMapper;
    private final Clock clock;
    private final NoteTagsMapper noteTagsMapper;
    private final TagsMapper tagsMapper;
    private final NoteVersionsMapper noteVersionsMapper;
    private final FoldersMapper foldersMapper;

    private static final long VERSION_MERGE_MINUTES = 5;
    /** 列表项正文预览长度。 */
    private static final int PREVIEW_LENGTH = 200;

    @Override
    public NotePage listNotes(
            String userId, Integer limit, Integer offset, UUID tagId, UUID folderId, Boolean includeTrash) {
        UUID uid = UUID.fromString(userId);
        int lim = Math.clamp(limit != null ? limit : 20, 1, 100);
        int off = Math.max(offset != null ? offset : 0, 0);

        var wrapper = new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid);
        if (!Boolean.TRUE.equals(includeTrash)) {
            wrapper.isNull(Notes::getDeletedAt);
        }
        if (folderId != null) {
            wrapper.eq(Notes::getFolderId, folderId);
        }

        // 按标签过滤：先查关联 note_id
        if (tagId != null) {
            List<UUID> noteIds =
                    noteTagsMapper.selectList(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getTagId, tagId)).stream()
                            .map(NoteTags::getNoteId)
                            .collect(Collectors.toList());
            if (noteIds.isEmpty()) {
                return new NotePage(List.of(), 0);
            }
            wrapper.in(Notes::getId, noteIds);
        }

        long total = notesMapper.selectCount(wrapper);
        wrapper.orderByDesc(Notes::getUpdatedAt).last("LIMIT " + lim + " OFFSET " + off);
        List<Notes> notes = notesMapper.selectList(wrapper);

        Map<UUID, List<TagBrief>> tagsByNote = loadTags(uid, notes);
        List<NoteSummary> items = notes.stream()
                .map(n -> toSummary(n, tagsByNote.getOrDefault(n.getId(), List.of())))
                .collect(Collectors.toList());
        return new NotePage(items, total);
    }

    @Override
    public NoteDetail getNote(String userId, UUID noteId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        return buildNoteDetail(note, uid);
    }

    @Override
    @Transactional
    public NoteDetail createNote(String userId, String title, String content, List<UUID> tagIds, UUID folderId) {
        UUID uid = UUID.fromString(userId);
        // 验证 folder
        if (folderId != null) {
            Folders f = foldersMapper.selectById(folderId);
            if (f == null || !f.getUserId().equals(uid)) {
                throw BizException.notFound("文件夹不存在");
            }
        }

        int maxOrder = 0;
        if (folderId != null) {
            Notes max = notesMapper.selectOne(new LambdaQueryWrapper<Notes>()
                    .eq(Notes::getUserId, uid)
                    .eq(Notes::getFolderId, folderId)
                    .isNull(Notes::getDeletedAt)
                    .orderByDesc(Notes::getSortOrder)
                    .last("LIMIT 1"));
            if (max != null) {
                maxOrder = max.getSortOrder() != null ? max.getSortOrder() : 0;
            }
        }

        Notes note = new Notes();
        note.setId(UUID.randomUUID());
        note.setUserId(uid);
        note.setTitle(title != null ? title : "");
        note.setContent(content != null ? content : "");
        note.setFolderId(folderId);
        note.setSortOrder(maxOrder + 1);
        note.setSearchText(buildSearchText(note.getTitle(), note.getContent()));
        note.setCreatedAt(OffsetDateTime.now(clock));
        note.setUpdatedAt(OffsetDateTime.now(clock));
        notesMapper.insert(note);

        if (tagIds != null && !tagIds.isEmpty()) {
            setTags(uid, note.getId(), tagIds);
        }

        // 创建时不存快照：此时没有「之前」的内容，存下来只会得到一个与当前一致的冗余版本。
        return buildNoteDetail(note, uid);
    }

    @Override
    @Transactional
    public NoteDetail updateNote(
            String userId,
            UUID noteId,
            String title,
            String content,
            List<UUID> tagIds,
            UUID folderId,
            boolean clearFolder,
            Integer sortOrder) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        if (Boolean.TRUE.equals(note.getDeletedAt() != null)) {
            throw BizException.validation("回收站中的笔记不能编辑");
        }

        boolean changed = false;
        // 严格判断是否有实际变化：无变化的 PATCH（自动保存常发）不该产生版本，否则历史里全是重复项
        if (title != null && !title.equals(note.getTitle())) {
            changed = true;
        }
        if (content != null && !content.equals(note.getContent())) {
            changed = true;
        }
        if (folderId != null && !folderId.equals(note.getFolderId())) {
            changed = true;
        }
        if (clearFolder && note.getFolderId() != null) {
            changed = true;
        }
        if (sortOrder != null && !sortOrder.equals(note.getSortOrder())) {
            changed = true;
        }

        // 先把「修改前」的状态存成快照，再写新值。
        // 顺序不能反：存修改后的值会让历史里最早一版退化成当前内容，用户永远回不到过去。
        if (changed) {
            saveVersion(note, uid);
        }

        if (title != null) {
            note.setTitle(title);
        }
        if (content != null) {
            note.setContent(content);
        }
        if (folderId != null) {
            Folders f = foldersMapper.selectById(folderId);
            if (f == null || !f.getUserId().equals(uid)) {
                throw BizException.notFound("文件夹不存在");
            }
            note.setFolderId(folderId);
        } else if (clearFolder) {
            // updateById 跳过 null，必须用 UpdateWrapper 显式清空
            notesMapper.update(
                    new Notes(),
                    new LambdaUpdateWrapper<Notes>()
                            .eq(Notes::getId, noteId)
                            .eq(Notes::getUserId, uid)
                            .set(Notes::getFolderId, null));
            note.setFolderId(null);
        }
        if (sortOrder != null) {
            note.setSortOrder(sortOrder);
        }

        if (changed) {
            note.setSearchText(buildSearchText(note.getTitle(), note.getContent()));
            note.setUpdatedAt(OffsetDateTime.now(clock));
            notesMapper.updateById(note);
        }
        if (tagIds != null) {
            setTags(uid, note.getId(), tagIds);
        }

        return buildNoteDetail(note, uid);
    }

    @Override
    @Transactional
    public void deleteNote(String userId, UUID noteId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        note.setDeletedAt(OffsetDateTime.now(clock));
        note.setUpdatedAt(OffsetDateTime.now(clock));
        notesMapper.updateById(note);
    }

    @Override
    public TrashNotePage listTrash(String userId, int limit, int offset) {
        UUID uid = UUID.fromString(userId);
        int lim = Math.clamp(limit, 1, 100);
        int off = Math.max(offset, 0);
        // 先查总数（不带 ORDER BY）
        var countWrapper =
                new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid).isNotNull(Notes::getDeletedAt);
        long total = notesMapper.selectCount(countWrapper);
        // 再查列表（带 ORDER BY 和分页）
        var listWrapper = new LambdaQueryWrapper<Notes>()
                .eq(Notes::getUserId, uid)
                .isNotNull(Notes::getDeletedAt)
                .orderByDesc(Notes::getDeletedAt)
                .last("LIMIT " + lim + " OFFSET " + off);
        List<Notes> notes = notesMapper.selectList(listWrapper);

        List<TrashNoteSummary> items = notes.stream()
                .map(n -> new TrashNoteSummary(
                        n.getId(),
                        n.getTitle(),
                        preview(n.getContent()),
                        n.getFolderId(),
                        getFolderPath(n.getFolderId(), uid),
                        n.getDeletedAt()))
                .collect(Collectors.toList());
        return new TrashNotePage(items, total);
    }

    @Override
    @Transactional
    public NoteDetail restoreNote(String userId, UUID noteId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        if (note.getDeletedAt() == null) {
            throw BizException.validation("笔记不在回收站中");
        }
        // 必须用 UpdateWrapper 显式 set null：updateById 会跳过 null 字段（FieldStrategy.NOT_NULL），
        // 直接 setDeletedAt(null) + updateById 不会生成清空语句，笔记永远留在回收站。
        OffsetDateTime now = OffsetDateTime.now(clock);
        notesMapper.update(
                new Notes(),
                new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<Notes>()
                        .eq(Notes::getId, noteId)
                        .eq(Notes::getUserId, uid)
                        .set(Notes::getDeletedAt, null)
                        .set(Notes::getUpdatedAt, now));
        note.setDeletedAt(null);
        note.setUpdatedAt(now);
        return buildNoteDetail(note, uid);
    }

    @Override
    @Transactional
    public void purgeNote(String userId, UUID noteId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        if (note.getDeletedAt() == null) {
            throw BizException.validation("只能永久删除非回收站的笔记");
        }
        noteTagsMapper.delete(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getNoteId, noteId));
        noteVersionsMapper.delete(new LambdaQueryWrapper<NoteVersions>().eq(NoteVersions::getNoteId, noteId));
        notesMapper.deleteById(noteId);
    }

    @Override
    @Transactional
    public void emptyTrash(String userId) {
        UUID uid = UUID.fromString(userId);
        List<Notes> trash = notesMapper.selectList(
                new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid).isNotNull(Notes::getDeletedAt));
        for (Notes n : trash) {
            noteTagsMapper.delete(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getNoteId, n.getId()));
            noteVersionsMapper.delete(new LambdaQueryWrapper<NoteVersions>().eq(NoteVersions::getNoteId, n.getId()));
            notesMapper.deleteById(n.getId());
        }
    }

    @Override
    public NoteVersionPage listVersions(String userId, UUID noteId, int limit, int offset) {
        UUID uid = UUID.fromString(userId);
        getOwnedNote(uid, noteId); // 确认归属
        int lim = Math.clamp(limit, 1, 100);
        int off = Math.max(offset, 0);
        // 先查总数（不带 ORDER BY）
        var countWrapper = new LambdaQueryWrapper<NoteVersions>().eq(NoteVersions::getNoteId, noteId);
        long total = noteVersionsMapper.selectCount(countWrapper);
        // 再查列表（带 ORDER BY 和分页）
        var listWrapper = new LambdaQueryWrapper<NoteVersions>()
                .eq(NoteVersions::getNoteId, noteId)
                .orderByDesc(NoteVersions::getCreatedAt)
                .last("LIMIT " + lim + " OFFSET " + off);
        List<NoteVersions> versions = noteVersionsMapper.selectList(listWrapper);
        List<NoteVersionSummary> items = versions.stream()
                .map(v -> new NoteVersionSummary(
                        v.getId(),
                        v.getTitle(),
                        preview(v.getContent()),
                        v.getCreatedAt(),
                        v.getContent() != null ? v.getContent().length() : 0))
                .collect(Collectors.toList());
        return new NoteVersionPage(items, total);
    }

    @Override
    public NoteVersionDetail getVersion(String userId, UUID noteId, UUID versionId) {
        UUID uid = UUID.fromString(userId);
        getOwnedNote(uid, noteId);
        NoteVersions v = noteVersionsMapper.selectById(versionId);
        if (v == null || !v.getNoteId().equals(noteId)) {
            throw BizException.notFound("版本不存在");
        }
        return new NoteVersionDetail(
                v.getId(),
                v.getTitle(),
                v.getContent(),
                v.getFolderId(),
                v.getTagIds() != null ? v.getTagIds() : List.of(),
                v.getCreatedAt(),
                v.getContent() != null ? v.getContent().length() : 0);
    }

    @Override
    @Transactional
    public NoteDetail restoreVersion(String userId, UUID noteId, UUID versionId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        NoteVersions v = noteVersionsMapper.selectById(versionId);
        if (v == null || !v.getNoteId().equals(noteId)) {
            throw BizException.notFound("版本不存在");
        }

        // 还原前先存当前内容，否则「还原」这一步本身无法撤销
        saveVersion(note, uid);

        note.setTitle(v.getTitle());
        note.setContent(v.getContent());
        note.setFolderId(v.getFolderId());
        note.setSearchText(buildSearchText(note.getTitle(), note.getContent()));
        note.setUpdatedAt(OffsetDateTime.now(clock));
        notesMapper.updateById(note);

        // 恢复标签
        List<UUID> tagIds = v.getTagIds();
        if (tagIds != null && !tagIds.isEmpty()) {
            setTags(uid, note.getId(), tagIds);
        } else {
            noteTagsMapper.delete(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getNoteId, noteId));
        }

        return buildNoteDetail(note, uid);
    }

    // ---- 内部方法 ----

    private Notes getOwnedNote(UUID userId, UUID noteId) {
        Notes note = notesMapper.selectById(noteId);
        if (note == null || !note.getUserId().equals(userId)) {
            throw BizException.notFound("笔记不存在");
        }
        return note;
    }

    private void setTags(UUID userId, UUID noteId, List<UUID> tagIds) {
        if (!tagIds.isEmpty()) {
            // 标签必须属于当前用户，否则会形成跨租户关联并回显他人标签名
            long owned = tagsMapper.selectCount(
                    new LambdaQueryWrapper<Tags>().eq(Tags::getUserId, userId).in(Tags::getId, tagIds));
            if (owned != tagIds.stream().distinct().count()) {
                throw BizException.notFound("标签不存在");
            }
        }
        noteTagsMapper.delete(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getNoteId, noteId));
        for (UUID tid : tagIds) {
            NoteTags nt = new NoteTags();
            nt.setNoteId(noteId);
            nt.setTagId(tid);
            noteTagsMapper.insert(nt);
        }
    }

    /**
     * 一次查询取回多条笔记的标签并分组，避免列表页逐条查关联（N+1）。
     *
     */
    private Map<UUID, List<TagBrief>> loadTags(UUID userId, List<Notes> notes) {
        if (notes.isEmpty()) {
            return Map.of();
        }
        List<UUID> noteIds = notes.stream().map(Notes::getId).collect(Collectors.toList());
        Map<UUID, List<TagBrief>> result = new HashMap<>();
        for (NoteTagsMapper.NoteTag row : noteTagsMapper.selectTagsForNotes(userId, noteIds)) {
            result.computeIfAbsent(row.noteId(), k -> new ArrayList<>()).add(new TagBrief(row.tagId(), row.tagName()));
        }
        return result;
    }

    /**
     * 保存一个历史版本快照。
     * <p>
     * **调用时机必须在写入新内容之前**：快照保存的是「修改前」的状态，
     * 这样历史里每条都对应一个真实存在过的过去版本。
     * <p>
     * 5 分钟窗口内的多次修改合并成一条：内容是窗口起点那一刻的样子，
     * 避免自动保存刷出大量近乎相同的版本。窗口锚点用 window_started_at
     * （不会被刷新），不能用 created_at，否则窗口会无限滑动、永远合并不出第二条。
     */
    private void saveVersion(Notes note, UUID userId) {
        // 5 分钟合并窗口；窗口锚点用空窗起点，不能用会被刷新的 created_at，否则窗口无限滑动
        OffsetDateTime now = OffsetDateTime.now(clock);
        NoteVersions latest = noteVersionsMapper.selectOne(new LambdaQueryWrapper<NoteVersions>()
                .eq(NoteVersions::getNoteId, note.getId())
                .orderByDesc(NoteVersions::getCreatedAt)
                .last("LIMIT 1"));
        if (latest != null && latest.getWindowStartedAt() != null) {
            OffsetDateTime windowEnd = latest.getWindowStartedAt().plusMinutes(VERSION_MERGE_MINUTES);
            if (windowEnd.isAfter(now)) {
                // 同一窗口内合并内容，但不改写 created_at / window_started_at
                latest.setTitle(note.getTitle());
                latest.setContent(note.getContent());
                latest.setFolderId(note.getFolderId());
                latest.setTagIds(getTagIdList(note.getId()));
                latest.setUpdatedAt(now);
                noteVersionsMapper.updateById(latest);
                return;
            }
        }
        NoteVersions v = new NoteVersions();
        v.setId(UUID.randomUUID());
        v.setNoteId(note.getId());
        v.setUserId(userId);
        v.setTitle(note.getTitle());
        v.setContent(note.getContent());
        v.setFolderId(note.getFolderId());
        v.setTagIds(getTagIdList(note.getId()));
        v.setCreatedAt(now);
        v.setUpdatedAt(now);
        v.setWindowStartedAt(now);
        noteVersionsMapper.insert(v);
    }

    private List<UUID> getTagIdList(UUID noteId) {
        List<NoteTags> rels =
                noteTagsMapper.selectList(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getNoteId, noteId));
        return rels.stream().map(NoteTags::getTagId).collect(Collectors.toList());
    }

    private String buildSearchText(String title, String content) {
        StringBuilder sb = new StringBuilder();
        if (title != null) {
            sb.append(title);
        }
        if (content != null) {
            String text =
                    content.replaceAll("<[^>]*>", " ").replaceAll("\\s+", " ").trim();
            if (sb.length() > 0) {
                sb.append(" ");
            }
            sb.append(text);
        }
        return sb.toString();
    }

    private String getFolderPath(UUID folderId, UUID userId) {
        if (folderId == null) {
            return "/";
        }
        Folders f = foldersMapper.selectById(folderId);
        // 文件夹已被删除或不属于当前用户时，不暴露名称
        if (f == null || userId == null || !f.getUserId().equals(userId)) {
            return "/";
        }
        return "/" + f.getName();
    }

    /** 正文预览：去除换行并截断到 200 个字符。 */
    private static String preview(String content) {
        if (content == null) {
            return "";
        }
        return content.length() > PREVIEW_LENGTH ? content.substring(0, PREVIEW_LENGTH) : content;
    }

    /**
     * 笔记列表项的统一映射，供笔记列表、标签页、搜索结果共用，避免多份重复实现。
     *
     * @param tags 已批量加载的标签，null 表示不附标签
     */
    static NoteSummary toSummary(Notes n, List<TagBrief> tags) {
        return new NoteSummary(
                n.getId(),
                n.getFolderId(),
                n.getSortOrder(),
                n.getTitle(),
                preview(n.getContent()),
                n.getCreatedAt(),
                n.getUpdatedAt(),
                tags != null ? tags : List.of());
    }

    /** 单条映射（不附标签），用于不需要标签的场景。 */
    static NoteSummary toSummary(Notes n) {
        return toSummary(n, null);
    }

    private NoteDetail buildNoteDetail(Notes n, UUID uid) {
        List<TagBrief> tags = loadTags(n.getUserId(), List.of(n)).getOrDefault(n.getId(), List.of());
        return new NoteDetail(
                n.getId(),
                n.getFolderId(),
                n.getSortOrder(),
                n.getTitle(),
                n.getContent(),
                n.getCreatedAt(),
                n.getUpdatedAt(),
                tags);
    }
}
