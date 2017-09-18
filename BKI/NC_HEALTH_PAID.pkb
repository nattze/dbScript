CREATE OR REPLACE PACKAGE BODY NC_HEALTH_PAID IS
/******************************************************************************
 NAME: ALLCLM.NC_HEALTH_PAID
 PURPOSE: calculate Paid Data and send to ACR 

 REVISIONS:
 Ver Date Author Description
 --------- ---------- --------------- ------------------------------------
 1.0 22/08/2013 2702 1. Created this package.
******************************************************************************/
FUNCTION IS_TL_UP_STAFF(vUserId in varchar2) RETURN BOOLEAN IS

BEGIN
 FOR X IN (
 select name_t --,p_acc_lookup.get_position_grp_desc ( position_grp_id , 'T') POSITION_NAME 
 ,p_acc_lookup.GET_BKIUSER_POSGRP0(user_id) POSITION
 from bkiuser
 where user_id = vUserId
 ) LOOP
 IF X.POSITION <= 41 THEN
 return true;
 ELSE
 return false;
 END IF;
 END LOOP;
 return false;
EXCEPTION
 WHEN OTHERS THEN
 return false; 
END IS_TL_UP_STAFF;
 
PROCEDURE WRITE_LOG (V_MODULE in VARCHAR2 , V_USER in VARCHAR2 ,V_USER_NAME in VARCHAR2 ,V_FUNC IN VARCHAR2 ,V_LOG_TEXT in VARCHAR2 ,
 V_STATUS in VARCHAR2 ,V_RST OUT VARCHAR2) IS
BEGIN
/* Formatted on 05/01/2013 11:15:57 (QP5 v5.149.1003.31008) */
 V_RST := null;
 INSERT INTO NC_WS_LOG
 (SYS_ID,USER_ID,USER_NAME,FUNC,LOG_TEXT,STATUS,TIMESTAMP,
 SESSIONID,TERMINAL,SID)
 values
 (V_MODULE ,V_USER ,V_USER_NAME,V_FUNC ,V_LOG_TEXT,V_STATUS ,sysdate,
 '','','');
 
 COMMIT; 
EXCEPTION
 WHEN OTHERS THEN
 V_RST := 'error insert log: '||sqlerrm ;
END WRITE_LOG;

PROCEDURE WRITE_LOG_SWITCH (V_USESWITCH in Boolean ,V_MODULE in VARCHAR2 , V_USER in VARCHAR2 ,V_USER_NAME in VARCHAR2 ,V_FUNC IN VARCHAR2 ,V_LOG_TEXT in VARCHAR2 ,
 V_STATUS in VARCHAR2 ,V_RST OUT VARCHAR2) IS
 log_sw varchar2(10); 
BEGIN
/* Formatted on 05/01/2013 11:15:57 (QP5 v5.149.1003.31008) */
 V_RST := null;
 
 IF V_USESWITCH THEN -- check LOG Switch On - Off 
 begin 
 select remark into log_sw
 from clm_constant a
 where key like 'LOG_SWITCH' ;
 exception
 when no_data_found then
 log_sw := 'OFF';
 when others then
 log_sw := 'OFF';
 end;
 if log_sw = 'ON' then
 INSERT INTO NC_WS_LOG
 (SYS_ID,USER_ID,USER_NAME,FUNC,LOG_TEXT,STATUS,TIMESTAMP,
 SESSIONID,TERMINAL,SID)
 values
 (V_MODULE ,V_USER ,V_USER_NAME,V_FUNC ,V_LOG_TEXT,V_STATUS ,sysdate,
 '','',''); 
 COMMIT; 
 end if;
 ELSE
 INSERT INTO NC_WS_LOG
 (SYS_ID,USER_ID,USER_NAME,FUNC,LOG_TEXT,STATUS,TIMESTAMP,
 SESSIONID,TERMINAL,SID)
 values
 (V_MODULE ,V_USER ,V_USER_NAME,V_FUNC ,V_LOG_TEXT,V_STATUS ,sysdate,
 '','',''); 
 COMMIT; 
 END IF;
 
 
EXCEPTION
 WHEN OTHERS THEN
 V_RST := 'error insert log: '||sqlerrm ;
END WRITE_LOG_SWITCH;
 
PROCEDURE GEN_CURSOR(qry_str IN LONG ,P_CUR OUT v_ref_cursor1) IS
 --TYPE cur_typ IS REF CURSOR;
 --c cur_typ;
BEGIN
 
 OPEN P_CUR FOR qry_str ;
 --RETURN;

END;

FUNCTION VALIDATE_INDV(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS
 CURSOR c_clm IS select clm_no ,prod_type,clm_sts from mis_clm_mas
 where clm_no = vClmNo; 
 c_rec c_clm%ROWTYPE; 
 
 v_chk Boolean:=false; 
 dum_Gm0 varchar2(20); 
BEGIN
 
 OPEN c_clm;
 LOOP 
 FETCH c_clm INTO c_rec;
 EXIT WHEN c_clm%NOTFOUND;
 
 if c_rec.clm_sts in ('2','3') then 
 P_RST := c_rec.clm_no||': เคลมนี้ปิดเคลมหรือพิมพ์ STATEMENT ไปแล้ว! CLM_STS='||c_rec.clm_sts ;
 return false; 
 elsif c_rec.clm_sts not in ('6','7') then
 P_RST := c_rec.clm_no||': เคลมยังไม่ทำจ่าย! CLM_STS='||c_rec.clm_sts ;
 return false; 
 end if;

 -- if IS_FOUND_BATCH(c_rec.clm_no ,vPayNo ,P_RST ) then -- Case Batch Print
 -- 
 -- return false;
 -- end if; 
 
 END LOOP; 
 CLOSE c_clm; 
 
 if nc_clnmc908.get_productid(vClmNo) ='PA' then
 begin
 select clm_no into dum_Gm0
 from mis_clm_payee a 
 where pay_no = vPayNo
 and nvl(corr_seq ,0) in (select max(nvl(aa.corr_seq,0)) from mis_clm_payee aa where aa.pay_no = a.pay_no)
 and nvl(payee_amt,0) <=0 ;
 P_RST := vClmNo||': เคลมมียอด Payee Amt = 0 กรุณาตรวจสอบก่อนอนุมัติ '||'' ; 
 dbms_output.put_line(P_RST);
 return false; 
 exception
 when no_data_found then
 null ;
 when others then
 null;
 end; 
 elsif nc_clnmc908.get_productid(vClmNo) = 'GM' then
 begin
 select clm_no into dum_Gm0
 from clm_gm_payee
 where pay_no = vPayNo
 and nvl(payee_amt,0) <= 0 ;
 P_RST := vClmNo||': เคลมมียอด Payee Amt = 0 กรุณาตรวจสอบก่อนอนุมัติ '||'' ; 
 dbms_output.put_line(P_RST);
 return false; 
 exception
 when no_data_found then
 null ;
 when others then
 null;
 end; 
 end if; 
 
 v_chk:= true;
 return v_chk;
END VALIDATE_INDV;

FUNCTION IS_FOUND_BATCH(vClmno in varchar2 ,vPayno in varchar2 ,P_RST out varchar2) RETURN BOOLEAN IS
 v_batchno varchar2(10);
 isBatch boolean:= false;
BEGIN 
 BEGIN
 IF NC_CLNMC908.GET_PRODUCTID(vClmno) = 'PA' THEN
 Select a.batch_no into v_batchno
 from CLM_BATCH_TMP a where a.clm_no = vClmno and a.prod_type ='001'
 and pay_no = vPayno and batch_no is not null 
 group by a.batch_no;
 ELSIF NC_CLNMC908.GET_PRODUCTID(vClmno) = 'GM' THEN
 Select a.batch_no into v_batchno
 from CLMGM_BATCH_TMP a where a.clm_no = vClmno 
 and pay_no = vPayno and batch_no is not null 
 group by a.batch_no; 
 END IF;
 --if v_batchno is not null then
 isBatch := true; 
 P_RST := 'พบงานนี้อยู่ในขั้นตอนพิมพ์ BATCH';
 --end if;
 EXCEPTION 
 WHEN NO_DATA_FOUND THEN
 isBatch := false; 
 WHEN OTHERS THEN
 isBatch := false; 
 END;
 return isBatch;
END;

FUNCTION RUN_INDV(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS
 CURSOR c_clm IS select clm_no ,pol_no ,pol_run ,nvl(policy_number,pol_no||pol_run) policy_number ,prod_grp ,prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,channel ,clm_men
 from mis_clm_mas
 where clm_no = vClmNo
 ; 
 c_rec c_clm%ROWTYPE; 
 
 
 v_chk Boolean:=false; 
 V_STATUS_RST varchar2(200);
 V_POSTGL_STS varchar2(200);
 m_rst varchar2(200);
 inw_type varchar2(1); 
 b1 varchar2(10);
 b2 varchar2(10); 
 V_DEPT_ID VARCHAR (2) ;
 V_DIV_ID VARCHAR (2) ;
 V_TEAM_ID VARCHAR (2); 
 V_RESULT VARCHAR2(100); 
 V_RESULT2 VARCHAR2(100); 
 V_RESULT3 VARCHAR2(100); 
 V_TITLE VARCHAR (30) ;
 V_NAME VARCHAR (120) ; 
 V_CONTACT VARCHAR (120) ; 
 V_VOUNO varchar2(15);
 V_VOUDATE DATE;
 V_REPRINT_NO number(2);
 v_DEDUCT_AMT NUMBER ; 
 v_RES_AMT number;
 v_ADV_AMT number;
 V_GM_PAY number;
 V_REC_TOTAL number; 
 cnt number;
 M_SEND_TITLE varchar2(100); 
 M_SEND_ADDR1 varchar2(200); 
 M_SEND_ADDR2 varchar2(200); 
 M_PAYEE_CODE varchar2(20); 
 M_PAYEE_NAME varchar2(200); 
 M_PAY_NO varchar2(20); 
 
 M_SPECIAL_FLAG VARCHAR2(1);
 M_AGENT_MAIL VARCHAR2(150);
 M_AGENT_MAIL_FLAG VARCHAR2(1);
 M_AGENT_MOBILE_NUMBER VARCHAR2(50);
 M_AGENT_SMS_FLAG VARCHAR2(1 );
 M_CUST_MAIL VARCHAR2(150 );
 M_CUST_MAIL_FLAG VARCHAR2(1 );
 M_MOBILE_NUMBER VARCHAR2(50);
 M_SMS_FLAG VARCHAR2(1 );
 
 M_URGENT_FLAG VARCHAR2(1 );
 
 vclm_sent_payee_seq number;
-- p_chkv boolean;
BEGIN
 if NOT validate_indv(vClmNo , vPayNo ,P_RST) then
 return false;
 end if;
 
 b1 := GET_BATCHNO('B');
 
 --======= Step Insert Data ========
 for c_rec in (
 select a.clm_no ,a.pol_no ,a.pol_run ,nvl(a.policy_number,a.pol_no||a.pol_run) policy_number ,a.prod_grp ,a.prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,a.channel ,clm_men
 ,nvl(a.clm_curr_code,'BHT') clm_curr_code
 from mis_clm_mas a ,mis_clm_mas_seq d
 where a.clm_no = d.clm_no 
 and a.clm_no = vClmNo
 and d.corr_seq = (select max(x.corr_seq) from mis_clm_mas_seq x where x.clm_no = d.clm_no) 
 and a.clm_sts in ('6','7') and d.close_date is null 
 )
 loop 
 /* script 3 */
 if c_rec.channel = '9' then inw_type := 'Y'; else inw_type := null; end if; 
 begin
 select dept_id ,div_id ,team_id into V_DEPT_ID, V_DIV_ID, V_TEAM_ID
 from bkiuser
 where user_id = c_rec.clm_men; 
 exception
 when no_data_found then
 V_DEPT_ID:=null;
 V_DIV_ID :=null;
 V_TEAM_ID :=null;
 when others then
 V_DEPT_ID:=null;
 V_DIV_ID :=null;
 V_TEAM_ID :=null;
 end;
 
 for p1 in (select a.pay_no ,pay_seq ,pay_date ,payee_amt ,pay_total ,0 rec_total ,0 disc_total ,replace(payee_code,' ','') payee_code 
 from mis_clm_paid a, mis_clm_payee b
 where a.clm_no = b.clm_no
 and a.pay_no = b.pay_no
 and a.pay_no = vPayno
 and a.clm_no = c_rec.clm_no
 and pay_seq = (select max(e.pay_seq) from mis_clm_payee e where e.pay_no = b.pay_no )
 and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
 where b.pay_no = a.pay_no
 group by b.pay_no) 
 ) 
 loop 
 
 P_CLAIM_ACR.Post_acc_clm_tmp( c_rec.prod_grp /*P_prod_grp IN acc_clm_tmp.prod_grp%type*/,

 c_rec.prod_type /* P_prod_type IN acc_clm_tmp.prod_type%type */,

 p1.pay_no /* P_payno IN acc_clm_tmp.payment_no%type */,

 trunc(sysdate) /* P_appoint_date IN acc_clm_tmp.appoint_date%type */,

 c_rec.clm_no /* P_clmno IN acc_clm_tmp.clm_no%type */,

 c_rec.pol_no /* P_polno IN acc_clm_tmp.pol_no%type */,

 c_rec.pol_run /* P_polrun IN acc_clm_tmp.pol_run%type */,

 c_rec.policy_number /* P_polnum IN acc_clm_tmp.policy_number%type */,

 c_rec.pol_no||c_rec.pol_run /* P_polref IN acc_clm_tmp.pol_ref%type */, 

 c_rec.cus_code /* P_cuscode IN acc_clm_tmp.cus_code%type */,

 c_rec.th_eng /* P_th_eng IN acc_clm_tmp.th_eng%type */,

 c_rec.agent_code /* P_agent_code IN acc_clm_tmp.agent_code%type */,

 c_rec.agent_seq /* P_agent_seq IN acc_clm_tmp.agent_seq%type */,

 c_rec.clm_men /* P_Postby IN acc_clm_tmp.post_by%type */, 

 c_rec.br_code /* P_brn_code IN acc_clm_tmp.brn_code%type */,

 inw_type /* P_inw_type IN acc_clm_tmp.inw_type%type */,

 null /* P_batch_no IN acc_clm_tmp.batch_no%type */, 

 v_dept_id /* P_dept_id IN acc_clm_tmp.dept_id%type */,

 v_div_id /* P_div_id IN acc_clm_tmp.div_id%type */,

 v_team_id /* P_team_id IN acc_clm_tmp.team_id%type */,

 v_result /* P_msg Out varchar2*/); 
 
 if v_result is not null then rollback; P_RST:= v_result||' in P_CLAIM_ACR.Post_acc_clm_tmp'; return false; end if;
 
 for p5 in (select tot_res res_amt
 from mis_clm_mas a
 where a.clm_no = c_rec.clm_no) 
 loop
 v_RES_AMT := p5.res_amt; 
 end loop; 
 --v_ADV_AMT := v_RES_AMT - p1.pay_total;
 --v_ADV_AMT := p1.payee_amt - ( p1.pay_total-nvl(p1.rec_total,0) );

 for p3 in (select payee_code ,pay_seq ,payee_amt pay_amt,0 deduct_amt ,0 rec_amt 
 ,bank_code ,bank_br_code ,acc_no ,acc_name ,settle
 ,b.special_flag ,special_remark
 ,b.agent_mail_flag ,decode(b.agent_mail_flag,'Y',b.agent_mail,'') agent_mail,b.agent_sms_flag ,decode(b.agent_sms_flag,'Y',b.agent_mobile_number ,'') agent_mobile_number
 ,b.cust_mail_flag ,decode(b.cust_mail_flag ,'Y' ,b.cust_mail ,'') cust_mail ,b.sms_flag ,decode(b.sms_flag ,'Y' ,b.mobile_number ,'') mobile_number 
 from mis_clm_payee b
 where b.clm_no = c_rec.clm_no
 ) 
 loop
 v_DEDUCT_AMT := p3.deduct_amt; 
 V_REC_TOTAL := p3.rec_amt;
 V_GM_PAY := p3.pay_amt; 
 
 begin
 select b.title ,b.name ,b.contact_name into V_TITLE ,V_NAME ,V_CONTACT
 from acc_payee b
 where b.cancel is null
 and b.payee_code = replace(p3.payee_code,' ','');
 exception
 when no_data_found then
 V_TITLE:=null;
 V_NAME :=null;
 V_CONTACT := null;
 when others then
 V_TITLE:=null;
 V_NAME :=null;
 V_CONTACT := null;
 end; 
 
 --v_ADV_AMT := p1.payee_amt - ( p1.pay_total-nvl(p1.rec_total,0) ) - nvl(v_DEDUCT_AMT,0);
 --v_ADV_AMT := p1.payee_amt - ( V_GM_PAY - nvl(V_REC_TOTAL,0) ) - nvl(v_DEDUCT_AMT,0);
 v_ADV_AMT := 0;
 
 P_CLAIM_ACR.Post_acc_clm_payee_pagm( c_rec.prod_grp /* P_prod_grp IN acc_clm_payee_tmp.prod_grp%type */, 
 
 c_rec.prod_type /* P_prod_type IN acc_clm_payee_tmp.prod_type%type */,
 
 p1.pay_no /* P_payno IN acc_clm_payee_tmp.payment_no%type */,
 
 p3.pay_seq /* P_seq IN acc_clm_payee_tmp.seq%type */,
 
 '01' /* P_doc_type IN acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
 
 c_rec.clm_curr_code /* P_curr_code IN acc_clm_payee_tmp.curr_code%type */,
 
 p3.pay_amt /* P_payee_amt IN acc_clm_payee_tmp.payee_amt%type */,
 
 p3.payee_code /* P_payee_code IN acc_clm_payee_tmp.payee_code%type */,
 
 v_title /* P_title IN acc_clm_payee_tmp.title%type */,
 
 v_name /* P_name IN acc_clm_payee_tmp.name%type */, 
 
 '08' /* P_dept_no IN acc_clm_payee_tmp.dept_no%type */,
 
 null /* P_batch_no IN acc_clm_payee_tmp.batch_no%type */,
 
 nvl(v_DEDUCT_AMT,0) * -1 /* P_deduct_amt IN acc_clm_payee_tmp.deduct_amt%type */,
 
 v_ADV_AMT /* P_adv_amt IN acc_clm_payee_tmp.adv_amt%type */,
 
 p3.bank_code /* p_bank_code in acc_clm_payee_tmp.bank_code%type */ ,
 
 p3.bank_br_code /* p_branch_code in acc_clm_payee_tmp.branch_code%type */ ,
 
 p3.acc_no /* p_acc_no in acc_clm_payee_tmp.acc_no%type*/,
 
 p3.acc_name /* p_acc_name_th in acc_clm_payee_tmp.acc_name_th%type*/,
 
 null /* p_acc_name_eng in acc_clm_payee_tmp.acc_name_eng%type*/,
 
 null /* p_deposit_type in acc_clm_payee_tmp.deposit_type%type*/,
 
 p3.settle /* p_paid_type in acc_clm_payee_tmp.paid_type%type*/,
 
 p3.special_flag /* p_special_flag in acc_clm_payee_tmp.special_flag%type*/,
 
 p3.special_remark /* p_special_remark in acc_clm_payee_tmp.special_remark%type*/,
 
 p3.agent_mail /* p_agent_mail in acc_clm_payee_tmp.agent_mail%type*/,
 
 p3.agent_mail_flag /* p_agent_mail_flag in acc_clm_payee_tmp.agent_mail_flag%type*/,
 
 p3.agent_mobile_number /* p_agent_mobile_number in acc_clm_payee_tmp.agent_mobile_number%type*/,
 
 p3.agent_sms_flag /* p_agent_sms_flag in acc_clm_payee_tmp.agent_sms_flag%type*/,
 
 p3.cust_mail /* p_cust_mail in acc_clm_payee_tmp.cust_mail%type*/,
 
 p3.cust_mail_flag /* p_cust_mail_flag in acc_clm_payee_tmp.cust_mail_flag%type*/,
 
 p3.mobile_number /* p_mobile_number in acc_clm_payee_tmp.mobile_number%type*/, 
 
 p3.sms_flag /* p_sms_flag in acc_clm_payee_tmp.sms_flag%type*/, 
 
 V_RESULT2 /* P_msg Out varchar2*/ ) ; 
 
 if v_result2 is not null then rollback; P_RST:= v_result2||' in P_CLAIM_ACR.Post_acc_clm_payee_tmp'; return false; end if;
 
 end loop; -- end loop payee
 COMMIT; -- post ACC_CLM_TEMP b4 call post GL

 p_acc_claim.post_gl ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,
 
 c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,
 
 p1.pay_no /* p_number in varchar2 */, -- payment no or batch no
 
 'P' /* p_flag in varchar2 */, -- 'P' = Payment, 'B' = Batch
 
 V_RESULT3 /* p_err out varchar2 */); -- return null if no error


 if v_result3 is not null then /* CLR_ACC_TMP; */ P_RST:= v_result3||' in p_acc_claim.post_gl'; return false; end if; 
 
 p_acc_claim.get_acr_voucher ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,

 c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,

 p1.pay_no /* p_number in varchar2 */, -- payment no or batch no

 'P' /* p_flag in varchar2 */, -- 'P' = Payment, 'B' = Batch

 V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,

 V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);

 IF V_VOUNO is null THEN
 P_RST:= ' p_acc_claim.post_gl have any Problem '; return false;
 END IF;
 
 begin
 Update mis_clm_paid a 
 set a.print_type = '1' ,
 a.pay_date = V_VOUDATE ,a.state_flag='1' ,
 a.corr_date = V_VOUDATE ,
 a.batch_no = b1
 where a.clm_no = c_rec.clm_no
 and a.pay_no = vPayNo 
 and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
 where b.pay_no = a.pay_no
 group by b.pay_no); 
 
 update mis_clm_mas
 set clm_sts = '2',
 close_date = trunc(sysdate)
 where clm_no = c_rec.clm_no;
 
 update mis_clm_mas_seq a
 set clm_sts = '2',
 close_date = trunc(sysdate)
 where (a.clm_no = c_rec.clm_no) and
 (a.clm_no,corr_seq) in (select b.clm_no,max(corr_seq) from mis_clm_mas_seq b
 where a.clm_no = b.clm_no
 group by b.clm_no); 
 exception
 when others then
 rollback; P_RST := 'error update claim: '||sqlerrm ; return false;
 end; 
 
 -- ++++ get Send Address ++++
 BEGIN
 select a.send_title ,a.send_addr1 ,a.send_addr2 ,b.payee_code ,b.payee_name
 ,b.special_flag 
 ,b.agent_mail_flag ,decode(b.agent_mail_flag,'Y',b.agent_mail,'') agent_mail,b.agent_sms_flag ,decode(b.agent_sms_flag,'Y',b.agent_mobile_number ,'') agent_mobile_number
 ,b.cust_mail_flag ,decode(b.cust_mail_flag ,'Y' ,b.cust_mail ,'') cust_mail ,b.sms_flag ,decode(b.sms_flag ,'Y' ,b.mobile_number ,'') mobile_number 
 ,b.urgent_flag 
 into M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_CODE ,M_PAYEE_NAME 
 ,M_SPECIAL_FLAG 
 ,M_AGENT_MAIL_FLAG ,M_AGENT_MAIL ,M_AGENT_SMS_FLAG ,M_AGENT_MOBILE_NUMBER
 ,M_CUST_MAIL_FLAG ,M_CUST_MAIL ,M_SMS_FLAG ,M_MOBILE_NUMBER 
 ,M_URGENT_FLAG 
 from mis_clm_paid a ,mis_clm_payee b
 where a.pay_no = b.pay_no 
 and a.pay_no = vPayNo
 and (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
 where b.pay_no = a.pay_no
 group by b.pay_no) and rownum=1 ; 
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 null;
 WHEN OTHERS THEN
 null;
 END; 
 -- +++ + ++ + + + + + + + + + 
 
 begin 
 Insert into clm_sent_payee
 (KEY_NO ,SENT_TYPE ,PAYEE_CODE ,CONTACT_NAME ,ADDR1 ,ADDR2 ,PAYEE_NAME ,SEQ ,TRN_DATE)
 Values 
 (vPayNo ,'P' ,M_PAYEE_CODE ,M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_NAME ,vclm_sent_payee_seq ,sysdate); 
 
 exception
 when others then
 rollback; P_RST := 'error update claim: '||sqlerrm ; return false;
 end; 
 
 end loop; 
 end loop;
 --// End Run Individual ========
 COMMIT;
 
 V_STATUS_RST := UPDATE_STATUS(vPayNo , vClmUser);
 
 IF V_STATUS_RST is not null THEN 
 NC_HEALTH_PACKAGE.WRITE_LOG ( 'PACKAGE' ,'ALLCLM.NC_HEALTH_PAID' ,'UPDATE_STATUS' ,V_STATUS_RST,
 m_rst) ; 
 END IF;
 
 return true;
EXCEPTION
 WHEN OTHERS THEN
 rollback; P_RST := 'error update claim: '||sqlerrm ; return false; 
END RUN_INDV;

FUNCTION RUN_INDV_GM(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS
 CURSOR c_clm IS select clm_no ,pol_no ,pol_run ,nvl(policy_number,pol_no||pol_run) policy_number ,prod_grp ,prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,channel ,clm_men
 from mis_clm_mas
 where clm_no = vClmNo
 ; 
 c_rec c_clm%ROWTYPE; 
 
 v_chk Boolean:=false; 
 V_STATUS_RST varchar2(200);
 m_rst varchar2(200);
 inw_type varchar2(1); 
 b1 varchar2(10);
 b2 varchar2(10); 
 V_DEPT_ID VARCHAR (2) ;
 V_DIV_ID VARCHAR (2) ;
 V_TEAM_ID VARCHAR (2); 
 V_RESULT VARCHAR2(100); 
 V_RESULT2 VARCHAR2(100); 
 V_RESULT3 VARCHAR2(100); 
 V_RESULT_x VARCHAR2(100); 
 V_TITLE VARCHAR (30) ;
 V_NAME VARCHAR (120) ; 
 V_CONTACT VARCHAR (120) ; 
 V_VOUNO varchar2(15);
 V_VOUDATE DATE;
 V_REPRINT_NO number(2);
 v_DEDUCT_AMT NUMBER ; 
 v_RES_AMT number;
 v_ADV_AMT number;
 V_GM_PAY number;
 V_REC_TOTAL number; 
 cnt number;
 M_SEND_TITLE varchar2(100); 
 M_SEND_ADDR1 varchar2(200); 
 M_SEND_ADDR2 varchar2(200); 
 M_PAYEE_CODE varchar2(20); 
 M_PAYEE_NAME varchar2(200); 
 M_PAY_NO varchar2(20); 
 
 vclm_sent_payee_seq number;
-- p_chkv boolean;
BEGIN
 if NOT validate_indv(vClmNo , vPayNo ,P_RST) then
 return false;
 end if;
 
 b1 := GET_BATCHNO('GB');
 
 --======= Step Insert Data ========
 for c_rec in (select clm_no ,pol_no ,pol_run ,nvl(policy_number,pol_no||pol_run) policy_number ,prod_grp ,prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,channel ,clm_men
 from mis_clm_mas
 where clm_no = vClmNo and clm_sts = '6' and close_date is null) 
 loop 
 /* script 3 */
 if c_rec.channel = '9' then inw_type := 'Y'; else inw_type := null; end if; 
 begin
 select dept_id ,div_id ,team_id into V_DEPT_ID, V_DIV_ID, V_TEAM_ID
 from bkiuser
 where user_id = c_rec.clm_men; 
 exception
 when no_data_found then
 V_DEPT_ID:=null;
 V_DIV_ID :=null;
 V_TEAM_ID :=null;
 when others then
 V_DEPT_ID:=null;
 V_DIV_ID :=null;
 V_TEAM_ID :=null;
 end;
 
 for p1 in (select a.pay_no ,pay_seq ,pay_date ,payee_amt ,pay_total ,rec_total ,disc_total ,replace(payee_code,' ','') payee_code 
 ,b.bank_code ,b.bank_br_code ,b.acc_no ,b.acc_name ,b.settle
 ,b.special_flag ,b.special_remark
 ,b.agent_mail_flag ,decode(b.agent_mail_flag,'Y',b.agent_mail,'') agent_mail,b.agent_sms_flag ,decode(b.agent_sms_flag,'Y',b.agent_mobile_number ,'') agent_mobile_number
 ,b.cust_mail_flag ,decode(b.cust_mail_flag ,'Y' ,b.cust_mail ,'') cust_mail ,b.sms_flag ,decode(b.sms_flag ,'Y' ,b.mobile_number ,'') mobile_number 
 from mis_clmgm_paid a, clm_gm_payee b
 where a.clm_no = b.clm_no
 and a.pay_no = b.pay_no
 and a.clm_no = c_rec.clm_no
 and pay_seq = (select max(e.pay_seq) from clm_gm_payee e where e.pay_no = b.pay_no )
 and (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from mis_clmgm_paid b
 where b.clm_no = a.clm_no
 group by b.clm_no) 
 ) 
 loop 
 P_CLAIM_ACR.Post_acc_clm_tmp( c_rec.prod_grp /*P_prod_grp IN acc_clm_tmp.prod_grp%type*/,

 c_rec.prod_type /* P_prod_type IN acc_clm_tmp.prod_type%type */,

 p1.pay_no /* P_payno IN acc_clm_tmp.payment_no%type */,

 trunc(sysdate) /* P_appoint_date IN acc_clm_tmp.appoint_date%type */,

 c_rec.clm_no /* P_clmno IN acc_clm_tmp.clm_no%type */,

 c_rec.pol_no /* P_polno IN acc_clm_tmp.pol_no%type */,

 c_rec.pol_run /* P_polrun IN acc_clm_tmp.pol_run%type */,

 c_rec.policy_number /* P_polnum IN acc_clm_tmp.policy_number%type */,

 c_rec.pol_no||c_rec.pol_run /* P_polref IN acc_clm_tmp.pol_ref%type */, 

 c_rec.cus_code /* P_cuscode IN acc_clm_tmp.cus_code%type */,

 c_rec.th_eng /* P_th_eng IN acc_clm_tmp.th_eng%type */,

 c_rec.agent_code /* P_agent_code IN acc_clm_tmp.agent_code%type */,

 c_rec.agent_seq /* P_agent_seq IN acc_clm_tmp.agent_seq%type */,

 c_rec.clm_men /* P_Postby IN acc_clm_tmp.post_by%type */, 

 c_rec.br_code /* P_brn_code IN acc_clm_tmp.brn_code%type */,

 inw_type /* P_inw_type IN acc_clm_tmp.inw_type%type */,

 null /* P_batch_no IN acc_clm_tmp.batch_no%type */, 

 v_dept_id /* P_dept_id IN acc_clm_tmp.dept_id%type */,

 v_div_id /* P_div_id IN acc_clm_tmp.div_id%type */,

 v_team_id /* P_team_id IN acc_clm_tmp.team_id%type */,

 v_result /* P_msg Out varchar2*/); 
 
 if v_result is not null then rollback; P_RST:= v_result||' in P_CLAIM_ACR.Post_acc_clm_tmp'; return false; end if;

 begin
 select b.title ,b.name ,b.contact_name into V_TITLE ,V_NAME ,V_CONTACT
 from acc_payee b
 where b.cancel is null
 and b.payee_code = replace(p1.payee_code,' ','');
 exception
 when no_data_found then
 V_TITLE:=null;
 V_NAME :=null;
 V_CONTACT := null;
 when others then
 V_TITLE:=null;
 V_NAME :=null;
 V_CONTACT := null;
 end; 
 
 for p5 in (select sum(res_amt) res_amt
 from clm_medical_res a 
 where a.clm_no = c_rec.clm_no
 and (a.state_no,a.state_seq) = (select b.state_no,max(b.state_seq) from clm_medical_res b
 where b.clm_no = a.clm_no and b.state_no = a.state_no
 group by b.state_no) ) 
 loop
 v_RES_AMT := p5.res_amt; 
 end loop; 

 for p3 in (select sum(pay_amt) pay_amt ,sum(rec_amt) rec_amt ,sum(deduct_amt) deduct_amt
 from clm_gm_paid a
 where a.clm_no = c_rec.clm_no
 and (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from clm_gm_paid b
 where b.clm_no = a.clm_no
 group by b.clm_no) ) 
 loop
 v_DEDUCT_AMT := p3.deduct_amt; 
 V_REC_TOTAL := p3.rec_amt;
 V_GM_PAY := p3.pay_amt; 
 end loop; 

 v_ADV_AMT := nvl(p1.payee_amt,0) - (nvl(V_GM_PAY,0) -nvl(V_REC_TOTAL,0)) - nvl(v_DEDUCT_AMT,0);
 
 P_CLAIM_ACR.Post_acc_clm_payee_pagm( c_rec.prod_grp /* P_prod_grp IN acc_clm_payee_tmp.prod_grp%type */, 

 c_rec.prod_type /* P_prod_type IN acc_clm_payee_tmp.prod_type%type */,
 
 p1.pay_no /* P_payno IN acc_clm_payee_tmp.payment_no%type */,
 
 p1.pay_seq /* P_seq IN acc_clm_payee_tmp.seq%type */,
 
 '01' /* P_doc_type IN acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
 
 'BHT' /* P_curr_code IN acc_clm_payee_tmp.curr_code%type */,
 
 p1.payee_amt /* P_payee_amt IN acc_clm_payee_tmp.payee_amt%type */,
 
 p1.payee_code /* P_payee_code IN acc_clm_payee_tmp.payee_code%type */,
 
 v_title /* P_title IN acc_clm_payee_tmp.title%type */,
 
 v_name /* P_name IN acc_clm_payee_tmp.name%type */, 
 
 '08' /* P_dept_no IN acc_clm_payee_tmp.dept_no%type */,
 
 null /* P_batch_no IN acc_clm_payee_tmp.batch_no%type */,
 
 nvl(v_DEDUCT_AMT,0) * -1 /* P_deduct_amt IN acc_clm_payee_tmp.deduct_amt%type */,
 
 v_ADV_AMT /* P_adv_amt IN acc_clm_payee_tmp.adv_amt%type */,
 
 p1.bank_code /* p_bank_code in acc_clm_payee_tmp.bank_code%type */ ,
 
 p1.bank_br_code /* p_branch_code in acc_clm_payee_tmp.branch_code%type */ ,
 
 p1.acc_no /* p_acc_no in acc_clm_payee_tmp.acc_no%type*/,
 
 p1.acc_name /* p_acc_name_th in acc_clm_payee_tmp.acc_name_th%type*/,
 
 null /* p_acc_name_eng in acc_clm_payee_tmp.acc_name_eng%type*/,
 
 null /* p_deposit_type in acc_clm_payee_tmp.deposit_type%type*/,
 
 p1.settle /* p_paid_type in acc_clm_payee_tmp.paid_type%type*/,
 
 p1.special_flag /* p_special_flag in acc_clm_payee_tmp.special_flag%type*/,
 
 p1.special_remark /* p_special_remark in acc_clm_payee_tmp.special_remark%type*/,
 
 p1.agent_mail /* p_agent_mail in acc_clm_payee_tmp.agent_mail%type*/,
 
 p1.agent_mail_flag /* p_agent_mail_flag in acc_clm_payee_tmp.agent_mail_flag%type*/,
 
 p1.agent_mobile_number /* p_agent_mobile_number in acc_clm_payee_tmp.agent_mobile_number%type*/,
 
 p1.agent_sms_flag /* p_agent_sms_flag in acc_clm_payee_tmp.agent_sms_flag%type*/,
 
 p1.cust_mail /* p_cust_mail in acc_clm_payee_tmp.cust_mail%type*/,
 
 p1.cust_mail_flag /* p_cust_mail_flag in acc_clm_payee_tmp.cust_mail_flag%type*/,
 
 p1.mobile_number /* p_mobile_number in acc_clm_payee_tmp.mobile_number%type*/, 
 
 p1.sms_flag /* p_sms_flag in acc_clm_payee_tmp.sms_flag%type*/, 
 
 V_RESULT2 /* P_msg Out varchar2*/ ) ; 
 
 if v_result2 is not null then rollback; P_RST:= v_result2||' in P_CLAIM_ACR.Post_acc_clm_payee_tmp'; return false; end if;

 -- ++++ get Send Address ++++
 BEGIN
 select a.send_title ,a.send_addr1 ,a.send_addr2 ,replace(a.payee_code,' ','') ,a.payee_name
 into M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_CODE ,M_PAYEE_NAME 
 from clm_gm_payee a
 where a.pay_no = vPayNo and replace(a.payee_code,' ','') = p1.payee_code ; 
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 null;
 WHEN OTHERS THEN
 null;
 END; 
 -- +++ + ++ + + + + + + + + + 
 
 begin 
 Insert into clm_sent_payee
 (KEY_NO ,SENT_TYPE ,PAYEE_CODE ,CONTACT_NAME ,ADDR1 ,ADDR2 ,PAYEE_NAME ,SEQ ,TRN_DATE)
 Values 
 (vPayNo ,'P' ,M_PAYEE_CODE ,M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_NAME ,vclm_sent_payee_seq ,sysdate); 
 
 exception
 when others then
 rollback; P_RST := 'error update claim: '||sqlerrm ; return false;
 end; 
 
 COMMIT; -- post ACC_CLM_TEMP b4 call post GL

 --*** Insert CLM_GM_RECOV
 IF nvl(v_ADV_AMT,0) > 0 THEN
 NMTR_PACKAGE.SET_CLM_GM_RECOV(c_rec.clm_no ,p1.pay_no ,v_ADV_AMT 
 ,V_RESULT_x );
 END IF;
 
 end loop; -- end Payee Loop
 
 p_acc_claim.post_gl ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,
 
 c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,
 
 vPayNo /* p_number in varchar2 */, -- payment no or batch no
 
 'P' /* p_flag in varchar2 */, -- 'P' = Payment, 'B' = Batch
 
 V_RESULT3 /* p_err out varchar2 */); -- return null if no error

 if v_result3 is not null then /* CLR_ACC_TMP; */ P_RST:= v_result3||' in p_acc_claim.post_gl'; return false; end if; 
 
 p_acc_claim.get_acr_voucher ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,

 c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,

 vPayNo /* p_number in varchar2 */, -- payment no or batch no

 'P' /* p_flag in varchar2 */, -- 'P' = Payment, 'B' = Batch

 V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,

 V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);
 
 IF V_VOUNO is null THEN
 P_RST:= ' p_acc_claim.post_gl have any Problem '; return false;
 END IF;
 
 begin
 Update mis_clmgm_paid a 
 set a.print_type = '1' ,
 a.pay_date = V_VOUDATE ,
 a.batch_no = b1
 where a.clm_no = c_rec.clm_no
 and (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from mis_clmgm_paid b
 where b.clm_no = a.clm_no
 group by b.clm_no); 
 
 update clm_gm_paid a 
 set a.date_paid = V_VOUDATE
 where a.clm_no = c_rec.clm_no
 and (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from clm_gm_paid b
 where b.clm_no = a.clm_no
 group by b.clm_no);

 update clm_medical_res a 
 set a.close_date = V_VOUDATE
 where a.clm_no = c_rec.clm_no
 and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq) from clm_medical_res b
 where b.clm_no = a.clm_no
 group by b.clm_no,b.state_no);
 
 update mis_clm_mas
 set clm_sts = '2',
 close_date = trunc(sysdate)
 ,out_open_sts = 'Y'
 ,out_paid_sts = 'Y'
 ,out_print_sts ='Y'
 where clm_no = c_rec.clm_no;
 
 update mis_clm_mas_seq a
 set clm_sts = '2',
 close_date = trunc(sysdate)
 where (a.clm_no = c_rec.clm_no) and
 (a.clm_no,corr_seq) in (select b.clm_no,max(corr_seq) from mis_clm_mas_seq b
 where a.clm_no = b.clm_no
 group by b.clm_no); 
 exception
 when others then
 rollback; P_RST := 'error update claim: '||sqlerrm ; return false;
 end; 
 end loop;
 --// End Run Individual ========
 COMMIT;
 
 V_STATUS_RST := UPDATE_STATUS(vPayNo , vClmUser);
 
 IF V_STATUS_RST is not null THEN 
 NC_HEALTH_PACKAGE.WRITE_LOG ( 'PACKAGE' ,'ALLCLM.NC_HEALTH_PAID' ,'UPDATE_STATUS' ,V_STATUS_RST,
 m_rst) ; 
 END IF;
 
 return true;
EXCEPTION
 WHEN OTHERS THEN
 rollback; P_RST := 'error update claim: '||sqlerrm ; return false; 
END RUN_INDV_GM;

FUNCTION POST_ACR_PA(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS
 CURSOR c_clm IS select clm_no ,pol_no ,pol_run ,nvl(policy_number,pol_no||pol_run) policy_number ,prod_grp ,prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,channel ,clm_men
 from mis_clm_mas
 where clm_no = vClmNo
 ; 
 c_rec c_clm%ROWTYPE; 
 
 v_chk Boolean:=false; 
 V_STATUS_RST varchar2(200);
 V_POSTGL_STS varchar2(200);
 m_rst varchar2(200);
 inw_type varchar2(1); 
 b1 varchar2(10);
 b2 varchar2(10); 
 V_DEPT_ID VARCHAR (2) ;
 V_DIV_ID VARCHAR (2) ;
 V_TEAM_ID VARCHAR (2); 
 V_RESULT VARCHAR2(100); 
 V_RESULT2 VARCHAR2(100); 
 V_RESULT3 VARCHAR2(100); 
 V_TITLE VARCHAR (30) ;
 V_NAME VARCHAR (200) ; 
 V_CONTACT VARCHAR (300) ; 
 V_VOUNO varchar2(15);
 V_VOUDATE DATE;
 V_REPRINT_NO number(2);
 v_DEDUCT_AMT NUMBER ; 
 v_RES_AMT number;
 v_ADV_AMT number;
 V_GM_PAY number;
 V_REC_TOTAL number; 
 cnt number;
 M_SEND_TITLE varchar2(100); 
 M_SEND_ADDR1 varchar2(200); 
 M_SEND_ADDR2 varchar2(200); 
 M_PAYEE_CODE varchar2(20); 
 M_PAYEE_NAME varchar2(200); 
 M_PAY_NO varchar2(20); 
 
 M_SPECIAL_FLAG VARCHAR2(1);
 M_AGENT_MAIL VARCHAR2(150);
 M_AGENT_MAIL_FLAG VARCHAR2(1);
 M_AGENT_MOBILE_NUMBER VARCHAR2(50);
 M_AGENT_SMS_FLAG VARCHAR2(1 );
 M_CUST_MAIL VARCHAR2(150 );
 M_CUST_MAIL_FLAG VARCHAR2(1 );
 M_MOBILE_NUMBER VARCHAR2(50);
 M_SMS_FLAG VARCHAR2(1 );
 
 M_URGENT_FLAG VARCHAR2(1 );
 
 vclm_sent_payee_seq number;
-- p_chkv boolean;
BEGIN
 if NOT validate_indv(vClmNo , vPayNo ,P_RST) then
 return false;
 end if;

 BEGIN
 select nvl(max(seq),0) +1 
 into vclm_sent_payee_seq
 from clm_sent_payee
 where key_no = vPayNo; 
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 vclm_sent_payee_seq := 1;
 WHEN OTHERS THEN
 vclm_sent_payee_seq := 1;
 END; 
-- b1 := GET_BATCHNO('B');
 
 --======= Step Insert Data ========
 for c_rec in (
 select a.clm_no ,a.pol_no ,a.pol_run ,nvl(a.policy_number,a.pol_no||a.pol_run) policy_number ,a.prod_grp ,a.prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,a.channel ,clm_men 
 ,nvl(a.clm_curr_code,'BHT') clm_curr_code 
 from mis_clm_mas a ,mis_clm_mas_seq d
 where a.clm_no = d.clm_no 
 and a.clm_no = vClmNo
 and d.corr_seq = (select max(x.corr_seq) from mis_clm_mas_seq x where x.clm_no = d.clm_no) 
 and a.clm_sts in ('6','7') and d.close_date is null 
 )
 loop 
 /* script 3 */
 if c_rec.channel = '9' then inw_type := 'Y'; else inw_type := null; end if; 
 begin
 select dept_id ,div_id ,team_id into V_DEPT_ID, V_DIV_ID, V_TEAM_ID
 from bkiuser
 where user_id = c_rec.clm_men; 
 exception
 when no_data_found then
 V_DEPT_ID:=null;
 V_DIV_ID :=null;
 V_TEAM_ID :=null;
 when others then
 V_DEPT_ID:=null;
 V_DIV_ID :=null;
 V_TEAM_ID :=null;
 end;
 
 for p1 in (select a.pay_no ,pay_seq ,pay_date ,payee_amt ,pay_total ,0 rec_total ,0 disc_total ,replace(payee_code,' ','') payee_code 
 from mis_clm_paid a, mis_clm_payee b
 where a.clm_no = b.clm_no
 and a.pay_no = b.pay_no
 and a.pay_no = vPayno
 and a.clm_no = c_rec.clm_no
 and pay_seq = (select max(e.pay_seq) from mis_clm_payee e where e.pay_no = b.pay_no )
 and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
 where b.pay_no = a.pay_no
 group by b.pay_no) 
 ) 
 loop 
 
 P_CLAIM_ACR.Post_acc_clm_tmp( c_rec.prod_grp /*P_prod_grp IN acc_clm_tmp.prod_grp%type*/,

 c_rec.prod_type /* P_prod_type IN acc_clm_tmp.prod_type%type */,

 p1.pay_no /* P_payno IN acc_clm_tmp.payment_no%type */,

 trunc(sysdate) /* P_appoint_date IN acc_clm_tmp.appoint_date%type */,

 c_rec.clm_no /* P_clmno IN acc_clm_tmp.clm_no%type */,

 c_rec.pol_no /* P_polno IN acc_clm_tmp.pol_no%type */,

 c_rec.pol_run /* P_polrun IN acc_clm_tmp.pol_run%type */,

 c_rec.policy_number /* P_polnum IN acc_clm_tmp.policy_number%type */,

 c_rec.pol_no||c_rec.pol_run /* P_polref IN acc_clm_tmp.pol_ref%type */, 

 c_rec.cus_code /* P_cuscode IN acc_clm_tmp.cus_code%type */,

 c_rec.th_eng /* P_th_eng IN acc_clm_tmp.th_eng%type */,

 c_rec.agent_code /* P_agent_code IN acc_clm_tmp.agent_code%type */,

 c_rec.agent_seq /* P_agent_seq IN acc_clm_tmp.agent_seq%type */,

 c_rec.clm_men /* P_Postby IN acc_clm_tmp.post_by%type */, 

 c_rec.br_code /* P_brn_code IN acc_clm_tmp.brn_code%type */,

 inw_type /* P_inw_type IN acc_clm_tmp.inw_type%type */,

 null /* P_batch_no IN acc_clm_tmp.batch_no%type */, 

 v_dept_id /* P_dept_id IN acc_clm_tmp.dept_id%type */,

 v_div_id /* P_div_id IN acc_clm_tmp.div_id%type */,

 v_team_id /* P_team_id IN acc_clm_tmp.team_id%type */,

 v_result /* P_msg Out varchar2*/); 
 
 if v_result is not null then rollback; P_RST:= v_result||' in P_CLAIM_ACR.Post_acc_clm_tmp'; return false; end if;
 
 for p5 in (select tot_res res_amt
 from mis_clm_mas a
 where a.clm_no = c_rec.clm_no) 
 loop
 v_RES_AMT := p5.res_amt; 
 end loop; 
 --v_ADV_AMT := v_RES_AMT - p1.pay_total;
 --v_ADV_AMT := p1.payee_amt - ( p1.pay_total-nvl(p1.rec_total,0) );

 for p3 in (select payee_code ,pay_seq ,payee_amt pay_amt,0 deduct_amt ,0 rec_amt 
 ,bank_code ,bank_br_code ,acc_no ,acc_name ,settle
 ,b.special_flag ,special_remark
 ,b.agent_mail_flag ,decode(b.agent_mail_flag,'Y',b.agent_mail,'') agent_mail,b.agent_sms_flag ,decode(b.agent_sms_flag,'Y',b.agent_mobile_number ,'') agent_mobile_number
 ,b.cust_mail_flag ,decode(b.cust_mail_flag ,'Y' ,b.cust_mail ,'') cust_mail ,b.sms_flag ,decode(b.sms_flag ,'Y' ,b.mobile_number ,'') mobile_number 
 from mis_clm_payee b
    where b.pay_no = p1.pay_no
    and nvl(corr_seq ,0) in (select max(nvl(aa.corr_seq,0)) from mis_clm_payee aa where aa.pay_no = b.pay_no)
    and payee_code is not null   
 ) 
 loop -- PAYEE LOOP
 v_DEDUCT_AMT := p3.deduct_amt; 
 V_REC_TOTAL := p3.rec_amt;
 V_GM_PAY := p3.pay_amt; 
 
 begin
 select b.title ,b.name ,b.contact_name into V_TITLE ,V_NAME ,V_CONTACT
 from acc_payee b
 where b.cancel is null
 and b.payee_code = replace(p3.payee_code,' ','');
 exception
 when no_data_found then
 V_TITLE:=null;
 V_NAME :=null;
 V_CONTACT := null;
 when others then
 V_TITLE:=null;
 V_NAME :=null;
 V_CONTACT := null;
 end; 
 
 --v_ADV_AMT := p1.payee_amt - ( p1.pay_total-nvl(p1.rec_total,0) ) - nvl(v_DEDUCT_AMT,0);
 --v_ADV_AMT := p1.payee_amt - ( V_GM_PAY - nvl(V_REC_TOTAL,0) ) - nvl(v_DEDUCT_AMT,0);
 v_ADV_AMT := 0;
 
 P_CLAIM_ACR.Post_acc_clm_payee_pagm( c_rec.prod_grp /* P_prod_grp IN acc_clm_payee_tmp.prod_grp%type */, 
 
 c_rec.prod_type /* P_prod_type IN acc_clm_payee_tmp.prod_type%type */,
 
 p1.pay_no /* P_payno IN acc_clm_payee_tmp.payment_no%type */,
 
 p3.pay_seq /* P_seq IN acc_clm_payee_tmp.seq%type */,
 
 '01' /* P_doc_type IN acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
 
 c_rec.clm_curr_code /* P_curr_code IN acc_clm_payee_tmp.curr_code%type */,
 
 p3.pay_amt /* P_payee_amt IN acc_clm_payee_tmp.payee_amt%type */,
 
 p3.payee_code /* P_payee_code IN acc_clm_payee_tmp.payee_code%type */,
 
 v_title /* P_title IN acc_clm_payee_tmp.title%type */,
 
 v_name /* P_name IN acc_clm_payee_tmp.name%type */, 
 
 '08' /* P_dept_no IN acc_clm_payee_tmp.dept_no%type */,
 
 null /* P_batch_no IN acc_clm_payee_tmp.batch_no%type */,
 
 nvl(v_DEDUCT_AMT,0) * -1 /* P_deduct_amt IN acc_clm_payee_tmp.deduct_amt%type */,
 
 v_ADV_AMT /* P_adv_amt IN acc_clm_payee_tmp.adv_amt%type */,
 
 p3.bank_code /* p_bank_code in acc_clm_payee_tmp.bank_code%type */ ,
 
 p3.bank_br_code /* p_branch_code in acc_clm_payee_tmp.branch_code%type */ ,
 
 p3.acc_no /* p_acc_no in acc_clm_payee_tmp.acc_no%type*/,
 
 p3.acc_name /* p_acc_name_th in acc_clm_payee_tmp.acc_name_th%type*/,
 
 null /* p_acc_name_eng in acc_clm_payee_tmp.acc_name_eng%type*/,
 
 null /* p_deposit_type in acc_clm_payee_tmp.deposit_type%type*/,
 
 p3.settle /* p_paid_type in acc_clm_payee_tmp.paid_type%type*/,
 
 p3.special_flag /* p_special_flag in acc_clm_payee_tmp.special_flag%type*/,
 
 p3.special_remark /* p_special_remark in acc_clm_payee_tmp.special_remark%type*/,
 
 p3.agent_mail /* p_agent_mail in acc_clm_payee_tmp.agent_mail%type*/,
 
 p3.agent_mail_flag /* p_agent_mail_flag in acc_clm_payee_tmp.agent_mail_flag%type*/,
 
 p3.agent_mobile_number /* p_agent_mobile_number in acc_clm_payee_tmp.agent_mobile_number%type*/,
 
 p3.agent_sms_flag /* p_agent_sms_flag in acc_clm_payee_tmp.agent_sms_flag%type*/,
 
 p3.cust_mail /* p_cust_mail in acc_clm_payee_tmp.cust_mail%type*/,
 
 p3.cust_mail_flag /* p_cust_mail_flag in acc_clm_payee_tmp.cust_mail_flag%type*/,
 
 p3.mobile_number /* p_mobile_number in acc_clm_payee_tmp.mobile_number%type*/, 
 
 p3.sms_flag /* p_sms_flag in acc_clm_payee_tmp.sms_flag%type*/, 
 
 V_RESULT2 /* P_msg Out varchar2*/ ) ; 
 
 if v_result2 is not null then rollback; P_RST:= v_result2||' in P_CLAIM_ACR.Post_acc_clm_payee_tmp'; return false; end if;
 
 end loop; -- end loop payee
 COMMIT; -- post ACC_CLM_TEMP b4 call post GL 

 -- ++++ get Send Address ++++
 BEGIN
 select a.send_title ,a.send_addr1 ,a.send_addr2 ,b.payee_code ,b.payee_name
 ,b.special_flag 
 ,b.agent_mail_flag ,decode(b.agent_mail_flag,'Y',b.agent_mail,'') agent_mail,b.agent_sms_flag ,decode(b.agent_sms_flag,'Y',b.agent_mobile_number ,'') agent_mobile_number
 ,b.cust_mail_flag ,decode(b.cust_mail_flag ,'Y' ,b.cust_mail ,'') cust_mail ,b.sms_flag ,decode(b.sms_flag ,'Y' ,b.mobile_number ,'') mobile_number 
 ,b.urgent_flag 
 into M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_CODE ,M_PAYEE_NAME 
 ,M_SPECIAL_FLAG 
 ,M_AGENT_MAIL_FLAG ,M_AGENT_MAIL ,M_AGENT_SMS_FLAG ,M_AGENT_MOBILE_NUMBER
 ,M_CUST_MAIL_FLAG ,M_CUST_MAIL ,M_SMS_FLAG ,M_MOBILE_NUMBER 
 ,M_URGENT_FLAG 
 from mis_clm_paid a ,mis_clm_payee b
 where a.pay_no = b.pay_no 
 and a.pay_no = vPayNo
 and (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
 where b.pay_no = a.pay_no
 group by b.pay_no) and rownum=1 ; 
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 null;
 WHEN OTHERS THEN
 null;
 END; 
 -- +++ + ++ + + + + + + + + + 
 
 begin 
 Insert into clm_sent_payee
 (KEY_NO ,SENT_TYPE ,PAYEE_CODE ,CONTACT_NAME ,ADDR1 ,ADDR2 ,PAYEE_NAME ,SEQ ,TRN_DATE)
 Values 
 (vPayNo ,'P' ,M_PAYEE_CODE ,M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_NAME ,vclm_sent_payee_seq ,sysdate); 
 
 exception
 when others then
 rollback; P_RST := 'error update claim: '||sqlerrm ; return false;
 end; 
 
 end loop; 
 end loop;
 --// End Run Individual ========
 COMMIT;
 
 V_STATUS_RST := UPDATE_STATUS_ACR(vPayNo , vClmUser);
 
 IF V_STATUS_RST is not null THEN 
 NC_HEALTH_PACKAGE.WRITE_LOG ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'UPDATE_STATUS' ,V_STATUS_RST,
 m_rst) ; 
 END IF;
 
 IF M_URGENT_FLAG is not null THEN -- check Urgent Case
 
 p_acc_claim.post_gl ( '0' /* p_prod_grp in acr_tmp.prod_grp%type */, 
 NC_CLNMC908.GET_PRODUCT_TYPE(vPayNo) /* p_prod_type in acr_tmp.prod_type%type */, 
 vPayNo /* p_number in varchar2 */, -- payment no or batch no 
 'P' /* p_flag in varchar2 */, -- 'P' = Payment, 'B' = Batch 
 V_RESULT3 /* p_err out varchar2 */); -- return null if no error 
 
 if V_RESULT3 is null then --post gl success 
 P_CLAIM_ACR.After_post_NC_PAYMENT(vPayNo ,NC_CLNMC908.GET_PRODUCT_TYPE(vPayNo) ,'Y', null , V_POSTGL_STS);
 else -- post error 
 P_CLAIM_ACR.After_post_NC_PAYMENT(vPayNo ,NC_CLNMC908.GET_PRODUCT_TYPE(vPayNo) ,'N', V_RESULT3 , V_POSTGL_STS);
 end if;
 
 END IF; 

 IF NC_HEALTH_PAID.IS_CASH_PAYMENT(vClmNo ,vPayNo ,'PA') THEN
    NC_HEALTH_PAID.EMAIL_ALERT_CASH(vClmNo ,vPayNo) ; 
 END IF;
 
 NC_HEALTH_PAID.FIX_LETTNO(vClmNo ,vPayNo);
 return true;
EXCEPTION
 WHEN OTHERS THEN
 rollback; P_RST := 'error update claim: '||sqlerrm ; return false;        
END POST_ACR_PA;

FUNCTION POST_ACR_GM(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS
  CURSOR c_clm IS select clm_no ,pol_no ,pol_run ,nvl(policy_number,pol_no||pol_run) policy_number ,prod_grp ,prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,channel ,clm_men
                                  from mis_clm_mas
                  where clm_no = vClmNo
                  ;    
    c_rec   c_clm%ROWTYPE;  
    
  v_chk Boolean:=false;       
  V_STATUS_RST varchar2(200);
  m_rst varchar2(200);
  inw_type varchar2(1);   
    b1    varchar2(10);
    b2    varchar2(10);           
    V_DEPT_ID VARCHAR (2) ;
    V_DIV_ID  VARCHAR (2) ;
    V_TEAM_ID VARCHAR (2);         
    V_RESULT    VARCHAR2(100);    
    V_RESULT2    VARCHAR2(100);        
    V_RESULT3    VARCHAR2(100);        
    V_RESULT_x    VARCHAR2(100);        
    V_TITLE      VARCHAR (30) ;
    V_NAME VARCHAR (200) ; 
    V_CONTACT VARCHAR (300) ;      
    V_VOUNO    varchar2(15);
    V_VOUDATE    DATE;
    V_REPRINT_NO    number(2);
    v_DEDUCT_AMT NUMBER    ;        
    v_RES_AMT    number;
    v_ADV_AMT number;
    V_GM_PAY number;
    V_REC_TOTAL number;        
    V_SUM_PAYEE number;
    cnt    number;
    M_SEND_TITLE    varchar2(100);    
    M_SEND_ADDR1  varchar2(200); 
    M_SEND_ADDR2  varchar2(200); 
    M_PAYEE_CODE  varchar2(20); 
    M_PAYEE_NAME  varchar2(200);         
    M_PAY_NO    varchar2(20);     
    
    vclm_sent_payee_seq  number;
    cnt_payee_seq   number(2):=0;
--    p_chkv   boolean;
BEGIN
    if  NOT validate_indv(vClmNo , vPayNo ,P_RST) then
        return false;
    end if;

    BEGIN
        select nvl(max(seq),0) +1  
        into vclm_sent_payee_seq
        from  clm_sent_payee
        where key_no = vPayNo;    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            vclm_sent_payee_seq := 1;
        WHEN OTHERS THEN
           vclm_sent_payee_seq := 1;
    END;  
                     
        --======= Step Insert Data ========
    for c_rec in (                   
        select clm_no ,pol_no ,pol_run ,nvl(policy_number,pol_no||pol_run) policy_number ,prod_grp ,prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,nvl(clm_br_code,'01') br_code ,channel ,clm_men
        from mis_clm_mas
        where clm_no =  vClmNo and clm_sts = '6' and close_date is null    
    )
    loop    
        /* script 3 */
        if c_rec.channel = '9' then inw_type := 'Y'; else inw_type := null; end if;    
        begin
            select dept_id ,div_id ,team_id into V_DEPT_ID, V_DIV_ID, V_TEAM_ID
            from bkiuser
            where user_id = c_rec.clm_men;                
            exception
        when no_data_found then
            V_DEPT_ID:=null;
            V_DIV_ID :=null;
            V_TEAM_ID :=null;
        when others then
            V_DEPT_ID:=null;
            V_DIV_ID :=null;
            V_TEAM_ID :=null;
        end;
                
        for p1 in (select a.pay_no ,pay_seq ,pay_date ,payee_amt ,pay_total ,rec_total ,disc_total ,replace(payee_code,' ','') payee_code 
                ,b.bank_code ,b.bank_br_code ,b.acc_no ,b.acc_name ,b.settle
                ,b.special_flag ,b.special_remark
                ,b.agent_mail_flag ,decode(b.agent_mail_flag,'Y',b.agent_mail,'') agent_mail,b.agent_sms_flag ,decode(b.agent_sms_flag,'Y',b.agent_mobile_number ,'') agent_mobile_number
                ,b.cust_mail_flag ,decode(b.cust_mail_flag ,'Y' ,b.cust_mail ,'') cust_mail ,b.sms_flag ,decode(b.sms_flag ,'Y' ,b.mobile_number ,'') mobile_number    
                   from mis_clmgm_paid a, clm_gm_payee b
                            where a.clm_no = b.clm_no
                            and a.pay_no = b.pay_no
                            and a.clm_no = c_rec.clm_no
                            and pay_seq = (select max(e.pay_seq) from clm_gm_payee e where e.pay_no = b.pay_no )
                            and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from mis_clmgm_paid b
                                            where b.clm_no = a.clm_no
                                            group by b.clm_no)                            
        )            
        loop             
                    
            P_CLAIM_ACR.Post_acc_clm_tmp(    c_rec.prod_grp /*P_prod_grp IN   acc_clm_tmp.prod_grp%type*/,

                c_rec.prod_type /* P_prod_type IN  acc_clm_tmp.prod_type%type */,

                p1.pay_no /* P_payno   IN  acc_clm_tmp.payment_no%type */,

                trunc(sysdate) /* P_appoint_date IN  acc_clm_tmp.appoint_date%type */,

                c_rec.clm_no /* P_clmno   IN  acc_clm_tmp.clm_no%type */,

                c_rec.pol_no /* P_polno   IN  acc_clm_tmp.pol_no%type */,

                c_rec.pol_run /* P_polrun  IN  acc_clm_tmp.pol_run%type */,

                c_rec.policy_number /* P_polnum  IN  acc_clm_tmp.policy_number%type */,

                c_rec.pol_no||c_rec.pol_run /* P_polref  IN  acc_clm_tmp.pol_ref%type */,          

                c_rec.cus_code /* P_cuscode IN  acc_clm_tmp.cus_code%type */,

                c_rec.th_eng /* P_th_eng IN  acc_clm_tmp.th_eng%type */,

                c_rec.agent_code /* P_agent_code IN  acc_clm_tmp.agent_code%type */,

                c_rec.agent_seq /* P_agent_seq IN  acc_clm_tmp.agent_seq%type */,

                c_rec.clm_men /* P_Postby IN  acc_clm_tmp.post_by%type */,                                        

                c_rec.br_code /* P_brn_code IN  acc_clm_tmp.brn_code%type */,

                inw_type /* P_inw_type IN  acc_clm_tmp.inw_type%type */,

                null /* P_batch_no IN acc_clm_tmp.batch_no%type */,                                      

                v_dept_id /* P_dept_id IN acc_clm_tmp.dept_id%type */,

                v_div_id /* P_div_id IN acc_clm_tmp.div_id%type */,

                v_team_id /* P_team_id IN acc_clm_tmp.team_id%type */,

                v_result /* P_msg Out varchar2*/);    

            if v_result is not null then rollback; P_RST:= v_result||' in P_CLAIM_ACR.Post_acc_clm_tmp'; return false; end if;                    

            for p5 in (select sum(res_amt) res_amt
                        from clm_medical_res a 
                        where a.clm_no  = c_rec.clm_no
                        and  (a.state_no,a.state_seq) = (select b.state_no,max(b.state_seq) from clm_medical_res b
                        where b.clm_no = a.clm_no and b.state_no = a.state_no
                        group by b.state_no) )     
            loop
                v_RES_AMT := p5.res_amt;            
            end loop;   
                    --v_ADV_AMT := v_RES_AMT - p1.pay_total;
                    --v_ADV_AMT := p1.payee_amt - ( p1.pay_total-nvl(p1.rec_total,0) );

            for p3 in (select sum(pay_amt) pay_amt ,sum(rec_amt) rec_amt ,sum(deduct_amt) deduct_amt
                from clm_gm_paid a
                where a.clm_no = c_rec.clm_no
                and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from clm_gm_paid b
                where b.clm_no = a.clm_no
                group by b.clm_no) )        
            loop
                v_DEDUCT_AMT := p3.deduct_amt;    
                V_REC_TOTAL := p3.rec_amt;
                V_GM_PAY    := p3.pay_amt;       
            end loop;            

            begin
                select sum(payee_amt) into V_SUM_PAYEE
                from clm_gm_payee b
                where b.clm_no = c_rec.clm_no and pay_no = p1.pay_no;
            exception
                when no_data_found then
                    V_SUM_PAYEE:=0;
                when others then
                    V_SUM_PAYEE:=0;
            end;   
                            
            --v_ADV_AMT := p1.payee_amt - ( p1.pay_total-nvl(p1.rec_total,0) ) - nvl(v_DEDUCT_AMT,0);
            --v_ADV_AMT := p1.payee_amt - ( V_GM_PAY - nvl(V_REC_TOTAL,0) ) - nvl(v_DEDUCT_AMT,0);
    --        v_ADV_AMT := nvl(p1.payee_amt,0) - (nvl(V_GM_PAY,0) -nvl(V_REC_TOTAL,0)) - nvl(v_DEDUCT_AMT,0);
            v_ADV_AMT := nvl(V_SUM_PAYEE,0) - (nvl(V_GM_PAY,0) -nvl(V_REC_TOTAL,0)) - nvl(v_DEDUCT_AMT,0);
            
            for p_payee in (
                select b.pay_no ,pay_seq  ,payee_amt  ,replace(payee_code,' ','') payee_code 
                ,b.bank_code ,b.bank_br_code ,b.acc_no ,b.acc_name ,b.settle
                ,b.special_flag ,b.special_remark
                ,b.agent_mail_flag ,decode(b.agent_mail_flag,'Y',b.agent_mail,'') agent_mail,b.agent_sms_flag ,decode(b.agent_sms_flag,'Y',b.agent_mobile_number ,'') agent_mobile_number
                ,b.cust_mail_flag ,decode(b.cust_mail_flag ,'Y' ,b.cust_mail ,'') cust_mail ,b.sms_flag ,decode(b.sms_flag ,'Y' ,b.mobile_number ,'') mobile_number    
                   from clm_gm_payee b
                            where b.clm_no = c_rec.clm_no
                            order by pay_seq
            ) loop
                cnt_payee_seq := cnt_payee_seq+1;
                if cnt_payee_seq > 1 then v_ADV_AMT :=0; end if; -- advance must insert only payee_seq = 1

                begin
                    select b.title ,b.name ,b.contact_name into V_TITLE ,V_NAME ,V_CONTACT
                    from acc_payee b
                    where b.cancel is null
                    and b.payee_code = replace(p_payee.payee_code,' ','');
                exception
                    when no_data_found then
                        V_TITLE:=null;
                        V_NAME :=null;
                        V_CONTACT := null;
                    when others then
                        V_TITLE:=null;
                        V_NAME :=null;
                        V_CONTACT := null;
                end;     
                            
                P_CLAIM_ACR.Post_acc_clm_payee_pagm( c_rec.prod_grp /* P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type */,  

                    c_rec.prod_type /* P_prod_type  IN  acc_clm_payee_tmp.prod_type%type */,
                                                        
                    p_payee.pay_no /* P_payno      IN  acc_clm_payee_tmp.payment_no%type */,
                                                        
                    p_payee.pay_seq /* P_seq        IN  acc_clm_payee_tmp.seq%type */,
                                                        
                    '01' /* P_doc_type   IN  acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
                                                        
                    'BHT' /* P_curr_code  IN  acc_clm_payee_tmp.curr_code%type */,
                                                        
                    p_payee.payee_amt /* P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type */,
                                                        
                    p_payee.payee_code /* P_payee_code IN  acc_clm_payee_tmp.payee_code%type */,
                                                        
                    v_title /* P_title      IN  acc_clm_payee_tmp.title%type */,
                                                        
                    v_name /* P_name       IN  acc_clm_payee_tmp.name%type */, 
                                                        
                    '08' /* P_dept_no    IN  acc_clm_payee_tmp.dept_no%type */,
                                                        
                    null /* P_batch_no   IN  acc_clm_payee_tmp.batch_no%type */,
                                                        
                    nvl(v_DEDUCT_AMT,0) * -1 /* P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type */,
                                                        
                    v_ADV_AMT /* P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type */,
                        
                    p_payee.bank_code    /* p_bank_code       in  acc_clm_payee_tmp.bank_code%type  */ ,
                       
                    p_payee.bank_br_code    /* p_branch_code     in  acc_clm_payee_tmp.branch_code%type */ ,
                       
                    p_payee.acc_no    /* p_acc_no          in  acc_clm_payee_tmp.acc_no%type*/,
                       
                    p_payee.acc_name    /* p_acc_name_th     in  acc_clm_payee_tmp.acc_name_th%type*/,
                       
                    null    /* p_acc_name_eng   in  acc_clm_payee_tmp.acc_name_eng%type*/,
                       
                    null    /* p_deposit_type    in  acc_clm_payee_tmp.deposit_type%type*/,
                       
                    p_payee.settle    /* p_paid_type       in  acc_clm_payee_tmp.paid_type%type*/,
                       
                    p_payee.special_flag    /* p_special_flag    in  acc_clm_payee_tmp.special_flag%type*/,
                       
                    p_payee.special_remark    /* p_special_remark    in  acc_clm_payee_tmp.special_remark%type*/,
                       
                    p_payee.agent_mail    /* p_agent_mail           in  acc_clm_payee_tmp.agent_mail%type*/,
                       
                    p_payee.agent_mail_flag    /* p_agent_mail_flag      in  acc_clm_payee_tmp.agent_mail_flag%type*/,
                       
                    p_payee.agent_mobile_number    /* p_agent_mobile_number  in  acc_clm_payee_tmp.agent_mobile_number%type*/,
                       
                    p_payee.agent_sms_flag    /* p_agent_sms_flag       in  acc_clm_payee_tmp.agent_sms_flag%type*/,
                       
                    p_payee.cust_mail    /* p_cust_mail            in  acc_clm_payee_tmp.cust_mail%type*/,
                       
                    p_payee.cust_mail_flag    /* p_cust_mail_flag       in  acc_clm_payee_tmp.cust_mail_flag%type*/,
                       
                    p_payee.mobile_number    /* p_mobile_number   in  acc_clm_payee_tmp.mobile_number%type*/,  
                       
                    p_payee.sms_flag    /* p_sms_flag        in  acc_clm_payee_tmp.sms_flag%type*/,                   
                                                        
                    V_RESULT2 /* P_msg       Out varchar2*/ ) ;       
                                                                        
                    if v_result2 is not null then rollback; P_RST:= v_result2||' in P_CLAIM_ACR.Post_acc_clm_payee_tmp'; return false; end if;
                 
                 --*** Insert CLM_GM_RECOV
                IF nvl(v_ADV_AMT,0) > 0 THEN
                    NMTR_PACKAGE.SET_CLM_GM_RECOV(c_rec.clm_no ,p1.pay_no ,v_ADV_AMT ,V_RESULT_x );
                END IF;  
                    
                if cnt_payee_seq =1 then
                    -- ++++ get Send Address ++++
                    BEGIN
                        select a.send_title ,a.send_addr1 ,a.send_addr2  ,replace(a.payee_code,' ','') ,a.payee_name
                        into M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_CODE ,M_PAYEE_NAME 
                        from clm_gm_payee a
                        where a.pay_no = vPayNo and replace(a.payee_code,' ','') = p1.payee_code     ;    
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            null;
                        WHEN OTHERS THEN
                            null;
                    END;    
                    -- +++ + ++ + + + + +  + + + + 
                        
                    begin            
                     Insert into clm_sent_payee
                       (KEY_NO ,SENT_TYPE ,PAYEE_CODE ,CONTACT_NAME ,ADDR1 ,ADDR2 ,PAYEE_NAME ,SEQ ,TRN_DATE)
                     Values              
                          (vPayNo ,'P' ,M_PAYEE_CODE ,M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_NAME ,vclm_sent_payee_seq ,sysdate);  
                                        
                    exception
                    when others then
                        rollback; P_RST := 'error update claim: '||sqlerrm ; return false;
                    end;          
                end if;   
            end loop; -- end Payee_loop            
                                                    
        end loop;      
    end loop;
    --// End Run Individual ========
        COMMIT;
             
        V_STATUS_RST := UPDATE_STATUS_ACR(vPayNo , vClmUser);
                    
        IF V_STATUS_RST is not null THEN 
            NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'UPDATE_STATUS' ,V_STATUS_RST,
                          m_rst)   ;                    
        END IF;

         IF NC_HEALTH_PAID.IS_CASH_PAYMENT(vClmNo ,vPayNo ,'GM') THEN
            NC_HEALTH_PAID.EMAIL_ALERT_CASH(vClmNo ,vPayNo) ; 
         END IF;
    
    NC_HEALTH_PAID.FIX_LETTNO(vClmNo ,vPayNo);              
    return true;
EXCEPTION
    WHEN OTHERS THEN
    rollback; P_RST := 'error update claim: '||sqlerrm ; return false;        
END POST_ACR_GM;

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

FUNCTION GET_APPROVE_DATE(vPayNo in varchar2  ) RETURN DATE IS
    v_date DATE;
BEGIN

    FOR X IN (
        select APPROVE_DATE
        from nc_payment x
        where pay_no = vPayNo
        and pay_sts = 'NCPAYSTS03'
    ) LOOP
        v_date := X.APPROVE_DATE ;
    END LOOP;
    
    return v_date ;
END GET_APPROVE_DATE;
    
FUNCTION GET_USER_NAME(vUser_id in varchar2  ) RETURN VARCHAR2 IS 
    v_name VARCHAR2(200);
BEGIN

    FOR X IN (
        select 'คุณ '||NAME_T UNAME from bkiuser where user_id = vUser_id 
    ) LOOP
        v_name := X.UNAME ;
    END LOOP;
    
    return v_name ;
END GET_USER_NAME;
    
FUNCTION UPDATE_STATUS(v_payno in varchar2 ,v_clm_user in varchar2 ) RETURN VARCHAR2 IS
    v_sts_seq number:=0;
    v_sts_seq_m number:=0;
    v_trn_seq number:=0;
    chk_success boolean:=false;
    v_stskey number(20);
    v_chk_med    varchar2(20):=null;
BEGIN
    BEGIN    
        select sts_key into v_stskey
        from nc_payment xxx
        where pay_no = v_payno
        and xxx.trn_seq = (select max(b.trn_seq) from nc_payment b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no)     
        and rownum=1;
    exception
    when no_data_found then
        v_stskey    := 0;
    when others then
        v_stskey    := 0;
      --display_proc(sqlerrm);
    END;    


    BEGIN
        select max(sts_seq) + 1 into v_sts_seq
        from nc_status a
        where sts_key = v_stskey and STS_TYPE = 'NCPAYSTS' ;
    exception
    when no_data_found then
        v_sts_seq    := 1;
    when others then
        v_sts_seq    := 1;
    END;    

    BEGIN
        select max(sts_seq) + 1 into v_sts_seq_m
        from nc_status a
        where sts_key = v_stskey and STS_TYPE = 'MEDSTS' ;
    exception
    when no_data_found then
        v_sts_seq_m    := 1;
    when others then
        v_sts_seq_m    := 1;
    END;    
        
    BEGIN
        select clm_no into v_chk_med
        from nc_mas a
        where sts_key = v_stskey;
    exception
    when no_data_found then
        v_chk_med    := null;
    when others then
        v_chk_med    := null;
    END;   
     
/**/
    BEGIN
        select max(trn_seq) + 1 into v_trn_seq
        from nc_payment a
        where sts_key = v_stskey and pay_no = v_payno ;
    exception
    when no_data_found then
        v_trn_seq    := 1;
    when others then
        v_trn_seq    := 1;
    END;
    
    BEGIN
--      INSERT INTO NC_STATUS -- Approve 
--       (STS_KEY, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE)
--      VALUES
--       (v_stskey ,v_sts_seq ,'NCPAYSTS', 'NCPAYSTS03' ,'Approve by NC_HEALTH_PAID' , v_clm_user ,sysdate); 
       
      INSERT INTO NC_STATUS -- Settle ACR 
       (STS_KEY, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE)
      VALUES
       (v_stskey ,v_sts_seq+0 ,'NCPAYSTS', 'NCPAYSTS05' ,'Post ACR by NC_HEALTH_PAID' , v_clm_user ,sysdate); 

      INSERT INTO NC_STATUS -- Wait for Print Statement
       (STS_KEY, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE)
      VALUES
       (v_stskey ,v_sts_seq+1 ,'NCPAYSTS', 'NCPAYSTS09' ,'Wait for Print by NC_HEALTH_PAID' ,v_clm_user ,sysdate); 

      INSERT INTO NC_STATUS -- Print Statement
       (STS_KEY, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE)
      VALUES
       (v_stskey ,v_sts_seq+2 ,'NCPAYSTS', 'NCPAYSTS10' ,'Printed Statement  by NC_HEALTH_PAID' , v_clm_user ,sysdate);        

        if v_chk_med is not null then
          INSERT INTO NC_STATUS -- update for MED STS
           (STS_KEY, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE)
          VALUES
           (v_stskey ,v_sts_seq_m+0 ,'MEDSTS', 'MEDSTS21' ,'Approve Payment' , v_clm_user ,sysdate);             
        end if;        
/**/        
       chk_success := true;
    exception
    when others then
        rollback;
        chk_success := false;
        return 'error Update STATUS :'||sqlerrm ;
    END;  
    
    begin
        FOR C1 in (
            select clm_no ,pay_no ,clm_seq ,trn_seq ,PAY_STS ,approve_id ,pay_amt ,trn_amt ,curr_code ,curr_rate 
            ,sts_date ,clm_men ,prod_grp ,prod_type ,subsysid ,STS_KEY ,print_type ,type ,sub_type ,apprv_flag
            from nc_payment a
            where sts_key = v_stskey and pay_no = v_payno
            and trn_seq = (select max(b.trn_seq) from nc_payment b where b.sts_key = a.sts_key and b.pay_no = a.pay_no)             
        )            
        LOOP                
                
--          INSERT INTO NC_PAYMENT
--           (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
--           STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
--           SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG)
--          VALUES
--           (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,'NCPAYSTS03' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
--           c1.STS_DATE, sysdate, c1.CLM_MEN, :global.user_id , c1.APPROVE_ID ,sysdate , c1.PROD_GRP, c1.PROD_TYPE, 
--           c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG );

          INSERT INTO NC_PAYMENT
           (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
           STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
           SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG ,SETTLE_DATE ,PREM_CODE ,PREM_SEQ )
          VALUES
           (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,'NCPAYSTS05' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
           c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , c1.APPROVE_ID ,sysdate , c1.PROD_GRP, c1.PROD_TYPE, 
           c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ,sysdate ,'0000' ,1);

          INSERT INTO NC_PAYMENT
           (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
           STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
           SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG ,SETTLE_DATE  ,PREM_CODE ,PREM_SEQ)
          VALUES
           (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+2 ,'NCPAYSTS09' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
           c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , c1.APPROVE_ID ,sysdate , c1.PROD_GRP, c1.PROD_TYPE, 
           c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ,sysdate ,'0000' ,1);

          INSERT INTO NC_PAYMENT
           (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
           STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
           SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG ,SETTLE_DATE  ,PREM_CODE ,PREM_SEQ )
          VALUES
           (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+3 ,'NCPAYSTS10' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
           c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , c1.APPROVE_ID ,sysdate , c1.PROD_GRP, c1.PROD_TYPE, 
           c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ,sysdate ,'0000' ,1);    
    
                                      
                chk_success := true;
            END LOOP;    
    exception
        when no_data_found then
            null;
        when others then
            rollback;
            chk_success := false;
            return ('error update NC_PAYMENT :'||sqlerrm);
    end;        
    
    IF chk_success THEN 
        COMMIT;return null ; 
    END IF;
    
    return null;
    
END UPDATE_STATUS;

FUNCTION UPDATE_STATUS_ACR(v_payno in varchar2 ,v_clm_user in varchar2 ) RETURN VARCHAR2 IS
    v_sts_seq number:=0;
    v_sts_seq_m number:=0;
    v_trn_seq number:=0;
    chk_success boolean:=false;
    v_stskey number(20);
    v_chk_med    varchar2(20):=null;
    v_chk_ncapprv   varchar2(20):=null;
    v_trn_seq2 number:=0;
    v_apprvid varchar2(20);
    v_apprvdate date;    
BEGIN
    BEGIN    
        select sts_key into v_stskey
        from nc_payment xxx
        where pay_no = v_payno
        and xxx.trn_seq = (select max(b.trn_seq) from nc_payment b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no)     
        and rownum=1;
    exception
    when no_data_found then
        v_stskey    := 0;
    when others then
        v_stskey    := 0;
      --display_proc(sqlerrm);
    END;    

    BEGIN
        select nvl(max(sts_seq)+1,1) into v_sts_seq
        from nc_status a
        where sts_key = v_stskey and STS_TYPE = 'NCPAYSTS' ;
    exception
    when no_data_found then
        v_sts_seq    := 1;
    when others then
        v_sts_seq    := 1;
    END;    

    BEGIN
        select nvl(max(sts_seq)+1,1) into v_sts_seq_m
        from nc_status a
        where sts_key = v_stskey and STS_TYPE = 'MEDSTS' ;
    exception
    when no_data_found then
        v_sts_seq_m    := 1;
    when others then
        v_sts_seq_m    := 1;
    END;    
        
    BEGIN
        select clm_no into v_chk_med
        from nc_mas a
        where sts_key = v_stskey;
    exception
    when no_data_found then
        v_chk_med    := null;
    when others then
        v_chk_med    := null;
    END;   
     
/**/
    BEGIN
        select nvl(max(trn_seq)+1,1) into v_trn_seq
        from nc_payment a
        where sts_key = v_stskey and pay_no = v_payno ;
    exception
    when no_data_found then
        v_trn_seq    := 1;
    when others then
        v_trn_seq    := 1;
    END;

    -- Module for new PH system Approve+Post ACR
    BEGIN
        select nvl(max(trn_seq)+1,1) into v_trn_seq2
        from nc_payment_apprv a
        where sts_key = v_stskey and pay_no = v_payno ;
    exception
    when no_data_found then
        v_trn_seq2    := 1;
    when others then
        v_trn_seq2    := 1;
    END;    

    BEGIN --    Check Has NC_PAYMENT_APPRV ? 
        select clm_no into v_chk_ncapprv
        from nc_payment_apprv a
        where pay_no = v_payno and rownum =1;
    exception
    when no_data_found then
        v_chk_ncapprv    := null;
    when others then
        v_chk_ncapprv    := null;
    END;    
        
    BEGIN
       
      INSERT INTO NC_STATUS -- Post acc clm temp
       (STS_KEY, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE)
      VALUES
       (v_stskey ,v_sts_seq+0 ,'NCPAYSTS', 'NCPAYSTS11' ,'Post ACC CLM Temp by NC_HEALTH_PAID' , v_clm_user ,sysdate);     

        if v_chk_med is not null and v_chk_ncapprv is null then
          INSERT INTO NC_STATUS -- update for MED STS
           (STS_KEY, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE)
          VALUES
           (v_stskey ,v_sts_seq_m+0 ,'MEDSTS', 'MEDSTS21' ,'Approve Payment' , v_clm_user ,sysdate);             
        end if;        
/**/        
       chk_success := true;
    exception
    when others then
        rollback;
        chk_success := false;
        return 'error Update STATUS :'||sqlerrm ;
    END;  
    
    begin
        FOR C1 in (
            select clm_no ,pay_no ,clm_seq ,trn_seq ,PAY_STS ,approve_id ,pay_amt ,trn_amt ,curr_code ,curr_rate 
            ,sts_date ,clm_men ,prod_grp ,prod_type ,subsysid ,STS_KEY ,print_type ,type ,sub_type ,apprv_flag ,APPROVE_DATE
            from nc_payment a
            where sts_key = v_stskey and pay_no = v_payno
            and trn_seq = (select max(b.trn_seq) from nc_payment b where b.sts_key = a.sts_key and b.pay_no = a.pay_no and b.type='01')  
            and a.type='01'           
        )            
        LOOP                

          INSERT INTO NC_PAYMENT
           (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
           STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
           SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG ,SETTLE_DATE , PREM_CODE ,PREM_SEQ)
          VALUES
           (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,'NCPAYSTS11' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
           c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , c1.APPROVE_ID ,c1.APPROVE_DATE , c1.PROD_GRP, c1.PROD_TYPE, 
           c1.SUBSYSID, c1.STS_KEY, '01','01', 'Y' ,sysdate ,'0000' ,1);      

                v_apprvid := C1.APPROVE_ID;
                v_apprvdate := c1.APPROVE_DATE;
                                                      
                chk_success := true;
            END LOOP;    
    exception
        when no_data_found then
            null;
        when others then
            rollback;
            chk_success := false;
            return ('error update NC_PAYMENT :'||sqlerrm);
    end;        

    IF v_chk_ncapprv is not null THEN
        begin
            FOR C1 in (
                select clm_no ,pay_no ,clm_seq ,trn_seq ,PAY_STS ,approve_id ,pay_amt ,trn_amt ,curr_code ,curr_rate 
                ,sts_date ,clm_men ,prod_grp ,prod_type ,subsysid ,STS_KEY ,print_type ,type ,sub_type ,apprv_flag ,approve_date
                from nc_payment_apprv a
                where sts_key = v_stskey and pay_no = v_payno
                and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no)             
            )            
            LOOP                

              INSERT INTO NC_PAYMENT_APPRV
               (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
               STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
               SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG ,SETTLE_DATE ,remark )
              VALUES
               (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,'PHSTSAPPRV11' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
               c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , v_apprvid ,v_apprvdate , c1.PROD_GRP, c1.PROD_TYPE, 
               c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, 'Y' ,sysdate ,'Post ACC CLM Temp by NC_HEALTH_PAID' );           
                                          
                    chk_success := true;
            END LOOP;   
            
            UPDATE NC_MAS
            set 
--            claim_status = 'PHCLMSTS06' ,
            approve_status = 'PHSTSAPPRV11'
            where STS_KEY =v_stskey ;            
        exception
            when no_data_found then
                null;
            when others then
                rollback;
                chk_success := false;
                return ('error update NC_PAYMENT_APPRV :'||sqlerrm);
        end;         
    END IF;
        
    IF chk_success THEN 
        COMMIT;return null ; 
    END IF;
    
    return null;
    
END UPDATE_STATUS_ACR;

FUNCTION UPDATE_STATUS_AFTER_POST(v_payno in varchar2 ,v_clm_user in varchar2  ,v_success in varchar2 ,v_note in varchar2) RETURN VARCHAR2 IS
    v_sts_seq number:=0;
    v_sts_seq_m number:=0;
    v_trn_seq number:=0;
    chk_success boolean:=false;
    v_stskey number(20);
    v_chk_med    varchar2(20):=null;
    p_status    varchar2(20);
    p_remark    varchar2(200);
    
    v_stskey2 number(20);
    p_status2    varchar2(20);
    v_trn_seq2 number:=0;
    v_chk_ncapprv    varchar2(20):=null;
    v_apprvid varchar2(20);
    v_apprvdate date;
BEGIN
    if nvl(v_success ,'N') = 'Y' then
        p_status := 'NCPAYSTS12';
        p_status2 := 'PHSTSAPPRV12';
        p_remark := 'Post ACR by NC_HEALTH_PAID';
    elsif nvl(v_success ,'N') = 'N' then
        p_status := 'NCPAYSTS80';
        p_status2 := 'PHSTSAPPRV80';
        p_remark := 'Post ACR Error: '||v_note;
    end if;

    BEGIN    
        select sts_key into v_stskey
        from nc_payment xxx
        where pay_no = v_payno
        and xxx.trn_seq = (select max(b.trn_seq) from nc_payment b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no)     
        and rownum=1;
    exception
    when no_data_found then
        v_stskey    := 0;
    when others then
        v_stskey    := 0;
      --display_proc(sqlerrm);
    END;    


    BEGIN
        --max(sts_seq) + 1 
        select nvl(max(sts_seq)+1,1)into v_sts_seq
        from nc_status a
        where sts_key = v_stskey and STS_TYPE = 'NCPAYSTS' ;
    exception
    when no_data_found then
        v_sts_seq    := 1;
    when others then
        v_sts_seq    := 1;
    END;    

    BEGIN
        --  max(sts_seq) + 1
        select nvl(max(sts_seq)+1,1) into v_sts_seq_m 
        from nc_status a
        where sts_key = v_stskey and STS_TYPE = 'MEDSTS' ;
    exception
    when no_data_found then
        v_sts_seq_m    := 1;
    when others then
        v_sts_seq_m    := 1;
    END;    
        
    BEGIN
        select clm_no into v_chk_med
        from nc_mas a
        where sts_key = v_stskey;
    exception
    when no_data_found then
        v_chk_med    := null;
    when others then
        v_chk_med    := null;
    END;   
     
/**/
    BEGIN
        select max(trn_seq) + 1 into v_trn_seq
        from nc_payment a
        where sts_key = v_stskey and pay_no = v_payno  ;
    exception
    when no_data_found then
        v_trn_seq    := 1;
    when others then
        v_trn_seq    := 1;
    END;
        
    BEGIN
       
      INSERT INTO NC_STATUS -- Post acc clm temp
       (STS_KEY, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE)
      VALUES
       (v_stskey ,v_sts_seq+0 ,'NCPAYSTS',P_STATUS ,p_remark , v_clm_user ,sysdate);     

        if v_chk_med is not null and nvl(v_success ,'N') = 'Y' then
          INSERT INTO NC_STATUS -- update for MED STS
           (STS_KEY, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE)
          VALUES
           (v_stskey ,v_sts_seq_m+0 ,'MEDSTS', 'MEDSTS21' ,'Approve Payment' , v_clm_user ,sysdate);             
        end if;        
/**/        
       chk_success := true;
    exception
    when others then
        rollback;
        chk_success := false;
        return 'error Update STATUS :'||sqlerrm ;
    END;  
    
    -- Module for new PH system Approve+Post ACR
    BEGIN
        select nvl(max(trn_seq)+1,1) into v_trn_seq2
        from nc_payment_apprv a
        where sts_key = v_stskey and pay_no = v_payno ;
    exception
    when no_data_found then
        v_trn_seq2    := 1;
    when others then
        v_trn_seq2    := 1;
    END;    

    BEGIN --    Check Has NC_PAYMENT_APPRV ? 
        select clm_no into v_chk_ncapprv
        from nc_payment_apprv a
        where pay_no = v_payno and rownum =1;
    exception
    when no_data_found then
        v_chk_ncapprv    := null;
    when others then
        v_chk_ncapprv    := null;
    END;    
    
    IF v_chk_ncapprv is not null THEN
        begin
            FOR C1 in (
                select clm_no ,pay_no ,clm_seq ,trn_seq ,PAY_STS ,approve_id ,pay_amt ,trn_amt ,curr_code ,curr_rate 
                ,sts_date ,clm_men ,prod_grp ,prod_type ,subsysid ,STS_KEY ,print_type ,type ,sub_type ,apprv_flag ,approve_date
                from nc_payment_apprv a
                where sts_key = v_stskey and pay_no = v_payno
                and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no)             
            )            
            LOOP                
                v_apprvid := C1.APPROVE_ID;
                v_apprvdate := c1.APPROVE_DATE;
                if v_apprvdate is null then -- case Approve from CLNMC924
                    for x in (
                        select approve_id ,approve_date
                        from nc_payment a
                        where sts_key = v_stskey and pay_no = v_payno
                        and trn_seq = (select max(b.trn_seq) from nc_payment b where b.sts_key = a.sts_key and b.pay_no = a.pay_no and b.type='01') 
                        and a.type='01'            
                    )            
                    loop  
                        v_apprvid := x.approve_id;
                        v_apprvdate := x.approve_date;
                    end loop;                
                end if;
                
              INSERT INTO NC_PAYMENT_APPRV
               (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
               STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
               SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG ,SETTLE_DATE ,remark )
              VALUES
               (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,P_STATUS2 , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
               c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , c1.APPROVE_ID ,c1.APPROVE_DATE , c1.PROD_GRP, c1.PROD_TYPE, 
               c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ,sysdate ,p_remark);           
                                          
                    chk_success := true;
            END LOOP;    

            UPDATE NC_MAS
            set 
            claim_status = 'PHCLMSTS06' ,
            approve_status = P_STATUS2
            where STS_KEY =v_stskey ;  
                        
        exception
            when no_data_found then
                null;
            when others then
                rollback;
                chk_success := false;
                return ('error update NC_PAYMENT_APPRV :'||sqlerrm);
        end;         
    END IF;

    begin
        FOR C1 in (
            select clm_no ,pay_no ,clm_seq ,trn_seq ,PAY_STS ,approve_id ,pay_amt ,trn_amt ,curr_code ,curr_rate 
            ,sts_date ,clm_men ,prod_grp ,prod_type ,subsysid ,STS_KEY ,print_type ,type ,sub_type ,apprv_flag ,APPROVE_DATE
            from nc_payment a
            where sts_key = v_stskey and pay_no = v_payno
            and trn_seq = (select max(b.trn_seq) from nc_payment b where b.sts_key = a.sts_key and b.pay_no = a.pay_no 
            and b.type='01'
            )       and a.type='01'      
        )            
        LOOP                
          IF v_chk_ncapprv  is null THEN
                v_apprvid := C1.APPROVE_ID;
                v_apprvdate := c1.APPROVE_DATE;          
          END IF;
          
          INSERT INTO NC_PAYMENT
           (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
           STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
           SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG ,SETTLE_DATE  ,PREM_CODE ,PREM_SEQ)
          VALUES
           (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,P_STATUS , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
           c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , v_apprvid ,v_apprvdate , c1.PROD_GRP, c1.PROD_TYPE, 
           c1.SUBSYSID, c1.STS_KEY, '01', '01','Y' ,sysdate ,'0000' ,1);      
                                      
                chk_success := true;
        END LOOP;    
    exception
        when no_data_found then
            null;
        when others then
            rollback;
            chk_success := false;
            return ('error update NC_PAYMENT :'||sqlerrm);
    end;   
        
    IF chk_success THEN 
        COMMIT;return null ; 
    END IF;
    
    return null;
    
END UPDATE_STATUS_AFTER_POST;

FUNCTION UPDATE_CLM_AFTER_POST(v_payno in varchar2 ,v_sys in varchar2 /* PA ,GM */ ,v_vouno in varchar2 ,v_voudate in date) RETURN VARCHAR2 IS -- null = success  
    p_clmno varchar2(20);
    MY_SYSDATE  date:=sysdate;
    v_part varchar2(5000);
BEGIN
    IF v_sys = 'PA' THEN
        begin
            select clm_no into p_clmno
            from mis_clm_paid
            where pay_no = v_payno and rownum=1;
        exception
            when no_data_found then
                p_clmno := null;
            when others then
                p_clmno := null;
        end;

        begin
            select longtochar('MIS_CLM_PAID','PART',rowid,1,5000)
                into v_part
            from mis_clm_paid a
            where clm_no = p_clmno and pay_no = v_payno    
            and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
                    where b.pay_no = a.pay_no
                    group by b.pay_no)        
            ;
        exception
           when no_data_found then
           v_part := null;                           
           when others then
           v_part := null;
        end;
        
        for v1 in (
            select CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS
            from mis_clm_mas_seq a
            where clm_no = p_clmno
            and a.corr_seq in (select max(aa.corr_seq) from mis_clm_mas_seq aa where aa.clm_no = a.clm_no)
        ) loop         

            Insert into MIS_CLM_MAS_SEQ
               (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE
               , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS)
             Values
               (v1.CLM_NO, v1.POL_NO, v1.POL_RUN, v1.CORR_SEQ+1, MY_SYSDATE, v1.CHANNEL, v1.PROD_GRP, v1.PROD_TYPE, v1.CLM_DATE ,null
               , v1.TOT_RES, v1.TOT_PAID, TRUNC(MY_SYSDATE) ,'2' );        

            insert into mis_clm_paid (clm_no, pay_no, pay_sts, pay_date, pay_total, part, settle, pay_type, prt_flag, attached, acc_no, acc_name, bank_code, br_name, remark, pay_curr_code, pay_curr_rate, trn_date, app_sts, total_pay_total, vat_amt, rem_close, corr_seq, corr_date, tot_deduct_amt, state_flag, vat_percent, deduct_amt, rec_pay_date, sendchq_addr, send_title, send_addr1, send_addr2, bank_br_code, polyj_flag, co_pay_tatal, co_deduct_total, branch_code, acc_type, batch_no, print_type, reprint_no, print_batch, invoice_no, job_no, print_sts, deposit_type, paid_type, special_flag, special_remark, agent_mail, agent_mail_flag, agent_mobile_number, agent_sms_flag, cust_mail, cust_mail_flag, mobile_number, sms_flag, urgent_flag )
            (select a.clm_no, a.pay_no, a.pay_sts, a.pay_date, a.pay_total, '' , a.settle, a.pay_type, a.prt_flag, a.attached, a.acc_no, a.acc_name, a.bank_code, a.br_name, a.remark, a.pay_curr_code, a.pay_curr_rate, MY_SYSDATE, a.app_sts, a.total_pay_total, a.vat_amt, a.rem_close, a.corr_seq+1, MY_SYSDATE , a.tot_deduct_amt, a.state_flag, a.vat_percent, a.deduct_amt, a.rec_pay_date, a.sendchq_addr, a.send_title, a.send_addr1, a.send_addr2, a.bank_br_code, a.polyj_flag, a.co_pay_tatal, a.co_deduct_total, a.branch_code, a.acc_type, a.batch_no, a.print_type, a.reprint_no, a.print_batch, a.invoice_no, a.job_no, a.print_sts, a.deposit_type, a.paid_type, a.special_flag, a.special_remark, a.agent_mail, a.agent_mail_flag, a.agent_mobile_number, a.agent_sms_flag, a.cust_mail, a.cust_mail_flag, a.mobile_number, a.sms_flag, a.urgent_flag   
            from misc.mis_clm_paid a
                        where clm_no = p_clmno and pay_no = v_payno     
                        and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
                                where b.pay_no = a.pay_no
                                group by b.pay_no)    
            );

            Insert into MIS_CRI_PAID
            (CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, CORR_SEQ, LF_FLAG, RI_SUB_TYPE ,RI_CONT ,LETT_REMARK)                                                    
            (
            select CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, CORR_SEQ+1, LF_FLAG, RI_SUB_TYPE ,RI_CONT ,LETT_REMARK
            from mis_cri_paid a
            where clm_no = p_clmno and pay_no = v_payno    
            and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_cri_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no)                                     
            );

            insert into MIS_CPA_PAID (clm_no, pay_no, pay_sts, fleet_seq, loss_name, loss_date, loss_detail, paid_remark, prem_code1, prem_code2, prem_code3, prem_code4, prem_code5, prem_code6, prem_code7, prem_code8, prem_code9, prem_code10, prem_pay1, prem_pay2, prem_pay3, prem_pay4, prem_pay5, prem_pay6, prem_pay7, prem_pay8, prem_pay9, prem_pay10, cancel, risk_code, run_seq, corr_seq, dis_code, hpt_code, loss_of_day, loss_date_fr, loss_date_to, add_day, prem_code11, prem_code12, prem_code13, prem_code14, prem_code15, prem_code16, prem_code17, prem_code18, prem_code19, prem_code20, prem_code21, prem_code22, prem_code23, prem_code24, prem_code25, prem_pay11, prem_pay12, prem_pay13, prem_pay14, prem_pay15, prem_pay16, prem_pay17, prem_pay18, prem_pay19, prem_pay20, prem_pay21, prem_pay22, prem_pay23, prem_pay24, prem_pay25, res_remark, hpt_seq)
            (
            select a.clm_no, a.pay_no, a.pay_sts, a.fleet_seq, a.loss_name, a.loss_date, a.loss_detail, a.paid_remark, a.prem_code1, a.prem_code2, a.prem_code3, a.prem_code4, a.prem_code5, a.prem_code6, a.prem_code7, a.prem_code8, a.prem_code9, a.prem_code10, a.prem_pay1, a.prem_pay2, a.prem_pay3, a.prem_pay4, a.prem_pay5, a.prem_pay6, a.prem_pay7, a.prem_pay8, a.prem_pay9, a.prem_pay10, a.cancel, a.risk_code, a.run_seq, a.corr_seq+1, a.dis_code, a.hpt_code, a.loss_of_day, a.loss_date_fr, a.loss_date_to, a.add_day, a.prem_code11, a.prem_code12, a.prem_code13, a.prem_code14, a.prem_code15, a.prem_code16, a.prem_code17, a.prem_code18, a.prem_code19, a.prem_code20, a.prem_code21, a.prem_code22, a.prem_code23, a.prem_code24, a.prem_code25, a.prem_pay11, a.prem_pay12, a.prem_pay13, a.prem_pay14, a.prem_pay15, a.prem_pay16, a.prem_pay17, a.prem_pay18, a.prem_pay19, a.prem_pay20, a.prem_pay21, a.prem_pay22, a.prem_pay23, a.prem_pay24, a.prem_pay25, a.res_remark, a.hpt_seq   from misc.mis_cpa_paid a
            where  clm_no = p_clmno and pay_no = v_payno    
            and a.corr_seq in (select max(aa.corr_seq) from mis_cpa_paid aa where aa.pay_no = a.pay_no)
            );
                                    
        end loop; -- mis_clm_mas_seq
                                        
        begin
            Update mis_clm_paid a 
            set a.print_type = '1' ,
            a.pay_date = V_VOUDATE ,a.state_flag='1' ,
            a.corr_date = V_VOUDATE ,part = v_part 
            where a.clm_no = p_clmno
            and a.pay_no = v_payno 
            and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no);        
                                    
            update mis_clm_mas
            set    clm_sts = '2',
            close_date = trunc(MY_SYSDATE)
            where  clm_no = p_clmno;
                                                   
                                
        exception
        when others then
            rollback; return 'error update claim: '||sqlerrm ;
        end;     
        COMMIT; return '';
    ELSIF v_sys = 'GM' THEN
        begin
            select clm_no into p_clmno
            from mis_clmgm_paid
            where pay_no = v_payno and rownum=1;
        exception
            when no_data_found then
                p_clmno := null;
            when others then
                p_clmno := null;
        end;

        for v1 in (
            select CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS
            from mis_clm_mas_seq a
            where clm_no = p_clmno
            and a.corr_seq in (select max(aa.corr_seq) from mis_clm_mas_seq aa where aa.clm_no = a.clm_no)
        ) loop         

            Insert into MIS_CLM_MAS_SEQ
               (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE
               , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS)
             Values
               (v1.CLM_NO, v1.POL_NO, v1.POL_RUN, v1.CORR_SEQ+1, MY_SYSDATE, v1.CHANNEL, v1.PROD_GRP, v1.PROD_TYPE, v1.CLM_DATE ,null
               , v1.TOT_RES, v1.TOT_PAID, TRUNC(MY_SYSDATE) ,'2' );        


            Insert into MIS_CRI_PAID
            (CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, CORR_SEQ, LF_FLAG, RI_SUB_TYPE ,RI_CONT ,LETT_REMARK)                                                    
            (
            select CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, CORR_SEQ+1, LF_FLAG, RI_SUB_TYPE ,RI_CONT ,LETT_REMARK
            from mis_cri_paid a
            where clm_no = p_clmno and pay_no = v_payno    
            and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_cri_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no)                                     
            );

            insert into mis_clmgm_paid (clm_no, pay_no, corr_seq, pay_date, pay_total, rec_total, disc_total, settle, part, remark, lett_recno, permit, permit_date, acc_no, acc_name, acc_type, bank_code, branch_code, rec_pay_date, batch_no, print_type, reprint_no, print_sts, deposit_type, paid_type, special_flag, special_remark, agent_mail, agent_mail_flag, agent_mobile_number, agent_sms_flag, cust_mail, cust_mail_flag, mobile_number, sms_flag, urgent_flag)
            (
            select a.clm_no, a.pay_no, a.corr_seq+1, a.pay_date, a.pay_total, a.rec_total, a.disc_total, a.settle, a.part, a.remark, a.lett_recno, a.permit, a.permit_date, a.acc_no, a.acc_name, a.acc_type, a.bank_code, a.branch_code, a.rec_pay_date, a.batch_no, a.print_type, a.reprint_no, a.print_sts, a.deposit_type, a.paid_type, a.special_flag, a.special_remark, a.agent_mail, a.agent_mail_flag, a.agent_mobile_number, a.agent_sms_flag, a.cust_mail, a.cust_mail_flag, a.mobile_number, a.sms_flag, a.urgent_flag from misc.mis_clmgm_paid a
            where a.clm_no = p_clmno and pay_no = v_payno
            and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_clmgm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no)
            );                                    

            insert into clm_gm_paid(clm_no, pay_no, corr_seq, fleet_seq, sub_seq, plan, pd_flag, dis_code, bene_code, loss_date, date_paid, corr_date, disc_rate, disc_amt, pay_amt, hpt_code, rec_amt, clm_pd_flag, remark, sur_percent, ipd_day, seq, rec_pay_date, deduct_amt, fam_seq, dept_bki, id_no )
            (
            select a.clm_no, a.pay_no, a.corr_seq+1, a.fleet_seq, a.sub_seq, a.plan, a.pd_flag, a.dis_code, a.bene_code, a.loss_date, a.date_paid, MY_SYSDATE, a.disc_rate, a.disc_amt, a.pay_amt, a.hpt_code, a.rec_amt, a.clm_pd_flag, a.remark, a.sur_percent, a.ipd_day, a.seq, a.rec_pay_date, a.deduct_amt, a.fam_seq, a.dept_bki, a.id_no   from misc.clm_gm_paid a
            where a.clm_no = p_clmno and pay_no = v_payno
                        and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from clm_gm_paid b
                        where b.pay_no = a.pay_no
                        group by b.pay_no)
            );
            
        end loop; -- mis_clm_mas_seq
                
        begin
            Update mis_clmgm_paid a 
            set a.print_type = '1' ,
            a.pay_date = V_VOUDATE 
            where a.clm_no = p_clmno
            and pay_no = v_payno
            and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_clmgm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no);        
                
            update clm_gm_paid a 
            set a.date_paid = V_VOUDATE
            where a.clm_no = p_clmno
            and pay_no = v_payno
            and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from clm_gm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no);

            update clm_medical_res a 
            set a.close_date = V_VOUDATE
            where a.clm_no = p_clmno
            and  (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq) from clm_medical_res b
            where b.clm_no = a.clm_no
            group by b.clm_no,b.state_no);
                
            update mis_clm_mas
            set    clm_sts = '2',
                 close_date = trunc(MY_SYSDATE)
                 ,out_open_sts = 'Y'
                 ,out_paid_sts = 'Y'
                 ,out_print_sts ='Y'
            where  clm_no = p_clmno;
                                                                         
        exception
        when others then
            rollback; return 'error update claim: '||sqlerrm ;
        end;     
        COMMIT; return '';    
    ELSE
        return 'Not found SYS :'||v_sys;
    END IF;
END UPDATE_CLM_AFTER_POST;

FUNCTION GET_URGENTMAIL(v_vouno IN VARCHAR2 , v_voudate IN DATE ,v_User IN VARCHAR2 ,out_url OUT varchar2) RETURN VARCHAR2 IS   -- return null = success     
    v_refno varchar2(200);
    o_msg    varchar2(200);
    m_rst    varchar2(200);
BEGIN
    v_refno := account.p_acc_util.get_acc_paramref;
    account.p_acc_util.insert_acc_parameter(v_refno,
                                          'VOU_NO',
                                          v_vouno,
                                          v_User,
                                          null,
                                          o_msg);    
    account.p_acc_util.insert_acc_parameter(v_refno,
                                          'VOU_DATE',
                                          to_char(v_voudate,'dd/mm/yyyy'),
                                          v_User,
                                          null,
                                          o_msg);    
    account.p_acc_util.insert_acc_parameter(v_refno,
                                          'PROD_GRP',
                                          '0',
                                          v_User,
                                          null,
                                          o_msg);    
    account.p_acc_util.insert_acc_parameter(v_refno,
                                          'URGENT',
                                          'Y',
                                          v_User,
                                          null,
                                          o_msg);             
    out_url := account.p_acc_util.get_web_url(v_User, 'ACACR017', v_refno);
    
    if out_url is null then -- error 
        NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'GET_URGENTMAIL' ,'not found get_web_url '||sqlerrm,
                      m_rst)   ;      
    end if;

    NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'GET_URGENTMAIL' ,'Refno '||v_refno||' VOUNO='||v_vouno||' user='||v_User||' URL= '||out_url,
                  m_rst)   ;     
                          
    return out_url;
EXCEPTION
    WHEN OTHERS THEN
            NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'GET_URGENTMAIL' ,'error get_web_url '||sqlerrm,
                          m_rst)   ;          
            return  'error get_web_url '||sqlerrm;                                                                            
END GET_URGENTMAIL;
           
FUNCTION GET_BATCHNO(vType IN VARCHAR2) RETURN VARCHAR2 IS -- vType D , B 
    b_no varchar2(20);
    vKey    varchar2(50);
    m_rst   varchar2(100);
BEGIN
    IF nvl(vType , 'D' ) = 'D' THEN
        vKey :=  'CPADRAFT'||to_char(sysdate,'yyyy');  
    ELSIF nvl(vType , 'D' ) = 'GD' THEN
        vKey :=  'GMDRAFT'||to_char(sysdate,'yyyy');  
    ELSIF nvl(vType , 'D' ) = 'GB' THEN
        vKey :=  'CMSBATCH'||to_char(sysdate,'yyyy');      
    ELSE
        vKey :=  'CPABATCH'||to_char(sysdate,'yyyy');  
    END IF;
        
    BEGIN
        select run_no+1 into b_no
        from clm_control_std
        where key = vKey;  
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            b_no := null;
            return null;  
            NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'GET_BATCHNO' ,'not found key! :: '||vkey,
                              m_rst)   ; 
        WHEN OTHERs THEN    
            NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'GET_BATCHNO' ,'error key! :: '||vkey||' '||sqlerrm,
                              m_rst)   ; 
            return null;          
    END;    
        
    UPDATE clm_control_std
    set run_no = b_no
    WHERE key = vKey;  
    commit;
        
    return b_no;
EXCEPTION 
    WHEN OTHERs THEN
    return null;      
END GET_BATCHNO;    

FUNCTION CHECK_HASBATCH(P_DRAFTNO  IN VARCHAR2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS -- false = not success 
    v_draft varchar2(20);
    isFound    boolean:= false;
BEGIN    
    BEGIN
        SELECT max(b.draft_no) into v_draft
        FROM mis_clm_paid a, clm_batch_tmp b
        WHERE a.clm_no = b.clm_no 
        and a.pay_no = b.pay_no              
--        and b.clm_men = :enter_blk.clm_men and b.payee_code = :enter_blk.payee
--        and b.pay_no in  (
--        select pay_no from  MED_DRAFT_TMP xx
--        where xx.VSID = vSID
--        )  
        and draft_no = P_DRAFTNO
        and b.batch_no is null 
        and print_type = '0'
        and a.corr_seq in (select max(v.corr_seq) from mis_clm_paid v where v.pay_no = a.pay_no)
        and b.prod_type ='001'
        and rownum=1 ;
        
        if v_draft is not null then
            isFound := true;    
        end if;
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
            isFound := false;    
            P_RST := 'ไม่พบข้อมูลสร้าง Batch' ;
            --display_proc('ไม่พบข้อมูลสร้าง Batch' );   
            --raise form_trigger_failure;             
    WHEN OTHERS THEN
            isFound := false;      
            P_RST :=   ('error on CHECK_HASBATCH: '||sqlerrm );   
            --display_proc('error on CHECK_HASBATCH: '||sqlerrm );   
            --raise form_trigger_failure; 
    END;
    return isFound;
END CHECK_HASBATCH;

FUNCTION CHECK_HASBATCH_GM(P_DRAFTNO  IN VARCHAR2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS -- false = not success 
    v_draft varchar2(20);
    isFound    boolean:= false;
BEGIN    
    BEGIN
        
        SELECT max(b.draft_no) into v_draft
        FROM mis_clmgm_paid a, clmgm_batch_tmp b
        WHERE a.clm_no = b.clm_no and a.pay_no = b.pay_no
        and b.draft_no = P_DRAFTNO
        and print_type = '0' and b.batch_no is null 
        and a.corr_seq in (select max(v.corr_seq) from mis_clmgm_paid v where v.pay_no = a.pay_no)
        and rownum=1 ;   
        
        if v_draft is not null then
            isFound := true;    
        end if;
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
            isFound := false;    
            P_RST := 'ไม่พบข้อมูลสร้าง Batch' ;
            --display_proc('ไม่พบข้อมูลสร้าง Batch' );   
            --raise form_trigger_failure;             
    WHEN OTHERS THEN
            isFound := false;      
            P_RST :=   ('error on CHECK_HASBATCH: '||sqlerrm );   
            --display_proc('error on CHECK_HASBATCH: '||sqlerrm );   
            --raise form_trigger_failure; 
    END;
    return isFound;
END CHECK_HASBATCH_GM;

FUNCTION CHECK_DRAFT(vSID in number) RETURN VARCHAR2 IS
    v_draft varchar2(20);
    isFound    varchar2(2);
BEGIN    

    BEGIN
        SELECT distinct a.clm_no into v_draft
        FROM mis_clm_paid b, clm_batch_tmp a
        WHERE a.clm_no = b.clm_no 
    and b.pay_no in  (
        select pay_no from  MED_DRAFT_TMP b
        where B.VSID = vSID
        )
    and a.pay_no = b.pay_no                 
        AND b.print_type ='0'
        AND a.prod_type = '001'
        AND a.batch_no is null AND rownum=1 ;
        
    if v_draft is not null then
        isFound := 'D';    
        return isFound;
    end if;

    isFound := 'N';
           
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
            isFound := 'N';    
    WHEN OTHERS THEN
            isFound := 'N';         
            dbms_output.put_line('error on CHECK_DRAFT1: '||sqlerrm );    
    END;

    BEGIN
        select min(a.clm_no) into v_draft 
        from mis_clm_paid a, mis_clm_payee b ,mis_clm_mas c
        where a.clm_no = b.clm_no and b.clm_no = c.clm_no 
    and b.pay_no in  (
        select pay_no from  MED_DRAFT_TMP x
        where x.VSID = vSID
        )
     and a.pay_no = b.pay_no           
        and a.print_type is null and a.pay_date is null
        and pay_seq in (select max(e.pay_seq) from mis_clm_payee e where e.pay_no = b.pay_no )
        and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
                        where b.pay_no = a.pay_no
                        group by b.pay_no)                
        AND rownum=1 ;
        
    if v_draft is not null then
        isFound := 'N';    
        return isFound;
    end if;

    isFound := 'N';
           
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
            isFound := 'N';    
    WHEN TOO_MANY_ROWS THEN
            isFound := 'N';               
    WHEN OTHERS THEN
            isFound := 'N';         
            dbms_output.put_line('error on CHECK_DRAFT2: '||sqlerrm );    
    END;
  
    BEGIN   
         SELECT distinct a.clm_no into v_draft
        FROM mis_clm_paid b, clm_batch_tmp a
        WHERE a.clm_no = b.clm_no 
    and b.pay_no in  (
        select pay_no from  MED_DRAFT_TMP x
        where x.VSID = vSID
        )
    and a.pay_no = b.pay_no         
        AND b.print_type ='1'
        AND a.prod_type = '001'
        AND a.batch_no is not null AND rownum=1 ;

    if v_draft is not null then
        isFound := 'B';    
        return isFound;
    end if;        
    
    isFound := 'N';
           
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
            isFound := 'N';    
    WHEN OTHERS THEN
            isFound := 'N';         
            dbms_output.put_line('error on CHECK_DRAFT3: '||sqlerrm );    
    END;
/*  */    
    return isFound;
END CHECK_DRAFT;

FUNCTION CHECK_DRAFT_GM(vSID in number) RETURN VARCHAR2 IS
    v_draft varchar2(20);
    isFound    varchar2(2);
BEGIN    

    BEGIN
        SELECT distinct a.clm_no into v_draft
        FROM mis_clmgm_paid b, clmgm_batch_tmp a
        WHERE a.clm_no = b.clm_no 
    and b.pay_no in  (
        select pay_no from  MED_DRAFT_TMP b
        where B.VSID = vSID
        )
    and a.pay_no = b.pay_no                 
        AND b.print_type ='0'
--        AND a.prod_type = '001'
        AND a.batch_no is null AND rownum=1 ;
        
    if v_draft is not null then
        isFound := 'D';    
        return isFound;
    end if;

    isFound := 'N';
           
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
            isFound := 'N';    
    WHEN OTHERS THEN
            isFound := 'N';         
            dbms_output.put_line('error on CHECK_DRAFT1: '||sqlerrm );    
    END;

    BEGIN
        select min(a.clm_no) into v_draft 
        from mis_clmgm_paid a, clm_gm_payee b ,mis_clm_mas c
        where a.clm_no = b.clm_no and b.clm_no = c.clm_no 
        and a.print_type is null and a.pay_date is null
        and pay_seq = (select max(e.pay_seq) from clm_gm_payee e where e.pay_no = b.pay_no )
        and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from mis_clmgm_paid b
                        where b.clm_no = a.clm_no
                        group by b.clm_no)                
        and b.pay_no in  (
        select pay_no from  MED_DRAFT_TMP x
        where x.VSID = vSID
        )
        AND rownum=1 ;        
        
    if v_draft is not null then
        isFound := 'N';    
        return isFound;
    end if;

    isFound := 'N';
           
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
            isFound := 'N';    
    WHEN TOO_MANY_ROWS THEN
            isFound := 'N';               
    WHEN OTHERS THEN
            isFound := 'N';         
            dbms_output.put_line('error on CHECK_DRAFT2: '||sqlerrm );    
    END;
  
    BEGIN          
        SELECT distinct a.clm_no into v_draft
        FROM mis_clmgm_paid b, clmgm_batch_tmp a
        WHERE a.clm_no = b.clm_no 
        and b.pay_no in  (
            select pay_no from  MED_DRAFT_TMP x
            where x.VSID = vSID
        )
        AND b.print_type ='1'
        AND a.batch_no is not null AND rownum=1 ;        

    if v_draft is not null then
        isFound := 'B';    
        return isFound;
    end if;        
    
    isFound := 'N';
           
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
            isFound := 'N';    
    WHEN OTHERS THEN
            isFound := 'N';         
            dbms_output.put_line('error on CHECK_DRAFT3: '||sqlerrm );    
    END;
/*  */    
    return isFound;
END CHECK_DRAFT_GM;

FUNCTION CHECK_PENDING_APPRV(vSID in NUMBER) RETURN VARCHAR2 IS -- N คือ ไม่พบงานรออนุมัติ
    v_draft varchar2(20);
    isFound    varchar2(2);
BEGIN    
    BEGIN
        select 'found-new' f1 into v_draft
        from nc_payment xxx
        where 
        xxx.pay_sts in ('NCPAYSTS02','NCPAYSTS07') and  
        xxx.trn_seq = (select max(b.trn_seq) from nc_payment b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no) and   
        xxx.pay_no in (
        select pay_no from  MED_DRAFT_TMP x
        where x.VSID = vSID
        ) and rownum=1 ;
        
    if v_draft is not null then
        isFound := 'Y';    
        return isFound;
    end if;

    isFound := 'N';
           
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
            isFound := 'N';    
    WHEN OTHERS THEN
            isFound := 'N';         
            dbms_output.put_line('error on CHECK_FOUNDNEW: '||sqlerrm );    
    END;

    return isFound;
END CHECK_PENDING_APPRV;

FUNCTION GEN_DRAFT(qry_str IN  LONG , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 IS -- null สำเร็จ
--**** byPass Cursor from 6i 
    TMP_C   NC_HEALTH_PACKAGE.v_ref_cursor1;   
    m_rst   VARCHAR2(200);
BEGIN
    GEN_CURSOR(qry_str ,TMP_C );
    m_rst := GEN_DRAFT(TMP_C , P_DRAFTNO) ;
    
    return m_rst;
END GEN_DRAFT;    

FUNCTION GEN_DRAFT(P_DATA  IN v_ref_cursor1 , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 IS
    c1   NC_HEALTH_PACKAGE.v_ref_cursor1;      

    TYPE t_data1 IS RECORD
    (
    STS_KEY    NUMBER,
    CLM_NO  VARCHAR2(20),
    PAY_NO  VARCHAR2(20),
    REF_NO   VARCHAR2(20),
    PAYEE_CODE  VARCHAR2(20)
    ); 
    r1 t_data1;     

--***
    v_pay_no    varchar2(20);
    v_CORR_SEQ NUMBER (2) ;
    v_PAY_DATE DATE ;
    v_PAY_AMT    NUMBER;
    v_REC_AMT    NUMBER;
    v_DEDUCT_AMT NUMBER    ;
    v_RES_AMT   NUMBER;
    v_TITLE     VARCHAR (15) ;
    v_NAME      VARCHAR (60) ;
    v_FR_DATE   DATE ;
    v_TO_DATE   DATE ;
    v_LOSS_DATE DATE     ;
    v_ADV_AMT number;    
    V_GM_PAY number;
    V_TOTAL_PAY number;
    V_TOTAL_REC number;    
    V_PROD_GRP  VARCHAR (10) ;
--***        
    vRST    VARCHAR2(200);
    m_rst    VARCHAR2(200);
    dummy_drf   VARCHAR2(10);
    dummy_fnew  VARCHAR2(10);
    M_DRAFTNO   VARCHAR2(20);
    M_REFNO   VARCHAR2(20);
    v_SID    NUMBER:= NC_HEALTH_PACKAGE.GEN_SID;
BEGIN

    dbms_output.put_line('vSID='||v_SID);
    LOOP  -- นำข้อมูลมาสร้าง Draft 
       FETCH  P_DATA INTO r1;
        EXIT WHEN P_DATA%NOTFOUND;
            dbms_output.put_line('ref: '||r1.ref_no
            ||' clm_no: '||r1.clm_no
            ||' pay_no: '||r1.pay_no);
            if r1.ref_no is null or r1.clm_no is null  or r1.pay_no is null  or r1.payee_code is null  then
                vRST := 'ข้อมูลที่ทำ Draft ไม่สมบูรณ์' ;
                NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'GEN_DRAFT' ,vRST,
                              m_rst)   ;      
            end if;     
            INSERT INTO ALLCLM.MED_DRAFT_TMP
            ( VSID , REF_NO   , CLM_NO , STS_KEY , PAYEE_CODE ,PAY_NO )   VALUES
            ( v_SID ,r1.ref_no ,r1.clm_no ,r1.sts_key ,r1.payee_code , r1.pay_no)  ;      
            M_REFNO := r1.REF_NO ;                        
    END LOOP;     
               
    IF vRST is not null THEN
        ROLLBACK;
        return vRST;    
    ELSE
        COMMIT;  --** Submit MED_DRAFT_TMP 
    END IF; 
    --*** pass validate null INPUT
    
    --*** Validate Payment 
    dummy_drf := CHECK_DRAFT('');
    if dummy_drf = 'D' then    -- Case Batch Print
        vRST := ('พิมพ์ Draft แล้ว ต้องเคลียร์ Draft ก่อน!');
    elsif dummy_drf = 'B' then    
        vRST := ('พิมพ์ BATCH แล้ว ไม่สามารถเรียก Draft ได้!');       
    elsif dummy_drf = 'N' then    
          dummy_fnew := CHECK_PENDING_APPRV(''); -- check payment waiting for approve
          if dummy_fnew = 'Y' then
                vRST := ('พบเลขจ่ายในข้อมูลชุดนี้ มีการขออนุมัติวงเงินอยู่ ไม่สามารถพิมพ์ Draft ได้ !');                      
          elsif dummy_fnew = 'N' then
                vRST := null ;    /* success */
            end if;
    end if;       
    
    IF vRST is not null THEN
        ROLLBACK;
        return vRST;    
    END IF;        
    --**** * ** * ** * *  *
    
    -- *** gen Draft *******
    M_DRAFTNO := GET_BATCHNO('D');
    for p1 in (select  b.clm_no ,'' advance_no ,c.pol_no ,c.pol_run ,c.clm_men ,c.mas_cus_enq , b.payee_code ,b.pay_no ,c.prod_type
            from mis_clm_paid a, mis_clm_payee b ,mis_clm_mas c ,mis_clm_mas_seq d
            where a.clm_no = b.clm_no and b.clm_no = c.clm_no and c.clm_no = d.clm_no 
            and d.corr_seq in (select max(x.corr_seq) from mis_clm_mas_seq x where  x.clm_no = d.clm_no)  
            and a.pay_no = b.pay_no
            and a.pay_no in (
                    select yy.pay_no
                    from MED_DRAFT_TMP yy   where vSID = v_SID
            )                                     
            and a.print_type is null and a.pay_date is null
            and c.clm_sts in ('6','7') and d.close_date is null
      and pay_seq in (select max(e.pay_seq) from mis_clm_payee e where e.pay_no = b.pay_no )
      and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
                      where b.pay_no = a.pay_no
                      group by b.pay_no)                
            and a.pay_total >0
            and a.pay_no not like '01'||substr(A.CLM_NO,7,3)||'%'
            order by b.clm_no desc)
    loop       
    
        for p2 in (select pay_no ,corr_seq ,pay_date ,pay_total ,0 rec_total
            from mis_clm_paid a 
            where a.clm_no = p1.clm_no
            and a.pay_no =   p1.pay_no       
            and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no) )                
        loop
            v_pay_no := p2.pay_no;
            v_CORR_SEQ := p2.corr_seq;
            v_PAY_DATE := p2.pay_date;            
            V_TOTAL_PAY := p2.pay_total;
            V_TOTAL_REC := nvl(p2.rec_total,0);
        end loop;
        
        for p3 in (select sum(pay_total) pay_amt ,sum(0) rec_amt ,sum(0) deduct_amt
            from mis_clm_paid a
            where a.clm_no = p1.clm_no
            and a.pay_no = p1.pay_no                
            and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no) )                    
        loop
            V_GM_PAY := p3.pay_amt;
            v_REC_AMT := p3.rec_amt;
            v_DEDUCT_AMT := p3.deduct_amt;            
        end loop;
        
        if v_DEDUCT_AMT is not null or v_DEDUCT_AMT > 0 then
            v_DEDUCT_AMT := v_DEDUCT_AMT;    
        end if;    
        
        begin
            select payee_amt into v_PAY_AMT
            from mis_clm_payee
            where clm_no = p1.clm_no
            and pay_no = p1.pay_no
            and pay_seq in (select max(b.pay_seq) from mis_clm_payee b where b.clm_no = p1.clm_no    and b.pay_no = p1.pay_no);
        exception
            when no_data_found then
            v_PAY_AMT := null;
            when others then
            v_PAY_AMT := null;
        end;        
        
        for p4 in (select tot_res res_amt ,'' title ,loss_name name ,fr_date ,to_date ,b.loss_date ,prod_grp 
                from mis_clm_mas a ,mis_cpa_res b
                where a.clm_no = b.clm_no 
                and a.clm_no = p1.clm_no
                and b.res_seq in (select max(z.res_seq) from mis_cpa_res z where z.clm_no = b.clm_no) )        
        loop
            v_RES_AMT := p4.res_amt;
            v_TITLE := p4.title;
            v_NAME  := p4.name;
            v_FR_DATE := p4.fr_date;
            v_TO_DATE := p4.to_date;
            v_LOSS_DATE := p4.loss_date;            
            V_PROD_GRP := p4.prod_grp;
        end loop;        
        
        v_ADV_AMT := nvl(v_PAY_AMT,0) - (nvl(V_GM_PAY,0) -nvl(v_REC_AMT,0)) - nvl(v_DEDUCT_AMT,0);

        begin
            Insert into clm_batch_tmp
               (BATCH_NO, CLM_NO, PAY_NO, CORR_SEQ, PAID_DATE, P_VOU_NO, P_VOU_DATE, ADVANCE_NO, POL_NO, POL_RUN
               , PAYEE_CODE, CLM_MEN, CUS_ENQ, TITLE, NAME, FR_DATE, TO_DATE, LOSS_DATE
               , RES_AMT, PAY_AMT, ADV_AMT ,DEDUCT_AMT ,PROD_TYPE
               , REF_NO , DRAFT_NO ,REAL_PROD_TYPE ,PROD_GRP
               )
             Values
               (null, p1.clm_no, v_pay_no, v_CORR_SEQ, v_PAY_DATE, null, null, p1.advance_no, p1.pol_no, p1.pol_run
               , p1.payee_code, p1.clm_men, p1.mas_cus_enq, v_TITLE, v_NAME, v_FR_DATE, v_TO_DATE, v_LOSS_DATE
               , v_RES_AMT, v_PAY_AMT, v_ADV_AMT ,v_DEDUCT_AMT ,'001'
               ,M_REFNO ,M_DRAFTNO ,p1.prod_type ,V_PROD_GRP
               );
               
            update mis_clm_paid a
            set print_type = '0' 
            where a.clm_no = p1.clm_no
            and pay_no = p1.pay_no
            and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no)    ;
        exception
            when others then
            --rollback; raise form_trigger_failure;
            vRST := 'error Script Draft :'||sqlerrm; 
        end;
        
    end loop;        
    -- *** * END gen draft * *  * *
    
    --**** Final Step ****
    IF vRST is not null THEN
        ROLLBACK;
        DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
        COMMIT;        
        return vRST;    
    ELSE
        P_DRAFTNO := M_DRAFTNO;
        DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
        COMMIT;
    END IF; 
        
    return vRST;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
    COMMIT;    
    return 'error main GEN_DRAFT: '||sqlerrm ;    
END GEN_DRAFT;

FUNCTION GEN_DRAFT_GM(qry_str IN  LONG , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 IS -- null สำเร็จ
--**** byPass Cursor from 6i 
    TMP_C   NC_HEALTH_PACKAGE.v_ref_cursor1;   
    m_rst   VARCHAR2(200);
BEGIN
    GEN_CURSOR(qry_str ,TMP_C );
    m_rst := GEN_DRAFT_GM(TMP_C , P_DRAFTNO) ;
    
    return m_rst;
END GEN_DRAFT_GM;    

FUNCTION GEN_DRAFT_GM(P_DATA  IN v_ref_cursor1 , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 IS
    c1   NC_HEALTH_PACKAGE.v_ref_cursor1;      

    TYPE t_data1 IS RECORD
    (
    STS_KEY    NUMBER,
    CLM_NO  VARCHAR2(20),
    PAY_NO  VARCHAR2(20),
    REF_NO   VARCHAR2(20),
    PAYEE_CODE  VARCHAR2(20)
    ); 
    r1 t_data1;     

--***
    v_pay_no    varchar2(20);
    v_CORR_SEQ NUMBER (2) ;
    v_PAY_DATE DATE ;
    v_PAY_AMT    NUMBER;
    v_REC_AMT    NUMBER;
    v_DEDUCT_AMT NUMBER    ;
    v_RES_AMT   NUMBER;
    v_TITLE     VARCHAR (15) ;
    v_NAME      VARCHAR (60) ;
    v_FR_DATE   DATE ;
    v_TO_DATE   DATE ;
    v_LOSS_DATE DATE     ;
    v_ADV_AMT number;    
    V_GM_PAY number;
    V_TOTAL_PAY number;
    V_TOTAL_REC number;    
    V_PROD_GRP  VARCHAR (10):='0' ;
--***        
    vRST    VARCHAR2(200);
    m_rst    VARCHAR2(200);
    dummy_drf   VARCHAR2(10);
    dummy_fnew  VARCHAR2(10);
    M_DRAFTNO   VARCHAR2(20);
    M_REFNO   VARCHAR2(20);
    v_SID    NUMBER:= NC_HEALTH_PACKAGE.GEN_SID;
BEGIN

    dbms_output.put_line('vSID='||v_SID);
    LOOP  -- นำข้อมูลมาสร้าง Draft 
       FETCH  P_DATA INTO r1;
        EXIT WHEN P_DATA%NOTFOUND;
            dbms_output.put_line('ref: '||r1.ref_no
            ||' clm_no: '||r1.clm_no
            ||' pay_no: '||r1.pay_no);
            if r1.ref_no is null or r1.clm_no is null  or r1.pay_no is null  or r1.payee_code is null  then
                vRST := 'ข้อมูลที่ทำ Draft ไม่สมบูรณ์' ;
                NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'GEN_DRAFT' ,vRST,
                              m_rst)   ;      
            end if;     
            INSERT INTO ALLCLM.MED_DRAFT_TMP
            ( VSID , REF_NO   , CLM_NO , STS_KEY , PAYEE_CODE ,PAY_NO )   VALUES
            ( v_SID ,r1.ref_no ,r1.clm_no ,r1.sts_key ,r1.payee_code , r1.pay_no)  ;      
            M_REFNO := r1.REF_NO ;                        
    END LOOP;     
               
    IF vRST is not null THEN
        ROLLBACK;
        return vRST;    
    ELSE
        COMMIT;  --** Submit MED_DRAFT_TMP 
    END IF; 
    --*** pass validate null INPUT
    
    --*** Validate Payment 
    dummy_drf := CHECK_DRAFT_GM('');
    if dummy_drf = 'D' then    -- Case Batch Print
        vRST := ('พิมพ์ Draft แล้ว ต้องเคลียร์ Draft ก่อน!');
    elsif dummy_drf = 'B' then    
        vRST := ('พิมพ์ BATCH แล้ว ไม่สามารถเรียก Draft ได้!');       
    elsif dummy_drf = 'N' then    
          dummy_fnew := CHECK_PENDING_APPRV(''); -- check payment waiting for approve
          if dummy_fnew = 'Y' then
                vRST := ('พบเลขจ่ายในข้อมูลชุดนี้ มีการขออนุมัติวงเงินอยู่ ไม่สามารถพิมพ์ Draft ได้ !');                      
          elsif dummy_fnew = 'N' then
                vRST := null ;    /* success */
            end if;
    end if;       
    
    IF vRST is not null THEN
        ROLLBACK;
        return vRST;    
    END IF;        
    --**** * ** * ** * *  *
    
    -- *** gen Draft *******
    M_DRAFTNO := GET_BATCHNO('GD');
    for p1 in (select  b.clm_no ,'' advance_no ,c.pol_no ,c.pol_run ,c.clm_men ,c.mas_cus_enq ,replace(b.payee_code,' ','') payee_code ,b.pay_no ,c.prod_type
            from mis_clmgm_paid a, clm_gm_payee b ,mis_clm_mas c
            where a.clm_no = b.clm_no and b.clm_no = c.clm_no 
            and a.print_type is null and a.pay_date is null
            and c.clm_sts = '6' and c.close_date is null
      and pay_seq = (select max(e.pay_seq) from clm_gm_payee e where e.pay_no = b.pay_no )
      and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from mis_clmgm_paid b
                      where b.clm_no = a.clm_no
                      group by b.clm_no)                
            and a.pay_no in (
                    select yy.pay_no
                    from MED_DRAFT_TMP yy   where vSID = v_SID
            )    
            and a.pay_total >0
            and a.pay_no not like '01'||c.prod_type||'%'
            order by b.clm_no desc)            
    loop       
    
        for p2 in (select pay_no ,corr_seq ,pay_date ,pay_total ,rec_total
            from mis_clmgm_paid a where a.clm_no = p1.clm_no
            and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from mis_clmgm_paid b
            where b.clm_no = a.clm_no
            group by b.clm_no) )        
        loop
            v_pay_no := p2.pay_no;
            v_CORR_SEQ := p2.corr_seq;
            v_PAY_DATE := p2.pay_date;            
            V_TOTAL_PAY := p2.pay_total;
            V_TOTAL_REC := nvl(p2.rec_total,0);
        end loop;
    
        for p3 in (select sum(pay_amt) pay_amt ,sum(rec_amt) rec_amt ,sum(deduct_amt) deduct_amt
            from clm_gm_paid a
            where a.clm_no = p1.clm_no
            and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from clm_gm_paid b
            where b.clm_no = a.clm_no
            group by b.clm_no) )        
        loop
            V_GM_PAY := p3.pay_amt;
            v_REC_AMT := p3.rec_amt;
            v_DEDUCT_AMT := p3.deduct_amt;            
        end loop;
        
        if v_DEDUCT_AMT is not null or v_DEDUCT_AMT > 0 then
            v_DEDUCT_AMT := v_DEDUCT_AMT;    
        end if;    
        
        begin
            select payee_amt into v_PAY_AMT
            from clm_gm_payee
            where clm_no = p1.clm_no
            and pay_no = p1.pay_no
            and pay_seq = (select max(b.pay_seq) from clm_gm_payee b where b.clm_no = p1.clm_no    and b.pay_no = p1.pay_no);
        exception
            when no_data_found then
            v_PAY_AMT := null;
            when others then
            v_PAY_AMT := null;
        end;        
        
        for p4 in (select sum(res_amt) res_amt ,max(title) title ,max(name) name ,max(fr_date) fr_date ,max(to_date) to_date ,max(loss_date) loss_date
                from clm_medical_res a 
                where a.clm_no = p1.clm_no
                and  (a.state_no,a.state_seq) = (select b.state_no,max(b.state_seq) from clm_medical_res b
                where b.clm_no = a.clm_no and b.state_no = a.state_no
                group by b.state_no) )        
        loop
            v_RES_AMT := p4.res_amt;
            v_TITLE := p4.title;
            v_NAME  := p4.name;
            v_FR_DATE := p4.fr_date;
            v_TO_DATE := p4.to_date;
            v_LOSS_DATE := p4.loss_date;            
        end loop;        
        
        v_ADV_AMT := nvl(v_PAY_AMT,0) - (nvl(V_GM_PAY,0) -nvl(v_REC_AMT,0)) - nvl(v_DEDUCT_AMT,0);

        begin
            Insert into clmgm_batch_tmp
               (BATCH_NO, CLM_NO, PAY_NO, CORR_SEQ, PAID_DATE, P_VOU_NO, P_VOU_DATE, ADVANCE_NO, POL_NO, POL_RUN
               , PAYEE_CODE, CLM_MEN, CUS_ENQ, TITLE, NAME, FR_DATE, TO_DATE, LOSS_DATE
               , RES_AMT, PAY_AMT, ADV_AMT ,DEDUCT_AMT
               , REF_NO , DRAFT_NO ,REAL_PROD_TYPE ,PROD_GRP)
             Values
               (null, p1.clm_no, v_pay_no, v_CORR_SEQ, v_PAY_DATE, null, null, p1.advance_no, p1.pol_no, p1.pol_run
               , p1.payee_code, p1.clm_men, p1.mas_cus_enq, v_TITLE, v_NAME, v_FR_DATE, v_TO_DATE, v_LOSS_DATE
               , v_RES_AMT, v_PAY_AMT, v_ADV_AMT ,v_DEDUCT_AMT
               ,M_REFNO ,M_DRAFTNO ,p1.prod_type ,V_PROD_GRP);
               
            update mis_clmgm_paid a
            set print_type = '0' 
            where a.clm_no = p1.clm_no
            and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from mis_clmgm_paid b
            where b.clm_no = a.clm_no
            group by b.clm_no)    ;
        exception
            when others then
--            rollback; raise form_trigger_failure;
            vRST := 'error Script Draft :'||sqlerrm; 
        end;
    end loop;          
    -- *** * END gen draft * *  * *
    
    --**** Final Step ****
    IF vRST is not null THEN
        ROLLBACK;
        DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
        COMMIT;        
        return vRST;    
    ELSE
        P_DRAFTNO := M_DRAFTNO;
        DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
        COMMIT;
    END IF; 
        
    return vRST;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
    COMMIT;    
    return 'error main GEN_DRAFT: '||sqlerrm ;    
END GEN_DRAFT_GM;

FUNCTION GEN_BATCH(P_DRAFTNO  IN VARCHAR2 , V_USER_ID IN VARCHAR2 , P_BATCHNO OUT VARCHAR2 , P_BATCHNO2 OUT VARCHAR2) RETURN VARCHAR2 IS -- null สำเร็จ    
    m_hasbatch  BOOLEAN;
    m_rst_hasbatch  VARCHAR2(200);
    m_groupbatch VARCHAR2(200);
    m_rst_groupbatch   VARCHAR2(10);   
    m_rst_scriptbatch  VARCHAR2(200);
BEGIN
    m_hasbatch :=  CHECK_HASBATCH(P_DRAFTNO ,m_rst_hasbatch) ; -- false = not success 
    dbms_output.put_line('m_rst_hasbatch='||m_rst_hasbatch);
    if not m_hasbatch then -- check has Draft Data?
        return m_rst_hasbatch;
    end if;
    m_groupbatch := GROUP_BATCHNO(P_DRAFTNO ,m_rst_groupbatch /* Y , N*/ ) ; -- null success
    dbms_output.put_line('m_groupbatch='||m_groupbatch||' rst='||m_rst_groupbatch);
    if m_groupbatch is not null then
         return m_groupbatch;
    end if; 
    
    m_rst_scriptbatch := SCRIPT_BATCH(P_DRAFTNO , V_USER_ID ,m_rst_groupbatch ,P_BATCHNO  , P_BATCHNO2) ;
    
    return m_rst_scriptbatch;
END GEN_BATCH;

FUNCTION GEN_BATCH_GM(P_DRAFTNO  IN VARCHAR2 , V_USER_ID IN VARCHAR2 , P_BATCHNO OUT VARCHAR2 , P_BATCHNO2 OUT VARCHAR2) RETURN VARCHAR2 IS -- null สำเร็จ    
    m_hasbatch  BOOLEAN;
    m_rst_hasbatch  VARCHAR2(200);
    m_groupbatch VARCHAR2(200);
    m_rst_groupbatch   VARCHAR2(10);   
    m_rst_scriptbatch  VARCHAR2(200);
BEGIN
    m_hasbatch :=  CHECK_HASBATCH_GM(P_DRAFTNO ,m_rst_hasbatch) ; -- false = not success 
    dbms_output.put_line('m_rst_hasbatch='||m_rst_hasbatch);
    if not m_hasbatch then -- check has Draft Data?
        return m_rst_hasbatch;
    end if;
    m_groupbatch := GROUP_BATCHNO_GM(P_DRAFTNO ,m_rst_groupbatch /* Y , N*/ ) ; -- null success
    dbms_output.put_line('m_groupbatch='||m_groupbatch||' rst='||m_rst_groupbatch);
    if m_groupbatch is not null then
         return m_groupbatch;
    end if; 
    
    m_rst_scriptbatch := SCRIPT_BATCH_GM(P_DRAFTNO , V_USER_ID ,m_rst_groupbatch ,P_BATCHNO  , P_BATCHNO2) ;
    
    return m_rst_scriptbatch;
END GEN_BATCH_GM;

FUNCTION GROUP_BATCHNO(P_DRAFTNO  IN VARCHAR2, P_RST OUT VARCHAR2) RETURN VARCHAR2 IS 
-- P_RST Y many batch , N single ::: Result null success
    V_VOUNO varchar2(15);
    V_VOUDATE    date;
    has_v    boolean:=false;
    no_v    boolean:=false;
    v_cnt number:=0;
BEGIN
    for p1 in (
    select clm_no ,pol_no ,pol_run ,prod_grp ,real_prod_type prod_type ,pay_no
    from clm_batch_tmp a
    where draft_no = P_DRAFTNO
     )            
    loop       
        
            p_acc_claim.get_ar_voucher (p1.pol_no ,
            
                                         p1.pol_run ,
             
                                         p1.prod_grp ,
            
                                         V_VOUNO ,
            
                                         V_VOUDATE );        
            
            if V_VOUNO is null then no_v:= true; end if;
            if V_VOUNO is not null then has_v:= true; end if;
            
            BEGIN
                UPDATE clm_batch_tmp
                SET AR_VOU_NO = V_VOUNO
                ,AR_VOU_DATE = V_VOUDATE
                WHERE DRAFT_NO = P_DRAFTNO
                AND PAY_NO = P1.PAY_NO ;
            EXCEPTION
                WHEN Others Then
                ROLLBACK;
                RETURN 'error update AR_VOUNO :'||sqlerrm ;
            END ;
        v_cnt := v_cnt+1;            
    end loop;    
    
    if v_cnt = 0 then
        RETURN 'ไม่พบข้อมูลสร้าง BATCH' ;
    end if;
    
    if no_v and has_v then
        P_RST := 'Y';
    else
        P_RST := 'N';
    end if;
    COMMIT;
    return null;
END GROUP_BATCHNO;

FUNCTION GROUP_BATCHNO_GM(P_DRAFTNO  IN VARCHAR2, P_RST OUT VARCHAR2) RETURN VARCHAR2 IS 
-- P_RST Y many batch , N single ::: Result null success
    V_VOUNO varchar2(15);
    V_VOUDATE    date;
    has_v    boolean:=false;
    no_v    boolean:=false;
    v_cnt number:=0;
BEGIN
    for p1 in (
    select clm_no ,pol_no ,pol_run ,prod_grp ,real_prod_type prod_type ,pay_no
    from clmgm_batch_tmp a
    where draft_no = P_DRAFTNO
     )                      
    loop       
        
            p_acc_claim.get_ar_voucher (p1.pol_no ,
            
                                         p1.pol_run ,
             
                                         p1.prod_grp ,
            
                                         V_VOUNO ,
            
                                         V_VOUDATE );        
            
            if V_VOUNO is null then no_v:= true; end if;
            if V_VOUNO is not null then has_v:= true; end if;
            
            BEGIN
                UPDATE clmgm_batch_tmp
                SET AR_VOU_NO = V_VOUNO
                ,AR_VOU_DATE = V_VOUDATE
                WHERE DRAFT_NO = P_DRAFTNO
                AND PAY_NO = P1.PAY_NO ;
            EXCEPTION
                WHEN Others Then
                ROLLBACK;
                RETURN 'error update AR_VOUNO :'||sqlerrm ;
            END ;
        v_cnt := v_cnt+1;            
    end loop;    
    
    if v_cnt = 0 then
        RETURN 'ไม่พบข้อมูลสร้าง BATCH' ;
    end if;
    
    if no_v and has_v then
        P_RST := 'Y';
    else
        P_RST := 'N';
    end if;
    COMMIT;
    return null;
END GROUP_BATCHNO_GM;

FUNCTION SCRIPT_BATCH(P_DRAFTNO  IN VARCHAR2 , V_USER_ID IN VARCHAR2 ,P_MANY IN VARCHAR2 ,P_BATCHNO OUT VARCHAR2  , P_BATCHNO2 OUT VARCHAR2) RETURN VARCHAR2 IS
    cnt number;
--    double_b    boolean:=false;
    V_RESULT varchar2(100);
    V_RESULT2 varchar2(100);    
    V_RESULT3 varchar2(100);        
    b1    varchar2(10);
    b2    varchar2(10);    
  inw_type varchar2(1);        
    V_DEPT_ID VARCHAR (2) ;
    V_DIV_ID  VARCHAR (2) ;
    V_TEAM_ID VARCHAR (2);  
    v_DEDUCT_AMT NUMBER    ;        
    V_TITLE      VARCHAR (30) ;
    V_NAME       VARCHAR (120) ;        
    V_PAYEE       VARCHAR (20) ;    
    V_CONTACT       VARCHAR (120) ;
    V_GRP    VARCHAR2(3);
    V_TYPE VARCHAR2(3);
    V_GRP2    VARCHAR2(3);
    V_TYPE2 VARCHAR2(3);    
    V_VOUNO    varchar2(15);
    V_VOUDATE    DATE;    
    v_RES_AMT    number;
    v_ADV_AMT number;    
    v_GM_PAY number;    
    v_REC_TOTAL number;    
    M_SEND_TITLE    varchar2(100);    
    M_SEND_ADDR1  varchar2(200); 
    M_SEND_ADDR2  varchar2(200); 
    M_PAYEE_CODE  varchar2(20); 
    M_PAYEE_NAME  varchar2(200);         
    M_PAY_NO    varchar2(20); 
    V_STATUS_RST     varchar2(200);  
    m_rst   varchar2(200);  
BEGIN
    
    b1 := GET_BATCHNO('B');
    if P_MANY = 'Y' then b2 := GET_BATCHNO('B'); end if;    -- for VoucerBatch

    if P_MANY = 'Y' then    
--        first_record;
        for I1 in (
            select clm_no  ,prod_grp ,real_prod_type prod_type ,ar_vou_no ,pay_no
            from clm_batch_tmp a
            where draft_no = P_DRAFTNO      
        ) loop
            if I1.AR_VOU_NO is not null then
                -- :TMP_BLK.BATCH_NO := b2;
                V_GRP2 := I1.PROD_GRP;
                V_TYPE2 := I1.PROD_TYPE;
                begin 
                   update clm_batch_tmp
                   set batch_no = b2 
                   where draft_no = P_DRAFTNO and pay_no = I1.pay_no ;
                exception                
                when others then
                    rollback ;
                    return 'error I1: '||sqlerrm ;
                end;
            else
                -- :TMP_BLK.BATCH_NO := b1;
                V_GRP :=  I1.PROD_GRP;
                V_TYPE := I1.PROD_TYPE;     
                begin 
                   update clm_batch_tmp
                   set batch_no = b1 
                   where draft_no = P_DRAFTNO and pay_no = I1.pay_no ;
                exception                
                when others then
                    rollback ;
                    return 'error I1: '||sqlerrm ;
                end;                     
            end if;
        end loop;    
    else
        for I2 IN (
            select clm_no  ,prod_grp ,real_prod_type prod_type ,ar_vou_no  ,pay_no
            from clm_batch_tmp a
            where draft_no = P_DRAFTNO              
        ) loop
            -- :TMP_BLK.BATCH_NO := b1;
            V_GRP :=  I2.PROD_GRP;
            V_TYPE := I2.PROD_TYPE;      
            begin 
               update clm_batch_tmp
               set batch_no = b1
               where draft_no = P_DRAFTNO and pay_no = I2.pay_no ;
            exception                
            when others then
                rollback ;
                return 'error I2: '||sqlerrm ;
            end;                            
        end loop;        
    end if;
    
--    :parameter.p_batch1 := b1;    
--    :parameter.p_batch2 := b2;    
    
    --======= Step Insert Data ========
    for i in (
        select clm_no  ,prod_grp ,real_prod_type prod_type ,ar_vou_no  ,pay_no ,BATCH_NO
        from clm_batch_tmp a
        where draft_no = P_DRAFTNO         
    ) loop    -- on round insert data
      
        for c_rec in (select a.clm_no ,a.pol_no ,a.pol_run ,nvl(a.policy_number,a.pol_no||a.pol_run) policy_number ,a.prod_grp ,a.prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,a.channel ,clm_men
                                      from mis_clm_mas a ,mis_clm_mas_seq d
                      where a.clm_no = d.clm_no 
                      and a.clm_no = i.CLM_NO
                        and d.corr_seq in (select max(x.corr_seq) from mis_clm_mas_seq x where  x.clm_no = d.clm_no)                      
                      and a.clm_sts in ('6','7') and d.close_date is null)                   
        loop
            if c_rec.channel = '9' then inw_type := 'Y'; else inw_type := null; end if;    
            begin
                select dept_id ,div_id ,team_id into V_DEPT_ID, V_DIV_ID, V_TEAM_ID
                from bkiuser
                where user_id = c_rec.clm_men;                
            exception
                when no_data_found then
                    V_DEPT_ID:=null;
                    V_DIV_ID :=null;
                    V_TEAM_ID :=null;
                when others then
                    V_DEPT_ID:=null;
                    V_DIV_ID :=null;
                    V_TEAM_ID :=null;
            end;
            
            for p1 in (select a.pay_no ,pay_seq ,pay_date ,payee_amt ,pay_total  ,0 rec_total ,0 disc_total ,payee_code ,a.settle 
            ,a.bank_code ,a.bank_br_code ,a.acc_no ,a.acc_name
                       from mis_clm_paid a, mis_clm_payee b
                                where a.clm_no = b.clm_no
                                and b.pay_no = a.pay_no
                and pay_seq in (select max(e.pay_seq) from mis_clm_payee e where e.pay_no = b.pay_no )
                and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
                                where b.pay_no = a.pay_no
                                group by b.pay_no)                                  
                                and a.clm_no = c_rec.clm_no
                                )            
            loop             
                M_PAYEE_CODE := P1.PAYEE_CODE ;
                M_PAY_NO := P1.PAY_NO;
                
                P_CLAIM_ACR.Post_acc_clm_tmp(    c_rec.prod_grp /*P_prod_grp IN   acc_clm_tmp.prod_grp%type*/,
    
                            c_rec.prod_type /* P_prod_type IN  acc_clm_tmp.prod_type%type */,
    
                            p1.pay_no /* P_payno   IN  acc_clm_tmp.payment_no%type */,
    
                            trunc(sysdate) /* P_appoint_date IN  acc_clm_tmp.appoint_date%type */,
    
                            c_rec.clm_no /* P_clmno   IN  acc_clm_tmp.clm_no%type */,
    
                            c_rec.pol_no /* P_polno   IN  acc_clm_tmp.pol_no%type */,
    
                            c_rec.pol_run /* P_polrun  IN  acc_clm_tmp.pol_run%type */,
    
                            c_rec.policy_number /* P_polnum  IN  acc_clm_tmp.policy_number%type */,
    
                            c_rec.pol_no||c_rec.pol_run /* P_polref  IN  acc_clm_tmp.pol_ref%type */,          
    
                            c_rec.cus_code /* P_cuscode IN  acc_clm_tmp.cus_code%type */,
    
                            c_rec.th_eng /* P_th_eng IN  acc_clm_tmp.th_eng%type */,
    
                            c_rec.agent_code /* P_agent_code IN  acc_clm_tmp.agent_code%type */,
    
                            c_rec.agent_seq /* P_agent_seq IN  acc_clm_tmp.agent_seq%type */,
    
                            c_rec.clm_men /* P_Postby IN  acc_clm_tmp.post_by%type */,                                        
    
                            c_rec.br_code /* P_brn_code IN  acc_clm_tmp.brn_code%type */,
    
                            inw_type /* P_inw_type IN  acc_clm_tmp.inw_type%type */,
    
                            i.BATCH_NO /* P_batch_no IN acc_clm_tmp.batch_no%type */,                                      
    
                            v_dept_id /* P_dept_id IN acc_clm_tmp.dept_id%type */,
    
                            v_div_id /* P_div_id IN acc_clm_tmp.div_id%type */,
    
                            v_team_id /* P_team_id IN acc_clm_tmp.team_id%type */,
    
                            v_result2 /* P_msg Out varchar2*/);    
          
                if v_result2 is not null then rollback; return (v_result2||' in P_CLAIM_ACR.Post_acc_clm_tmp'); end if;        
                
                begin
                    select b.title ,b.name ,b.contact_name ,b.payee_code into V_TITLE ,V_NAME ,V_CONTACT ,V_PAYEE
                    from acc_payee b
                    where b.cancel is null
                    and b.payee_code =p1.payee_code ;            
                exception
                    when no_data_found then
                        V_TITLE:=null;
                        V_NAME :=null;
                        V_CONTACT := null;
                        V_PAYEE := null;
                    when others then
                        V_TITLE:=null;
                        V_NAME :=null;
                        V_CONTACT := null;
                        V_PAYEE := null;
                end;    
                
        for p5 in (select tot_res res_amt
                    from mis_clm_mas a 
                    where a.clm_no  = c_rec.clm_no
                     )     
        loop
            v_RES_AMT := p5.res_amt;            
        end loop;   
                --v_ADV_AMT := v_RES_AMT - p1.pay_total;    
                --v_ADV_AMT := p1.payee_amt - (p1.pay_total - p1.rec_total);            

            for p3 in (select sum(pay_total) pay_amt ,sum(0) rec_amt ,sum(0) deduct_amt
                    from mis_clm_paid a
                    where a.clm_no = c_rec.clm_no
            and a.pay_no in (
                select pay_no
                from mis_cpa_paid  x1
                where clm_no = a.clm_no
                and cancel is null and x1.corr_seq in (select max(x2.corr_seq) from mis_cpa_paid x2 where x2.clm_no = x1.clm_no and x2.pay_no = x1.pay_no)            
            )                      
                    and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
                    where b.pay_no = a.pay_no
                    group by b.pay_no) )        
                loop
                     v_DEDUCT_AMT := p3.deduct_amt;            
                      V_REC_TOTAL := p3.rec_amt;
                      V_GM_PAY    := p3.pay_amt;                       
                end loop;

                v_ADV_AMT := nvl(p1.payee_amt,0) - ( nvl(V_GM_PAY,0) - nvl(V_REC_TOTAL,0) ) - nvl(v_DEDUCT_AMT,0);
                        
--                P_CLAIM_ACR.Post_acc_clm_payee_tmp( c_rec.prod_grp /* P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type */,  
--
--                                                c_rec.prod_type /* P_prod_type  IN  acc_clm_payee_tmp.prod_type%type */,
--                                                
--                                                p1.pay_no /* P_payno      IN  acc_clm_payee_tmp.payment_no%type */,
--                                                
--                                                p1.pay_seq /* P_seq        IN  acc_clm_payee_tmp.seq%type */,
--                                                
--                                                '01' /* P_doc_type   IN  acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
--                                                
--                                                'BHT' /* P_curr_code  IN  acc_clm_payee_tmp.curr_code%type */,
--                                                
--                                                p1.payee_amt /* P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type */,
--                                                
--                                                p1.payee_code /* P_payee_code IN  acc_clm_payee_tmp.payee_code%type */,
--                                                
--                                                v_title /* P_title      IN  acc_clm_payee_tmp.title%type */,
--                                                
--                                                v_name /* P_name       IN  acc_clm_payee_tmp.name%type */, 
--                                                
--                                                '08' /* P_dept_no    IN  acc_clm_payee_tmp.dept_no%type */,
--                                                
--                                                i.BATCH_NO /* P_batch_no   IN  acc_clm_payee_tmp.batch_no%type */,
--                                                
--                                                nvl(v_DEDUCT_AMT,0) * -1 /* P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type */,
--                                                
--                                                v_ADV_AMT /* P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type */,
--                                                
--                                                V_RESULT3 /* P_msg       Out varchar2*/ ) ;     

                P_CLAIM_ACR.Post_acc_clm_payee_pagm( c_rec.prod_grp /* P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type */,  
                                            
                c_rec.prod_type /* P_prod_type  IN  acc_clm_payee_tmp.prod_type%type */,
                                                
                p1.pay_no /* P_payno      IN  acc_clm_payee_tmp.payment_no%type */,
                                                
                p1.pay_seq /* P_seq        IN  acc_clm_payee_tmp.seq%type */,
                                                
                '01' /* P_doc_type   IN  acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
                                                
                'BHT' /* P_curr_code  IN  acc_clm_payee_tmp.curr_code%type */,
                                                
                p1.payee_amt /* P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type */,
                                                
                p1.payee_code /* P_payee_code IN  acc_clm_payee_tmp.payee_code%type */,
                                                
                v_title /* P_title      IN  acc_clm_payee_tmp.title%type */,
                                                
                v_name /* P_name       IN  acc_clm_payee_tmp.name%type */, 
                                                
                '08' /* P_dept_no    IN  acc_clm_payee_tmp.dept_no%type */,
                                                
                i.BATCH_NO /* P_batch_no   IN  acc_clm_payee_tmp.batch_no%type */,
                                                
                nvl(v_DEDUCT_AMT,0) * -1 /* P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type */,
                                                
                v_ADV_AMT /* P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type */,
                                        
                p1.bank_code    /* p_bank_code       in  acc_clm_payee_tmp.bank_code%type  */ ,
                                       
                p1.bank_br_code    /* p_branch_code     in  acc_clm_payee_tmp.branch_code%type */ ,
                                       
                p1.acc_no    /* p_acc_no          in  acc_clm_payee_tmp.acc_no%type*/,
                                       
                p1.acc_name    /* p_acc_name_th     in  acc_clm_payee_tmp.acc_name_th%type*/,
                                       
                null    /* p_acc_name_eng   in  acc_clm_payee_tmp.acc_name_eng%type*/,
                                       
                null    /* p_deposit_type    in  acc_clm_payee_tmp.deposit_type%type*/,
                                       
                p1.settle    /* p_paid_type       in  acc_clm_payee_tmp.paid_type%type*/,
                                       
                ''    /* p_special_flag    in  acc_clm_payee_tmp.special_flag%type*/,
                                       
                ''    /* p_special_remark    in  acc_clm_payee_tmp.special_remark%type*/,
                                       
                ''    /* p_agent_mail           in  acc_clm_payee_tmp.agent_mail%type*/,
                                       
                ''    /* p_agent_mail_flag      in  acc_clm_payee_tmp.agent_mail_flag%type*/,
                                       
                ''    /* p_agent_mobile_number  in  acc_clm_payee_tmp.agent_mobile_number%type*/,
                                       
                ''    /* p_agent_sms_flag       in  acc_clm_payee_tmp.agent_sms_flag%type*/,
                                       
                ''    /* p_cust_mail            in  acc_clm_payee_tmp.cust_mail%type*/,
                                       
                ''    /* p_cust_mail_flag       in  acc_clm_payee_tmp.cust_mail_flag%type*/,
                                       
                ''    /* p_mobile_number   in  acc_clm_payee_tmp.mobile_number%type*/,  
                                       
                ''    /* p_sms_flag        in  acc_clm_payee_tmp.sms_flag%type*/,        
                                                                                        
                V_RESULT3 /* P_msg       Out varchar2*/ ) ;                                                      
                                                
                    if v_result3 is not null then rollback; return (v_result3||' in P_CLAIM_ACR.Post_acc_clm_payee_tmp'); end if;
                    
                                            
            end loop; -- payee ,mis_clmgm_paid    
        end loop;       -- C_REC                      

    end loop; -- on round insert data I clm_batch_tmp
    COMMIT;

    -- ++++ get Send Address ++++
    BEGIN
        select a.send_title ,a.send_addr1 ,a.send_addr2  ,b.payee_code ,b.payee_name
        into M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_CODE ,M_PAYEE_NAME 
        from mis_clm_paid a ,mis_clm_payee b
        where a.pay_no = b.pay_no 
        and a.pay_no = M_PAY_NO
        and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
        where b.pay_no = a.pay_no
        group by b.pay_no) and rownum=1    ;    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            null;
        WHEN OTHERS THEN
            null;
    END;    
    -- +++ + ++ + + + + +  + + + + 
    
    if P_MANY = 'Y' then            
        --=== Post GL Twice ====
        p_acc_claim.post_gl (    V_GRP /* p_prod_grp in acr_tmp.prod_grp%type */,
        
                            V_TYPE /* p_prod_type in acr_tmp.prod_type%type */,
        
                            b1 /* p_number in varchar2 */,  -- payment no or batch no
        
                            'B' /* p_flag in varchar2 */,   -- 'P' = Payment, 'B' = Batch
        
                            V_RESULT /* p_err  out varchar2 */);  -- return null if no error
        
        if v_result is not null then /* CLR_ACC_TMP; */ return (v_result||' in p_acc_claim.post_gl');  end if;    

        p_acc_claim.post_gl (    V_GRP2 /* p_prod_grp in acr_tmp.prod_grp%type */,
        
                            V_TYPE2 /* p_prod_type in acr_tmp.prod_type%type */,
        
                            b2 /* p_number in varchar2 */,  -- payment no or batch no
        
                            'B' /* p_flag in varchar2 */,   -- 'P' = Payment, 'B' = Batch
        
                            V_RESULT /* p_err  out varchar2 */);  -- return null if no error
        
        if v_result is not null then /* CLR_ACC_TMP; */ return (v_result||' in p_acc_claim.post_gl R1');  end if;    

         Insert into clm_sent_payee
           (KEY_NO ,SENT_TYPE ,PAYEE_CODE ,CONTACT_NAME ,ADDR1 ,ADDR2 ,PAYEE_NAME)
         Values              
              (b1 ,'B' ,M_PAYEE_CODE ,M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_NAME);     
         Insert into clm_sent_payee
           (KEY_NO ,SENT_TYPE ,PAYEE_CODE ,CONTACT_NAME ,ADDR1 ,ADDR2 ,PAYEE_NAME)
         Values              
              (b2 ,'B' ,M_PAYEE_CODE ,M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_NAME);                         
    else -- P_MANY = N
        --=== Post GL Single ====
        p_acc_claim.post_gl (    V_GRP /* p_prod_grp in acr_tmp.prod_grp%type */,
    
                            V_TYPE /* p_prod_type in acr_tmp.prod_type%type */,
        
                            b1 /* p_number in varchar2 */,  -- payment no or batch no
        
                            'B' /* p_flag in varchar2 */,   -- 'P' = Payment, 'B' = Batch
        
                            V_RESULT /* p_err  out varchar2 */);  -- return null if no error
        
        if v_result is not null then /* CLR_ACC_TMP; */ return (v_result||' in p_acc_claim.post_gl R2'); end if;    
        
         Insert into clm_sent_payee
           (KEY_NO ,SENT_TYPE ,PAYEE_CODE ,CONTACT_NAME ,ADDR1 ,ADDR2 ,PAYEE_NAME)
         Values              
              (b1 ,'B' ,M_PAYEE_CODE ,M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_NAME);                   
    end if;  -- END P_MANY
    
    --======= Step Update Data ========
    for J1 in (
        select clm_no  ,prod_grp ,real_prod_type prod_type ,ar_vou_no ,pay_no ,batch_no 
        from clm_batch_tmp a
        where draft_no = P_DRAFTNO          
    ) loop        
            begin
                p_acc_claim.get_acr_voucher ( J1.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,

                  J1.prod_type /* p_prod_type in acr_tmp.prod_type%type */,

                  J1.BATCH_NO /* p_number in varchar2 */,   -- payment no or batch no

                  'B' /* p_flag in varchar2 */,  -- 'P' = Payment, 'B' = Batch

                  V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,

                  V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);                
                
                
                Update mis_clm_paid a 
                set a.print_type = '1' ,
                a.pay_date = V_VOUDATE ,a.state_flag='1' ,
                a.corr_date = V_VOUDATE ,
                a.batch_no = J1.BATCH_NO ,
                a.print_sts = 'print'
                where a.clm_no = J1.clm_no
                and a.pay_no in (
                    select pay_no
                from mis_cpa_paid  x1
                where clm_no = a.clm_no
                and cancel is null and x1.corr_seq in (select max(x2.corr_seq) from mis_cpa_paid x2 where x2.clm_no = x1.clm_no and x2.pay_no = x1.pay_no)            
                )                  
                and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
                where b.pay_no = a.pay_no
                group by b.pay_no);        
                
                update clm_batch_tmp
                set --batch_no = J1.BATCH_NO ,
                PAID_DATE = V_VOUDATE, P_VOU_NO =V_VOUNO, P_VOU_DATE =V_VOUDATE
                where draft_no = P_DRAFTNO
                and pay_no = J1.PAY_NO
                and clm_no = J1.CLM_NO
                and prod_type ='001'
                --and batch_no is null
                ;
        
                update mis_clm_mas
                set    clm_sts = '2',
                       close_date = trunc(sysdate)                   
                where  clm_no =J1.CLM_NO ;
                
                update mis_clm_mas_seq a 
                set    clm_sts = '2', 
                       close_date = trunc(sysdate)
                where  (a.clm_no = J1.CLM_NO) and 
                       (a.clm_no,corr_seq) in (select b.clm_no,max(corr_seq) from mis_clm_mas_seq b 
                                               where  a.clm_no = b.clm_no 
                                               group by b.clm_no);                  
                                            
            exception
                when others then
                    rollback; return 'error Update Claim ::'||sqlerrm ;
            end;
            
            V_STATUS_RST := UPDATE_STATUS(J1.pay_no , V_USER_ID);
            
            IF V_STATUS_RST is not null THEN 
                NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'UPDATE_STATUS' ,V_STATUS_RST,
                              m_rst)   ;                    
            END IF;
            
    end loop; --J1 
    COMMIT;
        
    if P_MANY = 'Y' then
        P_BATCHNO := b1;
        P_BATCHNO2 := b2;
    else
        P_BATCHNO := b1;
    end if;
    
    return null; 
END SCRIPT_BATCH;

FUNCTION SCRIPT_BATCH_GM(P_DRAFTNO  IN VARCHAR2 , V_USER_ID IN VARCHAR2 ,P_MANY IN VARCHAR2 ,P_BATCHNO OUT VARCHAR2  , P_BATCHNO2 OUT VARCHAR2) RETURN VARCHAR2 IS
    cnt number;
--    double_b    boolean:=false;
    V_RESULT varchar2(100);
    V_RESULT2 varchar2(100);    
    V_RESULT3 varchar2(100);       
    V_RESULT_x  varchar2(100);       
    b1    varchar2(10);
    b2    varchar2(10);    
  inw_type varchar2(1);        
    V_DEPT_ID VARCHAR (2) ;
    V_DIV_ID  VARCHAR (2) ;
    V_TEAM_ID VARCHAR (2);  
    v_DEDUCT_AMT NUMBER    ;        
    V_TITLE      VARCHAR (30) ;
    V_NAME       VARCHAR (120) ;        
    V_PAYEE       VARCHAR (20) ;    
    V_CONTACT       VARCHAR (120) ;
    V_GRP    VARCHAR2(3);
    V_TYPE VARCHAR2(3);
    V_GRP2    VARCHAR2(3);
    V_TYPE2 VARCHAR2(3);    
    V_VOUNO    varchar2(15);
    V_VOUDATE    DATE;    
    v_RES_AMT    number;
    v_ADV_AMT number;    
    v_GM_PAY number;    
    v_REC_TOTAL number;    
    M_SEND_TITLE    varchar2(100);    
    M_SEND_ADDR1  varchar2(200); 
    M_SEND_ADDR2  varchar2(200); 
    M_PAYEE_CODE  varchar2(20); 
    M_PAYEE_NAME  varchar2(200);         
    M_PAY_NO    varchar2(20); 
    V_STATUS_RST     varchar2(200);  
    m_rst   varchar2(200);  
BEGIN
    
    b1 := GET_BATCHNO('GB');
    if P_MANY = 'Y' then b2 := GET_BATCHNO('GB'); end if;    -- for VoucerBatch

    if P_MANY = 'Y' then    
--        first_record;
        for I1 in (
            select clm_no  ,prod_grp ,real_prod_type prod_type ,ar_vou_no ,pay_no
            from clmgm_batch_tmp a
            where draft_no = P_DRAFTNO      
        ) loop
            if I1.AR_VOU_NO is not null then
                -- :TMP_BLK.BATCH_NO := b2;
                V_GRP2 := I1.PROD_GRP;
                V_TYPE2 := I1.PROD_TYPE;
                begin 
                   update clmgm_batch_tmp
                   set batch_no = b2 
                   where draft_no = P_DRAFTNO and pay_no = I1.pay_no ;
                exception                
                when others then
                    rollback ;
                    return 'error I1: '||sqlerrm ;
                end;
            else
                -- :TMP_BLK.BATCH_NO := b1;
                V_GRP :=  I1.PROD_GRP;
                V_TYPE := I1.PROD_TYPE;     
                begin 
                   update clmgm_batch_tmp
                   set batch_no = b1 
                   where draft_no = P_DRAFTNO and pay_no = I1.pay_no ;
                exception                
                when others then
                    rollback ;
                    return 'error I1: '||sqlerrm ;
                end;                     
            end if;
        end loop;    
    else
        for I2 IN (
            select clm_no  ,prod_grp ,real_prod_type prod_type ,ar_vou_no  ,pay_no
            from clmgm_batch_tmp a
            where draft_no = P_DRAFTNO              
        ) loop
            -- :TMP_BLK.BATCH_NO := b1;
            V_GRP :=  I2.PROD_GRP;
            V_TYPE := I2.PROD_TYPE;      
            begin 
               update clmgm_batch_tmp
               set batch_no = b1
               where draft_no = P_DRAFTNO and pay_no = I2.pay_no ;
            exception                
            when others then
                rollback ;
                return 'error I2: '||sqlerrm ;
            end;                            
        end loop;        
    end if;
    
--    :parameter.p_batch1 := b1;    
--    :parameter.p_batch2 := b2;    
    
    --======= Step Insert Data ========
    for i in (
        select clm_no  ,prod_grp ,real_prod_type prod_type ,ar_vou_no  ,pay_no ,BATCH_NO
        from clmgm_batch_tmp a
        where draft_no = P_DRAFTNO         
    ) loop    -- on round insert data
      
        for c_rec in (select clm_no ,pol_no ,pol_run ,nvl(policy_number,pol_no||pol_run) policy_number ,prod_grp ,prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,channel ,clm_men
                                  from mis_clm_mas
                  where clm_no =   i.CLM_NO and clm_sts = '6' and close_date is null)                                        
        loop
            if c_rec.channel = '9' then inw_type := 'Y'; else inw_type := null; end if;    
            begin
                select dept_id ,div_id ,team_id into V_DEPT_ID, V_DIV_ID, V_TEAM_ID
                from bkiuser
                where user_id = c_rec.clm_men;                
            exception
                when no_data_found then
                    V_DEPT_ID:=null;
                    V_DIV_ID :=null;
                    V_TEAM_ID :=null;
                when others then
                    V_DEPT_ID:=null;
                    V_DIV_ID :=null;
                    V_TEAM_ID :=null;
            end;
            
            for p1 in (select a.pay_no ,pay_seq ,pay_date ,payee_amt ,pay_total ,nvl(rec_total,0) rec_total ,disc_total ,replace(payee_code,' ','') payee_code 
                       from mis_clmgm_paid a, clm_gm_payee b
                                where a.clm_no = b.clm_no
                and pay_seq = (select max(e.pay_seq) from clm_gm_payee e where e.pay_no = b.pay_no )
                and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from mis_clmgm_paid b
                                where b.clm_no = a.clm_no
                                group by b.clm_no)                                  
                                and a.clm_no = c_rec.clm_no
                                )                                                  
            loop             
                M_PAYEE_CODE := P1.PAYEE_CODE ;
                M_PAY_NO := P1.PAY_NO;
                
                P_CLAIM_ACR.Post_acc_clm_tmp(    c_rec.prod_grp /*P_prod_grp IN   acc_clm_tmp.prod_grp%type*/,
    
                            c_rec.prod_type /* P_prod_type IN  acc_clm_tmp.prod_type%type */,
    
                            p1.pay_no /* P_payno   IN  acc_clm_tmp.payment_no%type */,
    
                            trunc(sysdate) /* P_appoint_date IN  acc_clm_tmp.appoint_date%type */,
    
                            c_rec.clm_no /* P_clmno   IN  acc_clm_tmp.clm_no%type */,
    
                            c_rec.pol_no /* P_polno   IN  acc_clm_tmp.pol_no%type */,
    
                            c_rec.pol_run /* P_polrun  IN  acc_clm_tmp.pol_run%type */,
    
                            c_rec.policy_number /* P_polnum  IN  acc_clm_tmp.policy_number%type */,
    
                            c_rec.pol_no||c_rec.pol_run /* P_polref  IN  acc_clm_tmp.pol_ref%type */,          
    
                            c_rec.cus_code /* P_cuscode IN  acc_clm_tmp.cus_code%type */,
    
                            c_rec.th_eng /* P_th_eng IN  acc_clm_tmp.th_eng%type */,
    
                            c_rec.agent_code /* P_agent_code IN  acc_clm_tmp.agent_code%type */,
    
                            c_rec.agent_seq /* P_agent_seq IN  acc_clm_tmp.agent_seq%type */,
    
                            c_rec.clm_men /* P_Postby IN  acc_clm_tmp.post_by%type */,                                        
    
                            c_rec.br_code /* P_brn_code IN  acc_clm_tmp.brn_code%type */,
    
                            inw_type /* P_inw_type IN  acc_clm_tmp.inw_type%type */,
    
                            i.BATCH_NO /* P_batch_no IN acc_clm_tmp.batch_no%type */,                                      
    
                            v_dept_id /* P_dept_id IN acc_clm_tmp.dept_id%type */,
    
                            v_div_id /* P_div_id IN acc_clm_tmp.div_id%type */,
    
                            v_team_id /* P_team_id IN acc_clm_tmp.team_id%type */,
    
                            v_result2 /* P_msg Out varchar2*/);    
          
                if v_result2 is not null then rollback; return (v_result2||' in P_CLAIM_ACR.Post_acc_clm_tmp'); end if;        
                
                begin
                    select b.title ,b.name ,b.contact_name ,b.payee_code into V_TITLE ,V_NAME ,V_CONTACT ,V_PAYEE
                    from acc_payee b
                    where b.cancel is null
                    and b.payee_code =p1.payee_code ;            
                exception
                    when no_data_found then
                        V_TITLE:=null;
                        V_NAME :=null;
                        V_CONTACT := null;
                        V_PAYEE := null;
                    when others then
                        V_TITLE:=null;
                        V_NAME :=null;
                        V_CONTACT := null;
                        V_PAYEE := null;
                end;    
                 
                for p5 in (select sum(res_amt) res_amt
                            from clm_medical_res a 
                            where a.clm_no  = c_rec.clm_no
                            and  (a.state_no,a.state_seq) = (select b.state_no,max(b.state_seq) from clm_medical_res b
                            where b.clm_no = a.clm_no and b.state_no = a.state_no
                            group by b.state_no) )     
                loop
                    v_RES_AMT := p5.res_amt;            
                end loop;         
      

                for p3 in (select sum(pay_amt) pay_amt ,sum(rec_amt) rec_amt ,sum(deduct_amt) deduct_amt
                    from clm_gm_paid a
                    where a.clm_no = c_rec.clm_no
                    and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from clm_gm_paid b
                    where b.clm_no = a.clm_no
                    group by b.clm_no) )        
                loop
                      v_DEDUCT_AMT := p3.deduct_amt;            
                      V_REC_TOTAL := p3.rec_amt;
                      V_GM_PAY    := p3.pay_amt;                       
                end loop;
                
                v_ADV_AMT := nvl(p1.payee_amt,0) - ( nvl(V_GM_PAY,0) - nvl(V_REC_TOTAL,0) ) - nvl(v_DEDUCT_AMT,0);
                            
                P_CLAIM_ACR.Post_acc_clm_payee_tmp( c_rec.prod_grp /* P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type */,  

                                                c_rec.prod_type /* P_prod_type  IN  acc_clm_payee_tmp.prod_type%type */,
                                                
                                                p1.pay_no /* P_payno      IN  acc_clm_payee_tmp.payment_no%type */,
                                                
                                                p1.pay_seq /* P_seq        IN  acc_clm_payee_tmp.seq%type */,
                                                
                                                '01' /* P_doc_type   IN  acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
                                                
                                                'BHT' /* P_curr_code  IN  acc_clm_payee_tmp.curr_code%type */,
                                                
                                                p1.payee_amt /* P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type */,
                                                
                                                p1.payee_code /* P_payee_code IN  acc_clm_payee_tmp.payee_code%type */,
                                                
                                                v_title /* P_title      IN  acc_clm_payee_tmp.title%type */,
                                                
                                                v_name /* P_name       IN  acc_clm_payee_tmp.name%type */, 
                                                
                                                '08' /* P_dept_no    IN  acc_clm_payee_tmp.dept_no%type */,
                                                
                                                i.BATCH_NO /* P_batch_no   IN  acc_clm_payee_tmp.batch_no%type */,
                                                
                                                nvl(v_DEDUCT_AMT,0) * -1 /* P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type */,
                                                
                                                v_ADV_AMT /* P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type */,
                                                
                                                V_RESULT3 /* P_msg       Out varchar2*/ ) ;      
                                                    
                    if v_result3 is not null then rollback; return (v_result3||' in P_CLAIM_ACR.Post_acc_clm_payee_tmp'); end if;
                        
                    --*** Insert CLM_GM_RECOV
                    IF nvl(v_ADV_AMT,0) > 0 THEN
                        NMTR_PACKAGE.SET_CLM_GM_RECOV(c_rec.clm_no ,p1.pay_no ,v_ADV_AMT 
                              ,V_RESULT_x );                
                    END IF;    
                                                                      
                end loop; -- payee ,mis_clmgm_paid    
        end loop;       -- C_REC                      

    end loop; -- on round insert data I clm_batch_tmp
    COMMIT;

    -- ++++ get Send Address ++++
        BEGIN
            select a.send_title ,a.send_addr1 ,a.send_addr2  ,replace(a.payee_code,' ','') ,a.payee_name
            into M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_CODE ,M_PAYEE_NAME 
            from clm_gm_payee a
            where a.pay_no = M_PAY_NO and rownum=1  ;    
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                null;
            WHEN OTHERS THEN
                null;
        END;    
    -- +++ + ++ + + + + +  + + + +     
    
    if P_MANY = 'Y' then            
        --=== Post GL Twice ====
        p_acc_claim.post_gl (    V_GRP /* p_prod_grp in acr_tmp.prod_grp%type */,
        
                            V_TYPE /* p_prod_type in acr_tmp.prod_type%type */,
        
                            b1 /* p_number in varchar2 */,  -- payment no or batch no
        
                            'B' /* p_flag in varchar2 */,   -- 'P' = Payment, 'B' = Batch
        
                            V_RESULT /* p_err  out varchar2 */);  -- return null if no error
        
        if v_result is not null then /* CLR_ACC_TMP; */ return (v_result||' in p_acc_claim.post_gl');  end if;    

        p_acc_claim.post_gl (    V_GRP2 /* p_prod_grp in acr_tmp.prod_grp%type */,
        
                            V_TYPE2 /* p_prod_type in acr_tmp.prod_type%type */,
        
                            b2 /* p_number in varchar2 */,  -- payment no or batch no
        
                            'B' /* p_flag in varchar2 */,   -- 'P' = Payment, 'B' = Batch
        
                            V_RESULT /* p_err  out varchar2 */);  -- return null if no error
        
        if v_result is not null then /* CLR_ACC_TMP; */ return (v_result||' in p_acc_claim.post_gl R1');  end if;    

         Insert into clm_sent_payee
           (KEY_NO ,SENT_TYPE ,PAYEE_CODE ,CONTACT_NAME ,ADDR1 ,ADDR2 ,PAYEE_NAME)
         Values              
              (b1 ,'B' ,M_PAYEE_CODE ,M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_NAME);     
         Insert into clm_sent_payee
           (KEY_NO ,SENT_TYPE ,PAYEE_CODE ,CONTACT_NAME ,ADDR1 ,ADDR2 ,PAYEE_NAME)
         Values              
              (b2 ,'B' ,M_PAYEE_CODE ,M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_NAME);                         
    else -- P_MANY = N
        --=== Post GL Single ====
        p_acc_claim.post_gl (    V_GRP /* p_prod_grp in acr_tmp.prod_grp%type */,
    
                            V_TYPE /* p_prod_type in acr_tmp.prod_type%type */,
        
                            b1 /* p_number in varchar2 */,  -- payment no or batch no
        
                            'B' /* p_flag in varchar2 */,   -- 'P' = Payment, 'B' = Batch
        
                            V_RESULT /* p_err  out varchar2 */);  -- return null if no error
        
        if v_result is not null then /* CLR_ACC_TMP; */ return (v_result||' in p_acc_claim.post_gl R2'); end if;    
        
         Insert into clm_sent_payee
           (KEY_NO ,SENT_TYPE ,PAYEE_CODE ,CONTACT_NAME ,ADDR1 ,ADDR2 ,PAYEE_NAME)
         Values              
              (b1 ,'B' ,M_PAYEE_CODE ,M_SEND_TITLE ,M_SEND_ADDR1 ,M_SEND_ADDR2 ,M_PAYEE_NAME);                   
    end if;  -- END P_MANY
    COMMIT;
    
    --======= Step Update Data ========
    for J1 in (
        select clm_no  ,prod_grp ,real_prod_type prod_type ,ar_vou_no ,pay_no ,batch_no 
        from clmgm_batch_tmp a
        where draft_no = P_DRAFTNO          
    ) loop        
            begin
                p_acc_claim.get_acr_voucher ( J1.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,

                  J1.prod_type /* p_prod_type in acr_tmp.prod_type%type */,

                  J1.BATCH_NO /* p_number in varchar2 */,   -- payment no or batch no

                  'B' /* p_flag in varchar2 */,  -- 'P' = Payment, 'B' = Batch

                  V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,

                  V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);                
                
                IF V_VOUNO is null THEN
                    ROLLBACK; return ' p_acc_claim.post_gl have any Problem ';
                END IF;
                            
                Update mis_clmgm_paid a 
                set a.print_type = '1' ,
                a.pay_date = V_VOUDATE ,
                a.batch_no = J1.BATCH_NO,
                a.print_sts = 'print'
                where a.clm_no = J1.CLM_NO
                and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from mis_clmgm_paid b
                where b.clm_no = a.clm_no
                group by b.clm_no);        
                
                update clm_gm_paid a 
                set a.date_paid = V_VOUDATE
                where a.clm_no = J1.CLM_NO
                and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from clm_gm_paid b
                where b.clm_no = a.clm_no
                group by b.clm_no);
        
                update clm_medical_res a 
                set a.close_date = V_VOUDATE
                where a.clm_no = J1.CLM_NO
                and  (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq) from clm_medical_res b
                where b.clm_no = a.clm_no
                group by b.clm_no,b.state_no);
                
                update clmgm_batch_tmp
                set batch_no = J1.BATCH_NO
                ,PAID_DATE = V_VOUDATE, P_VOU_NO =V_VOUNO, P_VOU_DATE =V_VOUDATE
                where DRAFT_NO = P_DRAFTNO
                and pay_no = J1.PAY_NO
                and clm_no = J1.CLM_NO
                and batch_no is null;
        
                update mis_clm_mas
                set    clm_sts = '2',
                       close_date = trunc(sysdate)
                   ,out_open_sts = 'Y'
                   ,out_paid_sts = 'Y'
                   ,out_print_sts ='Y'                   
                where  clm_no =  J1.CLM_NO;
                
                update mis_clm_mas_seq a 
                set    clm_sts = '2', 
                       close_date = trunc(sysdate)
                where  (a.clm_no =  J1.CLM_NO) and 
                       (a.clm_no,corr_seq) in (select b.clm_no,max(corr_seq) from mis_clm_mas_seq b 
                                               where  a.clm_no = b.clm_no 
                                               group by b.clm_no);  
          
                                            
            exception
                when others then
                    rollback; return 'error Update Claim ::'||sqlerrm ;
            end;
            
            V_STATUS_RST := UPDATE_STATUS(J1.pay_no , V_USER_ID);
            
            IF V_STATUS_RST is not null THEN 
                NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'UPDATE_STATUS' ,V_STATUS_RST,
                              m_rst)   ;                    
            END IF;
            
    end loop; --J1 
    COMMIT;
        
    if P_MANY = 'Y' then
        P_BATCHNO := b1;
        P_BATCHNO2 := b2;
    else
        P_BATCHNO := b1;
    end if;
    
    return null; 
END SCRIPT_BATCH_GM;

FUNCTION  CLEAR_DRAFT(P_DRAFTNO IN  VARCHAR2) RETURN VARCHAR2 IS -- null สำเร็จ
    TMP_C   NC_HEALTH_PACKAGE.v_ref_cursor1;   
    m_rst   VARCHAR2(200);
    v_batch_no VARCHAR2(20);
BEGIN
    
    FOR X1 IN (
        select max(batch_no) batch_no from clm_batch_tmp x where draft_no = P_DRAFTNO
    ) LOOP 
        v_batch_no := X1.BATCH_NO ;
    END LOOP;
    
    IF v_batch_no is not null THEN -- มีการสร้าง BATCH แล้ว
        return 'Draftno. '||P_DRAFTNO||' มีการสร้าง BATCH แล้ว ไม่สามารถ Clear Draft ได้! ';
    END IF;
    
    UPDATE mis_clm_paid a
    SET print_type = null
    WHERE pay_no in (
    select x.pay_no from clm_batch_tmp x where draft_no = P_DRAFTNO
    )
    and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no);
    
    DELETE from clm_batch_tmp  WHERE  draft_no = P_DRAFTNO ;
    
    COMMIT;
    return null;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    return 'error clear Draftno.: '||P_DRAFTNO ;
END CLEAR_DRAFT;

FUNCTION  CLEAR_DRAFT_GM(P_DRAFTNO IN  VARCHAR2) RETURN VARCHAR2 IS -- null สำเร็จ
    TMP_C   NC_HEALTH_PACKAGE.v_ref_cursor1;   
    m_rst   VARCHAR2(200);
    v_batch_no VARCHAR2(20);
BEGIN
    
    FOR X1 IN (
        select max(batch_no) batch_no from clmgm_batch_tmp x where draft_no = P_DRAFTNO
    ) LOOP 
        v_batch_no := X1.BATCH_NO ;
    END LOOP;
    
    IF v_batch_no is not null THEN -- มีการสร้าง BATCH แล้ว
        return 'Draftno. '||P_DRAFTNO||' มีการสร้าง BATCH แล้ว ไม่สามารถ Clear Draft ได้! ';
    END IF;
    
    UPDATE mis_clmgm_paid a
    SET print_type = null
    WHERE pay_no in (
    select x.pay_no from clmgm_batch_tmp x where draft_no = P_DRAFTNO
    )
    and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clmgm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no);
    
    DELETE from clmgm_batch_tmp  WHERE  draft_no = P_DRAFTNO ;
    
    COMMIT;
    return null;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    return 'error clear Draftno.: '||P_DRAFTNO ;
END CLEAR_DRAFT_GM;       

FUNCTION FIX_MED_DATA_STEP1(P_CLMNO IN VARCHAR2 ,P_OUT OUT VARCHAR2) RETURN BOOLEAN IS
-- == fix problem recpt_seq end_seq error  ==
    v_clm_no varchar2(20);
    v_sts_key   number;
    p_recpt_seq number;
    p_end_seq   number ;
    dumm_recpt  number;
    dumm_end  number;
    dumm_name   varchar2(250);
    dumm_cnt    number:=0;
    is_manyname boolean:=false;
    v_cnt number:=0;
    v_rst   varchar2(200);
    v_return  boolean:=true;
BEGIN
    v_clm_no := P_CLMNO;
        FOR X1 in (
            select a.sts_key ,a.clm_no ,a.pol_no
             ,a.pol_run ,end_seq ,a.fleet_seq ,a.recpt_seq , a.clm_date ,a.loss_date,tr_date_fr ,tr_date_to ,tr_date_to - tr_date_fr xday,tot_tr_day ,cus_name ,id_no ,loss_detail
            ,(select nvl(sum(res_amt),0) from nc_reserved x where x.sts_key = a.sts_key and x.trn_seq in (select max(xx.trn_seq) from  nc_reserved xx where xx.sts_key = x.sts_key) ) res_amt
            ,a.hpt_code,nc_health_package.get_hospital_name(null,'T',a.hpt_code) hosptial , nc_health_package.GET_CLM_STATUS_DESC(b.sts_sub_type ,1) status -- ,b.sts_sub_type ,b.remark
            from nc_mas a ,nc_status b
            where a.sts_key = B.STS_KEY 
            and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type='MEDSTS' )
            and b.sts_type='MEDSTS'
            and a.clm_no = v_clm_no
        ) LOOP
            v_cnt := v_cnt+1;
            FOR Y1 in (
            select recpt_seq ,end_seq ,name||surname name1
            from mis_pa_prem
            where pol_no =X1.POL_NO and pol_run =X1.POL_RUN  and fleet_seq = X1.FLEET_SEQ
            and X1.LOSS_DATE between fr_date and to_date
            ) LOOP
                dumm_cnt := dumm_cnt + 1;
                dbms_output.put_line('current recpt='||X1.recpt_seq||' end_seq='||X1.end_seq);
                dbms_output.put_line('correct recpt='||Y1.recpt_seq||' end_seq='||Y1.end_seq);
                if dumm_cnt > 1 then
                    if dumm_name <> Y1.name1 then -- in case 1 fleet has many customer name seperate by recpt_seq
                        is_manyname := true;
                        p_recpt_seq := dumm_recpt ;
                        p_end_seq :=  dumm_end ;                          
                    end if;
                end if;
                dumm_name := Y1.name1;
                dumm_recpt := Y1.recpt_seq ;
                dumm_end :=  Y1.end_seq ;                
--                p_recpt_seq := Y1.recpt_seq ;
--                p_end_seq :=  Y1.end_seq ;              
            END LOOP;
            
            if not is_manyname then
                p_recpt_seq := dumm_recpt;
                p_end_seq := dumm_end;    
            end if;
                            
            UPDATE NC_MAS 
            set recpt_seq = p_recpt_seq , end_seq =p_end_seq
            WHERE CLM_NO = v_clm_no ;
            
            UPDATE MIS_CLM_MAS 
            set recpt_seq = p_recpt_seq , end_seq =p_end_seq
            WHERE CLM_NO = v_clm_no ;            
        END LOOP;   
        
        IF v_cnt = 0 THEN
            v_rst := 'no data' ;
        ELSE
            COMMIT;
            v_rst := 'update data clmplete' ;
        END IF;
        
        P_OUT := v_rst;
        RETURN V_RETURN;
EXCEPTION
    WHEN OTHERS THEN
        rollback; 
        P_OUT :='error :'||sqlerrm ;
        return false;
END FIX_MED_DATA_STEP1;

FUNCTION FIX_MED_DATA_STEP2(P_CLMNO IN VARCHAR2 ,P_OUT OUT VARCHAR2) RETURN BOOLEAN IS 
        c1   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data1 IS RECORD
        (
        POL_NO  MIS_RI_MAS.POL_NO%TYPE ,
        POL_RUN MIS_RI_MAS.POL_RUN%TYPE ,
        RI_CODE MIS_RI_MAS.RI_CODE%TYPE ,
        RI_BR_CODE MIS_RI_MAS.RI_BR_CODE%TYPE ,
        RI_TYPE MIS_RI_MAS.RI_TYPE%TYPE ,
        LF_FLAG MIS_RI_MAS.LF_FLAG%TYPE ,
        RI_SUB_TYPE MIS_RI_MAS.RI_SUB_TYPE%TYPE ,
        --RI_SUM  NUMBER(20,2),
        --RI_SUM_SHR   MIS_RI_MAS.RI_SHARE%TYPE      
        RI_SUM_SHR   NUMBER
        ); 
        j_rec1 t_data1;        
        
        v_cnt   number:=0;
        --v_tot_res   number:= 2168;
        v_tot_res   number;
        v_shr_amt   number;
        v_sum_res   number:=0;
        v_rec   number:=0;
        vLETT_PRT varchar2(20);
        vLETT_NO varchar2(20);
        
        vProd_type varchar2(5):='002';
        --v_key   number:=87427;
        v_key   number;
        vCLm_no  varchar2(20);
        vprod_grp  varchar2(5):='0';
        p_pol_no    varchar2(20);
        p_pol_run  number;
        p_recpt_seq number;
        p_end_seq   number ;      
        p_fleet_seq number;  
        p_loss_date date;
        p_maxtrn    number:=0;
        v_rst   varchar2(200);
        v_return  boolean:=true;        
begin
    vCLm_no := P_CLMNO ;    
    
            begin 
            select nvl(max(aa.trn_seq),-1)+1 into p_maxtrn
            from nc_ri_reserved aa where aa.clm_no = vCLm_no;
            exception
                when others then
                null;
            end;
            
            FOR X1 in (
            select a.sts_key ,a.clm_no ,a.prod_type ,a.pol_no
             ,a.pol_run ,end_seq ,a.fleet_seq ,a.recpt_seq , a.clm_date ,a.loss_date,tr_date_fr ,tr_date_to ,tr_date_to - tr_date_fr xday,tot_tr_day ,cus_name ,id_no ,loss_detail
            ,(select nvl(sum(res_amt),0) from nc_reserved x where x.sts_key = a.sts_key and x.trn_seq in (select max(xx.trn_seq) from  nc_reserved xx where xx.sts_key = x.sts_key) ) res_amt
            ,a.hpt_code,nc_health_package.get_hospital_name(null,'T',a.hpt_code) hosptial , nc_health_package.GET_CLM_STATUS_DESC(b.sts_sub_type ,1) status -- ,b.sts_sub_type ,b.remark
            from nc_mas a ,nc_status b
            where a.sts_key = B.STS_KEY 
            and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type='MEDSTS' )
            and b.sts_type='MEDSTS'
            and a.clm_no = vCLm_no
            ) LOOP
                p_recpt_seq := X1.recpt_seq ;
                p_end_seq :=  X1.end_seq ;
                p_pol_no:= X1.pol_no;
                p_pol_run := X1.pol_run;
                p_fleet_seq := X1.fleet_seq;
                p_loss_date := X1.loss_date ;
                v_tot_res := X1.res_amt;
                v_key := X1.sts_key;
                vProd_type := X1.prod_type ;
            END LOOP;
            
    v_cnt := NC_HEALTH_PACKAGE.GET_RI_RES( p_pol_no , p_pol_run, p_recpt_seq ,0 ,p_loss_date ,p_end_seq ,c1 );
    --dbms_output.put_line(' Count ==>'|| v_cnt);    
    if V_cnt>0 then
        LOOP
           FETCH  c1 INTO j_rec1;
            EXIT WHEN c1%NOTFOUND;
            
                if v_rec = v_cnt then
                   v_shr_amt := v_tot_res -  v_sum_res;
                else
                    v_shr_amt   := (v_tot_res* j_rec1.RI_SUM_SHR/100);     
                end if;
                v_sum_res := v_sum_res +v_shr_amt;                

                dbms_output.put_line('RI_CODE==>'|| 
                 j_rec1.ri_code||
                 ' RI_BR_CODE:'||
                  j_rec1.ri_br_code||
                 ' RI_SUM_SHR:'||
                  j_rec1.RI_SUM_SHR|| 
                 ' v_shr_amt:'||v_shr_amt
                );   
                v_rst :=v_rst||' cnt:'||v_cnt|| ' RI_CODE==>'||j_rec1.ri_code|| ' RI_BR_CODE:'||j_rec1.ri_br_code|| ' RI_SUM_SHR:'||j_rec1.RI_SUM_SHR|| ' v_shr_amt:'||v_shr_amt;

                    IF j_rec1.RI_TYPE = '1' THEN
                       IF  v_shr_amt < 1000000 THEN
                          vLETT_PRT := 'N';
                       ELSE
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                       END IF;
                    ELSIF j_rec1.RI_TYPE = '0' THEN
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                    ELSE
                          vLETT_PRT := 'N';
                    END IF;                  
                    BEGIN
                      INSERT INTO NC_RI_RESERVED A
                       (
                        A.STS_KEY,  A.CLM_NO, A.PROD_GRP,  A.PROD_TYPE,A.TYPE,A.TRN_SEQ
                        ,A.RI_CODE, A.RI_BR_CODE, A.RI_STS_DATE, A.RI_AMD_DATE     
                        ,A.RI_TYPE, A.RI_RES_AMT ,A.RI_TRN_AMT,A.RI_SHARE          
                        ,A.LETT_NO, A.LETT_PRT, A.LETT_TYPE ,A.RI_LF_FLAG, A.RI_SUB_TYPE ,SUB_TYPE                     
                        )
                      VALUES
                       (v_key ,vCLm_no ,vprod_grp ,vprod_type , j_rec1.RI_TYPE ,p_maxtrn,
                        j_rec1.RI_CODE, j_rec1.RI_BR_CODE, trunc(sysdate) , sysdate,
                        j_rec1.RI_TYPE, v_shr_amt , v_shr_amt ,j_rec1.RI_SUM_SHR, 
                        vLETT_NO ,vLETT_PRT, 'P',j_rec1.LF_FLAG,j_rec1.RI_SUB_TYPE ,'NCNATSUBTYPECLM001'); 
                    EXCEPTION
                    WHEN OTHERS THEN
                        --DBMS_OUTPUT.PUT_LINE('error insert CRI_RES: '||SQLERRM);
                        ROLLBACK;
                        v_rst := 'error insert CRI_RES: '||sqlerrm;
                        return false;
                    END;      
                                    
                v_rec := v_rec+1; 
          END LOOP;    
      END IF;        
      COMMIT;            
      P_OUT := v_rst;
      RETURN v_return;          
EXCEPTION
    WHEN OTHERS THEN
        rollback; 
        P_OUT :='error :'||sqlerrm ;
        return false;                                
END FIX_MED_DATA_STEP2;

PROCEDURE GET_PA_RESERVE(P_PAYNO IN VARCHAR2 ,V_KEY OUT NUMBER , V_RST OUT VARCHAR2) IS
    --q_str   CLOB;

     cursor c1 is                
                SELECT  a.pay_no ,a.prem_code1, a.prem_pay1,
                a.prem_code2, a.prem_pay2, a.prem_code3, a.prem_pay3, a.prem_code4,
                a.prem_pay4, a.prem_code5, a.prem_pay5, a.prem_code6, a.prem_pay6,
                a.prem_code7, a.prem_pay7, a.prem_code8, a.prem_pay8, a.prem_code9,
                a.prem_pay9, a.prem_code10, a.prem_pay10, a.prem_code11, a.prem_pay11,
                a.prem_code12, a.prem_pay12, a.prem_code13, a.prem_pay13, a.prem_code14,
                a.prem_pay14, a.prem_code15, a.prem_pay15, a.prem_code16, a.prem_pay16,
                a.prem_code17, a.prem_pay17, a.prem_code18, a.prem_pay18, a.prem_code19,
                a.prem_pay19, a.prem_code20, a.prem_pay20, a.prem_code21, a.prem_pay21,
                a.prem_code22, a.prem_pay22, a.prem_code23, a.prem_pay23, a.prem_code24,
                a.prem_pay24, a.prem_code25, a.prem_pay25
                from mis_cpa_paid a
                where a.pay_no = P_PAYNO
                and (pay_no ,corr_seq ) in (
                    select aa.pay_no ,max(aa.corr_seq) from mis_cpa_paid aa where aa.pay_no = a.pay_no
                    and cancel is null
                    group by aa.pay_no
                )
                --and b.loss_date =P_LOSSDATE           
                ; 
 

    c_rec c1%rowtype;

    TYPE DEFINE_CLMNO IS VARRAY(50) OF VARCHAR2(20);
    t_clmno   DEFINE_CLMNO ;    
    TYPE DEFINE_PREMCODE IS VARRAY(50) OF VARCHAR2(20);
    t_premcode   DEFINE_PREMCODE ;
    TYPE DEFINE_AMT IS VARRAY(50) OF NUMBER;
    t_amt   DEFINE_AMT ;    
    TYPE DEFINE_PREMCOL IS VARRAY(50) OF NUMBER;
    t_premcol   DEFINE_PREMCOL ;    
        
    v_SID number(10);
    v_Tmp1 VARCHAR2(20);
    cnt NUMBER:=0;                      
    BEGIN
        V_RST := null; 
       --*** GET SID ***
        BEGIN
            --SELECT sys_context('USERENV', 'SID') + to_char(sysdate , 'SS') into v_SID
            SELECT sys_context('USERENV', 'SID')  into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;        
            
       t_clmno := DEFINE_CLMNO(); --create empty varray 
       t_premcode := DEFINE_PREMCODE(); --create empty varray 
       t_amt := DEFINE_AMT(); --create empty varray 
       t_premcol := DEFINE_PREMCOL(); --create empty varray        
       OPEN C1;
       LOOP
          FETCH C1 INTO C_REC;
          EXIT WHEN C1%NOTFOUND;
            if c_rec.prem_code1 is not null and c_rec.prem_pay1 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;            
            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code1 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay1 ;

                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 1 ;                
            end if;
              
            if c_rec.prem_code2 is not null and c_rec.prem_pay2 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code2 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay2 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 2;
            end if;
            if c_rec.prem_code3 is not null and c_rec.prem_pay3 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code3 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay3 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 3 ;
            end if;
        
            if c_rec.prem_code4 is not null and c_rec.prem_pay4 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code4 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay4 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 4 ;
            end if;        

            if c_rec.prem_code5 is not null and c_rec.prem_pay5 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code5 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay5 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 5 ;
            end if;                
        
            if c_rec.prem_code6 is not null and c_rec.prem_pay6 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code6 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay6 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 6 ;
            end if;        
        
            if c_rec.prem_code7 is not null and c_rec.prem_pay7 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code7 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay7 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 7 ;
            end if;        

            if c_rec.prem_code8 is not null and c_rec.prem_pay8 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code8 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay8 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 8 ;
            end if;       
        
            if c_rec.prem_code9 is not null and c_rec.prem_pay9 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code9 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay9 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 9 ;
            end if;         
        
            if c_rec.prem_code10 is not null and c_rec.prem_pay10 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code10 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay10 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 10 ;
            end if;        
        
            if c_rec.prem_code11 is not null and c_rec.prem_pay11 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code11 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay11 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 11 ;
            end if;
        
            if c_rec.prem_code12 is not null and c_rec.prem_pay12 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code12 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay12 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 12 ;
            end if;        
        
            if c_rec.prem_code13 is not null and c_rec.prem_pay13 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code13 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay13 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 13 ;
            end if;        
        
            if c_rec.prem_code14 is not null and c_rec.prem_pay14 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code14 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay14 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 14 ;
            end if;        
        
            if c_rec.prem_code15 is not null and c_rec.prem_pay15 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code15 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay15 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 15 ;
            end if;        
                
            if c_rec.prem_code16 is not null and c_rec.prem_pay16 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code16 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay16 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 16 ;
            end if;
        
            if c_rec.prem_code17 is not null and c_rec.prem_pay17 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code17 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay17 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 17 ;
            end if;        
                
            if c_rec.prem_code18 is not null and c_rec.prem_pay18 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code18 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay18 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 18 ;
            end if;
                
            if c_rec.prem_code19 is not null and c_rec.prem_pay19 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code19 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay19 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 19 ;
            end if;        
        
            if c_rec.prem_code20 is not null and c_rec.prem_pay20 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code20 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay20 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 20 ;
            end if;
        
            if c_rec.prem_code21 is not null and c_rec.prem_pay21 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code21 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay21 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 21 ;
            end if;        
        
            if c_rec.prem_code22 is not null and c_rec.prem_pay22 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code22 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay22 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 22 ;
            end if;        

            if c_rec.prem_code23 is not null and c_rec.prem_pay23 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code23 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay23 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 23 ;
            end if;                
        
            if c_rec.prem_code24 is not null and c_rec.prem_pay24 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code24 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay24 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 24 ;
            end if;        
        
            if c_rec.prem_code25 is not null and c_rec.prem_pay25 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code25 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay25 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 25 ;
            end if;        
        
       END LOOP;
       --DBMS_OUTPUT.PUT_LINE('COUNT='||t_premcode.COUNT);
       --q_str    := '';
       cnt:=0;
       FOR I in 1..t_premcode.COUNT LOOP
            cnt := cnt+1;            
            --DBMS_OUTPUT.PUT_LINE('C2 CLMNO='||t_clmno(cnt)||' PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_amt(cnt));
             BEGIN   --NC_H_HISTORY_TMP  
                insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
                values (v_SID ,t_clmno(cnt) ,t_premcode(cnt) ,t_amt(cnt) ,'P');
             EXCEPTION
               WHEN  OTHERS THEN
               --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
               V_KEY := 0 ; 
               rollback;
             END;     
       END LOOP;
       
        t_premcode.DELETE;
        t_amt.DELETE;
        t_clmno.DELETE;
        t_premcol.DELETE;
        
        BEGIN  -- check found
           
           SELECT max(PREM_CODE) into v_Tmp1
           FROM   NC_H_HISTORY_TMP
           WHERE   SID = V_SID
           AND ROWNUM=1;              
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            V_KEY :=0 ;
            V_RST := 'Error :'||sqlerrm;
          WHEN  OTHERS THEN
            V_KEY :=0 ;
            V_RST := 'Error :'||sqlerrm;
        END;   -- end check found
        
        IF   nvl(v_Tmp1,'N') <> 'N' THEN              
            commit;
            V_KEY := v_SID ;
        ELSE
            V_KEY :=0 ;
            V_RST := 'N';
        END IF;
            
        --gen_cursor(q_str , P_CUR);
EXCEPTION
    WHEN OTHERS THEN
        V_RST := 'Error :'||sqlerrm;                
        V_KEY :=0 ;      
        
END GET_PA_RESERVE;

PROCEDURE GET_PA_RESERVE(P_PAYNO IN VARCHAR2 ,P_QUERY OUT LONG , V_RST OUT VARCHAR2) IS
    q_str   LONG;

     cursor c1 is                
                SELECT  a.pay_no ,a.prem_code1, a.prem_pay1,
                a.prem_code2, a.prem_pay2, a.prem_code3, a.prem_pay3, a.prem_code4,
                a.prem_pay4, a.prem_code5, a.prem_pay5, a.prem_code6, a.prem_pay6,
                a.prem_code7, a.prem_pay7, a.prem_code8, a.prem_pay8, a.prem_code9,
                a.prem_pay9, a.prem_code10, a.prem_pay10, a.prem_code11, a.prem_pay11,
                a.prem_code12, a.prem_pay12, a.prem_code13, a.prem_pay13, a.prem_code14,
                a.prem_pay14, a.prem_code15, a.prem_pay15, a.prem_code16, a.prem_pay16,
                a.prem_code17, a.prem_pay17, a.prem_code18, a.prem_pay18, a.prem_code19,
                a.prem_pay19, a.prem_code20, a.prem_pay20, a.prem_code21, a.prem_pay21,
                a.prem_code22, a.prem_pay22, a.prem_code23, a.prem_pay23, a.prem_code24,
                a.prem_pay24, a.prem_code25, a.prem_pay25
                from mis_cpa_paid a
                where a.pay_no = P_PAYNO
                and (pay_no ,corr_seq ) in (
                    select aa.pay_no ,max(aa.corr_seq) from mis_cpa_paid aa where aa.pay_no = a.pay_no
                    and cancel is null
                    group by aa.pay_no
                )
                --and b.loss_date =P_LOSSDATE           
                ; 
 

    c_rec c1%rowtype;

    TYPE DEFINE_CLMNO IS VARRAY(50) OF VARCHAR2(20);
    t_clmno   DEFINE_CLMNO ;    
    TYPE DEFINE_PREMCODE IS VARRAY(50) OF VARCHAR2(20);
    t_premcode   DEFINE_PREMCODE ;
    TYPE DEFINE_AMT IS VARRAY(50) OF NUMBER;
    t_amt   DEFINE_AMT ;    
    TYPE DEFINE_PREMCOL IS VARRAY(50) OF NUMBER;
    t_premcol   DEFINE_PREMCOL ;    
        
    v_SID number(10);
    v_Tmp1 VARCHAR2(20);
    cnt NUMBER:=0;                      
    BEGIN
        V_RST := null; 
       --*** GET SID ***
        BEGIN
            SELECT sys_context('USERENV', 'SID') into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;        
            
       t_clmno := DEFINE_CLMNO(); --create empty varray 
       t_premcode := DEFINE_PREMCODE(); --create empty varray 
       t_amt := DEFINE_AMT(); --create empty varray 
       t_premcol := DEFINE_PREMCOL(); --create empty varray        
       OPEN C1;
       LOOP
          FETCH C1 INTO C_REC;
          EXIT WHEN C1%NOTFOUND;
            if c_rec.prem_code1 is not null and c_rec.prem_pay1 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;            
            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code1 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay1 ;

                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 1 ;                
            end if;
              
            if c_rec.prem_code2 is not null and c_rec.prem_pay2 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code2 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay2 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 2;
            end if;
            if c_rec.prem_code3 is not null and c_rec.prem_pay3 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code3 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay3 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 3 ;
            end if;
        
            if c_rec.prem_code4 is not null and c_rec.prem_pay4 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code4 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay4 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 4 ;
            end if;        

            if c_rec.prem_code5 is not null and c_rec.prem_pay5 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code5 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay5 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 5 ;
            end if;                
        
            if c_rec.prem_code6 is not null and c_rec.prem_pay6 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code6 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay6 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 6 ;
            end if;        
        
            if c_rec.prem_code7 is not null and c_rec.prem_pay7 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code7 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay7 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 7 ;
            end if;        

            if c_rec.prem_code8 is not null and c_rec.prem_pay8 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code8 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay8 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 8 ;
            end if;       
        
            if c_rec.prem_code9 is not null and c_rec.prem_pay9 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code9 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay9 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 9 ;
            end if;         
        
            if c_rec.prem_code10 is not null and c_rec.prem_pay10 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code10 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay10 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 10 ;
            end if;        
        
            if c_rec.prem_code11 is not null and c_rec.prem_pay11 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code11 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay11 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 11 ;
            end if;
        
            if c_rec.prem_code12 is not null and c_rec.prem_pay12 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code12 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay12 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 12 ;
            end if;        
        
            if c_rec.prem_code13 is not null and c_rec.prem_pay13 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code13 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay13 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 13 ;
            end if;        
        
            if c_rec.prem_code14 is not null and c_rec.prem_pay14 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code14 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay14 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 14 ;
            end if;        
        
            if c_rec.prem_code15 is not null and c_rec.prem_pay15 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code15 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay15 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 15 ;
            end if;        
                
            if c_rec.prem_code16 is not null and c_rec.prem_pay16 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code16 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay16 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 16 ;
            end if;
        
            if c_rec.prem_code17 is not null and c_rec.prem_pay17 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code17 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay17 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 17 ;
            end if;        
                
            if c_rec.prem_code18 is not null and c_rec.prem_pay18 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code18 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay18 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 18 ;
            end if;
                
            if c_rec.prem_code19 is not null and c_rec.prem_pay19 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code19 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay19 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 19 ;
            end if;        
        
            if c_rec.prem_code20 is not null and c_rec.prem_pay20 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code20 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay20 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 20 ;
            end if;
        
            if c_rec.prem_code21 is not null and c_rec.prem_pay21 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code21 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay21 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 21 ;
            end if;        
        
            if c_rec.prem_code22 is not null and c_rec.prem_pay22 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code22 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay22 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 22 ;
            end if;        

            if c_rec.prem_code23 is not null and c_rec.prem_pay23 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code23 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay23 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 23 ;
            end if;                
        
            if c_rec.prem_code24 is not null and c_rec.prem_pay24 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code24 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay24 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 24 ;
            end if;        
        
            if c_rec.prem_code25 is not null and c_rec.prem_pay25 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code25 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay25 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 25 ;
            end if;        
        
       END LOOP;
       --DBMS_OUTPUT.PUT_LINE('COUNT='||t_premcode.COUNT);
       P_QUERY    := '';
       cnt:=0;
       FOR I in 1..t_premcode.COUNT LOOP
            cnt := cnt+1;            
            --DBMS_OUTPUT.PUT_LINE('C1 CLMNO='||t_clmno(cnt)||' PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_amt(cnt));
                
                P_QUERY := P_QUERY||' select '''||t_clmno(cnt)||''' pay_no , '''||t_premcode(cnt)||''' prem_code , '||t_amt(cnt)||' amount from dual UNION ';
  
       END LOOP;
        t_premcode.DELETE;
        t_amt.DELETE;
        t_clmno.DELETE;
        t_premcol.DELETE;
        
        if cnt > 0 then
            P_QUERY := rtrim(P_QUERY, 'UNION ') ;
            --OPEN P_CUR FOR q_str ;
        else
            P_QUERY :=' SELECT '''||'' ||''' pay_no ,'''||'' ||''' prem_code ,0 amount FROM dual ';
            V_RST := 'N'; 
            --OPEN P_CUR FOR q_str ;
        end if;        
        --gen_cursor(q_str , P_CUR);
EXCEPTION
    WHEN OTHERS THEN
        V_RST := 'Error :'||sqlerrm;                
        P_QUERY :=' SELECT '''||'' ||''' pay_no ,'''||'' ||''' prem_code ,0 amount FROM dual ';
        --OPEN P_CUR FOR q_str ;        
        
END GET_PA_RESERVE;

FUNCTION IS_APPROVE_PROCESS(P_PAYNO IN VARCHAR2 ,P_OUT OUT VARCHAR2) RETURN BOOLEAN IS

BEGIN
    return true;
END IS_APPROVE_PROCESS;
    
FUNCTION SET_APPROVE_STATUS(P_PAYNO IN VARCHAR2 ,P_STATUS IN VARCHAR2) RETURN VARCHAR2 IS -- return NULL = success

BEGIN
    return '';
END SET_APPROVE_STATUS;

FUNCTION SET_SEND_ADDR  (P_PAYNO in VARCHAR2 , M_SEND_TITLE in  VARCHAR2 ,M_SEND_ADDR1 in VARCHAR2 ,M_SEND_ADDR2 IN VARCHAR2 ,
                           V_RST  OUT VARCHAR2)   RETURN BOOLEAN IS 
    V_CLM_NO MIS_CLM_MAS.CLM_NO%TYPE;                           
BEGIN

    begin
        select clm_no into V_CLM_NO
        from mis_cri_paid
        where pay_no = P_PAYNO and rownum=1;
    exception
    when no_data_found then
        V_CLM_NO := null;
    when others then
        V_CLM_NO := null;
    end;
    
    IF NC_CLNMC908.GET_PRODUCTID(V_CLM_NO) = 'GM' THEN
        BEGIN
            update clm_gm_payee a
            SET send_title = M_SEND_TITLE
            ,send_addr1 = M_SEND_ADDR1 
            ,send_addr2 = M_SEND_ADDR2            
            where a.pay_no = P_PAYNO  ;    
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                V_RST := 'error update Send Address :'||' not found data'; return false;
            WHEN OTHERS THEN
                rollback;
                V_RST := 'error update Send Address :'||sqlerrm; return false;
        END;        
    ELSE
        UPDATE mis_clm_paid a
        SET send_title = M_SEND_TITLE
        ,send_addr1 = M_SEND_ADDR1
        ,send_addr2 = M_SEND_ADDR2
        WHERE a.PAY_NO = P_PAYNO
        AND (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no) ;    
    END IF;    
        
    COMMIT;
    return true;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    V_RST := 'error update Send Address :'||' not found data'; return false;
    WHEN OTHERS THEN
    rollback;
    V_RST := 'error update Send Address :'||sqlerrm; return false;
END SET_SEND_ADDR;

FUNCTION  SET_SPECIAL_DATA  (P_PAYNO IN VARCHAR2 , T_CUST_MAIL_FLAG IN  VARCHAR2 ,T_CUST_MAIL IN VARCHAR2 ,T_SMS_FLAG IN VARCHAR2 ,T_MOBILE_NUMBER IN VARCHAR2 
    , T_AGENT_MAIL_FLAG IN  VARCHAR2 ,T_AGENT_MAIL IN VARCHAR2 ,T_AGENT_SMS_FLAG IN VARCHAR2 ,T_AGENT_MOBILE_NUMBER IN VARCHAR2 
    , T_SPECIAL_REMARK IN VARCHAR2 ,T_SPECIAL_FLAG IN VARCHAR2 
    ,V_RST  OUT VARCHAR2)   RETURN BOOLEAN IS 
    
    V_CLM_NO MIS_CLM_MAS.CLM_NO%TYPE;                           
BEGIN

    begin
        select clm_no into V_CLM_NO
        from mis_cri_paid
        where pay_no = P_PAYNO and rownum=1;
    exception
    when no_data_found then
        V_CLM_NO := null;
    when others then
        V_CLM_NO := null;
    end;
    
    IF NC_CLNMC908.GET_PRODUCTID(V_CLM_NO) = 'GM' THEN
        BEGIN
            update clm_gm_payee a
            SET CUST_MAIL_FLAG = T_CUST_MAIL_FLAG
            ,CUST_MAIL = T_CUST_MAIL 
            ,SMS_FLAG = T_SMS_FLAG  
            ,MOBILE_NUMBER = T_MOBILE_NUMBER     
            ,AGENT_MAIL_FLAG = T_AGENT_MAIL_FLAG
            ,AGENT_MAIL = T_AGENT_MAIL 
            ,AGENT_SMS_FLAG = T_AGENT_SMS_FLAG  
            ,AGENT_MOBILE_NUMBER = T_AGENT_MOBILE_NUMBER                      
            ,SPECIAL_REMARK = T_SPECIAL_REMARK  
            ,SPECIAL_FLAG = T_SPECIAL_FLAG    
            where a.pay_no = P_PAYNO  ;    
            
            update mis_clmgm_paid a
            SET CUST_MAIL_FLAG = T_CUST_MAIL_FLAG
            ,CUST_MAIL = T_CUST_MAIL 
            ,SMS_FLAG = T_SMS_FLAG  
            ,MOBILE_NUMBER = T_MOBILE_NUMBER     
            ,AGENT_MAIL_FLAG = T_AGENT_MAIL_FLAG
            ,AGENT_MAIL = T_AGENT_MAIL 
            ,AGENT_SMS_FLAG = T_AGENT_SMS_FLAG  
            ,AGENT_MOBILE_NUMBER = T_AGENT_MOBILE_NUMBER                      
            ,SPECIAL_REMARK = T_SPECIAL_REMARK  
            ,SPECIAL_FLAG = T_SPECIAL_FLAG    
            where a.pay_no = P_PAYNO  
            and (pay_no ,corr_seq) in (select aa.pay_no , max(aa.corr_seq) from mis_clmgm_paid aa where aa.pay_no = a.pay_no group by aa.pay_no );               
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                V_RST := 'error update clm_gm_payee :'||' not found data'; return false;
            WHEN OTHERS THEN
                rollback;
                V_RST := 'error update clm_gm_payee :'||sqlerrm; return false;
        END;        
    ELSE
            update mis_clm_payee a
            SET CUST_MAIL_FLAG = T_CUST_MAIL_FLAG
            ,CUST_MAIL = T_CUST_MAIL 
            ,SMS_FLAG = T_SMS_FLAG  
            ,MOBILE_NUMBER = T_MOBILE_NUMBER     
            ,AGENT_MAIL_FLAG = T_AGENT_MAIL_FLAG
            ,AGENT_MAIL = T_AGENT_MAIL 
            ,AGENT_SMS_FLAG = T_AGENT_SMS_FLAG  
            ,AGENT_MOBILE_NUMBER = T_AGENT_MOBILE_NUMBER                      
            ,SPECIAL_REMARK = T_SPECIAL_REMARK  
            ,SPECIAL_FLAG = T_SPECIAL_FLAG    
            where a.pay_no = P_PAYNO  ;    
            
            update mis_clm_paid a
            SET CUST_MAIL_FLAG = T_CUST_MAIL_FLAG
            ,CUST_MAIL = T_CUST_MAIL 
            ,SMS_FLAG = T_SMS_FLAG  
            ,MOBILE_NUMBER = T_MOBILE_NUMBER     
            ,AGENT_MAIL_FLAG = T_AGENT_MAIL_FLAG
            ,AGENT_MAIL = T_AGENT_MAIL 
            ,AGENT_SMS_FLAG = T_AGENT_SMS_FLAG  
            ,AGENT_MOBILE_NUMBER = T_AGENT_MOBILE_NUMBER                      
            ,SPECIAL_REMARK = T_SPECIAL_REMARK  
            ,SPECIAL_FLAG = T_SPECIAL_FLAG    
            where a.pay_no = P_PAYNO  
            and (pay_no ,corr_seq) in (select aa.pay_no , max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no group by aa.pay_no );     
    END IF;    
        
    COMMIT;
    return true;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    V_RST := 'error update Send Address :'||' not found data'; return false;
    WHEN OTHERS THEN
    rollback;
    V_RST := 'error update Send Address :'||sqlerrm; return false;
END SET_SPECIAL_DATA;

FUNCTION GET_HISTORY_CLAIM(vPOLICY IN VARCHAR2,
                                                    P_FLEET_SEQ IN NUMBER,
                                                    P_CLM_MAS OUT v_ref_cursor1 ,P_CLM_DETAIL OUT v_ref_cursor2 ,
                        RST OUT VARCHAR2)  RETURN VARCHAR2 IS

P_POL_NO  VARCHAR2(20);
P_POL_RUN  NUMBER;
--    P_FLEET_SEQ  NUMBER:=1;
--    P_LOSSDATE  DATE:='15-SEP-11';
V_KEY  NUMBER;
        
v_SID number(10);
v_Tmp1 VARCHAR2(20);
cnt NUMBER:=0;                    
    
vPolType varchar2(10);  
    
v_cntmas    number:=0;
vOldPol     VARCHAR2(30);
BEGIN
    --dbms_output.put_line('POLICY='||vPOLICY);
    p_acc_package.read_pol(vPOLICY ,P_POL_NO ,P_POL_RUN);
    dbms_output.put_line('P_POL_NO='||P_POL_NO||' P_POL_RUN:'||P_POL_RUN);
    vPolType := 'XX';         
    if P_POL_NO is not null and P_POL_RUN is not null then
        HEALTHUTIL.get_pa_health_type(P_POL_NO ,P_POL_RUN ,vPolType) ; 
        dbms_output.put_line('PolType='||vPolType);
    end if;
        
    IF vPolType not in ('PI','PG') THEN
        OPEN P_CLM_MAS FOR 
            select '' clm_no ,'' policyno ,0 fleet_seq ,'' mas_cus_code ,'' mas_cus_name
            ,'' title 
            ,'' name 
            ,'' surname 
            ,'' cus_code 
            ,'' idcard_no 
            ,'' loss_date ,''loss_detail ,''clm_sts ,'' icd_code 
            ,'' tr_date_fr ,'' tr_date_to ,''risk_code 
            ,'' clm_type 
            from dual      
        ;
        OPEN P_CLM_DETAIL FOR 
            select ''clm_no ,'' bene_code ,'' descr , 0 reserve_amt , 0 paid_amt 
            from dual
        ;          
        dbms_output.put_line('Exit');
        RST := 'ไม่พบข้อมูลกรมธรรม์นี้ในกลุ่มงาน PA';
        RETURN 'E';
    END IF;
                    
    NC_HEALTH_PAID.GET_HISTORY_ALL_STATUS(P_POL_NO,P_POL_RUN,P_FLEET_SEQ, V_KEY) ;  
    dbms_output.put_line('Key='||V_KEY);
        
    IF V_KEY = 0 THEN
        OPEN P_CLM_MAS FOR 
            select '' clm_no ,'' policyno ,0 fleet_seq ,'' mas_cus_code ,'' mas_cus_name
            ,'' title 
            ,'' name 
            ,'' surname 
            ,'' cus_code 
            ,'' idcard_no 
            ,'' loss_date ,''loss_detail ,''clm_sts ,'' icd_code 
            ,'' tr_date_fr ,'' tr_date_to ,''risk_code 
            ,'' clm_type 
            from dual      
        ;
        OPEN P_CLM_DETAIL FOR 
            select ''clm_no ,'' bene_code ,'' descr , 0 reserve_amt , 0 paid_amt 
            from dual
        ;              
        RST := 'ไม่พบประวัติเคลม ';
        RETURN 'N';            
    ELSE
        FOR P1 IN (
                select x.clm_no ,pol_no||pol_run policyno ,y.fleet_seq ,mas_cus_code ,mas_cus_enq mas_cus_name
                ,(select title from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) title 
                ,(select name from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) name 
                ,(select surname from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) surname 
                ,cus_code 
                ,(select id from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) idcard_no 
                ,x.loss_date ,loss_detail ,nc_health_paid.CONVERT_CLM_STATUS(clm_sts) clm_sts ,dis_code icd_code 
                ,loss_date_fr tr_date_fr ,loss_date_to tr_date_to ,risk_code 
                from mis_clm_mas x ,mis_cpa_res y
                where x.clm_no in 
                (
                select distinct a.clm_no
                from NC_H_HISTORY_TMP a
                where  sid=V_KEY
                )
                and x.clm_no = y.clm_no
                and y.revise_seq = (select max(xx.revise_seq) from mis_cpa_res xx where xx.clm_no = y.clm_no)        
                UNION
                select a.clm_no ,pol_no||pol_run policyno ,a.fleet_seq ,mas_cus_code , mas_cus_name
                ,(select title from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) title 
                ,(select name  from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) name 
                ,(select surname from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) surname 
                ,cus_code ,a.id_no idcard_no
                ,a.loss_date ,loss_detail ,nc_health_package.GET_CLM_STATUS(a.sts_key) clm_sts ,dis_code icd_code 
                , tr_date_fr , tr_date_to ,cause_code risk_code 
                from nc_mas a , nc_reserved b
                where a.sts_key = b.sts_key
                and a.clm_no not in (select x.clm_no from mis_clm_mas x where x.clm_no = a.clm_no)
                and b.trn_seq in (select max(bb.trn_seq) from nc_reserved bb where bb.sts_key = b.sts_key)
                and a.clm_no in 
                (
                select distinct x.clm_no
                from NC_H_HISTORY_TMP x
                where  sid=V_KEY
                )           
        )
        LOOP
            v_cntmas := v_cntmas+1;
        END LOOP;
            
        IF v_cntmas = 0 THEN -- ไม่พบ clm_mas บน BKI APP
            NC_HEALTH_PAID.REMOVE_HISTORY_CLAIM(V_KEY);             
            OPEN P_CLM_MAS FOR 
                select '' clm_no ,'' policyno ,0 fleet_seq ,'' mas_cus_code ,'' mas_cus_name
                ,'' title 
                ,'' name 
                ,'' surname 
                ,'' cus_code 
                ,'' idcard_no 
                ,'' loss_date ,''loss_detail ,''clm_sts ,'' icd_code 
                ,'' tr_date_fr ,'' tr_date_to ,''risk_code
                ,'' clm_type --,'' old_policy
                from dual      
            ;
            OPEN P_CLM_DETAIL FOR 
                select ''clm_no ,'' bene_code ,'' descr , 0 reserve_amt , 0 paid_amt 
                from dual
            ;                 
            RST := 'ไม่พบประวัติเคลม ';
            RETURN 'N';      
   
        END IF;
            
        OPEN P_CLM_MAS FOR 
            select x.clm_no ,pol_no||pol_run policyno ,y.fleet_seq ,mas_cus_code ,mas_cus_enq mas_cus_name
            ,(select title from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) title 
            ,(select name from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) name 
            ,(select surname from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) surname 
            ,cus_code 
            ,(select id from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1 ) idcard_no 
            ,to_char(x.loss_date,'yyyyddmm')  loss_date ,loss_detail ,nc_health_paid.CONVERT_CLM_STATUS(clm_sts) clm_sts ,dis_code icd_code 
            ,to_char(loss_date_fr,'yyyyddmm')  tr_date_fr ,to_char(loss_date_to,'yyyyddmm')  tr_date_to ,risk_code 
            ,decode(nvl(x.ipd_flag,'N/A'),'I','IPD' ,decode(nvl(x.ipd_flag,'N/A'),'O','OPD',nvl(x.ipd_flag,'N/A')) ) clm_type
            --, (select old_pol_no||old_pol_run from mis_mas mm where mm.pol_no = x.pol_no and mm.pol_run = x.pol_run and mm.end_seq = (select max(mx.end_seq) from mis_mas mx where mx.pol_no = mm.pol_no and mx.pol_run = mm.pol_run) ) old_policy
            from mis_clm_mas x ,mis_cpa_res y
            where x.clm_no in 
            (
            select distinct a.clm_no
            from NC_H_HISTORY_TMP a
            where  sid=V_KEY
            )
            and x.clm_no = y.clm_no
            and y.revise_seq = (select max(xx.revise_seq) from mis_cpa_res xx where xx.clm_no = y.clm_no)    
            UNION
            select a.clm_no ,pol_no||pol_run policyno ,a.fleet_seq ,mas_cus_code , mas_cus_name
            ,(select title from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) title 
            ,(select name  from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) name 
            ,(select surname from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq  and rownum=1) surname 
            ,cus_code ,a.id_no idcard_no
            , to_char(a.loss_date,'yyyyddmm') loss_date ,loss_detail ,nc_health_paid.CONVERT_CLM_STATUS( nc_health_package.GET_CLM_STATUS(a.sts_key)) clm_sts ,dis_code icd_code 
            ,to_char(tr_date_fr,'yyyyddmm') tr_date_fr ,to_char(tr_date_to,'yyyyddmm') tr_date_to ,cause_code risk_code 
            ,decode(nvl(a.ipd_flag,'N/A'),'I','IPD' ,decode(nvl(a.ipd_flag,'N/A'),'O','OPD',nvl(a.ipd_flag,'N/A')) ) clm_type
            --, (select old_pol_no||old_pol_run from mis_mas mm where mm.pol_no = a.pol_no and mm.pol_run = a.pol_run and mm.end_seq = (select max(mx.end_seq) from mis_mas mx where mx.pol_no = mm.pol_no and mx.pol_run = mm.pol_run) ) old_policy
            from nc_mas a , nc_reserved b
            where a.sts_key = b.sts_key
            and a.clm_no not in (select x.clm_no from mis_clm_mas x where x.clm_no = a.clm_no)
            and b.trn_seq in (select max(bb.trn_seq) from nc_reserved bb where bb.sts_key = b.sts_key)
            and a.clm_no in 
            (
            select distinct x.clm_no
            from NC_H_HISTORY_TMP x
            where  sid=V_KEY
            )                                 
        ;
        OPEN P_CLM_DETAIL FOR 
            select clm_no ,prem_code bene_code ,NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(prem_code ,'T') descr , amount reserve_amt , 0 paid_amt 
            from NC_H_HISTORY_TMP a
            where sid=V_KEY and TYPE in ('X','R')
            --and (select chk_accum from nc_h_premcode where premcode = a.prem_code and rownum =1 ) = 'Y'
            UNION
            select clm_no ,prem_code bene_code ,NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(prem_code ,'T') descr, 0 reserve_amt ,amount paid_amt
            from NC_H_HISTORY_TMP a
            where sid=V_KEY and TYPE in ('P')
            --and (select chk_accum from nc_h_premcode where premcode = a.prem_code and rownum =1 ) = 'Y'
            order by clm_no    
        ;          
            
        NC_HEALTH_PAID.REMOVE_HISTORY_CLAIM(V_KEY);
            
        return   'Y'; 
            
    END IF;
EXCEPTION
    WHEN OTHERS THEN
    NC_HEALTH_PAID.REMOVE_HISTORY_CLAIM(V_KEY);
        OPEN P_CLM_MAS FOR 
            select '' clm_no ,'' policyno ,0 fleet_seq ,'' mas_cus_code ,'' mas_cus_name
            ,'' title 
            ,'' name 
            ,'' surname 
            ,'' cus_code 
            ,'' idcard_no 
            ,'' loss_date ,''loss_detail ,''clm_sts ,'' icd_code 
            ,'' tr_date_fr ,'' tr_date_to ,''risk_code 
            ,'' clm_type 
            from dual      
        ;
        OPEN P_CLM_DETAIL FOR 
            select ''clm_no ,'' bene_code ,'' descr , 0 reserve_amt , 0 paid_amt 
            from dual
        ;              
    RST := 'error in GET_HISTORY_CLAIM :'||sqlerrm;
    return 'E';
END;         --END GET_HISTORY_CLAIM
                                   

PROCEDURE GET_HISTORY_ALL_STATUS(P_POL_NO IN VARCHAR2,
                                                    P_POL_RUN IN NUMBER,
                                                    P_FLEET_SEQ IN NUMBER,
                       V_KEY OUT NUMBER)  IS
 cursor c1 is                
            SELECT  b.clm_no ,a.prem_code1, a.prem_pay1,
            a.prem_code2, a.prem_pay2, a.prem_code3, a.prem_pay3, a.prem_code4,
            a.prem_pay4, a.prem_code5, a.prem_pay5, a.prem_code6, a.prem_pay6,
            a.prem_code7, a.prem_pay7, a.prem_code8, a.prem_pay8, a.prem_code9,
            a.prem_pay9, a.prem_code10, a.prem_pay10, a.prem_code11, a.prem_pay11,
            a.prem_code12, a.prem_pay12, a.prem_code13, a.prem_pay13, a.prem_code14,
            a.prem_pay14, a.prem_code15, a.prem_pay15, a.prem_code16, a.prem_pay16,
            a.prem_code17, a.prem_pay17, a.prem_code18, a.prem_pay18, a.prem_code19,
            a.prem_pay19, a.prem_code20, a.prem_pay20, a.prem_code21, a.prem_pay21,
            a.prem_code22, a.prem_pay22, a.prem_code23, a.prem_pay23, a.prem_code24,
            a.prem_pay24, a.prem_code25, a.prem_pay25
            from mis_clm_mas b ,mis_cpa_paid a
            where b.pol_no = P_POL_NO and b.pol_run = P_POL_RUN
            and b.clm_sts ='2' 
            and a.clm_no = b.clm_no
            and a.corr_seq = (select max(x.corr_seq) from mis_cpa_paid x where x.clm_no = a.clm_no)
            and nvl(a.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
            --and b.loss_date =P_LOSSDATE           
            ; 
 
 cursor c2 is                
            SELECT  b.clm_no ,a.prem_code1, a.prem_pay1,
            a.prem_code2, a.prem_pay2, a.prem_code3, a.prem_pay3, a.prem_code4,
            a.prem_pay4, a.prem_code5, a.prem_pay5, a.prem_code6, a.prem_pay6,
            a.prem_code7, a.prem_pay7, a.prem_code8, a.prem_pay8, a.prem_code9,
            a.prem_pay9, a.prem_code10, a.prem_pay10, a.prem_code11, a.prem_pay11,
            a.prem_code12, a.prem_pay12, a.prem_code13, a.prem_pay13, a.prem_code14,
            a.prem_pay14, a.prem_code15, a.prem_pay15, a.prem_code16, a.prem_pay16,
            a.prem_code17, a.prem_pay17, a.prem_code18, a.prem_pay18, a.prem_code19,
            a.prem_pay19, a.prem_code20, a.prem_pay20, a.prem_code21, a.prem_pay21,
            a.prem_code22, a.prem_pay22, a.prem_code23, a.prem_pay23, a.prem_code24,
            a.prem_pay24, a.prem_code25, a.prem_pay25
            from mis_clm_mas b ,mis_cpa_res a
            where b.pol_no = P_POL_NO and b.pol_run = P_POL_RUN
            and b.clm_sts  in ('0' ,'6' ,'4')
            and a.clm_no = b.clm_no
            and a.revise_seq = (select max(x.revise_seq) from mis_cpa_res x where x.clm_no = a.clm_no)
            and nvl(a.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
            --and b.loss_date =P_LOSSDATE           
            ; 

 cursor c3 is                  
            --select clm_no ,prem_code ,nvl(sum(res_amt) ,0) res_amt
            select clm_no ,prem_code ,sum( decode(nvl(res_amt ,nvl(req_amt,0)) ,0 ,req_amt ,res_amt)  ) res_amt
            from nc_reserved x
            where x.sts_key in (
            select a.sts_key
            from nc_mas a ,nc_status b
            where A.STS_KEY = b.sts_key
            and a.pol_no = P_POL_NO and a.pol_run = P_POL_RUN
            --and a.loss_date = P_LOSSDATE
            and nvl(a.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
            and b.sts_type = 'MEDSTS'
            and b.sts_sub_type in ('MEDSTS00','MEDSTS01','MEDSTS03','MEDSTS11','MEDSTS12') 
            and a.clm_no not in (select aa.clm_no from mis_clm_mas aa where aa.clm_no = a.clm_no)
            and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type = 'MEDSTS')
            )  and x.trn_seq in (select max(xx.trn_seq) from nc_reserved xx where XX.STS_KEY = x.sts_key ) 
            and prod_grp = '0'
            group by x.clm_no ,X.PREM_CODE;                

 cursor c4 is                
            SELECT  b.clm_no ,a.prem_code1, a.prem_pay1,
            a.prem_code2, a.prem_pay2, a.prem_code3, a.prem_pay3, a.prem_code4,
            a.prem_pay4, a.prem_code5, a.prem_pay5, a.prem_code6, a.prem_pay6,
            a.prem_code7, a.prem_pay7, a.prem_code8, a.prem_pay8, a.prem_code9,
            a.prem_pay9, a.prem_code10, a.prem_pay10, a.prem_code11, a.prem_pay11,
            a.prem_code12, a.prem_pay12, a.prem_code13, a.prem_pay13, a.prem_code14,
            a.prem_pay14, a.prem_code15, a.prem_pay15, a.prem_code16, a.prem_pay16,
            a.prem_code17, a.prem_pay17, a.prem_code18, a.prem_pay18, a.prem_code19,
            a.prem_pay19, a.prem_code20, a.prem_pay20, a.prem_code21, a.prem_pay21,
            a.prem_code22, a.prem_pay22, a.prem_code23, a.prem_pay23, a.prem_code24,
            a.prem_pay24, a.prem_code25, a.prem_pay25
            from mis_clm_mas b ,mis_cpa_res a
            where b.pol_no = P_POL_NO and b.pol_run = P_POL_RUN
            and b.clm_sts  in ('3')
            and a.clm_no = b.clm_no
            and a.revise_seq = (select max(x.revise_seq) from mis_cpa_res x where x.clm_no = a.clm_no)
            and nvl(a.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
            --and b.loss_date =P_LOSSDATE           
            ; 

 cursor c5 is                  
            --select clm_no ,prem_code ,nvl(sum(res_amt) ,0) res_amt
            select clm_no ,prem_code ,sum( decode(nvl(res_amt ,nvl(req_amt,0)) ,0 ,req_amt ,res_amt)  ) res_amt
            from nc_reserved x
            where x.sts_key in (
            select a.sts_key
            from nc_mas a ,nc_status b
            where A.STS_KEY = b.sts_key
            and a.pol_no = P_POL_NO and a.pol_run = P_POL_RUN
            --and a.loss_date = P_LOSSDATE
            and nvl(a.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
            and b.sts_type = 'MEDSTS'
            and b.sts_sub_type in ('MEDSTS31','MEDSTS32') 
            and a.clm_no not in (select aa.clm_no from mis_clm_mas aa where aa.clm_no = a.clm_no)
            and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type = 'MEDSTS')
            )  and x.trn_seq in (select max(xx.trn_seq) from nc_reserved xx where XX.STS_KEY = x.sts_key ) 
            and x.clm_no not in (select x.clm_no from mis_clm_mas x where x.clm_no = x.clm_no)
            group by x.clm_no ,X.PREM_CODE;   
                                          
c_rec c1%rowtype;
c_rec2 c2%rowtype; 
c_rec3 c3%rowtype;    
c_rec4 c4%rowtype; 
c_rec5 c5%rowtype;    
TYPE DEFINE_CLMNO IS VARRAY(200) OF VARCHAR2(20);
t_clmno   DEFINE_CLMNO ;    
TYPE DEFINE_PREMCODE IS VARRAY(200) OF VARCHAR2(20);
t_premcode   DEFINE_PREMCODE ;
TYPE DEFINE_AMT IS VARRAY(200) OF NUMBER;
t_amt   DEFINE_AMT ;    
TYPE DEFINE_PREMCOL IS VARRAY(200) OF NUMBER;
t_premcol   DEFINE_PREMCOL ;    
        
v_SID number(10);
v_Tmp1 VARCHAR2(20);
cnt NUMBER:=0;                      
BEGIN
    
   --*** GET SID ***
    BEGIN
        SELECT sys_context('USERENV', 'SID') into v_SID
        FROM DUAL;
    EXCEPTION
      WHEN  NO_DATA_FOUND THEN
      v_SID := 0;        
      WHEN  OTHERS THEN
      v_SID := 0;
    END;        
            
   t_clmno := DEFINE_CLMNO(); --create empty varray 
   t_premcode := DEFINE_PREMCODE(); --create empty varray 
   t_amt := DEFINE_AMT(); --create empty varray 
   t_premcol := DEFINE_PREMCOL(); --create empty varray        
   OPEN C1;
   LOOP
      FETCH C1 INTO C_REC;
      EXIT WHEN C1%NOTFOUND;
        if c_rec.prem_code1 is not null and c_rec.prem_pay1 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;            
            
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code1 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay1 ;

            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 1 ;                
        end if;
              
        if c_rec.prem_code2 is not null and c_rec.prem_pay2 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                            
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code2 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay2 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 2;
        end if;
        if c_rec.prem_code3 is not null and c_rec.prem_pay3 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code3 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay3 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 3 ;
        end if;
        
        if c_rec.prem_code4 is not null and c_rec.prem_pay4 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code4 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay4 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 4 ;
        end if;        

        if c_rec.prem_code5 is not null and c_rec.prem_pay5 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code5 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay5 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 5 ;
        end if;                
        
        if c_rec.prem_code6 is not null and c_rec.prem_pay6 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code6 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay6 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 6 ;
        end if;        
        
        if c_rec.prem_code7 is not null and c_rec.prem_pay7 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code7 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay7 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 7 ;
        end if;        

        if c_rec.prem_code8 is not null and c_rec.prem_pay8 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code8 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay8 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 8 ;
        end if;       
        
        if c_rec.prem_code9 is not null and c_rec.prem_pay9 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code9 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay9 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 9 ;
        end if;         
        
        if c_rec.prem_code10 is not null and c_rec.prem_pay10 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code10 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay10 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 10 ;
        end if;        
        
        if c_rec.prem_code11 is not null and c_rec.prem_pay11 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code11 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay11 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 11 ;
        end if;
        
        if c_rec.prem_code12 is not null and c_rec.prem_pay12 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code12 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay12 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 12 ;
        end if;        
        
        if c_rec.prem_code13 is not null and c_rec.prem_pay13 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code13 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay13 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 13 ;
        end if;        
        
        if c_rec.prem_code14 is not null and c_rec.prem_pay14 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code14 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay14 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 14 ;
        end if;        
        
        if c_rec.prem_code15 is not null and c_rec.prem_pay15 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code15 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay15 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 15 ;
        end if;        
                
        if c_rec.prem_code16 is not null and c_rec.prem_pay16 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code16 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay16 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 16 ;
        end if;
        
        if c_rec.prem_code17 is not null and c_rec.prem_pay17 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code17 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay17 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 17 ;
        end if;        
                
        if c_rec.prem_code18 is not null and c_rec.prem_pay18 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code18 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay18 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 18 ;
        end if;
                
        if c_rec.prem_code19 is not null and c_rec.prem_pay19 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code19 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay19 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 19 ;
        end if;        
        
        if c_rec.prem_code20 is not null and c_rec.prem_pay20 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code20 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay20 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 20 ;
        end if;
        
        if c_rec.prem_code21 is not null and c_rec.prem_pay21 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code21 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay21 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 21 ;
        end if;        
        
        if c_rec.prem_code22 is not null and c_rec.prem_pay22 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code22 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay22 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 22 ;
        end if;        

        if c_rec.prem_code23 is not null and c_rec.prem_pay23 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code23 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay23 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 23 ;
        end if;                
        
        if c_rec.prem_code24 is not null and c_rec.prem_pay24 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code24 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay24 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 24 ;
        end if;        
        
        if c_rec.prem_code25 is not null and c_rec.prem_pay25 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec.prem_code25 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec.prem_pay25 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 25 ;
        end if;        
        
   END LOOP;
   --DBMS_OUTPUT.PUT_LINE('COUNT='||t_premcode.COUNT);
       
   cnt:=0;
   FOR I in 1..t_premcode.COUNT LOOP
        cnt := cnt+1;            
        --DBMS_OUTPUT.PUT_LINE('C1 CLMNO='||t_clmno(cnt)||' PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_amt(cnt));
         BEGIN   --NC_H_HISTORY_TMP  
            insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
            values (v_SID ,t_clmno(cnt) ,t_premcode(cnt) ,t_amt(cnt) ,'P');
                
         EXCEPTION
           WHEN  OTHERS THEN
           --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
           V_KEY := 0 ; 
           rollback;
         END;     
   END LOOP;

    t_premcode.DELETE;
    t_amt.DELETE;
    t_clmno.DELETE;
    t_premcol.DELETE;
       
/*
   t_clmno := DEFINE_CLMNO(); --create empty varray 
   t_premcode := DEFINE_PREMCODE(); --create empty varray 
   t_amt := DEFINE_AMT(); --create empty varray 
   t_premcol := DEFINE_PREMCOL(); --create empty varray      */   
   OPEN C2;
   LOOP
      FETCH C2 INTO C_REC2;
      EXIT WHEN C2%NOTFOUND;
        if c_rec2.prem_code1 is not null and c_rec2.prem_pay1 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;            
            
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code1 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay1 ;

            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 1 ;                
        end if;
              
        if c_rec2.prem_code2 is not null and c_rec2.prem_pay2 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                            
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code2 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay2 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 2;
        end if;
        if c_rec2.prem_code3 is not null and c_rec2.prem_pay3 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code3 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay3 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 3 ;
        end if;
        
        if c_rec2.prem_code4 is not null and c_rec2.prem_pay4 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code4 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay4 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 4 ;
        end if;        

        if c_rec2.prem_code5 is not null and c_rec2.prem_pay5 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code5 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay5 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 5 ;
        end if;                
        
        if c_rec2.prem_code6 is not null and c_rec2.prem_pay6 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code6 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay6 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 6 ;
        end if;        
        
        if c_rec2.prem_code7 is not null and c_rec2.prem_pay7 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code7 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay7 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 7 ;
        end if;        

        if c_rec2.prem_code8 is not null and c_rec2.prem_pay8 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code8 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay8 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 8 ;
        end if;       
        
        if c_rec2.prem_code9 is not null and c_rec2.prem_pay9 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code9 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay9 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 9 ;
        end if;         
        
        if c_rec2.prem_code10 is not null and c_rec2.prem_pay10 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code10 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay10 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 10 ;
        end if;        
        
        if c_rec2.prem_code11 is not null and c_rec2.prem_pay11 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code11 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay11 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 11 ;
        end if;
        
        if c_rec2.prem_code12 is not null and c_rec2.prem_pay12 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code12 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay12 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 12 ;
        end if;        
        
        if c_rec2.prem_code13 is not null and c_rec2.prem_pay13 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code13 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay13 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 13 ;
        end if;        
        
        if c_rec2.prem_code14 is not null and c_rec2.prem_pay14 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code14 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay14 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 14 ;
        end if;        
        
        if c_rec2.prem_code15 is not null and c_rec2.prem_pay15 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code15 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay15 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 15 ;
        end if;        
                
        if c_rec2.prem_code16 is not null and c_rec2.prem_pay16 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code16 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay16 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 16 ;
        end if;
        
        if c_rec2.prem_code17 is not null and c_rec2.prem_pay17 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code17 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay17 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 17 ;
        end if;        
                
        if c_rec2.prem_code18 is not null and c_rec2.prem_pay18 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code18 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay18 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 18 ;
        end if;
                
        if c_rec2.prem_code19 is not null and c_rec2.prem_pay19 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code19 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay19 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 19 ;
        end if;        
        
        if c_rec2.prem_code20 is not null and c_rec2.prem_pay20 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code20 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay20 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 20 ;
        end if;
        
        if c_rec2.prem_code21 is not null and c_rec2.prem_pay21 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code21 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay21 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 21 ;
        end if;        
        
        if c_rec2.prem_code22 is not null and c_rec2.prem_pay22 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code22 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay22 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 22 ;
        end if;        

        if c_rec2.prem_code23 is not null and c_rec2.prem_pay23 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code23 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay23 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 23 ;
        end if;                
        
        if c_rec2.prem_code24 is not null and c_rec2.prem_pay24 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code24 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay24 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 24 ;
        end if;        
        
        if c_rec2.prem_code25 is not null and c_rec2.prem_pay25 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := c_rec2.prem_code25 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := c_rec2.prem_pay25 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 25 ;
        end if;        
        
   END LOOP;

   cnt:=0;
   FOR I in 1..t_premcode.COUNT LOOP
        cnt := cnt+1;            
        --DBMS_OUTPUT.PUT_LINE('C2 CLMNO='||t_clmno(cnt)||' PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_amt(cnt));
         BEGIN   --NC_H_HISTORY_TMP  
            insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
            values (v_SID ,t_clmno(cnt) ,t_premcode(cnt) ,t_amt(cnt) ,'R');
         EXCEPTION
           WHEN  OTHERS THEN
           --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
           V_KEY := 0 ; 
           rollback;
         END;     
   END LOOP;
    t_premcode.DELETE;
    t_amt.DELETE;
    t_clmno.DELETE;
    t_premcol.DELETE;
              
   OPEN C4;
   LOOP
      FETCH C4 INTO C_REC4;
      EXIT WHEN C4%NOTFOUND;
        if C_REC4.prem_code1 is not null and C_REC4.prem_pay1 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;            
            
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code1 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay1 ;

            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 1 ;                
        end if;
              
        if C_REC4.prem_code2 is not null and C_REC4.prem_pay2 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                            
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code2 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay2 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 2;
        end if;
        if C_REC4.prem_code3 is not null and C_REC4.prem_pay3 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code3 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay3 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 3 ;
        end if;
        
        if C_REC4.prem_code4 is not null and C_REC4.prem_pay4 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code4 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay4 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 4 ;
        end if;        

        if C_REC4.prem_code5 is not null and C_REC4.prem_pay5 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code5 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay5 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 5 ;
        end if;                
        
        if C_REC4.prem_code6 is not null and C_REC4.prem_pay6 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code6 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay6 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 6 ;
        end if;        
        
        if C_REC4.prem_code7 is not null and C_REC4.prem_pay7 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code7 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay7 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 7 ;
        end if;        

        if C_REC4.prem_code8 is not null and C_REC4.prem_pay8 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code8 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay8 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 8 ;
        end if;       
        
        if C_REC4.prem_code9 is not null and C_REC4.prem_pay9 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code9 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay9 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 9 ;
        end if;         
        
        if C_REC4.prem_code10 is not null and C_REC4.prem_pay10 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code10 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay10 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 10 ;
        end if;        
        
        if C_REC4.prem_code11 is not null and C_REC4.prem_pay11 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code11 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay11 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 11 ;
        end if;
        
        if C_REC4.prem_code12 is not null and C_REC4.prem_pay12 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code12 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay12 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 12 ;
        end if;        
        
        if C_REC4.prem_code13 is not null and C_REC4.prem_pay13 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code13 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay13 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 13 ;
        end if;        
        
        if C_REC4.prem_code14 is not null and C_REC4.prem_pay14 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code14 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay14 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 14 ;
        end if;        
        
        if C_REC4.prem_code15 is not null and C_REC4.prem_pay15 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code15 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay15 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 15 ;
        end if;        
                
        if C_REC4.prem_code16 is not null and C_REC4.prem_pay16 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code16 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay16 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 16 ;
        end if;
        
        if C_REC4.prem_code17 is not null and C_REC4.prem_pay17 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code17 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay17 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 17 ;
        end if;        
                
        if C_REC4.prem_code18 is not null and C_REC4.prem_pay18 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code18 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay18 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 18 ;
        end if;
                
        if C_REC4.prem_code19 is not null and C_REC4.prem_pay19 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code19 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay19 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 19 ;
        end if;        
        
        if C_REC4.prem_code20 is not null and C_REC4.prem_pay20 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code20 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay20 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 20 ;
        end if;
        
        if C_REC4.prem_code21 is not null and C_REC4.prem_pay21 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code21 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay21 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 21 ;
        end if;        
        
        if C_REC4.prem_code22 is not null and C_REC4.prem_pay22 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code22 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay22 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 22 ;
        end if;        

        if C_REC4.prem_code23 is not null and C_REC4.prem_pay23 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code23 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay23 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 23 ;
        end if;                
        
        if C_REC4.prem_code24 is not null and C_REC4.prem_pay24 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code24 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay24 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 24 ;
        end if;        
        
        if C_REC4.prem_code25 is not null and C_REC4.prem_pay25 is not null then
            t_clmno.EXTEND(1);
            t_clmno(t_clmno.LAST) := C_REC4.clm_no ;      
                  
            t_premcode.EXTEND(1);
            t_premcode(t_premcode.LAST) := C_REC4.prem_code25 ;
                        
            t_amt.EXTEND(1);
            t_amt(t_amt.LAST) := C_REC4.prem_pay25 ;
                
            t_premcol.EXTEND(1);
            t_premcol(t_premcol.LAST) := 25 ;
        end if;        
        
   END LOOP;

   cnt:=0;
   FOR I in 1..t_premcode.COUNT LOOP
        cnt := cnt+1;            
        --DBMS_OUTPUT.PUT_LINE('C2 CLMNO='||t_clmno(cnt)||' PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_amt(cnt));
         BEGIN   --NC_H_HISTORY_TMP  
            insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
            values (v_SID ,t_clmno(cnt) ,t_premcode(cnt) ,t_amt(cnt) ,'R');
         EXCEPTION
           WHEN  OTHERS THEN
           --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
           V_KEY := 0 ; 
           rollback;
         END;     
   END LOOP;

    t_premcode.DELETE;
    t_amt.DELETE;
    t_clmno.DELETE;
    t_premcol.DELETE;
       
   OPEN C3;
   LOOP
      FETCH C3 INTO C_REC3;
      EXIT WHEN C3%NOTFOUND;
         BEGIN   --NC_H_HISTORY_TMP  
            insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
            values (v_SID ,c_rec3.clm_no , c_rec3.prem_code ,c_rec3.res_amt ,'X');
         EXCEPTION
           WHEN  OTHERS THEN
           --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
           V_KEY := 0 ; 
           rollback;
         END;              
   END LOOP;

   OPEN C5;
   LOOP
      FETCH C5 INTO C_REC5;
      EXIT WHEN C5%NOTFOUND;
         BEGIN   --NC_H_HISTORY_TMP  
            insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
            values (v_SID ,C_REC5.clm_no , C_REC5.prem_code ,C_REC5.res_amt ,'X');
         EXCEPTION
           WHEN  OTHERS THEN
           --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
           V_KEY := 0 ; 
           rollback;
         END;              
   END LOOP;
                    
   COMMIT;        
       
    BEGIN  -- check found
           
       SELECT max(PREM_CODE) into v_Tmp1
       FROM   NC_H_HISTORY_TMP
       WHERE   SID = V_SID
       AND ROWNUM=1;              
          
    EXCEPTION
      WHEN  NO_DATA_FOUND THEN
        V_KEY :=0 ;
      WHEN  OTHERS THEN
        V_KEY :=0 ;
    END;   -- end check found
        
    IF   nvl(v_Tmp1,'N') <> 'N' THEN              
        commit;
        V_KEY := v_SID ;
    ELSE
        V_KEY :=0 ;
    END IF;
        
END;         --END GET_HISTORY_ALL     

PROCEDURE REMOVE_HISTORY_CLAIM (V_KEY IN NUMBER) IS
    
BEGIN
    BEGIN  -- check found
           
       DELETE   NC_H_HISTORY_TMP
       WHERE   SID = V_KEY ;              
          
    EXCEPTION
      WHEN  OTHERS THEN
        null ;
    END;   -- end check found        
        
    COMMIT;
END; --END REMOVE_HISTORY_CLAIM  

FUNCTION CONVERT_CLM_STATUS(vSTATUS IN VARCHAR2) RETURN VARCHAR2 IS    
    
BEGIN
    IF vSTATUS  in ('MEDSTS00','MEDSTS01','MEDSTS03','MEDSTS11')  THEN
        --return GET_CLM_STATUS_DESC(vSTATUS ,1 ) ;
        return 'Pending';
    ELSIF vSTATUS  in ('MEDSTS31','MEDSTS32')  THEN
        --return GET_CLM_STATUS_DESC(vSTATUS ,1 ) ;
        return 'Cancel';        
    ELSIF substr(vSTATUS , 1,6) = 'MEDSTS' THEN -- อื่นๆ นอกจากการเปิดเคลมบน MED 
        return NC_HEALTH_PACKAGE.GET_CLM_STATUS_DESC(vSTATUS ,1 ) ;
    ELSE
        IF vSTATUS in ('0','1') THEN
            --return 'เปิดเคลม';
            return 'Pending';
        ELSIF vSTATUS in ('6') THEN
            --return 'พิจารณาจ่ายเคลม';
            return 'Draft Paid';
        ELSIF vSTATUS in ('2') THEN
            --return 'ปิดเคลม (จ่าย)';
            return 'Approved';
        ELSIF vSTATUS in ('3') THEN
            --return 'ปิดเคลม (ไม่จ่าย)';
            return 'Rejected(CWP)';
        ELSIF vSTATUS in ('4') THEN
            --return 'reOpen claim';
            return 'Pending';
        ELSE
            return vSTATUS;
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        return vSTATUS;
END;    -- END CONVERT_CLM_STATUS 

FUNCTION GET_PAYEEDETAIL(vPayee_code IN VARCHAR2 , vPayee_Seq IN NUMBER ,vType IN NUMBER) RETURN VARCHAR2 IS   -- vType 0 = NAME ,1 = Address                
    vReturn     VARCHAR2(1000);
BEGIN
    IF vType = 0 THEN
        select name_th into vReturn
        from acc_payee_detail
        where payee_code =vPayee_code and payee_seq = vPayee_Seq   ;
        return vReturn ;
    ELSIF vType = 1 THEN
        select contact_name||' '||addr1_th||' '||addr2_th into vReturn
        from acc_payee_detail
        where payee_code =vPayee_code and payee_seq = vPayee_Seq   ;
        return vReturn ;    
    ELSE
        return '';
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        return '';
    WHEN OTHERS THEN
         return '';
END; -- GET_PAYEEDETAIL

FUNCTION IS_NEWACR_ACTIVATE(p_sys IN VARCHAR2) RETURN BOOLEAN IS -- True = on   
    v_sw    VARCHAR2(10);
BEGIN
    select remark into v_sw
    from clm_constant a
    where key = 'ACR'||p_sys||'_SWITCH' ;
    
    IF v_sw = 'ON' THEN
        return true;
    ELSE
        return false;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        return false;
    WHEN OTHERS THEN
        return false;
END IS_NEWACR_ACTIVATE;       

FUNCTION IS_AGENT_CHANNEL(p_clmno IN VARCHAR2  ,p_payee IN VARCHAR2) RETURN BOOLEAN IS
    v_sw    VARCHAR2(10);
    v_payee_type VARCHAR2(10);
    tmp_agent   VARCHAR2(20);
    xrem   VARCHAR2(20);
    v_polno VARCHAR2(20);
    v_polrun    number;
    v_agtch boolean:=false;
BEGIN
    begin
        select pol_no ,pol_run
        into  v_polno ,v_polrun
        from mis_clm_mas
        where clm_no = p_clmno;
    exception
    when no_data_found then
        null;
    when others then
        null;
    end;
    
    begin
        select channel , agent_code||agent_seq into v_sw ,tmp_agent
        from mis_mas a
        where pol_no = v_polno and pol_run = v_polrun;
    exception
    when no_data_found then
        null;
    when others then
        null;
    end;    

    BEGIN 
        select remark into xrem
        from clm_constant
        where key like 'AGTEMAILCH%'             
        and v_sw = remark; 
            
        v_agtch := true;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_agtch := false;
        WHEN OTHERS THEN
            v_agtch := false;
   END;    
                       
    IF v_agtch THEN  -- filter CB Agent Broker
--    IF 1=1 THEN  -- cancel check Chanel criteria
        BEGIN 
            select payee_type into v_payee_type
            from acc_payee
            where payee_code = p_payee ;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                null;
            WHEN OTHERS THEN
                null;
       END;      
       if v_payee_type = '06' then -- จ่ายโรงพยาบาล
        return false;
       else  
        return true;
       end if;
               
    ELSE
        BEGIN 
            select remark into xrem
            from clm_constant
            where key like 'BROKERINRETAIL%' 
            and remark = tmp_agent  ;
            
            return true;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                null;
            WHEN OTHERS THEN
                null;
       END;           
        return false;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        return false;
    WHEN OTHERS THEN
        return false;
END IS_AGENT_CHANNEL;      

PROCEDURE GET_AGENT_CONTACT(p_clmno  IN VARCHAR2 , o_contact_name OUT VARCHAR2 , o_addr1 OUT VARCHAR2  , o_addr2 OUT VARCHAR2  , o_mobile OUT VARCHAR2  , o_email OUT VARCHAR2)  IS
    v_agent_code varchar2(20);
    v_agent_seq varchar2(10);
    tmp_email   varchar2(150);
    v_polno varchar2(20);
    v_polrun    number;
BEGIN

    BEGIN 
        select pol_no ,pol_run
        into v_polno ,v_polrun
        from mis_clm_mas
        where clm_no = p_clmno ;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            null;
        WHEN OTHERS THEN
            null;
   END;    
    BEGIN        
        select agent_code ,agent_seq 
        into v_agent_code ,v_agent_seq
        from mis_mas a
        where  pol_no = v_polno and pol_run =v_polrun 
        and end_seq in (select max(end_seq) from  mis_mas aa where  pol_no =a.pol_no and pol_run =a.pol_run )
        and rownum=1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            null;
        WHEN OTHERS THEN
            null;
   END;    
   
   account.p_actr_package.get_producer_addr_dist(v_agent_code, v_agent_seq , '07' ,'T' ,
                                                o_contact_name, o_addr1,o_addr2 );
                                                
    o_email := account.p_actr_package.get_producer_email_dist(v_agent_code,v_agent_seq,'07');   
    
    o_mobile := account.p_actr_package.get_producer_sms_dist (v_agent_code,v_agent_seq,'07');       
    
    IF o_email is null THEN -- user dummy email
        BEGIN 
            select remark into tmp_email
            from clm_constant
            where key like 'NC_DUMMYEMAIL%' ;
            
            o_email := tmp_email;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                null;
            WHEN OTHERS THEN
                null;
       END;        
    END IF;                                   

END GET_AGENT_CONTACT;    

PROCEDURE GET_HOSPITAL_CONTACT(p_payee_code  IN VARCHAR2 ,p_payee_seq  IN NUMBER ,TH_ENG IN VARCHAR2 , o_contact_name OUT VARCHAR2 , o_addr1 OUT VARCHAR2  , o_addr2 OUT VARCHAR2  , o_mobile OUT VARCHAR2  , o_email OUT VARCHAR2)  IS
    v_payeetype varchar2(100);
    tmp_email   varchar2(150);
BEGIN

    BEGIN
        select payee_type
        into v_payeetype
        from acc_payee a
        where  payee_code = p_payee_code ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        null;
    WHEN OTHERS THEN
        null;
    END;
    
   IF v_payeetype = '06' THEN -- Hospital    
        BEGIN 
            select contact_name ,addr1_th ,addr2_th ,e_mail ,mobile_sms 
            into o_contact_name , o_addr1 ,o_addr2 , o_email,o_mobile 
            from acc_payee_detail a
            where  a.payee_code not in (select x.payee_code from acc_payee x where cancel is not null)
            and  payee_code = p_payee_code
            and payee_seq = nvl(p_payee_seq,1) 
            and cancel_flag is null ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                null;
            WHEN OTHERS THEN
                null;
       END;

        IF o_email is null THEN -- user dummy email
            BEGIN 
                select remark into tmp_email
                from clm_constant
                where key like 'NC_DUMMYEMAIL%' ;
                
                o_email := tmp_email;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    null;
                WHEN OTHERS THEN
                    null;
           END;        
        END IF;            
   ELSE -- customer and others
        BEGIN 
            select nvl(contact_name,title||' '||name) contact_name ,addr1 ,addr2 ,e_mail ,mobile_sms 
            into o_contact_name , o_addr1 ,o_addr2 , o_email,o_mobile 
            from acc_payee a
            where   payee_code = p_payee_code
            and cancel is null ;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                null;
            WHEN OTHERS THEN
                null;
       END;   
   END IF;
   
END GET_HOSPITAL_CONTACT;

FUNCTION GET_ORG_CUSTOMER_EMAIL(p_clmno  IN VARCHAR2)  RETURN VARCHAR2 IS
    v_cuscode   varchar2(200);
    v_email   varchar2(200);
BEGIN
        IF IS_AGENT_CHANNEL(p_clmno , '') THEN
            return null;    
        END IF;
        
        BEGIN 
            select cus_code 
            into v_cuscode
            from mis_mas a
            where (a.pol_no ,a.pol_run) in (select x.pol_no ,x.pol_run from mis_clm_mas x where clm_no =p_clmno)
            and end_seq in (select max(end_seq) from  mis_mas aa where  pol_no =a.pol_no and pol_run =a.pol_run )
            and rownum=1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                null;
            WHEN OTHERS THEN
                null;
       END;   
        BEGIN 
             select email into v_email
             from cust_commerce a
             where cus_code = v_cuscode
              and rownum=1;
              
              return v_email;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                null;
            WHEN OTHERS THEN
                null;
       END;        
       
       return null;  
END GET_ORG_CUSTOMER_EMAIL;
    
FUNCTION VALIDATE_PAYEE_NAME (v_clm_no varchar2 ,v_payee_code varchar2 ,v_payee_name varchar2 ,v_payee_type varchar2 ,o_rst OUT VARCHAR2) RETURN BOOLEAN IS                        
    p_payee_name varchar2(200);
    p_payee_purename varchar2(200);
    v_title varchar2(10);
    v_payeetype varchar2(10);
    v_name  varchar2(200);
    v_purename varchar2(200);
    p_paytype   varchar2(10);
    v_payee varchar2(20);
BEGIN
    IF NC_CLNMC908.GET_PRODUCTID(v_clm_no) = 'GM' THEN 
        IF v_payee_type in ('01') THEN
            p_paytype := 'H';
        ELSIF v_payee_type in ('15') THEN
            p_paytype := 'I' ;
        ELSIF v_payee_type in ('16') THEN
            p_paytype := 'O';
        ELSE
            p_paytype := v_payee_type;
        END IF;
    ELSIF NC_CLNMC908.GET_PRODUCTID(v_clm_no) = 'PA' THEN
    IF v_payee_type in ('1') THEN
            p_paytype := 'H';
        ELSIF v_payee_type in ('2') THEN
            p_paytype := 'I' ;
        ELSIF v_payee_type in ('3') THEN
            p_paytype := 'O';
        ELSE
            p_paytype := v_payee_type;
        END IF;    
    END IF; 

    IF p_paytype = 'I' THEN -- insure
        BEGIN
            SELECT title||' '||name, name INTO p_payee_name ,p_payee_purename
            FROM ACC_PAYEE
            WHERE PAYEE_CODE = v_payee_code;
            
            select mas_cus_enq ,replace(mas_cus_enq ,'คุณ','') x ,substr(mas_cus_enq ,1,3) title into v_name ,v_purename ,v_title
            from mis_clm_mas
            where clm_no = v_clm_no ;
            
            if v_title = 'คุณ' then
                if replace(p_payee_purename,' ','') <> replace(v_purename,' ','') then
                    o_rst := 'InsureName('||v_name||') <> '||v_payee_name ;
                    return false;            
                else
                    return true;
                end if;                   
            else
                if replace(v_name,' ','') <> replace(v_payee_name,' ','') then
                    o_rst := 'InsureName('||v_name||') <> '||v_payee_name ;
                    return false;            
                else
                    return true;
                end if;            
            end if;
            

        EXCEPTION
            WHEN no_data_found THEN
                    o_rst := 'InsureName('||v_name||') <> '||v_payee_name ;
                    return false;
            WHEN others THEN
                    o_rst := 'InsureName('||v_name||') <> '||v_payee_name ;
                    return false;
        END;                                    
    ELSIF p_paytype = 'H' THEN  -- Hospital
               -- -- bypass alway TRUE ;; user request for cancel validate Hospital Name @10-SEP-14
              BEGIN 
                    SELECT title||' '||name , payee_type INTO v_name ,v_payeetype
                    FROM ACC_PAYEE
                    WHERE PAYEE_CODE = v_payee_code;
--                    dbms_output.put_line('v_name='||v_name||' v_payee_name='||v_payee_name);
                    
                    if v_payeetype <> '06' then -- ไม่ใช่สถานพยาบาล
                        o_rst := 'รายการ Payee ('||v_payee_name||') ไม่ใช่สถานพยาบาล ' ;
                        return false;                      
                    end if;
                    
                    if replace(v_name,' ','') <> replace(v_payee_name,' ','') then
                        o_rst := 'Hospital Name('||v_name||') <> '||v_payee_name ;
                        return false;            
                    else
                        return true;
                    end if; 
                EXCEPTION
                WHEN no_data_found THEN
                        o_rst := 'Hospital Name('||v_name||') <> '||v_payee_name ;
                        return false;
                WHEN others THEN
                        o_rst := 'Hospital Name('||v_name||') <> '||v_payee_name ;
                        return false;
            END;     
--        IF NC_CLNMC908.GET_PRODUCTID(v_clm_no) = 'GM' THEN        
--            BEGIN
--                select nvl(name,title) name  into v_name 
--                from payee_std                
--                where payee_code in (
--                    select hpt_code from clm_medical_res x where x.clm_no = v_clm_no
--                    and x.state_seq in (select max(xx.state_seq) from clm_medical_res xx where xx.clm_no = x.clm_no group by x.clm_no) and rownum=1
--                ) ;             
--                if replace(v_name,' ','') <> replace(v_payee_name,' ','') then
--                    o_rst := 'Hospital Name('||v_name||') <> '||v_payee_name ;
--                    return false;            
--                else
--                    return true;
--                end if;
--            EXCEPTION
--                WHEN no_data_found THEN
--                        begin 
--                            select payee_name into v_name
--                            from clm_outservice_mas
--                            where not_no in (select out_clm_no from mis_clm_mas where clm_no =v_clm_no )
--                            and payee_name is not null ;
--
--                            if replace(v_name,' ','') <> replace(v_payee_name,' ','') then
--                                o_rst := 'Hospital Name('||v_name||') <> '||v_payee_name ;
--                                return false;            
--                            else
--                                return true;
--                            end if;
--                                                            
--                        exception
--                            when no_data_found then
--                                o_rst := 'Hospital Name('||v_name||') <> '||v_payee_name ;
--                                return false;                                
--                            when others then
--                                o_rst := 'Hospital Name('||v_name||') <> '||v_payee_name ;
--                                return false;                                
--                        end;
--                WHEN others THEN
--                        o_rst := 'Hospital Name('||v_name||') <> '||v_payee_name ;
--                        return false;
--            END;                
--        ELSIF NC_CLNMC908.GET_PRODUCTID(v_clm_no) = 'PA' THEN   
--            begin 
--                select payee_code ,name_th  into v_payee ,v_name
--                from acc_payee_detail                
--                where (payee_code,payee_seq) in (
--                    select hpt_code , hpt_seq from mis_cpa_res x where x.clm_no = v_clm_no  
--                    and x.revise_seq in (select max(xx.revise_seq) from mis_cpa_res xx where xx.clm_no = x.clm_no group by x.clm_no) and rownum=1
--                ) ;   
--                
--                if v_payee <> v_payee_code then
--                    o_rst := 'Hospital Name('||v_name||') <> '||v_payee_name ;
--                    return false;    
--                else
--                    return true;
--                end if;
--                                                            
--            exception
--                when no_data_found then
--                    o_rst := 'Hospital Name('||v_name||') <> '||v_payee_name ;
--                    return false;                                
--                when others then
--                    o_rst := 'Hospital Name('||v_name||') <> '||v_payee_name ;
--                    return false;                                
--            end;            
--        END IF;
    ELSIF p_paytype = 'O' THEN   -- broker
            BEGIN
                select title||' '||name_th  into v_name 
                from agent_std
                where agent_code in (select agent_code from mis_clm_mas where clm_no = v_clm_no)
                and agent_seq  in (select agent_seq from mis_clm_mas where clm_no =v_clm_no) ;
                
                if replace(v_name,' ','') <> replace(v_payee_name,' ','') then
                    o_rst := 'Broker Name('||v_name||') <> '||v_payee_name ;
                    return false;            
                else
                    return true;
                end if;
            EXCEPTION
                WHEN no_data_found THEN
                        o_rst := 'Broker Name('||v_name||') <> '||v_payee_name ;
                        return false;
                WHEN others THEN
                        o_rst := 'Broker Name('||v_name||') <> '||v_payee_name ;
                        return false;
            END;          
    END IF;
    
    return true;

END VALIDATE_PAYEE_NAME;

FUNCTION VALIDATE_MOBILE(v_no IN VARCHAR2) RETURN BOOLEAN IS

BEGIN
    return true;
END VALIDATE_MOBILE;
    
FUNCTION VALIDATE_EMAIL(v_mail IN VARCHAR2) RETURN BOOLEAN  IS

BEGIN
    if v_mail = 'xxx' then
        return false;
    else
        return true;
    end if;
END VALIDATE_EMAIL;    

FUNCTION GET_COUNT_ACCNO(p_payee IN VARCHAR2) RETURN NUMBER IS
    cnt_acc number(5);
BEGIN
    select count(*) cnt into cnt_acc
    from acc_payee_account_detail x
    where payee_code =    p_payee ;
    
    return cnt_acc;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        return 0;
    WHEN OTHERS THEN
        return 0;
END GET_COUNT_ACCNO;

FUNCTION IS_USD_POLICY(i_polno IN VARCHAR2 ,i_polrun IN NUMBER) RETURN BOOLEAN IS
    x_curr varchar2(10);
BEGIN
    begin
        select curr_code into x_curr
        from mis_mas a
        where  pol_no = i_polno and pol_run =i_polrun
        and end_seq in (select max(aa.end_seq) from mis_mas aa where aa.pol_no = a.pol_no and aa.pol_run = a.pol_run);
    exception
        when no_data_found then
            x_curr := null;
        when others then
            x_curr := null;
    end;              
        
    if x_curr = 'USD' then
        return true;
    else
        return false;
    end if;
END IS_USD_POLICY;    

FUNCTION IS_CASH_PAYMENT(i_clmno IN VARCHAR2 ,i_payno IN VARCHAR2 ,i_prod IN VARCHAR2) RETURN BOOLEAN IS
    v_found varchar2(10);
BEGIN
    IF i_prod = 'PA' THEN
        begin
            select 'found' into v_found
            from mis_clm_payee
            where clm_no = i_clmno and pay_no = i_payno
            and settle = '1' and rownum=1;
        exception
            when no_data_found then
                v_found := null;
            when others then
                v_found := null;
        end;            
    ELSIF i_prod = 'GM' THEN
        begin
            select 'found' into v_found
            from clm_gm_payee
            where clm_no = i_clmno and pay_no = i_payno
            and settle = '1' and rownum=1;
        exception
            when no_data_found then
                v_found := null;
            when others then
                v_found := null;
        end;      
        if   v_found is null then   -- case data error on outsource paid program set null in mis_clm_payee.settle
            begin
                select 'found' into v_found
                from mis_clmgm_paid
                where clm_no = i_clmno and pay_no = i_payno
                and settle = '1' and rownum=1;
            exception
                when no_data_found then
                    v_found := null;
                when others then
                    v_found := null;
            end;            
        end if;
    END IF;      
        
    if v_found is not null then
        return true;
    else
        return false;
    end if;
END IS_CASH_PAYMENT;    

PROCEDURE email_alert_cash(i_clmno IN VARCHAR2 , i_payno IN VARCHAR2) IS
    v_to varchar2(1000);
    v_cc varchar2(1000);
    v_bcc varchar2(1000);
    v_from varchar2(50):= 'BKI_MED_ADMIN@bangkokinsurance.com' ; 
    v_dbins varchar2(10);
    x_body varchar2(1000);
    x_subject varchar2(1000);
    v_logrst varchar2(200);
    v_clmmen_name varchar2(200);
    v_apprv_name  varchar2(200);
    v_approve_date  varchar2(200);
BEGIN
--ALLCLM.NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail Bancas' ,'Start: '||v_body ,v_logrst);
    FOR X in (
    select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail ,(select UPPER(substr(instance_name,1,8)) instance_name from v$instance) ins_name
    from nc_med_email a
    where module = 'ALERTCASH' 
    and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
    and direction = 'TO' and CANCEL is null 
    ) LOOP
    v_to := v_to || x.ldap_mail ||';' ;
    v_dbins := x.ins_name ; -- get DB Instant 
    END LOOP;
 
    FOR X2 in (
    select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail 
    from nc_med_email a
    where module = 'ALERTCASH' 
    and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
    and direction = 'CC' and CANCEL is null 
    ) LOOP
    v_cc := v_cc || x2.ldap_mail ||';' ;
    END LOOP; 

    FOR X3 in (
    select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail 
    from nc_med_email a
    where module = 'ALERTCASH' 
    and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
    and direction = 'BCC' and CANCEL is null 
    ) LOOP
    v_bcc := v_bcc || x3.ldap_mail ||';' ;
    END LOOP; 

    begin           
      select  P_claim_send_mail.get_bkiuser_name(a.clm_men) ,P_claim_send_mail.get_bkiuser_name(a.approve_id) ,to_char(approve_date, 'DD-MON-YYYY HH24:MI:SS') 
        into   v_clmmen_name ,v_apprv_name ,v_approve_date
        from nc_payment a     
      where a.clm_no = i_clmno     
          and a.pay_no = i_payno     
          and a.trn_seq = (select max(b.trn_seq)     
                                      from nc_payment b     
                                   where a.clm_no = b.clm_no     
                                      and a.pay_no = b.pay_no);   
                                                                       
    exception     
      when no_data_found then 
        null;
      when others then     
        null;     
    end;    
    
--    x_body := '<h2>'||v_subject||'</h2></br>'; 
--    x_body := x_body||v_body; 
--    x_subject := v_subject||' ['||v_dbins||'] ' ; 

    x_subject := 'เตือน! มีอนุมัติจ่ายเคลมเงินสด claim no: '||i_clmno ; 
    x_body := '<h2>'||x_subject||'</h2></br>'; 
    x_body := x_body||'เลขเคลม : '||i_clmno||'  เลขจ่าย : '||i_payno||'</br>'||
    'มีการอนุมัติจ่ายเงินสด ซึ่งอนุมัติโดย '||'คุณ '||v_apprv_name||'</br>'||
    'เมื่อวันที่ '||v_approve_date||'</br>'|| 
    'กรุณาตรวจสอบ ก่อนข้อมูลถูกส่งไปการเงินช่วงกลางคืน'; 
    
     
    if v_to is not null then
    ALLCLM.nc_health_package.generate_email(v_from, v_to ,
    x_subject, 
    x_body 
    ,v_cc
    ,v_bcc); 
    end if;
--NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail Bancas' ,'END' ,v_logrst);
EXCEPTION
WHEN OTHERS THEN
NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail alert cash' ,'Error: '||sqlerrm ,v_logrst);
END email_alert_cash; 

FUNCTION SET_CARDNO(v_clmno in varchar2 ,v_user in varchar2 ,v_id_type in varchar2,v_id_no in varchar2 ,v_oth_type in varchar2 ,v_oth_no in varchar2
,rst out varchar2) RETURN BOOLEAN IS
    max_seq number(5);
BEGIN
    max_seq := 1;
    begin
        select  nvl(max(seq),0)+1 into max_seq
        from paph_card_history
        where clm_no = v_clmno;    
    exception
        when no_data_found then
            max_seq := 1;
        when others then
            max_seq := 1;
    end;
    
    for x in (
        select CARD_ID_TYPE,CARD_ID_NO  ,CARD_OTHER_TYPE  ,CARD_OTHER_NO ,CARD_UPDATEDATE
        from mis_clm_mas
        where clm_no = v_clmno
    )loop
        insert into paph_card_history (CLM_NO ,SEQ ,CARD_ID_TYPE ,CARD_ID_NO ,CARD_OTHER_TYPE ,CARD_OTHER_NO 
        ,CARD_UPDATEDATE ,UPDATED_BY)
        values 
        (v_clmno ,max_seq , x.CARD_ID_TYPE, x.CARD_ID_NO  , x.CARD_OTHER_TYPE  ,x.CARD_OTHER_NO
        ,x.CARD_UPDATEDATE ,v_user );        
    end loop; 
    
    update mis_clm_mas
    set CARD_ID_TYPE = v_id_type
    ,CARD_ID_NO  = v_id_no
    ,CARD_OTHER_TYPE  = v_oth_type
    ,CARD_OTHER_NO = v_oth_no
    ,CARD_UPDATEDATE = sysdate
    where clm_no = v_clmno;
    
    commit;
    
    --dbms_output.put_line('complete : clm_no='||v_clmno);
    return true;
EXCEPTION
    WHEN OTHERS THEN
        rst := 'error :'||sqlerrm;
        rollback;
        return false;
END SET_CARDNO;

FUNCTION GET_CARDNO(v_polno in varchar2  ,v_polrun in number ,v_fleet in number,v_recpt in number 
,v_cuscode in varchar2 ,v_cusseq in number ,v_name in varchar2 ,v_clmno in varchar2 ,v_payno in varchar2) RETURN varchar2 IS
    rst varchar2(100);
    v_sys   varchar2(10);
    v_prodtype  varchar2(5);
BEGIN
    if v_clmno is null and (v_polno is not null and v_polrun is not null) then
        begin
            select sysid into v_sys
            from clm_grp_prod a
            where a.prod_type in (
                select x.prod_type from bkiquery x where x.pol_no = v_polno and x.pol_run = v_polrun
            ) ;
        exception 
            when no_data_found then
                v_sys :=null;
            when others then
                v_sys := null;
        end;                
    else
        v_sys := NC_HEALTH_PAID.GET_PRODUCT(v_clmno);
    end if;
    --dbms_output.put_line('clm_no='||v_clmno||' sys: '||v_sys);
    if v_sys = 'PA' then
        begin
            select id into rst
            from mis_pa_prem
            where pol_no= v_polno
            and pol_run = v_polrun
            and fleet_seq = v_fleet
            and recpt_seq = nvl(v_recpt ,1) ;
        exception 
            when no_data_found then
                rst :=null;
            when others then
                rst := null;
        end;
        
        if rst is null then -- find in Payee Data
            begin
                select personal_id   into rst
                from acc_payee a
                where payee_code in (
                select trunc(x.payee_code) from mis_clm_payee x where 
                clm_no = v_clmno
                and pay_no like nvl(v_payno ,'%') 
                and payee_code is not null
                and rownum=1
                );                                    
            exception 
                when no_data_found then
                    rst :=null;
                when others then
                    rst := null;
            end;    
        end if;
        
    elsif v_sys = 'GM' then
        begin
            select decode(id_card,null,id_no,id_card) newid
            into rst
            from pa_medical_det 
            where pol_no= v_polno
            and pol_run = v_polrun
            and fleet_seq = v_fleet and end_seq = 0 ; 
        exception 
            when no_data_found then
                rst :=null;
            when others then
                rst := null;
        end;

        if rst is null then -- find in Payee Data
            begin
                select personal_id   into rst
                from acc_payee a
                where payee_code in (
                select trunc(x.payee_code) from clm_gm_payee x where 
                clm_no = v_clmno
                and pay_no like nvl(v_payno ,'%') 
                and payee_code is not null
                and rownum=1                
                );                                    
            exception 
                when no_data_found then
                    rst :=null;
                when others then
                    rst := null;
            end;    
        end if;        
        
    end if;

    return rst;
EXCEPTION
    WHEN OTHERS THEN
        rst := '';
        return rst;
END GET_CARDNO;

FUNCTION GET_PRODUCT(v_clmno in varchar2)    RETURN VARCHAR2 IS
    rst varchar2(20);
    v_prodtype  varchar2(10);
BEGIN
    SELECT PROD_TYPE into v_prodtype
    FROM MIS_CLM_MAS
    WHERE CLM_NO = v_clmno;
    
    SELECT SYSID    INTO rst
    FROM CLM_GRP_PROD
    WHERE prod_type =v_prodtype ;   
    
    return rst;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        rst := '';
        return rst;
    WHEN OTHERS THEN
        rst := '';
        return rst;
END GET_PRODUCT;

PROCEDURE FIX_LETTNO(vClmNo in varchar2 ,vPayNo in varchar2) IS

    vProd_type  varchar2(20):='';
    vLETT_PRT  varchar2(20);
    vLett_no  varchar2(20);
    is_cashcall boolean:=false;
    v_polyr varchar2(4);
    v_clmyr varchar2(4);
    o_cashcall  varchar2(5);
    o_line  float;
BEGIN
    begin
        select clm_yr ,pol_yr ,prod_type  into v_clmyr ,v_polyr ,vProd_type
        from mis_clm_mas
        where clm_no  =vClmno;
    exception
    when no_data_found then
        v_polyr := to_char(sysdate,'yyyy');
        v_clmyr := to_char(sysdate,'yyyy');
        vProd_type := '';
    when others then
        v_polyr := to_char(sysdate,'yyyy');
        v_clmyr := to_char(sysdate,'yyyy');  
        vProd_type := '';
    end;       
          
    for x in (
        select a.*
        from mis_cri_paid a
        where clm_no = vClmno and pay_no =   vPayNo                                                                                                                                                                                                     
        and corr_seq = (select max(corr_seq) from mis_cri_paid where pay_no = a.pay_no)
        order by clm_no ,pay_no ,corr_seq    
    )loop
           IF x.RI_TYPE = '1' THEN
               is_cashcall := false;           
                              
               nmtr_package.nc_get_cashcall(v_polyr,v_clmyr,
                               x.ri_code ,x.ri_br_code ,x.lf_flag ,x.ri_type ,x.ri_sub_type ,
                               x.pay_amt , 1,
                               o_cashcall , o_line);
               
               IF o_cashcall is not null THEN
                  vLETT_PRT := 'Y';
                  vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);               
               ELSE
                  vLETT_PRT := 'N';             
               END IF;                               
            ELSIF x.RI_TYPE = '0' THEN
                  vLETT_PRT := 'Y';
                  vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
            ELSE
                  vLETT_PRT := 'N';
            END IF;       
            
            if vLETT_PRT = 'Y' and x.lett_no is null then
                update mis_cri_paid
                set lett_prt = vLETT_PRT ,lett_no = vLett_no ,lett_type = 'L' 
                where pay_no = x.pay_no and corr_seq = x.corr_seq
                and RI_TYPE = x.ri_type and ri_code =x.ri_code and ri_br_code = x.ri_br_code and ri_sub_type = x.ri_sub_type;
                dbms_output.put_line('update pay_no :'||x.pay_no||' RI_TYPE ='||x.ri_type||' ri_amt='||x.pay_amt||' lett_no='||vLett_no);
                commit;
            elsif vLETT_PRT = 'N' and x.lett_prt = 'Y' then
                update mis_cri_paid
                set lett_prt = vLETT_PRT ,lett_no = vLett_no ,lett_type = 'L' 
                where pay_no = x.pay_no and corr_seq = x.corr_seq
                and RI_TYPE = x.ri_type and ri_code =x.ri_code and ri_br_code = x.ri_br_code and ri_sub_type = x.ri_sub_type;
                dbms_output.put_line('update lettPrt pay_no :'||x.pay_no||' RI_TYPE ='||x.ri_type||' ri_amt='||x.pay_amt||' lett_prt='||vLETT_PRT);    
                commit;            
            end if;
    end loop;
    
EXCEPTION
    WHEN OTHERS THEN
        rollback;    
END FIX_LETTNO;

FUNCTION CHECK_LSA(vPayNo in varchar2) Return VARCHAR2 IS
    rst varchar2(100);
    v_LettNo    varchar2(20);
BEGIN
    select lett_no into v_LettNo
    from mis_cri_paid a
    where pay_no = vPayNo
    and corr_seq in (select max(aa.corr_seq) from mis_cri_paid aa where aa.pay_no = a.pay_no)
    and lett_no is not null and rownum=1;
    
    rst := v_LettNo;
    
    return rst;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        rst := '';
        return rst;
    WHEN OTHERS THEN
        rst := '';
        return rst;
END CHECK_LSA;

END NC_HEALTH_PAID;
/
