package com.haven.backend.service;

import com.haven.backend.entity.Folders;

import java.util.List;
import java.util.UUID;

public interface FoldersService {
    List<Folders> listFolders(String userId);
    Folders createFolder(String userId, String name, UUID parentId, String icon);
    Folders updateFolder(String userId, UUID folderId, String name, UUID parentId, String icon, Integer sortOrder);
    void deleteFolder(String userId, UUID folderId);
}
