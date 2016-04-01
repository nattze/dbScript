CREATE OR REPLACE PACKAGE P_NON_PA_APPROVE AS
/******************************************************************************
 NAME: AICP.P_NON_PA_APPROVE
 PURPOSE: For Approve Non PA Claim 

 REVISIONS:
 Ver Date Author Description
 --------- ---------- --------------- ------------------------------------
 1.0 3/10/2014 2702 1. Created this package.
******************************************************************************/

 TYPE v_ref_cursor1 IS REF CURSOR;

FUNCTION GET_PRODUCT_TYPE(i_pol_no IN VARCHAR2 ,i_pol_run IN NUMBER) RETURN VARCHAR2 ;
 
FUNCTION GET_PRODUCTGROUP(vProdtype IN VARCHAR2) RETURN VARCHAR2 ;

FUNCTION GET_SUBGROUP(vProdtype IN VARCHAR2) RETURN VARCHAR2 ;

FUNCTION GET_CLMSTS(in_clmno IN VARCHAR2) RETURN VARCHAR2;

FUNCTION GET_APPRVSTATUS_DESC(vStatus IN VARCHAR2) RETURN VARCHAR2 ; 

FUNCTION GET_PRODUCTID(vProdtype IN VARCHAR2) RETURN VARCHAR2 ;

FUNCTION GET_CTRL_PAGE_ACCUM_AMT(i_clmno IN varchar2 ,i_payno IN varchar2) RETURN NUMBER;
 
FUNCTION GET_CTRL_PAGE_PAYEE_AMT(i_clmno IN varchar2 ,i_payno IN varchar2) RETURN NUMBER ;
 
FUNCTION GET_CTRL_PAGE_PAYEE_NAME(i_clmno IN varchar2 ,i_payno IN varchar2) RETURN VARCHAR2 ; 

FUNCTION GET_CTRL_PAGE_RES_AMT(i_clmno IN varchar2 ) RETURN NUMBER ; 

PROCEDURE GET_APPROVE_USER(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_apprv_id OUT varchar2 ,o_apprv_sts OUT varchar2) ;
 
FUNCTION CAN_SEND_APPROVE(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_rst OUT varchar2) RETURN BOOLEAN ; 

FUNCTION CAN_GO_APPROVE(i_clmno IN varchar2 ,i_payno IN varchar2 ,i_userid IN varchar2 ,i_status IN varchar2 ,o_rst OUT varchar2) RETURN BOOLEAN ; 
 
FUNCTION UPDATE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2 
,v_apprv_flag IN varchar2 ,v_user IN varchar2 ,v_amd_user IN varchar2 ,v_apprv_user IN varchar2 ,v_res_amt IN NUMBER ,v_rst OUT VARCHAR2) RETURN boolean ; 

FUNCTION APPROVE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2 ,v_apprv_user IN varchar2 
,v_rst OUT VARCHAR2) RETURN boolean ; 

FUNCTION APPROVE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2  ,v_apprv_user IN varchar2 ,v_remark IN varchar2
,v_rst OUT VARCHAR2) RETURN boolean ;

FUNCTION GET_BATCHNO(vType IN VARCHAR2) RETURN VARCHAR2;

FUNCTION VALIDATE_INDV(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ;

FUNCTION UPDATE_STATUS(v_payno in varchar2 ,v_clm_user in varchar2 ) RETURN VARCHAR2;

FUNCTION POST_MISC(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ;

FUNCTION GET_NAME_STATUS(i_grp in varchar2 ,i_pol_no in varchar2 ,i_pol_run in number ,i_fleet_seq in number ,i_recpt_seq in number
,i_loss_date in date ) RETURN VARCHAR2;

PROCEDURE GET_COVER_PA(P_POL_NO IN VARCHAR2, 
 P_POL_RUN IN NUMBER, 
 P_FLEET_SEQ IN NUMBER, 
 P_RECPT_SEQ IN NUMBER, 
 P_PREMCODE IN VARCHAR2, -- null คือดึงทั้งหมด 
 P_COVER_PA OUT v_ref_cursor1 ,RST OUT VARCHAR2);

FUNCTION GET_PREMCODE_DESCR(v_prem in varchar2 , v_prodtype in varchar2 ,v_th_eng in VARCHAR2) RETURN VARCHAR2 ;

FUNCTION CAN_CANCEL_PAYMENT(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_rst OUT varchar2) RETURN BOOLEAN ;    

FUNCTION CANCEL_PAYMENT(v_clmno IN varchar2 ,v_payno IN varchar2 ,v_rst OUT VARCHAR2) RETURN boolean ;  

FUNCTION IS_APPROVED(vClmNo in varchar2 ,vPayNo in varchar2 )  RETURN VARCHAR2 ; -- Y ,N
 
END P_NON_PA_APPROVE;
/

