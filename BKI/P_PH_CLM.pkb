CREATE OR REPLACE PACKAGE BODY ALLCLM.P_PH_CLM AS
/******************************************************************************
   NAME:       P_PH_CLM
   PURPOSE:     ����Ѻ Projetc PH system


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
        IF length(v_code) = 1 THEN
            if v_code = '0' then
                return 'Open';
            elsif v_code = '1' then
                return 'Open';
            elsif v_code = '6' then
                return 'Draft';
            elsif v_code = '3' then
                return 'Cwp';
            elsif v_code = '2' then
                return 'Close';
            else
                return null;
            end if;
        END IF;

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

    FUNCTION GET_CLMPDFLAG(v_code IN VARCHAR2) RETURN VARCHAR2 IS
        v_type    varchar2(5);
    BEGIN
        select clm_pd_flag into v_type
        from medical_ben_std
        where bene_code = v_code and th_eng='T'
        ;
        return v_type;
    EXCEPTION
        when no_data_found then return '' ;
        when others then return '' ;
    END GET_CLMPDFLAG;

    FUNCTION MAPP_BENECODE(v_bill IN VARCHAR2 ,v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2) RETURN VARCHAR2 IS
        o_type  varchar2(5);
        ret_bene    varchar2(10);
        is_opd  varchar2(5):='%';
        bill_descr  varchar2(200);
    BEGIN
         misc.healthutil.get_pa_health_type(v_polno ,v_polrun ,o_type);

         begin
            select descr_th into bill_descr
            from nc_billing_std
            where code = v_bill and descr_th like '%���¹͡%' ;
            if bill_descr is not null then is_opd := 'O'; end if;
        exception
            when no_data_found then
                bill_descr := null;
            when others then
                bill_descr := null;
        end;


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
                ) and pd_flag like is_opd
                and rownum=1;
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
                )  and pd_flag like is_opd
                and rownum=1;
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


    FUNCTION MAPP_BENECODE(v_bill IN VARCHAR2 ,v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_flag IN VARCHAR2) RETURN VARCHAR2 IS
        o_type  varchar2(5);
        ret_bene    varchar2(10);
        is_opd  varchar2(5):='%';
        bill_descr  varchar2(200);
        txt_daysur  varchar2(200):= '%��ҵѴ%����ͧ�ѡ%';
        txt_room    varchar2(200):='%�����ͧ%';
        txt_meal    varchar2(200):='%��������%';
        bill_type   varchar2(5);
    BEGIN
        bill_type := substr(v_bill,1,3);
         misc.healthutil.get_pa_health_type(v_polno ,v_polrun ,o_type);
        /*
        2.1.x   �����ͧ
        2.3.x   ��������    
         */
         begin
            select descr_th into bill_descr
            from nc_billing_std
            where code = v_bill and descr_th like '%���¹͡%' ;
            if bill_descr is not null then is_opd := 'O'; end if;
        exception
            when no_data_found then
                bill_descr := null;
            when others then
                bill_descr := null;
        end;

        if v_flag = 'PHADMTYPE01' then   is_opd := 'O'; end if;

         if o_type ='HG' then
            begin
                if v_flag = 'PHADMTYPE03' then -- Day Surg.
                    select a.bene_code  into ret_bene
                    from pa_gm_ben a ,medical_ben_std b
                    where a.bene_code = b.bene_code
                    and b.th_eng ='T'
                    and pol_no =v_polno and pol_run =v_polrun
                    and plan=v_plan
                    and a.bene_code in (
                        select x.bene_code
                        from nc_billing_mapp x
                        where x.cancel is null
                        and x.bill_code = v_bill
                    ) and a.pd_flag like is_opd
                    and descr not like TXT_DAYSUR
                    and rownum=1;                
                else
                    if bill_type = '2.1' then   -- ��ͧ
                        select a.bene_code  into ret_bene
                        from pa_gm_ben a ,medical_ben_std b
                        where a.bene_code = b.bene_code
                        and b.th_eng ='T'
                        and pol_no =v_polno and pol_run =v_polrun
                        and plan=v_plan
                        and a.bene_code in (
                            select x.bene_code
                            from nc_billing_mapp x
                            where x.cancel is null
                            and x.bill_code = v_bill
                        ) and a.pd_flag like is_opd
                        and descr like TXT_ROOM
                        and rownum=1;                       
                    elsif bill_type = '2.3' then    --�����
                        select a.bene_code  into ret_bene
                        from pa_gm_ben a ,medical_ben_std b
                        where a.bene_code = b.bene_code
                        and b.th_eng ='T'
                        and pol_no =v_polno and pol_run =v_polrun
                        and plan=v_plan
                        and a.bene_code in (
                            select x.bene_code
                            from nc_billing_mapp x
                            where x.cancel is null
                            and x.bill_code = v_bill
                        ) and a.pd_flag like is_opd
                        and descr like TXT_MEAL
                        and rownum=1;                          
                    else
                        select a.bene_code  into ret_bene
                        from pa_gm_ben a ,medical_ben_std b
                        where a.bene_code = b.bene_code
                        and b.th_eng ='T'
                        and pol_no =v_polno and pol_run =v_polrun
                        and plan=v_plan
                        and a.bene_code in (
                            select x.bene_code
                            from nc_billing_mapp x
                            where x.cancel is null
                            and x.bill_code = v_bill
                        ) and a.pd_flag like is_opd
                        --and descr like TXT_MEAL
                        and rownum=1;                      
                    end if;
                end if;
            exception
                when no_data_found then
                    ret_bene := null;
                when others then
                    ret_bene := null;
            end;
         elsif o_type = 'HI' then
            begin
                if v_flag = 'PHADMTYPE03' then -- Day Surg.
                    select a.bene_code  into ret_bene
                    from pa_ph_ben a ,medical_ben_std b
                    where a.bene_code = b.bene_code
                    and b.th_eng ='T'
                    and pol_no =v_polno and pol_run =v_polrun
                    and plan=v_plan
                    and a.bene_code in (
                        select x.bene_code
                        from nc_billing_mapp x
                        where x.cancel is null
                        and x.bill_code = v_bill
                    ) and a.pd_flag like is_opd
                    and descr not like TXT_DAYSUR
                    and rownum=1;                
                else
                    if bill_type = '2.1' then   -- ��ͧ
                        select a.bene_code  into ret_bene
                        from pa_ph_ben a ,medical_ben_std b
                        where a.bene_code = b.bene_code
                        and b.th_eng ='T'
                        and pol_no =v_polno and pol_run =v_polrun
                        and plan=v_plan
                        and a.bene_code in (
                            select x.bene_code
                            from nc_billing_mapp x
                            where x.cancel is null
                            and x.bill_code = v_bill
                        ) and a.pd_flag like is_opd
                        and descr like TXT_ROOM
                        and rownum=1;                       
                    elsif bill_type = '2.3' then    --�����
                        select a.bene_code  into ret_bene
                        from pa_ph_ben a ,medical_ben_std b
                        where a.bene_code = b.bene_code
                        and b.th_eng ='T'
                        and pol_no =v_polno and pol_run =v_polrun
                        and plan=v_plan
                        and a.bene_code in (
                            select x.bene_code
                            from nc_billing_mapp x
                            where x.cancel is null
                            and x.bill_code = v_bill
                        ) and a.pd_flag like is_opd
                        and descr like TXT_MEAL
                        and rownum=1;                          
                    else
                        select a.bene_code  into ret_bene
                        from pa_ph_ben a ,medical_ben_std b
                        where a.bene_code = b.bene_code
                        and b.th_eng ='T'
                        and pol_no =v_polno and pol_run =v_polrun
                        and plan=v_plan
                        and a.bene_code in (
                            select x.bene_code
                            from nc_billing_mapp x
                            where x.cancel is null
                            and x.bill_code = v_bill
                        ) and a.pd_flag like is_opd
                        --and descr like TXT_MEAL
                        and rownum=1;                      
                    end if;
                end if;
            
--                select a.bene_code  into ret_bene
--                from pa_ph_ben a
--                where pol_no =v_polno and pol_run =v_polrun
--                and plan=v_plan
--                and a.bene_code in (
--                    select x.bene_code
--                    from nc_billing_mapp x
--                    where x.cancel is null
--                    and x.bill_code = v_bill
--                )  and pd_flag like is_opd
--                and rownum=1;
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

    FUNCTION CONV_BENEFIT(v_clmno IN VARCHAR2  ,v_user IN VARCHAR2 ,O_RST OUT VARCHAR2) RETURN VARCHAR2 IS -- Y ,N
        v_ret varchar2(10):= 'Y';
        cnt_nullBene    number(3);
        v_clmsts    varchar2(20);   v_clmsts_descr    varchar2(200);
        v_maxSeq    number:=0;
        cnt_prem_seq    number(3):=0;
        v_sysdate date:=sysdate;
        v_rst   varchar2(250);
    BEGIN
        begin
            select count(*) into cnt_nullBene
            from nc_billing a
            where clm_no = v_clmno
            and trn_seq in (select max(aa.trn_seq) from nc_billing aa where aa.clm_no = a.clm_no)
            and mapp_bene is null;
        exception
            when no_data_found then
                cnt_nullBene := 0;
            when others then
                cnt_nullBene := 0;
        end;

        if cnt_nullBene >0 then
            O_RST := '�պ�źҧ��¡���ѧ����к� Benefit';
            return 'N';
        end if;

        begin
            select p_pH_clm.GET_CLAIM_STATUS( clm_no ,'' ,'C' ) into v_clmsts
            from nc_mas a
            where clm_no = v_clmno ;
        exception
            when no_data_found then
                v_clmsts := null;
            when others then
                v_clmsts := null;
        end;

        if v_clmsts not in ('PHCLMSTS40','PHCLMSTS01') then
            v_clmsts_descr := p_ph_clm.GET_CLMSTS_DESCR(v_clmsts) ;
            O_RST := '��� '||v_clmno||' �����ʶҹ� '||v_clmsts_descr||' �������ö Convert Billing to Benefit ���ӡ�� Cancel->ReOpen ��͹';
            return 'N';
        end if;

        begin
            select nvl(max(trn_seq),0) into v_maxSeq
            from nc_reserved a
            where a.clm_no = v_clmno
            and a.prod_grp = '0' and a.prod_type in (select cgp.prod_type from clm_grp_prod cgp where sysid='GM')  ;
        exception
            when no_data_found then
                v_maxSeq := 0;
            when others then
                v_maxSeq := 0;
        end;

        FOR Mas in (
            select sts_key, prod_grp, prod_type
            from nc_mas
            where clm_no = v_clmno
        )LOOP
            FOR x in (
                select mapp_bene , sum(net_amt) net_amt
                from nc_billing a
                where clm_no = v_clmno
                and trn_seq in (select max(aa.trn_seq) from nc_billing aa where aa.clm_no = a.clm_no)
                group by mapp_bene
            )LOOP
                dbms_output.put_line('mapp_bene:'||x.mapp_bene||' amt:'||x.net_amt);
                cnt_prem_seq := cnt_prem_seq+1;
                Insert into NC_RESERVED
                   (STS_KEY, CLM_NO, PROD_GRP, PROD_TYPE, TYPE, SUB_TYPE, TRN_SEQ, STS_DATE, AMD_DATE, PREM_CODE, PREM_SEQ, RES_AMT, CLM_USER, AMD_USER)
                 Values
                   (Mas.sts_key ,v_clmno ,Mas.prod_grp , Mas.prod_type , 'NCNATTYPECLM101',
                    'NCNATSUBTYPECLM101', v_maxSeq+1 ,v_sysdate , v_sysdate ,x.mapp_bene,
                    cnt_prem_seq, x.net_amt , v_user , 'PROGRAM' );
            END LOOP; --x
        END LOOP; --Mas

        update  nc_billing a
        set status = 'CONVERT'
        where clm_no = v_clmno
        and trn_seq in (select max(aa.trn_seq) from nc_billing aa where aa.clm_no = a.clm_no);

        commit;

        v_rst := p_ph_clm.SAVE_CLAIM_STATUS('benefit' ,v_clmno ,'' );

        return v_ret;
    EXCEPTION
        WHEN OTHERS THEN
            O_RST := 'error:'||sqlerrm;
            rollback;
            v_ret := 'N';
            return v_ret;
    END CONV_BENEFIT;

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

    PROCEDURE GET_MAJOR_SUMINS_PRO(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN NUMBER ,sum_insured OUT SYS_REFCURSOR) IS
    insured number;
    BEGIN
   
          insured  := p_ph_clm.GET_MAJOR_SUMINS(v_polno,v_polrun,v_plan);
          
          open sum_insured for select insured from dual;
         
    END GET_MAJOR_SUMINS_PRO;
         
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


    FUNCTION GET_LIST_CARDTYPE(O_CARDTYPE_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 IS
        v_ret   varchar2(250);
        cnt_rec number(10);
    BEGIN
            begin
                select count(*)  into cnt_rec
                from clm_constant a
                where key like 'PHCARDTYPE%'
                and nvl(exp_date ,trunc(sysdate)+1) > trunc(sysdate);
            exception
                when no_data_found then
                    cnt_rec := 0;
                when others then
                    cnt_rec := 0;
            end;

            if cnt_rec >0 then
            OPEN O_CARDTYPE_LIST For
                select REMARK2 VALUE ,remark TEXT
                from clm_constant a
                where key like 'PHCARDTYPE%'
                and nvl(exp_date ,trunc(sysdate)+1) > trunc(sysdate);
             end if;


             if cnt_rec = 0 then
                v_ret := 'not found list';
                open O_CARDTYPE_LIST for
                    select '' VALUE ,'' TEXT
                    from dual;
             end if;

             return v_ret;
    EXCEPTION
        WHEN OTHERS THEN
            v_ret := 'error:'||sqlerrm;
            open O_CARDTYPE_LIST for
                select '' VALUE ,'' TEXT
                from dual;
            return v_ret;
    END GET_LIST_CARDTYPE;

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
            claim_info_res  ˹�� KeyIn tab ClaimInfo
            billing     ˹�� KeyIn tab Billing
            benefit     ˹�� KeyIn tab Benefit
            ri_reserved     ˹�� KeyIn tab ReInsurance
        */
        v_ret   VARCHAR2(250):='';
        vsts_key    NUMBER;
        v_rst   VARCHAR2(250);
        save_Detail_Status VARCHAR2(25);
        save_NC_Status VARCHAR2(25);
        v_err_message   VARCHAR2(250);
    BEGIN
        if v_action is null or v_clmno is null then
            v_ret := '��س��кآ��������ú';
            return v_ret;
        end if;

        begin
            select sts_key into vsts_key
            from nc_mas
            where clm_no = v_clmno;
        exception
            when no_data_found then
                v_ret := '��辺������ Claim';
            when others then
                v_ret := '��辺������ Claim';
        end;

        if v_ret is not null then
            return v_ret;
        end if;

        nc_health_package.save_ncmas_history(vsts_key ,v_rst);

        if v_rst is not null then
            return v_rst;
        end if;

        if v_action = 'claim_info_res' then
            if P_PH_CLM.IS_BILLING_STEP(v_clmno ,v_rst) = '0' then -- ���������㹢�� billing

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
        elsif  v_action in ( 'reopen' ,'cancel' ,'cwp') then
            save_Detail_Status := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'D');
            save_NC_Status  := P_PH_CLM.GET_MAPPING_ACTION(v_action ,'O');
        end if;

        dbms_output.put_line('save_NC_Status='||save_NC_Status||' save_Detail_Status='||save_Detail_Status);
        UPDATE NC_MAS
        SET clm_sts = save_NC_Status ,claim_status = save_Detail_Status
        WHERE CLM_NO = v_clmno;

        COMMIT;

        if v_action in ( 'claim_info_paid' ) then -- check for Update claim_info_paid on Payment
            if not p_ph_convert.CONV_PH_RES_REV(v_clmno ,v_payno  ,save_Detail_Status, v_err_message ) then
                null;
            end if;   
        else
            p_ph_convert.CONV_TABLE(v_clmno ,v_payno ,null, v_ret) ;        
        end if;

--        p_ph_convert.CONV_TABLE(v_clmno ,v_payno ,null, v_ret) ;

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
        v_cnt_res number;
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

        else    -- case ��ͧ���Ǩ������ RI �ա��
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


    FUNCTION getRI_RES(v_clmno IN VARCHAR2 ,v_amt IN NUMBER ,O_RI OUT P_PH_CLM.v_curr) RETURN VARCHAR2 IS

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

                insert into TMP_RI_PAID (sid ,clm_no ,pay_no ,ri_code ,ri_br_code  ,ri_type
                , RI_PAY_AMT ,RI_TRN_AMT  , lett_no
                ,lett_prt, lett_type, STATUS, ri_lf_flag,ri_sub_type ,sub_type ,type
                ,ri_share ,prod_grp ,prod_type
                ) Values (mySID ,v_clmno, 'x', j_rec2.ri_code ,j_rec2.ri_br_code  ,j_rec2.ri_type
                ,v_riamt ,v_riamt ,vLett_no
                ,vLETT_PRT,vLETT_TYPE ,''  ,j_rec2.lf_flag ,j_rec2.ri_sub_type ,v_subtype ,v_type
                ,j_rec2.RI_SUM_SHR ,v_prodgrp ,v_prodtype
                );

                dbms_output.put_line('mySID='||mySID||' Tot_Paid='||v_tot_paid||' Ri_code:'||j_rec2.RI_CODE||' %shar='||j_rec2.RI_SUM_SHR||' Amt='||v_riamt);
            END LOOP; --C2

        else    -- case ��ͧ���Ǩ������ RI �ա��
            dbms_output.put_line('CRI_RES clm:'||v_clmno ||' cannot find CompleteRI-> ');
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
    END getRI_RES;

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
            v_rst := '�������ö�ѹ�֡ Billing �� ���ͧ�ҡ�ա�úѹ�֡ Benefit �����';
            return '0';
        else
            if P_PH_CLM.IS_CLOSED_CLAIM(v_clmno) = '0' then --false
                v_rst := '������Դ�����';
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
     v_sts_date date:=sysdate;
     v_oldsts  varchar2(20);
     v_rst2 varchar2(250);
     dumm_rst   boolean;
    BEGIN
        if v_accum_amt <= 0 then
            if v_sts in ('PHSTSAPPRV02' ,'PHSTSAPPRV05') then
                v_rst := 'Cannot send amount 0 for approve payment ';
                return '0';
            end if;
        end if;

        if v_sts in ('PHSTSAPPRV03','PHSTSAPPRV04','PHSTSAPPRV06','PHSTSAPPRV11') then
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
        
        if v_max_seq >1 then
            BEGIN
                select sts_date into v_sts_date
                from nc_payment_apprv a
                where sts_key = v_key and pay_no = v_payno
                and trn_seq in (select max(aa.trn_seq) from nc_payment_apprv aa where aa.pay_no = a.pay_no );
            exception
                when no_data_found then
                    v_sts_date := sysdate;
                when others then
                    v_sts_date := sysdate;
            END;        
        end if;

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
        m_curr_code, m_curr_rate ,v_sts_date ,sysdate ,v_user ,v_amd_user ,v_apprv_user ,v_apprv_date
        ,m_prodgrp,m_prodtype, 'PH' ,v_key ,'NCNATSUBTYPECLM101' ,'NCNATTYPECLM101' ,v_apprv_flag ,v_remark) ;

        UPDATE NC_MAS
        SET APPROVE_STATUS = v_sts
        WHERE CLM_NO = v_clmno;

        COMMIT;

        if v_sts = 'PHSTSAPPRV01' then
            v_oldsts := 'NCPAYSTS01';
        elsif v_sts = 'PHSTSAPPRV02' then
            v_oldsts := 'NCPAYSTS02';
        elsif v_sts = 'PHSTSAPPRV03' then
            v_oldsts := 'NCPAYSTS03';
        elsif v_sts = 'PHSTSAPPRV04' then
            v_oldsts := 'NCPAYSTS04';
        elsif v_sts = 'PHSTSAPPRV05' then
            v_oldsts := 'NCPAYSTS07';
        elsif v_sts = 'PHSTSAPPRV06' then
            v_oldsts := 'NCPAYSTS08';
        elsif v_sts = 'PHSTSAPPRV11' then
            v_oldsts := 'NCPAYSTS11';
        elsif v_sts = 'PHSTSAPPRV12' then
            v_oldsts := 'NCPAYSTS12';
        elsif v_sts = 'PHSTSAPPRV31' then
            v_oldsts := 'NCPAYSTS06';
        elsif v_sts = 'PHSTSAPPRV80' then
            v_oldsts := 'NCPAYSTS80';
        end if;

        dumm_rst := NC_CLNMC908.UPDATE_STATUS(v_key ,'NCPAYSTS' ,v_oldsts ,v_amd_user ,v_remark ,v_rst2);

        dumm_rst := NC_CLNMC908.UPDATE_NCPAYMENT(v_key ,v_clmno ,v_payno ,v_oldsts ,v_remark ,v_apprv_flag  ,v_user  ,v_amd_user ,v_apprv_user ,v_res_amt ,v_rst2);

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
         o_rst := '�ҹ���������ҧ�͡��͹��ѵ�' ;
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
             o_rst := '�ҹ͹��ѵ������' ;
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
             o_rst := '������͹��ѵ������ !';
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
                 P_PH_CLM.GET_APPROVE_USER(i_clmno ,i_payno ,v_apprv_id ,v_sts );
                 IF v_apprv_id <> i_userid THEN
                     o_rst := '�ҹ����繢ͧ���� '||v_apprv_id ||' �繼��͹��ѵ� !';
                     v_return :=  'N';
                 ELSIF v_apprv_id = i_userid and v_apprv_id is not null THEN
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
            o_rst := '���� '||i_userid||' ������Է��͹��ѵ� !';
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

    FUNCTION CAN_GO_RESERVED(v_clmno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 IS
     v_return varchar2(10):='Y';
     v_maxpayno varchar2(20);
     v_apprv_sts varchar2(20);
     v_clm_sts varchar2(20);
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

        v_apprv_sts := p_ph_clm.get_claim_status(v_clmno ,v_maxpayno ,'A');
        v_clm_sts := p_ph_clm.get_claim_status(v_clmno ,v_maxpayno ,'C');

        if  v_clm_sts in ('PHCLMSTS03','PHCLMSTS06','PHCLMSTS30','PHCLMSTS31') then
            o_rst := '��� '||v_clmno||' �����ʶҹ� '||p_ph_clm.GET_CLMSTS_DESCR(v_clm_sts)||' �������ö��� reserved ��!';
            return 'N';
        end if;
        if  v_apprv_sts in ('PHSTSAPPRV02','PHSTSAPPRV03','PHSTSAPPRV05','PHSTSAPPRV06','PHSTSAPPRV11' ,'PHSTSAPPRV12') then
            o_rst := '��� '||v_clmno||' �����ʶҹ� '||p_ph_clm.GET_APPRVSTS_DESCR(v_apprv_sts)||' �������ö��� reserved ��!';
            return 'N';
        end if;
       --p_ph_clm.CAN_SEND_APPROVE

        return v_return;
    END CAN_GO_RESERVED;


    FUNCTION CAN_SAVE_BILLING(v_clmno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 IS
     v_return varchar2(10):='Y';
     v_maxpayno varchar2(20);
     v_apprv_sts varchar2(20);
     v_clm_sts varchar2(20);
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

        v_apprv_sts := p_ph_clm.get_claim_status(v_clmno ,v_maxpayno ,'A');
        v_clm_sts := p_ph_clm.get_claim_status(v_clmno ,'' ,'C');

        if  v_clm_sts not in ('PHCLMSTS01','PHCLMSTS40') then
            o_rst := '��� '||v_clmno||' �����ʶҹ� '||p_ph_clm.GET_CLMSTS_DESCR(v_clm_sts)||' �������ö��� �ѹ�֡��� ��!';
            return 'N';
        end if;
        if  v_apprv_sts in ('PHSTSAPPRV02','PHSTSAPPRV03','PHSTSAPPRV05','PHSTSAPPRV06','PHSTSAPPRV11' ,'PHSTSAPPRV12') then
            o_rst := '��� '||v_clmno||' �����ʶҹ� '||p_ph_clm.GET_APPRVSTS_DESCR(v_apprv_sts)||' �������ö��� �ѹ�֡��� ��!';
            return 'N';
        end if;
       --p_ph_clm.CAN_SEND_APPROVE

        return v_return;
    END CAN_SAVE_BILLING;


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
            and a.trn_seq in (select max(bb.trn_seq) from nc_payment bb where bb.clm_no = a.clm_no and  bb.pay_no = a.pay_no and type = 'NCNATTYPECLM101' )
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
            o_rst := '��辺������ RI Paid';
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
            and trn_seq = (select max(trn_seq) from nc_payment aa where aa.pay_no = a.pay_no and aa.type = 'NCNATTYPECLM101')
            and a.type ='NCNATTYPECLM101'
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
            o_rst := '��辺 '||v_status||' ��к�';
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
        v_clmsts    varchar2(20);
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
        
        v_clmsts :=  P_PH_CLM.GET_CLAIM_STATUS(v_clmno ,'' ,'C');
        if v_clmsts in ('PHCLMSTS06', 'PHCLMSTS30' ,'PHCLMSTS31' ,'PHCLMSTS01') then
                o_rst := '��� �����ʶҹ� '||p_ph_clm.get_clmsts_descr(v_clmsts)||' �������ö�ѹ�֡������ Payment ��';
                if v_clmsts = 'PHCLMSTS01' then
                    o_rst := o_rst|| ' ,��سҵ�� Reserved ��͹';
                elsif v_clmsts in ('PHCLMSTS30' ,'PHCLMSTS31' ) then
                    o_rst := o_rst|| ' ,��سҷ� ReOpen ��͹';
                end if;
                
                v_return := 'N';       
                return v_return; 
        end if;
        
        v_return := P_PH_CLM.CAN_SEND_APPROVE(v_clmno ,v_maxpayno ,o_rst) ;

        if v_return = 'Y' then -- �� Claim Status ����
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
                o_rst := '�ʹ Reserved <= 0';
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
                select user_id VALUE , '�س '||name_t TEXT
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
        v_polno varchar2(20);
        v_polrun    number(20);
        v_fleet number(10);
        v_id    varchar2(20);
    BEGIN
        NC_HEALTH_PAID.GET_HOSPITAL_CONTACT(v_payee ,v_payee_seq ,null , o_contact_name ,o_addr1  ,o_addr2  , o_mobile ,o_email);
        --:clm_gm_payee.CUST_MAIL := NC_HEALTH_PAID.GET_ORG_CUSTOMER_EMAIL(:clm_gm_payee.CLM_NO);
        if o_email is null then o_email := NC_HEALTH_PAID.GET_ORG_CUSTOMER_EMAIL(v_clmno); end if;

        IF NC_HEALTH_PAID.IS_AGENT_CHANNEL(v_clmno ,v_payee) THEN
            NC_HEALTH_PAID.GET_AGENT_CONTACT (v_clmno , o_contact_name ,o_addr1  ,o_addr2
            , o_agent_mobile ,o_agent_email );
        END IF;

        if o_email is null then -- find BKI Email
            begin
                select pol_no ,pol_run ,fleet_seq into v_polno ,v_polrun ,v_fleet
                from nc_mas a
                where clm_no = v_clmno;

                if p_ph_clm.is_bkipolicy(v_polno ,v_polrun) then
                    begin
                        select substr(id_no,1,instr(id_no ,'-')-1)  into v_id
                        from pa_medical_det
                        where pol_no = v_polno and pol_run=v_polrun
                        and fleet_seq = v_fleet and rownum=1;

                        O_EMAIL := P_PH_CLM.GET_BKISTAFF_EMAIL(V_ID);
                    exception
                     when no_data_found then
                         v_id := null;
                    when others then
                        v_id := null;
                    end;
                end if;
            exception
             when no_data_found then
                 v_polno := null; v_polrun := null; v_fleet  := null;
            when others then
                v_polno := null; v_polrun := null; v_fleet  := null;
            end;
        end if;
    EXCEPTION
        WHEN OTHERS THEN
        o_contact_name := null;  o_addr1 := null;  o_addr2 := null;  o_mobile := null;  o_email := null; o_agent_mobile := null; o_agent_email := null;
    END GET_PAYEE_DETAIL ;

    FUNCTION IS_BKIPOLICY (vPolNo IN VARCHAR2 ,vPolRun IN NUMBER ) RETURN BOOLEAN IS
        v_ret   boolean:=false;
        v_code  varchar2(30);
    BEGIN
        select key into v_code
        from clm_constant
        where key like 'PHBKIPOL%'
        and remark = vPolno
        and remark2 = vPolrun;

        return true;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        return false;
        WHEN OTHERS THEN
        return false;
    END IS_BKIPOLICY ;

    FUNCTION GET_BKISTAFF_EMAIL (vUser IN VARCHAR2 ) RETURN VARCHAR2 IS

        v_email  varchar2(150);
    BEGIN
        select email into v_email
        from bkiuser
        where user_id = vUser;

        return v_email;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        return null;
        WHEN OTHERS THEN
        return null;
    END GET_BKISTAFF_EMAIL ;

    FUNCTION GET_PH_HISTORY(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_fleet IN NUMBER ,v_clmno IN VARCHAR2
    ,O_History Out P_PH_CLM.v_curr) RETURN VARCHAR2 IS -- Return null = success ,not null = show error
        mySID   NUMBER;
        v_rst   VARCHAR2(250):=null;
        cnt_r1  NUMBER:=0;  cnt_r2  NUMBER:=0;
    BEGIN
        if v_polno is null or v_polrun is null or v_fleet is null then
            v_rst := '��س��к� policyno ,fleet_seq';
        else
            mySID := nc_health_package.gen_sid();

            for x in (
                select  a.clm_no ,np.pay_no,a.pol_no ,a.pol_run ,a.fleet_seq ,a.mas_cus_name ,a.cus_name, a.plan
                ,a.hpt_code ,p_ph_clm.get_hospital_name(a.hpt_code) hpt_descr, p_ph_clm.get_clmpdflag(nr.prem_code) clm_pd_flag
                ,a.claim_status clm_sts ,p_ph_clm.get_clmsts_descr(a.claim_status) clm_sts_descr
                , nr.prem_code bene_code ,p_ph_clm.get_bene_descr(nr.prem_code ,'T') bene_descr
                , a.dis_code ,p_ph_clm.get_icd10_descr(a.dis_code,'T') dis_code_descr
                ,a.loss_date ,a.tr_date_fr ,a.tr_date_to ,a.tot_tr_day ipd_day ,a.add_tr_day add_day , np.remark
                ,nr.res_amt ,np.pay_amt ,np.recov_amt rec_amt
                from nc_mas a ,nc_reserved nr ,nc_payment np
                where nr.clm_no = a.clm_no
                and nr.clm_no = np.clm_no(+)
                and a.pol_no =v_polno and a.pol_run = v_polrun and a.fleet_seq = v_fleet
                and nr.trn_seq in (select max(nrr.trn_seq) from nc_reserved nrr where nrr.clm_no = nr.clm_no)
                and np.pay_no = (select max(npp.pay_no) from nc_payment npp where npp.clm_no = np.clm_no)
                and np.trn_seq in (select max(npp.trn_seq) from nc_payment npp where npp.clm_no = np.clm_no and npp.pay_no = np.pay_no and npp.type = 'NCNATTYPECLM101')
                and np.type = 'NCNATTYPECLM101'
                and nr.prem_code = np.prem_code
                and nr.clm_no like nvl(v_clmno,'%')
                order by a.clm_no ,nr.prem_code
            )loop
                cnt_r1 := cnt_r1+1;
                INSERT into TMP_PH_HISTORY(
                SID ,clm_no ,pay_no ,pol_no ,pol_run ,fleet_seq ,mas_cus_name ,cus_name ,plan
                ,hpt_code ,hpt_descr ,clm_pd_flag ,clm_sts ,clm_sts_descr
                ,bene_code ,bene_descr,dis_code ,dis_code_descr
                ,loss_date ,tr_date_fr ,tr_date_to ,ipd_day ,add_day ,remark
                ,res_amt ,pay_amt ,rec_amt
                )values(
                mySID ,x.clm_no ,x.pay_no ,x.pol_no ,x.pol_run ,x.fleet_seq ,x.mas_cus_name ,x.cus_name ,x.plan
                ,x.hpt_code ,x.hpt_descr ,x.clm_pd_flag ,x.clm_sts ,x.clm_sts_descr
                ,x.bene_code ,x.bene_descr,x.dis_code ,x.dis_code_descr
                ,x.loss_date ,x.tr_date_fr ,x.tr_date_to ,x.ipd_day ,x.add_day ,x.remark
                ,x.res_amt ,x.pay_amt ,x.rec_amt
                );
            end loop; --x

            for y in (
                SELECT cr.clm_no ,a.pay_no ,c.pol_no ,c.pol_run ,cr.fleet_seq ,c.mas_cus_enq mas_cus_name ,cr.title||' '||cr.name cus_name , a.plan
                ,cr.hpt_code  ,p_ph_clm.get_hospital_name(a.hpt_code) hpt_descr , a.clm_pd_flag
                ,c.clm_sts ,p_ph_clm.get_clmsts_descr(c.clm_sts) clm_sts_descr
                , a.bene_code ,p_ph_clm.get_bene_descr(a.bene_code ,'T') bene_descr
                , a.dis_code  ,p_ph_clm.get_icd10_descr(a.dis_code,'T') dis_code_descr
                ,a.loss_date ,a.loss_date tr_date_fr ,'' tr_date_to ,a.ipd_day ipd_day ,'' add_day , a.remark
                ,cr.res_amt ,a.pay_amt ,a.rec_amt
                FROM mis_clm_mas c ,clm_medical_res cr , clm_gm_paid a
                WHERE a.clm_no = c.clm_no and cr.clm_no = a.clm_no(+)
                and a.pay_no = (select max(x.pay_no) from clm_gm_paid x where x.clm_no = a.clm_no)
                and (pay_no,corr_seq) in (select aa.pay_no ,max(aa.corr_seq) from clm_gm_paid aa where aa.pay_no = a.pay_no group by aa.pay_no)
                AND cr.fleet_seq = v_fleet
                AND pol_no = v_polno AND pol_run = v_polrun
                AND state_seq = (SELECT MAX (state_seq) FROM clm_medical_res b WHERE b.clm_no = cr.clm_no AND b.state_no = cr.state_no)
                and cr.bene_code = a.bene_code
                AND cr.clm_no like nvl(v_clmno,'%')
                and c.clm_no not in (select d.clm_no from nc_mas d where d.clm_no = c.clm_no)
                order by cr.clm_no ,state_seq ,cr.bene_code
            )loop
                cnt_r2 := cnt_r2+1;
                INSERT into TMP_PH_HISTORY(
                SID ,clm_no ,pay_no ,pol_no ,pol_run ,fleet_seq ,mas_cus_name ,cus_name ,plan
                ,hpt_code ,hpt_descr ,clm_pd_flag ,clm_sts ,clm_sts_descr
                ,bene_code ,bene_descr,dis_code ,dis_code_descr
                ,loss_date ,tr_date_fr ,tr_date_to ,ipd_day ,add_day ,remark
                ,res_amt ,pay_amt ,rec_amt
                )values(
                mySID ,y.clm_no ,y.pay_no ,y.pol_no ,y.pol_run ,y.fleet_seq ,y.mas_cus_name ,y.cus_name ,y.plan
                ,y.hpt_code ,y.hpt_descr ,y.clm_pd_flag ,y.clm_sts ,y.clm_sts_descr
                ,y.bene_code ,y.bene_descr,y.dis_code ,y.dis_code_descr
                ,y.loss_date ,y.tr_date_fr ,y.tr_date_to ,y.ipd_day ,y.add_day ,y.remark
                ,y.res_amt ,y.pay_amt ,y.rec_amt
                );
            end loop; --y

            for x in (  -- Reserve
                select  a.clm_no ,'**�ѧ������**' pay_no,a.pol_no ,a.pol_run ,a.fleet_seq ,a.mas_cus_name ,a.cus_name, a.plan
                ,a.hpt_code ,p_ph_clm.get_hospital_name(a.hpt_code) hpt_descr, p_ph_clm.get_clmpdflag(nr.prem_code) clm_pd_flag
                ,a.claim_status clm_sts ,p_ph_clm.get_clmsts_descr(a.claim_status) clm_sts_descr
                , nr.prem_code bene_code ,p_ph_clm.get_bene_descr(nr.prem_code ,'T') bene_descr
                , a.dis_code ,p_ph_clm.get_icd10_descr(a.dis_code,'T') dis_code_descr
                ,a.loss_date ,a.tr_date_fr ,a.tr_date_to ,a.tot_tr_day ipd_day ,a.add_tr_day add_day  , '' remark
                ,nr.res_amt  ,'' pay_amt ,'' rec_amt
                from nc_mas a ,nc_reserved nr 
                where nr.clm_no = a.clm_no
                and a.pol_no =v_polno and a.pol_run = v_polrun and a.fleet_seq = v_fleet
                and a.claim_status not in ('PHCLMSTS03','PHCLMSTS06')
                and nr.trn_seq in (select max(nrr.trn_seq) from nc_reserved nrr where nrr.clm_no = nr.clm_no)
                and nr.clm_no like nvl(v_clmno,'%')
                order by a.clm_no ,nr.prem_code
            )loop
                cnt_r1 := cnt_r1+1;
                INSERT into TMP_PH_HISTORY(
                SID ,clm_no ,pay_no ,pol_no ,pol_run ,fleet_seq ,mas_cus_name ,cus_name ,plan
                ,hpt_code ,hpt_descr ,clm_pd_flag ,clm_sts ,clm_sts_descr
                ,bene_code ,bene_descr,dis_code ,dis_code_descr
                ,loss_date ,tr_date_fr ,tr_date_to ,ipd_day ,add_day ,remark
                ,res_amt ,pay_amt ,rec_amt
                )values(
                mySID ,x.clm_no ,x.pay_no ,x.pol_no ,x.pol_run ,x.fleet_seq ,x.mas_cus_name ,x.cus_name ,x.plan
                ,x.hpt_code ,x.hpt_descr ,x.clm_pd_flag ,x.clm_sts ,x.clm_sts_descr
                ,x.bene_code ,x.bene_descr,x.dis_code ,x.dis_code_descr
                ,x.loss_date ,x.tr_date_fr ,x.tr_date_to ,x.ipd_day ,x.add_day ,x.remark
                ,x.res_amt ,x.pay_amt ,x.rec_amt
                );
            end loop; --x
                        
            for y in (  --Reserve
                SELECT cr.clm_no ,'**�ѧ������**' pay_no ,c.pol_no ,c.pol_run ,cr.fleet_seq ,c.mas_cus_enq mas_cus_name ,cr.title||' '||cr.name cus_name , cr.plan
                ,cr.hpt_code  ,p_ph_clm.get_hospital_name(cr.hpt_code) hpt_descr , cr.clm_pd_flag
                ,c.clm_sts ,p_ph_clm.get_clmsts_descr(c.clm_sts) clm_sts_descr
                , cr.bene_code ,p_ph_clm.get_bene_descr(cr.bene_code ,'T') bene_descr
                , cr.dis_code  ,p_ph_clm.get_icd10_descr(cr.dis_code,'T') dis_code_descr
                ,cr.loss_date ,cr.loss_date tr_date_fr ,'' tr_date_to ,cr.ipd_day ipd_day ,'' add_day , '' remark
                ,cr.res_amt ,'' pay_amt ,'' rec_amt
                FROM mis_clm_mas c ,clm_medical_res cr 
                WHERE c.clm_no = cr.clm_no 
                AND cr.fleet_seq = v_fleet
                AND pol_no = v_polno AND pol_run = v_polrun
                AND c.clm_sts not in ('2','6')
                AND state_seq = (SELECT MAX (state_seq) FROM clm_medical_res b WHERE b.clm_no = cr.clm_no AND b.state_no = cr.state_no)
                AND cr.clm_no like nvl(v_clmno,'%')
                and c.clm_no not in (select d.clm_no from nc_mas d where d.clm_no = c.clm_no)
                order by cr.clm_no ,state_seq ,cr.bene_code
            )loop
                cnt_r2 := cnt_r2+1;
                INSERT into TMP_PH_HISTORY(
                SID ,clm_no ,pay_no ,pol_no ,pol_run ,fleet_seq ,mas_cus_name ,cus_name ,plan
                ,hpt_code ,hpt_descr ,clm_pd_flag ,clm_sts ,clm_sts_descr
                ,bene_code ,bene_descr,dis_code ,dis_code_descr
                ,loss_date ,tr_date_fr ,tr_date_to ,ipd_day ,add_day ,remark
                ,res_amt ,pay_amt ,rec_amt
                )values(
                mySID ,y.clm_no ,y.pay_no ,y.pol_no ,y.pol_run ,y.fleet_seq ,y.mas_cus_name ,y.cus_name ,y.plan
                ,y.hpt_code ,y.hpt_descr ,y.clm_pd_flag ,y.clm_sts ,y.clm_sts_descr
                ,y.bene_code ,y.bene_descr,y.dis_code ,y.dis_code_descr
                ,y.loss_date ,y.tr_date_fr ,y.tr_date_to ,y.ipd_day ,y.add_day ,y.remark
                ,y.res_amt ,y.pay_amt ,y.rec_amt
                );
            end loop; --y            

            if cnt_r1 + cnt_r2 = 0 then --not found claim
                v_rst := '��辺����ѵ����';
            end if;
        end if;

        if v_rst is null then -- check error /Not Error
            OPEN O_History  FOR
                SELECT clm_no ,pay_no ,pol_no ,pol_run ,fleet_seq ,mas_cus_name ,cus_name ,plan
                ,hpt_code ,hpt_descr ,clm_pd_flag ,clm_sts ,clm_sts_descr
                ,bene_code ,bene_descr,dis_code ,dis_code_descr
                ,loss_date ,tr_date_fr ,tr_date_to ,ipd_day ,add_day ,remark
                ,res_amt ,pay_amt ,rec_amt
                FROM TMP_PH_HISTORY
                WHERE SID = mySID
                order by p_std_clmno.split_clm_num(clm_no) ,p_std_clmno.split_clm_run(clm_no);

            delete     TMP_PH_HISTORY where SID = mySID;
            commit;
            Return null;
        else -- Has Error
            OPEN O_History  FOR
                SELECT '' clm_no ,'' pay_no ,'' pol_no ,'' pol_run ,'' fleet_seq ,'' mas_cus_name ,'' cus_name ,'' plan
                ,'' hpt_code ,'' hpt_descr ,'' clm_pd_flag ,'' clm_sts ,'' clm_sts_descr
                ,'' bene_code ,'' bene_descr,'' dis_code ,'' dis_code_descr
                ,'' loss_date ,'' tr_date_fr ,'' tr_date_to ,'' ipd_day ,'' add_day ,'' remark
                ,'' res_amt ,'' pay_amt ,'' rec_amt  FROM DUAL;
            return v_rst;
        end if; -- check error

    EXCEPTION
        WHEN OTHERS THEN
            rollback;
                OPEN O_History  FOR
                SELECT '' clm_no ,'' pay_no ,'' pol_no ,'' pol_run ,'' fleet_seq ,'' mas_cus_name ,'' cus_name ,'' plan
                ,'' hpt_code ,'' hpt_descr ,'' clm_pd_flag ,'' clm_sts ,'' clm_sts_descr
                ,'' bene_code ,'' bene_descr,'' dis_code ,'' dis_code_descr
                ,'' loss_date ,'' tr_date_fr ,'' tr_date_to ,'' ipd_day ,'' add_day ,'' remark
                ,'' res_amt ,'' pay_amt ,'' rec_amt  FROM DUAL;
            dbms_output.put_line('error :'||sqlerrm);
            Return 'error: '||sqlerrm;
    END GET_PH_HISTORY;

    FUNCTION CAN_GO_CWP(v_clmno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 IS
     v_return varchar2(10):='Y';
     v_maxpayno varchar2(20);
     v_apprv_sts varchar2(20);
     v_clm_sts varchar2(20);
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

        v_apprv_sts := p_ph_clm.get_claim_status(v_clmno ,v_maxpayno ,'A');
        v_clm_sts := p_ph_clm.get_claim_status(v_clmno ,v_maxpayno ,'C');

        if  v_clm_sts in ('','PHCLMSTS06','PHCLMSTS30','PHCLMSTS31') then
            o_rst := '��� '||v_clmno||' �����ʶҹ� '||p_ph_clm.GET_CLMSTS_DESCR(v_clm_sts)||' �������ö�� CWP/Cancel ��!';
            return 'N';
        end if;
        if  v_apprv_sts in ('PHSTSAPPRV02','PHSTSAPPRV03','PHSTSAPPRV05','','PHSTSAPPRV11' ,'PHSTSAPPRV12') then
            o_rst := '��� '||v_clmno||' �����ʶҹ� '||p_ph_clm.GET_APPRVSTS_DESCR(v_apprv_sts)||' �������ö�� CWP/Cancel ��!';
            return 'N';
        end if;

        return v_return;
    END CAN_GO_CWP;

    FUNCTION GET_CWP_LIST (v_type IN VARCHAR2 ,O_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 IS
        v_ret varchar2(250);
        cnt_rec number(10);
    BEGIN
       OPEN O_LIST  FOR
            select remark VALUE ,descr TEXT
            from clm_constant
            where key like 'CWPPH-TYPE%'
            order by remark ;
        return v_ret;

    EXCEPTION
           when no_data_found then
            v_ret := 'Not found ';
            OPEN O_LIST  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;

           when others then
            v_ret := 'error: '||sqlerrm;
            OPEN O_LIST  FOR SELECT '' VALUE ,'' TEXT   FROM DUAL;
            return v_ret;

    END GET_CWP_LIST;

    FUNCTION SET_CWP_CLM(v_clmno IN VARCHAR2 ,v_code IN VARCHAR2  ,v_remark IN VARCHAR2 ,v_user IN VARCHAR2 ) RETURN VARCHAR2 IS
        v_return    VARCHAR2(250);
        v_sysdate   date:=sysdate;
        vPayNo  VARCHAR2(20);
        v_rst   VARCHAR2(250);
        V_AMT   number:=0;
    BEGIN
        begin
            select max(pay_no) into vPayNo
            from nc_payment
            where clm_no = v_clmno;
        exception
            when no_data_found then
                vPayNo := null;
            when others then
                vPayNo :=null;
        end;

        Insert into ALLCLM.NC_PAYMENT
           (CLM_NO, PAY_NO, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, SUBSYSID, CURR_CODE, CURR_RATE, STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, PROD_GRP, PROD_TYPE, STS_KEY, TYPE, SUB_TYPE, PREM_CODE, PREM_SEQ, STATUS, TOT_PAY_AMT
           ,CLM_SEQ ,OFFSET_FLAG ,DAYS ,RECOV_AMT ,DAY_ADD ,REMARK)
           (
            select clm_no, pay_no, trn_seq+1, pay_sts, V_AMT pay_amt, V_AMT trn_amt, subsysid, curr_code, curr_rate, sts_date,v_sysdate, clm_men, v_user, prod_grp, prod_type, sts_key, type, sub_type, prem_code, prem_seq, status, tot_pay_amt
            ,clm_seq ,offset_flag ,days ,recov_amt ,day_add ,remark
            from nc_payment a
            where  a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no and type<>'01')
            and a.pay_no = vPayNo
             and type<>'01'
            );

        Insert into ALLCLM.NC_PAYMENT
           (CLM_NO, PAY_NO, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, SUBSYSID, CURR_CODE, CURR_RATE, STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, PROD_GRP, PROD_TYPE, STS_KEY, TYPE, SUB_TYPE, PREM_CODE, PREM_SEQ, STATUS, TOT_PAY_AMT
           ,CLM_SEQ ,OFFSET_FLAG ,DAYS ,RECOV_AMT ,DAY_ADD ,REMARK)
           (
            select clm_no, pay_no, trn_seq+1, 'NCPAYSTS06' pay_sts, V_AMT pay_amt, V_AMT trn_amt, subsysid, curr_code, curr_rate, sts_date,v_sysdate, clm_men, v_user, prod_grp, prod_type, sts_key, type, sub_type, prem_code, prem_seq, status, tot_pay_amt
            ,clm_seq ,offset_flag ,days ,recov_amt ,day_add ,remark
            from nc_payment a
            where  a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no and type='01')
            and a.pay_no = vPayNo
             and type='01'
            );
            
        Insert into ALLCLM.NC_PAYMENT_APPRV
        (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, PROD_GRP, PROD_TYPE
        , SUBSYSID, STS_KEY, TYPE, SUB_TYPE, REMARK)
        (
        select CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ+1, 'PHSTSAPPRV31' PAY_STS, V_AMT PAY_AMT, V_AMT TRN_AMT, CURR_CODE, CURR_RATE, STS_DATE, v_sysdate, CLM_MEN, v_user, PROD_GRP, PROD_TYPE
        , SUBSYSID, STS_KEY, TYPE, SUB_TYPE, 'Cancel by Cancel/Cwp'
        from NC_PAYMENT_APPRV a
        where clm_no = v_clmno and pay_no = vPayNo
        and trn_seq in (select max(aa.trn_seq) from nc_payment_apprv aa where aa.pay_no = a.pay_no)
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
            select clm_no, pay_no, prod_grp, prod_type, trn_seq +1, sts_date, v_sysdate, payee_code, payee_name, payee_type, payee_seq, V_AMT payee_amt, settle, acc_no, acc_name, bank_code, bank_br_code, br_name, send_title, paid_sts, deduct_flag, type, sent_type, salvage_amt, deduct_amt, curr_code
            ,send_addr1 ,send_addr2 ,salvage_flag ,email ,sms ,appoint_date ,curr_rate ,agent_sms ,agent_email ,special_flag ,special_remark ,grp_payee_flag ,urgent_flag
            ,recovery_flag ,V_AMT recovery_amt ,paid_to
            from nc_payee a
            where  a.trn_seq in (select max(aa.trn_seq) from nc_payee aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no)
            and a.pay_no = vPayNo
           ) ;


        Insert into ALLCLM.NC_RI_PAID
           (STS_KEY, CLM_NO, PAY_NO, PROD_GRP, PROD_TYPE, TYPE, RI_CODE, RI_BR_CODE, RI_TYPE, RI_LF_FLAG, RI_SUB_TYPE, RI_SHARE, TRN_SEQ, RI_STS_DATE, RI_AMD_DATE, RI_PAY_AMT, RI_TRN_AMT, STATUS, SUB_TYPE
           ,LETT_NO ,LETT_PRT ,LETT_TYPE ,CASHCALL ,CANCEL ,PRINT_TYPE ,PRINT_USER ,PRINT_DATE
           )
           (
           select sts_key, clm_no, pay_no, prod_grp, prod_type, type, ri_code, ri_br_code, ri_type, ri_lf_flag, ri_sub_type, ri_share, trn_seq +1, ri_sts_date,v_sysdate,V_AMT ri_pay_amt,V_AMT ri_trn_amt, status, sub_type
           ,lett_no ,lett_prt ,lett_type ,cashcall ,cancel ,print_type ,print_user ,print_date
            from nc_ri_paid a
            where  a.trn_seq in (select max(aa.trn_seq) from nc_ri_paid aa where  aa.clm_no =a.clm_no and aa.pay_no = a.pay_no)
            and a.pay_no = vPayNo
           );

        commit;

        if vPayNo is null then
            v_rst := p_ph_clm.SAVE_CLAIM_STATUS('claim_info_res' ,v_clmno ,vPayNo);
        else
            v_rst := p_ph_clm.SAVE_CLAIM_STATUS('claim_info_paid' ,v_clmno ,vPayNo);
        end if;

        update nc_mas
        set cwp_code = v_code ,cwp_remark =v_remark ,cwp_user = v_user
        ,close_date = trunc(v_sysdate)
        where clm_no = v_clmno;

        commit;

        if v_code in ('3','4') then --Cancel
            v_rst := p_ph_clm.SAVE_CLAIM_STATUS('cancel' ,v_clmno ,vPayNo) ;
        else --CWP
            v_rst := p_ph_clm.SAVE_CLAIM_STATUS('cwp' ,v_clmno ,vPayNo) ;
        end if;


        return v_return;
    EXCEPTION
        WHEN OTHERS THEN
        rollback; v_return := 'error update  ->'||sqlerrm ;
        return v_return;
    END SET_CWP_CLM;

    FUNCTION CAN_REOPEN(v_clmno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 IS
     v_return varchar2(10):='Y';
     v_maxpayno varchar2(20);
     v_apprv_sts varchar2(20);
     v_clm_sts varchar2(20);
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

        v_apprv_sts := p_ph_clm.get_claim_status(v_clmno ,v_maxpayno ,'A');
        v_clm_sts := p_ph_clm.get_claim_status(v_clmno ,v_maxpayno ,'C');

        if  v_clm_sts not in ('PHCLMSTS30','PHCLMSTS31') then
            o_rst := '��� '||v_clmno||' �����ʶҹ� '||p_ph_clm.GET_CLMSTS_DESCR(v_clm_sts)||' �������ö�� ReOpen ��!';
            return 'N';
        end if;
        if  v_apprv_sts in ('PHSTSAPPRV02','PHSTSAPPRV03','PHSTSAPPRV05','','PHSTSAPPRV11' ,'PHSTSAPPRV12') then
            o_rst := '��� '||v_clmno||' �����ʶҹ� '||p_ph_clm.GET_APPRVSTS_DESCR(v_apprv_sts)||' �������ö�� ReOpen ��!';
            return 'N';
        end if;

        return v_return;
    END CAN_REOPEN;

    FUNCTION SET_REOPEN(v_clmno IN VARCHAR2 ,v_code IN VARCHAR2  ,v_remark IN VARCHAR2 ,v_user IN VARCHAR2 ) RETURN VARCHAR2 IS
        v_return    VARCHAR2(250);
        v_sysdate   date:=sysdate;
        vPayNo  VARCHAR2(20);
        v_rst   VARCHAR2(250);
    BEGIN
        begin
            select max(pay_no) into vPayNo
            from nc_payment
            where clm_no = v_clmno;
        exception
            when no_data_found then
                vPayNo := null;
            when others then
                vPayNo :=null;
        end;

        update nc_mas
        set cwp_code = '' ,cwp_remark =v_remark ,cwp_user = v_user
        ,close_date = null ,reopen_date = trunc(v_sysdate)
        where clm_no = v_clmno;

        v_rst := p_ph_clm.SAVE_CLAIM_STATUS('reopen' ,v_clmno ,vPayNo) ;

        return v_return;
    EXCEPTION
        WHEN OTHERS THEN
        rollback; v_return := 'error update  ->'||sqlerrm ;
        return v_return;
    END SET_REOPEN;

    PROCEDURE GET_APPROVE_USER(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_apprv_id OUT varchar2 ,o_apprv_sts OUT varchar2) IS

    BEGIN
         BEGIN
             select approve_id ,pay_sts into o_apprv_id ,o_apprv_sts
             from nc_payment_apprv xxx
             where
             xxx.clm_no = i_clmno and pay_no = i_payno
             and xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no
              );
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            o_apprv_id := null; o_apprv_sts := null;
         WHEN OTHERS THEN
            o_apprv_id := null; o_apprv_sts := null;
         END;
    END GET_APPROVE_USER;

    FUNCTION IS_NEW_PHCLM(v_clmno IN VARCHAR2 ,O_RST OUT VARCHAR2) RETURN BOOLEAN IS
        v_dumm  VARCHAR2(20);
    BEGIN
        select clm_no into v_dumm
        from nc_mas a
        where a.clm_no = v_clmno
        and prod_grp ='0';

        if v_dumm is not null then
            O_RST := 'CLMNO: '||v_clmno||' �١���ҧ���к� new PHsystem ��سҴ��Թ��÷�����������!';
            return true;
        else
            return false;
        end if;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
        return false;
     WHEN OTHERS THEN
        return false;
    END IS_NEW_PHCLM;
END P_PH_CLM;
/

