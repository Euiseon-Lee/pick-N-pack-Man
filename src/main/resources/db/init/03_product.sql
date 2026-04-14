-- ============================================
-- product_master (상품 마스터)
-- ============================================
CREATE TABLE product_master (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    name                        VARCHAR(255)    NOT NULL,
    code                        VARCHAR(100),
    status                      INT             NOT NULL DEFAULT 1,
    description                 TEXT,

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX UQ_product_master_code ON product_master (code);

COMMENT ON TABLE product_master IS '상품 마스터';
COMMENT ON COLUMN product_master.name IS '상품명';
COMMENT ON COLUMN product_master.code IS '상품코드';
COMMENT ON COLUMN product_master.status IS '상태 (common_code 참조)';
COMMENT ON COLUMN product_master.description IS '상품 설명';


-- ============================================
-- product_option (상품 옵션)
-- ============================================
CREATE TABLE product_option (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    product_id                  BIGINT          NOT NULL REFERENCES product_master (id),

    option_type                 VARCHAR(100)    NOT NULL,
    option_value                VARCHAR(255)    NOT NULL,
    sort_order                  INT             NOT NULL DEFAULT 0,

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IDX_product_option_product_id ON product_option (product_id);
CREATE INDEX IDX_product_option_option_type ON product_option (product_id, option_type);

COMMENT ON TABLE product_option IS '상품 옵션';
COMMENT ON COLUMN product_option.product_id IS 'product_master.id';
COMMENT ON COLUMN product_option.option_type IS '옵션 유형 (컬러, 사이즈 등)';
COMMENT ON COLUMN product_option.option_value IS '옵션 값 (블랙, 270mm 등)';
COMMENT ON COLUMN product_option.sort_order IS '정렬 순서';
COMMENT ON COLUMN product_option.created_user_id IS '생성자';
COMMENT ON COLUMN product_option.updated_user_id IS '수정자';


-- ============================================
-- product_item (SKU)
-- ============================================
CREATE TABLE product_item (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    product_id                  BIGINT          NOT NULL REFERENCES product_master (id),

    barcode                     VARCHAR(100),
    sku_code                    VARCHAR(100),
    option_name                 VARCHAR(255),
    unit_price                  DECIMAL(15,2),
    cost_price                  DECIMAL(15,2),
    status                      INT             NOT NULL DEFAULT 1,

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX UQ_product_item_barcode ON product_item (barcode);
CREATE INDEX IDX_product_item_product_id ON product_item (product_id);
CREATE INDEX IDX_product_item_sku_code ON product_item (sku_code);
CREATE INDEX IDX_product_item_status ON product_item (status);

COMMENT ON TABLE product_item IS 'SKU (상품 옵션 조합)';
COMMENT ON COLUMN product_item.product_id IS 'product_master.id';
COMMENT ON COLUMN product_item.barcode IS '바코드';
COMMENT ON COLUMN product_item.sku_code IS 'SKU 코드';
COMMENT ON COLUMN product_item.option_name IS '옵션 조합 텍스트 (블랙/270mm)';
COMMENT ON COLUMN product_item.unit_price IS '판매 단가';
COMMENT ON COLUMN product_item.cost_price IS '원가';
COMMENT ON COLUMN product_item.status IS '상태 (common_code 참조)';


-- ============================================
-- product_item_option (SKU ↔ 옵션 매핑)
-- ============================================
CREATE TABLE product_item_option (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    product_item_id             BIGINT          NOT NULL REFERENCES product_item (id),
    option_id                   BIGINT          NOT NULL REFERENCES product_option (id)
);

CREATE UNIQUE INDEX UQ_product_item_option ON product_item_option (product_item_id, option_id);
CREATE INDEX IDX_product_item_option_option_id ON product_item_option (option_id);

COMMENT ON TABLE product_item_option IS 'SKU-옵션 매핑';
COMMENT ON COLUMN product_item_option.product_item_id IS 'product_item.id';
COMMENT ON COLUMN product_item_option.option_id IS 'product_option.id';


-- ============================================
-- inventory (재고)
-- ============================================
CREATE TABLE inventory (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    product_item_id             BIGINT          NOT NULL REFERENCES product_item (id),

    total_stock                 INT             NOT NULL DEFAULT 0,
    available_stock             INT             NOT NULL DEFAULT 0,
    reserved_stock              INT             NOT NULL DEFAULT 0,
    defective_stock             INT             NOT NULL DEFAULT 0,

    warehouse_id                VARCHAR(100)    NOT NULL,
    warehouse_name              VARCHAR(255),

    last_synced_at              TIMESTAMP,

    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX UQ_inventory_item_warehouse ON inventory (product_item_id, warehouse_id);
CREATE INDEX IDX_inventory_product_item_id ON inventory (product_item_id);
CREATE INDEX IDX_inventory_warehouse_id ON inventory (warehouse_id);

COMMENT ON TABLE inventory IS '재고';
COMMENT ON COLUMN inventory.product_item_id IS 'product_item.id';
COMMENT ON COLUMN inventory.total_stock IS '총 재고';
COMMENT ON COLUMN inventory.available_stock IS '가용 재고';
COMMENT ON COLUMN inventory.reserved_stock IS '예약 재고 (출고 예정)';
COMMENT ON COLUMN inventory.defective_stock IS '불량 재고';
COMMENT ON COLUMN inventory.warehouse_id IS '창고 ID';
COMMENT ON COLUMN inventory.warehouse_name IS '창고명';
COMMENT ON COLUMN inventory.last_synced_at IS 'WMS 마지막 동기화 일시';


-- ============================================
-- marketplace_product_mapping (마켓 상품 ↔ 우리 상품 매핑)
-- ============================================
CREATE TABLE marketplace_product_mapping (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    marketplace_type            VARCHAR(50)     NOT NULL,
    marketplace_seller_id       VARCHAR(255)    NOT NULL,
    marketplace_product_id      VARCHAR(255)    NOT NULL,
    marketplace_option_id       VARCHAR(255),

    product_id                  BIGINT          NOT NULL REFERENCES product_master (id),
    product_item_id             BIGINT          REFERENCES product_item (id),

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX UQ_marketplace_product_mapping ON marketplace_product_mapping (
    marketplace_type, marketplace_seller_id, marketplace_product_id, marketplace_option_id
);
CREATE INDEX IDX_marketplace_product_mapping_product_id ON marketplace_product_mapping (product_id);
CREATE INDEX IDX_marketplace_product_mapping_product_item_id ON marketplace_product_mapping (product_item_id);

COMMENT ON TABLE marketplace_product_mapping IS '마켓 상품 ↔ 우리 상품 매핑';
COMMENT ON COLUMN marketplace_product_mapping.marketplace_type IS '마켓 구분 (naver, cafe24 등)';
COMMENT ON COLUMN marketplace_product_mapping.marketplace_seller_id IS '마켓 판매처 ID';
COMMENT ON COLUMN marketplace_product_mapping.marketplace_product_id IS '마켓 상품 식별코드';
COMMENT ON COLUMN marketplace_product_mapping.marketplace_option_id IS '마켓 옵션 식별코드 (옵션 없으면 null)';
COMMENT ON COLUMN marketplace_product_mapping.product_id IS 'product_master.id';
COMMENT ON COLUMN marketplace_product_mapping.product_item_id IS 'product_item.id (SKU)';
COMMENT ON COLUMN marketplace_product_mapping.created_user_id IS '생성자';
COMMENT ON COLUMN marketplace_product_mapping.updated_user_id IS '수정자';
