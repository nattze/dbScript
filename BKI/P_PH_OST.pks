CREATE OR REPLACE PACKAGE P_PH_OST AS
/******************************************************************************
   NAME:       P_PH_OST
   PURPOSE:     For Manage Ost Claim Data
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/4/2017      2702       1. Created this package.
******************************************************************************/
    TYPE v_curr IS REF CURSOR;    
    
    FUNCTION CAN_OPEN_CLAIM(v_notno  IN VARCHAR2 ,o_RST OUT VARCHAR2) RETURN BOOLEAN; 
    
    PROCEDURE GET_OSTCLM(v_date IN DATE ,v_notno IN VARCHAR2 ,v_user IN VARCHAR2 ,o_RST OUT VARCHAR2);
    
    PROCEDURE OPEN_CLM(v_date IN DATE ,v_notno IN VARCHAR2 ,v_user IN VARCHAR2 ,o_RST OUT VARCHAR2); 
    
    PROCEDURE REVISE_CLM(v_date IN DATE ,v_notno IN VARCHAR2 ,v_user IN VARCHAR2 ,o_RST OUT VARCHAR2); 
    
    FUNCTION genRI_RES(v_stskey IN NUMBER ,v_clmno IN VARCHAR2 ,v_amt IN NUMBER) RETURN VARCHAR2;
    
    PROCEDURE GET_OSTPAYEE_DETAIL(v_clmno IN VARCHAR2 ,v_payee_name IN VARCHAR2 ,v_hos_flag IN VARCHAR2 ,v_hosp_code IN VARCHAR2
     , o_payee_code OUT VARCHAR2 ,o_payee_seq OUT VARCHAR2 ,o_payee_type OUT VARCHAR2 , o_payee_name OUT VARCHAR2 ,o_hosp_id   OUT VARCHAR2
     , o_contact_name OUT VARCHAR2 , o_addr1 OUT VARCHAR2  , o_addr2 OUT VARCHAR2  , o_mobile OUT VARCHAR2  , o_email OUT VARCHAR2
     ,o_agent_mobile  OUT VARCHAR2 ,o_agent_email  OUT VARCHAR2 ,o_paidto OUT VARCHAR2
     ,o_acc_no  out varchar2, o_acc_name_th out varchar2,  o_acc_name_en  out varchar2, o_bank_code  out varchar2, o_bank_br_code  out varchar2, o_deposit out varchar2) ;

    FUNCTION SET_CLMUSER(v_batch in VARCHAR2 ,v_user in VARCHAR2 ,v_rst out VARCHAR2) RETURN NUMBER   ;  -- 0 ,1 
    
    FUNCTION SET_CLMUSER_ByCLM(v_clmno in VARCHAR2 ,v_user in VARCHAR2 ,v_rst out VARCHAR2) RETURN NUMBER   ;  -- 0 ,1 
    
    PROCEDURE GET_BATCH_STATUS(v_batch in VARCHAR2 ,V_STS out varchar2) ; -- N = Not Open,Y = Open/Draft ,P = Paid,S = Print statement,C = cwp
    
    FUNCTION FIX_BATCH_PAYEE(v_batch in VARCHAR2 ,v_clmno in VARCHAR2 ,v_user in VARCHAR2 
     , v_payee_code IN VARCHAR2 ,v_payee_seq IN VARCHAR2 ,v_payee_type IN VARCHAR2 , v_payee_name IN VARCHAR2 
     , v_contact_name IN VARCHAR2 , v_addr1 IN VARCHAR2  , v_addr2 IN VARCHAR2  , v_mobile IN VARCHAR2  , v_email IN VARCHAR2
     ,v_agent_mobile  IN VARCHAR2 ,v_agent_email  IN VARCHAR2 ,v_paidto IN VARCHAR2
     ,v_acc_no  IN varchar2, v_acc_name_th IN varchar2,  v_acc_name_en  IN varchar2, v_bank_code  IN varchar2, v_bank_br_code  IN varchar2, v_settle IN varchar2
     ,o_rst out VARCHAR2) RETURN NUMBER ; --0 false ,1 true 
END P_PH_OST;

/
