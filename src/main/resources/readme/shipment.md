# 배송 도메인 정의서 - v1.260411

---

## 1. 테이블 구성

```
shipment_master         출고 마스터 (송장 1개 = 1건)
shipment_item          출고 상품
```

---

## 2. 각 테이블의 책임

| 테이블 | 질문 | 책임 | 변경 빈도 |
|---|---|---|---|
| `shipment_master` | 이 출고건이 뭐지? | 출고 단위 정보 (수령자, 송장, 택배사, 출고상태) | 중간 |
| `shipment_item` | 이 출고에 어떤 상품이 있지? | 출고 상품 단위 (주문상품 연결, 수량, 상태) | 중간 |

---

## 3. 관계

```
shipment_master (1) ──→ (N) shipment_item
shipment_item  (1) ──→ (1) order_item

* order_master ↔ shipment_master 사이에 직접 FK 없음
* 연결 경로: shipment_item → order_item → order_master
```

---

## 4. 데이터 예시 및 흐름

### 데이터 예시

```
shipment_master #500 (합포)
  receiver_name = '김철수'
  invoice_number = '1234567890'
  deliver_code = 'CJ'
  status = 1 (PENDING)
  │
  ├── shipment_item #5001
  │     order_id = 100, order_item_id = 1
  │     product_item_id = 100 (블랙/270mm)
  │     quantity = 2, status = 1 (PENDING)
  │
  ├── shipment_item #5002
  │     order_id = 100, order_item_id = 2
  │     product_item_id = 200 (양말세트)
  │     quantity = 1, status = 1 (PENDING)
  │
  └── shipment_item #5003
        order_id = 101, order_item_id = 3  ← 복합주문
        product_item_id = 100 (블랙/270mm)
        quantity = 1, status = 1 (PENDING)
```

### 흐름 1: 합포 처리

```
합포 조건에 맞는 주문상품들을 묶음
  → shipment_master 생성 (수령자 정보 복사, status = PENDING)
  → shipment_item 생성 (각 order_item에 대해 1:1)
  → order_master, order_item는 변경 없음
```

### 흐름 2: 출고 요청 → 완료

```
WMS로 출고 요청
  → shipment_master.status = SHIPMENT_REQUESTED
  → shipment_master.is_sent = 1, sent_at = now()

발송 완료
  → shipment_master.status = SHIPPED
  → shipment_item 전체 status = SHIPPED
```

### 흐름 3: 합포 해제

```
출고 미완료 상태에서만 가능 (status != SHIPPED)

시나리오 A: 배송상품을 새 배송으로 분리
  → 새 shipment_master 생성
  → shipment_item의 shipment_id를 새 shipment_master로 변경

시나리오 B: 배송 미할당으로 되돌림
  → shipment_item 삭제 (is_deleted = 1)
  → 해당 order_item는 다시 shipment 없는 상태

시나리오 C: 전체 합포 해제
  → shipment_item 전체 삭제 (is_deleted = 1)
  → shipment_master 삭제 (is_deleted = 1)
```

### 흐름 4: CS에서 배송 주소 변경

```
CS 담당자가 배송 주소 변경
  → shipment_master의 수령자 정보만 수정
  → order_master의 수령자 정보는 원본 유지
```

---

## 5. 테이블 정의서

### 5-1. shipment_master (출고 마스터)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **수령자** | 2 | `receiver_name` | varchar(100) | NULL | - | 수령자명 |
| | 3 | `receiver_zipcode` | varchar(50) | NULL | - | 우편번호 |
| | 4 | `receiver_address` | varchar(500) | NULL | - | 주소 |
| | 5 | `receiver_address_detail` | varchar(500) | NULL | - | 상세주소 |
| | 6 | `receiver_mobile` | varchar(20) | NULL | - | 수령자 휴대폰 (1순위) |
| | 7 | `receiver_tel` | varchar(20) | NULL | - | 수령자 유선전화 (2순위) |
| | 8 | `delivery_request` | text | NULL | - | 배송 요청사항 |
| **출고 정보** | 9 | `deliver_code` | varchar(20) | NULL | - | 택배사 코드 |
| | 10 | `invoice_number` | varchar(50) | NULL | - | 운송장번호 |
| | 11 | `status` | int | NOT NULL | 1 | 출고상태 (common_code 참조) |
| | 12 | `shipment_type` | int | NULL | - | 출고유형 (common_code 참조, WMS 참고용) |
| **WMS 이관** | 13 | `is_sent` | smallint | NULL | NULL | WMS 이관 여부 (null=미이관, 1=이관) |
| | 14 | `sent_at` | datetime | NULL | - | WMS 이관 일시 |
| **상태/관리** | 15 | `is_canceled` | smallint | NULL | NULL | 취소 (null=정상, 1=취소) |
| | 16 | `canceled_user_id` | varchar(100) | NULL | - | 취소자 |
| | 17 | `canceled_at` | datetime | NULL | - | 취소 일시 |
| | 18 | `is_deleted` | smallint | NULL | NULL | 삭제 (null=정상, 1=삭제) |
| | 19 | `deleted_user_id` | varchar(100) | NULL | - | 삭제자 |
| | 20 | `deleted_at` | datetime | NULL | - | 삭제 일시 |
| **감사** | 21 | `created_user_id` | varchar(100) | NOT NULL | 'SYSTEM' | 생성자 |
| | 22 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 23 | `updated_user_id` | varchar(100) | NULL | - | 수정자 |
| | 24 | `updated_at` | timestamp | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |

---

### 5-2. shipment_item (출고 상품)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **관계** | 2 | `shipment_id` | bigint | NOT NULL | - | shipment_master.id (FK) |
| | 3 | `order_id` | bigint | NOT NULL | - | order_master.id |
| | 4 | `order_item_id` | bigint | NOT NULL | - | order_item.id |
| | 5 | `product_item_id` | bigint | NULL | - | product_item.id (SKU) |
| **출고 정보** | 6 | `quantity` | int | NULL | - | 출고 수량 |
| | 7 | `status` | int | NULL | 1 | 출고상태 (common_code 참조) |
| **상태/관리** | 8 | `is_canceled` | smallint | NULL | NULL | 취소 (null=정상, 1=취소) |
| | 9 | `canceled_user_id` | varchar(100) | NULL | - | 취소자 |
| | 10 | `canceled_at` | datetime | NULL | - | 취소 일시 |
| | 11 | `is_deleted` | smallint | NULL | NULL | 삭제 (null=정상, 1=삭제) |
| | 12 | `deleted_user_id` | varchar(100) | NULL | - | 삭제자 |
| | 13 | `deleted_at` | datetime | NULL | - | 삭제 일시 |
| **감사** | 14 | `created_user_id` | varchar(100) | NOT NULL | 'SYSTEM' | 생성자 |
| | 15 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 16 | `updated_user_id` | varchar(100) | NULL | - | 수정자 |
| | 17 | `updated_at` | timestamp | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |

---

## 6. DDL

db/init/04_shipment.sql 참조

---
