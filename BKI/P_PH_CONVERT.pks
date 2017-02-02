CREATE OR REPLACE PACKAGE ALLCLM.P_PH_CONVERT AS
/******************************************************************************
   NAME:       P_PH_CONVERT
   PURPOSE:     สำหรับการ Convert to old table(BKIAPP) และ ส่วนการ post Data
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        1/2/2017      2702       1. Created this package.
******************************************************************************/
    TYPE v_curr IS REF CURSOR;    
    
    FUNCTION VALIDATE_INDV(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ;
    
    FUNCTION POST_ACCTMP(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN;
     
END P_PH_CONVERT;
/

