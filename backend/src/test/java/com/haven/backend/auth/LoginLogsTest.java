package com.haven.backend.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import at.favre.lib.crypto.bcrypt.BCrypt;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.auth.dto.LoginLogDtos.LoginLogPage;
import com.haven.backend.auth.dto.LoginRequest;
import com.haven.backend.auth.entity.LoginLogs;
import com.haven.backend.auth.entity.Users;
import com.haven.backend.auth.mapper.LoginLogsMapper;
import com.haven.backend.auth.mapper.UsersMapper;
import com.haven.backend.auth.service.AuthService;
import com.haven.backend.auth.service.LoginLogRecorder;
import com.haven.backend.auth.service.LoginLogService;
import com.haven.backend.exception.BizException;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * 登录日志的落库与查询。
 *
 * <p>最关键的一条：失败日志写在 {@code REQUIRES_NEW} 事务里，登录失败抛 401
 * 回滚外层事务时日志仍然保留。当前用例用 {@code Propagation.NOT_SUPPORTED}
 * 运行，让每次 {@code REQUIRES_NEW} 真正开独立事务，才能覆盖到这一点。
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class LoginLogsTest {

    private static final String PASSWORD = "login-logs-password";

    @Autowired
    private AuthService authService;

    @Autowired
    private LoginLogService loginLogService;

    @Autowired
    private LoginLogRecorder loginLogRecorder;

    @Autowired
    private LoginLogsMapper loginLogsMapper;

    @Autowired
    private UsersMapper usersMapper;

    /** 建一个关闭 TOTP 的真实用户，BCrypt cost 4 加快测试。 */
    private Users insertUser() {
        String username = "loginlog-" + UUID.randomUUID().toString().substring(0, 8);
        Users user = new Users();
        user.setId(UUID.randomUUID());
        user.setUsername(username);
        user.setPasswordHash(BCrypt.withDefaults().hashToString(4, PASSWORD.toCharArray()));
        user.setTotpEnabled(false);
        user.setCreatedAt(OffsetDateTime.now());
        user.setUpdatedAt(OffsetDateTime.now());
        usersMapper.insert(user);
        return user;
    }

    private List<LoginLogs> logsFor(UUID userId) {
        return loginLogsMapper.selectList(new LambdaQueryWrapper<LoginLogs>().eq(LoginLogs::getUserId, userId));
    }

    @Test
    @DisplayName("密码错误：401 之后失败日志仍然落库")
    void failedPasswordIsLoggedAfterRollback() {
        Users user = insertUser();

        BizException ex = assertThrows(
                BizException.class,
                () -> authService.login(new LoginRequest(user.getUsername(), "wrong", false), "10.0.0.1", "ua", null));
        assertEquals(401, ex.getCode());

        List<LoginLogs> logs = logsFor(user.getId());
        assertEquals(1, logs.size());
        LoginLogs log = logs.getFirst();
        assertEquals("login_failure", log.getEventType());
        assertEquals("bad_password", log.getFailureReason());
        assertFalse(log.isSuccess());
        assertEquals("10.0.0.1", log.getIp());
    }

    @Test
    @DisplayName("用户名不存在：日志记下用户名快照，user_id 为空")
    void unknownUserIsLoggedWithoutUserId() {
        String username = "ghost-" + UUID.randomUUID().toString().substring(0, 8);

        assertThrows(
                BizException.class,
                () -> authService.login(new LoginRequest(username, PASSWORD, false), "10.0.0.2", "ua", null));

        List<LoginLogs> logs =
                loginLogsMapper.selectList(new LambdaQueryWrapper<LoginLogs>().eq(LoginLogs::getUsername, username));
        assertEquals(1, logs.size());
        assertEquals(null, logs.getFirst().getUserId());
        assertEquals("unknown_user", logs.getFirst().getFailureReason());
    }

    @Test
    @DisplayName("查询：按 user_id 或同名失败尝试过滤，不返回 session_hash")
    void listIncludesSameUsernameFailures() {
        Users user = insertUser();
        // 一次失败 + 一次成功
        assertThrows(
                BizException.class,
                () -> authService.login(new LoginRequest(user.getUsername(), "wrong", false), "10.0.0.3", "ua", null));
        // 成功日志由 AuthSessionOpener 在建立会话后写入；这里模拟同一段调用
        loginLogRecorder.record(
                LoginLogEventType.LOGIN_SUCCESS,
                user.getId(),
                user.getUsername(),
                "password",
                true,
                null,
                "10.0.0.3",
                "ua",
                null);

        LoginLogPage page = loginLogService.list(user.getId().toString(), 20, 0);
        assertEquals(2, page.total());
        assertTrue(page.items().stream().allMatch(item -> item.username().equals(user.getUsername())));
        // 找到那条成功记录，它的 session_hash 不应出现在 DTO 里（DTO 根本没有这个字段）
        assertTrue(page.items().stream().anyMatch(item -> item.success()));
        assertNotNull(page.items().getFirst().createdAt());

        // 分页
        LoginLogPage first = loginLogService.list(user.getId().toString(), 1, 0);
        assertEquals(1, first.items().size());
        assertEquals(2, first.total());
    }
}
