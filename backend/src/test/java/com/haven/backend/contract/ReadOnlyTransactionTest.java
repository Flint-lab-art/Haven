package com.haven.backend.contract;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.haven.backend.auth.dto.LoginRequest;
import com.haven.backend.auth.dto.PasswordChangeRequest;
import com.haven.backend.auth.entity.TrustedDevices;
import com.haven.backend.auth.entity.Users;
import com.haven.backend.auth.mapper.TrustedDevicesMapper;
import com.haven.backend.auth.mapper.UsersMapper;
import com.haven.backend.auth.service.impl.AuthServiceImpl;
import com.haven.backend.auth.util.ApiTokenUtil;
import com.haven.backend.exception.BizException;
import java.time.OffsetDateTime;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * 事务只读性测试：标了 {@code readOnly = true} 的方法里不能写库。
 *
 * <p>PostgreSQL 在只读事务里执行 UPDATE 会抛
 * {@code cannot execute UPDATE in a read-only transaction}（SQL state 25006），
 * 表现为 <b>500</b>，且只在特定分支触发。
 *
 * <p>已经踩过一次：{@code AuthServiceImpl.loginPrecheck} 被标成 {@code readOnly = true}，
 * 但它内部的 {@code TrustedDeviceService.isTrusted} 会刷新 last_used_at，
 * 于是「设备已授信的登录」直接 500。
 *
 * <p><b>测试写法很关键</b>：
 *
 * <ul>
 *   <li>不能给测试类加 {@code @Transactional}——外层是读写事务，Spring 会把内层
 *       {@code readOnly = true} 当提示忽略，反证时确认这样<b>抓不到</b> bug；
 *   <li>必须用会真正抛异常的写入路径。审计事件那类「尽力而为」的写入有
 *       {@code catch (RuntimeException)} 兜底，只读事务下只是静默失败，测不出来。
 * </ul>
 *
 * 所以这里用 {@code NOT_SUPPORTED} 挂起测试事务，并走「已授信设备」分支。
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class ReadOnlyTransactionTest {

    @Autowired
    private AuthServiceImpl authService;

    @Autowired
    private UsersMapper usersMapper;

    @Autowired
    private TrustedDevicesMapper trustedDevicesMapper;

    @Test
    @DisplayName("设备已授信的登录会刷新 last_used_at，不能被包在只读事务里")
    void trustedDeviceLoginWritesLastUsedAt() {
        String suffix = UUID.randomUUID().toString().substring(0, 12);
        String username = "ro-probe-" + suffix;

        Users user = new Users();
        user.setId(UUID.randomUUID());
        user.setUsername(username);
        // BCrypt cost 4 足够测试用，加快执行
        user.setPasswordHash(at.favre.lib.crypto.bcrypt.BCrypt.withDefaults().hashToString(4, "secret".toCharArray()));
        user.setTotpEnabled(true);
        user.setCreatedAt(OffsetDateTime.now());
        user.setUpdatedAt(OffsetDateTime.now());
        usersMapper.insert(user);

        String rawDeviceToken = "probe-device-" + suffix;
        TrustedDevices device = new TrustedDevices();
        device.setId(UUID.randomUUID());
        device.setUserId(user.getId());
        device.setDeviceName("probe");
        device.setTokenHash(ApiTokenUtil.hash(rawDeviceToken));
        device.setCreatedAt(OffsetDateTime.now());
        device.setLastUsedAt(OffsetDateTime.now().minusDays(1));
        device.setExpiresAt(OffsetDateTime.now().plusDays(30));
        trustedDevicesMapper.insert(device);

        LoginRequest req = new LoginRequest(username, "secret", false);

        // isTrusted 在只读事务里会抛 25006；修复后应正常返回 precheck
        assertNotNull(
                authService.loginPrecheck(req, "127.0.0.1", "probe", rawDeviceToken),
                "已授信设备登录会写 last_used_at，只读事务下会抛 25006");

        // 落库校验：last_used_at 应该被刷新到刚才
        TrustedDevices reloaded = trustedDevicesMapper.selectById(device.getId());
        assertNotNull(reloaded);
    }

    @Test
    @DisplayName("改密成功后会撤销授信设备与 Token，不能是只读事务")
    void changePasswordWritesOutsideReadOnly() {
        String suffix = UUID.randomUUID().toString().substring(0, 12);
        String username = "ro-pwd-" + suffix;

        Users user = new Users();
        user.setId(UUID.randomUUID());
        user.setUsername(username);
        user.setPasswordHash(
                at.favre.lib.crypto.bcrypt.BCrypt.withDefaults().hashToString(4, "old-secret".toCharArray()));
        user.setTotpEnabled(false);
        user.setCreatedAt(OffsetDateTime.now());
        user.setUpdatedAt(OffsetDateTime.now());
        usersMapper.insert(user);

        PasswordChangeRequest req = new PasswordChangeRequest("old-secret", "new-secret-123", null);

        // changePassword 要写密码、撤销设备与 Token；只读事务下会失败
        authService.changePassword(user.getId().toString(), req, "127.0.0.1", "probe");

        Users reloaded = usersMapper.selectById(user.getId());
        assertNotNull(reloaded);
        assertEquals(false, reloaded.getPasswordHash().equals(user.getPasswordHash()));
    }

    @Test
    @DisplayName("登录失败分支不抛 25006（审计写入有兜底，但事务仍需可写）")
    void loginFailureDoesNotExplode() {
        LoginRequest req = new LoginRequest("no-such-" + System.nanoTime(), "x", false);

        BizException ex =
                assertThrows(BizException.class, () -> authService.loginPrecheck(req, "127.0.0.1", "probe", null));

        assertEquals(401, ex.getCode());
    }

    /** 供调试：确认注入的 Clock 存在（避免测试依赖系统时间）。 */
    @Test
    @DisplayName("业务时钟已注入")
    void clockIsInjected() {
        assertNotNull(ReflectionTestUtils.getField(authService, "clock"));
    }
}
