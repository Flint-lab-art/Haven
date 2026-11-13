package com.haven.backend.ledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 新增或更新分类别名。
 */
public record UpsertLedgerAliasRequest(

        @NotBlank(message = "alias 不能为空")
        @Size(max = 64, message = "alias 不能超过 64 个字符")
        String alias,

        @NotBlank(message = "category 不能为空")
        String category
) {
}
