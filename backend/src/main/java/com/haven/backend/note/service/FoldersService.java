package com.haven.backend.note.service;

import java.util.List;
import java.util.UUID;

import com.haven.backend.note.entity.Folders;

public interface FoldersService {
    List<Folders> listFolders(String userId);

    Folders createFolder(String userId, String name, UUID parentId, String icon);

    Folders updateFolder(String userId, UUID folderId, String name, UUID parentId, String icon, Integer sortOrder);

    void deleteFolder(String userId, UUID folderId);
}
