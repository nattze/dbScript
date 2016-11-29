CREATE OR REPLACE PACKAGE BODY ALLCLM."WEB_CLM_PAHEALTH"  IS           
  
FUNCTION  get_policy_by_other(other_card  IN VARCHAR2, i_loss_date IN DATE) return varchar2 IS      
                v_policy_no  varchar2(30);     
  begin               
         begin      
--                         select distinct a.pol_no||a.pol_run     
--                         into v_policy_no     
--                        from mis_mas a     
--                        where  id_card  in (select  id from mis_pa_prem b     
--                                          where b.pol_no  = a.pol_no and     
--                                                b.pol_run = a.pol_run)     
--                      and  nvl(i_loss_date,trunc(sysdate)) between a.fr_date and  a.to_date        
--                      -- and a.end_seq = 0;      
--                      and ((end_Seq = 0 and renewed is null) or (renewed = 'X' and nvl(ren_time,0)>0));     
  
                        select distinct(pol_no||pol_run)  
                        into v_policy_no      
                        from mis_pa_prem a  
                        where other = other_card  
                        and i_loss_date   between a.fr_date and  a.to_date   ;      
                                                 
         exception        
                   when others then        
                        v_policy_no :=  null;       
         end;     
         return (v_policy_no);      
  end;   
         
  Function  get_policy_by_id(id_card  IN VARCHAR2, i_loss_date IN DATE) return varchar2 IS             
                v_policy_no  varchar2(30);            
  begin                      
         begin             
--                         select distinct a.pol_no||a.pol_run          
--                         into v_policy_no          
--                        from mis_mas a          
--                        where  id_card  in (select  id from mis_pa_prem b          
--                                          where b.pol_no  = a.pol_no and          
--                                                b.pol_run = a.pol_run)          
--                      and  nvl(i_loss_date,trunc(sysdate)) between a.fr_date and  a.to_date             
--                      -- and a.end_seq = 0;           
--                      and ((end_Seq = 0 and renewed is null) or (renewed = 'X' and nvl(ren_time,0)>0));          
       
                        select distinct(pol_no||pol_run)       
                        into v_policy_no           
                        from mis_pa_prem a       
                        where id = id_card       
                        and i_loss_date   between a.fr_date and  a.to_date  and cancel is null ;              
                                
         exception               
                   when others then               
                        v_policy_no :=  null;              
         end;            
         return (v_policy_no);             
  end;          
  
 FUNCTION  get_count_policy_by_other (other_card  IN VARCHAR2, i_loss_date IN DATE )   RETURN NUMBER is      
            v_cnt       number;      
  begin               
         begin      
--                        select count(distinct a.pol_no||a.pol_run)     
--                        into v_cnt      
--                        from mis_mas a     
--                        where  id_card  in (select  id from mis_pa_prem b     
--                                                      where b.pol_no  = a.pol_no and     
--                                                                b.pol_run = a.pol_run)     
--                      and  nvl(i_loss_date,trunc(sysdate)) between a.fr_date and  a.to_date        
--                      -- and a.end_seq = 0;      
--                      and ((end_Seq = 0 and renewed is null) or (renewed = 'X' and nvl(ren_time,0)>0));     
                        select count(distinct(pol_no||pol_run))  
                        into v_cnt      
                        from mis_pa_prem a  
                        where other = other_card  
                        and i_loss_date   between a.fr_date and  a.to_date  and cancel is null ;                      
         exception        
                   when others then        
                        v_cnt := 1;       
         end;     
         return (v_cnt);      
  end;    
                                                    
  FUNCTION  get_count_policy_by_id (id_card  IN VARCHAR2, i_loss_date IN DATE )   RETURN NUMBER is           
            v_cnt       number;           
  begin                    
         begin           
--                        select count(distinct a.pol_no||a.pol_run)          
--                        into v_cnt           
--                        from mis_mas a          
--                        where  id_card  in (select  id from mis_pa_prem b          
--                                                      where b.pol_no  = a.pol_no and          
--                                                                b.pol_run = a.pol_run)          
--                      and  nvl(i_loss_date,trunc(sysdate)) between a.fr_date and  a.to_date             
--                      -- and a.end_seq = 0;           
--                      and ((end_Seq = 0 and renewed is null) or (renewed = 'X' and nvl(ren_time,0)>0));          
                        select count(distinct(pol_no||pol_run))       
                        into v_cnt           
                        from mis_pa_prem a       
                        where id = id_card       
                        and i_loss_date   between a.fr_date and  a.to_date   and cancel is null  ;                           
         exception             
                   when others then             
                        v_cnt := 1;            
         end;          
         return (v_cnt);           
  end;         
                          
  PROCEDURE get_policy_by_id (id_card  IN VARCHAR2,  i_loss_date IN DATE ,            
              o_cursor_pol  OUT sys_refcursor) IS             
                                          
  BEGIN                          
                                    
      open o_cursor_pol for               
        select distinct a.pol_no||a.pol_run policy_no ,fleet_seq ,recpt_seq ,id,title||' '||name||surname cust_name --,fr_date ,to_date ,cancel ,prem_code6 ,sum_ins6           
        , (select c.prod_type||'-'||c.name_th from prod_type_std c where c.prod_type = a.prod_type)  prod_type            
        from mis_pa_prem a           
        where            
        id = id_card           
        and i_loss_date between fr_date and to_date           
--        and (pol_no,pol_run) in (           
--        select x.pol_no ,x.pol_run from mis_mas x           
--        where ((end_Seq = 0 and renewed is null) or (renewed = 'X' and nvl(ren_time,0)>0))           
--        )           
        and a.recpt_seq in (select b.recpt_seq from mis_pa_prem b             
                       where b.pol_no  = a.pol_no and            
                             b.pol_run = a.pol_run and              
                             i_loss_date between b.fr_date and b.to_date and            
                             id = id_card and rownum = 1) and cancel is null;           
  END;            
  
  PROCEDURE get_policy_by_other   
 (other_card IN VARCHAR2,   
 i_loss_date IN DATE ,   
 o_cursor_pol OUT sys_refcursor) IS   
   
 BEGIN   
   
     open o_cursor_pol for   
     select distinct a.pol_no||a.pol_run policy_no ,fleet_seq ,recpt_seq ,id,other,title||' '||name||surname cust_name --,fr_date ,to_date ,cancel ,prem_code6 ,sum_ins6  
     , (select c.prod_type||'-'||c.name_th from prod_type_std c where c.prod_type = a.prod_type) prod_type   
     from mis_pa_prem a  
     where   
     other = other_card  
     and i_loss_date between fr_date and to_date  
--     and (pol_no,pol_run) in (  
--     select x.pol_no ,x.pol_run from mis_mas x  
--     where ((end_Seq = 0 and renewed is null) or (renewed = 'X' and nvl(ren_time,0)>0))  
--     )  
     and a.recpt_seq in (select b.recpt_seq from mis_pa_prem b   
     where b.pol_no = a.pol_no and   
     b.pol_run = a.pol_run and   
     i_loss_date between b.fr_date and b.to_date and   
     other = other_card and rownum = 1) ;  
 END;   
   
  PROCEDURE get_policy_other  
 (  
 in_policy_no IN varchar2,  
 in_fleet_seq IN Number,  
 in_recpt_seq IN Number,  
 in_id_no IN varchar2,  
 in_other_no IN varchar2,  
 in_loss_date IN varchar2, --5  
 out_name OUT varchar2,  
 out_fr_date OUT date,  
 out_to_date OUT date,  
 out_status OUT varchar2,  
 out_pd_grp OUT varchar2, --10  
 out_txt_remark OUT varchar2,  
 out_cursor OUT pahealth_cursor,   
 out_cursor_name OUT sys_refcursor,  
 out_cursor_policy OUT sys_refcursor,  
 x_result OUT varchar2 --15  
 ) IS  
 x_pol_no MIS_PA_PREM.Pol_no%type;  
 x_pol_run MIS_PA_PREM.Pol_run%type;  
 x_type varchar2(2);  
 x_name1 varchar2(100);  
 x_name2 varchar2(200);  
 x_cnt number;  
 x_cnt_name number;  
 x_recpt_seq mis_pa_prem.recpt_seq%type;  
 x_policy_no varchar2(30);  
 x_loss_date date;  
 x_is_tele varchar2(5);  
 x_tot_prem pa_patn.tot_prem%type;   
 cursor_name ALLCLM.web_clm_pahealth.sys_refcursor;  
 x_tmp_remark varchar2(500);  
 x_sql4mc varchar2(2000);  
   
 x_fleet_seq number;  
 TYPE t_data_name IS RECORD  
 (  
 name varchar2(1000),  
 fleet_seq number,  
 recpt_seq number  
 );   
 rec1 t_data_name;  
   
 c2 HEALTHUTIL.sys_refcursor;  
 TYPE t_data2 IS RECORD  
 (  
 ID_CARD VARCHAR2(30),  
 CUS_NAME VARCHAR2(200),  
 PREM NUMBER,  
 fr_date date,  
 to_date date  
 );   
 j_rec2 t_data2;  
   
 x_other_no varchar2(30);  
 --x_loss_date date;  
 BEGIN  
 x_other_no := in_other_no;  
 x_policy_no := in_policy_no;  
 x_loss_date := to_date(in_loss_date,'dd/mm/rrrr');  
 --????? ????? procedure get_count_policy_by_other  
 x_cnt := web_clm_pahealth.get_count_policy_by_other(in_other_no,x_loss_date);  
 if x_cnt > 1 then  
           --Get list of name_cover  
           --x_test := WEB_CLM_PAHEALTH.get_policy_by_other(in_other_no,x_loss_date);  
           WEB_CLM_PAHEALTH.get_policy_by_other(in_other_no,x_loss_date,out_cursor_policy);  
           open out_cursor for  
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
           open out_cursor_name for  
                select null name,null fleet_seq,null recpt_seq from dual;  
           return;  
        else   
           x_policy_no := web_clm_pahealth.get_policy_by_other(in_other_no,x_loss_date);  
              
          
        end if;  
      
      
    if x_type is null then     
        p_acc_package.read_pol(x_policy_no,x_pol_no,x_pol_run); --separate in_policy_no into x_pol_no,x_pol_run  
        MISC.HEALTHUTIL.get_pa_health_type(x_pol_no,x_pol_run,x_type); --Get type  
        MISC.HEALTHUTIL.get_is_tele(x_pol_no,x_pol_run,x_is_tele); --Get Is tele == 'Y'  
        out_pd_grp := substr(x_type,1,1);  
    end if;  
      
    dbms_output.put_line('x_type='||x_type);  
      
    if x_type in ('PI','PG') then -- check is disallow for open claim e.g. CTA  
        if nc_health_package.is_disallow_policy(x_pol_no,x_pol_run) then  
             x_type := 'XX' ;  
        end if;      
        if nc_health_package.is_watchlist_policy(x_pol_no,x_pol_run) then  
             x_type := 'XY' ;   -- return status ?????????  
        end if;              
          
    end if;  
      
--    if x_type = 'XX' then --error  
    if x_type in ('XX' ,'XY') then --error or watchlist  
        x_result := x_type;  
        open out_cursor for  
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
        open out_cursor_name for  
             select null name,null fleet_seq,null recpt_seq from dual;  
        open out_cursor_policy for  
             select null policy_no,null prod_type from dual;    
    elsif x_type in ('PI','HI') and in_fleet_seq <> 0 then  
        x_result := 'NO'; --Invalid Critiria  
        open out_cursor for  
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
        open out_cursor_name for  
             select null name,null fleet_seq,null recpt_seq from dual;  
        open out_cursor_policy for  
             select null policy_no,null prod_type from dual;  
    elsif x_type = 'B' then --Bancas  
        out_status := 'Y';      
        out_pd_grp := 'B';  
          
        open out_cursor_name for  
             select null name,null fleet_seq,null recpt_seq from dual;  
        open out_cursor_policy for  
             select null policy_no,null prod_type from dual;          
    elsif x_type in ('PG','PI') and  in_other_no is not null and x_cnt = 1 then -- case search ID get one result  
        begin  
            select fleet_seq ,recpt_seq  
            into x_fleet_seq ,x_recpt_seq  
            from mis_pa_prem a  
            where pol_no =x_pol_no  
            and pol_run=x_pol_run  
            and x_loss_date  between fr_date and to_date  
            and other = in_other_no  
            and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run  
            and x_loss_date between aa.fr_date and aa.to_date and other= in_other_no)      ;    
        exception  
        when no_data_found then  
            x_fleet_seq := in_fleet_seq;  
        when others then  
            x_fleet_seq := in_fleet_seq;  
        end;      
      
--        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,x_fleet_seq,x_loss_date,cursor_name);  
--        fetch cursor_name into rec1;  
--        x_recpt_seq := rec1.recpt_seq;  
--        close cursor_name;  
        --Get Name, fr_date, to_date  
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);  
        if x_name2 is not null then  
           out_name := x_name1||' ('||x_name2||')';   
        else    
           out_name := x_name1;   
        end if;  
        --Get Status           
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,out_status);  
        --Get Coverage  
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);  
        if out_pd_grp <> 'H' then  
           web_clm_pahealth.claim_coverage(x_policy_no,x_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim  
        end if;  
--        open out_cursor_name for  
--             select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;  
--        open out_cursor_policy for  
--             select x_policy_no policy_no,null prod_type from dual;      
  
        open out_cursor_name for  
             select title||' '||name||' '||surname name, fleet_seq, recpt_seq   
            from mis_pa_prem a  
            where pol_no =x_pol_no  
            and pol_run=x_pol_run  
            and x_loss_date  between fr_date and to_date  
            and other = in_other_no  
            and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run  
            and x_loss_date between aa.fr_date and aa.to_date and other= in_other_no) ;   
        open out_cursor_policy for  
             select pol_no||pol_run policy_no ,prod_type  
            from mis_pa_prem a  
            where pol_no =x_pol_no  
            and pol_run=x_pol_run  
            and x_loss_date  between fr_date and to_date  
            and other = in_other_no  
            and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run  
            and x_loss_date between aa.fr_date and aa.to_date and other= in_other_no) ;                
                               
    elsif x_type in ('PG','HG') and in_fleet_seq = 0 then --For x_type = PG or HG and user didn't key a fleet_seq  
             if MISC.HEALTHUTIL.get_type_family(x_pol_no,x_pol_run) then --For Telemarketing  
                --Get list of name_cover  
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);  
                open out_cursor for  
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
                open out_cursor_policy for  
                     select x_policy_no policy_no,null prod_type from dual;                
             else --Not Telemarketing  
                x_result := 'NO';  
                open out_cursor for  
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
                open out_cursor_name for  
                     select null name,null fleet_seq,null recpt_seq from dual;  
                open out_cursor_policy for  
                     select x_policy_no policy_no,null prod_type from dual;  
             end if;  
    elsif x_type in ('PI','HI') and x_is_tele = 'Y' then --For Telemarketing  
        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);  
        fetch cursor_name into rec1;  
        x_recpt_seq := rec1.recpt_seq;  
        close cursor_name;  
        --Get Name, fr_date, to_date  
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);  
        if x_name2 is not null then  
           out_name := x_name1||' ('||x_name2||')';   
        else    
           out_name := x_name1;   
        end if;  
        --Get Status           
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);  
        --Get Coverage  
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);  
        if out_pd_grp <> 'H' then  
           web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim  
        end if;  
        open out_cursor_name for  
             select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;  
        open out_cursor_policy for  
             select x_policy_no policy_no,null prod_type from dual;  
    else   
        x_cnt_name := MISC.HEALTHUTIL.get_count_name(x_pol_no,x_pol_run,in_fleet_seq); --Count name records  
        if in_recpt_seq <> 0 then --Chosen name  
           --set x_cnt_name when in_recpt_seq is sent by web  
           x_cnt_name := 1;  
        end if;  
        if x_cnt_name > 1 then  
           --Get list of name_cover  
           MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);  
           open out_cursor for  
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;    
           open out_cursor_policy for  
                select x_policy_no policy_no,null prod_type from dual;           
        else  
            --Set Default in_recpt_seq  
            if in_recpt_seq = 0 then   
                --x_recpt_seq := 1;  
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);  
                fetch cursor_name into rec1;  
                x_recpt_seq := rec1.recpt_seq;  
                close cursor_name;  
            else              
--                x_recpt_seq := in_recpt_seq;  -- get recpt_seq  
                begin  
                    select recpt_seq   
                    into x_recpt_seq  
                    from mis_pa_prem a  
                    where pol_no =x_pol_no  
                    and pol_run=x_pol_run  
                    and x_loss_date  between fr_date and to_date  
                    and fleet_seq = in_fleet_seq  
                    and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run  
                    and x_loss_date between aa.fr_date and aa.to_date and fleet_seq = in_fleet_seq )  and rownum=1    ;    
                exception  
                when no_data_found then  
                    x_recpt_seq := in_recpt_seq;  
                when others then  
                    x_recpt_seq := in_recpt_seq;  
                end;      
      
            end if;  
            --Get Name, fr_date, to_date  
            MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);  
            if x_name2 is not null then  
               out_name := x_name1||' ('||x_name2||')';   
            else    
               out_name := x_name1;   
            end if;  
            --Get Status           
            MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);  
            --Get Coverage  
            MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);  
            if out_pd_grp <> 'H' then  
               web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim  
            end if;  
            open out_cursor_name for  
                 --select null name,null fleet_seq,null recpt_seq from dual;  
                 select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;  
            open out_cursor_policy for  
                 select x_policy_no policy_no,null prod_type from dual;  
        end if;  
     end if;  
     if MISC.HEALTHUTIL.is_45plus(x_pol_no,x_pol_run) then  
        out_txt_remark := MISC.HEALTHUTIL.get_benefit_card_45plus(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq);  
     else  
        out_txt_remark := '';  
     end if;  
     if x_type = 'B' then --Bancas  
        dbms_output.put_line('x_sql4mc='||x_sql4mc);  
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_sql4mc,x_tmp_remark);  
     elsif out_pd_grp = 'P' then --PA  
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_pol_no,x_pol_run,in_fleet_seq,x_tmp_remark);  
     end if;  
     out_txt_remark := out_txt_remark||x_tmp_remark||'<br />';  
  EXCEPTION  
    WHEN OTHERS THEN  
      x_result := SQLERRM;    
  END get_policy_other;   
         
 PROCEDURE get_policy_data         
 (         
 in_policy_no IN varchar2,         
 in_fleet_seq IN Number,         
 in_recpt_seq IN Number,         
 in_id_no IN varchar2,         
 in_loss_date IN varchar2, --5         
 out_name OUT varchar2,         
 out_fr_date OUT date,         
 out_to_date OUT date,         
 out_status OUT varchar2,         
 out_pd_grp OUT varchar2, --10         
 out_txt_remark OUT varchar2,         
 out_cursor OUT pahealth_cursor,          
 out_cursor_name OUT sys_refcursor,         
 out_cursor_policy OUT sys_refcursor,         
 x_result OUT varchar2 --15         
 ) IS         
 x_pol_no MIS_PA_PREM.Pol_no%type;         
 x_pol_run MIS_PA_PREM.Pol_run%type;         
 x_type varchar2(2);         
 x_name1 varchar2(100);         
 x_name2 varchar2(200);         
 x_cnt number;         
 x_cnt_name number;         
 x_recpt_seq mis_pa_prem.recpt_seq%type;         
 x_policy_no varchar2(30);         
 x_loss_date date;         
 x_is_tele varchar2(5);         
 x_tot_prem pa_patn.tot_prem%type;          
 cursor_name ALLCLM.web_clm_pahealth.sys_refcursor;         
 x_tmp_remark varchar2(500);         
 x_sql4mc varchar2(2000);         
          
 x_fleet_seq number;         
 TYPE t_data_name IS RECORD         
 (         
 name varchar2(1000),         
 fleet_seq number,         
 recpt_seq number         
 );          
 rec1 t_data_name;         
          
 c2 HEALTHUTIL.sys_refcursor;         
 TYPE t_data2 IS RECORD         
 (         
 ID_CARD VARCHAR2(30),         
 CUS_NAME VARCHAR2(200),         
 PREM NUMBER,         
 fr_date date,         
 to_date date         
 );          
 j_rec2 t_data2;         
          
 BEGIN         
 x_policy_no := in_policy_no;         
 x_loss_date := to_date(in_loss_date,'dd/mm/rrrr');         
 if x_policy_no is null and in_id_no is not null then --- Case search by ID card          
 x_cnt := web_clm_pahealth.get_count_policy_by_id(in_id_no,x_loss_date);         
 if x_cnt > 1 then         
           --Get list of name_cover         
           WEB_CLM_PAHEALTH.get_policy_by_id(in_id_no,x_loss_date,out_cursor_policy);         
           open out_cursor for         
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;         
           open out_cursor_name for         
                select null name,null fleet_seq,null recpt_seq from dual;         
           return;         
        elsif x_cnt = 1 then         
           x_policy_no := web_clm_pahealth.get_policy_by_id(in_id_no,x_loss_date);         
        else --Checking for Bancas         
           x_cnt := MISC.HEALTHUTIL.get_count_policy_by_id_bancas(in_id_no,x_loss_date); --         
           if x_cnt > 0 then         
              begin         
                  MISC.HEALTHUTIL.GET_POLICY_BY_ID_BANCAS(in_id_no,x_loss_date,c2);         
                  FETCH  c2 INTO j_rec2;         
                      x_tot_prem := j_rec2.PREM ; --Choose First Record           
                      out_name := j_rec2.cus_name ;             
                      out_fr_date := j_rec2.fr_date;         
                      out_to_date := j_rec2.to_date;         
              exception         
                  when others then         
                       x_tot_prem := 0;         
                       x_type := 'XX'; --Not Found         
              end;         
              close c2;         
                       
              if x_tot_prem > 0 then         
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor);         
                 x_sql4mc := web_clm_pahealth.get_sql4mc(out_cursor);         
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor);         
                 web_clm_pahealth.claim_coverage(in_id_no,in_fleet_seq,in_recpt_seq,out_cursor,out_cursor); --get premcode that can claim         
                 x_type := 'B'; --Bancas         
              end if;         
           else         
              x_type := 'XX'; --Not Found         
           end if;         
        end if;         
    end if;          
             
    if x_type is null then            
        p_acc_package.read_pol(x_policy_no,x_pol_no,x_pol_run); --separate in_policy_no into x_pol_no,x_pol_run         
        MISC.HEALTHUTIL.get_pa_health_type(x_pol_no,x_pol_run,x_type); --Get type         
        MISC.HEALTHUTIL.get_is_tele(x_pol_no,x_pol_run,x_is_tele); --Get Is tele == 'Y'         
        out_pd_grp := substr(x_type,1,1);         
    end if;         
             
    dbms_output.put_line('x_type='||x_type);         
             
    if x_type in ('PI','PG') then -- check is disallow for open claim e.g. CTA      
        if nc_health_package.is_disallow_policy(x_pol_no,x_pol_run) then      
             x_type := 'XX' ;      
        end if;          
        if nc_health_package.is_watchlist_policy(x_pol_no,x_pol_run) then      
             x_type := 'XY' ;   -- return status ????????      
        end if;                  
              
    end if;      
          
--    if x_type = 'XX' then --error      
    if x_type in ('XX' ,'XY') then --error or watchlist      
        x_result := x_type;         
        open out_cursor for         
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;         
        open out_cursor_name for         
             select null name,null fleet_seq,null recpt_seq from dual;         
        open out_cursor_policy for         
             select null policy_no,null prod_type from dual;           
    elsif x_type in ('PI','HI') and in_fleet_seq <> 0 then         
        x_result := 'NO'; --Invalid Critiria         
        open out_cursor for         
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;         
        open out_cursor_name for         
             select null name,null fleet_seq,null recpt_seq from dual;         
        open out_cursor_policy for         
             select null policy_no,null prod_type from dual;         
    elsif x_type = 'B' then --Bancas         
        out_status := 'Y';             
        out_pd_grp := 'B';         
                 
        open out_cursor_name for         
             select null name,null fleet_seq,null recpt_seq from dual;         
        open out_cursor_policy for         
             select null policy_no,null prod_type from dual;                 
    elsif x_type in ('PG','PI') and  in_id_no is not null and x_cnt = 1 then -- case search ID get one result         
        begin         
            select distinct fleet_seq ,recpt_seq         
            into x_fleet_seq ,x_recpt_seq         
            from mis_pa_prem a         
            where pol_no =x_pol_no         
            and pol_run=x_pol_run         
            and x_loss_date  between fr_date and to_date         
            and id = in_id_no         
            and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run         
            and x_loss_date between aa.fr_date and aa.to_date and id= in_id_no) and cancel is null     ;           
        exception         
        when no_data_found then         
            x_fleet_seq := in_fleet_seq;         
        when others then         
            x_fleet_seq := in_fleet_seq;         
        end;             
             
--        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,x_fleet_seq,x_loss_date,cursor_name);         
--        fetch cursor_name into rec1;         
--        x_recpt_seq := rec1.recpt_seq;         
--        close cursor_name;         
        --Get Name, fr_date, to_date         
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);         
        if x_name2 is not null then         
           out_name := x_name1||' ('||x_name2||')';          
        else           
           out_name := x_name1;          
        end if;         
        --Get Status                  
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,out_status);         
        --Get Coverage         
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);         
        if out_pd_grp <> 'H' then         
           web_clm_pahealth.claim_coverage(x_policy_no,x_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim         
        end if;         
--        open out_cursor_name for         
--             select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;         
--        open out_cursor_policy for         
--             select x_policy_no policy_no,null prod_type from dual;             
         
        open out_cursor_name for         
             select distinct title||' '||name||' '||surname name, fleet_seq, recpt_seq          
            from mis_pa_prem a         
            where pol_no =x_pol_no         
            and pol_run=x_pol_run         
            and x_loss_date  between fr_date and to_date         
            and id = in_id_no         
            and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run         
            and x_loss_date between aa.fr_date and aa.to_date and id= in_id_no) and cancel is null ;          
        open out_cursor_policy for         
             select distinct pol_no||pol_run policy_no ,prod_type         
            from mis_pa_prem a         
            where pol_no =x_pol_no         
            and pol_run=x_pol_run         
            and x_loss_date  between fr_date and to_date         
            and id = in_id_no         
            and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run         
            and x_loss_date between aa.fr_date and aa.to_date and id= in_id_no) and cancel is null ;                       
                                      
    elsif x_type in ('PG','HG') and in_fleet_seq = 0 then --For x_type = PG or HG and user didn't key a fleet_seq         
             if MISC.HEALTHUTIL.get_type_family(x_pol_no,x_pol_run) then --For Telemarketing         
                --Get list of name_cover         
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);         
                open out_cursor for         
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;         
                open out_cursor_policy for         
                     select x_policy_no policy_no,null prod_type from dual;                       
             else --Not Telemarketing         
                x_result := 'NO';         
                open out_cursor for         
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;         
                open out_cursor_name for         
                     select null name,null fleet_seq,null recpt_seq from dual;         
                open out_cursor_policy for         
                     select x_policy_no policy_no,null prod_type from dual;         
             end if;         
    elsif x_type in ('PI','HI') and x_is_tele = 'Y' then --For Telemarketing         
        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);         
        fetch cursor_name into rec1;         
        x_recpt_seq := rec1.recpt_seq;         
        close cursor_name;         
        --Get Name, fr_date, to_date         
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);         
        if x_name2 is not null then         
           out_name := x_name1||' ('||x_name2||')';          
        else           
           out_name := x_name1;          
        end if;         
        --Get Status                  
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);         
        --Get Coverage         
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);         
        if out_pd_grp <> 'H' then         
           web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim         
        end if;         
        open out_cursor_name for         
             select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;         
        open out_cursor_policy for         
             select x_policy_no policy_no,null prod_type from dual;         
    else          
        x_cnt_name := MISC.HEALTHUTIL.get_count_name(x_pol_no,x_pol_run,in_fleet_seq); --Count name records         
        if in_recpt_seq <> 0 then --Chosen name         
           --set x_cnt_name when in_recpt_seq is sent by web         
           x_cnt_name := 1;         
        end if;         
        if x_cnt_name > 1 then         
           --Get list of name_cover         
           MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);         
           open out_cursor for         
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;           
           open out_cursor_policy for         
                select x_policy_no policy_no,null prod_type from dual;                  
        else         
            --Set Default in_recpt_seq         
            if in_recpt_seq = 0 then          
                --x_recpt_seq := 1;         
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);         
                fetch cursor_name into rec1;         
                x_recpt_seq := rec1.recpt_seq;         
                close cursor_name;         
            else                     
--                x_recpt_seq := in_recpt_seq;  -- get recpt_seq         
                begin         
                    select distinct recpt_seq          
                    into x_recpt_seq         
                    from mis_pa_prem a         
                    where pol_no =x_pol_no         
                    and pol_run=x_pol_run         
                    and x_loss_date  between fr_date and to_date         
                    and fleet_seq = in_fleet_seq         
                    and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run         
                    and x_loss_date between aa.fr_date and aa.to_date and fleet_seq = in_fleet_seq )  and rownum=1    ;           
                exception         
                when no_data_found then         
                    x_recpt_seq := in_recpt_seq;         
                when others then         
                    x_recpt_seq := in_recpt_seq;         
                end;             
             
            end if;         
            --Get Name, fr_date, to_date         
            MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);         
            if x_name2 is not null then         
               out_name := x_name1||' ('||x_name2||')';          
            else           
               out_name := x_name1;          
            end if;         
            --Get Status                   
            MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);         
            --Get Coverage         
            MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);         
            if out_pd_grp <> 'H' then         
               web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim         
            end if;         
            open out_cursor_name for         
                 --select null name,null fleet_seq,null recpt_seq from dual;         
                 select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;         
            open out_cursor_policy for         
                 select x_policy_no policy_no,null prod_type from dual;         
        end if;         
     end if;         
     if MISC.HEALTHUTIL.is_45plus(x_pol_no,x_pol_run) then         
        out_txt_remark := MISC.HEALTHUTIL.get_benefit_card_45plus(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq);         
     else         
        out_txt_remark := '';         
     end if;         
     if x_type = 'B' then --Bancas         
        dbms_output.put_line('x_sql4mc='||x_sql4mc);         
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_sql4mc,x_tmp_remark);         
     elsif out_pd_grp = 'P' then --PA         
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_pol_no,x_pol_run,in_fleet_seq,x_tmp_remark);         
     end if;         
     out_txt_remark := out_txt_remark||x_tmp_remark||'<br />';         
  EXCEPTION         
    WHEN OTHERS THEN         
      x_result := SQLERRM;           
  END get_policy_data;          
  
 PROCEDURE get_policy_data  
 (  
 in_policy_no IN varchar2,  
 in_fleet_seq IN Number,  
 in_recpt_seq IN Number,  
 in_id_no IN varchar2,  
 in_other_no IN varchar2,  
 in_loss_date IN varchar2, --5  
 out_name OUT varchar2,  
 out_fr_date OUT date,  
 out_to_date OUT date,  
 out_status OUT varchar2,  
 out_pd_grp OUT varchar2, --10  
 out_txt_remark OUT varchar2,  
 out_cursor OUT pahealth_cursor,   
 out_cursor_name OUT sys_refcursor,  
 out_cursor_policy OUT sys_refcursor,  
 x_result OUT varchar2 --15  
 ) IS  
 x_pol_no MIS_PA_PREM.Pol_no%type;  
 x_pol_run MIS_PA_PREM.Pol_run%type;  
 x_type varchar2(2);  
 x_name1 varchar2(100);  
 x_name2 varchar2(200);  
 x_cnt number;  
 x_cnt_name number;  
 x_recpt_seq mis_pa_prem.recpt_seq%type;  
 x_policy_no varchar2(30);  
 x_loss_date date;  
 x_is_tele varchar2(5);  
 x_tot_prem pa_patn.tot_prem%type;   
 cursor_name ALLCLM.web_clm_pahealth.sys_refcursor;  
 x_tmp_remark varchar2(500);  
 x_sql4mc varchar2(2000);  
   
 x_fleet_seq number;  
 TYPE t_data_name IS RECORD  
 (  
 name varchar2(1000),  
 fleet_seq number,  
 recpt_seq number  
 );   
 rec1 t_data_name;  
   
 c2 HEALTHUTIL.sys_refcursor;  
 TYPE t_data2 IS RECORD  
 (  
 ID_CARD VARCHAR2(30),  
 CUS_NAME VARCHAR2(200),  
 PREM NUMBER,  
 fr_date date,  
 to_date date  
 );   
 j_rec2 t_data2;  
   
 BEGIN  
 x_policy_no := in_policy_no;  
 x_loss_date := to_date(in_loss_date,'dd/mm/rrrr');  
 if x_policy_no is null and in_id_no is not null then --- Case search by ID card   
 x_cnt := web_clm_pahealth.get_count_policy_by_id(in_id_no,x_loss_date);  
 if x_cnt > 1 then  
           --Get list of name_cover  
           WEB_CLM_PAHEALTH.get_policy_by_id(in_id_no,x_loss_date,out_cursor_policy);  
           open out_cursor for  
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
           open out_cursor_name for  
                select null name,null fleet_seq,null recpt_seq from dual;  
           return;  
        elsif x_cnt = 1 then  
           x_policy_no := web_clm_pahealth.get_policy_by_id(in_id_no,x_loss_date);  
        else --Checking for Bancas  
           x_cnt := MISC.HEALTHUTIL.get_count_policy_by_id_bancas(in_id_no,x_loss_date); --  
           if x_cnt > 0 then  
              begin  
                  MISC.HEALTHUTIL.GET_POLICY_BY_ID_BANCAS(in_id_no,x_loss_date,c2);  
                  FETCH  c2 INTO j_rec2;  
                      x_tot_prem := j_rec2.PREM ; --Choose First Record    
                      out_name := j_rec2.cus_name ;      
                      out_fr_date := j_rec2.fr_date;  
                      out_to_date := j_rec2.to_date;  
              exception  
                  when others then  
                       x_tot_prem := 0;  
                       x_type := 'XX'; --Not Found  
              end;  
              close c2;  
                
              if x_tot_prem > 0 then  
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor);  
                 x_sql4mc := web_clm_pahealth.get_sql4mc(out_cursor);  
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor);  
                 web_clm_pahealth.claim_coverage(in_id_no,in_fleet_seq,in_recpt_seq,out_cursor,out_cursor); --get premcode that can claim  
                 x_type := 'B'; --Bancas  
              end if;  
           else  
              x_type := 'XX'; --Not Found  
           end if;  
        end if;  
    end if;   
      
    if x_type is null then     
        p_acc_package.read_pol(x_policy_no,x_pol_no,x_pol_run); --separate in_policy_no into x_pol_no,x_pol_run  
        MISC.HEALTHUTIL.get_pa_health_type(x_pol_no,x_pol_run,x_type); --Get type  
        MISC.HEALTHUTIL.get_is_tele(x_pol_no,x_pol_run,x_is_tele); --Get Is tele == 'Y'  
        out_pd_grp := substr(x_type,1,1);  
    end if;  
      
    dbms_output.put_line('x_type='||x_type);  
      
    if x_type in ('PI','PG') then -- check is disallow for open claim e.g. CTA  
        if nc_health_package.is_disallow_policy(x_pol_no,x_pol_run) then  
             x_type := 'XX' ;  
        end if;      
        if nc_health_package.is_watchlist_policy(x_pol_no,x_pol_run) then  
             x_type := 'XY' ;   -- return status ?????????  
        end if;              
          
    end if;  
      
--    if x_type = 'XX' then --error  
    if x_type in ('XX' ,'XY') then --error or watchlist  
        x_result := x_type;  
        open out_cursor for  
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
        open out_cursor_name for  
             select null name,null fleet_seq,null recpt_seq from dual;  
        open out_cursor_policy for  
             select null policy_no,null prod_type from dual;    
    elsif x_type in ('PI','HI') and in_fleet_seq <> 0 then  
        x_result := 'NO'; --Invalid Critiria  
        open out_cursor for  
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
        open out_cursor_name for  
             select null name,null fleet_seq,null recpt_seq from dual;  
        open out_cursor_policy for  
             select null policy_no,null prod_type from dual;  
    elsif x_type = 'B' then --Bancas  
        out_status := 'Y';      
        out_pd_grp := 'B';  
          
        open out_cursor_name for  
             select null name,null fleet_seq,null recpt_seq from dual;  
        open out_cursor_policy for  
             select null policy_no,null prod_type from dual;          
    elsif x_type in ('PG','PI') and  in_id_no is not null and x_cnt = 1 then -- case search ID get one result  
        begin  
            select distinct fleet_seq ,recpt_seq  
            into x_fleet_seq ,x_recpt_seq  
            from mis_pa_prem a  
            where pol_no =x_pol_no  
            and pol_run=x_pol_run  
            and x_loss_date  between fr_date and to_date  
            and id = in_id_no  
            and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run  
            and x_loss_date between aa.fr_date and aa.to_date and id= in_id_no)      
            and cancel is null;    
        exception  
        when no_data_found then  
            x_fleet_seq := in_fleet_seq;  
        when others then  
            x_fleet_seq := in_fleet_seq;  
        end;      
      
--        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,x_fleet_seq,x_loss_date,cursor_name);  
--        fetch cursor_name into rec1;  
--        x_recpt_seq := rec1.recpt_seq;  
--        close cursor_name;  
        --Get Name, fr_date, to_date  
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);  
        if x_name2 is not null then  
           out_name := x_name1||' ('||x_name2||')';   
        else    
           out_name := x_name1;   
        end if;  
        --Get Status           
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,out_status);  
        --Get Coverage  
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);  
        if out_pd_grp <> 'H' then  
           web_clm_pahealth.claim_coverage(x_policy_no,x_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim  
        end if;  
--        open out_cursor_name for  
--             select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;  
--        open out_cursor_policy for  
--             select x_policy_no policy_no,null prod_type from dual;      
  
        open out_cursor_name for  
             select distinct title||' '||name||' '||surname name, fleet_seq, recpt_seq   
            from mis_pa_prem a  
            where pol_no =x_pol_no  
            and pol_run=x_pol_run  
            and x_loss_date  between fr_date and to_date  
            and id = in_id_no  
            and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run  
            and x_loss_date between aa.fr_date and aa.to_date and id= in_id_no)  and cancel is null;   
        open out_cursor_policy for  
             select distinct pol_no||pol_run policy_no ,prod_type  
            from mis_pa_prem a  
            where pol_no =x_pol_no  
            and pol_run=x_pol_run  
            and x_loss_date  between fr_date and to_date  
            and id = in_id_no  
            and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run  
            and x_loss_date between aa.fr_date and aa.to_date and id= in_id_no)  and cancel is null;                
                               
    elsif x_type in ('PG','HG') and in_fleet_seq = 0 then --For x_type = PG or HG and user didn't key a fleet_seq  
             if MISC.HEALTHUTIL.get_type_family(x_pol_no,x_pol_run) then --For Telemarketing  
                --Get list of name_cover  
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);  
                open out_cursor for  
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
                open out_cursor_policy for  
                     select x_policy_no policy_no,null prod_type from dual;                
             else --Not Telemarketing  
                x_result := 'NO';  
                open out_cursor for  
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
                open out_cursor_name for  
                     select null name,null fleet_seq,null recpt_seq from dual;  
                open out_cursor_policy for  
                     select x_policy_no policy_no,null prod_type from dual;  
             end if;  
    elsif x_type in ('PI','HI') and x_is_tele = 'Y' then --For Telemarketing  
        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);  
        fetch cursor_name into rec1;  
        x_recpt_seq := rec1.recpt_seq;  
        close cursor_name;  
        --Get Name, fr_date, to_date  
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);  
        if x_name2 is not null then  
           out_name := x_name1||' ('||x_name2||')';   
        else    
           out_name := x_name1;   
        end if;  
        --Get Status           
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);  
        --Get Coverage  
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);  
        if out_pd_grp <> 'H' then  
           web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim  
        end if;  
        open out_cursor_name for  
             select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;  
        open out_cursor_policy for  
             select x_policy_no policy_no,null prod_type from dual;  
    else   
        x_cnt_name := MISC.HEALTHUTIL.get_count_name(x_pol_no,x_pol_run,in_fleet_seq); --Count name records  
        if in_recpt_seq <> 0 then --Chosen name  
           --set x_cnt_name when in_recpt_seq is sent by web  
           x_cnt_name := 1;  
        end if;  
        if x_cnt_name > 1 then  
           --Get list of name_cover  
           MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);  
           open out_cursor for  
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;    
           open out_cursor_policy for  
                select x_policy_no policy_no,null prod_type from dual;           
        else  
            --Set Default in_recpt_seq  
            if in_recpt_seq = 0 then   
                --x_recpt_seq := 1;  
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);  
                fetch cursor_name into rec1;  
                x_recpt_seq := rec1.recpt_seq;  
                close cursor_name;  
            else              
--                x_recpt_seq := in_recpt_seq;  -- get recpt_seq  
                begin  
                    select distinct recpt_seq   
                    into x_recpt_seq  
                    from mis_pa_prem a  
                    where pol_no =x_pol_no  
                    and pol_run=x_pol_run  
                    and x_loss_date  between fr_date and to_date  
                    and fleet_seq = in_fleet_seq  
                    and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run  
                    and x_loss_date between aa.fr_date and aa.to_date and fleet_seq = in_fleet_seq )  and rownum=1    ;    
                exception  
                when no_data_found then  
                    x_recpt_seq := in_recpt_seq;  
                when others then  
                    x_recpt_seq := in_recpt_seq;  
                end;      
      
            end if;  
            --Get Name, fr_date, to_date  
            MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);  
            if x_name2 is not null then  
               out_name := x_name1||' ('||x_name2||')';   
            else    
               out_name := x_name1;   
            end if;  
            --Get Status           
            MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);  
            --Get Coverage  
            MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);  
            if out_pd_grp <> 'H' then  
               web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim  
            end if;  
            open out_cursor_name for  
                 --select null name,null fleet_seq,null recpt_seq from dual;  
                 select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;  
            open out_cursor_policy for  
                 select x_policy_no policy_no,null prod_type from dual;  
        end if;  
     end if;  
     if MISC.HEALTHUTIL.is_45plus(x_pol_no,x_pol_run) then  
        out_txt_remark := MISC.HEALTHUTIL.get_benefit_card_45plus(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq);  
     else  
        out_txt_remark := '';  
     end if;  
     if x_type = 'B' then --Bancas  
        dbms_output.put_line('x_sql4mc='||x_sql4mc);  
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_sql4mc,x_tmp_remark);  
     elsif out_pd_grp = 'P' then --PA  
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_pol_no,x_pol_run,in_fleet_seq,x_tmp_remark);  
     end if;  
     out_txt_remark := out_txt_remark||x_tmp_remark||'<br />';  
  EXCEPTION  
    WHEN OTHERS THEN  
      x_result := SQLERRM;    
  END get_policy_data;   
             
  PROCEDURE web_pahealth_details         
  (         
    in_policy_no          IN varchar2,         
    in_fleet_seq          IN Number,         
    in_recpt_seq          IN Number,         
    in_id_no              IN varchar2,         
    in_loss_date          IN varchar2, --5         
    out_name              OUT varchar2,         
    out_fr_date           OUT date,         
    out_to_date           OUT date,         
    out_status            OUT varchar2,         
    out_pd_grp            OUT varchar2, --10         
    out_txt_remark        OUT varchar2,         
    out_cursor            OUT pahealth_cursor,          
    out_cursor_name       OUT sys_refcursor,         
    out_cursor_policy     OUT sys_refcursor,         
    x_result              OUT varchar2 --15         
  ) IS         
  x_pol_no  MIS_PA_PREM.Pol_no%type;         
  x_pol_run  MIS_PA_PREM.Pol_run%type;         
  x_type     varchar2(2);         
  x_name1             varchar2(100);         
  x_name2             varchar2(200);         
  x_cnt               number;         
  x_cnt_name          number;         
  x_recpt_seq         mis_pa_prem.recpt_seq%type;         
  x_policy_no         varchar2(30);         
  x_loss_date         date;         
  x_is_tele           varchar2(5);         
  x_tot_prem          pa_patn.tot_prem%type;          
  cursor_name         web_clm_pahealth.sys_refcursor;         
  x_tmp_remark        varchar2(500);         
  x_sql4mc            varchar2(2000);         
           
  x_fleet_seq   number;         
  TYPE t_data_name IS RECORD         
    (         
    name           varchar2(1000),         
    fleet_seq      number,         
    recpt_seq      number         
    );          
    rec1 t_data_name;         
             
  c2   HEALTHUTIL.sys_refcursor;         
  TYPE t_data2 IS RECORD         
  (         
  ID_CARD    VARCHAR2(30),         
  CUS_NAME   VARCHAR2(200),         
  PREM       NUMBER,         
  fr_date  date,         
  to_date  date         
  );          
  j_rec2 t_data2;         
           
  BEGIN         
    x_policy_no := in_policy_no;         
    x_loss_date := to_date(in_loss_date,'dd/mm/rrrr');         
    if x_policy_no is null and in_id_no is not null then                 
        x_cnt := MISC.HEALTHUTIL.get_count_policy_by_id(in_id_no,x_loss_date);         
        if x_cnt > 1 then         
           --Get list of name_cover         
           MISC.HEALTHUTIL.get_policy_by_id(in_id_no,x_loss_date,out_cursor_policy);         
           open out_cursor for         
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;         
           open out_cursor_name for         
                select null name,null fleet_seq,null recpt_seq from dual;         
           return;         
        elsif x_cnt = 1 then         
           x_policy_no := MISC.HEALTHUTIL.get_policy_by_id(in_id_no,x_loss_date);         
        else --Checking for Bancas         
           x_cnt := MISC.HEALTHUTIL.get_count_policy_by_id_bancas(in_id_no,x_loss_date); --         
           if x_cnt > 0 then         
              begin         
                  MISC.HEALTHUTIL.GET_POLICY_BY_ID_BANCAS(in_id_no,x_loss_date,c2);         
                  FETCH  c2 INTO j_rec2;         
                      x_tot_prem := j_rec2.PREM ; --Choose First Record           
                      out_name := j_rec2.cus_name ;             
                      out_fr_date := j_rec2.fr_date;         
                      out_to_date := j_rec2.to_date;         
              exception         
                  when others then         
                       x_tot_prem := 0;         
                       x_type := 'XX'; --Not Found         
              end;         
              close c2;         
                       
              if x_tot_prem > 0 then         
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor);         
                 x_sql4mc := web_clm_pahealth.get_sql4mc(out_cursor);         
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor);         
                 web_clm_pahealth.claim_coverage(in_id_no,in_fleet_seq,in_recpt_seq,out_cursor,out_cursor); --get premcode that can claim         
                 x_type := 'B'; --Bancas         
              end if;         
           else         
              x_type := 'XX'; --Not Found         
           end if;         
        end if;         
    end if;          
             
    if x_type is null then            
        p_acc_package.read_pol(x_policy_no,x_pol_no,x_pol_run); --separate in_policy_no into x_pol_no,x_pol_run         
        MISC.HEALTHUTIL.get_pa_health_type(x_pol_no,x_pol_run,x_type); --Get type         
        MISC.HEALTHUTIL.get_is_tele(x_pol_no,x_pol_run,x_is_tele); --Get Is tele == 'Y'         
        out_pd_grp := substr(x_type,1,1);         
    end if;         
             
    dbms_output.put_line('x_type='||x_type);         
             
    if x_type in ('PI','PG') then -- check is disallow for open claim e.g. CTA      
        if nc_health_package.is_disallow_policy(x_pol_no,x_pol_run) then      
             x_type := 'XX' ;      
        end if;          
        if nc_health_package.is_watchlist_policy(x_pol_no,x_pol_run) then      
             x_type := 'XY' ;   -- return status ????????      
        end if;                  
              
    end if;      
          
--    if x_type = 'XX' then --error      
    if x_type in ('XX' ,'XY') then --error or watchlist      
        x_result := x_type;         
        open out_cursor for         
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;         
        open out_cursor_name for         
             select null name,null fleet_seq,null recpt_seq from dual;         
        open out_cursor_policy for         
             select null policy_no,null prod_type from dual;           
    elsif x_type in ('PI','HI') and in_fleet_seq >1 then         
        x_result := 'NO'; --Invalid Critiria         
        open out_cursor for         
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;         
        open out_cursor_name for         
             select null name,null fleet_seq,null recpt_seq from dual;         
        open out_cursor_policy for         
             select null policy_no,null prod_type from dual;         
    elsif x_type = 'B' then --Bancas         
        out_status := 'Y';             
        out_pd_grp := 'B';         
                 
        open out_cursor_name for         
             select null name,null fleet_seq,null recpt_seq from dual;         
        open out_cursor_policy for         
             select null policy_no,null prod_type from dual;                 
    elsif x_type in ('PG','PI') and  in_id_no is not null and x_cnt = 1 then -- case search ID get one result         
        begin         
            select distinct fleet_seq ,recpt_seq   
            into x_fleet_seq ,x_recpt_seq   
            from mis_pa_prem a   
            where pol_no =x_pol_no   
            and pol_run=x_pol_run   
            and x_loss_date  between fr_date and to_date   
            and id = in_id_no and a.cancel is null   
            and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run   
            and x_loss_date between aa.fr_date and aa.to_date and id= in_id_no and aa.cancel is null)      ;        
        exception         
        when no_data_found then         
            x_fleet_seq := in_fleet_seq;         
        when others then         
            x_fleet_seq := in_fleet_seq;         
        end;             
             
--        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,x_fleet_seq,x_loss_date,cursor_name);         
--        fetch cursor_name into rec1;         
--        x_recpt_seq := rec1.recpt_seq;         
--        close cursor_name;         
        --Get Name, fr_date, to_date         
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);         
        if x_name2 is not null then         
           out_name := x_name1||' ('||x_name2||')';          
        else           
           out_name := x_name1;          
        end if;         
        --Get Status                  
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,out_status);         
        --Get Coverage         
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);         
        if out_pd_grp <> 'H' then         
           web_clm_pahealth.claim_coverage(x_policy_no,x_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim         
        end if;         
        open out_cursor_name for         
             select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;         
        open out_cursor_policy for         
             select x_policy_no policy_no,null prod_type from dual;                                
    elsif x_type in ('PG','HG') and in_fleet_seq = 0 then --For x_type = PG or HG and user didn't key a fleet_seq         
             if MISC.HEALTHUTIL.get_type_family(x_pol_no,x_pol_run) then --For Telemarketing         
                --Get list of name_cover         
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);         
                open out_cursor for         
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;         
                open out_cursor_policy for         
                     select x_policy_no policy_no,null prod_type from dual;           
             else --Not Telemarketing         
                x_result := 'NO';         
                open out_cursor for         
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;         
                open out_cursor_name for         
                     select null name,null fleet_seq,null recpt_seq from dual;         
                open out_cursor_policy for         
                     select x_policy_no policy_no,null prod_type from dual;         
             end if;         
    elsif x_type in ('PI','HI') and x_is_tele = 'Y' then --For Telemarketing         
        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);         
        fetch cursor_name into rec1;         
        x_recpt_seq := rec1.recpt_seq;         
        close cursor_name;         
        --Get Name, fr_date, to_date         
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);         
        if x_name2 is not null then         
           out_name := x_name1||' ('||x_name2||')';          
        else           
           out_name := x_name1;          
        end if;         
        --Get Status                  
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);         
        --Get Coverage         
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);         
        if out_pd_grp <> 'H' then         
           web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim         
        end if;         
        open out_cursor_name for         
             select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;         
        open out_cursor_policy for         
             select x_policy_no policy_no,null prod_type from dual;         
    else          
        x_cnt_name := MISC.HEALTHUTIL.get_count_name(x_pol_no,x_pol_run,in_fleet_seq); --Count name records         
        if in_recpt_seq <> 0 then --Chosen name         
           --set x_cnt_name when in_recpt_seq is sent by web         
           x_cnt_name := 1;         
        end if;         
        if x_cnt_name > 1 then         
           --Get list of name_cover         
           MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);         
           open out_cursor for         
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;           
           open out_cursor_policy for         
                select x_policy_no policy_no,null prod_type from dual;                  
        else         
            --Set Default in_recpt_seq         
            if in_recpt_seq = 0 then          
                --x_recpt_seq := 1;         
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);         
                fetch cursor_name into rec1;         
                x_recpt_seq := rec1.recpt_seq;         
                if in_fleet_seq = 0 then       
                    x_fleet_seq := rec1.fleet_seq;       
                end if;                           
                close cursor_name;         
            else                     
--                x_recpt_seq := in_recpt_seq;  -- get recpt_seq         
                if x_type in ('PI') then         
                    begin         
                        select recpt_seq          
                        into x_recpt_seq         
                        from mis_pa_prem a         
                        where pol_no =x_pol_no         
                        and pol_run=x_pol_run         
                        and x_loss_date  between fr_date and to_date         
                        and fleet_seq = in_fleet_seq         
                        and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run         
                        and x_loss_date between aa.fr_date and aa.to_date and fleet_seq = in_fleet_seq )  and rownum=1    ;           
                    exception         
                    when no_data_found then         
                        x_recpt_seq := in_recpt_seq;         
                    when others then         
                        x_recpt_seq := in_recpt_seq;         
                    end;             
                else --- Group policy get recpt from input         
                    x_recpt_seq := in_recpt_seq;         
                    x_fleet_seq := in_fleet_seq;         
                end if;         
            end if;         
            --Get Name, fr_date, to_date         
            MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);         
            if x_name2 is not null then         
               out_name := x_name1||' ('||x_name2||')';          
            else           
               out_name := x_name1;          
            end if;         
            --Get Status                  
            MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);         
            --Get Coverage         
            MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);         
            if out_pd_grp <> 'H' then         
               web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim         
            end if;         
            open out_cursor_name for         
                 --select null name,null fleet_seq,null recpt_seq from dual;         
--                 select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;         
                 select out_name name,nvl(x_fleet_seq,in_fleet_seq) fleet_seq,x_recpt_seq recpt_seq from dual;         
            open out_cursor_policy for         
                 select x_policy_no policy_no,null prod_type from dual;         
        end if;         
     end if;         
     if MISC.HEALTHUTIL.is_45plus(x_pol_no,x_pol_run) then         
        out_txt_remark := MISC.HEALTHUTIL.get_benefit_card_45plus(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq);         
     else         
        out_txt_remark := '';         
     end if;         
     if x_type = 'B' then --Bancas         
        dbms_output.put_line('x_sql4mc='||x_sql4mc);         
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_sql4mc,x_tmp_remark);         
     elsif out_pd_grp = 'P' then --PA         
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_pol_no,x_pol_run,in_fleet_seq,x_tmp_remark);         
     end if;         
     out_txt_remark := out_txt_remark||x_tmp_remark||'<br />';         
  EXCEPTION         
    WHEN OTHERS THEN         
      x_result := SQLERRM;           
  END web_pahealth_details;          
                           
  
  PROCEDURE web_pahealth_details  
  (  
    in_policy_no          IN varchar2,  
    in_fleet_seq          IN Number,  
    in_recpt_seq          IN Number,  
    in_id_no              IN varchar2,  
    in_other_no         IN varchar2,  
    in_loss_date          IN varchar2, --5  
    out_name              OUT varchar2,  
    out_fr_date           OUT date,  
    out_to_date           OUT date,  
    out_status            OUT varchar2,  
    out_pd_grp            OUT varchar2, --10  
    out_txt_remark        OUT varchar2,  
    out_cursor            OUT pahealth_cursor,   
    out_cursor_name       OUT sys_refcursor,  
    out_cursor_policy     OUT sys_refcursor,  
    x_result              OUT varchar2 --15  
  ) IS  
  x_pol_no  MIS_PA_PREM.Pol_no%type;  
  x_pol_run  MIS_PA_PREM.Pol_run%type;  
  x_type     varchar2(2);  
  x_name1             varchar2(100);  
  x_name2             varchar2(200);  
  x_cnt               number;  
  x_cnt_name          number;  
  x_recpt_seq         mis_pa_prem.recpt_seq%type;  
  x_policy_no         varchar2(30);  
  x_loss_date         date;  
  x_is_tele           varchar2(5);  
  x_tot_prem          pa_patn.tot_prem%type;   
  cursor_name         web_clm_pahealth.sys_refcursor;  
  x_tmp_remark        varchar2(500);  
  x_sql4mc            varchar2(2000);  
    
  x_fleet_seq   number;  
  TYPE t_data_name IS RECORD  
    (  
    name           varchar2(1000),  
    fleet_seq      number,  
    recpt_seq      number  
    );   
    rec1 t_data_name;  
      
  c2   HEALTHUTIL.sys_refcursor;  
  TYPE t_data2 IS RECORD  
  (  
  ID_CARD    VARCHAR2(30),  
  CUS_NAME   VARCHAR2(200),  
  PREM       NUMBER,  
  fr_date  date,  
  to_date  date  
  );   
  j_rec2 t_data2;  
    
  BEGIN  
    x_policy_no := in_policy_no;  
    x_loss_date := to_date(in_loss_date,'dd/mm/rrrr');  
    if x_policy_no is null and in_id_no is not null then          
        x_cnt := MISC.HEALTHUTIL.get_count_policy_by_id(in_id_no,x_loss_date);  
        if x_cnt > 1 then  
           --Get list of name_cover  
           MISC.HEALTHUTIL.get_policy_by_id(in_id_no,x_loss_date,out_cursor_policy);  
           open out_cursor for  
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
           open out_cursor_name for  
                select null name,null fleet_seq,null recpt_seq from dual;  
           return;  
        elsif x_cnt = 1 then  
           x_policy_no := MISC.HEALTHUTIL.get_policy_by_id(in_id_no,x_loss_date);  
        else --Checking for Bancas  
           x_cnt := MISC.HEALTHUTIL.get_count_policy_by_id_bancas(in_id_no,x_loss_date); --  
           if x_cnt > 0 then  
              begin  
                  MISC.HEALTHUTIL.GET_POLICY_BY_ID_BANCAS(in_id_no,x_loss_date,c2);  
                  FETCH  c2 INTO j_rec2;  
                      x_tot_prem := j_rec2.PREM ; --Choose First Record    
                      out_name := j_rec2.cus_name ;      
                      out_fr_date := j_rec2.fr_date;  
                      out_to_date := j_rec2.to_date;  
              exception  
                  when others then  
                       x_tot_prem := 0;  
                       x_type := 'XX'; --Not Found  
              end;  
              close c2;  
                
              if x_tot_prem > 0 then  
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor);  
                 x_sql4mc := web_clm_pahealth.get_sql4mc(out_cursor);  
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor);  
                 web_clm_pahealth.claim_coverage(in_id_no,in_fleet_seq,in_recpt_seq,out_cursor,out_cursor); --get premcode that can claim  
                 x_type := 'B'; --Bancas  
              end if;  
           else  
              x_type := 'XX'; --Not Found  
           end if;  
        end if;  
    end if;   
      
    if x_type is null then     
        p_acc_package.read_pol(x_policy_no,x_pol_no,x_pol_run); --separate in_policy_no into x_pol_no,x_pol_run  
        MISC.HEALTHUTIL.get_pa_health_type(x_pol_no,x_pol_run,x_type); --Get type  
        MISC.HEALTHUTIL.get_is_tele(x_pol_no,x_pol_run,x_is_tele); --Get Is tele == 'Y'  
        out_pd_grp := substr(x_type,1,1);  
    end if;  
      
    dbms_output.put_line('x_type='||x_type);  
      
    if x_type in ('PI','PG') then -- check is disallow for open claim e.g. CTA  
        if nc_health_package.is_disallow_policy(x_pol_no,x_pol_run) then  
             x_type := 'XX' ;  
        end if;      
        if nc_health_package.is_watchlist_policy(x_pol_no,x_pol_run) then  
             x_type := 'XY' ;   -- return status ?????????  
        end if;              
          
    end if;  
      
--    if x_type = 'XX' then --error  
    if x_type in ('XX' ,'XY') then --error or watchlist  
        x_result := x_type;  
        open out_cursor for  
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
        open out_cursor_name for  
             select null name,null fleet_seq,null recpt_seq from dual;  
        open out_cursor_policy for  
             select null policy_no,null prod_type from dual;    
    elsif x_type in ('PI','HI') and in_fleet_seq >1 then  
        x_result := 'NO'; --Invalid Critiria  
        open out_cursor for  
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
        open out_cursor_name for  
             select null name,null fleet_seq,null recpt_seq from dual;  
        open out_cursor_policy for  
             select null policy_no,null prod_type from dual;  
    elsif x_type = 'B' then --Bancas  
        out_status := 'Y';      
        out_pd_grp := 'B';  
          
        open out_cursor_name for  
             select null name,null fleet_seq,null recpt_seq from dual;  
        open out_cursor_policy for  
             select null policy_no,null prod_type from dual;          
    elsif x_type in ('PG','PI') and  in_id_no is not null and x_cnt = 1 then -- case search ID get one result  
        begin  
            select distinct fleet_seq ,recpt_seq  
            into x_fleet_seq ,x_recpt_seq  
            from mis_pa_prem a  
            where pol_no =x_pol_no  
            and pol_run=x_pol_run  
            and x_loss_date  between fr_date and to_date  
            and id = in_id_no and a.cancel is null  
            and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run  
            and x_loss_date between aa.fr_date and aa.to_date and id= in_id_no and aa.cancel is null)      ;    
        exception  
        when no_data_found then  
            x_fleet_seq := in_fleet_seq;  
        when others then  
            x_fleet_seq := in_fleet_seq;  
        end;      
        dbms_output.put_line('pol='||x_pol_no||x_pol_run||' fleet='||x_fleet_seq||' x_recpt='||x_recpt_seq);  
--        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,x_fleet_seq,x_loss_date,cursor_name);  
--        fetch cursor_name into rec1;  
--        x_recpt_seq := rec1.recpt_seq;  
--        close cursor_name;  
        --Get Name, fr_date, to_date  
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);  
        if x_name2 is not null then  
           out_name := x_name1||' ('||x_name2||')';   
        else    
           out_name := x_name1;   
        end if;  
        --Get Status           
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,out_status);  
        --Get Coverage  
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);  
        if out_pd_grp <> 'H' then  
           web_clm_pahealth.claim_coverage(x_policy_no,x_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim  
        end if;  
        open out_cursor_name for  
             select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;  
        open out_cursor_policy for  
             select x_policy_no policy_no,null prod_type from dual;                         
    elsif x_type in ('PG','HG') and in_fleet_seq = 0 then --For x_type = PG or HG and user didn't key a fleet_seq  
             if MISC.HEALTHUTIL.get_type_family(x_pol_no,x_pol_run) then --For Telemarketing  
                --Get list of name_cover  
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);  
                open out_cursor for  
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
                open out_cursor_policy for  
                     select x_policy_no policy_no,null prod_type from dual;    
             else --Not Telemarketing  
                x_result := 'NO';  
                open out_cursor for  
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;  
                open out_cursor_name for  
                     select null name,null fleet_seq,null recpt_seq from dual;  
                open out_cursor_policy for  
                     select x_policy_no policy_no,null prod_type from dual;  
             end if;  
    elsif x_type in ('PI','HI') and x_is_tele = 'Y' then --For Telemarketing  
        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);  
        fetch cursor_name into rec1;  
        x_recpt_seq := rec1.recpt_seq;  
        close cursor_name;  
        --Get Name, fr_date, to_date  
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);  
        if x_name2 is not null then  
           out_name := x_name1||' ('||x_name2||')';   
        else    
           out_name := x_name1;   
        end if;  
        --Get Status           
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);  
        --Get Coverage  
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);  
        if out_pd_grp <> 'H' then  
           web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim  
        end if;  
        open out_cursor_name for  
             select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;  
        open out_cursor_policy for  
             select x_policy_no policy_no,null prod_type from dual;  
    else   
        x_cnt_name := MISC.HEALTHUTIL.get_count_name(x_pol_no,x_pol_run,in_fleet_seq); --Count name records  
        if in_recpt_seq <> 0 then --Chosen name  
           --set x_cnt_name when in_recpt_seq is sent by web  
           x_cnt_name := 1;  
        end if;  
        if x_cnt_name > 1 then  
           --Get list of name_cover  
           MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);  
           open out_cursor for  
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;    
           open out_cursor_policy for  
                select x_policy_no policy_no,null prod_type from dual;           
        else  
            --Set Default in_recpt_seq  
            if in_recpt_seq = 0 then   
                --x_recpt_seq := 1;  
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);  
                fetch cursor_name into rec1;  
                x_recpt_seq := rec1.recpt_seq;  
                if in_fleet_seq = 0 then  
                    x_fleet_seq := rec1.fleet_seq;  
                end if;      
                close cursor_name;  
            else              
--                x_recpt_seq := in_recpt_seq;  -- get recpt_seq  
                if x_type in ('PI') then  
                    begin  
                        select recpt_seq   
                        into x_recpt_seq  
                        from mis_pa_prem a  
                        where pol_no =x_pol_no  
                        and pol_run=x_pol_run  
                        and x_loss_date  between fr_date and to_date  
                        and fleet_seq = in_fleet_seq  
                        and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run  
                        and x_loss_date between aa.fr_date and aa.to_date and fleet_seq = in_fleet_seq )  and rownum=1    ;    
                    exception  
                    when no_data_found then  
                        x_recpt_seq := in_recpt_seq;  
                    when others then  
                        x_recpt_seq := in_recpt_seq;  
                    end;      
                else --- Group policy get recpt from input  
                    x_recpt_seq := in_recpt_seq;  
                    x_fleet_seq := in_fleet_seq;  
                end if;  
            end if;  
            --Get Name, fr_date, to_date  
            MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);  
            if x_name2 is not null then  
               out_name := x_name1||' ('||x_name2||')';   
            else    
               out_name := x_name1;   
            end if;  
            --Get Status           
            MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);  
            --Get Coverage  
            MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);  
            if out_pd_grp <> 'H' then  
               web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim  
            end if;  
            open out_cursor_name for  
                 --select null name,null fleet_seq,null recpt_seq from dual;  
--                 select null name,null fleet_seq,x_recpt_seq recpt_seq from dual;  
                 select out_name name,nvl(x_fleet_seq,in_fleet_seq) fleet_seq,x_recpt_seq recpt_seq from dual;  
            open out_cursor_policy for  
                 select x_policy_no policy_no,null prod_type from dual;  
        end if;  
     end if;  
     if MISC.HEALTHUTIL.is_45plus(x_pol_no,x_pol_run) then  
        out_txt_remark := MISC.HEALTHUTIL.get_benefit_card_45plus(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq);  
     else  
        out_txt_remark := '';  
     end if;  
     if x_type = 'B' then --Bancas  
        dbms_output.put_line('x_sql4mc='||x_sql4mc);  
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_sql4mc,x_tmp_remark);  
     elsif out_pd_grp = 'P' then --PA  
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_pol_no,x_pol_run,in_fleet_seq,x_tmp_remark);  
     end if;  
     out_txt_remark := out_txt_remark||x_tmp_remark||'<br />';  
  EXCEPTION  
    WHEN OTHERS THEN  
      x_result := SQLERRM;    
  END web_pahealth_details;   
    
 FUNCTION get_help1            
  RETURN VARCHAR2           
  IS           
  tmp      varchar2(2000);                          
  BEGIN           
    select P_MM_PACKAGE.GET_MM_URL('1', '6', 'CLM', 'HELP', 'BKI_MED')           
    into tmp           
    from dual;           
               
    RETURN tmp;           
  EXCEPTION           
    WHEN OTHERS THEN           
      RETURN null;           
  END get_help1;            
             
  FUNCTION get_help1(in_type IN varchar2)           
  RETURN VARCHAR2           
  IS           
  tmp      varchar2(2000):= '';                          
  BEGIN           
    if in_type = 'ENQ' then           
        select P_MM_PACKAGE.GET_MM_URL('1', '6', 'CLM', 'HELP', 'BKI_MED')           
        into tmp           
        from dual;           
    elsif in_type = 'H_TAB' then           
--        select P_MM_PACKAGE.GET_MM_URL('1', '6', 'CLM', 'HELP2', 'BKI_MED')           
--        into tmp           
--        from dual;           
        select P_MM_PACKAGE.GET_MM_URL('1', '6', 'CLM', 'HELP', 'BKI_MED')           
        into tmp           
        from dual;                
    elsif in_type = 'QST' then           
        select P_MM_PACKAGE.GET_MM_URL('1', '6', 'CLM', 'QST', 'BKI_MED')           
        into tmp           
        from dual;           
    elsif in_type = 'BROKER' then           
        select P_MM_PACKAGE.GET_MM_URL('1', '6', 'CLM', 'HELPBRK', 'BKI_MED')           
        into tmp           
        from dual;           
    end if;           
           
    RETURN tmp;           
  EXCEPTION           
    WHEN OTHERS THEN           
      RETURN null;           
  END get_help1;           
             
  PROCEDURE get_status            
  (           
    in_type               IN varchar2,           
    in_hpt_code           IN varchar2,           
    out_cursor            OUT sys_refcursor           
  ) IS           
  BEGIN           
    if in_type = 'HOS1' then           
       open out_cursor for           
            select a.key,a.remark,           
            web_clm_pahealth.get_tot_rec_sts(in_hpt_code,a.key) total            
            from clm_constant a           
            where key like '%MEDST%'           
            and a.remark3 = 'H'           
            order by a.key;           
    elsif in_type = 'HOS_T3' then           
       open out_cursor for           
            select a.key,a.remark,2 seq from clm_constant a           
            where key in ('MEDSTS00','MEDSTS02','MEDSTS11','MEDSTS21','MEDSTS31')           
            union           
            select '' key,'??????' remark,1 seq from dual           
            order by seq,key;           
    elsif in_type = 'BKI' then           
       open out_cursor for           
            select a.key,a.remark,a.remark2,1 total from clm_constant a           
            where key like '%MEDST%'           
            and a.remark3 in ('B','H')           
            order by a.key;           
    elsif in_type = 'BROKER' then           
       open out_cursor for           
            select a.key,a.remark,2 seq from clm_constant a           
            where key in ('MEDSTS11','MEDSTS12','MEDSTS21','MEDSTS31','MEDSTS32')           
            union           
            select '' key,'??????' remark,1 seq from dual           
            order by seq,key;           
    end if;           
  EXCEPTION           
    WHEN OTHERS THEN           
      if in_type = 'HOS1' then           
         open out_cursor for           
              select null key,null remark,0 total from dual;           
      elsif in_type = 'HOS_T3' then           
          open out_cursor for           
              select null key,null remark from dual;            
      elsif in_type = 'BKI' then           
         open out_cursor for           
              select null key,null remark,null remark2,0 total from dual;           
      end if;           
  END get_status;           
             
  FUNCTION get_desease            
  (           
    in_dis_code               IN varchar2           
  )RETURN VARCHAR2 IS           
     cDis_text DIS_CODE_STD.Dis_Text%type := null;           
  BEGIN           
    SELECT DIS_TEXT           
    INTO cDis_text           
    FROM DIS_CODE_STD           
    WHERE TH_ENG = 'E'           
    AND   DIS_CODE = in_dis_code;           
    return cDis_text;           
  EXCEPTION           
    WHEN OTHERS THEN           
       return cDis_text;           
  END get_desease;           
             
  PROCEDURE get_desease            
  (           
    in_dis_code               IN varchar2,           
    in_dis_text               IN varchar2,           
    out_cursor            OUT sys_refcursor           
  ) IS           
  BEGIN           
   open out_cursor for           
            SELECT dis_code,dis_text FROM DIS_CODE_STD           
            WHERE TH_ENG = 'E'           
            AND (in_dis_code is null or (in_dis_code is not null and DIS_CODE like '%'||in_dis_code||'%'))           
            AND (in_dis_text is null or (in_dis_text is not null and DIS_TEXT like '%'||in_dis_text||'%'))           
            ORDER BY DIS_CODE;           
  EXCEPTION           
    WHEN OTHERS THEN           
       open out_cursor for           
            select null dis_code,null dis_text from dual;           
  END get_desease;           
             
  FUNCTION get_url_upload_file           
  (           
    in_type    IN varchar2,           
    in_sts_key IN NUMBER,           
    in_user_id IN varchar2           
  )RETURN VARCHAR2           
  IS           
  tmp      varchar2(2000);                          
  BEGIN           
    -- '20' for Medical Claim           
    -- in_type (3 = lite all, 4 = lite except delete)           
--    select P_MM_PACKAGE.GET_MM_URL(in_type,'20',in_user_id,in_sts_key)           
--    into tmp           
--    from dual;           
    tmp :=    P_MM_PACKAGE.GET_MM_URL(in_type,'20',in_user_id,in_sts_key) ;        
            
    RETURN tmp;           
  EXCEPTION           
    WHEN OTHERS THEN           
      RETURN null;           
  END get_url_upload_file;           
             
  PROCEDURE insert_nc_master_tmp           
  (           
    in_out_sts_key  IN OUT number,           
    in_invoice      IN varchar2,           
    in_clm_type     IN varchar2,           
    in_policy_no    IN varchar2,           
    in_fleet_seq    IN number,           
    in_name         IN varchar2,           
    in_surname      IN varchar2,           
    in_hn           IN varchar2,           
    in_icd10        IN varchar2,           
    in_cause_code   IN varchar2,           
    in_risk_desc    IN varchar2,           
    in_loss_date    IN varchar2,           
    in_fr_loss_date IN varchar2,           
    in_to_loss_date IN varchar2,           
    in_hpt_code     IN varchar2,           
    in_day          IN number,           
    in_hpt_user     IN varchar2,           
    in_recpt_seq    IN number,           
    in_evn_desc     IN varchar2,           
    in_id_no        IN varchar2,           
    in_remark       IN varchar2,           
    in_sid          IN varchar2,           
    in_clm_no       IN varchar2,           
    in_grp_seq      IN varchar2,           
    x_result        OUT varchar2           
  ) IS           
  tmpCnt  varchar2(1);           
  BEGIN           
    if in_out_sts_key = 0 then           
      in_out_sts_key := NC_HEALTH_PACKAGE.GEN_STSKEY('');           
    end if;           
               
    begin           
      select '1'            
      into tmpCnt           
      from nc_master_tmp           
      where sts_key = in_out_sts_key;           
    exception           
       when others then           
            tmpCnt := '0';           
    end;           
               
    if tmpCnt = '1' then           
       delete from nc_master_tmp           
       where sts_key = in_out_sts_key;           
    end if;           
               
    insert into nc_master_tmp            
    (           
    sts_key,           
    invoice,           
    clm_type,           
    policy_no,           
    fleet_seq,           
    name,           
    surname,           
    hn,           
    icd10,           
    cause_code,           
    risk_desc,           
    loss_date,           
    fr_loss_date,           
    to_loss_date,           
    hpt_code,           
    day,           
    hpt_user,           
    recpt_seq,           
    evn_desc,           
    id_no,           
    remark,           
    sub_cause_code,           
    sid,           
    clm_no,           
    grp_seq           
    )           
    values           
    (           
    in_out_sts_key,           
    in_invoice,           
    in_clm_type,           
    in_policy_no,           
    in_fleet_seq,           
    in_name,           
    in_surname,           
    in_hn,           
    in_icd10,           
    (select risk_code from MED_RISK_STD where med_risk_code =in_cause_code),           
    in_risk_desc,           
    in_loss_date,           
    in_fr_loss_date,           
    in_to_loss_date,           
    in_hpt_code,           
    in_day,           
    in_hpt_user,           
    in_recpt_seq,           
    in_evn_desc,           
    in_id_no,           
    in_remark,           
    in_cause_code,           
    to_number(in_sid),           
    in_clm_no,           
    to_number(in_grp_seq)           
    );                
  EXCEPTION           
    WHEN OTHERS THEN           
      x_result := SQLERRM;           
  END insert_nc_master_tmp;           
             
  PROCEDURE insert_nc_detail_tmp           
  (           
    in_sts_key          IN number,           
    in_premcode         IN varchar2,           
    in_request_amt      IN number,           
    in_remain_amt       IN number,           
    x_result            OUT varchar2           
  ) IS           
  BEGIN           
    insert into nc_detail_tmp            
    (           
    sts_key,           
    premcode,           
    request_amt,           
    remain_amt           
    )           
    values           
    (           
    in_sts_key,           
    in_premcode,           
    in_request_amt,           
    in_remain_amt           
    );                   
  EXCEPTION           
    WHEN OTHERS THEN           
      x_result := SQLERRM;           
  END insert_nc_detail_tmp;           
             
  PROCEDURE search_sts_by_hpt           
  (           
    in_hn_no          IN varchar2,           
    in_name           IN varchar2,           
    in_inv_no         IN varchar2,           
    in_loss_Date_fr   IN varchar2,           
    in_loss_Date_to   IN varchar2,           
    in_status         IN varchar2,           
    in_user_id        IN varchar2,           
    out_cursor        OUT sys_refcursor,           
    x_result          OUT varchar2           
  )           
  IS           
  BEGIN           
    open out_cursor for           
      select a.sts_key,a.invoice_no inv_no,a.clm_no,to_char(a.tr_date_fr,'dd/mm/yyyy') loss_date,a.hn_no,a.mas_cus_name name,           
      (select sum(res_amt) from nc_reserved r where r.sts_key = a.sts_key) res_amt,           
      (select NC_HEALTH_PACKAGE.get_clm_status_desc(NC_HEALTH_PACKAGE.get_clm_status(a.clm_no), 0)  sts_clm           
      from dual) status,           
      nc_health_package.get_med_remark(a.sts_key ,'D') remark           
      from nc_mas a ,nc_status b           
      where a.sts_key = b.STS_KEY            
      and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type='MEDSTS' )           
      and (a.hn_no = in_hn_no or in_hn_no is null)           
      and (a.mas_cus_name like '%'||in_name||'%' or in_name is null)           
      and (a.invoice_no = in_inv_no or in_inv_no is null)           
      and ((a.tr_date_fr between to_date(in_loss_Date_fr,'dd/mm/rrrr') and to_date(in_loss_Date_to,'dd/mm/rrrr') or (in_loss_Date_fr is null and in_loss_Date_to is null)) or           
          (a.tr_date_to between to_date(in_loss_Date_fr,'dd/mm/rrrr') and to_date(in_loss_Date_to,'dd/mm/rrrr') or (in_loss_Date_fr is null and in_loss_Date_to is null)) or           
          (to_date(in_loss_Date_fr,'dd/mm/rrrr') between a.tr_date_fr and a.tr_date_to and in_loss_Date_fr is not null and in_loss_Date_to is null))           
      and (b.sts_sub_type = in_status or in_status is null)           
      and a.clm_user = in_user_id           
      order by a.clm_no;           
  EXCEPTION           
    WHEN NO_DATA_FOUND THEN           
         x_result := 'NO DATA FOUND';           
         open out_cursor for           
            select '' sts_key,'' inv_no,'' clm_no,'' loss_date,'' hn_no,'' name,'' res_amt,'' status           
            from dual;           
    WHEN OTHERS THEN           
         x_result := SQLERRM;           
         open out_cursor for           
            select '' sts_key,'' inv_no,'' clm_no,'' loss_date,'' hn_no,'' name,'' res_amt,'' status           
            from dual;           
  END search_sts_by_hpt;            
             
  PROCEDURE get_med_risk_std           
  (           
    out_cursor        OUT sys_refcursor           
  )            
  IS           
  BEGIN           
   open out_cursor for           
            select '' val,'--กรุณาเลือก--' descr,1 seq from dual           
            union           
            select a.med_risk_code val,a.med_risk_desc descr,2 seq from MED_RISK_STD a           
            where a.th_eng = 'T'           
            order by seq,descr;           
  EXCEPTION           
    WHEN OTHERS THEN           
       open out_cursor for           
            select '' val,'--กรุณาเลือก--' descr from dual;           
  END get_med_risk_std;           
             
  PROCEDURE get_med_risk_sub_std           
  (           
    in_med_risk_code  IN varchar2,           
    out_cursor        OUT sys_refcursor           
  )           
  IS           
  BEGIN           
   open out_cursor for           
            select '' val,'--กรุณาเลือก--' descr,1 seq from dual           
            union           
            select a.dis_code val,b.short_descr descr,2 seq            
            from MED_RISK_SUB_STD a,dis_code_std b           
            where a.dis_code = b.dis_code           
            and b.th_eng = 'T'           
            and a.med_risk_code = in_med_risk_code           
            order by seq,val;           
  EXCEPTION           
    WHEN OTHERS THEN           
       open out_cursor for           
            select '' val,'--กรุณาเลือก--' descr from dual;           
  END get_med_risk_sub_std;           
             
  PROCEDURE web_pahealth_coverage            
  (           
    in_policy_no          IN varchar2,           
    in_fleet_seq          IN Number,           
    in_recpt_seq          IN Number,           
    in_id_no              IN varchar2,           
    in_loss_date          IN varchar2, --5           
    out_cursor            OUT pahealth_cursor,           
    x_result              OUT varchar2                                     
  )           
  IS           
    x_pol_no  MIS_PA_PREM.Pol_no%type;           
    x_pol_run  MIS_PA_PREM.Pol_run%type;           
  BEGIN           
    out_cursor := null;           
    p_acc_package.read_pol(in_policy_no,x_pol_no,x_pol_run); --separate in_policy_no into x_pol_no,x_pol_run           
    --Get Coverage           
    MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,in_recpt_seq,to_date(in_loss_date,'dd/mm/rrrr'),out_cursor);           
  EXCEPTION           
    WHEN OTHERS THEN           
       x_result := SQLERRM;           
  END web_pahealth_coverage;           
             
  PROCEDURE claim_coverage            
  (           
    in_policy_no      IN varchar2,           
    in_fleet_seq      IN Number,           
    in_recpt_seq      IN Number,           
    in_cursor         IN sys_refcursor,           
    out_cursor        OUT sys_refcursor                                 
  )            
  IS            
    TYPE t_data1 IS RECORD           
    (           
    CODE         VARCHAR2(20),           
    DESCR        VARCHAR2(1000),           
    MAX_DAY      NUMBER,           
    SUB_AGR_AMT  NUMBER,           
    MAX_AMT      NUMBER           
    );            
    j_rec1 t_data1;             
  BEGIN           
    LOOP           
         FETCH  in_cursor INTO j_rec1;           
          EXIT WHEN in_cursor%NOTFOUND;           
              --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec1.CODE) then  -- hide TOTLOSS Prem_code           
              if nc_health_package.IS_CHECK_ACCUM(j_rec1.CODE) then -- Show only Treatment expense           
                  insert into tmp_clm_coverage           
                  (POLICY_NO,           
                  FLEET_SEQ,           
                  RECPT_SEQ,           
                  CODE,           
                  DESCR,           
                  MAX_DAY,           
                  SUB_AGR_AMT,           
                  MAX_AMT)           
                  values           
                  (in_policy_no,           
                  in_fleet_seq,           
                  in_recpt_seq,           
                  j_rec1.CODE,           
                  j_rec1.DESCR,           
                  j_rec1.MAX_DAY,           
                  j_rec1.SUB_AGR_AMT,           
                  j_rec1.MAX_AMT);           
              end if;           
         end loop;                
              open out_cursor for           
                 select CODE,DESCR,MAX_DAY,SUB_AGR_AMT,MAX_AMT from tmp_clm_coverage a           
                 where a.policy_no=in_policy_no and a.fleet_seq=in_fleet_seq and a.recpt_seq=in_recpt_seq;           
                         
              delete from tmp_clm_coverage a           
              where a.policy_no=in_policy_no and a.fleet_seq=in_fleet_seq and a.recpt_seq=in_recpt_seq;           
              commit;           
  END claim_coverage;           
             
  PROCEDURE get_initQuery            
  (           
    out_cursor_sts            OUT sys_refcursor,           
    out_cursor_order_by       OUT sys_refcursor,           
    out_cursor_date_type      OUT sys_refcursor           
  )           
  IS           
    x_result   varchar2(1);           
  BEGIN           
    web_clm_pahealth.get_status('HOS_T3',null,out_cursor_sts);           
    x_result := NC_HEALTH_PACKAGE.GET_LIST_CLM_ORDERBY(out_cursor_order_by);           
    x_result := NC_HEALTH_PACKAGE.GET_LIST_DATE_TYPE(out_cursor_date_type);           
  EXCEPTION           
    WHEN OTHERS THEN           
       open out_cursor_sts for           
            select null key,null remark from dual;           
       open out_cursor_order_by for           
            SELECT '' NAME , '' VALUE FROM DUAL;           
       open out_cursor_date_type for           
            SELECT '' NAME , '' VALUE FROM DUAL;           
  END get_initQuery;           
             
  FUNCTION get_hosp_id(in_user_id IN varchar2)           
  RETURN VARCHAR2           
  IS           
  tmp      med_hospital_list.hosp_id%type;                        
  BEGIN           
    select hosp_id            
    into tmp           
    from MED_STAFF           
    where user_id = in_user_id;           
           
    RETURN tmp;           
  EXCEPTION           
    WHEN OTHERS THEN           
      RETURN null;           
  END get_hosp_id;           
             
  FUNCTION get_tot_rec_sts           
  (           
    in_hpt_code      IN varchar2,           
    in_sts_sub_type  IN varchar2           
  ) RETURN NUMBER           
  IS           
  tmp      number;                        
  BEGIN           
    if in_sts_sub_type = 'MEDSTS11' then           
      select count(*)           
      into tmp           
      from nc_mas a, nc_status b           
      where a.sts_key = B.STS_KEY           
       and b.sts_seq in (select max(bb.sts_seq)           
                           from nc_status bb           
                          where bb.sts_key = b.sts_key           
                            and bb.sts_type = 'MEDSTS')           
       and a.hpt_code = in_hpt_code           
       and b.sts_sub_type = in_sts_sub_type;           
    else           
      select count(*)           
      into tmp           
      from nc_mas a, nc_status b           
      where a.sts_key = B.STS_KEY           
       and b.sts_seq in (select max(bb.sts_seq)           
                           from nc_status bb           
                          where bb.sts_key = b.sts_key           
                            and bb.sts_type = 'MEDSTS')           
       and a.hpt_code = in_hpt_code           
       and b.sts_sub_type = in_sts_sub_type           
       and a.reg_date between trunc(sysdate-30) and trunc(sysdate);           
    end if;           
                  
    RETURN tmp;           
  EXCEPTION           
    WHEN OTHERS THEN           
      RETURN 0;           
  END get_tot_rec_sts;           
             
  FUNCTION get_sql4mc(in_cursor   IN sys_refcursor) RETURN VARCHAR2           
  IS           
    TYPE t_data1 IS RECORD           
    (           
    CODE         VARCHAR2(20),           
    DESCR        VARCHAR2(1000),           
    MAX_DAY      NUMBER,           
    SUB_AGR_AMT  NUMBER,           
    MAX_AMT      NUMBER           
    );            
    j_rec1 t_data1;           
               
    x_sql        VARCHAR2(2000):=null;           
  BEGIN           
      LOOP           
         FETCH  in_cursor INTO j_rec1;           
          EXIT WHEN in_cursor%NOTFOUND;           
          if x_sql is not null then           
             x_sql := x_sql||' union ';           
          end if;           
          x_sql := x_sql||' select '''||j_rec1.CODE||''' PREMCODE, 0 SUMINS,0 PREMCOL from dual ';           
      END LOOP;           
      return x_sql;           
  END get_sql4mc;           
             
  PROCEDURE web_pahealth_detail_for_broker 
  ( 
    in_policy_no          IN varchar2, 
    in_fleet_seq          IN Number, 
    in_recpt_seq          IN Number, 
    in_id_no              IN varchar2, 
    in_name               IN varchar2, --5 
    in_loss_date          IN varchar2, 
    in_grp_seq            IN varchar2, 
    out_name              OUT varchar2,  
    out_fr_date           OUT date, 
    out_to_date           OUT date, --10 
    out_status            OUT varchar2, 
    out_pd_grp            OUT varchar2, 
    out_txt_remark        OUT varchar2, 
    out_cursor            OUT pahealth_cursor,  
    out_cursor_name       OUT sys_refcursor, --15 
    out_cursor_policy     OUT sys_refcursor,  
    out_cursor_unname     OUT sys_refcursor, 
    x_result              OUT varchar2                      
  ) 
  IS 
    TYPE t_data_name IS RECORD 
    ( 
    name           varchar2(1000), 
    fleet_seq      number, 
    recpt_seq      number 
    );  
    rec1 t_data_name; 
    c2   HEALTHUTIL.sys_refcursor; 
     
    x_pol_no       MIS_PA_PREM.Pol_no%type; 
    x_pol_run      MIS_PA_PREM.Pol_run%type; 
    x_cnt          number; 
    x_fleet_seq    mis_pa_prem.fleet_seq%type:=null; 
    x_recpt_seq    mis_pa_prem.recpt_seq%type:=null; 
    cursor_name    web_clm_pahealth.sys_refcursor; 
    x_type         varchar2(5); 
    x_name         varchar2(100); 
  BEGIN 
    x_fleet_seq := in_fleet_seq; 
    x_recpt_seq := in_recpt_seq;   
    x_name := UPPER(in_name); 
   
    if in_policy_no is not null and x_name is not null and x_recpt_seq = 0 then --Find Customer 
       p_acc_package.read_pol(in_policy_no,x_pol_no,x_pol_run); --separate in_policy_no into x_pol_no,x_pol_run 
       web_clm_pahealth.get_list_customer(x_pol_no,x_pol_run,x_name,in_loss_date,x_cnt,out_cursor_name); 
        
       if x_cnt = 0 then 
         web_clm_pahealth.get_pahealth_details_for_broke(in_policy_no,x_fleet_seq,x_recpt_seq,in_id_no, 
                 in_loss_date,in_grp_seq,in_name ,out_name,out_fr_date,out_to_date,out_status,out_pd_grp, 
                 out_txt_remark,out_cursor,out_cursor_name,out_cursor_policy,out_cursor_unname,x_result); 
       elsif x_cnt = 1 then 
          fetch out_cursor_name into rec1; 
                x_fleet_seq := rec1.fleet_seq; 
                x_recpt_seq := rec1.recpt_seq; 
          close out_cursor_name; 
           
          MISC.HEALTHUTIL.get_pa_health_type(x_pol_no,x_pol_run,x_type); 
          if x_type in ('PI','HI') then 
             x_fleet_seq := 0; 
             x_recpt_seq := 0; 
          end if; 
           
          web_clm_pahealth.get_pahealth_details_for_broke(in_policy_no,x_fleet_seq,x_recpt_seq,in_id_no, 
                 in_loss_date,in_grp_seq ,in_name,out_name,out_fr_date,out_to_date,out_status,out_pd_grp, 
                 out_txt_remark,out_cursor,out_cursor_name,out_cursor_policy,out_cursor_unname,x_result); 
       else 
          open out_cursor for 
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual; 
          open out_cursor_policy for 
             select null policy_no,null prod_type from dual; 
          open out_cursor_unname for 
             select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual; 
       end if; 
    else 
       web_clm_pahealth.get_pahealth_details_for_broke(in_policy_no,x_fleet_seq,x_recpt_seq,in_id_no, 
                 in_loss_date,in_grp_seq,out_name,out_fr_date,out_to_date,out_status,out_pd_grp, 
                 out_txt_remark,out_cursor,out_cursor_name,out_cursor_policy,out_cursor_unname,x_result); 
    end if; 
        
  END web_pahealth_detail_for_broker; 
   
  PROCEDURE get_pahealth_details_for_broke           
  (           
    in_policy_no          IN varchar2,           
    in_fleet_seq          IN Number,           
    in_recpt_seq          IN Number,           
    in_id_no              IN varchar2,           
    in_loss_date          IN varchar2, --5           
    in_grp_seq            IN varchar2,           
    out_name              OUT varchar2,           
    out_fr_date           OUT date,           
    out_to_date           OUT date,           
    out_status            OUT varchar2, --10           
    out_pd_grp            OUT varchar2,           
    out_txt_remark        OUT varchar2,           
    out_cursor            OUT pahealth_cursor,            
    out_cursor_name       OUT sys_refcursor,           
    out_cursor_policy     OUT sys_refcursor, --15            
    out_cursor_unname     OUT sys_refcursor,           
    x_result              OUT varchar2           
  ) IS           
  x_pol_no  MIS_PA_PREM.Pol_no%type;           
  x_pol_run  MIS_PA_PREM.Pol_run%type;           
  x_type     varchar2(2);           
  x_name1             varchar2(100);           
  x_name2             varchar2(200);           
  x_cnt               number;           
  x_cnt_name          number;           
  x_recpt_seq         mis_pa_prem.recpt_seq%type;           
  x_policy_no         varchar2(30);           
  x_loss_date         date;           
  x_is_tele           varchar2(5);           
  x_tot_prem          pa_patn.tot_prem%type;            
  cursor_name         web_clm_pahealth.sys_refcursor;           
  x_tmp_remark        varchar2(500);           
  x_sql4mc            varchar2(2000);           
  x_rst               varchar2(500);           
  x_grp_seq           number;           
  TYPE t_data_name IS RECORD           
    (           
    name           varchar2(1000),           
    fleet_seq      number,           
    recpt_seq      number           
    );            
    rec1 t_data_name;           
               
  c2   web_clm_pahealth.sys_refcursor;--HEALTHUTIL.sys_refcursor;           
  TYPE t_data2 IS RECORD           
  (           
  ID_CARD    VARCHAR2(30),           
  CUS_NAME   VARCHAR2(200),           
  PREM       NUMBER,           
  fr_date  date,           
  to_date  date           
  );            
  j_rec2 t_data2;           
             
  TYPE t_data_unname IS RECORD           
  (           
  GRP_SEQ  NUMBER,           
  SUM_INS  NUMBER,           
  FLEET_COUNT NUMBER,           
  FR_DATE DATE,           
  TO_DATE DATE           
  );            
  j_rec3 t_data_unname;           
             
  BEGIN           
    x_policy_no := in_policy_no;           
    x_loss_date := to_date(in_loss_date,'dd/mm/rrrr');           
    if x_policy_no is null and in_id_no is not null then                   
        x_cnt := MISC.HEALTHUTIL.get_count_policy_by_id(in_id_no,x_loss_date);           
        if x_cnt > 1 then           
           --Get list of name_cover           
           MISC.HEALTHUTIL.get_policy_by_id(in_id_no,x_loss_date,out_cursor_policy);           
           open out_cursor for           
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;           
           open out_cursor_name for           
                select null name,null fleet_seq,null recpt_seq from dual;           
           return;           
        elsif x_cnt = 1 then           
           x_policy_no := MISC.HEALTHUTIL.get_policy_by_id(in_id_no,x_loss_date);           
        else --Checking for Bancas           
           x_cnt := MISC.HEALTHUTIL.get_count_policy_by_id_bancas(in_id_no,x_loss_date); --           
           if x_cnt > 0 then           
              begin           
                  MISC.HEALTHUTIL.GET_POLICY_BY_ID_BANCAS(in_id_no,x_loss_date,c2);           
                  FETCH  c2 INTO j_rec2;           
                      x_tot_prem := j_rec2.PREM ; --Choose First Record             
                      out_name := j_rec2.cus_name ;               
                      out_fr_date := j_rec2.fr_date;           
                      out_to_date := j_rec2.to_date;           
              exception           
                  when others then           
                       x_tot_prem := 0;           
                       x_type := 'XX'; --Not Found           
              end;           
              close c2;           
                         
              if x_tot_prem > 0 then           
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor);           
                 x_sql4mc := web_clm_pahealth.get_sql4mc(out_cursor);           
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor);           
                 --web_clm_pahealth.claim_coverage(in_id_no,in_fleet_seq,in_recpt_seq,out_cursor,out_cursor); --get premcode that can claim           
                 x_type := 'B'; --Bancas           
              end if;           
           else           
              x_type := 'XX'; --Not Found           
           end if;           
        end if;           
    end if;            
               
    if x_type is null then              
        p_acc_package.read_pol(x_policy_no,x_pol_no,x_pol_run); --separate in_policy_no into x_pol_no,x_pol_run           
        MISC.HEALTHUTIL.get_pa_health_type(x_pol_no,x_pol_run,x_type); --Get type           
        MISC.HEALTHUTIL.get_is_tele(x_pol_no,x_pol_run,x_is_tele); --Get Is tele == 'Y'           
        out_pd_grp := substr(x_type,1,1);           
    end if;           
               
    dbms_output.put_line('x_type='||x_type);           
               
    if x_type in ('PI','PG') then -- check for watchlist       
        if nc_health_package.is_watchlist_policy(x_pol_no,x_pol_run) then      
             x_type := 'XY' ;   -- return status ????????      
        end if;                          
    end if;      
              
    dbms_output.put_line('x_type='||x_type);      
          
--    if x_type = 'XX' then --error      
    if x_type in ('XX' ,'XY') then --error or watchlist          
        x_result := x_type;           
        open out_cursor for           
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;           
        open out_cursor_name for           
             select null name,null fleet_seq,null recpt_seq from dual;           
        open out_cursor_policy for           
             select null policy_no,null prod_type from dual;             
        open out_cursor_unname for           
             select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual;           
    elsif nc_health_package.IS_UNNAME_POLICY(x_pol_no,x_pol_run) then --Unname Policy                   
        nc_health_package.GET_UNNAME_GROUP(x_pol_no,x_pol_run,0,1,x_rst,x_cnt,out_cursor_unname);           
        if x_cnt = 1 or in_grp_seq is not null then           
           nc_health_package.GET_UNNAME_GROUP(x_pol_no,x_pol_run,0,1,x_rst,x_cnt,c2);           
           LOOP           
             FETCH  c2 INTO j_rec3;            
             EXIT WHEN c2%NOTFOUND;            
                if x_cnt = 1 or to_number(in_grp_seq) = j_rec3.GRP_SEQ then           
                    out_fr_date := j_rec3.fr_date;           
                    out_to_date := j_rec3.to_date;           
                    x_grp_seq := j_rec3.GRP_SEQ;           
                end if;           
             END LOOP;           
           close c2;           
           nc_health_package.GET_UNNAME_STATUS(x_pol_no,x_pol_run,x_loss_date,out_status);           
           nc_health_package.GET_COVER_PA_UNNAME(x_pol_no,x_pol_run,null,null,x_grp_seq,null,out_cursor,x_rst);           
           open out_cursor_name for           
             select null name,null fleet_seq,null recpt_seq from dual;           
           open out_cursor_policy for           
             select x_policy_no policy_no,null prod_type from dual;           
           open out_cursor_unname for           
             select x_grp_seq grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual;           
        else           
           /*nc_health_package.GET_UNNAME_GROUP(x_pol_no,x_pol_run,0,1,x_rst,x_cnt,c2);           
           LOOP           
             FETCH  c2 INTO j_rec3;             
             EXIT WHEN c2%NOTFOUND;           
                if 3 = j_rec3.GRP_SEQ then--x_cnt = 1 or in_grp_seq = j_rec3.GRP_SEQ then           
                    out_fr_date := j_rec3.fr_date;           
                    out_to_date := j_rec3.to_date;           
                end if;           
             END LOOP;           
           close c2;*/           
           nc_health_package.GET_UNNAME_STATUS(x_pol_no,x_pol_run,x_loss_date,out_status);           
           nc_health_package.GET_COVER_PA_UNNAME(x_pol_no,x_pol_run,null,null,to_number(in_grp_seq),null,out_cursor,x_rst);           
           open out_cursor_name for           
             select null name,null fleet_seq,null recpt_seq from dual;           
           open out_cursor_policy for           
             select x_policy_no policy_no,null prod_type from dual;           
        end if;           
    elsif x_type in ('PI','HI') and in_fleet_seq <> 0 then           
        x_result := 'NO'; --Invalid Critiria           
        open out_cursor for           
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;           
        open out_cursor_name for           
             select null name,null fleet_seq,null recpt_seq from dual;           
        open out_cursor_policy for           
             select null policy_no,null prod_type from dual;           
        open out_cursor_unname for           
             select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual;           
    elsif x_type = 'B' then --Bancas           
        out_status := 'Y';               
        out_pd_grp := 'B';           
                   
        open out_cursor_name for           
             select null name,null fleet_seq,null recpt_seq from dual;           
        open out_cursor_policy for           
             select null policy_no,null prod_type from dual;              
        open out_cursor_unname for           
             select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual;                      
    elsif x_type in ('PG','HG') and in_fleet_seq = 0 then --For x_type = PG or HG and user didn't key a fleet_seq           
             if MISC.HEALTHUTIL.get_type_family(x_pol_no,x_pol_run) then --For Telemarketing           
                --Get list of name_cover           
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);           
                open out_cursor for           
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;           
                open out_cursor_policy for           
                     select x_policy_no policy_no,null prod_type from dual;             
                open out_cursor_unname for           
                     select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual;           
             else --Not Telemarketing           
                x_result := 'NO';           
                open out_cursor for           
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;           
                open out_cursor_name for           
                     select null name,null fleet_seq,null recpt_seq from dual;           
                open out_cursor_policy for           
                     select x_policy_no policy_no,null prod_type from dual;           
                open out_cursor_unname for           
                     select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual;           
             end if;           
    elsif x_type in ('PI','HI') and x_is_tele = 'Y' then --For Telemarketing           
        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);           
        fetch cursor_name into rec1;           
        x_recpt_seq := rec1.recpt_seq;           
        close cursor_name;           
        --Get Name, fr_date, to_date           
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);           
        if x_name2 is not null then           
           out_name := x_name1||' ('||x_name2||')';            
        else             
           out_name := x_name1;            
        end if;           
        --Get Status                    
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);           
        --Get Coverage           
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);           
        /*if out_pd_grp <> 'H' then           
           web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim           
        end if;*/           
        open out_cursor_name for           
             select null name,decode(in_fleet_seq,0,1,in_fleet_seq) fleet_seq,x_recpt_seq recpt_seq from dual;           
        open out_cursor_policy for           
             select x_policy_no policy_no,null prod_type from dual;           
        open out_cursor_unname for           
             select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual;           
    else            
        x_cnt_name := MISC.HEALTHUTIL.get_count_name(x_pol_no,x_pol_run,in_fleet_seq); --Count name records           
        if in_recpt_seq <> 0 then --Chosen name           
           --set x_cnt_name when in_recpt_seq is sent by web           
           x_cnt_name := 1;           
        end if;           
        if x_cnt_name > 1 then           
           --Get list of name_cover           
           MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name);           
           open out_cursor for           
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;             
           open out_cursor_policy for           
                select x_policy_no policy_no,null prod_type from dual;            
           open out_cursor_unname for           
                select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual;                   
        else           
            --Set Default in_recpt_seq           
            if in_recpt_seq = 0 then            
                --x_recpt_seq := 1;           
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name);           
                fetch cursor_name into rec1;           
                x_recpt_seq := rec1.recpt_seq;           
                close cursor_name;           
            else           
                x_recpt_seq := in_recpt_seq;           
            end if;           
            --Get Name, fr_date, to_date           
            MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date);           
            if x_name2 is not null then           
               out_name := x_name1||' ('||x_name2||')';            
            else             
               out_name := x_name1;            
            end if;           
            --Get Status                    
            MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status);           
            --Get Coverage           
            MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor);           
            /*if out_pd_grp <> 'H' then           
               web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim           
            end if;*/           
            open out_cursor_name for           
                 --select null name,null fleet_seq,null recpt_seq from dual;           
                 select null name,decode(in_fleet_seq,0,1,in_fleet_seq) fleet_seq,x_recpt_seq recpt_seq from dual;           
            open out_cursor_policy for           
                 select x_policy_no policy_no,null prod_type from dual;           
            open out_cursor_unname for           
                 select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual;           
        end if;           
     end if;           
     if MISC.HEALTHUTIL.is_45plus(x_pol_no,x_pol_run) then           
        out_txt_remark := MISC.HEALTHUTIL.get_benefit_card_45plus(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq);           
     else           
        out_txt_remark := '';           
     end if;           
     if x_type = 'B' then --Bancas           
        dbms_output.put_line('x_sql4mc='||x_sql4mc);           
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_sql4mc,x_tmp_remark);           
     elsif out_pd_grp = 'P' then --PA           
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_pol_no,x_pol_run,in_fleet_seq,x_tmp_remark);           
     end if;           
     out_txt_remark := out_txt_remark||x_tmp_remark||'<br />';           
  EXCEPTION           
    WHEN OTHERS THEN           
      x_result := SQLERRM;             
  END get_pahealth_details_for_broke;           
 
             
 
  PROCEDURE get_pahealth_details_for_broke  -- V2 
  ( 
    in_policy_no          IN varchar2, 
    in_fleet_seq          IN Number, 
    in_recpt_seq          IN Number, 
    in_id_no              IN varchar2, 
    in_loss_date          IN varchar2, --5 
    in_grp_seq            IN varchar2, 
    in_name            IN varchar2, 
    out_name              OUT varchar2, 
    out_fr_date           OUT date, 
    out_to_date           OUT date, 
    out_status            OUT varchar2, --10 
    out_pd_grp            OUT varchar2, 
    out_txt_remark        OUT varchar2, 
    out_cursor            OUT pahealth_cursor,  
    out_cursor_name       OUT sys_refcursor, 
    out_cursor_policy     OUT sys_refcursor, --15  
    out_cursor_unname     OUT sys_refcursor, 
    x_result              OUT varchar2 
  ) IS 
  x_pol_no  MIS_PA_PREM.Pol_no%type; 
  x_pol_run  MIS_PA_PREM.Pol_run%type; 
  x_type     varchar2(2); 
  x_name1             varchar2(100); 
  x_name2             varchar2(200); 
  x_cnt               number; 
  x_cnt_name          number; 
  x_recpt_seq         mis_pa_prem.recpt_seq%type; 
  x_policy_no         varchar2(30); 
  x_loss_date         date; 
  x_is_tele           varchar2(5); 
  x_tot_prem          pa_patn.tot_prem%type;  
  cursor_name         web_clm_pahealth.sys_refcursor; 
  x_tmp_remark        varchar2(500); 
  x_sql4mc            varchar2(2000); 
  x_rst               varchar2(500); 
  x_grp_seq           number; 
  TYPE t_data_name IS RECORD 
    ( 
    name           varchar2(1000), 
    fleet_seq      number, 
    recpt_seq      number 
    );  
    rec1 t_data_name; 
     
  c2   HEALTHUTIL.sys_refcursor; 
  TYPE t_data2 IS RECORD 
  ( 
  ID_CARD    VARCHAR2(30), 
  CUS_NAME   VARCHAR2(200), 
  PREM       NUMBER, 
  fr_date  date, 
  to_date  date 
  );  
  j_rec2 t_data2; 
   
  TYPE t_data_unname IS RECORD 
  ( 
  GRP_SEQ  NUMBER, 
  SUM_INS  NUMBER, 
  FLEET_COUNT NUMBER, 
  FR_DATE DATE, 
  TO_DATE DATE 
  );  
  j_rec3 t_data_unname; 
   
  BEGIN 
    x_policy_no := in_policy_no; 
    x_loss_date := to_date(in_loss_date,'dd/mm/rrrr'); 
    if x_policy_no is null and in_id_no is not null then         
        x_cnt := MISC.HEALTHUTIL.get_count_policy_by_id(in_id_no,x_loss_date); 
        if x_cnt > 1 then 
           --Get list of name_cover 
           MISC.HEALTHUTIL.get_policy_by_id(in_id_no,x_loss_date,out_cursor_policy); 
           open out_cursor for 
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual; 
           open out_cursor_name for 
                select null name,null fleet_seq,null recpt_seq from dual; 
           return; 
        elsif x_cnt = 1 then 
           x_policy_no := MISC.HEALTHUTIL.get_policy_by_id(in_id_no,x_loss_date); 
        else --Checking for Bancas 
           x_cnt := MISC.HEALTHUTIL.get_count_policy_by_id_bancas(in_id_no,x_loss_date); -- 
           if x_cnt > 0 then 
              begin 
                  MISC.HEALTHUTIL.GET_POLICY_BY_ID_BANCAS(in_id_no,x_loss_date,c2); 
                  FETCH  c2 INTO j_rec2; 
                      x_tot_prem := j_rec2.PREM ; --Choose First Record   
                      out_name := j_rec2.cus_name ;     
                      out_fr_date := j_rec2.fr_date; 
                      out_to_date := j_rec2.to_date; 
              exception 
                  when others then 
                       x_tot_prem := 0; 
                       x_type := 'XX'; --Not Found 
              end; 
              close c2; 
               
              if x_tot_prem > 0 then 
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor); 
                 x_sql4mc := web_clm_pahealth.get_sql4mc(out_cursor); 
                 misc.healthutil.get_coverage_bancas(x_tot_prem,out_cursor); 
                 --web_clm_pahealth.claim_coverage(in_id_no,in_fleet_seq,in_recpt_seq,out_cursor,out_cursor); --get premcode that can claim 
                 x_type := 'B'; --Bancas 
              end if; 
           else 
              x_type := 'XX'; --Not Found 
           end if; 
        end if; 
    end if;  
     
    if x_type is null then    
        p_acc_package.read_pol(x_policy_no,x_pol_no,x_pol_run); --separate in_policy_no into x_pol_no,x_pol_run 
        MISC.HEALTHUTIL.get_pa_health_type(x_pol_no,x_pol_run,x_type); --Get type 
        MISC.HEALTHUTIL.get_is_tele(x_pol_no,x_pol_run,x_is_tele); --Get Is tele == 'Y' 
        out_pd_grp := substr(x_type,1,1); 
    end if; 
 
    if x_type in ('PI','PG') then -- check for watchlist  
        if nc_health_package.is_watchlist_policy(x_pol_no,x_pol_run) then 
             x_type := 'XY' ;   -- return status ????????? 
        end if;                     
    end if; 
         
    dbms_output.put_line('x_type='||x_type); 
     
--    if x_type = 'XX' then --error 
    if x_type in ('XX' ,'XY') then --error or watchlist     
        x_result := x_type; 
        open out_cursor for 
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual; 
        open out_cursor_name for 
             select null name,null fleet_seq,null recpt_seq from dual; 
        open out_cursor_policy for 
             select null policy_no,null prod_type from dual;   
        open out_cursor_unname for 
             select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual; 
    elsif nc_health_package.IS_UNNAME_POLICY(x_pol_no,x_pol_run) then --Unname Policy         
        nc_health_package.GET_UNNAME_GROUP(x_pol_no,x_pol_run,0,1,x_rst,x_cnt,out_cursor_unname); 
        if x_cnt = 1 or in_grp_seq is not null then 
           nc_health_package.GET_UNNAME_GROUP(x_pol_no,x_pol_run,0,1,x_rst,x_cnt,c2); 
           LOOP 
             FETCH  c2 INTO j_rec3;  
             EXIT WHEN c2%NOTFOUND;  
                if x_cnt = 1 or to_number(in_grp_seq) = j_rec3.GRP_SEQ then 
                    out_fr_date := j_rec3.fr_date; 
                    out_to_date := j_rec3.to_date; 
                    x_grp_seq := j_rec3.GRP_SEQ; 
                end if; 
             END LOOP; 
           close c2; 
           nc_health_package.GET_UNNAME_STATUS(x_pol_no,x_pol_run,x_loss_date,out_status); 
           nc_health_package.GET_COVER_PA_UNNAME(x_pol_no,x_pol_run,null,null,x_grp_seq,null,out_cursor,x_rst); 
           out_name := in_name; 
           open out_cursor_name for 
             select in_name name,null fleet_seq,null recpt_seq from dual; 
           open out_cursor_policy for 
             select x_policy_no policy_no,null prod_type from dual; 
           open out_cursor_unname for 
             select x_grp_seq grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual; 
        else 
           /*nc_health_package.GET_UNNAME_GROUP(x_pol_no,x_pol_run,0,1,x_rst,x_cnt,c2); 
           LOOP 
             FETCH  c2 INTO j_rec3;   
             EXIT WHEN c2%NOTFOUND; 
                if 3 = j_rec3.GRP_SEQ then--x_cnt = 1 or in_grp_seq = j_rec3.GRP_SEQ then 
                    out_fr_date := j_rec3.fr_date; 
                    out_to_date := j_rec3.to_date; 
                end if; 
             END LOOP; 
           close c2;*/ 
           nc_health_package.GET_UNNAME_STATUS(x_pol_no,x_pol_run,x_loss_date,out_status); 
           nc_health_package.GET_COVER_PA_UNNAME(x_pol_no,x_pol_run,null,null,to_number(in_grp_seq),null,out_cursor,x_rst); 
           out_name := in_name; 
           open out_cursor_name for 
             select in_name name,null fleet_seq,null recpt_seq from dual; 
           open out_cursor_policy for 
             select x_policy_no policy_no,null prod_type from dual; 
        end if; 
    elsif x_type in ('PI','HI') and in_fleet_seq <> 0 then 
        x_result := 'NO'; --Invalid Critiria 
        open out_cursor for 
             select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual; 
        open out_cursor_name for 
             select null name,null fleet_seq,null recpt_seq from dual; 
        open out_cursor_policy for 
             select null policy_no,null prod_type from dual; 
        open out_cursor_unname for 
             select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual; 
    elsif x_type = 'B' then --Bancas 
        out_status := 'Y';     
        out_pd_grp := 'B'; 
         
        open out_cursor_name for 
             select null name,null fleet_seq,null recpt_seq from dual; 
        open out_cursor_policy for 
             select null policy_no,null prod_type from dual;    
        open out_cursor_unname for 
             select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual;            
    elsif x_type in ('PG','HG') and in_fleet_seq = 0 then --For x_type = PG or HG and user didn't key a fleet_seq 
             if MISC.HEALTHUTIL.get_type_family(x_pol_no,x_pol_run) then --For Telemarketing 
                --Get list of name_cover 
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name); 
                open out_cursor for 
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual; 
                open out_cursor_policy for 
                     select x_policy_no policy_no,null prod_type from dual;   
                open out_cursor_unname for 
                     select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual; 
             else --Not Telemarketing 
                x_result := 'NO'; 
                open out_cursor for 
                     select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual; 
                open out_cursor_name for 
                     select null name,null fleet_seq,null recpt_seq from dual; 
                open out_cursor_policy for 
                     select x_policy_no policy_no,null prod_type from dual; 
                open out_cursor_unname for 
                     select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual; 
             end if; 
    elsif x_type in ('PI','HI') and x_is_tele = 'Y' then --For Telemarketing 
        MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name); 
        fetch cursor_name into rec1; 
        x_recpt_seq := rec1.recpt_seq; 
        close cursor_name; 
        --Get Name, fr_date, to_date 
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date); 
        if x_name2 is not null then 
           out_name := x_name1||' ('||x_name2||')';  
        else   
           out_name := x_name1;  
        end if; 
        --Get Status          
        MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status); 
        --Get Coverage 
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor); 
        /*if out_pd_grp <> 'H' then 
           web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim 
        end if;*/ 
        open out_cursor_name for 
             select null name,decode(in_fleet_seq,0,1,in_fleet_seq) fleet_seq,x_recpt_seq recpt_seq from dual; 
        open out_cursor_policy for 
             select x_policy_no policy_no,null prod_type from dual; 
        open out_cursor_unname for 
             select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual; 
    else  
        x_cnt_name := MISC.HEALTHUTIL.get_count_name(x_pol_no,x_pol_run,in_fleet_seq); --Count name records 
        if in_recpt_seq <> 0 then --Chosen name 
           --set x_cnt_name when in_recpt_seq is sent by web 
           x_cnt_name := 1; 
        end if; 
        if x_cnt_name > 1 then 
           --Get list of name_cover 
           MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,out_cursor_name); 
           open out_cursor for 
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;   
           open out_cursor_policy for 
                select x_policy_no policy_no,null prod_type from dual;  
           open out_cursor_unname for 
                select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual;         
        else 
            --Set Default in_recpt_seq 
            if in_recpt_seq = 0 then  
                --x_recpt_seq := 1; 
                MISC.HEALTHUTIL.get_name_cover(x_pol_no,x_pol_run,in_fleet_seq,x_loss_date,cursor_name); 
                fetch cursor_name into rec1; 
                x_recpt_seq := rec1.recpt_seq; 
                close cursor_name; 
            else 
                x_recpt_seq := in_recpt_seq; 
            end if; 
            --Get Name, fr_date, to_date 
            MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_type,x_name1,x_name2,out_fr_date,out_to_date); 
            if x_name2 is not null then 
               out_name := x_name1||' ('||x_name2||')';  
            else   
               out_name := x_name1;  
            end if; 
            --Get Status          
            MISC.HEALTHUTIL.get_status_active(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_status); 
            --Get Coverage 
            MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq,x_loss_date,out_cursor); 
            /*if out_pd_grp <> 'H' then 
               web_clm_pahealth.claim_coverage(x_policy_no,in_fleet_seq,x_recpt_seq,out_cursor,out_cursor); --get premcode that can claim 
            end if;*/ 
            open out_cursor_name for 
                 --select null name,null fleet_seq,null recpt_seq from dual; 
                 select null name,decode(in_fleet_seq,0,1,in_fleet_seq) fleet_seq,x_recpt_seq recpt_seq from dual; 
            open out_cursor_policy for 
                 select x_policy_no policy_no,null prod_type from dual; 
            open out_cursor_unname for 
                 select null grp_seq,null sum_ins,null fleet_count,null fr_date,null to_date from dual; 
        end if; 
     end if; 
     if MISC.HEALTHUTIL.is_45plus(x_pol_no,x_pol_run) then 
        out_txt_remark := MISC.HEALTHUTIL.get_benefit_card_45plus(x_pol_no,x_pol_run,in_fleet_seq,x_recpt_seq); 
     else 
        out_txt_remark := ''; 
     end if; 
     if x_type = 'B' then --Bancas 
        dbms_output.put_line('x_sql4mc='||x_sql4mc); 
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_sql4mc,x_tmp_remark); 
     elsif out_pd_grp = 'P' then --PA 
        NC_HEALTH_PACKAGE.GET_MC_REMARK(x_pol_no,x_pol_run,in_fleet_seq,x_tmp_remark); 
     end if; 
     out_txt_remark := out_txt_remark||x_tmp_remark||'<br />'; 
  EXCEPTION 
    WHEN OTHERS THEN 
      x_result := SQLERRM;   
  END get_pahealth_details_for_broke;  --v2 
     
  PROCEDURE get_list_customer           
  (           
    in_pol_no         IN varchar2,           
    in_pol_run        IN Number,           
    in_name           IN varchar2,           
    in_loss_date      IN varchar2,           
    out_count         OUT Number,           
    out_cursor        OUT sys_refcursor                               
  )           
  IS           
    o_name web_clm_pahealth.sys_refcursor;           
               
    TYPE t_data1 IS RECORD           
    (           
    NAME    VARCHAR2(200) ,           
    FLEET_SEQ   NUMBER ,           
    RECPT_SEQ NUMBER            
    );            
    j_rec1 t_data1;                
               
    str_query   LONG;           
    cnt number;           
  BEGIN           
    -- Call the procedure           
    misc.healthutil.get_name_cover(in_pol_no,           
                                 in_pol_run,           
                                 null,           
                                 to_date(in_loss_date,'dd/mm/rrrr'),           
                                 o_name);                   
    str_query := null;            
    cnt := 0;           
    LOOP           
    FETCH  o_name -- FOR (select * from o_name where recpt_seq = 1)           
    INTO j_rec1;           
    EXIT WHEN o_name%NOTFOUND;           
        --dbms_output.put_line('NAME '||j_rec1.name||' search '||nc_health_package.update_search_name(j_rec1.name));            
        if  nc_health_package.update_search_name(j_rec1.name) like            
                '%'||nc_health_package.update_search_name(in_name)||'%'  then           
            --dbms_output.put_line('Found : '||j_rec1.name) ;           
            cnt := cnt+1;            
            if cnt = 1 then           
                str_query := 'SELECT '''||j_rec1.name||''' NAME , '||j_rec1.fleet_seq||' fleet_seq , '||j_rec1.recpt_seq||' recpt_seq FROM dual ' ;           
            else           
                str_query := str_query||' UNION SELECT '''||j_rec1.name||''' NAME , '||j_rec1.fleet_seq||' fleet_seq , '||j_rec1.recpt_seq||' recpt_seq FROM dual ' ;           
            end if;               
        end if;           
    END LOOP;           
    --dbms_output.put_line('query='|| str_query);           
    if cnt = 0 then           
       open out_cursor for           
              select null name,null fleet_seq,null recpt_seq from dual;           
    end if;           
               
    out_count := cnt;           
    NC_HEALTH_PAID.GEN_CURSOR(str_query,out_cursor);           
  EXCEPTION           
    WHEN OTHERS THEN           
         dbms_output.put_line('get_list_customer err ='|| SQLERRM);           
         out_count := 0;           
         open out_cursor for           
              select null name,null fleet_seq,null recpt_seq from dual;           
  END get_list_customer;           
             
  PROCEDURE get_initQuery_broker            
  (           
    out_cursor_sts            OUT sys_refcursor,           
    out_cursor_order_by       OUT sys_refcursor,           
    out_cursor_date_type      OUT sys_refcursor           
  )           
  IS           
    x_result   varchar2(1);           
  BEGIN           
    web_clm_pahealth.get_status('BROKER',null,out_cursor_sts);           
    x_result := NC_HEALTH_PACKAGE.GET_LIST_CLM_ORDERBY_BROK(out_cursor_order_by);           
    x_result := NC_HEALTH_PACKAGE.GET_LIST_DATE_TYPE(out_cursor_date_type);           
  EXCEPTION           
    WHEN OTHERS THEN           
       open out_cursor_sts for           
            select null key,null remark from dual;           
       open out_cursor_order_by for           
            SELECT '' NAME , '' VALUE FROM DUAL;           
       open out_cursor_date_type for           
            SELECT '' NAME , '' VALUE FROM DUAL;           
  END get_initQuery_broker;          
            
END web_clm_pahealth;
/

