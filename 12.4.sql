DELIMITER //

DROP TRIGGER IF EXISTS before_insert_employee_email //

CREATE TRIGGER before_insert_employee_email
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF NEW.email NOT LIKE '%@company.com' THEN
        SET NEW.email = CONCAT(NEW.email, '@company.com');
    END IF;
END //

DELIMITER ;

DELIMITER //

DROP TRIGGER IF EXISTS after_insert_employee_salary //

CREATE TRIGGER after_insert_employee_salary
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO salaries (employee_id, base_salary, bonus)
    VALUES (NEW.employee_id, 10000.00, 0.00);
END //

DELIMITER ;

DELIMITER //

DROP TRIGGER IF EXISTS before_update_attendance_hours //

CREATE TRIGGER before_update_attendance_hours
BEFORE UPDATE ON attendance
FOR EACH ROW
BEGIN
    IF NEW.check_out_time IS NOT NULL AND (OLD.check_out_time IS NULL OR OLD.check_out_time <> NEW.check_out_time) THEN
        SET NEW.total_hours = TIMESTAMPDIFF(MINUTE, NEW.check_in_time, NEW.check_out_time) / 60.0;
    END IF;
END //

DELIMITER ;

INSERT INTO departments (department_name) VALUES ('Phòng Công Nghệ');
INSERT INTO employees (name, email, phone, hire_date, department_id)
VALUES ('Nguyen Van A', 'anv', '0901234567', '2026-07-17', 1);
INSERT INTO employees (name, email, phone, hire_date, department_id)
VALUES ('Tran Thi B', 'btt@company.com', '0907654321', '2026-07-17', 1);

SELECT * FROM employees;
SELECT * FROM salaries;
   
   INSERT INTO attendance (employee_id, check_in_time) 
VALUES (1, '2026-07-17 08:00:00');

UPDATE attendance 
SET check_out_time = '2026-07-17 17:30:00' 
WHERE employee_id = 1;

SELECT * FROM attendance;

DROP TRIGGER IF EXISTS before_insert_employee_email;
DROP TRIGGER IF EXISTS after_insert_employee_salary;
DROP TRIGGER IF EXISTS before_update_attendance_hours;