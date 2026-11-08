package com.haven.backend.controller;

import cn.dev33.satoken.stp.StpUtil;
import com.haven.backend.service.UploadsService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/uploads")
@RequiredArgsConstructor
public class UploadsController {

    private final UploadsService uploadsService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> upload(@RequestParam("file") MultipartFile file,
                                      @RequestParam(required = false) String kind,
                                      HttpServletRequest request) {
        StpUtil.checkLogin();
        try {
            byte[] data = file.getBytes();
            return uploadsService.upload(data, file.getOriginalFilename(), kind);
        } catch (Exception e) {
            throw new RuntimeException("读取上传文件失败", e);
        }
    }

    @GetMapping
    public Map<String, Object> list(@RequestParam(defaultValue = "60") int limit,
                                    HttpServletRequest request) {
        StpUtil.checkLogin();
        return uploadsService.listIcons(limit);
    }
}
