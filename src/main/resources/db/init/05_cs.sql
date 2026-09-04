-- ============================================
-- cs_category (CS 분류 체계)
-- ============================================
CREATE TABLE cs_category (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    category_type               INT             NOT NULL,
    parent_id                   BIGINT,
    name                        VARCHAR(100)    NOT NULL,
    description                 VARCHAR(100),
    sort_order                  INT             NOT NULL DEFAULT 0,
    is_system                   SMALLINT        NOT NULL DEFAULT 0,
    is_active                   SMALLINT        NOT NULL DEFAULT 1,

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IDX_cs_category_type ON cs_category (category_type);
CREATE INDEX IDX_cs_category_parent_id ON cs_category (parent_id);

COMMENT ON TABLE cs_category IS 'CS 분류 체계';
COMMENT ON COLUMN cs_category.category_type IS '분류 타입 (common_code CS_CATEGORY_TYPE)';
COMMENT ON COLUMN cs_category.parent_id IS '부모 카테고리 ID (CHILD_CATEGORY일 때만)';
COMMENT ON COLUMN cs_category.name IS '분류명';
COMMENT ON COLUMN cs_category.description IS '분류 설명';
COMMENT ON COLUMN cs_category.sort_order IS '정렬 순서';
COMMENT ON COLUMN cs_category.is_system IS '시스템 데이터 여부 (1=수정/삭제 불가)';
COMMENT ON COLUMN cs_category.is_active IS '사용 여부';


-- ============================================
-- cs_claim_code (클레임 코드)
-- ============================================
CREATE TABLE cs_claim_code (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    action_type                 INT             NOT NULL,
    claim_type                  INT,
    code                        VARCHAR(50)     NOT NULL,
    name                        VARCHAR(100)    NOT NULL,
    description                 VARCHAR(100),
    status                      INT,
    sort_order                  INT             NOT NULL DEFAULT 0,

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP
);

CREATE UNIQUE INDEX UQ_cs_claim_code_code ON cs_claim_code (code);
CREATE INDEX IDX_cs_claim_code_type ON cs_claim_code (action_type);
CREATE INDEX IDX_cs_claim_code_claim_type ON cs_claim_code (claim_type);

COMMENT ON TABLE cs_claim_code IS 'CS 화면 액션 목록. 클레임 유형 자체는 common_code CLAIM_TYPE이 원천';
COMMENT ON COLUMN cs_claim_code.action_type IS '액션 타입 (common_code CLAIM_ACTION_TYPE)';
COMMENT ON COLUMN cs_claim_code.claim_type IS '이 액션이 속한 클레임 유형 (common_code CLAIM_TYPE). 클레임을 만들지 않는 공통 액션은 null';
COMMENT ON COLUMN cs_claim_code.code IS '프로그래밍 식별코드 (UNIQUE)';
COMMENT ON COLUMN cs_claim_code.name IS '액션명';
COMMENT ON COLUMN cs_claim_code.description IS '설명';
COMMENT ON COLUMN cs_claim_code.status IS '이 액션이 만드는 클레임 상태 (common_code CLAIM_STATUS, 상태를 바꾸지 않는 액션은 null)';
COMMENT ON COLUMN cs_claim_code.sort_order IS '정렬 순서';


-- ============================================
-- cs_claim (클레임)
-- ============================================
CREATE TABLE cs_claim (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    order_product_id            BIGINT          NOT NULL,
    shipment_id                 BIGINT,

    claim_type                  INT             NOT NULL,
    status                      INT             NOT NULL DEFAULT 1,
    claim_data                  JSONB,

    worker_id                   VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP
);

CREATE INDEX IDX_cs_claim_order_product_id ON cs_claim (order_product_id);
CREATE INDEX IDX_cs_claim_shipment_id ON cs_claim (shipment_id);
CREATE INDEX IDX_cs_claim_status ON cs_claim (status);

COMMENT ON TABLE cs_claim IS '클레임';
COMMENT ON COLUMN cs_claim.order_product_id IS 'order_item.id (주문은 order_item.order_id로 도출)';
COMMENT ON COLUMN cs_claim.shipment_id IS 'shipment_master.id (합포 미지정 시 NULL)';
COMMENT ON COLUMN cs_claim.claim_type IS '클레임 유형 (common_code CLAIM_TYPE)';
COMMENT ON COLUMN cs_claim.status IS '클레임 상태 (common_code CLAIM_STATUS: REQUESTED → COMPLETED 또는 CANCELED)';
COMMENT ON COLUMN cs_claim.claim_data IS '클레임 상세 + 교환 상품 정보 (추후 별도 테이블 분리 검토)';
COMMENT ON COLUMN cs_claim.worker_id IS '실제 처리 담당자';


-- ============================================
-- cs_history (상담 이력)
-- ============================================
CREATE TABLE cs_history (
    id                          BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    order_product_id            BIGINT          NOT NULL,
    shipment_id                 BIGINT,

    history_type                INT             NOT NULL,
    cs_category_id              BIGINT,
    cs_category_name            VARCHAR(100),

    is_system                   SMALLINT        NOT NULL DEFAULT 0,
    cs_target                   INT             NOT NULL DEFAULT 1,
    content                     TEXT            NOT NULL,
    is_important                SMALLINT,
    is_complete                 SMALLINT,
    is_pinned                   SMALLINT,
    linked_memo_id              BIGINT,

    is_canceled                 SMALLINT,
    canceled_user_id            VARCHAR(100),
    canceled_at                 TIMESTAMP,

    worker_id                   VARCHAR(100)    NOT NULL,
    completed_user_id           VARCHAR(100),
    completed_at                TIMESTAMP,

    created_user_id             VARCHAR(100)    NOT NULL DEFAULT 'SYSTEM',
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_user_id             VARCHAR(100),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IDX_cs_history_order_product_id ON cs_history (order_product_id);
CREATE INDEX IDX_cs_history_shipment_id ON cs_history (shipment_id);
CREATE INDEX IDX_cs_history_history_type ON cs_history (history_type);
CREATE INDEX IDX_cs_history_created_at ON cs_history (created_at);

COMMENT ON TABLE cs_history IS 'CS 상담 이력';
COMMENT ON COLUMN cs_history.order_product_id IS 'order_item.id (주문은 order_item.order_id로 도출)';
COMMENT ON COLUMN cs_history.shipment_id IS 'shipment_master.id (합포 미지정 시 NULL)';
COMMENT ON COLUMN cs_history.history_type IS '이력 유형 (common_code CS_HISTORY_TYPE: CONSULT, CLAIM)';
COMMENT ON COLUMN cs_history.cs_category_id IS 'cs_category.id 또는 cs_claim_code.id (history_type으로 구분)';
COMMENT ON COLUMN cs_history.cs_category_name IS '기록 시점 분류/액션명 (스냅샷)';
COMMENT ON COLUMN cs_history.is_system IS '시스템 자동 여부 (0=수동, 1=자동)';
COMMENT ON COLUMN cs_history.cs_target IS 'CS 처리 대상 범위 (common_code CS_TARGET)';
COMMENT ON COLUMN cs_history.content IS '처리 내용';
COMMENT ON COLUMN cs_history.is_important IS '중요 (null=아님, 1=중요)';
COMMENT ON COLUMN cs_history.is_complete IS '처리 완료 (null=미완료, 1=완료)';
COMMENT ON COLUMN cs_history.is_pinned IS '최상단 고정 (null=아님, 1=고정)';
COMMENT ON COLUMN cs_history.linked_memo_id IS '연결된 CS 메모 ID';
COMMENT ON COLUMN cs_history.is_canceled IS '취소 (null=정상, 1=취소)';
COMMENT ON COLUMN cs_history.worker_id IS '실제 처리 담당자';
COMMENT ON COLUMN cs_history.completed_user_id IS '완료 처리자';
COMMENT ON COLUMN cs_history.completed_at IS '완료 처리 일시';


-- ============================================
-- cs_category 초기 데이터
-- ============================================
INSERT INTO cs_category (id, category_type, parent_id, name, sort_order, is_system, is_active, created_user_id)
OVERRIDING SYSTEM VALUE VALUES
  (1,  2, NULL, '일반상담',    10, 1, 1, 'SYSTEM')
, (2,  2, NULL, '교환',       20, 1, 1, 'SYSTEM')
, (3,  2, NULL, '맞교환',     30, 1, 1, 'SYSTEM')
, (4,  2, NULL, '발송전취소',  40, 1, 1, 'SYSTEM')
, (5,  2, NULL, '발송후반품',  50, 1, 1, 'SYSTEM')
, (6,  2, NULL, '배송문제',    60, 1, 1, 'SYSTEM')
, (7,  2, NULL, '발송후회수',  70, 1, 1, 'SYSTEM')
, (8,  2, NULL, '주문수정',    80, 1, 1, 'SYSTEM')
, (9,  2, NULL, '품절취소',    90, 1, 1, 'SYSTEM')
, (10, 2, NULL, '기타',       100, 1, 1, 'SYSTEM');

SELECT setval('cs_category_id_seq', 10);

INSERT INTO cs_category (category_type, parent_id, name, sort_order, is_system, is_active, created_user_id) VALUES
  (3, 2, '교환완료',              10, 1, 1, 'SYSTEM')
, (3, 2, '교환요청',              20, 1, 1, 'SYSTEM')
, (3, 2, '교환요청취소',           30, 1, 1, 'SYSTEM')
, (3, 2, '교환으로 인한 생성',      40, 1, 1, 'SYSTEM')
, (3, 2, '교환으로 인한 취소',      50, 1, 1, 'SYSTEM')
, (3, 2, '교환 반품회수 완료',      60, 1, 1, 'SYSTEM')
, (3, 3, '맞교환완료',             10, 1, 1, 'SYSTEM')
, (3, 3, '맞교환요청',             20, 1, 1, 'SYSTEM')
, (3, 3, '맞교환요청취소',          30, 1, 1, 'SYSTEM')
, (3, 4, '발송전취소',             10, 1, 1, 'SYSTEM')
, (3, 9, '품절취소',               20, 1, 1, 'SYSTEM')
, (3, 5, '반품완료',               10, 1, 1, 'SYSTEM')
, (3, 5, '반품요청',               20, 1, 1, 'SYSTEM')
, (3, 5, '반품요청취소',            30, 1, 1, 'SYSTEM')
, (3, 5, '반품으로 인한 취소',       40, 1, 1, 'SYSTEM')
, (3, 5, '반품입고',               50, 1, 1, 'SYSTEM')
, (3, 5, '반품회수요청',            60, 1, 1, 'SYSTEM')
, (3, 5, '반품회수취소',            70, 1, 1, 'SYSTEM')
, (3, 5, '택배 반품접수',           80, 1, 1, 'SYSTEM')
, (3, 6, '배송중분실',             10, 1, 1, 'SYSTEM')
, (3, 6, '미배송',                20, 1, 1, 'SYSTEM')
, (3, 6, '배송중 분실로 인한 생성',  30, 1, 1, 'SYSTEM')
, (3, 8, '배송지 수정',            10, 1, 1, 'SYSTEM')
, (3, 8, '상품변경',               20, 1, 1, 'SYSTEM');


-- ============================================
-- cs_claim_code 초기 데이터
-- action_type: 1 SHIPPED_CLAIM, 2 UNSHIPPED_CLAIM, 3 COMMON_CLAIM, 4 ETC
-- claim_type : common_code CLAIM_TYPE (1 RETURN ~ 9 PRE_SHIP_CANCEL)
-- status     : 이 액션이 만드는 클레임 상태 (1 REQUESTED, 2 COMPLETED, 3 CANCELED)
-- ============================================
INSERT INTO cs_claim_code (id, action_type, claim_type, code, name, status, sort_order)
OVERRIDING SYSTEM VALUE VALUES
-- 출고 후 클레임: 접수 → 완료 / 취소
  (1,  1, 1,    'RETURN_REQUESTED',            '발송후반품 접수',   1,    10)
, (2,  1, 1,    'RETURN_COMPLETED',            '발송후반품 완료',   2,    20)
, (3,  1, 1,    'RETURN_CANCELED',             '발송후반품 취소',   3,    30)
, (4,  1, 2,    'RECALL_REQUESTED',            '발송후회수 접수',   1,    40)
, (5,  1, 2,    'RECALL_COMPLETED',            '발송후회수 완료',   2,    50)
, (6,  1, 2,    'RECALL_CANCELED',             '발송후회수 취소',   3,    60)
, (7,  1, 3,    'EXCHANGE_REQUESTED',          '교환 접수',        1,    70)
, (8,  1, 3,    'EXCHANGE_COMPLETED',          '교환 완료',        2,    80)
, (9,  1, 3,    'EXCHANGE_CANCELED',           '교환 취소',        3,    90)
, (10, 1, 4,    'COUNTER_EXCHANGE_REQUESTED',  '맞교환 접수',      1,    100)
, (11, 1, 4,    'COUNTER_EXCHANGE_COMPLETED',  '맞교환 완료',      2,    110)
, (12, 1, 4,    'COUNTER_EXCHANGE_CANCELED',   '맞교환 취소',      3,    120)
-- 출고 후 클레임: 즉시 완료
, (13, 1, 5,    'LOST_IN_TRANSIT',             '배송중분실',       2,    130)
, (14, 1, 6,    'NON_DELIVERY',                '미배송',          2,    140)
-- 출고 전 클레임: 즉시 완료
, (15, 2, 7,    'PRODUCT_CHANGE',              '상품변경',         2,    10)
, (16, 2, 8,    'SOLDOUT_CANCEL',              '품절취소',         2,    20)
, (17, 2, 9,    'PRE_SHIP_CANCEL',             '발송전취소',       2,    30)
-- 공통 액션: 클레임을 만들지 않는다 (claim_type, status null)
, (18, 3, NULL, 'RESTORE_CANCEL',              '취소주문 복구',     NULL, 10)
, (19, 3, NULL, 'CS_MEMO_LINK',                'CS메모연결',       NULL, 20)
, (20, 3, NULL, 'ORDER_DELETE',                '주문삭제',         NULL, 30)
, (21, 3, NULL, 'BARCODE_PRINT',               '바코드인쇄',       NULL, 40)
-- 기타
, (22, 4, NULL, 'SPLIT_QUANTITY',              '주문수량 분리',     NULL, 10);

SELECT setval('cs_claim_code_id_seq', 22);
