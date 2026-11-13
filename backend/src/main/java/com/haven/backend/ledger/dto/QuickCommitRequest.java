package com.haven.backend.ledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 快捷指令一步记账：解析文本并直接写入。
 * <p>
 * 与 {@code POST /api/ledger/quick} + {@code POST /api/ledger/entries/batch}
 * 的两步流程等价，只是省掉客户端搬运 items 的步骤。
 * {@code batchId} 可选：不传时服务端生成，传入相同值可保证重试幂等。
 */
public record QuickCommitRequest(

        @NotBlank(message = "text 不能为空")
        String text,

        @Size(max = 64, message = "batch_id 不能超过 64 个字符")
        String batchId
) {
}
