package com.picknpack.order.entity;

import com.picknpack.common.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "order_item")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class OrderItem extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private OrderMaster orderMaster ;

    @Column(name = "origin_order_item_id")
    private Long originOrderItemId;

    @Column(name = "marketplace_product_id")
    private String marketplaceProductId;

    @Column(name = "marketplace_product_name")
    private String marketplaceProductName;

    @Column(name = "marketplace_option_id")
    private String marketplaceOptionId;

    @Column(name = "marketplace_option_name", columnDefinition = "TEXT")
    private String marketplaceOptionName;

    @Column(name = "matched_product_id")
    private Long matchedProductId;

    @Column(name = "matched_product_item_id")
    private Long matchedProductItemId;

    @Column(name = "matching_status", nullable = false)
    private Integer matchingStatus = 1;

    @Column(name = "quantity")
    private Integer quantity;

    @Column(name = "unit_price", precision = 15, scale = 2)
    private BigDecimal unitPrice;

    @Column(name = "total_amount", precision = 15, scale = 2)
    private BigDecimal totalAmount;

    @Column(name= "is_shipment_on_hold")
    private Short isShipmentOnHold;

    @Column(name = "shipment_hold_user_id", length = 100)
    private String shipmentHoldUserId;

    @Column(name = "shipment_hold_at")
    private LocalDateTime shipmentHoldAt;

    @Column(name= "is_canceled")
    private Short isCanceled;

    @Column(name = "canceled_user_id", length = 100)
    private String canceledUserId;

    @Column(name = "canceled_at")
    private LocalDateTime canceledAt;

    @Column(name= "is_deleted")
    private Short isDeleted;

    @Column(name = "deleted_user_id", length = 100)
    private String deletedUserId;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;
}
