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
    
END N_EF_EXAMPLE;
/
