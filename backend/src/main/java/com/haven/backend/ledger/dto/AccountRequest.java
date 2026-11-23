package com.haven.backend.ledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * 新建或修改账户。
 */
public record AccountRequest(
        @NotBlank(message = "name 不能为空") @Size(max = 32, message = "账户名过长")
        String name,

        /** 图标 key（如 `icbc`）；可空。 */
        @Size(max = 32, message = "图标标识过长") String icon,

        @NotBlank(message = "type 不能为空")
        @Pattern(regexp = "cash|bank|credit|ewallet", message = "type 只能是 cash、bank、credit 或 ewallet")
        String type,

        /** 期初余额（分）；credit 类填欠款，通常为负数。 */
        Long initialBalanceCents,

        Integer sortOrder,

        /** 仅修改时有意义：归档 / 取消归档。 */
        Boolean archived,

        /** 修改时用于保持 id；新建忽略。 */
        UUID id) {}
