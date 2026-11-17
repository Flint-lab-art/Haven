package com.haven.backend.note.service;

import java.util.UUID;

/**
 * 更新文件夹的入参对象。
 *
 * @param parentId 目标父文件夹；为 {@code null} 且 {@code clearParent=false} 时不修改
 * @param clearParent 为 true 时移到根目录（忽略 {@code parentId}）
 * @param name 新名称，null 表示不修改
 * @param icon 新图标，null 表示不修改
 * @param sortOrder 新排序，null 表示不修改
 */
public record FolderUpdate(UUID parentId, boolean clearParent, String name, String icon, Integer sortOrder) {}
