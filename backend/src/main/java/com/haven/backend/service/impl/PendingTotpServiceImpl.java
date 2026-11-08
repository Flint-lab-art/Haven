package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.spring.service.impl.ServiceImpl;
import com.haven.backend.entity.PendingTotp;
import com.haven.backend.mapper.PendingTotpMapper;
import com.haven.backend.service.IPendingTotpService;
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
public class PendingTotpServiceImpl extends ServiceImpl<PendingTotpMapper, PendingTotp> implements IPendingTotpService {

}
