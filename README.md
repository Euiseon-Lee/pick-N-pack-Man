# pick-N-pack-Man

마켓(네이버, 카페24 등)에서 수집한 주문을 우리 상품/SKU에 매칭하고, 합포(여러 주문 상품을 송장 하나로 묶기)하여 출고하고, 이후 CS(상담·클레임)까지 관리하는 주문·출고 시스템의 백엔드 API.

```
상품 등록 → 마켓 주문 수집 → 상품/SKU 매칭 → 합포(송장 생성) → 출고 → CS
```

---

## 기술 스택

| 구분 | 내용 |
|---|---|
| 언어 / 프레임워크 | Java 17, Spring Boot 3.4 (Web, Data JPA, Validation) |
| DB | PostgreSQL 16 (Docker) |
| API 문서 | springdoc-openapi (Swagger UI) |
| 빌드 | Gradle (Kotlin DSL) |

---

## 실행

**1. DB 기동** — `docker-compose.yml`이 `src/main/resources/db/init/*.sql`을 자동 실행해 테이블과 공통 코드를 만든다.

```bash
docker compose up -d
```

**2. 샘플 데이터** (선택) — 상품/옵션/SKU/재고/마켓 매핑 예시.

```bash
docker exec -i pnp-postgres psql -U pnp -d pick_n_pack_man < src/main/resources/db/sample/product_inventory_sample.sql
```

**3. 앱 실행** — IntelliJ에서 `PickNPackApplication` 실행, 또는

```bash
./gradlew bootRun
```

JDK 17이 필요하다. 터미널에서 실행할 때 `java`가 PATH에 없으면 `JAVA_HOME`을 JDK 17 경로로 지정한다.

기동 시 `ddl-auto: validate`로 엔티티와 테이블을 대조하므로 스키마가 안 맞으면 여기서 실패한다.

**4. API 확인**

| 항목 | 주소 |
|---|---|
| Swagger UI | http://localhost:8080/docs |
| OpenAPI JSON | http://localhost:8080/api-docs |

**스키마를 바꾼 뒤에는** 볼륨을 지우고 다시 올려야 init SQL이 재실행된다.

```bash
docker compose down -v && docker compose up -d
```

---

## 문서 구조

정보마다 원천을 하나만 둔다. 같은 내용을 두 곳에 적지 않는다.

| 알고 싶은 것 | 보는 곳 |
|---|---|
| 테이블·컬럼이 무엇인지 | `src/main/resources/db/init/*.sql` (DDL, COMMENT 포함) |
| 테이블끼리 어떻게 연결되는지 | ERD (ERDCloud, 링크는 `docs/erd.md`) |
| 어떤 일이 생기면 데이터가 어떻게 바뀌는지 | `docs/flows.md` |
| 설계 원칙과 네이밍·상태 규칙 | `docs/premise.md` |
| API 요청/응답 | `docs/api/openapi.json` (Swagger UI와 동일) |

```
docs/
├── premise.md              시스템 전제, 설계 규칙, 문서 규칙 ← 가장 먼저 읽을 것
├── flows.md                업무 흐름: 사건별로 어느 행이 생기고 바뀌는지, 미정 사항
├── erd.md                  ERD 위치(ERDCloud)와 갱신 절차
├── erd/                    DDL → ERDCloud 변환 스크립트와 결과
└── api/                    OpenAPI 스펙(Postman import용)과 환경 파일

src/main/resources/db/
├── init/                   DDL — 스키마의 유일한 원천
└── sample/                 수동 실행용 샘플 데이터
```

### 문서 규칙

- **스키마 원천은 DDL**(`src/main/resources/db/init/*.sql`)이다. 컬럼 설명은 `COMMENT ON`으로 DDL 안에 적는다. 다른 문서에 컬럼 표를 만들지 않는다.
- **업무 흐름은 `docs/flows.md` 한 파일**에 적는다. "무슨 일이 생기면 어느 행이 어떻게 바뀌는가"만 쓰고, 컬럼 정의나 관계는 쓰지 않는다.
- **ERD는 ERDCloud**에서 관리한다. DDL 변경 후 `docs/erd.md`의 절차로 다시 가져온다.
- **API 문서는 코드에서 생성**한다. 컨트롤러를 바꾼 뒤 앱을 띄우고 아래로 내려받아 커밋한다. Postman에서는 이 파일을 Import → OpenAPI로 읽는다.

  ```bash
  curl -s http://localhost:8080/api-docs -o docs/api/openapi.json
  ```

- **마이그레이션 도구(Flyway 등)는 쓰지 않는다.** 스키마 변경은 init SQL 수정 + 볼륨 재생성.

### 커밋 메시지

`<도메인> - <내용>` 형식. 예: `주문 도메인 - 주문 마스터 entity`, `공통 - 예외 처리 및 에러 응답 포맷 추가`, `문서 - 업무 흐름 정리`
