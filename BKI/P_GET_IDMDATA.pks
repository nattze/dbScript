CREATE OR REPLACE PACKAGE ALLCLM.P_GET_IDMDATA AS
/******************************************************************************
   NAME:       P_GET_IDMDATA
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/02/2016      2702       1. Created this package.
******************************************************************************/

  FUNCTION ASSIGN_BKIUSER_ROLE(i_userid IN varchar2 ,i_username IN varchar2 ,i_dept IN varchar2 ,i_div IN varchar2 ,i_team IN varchar2 ,i_roles IN varchar2
    ,action IN varchar2 ,p_rst    OUT varchar2)  RETURN BOOLEAN ; -- True = success /False = error ,description see on P_RST
  
  FUNCTION ASSIGN_ROLE_MENU(i_userid IN varchar2 ,role_type IN varchar2 ,p_rst    OUT varchar2)  RETURN BOOLEAN; 
  --role_tyep = 'Standard' , 'Special' True = success /False = error ,description see on P_RST

  PROCEDURE GET_EMPLOYEE_UPDATE( I_USERID IN VARCHAR2 ,I_ACCREQ IN VARCHAR2 ,I_CLMREQ IN VARCHAR2 ,I_UNWREQ IN VARCHAR2 ,O_RST OUT VARCHAR2);  --สำหรับปรับข้อมูลพนักงานรายคน Special Role
  
  PROCEDURE GET_EMPLOYEE_UPDATE( I_USERID IN VARCHAR2,I_DATE IN DATE ,O_RST OUT VARCHAR2); -- สำหรับปรับข้อมูล แบบ Batch ในรายการพนักงานที่มีการ new/modify ตาท I_DATE
  
  PROCEDURE GET_EMPLOYEE_UPDATE( I_USERID IN VARCHAR2 ,O_RST OUT VARCHAR2);  -- สำหรับปรับข้อมูลพนักงานรายคน (ข้อมูล bkiuser และ standard role)
  -- input I_USERID-> if null = get all staff that was modified on system date; if not null get staff that matched with i_userid 
  -- output O_RST -> if complete value = null ,if error value is error message 
  
  PROCEDURE EMAIL_NOTIFY(i_date IN DATE );
  
  FUNCTION GET_SYSOWNER(i_roleid IN VARCHAR2) RETURN VARCHAR2; --สำหรับดึงระบบที่เป็นเจ้าจอง ROLE
  
  --    สำหรับ mapping ข้อมูล user ว่าตรงกับ role ใดบ้าง จาก table IDM_MAPPING_ROLE |O_MSG = null คือสำเร็จ ,Not null คือมี Error Message 
  PROCEDURE MAPPING_STDROLE(I_USERID IN VARCHAR2 
    ,ROLE_UNDERWRITING OUT VARCHAR2 ,ROLE_CLAIM OUT VARCHAR2 ,ROLE_ACCOUNTING OUT VARCHAR2 
    ,ROLE_CRM_TSEC OUT VARCHAR2 ,ROLE_CRM_FSEC OUT VARCHAR2 ,ROLE_CRM_RSEC OUT VARCHAR2 
    ,ROLE_BPM OUT VARCHAR2 ,ROLE_PPS OUT VARCHAR2 
    ,ROLE_EFORM_S OUT VARCHAR2 ,ROLE_EFORM_P OUT VARCHAR2
    ,O_MSG OUT VARCHAR2);  
    
  PROCEDURE BACKUP_HR_EMP(I_USERID IN VARCHAR2 ,O_MSG OUT VARCHAR2 ); -- O_MSG = null คือสำเร็จ ,Not null คือมี Error Message     
    
  PROCEDURE BACKUP_BKIUSER(I_USERID IN VARCHAR2 ,O_MSG OUT VARCHAR2 ); -- O_MSG = null คือสำเร็จ ,Not null คือมี Error Message  
  
  FUNCTION GET_ROLELEVEL(I_ROLE IN VARCHAR2) RETURN VARCHAR2; -- for Support CRM ,EFORM  
       
  --    สำหรับ assign menu จาก standard role to BKIAPP BKIService Menu  
  -- I_DATE คือวันที่ต้องการกวาดข้อมูลมา assign menu ,I_USERID คือระบุเฉพาะ user ที่ต้องการ assign |O_MSG = null คือสำเร็จ ,Not null คือมี Error Message  
  PROCEDURE NoIDM_ASSIGN_MENU(I_DATE IN DATE  ,I_USERID IN VARCHAR2
    ,O_MSG OUT VARCHAR2); -- O_MSG = null คือสำเร็จ ,Not null คือมี Error Message  
          
END P_GET_IDMDATA;
/
