package com.haven.backend.portfolio.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

import com.haven.backend.exception.BizException;
import com.haven.backend.portfolio.entity.PortfolioItems;
import com.haven.backend.portfolio.mapper.PortfolioItemsMapper;
import com.haven.backend.portfolio.mapper.PortfolioReposMapper;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * 公开作品集可见性：未显式公开的作品不能通过匿名接口读到。
 */
@ExtendWith(MockitoExtension.class)
class PortfolioServiceImplTest {

    @Mock
    private PortfolioItemsMapper itemsMapper;

    @Mock
    private PortfolioReposMapper reposMapper;

    @InjectMocks
    private PortfolioServiceImpl portfolioService;

    @Test
    @DisplayName("未公开作品在匿名详情接口按不存在处理")
    void getPublicItem_notPublic_throwsNotFound() {
        PortfolioItems item = item(false);
        when(itemsMapper.selectById(item.getId())).thenReturn(item);

        BizException ex = assertThrows(BizException.class, () -> portfolioService.getPublicPortfolioItem(item.getId()));

        assertEquals(404, ex.getCode());
    }

    @Test
    @DisplayName("公开作品可以匿名读取")
    void getPublicItem_public_returnsContent() {
        PortfolioItems item = item(true);
        item.setContent("<p>hello</p>");
        when(itemsMapper.selectById(item.getId())).thenReturn(item);
        when(reposMapper.selectList(org.mockito.ArgumentMatchers.any())).thenReturn(java.util.List.of());

        assertEquals(
                "<p>hello</p>",
                portfolioService.getPublicPortfolioItem(item.getId()).content());
    }

    private static PortfolioItems item(boolean isPublic) {
        PortfolioItems item = new PortfolioItems();
        item.setId(UUID.randomUUID());
        item.setUserId(UUID.randomUUID());
        item.setTitle("title");
        item.setDescription("");
        item.setContent("");
        item.setSortOrder(0);
        item.setIsPublic(isPublic);
        return item;
    }
}
