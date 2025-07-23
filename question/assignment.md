# Practice 04: 工場作業員の給与計算ストアドプロシージャ

## 目的

工場の作業員について、勤務実績・割増賃金・祝日を考慮し、指定した月の従業員ごとの給与サマリテーブルを作成するストアドプロシージャを作成してください。

## 前提
- 作業員ごとに工数単価（hourly_wage）、夜勤割増率（night_shift_rate）、休日割増率（holiday_rate）が異なります。
- 勤務実績（work_records）は日付・シフト（昼勤/夜勤）・工数（hours_worked）を持ちます。
- 土日・祝日（holidays）は休日とし、休日出勤には割増賃金が支払われます。
- 夜勤も割増賃金が支払われます。
- 今回、2025年分のテストデータを準備しています。

## 手順

1. 指定した月の全日付・曜日情報を再帰CTEで生成し、一時テーブルに格納してください。
2. 各勤務実績について、
    - 平日昼勤は基本単価
    - 平日夜勤は夜勤割増
    - 休日（祝日・土日）昼勤は休日割増
    - 休日夜勤は休日割増×夜勤割増
   を適用して給与を計算してください。
3. 従業員ごとにその月の給与合計を集計し、`monthly_salary_summary`テーブルに格納してください。
4. ストアドプロシージャ名は `calculate_monthly_salary_summary(target_year_month CHAR(7))` としてください。
5. カーソル（cursor）を利用して従業員ごとに処理を行う実装としてください。
6. 各従業員ごと(=カーソルでのループごと)に、作業時間・給与・割増ごとの内訳（平日昼勤、平日夜勤、休日昼勤、休日夜勤）をログ出力（RAISE NOTICE等）してください。
7. ループ処理全体をトランザクションで囲むようにしてください（明示的なBEGIN/COMMIT/ROLLBACK）。

## 期待する出力

- `monthly_salary_summary` テーブルに、従業員ID・年月・合計給与が格納されること。
- テストデータ（2025年7月）で正しく集計されること。
- ログに従業員ごとの作業時間・給与・割増ごとの内訳が出力されること。
- トランザクション制御が正しく行われていること。

---

## 模範回答サマリテーブルとの一致判定方法

模範回答サマリテーブル（例: `summary_answer_july`）を用意し、あなたの集計結果（`monthly_salary_summary`）と一致するかを以下のクエリで判定できます。

### OK/NG判定クエリ例

```sql
-- NGが0件ならOK、1件以上ならNG
SELECT
  CASE
    WHEN (
      SELECT COUNT(*) FROM (
        SELECT * FROM monthly_salary_summary WHERE year_month = '2025-07'
        EXCEPT
        SELECT * FROM summary_answer_july
      ) AS diff1
    ) +
    (
      SELECT COUNT(*) FROM (
        SELECT * FROM summary_answer_july
        EXCEPT
        SELECT * FROM monthly_salary_summary WHERE year_month = '2025-07'
      ) AS diff2
    ) = 0
    THEN 'OK'
    ELSE 'NG'
  END AS result;
```

### 差分調査用クエリ

```sql
-- あなたの集計結果にしかない行
SELECT * FROM monthly_salary_summary WHERE year_month = '2025-07'
EXCEPT
SELECT * FROM summary_answer_july;

-- 模範回答にしかない行
SELECT * FROM summary_answer_july
EXCEPT
SELECT * FROM monthly_salary_summary WHERE year_month = '2025-07';
```

> EXCEPT句を使うことで、差分の詳細調査が可能です。
