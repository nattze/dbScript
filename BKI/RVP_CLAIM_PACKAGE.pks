CREATE OR REPLACE PACKAGE ALLCLM.RVP_CLAIM_PACKAGE AS
  TYPE sys_refcursor IS REF CURSOR;

  TYPE v_ref_cursor1 IS REF CURSOR;  
  TYPE v_ref_cursor2 IS REF CURSOR;  
/******************************************************************************
   NAME:       RVP_CLAIM_PACKAGE
   PURPOSE: Connect to RVP Web Service
   Develop by: Taywin.S
   
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        13/01/2015      2702       1. Created this package.
******************************************************************************/

    PROCEDURE REQUEST_POLICY(i_searchno IN VARCHAR2 ,i_logid IN VARCHAR2 ,o_rst OUT VARCHAR2) ;
    PROCEDURE GET_RVP_ENQ(i_searchno IN VARCHAR2 ,i_logid IN VARCHAR2,
        out_rvp_enq_rep  OUT sys_refcursor,out_rvp_enq_rep_policy OUT sys_refcursor,out_rvp_enq_rep_benefit OUT sys_refcursor); 
    PROCEDURE R_INSET_RVP_ENQ_REQ    
    (SearchNo       IN varchar2,   
     LogId              IN varchar2,
     InsurerID          IN varchar2,   
     InsurerName     IN varchar2,
     HospitalID         IN varchar2,
     HospitalName    IN varchar2,
     PolicyNo    IN varchar2,
     SubPolicy1  IN varchar2,
     SubPolicy2  IN varchar2,
     IDCard  IN varchar2,
     CardType    IN varchar2,
     Prefix  IN varchar2,
     Fname   IN varchar2,
     Lname   IN varchar2,
     PatientType     IN varchar2,
     TreatmentType   IN varchar2,
     AccDate     IN varchar2,
     AdmissionDate   IN varchar2,
     REF1    IN varchar2,
     REF2      IN varchar2 ); 
     
     PROCEDURE INSERT_BLANK_RESPONSE(i_searchno IN VARCHAR2 ,i_logid IN VARCHAR2 ,i_return IN VARCHAR2 ,i_err IN VARCHAR2 ,i_err_desc IN VARCHAR2) ;
     
     PROCEDURE GET_POLICY_COVERAGE(i_searchno IN VARCHAR2 ,i_logid IN VARCHAR2,
     i_policyno  IN VARCHAR2 ,i_idcard  IN VARCHAR2 ,i_prefix  IN VARCHAR2 ,i_fname  IN VARCHAR2 ,i_lname  IN VARCHAR2 ,
     i_accdate  IN DATE ,o_rst OUT VARCHAR2) ;

     PROCEDURE GET_POLICY_COVERAGE2(i_searchno IN VARCHAR2 ,i_logid IN VARCHAR2,
     i_policyno  IN VARCHAR2 ,i_idcard  IN VARCHAR2 ,i_prefix  IN VARCHAR2 ,i_fname  IN VARCHAR2 ,i_lname  IN VARCHAR2 ,
     i_accdate  IN DATE ,o_rst OUT VARCHAR2) ;
     
     PROCEDURE GET_MED_REMARK(i_pol_no in varchar2 ,i_pol_run in number ,i_fleet_seq in number ,o_remark out varchar2) ;
          
     FUNCTION CHECK_POLICY_MAIN(vPOLICY IN VARCHAR2 ,vLOSS_DATE IN VARCHAR2 ,vRecpt IN VARCHAR2 ,vFLEET IN VARCHAR2  ,vIDNO IN VARCHAR2  ,P_POLICY OUT v_ref_cursor1 ,P_COVER OUT v_ref_cursor2 ,RST OUT VARCHAR2) RETURN VARCHAR2 ;

END RVP_CLAIM_PACKAGE;
/

