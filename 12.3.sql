CREATE TABLE order_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    old_status ENUM('Pending', 'Completed', 'Cancelled'),
    new_status ENUM('Pending', 'Completed', 'Cancelled'),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

DELIMITER //

CREATE TRIGGER before_insert_check_payment
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE v_total_amount DECIMAL(10,2);
    SELECT total_amount INTO v_total_amount 
    FROM orders 
    WHERE order_id = NEW.order_id;
    IF NEW.amount <> v_total_amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Thất bại: Số tiền thanh toán không khớp với tổng tiền của đơn hàng!';
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER after_update_order_status
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO order_logs (order_id, old_status, new_status)
        VALUES (OLD.order_id, OLD.status, NEW.status);
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE sp_update_order_status_with_payment(
    IN p_order_id INT,
    IN p_new_status ENUM('Pending', 'Completed', 'Cancelled'), 
    IN p_payment_amount DECIMAL(10,2), 
    IN p_payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer', 'Cash')
)
BEGIN
    DECLARE v_current_status ENUM('Pending', 'Completed', 'Cancelled'); 
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK; 
        SELECT 'Thất bại: Lỗi hệ thống hoặc Trigger chặn thao tác. Giao dịch bị hủy!' AS Status;
    END;

    START TRANSACTION;

    SELECT status INTO v_current_status 
    FROM orders 
    WHERE order_id = p_order_id FOR UPDATE;

    IF v_current_status IS NULL THEN
        ROLLBACK;
        SELECT 'Thất bại: Đơn hàng không tồn tại!' AS Status;

    ELSEIF v_current_status = p_new_status THEN
        ROLLBACK; 
        SELECT 'Thất bại: Đơn hàng đã ở trạng thái này rồi, không cần cập nhật!' AS Status;

    ELSE
        IF p_new_status = 'Completed' THEN
            INSERT INTO payments (order_id, amount, payment_method, status)
            VALUES (p_order_id, p_payment_amount, p_payment_method, 'Completed');
        END IF;
        UPDATE orders 
        SET status = p_new_status
        WHERE order_id = p_order_id;

        COMMIT; 
        SELECT 'Thành công: Cập nhật đơn hàng và xử lý thanh toán hoàn tất!' AS Status;
    END IF;
END //

DELIMITER ;

INSERT INTO customers (customer_id, name, email) VALUES (1, 'Nguyen Van A', 'a@gmail.com');

INSERT INTO products (product_id, name, price) VALUES (1, 'Tai nghe Bluetooth', 500000.00);

INSERT INTO inventory (product_id, stock_quantity) VALUES (1, 10);

CALL sp_create_order(1, 1, 2, 500000.00); 

CALL sp_update_order_status_with_payment(1, 'Completed', 900000.00, 'Cash');

CALL sp_update_order_status_with_payment(1, 'Completed', 1000000.00, 'Cash');

SELECT * FROM order_logs;

DROP TRIGGER IF EXISTS before_insert_check_payment;
DROP TRIGGER IF EXISTS after_update_order_status;
DROP PROCEDURE IF EXISTS sp_update_order_status_with_payment;