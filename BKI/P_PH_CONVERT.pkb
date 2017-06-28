CREATE OR REPLACE PACKAGE BODY P_PH_CONVERT AS
/******************************************************************************
 NAME: ALLCLM.P_PH_CONVERT
   PURPOSE:     สำหรับการ Convert to old table(BKIAPP) และ ส่วนการ post Data
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        1/2/2017      2702       1. Created this package.
******************************************************************************/

FUNCTION GEN_STATENO(v_PROD_TYPE IN VARCHAR2 ) RETURN VARCHAR2 IS
    v_stateno  VARCHAR2(20);
BEGIN    
        BEGIN
            select TO_CHAR(TO_NUMBER(RUN_NO) + 1) into v_stateno
            from clm_control_std a
            where key ='CMSO'||TO_CHAR(SYSDATE,'YYYY')||'GM'
            FOR UPDATE OF KEY ,RUN_NO;
        EXCEPTION
            WHEN  NO_DATA_FOUND THEN
                v_stateno := null;            
            WHEN  OTHERS THEN
                v_stateno := null;
        END;       
                    
       if v_stateno is not null  then  
        BEGIN
            update clm_control_std a
            set run_no = v_stateno
            where  key ='CMSO'||TO_CHAR(SYSDATE,'YYYY')||'GM';
        EXCEPTION
            WHEN  OTHERS THEN
                ROLLBACK;
                v_stateno := null;
        END;  
        COMMIT;
       else
        ROLLBACK;
       end if;    
        Return v_stateno;
END;    --End GEN_STATENO
 

FUNCTION VALIDATE_INDV(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
 CURSOR c_clm IS select clm_no ,prod_type, p_non_pa_approve.GET_CLMSTS(clm_no) clm_sts ,clm_user from nc_mas 
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
 
 if c_rec.clm_user is null then
 P_RST := c_rec.clm_no||': ไม่พบ เจ้าของเรื่อง' ; 
 return false;  
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

FUNCTION POST_ACCTMP(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
-- CURSOR c_clm IS select clm_no ,pol_no ,pol_run ,nvl(policy_number,pol_no||pol_run) policy_number ,prod_grp ,prod_type ,th_eng ,mas_cus_code cus_code ,agent_code ,agent_seq ,clm_br_code br_code ,channel ,clm_men 
-- from mis_clm_mas 
-- where clm_no = vClmNo 
-- ; 
-- c_rec c_clm%ROWTYPE; 
 
 
 v_chk Boolean:=false; 
 V_STATUS_RST varchar2(200); 
 V_RESULT_x  varchar2(200); 
 V_POSTGL_STS varchar2(200); 
 m_rst varchar2(200); 
 inw_type varchar2(1); 
-- b1 varchar2(10); 
-- b2 varchar2(10); 
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
     
    --b1 := GET_BATCHNO('MI'); 

    --dbms_output.put_line('b1 = '||b1); 
    --======= Step Insert Data ======== 
    for c_rec in ( 
    select a.clm_no ,a.pol_no ,a.pol_run ,a.end_seq ,a.pol_no||a.pol_run policy_number ,a.prod_grp ,a.prod_type 
    ,nvl(t_e,'T') th_eng ,mas_cus_code cus_code ,'' agent_code ,'' agent_seq ,'01' br_code 
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
            ,salvage_flag ,deduct_flag ,recovery_flag ,salvage_amt ,deduct_amt ,recovery_amt ,payee_type
            ,bank_code ,bank_br_code ,acc_no ,acc_name 
--            ,P_NON_PA_APPROVE.CONVERT_PAYMENT_METHOD(settle) settle 
            ,settle
            ,curr_code
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

                
                v_DEDUCT_AMT := 0; 
                V_REC_TOTAL := 0;
                V_SAL_TOTAL := 0; 
                V_REC_TOTAL := 0;
                 
                CNT_P := CNT_P +1;
                v_ADV_AMT := 0; 
                V_PAY_TOTAL := p3.payee_amt ;
                V_PREM_OFFSET := p3.PREM_OFFSET;
                IF V_PREM_OFFSET is not null THEN v_less_other := '01'; END IF;

                V_SUM_SAL := 0;
                V_SUM_PAY := 0;
                V_SUM_DEC := 0;
                V_SUM_REC := 0;

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
--                    V_SAL_TOTAL := V_SUM_SAL;  
                    V_SAL_TOTAL := p3.salvage_amt;  
                ELSIF p3.salvage_flag = '2' THEN --M     
                    V_SAL_TOTAL := p3.salvage_amt * -1;  
                ELSE
                    V_SAL_TOTAL :=0;
                END IF;       

                IF p3.recovery_flag = '1' THEN --P 
--                    V_REC_TOTAL := V_SUM_REC;
                    V_REC_TOTAL := p3.recovery_amt;
                ELSIF p3.recovery_flag = '2' THEN --M     
                    V_REC_TOTAL := p3.recovery_amt * -1;   
                ELSE
                    V_REC_TOTAL := 0;
                END IF;    
                                                             
                IF p3.deduct_flag = '1' THEN --P
--                    v_DEDUCT_AMT := V_SUM_DEC;    
                    v_DEDUCT_AMT := p3.deduct_amt ;    
                ELSIF p3.deduct_flag = '2' THEN --M
                    v_DEDUCT_AMT := p3.deduct_amt * -1;                    
                ELSE       
                    v_DEDUCT_AMT := 0;                      
                END IF;    
                                
                if v_chk_adv = false then
                    IF p3.payee_type = '01' THEN
                        v_ADV_AMT := V_SUM_PAYEE - (V_SUM_PAY - V_SUM_SAL - V_SUM_DEC- V_SUM_REC);
                        if v_ADV_AMT <> 0 then
                            v_chk_adv := true;
                        end if;
                    END IF;
                end if;
                --===========**CALULATE Deduct Salvage **===========   
               
                IF (v_payeecurr <> v_paidcurr)  THEN -- case different Currency
                    v_ADV_AMT := 0;
                END IF;    
                
                 --*** Insert CLM_GM_RECOV
                IF nvl(v_ADV_AMT,0) > 0 THEN
                    NMTR_PACKAGE.SET_CLM_GM_RECOV(c_rec.clm_no ,p1.pay_no ,v_ADV_AMT ,V_RESULT_x );
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
                                          
                P_CLAIM_ACR.Post_acc_clm_payee_pagm( c_rec.prod_grp /* P_prod_grp  IN  acc_clm_payee_tmp.prod_grp%type */,  
                                    
                c_rec.prod_type /* P_prod_type  IN  acc_clm_payee_tmp.prod_type%type */,
                                                                                
                p1.pay_no /* P_payno      IN  acc_clm_payee_tmp.payment_no%type */,
                                                                                
                p3.pay_seq /* P_seq        IN  acc_clm_payee_tmp.seq%type */,
                                                                                
                '01' /* P_doc_type   IN  acc_clm_payee_tmp.doc_type%type */, --Loss motor = 01,02 expense 
                                                                                
                X_CURRCODE /* P_curr_code  IN  acc_clm_payee_tmp.curr_code%type */,                                                                               
                                                                                
                V_PAY_TOTAL /* P_payee_amt  IN  acc_clm_payee_tmp.payee_amt%type */,
                                                                                
                p3.payee_code /* P_payee_code IN  acc_clm_payee_tmp.payee_code%type */,
                                                                                
                v_title /* P_title      IN  acc_clm_payee_tmp.title%type */,
                                                                                
                v_name /* P_name       IN  acc_clm_payee_tmp.name%type */, 
                                                                                
                '08' /* P_dept_no    IN  acc_clm_payee_tmp.dept_no%type */,
                                                                                
                M_PAIDBY_PAYMENT /* P_batch_no   IN  acc_clm_payee_tmp.batch_no%type */,
                                                                                
                nvl(v_DEDUCT_AMT,0) /* P_deduct_amt IN  acc_clm_payee_tmp.deduct_amt%type */,
                                                                                
                v_ADV_AMT /* P_adv_amt    IN  acc_clm_payee_tmp.adv_amt%type */,
                                                                                
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
                                                                                           
                V_RESULT2 /* P_msg       Out varchar2*/ ) ;      --35
                                                                             
                if v_result2 is not null then rollback; P_RST:= v_result2||' in P_CLAIM_ACR.Post_acc_clm_payee_tmp'; return false; end if;  
                                           
                dbms_output.put_line('pass post acc payee tmp ! '||p3.payee_code);              
            end loop;   -- end loop payee  P3
            COMMIT; -- post ACC_CLM_TEMP b4 call post GL  
                        
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
END POST_ACCTMP;  


FUNCTION APPROVE_PAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2 ,v_apprv_user IN varchar2 ,v_remark IN varchar2 
,v_rst OUT VARCHAR2) RETURN boolean IS


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
 v_rst2 varchar2(250);
BEGIN

    BEGIN
        select pay_sts into v_lastPaySTS
        from nc_payment_apprv a
        where a.clm_no = v_clmno and a.pay_no = v_payno
        and a.trn_seq in (select max(aa.trn_seq) from nc_payment_apprv aa where aa.clm_no =a.clm_no and aa.pay_no = a.pay_no) 
        and pay_no =v_payno ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_lastPaySTS := null;
    WHEN OTHERS THEN
        v_lastPaySTS := null;
    END; 

 
--
--    BEGIN
--        select key into v_chkApproved
--        from clm_constant
--        where key like 'PHSTSAPPRV%'
--        and key = v_lastPaySTS 
--        and remark2 = 'APPRV' ;
--    EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--        v_chkApproved := null;
--    WHEN OTHERS THEN
--        v_chkApproved := null;
--    END; 
    
    IF v_lastPaySTS <> 'PHSTSAPPRV03' THEN
        v_rst := 'เลขที่จ่ายนี้ไม่ใช่สถานะ Approve!!'; 
        dbms_output.put_line('in validate Last ApproveStatus: '||v_rst); 
        return false;            
    END IF;
     
--     if v_chkApproved is not null then
--        v_rst := 'เลขที่จ่ายนี้มีการอนุมัติไปแล้ว!!'; 
--        dbms_output.put_line('in validate Last ApproveStatus: '||v_rst); 
--        return false;        
--     end if;

 
    if v_sts in ('PHSTSAPPRV03' ,'PHSTSAPPRV06') then
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
                         
        if v_payeeamt <=0 then
        v_rst := 'Cannot Approve payee amt <> 0'; 
        return false;
        end if;      
    end if;

    if v_sts in ('PHSTSAPPRV03' ,'PHSTSAPPRV04' ,'PHSTSAPPRV06') then
    v_apprv_date := sysdate;
    else
    v_apprv_date := null;
    end if;


--    if v_sts in ('NONPASTSAPPRV03') then --- mark close claim
--        if not P_NON_PA_CLM_PAYMENT.update_end_payment(v_clmno,v_payno,v_sts,v_rst) then
--            return false;
--        end if;
--        P_NON_PA_CLM_PAYMENT.save_oic_payment_seq(v_clmno,v_payno,'I');
--    end if;
    
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
     
     if v_sts in ('PHSTSAPPRV03')  AND v_payeeamt >0 then -- When Approve Convert to BKIAPP
         -- new Paperless 
         IF not p_ph_convert.POST_ACCTMP(v_clmno, v_payno , v_apprv_user ,v_rst) THEN --POST ACR
--             delete nc_payment_apprv a
--             where clm_no = v_clmno and pay_no = v_payno
--             and trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = a.sts_key and b.pay_no = a.pay_no); 
--             COMMIT; 
             v_rst2 := p_ph_convert.update_status_error( v_payno , v_apprv_user ,v_rst);  
             dbms_output.put_line('in Auto Post false: '||v_rst); 
             return false;
         END IF; 
         dbms_output.put_line('after AUTO_POST');
     
--         IF not p_non_pa_approve.AFTER_POST(v_clmno, v_payno , v_apprv_user,v_rst) THEN --POST ACR
--             v_rst2 := p_ph_convert.update_status_error( v_payno , v_apprv_user ,v_rst);             
--             dbms_output.put_line('in AFTER POST false: '||v_rst); 
--             return false;
--         END IF; 
--         dbms_output.put_line('End after POST');
         --EMAIL_NOTICE_APPRV(v_clmno ,v_payno ,v_sts);

         IF not p_ph_convert.SET_SETTLEDATE(v_clmno, v_payno , v_apprv_user,v_rst) THEN --Stamp Settle Date for confirm Actual Payment Date when issue monthly report
             --ROLLBACK; 
             --P_RST := 'in SET_SETTLE false: '||v_rst;
             v_rst2 := p_ph_convert.update_status_error( v_payno , v_apprv_user ,v_rst);            
             dbms_output.put_line('in SET_SETTLE false: '||v_rst); 
             return false;
         END IF;  
                  
          v_rst2 := p_ph_convert.UPDATE_STATUS_ACR( v_payno , v_apprv_user );
          
     end if;
     
     return true;


EXCEPTION
 WHEN OTHERS THEN
    v_rst := 'error APPROVE_PAYMENT:'||sqlerrm; 
    ROLLBACK;
    return false; 
END APPROVE_PAYMENT;

FUNCTION UPDATE_STATUS_ACR(v_payno in varchar2 ,v_clm_user in varchar2 ) RETURN VARCHAR2 IS
    v_sts_seq number:=0;
    v_sts_seq_m number:=0;
    v_trn_seq number:=0;
    chk_success boolean:=false;
    v_stskey number(20);
    v_chk_med    varchar2(20):=null;
    v_clmno varchar2(20);
    dumm_rst    boolean;
    v_rst2  varchar2(200);
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
           (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,'PHSTSAPPRV11' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
           c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , c1.APPROVE_ID ,c1.APPROVE_DATE , c1.PROD_GRP, c1.PROD_TYPE, 
           c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, c1.APPRV_FLAG ,sysdate ,'Approved: Claim data Post to ACC Temp wait for AutoPost ACR at Night');           
                                      
                chk_success := true;
                v_clmno := c1.clm_no;
                
            dumm_rst := NC_CLNMC908.UPDATE_STATUS(c1.STS_KEY ,'NCPAYSTS' ,'NCPAYSTS11' ,v_clm_user ,'Approved: Claim data Post to ACC Temp wait for AutoPost ACR at Night' ,v_rst2);
            
            dumm_rst := NC_CLNMC908.UPDATE_NCPAYMENT(c1.STS_KEY ,c1.clm_no ,c1.pay_no ,'NCPAYSTS11' ,'Approved: Claim data Post to ACC Temp wait for AutoPost ACR at Night' 
            ,c1.APPRV_FLAG  ,c1.CLM_MEN  ,v_clm_user ,c1.APPROVE_ID ,c1.PAY_AMT ,v_rst2);                
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
        UPDATE NC_MAS
        SET APPROVE_STATUS = 'PHSTSAPPRV11'
        WHERE CLM_NO = v_clmno;
            
        COMMIT;return null ; 
    END IF;
    
    return null;
    
END UPDATE_STATUS_ACR;

FUNCTION UPDATE_STATUS_ERROR(v_payno in varchar2 ,v_clm_user in varchar2 ,v_rst in varchar2 ) RETURN VARCHAR2 IS
    v_sts_seq number:=0;
    v_sts_seq_m number:=0;
    v_trn_seq number:=0;
    chk_success boolean:=false;
    v_stskey number(20);
    v_chk_med    varchar2(20):=null;
    v_clmno varchar2(20);
    dumm_rst    boolean;
    v_rst2  varchar2(200);    
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
           (c1.clm_no ,c1.pay_no ,c1.CLM_SEQ ,c1.trn_seq+1 ,'PHSTSAPPRV80' , c1.PAY_AMT, c1.TRN_AMT, c1.CURR_CODE, c1.CURR_RATE, 
           c1.STS_DATE, sysdate, c1.CLM_MEN, v_clm_user , null ,null , c1.PROD_GRP, c1.PROD_TYPE, 
           c1.SUBSYSID, c1.STS_KEY, c1.TYPE, c1.SUB_TYPE, null ,sysdate ,v_rst);           
                                      
                chk_success := true;
                v_clmno := c1.clm_no;
            dumm_rst := NC_CLNMC908.UPDATE_STATUS(c1.STS_KEY ,'NCPAYSTS' ,'NCPAYSTS80' ,v_clm_user ,'' ,v_rst2);
            
            dumm_rst := NC_CLNMC908.UPDATE_NCPAYMENT(c1.STS_KEY ,c1.clm_no ,c1.pay_no ,'NCPAYSTS80' ,'' 
            ,null  ,c1.CLM_MEN  ,v_clm_user ,null ,c1.PAY_AMT ,v_rst2);      
                            
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
        UPDATE NC_MAS
        SET APPROVE_STATUS = 'PHSTSAPPRV80'
        WHERE CLM_NO = v_clmno;
                
        COMMIT;return null ; 
    END IF;
    
    return null;
    
END UPDATE_STATUS_ERROR;

FUNCTION CONV_PH_OPEN(v_clmno in varchar2,v_payno in varchar2  ,v_sts in varchar2
    , v_err_message out varchar2) RETURN BOOLEAN IS 
    v_claim_status VARCHAR2(20); 
    v_dummy_clm  VARCHAR2(20); 
    v_MAIN_CLASS varchar2(2);  
    v_COV_NO varchar2(15);  v_COV_SEQ number(2);  
    v_POL_YR varchar2(10);  v_BR_CODE varchar2(5);  v_PROD_TYPE varchar2(5);  v_prod_grp varchar2(5); 
    v_CHANNEL varchar2(2);  
    v_MAS_CUS_CODE varchar2(20);  v_MAS_CUS_SEQ number(3); 
    v_MAS_CUS_ENQ     varchar2(100);      
    v_CURR_CODE varchar2(5);  
    v_CURR_RATE number;  v_CO_TYPE varchar2(2);  v_CO_RE varchar2(2); 
    v_BKI_SHR number;  v_AGENT_CODE varchar2(5);  v_AGENT_SEQ varchar2(5);   
    v_TH_ENG  varchar2(2); 
    v_ALC_RE varchar2(2); v_UNNAME_POL varchar2(2); v_MAS_SUM_INS number;  v_RECPT_SUM_INS number; 
    v_FR_DATE    DATE; v_TO_DATE    DATE; 
    v_Close_date    DATE; v_cwp_remark varchar2(250);
    v_invoice    varchar2(1);
    v_fax    varchar2(1);
    v_sum_res number;
    v_sum_paid    number;    
    v_max_corrseq   number(5):=0;
    vsysdate    date:=sysdate;
    v_state_no  varchar2(20);
    v_max_stateseq   number(5):=0;
    v_max_criseq   number(5):=0;
    v_hpt_code  varchar2(20);
    o_inc  varchar2(2);
    o_recpt   varchar2(2);
    o_inv  varchar2(2);
    o_ost  varchar2(2);
    o_dead   varchar2(2); 
BEGIN
    begin -- check mis_clm_mas
        select clm_no into v_dummy_clm
        from mis_clm_mas 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_dummy_clm := null;
        when others then
            v_dummy_clm := null;
    end;  -- check mis_clm_mas

    begin -- max corr_seq
        select nvl(max(corr_seq)+1,0) into v_max_corrseq
        from mis_clm_mas_seq 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_max_corrseq := 0;
        when others then
            v_max_corrseq := 0;
    end;  -- max corr_seq

    begin -- max v_max_stateseq
        select  max(state_no) into v_state_no
        from clm_medical_res 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_state_no := null;
        when others then
            v_state_no := null;
    end;  -- max v_max_stateseq    
        
    begin -- max v_max_stateseq
        select nvl(max(state_seq)+1,0) into v_max_stateseq
        from clm_medical_res 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_max_stateseq := 0;
        when others then
            v_max_stateseq := 0;
    end;  -- max v_max_stateseq    

    begin -- max v_max_criseq
        select nvl(max(corr_seq)+1,0) into v_max_criseq
        from mis_cri_res 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_max_criseq := 0;
        when others then
            v_max_criseq := 0;
    end;  -- max v_max_criseq    
          
    dbms_output.put_line ('v_dummy_clm:'||v_dummy_clm);
     
    if v_dummy_clm is null then
        for Cmas in (
          select STS_KEY ,CLM_NO, 'M' MAIN_CLASS, POL_NO, RECPT_SEQ, CLM_YR, POL_YR,'01' BR_CODE, MAS_CUS_CODE, 
               MAS_CUS_SEQ,MAS_CUS_NAME MAS_CUS_ENQ, CUS_CODE, CUS_SEQ,CUS_NAME CUS_ENQ, MAS_SUM_INS, RECPT_SUM_INS, 
              p_ph_clm.get_SUM_RES(clm_no ,null) TOT_RES,0 TOT_PAID,0 TOT_DEDUCT,0 TOT_RECOV, FR_DATE, TO_DATE, CURR_CODE, CURR_RATE, 
              '' CO_TYPE,'' CO_RE, BKI_SHR, '' AGENT_CODE,'T' TH_ENG, trunc(REG_DATE) reg_date, trunc(CLM_DATE) clm_date, trunc(LOSS_DATE) loss_date, LOSS_TIME, 
              CLM_USER CLM_MEN,CLM_USER CLM_STAFF ,'' PAID_STAFF,'' RECOV_STS,'' POL_COV,p_ph_convert.CONV_CLMSTS(claim_status) CLM_STS, ALC_RE,'' CLM_CURR_CODE,'' CLM_CURR_RATE, '' SHR_TYPE, 
               '' AGENT_SEQ, END_SEQ, POL_RUN, CHANNEL, PROD_GRP, PROD_TYPE, '01' CLM_BR_CODE,
               trunc(FAX_CLM_DATE) FAX_CLM_DATE, p_ph_convert.CONV_ADMISSTYPE(admission_type) IPD_FLAG  ,close_date , '' cwp_remark ,'' fax_clm ,'' invoice ,
               '' RISK_DESCR ,REMARK ,DIS_CODE ,HPT_CODE ,FLEET_SEQ ,CLM_TYPE ,
               OUT_CLM_NO ,OUT_OPEN_STS ,OUT_PAID_STS ,OUT_APPROVE_STS ,OTHER_HPT ,LOSS_DETAIL
           from nc_mas
           where clm_no = v_clmno   
        )loop
            BEGIN
            SELECT MAIN_CLASS, 
                   COV_NO, COV_SEQ, 
                   POL_YR, BR_CODE, PROD_TYPE, prod_grp, CHANNEL, 
                   CUS_CODE, CUS_SEQ, substr(CUS_ENQ,1,90), --table mis_mas cus_enq varchar2(160) ???????????? display ???????????????? table mis_clm_mas 
                   CURR_CODE, 
                   CURR_RATE, NVL(CO_TYPE,'0'), NVL(CO_RE,'0'),
                   BKI_SHR, AGENT_CODE, AGENT_SEQ, 
                   TH_ENG ,
                   ALC_RE ,UNNAME_POL
            INTO
                   v_MAIN_CLASS, 
                   v_COV_NO, v_COV_SEQ, 
                   v_POL_YR, v_BR_CODE, v_PROD_TYPE, v_prod_grp,
                   v_CHANNEL, 
                   v_MAS_CUS_CODE, v_MAS_CUS_SEQ,
                   v_MAS_CUS_ENQ    ,     
                   v_CURR_CODE, 
                   v_CURR_RATE, v_CO_TYPE, v_CO_RE,
                   v_BKI_SHR, v_AGENT_CODE, v_AGENT_SEQ,  
                   v_TH_ENG ,
                   v_ALC_RE,v_UNNAME_POL
            FROM MIS_MAS
            WHERE POL_NO = Cmas.POL_NO AND
                      nvl(pol_run,0) = to_number(Cmas.POL_RUN) and
                      END_SEQ = Cmas.END_SEQ
                                         ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
            null;
            WHEN OTHERS THEN 
            null;
            END;     
                
            BEGIN
              SELECT SUM(SUM_INS)
              INTO v_MAS_SUM_INS
              FROM MIS_MAS
              WHERE POL_NO = Cmas.POL_NO AND
                      nvl(pol_run,0) = to_number(Cmas.POL_RUN) and
                       Cmas.LOSS_DATE BETWEEN FR_DATE AND TO_DATE
              GROUP BY POL_NO,pol_run;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   v_MAS_SUM_INS := null;
            END;                    

            if v_alc_re = '1' then
                    select  sum_ins
                    into v_RECPT_SUM_INS
                    from mis_recpt a
                    where pol_no =  Cmas.POL_NO
                    and pol_run = Cmas.POL_RUN
                    and end_seq =0    
                    and recpt_seq in (select min(x.recpt_seq) from mis_recpt x where x.pol_no =a.pol_no and x.pol_run = a.pol_run and x.end_seq =a.end_seq );                         
            else    
          
              SELECT SUM(B.SUM_INS)
              INTO v_RECPT_SUM_INS
              FROM MIS_MAS A, MIS_RECPT B
              WHERE (
                              (A.POL_NO =  Cmas.POL_NO) and 
                     (nvl(a.pol_run,0) = to_number( Cmas.POL_RUN))
                     )  
                     AND
                    ((A.POL_NO = B.POL_NO) and (nvl(a.pol_run,0) = nvl(b.pol_run,0))) AND
                    (
                        B.RECPT_SEQ  in  (select min(x.recpt_seq) from MIS_RECPT x where x.pol_no =b.pol_no and x.pol_run =b.pol_run  
                        AND (Cmas.LOSS_DATE BETWEEN x.FR_DATE AND x.TO_DATE ) )
                    ) AND
                    ((Cmas.LOSS_DATE BETWEEN A.FR_DATE AND A.TO_DATE OR
                    Cmas.LOSS_DATE BETWEEN FR_MAINT AND TO_MAINT))  
                    AND (Cmas.LOSS_DATE BETWEEN B.FR_DATE AND B.TO_DATE )        
                    AND (A.END_SEQ = B.END_SEQ) 
              GROUP BY B.POL_NO,b.pol_run,B.RECPT_SEQ;

            end if;    
            
            P_PH_CONVERT.CONV_CLMTYPE(Cmas.CLM_TYPE ,o_inc ,o_recpt ,o_inv ,o_ost ,o_dead);
                        
            Insert into MIS_CLM_MAS
               (STS_KEY ,CLM_NO, MAIN_CLASS, POL_NO, RECPT_SEQ, CLM_YR, POL_YR, BR_CODE, MAS_CUS_CODE, 
               MAS_CUS_SEQ, MAS_CUS_ENQ, CUS_CODE, CUS_SEQ, CUS_ENQ, MAS_SUM_INS, RECPT_SUM_INS, 
               TOT_RES, TOT_PAID, TOT_DEDUCT, TOT_RECOV, FR_DATE, TO_DATE, CURR_CODE, CURR_RATE, 
               CO_TYPE, CO_RE, BKI_SHR, AGENT_CODE, TH_ENG, REG_DATE, CLM_DATE, LOSS_DATE, LOSS_TIME, 
               CLM_MEN, CLM_STAFF ,PAID_STAFF, RECOV_STS, POL_COV, CLM_STS, ALC_RE, CLM_CURR_CODE, CLM_CURR_RATE, SHR_TYPE, 
               AGENT_SEQ, END_SEQ, POL_RUN, CHANNEL, PROD_GRP, PROD_TYPE, CLM_BR_CODE,
               FAX_CLM_DATE, IPD_FLAG  ,close_date,cwp_remark 
               ,fax_clm ,invoice ,receipt ,walkin ,deathclm ,clm_type ,
               RISK_DESCR ,REMARK ,OUT_CLM_NO ,OUT_OPEN_STS ,OUT_PAID_STS ,OUT_PRINT_STS)
            Values  (
                Cmas.STS_KEY ,Cmas.CLM_NO,  v_MAIN_CLASS ,  Cmas.POL_NO, Cmas.RECPT_SEQ, Cmas.CLM_YR, v_POL_YR ,v_BR_CODE, Cmas.MAS_CUS_CODE,
               Cmas.MAS_CUS_SEQ, Cmas.MAS_CUS_ENQ, Cmas.CUS_CODE, Cmas.CUS_SEQ, Cmas.CUS_ENQ,v_MAS_SUM_INS, v_RECPT_SUM_INS,
               Cmas.TOT_RES, Cmas.TOT_PAID, Cmas.TOT_DEDUCT, Cmas.TOT_RECOV, Cmas.FR_DATE, Cmas.TO_DATE, v_CURR_CODE, v_CURR_RATE,
               v_CO_TYPE, v_CO_RE , v_BKI_SHR,v_AGENT_CODE, v_TH_ENG , Cmas.REG_DATE, Cmas.CLM_DATE, Cmas.LOSS_DATE, Cmas.LOSS_TIME,
               Cmas.CLM_MEN, Cmas.CLM_STAFF , Cmas.PAID_STAFF, Cmas.RECOV_STS, Cmas.POL_COV, Cmas.CLM_STS, Cmas.ALC_RE, Cmas.CLM_CURR_CODE, Cmas.CLM_CURR_RATE, Cmas.SHR_TYPE, 
               v_AGENT_SEQ, Cmas.END_SEQ, Cmas.POL_RUN, v_CHANNEL, Cmas.PROD_GRP, Cmas.PROD_TYPE, Cmas.CLM_BR_CODE,
               Cmas.FAX_CLM_DATE, Cmas.IPD_FLAG  ,Cmas.close_date,Cmas.cwp_remark 
               ,o_inc ,o_inv ,o_recpt ,o_ost ,o_dead , Cmas.CLM_TYPE ,
               Cmas.LOSS_DETAIL ,Cmas.REMARK ,Cmas.OUT_CLM_NO ,Cmas.OUT_OPEN_STS ,Cmas.OUT_PAID_STS ,Cmas.OUT_APPROVE_STS                  
            );     
            
            update nc_mas
            set channel = v_CHANNEL
            where clm_no = Cmas.clm_no;
            
             insert into mis_clm_mas_seq(clm_no,pol_no,pol_run,corr_seq,corr_date,channel,prod_grp,
                                         prod_type,clm_date,tot_res,tot_paid,clm_sts,close_date)
             values (
                              Cmas.clm_no,Cmas.pol_no,Cmas.pol_run,v_max_corrseq ,vsysdate,
                     v_CHANNEL, Cmas.Prod_grp, Cmas.Prod_type,Cmas.clm_date,
                     Cmas.tot_res, Cmas.tot_paid ,Cmas.clm_sts, Cmas.Close_date); 
                                          
            if v_sts = 'PHCLMSTS02' then --incase Open insert Reserved Amt Data           
                Insert into MISC.MIS_CRI_RES
                   (CLM_NO, RI_CODE, RI_BR_CODE, RI_TYPE, RI_RES_DATE, RI_RES_AMT, RI_SHR, LETT_NO, LETT_PRT, LETT_TYPE, RES_STS, CORR_SEQ, LF_FLAG, RI_SUB_TYPE)
                (select CLM_NO, RI_CODE, RI_BR_CODE, RI_TYPE,trunc(RI_STS_DATE) RI_RES_DATE, RI_RES_AMT,RI_SHARE RI_SHR, LETT_NO, LETT_PRT, LETT_TYPE,'0' RES_STS,v_max_criseq ,RI_LF_FLAG LF_FLAG, RI_SUB_TYPE
                from nc_ri_reserved a   
                where clm_no = v_clmno
                and trn_seq in (select max(aa.trn_seq) from nc_ri_reserved aa where aa.clm_no = a.clm_no)
                );    
                
                if v_state_no is null then        
                    v_state_no := p_ph_convert.GEN_STATENO('');
                end if;
                
                if cmas.hpt_code is null and cmas.other_hpt is not null then
                    v_hpt_code := '3880';
                else
                    v_hpt_code := P_PH_CONVERT.CONV_HOSPITAL(cmas.hpt_code);
                end if;
                
                FOR res in (
                    select CLM_NO,'' STATE_NO,'' STATE_SEQ, '' FLEET_SEQ,'' SUB_SEQ,'' PLAN ,'' DIS_CODE,PREM_CODE BENE_CODE, '' RECPT_SEQ
                    ,'' STATE_DATE,'' CORR_DATE,'' TITLE,'' NAME,'' FR_DATE,'' TO_DATE,'' HPT_CODE, RES_AMT,'' CLOSE_DATE,'' LOSS_DATE,'' FAM_STS,'N' PAID_STS
                    ,'' CONTACT,'' REMARK,nvl(pd_flag,clm_pd_flag) PD_FLAG , CLM_PD_FLAG,1 SEQ,'' FAM_SEQ,'' DEPT_BKI,'' ID_NO
                    from nc_reserved a ,medical_ben_std b
                    where clm_no = v_clmno
                    and a.trn_seq in (select max(aa.trn_seq) from nc_reserved aa where aa.clm_no = a.clm_no)
                    and a.prem_code = b.bene_code
                    and b.th_eng='T'                
                )LOOP
                    for fleet in (
                        select  FLEET_SEQ, NVL(SUB_SEQ,0) SUB_SEQ, PLAN, TITLE, NAME, FR_DATE, TO_DATE
                        , FAM_STS, FAM_SEQ, DEPT_BKI, ID_NO
                        from pa_medical_det
                        where pol_no =Cmas.Pol_no and pol_run = Cmas.Pol_run
                        and fleet_seq = CMas.Fleet_seq  
                        and rownum=1                  
                    )loop
                        Insert into MISC.CLM_MEDICAL_RES
                           (CLM_NO, STATE_NO, STATE_SEQ, FLEET_SEQ, SUB_SEQ, PLAN, PD_FLAG, DIS_CODE, BENE_CODE, RECPT_SEQ, STATE_DATE, CORR_DATE, TITLE, NAME, FR_DATE, TO_DATE, HPT_CODE, RES_AMT, CLOSE_DATE, LOSS_DATE, FAM_STS, PAID_STS, CONTACT, REMARK, CLM_PD_FLAG, SEQ, FAM_SEQ, DEPT_BKI, ID_NO)
                         Values
                           (
                           res.clm_no, v_state_no, v_max_stateseq, fleet.fleet_seq, fleet.sub_seq, fleet.plan, res.pd_flag, Cmas.dis_code, res.bene_code
                           , Cmas.recpt_seq, trunc(vsysdate), vsysdate, fleet.title, fleet.name, fleet.fr_date, fleet.to_date, v_hpt_code, res.res_amt
                           , res.close_date, Cmas.loss_date, fleet.fam_sts, res.paid_sts, res.contact, res.remark, res.clm_pd_flag, res.seq, fleet.fam_seq
                           , fleet.dept_bki, fleet.id_no
                           );                      
                    end loop;
                                                      
                END LOOP; --res
            end if;
            
        end loop; --Cmas
    
    else -- case Update Mis_clm_mas    

        for Cmas in (
          select STS_KEY ,CLM_NO, 'M' MAIN_CLASS, POL_NO, RECPT_SEQ, CLM_YR, POL_YR,'01' BR_CODE, MAS_CUS_CODE, 
               MAS_CUS_SEQ,MAS_CUS_NAME MAS_CUS_ENQ, CUS_CODE, CUS_SEQ,CUS_NAME CUS_ENQ, MAS_SUM_INS, RECPT_SUM_INS, 
              p_ph_clm.get_SUM_RES(clm_no ,null) TOT_RES,p_ph_clm.get_SUM_Paid(clm_no ,null) TOT_PAID,0 TOT_DEDUCT,0 TOT_RECOV, FR_DATE, TO_DATE, CURR_CODE, CURR_RATE, 
              '' CO_TYPE,'' CO_RE, BKI_SHR, '' AGENT_CODE,'T' TH_ENG, trunc(REG_DATE) reg_date, trunc(CLM_DATE) clm_date, trunc(LOSS_DATE) loss_date, LOSS_TIME, 
              CLM_USER CLM_MEN,CLM_USER CLM_STAFF ,'' PAID_STAFF,'' RECOV_STS,'' POL_COV,p_ph_convert.CONV_CLMSTS(claim_status) CLM_STS, ALC_RE,'' CLM_CURR_CODE,'' CLM_CURR_RATE, '' SHR_TYPE, 
               '' AGENT_SEQ, END_SEQ, POL_RUN, CHANNEL, PROD_GRP, PROD_TYPE, '01' CLM_BR_CODE,
               trunc(FAX_CLM_DATE) FAX_CLM_DATE, p_ph_convert.CONV_ADMISSTYPE(admission_type) IPD_FLAG  ,close_date , '' cwp_remark ,'' fax_clm ,'' invoice ,
               '' RISK_DESCR ,REMARK ,DIS_CODE ,HPT_CODE ,fleet_seq ,amd_user  ,clm_type ,
               OUT_CLM_NO ,OUT_OPEN_STS ,OUT_PAID_STS ,OUT_APPROVE_STS  ,OTHER_HPT ,LOSS_DETAIL
           from nc_mas
           where clm_no = v_clmno   
        )loop
            
            P_PH_CONVERT.CONV_CLMTYPE(Cmas.CLM_TYPE ,o_inc ,o_recpt ,o_inv ,o_ost ,o_dead);
                        
            update mis_clm_mas
            set tot_res = Cmas.tot_res ,clm_sts =Cmas.CLM_STS , tot_paid = Cmas.tot_paid , close_date = cmas.close_date ,loss_date = cmas.loss_date
            ,fax_clm_date =cmas.fax_clm_date ,clm_men = cmas.clm_men ,clm_staff =  cmas.amd_user ,remark = cmas.remark 
            ,risk_descr = cmas.loss_detail 
            ,fax_clm = o_inc ,invoice =o_inv ,receipt =o_recpt ,walkin =o_ost ,deathclm = o_dead ,clm_type = Cmas.CLM_TYPE
            ,OUT_CLM_NO = Cmas.OUT_CLM_NO ,OUT_OPEN_STS = Cmas.OUT_OPEN_STS ,OUT_PAID_STS = Cmas.OUT_PAID_STS ,OUT_PRINT_STS = Cmas.OUT_APPROVE_STS        
            where clm_no = v_clmno;

             insert into mis_clm_mas_seq(clm_no,pol_no,pol_run,corr_seq,corr_date,channel,prod_grp,
                                         prod_type,clm_date,tot_res,tot_paid,clm_sts,close_date)
             values (
                              Cmas.clm_no,Cmas.pol_no,Cmas.pol_run,v_max_corrseq ,vsysdate,
                     Cmas.channel , Cmas.Prod_grp, Cmas.Prod_type,Cmas.clm_date,
                     Cmas.tot_res, Cmas.tot_paid ,Cmas.clm_sts, Cmas.Close_date); 
                                          
            if v_sts = 'PHCLMSTS02' then --incase Open insert Reserved Amt Data           
                Insert into MISC.MIS_CRI_RES
                   (CLM_NO, RI_CODE, RI_BR_CODE, RI_TYPE, RI_RES_DATE, RI_RES_AMT, RI_SHR, LETT_NO, LETT_PRT, LETT_TYPE, RES_STS, CORR_SEQ, LF_FLAG, RI_SUB_TYPE)
                (select CLM_NO, RI_CODE, RI_BR_CODE, RI_TYPE,trunc(RI_STS_DATE) RI_RES_DATE, RI_RES_AMT,RI_SHARE RI_SHR, LETT_NO, LETT_PRT, LETT_TYPE,'0' RES_STS,v_max_criseq,RI_LF_FLAG LF_FLAG, RI_SUB_TYPE
                from nc_ri_reserved a   
                where clm_no = v_clmno
                and trn_seq in (select max(aa.trn_seq) from nc_ri_reserved aa where aa.clm_no = a.clm_no)
                );    
                
                if v_state_no is null then        
                    v_state_no := p_ph_convert.GEN_STATENO('');
                end if;

                if cmas.hpt_code is null and cmas.other_hpt is not null then
                    v_hpt_code := '3880';
                else
                    v_hpt_code := P_PH_CONVERT.CONV_HOSPITAL(cmas.hpt_code);
                end if;
                
                FOR res in (
                    select CLM_NO,'' STATE_NO,'' STATE_SEQ, '' FLEET_SEQ,'' SUB_SEQ,'' PLAN ,'' DIS_CODE,PREM_CODE BENE_CODE, '' RECPT_SEQ
                    ,'' STATE_DATE,'' CORR_DATE,'' TITLE,'' NAME,'' FR_DATE,'' TO_DATE,'' HPT_CODE, RES_AMT,'' CLOSE_DATE,'' LOSS_DATE,'' FAM_STS,'N' PAID_STS
                    ,'' CONTACT,'' REMARK,nvl(pd_flag,clm_pd_flag) PD_FLAG , CLM_PD_FLAG,1 SEQ,'' FAM_SEQ,'' DEPT_BKI,'' ID_NO
                    from nc_reserved a ,medical_ben_std b
                    where clm_no = v_clmno
                    and a.trn_seq in (select max(aa.trn_seq) from nc_reserved aa where aa.clm_no = a.clm_no)
                    and a.prem_code = b.bene_code
                    and b.th_eng='T'                
                )LOOP
                    for fleet in (
                        select  FLEET_SEQ, NVL(SUB_SEQ,0) SUB_SEQ, PLAN, TITLE, NAME, FR_DATE, TO_DATE
                        , FAM_STS, FAM_SEQ, DEPT_BKI, ID_NO
                        from pa_medical_det
                        where pol_no =Cmas.Pol_no and pol_run = Cmas.Pol_run
                        and fleet_seq = CMas.Fleet_seq  
                        and rownum=1                  
                    )loop
                        Insert into MISC.CLM_MEDICAL_RES
                           (CLM_NO, STATE_NO, STATE_SEQ, FLEET_SEQ, SUB_SEQ, PLAN, PD_FLAG, DIS_CODE, BENE_CODE, RECPT_SEQ, STATE_DATE, CORR_DATE, TITLE, NAME, FR_DATE, TO_DATE, HPT_CODE, RES_AMT, CLOSE_DATE, LOSS_DATE, FAM_STS, PAID_STS, CONTACT, REMARK, CLM_PD_FLAG, SEQ, FAM_SEQ, DEPT_BKI, ID_NO)
                         Values
                           (
                           res.clm_no, v_state_no, v_max_stateseq, fleet.fleet_seq, fleet.sub_seq, fleet.plan, res.pd_flag, Cmas.dis_code, res.bene_code
                           , Cmas.recpt_seq, trunc(vsysdate), vsysdate, fleet.title, fleet.name, fleet.fr_date, fleet.to_date, v_hpt_code, res.res_amt
                           , res.close_date, Cmas.loss_date, fleet.fam_sts, res.paid_sts, res.contact, res.remark, res.clm_pd_flag, res.seq, fleet.fam_seq
                           , fleet.dept_bki, fleet.id_no
                           );                      
                    end loop;
                                                      
                END LOOP; --res
            end if;
            
        end loop; --Cmas           
    end if; -- check null Mis_clm_mas
    COMMIT;
    return true;
EXCEPTION
    WHEN OTHERS THEN
        v_err_message :=     'CONV_PH_OPEN error:'||sqlerrm;
        dbms_output.put_line (v_err_message);
        rollback;
        return false;
END CONV_PH_OPEN;

FUNCTION CONV_PH_DRAFT(v_clmno in varchar2,v_payno in varchar2  ,v_sts in varchar2
    , v_err_message out varchar2) RETURN BOOLEAN IS 
    v_claim_status VARCHAR2(20); 
    v_dummy_clm  VARCHAR2(20);  
    v_max_corrseq   number(5):=0;
    vsysdate    date:=sysdate;
    v_state_no  varchar2(20);
    v_max_stateseq   number(5):=0;
    v_polno varchar2(20);
    v_polrun number;
    v_fleet number;
    v_discode   varchar2(20);
    v_pdflag    varchar2(5);
    v_clmpdflag varchar2(5);
    v_lossdate  date;
    v_hpt_code varchar2(20);
    v_other_hpt varchar2(250);
    v_days  number;
    cnt_paid    number:=0;
    v_gmpaid_seq number:=0;
    v_misclm_seq number:=0;
    v_payee_seq number:=0;
    v_cripaid_seq number:=0;
    o_inc  varchar2(2);
    o_recpt   varchar2(2);
    o_inv  varchar2(2);
    o_ost  varchar2(2);
    o_dead   varchar2(2);     
    v_payeetype varchar2(5);
    v_max_amt   number;
    v_agr_amt   number;
BEGIN
    begin -- check mis_clm_mas
        select clm_no into v_dummy_clm
        from mis_clm_mas 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_dummy_clm := null;
        when others then
            v_dummy_clm := null;
    end;  -- check mis_clm_mas

    begin -- max corr_seq
        select nvl(max(corr_seq)+1,0) into v_max_corrseq
        from mis_clm_mas_seq 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_max_corrseq := 0;
        when others then
            v_max_corrseq := 0;
    end;  -- max corr_seq
     
    begin -- max v_max_stateseq
        select nvl(max(state_seq)+1,0) into v_max_stateseq
        from clm_medical_res 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_max_stateseq := 0;
        when others then
            v_max_stateseq := 0;
    end;  -- max v_max_stateseq    
            
    begin -- max v_gmpaid_seq
        select nvl(max(corr_seq)+1,0) into v_gmpaid_seq
        from clm_gm_paid 
        where clm_no = v_clmno and pay_no = v_payno;
    exception
        when no_data_found then 
            v_gmpaid_seq := 0;
        when others then
            v_gmpaid_seq := 0;
    end;  -- max v_gmpaid_seq    

    begin -- max v_misclm_seq
        select nvl(max(corr_seq)+1,0) into v_misclm_seq
        from mis_clmgm_paid 
        where clm_no = v_clmno and pay_no = v_payno;
    exception
        when no_data_found then 
            v_misclm_seq := 0;
        when others then
            v_misclm_seq := 0;
    end;  -- max v_misclm_seq    

    begin -- max v_payee_seq
        select nvl(max(corr_seq)+1,0) into v_payee_seq
        from clm_gm_payee 
        where clm_no = v_clmno and pay_no = v_payno;
    exception
        when no_data_found then 
            v_payee_seq := 0;
        when others then
            v_payee_seq := 0;
    end;  -- max v_payee_seq    

    begin -- max v_cripaid_seq
        select nvl(max(corr_seq)+1,0) into v_cripaid_seq
        from mis_cri_paid 
        where clm_no = v_clmno and pay_no = v_payno;
    exception
        when no_data_found then 
            v_cripaid_seq := 0;
        when others then
            v_cripaid_seq := 0;
    end;  -- max v_cripaid_seq    
            
    begin -- get policy
        select pol_no ,pol_run ,fleet_seq ,dis_code ,loss_date ,hpt_code ,tot_tr_day ,other_hpt  into v_polno ,v_polrun ,v_fleet ,v_discode ,v_lossdate ,v_hpt_code ,v_days ,v_other_hpt
        from nc_mas 
        where clm_no = v_clmno;
    exception
        when no_data_found then null;
        when others then null;
    end;  -- get policy
          
    dbms_output.put_line ('v_dummy_clm:'||v_dummy_clm);

    if v_hpt_code is null and v_other_hpt is not null then
        v_hpt_code := '3880';
    else
        v_hpt_code := P_PH_CONVERT.CONV_HOSPITAL(v_hpt_code);
    end if;
                    
    delete CLM_MEDICAL_PAID where clm_no = v_clmno; -- Clear Record
    
    FOR paid IN (
       select clm_no ,pay_no , trn_seq corr_seq ,pay_amt ,sts_date ,amd_date ,prem_code bene_code ,prem_seq ,remark ,recov_amt ,days ,day_add
       from nc_payment a
       where clm_no =v_clmno
       and pay_no = v_payno
       and trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.pay_no = a.pay_no and type like 'NCNATTYPECLM%')    
       and a.type like 'NCNATTYPECLM%'
    )LOOP
        cnt_paid := cnt_paid+1;
        for F in (
            select  FLEET_SEQ, NVL(SUB_SEQ,0) SUB_SEQ, PLAN, TITLE, NAME, FR_DATE, TO_DATE
            , FAM_STS, FAM_SEQ, DEPT_BKI, ID_NO
            from pa_medical_det
            where pol_no =v_polno and pol_run = v_polrun
            and fleet_seq = v_fleet 
            and rownum=1                  
        )loop
            begin -- get policy
                select nvl(pd_flag,clm_pd_flag) pd_flag ,clm_pd_flag into v_pdflag ,v_clmpdflag
                from medical_ben_std  b
                where bene_code = paid.bene_code and b.th_eng='T' ;
            exception
                when no_data_found then 
                    v_pdflag := null ;v_clmpdflag := null;
                when others then
                    v_pdflag := null ;v_clmpdflag := null;  
            end;  -- get policy
            
            if p_ph_clm.IS_BKIPOLICY(v_polno ,v_polrun) then
                v_max_amt := 0;
                v_agr_amt := paid.pay_amt;
            else
                if v_clmpdflag in ('O','S') then
                    v_max_amt := paid.pay_amt;
                    v_agr_amt := 0;                         
                else
                    v_max_amt := 0;
                    v_agr_amt := paid.pay_amt;                 
                end if;           
            end if;
            
            Insert into MISC.CLM_MEDICAL_PAID
               (POL_NO, CLM_NO, FLEET_SEQ, SUB_SEQ, PLAN, PD_FLAG, DIS_CODE, BENE_CODE, MAX_AMT_CLM ,MAX_AGR_AMT , CLM_PD_FLAG, POL_RUN, FAM_SEQ ,DEPT_BKI ,ID_NO)
             Values
               (v_polno ,v_clmno ,v_fleet ,F.sub_seq ,F.plan ,v_pdflag ,v_discode ,paid.bene_code ,v_max_amt ,v_agr_amt ,v_clmpdflag ,v_polrun ,F.Fam_seq ,F.dept_bki ,F.id_no);
            
            v_days := nvl(paid.days,0)+nvl(paid.day_add,0);
            Insert into MISC.CLM_GM_PAID
           (CLM_NO, PAY_NO, CORR_SEQ, FLEET_SEQ, SUB_SEQ, PLAN, PD_FLAG, DIS_CODE, BENE_CODE, LOSS_DATE, DATE_PAID, CORR_DATE
           , DISC_AMT, PAY_AMT, HPT_CODE, CLM_PD_FLAG, SEQ, REC_PAY_DATE, FAM_SEQ
           ,REMARK ,REC_AMT ,IPD_DAY ,DEPT_BKI ,ID_NO)      
           Values
           (v_clmno ,v_payno ,v_gmpaid_seq ,v_fleet ,F.sub_seq ,F.plan ,v_pdflag ,v_discode ,paid.bene_code ,v_lossdate ,paid.sts_date ,paid.amd_date
           , 0 ,paid.pay_amt ,v_hpt_code ,v_clmpdflag ,1 ,paid.sts_date ,F.fam_seq
           ,paid.remark ,paid.recov_amt , v_days ,F.dept_bki ,F.id_no);            
           
            if cnt_paid =1 then
                Insert into MISC.MIS_CLMGM_PAID
                (   CLM_NO, PAY_NO, CORR_SEQ, PAY_DATE, PAY_TOTAL, REC_TOTAL, DISC_TOTAL, SETTLE, REC_PAY_DATE, PRINT_TYPE
                ,REMARK )         
                values
                (
                    v_clmno ,v_payno ,v_misclm_seq ,null , p_ph_clm.get_sum_paid(v_clmno ,v_payno) ,0 , 0 ,null ,paid.sts_date ,null ,paid.remark
                );     
                
                delete CLM_GM_PAYEE where clm_no = v_clmno  and pay_no = v_payno; -- Clear Record
                
                FOR payee in (
                   select clm_no ,pay_no ,trn_seq corr_seq ,payee_amt ,sts_date ,amd_date , payee_code ,payee_name ,payee_type ,payee_seq 
                   ,settle ,acc_no ,acc_name ,bank_code ,bank_br_code ,br_name ,send_title ,send_addr1 ,send_addr2 
                   ,sms ,email ,agent_sms ,agent_email ,special_flag ,special_remark ,urgent_flag 
                   ,invalid_payee ,invalid_payee_remark ,p_ph_convert.CONV_PAYEETYPE(paid_to) paid_to
                   from nc_payee a
                   where clm_no = v_clmno
                   and pay_no = v_payno
                   and trn_seq in (select max(aa.trn_seq) from nc_payee aa where aa.pay_no = a.pay_no)                  
                )LOOP
                    Insert into MISC.CLM_GM_PAYEE
                       (CLM_NO, PAY_NO, CORR_SEQ , PAY_SEQ, PAYEE_TYPE, PAYEE_CODE, PAYEE_AMT, PAY_TYPE, PAYEE_NAME, SEND_TITLE, SEND_ADDR1, SEND_ADDR2
                       ,SPECIAL_FLAG ,SPECIAL_REMARK , AGENT_MAIL, AGENT_MAIL_FLAG ,AGENT_MOBILE_NUMBER ,AGENT_SMS_FLAG
                       ,CUST_MAIL ,CUST_MAIL_FLAG ,MOBILE_NUMBER ,SMS_FLAG
                       ,SETTLE, ACC_NO, ACC_NAME, BANK_CODE, BANK_BR_CODE, BR_NAME, URGENT_FLAG
                       , INVALID_PAYEE ,INVALID_PAYEE_REMARK )
                    Values                
                        (
                         v_clmno ,v_payno ,v_payee_seq ,payee.payee_seq ,PAYEE.PAID_TO ,payee.payee_code ,payee.payee_amt ,'1' ,payee.payee_name ,payee.send_title, payee.send_addr1, payee.send_addr2
                         ,payee.special_flag ,payee.special_remark ,payee.agent_email ,decode(payee.agent_email,null ,null,'Y') ,payee.agent_sms ,decode(payee.agent_sms,null ,null,'Y')
                         ,payee.email ,decode(payee.email,null ,null,'Y') , payee.sms ,decode(payee.sms,null ,null,'Y') 
                         ,payee.settle ,payee.acc_no  ,payee.acc_name ,payee.bank_code ,payee.bank_br_code ,payee.br_name ,payee.urgent_flag
                          ,payee.invalid_payee ,payee.invalid_payee_remark
                        );
                END LOOP;

                Insert into MISC.MIS_CRI_PAID
                (CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, RI_TYPE, PAY_AMT, LETT_PRT, LETT_TYPE, CORR_SEQ, LF_FLAG, RI_SUB_TYPE ,LETT_NO )
                (
                select clm_no, pay_no,'0' pay_sts, ri_code, ri_br_code, ri_type, ri_pay_amt, lett_prt, lett_type,v_cripaid_seq, ri_lf_flag, ri_sub_type ,lett_no 
                from nc_ri_paid a
                where clm_no = v_clmno
                and pay_no = v_payno
                and trn_seq in (select max(aa.trn_seq) from nc_ri_paid aa where aa.pay_no = a.pay_no)
                );                
                
                FOR Cmas IN (
                select CLM_NO ,POL_NO,  p_ph_clm.get_SUM_RES(clm_no ,null) TOT_RES,p_ph_clm.get_SUM_Paid(clm_no ,null) TOT_PAID
                , trunc(REG_DATE) reg_date, trunc(CLM_DATE) clm_date, trunc(LOSS_DATE) loss_date, LOSS_TIME, 
                CLM_USER CLM_MEN,CLM_USER CLM_STAFF ,'' PAID_STAFF,'' RECOV_STS,'' POL_COV,p_ph_convert.CONV_CLMSTS(claim_status) CLM_STS
                , END_SEQ, POL_RUN, CHANNEL, PROD_GRP, PROD_TYPE,
                trunc(FAX_CLM_DATE) FAX_CLM_DATE, p_ph_convert.CONV_ADMISSTYPE(admission_type) IPD_FLAG  
                ,close_date , '' cwp_remark ,'' fax_clm ,'' invoice ,
                '' RISK_DESCR ,REMARK ,DIS_CODE ,HPT_CODE ,fleet_seq ,amd_user ,clm_type ,
                OUT_CLM_NO ,OUT_OPEN_STS ,OUT_PAID_STS ,OUT_APPROVE_STS ,LOSS_DETAIL
                FROM nc_mas where clm_no = v_clmno
                )LOOP 
                    P_PH_CONVERT.CONV_CLMTYPE(Cmas.CLM_TYPE ,o_inc ,o_recpt ,o_inv ,o_ost ,o_dead);
                    
                    update mis_clm_mas
                    set tot_res = Cmas.tot_res ,clm_sts =Cmas.CLM_STS , tot_paid = Cmas.tot_paid , close_date = cmas.close_date ,loss_date = cmas.loss_date
                    ,fax_clm_date =cmas.fax_clm_date ,clm_men = cmas.clm_men ,clm_staff =  cmas.amd_user ,remark = cmas.remark 
                    ,risk_descr = cmas.loss_detail 
                    ,fax_clm = o_inc ,invoice =o_inv ,receipt =o_recpt ,walkin =o_ost ,deathclm = o_dead ,clm_type = Cmas.CLM_TYPE
                    where clm_no = v_clmno;

                    insert into mis_clm_mas_seq(clm_no,pol_no,pol_run,corr_seq,corr_date,channel,prod_grp,
                                             prod_type,clm_date,tot_res,tot_paid,clm_sts,close_date)
                    values (
                                  Cmas.clm_no,Cmas.pol_no,Cmas.pol_run,v_max_corrseq ,vsysdate,
                         Cmas.channel , Cmas.Prod_grp, Cmas.Prod_type,Cmas.clm_date,
                         Cmas.tot_res, Cmas.tot_paid ,Cmas.clm_sts, Cmas.Close_date);        
                                  
                END LOOP;
                                     
            end if; -- cnt =1
                              
        end loop;    
    END LOOP;
     
    COMMIT;
    return true;
EXCEPTION
    WHEN OTHERS THEN
        v_err_message :=     'CONV_PH_DRAFT error:'||sqlerrm;
        dbms_output.put_line ('error:'||sqlerrm);
        rollback;
        return false;
END CONV_PH_DRAFT;

FUNCTION CONV_PH_CWP(v_clmno in varchar2,v_payno in varchar2  ,v_sts in varchar2
    , v_err_message out varchar2) RETURN BOOLEAN IS 
    v_claim_status VARCHAR2(20); 
    v_dummy_clm  VARCHAR2(20);  
    v_max_corrseq   number(5):=0;
    vsysdate    date:=sysdate;
    v_state_no  varchar2(20);
    v_max_stateseq   number(5):=0;
    v_polno varchar2(20);
    v_polrun number;
    v_fleet number;
    v_discode   varchar2(20);
    v_pdflag    varchar2(5);
    v_clmpdflag varchar2(5);
    v_lossdate  date;
    v_hpt_code varchar2(20);
    v_days  number;
    cnt_paid    number:=0;
    v_gmpaid_seq number:=0;
    v_misclm_seq number:=0;
    v_payee_seq number:=0;
    v_cripaid_seq number:=0;
BEGIN
    begin -- check mis_clm_mas
        select clm_no into v_dummy_clm
        from mis_clm_mas 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_dummy_clm := null;
        when others then
            v_dummy_clm := null;
    end;  -- check mis_clm_mas

    begin -- max corr_seq
        select nvl(max(corr_seq)+1,0) into v_max_corrseq
        from mis_clm_mas_seq 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_max_corrseq := 0;
        when others then
            v_max_corrseq := 0;
    end;  -- max corr_seq
        
    begin -- max v_gmpaid_seq
        select nvl(max(corr_seq)+1,0) into v_gmpaid_seq
        from clm_gm_paid 
        where clm_no = v_clmno and pay_no = v_payno;
    exception
        when no_data_found then 
            v_gmpaid_seq := 0;
        when others then
            v_gmpaid_seq := 0;
    end;  -- max v_gmpaid_seq    

    begin -- max v_misclm_seq
        select nvl(max(corr_seq)+1,0) into v_misclm_seq
        from mis_clmgm_paid 
        where clm_no = v_clmno and pay_no = v_payno;
    exception
        when no_data_found then 
            v_misclm_seq := 0;
        when others then
            v_misclm_seq := 0;
    end;  -- max v_misclm_seq    

    begin -- max v_payee_seq
        select nvl(max(corr_seq)+1,0) into v_payee_seq
        from clm_gm_payee 
        where clm_no = v_clmno and pay_no = v_payno;
    exception
        when no_data_found then 
            v_payee_seq := 0;
        when others then
            v_payee_seq := 0;
    end;  -- max v_payee_seq    

    begin -- max v_cripaid_seq
        select nvl(max(corr_seq)+1,0) into v_cripaid_seq
        from mis_cri_paid 
        where clm_no = v_clmno and pay_no = v_payno;
    exception
        when no_data_found then 
            v_cripaid_seq := 0;
        when others then
            v_cripaid_seq := 0;
    end;  -- max v_cripaid_seq    
            
    begin -- get policy
        select pol_no ,pol_run ,fleet_seq ,dis_code ,loss_date ,hpt_code ,tot_tr_day  into v_polno ,v_polrun ,v_fleet ,v_discode ,v_lossdate ,v_hpt_code ,v_days
        from nc_mas 
        where clm_no = v_clmno;
    exception
        when no_data_found then null;
        when others then null;
    end;  -- get policy
          
    dbms_output.put_line ('v_dummy_clm:'||v_dummy_clm);
    
    FOR Cmas IN (
    select CLM_NO ,POL_NO,  p_ph_clm.get_SUM_RES(clm_no ,null) TOT_RES,p_ph_clm.get_SUM_Paid(clm_no ,null) TOT_PAID
    , trunc(REG_DATE) reg_date, trunc(CLM_DATE) clm_date, trunc(LOSS_DATE) loss_date, LOSS_TIME, 
    CLM_USER CLM_MEN,CLM_USER CLM_STAFF ,'' PAID_STAFF,'' RECOV_STS,'' POL_COV,p_ph_convert.CONV_CLMSTS(claim_status) CLM_STS
    , END_SEQ, POL_RUN, CHANNEL, PROD_GRP, PROD_TYPE,
    trunc(FAX_CLM_DATE) FAX_CLM_DATE, p_ph_convert.CONV_ADMISSTYPE(admission_type) IPD_FLAG  
    ,close_date  ,cwp_code , cwp_remark ,cwp_user  ,(select descr from clm_constant x where key like 'CWPPH-TYPE%' and remark = cwp_code) cwp_descr
     ,(select key from clm_constant x where key like 'CWPPH-TYPE%' and remark = cwp_code) rem_close  
    ,'' fax_clm ,'' invoice ,
    '' RISK_DESCR ,REMARK ,DIS_CODE ,HPT_CODE ,fleet_seq ,amd_user ,
    OUT_CLM_NO ,OUT_OPEN_STS ,OUT_PAID_STS ,OUT_APPROVE_STS
    FROM nc_mas where clm_no = v_clmno
    )LOOP 
        update mis_clm_mas
        set tot_res = Cmas.tot_res ,clm_sts =Cmas.CLM_STS , tot_paid = Cmas.tot_paid , close_date = cmas.close_date ,loss_date = cmas.loss_date
        ,fax_clm_date =cmas.fax_clm_date ,clm_men = cmas.clm_men ,clm_staff =  cmas.amd_user ,remark = cmas.remark 
        ,first_close = decode(first_close ,null ,cmas.close_date ,first_close)
        ,cwp_remark = Cmas.cwp_remark ,rem_close =Cmas.rem_close ,remark_cwp = Cmas.cwp_descr ,cwp_user = Cmas.cwp_user
        where clm_no = v_clmno;

        insert into mis_clm_mas_seq(clm_no,pol_no,pol_run,corr_seq,corr_date,channel,prod_grp,
                                 prod_type,clm_date,tot_res,tot_paid,clm_sts,close_date)
        values (
                      Cmas.clm_no,Cmas.pol_no,Cmas.pol_run,v_max_corrseq ,vsysdate, 
             Cmas.channel , Cmas.Prod_grp, Cmas.Prod_type,Cmas.clm_date, 
             Cmas.tot_res, Cmas.tot_paid ,Cmas.clm_sts, Cmas.Close_date);        
                                  
    END LOOP;
     
    COMMIT;
    return true;
EXCEPTION
    WHEN OTHERS THEN
        v_err_message :=     'CONV_PH_CWP error:'||sqlerrm;
        dbms_output.put_line ('error:'||sqlerrm);
        rollback;
        return false;
END CONV_PH_CWP;

FUNCTION CONV_PH_REOPEN(v_clmno in varchar2,v_payno in varchar2  ,v_sts in varchar2
    , v_err_message out varchar2) RETURN BOOLEAN IS 
    v_claim_status VARCHAR2(20); 
    v_dummy_clm  VARCHAR2(20);  
    v_max_corrseq   number(5):=0;
    vsysdate    date:=sysdate;
    v_state_no  varchar2(20);
    v_max_stateseq   number(5):=0;
    v_polno varchar2(20);
    v_polrun number;
    v_fleet number;
    v_discode   varchar2(20);
    v_pdflag    varchar2(5);
    v_clmpdflag varchar2(5);
    v_lossdate  date;
    v_hpt_code varchar2(20);
    v_days  number;
    cnt_paid    number:=0;
    v_gmpaid_seq number:=0;
    v_misclm_seq number:=0;
    v_payee_seq number:=0;
    v_cripaid_seq number:=0;
BEGIN
    begin -- check mis_clm_mas
        select clm_no into v_dummy_clm
        from mis_clm_mas 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_dummy_clm := null;
        when others then
            v_dummy_clm := null;
    end;  -- check mis_clm_mas

    begin -- max corr_seq
        select nvl(max(corr_seq)+1,0) into v_max_corrseq
        from mis_clm_mas_seq 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_max_corrseq := 0;
        when others then
            v_max_corrseq := 0;
    end;  -- max corr_seq       
            
    begin -- get policy
        select pol_no ,pol_run ,fleet_seq ,dis_code ,loss_date ,hpt_code ,tot_tr_day  into v_polno ,v_polrun ,v_fleet ,v_discode ,v_lossdate ,v_hpt_code ,v_days
        from nc_mas 
        where clm_no = v_clmno;
    exception
        when no_data_found then null;
        when others then null;
    end;  -- get policy
          
    dbms_output.put_line ('v_dummy_clm:'||v_dummy_clm);
    
    FOR Cmas IN (
    select CLM_NO ,POL_NO,  p_ph_clm.get_SUM_RES(clm_no ,null) TOT_RES,p_ph_clm.get_SUM_Paid(clm_no ,null) TOT_PAID
    , trunc(REG_DATE) reg_date, trunc(CLM_DATE) clm_date, trunc(LOSS_DATE) loss_date, LOSS_TIME, 
    CLM_USER CLM_MEN,CLM_USER CLM_STAFF ,'' PAID_STAFF,'' RECOV_STS,'' POL_COV,p_ph_convert.CONV_CLMSTS(claim_status) CLM_STS
    , END_SEQ, POL_RUN, CHANNEL, PROD_GRP, PROD_TYPE,
    trunc(FAX_CLM_DATE) FAX_CLM_DATE, p_ph_convert.CONV_ADMISSTYPE(admission_type) IPD_FLAG  
    ,close_date  ,cwp_code , cwp_remark ,cwp_user  ,(select descr from clm_constant x where key like 'CWPPH-TYPE%' and remark = cwp_code) cwp_descr
     ,(select key from clm_constant x where key like 'CWPPH-TYPE%' and remark = cwp_code) rem_close  ,reopen_date
    ,'' fax_clm ,'' invoice ,
    '' RISK_DESCR ,REMARK ,DIS_CODE ,HPT_CODE ,fleet_seq ,amd_user ,
    OUT_CLM_NO ,OUT_OPEN_STS ,OUT_PAID_STS ,OUT_APPROVE_STS
    FROM nc_mas where clm_no = v_clmno
    )LOOP 
        update mis_clm_mas
        set tot_res = Cmas.tot_res ,clm_sts =Cmas.CLM_STS , tot_paid = Cmas.tot_paid , close_date = cmas.close_date ,loss_date = cmas.loss_date
        ,fax_clm_date =cmas.fax_clm_date ,clm_men = cmas.clm_men ,clm_staff =  cmas.amd_user ,remark = cmas.remark 
        ,first_close = decode(first_close ,null ,cmas.close_date ,first_close)
        ,cwp_remark = Cmas.cwp_remark ,rem_close =Cmas.rem_close ,remark_cwp = Cmas.cwp_descr ,cwp_user = Cmas.cwp_user
        ,reopen_date = Cmas.reopen_date
        where clm_no = v_clmno;

        insert into mis_clm_mas_seq(clm_no,pol_no,pol_run,corr_seq,corr_date,channel,prod_grp,
                                 prod_type,clm_date,tot_res,tot_paid,clm_sts,close_date ,reopen_date)
        values (
                      Cmas.clm_no,Cmas.pol_no,Cmas.pol_run,v_max_corrseq ,vsysdate, 
             Cmas.channel , Cmas.Prod_grp, Cmas.Prod_type,Cmas.clm_date, 
             Cmas.tot_res, Cmas.tot_paid ,Cmas.clm_sts, Cmas.Close_date ,Cmas.reopen_date);        
                                  
    END LOOP;
     
    COMMIT;
    return true;
EXCEPTION
    WHEN OTHERS THEN
        v_err_message :=     'CONV_PH_REOPEN error:'||sqlerrm;
        dbms_output.put_line ('error:'||sqlerrm);
        rollback;
        return false;
END CONV_PH_REOPEN;

FUNCTION CONV_PH_RES_REV(v_clmno in varchar2,v_payno in varchar2  ,v_sts in varchar2
    , v_err_message out varchar2) RETURN BOOLEAN IS 
    v_claim_status VARCHAR2(20); 
    v_dummy_clm  VARCHAR2(20); 
    v_MAIN_CLASS varchar2(2);  
    v_COV_NO varchar2(15);  v_COV_SEQ number(2);  
    v_POL_YR varchar2(10);  v_BR_CODE varchar2(5);  v_PROD_TYPE varchar2(5);  v_prod_grp varchar2(5); 
    v_CHANNEL varchar2(2);  
    v_MAS_CUS_CODE varchar2(20);  v_MAS_CUS_SEQ number(3); 
    v_MAS_CUS_ENQ     varchar2(100);      
    v_CURR_CODE varchar2(5);  
    v_CURR_RATE number;  v_CO_TYPE varchar2(2);  v_CO_RE varchar2(2); 
    v_BKI_SHR number;  v_AGENT_CODE varchar2(5);  v_AGENT_SEQ varchar2(5);   
    v_TH_ENG  varchar2(2); 
    v_ALC_RE varchar2(2); v_UNNAME_POL varchar2(2); v_MAS_SUM_INS number;  v_RECPT_SUM_INS number; 
    v_FR_DATE    DATE; v_TO_DATE    DATE; 
    v_Close_date    DATE; v_cwp_remark varchar2(250);
    v_invoice    varchar2(1);
    v_fax    varchar2(1);
    v_sum_res number;
    v_sum_paid    number;    
    v_max_corrseq   number(5):=0;
    vsysdate    date:=sysdate;
    v_state_no  varchar2(20);
    v_max_stateseq   number(5):=0;
    v_max_criseq   number(5):=0;
    v_polno varchar2(20);
    v_polrun number;
    v_fleet number;
    v_discode   varchar2(20);
    v_pdflag    varchar2(5);
    v_clmpdflag varchar2(5);
    v_lossdate  date;
    v_hpt_code varchar2(20);
    v_other_hpt varchar2(250);
    v_days  number;
    cnt_paid    number:=0;
    v_gmpaid_seq number:=0;
    v_misclm_seq number:=0;
    v_payee_seq number:=0;
    v_cripaid_seq number:=0;
    o_inc  varchar2(2);
    o_recpt   varchar2(2);
    o_inv  varchar2(2);
    o_ost  varchar2(2);
    o_dead   varchar2(2); 
    v_max_amt   number;
    v_agr_amt   number;    
BEGIN
    begin -- check mis_clm_mas
        select clm_no into v_dummy_clm
        from mis_clm_mas 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_dummy_clm := null;
        when others then
            v_dummy_clm := null;
    end;  -- check mis_clm_mas

    begin -- max corr_seq
        select nvl(max(corr_seq)+1,0) into v_max_corrseq
        from mis_clm_mas_seq 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_max_corrseq := 0;
        when others then
            v_max_corrseq := 0;
    end;  -- max corr_seq

    begin -- max v_max_stateseq
        select  max(state_no) into v_state_no
        from clm_medical_res 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_state_no := null;
        when others then
            v_state_no := null;
    end;  -- max v_max_stateseq    
        
    begin -- max v_max_stateseq
        select nvl(max(state_seq)+1,0) into v_max_stateseq
        from clm_medical_res 
        where clm_no = v_clmno;
    exception
        when no_data_found then 
            v_max_stateseq := 0;
        when others then
            v_max_stateseq := 0;
    end;  -- max v_max_stateseq    

    begin -- max v_gmpaid_seq
        select nvl(max(corr_seq)+1,0) into v_gmpaid_seq
        from clm_gm_paid 
        where clm_no = v_clmno and pay_no = v_payno;
    exception
        when no_data_found then 
            v_gmpaid_seq := 0;
        when others then
            v_gmpaid_seq := 0;
    end;  -- max v_gmpaid_seq    
          
    dbms_output.put_line ('v_dummy_clm:'||v_dummy_clm);

    for Cmas in (
      select STS_KEY ,CLM_NO, 'M' MAIN_CLASS, POL_NO, RECPT_SEQ, CLM_YR, POL_YR,'01' BR_CODE, MAS_CUS_CODE, 
           MAS_CUS_SEQ,MAS_CUS_NAME MAS_CUS_ENQ, CUS_CODE, CUS_SEQ,CUS_NAME CUS_ENQ, MAS_SUM_INS, RECPT_SUM_INS, 
          p_ph_clm.get_SUM_RES(clm_no ,null) TOT_RES,p_ph_clm.get_SUM_Paid(clm_no ,null) TOT_PAID,0 TOT_DEDUCT,0 TOT_RECOV, FR_DATE, TO_DATE, CURR_CODE, CURR_RATE, 
          '' CO_TYPE,'' CO_RE, BKI_SHR, '' AGENT_CODE,'T' TH_ENG, trunc(REG_DATE) reg_date, trunc(CLM_DATE) clm_date, trunc(LOSS_DATE) loss_date, LOSS_TIME, 
          CLM_USER CLM_MEN,CLM_USER CLM_STAFF ,'' PAID_STAFF,'' RECOV_STS,'' POL_COV,p_ph_convert.CONV_CLMSTS(claim_status) CLM_STS, ALC_RE,'' CLM_CURR_CODE,'' CLM_CURR_RATE, '' SHR_TYPE, 
           '' AGENT_SEQ, END_SEQ, POL_RUN, CHANNEL, PROD_GRP, PROD_TYPE, '01' CLM_BR_CODE,
           trunc(FAX_CLM_DATE) FAX_CLM_DATE, p_ph_convert.CONV_ADMISSTYPE(admission_type) IPD_FLAG  ,close_date , '' cwp_remark ,'' fax_clm ,'' invoice ,
           '' RISK_DESCR ,REMARK ,DIS_CODE ,HPT_CODE ,fleet_seq ,amd_user  ,clm_type ,
           OUT_CLM_NO ,OUT_OPEN_STS ,OUT_PAID_STS ,OUT_APPROVE_STS  ,OTHER_HPT ,LOSS_DETAIL
       from nc_mas
       where clm_no = v_clmno   
    )loop
            
        P_PH_CONVERT.CONV_CLMTYPE(Cmas.CLM_TYPE ,o_inc ,o_recpt ,o_inv ,o_ost ,o_dead);
                        
        update mis_clm_mas
        set loss_date = cmas.loss_date
--        ,fax_clm_date =cmas.fax_clm_date 
        ,clm_men = cmas.clm_men ,clm_staff =  cmas.amd_user ,remark = cmas.remark 
        ,risk_descr = cmas.loss_detail 
        ,fax_clm = o_inc ,invoice =o_inv ,receipt =o_recpt ,walkin =o_ost ,deathclm = o_dead ,clm_type = Cmas.CLM_TYPE
        ,OUT_CLM_NO = Cmas.OUT_CLM_NO ,OUT_OPEN_STS = Cmas.OUT_OPEN_STS ,OUT_PAID_STS = Cmas.OUT_PAID_STS ,OUT_PRINT_STS = Cmas.OUT_APPROVE_STS        
        where clm_no = v_clmno;

         insert into mis_clm_mas_seq(clm_no,pol_no,pol_run,corr_seq,corr_date,channel,prod_grp,
                                     prod_type,clm_date,tot_res,tot_paid,clm_sts,close_date)
         values (
                          Cmas.clm_no,Cmas.pol_no,Cmas.pol_run,v_max_corrseq ,vsysdate,
                 Cmas.channel , Cmas.Prod_grp, Cmas.Prod_type,Cmas.clm_date,
                 Cmas.tot_res, Cmas.tot_paid ,Cmas.clm_sts, Cmas.Close_date); 
                                          
        if 1=1then     
                
            if v_state_no is null then        
                v_state_no := p_ph_convert.GEN_STATENO('');
            end if;

            if cmas.hpt_code is null and cmas.other_hpt is not null then
                v_hpt_code := '3880';
            else
                v_hpt_code := P_PH_CONVERT.CONV_HOSPITAL(cmas.hpt_code);
            end if;
                
            FOR res in (
                select CLM_NO,'' STATE_NO,'' STATE_SEQ, '' FLEET_SEQ,'' SUB_SEQ,'' PLAN ,'' DIS_CODE,PREM_CODE BENE_CODE, '' RECPT_SEQ
                ,'' STATE_DATE,'' CORR_DATE,'' TITLE,'' NAME,'' FR_DATE,'' TO_DATE,'' HPT_CODE, RES_AMT,'' CLOSE_DATE,'' LOSS_DATE,'' FAM_STS,'N' PAID_STS
                ,'' CONTACT,'' REMARK ,nvl(pd_flag,clm_pd_flag) PD_FLAG , CLM_PD_FLAG,1 SEQ,'' FAM_SEQ,'' DEPT_BKI,'' ID_NO
                from nc_reserved a ,medical_ben_std b
                where clm_no = v_clmno
                and a.trn_seq in (select max(aa.trn_seq) from nc_reserved aa where aa.clm_no = a.clm_no)
                and a.prem_code = b.bene_code
                and b.th_eng='T'                
            )LOOP
                for fleet in (
                    select  FLEET_SEQ, SUB_SEQ, PLAN, TITLE, NAME, FR_DATE, TO_DATE
                    , FAM_STS, FAM_SEQ, DEPT_BKI, ID_NO
                    from pa_medical_det
                    where pol_no =Cmas.Pol_no and pol_run = Cmas.Pol_run
                    and fleet_seq = CMas.Fleet_seq  
                    and rownum=1                  
                )loop
                    Insert into MISC.CLM_MEDICAL_RES
                       (CLM_NO, STATE_NO, STATE_SEQ, FLEET_SEQ, SUB_SEQ, PLAN, PD_FLAG, DIS_CODE, BENE_CODE, RECPT_SEQ, STATE_DATE, CORR_DATE
                       , TITLE, NAME, FR_DATE, TO_DATE, HPT_CODE, RES_AMT, CLOSE_DATE, LOSS_DATE, FAM_STS, PAID_STS, CONTACT, REMARK
                       , CLM_PD_FLAG, SEQ, FAM_SEQ, DEPT_BKI, ID_NO )
                     Values
                       (
                       res.clm_no, v_state_no, v_max_stateseq, fleet.fleet_seq, fleet.sub_seq, fleet.plan, res.pd_flag, Cmas.dis_code, res.bene_code
                       , Cmas.recpt_seq, trunc(vsysdate), vsysdate, fleet.title, fleet.name, fleet.fr_date, fleet.to_date, v_hpt_code, res.res_amt
                       , res.close_date, Cmas.loss_date, fleet.fam_sts, res.paid_sts, res.contact, res.remark, res.clm_pd_flag, res.seq, fleet.fam_seq
                       , fleet.dept_bki, fleet.id_no 
                       );                      
                end loop;
                                                      
            END LOOP; --res
        end if;

        delete CLM_MEDICAL_PAID where clm_no = v_clmno; -- Clear Record
        
        FOR paid IN (
           select clm_no ,pay_no , trn_seq corr_seq ,pay_amt ,sts_date ,amd_date ,prem_code bene_code ,prem_seq ,remark ,recov_amt ,days ,day_add
           from nc_payment a
           where clm_no =v_clmno
           and pay_no = v_payno
           and trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.pay_no = a.pay_no and type like 'NCNATTYPECLM%')    
           and a.type like 'NCNATTYPECLM%'
        )LOOP
            cnt_paid := cnt_paid+1;
            for F in (
                select  FLEET_SEQ, SUB_SEQ, PLAN, TITLE, NAME, FR_DATE, TO_DATE
                , FAM_STS, FAM_SEQ, DEPT_BKI, ID_NO
                from pa_medical_det
                where pol_no =cmas.pol_no and pol_run = cmas.pol_run
                and fleet_seq = cmas.fleet_seq 
                and rownum=1                  
            )loop
                begin -- get policy
                    select nvl(pd_flag,clm_pd_flag) pd_flag ,clm_pd_flag into v_pdflag ,v_clmpdflag
                    from medical_ben_std  b
                    where bene_code = paid.bene_code and b.th_eng='T' ;
                exception
                    when no_data_found then 
                        v_pdflag := null ;v_clmpdflag := null;
                    when others then
                        v_pdflag := null ;v_clmpdflag := null;  
                end;  -- get policy
                
                if p_ph_clm.IS_BKIPOLICY(v_polno ,v_polrun) then
                    v_max_amt := 0;
                    v_agr_amt := paid.pay_amt;
                else
                    if v_clmpdflag in ('O','S') then
                        v_max_amt := paid.pay_amt;
                        v_agr_amt := 0;                         
                    else
                        v_max_amt := 0;
                        v_agr_amt := paid.pay_amt;                 
                    end if;           
                end if;
                
                Insert into MISC.CLM_MEDICAL_PAID
                   (POL_NO, CLM_NO, FLEET_SEQ, SUB_SEQ, PLAN, PD_FLAG, DIS_CODE, BENE_CODE, MAX_AMT_CLM ,MAX_AGR_AMT , CLM_PD_FLAG, POL_RUN, FAM_SEQ ,DEPT_BKI ,ID_NO)
                 Values
                   (cmas.pol_no ,v_clmno ,cmas.fleet_seq ,F.sub_seq ,F.plan ,v_pdflag ,cmas.dis_code ,paid.bene_code ,v_max_amt ,v_agr_amt ,v_clmpdflag ,cmas.pol_run ,F.Fam_seq ,F.dept_bki ,F.id_no);
                
                v_days := nvl(paid.days,0)+nvl(paid.day_add,0);
                Insert into MISC.CLM_GM_PAID
               (CLM_NO, PAY_NO, CORR_SEQ, FLEET_SEQ, SUB_SEQ, PLAN, PD_FLAG, DIS_CODE, BENE_CODE, LOSS_DATE, DATE_PAID, CORR_DATE
               , DISC_AMT, PAY_AMT, HPT_CODE, CLM_PD_FLAG, SEQ, REC_PAY_DATE, FAM_SEQ
               ,REMARK ,REC_AMT ,IPD_DAY ,DEPT_BKI ,ID_NO)      
               Values
               (v_clmno ,v_payno ,v_gmpaid_seq ,cmas.fleet_seq ,F.sub_seq ,F.plan ,v_pdflag ,cmas.dis_code ,paid.bene_code ,cmas.loss_date ,paid.sts_date ,vsysdate
               , 0 ,paid.pay_amt ,v_hpt_code ,v_clmpdflag ,1 ,paid.sts_date ,F.fam_seq
               ,paid.remark ,paid.recov_amt , v_days ,F.dept_bki ,F.id_no);            
                                                 
            end loop;    
        END LOOP;
                
    end loop; --Cmas           

    COMMIT;
    return true;
EXCEPTION
    WHEN OTHERS THEN
        v_err_message :=     'CONV_PH_RES_REV error:'||sqlerrm;
        dbms_output.put_line (v_err_message);
        rollback;
        return false;
END CONV_PH_RES_REV;


PROCEDURE CONV_TABLE(v_clmno in varchar2,v_payno in varchar2 ,v_prodtype in varchar2
    , v_err_message out varchar2) IS
    v_claim_status VARCHAR2(20);
BEGIN
    v_claim_status := p_ph_clm.GET_CLAIM_STATUS(v_clmno ,null ,'C');
    
    if v_claim_status in ('PHCLMSTS01' ,'PHCLMSTS02') then -- KeyIn Open    
        if not p_ph_convert.CONV_PH_OPEN(v_clmno ,v_payno  ,v_claim_status, v_err_message ) then
            null;
        end if;
    elsif v_claim_status in ('PHCLMSTS03') then -- Draft 
        if not p_ph_convert.CONV_PH_DRAFT(v_clmno ,v_payno  ,v_claim_status, v_err_message ) then
            null;
        end if;    
    elsif v_claim_status in ('PHCLMSTS30' ,'PHCLMSTS31') then -- CWP Cancel 
        if not p_ph_convert.CONV_PH_CWP(v_clmno ,v_payno  ,v_claim_status, v_err_message ) then
            null;
        end if;    
    elsif v_claim_status in ('PHCLMSTS40') then -- CWP Cancel 
        if not p_ph_convert.CONV_PH_REOPEN(v_clmno ,v_payno  ,v_claim_status, v_err_message ) then
            null;
        end if;            
    elsif v_claim_status in ('PHCLMSTS06') then -- Close 
        null;
    end if;
    
   -- return v_err_message;
END CONV_TABLE;

FUNCTION CONV_ADMISSTYPE(v_code in varchar2) RETURN VARCHAR2 IS  

    v_ret varchar2(250);
BEGIN
    IF v_code is null THEN return null ; END IF;
    
    IF v_code in ('PHADMTYPE02' ,'PHADMTYPE03' ) THEN
        v_ret := 'I' ;
        return v_ret;
    END IF;
    
    IF v_code in ('PHADMTYPE01','PHADMTYPE04'  ) THEN
        v_ret := 'O' ;
    ELSE
        v_ret :=null;
    END IF;
    
    return v_ret;                      
END CONV_ADMISSTYPE;   

FUNCTION CONV_CLMSTS(v_code in varchar2) RETURN VARCHAR2 IS  

    v_ret varchar2(250);
BEGIN
    IF v_code is null THEN return null ; END IF;
    
    IF v_code in ('PHCLMSTS01' ,'PHCLMSTS02' ) THEN
        v_ret := '0' ;
        return v_ret;
    END IF;
    
    IF v_code in ('PHCLMSTS03','PHCLMSTS04' ,'PHCLMSTS05'  ) THEN
        v_ret := '6' ;
    ELSIF v_code in ('PHCLMSTS06' ) THEN
        v_ret := '2' ;
    ELSIF v_code in ('PHCLMSTS40' ) THEN
        v_ret := '4' ;   
    ELSE
        v_ret := '3' ;     
    END IF;
    
    return v_ret;                      
END CONV_CLMSTS;   

FUNCTION CONV_CLMSTS_O2N(v_code in varchar2, v_type in varchar2) RETURN VARCHAR2 IS
     -- V_type : 1 (CLM_STS),2 (CLAIM_STATUS)
    v_ret varchar2(250);
    v_clmsts    varchar2(20);
    v_claimsts    varchar2(20); 
BEGIN
    IF v_code is null THEN return null ; END IF;
    
    IF v_code in ('0' ,'1' ) THEN   -- Open /Reserved
        v_clmsts := 'NCCLMSTS01';
        v_claimsts := 'PHCLMSTS02';
    END IF;
    
    IF v_code in ('6'  ) THEN   -- Draft Paid
        v_clmsts := 'NCCLMSTS01';
        v_claimsts := 'PHCLMSTS03';
    ELSIF v_code in ('2' ) THEN -- Close Claim
        v_clmsts := 'NCCLMSTS02';
        v_claimsts := 'PHCLMSTS06';
    ELSIF v_code in ('3' ) THEN -- CWP
        v_clmsts := 'NCCLMSTS03';
        v_claimsts := 'PHCLMSTS30';
    ELSIF v_code in ('4' ) THEN --ReOpen 
        v_clmsts := 'NCCLMSTS04';
        v_claimsts := 'PHCLMSTS40';  
    END IF;
    
    if v_type ='1' then v_ret := v_clmsts; else v_ret := v_claimsts; end if;
    return v_ret;                      
END CONV_CLMSTS_O2N;   

FUNCTION CONV_PAYEETYPE(v_code in varchar2) RETURN VARCHAR2 IS  

    v_ret varchar2(250);
BEGIN
    IF v_code is null THEN return null ; END IF;
    
    IF v_code in ('I' ) THEN
        v_ret := '15' ;
        return v_ret;
    END IF;
    
    IF v_code in ('H'  ) THEN
        v_ret := '01' ;
    ELSE
        v_ret := '16' ;     
    END IF;
    
    return v_ret;                      
END CONV_PAYEETYPE;   

FUNCTION CONV_HOSPITAL(v_code in varchar2) RETURN VARCHAR2 IS  

    v_ret varchar2(250);
BEGIN
    IF v_code is null THEN return null ; END IF;
    
    BEGIN
        select gm_code into v_ret
        from med_hospital_list
        where hosp_id=v_code and rownum=1 ;
        
        if v_ret is null then v_ret := v_code; end if;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_ret := v_code;
        WHEN OTHERS THEN
            v_ret := v_code;
    END;    
    
    return v_ret;                      
END CONV_HOSPITAL;   

FUNCTION CONV_HOSPITAL_NEW(v_code in varchar2) RETURN VARCHAR2 IS  

    v_ret varchar2(250);
BEGIN
    IF v_code is null THEN return null ; END IF;
    
    BEGIN
        select hosp_id into v_ret
        from med_hospital_list
        where gm_code=v_code and rownum=1 ;
        
        if v_ret is null then v_ret := v_code; end if;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_ret := v_code;
        WHEN OTHERS THEN
            v_ret := v_code;
    END;    
    
    return v_ret;                      
END CONV_HOSPITAL_NEW;   

PROCEDURE CONV_CLMTYPE(v_code in varchar2, o_inc out varchar2 ,o_recpt out varchar2 
    ,o_inv out varchar2 ,o_ost out varchar2 ,o_dead out varchar2) IS  

    v_ret varchar2(250);
BEGIN
/*
PHCLMTYPE01    ประเภทเคลมงานระบบ PH    Reimburse
PHCLMTYPE02    ประเภทเคลมงานระบบ PH    Credit
PHCLMTYPE03    ประเภทเคลมงานระบบ PH    Outsource
PHCLMTYPE04    ประเภทเคลมงานระบบ PH    Cancer
PHCLMTYPE05    ประเภทเคลมงานระบบ PH    Death
*/
    IF v_code is null THEN 
        o_inc :=null ; o_recpt :=null ; o_inv :=null ; o_ost :=null ; o_dead :=null ;
    END IF;
    
    IF v_code = 'PHCLMTYPE01' THEN
        o_inc :=null ; o_recpt :='Y' ; o_inv :=null ; o_ost :=null ; o_dead :=null ;
    ELSIF v_code = 'PHCLMTYPE02' THEN
        o_inc :=null ; o_recpt :=null ; o_inv :='Y' ; o_ost :=null ; o_dead :=null ;
    ELSIF v_code = 'PHCLMTYPE03' THEN
        o_inc :=null ; o_recpt :=null ; o_inv :=null ; o_ost :='Y' ; o_dead :=null ;
    ELSIF v_code = 'PHCLMTYPE04' THEN
        o_inc :=null ; o_recpt :=null ; o_inv :=null ; o_ost :=null ; o_dead :='Y' ;
    ELSIF v_code = 'PHCLMTYPE05' THEN
        o_inc :=null ; o_recpt :=null ; o_inv :=null ; o_ost :=null ; o_dead :='Y' ;
    END IF;
                
END CONV_CLMTYPE;   

FUNCTION CONV_CWPCODE(v_code in varchar2) RETURN VARCHAR2 IS  

    v_ret varchar2(25);
BEGIN
    IF v_code is null THEN return null ; END IF;
    
    select remark into v_ret
    from clm_constant x 
    where key = v_code;
--    where key like 'CWPPH-TYPE%'  
    
    return v_ret;      
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    return  null;
    WHEN OTHERS THEN
    return  null;                    
END CONV_CWPCODE;   

FUNCTION SET_SETTLEDATE(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
    v_sysdate   date:=sysdate;
BEGIN 

    Insert into ALLCLM.NC_PAYMENT
       (CLM_NO, PAY_NO, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, PROD_GRP, PROD_TYPE, STS_KEY, TYPE, SUB_TYPE, PREM_CODE, PREM_SEQ, STATUS, TOT_PAY_AMT
       ,CLM_SEQ ,SETTLE_DATE,OFFSET_FLAG ,DAYS ,RECOV_AMT ,DAY_ADD ,REMARK ,subsysid)
       (
        select clm_no, pay_no, trn_seq+1, pay_sts, pay_amt, trn_amt, curr_code, curr_rate, sts_date,v_sysdate, clm_men, amd_user, prod_grp, prod_type, sts_key, type, sub_type, prem_code, prem_seq, status, tot_pay_amt
        ,clm_seq ,v_sysdate ,offset_flag ,days ,recov_amt ,day_add ,remark ,subsysid
        from nc_payment a
        where  a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no and aa.type='NCNATTYPECLM101') 
        and a.pay_no = vPayNo
        and a.type='NCNATTYPECLM101'
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
        ,SEND_ADDR1 ,SEND_ADDR2 ,SALVAGE_FLAG ,EMAIL ,SMS ,APPOINT_DATE ,CURR_RATE ,AGENT_SMS ,AGENT_EMAIL ,SPECIAL_FLAG ,SPECIAL_REMARK ,GRP_PAYEE_FLAG ,URGENT_FLAG
        ,RECOVERY_FLAG ,RECOVERY_AMT ,PAID_TO)
       (
        select clm_no, pay_no, prod_grp, prod_type, trn_seq +1, sts_date, v_sysdate, payee_code, payee_name, payee_type, payee_seq, payee_amt, settle, acc_no, acc_name, bank_code, bank_br_code, br_name, send_title, paid_sts, deduct_flag, type, sent_type, salvage_amt, deduct_amt, curr_code
        ,send_addr1 ,send_addr2 ,salvage_flag ,email ,sms ,appoint_date ,curr_rate ,agent_sms ,agent_email ,special_flag ,special_remark ,grp_payee_flag ,urgent_flag 
        ,recovery_flag ,recovery_amt ,paid_to
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

FUNCTION  VALIDATE_CONVERT924(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN VARCHAR2 IS 
 
 v_chk Varchar2(1):='N'; 
 v_payeeamt number;
 v_key  number:=0;
 v_apprvsts varchar2(20);
 --v_pay_no varchar2(20); 
BEGIN 
    
    IF NOT P_PH_CONVERT.VALIDATE_INDV(vClmNo ,vPayNo ,P_RST ) THEN
        v_chk := 'N';
        return v_chk;
    END IF;
     
    FOR x in (
        select clm_men
        from mis_clm_mas a
        where clm_no = vClmNo
    ) LOOP
        if x.clm_men is null then
             P_RST := vClmNo||': Not Found CLM_MEN ' ; 
            v_chk := 'N';
            return v_chk; 
        end if;
    END LOOP;
    
    begin 
        select nvl(sum(payee_amt),0)
        into v_payeeamt 
        from clm_gm_payee a
        where  clm_no= vClmNo and pay_no = vPayNo
        and nvl(corr_seq,0) = (select nvl(max(aa.corr_seq),0) from clm_gm_payee aa where aa.pay_no = a.pay_no) 
        ;
    exception
        when no_data_found then
            v_payeeamt :=0;
        when others then
            v_payeeamt :=0;
    end;         
    
    if v_payeeamt <=0 then
         P_RST := vClmNo||': Not found Payee Amt ' ; 
        v_chk := 'N';
        return v_chk;     
    end if;

--    BEGIN
--        select nvl(max(trn_seq),0) into v_key
--        from nc_payment a
--        where  pay_no = vPayNo 
--        and type='01'
--        ;
--    exception
--    when no_data_found then
--        v_key    := 0;
--    when others then
--        v_key    := 0;
--    END; 
--    
--    if v_key > 0 then
--         P_RST := vClmNo||': เคย Convert เข้า CLNMC924 แล้ว สามารถตรวจสอบที่ CLNMC924 ได้เลย' ; 
--        v_chk := 'N';
--        return v_chk;     
--    end if;       

    BEGIN
        select pay_sts into v_apprvsts
        from nc_payment a
        where  pay_no = vPayNo 
        and type='01'
        and trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.pay_no = a.pay_no)
        ;
    exception
    when no_data_found then
        v_apprvsts    := null;
    when others then
        v_apprvsts    := null;
    END; 

    if v_apprvsts in ('NCPAYSTS02' ,'NCPAYSTS07' ) then
         P_RST := vClmNo||': อยู่ระหว่างรออนุมัติแล้ว ไม่สามารถ Convert ได้' ; 
        v_chk := 'N';
        return v_chk;     
    elsif v_apprvsts in ('NCPAYSTS03' ,'NCPAYSTS11' ,'NCPAYSTS12' ) then
         P_RST := vClmNo||': อนุมัติแล้ว ไม่สามารถ Convert ได้' ; 
        v_chk := 'N';
        return v_chk;        
    end if;       
             
    v_chk:= 'Y'; 
    return v_chk; 
END VALIDATE_CONVERT924; 
        

FUNCTION  CONVERT924(vClmNo in varchar2 ,vPayNo in varchar2 ,vUser in varchar2 ,P_RST OUT VARCHAR2) RETURN VARCHAR2 IS  
    v_chk Varchar2(1):='N'; 

    v_key number;
    v_sys varchar2(10) :='NCPAYSTS';
    v_max_seq number :=1;
    v_sts varchar2(10) :='NCPAYSTS01';
    v_user varchar2(10);
BEGIN 

    BEGIN
        select nvl(max(trn_seq)+1,1) into v_max_seq
        from nc_payment a
        where pay_no = vPayNo ;
    exception
    when no_data_found then
        v_max_seq    := 1;
    when others then
        v_max_seq    := 1;
    END;
    
    for x in ( select sts_key ,clm_men ,a.clm_no ,b.pay_no ,b.payee_amt ,a.prod_type ,a.prod_grp
        from mis_clm_mas a ,clm_gm_payee b
        where a.clm_no = vClmNo
        and a.clm_no = b.clm_no
        and nvl(b.corr_seq,0) in (select nvl(max(bb.corr_seq),0) from clm_gm_payee bb where bb.pay_no = b.pay_no )
        )
    loop
        if x.sts_key is null then
            v_key := nc_health_package.gen_stskey('');
        else
            v_key := x.sts_key;
        end if;
        
        if vUser is  null then
            v_user := x.clm_men;
        else
            v_user := vUser;
        end if;

        insert into nc_status 
        ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
        values     
        (  v_key ,v_max_seq ,v_sys,v_sts ,'initial Active by Admin' ,v_user , sysdate        
        );    

        INSERT into nc_payment(clm_no ,pay_no ,clm_seq ,trn_seq ,Pay_sts ,pay_amt ,Trn_amt ,Curr_code ,Curr_rate 
        ,Sts_date ,Amd_date ,Clm_men ,Amd_user, APPROVE_ID , Prod_grp ,Prod_type ,SUBSYSID ,Sts_key ,Sub_type 
        ,Type ,apprv_flag ,approve_date ,prem_code ,prem_seq)        
         VALUES (x.CLM_NO , x.pay_no ,1 ,v_max_seq, v_sts , x.payee_amt ,x.payee_amt ,
        'BHT',    1 ,trunc(sysdate),trunc(sysdate) ,x.clm_men ,v_user ,null 
        ,x.prod_grp ,x.prod_type ,'GM',v_key ,'01' ,'01' ,null ,null ,'0000',1) ; 
            
        dbms_output.put_line('clm: '||x.CLM_NO);      
    end loop;    
    
    COMMIT;
    v_chk:= 'Y'; 
    return v_chk; 
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    P_RST := 'error: '||'clmno='||vClmNo||' '||sqlerrm;
    v_chk:= 'N'; 
    return v_chk;         
END CONVERT924; 
        
PROCEDURE  O2N_CONV_RUN_PA(v_Year in VARCHAR2) IS
  d_date  date:='16-jan-16';
  P_RST  VARCHAR2(250);
  v_to varchar2(50):= 'taywin.s@bangkokinsurance.com' ; 
  v_from varchar2(50):= 'AdminClm@bangkokinsurance.com' ; 
  x_body varchar2(5000);
  x_subject varchar2(1000);
  v_rec_str   date:=sysdate;
BEGIN
  x_body := x_body||'Start at '||to_char(v_rec_str ,'DD-MON-YYYY HH24:MI:SS');
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date := '16-jan-'||v_Year;
  -- Jan16
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p  
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  -- Feb16
  d_date  :='16-feb-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-mar-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-apr-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-may-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-jun-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-jul-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-aug-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p           
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-sep-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p  
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-oct-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p     
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-nov-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p         
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-dec-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PA(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p  
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  x_body := x_body||'<br/>' ||' End: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  x_subject:='Run Convert O2N PA';
  nc_health_package.generate_email(v_from, v_to ,
  x_subject, 
  x_body 
  ,''
  ,'');    
EXCEPTION
    WHEN OTHERS THEn
        dbms_output.put_line('error: '||sqlerrm); 
        x_subject := x_subject||' [error]';
        x_body := x_body||'<br/>'||sqlerrm;
          nc_health_package.generate_email(v_from, v_to ,
          x_subject, 
          x_body 
          ,''
          ,'');            
END O2N_CONV_RUN_PA;


PROCEDURE  O2N_CONV_RUN_GM(v_Year in VARCHAR2) IS
  d_date  date:='16-jan-16';
  P_RST  VARCHAR2(250);
  v_to varchar2(50):= 'taywin.s@bangkokinsurance.com' ; 
  v_from varchar2(50):= 'AdminClm@bangkokinsurance.com' ; 
  x_body varchar2(5000);
  x_subject varchar2(1000);
  v_rec_str   date:=sysdate;
BEGIN
  x_body := x_body||'Start at '||to_char(v_rec_str ,'DD-MON-YYYY HH24:MI:SS');
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date := '16-jan-'||v_Year;
  -- Jan16
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p  
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  -- Feb16
  d_date  :='16-feb-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-mar-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-apr-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-may-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-jun-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-jul-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-aug-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p           
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-sep-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p  
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-oct-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p     
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-nov-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p         
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  d_date  :='16-dec-'||v_Year;
  x_body := x_body||'<br/>'||' query date: '||to_char(d_date ,'DD-MON-YYYY HH24:MI:SS');
  for p in (
    select day_of_month
    from
    (select (level - 1) + trunc(d_date,'MM') day_of_month
    from
    dual
    connect by level <= 31)
    where day_of_month < add_months(trunc(d_date,'MM'),1)  
  )loop
    dbms_output.put_line('Run As Day:'||p.day_of_month);
    IF NOT P_PH_CONVERT.O2N_CONV_PH(p.day_of_month ,null ,P_RST )THEN
       DBMS_OUTPUT.PUT_LINE(P_RST);
    END IF;
  end loop; --p  
  x_body := x_body||'<br/>'||' Result: '||P_RST||' finish: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  x_body := x_body||'<br/>' ||' End: '||to_char(sysdate ,'DD-MON-YYYY HH24:MI:SS');
  
  x_subject:='Run Convert O2N PH';
  nc_health_package.generate_email(v_from, v_to ,
  x_subject, 
  x_body 
  ,''
  ,'');    
EXCEPTION
    WHEN OTHERS THEn
        dbms_output.put_line('error: '||sqlerrm); 
        x_subject := x_subject||' [error]';
        x_body := x_body||'<br/>'||sqlerrm;
          nc_health_package.generate_email(v_from, v_to ,
          x_subject, 
          x_body 
          ,''
          ,'');            
END O2N_CONV_RUN_GM;

FUNCTION O2N_CONV_PA(v_Date in Date ,v_CLMNO in VARCHAR2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS -- Convert PA Claim
    cnt NUMBER(10):=0;
    V_SYSDATE   date:=sysdate;
    V_SYSDATE_T date:=trunc(sysdate);
    v_CLMTYPE  VARCHAR2(20);
    v_ADMTYPE   VARCHAR2(20);
    v_CLMSTS   VARCHAR2(20);
    v_CLAIMSTATUS   VARCHAR2(20);
    v_HPTCODE   VARCHAR2(20);
    v_HPTSEQ    NUMBER(2);
    v_STSKEY    NUMBER;
    v_DummClm    VARCHAR2(20);
    v_existCPA_RES  VARCHAR2(20);
    v_PAYNO  VARCHAR2(20);
    v_PAID_CORRSEQ    NUMBER;
    V_LOSS_DATE_FR DATE;
    V_LOSS_DATE_TO DATE;
    V_LOSS_OF_DAY NUMBER;
    V_ADD_DAY NUMBER;
    V_PAIDTO    VARCHAR2(2);
    V_CWPCODE   VARCHAR2(25);
    V_SETTLE_DATE   DATE;
    p1_rst  VARCHAR2(250);
    p2_rst  VARCHAR2(250);
    v_sid NUMBER;
    v_seq   NUMBER:=0;
    
    v_max_ncres NUMBER(10);
    v_max_ncpay NUMBER(10);
    v_max_rires    NUMBER(10);    
    v_max_ripay    NUMBER(10);  
    v_max_payee    NUMBER(10);      
    v_max_apprvseq    NUMBER(10);    
    v_ncres_stsdate date:=v_Date;
    v_ncpay_stsdate date:=v_Date;
    v_rires_stsdate date:=v_Date;   
    v_ripay_stsdate date:=v_Date;
    v_payee_stsdate date:=v_Date;
    v_user  VARCHAR2(20):='CONVERT';
    v_approve_id    VARCHAR2(10);
    v_idno  VARCHAR2(20);
BEGIN
    FOR M1 IN (
--        select a.sts_key ,a.clm_no ,'' pay_no ,fleet_seq ,recpt_seq ,a.pol_no ,a.pol_run ,reg_date ,nvl(c.close_date ,trunc(c.corr_date)) corr_date ,a.loss_date ,c.clm_sts , dis_code ,risk_code ,c.tot_res
--        ,decode(ipd_flag,'O','OPD','I','IPD','OPD') CLM_TYPE ,a.clm_date ,a.prod_grp ,a.prod_type ,a.close_date ,c.tot_paid
         select distinct a.sts_key, a.clm_no ,ord_no reg_no, a.pol_no, a.pol_run, end_seq, recpt_seq, clm_yr, pol_yr, a.prod_grp, a.prod_type, fleet_seq,'' id_no,'' ipd_flag, dis_code, b.risk_code cause_code, '' cause_seq
        , reg_date, a.clm_date, a.loss_date, fr_date, to_date,loss_date_fr tr_date_fr, loss_date_to tr_date_to, loss_of_day tot_tr_day, add_day add_tr_day, c.close_date, c.reopen_date, alc_re, loss_detail,a.clm_men clm_user,'' invoice_no, hpt_code, hpt_seq,'' hn_no
        , mas_cus_code, mas_cus_seq, mas_cus_enq mas_cus_name, cus_code, cus_seq, b.loss_name cus_name, fax_clm_date, mas_sum_ins, recpt_sum_ins, ''Sub_cause_code
        , c.clm_sts, remark, cwp_remark, a.rem_close cwp_code, cwp_user, card_id_type, card_id_no, card_other_type, card_other_no, card_updatedate
        , complete_code, complete_user, '' admission_type, '' clm_type 
        , receipt, invoice, walkin, fax_clm, deathclm
        ,c.corr_date, curr_code, curr_rate, a.tot_paid
        from mis_clm_mas a ,mis_cpa_res b ,mis_clm_mas_seq c
        where a.clm_no = b.clm_no and a.clm_no = c.clm_no and a.prod_grp = '0' 
        and a.prod_type in (select prod_type from clm_grp_prod where sysid='PA') 
--        and nvl(c.close_date ,trunc(c.corr_date)) = v_Date
        and trunc(c.corr_date) = v_Date
        and (b.clm_no ,b.revise_seq) in (select bb.clm_no ,max(bb.revise_seq) from mis_cpa_res bb where bb.clm_no =b.clm_no 
            and trunc(bb.corr_date) <= v_Date group by bb.clm_no)
        and c.corr_seq in (select max(cc.corr_seq) from mis_clm_mas_seq cc where cc.clm_no = c.clm_no 
--            and nvl(cc.close_date ,trunc(cc.corr_date))  <= v_Date
            and trunc(cc.corr_date) = v_Date
            )            
--        and b.corr_date <= i_asdate
        and a.clm_no like nvl(v_CLMNO,'%')
        and a.channel <> '9'
        order by a.clm_no   
    )LOOP
        cnt := cnt+1;   v_DummClm := M1.CLM_NO;
        dbms_output.put_line('clm: '||M1.CLM_NO||' sts: '||M1.CLM_STS||' Corr_Date: '||M1.CORR_DATE);
        if M1.IPD_FLAG = 'O' then v_ADMTYPE := 'PHADMTYPE01'; 
        elsif  M1.IPD_FLAG = 'I' then v_ADMTYPE := 'PHADMTYPE02'; 
        else v_ADMTYPE := 'PHADMTYPE99';  end if;
        
        if M1.receipt is not null then
            v_CLMTYPE := 'PHCLMTYPE01';
        elsif M1.invoice is not null then
            v_CLMTYPE := 'PHCLMTYPE02';
        elsif M1.walkin is not null then    --ost
            v_CLMTYPE := 'PHCLMTYPE03';
        elsif M1.fax_clm is not null then   --ชดเชยรายได้
            v_CLMTYPE := 'PHCLMTYPE06';
        elsif M1.deathclm is not null then
            v_CLMTYPE := 'PHCLMTYPE05';
        else
            null;
        end if;
        
        v_HPTCODE := M1.HPT_CODE;
        v_HPTSEQ := M1.HPT_SEQ;
        
        v_CLMSTS := P_PH_CONVERT.CONV_CLMSTS_O2N(M1.CLM_STS ,'1');
        v_CLAIMSTATUS := P_PH_CONVERT.CONV_CLMSTS_O2N(M1.CLM_STS ,'2');
        
        if M1.CWP_CODE is not null then
            v_CWPCODE := p_ph_convert.CONV_CWPCODE(M1.CWP_CODE);
        end if;
        
        V_SETTLE_DATE := null;
        if M1.CLM_STS = '2' then V_SETTLE_DATE := M1.CLOSE_DATE; end if;

        v_idno := nvl(m1.card_id_no ,m1.card_other_no);
        if v_idno is null then
            v_idno := nc_health_paid.GET_CARDNO(m1.pol_no  ,m1.pol_run ,m1.fleet_seq ,m1.recpt_seq
                        ,null ,null,null ,m1.clm_no ,null);
        end if;
        
        dbms_output.put_line('v_CLMSTS='||v_CLMSTS||' v_CLAIMSTATUS='||v_CLAIMSTATUS);
        if M1.STS_KEY is null then
            v_STSKEY := NC_HEALTH_PACKAGE.GEN_STSKEY(null);
            UPDATE MIS_CLM_MAS
            set STS_KEY = v_STSKEY
            WHERE CLM_NO = M1.CLM_NO;
        else
            v_STSKEY := M1.STS_KEY;
        end if;

        begin -- max v_max_ncres
            select  nvl(max(trn_seq),0)+1 into v_max_ncres
            from nc_reserved 
            where clm_no = M1.CLM_NO;
        exception
            when no_data_found then 
                v_max_ncres := 1;
            when others then
                v_max_ncres := 1;
        end;  -- max v_max_ncres    
        if v_max_ncres >1 then -- get First STS_DATE
            select sts_date into v_ncres_stsdate
            from nc_reserved a
            where clm_no = M1.CLM_NO and rownum=1;
        end if;

        begin -- max v_max_rires
            select  nvl(max(trn_seq),0)+1 into v_max_rires
            from nc_ri_reserved 
            where clm_no = M1.CLM_NO;
        exception
            when no_data_found then 
                v_max_rires := 1;
            when others then
                v_max_rires := 1;
        end;  -- max v_max_rires    
        if v_max_rires >1 then -- get First STS_DATE
            select ri_sts_date into v_rires_stsdate
            from nc_ri_reserved a
            where clm_no = M1.CLM_NO and rownum=1;
        end if;
        
        -- ============== Set Reserved  & Mas           
        IF NOT p_ph_convert.IS_EXIST_NC_MAS(M1.CLM_NO) THEN -- not found NC_MAS
            Insert into ALLCLM.NC_MAS
            (STS_KEY, CLM_NO ,REG_NO, POL_NO, POL_RUN, END_SEQ, RECPT_SEQ, CLM_YR, POL_YR, PROD_GRP, PROD_TYPE, FLEET_SEQ, ID_NO, IPD_FLAG, DIS_CODE, CAUSE_CODE, CAUSE_SEQ
            , REG_DATE, CLM_DATE, LOSS_DATE, FR_DATE, TO_DATE, TR_DATE_FR, TR_DATE_TO, TOT_TR_DAY, CLOSE_DATE, REOPEN_DATE, ALC_RE, LOSS_DETAIL, CLM_USER, INVOICE_NO, HPT_CODE, HPT_SEQ, HN_NO
            , MAS_CUS_CODE, MAS_CUS_SEQ, MAS_CUS_NAME, CUS_CODE, CUS_SEQ, CUS_NAME, FAX_CLM, FAX_CLM_DATE, MAS_SUM_INS, RECPT_SUM_INS, SUB_CAUSE_CODE
            , CLM_STS, REMARK, CWP_REMARK, CWP_CODE, CWP_USER, CARD_ID_TYPE, CARD_ID_NO, CARD_OTHER_TYPE, CARD_OTHER_NO, CARD_UPDATEDATE
            , COMPLETE_CODE, COMPLETE_USER, CLAIM_STATUS, ADMISSION_TYPE, CLM_TYPE, CONVERT_FLAG)   
            VALUES
            (v_STSKEY, M1.CLM_NO ,M1.REG_NO, M1.POL_NO, M1.POL_RUN, M1.END_SEQ, M1.RECPT_SEQ, M1.CLM_YR, M1.POL_YR, M1.PROD_GRP, M1.PROD_TYPE, M1.FLEET_SEQ, V_IDNO, M1.IPD_FLAG, M1.DIS_CODE, M1.CAUSE_CODE, M1.CAUSE_SEQ
            , M1.REG_DATE, M1.CLM_DATE, M1.LOSS_DATE, M1.FR_DATE, M1.TO_DATE, M1.TR_DATE_FR, M1.TR_DATE_TO, M1.TOT_TR_DAY, M1.CLOSE_DATE, M1.REOPEN_DATE, M1.ALC_RE, M1.LOSS_DETAIL, M1.CLM_USER, M1.INVOICE_NO, v_HPTCODE, v_HPTSEQ, M1.HN_NO
            , M1.MAS_CUS_CODE, M1.MAS_CUS_SEQ, M1.MAS_CUS_NAME, M1.CUS_CODE, M1.CUS_SEQ, M1.CUS_NAME, M1.FAX_CLM, M1.FAX_CLM_DATE, M1.MAS_SUM_INS, M1.RECPT_SUM_INS, M1.SUB_CAUSE_CODE
            , v_CLMSTS, M1.REMARK, M1.CWP_REMARK, v_CWPCODE, M1.CWP_USER, M1.CARD_ID_TYPE, M1.CARD_ID_NO, M1.CARD_OTHER_TYPE, M1.CARD_OTHER_NO, M1.CARD_UPDATEDATE
            , M1.COMPLETE_CODE, M1.COMPLETE_USER, v_CLAIMSTATUS, M1.ADMISSION_TYPE, v_CLMTYPE, 'Y');         
        ELSE
            dbms_output.put_line('Exist CLM_NO in NC_MAS STS_KEY='||v_STSKEY);
            nc_health_package.save_ncmas_history(v_STSKEY ,p1_rst);
            if p1_rst is not null then
                dbms_output.put_line('save_ncmas_history Error: '||p1_rst);
                NC_HEALTH_PAID.WRITE_LOG ('CONVERT_PA' , 'PROGRAM' ,'Schedule Run','save_ncmas_history' ,'save_ncmas_history Error: '||p1_rst ,'error' ,p2_rst) ;
            end if;
            UPDATE ALLCLM.NC_MAS
            SET LOSS_DATE = M1.LOSS_DATE,TR_DATE_FR = M1.TR_DATE_FR,TR_DATE_TO = M1.TR_DATE_TO,TOT_TR_DAY= M1.TOT_TR_DAY ,CLOSE_DATE = M1.CLOSE_DATE,REOPEN_DATE =  M1.REOPEN_DATE ,LOSS_DETAIL = M1.LOSS_DETAIL
            ,CLM_USER = M1.CLM_USER,HPT_CODE = v_HPTCODE,HPT_SEQ = v_HPTSEQ,IPD_FLAG = M1.IPD_FLAG ,DIS_CODE = M1.DIS_CODE,CAUSE_CODE = M1.CAUSE_CODE,CAUSE_SEQ = M1.CAUSE_SEQ
            ,MAS_CUS_CODE = M1.MAS_CUS_CODE,MAS_CUS_SEQ = M1.MAS_CUS_SEQ,MAS_CUS_NAME = M1.MAS_CUS_NAME,CUS_CODE = M1.CUS_CODE,CUS_SEQ = M1.CUS_SEQ,CUS_NAME = M1.CUS_NAME
            ,FAX_CLM_DATE = M1.FAX_CLM_DATE,MAS_SUM_INS = M1.MAS_SUM_INS,RECPT_SUM_INS = M1.RECPT_SUM_INS,REMARK= M1.REMARK, CWP_REMARK= M1.CWP_REMARK, CWP_CODE= v_CWPCODE, CWP_USER= M1.CWP_USER, CARD_ID_TYPE= M1.CARD_ID_TYPE, CARD_ID_NO= M1.CARD_ID_NO
            ,CARD_OTHER_TYPE = M1.CARD_OTHER_TYPE ,CARD_OTHER_NO= M1.CARD_OTHER_NO, CARD_UPDATEDATE= M1.CARD_UPDATEDATE
            ,ID_NO = V_IDNO ,CLM_DATE = M1.CLM_DATE ,REG_DATE =  M1.REG_DATE
            ,COMPLETE_CODE = M1.COMPLETE_CODE, COMPLETE_USER= M1.COMPLETE_USER,CLM_STS= v_CLMSTS, CLAIM_STATUS = v_CLAIMSTATUS, ADMISSION_TYPE = M1.ADMISSION_TYPE, CLM_TYPE=v_CLMTYPE, CONVERT_FLAG= 'Y'
            WHERE CLM_NO = M1.CLM_NO;
        END IF;
        
       
        IF  p_ph_convert.IS_FOUND_CPARES(M1.CLM_NO) THEN -- check Found Cpa_Res
            P_OIC_PAPH_CLM.GET_PA_RESERVE(M1.CLM_NO,
                                            v_sid,
                                            p1_rst);          
                                    
            if p1_rst is null then
                v_seq :=0;
                FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
                from NC_H_HISTORY_TMP
                where sid = v_sid )
                LOOP    
                    v_seq := v_seq+1;
                    Insert into ALLCLM.NC_RESERVED
                    (STS_KEY, CLM_NO, PROD_GRP, PROD_TYPE, TYPE, SUB_TYPE, TRN_SEQ, STS_DATE, AMD_DATE
                    , PREM_CODE, PREM_SEQ, RES_AMT, CLM_USER, AMD_USER)
                    VALUES
                    (v_STSKEY, M1.CLM_NO, M1.PROD_GRP, M1.PROD_TYPE, 'NCNATTYPECLM101', 'NCNATSUBTYPECLM101', v_max_ncres, v_ncres_stsdate, v_Date
                    , p1.PREM_CODE, v_seq, p1.amount, v_user, v_user);
                                    
                END LOOP;      -- loop get Reserved
            end if;        
            NC_HEALTH_PACKAGE.remove_history_clm(v_sid);               
        END IF; -- Found CPA_RES in Date  
            
        FOR R1 in (
            select 0 STS_KEY, CLM_NO, '' PROD_GRP, '' PROD_TYPE, 'x' TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG RI_LF_FLAG, RI_SUB_TYPE, RI_SHR RI_SHARE, 1 TRN_SEQ
            , '' RI_STS_DATE, '' RI_AMD_DATE, RI_RES_AMT, RI_RES_AMT RI_TRN_AMT
            , LETT_TYPE, '' STATUS, LETT_PRT, 'x' SUB_TYPE, RI_RES_AMT ORG_RI_RES_AMT
            from mis_cri_res a
            where clm_no = M1.CLM_NO
            and corr_seq in (select max(aa.corr_seq) from mis_cri_res aa where aa.clm_no = a.clm_no --and ri_res_date = V_DATE
            )          
        )LOOP
            Insert into ALLCLM.NC_RI_RESERVED
            (STS_KEY, CLM_NO, PROD_GRP, PROD_TYPE, TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_SHARE, TRN_SEQ
            , RI_STS_DATE, RI_AMD_DATE, RI_RES_AMT, RI_TRN_AMT
            , LETT_TYPE, STATUS, LETT_PRT, SUB_TYPE, ORG_RI_RES_AMT)
            Values   
            (v_STSKEY, R1.CLM_NO, M1.PROD_GRP, M1.PROD_TYPE, 'NCNATTYPECLM101', R1.RI_CODE, R1.RI_BR_CODE, R1.RI_TYPE, R1.RI_LF_FLAG, R1.RI_SUB_TYPE, R1.RI_SHARE, v_max_rires
            , v_rires_stsdate, v_Date, R1.RI_RES_AMT, R1.RI_TRN_AMT
            , R1.LETT_TYPE, 'NCCLMSTS01', R1.LETT_PRT, 'NCNATSUBTYPECLM101', R1.ORG_RI_RES_AMT)   ;        
        END LOOP; --R1        
        COMMIT;
        
        IF M1.CLM_STS in ('6','2') THEN -- Draft and Paid
            begin 
                select pay_no   into v_PAYNO 
                from mis_clm_paid b
                where clm_no = M1.CLM_NO
                and (b.pay_no ,b.corr_seq) in (select bb.pay_no ,max(bb.corr_seq) from mis_clm_paid bb where bb.pay_no =b.pay_no 
                and trunc(bb.corr_date) <= V_DATE
                group by bb.pay_no)
--                    and pay_total <> 0 and pay_date is not null  
                and rownum=1;
            exception
                when no_data_found then
                    v_PAYNO := '';  v_PAID_CORRSEQ :=0;
                when others then
                    v_PAYNO := '';  v_PAID_CORRSEQ :=0;
            end;
                    
            begin -- max v_max_ncpay
                select  nvl(max(trn_seq),0)+1 into v_max_ncpay
                from nc_payment
                where pay_no =v_PAYNO and type<>'01' ;
            exception
                when no_data_found then 
                    v_max_ncpay := 1;
                when others then
                    v_max_ncpay := 1;
            end;  -- max v_max_ncpay    
            if v_max_ncpay >1 then -- get First STS_DATE
                select sts_date into v_ncpay_stsdate
                from nc_payment a
                where pay_no = v_PAYNO and type<>'01' and rownum=1;
            end if;
            
            begin -- max v_max_ripay
                select  nvl(max(trn_seq),0)+1 into v_max_ripay
                from nc_ri_paid
                where pay_no =v_PAYNO;
            exception
                when no_data_found then 
                    v_max_ripay := 1;
                when others then
                    v_max_ripay := 1;
            end;  -- max v_max_ripay    
            if v_max_ripay >1 then -- get First STS_DATE
                select ri_sts_date into v_ripay_stsdate
                from nc_ri_paid a
                where  pay_no = v_PAYNO and rownum=1;
            end if;     
            
            begin -- max v_max_payee
                select  nvl(max(trn_seq),0)+1 into v_max_payee
                from nc_payee
                where pay_no =v_PAYNO;
            exception
                when no_data_found then 
                    v_max_payee := 1;
                when others then
                    v_max_payee := 1;
            end;  -- max v_max_ncpay    
            if v_max_payee >1 then -- get First STS_DATE
                select sts_date into v_payee_stsdate
                from nc_payee a
                where pay_no = v_PAYNO and rownum=1;
            end if;                   
            
            dbms_output.put_line('payno: '||v_PAYNO);               
            if v_PAYNO is not null and p_ph_convert.IS_FOUND_CPAPAID(M1.CLM_NO ,v_PAYNO) then
                select corr_seq into v_PAID_CORRSEQ
                from mis_cpa_paid a
                where pay_no = v_PAYNO
                and corr_seq in (select max(aa.corr_seq) from mis_cpa_paid aa where aa.clm_no = a.clm_no) ;
                
                p_oic_paph_clm.get_pa_paid(V_PAYNO, v_PAID_CORRSEQ ,
                                                v_sid,
                                                p1_rst);                                                           
                dbms_output.put_line('get_pa_paid p1_rst: '||p1_rst);                       
                if p1_rst is null then 
                    v_seq :=0;
                    begin
                    select loss_date_fr ,loss_date_to ,loss_of_day ,add_day into  v_loss_date_fr ,v_loss_date_to ,v_loss_of_day ,v_add_day
                    from mis_cpa_paid a
                    where pay_no = v_PAYNO 
                    and corr_seq in (select max(aa.corr_seq) from mis_cpa_paid aa where aa.clm_no = a.clm_no) ;                    
                    exception
                        when no_data_found then 
                            v_loss_date_fr :=null; v_loss_date_to :=null;v_loss_of_day :=0;v_add_day:=0;
                        when others then
                            v_loss_date_fr :=null; v_loss_date_to :=null;v_loss_of_day :=0;v_add_day:=0;
                    end;  --     
                                
                    FOR p1 IN (select CLM_NO PAY_NO ,PREM_CODE ,AMOUNT
                    from NC_H_HISTORY_TMP
                    where sid = v_sid  and AMOUNT > 0
                    )
                    LOOP  
                        v_seq := v_seq+1;  
                        Insert into ALLCLM.NC_PAYMENT
                        (STS_KEY, CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, STS_DATE, AMD_DATE, SETTLE_DATE, CLM_MEN, AMD_USER
                        , PROD_GRP, PROD_TYPE, SUBSYSID, TYPE, SUB_TYPE, PREM_CODE, PREM_SEQ
                        , STATUS, DAYS, RECOV_AMT, DAY_ADD, REMARK)
                        VALUES
                        (v_STSKEY, M1.CLM_NO, V_PAYNO, 1, v_max_ncpay, p1.AMOUNT, p1.AMOUNT, M1.CURR_CODE, M1.CURR_RATE, v_ncpay_stsdate, V_DATE, V_SETTLE_DATE, v_user, v_user
                        , M1.PROD_GRP, M1.PROD_TYPE, 'PA', 'NCNATTYPECLM101', 'NCNATSUBTYPECLM101', P1.PREM_CODE, v_seq
                        , 'NCPAYMENTSTS02', v_loss_of_day, 0, v_add_day, ''
                        );
                                                                                    
                    END LOOP;  --p1_rst    
                
                end if;
                NC_HEALTH_PACKAGE.remove_history_clm(v_sid); 
                
                FOR R1 in (
                    select clm_no, pay_no, payee_code, payee_name, payee_type, pay_seq payee_seq, payee_amt
                    , settle, acc_no, acc_name, bank_code, bank_br_code, br_name, send_title, send_addr1, send_addr2
                    , mobile_number sms, cust_mail email, agent_mobile_number agent_sms,agent_mail agent_email, special_flag, special_remark
                    , urgent_flag, invalid_payee, invalid_payee_remark
                    from mis_clm_payee a
                    where pay_no = v_PAYNO         
                )LOOP
                    Insert into ALLCLM.NC_PAYEE
                    (CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TRN_SEQ, STS_DATE, AMD_DATE, PAYEE_CODE, PAYEE_NAME, PAYEE_TYPE, PAYEE_SEQ, PAYEE_AMT
                    , SETTLE, ACC_NO, ACC_NAME, BANK_CODE, BANK_BR_CODE, BR_NAME, SEND_TITLE, SEND_ADDR1, SEND_ADDR2
                    , SMS, EMAIL, CURR_CODE, CURR_RATE, AGENT_SMS, AGENT_EMAIL, SPECIAL_FLAG, SPECIAL_REMARK
                    , URGENT_FLAG, INVALID_PAYEE, INVALID_PAYEE_REMARK
                    , CREATE_USER, AMD_USER, PAID_TO)
                    Values
                    (R1.CLM_NO, R1.PAY_NO, M1.PROD_GRP, M1.PROD_TYPE, v_max_payee, v_payee_stsdate, V_DATE, R1.PAYEE_CODE, R1.PAYEE_NAME, R1.PAYEE_TYPE, R1.PAYEE_SEQ, R1.PAYEE_AMT
                    , R1.SETTLE, R1.ACC_NO, R1.ACC_NAME, R1.BANK_CODE, R1.BANK_BR_CODE, R1.BR_NAME, R1.SEND_TITLE, R1.SEND_ADDR1, R1.SEND_ADDR2
                    , R1.SMS, R1.EMAIL, M1.CURR_CODE, M1.CURR_RATE, R1.AGENT_SMS, R1.AGENT_EMAIL, R1.SPECIAL_FLAG, R1.SPECIAL_REMARK
                    , R1.URGENT_FLAG, R1.INVALID_PAYEE, R1.INVALID_PAYEE_REMARK
                    , v_user, v_user, V_PAIDTO);
                END LOOP; --R1
                
                FOR NR in (
                    select 0 STS_KEY, PAY_NO, CLM_NO, '' PROD_GRP, '' PROD_TYPE, 'NCNATTYPECLM101' TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG RI_LF_FLAG, RI_SUB_TYPE
                    , (select RI_SHARE from nc_ri_reserved nr where nr.clm_no = a.clm_no and nr.trn_seq = (select max(nrr.trn_seq) from nc_ri_reserved nrr where nrr.clm_no = nr.clm_no) 
                    and nr.ri_code = a.ri_code and nr.ri_br_code = a.ri_br_code and nr.ri_type = a.ri_type and nr.ri_sub_type = a.ri_sub_type) RI_SHARE
                    , 1 TRN_SEQ, '' RI_STS_DATE, '' RI_AMD_DATE, pay_amt RI_PAY_AMT, pay_amt RI_TRN_AMT
                    , LETT_NO, LETT_TYPE, '' STATUS, LETT_PRT, 'NCNATSUBTYPECLM101' SUB_TYPE
                    from mis_cri_paid a
                    where pay_no = v_PAYNO
                    and corr_seq in (select max(aa.corr_seq) from mis_cri_paid aa where aa.pay_no = a.pay_no) 
                )LOOP
                    Insert into ALLCLM.NC_RI_PAID
                    (STS_KEY, CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_SHARE, TRN_SEQ
                    , LETT_NO, LETT_PRT, RI_STS_DATE, RI_AMD_DATE, RI_PAY_AMT, RI_TRN_AMT, LETT_TYPE, STATUS, SUB_TYPE)
                    Values
                    (v_STSKEY, NR.CLM_NO, NR.PAY_NO, M1.PROD_GRP, M1.PROD_TYPE, NR.TYPE, NR.RI_CODE, NR.RI_BR_CODE, NR.RI_TYPE, NR.RI_LF_FLAG, NR.RI_SUB_TYPE, NR.RI_SHARE, v_max_ripay
                    , NR.LETT_NO, NR.LETT_PRT, v_ripay_stsdate, V_DATE, NR.RI_PAY_AMT, NR.RI_TRN_AMT, NR.LETT_TYPE, NR.STATUS, NR.SUB_TYPE);                
                END LOOP; -- NR 

            end if; -- check V_PAYNO
            
            if M1.CLM_STS = '2' then
                begin -- max v_max_apprvseq
                    select  nvl(max(trn_seq),0)+1 into v_max_apprvseq
                    from nc_payment_apprv
                    where pay_no =v_PAYNO;
                exception
                    when no_data_found then 
                        v_max_apprvseq := 1;
                    when others then
                        v_max_apprvseq := 1;
                end;  -- max v_max_apprvseq  
                begin -- apprv_id
                    select approve_id into v_approve_id
                    from nc_payment a
                    where pay_no =v_PAYNO and type='01'
                    and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type='01' and aa.pay_no = a.pay_no);
                exception
                    when no_data_found then 
                        v_approve_id := null;
                    when others then
                        v_approve_id := null;
                end;  -- max apprv_id                  
                
                INSERT into nc_payment_apprv(clm_no ,pay_no ,clm_seq ,trn_seq ,Pay_sts ,pay_amt ,Trn_amt ,Curr_code ,Curr_rate
                ,Sts_date ,Amd_date ,Clm_men ,Amd_user, APPROVE_ID ,approve_date , Prod_grp ,Prod_type ,SUBSYSID ,Sts_key ,Sub_type ,Type ,apprv_flag ,remark)
                VALUES (M1.CLM_NO , v_payno ,1 ,v_max_apprvseq, 'PHSTSAPPRV03' ,M1.TOT_PAID ,M1.TOT_PAID,
                M1.CURR_CODE, M1.CURR_RATE ,v_date ,v_date ,v_user ,v_user ,v_approve_id ,M1.CLOSE_DATE
                ,M1.PROD_GRP ,M1.PROD_TYPE, 'PH' ,v_STSKEY ,'NCNATSUBTYPECLM101' ,'NCNATTYPECLM101' ,'Y' ,'Convert data') ;

                UPDATE NC_MAS
                SET APPROVE_STATUS =  'PHSTSAPPRV03'
                WHERE CLM_NO = M1.CLM_NO;                
            end if; -- if M1.CLM_STS = '2' then
        
        END IF; -- check CLM_STS 6,2
       
        -- End ============== Set Reserved  & Mas   =============
        
        
    END LOOP; --M1
    
    COMMIT;
    return true;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    P_RST := 'error: '||'clmno='||v_DummClm||' '||sqlerrm;
    dbms_output.put_line(P_RST);
    NC_HEALTH_PAID.WRITE_LOG ('CONVERT_PA' , 'PROGRAM' ,'Schedule Run','Generate Data' ,P_RST ,'error' ,p1_rst) ;
    return false;   
END O2N_CONV_PA;


FUNCTION O2N_CONV_PH(v_Date in Date ,v_CLMNO in VARCHAR2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS -- Convert PH Claim
    cnt NUMBER(10):=0;
    V_SYSDATE   date:=sysdate;
    V_SYSDATE_T date:=trunc(sysdate);
    v_CLMTYPE  VARCHAR2(20);
    v_ADMTYPE   VARCHAR2(20);
    v_CLMSTS   VARCHAR2(20);
    v_CLAIMSTATUS   VARCHAR2(20);
    v_HPTCODE   VARCHAR2(20);
    v_HPTSEQ    NUMBER(2);
    v_STSKEY    NUMBER;
    v_DummClm    VARCHAR2(20);
    v_existCPA_RES  VARCHAR2(20);
    v_PAYNO  VARCHAR2(20);
    v_PAID_CORRSEQ    NUMBER;
    V_LOSS_DATE_FR DATE;
    V_LOSS_DATE_TO DATE;
    V_LOSS_OF_DAY NUMBER;
    V_ADD_DAY NUMBER;
    V_PAIDTO    VARCHAR2(2);
    V_CWPCODE   VARCHAR2(25);
    V_SETTLE_DATE DATE;
    p1_rst  VARCHAR2(250);
    p2_rst  VARCHAR2(250);
    v_sid NUMBER;
    v_seq   NUMBER:=0;
    
    v_max_ncres NUMBER(10);
    v_max_ncpay NUMBER(10);
    v_max_rires    NUMBER(10);    
    v_max_ripay    NUMBER(10);  
    v_max_payee    NUMBER(10);     
    v_max_apprvseq    NUMBER(10);     
    v_ncres_stsdate date:=v_Date;
    v_ncpay_stsdate date:=v_Date;
    v_rires_stsdate date:=v_Date;   
    v_ripay_stsdate date:=v_Date;
    v_payee_stsdate date:=v_Date;
    v_user  VARCHAR2(20):='CONVERT';
    v_approve_id    VARCHAR2(10);
    v_idno  VARCHAR2(20);
BEGIN
    FOR M1 IN (
         select distinct a.sts_key, a.clm_no ,ord_no reg_no, a.pol_no, a.pol_run, a.end_seq, b.recpt_seq, clm_yr, pol_yr, a.prod_grp, a.prod_type, fleet_seq, b.id_no,clm_pd_flag ipd_flag, b.dis_code, '' cause_code, '' cause_seq
        , reg_date, a.clm_date, b.loss_date, b.fr_date, b.to_date,'' tr_date_fr, '' tr_date_to, b.ipd_day tot_tr_day, '' add_tr_day, c.close_date, c.reopen_date, alc_re,RISK_DESCR loss_detail,a.clm_men clm_user,'' invoice_no, hpt_code,'' hpt_seq,'' hn_no
        , mas_cus_code, mas_cus_seq, mas_cus_enq mas_cus_name, cus_code, cus_seq, b.title||' '||b.name cus_name, fax_clm_date, mas_sum_ins, recpt_sum_ins, ''Sub_cause_code
        , c.clm_sts, a.remark, cwp_remark, a.rem_close cwp_code, cwp_user, card_id_type, card_id_no, card_other_type, card_other_no, card_updatedate
        , complete_code, complete_user, '' admission_type, '' clm_type 
        , receipt, invoice, walkin, fax_clm, deathclm 
        ,c.corr_date, curr_code, curr_rate, a.tot_paid        
        from mis_clm_mas a ,clm_medical_res b ,mis_clm_mas_seq c
        where a.clm_no = b.clm_no and a.clm_no = c.clm_no and a.prod_grp = '0' 
        and c.corr_seq in (select max(cc.corr_seq) from mis_clm_mas_seq cc where cc.clm_no = c.clm_no 
--            and nvl(cc.close_date ,trunc(cc.corr_date))   <= i_asdate
            and trunc(cc.corr_date) = v_Date
        ) 
        and a.prod_type in (select prod_type from clm_grp_prod where sysid='GM') 
--        and nvl(c.close_date ,trunc(c.corr_date)) between i_datefr and  i_dateto
        and trunc(c.corr_date)= v_Date
        and (b.clm_no ,b.state_seq) in (select bb.clm_no ,max(bb.state_seq) from clm_medical_res bb where bb.clm_no =b.clm_no 
        and trunc(bb.corr_date) <= v_Date group by bb.clm_no)
--        and trunc(b.corr_date) <=  v_Date
        and a.clm_no like nvl(v_CLMNO,'%')
        and a.clm_no not in (select nc.clm_no from nc_mas nc where convert_flag is null and nc.clm_no = a.clm_no)
        and a.channel <> '9'    
        and pol_yr > 2011    
        order by a.clm_no        
    )LOOP
        cnt := cnt+1;   v_DummClm := M1.CLM_NO;
        dbms_output.put_line('clm: '||M1.CLM_NO||' sts: '||M1.CLM_STS||' Corr_Date: '||M1.CORR_DATE);
        if M1.IPD_FLAG = 'O' then v_ADMTYPE := 'PHADMTYPE01'; 
        elsif  M1.IPD_FLAG = 'I' then v_ADMTYPE := 'PHADMTYPE02'; 
        else v_ADMTYPE := 'PHADMTYPE99';  end if;
        
        if M1.receipt is not null then
            v_CLMTYPE := 'PHCLMTYPE01';
        elsif M1.invoice is not null then
            v_CLMTYPE := 'PHCLMTYPE02';
        elsif M1.walkin is not null then    --ost
            v_CLMTYPE := 'PHCLMTYPE03';
        elsif M1.fax_clm is not null then   --ชดเชยรายได้
            v_CLMTYPE := 'PHCLMTYPE06';
        elsif M1.deathclm is not null then
            v_CLMTYPE := 'PHCLMTYPE05';
        else
            null;
        end if;
        
        v_HPTCODE := p_ph_convert.CONV_HOSPITAL_NEW(M1.HPT_CODE);
        v_HPTSEQ := M1.HPT_SEQ;
        
        v_CLMSTS := P_PH_CONVERT.CONV_CLMSTS_O2N(M1.CLM_STS ,'1');
        v_CLAIMSTATUS := P_PH_CONVERT.CONV_CLMSTS_O2N(M1.CLM_STS ,'2');

        if M1.CWP_CODE is not null then
            v_CWPCODE := p_ph_convert.CONV_CWPCODE(M1.CWP_CODE);
        end if;
        
        V_SETTLE_DATE := null;
        if M1.CLM_STS = '2' then V_SETTLE_DATE := M1.CLOSE_DATE; end if;
        
        v_idno := nvl(m1.card_id_no ,m1.card_other_no);
        if v_idno is null then
            v_idno := nc_health_paid.GET_CARDNO(m1.pol_no  ,m1.pol_run ,m1.fleet_seq ,m1.recpt_seq
                        ,null ,null,null ,m1.clm_no ,null);
        end if;                        
        
        dbms_output.put_line('v_CLMSTS='||v_CLMSTS||' v_CLAIMSTATUS='||v_CLAIMSTATUS);
        if M1.STS_KEY is null then
            v_STSKEY := NC_HEALTH_PACKAGE.GEN_STSKEY(null);
            UPDATE MIS_CLM_MAS
            set STS_KEY = v_STSKEY
            WHERE CLM_NO = M1.CLM_NO;
        else
            v_STSKEY := M1.STS_KEY;
        end if;

        begin -- max v_max_ncres
            select  nvl(max(trn_seq),0)+1 into v_max_ncres
            from nc_reserved 
            where clm_no = M1.CLM_NO;
        exception
            when no_data_found then 
                v_max_ncres := 1;
            when others then
                v_max_ncres := 1;
        end;  -- max v_max_ncres    
        if v_max_ncres >1 then -- get First STS_DATE
            select sts_date into v_ncres_stsdate
            from nc_reserved a
            where clm_no = M1.CLM_NO and rownum=1;
        end if;

        begin -- max v_max_rires
            select  nvl(max(trn_seq),0)+1 into v_max_rires
            from nc_ri_reserved 
            where clm_no = M1.CLM_NO;
        exception
            when no_data_found then 
                v_max_rires := 1;
            when others then
                v_max_rires := 1;
        end;  -- max v_max_rires    
        if v_max_rires >1 then -- get First STS_DATE
            select ri_sts_date into v_rires_stsdate
            from nc_ri_reserved a
            where clm_no = M1.CLM_NO and rownum=1;
        end if;
        
        -- ============== Set Reserved  & Mas           
        IF NOT p_ph_convert.IS_EXIST_NC_MAS(M1.CLM_NO) THEN -- not found NC_MAS
            Insert into ALLCLM.NC_MAS
            (STS_KEY, CLM_NO ,REG_NO, POL_NO, POL_RUN, END_SEQ, RECPT_SEQ, CLM_YR, POL_YR, PROD_GRP, PROD_TYPE, FLEET_SEQ, ID_NO, IPD_FLAG, DIS_CODE, CAUSE_CODE, CAUSE_SEQ
            , REG_DATE, CLM_DATE, LOSS_DATE, FR_DATE, TO_DATE, TR_DATE_FR, TR_DATE_TO, TOT_TR_DAY, CLOSE_DATE, REOPEN_DATE, ALC_RE, LOSS_DETAIL, CLM_USER, INVOICE_NO, HPT_CODE, HPT_SEQ, HN_NO
            , MAS_CUS_CODE, MAS_CUS_SEQ, MAS_CUS_NAME, CUS_CODE, CUS_SEQ, CUS_NAME, FAX_CLM, FAX_CLM_DATE, MAS_SUM_INS, RECPT_SUM_INS, SUB_CAUSE_CODE
            , CLM_STS, REMARK, CWP_REMARK, CWP_CODE, CWP_USER, CARD_ID_TYPE, CARD_ID_NO, CARD_OTHER_TYPE, CARD_OTHER_NO, CARD_UPDATEDATE
            , COMPLETE_CODE, COMPLETE_USER, CLAIM_STATUS, ADMISSION_TYPE, CLM_TYPE, CONVERT_FLAG)   
            VALUES
            (v_STSKEY, M1.CLM_NO ,M1.REG_NO, M1.POL_NO, M1.POL_RUN, M1.END_SEQ, M1.RECPT_SEQ, M1.CLM_YR, M1.POL_YR, M1.PROD_GRP, M1.PROD_TYPE, M1.FLEET_SEQ, V_IDNO, M1.IPD_FLAG, M1.DIS_CODE, M1.CAUSE_CODE, M1.CAUSE_SEQ
            , M1.REG_DATE, M1.CLM_DATE, M1.LOSS_DATE, M1.FR_DATE, M1.TO_DATE, M1.TR_DATE_FR, M1.TR_DATE_TO, M1.TOT_TR_DAY, M1.CLOSE_DATE, M1.REOPEN_DATE, M1.ALC_RE, M1.LOSS_DETAIL, M1.CLM_USER, M1.INVOICE_NO, v_HPTCODE, v_HPTSEQ, M1.HN_NO
            , M1.MAS_CUS_CODE, M1.MAS_CUS_SEQ, M1.MAS_CUS_NAME, M1.CUS_CODE, M1.CUS_SEQ, M1.CUS_NAME, M1.FAX_CLM, M1.FAX_CLM_DATE, M1.MAS_SUM_INS, M1.RECPT_SUM_INS, M1.SUB_CAUSE_CODE
            , v_CLMSTS, M1.REMARK, M1.CWP_REMARK, v_CWPCODE, M1.CWP_USER, M1.CARD_ID_TYPE, M1.CARD_ID_NO, M1.CARD_OTHER_TYPE, M1.CARD_OTHER_NO, M1.CARD_UPDATEDATE
            , M1.COMPLETE_CODE, M1.COMPLETE_USER, v_CLAIMSTATUS, M1.ADMISSION_TYPE, v_CLMTYPE, 'Y');         
        ELSE
            dbms_output.put_line('Exist CLM_NO in NC_MAS STS_KEY='||v_STSKEY);
            nc_health_package.save_ncmas_history(v_STSKEY ,p1_rst);
            if p1_rst is not null then
                dbms_output.put_line('save_ncmas_history Error: '||p1_rst);
                NC_HEALTH_PAID.WRITE_LOG ('CONVERT_PH' , 'PROGRAM' ,'Schedule Run','save_ncmas_history' ,'save_ncmas_history Error: '||p1_rst ,'error' ,p2_rst) ;
            end if;
            UPDATE ALLCLM.NC_MAS
            SET LOSS_DATE = M1.LOSS_DATE,TR_DATE_FR = M1.TR_DATE_FR,TR_DATE_TO = M1.TR_DATE_TO,TOT_TR_DAY= M1.TOT_TR_DAY ,CLOSE_DATE = M1.CLOSE_DATE,REOPEN_DATE =  M1.REOPEN_DATE ,LOSS_DETAIL = M1.LOSS_DETAIL
            ,CLM_USER = M1.CLM_USER,HPT_CODE = v_HPTCODE,HPT_SEQ = v_HPTSEQ,IPD_FLAG = M1.IPD_FLAG ,DIS_CODE = M1.DIS_CODE,CAUSE_CODE = M1.CAUSE_CODE,CAUSE_SEQ = M1.CAUSE_SEQ
            ,MAS_CUS_CODE = M1.MAS_CUS_CODE,MAS_CUS_SEQ = M1.MAS_CUS_SEQ,MAS_CUS_NAME = M1.MAS_CUS_NAME,CUS_CODE = M1.CUS_CODE,CUS_SEQ = M1.CUS_SEQ,CUS_NAME = M1.CUS_NAME
            ,FAX_CLM_DATE = M1.FAX_CLM_DATE,MAS_SUM_INS = M1.MAS_SUM_INS,RECPT_SUM_INS = M1.RECPT_SUM_INS,REMARK= M1.REMARK, CWP_REMARK= M1.CWP_REMARK, CWP_CODE= v_CWPCODE, CWP_USER= M1.CWP_USER, CARD_ID_TYPE= M1.CARD_ID_TYPE, CARD_ID_NO= M1.CARD_ID_NO
            ,CARD_OTHER_TYPE = M1.CARD_OTHER_TYPE ,CARD_OTHER_NO= M1.CARD_OTHER_NO, CARD_UPDATEDATE= M1.CARD_UPDATEDATE
            ,ID_NO = V_IDNO ,CLM_DATE = M1.CLM_DATE ,REG_DATE =  M1.REG_DATE
            ,COMPLETE_CODE = M1.COMPLETE_CODE, COMPLETE_USER= M1.COMPLETE_USER,CLM_STS= v_CLMSTS, CLAIM_STATUS = v_CLAIMSTATUS, ADMISSION_TYPE = M1.ADMISSION_TYPE, CLM_TYPE=v_CLMTYPE, CONVERT_FLAG= 'Y'
            WHERE CLM_NO = M1.CLM_NO;
        END IF;
        
        v_seq := 0;
        FOR res in (
            select CLM_NO ,  BENE_CODE PREM_CODE ,'' PREM_SEQ , RES_AMT         
            from clm_medical_res a
            where clm_no = M1.CLM_NO 
            and state_seq in (select max(aa.state_seq) from clm_medical_res aa where aa.clm_no = a.clm_no)               
        )LOOP
            v_seq := v_seq+1;
            Insert into ALLCLM.NC_RESERVED
            (STS_KEY, CLM_NO, PROD_GRP, PROD_TYPE, TYPE, SUB_TYPE, TRN_SEQ, STS_DATE, AMD_DATE
            , PREM_CODE, PREM_SEQ, RES_AMT, CLM_USER, AMD_USER)
            VALUES
            (v_STSKEY, M1.CLM_NO, M1.PROD_GRP, M1.PROD_TYPE, 'NCNATTYPECLM101', 'NCNATSUBTYPECLM101', v_max_ncres, v_ncres_stsdate, v_Date
            , res.PREM_CODE, v_seq, res.RES_AMT, v_user, v_user);              
        END LOOP; --res
            
        FOR R1 in (
            select 0 STS_KEY, CLM_NO, '' PROD_GRP, '' PROD_TYPE, 'x' TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG RI_LF_FLAG, RI_SUB_TYPE, RI_SHR RI_SHARE, 1 TRN_SEQ
            , '' RI_STS_DATE, '' RI_AMD_DATE, RI_RES_AMT, RI_RES_AMT RI_TRN_AMT
            , LETT_TYPE, '' STATUS, LETT_PRT, 'x' SUB_TYPE, RI_RES_AMT ORG_RI_RES_AMT
            from mis_cri_res a
            where clm_no = M1.CLM_NO
            and corr_seq in (select max(aa.corr_seq) from mis_cri_res aa where aa.clm_no = a.clm_no --and ri_res_date = V_DATE
            )          
        )LOOP
            Insert into ALLCLM.NC_RI_RESERVED
            (STS_KEY, CLM_NO, PROD_GRP, PROD_TYPE, TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_SHARE, TRN_SEQ
            , RI_STS_DATE, RI_AMD_DATE, RI_RES_AMT, RI_TRN_AMT
            , LETT_TYPE, STATUS, LETT_PRT, SUB_TYPE, ORG_RI_RES_AMT)
            Values   
            (v_STSKEY, R1.CLM_NO, M1.PROD_GRP, M1.PROD_TYPE, 'NCNATTYPECLM101', R1.RI_CODE, R1.RI_BR_CODE, R1.RI_TYPE, R1.RI_LF_FLAG, R1.RI_SUB_TYPE, R1.RI_SHARE, v_max_rires
            , v_rires_stsdate, v_Date, R1.RI_RES_AMT, R1.RI_TRN_AMT
            , R1.LETT_TYPE, 'NCCLMSTS01', R1.LETT_PRT, 'NCNATSUBTYPECLM101', R1.ORG_RI_RES_AMT)   ;        
        END LOOP; --R1        
        COMMIT;
        
        IF M1.CLM_STS in ('6','2') THEN -- Draft and Paid
            begin 
                select pay_no   into v_PAYNO 
                from mis_clmgm_paid b
                where clm_no = M1.CLM_NO
                and (b.pay_no ,b.corr_seq) in (select bb.pay_no ,max(bb.corr_seq) from mis_clmgm_paid bb where bb.pay_no =b.pay_no 
--                and trunc(bb.corr_date) <= V_DATE
                group by bb.pay_no)
                and rownum=1;
            exception
                when no_data_found then
                    v_PAYNO := '';  v_PAID_CORRSEQ :=0;
                when others then
                    v_PAYNO := '';  v_PAID_CORRSEQ :=0;
            end;
                    
            begin -- max v_max_ncpay
                select  nvl(max(trn_seq),0)+1 into v_max_ncpay
                from nc_payment
                where pay_no =v_PAYNO and type<>'01' ;
            exception
                when no_data_found then 
                    v_max_ncpay := 1;
                when others then
                    v_max_ncpay := 1;
            end;  -- max v_max_ncpay    
            if v_max_ncpay >1 then -- get First STS_DATE
                select sts_date into v_ncpay_stsdate
                from nc_payment a
                where pay_no = v_PAYNO and type<>'01' and rownum=1;
            end if;
            
            begin -- max v_max_ripay
                select  nvl(max(trn_seq),0)+1 into v_max_ripay
                from nc_ri_paid
                where pay_no =v_PAYNO;
            exception
                when no_data_found then 
                    v_max_ripay := 1;
                when others then
                    v_max_ripay := 1;
            end;  -- max v_max_ripay    
            if v_max_ripay >1 then -- get First STS_DATE
                select ri_sts_date into v_ripay_stsdate
                from nc_ri_paid a
                where  pay_no = v_PAYNO and rownum=1;
            end if;     
            
            begin -- max v_max_payee
                select  nvl(max(trn_seq),0)+1 into v_max_payee
                from nc_payee
                where pay_no =v_PAYNO;
            exception
                when no_data_found then 
                    v_max_payee := 1;
                when others then
                    v_max_payee := 1;
            end;  -- max v_max_ncpay    
            if v_max_payee >1 then -- get First STS_DATE
                select sts_date into v_payee_stsdate
                from nc_payee a
                where pay_no = v_PAYNO and rownum=1;
            end if;                   
            
            dbms_output.put_line('payno: '||v_PAYNO);               
            if v_PAYNO is not null  then
                v_seq := 0;
                FOR p1 IN (        
                    select CLM_NO, PAY_NO, PAY_AMT, PAY_AMT TRN_AMT, 'PH' SUBSYSID, BENE_CODE PREM_CODE, '' PREM_SEQ
                    , IPD_DAY DAYS, null RECOV_AMT, '' DAY_ADD, REMARK
                    from clm_gm_paid a
                    where pay_no =v_PAYNO
                    and a.corr_seq in (select max(aa.corr_seq) from clm_gm_paid aa where aa.pay_no = a.pay_no )
                )
                LOOP  
                    v_seq := v_seq+1;  
                    Insert into ALLCLM.NC_PAYMENT
                    (STS_KEY, CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, STS_DATE, AMD_DATE, SETTLE_DATE, CLM_MEN, AMD_USER
                    , PROD_GRP, PROD_TYPE, SUBSYSID, TYPE, SUB_TYPE, PREM_CODE, PREM_SEQ
                    , STATUS, DAYS, RECOV_AMT, DAY_ADD, REMARK)
                    VALUES
                    (v_STSKEY, M1.CLM_NO, V_PAYNO, 1, v_max_ncpay, p1.PAY_AMT, p1.TRN_AMT, M1.CURR_CODE, M1.CURR_RATE, v_ncpay_stsdate, V_DATE, V_SETTLE_DATE, v_user, v_user
                    , M1.PROD_GRP, M1.PROD_TYPE, p1.SUBSYSID, 'NCNATTYPECLM101', 'NCNATSUBTYPECLM101', P1.PREM_CODE, v_seq
                    , 'NCPAYMENTSTS02', p1.DAYS, p1.RECOV_AMT, p1.DAY_ADD, p1.REMARK
                    );
                                                                                    
                END LOOP;  --p1_rst    
                
                FOR R1 in (
                    select clm_no, pay_no, payee_code, payee_name, payee_type, pay_seq payee_seq, payee_amt
                    , settle, acc_no, acc_name, bank_code, bank_br_code, br_name, send_title, send_addr1, send_addr2
                    , mobile_number sms, cust_mail email, agent_mobile_number agent_sms,agent_mail agent_email, special_flag, special_remark
                    , urgent_flag, invalid_payee, invalid_payee_remark
                    from clm_gm_payee a
                    where pay_no = v_PAYNO         
                )LOOP
                    Insert into ALLCLM.NC_PAYEE
                    (CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TRN_SEQ, STS_DATE, AMD_DATE, PAYEE_CODE, PAYEE_NAME, PAYEE_TYPE, PAYEE_SEQ, PAYEE_AMT
                    , SETTLE, ACC_NO, ACC_NAME, BANK_CODE, BANK_BR_CODE, BR_NAME, SEND_TITLE, SEND_ADDR1, SEND_ADDR2
                    , SMS, EMAIL, CURR_CODE, CURR_RATE, AGENT_SMS, AGENT_EMAIL, SPECIAL_FLAG, SPECIAL_REMARK
                    , URGENT_FLAG, INVALID_PAYEE, INVALID_PAYEE_REMARK
                    , CREATE_USER, AMD_USER, PAID_TO)
                    Values
                    (R1.CLM_NO, R1.PAY_NO, M1.PROD_GRP, M1.PROD_TYPE, v_max_payee, v_payee_stsdate, V_DATE, R1.PAYEE_CODE, R1.PAYEE_NAME, R1.PAYEE_TYPE, R1.PAYEE_SEQ, R1.PAYEE_AMT
                    , R1.SETTLE, R1.ACC_NO, R1.ACC_NAME, R1.BANK_CODE, R1.BANK_BR_CODE, R1.BR_NAME, R1.SEND_TITLE, R1.SEND_ADDR1, R1.SEND_ADDR2
                    , R1.SMS, R1.EMAIL, M1.CURR_CODE, M1.CURR_RATE, R1.AGENT_SMS, R1.AGENT_EMAIL, R1.SPECIAL_FLAG, R1.SPECIAL_REMARK
                    , R1.URGENT_FLAG, R1.INVALID_PAYEE, R1.INVALID_PAYEE_REMARK
                    , v_user, v_user, V_PAIDTO);
                END LOOP; --R1
                
                FOR NR in (
                    select 0 STS_KEY, PAY_NO, CLM_NO, '' PROD_GRP, '' PROD_TYPE, 'NCNATTYPECLM101' TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG RI_LF_FLAG, RI_SUB_TYPE
                    , (select RI_SHARE from nc_ri_reserved nr where nr.clm_no = a.clm_no and nr.trn_seq = (select max(nrr.trn_seq) from nc_ri_reserved nrr where nrr.clm_no = nr.clm_no) 
                    and nr.ri_code = a.ri_code and nr.ri_br_code = a.ri_br_code and nr.ri_type = a.ri_type and nr.ri_sub_type = a.ri_sub_type) RI_SHARE
                    , 1 TRN_SEQ, '' RI_STS_DATE, '' RI_AMD_DATE, pay_amt RI_PAY_AMT, pay_amt RI_TRN_AMT
                    , LETT_NO, LETT_TYPE, '' STATUS, LETT_PRT, 'NCNATSUBTYPECLM101' SUB_TYPE
                    from mis_cri_paid a
                    where pay_no = v_PAYNO
                    and corr_seq in (select max(aa.corr_seq) from mis_cri_paid aa where aa.pay_no = a.pay_no) 
                )LOOP
                    Insert into ALLCLM.NC_RI_PAID
                    (STS_KEY, CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_SHARE, TRN_SEQ
                    , LETT_NO, LETT_PRT, RI_STS_DATE, RI_AMD_DATE, RI_PAY_AMT, RI_TRN_AMT, LETT_TYPE, STATUS, SUB_TYPE)
                    Values
                    (v_STSKEY, NR.CLM_NO, NR.PAY_NO, M1.PROD_GRP, M1.PROD_TYPE, NR.TYPE, NR.RI_CODE, NR.RI_BR_CODE, NR.RI_TYPE, NR.RI_LF_FLAG, NR.RI_SUB_TYPE, NR.RI_SHARE, v_max_ripay
                    , NR.LETT_NO, NR.LETT_PRT, v_ripay_stsdate, V_DATE, NR.RI_PAY_AMT, NR.RI_TRN_AMT, NR.LETT_TYPE, NR.STATUS, NR.SUB_TYPE);                
                END LOOP; -- NR 

            end if; -- check V_PAYNO

            if M1.CLM_STS = '2' then
                begin -- max v_max_apprvseq
                    select  nvl(max(trn_seq),0)+1 into v_max_apprvseq
                    from nc_payment_apprv
                    where pay_no =v_PAYNO;
                exception
                    when no_data_found then 
                        v_max_apprvseq := 1;
                    when others then
                        v_max_apprvseq := 1;
                end;  -- max v_max_apprvseq  
                begin -- apprv_id
                    select approve_id into v_approve_id
                    from nc_payment a
                    where pay_no =v_PAYNO and type='01'
                    and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type='01' and aa.pay_no = a.pay_no);
                exception
                    when no_data_found then 
                        v_approve_id := null;
                    when others then
                        v_approve_id := null;
                end;  -- max apprv_id                  
                
                INSERT into nc_payment_apprv(clm_no ,pay_no ,clm_seq ,trn_seq ,Pay_sts ,pay_amt ,Trn_amt ,Curr_code ,Curr_rate
                ,Sts_date ,Amd_date ,Clm_men ,Amd_user, APPROVE_ID ,approve_date , Prod_grp ,Prod_type ,SUBSYSID ,Sts_key ,Sub_type ,Type ,apprv_flag ,remark)
                VALUES (M1.CLM_NO , v_payno ,1 ,v_max_apprvseq, 'PHSTSAPPRV03' ,M1.TOT_PAID ,M1.TOT_PAID,
                M1.CURR_CODE, M1.CURR_RATE ,v_date ,v_date ,v_user ,v_user ,v_approve_id ,M1.CLOSE_DATE
                ,M1.PROD_GRP ,M1.PROD_TYPE, 'PH' ,v_STSKEY ,'NCNATSUBTYPECLM101' ,'NCNATTYPECLM101' ,'Y' ,'Convert data') ;

                UPDATE NC_MAS
                SET APPROVE_STATUS =  'PHSTSAPPRV03'
                WHERE CLM_NO = M1.CLM_NO;                
            end if; -- if M1.CLM_STS = '2' then
                
        END IF;
       
        -- End ============== Set Reserved  & Mas   =============
        
        
    END LOOP; --M1
    
    COMMIT;
    return true;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    P_RST := 'error: '||'clmno='||v_DummClm||' '||sqlerrm;
    dbms_output.put_line(P_RST);
    NC_HEALTH_PAID.WRITE_LOG ('CONVERT_PH' , 'PROGRAM' ,'Schedule Run','Generate Data' ,P_RST ,'error' ,p1_rst) ;
    return false;   
END O2N_CONV_PH;

FUNCTION IS_EXIST_NC_MAS(v_CLMNO in VARCHAR2) RETURN BOOLEAN IS -- check nc_mas
    v_dummy_clm varchar2(20);
BEGIN
    select clm_no into v_dummy_clm
    from nc_mas 
    where clm_no = v_clmno;
    
    return true;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    return false; 
    WHEN OTHERS THEN
    return false;   
END IS_EXIST_NC_MAS;

FUNCTION  IS_FOUND_CPARES(v_CLMNO in VARCHAR2 ,v_Date in Date) RETURN BOOLEAN IS -- check cpa_res with date
    v_dummy_clm varchar2(20);
BEGIN
    select clm_no into v_dummy_clm
    from mis_cpa_res  a
    where clm_no = v_clmno
    and revise_seq in (select max(aa.revise_seq) from mis_cpa_res aa where aa.clm_no = a.clm_no and trunc(corr_date) = v_Date );
    
    return true;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    return false; 
    WHEN OTHERS THEN
    return false;   
END IS_FOUND_CPARES;

FUNCTION  IS_FOUND_CPARES(v_CLMNO in VARCHAR2) RETURN BOOLEAN IS -- check cpa_res
    v_dummy_clm varchar2(20);
BEGIN
    select clm_no into v_dummy_clm
    from mis_cpa_res  a
    where clm_no = v_clmno
    and revise_seq in (select max(aa.revise_seq) from mis_cpa_res aa where aa.clm_no = a.clm_no);
    
    return true;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    return false; 
    WHEN OTHERS THEN
    return false;   
END IS_FOUND_CPARES;

FUNCTION  IS_FOUND_NCRES(v_CLMNO in VARCHAR2) RETURN BOOLEAN IS -- check cpa_res
    v_dummy_clm varchar2(20);
BEGIN
    select clm_no into v_dummy_clm
    from nc_reserved  a
    where clm_no = v_clmno
    and rownum=1;
    
    return true;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    return false; 
    WHEN OTHERS THEN
    return false;   
END IS_FOUND_NCRES;

FUNCTION  IS_FOUND_CPAPAID(v_CLMNO in VARCHAR2 ,v_PAYNO in VARCHAR2) RETURN BOOLEAN IS -- check cpa_paid
    v_dummy_clm varchar2(20);
BEGIN
    select clm_no into v_dummy_clm
    from mis_cpa_paid  a
    where clm_no = v_clmno
    and pay_no = v_PAYNO
    and corr_seq in (select max(aa.corr_seq) from mis_cpa_paid aa where aa.pay_no = a.pay_no);
    
    return true;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    return false; 
    WHEN OTHERS THEN
    return false;   
END IS_FOUND_CPAPAID;

END P_PH_CONVERT;
/

