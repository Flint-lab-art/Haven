package com.haven.backend.stats.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.stats.service.StatsService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/stats")
@RequiredArgsConstructor
public class StatsController {

    private final StatsService statsService;

    @GetMapping
    public Map<String, Object> snapshot(HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return statsService.getStats(userId);
    }
}
