CREATE OR REPLACE PACKAGE BODY ALLCLM."P_CLAIM_ACR" AS
/******************************************************************************
   NAME:       ALLCLM.P_CLAIM_ACR
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/06/2009             1. Created this package body.
   2.0         08/05/2014            2 Revise Procedure Set_paid_date_motor
******************************************************************************/

  PROCEDURE  Post_acc_clm_tmp(P_prod_grp IN   acc_clm_tmp.prod_grp%type,
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
                                        P_msg Out varchar2)  IS
    v_deptno varchar2(3);
  BEGIN
    if (P_prod_grp = '3' or P_prod_type = '335') then
        delete acc_clm_tmp
        where prod_grp = P_prod_grp
            and prod_type = P_prod_type
            and payment_no = P_payno
            and appoint_date =   P_appoint_date ;
    else
        delete acc_clm_tmp
        where prod_grp = P_prod_grp
            and prod_type = P_prod_type
            and payment_no = P_payno ;
    end if;

    if P_prod_grp = '3' then
       if P_prod_type  in ( '33','333') then
          v_deptno := '30';
       else
          v_deptno := '03';
       end if;
    elsif P_prod_grp = '0' then
         v_deptno := '08';
    elsif P_prod_grp = '2' then
         if P_prod_type in ( '22','222') then
            v_deptno := '05';
         else
            v_deptno := '02';
         end if;
    elsif  P_prod_grp in ('4','5')  then
        v_deptno := '04';
    elsif P_prod_grp = '9' then
        v_deptno := '08';
    elsif P_prod_grp = '1' then
        v_deptno := '01';
    end if;
     insert into  acc_clm_tmp
       ( PROD_GRP, PROD_TYPE, PAYMENT_NO, APPOINT_DATE,
         CLM_NO, POL_NO, POL_RUN, POLICY_NUMBER, POL_REF,
          CUS_CODE, TH_ENG, AGENT_CODE, AGENT_SEQ,
          POST_BY, POST_DATE, BRN_CODE, INW_TYPE, DEPT_NO,BATCH_NO,
          DEPT_ID,DIV_ID,TEAM_ID
       )
         values( P_prod_grp  ,  P_prod_type ,P_payno , P_appoint_date  ,
         P_clmno   , P_polno  ,P_polrun,P_polnum ,  P_polref,
         P_cuscode  , P_th_eng ,  P_agent_code , P_agent_seq  ,
         P_postby ,sysdate,  P_brn_code  , P_inw_type ,v_deptno, P_batch_no,
         P_dept_id,P_div_id,P_team_id);
               P_msg   := null;
  EXCEPTION
      when others then
               P_msg := 'Error';
  END;

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
                                   P_msg       Out varchar2) IS
  v_deptno varchar2(3);
 BEGIN
     -- P_batch_no รอใช้เพื่อระบุ GROUP BATCH By Payee

     delete acc_clm_payee_tmp
     where prod_grp = P_prod_grp
        and prod_type = P_prod_type
        and payment_no = P_payno
        and doc_type =   P_doc_type
        and seq = P_seq
        ;

     if P_prod_grp = '3' then
       if P_prod_type  in ( '33','333') then
          v_deptno := '30';
       else
          v_deptno := '03';
       end if;
    elsif P_prod_grp = '0' then
         v_deptno := '08';
    elsif P_prod_grp = '2' then
         if P_prod_type in ( '22','222') then
            v_deptno := '05';
         else
            v_deptno := '02';
         end if;
    elsif  P_prod_grp in ('4','5')  then
        v_deptno := '04';
    elsif P_prod_grp = '9' then
        v_deptno := '08';
    elsif P_prod_grp = '1' then
        v_deptno := '01';
    end if;

  insert into  acc_clm_payee_tmp
     ( PROD_GRP, PROD_TYPE, PAYMENT_NO, SEQ, DOC_TYPE,
       CURR_CODE, PAYEE_AMT, PAYEE_CODE,
       TITLE, NAME, DEPT_NO, BATCH_NO, DEDUCT_AMT, ADV_AMT , SALVAGE_AMT ,RECOV_AMT  ,
       BANK_CODE ,BRANCH_CODE ,ACC_NO ,ACC_NAME_TH ,ACC_NAME_ENG ,DEPOSIT_TYPE ,PAID_TYPE ,SPECIAL_FLAG ,SPECIAL_REMARK ,
       AGENT_MAIL ,AGENT_MAIL_FLAG ,AGENT_MOBILE_NUMBER ,AGENT_SMS_FLAG ,
       CUST_MAIL ,CUST_MAIL_FLAG ,MOBILE_NUMBER ,SMS_FLAG  ,LESS_OTHER ,PAID_BY_PAYMENT
       )
    values( P_prod_grp , P_prod_type,P_payno  ,  P_seq  ,  P_doc_type ,
     P_curr_code  , P_payee_amt, P_payee_code,  P_title ,    P_name ,v_deptno ,null ,  P_deduct_amt , P_adv_amt ,  P_salvage_amt , P_recov_amt ,
     P_BANK_CODE ,P_BRANCH_CODE ,P_ACC_NO ,P_ACC_NAME_TH ,P_ACC_NAME_ENG ,P_DEPOSIT_TYPE ,P_PAID_TYPE ,P_SPECIAL_FLAG ,P_SPECIAL_REMARK ,
     P_AGENT_MAIL ,P_AGENT_MAIL_FLAG ,P_AGENT_MOBILE_NUMBER ,P_AGENT_SMS_FLAG ,
     P_CUST_MAIL ,P_CUST_MAIL_FLAG ,P_MOBILE_NUMBER ,P_SMS_FLAG   ,P_prem_offset ,P_batch_no
     );

      P_msg   := null;
  EXCEPTION
      when others then
               P_msg := 'Error';
  END;

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
                                   P_msg       Out varchar2) IS
 BEGIN
     delete acc_clm_payee_tmp
    where prod_grp = P_prod_grp
        and prod_type = P_prod_type
        and payment_no = P_payno
        and doc_type =   P_doc_type
        and seq = P_seq;

  insert into  acc_clm_payee_tmp
     ( PROD_GRP, PROD_TYPE, PAYMENT_NO, SEQ, DOC_TYPE,
       CURR_CODE, PAYEE_AMT, PAYEE_CODE,
       TITLE, NAME, DEPT_NO, BATCH_NO, DEDUCT_AMT, ADV_AMT ,
       BANK_CODE ,BRANCH_CODE ,ACC_NO ,ACC_NAME_TH ,ACC_NAME_ENG ,DEPOSIT_TYPE ,PAID_TYPE ,SPECIAL_FLAG ,SPECIAL_REMARK ,
       AGENT_MAIL ,AGENT_MAIL_FLAG ,AGENT_MOBILE_NUMBER ,AGENT_SMS_FLAG ,
       CUST_MAIL ,CUST_MAIL_FLAG ,MOBILE_NUMBER ,SMS_FLAG
       )
    values( P_prod_grp , P_prod_type,P_payno  ,  P_seq  ,  P_doc_type ,
     P_curr_code  , P_payee_amt, P_payee_code,  P_title ,    P_name ,P_dept_no,P_batch_no ,  P_deduct_amt , P_adv_amt ,
     P_BANK_CODE ,P_BRANCH_CODE ,P_ACC_NO ,P_ACC_NAME_TH ,P_ACC_NAME_ENG ,P_DEPOSIT_TYPE ,P_PAID_TYPE ,P_SPECIAL_FLAG ,P_SPECIAL_REMARK ,
     P_AGENT_MAIL ,P_AGENT_MAIL_FLAG ,P_AGENT_MOBILE_NUMBER ,P_AGENT_SMS_FLAG ,
     P_CUST_MAIL ,P_CUST_MAIL_FLAG ,P_MOBILE_NUMBER ,P_SMS_FLAG
     );

      P_msg   := null;
  EXCEPTION
      when others then
               P_msg := 'Error';
  END;

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
                                   P_msg       Out varchar2) IS
 BEGIN
     delete acc_clm_payee_tmp
    where prod_grp = P_prod_grp
        and prod_type = P_prod_type
        and payment_no = P_payno
        and doc_type =   P_doc_type
        and seq = P_seq;

  insert into  acc_clm_payee_tmp
     ( PROD_GRP, PROD_TYPE, PAYMENT_NO, SEQ, DOC_TYPE,
       CURR_CODE, PAYEE_AMT, PAYEE_CODE,
       TITLE, NAME, DEPT_NO, BATCH_NO, DEDUCT_AMT, ADV_AMT  )
    values( P_prod_grp , P_prod_type,P_payno  ,  P_seq  ,  P_doc_type ,
     P_curr_code  , P_payee_amt, P_payee_code,  P_title ,    P_name ,P_dept_no,P_batch_no ,  P_deduct_amt , P_adv_amt );

      P_msg   := null;
  EXCEPTION
      when others then
               P_msg := 'Error';
  END;

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
                                   P_msg       Out varchar2) IS
 BEGIN
     delete acc_clm_payee_tmp
    where prod_grp = P_prod_grp
        and prod_type = P_prod_type
        and payment_no = P_payno
        and doc_type =   P_doc_type
        and payee_code = P_payee_code
        and seq =  P_seq;

  insert into  acc_clm_payee_tmp
     ( PROD_GRP, PROD_TYPE, PAYMENT_NO, SEQ, DOC_TYPE,
       CURR_CODE, PAYEE_AMT, PAYEE_CODE,
       TITLE, NAME, DEPT_NO, BATCH_NO, DEDUCT_AMT, ADV_AMT ,RECOV_AMT ,SALVAGE_AMT )
    values( P_prod_grp , P_prod_type,P_payno  ,  P_seq  ,  P_doc_type ,
     P_curr_code  , P_payee_amt, P_payee_code,  P_title ,    P_name ,P_dept_no,P_batch_no ,  P_deduct_amt , P_adv_amt   ,P_recov_amt ,P_salvage_amt);

      P_msg   := null;
  EXCEPTION
      when others then
               P_msg := 'Error';
  END;

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
                                   P_msg       Out varchar2) IS
  v_deptno varchar2(3);
 BEGIN
     delete acc_clm_payee_tmp
    where prod_grp = P_prod_grp
        and prod_type = P_prod_type
        and payment_no = P_payno
        and doc_type =   P_doc_type
        and payee_code = P_payee_code
        and seq =  P_seq;

    if P_prod_grp = '3' then
       if P_prod_type  in ( '33','333') then
          v_deptno := '30';
       else
          v_deptno := '03';
       end if;
    elsif P_prod_grp = '0' then
         v_deptno := '08';
    elsif P_prod_grp = '2' then
         if P_prod_type in ( '22','222') then
            v_deptno := '05';
         else
            v_deptno := '02';
         end if;
    elsif  P_prod_grp in ('4','5')  then
        v_deptno := '04';
    elsif P_prod_grp = '9' then
        v_deptno := '08';
    elsif P_prod_grp = '1' then
        v_deptno := '01';
    end if;

  insert into  acc_clm_payee_tmp
     ( PROD_GRP, PROD_TYPE, PAYMENT_NO, SEQ, DOC_TYPE,
       CURR_CODE, PAYEE_AMT, PAYEE_CODE,
       TITLE, NAME, DEPT_NO, BATCH_NO, DEDUCT_AMT, ADV_AMT ,RECOV_AMT ,SALVAGE_AMT,LESS_OTHER   ,booking_rate)
    values( P_prod_grp , P_prod_type,P_payno  ,  P_seq  ,  P_doc_type ,
     P_curr_code  , P_payee_amt, P_payee_code,  P_title ,    P_name ,v_deptno ,P_batch_no ,  P_deduct_amt , P_adv_amt   ,P_recov_amt ,P_salvage_amt,P_less_other ,P_booking_rate  );

      P_msg   := null;
  EXCEPTION
      when others then
               P_msg := 'Error:'||sqlerrm;
  END;

   PROCEDURE reverse_payment_motor(P_prod_grp IN varchar2,P_prod_type IN varchar2,
                                                      P_flag In varchar2 , /* P = payment ,B = batch_no */
                                                      P_number in varchar2,   /*  payment no or batch */
                                                      P_userid   in varchar2,
                                                      P_msg OUT varchar2) IS
   v_sts varchar2(100);
   p_sts varchar2(30) := null;
  BEGIN
    get_clm_sts(P_prod_grp ,P_prod_type ,  P_flag  ,  p_number ,v_sts);
    if v_sts is null and P_flag = 'P' then
      if P_prod_type = '335' then
      begin
         insert into mtr_payment_tab
         (
         TRN_DATE, CLM_NO, PAID_DATE, PAY_NO, PAY_CODE, PAYEE_NO, PAY_AMT, LINE_NO,
         DEDUCT_MARK, PAY_TYPE, PAY_MARK, BR_CODE, PAYEE_TYPE, DRV_NO, BANK_CODE,
         BANK_BR, ACCOUNT_NO, APPOINT_MARK, APPROVE_MARK, VOUCHER_MARK, TRN_SEQ,
         VAT, APPOINT_FLAG, PAY_TIME, ACC_TYPE, APPROVE_FLAG, APPROVE_USER_ID, BATCH_NO,
         USER_ID, VAT_FLAG, RECOV_FLAG, RECOV_FLAG_DATE, BILL_DATE, REC_TIME,
         APPOINT_DATE, STATE_FLAG,PAY_DAYS, BR_WALKIN
         )
         select trunc(sysdate), a.CLM_NO, a.PAID_DATE, a.PAY_NO, a.PAY_CODE, a.PAYEE_NO, 0, a.LINE_NO,
         a.DEDUCT_MARK, a.PAY_TYPE, 'C', a.BR_CODE, a.PAYEE_TYPE, a.DRV_NO, a.BANK_CODE,
         a.BANK_BR, a.ACCOUNT_NO, a.APPOINT_MARK, a.APPROVE_MARK, a.VOUCHER_MARK, a.TRN_SEQ+1,
         a.VAT, a.APPOINT_FLAG, a.PAY_TIME, a.ACC_TYPE, a.APPROVE_FLAG, a.APPROVE_USER_ID, a.BATCH_NO,
         P_userid, a.VAT_FLAG, a.RECOV_FLAG, a.RECOV_FLAG_DATE, a.BILL_DATE, a.REC_TIME,
         a.APPOINT_DATE, a.STATE_FLAG,a.PAY_DAYS, a.BR_WALKIN
         from mtr_payment_tab a
         where a.pay_no = P_number
            and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                      from mtr_payment_tab b
                                                    where a.clm_no = b.clm_no
                                                       and a.pay_no = b.pay_no
                                               group by b.pay_no)
            and exists (select 1 from acr_mas c
                            where a.clm_no = c.clm_no
                                and a.pay_no = c.payment_no
                               and c.prod_grp = '5'
                               and c.cancel_vou_date is not null);
           p_sts := null;
      exception
         when others then
                 p_sts := 'Error';
           dbms_output.put_line('Mtr_payment_tab:'||p_sts);
      end;
      else
          begin
             insert into mtr_payment_tab
             (
             TRN_DATE, CLM_NO, PAID_DATE, PAY_NO, PAY_CODE, PAYEE_NO, PAY_AMT, LINE_NO,
             DEDUCT_MARK, PAY_TYPE, PAY_MARK, BR_CODE, PAYEE_TYPE, DRV_NO, BANK_CODE,
             BANK_BR, ACCOUNT_NO, APPOINT_MARK, APPROVE_MARK, VOUCHER_MARK, TRN_SEQ,
             VAT, APPOINT_FLAG, PAY_TIME, ACC_TYPE, APPROVE_FLAG, APPROVE_USER_ID, BATCH_NO,
             USER_ID, VAT_FLAG, RECOV_FLAG, RECOV_FLAG_DATE, BILL_DATE, REC_TIME,
             APPOINT_DATE, STATE_FLAG,PAY_DAYS, BR_WALKIN
             )
             select trunc(sysdate), a.CLM_NO, a.PAID_DATE, a.PAY_NO, a.PAY_CODE, a.PAYEE_NO, 0, a.LINE_NO,
             a.DEDUCT_MARK, a.PAY_TYPE, 'C', a.BR_CODE, a.PAYEE_TYPE, a.DRV_NO, a.BANK_CODE,
             a.BANK_BR, a.ACCOUNT_NO, a.APPOINT_MARK, a.APPROVE_MARK, a.VOUCHER_MARK, a.TRN_SEQ+1,
             a.VAT, a.APPOINT_FLAG, a.PAY_TIME, a.ACC_TYPE, a.APPROVE_FLAG, a.APPROVE_USER_ID, a.BATCH_NO,
             P_userid, a.VAT_FLAG, a.RECOV_FLAG, a.RECOV_FLAG_DATE, a.BILL_DATE, a.REC_TIME,
             a.APPOINT_DATE, a.STATE_FLAG,a.PAY_DAYS, a.BR_WALKIN
             from mtr_payment_tab a
             where a.pay_no = P_number
                and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                          from mtr_payment_tab b
                                                        where a.clm_no = b.clm_no
                                                           and a.pay_no = b.pay_no
                                                   group by b.pay_no)
                and exists (select 1 from acr_mas c
                                where a.clm_no = c.clm_no
                                    and a.pay_no = c.payment_no
                                   and c.prod_grp = '3'
                                   and c.cancel_vou_date is not null);
               p_sts := null;
          exception
             when others then
                     p_sts := 'Error';
               dbms_output.put_line('Mtr_payment_tab:'||p_sts);
          end;
     end if;
      if P_sts is null then
        begin
         insert into mtr_ri_paid
         (CLM_NO, PAY_NO, CORR_DATE, CORR_SEQ, RI_CODE,
         RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
          RI_LA_NO, RI_LA_SEQ, RI_SHARE, RI_PAY_AMT, SUPPLEMENT,
           RI_FEE, RI_VAT, RI_PAID_DATE
         )
         select CLM_NO, PAY_NO, CORR_DATE, CORR_SEQ+1, RI_CODE,
          RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
          RI_LA_NO, RI_LA_SEQ, RI_SHARE, 0, SUPPLEMENT,
           RI_FEE, RI_VAT, RI_PAID_DATE
           from mtr_ri_paid a
         where a.pay_no = P_number
            and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                      from mtr_ri_paid b
                                                    where a.clm_no = b.clm_no
                                                       and a.pay_no = b.pay_no
                                               group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mtr_ri_paid:'||p_msg);
        end;
      end if;
    elsif v_sts is null and P_flag = 'B' then
      begin
         insert into mtr_payment_tab
         (
         TRN_DATE, CLM_NO, PAID_DATE, PAY_NO, PAY_CODE, PAYEE_NO, PAY_AMT, LINE_NO,
         DEDUCT_MARK, PAY_TYPE, PAY_MARK, BR_CODE, PAYEE_TYPE, DRV_NO, BANK_CODE,
         BANK_BR, ACCOUNT_NO, APPOINT_MARK, APPROVE_MARK, VOUCHER_MARK, TRN_SEQ,
         VAT, APPOINT_FLAG, PAY_TIME, ACC_TYPE, APPROVE_FLAG, APPROVE_USER_ID, BATCH_NO,
         USER_ID, VAT_FLAG, RECOV_FLAG, RECOV_FLAG_DATE, BILL_DATE, REC_TIME,
         APPOINT_DATE, STATE_FLAG,PAY_DAYS, BR_WALKIN
         )
         select trunc(sysdate), a.CLM_NO, a.PAID_DATE, a.PAY_NO, a.PAY_CODE, a.PAYEE_NO, 0, a.LINE_NO,
         a.DEDUCT_MARK, a.PAY_TYPE, 'C', a.BR_CODE, a.PAYEE_TYPE, a.DRV_NO, a.BANK_CODE,
         a.BANK_BR, a.ACCOUNT_NO, a.APPOINT_MARK, a.APPROVE_MARK, a.VOUCHER_MARK, a.TRN_SEQ+1,
         a.VAT, a.APPOINT_FLAG, a.PAY_TIME, a.ACC_TYPE, a.APPROVE_FLAG, a.APPROVE_USER_ID, a.BATCH_NO,
         P_userid, a.VAT_FLAG, a.RECOV_FLAG, a.RECOV_FLAG_DATE, a.BILL_DATE, a.REC_TIME,
         a.APPOINT_DATE, a.STATE_FLAG,a.PAY_DAYS, a.BR_WALKIN
         from mtr_payment_tab a
         where a.batch_no = P_number
            and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                      from mtr_payment_tab b
                                                    where a.clm_no = b.clm_no
                                                       and a.pay_no = b.pay_no
                                               group by b.pay_no)
             and exists (select 1 from acr_mas c
                            where a.clm_no = c.clm_no
                                and a.pay_no = c.payment_no
                                and c.BATCH_NO = P_number
                               and c.prod_grp = '3'
                               and c.cancel_vou_date is not null);
         p_sts := null;
      exception
         when others then
                 p_sts := 'Error';
      end;
      if P_sts is null then
        begin
         insert into mtr_ri_paid
         (CLM_NO, PAY_NO, CORR_DATE, CORR_SEQ, RI_CODE,
         RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
          RI_LA_NO, RI_LA_SEQ, RI_SHARE, RI_PAY_AMT, SUPPLEMENT,
           RI_FEE, RI_VAT, RI_PAID_DATE
         )
         select CLM_NO, PAY_NO, CORR_DATE, CORR_SEQ+1, RI_CODE,
          RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
          RI_LA_NO, RI_LA_SEQ, RI_SHARE, 0, SUPPLEMENT,
           RI_FEE, RI_VAT, RI_PAID_DATE
           from mtr_ri_paid a
         where a.pay_no in (select ab.pay_no
                                        from mtr_payment_tab ab
                                       where a.clm_no = ab.clm_no
                                          and a.pay_no = ab.pay_no
                                          and ab.batch_no = P_number)
            and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                      from mtr_ri_paid b
                                                    where a.clm_no = b.clm_no
                                                       and a.pay_no = b.pay_no
                                               group by b.pay_no);
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
        end;
      end if;
   else
       dbms_output.put_line('clm status:'||v_sts);
   end if;
  EXCEPTION
      when others then
               P_msg := 'Error';
              dbms_output.put_line('Error clm status:'||v_sts);
  END;
  PROCEDURE reverse_payment_nonmotor(P_prod_grp IN varchar2,P_prod_type IN varchar2,
                                                      P_flag In varchar2 , /* P = payment ,B = batch_no */
                                                      P_number in varchar2,   /*  payment no or batch */
                                                      P_userid   in varchar2,
                                                      P_msg OUT varchar2) IS
   v_sts varchar2(100);
   p_sts varchar2(30) := null;
   v_clm_no varchar2(15);
   v_paid_amt number(10,2);
   v_cnt_pay  number(3);
   v_sum_allpay  number(10,2);
   v_sum_pay  number(10,2);
   v_clm_sts  varchar2(1);
   v_chk_sts  boolean;
   v_chk_prod varchar2(1) := null;

  BEGIN
  if  P_prod_grp = '0'  and P_flag = 'P'  then   /* check prod_type for GM or PA */
      begin
        select main_class
        into   v_chk_prod
        from   prod_type_std
        where  prod_type = substr(P_number,5,3);
      exception
        when  others then
              v_chk_prod := null;
        dbms_output.put_line('Cannot find prod_type');
      end;
  end if;

  if  P_prod_grp = '0'   then   /* GM */
    if P_flag = 'P' and v_chk_prod = 'M' then
       begin
         select distinct clm_no
          into   v_clm_no
        from   mis_clmgm_paid
        where  pay_no = P_number;
       exception
         when others then
                 v_clm_no := null;
         dbms_output.put_line('Cannot find claim number');
       end;

      begin
         insert into mis_clm_mas_seq
         (
         clm_no, pol_no, pol_run, corr_seq, corr_date, channel, prod_grp, prod_type,
         clm_date, tot_res, tot_paid, close_date, reopen_date, clm_sts
         )
         select a.clm_no, a.pol_no, a.pol_run, a.corr_seq+1, trunc(sysdate), a.channel, a.prod_grp, a.prod_type,
                 a.clm_date, a.tot_res, a.tot_paid, null, trunc(sysdate), '4'
         from mis_clm_mas_seq a
         where a.clm_no = v_clm_no
            and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                                      from mis_clm_mas_seq b
                                                    where a.clm_no = b.clm_no
                                                 group by b.clm_no);
          p_sts := null;
      exception
         when others then
                 p_sts := 'Error';
           dbms_output.put_line('Mis_clm_mas_seq - reopen :'||p_sts);
      end;

      begin
         insert into clm_medical_res
         (
         clm_no,state_no,state_seq,fleet_seq,sub_seq,plan,pd_flag,dis_code,bene_code,recpt_seq,state_date,corr_date,
         title,name,fr_date,to_date,hpt_code,res_amt,close_date,close_code,reopen_date,loss_date,fam_sts,patronize,
         paid_sts,cancel,contact,remark,deduct_amt,clm_pd_flag,seq,fam_seq,dept_bki,id_no,disc_amt,ipd_day
         )
         select a.clm_no, a.state_no, a.state_seq+1, a.fleet_seq, a.sub_seq, a.plan, a.pd_flag, a.dis_code, a.bene_code, a.recpt_seq, a.state_date, trunc(sysdate),
                 a.title, a.name, a.fr_date, a.to_date, a.hpt_code, a.res_amt, null, null, trunc(sysdate), a.loss_date, a.fam_sts, a.patronize,
                 a.paid_sts, a.cancel, a.contact, a.remark, a.deduct_amt, a.clm_pd_flag, a.seq, a.fam_seq, a.dept_bki, a.id_no, a.disc_amt, a.ipd_day
         from  clm_medical_res a
         where a.clm_no = v_clm_no
            and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                                         from clm_medical_res b
                                                       where a.clm_no = b.clm_no
                                                          and a.state_no = b.state_no
                                                   group by b.state_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Clm_medical_res - reopen :'||p_msg);
        end;

        begin
         insert into clm_gm_paid
         (
         clm_no,pay_no,corr_seq,fleet_seq,sub_seq,plan,pd_flag,dis_code,bene_code,loss_date,date_paid,corr_date,
         disc_rate,disc_amt,pay_amt,hpt_code,rec_amt,clm_pd_flag,remark,sur_percent,ipd_day,seq,rec_pay_date,
         deduct_amt,fam_seq,dept_bki,id_no
         )
         select a.clm_no, a.pay_no, a.corr_seq+1, a.fleet_seq, a.sub_seq, a.plan, a.pd_flag, a.dis_code, a.bene_code, a.loss_date, a.date_paid, trunc(sysdate),
                  0.0, 0, 0, a.hpt_code, 0, a.clm_pd_flag, a.remark, 0, a.ipd_day, a.seq, null,
                  0, a.fam_seq, a.dept_bki, a.id_no
         from  clm_gm_paid a
         where a.clm_no = v_clm_no
            and a.pay_no = P_number
            and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                      from clm_gm_paid b
                                                     where a.clm_no = b.clm_no
                                                        and a.pay_no = b.pay_no
                                                 group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Clm_gm_paid :'||p_msg);
        end;

        begin
         insert into clm_gm_payee
         (
         clm_no,pay_no,pay_seq,payee_type,payee_code,payee_amt,pay_type,payee_name
          )
         select a.clm_no, a.pay_no, a.pay_seq+1, a.payee_type, a.payee_code, 0, a.pay_type, a.payee_name
         from  clm_gm_payee a
         where a.clm_no = v_clm_no
            and a.pay_no = P_number
            and (a.pay_no,a.pay_seq) in (select b.pay_no,max(b.pay_seq)
                                                      from clm_gm_payee b
                                                     where a.clm_no = b.clm_no
                                                        and a.pay_no = b.pay_no
                                                 group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Clm_gm_payee :'||p_msg);
        end;

    begin
         insert into mis_clmgm_paid
         (
         clm_no,pay_no,corr_seq,pay_date,pay_total,rec_total,disc_total,settle,part,remark,
         lett_recno,permit,permit_date,acc_no,acc_name,acc_type,bank_code,branch_code,rec_pay_date
          )
         select a.clm_no, a.pay_no, a.corr_seq+1, a.pay_date, 0, 0, 0, a.settle, a.part, a.remark,
                a.lett_recno, a.permit, a.permit_date, a.acc_no, a.acc_name, a.acc_type, a.bank_code, a.branch_code, a.rec_pay_date
         from  mis_clmgm_paid a
         where a.clm_no = v_clm_no
            and a.pay_no = P_number
            and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                      from mis_clmgm_paid b
                                                     where a.clm_no = b.clm_no
                                                        and a.pay_no = b.pay_no
                                                 group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mis_clmgm_paid :'||p_msg);
        end;

  begin
         insert into mis_clm_mas_seq
         (
         clm_no, pol_no, pol_run, corr_seq, corr_date, channel, prod_grp, prod_type,
         clm_date, tot_res, tot_paid, close_date, reopen_date, clm_sts
         )
         select a.clm_no, a.pol_no, a.pol_run, a.corr_seq+1, trunc(sysdate), a.channel, a.prod_grp, a.prod_type,
                 a.clm_date, a.tot_res, 0, trunc(sysdate), null, '3'
         from mis_clm_mas_seq a
         where a.clm_no = v_clm_no
            and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                                      from mis_clm_mas_seq b
                                                    where a.clm_no = b.clm_no
                                                 group by b.clm_no);
          p_sts := null;
        exception
         when others then
                 p_sts := 'Error';
           dbms_output.put_line('Mis_clm_mas_seq - cwp :'||p_sts);
        end;

        begin
         insert into clm_medical_res
         (
         clm_no,state_no,state_seq,fleet_seq,sub_seq,plan,pd_flag,dis_code,bene_code,recpt_seq,state_date,corr_date,
         title,name,fr_date,to_date,hpt_code,res_amt,close_date,close_code,reopen_date,loss_date,fam_sts,patronize,
         paid_sts,cancel,contact,remark,deduct_amt,clm_pd_flag,seq,fam_seq,dept_bki,id_no,disc_amt,ipd_day
         )
         select a.clm_no, a.state_no, a.state_seq+1, a.fleet_seq, a.sub_seq, a.plan, a.pd_flag, a.dis_code, a.bene_code, a.recpt_seq, a.state_date, trunc(sysdate),
                 a.title, a.name, a.fr_date, a.to_date, a.hpt_code, a.res_amt, trunc(sysdate), null, null, a.loss_date, a.fam_sts, a.patronize,
                 a.paid_sts, a.cancel, a.contact, a.remark, 0, a.clm_pd_flag, a.seq, a.fam_seq, a.dept_bki, a.id_no, 0, a.ipd_day
         from  clm_medical_res a
         where a.clm_no = v_clm_no
            and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                                         from clm_medical_res b
                                                       where a.clm_no = b.clm_no
                                                          and a.state_no = b.state_no
                                                   group by b.state_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Clm_medical_res - cwp :'||p_msg);
        end;

       begin
         insert into mis_cri_res
         (
         clm_no,ri_code,ri_br_code,ri_cont,ri_type,your_pol,ri_res_date,ri_res_amt,ri_shr,lett_no,lett_remark,lett_prt,lett_type,
         cwp_remark,cwp_no,res_sts,corr_seq,lf_flag,ri_sub_type,polyj_flag
         )
         select a.clm_no, a.ri_code, a.ri_br_code, a.ri_cont, a.ri_type, a.your_pol, a.ri_res_date, 0, a.ri_shr, a.lett_no, a.lett_remark, a.lett_prt, a.lett_type,
                 a.cwp_remark, a.cwp_no, a.res_sts, a.corr_seq+1, a.lf_flag, a.ri_sub_type, a.polyj_flag
         from  mis_cri_res a
         where a.clm_no = v_clm_no
           and  a.res_sts = '0'
           and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                                         from mis_cri_res b
                                                       where a.clm_no = b.clm_no
                                                          and a.res_sts = b.res_sts
                                                   group by b.clm_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mis_cri_res :'||p_msg);
        end;

       begin
         insert into mis_cri_paid
         (
         clm_no,pay_no,pay_sts,ri_code,ri_br_code,ri_cont,ri_type,pay_amt,lett_no,lett_remark,lett_prt,lett_type,
         corr_seq,lf_flag,ri_sub_type,polyj_flag
         )
         select a.clm_no, a.pay_no, a.pay_sts, a.ri_code, a.ri_br_code, a.ri_cont, a.ri_type, 0, a.lett_no, a.lett_remark, a.lett_prt, a.lett_type,
                 a.corr_seq+1, a.lf_flag, a.ri_sub_type, a.polyj_flag
         from  mis_cri_paid a
         where a.clm_no = v_clm_no
           and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                         from mis_cri_paid b
                                                       where a.clm_no = b.clm_no
                                                          and a.pay_no = b.pay_no
                                                   group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mis_cri_paid :'||p_msg);
        end;

  begin
    update mis_clm_mas
    set    tot_paid = 0, reopen_date = trunc(sysdate), close_date = trunc(sysdate), clm_sts = '3'
    where  clm_no = v_clm_no;
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Mis_clm_mas :'||p_msg);
        end;

    begin
    update clm_medical_paid
    set    max_day_clm = 0, max_amt_clm = 0, max_agr_amt = 0
    where  clm_no = v_clm_no;
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Clm_medical_paid :'||p_msg);
        end;

    begin
    delete clmgm_batch_tmp
    where pay_no = P_number;
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Clmgm_batch_tmp :'||p_msg);
        end;

    begin
      update clm_gm_recov
      set    cancel_flag = 'Y'
      where  clm_no = v_clm_no
      and    recv_sts = '0';
      P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Clm_gm_recov :'||p_msg);
        end;

    elsif P_flag = 'B' and substr(P_number,5,1) = '0' then
      begin
         insert into mis_clm_mas_seq
         (
         clm_no, pol_no, pol_run, corr_seq, corr_date, channel, prod_grp, prod_type,
         clm_date, tot_res, tot_paid, close_date, reopen_date, clm_sts
         )
         select a.clm_no, a.pol_no, a.pol_run, a.corr_seq+1, trunc(sysdate), a.channel, a.prod_grp, a.prod_type,
                 a.clm_date, a.tot_res, a.tot_paid, null, trunc(sysdate), '4'
         from mis_clm_mas_seq a
         where a.clm_no in (select distinct clm_no
                      from   mis_clmgm_paid
          where  batch_no = P_number)
            and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                                      from mis_clm_mas_seq b
                                                    where a.clm_no = b.clm_no
                                                 group by b.clm_no);
          p_sts := null;
      exception
         when others then
                 p_sts := 'Error';
           dbms_output.put_line('Mis_clm_mas_seq - reopen :'||p_sts);
      end;

      begin
         insert into clm_medical_res
         (
         clm_no,state_no,state_seq,fleet_seq,sub_seq,plan,pd_flag,dis_code,bene_code,recpt_seq,state_date,corr_date,
         title,name,fr_date,to_date,hpt_code,res_amt,close_date,close_code,reopen_date,loss_date,fam_sts,patronize,
         paid_sts,cancel,contact,remark,deduct_amt,clm_pd_flag,seq,fam_seq,dept_bki,id_no,disc_amt,ipd_day
         )
         select a.clm_no, a.state_no, a.state_seq+1, a.fleet_seq, a.sub_seq, a.plan, a.pd_flag, a.dis_code, a.bene_code, a.recpt_seq, a.state_date, trunc(sysdate),
                 a.title, a.name, a.fr_date, a.to_date, a.hpt_code, a.res_amt, null, null, trunc(sysdate), a.loss_date, a.fam_sts, a.patronize,
                 a.paid_sts, a.cancel, a.contact, a.remark, a.deduct_amt, a.clm_pd_flag, a.seq, a.fam_seq, a.dept_bki, a.id_no, a.disc_amt, a.ipd_day
         from  clm_medical_res a
         where a.clm_no in (select distinct clm_no
                                from   mis_clmgm_paid
                            where  batch_no = P_number)
            and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                                         from clm_medical_res b
                                                       where a.clm_no = b.clm_no
                                                          and a.state_no = b.state_no
                                                   group by b.state_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Clm_medical_res - reopen :'||p_msg);
        end;

  begin
         insert into clm_gm_paid
         (
         clm_no,pay_no,corr_seq,fleet_seq,sub_seq,plan,pd_flag,dis_code,bene_code,loss_date,date_paid,corr_date,
         disc_rate,disc_amt,pay_amt,hpt_code,rec_amt,clm_pd_flag,remark,sur_percent,ipd_day,seq,rec_pay_date,
         deduct_amt,fam_seq,dept_bki,id_no
         )
         select a.clm_no, a.pay_no, a.corr_seq+1, a.fleet_seq, a.sub_seq, a.plan, a.pd_flag, a.dis_code, a.bene_code, a.loss_date, a.date_paid, trunc(sysdate),
                  0.0, 0, 0, a.hpt_code, 0, a.clm_pd_flag, a.remark, 0, a.ipd_day, a.seq, null,
                  0, a.fam_seq, a.dept_bki, a.id_no
         from  clm_gm_paid a
         where a.pay_no in (select distinct pay_no
                                 from  mis_clmgm_paid
                            where  batch_no = P_number)
         and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                  from clm_gm_paid b
                                                where a.pay_no = b.pay_no
                                                 group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Clm_gm_paid :'||p_msg);
        end;

        begin
         insert into clm_gm_payee
         (
         clm_no,pay_no,pay_seq,payee_type,payee_code,payee_amt,pay_type,payee_name
          )
         select a.clm_no, a.pay_no, a.pay_seq+1, a.payee_type, a.payee_code, 0, a.pay_type, a.payee_name
         from  clm_gm_payee a
         where a.pay_no in (select distinct pay_no
                                 from  mis_clmgm_paid
                            where  batch_no = P_number)
          and (a.pay_no,a.pay_seq) in (select b.pay_no,max(b.pay_seq)
                                                      from clm_gm_payee b
                                                      where a.pay_no = b.pay_no
                                                 group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Clm_gm_payee :'||p_msg);
        end;

  begin
         insert into mis_clmgm_paid
         (
         clm_no,pay_no,corr_seq,pay_date,pay_total,rec_total,disc_total,settle,part,remark,
         lett_recno,permit,permit_date,acc_no,acc_name,acc_type,bank_code,branch_code,rec_pay_date
          )
         select a.clm_no, a.pay_no, a.corr_seq+1, a.pay_date, 0, 0, 0, a.settle, a.part, a.remark,
                a.lett_recno, a.permit, a.permit_date, a.acc_no, a.acc_name, a.acc_type, a.bank_code, a.branch_code, a.rec_pay_date
         from  mis_clmgm_paid a
         where a.pay_no in (select distinct pay_no
                                  from  mis_clmgm_paid
                             where  batch_no = P_number)
           and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                      from mis_clmgm_paid b
                                                      where a.pay_no = b.pay_no
                                                 group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mis_clmgm_paid :'||p_msg);
        end;

  begin
         insert into mis_clm_mas_seq
         (
         clm_no, pol_no, pol_run, corr_seq, corr_date, channel, prod_grp, prod_type,
         clm_date, tot_res, tot_paid, close_date, reopen_date, clm_sts
         )
         select a.clm_no, a.pol_no, a.pol_run, a.corr_seq+1, trunc(sysdate), a.channel, a.prod_grp, a.prod_type,
                 a.clm_date, a.tot_res, 0, trunc(sysdate), null, '3'
         from mis_clm_mas_seq a
         where a.clm_no in (select distinct clm_no
                      from   mis_clmgm_paid
          where  batch_no = P_number)
            and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                          from mis_clm_mas_seq b
                                         where a.clm_no = b.clm_no
                                         group by b.clm_no);
          p_sts := null;
        exception
         when others then
                 p_sts := 'Error';
           dbms_output.put_line('Mis_clm_mas_seq - cwp :'||p_sts);
        end;

        begin
         insert into clm_medical_res
         (
         clm_no,state_no,state_seq,fleet_seq,sub_seq,plan,pd_flag,dis_code,bene_code,recpt_seq,state_date,corr_date,
         title,name,fr_date,to_date,hpt_code,res_amt,close_date,close_code,reopen_date,loss_date,fam_sts,patronize,
         paid_sts,cancel,contact,remark,deduct_amt,clm_pd_flag,seq,fam_seq,dept_bki,id_no,disc_amt,ipd_day
         )
         select a.clm_no, a.state_no, a.state_seq+1, a.fleet_seq, a.sub_seq, a.plan, a.pd_flag, a.dis_code, a.bene_code, a.recpt_seq, a.state_date, trunc(sysdate),
                 a.title, a.name, a.fr_date, a.to_date, a.hpt_code, a.res_amt, trunc(sysdate), null, null, a.loss_date, a.fam_sts, a.patronize,
                 a.paid_sts, a.cancel, a.contact, a.remark, 0, a.clm_pd_flag, a.seq, a.fam_seq, a.dept_bki, a.id_no, 0, a.ipd_day
         from  clm_medical_res a
         where a.clm_no  in (select distinct clm_no
                        from   mis_clmgm_paid
            where  batch_no = P_number)
            and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                                         from clm_medical_res b
                                                       where a.clm_no = b.clm_no
                                                          and a.state_no = b.state_no
                                                   group by b.state_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Clm_medical_res - cwp :'||p_msg);
        end;

        begin
           insert into mis_cri_res
           (
           clm_no,ri_code,ri_br_code,ri_cont,ri_type,your_pol,ri_res_date,ri_res_amt,ri_shr,lett_no,lett_remark,lett_prt,lett_type,
           cwp_remark,cwp_no,res_sts,corr_seq,lf_flag,ri_sub_type,polyj_flag
           )
           select a.clm_no, a.ri_code, a.ri_br_code, a.ri_cont, a.ri_type, a.your_pol, a.ri_res_date, 0, a.ri_shr, a.lett_no, a.lett_remark, a.lett_prt, a.lett_type,
                   a.cwp_remark, a.cwp_no, a.res_sts, a.corr_seq+1, a.lf_flag, a.ri_sub_type, a.polyj_flag
           from mis_cri_res a
           where a.clm_no  in (select distinct clm_no
                                     from mis_clmgm_paid
                                   where batch_no = P_number)
           and a.res_sts = '0'
           and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                                   from mis_cri_res b
                                                   where a.clm_no = b.clm_no
                                                   and a.res_sts = b.res_sts
                                                   group by b.clm_no) ;
           P_msg := null;
        exception
          when others then
          P_msg := 'Error';
         dbms_output.put_line('Mis_cri_res :'||p_msg);
        end;

        begin
          insert into mis_cri_paid
          (
          clm_no,pay_no,pay_sts,ri_code,ri_br_code,ri_cont,ri_type,pay_amt,lett_no,lett_remark,lett_prt,lett_type,
          corr_seq,lf_flag,ri_sub_type,polyj_flag
          )
          select a.clm_no, a.pay_no, a.pay_sts, a.ri_code, a.ri_br_code, a.ri_cont, a.ri_type, 0, a.lett_no, a.lett_remark, a.lett_prt, a.lett_type,
                  a.corr_seq+1, a.lf_flag, a.ri_sub_type, a.polyj_flag
          from mis_cri_paid a
          where a.clm_no  in (select distinct clm_no
                                   from mis_clmgm_paid
                               where batch_no = P_number)
          and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                   from mis_cri_paid b
                                                   where a.clm_no = b.clm_no
                                                   and a.pay_no = b.pay_no
                                                   group by b.pay_no) ;
          P_msg := null;
       exception
         when others then
         P_msg := 'Error';
        dbms_output.put_line('Mis_cri_paid :'||p_msg);
       end;

  begin
    update mis_clm_mas
    set    tot_paid = 0, reopen_date = trunc(sysdate), close_date = trunc(sysdate), clm_sts = '3'
    where  clm_no in (select distinct clm_no
                        from   mis_clmgm_paid
            where  batch_no = P_number) ;
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Mis_clm_mas :'||p_msg);
        end;

    begin
    update clm_medical_paid
    set    max_day_clm = 0, max_amt_clm = 0, max_agr_amt = 0
    where  clm_no in (select distinct clm_no
                        from   mis_clmgm_paid
            where  batch_no = P_number) ;
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Clm_medical_paid :'||p_msg);
        end;

    begin
    delete clmgm_batch_tmp
    where batch_no = P_number;
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Clmgm_batch_tmp :'||p_msg);
        end;

    begin
      update clm_gm_recov
      set    cancel_flag = 'Y'
      where  clm_no in (select distinct clm_no
                        from mis_clmgm_paid
                   where batch_no = P_number)
      and    recv_sts = '0';
      P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Clm_gm_recov :'||p_msg);
        end;
    end if;
  end if;

  if  P_prod_grp = '0'   then   /* PA */
    if P_flag = 'P' and v_chk_prod = 'P' then
       begin
         select distinct clm_no
          into   v_clm_no
        from   mis_clm_paid
        where  pay_no = P_number;
       exception
         when others then
                 v_clm_no := null;
         dbms_output.put_line('PA - Cannot find claim number');
       end;

      begin
         insert into mis_clm_mas_seq
         (
         clm_no, pol_no, pol_run, corr_seq, corr_date, channel, prod_grp, prod_type,
         clm_date, tot_res, tot_paid, close_date, reopen_date, clm_sts
         )
         select a.clm_no, a.pol_no, a.pol_run, a.corr_seq+1, trunc(sysdate), a.channel, a.prod_grp, a.prod_type,
                 a.clm_date, a.tot_res, 0, null, trunc(sysdate), '4'
         from mis_clm_mas_seq a
         where a.clm_no = v_clm_no
            and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                                      from mis_clm_mas_seq b
                                                    where a.clm_no = b.clm_no
                                                 group by b.clm_no);
          p_sts := null;
      exception
         when others then
                 p_sts := 'Error';
           dbms_output.put_line('PA - Mis_clm_mas_seq - reopen :'||p_sts);
      end;

      begin
         insert into mis_cpa_res
         (
         clm_no,fleet_seq,res_seq,res_date,loss_name,loss_date,loss_detail,risk_code,prem_code1,prem_code2,prem_code3,prem_code4,
         prem_code5,prem_code6,prem_code7,prem_code8,prem_code9,prem_code10,prem_code11,prem_code12,prem_code13,prem_code14,prem_code15,
         prem_code16,prem_code17,prem_code18,prem_code19,prem_code20,prem_code21,prem_code22,prem_code23,prem_code24,prem_code25,
         prem_pay1,prem_pay2,prem_pay3,prem_pay4,prem_pay5,prem_pay6,prem_pay7,prem_pay8,prem_pay9,prem_pay10,
         prem_pay11,prem_pay12,prem_pay13,prem_pay14,prem_pay15,prem_pay16,prem_pay17,prem_pay18,prem_pay19,prem_pay20,
         prem_pay21,prem_pay22,prem_pay23,prem_pay24,prem_pay25,
         res_type,res_sts,res_flag,cancel,revise_seq,corr_date,dis_code,hpt_code,loss_of_day,res_remark,loss_date_fr,loss_date_to,add_day,hpt_seq
         )
         select a.clm_no,a.fleet_seq,a.res_seq,a.res_date,a.loss_name,a.loss_date,a.loss_detail,a.risk_code,a.prem_code1,a.prem_code2,
         a.prem_code3,a.prem_code4,a.prem_code5,a.prem_code6,a.prem_code7,a.prem_code8,a.prem_code9,a.prem_code10,a.prem_code11,
         a.prem_code12,a.prem_code13,a.prem_code14,a.prem_code15,a.prem_code16,a.prem_code17,a.prem_code18,a.prem_code19,a.prem_code20,
         a.prem_code21,a.prem_code22,a.prem_code23,a.prem_code24,a.prem_code25,nvl(a.prem_pay1,0),nvl(a.prem_pay2,0),nvl(a.prem_pay3,0),
         nvl(a.prem_pay4,0),nvl(a.prem_pay5,0),nvl(a.prem_pay6,0),nvl(a.prem_pay7,0),nvl(a.prem_pay8,0),nvl(a.prem_pay9,0),nvl(a.prem_pay10,0),
         nvl(a.prem_pay11,0),nvl(a.prem_pay12,0),nvl(a.prem_pay13,0),nvl(a.prem_pay14,0),nvl(a.prem_pay15,0),nvl(a.prem_pay16,0),nvl(a.prem_pay17,0),
         nvl(a.prem_pay18,0),nvl(a.prem_pay19,0),nvl(a.prem_pay20,0),nvl(a.prem_pay21,0),nvl(a.prem_pay22,0),nvl(a.prem_pay23,0),nvl(a.prem_pay24,0),
         nvl(a.prem_pay25,0),
         'R','0','0',cancel,revise_seq+1,trunc(sysdate),dis_code,hpt_code,loss_of_day,res_remark,loss_date_fr,loss_date_to,add_day,hpt_seq
         from  mis_cpa_res a
         where a.clm_no = v_clm_no
         and (a.res_seq,a.revise_seq) in (select b.res_seq,max(b.revise_seq)
                                          from   mis_cpa_res b
                                          where  a.clm_no = b.clm_no
                                          and    a.res_seq = b.res_seq
                                          group by b.res_seq) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('PA - Mis_cpa_res - reopen :'||p_msg);
        end;

     --   begin
     --    update mis_cpa_paid set cancel = 'C'
     --    where  clm_no = v_clm_no
     --    and    pay_no = P_number;

     --    P_msg  := null;
     --    exception
     --    when others then
     --            P_msg := 'Error';
     --            dbms_output.put_line('Update Mis_cpa_paid :'||p_msg);
     --   end;

        begin
         insert into mis_cpa_paid
         (
         clm_no,pay_no,pay_sts,fleet_seq,loss_name,loss_date,loss_detail,paid_remark,prem_code1,prem_code2,prem_code3,prem_code4,prem_code5,
         prem_code6,prem_code7,prem_code8,prem_code9,prem_code10,prem_code11,prem_code12,prem_code13,prem_code14,prem_code15,prem_code16,
         prem_code17,prem_code18,prem_code19,prem_code20,prem_code21,prem_code22,prem_code23,prem_code24,prem_code25,prem_pay1,prem_pay2,
         prem_pay3,prem_pay4,prem_pay5,prem_pay6,prem_pay7,prem_pay8,prem_pay9,prem_pay10,prem_pay11,prem_pay12,prem_pay13,prem_pay14,
         prem_pay15,prem_pay16,prem_pay17,prem_pay18,prem_pay19,prem_pay20,prem_pay21,prem_pay22,prem_pay23,prem_pay24,prem_pay25,cancel,
         risk_code,run_seq,corr_seq,dis_code,hpt_code,loss_of_day,loss_date_fr,loss_date_to,add_day,hpt_seq
         )
         select a.clm_no, a.pay_no, a.pay_sts,a.fleet_seq,a.loss_name,a.loss_date,a.loss_detail,a.paid_remark,a.prem_code1,a.prem_code2,
         a.prem_code3,a.prem_code4,a.prem_code5,a.prem_code6,a.prem_code7,a.prem_code8,a.prem_code9,a.prem_code10,a.prem_code11,a.prem_code12,
         a.prem_code13,a.prem_code14,a.prem_code15,a.prem_code16,a.prem_code17,a.prem_code18,a.prem_code19,a.prem_code20,a.prem_code21,
         a.prem_code22,a.prem_code23,a.prem_code24,a.prem_code25,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'C',a.risk_code,a.run_seq,
         a.corr_seq+1,a.dis_code,a.hpt_code,a.loss_of_day,a.loss_date_fr,a.loss_date_to,a.add_day,hpt_seq
         from  mis_cpa_paid a
         where a.clm_no = v_clm_no
            and a.pay_no = P_number
            and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                          from   mis_cpa_paid b
                                          where  a.clm_no = b.clm_no
                                          and    a.pay_no = b.pay_no
                                          and    a.pay_sts = b.pay_sts
                                          and    a.run_seq = b.run_seq
                                          group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mis_cpa_paid :'||p_msg);
        end;

        begin
         delete from mis_clm_payee
         where  clm_no = v_clm_no
         and    pay_no = P_number;

         P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mis_clm_payee :'||p_msg);
        end;

    begin
         insert into mis_clm_paid
         (
         clm_no,pay_no,pay_sts,pay_date,pay_total,settle,pay_type,prt_flag,attached,acc_no,acc_name,bank_code,br_name,remark,
         pay_curr_code,pay_curr_rate,trn_date,app_sts,total_pay_total,vat_amt,rem_close,corr_seq,corr_date,tot_deduct_amt,state_flag,
         vat_percent,deduct_amt,rec_pay_date,sendchq_addr,send_title,send_addr1,send_addr2,bank_br_code,polyj_flag,acc_type,branch_code,
         batch_no,print_type,reprint_no
          )
         select a.clm_no,a.pay_no,a.pay_sts,a.pay_date,0,a.settle,a.pay_type,a.prt_flag,a.attached,null,null,null,null,a.remark,
         null,0,a.trn_date,a.app_sts,0,0,a.rem_close,a.corr_seq+1,trunc(sysdate),0,a.state_flag,null,0,trunc(sysdate),null,null,null,null,
         null,a.polyj_flag,null,null,a.batch_no,a.print_type,a.reprint_no
         from  mis_clm_paid a
         where a.clm_no = v_clm_no
            and a.pay_no = P_number
            and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                          from mis_clm_paid b
                                          where a.clm_no = b.clm_no
                                           and a.pay_no = b.pay_no
                                           group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mis_clm_paid :'||p_msg);
        end;

     begin
         insert into mis_cri_res
         (
         clm_no,ri_code,ri_br_code,ri_cont,ri_type,your_pol,ri_res_date,ri_res_amt,ri_shr,lett_no,lett_remark,lett_prt,lett_type,
         cwp_remark,cwp_no,res_sts,corr_seq,lf_flag,ri_sub_type,polyj_flag
         )
         select a.clm_no, a.ri_code, a.ri_br_code, a.ri_cont, a.ri_type, a.your_pol, a.ri_res_date, a.ri_res_amt, a.ri_shr, a.lett_no, a.lett_remark, a.lett_prt, a.lett_type,
                 a.cwp_remark, a.cwp_no, a.res_sts, a.corr_seq+1, a.lf_flag, a.ri_sub_type, a.polyj_flag
         from  mis_cri_res a
         where a.clm_no = v_clm_no
           and  a.res_sts = '0'
           and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                                         from mis_cri_res b
                                                       where a.clm_no = b.clm_no
                                                          and a.res_sts = b.res_sts
                                                   group by b.clm_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('PA - Mis_cri_res :'||p_msg);
        end;

       begin
         insert into mis_cri_paid
         (
         clm_no,pay_no,pay_sts,ri_code,ri_br_code,ri_cont,ri_type,pay_amt,lett_no,lett_remark,lett_prt,lett_type,
         corr_seq,lf_flag,ri_sub_type,polyj_flag
         )
         select a.clm_no, a.pay_no, a.pay_sts, a.ri_code, a.ri_br_code, a.ri_cont, a.ri_type, 0, a.lett_no, a.lett_remark, a.lett_prt, a.lett_type,
                 a.corr_seq+1, a.lf_flag, a.ri_sub_type, a.polyj_flag
         from  mis_cri_paid a
         where a.clm_no = v_clm_no
           and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                         from mis_cri_paid b
                                                       where a.clm_no = b.clm_no
                                                          and a.pay_no = b.pay_no
                                                   group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('PA - Mis_cri_paid :'||p_msg);
        end;

  begin
    update mis_clm_mas
    set    tot_paid = 0, reopen_date = trunc(sysdate), close_date = null, clm_sts = '4'
    where  clm_no = v_clm_no;
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Mis_clm_mas :'||p_msg);
        end;

    begin
    delete clm_batch_tmp
    where pay_no = P_number;
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Clm_batch_tmp :'||p_msg);
        end;

    elsif P_flag = 'B' and substr(P_number,5,1) = '1' then
      begin
         insert into mis_clm_mas_seq
         (
         clm_no, pol_no, pol_run, corr_seq, corr_date, channel, prod_grp, prod_type,
         clm_date, tot_res, tot_paid, close_date, reopen_date, clm_sts
         )
         select a.clm_no, a.pol_no, a.pol_run, a.corr_seq+1, trunc(sysdate), a.channel, a.prod_grp, a.prod_type,
                 a.clm_date, a.tot_res, 0, null, trunc(sysdate), '4'
         from mis_clm_mas_seq a
         where a.clm_no in (select distinct clm_no
                          from   mis_clm_paid
                      where  batch_no = P_number)
         and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                       from mis_clm_mas_seq b
                                       where a.clm_no = b.clm_no
                                       group by b.clm_no);
          p_sts := null;
      exception
         when others then
                 p_sts := 'Error';
           dbms_output.put_line('Mis_clm_mas_seq - reopen :'||p_sts);
      end;

      begin
         insert into mis_cpa_res
         (
         clm_no,fleet_seq,res_seq,res_date,loss_name,loss_date,loss_detail,risk_code,prem_code1,prem_code2,prem_code3,prem_code4,
         prem_code5,prem_code6,prem_code7,prem_code8,prem_code9,prem_code10,prem_code11,prem_code12,prem_code13,prem_code14,prem_code15,
         prem_code16,prem_code17,prem_code18,prem_code19,prem_code20,prem_code21,prem_code22,prem_code23,prem_code24,prem_code25,
         prem_pay1,prem_pay2,prem_pay3,prem_pay4,prem_pay5,prem_pay6,prem_pay7,prem_pay8,prem_pay9,prem_pay10,
         prem_pay11,prem_pay12,prem_pay13,prem_pay14,prem_pay15,prem_pay16,prem_pay17,prem_pay18,prem_pay19,prem_pay20,
         prem_pay21,prem_pay22,prem_pay23,prem_pay24,prem_pay25,
         res_type,res_sts,res_flag,cancel,revise_seq,corr_date,dis_code,hpt_code,loss_of_day,res_remark,loss_date_fr,loss_date_to,add_day,hpt_seq
         )
         select a.clm_no,a.fleet_seq,a.res_seq,a.res_date,a.loss_name,a.loss_date,a.loss_detail,a.risk_code,a.prem_code1,a.prem_code2,
         a.prem_code3,a.prem_code4,a.prem_code5,a.prem_code6,a.prem_code7,a.prem_code8,a.prem_code9,a.prem_code10,a.prem_code11,
         a.prem_code12,a.prem_code13,a.prem_code14,a.prem_code15,a.prem_code16,a.prem_code17,a.prem_code18,a.prem_code19,a.prem_code20,
         a.prem_code21,a.prem_code22,a.prem_code23,a.prem_code24,a.prem_code25,nvl(a.prem_pay1,0),nvl(a.prem_pay2,0),nvl(a.prem_pay3,0),
         nvl(a.prem_pay4,0),nvl(a.prem_pay5,0),nvl(a.prem_pay6,0),nvl(a.prem_pay7,0),nvl(a.prem_pay8,0),nvl(a.prem_pay9,0),nvl(a.prem_pay10,0),
         nvl(a.prem_pay11,0),nvl(a.prem_pay12,0),nvl(a.prem_pay13,0),nvl(a.prem_pay14,0),nvl(a.prem_pay15,0),nvl(a.prem_pay16,0),nvl(a.prem_pay17,0),
         nvl(a.prem_pay18,0),nvl(a.prem_pay19,0),nvl(a.prem_pay20,0),nvl(a.prem_pay21,0),nvl(a.prem_pay22,0),nvl(a.prem_pay23,0),nvl(a.prem_pay24,0),
         nvl(a.prem_pay25,0),
         'R','0','0',cancel,revise_seq+1,trunc(sysdate),dis_code,hpt_code,loss_of_day,res_remark,loss_date_fr,loss_date_to,add_day,hpt_seq
         from  mis_cpa_res a
         where a.clm_no in (select distinct clm_no
                          from   mis_clm_paid
                      where  batch_no = P_number)
         and (a.res_seq,a.revise_seq) in (select b.res_seq,max(b.revise_seq)
                                          from   mis_cpa_res b
                                          where  a.clm_no = b.clm_no
                                          and    a.res_seq = b.res_seq
                                          group by b.res_seq) ;
         P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('PA - Mis_cpa_res - reopen :'||p_msg);
        end;

    --    begin
    --     update mis_cpa_paid set cancel = 'C'
    --     where  pay_no  in (select distinct pay_no
  --                        from   mis_clm_paid
  --                    where  batch_no = P_number);

    --     P_msg  := null;
    --     exception
    --     when others then
    --             P_msg := 'Error';
    --             dbms_output.put_line('Update Mis_cpa_paid :'||p_msg);
    --    end;

  begin
         insert into mis_cpa_paid
         (
         clm_no,pay_no,pay_sts,fleet_seq,loss_name,loss_date,loss_detail,paid_remark,prem_code1,prem_code2,prem_code3,prem_code4,prem_code5,
         prem_code6,prem_code7,prem_code8,prem_code9,prem_code10,prem_code11,prem_code12,prem_code13,prem_code14,prem_code15,prem_code16,
         prem_code17,prem_code18,prem_code19,prem_code20,prem_code21,prem_code22,prem_code23,prem_code24,prem_code25,prem_pay1,prem_pay2,
         prem_pay3,prem_pay4,prem_pay5,prem_pay6,prem_pay7,prem_pay8,prem_pay9,prem_pay10,prem_pay11,prem_pay12,prem_pay13,prem_pay14,
         prem_pay15,prem_pay16,prem_pay17,prem_pay18,prem_pay19,prem_pay20,prem_pay21,prem_pay22,prem_pay23,prem_pay24,prem_pay25,cancel,
         risk_code,run_seq,corr_seq,dis_code,hpt_code,loss_of_day,loss_date_fr,loss_date_to,add_day,hpt_seq
         )
         select a.clm_no, a.pay_no, a.pay_sts,a.fleet_seq,a.loss_name,a.loss_date,a.loss_detail,a.paid_remark,a.prem_code1,a.prem_code2,
         a.prem_code3,a.prem_code4,a.prem_code5,a.prem_code6,a.prem_code7,a.prem_code8,a.prem_code9,a.prem_code10,a.prem_code11,a.prem_code12,
         a.prem_code13,a.prem_code14,a.prem_code15,a.prem_code16,a.prem_code17,a.prem_code18,a.prem_code19,a.prem_code20,a.prem_code21,
         a.prem_code22,a.prem_code23,a.prem_code24,a.prem_code25,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'C',a.risk_code,a.run_seq,
         a.corr_seq+1,a.dis_code,a.hpt_code,a.loss_of_day,a.loss_date_fr,a.loss_date_to,a.add_day,hpt_seq
         from  mis_cpa_paid a
         where a.pay_no in (select distinct pay_no
                          from   mis_clm_paid
                      where  batch_no = P_number)
            and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                          from   mis_cpa_paid b
                                          where  a.clm_no = b.clm_no
                                          and    a.pay_no = b.pay_no
                                          and    a.pay_sts = b.pay_sts
                                          and    a.run_seq = b.run_seq
                                          group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mis_cpa_paid :'||p_msg);
        end;

        begin
         delete from mis_clm_payee
         where  pay_no in (select distinct pay_no
                         from   mis_clm_paid
                     where  batch_no = P_number);

         P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mis_clm_payee :'||p_msg);
        end;

  begin
         insert into mis_clm_paid
         (
         clm_no,pay_no,pay_sts,pay_date,pay_total,settle,pay_type,prt_flag,attached,acc_no,acc_name,bank_code,br_name,remark,
         pay_curr_code,pay_curr_rate,trn_date,app_sts,total_pay_total,vat_amt,rem_close,corr_seq,corr_date,tot_deduct_amt,state_flag,
         vat_percent,deduct_amt,rec_pay_date,sendchq_addr,send_title,send_addr1,send_addr2,bank_br_code,polyj_flag,acc_type,branch_code,
         batch_no,print_type,reprint_no
          )
         select a.clm_no,a.pay_no,a.pay_sts,a.pay_date,0,a.settle,a.pay_type,a.prt_flag,a.attached,null,null,null,null,a.remark,
         null,0,a.trn_date,a.app_sts,0,0,a.rem_close,a.corr_seq+1,trunc(sysdate),0,a.state_flag,null,0,trunc(sysdate),null,null,null,null,
         null,a.polyj_flag,null,null,a.batch_no,a.print_type,a.reprint_no
         from  mis_clm_paid a
         where a.pay_no in (select distinct pay_no
                          from   mis_clm_paid
                      where  batch_no = P_number)
         and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                       from mis_clm_paid b
                                       where a.clm_no = b.clm_no
                                       and a.pay_no = b.pay_no
                                       group by b.pay_no) ;
         P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mis_clm_paid :'||p_msg);
        end;

      begin
           insert into mis_cri_res
           (
           clm_no,ri_code,ri_br_code,ri_cont,ri_type,your_pol,ri_res_date,ri_res_amt,ri_shr,lett_no,lett_remark,lett_prt,lett_type,
           cwp_remark,cwp_no,res_sts,corr_seq,lf_flag,ri_sub_type,polyj_flag
           )
           select a.clm_no, a.ri_code, a.ri_br_code, a.ri_cont, a.ri_type, a.your_pol, a.ri_res_date, a.ri_res_amt, a.ri_shr, a.lett_no, a.lett_remark, a.lett_prt, a.lett_type,
                   a.cwp_remark, a.cwp_no, a.res_sts, a.corr_seq+1, a.lf_flag, a.ri_sub_type, a.polyj_flag
           from mis_cri_res a
           where a.clm_no  in (select distinct clm_no
                             from   mis_clm_paid
                            where  batch_no = P_number)
           and a.res_sts = '0'
           and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                         from mis_cri_res b
                                         where a.clm_no = b.clm_no
                                         and a.res_sts = b.res_sts
                                         group by b.clm_no) ;
           P_msg := null;
        exception
          when others then
          P_msg := 'Error';
         dbms_output.put_line('Mis_cri_res :'||p_msg);
        end;

        begin
          insert into mis_cri_paid
          (
          clm_no,pay_no,pay_sts,ri_code,ri_br_code,ri_cont,ri_type,pay_amt,lett_no,lett_remark,lett_prt,lett_type,
          corr_seq,lf_flag,ri_sub_type,polyj_flag
          )
          select a.clm_no, a.pay_no, a.pay_sts, a.ri_code, a.ri_br_code, a.ri_cont, a.ri_type, 0, a.lett_no, a.lett_remark, a.lett_prt, a.lett_type,
                  a.corr_seq+1, a.lf_flag, a.ri_sub_type, a.polyj_flag
          from mis_cri_paid a
          where a.clm_no  in (select distinct clm_no
                                   from mis_clm_paid
                               where batch_no = P_number)
          and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                        from mis_cri_paid b
                                        where a.clm_no = b.clm_no
                                        and a.pay_no = b.pay_no
                                        group by b.pay_no) ;
          P_msg := null;
       exception
         when others then
         P_msg := 'Error';
        dbms_output.put_line('Mis_cri_paid :'||p_msg);
       end;

  begin
    update mis_clm_mas
    set    tot_paid = 0, reopen_date = trunc(sysdate), close_date = null, clm_sts = '4'
    where  clm_no in (select distinct clm_no
                      from   mis_clm_paid
                  where  batch_no = P_number);
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Mis_clm_mas :'||p_msg);
        end;

    begin
    delete clm_batch_tmp
    where batch_no = P_number;
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Clm_batch_tmp :'||p_msg);
        end;
    end if;
  end if;

  if  P_prod_grp in ('4','5','9') then   /* Misc */
    if P_flag = 'P' then
       begin
         select distinct clm_no
          into   v_clm_no
         from   mis_clm_paid
        where  pay_no = P_number;
       exception
         when others then
                 v_clm_no := null;
         dbms_output.put_line('Misc - Cannot find claim number');
       end;

       begin
         select count(a.pay_no)
           into v_cnt_pay
           from mis_clm_paid a
          where a.clm_no = v_clm_no
            and a.pay_sts = '0'
            and a.state_flag = '1'
            and (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq)
                                           from mis_clm_paid b
                                          where b.clm_no = a.clm_no
                                            and b.pay_no = a.pay_no
                                            and b.pay_sts = a.pay_sts
                                            and b.state_flag = a.state_flag
                                       group by b.pay_no);
       exception
         when others then
              v_cnt_pay := 0;
         dbms_output.put_line('Misc - Cannot count payment');
       end;

       begin
         select sum(nvl(a.pay_total,0))
           into v_sum_allpay
           from mis_clm_paid a
          where a.clm_no = v_clm_no
            and a.pay_sts = '0'
            and a.state_flag = '1'
            and (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq)
                                           from mis_clm_paid b
                                          where b.clm_no = a.clm_no
                                            and b.pay_no = a.pay_no
                                            and b.pay_sts = a.pay_sts
                                            and b.state_flag = a.state_flag
                                       group by b.pay_no);
       exception
         when others then
              v_sum_allpay := 0;
         dbms_output.put_line('Misc - Cannot sum all payment amount');
       end;

       begin
         select sum(nvl(a.pay_total,0))
           into v_sum_pay
           from mis_clm_paid a
          where a.clm_no = v_clm_no
            and a.pay_no = P_number
            and a.pay_sts = '0'
            and a.state_flag = '1'
            and (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq)
                                           from mis_clm_paid b
                                          where b.clm_no = a.clm_no
                                            and b.pay_no = a.pay_no
                                            and b.pay_sts = a.pay_sts
                                            and b.state_flag = a.state_flag
                                       group by b.pay_no);
       exception
         when others then
              v_sum_pay := 0;
         dbms_output.put_line('Misc - Cannot sum payment amount');
       end;

       begin
         select clm_sts
           into v_clm_sts
           from mis_clm_mas
          where clm_no = v_clm_no;
       exception
         when others then
              v_clm_sts := null;
         dbms_output.put_line('Misc - Cannot find claim status');
      end;

      if  v_clm_sts in ('2','3')  then
          begin
            insert into mis_clm_mas_seq
            (
            clm_no, pol_no, pol_run, corr_seq, corr_date, channel, prod_grp, prod_type,
            clm_date, tot_res, tot_paid, close_date, reopen_date, clm_sts
            )
            select a.clm_no, a.pol_no, a.pol_run, a.corr_seq+1, trunc(sysdate), a.channel, a.prod_grp, a.prod_type,
                   a.clm_date, a.tot_res, v_sum_allpay - v_sum_pay, null, trunc(sysdate), '4'
            from mis_clm_mas_seq a
            where a.clm_no = v_clm_no
            and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                          from mis_clm_mas_seq b
                                          where a.clm_no = b.clm_no
                                          group by b.clm_no);
            p_sts := null;
          exception
            when others then
                 p_sts := 'Error';
            dbms_output.put_line('Misc - Mis_clm_mas_seq - reopen :'||p_sts);
          end;

          begin
            insert into mis_cms_res
            (
            clm_no,sectn,risk_code,prem_code,type,res_seq,res_date,res_amt,res_type,res_sts,res_flag,tot_res_amt,res_no,corr_date,co_res_amt
            )
            select a.clm_no,a.sectn,a.risk_code,a.prem_code,a.type,a.res_seq+1,a.res_date,a.res_amt,'R',a.res_sts,decode(v_cnt_pay,0,'0',1,'0',2,'1','1') res_flag,
                   nvl(a.tot_res_amt,0),a.res_no,trunc(sysdate),nvl(a.co_res_amt,0)
            from  mis_cms_res a
            where a.clm_no = v_clm_no
            and  a.res_sts = '0'
            and (a.clm_no,a.res_seq) in (select b.clm_no,max(b.res_seq)
                                         from   mis_cms_res b
                                         where  a.clm_no = b.clm_no
                                         and    a.res_sts = b.res_sts
                                         group by b.clm_no) ;
            P_msg := null;
          exception
               when others then
                    P_msg := 'Error';
               dbms_output.put_line('Misc - Mis_cms_res - reopen :'||p_msg);
          end;

          begin
      update mis_clm_mas
      set    tot_paid = v_sum_allpay - v_sum_pay, reopen_date = trunc(sysdate), clm_sts = '4'
      where  clm_no = v_clm_no;
      P_msg := null;
          exception
             when others then
                  P_msg := 'Error';
             dbms_output.put_line('Misc - Mis_clm_mas :'||p_msg);
          end;
      else
          begin
            insert into mis_clm_mas_seq
            (
            clm_no, pol_no, pol_run, corr_seq, corr_date, channel, prod_grp, prod_type,
            clm_date, tot_res, tot_paid, close_date, reopen_date, clm_sts
            )
            select a.clm_no, a.pol_no, a.pol_run, a.corr_seq+1, trunc(sysdate), a.channel, a.prod_grp, a.prod_type,
                   a.clm_date, a.tot_res, v_sum_allpay - v_sum_pay, a.close_date, a.reopen_date, a.clm_sts
            from mis_clm_mas_seq a
            where a.clm_no = v_clm_no
            and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                          from mis_clm_mas_seq b
                                          where a.clm_no = b.clm_no
                                          group by b.clm_no);
            p_sts := null;
          exception
            when others then
                 p_sts := 'Error';
            dbms_output.put_line('Misc - Mis_clm_mas_seq - not reopen :'||p_sts);
          end;

          begin
            insert into mis_cms_res
            (
            clm_no,sectn,risk_code,prem_code,type,res_seq,res_date,res_amt,res_type,res_sts,res_flag,tot_res_amt,res_no,corr_date,co_res_amt
            )
            select a.clm_no,a.sectn,a.risk_code,a.prem_code,a.type,a.res_seq+1,a.res_date,a.res_amt,'O',a.res_sts,decode(v_cnt_pay,0,'0',1,'0',2,'1','1') res_flag,
                   nvl(a.tot_res_amt,0),a.res_no,trunc(sysdate),nvl(a.co_res_amt,0)
            from  mis_cms_res a
            where a.clm_no = v_clm_no
            and  a.res_sts = '0'
            and (a.clm_no,a.res_seq) in (select b.clm_no,max(b.res_seq)
                                         from   mis_cms_res b
                                         where  a.clm_no = b.clm_no
                                         and    a.res_sts = b.res_sts
                                         group by b.clm_no) ;
            P_msg := null;
          exception
               when others then
                    P_msg := 'Error';
               dbms_output.put_line('Misc - Mis_cms_res - not reopen :'||p_msg);
          end;

          begin
      update mis_clm_mas
      set    tot_paid = v_sum_allpay - v_sum_pay, reopen_date = trunc(sysdate), clm_sts = '4'
      where  clm_no = v_clm_no;
      P_msg := null;
          exception
             when others then
                  P_msg := 'Error';
             dbms_output.put_line('Misc - Mis_clm_mas :'||p_msg);
          end;

      end if;

       begin
         insert into mis_cms_paid
         (
         clm_no,pay_no,pay_sts,sectn,risk_code,prem_code,type,corr_seq,pay_amt,deduct_amt,total_pay_amt,tot_deduct_amt,vat_amt,co_pay_amt,
         co_deduct_amt,salvage_amt,payee_code
         )
         select a.clm_no, a.pay_no, a.pay_sts, a.sectn, a.risk_code, a.prem_code, a.type, a.corr_seq+1, 0, 0, 0, 0, 0, 0,
                0, 0, a.payee_code
         from  mis_cms_paid a
         where a.clm_no = v_clm_no
           and a.pay_no = P_number
           and a.pay_sts = '0'
           and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                          from   mis_cms_paid b
                                          where  a.clm_no = b.clm_no
                                          and    a.pay_no = b.pay_no
                                          and    a.pay_sts = b.pay_sts
                                        group by b.pay_no) ;
         P_msg := null;
       exception
         when others then
              P_msg := 'Error';
         dbms_output.put_line('Misc - Mis_cms_paid :'||p_msg);
       end;

       begin
         delete from mis_clm_payee
         where  clm_no = v_clm_no
         and    pay_no = P_number;

         P_msg := null;
       exception
         when others then
              P_msg := 'Error';
         dbms_output.put_line('Misc - Mis_clm_payee :'||p_msg);
       end;

       begin
         insert into mis_clm_paid
         (
         clm_no,pay_no,pay_sts,pay_date,pay_total,settle,pay_type,prt_flag,attached,acc_no,acc_name,bank_code,br_name,remark,
         pay_curr_code,pay_curr_rate,trn_date,app_sts,total_pay_total,vat_amt,rem_close,corr_seq,corr_date,tot_deduct_amt,state_flag,
         vat_percent,deduct_amt,rec_pay_date,sendchq_addr,send_title,send_addr1,send_addr2,bank_br_code,polyj_flag,acc_type,branch_code,
         batch_no,print_type,reprint_no
          )
         select a.clm_no,a.pay_no,a.pay_sts,a.pay_date,0,a.settle,a.pay_type,a.prt_flag,a.attached,null,null,null,null,a.remark,
         null,0,a.trn_date,a.app_sts,0,0,a.rem_close,a.corr_seq+1,trunc(sysdate),0,a.state_flag,null,0,trunc(sysdate),null,null,null,null,
         null,a.polyj_flag,null,null,a.batch_no,a.print_type,a.reprint_no
         from  mis_clm_paid a
         where a.clm_no = v_clm_no
            and a.pay_no = P_number
            and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                          from mis_clm_paid b
                                          where a.clm_no = b.clm_no
                                           and a.pay_no = b.pay_no
                                           group by b.pay_no) ;
                 P_msg := null;
       exception
         when others then
              P_msg := 'Error';
         dbms_output.put_line('Misc - Mis_clm_paid :'||p_msg);
       end;

       begin
         insert into mis_cri_res
         (
         clm_no,ri_code,ri_br_code,ri_cont,ri_type,your_pol,ri_res_date,ri_res_amt,ri_shr,lett_no,lett_remark,lett_prt,lett_type,
         cwp_remark,cwp_no,res_sts,corr_seq,lf_flag,ri_sub_type,polyj_flag
         )
         select a.clm_no, a.ri_code, a.ri_br_code, a.ri_cont, a.ri_type, a.your_pol, a.ri_res_date, a.ri_res_amt, a.ri_shr, a.lett_no, a.lett_remark, a.lett_prt, a.lett_type,
                 a.cwp_remark, a.cwp_no, a.res_sts, a.corr_seq+1, a.lf_flag, a.ri_sub_type, a.polyj_flag
         from  mis_cri_res a
         where a.clm_no = v_clm_no
           and  a.res_sts = '0'
           and (a.clm_no,a.corr_seq) in (select b.clm_no,max(b.corr_seq)
                                                         from mis_cri_res b
                                                       where a.clm_no = b.clm_no
                                                          and a.res_sts = b.res_sts
                                                   group by b.clm_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Misc - Mis_cri_res :'||p_msg);
       end;

       begin
         insert into mis_cri_paid
         (
         clm_no,pay_no,pay_sts,ri_code,ri_br_code,ri_cont,ri_type,pay_amt,lett_no,lett_remark,lett_prt,lett_type,
         corr_seq,lf_flag,ri_sub_type,polyj_flag
         )
         select a.clm_no, a.pay_no, a.pay_sts, a.ri_code, a.ri_br_code, a.ri_cont, a.ri_type, 0, a.lett_no, a.lett_remark, a.lett_prt, a.lett_type,
                 a.corr_seq+1, a.lf_flag, a.ri_sub_type, a.polyj_flag
         from  mis_cri_paid a
         where a.clm_no = v_clm_no
           and a.pay_no = P_number
           and a.pay_sts = '0'
           and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                         from mis_cri_paid b
                                                       where a.clm_no = b.clm_no
                                                          and a.pay_no = b.pay_no
                                                          and a.pay_sts = b.pay_sts
                                                   group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Misc - Mis_cri_paid :'||p_msg);
        end;

        begin
        delete clm_batch_tmp
        where pay_no = P_number;
        P_msg := null;
          exception
          when others then
               P_msg := 'Error';
          dbms_output.put_line('Clm_batch_tmp :'||p_msg);
        end;
    end if;
    P_NON_PA_CLM.p_cancel_payment_bki(v_clm_no,P_number,v_chk_sts,p_msg);
  end if;

  if  P_prod_grp = '2' and P_prod_type in ('21','23','221','223')  then
     if P_flag = 'P' then
       begin
         select a.clm_no, nvl(a.tot_amt,0)
          into   v_clm_no, v_paid_amt
        from   mrn_paid_stat a
        where  a.state_no = P_number
        and     a.type = '01'
        and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                                         from mrn_paid_stat b
                                                        where a.clm_no = b.clm_no
                                                           and a.state_no = b.state_no
                                                           and b.type = '01'
                                                    group by b.state_no) ;
       exception
         when others then
                 v_clm_no := null;
                 v_paid_amt := 0;
         dbms_output.put_line('Cannot find claim number');
       end;

       begin
         insert into mrn_paid_stat
         (
         clm_no,state_no,state_seq,type,state_date,pa_amt,ga_amt,sur_amt,set_amt,rec_amt,exp_amt,tot_amt,
         descr_paid,ben_amt,typ_flag,corr_date,remark,vat_amt,print_type
         )
         select a.clm_no, a.state_no, a.state_seq+1, a.type, a.state_date, 0, 0, 0, 0, 0, 0, 0,
                 a.descr_paid, 0, a.typ_flag, trunc(sysdate), a.remark, 0, a.print_type
         from  mrn_paid_stat a
         where a.clm_no = v_clm_no
            and a.state_no = P_number
            and a.type = '01'
            and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                                         from mrn_paid_stat b
                                                        where a.clm_no = b.clm_no
                                                           and a.state_no = b.state_no
                                                           and b.type = '01'
                                                    group by b.state_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mrn_paid_stat :'||p_msg);
        end;

        begin
         insert into mrn_clm_paid
         (
         clm_no,pay_type,state_no,state_seq,type,pay_date,pay_agt,pay_sign,pay_for_amt,
         pay_rte,pay_amt,pay_agt_sts,pay_recp_sts,pay_vat_amt,offset_flag
         )
         select a.clm_no, a.pay_type, a.state_no, a.state_seq+1, a.type, trunc(sysdate), a.pay_agt, a.pay_sign, 0,
                  0, 0, a.pay_agt_sts, a.pay_recp_sts, 0, a.offset_flag
         from  mrn_clm_paid a
         where a.clm_no = v_clm_no
            and a.state_no = P_number
            and a.type = '01'
            and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                                         from mrn_clm_paid b
                                                        where a.clm_no = b.clm_no
                                                           and a.state_no = b.state_no
                                                           and b.type = '01'
                                                    group by b.state_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mrn_clm_paid :'||p_msg);
        end;

        begin
         insert into mrn_clm_payee
         (
         clm_no,state_no,state_seq,type,pay_date,pay_type,pay_agt,pay_amt,settle,cheque_no,
         acc_no,acc_name,bank_code,br_name,other,item_no,payee_code,br_code,pay_agt_sts
         )
         select a.clm_no, a.state_no, a.state_seq+1, a.type, trunc(sysdate), a.pay_type, a.pay_agt, 0, a.settle, a.cheque_no,
                  a.acc_no, a.acc_name, a.bank_code, a.br_name, a.other, a.item_no, a.payee_code, a.br_code, a.pay_agt_sts
         from  mrn_clm_payee a
         where a.clm_no = v_clm_no
            and a.state_no = P_number
            and a.type = '01'
            and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                                         from mrn_clm_payee b
                                                        where a.clm_no = b.clm_no
                                                           and a.state_no = b.state_no
                                                           and b.type = '01'
                                                    group by b.state_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mrn_clm_payee :'||p_msg);
        end;

        begin
         insert into mrn_ri_paid
         (
         clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,cess_pay_no,ri_shr,ri_pay_amt
         )
         select a.clm_no, a.state_no, a.state_seq+1, a.type, a.ri_code, a.ri_br_code, a.lf_flag, a.ri_type1, a.ri_type2, a.cess_pay_no, a.ri_shr, 0
         from  mrn_ri_paid a
         where a.clm_no = v_clm_no
            and a.state_no = P_number
            and a.type = '01'
            and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                                         from mrn_ri_paid b
                                                        where a.clm_no = b.clm_no
                                                           and a.state_no = b.state_no
                                                           and b.type = '01'
                                                    group by b.state_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Mrn_ri_paid :'||p_msg);
        end;

     begin
    update mrn_clm_mas
    set    tot_paid = nvl(tot_paid,0) - v_paid_amt
    where  clm_no = v_clm_no ;
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Mrn_clm_mas :'||p_msg);
      end;

     end if;
     P_NON_PA_CLM.p_cancel_payment_bki(v_clm_no,P_number,v_chk_sts,p_msg);
  end if;

  if  P_prod_grp = '2' and P_prod_type in ('22','222')  then
     if P_flag = 'P' then
       begin
         select a.clm_no, nvl(a.paid_amt,0)
         into   v_clm_no, v_paid_amt
         from   hull_paid_stat a
         where  a.pay_no = P_number
         and     a.type = '01'
         and (a.pay_no,a.pay_seq) in (select b.pay_no,max(b.pay_seq)
                                      from hull_paid_stat b
                                      where a.clm_no = b.clm_no
                                      and a.pay_no = b.pay_no
                                      and b.type = '01'
                                      group by b.pay_no) ;
       exception
         when others then
                 v_clm_no := null;
                 v_paid_amt := 0;
         dbms_output.put_line('Cannot find claim number');
       end;

       begin
         insert into hull_paid_stat
         (
         clm_no,pay_no,pay_seq,type,paid_date,corr_date,bal_est_amt,
         paid_amt,typ_flag,paid_for_amt,print_type
         )
         select a.clm_no, a.pay_no, a.pay_seq+1, a.type, a.paid_date, trunc(sysdate),0,
                0, a.typ_flag, 0, a.print_type
         from  hull_paid_stat a
         where a.clm_no = v_clm_no
            and a.pay_no = P_number
            and a.type = '01'
            and (a.pay_no,a.pay_seq) in (select b.pay_no,max(b.pay_seq)
                                         from hull_paid_stat b
                                         where a.clm_no = b.clm_no
                                         and   a.pay_no = b.pay_no
                                         and   b.type = '01'
                                         group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Hull_paid_stat :'||p_msg);
        end;

        begin
         insert into hull_clm_paid
         (
         clm_no,pay_type,pay_no,pay_seq,type,paid_date,pay_agt,pay_sign,bal_for_amt,
         pay_for_amt,pay_rte,vat_amt,pay_agt_sts,pay_amt
         )
         select a.clm_no, a.pay_type, a.pay_no, a.pay_seq+1, a.type, trunc(sysdate), a.pay_agt, a.pay_sign, 0,
                  0, 0, 0,a.pay_agt_sts, 0
         from  hull_clm_paid a
         where a.clm_no = v_clm_no
           and a.pay_no = P_number
           and a.type = '01'
           and (a.pay_no,a.pay_seq) in (select b.pay_no,max(b.pay_seq)
                                          from hull_clm_paid b
                                         where a.clm_no = b.clm_no
                                           and a.pay_no = b.pay_no
                                           and b.type = '01'
                                           group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Hull_clm_paid :'||p_msg);
        end;

        begin
         insert into hull_clm_payee
         (
         clm_no,pay_no,pay_seq,ben_seq,type,paid_date,pay_agt,descr_ben,pay_amt,settle,cheque_no,
         acc_no,acc_name,bank_code,br_code,other,payee_code,pay_agt_sts
         )
         select a.clm_no, a.pay_no, a.pay_seq+1, a.ben_seq, a.type, trunc(sysdate), a.pay_agt, a.descr_ben, 0, a.settle, a.cheque_no,
                  a.acc_no, a.acc_name, a.bank_code, a.br_code, a.other, a.payee_code, a.pay_agt_sts
         from  hull_clm_payee a
         where a.clm_no = v_clm_no
           and a.pay_no = P_number
           and a.type = '01'
           and (a.pay_no,a.pay_seq) in (select b.pay_no,max(b.pay_seq)
                                          from hull_clm_payee b
                                         where a.clm_no = b.clm_no
                                           and a.pay_no = b.pay_no
                                           and b.type = '01'
                                           group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Hull_clm_payee :'||p_msg);
        end;

        begin
         insert into hull_ri_paid
         (
         clm_no,pay_no,pay_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,cess_no,ri_shr,ri_bal_amt,ri_pay_amt
         )
         select a.clm_no, a.pay_no, a.pay_seq+1, a.type, a.ri_code, a.ri_br_code, a.lf_flag, a.ri_type1, a.ri_type2, a.cess_no, a.ri_shr, 0, 0
         from  hull_ri_paid a
         where a.clm_no = v_clm_no
            and a.pay_no = P_number
            and a.type = '01'
            and (a.pay_no,a.pay_seq) in (select b.pay_no,max(b.pay_seq)
                                           from hull_ri_paid b
                                          where a.clm_no = b.clm_no
                                            and a.pay_no = b.pay_no
                                            and b.type = '01'
                                            group by b.pay_no) ;
                 P_msg := null;
         exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Hull_ri_paid :'||p_msg);
        end;

     begin
    update hull_clm_mas
    set    tot_paid = nvl(tot_paid,0) - v_paid_amt
    where  clm_no = v_clm_no ;
    P_msg := null;
        exception
        when others then
             P_msg := 'Error';
             dbms_output.put_line('Mrn_clm_mas :'||p_msg);
      end;

     end if;
     P_NON_PA_CLM.p_cancel_payment_bki(v_clm_no,P_number,v_chk_sts,p_msg);
  end if;

  if  P_prod_grp = '1' then
     if P_flag = 'P' then
       begin
         select a.clm_no, nvl(a.tot_our_loss,0)
           into v_clm_no, v_paid_amt
           from fir_paid_stat a
          where a.state_no = P_number
            and a.type = '01'
            and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                               from fir_paid_stat b
                                              where a.clm_no = b.clm_no
                                                and a.state_no = b.state_no
                                                and b.type = '01'
                                           group by b.state_no);
       exception
         when others then
              v_clm_no := null;
              v_paid_amt := 0;
         dbms_output.put_line('Cannot find claim number');
       end;

       begin
         insert into fir_paid_stat
         (
         clm_no,state_no,state_seq,type,state_date,corr_date,build_tot_loss,build_our_loss,mach_tot_loss,mach_our_loss,stock_tot_loss,stock_our_loss,
         furn_tot_loss,furn_our_loss,other_tot_loss,other_our_loss,sur_tot_loss,sur_our_loss,rec_tot_loss,rec_our_loss,set_tot_loss,set_our_loss,
         tot_tot_loss,tot_our_loss,descr_paid,type_flag,remark,vat_amt,print_type,batch_no,reprint_no,pay_date,state_flag
         )
         select a.clm_no, a.state_no, a.state_seq+1, a.type, a.state_date, trunc(sysdate), 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, a.descr_paid, a.type_flag, a.remark, a.vat_amt, a.print_type, a.batch_no, a.reprint_no, a.pay_date, a.state_flag
         from  fir_paid_stat a
         where a.clm_no = v_clm_no
           and a.state_no = P_number
           and a.type = '01'
           and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                              from fir_paid_stat b
                                             where a.clm_no = b.clm_no
                                               and a.state_no = b.state_no
                                               and b.type = '01'
                                          group by b.state_no) ;
         P_msg := null;
       exception
         when others then
              P_msg := 'Error';
              dbms_output.put_line('Fir_paid_stat :'||p_msg);
       end;

       begin
         insert into fir_clm_paid
         (
         clm_no,pay_type,state_no,state_seq,type,pay_date,pay_agt,pay_sign,pay_for_amt,
         pay_rte,pay_amt,pay_agt_sts,pay_recp_sts
         )
         select a.clm_no, a.pay_type, a.state_no, a.state_seq+1, a.type, trunc(sysdate), a.pay_agt, a.pay_sign, 0,
                  0, 0, a.pay_agt_sts, a.pay_recp_sts
         from  fir_clm_paid a
         where a.clm_no = v_clm_no
           and a.state_no = P_number
           and a.type = '01'
           and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                              from fir_clm_paid b
                                             where a.clm_no = b.clm_no
                                               and a.state_no = b.state_no
                                               and b.type = '01'
                                          group by b.state_no) ;
         P_msg := null;
       exception
         when others then
                 P_msg := 'Error';
                 dbms_output.put_line('Fir_clm_paid :'||p_msg);
       end;

       begin
         insert into fir_clm_payee
         (
         clm_no,state_no,state_seq,type,item_no,pay_date,pay_agt_sts,pay_for_amt,pay_amt,settle,curr_code,cheque_no,
         acc_no,acc_name,bank_code,bank_name,br_name,app_date,other,descr_ben,sent,descr_sent,salvage_amt,deduct_amt,
         bank_br_code,send_title,send_addr1,send_addr2,payee_code,payee_offset,payee_offset2
         )
         select a.clm_no, a.state_no, a.state_seq+1, a.type, a.item_no, trunc(sysdate), a.pay_agt_sts, 0, 0, a.settle, a.curr_code,a.cheque_no,
                a.acc_no, a.acc_name, a.bank_code, a.bank_name, a.br_name, a.app_date, a.other, a.descr_ben, a.sent, a.descr_sent, 0, 0,
                a.bank_br_code, a.send_title, a.send_addr1, a.send_addr2, a.payee_code, a.payee_offset, a.payee_offset2
         from  fir_clm_payee a
         where a.clm_no = v_clm_no
           and a.state_no = P_number
           and a.type = '01'
           and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                              from fir_clm_payee b
                                             where a.clm_no = b.clm_no
                                               and a.state_no = b.state_no
                                               and b.type = '01'
                                          group by b.state_no) ;
         P_msg := null;
       exception
         when others then
              P_msg := 'Error';
              dbms_output.put_line('Fir_clm_payee :'||p_msg);
       end;

       begin
         insert into fir_ri_paid
         (
         clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_lf_flag,ri_type,ri_sub_type,ri_share,ri_app_no,ri_pay_amt
         )
         select a.clm_no, a.state_no, a.state_seq+1, a.type, a.ri_code, a.ri_br_code, a.ri_lf_flag, a.ri_type, a.ri_sub_type, a.ri_share,
                a.ri_app_no, 0
           from fir_ri_paid a
          where a.clm_no = v_clm_no
            and a.state_no = P_number
            and a.type = '01'
            and (a.state_no,a.state_seq) in (select b.state_no,max(b.state_seq)
                                               from fir_ri_paid b
                                              where a.clm_no = b.clm_no
                                                and a.state_no = b.state_no
                                                and b.type = '01'
                                           group by b.state_no) ;
         P_msg := null;
       exception
         when others then
              P_msg := 'Error';
              dbms_output.put_line('Fir_ri_paid :'||p_msg);
       end;

       begin
       update fir_clm_mas
          set tot_paid = nvl(tot_paid,0) - v_paid_amt
        where clm_no = v_clm_no ;
       P_msg := null;
       exception
         when others then
              P_msg := 'Error';
              dbms_output.put_line('Fir_clm_mas :'||p_msg);
       end;

     end if;
     P_NON_PA_CLM.p_cancel_payment_bki(v_clm_no,P_number,v_chk_sts,p_msg);
  end if;

  EXCEPTION
      when others then
               P_msg := 'Error';
              dbms_output.put_line('Error clm status:'||v_sts);
  END;
  PROCEDURE get_clm_sts(P_prod_grp IN varchar2,P_prod_type IN varchar2,
                                     P_flag In varchar2 , /* P = payment ,B = batch_no */
                                     p_number in varchar2,   /*payment no or batch*/
                                     P_sts OUT varchar2 /*C = Close claim or cwp,P = Pending,E = Error*/) IS
      v_cnt_close      number := 0;
      v_cnt_pedding  number := 0;
  BEGIN

     if (P_prod_grp = '3' or P_prod_type = '335')  and P_flag = 'P' then
        begin
            select count(*)
              into v_cnt_close
              from mtr_clm_tab a
           where a.clm_mark is not null
             and   exists (select 1 from mtr_payment_tab b
                                 where a.clm_no = b.clm_no
                                  and b.pay_no = p_number);
        exception
           when others then
                   v_cnt_close := 1;
        end;
        if nvl(v_cnt_close,0) = 0 then
           P_sts    := null;
        else
           P_sts    := 'C';
        end if;
    elsif (P_prod_grp = '3' or P_prod_type = '335') and P_flag = 'B' then
        begin
            select count(*)
              into v_cnt_close
              from mtr_clm_tab a
           where  a.clm_mark is not null
             and   exists (select 1 from mtr_payment_tab b
                                 where a.clm_no = b.clm_no
                                  and b.batch_no = p_number);
        exception
           when others then
                   v_cnt_close := 1;
        end;
        begin
            select count(*)
              into v_cnt_pedding
              from mtr_clm_tab a
           where a.clm_mark   is   null
             and   exists (select 1 from mtr_payment_tab b
                                 where a.clm_no = b.clm_no
                                  and b.batch_no = p_number );
        exception
           when others then
                   v_cnt_pedding := 1;
        end;
        if nvl(v_cnt_close,0) > 0 and nvl(v_cnt_pedding,0) > 0 then
           P_sts    := 'C';
        elsif nvl(v_cnt_close,0) = 0 and nvl(v_cnt_pedding,0) >  0 then
           P_sts    := null;
        else
            P_sts    := 'E';
        end if;
    end if;
  EXCEPTION
      when others then
             P_sts  := 'E';
  END;
  PROCEDURE Set_paid_date_motor_old(P_flag IN varchar2 , /* P = payment ,B = batch_no */
                                                   P_number IN varchar2,   /*payment no or batch*/
                                                   P_vou_date IN date,
                                                    P_userid In varchar2,
                                                   P_msg OUT varchar2 /*Error = update error*/) IS
   v_trn_date date := null;
   p_sts varchar2(30) := null;
  BEGIN
  if P_flag = 'P' then
      begin
          update mtr_payment_tab a
               set a.paid_date = P_vou_date ,a.state_flag = '1'
          where a.pay_no = P_number
             and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                      from mtr_payment_tab b
                                                    where a.clm_no = b.clm_no
                                                       and a.pay_no = b.pay_no
                                               group by b.pay_no);
             P_sts := null;
      exception
         when others then
                  P_sts := 'Error';
      end;
      if P_sts is null then
           begin
                update mtr_ri_paid a
                     set a.corr_date = P_vou_date,a.ri_paid_date = P_vou_date
                 where a.pay_no   = P_number
                    and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                              from mtr_ri_paid b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);

           exception
               when others then
                     P_msg := 'Error';
           end;
      end if;
    elsif P_flag = 'B' then
      begin
          select max(a.trn_date)
             into v_trn_date
             from mtr_payment_tab a
          where a.batch_no = P_number
             and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                      from mtr_payment_tab b
                                                    where a.clm_no = b.clm_no
                                                       and a.pay_no = b.pay_no
                                               group by b.pay_no);
      exception
          when others then
                  v_trn_date := trunc(sysdate) + 1;
      end;
          if  P_vou_date = v_trn_date then
              begin
                  update mtr_payment_tab a
                       set a.paid_date = P_vou_date  ,a.state_flag = '1'
                  where a.batch_no = P_number
                     and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                              from mtr_payment_tab b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);
                     P_sts := null;
              exception
                 when others then
                          P_sts := 'Error';
              end;
              if P_sts is null then
                  begin
                        update mtr_ri_paid a
                             set a.corr_date = P_vou_date,a.ri_paid_date = P_vou_date
                         where a.pay_no in (select ab.pay_no
                                                        from mtr_payment_tab ab
                                                       where a.clm_no = ab.clm_no
                                                          and a.pay_no = ab.pay_no
                                                          and ab.batch_no = P_number
                                                          and nvl(ab.state_flag,'0') = '1')
                            and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                                      from mtr_ri_paid b
                                                                    where a.clm_no = b.clm_no
                                                                       and a.pay_no = b.pay_no
                                                               group by b.pay_no);
                  exception
                        when others then
                             P_msg := 'Error';
                  end;
              else
                   P_msg := 'Error';
              end if;
         else
              begin
                 insert into mtr_payment_tab
                 (
                 TRN_DATE, CLM_NO, PAID_DATE, PAY_NO, PAY_CODE, PAYEE_NO, PAY_AMT, LINE_NO,
                 DEDUCT_MARK, PAY_TYPE, PAY_MARK, BR_CODE, PAYEE_TYPE, DRV_NO, BANK_CODE,
                 BANK_BR, ACCOUNT_NO, APPOINT_MARK, APPROVE_MARK, VOUCHER_MARK, TRN_SEQ,
                 VAT, APPOINT_FLAG, PAY_TIME, ACC_TYPE, APPROVE_FLAG, APPROVE_USER_ID, BATCH_NO,
                 USER_ID, VAT_FLAG, RECOV_FLAG, RECOV_FLAG_DATE, BILL_DATE, REC_TIME,
                 APPOINT_DATE, STATE_FLAG,PAY_DAYS, BR_WALKIN
                 )
                 select trunc(sysdate), a.CLM_NO, P_vou_date, a.PAY_NO, a.PAY_CODE, a.PAYEE_NO,a.pay_amt, a.LINE_NO,
                 a.DEDUCT_MARK, a.PAY_TYPE,a.pay_mark, a.BR_CODE, a.PAYEE_TYPE, a.DRV_NO, a.BANK_CODE,
                 a.BANK_BR, a.ACCOUNT_NO, a.APPOINT_MARK, a.APPROVE_MARK, a.VOUCHER_MARK, a.TRN_SEQ+1,
                 a.VAT, a.APPOINT_FLAG, a.PAY_TIME, a.ACC_TYPE, a.APPROVE_FLAG, a.APPROVE_USER_ID, a.BATCH_NO,
                 P_userid, a.VAT_FLAG, a.RECOV_FLAG, a.RECOV_FLAG_DATE, a.BILL_DATE, a.REC_TIME,
                 a.APPOINT_DATE, '1' ,a.PAY_DAYS, a.BR_WALKIN
                 from mtr_payment_tab a
                 where a.batch_no = P_number
                    and a.state_flag = '0'
                    and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                              from mtr_payment_tab b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);
                      p_sts := null;
              exception
                 when others then
                      p_sts := 'Error';
              end;
              if  p_sts is null then
                begin
                 insert into mtr_ri_paid
                 (CLM_NO, PAY_NO, CORR_DATE, CORR_SEQ, RI_CODE,
                 RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
                  RI_LA_NO, RI_LA_SEQ, RI_SHARE, RI_PAY_AMT, SUPPLEMENT,
                   RI_FEE, RI_VAT, RI_PAID_DATE
                 )
                 select CLM_NO, PAY_NO, P_vou_date, CORR_SEQ+1, RI_CODE,
                  RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
                  RI_LA_NO, RI_LA_SEQ, RI_SHARE, ri_pay_amt, SUPPLEMENT,
                   RI_FEE, RI_VAT, P_vou_date
                   from mtr_ri_paid a
                 where a.pay_no in (select ab.pay_no
                                                from mtr_payment_tab ab
                                               where a.clm_no = ab.clm_no
                                                  and a.pay_no = ab.pay_no
                                                  and ab.batch_no = P_number
                                                  and ab.state_flag = '0')
                    and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                              from mtr_ri_paid b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);
                         P_msg := null;
                 exception
                 when others then
                         P_msg := 'Error';
                 end;
              else
                       P_msg := 'Error';
             end if;
         end if;
     else
       P_msg := 'Error';
     end if;
  END;
 PROCEDURE Set_paid_date_motor(P_flag IN varchar2 , /* P = payment ,B = batch_no */
                                                   P_number IN varchar2,   /*payment no or batch*/
                                                   P_vou_date IN date,
                                                    P_userid In varchar2,
                                                   P_msg OUT varchar2 /*Error = update error*/) IS
   v_trn_date date := null;
   p_sts varchar2(30) := null;
  BEGIN
  if P_flag = 'P' then
      begin
          select max(a.trn_date)
             into v_trn_date
             from mtr_payment_tab a
          where a.pay_no = P_number
             and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                      from mtr_payment_tab b
                                                    where a.clm_no = b.clm_no
                                                       and a.pay_no = b.pay_no
                                               group by b.pay_no);
      exception
          when others then
                  v_trn_date := trunc(sysdate) + 1;
      end;
      if  P_vou_date = v_trn_date then
                      begin
                          update mtr_payment_tab a
                               set a.paid_date = P_vou_date ,a.state_flag = '1'
                          where a.pay_no = P_number
                             and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                                      from mtr_payment_tab b
                                                                    where a.clm_no = b.clm_no
                                                                       and a.pay_no = b.pay_no
                                                               group by b.pay_no);
                             P_sts := null;
                      exception
                         when others then
                                  P_sts := 'Error';
                      end;
                      if P_sts is null then
                           begin
                                update mtr_ri_paid a
                                     set a.corr_date = P_vou_date,a.ri_paid_date = P_vou_date
                                 where a.pay_no   = P_number
                                    and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                                              from mtr_ri_paid b
                                                                            where a.clm_no = b.clm_no
                                                                               and a.pay_no = b.pay_no
                                                                       group by b.pay_no);

                           exception
                               when others then
                                     P_msg := 'Error';
                           end;
                      end if;
         else
              begin
                 insert into mtr_payment_tab
                 (
                 TRN_DATE, CLM_NO, PAID_DATE, PAY_NO, PAY_CODE, PAYEE_NO, PAY_AMT, LINE_NO,
                 DEDUCT_MARK, PAY_TYPE, PAY_MARK, BR_CODE, PAYEE_TYPE, DRV_NO, BANK_CODE,
                 BANK_BR, ACCOUNT_NO, APPOINT_MARK, APPROVE_MARK, VOUCHER_MARK, TRN_SEQ,
                 VAT, APPOINT_FLAG, PAY_TIME, ACC_TYPE, APPROVE_FLAG, APPROVE_USER_ID, BATCH_NO,
                 USER_ID, VAT_FLAG, RECOV_FLAG, RECOV_FLAG_DATE, BILL_DATE, REC_TIME,
                 APPOINT_DATE, STATE_FLAG,PAY_DAYS, BR_WALKIN
                 )
                 select trunc(sysdate), a.CLM_NO, P_vou_date, a.PAY_NO, a.PAY_CODE, a.PAYEE_NO,a.pay_amt, a.LINE_NO,
                 a.DEDUCT_MARK, a.PAY_TYPE,a.pay_mark, a.BR_CODE, a.PAYEE_TYPE, a.DRV_NO, a.BANK_CODE,
                 a.BANK_BR, a.ACCOUNT_NO, a.APPOINT_MARK, a.APPROVE_MARK, a.VOUCHER_MARK, a.TRN_SEQ+1,
                 a.VAT, a.APPOINT_FLAG, a.PAY_TIME, a.ACC_TYPE, a.APPROVE_FLAG, a.APPROVE_USER_ID, a.BATCH_NO,
                 P_userid, a.VAT_FLAG, a.RECOV_FLAG, a.RECOV_FLAG_DATE, a.BILL_DATE, a.REC_TIME,
                 a.APPOINT_DATE, '1' ,a.PAY_DAYS, a.BR_WALKIN
                 from mtr_payment_tab a
                 where a.pay_no = P_number
                    and a.state_flag = '0'
                    and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                              from mtr_payment_tab b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);
                      p_sts := null;
              exception
                 when others then
                      p_sts := 'Error';
              end;
              if  p_sts is null then
                begin
                 insert into mtr_ri_paid
                 (CLM_NO, PAY_NO, CORR_DATE, CORR_SEQ, RI_CODE,
                 RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
                  RI_LA_NO, RI_LA_SEQ, RI_SHARE, RI_PAY_AMT, SUPPLEMENT,
                   RI_FEE, RI_VAT, RI_PAID_DATE
                 )
                 select CLM_NO, PAY_NO, P_vou_date, CORR_SEQ+1, RI_CODE,
                  RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
                  RI_LA_NO, RI_LA_SEQ, RI_SHARE, ri_pay_amt, SUPPLEMENT,
                   RI_FEE, RI_VAT, P_vou_date
                   from mtr_ri_paid a
                 where a.pay_no in (select ab.pay_no
                                                from mtr_payment_tab ab
                                               where a.clm_no = ab.clm_no
                                                  and a.pay_no = ab.pay_no
                                                  and ab.pay_no = P_number
                                                  and ab.state_flag = '0')
                    and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                              from mtr_ri_paid b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);
                         P_msg := null;
                 exception
                 when others then
                         P_msg := 'Error';
                 end;
              else
                       P_msg := 'Error';
             end if;
         end if;
    elsif P_flag = 'B' then
      begin
          select max(a.trn_date)
             into v_trn_date
             from mtr_payment_tab a
          where a.batch_no = P_number
             and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                      from mtr_payment_tab b
                                                    where a.clm_no = b.clm_no
                                                       and a.pay_no = b.pay_no
                                               group by b.pay_no);
      exception
          when others then
                  v_trn_date := trunc(sysdate) + 1;
      end;
          if  P_vou_date = v_trn_date then
              begin
                  update mtr_payment_tab a
                       set a.paid_date = P_vou_date  ,a.state_flag = '1'
                  where a.batch_no = P_number
                     and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                              from mtr_payment_tab b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);
                     P_sts := null;
              exception
                 when others then
                          P_sts := 'Error';
              end;
              if P_sts is null then
                  begin
                        update mtr_ri_paid a
                             set a.corr_date = P_vou_date,a.ri_paid_date = P_vou_date
                         where a.pay_no in (select ab.pay_no
                                                        from mtr_payment_tab ab
                                                       where a.clm_no = ab.clm_no
                                                          and a.pay_no = ab.pay_no
                                                          and ab.batch_no = P_number
                                                          and nvl(ab.state_flag,'0') = '1')
                            and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                                      from mtr_ri_paid b
                                                                    where a.clm_no = b.clm_no
                                                                       and a.pay_no = b.pay_no
                                                               group by b.pay_no);
                  exception
                        when others then
                             P_msg := 'Error';
                  end;
              else
                   P_msg := 'Error';
              end if;
         else
              begin
                 insert into mtr_payment_tab
                 (
                 TRN_DATE, CLM_NO, PAID_DATE, PAY_NO, PAY_CODE, PAYEE_NO, PAY_AMT, LINE_NO,
                 DEDUCT_MARK, PAY_TYPE, PAY_MARK, BR_CODE, PAYEE_TYPE, DRV_NO, BANK_CODE,
                 BANK_BR, ACCOUNT_NO, APPOINT_MARK, APPROVE_MARK, VOUCHER_MARK, TRN_SEQ,
                 VAT, APPOINT_FLAG, PAY_TIME, ACC_TYPE, APPROVE_FLAG, APPROVE_USER_ID, BATCH_NO,
                 USER_ID, VAT_FLAG, RECOV_FLAG, RECOV_FLAG_DATE, BILL_DATE, REC_TIME,
                 APPOINT_DATE, STATE_FLAG,PAY_DAYS, BR_WALKIN
                 )
                 select trunc(sysdate), a.CLM_NO, P_vou_date, a.PAY_NO, a.PAY_CODE, a.PAYEE_NO,a.pay_amt, a.LINE_NO,
                 a.DEDUCT_MARK, a.PAY_TYPE,a.pay_mark, a.BR_CODE, a.PAYEE_TYPE, a.DRV_NO, a.BANK_CODE,
                 a.BANK_BR, a.ACCOUNT_NO, a.APPOINT_MARK, a.APPROVE_MARK, a.VOUCHER_MARK, a.TRN_SEQ+1,
                 a.VAT, a.APPOINT_FLAG, a.PAY_TIME, a.ACC_TYPE, a.APPROVE_FLAG, a.APPROVE_USER_ID, a.BATCH_NO,
                 P_userid, a.VAT_FLAG, a.RECOV_FLAG, a.RECOV_FLAG_DATE, a.BILL_DATE, a.REC_TIME,
                 a.APPOINT_DATE, '1' ,a.PAY_DAYS, a.BR_WALKIN
                 from mtr_payment_tab a
                 where a.batch_no = P_number
                    and a.state_flag = '0'
                    and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                              from mtr_payment_tab b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);
                      p_sts := null;
              exception
                 when others then
                      p_sts := 'Error';
              end;
              if  p_sts is null then
                begin
                 insert into mtr_ri_paid
                 (CLM_NO, PAY_NO, CORR_DATE, CORR_SEQ, RI_CODE,
                 RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
                  RI_LA_NO, RI_LA_SEQ, RI_SHARE, RI_PAY_AMT, SUPPLEMENT,
                   RI_FEE, RI_VAT, RI_PAID_DATE
                 )
                 select CLM_NO, PAY_NO, P_vou_date, CORR_SEQ+1, RI_CODE,
                  RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
                  RI_LA_NO, RI_LA_SEQ, RI_SHARE, ri_pay_amt, SUPPLEMENT,
                   RI_FEE, RI_VAT, P_vou_date
                   from mtr_ri_paid a
                 where a.pay_no in (select ab.pay_no
                                                from mtr_payment_tab ab
                                               where a.clm_no = ab.clm_no
                                                  and a.pay_no = ab.pay_no
                                                  and ab.batch_no = P_number
                                                  and ab.state_flag = '0')
                    and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                              from mtr_ri_paid b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);
                         P_msg := null;
                 exception
                 when others then
                         P_msg := 'Error';
                 end;
              else
                       P_msg := 'Error';
             end if;
         end if;
     else
       P_msg := 'Error';
     end if;
  END;
  PROCEDURE Get_clm_motor_org_unit(P_clm IN varchar2,
                                                       P_dept OUT varchar2,
                                                       P_div    OUT varchar2,
                                                       P_team OUT varchar2)  IS
             c_line   varchar2(3);
             c_surv   varchar2(10);
             c_ocode  varchar2(2);
             c_oseq   varchar2(3);
             c_br     varchar2(3);
             c_surv_type varchar2(1);
    BEGIN
     begin
      select line_no,survey_no,out_survey_no,out_survey_seq,br_code,survey_type
        into c_line,c_surv,c_ocode,c_oseq,c_br,c_surv_type
        from mtr_clm_tab
       where clm_no = P_CLM;
     exception
      when others then
           c_line   := null;
           c_surv   := null;
           c_ocode  := null;
           c_oseq   := null;
     end;
     if c_line is not null then
        begin
            select dept_id,div_id,team_id
              into P_dept,P_div,P_team
              from mtr_line
             where line_no = c_line;
        exception
             when others then
                  P_dept := null;
                  P_div  := null;
                  P_team := null;
        end;
     else
           if c_surv_type = 'I' then
           begin
               select dept_id,div_id,team_id
                 into P_dept,P_div,P_team
                 from bkiuser
                where user_id = substr(c_surv,3,4);
          exception
                when others then
                  P_dept := null;
                  P_div  := null;
                  P_team := null;
          end;
           elsif length(c_surv) = 3 then
          begin
              select dept_id,div_id,team_id
                into P_dept,P_div,P_team
                from mtr_line
               where line_no = c_line;
          exception
                when others then
                  P_dept := null;
                  P_div  := null;
                  P_team := null;
          end;
           end if;
           if c_line is null and c_surv is null and c_ocode is null then
                if c_br = '01' then
                  P_dept := '21';
                 P_div  := '00';
                 P_team := '00';
                else
              begin
                 select dept_id,div_id,team_id
                   into P_dept,P_div,P_team
                   from mtr_line
                     where substr(line_no,2,2) = c_br;
          exception
                when others then
                  P_dept := null;
                  P_div  := null;
                  P_team := null;
          end;
                end if;
           end if;
     end if;
     if P_dept is null and P_div is null and P_team is null then
                if c_br = '01' then
                  P_dept := '21';
                 P_div  := '00';
                 P_team := '00';
                else
              begin
                 select dept_id,div_id,team_id
                   into P_dept,P_div,P_team
                   from mtr_line
                     where substr(line_no,2,2) = c_br;
          exception
                when others then
                  P_dept := null;
                  P_div  := null;
                  P_team := null;
          end;
          end if;
     end if;
    END;
  FUNCTION get_close_claim(P_prod_grp IN varchar2,P_prod_type IN varchar2,
                                          p_claim in varchar2   /*claim no  */) RETURN varchar2 IS
     c_sts varchar2(10);
  BEGIN
    If P_prod_grp in ('0','4','5','6','7','8','9') and P_prod_type <> '335' then
       begin
          select decode(clm_sts,'2','Y','3','Y',null)
            into c_sts
            from mis_clm_mas
         where  clm_no = P_claim ;
       exception
         when others then
                  c_sts := null;
       end;
    elsif P_prod_grp = '1' then
       begin
          select decode(clm_sts,'4','Y','5','Y','7','Y',null)
             into c_sts
            from fir_clm_mas
         where  clm_no = P_claim ;
       exception
         when others then
                  c_sts := null;
       end;
    elsif P_Prod_grp = '2'  and P_prod_type in ('221','222') then
       begin
          select decode(clm_sts,'2','Y','3','Y',null)
            into c_sts
            from mrn_clm_mas
         where  clm_no = P_claim ;
       exception
         when others then
                  c_sts := null;
       end;
    elsif P_Prod_grp = '2'  and P_prod_type in ('223') then
           begin
          select decode(clm_sts,'3','Y','4','Y',null)
            into c_sts
            from hull_clm_mas
         where  clm_no = P_claim ;
       exception
         when others then
                  c_sts := null;
       end;
    elsif (P_prod_grp = '3' or P_prod_type = '335')   then
           begin
              select decode(clm_mark,'*','Y','1','Y','2','Y','3','Y','4','Y','5','Y','6','Y',null)
                into c_sts
               from mtr_clm_tab
             where  clm_no = P_claim ;
           exception
             when others then
                      c_sts := null;
           end;
    end if;
  return(c_sts);
  END;
PROCEDURE post_acr_gl (P_claim IN varchar2,P_payno IN varchar2,P_msg OUT varchar2) IS
   v_msg     varchar2(1000);
   v_err     varchar2(1000);
   v_dept    varchar2(2);
   v_div     varchar2(3);
   v_team    varchar2(3);
   v_payee_title varchar2(20);
   v_payee_name varchar2(100);
   v_vou_no  varchar2(30);
   v_paid_date date;
BEGIN
  for p1 in
  (
    select a.pol_no,a.pol_run,a.prod_type,decode(a.prod_type,'335','5','3') prod_grp,
             decode(a.prod_type,'335','04','331','03','333','30') dept_no,
             a.cus_code,a.th_eng,a.agent_code,a.agent_seq,
             b.pay_no,b.appoint_date,b.user_id,b.payee_no,b.br_code,
             sum(decode(b.pay_code,'4EX21',b.pay_amt,0)) tot_exp,
             sum(decode(substr(b.pay_code,1,1),'2',b.pay_amt,'3',b.pay_amt,'4',b.pay_amt,'6',-1*b.pay_amt,0)) tot_amt  ,
             sum(decode(substr(b.pay_code,1,1),'6',b.pay_amt,0)) tot_ded
       from mtr_clm_tab a,mtr_payment_tab b
    where a.clm_no = b.clm_no
       and  a.clm_no = P_claim
       and  b.pay_no = P_payno
       and  nvl(b.pay_mark,'N') not in ('C','L','X')
       and  substr(b.pay_code,4,2) <> '17'
       and  b.state_flag = '0'
       and  b.trn_seq = (select max(c.trn_seq)
                                    from mtr_payment_tab c
                                 where  c.clm_no = P_claim
                                     and  c.pay_no = P_payno)
  group by a.pol_no,a.pol_run,a.prod_type,decode(a.prod_type,'335','5','3') ,
             decode(a.prod_type,'335','04','331','03','333','30') ,
             a.cus_code,a.th_eng,a.agent_code,a.agent_seq,
             b.pay_no,b.appoint_date,b.user_id ,b.payee_no,b.br_code
  )
  loop
     p_claim_acr.Get_clm_motor_org_unit(P_claim,
                                      v_dept,v_div,v_team);
     begin
        select TITLE, NAME
          into v_payee_title,v_payee_name
          from acc_payee
        where payee_code = P1.payee_no;
     exception
         when others then
                  v_msg := 'Error';
     end;
     begin
        p_claim_acr.Post_acc_clm_tmp(p1.prod_grp,
                                p1.prod_type,
                                p1.pay_no,
                                p1.appoint_date,
                                P_claim,
                                p1.pol_no,
                                p1.pol_run,
                                p1.pol_no||p1.pol_run,
                                p1.pol_no||p1.pol_run,
                                p1.cus_code,
                                p1.th_eng,
                                p1.agent_code,
                                p1.agent_seq,
                                p1.user_id,
                                p1.br_code,
                                null,
                                null,
                                v_dept,v_div,v_team,
                                v_msg );
       commit;
     exception
           when others then
                v_msg := 'Error';
     end ;

  if v_msg is null then
       if nvl(p1.tot_exp,0) = nvl(p1.tot_amt,0) then
      p_claim_acr.Post_acc_clm_payee_tmp(p1.prod_grp,
                                   p1.prod_type,
                                   p1.pay_no,
                                   1,
                                   '02', -- expense 4EX21 = 02
                                   'BHT',
                                   p1.tot_amt,
                                   p1.payee_no,
                                   v_payee_title,
                                   v_payee_name,
                                   P1.dept_no ,
                                   null,
                                   p1.tot_ded,
                                   null,
                                   v_msg);
       else
      p_claim_acr.Post_acc_clm_payee_tmp( p1.prod_grp,
                                   p1.prod_type,
                                   p1.pay_no,
                                   1,
                                   '01', --Loss motor = 01
                                   'BHT',
                                   p1.tot_amt,
                                   p1.payee_no,
                                   v_payee_title,
                                   v_payee_name,
                                   p1.dept_no ,
                                   null,
                                   p1.tot_ded,
                                   null,
                                   v_msg);
       end if;
     if v_msg is null then
           commit;
        p_acc_claim.post_gl (p1.prod_grp,
                              p1.prod_type,
                              p1.pay_no,
                              'P' ,
                              v_err );  -- return null if no error
         if v_err is null then
           p_acc_claim.get_acr_voucher (p1.prod_grp,
                              p1.prod_type,
                              p1.pay_no,
                              'P' ,
                              v_vou_no,
                              v_paid_date);
           if v_vou_no is not null then
                   P_CLAIM_ACR.Set_paid_date_motor( 'P' ,
                                                   p1.pay_no,
                                                   v_paid_date,
                                                   p1.user_id,
                                                   v_msg);
                     commit;
             end if;
     else
        begin
           delete acc_clm_tmp
            where prod_grp     =  p1.prod_grp
              and prod_type    = p1.prod_type
              and payment_no   = p1.pay_no
              and appoint_date = p1.appoint_date
              and clm_no       = P_claim  ;

           delete acc_clm_payee_tmp
            where prod_grp     =  p1.prod_grp
              and prod_type    = p1.prod_type
              and payment_no   = p1.pay_no
              and payee_code   = p1.payee_no;
        exception
             when others then
                  v_err := 'Delete success';
        end;
           commit;
           P_msg := v_err||':การ Post Auto GL มีปัญหากรุณาติดต่อ IT ' ;
           end if;
      else
           P_msg := v_msg||': การ Post Auto acc_clm_payee_tmp มีปัญหาติดต่อ IT ';
     end if;
  else
        P_msg := 'การ Post Auto มีปัญหากรุณาติดต่อ IT ' ;
  end if;
  end loop;
END;
 PROCEDURE Set_billing_date_motor(P_flag IN varchar2 , /* P = payment ,B = batch_no */
                                                     P_number IN varchar2,   /*payment no or batch*/
                                                     P_bill_date IN date,
                                                      P_userid In varchar2,
                                                     P_msg OUT varchar2 /*Error = update error*/) IS
   v_trn_date date := null;
   p_sts varchar2(30) := null;
  BEGIN
  if P_flag = 'P' then
      begin
          update mtr_payment_tab a
               set a.bill_date =  P_bill_date
          where a.pay_no = P_number
             and  a.bill_date is null
             and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                      from mtr_payment_tab b
                                                    where a.clm_no = b.clm_no
                                                       and a.pay_no = b.pay_no
                                               group by b.pay_no);
             P_sts := null;
      exception
         when others then
                  P_sts := 'Error';
      end;
    elsif P_flag = 'B' then
      begin
          select max(a.trn_date)
             into v_trn_date
             from mtr_payment_tab a
          where a.batch_no = P_number
             and  a.bill_date is null
             and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                      from mtr_payment_tab b
                                                    where a.clm_no = b.clm_no
                                                       and a.pay_no = b.pay_no
                                               group by b.pay_no);
      exception
          when others then
                  v_trn_date := trunc(sysdate) + 1;
      end;
          if  P_bill_date = v_trn_date then
              begin
                  update mtr_payment_tab a
                       set a.bill_date =  P_bill_date
                  where a.batch_no = P_number
                     and  a.bill_date is null
                     and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                              from mtr_payment_tab b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);
                     P_sts := null;
              exception
                 when others then
                          P_sts := 'Error';
              end;
         else
              begin
                 insert into mtr_payment_tab
                 (
                 TRN_DATE, CLM_NO, PAID_DATE, PAY_NO, PAY_CODE, PAYEE_NO, PAY_AMT, LINE_NO,
                 DEDUCT_MARK, PAY_TYPE, PAY_MARK, BR_CODE, PAYEE_TYPE, DRV_NO, BANK_CODE,
                 BANK_BR, ACCOUNT_NO, APPOINT_MARK, APPROVE_MARK, VOUCHER_MARK, TRN_SEQ,
                 VAT, APPOINT_FLAG, PAY_TIME, ACC_TYPE, APPROVE_FLAG, APPROVE_USER_ID, BATCH_NO,
                 USER_ID, VAT_FLAG, RECOV_FLAG, RECOV_FLAG_DATE, BILL_DATE, REC_TIME,
                 APPOINT_DATE, STATE_FLAG,PAY_DAYS, BR_WALKIN
                 )
                 select trunc(sysdate), a.CLM_NO, a.PAID_DATE, a.PAY_NO, a.PAY_CODE, a.PAYEE_NO,a.pay_amt, a.LINE_NO,
                 a.DEDUCT_MARK, a.PAY_TYPE,a.pay_mark, a.BR_CODE, a.PAYEE_TYPE, a.DRV_NO, a.BANK_CODE,
                 a.BANK_BR, a.ACCOUNT_NO, a.APPOINT_MARK, a.APPROVE_MARK, a.VOUCHER_MARK, a.TRN_SEQ+1,
                 a.VAT, a.APPOINT_FLAG, a.PAY_TIME, a.ACC_TYPE, a.APPROVE_FLAG, a.APPROVE_USER_ID, a.BATCH_NO,
                 P_userid, a.VAT_FLAG, a.RECOV_FLAG, a.RECOV_FLAG_DATE, P_bill_date, a.REC_TIME,
                 a.APPOINT_DATE, a.STATE_FLAG ,a.PAY_DAYS, a.BR_WALKIN
                 from mtr_payment_tab a
                 where a.batch_no = P_number
                    and (a.pay_no,a.trn_seq) in (select b.pay_no,max(b.trn_seq)
                                                              from mtr_payment_tab b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);
                      p_sts := null;
              exception
                 when others then
                      p_sts := 'Error';
              end;
              if  p_sts is null then
                begin
                 insert into mtr_ri_paid
                 (CLM_NO, PAY_NO, CORR_DATE, CORR_SEQ, RI_CODE,
                 RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
                  RI_LA_NO, RI_LA_SEQ, RI_SHARE, RI_PAY_AMT, SUPPLEMENT,
                   RI_FEE, RI_VAT, RI_PAID_DATE
                 )
                 select CLM_NO, PAY_NO, CORR_DATE, CORR_SEQ+1, RI_CODE,
                  RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_APP_NO,
                  RI_LA_NO, RI_LA_SEQ, RI_SHARE, ri_pay_amt, SUPPLEMENT,
                   RI_FEE, RI_VAT, RI_PAID_DATE
                   from mtr_ri_paid a
                 where a.pay_no in (select ab.pay_no
                                                from mtr_payment_tab ab
                                               where a.clm_no = ab.clm_no
                                                  and a.pay_no = ab.pay_no
                                                  and ab.batch_no = P_number )
                    and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                                                              from mtr_ri_paid b
                                                            where a.clm_no = b.clm_no
                                                               and a.pay_no = b.pay_no
                                                       group by b.pay_no);
                         P_msg := null;
                 exception
                 when others then
                         P_msg := 'Error';
                 end;
              else
                       P_msg := 'Error';
             end if;
         end if;
     else
       P_msg := 'Error';
     end if;
  END;

  PROCEDURE After_post_NC_PAYMENT(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2,   /* Prod_type*/
                                                     P_success IN varchar2,   /*  post Acr Success = 'Y' , Fail or Error = 'N' */
                                                     P_note In varchar2,   /*  note for Error Case */
                                                     P_msg OUT varchar2 /*null = Success ,Not null = error*/ ) IS
    V_STATUS_RST    VARCHAR2(300);
    m_rst     VARCHAR2(300);
    vClmUser    VARCHAR2(10):='ACR'; -- fix ACR User
    V_VOUNO       acr_mas.setup_vou_no%type ;
    V_VOUDATE   acr_mas.setup_vou_date%type ;
  BEGIN
    IF NC_CLNMC908.GET_PRODUCTID2(P_prod_type) in ( 'PA' ,'GM' ) THEN
        IF nvl(P_success ,'N') = 'N' THEN -- Error post ACR
            V_STATUS_RST := NC_HEALTH_PAID.UPDATE_STATUS_AFTER_POST(P_pay_no , vClmUser, NVL(P_success,'N') ,P_note );

            IF V_STATUS_RST is not null THEN
                NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'P_CLAIM_ACR' ,'UPDATE_STATUS' ,V_STATUS_RST,
                              m_rst)   ;
                P_msg := V_STATUS_RST; return;
            END IF;

        ELSIF nvl(P_success ,'N') = 'Y' THEN -- Success post ACR
            -- Check Voucher stamp??
            p_acc_claim.get_acr_voucher ( '0' /* p_prod_grp in acr_tmp.prod_grp%type */,

            P_prod_type /* p_prod_type in acr_tmp.prod_type%type */,

            P_pay_no /* p_number in varchar2 */,   -- payment no or batch no

            'P' /* p_flag in varchar2 */,  -- 'P' = Payment, 'B' = Batch

            V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,

            V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);

            IF V_VOUNO is not null THEN -- Post Voucher Success

                V_STATUS_RST := NC_HEALTH_PAID.UPDATE_STATUS_AFTER_POST(P_pay_no , vClmUser, NVL(P_success,'N') ,P_note );

                IF V_STATUS_RST is not null THEN
                    NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'P_CLAIM_ACR' ,'UPDATE_STATUS' ,V_STATUS_RST,
                                  m_rst)   ;
                    P_msg := V_STATUS_RST; return;
                END IF;

                V_STATUS_RST := NC_HEALTH_PAID.UPDATE_CLM_AFTER_POST(P_pay_no , nc_clnmc908.GET_PRODUCTID2(nc_clnmc908.GET_PRODUCT_TYPE(P_pay_no)) , V_VOUNO ,V_VOUDATE );
                -- update claim status ,paid_date
                IF V_STATUS_RST is not null THEN
                    NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'P_CLAIM_ACR' ,'UPDATE_CLM_AFTER_POST' ,V_STATUS_RST,
                                  m_rst)   ;
                    P_msg := V_STATUS_RST; return;
                END IF;
            ELSE
                V_STATUS_RST := NC_HEALTH_PAID.UPDATE_STATUS_AFTER_POST(P_pay_no , vClmUser, 'N' ,'Not Found VOUNO' );

                IF V_STATUS_RST is not null THEN
                    NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'P_CLAIM_ACR' ,'UPDATE_STATUS' ,V_STATUS_RST,
                                  m_rst)   ;
                    P_msg := V_STATUS_RST; return;
                END IF;
            END IF;
        ELSE
            NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'P_CLAIM_ACR' ,'UPDATE_STATUS' ,'P Success not define',
                          m_rst)   ;
            P_msg := 'P Success not define'; return;
        END IF;
    ELSE    ---- Product NONPA Claim
        IF nvl(P_success ,'N') = 'N' THEN -- Error post ACR
            V_STATUS_RST := P_NON_PA_APPROVE.UPDATE_STATUS_AFTER_POST(P_pay_no , vClmUser, NVL(P_success,'N') ,P_note );

            IF V_STATUS_RST is not null THEN
                NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'P_CLAIM_ACR' ,'UPDATE_STATUS' ,V_STATUS_RST,
                              m_rst)   ;
                P_msg := V_STATUS_RST; return;
            END IF;

        ELSIF nvl(P_success ,'N') = 'Y' THEN -- Success post ACR
            -- Check Voucher stamp??
            p_acc_claim.get_acr_voucher ( P_NON_PA_APPROVE.GET_PRODUCT_GRP(P_pay_no) /* p_prod_grp in acr_tmp.prod_grp%type */,

            P_prod_type /* p_prod_type in acr_tmp.prod_type%type */,

            P_pay_no /* p_number in varchar2 */,   -- payment no or batch no

            'P' /* p_flag in varchar2 */,  -- 'P' = Payment, 'B' = Batch

            V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,

            V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);

            IF V_VOUNO is not null THEN -- Post Voucher Success

                V_STATUS_RST := P_NON_PA_APPROVE.UPDATE_STATUS_AFTER_POST(P_pay_no , vClmUser, NVL(P_success,'N') ,P_note );

                IF V_STATUS_RST is not null THEN
                    NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'P_CLAIM_ACR' ,'UPDATE_STATUS' ,V_STATUS_RST,
                                  m_rst)   ;
                    P_msg := V_STATUS_RST; return;
                END IF;
                /*
                V_STATUS_RST := NC_HEALTH_PAID.UPDATE_CLM_AFTER_POST(P_pay_no , nc_clnmc908.GET_PRODUCTID2(nc_clnmc908.GET_PRODUCT_TYPE(P_pay_no)) , V_VOUNO ,V_VOUDATE );
                -- update claim status ,paid_date
                IF V_STATUS_RST is not null THEN
                    NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'P_CLAIM_ACR' ,'UPDATE_CLM_AFTER_POST' ,V_STATUS_RST,
                                  m_rst)   ;
                    P_msg := V_STATUS_RST; return;
                END IF;   */
            ELSE
                V_STATUS_RST := P_NON_PA_APPROVE.UPDATE_STATUS_AFTER_POST(P_pay_no , vClmUser, 'N' ,'Not Found VOUNO' );

                IF V_STATUS_RST is not null THEN
                    NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'P_CLAIM_ACR' ,'UPDATE_STATUS' ,V_STATUS_RST,
                                  m_rst)   ;
                    P_msg := V_STATUS_RST; return;
                END IF;
            END IF;
        ELSE
            NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'P_CLAIM_ACR' ,'UPDATE_STATUS' ,'P Success not define',
                          m_rst)   ;
            P_msg := 'P Success not define'; return;
        END IF;
    END IF;

  END After_post_NC_PAYMENT;

  PROCEDURE GET_SEND_ADDRESS(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2,   /* Prod_type*/
                                                     P_Send_Title OUT varchar2,   /*  Title */
                                                     P_Send_Addr1 OUT varchar2, /* Address1 */
                                                     P_Send_Addr2 OUT varchar2 /* Address2 */) IS
  BEGIN
    IF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)    in ('PA' ,'GM') THEN
        BEGIN
             select contact_name ,addr1 ,addr2
             into P_Send_Title ,P_Send_Addr1 ,P_Send_Addr2
             from clm_sent_payee a
             where key_no = P_pay_no
             and seq in (select max(x.seq) from clm_sent_payee x where x.key_no = a.key_no and x.payee_code = a.payee_code)
             and rownum =1 ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                P_Send_Title := null;
                P_Send_Addr1  := null;
                P_Send_Addr2    := null;
            WHEN OTHERS THEN
                P_Send_Title := null;
                P_Send_Addr1  := null;
                P_Send_Addr2    := null;
        END;
    END IF;
  END GET_SEND_ADDRESS;

  PROCEDURE GET_SEND_ADDRESS(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_payee_code IN varchar2 ,
                                                     P_prod_type IN varchar2,   /* Prod_type*/
                                                     P_Send_Title OUT varchar2,   /*  Title */
                                                     P_Send_Addr1 OUT varchar2, /* Address1 */
                                                     P_Send_Addr2 OUT varchar2 /* Address2 */) IS
  BEGIN
    BEGIN
         select send_title ,send_addr1 ,send_addr2
         into P_Send_Title ,P_Send_Addr1 ,P_Send_Addr2
         from nc_payee a
         where pay_no = P_pay_no
         and payee_code = P_payee_code
         and trn_seq in (select max(x.trn_seq) from nc_payee x where x.pay_no = a.pay_no)       ;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_Send_Title := null;
            P_Send_Addr1  := null;
            P_Send_Addr2    := null;
        WHEN OTHERS THEN
            P_Send_Title := null;
            P_Send_Addr1  := null;
            P_Send_Addr2    := null;
    END;
  END GET_SEND_ADDRESS;

  FUNCTION GET_LOSS_DATE(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN DATE /* loss date*/ IS
    v_lossdate DATE;
  BEGIN
    IF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  = 'PA' THEN
        BEGIN
              select loss_date into v_lossdate
             from mis_cpa_paid a
             where pay_no = P_pay_no
             and corr_seq in (select max(x.corr_seq) from mis_cpa_paid x where x.clm_no = a.clm_no and x.pay_no = a.pay_no)
             and rownum =1 ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_lossdate := null;
            WHEN OTHERS THEN
                v_lossdate := null;
        END;

    ELSIF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  = 'GM' THEN
        BEGIN
              select loss_date into v_lossdate
                from clm_gm_paid x
                where x.pay_no = P_pay_no
                and x.corr_seq in (select max(xx.corr_seq) from clm_gm_paid xx where xx.pay_no = x.pay_no and loss_date is not null  group by x.pay_no)
                and rownum=1      ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_lossdate := null;
            WHEN OTHERS THEN
                v_lossdate := null;
        END;
    ELSE    -- NONPA Claim
        BEGIN
              select loss_date into v_lossdate
                from nc_mas a
                where a.clm_no = (
                select b.clm_no from nc_payment b where b.pay_no = P_pay_no
                and rownum=1
                );
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_lossdate := null;
            WHEN OTHERS THEN
                v_lossdate := null;
        END;
    END IF;

    return v_lossdate;
  END GET_LOSS_DATE;

  FUNCTION GET_COVER_PERIOD(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* period*/  IS
    v_period varchar2(100);
  BEGIN
        IF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  in ('PA' ,'GM') THEN
            BEGIN
              select to_char(fr_date,'dd/mm/yyyy')||' to '||to_char(to_date,'dd/mm/yyyy') into v_period
             from mis_clm_mas a
             where clm_no in (
             select x.clm_no from mis_cri_paid x where x.pay_no = P_pay_no and rownum=1) ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_period := null;
            WHEN OTHERS THEN
                v_period := null;
            END;
        ELSE    -- NONPA
            BEGIN
              select to_char(fr_date,'dd/mm/yyyy')||' to '||to_char(to_date,'dd/mm/yyyy') into v_period
             from nc_mas a
             where clm_no in (
             select b.clm_no from nc_payment b where b.pay_no = P_pay_no and rownum=1
             ) ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_period := null;
            WHEN OTHERS THEN
                v_period := null;
            END;
        END IF;

    return v_period;
  END GET_COVER_PERIOD;

  FUNCTION GET_INSURE_NAME(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* Insure*/  IS
      v_insure  varchar2(250);
  BEGIN
        BEGIN
              select mas_cus_enq into v_insure
             from mis_clm_mas a
             where clm_no in (
             select x.clm_no from mis_cri_paid x where x.pay_no = P_pay_no and rownum=1) ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_insure := null;
            WHEN OTHERS THEN
                v_insure := null;
        END;
    return v_insure;
  END GET_INSURE_NAME;

  FUNCTION GET_CLAIMANT(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* Claimant*/ IS
    v_insure  varchar2(250);
  BEGIN
    IF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  = 'PA' THEN
        BEGIN
             select loss_name into v_insure
             from mis_cpa_paid a
             where pay_no = P_pay_no and corr_seq in
             (select max(b.corr_seq) from mis_cpa_paid b where b.pay_no = a.pay_no) ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_insure := null;
            WHEN OTHERS THEN
                v_insure := null;
        END;

    ELSIF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  = 'GM' THEN
        BEGIN
            select title||' '||name   into v_insure
            from clm_medical_res x
            where x.clm_no in (select y.clm_no from mis_cri_paid y where y.pay_no = P_pay_no and rownum=1 )
            and x.state_seq in (select max(xx.state_seq) from clm_medical_res xx where xx.clm_no = x.clm_no group by x.clm_no) and rownum=1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_insure := null;
            WHEN OTHERS THEN
                v_insure := null;
        END;
    END IF;
    return v_insure;
  END GET_CLAIMANT;

  FUNCTION GET_PAID_REMARK(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* Remark*/ IS
    v_remark VARCHAR2(250);
  BEGIN
    IF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  = 'PA' THEN
        BEGIN
              select paid_remark into v_remark
             from mis_cpa_paid a
             where pay_no = P_pay_no
             and corr_seq in (select max(x.corr_seq) from mis_cpa_paid x where x.clm_no = a.clm_no and x.pay_no = a.pay_no)
             and rownum =1 ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_remark := null;
            WHEN OTHERS THEN
                v_remark := null;
        END;
   ELSIF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  <> 'GM' THEN
        BEGIN
              select remark into v_remark
            from nc_payment_info a
            where pay_no = P_pay_no
            and a.trn_seq in (select max(aa.trn_seq) from nc_payment_info aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_remark := null;
            WHEN OTHERS THEN
                v_remark := null;
        END;
    END IF;

    return v_remark;
  END GET_PAID_REMARK;

    FUNCTION GET_APPROVE_ID(vPayNo in varchar2  ) RETURN VARCHAR2 IS
        v_id VARCHAR2(10);
    BEGIN

        FOR X IN (
            select APPROVE_ID
            from nc_payment x
            where pay_no = vPayNo
            and pay_sts = 'NCPAYSTS03'
        ) LOOP
            v_id := X.APPROVE_ID ;
        END LOOP;

        return v_id ;
    END GET_APPROVE_ID;

    FUNCTION GET_PRODUCTID(vProdtype IN VARCHAR2) RETURN VARCHAR2 IS
        vProd    VARCHAR2(10);
    BEGIN
      select sysid into vProd
        from clm_grp_prod
        where prod_type = vProdtype ;
        return vProd;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;
    END GET_PRODUCTID;

    FUNCTION GET_TREATMENT_DATE(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN DATE /* loss date*/ IS
    v_lossdate DATE;
    BEGIN
    IF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  = 'PA' THEN
        BEGIN
              select loss_date_fr into v_lossdate
             from mis_cpa_paid a
             where pay_no = P_pay_no
             and corr_seq in (select max(x.corr_seq) from mis_cpa_paid x where x.clm_no = a.clm_no and x.pay_no = a.pay_no)
             and rownum =1 ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_lossdate := null;
            WHEN OTHERS THEN
                v_lossdate := null;
        END;

    ELSIF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  = 'GM' THEN
    --        BEGIN
    --              select loss_date into v_lossdate
    --                from clm_gm_paid x
    --                where x.pay_no = P_pay_no
    --                and x.corr_seq in (select max(xx.corr_seq) from clm_gm_paid xx where xx.pay_no = x.pay_no and loss_date is not null  group by x.pay_no)
    --                and rownum=1      ;
    --        EXCEPTION
    --            WHEN NO_DATA_FOUND THEN
    --                v_lossdate := null;
    --            WHEN OTHERS THEN
    --                v_lossdate := null;
    --        END;
        v_lossdate := null;
    END IF;

    return v_lossdate;
    END GET_TREATMENT_DATE;

    FUNCTION GET_PARTICULAR(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /*  Particular*/ IS
    v_remark VARCHAR2(2048);
    BEGIN
    IF NC_CLNMC908.GET_PRODUCTID2(P_prod_type) in ( 'PA' ,'GM' ) THEN
        BEGIN
              select paid_remark into v_remark
             from mis_cpa_paid a
             where pay_no = P_pay_no
             and corr_seq in (select max(x.corr_seq) from mis_cpa_paid x where x.clm_no = a.clm_no and x.pay_no = a.pay_no)
             and rownum =1 ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_remark := null;
            WHEN OTHERS THEN
                v_remark := null;
        END;
    ELSE
        BEGIN
            select part into v_remark
            from nc_payment_info a
            where pay_no = P_pay_no
            and a.trn_seq in (select max(aa.trn_seq) from nc_payment_info aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_remark := null;
            WHEN OTHERS THEN
                v_remark := null;
        END;
    END IF;

    return v_remark;
    END GET_PARTICULAR;

    FUNCTION isGroupCheckByPolicy(P_payee_code IN varchar2) RETURN Boolean IS /*true = group check by payee_code+policy */
        v_rem   VARCHAR2(20);
    BEGIN
        BEGIN
            select remark into v_rem
            from clm_constant a
            where key like 'PAYEECHECKSEPE%' and remark = P_payee_code;

            return true;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                return false;
            WHEN OTHERS THEN
                return false;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            return false;
    END isGroupCheckByPolicy;

    FUNCTION getNONPA_losstype(vType  IN VARCHAR2) RETURN VARCHAR2   IS
        v_rem VARCHAR2(100);
    BEGIN
        BEGIN
            select descr into v_rem
            from clm_constant a
            where key = vType;

            return v_rem;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                return '';
            WHEN OTHERS THEN
                return '';
        END;
    EXCEPTION
        WHEN OTHERS THEN
            return '';
    END getNONPA_losstype;

    FUNCTION getNONPA_lossItem(vPrem  IN VARCHAR2 ,vProdtype IN VARCHAR2) RETURN VARCHAR2 IS
        v_rem VARCHAR2(100);
    BEGIN
        BEGIN
            select descr into v_rem
            from PREM_STD
            where prem_code = vPrem
            and prod_type =vProdtype and th_eng='E'       ;

            return v_rem;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                return '';
            WHEN OTHERS THEN
                return '';
        END;
    EXCEPTION
        WHEN OTHERS THEN
            return '';
    END getNONPA_lossItem;

    FUNCTION getNONPA_reserve_amt(vClmno  IN VARCHAR2 ,vType IN VARCHAR2) RETURN NUMBER   IS
        v_rem NUMBER;
    BEGIN
        BEGIN
            select res_amt into v_rem
            from nc_reserved a
            where clm_no = vClmno and a.trn_seq in (select max(aa.trn_seq) from nc_reserved aa where  aa.clm_no =a.clm_no )
            and type = vType ;

            return v_rem;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                return 0;
            WHEN OTHERS THEN
                return 0;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            return 0;
    END getNONPA_reserve_amt;

    FUNCTION getNONPA_InvoiceDtl(vPayno  IN VARCHAR2 ,vMode IN VARCHAR2/*1=get InvoiceNo 2=get Invoice Date*/) RETURN VARCHAR2 IS
        v_invno VARCHAR2(250);
        v_invdate  VARCHAR2(250);
    BEGIN
        BEGIN
            select invoice_no ,ref_no invoice_date
            into v_invno ,v_invdate
            from nc_payment_info a
            where pay_no = vPayno
            and (clm_no ,pay_no ,trn_seq) in (select aa.clm_no ,aa.pay_no ,max(aa.trn_seq) from nc_payment_info aa
            where aa.clm_no = a.clm_no and aa.pay_no =a.pay_no group by aa.clm_no ,aa.pay_no);

            if    vMode = '2' then
                return v_invdate;
            else
                return v_invno;
            end if;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                return '';
            WHEN OTHERS THEN
                return '';
        END;
    EXCEPTION
        WHEN OTHERS THEN
            return '';
    END getNONPA_InvoiceDtl;

  FUNCTION GET_CLAIMUSER(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* Claimant*/ IS
    v_user  varchar2(250);
  BEGIN
    IF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  in ( 'PA' ,'GM' ) THEN
        BEGIN
             --select P_claim_send_mail.get_bkiuser_name(a.clm_men) into v_insure
             select a.clm_men into v_user
             from mis_clm_mas a
             where clm_no in (select distinct aa.clm_no from mis_cri_paid aa where aa.pay_no = P_pay_no ) ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_user := null;
            WHEN OTHERS THEN
                v_user := null;
        END;

    ELSE
        BEGIN
--            select P_claim_send_mail.get_bkiuser_name(a.clm_user) into v_insure
            select a.clm_user into v_user
             from nc_mas a
             where clm_no in (select distinct aa.clm_no from nc_payment aa where aa.pay_no = P_pay_no ) ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_user := null;
            WHEN OTHERS THEN
                v_user := null;
        END;
    END IF;
    return v_user;
  END GET_CLAIMUSER;

  FUNCTION GET_STATEMENT_LINK(P_clm_no  IN VARCHAR2  ,P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* Claimant*/ IS
    v_link varchar2(200);
    v_url  varchar2(300);
    v_dbins varchar2(10);
    v_clmmen  varchar2(20);
  BEGIN
    IF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  in ( 'PA' ,'GM' ) THEN
        null;
    ELSE

         begin
             select UPPER(substr(instance_name,1,8)) instance_name
             into v_dbins
             from v$instance;

         exception
         when no_data_found then
         v_dbins := null;
         when others then
         v_dbins := null;
         end;
        v_clmmen := P_CLAIM_ACR.GET_CLAIMUSER(P_pay_no ,P_prod_type);

--        if v_dbins='UATBKIIN' then
--            v_link := 'http://bkinetdv/Non_pa_claim/Call_Crystal_Report.aspx?';
--            v_url := v_link||'user_id='||v_clmmen||'=CLNMC010_UAT'||'='||P_clm_no||'='||P_pay_no;
--        else
--            v_link := 'http://bkiintra.bki.co.th/Non_pa_claim/Call_Crystal_Report.aspx?';
--            v_url := v_link||'user_id='||v_clmmen||'=CLNMC010'||'='||P_clm_no||'='||P_pay_no;
--        end if;

        if v_dbins='UATBKIIN' then
            v_link := 'http://bkinetdv/Non_pa_claim/Call_Crystal_Report.aspx?'; 
            v_url := v_link||'user_id='||v_clmmen||chr(38)||'report_name=CLNMC010_UAT'||chr(38)||'IN_CLM_NO='||P_clm_no||chr(38)||'IN_PAY_NO='||P_pay_no;
        else 
            v_link := 'http://bkiintra.bki.co.th/Non_pa_claim/Call_Crystal_Report.aspx?'; 
            v_url := v_link||'user_id='||v_clmmen||chr(38)||'report_name=CLNMC010'||chr(38)||'IN_CLM_NO='||P_clm_no||chr(38)||'IN_PAY_NO='||P_pay_no;
        end if; 
     
    END IF;
    return v_url;
  END GET_STATEMENT_LINK;


  FUNCTION GET_PAIDUSER(P_pay_no IN varchar2 , /* Payment no  */
                                                     P_prod_type IN varchar2   /* Prod_type*/
                                                    ) RETURN VARCHAR2 /* PaidUser*/ IS
    v_user  varchar2(250);
  BEGIN
    IF NC_CLNMC908.GET_PRODUCTID2(P_prod_type)  in ( 'PA' ,'GM' ) THEN
        BEGIN
             --select P_claim_send_mail.get_bkiuser_name(a.clm_men) into v_insure
             select a.paid_staff into v_user
             from mis_clm_mas a
             where clm_no in (select distinct aa.clm_no from mis_cri_paid aa where aa.pay_no = P_pay_no ) ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_user := null;
            WHEN OTHERS THEN
                v_user := null;
        END;

    ELSE
        BEGIN
            select amd_user into v_user
            from nc_payment a
            where Pay_no = P_pay_no
            and trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.pay_no = a.pay_no )
            and rownum=1 ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_user := null;
            WHEN OTHERS THEN
                v_user := null;
        END;
    END IF;
    return v_user;
  END GET_PAIDUSER;

END P_CLAIM_ACR;
/

