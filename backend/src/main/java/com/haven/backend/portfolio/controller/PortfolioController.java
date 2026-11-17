package com.haven.backend.portfolio.controller;

import com.haven.backend.auth.interceptor.AuthInterceptor;
import com.haven.backend.portfolio.dto.AddRepoRequest;
import com.haven.backend.portfolio.dto.CreatePortfolioItemRequest;
import com.haven.backend.portfolio.dto.PortfolioDtos.PortfolioItemDetail;
import com.haven.backend.portfolio.dto.PortfolioDtos.PortfolioList;
import com.haven.backend.portfolio.dto.PortfolioDtos.PortfolioRepoResponse;
import com.haven.backend.portfolio.dto.UpdatePortfolioItemRequest;
import com.haven.backend.portfolio.dto.UpdateRepoRequest;
import com.haven.backend.portfolio.service.PortfolioService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * 作品集接口。
 * <p>
 * 公开路径（{@code /api/public/portfolio/**}）只返回显式公开的作品；
 * 私有路径需要登录，并且只能操作自己的作品。
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class PortfolioController {

    private final PortfolioService portfolioService;

    // ---- 公开接口（匿名可访问） ----

    @GetMapping("/public/portfolio")
    public PortfolioList listPublic() {
        return portfolioService.listPublicPortfolio();
    }

    @GetMapping("/public/portfolio/{id}")
    public PortfolioItemDetail getPublic(@PathVariable UUID id) {
        return portfolioService.getPublicPortfolioItem(id);
    }

    // ---- 需要登录的接口 ----

    /** 管理页列表：返回全部作品，含未公开的草稿。 */
    @GetMapping("/portfolio")
    public PortfolioList listMine(HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return portfolioService.listMyPortfolio(userId);
    }

    @GetMapping("/portfolio/{id}")
    public PortfolioItemDetail get(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return portfolioService.getPortfolioItem(userId, id);
    }

    @PostMapping("/portfolio")
    @ResponseStatus(HttpStatus.CREATED)
    public PortfolioItemDetail create(@Valid @RequestBody CreatePortfolioItemRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return portfolioService.createPortfolioItem(
                userId, req.title(), req.description(), req.content(), req.sortOrder(), req.isPublic());
    }

    @PatchMapping("/portfolio/{id}")
    public PortfolioItemDetail update(
            @PathVariable UUID id, @Valid @RequestBody UpdatePortfolioItemRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return portfolioService.updatePortfolioItem(userId, id, req);
    }

    @DeleteMapping("/portfolio/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        portfolioService.deletePortfolioItem(userId, id);
    }

    // ---- 作品链接管理 ----

    @PostMapping("/portfolio/{id}/repos")
    @ResponseStatus(HttpStatus.CREATED)
    public PortfolioRepoResponse addRepo(
            @PathVariable UUID id, @Valid @RequestBody AddRepoRequest req, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return portfolioService.addRepo(userId, id, req.url(), req.title(), Boolean.TRUE.equals(req.isPrimary()));
    }

    @PatchMapping("/portfolio/{id}/repos/{repoId}")
    public PortfolioRepoResponse updateRepo(
            @PathVariable UUID id,
            @PathVariable UUID repoId,
            @Valid @RequestBody UpdateRepoRequest req,
            HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        return portfolioService.updateRepo(userId, id, repoId, req.url(), req.title(), req.isPrimary());
    }

    @DeleteMapping("/portfolio/{id}/repos/{repoId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteRepo(@PathVariable UUID id, @PathVariable UUID repoId, HttpServletRequest request) {
        String userId = AuthInterceptor.requireUserId(request);
        portfolioService.deleteRepo(userId, id, repoId);
    }
}
