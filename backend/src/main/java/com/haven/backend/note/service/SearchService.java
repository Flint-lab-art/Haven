package com.haven.backend.note.service;

import com.haven.backend.note.dto.NoteDtos.SearchResult;

/**
 * 笔记搜索服务：只搜索当前用户自己的笔记与标签。
 */
public interface SearchService {

    SearchResult searchPrivate(String userId, String q, int limit, int offset, String type);
}
