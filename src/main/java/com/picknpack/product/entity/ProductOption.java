package com.picknpack.product.entity;

import com.picknpack.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "product_option")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ProductOption extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 옵션 값 하나 (블랙, 270mm ...). 어느 종류(컬러, 사이즈)의 값인지는 ProductOptionType 이 갖는다.
     * 상품은 optionType.productMaster 로 도출하므로 여기에 product_id 를 두지 않는다.
     *
     * //@ManyToOne	                        여러 ProductOption이 하나의 ProductOptionType에 속한다
     * fetch = FetchType.LAZY	            ProductOptionType 정보를 지금 당장 안 가져오고, 실제로 접근할 때 가져온다
     *      cf) FetchType.EAGER (즉시 로딩)   ProductOption을 조회하면 ProductOptionType도 같이 조회 (기본 값)
     * //@JoinColumn(name = "option_type_id")	DB에서 option_type_id 컬럼으로 연결한다 (FK 컬럼명)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "option_type_id", nullable = false)
    private ProductOptionType optionType;

    @Column(name = "option_value", nullable = false)
    private String optionValue;

    // 종류 안에서 값을 나열하는 순서 (260mm → 270mm → 280mm)
    @Column(name = "display_order", nullable = false)
    private Integer displayOrder = 0;
}
