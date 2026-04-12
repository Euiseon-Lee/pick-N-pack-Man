package com.picknpack.product.controller;

import com.picknpack.product.dto.request.CreateProductRequest;
import com.picknpack.product.dto.response.ProductResponse;
import com.picknpack.product.service.ProductService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 흐름 정리
 * 클라이언트: POST /api/v1/products
 *            { "name": "나이키 에어맥스", "code": "AM270", "description": "런닝화" }
 *     │
 *     ▼
 * Controller: @Valid로 검증 → @RequestBody로 JSON → CreateProductRequest 변환
 *     │
 *     ▼
 * Service: createProduct() → Entity 생성 → repository.save() → DB 저장
 *     │
 *     ▼
 * Controller: ProductResponse를 JSON으로 → 201 CREATED 응답
 *     │
 *     ▼
 * 클라이언트: { "id": 1, "name": "나이키 에어맥스", "code": "AM270", "status": 1, ... }
 */
@RestController         // @Controller + @ResponseBody → 이 클래스는 HTTP 요청을 처리하는 컨트롤러 + 반환값을 JSON으로 변환해서 응답한다
@RequestMapping("/api/v1/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

    @PostMapping
    public ResponseEntity<ProductResponse> createProduct(@Valid @RequestBody CreateProductRequest request) {
        ProductResponse response = productService.createProduct(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
