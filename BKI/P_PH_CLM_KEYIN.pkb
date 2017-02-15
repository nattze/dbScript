CREATE OR REPLACE package body ALLCLM.P_PH_CLM_KEYIN is

       PROCEDURE GET_BENEFIT(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_type IN VARCHAR2 
       ,v_benecode IN VARCHAR2 ,O_Benefit Out sys_refcursor, o_ret out varchar2) is
       v_ret varchar2(100);
      begin
            
          v_ret := P_PH_CLM.GET_PH_BENEFIT(v_polno, v_polrun, v_plan, v_type, v_benecode, o_benefit); 
          o_ret:= v_ret;
      end GET_BENEFIT;

      PROCEDURE GET_Init_KEYIN(
             o_hospital out sys_refcursor,
             o_claim_type out sys_refcursor,
             o_lcd10      out sys_refcursor,
             o_bene_type out sys_refcursor,
             o_clm_sts   out sys_refcursor,
             o_admission out sys_refcursor,
             o_bill_list out sys_refcursor,
             o_user      out sys_refcursor
         ) is 
        o_retType nvarchar2(10);
       begin
         
      o_retType := P_PH_CLM.GET_LIST_CLMTYPE(o_claim_type);
      o_retType := P_PH_CLM.GET_LIST_HOSPITAL('',o_hospital);
      o_retType := P_PH_CLM.GET_LIST_ICD10('',o_lcd10);
      o_retType := P_PH_CLM.GET_LIST_BENETYPE(o_bene_type);
      o_retType := P_PH_CLM.GET_LIST_CLMSTS(o_clm_sts);
      o_retType := P_PH_CLM.GET_LIST_ADMISSION(o_admission);
      o_retType := P_PH_CLM.GET_LIST_BILLSTD('',o_bill_list);
      o_retType := P_PH_CLM.GET_USER_LIST ('',o_user);

       end GET_Init_KEYIN;
       
      procedure gen_paph_benefit_detail(
       in_clm_no in varchar2,
       in_user_id in varchar2,
       out_cursor out sys_refcursor
   ) is
   x_ben_code nvarchar2(30);
   x_trn_seq int;
   x_sts_date date;
   x_amd_date date;
   x_user nvarchar2(20);
   x_cnt int;
   x_seq int;
   begin
     
   
   select  max(trn_seq)+1 into x_trn_seq from nc_reserved a where
   a.clm_no = in_clm_no;

   
   begin
         select a.sts_date,a.clm_user into x_sts_date,x_user from nc_reserved a where a.clm_no = in_clm_no  and 
         a.trn_seq= (select min(aa.trn_seq) from nc_reserved aa where aa.clm_no = a.clm_no)
         and rownum = 1;
         
   EXCEPTION   
    WHEN OTHERS THEN   
         x_sts_date := current_date; 
         x_user := in_user_id;
    end; 
 
 

   x_amd_date := current_date;
   
   

   if( x_trn_seq is null) then
       x_trn_seq := 1;
   end if;
           x_seq:=0;
           
            insert into nc_reserved(
                                            sts_key, 
                                            clm_no, 
                                            prod_grp, 
                                            prod_type, 
                                            type, 
                                            sub_type, 
                                            trn_seq, 
                                            sts_date, 
                                            amd_date, 
                                            prem_code, 
                                            prem_seq, 
                                            res_amt, 
                                            disc_amt, 
                                            deduct_amt, 
                                            trn_amt, 
                                            clm_user, 
                                            amd_user
                                        )
                            
                                      select 
                                          t.sts_key,
                                          t.clm_no,
                                          t.prod_grp,
                                          t.prod_type,
                                          t.type,
                                          t.sub_type,
                                          x_trn_seq,
                                          x_sts_date,
                                          current_date,
                                          t.benc,
                                          rownum,
                                          sumnet,
                                          0,
                                          0,
                                          0,
                                          x_user,
                                          in_user_id
                                          from (
                                     select
                                                            a.sts_key,
                                                            a.clm_no,
                                                            a.prod_grp,
                                                            a.prod_type,
                                                            'NCNATTYPECLM101' type,
                                                            'NCNATSUBTYPECLM101' sub_type,         
                                                           nvl( p_ph_clm.mapp_benecode(a.bill_code,
                                                            b.pol_no,
                                                            b.pol_run,
                                                            b.plan),
                                                            nvl((select bb.remark4  from clm_constant bb where bb.key=b.admission_type),'002')) benc,
                                                               sum(a.net_amt) sumnet
                                        from nc_billing a,nc_mas b 
                                       where a.clm_no = b.clm_no and  a.clm_no=in_clm_no and
                                        a.trn_seq =(select max(aa.trn_seq) from nc_billing aa where aa.clm_no = a.clm_no)
                                        group by a.clm_no,a.sts_key, a.prod_grp,a.prod_type,a.bill_no,   b.pol_no,b.pol_run,b.plan,b.admission_type,p_ph_clm.mapp_benecode(a.bill_code,
                                                        b.pol_no,
                                                        b.pol_run,
                                                        b.plan)
                                                   ) t where t.benc is not null;
     
    open out_cursor for
         select * from nc_reserved a where
         a.clm_no = in_clm_no and a.trn_seq = x_trn_seq;
         
   end gen_paph_benefit_detail;
       
      PROCEDURE GET_revise_KEYIN(
             in_clm_no in varchar2,
             o_clm_data out sys_refcursor,
             o_pol_data out sys_refcursor,
             o_list_billing out sys_refcursor,
             o_list_benefit out sys_refcursor,
             o_master_benefit out sys_refcursor,
             o_list_ri out sys_refcursor
          ) is
         x_pol_no varchar2(20);
         x_pol_run varchar2(20);
         x_plan varchar2(20);
         x_fleet varchar2(10);
         o_retType nvarchar2(1000);
         begin
           
         select a.pol_no , a.pol_run,a.plan, a.fleet_seq
         into
         x_pol_no, x_pol_run, x_plan,x_fleet
          from nc_mas a where a.clm_no = in_clm_no;  
         
         dbms_output.put_line(x_pol_no||'-'||x_pol_run||'-'||x_plan);
         
           open o_clm_data for
                select 
                sts_key, 
                clm_no, 
                reg_no, 
                pol_no, 
                pol_run, 
                end_no, 
                end_seq, 
                recpt_seq, 
                loc_seq, 
                clm_yr, 
                pol_yr, 
                prod_grp, 
                prod_type, 
                fleet_seq, 
                run_fleet_seq, 
                sub_seq, 
                fam_sts, 
                patronize, 
                fam_seq, 
                id_no, 
                plan, 
                ipd_flag, 
                dis_code, 
                P_PH_CLM.GET_ICD10_DESCR(dis_code,'T') DIS_CODE_DESCR,
                cause_code, 
                cause_seq, 
                trunc(reg_date) reg_date, 
                trunc(clm_date) clm_date, 
                trunc(loss_date) loss_date, 
                loss_time,  
                trunc(fr_date) fr_date,  
                trunc(to_date) to_date,  
                trunc(tr_date_fr) tr_date_fr,  
                trunc(tr_date_to) tr_date_to,  
                trunc(close_date) close_date, 
                trunc(reopen_date) reopen_date, 
                add_tr_day, 
                tot_tr_day, 
                alc_re, 
                loss_detail, 
                clm_user, 
                invoice_no, 
                hn_no, 
                hpt_code, 
                P_PH_CLM.GET_HOSPITAL_NAME(hpt_code) HPT_DESC,
                hpt_seq, 
                mas_cus_code, 
                mas_cus_seq, 
                mas_cus_name, 
                cus_code, 
                cus_seq, 
                cus_name, 
                fax_clm, 
                trunc(fax_clm_date) fax_clm_date, 
                death_claim, 
                mas_sum_ins, 
                recpt_sum_ins, 
                loc_sum_ins, 
                clm_sts, 
                remark, 
                clm_place, 
                clm_place_amp, 
                clm_place_jw, 
                catas_code, 
                pi_club, 
                carr_agent, 
                consign, 
                nat_clm_flag, 
                arrv_date, 
                del_date, 
                time_bar, 
                surv_date, 
                surv_code, 
                channel, 
                fir_source, 
                block, 
                pol_seq, 
                t_e, 
                damg_descr, 
                fire_source, 
                sub_cause_code, 
                part, 
                paid_remark, 
                bki_shr, 
                curr_code, 
                curr_rate, 
                grp_seq, 
                oic_run_no, 
                amlo_run_no, 
                bki_clm_staff, 
                your_clm_no, 
                end_run, 
                passport_id, 
                amph_code, 
                jw_code, 
                recov_user, 
                complete_date, 
                rec_agent, 
                cwp_remark, 
                cwp_code, 
                recpt_end_seq, 
                card_id_type, 
                card_id_no, 
                card_other_type, 
                card_other_no, 
                card_updatedate, 
                oic_prod_type, 
                oic_flag_pol, 
                claim_number, 
                claim_run, 
                admission_type, 
                clm_type, 
                P_PH_CLM.GET_CLMTYPE_DESCR(clm_type) CLM_TYPE_DESC,
                icd10_2, 
                P_PH_CLM.GET_ICD10_DESCR(icd10_2,'T') ICD10_2_DESCR,
                icd10_3, 
                P_PH_CLM.GET_ICD10_DESCR(icd10_3,'T') ICD10_3_DESCR,
                icd10_4,
                P_PH_CLM.GET_ICD10_DESCR(icd10_4,'T') ICD10_4_DESCR,
                a.add_tr_day,
                a.claim_status,
                a.other_hpt
                  from nc_mas a where a.clm_no = in_clm_no;  
         
           open o_pol_data for
                  SELECT a.pol_no||a.pol_run policy_no ,fleet_seq ,id_no ,title ,name ,dob ,age ,sex ,decode(a.cancel ,null ,'Ok','Cancel') Status, plan, 'N/A' package, decode(a.cancel, null, a.fr_date, null) fr_date, decode(a.cancel, null, a.to_date, null) to_date, decode(a.cancel, 'C', a.fr_date, null) cancel_fr_date, decode(a.cancel, 'C', a.to_date, null) cancel_to_date, b.pol_no, b.pol_run, a.recpt_seq, b.end_seq, b.pol_yr, b.cus_code, b.cus_seq, b.cus_enq, b.alc_re 
                 ,a.fam_seq, a.fam_sts,a.patronize,b.cus_code,b.cus_seq,a.title||a.name cus_name, b.prod_grp, b.prod_type, b.channel, a.sub_seq
                 ,b.cus_code mas_cus_code, b.cus_enq mas_cus_name, b.cus_seq mas_cus_seq
                 FROM pa_medical_det a , mis_mas b
                WHERE a.pol_no = b.pol_no and a.pol_run = b.pol_run and a.end_seq = b.end_seq 
                 and a.pol_no = x_pol_no and a.pol_run = x_pol_run and fleet_seq =x_fleet;
                
            open o_list_billing for
                 select 
                 sts_key, 
                  clm_no, 
                  prod_grp, 
                  prod_type, 
                  bill_no, 
                  bill_code, 
                  bill_seq, 
                  trn_seq, 
                  bill_amt, 
                  disc_amt, 
                  net_amt, 
                  status,
                  '('||bill_code||')'||(select descr_th from nc_billing_std aa where aa.code = a.Bill_Code) DESCR
                  from nc_billing a
                 where a.clm_no = in_clm_no and a.trn_seq = (select max(aa.trn_seq) from nc_billing aa where aa.clm_no = a.clm_no);
                 
            open o_list_benefit for
                 select 
                 sts_key, 
                  clm_no, 
                  prod_grp, 
                  prod_type, 
                  type, 
                  sub_type, 
                  trn_seq, 
                  sts_date, 
                  amd_date, 
                  prem_code, 
                  prem_seq, 
                  res_amt, 
                  disc_amt, 
                  deduct_amt, 
                  trn_amt, 
                  clm_user, 
                  amd_user, 
                  req_amt, 
                  close_date, 
                  offset_flag, 
                  status, 
                  tot_res_amt,
                 p_ph_clm.get_bene_descr(a.prem_code ,'T') PREM_CODE_DESCR
                  from nc_reserved a
             where a.clm_no = in_clm_no and a.trn_seq = (select max(aa.trn_seq) from nc_reserved aa where aa.clm_no = a.clm_no);
     
         
         
              -- o_retType := P_PH_CLM.GET_PH_BENEFIT(x_pol_no,x_pol_run,x_plan,'','',o_master_benefit);
          o_retType := P_PH_CLM.GET_PH_BENEFIT_4search(x_pol_no,x_pol_run,x_plan,'','',o_master_benefit);
         --      dbms_output.put_line(o_retType);
         
         open o_list_ri for
         select
         sts_key, 
          clm_no, 
          prod_grp, 
          prod_type, 
          type, 
          ri_code, 
          ri_br_code, 
          ri_type, 
          ri_lf_flag, 
          ri_sub_type, 
          ri_share, 
          trn_seq, 
          ri_sts_date, 
          ri_amd_date, 
          ri_res_amt, 
          ri_trn_amt, 
          lett_no, 
          lett_type, 
          cashcall, 
          status, 
          lett_prt, 
          sub_type, 
          print_type, 
          print_user, 
          print_date, 
          cancel, 
          org_ri_res_amt,
          nc_health_package.RI_NAME(a.ri_code,a.ri_br_code) REINSURER
         from nc_ri_reserved a where
         a.clm_no = in_clm_no and a.trn_seq = (select max(aa.trn_seq) from nc_ri_reserved aa where aa.clm_no = a.clm_no);
         
         
         
         end GET_revise_KEYIN;

      procedure calRI(
           in_clm_no in varchar2,
           out_cursor out sys_refcursor
       ) is
       x_pol_no nvarchar2(20);
       x_pol_run nvarchar2(10);
       x_loc_seq nvarchar2(10);
       x_recpt_seq nvarchar2(10);
       x_loss_date date;
       x_end_seq nvarchar2(10);
       x_ret float;
       --POL_NO,POL_RUN,RI_CODE,RI_BR_CODE,RI_TYPE,LF_FLAG,RI_SUB_TYPE,RI_SUM_SHR
       v_pol_no nvarchar2(10);
       v_pol_run nvarchar2(10);
       v_ri_code nvarchar2(10);
       v_ri_br_code nvarchar2(10);
       v_ri_type nvarchar2(10);
       v_lf_flag nvarchar2(10);
       v_ri_sub_type nvarchar2(10);
       v_ri_sum_shr nvarchar2(10);
       v_name nvarchar2(100);
       begin 
       
       
       select a.pol_no,a.pol_run,nvl(a.loc_seq,0) loc_seq, nvl(a.end_seq,0) end_seq,trunc(a.loss_date),nvl(a.recpt_seq,0) recpt_seq
       into
       x_pol_no,x_pol_run,x_loc_seq,x_end_seq,x_loss_date,x_recpt_seq
       from nc_mas a where a.clm_no = in_clm_no;
       
       dbms_output.put_line(x_pol_no||'-'||x_pol_run||'-'||x_loc_seq||'-'||x_end_seq||'-'||x_loss_date||'-'||x_recpt_seq);
       
         x_ret := nc_health_package.get_ri_res(x_pol_no,
                                        x_pol_run,
                                        x_recpt_seq,
                                        x_loc_seq,
                                        x_loss_date,
                                        x_end_seq,
                                        out_cursor);

                           
       end calRI;

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
         )
       is
       begin
       GET_revise_KEYIN(
             in_clm_no,
             o_clm_data,
             o_pol_data,
             o_list_billing,
             o_list_benefit,
             o_master_benefit,
             o_list_ri
          );
       
       
          open o_list_payment for
          SELECT sts_key, clm_no, prod_grp, prod_type, subsysid, type, sub_type, pay_no, 
          clm_seq, trn_seq, curr_code, curr_rate, clm_men, amd_user, days, recov_amt, pay_amt, 
          prem_code, p_ph_clm.GET_BENE_DESCR(prem_code, 'T') prem_descr, prem_seq 
          , (select res_amt from nc_reserved nr where nr.clm_no = a.clm_no and nr.trn_seq in (select max(bb.trn_seq) from nc_reserved bb where bb.clm_no = nr.clm_no) and nr.prem_code = a.prem_code ) res_amt
          from nc_payment a  where a.clm_no = in_clm_no
          and a.trn_seq = (select max(aa.trn_seq) from nc_payment aa where aa.clm_no = a.clm_no and aa.pay_no = a.pay_no);
          
          open o_list_ri_payment for
          SELECT  sts_key ,clm_no ,pay_no ,trn_seq  ,prod_grp ,prod_type ,ri_code ,ri_br_code 
          ,ri_type , ri_lf_flag,ri_sub_type ,sub_type ,type,ri_share , ri_pay_amt ,ri_trn_amt  
          , lett_no, lett_type, status ,cashcall ,cancel,print_type ,print_user ,print_date 
          ,ri_code||ri_br_code||'-'||ri_lf_flag||'-'||ri_type||ri_sub_type RI_DISPLAY 
          ,nc_health_package.RI_NAME(ri_code ,ri_br_code) RI_NAME
          from nc_ri_paid a  where a.clm_no = in_clm_no
          and a.trn_seq = (select max(aa.trn_seq) from nc_ri_paid aa where aa.clm_no = a.clm_no and aa.pay_no = a.pay_no);
                   
           
          open o_list_payee for
           select * from nc_payee a  where a.clm_no = in_clm_no
          and a.trn_seq = (select max(aa.trn_seq) from nc_payee aa where aa.clm_no = a.clm_no and aa.pay_no = a.pay_no);
              
          
       
       end get_enquiry_claim_detail;

         
end P_PH_CLM_KEYIN;
/

