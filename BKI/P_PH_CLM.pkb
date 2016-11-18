CREATE OR REPLACE PACKAGE BODY P_PH_CLM AS
/******************************************************************************
   NAME:       P_PH_CLM
   PURPOSE:     สำหรับ Projetc PH system
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        18/11/2016      2702       1. Created this package.
******************************************************************************/
    TYPE v_curr IS REF CURSOR;    

    FUNCTION mapp_benecode(v_bill IN VARCHAR2) RETURN VARCHAR2 IS
    
    BEGIN
    
        return v_bill;
    END mapp_benecode;
    
    
END P_PH_CLM;

/