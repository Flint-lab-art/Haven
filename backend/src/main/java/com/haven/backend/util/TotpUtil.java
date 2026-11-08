package com.haven.backend.util;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.ByteBuffer;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

/**
 * TOTP（RFC 6238）工具类。
 * <p>
 * 自行实现，避免引入额外依赖。算法：
 * 1. 生成随机 Base32 密钥
 * 2. 按 30 秒时间窗口计算 6 位动态码
 * 3. 验证时允许 ±1 步偏移（共 90 秒窗口）
 */
public final class TotpUtil {

    private static final int SECRET_BYTES = 20;
    private static final int CODE_DIGITS = 6;
    private static final int TIME_STEP_SECONDS = 30;
    private static final int WINDOW = 1; // 允许前后各 1 步
    private static final String HMAC_ALGO = "HmacSHA1";
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private static final String BASE32_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

    private TotpUtil() {}

    /**
     * 生成随机 TOTP secret（Base32 编码）。
     */
    public static String generateSecret() {
        byte[] bytes = new byte[SECRET_BYTES];
        SECURE_RANDOM.nextBytes(bytes);
        return base32Encode(bytes);
    }

    /**
     * 构造 otpauth:// URI，供二维码扫描。
     */
    public static String buildUri(String secret, String username, String issuer) {
        String encodedIssuer = URLEncoder.encode(issuer, java.nio.charset.StandardCharsets.UTF_8);
        String encodedName = URLEncoder.encode(username, java.nio.charset.StandardCharsets.UTF_8);
        return String.format("otpauth://totp/%s:%s?secret=%s&issuer=%s&digits=%d&period=%d",
                encodedIssuer, encodedName, secret, encodedIssuer, CODE_DIGITS, TIME_STEP_SECONDS);
    }

    /**
     * 校验 TOTP 动态码，允许 ±WINDOW 步时间偏移。
     */
    public static boolean verify(String secret, String code) {
        if (secret == null || code == null || code.length() != CODE_DIGITS) {
            return false;
        }
        int inputCode;
        try {
            inputCode = Integer.parseInt(code);
        } catch (NumberFormatException e) {
            return false;
        }

        long currentTimeStep = System.currentTimeMillis() / 1000 / TIME_STEP_SECONDS;
        byte[] decodedSecret = base32Decode(secret.toUpperCase());

        for (long i = -WINDOW; i <= WINDOW; i++) {
            int generated = generateCode(decodedSecret, currentTimeStep + i);
            if (generated == inputCode) {
                return true;
            }
        }
        return false;
    }

    // ---- 内部实现 ----

    private static int generateCode(byte[] secret, long timeStep) {
        byte[] timeBytes = ByteBuffer.allocate(8).putLong(timeStep).array();
        try {
            Mac mac = Mac.getInstance(HMAC_ALGO);
            mac.init(new SecretKeySpec(secret, HMAC_ALGO));
            byte[] hash = mac.doFinal(timeBytes);
            return truncate(hash);
        } catch (NoSuchAlgorithmException | InvalidKeyException e) {
            throw new RuntimeException("HMAC-SHA1 不可用", e);
        }
    }

    private static int truncate(byte[] hash) {
        int offset = hash[hash.length - 1] & 0x0F;
        return ((hash[offset] & 0x7F) << 24
                | (hash[offset + 1] & 0xFF) << 16
                | (hash[offset + 2] & 0xFF) << 8
                | (hash[offset + 3] & 0xFF))
                % (int) Math.pow(10, CODE_DIGITS);
    }

    private static String base32Encode(byte[] data) {
        StringBuilder sb = new StringBuilder();
        int buffer = 0;
        int bitsLeft = 0;
        for (byte b : data) {
            buffer = (buffer << 8) | (b & 0xFF);
            bitsLeft += 8;
            while (bitsLeft >= 5) {
                sb.append(BASE32_CHARS.charAt((buffer >> (bitsLeft - 5)) & 0x1F));
                bitsLeft -= 5;
            }
        }
        if (bitsLeft > 0) {
            sb.append(BASE32_CHARS.charAt((buffer << (5 - bitsLeft)) & 0x1F));
        }
        return sb.toString();
    }

    private static byte[] base32Decode(String base32) {
        String cleaned = base32.replaceAll("[=\\s]", "");
        int totalBits = cleaned.length() * 5;
        byte[] result = new byte[totalBits / 8];
        int buffer = 0;
        int bitsLeft = 0;
        int index = 0;
        for (char c : cleaned.toCharArray()) {
            int val = BASE32_CHARS.indexOf(c);
            if (val < 0) throw new IllegalArgumentException("非法 Base32 字符: " + c);
            buffer = (buffer << 5) | val;
            bitsLeft += 5;
            if (bitsLeft >= 8) {
                result[index++] = (byte) (buffer >> (bitsLeft - 8));
                bitsLeft -= 8;
            }
        }
        return result;
    }
}
