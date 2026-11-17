package com.haven.backend.issue.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.haven.backend.issue.entity.Issues;
import java.util.List;
import java.util.UUID;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 需求 / Bug Mapper。
 */
public interface IssuesMapper extends BaseMapper<Issues> {

    /** 按状态统计用户的所有 issue，返回 [status, count]；一条 SQL 代替多次 selectCount。 */
    @Select("""
            SELECT status, COUNT(*) AS cnt
            FROM issues
            WHERE user_id = #{userId}
            GROUP BY status
            """)
    List<StatusCount> countByStatus(@Param("userId") UUID userId);

    /** 状态统计行。 */
    record StatusCount(String status, long cnt) {}
}
