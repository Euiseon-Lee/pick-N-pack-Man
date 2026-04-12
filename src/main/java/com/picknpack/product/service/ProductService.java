package com.picknpack.product.service;

import com.picknpack.product.dto.request.CreateProductRequest;
import com.picknpack.product.dto.response.ProductResponse;
import com.picknpack.product.entity.ProductMaster;
import com.picknpack.product.repository.ProductMasterRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor        // Lombok이 final 필드를 매개변수로 받는 생성자를 자동 생성, 이 생성자를 통해 Spring이 자동으로 ProductMasterRepository를 넣어줌 → 의존성 주입(Dependency Injection)
@Transactional(readOnly = true)
public class ProductService {
    private final ProductMasterRepository productMasterRepository;

    /**
     * CreateProductRequest (클라이언트가 보낸 데이터)
     *     ↓ 1. Entity 생성
     * ProductMaster (DB에 넣을 객체)
     *     ↓ 2. repository.save()
     * ProductMaster (DB에서 ID가 채워진 객체)
     *     ↓ 3. ProductResponse.from()
     * ProductResponse (클라이언트에 보낼 데이터)
     *
     * @param request   CreateProductRequest
     * @return          ProductResponse
     */
    @Transactional
    public ProductResponse createProduct(CreateProductRequest request) {
        // 1. Entity 생성
        ProductMaster product = new ProductMaster(
            request.getName()
            , request.getCode()
            , request.getDescription()
        );

        // 2. DB 저장
        ProductMaster saved = productMasterRepository.save(product);

        // 3. Entity → Response DTO 변환 후 반환
        return ProductResponse.from(saved);
    }
}
