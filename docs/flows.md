# 업무 흐름

DDL에도 ERD에도 없는 정보만 적는다: **어떤 사건이 일어나면 어느 테이블의 어느 행이 어떻게 생기고 바뀌는가.**
API를 설계할 때 이 문서의 흐름 하나가 엔드포인트 하나 이상에 대응한다. 흐름 옆에 `API:` 줄을 두고, 구현되면 채운다.

예시 데이터는 `db/sample/product_inventory_sample.sql`을 기준으로 한다.

```
product_master 1   나이키 에어맥스 270 (AM270)
product_item   2   블랙/270mm  바코드 8801234002  단가 129,000
inventory          SKU 2: WH-A 가용 18, WH-B 가용 5  → 합계 23
marketplace_product_mapping   naver + SELLER_001 + NAVER-AM270 + OPT-BK27 → product 1, SKU 2
product_item   11  나이키 양말 세트 (옵션 없음)      cafe24 + SELLER_002 + CAFE24-NKSOCK + NULL → product 3, SKU 11
```

---

## 1. 상품 / 재고

### 1-1. 상품 등록

```
입력: 상품명, 코드, 옵션 목록(컬러: 블랙/화이트, 사이즈: 260/270/280), 옵션 조합별 바코드·단가

→ product_master 1행
→ product_option_type 2행           (종류 하나 = 1행. 컬러 display_order 1, 사이즈 display_order 2)
→ product_option 5행                (값 하나 = 1행. 블랙·화이트 → 컬러, 260·270·280 → 사이즈)
→ product_item 6행                  (조합 하나 = SKU 1행. 2컬러 × 3사이즈)
→ product_item_option 12행          (SKU마다 옵션 종류 수만큼. 6 × 2)
→ inventory 0행                     (재고는 WMS 동기화나 수동 입력으로 나중에 생김)

SKU 표시명("블랙/270mm")은 저장하지 않는다. product_item_option의 값을 종류 display_order 순으로 "/"로 이어 붙여 만든다
옵션이 없는 상품(양말 세트): product_option_type 0행, product_option 0행, product_item 1행, product_item_option 0행
```
API: `POST /api/v1/products` (현재는 product_master만 생성. 옵션·SKU 생성은 미구현)

### 1-2. 마켓 상품 매핑 등록

```
마켓에 상품을 올리면 마켓이 상품 ID·옵션 ID를 준다. 그걸 우리 SKU에 연결해 둔다.

→ marketplace_product_mapping 1행 / 마켓 옵션마다
   (marketplace_type, marketplace_seller_id, marketplace_product_id, marketplace_option_id) → (product_id, product_item_id)

규칙
- 같은 (마켓, 셀러, 상품ID, 옵션ID) 조합은 SKU 하나에만 매핑된다 (UNIQUE)
- product_item_id는 항상 있다 (NOT NULL). 옵션 없는 상품도 단일 SKU를 가리킨다
- 옵션 없는 상품은 marketplace_option_id = NULL. UNIQUE는 NULLS NOT DISTINCT라 같은 (마켓, 셀러, 상품ID)에 NULL 옵션 매핑이 두 번 들어가지 못한다
- 이 표가 있어야 1-4 자동 매칭이 된다. 없으면 담당자가 수동 매칭한다
```
API: 미구현

### 1-3. 재고 동기화 (WMS → 우리)

```
WMS가 SKU × 창고별 수량을 보낸다.

→ inventory upsert  (product_item_id + warehouse_id로 찾아서 있으면 UPDATE, 없으면 INSERT)
   total_stock, available_stock, reserved_stock, defective_stock 갱신, last_synced_at = now()
→ product_master, product_item는 건드리지 않는다

규칙
- 재고는 SKU 단위. "상품 단위 재고"는 없다. 상품 재고가 필요하면 SKU 합산으로 계산
- 가용 재고 = available_stock의 창고 합계. SKU 2는 18 + 5 = 23
```
API: 미구현

### 1-4. 자동 매칭

주문 접수(2-1)에서 order_item 한 줄마다 실행된다.

```
order_item의 (marketplace_type, marketplace_seller_id, marketplace_product_id, marketplace_option_id)로
marketplace_product_mapping 조회

  있음 → matched_product_id, matched_product_item_id 채움, matching_status = 3 (STOCK_MATCHED)
  없음 → 둘 다 NULL,                                       matching_status = 1 (NOT_MATCHED)

matching_status = 2 (PRODUCT_MATCHED)는 자동 매칭에서는 나오지 않는다. 담당자가 수동 매칭(1-5)에서 상품만 먼저 고른 중간 상태다

실패하는 경우: 신규 상품이라 매핑이 없음 / 마켓이 옵션 ID를 바꿔서 매핑이 깨짐
```

### 1-5. 수동 매칭

```
담당자가 미매칭(1) 또는 상품만 매칭(2)된 order_item에 SKU를 지정한다.

→ order_item.matched_product_id 설정, matching_status = 2
→ order_item_history 1행  (history_type = 2 PRODUCT_MATCHED, snapshot = {"matched_product_id": 1})
→ order_item.matched_product_item_id 설정, matching_status = 3
→ order_item_history 1행  (history_type = 3 STOCK_MATCHED, snapshot = {"matched_product_item_id": 2})
→ (선택) marketplace_product_mapping 1행 저장 → 다음 주문부터 자동 매칭됨

매칭 해제: matched_* = NULL, matching_status = 1, history 1행 (history_type = 4 UNMATCHED)
```
API: 미구현

### 1-6. 출고 가능 여부 (저장하지 않고 조회 시 계산)

| matching_status | 가용 재고 합계 vs quantity | 표시 |
|---|---|---|
| 3 | 합계 ≥ quantity | 출고 가능 (AVAILABLE) |
| 3 | 합계 < quantity | 출고 불가 (NOT_AVAILABLE) |
| 1, 2 | 무관 | 미매칭 (NOT_MATCHED) |
| 출고 완료(3-3)된 경우 | 무관 | 출고 완료 (SHIPPED) |

```sql
-- order_item 1건의 가용 재고
select coalesce(sum(available_stock), 0) from inventory where product_item_id = :matched_product_item_id
```

DB에 저장하지 않는 이유: 재고가 자주 바뀌어서 저장하면 동기화 비용이 크다.

### 1-7. 출고 시 재고 이동 (설계만 있고 시점 미확정)

```
출고 요청(3-2) 시  available_stock -= 수량,  reserved_stock += 수량
출고 완료(3-3) 시  reserved_stock  -= 수량,  total_stock    -= 수량
```
예약 시점을 합포(3-1)로 당길지, 동시 출고 시 락을 어떻게 걸지는 미정.

---

## 2. 주문

### 2-1. 주문 접수 (마켓 → 우리)

```
입력: 마켓 주문 1건 (주문자·수령자·결제·상품 목록, 원본 JSON)

→ order_master 1행
   pnp_order_no = 'ORD-YYMMDD-000001' (일자별 순번, 채번 방식 미정)
   origin_order_id = NULL (일반 주문)
   raw_data = 마켓 원본 JSON
→ order_item N행  (마켓 주문의 상품 줄 수만큼. origin_order_item_id = NULL)
   각 줄마다 1-4 자동 매칭 실행
→ order_item_history N행  (history_type = 1 CREATED)

예시: 홍길동이 네이버에서 에어맥스 블랙/270 2개 + 양말 1개 주문
  order_master 100   orderer 홍길동, receiver 김철수, total_amount 258,000 + 15,000
  order_item 1       NAVER-AM270 / OPT-BK27, quantity 2 → 매핑 있음 → matched (1, 2), status 3
  order_item 2       양말, 네이버에는 매핑 없음           → matched NULL,  status 1
```
API: 미구현. 유입 경로(크롤러가 POST로 밀어넣기 vs 우리가 마켓 API 호출) 미정

### 2-2. 수량 분리

```
order_item 1 (수량 5)을 재고 부족으로 3 + 2로 나눈다.

→ order_item 1  quantity 5 → 3, total_amount 재계산
→ order_item 4  신규. quantity 2, 같은 order_id, origin_order_item_id = 1, matched_*와 가격은 1에서 복사
→ order_item_history 2행  (1: history_type 9 QUANTITY_SPLIT, 4: history_type 1 CREATED)

규칙
- origin_order_item_id는 항상 뿌리를 가리킨다. 4를 다시 나눠 5가 생겨도 5.origin = 1. 직전 부모(4)는 history snapshot {"split_from": 4}에 남긴다
- 뿌리 찾기는 WHERE id = origin 한 번, 갈라진 줄 전부는 WHERE origin = 1 OR id = 1 한 번
- 분리된 줄은 서로 독립이다. 4만 보류하거나 4만 다른 송장에 넣을 수 있다
```
API: 미구현

### 2-3. 출고 보류 / 취소 / 삭제

```
order_master 레벨과 order_item 레벨에 같은 3세트가 각각 있다.
  is_shipment_on_hold + shipment_hold_user_id + shipment_hold_at
  is_canceled         + canceled_user_id      + canceled_at
  is_deleted          + deleted_user_id       + deleted_at

master의 값은 주문 전체에, item의 값은 그 줄에만 적용된다. 서로 동기화하지 않는다.
  → "주문 전체 보류"는 master에만 1을 쓴다. item은 그대로 NULL
  → 화면에서 "이 줄이 보류인가"는 master OR item, "주문이 취소인가"는 master OR 살아있는 item 전부 (premise 1-7)

각 동작은 order_item_history에 남긴다
  보류 5 HOLD / 해제 6 HOLD_RELEASED / 취소 7 CANCELED / 복구 8 RESTORED / 삭제 12 DELETED
값은 NULL = 정상, 1 = 해당. 0은 쓰지 않는다
```
API: 미구현

### 2-4. 주문 목록 화면

```
합포된 줄과 안 된 줄을 한 목록에 섞어서 보여준다.

  합포됨    → shipment_master 1건 = 1행  (안에 담긴 order_item들을 묶어서)
  합포 안 됨 → order_master 1건 = 1행

두 결과를 UNION해서 정렬한다. 복잡한 조회라 JPQL로는 어렵고 native query 또는 QueryDSL 필요 (미정)
```
API: 미구현

---

## 3. 출고

### 3-1. 합포 (송장 만들기)

```
같은 수령자(또는 담당자가 고른) order_item들을 송장 하나로 묶는다.

→ shipment_master 1행
   수령자 6개 컬럼 + delivery_request를 order_master에서 복사
   status = 1 PENDING, invoice_number = NULL (아직 송장번호 없음)
→ shipment_item N행  (order_item 하나당 1행. 갖는 것은 order_item_id뿐. 주문·SKU·수량은 order_item에서 읽는다)
→ order_master, order_item는 바뀌지 않는다

예시: 주문 100의 item 1, 2 와 주문 101의 item 3 (같은 수령자)을 한 박스로
  shipment_master 500        receiver 김철수
  shipment_item 5001 → order_item 1  (주문 100, SKU 2, 2개)
  shipment_item 5002 → order_item 2  (주문 100, SKU 11, 1개)
  shipment_item 5003 → order_item 3  (주문 101, SKU 2, 1개)   ← 복합 주문 (다른 주문이 같은 송장에)

규칙
- 합포 전에는 shipment 행이 없다. "아직 합포 안 됨" = shipment_item이 없는 order_item
- order_item 하나는 살아있는(is_deleted NULL) shipment_item을 하나만 가진다
- 주문 ↔ 송장 직접 FK는 없다. 경로는 shipment_item → order_item → order_master
- 매칭 안 된(matching_status < 3) item은 합포 대상이 아니다
- 합포된 order_item은 매칭을 바꿀 수 없다 (합포 해제 후에만). 그래서 SKU를 order_item에서 읽어도 안전하다
```
API: 미구현

### 3-2. 출고 요청 (우리 → WMS)

```
요청 전 검사 (저장하지 않고 이 시점에 판정)
  살아있는 shipment_item의 order_item 중 하나라도 보류(주문 또는 줄) 또는 취소면 요청 불가
  → 담당자가 그 줄을 송장에서 빼거나(3-4 B) 보류를 풀어야 요청할 수 있다

→ shipment_master.status = 2 SHIPMENT_REQUESTED
→ shipment_master.sent_at = now() (마지막 WMS 요청 일시)
→ (1-7) 재고 예약
→ WMS 응답으로 deliver_code(택배사), invoice_number(운송장) 채움
실패하면 status = 4 SHIPMENT_FAILED. item별 결과는 3-8
```
API: 미구현

### 3-3. 발송 완료

```
→ shipment_master.status = 3 SHIPPED
→ shipment_item 전체 status = 2 SHIPPED
→ (1-7) 재고 확정 차감
이 시점부터 합포 해제 불가, 클레임은 "출고 후 클레임"(4-3)만 가능
```
API: 미구현

### 3-4. 합포 해제

status가 3 SHIPPED가 아닐 때만 가능.

| 시나리오 | 동작 | 결과 |
|---|---|---|
| A. 일부를 새 송장으로 분리 | 새 shipment_master 생성, 해당 shipment_item의 shipment_id를 새 것으로 변경 | 송장 2개 |
| B. 일부를 미할당으로 되돌림 | 해당 shipment_item.is_deleted = 1 | 그 order_item은 다시 "합포 안 됨" |
| C. 전체 해제 | shipment_item 전부 is_deleted = 1, shipment_master.is_deleted = 1 | 송장 없어짐 |

물리 삭제는 하지 않는다. is_deleted = 1로 남겨 이력을 유지한다.
API: 미구현

### 3-5. 출고 보류

```
→ shipment_master.is_shipment_on_hold = 1, shipment_hold_user_id, shipment_hold_at
   status는 그대로 둔다. SHIPMENT_REQUESTED에서 보류하면 "요청까지 갔다"는 사실이 남는다
→ 해제하면 세 컬럼을 NULL로

order 쪽 is_shipment_on_hold와는 별개. 주문 보류(2-3)는 그 주문의 사정, 출고 보류는 송장 자체의 사정(재고 대기 등)
합포된 뒤 주문을 보류해도 송장에는 아무것도 쓰지 않는다. 3-2의 요청 전 검사가 막는다
```
API: 미구현

### 3-6. 배송지 변경 (CS)

```
→ shipment_master의 수령자 컬럼만 수정
→ order_master의 수령자는 접수 시점 원본 그대로 둔다
합포 전(shipment 행이 없을 때)에 주소가 바뀌면 어디에 반영할지는 미정 (5절)
```
API: 미구현

### 3-7. 합포된 주문상품이 취소될 때

```
취소는 order_item(또는 order_master)에만 쓴다. shipment_item, shipment_master에는 취소 컬럼이 없다.

master.status ≠ SHIPPED  → order_item.is_canceled = 1 로 끝. 송장 화면은 그 줄을 "취소"로 표시(도출)하고,
                           3-2 요청 전 검사가 그 송장을 막는다. 담당자가 그 줄을 빼면(3-4 B) 나머지가 나간다
master.status = SHIPPED  → 취소 불가. CS 클레임(반품 4-3)으로만 처리
송장의 살아있는 줄이 전부 취소 → 송장을 "취소"로 표시(도출). 정리하려면 3-4 C로 합포 해제
복구(order_item_history 8 RESTORED) → order_item.is_canceled = NULL. 송장은 건드릴 것이 없다
```
API: 미구현

### 3-8. WMS 실사에서 수량이 모자랄 때

송장 500: item 5001(SKU 2 × 2개), 5002(양말 × 1개). 창고에 SKU 2가 1개뿐.

```
① WMS 결과 수신
   item 5001   status = 3 FAILED   (2개 중 1개만 있음)
   item 5002   status = 1 PENDING  (문제 없음)
   master 500  status = 4 SHIPMENT_FAILED

② CS 팀이 고객에게 확인 → cs_history 1행 (history_type 1 CONSULT, cs_target 1 GROUP, 내용: 확인 결과)
   고객 선택에 따라 셋 중 하나

   a. 있는 것만 먼저 보내고 부족분은 나중에
      수량 분리(2-2)   order_item 1  2개 → 1개,  order_item 4 신규 1개 (origin_order_item_id = 1, 송장 없음)
      item 5001        is_deleted = 1
      item 5004 신규   order_item 1, status = 1 PENDING
      master 500       status = 2 SHIPMENT_REQUESTED (재요청) → 발송(3-3)
      order_item 4     재고가 들어와 출고 가능(1-6)이 되면 새 송장으로 합포(3-1)

   b. 전부 들어올 때까지 기다림
      master 500       is_shipment_on_hold = 1 (3-5). status는 SHIPMENT_FAILED 그대로
      재고 입고 후      보류 해제 → 재요청 → 발송

   c. 부족분 취소 (품절취소)
      수량 분리 후 order_item 4에 클레임  claim_type 8 SOLDOUT_CANCEL, 즉시 완료 → order_item 4.is_canceled = 1
      나머지는 a와 같이 재요청
```
부족 수량·사유 같은 WMS 응답 값을 담을 컬럼은 WMS 스펙이 정해진 뒤 추가한다.
API: 미구현

---

## 4. CS

CS = 상담(기록만 남김) + 클레임(접수 → 완료/취소 절차가 있고 주문 데이터가 바뀜)

### 4-1. 상담 기록

```
담당자가 "고객이 사이즈 교환 되냐고 문의함"을 남긴다.

→ cs_history 1행
   history_type = 1 CONSULT
   cs_category_id = cs_category의 id (예: '교환' > '교환요청'), cs_category_name = '교환요청' (이름 복사)
   cs_target = 1 GROUP(합포 전체) / 2 PRODUCT(이 상품만) / 3 ALL
   content, worker_id, is_important, is_pinned
→ cs_claim 없음. 주문·출고 데이터는 바뀌지 않는다

cs_category_name을 복사해 두는 이유: 나중에 분류 이름이 바뀌어도 기록 시점 이름을 보존. 조회 시 JOIN 불필요
```
API: 미구현

### 4-2. 출고 전 클레임: 부분 교환

```
order_item 1 (수량 5, 아직 합포 안 됨) 중 2개를 교환

① 수량 분리 (2-2)          order_item 1 → 3개,  order_item 4 → 2개 (origin_order_item_id = 1)
② 클레임 접수
   → cs_claim 1행          order_product_id 4, shipment_id NULL, claim_type = 3 EXCHANGE, status = 1 REQUESTED
   → cs_history 1행        history_type 2 CLAIM, cs_category_id = cs_claim_code 'EXCHANGE_REQUESTED'의 id, name '교환 접수'
   → order_item_history    item 4에 history_type 10 CLAIM_REQUESTED
③ 교환 완료
   → cs_claim.status = 2 COMPLETED
   → order_master 200 신규  origin_order_id = 100 (교환 상품을 보낼 새 주문)
   → order_item 5 신규      order_id 200, origin_order_item_id = 1 (4의 뿌리), 교환할 SKU로 매칭
   → order_item 4           원래 줄의 처리는 미정 (5절). cs_category에 '교환으로 인한 취소' 분류가 있어 취소로 보이지만 확정된 규칙은 없다
   → cs_history 1행        '교환 완료'
   → order_item_history    item 4에 11 CLAIM_COMPLETED, item 5에 1 CREATED

이후 새 주문 200은 일반 주문처럼 합포 → 출고를 탄다
```
API: 미구현

### 4-3. 출고 후 클레임: 반품

```
shipment_master 500 (status SHIPPED)의 shipment_item 5001 → order_item 1

① 반품 접수
   → cs_claim 1행          order_product_id 1, shipment_id 500, claim_type = 1 RETURN, status = 1 REQUESTED
   → cs_history 1행        '발송후반품 접수'
② 반품 완료 (물건이 돌아옴)
   → cs_claim.status = 2 COMPLETED
   → order_item 1.is_canceled = 1
   → cs_history 1행        '발송후반품 완료'
   → (재고 입고는 WMS 동기화(1-3)로 반영)

출고 후 클레임에는 shipment_id가 반드시 있다. 출고 전 클레임(4-2)은 NULL
```
API: 미구현

### 4-4. 클레임 유형과 상태

cs_claim_code에 정의된 유형. 접수 → 완료 / 취소 절차가 있는 것과 즉시 완료인 것이 있다.

| 구분 | claim_type | 절차 | 결과 |
|---|---|---|---|
| 출고 후 | RETURN 반품 | 접수 → 완료/취소 | order_item 취소 |
| | RECALL 회수 | 접수 → 완료/취소 | |
| | EXCHANGE 교환 | 접수 → 완료/취소 | 새 주문 생성 (4-2) |
| | COUNTER_EXCHANGE 맞교환 | 접수 → 완료/취소 | 새 주문 생성 |
| | LOST_IN_TRANSIT 분실, NON_DELIVERY 미배송 | 즉시 완료 | 새 주문 생성 |
| 출고 전 | PRODUCT_CHANGE 상품변경, SOLDOUT_CANCEL 품절취소, PRE_SHIP_CANCEL 발송전취소 | 즉시 완료 | order_item 변경/취소 |


클레임 유형의 원천은 common_code CLAIM_TYPE 9개다. cs_claim_code는 CS 화면의 액션(버튼) 목록이고, 각 액션은 "어느 유형의 클레임(claim_type)을 어느 상태(status)로 만드는가"를 갖는다.
  예: EXCHANGE_REQUESTED = claim_type 3 EXCHANGE, status 1 REQUESTED
      LOST_IN_TRANSIT    = claim_type 5, status 2 COMPLETED (접수 없이 즉시 완료)
COMMON_CLAIM(취소주문 복구, CS메모연결, 주문삭제, 바코드인쇄)과 ETC(주문수량 분리)는 claim_type이 null이다. 클레임을 만들지 않고 실행 결과만 cs_history(history_type 2)와 order_item_history에 남긴다.

### 4-5. CS 이력 화면

```
cs_history를 order_item 또는 shipment 기준으로 시간순 조회
  history_type 1 → cs_category_name을 분류로 표시
  history_type 2 → cs_category_name을 액션으로 표시
  둘 다 cs_category_name만 쓰므로 JOIN 없음
is_pinned = 1 은 최상단, is_important = 1 은 강조
```
API: 미구현

---

## 5. 미정 사항 (구현 전에 정할 것)

| 항목 | 선택지 |
|---|---|
| 주문 유입 경로 | 크롤러가 우리 API에 POST vs 우리가 마켓 API 폴링 |
| pnp_order_no 채번 | DB sequence + 날짜 prefix vs 일자별 순번 테이블 |
| 재고 예약 시점 | 합포 시 vs 출고 요청 시. 동시 출고 락 전략 |
| 작업자 식별 | created_user_id에 넣을 값. 인증 도입 전까지 헤더로 받을지 |
| 목록 조회 기술 | native query vs QueryDSL |
| 합포 전 배송지 변경 | shipment가 없을 때 바뀐 주소를 order_master에 쓸지, 별도 보관할지 |
| 교환 완료 시 원 주문상품 | 원래 줄(수량 분리된 쪽)을 is_canceled = 1 로 할지, 다른 표시를 둘지 |
