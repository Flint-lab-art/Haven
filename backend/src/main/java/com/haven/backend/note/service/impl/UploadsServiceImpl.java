package com.haven.backend.note.service.impl;

import com.haven.backend.exception.BizException;
import com.haven.backend.note.service.UploadsService;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Stream;

@Slf4j
@Service
public class UploadsServiceImpl implements UploadsService {

    private static final long MAX_UPLOAD_BYTES = 10L << 20; // 10 MiB
    private static final Set<String> ALLOWED_MIMES = Set.of(
            "image/png", "image/jpeg", "image/gif", "image/webp");
    private static final Map<String, String> MIME_EXT = Map.of(
            "image/png", ".png", "image/jpeg", ".jpg", "image/gif", ".gif", "image/webp", ".webp");
    private static final Map<String, String> KIND_DIR = Map.of("note", "notes", "icon", "icons");

    @Value("${haven.upload-dir:uploads}")
    private String uploadRoot;

    @Override
    public Map<String, Object> upload(byte[] data, String originalName, String kind) {
        if (data == null || data.length == 0)
            throw BizException.validation("文件为空");
        if (data.length > MAX_UPLOAD_BYTES)
            throw new BizException(413, "文件超过 10 MiB");

        // 检测真实 MIME
        String detectedMime = detectMime(data);
        if (detectedMime == null || !ALLOWED_MIMES.contains(detectedMime)) {
            throw new BizException(415, "只支持 png / jpeg / gif / webp 图片");
        }

        String normalizedKind = normalizeKind(kind);
        String ext = MIME_EXT.get(detectedMime);
        LocalDateTime now = LocalDateTime.now();

        String subDir = KIND_DIR.get(normalizedKind) + "/" +
                now.format(DateTimeFormatter.ofPattern("yyyy/MM"));
        String fileName = randomHex(16) + ext;

        Path dir = Path.of(uploadRoot, subDir);
        try {
            Files.createDirectories(dir);
        } catch (IOException e) {
            throw BizException.internal("创建上传目录失败");
        }

        Path target = dir.resolve(fileName);
        Path tmp = dir.resolve(fileName + ".part");
        try {
            Files.write(tmp, data, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
            Files.move(tmp, target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            try {
                Files.deleteIfExists(tmp);
            } catch (IOException ignored) {
            }
            throw BizException.internal("保存上传文件失败");
        }

        String url = "/uploads/" + subDir + "/" + fileName;
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("url", url);
        result.put("name", originalName != null ? originalName : fileName);
        result.put("size", (long) data.length);
        result.put("mime", detectedMime);
        return result;
    }

    @Override
    public Map<String, Object> listIcons(int limit) {
        int lim = Math.min(limit <= 0 ? 60 : limit, 200);
        Path iconRoot = Path.of(uploadRoot, "icons");
        if (!Files.exists(iconRoot)) {
            return Map.of("items", List.of(), "total", 0);
        }

        List<Map<String, Object>> allFiles = new ArrayList<>();
        try (Stream<Path> walk = Files.walk(iconRoot)) {
            walk.filter(Files::isRegularFile).forEach(p -> {
                String ext = getExt(p.getFileName().toString()).toLowerCase();
                if (!Set.of(".png", ".jpg", ".jpeg", ".gif", ".webp").contains(ext))
                    return;
                try {
                    long size = Files.size(p);
                    String rel = iconRoot.relativize(p).toString();
                    String url = "/uploads/icons/" + rel.replace('\\', '/');
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("url", url);
                    m.put("size", size);
                    m.put("created_at", Files.getLastModifiedTime(p).toInstant().toString());
                    allFiles.add(m);
                } catch (IOException ignored) {
                }
            });
        } catch (IOException e) {
            log.warn("扫描图标目录失败: {}", e.getMessage());
        }

        // 按修改时间倒序
        allFiles.sort((a, b) -> ((String) b.get("created_at")).compareTo((String) a.get("created_at")));
        int total = allFiles.size();
        List<Map<String, Object>> items = allFiles.size() > lim ? allFiles.subList(0, lim) : allFiles;
        return Map.of("items", items, "total", total);
    }

    // ---- 内部方法 ----

    private String detectMime(byte[] data) {
        // 优先用文件头魔数检测（最快、最可靠）
        String magic = detectMimeByMagic(data);
        if (magic != null)
            return magic;

        // 兜底：用 ImageIO 的 ImageInputStream 正确 API 检测
        try (ImageInputStream iis = ImageIO.createImageInputStream(new ByteArrayInputStream(data))) {
            Iterator<ImageReader> readers = ImageIO.getImageReaders(iis);
            if (readers.hasNext()) {
                String format = readers.next().getFormatName().toLowerCase();
                return switch (format) {
                    case "png" -> "image/png";
                    case "jpeg", "jpg" -> "image/jpeg";
                    case "gif" -> "image/gif";
                    case "webp" -> "image/webp";
                    default -> null;
                };
            }
        } catch (Exception e) {
            log.debug("ImageIO 兜底检测失败: {}", e.getMessage());
        }
        return null;
    }

    private String detectMimeByMagic(byte[] data) {
        if (data.length < 4)
            return null;
        // PNG: 89 50 4E 47
        if (data[0] == (byte) 0x89 && data[1] == (byte) 0x50 && data[2] == (byte) 0x4E && data[3] == (byte) 0x47)
            return "image/png";
        // JPEG: FF D8 FF
        if (data[0] == (byte) 0xFF && data[1] == (byte) 0xD8 && data[2] == (byte) 0xFF)
            return "image/jpeg";
        // GIF: 47 49 46 38
        if (data[0] == (byte) 0x47 && data[1] == (byte) 0x49 && data[2] == (byte) 0x46)
            return "image/gif";
        // WEBP: RIFF....WEBP
        if (data.length >= 12 && data[0] == 'R' && data[1] == 'I' && data[2] == 'F' && data[3] == 'F'
                && data[8] == 'W' && data[9] == 'E' && data[10] == 'B' && data[11] == 'P')
            return "image/webp";
        return null;
    }

    private String normalizeKind(String kind) {
        if (kind == null || kind.isBlank())
            return "note";
        if (!KIND_DIR.containsKey(kind))
            throw BizException.validation("kind 只能是 note 或 icon");
        return kind;
    }

    private String randomHex(int bytes) {
        byte[] buf = new byte[bytes];
        new Random().nextBytes(buf);
        StringBuilder sb = new StringBuilder();
        for (byte b : buf)
            sb.append(String.format("%02x", b));
        return sb.toString();
    }

    private String getExt(String filename) {
        int dot = filename.lastIndexOf('.');
        return dot >= 0 ? filename.substring(dot) : "";
    }
}
