--DROP MATERIALIZED VIEW VW_BUSINESS_UNIT_FINANCING;

CREATE MATERIALIZED VIEW VW_BUSINESS_UNIT_FINANCING
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND WITH PRIMARY KEY
AS
      SELECT DD.FULL_DATE                     PROCESS_DATE,
             DBU.BUSINESS_UNIT_NAME,
             SUM (FF.OUTSTANDING_BALANCE)     AS OUTSTANDING_BALANCE,
             SUM (FF.PRINCIPAL_BALANCE)       AS PRINCIPAL_BALANCE,
             SUM (FF.CLASSIFIED_AMOUNT)       AS CLASSIFIED_AMOUNT
        FROM FACT_FINANCING FF
             INNER JOIN DIM_DATE DD ON DD.DATE_ID = FF.PROCESS_DATE_ID
             INNER JOIN DIM_BUSINESS_UNIT DBU
                 ON DBU.BUSINESS_UNIT_ID = FF.BUSINESS_UNIT_ID
    GROUP BY DD.FULL_DATE, DBU.BUSINESS_UNIT_NAME;



--DROP MATERIALIZED VIEW VW_CL_STATUS_FINANCING;

CREATE MATERIALIZED VIEW VW_CL_STATUS_FINANCING
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND WITH PRIMARY KEY
AS
      SELECT DD.FULL_DATE                    PROCESS_DATE,
             DC.STATUS_NAME,
             DC.RISK_WEIGHT,
             CASE
                 WHEN DC.IS_PERFORMING = 1 THEN 'Performing'
                 ELSE 'Non-performing'
             END                             PERFORMING_STATUS,
             SUM (FF.OUTSTANDING_BALANCE)    AS OUTSTANDING_BALANCE,
             SUM (FF.PRINCIPAL_BALANCE)      AS PRINCIPAL_BALANCE,
             SUM (FF.CLASSIFIED_AMOUNT)      AS CLASSIFIED_AMOUNT
        FROM FACT_FINANCING FF
             INNER JOIN DIM_DATE DD ON DD.DATE_ID = FF.PROCESS_DATE_ID
             INNER JOIN DIM_CLASSIFICATION DC ON DC.STATUS_CODE = FF.CL_STATUS
    GROUP BY DD.FULL_DATE,
             DC.STATUS_NAME,
             DC.RISK_WEIGHT,
             DC.IS_PERFORMING;



--DROP MATERIALIZED VIEW VW_CUSTOMER_FINANCING;

CREATE MATERIALIZED VIEW VW_CUSTOMER_FINANCING
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND WITH PRIMARY KEY
AS
    SELECT PROCESS_DATE,
           CUSTOMER_NAME,
           CUSTOMER_TYPE,
           OUTSTANDING_BALANCE,
           PRINCIPAL_BALANCE,
           CLASSIFIED_AMOUNT,
           SUM (OUTSTANDING_BALANCE) OVER (PARTITION BY CUSTOMER_TYPE)
               CUSTOMER_TYPE_OUTSTANDING_BALANCE,
           SUM (PRINCIPAL_BALANCE) OVER (PARTITION BY CUSTOMER_TYPE)
               CUSTOMER_TYPE_PRINCIPAL_BALANCE,
           SUM (CLASSIFIED_AMOUNT) OVER (PARTITION BY CUSTOMER_TYPE)
               CUSTOMER_TYPE_CLASSIFIED_AMOUNT,
           SUM (OUTSTANDING_BALANCE) OVER ()
               TOTAL_OUTSTANDING_BALANCE,
           SUM (PRINCIPAL_BALANCE) OVER ()
               TOTAL_PRINCIPAL_BALANCE,
           SUM (CLASSIFIED_AMOUNT) OVER ()
               TOTAL_CLASSIFIED_AMOUNT
      FROM (  SELECT DD.FULL_DATE                     PROCESS_DATE,
                     DC.CUSTOMER_NAME,
                     DC.CUSTOMER_TYPE,
                     SUM (FF.OUTSTANDING_BALANCE)     AS OUTSTANDING_BALANCE,
                     SUM (FF.PRINCIPAL_BALANCE)       AS PRINCIPAL_BALANCE,
                     SUM (FF.CLASSIFIED_AMOUNT)       AS CLASSIFIED_AMOUNT
                FROM FACT_FINANCING FF
                     INNER JOIN DIM_DATE DD ON DD.DATE_ID = FF.PROCESS_DATE_ID
                     INNER JOIN DIM_CUSTOMER DC
                         ON DC.CUSTOMER_ID = FF.CUSTOMER_ID
            GROUP BY DD.FULL_DATE, DC.CUSTOMER_NAME, DC.CUSTOMER_TYPE);



--DROP MATERIALIZED VIEW VW_DATE_FINANCING;

CREATE MATERIALIZED VIEW VW_DATE_FINANCING
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND WITH PRIMARY KEY
AS
    SELECT DD.FULL_DATE,
                 DD.DAY,
                 DD.YEAR,
                 DD.QUARTER,
                 DD.QUARTER_NAME,
                 DD.MONTH,
                 DD.MONTH_NAME,
                 DD.DAY_OF_WEEK,
                 DD.IS_MONTH_END,
                 SUM (FF.OUTSTANDING_BALANCE)     AS OUTSTANDING_BALANCE,
                 SUM (FF.PRINCIPAL_BALANCE)       AS PRINCIPAL_BALANCE,
                 SUM (FF.CLASSIFIED_AMOUNT)       AS CLASSIFIED_AMOUNT
            FROM FACT_FINANCING FF
                 INNER JOIN DIM_DATE DD ON FF.PROCESS_DATE_ID = DD.DATE_ID
        GROUP BY DD.FULL_DATE,
                 DD.DAY,
                 DD.YEAR,
                 DD.QUARTER,
                 DD.QUARTER_NAME,
                 DD.MONTH,
                 DD.MONTH_NAME,
                 DD.DAY_OF_WEEK,
                 DD.IS_MONTH_END;


--DROP MATERIALIZED VIEW VW_GEOGRAPHICAL_FINANCING;

CREATE MATERIALIZED VIEW VW_GEOGRAPHICAL_FINANCING
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND WITH PRIMARY KEY
AS
    SELECT PROCESS_DATE,
           BRANCH_NAME,
           DIVISION,
           ZONE,
           DISTRICT,
           THANA,
           OUTSTANDING_BALANCE,
           PRINCIPAL_BALANCE,
           CLASSIFIED_AMOUNT,
           SUM (OUTSTANDING_BALANCE)
               OVER (PARTITION BY DIVISION,
                                  ZONE,
                                  DISTRICT,
                                  THANA)
               AS THANA_TOTAL_OUTSTANDING_BALANCE,
           SUM (PRINCIPAL_BALANCE)
               OVER (PARTITION BY DIVISION,
                                  ZONE,
                                  DISTRICT,
                                  THANA)
               AS THANA_TOTAL_PRINCIPAL_BALANCE,
           SUM (CLASSIFIED_AMOUNT)
               OVER (PARTITION BY DIVISION,
                                  ZONE,
                                  DISTRICT,
                                  THANA)
               AS THANA_TOTAL_CLASSIFIED_AMOUNT,
           SUM (OUTSTANDING_BALANCE)
               OVER (PARTITION BY DIVISION, ZONE, DISTRICT)
               AS DISTRICT_TOTAL_OUTSTANDING_BALANCE,
           SUM (PRINCIPAL_BALANCE)
               OVER (PARTITION BY DIVISION, ZONE, DISTRICT)
               AS DISTRICT_TOTAL_PRINCIPAL_BALANCE,
           SUM (CLASSIFIED_AMOUNT)
               OVER (PARTITION BY DIVISION, ZONE, DISTRICT)
               AS DISTRICT_TOTAL_CLASSIFIED_AMOUNT,
           SUM (OUTSTANDING_BALANCE) OVER (PARTITION BY DIVISION, ZONE)
               AS ZONE_TOTAL_OUTSTANDING_BALANCE,
           SUM (PRINCIPAL_BALANCE) OVER (PARTITION BY DIVISION, ZONE)
               AS ZONE_TOTAL_PRINCIPAL_BALANCE,
           SUM (CLASSIFIED_AMOUNT) OVER (PARTITION BY DIVISION, ZONE)
               AS ZONE_TOTAL_CLASSIFIED_AMOUNT,
           SUM (OUTSTANDING_BALANCE) OVER (PARTITION BY DIVISION)
               AS DIVISION_TOTAL_OUTSTANDING_BALANCE,
           SUM (PRINCIPAL_BALANCE) OVER (PARTITION BY DIVISION)
               AS DIVISION_TOTAL_PRINCIPAL_BALANCE,
           SUM (CLASSIFIED_AMOUNT) OVER (PARTITION BY DIVISION)
               AS DIVISION_TOTAL_CLASSIFIED_AMOUNT,
           SUM (OUTSTANDING_BALANCE) OVER ()
               AS GRAND_TOTAL_OUTSTANDING_BALANCE,
           SUM (PRINCIPAL_BALANCE) OVER ()
               AS GRAND_TOTAL_PRINCIPAL_BALANCE,
           SUM (CLASSIFIED_AMOUNT) OVER ()
               AS GRAND_TOTAL_CLASSIFIED_AMOUNT
      FROM (  SELECT DD.FULL_DATE                     PROCESS_DATE,
                     DB.BRANCH_NAME,
                     DB.DIVISION,
                     DB.ZONE,
                     DB.DISTRICT,
                     DB.THANA,
                     SUM (FF.OUTSTANDING_BALANCE)     AS OUTSTANDING_BALANCE,
                     SUM (FF.PRINCIPAL_BALANCE)       AS PRINCIPAL_BALANCE,
                     SUM (FF.CLASSIFIED_AMOUNT)       AS CLASSIFIED_AMOUNT
                FROM FACT_FINANCING FF
                     INNER JOIN DIM_DATE DD ON FF.PROCESS_DATE_ID = DD.DATE_ID
                     INNER JOIN DIM_BRANCH DB ON DB.BRANCH_ID = FF.BRANCH_ID
            GROUP BY DD.FULL_DATE,
                     DB.BRANCH_NAME,
                     DB.DIVISION,
                     DB.ZONE,
                     DB.DISTRICT,
                     DB.THANA);



--DROP MATERIALIZED VIEW VW_NATURE_WISE_FINANCING;

CREATE MATERIALIZED VIEW VW_NATURE_WISE_FINANCING
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND WITH PRIMARY KEY
AS
      SELECT DD.FULL_DATE                     PROCESS_DATE,
             DCC.CL_DESCRIPTION,
             DCC.RISK_WEIGHT,
             SUM (FF.OUTSTANDING_BALANCE)     AS OUTSTANDING_BALANCE,
             SUM (FF.PRINCIPAL_BALANCE)       AS PRINCIPAL_BALANCE,
             SUM (FF.CLASSIFIED_AMOUNT)       AS CLASSIFIED_AMOUNT
        FROM FACT_FINANCING FF
             INNER JOIN DIM_DATE DD ON FF.PROCESS_DATE_ID = DD.DATE_ID
             INNER JOIN DIM_CL_CATEGORY DCC
                 ON DCC.CL_CATEGORY_ID = FF.CL_CATEGORY_ID
    GROUP BY DD.FULL_DATE, DCC.CL_DESCRIPTION, DCC.RISK_WEIGHT;



--DROP MATERIALIZED VIEW VW_PRODUCT_FINANCING;

CREATE MATERIALIZED VIEW VW_PRODUCT_FINANCING
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND WITH PRIMARY KEY
AS
    SELECT PROCESS_DATE,
           PRODUCT_NAME,
           INV_MODE,
           IS_INSTALLMENT,
           OUTSTANDING_BALANCE,
           PRINCIPAL_BALANCE,
           CLASSIFIED_AMOUNT,
           SUM (OUTSTANDING_BALANCE) OVER (PARTITION BY INV_MODE)
               MOD_WISE_OUTSTANDING_BALANCE,
           SUM (PRINCIPAL_BALANCE) OVER (PARTITION BY INV_MODE)
               MOD_WISE_PRINCIPAL_BALANCE,
           SUM (CLASSIFIED_AMOUNT) OVER (PARTITION BY INV_MODE)
               MOD_WISE_CLASSIFIED_AMOUNT,
           SUM (OUTSTANDING_BALANCE) OVER (PARTITION BY IS_INSTALLMENT)
               ISNTALL_TYPE_OUTSTANDING_BALANCE,
           SUM (PRINCIPAL_BALANCE) OVER (PARTITION BY IS_INSTALLMENT)
               ISNTALL_TYPE_PRINCIPAL_BALANCE,
           SUM (CLASSIFIED_AMOUNT) OVER (PARTITION BY IS_INSTALLMENT)
               ISNTALL_TYPE_CLASSIFIED_AMOUNT,
           SUM (OUTSTANDING_BALANCE) OVER ()
               TOTAL_OUTSTANDING_BALANCE,
           SUM (PRINCIPAL_BALANCE) OVER ()
               TOTAL_PRINCIPAL_BALANCE,
           SUM (CLASSIFIED_AMOUNT) OVER ()
               TOTAL_CLASSIFIED_AMOUNT
      FROM (  SELECT DD.FULL_DATE                     PROCESS_DATE,
                     DP.PRODUCT_NAME,
                     DP.INV_MODE,
                     DP.IS_INSTALLMENT,
                     SUM (FF.OUTSTANDING_BALANCE)     AS OUTSTANDING_BALANCE,
                     SUM (FF.PRINCIPAL_BALANCE)       AS PRINCIPAL_BALANCE,
                     SUM (FF.CLASSIFIED_AMOUNT)       AS CLASSIFIED_AMOUNT
                FROM FACT_FINANCING FF
                     INNER JOIN DIM_DATE DD ON FF.PROCESS_DATE_ID = DD.DATE_ID
                     LEFT JOIN DIM_PRODUCT DP ON DP.PRODUCT_ID = FF.PRODUCT_ID
            GROUP BY DD.FULL_DATE,
                     DP.PRODUCT_NAME,
                     DP.INV_MODE,
                     DP.IS_INSTALLMENT);



--DROP MATERIALIZED VIEW VW_SECTOR_FINANCING;

CREATE MATERIALIZED VIEW VW_SECTOR_FINANCING
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND WITH PRIMARY KEY
AS
      SELECT DD.FULL_DATE                     PROCESS_DATE,
             DS.SECTOR_ID,
             DS.ECONOMIC_CODE,
             DS.SECTOR_NAME,
             DS.PARENT_ID,
             DS.HIERARCHY_LEVEL,
             DS.HIERARCHY_PATH,
             DS.IS_LEAF,
             SUM (FF.OUTSTANDING_BALANCE)     AS OUTSTANDING_BALANCE,
             SUM (FF.PRINCIPAL_BALANCE)       AS PRINCIPAL_BALANCE,
             SUM (FF.CLASSIFIED_AMOUNT)       AS CLASSIFIED_AMOUNT
        FROM FACT_FINANCING FF
             INNER JOIN DIM_DATE DD ON FF.PROCESS_DATE_ID = DD.DATE_ID
             RIGHT JOIN DIM_SECTOR DS ON DS.SECTOR_ID = FF.SECTOR_ID
    GROUP BY DD.FULL_DATE,
             DS.SECTOR_ID,
             DS.ECONOMIC_CODE,
             DS.SECTOR_NAME,
             DS.PARENT_ID,
             DS.HIERARCHY_LEVEL,
             DS.HIERARCHY_PATH,
             DS.IS_LEAF;