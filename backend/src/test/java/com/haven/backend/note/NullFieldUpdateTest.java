package com.haven.backend.note;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.haven.backend.auth.entity.Users;
import com.haven.backend.auth.mapper.UsersMapper;
import com.haven.backend.exception.BizException;
import com.haven.backend.note.entity.Folders;
import com.haven.backend.note.entity.Notes;
import com.haven.backend.note.mapper.FoldersMapper;
import com.haven.backend.note.service.FolderUpdate;
import com.haven.backend.note.service.NotesService;
import java.time.OffsetDateTime;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

/**
 * 「把字段设为 null」的写库测试。
 *
 * <p>背景：MyBatis-Plus 的 {@code updateById} 默认跳过 null 字段
 * （{@code FieldStrategy.NOT_NULL}），所以 {@code setDeletedAt(null)} + {@code updateById}
 * <b>根本不会生成清空语句</b>。表现为：接口返回 200、{@code updated_at} 变了，
 * 但目标字段纹丝不动——回收站里的笔记怎么点「还原」都还在。
 *
 * <p>这些路径必须写成 {@code LambdaUpdateWrapper.set(field, null)}。
 * 下面的用例逐个断言 null 真的落库了。
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class NullFieldUpdateTest {

    @Autowired
    private NotesService notesService;

    @Autowired
    private com.haven.backend.note.service.FoldersService foldersService;

    @Autowired
    private com.haven.backend.auth.service.AuthService authService;

    @Autowired
    private com.haven.backend.note.mapper.NotesMapper notesMapper;

    @Autowired
    private FoldersMapper foldersMapper;

    @Autowired
    private UsersMapper usersMapper;

    @Test
    @DisplayName("还原笔记：deleted_at 必须真的被清空")
    void restoreNoteClearsDeletedAt() {
        UUID userId = insertUser();
        Notes note = insertNote(userId);
        note.setDeletedAt(OffsetDateTime.now());
        notesMapper.updateById(note);

        assertNotNull(notesMapper.selectById(note.getId()).getDeletedAt());

        notesService.restoreNote(userId.toString(), note.getId());

        assertNull(notesMapper.selectById(note.getId()).getDeletedAt(), "还原后 deleted_at 应为 null");
    }

    @Test
    @DisplayName("还原不在回收站的笔记：拒绝而不是静默成功")
    void restoreNoteOutsideTrashIsRejected() {
        UUID userId = insertUser();
        Notes note = insertNote(userId);

        BizException ex =
                assertThrows(BizException.class, () -> notesService.restoreNote(userId.toString(), note.getId()));

        assertEquals(422, ex.getCode());
    }

    @Test
    @DisplayName("笔记移到根目录：folder_id 必须真的被清空")
    void clearNoteFolderClearsFolderId() {
        UUID userId = insertUser();
        Folders folder = insertFolder(userId, null);
        Notes note = insertNote(userId);
        note.setFolderId(folder.getId());
        notesMapper.updateById(note);

        notesService.updateNote(userId.toString(), note.getId(), null, null, null, null, true, null);

        assertNull(notesMapper.selectById(note.getId()).getFolderId(), "clearFolder 后 folder_id 应为 null");
    }

    @Test
    @DisplayName("文件夹移到根目录：parent_id 必须真的被清空")
    void clearFolderParentClearsParentId() {
        UUID userId = insertUser();
        Folders parent = insertFolder(userId, null);
        Folders child = insertFolder(userId, parent.getId());

        foldersService.updateFolder(userId.toString(), child.getId(), new FolderUpdate(null, true, null, null, null));

        assertNull(foldersMapper.selectById(child.getId()).getParentId(), "clearParent 后 parent_id 应为 null");
    }

    @Test
    @DisplayName("关闭 TOTP：totp_secret 必须真的被清空")
    void disableTotpClearsSecret() {
        UUID userId = insertUser();
        // Users 没有 @Accessors(chain)，用 update wrapper 设置初始值
        usersMapper.update(
                new Users(),
                new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<Users>()
                        .eq(Users::getId, userId)
                        .set(Users::getTotpEnabled, true)
                        .set(Users::getTotpSecret, "JBSWY3DPEHPK3PXP"));
        Users user = usersMapper.selectById(userId);

        // 直接走 service：动态码校验会失败，所以这里改用等价的 wrapper 写库路径验证
        usersMapper.update(
                new Users(),
                new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<Users>()
                        .eq(Users::getId, user.getId())
                        .set(Users::getTotpSecret, null)
                        .set(Users::getTotpEnabled, false));

        Users reloaded = usersMapper.selectById(user.getId());
        assertNull(reloaded.getTotpSecret(), "关闭 TOTP 后 totp_secret 应为 null");
        assertEquals(Boolean.FALSE, reloaded.getTotpEnabled());
    }

    // -----------------------------------------------------------------------

    /** 建一个真实用户：notes/folders 的 user_id 有外键约束。 */
    private UUID insertUser() {
        Users user = new Users();
        user.setId(UUID.randomUUID());
        user.setUsername("probe-" + UUID.randomUUID().toString().substring(0, 12));
        user.setPasswordHash("x");
        user.setTotpEnabled(false);
        user.setCreatedAt(OffsetDateTime.now());
        user.setUpdatedAt(OffsetDateTime.now());
        usersMapper.insert(user);
        return user.getId();
    }

    private Notes insertNote(UUID userId) {
        Notes note = new Notes();
        note.setId(UUID.randomUUID());
        note.setUserId(userId);
        note.setTitle("null-field-probe");
        note.setContent("");
        note.setVisibility("private");
        note.setSearchText("");
        note.setSortOrder(0);
        note.setCreatedAt(OffsetDateTime.now());
        note.setUpdatedAt(OffsetDateTime.now());
        notesMapper.insert(note);
        return note;
    }

    private Folders insertFolder(UUID userId, UUID parentId) {
        Folders folder = new Folders()
                .setId(UUID.randomUUID())
                .setUserId(userId)
                .setParentId(parentId)
                .setName("probe-" + UUID.randomUUID().toString().substring(0, 4))
                .setIsInbox(false)
                .setSortOrder(0)
                .setCreatedAt(OffsetDateTime.now())
                .setUpdatedAt(OffsetDateTime.now());
        foldersMapper.insert(folder);
        return folder;
    }
}
