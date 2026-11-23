package com.haven.backend.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.auth.dto.LoginLogDtos.LoginLogPage;
import com.haven.backend.auth.dto.LoginLogDtos.LoginLogSummary;
import com.haven.backend.auth.entity.LoginLogs;
import com.haven.backend.auth.entity.Users;
import com.haven.backend.auth.mapper.LoginLogsMapper;
import com.haven.backend.auth.mapper.UsersMapper;
import com.haven.backend.auth.service.LoginLogService;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class LoginLogServiceImpl implements LoginLogService {

    private final LoginLogsMapper loginLogsMapper;
    private final UsersMapper usersMapper;

    @Override
    @Transactional(readOnly = true)
    public LoginLogPage list(String userId, int limit, int offset) {
        UUID uid = UUID.fromString(userId);
        int lim = Math.clamp(limit, 1, 200);
        int off = Math.max(offset, 0);

        Users user = usersMapper.selectById(uid);
        String username = user != null ? user.getUsername() : "";

        var wrapper = new LambdaQueryWrapper<LoginLogs>();
        if (username.isBlank()) {
            wrapper.eq(LoginLogs::getUserId, uid);
        } else {
            wrapper.and(w -> w.eq(LoginLogs::getUserId, uid).or().apply("lower(username) = lower({0})", username));
        }

        long total = loginLogsMapper.selectCount(wrapper);
        List<LoginLogs> logs = loginLogsMapper.selectList(
                wrapper.orderByDesc(LoginLogs::getCreatedAt).last("LIMIT " + lim + " OFFSET " + off));

        List<LoginLogSummary> items = logs.stream()
                .map(log -> new LoginLogSummary(
                        log.getId(),
                        log.getEventType(),
                        log.getUsername(),
                        log.getMethod(),
                        log.isSuccess(),
                        log.getFailureReason(),
                        log.getIp(),
                        log.getUserAgent(),
                        log.getCreatedAt()))
                .toList();
        return new LoginLogPage(items, total);
    }
}
