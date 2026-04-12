package com.picknpack.product.repository;

import com.picknpack.product.entity.ProductMaster;
import org.springframework.data.jpa.repository.JpaRepository;

/** Repository
 *  Repository = DB 조회/저장 담당 → Entity를 DB에 넣고 꺼내는 역할
 * <p>
 *  extends JpaRepository<{entity}, {PK 타입}> = JPA가 자동으로 구현체를 생성
 * <p>
 *  메서드 이름 규칙:
 *  findBy + 컬럼명                    → WHERE 컬럼 = ?
 *  findBy + 컬럼명 + Containing      → WHERE 컬럼 LIKE '%?%'
 *  findBy + 컬럼명 + OrderBy + 컬럼명 → WHERE ... ORDER BY ...
 *  countBy + 컬럼명                   → SELECT COUNT(*) WHERE 컬럼 = ?
 *  existsBy + 컬럼명                  → 존재 여부 boolean
 */
public interface ProductMasterRepository extends JpaRepository<ProductMaster, Long> {
}
