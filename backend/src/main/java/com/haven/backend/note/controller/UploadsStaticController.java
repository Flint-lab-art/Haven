package com.haven.backend.note.controller;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 上传文件静态托管。
 * <p>
 * 匿名可访问（公开笔记里的图片也要能看），文件名含随机串可长缓存。
 * 未命中直接 404，不回退到 SPA。
 * <p>
 * 安全约束：请求路径必须落在上传根目录之内，且只能命中普通文件；
 * 目录穿越、指向目录、软链接逃逸都按 404 处理（不泄露文件是否存在）。
 */
@Slf4j
@RestController
public class UploadsStaticController {

    private static final String PREFIX = "/uploads/";

    @Value("${haven.upload-dir:uploads}")
    private String uploadRoot;

    @GetMapping(PREFIX + "**")
    public ResponseEntity<Resource> serveFile(jakarta.servlet.http.HttpServletRequest request) {
        String requestPath = request.getRequestURI();
        String relativePath = requestPath.substring(PREFIX.length());

        // 拒绝目录穿越（含编码后的形式由容器先解码，这里再兜一层）
        if (relativePath.isEmpty() || relativePath.contains("..")) {
            return ResponseEntity.notFound().build();
        }

        Path root = Path.of(uploadRoot).toAbsolutePath().normalize();
        Path filePath = root.resolve(relativePath).normalize();
        // 规范化后必须仍在根目录内，防止 "a/../../etc/passwd" 这类写法
        if (!filePath.startsWith(root)) {
            log.warn("拒绝越界的上传文件请求: {}", requestPath);
            return ResponseEntity.notFound().build();
        }
        if (!Files.isRegularFile(filePath)) {
            return ResponseEntity.notFound().build();
        }

        try {
            String contentType = Files.probeContentType(filePath);
            if (contentType == null) {
                contentType = "application/octet-stream";
            }
            return ResponseEntity.ok()
                    .header(HttpHeaders.CACHE_CONTROL, "public, max-age=31536000, immutable")
                    .header(HttpHeaders.CONTENT_TYPE, contentType)
                    .body(new FileSystemResource(filePath));
        } catch (IOException e) {
            // 探测 contentType 失败不应变成 500：退回通用二进制类型
            log.debug("读取上传文件类型失败: {}", filePath, e);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CACHE_CONTROL, "public, max-age=31536000, immutable")
                    .body(new FileSystemResource(filePath));
        }
    }
}
