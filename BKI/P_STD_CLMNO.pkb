CREATE OR REPLACE PACKAGE BODY ALLCLM.P_STD_CLMNO AS
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
        v_shortyr   number;
        v_fullyr    number;
        v_reg   varchar2(20);
        v_repyr varchar2(30);
    BEGIN
        if v_clm_no is not null then
            begin 
                select to_number(remark) shortYR ,to_number(remark2) fullYR
                into V_SHORTYR ,V_FULLYR
                from clm_constant a
                where key = 'CLMSPLITYEAR' ;
            exception
                when no_data_found then
                    V_SHORTYR := 17;
                    V_FULLYR := 2017;
                when others then
                    V_SHORTYR := 17;
                    V_FULLYR := 2017;
            end;         
--            dbms_output.put_line('V_FULLYR= '||V_FULLYR||' v_clm_no='||v_clm_no);   
            if length(v_clm_no) <15 then  
--                dbms_output.put_line('in length(v_clm_no) <15');
                v_clmyear := p_std_clmno.get_clmyear(v_clm_no) ;
                v_reg := '^'||to_char(v_clmyear)||'|'||substr(to_char(v_clmyear),3,2); 
--                dbms_output.put_line('clmyear='||v_clmyear||' v_reg= '||v_reg);     
                v_repyr := REGEXP_REPLACE (substr(v_clm_no ,1,4), v_reg, to_char(v_clmyear)) ;        
                v_repyr := v_repyr||substr(v_clm_no,5) ;  
--                dbms_output.put_line('v_repyr= '||v_repyr);             
                if to_number(substr(v_clm_no ,1,2)) >=V_SHORTYR then  -- have clm run
                        
                    if v_clmyear < V_FULLYR then
                        ret_clmno := v_repyr; --v_repyr||substr(v_clm_no ,5);
                    else
                        ret_clmno := substr(v_repyr ,1,9); --v_repyr||substr(v_clm_no ,5,5);
                    end if;
                    
                else    -- clm run = 0
                    if v_clmyear < V_FULLYR then
                        ret_clmno := v_repyr; --v_repyr||substr(v_clm_no ,5);
                    else
                        ret_clmno := substr(v_repyr ,1,9); --v_repyr||substr(v_clm_no ,5,5);
                    end if;
                end if;
            else    -- case normal                 
--                dbms_output.put_line('in length(v_clm_no) >=15');                
                v_clmyear := p_std_clmno.get_clmyear(v_clm_no) ;
                if v_clmyear < V_FULLYR then
                    ret_clmno := v_clm_no;
                else
                    v_reg := '^'||to_char(v_clmyear)||'|'||substr(to_char(v_clmyear),3,2); 
--                    dbms_output.put_line('clmyear='||v_clmyear||' v_reg= '||v_reg);        
                    v_repyr := REGEXP_REPLACE (substr(v_clm_no ,1,4), v_reg, to_char(v_clmyear)) ;   
                    v_repyr := v_repyr||substr(v_clm_no,5) ;  
--                    dbms_output.put_line('v_repyr= '||v_repyr);                   
                    ret_clmno := substr(v_repyr ,1,9);
                end if;                
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
        v_shortyr   number;
        v_fullyr    number;
        v_reg   varchar2(20);
        v_repyr varchar2(30);     
    BEGIN
        if v_clm_no is not null then

            begin 
                select to_number(remark) shortYR ,to_number(remark2) fullYR
                into V_SHORTYR ,V_FULLYR
                from clm_constant a
                where key = 'CLMSPLITYEAR' ;
            exception
                when no_data_found then
                    V_SHORTYR := 17;
                    V_FULLYR := 2017;
                when others then
                    V_SHORTYR := 17;
                    V_FULLYR := 2017;
            end;     
            
            if length(v_clm_no) <15 then
--                dbms_output.put_line('in length(v_clm_no) <15');
                v_clmyear := p_std_clmno.get_clmyear(v_clm_no) ;
                v_reg := '^'||to_char(v_clmyear)||'|'||substr(to_char(v_clmyear),3,2); 
--                dbms_output.put_line('clmyear='||v_clmyear||' v_reg= '||v_reg);         
                v_repyr := REGEXP_REPLACE (substr(v_clm_no ,1,4), v_reg, to_char(v_clmyear)) ;  
                v_repyr := v_repyr||substr(v_clm_no,5) ;  
--                dbms_output.put_line('v_repyr= '||v_repyr);  
                                
                if to_number(substr(v_clm_no ,1,2)) >=V_SHORTYR then
                    if v_clmyear < V_FULLYR then
                        ret_clmrun := 0;
                    else
--                        ret_clmrun :=  to_number(substr(v_clm_no ,8));
                        ret_clmrun :=  to_number(substr(v_repyr ,10));
                    end if;                
                    
                else
                    if v_clmyear < V_FULLYR then
                        ret_clmrun := 0;
                    else
--                        ret_clmrun := nvl(to_number(substr(v_clm_no ,8)),0);
                        ret_clmrun := nvl(to_number(substr(v_repyr ,10)),0);
                    end if;
                end if;
            else    -- case normal 
--                dbms_output.put_line('in length(v_clm_no) >=15');
                v_clmyear := p_std_clmno.get_clmyear(v_clm_no) ;
                v_reg := '^'||to_char(v_clmyear)||'|'||substr(to_char(v_clmyear),3,2); 
--                dbms_output.put_line('clmyear='||v_clmyear||' v_reg= '||v_reg);        
                v_repyr := REGEXP_REPLACE (substr(v_clm_no ,1,4), v_reg, to_char(v_clmyear)) ;
                v_repyr := v_repyr||substr(v_clm_no,5) ;  
--                dbms_output.put_line('v_repyr= '||v_repyr);  
                                
                if v_clmyear < V_FULLYR then
                    ret_clmrun := 0;
                else
--                    ret_clmrun := nvl(to_number(substr(v_clm_no ,8)),0);
                    ret_clmrun := nvl(to_number(substr(v_repyr ,10)),0);
                end if;                    
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
                
                begin 
                    select to_number(to_char(clm_rec_date,'yyyy')) clmyr into ret_clmyear
                    from fir_clm_mas
                    where clm_no = v_clm_no ;
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
                    select to_number(to_char(clm_rec_date,'yyyy')) clmyr into ret_clmyear
                    from mrn_clm_mas
                    where clm_no = v_clm_no ;
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
                    select to_number(to_char(clm_rec_date,'yyyy')) clmyr into ret_clmyear
                    from hull_clm_mas
                    where clm_no = v_clm_no ;
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

    FUNCTION mask_clmno(v_clm_no IN VARCHAR2) RETURN VARCHAR2 IS
        v_retclm    varchar2(50);
        v_clmyear   number;
        v_shortyr   number;
        v_fullyr    number;
        v_reg   varchar2(20);
        v_repyr varchar2(30);        
    BEGIN
        if v_clm_no is not null then
            begin 
                select to_number(remark) shortYR ,to_number(remark2) fullYR
                into V_SHORTYR ,V_FULLYR
                from clm_constant a
                where key = 'CLMSPLITYEAR' ;
            exception
                when no_data_found then
                    V_SHORTYR := 17;
                    V_FULLYR := 2017;
                when others then
                    V_SHORTYR := 17;
                    V_FULLYR := 2017;
            end; 
            v_clmyear := p_std_clmno.get_clmyear(v_clm_no);
            if v_clmyear >=V_FULLYR then  -- New ClmNo Format
                v_retclm := REGEXP_REPLACE (v_clm_no, '-|/', '');
                v_retclm := substr(v_retclm,1,2)||'-'||substr(v_retclm,3,5)||'-'||substr(v_retclm,8);               
                        
            else    -- Old ClmNo Format
                v_retclm := v_clm_no;
                p_claim.disp_claim(v_retclm);            
            end if;        
        else 
            v_retclm := null;
        end if;
                      

        return v_retclm;
        EXCEPTION
            WHEN OTHERS THEN
            return v_clm_no;            
    END mask_clmno ;  
      
    FUNCTION unmask_clmno(v_clm_no IN VARCHAR2) RETURN VARCHAR2 IS
        ret_clmno   varchar2(15);
    BEGIN
        ret_clmno := REGEXP_REPLACE(v_clm_no , '-|/|\', '') ;
        return ret_clmno;
        EXCEPTION
            WHEN OTHERS THEN
            return v_clm_no;            
    END unmask_clmno ;      
    
END P_STD_CLMNO;
/
