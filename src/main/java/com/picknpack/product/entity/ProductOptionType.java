package com.picknpack.product.entity;

import com.picknpack.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * 상품의 옵션 종류 (컬러, 사이즈 ...).
 * display_order = 상품 안에서 종류를 나열하는 순서. SKU 표시명("블랙/270mm")도 이 순서를 따른다.
 * 코드·분류 표의 sort_order(목록 정렬)와 달리, 옵션 표는 화면 표시 순서라는 뜻을 살려 display_order 로 이름 붙였다.
 * 값(블랙, 화이트 ...)은 ProductOption 에 있다.
 */
@Entity
@Table(name = "product_option_type", uniqueConstraints = {
    @UniqueConstraint(name = "UQ_product_option_type", columnNames = {"product_id", "name"})
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ProductOptionType extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // product_master (1) ──→ (N) product_option_type
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private ProductMaster productMaster;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "display_order", nullable = false)
    private Integer displayOrder = 0;

    // product_option_type (1) ──→ (N) product_option
    @OneToMany(mappedBy = "optionType")
    private List<ProductOption> options = new ArrayList<>();
}
