-- ============================================
-- common_code (공통 코드)
-- ============================================
CREATE TABLE common_code (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    group_code                  VARCHAR(50)     NOT NULL,
    code                        INT             NOT NULL,
    name                        VARCHAR(100)    NOT NULL,
    description                 VARCHAR(255),
    sort_order                  INT             NOT NULL DEFAULT 0,
    is_active                   SMALLINT        NOT NULL DEFAULT 1,

    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX UQ_common_code_group_code ON common_code (group_code, code);
CREATE INDEX IDX_common_code_group ON common_code (group_code);

COMMENT ON TABLE common_code IS '공통 코드';
COMMENT ON COLUMN common_code.group_code IS '그룹 식별';
COMMENT ON COLUMN common_code.code IS '코드 값';
COMMENT ON COLUMN common_code.name IS '코드명';
COMMENT ON COLUMN common_code.description IS '설명';
COMMENT ON COLUMN common_code.sort_order IS '정렬 순서';
COMMENT ON COLUMN common_code.is_active IS '사용 여부';


-- ============================================
-- common_code 초기 데이터 (전체)
-- ============================================
INSERT INTO common_code (group_code, code, name, description, sort_order) VALUES
-- 매칭 상태 (order_item.matching_status)
('MATCHING_STATUS', 1, 'NOT_MATCHED',      '미매칭',          1),
('MATCHING_STATUS', 2, 'PRODUCT_MATCHED',   '상품매칭 완료',    2),
('MATCHING_STATUS', 3, 'STOCK_MATCHED',     '재고매칭 완료',    3),

-- 주문 상품 변경 이력 유형 (order_item_history.history_type)
('ORDER_ITEM_HISTORY_TYPE', 1,  'CREATED',             '생성',            1),
('ORDER_ITEM_HISTORY_TYPE', 2,  'PRODUCT_MATCHED',     '상품 매칭',       2),
('ORDER_ITEM_HISTORY_TYPE', 3,  'STOCK_MATCHED',       '재고(SKU) 매칭',  3),
('ORDER_ITEM_HISTORY_TYPE', 4,  'UNMATCHED',           '매칭 해제',       4),
('ORDER_ITEM_HISTORY_TYPE', 5,  'HOLD',                '출고보류',        5),
('ORDER_ITEM_HISTORY_TYPE', 6,  'HOLD_RELEASED',       '출고보류 해제',    6),
('ORDER_ITEM_HISTORY_TYPE', 7,  'CANCELED',            '취소',            7),
('ORDER_ITEM_HISTORY_TYPE', 8,  'RESTORED',            '취소 복구',       8),
('ORDER_ITEM_HISTORY_TYPE', 9,  'QUANTITY_SPLIT',      '수량 분리',       9),
('ORDER_ITEM_HISTORY_TYPE', 10, 'CLAIM_REQUESTED',     '클레임 접수',     10),
('ORDER_ITEM_HISTORY_TYPE', 11, 'CLAIM_COMPLETED',     '클레임 완료',     11),
('ORDER_ITEM_HISTORY_TYPE', 12, 'DELETED',             '삭제',            12),

-- 상품 상태 (product_master.status)
('PRODUCT_STATUS', 1, 'ACTIVE',            '활성',            1),
('PRODUCT_STATUS', 2, 'INACTIVE',          '비활성',          2),
('PRODUCT_STATUS', 3, 'DISCONTINUED',      '단종',            3),

-- SKU 상태 (product_item.status)
('SKU_STATUS', 1, 'ACTIVE',               '활성',            1),
('SKU_STATUS', 2, 'INACTIVE',             '비활성',          2),
('SKU_STATUS', 3, 'OUT_OF_STOCK',         '품절',            3),

-- 출고 상태 (shipment_master.status)
('SHIPMENT_STATUS', 1, 'PENDING',             '출고 대기',       1),
('SHIPMENT_STATUS', 2, 'SHIPMENT_REQUESTED',  '출고요청 완료',    2),
('SHIPMENT_STATUS', 3, 'SHIPPED',             '발송완료',        3),
('SHIPMENT_STATUS', 4, 'SHIPMENT_FAILED',     '출고 실패',       4),
('SHIPMENT_STATUS', 5, 'SHIPMENT_ON_HOLD',    '출고보류',        5),

-- 출고 상품 상태 (shipment_item.status)
('SHIPMENT_ITEM_STATUS', 1, 'PENDING',         '대기',            1),
('SHIPMENT_ITEM_STATUS', 2, 'SHIPPED',          '발송완료',        2),
('SHIPMENT_ITEM_STATUS', 3, 'CANCELLED',        '취소됨',          3),

-- 출고 유형 (shipment_master.shipment_type, WMS 참고용)
('SHIPMENT_TYPE', 1, 'TRANSFER',              '이관형',          1),
('SHIPMENT_TYPE', 2, 'DIRECT',                '직접출고',        2),

-- CS 이력 유형 (cs_history.history_type)
('HISTORY_TYPE', 1, 'CONSULT',                '수동 상담',       1),
('HISTORY_TYPE', 2, 'CLAIM',                  '클레임',          2),

-- CS 처리 상태
('CS_STATUS', 1, 'REQUESTED',                 '미처리',          1),
('CS_STATUS', 2, 'COMPLETED',                 '처리완료',        2),
('CS_STATUS', 3, 'PROCESSING',                '처리중',          3);
