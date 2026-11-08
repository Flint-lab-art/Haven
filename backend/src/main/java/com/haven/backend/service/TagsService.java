package com.haven.backend.service;

import com.haven.backend.entity.Tags;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface TagsService {
    List<Map<String, Object>> listTags(String userId);
    Tags createTag(String userId, String name);
    void deleteTag(String userId, UUID tagId);
    Map<String, Object> listTagNotes(String userId, UUID tagId, int limit, int offset);
}
