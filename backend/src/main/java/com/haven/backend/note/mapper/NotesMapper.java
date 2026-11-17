package com.haven.backend.note.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.haven.backend.note.entity.Notes;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 笔记 Mapper。
 * <p>
 * 常规 CRUD 走 MyBatis-Plus；聚合统计与批量关联查询用参数化 SQL，
 * 避免 N+1 逐条查询和把全表数据加载进内存。
 */
public interface NotesMapper extends BaseMapper<Notes> {

    /**
     * 统计用户所有未删除笔记的正文总字符数（去掉 HTML 标签后）。
     * <p>
     * 统计口径与原先的 Java 实现保持一致：{@code <...>} 视为标签并移除，其余字符计数。
     */
    @Select("""
            SELECT COALESCE(SUM(char_length(regexp_replace(COALESCE(content, ''), '<[^>]*>', '', 'g'))), 0)::bigint
            FROM notes
            WHERE user_id = #{userId} AND deleted_at IS NULL
            """)
    long sumContentLength(@Param("userId") UUID userId);

    /** 按天统计用户笔记更新数量（热力图用），返回 [day, count]。 */
    @Select("""
            SELECT (updated_at AT TIME ZONE #{zone})::date AS day, COUNT(*) AS cnt
            FROM notes
            WHERE user_id = #{userId}
              AND deleted_at IS NULL
              AND updated_at >= #{from}
              AND updated_at < #{to}
            GROUP BY 1
            """)
    List<DailyCount> countByUpdatedDay(
            @Param("userId") UUID userId,
            @Param("from") OffsetDateTime from,
            @Param("to") OffsetDateTime to,
            @Param("zone") String zone);

    /** 按文件夹统计未删除笔记数量，返回 [folder_id, count]。 */
    @Select("""
            SELECT folder_id, COUNT(*) AS cnt
            FROM notes
            WHERE user_id = #{userId}
              AND deleted_at IS NULL
              AND folder_id IS NOT NULL
            GROUP BY folder_id
            """)
    List<FolderCount> countByFolder(@Param("userId") UUID userId);

    /** 热力图单日统计行。 */
    record DailyCount(java.time.LocalDate day, long cnt) {}

    /** 文件夹笔记统计行。 */
    record FolderCount(UUID folderId, long cnt) {}
}
