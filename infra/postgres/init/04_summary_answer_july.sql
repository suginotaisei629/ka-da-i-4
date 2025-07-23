-- 模範回答サマリテーブル（2025年7月分）
CREATE TABLE IF NOT EXISTS summary_answer_july (
    employee_id INTEGER PRIMARY KEY,
    year_month CHAR(7),
    total_salary INTEGER
);

INSERT INTO summary_answer_july (employee_id, year_month, total_salary) VALUES
    (1, '2025-07', 374800),
    (2, '2025-07', 364760),
    (3, '2025-07', 439320)
ON CONFLICT (employee_id) DO UPDATE SET year_month=EXCLUDED.year_month, total_salary=EXCLUDED.total_salary;
