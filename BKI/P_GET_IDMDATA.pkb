CREATE OR REPLACE PACKAGE BODY ALLCLM.P_GET_IDMDATA AS
/******************************************************************************
   NAME:       P_GET_IDMDATA
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/02/2016      2702       1. Created this package.
******************************************************************************/
    FUNCTION ASSIGN_BKIUSER_ROLE(i_userid IN varchar2 ,i_username IN varchar2 ,i_dept IN varchar2 ,i_div IN varchar2 ,i_team IN varchar2 ,i_roles IN varchar2
    ,action IN varchar2 ,p_rst    OUT varchar2)  RETURN BOOLEAN IS -- True = success /False = error ,description see on P_RST
      
    BEGIN
        
        if i_userid is null or i_dept is null or i_div is null or i_team is null or i_roles is null or action is null then
            p_rst := 'some required parameter not found!';
            return false;
        end if;
    
        BEGIN      
            Insert into ALLCLM.IDM_ASSIGN_ROLE_LOG
            (USER_ID, USER_NAME, DEPT, DIV, TEAM, ROLES, ACTION, SUBMIT_DATE)
            Values
            (i_userid, i_username ,i_dept , i_div , i_team, 
            i_roles ,action , sysdate );
        EXCEPTION
            WHEN OTHERS THEN
            rollback;
            p_rst := 'error: '||sqlerrm ;
            return false;
        END;    
        
        commit;
    return true;
    END ASSIGN_BKIUSER_ROLE;


    FUNCTION ASSIGN_ROLE_MENU(i_userid IN varchar2 ,role_type IN varchar2 ,p_rst    OUT varchar2)  RETURN BOOLEAN IS -- True = success /False = error ,description see on P_RST
        dumm    boolean;
        O_RST2   varchar2(250);
        v_to    varchar2(2000);
         v_from varchar2(50):= 'AdminClm@bangkokinsurance.com' ;   
--         v_dbins varchar2(10);  
--         v_whatsys varchar2(30);  
         x_body varchar2(4000);  
         x_subject varchar2(1000);  
         o_err  varchar2(250);      
         v_action   varchar2(10);
    BEGIN
        
        if i_userid is null or role_type is null then
            p_rst := 'some required parameter not found!';
            return false;
        end if;
        
        IF role_type = 'Standard' THEN
            begin 
                select action into v_action
                from hr_emp
                where user_id = i_userid
--                and action = 'create'
                ;           
            exception
                when no_data_found then
                    v_action := null;
                when others then
                    v_action :=null ;
            end;
            
            -- call UNW Package for setup UNW Parameter and Menu
            if v_action = 'create' then
                dbms_output.put_line('offZa');
                BkiUserUtil.set_user_brn_code(i_userid ,o_err);
                BkiUserUtil.set_user_email(i_userid ,o_err);
                BkiUserUtil.set_user_tel_fax(i_userid ,o_err);
--                BkiUserUtil.initial_menu(i_userid ,o_err);            
                BkiUserUtil.assign_unw_authorize(i_userid ,o_err);
            end if;
            -- End call UNW Package for setup UNW Parameter and Menu
        
            if NOT p_manage_role.assignUserStdRole(I_USERID ,O_RST2) then
                FOR X in (  
                    select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail   
                    from nc_med_email a  
                    where module = 'IDM-PROV'   
                    and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)  
                    and direction = 'TO' and CANCEL is null   
        --            and user_id='2702'
                ) LOOP  
                    v_to := v_to || x.ldap_mail ||';' ;  
                END LOOP;        
                x_subject :='Auto Assign Standard Role ['||I_USERID||']';
                x_body :='Issue on assign role for User: '||I_USERID||' <br/>'||O_RST2;
                if v_to is not null then  
                nc_health_package.generate_email(v_from, v_to ,  
                x_subject,   
                x_body   
                ,''  
                ,'');   
                -- nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_NOTICE_APPRV' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_pay:'||I_pay||' success::' ,'success' ,v_rst) ;  
                end if;                            
            end if;
        ELSE
            if NOT p_manage_role.assignUserSpecialRole(I_USERID ,O_RST2) then
                FOR X in (  
                    select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail   
                    from nc_med_email a  
                    where module = 'IDM-PROV'   
                    and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)  
                    and direction = 'TO' and CANCEL is null   
        --            and user_id='2702'
                ) LOOP  
                    v_to := v_to || x.ldap_mail ||';' ;  
                END LOOP;        
                x_subject :='Auto Assign Special Role ['||I_USERID||']';
                x_body :='Issue on assign role for User: '||I_USERID||' <br/>'||O_RST2;
                if v_to is not null then  
                nc_health_package.generate_email(v_from, v_to ,  
                x_subject,   
                x_body   
                ,''  
                ,'');   
                -- nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_NOTICE_APPRV' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_pay:'||I_pay||' success::' ,'success' ,v_rst) ;  
                end if;                            
            end if;        
        END IF;                
        return true;
    EXCEPTION
        WHEN OTHERS THEN
        p_rst := 'error: '||sqlerrm;
        return false;
    END ASSIGN_ROLE_MENU;


    PROCEDURE GET_EMPLOYEE_UPDATE(I_USERID IN VARCHAR2 ,I_ACCREQ IN VARCHAR2 ,I_CLMREQ IN VARCHAR2 ,I_UNWREQ IN VARCHAR2 ,O_RST OUT VARCHAR2) IS
        v_date  date:=sysdate;
        v_hist  number:=99;   
        v_seq   number:=0;
        dumm    boolean;
--        v_user  varchar2(10):='WSIDM';
    BEGIN
        IF I_USERID is null THEN -- sweep
            O_RST := 'not found USER_ID';
            RETURN;       
        ELSE -- by user_id
            BEGIN        
                SELECT IDM_HIST_BKIUSER_SEQ.NEXTVAL into v_hist        
                FROM dual;        
            EXCEPTION        
                WHEN  NO_DATA_FOUND THEN        
                    v_hist := 0;        
                WHEN  OTHERS THEN        
                    v_hist := 0;        
            END;             
            
            v_seq := p_manage_role.getSeq;
            for x in (
            select I_ACCREQ SPE_ROLE
            from dual 
            union 
            select I_CLMREQ SPE_ROLE
            from dual 
            union
            select I_UNWREQ SPE_ROLE
            from dual 
            )loop 
                dbms_output.put_line('SpecialRole: '||x.SPE_ROLE);
                
                if x.SPE_ROLE is not null then
                    for R in (
                        select regexp_substr(x.SPE_ROLE,'[^,;]+', 1, level) innerRole from dual
                        connect by regexp_substr(x.SPE_ROLE, '[^,;]+', 1, level) is not null            
                    )loop
                        dbms_output.put_line('Inner Role: '||R.innerRole);  -- unique role for assign to menu               
                        dumm := p_manage_role.KeepRole(I_USERID ,R.innerRole ,'Special' ,v_seq ,v_date);
                    end loop; --R
                end if;
            end loop;   --X
                        
            FOR x in (select user_id ,modified 
            from HR_EMP
            where user_id = I_USERID
            )LOOP            
            BEGIN
                Insert into HR_EMP_HISTORY
                (
                USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
                ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
                ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,I_ACCREQ BKI_ACCREQROLEID ,I_CLMREQ BKI_CLAIMREQROLEID ,I_UNWREQ BKI_UNDERWRITEREQROLEID,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
                ,v_hist ,v_date 
                from hr_emp
                where user_id = X.USER_ID
                );

                Insert into BKIUSER_HISTORY
                (
                USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
                ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
                ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC
                ,v_hist ,v_date
                from bkiuser
                where user_id = X.USER_ID
                );            
            EXCEPTION
                WHEN OTHERS THEN
                    O_RST := 'get by user have error: '||sqlerrm;
                    RETURN;
            END;            
            END LOOP; --select HR_EMP        
        END IF;          
        COMMIT;  
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            O_RST := 'error: '||sqlerrm;
    END GET_EMPLOYEE_UPDATE;
    
    PROCEDURE GET_EMPLOYEE_UPDATE( I_USERID IN VARCHAR2 ,I_DATE IN DATE ,O_RST OUT VARCHAR2) IS
        v_date  date:=sysdate;
        v_hist  number:=99;   
        dumm    boolean;
        O_RST2   varchar2(250);
        v_to    varchar2(2000);
         v_from varchar2(50):= 'AdminClm@bangkokinsurance.com' ;   
--         v_dbins varchar2(10);  
--         v_whatsys varchar2(30);  
         x_body varchar2(4000);  
         x_subject varchar2(1000);  
    BEGIN
        IF I_DATE is not null THEN
            v_date := i_date;
        END IF;
        
        IF I_USERID is null THEN -- sweep
            BEGIN        
                SELECT IDM_HIST_BKIUSER_SEQ.NEXTVAL into v_hist        
                FROM dual;        
            EXCEPTION        
                WHEN  NO_DATA_FOUND THEN        
                    v_hist := 0;        
                WHEN  OTHERS THEN        
                    v_hist := 0;        
            END;           
            FOR x in (select user_id ,modified 
            from HR_EMP
            where trunc(modified) = v_date
            )LOOP           
            
            dumm := P_MANAGE_ROLE.SweepRole(X.USER_ID);     -- keep Standard Role in Table   

            BEGIN
                Insert into HR_EMP_HISTORY
                (
                USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
                ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
                ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
                ,v_hist ,v_date 
                from hr_emp
                where user_id = X.USER_ID
                );

                Insert into BKIUSER_HISTORY
                (
                USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
                ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC 
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
                ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC
                ,v_hist ,v_date
                from bkiuser
                where user_id = X.USER_ID
                );            
            EXCEPTION
                WHEN OTHERS THEN
                    O_RST := 'get all modified have error: '||sqlerrm;
                    RETURN;
            END;            
            END LOOP; --select HR_EMP
       
        ELSE -- by user_id
            BEGIN        
                SELECT IDM_HIST_BKIUSER_SEQ.NEXTVAL into v_hist        
                FROM dual;        
            EXCEPTION        
                WHEN  NO_DATA_FOUND THEN        
                    v_hist := 0;        
                WHEN  OTHERS THEN        
                    v_hist := 0;        
            END;             
            FOR x in (select user_id ,modified 
            from HR_EMP
            where user_id = I_USERID
            )LOOP   
            
            dumm := P_MANAGE_ROLE.SweepRole(X.USER_ID);     -- keep Standard Role in Table        
                      
            BEGIN
                Insert into HR_EMP_HISTORY
                (
                USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
                ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
                ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
                ,v_hist ,v_date 
                from hr_emp
                where user_id = X.USER_ID
                );

                Insert into BKIUSER_HISTORY
                (
                USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
                ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
                ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC
                ,v_hist ,v_date
                from bkiuser
                where user_id = X.USER_ID
                );            
            EXCEPTION
                WHEN OTHERS THEN
                    O_RST := 'get by user have error: '||sqlerrm;
                    RETURN;
            END;            
            END LOOP; --select HR_EMP        
        END IF;          
        COMMIT;  
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            O_RST := 'error: '||sqlerrm;
    END GET_EMPLOYEE_UPDATE;
  
    PROCEDURE GET_EMPLOYEE_UPDATE( I_USERID IN VARCHAR2 ,O_RST OUT VARCHAR2) IS
        v_date  date:=sysdate;
        v_hist  number:=99;   
        dumm    boolean;
        O_RST2   varchar2(250);
        v_to    varchar2(2000);
         v_from varchar2(50):= 'AdminClm@bangkokinsurance.com' ;   
--         v_dbins varchar2(10);  
--         v_whatsys varchar2(30);  
         x_body varchar2(4000);  
         x_subject varchar2(1000);          
    BEGIN
        IF I_USERID is null THEN -- sweep
            BEGIN        
                SELECT IDM_HIST_BKIUSER_SEQ.NEXTVAL into v_hist        
                FROM dual;        
            EXCEPTION        
                WHEN  NO_DATA_FOUND THEN        
                    v_hist := 0;        
                WHEN  OTHERS THEN        
                    v_hist := 0;        
            END;           
            FOR x in (select user_id ,modified 
            from HR_EMP
            where trunc(modified) = trunc(sysdate)
            )LOOP    
            
            dumm := P_MANAGE_ROLE.SweepRole(X.USER_ID);     -- keep Standard Role in Table   

            BEGIN
                Insert into HR_EMP_HISTORY
                (
                USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
                ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
                ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
                ,v_hist ,v_date 
                from hr_emp
                where user_id = X.USER_ID
                );

                Insert into BKIUSER_HISTORY
                (
                USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
                ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
                ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC
                ,v_hist ,v_date
                from bkiuser
                where user_id = X.USER_ID
                );            
            EXCEPTION
                WHEN OTHERS THEN
                    O_RST := 'get all modified have error: '||sqlerrm;
                    RETURN;
            END;            
            END LOOP; --select HR_EMP
       
        ELSE -- by user_id
            BEGIN        
                SELECT IDM_HIST_BKIUSER_SEQ.NEXTVAL into v_hist        
                FROM dual;        
            EXCEPTION        
                WHEN  NO_DATA_FOUND THEN        
                    v_hist := 0;        
                WHEN  OTHERS THEN        
                    v_hist := 0;        
            END;             
            FOR x in (select user_id ,modified 
            from HR_EMP
            where user_id = I_USERID
            )LOOP            
            
            dumm := P_MANAGE_ROLE.SweepRole(X.USER_ID);     -- keep Standard Role in Table   

            BEGIN
                Insert into HR_EMP_HISTORY
                (
                USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
                ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
                ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
                ,v_hist ,v_date 
                from hr_emp
                where user_id = X.USER_ID
                );

                Insert into BKIUSER_HISTORY
                (
                USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
                ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
                ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC
                ,v_hist ,v_date
                from bkiuser
                where user_id = X.USER_ID
                );            
            EXCEPTION
                WHEN OTHERS THEN
                    O_RST := 'get by user have error: '||sqlerrm;
                    RETURN;
            END;            
            END LOOP; --select HR_EMP        
        END IF;          
        COMMIT;  
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            O_RST := 'error: '||sqlerrm;
    END GET_EMPLOYEE_UPDATE;
    
    PROCEDURE EMAIL_NOTIFY(i_date IN DATE ) IS  
     v_to varchar2(2000);  
     v_cc varchar2(1000);  
     v_bcc varchar2(1000);  
     v_allcc varchar2(2000);  
     v_from varchar2(50):= 'AdminClm@bangkokinsurance.com' ;   
     v_dbins varchar2(10);  
     v_whatsys varchar2(30);  
     x_body varchar2(4000);  
     x_subject varchar2(1000);  
     v_listPerson varchar2(2000);  
       
     v_logrst varchar2(200);  
     v_link varchar2(200);  
     v_clmmen varchar2(10);  
     v_remark varchar2(500);  
          
     v_rst varchar2(1000);  
       
     v_cnt1 number:=0;  
     
     v_cntPerson number:=0;  
       
     i_sts varchar2(10);  
    BEGIN  
        BEGIN
            select count(*) into v_cntPerson
            from hr_emp_history
            where trunc(modified) = i_date;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               v_cntPerson := 0;
            WHEN OTHERS THEN
                v_cntPerson := 0;
        END;    
        dbms_output.put_line('v_cntPerson='||v_cntPerson);
        IF v_cntPerson = 0 THEN
            return;
        END IF;
    
        FOR X in (  
            select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail   
            from nc_med_email a  
            where module = 'IDM-PROV'   
            and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)  
            and direction = 'BCC' and CANCEL is null   
        ) LOOP  
            v_bcc := v_bcc || x.ldap_mail ||';' ;  
        END LOOP;  

        FOR X in (  
            select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail   
            from nc_med_email a  
            where module = 'IDM-PROV'   
            and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)  
            and direction = 'TO' and CANCEL is null   
--            and user_id='2702'
        ) LOOP  
            v_to := v_to || x.ldap_mail ||';' ;  
        END LOOP;  
                   
        begin   
            select UPPER(substr(instance_name,1,8)) instance_name   
            into v_dbins  
            from v$instance;
               
            if v_dbins='UATBKIIN' then  
                v_whatsys := '[ระบบทดสอบ]';  
            else   
                v_whatsys := null;  
            end if;   
        exception   
            when no_data_found then   
                v_dbins := null;  
            when others then   
                v_dbins := null;  
        end;   
           
        if v_to is not null then  
        
            v_listPerson := null;
            FOR lst in (
                select user_id 
--                ,title_th||' '||first_name_th||' '||last_name_th NAME
                ,first_name_th NAME
                ,org_unit_id ,org_unit_th ,position_grp_th ,org_group_th job_desc ,supervisor1_id
                ,action ,employ_date ,depart_date 
                ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID
                from hr_emp_history
                where trunc(modified) = i_date
            ) LOOP
                if v_cntPerson > 30 then
                    v_listPerson :=  v_listPerson||'<tr><td>'||lst.user_id||'</td></tr>';                   
                else
                    v_listPerson :=  v_listPerson||'<tr><td>'||lst.user_id||'</td>'||'<td>'||lst.NAME||'</td>'||'<td>'||lst.org_unit_id||'</td>'||'<td>'||lst.action||'</td>'||
                '<td>'||lst.employ_date||'</td>'||'<td>'||lst.depart_date||'</td></tr>';               
                end if;
                
            END LOOP;
                    
            x_subject := 'รายการพนักงานเปลี่ยนแปลง วันที่ '||to_char(i_date,'dd/mm/yy')||' จาก HRdata '||v_whatsys;   
            
            if v_cntPerson > 30 then
            X_BODY := '<!DOCTYPE html>'||  
                '<html lang="en">'||'<head><meta charset="utf-8">'||  
                '<title>รายการพนักงานเปลี่ยนแปลง HRdata</title>'||'</head>'||  
                '<body style="font-family:''Angsana New'';background-color:#dff1f8">'||  
                '<h2 align="center" style="color:blue;">รายการพนักงานเปลี่ยนแปลง วันที่ '||to_char(i_date,'dd/mm/yy')||' จาก HRdata จำนวน '||v_cntPerson||' รายการ</h2>'||  
                '<div>'||  
                '<table border="1" style="color:blue;border:thin;padding:4px;margin:4px; ">'||
                '<thead style="background-color:lightblue;color:blue ">'||
                '<tr>'||
                '<td>USER_ID</td>'||
                '</tr>'||
                '</thead>'||
                '<tbody>'||
                v_listPerson||    
                '</tbody>'||
                '</table>'||
                '<br/>'||  
                '<h3 style="color:brown">ขณะนี้ข้อมูลได้ update เข้า table BKIUSER แล้ว </h3>'||
                 '<p style="color:red;">มีรายการ>30 ตัดแสดงแต่ user_id</p>'||
                '</div>'||   
                '</body></html>' ;                    
            else
                X_BODY := '<!DOCTYPE html>'||  
                '<html lang="en">'||'<head><meta charset="utf-8">'||  
                '<title>รายการพนักงานเปลี่ยนแปลง HRdata</title>'||'</head>'||  
                '<body style="font-family:''Angsana New'';background-color:#dff1f8">'||  
                '<h2 align="center" style="color:blue;">รายการพนักงานเปลี่ยนแปลง วันที่ '||to_char(i_date,'dd/mm/yy')||' จาก HRdata จำนวน '||v_cntPerson||' รายการ</h2>'||  
                '<div>'||  
                '<table border="1" style="color:blue;border:thin;padding:4px;margin:4px; ">'||
                '<thead style="background-color:lightblue;color:blue ">'||
                '<tr>'||
                '<td>USER_ID</td>'||'<td>NAME</td>'||'<td>ORGUNIT</td>'||'<td>ACTION</td>'||
                '<td>EMPLOY_DATE</td>'||'<td>DEPART_DATE</td>'||
                '</tr>'||
                '</thead>'||
                '<tbody>'||
                v_listPerson||    
                '</tbody>'||
                '</table>'||
                '<br/>'||  
                '<h3 style="color:brown">ขณะนี้ข้อมูลได้ update เข้า table BKIUSER แล้ว </h3>'||
                '</div>'||   
                '</body></html>' ;              
            end if;

        end if;   
--
--        dbms_output.put_line('dummy to: '||v_to );   
--        dbms_output.put_line('dummy cc: '||v_cc );  
--               
--        if v_dbins='DBBKIINS' then  
--        null;   
--        else   
--        v_to := v_bcc; -- for test  
--        v_cc := ''; -- for test  
--        end if;   
        dbms_output.put_line('length(x_body)='||length(x_body));   
        dbms_output.put_line(x_body);  
           
        dbms_output.put_line('to: '||v_to );   
        dbms_output.put_line('allcc: '||v_allcc );   
        dbms_output.put_line('bcc: '||v_bcc );   
        if v_to is not null then  
        nc_health_package.generate_email(v_from, v_to ,  
        x_subject,   
        x_body   
        ,v_cc  
        ,v_bcc);   
        -- nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_NOTICE_APPRV' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_pay:'||I_pay||' success::' ,'success' ,v_rst) ;  
        end if;  
      
    EXCEPTION  
     WHEN OTHERS THEN  
     --NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail Bancas' ,'Error: '||sqlerrm ,v_logrst);  
     nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_IDM' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_date:'||I_date||' error::'||sqlerrm ,'error' ,v_rst) ;  
     dbms_output.put_line('Error: '||sqlerrm );  
    END EMAIL_NOTIFY; --email_notice bancas   
    
    FUNCTION GET_SYSOWNER(i_roleid IN VARCHAR2) RETURN VARCHAR2 IS
      sys_owner  VARCHAR2(100);
    BEGIN
      select val2 into sys_owner
      from BKIUSER_ROLE a ,IDM_CONSTANT b
      where roleid = i_roleid
      and a.roleowner = b.val1(+)
      ;      
      return sys_owner;
    EXCEPTION  
     WHEN NO_DATA_FOUND THEN  
     RETURN '';      
     WHEN OTHERS THEN  
     dbms_output.put_line('Error: '||sqlerrm );  
     RETURN '';
    END GET_SYSOWNER; --email_notice bancas       

  /*      สำหรับ mapping ข้อมูล user ว่าตรงกับ role ใดบ้าง จาก table IDM_MAPPING_ROLE  */  
    PROCEDURE MAPPING_STDROLE(I_USERID IN VARCHAR2 
      ,ROLE_UNDERWRITING OUT VARCHAR2 ,ROLE_CLAIM OUT VARCHAR2 ,ROLE_ACCOUNTING OUT VARCHAR2 
      ,ROLE_CRM_TSEC OUT VARCHAR2 ,ROLE_CRM_FSEC OUT VARCHAR2 ,ROLE_CRM_RSEC OUT VARCHAR2 
      ,ROLE_BPM OUT VARCHAR2 ,ROLE_PPS OUT VARCHAR2
      ,ROLE_EFORM_S OUT VARCHAR2 ,ROLE_EFORM_P OUT VARCHAR2
      ,O_MSG OUT VARCHAR2)IS -- O_MSG = null คือสำเร็จ ,Not null คือมี Error Message     
      v_pass  boolean;
      v_match  boolean;
    BEGIN
      for emp in (
        select a.user_id ,title_th ,first_name_th ,last_name_th ,substr(org_unit_id,3,2) dept_id ,substr(org_unit_id,5,2) div_id ,substr(org_unit_id,7,2) team_id
        ,org_unit_th ,b.brn_code ,UPPER(b.job_desc) job_desc ,b.pl_code ,b.position_id 
        from hr_emp a ,bkiuser b
        where a.user_id = I_USERID
        and a.user_id = b.user_id(+)    
      )loop    
        ROLE_UNDERWRITING :=null;
        ROLE_CLAIM :=null;
        ROLE_ACCOUNTING :=null;
        ROLE_CRM_TSEC :=null;
        ROLE_CRM_FSEC :=null;
        ROLE_CRM_RSEC :=null;
        ROLE_BPM :=null;
        ROLE_PPS := null;
        ROLE_EFORM_S :=null;
        ROLE_EFORM_P :=null;
        dbms_output.put_line('user_id:'||emp.user_id||' unit:'||emp.org_unit_th||' deptid:'||emp.dept_id||' divid:'||emp.div_id||' teamid:'||emp.team_id
        ||' bbrn_codeanch:'||emp.brn_code||' pl_code:'||emp.pl_code||' position_id:'||emp.position_id||' job_desc:'||emp.job_desc);
        dbms_output.put_line('---------------------------------------------------------');
        for mapp in(
          select a.roleid ,nvl(deptid,'ALL') deptid ,nvl(divid,'ALL') divid ,nvl(teamid,'ALL') teamid ,nvl(branch,'ALL') branch ,nvl(pl_code,'ALL') pl_code 
          ,nvl(position_id,'ALL') position_id ,UPPER(nvl(job_desc,'ALL')) job_desc ,a.rolelevel ,a.roleowner
          --,p_get_idmdata.GET_SYSOWNER(a.roleid) sysowner
          ,(select val2 
          from BKIUSER_ROLE br ,IDM_CONSTANT b
          where roleid = a.roleid
          and br.roleowner = b.val1(+)) sysowner      
          from idm_mapping_role a 
          where 1=1 
          and (deptid =  emp.dept_id or nvl(deptid ,'ALL' ) = 'ALL')   
          --and a.roleid = 'BRN_ACC_STAFF'
          and a.roleid in (select x.roleid from bkiuser_role x where UPPER(roletype) = 'STANDARD')   
        )loop
          v_pass := true;
          v_match := false;
          --dbms_output.put_line('MAPP roleid:'||mapp.roleid||' sysowner:'||mapp.sysowner||' deptid:'||mapp.deptid||' divid:'||mapp.divid||' teamid:'||mapp.teamid 
          --||' branch:'||mapp.branch||' pl_code:'||mapp.pl_code||' position_id:'||mapp.position_id||' job_desc:'||mapp.job_desc);
          if v_pass then -- check Dept
            if mapp.deptid in ('ALL' ,emp.dept_id )  then --Pass  Dept
                 --dbms_output.put_line('match deptid....');
                 v_pass := true;
            else
                 if substr(mapp.deptid,1,1) = '!' then -- Case Except
                    if  substr(mapp.deptid,2) <> emp.dept_id then
                        --dbms_output.put_line('match dept_id 2....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;
                 else  -- Case Exact
                    if  mapp.deptid = emp.dept_id then
                        --dbms_output.put_line('match dept_id 3....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;                
                 end if;
            end if;
          end if;
          if v_pass then -- check Div
            if mapp.divid in ('ALL' ,emp.div_id ) then --Pass  Div
                 --dbms_output.put_line('match divid....');
                 v_pass := true;
            else
                 if substr(mapp.divid,1,1) = '!' then -- Case Except
                    if  substr(mapp.divid,2) <> emp.div_id then
                        --dbms_output.put_line('match divid 2....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;
                 else  -- Case Exact
                    if  mapp.divid = emp.div_id then
                        --dbms_output.put_line('match divid 3....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;                
                 end if;
            end if;
          end if;      
          if v_pass then -- check Team
            if mapp.teamid in ('ALL' ,emp.team_id ) then --Pass  Team
                 --dbms_output.put_line('match teamid....');
                 v_pass := true;
            else
                 if substr(mapp.teamid,1,1) = '!' then -- Case Except
                    if  substr(mapp.teamid,2) <> emp.team_id then
                        --dbms_output.put_line('match teamid 2....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;
                 else  -- Case Exact
                    if  mapp.teamid = emp.team_id then
                        --dbms_output.put_line('match teamid 3....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;                
                 end if;
            end if;
          end if;      
          if v_pass then -- check Branch
--            dbms_output.put_line('emp.brn_code='||emp.brn_code||' mapp.branch='||mapp.branch);
            if mapp.branch in ('ALL' ,emp.brn_code ) then --Pass  Branch
                 --dbms_output.put_line('match Branch....');
                 v_pass := true;
            else
                 if substr(mapp.branch,1,1) = '!' then -- Case Except
                    if  substr(mapp.branch,2) <> emp.brn_code then
                        --dbms_output.put_line('match Branch2....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;
                 else  -- Case Exact
                    if  mapp.branch = emp.brn_code then
                        --dbms_output.put_line('match Branch3....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;                
                 end if;
            end if;
          end if;         
          if v_pass then -- check pl_code
            if mapp.pl_code in ('ALL' ,emp.pl_code ) then --Pass  pl_code
                 --dbms_output.put_line('match pl_code....');
                 v_pass := true;
            else
                 if substr(mapp.pl_code,1,1) = '!' then -- Case Except
                    if  substr(mapp.pl_code,2) <> emp.pl_code then
                        --dbms_output.put_line('match pl_code 2....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;
                 else  -- Case Exact
                    if  mapp.pl_code = emp.pl_code then
                        --dbms_output.put_line('match pl_code 3....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;                
                 end if;
            end if;
          end if;  
          if v_pass then -- check position_id
            if mapp.position_id in ('ALL' ,emp.position_id ) then --Pass  position_id
                 --dbms_output.put_line('match position_id....');
                 v_pass := true;
            else
                 if substr(mapp.position_id,1,1) = '!' then -- Case Except
                    if  substr(mapp.position_id,2) <> emp.position_id then
                        --dbms_output.put_line('match position_id 2....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;
                 else  -- Case Exact
                    if  mapp.position_id = emp.position_id then
                        --dbms_output.put_line('match position_id 3....');
                        v_pass := true;        
                    else
                        v_pass := false;  
                    end if;                
                 end if;
            end if;
          end if;   
          if v_pass then -- check job_desc
            if mapp.job_desc in ('ALL' ,emp.job_desc ) then --Pass  job_desc
                 --dbms_output.put_line('match job_desc....');
                 v_pass := true;
                 v_match := true;
            else
                 if substr(mapp.job_desc,1,1) = '!' then -- Case Except
                    if  substr(mapp.job_desc,2) <> nvl(emp.job_desc,'N/A')then
                        --dbms_output.put_line('match job_desc 2....');
                        v_pass := true;     
                        v_match := true;   
                    else
                        v_pass := false;  
                    end if;
                 else  -- Case Exact
                    if  mapp.job_desc = emp.job_desc then
                        --dbms_output.put_line('match job_desc 3....');
                        v_pass := true; 
                        v_match := true;       
                    else
                        v_pass := false;  
                    end if;                
                 end if;
            end if;
          end if;        
          if v_match then
            CASE mapp.sysowner
              WHEN 'CLAIM' THEN ROLE_CLAIM := ROLE_CLAIM||mapp.roleid||',';
              WHEN 'UNDERWRITING' THEN ROLE_UNDERWRITING := ROLE_UNDERWRITING||mapp.roleid||',';
              WHEN 'ACCOUNTING' THEN ROLE_ACCOUNTING := ROLE_ACCOUNTING||mapp.roleid||',';
              WHEN 'CRM' THEN 
                CASE UPPER(P_GET_IDMDATA.GET_ROLELEVEL(mapp.roleid)) 
                  WHEN 'TEAM SECURITY' THEN ROLE_CRM_TSEC := ROLE_CRM_TSEC||mapp.roleid||',';   
                  WHEN 'FIELD SECURITY' THEN ROLE_CRM_FSEC := ROLE_CRM_FSEC||mapp.roleid||',';  
                  WHEN 'SECURITY ROLE' THEN ROLE_CRM_RSEC := ROLE_CRM_RSEC||mapp.roleid||',';  
                  ELSE null;
                END CASE;                
              WHEN 'BPM' THEN ROLE_BPM := ROLE_BPM||mapp.roleid||',';
              WHEN 'EFORM' THEN 
                IF UPPER(P_GET_IDMDATA.GET_ROLELEVEL(mapp.roleid)) = 'PERSONGROUP' THEN
                   ROLE_EFORM_P := ROLE_EFORM_P||mapp.roleid||',';              
                ELSE
                   ROLE_EFORM_S := ROLE_EFORM_S||mapp.roleid||',';  
                END IF;            
              ELSE null;
            END CASE;
--            dbms_output.put_line('++++ Match Role:'||mapp.roleid||' +++++');   
          end if; -- Matched Role
                    
        end loop; --mapp
        dbms_output.put_line('ROLE_CLAIM='||ROLE_CLAIM);
        dbms_output.put_line('ROLE_UNDERWRITING='||ROLE_UNDERWRITING);
        dbms_output.put_line('ROLE_ACCOUNTING='||ROLE_ACCOUNTING);
        dbms_output.put_line('ROLE_CRM_TSEC='||ROLE_CRM_TSEC);
        dbms_output.put_line('ROLE_CRM_FSEC='||ROLE_CRM_FSEC);
        dbms_output.put_line('ROLE_CRM_RSEC='||ROLE_CRM_RSEC);
        dbms_output.put_line('ROLE_BPM='||ROLE_BPM);
        dbms_output.put_line('ROLE_PPS='||ROLE_PPS);
        dbms_output.put_line('ROLE_EFORM_S='||ROLE_EFORM_S);
        dbms_output.put_line('ROLE_EFORM_P='||ROLE_EFORM_P);
        dbms_output.put_line('---------------------------------------------------------');
      end loop; --emp
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('error:'||sqlerrm);
        O_MSG := 'error:'||sqlerrm;
        --rollback;
    END MAPPING_STDROLE;  
    
    PROCEDURE BACKUP_HR_EMP(I_USERID IN VARCHAR2 ,O_MSG OUT VARCHAR2) IS
        v_date  date:=sysdate;
        v_hist  number:=99;   
        v_found varchar2(10);     
    BEGIN
        IF I_USERID is null THEN 
           O_MSG := 'กรุณาระบุ USER_ID';     
        END IF;

        BEGIN        
            SELECT user_id into v_found        
            FROM hr_emp
            WHERE user_id = I_USERID;        
        EXCEPTION        
            WHEN  NO_DATA_FOUND THEN        
                v_found := null;        
            WHEN  OTHERS THEN        
                v_found := null;        
        END;  
        
        IF v_found is null THEN 
           O_MSG := 'ไม่พบ USER_ID';     
        END IF;
                        
        BEGIN        
            SELECT IDM_HIST_BKIUSER_SEQ.NEXTVAL into v_hist        
            FROM dual;        
        EXCEPTION        
            WHEN  NO_DATA_FOUND THEN        
                v_hist := 0;        
            WHEN  OTHERS THEN        
                v_hist := 0;        
        END;   
            
        Insert into HR_EMP_HISTORY
        (
        USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
        ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
        ,MODIFIED_ROLE ,BKI_BPM_ROLE_ID ,SUPERVISOR2_ID ,BKI_EFORM_S_ROLE_ID ,BKI_EFORM_P_ROLE_ID ,BKI_PPS_ROLE_ID
        ,BKI_CRM_RSEC_ROLE_ID ,BKI_CRM_TSEC_ROLE_ID ,BKI_CRM_FSEC_ROLE_ID
        ,HIST_ID ,HIST_REC_DATE
        )
        (
        select USER_ID, TITLE_TH, FIRST_NAME_TH, LAST_NAME_TH, TITLE_ENG, FIRST_NAME_ENG, LAST_NAME_ENG, WORK_STATUS, EMPLOY_DATE ,DEPART_DATE, PROBATION_END_DATE, ORG_UNIT_ID, ORG_UNIT_TH, ORG_UNIT_ENG, POSITION_ID, POSITION_TH, POSITION_ENG, POSITION_GRP_TH, POSITION_GRP_ENG, CREATED_BY, CREATED_DATE, POSITION_LEVEL_ENG, POSITION_GRP_ID, SUPERVISOR1_ID
        ,ORG_GROUP_TH ,ORG_GROUP_ENG ,ACTION ,BKI_ACCREQROLEID ,BKI_CLAIMREQROLEID ,BKI_UNDERWRITEREQROLEID ,BKI_ACC_ROLE_ID  ,BKI_CLAIM_ROLE_ID ,BKI_UNDERWRITE_ROLE_ID ,MODIFIED  ,DISABLESTATE 
        ,MODIFIED_ROLE ,BKI_BPM_ROLE_ID ,SUPERVISOR2_ID ,BKI_EFORM_S_ROLE_ID ,BKI_EFORM_P_ROLE_ID ,BKI_PPS_ROLE_ID
        ,BKI_CRM_RSEC_ROLE_ID ,BKI_CRM_TSEC_ROLE_ID ,BKI_CRM_FSEC_ROLE_ID
        ,v_hist ,v_date 
        from hr_emp
        where user_id = I_USERID
        );
         
        COMMIT;   
    EXCEPTION
        WHEN OTHERS THEN
            O_MSG := 'backup HR_EMP error: '||sqlerrm;
            ROLLBACK;
    END BACKUP_HR_EMP;            

    PROCEDURE BACKUP_BKIUSER(I_USERID IN VARCHAR2 ,O_MSG OUT VARCHAR2) IS
        v_date  date:=sysdate;
        v_hist  number:=99;   
        v_found varchar2(10);     
    BEGIN
        IF I_USERID is null THEN 
           O_MSG := 'กรุณาระบุ USER_ID';     
        END IF;

        BEGIN        
            SELECT user_id into v_found        
            FROM bkiuser
            WHERE user_id = I_USERID;        
        EXCEPTION        
            WHEN  NO_DATA_FOUND THEN        
                v_found := null;        
            WHEN  OTHERS THEN        
                v_found := null;        
        END;  
        
        IF v_found is null THEN 
           O_MSG := 'ไม่พบ USER_ID';     
        END IF;
                        
        BEGIN        
            SELECT IDM_HIST_BKIUSER_SEQ.NEXTVAL into v_hist        
            FROM dual;        
        EXCEPTION        
            WHEN  NO_DATA_FOUND THEN        
                v_hist := 0;        
            WHEN  OTHERS THEN        
                v_hist := 0;        
        END;   
            
        Insert into BKIUSER_HISTORY
        (
        USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
        ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
        ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC 
        ,HIST_ID ,HIST_REC_DATE
        )
        (
        select USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
        ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
        ,PL_CODE ,CLM_BRN ,SPECIAL_FLAG ,FREEZEMENUSTD ,FREEZEMENUSPC
        ,v_hist ,v_date
        from bkiuser
        where user_id = I_USERID
        );         
        COMMIT;   
    EXCEPTION
        WHEN OTHERS THEN
            O_MSG := 'backup BKIUSER error: '||sqlerrm;
            ROLLBACK;
    END BACKUP_BKIUSER;            

    FUNCTION GET_ROLELEVEL(I_ROLE IN VARCHAR2) RETURN VARCHAR2 IS -- for Support CRM ,EFORM   
      v_rolelevel  varchar2(200);       
    BEGIN
      select rolelevel into v_rolelevel
      from bkiuser_role a
      where roleid = I_ROLE ;
      return v_rolelevel;
    EXCEPTION        
        WHEN  NO_DATA_FOUND THEN        
            return '';        
        WHEN  OTHERS THEN        
            return '';         
    END GET_ROLELEVEL; 
    
    /*      สำหรับ assign menu จาก standard role to BKIAPP BKIService Menu
    -- O_MSG = null คือสำเร็จ ,Not null คือมี Error Message  */  
    PROCEDURE NoIDM_ASSIGN_MENU(I_DATE IN DATE ,I_USERID IN VARCHAR2
      ,O_MSG OUT VARCHAR2) IS         
      v_found    varchar2(10);
      dumm       boolean;
      P_RST      varchar2(250);
    BEGIN
      if I_USERID is null and I_DATE is null then
         O_MSG := 'กรุณาระบุ User หรือ วันที่ต้องการกวาดข้อมูลก่อน'; return;   
      end if;
      
      if I_DATE is not null then
        BEGIN
          select a.user_id into v_found 
          from hr_emp a ,bkiuser b
          where a.user_id = b.user_id(+)
          and a.user_id like nvl(I_USERID ,'%') 
          and trunc(modified_role) = I_DATE
          and freezemenustd is null 
          and rownum=1;
        EXCEPTION        
            WHEN  NO_DATA_FOUND THEN        
                v_found := null;
            WHEN  OTHERS THEN        
                v_found := null; 
        END;  
        dbms_output.put_line('v_found I_DATE='||v_found);
        
        if v_found is null then O_MSG := 'ไม่พบข้อมูล user_id สำหรับ assign menu'; return;   end if;        
        
        FOR x in (
          select a.user_id 
          from hr_emp a ,bkiuser b
          where a.user_id = b.user_id(+)
          and a.user_id like nvl(I_USERID ,'%') 
          and trunc(modified_role) = I_DATE
          and freezemenustd is null          
        )LOOP        
          dumm := P_MANAGE_ROLE.SweepRole(X.user_id);     -- keep Standard Role in Table    
          
          dumm := p_get_idmdata.ASSIGN_ROLE_MENU(X.user_id  ,'Standard' ,P_RST)  ;  
        END LOOP; --X   
        
      elsif I_USERID is not null then -- case user   
        BEGIN
          select a.user_id into v_found 
          from hr_emp a ,bkiuser b
          where a.user_id = b.user_id(+)
          and a.user_id = I_USERID
          and rownum=1;
        EXCEPTION        
            WHEN  NO_DATA_FOUND THEN        
                v_found := null;
            WHEN  OTHERS THEN        
                v_found := null; 
        END;  
        dbms_output.put_line('v_found I_USERID='||v_found);
        
        if v_found is null then O_MSG := 'ไม่พบข้อมูล user_id สำหรับ assign menu'; return;   end if;  
                
        if p_manage_role.isFREEZEMENU_STD(I_USERID) then
            O_MSG := 'user_id: '||O_MSG||' was set FreezeMenu ,cannot remove menu';
            return ;           
        end if;
        
        dumm := P_MANAGE_ROLE.SweepRole(I_USERID);     -- keep Standard Role in Table    
        
        dumm := p_get_idmdata.ASSIGN_ROLE_MENU(I_USERID  ,'Standard' ,O_MSG)  ;    
             
      end if; --check user or date 
        
    EXCEPTION               
        WHEN  OTHERS THEN        
            O_MSG := 'error Assign Menu :'||sqlerrm;         
    END NoIDM_ASSIGN_MENU;       
         
END P_GET_IDMDATA;
/
