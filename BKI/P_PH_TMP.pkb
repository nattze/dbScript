CREATE OR REPLACE PACKAGE BODY P_PH_TMP AS
/******************************************************************************
   NAME:       P_PH_TMP
   PURPOSE: สำหรับทดลองสร้าง Procedure / Function ใหม่ๆ เพื่อไม่กระทบกับ Package ที่มีการใช้งานอยู่ 

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        22/08/2017      2702       1. Created this package body.
******************************************************************************/


    PROCEDURE CHECK_LIMIT(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_benecode IN VARCHAR2
    ,v_pdflag IN VARCHAR2 ,v_days IN NUMBER ,v_amount IN NUMBER ,v_clmno IN VARCHAR2 ,o_remain_day OUT NUMBER ,o_remain_amt OUT NUMBER) IS
        o_type  varchar2(2);
        m_rst   varchar2(250);
    BEGIN
        misc.healthutil.get_pa_health_type(v_polno ,v_polrun ,o_type);
        o_remain_amt := v_amount;
    EXCEPTION
    WHEN OTHERs THEN
        nc_health_package.WRITE_LOG  ( 'PH_CLM' ,'CHECK_LIMIT' ,'Error' ,'polno:'||v_polno||v_polrun||' plan:'||v_plan||' bene:'||v_benecode||
        'flag:'||v_pdflag||' amt:'||v_amount||' clm:'||v_clmno||' ='||sqlerrm , m_rst)   ;  
    END CHECK_LIMIT;

    PROCEDURE CHECK_OPD(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_benecode IN VARCHAR2
    ,v_poltype IN VARCHAR2 ,v_days IN NUMBER ,v_amount IN NUMBER ,v_clmno IN VARCHAR2 ,o_remain_day OUT NUMBER ,o_remain_amt OUT NUMBER) IS
        o_type  varchar2(2);
        m_rst   varchar2(250);
    BEGIN
        if v_poltype = 'HG' then
            null;
        elsif v_poltype = 'HI' then
            null;
        end if;
        
    EXCEPTION
    WHEN OTHERs THEN
        nc_health_package.WRITE_LOG  ( 'PH_CLM' ,'CHECK_LIMIT' ,'Error' ,'polno:'||v_polno||v_polrun||' plan:'||v_plan||' bene:'||v_benecode||
        ' amt:'||v_amount||' clm:'||v_clmno||' ='||sqlerrm , m_rst)   ;  
    END CHECK_OPD;
    
END P_PH_TMP;

/
