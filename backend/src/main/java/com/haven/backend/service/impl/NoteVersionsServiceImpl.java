package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.spring.service.impl.ServiceImpl;
import com.haven.backend.entity.NoteVersions;
import com.haven.backend.mapper.NoteVersionsMapper;
import com.haven.backend.service.INoteVersionsService;
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
public class NoteVersionsServiceImpl extends ServiceImpl<NoteVersionsMapper, NoteVersions> implements INoteVersionsService {

}
