package com.haven.backend;

import cn.dev33.satoken.SaManager;
import lombok.extern.slf4j.Slf4j;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@Slf4j
@SpringBootApplication
@MapperScan({
        "com.haven.backend.auth.mapper",
        "com.haven.backend.issue.mapper",
        "com.haven.backend.ledger.mapper",
        "com.haven.backend.note.mapper",
        "com.haven.backend.portfolio.mapper"
})
public class BackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(BackendApplication.class, args);
        log.info("启动成功，Sa-Token 配置如下： {}" ,SaManager.getConfig());
    }

}
