package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.spring.service.impl.ServiceImpl;
import com.haven.backend.entity.Tokens;
import com.haven.backend.mapper.TokensMapper;
import com.haven.backend.service.ITokensService;
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
public class TokensServiceImpl extends ServiceImpl<TokensMapper, Tokens> implements ITokensService {

}
