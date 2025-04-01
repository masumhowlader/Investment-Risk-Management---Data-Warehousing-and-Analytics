CREATE TABLE TEMP_FIRST_NAMES
AS
    SELECT COLUMN_VALUE     AS FIRST_NAME
      FROM TABLE (SYS.ODCIVARCHAR2LIST (                      -- Western Names
                                        'John',
                                        'Michael',
                                        'David',
                                        'James',
                                        'Robert',
                                        'William',
                                        'Joseph',
                                        'Daniel',
                                        'Matthew',
                                        'Andrew',
                                        'Thomas',
                                        'Mark',
                                        'Anthony',
                                        'Joshua',
                                        'Christopher',
                                        'Nicholas',
                                        'Benjamin',
                                        'Alexander',
                                        'Samuel',
                                        'Jacob',
                                        'Ethan',
                                        'Henry',
                                        'Leo',
                                        'Ryan',
                                        'Jack',
                                        'Mason',
                                        'Owen',
                                        'Julian',
                                        'Nathan',
                                        'Dylan',
                                        -- Female Western Names
                                        'Emily',
                                        'Sophia',
                                        'Olivia',
                                        'Emma',
                                        'Ava',
                                        'Charlotte',
                                        'Amelia',
                                        'Mia',
                                        'Harper',
                                        'Evelyn',
                                        'Abigail',
                                        'Ella',
                                        'Scarlett',
                                        'Lily',
                                        'Madison',
                                        'Grace',
                                        'Victoria',
                                        'Chloe',
                                        'Isabella',
                                        'Lucy',
                                        -- Asian Names
                                        'Chen',
                                        'Wei',
                                        'Zhang',
                                        'Hao',
                                        'Lin',
                                        'Tian',
                                        'Jin',
                                        'Yuan',
                                        'Liang',
                                        'Jia',
                                        'Xia',
                                        'Hui',
                                        'Lei',
                                        'Takashi',
                                        'Haruto',
                                        'Satoshi',
                                        'Yuki',
                                        'Kenji',
                                        'Taro',
                                        'Akira',
                                        'Hiroshi',
                                        'Ryu',
                                        'Minato',
                                        -- Arabic Names
                                        'Omar',
                                        'Ali',
                                        'Ahmed',
                                        'Mohamed',
                                        'Youssef',
                                        'Hassan',
                                        'Karim',
                                        'Tariq',
                                        'Sami',
                                        'Ibrahim',
                                        'Fatima',
                                        'Aisha',
                                        'Hana',
                                        'Layla',
                                        'Zainab',
                                        'Mariam',
                                        'Nour',
                                        'Khadija',
                                        'Salma',
                                        'Rania'));

CREATE TABLE TEMP_LAST_NAMES
AS
    SELECT COLUMN_VALUE     AS LAST_NAME
      FROM TABLE (SYS.ODCIVARCHAR2LIST (                 -- Western Last Names
                                        'Smith',
                                        'Johnson',
                                        'Brown',
                                        'White',
                                        'Miller',
                                        'Davis',
                                        'Moore',
                                        'Anderson',
                                        'Thomas',
                                        'Harris',
                                        'Clark',
                                        'Lewis',
                                        'Walker',
                                        'Young',
                                        'King',
                                        'Wright',
                                        'Hill',
                                        'Baker',
                                        'Carter',
                                        'Mitchell',
                                        -- Asian Last Names
                                        'Chen',
                                        'Wang',
                                        'Zhang',
                                        'Liu',
                                        'Huang',
                                        'Lin',
                                        'Li',
                                        'Zhao',
                                        'Xu',
                                        'Yang',
                                        'Guo',
                                        'Wu',
                                        'Deng',
                                        'Tang',
                                        'Takahashi',
                                        'Kobayashi',
                                        'Tanaka',
                                        'Matsumoto',
                                        'Ishikawa',
                                        'Nakamura',
                                        'Fujiwara',
                                        'Sato',
                                        'Ota',
                                        'Shimizu',
                                        -- Arabic Last Names
                                        'Al-Farsi',
                                        'Haddad',
                                        'Al-Mohammed',
                                        'Zayed',
                                        'Rahman',
                                        'Khan',
                                        'Al-Farooq',
                                        'Nasir',
                                        'Al-Mansour',
                                        'Jabari',
                                        'Darwish',
                                        'Zain',
                                        'Mustafa',
                                        'El-Sayed',
                                        'Fahmy',
                                        'Younis',
                                        'Hussein',
                                        'Sharif',
                                        'Amin',
                                        'Qureshi'));


DECLARE
    TYPE T_CUSTOMER_ID IS TABLE OF SRC_CUSTOMERS.CUSTOMER_ID%TYPE;

    V_CUSTOMER_IDS   T_CUSTOMER_ID;
BEGIN
    SELECT DISTINCT CUSTOMER_ID
      BULK COLLECT INTO V_CUSTOMER_IDS
      FROM SRC_MONTHLY_ACCOUNT_BALANCES B
     WHERE NOT EXISTS
               (SELECT 1
                  FROM SRC_CUSTOMERS C
                 WHERE B.CUSTOMER_ID = C.CUSTOMER_ID);

    FORALL I IN 1 .. V_CUSTOMER_IDS.COUNT
        INSERT INTO SRC_CUSTOMERS (CUSTOMER_ID)         -- Mention all columns
             VALUES (V_CUSTOMER_IDS (I));

    COMMIT;
END;


DECLARE
    TYPE T_FIRST_NAME IS TABLE OF TEMP_FIRST_NAMES.FIRST_NAME%TYPE;

    TYPE T_LAST_NAME IS TABLE OF TEMP_LAST_NAMES.LAST_NAME%TYPE;

    V_FIRST_NAMES                T_FIRST_NAME;
    V_LAST_NAMES                 T_LAST_NAME;
    V_CUSTOMER_NAME              VARCHAR2 (200);

    -- Constants for probabilities
    C_MID_NAME_PROB     CONSTANT NUMBER := 0.5;  -- 50% chance for middle name
    C_MID2_NAME_PROB    CONSTANT NUMBER := 0.3; -- 30% chance for second middle name
    C_LAST2_NAME_PROB   CONSTANT NUMBER := 0.3; -- 30% chance for second last name
BEGIN
      -- Step 1: Pre-fetch random first and last names into collections
      SELECT FIRST_NAME
        BULK COLLECT INTO V_FIRST_NAMES
        FROM TEMP_FIRST_NAMES
    ORDER BY DBMS_RANDOM.VALUE
       FETCH FIRST 1000 ROWS ONLY;               -- ADJUST THE LIMIT AS NEEDED

      SELECT LAST_NAME
        BULK COLLECT INTO V_LAST_NAMES
        FROM TEMP_LAST_NAMES
    ORDER BY DBMS_RANDOM.VALUE
       FETCH FIRST 1000 ROWS ONLY;               -- ADJUST THE LIMIT AS NEEDED

    -- STEP 2: LOOP THROUGH SRC_CUSTOMERS AND UPDATE CUSTOMER NAMES
    FOR I IN (SELECT CUSTOMER_ID FROM SRC_CUSTOMERS)
    LOOP
        DECLARE
            V_RANDOM_FIRST_NAME   VARCHAR2 (200);
            V_RANDOM_MID_NAME     VARCHAR2 (200);
            V_RANDOM_MID2_NAME    VARCHAR2 (200);
            V_RANDOM_LAST_NAME    VARCHAR2 (200);
            V_RANDOM_LAST2_NAME   VARCHAR2 (200);
            V_INDEX               NUMBER;
        BEGIN
            -- RANDOM FIRST NAME
            V_INDEX := TRUNC (DBMS_RANDOM.VALUE (1, V_FIRST_NAMES.COUNT + 1));
            V_RANDOM_FIRST_NAME := V_FIRST_NAMES (V_INDEX);

            -- OPTIONAL MIDDLE NAMES
            IF DBMS_RANDOM.VALUE < C_MID_NAME_PROB
            THEN
                V_INDEX :=
                    TRUNC (DBMS_RANDOM.VALUE (1, V_FIRST_NAMES.COUNT + 1));
                V_RANDOM_MID_NAME := V_FIRST_NAMES (V_INDEX);
            ELSE
                V_RANDOM_MID_NAME := NULL;
            END IF;

            IF DBMS_RANDOM.VALUE < C_MID2_NAME_PROB
            THEN
                V_INDEX :=
                    TRUNC (DBMS_RANDOM.VALUE (1, V_FIRST_NAMES.COUNT + 1));
                V_RANDOM_MID2_NAME := V_FIRST_NAMES (V_INDEX);
            ELSE
                V_RANDOM_MID2_NAME := NULL;
            END IF;

            -- RANDOM LAST NAME
            V_INDEX := TRUNC (DBMS_RANDOM.VALUE (1, V_LAST_NAMES.COUNT + 1));
            V_RANDOM_LAST_NAME := V_LAST_NAMES (V_INDEX);

            -- OPTIONAL SECONDARY LAST NAME
            IF DBMS_RANDOM.VALUE < C_LAST2_NAME_PROB
            THEN
                V_INDEX :=
                    TRUNC (DBMS_RANDOM.VALUE (1, V_LAST_NAMES.COUNT + 1));
                V_RANDOM_LAST2_NAME := V_LAST_NAMES (V_INDEX);
            ELSE
                V_RANDOM_LAST2_NAME := NULL;
            END IF;

            -- CONCATENATE NAMES WITH PROPER SPACING
            V_CUSTOMER_NAME :=
                TRIM (
                       V_RANDOM_FIRST_NAME
                    || CASE
                           WHEN V_RANDOM_MID_NAME IS NOT NULL
                           THEN
                               ' ' || V_RANDOM_MID_NAME
                           ELSE
                               ''
                       END
                    || CASE
                           WHEN V_RANDOM_MID2_NAME IS NOT NULL
                           THEN
                               ' ' || V_RANDOM_MID2_NAME
                           ELSE
                               ''
                       END
                    || ' '
                    || V_RANDOM_LAST_NAME
                    || CASE
                           WHEN V_RANDOM_LAST2_NAME IS NOT NULL
                           THEN
                               ' ' || V_RANDOM_LAST2_NAME
                           ELSE
                               ''
                       END);

            -- UPDATE CUSTOMER NAME
            UPDATE SRC_CUSTOMERS
               SET CUSTOMER_NAME = V_CUSTOMER_NAME
             WHERE CUSTOMER_ID = I.CUSTOMER_ID;
        END;
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;
END;


DECLARE
    TYPE T_CUSTOMER_ID
        IS TABLE OF SRC_MONTHLY_ACCOUNT_BALANCES.CUSTOMER_ID%TYPE;

    TYPE T_CUSTOMER_NAME
        IS TABLE OF SRC_MONTHLY_ACCOUNT_BALANCES.CUSTOMER_NAME%TYPE;

    V_CUSTOMER_IDS     T_CUSTOMER_ID;
    V_CUSTOMER_NAMES   T_CUSTOMER_NAME;

    CURSOR C_MONTHLY_ACCOUNT_BALANCES IS
        SELECT MAB.CUSTOMER_ID, SC.CUSTOMER_NAME
          FROM SRC_MONTHLY_ACCOUNT_BALANCES  MAB
               JOIN SRC_CUSTOMERS SC ON MAB.CUSTOMER_ID = SC.CUSTOMER_ID; ------INDEX CREATION ON SRC_MONTHLY_ACCOUNT_BALANCES(CUSTOMER_ID) AND SRC_CUSTOMERS(CUSTOMER_ID)

    V_BATCH_SIZE       NUMBER := 10000;         -- Adjust batch size as needed
BEGIN
    OPEN C_MONTHLY_ACCOUNT_BALANCES;

    LOOP
        -- Fetch rows in bulk
        FETCH C_MONTHLY_ACCOUNT_BALANCES
            BULK COLLECT INTO V_CUSTOMER_IDS, V_CUSTOMER_NAMES
            LIMIT V_BATCH_SIZE;

        EXIT WHEN V_CUSTOMER_IDS.COUNT = 0;

        -- Update rows in bulk
        FORALL I IN 1 .. V_CUSTOMER_IDS.COUNT
            UPDATE SRC_MONTHLY_ACCOUNT_BALANCES
               SET CUSTOMER_NAME = V_CUSTOMER_NAMES (I)
             WHERE CUSTOMER_ID = V_CUSTOMER_IDS (I);

        COMMIT;                                     -- Commit after each batch
    END LOOP;

    CLOSE C_MONTHLY_ACCOUNT_BALANCES;
EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE ('Error: ' || SQLERRM);
END;
/



CREATE TABLE CUSTOMER_ID_MAPPING
(
    OLD_CUSTOMER_ID    VARCHAR2 (20),
    NEW_CUSTOMER_ID    VARCHAR2 (20)
);

-- Populate the mapping table

INSERT INTO CUSTOMER_ID_MAPPING (OLD_CUSTOMER_ID, NEW_CUSTOMER_ID)
    SELECT CUSTOMER_ID,
           TO_CHAR (ROW_NUMBER () OVER (ORDER BY CUSTOMER_ID) + 10000000)    AS NEW_CUSTOMER_ID
      FROM (SELECT DISTINCT CUSTOMER_ID
              FROM SRC_CUSTOMERS);


DECLARE
    -- Define collection types
    TYPE T_OLD_CUSTOMER_ID IS TABLE OF SRC_CUSTOMERS.CUSTOMER_ID%TYPE;

    TYPE T_NEW_CUSTOMER_ID IS TABLE OF SRC_CUSTOMERS.CUSTOMER_ID%TYPE;

    -- Declare collections
    V_OLD_CUSTOMER_IDS   T_OLD_CUSTOMER_ID;
    V_NEW_CUSTOMER_IDS   T_NEW_CUSTOMER_ID;

    -- Define chunk size
    V_BATCH_SIZE         NUMBER := 10000;

    -- Cursor to fetch data in chunks
    CURSOR C_DATA IS
        SELECT CM.OLD_CUSTOMER_ID, CM.NEW_CUSTOMER_ID
          FROM CUSTOMER_ID_MAPPING CM
         WHERE EXISTS
                   (SELECT 1
                      FROM SRC_CUSTOMERS SC
                     WHERE SC.CUSTOMER_ID = CM.OLD_CUSTOMER_ID);
BEGIN
    OPEN C_DATA;

    LOOP
        -- Fetch data in bulk (chunk size of 10,000)
        FETCH C_DATA
            BULK COLLECT INTO V_OLD_CUSTOMER_IDS, V_NEW_CUSTOMER_IDS
            LIMIT V_BATCH_SIZE;

        EXIT WHEN V_OLD_CUSTOMER_IDS.COUNT = 0; -- Exit when no more rows to process

        -- Perform bulk update using FORALL
        FORALL I IN 1 .. V_OLD_CUSTOMER_IDS.COUNT
            UPDATE SRC_CUSTOMERS
               SET CUSTOMER_ID = V_NEW_CUSTOMER_IDS (I)
             WHERE CUSTOMER_ID = V_OLD_CUSTOMER_IDS (I);

        COMMIT; -- Commit after each chunk to release locks and reduce rollback segment usage

        DBMS_OUTPUT.PUT_LINE (
            'Processed ' || V_OLD_CUSTOMER_IDS.COUNT || ' rows.');
    END LOOP;

    CLOSE C_DATA;

    DBMS_OUTPUT.PUT_LINE ('SRC_CUSTOMERS updated successfully.');
EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;                             -- Rollback in case of any error
        DBMS_OUTPUT.PUT_LINE ('Error updating SRC_CUSTOMERS: ' || SQLERRM);
END;
/

DECLARE
    -- Define collection types
    TYPE T_OLD_CUSTOMER_ID
        IS TABLE OF SRC_MONTHLY_ACCOUNT_BALANCES.CUSTOMER_ID%TYPE;

    TYPE T_NEW_CUSTOMER_ID
        IS TABLE OF SRC_MONTHLY_ACCOUNT_BALANCES.CUSTOMER_ID%TYPE;

    -- Declare collections
    V_OLD_CUSTOMER_IDS   T_OLD_CUSTOMER_ID;
    V_NEW_CUSTOMER_IDS   T_NEW_CUSTOMER_ID;

    -- Define chunk size
    V_BATCH_SIZE         NUMBER := 10000;

    -- Cursor to fetch data in chunks
    CURSOR C_DATA IS
        SELECT CM.OLD_CUSTOMER_ID, CM.NEW_CUSTOMER_ID
          FROM CUSTOMER_ID_MAPPING CM
         WHERE EXISTS
                   (SELECT 1
                      FROM SRC_MONTHLY_ACCOUNT_BALANCES MAB
                     WHERE MAB.CUSTOMER_ID = CM.OLD_CUSTOMER_ID);
BEGIN
    OPEN C_DATA;

    LOOP
        -- Fetch data in bulk (chunk size of 10,000)
        FETCH C_DATA
            BULK COLLECT INTO V_OLD_CUSTOMER_IDS, V_NEW_CUSTOMER_IDS
            LIMIT V_BATCH_SIZE;

        EXIT WHEN V_OLD_CUSTOMER_IDS.COUNT = 0; -- Exit when no more rows to process

        -- Perform bulk update using FORALL
        FORALL I IN 1 .. V_OLD_CUSTOMER_IDS.COUNT
            UPDATE SRC_MONTHLY_ACCOUNT_BALANCES
               SET CUSTOMER_ID = V_NEW_CUSTOMER_IDS (I)
             WHERE CUSTOMER_ID = V_OLD_CUSTOMER_IDS (I);

        COMMIT; -- Commit after each chunk to release locks and reduce rollback segment usage

        DBMS_OUTPUT.PUT_LINE (
            'Processed ' || V_OLD_CUSTOMER_IDS.COUNT || ' rows.');
    END LOOP;

    CLOSE C_DATA;

    DBMS_OUTPUT.PUT_LINE (
        'SRC_MONTHLY_ACCOUNT_BALANCES updated successfully.');
EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;                             -- Rollback in case of any error
        DBMS_OUTPUT.PUT_LINE (
            'Error updating SRC_MONTHLY_ACCOUNT_BALANCES: ' || SQLERRM);
END;
/

    -- Update CUSTOMER_CATEGORY_TYPE_ID for rows where it is 0

UPDATE SRC_CUSTOMERS
   SET CUSTOMER_CATEGORY_TYPE_ID = TRUNC (DBMS_RANDOM.VALUE (1, 5))
 WHERE CUSTOMER_CATEGORY_TYPE_ID = 0;

COMMIT;