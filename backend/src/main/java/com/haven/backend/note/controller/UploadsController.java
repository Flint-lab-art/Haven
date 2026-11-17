package com.haven.backend.note.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.note.dto.NoteDtos.IconPage;
import com.haven.backend.note.dto.NoteDtos.UploadResult;
import com.haven.backend.note.service.UploadsService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/uploads")
@RequiredArgsConstructor
public class UploadsController {

    private final UploadsService uploadsService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UploadResult upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam(required = false) String kind,
            HttpServletRequest request) {
        AuthInterceptor.requireUserId(request);
        return uploadsService.upload(file, kind);
    }

    @GetMapping
    public IconPage list(@RequestParam(defaultValue = "60") int limit, HttpServletRequest request) {
        AuthInterceptor.requireUserId(request);
        return uploadsService.listIcons(limit);
    }
}
