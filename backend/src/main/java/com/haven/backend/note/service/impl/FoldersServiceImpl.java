package com.haven.backend.note.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.spring.service.impl.ServiceImpl;
import com.haven.backend.exception.BizException;
import com.haven.backend.note.entity.Folders;
import com.haven.backend.note.entity.Notes;
import com.haven.backend.note.mapper.FoldersMapper;
import com.haven.backend.note.mapper.NotesMapper;
import com.haven.backend.note.service.FolderUpdate;
import com.haven.backend.note.service.FoldersService;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class FoldersServiceImpl extends ServiceImpl<FoldersMapper, Folders> implements FoldersService {

    private final FoldersMapper foldersMapper;
    private final Clock clock;
    private final NotesMapper notesMapper;

    @Override
    @Transactional(readOnly = true)
    public List<Folders> listFolders(String userId) {
        UUID uid = UUID.fromString(userId);
        return list(
                new LambdaQueryWrapper<Folders>().eq(Folders::getUserId, uid).orderByAsc(Folders::getSortOrder));
    }

    @Override
    @Transactional
    public Folders createFolder(String userId, String name, UUID parentId, String icon) {
        UUID uid = UUID.fromString(userId);
        validateName(name);
        // 父文件夹必须属于当前用户，否则会形成跨租户引用
        requireOwnedParent(uid, parentId);
        checkDuplicateName(uid, parentId, name, null);

        int maxOrder = getMaxSortOrder(uid, parentId);
        Folders folder = new Folders();
        folder.setId(UUID.randomUUID())
                .setUserId(uid)
                .setParentId(parentId)
                .setName(name.trim())
                .setIcon(icon)
                .setIsInbox(false)
                .setSortOrder(maxOrder + 1)
                .setCreatedAt(OffsetDateTime.now(clock))
                .setUpdatedAt(OffsetDateTime.now(clock));
        save(folder);
        return folder;
    }

    @Override
    @Transactional
    public Folders updateFolder(String userId, UUID folderId, FolderUpdate update) {
        UUID uid = UUID.fromString(userId);
        String name = update.name();
        UUID parentId = update.parentId();
        String icon = update.icon();
        Integer sortOrder = update.sortOrder();
        Folders folder = getOwnedFolder(uid, folderId);
        if (Boolean.TRUE.equals(folder.getIsInbox())) {
            if (parentId != null) {
                throw BizException.validation("收件箱不能移动");
            }
            if (name != null && !name.isBlank()) {
                throw BizException.validation("收件箱不能重命名");
            }
        }

        if (name != null) {
            validateName(name);
            checkDuplicateName(uid, parentId != null ? parentId : folder.getParentId(), name, folderId);
            folder.setName(name.trim());
        }
        if (parentId != null) {
            if (parentId.equals(folderId)) {
                throw BizException.validation("不能将文件夹移动到自身下");
            }
            requireOwnedParent(uid, parentId);
            checkCycle(folderId, parentId, uid);
            folder.setParentId(parentId);
        } else if (update.clearParent()) {
            // updateById 跳过 null 字段，移到根目录必须用 UpdateWrapper 显式 set null
            foldersMapper.update(
                    new Folders(),
                    new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<Folders>()
                            .eq(Folders::getId, folderId)
                            .eq(Folders::getUserId, uid)
                            .set(Folders::getParentId, null));
            folder.setParentId(null);
        }
        if (icon != null) {
            folder.setIcon(icon);
        }
        if (sortOrder != null) {
            folder.setSortOrder(sortOrder);
        }
        folder.setUpdatedAt(OffsetDateTime.now(clock));
        updateById(folder);
        return folder;
    }

    @Override
    @Transactional
    public void deleteFolder(String userId, UUID folderId) {
        UUID uid = UUID.fromString(userId);
        Folders folder = getOwnedFolder(uid, folderId);
        if (Boolean.TRUE.equals(folder.getIsInbox())) {
            throw BizException.validation("收件箱不能删除");
        }

        // 找到用户的收件箱 ID，用于迁移笔记
        UUID inboxId = getInboxId(uid);

        // 级联删除子文件夹 + 迁移笔记
        cascadeDelete(uid, folderId, inboxId);
        foldersMapper.deleteById(folderId);
    }

    // ---- 内部方法 ----

    private void cascadeDelete(UUID userId, UUID folderId, UUID inboxId) {
        List<Folders> children = foldersMapper.selectList(new LambdaQueryWrapper<Folders>()
                .eq(Folders::getParentId, folderId)
                .eq(Folders::getUserId, userId));
        for (Folders child : children) {
            cascadeDelete(userId, child.getId(), inboxId);
            foldersMapper.deleteById(child.getId());
        }
        // 将此文件夹下的笔记移到收件箱
        Notes noteUpdate = new Notes();
        noteUpdate.setFolderId(inboxId);
        notesMapper.update(
                noteUpdate,
                new LambdaQueryWrapper<Notes>().eq(Notes::getFolderId, folderId).eq(Notes::getUserId, userId));
    }

    private UUID getInboxId(UUID userId) {
        Folders inbox = foldersMapper.selectOne(
                new LambdaQueryWrapper<Folders>().eq(Folders::getUserId, userId).eq(Folders::getIsInbox, true));
        if (inbox == null) {
            throw BizException.internal("收件箱不存在");
        }
        return inbox.getId();
    }

    private void validateName(String name) {
        if (name == null || name.trim().isEmpty()) {
            throw BizException.validation("文件夹名称不能为空");
        }
        if (name.trim().length() > 32) {
            throw BizException.validation("文件夹名称不能超过 32 个字符");
        }
    }

    private void checkDuplicateName(UUID userId, UUID parentId, String name, UUID excludeId) {
        LambdaQueryWrapper<Folders> wrapper =
                new LambdaQueryWrapper<Folders>().eq(Folders::getUserId, userId).eq(Folders::getName, name.trim());

        if (parentId == null) {
            wrapper.isNull(Folders::getParentId);
        } else {
            wrapper.eq(Folders::getParentId, parentId);
        }

        if (excludeId != null) {
            wrapper.ne(Folders::getId, excludeId);
        }

        if (foldersMapper.selectCount(wrapper) > 0) {
            throw BizException.conflict("同名文件夹已存在");
        }
    }

    private void checkCycle(UUID folderId, UUID newParentId, UUID userId) {
        UUID current = newParentId;
        Set<UUID> visited = new HashSet<>();
        while (current != null) {
            if (current.equals(folderId)) {
                throw BizException.validation("不能将文件夹移动到自身的子文件夹下");
            }
            if (!visited.add(current)) {
                break;
            }
            Folders parent = foldersMapper.selectById(current);
            if (parent == null || !parent.getUserId().equals(userId)) {
                // 祖先链出现非本人（或悬空）引用属于数据异常，直接拒绝，避免越权挂载
                throw BizException.notFound("文件夹不存在");
            }
            current = parent.getParentId();
        }
    }

    private int getMaxSortOrder(UUID userId, UUID parentId) {
        var wrapper = new LambdaQueryWrapper<Folders>()
                .eq(Folders::getUserId, userId)
                .orderByDesc(Folders::getSortOrder)
                .last("LIMIT 1");
        if (parentId == null) {
            wrapper.isNull(Folders::getParentId);
        } else {
            wrapper.eq(Folders::getParentId, parentId);
        }
        Folders max = foldersMapper.selectOne(wrapper);
        return max != null && max.getSortOrder() != null ? max.getSortOrder() : 0;
    }

    /** 父文件夹必须存在且属于当前用户。 */
    private void requireOwnedParent(UUID userId, UUID parentId) {
        if (parentId != null) {
            getOwnedFolder(userId, parentId);
        }
    }

    private Folders getOwnedFolder(UUID userId, UUID folderId) {
        Folders folder = foldersMapper.selectById(folderId);
        if (folder == null || !folder.getUserId().equals(userId)) {
            throw BizException.notFound("文件夹不存在");
        }
        return folder;
    }
}
