package com.haven.backend.system.controller;

import com.haven.backend.system.dto.SystemDtos.AppConfigResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 运行时前端配置。
 * <p>
 * 前端不再根据域名切换路由，部署在哪个域名完全由反向代理决定。
 * 这里只保留一个轻量端点返回版本号，方便部署探活与排查前端产物版本。
 */
@RestController
public class AppConfigController {

    @Value("${app.version:unknown}")
    private String appVersion;

    /** GET /api/app-config -> {"version":"2.3.0"}。 */
    @GetMapping("/api/app-config")
    public AppConfigResponse appConfig() {
        return new AppConfigResponse(appVersion);
    }
}
