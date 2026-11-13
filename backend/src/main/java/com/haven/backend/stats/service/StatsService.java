package com.haven.backend.stats.service;

import java.util.Map;

public interface StatsService {
    Map<String, Object> getStats(String userId);
}
