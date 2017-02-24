CREATE OR REPLACE PACKAGE ALLCLM."NMTR_PACKAGE" IS
/******************************************************************************    
   NAME:       NMTR_PAPERLESS    
   PURPOSE: Get Authurized NonMotorClaim User for Approve payment     
    
   REVISIONS:    
   Ver        Date        Author           Description    
   ---------  ----------  ---------------  ------------------------------------    
   1.0        14/6/2011   Taywin          1. Created this package.    
******************************************************************************/    
  TYPE v_ref_cursor1 IS REF CURSOR;    
  TYPE v_ref_cursor2 IS REF CURSOR;     
  TYPE v_ref_cursor3 IS REF CURSOR;     
  TYPE v_ref_cursor4 IS REF CURSOR;    
  TYPE v_ref_cursor5 IS REF CURSOR;    
  TYPE v_ref_cursor6 IS REF CURSOR;    
  TYPE v_ref_cursor7 IS REF CURSOR;    
  TYPE v_ref_cursor8 IS REF CURSOR;   
    
  PROCEDURE SET_CLM_GM_RECOV(P_CLM_NO IN VARCHAR2 ,P_PAY_NO IN VARCHAR2 ,P_REC_AMT IN NUMBER     
  ,V_RESULT OUT VARCHAR2 );  /* V_RESULT = null คือ complete */           
      
  PROCEDURE NC_WAIT_FOR_APPROVE(P_POSITION IN VARCHAR2,    
                                                        P_SUBSYSID IN VARCHAR2,    
                                                        P_LOSS_AMT IN NUMBER,    
                            P_USER_ID  OUT v_ref_cursor1);    
                                
  PROCEDURE NC_WAIT_FOR_APPROVE2(P_USERID IN VARCHAR2,    
                                                        P_SUBSYSID IN VARCHAR2,    
                                                        P_LOSS_AMT IN NUMBER,    
                            P_USER_ID  OUT v_ref_cursor2);                                
    
  PROCEDURE UPDATE_OPEN_CLM(P_REG_NO IN VARCHAR2 ,V_RESULT OUT VARCHAR2 );  /* V_RESULT = null คือ complete */           
  PROCEDURE your_pol  (In_pol_no    IN VARCHAR,    
                 In_pol_run   IN NUMBER,     
                          In_recpt_seq IN NUMBER,    
                          In_loc_seq   IN NUMBER,    
                          In_ri_code   IN VARCHAR2,    
                          In_ri_br_code IN VARCHAR2,    
                          In_ri_sub_type   IN VARCHAR2,    
                          In_ri_type   IN VARCHAR2,    
                          In_lf_flag   IN VARCHAR2,    
                          In_date      IN DATE,    
                          Out_yourpol  OUT VARCHAR) ;                              
  FUNCTION nc_get_co_sumins(i_no IN VARCHAR2, i_run IN NUMBER, i_date IN DATE, i_flag IN VARCHAR2) RETURN NUMBER;    
  FUNCTION nc_get_hide_flag(i_no IN VARCHAR2, i_run IN NUMBER, i_end_seq IN NUMBER)   RETURN VARCHAR2;    
  FUNCTION GET_STS_OPEN(P_REG_NO IN VARCHAR2) RETURN BOOLEAN ;    
  FUNCTION nc_get_ri_name (in_ri_code varchar2, in_br_code varchar2) RETURN varchar2;    
  FUNCTION get_first_close ( v_clm_no VARCHAR2 ) RETURN date;    
  PROCEDURE nc_get_pla_no (p_pla_no out varchar2,p_message out varchar2 ) ;    
  PROCEDURE nc_get_lsa_no (p_lsa_no out varchar2,p_message out varchar2 ) ;    
  PROCEDURE nc_get_cashcall (p_pol_yr in varchar2, p_clm_yr in varchar2, p_ri_code in varchar2, p_ri_br_code in varchar2, p_lf_flag in varchar2, p_ri_type1 in varchar2,     
                                             p_ri_type2 in varchar2, p_ri_reserve_amt in number, p_curr_rate in number, p_out_cashcall out varchar2, p_out_lines out number) ;    
  PROCEDURE nc_get_ri_share (p_lossclm in number, p_lossri in number, p_rishr out number ) ;    
  PROCEDURE nc_get_block_limit (In_blk in varchar2, out_blk_limit out number, out_fqs_limit out number) ;    
  PROCEDURE nc_update_clm_sts (p_clm_no in varchar2, p_prod_grp in varchar2, p_prod_type in varchar2, p_close_type in varchar2, p_err_message out varchar2) ;    
  PROCEDURE nc_update_reopen_sts (p_clm_no in varchar2, p_prod_grp in varchar2, p_prod_type in varchar2, p_err_message out varchar2) ;    
  PROCEDURE nc_allclm_table (p_clm_no in varchar2, p_prod_grp in varchar2, p_prod_type in varchar2, p_co_type in varchar2, p_co_re in varchar2, p_bki_shr in number,     
                                             p_agent_code in varchar2, p_agent_seq in varchar2, p_insert_flag in varchar2, p_err_message out varchar2)  ;    
  PROCEDURE nc_allclm_mas (p_clm_no in varchar2, p_prod_grp in varchar2, p_prod_type in varchar2, p_err_message out varchar2)  ;
  PROCEDURE nc_insert_fire_table (v_clm_no in varchar2, v_err_message out varchar2) ;    
  PROCEDURE nc_update_fire_table (v_clm_no in varchar2, v_err_message out varchar2) ;    
  PROCEDURE nc_insert_mrn_table (v_clm_no in varchar2, v_err_message out varchar2) ;    
  PROCEDURE nc_update_mrn_table (v_clm_no in varchar2, v_err_message out varchar2) ;    
  PROCEDURE nc_insert_hull_table (v_clm_no in varchar2, v_err_message out varchar2) ;    
  PROCEDURE nc_update_hull_table (v_clm_no in varchar2, v_err_message out varchar2) ;    
  PROCEDURE nc_insert_misc_table (v_clm_no in varchar2, v_co_type in varchar2, v_co_re in varchar2, v_bki_shr in number, v_agent_code in varchar2, v_agent_seq in varchar2, v_err_message out varchar2) ;    
  PROCEDURE nc_update_misc_table (v_clm_no in varchar2, v_err_message out varchar2) ;    
  PROCEDURE nc_update_fire_mas (v_clm_no in varchar2, v_err_message out varchar2) ;
  PROCEDURE nc_update_mrn_mas (v_clm_no in varchar2, v_err_message out varchar2) ;
  PROCEDURE nc_update_hull_mas (v_clm_no in varchar2, v_err_message out varchar2) ;
  PROCEDURE nc_update_misc_mas (v_clm_no in varchar2, v_err_message out varchar2) ;    
  PROCEDURE nc_insert_reinsurance_tmp (p_sts_key in number, p_pla_no in varchar2, p_cashcall in varchar2, p_ri_type1 in varchar2, p_ri_code in varchar2, p_ri_br_code in varchar2, p_ri_type2 in varchar2, p_lf_flag in varchar2,     
                                                             p_ri_share in number, pri_res_amt in number, p_lines in number) ;        
  PROCEDURE nc_insert_fir_block_reloss_tmp (p_pol_no in varchar2, p_sts_key in number, p_block in varchar2, p_block_limit in number, p_first in number, p_second in number, p_fpre in number, p_ret in number,    
                                                                   p_mfp in number, p_frqs in number, p_tgr in number, p_sum_ins in number, p_pol_run in number, p_fqs_limit in number, p_fqs in number, p_ffs in number);                                                                 
  PROCEDURE nc_block_reloss_fire (p_loss_date in date, p_pol_no in varchar2, p_pol_run in number, p_block in varchar2, p_channel in varchar2,    
                                                    Out_f1st out number, Out_f2nd out number, Out_mfp out number, Out_fpre out number,    
                                                    Out_frqs out number, Out_rent out number, Out_tgr  out number, Out_sumins  out number) ;    
  PROCEDURE nc_block_reloss_accum (p_block in varchar2, p_pol_no in varchar2, p_pol_run in varchar2, p_loss_date in date, p_loc_seq in number,    
                                                        Out_f1st  out number, Out_f2nd  out number, Out_fpre  out number, Out_rent  out number,    
                                                        Out_fqs   out number, Out_ffs     out number, Out_sumins out number, Out_tgr  out number) ;    
  PROCEDURE nc_block_reloss_fire_f1st (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_f1st out number) ;    
  PROCEDURE nc_block_reloss_fire_f2nd (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_f2nd out number) ;    
  PROCEDURE nc_block_reloss_fire_frqs  (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_frqs out number) ;    
  PROCEDURE nc_block_reloss_fire_sumins (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_sumins out number) ;    
  PROCEDURE nc_block_reloss_fire_mfp (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_mfp out number) ;    
  PROCEDURE nc_block_reloss_fire_pre  (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_pre out number) ;    
  PROCEDURE nc_block_reloss_fire_rent  ( p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_rent out number) ;    
  PROCEDURE nc_block_reloss_fire_fqs  (p_pol_no in  varchar2, p_pol_run  in  number, p_end_seq  in  number, p_loss_date  in  date, Out_fqs  out  number) ;    
  PROCEDURE nc_block_reloss_fire_ffs  (p_pol_no  in  varchar2, p_pol_run  in  number, p_end_seq  in  number, p_loss_date  in  date, Out_ffs  out  number) ;    
  PROCEDURE nc_block_reloss_misc_rent  (p_pol_no  in  varchar2, p_pol_run  in  number, p_loc_seq  in  number, p_end_seq  in  number, p_loss_date  in  date, Out_rent  out  number) ;    
  PROCEDURE nc_block_reloss_misc_fqs  (p_pol_no in  varchar2, p_pol_run  in  number, p_loc_seq  in  number, p_end_seq  in number,  p_loss_date  in  date, Out_fqs  out  number) ;    
  PROCEDURE nc_block_reloss_misc_ffs  (p_pol_no  in  varchar2, p_pol_run  in  number, p_loc_seq  in  number, p_end_seq  in  number, p_loss_date in  date, Out_ffs  out  number) ;    
  PROCEDURE nc_block_reloss_misc_sumins  (p_pol_no  in  varchar2, p_pol_run  in  number, p_loc_seq  in  number, p_end_seq  in  number, p_loss_date  in  date, Out_sumins  out  number) ;    
  FUNCTION nc_fire_fac_ri_share (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loc_seq in number, p_loss_date in date,    
                                           p_ri_code in  varchar2, p_ri_br_code in  varchar2, p_lf_flag in  varchar2, p_ri_type1 in  varchar2, p_ri_type2 in varchar2 ) RETURN number;    
  FUNCTION nc_mrn_ri_share (p_pol_no  in varchar2, p_pol_run  in  number, p_pol_seq  in number, p_end_seq  in number,   
                                             p_ri_code  in varchar2, p_ri_br_code  in  varchar2, p_lf_flag  in  varchar2, p_ri_type1 in varchar2, p_ri_type2 in  varchar2 ) RETURN number;   
  PROCEDURE nc_misc_ri_reserve1 (p_pol_no in varchar2, p_pol_run in number, p_alc_re in varchar2, p_loss_date in date, p_recpt_seq in number, p_loc_seq in number,     
                                                    p_tot_sum_ins out number, p_sum_shr out number, w_recpt out number, w_loc out number, p_message out varchar2 ) ;    
  PROCEDURE nc_misc_ri_reserve1_loc (p_pol_no in varchar2, p_pol_run in number, p_alc_re in varchar2, p_loss_date in date, p_recpt_seq in number, p_loc_seq in number,     
                                                          p_tot_sum_ins out number, p_sum_shr out number, w_recpt out number, w_loc out number, p_message out varchar2 ) ;    
  PROCEDURE nc_misc_ri_reserve2 (p_pol_no in varchar2, p_pol_run in number, p_alc_re in varchar2, p_loss_date in date, p_recpt_seq in number, p_loc_seq in number,     
                                                    p_tot_sum_ins out number, p_sum_shr out number, p_ext_seq out number, p_message out varchar2 ) ;    
  PROCEDURE nc_misc_ri_reserve3 (p_pol_no in varchar2, p_pol_run in number, p_alc_re in varchar2, p_loss_date in date, p_recpt_seq in number, p_loc_seq in number,     
                                                    p_tot_sum_ins out number, p_sum_shr out number, p_ext_seq out number, p_message out varchar2 ) ;    
  PROCEDURE nc_fire_fac_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_end_seq in varchar2, p_loc_seq in varchar2, p_loss_date in date, p_block in varchar2,     
                                                         p_ri_cursor out v_ref_cursor3, p_message out varchar2 ) ;    
  PROCEDURE nc_fire_all_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_end_seq in varchar2, p_loc_seq in varchar2, p_loss_date in date, p_block in varchar2,     
                                                        p_ri_cursor out v_ref_cursor7, p_message out varchar2 ) ;    
  PROCEDURE nc_fire_catas_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_end_seq in varchar2, p_loc_seq in varchar2, p_loss_date in date, p_block in varchar2,    
                                                            p_ri_cursor out v_ref_cursor8, p_message out varchar2 ) ;  
  PROCEDURE nc_iar_fac_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_prod_type in varchar2, p_alc_re in varchar2, p_recpt_seq in number,     
                                                       p_loc_seq in number, p_loss_date in date, p_ri_fac_cursor out v_ref_cursor5, p_message out varchar2 ) ;    
  PROCEDURE nc_iar_chk_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_prod_type in varchar2, p_alc_re in varchar2, p_recpt_seq in number,      
                                                       p_loc_seq in number, p_loss_date in date, p_chk_re out varchar2, p_message out varchar2 ) ;
  PROCEDURE nc_fire_trty_reinsurance (p_trty in number, p_balance in number, p_reserve_amt in number, p_tgr in number, p_ri_share out number, p_ri_reserve_amt out number);    
  PROCEDURE nc_hull_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_ret out number, p_ret1 out number, p_ret2 out number, p_ri_cursor out v_ref_cursor3, p_message out varchar2 );    
  PROCEDURE nc_mrn_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_pol_seq in number, p_sailing_date in varchar2,p_vessel_code in varchar2, p_I_E in varchar2, p_flight_no in varchar2,    
                                                    p_trc out number,p_ret out number,p_first out number,p_second out number,p_binder out number,p_reserve_fac out number,p_pret out number,    
                                                    p_sum_ins out number, p_sum_ins_ret2 out number, p_ri_cursor out v_ref_cursor3, p_message out varchar2 );    
                                                        
  PROCEDURE nc_misc_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_pol_yr in varchar2, p_prod_type in varchar2, p_loss_date in date, p_recpt_seq in number, p_loc_seq in number,    
                                                     p_alc_re in varchar2, p_end in number, p_ri_end in varchar2, p_tot_sum_ins out number, p_sum_shr out number, p_ri_cursor out  v_ref_cursor3, p_message out varchar2) ;    
  PROCEDURE nc_misc_reinsurance_initial (p_sts_key in number, p_ri_cursor out  v_ref_cursor6, p_message out varchar2) ;                         
  PROCEDURE nc_misc_reinsurance_ret (p_sts_key in number, p_99999 out  number, p_99998 out number, p_99993 out number) ;                                
  PROCEDURE nc_get_ri_reserved   (p_pol_no in varchar2,    
                                                    p_pol_run in number,    
                                                    p_pol_seq in number,    
                                                    p_end_seq in number,    
                                                    p_pol_yr  in varchar2,    
                                                    p_clm_yr  in  varchar2,    
                                                    p_prod_grp in varchar2,    
                                                    p_prod_type in varchar2,    
                                                    p_channel  in varchar2,    
                                                    p_cause_code in varchar2,    
                                                    p_cause_seq in varchar2,    
                                                    p_loss_date in date,    
                                                    p_sailing_date in varchar2,    
                                                    p_vessel_code in varchar2,    
                                                    p_I_E in varchar2,    
                                                    p_flight_no in varchar2,    
                                                    p_reserve_amt in number,    
                                                    p_sts_key in number,    
                                                    p_recpt_seq in number,    
                                                    p_loc_seq in number,    
                                                    p_block in varchar2,    
                                                    p_curr_rate in number,    
                                                    p_loss_date_flag  in varchar2,    
                                                    p_cause_flag in varchar2,    
                                                    p_re_cursor out v_ref_cursor4,    
                                                    p_alc_re out varchar2,    
                                                    p_message out varchar2,    
                                                    p_message2 out varchar2) ;                 
                                                

   FUNCTION GET_ABBNAME(v_userid IN VARCHAR2) RETURN VARCHAR2; -- ดึงรหัสตำแหน่ง
   
END NMTR_PACKAGE;
/

