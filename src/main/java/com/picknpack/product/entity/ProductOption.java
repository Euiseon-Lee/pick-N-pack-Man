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
     * //@ManyToOne	                        여러 ProductOption이 하나의 ProductMaster에 속한다
     * fetch = FetchType.LAZY	            ProductMaster 정보를 지금 당장 안 가져오고, 실제로 접근할 때 가져온다
     *      cf) FetchType.EAGER (즉시 로딩)   ProductOption을 조회하면 ProductMaster도 같이 조회 (기본 값)
     * //@JoinColumn(name = "product_id")	    DB에서 product_id 컬럼으로 연결한다 (FK 컬럼명)
     * private ProductMaster productMaster	Java에서는 ID 숫자(Long) 대신 ProductMaster 객체 자체를 필드로 가지므로, 객체 자체를 참조
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private ProductMaster productMaster;

    @Column(name = "option_type", nullable = false, length = 100)
    private String optionType;

    @Column(name = "option_value", nullable = false)
    private String optionValue;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder = 0;
}
