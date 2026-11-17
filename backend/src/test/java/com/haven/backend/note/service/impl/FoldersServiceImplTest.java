package com.haven.backend.note.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.haven.backend.exception.BizException;
import com.haven.backend.note.entity.Folders;
import com.haven.backend.note.mapper.FoldersMapper;
import com.haven.backend.note.mapper.NotesMapper;
import com.haven.backend.note.service.FolderUpdate;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * 文件夹归属校验：父文件夹必须属于当前用户，禁止跨用户挂载。
 */
@ExtendWith(MockitoExtension.class)
class FoldersServiceImplTest {

    @Mock
    private FoldersMapper foldersMapper;

    @Mock
    private NotesMapper notesMapper;

    @InjectMocks
    private FoldersServiceImpl foldersService;

    @Test
    @DisplayName("创建文件夹时不能挂到他人文件夹下")
    void createFolder_withForeignParent_throwsNotFound() {
        Folders foreign = folder(UUID.randomUUID(), UUID.randomUUID());
        when(foldersMapper.selectById(foreign.getId())).thenReturn(foreign);

        BizException ex = assertThrows(
                BizException.class,
                () -> foldersService.createFolder(UUID.randomUUID().toString(), "child", foreign.getId(), null));

        assertEquals(404, ex.getCode());
        verify(foldersMapper, never()).insert(any(Folders.class));
    }

    @Test
    @DisplayName("移动文件夹时不能挂到他人文件夹下")
    void updateFolder_withForeignParent_throwsNotFound() {
        UUID userId = UUID.randomUUID();
        Folders own = folder(UUID.randomUUID(), userId);
        Folders foreign = folder(UUID.randomUUID(), UUID.randomUUID());
        when(foldersMapper.selectById(own.getId())).thenReturn(own);
        when(foldersMapper.selectById(foreign.getId())).thenReturn(foreign);

        BizException ex = assertThrows(
                BizException.class,
                () -> foldersService.updateFolder(
                        userId.toString(), own.getId(), new FolderUpdate(foreign.getId(), false, null, null, null)));

        assertEquals(404, ex.getCode());
        verify(foldersMapper, never()).updateById(any(Folders.class));
    }

    private static Folders folder(UUID id, UUID userId) {
        return new Folders().setId(id).setUserId(userId).setName("folder").setIsInbox(false);
    }
}
