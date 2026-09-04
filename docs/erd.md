# ERD 관리 - ERDCloud

ERD는 ERDCloud에서 관리한다. 스키마의 원천은 `src/main/resources/db/init/*.sql` 이고, ERDCloud는 보기/공유용이다.

- ERDCloud 링크: https://www.erdcloud.com/d/RWXp7yqwpzL7SPGRR

---

## 파일

| 파일 | 역할 |
|---|---|
| `docs/erd/generate-erdcloud-ddl.js` | `src/main/resources/db/init/*.sql` → ERDCloud 가져오기용 DDL 변환 스크립트 |
| `docs/erd/erdcloud.sql` | 변환 결과 (자동 생성, 직접 수정하지 말 것) |

---

## DDL 변경 시 ERD 갱신 순서

1. `src/main/resources/db/init/*.sql` 수정
2. 변환 스크립트 실행

   ```bash
   node docs/erd/generate-erdcloud-ddl.js
   ```

3. ERDCloud 다이어그램 열기 → 상단 메뉴 `Import` → `SQL` → `docs/erd/erdcloud.sql` 내용 붙여넣기
4. 기존 테이블이 있으면 덮어쓸지 확인 후 배치 정리
5. `docs/erd/erdcloud.sql` 을 함께 커밋

---

## 변환 규칙

| PostgreSQL (원천) | 변환 결과 | 이유 |
|---|---|---|
| `GENERATED ALWAYS AS IDENTITY` | `AUTO_INCREMENT` | ERDCloud 파서가 MySQL 문법 기준 |
| `TIMESTAMP` | `DATETIME` | |
| `JSONB` | `JSON` | |
| `COMMENT ON TABLE / COLUMN` | 인라인 `COMMENT '...'` | ERDCloud의 컬럼 코멘트 칸에 들어간다. ERD 설정 → 디스플레이 → 코멘트를 켜야 보인다. 논리명으로는 들어가지 않는다 |
| 인라인 `REFERENCES`, `98_foreign_keys.sql` 의 `ALTER TABLE` | `CONSTRAINT ... FOREIGN KEY` | 관계선 생성 |
| `CREATE UNIQUE INDEX` | `UNIQUE KEY` | |
| `INSERT`, 트리거, 함수 | 제외 | ERD 무관 |

- 코멘트는 컬럼 주석의 괄호 앞 부분만 사용한다. 예: `'전체 출고보류 (null=정상, 1=보류)'` → `전체 출고보류`
- 주석이 없는 공통 컬럼(감사, 취소, 삭제 등)은 스크립트 안의 `DEFAULT_LOGICAL` 사전으로 채운다.
- 테이블·컬럼 논리명은 가져오기로 채워지지 않는다. 테이블 논리명은 ERDCloud에서 직접 입력한다 (컬럼 논리명은 물리명 그대로 둔다)
- 참조되는 테이블이 먼저 나오도록 정렬한다 (order → product 순서 문제 해결).
