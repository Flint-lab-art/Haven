package com.haven.backend.ledger.dto;

import java.util.List;

/**
 * quick 接口结果：成功解析的条目与逐行错误分开返回。
 */
public record QuickParseResult(List<ParsedLedgerItem> items, List<LedgerParseError> errors) {
}
