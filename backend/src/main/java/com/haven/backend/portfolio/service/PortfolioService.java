package com.haven.backend.portfolio.service;

import com.haven.backend.portfolio.dto.PortfolioDtos.PortfolioItemDetail;
import com.haven.backend.portfolio.dto.PortfolioDtos.PortfolioList;
import com.haven.backend.portfolio.dto.PortfolioDtos.PortfolioRepoResponse;
import com.haven.backend.portfolio.dto.UpdatePortfolioItemRequest;
import java.util.UUID;

/**
 * 作品集服务。
 * <p>
 * 所有返回值都是有名字的 DTO（见 {@code PortfolioDtos}）；公开接口只返回 {@code is_public=true} 的作品。
 */
public interface PortfolioService {

    PortfolioList listPublicPortfolio();

    PortfolioItemDetail getPublicPortfolioItem(UUID itemId);

    PortfolioItemDetail getPortfolioItem(String userId, UUID itemId);

    PortfolioItemDetail createPortfolioItem(
            String userId, String title, String description, String content, Integer sortOrder, Boolean isPublic);

    PortfolioItemDetail updatePortfolioItem(String userId, UUID itemId, UpdatePortfolioItemRequest req);

    void deletePortfolioItem(String userId, UUID itemId);

    PortfolioRepoResponse addRepo(String userId, UUID itemId, String url, String title, boolean isPrimary);

    PortfolioRepoResponse updateRepo(
            String userId, UUID itemId, UUID repoId, String url, String title, Boolean isPrimary);

    void deleteRepo(String userId, UUID itemId, UUID repoId);
}
