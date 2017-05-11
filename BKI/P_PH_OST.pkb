CREATE OR REPLACE PACKAGE BODY P_PH_OST AS
/******************************************************************************
   NAME:       P_PH_OST
   PURPOSE:     For Manage Ost Claim Data
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/4/2017      2702       1. Created this package.
******************************************************************************/
    FUNCTION TEST   RETURN VARCHAR2 IS
    
    BEGIN
        return 'Hello';
    END TEST;
    
    FUNCTION CAN_OPEN_CLAIM(v_notno  IN VARCHAR2 ,o_RST OUT VARCHAR2) RETURN BOOLEAN IS
        dumm_clm    varchar2(20);
    BEGIN
        select clm_no into dumm_clm
        from nc_mas
        where out_clm_no = v_notno ;
        
        if dumm_clm is not null then
            o_RST := 'Not_No นี้เปิดเคลม ได้เลข :'||dumm_clm||' แล้ว';
            return false;
        end if;

        select clm_no into dumm_clm
        from mis_clm_mas
        where out_clm_no = v_notno;
        
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
            else
                p_ph_ost.OPEN_CLM(v_date ,x.not_no ,v_user ,v_rst);
                
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
        
    BEGIN
        FOR mas IN (
            select not_no ,revision ,batch_no ,bki_clm_no ,pol_no ,fleet_seq ,reg_date ,not_date ,doc_date ,ret_date
            ,cus_code ,cus_name , sub_seq ,fam_seq ,id_no ,title ,name ,surname ,eff_date ,exp_date ,plan ,clm_type ,type_clm 
            ,acc_date ,admit ,disc ,hosp_amt ,disc_amt ,benf_covr ,non_cover ,benf_paid 
            ,hosp_code ,hosp_name ,ill_name ,icd_10 ,icd10_2 ,icd10_3 ,clm_pstat ,indication,treatment ,remark ,clm_decline ,fax_clm
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
                        v_SubType, 1, v_SYSDATE_T, v_SYSDATE_T, det.BENCODE, 
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
    
END P_PH_OST;
/
