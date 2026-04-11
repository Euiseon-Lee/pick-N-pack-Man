-- ============================================
-- shipment_master (출고 마스터)
-- ============================================
CREATE TABLE shipment_master (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    receiver_name               VARCHAR(100),
    receiver_zipcode            VARCHAR(50),
    receiver_address            VARCHAR(500),
    receiver_address_detail     VARCHAR(500),
    receiver_mobile             VARCHAR(20),
    receiver_tel                VARCHAR(20),
    delivery_request            TEXT,

    deliver_code                VARCHAR(20),
    invoice_number              VARCHAR(50),
    status                      INT             NOT NULL DEFAULT 1,
    shipment_type               INT,

    is_sent                     SMALLINT,
    sent_at                     TIMESTAMP,

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

CREATE INDEX IDX_shipment_master_status ON shipment_master (status);
CREATE INDEX IDX_shipment_master_invoice_number ON shipment_master (invoice_number);

COMMENT ON TABLE shipment_master IS '출고 마스터';
COMMENT ON COLUMN shipment_master.receiver_name IS '수령자명';
COMMENT ON COLUMN shipment_master.receiver_zipcode IS '우편번호';
COMMENT ON COLUMN shipment_master.receiver_address IS '주소';
COMMENT ON COLUMN shipment_master.receiver_address_detail IS '상세주소';
COMMENT ON COLUMN shipment_master.receiver_mobile IS '수령자 휴대폰 (1순위)';
COMMENT ON COLUMN shipment_master.receiver_tel IS '수령자 유선전화 (2순위)';
COMMENT ON COLUMN shipment_master.delivery_request IS '배송 요청사항';
COMMENT ON COLUMN shipment_master.deliver_code IS '택배사 코드';
COMMENT ON COLUMN shipment_master.invoice_number IS '운송장번호';
COMMENT ON COLUMN shipment_master.status IS '출고상태 (common_code 참조)';
COMMENT ON COLUMN shipment_master.shipment_type IS '출고유형 (common_code 참조, WMS 참고용)';
COMMENT ON COLUMN shipment_master.is_sent IS 'WMS 이관 여부 (null=미이관, 1=이관)';
COMMENT ON COLUMN shipment_master.sent_at IS 'WMS 이관 일시';
COMMENT ON COLUMN shipment_master.is_canceled IS '취소 (null=정상, 1=취소)';
COMMENT ON COLUMN shipment_master.is_deleted IS '삭제 (null=정상, 1=삭제)';


-- ============================================
-- shipment_item (출고 상품)
-- ============================================
CREATE TABLE shipment_item (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    shipment_id                 BIGINT          NOT NULL REFERENCES shipment_master (id),
    order_id                    BIGINT          NOT NULL,
    order_item_id               BIGINT          NOT NULL,
    product_item_id             BIGINT,

    quantity                    INT,
    status                      INT             DEFAULT 1,

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

CREATE INDEX IDX_shipment_item_shipment_id ON shipment_item (shipment_id);
CREATE INDEX IDX_shipment_item_order_id ON shipment_item (order_id);
CREATE INDEX IDX_shipment_item_order_item_id ON shipment_item (order_item_id);
CREATE INDEX IDX_shipment_item_product_item_id ON shipment_item (product_item_id);

COMMENT ON TABLE shipment_item IS '출고 상품';
COMMENT ON COLUMN shipment_item.shipment_id IS 'shipment_master.id';
COMMENT ON COLUMN shipment_item.order_id IS 'order_master.id';
COMMENT ON COLUMN shipment_item.order_item_id IS 'order_item.id';
COMMENT ON COLUMN shipment_item.product_item_id IS 'product_item.id (SKU)';
COMMENT ON COLUMN shipment_item.quantity IS '출고 수량';
COMMENT ON COLUMN shipment_item.status IS '출고상태 (common_code 참조)';
COMMENT ON COLUMN shipment_item.is_canceled IS '취소 (null=정상, 1=취소)';
COMMENT ON COLUMN shipment_item.is_deleted IS '삭제 (null=정상, 1=삭제)';
