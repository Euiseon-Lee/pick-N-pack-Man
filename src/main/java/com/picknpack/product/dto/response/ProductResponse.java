package com.picknpack.product.dto.response;

import com.picknpack.product.entity.ProductMaster;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class ProductResponse {

    private Long id;
    private String name;
    private String code;
    private Integer status;
    private String description;
    private LocalDateTime createdAt;

    /** Entity → Response DTO로 변환하는 메서드
     * static: 객체를 만들지 않고도, 객체 없이 클래스 이름으로 직접 호출
     *         Entity → DTO 변환을 매번 Service에 쓰면 중복이 생기니까, DTO 안에 변환 로직을 넣어둔 것
     * @param entity    ProductMaster
     * @return          ProductResponse
     */
    public static ProductResponse from(ProductMaster entity) {
        ProductResponse response = new ProductResponse();
        response.id = entity.getId();
        response.name = entity.getName();
        response.code = entity.getCode();
        response.status = entity.getStatus();
        response.description = entity.getDescription();
        response.createdAt = entity.getCreatedAt();
        return response;
    }
}
