package com.haven.backend.note.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.note.dto.NoteDtos.SearchResult;
import com.haven.backend.note.service.SearchService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class SearchController {

    private final SearchService searchService;

    @GetMapping("/api/search")
    public SearchResult searchPrivate(
            @RequestParam String q,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String type,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return searchService.searchPrivate(userId, q, limit, offset, type);
    }
}
