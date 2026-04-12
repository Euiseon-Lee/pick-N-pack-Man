package com.picknpack.common.entity;

import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;

@Getter
@MappedSuperclass       // 이 클래스는 직접 테이블이 되지 않고, 다른 Entity의 부모로만 사용된다는 의미 (상속의 대상)
public abstract class BaseEntity extends BaseTimeEntity {      // abstract = 이 클래스는 반드시 상속해서 써야 한다는 의미

    @Setter
    @Column(name = "created_user_id", nullable = false, length = 100)
    private String createdUserId = "SYSTEM";

    @Setter
    @Column(name = "updated_user_id", length = 100)
    private String updatedUserId;

}
