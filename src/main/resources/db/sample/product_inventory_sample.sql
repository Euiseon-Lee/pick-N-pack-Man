-- ============================================
-- 상품/재고 샘플 데이터
-- 수동 실행용 (Docker 초기화 아님)
-- ============================================

-- 1. 상품 마스터
INSERT INTO product_master (name, code, status, description, created_user_id)
VALUES
    ('나이키 에어맥스 270', 'AM270', 1, '나이키 에어맥스 270 런닝화', 'SYSTEM'),
    ('아디다스 울트라부스트 22', 'UB22', 1, '아디다스 울트라부스트 22 런닝화', 'SYSTEM'),
    ('나이키 양말 세트', 'NK-SOCK', 1, '나이키 스포츠 양말 3팩', 'SYSTEM');


-- 2. 상품 옵션
-- 나이키 에어맥스 270 (product_master.id = 1)
INSERT INTO product_option (product_id, option_type, option_value, sort_order)
VALUES
    (1, '컬러', '블랙', 1),
    (1, '컬러', '화이트', 2),
    (1, '사이즈', '260mm', 1),
    (1, '사이즈', '270mm', 2),
    (1, '사이즈', '280mm', 3);

-- 아디다스 울트라부스트 22 (product_master.id = 2)
INSERT INTO product_option (product_id, option_type, option_value, sort_order)
VALUES
    (2, '컬러', '블랙', 1),
    (2, '컬러', '그레이', 2),
    (2, '사이즈', '265mm', 1),
    (2, '사이즈', '275mm', 2);

-- 나이키 양말 세트 (product_master.id = 3) - 옵션 없음 (단일 SKU)


-- 3. SKU (product_item)
-- 나이키 에어맥스 270 SKU
INSERT INTO product_item (product_id, barcode, sku_code, option_name, unit_price, cost_price, status, created_user_id)
VALUES
    (1, '8801234001', 'AM270-BK26', '블랙/260mm', 129000.00, 65000.00, 1, 'SYSTEM'),
    (1, '8801234002', 'AM270-BK27', '블랙/270mm', 129000.00, 65000.00, 1, 'SYSTEM'),
    (1, '8801234003', 'AM270-BK28', '블랙/280mm', 129000.00, 65000.00, 1, 'SYSTEM'),
    (1, '8801234004', 'AM270-WH26', '화이트/260mm', 129000.00, 65000.00, 1, 'SYSTEM'),
    (1, '8801234005', 'AM270-WH27', '화이트/270mm', 129000.00, 65000.00, 1, 'SYSTEM'),
    (1, '8801234006', 'AM270-WH28', '화이트/280mm', 129000.00, 65000.00, 1, 'SYSTEM');

-- 아디다스 울트라부스트 22 SKU
INSERT INTO product_item (product_id, barcode, sku_code, option_name, unit_price, cost_price, status, created_user_id)
VALUES
    (2, '8802345001', 'UB22-BK265', '블랙/265mm', 189000.00, 95000.00, 1, 'SYSTEM'),
    (2, '8802345002', 'UB22-BK275', '블랙/275mm', 189000.00, 95000.00, 1, 'SYSTEM'),
    (2, '8802345003', 'UB22-GR265', '그레이/265mm', 189000.00, 95000.00, 1, 'SYSTEM'),
    (2, '8802345004', 'UB22-GR275', '그레이/275mm', 189000.00, 95000.00, 1, 'SYSTEM');

-- 나이키 양말 세트 SKU (단일)
INSERT INTO product_item (product_id, barcode, sku_code, option_name, unit_price, cost_price, status, created_user_id)
VALUES
    (3, '8801234100', 'NK-SOCK-01', NULL, 15000.00, 5000.00, 1, 'SYSTEM');


-- 4. SKU ↔ 옵션 매핑 (product_item_option)
-- 나이키 에어맥스 270
-- product_option: 1=블랙, 2=화이트, 3=260mm, 4=270mm, 5=280mm
-- product_item: 1=블랙/260, 2=블랙/270, 3=블랙/280, 4=화이트/260, 5=화이트/270, 6=화이트/280
INSERT INTO product_item_option (product_item_id, option_id)
VALUES
    (1, 1), (1, 3),   -- 블랙/260mm
    (2, 1), (2, 4),   -- 블랙/270mm
    (3, 1), (3, 5),   -- 블랙/280mm
    (4, 2), (4, 3),   -- 화이트/260mm
    (5, 2), (5, 4),   -- 화이트/270mm
    (6, 2), (6, 5);   -- 화이트/280mm

-- 아디다스 울트라부스트 22
-- product_option: 6=블랙, 7=그레이, 8=265mm, 9=275mm
-- product_item: 7=블랙/265, 8=블랙/275, 9=그레이/265, 10=그레이/275
INSERT INTO product_item_option (product_item_id, option_id)
VALUES
    (7, 6), (7, 8),    -- 블랙/265mm
    (8, 6), (8, 9),    -- 블랙/275mm
    (9, 7), (9, 8),    -- 그레이/265mm
    (10, 7), (10, 9);  -- 그레이/275mm

-- 나이키 양말 세트 (옵션 없으므로 매핑 없음)


-- 5. 재고 (inventory)
-- 창고 A (WH-A): 메인 창고
-- 창고 B (WH-B): 보조 창고
INSERT INTO inventory (product_item_id, total_stock, available_stock, reserved_stock, defective_stock, warehouse_id, warehouse_name)
VALUES
    -- 나이키 에어맥스 270 - 창고 A
    (1, 15, 12, 2, 1, 'WH-A', '메인창고'),   -- 블랙/260mm
    (2, 20, 18, 2, 0, 'WH-A', '메인창고'),   -- 블랙/270mm
    (3, 8, 8, 0, 0, 'WH-A', '메인창고'),     -- 블랙/280mm
    (4, 5, 3, 1, 1, 'WH-A', '메인창고'),     -- 화이트/260mm
    (5, 10, 10, 0, 0, 'WH-A', '메인창고'),   -- 화이트/270mm
    (6, 3, 3, 0, 0, 'WH-A', '메인창고'),     -- 화이트/280mm

    -- 나이키 에어맥스 270 - 창고 B (일부 SKU만)
    (2, 5, 5, 0, 0, 'WH-B', '보조창고'),     -- 블랙/270mm
    (5, 3, 3, 0, 0, 'WH-B', '보조창고'),     -- 화이트/270mm

    -- 아디다스 울트라부스트 22 - 창고 A
    (7, 12, 10, 2, 0, 'WH-A', '메인창고'),   -- 블랙/265mm
    (8, 7, 7, 0, 0, 'WH-A', '메인창고'),     -- 블랙/275mm
    (9, 4, 4, 0, 0, 'WH-A', '메인창고'),     -- 그레이/265mm
    (10, 0, 0, 0, 0, 'WH-A', '메인창고'),    -- 그레이/275mm (품절)

    -- 나이키 양말 세트 - 창고 A
    (11, 100, 95, 5, 0, 'WH-A', '메인창고');
