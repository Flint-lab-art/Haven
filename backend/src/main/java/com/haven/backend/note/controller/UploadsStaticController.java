package com.haven.backend.note.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.nio.file.Files;
import java.nio.file.Path;

/**
 * 上传文件静态托管。
 * <p>
 * 匿名可访问（公开笔记里的图片也要能看），文件名含随机串可长缓存。
 * 未命中直接 404，不回退到 SPA。
 */
@RestController
public class UploadsStaticController {

    @Value("${haven.upload-dir:uploads}")
    private String uploadRoot;

    @GetMapping("/uploads/**")
    public ResponseEntity<Resource> serveFile(jakarta.servlet.http.HttpServletRequest request) {
        String requestPath = request.getRequestURI();
        // 去掉 /uploads/ 前缀
        String relativePath = requestPath.substring("/uploads/".length());

        // 防止路径穿越
        if (relativePath.contains("..")) {
            return ResponseEntity.notFound().build();
        }

        Path filePath = Path.of(uploadRoot, relativePath);
        if (!Files.exists(filePath) || Files.isDirectory(filePath)) {
            return ResponseEntity.notFound().build();
        }

        try {
            Resource resource = new FileSystemResource(filePath);
            String contentType = Files.probeContentType(filePath);
            if (contentType == null)
                contentType = "application/octet-stream";

            return ResponseEntity.ok()
                    .header(HttpHeaders.CACHE_CONTROL, "public, max-age=31536000, immutable")
                    .header(HttpHeaders.CONTENT_TYPE, contentType)
                    .body(resource);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
