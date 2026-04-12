package com.picknpack.product.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "product_item_option", uniqueConstraints = {
    @UniqueConstraint(name = "UQ_product_item_option", columnNames = {"product_item_id", "option_id"})
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ProductItemOption {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_item_id", nullable = false)
    private ProductItem productItem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "option_id", nullable = false)
    private ProductOption productOption;
}
