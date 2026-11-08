package com.haven.backend.controller;

import cn.dev33.satoken.stp.StpUtil;
import com.haven.backend.entity.Folders;
import com.haven.backend.interceptor.AuthInterceptor;
import com.haven.backend.service.FoldersService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/folders")
@RequiredArgsConstructor
public class FoldersController {

    private final FoldersService foldersService;

    @GetMapping
    public Map<String, Object> list(HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        List<Folders> folders = foldersService.listFolders(userId);
        List<Map<String, Object>> items = folders.stream().map(this::toMap).toList();
        return Map.of("items", items, "total", items.size());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@RequestBody Map<String, Object> body, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        String name = (String) body.get("name");
        UUID parentId = body.get("parent_id") != null ? UUID.fromString(body.get("parent_id").toString()) : null;
        String icon = (String) body.get("icon");
        Folders folder = foldersService.createFolder(userId, name, parentId, icon);
        return toMap(folder);
    }

    @PatchMapping("/{id}")
    public Map<String, Object> update(@PathVariable String id, @RequestBody Map<String, Object> body,
                                      HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        UUID folderId = UUID.fromString(id);
        String name = body.containsKey("name") ? (String) body.get("name") : null;
        UUID parentId = null;
        if (body.containsKey("parent_id")) {
            parentId = body.get("parent_id") != null ? UUID.fromString(body.get("parent_id").toString()) : null;
        }
        String icon = body.containsKey("icon") ? (String) body.get("icon") : null;
        Integer sortOrder = body.containsKey("sort_order") ? ((Number) body.get("sort_order")).intValue() : null;
        Folders folder = foldersService.updateFolder(userId, folderId, name, parentId, icon, sortOrder);
        return toMap(folder);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String id, HttpServletRequest request) {
        StpUtil.checkLogin();
        String userId = AuthInterceptor.getUserId(request);
        foldersService.deleteFolder(userId, UUID.fromString(id));
    }

    private Map<String, Object> toMap(Folders f) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", f.getId().toString());
        m.put("parent_id", f.getParentId() != null ? f.getParentId().toString() : null);
        m.put("name", f.getName());
        m.put("icon", f.getIcon());
        m.put("is_inbox", f.getIsInbox());
        m.put("sort_order", f.getSortOrder());
        return m;
    }
}
