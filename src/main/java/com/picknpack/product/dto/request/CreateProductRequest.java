package com.picknpack.product.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

/** 어노테이션 @Setter가 없는데 값이 들어가는 이유
 *  Spring이 JSON을 Java 객체로 변환할 때 Jackson 라이브러리를 사용
 *  Jackson은 @Setter 없이도 필드에 값을 넣을 수 있음 (리플렉션 사용)
 */
@Getter
public class CreateProductRequest {

    /** 어노테이션 @NotBlank
     *  build.gradle.kts에 추가한 spring-boot-starter-validation의 기능
     *  이 필드가 비어있으면 에러를 발생시킴
     */
    @NotBlank(message = "상품명은 필수입니다")
    private String name;

    private String code;

    private String description;
}
