package com.haven.backend.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HealthController {

    @Value("${app.version:unknown}")
    private String version;

    @GetMapping("/api/health")
    public Map<String, Object> health() {
        return Map.of("status", "ok", "version", version);
    }
}
