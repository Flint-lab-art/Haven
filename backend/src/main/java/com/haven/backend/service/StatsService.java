package com.haven.backend.service;

import java.util.Map;

public interface StatsService {
    Map<String, Object> getStats(String userId);
}
