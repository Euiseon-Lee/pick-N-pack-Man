package com.picknpack.product.entity;

import com.picknpack.common.entity.BaseTimeEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "inventory", uniqueConstraints = {
    @UniqueConstraint(name = "UQ_inventory_item_warehouse", columnNames = {"product_item_id", "warehouse_id"})
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Inventory extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_item_id", nullable = false)
    private ProductItem productItem;

    @Column(name = "total_stock", nullable = false)
    private Integer totalStock = 0;

    @Column(name = "available_stock", nullable = false)
    private Integer availableStock = 0;

    @Column(name = "reserved_stock", nullable = false)
    private Integer reservedStock = 0;

    @Column(name = "defective_stock", nullable = false)
    private Integer defectiveStock = 0;

    @Column(name = "warehouse_id", length = 100, nullable = false)
    private String warehouseId;

    @Column(name = "warehouse_name")
    private String warehouseName;

    @Column(name = "last_synced_at")
    private LocalDateTime lastSyncedAt;
}
