package com.haven.backend.controller;

import cn.dev33.satoken.stp.StpUtil;
import com.haven.backend.interceptor.AuthInterceptor;
import com.haven.backend.service.PortfolioService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class PortfolioController {

    private final PortfolioService portfolioService;

    // ---- 公开接口（匿名可访问） ----

    @GetMapping("/api/public/portfolio")
    public Map<String, Object> listPublic() {
        return portfolioService.listPublicPortfolio();
    }

    @GetMapping("/api/public/portfolio/{id}")
    public Map<String, Object> getPublic(@PathVariable String id) {
        return portfolioService.getPublicPortfolioItem(UUID.fromString(id));
    }

    // ---- 需要登录的接口 ----

    @GetMapping("/api/portfolio/{id}")
    public Map<String, Object> get(@PathVariable String id, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        return portfolioService.getPortfolioItem(userId, UUID.fromString(id));
    }

    @PostMapping("/api/portfolio")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@RequestBody Map<String, Object> body, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        String title = (String) body.get("title");
        String description = (String) body.get("description");
        String content = (String) body.get("content");
        Integer sortOrder = body.containsKey("sort_order") ? ((Number) body.get("sort_order")).intValue() : null;
        return portfolioService.createPortfolioItem(userId, title, description, content, sortOrder);
    }

    @PatchMapping("/api/portfolio/{id}")
    public Map<String, Object> update(@PathVariable String id, @RequestBody Map<String, Object> body,
                                      HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        String title = body.containsKey("title") ? (String) body.get("title") : null;
        String description = body.containsKey("description") ? (String) body.get("description") : null;
        String content = body.containsKey("content") ? (String) body.get("content") : null;
        Integer sortOrder = body.containsKey("sort_order") ? ((Number) body.get("sort_order")).intValue() : null;
        return portfolioService.updatePortfolioItem(userId, UUID.fromString(id), title, description, content, sortOrder);
    }

    @DeleteMapping("/api/portfolio/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String id, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        portfolioService.deletePortfolioItem(userId, UUID.fromString(id));
    }

    // ---- 作品链接管理 ----

    @PostMapping("/api/portfolio/{id}/repos")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> addRepo(@PathVariable String id, @RequestBody Map<String, Object> body,
                                       HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        String url = (String) body.get("url");
        String title = (String) body.get("title");
        boolean isPrimary = body.containsKey("is_primary") && Boolean.TRUE.equals(body.get("is_primary"));
        return portfolioService.addRepo(userId, UUID.fromString(id), url, title, isPrimary);
    }

    @PatchMapping("/api/portfolio/{id}/repos/{repoId}")
    public Map<String, Object> updateRepo(@PathVariable String id, @PathVariable String repoId,
                                          @RequestBody Map<String, Object> body, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        String url = body.containsKey("url") ? (String) body.get("url") : null;
        String title = body.containsKey("title") ? (String) body.get("title") : null;
        Boolean isPrimary = body.containsKey("is_primary") ? (Boolean) body.get("is_primary") : null;
        return portfolioService.updateRepo(userId, UUID.fromString(id), UUID.fromString(repoId), url, title, isPrimary);
    }

    @DeleteMapping("/api/portfolio/{id}/repos/{repoId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteRepo(@PathVariable String id, @PathVariable String repoId, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        portfolioService.deleteRepo(userId, UUID.fromString(id), UUID.fromString(repoId));
    }
}
