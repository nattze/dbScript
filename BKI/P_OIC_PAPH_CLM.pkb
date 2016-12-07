CREATE OR REPLACE PACKAGE BODY ALLCLM.P_OIC_PAPH_CLM AS
/******************************************************************************
   NAME:       P_OIC_PAPH_CLM
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        14/08/2015      2702       1. Created this package.
   2.0        03/02/2016       2702       2. adjust by OIC announce 
******************************************************************************/

PROCEDURE get_PAPH_Claim( i_datefr IN DATE ,i_dateto IN DATE  ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2)
IS
  o_msg VARCHAR2(250);

BEGIN
    Clear_PAPH_Claim(null ,i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);
    getMain_PAPH_Claim('PA' ,i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);
    getMain_PAPH_Claim('GM' ,i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);
    
    o_rst := o_msg ;
END get_PAPH_Claim;


PROCEDURE get_PAPH_Claim( i_datefr IN DATE ,i_dateto IN DATE  ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_cnt_clm OUT NUMBER ,o_cnt_payment OUT NUMBER)
IS
    o_msg VARCHAR2(250);
    X NUMBER;
    myJob VARCHAR2(10);
    myStartTime   DATE:=sysdate+ (10 / (24 * 60 * 60));    
    v_job_txt varchar2(3000);

BEGIN


--    Clear_PAPH_Claim(null ,i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);
--    getMain_PAPH_Claim('PA' ,i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);
--    getMain_PAPH_Claim('GM' ,i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);
    v_job_txt := '
    declare
        o_rst   varchar2(200);
    begin
      p_oic_paph_clm.Clear_PAPH_Claim('''',
                                        '''||i_datefr||''',
                                        '''||i_dateto||''',
                                        '''||i_dateto||''',
                                        '''||i_user||''' ,o_rst);     

      p_oic_paph_clm.getMain_PAPH_Claim(''PA'',
                                        '''||i_datefr||''',
                                        '''||i_dateto||''',
                                        '''||i_dateto||''',
                                        '''||i_user||''' ,o_rst);  

      p_oic_paph_clm.getMain_PAPH_Claim(''GM'',
                                        '''||i_datefr||''',
                                        '''||i_dateto||''',
                                        '''||i_dateto||''',
                                        '''||i_user||''' ,o_rst);    
                                                                                                                  
      p_oic_paph_clm.getMain_PAPH_Claim('''',
                                        '''||i_datefr||''',
                                        '''||i_dateto||''',
                                        '''||i_dateto||''',
                                        '''||i_user||''' ,o_rst);       
                                        
    end;' ;
    
    dbms_output.put_line(v_job_txt);
      SYS.DBMS_JOB.SUBMIT
        (
          job        => X
         ,what       => v_job_txt
         ,next_date  => myStartTime
         ,no_parse   => FALSE
        );
    myJob := to_char(X);
    dbms_output.put_line('myJob='||myJob||' start: '||to_char(myStartTime,'mm/dd/yyyy hh24:mi:ss'));
    commit;
  
--- Gen Email     
     o_cnt_clm := 0 ; o_cnt_payment := 0;
END get_PAPH_Claim;


PROCEDURE getMain_PAPH_Claim(i_type IN VARCHAR2 ,i_datefr IN DATE ,i_dateto IN DATE  ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2)
IS
  -- t_type  : PA ,GM
--  i_datefr  date:='1-JAN-14';
--  i_dateto date:='1-JAN-15';
    o_msg VARCHAR2(250);
    x_subject   varchar2(1000);
    x_message   varchar2(1000);  
    V_RECORD_DATE   DATE:=sysdate;  
    o_cnt_clm   number;
    o_cnt_ins   number;
    o_cnt_payment number;
BEGIN
    if i_type = 'PA' then      
        get_PA_Claim_v2( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);        
--        get_pa_claim_out( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);    
--        get_pa_claim_outpaid( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);    
--        get_pa_claim_paid( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);    
--        get_pa_claim_outcwp( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);    
--        get_pa_claim_cwp( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);    
    elsif i_type = 'GM' then
        get_GM_Claim_v2( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);      
--        get_gm_claim_out( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);    
--        get_gm_claim_outpaid( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);    
--        get_gm_claim_paid( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);    
--        get_gm_claim_outcwp( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);    
--        get_gm_claim_cwp( i_datefr ,i_dateto ,i_asdate ,i_user ,o_msg);    
    else
        x_subject := 'ผลการ Get Data PAGM @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
        x_message := 'Criteria fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
        
        begin
            select  count(*) into o_cnt_clm
            from OIC_PAPH_CLAIM
            where fr_date = i_datefr
            and to_date = i_dateto ;  
        exception
            when no_data_found then
                o_cnt_clm := 0;
            when others then
                o_cnt_clm := 0;
        end ;

        begin
            select  count(*) into o_cnt_ins
            from OIC_PAPH_INS_CLAIM
            where fr_date = i_datefr
            and to_date = i_dateto ;  
        exception
            when no_data_found then
                o_cnt_ins := 0;
            when others then
                o_cnt_ins := 0;
        end ;
                
        begin
            select  count(*) into o_cnt_payment
            from OIC_PAPH_PAYMENT
            where fr_date = i_datefr
            and to_date = i_dateto ;  
        exception
            when no_data_found then
                o_cnt_payment := 0;
            when others then
                o_cnt_payment := 0;
        end ;  
        
        x_message := x_message||' record OIC_PAPH_CLAIM = '||o_cnt_clm||'<br/>' ;
        x_message := x_message||' record OIC_PAPH_PAYMENT = '||o_cnt_payment||'<br/>' ;
        x_message := x_message||' record OIC_PAPH_INS_CLAIM = '||o_cnt_ins||'<br/>' ;
        P_OIC_PAPH_CLM.email_log(x_subject ,x_message,i_user);          
    end if;
    o_rst := o_msg ;
END getMain_PAPH_Claim;

PROCEDURE Clear_PAPH_Claim(i_type IN VARCHAR2 ,i_datefr IN DATE ,i_dateto IN DATE  ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2)
IS
  -- t_type  : PA ,GM
--  i_datefr  date:='1-JAN-14';
--  i_dateto date:='1-JAN-15';
  o_msg VARCHAR2(250);
BEGIN
--    if i_type = 'PA' then
--
--    elsif i_type = 'GM' then            
--
--    end if;
    delete from OIC_PAPH_CLAIM a
    where fr_date = i_datefr  and to_date = i_dateto;

    delete from OIC_PAPH_INS_CLAIM a
    where fr_date = i_datefr  and to_date = i_dateto;

    delete from OIC_PAPH_PAYMENT a
    where fr_date = i_datefr  and to_date = i_dateto;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        rollback;
        o_rst := 'error :'||sqlerrm;
    
END Clear_PAPH_Claim;

PROCEDURE get_PA_Claim_out(i_datefr IN DATE ,i_dateto IN DATE  ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(2);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);
    
    v_cnt number(10):=0;
    v_runclmseq number(5);    
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
BEGIN
    x_subject := 'run get_pa_claim_out @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim Out === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    
    FOR M1 in (
        select a.clm_no ,'' pay_no ,fleet_seq ,recpt_seq ,pol_no ,pol_run ,reg_date ,a.loss_date ,clm_sts , dis_code ,risk_code ,tot_res
        ,decode(ipd_flag,'O','OPD','I','IPD','OPD') CLM_TYPE ,clm_date ,prod_type
        from mis_clm_mas a ,mis_cpa_res b
        where a.clm_no = b.clm_no and prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='PA') 
        and clm_sts in ('0','1','6')
        and clm_date between i_datefr and  i_dateto
        and (b.clm_no ,b.revise_seq) in (select bb.clm_no ,max(bb.revise_seq) from mis_cpa_res bb where bb.clm_no =b.clm_no 
        and bb.corr_date <= i_asdate group by bb.clm_no)
        and corr_date <= i_asdate
        and channel <> '9'
        --and a.clm_no ='201301002015766'
--        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'EC')
--        and rownum < 50
        order by a.clm_no
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        V_CLAIMSEQ := 0;
        V_CLAIMGROUP := 'EC'; 

        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype); 

        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if V_MAINCLASS is null then
            V_MAINCLASS := '06';    
            IF v_poltype = 'PI' THEN
                V_SUBCLASS := '01';
                IF nc_health_package.is_unname_policy(m1.pol_no ,m1.pol_run) THEN
                    V_SUBCLASS := '03';
                END IF;
            ELSIF  v_poltype = 'PG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;
        end if;
                
--        V_CLAIMSEQ := 1;
        V_CLAIMTYPE := GET_CLMTYPE('PA',m1.CLM_TYPE ,v_premcode);
        V_INSUREDSEQ := nvl(M1.fleet_seq,0);
        V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
        V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
        V_LOSSDATE :=  m1.loss_date; --to_date(m1.loss_date,'yyyymmdd');
        V_CLAIMSTATUS := '1';  --  open claim
        V_CLAIMCAUSE := m1.dis_code ; -- Accident
        V_ICD10CODE1 := m1.dis_code;
--        V_CLAIMAMT := m1.tot_res;
        V_TRANSACTIONSTATUS  :='N';
        V_REFERENCENUMBER    :=null;     
        V_DEDUCTIBLEAMT :=0;       
        V_ACCOUNTINGDATE := M1.clm_date ;
                
        get_citizen('PA' ,m1.pol_no ,m1.pol_run ,m1.fleet_seq ,nvl(m1.recpt_seq,1)  ,'' ,M1.CLM_NO ,M1.PAY_NO ,V_INSUREDNAME ,V_INSUREDCITIZENID);
        
        if m1.clm_type = 'OPD' then
            V_TREATMENTTYPE := '1';
        elsif m1.clm_type = 'IPD' then
            V_TREATMENTTYPE := '2';
        else
            V_TREATMENTTYPE := '3';
        end if;
        
--        FOR c_payee in (
--            select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
--            from mis_clm_payee a
--            where pay_no = M1.pay_no
--        ) LOOP
--            V_PAYEEAMT := c_payee.payee_amt;
--            V_PAIDBY := get_paidby('PA',c_payee.settle);
--        END LOOP;
--        V_CLAIMPAIDSEQ :=1;
                
        -- ===== Path get prem code ====
        GET_PA_RESERVE(M1.CLM_NO,
                                        v_sid,
                                        p1_rst);          
                
        if p1_rst is null then
        FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
        from NC_H_HISTORY_TMP
        where sid = v_sid )
        LOOP    
            v_runclmseq := v_runclmseq+1;
            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
            v_premcode := p1.prem_code;    
            V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
            V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
            
            V_CLAIMAMT := p1.amount;
            
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE  , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

        END LOOP;      -- loop get Reserved
        end if;
        NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
        -- ===== End Path get prem code ====
        
--        V_CHEQUEDATE   :=null;
--        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
--        V_CHEQUENO     VARCHAR2(20);
--        V_PAYEEAMT  NUMBER(15,2);
            
        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
        

        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        

    END LOOP;
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
    email_log(x_subject ,x_message);
END get_PA_Claim_out;
  
PROCEDURE get_PA_Claim_outpaid(i_datefr IN DATE ,i_dateto IN DATE  ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(2);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);

    ACR_PAID_TYPE    VARCHAR2(1);
    ACR_PAID_DATE   DATE;
    ACR_BANK_CODE   VARCHAR2(20);
    ACR_BRANCH_CODE VARCHAR2(20);
    ACR_CHEQUE_NO   VARCHAR2(20);
    
    v_runclmseq number(5);        
    v_cnt number(10):=0;
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
BEGIN
    x_subject := 'run get_pa_claim_outpaid @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim Out+Paid === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    
    FOR M1 in (
        select a.clm_no ,b.pay_no ,fleet_seq ,recpt_seq ,pol_no ,pol_run ,reg_date ,a.loss_date ,clm_sts , dis_code ,risk_code ,tot_paid
        ,decode(ipd_flag,'O','OPD','I','IPD','OPD') CLM_TYPE ,clm_date ,close_date ,prod_type
        from mis_clm_mas a  ,mis_clm_paid c ,mis_cpa_paid b
        where a.clm_no = c.clm_no and a.clm_no = b.clm_no and c.pay_no = b.pay_no  and c.corr_seq = b.corr_seq 
        and prod_type in (select prod_type from clm_grp_prod where sysid='PA') 
        and clm_sts ='2' 
        and clm_date between i_datefr and  i_dateto
        and close_date between i_datefr and  i_dateto
        and to_char(clm_date,'yyyymm') = to_char(close_date,'yyyymm')
        and (b.pay_no ,b.corr_seq) in (select bb.pay_no ,max(bb.corr_seq) from mis_clm_paid bb where bb.pay_no =c.pay_no 
        and bb.corr_date <= i_asdate group by bb.pay_no)
        and b.cancel is null
        and corr_date <= i_asdate
        and channel <> '9'
        --and a.clm_no ='201301002015766'
--        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'P')
--        and rownum<50
        order by a.clm_no
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        V_CLAIMSEQ := 0;
--        V_CLAIMGROUP := 'P';

        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);
   
        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if V_MAINCLASS is null then
            V_MAINCLASS := '06';    
            IF v_poltype = 'PI' THEN
                V_SUBCLASS := '01';
                IF nc_health_package.is_unname_policy(m1.pol_no ,m1.pol_run) THEN
                    V_SUBCLASS := '03';
                END IF;
            ELSIF  v_poltype = 'PG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;
        end if;
                        
        V_CLAIMTYPE := GET_CLMTYPE('PA',m1.CLM_TYPE ,v_premcode);
        V_INSUREDSEQ := nvl(M1.fleet_seq,0);
        V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
        V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
        V_LOSSDATE :=  m1.loss_date; --to_date(m1.loss_date,'yyyymmdd');
        --V_CLAIMSTATUS := '2';  -- close claim
        V_CLAIMCAUSE := m1.dis_code ; -- Accident
        V_ICD10CODE1 := m1.dis_code;
        V_CLAIMAMT := m1.tot_paid;
        V_TRANSACTIONSTATUS  :='N';
        V_REFERENCENUMBER    :=null;     
        V_DEDUCTIBLEAMT :=0;       

        begin
            select pay_date into V_CHEQUEDATE
            from mis_clm_paid a
            where pay_no = m1.pay_no and
            a.corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no group by aa.pay_no);
            
            if V_CHEQUEDATE is null then
                V_CHEQUEDATE := M1.close_date;
            end if; 
        exception
            when no_data_found then
                V_CHEQUEDATE := M1.close_date;
            when others then
                V_CHEQUEDATE := M1.close_date;
        end;    
                
        get_citizen('PA' ,m1.pol_no ,m1.pol_run ,m1.fleet_seq ,nvl(m1.recpt_seq,1)  ,''  ,M1.CLM_NO ,M1.PAY_NO ,V_INSUREDNAME ,V_INSUREDCITIZENID);
                
        if m1.clm_type = 'OPD' then
            V_TREATMENTTYPE := '1';
        elsif m1.clm_type = 'IPD' then
            V_TREATMENTTYPE := '2';
        else
            V_TREATMENTTYPE := '3';
        end if;
                
        -- ===== Path get prem code ====
        nc_health_paid.get_pa_reserve(M1.PAY_NO,
                                        v_sid,
                                        p1_rst);          
                
        if p1_rst is null then
        FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
        from NC_H_HISTORY_TMP
        where sid = v_sid -- and rownum=1
        )
        LOOP    
            v_runclmseq := v_runclmseq+1;
            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
            v_premcode := p1.prem_code;  
            
            V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
            V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);     
                   
            --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('PA',m1.CLM_TYPE ,v_premcode);
            V_CLAIMAMT := p1.amount;  
            
            -- == set EC
            V_ACCOUNTINGDATE := M1.clm_date;
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'EC' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '1' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'EC' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '1' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;
            
            --=== P
            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
            V_ACCOUNTINGDATE := M1.close_date;
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '2' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '2' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE, i_datefr, i_dateto , i_asdate ,v_record_date ,i_user )          ;
                                
        END LOOP;      
        end if;
        NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
        -- ===== End Path get prem code ====

        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        

        
        FOR c_payee in (  -- Get Payee
            select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
            from mis_clm_payee a
            where pay_no = M1.pay_no and payee_code is not null
        ) LOOP
            V_PAYEEAMT := c_payee.payee_amt;
            V_PAIDBY := get_paidby('PA',c_payee.settle);
            V_CLAIMPAIDSEQ :=c_payee.pay_seq ;
            V_CHEQUENO := null;
            
            if V_PAIDBY = 'K' then
                account.p_acc_acr.get_paid_info(M1.pay_no,'0',M1.prod_type,c_payee.payee_code,c_payee.settle,
                                              ACR_PAID_TYPE, ACR_PAID_DATE, ACR_BANK_CODE, ACR_BRANCH_CODE, ACR_CHEQUE_NO);
                V_CHEQUENO := ACR_CHEQUE_NO;          
                
                IF V_CHEQUENO is null THEN
                    V_PAIDBY := 'O' ;
                END IF;               
            elsif V_PAIDBY = 'T' then
                V_CHEQUENO := null;
            end if;    
            
            if V_PAYEEAMT = 0 then
                V_PAYEEAMT := M1.tot_paid;    
            end if;
            
                        
            INSERT INTO OIC_PAPH_PAYMENT
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

            INSERT INTO OIC_PAPH_PAYMENT_HIST
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);              
        END LOOP;
        
--        V_CHEQUEDATE   :=null;
--        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
--        V_CHEQUENO     VARCHAR2(20);
--        V_PAYEEAMT  NUMBER(15,2);
            
        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
             
    END LOOP;
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
    email_log(x_subject ,x_message);    
END get_PA_Claim_outpaid;

PROCEDURE get_PA_Claim_paid(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(2);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);
    
    ACR_PAID_TYPE    VARCHAR2(1);
    ACR_PAID_DATE   DATE;
    ACR_BANK_CODE   VARCHAR2(20);
    ACR_BRANCH_CODE VARCHAR2(20);
    ACR_CHEQUE_NO   VARCHAR2(20);
    
    v_runclmseq number(5);        
    v_cnt number(10):=0;
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    V_TRANSACTIONSTATUS2    VARCHAR2(1);  
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
BEGIN
    x_subject := 'run get_pa_claim_paid @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim Paid === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    
    FOR M1 in (
        select a.clm_no ,b.pay_no ,fleet_seq ,recpt_seq ,pol_no ,pol_run ,reg_date ,a.loss_date ,clm_sts , dis_code ,risk_code ,tot_paid
        ,decode(ipd_flag,'O','OPD','I','IPD','OPD') CLM_TYPE ,clm_date ,close_date ,prod_type
        from mis_clm_mas a  ,mis_clm_paid c ,mis_cpa_paid b
        where a.clm_no = c.clm_no and a.clm_no = b.clm_no and c.pay_no = b.pay_no  and c.corr_seq = b.corr_seq 
        and prod_type in (select prod_type from clm_grp_prod where sysid='PA') 
        and clm_sts ='2' 
--        and clm_date between i_datefr and  i_dateto
        and close_date between i_datefr and  i_dateto
        and to_char(clm_date,'yyyymm') < to_char(close_date,'yyyymm')
        and (b.pay_no ,b.corr_seq) in (select bb.pay_no ,max(bb.corr_seq) from mis_clm_paid bb where bb.pay_no =c.pay_no 
        and bb.corr_date <= i_asdate group by bb.pay_no)
        and b.cancel is null
        and corr_date <= i_asdate
        and channel <> '9'
--        and a.clm_no ='201401002062213'
--        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'P')
--        and rownum<50
        order by a.clm_no
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        V_CLAIMSEQ := 0;
--        V_CLAIMGROUP := 'P';
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);
   
        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if V_MAINCLASS is null then
            V_MAINCLASS := '06';    
            IF v_poltype = 'PI' THEN
                V_SUBCLASS := '01';
                IF nc_health_package.is_unname_policy(m1.pol_no ,m1.pol_run) THEN
                    V_SUBCLASS := '03';
                END IF;
            ELSIF  v_poltype = 'PG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;
        end if;
                        
        V_CLAIMTYPE := p_oic_paph_clm.GET_CLMTYPE('PA',m1.CLM_TYPE ,v_premcode);
        V_INSUREDSEQ := nvl(M1.fleet_seq,0);
        V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
        V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
        V_LOSSDATE :=  m1.loss_date; --to_date(m1.loss_date,'yyyymmdd');
        V_CLAIMSTATUS := '2';  -- close claim
        V_CLAIMCAUSE := m1.dis_code ; -- Accident
        V_ICD10CODE1 := m1.dis_code;
        V_CLAIMAMT := m1.tot_paid;
        V_TRANSACTIONSTATUS  :='N';
        V_REFERENCENUMBER    :=null;     
        V_DEDUCTIBLEAMT :=0;       

        begin
            select pay_date into V_CHEQUEDATE
            from mis_clm_paid a
            where pay_no = m1.pay_no and
            a.corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no group by aa.pay_no);
            
            if V_CHEQUEDATE is null then
                V_CHEQUEDATE := M1.close_date;
            end if; 
        exception
            when no_data_found then
                V_CHEQUEDATE := M1.close_date;
            when others then
                V_CHEQUEDATE := M1.close_date;
        end;    
                
        p_oic_paph_clm.get_citizen('PA' ,m1.pol_no ,m1.pol_run ,m1.fleet_seq ,nvl(m1.recpt_seq,1)  ,''  ,M1.CLM_NO ,M1.PAY_NO ,V_INSUREDNAME ,V_INSUREDCITIZENID);
        
        if m1.clm_type = 'OPD' then
            V_TREATMENTTYPE := '1';
        elsif m1.clm_type = 'IPD' then
            V_TREATMENTTYPE := '2';
        else
            V_TREATMENTTYPE := '3';
        end if;
                
        -- ===== Path get prem code ====
        nc_health_paid.get_pa_reserve(M1.PAY_NO,
                                        v_sid,
                                        p1_rst);          
                
        if p1_rst is null then
        FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
        from NC_H_HISTORY_TMP
        where sid = v_sid -- and rownum=1
        )
        LOOP    
            v_runclmseq := v_runclmseq+1;
            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
            v_premcode := p1.prem_code;  
            
            V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
            V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);            
            --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('PA',m1.CLM_TYPE ,v_premcode);
            V_CLAIMAMT := p1.amount;  
                       
            --=== P
            V_ACCOUNTINGDATE := M1.close_date;
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user )          ;
                                
        END LOOP;      
        end if;
        NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
        -- ===== End Path get prem code ====
        
        IF p_oic_paph_clm.hasINS_data(V_CLAIMNUMBER) THEN
            V_TRANSACTIONSTATUS2 := 'U';        
        ELSE    
            V_TRANSACTIONSTATUS2 := 'N';        
        END IF;
        
        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        

        
        FOR c_payee in (  -- Get Payee
            select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
            from mis_clm_payee a
            where pay_no = M1.pay_no and payee_code is not null 
        ) LOOP
            V_PAYEEAMT := c_payee.payee_amt;
            V_PAIDBY := p_oic_paph_clm.get_paidby('PA',c_payee.settle);
            V_CLAIMPAIDSEQ :=c_payee.pay_seq ;
            V_CHEQUENO := null;
            
            if V_PAIDBY = 'K' then
                account.p_acc_acr.get_paid_info(M1.pay_no,'0',M1.prod_type,c_payee.payee_code,c_payee.settle,
                                              ACR_PAID_TYPE, ACR_PAID_DATE, ACR_BANK_CODE, ACR_BRANCH_CODE, ACR_CHEQUE_NO);
                V_CHEQUENO := ACR_CHEQUE_NO;                              
                IF V_CHEQUENO is null THEN
                    V_PAIDBY := 'O' ;
                END IF;               
            elsif V_PAIDBY = 'T' then
                V_CHEQUENO := null;
            end if;               

            if V_PAYEEAMT = 0 then
                V_PAYEEAMT := M1.tot_paid;    
            end if;
                        
            INSERT INTO OIC_PAPH_PAYMENT
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

            INSERT INTO OIC_PAPH_PAYMENT_HIST
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);              
        END LOOP;
        
--        V_CHEQUEDATE   :=null;
--        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
--        V_CHEQUENO     VARCHAR2(20);
--        V_PAYEEAMT  NUMBER(15,2);
            
        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
             
    END LOOP;
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
    p_oic_paph_clm.email_log(x_subject ,x_message);   
END get_PA_Claim_paid;

PROCEDURE get_PA_Claim_outcwp(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(2);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);

    v_runclmseq number(5);        
    v_cnt number(10):=0;
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
BEGIN
    x_subject := 'run get_pa_claim_outcwp @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim Out+Cwp === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;

    FOR M1 in (
        select a.clm_no ,'' pay_no ,fleet_seq ,recpt_seq ,pol_no ,pol_run ,reg_date ,a.loss_date ,clm_sts , dis_code ,risk_code ,tot_res tot_paid
        ,decode(ipd_flag,'O','OPD','I','IPD','OPD') CLM_TYPE ,a.clm_date ,A.CLOSE_DATE ,prod_type
        from mis_clm_mas a ,mis_cpa_res b
        where a.clm_no = b.clm_no and prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='PA') 
        and clm_sts in ('3')
        and clm_date  between i_datefr and  i_dateto
        and close_date between i_datefr and  i_dateto
        and to_char(clm_date,'yyyymm') = to_char(close_date,'yyyymm')
        and (b.clm_no ,b.revise_seq) in (select bb.clm_no ,max(bb.revise_seq) from mis_cpa_res bb where bb.clm_no =b.clm_no 
        and bb.corr_date <= i_asdate group by bb.clm_no)
        and corr_date <= i_asdate
        and nvl(a.tot_res ,0) > 0 
        and channel <> '9'
        --and a.clm_no ='201301002015766'
        --and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'EC')   
        order by a.clm_no
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        V_CLAIMSEQ := 0;
--        V_CLAIMGROUP := 'P';
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);
   
        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if V_MAINCLASS is null then
            V_MAINCLASS := '06';    
            IF v_poltype = 'PI' THEN
                V_SUBCLASS := '01';
                IF nc_health_package.is_unname_policy(m1.pol_no ,m1.pol_run) THEN
                    V_SUBCLASS := '03';
                END IF;
            ELSIF  v_poltype = 'PG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;
        end if;
                        
        V_CLAIMTYPE := GET_CLMTYPE('PA',m1.CLM_TYPE ,v_premcode);
        V_INSUREDSEQ := nvl(M1.fleet_seq,0);
        V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
        V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
        V_LOSSDATE :=  m1.loss_date; --to_date(m1.loss_date,'yyyymmdd');
        --V_CLAIMSTATUS := '2';  -- close claim
        V_CLAIMCAUSE := m1.dis_code ; -- Accident
        V_ICD10CODE1 := m1.dis_code;
        V_CLAIMAMT := m1.tot_paid;
        V_TRANSACTIONSTATUS  :='N';
        V_REFERENCENUMBER    :=null;     
        V_DEDUCTIBLEAMT :=0;       

--        begin
--            select pay_date into V_ACCOUNTINGDATE
--            from mis_clm_paid a
--            where pay_no = m1.pay_no and
--            a.corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no group by aa.pay_no);
--        exception
--            when no_data_found then
--                V_ACCOUNTINGDATE := null;
--            when others then
--                V_ACCOUNTINGDATE := null;
--        end;    
                
        get_citizen('PA' ,m1.pol_no ,m1.pol_run ,m1.fleet_seq ,nvl(m1.recpt_seq,1)  ,'' ,M1.CLM_NO ,M1.PAY_NO ,V_INSUREDNAME ,V_INSUREDCITIZENID);
        
        if m1.clm_type = 'OPD' then
            V_TREATMENTTYPE := '1';
        elsif m1.clm_type = 'IPD' then
            V_TREATMENTTYPE := '2';
        else
            V_TREATMENTTYPE := '3';
        end if;
                
        -- ===== Path get prem code ====
        p_oic_paph_clm.GET_PA_RESERVE(M1.CLM_NO,
                                        v_sid,
                                        p1_rst);        
                
        if p1_rst is null then
        FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
        from NC_H_HISTORY_TMP
        where sid = v_sid -- and rownum=1
        )
        LOOP    
            v_runclmseq := v_runclmseq+1;
            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
            v_premcode := p1.prem_code;  
            V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
            V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);            
            --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('PA',m1.CLM_TYPE ,v_premcode);
            V_CLAIMAMT := p1.amount;  
            
            -- == set EC
            V_ACCOUNTINGDATE := M1.clm_date;
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'EC' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '1' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'EC' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '1' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;
            
            --=== P
            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
            V_ACCOUNTINGDATE := M1.close_date;
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '2' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            0 , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '2' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            0 , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user )          ;
                                
        END LOOP;      
        end if;
        NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
        -- ===== End Path get prem code ====

        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        

        
--        FOR c_payee in (  -- Get Payee
--            select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
--            from mis_clm_payee a
--            where pay_no = M1.pay_no
--        ) LOOP
--            V_PAYEEAMT := c_payee.payee_amt;
--            V_PAIDBY := get_paidby('PA',c_payee.settle);
--            V_CLAIMPAIDSEQ :=c_payee.pay_seq ;
--            
--            INSERT INTO OIC_PAPH_PAYMENT
--            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
--            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ) 
--            VALUES 
--            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
--            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER);
--
--            INSERT INTO OIC_PAPH_PAYMENT_HIST
--            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
--            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ) 
--            VALUES 
--            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
--            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE);              
--        END LOOP;
        
--        V_CHEQUEDATE   :=null;
--        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
--        V_CHEQUENO     VARCHAR2(20);
--        V_PAYEEAMT  NUMBER(15,2);

        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
             
    END LOOP;
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
    email_log(x_subject ,x_message);    
END get_PA_Claim_outcwp;

PROCEDURE get_PA_Claim_cwp(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(2);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_TRANSACTIONSTATUS2 VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);

    v_runclmseq number(5);        
    v_cnt number(10):=0;
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
BEGIN
    x_subject := 'run get_pa_claim_cwp @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim Cwp === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    
    FOR M1 in (
        select a.clm_no ,'' pay_no ,fleet_seq ,recpt_seq ,pol_no ,pol_run ,reg_date ,a.loss_date ,clm_sts , dis_code ,risk_code ,tot_res
        ,decode(ipd_flag,'O','OPD','I','IPD','OPD') CLM_TYPE ,a.clm_date ,A.CLOSE_DATE ,prod_type
        from mis_clm_mas a ,mis_cpa_res b
        where a.clm_no = b.clm_no and prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='PA') 
        and clm_sts in ('3')
        --and clm_date  between :i_datefr and  :i_dateto
        and close_date between i_datefr and  i_dateto
        and to_char(clm_date,'yyyymm') < to_char(close_date,'yyyymm')
        and (b.clm_no ,b.revise_seq) in (select bb.clm_no ,max(bb.revise_seq) from mis_cpa_res bb where bb.clm_no =b.clm_no 
        and bb.corr_date <= i_asdate group by bb.clm_no)
        and corr_date <= i_asdate
        and nvl(a.tot_res ,0) > 0 
        and channel <> '9'
        --and a.clm_no ='201301002015766'
        --and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'EC')        
        order by a.clm_no
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        V_CLAIMSEQ := 0;
--        V_CLAIMGROUP := 'P';
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);
   
        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if V_MAINCLASS is null then
            V_MAINCLASS := '06';    
            IF v_poltype = 'PI' THEN
                V_SUBCLASS := '01';
                IF nc_health_package.is_unname_policy(m1.pol_no ,m1.pol_run) THEN
                    V_SUBCLASS := '03';
                END IF;
            ELSIF  v_poltype = 'PG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;
        end if;
                        
        V_CLAIMTYPE := GET_CLMTYPE('PA',m1.CLM_TYPE ,v_premcode);
        V_INSUREDSEQ := nvl(M1.fleet_seq,0);
        V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
        V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
        V_LOSSDATE :=  m1.loss_date; --to_date(m1.loss_date,'yyyymmdd');
        V_CLAIMSTATUS := '2';  -- close claim
        V_CLAIMCAUSE := m1.dis_code; -- Accident
        V_ICD10CODE1 := m1.dis_code;
--        V_CLAIMAMT := m1.tot_paid;
        V_TRANSACTIONSTATUS  :='N';
        V_REFERENCENUMBER    :=null;     
        V_DEDUCTIBLEAMT :=0;       
        V_ACCOUNTINGDATE := M1.close_date;
                
        get_citizen('PA' ,m1.pol_no ,m1.pol_run ,m1.fleet_seq ,nvl(m1.recpt_seq,1)  ,''  ,M1.CLM_NO ,M1.PAY_NO ,V_INSUREDNAME ,V_INSUREDCITIZENID);
        
        if m1.clm_type = 'OPD' then
            V_TREATMENTTYPE := '1';
        elsif m1.clm_type = 'IPD' then
            V_TREATMENTTYPE := '2';
        else
            V_TREATMENTTYPE := '3';
        end if;
                
        -- ===== Path get prem code ====
        GET_PA_RESERVE(M1.CLM_NO,
                                        v_sid,
                                        p1_rst);     
                
        if p1_rst is null then
        FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
        from NC_H_HISTORY_TMP
        where sid = v_sid -- and rownum=1
        )
        LOOP    
            v_runclmseq := v_runclmseq+1;
            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
            v_premcode := p1.prem_code;  
            V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
            V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);            
            --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('PA',m1.CLM_TYPE ,v_premcode);
            V_CLAIMAMT :=0;  
            
            -- == set EC
            V_ACCOUNTINGDATE := M1.clm_date;
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE ,V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user )          ;
                                
        END LOOP;      
        end if;
        NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
        -- ===== End Path get prem code ====

        IF hasINS_data(V_CLAIMNUMBER) THEN
            V_TRANSACTIONSTATUS2 := 'U';        
        ELSE    
            V_TRANSACTIONSTATUS2 := 'N';        
        END IF;
        
        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        

        
--        FOR c_payee in (  -- Get Payee
--            select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
--            from mis_clm_payee a
--            where pay_no = M1.pay_no
--        ) LOOP
--            V_PAYEEAMT := c_payee.payee_amt;
--            V_PAIDBY := get_paidby('PA',c_payee.settle);
--            V_CLAIMPAIDSEQ :=c_payee.pay_seq ;
--            
--            INSERT INTO OIC_PAPH_PAYMENT
--            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
--            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ) 
--            VALUES 
--            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
--            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER);
--
--            INSERT INTO OIC_PAPH_PAYMENT_HIST
--            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
--            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ) 
--            VALUES 
--            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
--            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE);              
--        END LOOP;
        
--        V_CHEQUEDATE   :=null;
--        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
--        V_CHEQUENO     VARCHAR2(20);
--        V_PAYEEAMT  NUMBER(15,2);
            
        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
             
    END LOOP;
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
    email_log(x_subject ,x_message);    
END get_PA_Claim_cwp;

PROCEDURE get_GM_Claim_close(i_datefr IN DATE ,i_dateto IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(2);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(5);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);
    
    v_cnt number(10):=0;
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    v_runclmseq number(5);
    v_tmppayno  varchar2(20);
BEGIN
    FOR M1 in (
        select clm_no ,pol_no ,pol_run ,recpt_seq ,reg_date ,clm_sts ,'' risk_code ,tot_paid
        from mis_clm_mas a
        where  prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='GM') 
        and clm_sts ='2' 
        and close_date between i_datefr and i_dateto
        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'P')
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        v_runclmseq :=0;
        V_CLAIMGROUP := 'P';
        V_MAINCLASS := '07'; 
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);
   
        IF v_poltype = 'HI' THEN
            V_SUBCLASS := '01';
        ELSIF  v_poltype = 'HG' THEN
            V_SUBCLASS := '02';
        ELSE
            V_SUBCLASS := '99';
        END IF;
        
        FOR c_paid IN (
            select  pay_no, fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,date_paid pay_date ,pay_amt
            from clm_gm_paid a
            where clm_no = M1.CLM_NO
            and corr_seq in (select max(aa.corr_seq) from clm_gm_paid aa where aa.pay_no =a.pay_no group by aa.pay_no)
--            and pay_amt = (select max(b.pay_amt) from clm_gm_paid b where b.pay_no =a.pay_no and b.corr_seq = a.corr_seq)
            order by pay_no      
        )  LOOP
            -- ===== Path get prem code ====
            v_premcode := c_paid.bene_code;
            -- ===== End Path get prem code ====
                    
            v_runclmseq := v_runclmseq+1;
            v_tmppayno := c_paid.pay_no;
            V_CLAIMTYPE := GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
            V_INSUREDSEQ := c_paid.fleet_seq;
            V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
            V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
            V_CLAIMSTATUS := '2';  -- close claim        
            V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
            V_CLAIMCAUSE :='0000' ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
            V_ICD10CODE1 := c_paid.dis_code;
--            V_CLAIMAMT := m1.tot_paid;
            V_CLAIMAMT := c_paid.pay_amt;
            V_TRANSACTIONSTATUS  :='N';
            V_REFERENCENUMBER    :=null;     
            V_DEDUCTIBLEAMT :=0;       
            V_ACCOUNTINGDATE := c_paid.pay_date ;
                    
            get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date ,V_INSUREDNAME ,V_INSUREDCITIZENID);
            
            if c_paid.clm_type = 'OPD' then
                V_TREATMENTTYPE := '1';
            elsif c_paid.clm_type = 'IPD' then
                V_TREATMENTTYPE := '2';
            else
                V_TREATMENTTYPE := '3';
            end if;  
                            
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto ,'' ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE )          ;
                    
    --        V_CHEQUEDATE   :=null;
    --        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
    --        V_CHEQUENO     VARCHAR2(20);
    --        V_PAYEEAMT  NUMBER(15,2);
        END LOOP; -- C_paid
            
        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
        

        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER ,V_RECORD_DATE);                        

        FOR c_payee in (
            select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
            from clm_gm_payee a
            where pay_no = V_TMPPAYNO
        ) LOOP
            V_PAYEEAMT := c_payee.payee_amt;
            V_PAIDBY := get_paidby('GM',c_payee.settle);       
            V_CLAIMPAIDSEQ :=c_payee.pay_seq;
                 
            INSERT INTO OIC_PAPH_PAYMENT
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER);

            INSERT INTO OIC_PAPH_PAYMENT_HIST
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE);   
                    
        END LOOP;  -- payee 
--        FOR c_gmpaid in (
--            select settle
--            from mis_clmgm_paid a
--            where pay_no = V_TMPPAYNO and corr_seq in (select max(aa.corr_seq) from mis_clmgm_paid aa 
--            where aa.pay_no =a.pay_no group by aa.pay_no)
--        ) LOOP
--            V_PAIDBY := get_paidby('GM',c_gmpaid.settle);
--        END LOOP; 
            
     
    END LOOP;  -- clm_mas
    COMMIT;
END get_GM_Claim_close;

PROCEDURE get_GM_Claim_reserve(i_datefr IN DATE ,i_dateto IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(2);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(5);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);
    
    v_cnt number(10):=0;
    v_runclmseq number(5);
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
BEGIN
    FOR M1 in (
        select clm_no ,pol_no ,pol_run ,recpt_seq ,reg_date ,clm_sts ,'' risk_code ,tot_res
        from mis_clm_mas a
        where  prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='GM') 
        and clm_sts in ('0','1','6')
        and clm_date between i_datefr and i_dateto
--        and rownum<31
        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'EC')
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
--        V_CLAIMSEQ :=1;
        v_runclmseq := 0;
        V_CLAIMGROUP := 'EC';
        V_MAINCLASS := '07'; 
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);
   
        IF v_poltype = 'HI' THEN
            V_SUBCLASS := '01';
        ELSIF  v_poltype = 'HG' THEN
            V_SUBCLASS := '02';
        ELSE
            V_SUBCLASS := '99';
        END IF;
        
        FOR c_paid IN ( 
            select '' pay_no , fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,state_date , res_amt
            from clm_medical_res a
            where  clm_no =M1.CLM_NO
            and (clm_no ,state_seq) in (select clm_no ,max(aa.state_seq) from clm_medical_res aa where aa.clm_no =a.clm_no group by aa.clm_no)
            order by res_amt               
        )  LOOP
            -- ===== Path get prem code ====
            v_premcode := c_paid.bene_code;
            -- ===== End Path get prem code ====
            v_runclmseq := v_runclmseq+1;         
            V_CLAIMSEQ := v_runclmseq;
            V_CLAIMTYPE := GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
            V_INSUREDSEQ := c_paid.fleet_seq;
            V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
            V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
            V_CLAIMSTATUS := '1';  -- Reserve claim        
            V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
            V_CLAIMCAUSE :='0000' ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
            V_ICD10CODE1 := c_paid.dis_code;
            V_CLAIMAMT := c_paid.res_amt;
            V_TRANSACTIONSTATUS  :='N';
            V_REFERENCENUMBER    :=null;     
            V_DEDUCTIBLEAMT :=0;       
            V_ACCOUNTINGDATE := c_paid.state_date ;
                    
            get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date ,V_INSUREDNAME ,V_INSUREDCITIZENID);
            
            if c_paid.clm_type = 'OPD' then
                V_TREATMENTTYPE := '1';
            elsif c_paid.clm_type = 'IPD' then
                V_TREATMENTTYPE := '2';
            else
                V_TREATMENTTYPE := '3';
            end if;

            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , '' ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE )          ;
                    
            FOR c_payee in (
                select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
                from clm_gm_payee a
                where pay_no = c_paid.pay_no
            ) LOOP
                V_PAYEEAMT := c_payee.payee_amt;
            END LOOP;
            FOR c_gmpaid in (
                select settle
                from mis_clmgm_paid a
                where pay_no = c_paid.pay_no and corr_seq in (select max(aa.corr_seq) from mis_clmgm_paid aa 
                where aa.pay_no =a.pay_no group by aa.pay_no)
            ) LOOP
                V_PAIDBY := get_paidby('GM',c_gmpaid.settle);
            END LOOP;            
                            
            V_CLAIMPAIDSEQ :=1;
            
    --        V_CHEQUEDATE   :=null;
    --        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
    --        V_CHEQUENO     VARCHAR2(20);
    --        V_PAYEEAMT  NUMBER(15,2);
        END LOOP; -- C_paid
            
        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   

        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER ,V_RECORD_DATE);                        

--        INSERT INTO OIC_PAPH_PAYMENT
--        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
--        PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ) 
--        VALUES 
--        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
--        V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER);
--
--        INSERT INTO OIC_PAPH_PAYMENT_HIST
--        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
--        PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ) 
--        VALUES 
--        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
--        V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE);       
         
    END LOOP;
    COMMIT;
END get_GM_Claim_reserve;

PROCEDURE get_GM_Claim_out(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(10);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(5);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);
    
    v_cnt number(10):=0;
    v_runclmseq number(5);
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
BEGIN
    x_subject := 'run get_gm_claim_out @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim Out === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    
    FOR M1 in (
        select distinct  trunc(clm_date) clm_date ,trunc(a.close_date) close_date ,state_seq ,trunc(corr_date) corr_date ,prod_type ,'' pay_no ,
        a.clm_no ,pol_no ,pol_run ,a.recpt_seq ,reg_date ,clm_sts ,'' risk_code ,tot_paid ,tot_res
        from mis_clm_mas a ,clm_medical_res b 
        where  a.clm_no = b.clm_no and prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='GM') 
        and clm_sts in ('0','1','6')
        and clm_date between i_datefr and  i_dateto
        and (b.clm_no ,b.state_seq) in (select bb.clm_no ,max(bb.state_seq) from clm_medical_res bb where bb.clm_no =b.clm_no 
        and bb.corr_date <= i_asdate group by bb.clm_no)
        and b.corr_date <= i_asdate
        and channel <> '9'
--        and rownum<31
--        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'EC')
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
--        V_CLAIMSEQ :=1;
        V_CLAIMSEQ := 0;
        V_CLAIMGROUP := 'EC';

        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);

        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if  V_MAINCLASS is null then  
            V_MAINCLASS := '07'; 
            IF v_poltype = 'HI' THEN
                V_SUBCLASS := '01';
            ELSIF  v_poltype = 'HG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;        
        end if;
        
        
        FOR c_paid IN ( 
            select '' pay_no , fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,state_date ,nvl(res_amt,0) res_amt
            from clm_medical_res a
            where  clm_no =M1.CLM_NO
            and (clm_no ,state_seq) in (select clm_no ,max(aa.state_seq) from clm_medical_res aa where aa.clm_no =a.clm_no group by aa.clm_no)
            order by res_amt               
        )  LOOP
            -- ===== Path get prem code ====
            v_premcode := c_paid.bene_code;
            -- ===== End Path get prem code ====
            v_runclmseq := v_runclmseq+1;         
            V_CLAIMSEQ := V_CLAIMSEQ+1;
            V_CLAIMTYPE := P_OIC_PAPH_CLM.GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
            V_INSUREDSEQ := c_paid.fleet_seq;
            V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
            V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
            V_CLAIMSTATUS := '1';  -- Reserve claim        
            V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
            V_CLAIMCAUSE := c_paid.dis_code ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
            V_ICD10CODE1 := c_paid.dis_code;
            V_CLAIMAMT := c_paid.res_amt;
            V_TRANSACTIONSTATUS  :='N';
            V_REFERENCENUMBER    :=null;     
            V_DEDUCTIBLEAMT :=0;       
            --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('GM',c_paid.CLM_TYPE ,v_premcode) ;  --== mapping to table 5

            V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
            V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                                    
            V_ACCOUNTINGDATE := c_paid.state_date ;
                    
            get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date  ,M1.CLM_NO ,M1.PAY_NO ,V_INSUREDNAME ,V_INSUREDCITIZENID);
            
            if c_paid.clm_type = 'OPD' then
                V_TREATMENTTYPE := '1';
            elsif c_paid.clm_type = 'IPD' then
                V_TREATMENTTYPE := '2';
            else
                V_TREATMENTTYPE := '3';
            end if;

            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user )          ;
                    
--            FOR c_payee in (
--                select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
--                from clm_gm_payee a
--                where pay_no = c_paid.pay_no
--            ) LOOP
--                V_PAYEEAMT := c_payee.payee_amt;
--            END LOOP;
--            FOR c_gmpaid in (
--                select settle
--                from mis_clmgm_paid a
--                where pay_no = c_paid.pay_no and corr_seq in (select max(aa.corr_seq) from mis_clmgm_paid aa 
--                where aa.pay_no =a.pay_no group by aa.pay_no)
--            ) LOOP
--                V_PAIDBY := get_paidby('GM',c_gmpaid.settle);
--            END LOOP;            
                            
            V_CLAIMPAIDSEQ :=1;
            
    --        V_CHEQUEDATE   :=null;
    --        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
    --        V_CHEQUENO     VARCHAR2(20);
    --        V_PAYEEAMT  NUMBER(15,2);
        END LOOP; -- C_paid
            
        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   

        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        

--        INSERT INTO OIC_PAPH_PAYMENT
--        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
--        PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ) 
--        VALUES 
--        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
--        V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER);
--
--        INSERT INTO OIC_PAPH_PAYMENT_HIST
--        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
--        PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ) 
--        VALUES 
--        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
--        V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE);       
         
    END LOOP;
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
    email_log(x_subject ,x_message);    
END get_GM_Claim_out;

PROCEDURE get_GM_Claim_outpaid(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE  ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_ACCOUNTINGDATE2   DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(10);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);

    ACR_PAID_TYPE    VARCHAR2(1);
    ACR_PAID_DATE   DATE;
    ACR_BANK_CODE   VARCHAR2(20);
    ACR_BRANCH_CODE VARCHAR2(20);
    ACR_CHEQUE_NO   VARCHAR2(20);
        
    v_cnt number(10):=0;
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    v_runclmseq number(5);
    v_tmppayno  varchar2(20);
    
    v_chkrec    boolean;
    
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
BEGIN
    x_subject := 'run get_gm_claim_outpaid @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim Out+Paid === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    
    FOR M1 in (
        select distinct  trunc(clm_date) clm_date ,trunc(a.close_date) close_date ,trunc(corr_date) corr_date ,prod_type ,
        a.clm_no ,pol_no ,pol_run ,recpt_seq ,reg_date ,clm_sts ,'' risk_code ,tot_paid ,pay_no 
        from mis_clm_mas a ,clm_gm_paid b
        where  a.clm_no = b.clm_no and prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='GM') 
        and clm_sts ='2' 
        and clm_date between i_datefr and  i_dateto
        and close_date between i_datefr and  i_dateto
        and to_char(clm_date,'yyyymm') = to_char(close_date,'yyyymm')  
        and (b.pay_no ,b.corr_seq) in (select bb.pay_no ,max(bb.corr_seq) from clm_gm_paid bb where bb.pay_no = b.pay_no 
        and bb.corr_date <= i_asdate group by bb.pay_no) 
        and corr_date <= i_asdate     
        and channel <> '9'
--        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'P')
    )LOOP
        v_cnt := v_cnt+1;
        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no);
        V_CLAIMNUMBER := m1.clm_no;
        V_CLAIMSEQ :=0;
--        V_CLAIMGROUP := 'P';
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);
   
        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if  V_MAINCLASS is null then  
            V_MAINCLASS := '07'; 
            IF v_poltype = 'HI' THEN
                V_SUBCLASS := '01';
            ELSIF  v_poltype = 'HG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;        
        end if;
        
        v_chkrec := false;        
        FOR c_paid IN (
            select  pay_no, fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,date_paid pay_date ,nvl(pay_amt,0) pay_amt
            ,nvl(rec_amt,0) rec_amt
            from clm_gm_paid a
            where clm_no = M1.CLM_NO
            and corr_seq in (select max(aa.corr_seq) from clm_gm_paid aa where aa.pay_no =a.pay_no group by aa.pay_no)
--            and pay_amt = (select max(b.pay_amt) from clm_gm_paid b where b.pay_no =a.pay_no and b.corr_seq = a.corr_seq)
            order by pay_no 
        )  LOOP 
            if c_paid.rec_amt >0 then
                v_chkrec := true;   -- mark  when found Rec_Amt for insert ClaimGroup = S  
            end if;
                    
            -- ===== Path get prem code ====
            v_premcode := c_paid.bene_code;
            -- ===== End Path get prem code ====
                    
            v_runclmseq := v_runclmseq+1;
            v_tmppayno := c_paid.pay_no;
            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
            V_CLAIMTYPE := P_OIC_PAPH_CLM.GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
            V_INSUREDSEQ := c_paid.fleet_seq;
            V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
            V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
--            V_CLAIMSTATUS := '2';  -- close claim        
            V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
--            V_CLAIMCAUSE :='0000' ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
            V_CLAIMCAUSE := c_paid.dis_code ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
            V_ICD10CODE1 := c_paid.dis_code;
--            V_CLAIMAMT := m1.tot_paid;
            V_CLAIMAMT := c_paid.pay_amt;
            V_TRANSACTIONSTATUS  :='N';
            V_REFERENCENUMBER    :=null;     
            V_DEDUCTIBLEAMT :=0;       
            --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('GM',c_paid.CLM_TYPE ,v_premcode) ;  --== mapping to table 5            
            V_ACCOUNTINGDATE := M1.clm_date ;
--            V_ACCOUNTINGDATE2 := c_paid.pay_date ;
            V_ACCOUNTINGDATE2 := M1.close_date ;
            V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
            V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                                
            get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date ,M1.CLM_NO ,M1.PAY_NO ,V_INSUREDNAME ,V_INSUREDCITIZENID);
            
            if c_paid.clm_type = 'OPD' then
                V_TREATMENTTYPE := '1';
            elsif c_paid.clm_type = 'IPD' then
                V_TREATMENTTYPE := '2';
            else
                V_TREATMENTTYPE := '3';
            end if;  
                            
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'EC' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '1' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'EC' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '1' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            V_CLAIMSEQ := V_CLAIMSEQ+1; 
            
            INSERT INTO OIC_PAPH_CLAIM 
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE2 ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '2' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE2 ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '2' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user )          ;
                                
    --        V_CHEQUEDATE   :=null;
    --        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
    --        V_CHEQUENO     VARCHAR2(20);
    --        V_PAYEEAMT  NUMBER(15,2);
        END LOOP; -- C_paid

        IF v_chkrec THEN -- insert Master table for ClaimGroup = S
            FOR c_paid IN (
                select  pay_no, fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,date_paid pay_date ,nvl(pay_amt,0) pay_amt
                ,nvl(rec_amt,0) rec_amt 
                from clm_gm_paid a
                where clm_no = M1.CLM_NO
                and corr_seq in (select max(aa.corr_seq) from clm_gm_paid aa where aa.pay_no =a.pay_no group by aa.pay_no)
    --            and pay_amt = (select max(b.pay_amt) from clm_gm_paid b where b.pay_no =a.pay_no and b.corr_seq = a.corr_seq)
                and nvl(rec_amt,0) > 0
                order by pay_no 
            )  LOOP 
                
                -- ===== Path get prem code ====
                v_premcode := c_paid.bene_code;
                -- ===== End Path get prem code ====
                        
                v_runclmseq := v_runclmseq+1;
                v_tmppayno := c_paid.pay_no;
                V_CLAIMSEQ := V_CLAIMSEQ+1 ;
                V_CLAIMTYPE := P_OIC_PAPH_CLM.GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
                V_INSUREDSEQ := c_paid.fleet_seq;
                V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
                V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
                V_CLAIMSTATUS := '2';  -- close claim        
                V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
    --            V_CLAIMCAUSE :='0000' ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
                V_CLAIMCAUSE := c_paid.dis_code ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
                V_ICD10CODE1 := c_paid.dis_code;
    --            V_CLAIMAMT := m1.tot_paid;
                V_CLAIMAMT := c_paid.rec_amt;
                V_TRANSACTIONSTATUS  :='N';
                V_REFERENCENUMBER    :=null;     
                V_DEDUCTIBLEAMT :=0;       
                --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('GM',c_paid.CLM_TYPE ,v_premcode) ;  --== mapping to table 5            
                V_ACCOUNTINGDATE := M1.clm_date ;
    --            V_ACCOUNTINGDATE2 := c_paid.pay_date ;
                V_ACCOUNTINGDATE2 := M1.close_date ;
                V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                                    
                get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date  ,M1.CLM_NO ,M1.PAY_NO,V_INSUREDNAME ,V_INSUREDCITIZENID);
                
                if c_paid.clm_type = 'OPD' then
                    V_TREATMENTTYPE := '1';
                elsif c_paid.clm_type = 'IPD' then
                    V_TREATMENTTYPE := '2';
                else
                    V_TREATMENTTYPE := '3';
                end if;  
                                
                INSERT INTO OIC_PAPH_CLAIM
                ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                PROCODURECODE1 ,
                CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                VALUES 
                (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'S' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                V_PROCODURECODE1 ,
                V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

                INSERT INTO OIC_PAPH_CLAIM_HIST
                ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                PROCODURECODE1 ,
                CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                VALUES 
                (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'S' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                V_PROCODURECODE1 ,
                V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;
                                    
            END LOOP; -- C_paid        
        END IF;
                    
--        if M1.clm_no = '201301008000002' then    
--        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
--        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
--        end if;
        
        
        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        

        begin
            select pay_date into V_CHEQUEDATE
            from mis_clmgm_paid a
            where pay_no = m1.pay_no
            and (a.pay_no,a.corr_seq) in (select aa.pay_no ,max(aa.corr_seq) from mis_clmgm_paid aa where aa.pay_no = a.pay_no group by aa.pay_no );

            if V_CHEQUEDATE is null then
                V_CHEQUEDATE := M1.close_date;
            end if; 
        exception
            when no_data_found then
                V_CHEQUEDATE := M1.close_date;
            when others then
                V_CHEQUEDATE := M1.close_date;
        end;   
        
        FOR c_payee in (
            select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
            from clm_gm_payee a
            where pay_no = V_TMPPAYNO and payee_code is not null 
        ) LOOP
            V_PAYEEAMT := c_payee.payee_amt;
            V_PAIDBY := get_paidby('GM',c_payee.settle);       
            V_CLAIMPAIDSEQ :=c_payee.pay_seq;
            V_CHEQUENO := null;
            
            if V_PAIDBY = 'K' then
                account.p_acc_acr.get_paid_info(M1.pay_no,'0',M1.prod_type,c_payee.payee_code,c_payee.settle,
                                              ACR_PAID_TYPE, ACR_PAID_DATE, ACR_BANK_CODE, ACR_BRANCH_CODE, ACR_CHEQUE_NO);
                V_CHEQUENO := ACR_CHEQUE_NO;                              
                IF V_CHEQUENO is null THEN
                    V_PAIDBY := 'O' ;
                END IF;               
            elsif V_PAIDBY = 'T' then
                V_CHEQUENO := null;
            end if;    

            if V_PAYEEAMT = 0 then
                V_PAYEEAMT := M1.tot_paid;    
            end if;
                             
            INSERT INTO OIC_PAPH_PAYMENT
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

            INSERT INTO OIC_PAPH_PAYMENT_HIST
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);   
                    
        END LOOP;  -- payee 
            
     
    END LOOP;  -- clm_mas
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
    email_log(x_subject ,x_message);    
END get_GM_Claim_outpaid;


PROCEDURE get_GM_Claim_paid(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_ACCOUNTINGDATE2   DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(10);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);
    V_TRANSACTIONSTATUS2    VARCHAR2(1);  

    ACR_PAID_TYPE    VARCHAR2(1);
    ACR_PAID_DATE   DATE;
    ACR_BANK_CODE   VARCHAR2(20);
    ACR_BRANCH_CODE VARCHAR2(20);
    ACR_CHEQUE_NO   VARCHAR2(20);
        
    v_cnt number(10):=0;
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    v_runclmseq number(5);
    v_tmppayno  varchar2(20);
    
    v_chkrec    boolean;
    
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
BEGIN
    x_subject := 'run get_gm_claim_paid @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim Paid === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    
    FOR M1 in (
        select distinct  trunc(clm_date) clm_date ,trunc(a.close_date) close_date ,trunc(corr_date) corr_date ,prod_type ,
        a.clm_no ,pol_no ,pol_run ,recpt_seq ,reg_date ,clm_sts ,'' risk_code ,tot_paid ,pay_no
        from mis_clm_mas a ,clm_gm_paid b
        where  a.clm_no = b.clm_no and prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='GM') 
        and clm_sts ='2' 
--        and clm_date between i_datefr and  i_dateto
        and close_date between i_datefr and  i_dateto
        and to_char(clm_date,'yyyymm') < to_char(close_date,'yyyymm')  
        and (b.pay_no ,b.corr_seq) in (select bb.pay_no ,max(bb.corr_seq) from clm_gm_paid bb where bb.pay_no = b.pay_no 
        and bb.corr_date <= i_asdate group by bb.pay_no) 
        and corr_date <= i_asdate     
        and channel <> '9'  
--        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'P')
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        V_CLAIMSEQ :=0;
--        V_CLAIMGROUP := 'P';
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);
   
        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if  V_MAINCLASS is null then  
            V_MAINCLASS := '07'; 
            IF v_poltype = 'HI' THEN
                V_SUBCLASS := '01';
            ELSIF  v_poltype = 'HG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;        
        end if;
        
        v_chkrec := false;        
        FOR c_paid IN (
            select  pay_no, fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,date_paid pay_date ,nvl(pay_amt,0) pay_amt
            ,nvl(rec_amt,0) rec_amt 
            from clm_gm_paid a
            where clm_no = M1.CLM_NO
            and corr_seq in (select max(aa.corr_seq) from clm_gm_paid aa where aa.pay_no =a.pay_no group by aa.pay_no)
--            and pay_amt = (select max(b.pay_amt) from clm_gm_paid b where b.pay_no =a.pay_no and b.corr_seq = a.corr_seq)
            order by pay_no 
        )  LOOP 
            if c_paid.rec_amt >0 then
                v_chkrec := true;   -- mark  when found Rec_Amt for insert ClaimGroup = S  
            end if;
            
            -- ===== Path get prem code ====
            v_premcode := c_paid.bene_code;
            -- ===== End Path get prem code ====
                    
            v_runclmseq := v_runclmseq+1;
            v_tmppayno := c_paid.pay_no;
            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
            V_CLAIMTYPE := P_OIC_PAPH_CLM.GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
            V_INSUREDSEQ := c_paid.fleet_seq;
            V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
            V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
            V_CLAIMSTATUS := '2';  -- close claim        
            V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
--            V_CLAIMCAUSE :='0000' ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
            V_CLAIMCAUSE := c_paid.dis_code ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
            V_ICD10CODE1 := c_paid.dis_code;
--            V_CLAIMAMT := m1.tot_paid;
            V_CLAIMAMT := c_paid.pay_amt;
            V_TRANSACTIONSTATUS  :='N';
            V_REFERENCENUMBER    :=null;     
            V_DEDUCTIBLEAMT :=0;       
            --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('GM',c_paid.CLM_TYPE ,v_premcode) ;  --== mapping to table 5            
            V_ACCOUNTINGDATE := M1.clm_date ;
--            V_ACCOUNTINGDATE2 := c_paid.pay_date ;
            V_ACCOUNTINGDATE2 := M1.close_date ;
            V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
            V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                                
            get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date  ,M1.CLM_NO ,M1.PAY_NO,V_INSUREDNAME ,V_INSUREDCITIZENID);
            
            if c_paid.clm_type = 'OPD' then
                V_TREATMENTTYPE := '1';
            elsif c_paid.clm_type = 'IPD' then
                V_TREATMENTTYPE := '2';
            else
                V_TREATMENTTYPE := '3';
            end if;  
                            
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;
                                
    --        V_CHEQUEDATE   :=null;
    --        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
    --        V_CHEQUENO     VARCHAR2(20);
    --        V_PAYEEAMT  NUMBER(15,2);
        END LOOP; -- C_paid
        
        IF v_chkrec THEN -- insert Master table for ClaimGroup = S
            FOR c_paid IN (
                select  pay_no, fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,date_paid pay_date ,nvl(pay_amt,0) pay_amt
                ,nvl(rec_amt,0) rec_amt 
                from clm_gm_paid a
                where clm_no = M1.CLM_NO
                and corr_seq in (select max(aa.corr_seq) from clm_gm_paid aa where aa.pay_no =a.pay_no group by aa.pay_no)
    --            and pay_amt = (select max(b.pay_amt) from clm_gm_paid b where b.pay_no =a.pay_no and b.corr_seq = a.corr_seq)
                and nvl(rec_amt,0) > 0
                order by pay_no 
            )  LOOP 
                
                -- ===== Path get prem code ====
                v_premcode := c_paid.bene_code;
                -- ===== End Path get prem code ====
                        
                v_runclmseq := v_runclmseq+1;
                v_tmppayno := c_paid.pay_no;
                V_CLAIMSEQ := V_CLAIMSEQ+1 ;
                V_CLAIMTYPE := P_OIC_PAPH_CLM.GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
                V_INSUREDSEQ := c_paid.fleet_seq;
                V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
                V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
                V_CLAIMSTATUS := '2';  -- close claim        
                V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
    --            V_CLAIMCAUSE :='0000' ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
                V_CLAIMCAUSE := c_paid.dis_code ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
                V_ICD10CODE1 := c_paid.dis_code;
    --            V_CLAIMAMT := m1.tot_paid;
                V_CLAIMAMT := c_paid.rec_amt;
                V_TRANSACTIONSTATUS  :='N';
                V_REFERENCENUMBER    :=null;     
                V_DEDUCTIBLEAMT :=0;       
                --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('GM',c_paid.CLM_TYPE ,v_premcode) ;  --== mapping to table 5            
                V_ACCOUNTINGDATE := M1.clm_date ;
    --            V_ACCOUNTINGDATE2 := c_paid.pay_date ;
                V_ACCOUNTINGDATE2 := M1.close_date ;
                V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                                    
                get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date  ,M1.CLM_NO ,M1.PAY_NO,V_INSUREDNAME ,V_INSUREDCITIZENID);
                
                if c_paid.clm_type = 'OPD' then
                    V_TREATMENTTYPE := '1';
                elsif c_paid.clm_type = 'IPD' then
                    V_TREATMENTTYPE := '2';
                else
                    V_TREATMENTTYPE := '3';
                end if;  
                                
                INSERT INTO OIC_PAPH_CLAIM
                ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                PROCODURECODE1 ,
                CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                VALUES 
                (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'S' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                V_PROCODURECODE1 ,
                V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

                INSERT INTO OIC_PAPH_CLAIM_HIST
                ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                PROCODURECODE1 ,
                CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                VALUES 
                (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'S' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                V_PROCODURECODE1 ,
                V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;
                                    
            END LOOP; -- C_paid        
        END IF;
            
--        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
--        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
        
        IF hasINS_data(V_CLAIMNUMBER) THEN
            V_TRANSACTIONSTATUS2 := 'U';        
        ELSE    
            V_TRANSACTIONSTATUS2 := 'N';        
        END IF;
        
        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        

        begin
            select pay_date into V_CHEQUEDATE
            from mis_clmgm_paid a
            where pay_no = m1.pay_no
            and (a.pay_no,a.corr_seq) in (select aa.pay_no ,max(aa.corr_seq) from mis_clmgm_paid aa where aa.pay_no = a.pay_no group by aa.pay_no );

            if V_CHEQUEDATE is null then
                V_CHEQUEDATE := M1.close_date;
            end if; 
        exception
            when no_data_found then
                V_CHEQUEDATE := M1.close_date;
            when others then
                V_CHEQUEDATE := M1.close_date;
        end;    
        
        FOR c_payee in (
            select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
            from clm_gm_payee a
            where pay_no = V_TMPPAYNO and payee_code is not null 
        ) LOOP
            V_PAYEEAMT := c_payee.payee_amt;
            V_PAIDBY := get_paidby('GM',c_payee.settle);       
            V_CLAIMPAIDSEQ :=c_payee.pay_seq;
            V_CHEQUENO := null;
            
            if V_PAIDBY = 'K' then
                account.p_acc_acr.get_paid_info(M1.pay_no,'0',M1.prod_type,c_payee.payee_code,c_payee.settle,
                                              ACR_PAID_TYPE, ACR_PAID_DATE, ACR_BANK_CODE, ACR_BRANCH_CODE, ACR_CHEQUE_NO);
                V_CHEQUENO := ACR_CHEQUE_NO;                              
                IF V_CHEQUENO is null THEN
                    V_PAIDBY := 'O' ;
                END IF;               
            elsif V_PAIDBY = 'T' then
                V_CHEQUENO := null;
            end if;          

            if V_PAYEEAMT = 0 then
                V_PAYEEAMT := M1.tot_paid;    
            end if;
                                         
            INSERT INTO OIC_PAPH_PAYMENT
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

            INSERT INTO OIC_PAPH_PAYMENT_HIST
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);   
                    
        END LOOP;  -- payee 
            
     
    END LOOP;  -- clm_mas
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
    email_log(x_subject ,x_message);    
END get_GM_Claim_paid;

PROCEDURE get_GM_Claim_outcwp(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_ACCOUNTINGDATE2   DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(10);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);
    
    v_cnt number(10):=0;
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    v_runclmseq number(5);
    v_tmppayno  varchar2(20);
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
BEGIN
    x_subject := 'run get_gm_claim_outcwp @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim Out+Cwp === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    
    FOR M1 in (
        select distinct  trunc(clm_date) clm_date ,trunc(a.close_date) close_date ,state_seq ,trunc(corr_date) corr_date ,prod_type ,'' pay_no ,
        a.clm_no ,pol_no ,pol_run ,a.recpt_seq ,reg_date ,clm_sts ,'' risk_code ,tot_paid ,tot_res
        from mis_clm_mas a ,clm_medical_res b 
        where  a.clm_no = b.clm_no and prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='GM') 
        and clm_sts in ('3')
        and clm_date  between i_datefr and  i_dateto
        and a.close_date between i_datefr and  i_dateto
        and to_char(clm_date,'yyyymm') = to_char(a.close_date,'yyyymm')
        and (b.clm_no ,b.state_seq) in (select bb.clm_no ,max(bb.state_seq) from clm_medical_res bb where bb.clm_no =b.clm_no 
        and bb.corr_date <= i_asdate group by bb.clm_no)
        and b.corr_date <= i_asdate    
        and nvl(a.tot_res ,0) > 0 
        and channel <> '9'
--        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'P')
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        V_CLAIMSEQ :=0;
--        V_CLAIMGROUP := 'P';
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);
   
        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if  V_MAINCLASS is null then  
            V_MAINCLASS := '07'; 
            IF v_poltype = 'HI' THEN
                V_SUBCLASS := '01';
            ELSIF  v_poltype = 'HG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;        
        end if;
                
        FOR c_paid IN (
            select '' pay_no , fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,state_date pay_date,nvl(res_amt,0) pay_amt
            from clm_medical_res a
            where  clm_no =M1.CLM_NO
            and (clm_no ,state_seq) in (select clm_no ,max(aa.state_seq) from clm_medical_res aa where aa.clm_no =a.clm_no group by aa.clm_no)
            order by res_amt     
        )  LOOP 
            -- ===== Path get prem code ====
            v_premcode := c_paid.bene_code;
            -- ===== End Path get prem code ====
                    
            v_runclmseq := v_runclmseq+1;
            v_tmppayno := c_paid.pay_no;
            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
            
            V_CLAIMTYPE := P_OIC_PAPH_CLM.GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
            V_INSUREDSEQ := c_paid.fleet_seq;
            V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
            V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
--            V_CLAIMSTATUS := '2';  -- close claim        
            V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
--            V_CLAIMCAUSE :='0000' ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
            V_CLAIMCAUSE := c_paid.dis_code ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
            V_ICD10CODE1 := c_paid.dis_code;
--            V_CLAIMAMT := m1.tot_paid;
            V_CLAIMAMT := c_paid.pay_amt;
            V_TRANSACTIONSTATUS  :='N';
            V_REFERENCENUMBER    :=null;     
            V_DEDUCTIBLEAMT :=0;       
            --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('GM',c_paid.CLM_TYPE ,v_premcode) ;  --== mapping to table 5            
            V_ACCOUNTINGDATE := M1.clm_date ;
            V_ACCOUNTINGDATE2 := c_paid.pay_date ;
            V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
            V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                                
            get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date  ,M1.CLM_NO ,M1.PAY_NO,V_INSUREDNAME ,V_INSUREDCITIZENID);
            
            if c_paid.clm_type = 'OPD' then
                V_TREATMENTTYPE := '1';
            elsif c_paid.clm_type = 'IPD' then
                V_TREATMENTTYPE := '2';
            else
                V_TREATMENTTYPE := '3';
            end if;  
                            
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'EC' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '1' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'EC' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '1' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user )          ;
            
            V_CLAIMSEQ := V_CLAIMSEQ+1;
            
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE2 ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '2' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            0 , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE2 ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , '2' , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            0 , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE, i_datefr, i_dateto , i_asdate ,v_record_date ,i_user )          ;
                                
    --        V_CHEQUEDATE   :=null;
    --        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
    --        V_CHEQUENO     VARCHAR2(20);
    --        V_PAYEEAMT  NUMBER(15,2);
        END LOOP; -- C_paid
            
--        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
--        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
        

        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        
            
     
    END LOOP;  -- clm_mas
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
    email_log(x_subject ,x_message);    
END get_GM_Claim_outcwp;


PROCEDURE get_GM_Claim_cwp(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_ACCOUNTINGDATE2   DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(10);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);
    V_TRANSACTIONSTATUS2    VARCHAR2(1);  
    
    v_cnt number(10):=0;
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    v_runclmseq number(5);
    v_tmppayno  varchar2(20);
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
BEGIN
    x_subject := 'run get_gm_claim_cwp @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim Cwp === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    
    FOR M1 in (
        select distinct trunc(clm_date) clm_date ,trunc(a.close_date) close_date ,state_seq ,trunc(corr_date) corr_date ,prod_type ,'' pay_no ,
        a.clm_no ,pol_no ,pol_run ,a.recpt_seq ,reg_date ,clm_sts ,'' risk_code ,tot_paid ,tot_res
        from mis_clm_mas a ,clm_medical_res b 
        where  a.clm_no = b.clm_no and prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='GM') 
        and clm_sts in ('3')
--        and clm_date  between i_datefr and  i_dateto
        and a.close_date between i_datefr and  i_dateto
        and to_char(clm_date,'yyyymm') < to_char(a.close_date,'yyyymm')
        and (b.clm_no ,b.state_seq) in (select bb.clm_no ,max(bb.state_seq) from clm_medical_res bb where bb.clm_no =b.clm_no 
        and bb.corr_date <= i_asdate group by bb.clm_no)
        and b.corr_date <= i_asdate     
        and nvl(a.tot_res ,0) > 0 
        and channel <> '9'
--        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'P')
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        V_CLAIMSEQ :=0;
--        V_CLAIMGROUP := 'P';
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);
   
        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if  V_MAINCLASS is null then  
            V_MAINCLASS := '07'; 
            IF v_poltype = 'HI' THEN
                V_SUBCLASS := '01';
            ELSIF  v_poltype = 'HG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;        
        end if;
                
        FOR c_paid IN (
            select '' pay_no , fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,state_date pay_date, nvl(res_amt,0) pay_amt
            from clm_medical_res a
            where  clm_no =M1.CLM_NO
            and (clm_no ,state_seq) in (select clm_no ,max(aa.state_seq) from clm_medical_res aa where aa.clm_no =a.clm_no group by aa.clm_no)
            order by res_amt     
        )  LOOP 
            -- ===== Path get prem code ====
            v_premcode := c_paid.bene_code;
            -- ===== End Path get prem code ====
                    
            v_runclmseq := v_runclmseq+1;
            v_tmppayno := c_paid.pay_no;
            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
            
            V_CLAIMTYPE := P_OIC_PAPH_CLM.GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
            V_INSUREDSEQ := c_paid.fleet_seq;
            V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
            V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
            V_CLAIMSTATUS := '2';  -- close claim        
            V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
--            V_CLAIMCAUSE :='0000' ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
            V_CLAIMCAUSE := c_paid.dis_code ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
            V_ICD10CODE1 := c_paid.dis_code;
--            V_CLAIMAMT := m1.tot_paid;
            V_CLAIMAMT := c_paid.pay_amt;
            V_TRANSACTIONSTATUS  :='N';
            V_REFERENCENUMBER    :=null;     
            V_DEDUCTIBLEAMT :=0;       
            --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('GM',c_paid.CLM_TYPE ,v_premcode) ;  --== mapping to table 5            
            V_ACCOUNTINGDATE := M1.clm_date ;
            V_ACCOUNTINGDATE2 := c_paid.pay_date ;
            V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
            V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
            ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                                
            get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date ,M1.CLM_NO ,M1.PAY_NO ,V_INSUREDNAME ,V_INSUREDCITIZENID);
            
            if c_paid.clm_type = 'OPD' then
                V_TREATMENTTYPE := '1';
            elsif c_paid.clm_type = 'IPD' then
                V_TREATMENTTYPE := '2';
            else
                V_TREATMENTTYPE := '3';
            end if;  
                            

            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            0 , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE ,V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            0 , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

        END LOOP; -- C_paid

        IF hasINS_data(V_CLAIMNUMBER) THEN
            V_TRANSACTIONSTATUS2 := 'U';        
        ELSE    
            V_TRANSACTIONSTATUS2 := 'N';        
        END IF;
                    
        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
        

        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        
            
     
    END LOOP;  -- clm_mas
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
    email_log(x_subject ,x_message);    
END get_GM_Claim_cwp;

PROCEDURE get_PA_Claim_close(i_datefr IN DATE ,i_dateto IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(2);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);

    v_runclmseq number(5);        
    v_cnt number(10):=0;
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
BEGIN
    FOR M1 in (
        select a.clm_no ,pay_no ,fleet_seq ,recpt_seq ,pol_no ,pol_run ,reg_date ,a.loss_date ,clm_sts , dis_code ,risk_code ,tot_paid
        ,decode(ipd_flag,'O','OPD','I','IPD','DAY') CLM_TYPE
        from mis_clm_mas a ,mis_cpa_paid b
        where a.clm_no = b.clm_no and prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='PA') 
        and clm_sts ='2' 
        and close_date between i_datefr and i_dateto
        and (b.pay_no ,b.corr_seq) in (select bb.pay_no ,max(bb.corr_seq) from mis_cpa_paid bb where bb.pay_no =b.pay_no group by bb.pay_no)
        --and a.clm_no ='201301002015766'
        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'P')
--        and rownum<50
        order by a.clm_no
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        v_runclmseq := 0;
        V_CLAIMGROUP := 'P';
        V_MAINCLASS := '06'; 
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);
   
        IF v_poltype = 'PI' THEN
            V_SUBCLASS := '01';
            IF nc_health_package.is_unname_policy(m1.pol_no ,m1.pol_run) THEN
                V_SUBCLASS := '03';
            END IF;
        ELSIF  v_poltype = 'PG' THEN
            V_SUBCLASS := '02';
        ELSE
            V_SUBCLASS := '99';
        END IF;
        
                
        V_CLAIMTYPE := GET_CLMTYPE('PA',m1.CLM_TYPE ,v_premcode);
        V_INSUREDSEQ := nvl(M1.fleet_seq,0);
        V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
        V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
        V_LOSSDATE :=  m1.loss_date; --to_date(m1.loss_date,'yyyymmdd');
        V_CLAIMSTATUS := '2';  -- close claim
        V_CLAIMCAUSE :='1110' ; -- Accident
        V_ICD10CODE1 := m1.dis_code;
        V_CLAIMAMT := m1.tot_paid;
        V_TRANSACTIONSTATUS  :='N';
        V_REFERENCENUMBER    :=null;     
        V_DEDUCTIBLEAMT :=0;       

        begin
            select pay_date into V_ACCOUNTINGDATE
            from mis_clm_paid a
            where pay_no = m1.pay_no and
            a.corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no group by aa.pay_no);
        exception
            when no_data_found then
                V_ACCOUNTINGDATE := null;
            when others then
                V_ACCOUNTINGDATE := null;
        end;    
                
        get_citizen('PA' ,m1.pol_no ,m1.pol_run ,m1.fleet_seq ,nvl(m1.recpt_seq,1)  ,'' ,V_INSUREDNAME ,V_INSUREDCITIZENID);
        
        if m1.clm_type = 'OPD' then
            V_TREATMENTTYPE := '1';
        elsif m1.clm_type = 'IPD' then
            V_TREATMENTTYPE := '2';
        else
            V_TREATMENTTYPE := '3';
        end if;
                
        -- ===== Path get prem code ====
        nc_health_paid.get_pa_reserve(M1.PAY_NO,
                                        v_sid,
                                        p1_rst);          
                
        if p1_rst is null then
        FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
        from NC_H_HISTORY_TMP
        where sid = v_sid and rownum=1)
        LOOP    
            v_runclmseq := v_runclmseq+1;
            V_CLAIMSEQ := v_runclmseq ;
            v_premcode := p1.prem_code;    
            V_CLAIMAMT := p1.amount;  

            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , '' ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE )          ;
                    
        END LOOP;      
        end if;
        NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
        -- ===== End Path get prem code ====

        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER ,V_RECORD_DATE);                        

        
        FOR c_payee in (  -- Get Payee
            select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
            from mis_clm_payee a
            where pay_no = M1.pay_no
        ) LOOP
            V_PAYEEAMT := c_payee.payee_amt;
            V_PAIDBY := get_paidby('PA',c_payee.settle);
            V_CLAIMPAIDSEQ :=c_payee.pay_seq ;
            
            INSERT INTO OIC_PAPH_PAYMENT
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER);

            INSERT INTO OIC_PAPH_PAYMENT_HIST
            ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
            PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ) 
            VALUES 
            (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
            V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE);              
        END LOOP;
        
--        V_CHEQUEDATE   :=null;
--        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
--        V_CHEQUENO     VARCHAR2(20);
--        V_PAYEEAMT  NUMBER(15,2);
            
        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
             
    END LOOP;
    COMMIT;
END get_PA_Claim_close;

PROCEDURE get_PA_Claim_reserve(i_datefr IN DATE ,i_dateto IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(2);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);
    
    v_cnt number(10):=0;
    v_runclmseq number(5);    
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
BEGIN
    FOR M1 in (
        select a.clm_no ,'' pay_no ,fleet_seq ,recpt_seq ,pol_no ,pol_run ,reg_date ,a.loss_date ,clm_sts , dis_code ,risk_code ,tot_res
        ,decode(ipd_flag,'O','OPD','I','IPD','DAY') CLM_TYPE
        from mis_clm_mas a ,mis_cpa_res b
        where a.clm_no = b.clm_no and prod_grp = '0' 
        and prod_type in (select prod_type from clm_grp_prod where sysid='PA') 
        and clm_sts in ('0','1','6')
        and clm_date between i_datefr and  i_dateto
        and (b.clm_no ,b.revise_seq) in (select bb.clm_no ,max(bb.revise_seq) from mis_cpa_res bb where bb.clm_no =b.clm_no group by bb.clm_no)
        --and a.clm_no ='201301002015766'
        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'EC')
--        and rownum < 50
        order by a.clm_no
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        v_runclmseq := 0;
        V_CLAIMGROUP := 'EC'; 
        V_MAINCLASS := '06'; 
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype); 
   
        IF v_poltype = 'PI' THEN
            V_SUBCLASS := '01';
            IF nc_health_package.is_unname_policy(m1.pol_no ,m1.pol_run) THEN
                V_SUBCLASS := '03';
            END IF;
        ELSIF  v_poltype = 'PG' THEN
            V_SUBCLASS := '02';
        ELSE
            V_SUBCLASS := '99';
        END IF;
        
--        V_CLAIMSEQ := 1;
        V_CLAIMTYPE := GET_CLMTYPE('PA',m1.CLM_TYPE ,v_premcode);
        V_INSUREDSEQ := nvl(M1.fleet_seq,0);
        V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
        V_NOTIFYDATE := m1.reg_date; --to_date(m1.reg_date,'yyyymmdd');
        V_LOSSDATE :=  m1.loss_date; --to_date(m1.loss_date,'yyyymmdd');
        V_CLAIMSTATUS := '1';  --  open claim
        V_CLAIMCAUSE :='1110' ; -- Accident
        V_ICD10CODE1 := m1.dis_code;
--        V_CLAIMAMT := m1.tot_res;
        V_TRANSACTIONSTATUS  :='N';
        V_REFERENCENUMBER    :=null;     
        V_DEDUCTIBLEAMT :=0;       

--        begin
--            select pay_date into V_ACCOUNTINGDATE
--            from mis_clm_paid a
--            where pay_no = m1.pay_no and
--            a.corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no group by aa.pay_no);
--        exception
--            when no_data_found then
--                V_ACCOUNTINGDATE := null;
--            when others then
--                V_ACCOUNTINGDATE := null;
--        end;    
                
        get_citizen('PA' ,m1.pol_no ,m1.pol_run ,m1.fleet_seq ,nvl(m1.recpt_seq,1)  ,'' ,V_INSUREDNAME ,V_INSUREDCITIZENID);
        
        if m1.clm_type = 'OPD' then
            V_TREATMENTTYPE := '1';
        elsif m1.clm_type = 'IPD' then
            V_TREATMENTTYPE := '2';
        else
            V_TREATMENTTYPE := '3';
        end if;
        
--        FOR c_payee in (
--            select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
--            from mis_clm_payee a
--            where pay_no = M1.pay_no
--        ) LOOP
--            V_PAYEEAMT := c_payee.payee_amt;
--            V_PAIDBY := get_paidby('PA',c_payee.settle);
--        END LOOP;
--        V_CLAIMPAIDSEQ :=1;
                
        -- ===== Path get prem code ====
        GET_PA_RESERVE(M1.CLM_NO,
                                        v_sid,
                                        p1_rst);          
                
        if p1_rst is null then
        FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
        from NC_H_HISTORY_TMP
        where sid = v_sid )
        LOOP    
            v_runclmseq := v_runclmseq+1;
            V_CLAIMSEQ := v_runclmseq ;
            v_premcode := p1.prem_code;    
            V_CLAIMAMT := p1.amount;
            
            INSERT INTO OIC_PAPH_CLAIM
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , '' ,v_record_date ,i_user)          ;

            INSERT INTO OIC_PAPH_CLAIM_HIST
            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
            PROCODURECODE1 ,
            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ) 
            VALUES 
            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
            V_PROCODURECODE1 ,
            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE )          ;

        END LOOP;      -- loop get Reserved
        end if;
        NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
        -- ===== End Path get prem code ====
        
--        V_CHEQUEDATE   :=null;
--        V_PAIDBY := get_paidby('PA',); --รอปอเฮง เพิ่มการส่งกลับ ChequeNo
--        V_CHEQUENO     VARCHAR2(20);
--        V_PAYEEAMT  NUMBER(15,2);
            
        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
        

        INSERT INTO OIC_PAPH_INS_CLAIM
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER);

        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ) 
        VALUES 
        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER ,V_RECORD_DATE);                        

--        INSERT INTO OIC_PAPH_PAYMENT
--        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
--        PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ) 
--        VALUES 
--        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
--        V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER);
--
--        INSERT INTO OIC_PAPH_PAYMENT_HIST
--        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
--        PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ) 
--        VALUES 
--        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
--        V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE);        
    END LOOP;
    COMMIT;
END get_PA_Claim_reserve;
  
FUNCTION get_ClmType(i_grp IN VARCHAR2 ,i_opd IN VARCHAR2 ,i_premcode IN VARCHAR2) RETURN VARCHAR2 IS
    v_return varchar2(10);
    v_premdesc  varchar2(500);
BEGIN

    IF i_grp ='PA' THEN
        IF NC_HEALTH_PACKAGE.IS_CHECK_ACCUM(i_premcode) THEN -- ผลประโยชน์แบบต่อครั้ง
            if i_opd = 'O' then
                v_return := '19'; -- ค่ารักษาผู้ป่วยนอกจาก อบห.
            else
                v_return := '04'; -- ค่ารักษาพยาบาล
                v_premdesc := nc_health_package.GET_PREMCODE_DESCR(i_premcode,'T');
                if INSTR(v_premdesc ,'กระดูก') > 0 then
                    v_return := '05'; -- ค่ารักษาจากอาการกระดูก
                end if;
            end if;
        ELSIF NC_HEALTH_PACKAGE.IS_CHECK_PERTIME(i_premcode) THEN -- ผลประโยชน์แบบชดเชย
            v_return := '06'; -- เงินชดเชยระหว่างรักษาตัว
        ELSIF NC_HEALTH_PACKAGE.IS_CHECK_TOTLOSS(i_premcode) THEN -- ผลประโยชน์ทุนหลัก
            v_return := '01';
        END IF;
    ELSE
        v_return := '04';   -- ค่ารักษาพยาบาล
    END IF;
    
    return v_return;
END get_ClmType;

FUNCTION get_PaidBy(i_grp IN VARCHAR2 ,i_paidtype IN VARCHAR2) RETURN VARCHAR2 IS
    v_return    VARCHAR2(2);
BEGIN
    IF i_grp in ('PA','GM') THEN
        if i_paidtype = '1' then --Cash
            v_return := 'C';   
        elsif i_paidtype = '2' then  --Cheque
            v_return := 'K';   
        elsif i_paidtype = '3' then    -- BankTansfer
            v_return := 'T';   
        else    -- Others
            v_return := 'O';   
        end if;
    ELSE
        v_return :=  'O';
    END IF;
    return v_return;
END get_PaidBy;  
  
PROCEDURE get_Citizen(i_grp IN VARCHAR2 ,i_polno IN VARCHAR2 ,i_polrun IN NUMBER ,i_fleet IN NUMBER ,i_recpt IN NUMBER ,i_lossdate IN DATE 
,o_insname OUT  VARCHAR2 ,o_id OUT VARCHAR2) IS

BEGIN
    IF i_grp ='PA' THEN
        begin
            select title||' '||name||' '||surname ,id  into 
            o_insname ,o_id
            from mis_pa_prem
            where pol_no = i_polno and pol_run = i_polrun
            and fleet_seq = i_fleet and recpt_seq=i_recpt
            and rownum=1;
        exception
            when no_data_found then
                o_insname := null;
                o_id  := null;
            when others then
                o_insname := null;
                o_id  := null;
        end;    

    ELSE
--        dbms_output.put_line('polno: '||i_polno||i_polrun||' fleet:'||i_fleet);
        begin
            select title||' '||name , id_no   into 
            o_insname ,o_id
            from pa_medical_det
            where pol_no = i_polno and pol_run = i_polrun 
            and fleet_seq = i_fleet 
--            and i_lossdate between fr_date and to_date
            and rownum=1;
        exception
            when no_data_found then
                o_insname := null;
                o_id  := null;
            when others then
                o_insname := null;
                o_id  := null;
        end;        
    END IF;

END get_Citizen;

PROCEDURE get_Citizen(i_grp IN VARCHAR2 ,i_polno IN VARCHAR2 ,i_polrun IN NUMBER ,i_fleet IN NUMBER ,i_recpt IN NUMBER ,i_lossdate IN DATE 
,i_clmno IN VARCHAR2, i_payno IN VARCHAR2 ,o_insname OUT  VARCHAR2 ,o_id OUT VARCHAR2) IS

BEGIN

    IF i_grp ='PA' THEN
        begin
            select title||' '||name||' '||surname ,id  into 
            o_insname ,o_id
            from mis_pa_prem
            where pol_no = i_polno and pol_run = i_polrun
            and fleet_seq = i_fleet and recpt_seq=i_recpt
            and rownum=1;
        exception
            when no_data_found then
                o_insname := null;
                o_id  := null;
            when others then
                o_insname := null;
                o_id  := null;
        end;    

        begin
            select  decode(card_id_no,null,card_other_no,card_id_no)  CardID
            into o_id
            from mis_clm_mas
            where clm_no = i_clmno ;
        exception
            when no_data_found then
                o_id  := null;
            when others then
                o_id  := null;
        end;  
                
        if o_id is null then
            
            o_id := nc_health_paid.GET_CARDNO(i_polno  ,i_polrun ,i_fleet ,i_recpt
                ,null ,null,null ,i_clmno ,i_payno);
                
        end if;
        
        if o_insname is null then -- check UNNAME          
            if nc_health_package.is_unname_policy(i_polno ,i_polrun) then
                begin
                    select loss_name into o_insname
                    from mis_cpa_res a
                    where clm_no = i_clmno
                    and revise_seq in (select max(aa.revise_seq) from mis_cpa_res aa where aa.clm_no = a.clm_no);            
                exception
                    when no_data_found then
                        null;
                    when others then
                        null;
                end;         
            end if;         
        end if;

        if o_insname is null then -- get by fleet
            begin
                select title||' '||name||' '||surname into 
                o_insname
                from mis_pa_prem
                where pol_no = i_polno and pol_run = i_polrun
                and fleet_seq = i_fleet --and recpt_seq=i_recpt
                and rownum=1;
            exception
                when no_data_found then
                    o_insname := null;
                when others then
                    o_insname := null;
            end;         
        end if;     

        if o_insname is null then -- get by cpa_res
            begin
                select loss_name into o_insname
                from mis_cpa_res a
                where clm_no = i_clmno
                and revise_seq in (select max(aa.revise_seq) from mis_cpa_res aa where aa.clm_no = a.clm_no);            
            exception
                when no_data_found then
                    null;
                when others then
                    null;
            end;       
        end if;                     
    ELSE    --GM 
--        dbms_output.put_line('polno: '||i_polno||i_polrun||' fleet:'||i_fleet);
        begin
            select title||' '||name , id_no   into 
            o_insname ,o_id
            from pa_medical_det
            where pol_no = i_polno and pol_run = i_polrun 
            and fleet_seq = i_fleet 
--            and i_lossdate between fr_date and to_date
            and rownum=1;
        exception
            when no_data_found then
                o_insname := null;
                o_id  := null;
            when others then
                o_insname := null;
                o_id  := null;
        end;        
        
        begin
            select  decode(card_id_no,null,card_other_no,card_id_no)  CardID
            into o_id
            from mis_clm_mas
            where clm_no = i_clmno ;
        exception
            when no_data_found then
                o_id  := null;
            when others then
                o_id  := null;
        end;  
                
        if o_id is null then
            
            o_id := nc_health_paid.GET_CARDNO(i_polno  ,i_polrun ,i_fleet ,i_recpt
                ,null ,null,null ,i_clmno ,i_payno);
                
        end if;
                
    END IF;

END get_Citizen;

--PROCEDURE get_Citizen(i_grp IN VARCHAR2 ,i_polno IN VARCHAR2 ,i_polrun IN NUMBER ,i_fleet IN NUMBER ,i_recpt IN NUMBER ,i_lossdate IN DATE 
--,i_clmno IN VARCHAR2, i_payno IN VARCHAR2 ,o_insname OUT  VARCHAR2 ,o_id OUT VARCHAR2) IS
--
--BEGIN
--    IF i_grp ='PA' THEN
--        begin
--            select title||' '||name||' '||surname ,id  into 
--            o_insname ,o_id
--            from mis_pa_prem
--            where pol_no = i_polno and pol_run = i_polrun
--            and fleet_seq = i_fleet and recpt_seq=i_recpt
--            and rownum=1;
--        exception
--            when no_data_found then
--                o_insname := null;
--                o_id  := null;
--            when others then
--                o_insname := null;
--                o_id  := null;
--        end;    
--        
--        if o_insname is null then -- check UNNAME          
--            if nc_health_package.is_unname_policy(i_polno ,i_polrun) then
--                begin
--                    select loss_name into o_insname
--                    from mis_cpa_res a
--                    where clm_no = i_clmno
--                    and revise_seq in (select max(aa.revise_seq) from mis_cpa_res aa where aa.clm_no = a.clm_no);            
--                exception
--                    when no_data_found then
--                        null;
--                    when others then
--                        null;
--                end;         
--            end if;         
--        end if;
--
--        if o_insname is null then -- get by fleet
--            begin
--                select title||' '||name||' '||surname ,id  into 
--                o_insname ,o_id
--                from mis_pa_prem
--                where pol_no = i_polno and pol_run = i_polrun
--                and fleet_seq = i_fleet --and recpt_seq=i_recpt
--                and rownum=1;
--            exception
--                when no_data_found then
--                    o_insname := null;
--                    o_id  := null;
--                when others then
--                    o_insname := null;
--                    o_id  := null;
--            end;         
--        end if;     
--
--        if o_insname is null then -- get by cpa_res
--            begin
--                select loss_name into o_insname
--                from mis_cpa_res a
--                where clm_no = i_clmno
--                and revise_seq in (select max(aa.revise_seq) from mis_cpa_res aa where aa.clm_no = a.clm_no);            
--            exception
--                when no_data_found then
--                    null;
--                when others then
--                    null;
--            end;       
--        end if;                     
--    ELSE
----        dbms_output.put_line('polno: '||i_polno||i_polrun||' fleet:'||i_fleet);
--        begin
--            select title||' '||name , id_no   into 
--            o_insname ,o_id
--            from pa_medical_det
--            where pol_no = i_polno and pol_run = i_polrun 
--            and fleet_seq = i_fleet 
----            and i_lossdate between fr_date and to_date
--            and rownum=1;
--        exception
--            when no_data_found then
--                o_insname := null;
--                o_id  := null;
--            when others then
--                o_insname := null;
--                o_id  := null;
--        end;        
--    END IF;
--
--END get_Citizen;
--
PROCEDURE GET_PA_RESERVE(P_CLMNO IN VARCHAR2 ,V_KEY OUT NUMBER , V_RST OUT VARCHAR2) IS
    --q_str   CLOB;

     cursor c1 is                
                SELECT  clm_no pay_no ,a.prem_code1, a.prem_pay1,
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
                from mis_cpa_res a
                where a.clm_no = P_CLMNO
                and (a.clm_no ,a.revise_seq) in (select bb.clm_no ,max(bb.revise_seq) from mis_cpa_res bb where bb.clm_no =a.clm_no group by bb.clm_no)
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
            if c_rec.prem_code1 is not null and nvl(c_rec.prem_pay1,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;            
            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code1 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay1 ;

                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 1 ;                
            end if;
              
            if c_rec.prem_code2 is not null and nvl(c_rec.prem_pay2,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code2 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay2 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 2;
            end if;
            if c_rec.prem_code3 is not null and nvl(c_rec.prem_pay3,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code3 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay3 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 3 ;
            end if;
        
            if c_rec.prem_code4 is not null and nvl(c_rec.prem_pay4,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code4 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay4 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 4 ;
            end if;        

            if c_rec.prem_code5 is not null and nvl(c_rec.prem_pay5,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code5 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay5 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 5 ;
            end if;                
        
            if c_rec.prem_code6 is not null and nvl(c_rec.prem_pay6,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code6 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay6 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 6 ;
            end if;        
        
            if c_rec.prem_code7 is not null and nvl(c_rec.prem_pay7,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code7 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay7 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 7 ;
            end if;        

            if c_rec.prem_code8 is not null and nvl(c_rec.prem_pay8,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code8 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay8 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 8 ;
            end if;       
        
            if c_rec.prem_code9 is not null and nvl(c_rec.prem_pay9,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code9 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay9 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 9 ;
            end if;         
        
            if c_rec.prem_code10 is not null and nvl(c_rec.prem_pay10,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code10 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay10 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 10 ;
            end if;        
        
            if c_rec.prem_code11 is not null and nvl(c_rec.prem_pay11,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code11 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay11 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 11 ;
            end if;
        
            if c_rec.prem_code12 is not null and nvl(c_rec.prem_pay12,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code12 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay12 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 12 ;
            end if;        
        
            if c_rec.prem_code13 is not null and nvl(c_rec.prem_pay13,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code13 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay13 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 13 ;
            end if;        
        
            if c_rec.prem_code14 is not null and nvl(c_rec.prem_pay14,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code14 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay14 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 14 ;
            end if;        
        
            if c_rec.prem_code15 is not null and nvl(c_rec.prem_pay15,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code15 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay15 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 15 ;
            end if;        
                
            if c_rec.prem_code16 is not null and nvl(c_rec.prem_pay16,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code16 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay16 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 16 ;
            end if;
        
            if c_rec.prem_code17 is not null and nvl(c_rec.prem_pay17,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code17 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay17 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 17 ;
            end if;        
                
            if c_rec.prem_code18 is not null and nvl(c_rec.prem_pay18,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code18 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay18 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 18 ;
            end if;
                
            if c_rec.prem_code19 is not null and nvl(c_rec.prem_pay19,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code19 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay19 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 19 ;
            end if;        
        
            if c_rec.prem_code20 is not null and nvl(c_rec.prem_pay20,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code20 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay20 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 20 ;
            end if;
        
            if c_rec.prem_code21 is not null and nvl(c_rec.prem_pay21,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code21 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay21 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 21 ;
            end if;        
        
            if c_rec.prem_code22 is not null and nvl(c_rec.prem_pay22,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code22 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay22 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 22 ;
            end if;        

            if c_rec.prem_code23 is not null and nvl(c_rec.prem_pay23,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code23 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay23 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 23 ;
            end if;                
        
            if c_rec.prem_code24 is not null and nvl(c_rec.prem_pay24,0) >0 then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.pay_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code24 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay24 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 24 ;
            end if;        
        
            if c_rec.prem_code25 is not null and nvl(c_rec.prem_pay25,0) >0 then
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

PROCEDURE GET_PA_PAID(P_PAYNO IN VARCHAR2 ,V_CORR_SEQ IN NUMBER ,V_KEY OUT NUMBER , V_RST OUT VARCHAR2) IS
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
                and a.corr_seq = V_CORR_SEQ
--                and (pay_no ,corr_seq ) in (
--                    select aa.pay_no ,max(aa.corr_seq) from mis_cpa_paid aa where aa.pay_no = a.pay_no
--                    and cancel is null
--                    group by aa.pay_no
--                )      
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
        
END GET_PA_PAID;


FUNCTION hasINS_DATA(P_CLMNO IN VARCHAR2) RETURN BOOLEAN IS
    dummyClaim  varchar2(20);
BEGIN
    select claimnumber into dummyClaim
    from OIC_PAPH_INS_CLAIM
    where claimnumber =P_CLMNO ;
    
    return true;
EXCEPTION
    WHEN no_data_found THEN
        return false;
    WHEN others THEN
        return false;
END hasINS_DATA;

FUNCTION get_Coverage1(i_polno  IN VARCHAR2 ,i_polrun  IN VARCHAR2 ,i_fleet IN NUMBER ,i_clmno  IN VARCHAR2 ,i_payno  IN VARCHAR2, i_grp IN VARCHAR2 ,i_opd IN VARCHAR2 ,i_premcode IN VARCHAR2 ,i_risk  IN VARCHAR2) RETURN VARCHAR2 IS
    v_return varchar2(10);
    v_premdesc  varchar2(500);
    V_MAINCLASS varchar2(5);
    v_prod_type varchar2(5);
    v_orbor  varchar(2);
    v_cover varchar2(10);
    v_chkpertime    varchar(2);
    v_chkmotor    varchar(2);
    v_clmpdflag varchar2(2);
BEGIN
    begin
        select prod_type into v_prod_type
        from mis_clm_mas
        where clm_no = i_clmno;
    exception
        when no_data_found then
            v_prod_type :=null;
        when others then
            v_prod_type :=null;
    end;
    
    V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(v_prod_type);
    
    IF V_MAINCLASS is not null THEN
        if V_MAINCLASS = '06' then -- Accident
            begin
                select decode(orbo2,20,'2','1') into v_orbor
                from   mis_pa_prem
                where  pol_no    = i_polno
                and    pol_run   =  i_polrun
                and    recpt_seq = 1
                and    fleet_seq = i_fleet;
            exception when others then v_orbor := '1';
            end;     
            if v_orbor = '2' then 
                v_return := 'PA002';
            else
                v_return := 'PA001';
            end if;      
        elsif V_MAINCLASS = '07' then -- Health
            begin
                select oic_bene_code ,clm_pd_flag into v_cover ,v_clmpdflag
                from medical_ben_std
                where bene_code = i_premcode
                and th_eng = 'T'  ;
            exception 
                when no_data_found then v_cover := '';    v_clmpdflag := '';          
                when others then v_cover := '';  v_clmpdflag := '';          
            end;       
            if v_clmpdflag = 'I' then
                v_return :=  'HA007';
            elsif v_clmpdflag = 'O' then 
                v_return := 'HA006';
            else  
                v_return := null; -- ยังไม่มี column mapping          
            end if;
        elsif V_MAINCLASS = '11' then -- Travel
            begin
                select oic_group_coverage ,chk_pertime ,chk_motorcycle_cover into v_cover ,v_chkpertime ,v_chkmotor
                from nc_h_premcode
                where premcode = i_premcode;
            exception 
                when no_data_found then v_cover := '1.4'; v_chkpertime := null; v_chkmotor :=null;               
                when others then v_cover := '1.4'; v_chkpertime := null; v_chkmotor :=null; 
            end;     
            if v_cover ='1.4' then  -- บาดเจ็บ
                v_return := 'TA002';
            elsif v_cover in ('1.2','1.3') then -- ทุพลภาพ
                v_return := 'TA001';
            elsif v_cover in ('1.1.1','1.1.2','1.1.3') then -- เสียชีวิต
                v_return := 'TA003';
            else
                v_return := 'TA999';
            end if;
            if v_chkpertime = 'Y' then  -- ชดเชย
                v_return := 'TA004';
            end if;
        end if;
    ELSE
        IF i_grp ='PA' THEN 
            v_return := 'PA999';    -- อื่นๆ
        ELSE
            v_return := 'HA006';   -- OPD
        END IF;     
    END IF;
    /*
    IF i_grp ='PA' THEN
        IF NC_HEALTH_PACKAGE.IS_CHECK_ACCUM(i_premcode) THEN -- ผลประโยชน์แบบต่อครั้ง
            if i_opd = 'O' then
                v_return := '19'; -- ค่ารักษาผู้ป่วยนอกจาก อบห.
            else
                v_return := '04'; -- ค่ารักษาพยาบาล
                v_premdesc := nc_health_package.GET_PREMCODE_DESCR(i_premcode,'T');
                if INSTR(v_premdesc ,'กระดูก') > 0 then
                    v_return := '05'; -- ค่ารักษาจากอาการกระดูก
                end if;
            end if;
        ELSIF NC_HEALTH_PACKAGE.IS_CHECK_PERTIME(i_premcode) THEN -- ผลประโยชน์แบบชดเชย
            v_return := '06'; -- เงินชดเชยระหว่างรักษาตัว
        ELSIF NC_HEALTH_PACKAGE.IS_CHECK_TOTLOSS(i_premcode) THEN -- ผลประโยชน์ทุนหลัก
            v_return := '01';
        END IF;
    ELSE
        v_return := '04';   -- ค่ารักษาพยาบาล
    END IF; 
    */
    
    
    return v_return;
END get_Coverage1;

FUNCTION get_Coverage2(i_polno  IN VARCHAR2 ,i_polrun  IN VARCHAR2 ,i_fleet IN NUMBER ,i_clmno  IN VARCHAR2 ,i_payno  IN VARCHAR2, i_grp IN VARCHAR2 ,i_opd IN VARCHAR2 ,i_premcode IN VARCHAR2 ,i_risk  IN VARCHAR2) RETURN VARCHAR2 IS
    v_return varchar2(10);
    v_premdesc  varchar2(500);
    V_MAINCLASS varchar2(10);
    v_prod_type varchar2(10);
    v_orbor  varchar(2);
    v_cover varchar2(10);
    v_chkpertime    varchar(2);
    v_chkmotor    varchar(2);
    v_clmpdflag varchar2(2);    
BEGIN

    begin
        select prod_type into v_prod_type
        from mis_clm_mas
        where clm_no = i_clmno;
    exception
        when no_data_found then
            v_prod_type :=null;
        when others then
            v_prod_type :=null;
    end;
    
    V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(v_prod_type);
    
    IF V_MAINCLASS is not null THEN
        if V_MAINCLASS = '06' then -- Accident
            begin
                select oic_group_coverage ,chk_pertime ,chk_motorcycle_cover into v_cover ,v_chkpertime ,v_chkmotor
                from nc_h_premcode
                where premcode = i_premcode;
            exception 
                when no_data_found then v_cover := '1.4'; v_chkpertime := null; v_chkmotor :=null;               
                when others then v_cover := '1.4'; v_chkpertime := null; v_chkmotor :=null; 
            end;          
            IF NC_HEALTH_PACKAGE.IS_CHECK_ACCUM(i_premcode) THEN -- ผลประโยชน์แบบต่อครั้ง
    --            if i_opd = 'O' then
                if 'O' = 'O' then
                       -- ค่ารักษาผู้ป่วยนอกจาก อบห.
                    IF NC_HEALTH_PACKAGE.IS_CHECK_MOTORCYCLE(i_premcode)    THEN    -- เช็ค motorcycle
                        v_return := 'P00039';            
                    ELSE
                        v_return := 'P00038';            
                    END IF;                
                    v_premdesc := nc_health_package.GET_PREMCODE_DESCR(i_premcode,'T');
                    if INSTR(v_premdesc ,'กระดูก') > 0 then
                        v_return := 'P00042'; -- ค่ารักษาจากอาการกระดูก
                    end if;                
                end if;
            ELSIF NC_HEALTH_PACKAGE.IS_CHECK_PERTIME(i_premcode) THEN -- ผลประโยชน์แบบชดเชย
                v_return := 'P00054'; -- เงินชดเชยระหว่างรักษาตัว
            ELSIF NC_HEALTH_PACKAGE.IS_CHECK_TOTLOSS(i_premcode) THEN -- ผลประโยชน์ทุนหลัก
                IF NC_HEALTH_PACKAGE.IS_CHECK_MOTORCYCLE(i_premcode)    THEN    -- เช็ค motorcycle
                    v_return := 'P00002';            
                ELSE
                    v_return := 'P00001';            
                END IF;
            ELSE
                v_return := 'P99999';       
            END IF;
        elsif V_MAINCLASS = '07' then -- Health
            begin
                select oic_bene_code ,clm_pd_flag into v_cover ,v_clmpdflag
                from medical_ben_std
                where bene_code = i_premcode
                and th_eng = 'T'  ;
            exception 
                when no_data_found then v_cover := '';    v_clmpdflag := '';          
                when others then v_cover := '';  v_clmpdflag := '';          
            end;       
            if v_cover is not null then
                v_return :=  v_cover;
            else  
                v_return := 'H99999'; -- ยังไม่มี column mapping          
            end if;
        elsif V_MAINCLASS = '11' then -- Travel
/*
select  premcode ,nc_health_package.GET_PREMCODE_DESCR(premcode,'T')descr,oic_group_coverage ,chk_pertime ,chk_motorcycle_cover ,chk_totloss ,chk_accum --into v_cover ,v_chkpertime ,v_chkmotor
from nc_h_premcode
--where premcode in ('0031','0008')
where nc_health_package.GET_PREMCODE_DESCR(premcode,'T') like '%%เดินทาง%'

ไม่สงบ  จราจล 
%เที่ยวบิน% T00007
%จี้เครื่องบิน%   T00008
%เสีย%กระเป๋า%  T00001
%ช้า%กระเป๋า%   T00009
%เลิก%เดินทาง% T00013
เดินทาง
*/        
            begin
                select oic_group_coverage ,chk_pertime ,chk_motorcycle_cover ,nc_health_package.GET_PREMCODE_DESCR(premcode,'T') descr
                into v_cover ,v_chkpertime ,v_chkmotor ,v_premdesc
                from nc_h_premcode
                where premcode = i_premcode;
            exception 
                when no_data_found then v_cover := '1.4'; v_chkpertime := null; v_chkmotor :=null;               
                when others then v_cover := '1.4'; v_chkpertime := null; v_chkmotor :=null; 
            end;     
            IF NC_HEALTH_PACKAGE.IS_CHECK_ACCUM(i_premcode) THEN -- ผลประโยชน์แบบต่อครั้ง

                IF NC_HEALTH_PACKAGE.IS_CHECK_MOTORCYCLE(i_premcode)    THEN    -- เช็ค motorcycle                        
                    if v_cover ='1.4' then  -- บาดเจ็บ
                        v_return := 'T00023';
                    elsif v_cover in ('1.2','1.3') then -- ทุพลภาพ
                        v_return := 'T00017';
                    elsif v_cover in ('1.1.1','1.1.2','1.1.3') then -- เสียชีวิต
                        v_return := 'T00047';
                    else
                        v_return := 'T99999';
                    end if;          
                ELSE
                    if v_cover ='1.4' then  -- บาดเจ็บ
                        v_return := 'T00022';
                    elsif v_cover in ('1.2','1.3') then -- ทุพลภาพ
                        v_return := 'T00015';
                    elsif v_cover in ('1.1.1','1.1.2','1.1.3') then -- เสียชีวิต
                        v_return := 'T00045';
                    else
                        v_return := 'T99999';
                    end if;           
                END IF;                

            ELSIF NC_HEALTH_PACKAGE.IS_CHECK_PERTIME(i_premcode) THEN -- ผลประโยชน์แบบชดเชย
                v_return := 'T00002'; -- เงินชดเชยระหว่างรักษาตัว
            ELSIF NC_HEALTH_PACKAGE.IS_CHECK_TOTLOSS(i_premcode) THEN -- ผลประโยชน์ทุนหลัก
                IF NC_HEALTH_PACKAGE.IS_CHECK_MOTORCYCLE(i_premcode)    THEN    -- เช็ค motorcycle
                    if v_cover ='1.4' then  -- บาดเจ็บ
                        v_return := 'T00023';
                    elsif v_cover in ('1.2','1.3') then -- ทุพลภาพ
                        v_return := 'T00017';
                    elsif v_cover in ('1.1.1','1.1.2','1.1.3') then -- เสียชีวิต
                        v_return := 'T00047';
                    else
                        v_return := 'T99999';
                    end if;          
                ELSE
                    if v_cover ='1.4' then  -- บาดเจ็บ
                        v_return := 'T00022';
                    elsif v_cover in ('1.2','1.3') then -- ทุพลภาพ
                        v_return := 'T00015';
                    elsif v_cover in ('1.1.1','1.1.2','1.1.3') then -- เสียชีวิต
                        v_return := 'T00045';
                    else
                        v_return := 'T99999';
                    end if;               
                END IF;
            ELSE
                v_return := 'T99999';       
            END IF;
            
            -- ชดเชย
            if v_premdesc like '%เที่ยวบิน%' then  
                v_return := 'T00007';
            elsif v_premdesc like '%จี้เครื่องบิน%' then  
                v_return := 'T00008';
            elsif v_premdesc like '%เสีย%กระเป๋า%' then  
                v_return := 'T00001';
            elsif v_premdesc like '%ช้า%กระเป๋า%' then  
                v_return := 'T00009';
            elsif v_premdesc like '%เลิก%เดินทาง%' then  
                v_return := 'T00013';    
            end if;
        end if;    
    ELSE
        IF i_grp ='PA' THEN
            IF NC_HEALTH_PACKAGE.IS_CHECK_ACCUM(i_premcode) THEN -- ผลประโยชน์แบบต่อครั้ง
    --            if i_opd = 'O' then
                if 'O' = 'O' then
                       -- ค่ารักษาผู้ป่วยนอกจาก อบห.
                    IF NC_HEALTH_PACKAGE.IS_CHECK_MOTORCYCLE(i_premcode)    THEN    -- เช็ค motorcycle
                        v_return := 'P00039';            
                    ELSE
                        v_return := 'P00038';            
                    END IF;                
                    v_premdesc := nc_health_package.GET_PREMCODE_DESCR(i_premcode,'T');
                    if INSTR(v_premdesc ,'กระดูก') > 0 then
                        v_return := 'P00042'; -- ค่ารักษาจากอาการกระดูก
                    end if;                
                else
                    v_return := 'v_return'; -- ค่ารักษาพยาบาล
                    v_premdesc := nc_health_package.GET_PREMCODE_DESCR(i_premcode,'T');
                    if INSTR(v_premdesc ,'กระดูก') > 0 then
                        v_return := 'P00042'; -- ค่ารักษาจากอาการกระดูก
                    end if;
                end if;
            ELSIF NC_HEALTH_PACKAGE.IS_CHECK_PERTIME(i_premcode) THEN -- ผลประโยชน์แบบชดเชย
                v_return := 'P00054'; -- เงินชดเชยระหว่างรักษาตัว
            ELSIF NC_HEALTH_PACKAGE.IS_CHECK_TOTLOSS(i_premcode) THEN -- ผลประโยชน์ทุนหลัก
                IF NC_HEALTH_PACKAGE.IS_CHECK_MOTORCYCLE(i_premcode)    THEN    -- เช็ค motorcycle
                    v_return := 'P00002';            
                ELSE
                    v_return := 'P00001';            
                END IF;
            ELSE
                v_return := 'P99999';       
            END IF;
        ELSE
            if i_opd = 'O' then
                v_return := 'H00019';   -- ค่ารักษาพยาบาลและค่าบริการทั่วไป                    
            elsif i_opd = 'I' then
                v_return := 'H00032';   -- ค่ารักษาพยาบาลและค่าบริการทั่วไป            
            else
                v_return := 'H99999';   -- อื่นๆ
            end if;
            
        END IF;
        
    END IF;

    return v_return;
END get_Coverage2;

PROCEDURE EMAIL_LOG(i_subject IN VARCHAR2 ,i_message IN VARCHAR2 ) IS
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
 
 v_rst varchar2(1000);
 
 v_cnt1 number:=0;
 
 i_sts varchar2(10);
BEGIN
 
    FOR X in (
    select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail 
    from nc_med_email a
    where module = 'OIC-GROUP' 
    and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
    and CANCEL is null 
    ) LOOP
    v_to := v_to || x.ldap_mail ||';' ;
    END LOOP;

    begin 
        select UPPER(substr(instance_name,1,8)) instance_name 
        into v_dbins
        from v$instance; 
        if v_dbins='UATBKIIN' then
        v_whatsys := '[ระบบทดสอบ]';
--        v_link := p_claim_send_mail.get_link_bkiapp('UAT') ;
        else 
        v_whatsys := null;
--        v_link := p_claim_send_mail.get_link_bkiapp('PROD') ;
        end if; 
    exception 
    when no_data_found then 
    v_dbins := null;
    when others then 
    v_dbins := null;
    end; 

    x_subject :=i_subject||' '||v_whatsys; 
    X_BODY := '<!DOCTYPE html>'||
    '<html lang="en">'||'<head><meta charset="utf-8">'||
    '<title>'||x_subject||'</title>'||'</head>'||
    '<body bgcolor="#FFFFCC" style="font-family:''Angsana New'' ">'||
    '<h2 align="center">'||i_subject||'</h2>'||
    '<div>'||i_message||
    '<br/>'||
    '</div>'|| 
    '</body></html>' ;

-- 
-- if v_dbins='DBBKIINS' then
-- null; 
-- else 
-- v_to := v_bcc; -- for test
-- v_cc := ''; -- for test
-- end if; 
 
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
 nc_health_paid.WRITE_LOG('P_OIC_PAPH_CLM' ,'PACK','EMAIL_LOG' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' error::'||sqlerrm ,'error' ,v_rst) ;
 dbms_output.put_line('Error: '||sqlerrm );
END EMAIL_LOG; --email_notice bancas 

PROCEDURE EMAIL_LOG(i_subject IN VARCHAR2 ,i_message IN VARCHAR2 ,i_to  IN VARCHAR2) IS
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
 
 v_rst varchar2(1000);
 
 v_cnt1 number:=0;
 
 i_sts varchar2(10);
BEGIN
 
    FOR X in (
    select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail 
    from nc_med_email a
    where module = 'OIC-GROUP' 
    and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
    and direction = 'CC'
    and CANCEL is null 
    ) LOOP
    v_cc := v_cc || x.ldap_mail ||';' ;
    END LOOP;
    v_to := core_ldap.GET_EMAIL_FUNC(i_to);
    
    if v_to is not null then
        if instr(v_to ,'@') = 0 then
            v_to := v_cc;
        end if;
    else
        v_to := v_cc;
    end if;
    
    begin 
        select UPPER(substr(instance_name,1,8)) instance_name 
        into v_dbins
        from v$instance; 
        if v_dbins='UATBKIIN' then
        v_whatsys := '[ระบบทดสอบ]';
--        v_link := p_claim_send_mail.get_link_bkiapp('UAT') ;
        else 
        v_whatsys := null;
--        v_link := p_claim_send_mail.get_link_bkiapp('PROD') ;
        end if; 
    exception 
    when no_data_found then 
    v_dbins := null;
    when others then 
    v_dbins := null;
    end; 

    x_subject :=i_subject||' '||v_whatsys; 
    X_BODY := '<!DOCTYPE html>'||
    '<html lang="en">'||'<head><meta charset="utf-8">'||
    '<title>'||x_subject||'</title>'||'</head>'||
    '<body bgcolor="#FFFFCC" style="font-family:''Angsana New'' ">'||
    '<h2 align="center">'||i_subject||'</h2>'||
    '<div style="font-size:16pt;">'||i_message||
    '<br/>'||
    '</div>'|| 
    '</body></html>' ;

-- 
-- if v_dbins='DBBKIINS' then
-- null; 
-- else 
-- v_to := v_bcc; -- for test
-- v_cc := ''; -- for test
-- end if; 
 
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
 nc_health_paid.WRITE_LOG('P_OIC_PAPH_CLM' ,'PACK','EMAIL_LOG' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' error::'||sqlerrm ,'error' ,v_rst) ;
 dbms_output.put_line('Error: '||sqlerrm );
END EMAIL_LOG; --email_notice bancas 

PROCEDURE get_PA_Claim_v2(i_datefr IN DATE ,i_dateto IN DATE  ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(2);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_TRANSACTIONSTATUS2  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);
    
    ACR_PAID_TYPE    VARCHAR2(1);
    ACR_PAID_DATE   DATE;
    ACR_BANK_CODE   VARCHAR2(20);
    ACR_BRANCH_CODE VARCHAR2(20);
    ACR_CHEQUE_NO   VARCHAR2(20);
    
    v_cnt number(10):=0;
    v_runclmseq number(5);    
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
    
    m_payno varchar2(20);
    m_corr_date date;
    m_corr_seq number;
    v_skip  boolean:=false;
    v_foundpayee    boolean:=false;
    v_payeename varchar2(250);
    dummyClaim  varchar2(20);
BEGIN
    x_subject := 'run get_pa_claim_v2 @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim v2 === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    
    FOR M1 in (
        select a.clm_no ,'' pay_no ,fleet_seq ,recpt_seq ,a.pol_no ,a.pol_run ,reg_date ,nvl(c.close_date ,trunc(c.corr_date)) corr_date ,a.loss_date ,c.clm_sts , dis_code ,risk_code ,c.tot_res
        ,decode(ipd_flag,'O','OPD','I','IPD','OPD') CLM_TYPE ,a.clm_date ,a.prod_type ,a.close_date ,c.tot_paid
        from mis_clm_mas a ,mis_cpa_res b ,mis_clm_mas_seq c
        where a.clm_no = b.clm_no and a.clm_no = c.clm_no and a.prod_grp = '0' 
        and a.prod_type in (select prod_type from clm_grp_prod where sysid='PA') 
        and nvl(c.close_date ,trunc(c.corr_date)) between i_datefr and  i_dateto
        and (b.clm_no ,b.revise_seq) in (select bb.clm_no ,max(bb.revise_seq) from mis_cpa_res bb where bb.clm_no =b.clm_no 
            and trunc(bb.corr_date) <= i_asdate group by bb.clm_no)
        and c.corr_seq in (select max(cc.corr_seq) from mis_clm_mas_seq cc where cc.clm_no = c.clm_no 
            and nvl(cc.close_date ,trunc(cc.corr_date))  <= i_asdate)            
--        and b.corr_date <= i_asdate
        and a.channel <> '9'
        and pol_yr > 2010 
--        and a.clm_no = i_clmno
--        and a.clm_no not in (select claimnumber from OIC_PAPH_CLAIM_HIST WHERE CLAIMGROUP = 'EC')
--        and rownum < 50
        order by a.clm_no
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
        V_CLAIMSEQ := 0;
--        V_CLAIMGROUP := 'EC'; 
        dbms_output.put_line('clm='||M1.clm_no||' clmsts='||M1.clm_sts);
        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype); 

        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if V_MAINCLASS is null then
            V_MAINCLASS := '06';    
            IF v_poltype = 'PI' THEN
                V_SUBCLASS := '01';
                IF nc_health_package.is_unname_policy(m1.pol_no ,m1.pol_run) THEN
                    V_SUBCLASS := '03';
                END IF;
            ELSIF  v_poltype = 'PG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;
        end if;
                
--        V_CLAIMSEQ := 1;
        V_CLAIMTYPE := P_OIC_PAPH_CLM.GET_CLMTYPE('PA',m1.CLM_TYPE ,v_premcode);
        V_INSUREDSEQ := nvl(M1.fleet_seq,0);
        V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
        V_NOTIFYDATE := m1.clm_date; --to_date(m1.reg_date,'yyyymmdd');
        V_LOSSDATE :=  m1.loss_date; --to_date(m1.loss_date,'yyyymmdd');
--        V_CLAIMSTATUS := '1';  --  open claim
        V_CLAIMCAUSE := m1.dis_code ; -- Accident
        V_ICD10CODE1 := m1.dis_code;
--        V_CLAIMAMT := m1.tot_res;
        V_TRANSACTIONSTATUS  :='N';
        V_REFERENCENUMBER    :=null;     
        V_DEDUCTIBLEAMT :=0;       
        V_ACCOUNTINGDATE := M1.corr_date ;
                
        P_OIC_PAPH_CLM.get_citizen('PA' ,m1.pol_no ,m1.pol_run ,m1.fleet_seq ,nvl(m1.recpt_seq,1)  ,'' ,M1.CLM_NO ,M1.PAY_NO ,V_INSUREDNAME ,V_INSUREDCITIZENID);
        
        if m1.clm_type = 'OPD' then
            V_TREATMENTTYPE := '1';
        elsif m1.clm_type = 'IPD' then
            V_TREATMENTTYPE := '2';
        else
            V_TREATMENTTYPE := '3';
        end if;
        
        IF M1.CLM_STS <> '2' THEN
            v_skip := P_OIC_PAPH_CLM.check_have_paid(V_CLAIMNUMBER ,'1');
            IF M1.CLM_STS = '3' THEN
                V_CLAIMGROUP := 'P';
                V_CLAIMAMT := 0;
                V_CLAIMSTATUS := '2';  --  close claim
            ELSE
                V_CLAIMGROUP := 'EC';
                V_CLAIMAMT := -1;
                V_CLAIMSTATUS := '1';  --  open claim
            END IF;
            
        ELSIF M1.CLM_STS = '2' THEN
            v_skip := P_OIC_PAPH_CLM.check_have_paid(V_CLAIMNUMBER ,'2');
            V_CLAIMGROUP := 'P';
            V_CLAIMSTATUS := '2';  --  close claim
            V_CLAIMAMT := M1.TOT_PAID;
        END IF;
        
        -- check  last claim status (don't care as of date for select period)
        IF NOT v_skip THEN  
            v_skip := P_OIC_PAPH_CLM.check_have_paid(V_CLAIMNUMBER ,'3');   -- check  last claim status (don't care as of date for select period)
        END IF;
        -- end check last claim status
                 
        IF NOT v_skip THEN  -- validate flag for insert or do nothing
            dbms_output.put_line('IN Loop v_claimamt='||V_CLAIMAMT);
            IF V_CLAIMGROUP = 'EC' and V_CLAIMAMT = -1 THEN -- case Out.
                -- ===== Path get prem code ====
                P_OIC_PAPH_CLM.GET_PA_RESERVE(M1.CLM_NO,
                                                v_sid,
                                                p1_rst);          
                        
                if p1_rst is null then
                    FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
                    from NC_H_HISTORY_TMP
                    where sid = v_sid )
                    LOOP    
                        v_runclmseq := v_runclmseq+1;
                        V_CLAIMSEQ := V_CLAIMSEQ+1 ;
                        v_premcode := p1.prem_code;    
                        V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                        ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
                        V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                        ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
                        
                        V_CLAIMAMT := p1.amount;
                        
                        INSERT INTO OIC_PAPH_CLAIM
                        ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                        COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                        PROCODURECODE1 ,
                        CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                        V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                        V_PROCODURECODE1 ,
                        V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

                        INSERT INTO OIC_PAPH_CLAIM_HIST
                        ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                        COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                        PROCODURECODE1 ,
                        CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                        V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                        V_PROCODURECODE1 ,
                        V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE  , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

                    END LOOP;      -- loop get Reserved
                end if;        
                NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
                -- ===== End Path get prem code ====    

                IF P_OIC_PAPH_CLM.hasINS_data(V_CLAIMNUMBER) THEN
                    V_TRANSACTIONSTATUS2 := 'U';        
                ELSE    
                    V_TRANSACTIONSTATUS2 := 'N';  
                    
                    INSERT INTO OIC_PAPH_INS_CLAIM
                    ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                    INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                    VALUES 
                    (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                    V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

                    INSERT INTO OIC_PAPH_INS_CLAIM_HIST
                    ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                    INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                    VALUES 
                    (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                    V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        
                              
                END IF;
                                                            
            ELSIF V_CLAIMGROUP = 'P' and V_CLAIMAMT = 0 THEN -- case CWP.
                null; -- hold for IMD request not send claimamt = 0
--                -- ===== Path get prem code ====
--                P_OIC_PAPH_CLM.GET_PA_RESERVE(M1.CLM_NO,
--                                                v_sid,
--                                                p1_rst);          
--                        
--                if p1_rst is null then
--                    FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
--                    from NC_H_HISTORY_TMP
--                    where sid = v_sid and amount > 0 )
--                    LOOP    
--                        v_runclmseq := v_runclmseq+1;
--                        V_CLAIMSEQ := V_CLAIMSEQ+1 ;
--                        v_premcode := p1.prem_code;    
--                        V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
--                        ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
--                        V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
--                        ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
--                        
--                        V_CLAIMAMT := 0;
--                        
--                        INSERT INTO OIC_PAPH_CLAIM
--                        ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
--                        COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
--                        PROCODURECODE1 ,
--                        CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
--                        VALUES 
--                        (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
--                        V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
--                        V_PROCODURECODE1 ,
--                        V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;
--
--                        INSERT INTO OIC_PAPH_CLAIM_HIST
--                        ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
--                        COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
--                        PROCODURECODE1 ,
--                        CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
--                        VALUES 
--                        (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
--                        V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
--                        V_PROCODURECODE1 ,
--                        V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE  , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;
--
--                    END LOOP;      -- loop get Reserved
--                end if;        
--                NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
--                -- ===== End Path get prem code ====    
--
--                IF P_OIC_PAPH_CLM.hasINS_data(V_CLAIMNUMBER) THEN
--                    V_TRANSACTIONSTATUS2 := 'U';        
--                ELSE    
--                    V_TRANSACTIONSTATUS2 := 'N';   
--                    
--                    INSERT INTO OIC_PAPH_INS_CLAIM
--                    ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
--                    INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
--                    VALUES 
--                    (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
--                    V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);
--
--                    INSERT INTO OIC_PAPH_INS_CLAIM_HIST
--                    ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
--                    INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
--                    VALUES 
--                    (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
--                    V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        
--                                              
--                END IF;
             
            ELSIF V_CLAIMGROUP = 'P' THEN -- case Close Paid.

                begin 
                    select pay_no ,trunc(corr_date) into m_payno ,m_corr_date
                    from mis_clm_paid b
                    where clm_no = M1.CLM_NO
                    and (b.pay_no ,b.corr_seq) in (select bb.pay_no ,max(bb.corr_seq) from mis_clm_paid bb where bb.pay_no =b.pay_no 
                    and trunc(bb.corr_date) between i_datefr and i_dateto and pay_total <> 0 and pay_date is not null 
                    group by bb.pay_no)
--                    and pay_total <> 0 and pay_date is not null  
                    and rownum=1;
                exception
                    when no_data_found then
                        m_payno := '';
                        m_corr_date := null;
                    when others then
                        m_payno := '';
                        m_corr_date := null;
                end;
                
                v_foundpayee := false;
                
                begin 
                    select payee_name into v_payeename
                    from mis_clm_payee
                    where pay_no = M_PAYNO
                    and payee_code is not null and rownum=1;
                    v_foundpayee := true;
                exception
                    when no_data_found then
                        v_foundpayee := false;
                    when others then
                        v_foundpayee := false;
                end;
                
                dbms_output.put_line('payno='||M_PAYNO||' v_payeename='||v_payeename);
                            
                IF not P_OIC_PAPH_CLM.check_have_EC(M1.CLM_NO) and v_foundpayee THEN
                    V_CLAIMGROUP := 'EC';
                    V_CLAIMSTATUS := '1';  --  open claim                
                    -- ===== Path get prem code ====
                    P_OIC_PAPH_CLM.GET_PA_RESERVE(M1.CLM_NO,
                                                    v_sid,
                                                    p1_rst);          
                            
                    if p1_rst is null then
                        FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
                        from NC_H_HISTORY_TMP
                        where sid = v_sid )
                        LOOP    
                            v_runclmseq := v_runclmseq+1;
                            V_CLAIMSEQ := V_CLAIMSEQ+1 ;
                            v_premcode := p1.prem_code;    
                            V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
                            V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                            ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
                            
                            V_CLAIMAMT := p1.amount;
                            
                            INSERT INTO OIC_PAPH_CLAIM
                            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                            PROCODURECODE1 ,
                            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                            VALUES 
                            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                            V_PROCODURECODE1 ,
                            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

                            INSERT INTO OIC_PAPH_CLAIM_HIST
                            ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                            COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                            PROCODURECODE1 ,
                            CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                            VALUES 
                            (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                            V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                            V_PROCODURECODE1 ,
                            V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE  , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

                        END LOOP;      -- loop get Reserved
                    end if;        
                    NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
                    -- ===== End Path get prem code ====    

                    IF P_OIC_PAPH_CLM.hasINS_data(V_CLAIMNUMBER) THEN
                        V_TRANSACTIONSTATUS2 := 'U';        
                    ELSE    
                        V_TRANSACTIONSTATUS2 := 'N';  
                        
                        INSERT INTO OIC_PAPH_INS_CLAIM
                        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

                        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
                        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        
                                  
                    END IF;                
                END IF; -- check have EC group

                V_CLAIMGROUP := 'P';
                V_CLAIMSTATUS := '2';  --  close claim                
                
                if v_foundpayee then    -- filter data , have payee data
                    dbms_output.put_line('in Found Payee');
                    begin
                        select trunc(pay_date) ,corr_seq into V_CHEQUEDATE ,M_CORR_SEQ
                        from mis_clm_paid a
                        where pay_no = M_PAYNO and
                        a.corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no 
                        and aa.corr_date <=  i_asdate 
                        and pay_total <> 0 and pay_date is not null
                        group by aa.pay_no);
                        
                        if V_CHEQUEDATE is null then
                            V_CHEQUEDATE := M1.close_date;                          
                        end if; 
                    exception
                        when no_data_found then
                            V_CHEQUEDATE := M1.close_date;
                             M_CORR_SEQ := 0;
                        when others then
                            V_CHEQUEDATE := M1.close_date;
                             M_CORR_SEQ := 0;
                    end;    
            
                    -- ===== Path get prem code ====
--                    nc_health_paid.get_pa_reserve(M_PAYNO,
--                                                    v_sid,
--                                                    p1_rst);          
                    p_oic_paph_clm.get_pa_paid(M_PAYNO, M_CORR_SEQ ,
                                                    v_sid,
                                                    p1_rst);                                                           
                            
                    if p1_rst is null then
                    FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
                    from NC_H_HISTORY_TMP
                    where sid = v_sid  and AMOUNT > 0
                    )
                    LOOP    
                        v_runclmseq := v_runclmseq+1;
                        V_CLAIMSEQ := V_CLAIMSEQ+1 ;
                        v_premcode := p1.prem_code;  
                        
                        V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M_PAYNO 
                        ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);
                        V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,m1.fleet_seq, M1.CLM_NO ,M_PAYNO 
                        ,'PA',m1.CLM_TYPE ,v_premcode ,m1.risk_code);            
                        --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('PA',m1.CLM_TYPE ,v_premcode);
                        V_CLAIMAMT := p1.amount;  
                                   
                        --=== P
                        V_ACCOUNTINGDATE := m_corr_date;
                        INSERT INTO OIC_PAPH_CLAIM
                        ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                        COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                        PROCODURECODE1 ,
                        CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                        V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                        V_PROCODURECODE1 ,
                        V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

                        INSERT INTO OIC_PAPH_CLAIM_HIST
                        ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                        COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                        PROCODURECODE1 ,
                        CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                        V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                        V_PROCODURECODE1 ,
                        V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user )          ;
                                            
                    END LOOP;      
                    end if;
                    NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
                    -- ===== End Path get prem code ====
                    
                    IF p_oic_paph_clm.hasINS_data(V_CLAIMNUMBER) THEN
                        V_TRANSACTIONSTATUS2 := 'U';        
                    ELSE    
                        V_TRANSACTIONSTATUS2 := 'N';   
                        
                        INSERT INTO OIC_PAPH_INS_CLAIM
                        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

                        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
                        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        
                                                  
                    END IF;                
                    
                    FOR c_payee in (  -- Get Payee
                        select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
                        from mis_clm_payee a
                        where clm_no = M1.clm_no and payee_code is not null 
                    ) LOOP
                        V_PAYEEAMT := c_payee.payee_amt;
                        V_PAIDBY := p_oic_paph_clm.get_paidby('PA',c_payee.settle);
                        V_CLAIMPAIDSEQ :=c_payee.pay_seq ;
                        V_CHEQUENO := null;
                        
                        if V_PAIDBY = 'K' then
                            account.p_acc_acr.get_paid_info(M_PAYNO,'0',M1.prod_type,c_payee.payee_code,c_payee.settle,
                                                          ACR_PAID_TYPE, ACR_PAID_DATE, ACR_BANK_CODE, ACR_BRANCH_CODE, ACR_CHEQUE_NO);
                            V_CHEQUENO := ACR_CHEQUE_NO;                              
                            IF V_CHEQUENO is null THEN
                                V_PAIDBY := 'O' ;
                            END IF;               
                        elsif V_PAIDBY = 'T' then
                            V_CHEQUENO := null;
                        end if;               

                        if V_PAYEEAMT = 0 then
                            V_PAYEEAMT := M1.tot_paid;    
                        end if;
                                    
                        INSERT INTO OIC_PAPH_PAYMENT
                        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
                        PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
                        V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

                        INSERT INTO OIC_PAPH_PAYMENT_HIST
                        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
                        PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
                        VALUES 
                        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
                        V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);              
                    END LOOP;
                end if; -- check v_found_payee
            END IF;    -- check ClaimGroup    
        END IF; -- v_skip
        
    END LOOP;
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
--    P_OIC_PAPH_CLM.email_log(x_subject ,x_message);
END get_PA_Claim_v2;

PROCEDURE get_GM_Claim_V2(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS
--    i_datefr    DATE:='1-JAN-14';
--    i_dateto    DATE:= '1-JAN-15' ;
    V_COMPANY   varchar2(4):='2025';
    V_MAINCLASS          VARCHAR2(2);
    V_SUBCLASS           VARCHAR2(2);
    V_CLAIMNUMBER        VARCHAR2(30);
    V_CLAIMGROUP         VARCHAR2(2);
    V_ACCOUNTINGDATE     DATE;
    V_ACCOUNTINGDATE2     DATE;
    V_CLAIMSEQ           NUMBER(3);
    V_CLAIMTYPE          VARCHAR2(10);
    V_INSUREDSEQ          VARCHAR2(15);
    V_POLICYNUMBER       VARCHAR2(30);
    V_NOTIFYDATE         DATE;
    V_LOSSDATE           DATE;
    V_CLAIMSTATUS        VARCHAR2(1);
    V_CLAIMCAUSE         VARCHAR2(10);
    V_ICD10CODE1          VARCHAR2(10);
    V_ICD10CODE2          VARCHAR2(10);
    V_ICD10CODE3          VARCHAR2(10);
    V_ICD10CODE4          VARCHAR2(10);
    V_ICD10CODE5          VARCHAR2(10);
    V_PROCODURECODE1          VARCHAR2(10);
    V_PROCODURECODE2          VARCHAR2(10);
    V_COVERAGECODE1          VARCHAR2(10);
    V_COVERAGECODE2          VARCHAR2(10);
    
    V_CLAIMAMT           NUMBER(15,2);
    V_TRANSACTIONSTATUS  VARCHAR2(1);
    V_TRANSACTIONSTATUS2  VARCHAR2(1);
    V_REFERENCENUMBER    VARCHAR2(35);    
    V_RECORD_DATE   DATE:=sysdate;

    V_INSUREDNAME        VARCHAR2(200);
    V_INSUREDCITIZENID   VARCHAR2(20);
    V_TREATMENTTYPE      VARCHAR2(1);  
    V_DEDUCTIBLEAMT     NUMBER(15,2);
    
    V_CLAIMPAIDSEQ           NUMBER(3);
    V_CHEQUEDATE    DATE;
    V_PAIDBY    VARCHAR2(1);
    V_CHEQUENO     VARCHAR2(20);
    V_PAYEEAMT  NUMBER(15,2);
    
    ACR_PAID_TYPE    VARCHAR2(1);
    ACR_PAID_DATE   DATE;
    ACR_BANK_CODE   VARCHAR2(20);
    ACR_BRANCH_CODE VARCHAR2(20);
    ACR_CHEQUE_NO   VARCHAR2(20);
    
    v_cnt number(10):=0;
    v_runclmseq number(5);
    v_poltype   VARCHAR2(3);
    v_sid number;
    p1_rst  VARCHAR2(200);
    v_premcode  varchar2(10);
    x_subject   varchar2(1000);
    x_message   varchar2(1000);
    
    m_payno varchar2(20);
    v_TMPPAYNO varchar2(20);
    m_settle    varchar2(2);
    m_corr_date date;
    v_skip  boolean:=false;    
    v_chkrec    boolean;
    v_chkrec2    boolean;
    v_sumpaid    number;
    v_sumpayee  number;
    v_cntrec    number:=0;
    dummyClaim  varchar2(20);    
BEGIN
    x_subject := 'run get_gm_claim v2 @'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    x_message := 'PA Claim v2 === fr_date: '||i_datefr||' to_date: '||i_dateto||' as at: '||i_asdate||'<br/>';
    x_message := x_message||' start@'||to_char(V_RECORD_DATE ,'DD-MON-YYYY HH24:MI:SS') ;
    
    FOR M1 in (
        select distinct  trunc(a.clm_date) clm_date ,trunc(a.close_date) close_date ,state_seq ,nvl(c.close_date ,trunc(c.corr_date)) corr_date ,a.clm_sts sts_mas ,c.clm_sts sts_seq 
        ,a.prod_type ,'' pay_no 
        ,a.clm_no ,a.pol_no ,a.pol_run ,a.recpt_seq ,reg_date ,c.clm_sts ,'' risk_code ,c.tot_paid ,c.tot_res
        from mis_clm_mas a ,clm_medical_res b ,mis_clm_mas_seq c
        where a.clm_no = b.clm_no and a.clm_no = c.clm_no and a.prod_grp = '0' 
        and c.corr_seq in (select max(cc.corr_seq) from mis_clm_mas_seq cc where cc.clm_no = c.clm_no 
            and nvl(cc.close_date ,trunc(cc.corr_date))   <= i_asdate) 
        and a.prod_type in (select prod_type from clm_grp_prod where sysid='GM') 
        and nvl(c.close_date ,trunc(c.corr_date)) between i_datefr and  i_dateto
        and (b.clm_no ,b.state_seq) in (select bb.clm_no ,max(bb.state_seq) from clm_medical_res bb where bb.clm_no =b.clm_no 
        and trunc(bb.corr_date) <=  i_asdate group by bb.clm_no)
        and trunc(b.corr_date) <=  i_asdate
--        and a.clm_no = i_clmno
        and a.channel <> '9'    
        and pol_yr > 2010     
        order by a.clm_no
    )LOOP
        v_cnt := v_cnt+1;

        V_CLAIMNUMBER := m1.clm_no;
--        V_CLAIMSEQ :=1;
        V_CLAIMSEQ := 0;
--        V_CLAIMGROUP := 'EC';

        misc.healthutil.get_pa_health_type(m1.pol_no ,m1.pol_run , v_poltype);

        --==== get Main Class ,Sub Class from CORE
        V_MAINCLASS := CENTER.OIC_CORE_UTIL.GET_MAIN_CLASS(M1.prod_type);
        V_SUBCLASS := CENTER.OIC_CORE_UTIL.GET_SUBMAIN_CLASS(M1.prod_type);
        
        if  V_MAINCLASS is null then  
            V_MAINCLASS := '07'; 
            IF v_poltype = 'HI' THEN
                V_SUBCLASS := '01';
            ELSIF  v_poltype = 'HG' THEN
                V_SUBCLASS := '02';
            ELSE
                V_SUBCLASS := '99';
            END IF;        
        end if;
        
        IF M1.CLM_STS <> '2' THEN
            v_skip := P_OIC_PAPH_CLM.check_have_paid(V_CLAIMNUMBER ,'1');
            IF M1.CLM_STS = '3' THEN
                V_CLAIMGROUP := 'P';
                V_CLAIMAMT := 0;
                V_CLAIMSTATUS := '2';  --  close claim
            ELSE
                V_CLAIMGROUP := 'EC';
                V_CLAIMAMT := -1;
                V_CLAIMSTATUS := '1';  --  open claim
            END IF;
            
        ELSIF M1.CLM_STS = '2' THEN
            v_skip := P_OIC_PAPH_CLM.check_have_paid(V_CLAIMNUMBER ,'2');
            V_CLAIMGROUP := 'P';
            V_CLAIMSTATUS := '2';  --  close claim
            V_CLAIMAMT := M1.TOT_PAID;
        END IF;
        
        -- check  last claim status (don't care as of date for select period)
        IF NOT v_skip THEN  
            v_skip := P_OIC_PAPH_CLM.check_have_paid(V_CLAIMNUMBER ,'3');   -- check  last claim status (don't care as of date for select period)
        END IF;
        -- end check last claim status
                 
        IF NOT v_skip THEN  -- validate flag for insert or do nothing
            IF V_CLAIMGROUP = 'EC' and V_CLAIMAMT = -1 THEN -- case Out.
                FOR c_paid IN ( 
                    select '' pay_no , fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,state_date ,nvl(res_amt,0) res_amt
                    from clm_medical_res a
                    where  clm_no =M1.CLM_NO
                    and (clm_no ,state_seq) in (select clm_no ,max(aa.state_seq) from clm_medical_res aa where aa.clm_no =a.clm_no 
                    and aa.corr_date <=  i_asdate group by aa.clm_no)
                    and nvl(res_amt,0) > 0
                    order by res_amt               
                )  LOOP
                    -- ===== Path get prem code ====
                    v_premcode := c_paid.bene_code;
                    -- ===== End Path get prem code ====
                    v_runclmseq := v_runclmseq+1;         
                    V_CLAIMSEQ := V_CLAIMSEQ+1;
                    V_CLAIMTYPE := P_OIC_PAPH_CLM.GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
                    V_INSUREDSEQ := c_paid.fleet_seq;
                    V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
                    V_NOTIFYDATE := m1.clm_date; --to_date(m1.reg_date,'yyyymmdd');
--                    V_CLAIMSTATUS := '1';  -- Reserve claim        
                    V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
                    V_CLAIMCAUSE := c_paid.dis_code ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
                    V_ICD10CODE1 := c_paid.dis_code;
                    V_CLAIMAMT := c_paid.res_amt;
                    V_TRANSACTIONSTATUS  :='N';
                    V_REFERENCENUMBER    :=null;     
                    V_DEDUCTIBLEAMT :=0;       
                    --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('GM',c_paid.CLM_TYPE ,v_premcode) ;  --== mapping to table 5

                    V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                    ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                    V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                    ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                                            
                    V_ACCOUNTINGDATE := c_paid.state_date ;
                            
                    p_oic_paph_clm.get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date  ,M1.CLM_NO ,M1.PAY_NO ,V_INSUREDNAME ,V_INSUREDCITIZENID);
                    
                    if c_paid.clm_type = 'OPD' then
                        V_TREATMENTTYPE := '1';
                    elsif c_paid.clm_type = 'IPD' then
                        V_TREATMENTTYPE := '2';
                    else
                        V_TREATMENTTYPE := '3';
                    end if;

                    INSERT INTO OIC_PAPH_CLAIM
                    ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                    COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                    PROCODURECODE1 ,
                    CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                    VALUES 
                    (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                    V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                    V_PROCODURECODE1 ,
                    V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

                    INSERT INTO OIC_PAPH_CLAIM_HIST
                    ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                    COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                    PROCODURECODE1 ,
                    CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                    VALUES 
                    (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                    V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                    V_PROCODURECODE1 ,
                    V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user )          ;
                                                                  
--                    V_CLAIMPAIDSEQ :=1;
                END LOOP; -- C_paid
--                    
--                dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
--                ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   

                IF p_oic_paph_clm.hasINS_data(V_CLAIMNUMBER) THEN
                    V_TRANSACTIONSTATUS2 := 'U';        
                ELSE    
                    V_TRANSACTIONSTATUS2 := 'N';  
                    
                    INSERT INTO OIC_PAPH_INS_CLAIM
                    ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                    INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                    VALUES 
                    (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                    V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

                    INSERT INTO OIC_PAPH_INS_CLAIM_HIST
                    ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                    INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                    VALUES 
                    (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                    V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        
                              
                END IF;
            ELSIF V_CLAIMGROUP = 'P' and V_CLAIMAMT = 0 THEN -- case CWP.
                null; -- hold for IMD request not send claimamt = 0                                                
            ELSIF V_CLAIMGROUP = 'P' THEN -- case Close Paid.
                IF not P_OIC_PAPH_CLM.check_have_EC(M1.CLM_NO) THEN
                    V_CLAIMGROUP := 'EC';
                    V_CLAIMSTATUS := '1';  --  open claim  

                    FOR c_paid IN ( 
                        select '' pay_no , fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,state_date ,nvl(res_amt,0) res_amt
                        from clm_medical_res a
                        where  clm_no =M1.CLM_NO
                        and (clm_no ,state_seq) in (select clm_no ,max(aa.state_seq) from clm_medical_res aa where aa.clm_no =a.clm_no 
                        and aa.corr_date <=  i_asdate group by aa.clm_no
                        )
                        and nvl(res_amt,0) > 0
                        order by res_amt               
                    )  LOOP
                        -- ===== Path get prem code ====
                        v_premcode := c_paid.bene_code;
                        -- ===== End Path get prem code ====
                        v_runclmseq := v_runclmseq+1;         
                        V_CLAIMSEQ := V_CLAIMSEQ+1;
                        V_CLAIMTYPE := P_OIC_PAPH_CLM.GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
                        V_INSUREDSEQ := c_paid.fleet_seq;
                        V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
                        V_NOTIFYDATE := m1.clm_date; --to_date(m1.reg_date,'yyyymmdd');
    --                    V_CLAIMSTATUS := '1';  -- Reserve claim        
                        V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
                        V_CLAIMCAUSE := c_paid.dis_code ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
                        V_ICD10CODE1 := c_paid.dis_code;
                        V_CLAIMAMT := c_paid.res_amt;
                        V_TRANSACTIONSTATUS  :='N';
                        V_REFERENCENUMBER    :=null;     
                        V_DEDUCTIBLEAMT :=0;       
                        --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('GM',c_paid.CLM_TYPE ,v_premcode) ;  --== mapping to table 5

                        V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                        ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                        V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M1.PAY_NO 
                        ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                                                
                        V_ACCOUNTINGDATE := c_paid.state_date ;
                                
                        p_oic_paph_clm.get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date  ,M1.CLM_NO ,M1.PAY_NO ,V_INSUREDNAME ,V_INSUREDCITIZENID);
                        
                        if c_paid.clm_type = 'OPD' then
                            V_TREATMENTTYPE := '1';
                        elsif c_paid.clm_type = 'IPD' then
                            V_TREATMENTTYPE := '2';
                        else
                            V_TREATMENTTYPE := '3';
                        end if;

                        INSERT INTO OIC_PAPH_CLAIM
                        ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                        COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                        PROCODURECODE1 ,
                        CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                        V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                        V_PROCODURECODE1 ,
                        V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

                        INSERT INTO OIC_PAPH_CLAIM_HIST
                        ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                        COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                        PROCODURECODE1 ,
                        CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMGROUP , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                        V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                        V_PROCODURECODE1 ,
                        V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user )          ;
                                                                      
    --                    V_CLAIMPAIDSEQ :=1;
                    END LOOP; -- C_paid
    --                    
    --                dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
    --                ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   

                    IF p_oic_paph_clm.hasINS_data(V_CLAIMNUMBER) THEN
                        V_TRANSACTIONSTATUS2 := 'U';        
                    ELSE    
                        V_TRANSACTIONSTATUS2 := 'N';  
                        
                        INSERT INTO OIC_PAPH_INS_CLAIM
                        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

                        INSERT INTO OIC_PAPH_INS_CLAIM_HIST
                        ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                        INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                        VALUES 
                        (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                        V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        
                                  
                    END IF;                    
                END IF; -- check_have_EC
                V_CLAIMGROUP := 'P';
                V_CLAIMSTATUS := '2';  --  close claim                
                                    
                begin 
                    select pay_no ,trunc(corr_date) into m_payno ,m_corr_date
                    from clm_gm_paid b
                    where clm_no = M1.CLM_NO
                    and (b.pay_no ,b.corr_seq) in (select bb.pay_no ,max(bb.corr_seq) from clm_gm_paid bb where bb.pay_no =b.pay_no 
--                    and bb.corr_date <= i_asdate group by bb.pay_no
                    and trunc(bb.corr_date) between i_datefr and i_dateto  group by bb.pay_no                   
                    )
                    and pay_amt <> 0 and rownum=1;
                exception
                    when no_data_found then
                        m_payno := '';
                        m_corr_date := null;
                    when others then
                        m_payno := '';
                        m_corr_date := null;
                end;
                
                -- ********* check Advance Version 2 แบบไม่มี recov amt
                v_chkrec2 := false;
                BEGIN
                    select  sum(pay_amt) into v_sumpaid
                    from clm_gm_paid a
                    where pay_no = M_PAYNO
                    and corr_seq in (select max(aa.corr_seq) from clm_gm_paid aa where aa.pay_no =a.pay_no 
--                    and aa.corr_date <= i_asdate group by aa.pay_no
                    and trunc(aa.corr_date) between i_datefr and i_dateto  group by aa.pay_no 
                    )    ;

                    select sum(payee_amt) into v_sumpayee
                    from clm_gm_payee a
                    where pay_no =M_PAYNO  and payee_code is not null 
                    and nvl(payee_amt,0) >0  ;
                                                            
                EXCEPTION
                    when no_data_found then
                        v_sumpaid := 0;
                        v_sumpayee := 0;
                    when others then
                        v_sumpaid :=0;
                        v_sumpayee := 0;
                END;
                if (v_sumpayee - v_sumpaid >0) and v_sumpaid <> 0 then  -- case Advance 
                    v_chkrec2 := true;
                end if ;
                -- ********* check Advance Version 2 แบบไม่มี recov amt เตรียมนำ Sum Payee ไปใช้แทน tot_paid
                v_cntrec :=0;            
                v_chkrec := false;        
                FOR c_paid IN (
                    select  pay_no, fleet_seq ,dis_code ,bene_code ,clm_pd_flag CLM_TYPE ,loss_date ,date_paid pay_date ,nvl(pay_amt,0) pay_amt
                    ,nvl(rec_amt,0) rec_amt 
                    from clm_gm_paid a
                    where pay_no = M_PAYNO
                    and corr_seq in (select max(aa.corr_seq) from clm_gm_paid aa where aa.pay_no =a.pay_no 
--                    and aa.corr_date <= i_asdate group by aa.pay_no
                    and trunc(aa.corr_date) between i_datefr and i_dateto  group by aa.pay_no 
                    )
                    and ( nvl(pay_amt,0) > 0 or nvl(rec_amt,0) > 0 )
                    order by pay_no 
                )  LOOP 
                    if c_paid.rec_amt >0 then
                        v_chkrec := true;   -- mark  when found Rec_Amt for insert ClaimGroup = S  
                    end if;
                    
                    -- ===== Path get prem code ====
                    v_premcode := c_paid.bene_code;
                    -- ===== End Path get prem code ====
                            
                    v_runclmseq := v_runclmseq+1;
                    v_tmppayno := c_paid.pay_no;
                    V_CLAIMSEQ := V_CLAIMSEQ+1 ;
                    V_CLAIMTYPE := P_OIC_PAPH_CLM.GET_CLMTYPE('GM',c_paid.CLM_TYPE ,v_premcode);
                    V_INSUREDSEQ := c_paid.fleet_seq;
                    V_POLICYNUMBER := m1.pol_no ||m1.pol_run;
                    V_NOTIFYDATE := m1.clm_date; --to_date(m1.reg_date,'yyyymmdd');
--                    V_CLAIMSTATUS := '2';  -- close claim        
                    V_LOSSDATE :=  c_paid.loss_date; --to_date(m1.loss_date,'yyyymmdd');
        --            V_CLAIMCAUSE :='0000' ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
                    V_CLAIMCAUSE := c_paid.dis_code ; -- ยังไม่รู้ เพราะไม่สามารถ mapping กับ ICD10 ที่มีได้         
                    V_ICD10CODE1 := c_paid.dis_code;
        --            V_CLAIMAMT := m1.tot_paid;
                    v_cntrec := v_cntrec+1;
                    IF V_CHKREC2 THEN
                        if v_cntrec =1 then
                            V_CLAIMAMT := c_paid.pay_amt + (v_sumpayee - v_sumpaid);
                        else
                            V_CLAIMAMT := c_paid.pay_amt;    
                        end if;                       
                    ELSE
                        V_CLAIMAMT := c_paid.pay_amt;                    
                    END IF;    
                    
                    V_CLAIMAMT := c_paid.pay_amt;          
                    
                    V_TRANSACTIONSTATUS  :='N';
                    V_REFERENCENUMBER    :=null;     
                    V_DEDUCTIBLEAMT :=0;       
                    --V_COVERAGECODE2 :=  p_oic_paph_clm.get_coverage2('GM',c_paid.CLM_TYPE ,v_premcode) ;  --== mapping to table 5            
                    V_ACCOUNTINGDATE := M1.clm_date ;
        --            V_ACCOUNTINGDATE2 := c_paid.pay_date ;
                    V_ACCOUNTINGDATE2 := M1.close_date ;
                    V_COVERAGECODE1 := p_oic_paph_clm.get_coverage1(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M_PAYNO 
                    ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                    V_COVERAGECODE2 := p_oic_paph_clm.get_coverage2(m1.pol_no ,m1.pol_run ,c_paid.fleet_seq, M1.CLM_NO ,M_PAYNO 
                    ,'GM',c_paid.CLM_TYPE ,v_premcode ,V_ICD10CODE1);
                                        
                    p_oic_paph_clm.get_citizen('GM' ,m1.pol_no ,m1.pol_run ,c_paid.fleet_seq ,m1.recpt_seq ,c_paid.loss_date  ,M1.CLM_NO ,M_PAYNO,V_INSUREDNAME ,V_INSUREDCITIZENID);
                    
                    if c_paid.clm_type = 'OPD' then
                        V_TREATMENTTYPE := '1';
                    elsif c_paid.clm_type = 'IPD' then
                        V_TREATMENTTYPE := '2';
                    else
                        V_TREATMENTTYPE := '3';
                    end if;  
                                    
                    INSERT INTO OIC_PAPH_CLAIM
                    ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                    COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                    PROCODURECODE1 ,
                    CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                    VALUES 
                    (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                    V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                    V_PROCODURECODE1 ,
                    V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;

                    INSERT INTO OIC_PAPH_CLAIM_HIST
                    ( COMPANYCODE , MAINCLASS  , SUBCLASS  ,CLAIMNUMBER ,CLAIMGROUP , ACCOUNTINGDATE ,CLAIMSEQ ,
                    COVERAGECODE1 , COVERAGECODE2 , INSUREDSEQ ,  POLICYNUMBER , NOTIFYDATE , LOSSDATE , CLAIMSTATUS , CLAIMCAUSE , ICD10CODE1 ,
                    PROCODURECODE1 ,
                    CLAIMAMT , TRANSACTIONSTATUS , REFERENCENUMBER ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER) 
                    VALUES 
                    (V_COMPANY , V_MAINCLASS  , V_SUBCLASS  ,V_CLAIMNUMBER ,'P' , V_ACCOUNTINGDATE ,V_CLAIMSEQ ,
                    V_COVERAGECODE1 , V_COVERAGECODE2 , V_INSUREDSEQ ,  V_POLICYNUMBER , V_NOTIFYDATE , V_LOSSDATE , V_CLAIMSTATUS , V_CLAIMCAUSE , V_ICD10CODE1 ,
                    V_PROCODURECODE1 ,
                    V_CLAIMAMT , V_TRANSACTIONSTATUS , V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user)          ;
                END LOOP; -- C_paid
                                 
        --        dbms_output.put_line(v_cnt||' clm_no: '||M1.clm_no||' poltype: '||v_poltype||' subclass:'||V_SUBCLASS
        --        ||' clmtype:'||V_CLAIMTYPE||' prem:'||v_premcode||' lossdate:'||V_LOSSDATE);   
                
                IF p_oic_paph_clm.hasINS_data(V_CLAIMNUMBER) THEN
                    V_TRANSACTIONSTATUS2 := 'U';        
                ELSE    
                    V_TRANSACTIONSTATUS2 := 'N';  
                    INSERT INTO OIC_PAPH_INS_CLAIM
                    ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                    INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
                    VALUES 
                    (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                    V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

                    INSERT INTO OIC_PAPH_INS_CLAIM_HIST
                    ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  INSUREDSEQ  ,  POLICYNUMBER ,  INSUREDNAME  ,  
                    INSUREDCITIZENID ,  TREATMENTTYPE ,  DEDUCTIBLEAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
                    VALUES 
                    (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_INSUREDSEQ,V_POLICYNUMBER ,V_INSUREDNAME  ,
                    V_INSUREDCITIZENID ,V_TREATMENTTYPE ,V_DEDUCTIBLEAMT ,V_TRANSACTIONSTATUS2 ,V_REFERENCENUMBER ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);                        
                              
                END IF;
                
                begin
                    select trunc(pay_date) into V_CHEQUEDATE
                    from mis_clmgm_paid a
                    where pay_no = M_PAYNO
                    and (a.pay_no,a.corr_seq) in (select aa.pay_no ,max(aa.corr_seq) from mis_clmgm_paid aa where aa.pay_no = a.pay_no group by aa.pay_no );

                    if V_CHEQUEDATE is null then
                        V_CHEQUEDATE := M1.close_date;
                    end if; 
                exception
                    when no_data_found then
                        V_CHEQUEDATE := M1.close_date;
                    when others then
                        V_CHEQUEDATE := M1.close_date;
                end;    
                
                V_CLAIMPAIDSEQ := 0;
                FOR c_payee in (
                    select pay_no ,pay_seq ,payee_code ,payee_amt ,settle
                    from clm_gm_payee a
                    where pay_no = M_PAYNO and payee_code is not null 
                    and nvl(payee_amt,0) >0 
                ) LOOP
                    if c_payee.settle is null then
                        begin
                            select settle into m_settle
                            from mis_clmgm_paid      
                            where pay_no = M_PAYNO and pay_total >0 and rownum=1;                  
                        exception
                            when no_data_found then
                                m_settle:= null;
                            when others then
                                m_settle:= null;
                        end;
                    else
                        m_settle := c_payee.settle ;
                    end if;                        
                    
                    V_PAIDBY := p_oic_paph_clm.get_paidby('GM',m_settle);     
                    V_CLAIMPAIDSEQ := V_CLAIMPAIDSEQ+1;  
--                    V_CLAIMPAIDSEQ :=c_payee.pay_seq;
                    V_CHEQUENO := null;
                    
                    if V_CLAIMPAIDSEQ >1 then
                        V_PAYEEAMT := c_payee.payee_amt;                                                
                    else
                        V_PAYEEAMT := v_sumpaid ;  --use payee amt from BKI Paid amt
                    end if;                    
                    
                    if V_PAIDBY = 'K' then
                        account.p_acc_acr.get_paid_info(M1.pay_no,'0',M1.prod_type,c_payee.payee_code,c_payee.settle,
                                                      ACR_PAID_TYPE, ACR_PAID_DATE, ACR_BANK_CODE, ACR_BRANCH_CODE, ACR_CHEQUE_NO);
                        V_CHEQUENO := ACR_CHEQUE_NO;                              
                        IF V_CHEQUENO is null THEN
                            V_PAIDBY := 'O' ;
                        END IF;               
                    elsif V_PAIDBY = 'T' then
                        V_CHEQUENO := null;
                    end if;          

                    if V_PAYEEAMT = 0 then
                        V_PAYEEAMT := M1.tot_paid;    
                    end if;
                                                 
                    INSERT INTO OIC_PAPH_PAYMENT
                    ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
                    PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
                    VALUES 
                    (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
                    V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);

                    INSERT INTO OIC_PAPH_PAYMENT_HIST
                    ( COMPANYCODE ,  MAINCLASS  ,  SUBCLASS  ,  CLAIMNUMBER ,  CLAIMPAIDSEQ ,CHEQUEDATE  ,  POLICYNUMBER   ,  
                    PAIDBY ,  CHEQUENO ,  CLAIMAMT ,  TRANSACTIONSTATUS ,  REFERENCENUMBER  ,CONV_DATE ,FR_DATE ,TO_DATE , AS_AT_DATE ,SELECT_DATE ,SELECT_USER ) 
                    VALUES 
                    (V_COMPANY ,V_MAINCLASS  ,V_SUBCLASS  ,V_CLAIMNUMBER ,V_CLAIMPAIDSEQ ,V_CHEQUEDATE ,V_POLICYNUMBER  ,
                    V_PAIDBY ,V_CHEQUENO ,V_PAYEEAMT ,V_TRANSACTIONSTATUS ,V_REFERENCENUMBER  ,V_RECORD_DATE , i_datefr, i_dateto , i_asdate ,v_record_date ,i_user);   
                            
                END LOOP;  -- payee 

            END IF; --- check case out ,paid ,cwp
        END IF; -- v_skip
                         
    END LOOP;
    COMMIT;
    x_message := x_message||' finish@'||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS') ;
--    P_OIC_PAPH_CLM.email_log(x_subject ,x_message);
END GET_GM_CLAIM_V2 ;

FUNCTION check_have_paid(P_CLMNO IN VARCHAR2 ,P_MODE IN VARCHAR2) RETURN BOOLEAN IS
 --P_MODE 1 check has paid ,2 check double paid
    dummyClaim  varchar2(20);
BEGIN
    IF P_MODE = '1' THEN
        select distinct claimnumber into dummyClaim
        from OIC_PAPH_CLAIM
        where claimnumber =P_CLMNO 
        and ClaimGroup  = 'P' and ClaimAmt = 0;
     ELSIF P_MODE = '2' THEN
        select distinct claimnumber into dummyClaim
        from OIC_PAPH_CLAIM
        where claimnumber =P_CLMNO 
        and ClaimGroup  = 'P' ;   
     ELSE
        select distinct clm_no into dummyClaim
        from mis_clm_mas
        where clm_no =P_CLMNO 
        and clm_sts ='3' ;                   
     END IF;   
    
    return true;
EXCEPTION
    WHEN no_data_found THEN
        return false;
    WHEN others THEN
        return false;
END check_have_paid;

FUNCTION check_have_EC(P_CLMNO IN VARCHAR2) RETURN BOOLEAN IS
    dummyClaim  varchar2(20);
BEGIN

    select distinct claimnumber into dummyClaim
    from OIC_PAPH_CLAIM
    where claimnumber =P_CLMNO 
    and ClaimGroup  = 'EC' ;
            
    return true;
EXCEPTION
    WHEN no_data_found THEN
        return false;
    WHEN others THEN
        return false;
END check_have_EC;

PROCEDURE get_PA_TORBOR3(i_datefr IN DATE ,i_dateto IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS

    v_prod  varchar2(10):='PA';
    v_brn   varchar2(5):='01';
--    m_frdate date:='01-oct-16';
--    m_todate date:='31-oct-16';
    m_frdate date:=i_datefr;
    m_todate date:=i_dateto;
    v_frdate varchar2(10);
    v_todate varchar2(10);
    v_payeename varchar2(250);
    v_policy    varchar2(50);
    v_not_date  date;

    v_cnt   number(10):=0;
    v_ricnt  number(10):=0;
    
    v_ins_name  varchar2(250);
    v_fleet_seq number(10);
    v_paid_date date;
    v_receive_date date;
    v_id_card   varchar2(30);
    v_dummy_name   varchar2(250);
    v_ricode  varchar2(30);
    stamp   date:=sysdate;
    -- CLM_TORBOR3.Notify_date คือ วันที่รับเอกสาร / Doc_date 
BEGIN
    v_frdate := to_char(m_frdate , 'yyyymmdd');
    v_todate := to_char(m_todate , 'yyyymmdd');
    dbms_output.put_line('=====Start @'||to_char(stamp,'dd/mm/yy HH24:MI:SS')||'=====');
    FOR X in (
        select  m.sts_key ,m.clm_no,m.pol_no,m.pol_run,m.cus_enq mas_cus_enq, 
                   m.loss_date,m.clm_date, fax_clm_date doc_date,s.tot_res,m.prod_type,m.clm_sts,s.close_date
                   ,recpt_seq
        from    mis_clm_mas m,mis_clm_mas_seq  s
        where to_char(m.clm_date,'yyyymmdd') between V_FRDATE and  V_TODATE
            and m.prod_type in (select p.prod_type from clm_grp_prod p where p.sysid = V_PROD ) 
            and m.clm_br_code like V_BRN
            and m.clm_no = s.clm_no
            and s.corr_seq in (select max(a.corr_seq) from mis_clm_mas_seq a
                                         where a.clm_no = s.clm_no
                                            and  to_char(a.corr_date,'yyyymmdd') <= V_TODATE ) 
           -- and rownum<=100                                
        order by m.clm_no    
    )LOOP
        
        if length(X.pol_no) = 8 and X.pol_run = 0 then
             V_POLICY := substr(X.pol_no,1,2)||'/'||substr(X.pol_no,3);
        else
             pol_end.Disp_no_prn(X.pol_no,nvl(X.pol_run,0),V_POLICY);
        end if;        
    
        for cres in (
            select fleet_seq ,loss_name 
            from mis_cpa_res a 
            where clm_no = X.CLM_NO
            and revise_seq in (select max(aa.revise_seq) from mis_cpa_res aa where aa.clm_no = a.clm_no and 
            trunc(corr_date) <=M_TODATE )
        )loop
            v_ins_name := cres.loss_name;
            v_fleet_seq :=  cres.fleet_seq;
            p_oic_paph_clm.get_Citizen( 'PA' ,X.pol_no ,X.pol_run ,v_fleet_seq ,X.recpt_seq ,X.loss_date 
            ,X.clm_no, null /*i_payno */ ,V_DUMMY_NAME ,V_ID_CARD) ;       
        end loop; --cres
        
        v_cnt := v_cnt+1;
        
--        if X.sts_key is not null then   -- get NOT_DATE
--                begin
--                    select reg_date into v_not_date
--                    from nc_mas a
--                    where clm_no = X.clm_no
--                    and prod_grp ='0' ;                
--                exception
--                    when no_data_found then
--                        v_not_date := null;
--                    when others then
--                        v_not_date := null;
--                end;         
--        end if; -- get NOT_DATE
        v_not_date := X.doc_date;
        
        v_ricnt:=0;
        v_payeename:=null;
        for RI in (
            select   p.clm_no clm_paid,p.pay_no  pay_no,pay_total ,p.pay_date,p.pay_sts,r.ri_code,r.ri_br_code,r.lf_flag,r.ri_type,r.ri_sub_type,r.pay_amt,nvl(p.pay_curr_code,'BHT') curr_code
              from   mis_clm_paid p,mis_cri_paid r
              where (p.pay_no,p.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
                                               where  b.clm_no = p.clm_no
                                               and    b.pay_no = p.pay_no
                                               and    b.pay_sts = '0'
                                               and    b.state_flag = '1'   -- Pure statement
                                               and nvl(pay_total ,0) >0
            --                                   and    to_char(b.corr_date,'yyyymmdd') between to_char(:Pdate1,'yyyymmdd') and to_char(:Pdate2,'yyyymmdd')
                                               group by b.pay_no) 
              and    p.pay_sts        = '0'
              and    p.state_flag     =  '1'   -- Pure statement
              and    r.clm_no          = p.clm_no
              and    r.pay_no         = p.pay_no
              and    r.pay_sts         = p.pay_sts
              and    r.corr_seq        = p.corr_seq
              and p.clm_no = X.clm_no
            order by p.pay_no        
        )loop
            v_ricnt := v_ricnt+1;
            
            if v_ricnt =1 then --get v_payeename
                begin
                    select payee_name into v_payeename
                    from mis_clm_payee a
                    where clm_no = X.clm_no
                    and pay_no = RI.pay_no 
                    and nvl(corr_seq,0) in (select nvl(max(aa.corr_seq),0) from mis_clm_payee aa where aa.pay_no = a.pay_no);                
                exception
                    when no_data_found then
                        v_payeename := null;
                    when others then
                        v_payeename := null;
                end;        
            end if; -- v_payeename
            
            v_ricode := RI.ri_code||RI.ri_br_code||RI.lf_flag||RI.ri_type||RI.ri_sub_type;
            v_paid_date := RI.pay_date;
            begin
                select max(settle_date) into v_receive_date
                from  rsl_mas
                where  ri_code     = RI.ri_code
                and  ri_br_code  = RI.ri_br_code
                and  type        = '0'
                and  dept_no     = '04'
                and  acc_type    = '06'
                and  q_mm        = '04'
                and  settle_date is not null 
                and  vou_no      is not null
                and  curr_code   = RI.curr_code
                group by ri_code,ri_br_code,type,dept_no,acc_type,q_mm;
            exception 
                when no_data_found   then v_receive_date := null;
                when others   then v_receive_date := null;
            end;            
--            dbms_output.put_line('no. '||v_cnt||' clmno='||X.clm_no||' pol='||V_POLICY||' v_ins_name='||v_ins_name||' ID='||V_ID_CARD||' payee='||v_payeename||' pay_no='||RI.pay_no||' ResAmt='||X.tot_res||' PayAmt='||RI.pay_total||' riCode='||v_ricode
--            ||' riAmt='||RI.pay_amt||' recv_date='||v_receive_date||' clm_date='||X.clm_date||' not_date='||v_not_date);
            
            Insert into ALLCLM.CLM_TORBOR3
            (CLM_PROD_GRP, SELECT_FR, SELECT_TO, CLM_SEQ, CLM_NO, CLM_DATE, LOSS_DATE, POLICY_NO, IDCARD_NO, CUS_NAME ,PAYEE_NAME, EST_AMT, PAID_AMT, RICODE, RI_PAID_AMT, RECEIVE_DATE
            ,CLOSE_DATE ,FLEET_SEQ ,INSURE_NAME ,NOTIFY_DATE ,PAID_DATE)
            Values(v_prod ,m_frdate ,m_todate ,v_cnt ,X.clm_no ,X.clm_date ,x.loss_date ,V_POLICY ,V_ID_CARD ,X.mas_cus_enq ,v_payeename ,X.tot_res ,RI.pay_total ,V_RICODE ,RI.pay_amt,V_RECEIVE_DATE
            ,X.close_date ,v_fleet_seq ,V_INS_NAME ,v_not_date ,v_paid_date);
        end loop; --RI
        
        if v_ricnt =0 then
            --dbms_output.put_line('no. '||v_cnt||' clmno='||X.clm_no||' pol='||V_POLICY||' v_ins_name='||v_ins_name||' ID='||V_ID_CARD||' ResAmt='||X.tot_res||' clm_date='||X.clm_date||' not_date='||v_not_date);        

            Insert into ALLCLM.CLM_TORBOR3
            (CLM_PROD_GRP, SELECT_FR, SELECT_TO, CLM_SEQ, CLM_NO, CLM_DATE, LOSS_DATE, POLICY_NO, IDCARD_NO, CUS_NAME ,PAYEE_NAME , EST_AMT, PAID_AMT, RICODE, RI_PAID_AMT, RECEIVE_DATE
            ,CLOSE_DATE ,FLEET_SEQ ,INSURE_NAME ,NOTIFY_DATE)
            Values(v_prod ,m_frdate ,m_todate ,v_cnt ,X.clm_no ,X.clm_date ,x.loss_date ,V_POLICY ,V_ID_CARD ,X.mas_cus_enq ,v_payeename ,X.tot_res ,null ,null ,null,null
            ,null ,v_fleet_seq ,V_INS_NAME ,v_not_date);
        end if;
        if mod(v_cnt,1000) = 0 then COMMIT; end if;
    END LOOP; -- X
    COMMIT;
    stamp := sysdate;
    dbms_output.put_line('=====Complete  @'||to_char(stamp,'dd/mm/yy HH24:MI:SS')||'=====');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        o_rst :='Error: '||sqlerrm;

END get_PA_TORBOR3;
     

PROCEDURE get_GM_TORBOR3(i_datefr IN DATE ,i_dateto IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2) IS

    v_prod  varchar2(10):='GM';
    v_brn   varchar2(5):='01';
--    m_frdate date:='01-oct-16';
--    m_todate date:='31-oct-16';
    m_frdate date:=i_datefr;
    m_todate date:=i_dateto;
    v_frdate varchar2(10);
    v_todate varchar2(10);
    v_payeename varchar2(250);
    v_policy    varchar2(50);
    v_not_date  date;
    v_loss_date date;
    v_cnt   number(10):=0;
    v_ricnt  number(10):=0;
    
    v_ins_name  varchar2(250);
    v_fleet_seq number(10);
    v_paytotal  number(13,2);
    v_paid_date date;
    v_receive_date date;
    v_id_card   varchar2(30);
    v_dummy_name   varchar2(250);
    v_ricode  varchar2(30);
    stamp   date:=sysdate;
    
    -- CLM_TORBOR3.Notify_date คือ วันที่รับเอกสาร / Doc_date 
BEGIN
    v_frdate := to_char(m_frdate , 'yyyymmdd');
    v_todate := to_char(m_todate , 'yyyymmdd');
    dbms_output.put_line('=====Start @'||to_char(stamp,'dd/mm/yy HH24:MI:SS')||'=====');
    FOR X in (
        select  m.sts_key ,out_clm_no ,m.clm_no,m.pol_no,m.pol_run,m.cus_enq mas_cus_enq, 
                   m.loss_date,m.clm_date ,fax_clm_date doc_date ,s.tot_res,m.prod_type,m.clm_sts,s.close_date
                   ,recpt_seq
        from    mis_clm_mas m,mis_clm_mas_seq  s
        where to_char(m.clm_date,'yyyymmdd') between V_FRDATE and  V_TODATE
            and m.prod_type in (select p.prod_type from clm_grp_prod p where p.sysid = V_PROD ) 
            and m.clm_br_code like V_BRN
            and m.clm_no = s.clm_no
            and s.corr_seq in (select max(a.corr_seq) from mis_clm_mas_seq a
                                         where a.clm_no = s.clm_no
                                            and  to_char(a.corr_date,'yyyymmdd') <= V_TODATE ) 
           -- and rownum<=100                                
        order by m.clm_no    
    )LOOP
        
        if length(X.pol_no) = 8 and X.pol_run = 0 then
             V_POLICY := substr(X.pol_no,1,2)||'/'||substr(X.pol_no,3);
        else
             pol_end.Disp_no_prn(X.pol_no,nvl(X.pol_run,0),V_POLICY);
        end if;        
    
        for cres in (
            select fleet_seq ,title||' '||name loss_name ,loss_date
            from clm_medical_res a 
            where clm_no = X.CLM_NO
            and state_seq in (select max(aa.state_seq) from clm_medical_res aa where aa.clm_no = a.clm_no and 
            trunc(corr_date) <=M_TODATE )
        )loop
            v_ins_name := cres.loss_name;
            v_fleet_seq :=  cres.fleet_seq;
            v_loss_date := cres.loss_date;
            p_oic_paph_clm.get_Citizen( 'GM' ,X.pol_no ,X.pol_run ,v_fleet_seq ,X.recpt_seq ,v_loss_date 
            ,X.clm_no, null /*i_payno */ ,V_DUMMY_NAME ,V_ID_CARD) ;       
        end loop; --cres
        
        v_cnt := v_cnt+1;
        
        v_not_date := X.doc_date;
        
        v_ricnt:=0;
        v_payeename:=null;
        for RI in (
--            select   p.clm_no ,p.pay_no  pay_no,pay_total-rec_total  pay_total ,p.pay_date ,r.ri_code,r.ri_br_code,r.lf_flag,r.ri_type,r.ri_sub_type,r.pay_amt,'BHT' curr_code
--              from   mis_clmgm_paid p,mis_cri_paid r
--              where (p.pay_no,p.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clmgm_paid b
--                                               where  b.clm_no = p.clm_no
--                                               and    b.pay_no = p.pay_no
--                                               and    b.print_type = '1'   -- Pure statement
--                                               and nvl(pay_total ,0) >0
--            --                                   and    to_char(b.corr_date,'yyyymmdd') between to_char(:Pdate1,'yyyymmdd') and to_char(:Pdate2,'yyyymmdd')
--                                               group by b.pay_no) 
--              and    p.print_type     =  '1'   -- Pure statement
--              and    r.clm_no          = p.clm_no
--              and    r.pay_no         = p.pay_no
--              and    r.corr_seq        = p.corr_seq
--              and p.clm_no = X.clm_no
--            order by p.pay_no        
            select  distinct  p.clm_no clm_paid,p.pay_no pay_no,p.date_paid,r.ri_code,r.ri_br_code,r.lf_flag,r.ri_type,r.ri_sub_type,r.pay_amt
              from   clm_gm_paid p,mis_cri_paid r
            where 
            -- to_char(p.date_paid,'yyyymmdd') between to_char(:Pdate1,'yyyymmdd') and to_char(:Pdate2,'yyyymmdd') and 
                         p.corr_seq  = (select max(b.corr_seq) from clm_gm_paid b
                                                where b.clm_no         = p.clm_no and
                                             --             b.clm_pd_flag = 'O' and
                                                          b.fleet_seq       = p.fleet_seq    and
                                                          b.bene_code   = p.bene_code and
                                                          b.dis_code       = p.dis_code     and
                                                        --  to_char(b.corr_date,'yyyymmdd') between to_char(:Pdate1,'yyyymmdd') and to_char(:Pdate2,'yyyymmdd') and 
                                                          b.loss_date = p.loss_date
                                                group by b.clm_no)
              and    r.clm_no          = p.clm_no
              and    r.pay_no          = p.pay_no
              and    r.corr_seq        = p.corr_seq
              and p.clm_no = X.clm_no
            order by p.pay_no            
        )loop
            v_ricnt := v_ricnt+1;
            
            if v_ricnt =1 then --get v_payeename
                begin
                    select payee_name into v_payeename
                    from clm_gm_payee a
                    where clm_no = X.clm_no
                    and pay_no = RI.pay_no ;                
                exception
                    when no_data_found then
                        v_payeename := null;
                    when others then
                        v_payeename := null;
                end;        
                
                begin
                    select pay_total-rec_total ,pay_date  into v_paytotal ,v_paid_date  
                    from mis_clmgm_paid a
                    where clm_no = X.clm_no
                    and pay_no = RI.pay_no 
                    and a.corr_seq in (select max(b.corr_seq) from mis_clmgm_paid b
                                               where   b.pay_no = a.pay_no
                    ) ;                
                exception
                    when no_data_found then
                        v_paytotal := 0;
                        v_paid_date := X.close_date;
                    when others then
                        v_paytotal := 0;
                        v_paid_date := X.close_date;
                end;                      
            end if; -- v_payeename
            
            v_ricode := RI.ri_code||RI.ri_br_code||RI.lf_flag||RI.ri_type||RI.ri_sub_type;
            
            begin
                select max(settle_date) into v_receive_date
                from  rsl_mas
                where  ri_code     = RI.ri_code
                and  ri_br_code  = RI.ri_br_code
                and  type        = '0'
                and  dept_no     = '04'
                and  acc_type    = '06'
                and  q_mm        = '04'
                and  settle_date is not null 
                and  vou_no      is not null
                and  curr_code   = 'BHT'
                group by ri_code,ri_br_code,type,dept_no,acc_type,q_mm;
                
            exception 
                when no_data_found   then v_receive_date := null;
                when others   then v_receive_date := null;
            end;            
--            dbms_output.put_line('no. '||v_cnt||' clmno='||X.clm_no||' pol='||V_POLICY||' v_ins_name='||v_ins_name||' ID='||V_ID_CARD||' payee='||v_payeename||' pay_no='||RI.pay_no||' ResAmt='||X.tot_res||' PayAmt='||RI.pay_total||' riCode='||v_ricode
--            ||' riAmt='||RI.pay_amt||' recv_date='||v_receive_date||' clm_date='||X.clm_date||' not_date='||v_not_date);
            
            Insert into ALLCLM.CLM_TORBOR3
            (CLM_PROD_GRP, SELECT_FR, SELECT_TO, CLM_SEQ, CLM_NO, CLM_DATE, LOSS_DATE, POLICY_NO, IDCARD_NO, CUS_NAME ,PAYEE_NAME, EST_AMT, PAID_AMT, RICODE, RI_PAID_AMT, RECEIVE_DATE
            ,CLOSE_DATE ,FLEET_SEQ ,INSURE_NAME ,NOTIFY_DATE ,PAID_DATE)
            Values(v_prod ,m_frdate ,m_todate ,v_cnt ,X.clm_no ,X.clm_date ,v_loss_date ,V_POLICY ,V_ID_CARD ,X.mas_cus_enq ,v_payeename ,X.tot_res ,v_paytotal ,V_RICODE ,RI.pay_amt,V_RECEIVE_DATE
            ,X.close_date ,v_fleet_seq ,V_INS_NAME ,v_not_date ,v_paid_date);
        end loop; --RI
        
        if v_ricnt =0 then
            --dbms_output.put_line('no. '||v_cnt||' clmno='||X.clm_no||' pol='||V_POLICY||' v_ins_name='||v_ins_name||' ID='||V_ID_CARD||' ResAmt='||X.tot_res||' clm_date='||X.clm_date||' not_date='||v_not_date);        

            Insert into ALLCLM.CLM_TORBOR3
            (CLM_PROD_GRP, SELECT_FR, SELECT_TO, CLM_SEQ, CLM_NO, CLM_DATE, LOSS_DATE, POLICY_NO, IDCARD_NO, CUS_NAME ,PAYEE_NAME , EST_AMT, PAID_AMT, RICODE, RI_PAID_AMT, RECEIVE_DATE
            ,CLOSE_DATE ,FLEET_SEQ ,INSURE_NAME ,NOTIFY_DATE)
            Values(v_prod ,m_frdate ,m_todate ,v_cnt ,X.clm_no ,X.clm_date ,v_loss_date ,V_POLICY ,V_ID_CARD ,X.mas_cus_enq ,v_payeename ,X.tot_res ,null ,null ,null,null
            ,null ,v_fleet_seq ,V_INS_NAME ,v_not_date);
        end if;
        if mod(v_cnt,1000) = 0 then COMMIT; end if;
    END LOOP; -- X
    COMMIT;
    stamp := sysdate;
    dbms_output.put_line('=====Complete  @'||to_char(stamp,'dd/mm/yy HH24:MI:SS')||'=====');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        o_rst :='Error: '||sqlerrm;

END get_GM_TORBOR3;
     

END P_OIC_PAPH_CLM;
/
