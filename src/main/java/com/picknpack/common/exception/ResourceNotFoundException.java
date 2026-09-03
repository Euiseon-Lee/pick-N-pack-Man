package com.picknpack.common.exception;

/**
 * 조회 대상이 없을 때 던지는 예외.
 * GlobalExceptionHandler가 받아서 404로 변환한다.
 * (IllegalArgumentException을 쓰면 Spring 기본 처리에서 500으로 떨어짐)
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }

    public static ResourceNotFoundException of(String resource, Long id) {
        return new ResourceNotFoundException(resource + "을(를) 찾을 수 없습니다. id=" + id);
    }
}
