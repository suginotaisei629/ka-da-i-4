CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    hourly_wage INTEGER NOT NULL, -- 基本単価（円/時）
    night_shift_rate NUMERIC(4,2) NOT NULL DEFAULT 1.25, -- 夜勤割増率
    holiday_rate NUMERIC(4,2) NOT NULL DEFAULT 1.35 -- 休日割増率
);

-- 勤務実績
CREATE TABLE work_records (
    work_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
    work_date DATE NOT NULL,
    shift_type VARCHAR(10) NOT NULL CHECK (shift_type IN ('day', 'night')),
    hours_worked NUMERIC(4,2) NOT NULL
);

-- 2025年祝日マスタ
CREATE TABLE holidays (
    holiday_date DATE PRIMARY KEY,
    holiday_name VARCHAR(50) NOT NULL
);

-- 月次給与サマリ（ストアドプロシージャで作成）
CREATE TABLE monthly_salary_summary (
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
    year_month CHAR(7) NOT NULL, -- 例: '2025-07'
    total_salary INTEGER NOT NULL,
    PRIMARY KEY (employee_id, year_month)
);
