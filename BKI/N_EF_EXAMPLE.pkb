CREATE OR REPLACE PACKAGE BODY ALLCLM.N_EF_EXAMPLE AS
/******************************************************************************
   NAME:       N_EF_EXAMPLE
   PURPOSE:     For example case to call Store/Function
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/10/2016      2702       1. Created this package.
******************************************************************************/
    FUNCTION func_ret_vc2(v_param1 IN VARCHAR2) RETURN VARCHAR2 IS
        ret_vc2   varchar2(15);
    BEGIN
        if v_param1 is null then
            ret_vc2 := 'Input is Null';
        else
            ret_vc2 := 'Input = '||v_param1;
        end if;
        
        return null;
        EXCEPTION
            WHEN OTHERS THEN
            return null;
    END func_ret_vc2;
    
    FUNCTION func_ret_number(v_param1  IN VARCHAR2) RETURN NUMBER  IS
        ret_num  number;
    BEGIN
        if v_param1 is null then
            ret_num := 0;
        else
            ret_num := 100000000;
        end if;
            
        return ret_num;
        EXCEPTION
            WHEN OTHERS THEN
            return 0;            
    END func_ret_number;

    FUNCTION func_ret_boo_out_vc2(v_param1  IN VARCHAR2 ,o_param1 OUT VARCHAR2) RETURN BOOLEAN IS
    
    BEGIN
        if v_param1 is null then
            o_param1 := 'Input is Null';
            return true;
        else
            o_param1 := 'Input ='||v_param1;
            return false;
        end if;  
    
        EXCEPTION
            WHEN OTHERS THEN
            o_param1 := 'Error '||sqlerrm;
            return false;        
    END func_ret_boo_out_vc2;
    
    FUNCTION func_ret_Cursor(v_param1  IN VARCHAR2) RETURN N_EF_EXAMPLE.v_curr IS
        V_CUR1 N_EF_EXAMPLE.v_curr;
        V_CUR2 N_EF_EXAMPLE.v_curr;
    BEGIN
        OPEN V_CUR1  FOR 
            SELECT User_id MyID ,Name_T MyName FROM med_hospital_list;
            Return V_CUR1;
        EXCEPTION
            WHEN OTHERS THEN
                OPEN V_CUR2  FOR 
                    SELECT 0 MyID ,'Empty Row' MyName FROM DUAL;
                Return V_CUR2;    
    END func_ret_Cursor;    
    
    FUNCTION getRI_PAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2 ,v_amt IN NUMBER ,O_RI OUT N_EF_EXAMPLE.v_curr) RETURN VARCHAR2 IS

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
        end if;    
    
        OPEN O_RI  FOR 
            SELECT clm_no ,pay_no ,ri_code ,ri_br_code  ,ri_type 
                , ri_pay_amt ,ri_trn_amt  , lett_no
                ,lett_prt, lett_type, status, ri_lf_flag,ri_sub_type ,sub_type ,type
                ,ri_share ,prod_grp ,prod_type FROM TMP_RI_PAID
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
                                ,null ri_share ,'' prod_grp ,'' prod_type FROM DUAL;
            dbms_output.put_line('error :'||sqlerrm);
            Return '0';    
    END getRI_PAID;    
         


    FUNCTION validate_RI_RES(v_clmno IN VARCHAR2) RETURN VARCHAR2 IS
        v_ret VARCHAR2(250);
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
         type = '01' and sub_type = '01' and 
         xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no
         and type = '01' and sub_type = '01' );
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
             type = '01' and sub_type = '01' and 
             xxx.trn_seq = (select max(b.trn_seq) from nc_payment_apprv b where b.sts_key = xxx.sts_key and b.pay_no = xxx.pay_no
             and type = '01' and sub_type = '01' );
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
     --v_sum_payee number:=0;
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
            select nvl(sum(pay_amt),0) ,max(status) into v_sum_payment ,v_paysts
            from nc_payment a
            where prod_grp = '0'
            and type = 'PAPH' 
            and a.trn_seq in (select max(bb.trn_seq) from nc_payment bb where bb.clm_no = a.clm_no and  bb.pay_no = a.pay_no)
            and a.clm_no = v_clmno and a.pay_no = v_maxpayno
            ;
            
            if v_paysts = 'NCPAYMENTSTS04' and v_sum_payment = 0 then -- Cancel Payment
                o_rst := 'last payno was canceled';
                v_return := 'Y';                
            elsif  v_sum_payment > 0 then
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
        v_tot_res   number(10,4);
        v_tot_paid   number(10,4):=v_amt;
  
        v_riamt number(10,4);
        v_sumri number(10,4);  
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
    
END N_EF_EXAMPLE;
/
