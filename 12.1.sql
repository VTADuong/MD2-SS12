DELIMITER //
CREATE TRIGGER trg_order_items_before_insert
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
	DECLARE v_stock INT;
    SELECT stock_quantity INTO v_stock 
    FROM inventory 
    WHERE product_id = NEW.product_id;
    
    IF v_stock IS NULL OR v_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Thất bại: Số lượng hàng tồn kho không đủ!';
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_order_items_after_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE orders 
    SET total_amount = total_amount + (NEW.price * NEW.quantity)
    WHERE order_id = NEW.order_id;

    UPDATE inventory 
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_order_items_before_update
BEFORE UPDATE ON order_items
FOR EACH ROW
BEGIN
    DECLARE v_stock INT;

    SELECT stock_quantity INTO v_stock 
    FROM inventory 
    WHERE product_id = NEW.product_id;

    IF v_stock IS NULL OR (v_stock + OLD.quantity) < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Thất bại: Cập nhật không thành công do kho không đủ hàng!';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_order_items_after_update
AFTER UPDATE ON order_items
FOR EACH ROW
BEGIN
    UPDATE orders 
    SET total_amount = total_amount - (OLD.price * OLD.quantity) + (NEW.price * NEW.quantity)
    WHERE order_id = NEW.order_id;
    
    UPDATE inventory 
    SET stock_quantity = stock_quantity + OLD.quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_orders_before_delete
BEFORE DELETE ON orders
FOR EACH ROW
BEGIN
    IF OLD.status = 'Completed' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Thất bại: Không thể xóa đơn hàng đã hoàn thành (Completed)!';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_order_items_after_delete
AFTER DELETE ON order_items
FOR EACH ROW
BEGIN

    UPDATE inventory 
    SET stock_quantity = stock_quantity + OLD.quantity
    WHERE product_id = OLD.product_id;
    
    UPDATE orders 
    SET total_amount = total_amount - (OLD.price * OLD.quantity)
    WHERE order_id = OLD.order_id;
END //
DELIMITER ;