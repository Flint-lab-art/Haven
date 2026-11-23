package com.haven.backend;

import cn.dev33.satoken.SaManager;
import cn.dev33.satoken.config.SaTokenConfig;
import lombok.extern.slf4j.Slf4j;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@Slf4j
@SpringBootApplication
@MapperScan({
    "com.haven.backend.auth.mapper",
    "com.haven.backend.audit",
    "com.haven.backend.issue.mapper",
    "com.haven.backend.ledger.mapper",
    "com.haven.backend.note.mapper"
})
public class BackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(BackendApplication.class, args);
        // 不打印整个 SaTokenConfig：它包含 cookie/会话等细节，未来扩展可能带入敏感项。
        // 启动日志只保留排障真正需要的字段。
        SaTokenConfig config = SaManager.getConfig();
        log.info(
                "启动成功，Sa-Token: tokenName={}, timeout={}s, activeTimeout={}s, isConcurrent={}",
                config.getTokenName(),
                config.getTimeout(),
                config.getActiveTimeout(),
                config.getIsConcurrent());
    }
}
