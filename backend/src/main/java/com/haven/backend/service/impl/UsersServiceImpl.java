package com.haven.backend.service.impl;

import com.baomidou.mybatisplus.spring.service.impl.ServiceImpl;
import com.haven.backend.entity.Users;
import com.haven.backend.mapper.UsersMapper;
import com.haven.backend.service.IUsersService;
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
public class UsersServiceImpl extends ServiceImpl<UsersMapper, Users> implements IUsersService {

}
