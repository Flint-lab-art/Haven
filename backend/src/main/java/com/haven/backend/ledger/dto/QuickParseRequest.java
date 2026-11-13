package com.haven.backend.ledger.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * 手机端快捷记账输入，一行一条。
 */
public record QuickParseRequest(@NotBlank(message = "text 不能为空") String text) {
}
