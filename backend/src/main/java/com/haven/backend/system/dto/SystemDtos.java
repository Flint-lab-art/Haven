package com.haven.backend.system.dto;

import java.util.List;

/**
 * 系统接口的响应契约。
 */
public final class SystemDtos {

    private SystemDtos() {}

    /** GET /api/health 的响应。 */
    public record HealthResponse(String status, String version) {}

    /** GET /api/app-config 的运行时前端配置。 */
    public record AppConfigResponse(String version, List<String> privateHosts) {}
}
