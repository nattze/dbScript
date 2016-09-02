CREATE OR REPLACE PACKAGE BODY P_STD_CLMNO AS
/******************************************************************************
   NAME:       P_STD_CLMNO
   PURPOSE:     For manage new Claim Number Format 
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/08/2016      2702       1. Created this package.
******************************************************************************/

    FUNCTION split_clm_num(v_clm_no IN VARCHAR2) RETURN VARCHAR2 IS
    
    BEGIN
        if v_clm_no is not null then
            return substr(v_clm_no ,1,4);
        else
            return null;
        end if;
    END;
    
    FUNCTION split_clm_run(v_clm_no  IN VARCHAR2) RETURN NUMBER  IS
    
    BEGIN
        if v_clm_no is not null then
            return to_number(substr(v_clm_no ,5));
        else
            return 0;
        end if;    
    END;

END P_STD_CLMNO;

/
