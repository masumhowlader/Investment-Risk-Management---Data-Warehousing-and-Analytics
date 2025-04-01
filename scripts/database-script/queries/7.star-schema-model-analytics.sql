/* Formatted on 3/28/2025 5:44:19 AM (QP5 v5.360) */
--1. Portfolio Overview
--A. Portfolio Composition

  SELECT ds.sector_name,
         dcc.CL_DESCRIPTION              AS loan_type,
         dc.status_name                  AS risk_status,
         COUNT (*)                       AS loan_count,
         SUM (ff.outstanding_balance)    AS exposure,
         ROUND (
               SUM (ff.outstanding_balance)
             / (SELECT SUM (outstanding_balance) FROM FACT_FINANCING)
             * 100,
             2)                          AS portfolio_percentage
    FROM FACT_FINANCING ff
         JOIN DIM_SECTOR ds ON ff.sector_id = ds.sector_id
         JOIN DIM_CL_CATEGORY dcc ON ff.CL_CATEGORY_ID = dcc.CL_CATEGORY_ID
         JOIN DIM_CLASSIFICATION dc ON ff.CL_STATUS = dc.status_code
GROUP BY ds.sector_name, dcc.CL_DESCRIPTION, dc.status_name
ORDER BY exposure DESC;

--B. Performing vs Non-Performing

  SELECT CASE
             WHEN dc.is_performing = 1 THEN 'Performing'
             ELSE 'Non-Performing'
         END                             AS performance_category,
         --dc.status_name,
         SUM (ff.outstanding_balance)    AS amount
    FROM FACT_FINANCING ff
         JOIN DIM_CLASSIFICATION dc ON ff.cl_status = dc.status_code
GROUP BY dc.is_performing;                          --, dc.status_name;

--2. Risk Concentration
--A. Top 20 Borrower Exposure
  SELECT c.customer_name,
         c.RISK_LEVEL                      customer_risk_level,
         SUM (ff.outstanding_balance)      AS total_exposure,
         SUM (
             CASE
                 WHEN dc.is_performing = 0 THEN ff.outstanding_balance
                 ELSE 0
             END)                          AS npl_exposure,
           ROUND(SUM (
               CASE
                   WHEN dc.is_performing = 0 THEN ff.outstanding_balance
                   ELSE 0
               END)
         / SUM (ff.outstanding_balance)*100,2)||'%'    AS NPL_RATIO
    FROM FACT_FINANCING ff
         JOIN DIM_CUSTOMER c ON ff.customer_id = c.customer_id
         JOIN DIM_CLASSIFICATION dc ON ff.cl_status = dc.status_code
GROUP BY c.customer_name, c.RISK_LEVEL
ORDER BY total_exposure DESC
   FETCH FIRST 20 ROWS ONLY;

--B. Top 20 Non-performing Borrower Exposure
SELECT c.customer_name,
         c.RISK_LEVEL                      customer_risk_level,
         SUM (
             CASE
                 WHEN dc.is_performing = 0 THEN ff.outstanding_balance
                 ELSE 0
             END)                          AS npl_exposure,
           ROUND(SUM (
               CASE
                   WHEN dc.is_performing = 0 THEN ff.outstanding_balance
                   ELSE 0
               END)
         / SUM (ff.outstanding_balance)*100,2)||'%'    AS NPL_RATIO
    FROM FACT_FINANCING ff
         JOIN DIM_CUSTOMER c ON ff.customer_id = c.customer_id
         JOIN DIM_CLASSIFICATION dc ON ff.cl_status = dc.status_code
GROUP BY c.customer_name, c.RISK_LEVEL
ORDER BY npl_exposure DESC
   FETCH FIRST 20 ROWS ONLY;
   
   
--C. Sectoral Concentration Risk
  SELECT ds.sector_name,
         SUM (ff.outstanding_balance)    AS sector_exposure,
         ROUND (
               SUM (ff.outstanding_balance)
             / (SELECT SUM (outstanding_balance) FROM FACT_FINANCING)
             * 100,
             2)                          AS sector_concentration,
         ROUND (
             SUM (ff.classified_amount) / SUM (ff.outstanding_balance) * 100,
             2)                          AS sector_npl_ratio
    FROM FACT_FINANCING ff JOIN DIM_SECTOR ds ON ff.sector_id = ds.sector_id
GROUP BY ds.sector_name
  HAVING SUM (ff.outstanding_balance) > 0
ORDER BY sector_concentration DESC;

--3. Trend Analysis
--A. Monthly NPL Trend
  SELECT TO_CHAR (dd.full_date, 'YYYY-MM')    AS month,
         SUM (ff.outstanding_balance)         AS total_portfolio,
         SUM (
             CASE
                 WHEN dc.is_performing = 0 THEN ff.outstanding_balance
                 ELSE 0
             END)                             AS npl_amount,
         ROUND (
               SUM (
                   CASE
                       WHEN dc.is_performing = 0 THEN ff.outstanding_balance
                       ELSE 0
                   END)
             / SUM (ff.outstanding_balance)
             * 100,
             2)                               AS npl_ratio
    FROM FACT_FINANCING ff
         JOIN DIM_CLASSIFICATION dc ON ff.cl_status = dc.status_code
         JOIN DIM_DATE dd ON ff.process_date_id = dd.date_id
GROUP BY TO_CHAR (dd.full_date, 'YYYY-MM')
ORDER BY month;

--B. Risk Migration Analysis
WITH
    current_status
    AS
        (SELECT customer_id,
                CL_STATUS,
                outstanding_balance,
                ROW_NUMBER ()
                    OVER (PARTITION BY customer_id
                          ORDER BY process_date_id DESC)    AS rn
           FROM FACT_FINANCING)
  SELECT prev.CL_STATUS           AS from_status,
         curr.CL_STATUS           AS to_status,
         COUNT (*)                          AS loan_count,
         SUM (curr.outstanding_balance)     AS exposure_amount
    FROM current_status curr
         JOIN current_status prev
             ON curr.customer_id = prev.customer_id AND prev.rn = curr.rn + 1
   WHERE curr.rn = 1
GROUP BY prev.CL_STATUS, curr.CL_STATUS
ORDER BY exposure_amount DESC;

--4. Early Warning Signals
--A. Loans Approaching NPL Status

  SELECT c.customer_name,
         ff.outstanding_balance,
         dc.status_name         AS current_status,
         ff.process_date_id     AS last_review_date
    FROM FACT_FINANCING ff
         JOIN DIM_CUSTOMER c ON ff.customer_id = c.customer_id
         JOIN DIM_CLASSIFICATION dc ON ff.cl_status = dc.status_code
   WHERE dc.status_code = 'SMA' AND ff.outstanding_balance > 1000000 -- Threshold for material exposure
ORDER BY ff.outstanding_balance DESC;

--B. Deteriorating Loans

SELECT c.customer_name,
       prev_dc.status_name     AS previous_status,
       curr_dc.status_name     AS current_status,
       curr.outstanding_balance
  FROM FACT_FINANCING  curr
       JOIN FACT_FINANCING prev
           ON     curr.customer_id = prev.customer_id
              AND prev.process_date_id =
                  (SELECT MAX (process_date_id)
                     FROM FACT_FINANCING
                    WHERE     customer_id = curr.customer_id
                          AND process_date_id < curr.process_date_id)
       JOIN DIM_CLASSIFICATION curr_dc
           ON curr.cl_status = curr_dc.status_code
       JOIN DIM_CLASSIFICATION prev_dc
           ON prev.cl_status = prev_dc.status_code
       JOIN DIM_CUSTOMER c ON curr.customer_id = c.customer_id
 WHERE prev_dc.is_performing = 1 AND curr_dc.is_performing = 0;

--5. Regulatory & Basel Metrics
--A. Capital Adequacy

SELECT 'Risk-Weighted Assets'                             AS metric,
       SUM (ff.outstanding_balance * dlc.risk_weight)     AS VALUE
  FROM FACT_FINANCING  ff
       JOIN DIM_CL_CATEGORY dlc ON ff.CL_CATEGORY_ID = dlc.CL_CATEGORY_ID
UNION ALL
SELECT 'Gross NPL Exposure',
       SUM (
           CASE
               WHEN dc.is_performing = 0 THEN ff.outstanding_balance
               ELSE 0
           END)
  FROM FACT_FINANCING  ff
       JOIN DIM_CLASSIFICATION dc ON ff.cl_status = dc.status_code
--UNION ALL
--SELECT 'NPL Coverage Ratio (%)',
--       ROUND (
--             SUM (
--                 CASE WHEN dc.is_performing = 0 THEN ff.provisions ELSE 0 END)
--           / NULLIF (
--                 SUM (
--                     CASE
--                         WHEN dc.is_performing = 0
--                         THEN
--                             ff.outstanding_balance
--                         ELSE
--                             0
--                     END),
--                 0)
--           * 100,
--           2)
--  FROM FACT_FINANCING  ff
--       JOIN DIM_CLASSIFICATION dc ON ff.cl_status = dc.status_code
;


--B. Sectoral Risk Weight Analysis

  SELECT ds.sector_name,
         SUM (ff.outstanding_balance)
             AS total_exposure,
         SUM (ff.outstanding_balance * dlc.risk_weight)
             AS risk_weighted_exposure,
         ROUND (AVG (dlc.risk_weight) * 100, 2)
             AS avg_risk_weight_percent
    FROM FACT_FINANCING ff
         JOIN DIM_SECTOR ds ON ff.sector_id = ds.sector_id
         JOIN DIM_cl_CATEGORY dlc ON ff.cl_category_id = dlc.cl_category_id
GROUP BY ds.sector_name
ORDER BY risk_weighted_exposure DESC;

--6. Visualization-Ready Queries
--A. Heatmap Data (Sector × Risk)

  SELECT ds.sector_name,
         dc.status_name,
         SUM (ff.outstanding_balance)     AS exposure
    FROM FACT_FINANCING ff
         JOIN DIM_SECTOR ds ON ff.sector_id = ds.sector_id
         JOIN DIM_CLASSIFICATION dc ON ff.cl_status = dc.status_code
GROUP BY ds.sector_name, dc.status_name;

--B. Portfolio Composition Donut Chart

  SELECT dlc.CL_DESCRIPTION AS loan_type, SUM (ff.outstanding_balance) AS amount
    FROM FACT_FINANCING ff
         JOIN DIM_cl_CATEGORY dlc ON ff.cl_category_id = dlc.cl_category_id
GROUP BY dlc.CL_DESCRIPTION;

--Implementation Notes
--Index Optimization:

CREATE INDEX idx_fact_sector
    ON FACT_FINANCING (sector_id);

CREATE INDEX idx_fact_classification
    ON FACT_FINANCING (classification_code);

CREATE INDEX idx_fact_date
    ON FACT_FINANCING (process_date_id);


/*
--Materialized Views for frequent reports:
CREATE MATERIALIZED VIEW mv_daily_risk_snapshot
REFRESH COMPLETE ON DEMAND
AS SELECT * FROM (
  -- Your most frequently run query here
);
Automation:

Schedule these queries to run daily via Oracle Scheduler

Export results to CSV/Excel for regulatory reporting

This complete package gives you:
? Portfolio risk assessment
? Concentration analysis
? Trend monitoring
? Early warning signals
? Regulatory compliance metrics
? Visualization-ready data structures
*/