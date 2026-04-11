# CS 도메인 정의서 - v1.260411

---

## 1. 테이블 구성

```
cs_category           CS 분류 체계 (사용자 관리)
cs_claim_code        클레임 액션 (시스템 정의)
cs_claim               클레임
cs_history            상담 이력
```

---

## 2. 각 테이블의 책임

| 테이블 | 질문 | 책임 | 변경 빈도 |
|---|---|---|---|
| `cs_category` | 이 상담을 어떻게 분류하지? | CS 상담 분류 체계 (사용자 CRUD 가능) | 낮음 |
| `cs_claim_code` | 이 클레임 액션이 뭐지? | 클레임 유형별 버튼명 + 이력 자동 매핑 (시스템 정의) | 거의 없음 |
| `cs_claim` | 이 상품에 어떤 클레임이 있지? | 클레임 접수/완료/취소 상태 관리 | 중간 |
| `cs_history` | 이 상품에 어떤 상담이 있었지? | CS 상담/클레임 이력 기록 | 높음 |

---

## 3. 관계

```
cs_category → 자기참조 (parent_id → cs_category.id)

cs_claim → order_master.id (order_id)
          → order_item.id (order_product_id)
          → shipment_master.id (shipment_id, nullable)

cs_history → order_master.id (order_id)
             → order_item.id (order_product_id)
             → shipment_master.id (shipment_id, nullable)
             → cs_category.id 또는 cs_claim_code.id (history_type으로 구분)
```

### 원본 추적 경로

```
cs_claim.order_product_id → order_item.origin_order_item_id → 원본 상품
```

---

## 4. 데이터 예시 및 흐름

### 데이터 예시

```
cs_category (사용자 관리)
  #1: PARENT_CATEGORY, '일반상담'
  #2: PARENT_CATEGORY, '교환'
  #11: CHILD_CATEGORY, parent_id=2, '교환완료' (is_system=1)
  #12: CHILD_CATEGORY, parent_id=2, '교환요청' (is_system=1)
  #13: CHILD_CATEGORY, parent_id=2, '사용자 추가 종류' (is_system=0)

cs_claim_code (시스템 정의)
  #1: SHIPPED_CLAIM, code='RETURN', '발송후반품'
  #7: SHIPPED_CLAIM, parent_id=1, code='RETURN_REQUESTED', status='REQUESTED', '발송후반품 접수'
  #8: SHIPPED_CLAIM, parent_id=1, code='RETURN_COMPLETED', status='COMPLETED', '발송후반품 완료'

cs_claim #10
  order_id = 100
  order_product_id = 4
  shipment_id = 500
  claim_type = 'EXCHANGE'
  status = 'REQUESTED'
  worker_id = 'admin1'

cs_history #20 (수동 상담)
  history_type = 1 (CONSULT)
  cs_category_id = 12 (cs_category: '교환요청')
  cs_category_name = '교환요청'
  content = '고객 사이즈 교환 요청'

cs_history #21 (클레임 이력)
  history_type = 2 (CLAIM)
  cs_category_id = 13 (cs_claim_code: '교환 접수')
  cs_category_name = '교환 접수'
  content = '교환 접수 - 사이즈 교환 요청'
```

### 흐름 1: 수동 상담 이력 등록

```
담당자가 CS 화면에서 상담 내용 입력
  → cs_history 생성
      history_type = CONSULT
      cs_category_id = 12 (cs_category)
      cs_category_name = '교환요청'
      content = '고객이 사이즈 교환을 요청함'
      worker_id = 'admin1'
```

### 흐름 2: CS 부분 교환

```
order_item #1 (수량 5) → 2개 교환 요청
  │
  ▼ 자동 수량 분리
  order_item #1 (수량 3)
  order_item #4 (수량 2, origin_order_item_id = 1)
  │
  ▼ 클레임 접수
  cs_claim 생성 (order_product_id = 4, type = EXCHANGE, status = REQUESTED)
  cs_history 생성 (history_type = CLAIM, cs_category_id = 13, cs_category_name = '교환 접수')
  order_item_history 기록 (action_type = CLAIM_REQUESTED)
  │
  ▼ 교환 완료
  cs_claim.status = COMPLETED
  order_master #200 생성 (origin_order_id = 100)
  order_item #5 생성 (origin_order_item_id = 4)
  cs_history 생성 (history_type = CLAIM, cs_category_id = 14, cs_category_name = '교환 완료')
  order_item_history 기록 (action_type = CLAIM_COMPLETED)
```

### 흐름 3: 출고 후 반품

```
shipment_master #500 (status = SHIPPED)
  └── shipment_item #5001 → order_item #1
  │
  ▼ 반품 접수
  cs_claim 생성 (order_product_id = 1, shipment_id = 500, type = RETURN, status = REQUESTED)
  cs_history 생성 (history_type = CLAIM, cs_category_id = 7, cs_category_name = '발송후반품 접수')
  │
  ▼ 반품 완료
  cs_claim.status = COMPLETED
  order_item #1 → is_canceled = 1
  cs_history 생성 (history_type = CLAIM, cs_category_id = 8, cs_category_name = '발송후반품 완료')
```

### 흐름 4: 화면 표시

```
CS 이력 조회 시:
  history_type = CONSULT → cs_category_name으로 분류 표시
  history_type = CLAIM   → cs_category_name으로 액션 표시
  JOIN 없이 cs_category_name 바로 사용
```

---

## 5. 테이블 정의서

### 5-1. cs_category (CS 분류 체계)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **분류** | 2 | `category_type` | varchar(30) | NOT NULL | - | CONSULT, PARENT_CATEGORY, CHILD_CATEGORY |
| | 3 | `parent_id` | bigint | NULL | - | 부모 카테고리 ID (CHILD_CATEGORY일 때만) |
| | 4 | `name` | varchar(100) | NOT NULL | - | 분류명 |
| | 5 | `description` | varchar(100) | NULL | - | 분류 설명 |
| | 6 | `sort_order` | int | NOT NULL | 0 | 정렬 순서 |
| | 7 | `is_system` | smallint | NOT NULL | 0 | 시스템 데이터 여부 (1=수정/삭제 불가) |
| | 8 | `is_active` | smallint | NOT NULL | 1 | 사용 여부 |
| **감사** | 9 | `created_user_id` | varchar(100) | NOT NULL | 'SYSTEM' | 생성자 |
| | 10 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 11 | `updated_user_id` | varchar(100) | NULL | - | 수정자 |
| | 12 | `updated_at` | timestamp | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |

---

### 5-2. cs_claim_code (클레임 액션)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **액션 정보** | 2 | `action_type` | varchar(30) | NOT NULL | - | SHIPPED_CLAIM, UNSHIPPED_CLAIM, COMMON_CLAIM, ETC |
| | 3 | `parent_id` | bigint | NULL | - | 부모 액션 ID (상태별 하위 액션일 때) |
| | 4 | `code` | varchar(50) | NOT NULL | - | 프로그래밍 식별코드, UNIQUE |
| | 5 | `name` | varchar(100) | NOT NULL | - | 액션명 |
| | 6 | `description` | varchar(100) | NULL | - | 설명 |
| | 7 | `status` | varchar(20) | NULL | NULL | 클레임 상태 매핑 (REQUESTED/COMPLETED/CANCELED) |
| | 8 | `sort_order` | int | NOT NULL | 0 | 정렬 순서 |
| **감사** | 9 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 10 | `updated_at` | timestamp | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |

---

### 5-3. cs_claim (클레임)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **관계** | 2 | `order_id` | bigint | NOT NULL | - | order_master.id |
| | 3 | `order_product_id` | bigint | NOT NULL | - | order_item.id |
| | 4 | `shipment_id` | bigint | NULL | - | shipment_master.id (합포 미지정 시 NULL) |
| **클레임** | 5 | `claim_type` | enum | NOT NULL | - | RETURN, RECALL, EXCHANGE, COUNTER_EXCHANGE, LOST_IN_TRANSIT, NON_DELIVERY, PRODUCT_CHANGE, SOLDOUT_CANCEL, PRE_SHIP_CANCEL |
| | 6 | `status` | enum | NOT NULL | 'REQUESTED' | REQUESTED, COMPLETED, CANCELED |
| | 7 | `claim_data` | json | NULL | - | 클레임 상세 + 교환 상품 정보 (추후 별도 테이블 분리 검토) |
| **담당자** | 8 | `worker_id` | varchar(100) | NOT NULL | 'SYSTEM' | 실제 처리 담당자 |
| **감사** | 9 | `created_user_id` | varchar(100) | NOT NULL | 'SYSTEM' | 생성자 |
| | 10 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 11 | `updated_user_id` | varchar(100) | NULL | - | 수정자 |
| | 12 | `updated_at` | timestamp | NULL | NULL | 수정일 |

---

### 5-4. cs_history (상담 이력)

| 그룹 | # | 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|---|---|---|---|---|---|---|
| **PK** | 1 | `id` | bigint | NOT NULL | GENERATED ALWAYS AS IDENTITY | PK |
| **관계** | 2 | `order_id` | bigint | NOT NULL | - | order_master.id |
| | 3 | `order_product_id` | bigint | NOT NULL | - | order_item.id |
| | 4 | `shipment_id` | bigint | NULL | - | shipment_master.id (합포 미지정 시 NULL) |
| **분류** | 5 | `history_type` | int | NOT NULL | - | 이력 유형 (common_code: CONSULT/CLAIM) |
| | 6 | `cs_category_id` | bigint | NULL | - | cs_category.id 또는 cs_claim_code.id (history_type으로 구분) |
| | 7 | `cs_category_name` | varchar(100) | NULL | - | 기록 시점 분류/액션명 (스냅샷) |
| **이력** | 8 | `is_system` | smallint | NOT NULL | 0 | 시스템 자동 여부 (0=수동, 1=자동) |
| | 9 | `cs_target` | enum | NOT NULL | 'GROUP' | GROUP(합포 전체), PRODUCT(개별 상품), ALL(전체) |
| | 10 | `content` | text | NOT NULL | - | 처리 내용 |
| | 11 | `is_important` | smallint | NOT NULL | 0 | 중요 체크 |
| | 12 | `is_complete` | smallint | NOT NULL | 0 | 처리 완료 여부 |
| | 13 | `is_pinned` | smallint | NOT NULL | 0 | 최상단 고정 |
| | 14 | `linked_memo_id` | bigint | NULL | - | 연결된 CS 메모 ID |
| **취소** | 15 | `is_canceled` | smallint | NOT NULL | 0 | 취소 여부 (0=정상, 1=취소) |
| | 16 | `canceled_user_id` | varchar(100) | NULL | - | 취소자 |
| | 17 | `canceled_at` | datetime | NULL | - | 취소 일시 |
| **담당자** | 18 | `worker_id` | varchar(100) | NOT NULL | - | 실제 처리 담당자 |
| | 19 | `completed_at` | datetime | NULL | - | 완료 처리 일시 |
| **감사** | 20 | `created_user_id` | varchar(100) | NOT NULL | 'SYSTEM' | 생성자 |
| | 21 | `created_at` | timestamp | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| | 22 | `updated_user_id` | varchar(100) | NULL | - | 수정자 |
| | 23 | `updated_at` | timestamp | NOT NULL | ON UPDATE CURRENT_TIMESTAMP | 수정일 |

---

## 6. DDL

db/init/05_cs.sql 참조


---
