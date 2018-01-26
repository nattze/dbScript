CREATE OR REPLACE PACKAGE ALLCLM.P_STD_CLMNO AS
/******************************************************************************
 NAME: ALLCLM.P_STD_CLMNO
   PURPOSE:     For manage new Claim Number Format


   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/08/2016      2702       1. Created this package.
******************************************************************************/

    FUNCTION split_clm_num(v_clm_no IN VARCHAR2) RETURN VARCHAR2 ;

    FUNCTION split_clm_run(v_clm_no  IN VARCHAR2) RETURN NUMBER ;

    FUNCTION get_clmyear(v_clm_no IN VARCHAR2) RETURN NUMBER ;

    FUNCTION mask_clmno(v_clm_no IN VARCHAR2) RETURN VARCHAR2 ;

    FUNCTION unmask_clmno(v_clm_no IN VARCHAR2) RETURN VARCHAR2 ;

    PROCEDURE procedure_mask_clmno 
  (   
     in_clm_no       IN varchar2,
     out_detail       OUT sys_refcursor    
  );

    FUNCTION get_prodtype(v_clm_no  IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION mask_clmno_emcs(v_clm_no IN VARCHAR2) RETURN VARCHAR2;
END P_STD_CLMNO;
/

