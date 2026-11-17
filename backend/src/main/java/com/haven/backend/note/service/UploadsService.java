package com.haven.backend.note.service;

import com.haven.backend.note.dto.NoteDtos.IconPage;
import com.haven.backend.note.dto.NoteDtos.UploadResult;
import org.springframework.web.multipart.MultipartFile;

/**
 * 上传服务：图片保存到本地目录，并提供图标列表。
 */
public interface UploadsService {

    UploadResult upload(byte[] data, String originalName, String kind);

    /**
     * 上传 Spring Multipart 文件。
     * <p>
     * 先按声明大小拒绝超大文件，再流式读取并二次校验实际字节数，
     * 避免把超过上限的文件整个读进堆内存。
     */
    UploadResult upload(MultipartFile file, String kind);

    IconPage listIcons(int limit);
}
