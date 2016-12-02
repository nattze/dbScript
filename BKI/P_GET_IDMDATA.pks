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
END P_GET_IDMDATA;
/

