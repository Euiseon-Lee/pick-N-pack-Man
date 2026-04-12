package com.picknpack.product.entity;

import com.picknpack.common.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/** Entity
 *  Entity = DB 테이블의 Java 표현 → "이 클래스는 DB의 이 테이블이다" 라고 선언하는 것.
 *  Entity의 각 필드 = 테이블의 각 컬럼
 *  Entity는 DB에서 꺼낸 데이터를 담는 그릇 → DB에서 한 행(row)을 읽으면 Entity 객체 하나가 생성됨
 *
 *
 */
@Entity         // DB 테이블과 매핑되는 JPA Entity 클래스라는 annotation
@Table(name = "product_master")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)      // Lombok이 기본 생성자(매개변수 없는 생성자)를 자동 생성, protected로 생성됨
public class ProductMaster extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // @GeneratedValue → "PK 값을 자동 생성한다", strategy = GenerationType.IDENTITY → "DB의 자동 증가 기능을 사용한다"
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(length = 100, unique = true)
    private String code;

    @Column(nullable = false)
    private Integer status = 1;

    @Column(columnDefinition = "text")
    private String description;

    // product_master (1) ──→ (N) product_item
    @OneToMany(mappedBy = "productMaster")
    private List<ProductItem> productItems = new ArrayList<>();

    // product_master (1) ──→ (N) product_option
    @OneToMany(mappedBy = "productMaster")
    private List<ProductOption> productOptions = new ArrayList<>();

    public ProductMaster(String name, String code, String description) {
    this.name = name;
    this.code = code;
    this.description = description;
}
}
