package com.haven.backend.service;

import java.util.Map;

public interface UploadsService {
    Map<String, Object> upload(byte[] data, String originalName, String kind);
    Map<String, Object> listIcons(int limit);
}
