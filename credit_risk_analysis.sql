


CREATE TABLE credit_risk (
    id VARCHAR(30),
    loan_amnt NUMERIC(12,2),
    term VARCHAR(30),
    int_rate NUMERIC(8,4),
    installment NUMERIC(12,2),
    grade VARCHAR(5),
    sub_grade VARCHAR(10),
    emp_length VARCHAR(30),
    home_ownership VARCHAR(30),
    annual_inc NUMERIC(14,2),
    verification_status VARCHAR(50),
    purpose VARCHAR(100),
    dti NUMERIC(10,4),
    delinq_2yrs NUMERIC(10,2),
    fico_range_low NUMERIC(10,2),
    fico_range_high NUMERIC(10,2),
    open_acc NUMERIC(10,2),
    pub_rec NUMERIC(10,2),
    revol_bal NUMERIC(14,2),
    revol_util NUMERIC(10,4),
    total_acc NUMERIC(10,2),
    loan_status VARCHAR(100),
    risk_status VARCHAR(20)
);


SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = 'credit_risk';



SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Non-Default'
    ) AS non_default_loans,

    ROUND(
        COUNT(*) FILTER (
            WHERE risk_status = 'Default'
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct

FROM public.credit_risk;


---Loan Grade vs Default Risk Analysis 


SELECT
    grade,
    COUNT(*) AS total_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    ROUND(
        COUNT(*) FILTER (
            WHERE risk_status = 'Default'
        ) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,

    ROUND(AVG(int_rate), 2) AS avg_interest_rate

FROM public.credit_risk
GROUP BY grade
ORDER BY default_rate_pct DESC;


---Interest Rate Band vs Default Risk


SELECT
    CASE
        WHEN int_rate < 8 THEN '0-8%'
        WHEN int_rate < 12 THEN '8-12%'
        WHEN int_rate < 16 THEN '12-16%'
        WHEN int_rate < 20 THEN '16-20%'
        ELSE '20%+'
    END AS interest_rate_band,

    COUNT(*) AS total_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    ROUND(
        COUNT(*) FILTER (
            WHERE risk_status = 'Default'
        ) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM public.credit_risk
WHERE int_rate IS NOT NULL
GROUP BY 1
ORDER BY
    MIN(int_rate);

---DTI Band vs Default Risk


SELECT
    CASE
        WHEN dti < 10 THEN '0-10'
        WHEN dti < 20 THEN '10-20'
        WHEN dti < 30 THEN '20-30'
        WHEN dti < 40 THEN '30-40'
        ELSE '40+'
    END AS dti_band,

    COUNT(*) AS total_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    ROUND(
        COUNT(*) FILTER (
            WHERE risk_status = 'Default'
        ) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM public.credit_risk
WHERE dti IS NOT NULL
GROUP BY 1
ORDER BY MIN(dti);

---FICO Score Band vs Default Risk


WITH fico_data AS (
    SELECT
        (
            fico_range_low + fico_range_high
        ) / 2.0 AS avg_fico,
        loan_amnt,
        risk_status
    FROM public.credit_risk
    WHERE fico_range_low IS NOT NULL
      AND fico_range_high IS NOT NULL
),
fico_bands AS (
    SELECT
        CASE
            WHEN avg_fico < 580 THEN 'Below 580'
            WHEN avg_fico < 670 THEN '580-669'
            WHEN avg_fico < 740 THEN '670-739'
            WHEN avg_fico < 800 THEN '740-799'
            ELSE '800+'
        END AS fico_band,
        avg_fico,
        loan_amnt,
        risk_status
    FROM fico_data
)
SELECT
    fico_band,
    COUNT(*) AS total_loans,
    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,
    ROUND(
        COUNT(*) FILTER (
            WHERE risk_status = 'Default'
        ) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount
FROM fico_bands
GROUP BY fico_band
ORDER BY
    CASE fico_band
        WHEN 'Below 580' THEN 1
        WHEN '580-669' THEN 2
        WHEN '670-739' THEN 3
        WHEN '740-799' THEN 4
        WHEN '800+' THEN 5
    END;

---Loan Purpose vs Default Risk


SELECT
    purpose,
    COUNT(*) AS total_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    ROUND(
        COUNT(*) FILTER (
            WHERE risk_status = 'Default'
        ) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM public.credit_risk
GROUP BY purpose
ORDER BY default_rate_pct DESC;

---Employment Length vs Default Risk


SELECT
    emp_length,
    COUNT(*) AS total_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    ROUND(
        COUNT(*) FILTER (
            WHERE risk_status = 'Default'
        ) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM public.credit_risk
GROUP BY emp_length
ORDER BY default_rate_pct DESC;

---Overall Credit Risk Summary


SELECT
    COUNT(*) AS total_resolved_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS total_defaults,

    COUNT(*) FILTER (
        WHERE risk_status = 'Non-Default'
    ) AS total_non_defaults,

    ROUND(
        COUNT(*) FILTER (
            WHERE risk_status = 'Default'
        ) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,

    ROUND(AVG(int_rate), 2) AS avg_interest_rate,

    ROUND(AVG(annual_inc), 2) AS avg_annual_income,

    ROUND(AVG(dti), 2) AS avg_dti

FROM public.credit_risk;



CREATE OR REPLACE VIEW vw_credit_risk_overview AS
SELECT
    COUNT(*) AS total_resolved_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS total_defaults,

    COUNT(*) FILTER (
        WHERE risk_status = 'Non-Default'
    ) AS total_non_defaults,

    ROUND(
        COUNT(*) FILTER (
            WHERE risk_status = 'Default'
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(int_rate), 2) AS avg_interest_rate,
    ROUND(AVG(annual_inc), 2) AS avg_annual_income,
    ROUND(AVG(dti), 2) AS avg_dti

FROM public.credit_risk;


SELECT * FROM public.vw_credit_risk_overview;



CREATE OR REPLACE VIEW vw_credit_risk_by_grade AS
SELECT
    grade,
    COUNT(*) AS total_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    ROUND(
        COUNT(*) FILTER (
            WHERE risk_status = 'Default'
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(int_rate), 2) AS avg_interest_rate

FROM public.credit_risk
GROUP BY grade;





SELECT *
FROM public.vw_credit_risk_by_grade
ORDER BY grade;


CREATE OR REPLACE VIEW vw_credit_risk_by_interest_rate AS
SELECT
    CASE
        WHEN int_rate < 8 THEN '0-8%'
        WHEN int_rate < 12 THEN '8-12%'
        WHEN int_rate < 16 THEN '12-16%'
        WHEN int_rate < 20 THEN '16-20%'
        ELSE '20%+'
    END AS interest_rate_band,

    COUNT(*) AS total_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    ROUND(
        COUNT(*) FILTER (WHERE risk_status = 'Default') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM public.credit_risk
GROUP BY 1;




SELECT *
FROM public.vw_credit_risk_by_interest_rate
ORDER BY
    CASE interest_rate_band
        WHEN '0-8%' THEN 1
        WHEN '8-12%' THEN 2
        WHEN '12-16%' THEN 3
        WHEN '16-20%' THEN 4
        WHEN '20%+' THEN 5
    END;


CREATE OR REPLACE VIEW vw_credit_risk_by_dti AS
SELECT
    CASE
        WHEN dti < 10 THEN '0-10'
        WHEN dti < 20 THEN '10-20'
        WHEN dti < 30 THEN '20-30'
        WHEN dti < 40 THEN '30-40'
        ELSE '40+'
    END AS dti_band,

    COUNT(*) AS total_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    ROUND(
        COUNT(*) FILTER (WHERE risk_status = 'Default') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM public.credit_risk
WHERE dti IS NOT NULL
GROUP BY 1;




SELECT *
FROM public.vw_credit_risk_by_dti
ORDER BY
    CASE dti_band
        WHEN '0-10' THEN 1
        WHEN '10-20' THEN 2
        WHEN '20-30' THEN 3
        WHEN '30-40' THEN 4
        WHEN '40+' THEN 5
    END;


CREATE OR REPLACE VIEW vw_credit_risk_by_fico AS
SELECT
    CASE
        WHEN (fico_range_low + fico_range_high) / 2 < 670
            THEN '580-669'
        WHEN (fico_range_low + fico_range_high) / 2 < 740
            THEN '670-739'
        WHEN (fico_range_low + fico_range_high) / 2 < 800
            THEN '740-799'
        ELSE '800+'
    END AS fico_band,

    COUNT(*) AS total_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    ROUND(
        COUNT(*) FILTER (WHERE risk_status = 'Default') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM public.credit_risk
WHERE fico_range_low IS NOT NULL
  AND fico_range_high IS NOT NULL
GROUP BY 1;


SELECT *
FROM public.vw_credit_risk_by_fico
ORDER BY
    CASE fico_band
        WHEN '580-669' THEN 1
        WHEN '670-739' THEN 2
        WHEN '740-799' THEN 3
        WHEN '800+' THEN 4
    END;



CREATE OR REPLACE VIEW vw_credit_risk_by_purpose AS
SELECT
    purpose,
    COUNT(*) AS total_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    ROUND(
        COUNT(*) FILTER (WHERE risk_status = 'Default') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM public.credit_risk
WHERE purpose IS NOT NULL
GROUP BY purpose;


SELECT *
FROM public.vw_credit_risk_by_purpose
ORDER BY default_rate_pct DESC;


CREATE OR REPLACE VIEW vw_credit_risk_by_employment AS
SELECT
    emp_length,
    COUNT(*) AS total_loans,

    COUNT(*) FILTER (
        WHERE risk_status = 'Default'
    ) AS default_loans,

    ROUND(
        COUNT(*) FILTER (WHERE risk_status = 'Default') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount

FROM public.credit_risk
GROUP BY emp_length;


SELECT *
FROM public.vw_credit_risk_by_employment
ORDER BY default_rate_pct DESC;



SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name LIKE 'vw_credit_risk%'
ORDER BY table_name;















































