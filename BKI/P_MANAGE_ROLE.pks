CREATE OR REPLACE PACKAGE P_MANAGE_ROLE AS
/******************************************************************************
   NAME:       P_MANAGE_ROLE
   PURPOSE:     script for Manage User Role on BKIAPP

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        24/05/2016      2702       1. Created this package.
   
   Brief.
   1.
   2.After create BKIUSER and setup Menu for each Role (table IDM_MAPPING_ROLE2MENU ,iDM_MAPPING_ROLEMENU_AUTH)
   then run func. assignMenuToUsers
   
******************************************************************************/
    FUNCTION cloneDummyBKIUSER(v_user IN VARCHAR2 ,v_Group  IN VARCHAR2)  RETURN VARCHAR2;    
    /*
    v_user --  user_id for mirroring
    Return NewUser_ID that clone from v_user ,if Failed return NULL
    v_Group    --(C,A,U,O) Claim ,Acc. ,UNW ,Other
    */  

    FUNCTION cloneDummyBKIUSERwithTargetID(v_Oriuser IN VARCHAR2 ,v_Outuser  IN VARCHAR2)  RETURN VARCHAR2;    
    /*
    v_user --  user_id for mirroring
    Return NewUser_ID that clone from v_user ,if Failed return NULL
    v_Outuser    --User_id ที่ต้องการสร้าง  โดยรหัสผ่านจะตรงกับ user_id 
    */  
        
    FUNCTION createGroupDummyBKIUSER(v_inDept IN VARCHAR2 ,v_Group  IN VARCHAR2
    ,O_RST  OUT VARCHAR2) RETURN BOOLEAN;    
    /*
    v_inDept -- DEPT_ID for Query 
    v_Group    --(C,A,U,O) Claim ,Acc. ,UNW ,Other
    */    

    FUNCTION removeUserMenu(v_user IN VARCHAR2 ,O_RST  OUT VARCHAR2) RETURN BOOLEAN ;
    
    FUNCTION assignUserStdRole(v_user IN VARCHAR2 ,O_RST  OUT VARCHAR2) RETURN BOOLEAN;
    
    FUNCTION assignUserSpecialRole(v_user IN VARCHAR2 ,O_RST  OUT VARCHAR2) RETURN BOOLEAN;
      
    FUNCTION assignMenuToUser(v_user IN VARCHAR2, v_role  IN VARCHAR2,v_assignby  IN VARCHAR2
    ,O_RST  OUT VARCHAR2) RETURN BOOLEAN;
    
    FUNCTION isFREEZEMENU(v_user IN VARCHAR2) RETURN BOOLEAN;
    
    FUNCTION isFREEZEMENU_STD(v_user IN VARCHAR2) RETURN BOOLEAN;
    
    FUNCTION isFREEZEMENU_SPC(v_user IN VARCHAR2) RETURN BOOLEAN;
    /*
    v_sys -- MISC     , MTR   (for table CLM_USER_STD.SYSID)
    v_assignby    -- who's run script
    */
    
    FUNCTION split_clm_num(v_clm_no IN VARCHAR2) RETURN VARCHAR2 ;
    
    FUNCTION split_clm_run(v_clm_no  IN VARCHAR2) RETURN NUMBER ;
END P_MANAGE_ROLE;

/
