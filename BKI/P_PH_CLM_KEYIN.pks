CREATE OR REPLACE package ALLCLM.P_PH_CLM_KEYIN is

 PROCEDURE GET_BENEFIT(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_type IN VARCHAR2 
       ,v_benecode IN VARCHAR2 ,O_Benefit Out sys_refcursor, o_ret out varchar2);

      PROCEDURE GET_Init_KEYIN(
             o_hospital out sys_refcursor,
             o_claim_type out sys_refcursor,
             o_lcd10      out sys_refcursor,
             o_bene_type out sys_refcursor,
             o_clm_sts   out sys_refcursor,
             o_admission out sys_refcursor,
             o_bill_list out sys_refcursor,
             o_user      out sys_refcursor
         );

         PROCEDURE GET_revise_KEYIN(
             in_clm_no in varchar2,
             o_clm_data out sys_refcursor,
             o_pol_data out sys_refcursor,
             o_list_billing out sys_refcursor,
             o_list_benefit out sys_refcursor,
             o_master_benefit out sys_refcursor,
             o_list_ri out sys_refcursor
          );

     procedure gen_paph_benefit_detail(
           in_clm_no in varchar2,
           in_user_id in varchar2,
           out_cursor out sys_refcursor
       ) ;
       
       
     procedure calRI(
           in_clm_no in varchar2,
           out_cursor out sys_refcursor
       );
       
       
       procedure get_enquiry_claim_detail(
             in_clm_no in varchar2,
             o_clm_data out sys_refcursor,
             o_pol_data out sys_refcursor,
             o_list_billing out sys_refcursor,
             o_list_benefit out sys_refcursor,
             o_master_benefit out sys_refcursor,
             o_list_ri out sys_refcursor,
             o_list_payment out sys_refcursor,
             o_list_ri_payment out sys_refcursor,
             o_list_payee  out sys_refcursor
         );

end P_PH_CLM_KEYIN;
/

