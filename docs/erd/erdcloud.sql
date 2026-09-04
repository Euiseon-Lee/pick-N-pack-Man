-- ============================================
-- ERDCloud 가져오기용 DDL (자동 생성, 직접 수정하지 말 것)
-- 원천: src/main/resources/db/init/*.sql  |  생성: node docs/erd/generate-erdcloud-ddl.js
-- ============================================

CREATE TABLE common_code (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    group_code VARCHAR(50) NOT NULL COMMENT '그룹 식별',
    code INT NOT NULL COMMENT '코드 값',
    name VARCHAR(100) NOT NULL COMMENT '코드명',
    description VARCHAR(255) COMMENT '설명',
    sort_order INT NOT NULL DEFAULT 0 COMMENT '정렬 순서',
    is_active SMALLINT NOT NULL DEFAULT 1 COMMENT '사용 여부',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    UNIQUE KEY UQ_common_code_group_code (group_code, code)
) COMMENT '공통 코드';

CREATE TABLE order_master (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    pnp_order_no VARCHAR(100) NOT NULL COMMENT '내부 관리번호',
    origin_order_id BIGINT COMMENT '원주문 ID',
    marketplace_order_id VARCHAR(100) COMMENT '마켓 원본 주문번호',
    marketplace_type VARCHAR(50) COMMENT '마켓 구분',
    marketplace_seller_id VARCHAR(255) COMMENT '마켓 판매처 ID',
    marketplace_seller_name VARCHAR(255) COMMENT '마켓 판매처명',
    orderer_name VARCHAR(100) COMMENT '주문자명',
    orderer_mobile VARCHAR(20) COMMENT '주문자 휴대폰',
    orderer_email VARCHAR(200) COMMENT '주문자 이메일',
    ordered_at DATETIME COMMENT '주문일시',
    receiver_name VARCHAR(100) COMMENT '수령자명',
    receiver_zipcode VARCHAR(50) COMMENT '우편번호',
    receiver_address VARCHAR(500) COMMENT '주소',
    receiver_address_detail VARCHAR(500) COMMENT '상세주소',
    receiver_mobile VARCHAR(20) COMMENT '수령자 휴대폰',
    receiver_tel VARCHAR(20) COMMENT '수령자 유선전화',
    delivery_request TEXT COMMENT '배송 요청사항',
    total_amount DECIMAL(15,2) COMMENT '총 결제금액',
    delivery_fee DECIMAL(15,2) COMMENT '배송비',
    discount_amount DECIMAL(15,2) COMMENT '할인금액',
    payment_method VARCHAR(50) COMMENT '결제수단',
    payment_status VARCHAR(50) COMMENT '결제상태',
    paid_at DATETIME COMMENT '결제일시',
    is_shipment_on_hold SMALLINT COMMENT '전체 출고보류',
    shipment_hold_user_id VARCHAR(100) COMMENT '보류자',
    shipment_hold_at DATETIME COMMENT '보류 일시',
    is_canceled SMALLINT COMMENT '전체 취소',
    canceled_user_id VARCHAR(100) COMMENT '취소자',
    canceled_at DATETIME COMMENT '취소 일시',
    is_deleted SMALLINT COMMENT '전체 삭제',
    deleted_user_id VARCHAR(100) COMMENT '삭제자',
    deleted_at DATETIME COMMENT '삭제 일시',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    raw_data JSON COMMENT '크롤링 원본 데이터',
    PRIMARY KEY (id),
    UNIQUE KEY UQ_order_master_pnp_order_no (pnp_order_no),
    CONSTRAINT FK_order_master_origin_order FOREIGN KEY (origin_order_id) REFERENCES order_master (id)
) COMMENT '주문 마스터';

CREATE TABLE product_master (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    name VARCHAR(255) NOT NULL COMMENT '상품명',
    code VARCHAR(100) COMMENT '상품코드',
    status INT NOT NULL DEFAULT 1 COMMENT '상태',
    description TEXT COMMENT '상품 설명',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    UNIQUE KEY UQ_product_master_code (code)
) COMMENT '상품 마스터';

CREATE TABLE product_item (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    product_id BIGINT NOT NULL COMMENT 'product_master.id',
    barcode VARCHAR(100) COMMENT '바코드',
    sku_code VARCHAR(100) COMMENT 'SKU 코드',
    unit_price DECIMAL(15,2) COMMENT '판매 단가',
    cost_price DECIMAL(15,2) COMMENT '원가',
    status INT NOT NULL DEFAULT 1 COMMENT '상태',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    UNIQUE KEY UQ_product_item_barcode (barcode),
    CONSTRAINT FK_product_item_product_id FOREIGN KEY (product_id) REFERENCES product_master (id)
) COMMENT 'SKU (상품 옵션 조합). 표시명은 저장하지 않고 product_item_option 의 값을 옵션 종류 display_order 순으로 이어 붙여 만든다';

CREATE TABLE order_item (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    order_id BIGINT NOT NULL COMMENT 'order_master.id',
    origin_order_item_id BIGINT COMMENT '원주문상품 ID',
    marketplace_product_id VARCHAR(255) COMMENT '마켓 상품 식별코드',
    marketplace_product_name VARCHAR(255) COMMENT '마켓 상품명',
    marketplace_option_id VARCHAR(255) COMMENT '마켓 옵션 식별코드',
    marketplace_option_name TEXT COMMENT '마켓 옵션명',
    matched_product_id BIGINT COMMENT '매칭된 상품 ID',
    matched_product_item_id BIGINT COMMENT '매칭된 SKU ID',
    matching_status INT NOT NULL DEFAULT 1 COMMENT '매칭 상태',
    quantity INT COMMENT '주문 수량',
    unit_price DECIMAL(15,2) COMMENT '단가',
    total_amount DECIMAL(15,2) COMMENT '총 금액',
    is_shipment_on_hold SMALLINT COMMENT '개별 출고보류',
    shipment_hold_user_id VARCHAR(100) COMMENT '보류자',
    shipment_hold_at DATETIME COMMENT '보류 일시',
    is_canceled SMALLINT COMMENT '개별 취소',
    canceled_user_id VARCHAR(100) COMMENT '취소자',
    canceled_at DATETIME COMMENT '취소 일시',
    is_deleted SMALLINT COMMENT '개별 삭제',
    deleted_user_id VARCHAR(100) COMMENT '삭제자',
    deleted_at DATETIME COMMENT '삭제 일시',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    CONSTRAINT FK_order_item_order_id FOREIGN KEY (order_id) REFERENCES order_master (id),
    CONSTRAINT FK_order_item_origin_order_item FOREIGN KEY (origin_order_item_id) REFERENCES order_item (id),
    CONSTRAINT FK_order_item_matched_product FOREIGN KEY (matched_product_id) REFERENCES product_master (id),
    CONSTRAINT FK_order_item_matched_product_item FOREIGN KEY (matched_product_item_id) REFERENCES product_item (id)
) COMMENT '주문 상품';

CREATE TABLE order_item_history (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    order_item_id BIGINT NOT NULL COMMENT 'order_item.id',
    history_type INT NOT NULL COMMENT '변경 유형',
    snapshot JSON COMMENT '변경 시점 주요 값 스냅샷',
    description TEXT COMMENT '변경 내용 텍스트',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '작업자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    PRIMARY KEY (id),
    CONSTRAINT FK_order_item_history_order_item_id FOREIGN KEY (order_item_id) REFERENCES order_item (id)
) COMMENT '주문 상품 변경 이력';

CREATE TABLE product_option_type (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    product_id BIGINT NOT NULL COMMENT 'product_master.id',
    name VARCHAR(100) NOT NULL COMMENT '종류 이름',
    display_order INT NOT NULL DEFAULT 0 COMMENT '상품 안에서 종류를 나열하는 순서. SKU 표시명도 이 순서를 따른다',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    UNIQUE KEY UQ_product_option_type (product_id, name),
    CONSTRAINT FK_product_option_type_product_id FOREIGN KEY (product_id) REFERENCES product_master (id)
) COMMENT '상품 옵션 종류 (컬러, 사이즈 ...)';

CREATE TABLE product_option (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    option_type_id BIGINT NOT NULL COMMENT 'product_option_type.id',
    option_value VARCHAR(255) NOT NULL COMMENT '옵션 값',
    display_order INT NOT NULL DEFAULT 0 COMMENT '종류 안에서 값을 나열하는 순서',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    UNIQUE KEY UQ_product_option (option_type_id, option_value),
    CONSTRAINT FK_product_option_option_type_id FOREIGN KEY (option_type_id) REFERENCES product_option_type (id)
) COMMENT '상품 옵션 값 (블랙, 270mm ...). 상품은 option_type_id → product_option_type.product_id 로 도출';

CREATE TABLE product_item_option (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    product_item_id BIGINT NOT NULL COMMENT 'product_item.id',
    option_id BIGINT NOT NULL COMMENT 'product_option.id',
    PRIMARY KEY (id),
    UNIQUE KEY UQ_product_item_option (product_item_id, option_id),
    CONSTRAINT FK_product_item_option_product_item_id FOREIGN KEY (product_item_id) REFERENCES product_item (id),
    CONSTRAINT FK_product_item_option_option_id FOREIGN KEY (option_id) REFERENCES product_option (id)
) COMMENT 'SKU-옵션 매핑';

CREATE TABLE inventory (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    product_item_id BIGINT NOT NULL COMMENT 'product_item.id',
    total_stock INT NOT NULL DEFAULT 0 COMMENT '총 재고',
    available_stock INT NOT NULL DEFAULT 0 COMMENT '가용 재고',
    reserved_stock INT NOT NULL DEFAULT 0 COMMENT '예약 재고',
    defective_stock INT NOT NULL DEFAULT 0 COMMENT '불량 재고',
    warehouse_id VARCHAR(100) NOT NULL COMMENT '창고 ID',
    warehouse_name VARCHAR(255) COMMENT '창고명',
    last_synced_at DATETIME COMMENT 'WMS 마지막 동기화 일시',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    UNIQUE KEY UQ_inventory_item_warehouse (product_item_id, warehouse_id),
    CONSTRAINT FK_inventory_product_item_id FOREIGN KEY (product_item_id) REFERENCES product_item (id)
) COMMENT '재고';

CREATE TABLE marketplace_product_mapping (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    marketplace_type VARCHAR(50) NOT NULL COMMENT '마켓 구분',
    marketplace_seller_id VARCHAR(255) NOT NULL COMMENT '마켓 판매처 ID',
    marketplace_product_id VARCHAR(255) NOT NULL COMMENT '마켓 상품 식별코드',
    marketplace_option_id VARCHAR(255) COMMENT '마켓 옵션 식별코드',
    product_id BIGINT NOT NULL COMMENT 'product_master.id',
    product_item_id BIGINT NOT NULL COMMENT 'product_item.id',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    UNIQUE KEY UQ_marketplace_product_mapping (marketplace_type, marketplace_seller_id, marketplace_product_id, marketplace_option_id),
    CONSTRAINT FK_marketplace_product_mapping_product_id FOREIGN KEY (product_id) REFERENCES product_master (id),
    CONSTRAINT FK_marketplace_product_mapping_product_item_id FOREIGN KEY (product_item_id) REFERENCES product_item (id)
) COMMENT '마켓 상품 ↔ 우리 상품 매핑';

CREATE TABLE shipment_master (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    receiver_name VARCHAR(100) COMMENT '수령자명',
    receiver_zipcode VARCHAR(50) COMMENT '우편번호',
    receiver_address VARCHAR(500) COMMENT '주소',
    receiver_address_detail VARCHAR(500) COMMENT '상세주소',
    receiver_mobile VARCHAR(20) COMMENT '수령자 휴대폰',
    receiver_tel VARCHAR(20) COMMENT '수령자 유선전화',
    delivery_request TEXT COMMENT '배송 요청사항',
    deliver_code VARCHAR(20) COMMENT '택배사 코드',
    invoice_number VARCHAR(50) COMMENT '운송장번호',
    status INT NOT NULL DEFAULT 1 COMMENT '출고상태',
    shipment_type INT COMMENT '출고유형',
    sent_at DATETIME COMMENT 'WMS 마지막 요청 일시',
    is_shipment_on_hold SMALLINT COMMENT '출고보류',
    shipment_hold_user_id VARCHAR(100) COMMENT '보류자',
    shipment_hold_at DATETIME COMMENT '보류 일시',
    is_deleted SMALLINT COMMENT '삭제 = 합포 해제',
    deleted_user_id VARCHAR(100) COMMENT '삭제자',
    deleted_at DATETIME COMMENT '삭제 일시',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id)
) COMMENT '출고 마스터';

CREATE TABLE shipment_item (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    shipment_id BIGINT NOT NULL COMMENT 'shipment_master.id',
    order_item_id BIGINT NOT NULL COMMENT 'order_item.id',
    status INT NOT NULL DEFAULT 1 COMMENT 'WMS 처리 결과',
    is_deleted SMALLINT COMMENT '삭제 = 송장에서 뺌',
    deleted_user_id VARCHAR(100) COMMENT '삭제자',
    deleted_at DATETIME COMMENT '삭제 일시',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    UNIQUE KEY UQ_shipment_item_live_order_item (order_item_id),
    CONSTRAINT FK_shipment_item_shipment_id FOREIGN KEY (shipment_id) REFERENCES shipment_master (id),
    CONSTRAINT FK_shipment_item_order_item FOREIGN KEY (order_item_id) REFERENCES order_item (id)
) COMMENT '출고 상품';

CREATE TABLE cs_category (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    category_type INT NOT NULL COMMENT '분류 타입',
    parent_id BIGINT COMMENT '부모 카테고리 ID',
    name VARCHAR(100) NOT NULL COMMENT '분류명',
    description VARCHAR(100) COMMENT '분류 설명',
    sort_order INT NOT NULL DEFAULT 0 COMMENT '정렬 순서',
    is_system SMALLINT NOT NULL DEFAULT 0 COMMENT '시스템 데이터 여부',
    is_active SMALLINT NOT NULL DEFAULT 1 COMMENT '사용 여부',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    CONSTRAINT FK_cs_category_parent FOREIGN KEY (parent_id) REFERENCES cs_category (id)
) COMMENT 'CS 분류 체계';

CREATE TABLE cs_claim_code (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    action_type INT NOT NULL COMMENT '액션 타입',
    claim_type INT COMMENT '이 액션이 속한 클레임 유형',
    code VARCHAR(50) NOT NULL COMMENT '프로그래밍 식별코드',
    name VARCHAR(100) NOT NULL COMMENT '액션명',
    description VARCHAR(100) COMMENT '설명',
    status INT COMMENT '이 액션이 만드는 클레임 상태',
    sort_order INT NOT NULL DEFAULT 0 COMMENT '정렬 순서',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME COMMENT '수정일',
    PRIMARY KEY (id),
    UNIQUE KEY UQ_cs_claim_code_code (code)
) COMMENT 'CS 화면 액션 목록. 클레임 유형 자체는 common_code CLAIM_TYPE이 원천';

CREATE TABLE cs_claim (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    order_product_id BIGINT NOT NULL COMMENT 'order_item.id',
    shipment_id BIGINT COMMENT 'shipment_master.id',
    claim_type INT NOT NULL COMMENT '클레임 유형',
    status INT NOT NULL DEFAULT 1 COMMENT '클레임 상태',
    claim_data JSON COMMENT '클레임 상세 + 교환 상품 정보',
    worker_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '실제 처리 담당자',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME COMMENT '수정일',
    PRIMARY KEY (id),
    CONSTRAINT FK_cs_claim_order_item FOREIGN KEY (order_product_id) REFERENCES order_item (id),
    CONSTRAINT FK_cs_claim_shipment FOREIGN KEY (shipment_id) REFERENCES shipment_master (id)
) COMMENT '클레임';

CREATE TABLE cs_history (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    order_product_id BIGINT NOT NULL COMMENT 'order_item.id',
    shipment_id BIGINT COMMENT 'shipment_master.id',
    history_type INT NOT NULL COMMENT '이력 유형',
    cs_category_id BIGINT COMMENT 'cs_category.id 또는 cs_claim_code.id',
    cs_category_name VARCHAR(100) COMMENT '기록 시점 분류/액션명',
    is_system SMALLINT NOT NULL DEFAULT 0 COMMENT '시스템 자동 여부',
    cs_target INT NOT NULL DEFAULT 1 COMMENT 'CS 처리 대상 범위',
    content TEXT NOT NULL COMMENT '처리 내용',
    is_important SMALLINT COMMENT '중요',
    is_complete SMALLINT COMMENT '처리 완료',
    is_pinned SMALLINT COMMENT '최상단 고정',
    linked_memo_id BIGINT COMMENT '연결된 CS 메모 ID',
    is_canceled SMALLINT COMMENT '취소',
    canceled_user_id VARCHAR(100) COMMENT '취소자',
    canceled_at DATETIME COMMENT '취소 일시',
    worker_id VARCHAR(100) NOT NULL COMMENT '실제 처리 담당자',
    completed_user_id VARCHAR(100) COMMENT '완료 처리자',
    completed_at DATETIME COMMENT '완료 처리 일시',
    created_user_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM' COMMENT '생성자',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    updated_user_id VARCHAR(100) COMMENT '수정자',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    CONSTRAINT FK_cs_history_order_item FOREIGN KEY (order_product_id) REFERENCES order_item (id),
    CONSTRAINT FK_cs_history_shipment FOREIGN KEY (shipment_id) REFERENCES shipment_master (id)
) COMMENT 'CS 상담 이력';
