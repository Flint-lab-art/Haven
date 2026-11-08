package com.haven.backend.util;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.HexFormat;

/**
 * API Token 生成与哈希工具。
 * <p>
 * Token 格式：haven_{scope}_{32字节随机hex}，数据库只存 SHA-256 哈希，
 * 明文仅在创建时返回一次；另存前 8 位 token_prefix 供展示。
 */
public final class ApiTokenUtil {

    private static final int TOKEN_BYTES = 32;
    private static final int PREFIX_LEN = 8;
    private static final String PREFIX_RO = "haven_ro_";
    private static final String PREFIX_RW = "haven_rw_";
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private ApiTokenUtil() {}

    /**
     * 生成 API Token。
     *
     * @param scope "read" 或 "read_write"
     * @return [0]=完整明文, [1]=展示前缀
     */
    public static String[] generate(String scope) {
        byte[] bytes = new byte[TOKEN_BYTES];
        SECURE_RANDOM.nextBytes(bytes);
        String raw = HexFormat.of().formatHex(bytes);

        String prefix = ("read".equals(scope) ? PREFIX_RO : PREFIX_RW);
        String token = prefix + raw;
        String displayPrefix = token.substring(0, PREFIX_LEN);
        return new String[]{token, displayPrefix};
    }

    /**
     * 生成 32 字节随机十六进制串，用于授信设备令牌等不透明凭证。
     */
    public static String randomToken() {
        byte[] bytes = new byte[TOKEN_BYTES];
        SECURE_RANDOM.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    /**
     * 计算 token 的 SHA-256 哈希（小写十六进制），用于落库与按 token_hash 查询。
     */
    public static String hash(String token) {
        try {
            var digest = java.security.MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(token.getBytes()));
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 不可用", e);
        }
    }

    /**
     * HMAC-SHA256 签名。
     */
    public static String hmac(String data, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(), "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(data.getBytes()));
        } catch (NoSuchAlgorithmException | InvalidKeyException e) {
            throw new RuntimeException("HMAC-SHA256 不可用", e);
        }
    }
}
