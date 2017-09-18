CREATE OR REPLACE PACKAGE ALLCLM."P_CLAIM_ACR" AS
  TYPE v_ref_cursor IS REF CURSOR;

/******************************************************************************
   NAME:       ALLCLM.P_CLAIM_ACR
   PURPOSE:

   REVISIONS:
   Ver        Date              Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/06/2009      Pornpen       1. Created this package.
   2.0         13/08/2014     Taywin         Add module for Paperless PA/GM Payment
******************************************************************************/


  PROCEDURE Post_acc_clm_tmp(P_prod_grp IN   acc_clm_tmp.prod_grp%type,
                                        P_prod_type IN  acc_clm_tmp.prod_type%type,
                                        P_payno   IN  acc_clm_tmp.payment_no%type,
                                        P_appoint_date IN  acc_clm_tmp.appoint_date%type,
                                        P_clmno   IN  acc_clm_tmp.clm_no%type,
                                        P_polno   IN  acc_clm_tmp.pol_no%type,
                                        P_polrun  IN  acc_clm_tmp.pol_run%type,
                                        P_polnum  IN  acc_clm_tmp.policy_number%type,
                                        P_polref  IN  acc_clm_tmp.pol_ref%type,
                                        P_cuscode IN  acc_clm_tmp.cus_code%type,
                                        P_th_eng IN  acc_clm_tmp.th_eng%type,
                                        P_agent_code IN  acc_clm_tmp.agent_code%type,
                                        P_agent_seq IN  acc_clm_tmp.agent_seq%type,
                                        P_Postby IN  acc_clm_tmp.post_by%type,
                                        P_brn_code IN  acc_clm_tmp.brn_code%type,
                                        P_inw_type IN  acc_clm_tmp.inw_type%type,
                                        P_batch_no IN acc_clm_tmp.batch_no%type,
                                        P_dept_id IN acc_clm_tmp.dept_id%type,
                                        P_div_id IN acc_clm_tmp.div_id%type,
                                        P_team_id IN acc_clm_tmp.team_id%type,
                                        P_msg Out varchar2);

 PROCEDURE Post_acc_clm_payee_nonpa( P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type,
                                   P_prod_type  IN  acc_clm_payee_tmp.prod_type%type,
                                   P_payno      IN  acc_clm_payee_tmp.payment_no%type,
                                   P_seq        IN  acc_clm_payee_tmp.seq%type,
                                   P_doc_type   IN  acc_clm_payee_tmp.doc_type%type, --Loss motor = 01,expense = 02
                                   P_curr_code  IN  acc_clm_payee_tmp.curr_code%type,
                                   P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type,
                                   P_payee_code IN  acc_clm_payee_tmp.payee_code%type,
                                   P_title      IN  acc_clm_payee_tmp.title%type,
                                   P_name       IN  acc_clm_payee_tmp.name%type,
                                   P_dept_no    IN  acc_clm_payee_tmp.dept_no%type,
                                   P_batch_no   IN  acc_clm_payee_tmp.batch_no%type,
                                   P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type,
                                   P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type,
                                   P_salvage_amt    IN  acc_clm_payee_tmp.salvage_amt%type,
                                   P_recov_amt    IN  acc_clm_payee_tmp.recov_amt%type,
                                   P_prem_offset    IN  acc_clm_payee_tmp.less_other%type  ,
                                   p_bank_code       in  acc_clm_payee_tmp.bank_code%type,  --- start new Column 2015
                                   p_branch_code     in  acc_clm_payee_tmp.branch_code%type,
                                   p_acc_no          in  acc_clm_payee_tmp.acc_no%type,
                                   p_acc_name_th     in  acc_clm_payee_tmp.acc_name_th%type,
                                   p_acc_name_eng   in  acc_clm_payee_tmp.acc_name_eng%type,
                                   p_deposit_type    in  acc_clm_payee_tmp.deposit_type%type,
                                   p_paid_type       in  acc_clm_payee_tmp.paid_type%type,
                                   p_special_flag    in  acc_clm_payee_tmp.special_flag%type,
                                   p_special_remark    in  acc_clm_payee_tmp.special_remark%type,
                                   p_agent_mail           in  acc_clm_payee_tmp.agent_mail%type,
                                   p_agent_mail_flag      in  acc_clm_payee_tmp.agent_mail_flag%type,
                                   p_agent_mobile_number  in  acc_clm_payee_tmp.agent_mobile_number%type,
                                   p_agent_sms_flag       in  acc_clm_payee_tmp.agent_sms_flag%type,
                                   p_cust_mail            in  acc_clm_payee_tmp.cust_mail%type,
                                   p_cust_mail_flag       in  acc_clm_payee_tmp.cust_mail_flag%type,
                                   p_mobile_number   in  acc_clm_payee_tmp.mobile_number%type,
                                   p_sms_flag        in  acc_clm_payee_tmp.sms_flag%type,
                                   P_msg       Out varchar2) ;

 PROCEDURE Post_acc_clm_payee_pagm( P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type,
                                   P_prod_type  IN  acc_clm_payee_tmp.prod_type%type,
                                   P_payno      IN  acc_clm_payee_tmp.payment_no%type,
                                   P_seq        IN  acc_clm_payee_tmp.seq%type,
                                   P_doc_type   IN  acc_clm_payee_tmp.doc_type%type, --Loss motor = 01,expense = 02
                                   P_curr_code  IN  acc_clm_payee_tmp.curr_code%type,
                                   P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type,
                                   P_payee_code IN  acc_clm_payee_tmp.payee_code%type,
                                   P_title      IN  acc_clm_payee_tmp.title%type,
                                   P_name       IN  acc_clm_payee_tmp.name%type,
                                   P_dept_no    IN  acc_clm_payee_tmp.dept_no%type,
                                   P_batch_no   IN  acc_clm_payee_tmp.batch_no%type,
                                   P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type,
                                   P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type,
                                   p_bank_code       in  acc_clm_payee_tmp.bank_code%type,  --- start new Column 2014
                                   p_branch_code     in  acc_clm_payee_tmp.branch_code%type,
                                   p_acc_no          in  acc_clm_payee_tmp.acc_no%type,
                                   p_acc_name_th     in  acc_clm_payee_tmp.acc_name_th%type,
                                   p_acc_name_eng   in  acc_clm_payee_tmp.acc_name_eng%type,
                                   p_deposit_type    in  acc_clm_payee_tmp.deposit_type%type,
                                   p_paid_type       in  acc_clm_payee_tmp.paid_type%type,
                                   p_special_flag    in  acc_clm_payee_tmp.special_flag%type,
                                   p_special_remark    in  acc_clm_payee_tmp.special_remark%type,
                                   p_agent_mail           in  acc_clm_payee_tmp.agent_mail%type,
                                   p_agent_mail_flag      in  acc_clm_payee_tmp.agent_mail_flag%type,
                                   p_agent_mobile_number  in  acc_clm_payee_tmp.agent_mobile_number%type,
                                   p_agent_sms_flag       in  acc_clm_payee_tmp.agent_sms_flag%type,
                                   p_cust_mail            in  acc_clm_payee_tmp.cust_mail%type,
                                   p_cust_mail_flag       in  acc_clm_payee_tmp.cust_mail_flag%type,
                                   p_mobile_number   in  acc_clm_payee_tmp.mobile_number%type,
                                   p_sms_flag        in  acc_clm_payee_tmp.sms_flag%type,
                                   P_msg       Out varchar2) ;

 PROCEDURE Post_acc_clm_payee_tmp( P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type,
                                   P_prod_type  IN  acc_clm_payee_tmp.prod_type%type,
                                   P_payno      IN  acc_clm_payee_tmp.payment_no%type,
                                   P_seq        IN  acc_clm_payee_tmp.seq%type,
                                   P_doc_type   IN  acc_clm_payee_tmp.doc_type%type, --Loss motor = 01,expense = 02
                                   P_curr_code  IN  acc_clm_payee_tmp.curr_code%type,
                                   P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type,
                                   P_payee_code IN  acc_clm_payee_tmp.payee_code%type,
                                   P_title      IN  acc_clm_payee_tmp.title%type,
                                   P_name       IN  acc_clm_payee_tmp.name%type,
                                   P_dept_no    IN  acc_clm_payee_tmp.dept_no%type,
                                   P_batch_no   IN  acc_clm_payee_tmp.batch_no%type,
                                   P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type,
                                   P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type,
                                   P_msg       Out varchar2) ;
 PROCEDURE Post_acc_clm_payee_tmp_new( P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type,
                                   P_prod_type  IN  acc_clm_payee_tmp.prod_type%type,
                                   P_payno      IN  acc_clm_payee_tmp.payment_no%type,
                                   P_seq        IN  acc_clm_payee_tmp.seq%type,
                                   P_doc_type   IN  acc_clm_payee_tmp.doc_type%type, --Loss motor = 01,expense = 02
                                   P_curr_code  IN  acc_clm_payee_tmp.curr_code%type,
                                   P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type,
                                   P_payee_code IN  acc_clm_payee_tmp.payee_code%type,
                                   P_title      IN  acc_clm_payee_tmp.title%type,
                                   P_name       IN  acc_clm_payee_tmp.name%type,
                                   P_dept_no    IN  acc_clm_payee_tmp.dept_no%type,
                                   P_batch_no   IN  acc_clm_payee_tmp.batch_no%type,
                                   P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type,
                                   P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type,
                                   P_salvage_amt    IN  acc_clm_payee_tmp.salvage_amt%type,
                                   P_recov_amt    IN  acc_clm_payee_tmp.recov_amt%type,
                                   P_msg       Out varchar2) ;

 PROCEDURE Post_acc_clm_payee_tmp_misc( P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type,
                                   P_prod_type  IN  acc_clm_payee_tmp.prod_type%type,
                                   P_payno      IN  acc_clm_payee_tmp.payment_no%type,
                                   P_seq        IN  acc_clm_payee_tmp.seq%type,
                                   P_doc_type   IN  acc_clm_payee_tmp.doc_type%type, --Loss motor = 01,expense = 02
                                   P_curr_code  IN  acc_clm_payee_tmp.curr_code%type,
                                   P_booking_rate  IN  acc_clm_payee_tmp.booking_rate%type,
                                   P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type,
                                   P_payee_code IN  acc_clm_payee_tmp.payee_code%type,
                                   P_title      IN  acc_clm_payee_tmp.title%type,
                                   P_name       IN  acc_clm_payee_tmp.name%type,
                                   P_dept_no    IN  acc_clm_payee_tmp.dept_no%type,
                                   P_batch_no   IN  acc_clm_payee_tmp.batch_no%type,
                                   P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type,
                                   P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type,
                                   P_salvage_amt    IN  acc_clm_payee_tmp.salvage_amt%type,
                                   P_recov_amt    IN  acc_clm_payee_tmp.recov_amt%type,
                                   P_less_other    IN  acc_clm_payee_tmp.less_other%type,
                                   P_msg       Out varchar2) ;

  PROCEDURE reverse_payment_motor(P_prod_grp IN varchar2,P_prod_type IN varchar2,
                                                      P_flag In varchar2 , /* P = payment ,B = batch_no */
                                                      P_number in varchar2,   /*  payment no or batch */
                                                      p_userid   in varchar2,
                                                      P_msg OUT varchar2) ;
   PROCEDURE reverse_payment_nonmotor(P_prod_grp IN varchar2,P_prod_type IN varchar2,
                                                      P_flag In varchar2 , /* P = payment ,B = batch_no */
                                                      P_number in varchar2,   /*  payment no or batch */
                                                      p_userid   in varchar2,
                                                      P_msg OUT varchar2) ;
  PROCEDURE get_clm_sts(P_prod_grp IN varchar2,P_prod_type IN varchar2,
                                     P_flag In varchar2 , /* P = payment ,B = batch_no */
                                     p_number in varchar2,   /*payment no or batch*/
                                     P_sts OUT varchar2 /*C = Close claim or cwp,null = Pending*/);
  PROCEDURE Set_paid_date_motor(P_flag IN varchar2 , /* P = payment ,B = batch_no */
                                                   P_number IN varchar2,   /*payment no or batch*/
                                                   P_vou_date IN date,
                                                   P_userid In varchar2,
                                                   P_msg OUT varchar2 /*Error = update error*/) ;
  PROCEDURE Get_clm_motor_org_unit(P_clm IN varchar2,
                                                       P_dept OUT varchar2,
                                                       P_div    OUT varchar2,
                                                       P_team OUT varchar2);
  FUNCTION get_close_claim(P_prod_grp IN varchar2,P_prod_type IN varchar2,
                                          p_claim in varchar2   /*claim no  */) RETURN varchar2;   /*Y = Close claim or cwp,null = Pending*/
  PROCEDURE post_acr_gl (P_claim IN varchar2,P_payno IN varchar2,P_msg OUT varchar2);
  PROCEDURE Set_billing_date_motor(P_flag IN varchar2 , /* P = payment ,B = batch_no */
                                                     P_number IN varchar2,   /*payment no or batch*/
                                                     P_bill_date IN date,
                                                      P_userid In varchar2,
                                                     P_msg OUT varchar2 /*Error = update error*/) ;

  PROCEDURE After_post_NC_PAYMENT(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2,   /* Prod_type*/
                                                     P_success IN varchar2,   /*  post Acr Success = 'Y' , Fail or Error = 'N' */
                                                     P_note In varchar2,   /*  note for Error Case */
                                                     P_msg OUT varchar2 /*null = Success ,Not null = error*/) ;

  PROCEDURE GET_SEND_ADDRESS(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2,   /* Prod_type*/
                                                     P_Send_Title OUT varchar2,   /*  Title */
                                                     P_Send_Addr1 OUT varchar2, /* Address1 */
                                                     P_Send_Addr2 OUT varchar2 /* Address2 */) ;

  PROCEDURE GET_SEND_ADDRESS(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_payee_code IN varchar2 ,
                                                     P_prod_type IN varchar2,   /* Prod_type*/
                                                     P_Send_Title OUT varchar2,   /*  Title */
                                                     P_Send_Addr1 OUT varchar2, /* Address1 */
                                                     P_Send_Addr2 OUT varchar2 /* Address2 */) ;

  FUNCTION GET_LOSS_DATE(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN DATE /* loss date*/ ;

  FUNCTION GET_COVER_PERIOD(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* period*/ ;

  FUNCTION GET_INSURE_NAME(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* Insure*/ ;

  FUNCTION GET_CLAIMANT(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* Claimant*/ ;

  FUNCTION GET_PAID_REMARK(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* remerk*/ ;

  FUNCTION GET_TREATMENT_DATE(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN DATE /* loss date*/ ;

  FUNCTION GET_PARTICULAR(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* Particular*/ ;

  FUNCTION GET_APPROVE_ID(vPayNo in varchar2  ) RETURN VARCHAR2 ;

  FUNCTION GET_PRODUCTID(vProdtype IN VARCHAR2) RETURN VARCHAR2 ;

  FUNCTION isGroupCheckByPolicy(P_payee_code IN varchar2) RETURN Boolean ; /*true = group check by payee_code+policy */

  FUNCTION getNONPA_losstype(vType  IN VARCHAR2) RETURN VARCHAR2 ;

  FUNCTION getNONPA_lossItem(vPrem  IN VARCHAR2 ,vProdtype IN VARCHAR2) RETURN VARCHAR2 ;

  FUNCTION getNONPA_reserve_amt(vClmno  IN VARCHAR2  ,vType IN VARCHAR2) RETURN NUMBER ;

  FUNCTION getNONPA_InvoiceDtl(vPayno  IN VARCHAR2 ,vMode IN VARCHAR2/*1=get InvoiceNo 2=get Invoice Date*/) RETURN VARCHAR2 ;

  FUNCTION GET_CLAIMUSER(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* Claimant*/ ;

  FUNCTION GET_STATEMENT_LINK(P_clm_no  IN VARCHAR2  ,P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* URL*/ ;

  FUNCTION GET_PAIDUSER(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* Paid User*/ ;
                                                    
  FUNCTION GET_DAMAGE_DESCR(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* remerk*/ ;                                                    
END P_CLAIM_ACR;
/

