CREATE OR REPLACE PACKAGE P_STD_CLMNO AS
/******************************************************************************
   NAME:       P_STD_CLMNO
   PURPOSE:     For manage new Claim Number Format 
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/08/2016      2702       1. Created this package.
******************************************************************************/

    FUNCTION split_clm_num(v_clm_no IN VARCHAR2) RETURN VARCHAR2 ;
    
    FUNCTION split_clm_run(v_clm_no  IN VARCHAR2) RETURN NUMBER ;

END P_STD_CLMNO;

/