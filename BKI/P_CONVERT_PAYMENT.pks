CREATE OR REPLACE PACKAGE ALLCLM."P_CONVERT_PAYMENT"  IS 
/****************************************************************************** 
 NAME: NMTR_PAPERLESS 
 PURPOSE: Get Authurized NonMotorClaim User for Approve payment 
 
 REVISIONS: 
 Ver Date Author Description 
 --------- ---------- --------------- ------------------------------------ 
 1.0 13/10/2014 Pornpen 1. Created this package. 
******************************************************************************/ 
 TYPE v_ref_cursor1 IS REF CURSOR; 
 TYPE v_ref_cursor2 IS REF CURSOR; 
 TYPE v_ref_cursor3 IS REF CURSOR; 
 TYPE v_ref_cursor4 IS REF CURSOR; 
 TYPE v_ref_cursor5 IS REF CURSOR; 
 
 PROCEDURE conv_insert_fire_table (v_clm_no in varchar2,v_pay_no in varchar2,v_prod_type varchar2, v_err_message out varchar2) ; 
 PROCEDURE conv_insert_mrn_table (v_clm_no in varchar2,v_pay_no in varchar2,v_prod_type varchar2, v_err_message out varchar2) ; 
 PROCEDURE conv_insert_hull_table (v_clm_no in varchar2,v_pay_no in varchar2,v_prod_type varchar2, v_err_message out varchar2) ;  
 FUNCTION GET_PAYTYPE(In_prod_grp in varchar2,In_prem_code in varchar2,In_offset_flag in varchar2, In_type in varchar2 ,In_subtype in varchar2)return varchar2; 
 FUNCTION GET_TYPE(In_prod_grp in varchar2,In_offset_flag in varchar2,In_type in varchar2 ,In_subtype in varchar2)return varchar2; 
 FUNCTION Update_Master_Dt(In_clm_no in varchar2,In_prod_type in varchar2,In_prod_grp in varchar2,In_type in varchar2,v_tot_paid in number,v_salvage in number,v_deduct in number,v_recov in number) return varchar2; 
 PROCEDURE conv_insert_all_table(v_clm_no in varchar2,v_pay_no in varchar2,v_prod_type varchar2, v_err_message out varchar2); 
 PROCEDURE CONV_INSERT_MISC_TABLE(v_clm_no in varchar2,v_pay_no in varchar2,v_trn_seq in number ,v_prod_type varchar2, v_err_message out varchar2); 
 FUNCTION CONVERT_PAYMENT_METHOD(inPaidType IN VARCHAR2) RETURN VARCHAR2 ; 
 PROCEDURE GET_SALVAGE_DEDUCT_RECOV_FLAG(in_clm_no IN VARCHAR2 ,in_pay_no IN VARCHAR2 
 ,o_salvage OUT VARCHAR2 ,o_deduct OUT VARCHAR2 ,o_recov OUT VARCHAR2) ; 
 
 FUNCTION GET_CNT_LINEFEED(in_txt VARCHAR2) RETURN NUMBER; 
 
 FUNCTION FIX_LINEFEED(in_txt VARCHAR2) RETURN VARCHAR2; 
 
 FUNCTION GET_CMS_TYPE(In_subtype in varchar2 ,In_prem_code in varchar2) RETURN VARCHAR2;
 
END P_CONVERT_PAYMENT; 
/

