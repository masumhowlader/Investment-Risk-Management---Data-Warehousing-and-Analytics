CREATE OR REPLACE PROCEDURE REFRESH_MV
AS
BEGIN
    FOR I IN (SELECT MVIEW_NAME FROM USER_MVIEWS)
    LOOP
        BEGIN
            DBMS_MVIEW.REFRESH (I.MVIEW_NAME, 'COMPLETE');
        EXCEPTION
            WHEN OTHERS
            THEN
                DBMS_OUTPUT.PUT_LINE (
                       I.MVIEW_NAME
                    || ' materialized view refresh. Error: '
                    || SQLERRM);
        END;
    END LOOP;
END;