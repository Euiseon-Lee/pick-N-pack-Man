# 주문 배송 시스템의 전제

---

## 1. 대전제

### 1-1. 엔티티 관계

- 주문(order_master) - 1 : N - 주문상품(order_item)
- 배송(shipment_master) - 1 : N - 배송상품(shipment_item)
- 배송상품(shipment_item) - 1 : 1 - 주문상품(order_item)
- 주문과 배송 사이에 직접적인 관계(FK)는 없다.
- 주문과 배송은 "배송상품 → 주문상품 → 주문" 경로로만 연결된다.


### 1-2. 합포

합포란, 여러 주문상품을 하나의 배송(= 하나의 송장)으로 묶는 것이다.

합포 시 하나의 shipment_master가 생성되며, 이는 하나의 송장번호에 대응한다.

또한, 각 주문상품에 대응하는 배송상품(shipment_item)이 만들어진다.

합포 처리 전 상태에서는 배송 자체가 존재하지 않는다.


### 1-3. 복합 주문

복합 주문이란 하나의 배송 안에 서로 다른 주문의 상품이 포함되는 것이다.

복합 주문은 합포 상태에서만 발생할 수 있다.


### 1-4. 합포 해제

기존 배송에 포함된 배송상품(shipment_item)을 분리하여 새로운 배송을 생성하거나, 배송 미할당 상태로 되돌릴 수 있다.

단, 출고 완료된 배송은 합포 해제가 불가능하다.


### 1-5. 주문 테이블의 책임 범위

주문 테이블(order_master, order_item)은 "주문 접수 시점의 정보"만 관리한다.

배송 상태, 송장번호, 택배사 코드 등은 배송 도메인(shipment_master, shipment_item)이 관리한다.

출고 가능 여부는 order_item.matching_status + 재고 테이블을 런타임 JOIN하여 판단한다.


### 1-6. 파생 주문

CS 클레임(교환, 분실, 미배송 등)으로 신규 주문이 생성될 수 있다.

수량 분리로 동일 주문 내에서 주문상품이 분리될 수 있다.

원본 추적은 단일 원천으로 관리한다:
  - order_master.origin_order_id → 원주문 ID
  - order_item.origin_order_item_id → 원주문상품 ID

CS에서 원본을 조회할 때: cs_claim.order_product_id → order_item.origin_order_item_id


### 1-7. 마스터/아이템 독립 관리

상태 컬럼(is_shipment_on_hold, is_canceled, is_deleted)은 양쪽 모두에 존재한다.
  - order_master의 상태 = 주문 전체에 적용
  - order_item의 상태 = 해당 상품에만 적용

각 레벨에서 독립적으로 의미를 가지며, 상호 동기화하지 않는다.


### 1-8. 출고 상태 판단

출고 상태는 2단계로 구분된다.
  - 출고 미완료 : 배송이 아직 발송되지 않은 상태
  - 출고 완료   : 배송이 발송된 상태


상품 레벨 출고 상태는 4개로 정의한다.

  - Available for Shipping     : 매칭 완료 + 재고 충분 (출고 가능)
  - Not Available for Shipping : 매칭 완료 + 재고 부족 (출고 불가능)
  - Not Matched                : 매칭 미완료 (미매칭)
  - Shipped                    : 출고 완료

출고 가능 여부(Available / Not Available)는 DB에 저장하지 않는다.

order_item.matching_status와 inventory 테이블을 런타임 JOIN하여 판단한다.

재고는 변동이 잦으므로 DB 저장 시 동기화 비용이 과도하다.


### 1-9. 재고 관리 원칙

재고(inventory)는 상품(product_item = SKU) 단위로 관리한다.

재고 수량은 WMS에서 동기화되거나 수동으로 관리된다.

재고 테이블은 "지금 몇 개 있는지"만 관리하며, 상품 정보(옵션 정의, 단가 등)는 갖지 않는다.

상품 도메인과 재고 도메인의 책임:
  - product_master   : 상품이 뭔지
  - product_item    : SKU가 뭔지 (옵션 조합, 바코드, 단가)
  - inventory        : 지금 몇 개 있는지 (가용, 예약, 불량 등)

---

## 2. 설계 규칙

| 규칙                   | 내용 |
|----------------------|---|
| **FK 제약조건**          | 단일 DB이므로 DB 수준 FK 적용 |
| **상태 관리 패턴**         | `is_*` (여부) + `*_user_id` (작업자) + `*_at` (일시) 3세트 |
| **soft delete**      | null=정상, 1=해당 |
| **marketplace_ 접두어** | 마켓에서 온 정보는 모두 marketplace_ |
| **origin_ 접두어**      | 파생 원본 추적 (CS 교환/수량 분리 등) |
| **matched_ 접두어**     | 매칭 결과 (상품매칭/재고매칭) |
| **delivery_ 접두어**    |  고객/수령자 관점 정보 (delivery_request, delivery_fee) |
| **shipment_ 접두어**    | 담당자/출고 관리 관점 (shipment_master, shipment_item, is_shipment_on_hold) |
| **코드값**              | 상태/유형은 int + common_code 참조 |
| **감사 컬럼 순서**         | created_user_id → created_at → updated_user_id → updated_at |
| **주소 타입**            | varchar(500), 인덱싱 가능 |
| **테이블 네이밍**          | 도메인 일관성: master / item 패턴 |
| **출고 가능 여부**         |	DB 저장 안 함, 런타임 재고 JOIN으로 판단 |
| **재고와 SKU 분리**       |	product_item = SKU 정의, inventory = 수량 관리 |

	