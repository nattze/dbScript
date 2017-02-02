CREATE OR REPLACE PACKAGE BODY P_PH_CONVERT AS
/******************************************************************************
 NAME: ALLCLM.P_PH_CONVERT
   PURPOSE:     สำหรับการ Convert to old table(BKIAPP) และ ส่วนการ post Data
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        1/2/2017      2702       1. Created this package.
******************************************************************************/

FUNCTION VALIDATE_INDV(vClmNo in varchar2 ,vPayNo in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
 CURSOR c_clm IS select clm_no ,prod_type, p_non_pa_approve.GET_CLMSTS(clm_no) clm_sts from nc_mas 
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

FUNCTION POST_ACCTMP(vClmNo in varchar2 ,vPayNo in varchar2 ,vClmUser in varchar2 ,P_RST OUT VARCHAR2) RETURN BOOLEAN IS 
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
            ,salvage_flag ,deduct_flag ,recovery_flag ,salvage_amt ,deduct_amt ,recovery_amt ,payee_type
            ,bank_code ,bank_br_code ,acc_no ,acc_name ,P_NON_PA_APPROVE.CONVERT_PAYMENT_METHOD(settle) settle ,curr_code
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

END P_PH_CONVERT;
/

