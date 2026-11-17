package com.haven.backend.note.service;

import com.haven.backend.note.dto.NoteDtos.NotePage;
import com.haven.backend.note.dto.NoteDtos.TagSummary;
import com.haven.backend.note.entity.Tags;
import java.util.List;
import java.util.UUID;

/**
 * 标签服务。
 * <p>
 * 列出标签是只读操作，不会自动清理未被引用的标签（清理走显式删除）。
 */
public interface TagsService {

    /** 当前用户的全部标签，附带使用次数。 */
    List<TagSummary> listTags(String userId);

    Tags createTag(String userId, String name);

    void deleteTag(String userId, UUID tagId);

    /** 指定标签下的笔记（只返回当前用户自己的笔记）。 */
    NotePage listTagNotes(String userId, UUID tagId, int limit, int offset);
}
