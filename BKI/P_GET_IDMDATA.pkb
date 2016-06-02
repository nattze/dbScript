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
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
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
                ,HIST_ID ,HIST_REC_DATE
                )
                (
                select USER_ID, TITLE_T, NAME_T, TITLE_E, NAME_E, BRN_CODE, TEL, EMAIL, PASSWORD, MENU_ID, ORG_ID, DEPT_ID, DIV_ID, TEAM_ID, POSITION_GRP_ID, POSITION_ID, HR_ORG_ID, HR_DEPT_ID, HR_DIV_ID, HR_TEAM_ID, JOIN_DATE, CREATE_DATE, CREATE_BY, EXPIRED_DATE, NEW_EMAIL, OLD_EMAIL, HR_POSITION_GRP_ID, HR_POSITION_ID, SUPERVISOR1_ID
                ,CHANNEL ,DEPT ,UNIT ,FAX ,POSTN_ID ,DIV ,TEAM ,TERMINATION_FLAG ,TERMINATION_DATE ,OS_FLAG ,TEL_EXT ,AMEND_DATE ,AMEND_BY ,ACCT_LOCK ,ACCT_LOCK_DATE ,LAST_LOGON ,LAST_LOGOUT ,POSITION_LEVEL ,JOB_DESC
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
END P_GET_IDMDATA;
/

