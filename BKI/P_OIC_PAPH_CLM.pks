CREATE OR REPLACE PACKAGE ALLCLM.P_OIC_PAPH_CLM AS
/******************************************************************************
   NAME:       P_OIC_PAPH_CLM
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        14/08/2015      2702       1. Created this package.
******************************************************************************/
    PROCEDURE get_PAPH_Claim(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);

    PROCEDURE get_PAPH_Claim(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_cnt_clm OUT NUMBER ,o_cnt_payment OUT NUMBER);

    PROCEDURE getMain_PAPH_Claim(i_type IN VARCHAR2 ,i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);

    PROCEDURE Clear_PAPH_Claim(i_type IN VARCHAR2 ,i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);
        
    PROCEDURE get_PA_Claim_out(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);
    
    PROCEDURE get_PA_Claim_outpaid(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);

    PROCEDURE get_PA_Claim_paid(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);

    PROCEDURE get_PA_Claim_outcwp(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);    
    
    PROCEDURE get_PA_Claim_cwp(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);     
    
    PROCEDURE get_GM_Claim_close(i_datefr IN DATE ,i_dateto IN DATE  ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);
    
    PROCEDURE get_GM_Claim_reserve(i_datefr IN DATE ,i_dateto IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);
    
    PROCEDURE get_GM_Claim_out(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);
    
    PROCEDURE get_GM_Claim_outpaid(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);

    PROCEDURE get_GM_Claim_paid(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);
    
    PROCEDURE get_GM_Claim_outcwp(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);

    PROCEDURE get_GM_Claim_cwp(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);
              
    PROCEDURE get_PA_Claim_close(i_datefr IN DATE ,i_dateto IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);

    PROCEDURE get_PA_Claim_reserve(i_datefr IN DATE ,i_dateto IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);
        
    FUNCTION get_ClmType(i_grp IN VARCHAR2 ,i_opd IN VARCHAR2 ,i_premcode IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION get_PaidBy(i_grp IN VARCHAR2 ,i_paidtype IN VARCHAR2) RETURN VARCHAR2;
      
    PROCEDURE get_Citizen(i_grp IN VARCHAR2 ,i_polno IN VARCHAR2 ,i_polrun IN NUMBER ,i_fleet IN NUMBER ,i_recpt IN NUMBER ,i_lossdate IN DATE
    ,o_insname OUT  VARCHAR2 ,o_id OUT VARCHAR2);  
    
    PROCEDURE get_Citizen(i_grp IN VARCHAR2 ,i_polno IN VARCHAR2 ,i_polrun IN NUMBER ,i_fleet IN NUMBER ,i_recpt IN NUMBER ,i_lossdate IN DATE
    ,i_clmno IN VARCHAR2, i_payno IN VARCHAR2
    ,o_insname OUT  VARCHAR2 ,o_id OUT VARCHAR2);      
      
    PROCEDURE GET_PA_RESERVE(P_CLMNO IN VARCHAR2 ,V_KEY OUT NUMBER , V_RST OUT VARCHAR2) ;  
    
    FUNCTION hasINS_DATA(P_CLMNO IN VARCHAR2) RETURN BOOLEAN;
    
    FUNCTION get_Coverage1(i_polno  IN VARCHAR2 ,i_polrun  IN VARCHAR2 ,i_fleet IN NUMBER ,i_clmno  IN VARCHAR2 ,i_payno  IN VARCHAR2, i_grp IN VARCHAR2 ,i_opd IN VARCHAR2 ,i_premcode IN VARCHAR2 ,i_risk  IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION get_Coverage2(i_polno  IN VARCHAR2 ,i_polrun  IN VARCHAR2 ,i_fleet IN NUMBER ,i_clmno  IN VARCHAR2 ,i_payno  IN VARCHAR2, i_grp IN VARCHAR2 ,i_opd IN VARCHAR2 ,i_premcode IN VARCHAR2 ,i_risk  IN VARCHAR2) RETURN VARCHAR2;
    
    PROCEDURE EMAIL_LOG(i_subject IN VARCHAR2 ,i_message IN VARCHAR2 ) ;

    PROCEDURE EMAIL_LOG(i_subject IN VARCHAR2 ,i_message IN VARCHAR2 ,i_to  IN VARCHAR2) ;
        
    PROCEDURE get_PA_Claim_v2(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);

    PROCEDURE get_GM_Claim_v2(i_datefr IN DATE ,i_dateto IN DATE ,i_asdate IN DATE ,i_user IN VARCHAR2 ,o_rst OUT VARCHAR2);
    
    FUNCTION check_have_paid(P_CLMNO IN VARCHAR2 ,P_MODE IN VARCHAR2) RETURN BOOLEAN; --P_MODE 1 check has paid ,2 check double paid

    FUNCTION check_have_EC(P_CLMNO IN VARCHAR2) RETURN BOOLEAN; 

END P_OIC_PAPH_CLM;
/
