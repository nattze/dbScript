CREATE OR REPLACE PACKAGE ALLCLM."WEB_CLM_PAHEALTH" IS    
    
  TYPE pahealth_cursor IS REF CURSOR;    
  type sys_refcursor is ref cursor;    
  
  FUNCTION get_policy_by_other(other_card  IN VARCHAR2, i_loss_date IN DATE) return varchar2 ;  
   
  Function  get_policy_by_id(id_card  IN VARCHAR2, i_loss_date IN DATE) return varchar2 ;   
   
 FUNCTION  get_count_policy_by_other (other_card  IN VARCHAR2, i_loss_date IN DATE )    
 RETURN NUMBER;   
                              
 FUNCTION  get_count_policy_by_id (id_card  IN VARCHAR2, i_loss_date IN DATE )     
 RETURN NUMBER;     
       
  PROCEDURE get_policy_by_id          
(     id_card  IN VARCHAR2,       
      i_loss_date IN DATE ,     
      o_cursor_pol  OUT sys_refcursor) ;    
        
  PROCEDURE get_policy_by_other   
 (other_card IN VARCHAR2,   
 i_loss_date IN DATE ,   
 o_cursor_pol OUT sys_refcursor) ;  
   
 PROCEDURE get_policy_other  
 (  
 in_policy_no IN varchar2,  
 in_fleet_seq IN Number,  
 in_recpt_seq IN Number,  
 in_id_no IN varchar2,  
 in_other_no IN varchar2,  
 in_loss_date IN varchar2, --5  
 out_name OUT varchar2,  
 out_fr_date OUT date,  
 out_to_date OUT date,  
 out_status OUT varchar2,  
 out_pd_grp OUT varchar2, --10  
 out_txt_remark OUT varchar2,  
 out_cursor OUT pahealth_cursor,   
 out_cursor_name OUT sys_refcursor,  
 out_cursor_policy OUT sys_refcursor,  
 x_result OUT varchar2 --15   
 );        
                  
  PROCEDURE get_policy_data --Procedure, is connected by WS, process all sub procedure.    
  (    
    in_policy_no          IN varchar2,    
    in_fleet_seq          IN Number,    
    in_recpt_seq          IN Number,    
    in_id_no              IN varchar2,    
    in_loss_date          IN varchar2, --5    
    out_name              OUT varchar2,    
    out_fr_date           OUT date,    
    out_to_date           OUT date,    
    out_status            OUT varchar2,    
    out_pd_grp            OUT varchar2, --10    
    out_txt_remark        OUT varchar2,    
    out_cursor            OUT pahealth_cursor,     
    out_cursor_name       OUT sys_refcursor,    
    out_cursor_policy     OUT sys_refcursor,    
    x_result              OUT varchar2 --15                             
  );    
  
 PROCEDURE get_policy_data --Procedure, is connected by WS, process all sub procedure.  
 (  
 in_policy_no IN varchar2,  
 in_fleet_seq IN Number,  
 in_recpt_seq IN Number,  
 in_id_no IN varchar2,  
 in_other_no IN varchar2,  
 in_loss_date IN varchar2, --5  
 out_name OUT varchar2,  
 out_fr_date OUT date,  
 out_to_date OUT date,  
 out_status OUT varchar2,  
 out_pd_grp OUT varchar2, --10  
 out_txt_remark OUT varchar2,  
 out_cursor OUT pahealth_cursor,   
 out_cursor_name OUT sys_refcursor,  
 out_cursor_policy OUT sys_refcursor,  
 x_result OUT varchar2 --15   
 );  
       
  PROCEDURE web_pahealth_details --Procedure, is connected by WS, process all sub procedure.    
  (    
    in_policy_no          IN varchar2,    
    in_fleet_seq          IN Number,    
    in_recpt_seq          IN Number,    
    in_id_no              IN varchar2,    
    in_loss_date          IN varchar2, --5    
    out_name              OUT varchar2,    
    out_fr_date           OUT date,    
    out_to_date           OUT date,    
    out_status            OUT varchar2,    
    out_pd_grp            OUT varchar2, --10    
    out_txt_remark        OUT varchar2,    
    out_cursor            OUT pahealth_cursor,     
    out_cursor_name       OUT sys_refcursor,    
    out_cursor_policy     OUT sys_refcursor,    
    x_result              OUT varchar2 --15                             
  );    
  
 PROCEDURE web_pahealth_details --Procedure, is connected by WS, process all sub procedure.  
 (  
 in_policy_no IN varchar2,  
 in_fleet_seq IN Number,  
 in_recpt_seq IN Number,  
 in_id_no IN varchar2,  
 in_other_no IN varchar2,  
 in_loss_date IN varchar2, --5  
 out_name OUT varchar2,  
 out_fr_date OUT date,  
 out_to_date OUT date,  
 out_status OUT varchar2,  
 out_pd_grp OUT varchar2, --10  
 out_txt_remark OUT varchar2,  
 out_cursor OUT pahealth_cursor,   
 out_cursor_name OUT sys_refcursor,  
 out_cursor_policy OUT sys_refcursor,  
 x_result OUT varchar2 --15   
 );  
       
  FUNCTION get_help1    
  RETURN VARCHAR2;    
      
  FUNCTION get_help1(in_type IN varchar2) RETURN VARCHAR2;    
      
  PROCEDURE get_status     
  (    
    in_type               IN varchar2,    
    in_hpt_code           IN varchar2,    
    out_cursor            OUT sys_refcursor    
  );    
      
  FUNCTION get_desease     
  (    
    in_dis_code               IN varchar2    
  )RETURN VARCHAR2;    
      
  PROCEDURE get_desease     
  (    
    in_dis_code               IN varchar2,    
    in_dis_text               IN varchar2,    
    out_cursor            OUT sys_refcursor    
  );    
      
  FUNCTION get_url_upload_file    
  (    
    in_type    IN varchar2,    
    in_sts_key IN NUMBER,    
    in_user_id IN varchar2    
  )RETURN VARCHAR2;    
      
  PROCEDURE insert_nc_master_tmp    
  (    
    in_out_sts_key      IN OUT number,    
    in_invoice      IN varchar2,    
    in_clm_type     IN varchar2,    
    in_policy_no    IN varchar2,    
    in_fleet_seq    IN number,    
    in_name         IN varchar2,    
    in_surname      IN varchar2,    
    in_hn           IN varchar2,    
    in_icd10        IN varchar2,    
    in_cause_code   IN varchar2,    
    in_risk_desc    IN varchar2,    
    in_loss_date    IN varchar2,    
    in_fr_loss_date IN varchar2,    
    in_to_loss_date IN varchar2,    
    in_hpt_code     IN varchar2,    
    in_day          IN number,    
    in_hpt_user     IN varchar2,    
    in_recpt_seq    IN number,    
    in_evn_desc     IN varchar2,    
    in_id_no        IN varchar2,    
    in_remark       IN varchar2,    
    in_sid          IN varchar2,    
    in_clm_no       IN varchar2,    
    in_grp_seq       IN varchar2,    
    x_result        OUT varchar2    
  );    
      
  PROCEDURE insert_nc_detail_tmp    
  (    
    in_sts_key          IN number,    
    in_premcode         IN varchar2,    
    in_request_amt      IN number,    
    in_remain_amt       IN number,    
    x_result            OUT varchar2    
  );    
      
  PROCEDURE search_sts_by_hpt    
  (    
    in_hn_no          IN varchar2,    
    in_name           IN varchar2,    
    in_inv_no         IN varchar2,    
    in_loss_Date_fr   IN varchar2,    
    in_loss_Date_to   IN varchar2,    
    in_status         IN varchar2,    
    in_user_id        IN varchar2,    
    out_cursor        OUT sys_refcursor,    
    x_result          OUT varchar2    
  );    
      
  PROCEDURE get_med_risk_std    
  (    
    out_cursor        OUT sys_refcursor    
  );    
      
  PROCEDURE get_med_risk_sub_std    
  (    
    in_med_risk_code  IN varchar2,    
    out_cursor        OUT sys_refcursor    
  );    
      
  PROCEDURE web_pahealth_coverage     
  (    
    in_policy_no          IN varchar2,    
    in_fleet_seq          IN Number,    
    in_recpt_seq          IN Number,    
    in_id_no              IN varchar2,    
    in_loss_date          IN varchar2, --5    
    out_cursor            OUT pahealth_cursor, --10    
    x_result              OUT varchar2                              
  );    
      
  PROCEDURE claim_coverage     
  (    
    in_policy_no      IN varchar2,    
    in_fleet_seq      IN Number,    
    in_recpt_seq      IN Number,    
    in_cursor         IN sys_refcursor,    
    out_cursor        OUT sys_refcursor                          
  );    
      
  PROCEDURE get_initQuery     
  (    
    out_cursor_sts            OUT sys_refcursor,    
    out_cursor_order_by       OUT sys_refcursor,    
    out_cursor_date_type      OUT sys_refcursor    
  );    
      
  FUNCTION get_hosp_id(in_user_id IN varchar2) RETURN VARCHAR2;    
      
  FUNCTION get_tot_rec_sts    
  (    
    in_hpt_code      IN varchar2,    
    in_sts_sub_type  IN varchar2    
  ) RETURN NUMBER;    
      
  FUNCTION get_sql4mc(in_cursor   IN sys_refcursor) RETURN VARCHAR2;    
      
  PROCEDURE web_pahealth_detail_for_broker    
  (    
    in_policy_no          IN varchar2,    
    in_fleet_seq          IN Number,    
    in_recpt_seq          IN Number,    
    in_id_no              IN varchar2,    
    in_name               IN varchar2, --5    
    in_loss_date          IN varchar2,    
    in_grp_seq            IN varchar2,    
    out_name              OUT varchar2,     
    out_fr_date           OUT date,    
    out_to_date           OUT date, --10    
    out_status            OUT varchar2,    
    out_pd_grp            OUT varchar2,    
    out_txt_remark        OUT varchar2,    
    out_cursor            OUT pahealth_cursor,     
    out_cursor_name       OUT sys_refcursor, --15    
    out_cursor_policy     OUT sys_refcursor,     
    out_cursor_unname     OUT sys_refcursor,    
    x_result              OUT varchar2                         
  );    
      
  PROCEDURE get_pahealth_details_for_broke    
  (    
    in_policy_no          IN varchar2,    
    in_fleet_seq          IN Number,    
    in_recpt_seq          IN Number,    
    in_id_no              IN varchar2,    
    in_loss_date          IN varchar2, --5    
    in_grp_seq            IN varchar2,    
    out_name              OUT varchar2,    
    out_fr_date           OUT date,    
    out_to_date           OUT date,    
    out_status            OUT varchar2, --10    
    out_pd_grp            OUT varchar2,    
    out_txt_remark        OUT varchar2,    
    out_cursor            OUT pahealth_cursor,     
    out_cursor_name       OUT sys_refcursor,    
    out_cursor_policy     OUT sys_refcursor, --15     
    out_cursor_unname     OUT sys_refcursor,    
    x_result              OUT varchar2                           
  );    
      
 
 PROCEDURE get_pahealth_details_for_broke 
 ( 
 in_policy_no IN varchar2, 
 in_fleet_seq IN Number, 
 in_recpt_seq IN Number, 
 in_id_no IN varchar2, 
 in_loss_date IN varchar2, --5 
 in_grp_seq IN varchar2, 
 in_name IN  varchar2, 
 out_name OUT varchar2, 
 out_fr_date OUT date, 
 out_to_date OUT date, 
 out_status OUT varchar2, --10 
 out_pd_grp OUT varchar2, 
 out_txt_remark OUT varchar2, 
 out_cursor OUT pahealth_cursor,  
 out_cursor_name OUT sys_refcursor, 
 out_cursor_policy OUT sys_refcursor, --15  
 out_cursor_unname OUT sys_refcursor, 
 x_result OUT varchar2  
 ); 
  
  PROCEDURE get_list_customer    
  (    
    in_pol_no         IN varchar2,    
    in_pol_run        IN Number,    
    in_name           IN varchar2,    
    in_loss_date      IN varchar2,    
    out_count         OUT Number,    
    out_cursor        OUT sys_refcursor                          
  );    
      
  PROCEDURE get_initQuery_broker    
  (    
    out_cursor_sts            OUT sys_refcursor,    
    out_cursor_order_by       OUT sys_refcursor,    
    out_cursor_date_type      OUT sys_refcursor    
  );    
      
END web_clm_pahealth;
/

