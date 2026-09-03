package com.picknpack.common.dto;

import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 에러 응답 공통 포맷.
 * {
 *   "status": 404,
 *   "message": "상품을 찾을 수 없습니다. id=1",
 *   "errors": ["name: 상품명은 필수입니다"],   ← 검증 실패 시에만
 *   "timestamp": "2026-09-03T12:00:00"
 * }
 */
@Getter
public class ErrorResponse {

    private final int status;
    private final String message;
    private final List<String> errors;
    private final LocalDateTime timestamp = LocalDateTime.now();

    private ErrorResponse(int status, String message, List<String> errors) {
        this.status = status;
        this.message = message;
        this.errors = errors;
    }

    public static ErrorResponse of(int status, String message) {
        return new ErrorResponse(status, message, List.of());
    }

    public static ErrorResponse of(int status, String message, List<String> errors) {
        return new ErrorResponse(status, message, errors);
    }
}
