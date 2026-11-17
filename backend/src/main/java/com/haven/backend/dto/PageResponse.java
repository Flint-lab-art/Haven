package com.haven.backend.dto;

import java.util.List;

/**
 * 列表响应的统一契约：{@code {"items": [...], "total": N}}。
 * <p>
 * 各模块此前各自定义 {@code XxxPage} record，结构完全一致。这里提供通用实现，
 * 新接口应优先使用 {@code PageResponse<T>}；已有模块的具名 record 可以保持不变，
 * 迁移到通用类型时字段名与结构完全兼容。
 *
 * @param items 当前页数据
 * @param total 满足条件的总条数（不是当前页条数）
 */
public record PageResponse<T>(List<T> items, long total) {

    /** 拷贝一份不可变列表，避免调用方后续修改影响响应。 */
    public PageResponse {
        items = List.copyOf(items);
    }
}
