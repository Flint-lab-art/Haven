package com.haven.backend.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * 运行时前端配置。
 * <p>
 * 前端构建产物只有一份，部署时通过不同域名区分公开站点和私有站点。
 * 哪些域名属于私有域由后端配置下发，避免把域名写死在打包时的环境变量里。
 */
@RestController
public class AppConfigController {

    private final List<String> privateHosts;

    public AppConfigController(@Value("${haven.private-hosts:}") String privateHosts) {
        this.privateHosts = Arrays.stream(privateHosts.split(","))
                .map(String::trim)
                .filter(host -> !host.isEmpty())
                .toList();
    }

    /**
     * GET /api/app-config
     * <p>
     * 返回 {@code {"private_hosts": ["note.example.com"]}}。
     * Jackson 的 SNAKE_CASE 命名策略不影响 Map 的 key，这里直接写 snake_case。
     */
    @GetMapping("/api/app-config")
    public Map<String, Object> appConfig() {
        return Map.of("private_hosts", privateHosts);
    }
}
