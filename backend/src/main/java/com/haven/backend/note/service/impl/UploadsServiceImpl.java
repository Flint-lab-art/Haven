package com.haven.backend.note.service.impl;

import com.haven.backend.exception.BizException;
import com.haven.backend.note.dto.NoteDtos.IconItem;
import com.haven.backend.note.dto.NoteDtos.IconPage;
import com.haven.backend.note.dto.NoteDtos.UploadResult;
import com.haven.backend.note.service.UploadsService;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Stream;
import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Slf4j
@Service
public class UploadsServiceImpl implements UploadsService {

    private static final long MAX_UPLOAD_BYTES = 10L << 20; // 10 MiB
    private static final Set<String> ALLOWED_MIMES = Set.of("image/png", "image/jpeg", "image/gif", "image/webp");
    private static final Map<String, String> MIME_EXT =
            Map.of("image/png", ".png", "image/jpeg", ".jpg", "image/gif", ".gif", "image/webp", ".webp");
    private static final Map<String, String> KIND_DIR = Map.of("note", "notes", "icon", "icons");
    /** 文件名随机源：必须不可预测，避免上传文件被枚举。 */
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    @Value("${haven.upload-dir:uploads}")
    private String uploadRoot;

    private final Clock clock;

    /** 显式构造器：类中存在 {@code @Value} 字段，不能依赖 Lombok 生成构造器。 */
    public UploadsServiceImpl(Clock clock) {
        this.clock = clock;
    }

    @Override
    public UploadResult upload(byte[] data, String originalName, String kind) {
        if (data == null || data.length == 0) {
            throw BizException.validation("文件为空");
        }
        return uploadBytes(data, originalName, kind);
    }

    @Override
    public UploadResult upload(MultipartFile file, String kind) {
        if (file == null || file.isEmpty()) {
            throw BizException.validation("文件为空");
        }
        // 先按声明大小拒绝，避免把超大文件整个读进内存
        if (file.getSize() > MAX_UPLOAD_BYTES) {
            throw new BizException(413, "文件超过 10 MiB");
        }
        byte[] data;
        try (InputStream in = file.getInputStream()) {
            data = in.readNBytes((int) MAX_UPLOAD_BYTES + 1);
        } catch (IOException e) {
            throw BizException.internal("读取上传文件失败");
        }
        // 声明大小与实际字节不一致时（分块/被篡改）以实际读取为准
        if (data.length > MAX_UPLOAD_BYTES) {
            throw new BizException(413, "文件超过 10 MiB");
        }
        return uploadBytes(data, file.getOriginalFilename(), kind);
    }

    private UploadResult uploadBytes(byte[] data, String originalName, String kind) {
        if (data.length == 0) {
            throw BizException.validation("文件为空");
        }
        if (data.length > MAX_UPLOAD_BYTES) {
            throw new BizException(413, "文件超过 10 MiB");
        }

        // 检测真实 MIME
        String detectedMime = detectMime(data);
        if (detectedMime == null || !ALLOWED_MIMES.contains(detectedMime)) {
            throw new BizException(415, "只支持 png / jpeg / gif / webp 图片");
        }

        String normalizedKind = normalizeKind(kind);
        String ext = MIME_EXT.get(detectedMime);
        LocalDateTime now = LocalDateTime.now(clock);

        String subDir = KIND_DIR.get(normalizedKind) + "/" + now.format(DateTimeFormatter.ofPattern("yyyy/MM"));
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
            } catch (IOException cleanupFailure) {
                // 清理临时文件失败不影响主流程，原始异常更重要
                log.warn("清理临时上传文件失败: {}", tmp);
            }
            throw BizException.internal("保存上传文件失败");
        }

        String url = "/uploads/" + subDir + "/" + fileName;
        return new UploadResult(url, originalName != null ? originalName : fileName, data.length, detectedMime);
    }

    @Override
    public IconPage listIcons(int limit) {
        int lim = Math.min(limit <= 0 ? 60 : limit, 200);
        Path iconRoot = Path.of(uploadRoot, "icons");
        if (!Files.exists(iconRoot)) {
            return new IconPage(List.of(), 0);
        }

        List<IconItem> allFiles = new ArrayList<>();
        try (Stream<Path> walk = Files.walk(iconRoot)) {
            walk.filter(Files::isRegularFile).forEach(p -> {
                String ext = getExt(p.getFileName().toString()).toLowerCase();
                if (!Set.of(".png", ".jpg", ".jpeg", ".gif", ".webp").contains(ext)) {
                    return;
                }
                try {
                    long size = Files.size(p);
                    String rel = iconRoot.relativize(p).toString();
                    String url = "/uploads/icons/" + rel.replace('\\', '/');
                    allFiles.add(new IconItem(
                            url, size, Files.getLastModifiedTime(p).toInstant().toString()));
                } catch (IOException unreadable) {
                    // 单个图标文件读不到时跳过，不影响整体列表
                    log.debug("跳过无法读取的图标文件: {}", p);
                }
            });
        } catch (IOException e) {
            log.warn("扫描图标目录失败: {}", e.getMessage());
        }

        // 按修改时间倒序
        allFiles.sort((a, b) -> b.createdAt().compareTo(a.createdAt()));
        int total = allFiles.size();
        List<IconItem> items = allFiles.size() > lim ? allFiles.subList(0, lim) : allFiles;
        return new IconPage(items, total);
    }

    // ---- 内部方法 ----

    private String detectMime(byte[] data) {
        // 优先用文件头魔数检测（最快、最可靠）
        String magic = detectMimeByMagic(data);
        if (magic != null) {
            return magic;
        }

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
        if (data.length < 4) {
            return null;
        }
        // PNG: 89 50 4E 47
        if (data[0] == (byte) 0x89 && data[1] == (byte) 0x50 && data[2] == (byte) 0x4E && data[3] == (byte) 0x47) {
            return "image/png";
        }
        // JPEG: FF D8 FF
        if (data[0] == (byte) 0xFF && data[1] == (byte) 0xD8 && data[2] == (byte) 0xFF) {
            return "image/jpeg";
        }
        // GIF: 47 49 46 38
        if (data[0] == (byte) 0x47 && data[1] == (byte) 0x49 && data[2] == (byte) 0x46) {
            return "image/gif";
        }
        // WEBP: RIFF....WEBP
        if (data.length >= 12
                && data[0] == 'R'
                && data[1] == 'I'
                && data[2] == 'F'
                && data[3] == 'F'
                && data[8] == 'W'
                && data[9] == 'E'
                && data[10] == 'B'
                && data[11] == 'P') {
            return "image/webp";
        }
        return null;
    }

    private String normalizeKind(String kind) {
        if (kind == null || kind.isBlank()) {
            return "note";
        }
        if (!KIND_DIR.containsKey(kind)) {
            throw BizException.validation("kind 只能是 note 或 icon");
        }
        return kind;
    }

    private String randomHex(int bytes) {
        byte[] buf = new byte[bytes];
        SECURE_RANDOM.nextBytes(buf);
        StringBuilder sb = new StringBuilder();
        for (byte b : buf) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    private String getExt(String filename) {
        int dot = filename.lastIndexOf('.');
        return dot >= 0 ? filename.substring(dot) : "";
    }
}
