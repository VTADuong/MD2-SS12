ALTER TABLE salary_history DROP FOREIGN KEY salary_history_ibfk_1;

ALTER TABLE salary_history 
MODIFY employee_id INT NULL,
ADD CONSTRAINT fk_salary_history_employee 
FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL;

DELIMITER //

CREATE PROCEDURE IncreaseSalary(
    IN p_emp_id INT, 
    IN p_new_salary DECIMAL(10,2),
    IN p_reason TEXT  
)
BEGIN
    DECLARE v_old_salary DECIMAL(10,2); 

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Thất bại: Lỗi hệ thống bất ngờ khi tăng lương!' AS Status;
    END;

    START TRANSACTION;

    SELECT base_salary INTO v_old_salary 
    FROM salaries 
    WHERE employee_id = p_emp_id FOR UPDATE;

    IF v_old_salary IS NULL THEN
        ROLLBACK; 
        SELECT 'Thất bại: Nhân viên không tồn tại trong hệ thống!' AS Status;
    ELSE
        UPDATE salaries 
        SET base_salary = p_new_salary
        WHERE employee_id = p_emp_id;
        INSERT INTO salary_history (employee_id, old_salary, new_salary, reason)
        VALUES (p_emp_id, v_old_salary, p_new_salary, p_reason);

        COMMIT; 
        SELECT 'Thành công: Cập nhật lương và lịch sử lương hoàn tất!' AS Status;
    END IF;
END //

DELIMITER ;

DELIMITER //

DROP PROCEDURE IF EXISTS DeleteEmployee //

CREATE PROCEDURE DeleteEmployee(
    IN p_emp_id INT 
)
BEGIN
    DECLARE v_emp_exists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Thất bại: Lỗi hệ thống bất ngờ khi xóa nhân viên!' AS Status;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_emp_exists 
    FROM employees 
    WHERE employee_id = p_emp_id FOR UPDATE;

    IF v_emp_exists = 0 THEN
        ROLLBACK; 
        SELECT 'Thất bại: Nhân viên không tồn tại trong hệ thống!' AS Status;
    ELSE
        
        DELETE FROM employees WHERE employee_id = p_emp_id;

        COMMIT; 
        SELECT 'Thành công: Nhân viên đã bị xóa khỏi hệ thống!' AS Status;
    END IF;
END //

DELIMITER ;

CALL IncreaseSalary(1, 15000.00, 'Tăng lương định kỳ do đạt KPI xuất sắc');
CALL DeleteEmployee(1);
SELECT * FROM employees WHERE employee_id = 1;
SELECT * FROM salaries WHERE employee_id = 1;
SELECT * FROM salary_history;