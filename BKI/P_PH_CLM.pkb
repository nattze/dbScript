CREATE OR REPLACE PACKAGE BODY P_PH_CLM AS
/******************************************************************************
   NAME:       P_PH_CLM
   PURPOSE:     สำหรับ Projetc PH system
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        18/11/2016      2702       1. Created this package.
******************************************************************************/
    FUNCTION PH_SIGNIN(v_user IN VARCHAR2 ,v_pass IN VARCHAR2) RETURN VARCHAR2 IS
        v_sys   VARCHAR2(20);
        v_found VARCHAR2(10);
    BEGIN
        BEGIN
            select UPPER(substr(instance_name,1,8)) instance_name into v_sys
            from v$instance;
        EXCEPTION
            WHEN  NO_DATA_FOUND THEN
                v_sys := null;            
            WHEN  OTHERS THEN
                v_sys := null;
        END;           
        
        IF v_sys = 'DBBKIINS' THEN -- Prod..
            IF center.core_ldap.ldap_authentication(v_user ,v_pass ) THEN
                return 'Y';
            END IF;
        ELSE
            BEGIN
                select user_name into v_found
                from nc_user
                where UPPER(user_name) = UPPER(v_user)
                and UPPER(password) = UPPER(v_pass)  ;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_found := null;            
                WHEN  OTHERS THEN
                    v_found := null;
            END;    
            
            if v_found is not null then
                return 'Y';
            end if;               
        END IF;
        
        return 'N';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return 'N';
        WHEN OTHERS THEN
            return 'N';            
    END PH_SIGNIN;
    
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

    FUNCTION GET_APPRVSTS_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret   VARCHAR2(250);
    BEGIN
        select descr into v_ret
        from clm_constant a
        where key like 'PHSTSAPPRV%'
        and key = v_code
        and rownum=1;
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;        
    END GET_APPRVSTS_DESCR; 
    
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
        
    FUNCTION GET_BENE_TYPE(v_code IN VARCHAR2) RETURN VARCHAR2 IS
        v_type    varchar2(5);
    BEGIN
        select type into v_type
        from medical_ben_std 
        where bene_code = v_code and th_eng='T'
        ;
        return v_type;
    EXCEPTION
        when no_data_found then return 'X' ;
        when others then return 'X' ;
    END GET_BENE_TYPE;

    FUNCTION GET_BENETYPE_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret   VARCHAR2(250);
    BEGIN
        select remark2 into v_ret
        from clm_constant a
        where key like 'PHBENETYPE%'
        and remark = v_code
        and rownum=1;
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;        
    END GET_BENETYPE_DESCR; 
                    
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
                from (
                select pd_flag bene_type ,bene_code ,p_ph_clm.get_bene_descr(a.bene_code ,'T') bene_descr ,rider ,agr_flag ,max_day ,max_amt ,sub_agr_amt
                from pa_gm_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan
                and pd_flag like nvl( v_type ,'%' )
                and bene_code like nvl( v_benecode ,'%' )
                );            
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
                and bene_code like nvl( v_benecode ,'%' ) ;
             end if;   
         elsif o_type = 'HI' then
            begin
                select  count(*)  into cnt_rec
                from(
                select pd_flag bene_type ,bene_code ,p_ph_clm.get_bene_descr(a.bene_code ,'T') bene_descr ,rider ,agr_flag ,max_day ,max_amt ,sub_agr_amt
                from pa_ph_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan
                and pd_flag like nvl( v_type ,'%' )
                and bene_code like nvl( v_benecode ,'%' )   
                );            
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

    FUNCTION GET_PH_BENEFIT_4search(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_type IN VARCHAR2 ,v_benecode IN VARCHAR2 ,O_Benefit Out P_PH_CLM.v_curr) RETURN VARCHAR2 IS -- Return null = success ,not null = show error
        v_ret   varchar2(250);
        o_type  varchar2(5);
        cnt_rec number(10);
    BEGIN
         misc.healthutil.get_pa_health_type(v_polno ,v_polrun ,o_type);  
             
         if o_type ='HG' then
            begin
                select count(*)  into cnt_rec
                from (
                select pd_flag bene_type ,bene_code ,p_ph_clm.get_bene_descr(a.bene_code ,'T') bene_descr ,rider ,agr_flag ,max_day ,max_amt ,sub_agr_amt
                from pa_gm_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan
                and pd_flag like nvl( v_type ,'%' )
                and bene_code like nvl( v_benecode ,'%' )
                UNION
                select clm_pd_flag bene_type ,bene_code ,p_ph_clm.get_bene_descr(x.bene_code ,'T') bene_descr ,rider ,'M' agr_flag ,null max_day ,null max_amt ,null sub_agr_amt
                from medical_ben_std x
                where bene_code in ('001','002','003','004','005','006','007','008','009','010','011','012','013')
                and th_eng ='T'                
                and clm_pd_flag like nvl( v_type ,'%' )
                and bene_code like nvl( v_benecode ,'%' )
                );            
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
                and bene_code like nvl( v_benecode ,'%' )
                UNION
                select clm_pd_flag bene_type ,bene_code ,p_ph_clm.get_bene_descr(x.bene_code ,'T') bene_descr ,rider ,'M' agr_flag ,null max_day ,null max_amt ,null sub_agr_amt
                from medical_ben_std x
                where bene_code in ('001','002','003','004','005','006','007','008','009','010','011','012','013')
                and th_eng ='T'                
                and clm_pd_flag like nvl( v_type ,'%' )
                and bene_code like nvl( v_benecode ,'%' ) ;
             end if;   
         elsif o_type = 'HI' then
            begin
                select  count(*)  into cnt_rec
                from(
                select pd_flag bene_type ,bene_code ,p_ph_clm.get_bene_descr(a.bene_code ,'T') bene_descr ,rider ,agr_flag ,max_day ,max_amt ,sub_agr_amt
                from pa_ph_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan
                and pd_flag like nvl( v_type ,'%' )
                and bene_code like nvl( v_benecode ,'%' )
                UNION
                select clm_pd_flag bene_type ,bene_code ,p_ph_clm.get_bene_descr(x.bene_code ,'T') bene_descr ,rider ,'M' agr_flag ,null max_day ,null max_amt ,null sub_agr_amt
                from medical_ben_std x
                where bene_code in ('001','002','003','004','005','006','007','008','009','010','011','012','013')
                and th_eng ='T'                
                and clm_pd_flag like nvl( v_type ,'%' )
                and bene_code like nvl( v_benecode ,'%' )              
                );            
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
                and bene_code like nvl( v_benecode ,'%' )
                UNION
                select clm_pd_flag bene_type ,bene_code ,p_ph_clm.get_bene_descr(x.bene_code ,'T') bene_descr ,rider ,'M' agr_flag ,null max_day ,null max_amt ,null sub_agr_amt
                from medical_ben_std x
                where bene_code in ('001','002','003','004','005','006','007','008','009','010','011','012','013')
                and th_eng ='T'                
                and clm_pd_flag like nvl( v_type ,'%' )
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
    END GET_PH_BENEFIT_4search;
    
    FUNCTION GET_WAITING_PERIOD(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_fleet IN NUMBER  
    ,O_Wait Out P_PH_CLM.v_curr) RETURN VARCHAR2 IS
        v_ret   varchar2(250);
        cnt_rec number(10);    
        p_period  number(5):=90;
        p_prodtype varchar2(10);
        p_fr    date;
        p_to    date;
    BEGIN
            begin
                select prod_type
                into p_prodtype
                from mis_mas
                where pol_no = v_polno
                and pol_run = v_polrun and rownum=1; 
            exception 
                when no_data_found then
                    p_prodtype := null;
                when others then
                    p_prodtype := null;
            end;
            
            if p_prodtype is not null then
                if p_prodtype in ('009' ,'073') then
                    p_period := 30;
                elsif p_prodtype in ('077','049','026') then
                    p_period := 90;
                else
                    p_period := 0;    
                end if;
            end if;
            
            begin
                select min(fr_date) ,min(fr_date)+p_period
                into p_fr ,p_to
                from pa_medical_det
                where pol_no = v_polno
                and pol_run = v_polrun
                and fleet_seq = v_fleet; 
            exception 
                when no_data_found then
                    p_fr := null; p_to := null;
                when others then
                    p_fr := null; p_to := null;
            end;

            if p_fr is not null then
            OPEN O_Wait For
                select p_period W_PERIOD ,p_fr W_FROM ,p_to W_TO 
                from dual a;
             end if;                   
       
         
             if cnt_rec = 0 then
                v_ret := 'not found ';
                OPEN O_Wait For
                    select '' W_PERIOD ,'' W_FROM ,'' W_TO 
                    from dual a;
             end if;
             
             return v_ret;                  
    EXCEPTION
        WHEN OTHERS THEN
            v_ret := 'error:'||sqlerrm;
                OPEN O_Wait For
                    select '' W_PERIOD ,'' W_FROM ,'' W_TO 
                    from dual a;        
            return v_ret;    
    END GET_WAITING_PERIOD;

    FUNCTION GET_ONECLAIM_HISTORY(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_fleet IN NUMBER) RETURN  VARCHAR2 IS
        v_ret   VARCHAR2(30);
    BEGIN
 
        select min(clm_no) into v_ret
        from nc_mas a
        where a.prod_grp = '0' and a.prod_type in (select cgp.prod_type from clm_grp_prod cgp where sysid='GM')
        and pol_no = v_polno
        and pol_run = v_polrun and fleet_seq  = v_fleet
         ;            
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return null;
        WHEN OTHERS THEN
            return null;        
    END GET_ONECLAIM_HISTORY; 

    FUNCTION GET_MAJOR_SUMINS(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN NUMBER) RETURN  NUMBER IS 
        v_ret   number(20):=0;
        o_type  varchar2(5);
        sum_amt number(20);
    BEGIN
         misc.healthutil.get_pa_health_type(v_polno ,v_polrun ,o_type);  
             
         if o_type ='HG' then
            begin
                select nvl(max(sub_agr_amt) ,0)  into sum_amt
                from pa_gm_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan;            
            exception
                when no_data_found then
                    sum_amt := 0;
                when others then
                    sum_amt := 0;
            end;
            
            if sum_amt = 0 then
                begin
                    select nvl(max(max_amt) ,0)  into sum_amt
                    from pa_gm_ben a
                    where pol_no =v_polno and pol_run =v_polrun
                    and plan=v_plan;            
                exception
                    when no_data_found then
                        sum_amt := 0;
                    when others then
                        sum_amt := 0;
                end;
             end if;   
         elsif o_type = 'HI' then
            begin
                select  nvl(max(sub_agr_amt) ,0)  into sum_amt
                from pa_ph_ben a
                where pol_no =v_polno and pol_run =v_polrun
                and plan=v_plan;            
            exception
                when no_data_found then
                    sum_amt := 0;
                when others then
                    sum_amt := 0;
            end;     
            if sum_amt =0 then
                begin
                    select  nvl(max(max_amt) ,0)   into sum_amt
                    from pa_ph_ben a
                    where pol_no =v_polno and pol_run =v_polrun
                    and plan=v_plan;            
                exception
                    when no_data_found then
                        sum_amt := 0;
                    when others then
                        sum_amt := 0;
                end;                 
            end if;                   
         else
            sum_amt := 0;            
         end if;
         
         v_ret := sum_amt;
                 
        return v_ret;
    EXCEPTION
        WHEN OTHERS THEN
            v_ret := 0;
            return v_ret;
    END GET_MAJOR_SUMINS;
        
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


    FUNCTION GET_LIST_APPRVSTS(O_APPRVSTS_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 IS
        v_ret   varchar2(250);
        cnt_rec number(10);    
    BEGIN
            begin
                select count(*)  into cnt_rec
                from clm_constant a
                where key like 'PHSTSAPPRV%' 
                and nvl(exp_date ,trunc(sysdate)+1) > trunc(sysdate); 
            exception 
                when no_data_found then
                    cnt_rec := 0; 
                when others then
                    cnt_rec := 0; 
            end;

            if cnt_rec >0 then
            OPEN O_APPRVSTS_LIST For
                select key VALUE ,descr TEXT
                from clm_constant a
                where key like 'PHSTSAPPRV%'
                and nvl(exp_date ,trunc(sysdate)+1) > trunc(sysdate);
             end if;                   
       
         
             if cnt_rec = 0 then
                v_ret := 'not found list';
                open O_APPRVSTS_LIST for
                    select '' VALUE ,'' TEXT 
                    from dual;   
             end if;
             
             return v_ret;                  
    EXCEPTION
        WHEN OTHERS THEN
            v_ret := 'error:'||sqlerrm;
            open O_APPRVSTS_LIST for
                select '' VALUE ,'' TEXT 
                from dual;            
            return v_ret;    
    END GET_LIST_APPRVSTS;

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
        v_ret   VARCHAR2(250):='';
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
               
                save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION('benefit' ,'D'); --Status Detail
                save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION('benefit' ,'O'); -- Status Original
            else
                save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
                save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');            
            end if;
           
        elsif v_action = 'billing' then    
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');
        elsif v_action = 'benefit' then    
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');
        elsif v_action = 'ri_reserved' then    
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');
        elsif v_action = 'claim_info_paid' then    
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');            
        elsif v_action = 'payment' then    
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');    
        elsif v_action = 'payee' then    
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');    
        elsif v_action = 'ri_paid' then    
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');                            
        end if;
        
        dbms_output.put_line('save_NC_Status='||save_NC_Status||' save_Detail_Status='||save_Detail_Status);
        UPDATE NC_MAS
        SET clm_sts = save_NC_Status ,claim_status = save_Detail_Status
        WHERE CLM_NO = v_clmno;
        
        COMMIT;
        
        if v_action in ( 'payment' ,'payee' ) then -- check for Update Status Payment and Claim
            null;
        end if;
        
        p_ph_convert.CONV_TABLE(v_clmno ,v_payno ,null, v_ret) ;
        
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
        v_tot_res   number(12,4);
        v_tot_paid   number(12,4):=v_amt;
  
        v_riamt number(12,4);
        v_sumri number(12,4);
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
        
        begin 
            select count(ri_share)
            into ri_max_rec
            from nc_ri_reserved a
            where  clm_no= v_clmno
            and trn_seq = (select max(trn_seq) from nc_ri_reserved where clm_no = a.clm_no) 
            ;
        exception
            when no_data_found then
                ri_max_rec :=0;
            when others then
                ri_max_rec :=0;
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
        ri_res_sum  number(12,2);
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
            

    FUNCTION validate_RI_PAID(v_clmno IN VARCHAR2  ,v_payno IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret VARCHAR2(250):='';
        ri_mas_shr  number(5,2);
        ri_res_sum  number(12,2);
        v_maxpayno varchar2(20);
    BEGIN
        if v_payno is null then
            begin
                select max(pay_no) into v_maxpayno
                from nc_payment a
                where prod_grp = '0'
                and a.clm_no = v_clmno
                ;

            exception
             when no_data_found then
                 v_maxpayno := null;
            when others then
                v_maxpayno := null;
            end;        
        else
            v_maxpayno := v_payno;
        end if;
        
        begin 
            select nvl(sum(ri_share),0)
            into ri_mas_shr 
            from nc_ri_paid a
            where  clm_no= v_clmno and pay_no = v_maxpayno
            and trn_seq = (select max(trn_seq) from nc_ri_paid aa where aa.pay_no = a.pay_no) 
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
        end if;
        
        return v_ret;        
    EXCEPTION    
        WHEN OTHERS THEN 
        v_ret := 'error: '||sqlerrm;
        return v_ret;       
    END validate_RI_PAID;
            
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

    FUNCTION UPD_PAYMENTAPPRV(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2 
    ,v_apprv_flag IN varchar2 ,v_user IN varchar2 ,v_amd_user IN varchar2 ,v_apprv_user IN varchar2 ,v_res_amt IN NUMBER ,v_accum_amt IN NUMBER ,v_remark IN VARCHAR2 ,v_rst OUT VARCHAR2) RETURN VARCHAR2 IS
     v_max_seq number:=1;
     m_prodgrp varchar2(10);
     m_prodtype varchar2(10);
     m_curr_code varchar2(10);
     m_curr_rate number(5,2);
     dummy_payno varchar2(20);
     v_apprv_date date;
    BEGIN
        if v_accum_amt <= 0 then
            if v_sts in ('PHSTSAPPRV02' ,'PHSTSAPPRV05') then 
                v_rst := 'Cannot send amount 0 for approve payment ';
                return '0';
            end if;
        end if;
     
        if v_sts in ('PHSTSAPPRV03','PHSTSAPPRV04','PHSTSAPPRV06') then
        v_apprv_date := sysdate;
        else
        v_apprv_date := null;
        end if;
        BEGIN
            select nvl(max(trn_seq),0) + 1 into v_max_seq
            from nc_payment_apprv a
            where sts_key = v_key and pay_no = v_payno
            --and type = 'NCNATTYPECLM101' and sub_type = 'NCNATSUBTYPECLM101' 
            ;
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
        --m_curr_code := x1.curr_code;
        --m_curr_rate := x1.curr_rate; 
        END LOOP;
        
        BEGIN
            select nvl(curr_code,'BHT') ,nvl(curr_rate,1)  into m_curr_code ,m_curr_rate
            from nc_payee a
            where clm_no = v_clmno and pay_no = v_payno
            and a.trn_seq =  (select max(b.trn_seq) from nc_payee b where b.prod_grp ='0' and  b.clm_no = a.clm_no and b.pay_no = a.pay_no) 
            and rownum =1;
        exception
            when no_data_found then
                m_curr_code := 'BHT';
                m_curr_rate := 1;
            when others then
                m_curr_code := 'BHT';
                m_curr_rate := 1;
        END;        
        
        nc_health_package.save_ncmas_history(v_key ,v_rst); -- keep log
        
        if v_rst is not null then
            return '0';
        end if;
         
        INSERT into nc_payment_apprv(clm_no ,pay_no ,clm_seq ,trn_seq ,Pay_sts ,pay_amt ,Trn_amt ,Curr_code ,Curr_rate 
        ,Sts_date ,Amd_date ,Clm_men ,Amd_user, APPROVE_ID ,approve_date , Prod_grp ,Prod_type ,SUBSYSID ,Sts_key ,Sub_type ,Type ,apprv_flag ,remark) 
        VALUES (v_clmno , v_payno ,1 ,v_max_seq, v_sts ,v_res_amt ,v_accum_amt,
        m_curr_code, m_curr_rate ,sysdate ,sysdate ,v_user ,v_amd_user ,v_apprv_user ,v_apprv_date
        ,m_prodgrp,m_prodtype, 'PH' ,v_key ,'NCNATSUBTYPECLM101' ,'NCNATTYPECLM101' ,v_apprv_flag ,v_remark) ; 
        
        UPDATE NC_MAS
        SET APPROVE_STATUS = v_sts
        WHERE CLM_NO = v_clmno;
         
        COMMIT;
        
        
        if v_sts in ('PHSTSAPPRV03') then
            --Call Post ACC TMP
            IF not p_ph_convert.APPROVE_PAYMENT(v_key  ,v_clmno  ,v_payno ,v_sts ,v_apprv_user  ,v_remark ,v_rst) THEN
            
                return '0';
            END IF;
        end if; 
        --EMAIL_NOTICE_APPRV(v_clmno ,v_payno ,v_sts);
         
        return '1';
     
    EXCEPTION
     WHEN OTHERS THEN
     v_rst := 'error insert nc_payment_apprv:'||sqlerrm; 
     ROLLBACK;
     return '0'; 
    END UPD_PAYMENTAPPRV;

    FUNCTION IS_ADVANCE_POLICY(v_polno IN VARCHAR2 ,v_polrun IN NUMBER) RETURN VARCHAR2 IS -- 0=false ,1=true
        v_ret   VARCHAR2(1):='0';
        v_pol     VARCHAR2(25);
    BEGIN

        select remark||remark2 into v_pol
        from clm_constant
        where key like 'PHPOLADV%' 
        and nvl (exp_date, trunc (sysdate)) >= trunc (sysdate)
        and remark = v_polno and remark2 = v_polrun;        
        
        if v_pol is null then
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
    END IS_ADVANCE_POLICY;          

    FUNCTION CAN_SEND_APPROVE(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 IS
     v_f1 varchar2(20):=null;
     v_return varchar2(10);
    BEGIN
     begin
         select pay_sts into v_f1
         from nc_payment_apprv xxx
         where 
         xxx.clm_no = v_clmno and pay_no = v_payno and 
         xxx.pay_sts in ('PHSTSAPPRV02','PHSTSAPPRV05') and  
--         and type = '01' and sub_type = '01' and 
         xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no
--         and type = '01' and sub_type = '01' 
         );
         o_rst := 'งานอยู่ระหว่างรอการอนุมัติ' ; 
         v_return := 'N'; 
     exception
         when no_data_found then
             v_f1 := null;
             v_return := 'Y';
        when others then
             dbms_output.put_line('error'||sqlerrm);
             o_rst := 'error'||sqlerrm ; 
             v_return := 'N';
     end;
     
     if v_f1 is null then
         begin
             select pay_sts into v_f1
             from nc_payment_apprv xxx
             where 
             xxx.clm_no = v_clmno and pay_no = v_payno and 
             xxx.pay_sts in ('PHSTSAPPRV03','PHSTSAPPRV11','PHSTSAPPRV12') and 
--             type = '01' and sub_type = '01' and 
             xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no
--             and type = '01' and sub_type = '01' 
             );
             o_rst := 'งานอนุมัติไปแล้ว' ;              
             v_return := 'N';
         exception
             when no_data_found then
                 v_f1 := null;
                 v_return := 'Y';
             when others then
                 dbms_output.put_line('error'||sqlerrm);
                 o_rst := 'error'||sqlerrm ; 
                 v_return := 'N';
         end; 
     end if;
     
    -- o_rst := null;
     return v_return;
    END CAN_SEND_APPROVE; 

    FUNCTION CAN_GO_APPROVE(i_clmno IN varchar2 ,i_payno IN varchar2 ,i_userid IN varchar2 ,i_status IN varchar2 ,i_sys IN VARCHAR2 ,o_rst OUT varchar2) RETURN VARCHAR2 IS
        v_return varchar2(1):='Y';
        v_apprv_id varchar2(10);
        v_sts varchar2(20);
        v_found varchar2(20);
        v_apprv_amt    NUMBER;
             
        c1   NMTR_PACKAGE.v_ref_cursor2;  
        TYPE t_data1 IS RECORD
        (
        SUBSYSID varchar2(5)  ,
        USER_ID  varchar2(5) ,
        NAME varchar2(200) ,
        MIN_LIMIT number,
        MAX_LIMIT number,
        APPROVE_FLAG varchar2(1)
        ); 
        j_rec1 t_data1;       
    BEGIN

         BEGIN
             select key into v_found
             from clm_constant a
             where key like 'PHSTSAPPRV%'
             and key = i_status
             and (remark2 = 'APPRV')
             ;
         EXCEPTION
             WHEN NO_DATA_FOUND THEN
                v_found := null;
             WHEN OTHERS THEN
                v_found := null;
         END; 
         
         IF v_found is not null THEN
             o_rst := 'เคลมนี้อนุมัติไปแล้ว !';
             v_return := 'N';
         END IF;
         
         IF v_return = 'Y' THEN
         
            BEGIN
                 select key into v_found
                 from clm_constant a
                 where key like 'PHSTSAPPRV%'
                 and key = i_status
                 and (remark2 is null)
                 ;
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
                v_found := null;
             WHEN OTHERS THEN
                v_found := null;
            END; 

             IF v_found is not null THEN
                 ALLCLM.P_NON_PA_APPROVE.GET_APPROVE_USER(i_clmno ,i_payno ,v_apprv_id ,v_sts );
                 IF v_apprv_id <> i_userid THEN
                     o_rst := 'งานนี้เป็นของรหัส '||v_apprv_id ||' เป็นผู้อนุมัติ !';
                     v_return :=  'N'; 
                 ELSE
                    o_rst := null;
                    v_return :=  'Y';    
                    return v_return;                 
                 END IF;
             END IF;                             

         END IF;
         
         IF v_return ='Y' THEN -- Check Limit
            v_apprv_amt := P_PH_CLM.GET_APPROVE_AMT(i_clmno ,i_payno);
            NMTR_PACKAGE.NC_WAIT_FOR_APPROVE2 (i_userid , i_sys ,v_apprv_amt,
                                                  c1 );            
            v_return :=  'N'; 
            o_rst := 'รหัส '||i_userid||' ไม่มีสิทธิอนุมัติ !';                                      
            LOOP
            FETCH  c1 INTO j_rec1;
            EXIT WHEN c1%NOTFOUND;
                dbms_output.put_line('User==>'|| 
                 j_rec1.user_id||
                 ':'||
                 j_rec1.NAME||
                 'MIN:'||
                  j_rec1.MIN_LIMIT||
                  '    MAX:'||
                   j_rec1.MAX_LIMIT||
                   '       FLAG:'||
                    j_rec1.APPROVE_FLAG
                );    
                if j_rec1.APPROVE_FLAG = 'Y' and j_rec1.user_id = i_userid then
                    dbms_output.put_line('Yes!!!');
                    o_rst := null;
                    v_return :=  'Y'; 
                end if;
            end loop;                                                          
         END IF;         
         
    -- o_rst := null;
        return v_return;
    END CAN_GO_APPROVE;

    FUNCTION GET_APPROVE_AMT(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN NUMBER IS
        v_ret   NUMBER:=9999999999;
    BEGIN
        select nvl(sum(payee_amt),9999999999) into v_ret
        from nc_payee a
        where payee_code is not null
        and prod_grp ='0'
        and clm_no =v_clmno and pay_no = v_payno
        and a.trn_seq = (select max(b.trn_seq) from nc_payee b where b.prod_grp ='0' and  b.clm_no = a.clm_no and b.pay_no = a.pay_no) ;    
        
        return v_ret;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return v_ret;
        WHEN OTHERS THEN
            return v_ret;
    END GET_APPROVE_AMT;

    FUNCTION IS_NEW_PAYMENT(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 IS
     v_paysts varchar2(20):=null;
     v_maxpayno    varchar2(20):=null;
     v_sum_payment number:=0;
     v_sum_payee number:=0;
     v_return varchar2(10):='Y';
    BEGIN
        begin
            select max(pay_no) into v_maxpayno
            from nc_payment a
            where prod_grp = '0'
            and a.clm_no = v_clmno
            ;

        exception
         when no_data_found then
             v_maxpayno := null;
        when others then
            v_maxpayno := null;
        end;

        begin
            select nvl(max(payee_amt),0) into v_sum_payee
            from nc_payee a
            where prod_grp = '0'
            and clm_no = v_clmno and pay_no = v_maxpayno
            and a.trn_seq in (select max(bb.trn_seq) from nc_payee bb where bb.pay_no = a.pay_no)
            ;

        exception
         when no_data_found then
             v_sum_payee := 0;
        when others then
            v_sum_payee := 0;
        end;
                    
        begin
            select nvl(sum(pay_amt),0) ,max(status) into v_sum_payment ,v_paysts
            from nc_payment a
            where prod_grp = '0'
            and type = 'NCNATTYPECLM101' 
            and a.trn_seq in (select max(bb.trn_seq) from nc_payment bb where bb.clm_no = a.clm_no and  bb.pay_no = a.pay_no)
            and a.clm_no = v_clmno and a.pay_no = v_maxpayno
            ;
            
            if v_paysts = 'NCPAYMENTSTS04' and v_sum_payment = 0 and v_sum_payee = 0  then -- Cancel Payment
                o_rst := 'last payno was canceled';
                v_return := 'Y';                
            elsif  v_sum_payment > 0 then
                o_rst := 'payment > 0';
                v_return := 'N';        
            elsif    v_sum_payee > 0 then
                o_rst := 'payee > 0';
                v_return := 'N';   
            else
                o_rst := 'not found status or payment';
                v_return := 'Y';                  
            end if;
            
        exception
            when no_data_found then
                o_rst := 'not found payment';
                v_return := 'Y';  
            when others then
                o_rst := 'not found payment';
                v_return := 'Y';  
        end;
        
        return v_return;
    END IS_NEW_PAYMENT; 

    FUNCTION GEN_RI_PAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2 ,v_amt IN NUMBER  ,o_rst OUT varchar2) RETURN VARCHAR2 IS

         v_return varchar2(10):='Y';
         v_date date:=sysdate;
         v_status   varchar2(20);
        ri_mas_shr  number(5,2);
        ri_max_rec  number(2);
        v_tot_res   number(12,4);
        v_tot_paid   number(12,4):=v_amt;
  
        v_riamt number(12,4);
        v_sumri number(12,4);  
        r_cnt   number;        
    BEGIN
        begin
            select count(*) into ri_max_rec
            from nc_ri_paid a
            where prod_grp = '0'
            and clm_no = v_clmno and pay_no = v_payno 
            and trn_seq in (select max(aa.trn_seq) from nc_ri_paid aa where aa.pay_no = a.pay_no )
            ;

        exception
         when no_data_found then
             ri_max_rec := 0;
        when others then
            ri_max_rec := 0;
        end;
        
        if ri_max_rec = 0  then
            o_rst := 'ไม่พบข้อมูล RI Paid';
            return 'N';
        end if;
        
        begin
            v_status := P_PH_CLM.GET_MAPPING_ACTION('benefit' ,'O');
            
            r_cnt :=0;
            v_sumri :=0;        
            for x in (
                select sts_key, clm_no, pay_no, prod_grp, prod_type, type, ri_code, ri_br_code, ri_type, ri_lf_flag, ri_sub_type, ri_share
                , trn_seq, ri_sts_date, ri_amd_date, ri_pay_amt, ri_trn_amt, lett_type, sub_type
                ,status ,lett_no ,lett_prt
                from nc_ri_paid a
                where prod_grp = '0'
                and clm_no = v_clmno and pay_no = v_payno 
                and trn_seq in (select max(aa.trn_seq) from nc_ri_paid aa where aa.pay_no = a.pay_no )            
            )loop
                v_riamt :=0;
                r_cnt := r_cnt+1;
                if r_cnt = ri_max_rec then
                    v_riamt := v_tot_paid-v_sumri;
                else
                    v_riamt := v_tot_paid * (x.ri_share/100);    
                end if;
                v_riamt := trunc(v_riamt ,2);
                v_sumri := v_sumri + v_riamt;
                
                Insert into NC_RI_PAID
                   (STS_KEY, CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_SHARE
                   , TRN_SEQ, RI_STS_DATE, RI_AMD_DATE, RI_PAY_AMT, RI_TRN_AMT, LETT_TYPE, SUB_TYPE
                   ,STATUS ,LETT_NO ,LETT_PRT)
                 Values
                   (x.STS_KEY, x.CLM_NO, x.PAY_NO, x.PROD_GRP, x.PROD_TYPE, x.TYPE, x.RI_CODE, x.RI_BR_CODE, x.RI_TYPE, x.RI_LF_FLAG, x.RI_SUB_TYPE, x.RI_SHARE
                   , x.TRN_SEQ+1, x.RI_STS_DATE, v_date , v_riamt , v_riamt , x.LETT_TYPE, x.SUB_TYPE
                   ,v_status ,x.LETT_NO ,x.LETT_PRT);            
                   
            end loop  ;  
        exception
            when others then
                o_rst := 'error insert nc_ri_paid';
                v_return := 'N';  
        end;
        
        return v_return;
    END GEN_RI_PAID; 

    FUNCTION  get_SUM_RES(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN NUMBER IS
        v_ret NUMBER(12,2);
        sum_res  number(12,2);
        --ri_res_sum  number(12,2);
        v_maxpayno varchar2(20);
    BEGIN
        
        begin 
            select nvl(sum(res_amt),0)
            into sum_res 
            from nc_reserved a
            where  clm_no= v_clmno 
            and trn_seq = (select max(trn_seq) from nc_reserved aa where aa.clm_no = a.clm_no) 
            ;
        exception
            when no_data_found then
                sum_res :=0;
            when others then
                sum_res :=0;
        end;          
        v_ret := sum_res;
        return v_ret;        
    EXCEPTION    
        WHEN OTHERS THEN 
        v_ret := 0;
        return v_ret;       
    END get_SUM_RES;

    FUNCTION  get_SUM_RIPAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN NUMBER IS
        v_ret NUMBER(12,2);
        ri_pay  number(12,2);
        --ri_res_sum  number(12,2);
        v_maxpayno varchar2(20);
    BEGIN
        if v_payno is null then
            begin
                select max(pay_no) into v_maxpayno
                from nc_payment a
                where prod_grp = '0'
                and a.clm_no = v_clmno
                ;

            exception
             when no_data_found then
                 v_maxpayno := null;
            when others then
                v_maxpayno := null;
            end;        
        else
            v_maxpayno := v_payno;
        end if;
        
        begin 
            select nvl(sum(ri_pay_amt),0)
            into ri_pay 
            from nc_ri_paid a
            where  clm_no= v_clmno and pay_no = v_maxpayno
            and trn_seq = (select max(trn_seq) from nc_ri_paid aa where aa.pay_no = a.pay_no) 
            ;
        exception
            when no_data_found then
                ri_pay :=0;
            when others then
                ri_pay :=0;
        end;          
        v_ret := ri_pay;
        return v_ret;        
    EXCEPTION    
        WHEN OTHERS THEN 
        v_ret := 0;
        return v_ret;       
    END get_SUM_RIPAID;

    FUNCTION  get_SUM_PAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN NUMBER IS
        v_ret NUMBER(12,2);
        sum_pay  number(12,2);
        --ri_res_sum  number(12,2);
        v_maxpayno varchar2(20);
    BEGIN
        if v_payno is null then
            begin
                select max(pay_no) into v_maxpayno
                from nc_payment a
                where prod_grp = '0'
                and a.clm_no = v_clmno
                ;

            exception
             when no_data_found then
                 v_maxpayno := null;
            when others then
                v_maxpayno := null;
            end;        
        else
            v_maxpayno := v_payno;
        end if;
        
        begin 
            select nvl(sum(pay_amt),0)
            into sum_pay 
            from nc_payment a
            where  clm_no= v_clmno and pay_no = v_maxpayno
            and trn_seq = (select max(trn_seq) from nc_payment aa where aa.pay_no = a.pay_no) 
            ;
        exception
            when no_data_found then
                sum_pay :=0;
            when others then
                sum_pay :=0;
        end;          
        v_ret := sum_pay;
        return v_ret;        
    EXCEPTION    
        WHEN OTHERS THEN 
        v_ret := 0;
        return v_ret;       
    END get_SUM_PAID;
                        


    FUNCTION  get_SUM_PAYEE(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN NUMBER IS
        v_ret NUMBER(12,2);
        sum_pay  number(12,2);
        --ri_res_sum  number(12,2);
        v_maxpayno varchar2(20);
    BEGIN
        if v_payno is null then
            begin
                select max(pay_no) into v_maxpayno
                from nc_payee a
                where prod_grp = '0'
                and a.clm_no = v_clmno
                ;

            exception
             when no_data_found then
                 v_maxpayno := null;
            when others then
                v_maxpayno := null;
            end;        
        else
            v_maxpayno := v_payno;
        end if;
        
        begin 
            select nvl(sum(payee_amt),0)
            into sum_pay 
            from nc_payee a
            where  clm_no= v_clmno and pay_no = v_maxpayno
            and trn_seq = (select max(trn_seq) from nc_payee aa where aa.pay_no = a.pay_no) 
            ;
        exception
            when no_data_found then
                sum_pay :=0;
            when others then
                sum_pay :=0;
        end;          
        v_ret := sum_pay;
        return v_ret;        
    EXCEPTION    
        WHEN OTHERS THEN 
        v_ret := 0;
        return v_ret;       
    END get_SUM_PAYEE;
                        
    FUNCTION  get_PAYEENAME(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret VARCHAR2(250);
        sum_pay  number(12,2);
        --ri_res_sum  number(12,2);
        v_maxpayno varchar2(20);
    BEGIN
        if v_payno is null then
            begin
                select max(pay_no) into v_maxpayno
                from nc_payment a
                where prod_grp = '0'
                and a.clm_no = v_clmno
                ;

            exception
             when no_data_found then
                 v_maxpayno := null;
            when others then
                v_maxpayno := null;
            end;        
        else
            v_maxpayno := v_payno;
        end if;
        
        begin 
            select payee_name
            into v_ret 
            from nc_payee a
            where  clm_no= v_clmno and pay_no = v_maxpayno
            and trn_seq = (select max(trn_seq) from nc_payee aa where aa.pay_no = a.pay_no) 
            and rownum=1
            ;
        exception
            when no_data_found then
                v_ret :=null;
            when others then
                v_ret :=null;
        end;          

        return v_ret;        
    EXCEPTION    
        WHEN OTHERS THEN 
        v_ret :=null;
        return v_ret;       
    END get_PAYEENAME;
                        

    FUNCTION UPD_PAYMENT_STS(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,v_status IN VARCHAR2 ,o_rst OUT varchar2) RETURN VARCHAR2 IS
        chk_sts varchar2(20);
        v_return varchar2(2):='Y';
    BEGIN
        begin
            select key into chk_sts
            from clm_constant
            where key = v_status ;
        exception
         when no_data_found then
             chk_sts := null;
        when others then
            chk_sts := null;
        end;
        
        if chk_sts is null  then
            o_rst := 'ไม่พบ '||v_status||' ในระบบ';
            return 'N';
        end if;
        
        begin
            update nc_payment a
            set status = v_status
            where prod_grp = '0'
            and a.clm_no = v_clmno and pay_no = v_payno
            and a.trn_seq in (select max(bb.trn_seq) from nc_payment bb where bb.pay_no = a.pay_no)  ;
            
            commit;
        exception
            when others then
                rollback;
                o_rst := 'error update nc_payment';
                v_return := 'N';  
        end;
        
        
        return v_return;
    END UPD_PAYMENT_STS; 

    FUNCTION CAN_UPDATE_PAYMENT(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 IS
        v_sumres    number;
        v_return varchar2(10):='Y';
        v_maxpayno varchar2(20);
    BEGIN
        if v_payno is null then
            begin
                select max(pay_no) into v_maxpayno
                from nc_payment a
                where prod_grp = '0'
                and a.clm_no = v_clmno
                ;

            exception
             when no_data_found then
                 v_maxpayno := null;
            when others then
                v_maxpayno := null;
            end;        
        else
            v_maxpayno := v_payno;
        end if;
        v_return := P_PH_CLM.CAN_SEND_APPROVE(v_clmno ,v_maxpayno ,o_rst) ;
        
        if v_return = 'Y' then -- เช็ค Claim Status เพิ่ม 
            begin
                select sum(res_amt) into v_sumres
                from nc_reserved a
                where a.clm_no =v_clmno
                and a.prod_grp = '0' --and a.prod_type in (select cgp.prod_type from clm_grp_prod cgp where sysid='GM')
                and a.trn_seq in (select max(bb.trn_seq) from nc_reserved bb where bb.clm_no = a.clm_no);      

            exception
             when no_data_found then
                 v_sumres := 0;
            when others then
                v_sumres := 0;
            end;        
            
            if v_sumres <= 0 then
                o_rst := 'ยอด Reserved <= 0';
                v_return := 'N';
            end if ;
        end if;
        
        return v_return;
    END CAN_UPDATE_PAYMENT; 

    FUNCTION GET_CLAIM_STATUS(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2 ,v_mode IN VARCHAR2 ) RETURN VARCHAR2 IS
        v_return varchar2(20);
    BEGIN
        if nvl(v_mode,'C') = 'C' then
            begin
                select claim_status into v_return
                from nc_mas a
                where a.clm_no =v_clmno
                and a.prod_grp = '0'   ;    

            exception
             when no_data_found then
                 v_return := null;
            when others then
                v_return := null;
            end;              
        else
            begin
                select approve_status into v_return
                from nc_mas a
                where a.clm_no =v_clmno
                and a.prod_grp = '0'   ;    

            exception
             when no_data_found then
                 v_return := null;
            when others then
                v_return := null;
            end;               
        end if;
  
                    
        return v_return;
    END GET_CLAIM_STATUS; 

    FUNCTION GET_USER_LIST (v_user IN VARCHAR2 ,O_USER Out P_PH_CLM.v_curr ) RETURN VARCHAR2 IS  
        v_ret varchar2(250);
        cnt_rec number(10);
    BEGIN
        begin
        select nvl(count(*),0) into cnt_rec
        from bkiuser a
        where dept_id = '22'
        and div_id = '03'
        and user_id like nvl(UPPER(v_user),'%')
        and termination_flag is null ;
        exception
            when no_data_found then
                cnt_rec := 0;
            when others then
                cnt_rec := 0;
        end;
        
        if cnt_rec >0 then
           OPEN O_USER  FOR 
                select user_id VALUE , 'คุณ '||name_t TEXT
                from bkiuser a
                where dept_id = '22'
                and div_id = '03'
                and user_id like nvl(UPPER(v_user),'%')
                and termination_flag is null 
                order by team_id desc ,user_id ;            
        else
            v_ret := 'Not found User';
            OPEN O_USER  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;             
        end if;
   
                 
        return v_ret;       

    EXCEPTION
           when no_data_found then 
            v_ret := 'Not found ';
            OPEN O_USER  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;           
   
           when others then 
            v_ret := 'error: '||sqlerrm;
            OPEN O_USER  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;  
                      
    END GET_USER_LIST;   

   FUNCTION GET_PAID_TO(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2 ) RETURN VARCHAR2 IS
        v_return varchar2(20);
        v_type  varchar2(20);
    BEGIN
        begin
            select clm_type into v_type
            from nc_mas a
            where a.clm_no =v_clmno
            and a.prod_grp = '0'   ;    
            if v_type = 'PHCLMTYPE02' then -- Credit
                v_return := 'H';
            else
                v_return := null;
            end if;
        exception
         when no_data_found then
             v_type := null;
        when others then
            v_type := null;
        end;              
                    
        return v_return;
    END GET_PAID_TO; 


   PROCEDURE GET_HOSP_PAYEE(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2 ,o_payee_code OUT VARCHAR2 ,o_payee_seq OUT VARCHAR2) IS
        --v_paye varchar2(20);
        v_type  varchar2(20);
        --v_seq    varchar2(5);
    BEGIN
        begin
            select hpt_code into v_type 
            from nc_mas a
            where a.clm_no =v_clmno
            and a.prod_grp = '0'   ;    

        exception
         when no_data_found then
             v_type := null;
        when others then
            v_type := null;
        end;            
        
        if v_type is not null then
        begin
            select payee_code ,hosp_seq into o_payee_code ,o_payee_seq
            from med_hospital_list a
            where a.hosp_id =v_type and rownum=1;    

        exception
         when no_data_found then
             o_payee_code := null;
        when others then
            o_payee_code := null;
        end;           
        end if;  
                    
    END GET_HOSP_PAYEE; 

    PROCEDURE GET_PAYEE_ACC(v_clmno IN VARCHAR2 ,v_payee IN VARCHAR2 
    ,O_ACC_NO  OUT VARCHAR2, O_ACC_NAME_TH OUT VARCHAR2,  O_ACC_NAME_EN  OUT VARCHAR2, O_BANK_CODE  OUT VARCHAR2, O_BANK_BR_CODE  OUT VARCHAR2, O_DEPOSIT OUT VARCHAR2 ) IS
    
    BEGIN
      --== = get new ACC_NO ==
      account.p_actr_package.p_get_payee_acc(v_payee,
                                             'A', /* fix A = ACR type */
                                             O_ACC_NO,
                                             O_ACC_NAME_TH,
                                             O_ACC_NAME_EN,
                                             O_BANK_CODE,
                                             O_BANK_BR_CODE,
                                             O_DEPOSIT);
      if O_ACC_NAME_TH is null then
          O_ACC_NAME_TH := O_ACC_NAME_EN;    
      end if;   
      -- == == = = = = = = =  = =    
    EXCEPTION
        WHEN OTHERS THEN
        O_ACC_NO  := null; O_ACC_NAME_TH := null;  O_ACC_NAME_EN  := null; O_BANK_CODE  := null; O_BANK_BR_CODE  := null; O_DEPOSIT := null; 
    END GET_PAYEE_ACC ;
    
    PROCEDURE GET_PAYEE_DETAIL(v_clmno IN VARCHAR2 ,v_payee IN VARCHAR2 ,v_payee_seq IN VARCHAR2 
     , o_contact_name OUT VARCHAR2 , o_addr1 OUT VARCHAR2  , o_addr2 OUT VARCHAR2  , o_mobile OUT VARCHAR2  , o_email OUT VARCHAR2
     ,o_agent_mobile  OUT VARCHAR2 ,o_agent_email  OUT VARCHAR2) IS
     
    BEGIN
        NC_HEALTH_PAID.GET_HOSPITAL_CONTACT(v_payee ,v_payee_seq ,null , o_contact_name ,o_addr1  ,o_addr2  , o_mobile ,o_email);
        --:clm_gm_payee.CUST_MAIL := NC_HEALTH_PAID.GET_ORG_CUSTOMER_EMAIL(:clm_gm_payee.CLM_NO);
        if o_email is null then o_email := NC_HEALTH_PAID.GET_ORG_CUSTOMER_EMAIL(v_clmno); end if;

        IF NC_HEALTH_PAID.IS_AGENT_CHANNEL(v_clmno ,v_payee) THEN
            NC_HEALTH_PAID.GET_AGENT_CONTACT (v_clmno , o_contact_name ,o_addr1  ,o_addr2 
            , o_agent_mobile ,o_agent_email );           
        END IF;
    EXCEPTION
        WHEN OTHERS THEN     
        o_contact_name := null;  o_addr1 := null;  o_addr2 := null;  o_mobile := null;  o_email := null; o_agent_mobile := null; o_agent_email := null;
     END GET_PAYEE_DETAIL ;
                                             
END P_PH_CLM;

/