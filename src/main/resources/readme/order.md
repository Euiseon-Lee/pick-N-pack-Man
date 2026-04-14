# 주문 도메인 정의서 - v1.260411

---

## 1. 테이블 구성

```
order_master              주문 마스터
order_item               주문 상품 (처리의 기본 단위)
order_item_history        주문 상품 변경 이력
```

---

## 2. 각 테이블의 책임

| 테이블 | 질문 | 책임 | 변경 빈도 |
|---|---|---|---|
| `order_master` | 이 주문이 뭐지? | 주문 접수 시점의 정보 (주문자, 수령자, 결제) | 낮음 |
| `order_item` | 이 주문에 어떤 상품이 있지? | 주문 상품 단위의 정보 (매칭, 수량, 가격) | 중간 |
| `order_item_history` | 이 상품에 무슨 일이 있었지? | 주문 상품의 모든 변경 이력 추적 | 높음 |

---

## 3. 관계

```
order_master (1) ──→ (N) order_item
order_item  (1) ──→ (N) order_item_history

order_item.matched_product_id      → product_master.id
order_item.matched_product_item_id → product_item.id
```

### 타 도메인과의 연결

```
* order_master ↔ shipment_master 사이에 직접 FK 없음
* 연결 경로: shipment_item → order_item → order_master

* CS 연결: cs_claim.order_product_id → order_item.id
* 원본 추적: cs_claim.order_product_id → order_item.origin_order_item_id
```

---

## 4. 데이터 예시 및 흐름

### 데이터 예시

```
order_master #100
  pnp_order_no = 'ORD-240315-000001'
  marketplace_order_id = '2024031512345'
  marketplace_type = 'naver'
  marketplace_seller_id = 'SELLER_001'
  marketplace_seller_name = '나이키공식스토어'
  orderer_name = '홍길동'
  receiver_name = '김철수'
  total_amount = 258,000
  origin_order_id = null (일반 주문)
  │
  ├── order_item #1
  │     marketplace_product_name = '나이키 에어맥스 270 블랙'
  │     matched_product_id = 10 (product_master)
  │     matched_product_item_id = 100 (product_item: 블랙/270mm)
  │     matching_status = 3 (STOCK_MATCHED)
  │     quantity = 2, unit_price = 129,000, total_amount = 258,000
  │     origin_order_item_id = null (원본)
  │     │
  │     └── order_item_history
  │           #1: history_type=CREATED
  │           #2: history_type=PRODUCT_MATCHED, snapshot={"matched_product_id": 10}
  │           #3: history_type=STOCK_MATCHED, snapshot={"matched_product_item_id": 100}
  │
  └── order_item #2
        marketplace_product_name = '나이키 양말 세트'
        matched_product_id = null
        matching_status = 1 (NOT_MATCHED)
        quantity = 1, unit_price = 15,000, total_amount = 15,000
```

### 흐름 1: 주문 접수

```
마켓에서 주문 수집
  → order_master 생성 (pnp_order_no 자동생성, origin_order_id = null)
  → order_item 생성 (origin_order_item_id = null)
     ↓ 자동 매칭 시도
     marketplace_product_mapping 조회
     (marketplace_type + marketplace_seller_id + marketplace_product_id + marketplace_option_id)
     ↓
     매핑 존재:
       matched_product_id, matched_product_item_id 채움
       matching_status = 3 (STOCK_MATCHED) 또는 2 (PRODUCT_MATCHED, SKU 미매핑 시)
     매핑 없음:
       matched_product_id = null, matched_product_item_id = null
       matching_status = 1 (NOT_MATCHED)
  → order_item_history 기록 (history_type = CREATED)
```

### 흐름 2: 수동 매칭 (자동 매칭 실패 시)

```
담당자가 미매칭 주문을 직접 매칭
  → order_item.matched_product_id 설정, matching_status = 2
  → order_item_history 기록 (history_type = PRODUCT_MATCHED)

  → order_item.matched_product_item_id 설정, matching_status = 3
  → order_item_history 기록 (history_type = STOCK_MATCHED)

  → (선택) marketplace_product_mapping에 매핑 저장
     → 다음부터는 자동 매칭됨 (학습 효과)

출고 가능 여부 판단 (런타임):
  matching_status = 3 AND SUM(inventory.available_stock) >= quantity → AVAILABLE
  matching_status = 3 AND SUM(inventory.available_stock) < quantity  → NOT_AVAILABLE
  matching_status < 3                                                → NOT_MATCHED
```

### 흐름 3: 합포 → 출고

```
합포 처리
  → shipment_master 생성 (배송 도메인)
  → shipment_item 생성 (order_item와 1:1)
  → order_master, order_item는 변경 없음

출고 요청/완료
  → shipment_master.status 변경 (배송 도메인)
  → order 테이블은 변경 없음
```

### 흐름 4: 수량 분리 (운영)

```
order_item #1 (수량 5) → 재고 부족으로 3+2 분리
  → order_item #1 수량 5 → 3
  → order_item #4 신규 생성 (수량 2, origin_order_item_id = 1, 같은 order_id)
  → order_item_history 기록: #1 (QUANTITY_SPLIT), #4 (CREATED)
```

### 흐름 5: CS 부분 교환

```
order_item #1 (수량 5) → 2개 교환
  → 자동 수량 분리: #1(수량3) + #4(수량2, origin_order_item_id = 1)
  → cs_claim 생성 (order_product_id = 4)
  → 교환 완료 시: order_master #200 생성 (origin_order_id = 100)
  → order_item #5 생성 (origin_order_item_id = 4)
  → order_item_history 기록: #4 (CLAIM_REQUESTED → CLAIM_COMPLETED), #5 (CREATED)
```

### 흐름 6: 화면 표시

```
합포 처리됨 → shipment_master 기준 행 표시 (UNION Part A)
합포 미처리 → order_master 기준 행 표시 (UNION Part B)
```

---

## 5. 테이블 정의서

### 5-1. order_master (주문 마스터)

| 그룹 | # | 컬럼명 | 타입            | NULL | 기본값 | 설명 |
|---|---|---|---------------|---|---|---|
| **PK** | 1 | `id` | bigint        | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **내부 식별** | 2 | `pnp_order_no` | varchar(100)  | NOT NULL | - | 내부 관리번호 (ORD-YYMMDD-000001), UNIQUE |
| **파생 원본** | 3 | `origin_order_id` | bigint        | NULL | - | 원주문 ID (CS 교환/분실 등으로 생성된 경우) |
| **마켓플레이스** | 4 | `marketplace_order_id` | varchar(100)  | NULL | - | 마켓 원본 주문번호 |
| | 5 | `marketplace_type` | varchar(50)   | NULL | - | 마켓 구분 (naver, cafe24 등) |
| | 6 | `marketplace_seller_id` | varchar(255)  | NULL | - | 마켓 판매처 ID |
| | 7 | `marketplace_seller_name` | varchar(255)  | NULL | - | 마켓 판매처명 |
| **주문자** | 8 | `orderer_name` | varchar(100)  | NULL | - | 주문자명 |
| | 9 | `orderer_mobile` | varchar(20)   | NULL | - | 주문자 휴대폰 |
| | 10 | `orderer_email` | varchar(200)  | NULL | - | 주문자 이메일 |
| | 11 | `ordered_at` | datetime      | NULL | - | 주문일시 |
| **수령자** | 12 | `receiver_name` | varchar(100)  | NULL | - | 수령자명 |
| | 13 | `receiver_zipcode` | varchar(50)   | NULL | - | 우편번호 |
| | 14 | `receiver_address` | varchar(500)  | NULL | - | 주소 |
| | 15 | `receiver_address_detail` | varchar(500)  | NULL | - | 상세주소 |
| | 16 | `receiver_mobile` | varchar(20)   | NULL | - | 수령자 휴대폰 (1순위) |
| | 17 | `receiver_tel` | varchar(20)   | NULL | - | 수령자 유선전화 (2순위) |
| | 18 | `delivery_request` | text          | NULL | - | 배송 요청사항 |
| **결제** | 19 | `total_amount` | decimal(15,2) | NULL | - | 총 결제금액 |
| | 20 | `delivery_fee` | decimal(15,2) | NULL | - | 배송비 |
| | 21 | `discount_amount` | decimal(15,2) | NULL | - | 할인금액 |
| | 22 | `payment_method` | varchar(50)   | NULL | - | 결제수단 |
| | 23 | `payment_status` | varchar(50)   | NULL | - | 결제상태 |
| | 24 | `paid_at` | datetime      | NULL | - | 결제일시 |
| **상태/관리** | 25 | `is_shipment_on_hold` | smallint      | NULL | NULL | 전체 출고보류 (null=정상, 1=보류) |
| | 26 | `shipment_hold_user_id` | varchar(100)  | NULL | - | 보류자 |
| | 27 | `shipment_hold_at` | datetime      | NULL | - | 보류 일시 |
| | 28 | `is_canceled` | smallint      | NULL | NULL | 전체 취소 (null=정상, 1=취소) |
| | 29 | `canceled_user_id` | varchar(100)  | NULL | - | 취소자 |
| | 30 | `canceled_at` | datetime      | NULL | - | 취소 일시 |
| | 31 | `is_deleted` | smallint      | NULL | NULL | 전체 삭제 (null=정상, 1=삭제) |
| | 32 | `deleted_user_id` | varchar(100)  | NULL | - | 삭제자 |
| | 33 | `deleted_at` | datetime      | NULL | - | 삭제 일시 |
| **감사** | 34 | `created_user_id` | varchar(100)  | NOT NULL | 'SYSTEM' | 생성자 |
| | 35 | `created_at` | timestamp     | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 36 | `updated_user_id` | varchar(100)  | NULL | - | 수정자 |
| | 37 | `updated_at` | timestamp     | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |
| **원본** | 38 | `raw_data` | jsonb         | NULL | - | 크롤링 원본 데이터 |

---

### 5-2. order_item (주문 상품)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **관계** | 2 | `order_id` | bigint | NOT NULL | - | order_master.id (FK) |
| **파생 원본** | 3 | `origin_order_item_id` | bigint | NULL | - | 원주문상품 ID (수량 분리/CS로 생성된 경우) |
| **마켓플레이스 상품** | 4 | `marketplace_product_id` | varchar(255) | NULL | - | 마켓 상품 식별코드 |
| | 5 | `marketplace_product_name` | varchar(255) | NULL | - | 마켓 상품명 |
| | 6 | `marketplace_option_id` | varchar(255) | NULL | - | 마켓 옵션 식별코드 |
| | 7 | `marketplace_option_name` | text | NULL | - | 마켓 옵션명 |
| **매칭** | 8 | `matched_product_id` | bigint | NULL | - | 매칭된 상품 ID (product_master.id) |
| | 9 | `matched_product_item_id` | bigint | NULL | - | 매칭된 SKU ID (product_item.id) |
| | 10 | `matching_status` | int | NOT NULL | 1 | 매칭 상태 (common_code 참조) |
| **수량/가격** | 11 | `quantity` | int | NULL | - | 주문 수량 |
| | 12 | `unit_price` | decimal(15,2) | NULL | - | 단가 |
| | 13 | `total_amount` | decimal(15,2) | NULL | - | 총 금액 (단가 × 수량) |
| **상태/관리** | 14 | `is_shipment_on_hold` | smallint | NULL | NULL | 개별 출고보류 (null=정상, 1=보류) |
| | 15 | `shipment_hold_user_id` | varchar(100) | NULL | - | 보류자 |
| | 16 | `shipment_hold_at` | datetime | NULL | - | 보류 일시 |
| | 17 | `is_canceled` | smallint | NULL | NULL | 개별 취소 (null=정상, 1=취소) |
| | 18 | `canceled_user_id` | varchar(100) | NULL | - | 취소자 |
| | 19 | `canceled_at` | datetime | NULL | - | 취소 일시 |
| | 20 | `is_deleted` | smallint | NULL | NULL | 개별 삭제 (null=정상, 1=삭제) |
| | 21 | `deleted_user_id` | varchar(100) | NULL | - | 삭제자 |
| | 22 | `deleted_at` | datetime | NULL | - | 삭제 일시 |
| **감사** | 23 | `created_user_id` | varchar(100) | NOT NULL | 'SYSTEM' | 생성자 |
| | 24 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 25 | `updated_user_id` | varchar(100) | NULL | - | 수정자 |
| | 26 | `updated_at` | timestamp | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |

---

### 5-3. order_item_history (주문 상품 변경 이력)

| 그룹 | # | 컬럼명 | 타입           | NULL | 기본값 | 설명 |
|---|---|---|--------------|---|---|---|
| **PK** | 1 | `id` | bigint       | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **관계** | 2 | `order_item_id` | bigint       | NOT NULL | - | order_item.id (FK) |
| **이력** | 3 | `history_type` | int          | NOT NULL | - | 변경 유형 (common_code 참조) |
| | 4 | `snapshot` | jsonb        | NULL | - | 변경 시점 주요 값 스냅샷 |
| | 5 | `description` | text         | NULL | - | 변경 내용 텍스트 |
| **감사** | 6 | `created_user_id` | varchar(100) | NOT NULL | 'SYSTEM' | 작업자 |
| | 7 | `created_at` | timestamp    | NOT NULL | CURRENT_TIMESTAMP | 기록 일시 |

---

### 5-4. common_code (공통 코드)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **코드** | 2 | `group_code` | varchar(50) | NOT NULL | - | 그룹 식별 (MATCHING_STATUS, ORDER_ITEM_HISTORY_TYPE 등) |
| | 3 | `code` | int | NOT NULL | - | 코드 값 (1, 2, 3...) |
| | 4 | `name` | varchar(100) | NOT NULL | - | 코드명 |
| | 5 | `description` | varchar(255) | NULL | - | 설명 |
| | 6 | `sort_order` | int | NOT NULL | 0 | 정렬 순서 |
| | 7 | `is_active` | smallint | NOT NULL | 1 | 사용 여부 |
| **감사** | 8 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 9 | `updated_at` | timestamp | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |

---

## 6. DDL

db/init/02_order.sql 참조


---
