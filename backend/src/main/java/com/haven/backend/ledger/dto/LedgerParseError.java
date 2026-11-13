package com.haven.backend.ledger.dto;

/**
 * quick 接口的单行解析错误。
 */
public record LedgerParseError(int line, String raw, String message) {
}
