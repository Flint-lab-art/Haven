package com.haven.backend.note.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.haven.backend.exception.BizException;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.test.util.ReflectionTestUtils;

/**
 * 上传校验测试：拒绝空文件、超大文件和伪造图片，并保证文件名不可预测。
 */
class UploadsServiceImplTest {
    /** 固定时钟，避免文件名里的日期目录随运行时间变化。 */
    private static final Clock FIXED_CLOCK = Clock.fixed(Instant.parse("2026-01-02T03:04:05Z"), ZoneOffset.UTC);

    @TempDir
    java.nio.file.Path uploadRoot;

    private UploadsServiceImpl uploadsService;

    @BeforeEach
    void setUp() {
        uploadsService = new UploadsServiceImpl(FIXED_CLOCK);
        ReflectionTestUtils.setField(uploadsService, "uploadRoot", uploadRoot.toString());
    }

    @Test
    @DisplayName("空文件返回 422")
    void emptyFileIsRejected() {
        BizException ex = assertThrows(BizException.class, () -> uploadsService.upload(new byte[0], "a.png", "note"));

        assertEquals(422, ex.getCode());
    }

    @Test
    @DisplayName("超过 10 MiB 返回 413")
    void oversizedFileIsRejected() {
        byte[] data = new byte[(10 << 20) + 1];

        BizException ex = assertThrows(BizException.class, () -> uploadsService.upload(data, "a.png", "note"));

        assertEquals(413, ex.getCode());
    }

    @Test
    @DisplayName("魔数与图片无关时返回 415")
    void nonImageIsRejected() {
        BizException ex = assertThrows(
                BizException.class, () -> uploadsService.upload(new byte[] {1, 2, 3, 4, 5, 6}, "a.png", "note"));

        assertEquals(415, ex.getCode());
    }

    @Test
    @DisplayName("合法 PNG 落盘，返回 url 且文件名为 32 位随机十六进制")
    void pngIsStoredWithRandomName() throws IOException {
        byte[] png = onePixelPng();

        var result = uploadsService.upload(png, "a.png", "note");

        String url = result.url();
        assertTrue(url.startsWith("/uploads/notes/"), url);
        String fileName = url.substring(url.lastIndexOf('/') + 1);
        assertTrue(fileName.matches("[0-9a-f]{32}\\.png"), fileName);
    }

    private byte[] onePixelPng() throws IOException {
        BufferedImage image = new BufferedImage(1, 1, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "png", out);
        return out.toByteArray();
    }
}
