package com.haven.backend.note.service;

import com.haven.backend.note.dto.NoteDtos.PublicNotePage;
import com.haven.backend.note.dto.NoteDtos.SearchResult;

/**
 * 笔记搜索服务，区分私有（当前用户）与公开（匿名）两种范围。
 */
public interface SearchService {

    SearchResult searchPrivate(String userId, String q, int limit, int offset, String type);

    PublicNotePage searchPublic(String q, int limit, int offset);
}
