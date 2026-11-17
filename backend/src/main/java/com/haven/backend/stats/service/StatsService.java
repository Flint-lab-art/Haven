package com.haven.backend.stats.service;

import com.haven.backend.stats.dto.StatsDtos.StatsSnapshot;

public interface StatsService {
    StatsSnapshot getStats(String userId);
}
