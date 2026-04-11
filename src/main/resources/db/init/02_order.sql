-- ============================================
-- order_master (주문 마스터)
-- ============================================
CREATE TABLE order_master (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    pnp_order_no                VARCHAR(100)    NOT NULL,
    origin_order_id             BIGINT,

    marketplace_order_id        VARCHAR(100),
    marketplace_type            VARCHAR(50),
    marketplace_seller_id       VARCHAR(255),
    marketplace_seller_name     VARCHAR(255),

    orderer_name                VARCHAR(100),
    orderer_mobile              VARCHAR(20),
    orderer_email               VARCHAR(200),
    ordered_at                  TIMESTAMP,

    receiver_name               VARCHAR(100),
    receiver_zipcode            VARCHAR(50),
    receiver_address            VARCHAR(500),
    receiver_address_detail     VARCHAR(500),
    receiver_mobile             VARCHAR(20),
    receiver_tel                VARCHAR(20),
    delivery_request            TEXT,

    total_amount                DECIMAL(15,2),
    delivery_fee                DECIMAL(15,2),
    discount_amount             DECIMAL(15,2),
    payment_method              VARCHAR(50),
    payment_status              VARCHAR(50),
    paid_at                     TIMESTAMP,

    is_shipment_on_hold         SMALLINT,
    shipment_hold_user_id       VARCHAR(100),
    shipment_hold_at            TIMESTAMP,
    is_canceled                 SMALLINT,
    canceled_user_id            VARCHAR(100),
    canceled_at                 TIMESTAMP,
    is_deleted                  SMALLINT,
    deleted_user_id             VARCHAR(100),
    deleted_at                  TIMESTAMP,

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    raw_data                    JSONB
);

CREATE UNIQUE INDEX UQ_order_master_pnp_order_no ON order_master (pnp_order_no);
CREATE INDEX IDX_order_master_origin_order_id ON order_master (origin_order_id);
CREATE INDEX IDX_order_master_marketplace_order_id ON order_master (marketplace_order_id);
CREATE INDEX IDX_order_master_marketplace_seller ON order_master (marketplace_seller_id, marketplace_seller_name);
CREATE INDEX IDX_order_master_ordered_at ON order_master (ordered_at);

COMMENT ON TABLE order_master IS '주문 마스터';
COMMENT ON COLUMN order_master.pnp_order_no IS '내부 관리번호 (ORD-YYMMDD-000001)';
COMMENT ON COLUMN order_master.origin_order_id IS '원주문 ID (CS 교환/분실 등으로 생성된 경우)';
COMMENT ON COLUMN order_master.marketplace_order_id IS '마켓 원본 주문번호';
COMMENT ON COLUMN order_master.marketplace_type IS '마켓 구분 (naver, cafe24 등)';
COMMENT ON COLUMN order_master.marketplace_seller_id IS '마켓 판매처 ID';
COMMENT ON COLUMN order_master.marketplace_seller_name IS '마켓 판매처명';
COMMENT ON COLUMN order_master.orderer_name IS '주문자명';
COMMENT ON COLUMN order_master.orderer_mobile IS '주문자 휴대폰';
COMMENT ON COLUMN order_master.orderer_email IS '주문자 이메일';
COMMENT ON COLUMN order_master.ordered_at IS '주문일시';
COMMENT ON COLUMN order_master.receiver_name IS '수령자명';
COMMENT ON COLUMN order_master.receiver_zipcode IS '우편번호';
COMMENT ON COLUMN order_master.receiver_address IS '주소';
COMMENT ON COLUMN order_master.receiver_address_detail IS '상세주소';
COMMENT ON COLUMN order_master.receiver_mobile IS '수령자 휴대폰 (1순위)';
COMMENT ON COLUMN order_master.receiver_tel IS '수령자 유선전화 (2순위)';
COMMENT ON COLUMN order_master.delivery_request IS '배송 요청사항';
COMMENT ON COLUMN order_master.total_amount IS '총 결제금액';
COMMENT ON COLUMN order_master.delivery_fee IS '배송비';
COMMENT ON COLUMN order_master.discount_amount IS '할인금액';
COMMENT ON COLUMN order_master.payment_method IS '결제수단';
COMMENT ON COLUMN order_master.payment_status IS '결제상태';
COMMENT ON COLUMN order_master.paid_at IS '결제일시';
COMMENT ON COLUMN order_master.is_shipment_on_hold IS '전체 출고보류 (null=정상, 1=보류)';
COMMENT ON COLUMN order_master.shipment_hold_user_id IS '보류자';
COMMENT ON COLUMN order_master.shipment_hold_at IS '보류 일시';
COMMENT ON COLUMN order_master.is_canceled IS '전체 취소 (null=정상, 1=취소)';
COMMENT ON COLUMN order_master.canceled_user_id IS '취소자';
COMMENT ON COLUMN order_master.canceled_at IS '취소 일시';
COMMENT ON COLUMN order_master.is_deleted IS '전체 삭제 (null=정상, 1=삭제)';
COMMENT ON COLUMN order_master.deleted_user_id IS '삭제자';
COMMENT ON COLUMN order_master.deleted_at IS '삭제 일시';
COMMENT ON COLUMN order_master.created_user_id IS '생성자';
COMMENT ON COLUMN order_master.updated_user_id IS '수정자';
COMMENT ON COLUMN order_master.raw_data IS '크롤링 원본 데이터';


-- ============================================
-- order_item (주문 상품)
-- ============================================
CREATE TABLE order_item (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    order_id                    BIGINT          NOT NULL REFERENCES order_master (id),
    origin_order_item_id        BIGINT,

    marketplace_product_id      VARCHAR(255),
    marketplace_product_name    VARCHAR(255),
    marketplace_option_id       VARCHAR(255),
    marketplace_option_name     TEXT,

    matched_product_id          BIGINT,
    matched_product_item_id     BIGINT,
    matching_status             INT             NOT NULL DEFAULT 1,

    quantity                    INT,
    unit_price                  DECIMAL(15,2),
    total_amount                DECIMAL(15,2),

    is_shipment_on_hold         SMALLINT,
    shipment_hold_user_id       VARCHAR(100),
    shipment_hold_at            TIMESTAMP,
    is_canceled                 SMALLINT,
    canceled_user_id            VARCHAR(100),
    canceled_at                 TIMESTAMP,
    is_deleted                  SMALLINT,
    deleted_user_id             VARCHAR(100),
    deleted_at                  TIMESTAMP,

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IDX_order_item_order_id ON order_item (order_id);
CREATE INDEX IDX_order_item_origin_order_item_id ON order_item (origin_order_item_id);
CREATE INDEX IDX_order_item_matched_product_id ON order_item (matched_product_id);
CREATE INDEX IDX_order_item_matched_product_item_id ON order_item (matched_product_item_id);
CREATE INDEX IDX_order_item_matching_status ON order_item (matching_status);

COMMENT ON TABLE order_item IS '주문 상품';
COMMENT ON COLUMN order_item.order_id IS 'order_master.id';
COMMENT ON COLUMN order_item.origin_order_item_id IS '원주문상품 ID (수량 분리/CS로 생성된 경우)';
COMMENT ON COLUMN order_item.marketplace_product_id IS '마켓 상품 식별코드';
COMMENT ON COLUMN order_item.marketplace_product_name IS '마켓 상품명';
COMMENT ON COLUMN order_item.marketplace_option_id IS '마켓 옵션 식별코드';
COMMENT ON COLUMN order_item.marketplace_option_name IS '마켓 옵션명';
COMMENT ON COLUMN order_item.matched_product_id IS '매칭된 상품 ID (product_master.id)';
COMMENT ON COLUMN order_item.matched_product_item_id IS '매칭된 SKU ID (product_item.id)';
COMMENT ON COLUMN order_item.matching_status IS '매칭 상태 (common_code 참조)';
COMMENT ON COLUMN order_item.quantity IS '주문 수량';
COMMENT ON COLUMN order_item.unit_price IS '단가';
COMMENT ON COLUMN order_item.total_amount IS '총 금액 (단가 x 수량)';
COMMENT ON COLUMN order_item.is_shipment_on_hold IS '개별 출고보류 (null=정상, 1=보류)';
COMMENT ON COLUMN order_item.is_canceled IS '개별 취소 (null=정상, 1=취소)';
COMMENT ON COLUMN order_item.is_deleted IS '개별 삭제 (null=정상, 1=삭제)';


-- ============================================
-- order_item_history (주문 상품 변경 이력)
-- ============================================
CREATE TABLE order_item_history (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    order_item_id               BIGINT          NOT NULL REFERENCES order_item (id),

    history_type                INT             NOT NULL,
    snapshot                    JSONB,
    description                 TEXT,

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IDX_order_item_history_order_item_id ON order_item_history (order_item_id);
CREATE INDEX IDX_order_item_history_history_type ON order_item_history (history_type);
CREATE INDEX IDX_order_item_history_created_at ON order_item_history (created_at);

COMMENT ON TABLE order_item_history IS '주문 상품 변경 이력';
COMMENT ON COLUMN order_item_history.order_item_id IS 'order_item.id';
COMMENT ON COLUMN order_item_history.history_type IS '변경 유형 (common_code 참조)';
COMMENT ON COLUMN order_item_history.snapshot IS '변경 시점 주요 값 스냅샷';
COMMENT ON COLUMN order_item_history.description IS '변경 내용 텍스트';
COMMENT ON COLUMN order_item_history.created_user_id IS '작업자';
