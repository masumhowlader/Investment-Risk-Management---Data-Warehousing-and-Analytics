CREATE OR REPLACE PROCEDURE STAR_SCHEMA_TABLE
IS
BEGIN
    FOR C
        IN (SELECT TABLE_NAME, CONSTRAINT_NAME
              FROM USER_CONSTRAINTS
             WHERE     CONSTRAINT_TYPE IN ('P',
                                           'U',
                                           'R',
                                           'C') -- P: Primary Key, U: Unique, R: Foreign Key, C: Check
                   AND (TABLE_NAME LIKE 'DIM_%' OR TABLE_NAME LIKE 'FACT_%'))
    LOOP
        BEGIN
            EXECUTE IMMEDIATE   'ALTER TABLE '
                             || C.TABLE_NAME
                             || ' DISABLE CONSTRAINT '
                             || C.CONSTRAINT_NAME;
        EXCEPTION
            WHEN OTHERS
            THEN
                DBMS_OUTPUT.PUT_LINE (
                       C.CONSTRAINT_NAME
                    || ' constraint disabling. Error: '
                    || SQLERRM);
        END;
    END LOOP;

    -- Drop tables starting with DIM_ and FACT_
    FOR T IN (SELECT TABLE_NAME
                FROM USER_TABLES
               WHERE TABLE_NAME LIKE 'DIM_%' OR TABLE_NAME LIKE 'FACT_%')
    LOOP
        BEGIN
            EXECUTE IMMEDIATE   'DROP TABLE '
                             || T.TABLE_NAME
                             || ' CASCADE CONSTRAINTS';
        EXCEPTION
            WHEN OTHERS
            THEN
                DBMS_OUTPUT.PUT_LINE (
                    T.TABLE_NAME || ' table droping. Error: ' || SQLERRM);
        END;
    END LOOP;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE DIM_DATE
(
    DATE_ID         NUMBER(8) PRIMARY KEY,
    FULL_DATE       DATE,
    DAY             NUMBER (2),
    MONTH           NUMBER (2),
    MONTH_NAME      VARCHAR2(10),
    YEAR            NUMBER (4),
    QUARTER         NUMBER (1),
    QUARTER_NAME      VARCHAR2(14),
    DAY_OF_WEEK     VARCHAR2 (10),
    IS_MONTH_END    NUMBER (1)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'DIM_DATE table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE DIM_SECTOR
(
    SECTOR_ID          NUMBER(4) PRIMARY KEY,                -- New synthetic key
    ECONOMIC_CODE      VARCHAR2 (30),                      -- Original ECOCODE
    SECTOR_NAME        VARCHAR2 (100),
    PARENT_ID          NUMBER(4),          -- References sector_key (not ECOCODE)
    HIERARCHY_LEVEL    NUMBER(2),
    HIERARCHY_PATH     VARCHAR2 (500),
    IS_LEAF            NUMBER (1),
    CONSTRAINT FK_PARENT FOREIGN KEY (PARENT_ID)
        REFERENCES DIM_SECTOR (SECTOR_ID)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'DIM_SECTOR table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE DIM_CUSTOMER
(
    CUSTOMER_ID      NUMBER(9) PRIMARY KEY,
    CUSTOMER_NAME    VARCHAR2 (50 BYTE),
    CUSTOMER_TYPE    VARCHAR2 (30 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'DIM_CUSTOMER table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE DIM_PRODUCT
(
    PRODUCT_ID        NUMBER(4) PRIMARY KEY,
    PRODUCT_CODE      VARCHAR2 (3 BYTE),
    PRODUCT_NAME      VARCHAR2 (70 BYTE),
    INV_MODE          VARCHAR2 (50 BYTE),
    IS_INSTALLMENT    NUMBER (1)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'DIM_PRODUCT table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE DIM_BRANCH
(
    BRANCH_ID      VARCHAR2 (10 BYTE) PRIMARY KEY,
    BRANCH_NAME    VARCHAR2 (50 BYTE),
    DISTRICT       VARCHAR2 (30 BYTE),
    THANA          VARCHAR2 (30 BYTE),
    DIVISION       VARCHAR2 (30 BYTE),
    ZONE           VARCHAR2 (30 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'DIM_BRANCH table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE DIM_CL_CATEGORY
(
    CL_CATEGORY_ID    NUMBER(2) PRIMARY KEY,
    CL_CODE           VARCHAR2 (2 BYTE),
    CL_DESCRIPTION    VARCHAR2 (50 BYTE),
    RISK_WEIGHT       NUMBER (3, 2)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'DIM_CL_CATEGORY table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE DIM_BUSINESS_UNIT
(
    BUSINESS_UNIT_ID      NUMBER(2) PRIMARY KEY,
    BUSINESS_UNIT_NAME    VARCHAR2 (20 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'DIM_BUSINESS_UNIT table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE DIM_CLASSIFICATION
(
    STATUS_CODE      VARCHAR2 (3) PRIMARY KEY,            -- E.G., "STD", "SS"
    STATUS_NAME      VARCHAR2 (20),         -- E.G., "STANDARD", "SUBSTANDARD"
    RISK_WEIGHT      NUMBER (3, 2),           -- E.G., 0.0 FOR STD, 0.2 FOR SS
    IS_PERFORMING    NUMBER (1)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'DIM_CLASSIFICATION table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE FACT_FINANCING
(
    FACT_ID                NUMBER PRIMARY KEY,
    PROCESS_DATE_ID        NUMBER(8),
    CUSTOMER_ID            NUMBER(9),
    BRANCH_ID              VARCHAR2 (10 BYTE),
    PRODUCT_ID             NUMBER(4),
    SECTOR_ID              NUMBER(4),
    CL_CATEGORY_ID         NUMBER(2),
    BUSINESS_UNIT_ID       NUMBER(2),
    CL_STATUS              VARCHAR2 (3 BYTE),
    OUTSTANDING_BALANCE    NUMBER (20, 2),
    PRINCIPAL_BALANCE      NUMBER (20, 2),
    CLASSIFIED_AMOUNT      NUMBER (20, 2),
    NO_OF_ACCOUNTS         NUMBER(1),
    IS_INSTALLMENT         NUMBER (1),
    FOREIGN KEY (PROCESS_DATE_ID) REFERENCES DIM_DATE (DATE_ID),
    FOREIGN KEY (CUSTOMER_ID) REFERENCES DIM_CUSTOMER (CUSTOMER_ID),
    FOREIGN KEY (BRANCH_ID) REFERENCES DIM_BRANCH (BRANCH_ID),
    FOREIGN KEY (PRODUCT_ID) REFERENCES DIM_PRODUCT (PRODUCT_ID),
    FOREIGN KEY (SECTOR_ID) REFERENCES DIM_SECTOR (SECTOR_ID),
    FOREIGN KEY (CL_CATEGORY_ID) REFERENCES DIM_CL_CATEGORY (CL_CATEGORY_ID),
    FOREIGN KEY (CL_STATUS) REFERENCES DIM_CLASSIFICATION (STATUS_CODE),
    FOREIGN KEY
        (BUSINESS_UNIT_ID)
        REFERENCES DIM_BUSINESS_UNIT (BUSINESS_UNIT_ID)
)
PARTITION BY RANGE (PROCESS_DATE_ID) (
            PARTITION P_2020 VALUES LESS THAN (20210101), -- Data for 2020
            PARTITION P_2021 VALUES LESS THAN (20220101), -- Data for 2021
            PARTITION P_2022 VALUES LESS THAN (20230101), -- Data for 2022
            PARTITION P_2023 VALUES LESS THAN (20240101), -- Data for 2023
            PARTITION P_2024 VALUES LESS THAN (20250101), -- Data for 2024
            PARTITION P_MAXVALUE VALUES LESS THAN (MAXVALUE) -- Future data
        )';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'FACT_FINANCING table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE FACT_FINANCING MOVE PARTITION P_2020 COMPRESS BASIC';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'PARTITION P_2020 creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE FACT_FINANCING MOVE PARTITION P_2021 COMPRESS BASIC';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'PARTITION P_2021 creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE FACT_FINANCING MOVE PARTITION P_2022 COMPRESS BASIC';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'PARTITION P_2022 creation. Error: ' || SQLERRM);
    END;

    BEGIN
        -- Compress the most recent partition (2023) with OLTP compression
        EXECUTE IMMEDIATE 'ALTER TABLE FACT_FINANCING MOVE PARTITION P_2023 COMPRESS FOR OLTP';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'PARTITION P_2023 creation. Error: ' || SQLERRM);
    END;

    BEGIN
        -- Leave future partitions (2024, 2025) uncompressed for flexibility
        EXECUTE IMMEDIATE 'ALTER TABLE FACT_FINANCING MOVE PARTITION P_2024 NOCOMPRESS';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'PARTITION P_2024 creation. Error: ' || SQLERRM);
    END;

    FOR I
        IN (SELECT TABLE_NAME,
                   COLUMN_NAME,
                   'IDX_' || TABLE_NAME || '_' || COLUMN_NAME     INDEX_NAME
              FROM USER_TAB_COLUMNS
             WHERE    (TABLE_NAME = 'DIM_DATE' AND COLUMN_NAME <> 'DATE_ID')
                   OR (    TABLE_NAME = 'FACT_FINANCING'
                       AND COLUMN_NAME IN ('PROCESS_DATE_ID',
                                           'CUSTOMER_ID',
                                           'BRANCH_ID',
                                           'PRODUCT_ID',
                                           'SECTOR_ID'))
                   OR (    TABLE_NAME = 'DIM_SECTOR'
                       AND COLUMN_NAME = 'PARENT_ID')
                   OR (    TABLE_NAME = 'DIM_CUSTOMER'
                       AND COLUMN_NAME = 'CUSTOMER_TYPE')
                   OR (    TABLE_NAME = 'DIM_BRANCH'
                       AND COLUMN_NAME IN ('DISTRICT', 'DIVISION'))
                   OR (    TABLE_NAME = 'DIM_PRODUCT'
                       AND COLUMN_NAME IN ('PRODUCT_CODE', 'PRODUCT_NAME')))
    LOOP
        BEGIN
            EXECUTE IMMEDIATE   'CREATE INDEX '
                             || I.INDEX_NAME
                             || ' ON '
                             || I.TABLE_NAME
                             || '('
                             || I.COLUMN_NAME
                             || ')';
        EXCEPTION
            WHEN OTHERS
            THEN
                DBMS_OUTPUT.PUT_LINE (
                       I.INDEX_NAME
                    || ' index on '
                    || I.TABLE_NAME
                    || '('
                    || I.COLUMN_NAME
                    || ') creation. Error: '
                    || SQLERRM);
        END;
    END LOOP;

    FOR I
        IN (SELECT TABLE_NAME,
                   COLUMN_NAME,
                   'IDX_' || TABLE_NAME || '_' || COLUMN_NAME     INDEX_NAME
              FROM USER_TAB_COLUMNS
             WHERE     TABLE_NAME = 'FACT_FINANCING'
                   AND COLUMN_NAME IN ('CL_STATUS',
                                       'IS_INSTALLMENT',
                                       'BUSINESS_UNIT_ID',
                                       'CL_CATEGORY_ID'))
    LOOP
        BEGIN
            EXECUTE IMMEDIATE   'CREATE BITMAP INDEX '
                             || I.INDEX_NAME
                             || ' ON '
                             || I.TABLE_NAME
                             || '('
                             || I.COLUMN_NAME
                             || ') COMPRESS';
        EXCEPTION
            WHEN OTHERS
            THEN
                DBMS_OUTPUT.PUT_LINE (
                       I.INDEX_NAME
                    || ' index on '
                    || I.TABLE_NAME
                    || '('
                    || I.COLUMN_NAME
                    || ') creation. Error: '
                    || SQLERRM);
        END;
    END LOOP;
END;