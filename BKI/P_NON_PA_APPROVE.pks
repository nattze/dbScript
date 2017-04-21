CREATE OR REPLACE PACKAGE ALLCLM."P_NON_PA_APPROVE" AS 
/****************************************************************************** 
 NAME: ALLCLM.P_NON_PA_APPROVE 
 PURPOSE: For Approve Non PA Claim  
 
 REVISIONS: 
 Ver Date Author Description 
 --------- ---------- --------------- ------------------------------------ 
 1.0 3/10/2014 2702 1. Created this package. 
******************************************************************************/ 
  TYPE v_ref_cursor1 IS REF CURSOR; 
  
   
FUNCTION CONVERT_PAYMENT_METHOD(inPaidType IN VARCHAR2) RETURN VARCHAR2 ; 
 
FUNCTION GET_APPRVSTATUS_DESC(vStatus IN VARCHAR2) RETURN VARCHAR2 ;  
 
FUNCTION GET_PRODUCTID(vProdtype IN VARCHAR2) RETURN VARCHAR2 ; 
 
FUNCTION GET_CTRL_PAGE_ACCUM_AMT(i_clmno IN varchar2 ,i_payno IN varchar2) RETURN NUMBER ; 
  
FUNCTION GET_CTRL_PAGE_PAYEE_AMT(i_clmno IN varchar2 ,i_payno IN varchar2) RETURN NUMBER ; 
  
FUNCTION GET_CTRL_PAGE_PAYEE_NAME(i_clmno IN varchar2 ,i_payno IN varchar2) RETURN VARCHAR2 ;  
 
FUNCTION GET_CTRL_PAGE_RES_AMT(i_clmno IN varchar2 ) RETURN NUMBER ;  
 
PROCEDURE GET_APPROVE_USER(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_apprv_id OUT varchar2 ,o_apprv_sts OUT varchar2) ; 
 
PROCEDURE GET_REPORT_USER(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_apprv_id OUT varchar2 ,o_clm_men OUT varchar2) ; 
  
FUNCTION CAN_SEND_APPROVE(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_rst OUT varchar2) RETURN BOOLEAN ;  
 
FUNCTION CAN_MAKE_NEW_PAYMENT(i_clmno IN varchar2 ,o_rst OUT varchar2) RETURN BOOLEAN ;  
 
FUNCTION CAN_GO_APPROVE(i_clmno IN varchar2 ,i_payno IN varchar2 ,i_userid IN varchar2 ,i_status IN varchar2 ,o_rst OUT varchar2) RETURN BOOLEAN ;  

FUNCTION CAN_APPROVE_CLM(i_clmno IN varchar2 ,i_payno IN varchar2  ,i_prodtype IN varchar2 ,i_userid IN varchar2 ,i_amt  IN number ,o_rst OUT varchar2) RETURN BOOLEAN ;  
  
FUNCTION UPDATE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2  
,v_apprv_flag IN varchar2 ,v_user IN varchar2 ,v_amd_user IN varchar2 ,v_apprv_user IN varchar2 ,v_res_amt IN NUMBER ,v_rst OUT VARCHAR2) RETURN boolean ;  
 
FUNCTION UPDATE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2  
,v_apprv_flag IN varchar2 ,v_user IN varchar2 ,v_amd_user IN varchar2 ,v_apprv_user IN varchar2 ,v_res_amt IN NUMBER ,v_accum_amt IN NUMBER ,v_rst OUT VARCHAR2) RETURN boolean ;  
 
FUNCTION APPROVE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2 ,v_apprv_user IN varchar2  
,v_rst OUT VARCHAR2) RETURN boolean ;  
 
FUNCTION APPROVE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2 ,v_apprv_user IN varchar2 ,v_remark IN varchar2 
,v_rst OUT VARCHAR2) RETURN boolean ;  
 
FUNCTION GET_CLMSTS(in_clmno IN VARCHAR2) RETURN VARCHAR2; 
  
FUNCTION GET_TYPE(In_prod_grp in varchar2,In_offset_flag in varchar2,In_type in varchar2 ,In_subtype in varchar2 ,in_prem_code in varchar2)return varchar2; 
 
FUNCTION GET_PAYTYPE(in_status in varchar2) RETURN varchar2; 
  
PROCEDURE conv_insert_misc_table(v_clm_no in varchar2,v_pay_no in varchar2,v_trn_seq in number ,v_prod_type varchar2, v_err_message out varchar2); 
 
PROCEDURE EMAIL_NOTICE_APPRV(i_clm IN VARCHAR2 ,i_pay IN VARCHAR2 ,i_sts IN VARCHAR2) ; 
 
PROCEDURE EMAIL_CWP_LETTER(i_clm IN VARCHAR2 ,i_pay IN VARCHAR2 ) ; 
 
FUNCTION CAN_CANCEL_PAYMENT(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_rst OUT varchar2) RETURN BOOLEAN ;  
 
FUNCTION CANCEL_PAYMENT(v_clmno IN varchar2 ,v_payno IN varchar2 ,v_rst OUT VARCHAR2) RETURN boolean ;  
 
FUNCTION GET_BATCHNO(vType IN VARCHAR2) RETURN VARCHAR2; 
 
FUNCTION VALIDATE_INDV(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; 
 
FUNCTION POST_MISC(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; 
 
FUNCTION POST_FIR(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; 
 
FUNCTION POST_MRN(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; 
 
FUNCTION AUTO_POST(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; 
 
FUNCTION AFTER_POST(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; 
 
PROCEDURE GET_DRAFT_ACRDATA(i_clmno IN VARCHAR2 ,i_payno IN VARCHAR2 ,o_payee_amt OUT NUMBER ,o_paid_amt OUT NUMBER 
,o_deduct_amt OUT NUMBER ,o_salvage_amt OUT NUMBER ,o_recov_amt OUT NUMBER ,o_adv_amt OUT NUMBER 
,o_payee_curr OUT VARCHAR2 ,o_paid_curr OUT VARCHAR2);  
 
PROCEDURE RPT_GET_DRAFT_ACRDATA(i_clmno IN VARCHAR2 , 
                                i_payno IN VARCHAR2 ,  
                                out_cursor OUT sys_refcursor); 
FUNCTION Get_Special_email(i_Type IN VARCHAR2,i_user IN VARCHAR2) return VARCHAR2 ;   
 
PROCEDURE GET_SPECIALFLAG_LIST(o_cursor OUT v_ref_cursor1 ) ; 
 
FUNCTION IS_GRP_PAYEE(v_clmno IN varchar2 ,v_payno IN varchar2 ,v_payee IN varchar2 ) RETURN BOOLEAN; 
 
PROCEDURE GET_PAYEE_CONTACT(v_clmno IN varchar2 ,v_payno IN varchar2 ,v_payee IN varchar2  
,o_cust_email OUT varchar2  ,o_cust_sms OUT varchar2 ,o_agent_email OUT varchar2 ,o_agent_sms OUT varchar2) ; 
 
PROCEDURE GET_CUST_CONTACT(p_payee_code  IN VARCHAR2 ,p_payee_seq  IN NUMBER ,TH_ENG IN VARCHAR2 , o_contact_name OUT VARCHAR2 , o_addr1 OUT VARCHAR2  , o_addr2 OUT VARCHAR2   
, o_mobile OUT VARCHAR2  , o_email OUT VARCHAR2) ; 
 
PROCEDURE GET_AGENT_CONTACT(p_clmno  IN VARCHAR2 , o_contact_name OUT VARCHAR2 , o_addr1 OUT VARCHAR2  , o_addr2 OUT VARCHAR2   
, o_mobile OUT VARCHAR2  , o_email OUT VARCHAR2)  ; 
  
FUNCTION IS_AGENT_CHANNEL(p_clmno IN VARCHAR2  ,p_payee IN VARCHAR2) RETURN BOOLEAN ; 
 
FUNCTION GET_PRODUCT_TYPE(vPayno IN VARCHAR2) RETURN VARCHAR2; 
 
FUNCTION GET_PRODUCT_GRP(vPayno IN VARCHAR2) RETURN VARCHAR2; 
 
FUNCTION UPDATE_STATUS_ACR(v_payno in varchar2 ,v_clm_user in varchar2 ) RETURN VARCHAR2 ; 
 
FUNCTION UPDATE_STATUS_AFTER_POST(v_payno in varchar2 ,v_clm_user in varchar2  ,v_success in varchar2 ,v_note in varchar2) RETURN VARCHAR2 ; 
 
FUNCTION CANCEL_APPROVE(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; 
 
PROCEDURE EMAIL_URGENT_PAYMENT(i_clm IN VARCHAR2 ,i_pay IN VARCHAR2 ,i_payee IN VARCHAR2) ; 
 
PROCEDURE GET_LAST_PAYMENTNO(i_clm IN VARCHAR2 ,o_pay OUT VARCHAR2 ,o_sts OUT VARCHAR2) ; 
 
FUNCTION GET_SPECIALFLAG_DESCR(i_flag IN VARCHAR2) RETURN VARCHAR2;  
 
FUNCTION GET_TRANSFER_DETAIL(i_pay IN VARCHAR2 ,i_payee IN VARCHAR2 ,i_mode IN VARCHAR2 ) RETURN VARCHAR2; --i_mode is A = acr , C = claim 
 
FUNCTION GET_METHOD_DESCR(i_med IN VARCHAR2) RETURN VARCHAR2;  
 
FUNCTION GET_PAID_INFO(i_pay IN VARCHAR2 ,i_mode IN VARCHAR2) RETURN VARCHAR2;  
--i_mode : vou_date ,paid_date ,paid_amt ,paid_by ,cheque_no 

FUNCTION GET_PAID_INFO(i_pay IN VARCHAR2 ,i_payseq IN VARCHAR2 ,i_mode IN VARCHAR2) RETURN VARCHAR2;  
--i_mode : vou_date ,paid_date ,paid_amt ,paid_by ,cheque_no 
 
FUNCTION IS_ACTIVATE_AUTOPOST RETURN BOOLEAN; -- TRUE = ON ,FALSE= OFF 
 
FUNCTION SET_SETTLEDATE(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; 

FUNCTION SET_SETTLEDATE(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,vApproveDate in DATE ,P_RST OUT VARCHAR2) RETURN BOOLEAN ; 
/*  vApproveDate สำหรับกรณีเรียกซ่อมงานที่ไม่ได้ stamp nc_payment.settle_date*/
 
FUNCTION IS_APPROVED(vClmNo in varchar2 ,vPayNo in varchar2 ) RETURN VARCHAR2 ; 

FUNCTION IS_VP_UP(i_user in varchar2 ) RETURN VARCHAR2 ; -- Y ,N

FUNCTION IS_AVP_UP(i_user in varchar2 ) RETURN VARCHAR2 ; -- Y ,N

FUNCTION IS_SWITCH_ON(i_switch in varchar2) RETURN BOOLEAN;

FUNCTION IS_URGENT_CLM(vClmNo in varchar2 ,vPayNo in varchar2) RETURN VARCHAR2 ; -- Y ,N

PROCEDURE SAVE_CLM_LIMIT_HISTORY(v_SUBSYSID IN VARCHAR2  ,v_user IN VARCHAR2 ,
                            RST OUT VARCHAR2) ;
 
END P_NON_PA_APPROVE;
/

