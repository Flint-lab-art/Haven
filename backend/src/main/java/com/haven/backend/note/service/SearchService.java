package com.haven.backend.note.service;

import java.util.Map;

public interface SearchService {
    Map<String, Object> searchPrivate(String userId, String q, int limit, int offset, String type);

    Map<String, Object> searchPublic(String q, int limit, int offset);
}
