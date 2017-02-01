CREATE OR REPLACE PACKAGE N_EF_EXAMPLE AS
/******************************************************************************
   NAME:       N_EF_EXAMPLE
   PURPOSE:     For example case to call Store/Function
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/10/2016      2702       1. Created this package.
******************************************************************************/
    TYPE v_curr IS REF CURSOR;    

    FUNCTION func_ret_vc2(v_param1 IN VARCHAR2) RETURN VARCHAR2 ;
    
    FUNCTION func_ret_number(v_param1  IN VARCHAR2) RETURN NUMBER ;
    
    FUNCTION func_ret_boo_out_vc2(v_param1  IN VARCHAR2 ,o_param1 OUT VARCHAR2) RETURN BOOLEAN ;
    
    FUNCTION func_ret_Cursor(v_param1  IN VARCHAR2) RETURN N_EF_EXAMPLE.v_curr;

    FUNCTION getRI_PAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,v_amt IN NUMBER ,O_RI OUT N_EF_EXAMPLE.v_curr) RETURN VARCHAR2 ;
   
    FUNCTION validate_RI_RES(v_clmno IN VARCHAR2) RETURN VARCHAR2 ;
    -- return Null คือผ่าน ,not null คือ มีข้อผิดพลาด
    
    FUNCTION CAN_SEND_APPROVE(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N

    FUNCTION CAN_GO_APPROVE(i_clmno IN varchar2 ,i_payno IN varchar2 ,i_userid IN varchar2 ,i_status IN varchar2 ,i_sys IN VARCHAR2 ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N 
    
    FUNCTION GET_APPROVE_AMT(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN NUMBER;
    
    FUNCTION IS_NEW_PAYMENT(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N

    FUNCTION GEN_RI_PAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2 ,v_amt IN NUMBER  ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N
    
    FUNCTION UPD_PAYMENT_STS(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,v_status IN VARCHAR2 ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N

    FUNCTION GET_USER_LIST (v_user IN VARCHAR2 ,O_USER Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
     
END N_EF_EXAMPLE;

/
