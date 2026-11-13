package com.haven.backend.note.service;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.haven.backend.note.entity.Tags;

public interface TagsService {
    List<Map<String, Object>> listTags(String userId);

    Tags createTag(String userId, String name);

    void deleteTag(String userId, UUID tagId);

    Map<String, Object> listTagNotes(String userId, UUID tagId, int limit, int offset);
}
