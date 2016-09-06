CREATE OR REPLACE PACKAGE BODY P_STD_CLMNO AS
/******************************************************************************
   NAME:       P_STD_CLMNO
   PURPOSE:     For manage new Claim Number Format 
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/08/2016      2702       1. Created this package.
******************************************************************************/

    FUNCTION split_clm_num(v_clm_no IN VARCHAR2) RETURN VARCHAR2 IS
        ret_clmno   varchar2(15);
        v_clmyear   number;
    BEGIN
        if v_clm_no is not null then
            --return substr(v_clm_no ,1,4);
            if length(v_clm_no) <15 then               
                if to_number(substr(v_clm_no ,1,2)) >=16 then
                    v_clmyear := p_std_clmno.get_clmyear(v_clm_no) ;
                    ret_clmno := v_clmyear||substr(v_clm_no ,3,5);
                else
                    v_clmyear := p_std_clmno.get_clmyear(v_clm_no) ;
                    if v_clmyear <= 2000 then
                        ret_clmno := v_clmyear||substr(v_clm_no ,3);
                    else
                        ret_clmno := substr(v_clm_no ,1,7);
                    end if;
                end if;
            else    -- case normal 
                ret_clmno := substr(v_clm_no ,1,9);
            end if;
            
        else
            return null;
        end if;
        
        return ret_clmno;
        EXCEPTION
            WHEN OTHERS THEN
            return null;
    END split_clm_num;
    
    FUNCTION split_clm_run(v_clm_no  IN VARCHAR2) RETURN NUMBER  IS
        ret_clmrun  number;
        v_clmyear   number;
    BEGIN
        if v_clm_no is not null then

            if length(v_clm_no) <15 then
                if to_number(substr(v_clm_no ,1,2)) >=16 then
                    ret_clmrun :=  to_number(substr(v_clm_no ,8));
                else
                    v_clmyear := p_std_clmno.get_clmyear(v_clm_no) ;
                    if v_clmyear <= 2000 then
                        ret_clmrun := 0;
                    else
                        ret_clmrun := nvl(to_number(substr(v_clm_no ,8)),0);
                    end if;
                end if;
            else    -- case normal 
                ret_clmrun := to_number(substr(v_clm_no ,10));
            end if;            
        else
            return 0;
        end if;
        return ret_clmrun;
        EXCEPTION
            WHEN OTHERS THEN
            return 0;            
    END split_clm_run;

    FUNCTION get_clmyear(v_clm_no  IN VARCHAR2) RETURN NUMBER  IS
        ret_clmyear  number;
    BEGIN
        if v_clm_no is not null then
            if length(v_clm_no) <15 then
                begin 
                    select to_number(to_char(clm_date,'yyyy')) clmyr into ret_clmyear
                    from mis_clm_mas
                    where clm_no = v_clm_no;
                exception
                    when no_data_found then
                        ret_clmyear := 0;
                    when others then
                        ret_clmyear := 0;
                end;
                
                if ret_clmyear >0 then
                    return ret_clmyear;
                end if;
                
                begin 
                    select to_number(to_char(trn_date,'yyyy')) clmyr into ret_clmyear
                    from mtr_clm_tab
                    where clm_no = v_clm_no;
                exception
                    when no_data_found then
                        ret_clmyear := 0;
                    when others then
                        ret_clmyear := 0;
                end;
                
                if ret_clmyear >0 then
                    return ret_clmyear;
                else
                    if to_number(substr(v_clm_no ,1,2)) >=16 then
                        ret_clmyear :=to_number( '20'||substr(v_clm_no ,1,2));
                    end if; 
                end if;                                
            else    -- case normal 
                ret_clmyear := to_number(substr(v_clm_no ,1,4));
            end if;        
        else
            return 0;
        end if;
        
        return ret_clmyear;
        EXCEPTION
            WHEN OTHERS THEN
            return 0;            
    END get_clmyear ;

    FUNCTION gen_clmno_clmrun(v_clm_no IN VARCHAR2 ,v_table IN VARCHAR2 ,o_rst OUT VARCHAR2) RETURN BOOLEAN IS
        v_clmno varchar2(20);
        v_clmrun    number(15);
    BEGIN
        
        IF v_table = 'NC_MAS' THEN
            v_clmno := p_std_clmno.split_clm_num(v_clm_no);
            v_clmrun := p_std_clmno.split_clm_run(v_clm_no);
            update nc_mas
            set claim_number = v_clmno
            ,claim_run = v_clmrun
            where clm_no = v_clm_no;
            
            commit;
        END IF;
        
    return true;
    EXCEPTION
        WHEN OTHERS THEN
        o_rst := 'error on gen_clmno_clmrun: '||sqlerrm;
        return false;  
    END;
END P_STD_CLMNO;

/
