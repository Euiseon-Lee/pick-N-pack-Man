```
BaseTimeEntity
  ├── createdAt
  └── updatedAt
      ↑ 상속
BaseEntity
  ├── createdAt       ← BaseTimeEntity에서
  ├── updatedAt       ← BaseTimeEntity에서
  ├── createdUserId   ← 여기서 추가
  └── updatedUserId   ← 여기서 추가
      ↑ 상속
ProductMaster         → 4개 컬럼 모두 포함

```