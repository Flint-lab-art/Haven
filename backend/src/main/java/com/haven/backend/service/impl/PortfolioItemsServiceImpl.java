package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.spring.service.impl.ServiceImpl;
import com.haven.backend.entity.PortfolioItems;
import com.haven.backend.mapper.PortfolioItemsMapper;
import com.haven.backend.service.IPortfolioItemsService;
import org.springframework.stereotype.Service;

/**
 * <p>
 *  服务实现类
 * </p>
 *
 * @author Kairo
 * @since 2026-11-08
 */
@Service
public class PortfolioItemsServiceImpl extends ServiceImpl<PortfolioItemsMapper, PortfolioItems> implements IPortfolioItemsService {

}
