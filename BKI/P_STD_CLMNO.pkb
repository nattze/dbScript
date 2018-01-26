CREATE OR REPLACE PACKAGE BODY P_STD_CLMNO AS
/******************************************************************************
 NAME: ALLCLM.P_STD_CLMNO
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
                v_reg := '^'||to_char(v_clmyear)||'|^'||substr(to_char(v_clmyear),3,2); 
                dbms_output.put_line('clmyear='||v_clmyear||' v_reg= '||v_reg);     
                v_repyr := REGEXP_REPLACE (substr(v_clm_no ,1,4), v_reg, to_char(v_clmyear)) ;        
                v_repyr := v_repyr||substr(v_clm_no,5) ;  
                dbms_output.put_line('v_repyr= '||v_repyr);             
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
                    v_reg := '^'||to_char(v_clmyear)||'|^'||substr(to_char(v_clmyear),3,2); 
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
                v_reg := '^'||to_char(v_clmyear)||'|^'||substr(to_char(v_clmyear),3,2); 
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
                v_reg := '^'||to_char(v_clmyear)||'|^'||substr(to_char(v_clmyear),3,2); 
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

    FUNCTION unmask_clmno(v_clm_no IN VARCHAR2) RETURN VARCHAR2 IS
        ret_clmno   varchar2(15);
    BEGIN
        ret_clmno := REGEXP_REPLACE(v_clm_no , '-|/|\', '') ;
        return ret_clmno;
        EXCEPTION
            WHEN OTHERS THEN
            return v_clm_no;            
    END unmask_clmno ;      

    PROCEDURE procedure_mask_clmno 
  (   
     in_clm_no       IN varchar2,
     out_detail       OUT sys_refcursor    
  )
  IS
     x_clm_no_format varchar2(50);
  BEGIN
    
     x_clm_no_format := p_std_clmno.mask_clmno(in_clm_no);
  
  --out_detail := x_product;
  open out_detail for
   select x_clm_no_format as clm_no_format from dual;
  
  Exception
     WHEN OTHERS THEN
      --DBMS_OUTPUT.put_line('ERROR::' || SQLERRM);
      open out_detail for
   select null as clm_no_format from dual;
  
  END;

    FUNCTION get_clmyear(v_clm_no  IN VARCHAR2) RETURN NUMBER  IS
        ret_clmyear  number;
    BEGIN
        if v_clm_no is not null then
            if length(v_clm_no) <15 then
              begin 
                    select to_number(to_char(clm_date,'yyyy')) clmyr into ret_clmyear
                    from nc_mas
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
                    select to_number(to_char(clm_date,'yyyy')) clmyr into ret_clmyear
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
                v_retclm := p_std_clmno.unmask_clmno(v_clm_no); 
             if   substr(p_std_clmno.get_prodtype(v_retclm),1,1) = '3' then
                   if length(v_retclm) <= 13 then
                      v_retclm := substr(v_retclm,1,4)||'/'||substr(v_retclm,5,length(v_retclm)-4);
                   elsif length(v_retclm) > 13 then
                      v_retclm := substr(v_retclm,1,4)||'-'||substr(v_retclm,5,5)||'-'||substr(v_retclm,10,length(v_retclm)-9);
                   end if;   
             end if;  
            end if;        
        else 
            v_retclm := null;
        end if; 
        return v_retclm;
        EXCEPTION
            WHEN OTHERS THEN
            return v_clm_no;            
    END mask_clmno ;  

    FUNCTION get_prodtype(v_clm_no  IN VARCHAR2) RETURN VARCHAR2 IS
        c_prodtype  varchar2(3) := null;
    BEGIN
        if v_clm_no is not null then 

                begin 
                    select prod_type into c_prodtype
                    from nc_mas
                    where clm_no = v_clm_no;
                exception
                    when no_data_found then
                        c_prodtype  := null;
                    when others then
                        c_prodtype  := null;
                end;
                
                if c_prodtype is not null then
                    return c_prodtype;
                end if;
                        
                begin 
                    select prod_type into c_prodtype
                    from mis_clm_mas
                    where clm_no = v_clm_no;
                exception
                    when no_data_found then
                        c_prodtype  := null;
                    when others then
                        c_prodtype  := null;
                end;
                
                if c_prodtype is not null then
                    return c_prodtype;
                end if;
                
                begin 
                    select prod_type  into c_prodtype
                    from mtr_clm_tab
                    where clm_no = v_clm_no;
                exception
                    when no_data_found then
                       c_prodtype  := null;
                    when others then
                       c_prodtype  := null;
                end;

                if c_prodtype is not null then
                    return c_prodtype;
                end if;
                
                begin 
                    select prod_type into c_prodtype
                    from fir_clm_mas
                    where clm_no = v_clm_no ;
                exception
                    when no_data_found then
                        c_prodtype := null;
                    when others then
                        c_prodtype := null;
                end;

                if c_prodtype is not null  then
                    return c_prodtype;
                end if;
                
                begin 
                    select prod_type into c_prodtype
                    from mrn_clm_mas
                    where clm_no = v_clm_no ;
                exception
                    when no_data_found then
                       c_prodtype := null;
                    when others then
                       c_prodtype := null;
                end;

                if c_prodtype is not null then
                    return c_prodtype;
                end if;
                
                begin 
                    select prod_type into c_prodtype
                    from hull_clm_mas
                    where clm_no = v_clm_no ;
                exception
                    when no_data_found then
                        c_prodtype := null;
                    when others then
                        c_prodtype := null;
                end;
                                                                
                if c_prodtype is not null then
                    return c_prodtype;
                else
                    return null;
                end if;         
        else
            return null;
        end if;
        
        return c_prodtype;
        EXCEPTION
            WHEN OTHERS THEN
            return 0;            
    END get_prodtype; 
    
    FUNCTION mask_clmno_emcs(v_clm_no IN VARCHAR2) RETURN VARCHAR2 IS
        v_mask_clmno    varchar2(50);      
    BEGIN 
        
        if to_number(p_std_clmno.get_clmyear(p_std_clmno.unmask_clmno(v_clm_no))) >= '2017' then
          v_mask_clmno := p_std_clmno.mask_clmno(v_clm_no);
        else
          v_mask_clmno := p_std_clmno.unmask_clmno(v_clm_no);
        end if;
        
        return v_mask_clmno;
        
        EXCEPTION
            WHEN OTHERS THEN
            return v_clm_no;            
    END mask_clmno_emcs ;
    
END P_STD_CLMNO;
/

