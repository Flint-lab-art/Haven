package com.haven.backend.controller;

import cn.dev33.satoken.stp.StpUtil;
import com.haven.backend.interceptor.AuthInterceptor;
import com.haven.backend.service.StatsService;
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
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        return statsService.getStats(userId);
    }
}
