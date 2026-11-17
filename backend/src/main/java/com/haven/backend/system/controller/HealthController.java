package com.haven.backend.system.controller;

import com.haven.backend.system.dto.SystemDtos.HealthResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    @Value("${app.version:unknown}")
    private String version;

    @GetMapping("/api/health")
    public HealthResponse health() {
        return new HealthResponse("ok", version);
    }
}
