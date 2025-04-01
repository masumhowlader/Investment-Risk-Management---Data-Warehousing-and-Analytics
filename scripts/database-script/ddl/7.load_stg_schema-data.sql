CREATE OR REPLACE PROCEDURE INV_RISK_MGMT_SOURCE.LOAD_STG_SCHEMA
AS
BEGIN
    STAGING_TABLE_SCRIPT;

    INSERT INTO STG_BRANCHES (BRANCH_NAME,
                              BRANCH_ZONE,
                              DISTRICT,
                              THANA,
                              BRANCH_ID)
        SELECT TRANSFORM_TEXT (BRANCH_NAME,
                               'I',
                               'ID,HO,DFS,IBW,ATM,ABD,ICT,SME,FAD,FTPD,VIP'),
               INITCAP (
                   CASE
                       WHEN BRANCH_ZONE IS NULL
                       THEN
                           'UNKNOWN ZONE'
                       WHEN TRIM (BRANCH_ZONE) LIKE '% ZONE'
                       THEN
                           TRIM (BRANCH_ZONE)
                       ELSE
                           TRIM (BRANCH_ZONE) || ' ZONE'
                   END),
               INITCAP (
                   CASE
                       WHEN DISTRICT IS NULL
                       THEN
                           'UNKNOWN'
                       WHEN UPPER (DISTRICT) IN ('BARGUNA', 'BARGONA')
                       THEN
                           'BARGUNA'
                       WHEN UPPER (DISTRICT) IN ('BOGRA', 'BOGURA')
                       THEN
                           'BOGURA'
                       WHEN UPPER (DISTRICT) IN ('COMILLA', 'CUMILLA')
                       THEN
                           'CUMILLA'
                       WHEN UPPER (DISTRICT) IN ('GAJIPUR', 'GAZIPUR')
                       THEN
                           'GAZIPUR'
                       WHEN UPPER (DISTRICT) IN ('MUNSHIGANJ', 'MUNSHIGONJ')
                       THEN
                           'MUNSHIGANJ'
                       WHEN UPPER (DISTRICT) IN
                                ('NARAYANGANJ', 'NARAYANGONJ')
                       THEN
                           'NARAYANGANJ'
                       WHEN UPPER (DISTRICT) IN ('NARSHINGDI', 'NARSINGDI')
                       THEN
                           'NARSINGDI'
                       WHEN UPPER (DISTRICT) IN
                                ('B. BARIA', 'B.BARIA', 'BRAHMONBARIA')
                       THEN
                           'BRAHMANBARIA'
                       WHEN UPPER (DISTRICT) IN
                                ('CHATTOGRAM', 'CHATTOGRAM.', 'CHITTAGONG')
                       THEN
                           'CHATTOGRAM'
                       WHEN UPPER (DISTRICT) IN
                                ('COX''S BAZAR', 'COXBAZAR', 'COXS BAZAR')
                       THEN
                           'COX''S BAZAR'
                       WHEN UPPER (DISTRICT) IN ('JHALAKATHI')
                       THEN
                           'JHALOKATHI'
                       WHEN UPPER (DISTRICT) IN ('CHAPAI NAWABGANJ')
                       THEN
                           'CHAPAINAWABGANJ'
                       WHEN UPPER (DISTRICT) IN ('GHAIBANDHA')
                       THEN
                           'GAIBANDHA'
                       WHEN UPPER (DISTRICT) IN ('HABIGONJ')
                       THEN
                           'HOBIGANJ'
                       WHEN UPPER (DISTRICT) IN ('JHENAIDAH')
                       THEN
                           'JINAIDAHA'
                       WHEN UPPER (DISTRICT) IN ('KHAGRACHORI')
                       THEN
                           'KHAGRACHHARI'
                       WHEN UPPER (DISTRICT) IN ('KISHORGONJ')
                       THEN
                           'KISHOREGANJ'
                       WHEN UPPER (DISTRICT) IN ('KUSHTIA')
                       THEN
                           'KUSTIA'
                       WHEN UPPER (DISTRICT) IN ('MANIKGONJ')
                       THEN
                           'MANIKGANJ'
                       WHEN UPPER (DISTRICT) IN ('NETROKONA')
                       THEN
                           'NETRAKONA'
                       WHEN UPPER (DISTRICT) IN ('RAZSHAHI')
                       THEN
                           'RAJSHAHI'
                       WHEN UPPER (DISTRICT) IN ('SIRAJGONG')
                       THEN
                           'SIRAJGANJ'
                       WHEN UPPER (DISTRICT) IN ('LAXMIPUR')
                       THEN
                           'LAKSHMIPUR'
                       ELSE
                           UPPER (DISTRICT)
                   END),
               INITCAP (
                   CASE WHEN DISTRICT IS NULL THEN 'UNKNOWN' ELSE THANA END),
               BRANCH_ID
          FROM SRC_BRANCHES;

    COMMIT;

    -------------------------------------------------------------
    
    INSERT INTO STG_THANAS (DISTRICT_ID, THANA_ID, THANA_TITLE)
        SELECT DISTRICT_ID, THANA_ID, TRANSFORM_TEXT (THANA_TITLE)
          FROM SRC_THANAS;

    COMMIT;

    -------------------------------------------------------------
    
    INSERT INTO STG_DISTRICTS (DISTRICT_ID, DISTRICT_TITLE, DIVISION_ID)
        SELECT DISTRICT_ID, INITCAP (DISTRICT_TITLE), DIVISION_ID
          FROM SRC_DISTRICTS
         WHERE DIVISION_ID IS NOT NULL;

    COMMIT;

    -------------------------------------------------------------
    
    INSERT INTO STG_DIVISIONS (DIVISION_ID, DIVISION_NAME)
        SELECT DIVISION_ID, DIVISION_NAME FROM SRC_DIVISIONS;

    COMMIT;

    -------------------------------------------------------------
    
    INSERT INTO STG_PRODUCTS (ID,
                              PRODUCT_CODE,
                              PRODUCT_NAME,
                              INV_MODE,
                              SECTOR_CODE,
                              IS_CHARGE_APPLICABLE_ON_ACC,
                              IS_INSTALLMENT,
                              IS_QUARD_ON_DEP_ACC,
                              IS_PROFIT_REALIZED_AS_RENT,
                              IS_BILLS,
                              IS_LC_REQUIRED,
                              FPLOANCATEGORYCODE,
                              IS_STAFF_ACC,
                              CIBCODE,
                              FPCIBCONTACT)
        SELECT ID,
               PRODUCT_CODE,
               TRANSFORM_TEXT (
                   PRODUCT_NAME,
                   'I',
                   'SSBF,BTB,BD,QSF,PF,GSIS,ARDP,CIS,MEF,MEIS,RAIS,SEF,SMEF,MPI,DP,BB,EPZ,SIS,CMSME,TR,SEIS,TDR,MDB,PIS,CF,DDIS,MMIS,QIBP,IBN,FBN,MEB,SHBS,LC,PG,WES,FBP,DA,DP,RE',
                   'to,for,frm,from,by,of'),
               INV_MODE,
               SECTOR_CODE,
               IS_CHARGE_APPLICABLE_ON_ACC,
               IS_INSTALLMENT,
               NVL (IS_QUARD_ON_DEP_ACC, 0),
               IS_PROFIT_REALIZED_AS_RENT,
               IS_BILLS,
               IS_LC_REQUIRED,
               FPLOANCATEGORYCODE,
               NVL (IS_STAFF_ACC, 0),
               CIBCODE,
               FPCIBCONTACT
          FROM SRC_PRODUCTS
         WHERE ID NOT IN (188, 202);

    COMMIT;

    -------------------------------------------------------------
    
    INSERT INTO STG_CUSTOMER_TYPES (CUSTOMER_TYPE_ID,
                                    CUSTOMER_TYPE,
                                    DESCRIPTION)
        SELECT CUSTOMER_TYPE_ID, CUSTOMER_TYPE, DESCRIPTION
          FROM SRC_CUSTOMER_TYPES;

    COMMIT;

    -------------------------------------------------------------
    
    INSERT INTO STG_CUSTOMERS (CUSTOMER_ID,
                               CUSTOMER_CATEGORY_ID,
                               CUSTOMER_NAME,
                               CUSTOMER_SECTOR_TYPE,
                               SECTOR_CODE,
                               CUSTOMER_RISK_LEVEL)
        SELECT CUSTOMER_ID,
               CUSTOMER_CATEGORY_ID,
               TRIM (CUSTOMER_NAME)     CUSTOMER_NAME,
               CUSTOMER_SECTOR_TYPE,
               SECTOR_CODE,
               CUSTOMER_RISK_LEVEL
          FROM (SELECT CUSTOMER_ID,
                       CUSTOMER_CATEGORY_ID,
                       TRIM (CUSTOMER_NAME)                 CUSTOMER_NAME,
                       CUSTOMER_SECTOR_TYPE,
                       SECTOR_CODE,
                       CUSTOMER_RISK_LEVEL,
                       ROW_NUMBER ()
                           OVER (PARTITION BY CUSTOMER_ID
                                 ORDER BY CUSTOMER_NAME)    RNK
                  FROM SRC_CUSTOMERS)
         WHERE RNK = 1;

    COMMIT;


    -------------------------------------------------------------
    
    INSERT INTO STG_BUSINESS_UNITS (BUSINESS_UNIT_ID, BUSINESS_UNIT_NAME)
        SELECT BUSINESS_UNIT_ID, BUSINESS_UNIT_NAME FROM SRC_BUSINESS_UNITS;

    COMMIT;

    -------------------------------------------------------------
    
    INSERT INTO STG_SECTORS (ID,
                             PARENT_ID,
                             GROUP_ID,
                             ECOCODE_LEVEL,
                             ECOCODE,
                             ECODESCRIPTION,
                             ISSHORTLISTED,
                             ELIGIBLE_OWNER,
                             SHOW_IN_REPORT)
        SELECT ID,
               PARENT_ID,
               GROUP_ID,
               ECOCODE_LEVEL,
               ECOCODE,
               TRANSFORM_TEXT (
                   ECODESCRIPTION,
                   'I',
                   'LIM,CC,TR,TV,EPZ,PC,ECC,LTR,PF,DPS,MSS,FDR,MBS,DBS,OD,NGO,NBFI',
                   'for,of,against,in,etc,and,to,or,by,than,including')
                   ECODESCRIPTION,
               ISSHORTLISTED,
               ELIGIBLE_OWNER,
               SHOW_IN_REPORT
          FROM SRC_SECTORS;

    INSERT INTO STG_SECTORS (ID,
                             PARENT_ID,
                             GROUP_ID,
                             ECOCODE_LEVEL,
                             ECOCODE,
                             ECODESCRIPTION,
                             ISSHORTLISTED,
                             ELIGIBLE_OWNER,
                             SHOW_IN_REPORT)
         VALUES (-1,                     -- Unique ID for the "Unknown" sector
                 NULL,                              -- No parent for "Unknown"
                 NULL,                               -- No group for "Unknown"
                 0,                                           -- Default level
                 '0000',                                -- Placeholder ECOCODE
                 'Unknown Sector',                              -- Description
                 0,                                         -- Not shortlisted
                 0,                                      -- Not eligible owner
                 0                                     -- Not shown in reports
                  );

    COMMIT;

    -------------------------------------------------------------
    
    INSERT INTO STG_BBSECTORINFO (ID,
                                  SECTOR_CODE,
                                  DESCRIPTION,
                                  ISSHORTLISTED,
                                  SECTOR_TYPE_ID)
        SELECT ID,
               SECTOR_CODE,
               TRANSFORM_TEXT (
                   DESCRIPTION,
                   'I',
                   'NGO,PDB,NRI,CA,BTCL,EPZ,BFRI,BTRI,ARI,BSRTI,BIBM,BHPI,RARD,BITAC,APSCL,NWPGC,BITT,BIDS,BIISS,BIM,ICAB,ICMA,NIMCO,BRDTI,MTTI,BFTI,BKSP,BANSDOC,CPP,PKSF,PSCL,EGCB,SWPGC,WZPDCL,DPDCL,PGCB,RPCL,TV,CNG,BRAC,ASA,PROSHIKA,DSE,CSE,BG,VDP,RAB,DGFI,LGED,BIWTC,DESA,BTRC,BERC,BEPZA,MRA,NTRCA,IDRA,BRTA,LATC,BARC,NSC,BCC,SPARRSO,BOESEL,BD,BIWTA,HBFC,SABINCO,DESCO,NBDC,ICB,RAJUK,BRDB,WARPO,NIPSOM,NIDCH,NITOR,NAEP,NAEM,NACTAR,BJRI,BSRI',
                   'of,and,etc,is,as,in'),
               ISSHORTLISTED,
               SECTOR_TYPE_ID
          FROM SRC_BBSECTORINFO;

    COMMIT;

    -------------------------------------------------------------
    
    INSERT INTO STG_CL_CATEGORIES (ID, CL_CODE, DESCRIPTION)
        SELECT ID, CL_CODE, DESCRIPTION FROM SRC_CL_CATEGORIES;

    COMMIT;

    -------------------------------------------------------------
    
    INSERT INTO STG_MONTHLY_ACCOUNT_BALANCES (PROCESS_DATE,
                                              CUSTOMER_ID,
                                              CUSTOMER_NAME,
                                              ACC_BRANCH_ID,
                                              ACCOUNT_NO,
                                              PRODUCT_CODE,
                                              OPEN_DATE,
                                              CLOSE_DATE,
                                              EXPIRY_DATE,
                                              ACCOUNT_STATUS,
                                              IS_INSTALLMENT,
                                              ACC_EMI_SIZE,
                                              NO_OF_INSTALLMENT,
                                              OUTSTANDING_NO_OF_INSTALLMENT,
                                              ECONOMIC_CODE,
                                              SECTOR_CODE,
                                              SUB_SECTOR_CODE,
                                              SBS_CODE,
                                              ACC_PROFIT_RATE,
                                              INV_AMOUNT,
                                              OUTSTANDING_BALANCE,
                                              PRINCIPAL_BALANCE,
                                              TOTAL_RECOVERY,
                                              CL_STATUS,
                                              CUSTOMER_GROUP_ID,
                                              CL_CODE,
                                              SUB_CL_CODE,
                                              BBSECTORCODE,
                                              BUSINESS_UNIT)
        SELECT PROCESS_DATE,
               CUSTOMER_ID,
               CUSTOMER_NAME,
               ACC_BRANCH_ID,
               ACCOUNT_NO,
               PRODUCT_CODE,
               OPEN_DATE,
               CLOSE_DATE,
               EXPIRY_DATE,
               ACCOUNT_STATUS,
               IS_INSTALLMENT,
               ACC_EMI_SIZE,
               NO_OF_INSTALLMENT,
               OUTSTANDING_NO_OF_INSTALLMENT,
               NVL (ECONOMIC_CODE, '0000')     AS ECONOMIC_CODE,
               SECTOR_CODE,
               SUB_SECTOR_CODE,
               SBS_CODE,
               ACC_PROFIT_RATE,
               INV_AMOUNT,
               OUTSTANDING_BALANCE,
               PRINCIPAL_BALANCE,
               TOTAL_RECOVERY,
               NVL(CL_STATUS,'STD') AS CL_STATUS,
               CUSTOMER_GROUP_ID,
               CL_CODE,
               SUB_CL_CODE,
               BBSECTORCODE,
               BUSINESS_UNIT
          FROM SRC_MONTHLY_ACCOUNT_BALANCES B
         /*WHERE     EXISTS
                       (SELECT 1
                          FROM SRC_CUSTOMERS C
                         WHERE B.CUSTOMER_ID = C.CUSTOMER_ID)*/
                         ;

    COMMIT;
END;
/