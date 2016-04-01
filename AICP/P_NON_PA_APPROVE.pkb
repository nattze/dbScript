CREATE OR REPLACE PACKAGE BODY P_NON_PA_APPROVE AS
/******************************************************************************
 NAME: AICP.P_NON_PA_APPROVE
 PURPOSE: For Approve Non PA Claim 

 REVISIONS:
 Ver Date Author Description
 --------- ---------- --------------- ------------------------------------
 1.0 3/10/2014 2702 1. Created this package.
******************************************************************************/
FUNCTION GET_PRODUCT_TYPE(i_pol_no IN VARCHAR2 ,i_pol_run IN NUMBER) RETURN VARCHAR2 IS
 vProd VARCHAR2(10);
BEGIN
 select prod_type into vProd
 from mis_mas
 where pol_no = i_pol_no and pol_run = i_pol_run and end_seq=0 ;
 
 return vProd;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 return null;
 WHEN OTHERS THEN
 return null;
END GET_PRODUCT_TYPE;

FUNCTION GET_PRODUCTGROUP(vProdtype IN VARCHAR2) RETURN VARCHAR2 IS
 vProd VARCHAR2(10);
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
END GET_PRODUCTGROUP;

FUNCTION GET_SUBGROUP(vProdtype IN VARCHAR2) RETURN VARCHAR2 IS
 vProd VARCHAR2(10);
BEGIN
 select prod_key into vProd
 from clm_grp_prod
 where prod_type = vProdtype ;
 
 return vProd;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 return null;
 WHEN OTHERS THEN
 return null;
END GET_SUBGROUP;

FUNCTION GET_CLMSTS(in_clmno IN VARCHAR2) RETURN VARCHAR2 IS
 v_return varchar2(20);
 v_status varchar2(20);
BEGIN
 BEGIN
 select clm_sts into v_status
 from nc_mas
 where clm_no = in_clmno ;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 v_status := null;
 WHEN OTHERS THEN
 v_status := null;
 END;


 CASE
 WHEN v_status = 'NCCLMSTS01' THEN v_return := '6'; -- Pending
 WHEN v_status = 'NCCLMSTS02' THEN v_return := '2'; -- Close
 WHEN v_status = 'NCCLMSTS03' THEN v_return := '3'; -- CWP
 WHEN v_status = 'NCCLMSTS04' THEN v_return := '4'; -- ReOpen
 ELSE v_return := v_status;
 END CASE; 
 
 return v_return;
EXCEPTION
 WHEN OTHERS THEN
 return null;
END GET_CLMSTS; 

FUNCTION GET_APPRVSTATUS_DESC(vStatus IN VARCHAR2) RETURN VARCHAR2 IS
 v_desc varchar2(200);
BEGIN
 begin
 select descr into v_desc
 from clm_constant a
 where key = vStatus;
 exception
 when no_data_found then
 v_desc := 'Not found status desc.';
 when others then
 dbms_output.put_line('error'||sqlerrm);
 v_desc := 'Not found status desc.';
 end; 
 return v_desc;
END GET_APPRVSTATUS_DESC; 

FUNCTION GET_PRODUCTID(vProdtype IN VARCHAR2) RETURN VARCHAR2 IS
 vProd VARCHAR2(10);
BEGIN
 select sysid into vProd
 from clm_grp_prod
 where prod_type = vProdtype ;
 
 vProd := 'NMC';
 return vProd;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 return null;
 WHEN OTHERS THEN
 return null;
END GET_PRODUCTID;

FUNCTION GET_CTRL_PAGE_ACCUM_AMT(i_clmno IN varchar2 ,i_payno IN varchar2) RETURN NUMBER IS
 v_return number:=0;
BEGIN

 BEGIN
 select sum(payee_amt) into v_return
 from nc_payee c
 where clm_no = i_clmno
-- and pay_no = i_payno 
 and c.trn_seq in (select max(cc.trn_seq) from nc_payee cc where cc.clm_no = c.clm_no and cc.pay_no = c.pay_no)
 ;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 v_return := 0; 
 WHEN OTHERS THEN
 v_return := 0; 
 END;

 return v_return; 
END GET_CTRL_PAGE_ACCUM_AMT;

FUNCTION GET_CTRL_PAGE_PAYEE_AMT(i_clmno IN varchar2 ,i_payno IN varchar2) RETURN NUMBER IS
 v_return number:=0;
BEGIN

 BEGIN
 select sum(payee_amt) into v_return
 from nc_payee c
 where clm_no = i_clmno
 and pay_no = i_payno 
 and c.trn_seq in (select max(cc.trn_seq) from nc_payee cc where cc.clm_no = c.clm_no and cc.pay_no = c.pay_no)
 ;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 v_return := 0; 
 WHEN OTHERS THEN
 v_return := 0; 
 END;

 return v_return; 
END GET_CTRL_PAGE_PAYEE_AMT;

FUNCTION GET_CTRL_PAGE_PAYEE_NAME(i_clmno IN varchar2 ,i_payno IN varchar2) RETURN VARCHAR2 IS
 v_return varchar2(250);
BEGIN

 BEGIN
 select min(payee_name) into v_return
 from nc_payee c
 where clm_no = i_clmno
 and pay_no = i_payno 
 and c.trn_seq in (select max(cc.trn_seq) from nc_payee cc where cc.clm_no = c.clm_no and cc.pay_no = c.pay_no)
 and payee_type = '01' and payee_seq =1
 ;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 v_return := null; 
 WHEN OTHERS THEN
 v_return := null; 
 END;

 return v_return; 
END GET_CTRL_PAGE_PAYEE_NAME;

FUNCTION GET_CTRL_PAGE_RES_AMT(i_clmno IN varchar2) RETURN NUMBER IS
 v_return number:=0;
BEGIN

 BEGIN
 select sum(res_amt) into v_return
 from nc_reserved a
 where clm_no = i_clmno
 and a.trn_seq = (select max(aa.trn_seq) from nc_reserved aa where aa.clm_no = a.clm_no)
 ;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 v_return := 0; 
 WHEN OTHERS THEN
 v_return := 0; 
 END;

 return v_return; 
END GET_CTRL_PAGE_RES_AMT;

PROCEDURE GET_APPROVE_USER(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_apprv_id OUT varchar2 ,o_apprv_sts OUT varchar2) IS

BEGIN
 BEGIN
 select approve_id ,pay_sts into o_apprv_id ,o_apprv_sts
 from nc_payment_apprv xxx
 where 
 xxx.clm_no = i_clmno and pay_no = i_payno and 
 type = '01' and sub_type = '01' and 
 xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no
 and type = '01' and sub_type = '01' ); 
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 o_apprv_id := null; o_apprv_sts := null;
 WHEN OTHERS THEN
 o_apprv_id := null; o_apprv_sts := null;
 END; 
END GET_APPROVE_USER;

FUNCTION CAN_SEND_APPROVE(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_rst OUT varchar2) RETURN BOOLEAN IS
 v_f1 varchar2(20):=null;
 v_return boolean;
BEGIN
 begin
 select pay_sts into v_f1
 from nc_payment_apprv xxx
 where 
 xxx.clm_no = i_clmno and pay_no = i_payno and 
 xxx.pay_sts in ('NONPASTSAPPRV02','NONPASTSAPPRV05') and 
 type = '01' and sub_type = '01' and 
 xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no
 and type = '01' and sub_type = '01' );
 o_rst := 'Claim in on waiting for Approve' ; 
 v_return := false; 
 exception
 when no_data_found then
 v_f1 := null;
 v_return := true;
 when others then
 dbms_output.put_line('error'||sqlerrm);
 o_rst := 'error'||sqlerrm ; 
 v_return := false;
 end;
 
 if v_f1 is null then
 begin
 select pay_sts into v_f1
 from nc_payment_apprv xxx
 where 
 xxx.clm_no = i_clmno and pay_no = i_payno and 
 xxx.pay_sts in ('NONPASTSAPPRV03') and 
 type = '01' and sub_type = '01' and 
 xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no
 and type = '01' and sub_type = '01' );
 o_rst := 'Claim was approved' ; 
 v_return := false; 
 exception
 when no_data_found then
 v_f1 := null;
 v_return := true;
 when others then
 dbms_output.put_line('error'||sqlerrm);
 o_rst := 'error'||sqlerrm ; 
 v_return := false;
 end; 
 end if;
 
-- o_rst := null;
 return v_return;
END CAN_SEND_APPROVE; 

FUNCTION CAN_GO_APPROVE(i_clmno IN varchar2 ,i_payno IN varchar2 ,i_userid IN varchar2 ,i_status IN varchar2 ,o_rst OUT varchar2) RETURN BOOLEAN IS
 v_return boolean:=true;
 v_apprv_id varchar2(10);
 v_sts varchar2(20);
 v_found varchar2(20);
BEGIN

 BEGIN
 select key into v_found
 from clm_constant a
 where key like 'NONPASTSAPPRV%'
 and key = i_status
-- and (remark2 is not null or remark2 = 'APPRV')
 and remark2 is not null;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 v_found := null;
 WHEN OTHERS THEN
 v_found := null;
 END; 
 
 IF v_found is not null THEN
-- o_rst := 'สถานะงานไม่อยู่ในการขออนุมัติ !';
 o_rst := 'Claim was not Send Approve Status !'; 
 v_return := false;
 END IF;
 
 IF v_return THEN
 AICP.P_NON_PA_APPROVE.GET_APPROVE_USER(i_clmno ,i_payno ,v_apprv_id ,v_sts );
 IF v_apprv_id <> i_userid THEN
-- o_rst := 'งานนี้เป็นของรหัส '||v_apprv_id ||' เป็นผู้อนุมัติ !';
 o_rst := 'This Claim is waiting for '||v_apprv_id ||' Approve !';
 v_return := false; 
 END IF;
 END IF;
 
-- o_rst := null;
 return v_return;
END CAN_GO_APPROVE;
 
FUNCTION UPDATE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2 
,v_apprv_flag IN varchar2 ,v_user IN varchar2 ,v_amd_user IN varchar2 ,v_apprv_user IN varchar2 ,v_res_amt IN NUMBER ,v_rst OUT VARCHAR2) RETURN boolean IS
 v_max_seq number:=1;
 m_prodgrp varchar2(10);
 m_prodtype varchar2(10);
 m_curr_code varchar2(10);
 m_curr_rate number(5,2);
 dummy_payno varchar2(20);
 v_apprv_date date;
BEGIN
 if v_sts in ('NONPASTSAPPRV03') then
 v_apprv_date := sysdate;
 else
 v_apprv_date := null;
 end if;
 BEGIN
 select nvl(max(trn_seq),0) + 1 into v_max_seq
 from nc_payment_apprv a
 where sts_key = v_key and pay_no = v_payno
 and type = '01' and sub_type = '01' ;
 exception
 when no_data_found then
 v_max_seq := 1;
 when others then
 v_max_seq := 1;
 END;

 FOR X1 in (
 select prod_grp ,prod_type ,curr_code ,curr_rate
 from nc_mas a
 where sts_key = v_key 
 ) 
 LOOP 
 m_prodgrp := x1.prod_grp ;
 m_prodtype := x1.prod_type ;
 m_curr_code := x1.curr_code;
 m_curr_rate := x1.curr_rate; 
 END LOOP;
 
 INSERT into nc_payment_apprv(clm_no ,pay_no ,clm_seq ,trn_seq ,Pay_sts ,pay_amt ,Trn_amt ,Curr_code ,Curr_rate 
 ,Sts_date ,Amd_date ,Clm_men ,Amd_user, APPROVE_ID ,approve_date , Prod_grp ,Prod_type ,SUBSYSID ,Sts_key ,Sub_type ,Type ,apprv_flag) 
 VALUES (v_clmno , v_payno ,1 ,v_max_seq, v_sts ,v_res_amt ,v_res_amt,
 m_curr_code, m_curr_rate ,sysdate ,sysdate ,v_user ,v_amd_user ,v_apprv_user ,v_apprv_date
 ,m_prodgrp,m_prodtype, GET_PRODUCTID(m_prodtype) ,v_key ,'01' ,'01' ,v_apprv_flag) ; 
 
 COMMIT;
 return true;
 
EXCEPTION
 WHEN OTHERS THEN
 v_rst := 'error insert ncpayment:'||sqlerrm; 
 ROLLBACK;
 return false; 
END UPDATE_NCPAYMENT;

FUNCTION APPROVE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2 ,v_apprv_user IN varchar2 
,v_rst OUT VARCHAR2) RETURN boolean IS

-- v_max_seq number:=1;
-- m_prodgrp varchar2(10);
-- m_prodtype varchar2(10);
-- m_curr_code varchar2(10);
-- m_curr_rate number(5,2);
-- dummy_payno varchar2(20);
 v_apprv_date date;
 v_cnt number:=0;
 v_return boolean;
BEGIN
 if v_sts in ('NONPASTSAPPRV03' ,'NONPASTSAPPRV04' ,'NONPASTSAPPRV06') then
 v_apprv_date := sysdate;
 else
 v_apprv_date := null;
 end if;
 
 FOR C1 in (
 select clm_no ,pay_no ,clm_seq ,trn_seq ,PAY_STS ,approve_id ,pay_amt ,trn_amt ,curr_code ,curr_rate 
 ,sts_date ,clm_men ,prod_grp ,prod_type ,subsysid ,STS_KEY ,print_type ,type ,sub_type ,apprv_flag
 from nc_payment_apprv a
 where sts_key = v_key and pay_no = v_payno
 and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no) 
 ) 
 LOOP 
 v_cnt := v_cnt+1; 
 INSERT INTO nc_payment_apprv
 (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
 STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
 SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG )
 VALUES
 (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 , v_sts, c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
 c1.STS_DATE, sysdate, c1.CLM_MEN, v_apprv_user , v_apprv_user ,v_apprv_date , c1.PROD_GRP, c1.PROD_TYPE, 
 c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ); 
 
 END LOOP; 
 
 IF v_cnt > 0 THEN
 COMMIT;
 --========== Step Post ACR , RSL 
 IF v_sts in ('NONPASTSAPPRV03' ) THEN --Approve 
 IF not POST_MISC(v_clmno, v_payno , v_apprv_user,v_rst) THEN --POST ACR
 delete nc_payment_apprv a
 where sts_key = v_key and pay_no = v_payno
 and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no); 
 COMMIT; 
 
 return false;
 END IF; 
-- nmtr_package.clm_post_rsl(p_state_no => :p_state_no); 
 IF not nmtr_package.clm_post_rsl( v_payno ) THEN --POST RSL
 delete nc_payment_apprv a
 where sts_key = v_key and pay_no = v_payno
 and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no); 
 COMMIT; 
 v_rst := 'Process failed on Post RSL !!'; 
 return false;
 END IF; 
 END IF; 
 --========== end Step Post ACR , RSL 
 return true;
 ELSE
-- v_rst := 'ไม่พบข้อมูลการอนุมัติ!';
 v_rst := 'Not found data for Approve!!'; 
 return false; 
 END IF;

EXCEPTION
 WHEN OTHERS THEN
 v_rst := 'error APPROVE_NCPAYMENT:'||sqlerrm; 
 ROLLBACK;
 return false; 
END APPROVE_NCPAYMENT;

FUNCTION APPROVE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2 ,v_apprv_user IN varchar2 ,v_remark IN varchar2 
,v_rst OUT VARCHAR2) RETURN boolean IS 
 
-- v_max_seq number:=1; 
-- m_prodgrp varchar2(10); 
-- m_prodtype varchar2(10); 
-- m_curr_code varchar2(10); 
-- m_curr_rate number(5,2); 
-- dummy_payno varchar2(20); 
 v_apprv_date date; 
 v_prod_type varchar2(10); 
 v_err_message varchar2(200); 
 v_cnt number:=0; 
BEGIN 
 if v_sts in ('NONPASTSAPPRV03' ,'NONPASTSAPPRV04' ,'NONPASTSAPPRV06') then 
 v_apprv_date := sysdate; 
 else 
 v_apprv_date := null; 
 end if; 
 
 FOR C1 in ( 
 select clm_no ,pay_no ,clm_seq ,trn_seq ,PAY_STS ,approve_id ,pay_amt ,trn_amt ,curr_code ,curr_rate 
 ,sts_date ,clm_men ,prod_grp ,prod_type ,subsysid ,STS_KEY ,print_type ,type ,sub_type ,apprv_flag 
 from nc_payment_apprv a 
 where sts_key = v_key and pay_no = v_payno 
 and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no) 
 ) 
 LOOP 
 v_cnt := v_cnt+1; 
 v_prod_type := c1.PROD_TYPE; 
 INSERT INTO nc_payment_apprv 
 (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
 STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
 SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG, REMARK ) 
 VALUES 
 (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 , v_sts, c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
 c1.STS_DATE, sysdate, c1.CLM_MEN, v_apprv_user , v_apprv_user ,v_apprv_date , c1.PROD_GRP, c1.PROD_TYPE, 
 c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG, v_remark ); 
 
 END LOOP; 
 dbms_output.put_line('after insert NC_PAYMENT_APPRV: '||v_sts);
 IF v_cnt > 0 THEN 
 COMMIT; 
-- EMAIL_NOTICE_APPRV(v_clmno ,v_payno ,v_sts); 
 if v_sts in ('NONPASTSAPPRV03') then -- When Approve Convert to BKIAPP 
 IF not P_NON_PA_CLM_PAYMENT.update_end_payment(v_clmno, v_payno , v_sts ,v_rst) THEN
 dbms_output.put_line('error update_end_payment false: '||v_rst); 
 return false; 
 END IF;
 
 IF not POST_MISC(v_clmno, v_payno , v_apprv_user,v_rst) THEN --POST ACR
 delete nc_payment_apprv a
 where sts_key = v_key and pay_no = v_payno
 and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no); 
 COMMIT; 
 dbms_output.put_line('in POST_MISC false: '||v_rst); 
 return false;
 END IF; 
 dbms_output.put_line('after POST_MISC');
-- nmtr_package.clm_post_rsl(p_state_no => :p_state_no); 
 IF not nmtr_package.clm_post_rsl( v_payno ) THEN --POST RSL
 delete nc_payment_apprv a
 where sts_key = v_key and pay_no = v_payno
 and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no); 
 COMMIT; 
 v_rst := 'Process failed on Post RSL !!'; 
 dbms_output.put_line('in clm_post_rsl false: '||v_rst); 
 return false;
 END IF; 
 dbms_output.put_line('after clm_post_rsl');
 end if; 
 
 return true; 
 ELSE 
-- v_rst := 'ไม่พบข้อมูลการอนุมัติ!'; 
 v_rst := 'Not found data for Approve!!'; 
 return false; 
 END IF; 
 dbms_output.put_line('finish APPROVE+POST ');
EXCEPTION 
 WHEN OTHERS THEN 
 v_rst := 'error APPROVE_NCPAYMENT:'||sqlerrm; 
 ROLLBACK; 
 return false; 
END APPROVE_NCPAYMENT; 

FUNCTION GET_BATCHNO(vType IN VARCHAR2) RETURN VARCHAR2 IS -- vType D , B 
 b_no varchar2(20); 
 vKey varchar2(50); 
 m_rst varchar2(100); 
BEGIN 
 IF nvl(vType , 'D' ) = 'D' THEN 
 vKey := 'CPADRAFT'||to_char(sysdate,'yyyy'); 
 ELSIF nvl(vType , 'D' ) = 'GD' THEN 
 vKey := 'GMDRAFT'||to_char(sysdate,'yyyy'); 
 ELSIF nvl(vType , 'D' ) = 'GB' THEN 
 vKey := 'CMSBATCH'||to_char(sysdate,'yyyy'); 
 ELSIF nvl(vType , 'D' ) = 'MI' THEN
 vKey := 'MISBATCH'||to_char(sysdate,'yyyy'); 
 ELSE 
 vKey := 'CPABATCH'||to_char(sysdate,'yyyy'); 
 END IF; 
 
 BEGIN 
 select run_no+1 into b_no 
 from clm_control_std 
 where key = vKey; 
 EXCEPTION 
 WHEN NO_DATA_FOUND THEN 
 b_no := null; 
 return null; 
-- NC_HEALTH_PACKAGE.WRITE_LOG ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'GET_BATCHNO' ,'not found key! :: '||vkey, 
-- m_rst) ; 
 WHEN OTHERs THEN 
-- NC_HEALTH_PACKAGE.WRITE_LOG ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'GET_BATCHNO' ,'error key! :: '||vkey||' '||sqlerrm, 
-- m_rst) ; 
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

FUNCTION VALIDATE_INDV(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
 CURSOR c_clm IS select clm_no ,prod_type,GET_CLMSTS(clm_no) clm_sts from nc_mas 
 where clm_no = vClmNo; 
 c_rec c_clm%ROWTYPE; 
 
 v_chk Boolean:=false; 
 --v_pay_no varchar2(20); 
BEGIN 
 
 OPEN c_clm; 
 LOOP 
 FETCH c_clm INTO c_rec; 
 EXIT WHEN c_clm%NOTFOUND; 
 
 if c_rec.clm_sts in ('3') then 
 P_RST := c_rec.clm_no||': was Closed or Printed Statement already! CLM_STS='||c_rec.clm_sts ; 
 return false; 
 elsif c_rec.clm_sts not in ('6','7','2','4') then 
 P_RST := c_rec.clm_no||': Does not make payment! CLM_STS='||c_rec.clm_sts ; 
 return false; 
-- elsif c_rec.clm_sts not in ('2') then 
-- P_RST := c_rec.clm_no||': was Closed! CLM_STS='||c_rec.clm_sts ; 
-- return false; 
 end if; 
 
-- if IS_FOUND_BATCH(c_rec.clm_no ,vPayNo ,P_RST ) then -- Case Batch Print 
-- 
-- return false; 
-- end if; 
 
 END LOOP; 
 CLOSE c_clm; 
 v_chk:= true; 
 return v_chk; 
END VALIDATE_INDV; 

FUNCTION UPDATE_STATUS(v_payno in varchar2 ,v_clm_user in varchar2 ) RETURN VARCHAR2 IS 
 v_sts_seq number:=0; 
 v_sts_seq_m number:=0; 
 v_trn_seq number:=0; 
 chk_success boolean:=false; 
 v_stskey number(20); 
 v_chk_med varchar2(20):=null; 
BEGIN 
 BEGIN 
 select sts_key into v_stskey 
 from nc_payment xxx 
 where pay_no = v_payno 
 and xxx.trn_seq = (select max(b.trn_seq) from nc_payment b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no) 
 and rownum=1; 
 exception 
 when no_data_found then 
 v_stskey := 0; 
 when others then 
 v_stskey := 0; 
 --display_proc(sqlerrm); 
 END; 
 
 
 BEGIN 
 select max(sts_seq) + 1 into v_sts_seq 
 from nc_status a 
 where sts_key = v_stskey and STS_TYPE = 'NCPAYSTS' ; 
 exception 
 when no_data_found then 
 v_sts_seq := 1; 
 when others then 
 v_sts_seq := 1; 
 END; 
 
 BEGIN 
 select max(sts_seq) + 1 into v_sts_seq_m 
 from nc_status a 
 where sts_key = v_stskey and STS_TYPE = 'MEDSTS' ; 
 exception 
 when no_data_found then 
 v_sts_seq_m := 1; 
 when others then 
 v_sts_seq_m := 1; 
 END; 
 
 BEGIN 
 select clm_no into v_chk_med 
 from nc_mas a 
 where sts_key = v_stskey; 
 exception 
 when no_data_found then 
 v_chk_med := null; 
 when others then 
 v_chk_med := null; 
 END; 
 
/**/ 
 BEGIN 
 select max(trn_seq) + 1 into v_trn_seq 
 from nc_payment a 
 where sts_key = v_stskey and pay_no = v_payno ; 
 exception 
 when no_data_found then 
 v_trn_seq := 1; 
 when others then 
 v_trn_seq := 1; 
 END; 
 
 BEGIN 
-- INSERT INTO NC_STATUS -- Approve 
-- (STS_KEY, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE) 
-- VALUES 
-- (v_stskey ,v_sts_seq ,'NCPAYSTS', 'NCPAYSTS03' ,'Approve by NC_HEALTH_PAID' , v_clm_user ,sysdate); 
 
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
 (v_stskey ,v_sts_seq+2 ,'NCPAYSTS', 'NCPAYSTS10' ,'Printed Statement by NC_HEALTH_PAID' , v_clm_user ,sysdate); 
 
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
 
-- INSERT INTO NC_PAYMENT 
-- (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
-- STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
-- SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG) 
-- VALUES 
-- (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,'NCPAYSTS03' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
-- c1.STS_DATE, sysdate, c1.CLM_MEN, :global.user_id , c1.APPROVE_ID ,sysdate , c1.PROD_GRP, c1.PROD_TYPE, 
-- c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ); 
 
 INSERT INTO NC_PAYMENT 
 (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
 STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
 SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG ,SETTLE_DATE ) 
 VALUES 
 (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,'NCPAYSTS05' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
 c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , c1.APPROVE_ID ,sysdate , c1.PROD_GRP, c1.PROD_TYPE, 
 c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ,sysdate); 
 
 INSERT INTO NC_PAYMENT 
 (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
 STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
 SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG ,SETTLE_DATE ) 
 VALUES 
 (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+2 ,'NCPAYSTS09' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
 c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , c1.APPROVE_ID ,sysdate , c1.PROD_GRP, c1.PROD_TYPE, 
 c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ,sysdate); 
 
 INSERT INTO NC_PAYMENT 
 (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
 STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
 SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG ,SETTLE_DATE ) 
 VALUES 
 (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+3 ,'NCPAYSTS10' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
 c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , c1.APPROVE_ID ,sysdate , c1.PROD_GRP, c1.PROD_TYPE, 
 c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ,sysdate); 
 
 
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

FUNCTION POST_MISC(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
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
 V_SAL_TOTAL number; 
 V_PAY_TOTAL number;
 V_SUM_SAL number:=0;
 V_SUM_PAY number:=0;
 V_SUM_DEC number:=0;
 V_SUM_REC number:=0; 
 V_SUM_PAYEE number:=0;
 
 CNT_P number:=0;
 V_CLASSx varchar2(10); 
 V_CLASS varchar2(10); 
 V_PREM_OFFSET varchar2(1);
 v_less_other varchar2(2);
 cnt number;
 v_chk_adv boolean:=false;
 v_part varchar2(5000);
 v_pay_total_paid number:=0;

 M_SEND_TITLE varchar2(100); 
 M_SEND_ADDR1 varchar2(200); 
 M_SEND_ADDR2 varchar2(200); 
 M_PAYEE_CODE varchar2(20); 
 M_PAYEE_NAME varchar2(200); 
 M_PAY_NO varchar2(20); 
 
 V_agentcode varchar2(5); 
 v_agentseq varchar2(2); 
-- V_CLM_STS varchar2(2);
BEGIN 
 if NOT validate_indv(vClmNo , vPayNo ,P_RST) then 
 return false; 
 end if; 
 
 dbms_output.put_line('pass validate_indv!');
 
 b1 := GET_BATCHNO('MI'); 

 
 dbms_output.put_line('b1 = '||b1); 
 --======= Step Insert Data ======== 
 for c_rec in ( 
-- select a.clm_no ,a.pol_no ,a.pol_run ,nvl(a.policy_number,a.pol_no||a.pol_run) policy_number ,a.prod_grp ,a.prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,a.channel ,clm_men ,a.clm_sts 
-- from mis_clm_mas a ,mis_clm_mas_seq d 
-- where a.clm_no = d.clm_no 
-- and a.clm_no = vClmNo 
-- and d.corr_seq = (select max(x.corr_seq) from mis_clm_mas_seq x where x.clm_no = d.clm_no) 
-- and a.clm_sts in ('6','7') and d.close_date is null 
 select a.clm_no ,a.pol_no ,a.pol_run ,a.end_seq ,a.pol_no||a.pol_run policy_number ,a.prod_grp ,a.prod_type 
 ,t_e th_eng ,mas_cus_code cus_code ,'' agent_code ,'' agent_seq ,'01' br_code 
 ,a.channel ,clm_user clm_men ,AICP.P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) clm_sts 
 from nc_mas a
 where a.clm_no = vClmNo
 and AICP.P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) in ('6','7','2','4')
 ) 
 loop 
 dbms_output.put_line('in c_rec = '||vClmNo); 
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

    begin 
        select agent_code , agent_seq into V_agentcode, V_agentseq 
        from mis_mas 
        where pol_no = c_rec.pol_no and pol_run = c_rec.pol_run and end_seq = c_rec.end_seq ; 
    exception 
    when no_data_found then 
        V_agentcode:=null; 
        V_agentseq :=null; 
    when others then 
        V_agentcode:=null; 
        V_agentseq :=null; 
    end; 
     
-- for p1 in (select a.pay_no ,pay_seq ,pay_date ,payee_amt ,pay_total ,0 rec_total ,0 disc_total ,replace(payee_code,' ','') payee_code ,a.pay_curr_code ,a.pay_curr_rate
-- from mis_clm_paid a, mis_clm_payee b 
-- where a.clm_no = b.clm_no 
-- and a.pay_no = b.pay_no 
-- and a.pay_no = vPayno 
-- and a.clm_no = c_rec.clm_no 
-- and pay_seq = (select max(e.pay_seq) from mis_clm_payee e where e.pay_no = b.pay_no ) 
-- and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b 
-- where b.pay_no = a.pay_no 
-- group by b.pay_no) 
-- ) 
 for p1 in (
 select a.pay_no ,0 pay_seq ,null pay_date 
 ,0 payee_amt ,sum(pay_amt) pay_total ,0 rec_total ,0 disc_total ,'' payee_code 
 ,min(curr_code) pay_curr_code ,min(curr_rate) pay_curr_rate
 from nc_payment a
 where a.pay_no = vPayno
 and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no)
 and type like 'NCNATTYPECLM%'
 group by pay_no 
 )
 loop 
 dbms_output.put_line('in p1 = '||vPayno); 
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
 
 V_agentcode /* P_agent_code IN acc_clm_tmp.agent_code%type */, 
 
 V_agentseq /* P_agent_seq IN acc_clm_tmp.agent_seq%type */, 
 
 c_rec.clm_men /* P_Postby IN acc_clm_tmp.post_by%type */, 
 
 c_rec.br_code /* P_brn_code IN acc_clm_tmp.brn_code%type */, 
 
 inw_type /* P_inw_type IN acc_clm_tmp.inw_type%type */, 
 
 null /* P_batch_no IN acc_clm_tmp.batch_no%type */, 
 
 v_dept_id /* P_dept_id IN acc_clm_tmp.dept_id%type */, 
 
 v_div_id /* P_div_id IN acc_clm_tmp.div_id%type */, 
 
 v_team_id /* P_team_id IN acc_clm_tmp.team_id%type */, 
 
 v_result /* P_msg Out varchar2*/); 
 
 if v_result is not null then rollback; P_RST:= v_result||' in P_CLAIM_ACR.Post_acc_clm_tmp'; return false; end if; 
 
 
 dbms_output.put_line('pass Post acc tmp!'); 
-- for p5 in (select tot_res res_amt 
-- from mis_clm_mas a 
-- where a.clm_no = c_rec.clm_no) 
-- loop 
-- v_RES_AMT := p5.res_amt; 
-- end loop; 
 
 Begin 
 select sum(nvl(a.res_amt,0)) 
 into v_RES_AMT 
 from nc_reserved a 
 where a.clm_no = c_rec.clm_no 
 and a.type like 'NCNATTYPECLM%' 
 and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq) 
 from nc_reserved b 
 where b.clm_no = a.clm_no 
 and b.type like 'NCNATTYPECLM%' 
 group by b.clm_no); 
 exception 
 when no_data_found then 
 v_RES_AMT := 0; 
 when others then 
 v_RES_AMT := 0; 
 End; 
 
-- for p3 in (select a.payee_code ,pay_seq ,payee_amt ,prem_offset ,payee_offset ,payee_offset2 
-- from mis_clm_payee a 
-- where a.clm_no = c_rec.clm_no 
-- ) 
 for p3 in (
 select payee_code ,payee_seq pay_seq ,payee_amt ,'' prem_offset ,'' payee_offset ,'' payee_offset2 
 ,salvage_flag ,deduct_flag ,salvage_amt ,deduct_amt ,payee_type
 from nc_payee b
 where b.pay_no = p1.pay_no
 and b.trn_seq in (select max(bb.trn_seq) from nc_payee bb where bb.clm_no =b.clm_no and bb.pay_no = b.pay_no) 
 ) 
 loop 
 v_DEDUCT_AMT := 0; 
 V_REC_TOTAL := 0;
 V_SAL_TOTAL := 0; 
 v_chk_adv := false;
 
 CNT_P := CNT_P +1;
 v_ADV_AMT := 0; 
 V_PAY_TOTAL := p3.payee_amt ;
 V_PREM_OFFSET := p3.PREM_OFFSET;
 IF V_PREM_OFFSET is not null THEN v_less_other := '01'; END IF;

 V_SUM_SAL := 0;
 V_SUM_PAY := 0;
 V_SUM_DEC := 0;

 Begin 
 select sum(payee_amt)
 into V_SUM_PAYEE
 from nc_payee b
 where b.pay_no = p1.pay_no
 and b.trn_seq in (select max(bb.trn_seq) from nc_payee bb where bb.clm_no =b.clm_no and bb.pay_no = b.pay_no) ; 
 exception 
 when no_data_found then   
                         V_SUM_PAYEE := 0;   
                      when  others  then   
                         V_SUM_PAYEE := 0;   
                End;      

--===========**CALULATE Deduct Salvage **===========   
                for p_cms in ( select A.CLM_NO ,A.PAY_NO , a.PAY_AMT PAY_AMT,a.sub_type
                    from nc_mas x , nc_payment a 
                    where a.clm_no = x.clm_no 
                    and a.pay_no =vPayno
                    and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no)                    
                )
                loop
                    if p_cms.sub_type like  'NCNATSUBTYPECLM%' then
                        V_SUM_PAY := V_SUM_PAY + p_cms.PAY_AMT;
                    elsif p_cms.sub_type like  'NCNATSUBTYPESAL%' then
                        V_SUM_SAL := V_SUM_SAL + p_cms.PAY_AMT;
                    elsif p_cms.sub_type like  'NCNATSUBTYPEDED%' then
                        V_SUM_DEC := V_SUM_DEC + p_cms.PAY_AMT;
                    elsif p_cms.sub_type like  'NCNATSUBTYPEREC%' then
                        V_SUM_REC := V_SUM_REC + p_cms.PAY_AMT;                            
                    end if;
                end loop;       
                    
                IF p3.salvage_flag = '1' THEN --P
                    --v_DEDUCT_AMT := p_cms.deduct_amt;    
                    V_REC_TOTAL := V_SUM_REC;
                    V_SAL_TOTAL := V_SUM_SAL;  
                ELSIF p3.salvage_flag = '2' THEN --M     
                    --v_DEDUCT_AMT := p_cms.deduct_amt * -1;    
                    V_REC_TOTAL := V_SUM_REC * -1;   
                    V_SAL_TOTAL := V_SUM_SAL * -1;  
                ELSE
                    V_REC_TOTAL := 0;
                    V_SAL_TOTAL :=0;
                END IF;       
                             
                IF p3.deduct_flag = '1' THEN --P
                    v_DEDUCT_AMT := V_SUM_DEC;    
                ELSIF p3.deduct_flag = '2' THEN --M
                    v_DEDUCT_AMT := V_SUM_DEC * -1;                    
                ELSE       
                    v_DEDUCT_AMT := 0;                      
                END IF;        
                
                if v_chk_adv = false then
                    IF p3.payee_type = '01' THEN
                        v_ADV_AMT := V_SUM_PAYEE - (V_SUM_PAY - V_SUM_SAL - V_SUM_DEC);
                        if v_ADV_AMT <> 0 then
                            v_chk_adv := true;
                        end if;
                    END IF;
                end if;
--===========**CALULATE Deduct Salvage **===========   
                             
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
                          
                P_CLAIM_ACR.Post_acc_clm_payee_tmp_misc( c_rec.prod_grp /* P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type */,  
                    
                c_rec.prod_type /* P_prod_type  IN  acc_clm_payee_tmp.prod_type%type */,
                                                                
                p1.pay_no /* P_payno      IN  acc_clm_payee_tmp.payment_no%type */,
                                                                
                p3.pay_seq /* P_seq        IN  acc_clm_payee_tmp.seq%type */,
                                                                
                '01' /* P_doc_type   IN  acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
                                                                
                p1.pay_curr_code /* P_curr_code  IN  acc_clm_payee_tmp.curr_code%type */,
                                                                
                p1.pay_curr_rate /* P_booking_rate  IN  acc_clm_payee_tmp.booking_rate%type */, 
                                                                
                V_PAY_TOTAL /* P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type */,
                                                                
                p3.payee_code /* P_payee_code IN  acc_clm_payee_tmp.payee_code%type */,
                                                                
                v_title /* P_title      IN  acc_clm_payee_tmp.title%type */,
                                                                
                v_name /* P_name       IN  acc_clm_payee_tmp.name%type */, 
                                                                
                '04' /* P_dept_no    IN  acc_clm_payee_tmp.dept_no%type */,
                                                                
                null /* P_batch_no   IN  acc_clm_payee_tmp.batch_no%type */,
                                                                
                nvl(v_DEDUCT_AMT,0) /* P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type */,
                                                                
                v_ADV_AMT /* P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type */,
                                                                
                v_SAL_TOTAL /* P_salvage_amt    IN  acc_clm_payee_tmp.salvage_amt%type*/,
                                                                                          
                v_REC_TOTAL /* P_recov_amt    IN  acc_clm_payee_tmp.recov_amt%type*/,    
                                                                                          
                v_less_other /* P_prem_offset    IN  acc_clm_payee_tmp.less_other%type */ ,                                                                                           
                                                                          
                V_RESULT2 /* P_msg       Out varchar2*/ ) ;      
                                                                  
                if v_result2 is not null then rollback; P_RST:= v_result2||' in P_CLAIM_ACR.Post_acc_clm_payee_tmp'; return false; end if;  
                
                    
                dbms_output.put_line('pass post acc payee tmp ! '||p3.payee_code);              
            end loop;   -- end loop payee  
            COMMIT; -- post ACC_CLM_TEMP b4 call post GL  
  
            p_acc_claim.post_gl ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,  
                          
            c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,  
                          
            p1.pay_no /* p_number in varchar2 */,  -- payment no or batch no  
                          
            'P' /* p_flag in varchar2 */,   -- 'P' = Payment, 'B' = Batch  
                          
            V_RESULT3 /* p_err  out varchar2 */);  -- return null if no error  
  
  
            if v_result3 is not null then /* CLR_ACC_TMP; */ P_RST:= v_result3||' in p_acc_claim.post_gl'; return false; end if;       
            
           dbms_output.put_line('pass Post ACR');                      
                                               
            p_acc_claim.get_acr_voucher ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,  
  
            c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,  
  
            p1.pay_no /* p_number in varchar2 */,   -- payment no or batch no  
  
            'P' /* p_flag in varchar2 */,  -- 'P' = Payment, 'B' = Batch  
  
            V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,  
  
            V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);  
  
            IF V_VOUNO is null THEN  
                P_RST:= ' p_acc_claim.post_gl have any Problem '; return false;  
            END IF;  
            
            begin
            null; 
            exception
            when others then
                rollback; P_RST := 'error update claim: '||sqlerrm ; return false;
            end; 
                      
        end loop;        
    end loop;  
    --// End Run Individual ========  
     COMMIT;  
       
--    V_STATUS_RST := UPDATE_STATUS(vPayNo , vClmUser);  
--                          
--    IF V_STATUS_RST is not null THEN   
--        NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'UPDATE_STATUS' ,V_STATUS_RST,  
--                      m_rst)   ;                      
--    END IF;  
                   
    return true;  
EXCEPTION  
    WHEN OTHERS THEN  
    rollback; P_RST := 'error update claim: '||sqlerrm ; return false;          
END POST_MISC;  


FUNCTION GET_NAME_STATUS(i_grp in varchar2 ,i_pol_no in varchar2 ,i_pol_run in number ,i_fleet_seq in number ,i_recpt_seq in number
,i_loss_date in date ) RETURN VARCHAR2 IS
    P_return    VARCHAR2(1):='E';  -- Y = cover ,N = not cover,E = error
    v_found varchar2(10);
BEGIN
    IF i_grp = 'PA' THEN
        begin
            select cancel into v_found
            from mis_pa_prem
            where pol_no=i_pol_no and pol_run=i_pol_run 
            and fleet_seq=i_fleet_seq and recpt_seq = i_recpt_seq
            and i_loss_date between fr_date and to_date;
            if v_found is not null then --Cancel
                P_return := 'N';
            else
                P_return := 'Y';
            end if;
        exception
        when no_data_found then
            P_return := 'N';
        when others then
            P_return := 'N';
        end;        
    ELSIF i_grp = 'GM' THEN
        begin
            select cancel into v_found
            from pa_medical_det
            where pol_no=i_pol_no and pol_run=i_pol_run 
            and fleet_seq=i_fleet_seq and recpt_seq = i_recpt_seq
            and i_loss_date between fr_date and to_date;
            if v_found is not null then --Cancel
                P_return := 'N';
            else
                P_return := 'Y';
            end if;
        exception
        when no_data_found then
            P_return := 'N';
        when others then
            P_return := 'N';
        end;   
    END IF;
    return P_return;
EXCEPTION  
    WHEN OTHERS THEN  
    return 'N';          
END GET_NAME_STATUS;  

PROCEDURE GET_COVER_PA(P_POL_NO IN VARCHAR2,  
                                                    P_POL_RUN IN NUMBER,  
                                                    P_FLEET_SEQ IN NUMBER,  
                                                    P_RECPT_SEQ IN NUMBER,  
                                                    P_PREMCODE IN VARCHAR2, -- null คือดึงทั้งหมด   
                        P_COVER_PA  OUT v_ref_cursor1  ,RST OUT VARCHAR2)  IS  
 cursor c1 is SELECT a.pol_no, a.pol_run, a.recpt_seq, a.fleet_seq, a.end_seq, a.title,  
               a.NAME, a.surname, a.fr_date, a.TO_DATE, a.prem_code1, a.sum_ins1,  
               a.prem_code2, a.sum_ins2, a.prem_code3, a.sum_ins3, a.prem_code4,  
               a.sum_ins4, a.prem_code5, a.sum_ins5, a.prem_code6, a.sum_ins6,  
               a.prem_code7, a.sum_ins7, a.prem_code8, a.sum_ins8, a.prem_code9,  
               a.sum_ins9, a.prem_code10, a.sum_ins10, a.prem_code11, a.sum_ins11,  
               a.prem_code12, a.sum_ins12, a.prem_code13, a.sum_ins13, a.prem_code14,  
               a.sum_ins14, a.prem_code15, a.sum_ins15, a.prem_code16, a.sum_ins16,  
               a.prem_code17, a.sum_ins17, a.prem_code18, a.sum_ins18, a.prem_code19,  
               a.sum_ins19, a.prem_code20, a.sum_ins20, a.prem_code21, a.sum_ins21,  
               a.prem_code22, a.sum_ins22, a.prem_code23, a.sum_ins23, a.prem_code24,  
               a.sum_ins24, a.prem_code25, a.sum_ins25  
          FROM mis_pa_prem a  
            where pol_no = P_POL_NO  
            and pol_run = P_POL_RUN  
            and fleet_seq = P_FLEET_SEQ --:cpa_paid_blk.fleet_seq  
            and recpt_seq = P_RECPT_SEQ ;   
     
c_rec c1%rowtype;  
  
TYPE DEFINE_PREMCODE IS VARRAY(25) OF VARCHAR2(20);  
t_premcode   DEFINE_PREMCODE ;  
TYPE DEFINE_SUMINS IS VARRAY(25) OF NUMBER;  
t_sumins   DEFINE_SUMINS ;      
TYPE DEFINE_PREMCOL IS VARRAY(25) OF NUMBER;  
t_premcol   DEFINE_PREMCOL ;      
          
v_SID number(10);  
v_Tmp1 VARCHAR2(20);  
cnt NUMBER:=0;                        
BEGIN  
   RST := null;   
   t_premcode := DEFINE_PREMCODE(); --create empty varray   
   t_sumins := DEFINE_SUMINS(); --create empty varray   
   t_premcol := DEFINE_PREMCOL(); --create empty varray          
   OPEN C1;  
   LOOP  
      FETCH C1 INTO C_REC;  
      EXIT WHEN C1%NOTFOUND;  
        if c_rec.prem_code1 is not null and c_rec.sum_ins1 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code1 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins1 ;  
  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 1 ;                  
        end if;  
                
        if c_rec.prem_code2 is not null and c_rec.sum_ins2 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code2 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins2 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 2;  
        end if;  
        if c_rec.prem_code3 is not null and c_rec.sum_ins3 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code3 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins3 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 3 ;  
        end if;  
          
        if c_rec.prem_code4 is not null and c_rec.sum_ins4 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code4 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins4 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 4 ;  
        end if;          
  
        if c_rec.prem_code5 is not null and c_rec.sum_ins5 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code5 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins5 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 5 ;  
        end if;                  
          
        if c_rec.prem_code6 is not null and c_rec.sum_ins6 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code6 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins6 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 6 ;  
        end if;          
          
        if c_rec.prem_code7 is not null and c_rec.sum_ins7 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code7 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins7 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 7 ;  
        end if;          
  
        if c_rec.prem_code8 is not null and c_rec.sum_ins8 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code8 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins8 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 8 ;  
        end if;         
          
        if c_rec.prem_code9 is not null and c_rec.sum_ins9 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code9 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins9 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 9 ;  
        end if;           
          
        if c_rec.prem_code10 is not null and c_rec.sum_ins10 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code10 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins10 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 10 ;  
        end if;          
          
        if c_rec.prem_code11 is not null and c_rec.sum_ins11 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code11 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins11 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 11 ;  
        end if;  
          
        if c_rec.prem_code12 is not null and c_rec.sum_ins12 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code12 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins12 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 12 ;  
        end if;          
          
        if c_rec.prem_code13 is not null and c_rec.sum_ins13 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code13 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins13 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 13 ;  
        end if;          
          
        if c_rec.prem_code14 is not null and c_rec.sum_ins14 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code14 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins14 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 14 ;  
        end if;          
          
        if c_rec.prem_code15 is not null and c_rec.sum_ins15 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code15 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins15 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 15 ;  
        end if;          
                  
        if c_rec.prem_code16 is not null and c_rec.sum_ins16 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code16 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins16 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 16 ;  
        end if;  
          
        if c_rec.prem_code17 is not null and c_rec.sum_ins17 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code17 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins17 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 17 ;  
        end if;          
                  
        if c_rec.prem_code18 is not null and c_rec.sum_ins18 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code18 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins18 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 18 ;  
        end if;  
                  
        if c_rec.prem_code19 is not null and c_rec.sum_ins19 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code19 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins19 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 19 ;  
        end if;          
          
        if c_rec.prem_code20 is not null and c_rec.sum_ins20 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code20 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins20 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 20 ;  
        end if;  
          
        if c_rec.prem_code21 is not null and c_rec.sum_ins21 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code21 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins21 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 21 ;  
        end if;          
          
        if c_rec.prem_code22 is not null and c_rec.sum_ins22 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code22 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins22 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 22 ;  
        end if;          
  
        if c_rec.prem_code23 is not null and c_rec.sum_ins23 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code23 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins23 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 23 ;  
        end if;                  
          
        if c_rec.prem_code24 is not null and c_rec.sum_ins24 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code24 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins24 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 24 ;  
        end if;          
          
        if c_rec.prem_code25 is not null and c_rec.sum_ins25 is not null then  
            t_premcode.EXTEND(1);  
            t_premcode(t_premcode.LAST) := c_rec.prem_code25 ;  
                          
            t_sumins.EXTEND(1);  
            t_sumins(t_sumins.LAST) := c_rec.sum_ins25 ;  
                  
            t_premcol.EXTEND(1);  
            t_premcol(t_premcol.LAST) := 25 ;  
        end if;          
          
   END LOOP;  
   --DBMS_OUTPUT.PUT_LINE('COUNT='||t_premcode.COUNT);  
         
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
         
   FOR I in 1..t_premcode.COUNT LOOP  
        cnt := cnt+1;              
        --DBMS_OUTPUT.PUT_LINE('PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_sumins(cnt));  
         BEGIN   
            insert into nc_prem_tmp(SID,  PREMCODE, SUMINS ,PREMCOL)  
            values (v_SID ,t_premcode(cnt) ,t_sumins(cnt) ,t_premcol(cnt));  
         EXCEPTION  
           WHEN  OTHERS THEN  
           OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;  
           RST := 'error 1: '||sqlerrm;   
           rollback;  
         END;       
   END LOOP;  
    commit;  
  
    BEGIN  -- check found  
             
       SELECT max(PREMCODE) into v_Tmp1  
       FROM   NC_PREM_TMP  
       WHERE   SID = V_SID  
       AND PREMCODE like nvl(P_PREMCODE,'%');                
            
    EXCEPTION  
      WHEN  NO_DATA_FOUND THEN  
        RST := 'not found coverage';           
      WHEN  OTHERS THEN  
        RST := 'error 2: '||sqlerrm;   
    END;   -- end check found  
                  
    BEGIN  
       OPEN P_COVER_PA  FOR   
           SELECT PREMCODE, SUMINS ,PREMCOL 
           ,P_NON_PA_APPROVE.GET_PREMCODE_DESCR(PREMCODE, P_NON_PA_APPROVE.GET_PRODUCT_TYPE(P_POL_NO,P_POL_RUN) ,'E') DESCR
           FROM   NC_PREM_TMP  
           WHERE   SID = V_SID  
           AND PREMCODE like nvl(P_PREMCODE,'%');                
            
    EXCEPTION  
      WHEN  NO_DATA_FOUND THEN  
        OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL ,'' DESCR FROM DUAL;  
        RST := 'not found coverage';           
      WHEN  OTHERS THEN  
        OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL ,'' DESCR  FROM DUAL;  
        RST := 'error 3: '||sqlerrm;   
    END;    
          
    BEGIN  
           DELETE NC_PREM_TMP  
           WHERE   SID = V_SID;                
            
    EXCEPTION  
      WHEN  OTHERS THEN  
        --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS FROM DUAL;  
        rollback;  
    END;            
          
    commit;  
END GET_COVER_PA;    

FUNCTION GET_PREMCODE_DESCR(v_prem in varchar2 , v_prodtype in varchar2 ,v_th_eng in VARCHAR2) RETURN VARCHAR2 IS  
    v_descr VARCHAR2(100);  
BEGIN  
    select descr into v_descr  
    from prem_std a  
    where prem_code  =v_prem  
    and TH_ENG = v_th_eng  
    and prod_type = v_prodtype and rownum=1;    
    return v_descr;  
EXCEPTION  
    WHEN no_data_found THEN  
       return '';  
    WHEN OTHERS THEN  
       return '';      
END GET_PREMCODE_DESCR;   

FUNCTION CAN_CANCEL_PAYMENT(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_rst OUT varchar2) RETURN BOOLEAN IS
 v_f1 varchar2(20):=null;
 v_return boolean;
BEGIN
     begin
         select pay_sts into v_f1
         from nc_payment_apprv xxx
         where 
         xxx.clm_no = i_clmno and pay_no = i_payno and 
         xxx.pay_sts in ('NONPASTSAPPRV02','NONPASTSAPPRV05') and 
         type = '01' and sub_type = '01' and 
         xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no
         and type = '01' and sub_type = '01' );
         
         o_rst := 'งานอยู่ระหว่างรอการอนุมัติ' ; 
         v_return := false; 
     exception
     when no_data_found then
         v_f1 := null;
         v_return := true;
     when others then
     dbms_output.put_line('error'||sqlerrm);
         o_rst := 'error'||sqlerrm ; 
         v_return := false;
     end;
     
     if v_f1 is null then
         begin
             select payment_no into v_f1
             from acr_name_mas xxx
             where payment_no = i_payno ;
             
             o_rst := 'งานพิมพ์ Statement ไปแล้ว' ; 
             v_return := false; 
         exception
         when no_data_found then
             v_f1 := null;
             v_return := true;
         when others then
             dbms_output.put_line('error'||sqlerrm);
             o_rst := 'error'||sqlerrm ; 
             v_return := false;
         end; 
     end if;
     
     
    -- o_rst := null;
    return v_return;
END CAN_CANCEL_PAYMENT; 


FUNCTION CANCEL_PAYMENT(v_clmno IN varchar2 ,v_payno IN varchar2 ,v_rst OUT VARCHAR2) RETURN boolean IS
 v_apprv_date date;
 v_cnt number:=0;
-- v_err_message  varchar2(1000); 
 v_tmprst  varchar2(1000); 
 v_totpaid number:=0;
 V_CLMSTS varchar2(2); 
 v_found    varchar2(20);
 v_closedate    date;
 v_reopendate date;
BEGIN
--    begin
--        select CLM_NO into v_found
--        from mis_clm_paid a
--        where clm_no = v_clmno
--        and pay_no = v_payno
--        and corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no)
--        and rownum=1;
--    exception
--        when no_data_found then
--            nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'No claim data on BKIAPP ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
--            return true;
--        when others then
--            nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'No claim data on BKIAPP ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
--            return true;
--    end;
--
--    FOR x1 in (
--        select CLM_NO, PAY_NO, PAY_STS,  SETTLE, PART, ATTACHED ,
--                        PAY_TYPE, PRT_FLAG, REMARK, PAY_CURR_CODE, PAY_CURR_RATE, 
--                        PAY_TOTAL ,TOTAL_PAY_TOTAL, CORR_SEQ, CORR_DATE, STATE_FLAG, VAT_PERCENT, 
--                        DEDUCT_AMT, TOT_DEDUCT_AMT , REC_PAY_DATE, PRINT_BATCH ,
--                        INVOICE_NO ,JOB_NO 
--                        ,ACC_NO ,ACC_NAME ,BANK_CODE ,BR_NAME ,BANK_BR_CODE 
--        from mis_clm_paid a
--        where clm_no = v_clmno
--        and pay_no = v_payno
--        and corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no)    
--    ) LOOP
--        Begin
--            Insert into MIS_CLM_PAID
--               (CLM_NO, PAY_NO, PAY_STS,  SETTLE, PART, ATTACHED ,
--                PAY_TYPE, PRT_FLAG, REMARK, PAY_CURR_CODE, PAY_CURR_RATE, 
--                PAY_TOTAL ,TOTAL_PAY_TOTAL, CORR_SEQ, CORR_DATE, STATE_FLAG, VAT_PERCENT, 
--                DEDUCT_AMT, TOT_DEDUCT_AMT , REC_PAY_DATE, PRINT_BATCH ,
--                INVOICE_NO ,JOB_NO
--                ,ACC_NO ,ACC_NAME ,BANK_CODE ,BR_NAME ,BANK_BR_CODE )
--             Values
--               (x1.CLM_NO, x1.PAY_NO, x1.PAY_STS , x1.SETTLE, x1.PART ,x1.ATTACHED ,
--                x1.pay_type, x1.prt_flag , x1.remark, x1.PAY_CURR_CODE, x1.PAY_CURR_RATE, 
--                0 , 0 , x1.CORR_SEQ +1 ,sysdate , x1.STATE_FLAG, x1.VAT_PERCENT, 
--                0 , 0 , X1.REC_PAY_DATE, x1.PRINT_BATCH ,
--                x1.INVOICE_NO ,x1.JOB_NO 
--                ,x1.ACC_NO ,x1.ACC_NAME ,x1.BANK_CODE ,x1.BR_NAME ,x1.BANK_BR_CODE);
--            v_cnt := v_cnt +1;    
--            dbms_output.put_line('cancel mis_clm_paid: '||x1.CLM_NO||' payno: '||x1.PAY_NO);
--        exception   
--        when  OTHERS  then   
--             v_rst := 'MIS_CLM_PAID : '||sqlerrm;   
--             nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: insert MIS_CLM_PAID ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
--             rollback;  
--             return false;  
--        End;  
--    END LOOP;
--
--    FOR X2 in (
--        select CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, 
--                RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, 
--                CORR_SEQ, LF_FLAG, RI_SUB_TYPE
--        from MIS_CRI_PAID a
--        where clm_no = v_clmno
--        and pay_no = v_payno
--        and corr_seq in (select max(aa.corr_seq) from MIS_CRI_PAID aa where aa.pay_no = a.pay_no)
--    ) LOOP
--        Begin
--            Insert into MIS_CRI_PAID                                                    
--               (CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, 
--                RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, 
--                CORR_SEQ, LF_FLAG, RI_SUB_TYPE)
--             Values
--               (X2.CLM_NO, X2.PAY_NO, X2.PAY_STS , X2.RI_CODE, X2.RI_BR_CODE, 
--                X2.RI_TYPE, 0, X2.LETT_NO, X2.LETT_PRT, X2.LETT_TYPE, 
--                X2.CORR_SEQ+1, X2.LF_FLAG, X2.RI_SUB_TYPE );   
--            v_cnt := v_cnt +1;    
--            dbms_output.put_line('cancel MIS_CRI_PAID: '||X2.CLM_NO||' payno: '||X2.PAY_NO);
--        exception   
--        when  OTHERS  then   
--             v_rst := 'MIS_CRI_PAID : '||sqlerrm;   
--             nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: insert MIS_CRI_PAID ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
--             rollback;  
--             return false;  
--        End;  
--    END LOOP;
--    
--    FOR x3 in (
--        select CLM_NO, PAY_NO, PAY_STS, PAY_SEQ, PAYEE_TYPE, 
--                PAYEE_CODE , PAYEE_NAME, PAYEE_AMT, SETTLE, SEND_TITLE, 
--                SEND_ADDR1, SEND_ADDR2  
--                ,ACC_NO ,ACC_NAME ,BANK_CODE ,BANK_BR_CODE ,BR_NAME
--                ,CORR_SEQ ,CORR_DATE,
--                PAYEE_OFFSET ,PAYEE_OFFSET2 ,SALVAGE_AMT ,DEDUCT_AMT
--        from mis_clm_payee a
--        where clm_no = v_clmno
--        and pay_no = v_payno
--        and corr_seq in (select max(aa.corr_seq) from mis_clm_payee aa where aa.pay_no = a.pay_no)
--    ) LOOP
--        Begin
--            Insert into MIS_CLM_PAYEE
--               (CLM_NO, PAY_NO, PAY_STS, PAY_SEQ, PAYEE_TYPE, 
--                PAYEE_CODE , PAYEE_NAME, PAYEE_AMT, SETTLE, SEND_TITLE, 
--                SEND_ADDR1, SEND_ADDR2  
--                ,ACC_NO ,ACC_NAME ,BANK_CODE ,BANK_BR_CODE ,BR_NAME
--                ,CORR_SEQ ,CORR_DATE,
--                PAYEE_OFFSET ,PAYEE_OFFSET2 ,SALVAGE_AMT ,DEDUCT_AMT)
--             Values
--               (X3.CLM_NO, X3.PAY_NO, X3.PAY_STS , X3.PAY_SEQ, X3.PAYEE_TYPE, 
--                X3.PAYEE_CODE , X3.PAYEE_NAME, 0 , X3.SETTLE, X3.SEND_TITLE, 
--                X3.SEND_ADDR1, X3.SEND_ADDR2 ,X3.ACC_NO ,X3.ACC_NAME ,X3.BANK_CODE ,X3.BANK_BR_CODE ,X3.BR_NAME
--                ,X3.CORR_SEQ +1 ,sysdate,
--                X3.PAYEE_OFFSET ,X3.PAYEE_OFFSET2 ,0 ,0
--               );
--            v_cnt := v_cnt +1;    
--            dbms_output.put_line('cancel mis_clm_payee: '||x3.CLM_NO||' payno: '||x3.PAY_NO);
--        exception   
--        when  OTHERS  then   
--             v_rst := 'MIS_CLM_PAYEE : '||sqlerrm;   
--             nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: insert MIS_CLM_PAYEE ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
--             rollback;  
--             return false;  
--        End;  
--    END LOOP;
--
--    FOR x4 in (
--        select CLM_NO, PAY_NO, PAY_STS, SECTN, RISK_CODE, CLM_SEQ ,
--                PREM_CODE, TYPE, CORR_SEQ, PAY_AMT, TOTAL_PAY_AMT ,                
--                DEDUCT_AMT, TOT_DEDUCT_AMT ,
--                SALVAGE_AMT , TOT_SALVAGE_AMT 
--        from MIS_CMS_PAID a
--        where clm_no = v_clmno
--        and pay_no = v_payno
--        and corr_seq in (select max(aa.corr_seq) from MIS_CMS_PAID aa where aa.pay_no = a.pay_no)
--    ) LOOP
--        Begin
--            Insert into MIS_CMS_PAID
--               (CLM_NO, PAY_NO, PAY_STS, SECTN, RISK_CODE, CLM_SEQ ,
--                PREM_CODE, TYPE, CORR_SEQ, PAY_AMT, TOTAL_PAY_AMT ,                
--                DEDUCT_AMT, TOT_DEDUCT_AMT ,
--                SALVAGE_AMT , TOT_SALVAGE_AMT 
--                )
--             Values
--               (x4.CLM_NO, x4.PAY_NO, X4.PAY_STS , x4.SECTN, x4.RISK_CODE, x4.CLM_SEQ ,
--                x4.PREM_CODE, X4.TYPE , x4.CORR_SEQ +1 ,  0 , 0, 
--                0 ,0 ,
--                0 ,0
--                );  
--            v_cnt := v_cnt +1;    
--            dbms_output.put_line('cancel mis_cms_paid: '||x4.CLM_NO||' payno: '||x4.PAY_NO);
--        exception   
--        when  OTHERS  then   
--             v_rst := 'MIS_CMS_PAID : '||sqlerrm;   
--             nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: insert MIS_CMS_PAID ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
--             rollback;  
--             return false;  
--        End;  
--    END LOOP;
--
--        
--    begin
--        select sum(pay_total) into v_totpaid
--        from mis_clm_paid a
--        where clm_no = v_clmno 
--        and (pay_no, corr_seq) in (select aa.pay_no ,max(aa.corr_seq) from mis_clm_paid aa where aa.clm_no=a.clm_no group by aa.pay_no
--        ) and pay_sts='0';        
--    exception
--    when no_data_found then
--        v_totpaid := 0;
--    when others then
--    dbms_output.put_line('error'||sqlerrm);
--        v_totpaid :=0;
--    end;    
--    
--    V_CLMSTS := '1';
--    FOR Y1 in (
--        select close_date ,reopen_date
--        from nc_mas
--        where clm_no = v_clmno
--    )LOOP
--        IF v_clmsts in ('2','3') THEN
--            v_closedate := trunc(sysdate) ;
--            v_reopendate    := Y1.REOPEN_DATE ;
--        ELSIF v_clmsts = '4' THEN
--            v_closedate :=  Y1.CLOSE_DATE ;
--            v_reopendate    := trunc(sysdate);         
--        ELSIF v_clmsts in ('1') THEN      
--            v_closedate :=  null ;
--            v_reopendate    := Y1.REOPEN_DATE;             
--        END IF;  
--        nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: find ReopenDate ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' ReopenDate '|| v_reopendate ,'error' ,v_tmprst) ;
--    END LOOP;      
--        
--    FOR X5 IN 
--    ( 
--    select clm_no ,pol_no ,pol_run ,corr_seq ,channel ,prod_grp ,prod_type ,clm_date ,tot_res ,close_date ,reopen_date ,clm_sts
--    from mis_clm_mas_seq a
--    where clm_no = v_clmno
--    and corr_seq in (select max(aa.corr_Seq) from mis_clm_mas_seq aa where aa.clm_no = a.clm_no)    
--    )
--    Loop
--        Begin
--            Insert into MIS_CLM_MAS_SEQ
--               (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, 
--                CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE, TOT_RES, 
--                TOT_PAID, CLM_STS ,
--                 CLOSE_DATE ,REOPEN_DATE)
--             Values
--               (x5.CLM_NO, x5.POL_NO, x5.POL_RUN, x5.CORR_SEQ+1, sysdate, 
--                x5.CHANNEL, x5.PROD_GRP, x5.PROD_TYPE, x5.CLM_DATE, x5.TOT_RES, 
--                v_totpaid, V_CLMSTS,
--                v_closedate ,v_reopendate); 
--    --             dbms_output.put_line('convert mis_clm_mas_seq: '||x5.CLM_NO||' seq=' || x5.CORR_SEQ+1); 
--             dbms_output.put_line('convert mis_clm_mas_seq: '||x5.CLM_NO||' STS=' || V_CLMSTS); 
--                     
--             update MIS_CLM_MAS
--             set tot_paid = v_totpaid
--             ,clm_sts = V_CLMSTS ,CLOSE_DATE = v_closedate ,REOPEN_DATE = v_reopendate
--             where  clm_no = v_clmno ;     
--             dbms_output.put_line('convert mis_clm_mas: '||x5.CLM_NO); 
--        exception   
--        when  OTHERS  then   
--                 v_rst := 'MIS_CLM_MAS_SEQ : '||sqlerrm;
--                 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: MIS_CLM_MAS' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;   
--                 rollback;   
--                 return false;  
--        End;
--    End Loop;
                           
--    IF v_cnt > 0 THEN
--        COMMIT;
--        return true;
--    ELSE
--        v_rst := 'ไม่พบข้อมูล!';
--        return false; 
--    END IF;
    return true;
EXCEPTION
 WHEN OTHERS THEN
     v_rst := 'error CANCEL_PAYMENT:'||sqlerrm; 
     ROLLBACK;
     return false; 
END CANCEL_PAYMENT;

FUNCTION IS_APPROVED(vClmNo in varchar2 ,vPayNo in varchar2 )  RETURN VARCHAR2 IS
 v_f1 varchar2(20):=null;
 v_return boolean;
 is_clmtype boolean;
 v_dummyPayno   varchar2(20) ;
BEGIN   
    begin
        select pay_sts into v_f1
        from nc_payment_apprv xxx
        where 
        xxx.clm_no = vClmNo and pay_no = vPayNo  
        and pay_sts in (select key from clm_constant where key like 'NONPASTSAPPRV%' and remark2 = 'APPRV') 
        and xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.pay_no = xxx.pay_no );

        v_return := true; 
    exception
        when no_data_found then
        v_return := false;
    when others then
        v_return := false;
    end;
    
    if not v_return then  -- Old Claim not have approved data
        begin
            select payment_no into v_f1
            from acr_mas
            where payment_no = vPayNo ;
            
            v_return := true; 
        exception
            when no_data_found then
            v_return := false;
        when others then
            v_return := false;
        end;    
        
        if not v_return then  -- Old Claim not have approved data Recovery
             begin
             select distinct pay_no into v_dummyPayno
             from nc_payment
             where type like 'NCNATTYPECLM%'
             and pay_no = vPayNo ; 
             is_clmtype := true;
             exception
             when no_data_found then
             is_clmtype := false;
             when others then
             is_clmtype := false;
             end;        
             
             if not is_clmtype then -- For Recovery Type 
                if substr(vPayNo,1,4) < '2016' then
                    v_return := true;
                else
                    v_return := false;
                end if;             
             end if;
        end if;        
        
    end if;
    
    if v_return then
        return 'Y';
    else
        return 'N';
    end if;
END IS_APPROVED; 
           
END P_NON_PA_APPROVE;
/

