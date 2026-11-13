package com.haven.backend.portfolio.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.portfolio.entity.PortfolioItems;
import com.haven.backend.portfolio.entity.PortfolioRepos;
import com.haven.backend.exception.BizException;
import com.haven.backend.portfolio.mapper.PortfolioItemsMapper;
import com.haven.backend.portfolio.mapper.PortfolioReposMapper;
import com.haven.backend.portfolio.service.PortfolioService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PortfolioServiceImpl implements PortfolioService {

    private final PortfolioItemsMapper itemsMapper;
    private final PortfolioReposMapper reposMapper;

    @Override
    public Map<String, Object> listPublicPortfolio() {
        List<PortfolioItems> items = itemsMapper.selectList(
                new LambdaQueryWrapper<PortfolioItems>().orderByAsc(PortfolioItems::getSortOrder));
        List<Map<String, Object>> list = items.stream().map(i -> {
            Map<String, Object> m = toItemMap(i, false);
            m.put("repos", getRepos(i.getId()));
            return m;
        }).collect(Collectors.toList());
        return Map.of("items", list, "total", list.size());
    }

    @Override
    public Map<String, Object> getPublicPortfolioItem(UUID itemId) {
        PortfolioItems item = itemsMapper.selectById(itemId);
        if (item == null) throw BizException.notFound("作品不存在");
        Map<String, Object> m = toItemMap(item, true);
        m.put("repos", getRepos(itemId));
        return m;
    }

    @Override
    public Map<String, Object> getPortfolioItem(String userId, UUID itemId) {
        UUID uid = UUID.fromString(userId);
        PortfolioItems item = getOwned(uid, itemId);
        Map<String, Object> m = toItemMap(item, true);
        m.put("repos", getRepos(itemId));
        return m;
    }

    @Override
    public Map<String, Object> createPortfolioItem(String userId, String title, String description,
                                                    String content, Integer sortOrder) {
        UUID uid = UUID.fromString(userId);
        PortfolioItems item = new PortfolioItems();
        item.setId(UUID.randomUUID());
        item.setUserId(uid);
        item.setTitle(title != null ? title : "");
        item.setDescription(description != null ? description : "");
        item.setContent(content != null ? content : "");
        item.setSortOrder(sortOrder != null ? sortOrder : 0);
        item.setCreatedAt(OffsetDateTime.now());
        itemsMapper.insert(item);
        Map<String, Object> m = toItemMap(item, true);
        m.put("repos", List.of());
        return m;
    }

    @Override
    public Map<String, Object> updatePortfolioItem(String userId, UUID itemId, String title, String description,
                                                    String content, Integer sortOrder) {
        UUID uid = UUID.fromString(userId);
        PortfolioItems item = getOwned(uid, itemId);
        if (title != null) item.setTitle(title);
        if (description != null) item.setDescription(description);
        if (content != null) item.setContent(content);
        if (sortOrder != null) item.setSortOrder(sortOrder);
        itemsMapper.updateById(item);
        Map<String, Object> m = toItemMap(item, true);
        m.put("repos", getRepos(itemId));
        return m;
    }

    @Override
    @Transactional
    public void deletePortfolioItem(String userId, UUID itemId) {
        UUID uid = UUID.fromString(userId);
        getOwned(uid, itemId);
        reposMapper.delete(new LambdaQueryWrapper<PortfolioRepos>().eq(PortfolioRepos::getPortfolioItemId, itemId));
        itemsMapper.deleteById(itemId);
    }

    @Override
    public Map<String, Object> addRepo(String userId, UUID itemId, String url, String title, boolean isPrimary) {
        UUID uid = UUID.fromString(userId);
        getOwned(uid, itemId);
        if (url == null || url.isBlank()) throw BizException.validation("链接地址不能为空");

        if (isPrimary) clearPrimary(itemId);

        PortfolioRepos repo = new PortfolioRepos();
        repo.setId(UUID.randomUUID());
        repo.setPortfolioItemId(itemId);
        repo.setUrl(url.trim());
        repo.setTitle(title != null ? title : "");
        repo.setIsPrimary(isPrimary);
        reposMapper.insert(repo);
        return toRepoMap(repo);
    }

    @Override
    public Map<String, Object> updateRepo(String userId, UUID itemId, UUID repoId,
                                           String url, String title, Boolean isPrimary) {
        UUID uid = UUID.fromString(userId);
        getOwned(uid, itemId);
        PortfolioRepos repo = reposMapper.selectById(repoId);
        if (repo == null || !repo.getPortfolioItemId().equals(itemId)) throw BizException.notFound("链接不存在");

        if (url != null) repo.setUrl(url.trim());
        if (title != null) repo.setTitle(title);
        if (isPrimary != null && isPrimary) { clearPrimary(itemId); repo.setIsPrimary(true); }
        reposMapper.updateById(repo);
        return toRepoMap(repo);
    }

    @Override
    public void deleteRepo(String userId, UUID itemId, UUID repoId) {
        UUID uid = UUID.fromString(userId);
        getOwned(uid, itemId);
        PortfolioRepos repo = reposMapper.selectById(repoId);
        if (repo == null || !repo.getPortfolioItemId().equals(itemId)) throw BizException.notFound("链接不存在");
        reposMapper.deleteById(repoId);
    }

    // ---- 内部 ----

    private PortfolioItems getOwned(UUID userId, UUID itemId) {
        PortfolioItems item = itemsMapper.selectById(itemId);
        if (item == null || !item.getUserId().equals(userId)) throw BizException.notFound("作品不存在");
        return item;
    }

    private void clearPrimary(UUID itemId) {
        PortfolioRepos update = new PortfolioRepos();
        update.setIsPrimary(false);
        reposMapper.update(update,
                new LambdaQueryWrapper<PortfolioRepos>()
                        .eq(PortfolioRepos::getPortfolioItemId, itemId)
                        .eq(PortfolioRepos::getIsPrimary, true));
    }

    private List<Map<String, Object>> getRepos(UUID itemId) {
        List<PortfolioRepos> repos = reposMapper.selectList(
                new LambdaQueryWrapper<PortfolioRepos>().eq(PortfolioRepos::getPortfolioItemId, itemId));
        return repos.stream().map(this::toRepoMap).collect(Collectors.toList());
    }

    private Map<String, Object> toItemMap(PortfolioItems i, boolean includeContent) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", i.getId().toString());
        m.put("title", i.getTitle());
        m.put("description", i.getDescription());
        if (includeContent) m.put("content", i.getContent());
        m.put("sort_order", i.getSortOrder());
        return m;
    }

    private Map<String, Object> toRepoMap(PortfolioRepos r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getId().toString());
        m.put("url", r.getUrl());
        m.put("title", r.getTitle());
        m.put("kind", inferKind(r.getUrl()));
        m.put("is_primary", r.getIsPrimary());
        return m;
    }

    private String inferKind(String url) {
        if (url == null) return "link";
        String lower = url.toLowerCase();
        if (lower.contains("github.com")) return "github";
        if (lower.contains("gitee.com")) return "gitee";
        if (lower.contains("gitlab.com") || lower.contains("bitbucket.org")) return "git";
        return "link";
    }
}
