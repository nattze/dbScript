CREATE OR REPLACE PACKAGE BODY P_MANAGE_ROLE AS
/******************************************************************************
   NAME:       P_MANAGE_ROLE
   PURPOSE:     script for Manage User Role on BKIAPP

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        24/05/2016      2702       1. Created this package.
******************************************************************************/

    FUNCTION cloneDummyBKIUSER(v_user IN VARCHAR2 ,v_Group  IN VARCHAR2)  RETURN VARCHAR2 IS
        cnt number:=0;
        cnt_f number:=0;
        cnt_t number:=0;
        v_position_grp_id varchar2(2);
        v_name_t    bkiuser.name_t%type;
        v_title_t    bkiuser.TITLE_T%type;
        v_name_e    bkiuser.name_e%type;
        v_maxuser   varchar2(20);
        v_team  varchar2(200);
        v_division  varchar2(200);
        v_userPrefix    varchar2(20);
    BEGIN
            if v_Group = 'C' then
                v_userPrefix := 'IDMC';
            elsif v_Group = 'A' then
                v_userPrefix := 'IDMA';
            elsif v_Group = 'U' then
                v_userPrefix := 'IDMU';
            else
                v_userPrefix := 'IDMO';
            end if;    
            for y in (
                select USER_ID, '���ͺ' TITLE_T, NAME_T, '���ͺ'  TITLE_E, NAME_E, DEPT, BRN_CODE, EMAIL, PASSWORD, DIV, TEAM, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID , POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, EXPIRED_DATE, HR_POSITION_GRP_ID, HR_POSITION_ID, POSITION_LEVEL, SUPERVISOR1_ID
                from bkiuser
                where user_id = V_USER
            )loop
                cnt_f := cnt_f+1;
                
                for x in (  
                    select (select name_th from org_unit_std x where x.dept_id=a.dept_id and x.div_id =a.div_id and team_id='00') Division 
                    ,team_id ,name_th Team
                    from org_unit_std     a
                    where org_id ='01' and cancel_flag is null
                    and dept_id = y.dept_id
                    and team_id = y.team_id and div_id = y.div_id 
                    order by dept_id ,div_id ,team_id 
                )loop
                    v_team := X.Team;
                    v_division := X.Division;
                end loop; --get Team Name 
                        
                if y.position_grp_id < 42 then
                    if y.position_grp_id in ('41','35','31') then
                        cnt_t := cnt_t+1;
                        dbms_output.put_line('TL up');
                        if y.position_grp_id = '41' then
                            v_name_t := v_team||' (TL) ';
                            v_name_e := v_division;                   
                        elsif y.position_grp_id = '35' then
                            v_name_t := v_team||' (AVP) ';
                            v_name_e := v_division;                       
                        elsif y.position_grp_id = '31' then
                            v_name_t := v_team||' (VP) ';
                            v_name_e := v_division;                  
                        end if;
                    end if;                  
                else
                    v_name_t :=v_team;
                    v_name_e := v_division;            
                end if;
                v_title_t := 'clone:'||y.user_id;
                
                v_maxuser :=null;
                begin
                    select -- 'IDM'||nvl(lpad(to_number(substr(max(user_id),2))+1,4,'0'),'0001') newuserid
                    to_number(nvl(substr(max(user_id),5),0))+1 
                    into v_maxuser
                    from bkiuser
                    where user_id like v_userPrefix||'%'      ;  
                    
                exception
                    when no_data_found then
                        v_maxuser := 1;
                    when others then
                        null;
                end;
                v_maxuser := v_userPrefix||lpad(v_maxuser,4,'0');    
                dbms_output.put_line('user: '||y.user_id||'newuser: '||v_maxuser||' name:'||y.name_t||' newname: '||v_name_t||' div:'||y.div_id||' positionGrp:'||y.position_grp_id||' position:'||y.position_id);
                Insert into BKIUSER (USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, DEPT, BRN_CODE, EMAIL, PASSWORD, DIV, TEAM, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID , POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, EXPIRED_DATE, HR_POSITION_GRP_ID, HR_POSITION_ID, POSITION_LEVEL, SUPERVISOR1_ID) 
                Values (v_maxuser, v_title_t , v_name_t, Y.TITLE_E, v_name_e, Y.DEPT, Y.BRN_CODE, Y.EMAIL, v_maxuser||'' , Y.DIV, Y.TEAM, Y.ORG_ID, Y.DEPT_ID, Y.DIV_ID, Y.TEAM_ID, Y.POSITION_GRP_ID , Y.POSITION_ID, Y.HR_ORG_ID, Y.HR_DEPT_ID, Y.HR_DIV_ID, Y.HR_TEAM_ID, Y.JOIN_DATE, Y.CREATE_DATE, trunc(sysdate)+1000, Y.HR_POSITION_GRP_ID, Y.HR_POSITION_ID, Y.POSITION_LEVEL, Y.SUPERVISOR1_ID) 
                ;
                
            end loop; -- bkiuser    TL up 
            
            COMMIT;   
            RETURN   V_MAXUSER; 
    EXCEPTION
        WHEN OTHERS THEN
        rollback;
        return null;                   
    END cloneDummyBKIUSER;

    FUNCTION createGroupDummyBKIUSER(v_inDept IN VARCHAR2 ,v_Group  IN VARCHAR2
    ,O_RST  OUT VARCHAR2) RETURN BOOLEAN   IS
        cnt number:=0;
        cnt_f number:=0;
        cnt_t number:=0;
        v_position_grp_id varchar2(2);
        v_name_t    bkiuser.name_t%type;
        v_name_e    bkiuser.name_e%type;
        v_maxuser   varchar2(20);
        v_mode  varchar2(100);
--        v_inDept    varchar2(5):='21';
        v_userPrefix    varchar2(20):='IDMC';       -- IDMC = Claim ,IDMA = Acc ,IDMU = Unw    
    BEGIN
        if v_inDept is null then
            O_RST := 'please choose DEPT_ID';
            return false;
        end if;
        
        if v_Group = 'C' then
            v_userPrefix := 'IDMC';
        elsif v_Group = 'A' then
            v_userPrefix := 'IDMA';
        elsif v_Group = 'U' then
            v_userPrefix := 'IDMU';
        else
            v_userPrefix := 'IDMO';
        end if;
        v_mode := '++++ create Staff +++++';
        dbms_output.put_line(v_mode);
        for x in (  --++++ create TL UP 
            select Dept_id ,(select name_th from org_unit_std x where x.dept_id=a.dept_id and x.div_id ='00') Departmant 
            ,div_id , (select name_th from org_unit_std x where x.dept_id=a.dept_id and x.div_id =a.div_id and team_id='00') Division 
            ,team_id ,name_th Team
            from org_unit_std     a
            where org_id ='01' and cancel_flag is null
            and dept_id = v_inDept
            and team_id <> '00' and div_id <> '00'
    --        and div_id='00'
    --        and team_id='00'
            order by dept_id ,div_id ,team_id 
        )loop
        cnt:=cnt+1;        
        dbms_output.put_line(' dept:'||x.dept_id||' divid:'||x.div_id||' teamid:'||x.team_id||' division: '||x.division||' team: '||x.Team);
            
            for y in (
                select USER_ID, '���ͺ' TITLE_T, NAME_T, '���ͺ'  TITLE_E, NAME_E, DEPT, BRN_CODE, EMAIL, PASSWORD, DIV, TEAM, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID , POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, EXPIRED_DATE, HR_POSITION_GRP_ID, HR_POSITION_ID, POSITION_LEVEL, SUPERVISOR1_ID
                from bkiuser
                where dept_id = x.dept_id and div_id = x.div_id
                and team_id = x.team_id
    --            and team_id ='35'
                and position_grp_id <42
    --            and position_grp_id like v_position_grp_id
                and rownum=1
            )loop
                cnt_f := cnt_f+1;
                
                if y.position_grp_id < 42 then
                    if y.position_grp_id in ('41','35','31') then
                        cnt_t := cnt_t+1;
                        dbms_output.put_line('TL up');
                        if y.position_grp_id = '41' then
                            v_name_t := x.team||' (TL) ';
                            v_name_e := x.Division;                   
                        elsif y.position_grp_id = '35' then
                            v_name_t := x.team||' (AVP) ';
                            v_name_e := x.Division;                       
                        elsif y.position_grp_id = '31' then
                            v_name_t := x.team||' (VP) ';
                            v_name_e := x.Division;                  
                        end if;
                    end if;                  
                else
                    v_name_t := x.team;
                    v_name_e := x.Division;            
                end if;
                v_maxuser :=null;
                begin
                    select -- 'IDM'||nvl(lpad(to_number(substr(max(user_id),2))+1,4,'0'),'0001') newuserid
                    to_number(nvl(substr(max(user_id),5),0))+1 
                    into v_maxuser
                    from bkiuser
                    where user_id like v_userPrefix||'%'      ;  
                    
                exception
                    when no_data_found then
                        v_maxuser := 1;
                    when others then
                        null;
                end;
                v_maxuser := v_userPrefix||lpad(v_maxuser,4,'0');    
                dbms_output.put_line('user: '||y.user_id||'newuser: '||v_maxuser||' name:'||y.name_t||' newname: '||v_name_t||' div:'||y.div_id||' positionGrp:'||y.position_grp_id||' position:'||y.position_id);
                Insert into BKIUSER (USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, DEPT, BRN_CODE, EMAIL, PASSWORD, DIV, TEAM, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID , POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, EXPIRED_DATE, HR_POSITION_GRP_ID, HR_POSITION_ID, POSITION_LEVEL, SUPERVISOR1_ID) 
                Values (v_maxuser, Y.TITLE_T, v_name_t, Y.TITLE_E, v_name_e, Y.DEPT, Y.BRN_CODE, Y.EMAIL, v_maxuser||'' , Y.DIV, Y.TEAM, Y.ORG_ID, Y.DEPT_ID, Y.DIV_ID, Y.TEAM_ID, Y.POSITION_GRP_ID , Y.POSITION_ID, Y.HR_ORG_ID, Y.HR_DEPT_ID, Y.HR_DIV_ID, Y.HR_TEAM_ID, Y.JOIN_DATE, Y.CREATE_DATE, trunc(sysdate)+1000, Y.HR_POSITION_GRP_ID, Y.HR_POSITION_ID, Y.POSITION_LEVEL, Y.SUPERVISOR1_ID) 
                ;
                
            end loop; -- bkiuser    TL up 
            commit;
            v_maxuser :=null;
            
            for y in (
                select USER_ID, '���ͺ' TITLE_T, NAME_T, '���ͺ'  TITLE_E, NAME_E, DEPT, BRN_CODE, EMAIL, PASSWORD, DIV, TEAM, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID , POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, EXPIRED_DATE, HR_POSITION_GRP_ID, HR_POSITION_ID, POSITION_LEVEL, SUPERVISOR1_ID
                from bkiuser
                where dept_id = x.dept_id and div_id = x.div_id
                and team_id = x.team_id
    --            and team_id ='35'
                and position_grp_id >42
    --            and position_grp_id like v_position_grp_id
                and rownum=1
            )loop
                cnt_f := cnt_f+1;
                
                if y.position_grp_id < 42 then
                    if y.position_grp_id in ('41','35','31') then
                        cnt_t := cnt_t+1;
                        dbms_output.put_line('TL up');
                        if y.position_grp_id = '41' then
                            v_name_t := x.team||' (TL) ';
                            v_name_e := x.Division;                   
                        elsif y.position_grp_id = '35' then
                            v_name_t := x.team||' (AVP) ';
                            v_name_e := x.Division;                       
                        elsif y.position_grp_id = '31' then
                            v_name_t := x.team||' (VP) ';
                            v_name_e := x.Division;                  
                        end if;
                    end if;                  
                else
                    v_name_t := x.team;
                    v_name_e := x.Division;            
                end if;
                v_maxuser :=null;
                begin
                    select -- 'IDM'||nvl(lpad(to_number(substr(max(user_id),2))+1,4,'0'),'0001') newuserid
                    to_number(nvl(substr(max(user_id),5),0))+1 
                    into v_maxuser
                    from bkiuser
                    where user_id like v_userPrefix||'%'      ;  
                    
                exception
                    when no_data_found then
                        v_maxuser := 1;
                    when others then
                        null;
                end;
                v_maxuser := v_userPrefix||lpad(v_maxuser,4,'0');    
                dbms_output.put_line('user: '||y.user_id||'newuser: '||v_maxuser||' name:'||y.name_t||' newname: '||v_name_t||' div:'||y.div_id||' positionGrp:'||y.position_grp_id||' position:'||y.position_id);
                Insert into BKIUSER (USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, DEPT, BRN_CODE, EMAIL, PASSWORD, DIV, TEAM, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID , POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, EXPIRED_DATE, HR_POSITION_GRP_ID, HR_POSITION_ID, POSITION_LEVEL, SUPERVISOR1_ID) 
                Values (v_maxuser, Y.TITLE_T, v_name_t, Y.TITLE_E, v_name_e, Y.DEPT, Y.BRN_CODE, Y.EMAIL, v_maxuser||'' , Y.DIV, Y.TEAM, Y.ORG_ID, Y.DEPT_ID, Y.DIV_ID, Y.TEAM_ID, Y.POSITION_GRP_ID , Y.POSITION_ID, Y.HR_ORG_ID, Y.HR_DEPT_ID, Y.HR_DIV_ID, Y.HR_TEAM_ID, Y.JOIN_DATE, Y.CREATE_DATE, trunc(sysdate)+1000, Y.HR_POSITION_GRP_ID, Y.HR_POSITION_ID, Y.POSITION_LEVEL, Y.SUPERVISOR1_ID) 
                ;
                
            end loop; -- bkiuser  Staff   
        end loop;
        dbms_output.put_line('select :'||cnt||' match :'||cnt_f||' TL up :'||cnt_t);
        commit;
        dbms_output.put_line('END============='||v_mode);dbms_output.put_line('');

        v_mode := '++++ create DIV00 +++++';
        dbms_output.put_line(v_mode);
        for x in (  --++++ create TL UP 
            select Dept_id ,(select name_th from org_unit_std x where x.dept_id=a.dept_id and x.div_id ='00') Departmant 
            ,div_id , (select name_th from org_unit_std x where x.dept_id=a.dept_id and x.div_id =a.div_id and team_id='00') Division 
            ,team_id ,name_th Team
            from org_unit_std     a
            where org_id ='01' and cancel_flag is null
            and dept_id = v_inDept
    --        and team_id <> '00' and div_id <> '00'
            and div_id='00'
    --        and team_id='00'
            order by dept_id ,div_id ,team_id 
        )loop
        cnt:=cnt+1;        
        dbms_output.put_line(' dept:'||x.dept_id||' divid:'||x.div_id||' teamid:'||x.team_id||' division: '||x.division||' team: '||x.Team);
            
            for y in (
                select USER_ID, '���ͺ' TITLE_T, NAME_T, '���ͺ'  TITLE_E, NAME_E, DEPT, BRN_CODE, EMAIL, PASSWORD, DIV, TEAM, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID , POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, EXPIRED_DATE, HR_POSITION_GRP_ID, HR_POSITION_ID, POSITION_LEVEL, SUPERVISOR1_ID
                from bkiuser
                where dept_id = x.dept_id and div_id = x.div_id
                and team_id = x.team_id
    --            and team_id ='35'
    --            and position_grp_id <42
    --            and position_grp_id like v_position_grp_id
                and rownum=1
            )loop
                cnt_f := cnt_f+1;
                
                if y.position_grp_id < 42 then
                    if y.position_grp_id in ('41','35','31') then
                        cnt_t := cnt_t+1;
                        dbms_output.put_line('TL up');
                        if y.position_grp_id = '41' then
                            v_name_t := x.team||' (TL) ';
                            v_name_e := x.Division;                   
                        elsif y.position_grp_id = '35' then
                            v_name_t := x.team||' (AVP) ';
                            v_name_e := x.Division;                       
                        elsif y.position_grp_id = '31' then
                            v_name_t := x.team||' (VP) ';
                            v_name_e := x.Division;                  
                        end if;
                    end if;                  
                else
                    v_name_t := x.team;
                    v_name_e := x.Division;            
                end if;
                v_maxuser :=null;
                begin
                    select -- 'IDM'||nvl(lpad(to_number(substr(max(user_id),2))+1,4,'0'),'0001') newuserid
                    to_number(nvl(substr(max(user_id),5),0))+1 
                    into v_maxuser
                    from bkiuser
                    where user_id like v_userPrefix||'%'      ;  
                    
                exception
                    when no_data_found then
                        v_maxuser := 1;
                    when others then
                        null;
                end;
                v_maxuser := v_userPrefix||lpad(v_maxuser,4,'0');    
                dbms_output.put_line('user: '||y.user_id||'newuser: '||v_maxuser||' name:'||y.name_t||' newname: '||v_name_t||' div:'||y.div_id||' positionGrp:'||y.position_grp_id||' position:'||y.position_id);
                Insert into BKIUSER (USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, DEPT, BRN_CODE, EMAIL, PASSWORD, DIV, TEAM, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID , POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, EXPIRED_DATE, HR_POSITION_GRP_ID, HR_POSITION_ID, POSITION_LEVEL, SUPERVISOR1_ID) 
                Values (v_maxuser, Y.TITLE_T, v_name_t, Y.TITLE_E, v_name_e, Y.DEPT, Y.BRN_CODE, Y.EMAIL, v_maxuser||'' , Y.DIV, Y.TEAM, Y.ORG_ID, Y.DEPT_ID, Y.DIV_ID, Y.TEAM_ID, Y.POSITION_GRP_ID , Y.POSITION_ID, Y.HR_ORG_ID, Y.HR_DEPT_ID, Y.HR_DIV_ID, Y.HR_TEAM_ID, Y.JOIN_DATE, Y.CREATE_DATE, trunc(sysdate)+1000, Y.HR_POSITION_GRP_ID, Y.HR_POSITION_ID, Y.POSITION_LEVEL, Y.SUPERVISOR1_ID) 
                ;
                
            end loop; -- bkiuser
        
        end loop;
        dbms_output.put_line('select :'||cnt||' match :'||cnt_f||' TL up :'||cnt_t);
        commit;
        dbms_output.put_line('END============='||v_mode);dbms_output.put_line('');
        
        v_mode := '++++ create TEAM00 +++++';
        dbms_output.put_line(v_mode);
        for x in (  --++++ create TL UP 
            select Dept_id ,(select name_th from org_unit_std x where x.dept_id=a.dept_id and x.div_id ='00') Departmant 
            ,div_id , (select name_th from org_unit_std x where x.dept_id=a.dept_id and x.div_id =a.div_id and team_id='00') Division 
            ,team_id ,name_th Team
            from org_unit_std     a
            where org_id ='01' and cancel_flag is null
            and dept_id = v_inDept
    --        and team_id <> '00' and div_id <> '00'
    --        and div_id='00'
            and team_id='00'
            order by dept_id ,div_id ,team_id 
        )loop
        cnt:=cnt+1;        
        dbms_output.put_line(' dept:'||x.dept_id||' divid:'||x.div_id||' teamid:'||x.team_id||' division: '||x.division||' team: '||x.Team);
            
            for y in (
                select USER_ID, '���ͺ' TITLE_T, NAME_T, '���ͺ'  TITLE_E, NAME_E, DEPT, BRN_CODE, EMAIL, PASSWORD, DIV, TEAM, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID , POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, EXPIRED_DATE, HR_POSITION_GRP_ID, HR_POSITION_ID, POSITION_LEVEL, SUPERVISOR1_ID
                from bkiuser
                where dept_id = x.dept_id and div_id = x.div_id
                and team_id = x.team_id
    --            and team_id ='35'
    --            and position_grp_id <42
    --            and position_grp_id like v_position_grp_id
                and rownum=1
            )loop
                cnt_f := cnt_f+1;
                
                if y.position_grp_id < 42 then
                    if y.position_grp_id in ('41','35','31') then
                        cnt_t := cnt_t+1;
                        dbms_output.put_line('TL up');
                        if y.position_grp_id = '41' then
                            v_name_t := x.team||' (TL) ';
                            v_name_e := x.Division;                   
                        elsif y.position_grp_id = '35' then
                            v_name_t := x.team||' (AVP) ';
                            v_name_e := x.Division;                       
                        elsif y.position_grp_id = '31' then
                            v_name_t := x.team||' (VP) ';
                            v_name_e := x.Division;                  
                        end if;
                    end if;                  
                else
                    v_name_t := x.team;
                    v_name_e := x.Division;            
                end if;
                v_maxuser :=null;
                begin
                    select -- 'IDM'||nvl(lpad(to_number(substr(max(user_id),2))+1,4,'0'),'0001') newuserid
                    to_number(nvl(substr(max(user_id),5),0))+1 
                    into v_maxuser
                    from bkiuser
                    where user_id like v_userPrefix||'%'      ;  
                    
                exception
                    when no_data_found then
                        v_maxuser := 1;
                    when others then
                        null;
                end;
                v_maxuser := v_userPrefix||lpad(v_maxuser,4,'0');    
                dbms_output.put_line('user: '||y.user_id||'newuser: '||v_maxuser||' name:'||y.name_t||' newname: '||v_name_t||' div:'||y.div_id||' positionGrp:'||y.position_grp_id||' position:'||y.position_id);
                Insert into BKIUSER (USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, DEPT, BRN_CODE, EMAIL, PASSWORD, DIV, TEAM, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID , POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, EXPIRED_DATE, HR_POSITION_GRP_ID, HR_POSITION_ID, POSITION_LEVEL, SUPERVISOR1_ID) 
                Values (v_maxuser, Y.TITLE_T, v_name_t, Y.TITLE_E, v_name_e, Y.DEPT, Y.BRN_CODE, Y.EMAIL, v_maxuser||'' , Y.DIV, Y.TEAM, Y.ORG_ID, Y.DEPT_ID, Y.DIV_ID, Y.TEAM_ID, Y.POSITION_GRP_ID , Y.POSITION_ID, Y.HR_ORG_ID, Y.HR_DEPT_ID, Y.HR_DIV_ID, Y.HR_TEAM_ID, Y.JOIN_DATE, Y.CREATE_DATE, trunc(sysdate)+1000, Y.HR_POSITION_GRP_ID, Y.HR_POSITION_ID, Y.POSITION_LEVEL, Y.SUPERVISOR1_ID) 
                ;
                
            end loop; -- bkiuser
        
        end loop;
        dbms_output.put_line('select :'||cnt||' match :'||cnt_f||' TL up :'||cnt_t);
        commit;
        dbms_output.put_line('END============='||v_mode);dbms_output.put_line('');    
        return true;
    EXCEPTION
        WHEN OTHERS THEN
        rollback;
        O_RST := v_mode||' error:'||sqlerrm;
        return false;      
    END createGroupDummyBKIUSER;
    
    FUNCTION assignMenuToUsers(v_user IN VARCHAR2, v_role  IN VARCHAR2,v_assignby  IN VARCHAR2,v_sys  IN VARCHAR2
    ,O_RST  OUT VARCHAR2) RETURN BOOLEAN IS
        cnt number:=0;
        v_pos   varchar2(5);
        v_pos_grp   varchar2(5);      
    BEGIN
        dbms_output.put_line('==== assign ROLE : '||v_role||' ======');            
        begin
            select position_grp_id ,(select abb_name_eng from position_grp_std where position_grp_id =position_grp_id ) c into v_pos_grp ,v_pos
            from bkiuser 
            where user_id =v_user ;
        exception
            when no_data_found then
                v_pos_grp := null;
                v_pos := null;
            when others then
                v_pos_grp := null;
                v_pos := null; 
        end;
            
        for q in (
            select user_id ,title_t ,name_t ,dept_id ,brn_code 
            ,(select priv from clm_user_std where position =v_pos and sysid is not null and  rownum=1) priv
            from bkiuser where user_id = v_user
        )loop
            
            if q.dept_id in ('21','22') then
                Insert into ALLCLM.CLM_USER_STD
                   (USER_ID, TITLE, NAME, POSITION, PRIV, SYSID, PASSWORD, CLM_BR_CODE)
                 Values
                   (q.user_id, q.title_t, q.name_t, V_POS, q.priv, V_SYS, null , q.brn_code);
                   dbms_output.put_line('++++ Add Clm_user_std ++++');
            end if;
                
        end loop;
            
        for x in (
            select menuid ,menudesc
            from idm_mapping_role2menu a
            where roleid = v_role
        )loop
            cnt := cnt+1;
            Insert into ACCOUNT.USER_MODULE  (USER_ID, PROG_CODE, CREATED_BY, CREATED_DATE, PROG_SEQ, EXPIRED_DATE ,ROLE_ID) 
            Values ( v_user , x.menuid , v_assignby , trunc(sysdate) , null , null ,null );
            dbms_output.put_line('no: '||cnt||' menu: '||x.menuid||'  '||x.menudesc);
        end loop;
            
        dbms_output.put_line('==== assign Menu Access : '||v_role||' ======');
        cnt := 0;
        for y in (
            select menuid ,ins ,upd ,del ,sel ,remark
            from idm_mapping_rolemenu_auth a
            where roleid = v_role
        )loop
            cnt := cnt+1;
            Insert into ACCOUNT.USER_ACCESS (USERID, PROGRAM, TRN_DATE, INS, UPD, DEL ,SEL ,REMARK)
            Values  ( v_user , y.menuid, sysdate,y.ins , y.upd , y.del ,y.sel ,y.remark );    
            dbms_output.put_line('no: '||cnt||' menu: '||y.menuid||'  '||'Menu Access');
        end loop;

        commit;
        return true;
    exception
    when others then
        rollback ;
        o_rst := 'error: '||sqlerrm;
        dbms_output.put_line(o_rst);
        return false;
    END   assignMenuToUsers;

--    FUNCTION split_clm_num(v_clm_no IN VARCHAR2) RETURN VARCHAR2 IS
--    
--    BEGIN
--        if v_clm_no is not null then
--            return substr(v_clm_no ,1,4);
--        else
--            return null;
--        end if;
--    END;
--    
--    FUNCTION split_clm_run(v_clm_no  IN VARCHAR2) RETURN NUMBER  IS
--    
--    BEGIN
--        if v_clm_no is not null then
--            return to_number(substr(v_clm_no ,5));
--        else
--            return 0;
--        end if;    
--    END;
--    
    
END P_MANAGE_ROLE;

/
