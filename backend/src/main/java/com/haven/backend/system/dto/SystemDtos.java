package com.haven.backend.system.dto;

/**
 * 系统接口的响应契约。
 */
public final class SystemDtos {

    private SystemDtos() {}

    /** GET /api/health 的响应。 */
    public record HealthResponse(String status, String version) {}

    /** GET /api/app-config 的运行时前端配置（目前只有版本号，保留端点供前端探活）。 */
    public record AppConfigResponse(String version) {}
}
