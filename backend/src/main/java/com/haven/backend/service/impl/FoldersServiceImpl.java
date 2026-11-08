package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.entity.Folders;
import com.haven.backend.entity.Notes;
import com.haven.backend.exception.BizException;
import com.haven.backend.mapper.FoldersMapper;
import com.haven.backend.mapper.NotesMapper;
import com.haven.backend.service.FoldersService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FoldersServiceImpl implements FoldersService {

    private final FoldersMapper foldersMapper;
    private final NotesMapper notesMapper;

    @Override
    public List<Folders> listFolders(String userId) {
        UUID uid = UUID.fromString(userId);
        return foldersMapper.selectList(
                new LambdaQueryWrapper<Folders>()
                        .eq(Folders::getUserId, uid)
                        .orderByAsc(Folders::getSortOrder));
    }

    @Override
    public Folders createFolder(String userId, String name, UUID parentId, String icon) {
        UUID uid = UUID.fromString(userId);
        validateName(name);
        checkDuplicateName(uid, parentId, name, null);

        int maxOrder = getMaxSortOrder(uid, parentId);
        Folders folder = new Folders();
        folder.setId(UUID.randomUUID());
        folder.setUserId(uid);
        folder.setParentId(parentId);
        folder.setName(name.trim());
        folder.setIcon(icon);
        folder.setIsInbox(false);
        folder.setSortOrder(maxOrder + 1);
        folder.setCreatedAt(OffsetDateTime.now());
        folder.setUpdatedAt(OffsetDateTime.now());
        foldersMapper.insert(folder);
        return folder;
    }

    @Override
    public Folders updateFolder(String userId, UUID folderId, String name, UUID parentId, String icon, Integer sortOrder) {
        UUID uid = UUID.fromString(userId);
        Folders folder = getOwnedFolder(uid, folderId);
        if (Boolean.TRUE.equals(folder.getIsInbox())) {
            if (parentId != null) throw BizException.validation("收件箱不能移动");
            if (name != null && !name.isBlank()) throw BizException.validation("收件箱不能重命名");
        }

        if (name != null) {
            validateName(name);
            checkDuplicateName(uid, parentId != null ? parentId : folder.getParentId(), name, folderId);
            folder.setName(name.trim());
        }
        if (parentId != null) {
            if (parentId.equals(folderId)) throw BizException.validation("不能将文件夹移动到自身下");
            checkCycle(folderId, parentId, uid);
            folder.setParentId(parentId);
        }
        if (icon != null) folder.setIcon(icon);
        if (sortOrder != null) folder.setSortOrder(sortOrder);
        folder.setUpdatedAt(OffsetDateTime.now());
        foldersMapper.updateById(folder);
        return folder;
    }

    @Override
    @Transactional
    public void deleteFolder(String userId, UUID folderId) {
        UUID uid = UUID.fromString(userId);
        Folders folder = getOwnedFolder(uid, folderId);
        if (Boolean.TRUE.equals(folder.getIsInbox())) throw BizException.validation("收件箱不能删除");

        // 找到用户的收件箱 ID，用于迁移笔记
        UUID inboxId = getInboxId(uid);

        // 级联删除子文件夹 + 迁移笔记
        cascadeDelete(uid, folderId, inboxId);
        foldersMapper.deleteById(folderId);
    }

    // ---- 内部方法 ----

    private void cascadeDelete(UUID userId, UUID folderId, UUID inboxId) {
        List<Folders> children = foldersMapper.selectList(
                new LambdaQueryWrapper<Folders>()
                        .eq(Folders::getParentId, folderId)
                        .eq(Folders::getUserId, userId));
        for (Folders child : children) {
            cascadeDelete(userId, child.getId(), inboxId);
            foldersMapper.deleteById(child.getId());
        }
        // 将此文件夹下的笔记移到收件箱
        Notes noteUpdate = new Notes();
        noteUpdate.setFolderId(inboxId);
        notesMapper.update(noteUpdate,
                new LambdaQueryWrapper<Notes>()
                        .eq(Notes::getFolderId, folderId)
                        .eq(Notes::getUserId, userId));
    }

    private UUID getInboxId(UUID userId) {
        Folders inbox = foldersMapper.selectOne(
                new LambdaQueryWrapper<Folders>()
                        .eq(Folders::getUserId, userId)
                        .eq(Folders::getIsInbox, true));
        if (inbox == null) throw BizException.internal("收件箱不存在");
        return inbox.getId();
    }

    private void validateName(String name) {
        if (name == null || name.trim().isEmpty()) throw BizException.validation("文件夹名称不能为空");
        if (name.trim().length() > 32) throw BizException.validation("文件夹名称不能超过超过 32 个字符");
    }

    private void checkDuplicateName(UUID userId, UUID parentId, String name, UUID excludeId) {
        var wrapper = new LambdaQueryWrapper<Folders>()
                .eq(Folders::getUserId, userId)
                .eq(Folders::getName, name.trim())
                .apply(parentId == null ? "parent_id IS NULL" : "parent_id = {0}", parentId);
        if (excludeId != null) wrapper.ne(Folders::getId, excludeId);
        if (foldersMapper.selectCount(wrapper) > 0) {
            throw BizException.conflict("同名文件夹已存在");
        }
    }

    private void checkCycle(UUID folderId, UUID newParentId, UUID userId) {
        UUID current = newParentId;
        Set<UUID> visited = new HashSet<>();
        while (current != null) {
            if (current.equals(folderId)) throw BizException.validation("不能将文件夹移动到自身的子文件夹下");
            if (!visited.add(current)) break;
            Folders parent = foldersMapper.selectById(current);
            if (parent == null || !parent.getUserId().equals(userId)) break;
            current = parent.getParentId();
        }
    }

    private int getMaxSortOrder(UUID userId, UUID parentId) {
        var wrapper = new LambdaQueryWrapper<Folders>()
                .eq(Folders::getUserId, userId)
                .orderByDesc(Folders::getSortOrder)
                .last("LIMIT 1");
        if (parentId == null) {
            wrapper.apply("parent_id IS NULL");
        } else {
            wrapper.eq(Folders::getParentId, parentId);
        }
        Folders max = foldersMapper.selectOne(wrapper);
        return max != null && max.getSortOrder() != null ? max.getSortOrder() : 0;
    }

    private Folders getOwnedFolder(UUID userId, UUID folderId) {
        Folders folder = foldersMapper.selectById(folderId);
        if (folder == null || !folder.getUserId().equals(userId)) {
            throw BizException.notFound("文件夹不存在");
        }
        return folder;
    }
}
