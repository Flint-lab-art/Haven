package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.spring.service.impl.ServiceImpl;
import com.haven.backend.entity.AuditEvents;
import com.haven.backend.mapper.AuditEventsMapper;
import com.haven.backend.service.IAuditEventsService;
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
public class AuditEventsServiceImpl extends ServiceImpl<AuditEventsMapper, AuditEvents> implements IAuditEventsService {

}
