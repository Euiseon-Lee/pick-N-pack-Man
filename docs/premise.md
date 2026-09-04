# 주문·출고 시스템의 전제

---

## 0. 용어

| 용어 | 뜻 | 데이터 |
|---|---|---|
| **출고** | 송장 단위로 창고에서 물건이 나가는 것. WMS에 요청하고 발송 완료로 끝난다 | shipment_master, shipment_item, SHIPMENT_STATUS |
| **배송** | 출고된 뒤 택배사가 고객에게 전달하는 과정 | 현재 모델에 없다. 배송중·배송완료 같은 상태 코드는 정의돼 있지 않다. 고객 관점 정보만 `delivery_` 접두어로 둔다 (delivery_request, delivery_fee) |
| **송장** | 출고 1건 = 운송장 1장 = shipment_master 1행 | invoice_number, deliver_code |
| **합포** | 여러 주문상품을 송장 하나로 묶는 것 | flows.md 3-1 |
| **복합 주문** | 송장 하나에 서로 다른 주문의 상품이 섞인 것. 합포에서만 생긴다 | |
| **SKU** | 옵션 조합 하나. 재고·출고의 최소 단위 | product_item |
| **매칭** | 마켓 주문상품을 우리 상품/SKU에 연결하는 것 | order_item.matched_*, matching_status |

---

## 1. 대전제

### 1-1. 엔티티 관계

- 주문(order_master) - 1 : N - 주문상품(order_item)
- 출고(shipment_master) - 1 : N - 출고상품(shipment_item)
- 출고상품(shipment_item) - 1 : 1 - 주문상품(order_item)
- 주문과 출고 사이에 직접적인 관계(FK)는 없다.
- 주문과 출고는 "출고상품 → 주문상품 → 주문" 경로로만 연결된다.


### 1-2. 합포

합포란, 여러 주문상품을 하나의 출고(= 송장 하나)로 묶는 것이다.

합포 시 하나의 shipment_master가 생성되며, 이는 하나의 송장번호에 대응한다.

또한, 각 주문상품에 대응하는 출고상품(shipment_item)이 만들어진다.

합포 처리 전에는 출고 자체가 존재하지 않는다.


### 1-3. 복합 주문

복합 주문이란 하나의 출고(송장) 안에 서로 다른 주문의 상품이 포함되는 것이다.

복합 주문은 합포 상태에서만 발생할 수 있다.


### 1-4. 합포 해제

기존 출고에 포함된 출고상품(shipment_item)을 분리하여 새 출고를 만들거나, 출고 미할당 상태로 되돌릴 수 있다.

단, 발송 완료된 출고는 합포 해제가 불가능하다.


### 1-5. 주문 테이블의 책임 범위

주문 테이블(order_master, order_item)은 "주문 접수 시점의 정보"만 관리한다.

출고 상태, 송장번호, 택배사 코드 등은 출고 도메인(shipment_master, shipment_item)이 관리한다.

### 1-6. 파생 주문

CS 클레임(교환, 분실, 미배송 등)으로 신규 주문이 생성될 수 있다.

수량 분리로 동일 주문 내에서 주문상품이 분리될 수 있다.

원본 추적은 단일 원천으로 관리하며, 항상 뿌리(맨 처음 원본)를 가리킨다:
  - order_master.origin_order_id → 뿌리 주문 ID
  - order_item.origin_order_item_id → 뿌리 주문상품 ID
  - 새 행을 만들 때: 대상 행의 origin이 있으면 그 값을, 없으면 대상 행의 id를 넣는다
    1(원본) → 4(origin 1) → 4를 다시 나눈 5도 origin 1
  - 직전 부모가 필요하면 order_item_history(QUANTITY_SPLIT)의 snapshot {"split_from": 4}를 본다
  - 이유: 원본 조회가 WHERE 한 번으로 끝나고, 갈라진 줄 전부는 WHERE origin = 뿌리 한 번으로 모인다

CS에서 원본을 조회할 때: cs_claim.order_product_id → order_item.origin_order_item_id


### 1-7. 저장은 각자, 판정은 조회 시

플래그는 실제로 한 행위가 일어난 행에만 쓴다. 다른 행으로 복사하거나 자동으로 전파하지 않는다.
  - order_master의 플래그 = 담당자가 "주문 전체"에 한 행위
  - order_item의 플래그   = 그 줄에만 한 행위
  - 출고(shipment_*)에는 취소 플래그가 없다. 취소는 담긴 order_item에서 도출한다

합쳐진 상태는 저장하지 않고 조회나 행위 시점에 계산한다.
  - 줄이 취소인가     : order_master.is_canceled = 1 OR order_item.is_canceled = 1
  - 주문이 취소인가   : order_master.is_canceled = 1 OR 살아있는 order_item 전부 취소
  - 줄이 보류인가     : order_master.is_shipment_on_hold = 1 OR order_item.is_shipment_on_hold = 1
  - 송장을 요청할 수 있나 : 살아있는 shipment_item의 order_item 중 보류·취소가 하나도 없을 때만
  - 송장이 취소인가   : 살아있는 shipment_item의 order_item이 전부 취소

동기화를 하지 않는 이유: 전파 코드가 실패하거나 부분 복구에서 꼬이면 두 곳이 어긋나고, 어느 쪽이 맞는지 알 수 없게 된다.


### 1-8. 출고 상태 판단

출고 상태는 2단계로 구분된다.
  - 출고 미완료 : 송장이 아직 발송되지 않은 상태
  - 출고 완료   : 송장이 발송된 상태


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


### 1-10. 상태와 플래그

되돌릴 수 없는 진행은 status, 되돌릴 수 있는 표시는 플래그로 둔다.

  - status  : "지금 어디까지 왔나". 한 방향으로만 바뀌고 한 시점에 하나만 가진다.
              실패(SHIPMENT_FAILED)는 위치이며, 실패 후 재요청으로 되돌아가는 것만 허용한다.
  - 플래그   : "지금 붙어 있는 표시". 어느 status에서든 붙였다 뗄 수 있고 여러 개가 동시에 붙는다.
              보류·취소·삭제가 플래그인 이유는 복구(RESTORED, RESTORE_CANCEL)가 있기 때문이다.

표별 구성
  - order_master     : status 없음. 보류·취소·삭제 플래그
  - order_item       : matching_status (매칭 작업 단계, 해제 시 1로 되돌아가는 예외). 보류·취소·삭제 플래그
  - shipment_master  : PENDING → SHIPMENT_REQUESTED → SHIPPED, 실패 시 SHIPMENT_FAILED. 보류·삭제 플래그 (취소는 1-7대로 도출)
  - shipment_item    : WMS가 알려주는 item별 결과. PENDING → SHIPPED 또는 FAILED. 삭제 플래그 (취소는 order_item에서 도출)
  - cs_claim         : REQUESTED → COMPLETED 또는 CANCELED (절차의 종착이라 status). 플래그 없음

화면에 "현재 상태" 하나로 보일 때는 저장하지 않고 조회 시 계산한다. 우선순위:
  is_deleted=1 → 삭제됨(숨김) > 취소(1-7의 도출 규칙) > 보류(1-7의 도출 규칙, status 병기) > status 그대로

master와 item의 관계
  - 살아있는 item이 전부 SHIPPED      → master SHIPPED
  - 살아있는 item 중 하나라도 FAILED  → master SHIPMENT_FAILED
  - item이 전부 취소                  → master를 취소로 표시 (저장하지 않음, 1-7)

---

## 2. 설계 규칙

| 규칙                   | 내용 |
|----------------------|---|
| **FK 제약조건**          | 단일 DB이므로 DB 수준 FK 적용. 도메인 내부 FK는 각 도메인 SQL에, 도메인 간 FK는 `98_foreign_keys.sql`에 일괄 정의 |
| **상태 관리 패턴**         | status = 진행 위치(한 방향), 플래그 = 되돌릴 수 있는 표시. 자세한 규칙은 1-10 |
| **플래그 3갈래**         | 행위(보류·취소·삭제·완료: 책임이 따름) = `is_*` + `*_user_id` + `*_at` 3세트, null=아님 1=해당. 표시(중요·고정) = `is_*` 하나, null=아님 1=해당. 속성(`is_active`, `is_system`) = `0/1 NOT NULL`, user·at 없음 |
| **marketplace_ 접두어** | 마켓에서 온 정보는 모두 marketplace_ |
| **origin_ 접두어**      | 파생 원본 추적 (CS 교환/수량 분리 등) |
| **matched_ 접두어**     | 매칭 결과 (상품매칭/재고매칭) |
| **delivery_ 접두어**    |  고객/수령자 관점 정보 (delivery_request, delivery_fee) |
| **shipment_ 접두어**    | 담당자/출고 관리 관점 (shipment_master, shipment_item, is_shipment_on_hold) |
| **코드값**              | 상태·유형 컬럼은 전부 `int` + common_code 참조. 컬럼별 그룹명은 DDL의 COMMENT ON에 적는다. varchar 상태 컬럼은 두지 않는다 |
| **감사 컬럼 순서**         | created_user_id → created_at → updated_user_id → updated_at |
| **주소 타입**            | varchar(500), 인덱싱 가능 |
| **테이블 네이밍**          | 도메인 일관성: master / item 패턴 |
| **정렬 컬럼 이름**       | 코드·분류 표(common_code, cs_category, cs_claim_code)는 `sort_order` = 목록 정렬 순서. 옵션 표(product_option_type, product_option)는 `display_order` = 화면 표시 순서이며 옵션 종류의 display_order는 SKU 표시명 순서로도 쓰인다 |
| **공통 코드 운영**       | 코드 추가는 group 내 최대값+1, 기존 code 값 변경 금지(int로 참조 중), 폐기는 삭제 대신 is_active=0, name은 영문 대문자 식별자·description은 한글 표시용 |

	
---

## 3. 문서 규칙

| 규칙 | 내용 |
|---|---|
| **스키마 원천** | `src/main/resources/db/init/*.sql` 이 유일한 원천. 컬럼 설명은 `COMMENT ON`으로 DDL 안에 적고, 다른 문서에 컬럼 표를 만들지 않는다. 문서와 DDL이 어긋나면 DDL을 따른다 |
| **업무 흐름** | `flows.md` 한 파일. "사건이 일어나면 어느 행이 어떻게 바뀌는가"만 적고, 컬럼 정의·관계는 적지 않는다 (DDL·ERD와 중복 금지) |
| **ERD** | ERDCloud에서 관리. `erd.md` 의 절차로 DDL에서 변환해 가져온다 |
| **마이그레이션** | Flyway 등 도구 미사용. 스키마 변경은 init SQL 수정 + 볼륨 재생성 |
| **API 문서** | springdoc이 코드에서 생성한 OpenAPI(`/api-docs`)를 `docs/api/openapi.json`으로 내려받아 커밋. Postman은 이 파일을 Import |
| **문서 위치** | 설계 문서는 루트 `docs/`, DDL과 샘플 SQL만 `src/main/resources/db/` (docker 마운트 필요) |
