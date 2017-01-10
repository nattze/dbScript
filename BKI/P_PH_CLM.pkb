CREATE OR REPLACE PACKAGE BODY P_PH_CLM AS
/******************************************************************************
   NAME:       P_PH_CLM
   PURPOSE:     สำหรับ Projetc PH system
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        18/11/2016      2702       1. Created this package.
******************************************************************************/
    FUNCTION GEN_NOTEKEY RETURN NUMBER IS
        v_key  NUMBER;
    BEGIN    

            BEGIN
                SELECT NC_NOTE_KEY.NEXTVAL into v_key
                FROM dual;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_key := 0;            
                WHEN  OTHERS THEN
                    v_key := 0;
            END;       
            Return v_key;
    END;    --End GEN_NOTEKEY 
    
    FUNCTION GET_CLMTYPE_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret   VARCHAR2(250);
    BEGIN
        select remark into v_ret
        from clm_constant a
        where key like 'PHCLMTYPE%'
        and key = v_code
        and rownum=1;
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;        
    END GET_CLMTYPE_DESCR; 
    
    FUNCTION GET_CLMSTS_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret   VARCHAR2(250);
    BEGIN
        select remark into v_ret
        from clm_constant a
        where key like 'PHCLMSTS%'
        and key = v_code
        and rownum=1;
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;        
    END GET_CLMSTS_DESCR; 

    FUNCTION GET_ADMISS_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret   VARCHAR2(250);
    BEGIN
        select remark into v_ret
        from clm_constant a
        where key like 'PHADMTYPE%'
        and key = v_code
        and rownum=1;
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;        
    END GET_ADMISS_DESCR; 
    
    FUNCTION GET_BENE_DESCR(v_benecode IN VARCHAR2 ,v_lang IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret   VARCHAR2(250);
    BEGIN
        select descr into v_ret
        from  medical_ben_std z 
        where z.bene_code =v_benecode and th_eng = nvl(v_lang, 'T' );
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;
    END GET_BENE_DESCR;

    FUNCTION GET_HOSPITAL_NAME(v_code IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret   VARCHAR2(250);
    BEGIN
        select distinct name_t  into v_ret
        from med_hospital_list
        where hosp_id = v_code
        and rownum =1 ;        
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;        
    END GET_HOSPITAL_NAME; 

    FUNCTION GET_ICD10_DESCR(v_code IN VARCHAR2  ,v_lang IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret   VARCHAR2(250);
    BEGIN
 
        select dis_text   into v_ret
        from dis_code_std
        where th_eng = nvl(v_lang ,'T' )  and dis_code = v_code
         ;            
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;        
    END GET_ICD10_DESCR; 

    FUNCTION GET_PAIDBY_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret   VARCHAR2(250);
    BEGIN
          select descr into v_ret
         from clm_constant 
         where key like 'PAIDTYPE%' 
        and remark = v_code
        and rownum =1 ;        
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;        
    END GET_PAIDBY_DESCR; 
    
    FUNCTION GET_BANK_BRNAME(v_bank IN VARCHAR2 ,v_branch IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret   VARCHAR2(250);
        v_bankname  VARCHAR2(100);
        v_brname   VARCHAR2(200);   
    BEGIN
        select substr(thai_name,1,50) into v_bankname
        from   bank
        where  bank_code =v_bank and rownum=1;
                    
        select substr(thai_brn_name,1,50) into  v_brname
        from   bank_branch
        where  bank_code = v_bank
        and    branch_code = v_branch and rownum=1;    
        
        v_ret := v_bankname||' '||v_brname;
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;        
    END GET_BANK_BRNAME;     
        
                
    FUNCTION MAPP_BENECODE(v_bill IN VARCHAR2 ,v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2) RETURN VARCHAR2 IS
        o_type  varchar2(5);
        ret_bene    varchar2(10);
    BEGIN
         misc.healthutil.get_pa_health_type(v_polno ,v_polrun ,o_type);  
             
         if o_type ='HG' then
            begin
                select a.bene_code  into ret_bene
                from pa_gm_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan
                and a.bene_code in (
                    select x.bene_code
                    from nc_billing_mapp x
                    where x.cancel is null 
                    and x.bill_code = v_bill
                ) and rownum=1;            
            exception
                when no_data_found then
                    ret_bene := null;
                when others then
                    ret_bene := null;
            end;
         elsif o_type = 'HI' then
            begin
                select a.bene_code  into ret_bene
                from pa_ph_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan
                and a.bene_code in (
                    select x.bene_code
                    from nc_billing_mapp x
                    where x.cancel is null 
                    and x.bill_code = v_bill
                ) and rownum=1;            
            exception
                when no_data_found then
                    ret_bene := null;
                when others then
                    ret_bene := null;
            end;         
         else
            ret_bene := null;
         end if;
           
        return ret_bene;
    END MAPP_BENECODE;
    
    FUNCTION GET_PH_BENEFIT(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_type IN VARCHAR2 ,v_benecode IN VARCHAR2 ,O_Benefit Out P_PH_CLM.v_curr) RETURN VARCHAR2 IS -- Return null = success ,not null = show error
        v_ret   varchar2(250);
        o_type  varchar2(5);
        cnt_rec number(10);
    BEGIN
         misc.healthutil.get_pa_health_type(v_polno ,v_polrun ,o_type);  
             
         if o_type ='HG' then
            begin
                select count(*)  into cnt_rec
                from pa_gm_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan
                and pd_flag like nvl( v_type ,'%' )
                and bene_code like nvl( v_benecode ,'%' );            
            exception
                when no_data_found then
                    cnt_rec := 0;
                when others then
                    cnt_rec := 0;
            end;
            
            if cnt_rec >0 then
            open O_Benefit for
                select pd_flag bene_type ,bene_code ,p_ph_clm.get_bene_descr(a.bene_code ,'T') bene_descr ,rider ,agr_flag ,max_day ,max_amt ,sub_agr_amt
                from pa_gm_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan
                and pd_flag like nvl( v_type ,'%' )
                and bene_code like nvl( v_benecode ,'%' );
             end if;   
         elsif o_type = 'HI' then
            begin
                select  count(*)  into cnt_rec
                from pa_ph_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan
                and pd_flag like nvl( v_type ,'%' )
                and bene_code like nvl( v_benecode ,'%' );            
            exception
                when no_data_found then
                    cnt_rec := 0;
                when others then
                    cnt_rec := 0;
            end;     
            if cnt_rec >0 then
            open O_Benefit for
                select pd_flag bene_type ,bene_code ,p_ph_clm.get_bene_descr(a.bene_code ,'T') bene_descr ,rider ,agr_flag ,max_day ,max_amt ,sub_agr_amt
                from pa_ph_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan
                and pd_flag like nvl( v_type ,'%' )
                and bene_code like nvl( v_benecode ,'%' );
             end if;                   
         else
            cnt_rec := 0;            
         end if;
         
         if cnt_rec = 0 then
            v_ret := 'not found benefit';
            open O_Benefit for
                select '' bene_type ,'' bene_code ,'' bene_descr ,'' rider ,'' agr_flag ,null max_day ,null max_amt ,null  sub_agr_amt
                from dual;
         end if;
                 
        return v_ret;
    EXCEPTION
        WHEN OTHERS THEN
            v_ret := 'error:'||sqlerrm;
            open O_Benefit for
                select '' bene_type ,'' bene_code ,'' bene_descr ,'' rider ,'' agr_flag ,null max_day ,null max_amt ,null  sub_agr_amt
                from dual;            
            return v_ret;
    END GET_PH_BENEFIT;
    
    
    FUNCTION GET_LIST_CLMTYPE(O_CLMTYPE_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 IS
        v_ret   varchar2(250);
        cnt_rec number(10);    
    BEGIN
            begin
                select count(*)  into cnt_rec
                from clm_constant a
                where key like 'PHCLMTYPE%' 
                and nvl(exp_date ,trunc(sysdate)+1) > trunc(sysdate); 
            exception 
                when no_data_found then
                    cnt_rec := 0; 
                when others then
                    cnt_rec := 0; 
            end;

            if cnt_rec >0 then
            OPEN O_CLMTYPE_LIST For
                select key VALUE ,remark TEXT
                from clm_constant a
                where key like 'PHCLMTYPE%'
                and nvl(exp_date ,trunc(sysdate)+1) > trunc(sysdate);
             end if;                   
       
         
             if cnt_rec = 0 then
                v_ret := 'not found list';
                open O_CLMTYPE_LIST for
                    select '' VALUE ,'' TEXT 
                    from dual;   
             end if;
             
             return v_ret;                  
    EXCEPTION
        WHEN OTHERS THEN
            v_ret := 'error:'||sqlerrm;
            open O_CLMTYPE_LIST for
                select '' VALUE ,'' TEXT 
                from dual;            
            return v_ret;    
    END GET_LIST_CLMTYPE;

    FUNCTION GET_LIST_CLMSTS(O_CLMSTS_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 IS
        v_ret   varchar2(250);
        cnt_rec number(10);    
    BEGIN
            begin
                select count(*)  into cnt_rec
                from clm_constant a
                where key like 'PHCLMSTS%' 
                and nvl(exp_date ,trunc(sysdate)+1) > trunc(sysdate); 
            exception 
                when no_data_found then
                    cnt_rec := 0; 
                when others then
                    cnt_rec := 0; 
            end;

            if cnt_rec >0 then
            OPEN O_CLMSTS_LIST For
                select key VALUE ,remark TEXT
                from clm_constant a
                where key like 'PHCLMSTS%'
                and nvl(exp_date ,trunc(sysdate)+1) > trunc(sysdate);
             end if;                   
       
         
             if cnt_rec = 0 then
                v_ret := 'not found list';
                open O_CLMSTS_LIST for
                    select '' VALUE ,'' TEXT 
                    from dual;   
             end if;
             
             return v_ret;                  
    EXCEPTION
        WHEN OTHERS THEN
            v_ret := 'error:'||sqlerrm;
            open O_CLMSTS_LIST for
                select '' VALUE ,'' TEXT 
                from dual;            
            return v_ret;    
    END GET_LIST_CLMSTS;

    FUNCTION GET_LIST_BENETYPE(O_BENETYPE_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 IS
        v_ret   varchar2(250);
        cnt_rec number(10):=1;    
    BEGIN
            

            if cnt_rec >0 then
            OPEN O_BENETYPE_LIST For
                select 'I' VALUE ,'IPD' TEXT from dual
                union
                select 'O' VALUE ,'OPD' TEXT from dual
                union
                select 'S' VALUE ,'Special' TEXT from dual;
             end if;                   
       
         
             if cnt_rec = 0 then
                v_ret := 'not found list';
                open O_BENETYPE_LIST for
                    select '' VALUE ,'' TEXT 
                    from dual;   
             end if;
             
             return v_ret;                  
    EXCEPTION
        WHEN OTHERS THEN
            v_ret := 'error:'||sqlerrm;
            open O_BENETYPE_LIST for
                select '' VALUE ,'' TEXT 
                from dual;            
            return v_ret;    
    END GET_LIST_BENETYPE;

    FUNCTION GET_LIST_HOSPITAL (vName IN VARCHAR2 ,O_HOSP_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 IS  
--        c1   NC_HEALTH_PACKAGE.v_ref_cursor4;
--        TYPE t_data1 IS RECORD
--        (
--        HPT_CODE  acc_payee_detail.PAYEE_CODE%TYPE ,
--        NAME_TH acc_payee_detail.NAME_TH%TYPE ,
--        NAME_ENG acc_payee_detail.NAME_ENG%TYPE 
--        ); 
--        j_rec1 t_data1; 
        v_searchname varchar2(100);
        v_ret varchar2(250);
    BEGIN
        v_searchname := NC_HEALTH_PACKAGE.UPDATE_SEARCH_NAME(vName) ;
        --dbms_output.put_line('Search Name ==>'||v_searchname);  
           OPEN O_HOSP_LIST  FOR 
            select (select hosp_id  from med_hospital_list x  where x.payee_code =  a.payee_code and x.hosp_seq = a.payee_seq   and rownum =1) HPT_CODE ,NAME_TH NAME  
             from acc_payee_detail a
             where a.payee_seq>=1 
             and search_name like '%'||v_searchname||'%'
             and a.payee_code in (select x.payee_code from acc_payee x where x.payee_code = a.payee_code and payee_type = '06' and cancel is null)
--             and (a.payee_code ,a.payee_seq) in (select x.payee_code ,x.hosp_seq from med_hospital_list x )
             ;       
             return v_ret;       

    EXCEPTION
           when no_data_found then 
            v_ret := 'Not found Hospital';
            OPEN O_HOSP_LIST  FOR SELECT '' HPT_CODE , '' NAME  FROM DUAL;
            return v_ret;           
   
           when others then 
            v_ret := 'error: '||sqlerrm;
            OPEN O_HOSP_LIST  FOR SELECT '' HPT_CODE , '' NAME  FROM DUAL;
            return v_ret;  
                      
    END GET_LIST_HOSPITAL;   
     

    FUNCTION GET_LIST_ICD10 (vName IN VARCHAR2 ,O_ICD10_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 IS  
        v_searchname varchar2(100);
        v_ret varchar2(250);
    BEGIN
        v_searchname := vName ;
           OPEN O_ICD10_LIST  FOR 
                select dis_code value ,dis_text text
                from dis_code_std
                where th_eng = nvl(null ,'T' ) 
                and ( dis_code like '%'||v_searchname||'%' 
                or dis_text like '%'||v_searchname||'%' 
                ) ;       
             return v_ret;       

    EXCEPTION
           when no_data_found then 
            v_ret := 'Not found Code';
            OPEN O_ICD10_LIST  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;           
   
           when others then 
            v_ret := 'error: '||sqlerrm;
            OPEN O_ICD10_LIST  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;  
                      
    END GET_LIST_ICD10;   
     

    FUNCTION GET_LIST_ADMISSION (O_ADM_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 IS  
        v_searchname varchar2(100);
        v_ret varchar2(250);
    BEGIN
           OPEN O_ADM_LIST  FOR 
                select key value ,remark text
                from clm_constant a
                where key like 'PHADMTYPE%'
                 ;       
             return v_ret;       

    EXCEPTION
           when no_data_found then 
            v_ret := 'Not found Type';
            OPEN O_ADM_LIST  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;           
   
           when others then 
            v_ret := 'error: '||sqlerrm;
            OPEN O_ADM_LIST  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;  
                      
    END GET_LIST_ADMISSION;   
     
    FUNCTION GET_LIST_BILLSTD (vName IN VARCHAR2 ,O_BILLSTD_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 IS  
        v_searchname varchar2(100);
        v_ret varchar2(250);
    BEGIN
        v_searchname := vName ;
           OPEN O_BILLSTD_LIST  FOR    
                select code value ,descr_th text
                from nc_billing_std                
                where  code like '%'||v_searchname||'%' 
                or descr_th like '%'||v_searchname||'%' ;
                
             return v_ret;       

    EXCEPTION
           when no_data_found then 
            v_ret := 'Not found Code';
            OPEN O_BILLSTD_LIST  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;           
   
           when others then 
            v_ret := 'error: '||sqlerrm;
            OPEN O_BILLSTD_LIST  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;  
                      
    END GET_LIST_BILLSTD;   
     
    FUNCTION GET_LIST_PAIDBY (O_PAIDBY Out P_PH_CLM.v_curr ) RETURN VARCHAR2 IS  
        v_searchname varchar2(100);
        v_ret varchar2(250);
    BEGIN
           OPEN O_PAIDBY  FOR 
                select remark value ,descr text
                from clm_constant a
                where key like 'PAIDTYPE%'
                 ;       
             return v_ret;       

    EXCEPTION
           when no_data_found then 
            v_ret := 'Not found Type';
            OPEN O_PAIDBY  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;           
   
           when others then 
            v_ret := 'error: '||sqlerrm;
            OPEN O_PAIDBY  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;  
                      
    END GET_LIST_PAIDBY;   

    FUNCTION GET_SPECIAL_FLAG (O_SPECIAL Out P_PH_CLM.v_curr )  RETURN VARCHAR2 IS  
        v_searchname varchar2(100);
        v_ret varchar2(250);
    BEGIN
           OPEN O_SPECIAL  FOR 
                select remark value ,descr text
                from clm_constant a
                where key like 'PSPECIAL%'
                 ;       
             return v_ret;       

    EXCEPTION
           when no_data_found then 
            v_ret := 'Not found Type';
            OPEN O_SPECIAL  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;           
   
           when others then 
            v_ret := 'error: '||sqlerrm;
            OPEN O_SPECIAL  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;  
                      
    END GET_SPECIAL_FLAG;        

    FUNCTION  GET_INVALID_PAYEE (O_INV_PAYEE Out P_PH_CLM.v_curr )  RETURN VARCHAR2 IS  
        v_searchname varchar2(100);
        v_ret varchar2(250);
    BEGIN
           OPEN O_INV_PAYEE  FOR 
                select remark value ,descr text
                from clm_constant a
                where key like 'INVALIDPAYEE%'
                 ;       
             return v_ret;       

    EXCEPTION
           when no_data_found then 
            v_ret := 'Not found Type';
            OPEN O_INV_PAYEE  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;           
   
           when others then 
            v_ret := 'error: '||sqlerrm;
            OPEN O_INV_PAYEE  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;  
                      
    END GET_INVALID_PAYEE;      

    FUNCTION SAVE_CLAIM_STATUS(v_action IN VARCHAR2 ,v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN VARCHAR2 IS
        /*
            v_action  :
            claim_info_res  หน้า KeyIn tab ClaimInfo
            billing     หน้า KeyIn tab Billing
            benefit     หน้า KeyIn tab Benefit
            ri_reserved     หน้า KeyIn tab ReInsurance
        */    
        v_ret   VARCHAR2(250);
        vsts_key    NUMBER;
        v_rst   VARCHAR2(250);  
        save_Detail_Status VARCHAR2(25);
        save_NC_Status VARCHAR2(25);
    BEGIN
        if v_action is null or v_clmno is null then
            v_ret := 'กรุณาระบุข้อมูลให้ครบ';
            return v_ret;
        end if;
        
        begin
            select sts_key into vsts_key
            from nc_mas
            where clm_no = v_clmno;
        exception
            when no_data_found then
                v_ret := 'ไม่พบข้อมูล Claim';
            when others then
                v_ret := 'ไม่พบข้อมูล Claim';
        end;
        
        if v_ret is not null then
            return v_ret;
        end if;
        
        nc_health_package.save_ncmas_history(vsts_key ,v_rst);
        
        if v_rst is not null then
            return v_rst;
        end if;
        
        if v_action = 'claim_info_res' then
            if P_PH_CLM.IS_BILLING_STEP(v_clmno ,v_rst) = '0' then -- ไม่ได้อยู่ในขั้น billing 
               
                save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION('benefit' ,'D');
                save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION('benefit' ,'O');
            end if;
            
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');
        elsif v_action = 'billing' then    
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');
        elsif v_action = 'benefit' then    
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');
        elsif v_action = 'ri_reserved' then    
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');
        end if;
        
        dbms_output.put_line('save_NC_Status='||save_NC_Status||' save_Detail_Status='||save_Detail_Status);
        UPDATE NC_MAS
        SET clm_sts = save_NC_Status ,claim_status = save_Detail_Status
        WHERE CLM_NO = v_clmno;
        
        COMMIT;
        
        return v_ret;
    EXCEPTION    
        WHEN OTHERS THEN 
        ROLLBACK;
        v_ret := 'error: '||sqlerrm;
        return v_ret;      
    END SAVE_CLAIM_STATUS;    

    FUNCTION getRI_PAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2 ,v_amt IN NUMBER ,O_RI OUT P_PH_CLM.v_curr) RETURN VARCHAR2 IS

        mySID   NUMBER;

        ri_mas_shr  number(5,2);
        ri_max_rec  number(2);
        v_tot_res   number(10,4);
        v_tot_paid   number(10,4):=v_amt;
  
        v_riamt number(10,4);
        v_sumri number(10,4);
        v_has_res   boolean:=true;
        r_cnt   number;        
    BEGIN

        begin 
            select sum(ri_share)
            into ri_mas_shr
            from nc_ri_reserved a
            where  clm_no= v_clmno
            and trn_seq = (select max(trn_seq) from nc_ri_reserved where clm_no = a.clm_no) 
            ;
        exception
            when no_data_found then
                ri_mas_shr :=0;
            when others then
                ri_mas_shr :=0;
        end;  
            
        if ri_mas_shr = 100 then
            mySID := nc_health_package.gen_sid();
            
            r_cnt :=0;
            v_sumri :=0;
            for R in (
                select ri_code ,ri_br_code ,ri_type  ,ri_sub_type
                ,ri_share ,lett_prt,lett_type ,'' pay_sts ,ri_lf_flag ,sub_type ,type
                ,lett_no ,prod_grp ,prod_type
                from nc_ri_reserved x
                where clm_no = v_clmno and trn_seq = (select max(rr.trn_seq) from nc_ri_reserved rr where rr.clm_no = x.clm_no group by rr.clm_no)  
                order by x.ri_code                             
            )loop
                v_riamt :=0;
                r_cnt := r_cnt+1;
                if r_cnt = ri_max_rec then
                    v_riamt := v_tot_paid-v_sumri;
                else
                    v_riamt := v_tot_paid * (R.ri_share/100);    
                end if;
                v_riamt := trunc(v_riamt ,2);
                v_sumri := v_sumri + v_riamt;

                insert into TMP_RI_PAID (sid ,clm_no ,pay_no ,ri_code ,ri_br_code  ,ri_type 
                , RI_PAY_AMT ,RI_TRN_AMT  , lett_no
                ,lett_prt, lett_type, STATUS, ri_lf_flag,ri_sub_type ,sub_type ,type
                ,ri_share ,prod_grp ,prod_type
                ) Values (mySID ,v_clmno, v_payno, R.ri_code ,R.ri_br_code  ,R.ri_type 
                ,v_riamt ,v_riamt ,R.lett_no
                ,R.lett_prt,R.lett_type ,R.pay_sts ,R.ri_lf_flag ,R.ri_sub_type ,R.sub_type ,R.type
                ,R.ri_share ,R.prod_grp ,R.prod_type
                );
                               
                dbms_output.put_line('mySID='||mySID||' Tot_Paid='||v_tot_paid||' Ri_code:'||R.ri_code||' %shar='||R.ri_share||' Amt='||v_riamt);
            end loop; --Loop R
         
        else    -- case ต้องสำรวจข้อมูล RI อีกที
            dbms_output.put_line('CRI_PAID clm:'||v_clmno ||' cannot find CompleteRI-> '||ri_mas_shr);
            OPEN O_RI  FOR 
            SELECT '' clm_no ,'' pay_no ,'' ri_code ,'' ri_br_code  ,'' ri_type 
                            , null ri_pay_amt ,null ri_trn_amt  ,'' lett_no
                            ,'' lett_prt,'' lett_type,'' status,'' ri_lf_flag ,'' ri_sub_type ,'' sub_type ,'' type
                            ,null ri_share ,'' prod_grp ,'' prod_type ,'' ri_display ,'' ri_name FROM DUAL;
            Return '0';                
        end if;    
    
        OPEN O_RI  FOR 
            SELECT clm_no ,pay_no ,ri_code ,ri_br_code  ,ri_type 
                , ri_pay_amt ,ri_trn_amt  , lett_no
                ,lett_prt, lett_type, status, ri_lf_flag,ri_sub_type ,sub_type ,type
                ,ri_share ,prod_grp ,prod_type 
                 ,ri_code||ri_br_code||'-'||ri_lf_flag||'-'||ri_type||ri_sub_type RI_DISPLAY ,nc_health_package.RI_NAME(ri_code ,ri_br_code) RI_NAME
                FROM TMP_RI_PAID
            WHERE SID = mySID;
        
        delete     TMP_RI_PAID where SID = mySID;
        commit;    
        Return '1';  
    EXCEPTION
        WHEN OTHERS THEN
            rollback;
                OPEN O_RI  FOR 
                SELECT '' clm_no ,'' pay_no ,'' ri_code ,'' ri_br_code  ,'' ri_type 
                                , null ri_pay_amt ,null ri_trn_amt  ,'' lett_no
                                ,'' lett_prt,'' lett_type,'' status,'' ri_lf_flag ,'' ri_sub_type ,'' sub_type ,'' type
                                ,null ri_share ,'' prod_grp ,'' prod_type ,'' ri_display ,'' ri_name FROM DUAL;
            dbms_output.put_line('error :'||sqlerrm);
            Return '0';    
    END getRI_PAID;    

    FUNCTION validate_RI_RES(v_clmno IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret VARCHAR2(250):='';
        ri_mas_shr  number(5,2);
        ri_res_sum  number(5,2);
    BEGIN
        begin 
            select nvl(sum(ri_share),0) ,nvl(sum(ri_res_amt),0) 
            into ri_mas_shr ,ri_res_sum
            from nc_ri_reserved a
            where  clm_no= v_clmno
            and trn_seq = (select max(trn_seq) from nc_ri_reserved where clm_no = a.clm_no) 
            ;
        exception
            when no_data_found then
                ri_mas_shr :=0;
                ri_res_sum := 0;
            when others then
                ri_mas_shr :=0;
                ri_res_sum := 0;
        end;          
        --dbms_output.put_line('ri_mas_shr= '||ri_mas_shr||' ri_res_sum='||ri_res_sum);
        if ri_mas_shr <> 100 then
            v_ret := 'RI Reserve <> 100% ';
        else
            if ri_res_sum <=0 then
                v_ret := 'Not found RI Amt or RI Amt =0 ';
            end if;        
        end if;
        
        return v_ret;        
    EXCEPTION    
        WHEN OTHERS THEN 
        v_ret := 'error: '||sqlerrm;
        return v_ret;       
    END validate_RI_RES;
            
    FUNCTION GET_MAPPING_ACTION(v_code IN VARCHAR2 ,v_mode IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret   VARCHAR2(250);
    BEGIN
        if v_mode = 'D' then
            select remark2 into v_ret
            from clm_constant a
            where key like 'PHMAPACTION%'
            and remark = v_code
            and rownum=1;            
        else 
            select remark3 into v_ret
            from clm_constant a
            where key like 'PHMAPACTION%'
            and remark = v_code
            and rownum=1;             
        end if;      
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;        
    END GET_MAPPING_ACTION;  
    
    FUNCTION IS_BILLING_STEP(v_clmno IN VARCHAR2 ,v_rst OUT VARCHAR2)  RETURN VARCHAR2 IS -- 0=false ,1=true
        v_ret   VARCHAR2(250):='0';
        sum_amt    NUMBER;
    BEGIN
        select sum(nvl(res_amt,0)) into sum_amt
        from nc_reserved a
        where prod_grp = '0' and  clm_no = v_clmno
        and a.trn_seq in (select max(bb.trn_seq) from nc_reserved bb where bb.clm_no = a.clm_no);
        
        if sum_amt > 0 then
            v_rst := 'ไม่สามารถบันทึก Billing ได้ เนื่องจากมีการบันทึก Benefit ไปแล้ว';
            return '0';
        else
            if P_PH_CLM.IS_CLOSED_CLAIM(v_clmno) = '0' then --false    
                v_rst := 'เคลมนี้ปิดไปแล้ว';
                return '0';            
            else
                return '1';  
            end if;   
        end if;
           
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return v_ret;
        WHEN OTHERS THEN
            return v_ret;        
    END IS_BILLING_STEP;   
    
    FUNCTION IS_CLOSED_CLAIM(v_clmno IN VARCHAR2)  RETURN VARCHAR2 IS -- 0=false ,1=true
        v_ret   VARCHAR2(250):='0';
        v_clmsts     VARCHAR2(25);
    BEGIN
        select clm_sts into v_clmsts
        from nc_mas a
        where prod_grp = '0' and  clm_no = v_clmno;
        
        if v_clmsts in ('NCCLMSTS02' ,'NCCLMSTS03') then
            v_ret := '0';
        else
           v_ret := '1';          
        end if;
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return v_ret;
        WHEN OTHERS THEN
            return v_ret;   
    END IS_CLOSED_CLAIM;  
             
END P_PH_CLM;

/