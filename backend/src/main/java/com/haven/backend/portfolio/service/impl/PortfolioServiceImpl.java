package com.haven.backend.portfolio.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.haven.backend.exception.BizException;
import com.haven.backend.portfolio.dto.PortfolioDtos.PortfolioItemDetail;
import com.haven.backend.portfolio.dto.PortfolioDtos.PortfolioItemSummary;
import com.haven.backend.portfolio.dto.PortfolioDtos.PortfolioList;
import com.haven.backend.portfolio.dto.PortfolioDtos.PortfolioRepoResponse;
import com.haven.backend.portfolio.dto.UpdatePortfolioItemRequest;
import com.haven.backend.portfolio.entity.PortfolioItems;
import com.haven.backend.portfolio.entity.PortfolioRepos;
import com.haven.backend.portfolio.mapper.PortfolioItemsMapper;
import com.haven.backend.portfolio.mapper.PortfolioReposMapper;
import com.haven.backend.portfolio.service.PortfolioService;
import java.time.Clock;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PortfolioServiceImpl implements PortfolioService {

    private final PortfolioItemsMapper itemsMapper;
    private final Clock clock;
    private final PortfolioReposMapper reposMapper;

    @Override
    @Transactional(readOnly = true)
    public PortfolioList listPublicPortfolio() {
        List<PortfolioItems> items = itemsMapper.selectList(new LambdaQueryWrapper<PortfolioItems>()
                .eq(PortfolioItems::getIsPublic, true)
                .orderByAsc(PortfolioItems::getSortOrder));
        List<PortfolioItemSummary> list = items.stream().map(this::toSummary).collect(Collectors.toList());
        return new PortfolioList(list, list.size());
    }

    @Override
    @Transactional(readOnly = true)
    public PortfolioItemDetail getPublicPortfolioItem(UUID itemId) {
        PortfolioItems item = itemsMapper.selectById(itemId);
        // 未公开的作品在匿名接口统一按不存在处理，避免泄露草稿存在性
        if (item == null || !Boolean.TRUE.equals(item.getIsPublic())) {
            throw BizException.notFound("作品不存在");
        }
        return toDetail(item);
    }

    @Override
    @Transactional(readOnly = true)
    public PortfolioItemDetail getPortfolioItem(String userId, UUID itemId) {
        UUID uid = UUID.fromString(userId);
        return toDetail(getOwned(uid, itemId));
    }

    @Override
    @Transactional
    public PortfolioItemDetail createPortfolioItem(
            String userId, String title, String description, String content, Integer sortOrder, Boolean isPublic) {
        UUID uid = UUID.fromString(userId);
        PortfolioItems item = new PortfolioItems();
        item.setId(UUID.randomUUID());
        item.setUserId(uid);
        item.setTitle(title != null ? title : "");
        item.setDescription(description != null ? description : "");
        item.setContent(content != null ? content : "");
        item.setSortOrder(sortOrder != null ? sortOrder : 0);
        item.setIsPublic(Boolean.TRUE.equals(isPublic));
        item.setCreatedAt(OffsetDateTime.now(clock));
        itemsMapper.insert(item);
        return new PortfolioItemDetail(
                item.getId(),
                item.getTitle(),
                item.getDescription(),
                item.getContent(),
                item.getSortOrder(),
                Boolean.TRUE.equals(item.getIsPublic()),
                List.of());
    }

    @Override
    @Transactional
    public PortfolioItemDetail updatePortfolioItem(String userId, UUID itemId, UpdatePortfolioItemRequest req) {
        UUID uid = UUID.fromString(userId);
        String title = req.title();
        String description = req.description();
        String content = req.content();
        Integer sortOrder = req.sortOrder();
        Boolean isPublic = req.isPublic();
        PortfolioItems item = getOwned(uid, itemId);
        if (title != null) {
            item.setTitle(title);
        }
        if (description != null) {
            item.setDescription(description);
        }
        if (content != null) {
            item.setContent(content);
        }
        if (sortOrder != null) {
            item.setSortOrder(sortOrder);
        }
        if (isPublic != null) {
            item.setIsPublic(isPublic);
        }
        itemsMapper.updateById(item);
        return toDetail(item);
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
    @Transactional
    public PortfolioRepoResponse addRepo(String userId, UUID itemId, String url, String title, boolean isPrimary) {
        UUID uid = UUID.fromString(userId);
        getOwned(uid, itemId);
        String normalizedUrl = requireHttpUrl(url);

        if (isPrimary) {
            clearPrimary(itemId);
        }

        PortfolioRepos repo = new PortfolioRepos();
        repo.setId(UUID.randomUUID());
        repo.setPortfolioItemId(itemId);
        repo.setUrl(normalizedUrl);
        repo.setTitle(title != null ? title : "");
        repo.setIsPrimary(isPrimary);
        reposMapper.insert(repo);
        return toRepoResponse(repo);
    }

    @Override
    @Transactional
    public PortfolioRepoResponse updateRepo(
            String userId, UUID itemId, UUID repoId, String url, String title, Boolean isPrimary) {
        UUID uid = UUID.fromString(userId);
        getOwned(uid, itemId);
        PortfolioRepos repo = reposMapper.selectById(repoId);
        if (repo == null || !repo.getPortfolioItemId().equals(itemId)) {
            throw BizException.notFound("链接不存在");
        }

        if (url != null) {
            repo.setUrl(requireHttpUrl(url));
        }
        if (title != null) {
            repo.setTitle(title);
        }
        if (Boolean.TRUE.equals(isPrimary)) {
            clearPrimary(itemId);
            repo.setIsPrimary(true);
        } else if (Boolean.FALSE.equals(isPrimary)) {
            repo.setIsPrimary(false);
        }
        reposMapper.updateById(repo);
        return toRepoResponse(repo);
    }

    @Override
    @Transactional
    public void deleteRepo(String userId, UUID itemId, UUID repoId) {
        UUID uid = UUID.fromString(userId);
        getOwned(uid, itemId);
        PortfolioRepos repo = reposMapper.selectById(repoId);
        if (repo == null || !repo.getPortfolioItemId().equals(itemId)) {
            throw BizException.notFound("链接不存在");
        }
        reposMapper.deleteById(repoId);
    }

    // ---- 内部 ----

    /** 作品链接只允许 http/https，避免 javascript:/data: 被前端当作 href 渲染。 */
    private static String requireHttpUrl(String url) {
        if (url == null || url.isBlank()) {
            throw BizException.validation("链接地址不能为空");
        }
        String trimmed = url.trim();
        if (!trimmed.regionMatches(true, 0, "http://", 0, 7) && !trimmed.regionMatches(true, 0, "https://", 0, 8)) {
            throw BizException.validation("链接只支持 http/https");
        }
        if (trimmed.length() > 2048) {
            throw BizException.validation("链接过长");
        }
        return trimmed;
    }

    private PortfolioItems getOwned(UUID userId, UUID itemId) {
        PortfolioItems item = itemsMapper.selectById(itemId);
        if (item == null || !item.getUserId().equals(userId)) {
            throw BizException.notFound("作品不存在");
        }
        return item;
    }

    private void clearPrimary(UUID itemId) {
        PortfolioRepos update = new PortfolioRepos();
        update.setIsPrimary(false);
        reposMapper.update(
                update,
                new LambdaQueryWrapper<PortfolioRepos>()
                        .eq(PortfolioRepos::getPortfolioItemId, itemId)
                        .eq(PortfolioRepos::getIsPrimary, true));
    }

    private List<PortfolioRepoResponse> getRepos(UUID itemId) {
        return reposMapper
                .selectList(new LambdaQueryWrapper<PortfolioRepos>().eq(PortfolioRepos::getPortfolioItemId, itemId))
                .stream()
                .map(this::toRepoResponse)
                .collect(Collectors.toList());
    }

    private PortfolioItemSummary toSummary(PortfolioItems i) {
        return new PortfolioItemSummary(
                i.getId(),
                i.getTitle(),
                i.getDescription(),
                i.getSortOrder() != null ? i.getSortOrder() : 0,
                Boolean.TRUE.equals(i.getIsPublic()),
                getRepos(i.getId()));
    }

    private PortfolioItemDetail toDetail(PortfolioItems i) {
        return new PortfolioItemDetail(
                i.getId(),
                i.getTitle(),
                i.getDescription(),
                i.getContent(),
                i.getSortOrder() != null ? i.getSortOrder() : 0,
                Boolean.TRUE.equals(i.getIsPublic()),
                getRepos(i.getId()));
    }

    private PortfolioRepoResponse toRepoResponse(PortfolioRepos r) {
        return new PortfolioRepoResponse(
                r.getId(), r.getUrl(), r.getTitle(), inferKind(r.getUrl()), Boolean.TRUE.equals(r.getIsPrimary()));
    }

    private String inferKind(String url) {
        if (url == null) {
            return "link";
        }
        String lower = url.toLowerCase(Locale.ROOT);
        if (lower.contains("github.com")) {
            return "github";
        }
        if (lower.contains("gitee.com")) {
            return "gitee";
        }
        if (lower.contains("gitlab.com") || lower.contains("bitbucket.org")) {
            return "git";
        }
        return "link";
    }
}
