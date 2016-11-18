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


    PROCEDURE GET_EMPLOYEE_UPDATE(I_USERID IN VARCHAR2 ,I_ACCREQ IN VARCHAR2 ,I_CLMREQ IN VARCHAR2 ,I_UNWREQ IN VARCHAR2 ,O_RST OUT VARCHAR2) IS
        v_date  date:=sysdate;
        v_hist  number:=99;   
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
     
END P_GET_IDMDATA;
/

