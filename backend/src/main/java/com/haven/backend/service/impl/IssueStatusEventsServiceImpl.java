package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.spring.service.impl.ServiceImpl;
import com.haven.backend.entity.IssueStatusEvents;
import com.haven.backend.mapper.IssueStatusEventsMapper;
import com.haven.backend.service.IIssueStatusEventsService;
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
public class IssueStatusEventsServiceImpl extends ServiceImpl<IssueStatusEventsMapper, IssueStatusEvents> implements IIssueStatusEventsService {

}
