package com.picknpack.order.entity;

import com.picknpack.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "order_master")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class OrderMaster extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 내부 식별
    @Column(name = "pnp_order_no", nullable = false, length = 100, unique = true)
    private String pnpOrderNo;

    // 파생 원본 (CS 교환/분실 등으로 생성된 경우)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "origin_order_id")
    private OrderMaster originOrder;

    // 마켓플레이스 정보
    @Column(name = "marketplace_order_id", length = 100)
    private String marketplaceOrderId;

    @Column(name = "marketplace_type", length = 50)
    private String marketplaceType;

    @Column(name = "marketplace_seller_id")
    private String marketplaceSellerId;

    @Column(name = "marketplace_seller_name")
    private String marketplaceSellerName;

    // 주문자 정보
    @Column(name = "orderer_name", length = 100)
    private String ordererName;

    @Column(name = "orderer_mobile", length = 20)
    private String ordererMobile;

    @Column(name = "orderer_email", length = 200)
    private String ordererEmail;

    @Column(name = "ordered_at")
    private LocalDateTime orderedAt;

    // 수령자 정보
    @Column(name = "receiver_name", length = 100)
    private String receiverName;

    @Column(name = "receiver_zipcode", length = 50)
    private String receiverZipcode;

    @Column(name = "receiver_address", length = 500)
    private String receiverAddress;

    @Column(name = "receiver_address_detail", length = 500)
    private String receiverAddressDetail;

    @Column(name = "receiver_mobile", length = 20)
    private String receiverMobile;

    @Column(name = "receiver_tel", length = 20)
    private String receiverTel;

    @Column(name = "delivery_request", columnDefinition = "TEXT")
    private String deliveryRequest;

    // 결제 정보
    @Column(name = "total_amount", precision = 15, scale = 2)
    private BigDecimal totalAmount;

    @Column(name = "delivery_fee", precision = 15, scale = 2)
    private BigDecimal deliveryFee;

    @Column(name = "discount_amount", precision = 15, scale = 2)
    private BigDecimal discountAmount;

    @Column(name = "payment_method", length = 50)
    private String paymentMethod;

    @Column(name = "payment_status", length = 50)
    private String paymentStatus;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    // 상태/관리 - 출고보류
    @Column(name = "is_shipment_on_hold")
    private short isShipmentOnHold;

    @Column(name = "shipment_hold_user_id", length = 100)
    private String shipmentHoldUserId;

    @Column(name = "shipment_hold_at")
    private LocalDateTime shipmentHoldAt;

    // 상태/관리 - 취소
    @Column(name = "is_canceled")
    private short isCanceled;

    @Column(name = "canceled_user_id", length = 100)
    private String canceledUserId;

    @Column(name = "canceled_at")
    private LocalDateTime canceledAt;

    // 상태/관리 - 삭제
    @Column(name = "is_deleted")
    private short isDeleted;

    @Column(name = "deleted_user_id", length = 100)
    private String deletedUserId;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    // 원본 데이터
    @Column(name = "raw_data", columnDefinition = "jsonb")
    private String rawData;

    // TODO: OrderItem 생성 후 연관관계 추가
    // @OneToMany(mappedBy = "orderMaster")
    // private List<OrderItem> orderItems = new ArrayList<>();
}