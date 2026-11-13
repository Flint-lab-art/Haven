package com.haven.backend.auth.service;

import java.util.List;
import java.util.Map;

/**
 * 登录会话服务（基于 Sa-Token 的账号终端列表）。
 */
public interface SessionService {

    /** 列出当前用户的全部活跃会话。 */
    List<Map<String, Object>> listSessions(String userId);

    /** 结束指定会话；不能结束当前会话。 */
    void revokeSession(String userId, String sessionId);
}
