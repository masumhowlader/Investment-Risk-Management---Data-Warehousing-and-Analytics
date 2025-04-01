CREATE OR REPLACE PROCEDURE STAGING_TABLE_SCRIPT
IS
BEGIN
    FOR T IN (SELECT TABLE_NAME
                FROM USER_TABLES
               WHERE TABLE_NAME LIKE 'STG_%')
    LOOP
        BEGIN
            EXECUTE IMMEDIATE   'DROP TABLE '
                             || T.TABLE_NAME
                             || ' CASCADE CONSTRAINTS';
        EXCEPTION
            WHEN OTHERS
            THEN
                DBMS_OUTPUT.PUT_LINE (
                    T.TABLE_NAME || ' table dropping. Error: ' || SQLERRM);
        END;
    END LOOP;

    BEGIN
        EXECUTE IMMEDIATE '
CREATE TABLE STG_BRANCHES
(
    BRANCH_NAME    VARCHAR2 (150 BYTE),
    BRANCH_ZONE    VARCHAR2 (765 BYTE),
    DISTRICT       VARCHAR2 (150 BYTE),
    THANA          VARCHAR2 (150 BYTE),
    BRANCH_ID      VARCHAR2 (10 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
CREATE TABLE STG_THANAS
(
    DISTRICT_ID    NUMBER (5),
    THANA_ID       NUMBER (3),
    THANA_TITLE    VARCHAR2 (50 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
CREATE TABLE STG_DISTRICTS
(
    DISTRICT_ID       NUMBER (3),
    DISTRICT_TITLE    VARCHAR2 (150 BYTE),
    DIVISION_ID       NUMBER
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
CREATE TABLE STG_DIVISIONS
(
    DIVISION_ID      NUMBER,
    DIVISION_NAME    VARCHAR2 (90 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
CREATE TABLE STG_PRODUCTS
(
    ID                             NUMBER,
    PRODUCT_CODE                   VARCHAR2 (15 BYTE),
    PRODUCT_NAME                   VARCHAR2 (750 BYTE),
    INV_MODE                       VARCHAR2 (6 BYTE),
    SECTOR_CODE                    VARCHAR2 (6 BYTE),
    IS_CHARGE_APPLICABLE_ON_ACC    NUMBER,
    IS_INSTALLMENT                 NUMBER,
    IS_QUARD_ON_DEP_ACC            NUMBER (16, 2),
    IS_PROFIT_REALIZED_AS_RENT     NUMBER,
    IS_BILLS                       NUMBER,
    IS_LC_REQUIRED                 NUMBER,
    FPLOANCATEGORYCODE             VARCHAR2 (18 BYTE),
    IS_STAFF_ACC                   NUMBER,
    CIBCODE                        NUMBER (5),
    FPCIBCONTACT                   VARCHAR2 (6 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
CREATE TABLE STG_CUSTOMER_TYPES
(
    CUSTOMER_TYPE_ID    NUMBER (2),
    CUSTOMER_TYPE       VARCHAR2 (40 BYTE),
    DESCRIPTION         VARCHAR2 (500 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
CREATE TABLE STG_CUSTOMERS
(
    CUSTOMER_ID             NUMBER (38),
    CUSTOMER_CATEGORY_ID    NUMBER,
    CUSTOMER_NAME           VARCHAR2 (200 BYTE),
    CUSTOMER_SECTOR_TYPE    NUMBER,
    SECTOR_CODE             VARCHAR2 (10 BYTE),
    CUSTOMER_RISK_LEVEL     VARCHAR2 (30 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
CREATE TABLE STG_BUSINESS_UNITS
(
    BUSINESS_UNIT_ID      NUMBER,
    BUSINESS_UNIT_NAME    VARCHAR2 (255 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
CREATE TABLE STG_SECTORS
(
    ID                NUMBER,
    PARENT_ID         NUMBER,
    GROUP_ID          VARCHAR2 (30 BYTE),
    ECOCODE_LEVEL     NUMBER,
    ECOCODE           NUMBER(4,0),
    ECODESCRIPTION    VARCHAR2 (765 BYTE),
    ISSHORTLISTED     VARCHAR2 (15 BYTE),
    ELIGIBLE_OWNER    NUMBER,
    SHOW_IN_REPORT    VARCHAR2 (1 BYTE) DEFAULT ''N''
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
CREATE TABLE STG_BBSECTORINFO
(
    ID                NUMBER (38),
    SECTOR_CODE       VARCHAR2 (50 BYTE),
    DESCRIPTION       VARCHAR2 (255 BYTE),
    ISSHORTLISTED     VARCHAR2 (5 BYTE),
    SECTOR_TYPE_ID    NUMBER (2)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE STG_CL_CATEGORIES
(
    ID             NUMBER,
    CL_CODE        VARCHAR2 (20 BYTE),
    DESCRIPTION    VARCHAR2 (200 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE STG_MONTHLY_ACCOUNT_BALANCES
(
    PROCESS_DATE                     DATE,
    CUSTOMER_ID                      VARCHAR2 (20 BYTE),
    CUSTOMER_NAME                    VARCHAR2 (500 BYTE),
    ACC_BRANCH_ID                    VARCHAR2 (10 BYTE),
    ACCOUNT_NO                       VARCHAR2 (20 BYTE),
    PRODUCT_CODE                     NUMBER,
    OPEN_DATE                        DATE,
    CLOSE_DATE                       DATE,
    EXPIRY_DATE                      DATE,
    ACCOUNT_STATUS                   VARCHAR2 (20 BYTE),
    IS_INSTALLMENT                   NUMBER,
    ACC_EMI_SIZE                     NUMBER,
    NO_OF_INSTALLMENT                NUMBER,
    OUTSTANDING_NO_OF_INSTALLMENT    NUMBER,
    ECONOMIC_CODE                    NUMBER(4,0),
    SECTOR_CODE                      VARCHAR2 (10 BYTE),
    SUB_SECTOR_CODE                  VARCHAR2 (10 BYTE),
    SBS_CODE                         VARCHAR2 (10 BYTE),
    ACC_PROFIT_RATE                  NUMBER,
    INV_AMOUNT                       NUMBER,
    OUTSTANDING_BALANCE              NUMBER,
    PRINCIPAL_BALANCE                NUMBER,
    TOTAL_RECOVERY                   NUMBER,
    CL_STATUS                        VARCHAR2 (10 BYTE),
    CUSTOMER_GROUP_ID                NUMBER,
    CL_CODE                          VARCHAR2 (20 BYTE),
    SUB_CL_CODE                      VARCHAR2 (20 BYTE),
    BBSECTORCODE                     NUMBER,
    BUSINESS_UNIT                    VARCHAR2 (20 BYTE)
)';
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'SRC_BBSECTORINFO table creation. Error: ' || SQLERRM);
    END;
END;