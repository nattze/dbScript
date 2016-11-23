CREATE OR REPLACE PACKAGE BODY P_PH_CLM AS
/******************************************************************************
   NAME:       P_PH_CLM
   PURPOSE:     สำหรับ Projetc PH system
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        18/11/2016      2702       1. Created this package.
******************************************************************************/
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
     
END P_PH_CLM;

/