package com.haven.backend.ledger.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * 确认写入一批记账记录。
 * <p>
 * {@code batchId} 由客户端生成，重复提交同一批次时不会重复写入。
 */
public record CreateLedgerBatchRequest(

        @NotBlank(message = "batch_id 不能为空")
        @Size(max = 64, message = "batch_id 不能超过 64 个字符")
        String batchId,

        /** 可选：原始输入文本，便于追溯。 */
        String rawText,

        @NotEmpty(message = "items 不能为空")
        @Valid
        List<CreateLedgerEntryRequest> items
) {
}
