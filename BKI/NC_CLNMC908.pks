CREATE OR REPLACE PACKAGE NC_CLNMC908 AS
/******************************************************************************
 NAME: ALLCLM.NC_CLNMC908
   PURPOSE:  USE for Approve payment Program

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        17/03/2014      2702       1. Created this package.
******************************************************************************/
    TYPE v_ref_cursor1 IS REF CURSOR;

    PROCEDURE GEN_CURSOR(qry_str IN CLOB ,P_CUR OUT v_ref_cursor1) ;
    
    FUNCTION GEN_DRAFT(qry_str IN  LONG , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ
        
    FUNCTION GEN_DRAFT(P_DATA  IN v_ref_cursor1  , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ   
    
    FUNCTION CLEAR_DRAFT(P_DRAFTNO IN  VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ     

    FUNCTION GEN_DRAFT_GM(qry_str IN  LONG , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ    

    FUNCTION GEN_DRAFT_GM(P_DATA  IN v_ref_cursor1  , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ   
    
    FUNCTION CLEAR_DRAFT_GM(P_DRAFTNO IN  VARCHAR2) RETURN VARCHAR2 ; -- null สำเร็จ         

    PROCEDURE CLEAR_ACR_TMP(P_PAYNO IN  VARCHAR2) ;      
        
    FUNCTION Validate_main(vClmno IN VARCHAR2 ,vPayno IN VARCHAR2 ,vPolno IN VARCHAR2 ,vPolrun IN Number,vLossDate IN Date ,vFleet IN Number ,vRecpt IN Number
,vRST OUT VARCHAR2) RETURN BOOLEAN /* false = not pass */ ;

    FUNCTION Validate_RI_AND_PAID (vClmno IN VARCHAR2 ,vPayno IN VARCHAR2 ,vProd IN VARCHAR2, vRST OUT VARCHAR2) 
    RETURN BOOLEAN /* false = not pass */ ;

    FUNCTION Validate_Advance_Amt (vClmno IN VARCHAR2 ,vPayno IN VARCHAR2 ,vProd IN VARCHAR2, vRST OUT VARCHAR2) 
    RETURN BOOLEAN /* false = not pass */ ;
        
    FUNCTION GET_PRODUCTID(vCLMno IN VARCHAR2) RETURN VARCHAR2 ;

    FUNCTION GET_PRODUCTID2(vProdtype IN VARCHAR2) RETURN VARCHAR2 ;
    
    FUNCTION GET_PRODUCT_TYPE(vPayno IN VARCHAR2) RETURN VARCHAR2 ;

    FUNCTION Validate_Cancel (vClmno IN VARCHAR2 , vRST OUT VARCHAR2)
    RETURN BOOLEAN /* false = not pass */ ;
    
    FUNCTION Validate_Approve_Cancel (vKey IN NUMBER ,vPayNo IN VARCHAR2 , vRST OUT VARCHAR2)
    RETURN BOOLEAN /* false = not pass */ ;
        
    PROCEDURE CHK_LAST_APPRV_STATUS(v_key IN NUMBER ,v_payno IN VARCHAR2 
    , O_STATUS OUT VARCHAR2 , O_APPRV_FLAG OUT VARCHAR2 ) ;

    FUNCTION CHK_OWN_APPRV(v_user IN VARCHAR2 ,v_amt IN NUMBER ,v_sys IN VARCHAR2 ,v_apprv IN VARCHAR2) RETURN BOOLEAN ;

    FUNCTION IS_PENDING_APPRV(v_key IN NUMBER ,v_payno IN VARCHAR2 ,o_apprv OUT VARCHAR2) RETURN BOOLEAN ;
    
    PROCEDURE GET_CHK_APPRV(v_key IN NUMBER ,v_payno IN VARCHAR2 ,o_send_apprv OUT VARCHAR2 ,o_apprv OUT VARCHAR2) ; -- Y ,null 
    
    FUNCTION GET_SUM_RI_PAID_TEXT(vPayno IN VARCHAR2) RETURN VARCHAR2 ;        

    FUNCTION GET_SUM_RI_PAID(vPayno IN VARCHAR2) RETURN NUMBER ;
        
    PROCEDURE GET_CURSOR_APPROVE_DATA(vWhere IN LONG ,pOut OUT NC_CLNMC908.v_ref_cursor1 ,pRST OUT VARCHAR2)  ; 

    FUNCTION UPDATE_STATUS(v_key IN number ,v_sys IN varchar2 ,v_sts IN varchar2 ,v_clmmen IN varchar2 ,v_remark IN varchar2 ,v_rst OUT VARCHAR2) RETURN boolean ;

    FUNCTION UPDATE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2  ,v_remark IN varchar2
    ,v_apprv_flag IN varchar2 ,v_user IN varchar2 ,v_amd_user IN varchar2 ,v_apprv_user IN varchar2 ,v_res_amt IN NUMBER ,v_rst OUT VARCHAR2) RETURN boolean ;           

    FUNCTION GET_SEND_APPRV_USER(v_key IN varchar2 ,v_payno IN varchar2 ) RETURN varchar2 ;
    
    PROCEDURE UPDATE_MASTER_STSKEY(v_key IN number ,v_clmno IN varchar2 ,v_rst  out VARCHAR2) ;

    FUNCTION CAN_SELF_APPROVE_STATUS(vPaySTS IN VARCHAR2) RETURN BOOLEAN ;

    PROCEDURE UPDATE_GMCLM908(v_pay_no in VARCHAR2 , v_send_title  in VARCHAR2 , v_send_addr1  in VARCHAR2 ,v_send_addr2  in VARCHAR2 
    ,v_settle  in VARCHAR2 ,v_special_flag  in VARCHAR2 ,v_special_remark  in VARCHAR2 ,v_urgent_flag  in VARCHAR2 
    ,v_agent_mail  in VARCHAR2 ,v_agent_mail_flag  in VARCHAR2 ,v_agent_mobile_number in VARCHAR2 ,v_agent_sms_flag  in VARCHAR2 
    ,v_cust_mail  in VARCHAR2 ,v_cust_mail_flag  in VARCHAR2 ,v_mobile_number  in VARCHAR2 ,v_sms_flag  in VARCHAR2
    ,v_acc_no  in VARCHAR2 ,v_acc_name  in VARCHAR2 ,v_bank_code  in VARCHAR2 ,v_bank_br_code in VARCHAR2
    ) ;

    PROCEDURE UPDATE_CLCPA913(v_pay_no in VARCHAR2 , v_invalid  in VARCHAR2 , v_invalid_remark  in VARCHAR2 ); 
    
    PROCEDURE UPDATE_MED_ADDR(vsts_key in NUMBER , v_send_title  in VARCHAR2 , v_send_addr1  in VARCHAR2 ,v_send_addr2  in VARCHAR2 
    ,v_special_flag  in VARCHAR2 ,v_special_remark  in VARCHAR2 
    ,v_agent_mail  in VARCHAR2 ,v_agent_mail_flag  in VARCHAR2 ,v_agent_mobile_number in VARCHAR2 ,v_agent_sms_flag  in VARCHAR2 
    ,v_cust_mail  in VARCHAR2 ,v_cust_mail_flag  in VARCHAR2 ,v_mobile_number  in VARCHAR2 ,v_sms_flag  in VARCHAR2
    ) ;    
    
    FUNCTION GET_ACR_PAIDDATE(vPayNo IN VARCHAR2) RETURN DATE    ;
    
    PROCEDURE Dupplicate_CLM(p_clm IN VARCHAR2 ,x_clmno OUT VARCHAR2) ;
    
    PROCEDURE FixPOST_ACR ; -- fix data after Approve before Auto Post ACR at Night 
    
    PROCEDURE FixPOST_ACR_PAIDTYPE ;    -- fix data after Approve before Auto Post ACR at Night 
        
    PROCEDURE FixPOST_SUBSYSID ;    -- fix data after Approve before Auto Post ACR at Night 
    
    PROCEDURE FixPOST_ACR_CUST_EMAIL ;    -- fix data after Approve before Auto Post ACR at Night 

    PROCEDURE FixPOST_ACR_INSERTLOSS_EMAIL ;    -- fix data after Approve before Auto Post ACR at Night 
    
    PROCEDURE FixMultiPayeeACC(i_pay_no IN VARCHAR2 ) ; -- fix multi payee paid by Acc tranfer

    PROCEDURE EMAIL_CWP_LETTER(i_clm IN VARCHAR2 ,i_pay IN VARCHAR2 ) ;      

    PROCEDURE EMAIL_DISAPPRV_LETTER(i_clm IN VARCHAR2 ,i_pay IN VARCHAR2  ,i_send IN VARCHAR ,i_apprv IN VARCHAR2) ;  
        
END NC_CLNMC908;
/

