## 패키지 구조 설명
```
src/main/java/com/picknpack/
├── PickNPackApplication.java
│
├── common/                            ← 공통
│   ├── entity/
│   │   └── BaseEntity.java           ← 감사 컬럼 공통 클래스
│   └── dto/
│       └── ApiResponse.java          ← 공통 응답 wrapper
│
└── product/                           ← 상품 도메인
    ├── entity/
    │   ├── ProductMaster.java
    │   ├── ProductItem.java
    │   ├── ProductOption.java
    │   ├── ProductItemOption.java
    │   └── Inventory.java
    ├── repository/
    │   ├── ProductMasterRepository.java
    │   ├── ProductItemRepository.java
    │   └── InventoryRepository.java
    ├── dto/
    │   ├── request/
    │   │   └── CreateProductRequest.java
    │   └── response/
    │       └── ProductResponse.java
    ├── service/
    │   └── ProductService.java
    └── controller/
        └── ProductController.java
```

---

### common/ (공통 모듈)

**특정 도메인에 속하지 않고, 여러 도메인에서 재사용하는 것들.**

#### common/entity/BaseEntity.java

거의 모든 테이블에 반복되는 감사 컬럼:
```
created_user_id, created_at, updated_user_id, updated_at
```

이걸 매번 각 Entity에 쓰면 중복이니까, **한 번 정의하고 상속받아 사용**합니다.

```java
ProductMaster extends BaseEntity   → 감사 컬럼 자동 포함
OrderMaster extends BaseEntity     → 감사 컬럼 자동 포함
```

#### common/dto/ApiResponse.java

API 응답의 공통 포맷. 예를 들어:
```json
{
  "success": true,
  "data": { ... },
  "message": null
}
```
```json
{
  "success": false,
  "data": null,
  "message": "상품을 찾을 수 없습니다"
}
```

모든 API가 동일한 형태로 응답하도록 wrapper를 만드는 겁니다.

---

### product/ (상품 도메인)

**상품과 관련된 모든 코드가 이 안에 존재.**

#### product/entity/

**DB 테이블과 1:1 매핑되는 Java 클래스.**

```
ProductMaster.java      ↔ product_master 테이블
ProductItem.java        ↔ product_item 테이블
ProductOption.java      ↔ product_option 테이블
ProductItemOption.java  ↔ product_item_option 테이블
Inventory.java          ↔ inventory 테이블
```

JPA가 이 클래스를 보고 "이 객체는 이 테이블에서 온 데이터다"라고 인식합니다.

#### product/repository/

**DB 조회/저장을 담당하는 인터페이스.**

NestJS의 TypeORM Repository와 같은 역할입니다. Spring Data JPA가 인터페이스만 정의하면 **구현체를 자동 생성**합니다.

```java
public interface ProductMasterRepository extends JpaRepository<ProductMaster, Long> {
    // findAll(), findById(), save(), delete() 등이 자동으로 생김
    // 추가 쿼리는 메서드명으로 정의
    Optional<ProductMaster> findByCode(String code);
}
```

`findByCode`라고 메서드명만 쓰면 JPA가 `SELECT * FROM product_master WHERE code = ?`를 자동 생성합니다.

#### product/dto/

**클라이언트와 주고받는 데이터 형태.**

Entity를 직접 클라이언트에 노출하면 문제가 생깁니다:
- 내부 필드가 전부 노출됨
- 클라이언트 요청과 테이블 구조가 다를 수 있음

그래서 **요청용(request)과 응답용(response)을 분리**합니다.

```
dto/request/CreateProductRequest.java   ← 클라이언트가 보내는 데이터
dto/response/ProductResponse.java       ← 클라이언트에 보내는 데이터
```

예시:
```java
// 클라이언트가 상품 등록 시 보내는 데이터
public class CreateProductRequest {
    private String name;          // 필수
    private String code;          // 선택
    private String description;   // 선택
}

// 클라이언트에 응답하는 데이터
public class ProductResponse {
    private Long id;
    private String name;
    private String code;
    private Integer status;
    private String statusName;    // common_code에서 조회한 한글명
    private LocalDateTime createdAt;
}
```

Entity에는 `statusName`이 없지만 응답에는 필요 → DTO에서 변환.

#### product/service/

**비즈니스 로직을 담당.**

Controller는 요청을 받아서 Service에 전달하고, Service가 실제 일을 합니다.

```
클라이언트 → Controller → Service → Repository → DB
클라이언트 ← Controller ← Service ← Repository ← DB
```

예시:
```java
// "상품 등록" 비즈니스 로직
public ProductMaster createProduct(CreateProductRequest request) {
    // 1. 코드 중복 검사
    // 2. Entity 생성
    // 3. DB 저장
    // 4. 반환
}
```

#### product/controller/

**HTTP 요청의 진입점.** URL과 메서드를 매핑합니다.

```
GET    /api/v1/products       → 상품 목록 조회
GET    /api/v1/products/{id}  → 상품 상세 조회
POST   /api/v1/products       → 상품 등록
PUT    /api/v1/products/{id}  → 상품 수정
DELETE /api/v1/products/{id}  → 상품 삭제
```

Controller는 **로직을 직접 수행하지 않고**, Service에 위임만 합니다.

---

### 요청 흐름 정리

```
[클라이언트] POST /api/v1/products  { "name": "나이키 에어맥스", "code": "AM270" }
     │
     ▼
[Controller] 요청 수신, DTO로 변환, Service 호출
     │
     ▼
[Service] 비즈니스 로직 (중복검사 등), Repository 호출
     │
     ▼
[Repository] DB에 INSERT
     │
     ▼
[Entity] product_master 테이블에 저장됨
     │
     ▼
[Service] Entity → Response DTO 변환
     │
     ▼
[Controller] 응답 반환
     │
     ▼
[클라이언트] { "success": true, "data": { "id": 1, "name": "나이키 에어맥스", ... } }
```
