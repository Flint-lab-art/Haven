package com.haven.backend.auth.service;

import com.haven.backend.auth.dto.LoginLogDtos.LoginLogPage;

/** 登录日志查询服务。 */
public interface LoginLogService {

    /**
     * 查询当前用户的登录日志。
     * <p>
     * 除 {@code user_id} 匹配外，还会带上「用户名相同」的失败尝试：
     * 用户名输错时 {@code user_id} 为空，但那条失败记录同样属于这个账号的登录历史。
     */
    LoginLogPage list(String userId, int limit, int offset);
}
