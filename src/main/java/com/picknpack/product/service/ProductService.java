package com.picknpack.product.service;

import com.picknpack.product.dto.request.CreateProductRequest;
import com.picknpack.product.dto.response.ProductResponse;
import com.picknpack.product.entity.ProductMaster;
import com.picknpack.product.repository.ProductMasterRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

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

    // TODO : JPQL 작성해서 DTO로 조회(Projection)하는 방식으로 추후에 개선할 것
    /**
     *  DB: [ProductMaster#1, ProductMaster#2, ProductMaster#3]
     *          ↓ for문으로 하나씩 변환
     *  결과: [ProductResponse#1, ProductResponse#2, ProductResponse#3]
     *  <p>
     *  Entity (ProductMaster)
     *      → DB 테이블의 한 행을 표현, 내부용 (서버가 DB와 주고받을 때 사용)
     *  DTO (ProductResponse)
     *      → 클라이언트와 주고받는 데이터 형태, 외부용 (API 응답)
     *  <p>
     *  그대로 반환하면 안되는 이유?
     *      1) @OneToMany로 연결된 productItems, productOptions가 전부 조회되어 불필요한 정보가 노출됨, DTO(ProductResponse)에는 필요한 필드만 선언해서 사용
     *      2) Entity를 그대로 쓰면, DB 컬럼을 변경할 때마다 API 응답도 변경됨
     *      3) Lazy Loading 문제: 이건 관련 데이터를 실제 접근할 때만 가져온다는 뜻인데, Entity를 JSON으로 변환할 때 Jackson이 모든 필드에 접근하니까 추가 쿼리가 계속 발생하게 됨
     *  <p>
     *  처음부터 JPQL 작성해서 DTO로 조회(Projection)하는 방식도 있지만, 기본적인 동작 이해부터 공부하는 것
     * @return List<ProductResponse>
     */
    public List<ProductResponse> getProducts() {
        List<ProductMaster> products = productMasterRepository.findAll();
        List<ProductResponse> result = new ArrayList<>();

        // products 리스트를 하나씩 꺼내면서 DTO로 변환해서 result에 추가
        for(ProductMaster product : products) {
            result.add(ProductResponse.from(product));
        }
        return result;
    }
}
