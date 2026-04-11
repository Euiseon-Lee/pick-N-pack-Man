-- ============================================
-- updated_at 자동 갱신 트리거 함수
-- PostgreSQL에는 MySQL의 ON UPDATE CURRENT_TIMESTAMP가 없으므로
-- 트리거로 구현
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
