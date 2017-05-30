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
     
END P_PH_OST;

/
