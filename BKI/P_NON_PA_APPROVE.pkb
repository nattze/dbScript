CREATE OR REPLACE PACKAGE BODY ALLCLM."P_NON_PA_APPROVE" AS
/******************************************************************************
 NAME: ALLCLM.P_NON_PA_APPROVE 
 PURPOSE: For Approve Non PA Claim  

 REVISIONS:
 Ver Date Author Description
 --------- ---------- --------------- ------------------------------------
 1.0 3/10/2014 2702 1. Created this package.
******************************************************************************/

FUNCTION CONVERT_PAYMENT_METHOD(inPaidType IN VARCHAR2) RETURN VARCHAR2 IS
 v_return varchar2(2);
BEGIN
 begin
 select remark into v_return
 from clm_constant 
 where key like 'PAIDTYPE%' 
-- and key = 'PAIDTYPE'||inPaidType
 and remark2 = inPaidType; 
 exception
 when no_data_found then
 v_return := inPaidType;
 when others then
 dbms_output.put_line('error'||sqlerrm);
 v_return :=inPaidType;
 end; 
 return v_return;
END CONVERT_PAYMENT_METHOD; 

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

PROCEDURE GET_REPORT_USER(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_apprv_id OUT varchar2 ,o_clm_men OUT varchar2) IS
 v_apprv_date date;
BEGIN
 BEGIN
 select NC_HEALTH_PAID.GET_USER_NAME(approve_id) into o_apprv_id 
 from nc_payment_apprv xxx
 where 
 xxx.clm_no = i_clmno and pay_no = i_payno and 
 type = '01' and sub_type = '01' and 
 --pay_sts = 'NONPASTSAPPRV03' 
 pay_sts in (select key from clm_constant where key like 'NONPASTSAPPRV%' and remark2 ='APPRV')
 and 
 xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no
 and type = '01' and sub_type = '01' ); 

 FOR X IN (
 select APPROVE_DATE
 from nc_payment_apprv x
 where pay_no = i_payno
 --and pay_sts = 'NONPASTSAPPRV03'
 and pay_sts in (select key from clm_constant where key like 'NONPASTSAPPRV%' and remark2 ='APPRV')
 ) LOOP
 v_apprv_date := X.APPROVE_DATE ;
 END LOOP;
 
 o_apprv_id := o_apprv_id||' ('||to_char(v_apprv_date,'dd/mm/yy')||')' ;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 o_apprv_id := null; 
 WHEN OTHERS THEN
 o_apprv_id := null; 
 END; 
 
 IF o_apprv_id is not null THEN
 BEGIN
 select distinct(NC_HEALTH_PAID.GET_USER_NAME(clm_men )) into o_clm_men
 from nc_payment_apprv xxx 
 where xxx.clm_no = i_clmno
 and xxx.pay_no =i_payno
 and xxx.trn_seq = (select min(a.trn_seq) from nc_payment_apprv a where a.clm_no =xxx.clm_no and a.pay_no =xxx.pay_no); 
 o_clm_men := o_clm_men;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 o_clm_men := null; 
 WHEN OTHERS THEN
 o_clm_men := null; 
 END; 
 END IF;
 
END GET_REPORT_USER;

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
 select pay_sts into v_f1
 from nc_payment_apprv xxx
 where 
 xxx.clm_no = i_clmno and pay_no = i_payno and 
 xxx.pay_sts in ('NONPASTSAPPRV03','NONPASTSAPPRV11','NONPASTSAPPRV12') and 
 type = '01' and sub_type = '01' and 
 xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no
 and type = '01' and sub_type = '01' );
 o_rst := 'งานอนุมัติไปแล้ว' ; 
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

FUNCTION CAN_MAKE_NEW_PAYMENT(i_clmno IN varchar2 ,o_rst OUT varchar2) RETURN BOOLEAN IS
 v_return boolean:=true;
 v_found varchar2(20);
BEGIN

 --return true ; -- bypass For Test waiting for adjust add read on acc_clm_payee_tmp
 
 begin
 select remark into v_found
 from clm_constant a
 where key like 'NONPAEXCEPT%'
 and remark = i_clmno
 and rownum=1;
 if v_found is not null then return TRUE; end if;
 exception
 when no_data_found then
 v_found := null;
 when others then
 v_found := null;
 end;
 
-- FOR c1 IN (
-- select pay_no ,sum(pay_total) pay_amt
-- from mis_clm_paid a
-- where clm_no = I_CLMNO
-- and pay_sts ='0' 
-- and (a.pay_no ,a.corr_seq) in (select aa.pay_no ,max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no 
-- and aa.pay_sts ='0' 
-- group by aa.pay_no) 
-- group by pay_no
-- having sum(pay_total) >0 
-- ) LOOP
--
-- begin
-- select payment_no
-- into v_found
-- from acr_name_mas
-- where payment_no = c1.pay_no and rownum=1;
-- exception
-- when no_data_found then
-- v_found := null;
-- when others then
-- v_found := null;
-- dbms_output.put_line('error'||sqlerrm);
-- end;
-- 
-- if v_found is null then -- ไม่พบการจ่าย 
-- v_return := false;
-- o_rst := 'มีเลขที่จ่าย '||c1.pay_no || 'ค้าง draft ในระบบ ไม่สามารถสร้างเลขจ่ายใหม่ได้ !! ';
-- end if;
-- 
-- END LOOP; --c1

 FOR c1 IN (
 select a.pay_no ,sum(pay_amt) pay_amt
 from nc_payment a
 where clm_no = I_CLMNO
 and type like 'NCNATTYPECLM%'
 and (a.pay_no ,a.trn_seq) = (select (aa.pay_no) , max(aa.trn_seq) from nc_payment aa where aa.pay_no = a.pay_no group by aa.pay_no)
 group by a.pay_no having sum(a.pay_amt)>0
 ) LOOP

 begin
 select payment_no
 into v_found
 from acc_clm_tmp
 where payment_no = c1.pay_no and rownum=1;
 exception
 when no_data_found then
 v_found := null;
 when others then
 v_found := null;
 dbms_output.put_line('error'||sqlerrm);
 end;
 
 if v_found is null then -- ไม่พบการจอนุมัติรอ post
 begin
 select payment_no
 into v_found
 from acr_name_mas
 where payment_no = c1.pay_no and rownum=1;
 exception
 when no_data_found then
 v_found := null;
 when others then
 v_found := null;
 dbms_output.put_line('error'||sqlerrm);
 end;
 end if;
 
 if v_found is null then -- ไม่พบการจ่าย ใน ACR 
 v_return := false;
 o_rst := 'มีเลขที่จ่าย '||c1.pay_no || 'ค้าง draft ในระบบ ไม่สามารถสร้างเลขจ่ายใหม่ได้ !! ';
 end if;
 
 END LOOP; --c1
 
 -- if i_clmno = '201501551000029' then
 -- v_return := true; o_rst := null;
 -- end if;

 return v_return;
END CAN_MAKE_NEW_PAYMENT;

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
 o_rst := 'สถานะงานไม่อยู่ในการขออนุมัติ !';
 v_return := false;
 END IF;
 
 IF v_return THEN
 ALLCLM.P_NON_PA_APPROVE.GET_APPROVE_USER(i_clmno ,i_payno ,v_apprv_id ,v_sts );
 IF v_apprv_id <> i_userid THEN
 o_rst := 'งานนี้เป็นของรหัส '||v_apprv_id ||' เป็นผู้อนุมัติ !';
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
 
 EMAIL_NOTICE_APPRV(v_clmno ,v_payno ,v_sts);
 
 return true;
 
EXCEPTION
 WHEN OTHERS THEN
 v_rst := 'error insert ncpayment:'||sqlerrm; 
 ROLLBACK;
 return false; 
END UPDATE_NCPAYMENT;

FUNCTION UPDATE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2 
,v_apprv_flag IN varchar2 ,v_user IN varchar2 ,v_amd_user IN varchar2 ,v_apprv_user IN varchar2 ,v_res_amt IN NUMBER ,v_accum_amt IN NUMBER ,v_rst OUT VARCHAR2) RETURN boolean IS
 v_max_seq number:=1;
 m_prodgrp varchar2(10);
 m_prodtype varchar2(10);
 m_curr_code varchar2(10);
 m_curr_rate number(5,2);
 dummy_payno varchar2(20);
 v_apprv_date date;
BEGIN
    if v_accum_amt <= 0 then
        if v_sts in ('NONPASTSAPPRV02' ,'NONPASTSAPPRV05') then 
            v_rst := 'Cannot send amount 0 for approve payment ';
            return false;
        end if;
    end if;
 
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
    VALUES (v_clmno , v_payno ,1 ,v_max_seq, v_sts ,v_res_amt ,v_accum_amt,
    m_curr_code, m_curr_rate ,sysdate ,sysdate ,v_user ,v_amd_user ,v_apprv_user ,v_apprv_date
    ,m_prodgrp,m_prodtype, GET_PRODUCTID(m_prodtype) ,v_key ,'01' ,'01' ,v_apprv_flag) ; 
     
    COMMIT;
     
    EMAIL_NOTICE_APPRV(v_clmno ,v_payno ,v_sts);
     
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
 EMAIL_NOTICE_APPRV(v_clmno ,v_payno ,v_sts);
 return true;
 ELSE
 v_rst := 'ไม่พบข้อมูลการอนุมัติ!';
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
 v_dummyPayno varchar2(20);
 is_clmtype boolean:=true; 
 v_found varchar2(20);
 v_lastPaySTS varchar2(20);
 v_chkApproved varchar2(20);
 v_subject VARCHAR2(250) ;
 v_body VARCHAR2(2000) ;
 v_to VARCHAR2(250) ;
 v_dbins VARCHAR2(20);
 v_payeeamt number:=0;
BEGIN

 BEGIN
 select pay_sts into v_lastPaySTS
 from nc_payment_apprv a
 where subsysid = 'NMC'
 and a.trn_seq in (select max(aa.trn_seq) from nc_payment_apprv aa where aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
 and pay_no =v_payno ;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 v_lastPaySTS := null;
 WHEN OTHERS THEN
 v_lastPaySTS := null;
 END; 
 
 BEGIN
 select key into v_found
 from clm_constant a
 where key like 'NONPASTSAPPRV%'
 and key = v_lastPaySTS
 and remark2 is null; -- status send Approve /Pre Approve
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 v_found := null;
 WHEN OTHERS THEN
 v_found := null;
 END; 
 
 if v_found is null then -- ไม่พบงานเป็นสถานะส่งอนุมัติ
 BEGIN
 select key into v_chkApproved
 from clm_constant
 where key like 'NONPASTSAPPRV%'
 and key = v_lastPaySTS 
 and remark2 = 'APPRV' ;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 v_chkApproved := null;
 WHEN OTHERS THEN
 v_chkApproved := null;
 END; 
 
 if v_chkApproved is not null then
 v_rst := 'เลขที่จ่ายนี้มีการอนุมัติไปแล้ว!!'; 
 else
 v_rst := 'เลขที่จ่ายนี้มีไม่ได้อยู่ระหว่างการขออนุมัติ!!'; 
 end if;
 dbms_output.put_line('in validate Last ApproveStatus: '||v_rst); 
 return false;
 end if;
 
 if v_sts in ('NONPASTSAPPRV03' ,'NONPASTSAPPRV06') then
     begin
        select sum(payee_amt) into v_payeeamt
        from nc_payee a
        where pay_no = v_payno
        and trn_seq in (select max(aa.trn_seq) from nc_payee aa where aa.pay_no = a.pay_no ) ;  
     exception
     when no_data_found then
        v_payeeamt := 0;
     when others then
        v_payeeamt := 0;
     end;  
     
     if v_payeeamt =0 then
     v_rst := 'Cannot Approve payee amt = 0'; 
     return false;
     end if;      
 end if;

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
 
 IF v_cnt > 0 THEN
     COMMIT;
    
    if v_sts in ('NONPASTSAPPRV03') then --- mark close claim
        if not P_NON_PA_CLM_PAYMENT.update_end_payment(v_clmno,v_payno,v_sts,v_rst) then
            return false;
        end if;
        P_NON_PA_CLM_PAYMENT.save_oic_payment_seq(v_clmno,v_payno,'I');
    end if;
    
     begin
     select distinct pay_no into v_dummyPayno
     from nc_payment
     where type like 'NCNATTYPECLM%'
     and pay_no = v_payno ; 
     is_clmtype := true;
     exception
     when no_data_found then
     is_clmtype := false;
     when others then
     is_clmtype := false;
     end;
     
     if v_sts in ('NONPASTSAPPRV03') AND IS_ACTIVATE_AUTOPOST AND IS_CLMTYPE AND v_payeeamt >0 then -- When Approve Convert to BKIAPP
         -- new Paperless 
         IF not AUTO_POST(v_clmno, v_payno , v_apprv_user ,v_rst) THEN --POST ACR
             delete nc_payment_apprv a
             where sts_key = v_key and pay_no = v_payno
             and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no); 
             COMMIT; 

             dbms_output.put_line('in Auto Post false: '||v_rst); 
             return false;
         END IF; 
         dbms_output.put_line('after AUTO_POST');
     
         IF not AFTER_POST(v_clmno, v_payno , v_apprv_user,v_rst) THEN --POST ACR
             delete nc_payment_apprv a
             where sts_key = v_key and pay_no = v_payno
             and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no); 
             COMMIT; 
             dbms_output.put_line('in AFTER POST false: '||v_rst); 
             return false;
         END IF; 
         dbms_output.put_line('End after POST');
         EMAIL_NOTICE_APPRV(v_clmno ,v_payno ,v_sts);
     elsif v_sts in ('NONPASTSAPPRV03') AND IS_ACTIVATE_AUTOPOST then -- case Recov/Salvage/Deduct Receive
         IF not AFTER_POST(v_clmno, v_payno , v_apprv_user,v_rst) THEN --POST ACR
             delete nc_payment_apprv a
             where sts_key = v_key and pay_no = v_payno
             and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no); 
             COMMIT; 
             dbms_output.put_line('in AFTER POST Receive false: '||v_rst); 
             return false;
         END IF; 
         dbms_output.put_line('End after POST');
         EMAIL_NOTICE_APPRV(v_clmno ,v_payno ,v_sts); 
     else
     EMAIL_NOTICE_APPRV(v_clmno ,v_payno ,v_sts);
     end if;
     return true;
 ELSE
     v_rst := 'ไม่พบข้อมูลการอนุมัติ!';
     return false; 
 END IF;

EXCEPTION
 WHEN OTHERS THEN
 v_rst := 'error APPROVE_NCPAYMENT:'||sqlerrm; 
 ROLLBACK;
 return false; 
END APPROVE_NCPAYMENT;

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
 WHEN v_status = 'NCCLMSTS02' THEN v_return := '7'; -- Close ฝั่ง NC_MAS แต่ MIS_CLM_MAS ให้รอ 7 ไว้
 WHEN v_status = 'NCCLMSTS03' THEN v_return := '3'; -- CWP
-- WHEN v_status = 'NCCLMSTS04' THEN v_return := '4'; -- ReOpen
 WHEN v_status = 'NCCLMSTS04' THEN v_return := '6'; -- ReOpen for fix User Problem
 ELSE v_return := v_status;
 END CASE; 
 
 return v_return;
EXCEPTION
 WHEN OTHERS THEN
 return null;
END GET_CLMSTS; 
 
FUNCTION GET_TYPE(In_prod_grp in varchar2,In_offset_flag in varchar2,In_type in varchar2 ,In_subtype in varchar2 ,in_prem_code in varchar2)return varchar2 is
 v_type varchar2(2);
BEGIN

 IF In_prod_grp ='5' THEN
 if In_subtype in ('NCNATSUBTYPECLM001') then 
 if in_prem_code = '1010' then 
 v_type := '01'; 
 elsif in_prem_code in ('1020','1030','1040','1560') then 
 v_type := '02'; 
 elsif in_prem_code in ('1050') then 
 v_type := '03'; 
 else 
 v_type := '04'; 
 end if; 
 elsif In_subtype in ('NCNATSUBTYPECLM002') then 
 v_type := '05'; 
 elsif In_subtype in ('NCNATSUBTYPECLM003') then 
 v_type := '06'; 
 elsif In_subtype in ('NCNATSUBTYPECLM004') then 
 v_type := '25'; 
 elsif In_subtype in ('NCNATSUBTYPECLM005','NCNATSUBTYPECLM006') then 
 v_type := '04'; 
 elsif In_subtype in ('NCNATSUBTYPECLM010','NCNATSUBTYPECLM011','NCNATSUBTYPECLM012') then 
 v_type := '07'; 
 elsif In_subtype in ('NCNATSUBTYPECLM018','NCNATSUBTYPECLM019') then 
 v_type := '08'; 
 elsif In_subtype in ('NCNATSUBTYPECLM013','NCNATSUBTYPECLM014','NCNATSUBTYPECLM015','NCNATSUBTYPECLM016','NCNATSUBTYPECLM017') then 
 v_type := '09'; 
 else 
 v_type := '00'; 
 end if; 
 END IF;
 return(v_type);
EXCEPTION
WHEN OTHERS THEN 
 return(null);
END;

FUNCTION GET_PAYTYPE(in_status in varchar2) RETURN varchar2 IS
 v_return varchar2(10):='';
BEGIN
 IF in_status = 'NCPAYMENTSTS01' THEN -- patial 
 v_return := '1'; 
 ELSIF in_status = 'NCPAYMENTSTS02' THEN --final 
 v_return := '4'; 
 ELSIF in_status = 'NCPAYMENTSTS03' THEN --interim 
 v_return := '2'; 
 END IF; 
 
 return v_return; 
EXCEPTION
WHEN OTHERS THEN 
 return(null);
END ;

PROCEDURE CONV_INSERT_MISC_TABLE(v_clm_no in varchar2,v_pay_no in varchar2,v_trn_seq in number ,v_prod_type varchar2, v_err_message out varchar2) IS
 v_pay_amt nc_payment.pay_amt%type;
 v_total_pay_total nc_payment.tot_pay_amt%type;
 v_deduct_total mis_cms_paid.deduct_amt%type;
 v_total_deduct_total mis_cms_paid.tot_deduct_amt%type; 
 v_clmsts varchar2(20);
 v_closedate date;
 v_reopendate date;
 v_type varchar2(20);
 v_paytype varchar2(20);
 cnt_x1 number:=0;
 rec_x1 number:=0;
 x_corr_seq number:=0;
 cms_pay_amt mis_cms_paid.pay_amt%type;
 cms_tot_pay_amt mis_cms_paid.total_pay_amt%type; 
 cms_deduct_amt mis_cms_paid.deduct_amt%type;
 cms_tot_deduct_amt mis_cms_paid.tot_deduct_amt%type; 
 cms_salvage_amt mis_cms_paid.salvage_amt%type;
 cms_tot_salvage_amt mis_cms_paid.tot_salvage_amt%type; 
 v_offset1 varchar2(2);
 v_offset2 varchar2(2); 
 v_part varchar2(10000);
 v_remark varchar2(1000);

 o_salvage VARCHAR2(1) ;
 o_deduct VARCHAR2(1) ;
 o_recov VARCHAR2(1) ;
 v_prt_flag VARCHAR2(1) ;
 v_rectype varchar2(2);
 v_rec_closedate date;
 v_rec_sts varchar2(2);
 v_rec_maxseq number:=0;
 v_rec_cnt number:=0;
Begin 
 v_err_message := null; 

 BEGIN
 select count(*) into cnt_x1
 from nc_payee c
 where c.clm_no = v_clm_no and c.pay_no = v_pay_no ;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 cnt_x1 := 0 ;
 WHEN OTHERS THEN
 cnt_x1 := 0;
 END; 
 
 IF cnt_x1 = 0 THEN
 v_err_message := 'not convert!! wait for NC_Payee Data ';
 return ; 
 END IF;

 BEGIN
 select count(*) into cnt_x1
 from nc_payment a ,nc_payment_info b ,nc_payee c
 where a.clm_no = v_clm_no and a.pay_no = v_pay_no
-- and a.trn_seq = v_trn_seq 
 and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
 and a.pay_no = b.pay_no(+) and a.pay_no = c.pay_no(+)
 and a.trn_seq = b.trn_seq(+) and a.trn_seq = c.trn_seq(+)
 and nvl(c.payee_seq,1) = 1 ;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 cnt_x1 := 0 ;
 WHEN OTHERS THEN
 cnt_x1 := 0;
 END; 
 v_pay_amt :=0 ;
 v_total_pay_total :=0 ;
 v_deduct_total :=0 ;
 v_total_deduct_total :=0 ;
 
 FOR X1 IN 
 ( 
 select a.CLM_NO, a.PAY_NO, a.trn_seq CORR_SEQ,a.amd_date CORR_DATE, '0' PAY_STS, 
 a.pay_amt PAY_AMT, P_CONVERT_PAYMENT.CONVERT_PAYMENT_METHOD(c.SETTLE) SETTLE, a.CLM_MEN ,a.AMD_USER ,a.STS_DATE ,a.AMD_DATE, a.SETTLE_DATE ,
 a.status PAY_TYPE, 'Y' PRT_FLAG, b.REMARK, a.CURR_CODE PAY_CURR_CODE, a.CURR_RATE PAY_CURR_RATE, 
 a.TOT_PAY_AMT TOTAL_PAY_TOTAL,'0' STATE_FLAG,'' VAT_PERCENT, 
 0 DEDUCT_AMT,a.sts_date REC_PAY_DATE,B.PRINT_BATCH ,
 ALLCLM.p_non_pa_approve.get_type(a.PROD_GRP,a.OFFSET_FLAG,a.TYPE, a.SUB_TYPE ,prem_code) convert_type,
 a.SUB_TYPE , b.part ,
 '' convert_pay_type --,ALLCLM.p_non_pa_approve.get_clmsts(a.STATUS) CLMSTS
 from nc_payment a ,nc_payment_info b ,nc_payee c
 where a.clm_no = v_clm_no and a.pay_no = v_pay_no
-- and a.trn_seq = v_trn_seq 
 and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
 and a.pay_no = b.pay_no(+) and a.pay_no = c.pay_no(+)
 and a.trn_seq = b.trn_seq(+) and a.trn_seq = c.trn_seq(+)
 and nvl(c.payee_seq,1) = 1 
 ) 
 LOOP 
 rec_x1 := rec_x1+1;
 v_clmsts := ALLCLM.p_non_pa_approve.get_clmsts(x1.clm_no) ;
 v_paytype := ALLCLM.p_non_pa_approve.get_paytype(x1.PAY_TYPE) ;
 if P_CONVERT_PAYMENT.GET_CNT_LINEFEED(substr(x1.part,1,10000)) > 9 then
 v_prt_flag := 'Y';
 else
 v_prt_flag := 'N';
 end if;
-- v_part := substr(x1.part,1,10000);
-- v_part := replace(v_part,chr(10),chr(13));
 v_part := P_CONVERT_PAYMENT.FIX_LINEFEED(substr(x1.part,1,10000)) ;
 v_remark := P_CONVERT_PAYMENT.FIX_LINEFEED(x1.remark) ;

 IF X1.SUB_TYPE like 'NCNATSUBTYPECLM%' THEN
 v_pay_amt := v_pay_amt + X1.PAY_AMT; 
 v_total_pay_total := v_total_pay_total + X1.TOTAL_PAY_TOTAL;
 ELSIF X1.SUB_TYPE like 'NCNATSUBTYPEDED%' THEN
 v_deduct_total := v_deduct_total + X1.PAY_AMT; 
 v_total_deduct_total := v_total_deduct_total + X1.TOTAL_PAY_TOTAL;
 END IF;

 -- v_pay_sts := X1.pay_sts;
 -- v_curr_code1 := X1.PAY_CURR_CODE;
 -- v_curr_rate1 := X1.PAY_CURR_RATE;
 -- v_clm_men := X1.clm_men;
 -- v_amd_user := X1.amd_user;
 -- v_pay_amt := X1.PAY_AMT;
 -- v_sts_date:= X1.sts_date;
 -- v_amd_date := X1.amd_date;
 -- v_settle_date := X1.settle_date;
 IF v_clmsts in ('2','3') THEN
 v_closedate := X1.CORR_DATE ;
 v_reopendate := null;
 ELSIF v_clmsts = '4' THEN
 v_closedate := null ;
 v_reopendate := X1.CORR_DATE; 
 END IF; 

 -- dbms_output.put_line('convert_pay_type='||X1.convert_pay_type);
 if rec_x1 = cnt_x1 then -- last row
 Begin
 Insert into ALLCLM.MIS_CLM_PAID
 (CLM_NO, PAY_NO, PAY_STS, SETTLE, PART,
 PAY_TYPE, PRT_FLAG, REMARK, PAY_CURR_CODE, PAY_CURR_RATE, 
 PAY_TOTAL ,TOTAL_PAY_TOTAL, CORR_SEQ, CORR_DATE, STATE_FLAG, VAT_PERCENT, 
 DEDUCT_AMT, TOT_DEDUCT_AMT , REC_PAY_DATE, PRINT_BATCH)
 Values
 (x1.CLM_NO, x1.PAY_NO, x1.PAY_STS, x1.SETTLE, v_part ,
 v_paytype, v_prt_flag , v_remark, x1.PAY_CURR_CODE, x1.PAY_CURR_RATE, 
 v_pay_amt , v_total_pay_total , x1.CORR_SEQ, x1.CORR_DATE, x1.STATE_FLAG, x1.VAT_PERCENT, 
 v_deduct_total , v_total_deduct_total , x1.REC_PAY_DATE, x1.PRINT_BATCH);
 dbms_output.put_line('convert mis_clm_paid: '||x1.CLM_NO);
 exception 
 when OTHERS then 
 v_err_message := 'MIS_CLM_PAID'; 
 rollback; 
 End; 
 end if;
 End loop; 

 

 Begin
 FOR X2 IN 
 ( 
 SELECT CLM_NO, PAY_NO, '0' PAY_STS, RI_CODE, RI_BR_CODE, 
 RI_TYPE, RI_PAY_AMT PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, 
 TRN_SEQ CORR_SEQ, RI_LF_FLAG, RI_SUB_TYPE 
 FROM NC_RI_PAID A
 WHERE A.CLM_NO = v_clm_no 
 AND A.PAY_NO =v_pay_no
-- AND A.TRN_SEQ = v_trn_seq 
 and a.trn_seq in (select max(aa.trn_seq) from NC_RI_PAID aa where AA.TYPE LIKE 'NCNATTYPECLM%' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
 AND A.TYPE LIKE 'NCNATTYPECLM%'
 )
 Loop
 Begin
 Insert into ALLCLM.MIS_CRI_PAID 
 (CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, 
 RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, 
 CORR_SEQ, LF_FLAG, RI_SUB_TYPE)
 Values
 (X2.CLM_NO, X2.PAY_NO, X2.PAY_STS, X2.RI_CODE, X2.RI_BR_CODE, 
 X2.RI_TYPE, X2.PAY_AMT, X2.LETT_NO, X2.LETT_PRT, X2.LETT_TYPE, 
 X2.CORR_SEQ, X2.RI_LF_FLAG, X2.RI_SUB_TYPE ); 
 dbms_output.put_line('convert mis_cri_paid: '||x2.CLM_NO); 
 exception 
 when OTHERS then 
 v_err_message := 'MIS_CRI_PAID'; 
 rollback; 
 End;
 End Loop;
 
 End; 


 cms_pay_amt := 0;
 cms_tot_pay_amt := 0;
 cms_deduct_amt := 0;
 cms_tot_deduct_amt := 0;
 cms_salvage_amt := 0;
 cms_tot_salvage_amt := 0; 
 
 Begin
 FOR X4 IN 
 ( 
 select A.CLM_NO ,A.PAY_NO , '0' PAY_STS ,nvl(a.CLM_SEQ,1) SECTN, x.cause_code RISK_CODE ,nvl(a.CLM_SEQ,1) CLM_SEQ, 
 a.PREM_CODE,ALLCLM.p_non_pa_approve.get_type(a.PROD_GRP,a.OFFSET_FLAG,a.TYPE, a.SUB_TYPE ,prem_code) TYPE, a.TRN_SEQ CORR_SEQ, a.PAY_AMT PAY_AMT, 0 DEDUCT_AMT, 
 a.TOT_PAY_AMT TOTAL_PAY_AMT ,a.sub_type ,a.OFFSET_FLAG ,A.STS_DATE ,A.AMD_DATE ,A.STATUS
 from nc_mas x , nc_payment a 
 where a.clm_no = x.clm_no and a.clm_no = v_clm_no and a.pay_no =v_pay_no
-- and a.trn_seq = v_trn_seq 
 and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no)
 )
 Loop
 
 if x4.sub_type in ('NCNATSUBTYPECLM001') then 
 if x4.prem_code = '1010' then 
 v_type := '01'; 
 elsif x4.prem_code in ('1020','1030','1040','1560') then 
 v_type := '02'; 
 elsif x4.prem_code in ('1050') then 
 v_type := '03'; 
 else 
 v_type := '04'; 
 end if; 
 elsif x4.sub_type in ('NCNATSUBTYPECLM002') then 
 v_type := '05'; 
 elsif x4.sub_type in ('NCNATSUBTYPECLM003') then 
 v_type := '06'; 
 elsif x4.sub_type in ('NCNATSUBTYPECLM004') then 
 v_type := '25'; 
 elsif x4.sub_type in ('NCNATSUBTYPECLM005','NCNATSUBTYPECLM006') then 
 v_type := '04'; 
 elsif x4.sub_type in ('NCNATSUBTYPECLM010','NCNATSUBTYPECLM011','NCNATSUBTYPECLM012') then 
 v_type := '07'; 
 elsif x4.sub_type in ('NCNATSUBTYPECLM018','NCNATSUBTYPECLM019') then 
 v_type := '08'; 
 elsif x4.sub_type in ('NCNATSUBTYPECLM013','NCNATSUBTYPECLM014','NCNATSUBTYPECLM015','NCNATSUBTYPECLM016','NCNATSUBTYPECLM017') then 
 v_type := '09'; 
 elsif x4.sub_type like 'NCNATSUBTYPEDED%' then
 v_type := '26'; 
 elsif x4.sub_type like 'NCNATSUBTYPESAL%' then
 v_type := '27'; 
 else 
 v_type := '00'; 
 end if; 

 cms_pay_amt := 0;
 cms_tot_pay_amt := 0;
 cms_deduct_amt := 0;
 cms_tot_deduct_amt := 0;
 cms_salvage_amt := 0;
 cms_tot_salvage_amt := 0; 
 
 if X4.sub_type like 'NCNATSUBTYPECLM%' then
 cms_pay_amt := cms_pay_amt + x4.PAY_AMT;
 cms_tot_pay_amt := cms_tot_pay_amt + x4.TOTAL_PAY_AMT;
 elsif X4.sub_type like 'NCNATSUBTYPESAL%' then
 cms_salvage_amt := cms_salvage_amt + x4.PAY_AMT;
 cms_tot_salvage_amt := cms_tot_salvage_amt + x4.TOTAL_PAY_AMT;
 elsif X4.sub_type like 'NCNATSUBTYPEDED%' then
 cms_deduct_amt := cms_deduct_amt + x4.PAY_AMT;
 cms_tot_deduct_amt := cms_tot_deduct_amt + x4.TOTAL_PAY_AMT;
 end if;

 -- === insert MIS_REC_MAS_SEQ
 if x4.type like 'NCNATTYPEREC%' and x4.OFFSET_FLAG is null then
 dbms_output.put_line('found recov ');
 if x4.sub_type like 'NCNATSUBTYPEREC%' then 
 v_rectype := '1';
 elsif x4.sub_type like 'NCNATSUBTYPESAL%' then 
 v_rectype := '2';
 elsif x4.sub_type like 'NCNATSUBTYPEDED%' then 
 v_rectype := '3';
 end if;
 
 if x4.STATUS = 'NCPAYMENTSTS02' then
 v_rec_closedate := X4.amd_date;
 v_rec_sts := '2';
 else
 v_rec_closedate := null;
 v_rec_sts := '1';
 end if;

 BEGIN
 select max(corr_seq)+1 into v_rec_maxseq
 from MIS_REC_MAS_SEQ a
 where a.clm_no = x4.clm_no ;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 v_rec_maxseq := 0 ;
 WHEN OTHERS THEN
 v_rec_maxseq := 0;
 END; 

 Begin
 Insert into ALLCLM.MIS_REC_MAS_SEQ
 (CLM_NO, REC_TYPE, CORR_SEQ, CORR_DATE, REC_DATE, REC_STS, TOT_RES_REC, OFFSET ,CLOSE_DATE)
 Values
 (x4.clm_no,v_rectype , v_rec_maxseq , x4.amd_date, x4.sts_date , 
 v_rec_sts , x4.pay_amt, '2' ,v_rec_closedate); 
 dbms_output.put_line('convert MIS_REC_MAS_SEQ: '||x4.CLM_NO); 
 exception 
 when OTHERS then 
 v_err_message := 'MIS_REC_MAS_SEQ'; 
 rollback; 
 End; 

 v_rec_cnt := v_rec_cnt+1; 
 if v_rec_cnt = 1 then -- do it only one time
 FOR xx4 in (
 select CLM_NO, REC_NO, ITEM_SEQ, REC_SEQ, REC_TYPE, REC_KIND, AMT
 from MIS_RECOVERY a
 where clm_no = X4.clm_no 
 and rec_seq in (select max(aa.rec_seq) from mis_recovery aa where aa.clm_no = a.clm_no) 
 ) LOOP
 Begin
 Insert into ALLCLM.MIS_RECOVERY
 (CLM_NO, REC_NO, ITEM_SEQ, REC_SEQ, REC_TYPE, REC_KIND, AMT)
 Values
 (x4.clm_no ,xx4.rec_no , xx4.item_seq , xx4.rec_seq+1 , v_rectype , 
 '1' ,x4.pay_amt ); 
 dbms_output.put_line('convert MIS_RECOVERY: '||xx4.CLM_NO); 
 exception 
 when OTHERS then 
 v_err_message := 'MIS_RECOVERY'; 
 rollback; 
 End; 
 END LOOP ; --xx4
 end if;
 end if; 
 --=== End insert MIS_REC_MAS_SEQ
 
 Begin
 Insert into ALLCLM.MIS_CMS_PAID
 (CLM_NO, PAY_NO, PAY_STS, SECTN, RISK_CODE, CLM_SEQ ,
 PREM_CODE, TYPE, CORR_SEQ, PAY_AMT, TOTAL_PAY_AMT , 
 DEDUCT_AMT, TOT_DEDUCT_AMT ,
 SALVAGE_AMT , TOT_SALVAGE_AMT 
 )
 Values
 (x4.CLM_NO, x4.PAY_NO, x4.PAY_STS, x4.SECTN, x4.RISK_CODE, x4.CLM_SEQ ,
 x4.PREM_CODE, V_TYPE , x4.CORR_SEQ, cms_pay_amt , cms_tot_pay_amt, 
 cms_deduct_amt ,cms_tot_deduct_amt ,
 cms_salvage_amt ,cms_tot_salvage_amt
 ); 
 dbms_output.put_line('convert mis_cms_paid: '||x4.CLM_NO); 
 exception 
 when OTHERS then 
 v_err_message := 'MIS_CMS_PAID'; 
 rollback; 
 End;
 End Loop;
 
 End; 

 v_offset1 := null;
 v_offset2 := null;
 BEGIN
 FOR X3 IN (
 SELECT CLM_NO, PAY_NO, '0' PAY_STS,TRN_SEQ, AMD_DATE, PAYEE_TYPE, 
 PAYEE_CODE, PAYEE_SEQ PAY_SEQ , PAYEE_NAME, PAYEE_AMT, P_CONVERT_PAYMENT.CONVERT_PAYMENT_METHOD(SETTLE) SETTLE, SEND_TITLE, 
 SEND_ADDR1, SEND_ADDR2 ,ACC_NO ,ACC_NAME ,BANK_CODE ,BANK_BR_CODE ,BR_NAME ,
 SALVAGE_FLAG ,DEDUCT_FLAG ,SALVAGE_AMT ,DEDUCT_AMT
 FROM NC_PAYEE A 
 WHERE A.CLM_NO = v_clm_no 
 AND A.PAY_NO =v_pay_no
-- AND A.TRN_SEQ = v_trn_seq 
 AND a.trn_seq in (select max(aa.trn_seq) from NC_PAYEE aa where aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
 )LOOP 
 v_offset2 := null;
 v_offset1 := null;
 IF x3.DEDUCT_FLAG = '1' THEN -- offset หัก
 v_offset2 := 'P' ; 
 ELSIF x3.DEDUCT_FLAG = '2' THEN -- post นำส่ง
 v_offset2 := 'M' ; 
 END IF;

 IF x3.SALVAGE_FLAG = '1' THEN -- offset หัก
 v_offset1 := 'P' ; 
 ELSIF x3.SALVAGE_FLAG = '2' THEN -- post นำส่ง
 v_offset1 := 'M' ; 
 END IF;
 dbms_output.put_line('convert mis_clm_payee: '||x3.CLM_NO||' paye_code='||X3.PAYEE_CODE||' PaySeq='|| X3.PAY_SEQ); 
 Begin
 if X3.pay_seq=1 then -- update account data for MIS_CLM_PAID
 UPDATE MIS_CLM_PAID
 SET acc_no = X3.ACC_NO ,bank_code = X3.BANK_CODE ,bank_br_code = X3.BANK_BR_CODE
 WHERE CLM_NO = X3.CLM_NO
 and PAY_NO = X3.PAY_NO
 and corr_seq = X3.TRN_SEQ ;
 end if;
 
 Insert into MISC.MIS_CLM_PAYEE
 (CLM_NO, PAY_NO, PAY_STS, PAY_SEQ, PAYEE_TYPE, 
 PAYEE_CODE , PAYEE_NAME, PAYEE_AMT, SETTLE, SEND_TITLE, 
 SEND_ADDR1, SEND_ADDR2 
 ,ACC_NO ,ACC_NAME ,BANK_CODE ,BANK_BR_CODE ,BR_NAME
 ,CORR_SEQ ,CORR_DATE,
 PAYEE_OFFSET ,PAYEE_OFFSET2 ,SALVAGE_AMT ,DEDUCT_AMT)
 Values
 (X3.CLM_NO, X3.PAY_NO, X3.PAY_STS, X3.PAY_SEQ, X3.PAYEE_TYPE, 
 X3.PAYEE_CODE , X3.PAYEE_NAME, X3.PAYEE_AMT, X3.SETTLE, X3.SEND_TITLE, 
 X3.SEND_ADDR1, X3.SEND_ADDR2 ,X3.ACC_NO ,X3.ACC_NAME ,X3.BANK_CODE ,X3.BANK_BR_CODE ,X3.BR_NAME
 ,X3.TRN_SEQ ,X3.AMD_DATE,
-- ,3 ,sysdate,
 v_offset1 ,v_offset2 ,X3.SALVAGE_AMT ,X3.DEDUCT_AMT
 );
 dbms_output.put_line('convert mis_clm_payee: '||x3.CLM_NO||' paye_code='||X3.PAYEE_CODE); 
 exception 
 when OTHERS then 
 v_err_message := 'MIS_CLM_PAYEE'; 
 rollback; 
 End;
 End Loop;
 
 END;
 
 Begin

 P_CONVERT_PAYMENT.GET_SALVAGE_DEDUCT_RECOV_FLAG(v_clm_no ,v_pay_no ,o_salvage ,o_deduct ,o_recov) ;
 FOR X5 IN 
 ( 
 select clm_no ,pol_no ,pol_run ,corr_seq ,channel ,prod_grp ,prod_type ,clm_date ,tot_res ,close_date ,reopen_date ,clm_sts
 from mis_clm_mas_seq a
 where clm_no = v_clm_no
 and corr_seq in (select max(aa.corr_Seq) from mis_clm_mas_seq aa where aa.clm_no = a.clm_no) 
 )
 Loop
 Begin
 Insert into ALLCLM.MIS_CLM_MAS_SEQ
 (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, 
 CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE, TOT_RES, 
 TOT_PAID, CLM_STS ,
 CLOSE_DATE ,REOPEN_DATE)
 Values
 (x5.CLM_NO, x5.POL_NO, x5.POL_RUN, x5.CORR_SEQ+1, sysdate, 
 x5.CHANNEL, x5.PROD_GRP, x5.PROD_TYPE, x5.CLM_DATE, x5.TOT_RES, 
 v_pay_amt, V_CLMSTS,
 V_CLOSEDATE ,V_REOPENDATE); 
-- dbms_output.put_line('convert mis_clm_mas_seq: '||x5.CLM_NO||' seq=' || x5.CORR_SEQ+1); 
 dbms_output.put_line('convert mis_clm_mas_seq: '||x5.CLM_NO||' STS=' || V_CLMSTS); 
 
 update allclm.MIS_CLM_MAS
 set tot_paid = v_pay_amt
 ,clm_sts = V_CLMSTS ,CLOSE_DATE = V_CLOSEDATE ,REOPEN_DATE = V_REOPENDATE
 ,deduct_rec_flag =o_deduct ,salvage_rec_flag =o_salvage ,recovery_rec_flag =o_recov
 where clm_no = v_clm_no ; 
 dbms_output.put_line('convert mis_clm_mas: '||x5.CLM_NO); 
 exception 
 when OTHERS then 
 v_err_message := 'MIS_CLM_MAS_SEQ'; 
 rollback; 
 End;
 End Loop;
 End; 

 COMMIT; -- last commit 

End CONV_INSERT_MISC_TABLE; 
 
PROCEDURE EMAIL_NOTICE_APPRV(i_clm IN VARCHAR2 ,i_pay IN VARCHAR2 ,i_sts IN VARCHAR2) IS
 v_to varchar2(1000);
 v_cc varchar2(1000);
 v_bcc varchar2(1000);
 v_allcc varchar2(2000);
 v_from varchar2(50):= 'AdminClm@bangkokinsurance.com' ; 
 v_dbins varchar2(10);
 v_whatsys varchar2(30);
 x_body varchar2(3000);
 x_subject varchar2(1000);
 v_logrst varchar2(200);
 v_link varchar2(200);
 v_clmmen varchar2(10);
 v_apprv varchar2(10);
 v_remark varchar2(500);
 v_clmmen_name varchar2(250);
 v_apprv_name varchar2(250);
 v_pay_descr varchar2(100);
 v_rst varchar2(1000);
 
 v_cnt1 number:=0;
BEGIN
 
 FOR X in (
 select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail 
 from nc_med_email a
 where module = 'NONPA-APPRV' 
 and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
 and direction = 'BCC' and CANCEL is null 
 ) LOOP
 v_bcc := v_bcc || x.ldap_mail ||';' ;
 END LOOP;
 
 begin 
 select UPPER(substr(instance_name,1,8)) instance_name 
 into v_dbins
 from v$instance; 
 if v_dbins='UATBKIIN' then
 v_whatsys := '[ระบบทดสอบ]';
 v_link := p_claim_send_mail.get_link_bkiapp('UAT') ;
 else 
 v_whatsys := null;
 v_link := p_claim_send_mail.get_link_bkiapp('PROD') ;
 end if; 
 exception 
 when no_data_found then 
 v_dbins := null;
 when others then 
 v_dbins := null;
 end; 
 
 begin 
 select clm_men ,P_claim_send_mail.get_bkiuser_name(a.clm_men), approve_id ,P_claim_send_mail.get_bkiuser_name(a.approve_id) ,remark
 into v_clmmen, v_clmmen_name ,v_apprv ,v_apprv_name ,v_remark 
 from nc_payment_apprv a 
 where a.clm_no = I_clm 
 and a.pay_no = I_pay 
 and a.trn_seq = (select max(b.trn_seq) 
 from nc_payment_apprv b 
 where a.clm_no = b.clm_no 
 and a.pay_no = b.pay_no); 
 
 exception 
 when no_data_found then 
 null;
 when others then 
 null; 
 end; 
 
 if i_sts = 'NONPASTSAPPRV03' then -- send email to all loop staff 
 for e1 in (
 select distinct core_ldap.GET_EMAIL_FUNC(clm_men) e_mail
 from nc_payment_apprv a 
 where a.clm_no = I_clm
 and a.pay_no = I_pay 
 ) loop
 v_cnt1 := v_cnt1+1;
 if v_cnt1 = 1 then
 v_allcc := e1.e_mail||';' ; 
 else
 v_allcc := v_allcc||e1.e_mail||';' ; 
 end if; 
 end loop;
 else
 v_allcc := '';
 end if;
 
 if i_sts in ('NONPASTSAPPRV02' ,'NONPASTSAPPRV05' ) then -- Send Apprv
 if i_sts = 'NONPASTSAPPRV05' then
 x_subject := 'เรื่องขออนุมัติการจ่ายค่าสินไหม '||'(อนุมัติผ่าน)'||v_whatsys; 
 else
 x_subject := 'เรื่องขออนุมัติการจ่ายค่าสินไหม '||v_whatsys; 
 end if;
 
 x_body := '<HTML>'|| 
 '<HEAD>'|| 
 '<TITLE>Approval Non PA Claim Payment</TITLE>'|| 
 '</HEAD>'|| 
 '<BODY bgcolor=''#FFFFCC''>'|| 
 ' <font color=#0000CC><h3>ระบบ Approval Non PA Claim Payment </h3></font>'|| 
 '<P>'|| 
 ' เรียน คุณ '||v_apprv_name||'<br />'|| 
 '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'|| 
 'ขณะนี้ท่านมีรายการที่ต้องพิจารณาในระบบ'|| 
 '<font color=#009900> Approval Non PA Claim Payment'||'</font> '|| 
 'ซึ่งส่งมาจาก คุณ '||v_clmmen_name|| '&'||'nbsp;'||'&'||'nbsp;'||'' ||'</br>'|| 
 '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'|| 
 '<font color=#0033CC >'||'Claim No. : '||'</font>'||'<font color=#CC0000>'||I_clm||'</font>'|| 
 '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'|| 
 '<font color=#0033CC>'||'Payment No. : '||'</font>'||'<font color=#CC0000>'||I_pay||'</font>'|| 
 '</P>'|| 
 '<hr/>'|| 
 '<P>'|| 
 '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'กรุณาเข้าระบบ Approval Non PA Claim Payment บน '|| '&'||'nbsp;'||'&'||'nbsp;'|| 
 '<font color=#0033CC; font-weight=bold">'||'<A HREF="'||v_link||'">'||'BKI App On Web'||'</A>'||'</font>'|| '&'||'nbsp;'||'&'||'nbsp;'||'เพื่อพิจารณา'|| 
 '</P>'|| 
 '</BODY>'|| 
 '</HTML>'; 
 v_to := core_ldap.GET_EMAIL_FUNC(v_apprv);
 v_cc := core_ldap.GET_EMAIL_FUNC(v_clmmen); 
 elsif i_sts in ('NONPASTSAPPRV03' ,'NONPASTSAPPRV06' ,'NONPASTSAPPRV04') then -- Apprv ,disapprv
 if i_sts = 'NONPASTSAPPRV03' then
 v_pay_descr := 'อนุมัติการจ่ายค่าสินไหม'; 
 elsif i_sts = 'NONPASTSAPPRV06' then
 v_pay_descr := 'อนุมัติการจ่ายค่าสินไหม (อนุมัติผ่าน)'; 
 elsif i_sts = 'NONPASTSAPPRV04' then
 v_pay_descr := 'ไม่อนุมัติการจ่ายค่าสินไหม'; 
 end if;
 
 x_subject := 'เรื่องผลการอนุมัติการจ่ายค่าสินไหม '||v_whatsys; 
 x_body := '<HTML>'|| 
 '<HEAD>'|| 
 '<TITLE>Approval Non PA Claim Payment</TITLE>'|| 
 '</HEAD>'|| 
 '<BODY bgcolor=''#FFFFCC''>'|| 
 ' <font color=#0000CC><h3>ระบบ Approval Non PA Claim Payment </h3></font>'|| 
 '<P>'|| 
 ' ถึง คุณ '||v_clmmen_name ||'<br />'|| 
 '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'|| 
 'ตามที่ท่านได้ขออนุมัติงานผ่านทางระบบ '||'<font color=#009900>'||' Approval Non PA Claim Payment '||'</font>'||' ขณะนี้ '||'<br />'|| 
 'ผลการขออนุมัติของท่าน คือ '||'<font color=#FF0000>'||v_pay_descr||'</font>'||' <br/>'|| 
 'ซึ่งส่งมาจาก คุณ '||v_apprv_name||' <br/>'|| 
 'หมายเหตุ : '||v_remark||' <br/>'|| 
 'ท่านสามารถตรวจสอบได้ที่ ระบบ Approval Non PA Claim Payment'|| 
 '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp; <br/>'|| 
 '<font color=#0033CC >'||'Claim No. : '||'</font>'||'<font color=#CC0000>'||I_clm||'</font>'|| 
 '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'|| 
 '<font color=#0033CC>'||'Payment No. : '||'</font>'||'<font color=#CC0000>'||I_pay||'</font>'|| 
 '</P>'|| 
 '<hr/>'|| 
 '<P>'|| 
 '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'กรุณาเข้าระบบ Approval Non PA Claim Payment '||' บน '||'&'||'nbsp;'||'&'||'nbsp;'|| 
 '<span style ="color=#0033CC; font-weight=bold">'||'<A HREF="'||v_link||'">BKI App On Web'||'</A>'||'</span>'|| '&'||'nbsp;'||'&'||'nbsp;'||'เพื่อรับทราบผลการพิจารณา'|| 
 '</P>'|| 
 '</BODY>'|| 
 '</HTML>'; 
 v_to := core_ldap.GET_EMAIL_FUNC(v_clmmen);
 v_cc := core_ldap.GET_EMAIL_FUNC(v_apprv); 
 end if;
 
 if v_dbins='DBBKIINS' then
 null; 
 else 
 v_to := v_bcc; -- for test
 v_cc := ''; -- for test
 end if; 
-- dbms_output.put_line('to: '||v_to ); 
-- dbms_output.put_line('allcc: '||v_allcc ); 
-- dbms_output.put_line('cc: '||v_cc ); 
-- dbms_output.put_line('bcc: '||v_bcc ); 
 if v_to is not null then
 nc_health_package.generate_email(v_from, v_to ,
 x_subject, 
 x_body 
 ,v_cc
 ,v_bcc); 
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_NOTICE_APPRV' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_pay:'||I_pay||' success::' ,'success' ,v_rst) ;

 if v_allcc is not null and v_cnt1 > 1 then -- inform email for colleage
 nc_health_package.generate_email(v_from, v_allcc ,
 x_subject||' (FYI)', 
 x_body 
 ,null
 ,v_bcc); 
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_NOTICE_APPRV' ,'step: send FYI email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_pay:'||I_pay||' success::' ,'success' ,v_rst) ; 
 end if;
 end if;

EXCEPTION
 WHEN OTHERS THEN
 --NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail Bancas' ,'Error: '||sqlerrm ,v_logrst);
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_NOTICE_APPRV' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_pay:'||I_pay||' error::'||sqlerrm ,'error' ,v_rst) ;
 dbms_output.put_line('Error: '||sqlerrm );
END EMAIL_NOTICE_APPRV; --email_notice bancas 


PROCEDURE EMAIL_CWP_LETTER(i_clm IN VARCHAR2 ,i_pay IN VARCHAR2 ) IS
 v_to varchar2(1000);
 v_cc varchar2(1000);
 v_bcc varchar2(1000);
 v_allcc varchar2(2000);
 v_from varchar2(50):= 'AdminClm@bangkokinsurance.com' ; 
 v_dbins varchar2(10);
 v_whatsys varchar2(30);
 x_body varchar2(3000);
 x_subject varchar2(1000);
 x_listmail varchar2(1000);
 
 v_logrst varchar2(200);
 v_link varchar2(200);
 v_clmmen varchar2(10);
 v_remark varchar2(500);
 v_cwpcode varchar2(250);
 v_clmmen_name varchar2(250);
 v_polno varchar2(20);
 v_polrun number(10);
 v_policy varchar2(50);
 v_cusname varchar2(250);
 v_sumins number;
 v_frdate date;
 v_todate date;
 v_lossdate date;
 v_lossdetail varchar2(500);
 v_clmplace varchar2(500);
 v_cause varchar2(250);
 v_deptid varchar2(5);
 v_divid varchar2(5);
 v_team varchar2(5);
 v_position_grp varchar2(5);
 
 v_rst varchar2(1000);
 
 v_cnt1 number:=0;
 
 i_sts varchar2(10);
BEGIN
 
 FOR X in (
 select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail 
 from nc_med_email a
 where module = 'NONPA-CWP' 
 and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
 and direction = 'BCC' and CANCEL is null 
 ) LOOP
 v_bcc := v_bcc || x.ldap_mail ||';' ;
 END LOOP;
 
 begin 
 select UPPER(substr(instance_name,1,8)) instance_name 
 into v_dbins
 from v$instance; 
 if v_dbins='UATBKIIN' then
 v_whatsys := '[ระบบทดสอบ]';
 v_link := p_claim_send_mail.get_link_bkiapp('UAT') ;
 else 
 v_whatsys := null;
 v_link := p_claim_send_mail.get_link_bkiapp('PROD') ;
 end if; 
 exception 
 when no_data_found then 
 v_dbins := null;
 when others then 
 v_dbins := null;
 end; 
 
 begin 
 select pol_no ,pol_run , cus_name , mas_sum_ins ,fr_date ,to_date , loss_date ,loss_detail ,clm_place , cwp_remark ,clm_user 
 ,(select name_th from CLM_CAUSE_STD a where a.cause_code = x.cause_code and a.cause_seq = x.cause_seq) 
 ,(select descr from clm_constant where key = cwp_code) cwpcode 
 into v_polno ,v_polrun , v_cusname ,v_sumins ,v_frdate ,v_todate ,v_lossdate ,v_lossdetail ,v_clmplace ,v_remark ,v_clmmen
 ,v_cause ,v_cwpcode
 from nc_mas x
 where clm_no = i_clm--and cwp_remark is not null 
 ; 
 
-- p_acc_package.write_pol(v_policy ,v_polno ,v_polrun);
 v_policy := v_polno||v_polrun ;
 
 begin
 select dept_id ,div_id ,team_id ,position_grp_id 
 into v_deptid ,v_divid ,v_team ,v_position_grp
 from bkiuser
 where user_id =v_clmmen ; 
 
 if v_deptid <> '22' then -- not Claim Dept.
 begin
 select amd_user into v_clmmen
 from nc_reserved a
 where clm_no = i_clm
 and trn_seq in (select max(aa.trn_seq) from nc_reserved aa where aa.clm_no = a.clm_no)
 and status = 'NCCLMSTS03' and rownum=1; 
 
 exception 
 when no_data_found then 
 null;
 when others then 
 null; 
 end; 
 
 select dept_id ,div_id ,team_id ,position_grp_id 
 into v_deptid ,v_divid ,v_team ,v_position_grp
 from bkiuser
 where user_id =v_clmmen ; 
 
 end if;
 
 v_cc := core_ldap.GET_EMAIL_FUNC(ALLCLM.P_NON_PA_APPROVE.Get_Special_email('CC',v_clmmen)) ;
 
 if v_position_grp >42 then -- Case Staff
 for c1 in (select core_ldap.GET_EMAIL_FUNC(P_NON_PA_APPROVE.Get_Special_email('TO',user_id)) tl_email
 from bkiuser
 where dept_id = v_deptid
 and div_id = v_divid
 and team_id = v_team
 and position_grp_id in ('41','42')) loop
 v_to := v_to || c1.tl_email ||';' ; 
 end loop;
 else -- Case TL up
 v_to := v_cc ; 
 end if;
 exception 
 when no_data_found then 
 null;
 when others then 
 null; 
 end; 

 exception 
 when no_data_found then 
 null;
 when others then 
 null; 
 end; 
 
 if v_polno is not null then
 
 if v_dbins='UATBKIIN' then
 x_listmail := '<tr><td colspan=2>'||
 '<br/>'||'<br/>'||'<br/>'||'<br/>'||'<br/>'||
 '<p style="color:red">ถ้าเป็นระบบจริง email นี้จะส่งไปที่รายชื่อตามด้านล่าง </p><br/>'||
 'to: '||v_to||'<br/>'||
 'cc: '||v_cc||'<br/>'||
 '</td></tr>';
 end if;
 
 x_subject := 'ใบสรุปปิดเคลม (CWP) '||v_whatsys; 
 X_BODY := '<!DOCTYPE html>'||
 '<html lang="en">'||'<head><meta charset="utf-8">'||
 '<title>จดหมาย CWP</title>'||'</head>'||
 '<body bgcolor="#FFFFCC" style="font-family:''Angsana New'' ">'||
 '<h2 align="center">ใบสรุปปิดเคลมที่ไม่มีการชดใช้ค่าสินไหมทดแทน (CWP)</h2>'||
 '<div>'||
 '<table align="left"><tr><td>หมายเลขกรมธรรม์'||'</td>'||
 '<td>'||v_policy||'</td></tr>'||
 '<tr><td>หมายเลขเรียกร้อง'||'</td>'||
 '<td>'||i_clm||'</td></tr>'||
 '<tr><td>ผู้เอาประกันภัย'||'</td><td>'||v_cusname||'</td> </tr>'||
 '<tr><td>ทุนประกันภัย/เงินจำกัดความรับผิด(บาท)'||'</td><td>'||to_char(v_sumins,'9,999,999,999,990.00')||'</td></tr>'||    
    '<tr><td>ระยะเวลาประกันภัย'||'</td><td>'||v_frdate||'  -  '||v_todate||'</td></tr>'||
    '<tr><td>วันที่เกิดเหตุ'||'</td><td>'||v_lossdate||'</td></tr>'||
    '<tr><td colspan="2">รายละเอียด'||'</td></tr>'||
    '<tr><td colspan="2">'||
 --   '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||
     '<table align="left"><tr><td style="font-weight:bold">ลักษณะความเสียหาย'||'</td><td>'||v_lossdetail||'</td></tr>'||
    '<tr><td style="font-weight:bold">สาเหตุความเสียหาย'||'</td><td>'||v_cause||'</td></tr>'||
    '<tr><td style="font-weight:bold">สถานที่เกิดเหตุ'||'</td><td>'||v_clmplace||'</td>    </tr>'||
    '<tr><td style="font-weight:bold">CLOSED WITHOUT PAYMENT DUE TO'||'</td><td>'||v_cwpcode||' : '||v_remark||
    '</td></tr>'||
    x_listmail||
    '</table>'||   
    '</td></tr></table>'||
    '<br/>'||
    '</div>'|| 
    '</body></html>' ;
    -- v_to := core_ldap.GET_EMAIL_FUNC(v_apprv);
    -- v_cc := core_ldap.GET_EMAIL_FUNC(v_clmmen); 
--    dbms_output.put_line('to: '||v_to ); 
--    dbms_output.put_line('cc: '||v_cc ); 
--    v_bcc := 'taywin.s@bangkokinsurance.com' ||';' ;
--    v_to :=  'taywin.s@bangkokinsurance.com' ||';' ;
 end if; 
 
 if v_dbins='DBBKIINS' then
 null; 
 else 
 v_to := v_bcc; -- for test
 v_cc := ''; -- for test
 end if; 
 
 dbms_output.put_line(x_body);
 
 dbms_output.put_line('dummy to: '||v_to ); 
 dbms_output.put_line('allcc: '||v_allcc ); 
 dbms_output.put_line('dummy cc: '||v_cc ); 
 dbms_output.put_line('bcc: '||v_bcc ); 
 if v_to is not null then
 nc_health_package.generate_email(v_from, v_to ,
 x_subject, 
 x_body 
 ,v_cc
 ,v_bcc); 
-- nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_NOTICE_APPRV' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_pay:'||I_pay||' success::' ,'success' ,v_rst) ;
 end if;

EXCEPTION
 WHEN OTHERS THEN
 --NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail Bancas' ,'Error: '||sqlerrm ,v_logrst);
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_CWP' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_clm:'||I_clm||' error::'||sqlerrm ,'error' ,v_rst) ;
 dbms_output.put_line('Error: '||sqlerrm );
END EMAIL_CWP_LETTER; --email_notice bancas 


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
 from acr_mas xxx
 where payment_no = i_payno
 and cancel_vou_no is null ;
 
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
-- v_err_message varchar2(1000); 
 v_tmprst varchar2(1000); 
 v_totpaid number:=0;
 V_CLMSTS varchar2(2); 
 v_found varchar2(20);
 v_closedate date;
 v_reopendate date;
BEGIN
 begin
 select CLM_NO into v_found
 from mis_clm_paid a
 where clm_no = v_clmno
 and pay_no = v_payno
 and corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no)
 and rownum=1;
 exception
 when no_data_found then
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'No claim data on BKIAPP ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
 return true;
 when others then
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'No claim data on BKIAPP ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
 return true;
 end;

 FOR x1 in (
 select CLM_NO, PAY_NO, PAY_STS, SETTLE, PART, ATTACHED ,
 PAY_TYPE, PRT_FLAG, REMARK, PAY_CURR_CODE, PAY_CURR_RATE, 
 PAY_TOTAL ,TOTAL_PAY_TOTAL, CORR_SEQ, CORR_DATE, STATE_FLAG, VAT_PERCENT, 
 DEDUCT_AMT, TOT_DEDUCT_AMT , REC_PAY_DATE, PRINT_BATCH ,
 INVOICE_NO ,JOB_NO 
 ,ACC_NO ,ACC_NAME ,BANK_CODE ,BR_NAME ,BANK_BR_CODE 
 from mis_clm_paid a
 where clm_no = v_clmno
 and pay_no = v_payno
 and corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no) 
 ) LOOP
 Begin
 Insert into ALLCLM.MIS_CLM_PAID
 (CLM_NO, PAY_NO, PAY_STS, SETTLE, PART, ATTACHED ,
 PAY_TYPE, PRT_FLAG, REMARK, PAY_CURR_CODE, PAY_CURR_RATE, 
 PAY_TOTAL ,TOTAL_PAY_TOTAL, CORR_SEQ, CORR_DATE, STATE_FLAG, VAT_PERCENT, 
 DEDUCT_AMT, TOT_DEDUCT_AMT , REC_PAY_DATE, PRINT_BATCH ,
 INVOICE_NO ,JOB_NO
 ,ACC_NO ,ACC_NAME ,BANK_CODE ,BR_NAME ,BANK_BR_CODE )
 Values
 (x1.CLM_NO, x1.PAY_NO, x1.PAY_STS , x1.SETTLE, x1.PART ,x1.ATTACHED ,
 x1.pay_type, x1.prt_flag , x1.remark, x1.PAY_CURR_CODE, x1.PAY_CURR_RATE, 
 0 , 0 , x1.CORR_SEQ +1 ,sysdate , x1.STATE_FLAG, x1.VAT_PERCENT, 
 0 , 0 , X1.REC_PAY_DATE, x1.PRINT_BATCH ,
 x1.INVOICE_NO ,x1.JOB_NO 
 ,x1.ACC_NO ,x1.ACC_NAME ,x1.BANK_CODE ,x1.BR_NAME ,x1.BANK_BR_CODE);
 v_cnt := v_cnt +1; 
 dbms_output.put_line('cancel mis_clm_paid: '||x1.CLM_NO||' payno: '||x1.PAY_NO);
 exception 
 when OTHERS then 
 v_rst := 'MIS_CLM_PAID : '||sqlerrm; 
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: insert MIS_CLM_PAID ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
 rollback; 
 return false; 
 End; 
 END LOOP;

 FOR X2 in (
 select CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, 
 RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, 
 CORR_SEQ, LF_FLAG, RI_SUB_TYPE
 from MIS_CRI_PAID a
 where clm_no = v_clmno
 and pay_no = v_payno
 and corr_seq in (select max(aa.corr_seq) from MIS_CRI_PAID aa where aa.pay_no = a.pay_no)
 ) LOOP
 Begin
 Insert into ALLCLM.MIS_CRI_PAID 
 (CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, 
 RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, 
 CORR_SEQ, LF_FLAG, RI_SUB_TYPE)
 Values
 (X2.CLM_NO, X2.PAY_NO, X2.PAY_STS , X2.RI_CODE, X2.RI_BR_CODE, 
 X2.RI_TYPE, 0, X2.LETT_NO, X2.LETT_PRT, X2.LETT_TYPE, 
 X2.CORR_SEQ+1, X2.LF_FLAG, X2.RI_SUB_TYPE ); 
 v_cnt := v_cnt +1; 
 dbms_output.put_line('cancel MIS_CRI_PAID: '||X2.CLM_NO||' payno: '||X2.PAY_NO);
 exception 
 when OTHERS then 
 v_rst := 'MIS_CRI_PAID : '||sqlerrm; 
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: insert MIS_CRI_PAID ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
 rollback; 
 return false; 
 End; 
 END LOOP;
 
 FOR x3 in (
 select CLM_NO, PAY_NO, PAY_STS, PAY_SEQ, PAYEE_TYPE, 
 PAYEE_CODE , PAYEE_NAME, PAYEE_AMT, SETTLE, SEND_TITLE, 
 SEND_ADDR1, SEND_ADDR2 
 ,ACC_NO ,ACC_NAME ,BANK_CODE ,BANK_BR_CODE ,BR_NAME
 ,CORR_SEQ ,CORR_DATE,
 PAYEE_OFFSET ,PAYEE_OFFSET2 ,SALVAGE_AMT ,DEDUCT_AMT
 from mis_clm_payee a
 where clm_no = v_clmno
 and pay_no = v_payno
 and corr_seq in (select max(aa.corr_seq) from mis_clm_payee aa where aa.pay_no = a.pay_no)
 ) LOOP
 Begin
 Insert into MISC.MIS_CLM_PAYEE
 (CLM_NO, PAY_NO, PAY_STS, PAY_SEQ, PAYEE_TYPE, 
 PAYEE_CODE , PAYEE_NAME, PAYEE_AMT, SETTLE, SEND_TITLE, 
 SEND_ADDR1, SEND_ADDR2 
 ,ACC_NO ,ACC_NAME ,BANK_CODE ,BANK_BR_CODE ,BR_NAME
 ,CORR_SEQ ,CORR_DATE,
 PAYEE_OFFSET ,PAYEE_OFFSET2 ,SALVAGE_AMT ,DEDUCT_AMT)
 Values
 (X3.CLM_NO, X3.PAY_NO, X3.PAY_STS , X3.PAY_SEQ, X3.PAYEE_TYPE, 
 X3.PAYEE_CODE , X3.PAYEE_NAME, 0 , X3.SETTLE, X3.SEND_TITLE, 
 X3.SEND_ADDR1, X3.SEND_ADDR2 ,X3.ACC_NO ,X3.ACC_NAME ,X3.BANK_CODE ,X3.BANK_BR_CODE ,X3.BR_NAME
 ,X3.CORR_SEQ +1 ,sysdate,
 X3.PAYEE_OFFSET ,X3.PAYEE_OFFSET2 ,0 ,0
 );
 v_cnt := v_cnt +1; 
 dbms_output.put_line('cancel mis_clm_payee: '||x3.CLM_NO||' payno: '||x3.PAY_NO);
 exception 
 when OTHERS then 
 v_rst := 'MIS_CLM_PAYEE : '||sqlerrm; 
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: insert MIS_CLM_PAYEE ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
 rollback; 
 return false; 
 End; 
 END LOOP;

 FOR x4 in (
 select CLM_NO, PAY_NO, PAY_STS, SECTN, RISK_CODE, CLM_SEQ ,
 PREM_CODE, TYPE, CORR_SEQ, PAY_AMT, TOTAL_PAY_AMT , 
 DEDUCT_AMT, TOT_DEDUCT_AMT ,
 SALVAGE_AMT , TOT_SALVAGE_AMT 
 from MIS_CMS_PAID a
 where clm_no = v_clmno
 and pay_no = v_payno
 and corr_seq in (select max(aa.corr_seq) from MIS_CMS_PAID aa where aa.pay_no = a.pay_no)
 ) LOOP
 Begin
 Insert into ALLCLM.MIS_CMS_PAID
 (CLM_NO, PAY_NO, PAY_STS, SECTN, RISK_CODE, CLM_SEQ ,
 PREM_CODE, TYPE, CORR_SEQ, PAY_AMT, TOTAL_PAY_AMT , 
 DEDUCT_AMT, TOT_DEDUCT_AMT ,
 SALVAGE_AMT , TOT_SALVAGE_AMT 
 )
 Values
 (x4.CLM_NO, x4.PAY_NO, X4.PAY_STS , x4.SECTN, x4.RISK_CODE, x4.CLM_SEQ ,
 x4.PREM_CODE, X4.TYPE , x4.CORR_SEQ +1 , 0 , 0, 
 0 ,0 ,
 0 ,0
 ); 
 v_cnt := v_cnt +1; 
 dbms_output.put_line('cancel mis_cms_paid: '||x4.CLM_NO||' payno: '||x4.PAY_NO);
 exception 
 when OTHERS then 
 v_rst := 'MIS_CMS_PAID : '||sqlerrm; 
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: insert MIS_CMS_PAID ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ;
 rollback; 
 return false; 
 End; 
 END LOOP;

 
 begin
 select sum(pay_total) into v_totpaid
 from mis_clm_paid a
 where clm_no = v_clmno 
 and (pay_no, corr_seq) in (select aa.pay_no ,max(aa.corr_seq) from mis_clm_paid aa where aa.clm_no=a.clm_no group by aa.pay_no
 ) and pay_sts='0'; 
 exception
 when no_data_found then
 v_totpaid := 0;
 when others then
 dbms_output.put_line('error'||sqlerrm);
 v_totpaid :=0;
 end; 
 
 V_CLMSTS := '1';
 FOR Y1 in (
 select close_date ,reopen_date
 from nc_mas
 where clm_no = v_clmno
 )LOOP
 IF v_clmsts in ('2','3') THEN
 v_closedate := trunc(sysdate) ;
 v_reopendate := Y1.REOPEN_DATE ;
 ELSIF v_clmsts = '4' THEN
 v_closedate := Y1.CLOSE_DATE ;
 v_reopendate := trunc(sysdate); 
 ELSIF v_clmsts in ('1') THEN 
 v_closedate := null ;
 v_reopendate := Y1.REOPEN_DATE; 
 END IF; 
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: find ReopenDate ' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' ReopenDate '|| v_reopendate ,'error' ,v_tmprst) ;
 END LOOP; 
 
 FOR X5 IN 
 ( 
 select clm_no ,pol_no ,pol_run ,corr_seq ,channel ,prod_grp ,prod_type ,clm_date ,tot_res ,close_date ,reopen_date ,clm_sts
 from mis_clm_mas_seq a
 where clm_no = v_clmno
 and corr_seq in (select max(aa.corr_Seq) from mis_clm_mas_seq aa where aa.clm_no = a.clm_no) 
 )
 Loop
 Begin
 Insert into ALLCLM.MIS_CLM_MAS_SEQ
 (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, 
 CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE, TOT_RES, 
 TOT_PAID, CLM_STS ,
 CLOSE_DATE ,REOPEN_DATE)
 Values
 (x5.CLM_NO, x5.POL_NO, x5.POL_RUN, x5.CORR_SEQ+1, sysdate, 
 x5.CHANNEL, x5.PROD_GRP, x5.PROD_TYPE, x5.CLM_DATE, x5.TOT_RES, 
 v_totpaid, V_CLMSTS,
 v_closedate ,v_reopendate); 
 -- dbms_output.put_line('convert mis_clm_mas_seq: '||x5.CLM_NO||' seq=' || x5.CORR_SEQ+1); 
 dbms_output.put_line('convert mis_clm_mas_seq: '||x5.CLM_NO||' STS=' || V_CLMSTS); 
 
 update allclm.MIS_CLM_MAS
 set tot_paid = v_totpaid
 ,clm_sts = V_CLMSTS ,CLOSE_DATE = v_closedate ,REOPEN_DATE = v_reopendate
 where clm_no = v_clmno ; 
 dbms_output.put_line('convert mis_clm_mas: '||x5.CLM_NO); 
 exception 
 when OTHERS then 
 v_rst := 'MIS_CLM_MAS_SEQ : '||sqlerrm;
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CANCEL_PAYMENT' ,'step: MIS_CLM_MAS' ,'v_clm_no:'||v_clmno||' v_pay_no:'||v_payno||' || '|| v_rst ,'error' ,v_tmprst) ; 
 rollback; 
 return false; 
 End;
 End Loop;
 
 IF v_cnt > 0 THEN
 P_NON_PA_CLM_PAYMENT.save_oic_payment_seq(v_clmno,v_payno,'D');
 COMMIT;
 return true;
 ELSE
 v_rst := 'ไม่พบข้อมูล!';
 return false; 
 END IF;

EXCEPTION
 WHEN OTHERS THEN
 v_rst := 'error CANCEL_PAYMENT:'||sqlerrm; 
 ROLLBACK;
 return false; 
END CANCEL_PAYMENT;

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
 elsif c_rec.clm_sts not in ('6','7','2') then 
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
 
 FOR x in (
    select payee_amt
    from nc_payee a
    where pay_no = vPayNo
    and trn_seq in (select max(aa.trn_seq) from nc_payee aa where aa.pay_no = a.pay_no ) 
 ) LOOP
    if x.payee_amt <= 0 then
         P_RST := c_rec.clm_no||': Has Payee Amount = 0 ,Cannot Post Transactio to ACR ' ; 
         return false;     
    end if;
 END LOOP;
 
 v_chk:= true; 
 return v_chk; 
END VALIDATE_INDV; 

FUNCTION POST_MISC(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
-- CURSOR c_clm IS select clm_no ,pol_no ,pol_run ,nvl(policy_number,pol_no||pol_run) policy_number ,prod_grp ,prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,channel ,clm_men 
-- from mis_clm_mas 
-- where clm_no = vClmNo 
-- ; 
-- c_rec c_clm%ROWTYPE; 
 
 
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
  X_CURRCODE    varchar2(5);  
  v_paidCurr    varchar2(5);  
  v_payeeCurr    varchar2(5);  

 M_SEND_TITLE varchar2(100); 
 M_SEND_ADDR1 varchar2(200); 
 M_SEND_ADDR2 varchar2(200); 
 M_PAYEE_CODE varchar2(20); 
 M_PAYEE_NAME varchar2(200); 
 M_PAY_NO varchar2(20); 
 
 M_SPECIAL_FLAG VARCHAR2(1);
 M_SPECIAL_REMARK VARCHAR2(500);
 M_AGENT_MAIL VARCHAR2(150);
 M_AGENT_MAIL_FLAG VARCHAR2(1);
 M_AGENT_MOBILE_NUMBER VARCHAR2(50);
 M_AGENT_SMS_FLAG VARCHAR2(1 );
 M_CUST_MAIL VARCHAR2(150 );
 M_CUST_MAIL_FLAG VARCHAR2(1 );
 M_MOBILE_NUMBER VARCHAR2(50);
 M_SMS_FLAG VARCHAR2(1 ); 
 
 M_PAIDBY_PAYMENT VARCHAR2(1 ); 

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
    select a.clm_no ,a.pol_no ,a.pol_run ,a.end_seq ,a.pol_no||a.pol_run policy_number ,a.prod_grp ,a.prod_type 
    ,t_e th_eng ,mas_cus_code cus_code ,'' agent_code ,'' agent_seq ,'01' br_code 
    ,a.channel ,clm_user clm_men ,P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) clm_sts 
    from nc_mas a
    where a.clm_no = vClmNo
    and P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) in ('6','7','2')
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
         
        for p1 in (
        select a.pay_no ,0 pay_seq ,null pay_date 
        ,0 payee_amt ,sum(pay_amt) pay_total ,0 rec_total ,0 disc_total ,'' payee_code 
        ,min(curr_code) pay_curr_code ,min(curr_rate) pay_curr_rate
        from nc_payment a
        where a.pay_no = vPayno
        and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
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
            
            v_chk_adv := false; 
            for p3 in (
            select payee_code ,payee_seq pay_seq ,payee_amt ,'' prem_offset ,'' payee_offset ,'' payee_offset2 
            ,salvage_flag ,deduct_flag ,salvage_amt ,deduct_amt ,payee_type
            ,bank_code ,bank_br_code ,acc_no ,acc_name ,CONVERT_PAYMENT_METHOD(settle) settle ,curr_code
            ,GRP_PAYEE_FLAG ,EMAIL ,SMS ,AGENT_EMAIL ,AGENT_SMS
            ,SPECIAL_FLAG ,SPECIAL_REMARK
            from nc_payee b
            where b.pay_no = p1.pay_no
            and b.trn_seq in (select max(bb.trn_seq) from nc_payee bb where bb.clm_no =b.clm_no and bb.pay_no = b.pay_no) 
            ) 
            loop 

                v_paidcurr := p1.pay_curr_code;
                if p3.curr_code is null then 
                    v_payeecurr := v_paidcurr ;
                    X_CURRCODE:= v_payeecurr ;
                else
                    X_CURRCODE := p3.curr_code;  
                    v_payeecurr := X_CURRCODE;
                end if;      
                
                --== Part get Email and is Batch Job----
                IF NVL(p3.GRP_PAYEE_FLAG,'N') = 'Y'  THEN 
                    M_PAIDBY_PAYMENT := null;
                ELSE
                    M_PAIDBY_PAYMENT := 'Y';
                END IF;
                
                IF p3.email is not null THEN
                    M_CUST_MAIL := p3.email ; M_CUST_MAIL_FLAG := 'Y' ;
                END IF;
                IF p3.sms is not null THEN
                    M_MOBILE_NUMBER := p3.sms ; M_SMS_FLAG := 'Y' ;                 
                END IF;    
                
                IF p3.agent_email is not null THEN
                    M_AGENT_MAIL := p3.agent_email ; M_AGENT_MAIL_FLAG := 'Y' ;
                END IF;
                IF p3.agent_sms is not null THEN
                    M_AGENT_MOBILE_NUMBER := p3.agent_sms ; M_AGENT_SMS_FLAG := 'Y' ;                 
                END IF;       
                
                M_SPECIAL_FLAG := p3.special_flag;
                M_SPECIAL_REMARK := p3.special_remark;                        
/*                M_GROUP_BATCH :=null; 
                M_CUST_MAIL :=null; 
                M_CUST_MAIL_FLAG :=null;     
                begin
                    select decode(a.clm_user ,null ,'',core_ldap.GET_EMAIL_FUNC(a.clm_user)) ,b.print_batch
                    into  M_CUST_MAIL ,M_GROUP_BATCH
                    from nc_mas a ,nc_payment_info b
                    where A.CLM_NO = b.clm_no
                    and pay_no = p1.pay_no
                    and b.trn_seq in (select max(bb.trn_seq) from nc_payment_info bb where bb.pay_no = b.pay_no);    
                    
                    if M_CUST_MAIL is not null then
                        M_CUST_MAIL_FLAG := 'Y';
                    end if;            
                exception 
                    when no_data_found then
                        M_GROUP_BATCH :=null; 
                        M_CUST_MAIL :=null; 
                        M_CUST_MAIL_FLAG :=null;                         
                    when others then
                        M_GROUP_BATCH :=null; 
                        M_CUST_MAIL :=null; 
                        M_CUST_MAIL_FLAG :=null;                       
                end;                             */
                --== End Part get Email and is Batch Job----
                
                v_DEDUCT_AMT := 0; 
                V_REC_TOTAL := 0;
                V_SAL_TOTAL := 0; 
                 
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
                end loop;   -- p_cms    
                                        
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
               
                IF (v_payeecurr <> v_paidcurr)  THEN -- case different Currency
                    v_ADV_AMT := 0;
                END IF;    
                                                      
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
                                          
                P_CLAIM_ACR.Post_acc_clm_payee_nonpa( c_rec.prod_grp /* P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type */,  
                                    
                c_rec.prod_type /* P_prod_type  IN  acc_clm_payee_tmp.prod_type%type */,
                                                                                
                p1.pay_no /* P_payno      IN  acc_clm_payee_tmp.payment_no%type */,
                                                                                
                p3.pay_seq /* P_seq        IN  acc_clm_payee_tmp.seq%type */,
                                                                                
                '01' /* P_doc_type   IN  acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
                                                                                
                X_CURRCODE /* P_curr_code  IN  acc_clm_payee_tmp.curr_code%type */,                                                                               
                                                                                
                V_PAY_TOTAL /* P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type */,
                                                                                
                p3.payee_code /* P_payee_code IN  acc_clm_payee_tmp.payee_code%type */,
                                                                                
                v_title /* P_title      IN  acc_clm_payee_tmp.title%type */,
                                                                                
                v_name /* P_name       IN  acc_clm_payee_tmp.name%type */, 
                                                                                
                '04' /* P_dept_no    IN  acc_clm_payee_tmp.dept_no%type */,
                                                                                
                M_PAIDBY_PAYMENT /* P_batch_no   IN  acc_clm_payee_tmp.batch_no%type */,
                                                                                
                nvl(v_DEDUCT_AMT,0) /* P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type */,
                                                                                
                v_ADV_AMT /* P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type */,
                                                                                
                v_SAL_TOTAL /* P_salvage_amt    IN  acc_clm_payee_tmp.salvage_amt%type*/,
                                                                                                          
                v_REC_TOTAL /* P_recov_amt    IN  acc_clm_payee_tmp.recov_amt%type*/,    
                                                                                                          
                v_less_other /* P_prem_offset    IN  acc_clm_payee_tmp.less_other%type */ ,                                                                                           

                 p3.bank_code /* p_bank_code in acc_clm_payee_tmp.bank_code%type */ ,
                 
                 p3.bank_br_code /* p_branch_code in acc_clm_payee_tmp.branch_code%type */ ,
                 
                 p3.acc_no /* p_acc_no in acc_clm_payee_tmp.acc_no%type*/,
                 
                 p3.acc_name /* p_acc_name_th in acc_clm_payee_tmp.acc_name_th%type*/,
                 
                 null /* p_acc_name_eng in acc_clm_payee_tmp.acc_name_eng%type*/,
                 
                 null /* p_deposit_type in acc_clm_payee_tmp.deposit_type%type*/,
                 
                 p3.settle /* p_paid_type in acc_clm_payee_tmp.paid_type%type*/,
                 
                 M_SPECIAL_FLAG /* p_special_flag in acc_clm_payee_tmp.special_flag%type*/,
                 
                 M_SPECIAL_REMARK /* p_special_remark in acc_clm_payee_tmp.special_remark%type*/,
                 
                 M_AGENT_MAIL /* p_agent_mail in acc_clm_payee_tmp.agent_mail%type*/,
                 
                 M_AGENT_MAIL_FLAG /* p_agent_mail_flag in acc_clm_payee_tmp.agent_mail_flag%type*/,
                 
                 M_AGENT_MOBILE_NUMBER /* p_agent_mobile_number in acc_clm_payee_tmp.agent_mobile_number%type*/,
                 
                 M_AGENT_SMS_FLAG /* p_agent_sms_flag in acc_clm_payee_tmp.agent_sms_flag%type*/,
                 
                 M_CUST_MAIL /* p_cust_mail in acc_clm_payee_tmp.cust_mail%type*/,
                 
                 M_CUST_MAIL_FLAG /* p_cust_mail_flag in acc_clm_payee_tmp.cust_mail_flag%type*/,
                 
                 M_MOBILE_NUMBER /* p_mobile_number in acc_clm_payee_tmp.mobile_number%type*/, 
                 
                 M_SMS_FLAG /* p_sms_flag in acc_clm_payee_tmp.sms_flag%type*/, 
                                                                                           
                V_RESULT2 /* P_msg       Out varchar2*/ ) ;      
                                                                                  
                if v_result2 is not null then rollback; P_RST:= v_result2||' in P_CLAIM_ACR.Post_acc_clm_payee_tmp'; return false; end if;  
                                           
                dbms_output.put_line('pass post acc payee tmp ! '||p3.payee_code);              
            end loop;   -- end loop payee  P3
            COMMIT; -- post ACC_CLM_TEMP b4 call post GL  
              
--            p_acc_claim.post_gl ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,  
--                                      
--            c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,  
--                                      
--            p1.pay_no /* p_number in varchar2 */,  -- payment no or batch no  
--                                      
--            'P' /* p_flag in varchar2 */,   -- 'P' = Payment, 'B' = Batch  
--                                      
--            V_RESULT3 /* p_err  out varchar2 */);  -- return null if no error  
--              
--            if v_result3 is not null then /* CLR_ACC_TMP; */ P_RST:= v_result3||' in p_acc_claim.post_gl'; return false; end if;       
--                        
--            dbms_output.put_line('pass Post ACR');                      
--                                                           
--            p_acc_claim.get_acr_voucher ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,  
--              
--            c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,  
--              
--            p1.pay_no /* p_number in varchar2 */,   -- payment no or batch no  
--              
--            'P' /* p_flag in varchar2 */,  -- 'P' = Payment, 'B' = Batch  
--              
--            V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,  
--              
--            V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);  
--              
--            IF V_VOUNO is null THEN  
--                P_RST:= ' p_acc_claim.post_gl have any Problem '; return false;  
--            END IF;  
                        
            begin
            null; 
            exception
            when others then
            rollback; P_RST := 'error update claim: '||sqlerrm ; return false;
            end; 
                              
        end loop;    --P1    
    end loop;  
    --// End Run Individual ========  
     COMMIT;  

    return true;  
EXCEPTION  
    WHEN OTHERS THEN  
    rollback; P_RST := 'error update claim: '||sqlerrm ; return false;          
END POST_MISC;  

FUNCTION POST_FIR(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS

 
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
  X_CURRCODE    varchar2(5);  
  v_paidCurr    varchar2(5);  
  v_payeeCurr    varchar2(5);  

 M_SEND_TITLE varchar2(100); 
 M_SEND_ADDR1 varchar2(200); 
 M_SEND_ADDR2 varchar2(200); 
 M_PAYEE_CODE varchar2(20); 
 M_PAYEE_NAME varchar2(200); 
 M_PAY_NO varchar2(20); 
 
 M_SPECIAL_FLAG VARCHAR2(1);
 M_SPECIAL_REMARK VARCHAR2(500);
 M_AGENT_MAIL VARCHAR2(150);
 M_AGENT_MAIL_FLAG VARCHAR2(1);
 M_AGENT_MOBILE_NUMBER VARCHAR2(50);
 M_AGENT_SMS_FLAG VARCHAR2(1 );
 M_CUST_MAIL VARCHAR2(150 );
 M_CUST_MAIL_FLAG VARCHAR2(1 );
 M_MOBILE_NUMBER VARCHAR2(50);
 M_SMS_FLAG VARCHAR2(1 ); 
 
 M_PAIDBY_PAYMENT VARCHAR2(1 ); 

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
    select a.clm_no ,a.pol_no ,a.pol_run ,a.end_seq ,a.pol_no||a.pol_run policy_number ,a.prod_grp ,a.prod_type 
    ,t_e th_eng ,mas_cus_code cus_code ,'' agent_code ,'' agent_seq ,'01' br_code 
    ,a.channel ,clm_user clm_men ,P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) clm_sts 
    from nc_mas a
    where a.clm_no = vClmNo
    and P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) in ('6','7','2')
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
             
        for p1 in (
        select a.pay_no ,0 pay_seq ,null pay_date 
        ,0 payee_amt ,sum(pay_amt) pay_total ,0 rec_total ,0 disc_total ,'' payee_code 
        ,min(curr_code) pay_curr_code ,min(curr_rate) pay_curr_rate
        from nc_payment a
        where a.pay_no = vPayno
        and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
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
            
            v_chk_adv := false;  
            
            for p3 in (
            select payee_code ,payee_seq pay_seq ,payee_amt ,'' prem_offset ,'' payee_offset ,'' payee_offset2 
            ,salvage_flag ,deduct_flag ,salvage_amt ,deduct_amt ,payee_type
            ,bank_code ,bank_br_code ,acc_no ,acc_name ,CONVERT_PAYMENT_METHOD(settle) settle ,curr_code
            ,GRP_PAYEE_FLAG ,EMAIL ,SMS ,AGENT_EMAIL ,AGENT_SMS
            ,SPECIAL_FLAG ,SPECIAL_REMARK            
            from nc_payee b
            where b.pay_no = p1.pay_no
            and b.trn_seq in (select max(bb.trn_seq) from nc_payee bb where bb.clm_no =b.clm_no and bb.pay_no = b.pay_no) 
            ) 
            loop 

                v_paidcurr := p1.pay_curr_code;
                if p3.curr_code is null then 
                    v_payeecurr := v_paidcurr ;
                    X_CURRCODE:= v_payeecurr ;
                else
                    X_CURRCODE := p3.curr_code;  
                    v_payeecurr := X_CURRCODE;
                end if;      
                
                --== Part get Email and is Batch Job----
                IF NVL(p3.GRP_PAYEE_FLAG,'N') = 'Y'  THEN
                    M_PAIDBY_PAYMENT := null;
                ELSE
                    M_PAIDBY_PAYMENT := 'Y';
                END IF;
                
                IF p3.email is not null THEN
                    M_CUST_MAIL := p3.email ; M_CUST_MAIL_FLAG := 'Y' ;
                END IF;
                IF p3.sms is not null THEN
                    M_MOBILE_NUMBER := p3.sms ; M_SMS_FLAG := 'Y' ;                 
                END IF;    
                
                IF p3.agent_email is not null THEN
                    M_AGENT_MAIL := p3.agent_email ; M_AGENT_MAIL_FLAG := 'Y' ;
                END IF;
                IF p3.agent_sms is not null THEN
                    M_AGENT_MOBILE_NUMBER := p3.agent_sms ; M_AGENT_SMS_FLAG := 'Y' ;                 
                END IF;       
                
                M_SPECIAL_FLAG := p3.special_flag;
                M_SPECIAL_REMARK := p3.special_remark;                        
/*                M_GROUP_BATCH :=null; 
                M_CUST_MAIL :=null; 
                M_CUST_MAIL_FLAG :=null;     
                begin
                    select decode(a.clm_user ,null ,'',core_ldap.GET_EMAIL_FUNC(a.clm_user)) ,b.print_batch
                    into  M_CUST_MAIL ,M_GROUP_BATCH
                    from nc_mas a ,nc_payment_info b
                    where A.CLM_NO = b.clm_no
                    and pay_no = p1.pay_no
                    and b.trn_seq in (select max(bb.trn_seq) from nc_payment_info bb where bb.pay_no = b.pay_no);    
                    
                    if M_CUST_MAIL is not null then
                        M_CUST_MAIL_FLAG := 'Y';
                    end if;            
                exception 
                    when no_data_found then
                        M_GROUP_BATCH :=null; 
                        M_CUST_MAIL :=null; 
                        M_CUST_MAIL_FLAG :=null;                         
                    when others then
                        M_GROUP_BATCH :=null; 
                        M_CUST_MAIL :=null; 
                        M_CUST_MAIL_FLAG :=null;                       
                end;            */                 
                --== End Part get Email and is Batch Job----
                
                v_DEDUCT_AMT := 0; 
                V_REC_TOTAL := 0;
                V_SAL_TOTAL := 0; 
                 
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
                end loop;   -- p_cms    
                                        
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
               
                IF (v_payeecurr <> v_paidcurr)  THEN -- case different Currency
                    v_ADV_AMT := 0;
                END IF;    
                                                      
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
                                          
                P_CLAIM_ACR.Post_acc_clm_payee_nonpa( c_rec.prod_grp /* P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type */,  
                                    
                c_rec.prod_type /* P_prod_type  IN  acc_clm_payee_tmp.prod_type%type */,
                                                                                
                p1.pay_no /* P_payno      IN  acc_clm_payee_tmp.payment_no%type */,
                                                                                
                p3.pay_seq /* P_seq        IN  acc_clm_payee_tmp.seq%type */,
                                                                                
                '01' /* P_doc_type   IN  acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
                                                                                
                X_CURRCODE /* P_curr_code  IN  acc_clm_payee_tmp.curr_code%type */,                                                                               
                                                                                
                V_PAY_TOTAL /* P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type */,
                                                                                
                p3.payee_code /* P_payee_code IN  acc_clm_payee_tmp.payee_code%type */,
                                                                                
                v_title /* P_title      IN  acc_clm_payee_tmp.title%type */,
                                                                                
                v_name /* P_name       IN  acc_clm_payee_tmp.name%type */, 
                                                                                
                '04' /* P_dept_no    IN  acc_clm_payee_tmp.dept_no%type */,
                                                                                
                M_PAIDBY_PAYMENT /* P_batch_no   IN  acc_clm_payee_tmp.batch_no%type */,
                                                                                
                nvl(v_DEDUCT_AMT,0) /* P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type */,
                                                                                
                v_ADV_AMT /* P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type */,
                                                                                
                v_SAL_TOTAL /* P_salvage_amt    IN  acc_clm_payee_tmp.salvage_amt%type*/,
                                                                                                          
                v_REC_TOTAL /* P_recov_amt    IN  acc_clm_payee_tmp.recov_amt%type*/,    
                                                                                                          
                v_less_other /* P_prem_offset    IN  acc_clm_payee_tmp.less_other%type */ ,                                                                                           

                 p3.bank_code /* p_bank_code in acc_clm_payee_tmp.bank_code%type */ ,
                 
                 p3.bank_br_code /* p_branch_code in acc_clm_payee_tmp.branch_code%type */ ,
                 
                 p3.acc_no /* p_acc_no in acc_clm_payee_tmp.acc_no%type*/,
                 
                 p3.acc_name /* p_acc_name_th in acc_clm_payee_tmp.acc_name_th%type*/,
                 
                 null /* p_acc_name_eng in acc_clm_payee_tmp.acc_name_eng%type*/,
                 
                 null /* p_deposit_type in acc_clm_payee_tmp.deposit_type%type*/,
                 
                 p3.settle /* p_paid_type in acc_clm_payee_tmp.paid_type%type*/,
                 
                 M_SPECIAL_FLAG /* p_special_flag in acc_clm_payee_tmp.special_flag%type*/,
                 
                 M_SPECIAL_REMARK /* p_special_remark in acc_clm_payee_tmp.special_remark%type*/,
                 
                 M_AGENT_MAIL /* p_agent_mail in acc_clm_payee_tmp.agent_mail%type*/,
                 
                 M_AGENT_MAIL_FLAG /* p_agent_mail_flag in acc_clm_payee_tmp.agent_mail_flag%type*/,
                 
                 M_AGENT_MOBILE_NUMBER /* p_agent_mobile_number in acc_clm_payee_tmp.agent_mobile_number%type*/,
                 
                 M_AGENT_SMS_FLAG /* p_agent_sms_flag in acc_clm_payee_tmp.agent_sms_flag%type*/,
                 
                 M_CUST_MAIL /* p_cust_mail in acc_clm_payee_tmp.cust_mail%type*/,
                 
                 M_CUST_MAIL_FLAG /* p_cust_mail_flag in acc_clm_payee_tmp.cust_mail_flag%type*/,
                 
                 M_MOBILE_NUMBER /* p_mobile_number in acc_clm_payee_tmp.mobile_number%type*/, 
                 
                 M_SMS_FLAG /* p_sms_flag in acc_clm_payee_tmp.sms_flag%type*/, 
                                                                                           
                V_RESULT2 /* P_msg       Out varchar2*/ ) ;      
                                                                                  
                if v_result2 is not null then rollback; P_RST:= v_result2||' in P_CLAIM_ACR.Post_acc_clm_payee_tmp'; return false; end if;  
                                           
                dbms_output.put_line('pass post acc payee tmp ! '||p3.payee_code);              
            end loop;   -- end loop payee  P3
            COMMIT; -- post ACC_CLM_TEMP b4 call post GL  
              
--            p_acc_claim.post_gl ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,  
--                                      
--            c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,  
--                                      
--            p1.pay_no /* p_number in varchar2 */,  -- payment no or batch no  
--                                      
--            'P' /* p_flag in varchar2 */,   -- 'P' = Payment, 'B' = Batch  
--                                      
--            V_RESULT3 /* p_err  out varchar2 */);  -- return null if no error  
--              
--            if v_result3 is not null then /* CLR_ACC_TMP; */ P_RST:= v_result3||' in p_acc_claim.post_gl'; return false; end if;       
--                        
--            dbms_output.put_line('pass Post ACR');                      
--                                                           
--            p_acc_claim.get_acr_voucher ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,  
--              
--            c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,  
--              
--            p1.pay_no /* p_number in varchar2 */,   -- payment no or batch no  
--              
--            'P' /* p_flag in varchar2 */,  -- 'P' = Payment, 'B' = Batch  
--              
--            V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,  
--              
--            V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);  
--              
--            IF V_VOUNO is null THEN  
--                P_RST:= ' p_acc_claim.post_gl have any Problem '; return false;  
--            END IF;  
                        
            begin
            null; 
            exception
            when others then
            rollback; P_RST := 'error update claim: '||sqlerrm ; return false;
            end; 
                              
        end loop;    --P1    
    end loop;  
    --// End Run Individual ========  
     COMMIT;  
                   
    return true;  
EXCEPTION  
    WHEN OTHERS THEN  
    rollback; P_RST := 'error update claim: '||sqlerrm ; return false;          
END POST_FIR;

FUNCTION POST_MRN(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS

 
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
  X_CURRCODE    varchar2(5);  
  v_paidCurr    varchar2(5);  
  v_payeeCurr    varchar2(5);  

 M_SEND_TITLE varchar2(100); 
 M_SEND_ADDR1 varchar2(200); 
 M_SEND_ADDR2 varchar2(200); 
 M_PAYEE_CODE varchar2(20); 
 M_PAYEE_NAME varchar2(200); 
 M_PAY_NO varchar2(20); 
 
 M_SPECIAL_FLAG VARCHAR2(1);
 M_SPECIAL_REMARK VARCHAR2(500);
 M_AGENT_MAIL VARCHAR2(150);
 M_AGENT_MAIL_FLAG VARCHAR2(1);
 M_AGENT_MOBILE_NUMBER VARCHAR2(50);
 M_AGENT_SMS_FLAG VARCHAR2(1 );
 M_CUST_MAIL VARCHAR2(150 );
 M_CUST_MAIL_FLAG VARCHAR2(1 );
 M_MOBILE_NUMBER VARCHAR2(50);
 M_SMS_FLAG VARCHAR2(1 ); 
 
 M_PAIDBY_PAYMENT VARCHAR2(1 ); 

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
    select a.clm_no ,a.pol_no ,a.pol_run ,a.end_seq ,a.pol_no||a.pol_run policy_number ,a.prod_grp ,a.prod_type 
    ,t_e th_eng ,mas_cus_code cus_code ,'' agent_code ,'' agent_seq ,'01' br_code 
    ,a.channel ,clm_user clm_men ,P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) clm_sts 
    from nc_mas a
    where a.clm_no = vClmNo
    and P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) in ('6','7','2')
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
             
        for p1 in (
        select a.pay_no ,0 pay_seq ,null pay_date 
        ,0 payee_amt ,sum(pay_amt) pay_total ,0 rec_total ,0 disc_total ,'' payee_code 
        ,min(curr_code) pay_curr_code ,min(curr_rate) pay_curr_rate
        from nc_payment a
        where a.pay_no = vPayno
        and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
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
            
            v_chk_adv := false; 
              
            for p3 in (
            select payee_code ,payee_seq pay_seq ,payee_amt ,'' prem_offset ,'' payee_offset ,'' payee_offset2 
            ,salvage_flag ,deduct_flag ,salvage_amt ,deduct_amt ,payee_type
            ,bank_code ,bank_br_code ,acc_no ,acc_name ,CONVERT_PAYMENT_METHOD(settle) settle ,curr_code
            ,GRP_PAYEE_FLAG ,EMAIL ,SMS ,AGENT_EMAIL ,AGENT_SMS
            ,SPECIAL_FLAG ,SPECIAL_REMARK            
            from nc_payee b
            where b.pay_no = p1.pay_no
            and b.trn_seq in (select max(bb.trn_seq) from nc_payee bb where bb.clm_no =b.clm_no and bb.pay_no = b.pay_no) 
            ) 
            loop 

                v_paidcurr := p1.pay_curr_code;
                if p3.curr_code is null then 
                    v_payeecurr := v_paidcurr ;
                    X_CURRCODE:= v_payeecurr ;
                else
                    X_CURRCODE := p3.curr_code;  
                    v_payeecurr := X_CURRCODE;
                end if;      
                
                --== Part get Email and is Batch Job----
                IF NVL(p3.GRP_PAYEE_FLAG,'N') = 'Y'  THEN
                    M_PAIDBY_PAYMENT := null;
                ELSE
                    M_PAIDBY_PAYMENT := 'Y';
                END IF;
                
                IF p3.email is not null THEN
                    M_CUST_MAIL := p3.email ; M_CUST_MAIL_FLAG := 'Y' ;
                END IF;
                IF p3.sms is not null THEN
                    M_MOBILE_NUMBER := p3.sms ; M_SMS_FLAG := 'Y' ;                 
                END IF;    
                
                IF p3.agent_email is not null THEN
                    M_AGENT_MAIL := p3.agent_email ; M_AGENT_MAIL_FLAG := 'Y' ;
                END IF;
                IF p3.agent_sms is not null THEN
                    M_AGENT_MOBILE_NUMBER := p3.agent_sms ; M_AGENT_SMS_FLAG := 'Y' ;                 
                END IF;       
                
                M_SPECIAL_FLAG := p3.special_flag;
                M_SPECIAL_REMARK := p3.special_remark;                          
/*                M_GROUP_BATCH :=null; 
                M_CUST_MAIL :=null; 
                M_CUST_MAIL_FLAG :=null;     
                begin
                    select decode(a.clm_user ,null ,'',core_ldap.GET_EMAIL_FUNC(a.clm_user)) ,b.print_batch
                    into  M_CUST_MAIL ,M_GROUP_BATCH
                    from nc_mas a ,nc_payment_info b
                    where A.CLM_NO = b.clm_no
                    and pay_no = p1.pay_no
                    and b.trn_seq in (select max(bb.trn_seq) from nc_payment_info bb where bb.pay_no = b.pay_no);    
                    
                    if M_CUST_MAIL is not null then
                        M_CUST_MAIL_FLAG := 'Y';
                    end if;            
                exception 
                    when no_data_found then
                        M_GROUP_BATCH :=null; 
                        M_CUST_MAIL :=null; 
                        M_CUST_MAIL_FLAG :=null;                         
                    when others then
                        M_GROUP_BATCH :=null; 
                        M_CUST_MAIL :=null; 
                        M_CUST_MAIL_FLAG :=null;                       
                end;                             */
                --== End Part get Email and is Batch Job----
                
                v_DEDUCT_AMT := 0; 
                V_REC_TOTAL := 0;
                V_SAL_TOTAL := 0; 
                 
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
                end loop;   -- p_cms    
                                        
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
               
                IF (v_payeecurr <> v_paidcurr)  THEN -- case different Currency
                    v_ADV_AMT := 0;
                END IF;    
                                                      
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
                                          
                P_CLAIM_ACR.Post_acc_clm_payee_nonpa( c_rec.prod_grp /* P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type */,  
                                    
                c_rec.prod_type /* P_prod_type  IN  acc_clm_payee_tmp.prod_type%type */,
                                                                                
                p1.pay_no /* P_payno      IN  acc_clm_payee_tmp.payment_no%type */,
                                                                                
                p3.pay_seq /* P_seq        IN  acc_clm_payee_tmp.seq%type */,
                                                                                
                '01' /* P_doc_type   IN  acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
                                                                                
                X_CURRCODE /* P_curr_code  IN  acc_clm_payee_tmp.curr_code%type */,                                                                               
                                                                                
                V_PAY_TOTAL /* P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type */,
                                                                                
                p3.payee_code /* P_payee_code IN  acc_clm_payee_tmp.payee_code%type */,
                                                                                
                v_title /* P_title      IN  acc_clm_payee_tmp.title%type */,
                                                                                
                v_name /* P_name       IN  acc_clm_payee_tmp.name%type */, 
                                                                                
                '04' /* P_dept_no    IN  acc_clm_payee_tmp.dept_no%type */,
                                                                                
                M_PAIDBY_PAYMENT /* P_batch_no   IN  acc_clm_payee_tmp.batch_no%type */,
                                                                                
                nvl(v_DEDUCT_AMT,0) /* P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type */,
                                                                                
                v_ADV_AMT /* P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type */,
                                                                                
                v_SAL_TOTAL /* P_salvage_amt    IN  acc_clm_payee_tmp.salvage_amt%type*/,
                                                                                                          
                v_REC_TOTAL /* P_recov_amt    IN  acc_clm_payee_tmp.recov_amt%type*/,    
                                                                                                          
                v_less_other /* P_prem_offset    IN  acc_clm_payee_tmp.less_other%type */ ,                                                                                           

                 p3.bank_code /* p_bank_code in acc_clm_payee_tmp.bank_code%type */ ,
                 
                 p3.bank_br_code /* p_branch_code in acc_clm_payee_tmp.branch_code%type */ ,
                 
                 p3.acc_no /* p_acc_no in acc_clm_payee_tmp.acc_no%type*/,
                 
                 p3.acc_name /* p_acc_name_th in acc_clm_payee_tmp.acc_name_th%type*/,
                 
                 null /* p_acc_name_eng in acc_clm_payee_tmp.acc_name_eng%type*/,
                 
                 null /* p_deposit_type in acc_clm_payee_tmp.deposit_type%type*/,
                 
                 p3.settle /* p_paid_type in acc_clm_payee_tmp.paid_type%type*/,
                 
                 M_SPECIAL_FLAG /* p_special_flag in acc_clm_payee_tmp.special_flag%type*/,
                 
                 M_SPECIAL_REMARK /* p_special_remark in acc_clm_payee_tmp.special_remark%type*/,
                 
                 M_AGENT_MAIL /* p_agent_mail in acc_clm_payee_tmp.agent_mail%type*/,
                 
                 M_AGENT_MAIL_FLAG /* p_agent_mail_flag in acc_clm_payee_tmp.agent_mail_flag%type*/,
                 
                 M_AGENT_MOBILE_NUMBER /* p_agent_mobile_number in acc_clm_payee_tmp.agent_mobile_number%type*/,
                 
                 M_AGENT_SMS_FLAG /* p_agent_sms_flag in acc_clm_payee_tmp.agent_sms_flag%type*/,
                 
                 M_CUST_MAIL /* p_cust_mail in acc_clm_payee_tmp.cust_mail%type*/,
                 
                 M_CUST_MAIL_FLAG /* p_cust_mail_flag in acc_clm_payee_tmp.cust_mail_flag%type*/,
                 
                 M_MOBILE_NUMBER /* p_mobile_number in acc_clm_payee_tmp.mobile_number%type*/, 
                 
                 M_SMS_FLAG /* p_sms_flag in acc_clm_payee_tmp.sms_flag%type*/, 
                                                                                           
                V_RESULT2 /* P_msg       Out varchar2*/ ) ;      
                                                                                  
                if v_result2 is not null then rollback; P_RST:= v_result2||' in P_CLAIM_ACR.Post_acc_clm_payee_tmp'; return false; end if;  
                                           
                dbms_output.put_line('pass post acc payee tmp ! '||p3.payee_code);              
            end loop;   -- end loop payee  P3
            COMMIT; -- post ACC_CLM_TEMP b4 call post GL  
              
--            p_acc_claim.post_gl ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,  
--                                      
--            c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,  
--                                      
--            p1.pay_no /* p_number in varchar2 */,  -- payment no or batch no  
--                                      
--            'P' /* p_flag in varchar2 */,   -- 'P' = Payment, 'B' = Batch  
--                                      
--            V_RESULT3 /* p_err  out varchar2 */);  -- return null if no error  
--              
--            if v_result3 is not null then /* CLR_ACC_TMP; */ P_RST:= v_result3||' in p_acc_claim.post_gl'; return false; end if;       
--                        
--            dbms_output.put_line('pass Post ACR');                      
--                                                           
--            p_acc_claim.get_acr_voucher ( c_rec.prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,  
--              
--            c_rec.prod_type /* p_prod_type in acr_tmp.prod_type%type */,  
--              
--            p1.pay_no /* p_number in varchar2 */,   -- payment no or batch no  
--              
--            'P' /* p_flag in varchar2 */,  -- 'P' = Payment, 'B' = Batch  
--              
--            V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,  
--              
--            V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);  
--              
--            IF V_VOUNO is null THEN  
--                P_RST:= ' p_acc_claim.post_gl have any Problem '; return false;  
--            END IF;  
                        
            begin
            null; 
            exception
            when others then
            rollback; P_RST := 'error update claim: '||sqlerrm ; return false;
            end; 
                              
        end loop;    --P1    
    end loop;  
    --// End Run Individual ========  
     COMMIT;  
                   
    return true;  
EXCEPTION  
    WHEN OTHERS THEN  
    rollback; P_RST := 'error update claim: '||sqlerrm ; return false;          
END POST_MRN;

FUNCTION AUTO_POST(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
    v_prod_grp  varchar2(2);
    v_prod_type varchar2(5);
    v_cnt   number:=0;
    v_part varchar2(5000);
    v_pay_total_paid  number:=0;
    V_RESULT    varchar2(250);
    V_RESULT3   varchar2(250);
    V_RESULT4   varchar2(250);
    V_POSTGL_STS    varchar2(250);
    M_URGENT_FLAG  varchar2(2); 
    V_VOUNO varchar2(20);
    V_VOUDATE   date;
    
    v_payeecode varchar2(20);
BEGIN 

    for c_rec in ( 
    select a.clm_no ,a.pol_no ,a.pol_run ,a.pol_no||a.pol_run policy_number ,a.prod_grp ,a.prod_type 
    ,t_e th_eng ,mas_cus_code cus_code ,'' agent_code ,'' agent_seq ,'01' br_code 
    ,a.channel ,clm_user clm_men --,P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) clm_sts  ,close_date first_close
    from nc_mas a
    where a.clm_no = vClmNo
    --and P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) in ('6','7','2')
    ) 
    loop 

        v_prod_grp := c_rec.prod_grp ;
        v_prod_type := c_rec.prod_type ;
        
        IF v_prod_grp not in ('0','1','2','3' ) THEN -- Misc Product
            --- === Post MISC ===
            dbms_output.put_line('Post in Misc');
             IF not POST_MISC(vClmNo, vPayNo , vClmUser,P_RST) THEN --POST ACR TEMP
                 dbms_output.put_line('in POST_MISC false: '||P_RST); 
                 return false;
             END IF; 
             v_cnt := v_cnt+1;
        --- === END Post MISC ===
        ELSIF v_prod_grp  in ('1' ) THEN -- Fire Product
            --- === Post FIR ===
            dbms_output.put_line('Post in Fire');
             IF not POST_FIR(vClmNo, vPayNo , vClmUser,P_RST) THEN --POST ACR TEMP
                 dbms_output.put_line('in POST_FIR false: '||P_RST); 
                 return false;
             END IF; 
             v_cnt := v_cnt+1;
        --- === END Post FIR ===
        ELSIF v_prod_grp  in ('2' ) THEN -- Mrn/Hull Product
            --- === Post Mrn/Hull ===
            dbms_output.put_line('Post in Mrn/Hull');
             IF not POST_MRN(vClmNo, vPayNo , vClmUser,P_RST) THEN --POST ACR TEMP
                 dbms_output.put_line('in POST_MRN false: '||P_RST); 
                 return false;
             END IF; 
             v_cnt := v_cnt+1;
        --- === END Post Mrn/Hull ===
                
--            IF v_prod_type in ('222') THEN -- Hull Product
--            
--            ELSE -- Mrn Product
--            
--            END IF;        
        END IF;        
    end loop; --c_rec
    
    IF v_cnt > 0 THEN -- Post Success
        v_result := UPDATE_STATUS_ACR(vPayNo ,vClmUser );
        
        if v_result is not null then return true; end if; 
        
        BEGIN
            select payee_code ,urgent_flag into v_payeecode , M_URGENT_FLAG
            from nc_payee b
            where pay_no = vPayNo 
            and b.trn_seq in (select max(bb.trn_seq) from nc_payee bb where bb.clm_no =b.clm_no and bb.pay_no = b.pay_no)
            and nvl(urgent_flag ,'N') = 'Y' and rownum=1 ;
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                M_URGENT_FLAG := null;
            WHEN OTHERS THEN
                M_URGENT_FLAG := null;
        END;
        
        IF nvl(M_URGENT_FLAG ,'N') = 'Y' THEN -- check Urgent Case
             
            p_acc_claim.post_gl ( v_prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */, 
            P_NON_PA_APPROVE.GET_PRODUCT_TYPE(vPayNo) /* p_prod_type in acr_tmp.prod_type%type */, 
            vPayNo /* p_number in varchar2 */, -- payment no or batch no 
            'P' /* p_flag in varchar2 */, -- 'P' = Payment, 'B' = Batch 
            V_RESULT3 /* p_err out varchar2 */); -- return null if no error 
                 
            if V_RESULT3 is null then --post gl success 

            -- Check Voucher stamp??   
            p_acc_claim.get_acr_voucher ( v_prod_grp /* p_prod_grp in acr_tmp.prod_grp%type */,   
       
            P_NON_PA_APPROVE.GET_PRODUCT_TYPE(vPayNo) /* p_prod_type in acr_tmp.prod_type%type */,   
       
            vPayNo /* p_number in varchar2 */,   -- payment no or batch no   
       
            'P' /* p_flag in varchar2 */,  -- 'P' = Payment, 'B' = Batch   
       
            V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,   
       
            V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);   
       
            IF V_VOUNO is not null THEN -- Post Voucher Success   
                P_ACC_ACR.UPDATE_DATA_AFTER_POST_GL( V_VOUNO , V_VOUDATE , V_RESULT4) ;
            END IF;
                        
            P_CLAIM_ACR.After_post_NC_PAYMENT(vPayNo ,P_NON_PA_APPROVE.GET_PRODUCT_TYPE(vPayNo) ,'Y', null , V_POSTGL_STS);
            
            EMAIL_URGENT_PAYMENT(vClmNo ,vPayNo ,v_payeecode) ;
            else -- post error 
            P_CLAIM_ACR.After_post_NC_PAYMENT(vPayNo ,P_NON_PA_APPROVE.GET_PRODUCT_TYPE(vPayNo) ,'N', V_RESULT3 , V_POSTGL_STS);
            end if;
             
        END IF; 
        -- Wait for Another Product 
--        P_RST := 'Not found Post Procedure for Clm: '||vClmNo||' payno: '||vPayNo;
--        return false;
    END IF;
    
    return true;  
EXCEPTION  
    WHEN OTHERS THEN  
    rollback; P_RST := 'error Post ACR : '||sqlerrm ; return false;          
END AUTO_POST;  

FUNCTION AFTER_POST(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
    v_prod_grp  varchar2(2);
    v_prod_type varchar2(5);
    v_cnt   number:=0;
    v_part varchar2(5000);
    v_pay_total_paid  number:=0;
    v_rst   varchar2(250);
    v_dummyPayno  varchar2(20);
    is_clmtype  boolean;
    v_newclm_sts    varchar2(2);
    v_close_date    date;
BEGIN 

    for c_rec in ( 
    select a.clm_no ,a.pol_no ,a.pol_run ,a.pol_no||a.pol_run policy_number ,a.prod_grp ,a.prod_type 
    ,t_e th_eng ,mas_cus_code cus_code ,'' agent_code ,'' agent_seq ,'01' br_code 
    ,a.channel ,clm_user clm_men ,P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) clm_sts  ,close_date first_close
    ,a.clm_sts RAW_STS
    from nc_mas a
    where a.clm_no = vClmNo
    and P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) in ('6','7','2')
    ) 
    loop 

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
        v_close_date := trunc(c_rec.first_close) ;
             
        v_prod_grp := c_rec.prod_grp ;
        v_prod_type := c_rec.prod_type ;
        
        IF v_prod_grp not in ('0','1','2','3' ) THEN -- Misc Product
            --- === Update MISC ===
            if c_rec.clm_sts in ('7','2') then -- case close claim
                for v1 in (
                    select CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS
                    from mis_clm_mas_seq a
                    where clm_no = c_rec.clm_no
                    and a.corr_seq in (select max(aa.corr_seq) from mis_clm_mas_seq aa where aa.clm_no = a.clm_no)
                ) loop
                    v_cnt := v_cnt+1;    
                    
                    if c_rec.RAW_STS in ('NCCLMSTS02' ,'NCCLMSTS03') and v_close_date = trunc(sysdate) then   -- check update Close to Reserved
                        -- script update Reserved
                        if c_rec.RAW_STS = 'NCCLMSTS02' then
                            v_newclm_sts := '2';
                        elsif c_rec.RAW_STS = 'NCCLMSTS03' then
                            v_newclm_sts := '3';
                        end if;
                        
                        update mis_clm_mas
                        set    clm_sts = v_newclm_sts
                        , close_date = v_close_date
                        where  clm_no = c_rec.clm_no;             

                        Insert into MIS_CLM_MAS_SEQ
                           (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE
                           , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS)
                         Values
                           (v1.CLM_NO, v1.POL_NO, v1.POL_RUN, v1.CORR_SEQ+1, sysdate, v1.CHANNEL, v1.PROD_GRP, v1.PROD_TYPE, v1.CLM_DATE ,null
                           , v1.TOT_RES, v1.TOT_PAID, v_close_date ,v_newclm_sts );        
                    end if; -- check update Close to Reserved
                                                                       
--                    if (trunc(c_rec.first_close) = trunc(sysdate) or c_rec.first_close is null ) then --case approve+print same date
--                        update mis_clm_mas
--                        set    clm_sts = '2',
--                        close_date = trunc(sysdate) ,first_close = trunc(sysdate)
--                        where  clm_no = c_rec.clm_no;             
--                                             
--                        Insert into MIS_CLM_MAS_SEQ
--                           (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE
--                           , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS)
--                         Values
--                           (v1.CLM_NO, v1.POL_NO, v1.POL_RUN, v1.CORR_SEQ+1, sysdate, v1.CHANNEL, v1.PROD_GRP, v1.PROD_TYPE, v1.CLM_DATE ,null
--                           , v1.TOT_RES, v1.TOT_PAID, trunc(sysdate),'2');                           
--                    else -- case print another day
--                        update mis_clm_mas
--                        set    clm_sts = '2' --, reopen_date = trunc(sysdate),
--                        , close_date = trunc(sysdate)
--                        where  clm_no = c_rec.clm_no;             
--
--                        Insert into MIS_CLM_MAS_SEQ
--                           (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE
--                           , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS)
--                         Values
--                           (v1.CLM_NO, v1.POL_NO, v1.POL_RUN, v1.CORR_SEQ+1, sysdate, v1.CHANNEL, v1.PROD_GRP, v1.PROD_TYPE, v1.CLM_DATE ,null
--                           , v1.TOT_RES, v1.TOT_PAID, trunc(sysdate),'2');                                                  
--                    end if;
                                          
                end loop; 
                                           
            else    -- case Pending
                    
                for v1 in (
                    select CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS
                    from mis_clm_mas_seq a
                    where clm_no = c_rec.clm_no
                    and a.corr_seq in (select max(aa.corr_seq) from mis_clm_mas_seq aa where aa.clm_no = a.clm_no)
                ) loop
                            
                    if (trunc(c_rec.first_close) = trunc(sysdate) or c_rec.first_close is null ) then --case approve+print same date
                        update mis_clm_mas
                        set    clm_sts = '1',
                        close_date = null
                        where  clm_no = c_rec.clm_no;             
                                             
                        Insert into MIS_CLM_MAS_SEQ
                           (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE
                           , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS)
                         Values
                           (v1.CLM_NO, v1.POL_NO, v1.POL_RUN, v1.CORR_SEQ+1, sysdate, v1.CHANNEL, v1.PROD_GRP, v1.PROD_TYPE, v1.CLM_DATE ,v1.REOPEN_DATE
                           , v1.TOT_RES, v1.TOT_PAID, null ,'1');                           
                    else -- case print another day
                        update mis_clm_mas
                        set    clm_sts = '1', reopen_date = trunc(sysdate),
                        close_date = null 
                        where  clm_no = c_rec.clm_no;             
                                             
                        Insert into MIS_CLM_MAS_SEQ
                           (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE
                           , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS)
                         Values
                           (v1.CLM_NO, v1.POL_NO, v1.POL_RUN, v1.CORR_SEQ+1, sysdate, v1.CHANNEL, v1.PROD_GRP, v1.PROD_TYPE, v1.CLM_DATE ,trunc(sysdate)
                           , v1.TOT_RES, v1.TOT_PAID,null ,'4');               

                        Insert into MIS_CLM_MAS_SEQ
                           (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE ,REOPEN_DATE
                           , TOT_RES, TOT_PAID, CLOSE_DATE, CLM_STS)
                         Values
                           (v1.CLM_NO, v1.POL_NO, v1.POL_RUN, v1.CORR_SEQ+2, sysdate, v1.CHANNEL, v1.PROD_GRP, v1.PROD_TYPE, v1.CLM_DATE ,trunc(sysdate)
                           , v1.TOT_RES, v1.TOT_PAID, null,'1');                                                  
                    end if;
                                          
                end loop; 
            end if;    

            begin
                select longtochar('MIS_CLM_PAID','PART',rowid,1,5000)
                    into v_part
                from mis_clm_paid a
                where clm_no = c_rec.clm_no and pay_no = vPayNo    
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
                                                                                   
            insert into mis_clm_paid (
            CLM_NO, PAY_NO, PAY_STS, PAY_TOTAL, SETTLE, PAY_TYPE, PRT_FLAG, PAY_CURR_CODE, PAY_CURR_RATE, TOTAL_PAY_TOTAL, CORR_SEQ, CORR_DATE, STATE_FLAG, VAT_PERCENT, DEDUCT_AMT, REC_PAY_DATE, SEND_TITLE, SEND_ADDR1, SEND_ADDR2, BATCH_NO, PRINT_TYPE, REPRINT_NO, PRINT_BATCH
            ,TOT_DEDUCT_AMT ,CO_PAY_TATAL ,CO_DEDUCT_TOTAL ,ACC_TYPE ,BRANCH_CODE ,INVOICE_NO ,JOB_NO
            ,BANK_BR_CODE ,ATTACHED ,ACC_NO ,ACC_NAME ,BANK_CODE ,BR_NAME    ,REMARK, VAT_AMT                    
            )
            (
            select CLM_NO, PAY_NO, PAY_STS, PAY_TOTAL, SETTLE, PAY_TYPE, PRT_FLAG, PAY_CURR_CODE, PAY_CURR_RATE, TOTAL_PAY_TOTAL, CORR_SEQ+1 , sysdate , '1' STATE_FLAG, VAT_PERCENT, DEDUCT_AMT, REC_PAY_DATE, SEND_TITLE, SEND_ADDR1, SEND_ADDR2, BATCH_NO, '1' PRINT_TYPE, REPRINT_NO, PRINT_BATCH
            ,TOT_DEDUCT_AMT ,CO_PAY_TATAL ,CO_DEDUCT_TOTAL ,ACC_TYPE ,BRANCH_CODE ,INVOICE_NO ,JOB_NO
            ,BANK_BR_CODE ,ATTACHED ,ACC_NO ,ACC_NAME ,BANK_CODE ,BR_NAME    ,REMARK, VAT_AMT                    
            from mis_clm_paid a
            where clm_no = c_rec.clm_no and pay_no = vPayNo    
            and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
                    where b.pay_no = a.pay_no
                    group by b.pay_no)        
            );
            ------------
            begin
                select sum(a.pay_total) into v_pay_total_paid
                from mis_clm_paid a
                where a.clm_no =c_rec.clm_no
                --    and a.pay_no = :parameter.p_payno
                and a.pay_sts <> '0'
                and (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq)
                      from mis_clm_paid b
                      where a.clm_no = b.clm_no
                      and a.pay_no = b.pay_no 
                      group by b.pay_no)
                and a.state_flag = '1';                      
            exception
            when no_data_found then
            v_pay_total_paid :=0;                           
            when others then
            v_pay_total_paid :=0;
            end;
                        ---- UPdate AOM ----  23/2/2555 
            update mis_clm_mas
            set    net_recov_amt =v_pay_total_paid
            where  clm_no = c_rec.clm_no;    
            ------------------------------------------------------------------------------------------------------------
            Insert into MIS_CMS_PAID
            (CLM_NO, PAY_NO, PAY_STS, SECTN, RISK_CODE, PREM_CODE, TYPE, CORR_SEQ, PAY_AMT, DEDUCT_AMT, TOTAL_PAY_AMT, TOT_DEDUCT_AMT, SALVAGE_AMT ,VAT_AMT ,CO_PAY_AMT ,CO_DEDUCT_AMT ,CANCEL ,TOT_SALVAGE_AMT ,CO_SALVAGE_AMT)
            (
            select CLM_NO, PAY_NO, PAY_STS, SECTN, RISK_CODE, PREM_CODE, TYPE, CORR_SEQ+1, PAY_AMT, DEDUCT_AMT, TOTAL_PAY_AMT, TOT_DEDUCT_AMT, SALVAGE_AMT ,VAT_AMT ,CO_PAY_AMT ,CO_DEDUCT_AMT ,CANCEL ,TOT_SALVAGE_AMT ,CO_SALVAGE_AMT
            from mis_cms_paid a
            where clm_no = c_rec.clm_no and pay_no = vPayNo    
            and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_cms_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no)                                 
            );
                                                        
            Insert into MIS_CRI_PAID
            (CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, CORR_SEQ, LF_FLAG, RI_SUB_TYPE ,RI_CONT ,LETT_REMARK)                                                    
            (
            select CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE, CORR_SEQ+1, LF_FLAG, RI_SUB_TYPE ,RI_CONT ,LETT_REMARK
            from mis_cri_paid a
            where clm_no = c_rec.clm_no and pay_no = vPayNo
            and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_cri_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no)                                     
            );
                                            
                                                                   
            Update mis_clm_paid a 
            set a.print_type = '1' ,
            a.pay_date = trunc(sysdate) ,a.state_flag='1' ,
            part = v_part 
--            ,a.batch_no = :TMP_BLK.BATCH_NO
            where a.clm_no = c_rec.clm_no
            and a.pay_no =  vPayNo  
            and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no);  
                             
        --- === End Update MISC ===
        
        ELSIF v_prod_grp  in ('1' ) THEN -- Fire Product
            --- === Update FIRE ===   
            v_cnt := v_cnt+1;        
            
            if c_rec.RAW_STS in ('NCCLMSTS02' ,'NCCLMSTS03') and v_close_date = trunc(sysdate) then   -- check update Close to Reserved
                -- script update Reserved
                if c_rec.RAW_STS = 'NCCLMSTS02' then
                    v_newclm_sts := '4';
                elsif c_rec.RAW_STS = 'NCCLMSTS03' then
                    v_newclm_sts := '5';
                end if;

                update fir_clm_mas
                set close_date = v_close_date ,clm_sts = v_newclm_sts
                where clm_no = c_rec.clm_no    ;
                            
                 Insert into FIR_OUT_STAT
                (CLM_NO, STATE_NO, STATE_SEQ, TYPE, STATE_DATE, STATE_STS, CORR_DATE, BUILD_TOT_SUM, BUILD_OUR_SUM, BUILD_TOT_LOSS, BUILD_OUR_LOSS, MACH_TOT_SUM, MACH_OUR_SUM, MACH_TOT_LOSS, MACH_OUR_LOSS, STOCK_TOT_SUM, STOCK_OUR_SUM, STOCK_TOT_LOSS, STOCK_OUR_LOSS, FURN_TOT_SUM, FURN_OUR_SUM, FURN_TOT_LOSS, FURN_OUR_LOSS, OTHER_TOT_SUM, OTHER_OUR_SUM, OTHER_TOT_LOSS, OTHER_OUR_LOSS, SUR_TOT_LOSS, SUR_OUR_LOSS, REC_TOT_LOSS, REC_OUR_LOSS, SET_TOT_LOSS, SET_OUR_LOSS, TOT_TOT_SUM, TOT_OUR_SUM, TOT_TOT_LOSS, TOT_OUR_LOSS
                ,REOPEN_DATE ,CLOSE_DATE ,REOPEN_CODE ,CLOSE_CODE ,DESCR_CLOSE)
                (select CLM_NO, STATE_NO, STATE_SEQ+1, TYPE, STATE_DATE, '2' STATE_STS,sysdate CORR_DATE, BUILD_TOT_SUM, BUILD_OUR_SUM, BUILD_TOT_LOSS, BUILD_OUR_LOSS, MACH_TOT_SUM, MACH_OUR_SUM, MACH_TOT_LOSS, MACH_OUR_LOSS, STOCK_TOT_SUM, STOCK_OUR_SUM, STOCK_TOT_LOSS, STOCK_OUR_LOSS, FURN_TOT_SUM, FURN_OUR_SUM, FURN_TOT_LOSS, FURN_OUR_LOSS, OTHER_TOT_SUM, OTHER_OUR_SUM, OTHER_TOT_LOSS, OTHER_OUR_LOSS, SUR_TOT_LOSS, SUR_OUR_LOSS, REC_TOT_LOSS, REC_OUR_LOSS, SET_TOT_LOSS, SET_OUR_LOSS, TOT_TOT_SUM, TOT_OUR_SUM, TOT_TOT_LOSS, TOT_OUR_LOSS
                ,REOPEN_DATE ,v_close_date ,REOPEN_CODE ,CLOSE_CODE ,DESCR_CLOSE
                from fir_out_stat a  
                where clm_no = c_rec.clm_no and type='01'
                and a.state_seq in (select max(aa.state_seq) from fir_out_stat aa where aa.clm_no =a.clm_no and aa.type='01' )
                );

                Insert into FIR_CLM_OUT
                (CLM_NO, OUT_TYPE, STATE_NO, STATE_SEQ, TYPE, OUT_DATE, OUT_SIGN, OUT_FOR_AMT, OUT_RTE, OUT_AMT)
                (select CLM_NO, OUT_TYPE, STATE_NO, STATE_SEQ+1, TYPE, OUT_DATE, OUT_SIGN, OUT_FOR_AMT, OUT_RTE, OUT_AMT
                from FIR_CLM_OUT a
                where clm_no = c_rec.clm_no and type='01'
                and a.state_seq in (select max(aa.state_seq) from FIR_CLM_OUT aa where aa.clm_no =a.clm_no and aa.type='01' )
                );

                Insert into FIR_RI_OUT
                (CLM_NO, STATE_NO, STATE_SEQ, TYPE, RI_CODE, RI_BR_CODE, RI_LF_FLAG, RI_TYPE, RI_SUB_TYPE, RI_SHARE, RI_RES_AMT
                ,RI_APP_NO ,LETT_NO ,LETT_PRT ,CASH_CALL)
                (select CLM_NO, STATE_NO, STATE_SEQ+1, TYPE, RI_CODE, RI_BR_CODE, RI_LF_FLAG, RI_TYPE, RI_SUB_TYPE, RI_SHARE, RI_RES_AMT
                ,RI_APP_NO ,LETT_NO ,LETT_PRT ,CASH_CALL
                from FIR_RI_OUT a
                where clm_no = c_rec.clm_no and type='01'
                and a.state_seq in (select max(aa.state_seq) from FIR_RI_OUT aa where aa.clm_no =a.clm_no and aa.type='01' )
                );               
                -- end script update Reserved
            end if; -- check update Close to Reserved
            
            Insert into FIR_PAID_STAT
                (CLM_NO, STATE_NO, STATE_SEQ, TYPE, STATE_DATE, CORR_DATE, BUILD_TOT_LOSS, BUILD_OUR_LOSS, MACH_TOT_LOSS, MACH_OUR_LOSS, STOCK_TOT_LOSS, STOCK_OUR_LOSS, FURN_TOT_LOSS, FURN_OUR_LOSS, OTHER_TOT_LOSS, OTHER_OUR_LOSS, SUR_TOT_LOSS, SUR_OUR_LOSS, REC_TOT_LOSS, REC_OUR_LOSS, SET_TOT_LOSS, SET_OUR_LOSS, TOT_TOT_LOSS, TOT_OUR_LOSS, DESCR_PAID, TYPE_FLAG, VAT_AMT
                ,REMARK ,PRINT_TYPE ,BATCH_NO ,REPRINT_NO ,PAY_DATE ,STATE_FLAG
                )
                (select clm_no, state_no, state_seq+1, type, trunc(sysdate), sysdate, build_tot_loss, build_our_loss, mach_tot_loss, mach_our_loss, stock_tot_loss, stock_our_loss, furn_tot_loss, furn_our_loss, other_tot_loss, other_our_loss, sur_tot_loss, sur_our_loss, rec_tot_loss, rec_our_loss, set_tot_loss, set_our_loss, tot_tot_loss, tot_our_loss, descr_paid, type_flag, vat_amt
                   ,remark , '1' ,'' batch_no ,reprint_no ,TRUNC(sysdate) ,'1'
                 from FIR_PAID_STAT   a 
                 where clm_no = vClmNo
                and state_no = vPayNo
                and state_seq in (select max(aa.state_seq) from fir_paid_stat aa where aa.state_no = a.state_no) 
                );            

                Insert into FIRWIN.FIR_CLM_PAID
               (CLM_NO, PAY_TYPE, STATE_NO, STATE_SEQ, TYPE, PAY_SIGN, PAY_AMT ,PAY_DATE ,PAY_AGT ,PAY_AGT_STS 
               ,PAY_FOR_AMT ,PAY_RTE ,PAY_RECP_STS)
                (
                select clm_no, pay_type, state_no, state_seq+1, type, pay_sign, pay_amt , TRUNC(sysdate) pay_date ,pay_agt ,pay_agt_sts 
                   ,pay_for_amt ,pay_rte ,pay_recp_sts
                from fir_clm_paid a
                where clm_no = vClmNo
                and state_no = vPayNo
                and a.state_seq in (select max(aa.state_seq) from fir_clm_paid aa where aa.state_no = a.state_no)
                );

                Insert into FIR_CLM_PAYEE
                (CLM_NO, STATE_NO, STATE_SEQ, TYPE, ITEM_NO, PAY_DATE, PAY_AMT, SETTLE, ACC_NO, ACC_NAME, BANK_CODE, BR_NAME, DESCR_BEN, SALVAGE_AMT, DEDUCT_AMT, PAYEE_CODE
                ,PAY_AGT_STS ,PAY_FOR_AMT ,CURR_CODE ,CHEQUE_NO ,BANK_NAME ,APP_DATE ,OTHER ,SENT ,DESCR_SENT ,BANK_BR_CODE ,SEND_TITLE ,SEND_ADDR1 ,SEND_ADDR2 
                ,PAYEE_OFFSET ,PAYEE_OFFSET2)
                (
                select clm_no, state_no, state_seq +1 , type, item_no, pay_date, pay_amt, settle, acc_no, acc_name, bank_code, br_name, descr_ben, salvage_amt, deduct_amt, payee_code
                ,pay_agt_sts ,pay_for_amt ,curr_code ,cheque_no ,bank_name ,app_date ,other ,sent ,descr_sent ,bank_br_code ,send_title ,send_addr1 ,send_addr2 
                ,payee_offset ,payee_offset2
                from fir_clm_payee a
                where clm_no = vClmNo and state_no = vPayNo
                and state_seq in (select max(aa.state_seq) from fir_clm_payee aa where aa.state_no = a.state_no)
                );

                Insert into FIRWIN.FIR_RI_PAID
                   (CLM_NO, STATE_NO, STATE_SEQ, TYPE, RI_CODE, RI_BR_CODE, RI_LF_FLAG, RI_TYPE, RI_SUB_TYPE, RI_SHARE, RI_PAY_AMT, LETT_NO, LETT_PRT, SALVAGE_AMT, DEDUCT_AMT, IMD_OFFSET, LOSS_EXPENSE
                   ,RI_APP_NO ,CASH_CALL ,RECOV_EXPENSE ,RECOV_AMT ,SALVAGE_EXPENSE ,DEDUCT_EXPENSE)
                   (select clm_no, state_no, state_seq+1 , type, ri_code, ri_br_code, ri_lf_flag, ri_type, ri_sub_type, ri_share, ri_pay_amt, lett_no, lett_prt, salvage_amt, deduct_amt, imd_offset, loss_expense
                   ,ri_app_no ,cash_call ,recov_expense ,recov_amt ,salvage_expense ,deduct_expense
                   from fir_ri_paid a
                   where clm_no = vClmNo and state_no = vPayNo
                   and state_seq in (select max(aa.state_seq) from fir_ri_paid aa where aa.state_no = a.state_no)
                   );
   
        --- === End Update FIR ===         
        ELSIF v_prod_grp  in ('2' ) THEN -- Mrn/Hull Product
            IF v_prod_type in ('222') THEN -- Hull Product
                --- === Update Hull ===   
                v_cnt := v_cnt+1;        

                if c_rec.RAW_STS in ('NCCLMSTS02' ,'NCCLMSTS03') and v_close_date = trunc(sysdate) then   -- check update Close to Reserved
                    -- script update Reserved
                    if c_rec.RAW_STS = 'NCCLMSTS02' then
                        v_newclm_sts := '3';
                    elsif c_rec.RAW_STS = 'NCCLMSTS03' then
                        v_newclm_sts := '4';
                    end if;

                    update hull_clm_mas
                    set close_date = v_close_date ,clm_sts = v_newclm_sts
                    where clm_no = vClmNo;

                    Insert into HULL_OUT_STAT
                    (CLM_NO, STATE_NO, STATE_DATE ,STATE_SEQ, TYPE, CORR_DATE, RES_AMT, RES_FOR_AMT, USER_ID
                    ,REOPEN_DATE ,REOPEN_CODE ,CLOSE_DATE ,CLOSE_CODE ,CLOSE_MARK ,DESCR_REOPEN ,DESCR_CLOSE ,TYP_FLAG  )
                    (select CLM_NO, STATE_NO, STATE_DATE ,STATE_SEQ +1, TYPE, sysdate  CORR_DATE, RES_AMT, RES_FOR_AMT, USER_ID
                    ,REOPEN_DATE ,REOPEN_CODE ,v_close_date ,CLOSE_CODE ,'Y' CLOSE_MARK ,DESCR_REOPEN ,DESCR_CLOSE ,TYP_FLAG
                    from HULL_OUT_STAT a  
                    where clm_no = vClmNo and type='01'
                    and a.state_seq in (select max(aa.state_seq) from HULL_OUT_STAT aa where aa.clm_no =a.clm_no and aa.type='01' )
                    );

                    Insert into HULL_CLM_OUT
                    (CLM_NO, PAY_TYPE, STATE_NO, STATE_SEQ, TYPE, OUT_DATE, OUT_AGT, OUT_SIGN, OUT_FOR_AMT, OUT_RTE, OUT_AGT_STS, OUT_AMT)
                    (select CLM_NO, PAY_TYPE, STATE_NO, STATE_SEQ+1, TYPE, OUT_DATE, OUT_AGT, OUT_SIGN, OUT_FOR_AMT, OUT_RTE, OUT_AGT_STS, OUT_AMT
                    from HULL_CLM_OUT a
                    where clm_no = vClmNo and type='01'
                    and a.state_seq in (select max(aa.state_seq) from HULL_CLM_OUT aa where aa.clm_no =a.clm_no and aa.type='01' )
                    );

                    Insert into HULL_RI_OUT
                    (CLM_NO, STATE_NO, STATE_SEQ, TYPE, RI_CODE, RI_BR_CODE, LF_FLAG, RI_TYPE1, RI_TYPE2, RI_OUT_AMT, RI_SHR ,CESS_NO)
                    (select CLM_NO, STATE_NO, STATE_SEQ+1, TYPE, RI_CODE, RI_BR_CODE, LF_FLAG, RI_TYPE1, RI_TYPE2, RI_OUT_AMT, RI_SHR ,CESS_NO
                    from HULL_RI_OUT a
                    where clm_no = vClmNo and type='01'
                    and a.state_seq in (select max(aa.state_seq) from HULL_RI_OUT aa where aa.clm_no =a.clm_no and aa.type='01' )
                    );
                    -- end script update Reserved
                end if; -- check update Close to Reserved
            
                Insert into ALLCLM.HULL_CLM_PAID
                   (CLM_NO, PAY_TYPE, PAY_NO, PAY_SEQ, PAY_AGT,TYPE, PAID_DATE, PAY_SIGN, BAL_FOR_AMT, PAY_FOR_AMT, PAY_RTE, VAT_AMT, PAY_AGT_STS, PAY_AMT ,CLM_SEQ)
                (
                select clm_no, pay_type, pay_no, pay_seq +1, pay_agt,type,TRUNC(sysdate) paid_date, pay_sign, bal_for_amt, pay_for_amt, pay_rte, vat_amt, pay_agt_sts, pay_amt ,clm_seq
                from hull_clm_paid a
                where pay_no = vPayNo
                and pay_seq in (select max(aa.pay_seq) from hull_clm_paid aa where aa.pay_no = a.pay_no)
                );

                Insert into ALLCLM.HULL_PAID_STAT
                   (CLM_NO, PAY_NO, PAY_SEQ, TYPE, PAID_DATE, CORR_DATE, BAL_EST_AMT, PAID_AMT, TYP_FLAG, PAID_FOR_AMT, PRINT_TYPE ,PRINT_STS)
                (
                    select clm_no, pay_no, pay_seq+1, type,TRUNC(sysdate) paid_date,sysdate corr_date, bal_est_amt, paid_amt, typ_flag, paid_for_amt,'1' print_type ,print_sts
                    from hull_paid_stat a
                    where pay_no = vPayNo
                    and pay_seq in (select max(aa.pay_seq) from hull_paid_stat aa where aa.pay_no = a.pay_no)
                ) ;
                
                Insert into MRN.HULL_CLM_PAYEE
                   (CLM_NO, PAY_NO,PAY_SEQ, BEN_SEQ, TYPE, PAID_DATE, PAY_AGT, DESCR_BEN, PAY_AMT, SETTLE,CHEQUE_NO, ACC_NO, ACC_NAME, BANK_CODE, BR_CODE,
                 OTHER, PAYEE_CODE, PAY_AGT_STS, SALVAGE_AMT, DEDUCT_AMT, PAYEE_OFFSET,  PAYEE_OFFSET2)
                (
                    select a.clm_no, a.pay_no,a.pay_seq+1, a.ben_seq, a.type, TRUNC(sysdate) paid_date, a.pay_agt, a.descr_ben, a.pay_amt, a.settle,a.cheque_no, a.acc_no, a.acc_name, a.bank_code, a.br_code,
                     a.other, a.payee_code, a.pay_agt_sts, a.salvage_amt, a.deduct_amt, a.payee_offset,  a.payee_offset2
                    from hull_clm_payee a
                    where pay_no = vPayNo
                    and pay_seq in (select max(aa.pay_seq) from hull_clm_payee aa where aa.pay_no = a.pay_no)
                ) ;             

                Insert into MRN.HULL_RI_PAID
                   (CLM_NO, PAY_NO, PAY_SEQ, TYPE, RI_CODE, RI_BR_CODE, LF_FLAG, RI_TYPE1, RI_TYPE2, RI_SHR, RI_BAL_AMT, RI_PAY_AMT, IMD_OFFSET
                   ,CESS_NO ,SALVAGE_AMT ,RECOV_AMT ,LOSS_EXPENSE ,RECOV_EXPENSE ,DEDUCT_EXPENSE ,SALVAGE_EXPENSE)
                   (select clm_no, pay_no, pay_seq +1 , type, ri_code, ri_br_code, lf_flag, ri_type1, ri_type2, ri_shr, ri_bal_amt, ri_pay_amt , imd_offset
                   ,cess_no ,salvage_amt ,recov_amt ,loss_expense ,recov_expense ,deduct_expense ,salvage_expense
                    from hull_ri_paid a
                    where pay_no = vPayNo
                    and pay_seq in (select max(aa.pay_seq) from hull_ri_paid aa where aa.pay_no =a.pay_no )
                   );                   
            --- === End Update Hull === 
            ELSE
            --- === Update Mrn ===   
                v_cnt := v_cnt+1;           

                if c_rec.RAW_STS in ('NCCLMSTS02' ,'NCCLMSTS03') and v_close_date = trunc(sysdate) then   -- check update Close to Reserved
                    -- script update Reserved
                    if c_rec.RAW_STS = 'NCCLMSTS02' then
                        v_newclm_sts := '2';
                    elsif c_rec.RAW_STS = 'NCCLMSTS03' then
                        v_newclm_sts := '3';
                    end if;

                    update mrn_clm_mas
                    set close_date = v_close_date ,clm_sts = v_newclm_sts
                    where clm_no = vClmNo;

                    Insert into MRN_OUT_STAT
                    (CLM_NO, STATE_NO, STATE_SEQ, TYPE, STATE_DATE, PA_AMT, GA_AMT, SUR_AMT, SET_AMT, REC_AMT, EXP_AMT, TOT_AMT
                    ,REOPEN_DATE, CLOSE_DATE, REOPEN_CODE , CLOSE_CODE, DESCR_CLOSE ,TYP_FLAG, CORR_DATE)
                    (select CLM_NO, STATE_NO, STATE_SEQ+1, TYPE, STATE_DATE, PA_AMT, GA_AMT, SUR_AMT, SET_AMT, REC_AMT, EXP_AMT, TOT_AMT
                    ,REOPEN_DATE,v_close_date, REOPEN_CODE , CLOSE_CODE, DESCR_CLOSE ,'3' TYP_FLAG,sysdate CORR_DATE
                    from MRN_OUT_STAT a  
                    where clm_no = vClmNo and type='01'
                    and a.state_seq in (select max(aa.state_seq) from MRN_OUT_STAT aa where aa.clm_no =a.clm_no and aa.type='01' )
                    );
                    
                    Insert into MRN_CLM_OUT
                    (CLM_NO, OUT_TYPE, STATE_NO, STATE_SEQ, TYPE, OUT_DATE, OUT_AGT, OUT_SIGN, OUT_FOR_AMT, OUT_RTE, OUT_AMT, OUT_AGT_STS)
                    (select CLM_NO, OUT_TYPE, STATE_NO, STATE_SEQ+1, TYPE, OUT_DATE, OUT_AGT, OUT_SIGN, OUT_FOR_AMT, OUT_RTE, OUT_AMT, OUT_AGT_STS
                    from MRN_CLM_OUT a
                    where clm_no = vClmNo and type='01'
                    and a.state_seq in (select max(aa.state_seq) from MRN_CLM_OUT aa where aa.clm_no =a.clm_no and aa.type='01' )
                    );

                    Insert into MRN_RI_OUT
                    (CLM_NO, STATE_NO, STATE_SEQ, TYPE, RI_CODE, RI_BR_CODE, LF_FLAG, RI_TYPE1, RI_TYPE2, CESS_OUT_NO, RI_OUT_AMT)
                    (select CLM_NO, STATE_NO, STATE_SEQ+1, TYPE, RI_CODE, RI_BR_CODE, LF_FLAG, RI_TYPE1, RI_TYPE2, CESS_OUT_NO, RI_OUT_AMT
                    from MRN_RI_OUT a
                    where clm_no =  vClmNo and type='01'
                    and a.state_seq in (select max(aa.state_seq) from MRN_RI_OUT aa where aa.clm_no =a.clm_no and aa.type='01' )
                    );
                    -- end script update Reserved
                end if; -- check update Close to Reserved
                
                Insert into ALLCLM.MRN_PAID_STAT
                (CLM_NO, STATE_NO, STATE_SEQ, TYPE, STATE_DATE, PA_AMT, SUR_AMT, SET_AMT, REC_AMT, EXP_AMT, TOT_AMT, DESCR_PAID, BEN_AMT, CORR_DATE, REMARK, PRINT_TYPE
                ,GA_AMT ,TYP_FLAG ,VAT_AMT ,BATCH_NO ,REPRINT_NO ,PRINT_STS)
                (
                select clm_no, state_no, state_seq+1, type, TRUNC(sysdate) state_date, pa_amt, sur_amt, set_amt, rec_amt, exp_amt, tot_amt, descr_paid, ben_amt, sysdate corr_date, remark, '1' print_type
                   ,ga_amt ,typ_flag ,vat_amt ,batch_no ,reprint_no ,print_sts
                from mrn_paid_stat a
                where state_no = vPayNo
                and state_seq in (select max(aa.state_seq) from mrn_paid_stat aa where aa.state_no = a.state_no)
                )  ;


                Insert into ALLCLM.MRN_CLM_PAID
                (CLM_NO, PAY_TYPE, STATE_NO, STATE_SEQ, TYPE, PAY_DATE, PAY_SIGN, PAY_FOR_AMT, PAY_RTE, PAY_AMT, PAY_RECP_STS, PAY_VAT_AMT, CLM_SEQ
                ,PAY_AGT ,PAY_AGT_STS ,OFFSET_FLAG)
                (
                select clm_no, pay_type, state_no, state_seq+1, type, TRUNC(sysdate) pay_date, pay_sign, pay_for_amt, pay_rte, pay_amt, pay_recp_sts, pay_vat_amt, clm_seq
                ,pay_agt ,pay_agt_sts ,offset_flag
                from mrn_clm_paid a
                where state_no = vPayNo
                and state_seq in (select max(aa.state_seq) from mrn_clm_paid aa where aa.state_no = a.state_no)
                );


                Insert into ALLCLM.MRN_CLM_PAYEE
                (CLM_NO, STATE_NO, STATE_SEQ, TYPE, PAY_DATE, PAY_TYPE, PAY_AGT, PAY_AMT, SETTLE, ITEM_NO, PAYEE_CODE, VAT_AMT, SALVAGE_AMT, DEDUCT_AMT
                ,CHEQUE_NO ,ACC_NO ,ACC_NAME ,BANK_CODE ,BR_NAME ,OTHER ,BR_CODE ,PAY_AGT_STS ,PAYEE_OFFSET ,PAYEE_OFFSET2 )
                (
                select clm_no, state_no, state_seq +1, type, TRUNC(sysdate) pay_date, pay_type, pay_agt, pay_amt, settle, item_no, payee_code, vat_amt, salvage_amt, deduct_amt
                ,cheque_no ,acc_no ,acc_name ,bank_code ,br_name ,other ,br_code ,pay_agt_sts ,payee_offset ,payee_offset2
                from mrn_clm_payee a
                where state_no = vPayNo
                and state_seq in (select max(aa.state_seq) from mrn_clm_payee aa where aa.state_no = a.state_no)   
                ) ;
                
                Insert into MRN.MRN_RI_PAID
                   (CLM_NO, STATE_NO, STATE_SEQ, TYPE, RI_CODE, RI_BR_CODE, LF_FLAG, RI_TYPE1, RI_TYPE2, RI_SHR, RI_PAY_AMT, DEDUCT_AMT, IMD_OFFSET
                   ,CESS_PAY_NO ,SALVAGE_AMT ,RECOV_AMT ,LOSS_EXPENSE ,RECOV_EXPENSE ,DEDUCT_EXPENSE ,SALVAGE_EXPENSE)
                    (select clm_no, state_no, state_seq+1, type, ri_code, ri_br_code, lf_flag, ri_type1, ri_type2, ri_shr, ri_pay_amt, deduct_amt, imd_offset
                   ,cess_pay_no ,salvage_amt ,recov_amt ,loss_expense ,recov_expense ,deduct_expense ,salvage_expense
                    from mrn_ri_paid a
                    where state_no = vPayNo
                    and state_seq in (select max(aa.state_seq) from mrn_ri_paid aa where aa.state_no = a.state_no)
                    ) ;                 
            --- === End Update Mrn === 
            END IF;  
        END IF;        
    end loop; --c_rec
    
    IF v_cnt >0 THEN
         IF not SET_SETTLEDATE(vClmNo, vPayNo , vClmUser,v_rst) THEN --Stamp Settle Date for confirm Actual Payment Date when issue monthly report
             ROLLBACK; 
             P_RST := 'in SET_SETTLE false: '||v_rst;
             dbms_output.put_line('in SET_SETTLE false: '||v_rst); 
             return false;
         END IF;     
    
        COMMIT;         
        dbms_output.put_line('Update claim complete '||vClmNo||' payno: '||vPayNo);     
    END IF;      

    return true;  
EXCEPTION  
    WHEN OTHERS THEN  
    rollback; P_RST := 'error update claim: '||sqlerrm ; return false;          
END AFTER_POST;  

PROCEDURE GET_DRAFT_ACRDATA(i_clmno IN VARCHAR2 ,i_payno IN VARCHAR2 ,o_payee_amt OUT NUMBER ,o_paid_amt OUT NUMBER
,o_deduct_amt OUT NUMBER ,o_salvage_amt OUT NUMBER ,o_recov_amt OUT NUMBER ,o_adv_amt OUT NUMBER 
,o_payee_curr OUT VARCHAR2 ,o_paid_curr OUT VARCHAR2) IS

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
 v_prod_grp varchar2(2);
 
 CNT_P number:=0;
 V_CLASSx varchar2(10); 
 V_CLASS varchar2(10); 
 V_PREM_OFFSET varchar2(1);
 v_less_other varchar2(2);
 cnt number;
 v_chk_adv boolean:=false;
 v_part varchar2(5000);
 v_pay_total_paid number:=0;
 v_approve varchar2(30);
 v_approve_id varchar2(10); 
 X_CURRCODE varchar2(5); 
 v_paidCurr varchar2(5); 
 v_payeeCurr varchar2(5); 
 vCLMNO varchar2(20);
 vPayno  varchar2(20);
 v_dummyPayno   varchar2(20);
 is_clmtype boolean:=false;
BEGIN
    -- i_clmno := '201501551000003';
    -- i_payno :='2015551000003';
    vCLMNO := i_clmno;
    vPayno := i_payno;
    o_payee_amt := 0 ;
    o_paid_amt := 0;
    o_deduct_amt := 0;
    o_salvage_amt := 0;
    o_recov_amt := 0;
    o_adv_amt := 0;
    --======= Step Insert Data ======== 
    for c_rec in ( 
    select a.clm_no ,a.pol_no ,a.pol_run ,a.end_seq ,a.pol_no||a.pol_run policy_number ,a.prod_grp ,a.prod_type 
    ,t_e th_eng ,mas_cus_code cus_code ,'' agent_code ,'' agent_seq ,'01' br_code 
    ,a.channel ,clm_user clm_men ,P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) clm_sts 
    from nc_mas a
    where a.clm_no = vClmNo
    and P_NON_PA_APPROVE.GET_CLMSTS(a.clm_no) in ('6','7','2')
    ) 
    loop 
        dbms_output.put_line('in c_rec = '||vClmNo); 
        /* script 3 */ 
                 
        for p1 in (
        select a.pay_no ,0 pay_seq ,null pay_date 
        ,0 payee_amt ,sum(pay_amt) pay_total ,0 rec_total ,0 disc_total ,'' payee_code 
        ,min(curr_code) pay_curr_code ,min(curr_rate) pay_curr_rate
        from nc_payment a
        where a.pay_no = vPayno
        and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
        group by pay_no 
        )
        loop 
            dbms_output.put_line('in p1 = '||vPayno); 
             
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
            
            v_chk_adv := false; 
            v_ADV_AMT := 0; 
            for p3 in (
            select payee_code ,payee_seq pay_seq ,payee_amt ,'' prem_offset ,'' payee_offset ,'' payee_offset2 
            ,salvage_flag ,deduct_flag ,salvage_amt ,deduct_amt ,payee_type
            ,bank_code ,bank_br_code ,acc_no ,acc_name ,CONVERT_PAYMENT_METHOD(settle) settle ,curr_code
            ,GRP_PAYEE_FLAG ,EMAIL ,SMS ,AGENT_EMAIL ,AGENT_SMS
            ,SPECIAL_FLAG ,SPECIAL_REMARK
            from nc_payee b
            where b.pay_no = p1.pay_no
            and b.trn_seq in (select max(bb.trn_seq) from nc_payee bb where bb.clm_no =b.clm_no and bb.pay_no = b.pay_no) 
            ) 
            loop 

                v_paidcurr := p1.pay_curr_code;
                if p3.curr_code is null then 
                    v_payeecurr := v_paidcurr ;
                    X_CURRCODE:= v_payeecurr ;
                else
                    X_CURRCODE := p3.curr_code;  
                    v_payeecurr := X_CURRCODE;
                end if;      
                
                --== Part get Email and is Batch Job----
/*                IF NVL(p3.GRP_PAYEE_FLAG,'N') = 'Y'  THEN 
                    M_PAIDBY_PAYMENT := null;
                ELSE
                    M_PAIDBY_PAYMENT := 'Y';
                END IF;
                
                IF p3.email is not null THEN
                    M_CUST_MAIL := p3.email ; M_CUST_MAIL_FLAG := 'Y' ;
                END IF;
                IF p3.sms is not null THEN
                    M_MOBILE_NUMBER := p3.sms ; M_SMS_FLAG := 'Y' ;                 
                END IF;    
                
                IF p3.agent_email is not null THEN
                    M_AGENT_MAIL := p3.agent_email ; M_AGENT_MAIL_FLAG := 'Y' ;
                END IF;
                IF p3.agent_sms is not null THEN
                    M_AGENT_MOBILE_NUMBER := p3.agent_sms ; M_AGENT_SMS_FLAG := 'Y' ;                 
                END IF;       
                
                M_SPECIAL_FLAG := p3.special_flag;
                M_SPECIAL_REMARK := p3.special_remark;                      */  
                --== End Part get Email and is Batch Job----
                
                v_DEDUCT_AMT := 0; 
                V_REC_TOTAL := 0;
                V_SAL_TOTAL := 0; 
                 
                CNT_P := CNT_P +1;

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
                end loop;   -- p_cms    
                                        
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
               
                IF (v_payeecurr <> v_paidcurr)  THEN -- case different Currency
                    v_ADV_AMT := 0;
                END IF;    

                begin
                    select distinct pay_no into v_dummyPayno
                    from nc_payment
                    where type like 'NCNATTYPECLM%'
                    and pay_no = vPayno ;     
                    is_clmtype := true;
                exception
                when no_data_found then
                    is_clmtype := false;
                when others then
                    is_clmtype := false;
                end;

                IF not is_clmtype THEN -- case Receive don't show Advance
                    v_ADV_AMT := 0;
                END IF;    
                                                                           
            end loop;   -- end loop payee  P3                               
        end loop;    --P1    
    end loop;  
    --// End Run Individual ========  

    dbms_output.put_line('PAYEE: '||V_SUM_PAYEE||' '||v_payeecurr||' V_SUM_PAY: '||V_SUM_PAY||' '||v_paidcurr||' SALVAGE : '||V_SUM_SAL||' DEDUCT : '||V_SUM_DEC||
    ' Advance: '||v_ADV_AMT); 
     
    o_payee_amt := V_SUM_PAYEE ;
    o_paid_amt := V_SUM_PAY;
    o_deduct_amt := V_SUM_DEC;
    o_salvage_amt := V_SUM_SAL;
    o_recov_amt := V_SUM_REC;
    o_adv_amt := v_ADV_AMT;
    o_payee_curr := v_payeecurr;
    o_paid_curr := v_paidcurr;
 
EXCEPTION
 WHEN OTHERS THEN
 null;
END GET_DRAFT_ACRDATA;

PROCEDURE RPT_GET_DRAFT_ACRDATA(i_clmno IN VARCHAR2 ,
 i_payno IN VARCHAR2 , 
 out_cursor OUT sys_refcursor)
 IS
 o_payee_amt NUMBER;
 o_paid_amt NUMBER;
 o_deduct_amt NUMBER;
 o_salvage_amt NUMBER;
 o_recov_amt NUMBER;
 o_adv_amt NUMBER;
 o_payee_curr VARCHAR2(100);
 o_paid_curr VARCHAR2(100);
 BEGIN
 ALLCLM.p_non_pa_approve.GET_DRAFT_ACRDATA(i_clmno,
 i_payno,
 o_payee_amt,
 o_paid_amt,
 o_deduct_amt,
 o_salvage_amt,
 o_recov_amt,
 o_adv_amt,
 o_payee_curr,
 o_paid_curr);
 open out_cursor for
 select o_payee_amt o_payee_amt,
 o_paid_amt o_paid_amt,
 o_deduct_amt o_deduct_amt,
 o_salvage_amt o_salvage_amt,
 o_recov_amt o_recov_amt,
 o_adv_amt o_adv_amt,
 o_payee_curr o_payee_curr,
 o_paid_curr o_paid_curr
 from dual;
 
 EXCEPTION
 WHEN OTHERS THEN
 open out_cursor for
 select null o_payee_amt,
 null o_paid_amt,
 null o_deduct_amt,
 null o_salvage_amt,
 null o_recov_amt,
 null o_adv_amt,
 null o_payee_curr,
 null o_paid_curr
 from dual;
 END RPT_GET_DRAFT_ACRDATA;   
FUNCTION Get_Special_email(i_Type IN VARCHAR2,i_user IN VARCHAR2) return VARCHAR2  IS 
  v_id                 varchar2(10);
  v_deptdivteam varchar2(10);
BEGIN
   begin
     select dept_id||div_id||team_id
       into v_deptdivteam
       from bkiuser
     where user_id = i_user;
   exception
     when others then
              v_deptdivteam := null;
   end;
     if v_deptdivteam is not null then 
       if     i_type = 'TO' then
          begin
              select remark
                 into v_id
                 from clm_constant
               where key = 'NONPA-'||i_type||'-'||v_deptdivteam   
                   and trunc(sysdate) between eff_date and exp_date;  
          exception
              when others then
                       v_id := i_user;    
          end;
       elsif i_type = 'CC' then
           begin
              select remark
                 into v_id
                 from clm_constant
               where key = 'NONPA-'||i_type||'-'||v_deptdivteam  
                   and trunc(sysdate) between eff_date and exp_date;  
           exception
              when others then
                       v_id := i_user;     
          end;  
       end if;
     else
       v_deptdivteam := null;
       v_id                 := i_user;
     end if;
    return(v_id);
END Get_Special_email; 

PROCEDURE GET_SPECIALFLAG_LIST(o_cursor OUT v_ref_cursor1 ) IS

BEGIN    
 
    OPEN o_cursor for 
        select '' flag ,'== ไม่ระบุ ==' descr ,0 sort1
        from dual
        union
        select   remark flag,descr ,1 sort1  
        from clm_constant where key  like '%NSPECIALFLAG%'
        order by sort1    ;
    

END GET_SPECIALFLAG_LIST;

FUNCTION IS_GRP_PAYEE(v_clmno IN varchar2 ,v_payno IN varchar2 ,v_payee IN varchar2 ) RETURN BOOLEAN IS
    v_remark varchar2(200);
BEGIN
   select remark into v_remark
   from clm_constant
   where key like 'NONPAGRPPAYEE%' 
   and remark = v_payee and rownum=1 ;
   
   return true;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    return false ;
    WHEN OTHERS THEN
    return false ;
END IS_GRP_PAYEE;

PROCEDURE GET_PAYEE_CONTACT(v_clmno IN varchar2 ,v_payno IN varchar2 ,v_payee IN varchar2 
,o_cust_email OUT varchar2  ,o_cust_sms OUT varchar2 ,o_agent_email OUT varchar2 ,o_agent_sms OUT varchar2) IS
    o_contact_name VARCHAR2(250) ;
    o_addr1  VARCHAR2(250)   ;
    o_addr2  VARCHAR2(250) ;
BEGIN
/*
    NC_HEALTH_PAID.GET_HOSPITAL_CONTACT(:clm_payee_blk.payee_code ,null ,null , :CLM_PAID_BLK.SEND_TITLE ,:CLM_PAID_BLK.SEND_ADDR1  ,:CLM_PAID_BLK.SEND_ADDR2  , :CLM_PAID_BLK.MOBILE_NUMBER ,:CLM_PAID_BLK.CUST_MAIL);
  if :CLM_PAID_BLK.CUST_MAIL is null then :CLM_PAID_BLK.CUST_MAIL:= NC_HEALTH_PAID.GET_ORG_CUSTOMER_EMAIL(:CLM_PAID_BLK.CLM_NO); end if;
    
    IF NC_HEALTH_PAID.IS_AGENT_CHANNEL(:clm_mas_blk.CLM_NO ,:CLM_PAYEE_BLK.PAYEE_CODE) THEN
    NC_HEALTH_PAID.GET_AGENT_CONTACT (:clm_mas_blk.CLM_NO ,:CLM_PAID_BLK.SEND_TITLE, :CLM_PAID_BLK.SEND_ADDR1, :CLM_PAID_BLK.SEND_ADDR2 
    ,  :CLM_PAID_BLK.AGENT_MOBILE_NUMBER ,:CLM_PAID_BLK.AGENT_MAIL );           
    END IF;  
    */
    GET_CUST_CONTACT(v_payee ,0 ,'T' ,o_contact_name ,o_addr1 ,o_addr2 ,o_cust_sms ,o_cust_email);
    IF IS_AGENT_CHANNEL(v_clmno ,v_payee) THEN
        GET_AGENT_CONTACT (v_clmno ,o_contact_name,o_addr1,o_addr2 
    ,  o_agent_sms ,o_agent_email );  
    END IF;
--    null;
END GET_PAYEE_CONTACT;

PROCEDURE GET_CUST_CONTACT(p_payee_code  IN VARCHAR2 ,p_payee_seq  IN NUMBER ,TH_ENG IN VARCHAR2 , o_contact_name OUT VARCHAR2 , o_addr1 OUT VARCHAR2  , o_addr2 OUT VARCHAR2  , o_mobile OUT VARCHAR2  , o_email OUT VARCHAR2)  IS
    v_payeetype varchar2(100);
    tmp_email   varchar2(150);
BEGIN
/*
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
 */
    
   IF 1 = 1 THEN   
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
                where key like 'NONPA_DUMMYEMAIL%' ;
                
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
   
END GET_CUST_CONTACT;

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
        from nc_mas
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
            where key like 'NONPA_DUMMYEMAIL%' ;
            
            o_email := tmp_email;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                null;
            WHEN OTHERS THEN
                null;
       END;        
    END IF;                                   

END GET_AGENT_CONTACT;    

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
        from nc_mas
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

FUNCTION GET_PRODUCT_TYPE(vPayno IN VARCHAR2) RETURN VARCHAR2 IS
    vProd    VARCHAR2(10);
BEGIN
    
    select prod_type into vProd
    from nc_payee
    where pay_no = vPayno and rownum=1;
    
    return vProd;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        return null;
    WHEN OTHERS THEN
        return null;
END GET_PRODUCT_TYPE;

FUNCTION GET_PRODUCT_GRP(vPayno IN VARCHAR2) RETURN VARCHAR2 IS
    vProd    VARCHAR2(10);
BEGIN
    
    select prod_grp into vProd
    from nc_payee
    where pay_no = vPayno and rownum=1;
    
    return vProd;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        return null;
    WHEN OTHERS THEN
        return null;
END GET_PRODUCT_GRP;

FUNCTION UPDATE_STATUS_ACR(v_payno in varchar2 ,v_clm_user in varchar2 ) RETURN VARCHAR2 IS
    v_sts_seq number:=0;
    v_sts_seq_m number:=0;
    v_trn_seq number:=0;
    chk_success boolean:=false;
    v_stskey number(20);
    v_chk_med    varchar2(20):=null;
BEGIN
    BEGIN    
        select sts_key into v_stskey
        from nc_payment_apprv xxx
        where pay_no = v_payno
        and xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no)     
        and rownum=1;
    exception
    when no_data_found then
        v_stskey    := 0;
    when others then
        v_stskey    := 0;
      --display_proc(sqlerrm);
    END;    
     
/**/
    BEGIN
        select max(trn_seq) + 1 into v_trn_seq
        from nc_payment_apprv a
        where sts_key = v_stskey and pay_no = v_payno ;
    exception
    when no_data_found then
        v_trn_seq    := 1;
    when others then
        v_trn_seq    := 1;
    END;
    
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
           (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,'NONPASTSAPPRV11' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
           c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , c1.APPROVE_ID ,c1.APPROVE_DATE , c1.PROD_GRP, c1.PROD_TYPE, 
           c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ,sysdate ,'Approved: Claim data Post to ACC Temp wait for AutoPost ACR at Night');           
                                      
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
     v_subject  VARCHAR2(250) ;
     v_body VARCHAR2(2000) ;
     v_to   VARCHAR2(250) ;
     v_dbins    VARCHAR2(20);
     
BEGIN
    if nvl(v_success ,'N') = 'Y' then
        p_status := 'NONPASTSAPPRV12';
        p_remark := 'Post ACR by NC_HEALTH_PAID';
    elsif nvl(v_success ,'N') = 'N' then
        p_status := 'NONPASTSAPPRV80';
        p_remark := ' '||v_note;
    end if;

    BEGIN    
        select sts_key into v_stskey
        from nc_payment_apprv xxx
        where pay_no = v_payno
        and xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no)     
        and rownum=1;
    exception
    when no_data_found then
        v_stskey    := 0;
    when others then
        v_stskey    := 0;
      --display_proc(sqlerrm);
    END;    
     
/**/
    BEGIN
        select max(trn_seq) + 1 into v_trn_seq
        from nc_payment_apprv a
        where sts_key = v_stskey and pay_no = v_payno ;
    exception
    when no_data_found then
        v_trn_seq    := 1;
    when others then
        v_trn_seq    := 1;
    END;
    
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
           (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,P_STATUS , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
           c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , c1.APPROVE_ID ,sysdate , c1.PROD_GRP, c1.PROD_TYPE, 
           c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ,sysdate ,p_remark );           
                                      
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
        COMMIT;

        if nvl(v_success ,'N') = 'N' then
             FOR X in (
             select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail ,(select UPPER(substr(instance_name,1,8)) instance_name from v$instance) ins_name
             from nc_med_email a
             where module = 'NONPALOG'  
             and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
             and direction = 'TO' and CANCEL is null 
             ) LOOP
                 v_to := v_to || x.ldap_mail ||';' ;
                 v_dbins := x.ins_name ; -- get DB Instant 
             END LOOP;             
             v_subject := 'error AUTO_POST ['||v_dbins||']' ;
             v_body := ' PayNo:'||v_payno||' in Post false: '||v_note;
             
             NC_HEALTH_PACKAGE.generate_email('AdminClm@bangkokinsurance.com' ,v_to 
             ,v_subject  ,v_body ,'' ,'' ) ;
        end if;
            
        return null ; 
    END IF;
    
    return null;
    
END UPDATE_STATUS_AFTER_POST;

FUNCTION CANCEL_APPROVE(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS
    v_acr   varchar2(20);
    v_sts   varchar2(20);
    v_prod_grp  varchar2(2);
    v_prod_type varchar2(5);
    is_err boolean:=false;
BEGIN
--    P_RST := 'ยังอยู่ระหว่างทดสอบ';
--    return false;
    
    begin
        select clm_no into v_acr
        from  acr_mas
        where payment_no = vPayNo ;
        
        P_RST := 'payment no: '||vPayNo||' ได้ส่งเข้า ACR แล้ว ไม่สามารถย้อนสถานะได้!';
        return false;        
            
    exception
        when no_data_found then
            null;
        when others then
            null;
    end;

    begin
        select pay_sts into v_sts
        from  nc_payment_apprv a
        where pay_no = vPayNo 
        and trn_seq in (select max(aa.trn_seq) from nc_payment_apprv aa where aa.pay_no = a.pay_no ) ;
        
        if (v_sts in ('NONPASTSAPPRV03','NONPASTSAPPRV11')) then
            null;            
        else
            P_RST := 'payment no: '||vPayNo||' ไม่ได้อยู่ในขั้นตอนการอนุมัติงาน !';
            return false;           
        end if;
     
    exception
        when no_data_found then
            P_RST := 'payment no: '||vPayNo||' ไม่ได้อยู่ในขั้นตอนการอนุมัติงาน !';
            return false;     
        when others then
            P_RST := 'payment no: '||vPayNo||' ไม่ได้อยู่ในขั้นตอนการอนุมัติงาน !';
            return false;     
    end;   
    
    
    begin
        select prod_grp into v_prod_grp
        from nc_mas
        where clm_no = vClmNo;
        
        delete
        from  acc_clm_tmp
        where payment_no = vPayNo ;   

        delete
        from  acc_clm_payee_tmp
        where payment_no = vPayNo ;   
        
        P_NON_PA_CLM_PAYMENT.save_oic_payment_seq(vClmNo,vPayNo,'D');

        FOR C1 in (
            select clm_no ,pay_no ,clm_seq ,trn_seq ,PAY_STS ,approve_id ,pay_amt ,trn_amt ,curr_code ,curr_rate 
            ,sts_date ,clm_men ,prod_grp ,prod_type ,subsysid ,STS_KEY ,print_type ,type ,sub_type ,apprv_flag ,approve_date
            from nc_payment_apprv a
            where pay_no = vPayNo
            and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no)             
        )            
        LOOP                

          INSERT INTO NC_PAYMENT_APPRV
           (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, 
           STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, APPROVE_ID, APPROVE_DATE, PROD_GRP, PROD_TYPE, 
           SUBSYSID, STS_KEY, TYPE, SUB_TYPE, APPRV_FLAG ,SETTLE_DATE ,remark )
          VALUES
           (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,'NONPASTSAPPRV31' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
           c1.STS_DATE, sysdate, c1.CLM_MEN, vClmUser , null ,null , c1.PROD_GRP, c1.PROD_TYPE, 
           c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, null ,null ,'Cancel Approved ');           
        END LOOP;           
/*        
        delete
        from  nc_payment_apprv a
        where pay_no = vPayNo 
        and a.trn_seq in (select max(aa.trn_seq) from nc_payment_apprv aa where aa.pay_no = a.pay_no)
        and pay_sts in   ('NONPASTSAPPRV03','NONPASTSAPPRV11') ;        
        
        delete
        from  nc_payment_apprv a
        where pay_no = vPayNo 
        and a.trn_seq in (select max(aa.trn_seq) from nc_payment_apprv aa where aa.pay_no = a.pay_no)
        and pay_sts in   ('NONPASTSAPPRV03','NONPASTSAPPRV11') ;           
*/
        IF v_prod_grp not in ('0','1','2','3' ) THEN -- Misc Product
            --- ===  MISC ===
            dbms_output.put_line('rollback in Misc');
            update mis_clm_mas
            set close_date = null  ,clm_sts = '6'
            where clm_no =vClmNo;
            
            update mis_clm_mas_seq a
            set close_date = null , clm_sts='6'
            where clm_no =vClmNo 
            and corr_seq = (select max(aa.corr_seq) from mis_clm_mas_seq aa where aa.clm_no =a.clm_no ) ;
            
            update mis_clm_paid a
            set pay_date =null ,state_flag ='0'
            where a.pay_no = vPayNo
            and a.corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no) ;
            
        --- === END  MISC ===
        ELSIF v_prod_grp  in ('1' ) THEN -- Fire Product
            --- ===  FIR ===
            dbms_output.put_line('rollback in Fire');
            Update fir_paid_stat a 
            set a.print_type = '1' ,
            a.pay_date = null ,a.state_flag='0' ,
            a.batch_no = ''
            where a.clm_no = vClmNo
            and a.state_no =  vPayNo    
            and  (a.state_no,a.state_seq) = (select b.state_no,max(b.state_seq) from fir_paid_stat b
            where b.state_no = a.state_no
            group by b.state_no);   
        --- === END  FIR ===
        ELSIF v_prod_grp  in ('2' ) THEN -- Mrn/Hull Product
            --- ===  Mrn/Hull ===
            dbms_output.put_line('rollback in Mrn/Hull');
            IF v_prod_type in ('222') THEN -- Hull Product
                --- === Update Hull ===          
                Update hull_paid_stat a 
                set a.print_type = '0' 
                , a.paid_date = null
                where a.clm_no = vClmNo
                and a.pay_no = vPayNo
                and  (a.pay_no,a.pay_seq) = (select b.pay_no,max(b.pay_seq) from hull_paid_stat b
                where b.pay_no = a.pay_no
                group by b.pay_no);        
                
                update hull_clm_paid a 
                set a.paid_date = null
                where a.clm_no = vClmNo
                and a.pay_no = vPayNo
                and  (a.pay_no,a.pay_seq) = (select b.pay_no,max(b.pay_seq) from hull_clm_paid b
                where b.pay_no = a.pay_no
                group by b.pay_no);   
                
                update hull_clm_payee a 
                set a.paid_date = null
                where a.clm_no = vClmNo
                and a.pay_no = vPayNo
                and  (a.pay_no,a.pay_seq) = (select b.pay_no,max(b.pay_seq) from hull_clm_payee b
                where b.pay_no = a.pay_no
                group by b.pay_no);      
            --- === End Update Hull === 
            ELSE
            --- === Update Mrn ===   
                Update mrn_paid_stat a 
                set a.print_type = '0' 
                ,a.state_date = null
                where a.clm_no = vClmNo
                and a.state_no = vPayNo
                and  (a.state_no,a.state_seq) = (select b.state_no,max(b.state_seq) from mrn_paid_stat b
                where b.state_no = a.state_no
                group by b.state_no);        
                
                update mrn_clm_paid a 
                set a.pay_date = null
                where a.clm_no = vClmNo
                and a.state_no = vPayNo
                and  (a.state_no,a.state_seq) = (select b.state_no,max(b.state_seq) from mrn_clm_paid b
                where b.state_no = a.state_no
                group by b.state_no);
                
                update mrn_clm_payee a 
                set a.pay_date = null
                where a.clm_no = vClmNo
                and a.state_no = vPayNo
                --and a.payee_code = c_payee.payee_code
                and  (a.state_no,a.state_seq) = (select b.state_no,max(b.state_seq) from mrn_clm_payee b
                where b.state_no = a.state_no
                group by b.state_no);                    
            --- === End Update Mrn === 
            END IF;  
        --- === END Mrn/Hull ===
    
        END IF;          
                    
    exception
        when others then
            is_err := true;
    end;    
    
    if not is_err then
        COMMIT;
        return true;
    else
        ROLLBACK;
        P_RST := 'error revert data : '||sqlerrm;
        return false;
    end if;
    
/*        
    begin
        select clm_no into v_acr
        from  acc_clm_payee_tmp
        where payment_no = vPayNo ;
        
        P_RST := 'payment no: '||vPayNo||' ได้ส่งเข้า ACR แล้ว ไม่สามารถย้อนสถานะได้!';
        return false;        
            
    exception
        when no_data_found then
            null;
        when others then
            null;
    end;    
*/    
    
END CANCEL_APPROVE;

PROCEDURE EMAIL_URGENT_PAYMENT(i_clm IN VARCHAR2 ,i_pay IN VARCHAR2 ,i_payee IN VARCHAR2) IS
 v_to varchar2(1000);
 v_cc varchar2(1000);
 v_bcc varchar2(1000);
 v_allcc varchar2(2000);
 v_from varchar2(50):= 'AdminClm@bangkokinsurance.com' ; 
 v_dbins varchar2(10);
 v_whatsys varchar2(30);
 x_body varchar2(3000);
 x_subject varchar2(1000);
 x_listmail varchar2(1000);
 x_payeedtl varchar2(1000);
 x_voudtl    varchar2(500);
 
 v_logrst varchar2(200);
 v_link varchar2(200);
 v_url  varchar2(300);
 
 v_clmmen varchar2(10);
-- v_remark varchar2(500);
 v_clmmen_tel  varchar2(100);
 v_clmmen_name varchar2(250);
-- v_clmno    varchar2(20);
-- v_polrun   number(10);
 v_payee   varchar2(20);
 v_payee_name  varchar2(250);
 v_payee_amt   number;
 V_VOUNO  varchar2(20);
 V_VOUDATE  date;  
 v_deptid   varchar2(5);
 v_divid   varchar2(5);
 v_team   varchar2(5);
 v_position_grp   varchar2(5);
 v_prod_grp varchar2(2);
    
 v_rst varchar2(1000);
 
 v_cnt1 number:=0;
 
 i_sts varchar2(10);
BEGIN
 
 FOR X in (
 select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail 
 from nc_med_email a
 where module = 'NONPA-URGEN' 
 and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
 and direction = 'BCC' and CANCEL is null 
 ) LOOP
 v_bcc := v_bcc || x.ldap_mail ||';' ;
 END LOOP;
 
 begin 
 select UPPER(substr(instance_name,1,8)) instance_name 
 into v_dbins
 from v$instance; 
 if v_dbins='UATBKIIN' then
 v_whatsys := '[ระบบทดสอบ]';
 v_link := p_claim_send_mail.get_link_bkiapp('UAT') ;
 else 
 v_whatsys := null;
 v_link := p_claim_send_mail.get_link_bkiapp('PROD') ;
 end if; 
 exception 
 when no_data_found then 
 v_dbins := null;
 when others then 
 v_dbins := null;
 end; 
 
 begin 
    select clm_user  ,nc_health_paid.get_user_name(clm_user) ,(select tel from bkiuser a where a.user_id = clm_user) ,prod_grp 
    into v_clmmen,  v_clmmen_name ,v_clmmen_tel ,v_prod_grp
    from nc_mas x
    where clm_no = i_clm--and cwp_remark is not null 
    ; 

    v_cc := core_ldap.GET_EMAIL_FUNC(v_clmmen) ;

    for c1 in (
        select descript from constant a where key like 'ACRATTCHUSER_'||v_prod_grp||''
        union
        select descript from constant a where key like 'ACRATTCHUSER_*%'
    ) loop
        v_to := v_to || core_ldap.GET_EMAIL_FUNC(c1.descript) ||';' ;    
    end loop;
      
      
--    begin
--        select dept_id ,div_id ,team_id ,position_grp_id  
--        into v_deptid ,v_divid ,v_team ,v_position_grp
--        from bkiuser
--        where user_id =v_clmmen ;        
--        
--        if v_position_grp >42 then -- Case Staff
--            for c1 in (select core_ldap.GET_EMAIL_FUNC(P_NON_PA_APPROVE.Get_Special_email('TO',user_id)) tl_email
--            from bkiuser
--            where dept_id = v_deptid
--            and  div_id = v_divid
--            and team_id = v_team
--            and position_grp_id in ('41','42')) loop
--                v_to := v_to || c1.tl_email ||';' ;    
--            end loop;
--        else -- Case TL up
--            v_to :=   v_cc ;    
--        end if;
--    exception 
--    when no_data_found then 
--    null;
--    when others then 
--    null; 
--    end;     
    
 exception 
 when no_data_found then 
 null;
 when others then 
 null; 
 end; 
 
 x_payeedtl := null; 
 for xpayee in (
    select payee_code ,payee_name ,payee_amt 
--    into v_payee , v_payee_name ,v_payee_amt
    from nc_payee a
    where pay_no =i_pay
    and trn_seq = (select max(aa.trn_seq) from  nc_payee aa where aa.pay_no =a.pay_no)  
 )loop
    v_payee := xpayee.payee_code ;
    v_payee_name := xpayee.payee_name ;
    v_payee_amt := xpayee.payee_amt ;
    x_payeedtl := x_payeedtl||'payee: '||v_payee||'&nbsp;&nbsp;'||v_payee_name||'&nbsp;&nbsp;&nbsp;'||'จำนวนเงิน: '||to_char(v_payee_amt,'9,999,999.00')||'<br/>';
 end loop;

    -- Check Voucher stamp??   
    p_acc_claim.get_acr_voucher ( P_NON_PA_APPROVE.GET_PRODUCT_GRP(i_pay) /* p_prod_grp in acr_tmp.prod_grp%type */,   
           
    P_NON_PA_APPROVE.GET_PRODUCT_TYPE(i_pay) /* p_prod_type in acr_tmp.prod_type%type */,   
           
    i_pay /* p_number in varchar2 */,   -- payment no or batch no   
           
    'P' /* p_flag in varchar2 */,  -- 'P' = Payment, 'B' = Batch   
           
    V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,   
           
    V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);  
    
    x_voudtl := '<span style="color:blue;">โดยได้บันทึก Voucher No.: '||V_VOUNO||' Voucher Date : '||to_char(V_VOUDATE,'dd/mm/yyyy')||'</span><br/>';
 if v_payee is not null then

--http://bkinetdv/Non_pa_claim/Call_Crystal_Report.aspx?user_id=3793&report_name=CLNMC010_UAT&IN_CLM_NO=201301221000110&IN_PAY_NO=2015221000017



     if v_dbins='UATBKIIN' then
        v_link := 'http://bkinetdv/Non_pa_claim/Call_Crystal_Report.aspx?'; 
        v_url := v_link||'user_id='||v_clmmen||'&report_name=CLNMC010_UAT'||'&IN_CLM_NO='||i_clm||'&IN_PAY_NO='||i_pay;
     else 
        --http://bkiintra.bki.co.th/Non_pa_claim/Call_Crystal_Report.aspx?user_id=2463&report_name=CLNMC010&IN_CLM_NO=201501551003928&IN_PAY_NO=2015551004823
        v_link := 'http://bkiintra.bki.co.th/Non_pa_claim/Call_Crystal_Report.aspx?'; 
        v_url := v_link||'user_id='||v_clmmen||'&report_name=CLNMC010'||'&IN_CLM_NO='||i_clm||'&IN_PAY_NO='||i_pay;
     end if; 
     
    if v_dbins='UATBKIIN' then
        x_listmail := '<tr><td colspan=2>'||
        '<br/>'||'<br/>'||'<br/>'||'<br/>'||'<br/>'||
        '<p style="color:red">ถ้าเป็นระบบจริง email นี้จะส่งไปที่รายชื่อตามด้านล่าง </p><br/>'||
        'to: '||v_to||'<br/>'||
        'cc: '||v_cc||'<br/>'||
        '</td></tr>';
    end if;
    
    x_subject := 'ขอทำจ่ายสินไหมด่วน Urgent Case '||v_whatsys; 
    X_BODY := '<!DOCTYPE html>'||
    '<html lang="en">'||'<head><meta charset="utf-8">'||  
    '<title>ขอทำจ่ายสินไหมด่วน Urgent Case</title>'||'</head>'||
    '<body bgcolor="#FFFFCC" style="font-family:''Angsana New'' ">'||
    '<h2 align="center">แจ้งเรื่องมีการขอทำจ่ายสินไหมด่วน Urgent Case</h2>'||
    '<div style="font-size:20px;" >'||
    'เรียนผู้เกี่ยวข้อง'||'<br/>'||
    '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ขณะนี้ได้มีการส่งงานทำจ่ายด่วน (Urgent Case) จากฝ่ายสินไหมทดแทน มาให้ท่านตามรายละเอียดดังนี้'||'<br/>'||
    'เลขที่เคลม: '||i_clm||'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'||
    'เลขที่จ่าย: '||i_pay||'<br/>'||
    x_payeedtl||
    x_voudtl||
--    'payee: '||v_payee||' '||v_payee_name||'<br/>'||
--    'จำนวนเงิน: '||v_payee_amt||'<br/>'||
    'รายละเอียด Claim Statement -> <a href="'||v_url||' " >click to view claim statement </a>'||'<br/>'||
--    'http://bkinetdv/Non_pa_claim/Call_Crystal_Report.aspx?user_id=3793&report_name=CLNMC010_UAT&IN_CLM_NO=201301221000110&IN_PAY_NO=2015553000017'||
--    '<br/>'||
--    'http://bkinetdv/Non_pa_claim/Call_Crystal_Report.aspx?user_id=3793&report_name=CLNMC010_UAT&IN_CLM_NO=201301221000110&IN_PAY_NO=2015221000017'||
    '<br/>'||
    'หากมีข้อสงสัยติดต่อ'||'<br/>'||
    v_clmmen_name||' เบอร์ '||v_clmmen_tel||'<br/>'||
    '</div>'|| 
    '</body></html>' ;
    -- v_to := core_ldap.GET_EMAIL_FUNC(v_apprv);
    -- v_cc := core_ldap.GET_EMAIL_FUNC(v_clmmen); 
--    dbms_output.put_line('to: '||v_to ); 
--    dbms_output.put_line('cc: '||v_cc ); 
--    v_bcc := 'taywin.s@bangkokinsurance.com' ||';' ;
--    v_to :=  'taywin.s@bangkokinsurance.com' ||';' ;
 end if; 
 
 if v_dbins='DBBKIINS' then
 null; 
 else 
 v_to := v_bcc; -- for test
 v_cc := ''; -- for test
 end if; 
 
 dbms_output.put_line(x_body);
 
 dbms_output.put_line('dummy to: '||v_to ); 
 dbms_output.put_line('allcc: '||v_allcc ); 
 dbms_output.put_line('dummy cc: '||v_cc ); 
 dbms_output.put_line('bcc: '||v_bcc ); 
 if v_to is not null then
 nc_health_package.generate_email(v_from, v_to ,
 x_subject, 
 x_body 
 ,v_cc
 ,v_bcc); 
-- nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_NOTICE_APPRV' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_pay:'||I_pay||' success::' ,'success' ,v_rst) ;
 end if;

EXCEPTION
 WHEN OTHERS THEN
 --NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail Bancas' ,'Error: '||sqlerrm ,v_logrst);
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_URGEN' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_clm:'||I_clm||' error::'||sqlerrm ,'error' ,v_rst) ;
 dbms_output.put_line('Error: '||sqlerrm );
END EMAIL_URGENT_PAYMENT;

PROCEDURE GET_LAST_PAYMENTNO(i_clm IN VARCHAR2 ,o_pay OUT VARCHAR2 ,o_sts OUT VARCHAR2) IS

BEGIN

    BEGIN
        select b.pay_no , p_non_pa_approve.GET_APPRVSTATUS_DESC(b.pay_sts) approve_status -- ,b.pay_sts
        into o_pay ,o_sts 
        from nc_payment a , nc_payment_apprv b 
        where a.clm_no = i_clm 
        and a.pay_no = b.pay_no(+) 
        and (a.pay_no) = (select max(bb.pay_no) from nc_payment bb where bb.clm_no = a.clm_no and type like 'NCNATTYPECLM%')
        and (a.pay_no ,a.trn_seq) =  (select (aa.pay_no) , max(aa.trn_seq) from nc_payment aa where aa.pay_no = a.pay_no group by aa.pay_no)
        and (b.pay_no ,b.trn_seq) =  (select (bb.pay_no) , max(bb.trn_seq) from nc_payment_apprv bb where bb.pay_no =b.pay_no group by bb.pay_no)
        and rownum=1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_pay := null;
            o_sts := 'N/A';        
        WHEN OTHERS THEN
            o_pay := null;
            o_sts := 'N/A';            
    END;     

END GET_LAST_PAYMENTNO;

FUNCTION GET_SPECIALFLAG_DESCR(i_flag IN VARCHAR2) RETURN VARCHAR2 IS
    v_desc  varchar2(200);
BEGIN
    select descr into v_desc
    from clm_constant
    where key like 'SPECIAL%'
    and remark = i_flag ;
    return v_desc; 
EXCEPTION
 WHEN NO_DATA_FOUND THEN
    return ''; 
 WHEN OTHERS THEN
    return ''; 
END GET_SPECIALFLAG_DESCR ;

FUNCTION GET_TRANSFER_DETAIL(i_pay IN VARCHAR2 ,i_payee IN VARCHAR2 ,i_mode IN VARCHAR2 ) RETURN VARCHAR2 IS 
--i_mode is A = acr , C = claim
    v_bank  varchar2(150);
    v_branch    varchar2(150);
    v_fullbank  varchar2(500);
BEGIN 
    IF i_mode = 'C' THEN
        for i in (
            select acc_no ,acc_name ,bank_code ,bank_br_code 
            from nc_payee b
            where b.pay_no = i_pay
            and b.trn_seq in (select max(bb.trn_seq) from nc_payee bb where bb.clm_no =b.clm_no and bb.pay_no = b.pay_no)
            and payee_code = i_payee 
        )loop
            if i.acc_no is not null then
                begin
                    select thai_name into v_bank
                    from bank
                    where bank_code = i.bank_code     ;   
                exception
                    when no_data_found then
                        v_bank := null;
                    when others then
                        v_bank := null;
                end;
                begin
                    select thai_brn_name into v_branch
                    from bank_branch
                    where bank_code =  i.bank_code
                    and branch_code = i.bank_br_code ;       
                exception
                    when no_data_found then
                        v_branch := null;
                    when others then
                        v_branch := null;
                end;
                v_fullbank := 'เลขที่: '||i.acc_no||' ชื่อ: '||i.acc_name||' '||v_bank||' '||v_branch;    
            else
                v_fullbank := '';
            end if;
        end loop;
    ELSE
        for i in (
            select acc_no ,acc_name_th acc_name ,bank_code ,branch_code bank_br_code
            from acr_name_mas b
            where b.payment_no = i_pay
            and payee_code = i_payee 
        )loop
            if i.acc_no is not null then
                begin
                    select thai_name into v_bank
                    from bank
                    where bank_code = i.bank_code     ;   
                exception
                    when no_data_found then
                        v_bank := null;
                    when others then
                        v_bank := null;
                end;
                begin
                    select thai_brn_name into v_branch
                    from bank_branch
                    where bank_code =  i.bank_code
                    and branch_code = i.bank_br_code ;       
                exception
                    when no_data_found then
                        v_branch := null;
                    when others then
                        v_branch := null;
                end;
                v_fullbank := 'เลขที่: '||i.acc_no||' ชื่อ: '||i.acc_name||' '||v_bank||' '||v_branch;    
            else
                v_fullbank := '';
            end if;
        end loop;    
    END IF;
    
    return v_fullbank;
EXCEPTION 
 WHEN OTHERS THEN
    return ''; 
END GET_TRANSFER_DETAIL ;

FUNCTION GET_METHOD_DESCR(i_med IN VARCHAR2) RETURN VARCHAR2 IS
    v_ret   varchar2(150);
BEGIN
 select descript into v_ret
 from constant
 where key =  'ACCTYPE'
 and sub_key = i_med;
 return v_ret;
EXCEPTION 
 WHEN OTHERS THEN
    return ''; 
END GET_METHOD_DESCR;

FUNCTION GET_PAID_INFO(i_pay IN VARCHAR2 ,i_mode IN VARCHAR2) RETURN VARCHAR2 IS
--i_mode : vou_date ,paid_date ,paid_amt ,paid_by ,cheque_no
    o_paid_date  DATE;
    o_vou_date DATE;
    o_amount NUMBER;
    o_pay_method VARCHAR2(50);
    o_chq_no VARCHAR2(50);  
BEGIN
    ACCOUNT.P_ACTR_PACKAGE.GET_PAYMENT_PAID_INFO(i_pay,
    o_vou_date, o_paid_date ,
    o_amount, o_pay_method,
    o_chq_no) ;
    
    if i_mode = 'vou_date' then
        return o_vou_date;    
    elsif i_mode = 'paid_date' then
        return o_paid_date;    
    elsif i_mode = 'paid_amt' then
        return o_amount;    
    elsif i_mode = 'paid_by' then
        return o_pay_method;     
    elsif i_mode = 'cheque_no' then
        return o_chq_no;    
    end if;
    
    return ''; 
EXCEPTION 
 WHEN OTHERS THEN
    return ''; 
END GET_PAID_INFO;

FUNCTION IS_ACTIVATE_AUTOPOST RETURN BOOLEAN IS -- TRUE = ON ,FALSE= OFF
    v_remark    varchar2(20);
BEGIN
    select remark into v_remark
    from clm_constant a
    where key = 'ACRNONPA_SWITCH'
    and remark = 'ON';
    
    return TRUE;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
    return FALSE; 
    WHEN OTHERS THEN
    return FALSE; 
END IS_ACTIVATE_AUTOPOST;

FUNCTION SET_SETTLEDATE(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
    v_sysdate   date:=sysdate;
BEGIN 

    Insert into ALLCLM.NC_PAYMENT
       (CLM_NO, PAY_NO, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, PROD_GRP, PROD_TYPE, STS_KEY, TYPE, SUB_TYPE, PREM_CODE, PREM_SEQ, STATUS, TOT_PAY_AMT
       ,CLM_SEQ ,SETTLE_DATE,OFFSET_FLAG)
       (
        select clm_no, pay_no, trn_seq+1, pay_sts, pay_amt, trn_amt, curr_code, curr_rate, sts_date,v_sysdate, clm_men, amd_user, prod_grp, prod_type, sts_key, type, sub_type, prem_code, prem_seq, status, tot_pay_amt
        ,clm_seq ,v_sysdate ,offset_flag
        from nc_payment a
        where  a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
        and a.pay_no = vPayNo
        );
        
        
    Insert into ALLCLM.NC_PAYMENT_INFO
       (CLM_NO, PAY_NO, TYPE, PROD_GRP, PROD_TYPE, TRN_SEQ, STS_DATE, AMD_DATE, CLM_USER, STS_KEY
        ,PART ,REMARK ,INVOICE_NO,REF_NO ,AMD_USER ,PRINT_BATCH)
       (
        select clm_no, pay_no, type, prod_grp, prod_type, trn_seq +1, sts_date,v_sysdate, clm_user, sts_key
        ,part ,remark ,invoice_no,ref_no ,amd_user ,print_batch
        from nc_payment_info a
        where  a.trn_seq in (select max(aa.trn_seq) from nc_payment_info aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
        and a.pay_no = vPayNo
       ) ;
       

    Insert into ALLCLM.NC_PAYEE
       (CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TRN_SEQ, STS_DATE, AMD_DATE, PAYEE_CODE, PAYEE_NAME, PAYEE_TYPE, PAYEE_SEQ, PAYEE_AMT, SETTLE, ACC_NO, ACC_NAME, BANK_CODE, BANK_BR_CODE, BR_NAME, SEND_TITLE, PAID_STS, DEDUCT_FLAG, TYPE, SENT_TYPE, SALVAGE_AMT, DEDUCT_AMT, CURR_CODE
        ,SEND_ADDR1 ,SEND_ADDR2 ,SALVAGE_FLAG ,EMAIL ,SMS ,APPOINT_DATE ,CURR_RATE ,AGENT_SMS ,AGENT_EMAIL ,SPECIAL_FLAG ,SPECIAL_REMARK ,GRP_PAYEE_FLAG ,URGENT_FLAG)
       (
        select clm_no, pay_no, prod_grp, prod_type, trn_seq +1, sts_date, v_sysdate, payee_code, payee_name, payee_type, payee_seq, payee_amt, settle, acc_no, acc_name, bank_code, bank_br_code, br_name, send_title, paid_sts, deduct_flag, type, sent_type, salvage_amt, deduct_amt, curr_code
        ,send_addr1 ,send_addr2 ,salvage_flag ,email ,sms ,appoint_date ,curr_rate ,agent_sms ,agent_email ,special_flag ,special_remark ,grp_payee_flag ,urgent_flag 
        from nc_payee a
        where  a.trn_seq in (select max(aa.trn_seq) from nc_payee aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
        and a.pay_no = vPayNo
       ) ;
       

    Insert into ALLCLM.NC_RI_PAID
       (STS_KEY, CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_SHARE, TRN_SEQ, RI_STS_DATE, RI_AMD_DATE, RI_PAY_AMT, RI_TRN_AMT, STATUS, SUB_TYPE
       ,LETT_NO ,LETT_PRT ,LETT_TYPE ,CASHCALL ,CANCEL ,PRINT_TYPE ,PRINT_USER ,PRINT_DATE
       )
       (
       select sts_key, clm_no, pay_no, prod_grp, prod_type, type, ri_code, ri_br_code, ri_type, ri_lf_flag, ri_sub_type, ri_share, trn_seq +1, ri_sts_date,v_sysdate, ri_pay_amt, ri_trn_amt, status, sub_type
       ,lett_no ,lett_prt ,lett_type ,cashcall ,cancel ,print_type ,print_user ,print_date
        from nc_ri_paid a
        where  a.trn_seq in (select max(aa.trn_seq) from nc_ri_paid aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
        and a.pay_no = vPayNo
       );
       
    commit;
    return true;  
EXCEPTION  
    WHEN OTHERS THEN  
    rollback; P_RST := 'error update payno: '||vPayNo||' ->'||sqlerrm ; return false;          
END SET_SETTLEDATE;  


FUNCTION SET_SETTLEDATE(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,vApproveDate in DATE ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
    v_sysdate   date:=sysdate;
    /*  vApproveDate สำหรับกรณีเรียกซ่อมงานที่ไม่ได้ stamp nc_payment.settle_date*/
BEGIN 
    v_sysdate := nvl(vApproveDate,sysdate);
    Insert into ALLCLM.NC_PAYMENT
       (CLM_NO, PAY_NO, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, PROD_GRP, PROD_TYPE, STS_KEY, TYPE, SUB_TYPE, PREM_CODE, PREM_SEQ, STATUS, TOT_PAY_AMT
       ,CLM_SEQ ,SETTLE_DATE,OFFSET_FLAG)
       (
        select clm_no, pay_no, trn_seq+1, pay_sts, pay_amt, trn_amt, curr_code, curr_rate, sts_date,v_sysdate, clm_men, amd_user, prod_grp, prod_type, sts_key, type, sub_type, prem_code, prem_seq, status, tot_pay_amt
        ,clm_seq ,v_sysdate ,offset_flag
        from nc_payment a
        where  a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
        and a.pay_no = vPayNo
        );
        
        
    Insert into ALLCLM.NC_PAYMENT_INFO
       (CLM_NO, PAY_NO, TYPE, PROD_GRP, PROD_TYPE, TRN_SEQ, STS_DATE, AMD_DATE, CLM_USER, STS_KEY
        ,PART ,REMARK ,INVOICE_NO,REF_NO ,AMD_USER ,PRINT_BATCH)
       (
        select clm_no, pay_no, type, prod_grp, prod_type, trn_seq +1, sts_date,v_sysdate, clm_user, sts_key
        ,part ,remark ,invoice_no,ref_no ,amd_user ,print_batch
        from nc_payment_info a
        where  a.trn_seq in (select max(aa.trn_seq) from nc_payment_info aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
        and a.pay_no = vPayNo
       ) ;
       

    Insert into ALLCLM.NC_PAYEE
       (CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TRN_SEQ, STS_DATE, AMD_DATE, PAYEE_CODE, PAYEE_NAME, PAYEE_TYPE, PAYEE_SEQ, PAYEE_AMT, SETTLE, ACC_NO, ACC_NAME, BANK_CODE, BANK_BR_CODE, BR_NAME, SEND_TITLE, PAID_STS, DEDUCT_FLAG, TYPE, SENT_TYPE, SALVAGE_AMT, DEDUCT_AMT, CURR_CODE
        ,SEND_ADDR1 ,SEND_ADDR2 ,SALVAGE_FLAG ,EMAIL ,SMS ,APPOINT_DATE ,CURR_RATE ,AGENT_SMS ,AGENT_EMAIL ,SPECIAL_FLAG ,SPECIAL_REMARK ,GRP_PAYEE_FLAG ,URGENT_FLAG)
       (
        select clm_no, pay_no, prod_grp, prod_type, trn_seq +1, sts_date, v_sysdate, payee_code, payee_name, payee_type, payee_seq, payee_amt, settle, acc_no, acc_name, bank_code, bank_br_code, br_name, send_title, paid_sts, deduct_flag, type, sent_type, salvage_amt, deduct_amt, curr_code
        ,send_addr1 ,send_addr2 ,salvage_flag ,email ,sms ,appoint_date ,curr_rate ,agent_sms ,agent_email ,special_flag ,special_remark ,grp_payee_flag ,urgent_flag 
        from nc_payee a
        where  a.trn_seq in (select max(aa.trn_seq) from nc_payee aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
        and a.pay_no = vPayNo
       ) ;
       

    Insert into ALLCLM.NC_RI_PAID
       (STS_KEY, CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_SHARE, TRN_SEQ, RI_STS_DATE, RI_AMD_DATE, RI_PAY_AMT, RI_TRN_AMT, STATUS, SUB_TYPE
       ,LETT_NO ,LETT_PRT ,LETT_TYPE ,CASHCALL ,CANCEL ,PRINT_TYPE ,PRINT_USER ,PRINT_DATE
       )
       (
       select sts_key, clm_no, pay_no, prod_grp, prod_type, type, ri_code, ri_br_code, ri_type, ri_lf_flag, ri_sub_type, ri_share, trn_seq +1, ri_sts_date,v_sysdate, ri_pay_amt, ri_trn_amt, status, sub_type
       ,lett_no ,lett_prt ,lett_type ,cashcall ,cancel ,print_type ,print_user ,print_date
        from nc_ri_paid a
        where  a.trn_seq in (select max(aa.trn_seq) from nc_ri_paid aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
        and a.pay_no = vPayNo
       );
       
    commit;
    return true;  
EXCEPTION  
    WHEN OTHERS THEN  
    rollback; P_RST := 'error update payno: '||vPayNo||' ->'||sqlerrm ; return false;          
END SET_SETTLEDATE;  

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

