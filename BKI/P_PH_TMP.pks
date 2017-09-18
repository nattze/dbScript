CREATE OR REPLACE PACKAGE P_PH_TMP AS
/******************************************************************************
   NAME:       P_PH_TMP
   PURPOSE:  สำหรับทดลองสร้าง Procedure / Function ใหม่ๆ เพื่อไม่กระทบกับ Package ที่มีการใช้งานอยู่ 

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        22/08/2017      2702       1. Created this package.
******************************************************************************/

  PROCEDURE CHECK_LIMIT(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_benecode IN VARCHAR2
  ,v_pdflag IN VARCHAR2 ,v_days IN NUMBER ,v_amount IN NUMBER ,v_clmno IN VARCHAR2 ,o_remain_day OUT NUMBER ,o_remain_amt OUT NUMBER);

  PROCEDURE CHECK_OPD(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_benecode IN VARCHAR2
   ,v_poltype IN VARCHAR2 ,v_days IN NUMBER ,v_amount IN NUMBER ,v_clmno IN VARCHAR2 ,o_remain_day OUT NUMBER ,o_remain_amt OUT NUMBER);
END P_PH_TMP;

/
