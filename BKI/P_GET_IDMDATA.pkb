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
  

END P_GET_IDMDATA;
/

