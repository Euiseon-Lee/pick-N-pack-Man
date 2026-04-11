-- ============================================
-- updated_at 자동 갱신 트리거 적용
-- ============================================

-- common_code
CREATE TRIGGER trg_common_code_updated_at BEFORE UPDATE ON common_code
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- order_master
CREATE TRIGGER trg_order_master_updated_at BEFORE UPDATE ON order_master
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- order_item
CREATE TRIGGER trg_order_item_updated_at BEFORE UPDATE ON order_item
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- product_master
CREATE TRIGGER trg_product_master_updated_at BEFORE UPDATE ON product_master
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- product_option
CREATE TRIGGER trg_product_option_updated_at BEFORE UPDATE ON product_option
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- product_item
CREATE TRIGGER trg_product_item_updated_at BEFORE UPDATE ON product_item
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- inventory
CREATE TRIGGER trg_inventory_updated_at BEFORE UPDATE ON inventory
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- shipment_master
CREATE TRIGGER trg_shipment_master_updated_at BEFORE UPDATE ON shipment_master
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- shipment_item
CREATE TRIGGER trg_shipment_item_updated_at BEFORE UPDATE ON shipment_item
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- cs_category
CREATE TRIGGER trg_cs_category_updated_at BEFORE UPDATE ON cs_category
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- cs_claim_code
CREATE TRIGGER trg_cs_claim_code_updated_at BEFORE UPDATE ON cs_claim_code
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- cs_history
CREATE TRIGGER trg_cs_history_updated_at BEFORE UPDATE ON cs_history
FOR EACH ROW EXECUTE FUNCTION update_updated_at();
