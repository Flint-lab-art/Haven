package com.haven.backend.note.service;

import com.haven.backend.note.entity.Folders;
import java.util.List;
import java.util.UUID;

public interface FoldersService {
    List<Folders> listFolders(String userId);

    Folders createFolder(String userId, String name, UUID parentId, String icon);

    Folders updateFolder(String userId, UUID folderId, FolderUpdate update);

    void deleteFolder(String userId, UUID folderId);
}
