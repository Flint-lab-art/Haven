package com.haven.backend.service;

import java.util.Map;
import java.util.UUID;

public interface PortfolioService {
    Map<String, Object> listPublicPortfolio();
    Map<String, Object> getPublicPortfolioItem(UUID itemId);
    Map<String, Object> getPortfolioItem(String userId, UUID itemId);
    Map<String, Object> createPortfolioItem(String userId, String title, String description, String content, Integer sortOrder);
    Map<String, Object> updatePortfolioItem(String userId, UUID itemId, String title, String description, String content, Integer sortOrder);
    void deletePortfolioItem(String userId, UUID itemId);
    Map<String, Object> addRepo(String userId, UUID itemId, String url, String title, boolean isPrimary);
    Map<String, Object> updateRepo(String userId, UUID itemId, UUID repoId, String url, String title, Boolean isPrimary);
    void deleteRepo(String userId, UUID itemId, UUID repoId);
}
