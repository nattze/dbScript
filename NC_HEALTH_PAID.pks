CREATE OR REPLACE PACKAGE ALLCLM."NC_HEALTH_PAID" IS  
/******************************************************************************  
   NAME:       NC_HEALTH_PAID  
   PURPOSE: calculate Paid Data and send to ACR   
  
   REVISIONS:  
   Ver        Date        Author           Description  
   ---------  ----------  ---------------  ------------------------------------  
   1.0        22/08/2013      2702       1. Created this package.  
******************************************************************************/  
    TYPE v_ref_cursor1 IS REF CURSOR;  
    TYPE v_ref_cursor2 IS REF CURSOR;  
      
    FUNCTION IS_TL_UP_STAFF(vUserId in varchar2) RETURN BOOLEAN ;  
  
    PROCEDURE WRITE_LOG  (V_MODULE in VARCHAR2 , V_USER in  VARCHAR2 ,V_USER_NAME in VARCHAR2 ,V_FUNC IN VARCHAR2 ,V_LOG_TEXT in VARCHAR2 ,  
                                V_STATUS in  VARCHAR2 ,V_RST  OUT VARCHAR2)  ;        
                                  
    PROCEDURE WRITE_LOG_SWITCH  (V_USESWITCH in Boolean ,V_MODULE in VARCHAR2 , V_USER in  VARCHAR2 ,V_USER_NAME in VARCHAR2 ,V_FUNC IN VARCHAR2 ,V_LOG_TEXT in VARCHAR2 ,  
                                V_STATUS in  VARCHAR2 ,V_RST  OUT VARCHAR2) ;                                     
                                    
    PROCEDURE GEN_CURSOR(qry_str IN LONG ,P_CUR OUT v_ref_cursor1) ;     
      
    FUNCTION VALIDATE_INDV(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ;    
      
    FUNCTION IS_FOUND_BATCH(vClmno in varchar2 ,vPayno in varchar2 ,P_RST out varchar2) RETURN BOOLEAN ;  
  
    FUNCTION RUN_INDV(vClmNo in varchar2 ,vPayNo in varchar2  ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ;  

    FUNCTION RUN_INDV_GM(vClmNo in varchar2 ,vPayNo in varchar2  ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; 
    
    FUNCTION POST_ACR_PA(vClmNo in varchar2 ,vPayNo in varchar2  ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ;  

    FUNCTION POST_ACR_GM(vClmNo in varchar2 ,vPayNo in varchar2  ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ;  
              
    FUNCTION GET_APPROVE_ID(vPayNo in varchar2  ) RETURN VARCHAR2 ;   

    FUNCTION GET_APPROVE_DATE(vPayNo in varchar2  ) RETURN DATE ;  
          
    FUNCTION GET_USER_NAME(vUser_id in varchar2  ) RETURN VARCHAR2 ;   
      
    FUNCTION UPDATE_STATUS(v_payno in varchar2 ,v_clm_user in varchar2 ) RETURN VARCHAR2 ; -- null = success   

    FUNCTION UPDATE_STATUS_ACR(v_payno in varchar2 ,v_clm_user in varchar2 ) RETURN VARCHAR2 ; -- null = success   

    FUNCTION UPDATE_STATUS_AFTER_POST(v_payno in varchar2 ,v_clm_user in varchar2 ,v_success in varchar2 /* Y ,N*/ ,v_note in varchar2) RETURN VARCHAR2 ; -- null = success   

    FUNCTION UPDATE_CLM_AFTER_POST(v_payno in varchar2 ,v_sys in varchar2 /* PA ,GM */ ,v_vouno in varchar2 ,v_voudate in date) RETURN VARCHAR2 ; -- null = success  

    FUNCTION GET_URGENTMAIL(v_vouno IN VARCHAR2 , v_voudate IN DATE ,v_User IN VARCHAR2 ,out_url OUT varchar2) RETURN VARCHAR2;   -- return null = success              
                          
    FUNCTION GET_BATCHNO(vType IN VARCHAR2) RETURN VARCHAR2 ; -- vType D , B   
  
    FUNCTION CHECK_HASBATCH(P_DRAFTNO  IN VARCHAR2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; -- false = not success   

    FUNCTION CHECK_HASBATCH_GM(P_DRAFTNO  IN VARCHAR2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; -- false = not success   
  
    FUNCTION CHECK_DRAFT(vSID IN number) RETURN VARCHAR2 ;  

    FUNCTION CHECK_DRAFT_GM(vSID IN number) RETURN VARCHAR2 ;      
  
    FUNCTION CHECK_PENDING_APPRV(vSID in NUMBER) RETURN VARCHAR2 ; -- N คือ ไม่พบงานรออนุมัติ  
      
    FUNCTION GEN_DRAFT(qry_str IN  LONG , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ  
          
    FUNCTION GEN_DRAFT(P_DATA  IN v_ref_cursor1  , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ      

    FUNCTION GEN_DRAFT_GM(qry_str IN  LONG , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ  
          
    FUNCTION GEN_DRAFT_GM(P_DATA  IN v_ref_cursor1  , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ
      
    FUNCTION GEN_BATCH(P_DRAFTNO  IN VARCHAR2 , V_USER_ID IN VARCHAR2 , P_BATCHNO OUT VARCHAR2 , P_BATCHNO2 OUT VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ      

    FUNCTION GEN_BATCH_GM(P_DRAFTNO  IN VARCHAR2 , V_USER_ID IN VARCHAR2 , P_BATCHNO OUT VARCHAR2 , P_BATCHNO2 OUT VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ      
  
    FUNCTION GROUP_BATCHNO(P_DRAFTNO  IN VARCHAR2, P_RST OUT VARCHAR2) RETURN VARCHAR2 ;   
    -- P_RST Y many batch , N single ::: Result null success  

    FUNCTION GROUP_BATCHNO_GM(P_DRAFTNO  IN VARCHAR2, P_RST OUT VARCHAR2) RETURN VARCHAR2 ;   
    -- P_RST Y many batch , N single ::: Result null success  
      
    FUNCTION SCRIPT_BATCH(P_DRAFTNO  IN VARCHAR2 , V_USER_ID IN VARCHAR2 ,P_MANY IN VARCHAR2 ,P_BATCHNO OUT VARCHAR2  , P_BATCHNO2 OUT VARCHAR2) RETURN VARCHAR2 ;  
    -- null = success   

    FUNCTION SCRIPT_BATCH_GM(P_DRAFTNO  IN VARCHAR2 , V_USER_ID IN VARCHAR2 ,P_MANY IN VARCHAR2 ,P_BATCHNO OUT VARCHAR2  , P_BATCHNO2 OUT VARCHAR2) RETURN VARCHAR2 ;  
    -- null = success   
              
    FUNCTION CLEAR_DRAFT(P_DRAFTNO IN  VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ  

    FUNCTION CLEAR_DRAFT_GM(P_DRAFTNO IN  VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ  
      
    FUNCTION FIX_MED_DATA_STEP1(P_CLMNO IN VARCHAR2 ,P_OUT OUT VARCHAR2) RETURN BOOLEAN;    -- fix Recpt_seq ,End_seq Return True if success   
      
    FUNCTION FIX_MED_DATA_STEP2(P_CLMNO IN VARCHAR2 ,P_OUT OUT VARCHAR2) RETURN BOOLEAN;     -- fix RI   
  
    PROCEDURE GET_PA_RESERVE(P_PAYNO IN VARCHAR2 ,V_KEY OUT NUMBER , V_RST OUT VARCHAR2) ;  
  
    PROCEDURE GET_PA_RESERVE(P_PAYNO IN VARCHAR2 ,P_QUERY OUT LONG , V_RST OUT VARCHAR2) ;  
      
    FUNCTION IS_APPROVE_PROCESS(P_PAYNO IN VARCHAR2 ,P_OUT OUT VARCHAR2) RETURN BOOLEAN;   
      
    FUNCTION SET_APPROVE_STATUS(P_PAYNO IN VARCHAR2 ,P_STATUS IN VARCHAR2) RETURN VARCHAR2; -- return NULL = success  
  
    FUNCTION SET_SEND_ADDR  (P_PAYNO in VARCHAR2 , M_SEND_TITLE in  VARCHAR2 ,M_SEND_ADDR1 in VARCHAR2 ,M_SEND_ADDR2 IN VARCHAR2   
                                ,V_RST  OUT VARCHAR2)   RETURN BOOLEAN;       

    FUNCTION SET_SPECIAL_DATA  (P_PAYNO IN VARCHAR2 , T_CUST_MAIL_FLAG IN  VARCHAR2 ,T_CUST_MAIL IN VARCHAR2 ,T_SMS_FLAG IN VARCHAR2 ,T_MOBILE_NUMBER IN VARCHAR2 
    , T_AGENT_MAIL_FLAG IN  VARCHAR2 ,T_AGENT_MAIL IN VARCHAR2 ,T_AGENT_SMS_FLAG IN VARCHAR2 ,T_AGENT_MOBILE_NUMBER IN VARCHAR2 
    , T_SPECIAL_REMARK IN VARCHAR2 ,T_SPECIAL_FLAG IN VARCHAR2 
    ,V_RST  OUT VARCHAR2)   RETURN BOOLEAN;      
                                                                 
    FUNCTION GET_HISTORY_CLAIM(vPOLICY IN VARCHAR2, 
                                                        P_FLEET_SEQ IN NUMBER, 
                                                        P_CLM_MAS OUT v_ref_cursor1 ,P_CLM_DETAIL OUT v_ref_cursor2 , 
                            RST OUT VARCHAR2)  RETURN VARCHAR2; -- Y = คุ้มครอง N = ไม่คุ้มครอง , E = ไม่พบหรืออื่นๆ , M = many  Policy ;                                    
 
    PROCEDURE GET_HISTORY_ALL_STATUS(P_POL_NO IN VARCHAR2, 
                                                        P_POL_RUN IN NUMBER, 
                                                        P_FLEET_SEQ IN NUMBER, 
                            V_KEY OUT NUMBER) ;  
                             
    PROCEDURE REMOVE_HISTORY_CLAIM (V_KEY IN NUMBER) ;       
 
    FUNCTION CONVERT_CLM_STATUS(vSTATUS IN VARCHAR2) RETURN VARCHAR2;      

    FUNCTION GET_PAYEEDETAIL(vPayee_code IN VARCHAR2 , vPayee_Seq IN NUMBER ,vType IN NUMBER) RETURN VARCHAR2;   -- vType 0 = NAME ,1 = Address                

    FUNCTION IS_NEWACR_ACTIVATE(p_sys IN VARCHAR2) RETURN BOOLEAN; -- True = on            
    
    FUNCTION IS_AGENT_CHANNEL(p_clmno IN VARCHAR2 ,p_payee IN VARCHAR2) RETURN BOOLEAN; -- True = Agent/Broker    

    PROCEDURE GET_AGENT_CONTACT(p_clmno  IN VARCHAR2 , o_contact_name OUT VARCHAR2 , o_addr1 OUT VARCHAR2  , o_addr2 OUT VARCHAR2  , o_mobile OUT VARCHAR2  , o_email OUT VARCHAR2)  ;

    PROCEDURE GET_HOSPITAL_CONTACT(p_payee_code  IN VARCHAR2 ,p_payee_seq  IN NUMBER ,TH_ENG IN VARCHAR2, o_contact_name OUT VARCHAR2 , o_addr1 OUT VARCHAR2  , o_addr2 OUT VARCHAR2  , o_mobile OUT VARCHAR2  , o_email OUT VARCHAR2)  ;

    FUNCTION GET_ORG_CUSTOMER_EMAIL(p_clmno  IN VARCHAR2)  RETURN VARCHAR2;

    FUNCTION VALIDATE_PAYEE_NAME (v_clm_no varchar2 ,v_payee_code varchar2 ,v_payee_name varchar2 ,v_payee_type varchar2 ,o_rst OUT VARCHAR2) RETURN BOOLEAN ;                        

    FUNCTION VALIDATE_MOBILE(v_no IN VARCHAR2) RETURN BOOLEAN;
    
    FUNCTION VALIDATE_EMAIL(v_mail IN VARCHAR2) RETURN BOOLEAN; 
    
    FUNCTION GET_COUNT_ACCNO(p_payee IN VARCHAR2) RETURN NUMBER;   
    
    FUNCTION IS_USD_POLICY(i_polno IN VARCHAR2 ,i_polrun IN NUMBER) RETURN BOOLEAN;
    
    FUNCTION IS_CASH_PAYMENT(i_clmno IN VARCHAR2 ,i_payno IN VARCHAR2 ,i_prod IN VARCHAR2) RETURN BOOLEAN;

    PROCEDURE email_alert_cash(i_clmno IN VARCHAR2 , i_payno IN VARCHAR2);
    
    FUNCTION SET_CARDNO(v_clmno in varchar2  ,v_user in varchar2 ,v_id_type in varchar2,v_id_no in varchar2 ,v_oth_type in varchar2 ,v_oth_no in varchar2
,rst out varchar2) RETURN BOOLEAN;

    FUNCTION GET_CARDNO(v_polno in varchar2  ,v_polrun in number ,v_fleet in number,v_recpt in number 
    ,v_cuscode in varchar2 ,v_cusseq in number ,v_name in varchar2 ,v_clmno in varchar2 ,v_payno in varchar2) RETURN varchar2;

    FUNCTION GET_PRODUCT(v_clmno in varchar2)    RETURN VARCHAR2;
    
END NC_HEALTH_PAID;
/

