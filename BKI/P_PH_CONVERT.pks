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
    
    FUNCTION CONV_CLMSTS_O2N(v_code in varchar2, v_type in varchar2) RETURN VARCHAR2; -- V_type : 1 (CLM_STS),2 (CLAIM_STATUS)
    
    FUNCTION CONV_PAYEETYPE(v_code in varchar2) RETURN VARCHAR2;
    
    FUNCTION CONV_HOSPITAL(v_code in varchar2) RETURN VARCHAR2;

    FUNCTION CONV_HOSPITAL_NEW(v_code in varchar2) RETURN VARCHAR2;
        
    PROCEDURE CONV_CLMTYPE(v_code in varchar2, o_inc out varchar2 ,o_recpt out varchar2 
    ,o_inv out varchar2 ,o_ost out varchar2 ,o_dead out varchar2);
    
    FUNCTION CONV_CWPCODE(v_code in varchar2) RETURN VARCHAR2;

    FUNCTION SET_SETTLEDATE(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ;
    
    FUNCTION VALIDATE_CONVERT924(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN VARCHAR2;
    -- Return Y ,N
    
    FUNCTION CONVERT924(vClmNo in varchar2 ,vPayNo in varchar2 ,vUser in varchar2 ,P_RST OUT VARCHAR2) RETURN VARCHAR2;
    -- Return Y ,N    
    
    PROCEDURE O2N_CONV_RUN_PA(v_Year in VARCHAR2); -- for Keep Result via Email

    PROCEDURE O2N_CONV_RUN_GM(v_Year in VARCHAR2); -- for Keep Result via Email
        
    FUNCTION O2N_CONV_PA(v_Date in Date ,v_CLMNO in VARCHAR2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; -- Convert PA Claim

    FUNCTION O2N_CONV_PH(v_Date in Date ,v_CLMNO in VARCHAR2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; -- Convert PH Claim    
    
    FUNCTION IS_EXIST_NC_MAS(v_CLMNO in VARCHAR2) RETURN BOOLEAN;
    
    FUNCTION IS_FOUND_CPARES(v_CLMNO in VARCHAR2 ,v_Date in Date) RETURN BOOLEAN;
    
    FUNCTION IS_FOUND_CPARES(v_CLMNO in VARCHAR2 ) RETURN BOOLEAN;
    
    FUNCTION IS_FOUND_NCRES(v_CLMNO in VARCHAR2 ) RETURN BOOLEAN;
    
    FUNCTION IS_FOUND_CPAPAID(v_CLMNO in VARCHAR2 ,v_PAYNO in VARCHAR2 ) RETURN BOOLEAN;
    
    FUNCTION GEN_KPI_REPORT(v_fr in VARCHAR2 ,v_to in VARCHAR2)   RETURN NUMBER; -- Sid 0 = Fail 
    
    FUNCTION GET_KPI_DETAIL(v_fr in Date ,v_to in Date)   RETURN NUMBER; -- Sid
    
    FUNCTION GET_KPI_SUM(v_fr in Date ,v_to in Date ,v_sid in NUMBER)   RETURN NUMBER; -- Sid
    
    FUNCTION CLEAR_KPI_REPORT(v_sid in NUMBER)   RETURN NUMBER; -- 1 Success ,0 Fail
    
END P_PH_CONVERT;
/
