SELECT YEAR, QUARTER,
       SUM(OUTSTANDING_BALANCE) AS TOTAL_OUTSTANDING_BALANCE,
       SUM(CLASSIFIED_AMOUNT) AS TOTAL_CLASSIFIED_AMOUNT,
       LAG(SUM(CLASSIFIED_AMOUNT)) OVER (ORDER BY YEAR, QUARTER) AS PREV_QUARTER_CLASSIFIED_AMOUNT
FROM VW_DATE_FINANCING
GROUP BY YEAR, QUARTER;

SELECT CUSTOMER_NAME, CUSTOMER_TYPE,
       CASE
           WHEN CLASSIFIED_AMOUNT > 0 THEN 'High Risk'
           WHEN OUTSTANDING_BALANCE > AVG(OUTSTANDING_BALANCE) OVER () THEN 'Medium Risk'
           ELSE 'Low Risk'
       END AS CUSTOMER_RISK_SEGMENT
FROM VW_CUSTOMER_FINANCING;

SELECT DIVISION, ZONE, DISTRICT, THANA,
       SUM(OUTSTANDING_BALANCE) AS TOTAL_OUTSTANDING_BALANCE,
       SUM(CLASSIFIED_AMOUNT) AS TOTAL_CLASSIFIED_AMOUNT,
       (SUM(CLASSIFIED_AMOUNT) / NULLIF(SUM(OUTSTANDING_BALANCE), 0)) * 100 AS RISK_SCORE
FROM VW_GEOGRAPHICAL_FINANCING
GROUP BY DIVISION, ZONE, DISTRICT, THANA
ORDER BY RISK_SCORE DESC;

SELECT CUSTOMER_NAME, SUM(CLASSIFIED_AMOUNT) AS TOTAL_CLASSIFIED_AMOUNT
FROM VW_CUSTOMER_FINANCING
GROUP BY CUSTOMER_NAME
ORDER BY TOTAL_CLASSIFIED_AMOUNT DESC
FETCH FIRST 10 ROWS ONLY;
