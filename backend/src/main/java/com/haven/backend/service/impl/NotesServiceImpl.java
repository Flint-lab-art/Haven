package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.entity.*;
import com.haven.backend.exception.BizException;
import com.haven.backend.mapper.*;
import com.haven.backend.service.NotesService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotesServiceImpl implements NotesService {

    private final NotesMapper notesMapper;
    private final NoteTagsMapper noteTagsMapper;
    private final TagsMapper tagsMapper;
    private final NoteVersionsMapper noteVersionsMapper;
    private final FoldersMapper foldersMapper;

    private static final long VERSION_MERGE_MINUTES = 5;

    @Override
    public Map<String, Object> listNotes(String userId, Integer limit, Integer offset,
                                         String visibility, UUID tagId, UUID folderId, Boolean includeTrash) {
        UUID uid = UUID.fromString(userId);
        int lim = Math.min(limit != null ? limit : 20, 100);
        int off = offset != null ? offset : 0;

        var wrapper = new LambdaQueryWrapper<Notes>().eq(Notes::getUserId, uid);
        if (!Boolean.TRUE.equals(includeTrash)) wrapper.isNull(Notes::getDeletedAt);
        if (visibility != null && !visibility.isBlank()) wrapper.eq(Notes::getVisibility, visibility);
        if (folderId != null) wrapper.eq(Notes::getFolderId, folderId);

        // 按标签过滤：先查关联 note_id
        if (tagId != null) {
            List<UUID> noteIds = noteTagsMapper.selectList(
                    new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getTagId, tagId))
                    .stream().map(NoteTags::getNoteId).collect(Collectors.toList());
            if (noteIds.isEmpty()) return Map.of("items", List.of(), "total", 0);
            wrapper.in(Notes::getId, noteIds);
        }

        long total = notesMapper.selectCount(wrapper);
        wrapper.orderByDesc(Notes::getUpdatedAt).last("LIMIT " + lim + " OFFSET " + off);
        List<Notes> notes = notesMapper.selectList(wrapper);

        List<Map<String, Object>> items = notes.stream()
                .map(n -> buildNoteSummary(n, uid))
                .collect(Collectors.toList());
        return Map.of("items", items, "total", total);
    }

    @Override
    public Map<String, Object> getNote(String userId, UUID noteId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        return buildNoteDetail(note, uid);
    }

    @Override
    @Transactional
    public Map<String, Object> createNote(String userId, String title, String content,
                                          List<UUID> tagIds, UUID folderId) {
        UUID uid = UUID.fromString(userId);
        // 验证 folder
        if (folderId != null) {
            Folders f = foldersMapper.selectById(folderId);
            if (f == null || !f.getUserId().equals(uid)) throw BizException.notFound("文件夹不存在");
        }

        int maxOrder = 0;
        if (folderId != null) {
            Notes max = notesMapper.selectOne(new LambdaQueryWrapper<Notes>()
                    .eq(Notes::getUserId, uid).eq(Notes::getFolderId, folderId)
                    .isNull(Notes::getDeletedAt).orderByDesc(Notes::getSortOrder).last("LIMIT 1"));
            if (max != null) maxOrder = max.getSortOrder() != null ? max.getSortOrder() : 0;
        }

        Notes note = new Notes();
        note.setId(UUID.randomUUID());
        note.setUserId(uid);
        note.setTitle(title != null ? title : "");
        note.setContent(content != null ? content : "");
        note.setVisibility("private");
        note.setFolderId(folderId);
        note.setSortOrder(maxOrder + 1);
        note.setSearchText(buildSearchText(note.getTitle(), note.getContent()));
        note.setCreatedAt(OffsetDateTime.now());
        note.setUpdatedAt(OffsetDateTime.now());
        notesMapper.insert(note);

        if (tagIds != null && !tagIds.isEmpty()) setTags(note.getId(), tagIds);

        // 创建版本快照
        saveVersion(note, uid);
        return buildNoteDetail(note, uid);
    }

    @Override
    @Transactional
    public Map<String, Object> updateNote(String userId, UUID noteId, String title, String content,
                                          List<UUID> tagIds, UUID folderId, Integer sortOrder) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        if (Boolean.TRUE.equals(note.getDeletedAt() != null)) throw BizException.validation("回收站中的笔记不能编辑");

        boolean changed = false;
        if (title != null) { note.setTitle(title); changed = true; }
        if (content != null) { note.setContent(content); changed = true; }
        if (folderId != null) {
            Folders f = foldersMapper.selectById(folderId);
            if (f == null || !f.getUserId().equals(uid)) throw BizException.notFound("文件夹不存在");
            note.setFolderId(folderId); changed = true;
        }
        if (sortOrder != null) { note.setSortOrder(sortOrder); changed = true; }

        if (changed) {
            note.setSearchText(buildSearchText(note.getTitle(), note.getContent()));
            note.setUpdatedAt(OffsetDateTime.now());
            notesMapper.updateById(note);
            saveVersion(note, uid);
        }
        if (tagIds != null) setTags(note.getId(), tagIds);

        return buildNoteDetail(note, uid);
    }

    @Override
    public void deleteNote(String userId, UUID noteId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        note.setDeletedAt(OffsetDateTime.now());
        note.setUpdatedAt(OffsetDateTime.now());
        notesMapper.updateById(note);
    }

    @Override
    public Map<String, Object> listTrash(String userId, int limit, int offset) {
        UUID uid = UUID.fromString(userId);
        int lim = Math.min(limit, 100);
        // 先查总数（不带 ORDER BY）
        var countWrapper = new LambdaQueryWrapper<Notes>()
                .eq(Notes::getUserId, uid).isNotNull(Notes::getDeletedAt);
        long total = notesMapper.selectCount(countWrapper);
        // 再查列表（带 ORDER BY 和分页）
        var listWrapper = new LambdaQueryWrapper<Notes>()
                .eq(Notes::getUserId, uid).isNotNull(Notes::getDeletedAt)
                .orderByDesc(Notes::getDeletedAt)
                .last("LIMIT " + lim + " OFFSET " + offset);
        List<Notes> notes = notesMapper.selectList(listWrapper);

        List<Map<String, Object>> items = notes.stream().map(n -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", n.getId().toString());
            m.put("title", n.getTitle());
            String c = n.getContent() != null ? n.getContent() : "";
            m.put("content_preview", c.length() > 200 ? c.substring(0, 200) : c);
            m.put("folder_id", n.getFolderId() != null ? n.getFolderId().toString() : null);
            m.put("folder_path", getFolderPath(n.getFolderId(), uid));
            m.put("deleted_at", n.getDeletedAt());
            return m;
        }).collect(Collectors.toList());
        return Map.of("items", items, "total", total);
    }

    @Override
    public Map<String, Object> restoreNote(String userId, UUID noteId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        if (note.getDeletedAt() == null) throw BizException.validation("笔记不在回收站中");
        note.setDeletedAt(null);
        note.setUpdatedAt(OffsetDateTime.now());
        notesMapper.updateById(note);
        return buildNoteDetail(note, uid);
    }

    @Override
    public void purgeNote(String userId, UUID noteId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        if (note.getDeletedAt() == null) throw BizException.validation("只能永久删除非回收站的笔记");
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
    public Map<String, Object> publishNote(String userId, UUID noteId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        note.setVisibility("public");
        if (note.getPublishedAt() == null) note.setPublishedAt(OffsetDateTime.now());
        note.setUpdatedAt(OffsetDateTime.now());
        notesMapper.updateById(note);
        return buildNoteDetail(note, uid);
    }

    @Override
    public Map<String, Object> unpublishNote(String userId, UUID noteId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        note.setVisibility("private");
        note.setUpdatedAt(OffsetDateTime.now());
        notesMapper.updateById(note);
        return buildNoteDetail(note, uid);
    }

    @Override
    public Map<String, Object> listVersions(String userId, UUID noteId, int limit, int offset) {
        UUID uid = UUID.fromString(userId);
        getOwnedNote(uid, noteId); // 确认归属
        int lim = Math.min(limit, 100);
        // 先查总数（不带 ORDER BY）
        var countWrapper = new LambdaQueryWrapper<NoteVersions>()
                .eq(NoteVersions::getNoteId, noteId);
        long total = noteVersionsMapper.selectCount(countWrapper);
        // 再查列表（带 ORDER BY 和分页）
        var listWrapper = new LambdaQueryWrapper<NoteVersions>()
                .eq(NoteVersions::getNoteId, noteId)
                .orderByDesc(NoteVersions::getCreatedAt)
                .last("LIMIT " + lim + " OFFSET " + offset);
        List<NoteVersions> versions = noteVersionsMapper.selectList(listWrapper);
        List<Map<String, Object>> items = versions.stream().map(v -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", v.getId().toString());
            m.put("title", v.getTitle());
            m.put("created_at", v.getCreatedAt());
            m.put("content_size", v.getContent() != null ? v.getContent().length() : 0);
            return m;
        }).collect(Collectors.toList());
        return Map.of("items", items, "total", total);
    }

    @Override
    public Map<String, Object> getVersion(String userId, UUID noteId, UUID versionId) {
        UUID uid = UUID.fromString(userId);
        getOwnedNote(uid, noteId);
        NoteVersions v = noteVersionsMapper.selectById(versionId);
        if (v == null || !v.getNoteId().equals(noteId)) throw BizException.notFound("版本不存在");
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", v.getId().toString());
        m.put("note_id", v.getNoteId().toString());
        m.put("title", v.getTitle());
        m.put("content", v.getContent());
        m.put("folder_id", v.getFolderId() != null ? v.getFolderId().toString() : null);
        m.put("tag_ids", v.getTagIds() != null ? v.getTagIds() : List.of());
        m.put("created_at", v.getCreatedAt());
        return m;
    }

    @Override
    @Transactional
    public Map<String, Object> restoreVersion(String userId, UUID noteId, UUID versionId) {
        UUID uid = UUID.fromString(userId);
        Notes note = getOwnedNote(uid, noteId);
        NoteVersions v = noteVersionsMapper.selectById(versionId);
        if (v == null || !v.getNoteId().equals(noteId)) throw BizException.notFound("版本不存在");

        note.setTitle(v.getTitle());
        note.setContent(v.getContent());
        note.setFolderId(v.getFolderId());
        note.setSearchText(buildSearchText(note.getTitle(), note.getContent()));
        note.setUpdatedAt(OffsetDateTime.now());
        notesMapper.updateById(note);

        // 恢复标签
        List<UUID> tagIds = v.getTagIds();
        if (tagIds != null && !tagIds.isEmpty()) setTags(note.getId(), tagIds);
        else noteTagsMapper.delete(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getNoteId, noteId));

        saveVersion(note, uid);
        return buildNoteDetail(note, uid);
    }

    @Override
    public Map<String, Object> listPublicNotes(int limit, int offset) {
        int lim = Math.min(limit, 100);
        // 先查总数（不带 ORDER BY）
        var countWrapper = new LambdaQueryWrapper<Notes>()
                .eq(Notes::getVisibility, "public").isNotNull(Notes::getPublishedAt)
                .isNull(Notes::getDeletedAt);
        long total = notesMapper.selectCount(countWrapper);
        // 再查列表（带 ORDER BY 和分页）
        var listWrapper = new LambdaQueryWrapper<Notes>()
                .eq(Notes::getVisibility, "public").isNotNull(Notes::getPublishedAt)
                .isNull(Notes::getDeletedAt)
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

    @Override
    public Map<String, Object> getPublicNote(UUID noteId) {
        Notes note = notesMapper.selectById(noteId);
        if (note == null || !"public".equals(note.getVisibility()) || note.getPublishedAt() == null)
            throw BizException.notFound("笔记不存在或未公开");
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", note.getId().toString());
        m.put("title", note.getTitle());
        m.put("content", note.getContent());
        m.put("published_at", note.getPublishedAt());
        m.put("updated_at", note.getUpdatedAt());
        m.put("tags", getNoteTags(note.getId()));
        return m;
    }

    // ---- 内部方法 ----

    private Notes getOwnedNote(UUID userId, UUID noteId) {
        Notes note = notesMapper.selectById(noteId);
        if (note == null || !note.getUserId().equals(userId)) throw BizException.notFound("笔记不存在");
        return note;
    }

    private void setTags(UUID noteId, List<UUID> tagIds) {
        noteTagsMapper.delete(new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getNoteId, noteId));
        for (UUID tid : tagIds) {
            NoteTags nt = new NoteTags();
            nt.setNoteId(noteId);
            nt.setTagId(tid);
            noteTagsMapper.insert(nt);
        }
    }

    private List<Map<String, String>> getNoteTags(UUID noteId) {
        List<NoteTags> rels = noteTagsMapper.selectList(
                new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getNoteId, noteId));
        if (rels.isEmpty()) return List.of();
        List<UUID> tagIds = rels.stream().map(NoteTags::getTagId).collect(Collectors.toList());
        List<Tags> tags = tagsMapper.selectList(new LambdaQueryWrapper<Tags>().in(Tags::getId, tagIds));
        return tags.stream().map(t -> Map.of("id", t.getId().toString(), "name", t.getName()))
                .collect(Collectors.toList());
    }

    private void saveVersion(Notes note, UUID userId) {
        // 5 分钟合并窗口
        NoteVersions latest = noteVersionsMapper.selectOne(
                new LambdaQueryWrapper<NoteVersions>()
                        .eq(NoteVersions::getNoteId, note.getId())
                        .orderByDesc(NoteVersions::getCreatedAt).last("LIMIT 1"));
        if (latest != null && latest.getCreatedAt().plusMinutes(VERSION_MERGE_MINUTES).isAfter(OffsetDateTime.now())) {
            latest.setTitle(note.getTitle());
            latest.setContent(note.getContent());
            latest.setFolderId(note.getFolderId());
            latest.setTagIds(getTagIdList(note.getId()));
            latest.setCreatedAt(OffsetDateTime.now());
            noteVersionsMapper.updateById(latest);
            return;
        }
        NoteVersions v = new NoteVersions();
        v.setId(UUID.randomUUID());
        v.setNoteId(note.getId());
        v.setUserId(userId);
        v.setTitle(note.getTitle());
        v.setContent(note.getContent());
        v.setFolderId(note.getFolderId());
        v.setTagIds(getTagIdList(note.getId()));
        v.setCreatedAt(OffsetDateTime.now());
        noteVersionsMapper.insert(v);
    }

    private List<UUID> getTagIdList(UUID noteId) {
        List<NoteTags> rels = noteTagsMapper.selectList(
                new LambdaQueryWrapper<NoteTags>().eq(NoteTags::getNoteId, noteId));
        return rels.stream().map(NoteTags::getTagId).collect(Collectors.toList());
    }

    private String buildSearchText(String title, String content) {
        StringBuilder sb = new StringBuilder();
        if (title != null) sb.append(title);
        if (content != null) {
            String text = content.replaceAll("<[^>]*>", " ").replaceAll("\\s+", " ").trim();
            if (sb.length() > 0) sb.append(" ");
            sb.append(text);
        }
        return sb.toString();
    }

    private String getFolderPath(UUID folderId, UUID userId) {
        if (folderId == null) return "/";
        Folders f = foldersMapper.selectById(folderId);
        if (f == null) return "/";
        return "/" + f.getName();
    }

    private Map<String, Object> buildNoteSummary(Notes n, UUID uid) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", n.getId().toString());
        m.put("folder_id", n.getFolderId() != null ? n.getFolderId().toString() : null);
        m.put("sort_order", n.getSortOrder());
        m.put("title", n.getTitle());
        String c = n.getContent() != null ? n.getContent() : "";
        m.put("content_preview", c.length() > 200 ? c.substring(0, 200) : c);
        m.put("visibility", n.getVisibility());
        m.put("published_at", n.getPublishedAt());
        m.put("created_at", n.getCreatedAt());
        m.put("updated_at", n.getUpdatedAt());
        m.put("tags", getNoteTags(n.getId()));
        return m;
    }

    private Map<String, Object> buildNoteDetail(Notes n, UUID uid) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", n.getId().toString());
        m.put("folder_id", n.getFolderId() != null ? n.getFolderId().toString() : null);
        m.put("sort_order", n.getSortOrder());
        m.put("title", n.getTitle());
        m.put("content", n.getContent());
        m.put("visibility", n.getVisibility());
        m.put("published_at", n.getPublishedAt());
        m.put("created_at", n.getCreatedAt());
        m.put("updated_at", n.getUpdatedAt());
        m.put("tags", getNoteTags(n.getId()));
        return m;
    }
}
