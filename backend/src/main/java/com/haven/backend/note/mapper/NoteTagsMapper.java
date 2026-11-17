package com.haven.backend.note.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.haven.backend.note.entity.NoteTags;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 笔记-标签关联 Mapper。
 */
public interface NoteTagsMapper extends BaseMapper<NoteTags> {

    /**
     * 批量查询多条笔记的标签，避免列表页逐条查关联（N+1）。
     *
     * @param userId 只返回当前用户自己的标签
     * @param noteIds 笔记 ID 集合，调用方需保证非空
     */
    @Select("""
            <script>
            SELECT nt.note_id, t.id AS tag_id, t.name AS tag_name
            FROM note_tags nt
            JOIN tags t ON t.id = nt.tag_id
            WHERE t.user_id = #{userId}
              AND nt.note_id IN
              <foreach collection="noteIds" item="id" open="(" separator="," close=")">#{id}</foreach>
            </script>
            """)
    List<NoteTag> selectTagsForNotes(@Param("userId") UUID userId, @Param("noteIds") Collection<UUID> noteIds);

    /** 一条笔记标签关联的扁平结果。 */
    record NoteTag(UUID noteId, UUID tagId, String tagName) {}
}
