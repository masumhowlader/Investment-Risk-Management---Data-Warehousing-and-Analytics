CREATE OR REPLACE FUNCTION INV_RISK_MGMT_SOURCE.TRANSFORM_TEXT (
    PTEXT            VARCHAR2,
    PTRANSFORMTYPE   VARCHAR2 DEFAULT 'I',
    PUPPER_TEXT      VARCHAR2 DEFAULT NULL,
    PLOWER_TEXT      VARCHAR2 DEFAULT NULL,
    PINITCAP_TEXT    VARCHAR2 DEFAULT NULL,
    PASITIS_TEXT     VARCHAR2 DEFAULT NULL)
    RETURN VARCHAR2
IS
    LTEXT            VARCHAR2 (500);
    LTRANSFORMTYPE   VARCHAR2 (1);
BEGIN
    IF UPPER (PTRANSFORMTYPE) IN ('I', 'INIT', 'INITCAP')
    THEN
        LTEXT := INITCAP (PTEXT);
        LTRANSFORMTYPE := 'I';
    ELSIF UPPER (PTRANSFORMTYPE) IN ('U', 'UPPER', 'UP')
    THEN
        LTEXT := UPPER (PTEXT);
        LTRANSFORMTYPE := 'U';
    ELSIF UPPER (PTRANSFORMTYPE) IN ('L', 'LOWER', 'LOW')
    THEN
        LTEXT := LOWER (PTEXT);
        LTRANSFORMTYPE := 'L';
    ELSIF UPPER (NVL (PTRANSFORMTYPE, 'AS-IT-IS')) IN
              ('AS-IT-IS', 'SAME', 'AS')
    THEN
        LTEXT := PTEXT;
        LTRANSFORMTYPE := 'A';
    END IF;

    IF PUPPER_TEXT IS NOT NULL AND LTRANSFORMTYPE <> 'U'
    THEN
        FOR UPTEXT
            IN (    SELECT REGEXP_SUBSTR (PUPPER_TEXT,
                                          '[^,]+',
                                          1,
                                          LEVEL)    AS VALUE
                      FROM DUAL
                CONNECT BY LEVEL <= REGEXP_COUNT (PUPPER_TEXT, ',') + 1)
        LOOP
            -- Use word boundaries to match the specific word
            LTEXT :=
                REGEXP_REPLACE (
                    LTEXT,
                       '(^|[^a-zA-Z])('
                    || REGEXP_REPLACE (UPTEXT.VALUE,
                                       '([\\.*+?^$|(){}\[\]])',
                                       '\\\1')
                    || ')([^a-zA-Z]|$)',
                    '\1' || UPPER (UPTEXT.VALUE) || '\3',
                    1,
                    0,
                    'i');
        END LOOP;
    END IF;

    -- Replace words in the lowercase list
    IF PLOWER_TEXT IS NOT NULL AND LTRANSFORMTYPE <> 'L'
    THEN
        FOR LOWERTEXT
            IN (    SELECT REGEXP_SUBSTR (PLOWER_TEXT,
                                          '[^,]+',
                                          1,
                                          LEVEL)    AS VALUE
                      FROM DUAL
                CONNECT BY LEVEL <= REGEXP_COUNT (PLOWER_TEXT, ',') + 1)
        LOOP
            -- Use word boundaries to match the specific word
            LTEXT :=
                REGEXP_REPLACE (
                    LTEXT,
                       '(^|[^a-zA-Z])('
                    || REGEXP_REPLACE (LOWERTEXT.VALUE,
                                       '([\\.*+?^$|(){}\[\]])',
                                       '\\\1')
                    || ')([^a-zA-Z]|$)',
                    '\1' || LOWER (LOWERTEXT.VALUE) || '\3',
                    1,
                    0,
                    'i');
        END LOOP;
    END IF;

    IF PINITCAP_TEXT IS NOT NULL AND LTRANSFORMTYPE <> 'I'
    THEN
        FOR LINITCAPTEXT
            IN (    SELECT REGEXP_SUBSTR (PINITCAP_TEXT,
                                          '[^,]+',
                                          1,
                                          LEVEL)    AS VALUE
                      FROM DUAL
                CONNECT BY LEVEL <= REGEXP_COUNT (PINITCAP_TEXT, ',') + 1)
        LOOP
            LTEXT :=
                REGEXP_REPLACE (
                    LTEXT,
                       '(^|[^a-zA-Z])('
                    || REGEXP_REPLACE (LINITCAPTEXT.VALUE,
                                       '([\\.*+?^$|(){}\[\]])',
                                       '\\\1')
                    || ')([^a-zA-Z]|$)',
                    '\1' || LOWER (LINITCAPTEXT.VALUE) || '\3',
                    1,
                    0,
                    'i');
        END LOOP;
    END IF;

    IF PASITIS_TEXT IS NOT NULL AND LTRANSFORMTYPE <> 'A'
    THEN
        FOR LASITISTEXT
            IN (    SELECT REGEXP_SUBSTR (PASITIS_TEXT,
                                          '[^,]+',
                                          1,
                                          LEVEL)    AS VALUE
                      FROM DUAL
                CONNECT BY LEVEL <= REGEXP_COUNT (PASITIS_TEXT, ',') + 1)
        LOOP
            LTEXT :=
                REGEXP_REPLACE (
                    LTEXT,
                       '(^|[^a-zA-Z])('
                    || REGEXP_REPLACE (LASITISTEXT.VALUE,
                                       '([\\.*+?^$|(){}\[\]])',
                                       '\\\1')
                    || ')([^a-zA-Z]|$)',
                    '\1' || LOWER (LASITISTEXT.VALUE) || '\3',
                    1,
                    0,
                    'i');
        END LOOP;
    END IF;

    RETURN LTEXT;
END;
/