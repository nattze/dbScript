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
    BEGIN
        if v_clm_no is not null then
            --return substr(v_clm_no ,1,4);
            if length(v_clm_no) <15 then
                ret_clmno := null;
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
    BEGIN
        if v_clm_no is not null then

            if length(v_clm_no) <15 then
                ret_clmrun := 0;
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

    FUNCTION get_prodgrp(v_clm_no IN VARCHAR2) RETURN VARCHAR2 IS
        ret_prodgrp   varchar2(2);
        chk_found varchar2(20);
    BEGIN
        if v_clm_no is not null then

            if length(v_clm_no) <15 then
                ret_prodgrp := null;
                begin 
                    select prod_grp into chk_found
                    from mis_clm_mas
                    where clm_no = v_clm_no;
                exception
                    when no_data_found then
                        chk_found := null;
                    when others then
                        chk_found := null;
                end;
                
                if chk_found is not null then
                    ret_prodgrp := chk_found;
                    return ret_prodgrp;
                end if;
                
                                
            else    -- case normal 
                ret_prodgrp := substr(v_clm_no ,7,1);
            end if;
            
        else
            return null;
        end if;
        
        return ret_prodgrp;
        EXCEPTION
            WHEN OTHERS THEN
            return null;
    END get_prodgrp;
    
END P_STD_CLMNO;

/
