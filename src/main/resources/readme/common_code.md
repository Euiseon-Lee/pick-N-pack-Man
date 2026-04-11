# common code 정의서 - v1.260411

---

## 1. 테이블 구성

```
common_code               공통 코드
```

---

## 2. 각 테이블의 책임

| 테이블 | 질문 | 책임 | 변경 빈도 |
|---|---|---|---|
| `common_code` | 이 코드값이 뭐지? | 상태/유형 코드의 정의 및 관리 | 낮음 |

---

## 3. 관계

### 참조하는 테이블

| group_code | 참조 테이블 | 참조 컬럼 | 설명 |
|---|---|---|---|
| `MATCHING_STATUS` | order_item | matching_status | 매칭 상태 |
| `ORDER_ITEM_HISTORY_TYPE` | order_item_history | history_type | 주문 상품 변경 이력 유형 |
| `PRODUCT_STATUS` | product_master | status | 상품 상태 |
| `SKU_STATUS` | product_item | status | SKU 상태 |
| `SHIPMENT_STATUS` | shipment_master | status | 출고 상태 |
| `SHIPMENT_ITEM_STATUS` | shipment_item | status | 출고 상품 상태 |
| `SHIPMENT_TYPE` | shipment_master | shipment_type | 출고 유형 (WMS 참고용) |
| `HISTORY_TYPE` | cs_history | history_type | CS 이력 유형 |
| `CS_STATUS` | - | - | CS 처리 상태 (화면 표시용) |

---

## 4. 코드 그룹 목록

### 주문 도메인

| group_code | code | name | 설명 |
|---|---|---|---|
| `MATCHING_STATUS` | 1 | NOT_MATCHED | 미매칭 |
| | 2 | PRODUCT_MATCHED | 상품매칭 완료 |
| | 3 | STOCK_MATCHED | 재고매칭 완료 |
| `ORDER_ITEM_HISTORY_TYPE` | 1 | CREATED | 생성 |
| | 2 | PRODUCT_MATCHED | 상품 매칭 |
| | 3 | STOCK_MATCHED | 재고(SKU) 매칭 |
| | 4 | UNMATCHED | 매칭 해제 |
| | 5 | HOLD | 출고보류 |
| | 6 | HOLD_RELEASED | 출고보류 해제 |
| | 7 | CANCELED | 취소 |
| | 8 | RESTORED | 취소 복구 |
| | 9 | QUANTITY_SPLIT | 수량 분리 |
| | 10 | CLAIM_REQUESTED | 클레임 접수 |
| | 11 | CLAIM_COMPLETED | 클레임 완료 |
| | 12 | DELETED | 삭제 |

### 상품 도메인

| group_code | code | name | 설명 |
|---|---|---|---|
| `PRODUCT_STATUS` | 1 | ACTIVE | 활성 |
| | 2 | INACTIVE | 비활성 |
| | 3 | DISCONTINUED | 단종 |
| `SKU_STATUS` | 1 | ACTIVE | 활성 |
| | 2 | INACTIVE | 비활성 |
| | 3 | OUT_OF_STOCK | 품절 |

### 배송 도메인

| group_code | code | name | 설명 |
|---|---|---|---|
| `SHIPMENT_STATUS` | 1 | PENDING | 출고 대기 |
| | 2 | SHIPMENT_REQUESTED | 출고요청 완료 |
| | 3 | SHIPPED | 발송완료 |
| | 4 | SHIPMENT_FAILED | 출고 실패 |
| | 5 | SHIPMENT_ON_HOLD | 출고보류 |
| `SHIPMENT_ITEM_STATUS` | 1 | PENDING | 대기 |
| | 2 | SHIPPED | 발송완료 |
| | 3 | CANCELLED | 취소됨 |
| `SHIPMENT_TYPE` | 1 | TRANSFER | 이관형 |
| | 2 | DIRECT | 직접출고 |

### CS 도메인

| group_code | code | name | 설명 |
|---|---|---|---|
| `HISTORY_TYPE` | 1 | CONSULT | 수동 상담 |
| | 2 | CLAIM | 클레임 |
| `CS_STATUS` | 1 | REQUESTED | 미처리 |
| | 2 | COMPLETED | 처리완료 |
| | 3 | PROCESSING | 처리중 |

---

## 5. 운영 규칙

- 동일 group_code 내에서 code 값은 중복 불가 (UNIQUE 제약)
- 코드 추가 시 code 값은 기존 최대값 + 1로 순차 부여
- 기존 코드의 code 값은 변경하지 않음 (다른 테이블에서 int로 참조 중)
- 코드 폐기 시 삭제하지 않고 is_active = 0으로 비활성화
- name은 프로그래밍 식별용 (영문 대문자 + 언더스코어), description은 화면 표시용 (한글)

---

## 6. DDL

db/init/01_common_code.sql 참조
