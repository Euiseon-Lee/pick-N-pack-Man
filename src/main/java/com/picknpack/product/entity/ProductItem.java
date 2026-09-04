package com.picknpack.product.entity;

import com.picknpack.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "product_item")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ProductItem extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // product_master (1) ──→ (N) product_item
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private ProductMaster productMaster;

    @Column(name = "barcode", length = 100, unique = true)
    private String barcode;

    @Column(name = "sku_code", length = 100)
    private String skuCode;

    // 표시명("블랙/270mm")은 저장하지 않는다. product_item_option 의 값들을 옵션 종류 display_order 순으로 이어 붙여 만든다

    @Column(name = "unit_price", precision = 15, scale = 2)
    private BigDecimal unitPrice;

    @Column(name = "cost_price", precision = 15, scale = 2)
    private BigDecimal costPrice;

    @Column(nullable = false)
    private Integer status = 1;

    // product_item (1) ──→ (N) inventory
    @OneToMany(mappedBy = "productItem")
    private List<Inventory> inventories = new ArrayList<>();
}
