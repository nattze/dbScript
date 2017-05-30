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
    
    FUNCTION GEN_STATENO(v_PROD_TYPE IN VARCHAR2 ) RETURN VARCHAR2;
    
    FUNCTION VALIDATE_INDV(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ;
    
    FUNCTION POST_ACCTMP(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN;
    
    FUNCTION APPROVE_PAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2 ,v_apprv_user IN varchar2 ,v_remark IN varchar2 
,v_rst OUT VARCHAR2) RETURN boolean ;
 
    FUNCTION UPDATE_STATUS_ACR(v_payno in varchar2 ,v_clm_user in varchar2 ) RETURN VARCHAR2;
    
    FUNCTION UPDATE_STATUS_ERROR(v_payno in varchar2 ,v_clm_user in varchar2  ,v_rst in varchar2 ) RETURN VARCHAR2;
    
    FUNCTION CONV_PH_OPEN(v_clmno in varchar2,v_payno in varchar2 ,v_sts in varchar2
    , v_err_message out varchar2) RETURN BOOLEAN ;

    FUNCTION CONV_PH_DRAFT(v_clmno in varchar2,v_payno in varchar2 ,v_sts in varchar2
    , v_err_message out varchar2) RETURN BOOLEAN ;

    FUNCTION CONV_PH_CWP(v_clmno in varchar2,v_payno in varchar2 ,v_sts in varchar2
    , v_err_message out varchar2) RETURN BOOLEAN ;

    FUNCTION CONV_PH_REOPEN(v_clmno in varchar2,v_payno in varchar2 ,v_sts in varchar2
    , v_err_message out varchar2) RETURN BOOLEAN ;

    FUNCTION CONV_PH_RES_REV(v_clmno in varchar2,v_payno in varchar2 ,v_sts in varchar2
    , v_err_message out varchar2) RETURN BOOLEAN ;
                
    PROCEDURE CONV_TABLE(v_clmno in varchar2,v_payno in varchar2 ,v_prodtype in varchar2
    , v_err_message out varchar2) ;
    
    FUNCTION CONV_ADMISSTYPE(v_code in varchar2) RETURN VARCHAR2;
    
    FUNCTION CONV_CLMSTS(v_code in varchar2) RETURN VARCHAR2;
    
    FUNCTION CONV_PAYEETYPE(v_code in varchar2) RETURN VARCHAR2;
    
    FUNCTION CONV_HOSPITAL(v_code in varchar2) RETURN VARCHAR2;

    FUNCTION CONV_HOSPITAL_NEW(v_code in varchar2) RETURN VARCHAR2;
        
    PROCEDURE CONV_CLMTYPE(v_code in varchar2, o_inc out varchar2 ,o_recpt out varchar2 
    ,o_inv out varchar2 ,o_ost out varchar2 ,o_dead out varchar2);

    FUNCTION SET_SETTLEDATE(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ;
    
    FUNCTION VALIDATE_CONVERT924(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN VARCHAR2;
    -- Return Y ,N
    
    FUNCTION CONVERT924(vClmNo in varchar2 ,vPayNo in varchar2 ,vUser in varchar2 ,P_RST OUT VARCHAR2) RETURN VARCHAR2;
    -- Return Y ,N    
END P_PH_CONVERT;
/

