# 상품/재고 도메인 정의서 - v1.260411

---

## 1. 테이블 구성

```
product_master          상품 마스터
product_item           SKU (옵션 조합 결과, 재고 관리의 최소 단위)
product_option         옵션 (유형 + 값)
product_item_option    SKU ↔ 옵션 매핑
inventory               창고별 재고
```

---

## 2. 각 테이블의 책임

| 테이블 | 질문 | 책임 | 변경 빈도 |
|---|---|---|---|
| `product_master` | 이 상품이 뭐지? | 상품 자체의 정의 (이름, 코드, 상태) | 낮음 |
| `product_item` | 이 SKU가 뭐지? | 옵션 조합 결과의 정의 (바코드, 단가, 원가) | 낮음 |
| `product_option` | 이 상품에 어떤 선택지가 있지? | 옵션 유형과 값의 정의 (컬러:블랙, 사이즈:270mm) | 낮음 |
| `product_item_option` | 이 SKU가 어떤 옵션 조합이지? | SKU와 옵션 값의 N:N 매핑 | 낮음 |
| `inventory` | 지금 몇 개 있지? | 창고별 실시간 재고 수량 | **높음** |

---

## 3. 관계

```
product_master (1) ──→ (N) product_item (SKU)
product_master (1) ──→ (N) product_option (옵션)
product_item  (N) ←──→ (N) product_option (매핑: product_item_option)
product_item  (1) ──→ (N) inventory (창고별 재고)
```

### 타 도메인과의 연결

```
order_item.matched_product_id      → product_master.id
order_item.matched_product_item_id → product_item.id

출고 가능 여부: order_item.matching_status + inventory 런타임 JOIN
```

---

## 4. 데이터 예시 및 흐름

### 데이터 예시

```
product_master #10 (나이키 에어맥스 270)
  │
  ├── product_option
  │     #1: option_type='컬러',   option_value='블랙'
  │     #2: option_type='컬러',   option_value='화이트'
  │     #3: option_type='사이즈',  option_value='260mm'
  │     #4: option_type='사이즈',  option_value='270mm'
  │
  ├── product_item (SKU)
  │     #100: barcode='880123', sku_code='AM270-BK27'
  │           option_name='블랙/270mm', unit_price=129,000
  │       └── product_item_option: option_id=#1(블랙), #4(270mm)
  │       └── inventory:
  │             #501: warehouse_id='WH-A', available_stock=8
  │             #502: warehouse_id='WH-B', available_stock=5
  │
  │     #101: barcode='880124', sku_code='AM270-WH26'
  │           option_name='화이트/260mm', unit_price=129,000
  │       └── product_item_option: option_id=#2(화이트), #3(260mm)
  │       └── inventory:
  │             #503: warehouse_id='WH-A', available_stock=3
```

### 흐름 1: 상품 등록

```
담당자가 상품 등록
  → product_master 생성 (name='나이키 에어맥스 270', code='AM270')
  → product_option 생성 (컬러: 블랙/화이트, 사이즈: 260/270)
  → product_item 생성 (각 옵션 조합별 SKU)
  → product_item_option 생성 (SKU ↔ 옵션 매핑)
  → inventory 생성 (각 SKU × 창고별 초기 재고)
```

### 흐름 2: 주문 매칭

```
order_item #1 (marketplace_product_name='나이키 에어맥스 블랙 270')
  │
  ▼ 상품 매칭
  matched_product_id = 10 (product_master)
  matching_status = 2 (PRODUCT_MATCHED)
  │
  ▼ SKU 매칭
  matched_product_item_id = 100 (product_item: 블랙/270mm)
  matching_status = 3 (STOCK_MATCHED)
  │
  ▼ 출고 가능 여부 판단 (런타임)
  SELECT SUM(inv.available_stock) FROM inventory inv
  WHERE inv.product_item_id = 100
  → 8 + 5 = 13개 가용 → AVAILABLE
```

### 흐름 3: 재고 변동

```
WMS에서 재고 동기화 이벤트 수신
  → inventory 업데이트 (product_item_id + warehouse_id 기준)
  → last_synced_at 갱신
  → product_master, product_item는 변경 없음
```

### 흐름 4: 출고 시 재고 차감

```
출고 요청 (shipment)
  → inventory.available_stock 차감
  → inventory.reserved_stock 증가
  
출고 완료
  → inventory.reserved_stock 차감
  → inventory.total_stock 차감
```

---

## 5. 테이블 정의서

### 5-1. product_master (상품 마스터)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **상품 정보** | 2 | `name` | varchar(255) | NOT NULL | - | 상품명 |
| | 3 | `code` | varchar(100) | NULL | - | 상품코드, UNIQUE |
| | 4 | `status` | int | NOT NULL | 1 | 상태 (common_code 참조) |
| | 5 | `description` | text | NULL | - | 상품 설명 |
| **감사** | 6 | `created_user_id` | varchar(100) | NOT NULL | 'SYSTEM' | 생성자 |
| | 7 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 8 | `updated_user_id` | varchar(100) | NULL | - | 수정자 |
| | 9 | `updated_at` | timestamp | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |

---

### 5-2. product_option (상품 옵션)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **관계** | 2 | `product_id` | bigint | NOT NULL | - | product_master.id (FK) |
| **옵션 정보** | 3 | `option_type` | varchar(100) | NOT NULL | - | 옵션 유형 (컬러, 사이즈 등) |
| | 4 | `option_value` | varchar(255) | NOT NULL | - | 옵션 값 (블랙, 270mm 등) |
| | 5 | `sort_order` | int | NOT NULL | 0 | 정렬 순서 |
| **감사** | 6 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 7 | `updated_at` | timestamp | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |

---

### 5-3. product_item (SKU)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **관계** | 2 | `product_id` | bigint | NOT NULL | - | product_master.id (FK) |
| **SKU 정보** | 3 | `barcode` | varchar(100) | NULL | - | 바코드, UNIQUE |
| | 4 | `sku_code` | varchar(100) | NULL | - | SKU 코드 |
| | 5 | `option_name` | varchar(255) | NULL | - | 옵션 조합 텍스트 (블랙/270mm) |
| | 6 | `unit_price` | decimal(15,2) | NULL | - | 판매 단가 |
| | 7 | `cost_price` | decimal(15,2) | NULL | - | 원가 |
| | 8 | `status` | int | NOT NULL | 1 | 상태 (common_code 참조) |
| **감사** | 9 | `created_user_id` | varchar(100) | NOT NULL | 'SYSTEM' | 생성자 |
| | 10 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 11 | `updated_user_id` | varchar(100) | NULL | - | 수정자 |
| | 12 | `updated_at` | timestamp | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |

---

### 5-4. product_item_option (SKU ↔ 옵션 매핑)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **관계** | 2 | `product_item_id` | bigint | NOT NULL | - | product_item.id (FK) |
| | 3 | `option_id` | bigint | NOT NULL | - | product_option.id (FK) |

---

### 5-5. inventory (재고)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **관계** | 2 | `product_item_id` | bigint | NOT NULL | - | product_item.id (FK) |
| **재고 수량** | 3 | `total_stock` | int | NOT NULL | 0 | 총 재고 |
| | 4 | `available_stock` | int | NOT NULL | 0 | 가용 재고 |
| | 5 | `reserved_stock` | int | NOT NULL | 0 | 예약 재고 (출고 예정) |
| | 6 | `defective_stock` | int | NOT NULL | 0 | 불량 재고 |
| **창고** | 7 | `warehouse_id` | varchar(100) | NOT NULL | - | 창고 ID |
| | 8 | `warehouse_name` | varchar(255) | NULL | - | 창고명 |
| **동기화** | 9 | `last_synced_at` | timestamp | NULL | - | WMS 마지막 동기화 일시 |
| **감사** | 10 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 11 | `updated_at` | timestamp | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |

---

## 6. DDL

db/init/03_product.sql 참조


---