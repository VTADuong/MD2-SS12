DELIMITER //

CREATE PROCEDURE sp_create_order(
    IN p_customer_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_price DECIMAL(10,2)
)
BEGIN
    DECLARE v_stock INT;
    DECLARE v_order_id INT;
    DECLARE v_total_amount DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Thất bại: Lỗi hệ thống bất ngờ khi tạo đơn!' AS `Status`;
    END;

    START TRANSACTION;
    SELECT stock_quantity INTO v_stock 
    FROM inventory 
    WHERE product_id = p_product_id FOR UPDATE;

    IF v_stock IS NULL OR v_stock < p_quantity THEN
        ROLLBACK;
        SELECT 'Thất bại: Số lượng hàng tồn kho không đủ!' AS `Status`;
    ELSE
        SET v_total_amount = p_price * p_quantity;
        INSERT INTO orders (customer_id, total_amount, status)
        VALUES (p_customer_id, v_total_amount, 'Pending');
        SET v_order_id = LAST_INSERT_ID();
        INSERT INTO order_items (order_id, product_id, quantity, price)
        VALUES (v_order_id, p_product_id, p_quantity, p_price);
        UPDATE inventory 
        SET stock_quantity = stock_quantity - p_quantity
        WHERE product_id = p_product_id;
        COMMIT;
        SELECT 'Thành công: Tạo đơn hàng hoàn tất!' AS `Status`, v_order_id AS `New_Order_ID`;
    END IF;
END //

DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_pay_order(
    IN p_order_id INT,
    IN p_payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer', 'Cash')
)
BEGIN
    DECLARE v_status ENUM('Pending', 'Completed', 'Cancelled');
    DECLARE v_amount DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Thất bại: Lỗi hệ thống bất ngờ khi thanh toán!' AS `Status`;
    END;

    START TRANSACTION;
    SELECT status, total_amount INTO v_status, v_amount 
    FROM orders 
    WHERE order_id = p_order_id FOR UPDATE;
    IF v_status IS NULL OR v_status <> 'Pending' THEN
        ROLLBACK;
        SELECT 'Thất bại: Đơn hàng không ở trạng thái Chờ thanh toán (Pending)!' AS `Status`;
    ELSE
        INSERT INTO payments (order_id, amount, payment_method, status)
        VALUES (p_order_id, v_amount, p_payment_method, 'Completed');
        UPDATE orders 
        SET status = 'Completed'
        WHERE order_id = p_order_id;
        COMMIT;
        SELECT 'Thành công: Thanh toán đơn hàng hoàn tất!' AS `Status`;
    END IF;
END //

DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_cancel_order(
    IN p_order_id INT
)
BEGIN
    DECLARE v_status ENUM('Pending', 'Completed', 'Cancelled');
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    
    DECLARE cur_items CURSOR FOR 
        SELECT product_id, quantity FROM order_items WHERE order_id = p_order_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Thất bại: Lỗi hệ thống bất ngờ khi hủy đơn!' AS `Status`;
    END;
    
    START TRANSACTION;
    SELECT status INTO v_status FROM orders WHERE order_id = p_order_id FOR UPDATE;
    IF v_status IS NULL OR v_status <> 'Pending' THEN
        ROLLBACK;
        SELECT 'Thất bại: Chỉ có thể hủy đơn hàng đang ở trạng thái Pending!' AS `Status`;
    ELSE
        OPEN cur_items;
        read_loop: LOOP
            FETCH cur_items INTO v_product_id, v_quantity;
            IF done THEN
                LEAVE read_loop;
            END IF;
            
            UPDATE inventory 
            SET stock_quantity = stock_quantity + v_quantity
            WHERE product_id = v_product_id;
        END LOOP;
        CLOSE cur_items;
        DELETE FROM order_items WHERE order_id = p_order_id;
        UPDATE orders 
        SET status = 'Cancelled'
        WHERE order_id = p_order_id;
        COMMIT;
        SELECT 'Thành công: Hủy đơn hàng và hoàn trả kho hoàn tất!' AS `Status`;
    END IF;
END //

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_create_order;
DROP PROCEDURE IF EXISTS sp_pay_order;
DROP PROCEDURE IF EXISTS sp_cancel_order;