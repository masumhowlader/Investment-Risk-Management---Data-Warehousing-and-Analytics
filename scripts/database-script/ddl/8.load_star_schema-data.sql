CREATE OR REPLACE PROCEDURE LOAD_STAR_SCHEMA
AS
BEGIN
    STAR_SCHEMA_TABLE;

    INSERT INTO DIM_DATE (DATE_ID,
                          FULL_DATE,
                          DAY,
                          MONTH,
                          MONTH_NAME,
                          YEAR,
                          QUARTER,
                          QUARTER_NAME,
                          DAY_OF_WEEK,
                          IS_MONTH_END)
        SELECT TO_CHAR (PROCESS_DATE, 'RRRRMMDD'),
               PROCESS_DATE                         FULL_DATE,
               EXTRACT (DAY FROM PROCESS_DATE)      PDAY,
               EXTRACT (MONTH FROM PROCESS_DATE)    PMONTH,
               TO_CHAR (PROCESS_DATE, 'fmMonth')    PMONTH_NAME,
               EXTRACT (YEAR FROM PROCESS_DATE)     PYEAR,
               CASE
                   WHEN EXTRACT (MONTH FROM PROCESS_DATE) BETWEEN 1 AND 3
                   THEN
                       1
                   WHEN EXTRACT (MONTH FROM PROCESS_DATE) BETWEEN 4 AND 6
                   THEN
                       2
                   WHEN EXTRACT (MONTH FROM PROCESS_DATE) BETWEEN 7 AND 9
                   THEN
                       3
                   WHEN EXTRACT (MONTH FROM PROCESS_DATE) BETWEEN 10 AND 12
                   THEN
                       4
               END                                  PQUARTER,
               CASE
                   WHEN EXTRACT (MONTH FROM PROCESS_DATE) BETWEEN 1 AND 3
                   THEN
                       'First Quarter'
                   WHEN EXTRACT (MONTH FROM PROCESS_DATE) BETWEEN 4 AND 6
                   THEN
                       'Second Quarter'
                   WHEN EXTRACT (MONTH FROM PROCESS_DATE) BETWEEN 7 AND 9
                   THEN
                       'Third Quarter'
                   WHEN EXTRACT (MONTH FROM PROCESS_DATE) BETWEEN 10 AND 12
                   THEN
                       'Fourth Quarter'
               END                                  PQUARTER_NAME,
               TO_CHAR (PROCESS_DATE, 'Day')        DAY_OF_WEEK,
               CASE
                   WHEN PROCESS_DATE = LAST_DAY (PROCESS_DATE) THEN 1
                   ELSE 0
               END                                  IS_MONTH_END
          FROM (SELECT DISTINCT PROCESS_DATE
                  FROM STG_MONTHLY_ACCOUNT_BALANCES);

    COMMIT;

    ----------------------------------------------------
    INSERT INTO DIM_BRANCH (BRANCH_ID,
                            BRANCH_NAME,
                            DISTRICT,
                            THANA,
                            DIVISION,
                            ZONE)
        SELECT BRANCH_ID,
               BRANCH_NAME,
               DISTRICT,
               THANA,
               DIVISION_NAME,
               BRANCH_ZONE
          FROM STG_BRANCHES B, STG_DISTRICTS D, STG_DIVISIONS DV
         WHERE     B.DISTRICT = D.DISTRICT_TITLE
               AND D.DIVISION_ID = DV.DIVISION_ID;

    COMMIT;


    ----------------------------------------------------
    INSERT INTO DIM_PRODUCT (PRODUCT_ID,
                             PRODUCT_CODE,
                             PRODUCT_NAME,
                             INV_MODE,
                             IS_INSTALLMENT)
        SELECT ID,
               PRODUCT_CODE,
               PRODUCT_NAME,
               INITCAP (
                   CASE
                       WHEN UPPER (PRODUCT_NAME) LIKE '%MUAZZAL%'
                       THEN
                           'BAI-MUAZZAL'
                       WHEN    UPPER (PRODUCT_NAME) LIKE '%H.P.S.M%'
                            OR UPPER (PRODUCT_NAME) LIKE '%HIRE PURCHASE%'
                       THEN
                           'Hire Purchase under Shirkatul Milk'
                       WHEN UPPER (PRODUCT_NAME) LIKE '%MURABAHA%'
                       THEN
                           'MURABAHA'
                       WHEN UPPER (PRODUCT_NAME) LIKE '%MUDARABA%'
                       THEN
                           'MUDARABA'
                       WHEN UPPER (PRODUCT_NAME) LIKE '%BAIM%'
                       THEN
                           'BAIM'
                       WHEN    UPPER (PRODUCT_NAME) LIKE '%TRUST RECEIPT%'
                            OR UPPER (PRODUCT_NAME) LIKE '%TR%'
                       THEN
                           'TRUST RECEIPT'
                       WHEN UPPER (PRODUCT_NAME) LIKE '%BANK GUARAN%'
                       THEN
                           'BANK GUARANTEE'
                       WHEN UPPER (PRODUCT_NAME) LIKE '%BAI-SALAM%'
                       THEN
                           'BAI-SALAM'
                       WHEN UPPER (PRODUCT_NAME) LIKE '%MUSHARAKA%'
                       THEN
                           'MUSHARAKA'
                       WHEN UPPER (PRODUCT_NAME) LIKE '%QUARD%'
                       THEN
                           'QUARD'
                       WHEN UPPER (PRODUCT_NAME) LIKE '%ISTISHNA%'
                       THEN
                           'BAI-ISTISHNA'
                       WHEN UPPER (PRODUCT_NAME) LIKE '%BILL%'
                       THEN
                           'BILLS'
                       WHEN    UPPER (PRODUCT_NAME) LIKE '%L/C%'
                            OR UPPER (PRODUCT_NAME) LIKE '%LETTER%'
                            OR UPPER (PRODUCT_NAME) LIKE '%EPZ%'
                            OR UPPER (PRODUCT_NAME) LIKE '%BB SIGHT%'
                       THEN
                           'L/C'
                       ELSE
                           'Others'
                   END)    INV_MODE,
               IS_INSTALLMENT
          FROM STG_PRODUCTS;

    COMMIT;


    ----------------------------------------------------
    INSERT INTO DIM_CUSTOMER (CUSTOMER_ID, CUSTOMER_NAME, CUSTOMER_TYPE)
        SELECT CUSTOMER_ID, CUSTOMER_NAME, DESCRIPTION
          FROM STG_CUSTOMERS C, STG_CUSTOMER_TYPES T
         WHERE C.CUSTOMER_CATEGORY_ID = T.CUSTOMER_TYPE_ID;

    COMMIT;


    ----------------------------------------------------
    INSERT INTO DIM_BUSINESS_UNIT (BUSINESS_UNIT_ID, BUSINESS_UNIT_NAME)
        SELECT BUSINESS_UNIT_ID, BUSINESS_UNIT_NAME FROM STG_BUSINESS_UNITS;

    COMMIT;


    ----------------------------------------------------
    INSERT INTO DIM_SECTOR (SECTOR_ID,
                            ECONOMIC_CODE,
                            SECTOR_NAME,
                            PARENT_ID,
                            HIERARCHY_LEVEL,
                            HIERARCHY_PATH,
                            IS_LEAF)
        WITH
            HIERARCHY_DATA (SECTOR_ID,
                            ECONOCODE,
                            SECTOR_NAME,
                            PARENT_ID,
                            HIERARCHY_LEVEL,
                            HIERARCHY_PATH,
                            IS_LEAF)
            AS
                (                                      -- Level 0 (Root) nodes
                 SELECT ID                AS SECTOR_ID,
                        ECOCODE           AS ECONOCODE,
                        ECODESCRIPTION    AS SECTOR_NAME,
                        NULL              AS PARENT_ID,
                        1                 AS HIERARCHY_LEVEL,
                        ECODESCRIPTION    AS HIERARCHY_PATH,
                        CASE
                            WHEN EXISTS
                                     (SELECT 1
                                        FROM STG_SECTORS C
                                       WHERE C.PARENT_ID = S.ID)
                            THEN
                                0
                            ELSE
                                1
                        END               AS IS_LEAF
                   FROM STG_SECTORS S
                  WHERE PARENT_ID = 0
                 UNION ALL
                 -- Level 1 and Level 2 nodes
                 SELECT S.ID
                            AS SECTOR_ID,
                        S.ECOCODE
                            AS ECONOCODE,
                        S.ECODESCRIPTION
                            AS SECTOR_NAME,
                        S.PARENT_ID,
                        P.HIERARCHY_LEVEL + 1
                            AS HIERARCHY_LEVEL,
                        P.HIERARCHY_PATH || ' > ' || S.ECODESCRIPTION
                            AS HIERARCHY_PATH,
                        CASE
                            WHEN EXISTS
                                     (SELECT 1
                                        FROM STG_SECTORS C
                                       WHERE C.PARENT_ID = S.ID)
                            THEN
                                0
                            ELSE
                                1
                        END
                            AS IS_LEAF
                   FROM STG_SECTORS  S
                        JOIN HIERARCHY_DATA P ON S.PARENT_ID = P.SECTOR_ID)
          SELECT *
            FROM HIERARCHY_DATA
        ORDER BY HIERARCHY_LEVEL, SECTOR_NAME;

    COMMIT;


    ----------------------------------------------------
    INSERT INTO DIM_CL_CATEGORY (CL_CATEGORY_ID,
                                 CL_CODE,
                                 CL_DESCRIPTION,
                                 RISK_WEIGHT)
        SELECT ID,
               LPAD (CL_CODE, 2, 0),
               DESCRIPTION,
               CASE LPAD (CL_CODE, 2, 0)
                   WHEN '01' THEN 0.50                      -- Continuous Loan
                   WHEN '02' THEN 0.75                          -- Demand Loan
                   WHEN '03' THEN 0.80                     -- Term Loan (Long)
                   WHEN '04' THEN 0.70                             -- SME Loan
                   ELSE 0.75                                        -- Default
               END
          FROM STG_CL_CATEGORIES;

    COMMIT;


    ----------------------------------------------------
    INSERT INTO DIM_CLASSIFICATION (STATUS_CODE,
                                    STATUS_NAME,
                                    RISK_WEIGHT,
                                    IS_PERFORMING)
         VALUES ('STD',
                 'Standard',
                 0.0,
                 1);

    INSERT INTO DIM_CLASSIFICATION (STATUS_CODE,
                                    STATUS_NAME,
                                    RISK_WEIGHT,
                                    IS_PERFORMING)
         VALUES ('SMA',
                 'Special Mention',
                 0.1,
                 1);

    INSERT INTO DIM_CLASSIFICATION (STATUS_CODE,
                                    STATUS_NAME,
                                    RISK_WEIGHT,
                                    IS_PERFORMING)
         VALUES ('SS',
                 'Sub-Sandard',
                 0.2,
                 0);

    INSERT INTO DIM_CLASSIFICATION (STATUS_CODE,
                                    STATUS_NAME,
                                    RISK_WEIGHT,
                                    IS_PERFORMING)
         VALUES ('DF',
                 'Doubtful',
                 0.5,
                 0);

    INSERT INTO DIM_CLASSIFICATION (STATUS_CODE,
                                    STATUS_NAME,
                                    RISK_WEIGHT,
                                    IS_PERFORMING)
         VALUES ('BL',
                 'Bad/Loss',
                 1.0,
                 0);

    COMMIT;

    ----------------------------------------------------
    INSERT INTO FACT_FINANCING (FACT_ID,
                                PROCESS_DATE_ID,
                                CUSTOMER_ID,
                                BRANCH_ID,
                                PRODUCT_ID,
                                SECTOR_ID,
                                BUSINESS_UNIT_ID,
                                CL_CATEGORY_ID,
                                CL_STATUS,
                                OUTSTANDING_BALANCE,
                                PRINCIPAL_BALANCE,
                                CLASSIFIED_AMOUNT,
                                NO_OF_ACCOUNTS,
                                IS_INSTALLMENT)
        SELECT ROW_NUMBER () OVER (ORDER BY M.PROCESS_DATE, M.CUSTOMER_ID)
                   AS FACT_ID,
               (SELECT D.DATE_ID
                  FROM DIM_DATE D
                 WHERE D.FULL_DATE = M.PROCESS_DATE)
                   AS PROCESS_DATE_ID,
               M.CUSTOMER_ID,
               M.ACC_BRANCH_ID,
               P.ID,
               S.SECTOR_ID,                   -- Links to DIM_SECTOR.sector_id
               (SELECT BUSINESS_UNIT_ID
                  FROM STG_BUSINESS_UNITS BU
                 WHERE BU.BUSINESS_UNIT_NAME = M.BUSINESS_UNIT),
               (SELECT CL_CATEGORY_ID
                  FROM DIM_CL_CATEGORY CC
                 WHERE LPAD (CC.CL_CODE, 2, 0) = LPAD (M.CL_CODE, 2, 0))
                   AS LOAN_CATEGORY_ID,          -- Links to DIM_LOAN_CATEGORY
               M.CL_STATUS
                   AS CLASSIFICATION_CODE,      -- Links to DIM_CLASSIFICATION
               NVL (M.OUTSTANDING_BALANCE, 0),
               NVL (M.PRINCIPAL_BALANCE, 0),
               CASE
                   WHEN M.CL_STATUS IN ('SS', 'DF', 'BL')
                   THEN
                       M.OUTSTANDING_BALANCE
                   ELSE
                       0
               END
                   AS CLASSIFIED_AMOUNT,
               1
                   AS NO_OF_ACCOUNTS,                  -- Each row = 1 account
               M.IS_INSTALLMENT
          FROM STG_MONTHLY_ACCOUNT_BALANCES  M
               JOIN STG_PRODUCTS P ON M.PRODUCT_CODE = P.PRODUCT_CODE
               JOIN DIM_SECTOR S ON M.ECONOMIC_CODE = S.ECONOMIC_CODE
               JOIN DIM_CUSTOMER C ON M.CUSTOMER_ID = C.CUSTOMER_ID;

    COMMIT;
END;
/