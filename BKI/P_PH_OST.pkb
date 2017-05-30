CREATE OR REPLACE PACKAGE BODY P_PH_OST AS
/******************************************************************************
   NAME:       P_PH_OST
   PURPOSE:     For Manage Ost Claim Data
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/4/2017      2702       1. Created this package.
******************************************************************************/

    FUNCTION CAN_OPEN_CLAIM(v_notno  IN VARCHAR2 ,o_RST OUT VARCHAR2) RETURN BOOLEAN IS
        dumm_clm    varchar2(20);
    BEGIN
        select clm_no into dumm_clm
        from nc_mas
        where out_clm_no = v_notno 
        and claim_status not in ('PHCLMSTS30' ,'PHCLMSTS31' );
        
        if dumm_clm is not null then
            o_RST := 'Not_No นี้เปิดเคลม ได้เลข :'||dumm_clm||' แล้ว';
            return false;
        end if;

        select clm_no into dumm_clm
        from mis_clm_mas
        where out_clm_no = v_notno
        and clm_sts not in ('3');
        
        if dumm_clm is not null then 
            o_RST := 'Not_No นี้เปิดเคลม ได้เลข :'||dumm_clm||' แล้ว บน bkiapp'; 
            return false; 
        end if;        
        
    EXCEPTION
        WHEN no_data_found THEN
            return true;   
        WHEN Others THEN       
            return true;    
    END CAN_OPEN_CLAIM;
        
    PROCEDURE GET_OSTCLM(v_date IN DATE ,v_notno IN VARCHAR2 ,v_user IN VARCHAR2 ,o_RST OUT VARCHAR2) IS
        v_rst   varchar2(250);
    BEGIN
        FOR x in (
            select distinct not_no
            from clm_outservice_log a
            where trunc(trn_date) = v_date
            and not_no like nvl(  v_notno ,'%' ) 
        )LOOP
            dbms_output.put_line('not_no:'||x.not_no);
            if not p_ph_ost.CAN_OPEN_CLAIM(x.not_no ,v_rst) then dbms_output.put_line(v_rst); 
                p_ph_ost.REVISE_CLM(v_date ,x.not_no ,v_user ,v_rst);
            else
                p_ph_ost.OPEN_CLM(v_date ,x.not_no ,v_user ,v_rst);
                p_ph_ost.REVISE_CLM(v_date ,x.not_no ,v_user ,v_rst);
            end if;
            
        END LOOP; -- X
    EXCEPTION
        WHEN OTHERS THEN
            o_Rst := 'error: '||sqlerrm;
    END GET_OSTCLM;
    
    PROCEDURE OPEN_CLM(v_date IN DATE ,v_notno IN VARCHAR2 ,v_user IN VARCHAR2 ,o_RST OUT VARCHAR2) IS
        v_POLNO varchar2(20);
        v_POLRUN    number;
        v_CLMNO varchar2(20);
        v_STSKEY    number;
        v_SYSDATE   date:=trunc(sysdate);
        v_SYSDATE_T   date:=sysdate;
        v_Remark    varchar2(500);
        v_Detail    varchar2(500);
        v_ADMIT varchar2(20);
        v_DocDate   Date;
        v_RegDate   Date;
        v_ClmDate      Date;
        v_Type  varchar2(20):='NCNATTYPECLM101';
        v_SubType  varchar2(20):='NCNATSUBTYPECLM101';
        cnt_det number:=0;
        v_GenRI varchar2(200);
        v_SaveStatus    varchar2(200);
        
        v_max_resseq    number(5):=0;
    BEGIN
        FOR mas IN (
            select not_no ,revision ,batch_no ,bki_clm_no ,pol_no ,fleet_seq ,reg_date ,not_date ,doc_date ,ret_date
            ,cus_code ,cus_name , sub_seq ,fam_seq ,id_no ,title ,name ,surname ,eff_date ,exp_date ,plan ,clm_type ,type_clm 
            ,acc_date ,admit ,disc ,hosp_amt ,disc_amt ,benf_covr ,non_cover ,benf_paid 
            ,p_ph_convert.CONV_HOSPITAL_NEW(hosp_code) hosp_code ,hosp_name ,ill_name ,icd_10 ,icd10_2 ,icd10_3 ,clm_pstat ,indication,treatment ,remark ,clm_decline ,fax_clm
            ,pay_mode ,payee_name ,payee_addr1 ,payee_addr2 ,bank_code ,bank_br_code ,bank_acc_no 
            ,claim_status
            from clm_outservice_mas a
            where a.not_no = v_notno
            and revision in (select max(aa.revision) from clm_outservice_mas aa where aa.not_no = a.not_no and trunc(created_date) = v_date )      
            and rownum=1  
        )LOOP
            p_acc_package.read_pol(mas.pol_no ,v_POLNO ,v_POLRUN);
            dbms_output.put_line('not_no:'||mas.not_no||' pol_no:'||v_POLNO||' pol_run:'||v_POLRUN||' fleet:'||mas.fleet_seq||' inure:'||mas.title||' '||mas.name||' '||mas.surname||' reg_date:'||mas.reg_date
            ||' not_date:'||mas.not_date||' ret_date:'||mas.ret_date||' clm_sts:'||mas.claim_status);
            FOR pol IN(
                SELECT fleet_seq ,id_no ,title ,name ,dob ,age ,sex ,plan, decode(a.cancel, null, a.fr_date, null) fr_date, decode(a.cancel, null, a.to_date, null) to_date, decode(a.cancel, 'C', a.fr_date, null) cancel_fr_date, decode(a.cancel, 'C', a.to_date, null) cancel_to_date
                , b.pol_no, b.pol_run, a.recpt_seq, b.end_seq, b.pol_yr
                , b.cus_code, b.cus_seq, title ||' '||name cus_enq ,sub_seq ,fam_sts ,fam_seq ,patronize , b.alc_re ,prod_grp ,prod_type  
                ,b.cus_code mas_cus_code ,b.cus_seq mas_cus_seq ,b.cus_enq mas_cus_name ,channel ,agent_code ,agent_seq 
                FROM pa_medical_det a , mis_mas b 
                WHERE a.pol_no = b.pol_no and a.pol_run = b.pol_run and a.end_seq = b.end_seq 
                and a.pol_no = v_POLNO and a.pol_run =v_POLRUN and fleet_seq = mas.fleet_seq  
                 and plan = mas.plan
                and mas.acc_date between a.fr_date and a.to_date  
                and rownum =1           
            )LOOP
                v_CLMNO := NC_HEALTH_PACKAGE.GEN_CLMNO(pol.prod_type ,'0');
                v_STSKEY := NC_HEALTH_PACKAGE.GEN_STSKEY('');
                
                dbms_output.put_line('CLMNO: '||v_CLMNO||' STSKEY: '||v_STSKEY);
                
                v_Remark := mas.Remark ;
                
                --  mas.INDICATION||' :'||mas.TREATMENT
                if mas.INDICATION is null and mas.TREATMENT is null then 
                    v_Detail := null;
                else 
                    if mas.INDICATION is null and mas.TREATMENT is not null then
                        v_Detail := mas.TREATMENT;
                    elsif  mas.INDICATION is not null and mas.TREATMENT is  null then
                        v_Detail := mas.INDICATION;
                    else
                        v_Detail := mas.INDICATION||' :'||mas.TREATMENT;
                    end if;
                end if;
                
                if mas.DOC_DATE is null then    v_DocDate := mas.ret_date ;
                else    v_DocDate := mas.DOC_DATE;  end if;
                v_RegDate := mas.ret_date ;
                v_ClmDate := v_SYSDATE;
                
                if mas.CLM_TYPE = 'IPD' then v_ADMIT := 'PHADMTYPE02'; 
                elsif  mas.CLM_TYPE = 'OPD' then v_ADMIT := 'PHADMTYPE01'; 
                else  v_ADMIT := 'PHADMTYPE99';    end if;
                
                Insert into ALLCLM.NC_MAS
                   (STS_KEY, CLM_NO, POL_NO, POL_RUN, END_SEQ, RECPT_SEQ, CLM_YR, POL_YR, PROD_GRP, PROD_TYPE, FLEET_SEQ, SUB_SEQ, FAM_STS, FAM_SEQ, PATRONIZE, ID_NO, PLAN, DIS_CODE
                   , REG_DATE, CLM_DATE, LOSS_DATE, FR_DATE, TO_DATE, TR_DATE_FR, TR_DATE_TO, ADD_TR_DAY, TOT_TR_DAY, REOPEN_DATE, ALC_RE, LOSS_DETAIL, CLM_USER, HPT_CODE, MAS_CUS_CODE, MAS_CUS_SEQ
                   , MAS_CUS_NAME, CUS_CODE, CUS_SEQ, CUS_NAME, FAX_CLM_DATE, CLM_STS, REMARK, CHANNEL, CLAIM_NUMBER, CLAIM_RUN
                   , COMPLETE_CODE, COMPLETE_USER, ICD10_2, ICD10_3, ICD10_4, ADMISSION_TYPE, CLM_TYPE, CLAIM_STATUS, APPROVE_STATUS, AMD_USER
                   , CWP_USER, OTHER_HPT, OUT_CLM_NO, OUT_OPEN_STS, OUT_PAID_STS, OUT_APPROVE_STS)
                VALUES
                   ( v_STSKEY, v_CLMNO, pol.POL_NO, pol.POL_RUN, pol.END_SEQ, pol.RECPT_SEQ, to_char(sysdate,'YYYY'), pol.POL_YR, pol.PROD_GRP, pol.PROD_TYPE, pol.FLEET_SEQ, pol.SUB_SEQ, pol.FAM_STS,pol.FAM_SEQ, pol.PATRONIZE, pol.ID_NO, pol.PLAN, mas.ICD_10
                   , v_RegDate, v_ClmDate, mas.ACC_DATE, pol.FR_DATE, pol.TO_DATE, mas.ADMIT, mas.DISC, null, mas.DISC - mas.ADMIT+1, null, pol.ALC_RE, v_Detail,v_User, mas.HOSP_CODE, pol.MAS_CUS_CODE, pol.MAS_CUS_SEQ
                   , pol.MAS_CUS_NAME, pol.mas_cus_code, pol.mas_cus_seq, pol.TITLE||' '||pol.NAME, v_DocDate, 'NCCLMSTS01', v_Remark, pol.CHANNEL, null, null
                   , null, null, mas.ICD10_2, mas.ICD10_3, null, v_ADMIT, 'PHCLMTYPE03', 'PHCLMSTS01', null, v_user
                   , null, null, mas.NOT_NO, 'Y', null, null
                    );        
                
                Update clm_outservice_mas
                set BKI_CLM_NO = v_CLMNO 
                Where not_no = mas.NOT_NO and revision = mas.REVISION;

                begin -- max v_max_resseq
                    select nvl(max(TRN_SEQ)+1,0) into v_max_resseq
                    from NC_RESERVED 
                    where clm_no = v_clmno;
                exception
                    when no_data_found then 
                        v_max_resseq := 0;
                    when others then
                        v_max_resseq := 0;
                end;  -- max v_max_resseq    
                    
                cnt_det := 0;
                FOR det in (
                    select not_no ,revision,bencode ,days ,charge ,discount ,benefit ,paid ,noncover ,clientpaid
                    from clm_outservice_det a
                    where not_no = mas.NOT_NO
                    and revision =  mas.REVISION            
                )LOOP
                    cnt_det := cnt_det+1;
                    dbms_output.put_line(cnt_det||' benecode: '||det.BENCODE||' days:'||det.DAYS||' charge:'||det.CHARGE||' paid:'||det.CHARGE||' noncover:'||det.NONCOVER||' clientpaid:'||det.CLIENTPAID);

                    Insert into ALLCLM.NC_RESERVED
                       (STS_KEY, CLM_NO, PROD_GRP, PROD_TYPE, TYPE, SUB_TYPE, TRN_SEQ, STS_DATE, AMD_DATE, PREM_CODE, PREM_SEQ, RES_AMT, CLM_USER, AMD_USER)
                     Values
                       (v_STSKEY, v_CLMNO, pol.PROD_GRP, pol.PROD_TYPE, v_Type, 
                        v_SubType, v_max_resseq, v_SYSDATE_T, v_SYSDATE_T, det.BENCODE, 
                        cnt_det, det.CHARGE, v_user, v_user);
                        
                END LOOP; -- det
                
                if cnt_det > 0 then                    
                    v_GenRI := p_ph_ost.genRI_RES(v_stskey ,v_clmno ,mas.HOSP_AMT);
                    if v_GenRI is not null then dbms_output.put_line('v_GenRI: '||v_GenRI); end if;
                end if;
                
                COMMIT;        
                
                if cnt_det >0 then
                    v_SaveStatus := p_ph_clm.SAVE_CLAIM_STATUS('benefit' ,v_clmno ,null) ;
                else
                    v_SaveStatus := p_ph_clm.SAVE_CLAIM_STATUS('claim_info_res' ,v_clmno ,null) ;
                end if;
            END LOOP; --pol
            
        END LOOP; --mas
    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            o_Rst := 'error OPEN_CLM: '||sqlerrm;    
    END OPEN_CLM;
    


    PROCEDURE REVISE_CLM(v_date IN DATE ,v_notno IN VARCHAR2 ,v_user IN VARCHAR2 ,o_RST OUT VARCHAR2) IS
        v_POLNO varchar2(20);
        v_POLRUN    number;
        v_CLMNO varchar2(20);
        v_STSKEY    number;
        v_SYSDATE   date:=trunc(sysdate);
        v_SYSDATE_T   date:=sysdate;
        v_Remark    varchar2(500);
        v_Detail    varchar2(500);
        v_ADMIT varchar2(20);
        v_DocDate   Date;
        v_RegDate   Date;
        v_ClmDate      Date;
        v_Type  varchar2(20):='NCNATTYPECLM101';
        v_SubType  varchar2(20):='NCNATSUBTYPECLM101';
        v_ClmSts    varchar2(20);
        v_ClaimSts    varchar2(20);
        cnt_det number:=0;  cnt_det2 number:=0;
        v_GenRI varchar2(200);
        v_SaveStatus    varchar2(200);
        v_rst    varchar2(200);
        
        v_det_sum_res   NUMBER:=0;
        v_det_sum_paid  NUMBER:=0;
        v_max_resseq    number(5):=0;
        v_max_paidseq    number(5):=0;
        v_max_payeeseq    number(5):=0;
        v_ri_maxseq    number(5):=0;
        
        v_PAYNO varchar2(20);    
        v_ProdType  varchar2(5);    
        v_stsdate   date:=sysdate;

        o_payee_code VARCHAR2(20);
        o_payee_seq VARCHAR2(2); 
        o_payee_type  VARCHAR2(2); 
        o_payee_name VARCHAR2(250);
        o_hosp_id    VARCHAR2(20);
        o_contact_name VARCHAR2(250);
        o_addr1 VARCHAR2(250);
        o_addr2 VARCHAR2(250);
        o_mobile VARCHAR2(20);
        o_email VARCHAR2(250);
        o_agent_mobile  VARCHAR2(250);
        o_agent_email VARCHAR2(250);
        o_paidto VARCHAR2(2);
        o_acc_no VARCHAR2(20);
        o_acc_name_th VARCHAR2(150); 
        o_acc_name_en VARCHAR2(150); 
        o_bank_code VARCHAR2(5); 
        o_bank_br_code VARCHAR2(5); 
        o_deposit VARCHAR2(5); 

        c1   p_ph_clm.v_curr;  

        TYPE t_data1 IS RECORD
        (
            clm_no VARCHAR2(20) ,pay_no VARCHAR2(20) ,ri_code VARCHAR2(5) ,ri_br_code VARCHAR2(5)  ,ri_type VARCHAR2(5)
                                , ri_pay_amt NUMBER ,ri_trn_amt NUMBER  ,lett_no VARCHAR2(20)
                                ,lett_prt VARCHAR2(2),lett_type VARCHAR2(5),status VARCHAR2(20),ri_lf_flag VARCHAR2(2)
                                ,ri_sub_type VARCHAR2(20) ,sub_type VARCHAR2(20) ,type VARCHAR2(20)
                                ,ri_share NUMBER ,prod_grp VARCHAR2(1) ,prod_type VARCHAR2(5) ,ri_display VARCHAR2(250) , ri_name VARCHAR2(250)
        ); 
        j_rec1 t_data1;   
                     
    BEGIN
        FOR mas IN (
            select not_no ,revision ,batch_no ,bki_clm_no ,pol_no ,fleet_seq ,reg_date ,not_date ,doc_date ,ret_date
            ,cus_code ,cus_name , sub_seq ,fam_seq ,id_no ,title ,name ,surname ,eff_date ,exp_date ,plan ,clm_type ,type_clm 
            ,acc_date ,admit ,disc ,hosp_amt ,disc_amt ,benf_covr ,non_cover ,benf_paid 
            ,hosp_code ori_hosp_code ,p_ph_convert.CONV_HOSPITAL_NEW(hosp_code) hosp_code ,hosp_name ,ill_name ,icd_10 ,icd10_2 ,icd10_3 ,clm_pstat ,indication,treatment ,remark ,clm_decline ,fax_clm
            ,pay_mode ,payee_name ,payee_addr1 ,payee_addr2 ,bank_code ,bank_br_code ,bank_acc_no 
            ,claim_status
            from clm_outservice_mas a
            where a.not_no = v_notno
            and revision in (select max(aa.revision) from clm_outservice_mas aa where aa.not_no = a.not_no and trunc(created_date) = v_date )      
            and rownum=1  
        )LOOP
            p_acc_package.read_pol(mas.pol_no ,v_POLNO ,v_POLRUN);
            dbms_output.put_line('not_no:'||mas.not_no||' pol_no:'||v_POLNO||' pol_run:'||v_POLRUN||' fleet:'||mas.fleet_seq||' inure:'||mas.title||' '||mas.name||' '||mas.surname||' reg_date:'||mas.reg_date
            ||' not_date:'||mas.not_date||' ret_date:'||mas.ret_date||' clm_sts:'||mas.claim_status);
            FOR pol IN(
                SELECT fleet_seq ,id_no ,title ,name ,dob ,age ,sex ,plan, decode(a.cancel, null, a.fr_date, null) fr_date, decode(a.cancel, null, a.to_date, null) to_date, decode(a.cancel, 'C', a.fr_date, null) cancel_fr_date, decode(a.cancel, 'C', a.to_date, null) cancel_to_date
                , b.pol_no, b.pol_run, a.recpt_seq, b.end_seq, b.pol_yr
                , b.cus_code, b.cus_seq, title ||' '||name cus_enq ,sub_seq ,fam_sts ,fam_seq ,patronize , b.alc_re ,prod_grp ,prod_type  
                ,b.cus_code mas_cus_code ,b.cus_seq mas_cus_seq ,b.cus_enq mas_cus_name ,channel ,agent_code ,agent_seq 
                FROM pa_medical_det a , mis_mas b 
                WHERE a.pol_no = b.pol_no and a.pol_run = b.pol_run and a.end_seq = b.end_seq 
                and a.pol_no = v_POLNO and a.pol_run =v_POLRUN and fleet_seq = mas.fleet_seq  
                 and plan = mas.plan
                and mas.acc_date between a.fr_date and a.to_date  
                and rownum =1           
            )LOOP
                begin
                    select clm_no ,sts_key ,prod_type into v_CLMNO ,v_STSKEY ,v_ProdType
                    from nc_mas
                    where out_clm_no = mas.not_no ;
                exception
                    when no_data_found then
                        v_CLMNO := null; v_STSKEY :=0; v_ProdType := null;
                    when others then
                        v_CLMNO := null; v_STSKEY :=0; v_ProdType := null;
                end;
                
                dbms_output.put_line('CLMNO: '||v_CLMNO||' STSKEY: '||v_STSKEY);
                if v_STSKEY = 0 then o_Rst := 'not found Exist Clm'; return;    end if;
                
                v_Remark := mas.Remark ;
                
                --  mas.INDICATION||' :'||mas.TREATMENT
                if mas.INDICATION is null and mas.TREATMENT is null then 
                    v_Detail := null;
                else 
                    if mas.INDICATION is null and mas.TREATMENT is not null then
                        v_Detail := mas.TREATMENT;
                    elsif  mas.INDICATION is not null and mas.TREATMENT is  null then
                        v_Detail := mas.INDICATION;
                    else
                        v_Detail := mas.INDICATION||' :'||mas.TREATMENT;
                    end if;
                end if;
                
                if mas.DOC_DATE is null then    v_DocDate := mas.ret_date ;
                else    v_DocDate := mas.DOC_DATE;  end if;
                v_RegDate := mas.ret_date ;
                v_ClmDate := v_SYSDATE;
                
                if mas.CLM_TYPE = 'IPD' then v_ADMIT := 'PHADMTYPE02'; 
                elsif  mas.CLM_TYPE = 'OPD' then v_ADMIT := 'PHADMTYPE01'; 
                else  v_ADMIT := 'PHADMTYPE99';    end if;
                                
                cnt_det := 0;
                
                begin -- max v_max_resseq
                    select nvl(max(TRN_SEQ)+1,1) into v_max_resseq
                    from NC_RESERVED 
                    where clm_no = v_clmno;
                exception
                    when no_data_found then 
                        v_max_resseq := 1;
                    when others then
                        v_max_resseq := 1;
                end;  -- max v_max_resseq    
                                
                FOR det in (
                    select not_no ,revision,bencode ,days ,charge ,discount ,benefit ,paid ,noncover ,clientpaid
                    from clm_outservice_det a
                    where not_no = mas.NOT_NO
                    and revision =  mas.REVISION            
                )LOOP
                    cnt_det := cnt_det+1;
                    dbms_output.put_line(cnt_det||' benecode: '||det.BENCODE||' days:'||det.DAYS||' charge:'||det.CHARGE||' paid:'||det.PAID||' noncover:'||det.NONCOVER||' clientpaid:'||det.CLIENTPAID);

                    Insert into ALLCLM.NC_RESERVED
                       (STS_KEY, CLM_NO, PROD_GRP, PROD_TYPE, TYPE, SUB_TYPE
                       , TRN_SEQ, STS_DATE, AMD_DATE, PREM_CODE, PREM_SEQ, RES_AMT, CLM_USER, AMD_USER)
                     Values
                       (v_STSKEY, v_CLMNO, pol.PROD_GRP, pol.PROD_TYPE, v_Type, v_SubType
                       , v_max_resseq, v_SYSDATE_T, v_SYSDATE_T, det.BENCODE,  cnt_det, det.CHARGE, v_user, v_user);
                        
                END LOOP; -- det
                
                if cnt_det > 0 then    -- for gen. reserve ,paid data           
                    v_GenRI := p_ph_ost.genRI_RES(v_stskey ,v_clmno ,mas.HOSP_AMT);
                    if v_GenRI is not null then dbms_output.put_line('v_GenRI: '||v_GenRI); end if;
                    
                    begin
                        select sum(nvl(charge,0)) ,sum(nvl(paid,0)) into v_det_sum_res ,v_det_sum_paid
                        from clm_outservice_det a
                        where not_no = mas.NOT_NO
                        and revision =  mas.REVISION  ;
                    exception
                        when no_data_found then
                            v_det_sum_res := 0; v_det_sum_paid := 0;
                        when others then
                            v_det_sum_res := 0; v_det_sum_paid := 0;
                    end;
                    
                    if p_ph_clm.IS_NEW_PAYMENT(v_CLMNO ,'' ,v_rst) = 'Y' then
                        v_PAYNO := NC_HEALTH_PACKAGE.GEN_PAYNO(v_ProdType);
                    else
                        begin -- max pay_no
                            select max(pay_no) into v_PAYNO
                            from NC_PAYMENT
                            where clm_no = v_clmno and prod_grp ='0' and type <>'01';
                        exception
                            when no_data_found then 
                                v_PAYNO := null;
                            when others then
                                v_PAYNO := null;
                        end;  -- max pay_no                        
                    end if; -- iGET Pay_NO
                    dbms_output.put_line('Loop Paid Pay_NO = '||v_payno);          
                    begin -- max v_max_paidseq
                        select nvl(max(TRN_SEQ)+1,1) into v_max_paidseq
                        from NC_PAYMENT
                        where clm_no = v_clmno and pay_no =v_PAYNO and prod_grp ='0' and type <>'01';
                    exception
                        when no_data_found then 
                            v_max_paidseq := 1;
                        when others then
                            v_max_paidseq := 1;
                    end;  -- max v_max_paidseq          
                      
                    if v_max_paidseq >1 then
                        BEGIN
                            select sts_date into v_stsdate
                            from NC_PAYMENT a
                            where pay_no = v_payno
                            and trn_seq in (select max(aa.trn_seq) from NC_PAYMENT aa where aa.pay_no = a.pay_no and type <>'01')
                            and type <>'01';
                        exception
                            when no_data_found then
                                v_stsdate := sysdate;
                            when others then
                                v_stsdate := sysdate;
                        END;        
                    end if;
                            
                    cnt_det2 := 0;
                    FOR det in (
                        select not_no ,revision,bencode ,days ,charge ,discount ,benefit ,paid ,noncover ,clientpaid
                        from clm_outservice_det a
                        where not_no = mas.NOT_NO
                        and revision =  mas.REVISION            
                    )LOOP
                        cnt_det2 := cnt_det2+1;
                        dbms_output.put_line(cnt_det||' benecode: '||det.BENCODE||' days:'||det.DAYS||' charge:'||det.CHARGE||' paid:'||det.PAID||' noncover:'||det.NONCOVER||' clientpaid:'||det.CLIENTPAID);
                        Insert into ALLCLM.NC_PAYMENT
                           (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_AMT, RECOV_AMT, CURR_CODE, CURR_RATE
                           , STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, PROD_GRP, PROD_TYPE, SUBSYSID, STS_KEY, TYPE, SUB_TYPE
                           , PREM_CODE, PREM_SEQ, STATUS, DAYS, DAY_ADD ,REMARK)
                         Values
                           (v_CLMNO ,v_PAYNO ,1 ,v_max_paidseq ,det.PAID ,det.CLIENTPAID ,'BHT' ,1
                           ,v_stsdate ,v_sysdate ,v_user ,v_user ,pol.PROD_GRP, pol.PROD_TYPE, 'PH' , v_STSKEY,v_Type, v_SubType
                           ,det.bencode ,cnt_det2 ,'NCPAYMENTSTS02' ,det.days ,null ,null);
                            
                    END LOOP; -- det
                    dbms_output.put_line('==After NC_PAYMENT==');          
                    
                    
                    if p_ph_clm.getRI_PAID(v_clmno ,v_payno, v_det_sum_paid ,C1) = '1' then

                        begin
                            select nvl(max(TRN_SEQ)+1,1) into v_ri_maxseq
                            from nc_ri_paid a
                            where prod_grp = '0'
                            and clm_no = v_clmno and pay_no = v_payno
                            ;
                        exception
                         when no_data_found then
                             v_ri_maxseq := 1;
                        when others then
                            v_ri_maxseq := 1;
                        end;
                        if v_ri_maxseq >1 then
                            BEGIN
                                select sts_date into v_stsdate
                                from nc_ri_paid a
                                where pay_no = v_payno
                                and trn_seq in (select max(aa.trn_seq) from nc_ri_paid aa where aa.pay_no = a.pay_no )
                                and rownum=1 ;
                            exception
                                when no_data_found then
                                    v_stsdate := sysdate;
                                when others then
                                    v_stsdate := sysdate;
                            END;        
                        end if;
                                                
                        LOOP    -- Gen NC_RI_PAID
                           FETCH  c1 INTO j_rec1;
                            EXIT WHEN c1%NOTFOUND;
                                dbms_output.put_line('disp RI==>'||  j_rec1.RI_DISPLAY||  ' ri_pay:'|| j_rec1.ri_pay_amt );  
                                Insert into NC_RI_PAID
                                   (STS_KEY, CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_SHARE
                                   , TRN_SEQ, RI_STS_DATE, RI_AMD_DATE, RI_PAY_AMT, RI_TRN_AMT, LETT_TYPE, SUB_TYPE
                                   ,STATUS ,LETT_NO ,LETT_PRT)
                                 Values
                                   (v_STSKEY, v_CLMNO, v_PAYNO, ,pol.PROD_GRP, pol.PROD_TYPE , j_rec1.TYPE, j_rec1.RI_CODE, j_rec1.RI_BR_CODE, j_rec1.RI_TYPE, j_rec1.RI_LF_FLAG, j_rec1.RI_SUB_TYPE, j_rec1.RI_SHARE
                                   , v_ri_maxseq, v_stsdate, v_SYSDATE , j_rec1.ri_pay_amt , j_rec1.ri_trn_amt , j_rec1.LETT_TYPE, j_rec1.SUB_TYPE
                                   ,j_rec1.status ,j_rec1.LETT_NO ,j_rec1.LETT_PRT); 
                                                                  
                        END LOOP;      -- End    Gen NC_RI_PAID
                    end if;        
                    dbms_output.put_line('==After NC_RI_PAID==v_rst: '||v_rst);    
                    p_ph_ost.GET_OSTPAYEE_DETAIL(v_clmno ,mas.payee_name ,mas.clm_pstat ,mas.ori_hosp_code
                     , o_payee_code ,o_payee_seq ,o_payee_type , o_payee_name ,o_hosp_id 
                     , o_contact_name  , o_addr1   , o_addr2   , o_mobile   , o_email 
                     ,o_agent_mobile   ,o_agent_email   ,o_paidto 
                     ,o_acc_no  , o_acc_name_th ,  o_acc_name_en  , o_bank_code  , o_bank_br_code  , o_deposit ) ;       
                     
                     dbms_output.put_line('==Get Payee == code:'||o_payee_code);    
                     if    o_payee_code is not null then -- insert NC_PAYEE
                        begin -- max v_max_payeeseq
                            select nvl(max(TRN_SEQ)+1,1) into v_max_payeeseq
                            from NC_PAYEE
                            where clm_no = v_clmno and pay_no =v_PAYNO and prod_grp ='0' ;
                        exception
                            when no_data_found then 
                                v_max_payeeseq := 1;
                            when others then
                                v_max_payeeseq := 1;
                        end;  -- max v_max_payeeseq      
                        if v_max_payeeseq >1 then
                            BEGIN
                                select sts_date into v_stsdate
                                from NC_PAYEE a
                                where pay_no = v_payno
                                and trn_seq in (select max(aa.trn_seq) from NC_PAYEE aa where aa.pay_no = a.pay_no );
                            exception
                                when no_data_found then
                                    v_stsdate := sysdate;
                                when others then
                                    v_stsdate := sysdate;
                            END;        
                        end if;
                                                                   
                        Insert into ALLCLM.NC_PAYEE
                           (CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TRN_SEQ, STS_DATE, AMD_DATE
                           , PAYEE_CODE, PAYEE_NAME, PAYEE_TYPE, PAYEE_SEQ, PAYEE_AMT, SETTLE, ACC_NO, ACC_NAME, BANK_CODE, BANK_BR_CODE, BR_NAME, SEND_TITLE, SEND_ADDR1, SEND_ADDR2
                           , SMS, EMAIL, CURR_CODE, CURR_RATE, AGENT_SMS, AGENT_EMAIL, SPECIAL_FLAG, SPECIAL_REMARK, URGENT_FLAG, CREATE_USER, AMD_USER, INVALID_PAYEE, INVALID_PAYEE_REMARK, PAID_TO)
                         Values
                           (v_clmno, v_payno, pol.PROD_GRP, pol.PROD_TYPE, v_max_payeeseq, v_stsdate, v_SYSDATE 
                           , o_payee_code, o_payee_name, o_payee_type, 
                            1, mas.benf_paid, o_deposit, o_acc_no, o_acc_name_th, o_bank_code, o_bank_br_code, null, o_contact_name, o_addr1, o_addr1
                            , o_mobile, o_email, 'BHT', 1, o_agent_mobile, o_agent_email
                            , null, null, null, v_user, v_user, null, null, o_paidto);                     
                     end if; -- insert NC_PAYEE
                     
                end if; -- for gen. reserve ,paid data        

--                if mas.Claim_status is not null then -- Ost ระบุ สถานะเข้ามาให้
--                    /*
--                    เปิดเคลม    10
--                    แก้ไขเปิดเคลม    20
--                    ทำจ่าย/ปิดเคลม    30
--                    ยกเลิกเคลม    40
--
--                    */                    
--                    if mas.Claim_status = '10' then
--                        if cnt_det > 0 then
--                            v_ClaimSts := 'PHCLMSTS02'; 
--                        else
--                            v_ClaimSts := 'PHCLMSTS01'; 
--                        end if;                       
--                    elsif mas.Claim_status = '20' then
--                         if cnt_det > 0 then
--                            v_ClaimSts := 'PHCLMSTS02'; 
--                        else
--                            v_ClaimSts := 'PHCLMSTS01'; 
--                        end if;                     
--                    elsif mas.Claim_status = '30' then
--                        if cnt_det > 0 then
--                            v_ClaimSts := 'PHCLMSTS03'; 
--                        else
--                            v_ClaimSts := 'PHCLMSTS01'; 
--                        end if;                      
--                    end if;
--                end if;

                v_Clmsts := 'NCCLMSTS01';
                
                nc_health_package.save_ncmas_history(v_STSKEY ,v_rst); -- keep log
                
                update NC_MAS
                set DIS_CODE = mas.ICD_10 ,LOSS_DATE =  mas.ACC_DATE ,TR_DATE_FR = mas.ADMIT ,TR_DATE_TO = mas.DISC ,TOT_TR_DAY = mas.DISC - mas.ADMIT+1
                ,LOSS_DETAIL = v_Detail ,HPT_CODE = mas.HOSP_CODE ,CLM_STS = v_ClmSts ,REMARK = v_Remark ,ICD10_2 = mas.ICD10_2 ,ICD10_3 = mas.ICD10_3
                ,ADMISSION_TYPE = v_ADMIT ,CLAIM_STATUS = v_ClaimSts
                where CLM_NO = v_CLMNO;
                
                Update clm_outservice_mas
                set BKI_CLM_NO = v_CLMNO 
                Where not_no = mas.NOT_NO and revision = mas.REVISION;
                                
                COMMIT;        
                
                if cnt_det >0 then
                    v_SaveStatus := p_ph_clm.SAVE_CLAIM_STATUS('payment' ,v_clmno ,v_payno) ;
                else
                    v_SaveStatus := p_ph_clm.SAVE_CLAIM_STATUS('claim_info_paid' ,v_clmno ,v_payno) ;
                end if;
            END LOOP; --pol
            
        END LOOP; --mas
    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            o_Rst := 'error REVISE_CLM: '||sqlerrm;    
    END REVISE_CLM;
    
    FUNCTION genRI_RES(v_stskey IN NUMBER ,v_clmno IN VARCHAR2 ,v_amt IN NUMBER) RETURN VARCHAR2 IS

        mySID   NUMBER;

        ri_mas_shr  number(5,2);
        ri_max_rec  number(2);
        v_tot_res   number(12,4);
        v_tot_paid   number(12,4):=v_amt;

        v_riamt number(12,4);
        v_sumri number(12,4);
        v_has_res   boolean:=true;
        r_cnt   number;     v_cnt_res number;

        v_polno varchar2(20); v_polrun number;
        v_lossdate  date;
        vLETT_PRT  varchar2(2);
        vLETT_TYPE  varchar2(2);
        vLett_no  varchar2(20);
        is_cashcall boolean:=false;
        v_polyr varchar2(4);
        v_clmyr varchar2(4);
        o_cashcall  varchar2(5);
        o_line  float;

        v_prodgrp varchar2(1);
        v_prodtype varchar2(5);
        v_type   varchar2(20):='NCNATTYPECLM101';
        v_subtype   varchar2(20):='NCNATSUBTYPECLM101';
        v_endseq    number;
        
        v_SYSDATE   date:=sysdate;

        C2   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data2 IS RECORD
        (
        POL_NO  MIS_RI_MAS.POL_NO%TYPE ,
        POL_RUN MIS_RI_MAS.POL_RUN%TYPE ,
        RI_CODE MIS_RI_MAS.RI_CODE%TYPE ,
        RI_BR_CODE MIS_RI_MAS.RI_BR_CODE%TYPE ,
        RI_TYPE MIS_RI_MAS.RI_TYPE%TYPE ,
        LF_FLAG MIS_RI_MAS.LF_FLAG%TYPE ,
        RI_SUB_TYPE MIS_RI_MAS.RI_SUB_TYPE%TYPE ,
        --RI_SUM  MIS_RI_MAS.RI_SUM_INS%TYPE ,
        --RI_SUM  NUMBER(20,2),
        RI_SUM_SHR   NUMBER
        );
        j_rec2 t_data2;
    BEGIN

        begin
            select pol_no ,pol_run ,loss_date ,clm_yr ,pol_yr ,prod_grp ,prod_type ,end_seq
            into v_polno ,v_polrun ,v_lossdate , v_clmyr ,v_polyr ,v_prodgrp ,v_prodtype ,v_endseq
            from nc_mas a
            where  clm_no= v_clmno;
        exception
            when no_data_found then
                v_polno := null;
                v_endseq := null;
                v_polyr := to_char(sysdate,'yyyy');
                v_clmyr := to_char(sysdate,'yyyy');
            when others then
                v_polno :=null;
                v_endseq := null;
                v_polyr := to_char(sysdate,'yyyy');
                v_clmyr := to_char(sysdate,'yyyy');
        end;

        begin
            select nvl(max(trn_seq),0)+1  into ri_max_rec
            from nc_ri_reserved a
            where prod_grp = '0'
            and clm_no = v_clmno
            and trn_seq in (select max(aa.trn_seq) from nc_ri_reserved aa where aa.clm_no = a.clm_no )
            ;

        exception
         when no_data_found then
             ri_max_rec := 1;
        when others then
            ri_max_rec := 1;
        end;
        
        v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(v_polno ,v_polrun ,0 ,0 ,v_lossdate ,v_endseq ,C2 );

        if v_cnt_res > 0 then
            mySID := nc_health_package.gen_sid();

            r_cnt :=0;
            v_sumri :=0;
            LOOP
               FETCH  C2 INTO j_rec2;
                EXIT WHEN C2%NOTFOUND;

                dbms_output.put_line('RI_CODE==>'||
                 j_rec2.ri_code||
                 ' RI_BR_CODE:'||
                  j_rec2.ri_br_code||
                 ' RI_SUM_SHR:'||
                  j_rec2.RI_SUM_SHR
                );
                v_riamt :=0;
                r_cnt := r_cnt+1;
                if r_cnt = v_cnt_res then
                    v_riamt := v_tot_paid-v_sumri;
                else
                    v_riamt := v_tot_paid * (j_rec2.RI_SUM_SHR/100);
                end if;
                v_riamt := trunc(v_riamt ,2);
                v_sumri := v_sumri + v_riamt;

                IF j_rec2.RI_TYPE = '1' THEN
                   is_cashcall := false;

                   nmtr_package.nc_get_cashcall(v_polyr,v_clmyr,
                                   j_rec2.ri_code ,j_rec2.ri_br_code ,j_rec2.lf_flag ,j_rec2.ri_type ,j_rec2.ri_sub_type ,
                                   v_riamt , 1,
                                   o_cashcall , o_line);

                   IF o_cashcall is not null THEN
                      vLETT_PRT := 'Y';
                      vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(v_prodtype);
                      vLETT_TYPE := 'L';
                   ELSE
                      vLETT_PRT := 'N';
                      vLETT_TYPE := 'P';
                   END IF;
                ELSIF j_rec2.RI_TYPE = '0' THEN
                      vLETT_PRT := 'Y';
                      vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(v_prodtype);
                      vLETT_TYPE := 'L';
                ELSE
                      vLETT_PRT := 'N';
                      vLETT_TYPE := 'P';
                END IF;
--
--                insert into TMP_RI_PAID (sid ,clm_no ,pay_no ,ri_code ,ri_br_code  ,ri_type
--                , RI_PAY_AMT ,RI_TRN_AMT  , lett_no
--                ,lett_prt, lett_type, STATUS, ri_lf_flag,ri_sub_type ,sub_type ,type
--                ,ri_share ,prod_grp ,prod_type
--                ) Values (mySID ,v_clmno, 'x', j_rec2.ri_code ,j_rec2.ri_br_code  ,j_rec2.ri_type
--                ,v_riamt ,v_riamt ,vLett_no
--                ,vLETT_PRT,vLETT_TYPE ,''  ,j_rec2.lf_flag ,j_rec2.ri_sub_type ,v_subtype ,v_type
--                ,j_rec2.RI_SUM_SHR ,v_prodgrp ,v_prodtype
--                );

                Insert into ALLCLM.NC_RI_RESERVED
                   (STS_KEY, CLM_NO, PROD_GRP, PROD_TYPE, TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_SHARE, TRN_SEQ, RI_STS_DATE, RI_AMD_DATE
                   , RI_RES_AMT, RI_TRN_AMT, LETT_TYPE ,LETT_NO, STATUS, LETT_PRT, SUB_TYPE, ORG_RI_RES_AMT)
                 Values
                   (v_stskey, v_clmno, v_prodgrp, v_prodtype, v_type, 
                     j_rec2.ri_code ,j_rec2.ri_br_code  ,j_rec2.ri_type ,j_rec2.lf_flag ,j_rec2.ri_sub_type, 
                    j_rec2.RI_SUM_SHR, ri_max_rec, v_SYSDATE, v_SYSDATE, v_riamt, 
                    v_riamt, vLETT_TYPE ,vLett_no, 'NCCLMSTS01', 
                    vLETT_PRT, v_subtype, 0);
        
                dbms_output.put_line('mySID='||mySID||' Tot_Paid='||v_tot_paid||' Ri_code:'||j_rec2.RI_CODE||' %shar='||j_rec2.RI_SUM_SHR||' Amt='||v_riamt);
            END LOOP; --C2

        else    -- case ต้องสำรวจข้อมูล RI อีกที
            dbms_output.put_line('CRI_RES clm:'||v_clmno ||' cannot find CompleteRI-> ');
            Return 'CRI_RES clm:'||v_clmno ||' cannot find CompleteRI-> ';
        end if;
        
        COMMIT;
        Return '';
    EXCEPTION
        WHEN OTHERS THEN
            rollback;
            dbms_output.put_line('error :'||sqlerrm);
            Return 'error :'||sqlerrm;
    END genRI_RES;

    PROCEDURE GET_OSTPAYEE_DETAIL(v_clmno IN VARCHAR2 , v_payee_name IN VARCHAR2 ,v_hos_flag IN VARCHAR2 ,v_hosp_code IN VARCHAR2
     , o_payee_code OUT VARCHAR2 ,o_payee_seq OUT VARCHAR2 ,o_payee_type OUT VARCHAR2 , o_payee_name OUT VARCHAR2 ,o_hosp_id   OUT VARCHAR2
     , o_contact_name OUT VARCHAR2 , o_addr1 OUT VARCHAR2  , o_addr2 OUT VARCHAR2  , o_mobile OUT VARCHAR2  , o_email OUT VARCHAR2
     ,o_agent_mobile  OUT VARCHAR2 ,o_agent_email  OUT VARCHAR2 ,o_paidto OUT VARCHAR2
     ,o_acc_no  out varchar2, o_acc_name_th out varchar2,  o_acc_name_en  out varchar2, o_bank_code  out varchar2, o_bank_br_code  out varchar2, o_deposit out varchar2) IS
     
        v_search_name varchar2(250);  
    BEGIN
        if V_HOS_FLAG is null then
          o_paidto := 'O';
        elsif V_HOS_FLAG ='P1' then --I
          o_paidto := 'I';
        elsif V_HOS_FLAG ='P5' then --H
          o_paidto := 'H';
        else
          o_paidto := 'O';            
        end if;
        
        IF O_PAIDTO = 'H' THEN
            begin
                select payee_code ,hosp_seq ,hosp_id into o_payee_code ,o_payee_seq ,o_hosp_id
                from med_hospital_list a
                where a.gm_code =v_hosp_code and rownum=1;

            exception
             when no_data_found then
                 o_payee_code := null;  o_hosp_id := null;
            when others then
                o_payee_code := null;   o_hosp_id := null;
            end;
            
            if o_payee_code is not null then
                o_payee_type := '06';
                p_ph_clm.GET_PAYEE_ACC(v_clmno ,o_payee_code ,O_ACC_NO ,O_ACC_NAME_TH ,O_ACC_NAME_EN, O_BANK_CODE ,O_BANK_BR_CODE ,O_DEPOSIT) ;
                p_ph_clm.GET_PAYEE_DETAIL(v_clmno ,o_payee_code ,o_payee_seq ,o_contact_name ,o_addr1 ,o_addr2 ,o_mobile , o_email
                    ,o_agent_mobile ,o_agent_email );
            end if;
        ELSE    -- paid Insure or Others
            V_search_name := nc_health_package.update_search_name(v_payee_name);
            begin                    
                select b.payee_code ,payee_type ,b.title||' '||b.name payee_name ,account_no ,decode(account_name_th,null,account_name_eng,account_name_th) account_name_th ,b.bank_code ,b.branch_code
                into o_payee_code ,o_payee_type ,o_payee_name ,O_ACC_NO ,O_ACC_NAME_TH ,O_BANK_CODE ,O_BANK_BR_CODE
                    from acc_payee b
                    where b.cancel is null
                    and b.search_title_name like '%'||v_search_name||'%';
                o_payee_seq := '1';                         
            exception
              when no_data_found then            
                    o_payee_code := null;   return;
              when too_many_rows then
                    o_payee_code := null;   return;
                when others then
                    o_payee_code := null;   return;
            end;
            if o_payee_code is not null then
                p_ph_clm.GET_PAYEE_ACC(v_clmno ,o_payee_code ,O_ACC_NO ,O_ACC_NAME_TH ,O_ACC_NAME_EN, O_BANK_CODE ,O_BANK_BR_CODE ,O_DEPOSIT) ;
                p_ph_clm.GET_PAYEE_DETAIL(v_clmno ,o_payee_code ,o_payee_seq ,o_contact_name ,o_addr1 ,o_addr2 ,o_mobile , o_email
                    ,o_agent_mobile ,o_agent_email );
            end if;                  
        END IF; -- Check Hospital 
        
    END GET_OSTPAYEE_DETAIL;
         
END P_PH_OST;
/
