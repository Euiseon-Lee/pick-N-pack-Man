-- ============================================
-- 도메인 간 FK 제약조건
-- 각 도메인 SQL(02~05)은 자기 도메인 안의 FK만 갖고,
-- 다른 도메인 테이블을 참조하는 FK는 모든 테이블이 생성된 뒤 여기서 일괄 추가한다.
-- (전제 문서 2. 설계 규칙 - "단일 DB이므로 DB 수준 FK 적용")
--
-- 제외 대상 (FK 불가):
--   cs_history.cs_category_id  → history_type에 따라 cs_category 또는 cs_claim_code를 가리키는 다형 참조
--   cs_history.linked_memo_id  → 대상 테이블 미정의
-- ============================================

-- 주문 도메인: 파생 원본 (자기 참조)
ALTER TABLE order_master
    ADD CONSTRAINT FK_order_master_origin_order
        FOREIGN KEY (origin_order_id) REFERENCES order_master (id);

ALTER TABLE order_item
    ADD CONSTRAINT FK_order_item_origin_order_item
        FOREIGN KEY (origin_order_item_id) REFERENCES order_item (id);

-- 주문 → 상품 (매칭 결과)
ALTER TABLE order_item
    ADD CONSTRAINT FK_order_item_matched_product
        FOREIGN KEY (matched_product_id) REFERENCES product_master (id);

ALTER TABLE order_item
    ADD CONSTRAINT FK_order_item_matched_product_item
        FOREIGN KEY (matched_product_item_id) REFERENCES product_item (id);

-- 출고 → 주문 / 상품
ALTER TABLE shipment_item
    ADD CONSTRAINT FK_shipment_item_order
        FOREIGN KEY (order_id) REFERENCES order_master (id);

ALTER TABLE shipment_item
    ADD CONSTRAINT FK_shipment_item_order_item
        FOREIGN KEY (order_item_id) REFERENCES order_item (id);

ALTER TABLE shipment_item
    ADD CONSTRAINT FK_shipment_item_product_item
        FOREIGN KEY (product_item_id) REFERENCES product_item (id);

-- CS 도메인: 분류/코드 자기 참조
ALTER TABLE cs_category
    ADD CONSTRAINT FK_cs_category_parent
        FOREIGN KEY (parent_id) REFERENCES cs_category (id);

ALTER TABLE cs_claim_code
    ADD CONSTRAINT FK_cs_claim_code_parent
        FOREIGN KEY (parent_id) REFERENCES cs_claim_code (id);

-- CS → 주문 / 출고
ALTER TABLE cs_claim
    ADD CONSTRAINT FK_cs_claim_order
        FOREIGN KEY (order_id) REFERENCES order_master (id);

ALTER TABLE cs_claim
    ADD CONSTRAINT FK_cs_claim_order_item
        FOREIGN KEY (order_product_id) REFERENCES order_item (id);

ALTER TABLE cs_claim
    ADD CONSTRAINT FK_cs_claim_shipment
        FOREIGN KEY (shipment_id) REFERENCES shipment_master (id);

ALTER TABLE cs_history
    ADD CONSTRAINT FK_cs_history_order
        FOREIGN KEY (order_id) REFERENCES order_master (id);

ALTER TABLE cs_history
    ADD CONSTRAINT FK_cs_history_order_item
        FOREIGN KEY (order_product_id) REFERENCES order_item (id);

ALTER TABLE cs_history
    ADD CONSTRAINT FK_cs_history_shipment
        FOREIGN KEY (shipment_id) REFERENCES shipment_master (id);
