CREATE OR REPLACE PROCEDURE calculate_monthly_salary_summary(target_year_month CHAR(7))
LANGUAGE plpgsql
AS
$$
DECLARE
    cur_emp CURSOR FOR
        SELECT DISTINCT employee_id FROM work_records
        WHERE to_char(work_date, 'YYYY-MM') = target_year_month;

    rec_emp RECORD;

    v_work_hours_weekday_day NUMERIC := 0;
    v_work_hours_weekday_night NUMERIC := 0;
    v_work_hours_holiday_day NUMERIC := 0;
    v_work_hours_holiday_night NUMERIC := 0;

    v_salary_weekday_day NUMERIC := 0;
    v_salary_weekday_night NUMERIC := 0;
    v_salary_holiday_day NUMERIC := 0;
    v_salary_holiday_night NUMERIC := 0;

    v_total_salary NUMERIC := 0;

    emp_hourly_wage NUMERIC;
    emp_night_shift_rate NUMERIC;
    emp_holiday_rate NUMERIC;

BEGIN
    -- 1. 再帰CTEで指定月の全日付を生成し、一時テーブルに格納
    EXECUTE format('
        DROP TABLE IF EXISTS temp_dates;
        CREATE TEMP TABLE temp_dates AS
        WITH RECURSIVE dates AS (
            SELECT date_trunc(''month'', DATE %L::date) AS day
            UNION ALL
            SELECT day + INTERVAL ''1 day''
            FROM dates
            WHERE day + INTERVAL ''1 day'' < (date_trunc(''month'', DATE %L::date) + INTERVAL ''1 month'')
        )
        SELECT day::date AS work_date,
               EXTRACT(ISODOW FROM day) AS day_of_week
        FROM dates;
    ', target_year_month || '-01', target_year_month || '-01');

    -- 5. カーソルで従業員ごとにループ
    FOR rec_emp IN cur_emp LOOP
        v_work_hours_weekday_day := 0;
        v_work_hours_weekday_night := 0;
        v_work_hours_holiday_day := 0;
        v_work_hours_holiday_night := 0;

        v_salary_weekday_day := 0;
        v_salary_weekday_night := 0;
        v_salary_holiday_day := 0;
        v_salary_holiday_night := 0;

        v_total_salary := 0;

        SELECT hourly_wage, night_shift_rate, holiday_rate
        INTO emp_hourly_wage, emp_night_shift_rate, emp_holiday_rate
        FROM employees
        WHERE employee_id = rec_emp.employee_id;

        FOR rec IN
            SELECT wr.work_date, wr.shift, wr.hours_worked,
                   CASE 
                     WHEN h.work_date IS NOT NULL THEN TRUE
                     WHEN EXTRACT(ISODOW FROM wr.work_date) IN (6,7) THEN TRUE
                     ELSE FALSE
                   END AS is_holiday
            FROM work_records wr
            LEFT JOIN holidays h ON wr.work_date = h.work_date
            WHERE wr.employee_id = rec_emp.employee_id
              AND to_char(wr.work_date, 'YYYY-MM') = target_year_month
        LOOP
            IF rec.is_holiday THEN
                IF rec.shift = '昼勤' THEN
                    v_work_hours_holiday_day := v_work_hours_holiday_day + rec.hours_worked;
                    v_salary_holiday_day := v_salary_holiday_day + FLOOR(rec.hours_worked * emp_hourly_wage * emp_holiday_rate);
                ELSE
                    v_work_hours_holiday_night := v_work_hours_holiday_night + rec.hours_worked;
                    v_salary_holiday_night := v_salary_holiday_night + FLOOR(rec.hours_worked * emp_hourly_wage * emp_holiday_rate * emp_night_shift_rate);
                END IF;
            ELSE
                IF rec.shift = '昼勤' THEN
                    v_work_hours_weekday_day := v_work_hours_weekday_day + rec.hours_worked;
                    v_salary_weekday_day := v_salary_weekday_day + FLOOR(rec.hours_worked * emp_hourly_wage);
                ELSE
                    v_work_hours_weekday_night := v_work_hours_weekday_night + rec.hours_worked;
                    v_salary_weekday_night := v_salary_weekday_night + FLOOR(rec.hours_worked * emp_hourly_wage * emp_night_shift_rate);
                END IF;
            END IF;
        END LOOP;

        v_total_salary := v_salary_weekday_day + v_salary_weekday_night + v_salary_holiday_day + v_salary_holiday_night;

        INSERT INTO monthly_salary_summary(employee_id, year_month, total_salary)
        VALUES (rec_emp.employee_id, target_year_month, v_total_salary)
        ON CONFLICT (employee_id, year_month)
        DO UPDATE SET total_salary = EXCLUDED.total_salary;

    END LOOP;
END;
$$;
