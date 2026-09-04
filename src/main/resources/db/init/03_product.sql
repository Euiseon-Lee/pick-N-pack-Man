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
-- product_option_type (상품 옵션 종류)
-- ============================================
CREATE TABLE product_option_type (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    product_id                  BIGINT          NOT NULL REFERENCES product_master (id),

    name                        VARCHAR(100)    NOT NULL,
    display_order                  INT             NOT NULL DEFAULT 0,

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX UQ_product_option_type ON product_option_type (product_id, name);

COMMENT ON TABLE product_option_type IS '상품 옵션 종류 (컬러, 사이즈 ...)';
COMMENT ON COLUMN product_option_type.product_id IS 'product_master.id';
COMMENT ON COLUMN product_option_type.name IS '종류 이름 (컬러, 사이즈). 상품 안에서 UNIQUE';
COMMENT ON COLUMN product_option_type.display_order IS '상품 안에서 종류를 나열하는 순서. SKU 표시명도 이 순서를 따른다 (컬러 1, 사이즈 2 → 블랙/270mm)';


-- ============================================
-- product_option (상품 옵션 값)
-- ============================================
CREATE TABLE product_option (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    option_type_id              BIGINT          NOT NULL REFERENCES product_option_type (id),

    option_value                VARCHAR(255)    NOT NULL,
    display_order                  INT             NOT NULL DEFAULT 0,

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX UQ_product_option ON product_option (option_type_id, option_value);

COMMENT ON TABLE product_option IS '상품 옵션 값 (블랙, 270mm ...). 상품은 option_type_id → product_option_type.product_id 로 도출';
COMMENT ON COLUMN product_option.option_type_id IS 'product_option_type.id';
COMMENT ON COLUMN product_option.option_value IS '옵션 값 (블랙, 270mm 등)';
COMMENT ON COLUMN product_option.display_order IS '종류 안에서 값을 나열하는 순서 (260mm 1, 270mm 2, 280mm 3)';
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

COMMENT ON TABLE product_item IS 'SKU (상품 옵션 조합). 표시명은 저장하지 않고 product_item_option 의 값을 옵션 종류 display_order 순으로 이어 붙여 만든다';
COMMENT ON COLUMN product_item.product_id IS 'product_master.id';
COMMENT ON COLUMN product_item.barcode IS '바코드';
COMMENT ON COLUMN product_item.sku_code IS 'SKU 코드';
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
    product_item_id             BIGINT          NOT NULL REFERENCES product_item (id),

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX UQ_marketplace_product_mapping ON marketplace_product_mapping (
    marketplace_type, marketplace_seller_id, marketplace_product_id, marketplace_option_id
) NULLS NOT DISTINCT;
CREATE INDEX IDX_marketplace_product_mapping_product_id ON marketplace_product_mapping (product_id);
CREATE INDEX IDX_marketplace_product_mapping_product_item_id ON marketplace_product_mapping (product_item_id);

COMMENT ON TABLE marketplace_product_mapping IS '마켓 상품 ↔ 우리 상품 매핑';
COMMENT ON COLUMN marketplace_product_mapping.marketplace_type IS '마켓 구분 (naver, cafe24 등)';
COMMENT ON COLUMN marketplace_product_mapping.marketplace_seller_id IS '마켓 판매처 ID';
COMMENT ON COLUMN marketplace_product_mapping.marketplace_product_id IS '마켓 상품 식별코드';
COMMENT ON COLUMN marketplace_product_mapping.marketplace_option_id IS '마켓 옵션 식별코드 (옵션 없는 상품은 null. UNIQUE에서 null도 같은 값으로 취급)';
COMMENT ON COLUMN marketplace_product_mapping.product_id IS 'product_master.id';
COMMENT ON COLUMN marketplace_product_mapping.product_item_id IS 'product_item.id (SKU). 옵션 없는 상품도 단일 SKU를 가리킨다';
COMMENT ON COLUMN marketplace_product_mapping.created_user_id IS '생성자';
COMMENT ON COLUMN marketplace_product_mapping.updated_user_id IS '수정자';
