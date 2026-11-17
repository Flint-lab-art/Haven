package com.haven.backend.auth.util;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * TOTP 校验：固定时间点验证窗口、非法输入必须返回 false 而不是抛异常。
 */
class TotpUtilTest {

    private static final String SECRET = "JBSWY3DPEHPK3PXP";
    private static final long EPOCH_SECONDS = 1_700_000_000L;

    @Test
    @DisplayName("当前时间窗内的动态码校验通过")
    void currentCodeIsValid() {
        String code = TotpUtil.generateCurrentCode(SECRET, EPOCH_SECONDS);

        assertTrue(TotpUtil.verify(SECRET, code, EPOCH_SECONDS));
    }

    @Test
    @DisplayName("允许 ±1 步偏移")
    void windowTolerance() {
        String code = TotpUtil.generateCurrentCode(SECRET, EPOCH_SECONDS);

        assertTrue(TotpUtil.verify(SECRET, code, EPOCH_SECONDS + 30));
        assertTrue(TotpUtil.verify(SECRET, code, EPOCH_SECONDS - 30));
    }

    @Test
    @DisplayName("超出窗口的动态码视为失败")
    void outsideWindowIsInvalid() {
        String code = TotpUtil.generateCurrentCode(SECRET, EPOCH_SECONDS);

        assertFalse(TotpUtil.verify(SECRET, code, EPOCH_SECONDS + 300));
    }

    @Test
    @DisplayName("非法 Base32 secret 返回 false，不抛异常")
    void invalidSecretReturnsFalse() {
        assertFalse(TotpUtil.verify("not-base32!", "123456", EPOCH_SECONDS));
    }

    @Test
    @DisplayName("长度不为 6 位的动态码直接失败")
    void wrongLengthCodeReturnsFalse() {
        assertFalse(TotpUtil.verify(SECRET, "12345", EPOCH_SECONDS));
        assertFalse(TotpUtil.verify(SECRET, "1234567", EPOCH_SECONDS));
    }

    @Test
    @DisplayName("小写 secret 与空格也能校验")
    void secretIsNormalized() {
        String code = TotpUtil.generateCurrentCode(SECRET, EPOCH_SECONDS);

        assertTrue(TotpUtil.verify(" jbswy3dpehpk3pxp ", code, EPOCH_SECONDS));
    }
}
