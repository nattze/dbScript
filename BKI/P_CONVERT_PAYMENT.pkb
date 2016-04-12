CREATE OR REPLACE PACKAGE BODY ALLCLM."P_CONVERT_PAYMENT" IS  
/******************************************************************************                
 NAME: NMTR_PAPERLESS                
 PURPOSE: Get Authurized NonMotorClaim User for Approve payment                
                
 REVISIONS:                
 Ver Date Author Description                
 --------- ---------- --------------- ------------------------------------                
 1.0 13/10/2014 Pornpen 1. Created this package.                
******************************************************************************/                
                
PROCEDURE conv_insert_fire_table (v_clm_no in varchar2,v_pay_no in varchar2,v_prod_type varchar2, v_err_message out varchar2) IS  
 v_res_amt number := 0;  
 v_rec_amt number := 0;  
 v_tot_res_amt number := 0;  
 v_tot_paid number := 0;  
 v_clm_seq number := 0;  
 v_rec_seq number := 0;  
 v_sal_seq number := 0;  
 v_clm_sts varchar2(1) := null;  
 v_rec_sts varchar2(1) := null;  
 v_fir_code varchar2(4) := null;  
 v_state_no varchar2(16) := null;  
 v_rec_no varchar2(16) := null;  
 v_sal_no varchar2(16) := null;  
 v_rec_state_no varchar2(16) := null;  
 v_sal_state_no varchar2(16) := null;  
 v_pol_te varchar2(1);  
 v_pol_br varchar2(3);  
 v_loc1 varchar2(50);  
 v_loc2 varchar2(50);  
 v_loc3 varchar2(50);  
 v_loc_am varchar2(2);  
 v_loc_jw varchar2(2);  
 v_class1 varchar2(1);  
 v_class2 varchar2(1);  
 v_risk_exp varchar2(4);  
 v_ext_exp varchar2(4);  
 v_pol_type varchar2(2);  
 v_cus_te varchar2(1);  
 v_co_type varchar2(1);  
 v_leader varchar2(1);  
 v_contact varchar2(30);  
 v_your_pol_no varchar2(30);  
 v_your_end_no varchar2(30);  
 v_ben_code varchar2(4);  
 v_ben_descr varchar2(100);  
 v_type varchar2(2);  
 v_out_type varchar2(2);  
 v_co_shr number(6,3) := 0;  
 v_tot_sum_bld number(14,2) := 0;  
 v_our_sum_bld number(14,2) := 0;  
 v_tot_sum_mac number(14,2) := 0;  
 v_our_sum_mac number(14,2) := 0;  
 v_tot_sum_stk number(14,2) := 0;  
 v_our_sum_stk number(14,2) := 0;  
 v_tot_sum_fur number(14,2) := 0;  
 v_our_sum_fur number(14,2) := 0;  
 v_tot_sum_oth number(14,2) := 0;  
 v_our_sum_oth number(14,2) := 0;  
 v_sum_rec_clm number(14,2) := 0;  
 v_tot_rec_clm number(14,2) := 0;  
 v_sum_rec number(14,2) := 0;  
 v_tot_rec number(14,2) := 0;  
 v_sum_sal number(14,2) := 0;  
 v_tot_sal number(14,2) := 0;  
 v_sum_ded number(14,2) := 0;  
 v_tot_ded number(14,2) := 0;  
 v_sum_bld number(14,2) := 0;  
 v_tot_bld number(14,2) := 0;  
 v_sum_mac number(14,2) := 0;  
 v_tot_mac number(14,2) := 0;  
 v_sum_stk number(14,2) := 0;  
 v_tot_stk number(14,2) := 0;  
 v_sum_fur number(14,2) := 0;  
 v_tot_fur number(14,2) := 0;  
 v_sum_oth number(14,2) := 0;  
 v_tot_oth number(14,2) := 0;  
 v_sum_sur number(14,2) := 0;  
 v_tot_sur number(14,2) := 0;  
 v_sum_set number(14,2) := 0;  
 v_tot_set number(14,2) := 0;  
 v_clm_date date := null;  
 v_rec_date date := null;  
 v_sal_date date := null;  
 v_trn_seq nc_payment.trn_seq%type; 
 v_pay_type varchar2(2); 
 v_type1 varchar2(2); 
 v_pay_sts nc_payment.pay_sts%type; 
 v_curr_code1 nc_payment.curr_code%type; 
 v_curr_rate1 nc_payment.curr_rate%type; 
 v_clm_men nc_payment.clm_men%type; 
 v_amd_user nc_payment.amd_user%type; 
 v_pay_amt nc_payment.pay_amt%type; 
 v_sts_date nc_payment.sts_date%type; 
 v_amd_date nc_payment.amd_date%type; 
 v_settle_date nc_payment.settle_date%type; 
 v_tot_paid_mas  number(13,2); 
 v_part varchar2(2000); 
 v_remark varchar2(2000); 
 v_result_Ms varchar2(20); 
 v_salvage char(1); 
 v_deduct char(1); 
 v_recovery char(1); 
 cnt_x1  number:=0; 
  v_rst  VARCHAR2(500) ; 
  v_pol_no varchar2(13); 
  v_pol_run number; 
  v_pol_cat varchar2(1); 
  v_clm_sts1 varchar2(20); 
  v_offset1   varchar2(2); 
  v_offset2   varchar2(2); 
  v_brname    varchar2(200); 
  v_prod_grp varchar2(5); 
Begin  
 v_err_message := null;  
 BEGIN 
        select count(*) into cnt_x1 
        from nc_payee c 
        where  c.clm_no = v_clm_no and c.pay_no = v_pay_no ; 
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN 
            cnt_x1 := 0 ; 
        WHEN OTHERS THEN 
            cnt_x1 := 0; 
    END;  
   IF cnt_x1 = 0 THEN 
        v_err_message := 'not convert!!  wait for NC_Payee Data '; 
        nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: count nc_payee ' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' || '|| v_err_message ,'not found' ,v_rst) ; 
        return ;      
    END IF; 
 Begin  
 FOR NC_PAYMENT IN  
 (  
     SELECT A.CLM_NO,A.PAY_NO,A.CLM_SEQ,A.TRN_SEQ,A.PAY_STS,A.PAY_AMT,A.TRN_AMT,A.CURR_CODE, 
     A.CURR_RATE,A.STS_DATE,A.AMD_DATE,A.SETTLE_DATE,A.CLM_MEN,A.AMD_USER,A.APPROVE_ID, 
     A.APPROVE_DATE,A.PROD_GRP,A.PROD_TYPE,A.SUBSYSID,A.STS_KEY,A.PRINT_TYPE,A.TYPE,SUB_TYPE, 
     A.APPRV_FLAG,A.BATCH_NO,A.PREM_CODE,A.PREM_SEQ,A.OFFSET_FLAG,A.STATUS,A.TOT_PAY_AMT  
     FROM NC_PAYMENT A  
     WHERE A.CLM_NO = v_clm_no  
     AND A.PAY_NO = v_pay_no  
     AND A.TRN_SEQ IN (SELECT MAX(B.TRN_SEQ)FROM NC_PAYMENT B WHERE B.CLM_NO = A.CLM_NO AND B.PAY_NO = A.PAY_NO)  
     )  
 loop  
     P_CONVERT_PAYMENT.GET_SALVAGE_DEDUCT_RECOV_FLAG(v_clm_no,v_pay_no,v_salvage,v_deduct,v_recovery);  
  
     v_clm_men := nc_payment.CLM_MEN; 
     v_amd_user := nc_payment.AMD_USER;  
     v_pay_amt := nc_payment.PAY_AMT;  
     v_pay_sts := nc_payment.pay_sts; 
     v_curr_code1 :=nc_payment.curr_code; 
     v_curr_rate1 :=nc_payment.curr_rate; 
     v_sts_date:= nc_payment.sts_date; 
     v_amd_date := nc_payment.amd_date; 
     v_settle_date := nc_payment.settle_date; 
     v_clm_seq := nc_payment.trn_seq; 
     v_prod_grp := nc_payment.prod_grp; 
  
        if      nc_payment.type in ('NCNATTYPECLM001','NCNATTYPECLM002')  then       
                      v_type := '01';       
              elsif  nc_payment.type in ('NCNATTYPEREC001','NCNATTYPEREC002') then       
                      if      nc_payment.sub_type in ('NCNATSUBTYPEREC001') then       
                              if   nc_payment.offset_flag = 'Y'  then       
                                   v_type := '01';       
                                   v_out_type := '09';       
                                   v_sum_rec_clm := v_sum_rec_clm + nvl(nc_payment.pay_amt,0);       
                                   v_tot_rec_clm := v_tot_rec_clm + nvl(nc_payment.tot_pay_amt,0);       
                              else       
                                   v_type := '02';       
                                   v_out_type := '11';       
                                   v_sum_rec := v_sum_rec + nvl(nc_payment.pay_amt,0);       
                                   v_tot_rec := v_tot_rec + nvl(nc_payment.tot_pay_amt,0);       
                              end if;  
                      elsif  nc_payment.sub_type in ('NCNATSUBTYPEREC002') then       
                              v_type := '02';       
                              v_out_type := '39';       
                              v_sum_rec := v_sum_rec + nvl(nc_payment.pay_amt,0);       
                              v_tot_rec := v_tot_rec + nvl(nc_payment.tot_pay_amt,0);        
                      elsif  nc_payment.sub_type in ('NCNATSUBTYPESAL003') then       
                              if    nc_payment.offset_flag = 'Y'   then       
                                    v_type := '01';       
                                    v_out_type := '07';       
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_payment.pay_amt,0);       
                                    v_tot_rec_clm := v_tot_rec_clm + nvl(nc_payment.tot_pay_amt,0);       
                              else       
                                    v_type := '03';       
                                    v_out_type := '10';       
                                    v_sum_sal := v_sum_sal + nvl(nc_payment.pay_amt,0);       
                                    v_tot_sal := v_tot_sal + nvl(nc_payment.tot_pay_amt,0);       
                              end if;       
                      elsif  nc_payment.sub_type in ('NCNATSUBTYPESAL001') then       
                              v_type := '03';       
                              v_out_type := '10';       
                              v_sum_sal := v_sum_sal + nvl(nc_payment.pay_amt,0);       
                              v_tot_sal := v_tot_sal + nvl(nc_payment.tot_pay_amt,0);    
                      elsif  nc_payment.sub_type in ('NCNATSUBTYPESAL002') then           
                              v_type := '01';       
                              v_out_type := '40';       
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_payment.pay_amt,0);       
                              v_tot_rec_clm := v_tot_rec_clm + nvl(nc_payment.tot_pay_amt,0);           
                      elsif  nc_payment.sub_type in ('NCNATSUBTYPEDED001') then           
                              v_type := '04';       
                              v_out_type := '16';       
                              v_sum_ded := v_sum_ded + nvl(nc_payment.pay_amt,0);       
                              v_tot_ded := v_tot_ded + nvl(nc_payment.tot_pay_amt,0);       
                       elsif  nc_payment.sub_type in ('NCNATSUBTYPEDED002') then       
                              v_type := '01';       
                              v_out_type := '15';       
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_payment.pay_amt,0);       
                              v_tot_rec_clm := v_tot_rec_clm + nvl(nc_payment.tot_pay_amt,0);      
                      else       
                              v_type := '01';       
                      end if;       
              end if;       
              if     nc_payment.type in ('NCNATTYPECLM001')  then       
                     if      nc_payment.prem_code in ('1010') then       
                             v_out_type := '01';       
                             v_sum_bld := v_sum_bld + nvl(nc_payment.pay_amt,0);       
                             v_tot_bld   := v_tot_bld + nvl(nc_payment.tot_pay_amt,0);       
                     elsif  nc_payment.prem_code in  ('1560') then       
                             v_out_type := '02';       
                             v_sum_mac := v_sum_mac + nvl(nc_payment.pay_amt,0);       
                             v_tot_mac := v_tot_mac + nvl(nc_payment.tot_pay_amt,0);       
                     elsif  nc_payment.prem_code in  ('1050') then       
                             v_out_type := '03';       
                             v_sum_stk := v_sum_stk + nvl(nc_payment.pay_amt,0);       
                             v_tot_stk := v_tot_stk + nvl(nc_payment.tot_pay_amt,0);       
                     elsif  nc_payment.prem_code in  ('1020')  then       
                             v_out_type := '04';       
                             v_sum_fur := v_sum_fur + nvl(nc_payment.pay_amt,0);       
                             v_tot_fur := v_tot_fur + nvl(nc_payment.tot_pay_amt,0);       
                     elsif  nc_payment.prem_code in  ('1030')  then       
                             v_out_type := '38';       
                             v_sum_fur := v_sum_fur + nvl(nc_payment.pay_amt,0);       
                             v_tot_fur := v_tot_fur + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('1040')  then       
                             v_out_type := '17';       
                             v_sum_fur := v_sum_fur + nvl(nc_payment.pay_amt,0);       
                             v_tot_fur := v_tot_fur + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('1060')  then       
                             v_out_type := '18';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('1070')  then       
                             v_out_type := '19';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('1090')  then       
                             v_out_type := '20';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('2001')  then       
                             v_out_type := '21';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('2002')  then       
                             v_out_type := '22';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('3010')  then       
                             v_out_type := '23';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('3040')  then       
                             v_out_type := '24';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('5010')  then       
                             v_out_type := '25';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('5020')  then       
                             v_out_type := '26';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('5030')  then       
                             v_out_type := '27';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('5040')  then       
                             v_out_type := '28';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('6050')  then       
                             v_out_type := '29';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     elsif  nc_payment.prem_code in  ('A099')  then       
                             v_out_type := '05';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);  
                     else       
                             v_out_type := '05';       
                             v_sum_oth := v_sum_oth + nvl(nc_payment.pay_amt,0);       
                             v_tot_oth := v_tot_oth + nvl(nc_payment.tot_pay_amt,0);       
                     end if;       
              elsif nc_payment.type in ('NCNATTYPECLM002')  then       
                     if     nc_payment.sub_type in ('NCNATSUBTYPECLM010')   then       
                            v_out_type := '06';       
                            v_sum_sur := v_sum_sur + nvl(nc_payment.pay_amt,0);       
                            v_tot_sur := v_tot_sur + nvl(nc_payment.tot_pay_amt,0);       
                     elsif  nc_payment.sub_type in ('NCNATSUBTYPECLM011')   then       
                            v_out_type := '30';       
                            v_sum_sur := v_sum_sur + nvl(nc_payment.pay_amt,0);       
                            v_tot_sur := v_tot_sur + nvl(nc_payment.tot_pay_amt,0);       
                     elsif nc_payment.sub_type in ('NCNATSUBTYPECLM012')   then       
                            v_out_type := '31';       
                            v_sum_sur := v_sum_sur + nvl(nc_payment.pay_amt,0);       
                            v_tot_sur := v_tot_sur + nvl(nc_payment.tot_pay_amt,0);       
                     elsif nc_payment.sub_type in ('NCNATSUBTYPECLM013')   then       
                            v_out_type := '32';       
                            v_sum_sur := v_sum_set + nvl(nc_payment.pay_amt,0);       
                            v_tot_sur := v_tot_set + nvl(nc_payment.tot_pay_amt,0);       
                     elsif nc_payment.sub_type in ('NCNATSUBTYPECLM014')   then       
                            v_out_type := '12';       
                            v_sum_sur := v_sum_set + nvl(nc_payment.pay_amt,0);       
                            v_tot_sur := v_tot_set + nvl(nc_payment.tot_pay_amt,0);     
                     elsif nc_payment.sub_type in ('NCNATSUBTYPECLM015')   then       
                            v_out_type := '33';       
                            v_sum_sur := v_sum_set + nvl(nc_payment.pay_amt,0);       
                            v_tot_sur := v_tot_set + nvl(nc_payment.tot_pay_amt,0);     
                     elsif nc_payment.sub_type in ('NCNATSUBTYPECLM016')   then       
                            v_out_type := '34';       
                            v_sum_sur := v_sum_set + nvl(nc_payment.pay_amt,0);       
                            v_tot_sur := v_tot_set + nvl(nc_payment.tot_pay_amt,0);     
                     elsif nc_payment.sub_type in ('NCNATSUBTYPECLM017')   then       
                            v_out_type := '35';       
                            v_sum_sur := v_sum_set + nvl(nc_payment.pay_amt,0);       
                            v_tot_sur := v_tot_set + nvl(nc_payment.tot_pay_amt,0);    
                     elsif nc_payment.sub_type in ('NCNATSUBTYPECLM018')   then       
                            v_out_type := '36';       
                            v_sum_sur := v_sum_set + nvl(nc_payment.pay_amt,0);       
                            v_tot_sur := v_tot_set + nvl(nc_payment.tot_pay_amt,0);      
                     elsif nc_payment.sub_type in ('NCNATSUBTYPECLM019')   then       
                            v_out_type := '37';       
                            v_sum_sur := v_sum_set + nvl(nc_payment.pay_amt,0);       
                            v_tot_sur := v_tot_set + nvl(nc_payment.tot_pay_amt,0);     
                     else       
                            v_out_type := '08';       
                            v_sum_set := v_sum_set + nvl(nc_payment.pay_amt,0);       
                            v_tot_set := v_tot_set + nvl(nc_payment.tot_pay_amt,0);       
                     end if;       
              end if;    
 if v_type = '01' then  
     Begin   
     insert into fir_clm_paid (clm_no,pay_type,state_no,state_seq,type,pay_date,pay_sign,pay_amt)  
     values (v_clm_no,v_out_type,v_pay_no,nvl(v_clm_seq,1),v_type,null,'BHT',nvl(v_pay_amt,0));  
     exception  
     when OTHERS then  
     v_err_message := 'fir_clm_paid';  
     rollback;  
     End;  
     commit;  
 end if;  
 End loop;  
 commit;  
 End;  
  
 Begin 
 FOR NC_PAYMENT_INFO IN 
 ( 
 SELECT A.CLM_NO, A.PAY_NO, A.TYPE, A.PROD_GRP, A.PROD_TYPE, A.TRN_SEQ, A.STS_DATE,A.AMD_DATE,  
 A.PART, A.REMARK, A.INVOICE_NO, A.REF_NO, A.CLM_USER, A.AMD_USER, A.STS_KEY 
 FROM NC_PAYMENT_INFO A 
 WHERE A.CLM_NO = v_clm_no 
 AND A.PAY_NO = v_pay_no 
 AND A.TRN_SEQ IN (SELECT MAX(B.TRN_SEQ)  
 FROM NC_PAYMENT_INFO B 
 WHERE B.CLM_NO = v_clm_no 
 AND B.PAY_NO =v_pay_no) 
 ) 
 Loop 
 v_part := P_CONVERT_PAYMENT.FIX_LINEFEED(substr( NC_PAYMENT_INFO.PART,1,10000)) ; 
 v_remark :=P_CONVERT_PAYMENT.FIX_LINEFEED(substr(  NC_PAYMENT_INFO.REMARK,1,10000));  
 End Loop; 
 End; 
if v_type ='01' then 
 Begin  
 insert into fir_paid_stat(CLM_NO, STATE_NO, STATE_SEQ, TYPE, STATE_DATE, CORR_DATE, BUILD_TOT_LOSS,BUILD_OUR_LOSS,  
 MACH_TOT_LOSS, MACH_OUR_LOSS, STOCK_TOT_LOSS, STOCK_OUR_LOSS, FURN_TOT_LOSS, FURN_OUR_LOSS,  
 OTHER_TOT_LOSS, OTHER_OUR_LOSS, SUR_TOT_LOSS, SUR_OUR_LOSS, REC_TOT_LOSS, REC_OUR_LOSS, SET_TOT_LOSS, SET_OUR_LOSS, 
 TOT_TOT_LOSS, TOT_OUR_LOSS,  DESCR_PAID, TYPE_FLAG, REMARK, VAT_AMT, PRINT_TYPE, BATCH_NO, REPRINT_NO, PAY_DATE,STATE_FLAG )  
 values(v_clm_no,v_pay_no,nvl(v_clm_seq,1),v_type,trunc(sysdate),null,v_tot_bld,v_sum_bld, 
 v_tot_mac,v_sum_mac,v_tot_stk,v_sum_stk,v_tot_fur,v_sum_fur, 
 v_tot_oth,v_sum_oth,v_tot_sur,v_sum_sur,v_tot_rec_clm,v_sum_rec_clm,v_tot_set,v_sum_set, 
 nvl(v_tot_bld,0)+nvl(v_tot_mac,0)+nvl(v_tot_stk,0)+nvl(v_tot_fur,0)+nvl(v_tot_oth,0)+nvl(v_tot_sur,0)+nvl(v_tot_set,0)-nvl(v_tot_rec_clm,0),  
 nvl(v_sum_bld,0)+nvl(v_sum_mac,0)+nvl(v_sum_stk,0)+nvl(v_sum_fur,0)+nvl(v_sum_oth,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0),  
 v_part,null,v_remark,0,null,null,null,v_sts_date,null);  
 commit; 
  v_tot_paid_mas := (nvl(v_sum_bld,0)+nvl(v_sum_mac,0)+nvl(v_sum_stk,0)+nvl(v_sum_fur,0)+nvl(v_sum_oth,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0)); 
  v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,v_prod_type,v_prod_grp,v_type,v_tot_paid_mas,0,0,0);  
 exception  
 when OTHERS then  
 v_err_message := 'fir_paid_stat';  
 rollback;  
 commit;  
 End;  
 end if; 
  
 if nvl(v_sum_rec,0) > 0 then  
  
 Begin  
 insert into fir_clm_paid (clm_no,pay_type,state_no,state_seq,type,pay_date,pay_sign,pay_for_amt,pay_rte,pay_amt)  
 values (v_clm_no,v_out_type,v_pay_no,v_clm_seq,v_type,null,'BHT',nvl(v_sum_rec,0),1,nvl(v_sum_rec,0));  
  
 insert into fir_paid_stat (clm_no,state_no,state_seq,type,state_date,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss,DESCR_PAID,REMARK)  
 values (v_clm_no,v_pay_no,v_clm_seq,v_type,null,trunc(sysdate),nvl(v_tot_rec,0),nvl(v_sum_rec,0),nvl(v_tot_rec,0),nvl(v_sum_rec,0),v_part,v_remark);  
 commit;  
   v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,v_prod_type,v_prod_grp,v_type,0,0,0,nvl(v_sum_rec,0)); 
 exception  
 when OTHERS then  
 v_err_message := 'fir_clm_paid';  
 rollback;  
 end; 
 end if;  
 if nvl(v_sum_sal,0) > 0 then  
     Begin  
     insert into fir_clm_paid (clm_no,pay_type,state_no,state_seq,type,pay_date,pay_sign,pay_for_amt,pay_rte,pay_amt)  
     values (v_clm_no,v_out_type,v_pay_no,v_clm_seq,v_type,null,'BHT',nvl(v_sum_sal,0),1,nvl(v_sum_sal,0));  
      
     insert into fir_paid_stat (clm_no,state_no,state_seq,type,state_date,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss,DESCR_PAID,REMARK)    
                 values (v_clm_no,v_pay_no,v_clm_seq,v_type,null,trunc(sysdate),nvl(v_tot_sal,0),nvl(v_sum_sal,0),nvl(v_tot_sal,0),nvl(v_sum_sal,0),v_part,v_remark);    
                 commit;    
             exception    
                when  OTHERS  then    
                          v_err_message := 'fir_clm_paid';    
                          rollback;   
     End;  
  v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,v_prod_type,v_prod_grp,v_type,0,nvl(v_sum_sal,0),0,0);   
end if;    
     
 if   nvl(v_sum_ded,0) > 0  then    
         Begin    
             insert into fir_clm_paid (clm_no,pay_type,state_no,state_seq,type,pay_date,pay_sign,pay_for_amt,pay_rte,pay_amt)    
             values (v_clm_no,v_out_type,v_pay_no,v_clm_seq,v_type,null,'BHT',nvl(v_sum_ded,0),1,nvl(v_sum_ded,0));    
    
             insert into fir_paid_stat (clm_no,state_no,state_seq,type,state_date,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss,DESCR_PAID,REMARK)    
             values (v_clm_no,v_pay_no,1,v_type,null,trunc(sysdate),nvl(v_tot_ded,0),nvl(v_sum_ded,0),nvl(v_tot_ded,0),nvl(v_sum_ded,0),v_part,v_remark);    
             commit;    
         exception    
            when  OTHERS  then    
                      v_err_message := 'fir_clm_paid';    
                      rollback;   
         End;    
           v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,v_prod_type,v_prod_grp,v_type,0,0,nvl(v_sum_ded,0),0);   
 end if;    
 
    Begin    
        For nc_ri_paid in    
        (    
            select a.clm_no,a.pay_no,a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.ri_pay_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type    
            from nc_ri_paid a    
            where a.clm_no = v_clm_no   
            and a.pay_no = v_pay_no  
              and  a.type like 'NCNATTYPECLM%'    
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)    
                                                        from nc_ri_paid b    
                                                        where b.clm_no = a.clm_no    
                                                        and b.pay_no = a.pay_no  
                                                        and  b.type like 'NCNATTYPECLM%'    
                                                        group by b.clm_no,b.pay_no)    
         ) loop    
             Begin    
                 insert into fir_ri_paid (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_lf_flag,ri_type,ri_sub_type,ri_share,ri_pay_amt,lett_no,lett_prt,cash_call)    
                 values (nc_ri_paid.clm_no,nc_ri_paid.pay_no,nvl(v_clm_seq,1),'01',nc_ri_paid.ri_code,nc_ri_paid.ri_br_code,nc_ri_paid.ri_lf_flag,nc_ri_paid.ri_type,nc_ri_paid.ri_sub_type,nc_ri_paid.ri_share,nc_ri_paid.ri_pay_amt,    
                            nc_ri_paid.lett_no,decode(nc_ri_paid.lett_no,null,'N','Y'),nc_ri_paid.cashcall);    
              exception    
                 when  OTHERS  then    
                           v_err_message := 'fir_ri_paid';    
                           rollback;         
              End;    
         End loop;    
         commit;    
    End;    
    Begin    
        For nc_ri_paid1 in    
        (    
            select a.clm_no,a.pay_no,a.trn_seq,a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.ri_pay_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type    
            from nc_ri_paid a    
            where a.clm_no = v_clm_no  
              and a.pay_no = v_pay_no   
              and a.type like 'NCNATTYPEREC%'     
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)    
                                                          from nc_ri_paid b    
                                                        where b.clm_no = a.clm_no 
                                                           and b.pay_no = a.pay_no    
                                                           and  b.type like 'NCNATTYPEREC%'      
                                                     group by b.clm_no,b.pay_no)    
         ) loop    
             Begin    
                     insert into fir_ri_paid (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_lf_flag,ri_type,ri_sub_type,ri_share,ri_pay_amt,lett_no,lett_prt,cash_call)    
                     values (nc_ri_paid1.clm_no,nc_ri_paid1.pay_no,nc_ri_paid1.trn_seq,v_type,nc_ri_paid1.ri_code,nc_ri_paid1.ri_br_code,nc_ri_paid1.ri_lf_flag,nc_ri_paid1.ri_type,nc_ri_paid1.ri_sub_type,nc_ri_paid1.ri_share,nc_ri_paid1.ri_pay_amt,    
                                nc_ri_paid1.lett_no,decode(nc_ri_paid1.lett_no,null,'N','Y'),nc_ri_paid1.cashcall);    
              exception    
                 when  OTHERS  then    
                           v_err_message := 'fir_ri_paid';    
                           rollback;   
              End;    
         End loop;    
         commit;    
    End;    
     
    Begin 
    FOR NC_PAYEE IN 
    ( 
        SELECT A.CLM_NO, A.PAY_NO, A.PROD_GRP, A.PROD_TYPE, A.TRN_SEQ, A.STS_DATE,A.AMD_DATE, A.PAYEE_CODE,  
        substr(ltrim(rtrim(A.PAYEE_NAME)),1,200)PAYEE_NAME, A.PAYEE_TYPE, A.PAYEE_SEQ, A.PAYEE_AMT,P_CONVERT_PAYMENT.CONVERT_PAYMENT_METHOD(A.SETTLE)SETTLE, A.ACC_NO, A.ACC_NAME, A.BANK_CODE,  
        A.BANK_BR_CODE,substr(ltrim(rtrim(A.BR_NAME)),1,45)BR_NAME, A.SEND_TITLE, A.SEND_ADDR1, A.SEND_ADDR2, A.PAID_STS, A.SALVAGE_FLAG,  
        A.DEDUCT_FLAG, A.SMS, A.EMAIL, A.TYPE,A.SALVAGE_AMT,A.DEDUCT_AMT,A.SENT_TYPE 
        FROM NC_PAYEE A 
        WHERE A.CLM_NO = v_clm_no 
        AND A.PAY_NO = v_pay_no 
        AND A.TRN_SEQ IN (SELECT MAX(B.TRN_SEQ) FROM NC_PAYEE B  
                                                WHERE B.CLM_NO = v_clm_no 
                                                AND B.PAY_NO = v_pay_no) 
    ) 
    Loop 
     v_offset2 := null; 
     v_offset1 := null; 
        IF NC_PAYEE.DEDUCT_FLAG = '1' THEN -- offset หัก 
            v_offset2 := 'P' ;     
        ELSIF NC_PAYEE.DEDUCT_FLAG = '2' THEN -- post นำส่ง 
            v_offset2 := 'M' ;     
        END IF; 
 
        IF NC_PAYEE.SALVAGE_FLAG = '1' THEN -- offset หัก 
            v_offset1 := 'P' ;     
        ELSIF NC_PAYEE.SALVAGE_FLAG = '2' THEN -- post นำส่ง 
            v_offset1 := 'M' ;     
        END IF; 
        Begin        
        select thai_brn_name into v_brname 
             from bank_branch 
             where bank_code =  NC_PAYEE.BANK_CODE  and branch_code = NC_PAYEE.BANK_BR_CODE ; 
        exception    
        when no_data_found then  
            v_brname := null; 
        when  OTHERS  then    
            v_brname := null; 
        End; 
    Begin 
       INSERT INTO FIR_CLM_PAYEE(CLM_NO, STATE_NO, STATE_SEQ, TYPE, PAY_DATE, 
       PAY_AMT, SETTLE, CHEQUE_NO, ACC_NO, ACC_NAME, BANK_CODE,BANK_BR_CODE, BR_NAME, OTHER,  
       ITEM_NO, PAYEE_CODE,PAY_AGT_STS,DESCR_BEN,SALVAGE_AMT,DEDUCT_AMT,PAYEE_OFFSET,PAYEE_OFFSET2, 
       SEND_TITLE,SEND_ADDR1,SEND_ADDR2,SENT ) 
       VALUES(NC_PAYEE.CLM_NO,NC_PAYEE.PAY_NO,NC_PAYEE.TRN_SEQ,v_type,TRUNC(NC_PAYEE.STS_DATE), 
       NC_PAYEE.PAYEE_AMT,NC_PAYEE.SETTLE,NULL,NC_PAYEE.ACC_NO,NC_PAYEE.ACC_NAME,NC_PAYEE.BANK_CODE,NC_PAYEE.BANK_BR_CODE,v_brname,v_remark, 
       NC_PAYEE.PAYEE_SEQ,NC_PAYEE.PAYEE_CODE,NULL,NC_PAYEE.PAYEE_NAME,NC_PAYEE.SALVAGE_AMT,NC_PAYEE. DEDUCT_AMT,v_offset1,v_offset2, 
       NC_PAYEE.SEND_TITLE,NC_PAYEE.SEND_ADDR1,NC_PAYEE.SEND_ADDR2,NC_PAYEE.SENT_TYPE); 
       exception    
       when  OTHERS  then    
                 v_err_message := 'FIR_CLM_PAYEE';    
                 rollback;  
    End; 
    End Loop;  
      
     begin 
          select   pol_no,pol_run,pol_cat,pol_type   into  v_pol_no,v_pol_run,v_pol_cat,v_pol_type 
          from fir_clm_mas 
          where clm_no =v_clm_no; 
          exception when others then  
           v_pol_no :=null; 
           v_pol_run := null; 
           v_pol_cat := null; 
           v_pol_type := null; 
      end; 
      begin 
          insert  into fir_correct_clm( tran_date,clm_no,pol_no,pol_run,state_no,state_seq,pol_cat,type,status,amt,pol_type,prod_type) 
          values(sysdate,v_clm_no,v_pol_no,v_pol_run,v_pay_no,'1',v_pol_cat,v_type,'1',0,v_pol_type,v_prod_type); 
          exception when others then 
           v_err_message := 'FIR_CORRECT_CLM';  
          rollback;  
      end; 
      begin 
       select clm_sts into v_clm_sts1  from nc_mas where clm_no=v_clm_no; 
       exception when others then v_clm_sts1 := null; 
       end; 
      IF  v_clm_sts1 ='NCCLMSTS02' Then 
           BEGIN 
             update fir_clm_mas  
             set clm_sts='4',close_date=trunc(sysdate), 
               DEDUCT_REC_FLAG = v_deduct, 
               SALVAGE_REC_FLAG = v_salvage, 
               RECOVERY_REC_FLAG = v_recovery 
             where clm_no=v_clm_no; 
             exception when others then 
               v_err_message := 'fir_clm_mas';  
            rollback;  
           END; 
        
      BEGIN 
           INSERT INTO FIR_OUT_STAT A (A.TYPE, A.TOT_TOT_SUM, A.TOT_TOT_LOSS, A.TOT_OUR_SUM, A.TOT_OUR_LOSS, A.SUR_TOT_LOSS, A.SUR_OUR_LOSS, 
             A.STOCK_TOT_SUM, A.STOCK_TOT_LOSS, A.STOCK_OUR_SUM, A.STOCK_OUR_LOSS, A.STATE_STS,A.STATE_SEQ, A.STATE_NO, 
             A.STATE_DATE, A.SET_TOT_LOSS, A.SET_OUR_LOSS, A.REOPEN_DATE, A.REOPEN_CODE, A.REC_TOT_LOSS, A.REC_OUR_LOSS,  
             A.OTHER_TOT_SUM, A.OTHER_TOT_LOSS, A.OTHER_OUR_SUM, A.OTHER_OUR_LOSS, A.MACH_TOT_SUM, A.MACH_TOT_LOSS, 
             A.MACH_OUR_SUM, A.MACH_OUR_LOSS, A.FURN_TOT_SUM, A.FURN_TOT_LOSS, A.FURN_OUR_SUM, A.FURN_OUR_LOSS,A.DESCR_CLOSE,  
             A.CORR_DATE, A.CLOSE_DATE, A.CLOSE_CODE, A.CLM_NO, A.BUILD_TOT_SUM, A.BUILD_TOT_LOSS, A.BUILD_OUR_SUM, A.BUILD_OUR_LOSS)   
             SELECT  A.TYPE, A.TOT_TOT_SUM, A.TOT_TOT_LOSS, A.TOT_OUR_SUM, A.TOT_OUR_LOSS, A.SUR_TOT_LOSS, A.SUR_OUR_LOSS, 
             A.STOCK_TOT_SUM, A.STOCK_TOT_LOSS, A.STOCK_OUR_SUM, A.STOCK_OUR_LOSS, A.STATE_STS,A.STATE_SEQ+1, A.STATE_NO, 
             A.STATE_DATE, A.SET_TOT_LOSS, A.SET_OUR_LOSS, A.REOPEN_DATE, A.REOPEN_CODE, A.REC_TOT_LOSS, A.REC_OUR_LOSS,  
             A.OTHER_TOT_SUM, A.OTHER_TOT_LOSS, A.OTHER_OUR_SUM, A.OTHER_OUR_LOSS, A.MACH_TOT_SUM, A.MACH_TOT_LOSS, 
             A.MACH_OUR_SUM, A.MACH_OUR_LOSS, A.FURN_TOT_SUM, A.FURN_TOT_LOSS, A.FURN_OUR_SUM, A.FURN_OUR_LOSS,A.DESCR_CLOSE,  
             A.CORR_DATE, TRUNC(SYSDATE), ('10'), A.CLM_NO, A.BUILD_TOT_SUM, A.BUILD_TOT_LOSS, A.BUILD_OUR_SUM, A.BUILD_OUR_LOSS 
             FROM FIR_OUT_STAT A 
             WHERE A.CLM_NO =v_clm_no 
              AND A.STATE_NO =v_pay_no 
              AND A.STATE_SEQ  IN (SELECT MAX(B.STATE_SEQ) FROM FIR_OUT_STAT B  
                                                     WHERE B.CLM_NO= A.CLM_NO 
                                                     AND B.STATE_NO = A.STATE_NO); 
              exception when others then 
               v_err_message := 'FIR_OUT_STAT';  
              rollback;  
      END; 
      End if; 
      commit;  
    End; 
End conv_insert_fire_table;    
 
PROCEDURE conv_insert_mrn_table(v_clm_no in varchar2,v_pay_no in varchar2,v_prod_type varchar2, v_err_message out varchar2) IS 
      v_res_amt             number;      
      v_state_no            varchar2(16);    
      v_rec_state_no        varchar2(16);    
      v_sal_state_no        varchar2(16);    
      v_ded_state_no        varchar2(16);    
      v_pol_te              varchar2(1);    
      v_pol_br              varchar2(3);    
      v_agent_code          varchar2(5);    
      v_agent_seq           varchar2(2);    
      v_vessel_code         varchar2(7);    
      v_vessel_seq          number;    
      v_vessel_enq          varchar2(35);    
      v_sailing_date        varchar2(10);    
      v_pack_code           varchar2(3);    
      v_surv_agent          varchar2(6);    
      v_sett_agent          varchar2(6);    
      v_curr_code           varchar2(3);    
      v_curr_rate           number(8,5);    
      v_fr_port             varchar2(4);    
      v_to_port             varchar2(4);    
      v_i_e                 varchar2(1);    
      v_int_code            varchar2(5);    
      v_flight_no           varchar2(7);    
      v_cond_code           varchar2(4);    
      v_fgn_sum_ins         number(12);    
      v_sum_ded             number(14,2) := 0;    
      v_sum_pa              number(14,2) := 0;    
      v_sum_exp             number(14,2) := 0;    
      v_pol_type            varchar2(2);    
      v_cus_te              varchar2(1);    
      v_co_type             varchar2(1);    
      v_leader              varchar2(1);    
      v_your_pol_no         varchar2(30);    
      v_your_end_no         varchar2(30);    
      v_ben_code            varchar2(4);    
      v_ben_descr           varchar2(100);    
      v_type                varchar2(2);    
      v_out_type            varchar2(2);    
      v_co_shr              number(6,3) := 0;    
      v_sum_rec_clm         number(14,2) := 0;    
      v_tot_rec_clm         number(14,2) := 0;    
      v_sum_rec             number(14,2) := 0;    
      v_tot_rec             number(14,2) := 0;    
      v_sum_sal             number(14,2) := 0;    
      v_tot_sal             number(14,2) := 0;    
      v_sum_sur             number(14,2) := 0;    
      v_tot_sur             number(14,2) := 0;    
      v_sum_set             number(14,2) := 0;    
      v_tot_set             number(14,2) := 0;    
      v_flag                boolean; 
      v_type1               varchar2(2); 
      v_trn_seq             nc_payment.trn_seq%type; 
      v_pay_type            varchar2(2); 
      v_pay_sts             nc_payment.pay_sts%type; 
      v_curr_code1          nc_payment.curr_code%type; 
      v_curr_rate1          nc_payment.curr_rate%type; 
      v_clm_men             nc_payment.clm_men%type; 
      v_amd_user            nc_payment.amd_user%type; 
      v_pay_amt             nc_payment.pay_amt%type; 
      v_sts_date            nc_payment.sts_date%type; 
      v_amd_date            nc_payment.amd_date%type; 
      v_settle_date         nc_payment.settle_date%type; 
      v_part                nc_payment_info.part%type; 
      v_remark            nc_payment_info.remark%type; 
      v_result_MS           varchar2(20); 
      v_salvage                  char(1); 
      v_deduct                   char(1); 
      v_recovery                char(1); 
      cnt_x1  number:=0; 
      v_rst  VARCHAR2(500) ; 
      v_offset1   varchar2(2); 
      v_offset2   varchar2(2); 
      v_brname    varchar2(200); 
      v_prod_grp  varchar2(5); 
      v_tot_paid_mas  number(13,2); 
      v_clm_sts1 varchar2(20); 
Begin    
    v_err_message := null;   
    BEGIN 
        select count(*) into cnt_x1 
        from nc_payee c 
        where  c.clm_no = v_clm_no and c.pay_no = v_pay_no ; 
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN 
            cnt_x1 := 0 ; 
        WHEN OTHERS THEN 
            cnt_x1 := 0; 
    END;  
    begin 
       select clm_sts into v_clm_sts1  from nc_mas where clm_no=v_clm_no; 
       exception when others then v_clm_sts1 := null; 
     end; 
 
      IF cnt_x1 = 0 THEN 
        v_err_message := 'not convert!!  wait for NC_Payee Data '; 
        nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: count nc_payee ' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' || '|| v_err_message ,'not found' ,v_rst) ; 
        return ;      
    END IF;  
    Begin    
        FOR NC_PAYMENT IN   
        (    
        SELECT  A.CLM_NO,A.PAY_NO,A.CLM_SEQ,A.TRN_SEQ,A.PAY_STS,A.PAY_AMT,A.TRN_AMT,A.CURR_CODE, 
                A.CURR_RATE,A.STS_DATE,A.AMD_DATE,A.SETTLE_DATE,A.CLM_MEN,A.AMD_USER,A.APPROVE_ID, 
                A.APPROVE_DATE,A.PROD_GRP,A.PROD_TYPE,A.SUBSYSID,A.STS_KEY,A.PRINT_TYPE,A.TYPE,SUB_TYPE, 
                A.APPRV_FLAG,A.BATCH_NO,A.PREM_CODE,A.PREM_SEQ,A.OFFSET_FLAG,A.STATUS,A.TOT_PAY_AMT         
        FROM NC_PAYMENT A    
        WHERE A.CLM_NO = v_clm_no  
        AND A.PAY_NO = v_pay_no  
        AND A.TRN_SEQ IN (SELECT MAX(B.TRN_SEQ)FROM NC_PAYMENT B WHERE B.CLM_NO = A.CLM_NO AND B.PAY_NO = A.PAY_NO) 
        )  
        loop  
        GET_SALVAGE_DEDUCT_RECOV_FLAG(v_clm_no,v_pay_no,v_salvage,v_deduct,v_recovery);  
          
        v_curr_code1 := nc_payment.CURR_CODE; 
        v_curr_rate1 := nc_payment.CURR_RATE; 
        v_clm_men := nc_payment.CLM_MEN; 
        v_amd_user := nc_payment.AMD_USER;   
        v_pay_amt := nc_payment.PAY_AMT;  
        v_trn_seq := NC_PAYMENT.TRN_SEQ; 
        v_sts_date := NC_PAYMENT.STS_DATE; 
        v_prod_grp  := NC_PAYMENT.PROD_GRP; 
    
         ----------------------------------------------------------   Type ---------------------------------------------- 
           if      rtrim(NC_PAYMENT.type) in ('NCNATTYPECLM001','NCNATTYPECLM002')  then         
                      v_type := '01';         
           elsif  rtrim(NC_PAYMENT.type) in ('NCNATTYPEREC001','NCNATTYPEREC002') then         
                      if      rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPEREC001') then         
                              if   NC_PAYMENT.offset_flag = 'Y'  then         
                                   v_type := '01';         
                                   v_pay_type := '07';         
                                   v_sum_rec_clm := v_sum_rec_clm + nvl(NC_PAYMENT.pay_amt,0);         
                              else         
                                   v_type := '02';         
                                   v_pay_type := '15';         
                                   v_sum_rec := v_sum_rec + nvl(NC_PAYMENT.pay_amt,0);         
                              end if;    
                      elsif   rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPEREC002') then    
                                   v_type := '02';         
                                   v_pay_type := '24';         
                                   v_sum_rec := v_sum_rec + nvl(NC_PAYMENT.pay_amt,0);     
                      elsif  rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPESAL001') then         
                              if    NC_PAYMENT.offset_flag = 'Y'   then         
                                    v_type := '01';         
                                    v_pay_type := '06';         
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(NC_PAYMENT.pay_amt,0);         
                              else         
                                    v_type := '03';         
                                    v_pay_type := '16';         
                                    v_sum_sal := v_sum_sal + nvl(NC_PAYMENT.pay_amt,0);         
                              end if;         
                      elsif  rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPEDED001') then         
                              if    NC_PAYMENT.offset_flag = 'Y'   then         
                                    v_type := '01';         
                                    v_pay_type := '05';         
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(NC_PAYMENT.pay_amt,0);         
                              else         
                                    v_type := '04';         
                                    v_pay_type := '17';         
                                    v_sum_ded := v_sum_ded + nvl(NC_PAYMENT.pay_amt,0);         
                              end if;     
                      elsif  rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPESAL003') then         
                              v_type := '01';         
                              v_pay_type := '06';         
                              v_sum_rec_clm := v_sum_rec_clm + nvl(NC_PAYMENT.pay_amt,0);                                   
                      elsif  rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPEDED002') then         
                              v_type := '01';         
                              v_pay_type := '05';         
                              v_sum_rec_clm := v_sum_rec_clm + nvl(NC_PAYMENT.pay_amt,0);                                
                      else         
                              v_type := '01';         
                      end if;         
              end if;         
              if     rtrim(NC_PAYMENT.type) in ('NCNATTYPECLM001')  then         
                     v_pay_type := '01';         
                     v_sum_pa := v_sum_pa + nvl(NC_PAYMENT.pay_amt,0);         
              elsif rtrim(NC_PAYMENT.type) in ('NCNATTYPECLM002')  then         
                     if     rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPECLM010')   then         
                            v_pay_type := '30';         
                            v_sum_sur := v_sum_sur + nvl(NC_PAYMENT.pay_amt,0);       
                     elsif rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPECLM011')   then         
                            v_pay_type := '03';         
                            v_sum_sur := v_sum_sur + nvl(NC_PAYMENT.pay_amt,0);    
                     elsif rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPECLM012')   then         
                            v_pay_type := '04';         
                            v_sum_sur := v_sum_sur + nvl(NC_PAYMENT.pay_amt,0);   
                     elsif rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPECLM013')   then         
                            v_pay_type := '08';         
                            v_sum_set := v_sum_set + nvl(NC_PAYMENT.pay_amt,0);         
                     elsif rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPECLM015')   then         
                            v_pay_type := '09';         
                            v_sum_exp := v_sum_exp + nvl(NC_PAYMENT.pay_amt,0);         
                     elsif rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPECLM017')   then         
                            v_pay_type := '10';         
                            v_sum_exp := v_sum_exp + nvl(NC_PAYMENT.pay_amt,0);         
                     elsif rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPECLM018')   then         
                            v_pay_type := '12';         
                            v_sum_exp := v_sum_exp + nvl(NC_PAYMENT.pay_amt,0);         
                     elsif rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPECLM019')   then         
                            v_pay_type := '13';         
                            v_sum_exp := v_sum_exp + nvl(NC_PAYMENT.pay_amt,0);    
                     elsif rtrim(NC_PAYMENT.sub_type) in ('NCNATSUBTYPECLM020')   then         
                            v_pay_type := '14';         
                            v_sum_exp := v_sum_exp + nvl(NC_PAYMENT.pay_amt,0);          
                     end if;         
              end if;         
         ---------------------------------------------------------- The End ---------------------------------------------- 
      IF v_pay_type  not   in  ('01')   then   
        Begin 
            INSERT INTO MRN_CLM_PAID(CLM_NO,PAY_TYPE,STATE_NO,STATE_SEQ,TYPE,PAY_DATE,PAY_AGT, 
            PAY_SIGN,PAY_FOR_AMT,PAY_RTE,PAY_AMT,PAY_AGT_STS,PAY_RECP_STS,PAY_VAT_AMT,OFFSET_FLAG,CLM_SEQ) 
            VALUES(NC_PAYMENT.CLM_NO,V_PAY_TYPE,NC_PAYMENT.PAY_NO,NC_PAYMENT.TRN_SEQ,V_TYPE,NULL,NULL, 
            NC_PAYMENT.CURR_CODE,0,NC_PAYMENT.CURR_RATE,NC_PAYMENT.PAY_AMT,NULL,0,0,NULL,0); 
        exception    
        when  OTHERS  then    
                 v_err_message := 'MRN_CLM_PAID';    
                 rollback; 
        End;  
        commit; 
      END IF; 
   End loop;    
   IF v_type  in  ('01')   then   
       Begin    
            INSERT INTO MRN_PAID_STAT(CLM_NO,STATE_NO,STATE_SEQ,TYPE,STATE_DATE,PA_AMT, 
            SUR_AMT,SET_AMT,REC_AMT,EXP_AMT,TOT_AMT,DESCR_PAID,BEN_AMT,TYP_FLAG, 
            CORR_DATE) 
            values(V_CLM_NO,V_PAY_NO,v_trn_seq,V_TYPE,null,nvl(v_sum_pa,0),nvl(v_sum_sur,0),nvl(v_sum_set,0),nvl(v_sum_rec_clm,0),nvl(v_sum_exp,0),    
            nvl(v_sum_pa,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0)+nvl(v_sum_exp,0),v_part,'0',null,trunc(sysdate));   
            exception    
            when  OTHERS  then    
                v_err_message := 'MRN_PAID_STAT';    
            rollback;   
       End;  
       if  v_clm_sts1 ='NCCLMSTS02' Then 
        v_tot_paid_mas  :=  nvl(v_sum_pa,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0)+nvl(v_sum_exp,0); 
        v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,V_PROD_TYPE,V_PROD_GRP, v_type,v_tot_paid_mas,0,0,0);  
       end if; 
       commit;  
   END IF; 
   End;  
        if    nvl(v_sum_pa,0) > 0   then    
              Begin 
                   INSERT INTO MRN_CLM_PAID(CLM_NO,PAY_TYPE,STATE_NO,STATE_SEQ,TYPE,PAY_DATE,PAY_AGT, 
                   PAY_SIGN,PAY_FOR_AMT,PAY_RTE,PAY_AMT,PAY_AGT_STS,PAY_RECP_STS,PAY_VAT_AMT,OFFSET_FLAG,CLM_SEQ) 
                    VALUES(V_CLM_NO,'01',V_PAY_NO,V_TRN_SEQ,V_TYPE,null,null, 
                    v_curr_code1,0,v_curr_rate1,nvl(v_sum_pa,0),NULL,0,0,NULL,0);  
          
              exception    
              when  OTHERS  then    
                         v_err_message := 'MRN_CLM_PAID';    
                         rollback;   
              End;     
              commit;  
              Begin    
                    INSERT INTO MRN_PAID_STAT(CLM_NO,STATE_NO,STATE_SEQ,TYPE,STATE_DATE,PA_AMT, 
                    SUR_AMT,SET_AMT,REC_AMT,EXP_AMT,TOT_AMT,DESCR_PAID,BEN_AMT,TYP_FLAG, 
                    CORR_DATE) 
                    values(V_CLM_NO,V_PAY_NO,V_TRN_SEQ,V_TYPE,null,nvl(v_sum_pa,0),nvl(v_sum_sur,0),nvl(v_sum_set,0),nvl(v_sum_rec_clm,0),nvl(v_sum_exp,0),    
                    nvl(v_sum_pa,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0)+nvl(v_sum_exp,0),v_part,'0',null,trunc(sysdate));   
                    exception    
                    when  OTHERS  then    
                        v_err_message := 'MRN_PAID_STAT';    
                    rollback;   
               End; 
          if  v_clm_sts1 ='NCCLMSTS02' Then       
              v_tot_paid_mas := nvl(v_sum_pa,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0)+nvl(v_sum_exp,0); 
              v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,V_PROD_TYPE,V_PROD_GRP, v_type,v_tot_paid_mas,0,0,0);  
          end if; 
        commit; 
        end if;  
             
        if    nvl(v_sum_sur,0) > 0   then    
              Begin 
                    INSERT INTO MRN_CLM_PAID(CLM_NO,PAY_TYPE,STATE_NO,STATE_SEQ,TYPE,PAY_DATE,PAY_AGT, 
                    PAY_SIGN,PAY_FOR_AMT,PAY_RTE,PAY_AMT,PAY_AGT_STS,PAY_RECP_STS,PAY_VAT_AMT,OFFSET_FLAG,CLM_SEQ) 
                    VALUES(V_CLM_NO,'04',V_PAY_NO,V_TRN_SEQ,V_TYPE,null,null, 
                    V_CURR_CODE1,0,V_CURR_RATE1,v_sum_sur,NULL,0,0,NULL,0); 
              exception    
              when  OTHERS  then    
                         v_err_message := 'MRN_CLM_PAID';    
                         rollback;    
              End;   
               
               Begin    
                INSERT INTO MRN_PAID_STAT(CLM_NO,STATE_NO,STATE_SEQ,TYPE,STATE_DATE,PA_AMT, 
                SUR_AMT,SET_AMT,REC_AMT,EXP_AMT,TOT_AMT,DESCR_PAID,BEN_AMT,TYP_FLAG, 
                CORR_DATE) 
                values(V_CLM_NO,V_PAY_NO,V_TRN_SEQ,V_TYPE,null,nvl(v_sum_pa,0),nvl(v_sum_sur,0),nvl(v_sum_set,0),nvl(v_sum_rec_clm,0),nvl(v_sum_exp,0),    
                nvl(v_sum_pa,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec,0)+nvl(v_sum_exp,0),v_part,'0',null,trunc(sysdate));   
                exception    
                when  OTHERS  then    
                    v_err_message := 'MRN_PAID_STAT';    
                rollback;  
               end;  
              if  v_clm_sts1 ='NCCLMSTS02' Then  
                v_tot_paid_mas := nvl(v_sum_pa,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0)+nvl(v_sum_exp,0); 
                v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,V_PROD_TYPE,V_PROD_GRP,v_type, v_tot_paid_mas,0,0,0);  
              end if; 
                commit; 
       end if; 
        if    nvl(v_sum_rec,0) > 0   then    
                  Begin 
                        INSERT INTO MRN_CLM_PAID(CLM_NO,PAY_TYPE,STATE_NO,STATE_SEQ,TYPE,PAY_DATE,PAY_AGT, 
                        PAY_SIGN,PAY_FOR_AMT,PAY_RTE,PAY_AMT,PAY_AGT_STS,PAY_RECP_STS,PAY_VAT_AMT,OFFSET_FLAG,CLM_SEQ) 
                        VALUES(V_CLM_NO,'15',V_PAY_NO,V_TRN_SEQ,V_TYPE,null,null, 
                        V_CURR_CODE1,0,V_CURR_RATE1,v_sum_sur,NULL,0,0,NULL,0); 
                  exception    
                  when  OTHERS  then    
                             v_err_message := 'MRN_CLM_PAID';    
                             rollback;    
                  End;   
                   
                   Begin    
                    INSERT INTO MRN_PAID_STAT(CLM_NO,STATE_NO,STATE_SEQ,TYPE,STATE_DATE,PA_AMT, 
                    SUR_AMT,SET_AMT,REC_AMT,EXP_AMT,TOT_AMT,DESCR_PAID,BEN_AMT,TYP_FLAG, 
                    CORR_DATE) 
                    values(V_CLM_NO,V_PAY_NO,V_TRN_SEQ,V_TYPE,null,nvl(v_sum_pa,0),nvl(v_sum_sur,0),nvl(v_sum_set,0),nvl(v_sum_rec,0),nvl(v_sum_exp,0),    
                   nvl(v_sum_rec,0)-nvl(v_sum_pa,0)-nvl(v_sum_exp,0)-nvl(v_sum_sur,0)-nvl(v_sum_set,0) ,v_part,'0',null,trunc(sysdate));   
                     
                    exception    
                    when  OTHERS  then    
                        v_err_message := 'MRN_PAID_STAT';    
                    rollback;  
                   end;  
                  if  v_clm_sts1 ='NCCLMSTS02' Then 
                   v_tot_paid_mas :=nvl(v_sum_rec,0)-nvl(v_sum_pa,0)-nvl(v_sum_exp,0)-nvl(v_sum_sur,0)-nvl(v_sum_set,0) ; 
                   v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,V_PROD_TYPE,V_PROD_GRP,v_type, 0,0,0,v_tot_paid_mas);  
                  end if; 
                    commit; 
           end if; 
        if    nvl(v_sum_sal,0) > 0   then    
                      Begin 
                            INSERT INTO MRN_CLM_PAID(CLM_NO,PAY_TYPE,STATE_NO,STATE_SEQ,TYPE,PAY_DATE,PAY_AGT, 
                            PAY_SIGN,PAY_FOR_AMT,PAY_RTE,PAY_AMT,PAY_AGT_STS,PAY_RECP_STS,PAY_VAT_AMT,OFFSET_FLAG,CLM_SEQ) 
                            VALUES(V_CLM_NO,'16',V_PAY_NO,V_TRN_SEQ,V_TYPE,null,null, 
                            V_CURR_CODE1,0,V_CURR_RATE1,v_sum_sur,NULL,0,0,NULL,0); 
                      exception    
                      when  OTHERS  then    
                                 v_err_message := 'MRN_CLM_PAID';    
                                 rollback;    
                      End;   
                       
                       Begin    
                        INSERT INTO MRN_PAID_STAT(CLM_NO,STATE_NO,STATE_SEQ,TYPE,STATE_DATE,PA_AMT, 
                        SUR_AMT,SET_AMT,REC_AMT,EXP_AMT,TOT_AMT,DESCR_PAID,BEN_AMT,TYP_FLAG, 
                        CORR_DATE) 
                        values(V_CLM_NO,V_PAY_NO,V_TRN_SEQ,V_TYPE,null,nvl(v_sum_pa,0),nvl(v_sum_sur,0),nvl(v_sum_set,0),nvl(v_sum_sal,0),nvl(v_sum_exp,0),    
                        nvl(v_sum_rec,0)-nvl(v_sum_pa,0)-nvl(v_sum_exp,0)-nvl(v_sum_sur,0)-nvl(v_sum_set,0) ,v_part,'0',null,trunc(sysdate));   
                         
                        exception    
                        when  OTHERS  then    
                            v_err_message := 'MRN_PAID_STAT';    
                        rollback;  
                       end;  
                     if  v_clm_sts1 ='NCCLMSTS02' Then 
                        v_tot_paid_mas :=  nvl(v_sum_rec,0) - nvl(v_sum_pa,0) - nvl(v_sum_sur,0) - nvl(v_sum_exp,0) - nvl(v_sum_set,0); 
                        v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,V_PROD_TYPE,V_PROD_GRP,v_type, 0,v_tot_paid_mas,0,0); 
                     end if;  
                        commit; 
               end if; 
        if    nvl(v_sum_ded,0) > 0   then    
                      Begin 
                            INSERT INTO MRN_CLM_PAID(CLM_NO,PAY_TYPE,STATE_NO,STATE_SEQ,TYPE,PAY_DATE,PAY_AGT, 
                            PAY_SIGN,PAY_FOR_AMT,PAY_RTE,PAY_AMT,PAY_AGT_STS,PAY_RECP_STS,PAY_VAT_AMT,OFFSET_FLAG,CLM_SEQ) 
                            VALUES(V_CLM_NO,'17',V_PAY_NO,V_TRN_SEQ,V_TYPE,null,null, 
                            V_CURR_CODE1,0,V_CURR_RATE1,v_sum_sur,NULL,0,0,NULL,0); 
                      exception    
                      when  OTHERS  then    
                                 v_err_message := 'MRN_CLM_PAID';    
                                 rollback;    
                      End;   
                       
                       Begin    
                        INSERT INTO MRN_PAID_STAT(CLM_NO,STATE_NO,STATE_SEQ,TYPE,STATE_DATE,PA_AMT, 
                        SUR_AMT,SET_AMT,REC_AMT,EXP_AMT,TOT_AMT,DESCR_PAID,BEN_AMT,TYP_FLAG, 
                        CORR_DATE) 
                        values(V_CLM_NO,V_PAY_NO,V_TRN_SEQ,V_TYPE,null,nvl(v_sum_pa,0),nvl(v_sum_sur,0),nvl(v_sum_set,0),nvl(v_sum_ded,0),nvl(v_sum_exp,0),    
                         nvl(v_sum_rec,0)-nvl(v_sum_pa,0)-nvl(v_sum_exp,0)-nvl(v_sum_sur,0)-nvl(v_sum_set,0) ,v_part,'0',null,trunc(sysdate));   
                        exception    
                        when  OTHERS  then    
                            v_err_message := 'MRN_PAID_STAT';    
                        rollback;  
                       end;  
                      if  v_clm_sts1 ='NCCLMSTS02' Then 
                        v_tot_paid_mas := nvl(v_sum_rec,0)-nvl(v_sum_pa,0)-nvl(v_sum_exp,0)-nvl(v_sum_sur,0)-nvl(v_sum_set,0) ; 
                        v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,V_PROD_TYPE,V_PROD_GRP, v_type,0,0,v_tot_paid_mas,0);  
                      end if; 
                        commit; 
               end if; 
   Begin 
       FOR NC_PAYMENT_INFO IN 
       ( 
        SELECT A.CLM_NO,A.PAY_NO,A.TYPE,A.PROD_GRP,A.PROD_TYPE,A.TRN_SEQ,A.STS_DATE,A.AMD_DATE,A.PART,A.REMARK, 
        A.INVOICE_NO,A.REF_NO,A.CLM_USER,A.AMD_USER 
        FROM NC_PAYMENT_INFO A 
        WHERE A.CLM_NO = v_clm_no 
        AND A.PAY_NO = v_pay_no 
        AND A.TRN_SEQ IN (SELECT MAX(B.TRN_SEQ) FROM NC_PAYMENT_INFO B WHERE B.CLM_NO = A.CLM_NO AND B.PAY_NO=A.PAY_NO) 
       ) 
   Loop 
         v_part := P_CONVERT_PAYMENT.FIX_LINEFEED(substr( NC_PAYMENT_INFO.PART,1,10000)) ; 
         v_remark  := P_CONVERT_PAYMENT.FIX_LINEFEED(substr( NC_PAYMENT_INFO.REMARK,1,10000)) ; 
   End Loop; 
     begin 
       update mrn_paid_stat  
       set DESCR_PAID =v_part,remark =v_remark 
       where clm_no =v_clm_no and state_no= v_pay_no; 
       exception when others then rollback; 
      end; 
       commit;       
   End; 
    
   Begin 
     FOR NC_RI_PAID IN  
     (  
       select a.clm_no,a.pay_no,type,trn_seq,a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.ri_pay_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type    
            from nc_ri_paid a    
            where a.clm_no = v_clm_no   
            and a.pay_no = v_pay_no  
              and  a.type like 'NCNATTYPECLM%'    
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)    
                                                        from nc_ri_paid b    
                                                        where b.clm_no = a.clm_no    
                                                        and b.pay_no = a.pay_no  
                                                        and  b.type like 'NCNATTYPECLM%'    
                                                        group by b.clm_no,b.pay_no)    
      ) 
      Loop 
        Begin 
         INSERT INTO MRN_RI_PAID(CLM_NO, STATE_NO, STATE_SEQ, TYPE, RI_CODE, RI_BR_CODE,  
         LF_FLAG, RI_TYPE1, RI_TYPE2, CESS_PAY_NO, RI_SHR, RI_PAY_AMT) 
         VALUES(NC_RI_PAID.CLM_NO,NC_RI_PAID.PAY_NO,NC_RI_PAID.TRN_SEQ,v_type,NC_RI_PAID.RI_CODE,NC_RI_PAID.RI_BR_CODE, 
         NC_RI_PAID.RI_LF_FLAG,NC_RI_PAID.RI_TYPE,NC_RI_PAID.RI_SUB_TYPE,NC_RI_PAID.lett_no ,NC_RI_PAID.RI_SHARE,NVL(NC_RI_PAID.RI_PAY_AMT,0)); 
         exception    
         when  OTHERS  then    
                 v_err_message := 'MRN_RI_PAID';    
                 rollback;     
        End; 
      End Loop; 
    commit;    
    End;   
     
    Begin 
     FOR NC_RI_PAID IN  
     (  
        select a.clm_no,a.pay_no,type,trn_seq,a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.ri_pay_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type    
            from nc_ri_paid a    
            where a.clm_no = v_clm_no   
            and a.pay_no = v_pay_no  
              and a.type like 'NCNATTYPEREC%'      
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)    
                                                        from nc_ri_paid b    
                                                        where b.clm_no = a.clm_no    
                                                        and b.pay_no = a.pay_no  
                                                         and a.type like 'NCNATTYPEREC%'       
                                                        group by b.clm_no,b.pay_no)     
      ) 
      Loop 
        Begin 
         INSERT INTO MRN_RI_PAID(CLM_NO, STATE_NO, STATE_SEQ, TYPE, RI_CODE, RI_BR_CODE,  
         LF_FLAG, RI_TYPE1, RI_TYPE2, CESS_PAY_NO, RI_SHR, RI_PAY_AMT, SALVAGE_AMT, DEDUCT_AMT,  
         IMD_OFFSET, RECOV_AMT, LOSS_EXPENSE, RECOV_EXPENSE) 
         VALUES(NC_RI_PAID.CLM_NO,NC_RI_PAID.PAY_NO,NC_RI_PAID.TRN_SEQ,v_type,NC_RI_PAID.RI_CODE,NC_RI_PAID.RI_BR_CODE, 
         NC_RI_PAID.RI_LF_FLAG,NC_RI_PAID.RI_TYPE,NC_RI_PAID.RI_SUB_TYPE,NC_RI_PAID.lett_no ,NC_RI_PAID.RI_SHARE,NVL(NC_RI_PAID.RI_PAY_AMT,0),0,0, 
         0,0,0,0); 
        exception    
        when  OTHERS  then    
                 v_err_message := 'MRN_RI_PAID';    
                 rollback;      
        End; 
      End Loop; 
    commit;    
    End;   
 
  Begin 
    FOR NC_PAYEE IN 
    ( 
        SELECT A.CLM_NO, A.PAY_NO, A.PROD_GRP, A.PROD_TYPE, A.TRN_SEQ, A.STS_DATE,A.AMD_DATE, A.PAYEE_CODE, 
        substr(ltrim(rtrim(A.PAYEE_NAME)),1,45)PAYEE_NAME, A.PAYEE_TYPE, A.PAYEE_SEQ, A.PAYEE_AMT, P_CONVERT_PAYMENT.CONVERT_PAYMENT_METHOD(A.SETTLE)SETTLE, A.ACC_NO, A.ACC_NAME, A.BANK_CODE,  
        A.BANK_BR_CODE,substr(ltrim(rtrim(A.BR_NAME)),1,45)BR_NAME, A.SEND_TITLE, A.SEND_ADDR1, A.SEND_ADDR2, A.PAID_STS, A.SALVAGE_FLAG,  
        A.DEDUCT_FLAG, A.SMS, A.EMAIL, A.TYPE,SALVAGE_AMT,DEDUCT_AMT,SENT_TYPE 
        FROM NC_PAYEE A 
        WHERE A.CLM_NO =v_clm_no 
        AND A.PAY_NO = v_pay_no 
        AND A.TRN_SEQ IN (SELECT MAX(B.TRN_SEQ) FROM NC_PAYEE B  
                                                WHERE B.CLM_NO = v_clm_no 
                                                AND B.PAY_NO =v_pay_no) 
    ) 
    Loop 
     v_offset2 := null; 
     v_offset1 := null; 
  
        IF NC_PAYEE.DEDUCT_FLAG = '1' THEN   
            v_offset2 := 'P' ;     
        ELSIF  NC_PAYEE.DEDUCT_FLAG = '2' THEN   
            v_offset2 := 'M' ;     
        ELSE 
             v_offset2 := NULL ; 
        END IF; 
 
        IF NC_PAYEE.SALVAGE_FLAG = '1' THEN   
            v_offset1 := 'P' ;     
        ELSIF NC_PAYEE.SALVAGE_FLAG = '2' THEN   
            v_offset1 := 'M' ;   
        ELSE 
            v_offset1 := NULL ; 
        END IF; 
        
        Begin        
        select thai_brn_name into v_brname 
             from bank_branch 
             where bank_code =  NC_PAYEE.BANK_CODE  and branch_code = NC_PAYEE.BANK_BR_CODE ; 
        exception    
        when no_data_found then  
            v_brname := null; 
        when  OTHERS  then    
            v_brname := null; 
        End; 
    Begin 
       INSERT INTO MRN_CLM_PAYEE(CLM_NO, STATE_NO, STATE_SEQ, TYPE, PAY_DATE, PAY_TYPE,  
       PAY_AGT, PAY_AMT, SETTLE, CHEQUE_NO, ACC_NO, ACC_NAME,BANK_CODE, BR_NAME, OTHER,  
       ITEM_NO, PAYEE_CODE, BR_CODE, PAY_AGT_STS, VAT_AMT,SALVAGE_AMT,DEDUCT_AMT,PAYEE_OFFSET,PAYEE_OFFSET2 ) 
       VALUES(NC_PAYEE.CLM_NO,NC_PAYEE.PAY_NO,NC_PAYEE.TRN_SEQ,v_type,NC_PAYEE.STS_DATE,v_pay_type, 
       NC_PAYEE.PAYEE_NAME,NC_PAYEE.PAYEE_AMT,NC_PAYEE.SETTLE,NULL,NC_PAYEE.ACC_NO,NC_PAYEE.ACC_NAME,NC_PAYEE.BANK_CODE,NC_PAYEE.BR_NAME,NULL, 
       NC_PAYEE.PAYEE_SEQ,NC_PAYEE.PAYEE_CODE,NC_PAYEE.BANK_BR_CODE,NULL,0,NC_PAYEE.SALVAGE_AMT,NC_PAYEE.DEDUCT_AMT,v_offset1,v_offset2 ); 
       exception    
       when  OTHERS  then    
                 v_err_message := 'MRN_CLM_PAYEE';    
                 rollback;  
    End;    
    End Loop;  
 
  IF  v_clm_sts1 ='NCCLMSTS02' Then 
           BEGIN 
             update mrn_clm_mas 
             set   
             DEDUCT_REC_FLAG = v_deduct, 
             SALVAGE_REC_FLAG = v_salvage, 
             RECOVERY_REC_FLAG = v_recovery 
             where clm_no=v_clm_no; 
             exception when others then 
               v_err_message := 'mrn_clm_mas';  
            rollback;  
           END; 
       
   END IF;     
   commit;  
   End; 
End conv_insert_mrn_table; 
 
PROCEDURE  conv_insert_hull_table (v_clm_no in varchar2,v_pay_no in varchar2,v_prod_type varchar2, v_err_message out varchar2)IS 
      v_res_amt             number;    
      v_mrn_code            varchar2(4);    
      v_state_no            varchar2(16);    
      v_rec_state_no        varchar2(16);    
      v_sal_state_no        varchar2(16);    
      v_ded_state_no        varchar2(16);    
      v_pol_te              varchar2(1);    
      v_pol_br              varchar2(3);    
      v_agent_code          varchar2(5);    
      v_agent_seq           varchar2(2);    
      v_vessel_code         varchar2(7);    
      v_vessel_seq          number;    
      v_vessel_enq          varchar2(35);    
      v_clm_user            varchar2(10);       
      v_curr_code           varchar2(3);    
      v_curr_rate           number(8,5);       
      v_cond_code           varchar2(4);    
      v_sum_ded             number(14,2) := 0;    
      v_sum_pa              number(14,2) := 0;    
      v_sum_exp             number(14,2) := 0;    
      v_pol_type            varchar2(2);    
      v_cus_te              varchar2(1);    
      v_co_type             varchar2(1);    
      v_leader              varchar2(1);    
      v_your_pol_no         varchar2(30);    
      v_your_end_no         varchar2(30);    
      v_ben_code            varchar2(4);    
      v_ben_descr           varchar2(100);    
      v_type                varchar2(2);    
      v_out_type            varchar2(2);    
      v_co_shr              number(6,3) := 0;    
      v_sum_rec_clm         number(14,2) := 0;    
      v_tot_rec_clm         number(14,2) := 0;    
      v_sum_rec             number(14,2) := 0;    
      v_tot_rec             number(14,2) := 0;    
      v_sum_sal             number(14,2) := 0;    
      v_tot_sal             number(14,2) := 0;    
      v_sum_sur             number(14,2) := 0;    
      v_tot_sur             number(14,2) := 0;    
      v_sum_set             number(14,2) := 0;    
      v_tot_set             number(14,2) := 0;    
      v_flag                boolean;    
      v_type1               varchar2(2); 
      v_trn_seq             nc_payment.trn_seq%type; 
      v_pay_type            varchar2(2); 
      v_pay_sts             nc_payment.pay_sts%type; 
      v_curr_code1          nc_payment.curr_code%type; 
      v_curr_rate1          nc_payment.curr_rate%type; 
      v_clm_men             nc_payment.clm_men%type; 
      v_amd_user            nc_payment.amd_user%type; 
      v_pay_amt             nc_payment.pay_amt%type; 
      v_sts_date            nc_payment.sts_date%type; 
      v_amd_date            nc_payment.amd_date%type; 
      v_settle_date         nc_payment.settle_date%type; 
      v_part                nc_payment_info.part%type; 
      v_remark            nc_payment_info.remark%type; 
      v_result_Ms           varchar2(20); 
      v_payee_name          varchar2(50); 
      v_salvage                  char(1); 
      v_deduct                   char(1); 
      v_recovery                char(1); 
      cnt_x1  number:=0; 
      v_rst  VARCHAR2(500) ; 
      v_offset1   varchar2(2); 
      v_offset2   varchar2(2); 
      v_brname    varchar2(200); 
      v_tot_paid_mas  number(13,2);  
      v_prod_grp   varchar2(5); 
Begin    
    v_err_message := null;    
    BEGIN 
        select count(*) into cnt_x1 
        from nc_payee c 
        where  c.clm_no = v_clm_no and c.pay_no = v_pay_no ; 
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN 
            cnt_x1 := 0 ; 
        WHEN OTHERS THEN 
            cnt_x1 := 0; 
    END;  
     
    IF cnt_x1 = 0 THEN 
        v_err_message := 'not convert!!  wait for NC_Payee Data '; 
        nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: count nc_payee ' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' || '|| v_err_message ,'not found' ,v_rst) ; 
        return ;      
    END IF; 
    Begin    
    FOR NC_PAYMENT IN   
       ( 
        SELECT  A.CLM_NO,A.PAY_NO,A.CLM_SEQ,A.TRN_SEQ,A.PAY_STS,A.PAY_AMT,A.TRN_AMT,A.CURR_CODE, 
                A.CURR_RATE,A.STS_DATE,A.AMD_DATE,A.SETTLE_DATE,A.CLM_MEN,A.AMD_USER,A.APPROVE_ID, 
                A.APPROVE_DATE,A.PROD_GRP,A.PROD_TYPE,A.SUBSYSID,A.STS_KEY,A.PRINT_TYPE,A.TYPE,SUB_TYPE, 
                A.APPRV_FLAG,A.BATCH_NO,A.PREM_CODE,A.PREM_SEQ,A.OFFSET_FLAG,A.STATUS,A.TOT_PAY_AMT         
        FROM NC_PAYMENT A    
        WHERE A.CLM_NO = v_clm_no  
        AND A.PAY_NO = v_pay_no  
        AND A.TRN_SEQ IN (SELECT MAX(B.TRN_SEQ)FROM NC_PAYMENT B WHERE B.CLM_NO = A.CLM_NO AND B.PAY_NO = A.PAY_NO)  
        )  
        loop  
         GET_SALVAGE_DEDUCT_RECOV_FLAG(v_clm_no,v_pay_no,v_salvage,v_deduct,v_recovery);  
         
        v_curr_code1 := nc_payment.CURR_CODE; 
        v_curr_rate1 := nc_payment.CURR_RATE; 
        v_clm_men := nc_payment.CLM_MEN; 
        v_amd_user := nc_payment.AMD_USER;   
        v_pay_amt := nc_payment.PAY_AMT;  
        v_pay_sts  :=  nc_payment.pay_sts; 
        v_curr_code1 := nc_payment.curr_code; 
        v_curr_rate1 := nc_payment.curr_rate; 
        v_clm_men := nc_payment.clm_men; 
        v_amd_user := nc_payment.amd_user; 
        v_sts_date:= nc_payment.sts_date; 
        v_amd_date := nc_payment.amd_date; 
        v_settle_date := nc_payment.settle_date; 
        v_trn_seq := nc_payment.trn_seq; 
        v_prod_grp  := nc_payment.prod_grp; 
         
              if      rtrim(nc_payment.type) in ('NCNATTYPECLM001','NCNATTYPECLM002')  then         
                      v_type := '01';         
              elsif  rtrim(nc_payment.type) in ('NCNATTYPEREC001') then         
                      if      rtrim(nc_payment.sub_type) in ('NCNATSUBTYPEREC001','NCNATSUBTYPEREC002') then         
                              if   nc_payment.offset_flag = 'Y'  then         
                                   v_type := '01';         
                                   v_pay_type := '07';         
                                   v_sum_rec_clm := v_sum_rec_clm + nvl(nc_payment.pay_amt,0);         
                              else         
                                   v_type := '02';         
                                   v_pay_type := '15';         
                                   v_sum_rec := v_sum_rec + nvl(nc_payment.pay_amt,0);         
                              end if;         
                      elsif  rtrim(nc_payment.sub_type) in ('NCNATSUBTYPESAL001') then         
                              if    nc_payment.offset_flag = 'Y'   then         
                                    v_type := '01';         
                                    v_pay_type := '06';         
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_payment.pay_amt,0);         
                              else         
                                    v_type := '03';         
                                    v_pay_type := '16';         
                                    v_sum_sal := v_sum_sal + nvl(nc_payment.pay_amt,0);         
                              end if;         
                      elsif  rtrim(nc_payment.sub_type) in ('NCNATSUBTYPEDED001') then         
                              if    nc_payment.offset_flag = 'Y'   then         
                                    v_type := '01';         
                                    v_pay_type := '05';         
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_payment.pay_amt,0);         
                              else         
                                    v_type := '04';         
                                    v_pay_type := '17';         
                                    v_sum_ded := v_sum_ded + nvl(nc_payment.pay_amt,0);         
                              end if;         
                      else         
                              v_type := '01';         
                      end if;         
              end if;         
              if     rtrim(nc_payment.type) in ('NCNATTYPECLM001')  then         
                     v_pay_type := '01';         
                     v_sum_pa := v_sum_pa + nvl(nc_payment.pay_amt,0);         
              elsif rtrim(nc_payment.type) in ('NCNATTYPECLM002')  then         
                     if     rtrim(nc_payment.sub_type) in ('NCNATSUBTYPECLM010','NCNATSUBTYPECLM011','NCNATSUBTYPECLM012')   then         
                            v_pay_type := '04';         
                            v_sum_sur := v_sum_sur + nvl(nc_payment.pay_amt,0);         
                     elsif rtrim(nc_payment.sub_type) in ('NCNATSUBTYPECLM013')   then         
                            v_pay_type := '08';         
                            v_sum_set := v_sum_set + nvl(nc_payment.pay_amt,0);         
                     elsif rtrim(nc_payment.sub_type) in ('NCNATSUBTYPECLM015')   then         
                            v_pay_type := '09';         
                            v_sum_exp := v_sum_exp + nvl(nc_payment.pay_amt,0);         
                     elsif rtrim(nc_payment.sub_type) in ('NCNATSUBTYPECLM017')   then         
                            v_pay_type := '10';         
                            v_sum_exp := v_sum_exp + nvl(nc_payment.pay_amt,0);         
                     elsif rtrim(nc_payment.sub_type) in ('NCNATSUBTYPECLM018')   then         
                            v_pay_type := '12';         
                            v_sum_exp := v_sum_exp + nvl(nc_payment.pay_amt,0);         
                     elsif rtrim(nc_payment.sub_type) in ('NCNATSUBTYPECLM019')   then         
                            v_pay_type := '13';         
                            v_sum_exp := v_sum_exp + nvl(nc_payment.pay_amt,0);         
                     end if;         
              end if;   
        
         if   v_pay_type not in  ('01')   then    
              Begin    
                insert into hull_clm_paid (clm_no,pay_type,pay_no,pay_seq,type,paid_date,pay_sign,pay_for_amt,pay_rte,pay_amt,pay_agt_sts)    
                values (v_clm_no,v_pay_type,v_pay_no,nvl(v_trn_seq,1),v_type,null,'BHT',nc_payment.pay_amt,1,nc_payment.pay_amt,'4');    
                exception    
                when  OTHERS  then    
                    v_err_message := 'HULL_CLM_PAID';    
                    rollback;    
              End;   
               commit;  
         end if;   
         commit;  
         End loop;    
        commit;    
        IF v_pay_type  not   in  ('01')   then   
           Begin    
                 Begin         
                       insert into hull_paid_stat (clm_no,pay_no,pay_seq,type,paid_date,paid_for_amt,paid_amt,TYP_FLAG)         
                       values (v_clm_no,v_state_no,nvl(v_trn_seq,1),v_type,null,v_pay_amt,v_pay_amt,'0');         
                    exception         
                       when  OTHERS  then         
                                 v_err_message := 'hull_paid_stat';         
                                 rollback;         
                    End;   
                    v_tot_paid_mas := v_pay_amt; 
                    v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,V_PROD_TYPE,V_PROD_GRP,v_type, v_tot_paid_mas,0,0,0);  
                    commit;       
           End;  
       commit;  
       End if; 
    End;    
    if    nvl(v_sum_pa,0) > 0   then    
        Begin    
            insert into hull_clm_paid (clm_no,pay_type,pay_no,pay_seq,type,paid_date,pay_sign,pay_for_amt,pay_rte,pay_amt,pay_agt_sts)    
            values (v_clm_no,'01',v_pay_no,nvl(v_trn_seq,1),v_type,null,'BHT',v_sum_pa,v_type,v_sum_pa,'1');    
            exception    
            when  OTHERS  then    
                v_err_message := 'hull_clm_paid';    
                rollback;    
        End;   
         commit;   
         Begin         
                       insert into hull_paid_stat (clm_no,pay_no,pay_seq,type,paid_date,paid_for_amt,paid_amt,TYP_FLAG)         
                       values (v_clm_no,v_state_no,nvl(v_trn_seq,1),v_type,null,v_pay_amt,v_pay_amt,'0');         
                    exception         
                       when  OTHERS  then         
                                 v_err_message := 'hull_paid_stat';         
                                 rollback;         
                    End;    
                    v_tot_paid_mas := v_pay_amt; 
                    v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,V_PROD_TYPE,V_PROD_GRP,v_type, v_tot_paid_mas,0,0,0);   
        commit;        
    end if;    
    if    nvl(v_sum_sur,0) > 0   then    
        Begin    
            insert into hull_clm_paid (clm_no,pay_type,pay_no,pay_seq,type,paid_date,pay_sign,pay_for_amt,pay_rte,pay_amt,pay_agt_sts)    
            values (v_clm_no,'04',v_pay_no,nvl(v_trn_seq,1),v_type,null,'BHT',v_sum_sur,v_type,v_sum_sur,'2');    
            exception    
            when  OTHERS  then    
                v_err_message := 'hull_clm_paid';    
                rollback;  
        End;  
       Begin         
                       insert into hull_paid_stat (clm_no,pay_no,pay_seq,type,paid_date,paid_for_amt,paid_amt,TYP_FLAG)         
                       values (v_clm_no,v_state_no,nvl(v_trn_seq,1),v_type,null,v_pay_amt,v_pay_amt,'0');         
                    exception         
                       when  OTHERS  then         
                                 v_err_message := 'hull_paid_stat';         
                                 rollback;         
        End;   
       v_tot_paid_mas := v_pay_amt; 
       v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,V_PROD_TYPE,V_PROD_GRP, v_type,v_tot_paid_mas,0,0,0);  
       commit;         
    end if;   
     
    Begin 
     FOR NC_PAYMENT_INFO IN 
     ( 
       SELECT A.CLM_NO, A.PAY_NO, A.TYPE, A.PROD_GRP, A.PROD_TYPE, A.TRN_SEQ, A.STS_DATE,A.AMD_DATE,  
       A.PART, A.REMARK, A.INVOICE_NO, A.REF_NO, A.CLM_USER, A.AMD_USER, A.STS_KEY 
       FROM NC_PAYMENT_INFO A 
       WHERE  A.CLM_NO = v_clm_no 
       AND A.PAY_NO = v_pay_no 
       AND A.TRN_SEQ IN (SELECT MAX(B.TRN_SEQ)  
                            FROM NC_PAYMENT_INFO B 
                            WHERE B.CLM_NO = v_clm_no 
                            AND B.PAY_NO =v_pay_no) 
     ) 
     Loop 
         v_part := P_CONVERT_PAYMENT.FIX_LINEFEED(substr( NC_PAYMENT_INFO.PART,1,10000)) ; 
         v_remark  := P_CONVERT_PAYMENT.FIX_LINEFEED(substr( NC_PAYMENT_INFO.REMARK,1,10000)) ; 
     Begin 
        insert into hull_txt_opt(CLM_NO,DESCR_OPT, STATE_NO, STATE_TYPE) 
        values(NC_PAYMENT_INFO.clm_no,v_part,NC_PAYMENT_INFO.pay_no,'2'); 
        exception    
        when  OTHERS  then    
                  v_err_message :='hull_txt_opt';    
                  rollback; 
     End; 
     End Loop; 
    End;  
    Begin    
        insert into hull_paid_stat (clm_no,pay_no,pay_seq,type,paid_date,paid_amt,typ_flag,corr_date)    
        values (v_clm_no,v_pay_no,nvl(v_trn_seq,1),v_type,null,nvl(v_sum_pa,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0)+nvl(v_sum_exp,0),'0',trunc(sysdate));    
        commit;    
    exception    
        when  OTHERS  then    
                  v_err_message :='HULL_PAID_STAT';    
                  rollback;   
    End;    
    if   nvl(v_sum_rec,0) > 0  then    
        Begin    
             insert into hull_paid_stat (clm_no,pay_no,pay_seq,type,paid_date,paid_amt,typ_flag,corr_date)    
             values (v_clm_no,v_pay_no,nvl(v_trn_seq,1),v_type,null,nvl(v_sum_rec,0),'0',trunc(sysdate));  
              
        exception    
        when  OTHERS  then    
            v_err_message := 'hull_paid_stat';    
            rollback;    
        End;           
         v_tot_paid_mas :=nvl(v_sum_rec,0); 
         v_result_Ms := P_CONVERT_PAYMENT.Update_Master_Dt(V_CLM_NO,V_PROD_TYPE,V_PROD_GRP, v_type,0,0,0,v_tot_paid_mas);     
        Begin 
             insert into hull_clm_paid (clm_no,pay_type,pay_no,pay_seq,type,paid_date,pay_sign,pay_for_amt,pay_rte,pay_amt)    
             values (v_clm_no,v_pay_type,v_pay_no,nvl(v_trn_seq,1),v_type,null,'BHT',nvl(v_sum_rec,0),1,nvl(v_sum_rec,0));      
             commit;   
        exception    
        when  OTHERS  then    
            v_err_message := 'hull_paid_stat';    
            rollback;       
        End;       
      commit;  
    end if;    
    if   nvl(v_sum_sal,0) > 0  then    
        Begin    
             insert into hull_paid_stat (clm_no,pay_no,pay_seq,type,paid_date,paid_amt,typ_flag,corr_date)    
             values (v_clm_no,v_pay_no,nvl(v_trn_seq,1),v_type,null,nvl(v_sum_sal,0),'0',trunc(sysdate));   
               
             insert into hull_clm_paid (clm_no,pay_type,pay_no,pay_seq,type,paid_date,pay_sign,pay_for_amt,pay_rte,pay_amt)    
             values (v_clm_no,v_pay_type,v_pay_no,nvl(v_trn_seq,1),v_type,null,'BHT',nvl(v_sum_sal,0),1,nvl(v_sum_sal,0));    
            commit;    
        exception    
        when  OTHERS  then    
                      v_err_message := 'hull_paid_stat';    
                     rollback;  
        End;    
      commit; 
    end if;    
    if   nvl(v_sum_ded,0) > 0  then    
        Begin    
             insert into hull_paid_stat (clm_no,pay_no,pay_seq,type,paid_date,paid_amt,typ_flag,corr_date)    
             values (v_clm_no,v_pay_no,nvl(v_trn_seq,1),v_type,null,nvl(v_sum_ded,0),'0',trunc(sysdate));    
        exception    
        when  OTHERS  then    
                     v_err_message := 'hull_paid_stat';    
                     rollback; 
        End;  
         
        Begin         
             insert into hull_clm_paid (clm_no,pay_type,pay_no,pay_seq,type,paid_date,pay_sign,pay_for_amt,pay_rte,pay_amt)    
             values (v_clm_no,v_pay_type,v_pay_no,0,v_type,null,'BHT',nvl(v_sum_ded,0),1,nvl(v_sum_ded,0));          
        exception    
        when  OTHERS  then    
                     v_err_message := 'hull_clm_paid';    
                     rollback;      
        End;   
        commit;  
    end if;    
    Begin    
        For nc_ri_paid in    
        (    
            select a.clm_no,a.pay_no,type,trn_seq,a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.ri_pay_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type    
            from nc_ri_paid a    
            where a.clm_no = v_clm_no   
            and a.pay_no = v_pay_no  
              and  a.type like 'NCNATTYPECLM%'    
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)    
                                                        from nc_ri_paid b    
                                                        where b.clm_no = a.clm_no    
                                                        and b.pay_no = a.pay_no  
                                                        and  b.type like 'NCNATTYPECLM%'    
                                                        group by b.clm_no,b.pay_no)    
         ) loop    
             Begin    
                 insert into hull_ri_paid (clm_no,pay_no,pay_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_shr,ri_pay_amt,cess_no)    
                 values (v_clm_no,v_pay_no,v_trn_seq,v_type,nc_ri_paid.ri_code,nc_ri_paid.ri_br_code,nc_ri_paid.ri_lf_flag,nc_ri_paid.ri_type,nc_ri_paid.ri_sub_type,    
                            nc_ri_paid.ri_share,nc_ri_paid.ri_pay_amt,nc_ri_paid.lett_no);    
              exception    
                 when  OTHERS  then    
                           v_err_message := 'hull_ri_paid';    
                           rollback;    
              End;    
         End loop;    
         commit;    
    End;    
    Begin    
        For nc_ri_paid in    
        (    
            select a.clm_no,a.pay_no,type,trn_seq,a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.ri_pay_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type    
            from nc_ri_paid a    
            where a.clm_no = v_clm_no   
            and a.pay_no = v_pay_no  
            and a.type like 'NCNATTYPEREC%'       
            and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)    
                                                        from nc_ri_paid b    
                                                        where b.clm_no = a.clm_no    
                                                        and b.pay_no = a.pay_no  
                                                        and a.type like 'NCNATTYPEREC%'    
                                                        group by b.clm_no,b.pay_no)    
         ) loop    
             Begin    
                 insert into hull_ri_paid (clm_no,pay_no,pay_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_shr,ri_pay_amt,cess_no)    
                 values (v_clm_no,v_pay_no,v_trn_seq,v_type,nc_ri_paid.ri_code,nc_ri_paid.ri_br_code,nc_ri_paid.ri_lf_flag,nc_ri_paid.ri_type,nc_ri_paid.ri_sub_type,    
                            nc_ri_paid.ri_share,nc_ri_paid.ri_pay_amt,nc_ri_paid.lett_no);    
              exception    
                 when  OTHERS  then    
                           v_err_message := 'hull_ri_paid';    
                           rollback;   
              End;    
         End loop;    
         commit;    
    End;    
     
    Begin 
    FOR NC_PAYEE IN 
    ( 
        SELECT A.CLM_NO, A.PAY_NO, A.PROD_GRP, A.PROD_TYPE, A.TRN_SEQ, A.STS_DATE,A.AMD_DATE, A.PAYEE_CODE,  
         substr(ltrim(rtrim(A.PAYEE_NAME)),1,45)PAYEE_NAME, A.PAYEE_TYPE, A.PAYEE_SEQ, A.PAYEE_AMT,P_CONVERT_PAYMENT.CONVERT_PAYMENT_METHOD(A.SETTLE)SETTLE , A.ACC_NO, A.ACC_NAME, A.BANK_CODE,  
        A.BANK_BR_CODE,substr(ltrim(rtrim(A.BR_NAME)),1,45)BR_NAME, A.SEND_TITLE, A.SEND_ADDR1, A.SEND_ADDR2, A.PAID_STS, A.SALVAGE_FLAG,  
        A.DEDUCT_FLAG, A.SMS, A.EMAIL, A.TYPE,SALVAGE_AMT,DEDUCT_AMT 
        FROM NC_PAYEE A 
        WHERE A.CLM_NO =v_clm_no 
        AND A.PAY_NO = v_pay_no 
        AND A.TRN_SEQ IN (SELECT MAX(B.TRN_SEQ) FROM NC_PAYEE B  
                                                WHERE B.CLM_NO =A.CLM_NO 
                                                AND B.PAY_NO =A.PAY_NO) 
    ) 
    Loop 
     v_offset2 := null; 
     v_offset1 := null; 
      
       IF NC_PAYEE.DEDUCT_FLAG = '1' THEN   
            v_offset2 := 'P' ;     
        ELSIF  NC_PAYEE.DEDUCT_FLAG = '2' THEN   
            v_offset2 := 'M' ;     
        ELSE 
             v_offset2 := NULL ; 
        END IF; 
 
        IF NC_PAYEE.SALVAGE_FLAG = '1' THEN   
            v_offset1 := 'P' ;     
        ELSIF NC_PAYEE.SALVAGE_FLAG = '2' THEN   
            v_offset1 := 'M' ;   
        ELSE 
            v_offset1 := NULL ; 
        END IF; 
    Begin 
       INSERT INTO HULL_CLM_PAYEE(CLM_NO, PAY_NO, PAY_SEQ, TYPE,PAID_DATE,   
       PAY_AGT, PAY_AMT, SETTLE, CHEQUE_NO, ACC_NO, ACC_NAME, BANK_CODE,OTHER,  
       BEN_SEQ, PAYEE_CODE, BR_CODE, PAY_AGT_STS,DESCR_BEN,SALVAGE_AMT,DEDUCT_AMT,PAYEE_OFFSET,PAYEE_OFFSET2) 
       VALUES(NC_PAYEE.CLM_NO,NC_PAYEE.PAY_NO,NC_PAYEE.TRN_SEQ,v_pay_type,TRUNC(NC_PAYEE.STS_DATE), 
       null,NC_PAYEE.PAYEE_AMT,NC_PAYEE.SETTLE,NULL,NC_PAYEE.ACC_NO,NC_PAYEE.ACC_NAME,NC_PAYEE.BANK_CODE,NULL, 
       NC_PAYEE.PAYEE_SEQ,NC_PAYEE.PAYEE_CODE,NC_PAYEE.BANK_BR_CODE,NULL,NC_PAYEE.PAYEE_NAME,NC_PAYEE.SALVAGE_AMT,NC_PAYEE.DEDUCT_AMT,v_offset1,v_offset2); 
       exception    
       when  OTHERS  then    
                 v_err_message := 'HULL_CLM_PAYEE';    
                 rollback;  
    End; 
    End Loop;  
      commit;  
    End;   
End conv_insert_hull_table;       
         
FUNCTION GET_PAYTYPE(In_prod_grp in varchar2,In_prem_code in varchar2,In_offset_flag in varchar2, In_type in varchar2 ,In_subtype in varchar2) return  varchar2 IS                
v_map_type varchar2(5);                
v_pay_type varchar2(2);                
begin                
    if In_prod_grp ='1' then  --fire                
        if  In_type in ('NCNATTYPECLM001')  then                
            if  In_prem_code in ('1010') then                
                v_pay_type := '01';                
            elsif  In_prem_code in  ('1560') then                
                v_pay_type := '02';                
            elsif  In_prem_code in  ('1050') then                
                v_pay_type := '03';                
            elsif  In_prem_code in  ('1020','1030','1040')  then                
                v_pay_type := '04';                
            else                
                v_pay_type := '05';                
            end if;                
        elsif In_type in ('NCNATTYPECLM002')  then                
            if  In_subtype in ('NCNATSUBTYPECLM010','NCNATSUBTYPECLM011','NCNATSUBTYPECLM012')   then                
                v_pay_type := '06';                
            else                
                v_pay_type := '08';                
            end if;                
        end if;                
    elsif  In_prod_grp ='2' then                
                
         if  In_type in ('NCNATTYPEREC001') then                
            if  In_subtype in ('NCNATSUBTYPEREC001') then                
                if   In_offset_flag = 'Y'  then                
                    v_pay_type := '07';                
                else                
                    v_pay_type := '15';                
                end if;                
            elsif  In_subtype in ('NCNATSUBTYPESAL001') then                
                if  In_offset_flag = 'Y'   then                
                    v_pay_type := '06';                
                else                
                    v_pay_type := '16';                
                end if;                
            elsif  In_subtype in ('NCNATSUBTYPEDED001') then                
                if   In_offset_flag= 'Y'   then                
                    v_pay_type := '05';                
                else                
                    v_pay_type := '17';                
                end if;                
            end if;                
         end if;                
         if     In_type in ('NCNATTYPECLM001')  then                
                     v_pay_type := '01';                
         elsif  In_type in ('NCNATTYPECLM002')  then                
                if  In_subtype in ('NCNATSUBTYPECLM010','NCNATSUBTYPECLM011','NCNATSUBTYPECLM012')   then                
                        v_pay_type := '04';                
                elsif In_subtype in ('NCNATSUBTYPECLM013')   then                
                        v_pay_type := '08';                
                elsif In_subtype in ('NCNATSUBTYPECLM015')   then                
                        v_pay_type := '09';                
                elsif In_subtype in ('NCNATSUBTYPECLM017')   then                
                        v_pay_type := '10';                
                elsif In_subtype in ('NCNATSUBTYPECLM018')   then                
                        v_pay_type := '12';                
                elsif In_subtype in ('NCNATSUBTYPECLM019')   then                
                        v_pay_type := '13';                
                end if;                
         end if;                
    end if;                
    return(v_pay_type);                
   exception                
   when others then                
   return(null);                
 end;                
 FUNCTION GET_TYPE(In_prod_grp in varchar2,In_offset_flag in varchar2,In_type in varchar2 ,In_subtype in varchar2)return varchar2 is                
 v_type varchar2(2);                
 begin                
 if In_prod_grp ='1' then                
     if     In_type in ('NCNATTYPECLM001','NCNATTYPECLM002')  then                
             v_type := '01';                
     elsif  In_type in ('NCNATTYPEREC001') then                
            if  In_subtype in ('NCNATSUBTYPEREC001') then                
                v_type := '02';                
            elsif  In_subtype in ('NCNATSUBTYPESAL001') then                
                v_type := '03';                
            else                
                v_type := '01';                
            end if;                
     end if;                
elsif In_prod_grp ='2' then                
  if  In_type in ('NCNATTYPECLM001','NCNATTYPECLM002')  then                
                      v_type := '01';                
         elsif  In_type in ('NCNATTYPEREC001') then                
                      if      In_subtype in ('NCNATSUBTYPEREC001') then                
                              if   In_offset_flag = 'Y'  then                
                                   v_type := '01';                
                              else                
                                   v_type := '02';                
                              end if;                
                      elsif  In_subtype in ('NCNATSUBTYPESAL001') then                
                              if    In_offset_flag = 'Y'   then                
                                    v_type := '01';                
                              else                
                                    v_type := '03';                
                              end if;                
                      elsif  In_subtype in ('NCNATSUBTYPEDED001') then                
                              if    In_offset_flag = 'Y'   then                
                                    v_type := '01';                
                              else                
                                    v_type := '04';                
                              end if;                
                      else                
                              v_type := '01';                
                      end if;                
   end if;                
 end if;                
   return(v_type);                
   exception                
   when others then                
   return(null);                
 end;                
                
 FUNCTION Update_Master_Dt(In_clm_no in varchar2,In_prod_type in varchar2,In_prod_grp in varchar2,In_type in varchar2,v_tot_paid in number,v_salvage in number,v_deduct in number,v_recov in number) return varchar2 is  
  v_err_message varchar2(20);  
  x_tot_paid  number(13,2);  
  x_tot_ded number(13,2);  
  x_tot_sal  number(13,2);  
  x_tot_rec number(13,2);  
 begin  
 if  In_prod_grp in ('2') then  
      if In_prod_type in ('221','223')then  
        begin  
            select sum(decode(a.type,'01',a.tot_amt,0))tot_paid ,   
                     sum(decode(a.type,'02',a.tot_amt,0))tot_rec,  
                     sum(decode(a.type,'03',a.tot_amt,0))tot_sal ,    
                     sum(decode(a.type,'04',a.tot_amt,0))tot_deduct     
                     into  x_tot_paid,x_tot_rec,x_tot_sal,x_tot_ded  
                     from mrn_paid_stat a   
                     where a.clm_no = In_clm_no  
                     and    a.type in In_type  
                     and   (a.state_no,a.state_seq) = (select b.state_no,max(b.state_seq)   
                                                                     from   mrn_paid_stat b   
                                                                     where  b.clm_no = a.clm_no   
                                                                     and    b.state_no = a.state_no   
                                                                     and    b.type = a.type   
                                                                     and    b.corr_date <= trunc(sysdate)  
                                                          group by b.state_no)   
                group by a.clm_no;  
         begin  
          update mrn_clm_mas  
          set tot_paid = x_tot_paid,  
           tot_sal=x_tot_ded,  
           tot_dec =x_tot_ded,  
           tot_rec =x_tot_rec  
          where clm_no = In_clm_no ;  
         end;  
          exception     
           when  OTHERS  then     
                     v_err_message := 'mrn_clm_mas';     
                     rollback;   
         end  
         commit;  
     elsif In_prod_type in ('222')then  
      begin  
        begin  
         select  sum(decode(a.type,'01',a.paid_amt,0))tot_paid,   
                   sum(decode(a.type,'02',a.paid_amt,0))tot_rec,  
                   sum(decode(a.type,'03',a.paid_amt,0))tot_sal,    
                   sum(decode(a.type,'04',a.paid_amt,0))tot_deduct     
                   into  x_tot_paid,x_tot_rec,x_tot_sal,x_tot_ded  
                   from hull_paid_stat a   
                   where a.clm_no = In_clm_no  
                   and    a.type in  In_type  
                   and   (a.pay_no,a.pay_seq) = (select b.pay_no,max(b.pay_seq)   
                                                                from   hull_paid_stat b   
                                                                where  b.clm_no = a.clm_no   
                                                                and    b.pay_no = a.pay_no   
                                                                and    b.type = a.type   
                                                                and    b.corr_date <=  trunc(sysdate)  
                                                                group by b.pay_no)   
                  group by a.clm_no;  
         exception  
         when others then   
         x_tot_paid :=0;  
         x_tot_ded:=0;  
         x_tot_sal:=0;  
         x_tot_rec:=0;  
        end;  
        begin  
          update hull_clm_mas  
          set tot_paid = x_tot_paid,  
               tot_rec   = x_tot_rec  
          where clm_no = in_clm_no ;  
        end;  
          exception     
           when  OTHERS  then     
                     v_err_message := 'hull_clm_mas';     
                     rollback;   
         end  
         commit;  
     end if;  
 elsif In_prod_grp in ('1') then  
   begin  
        select     
                   sum(decode(b.type,'01',b.tot_our_loss,0))tot_paid ,   
                   sum(decode(b.type,'02',b.tot_our_loss,0))tot_rec,  
                   sum(decode(b.type,'03',b.tot_our_loss,0))tot_sal,  
                   sum(decode(b.type,'04',b.tot_our_loss,0))tot_deduct  
                   into  x_tot_paid,x_tot_rec,x_tot_sal,x_tot_ded  
                   from     fir_paid_stat b  
                   where   b.clm_no = in_clm_no  
                   and    (b.state_no,b.state_seq) = (select a1.state_no,max(a1.state_seq)   
                                                        from fir_paid_stat a1  
                                                         where a1.clm_no = b.clm_no  
                                                         and a1.state_no = b.state_no  
                                                         and a1.corr_date <= trunc(sysdate)  
                                                         and lpad(a1.type,2,'0') = '01'  
                                                    group by a1.state_no)  
                   and    b.corr_date <= trunc(sysdate)  
                   and    lpad(b.type,2,'0') =In_type ;  
         exception  
         when others then   
         x_tot_paid :=0;  
         x_tot_ded:=0;  
         x_tot_sal:=0;  
         x_tot_rec:=0;  
        end;  
          
         begin  
         update fir_clm_mas  
          set tot_paid = x_tot_paid,  
           tot_sal=x_tot_ded,  
           tot_dec =x_tot_ded,  
           tot_rec =x_tot_rec  
          where clm_no = IN_clm_no ;  
          exception when  OTHERS  then     
                     v_err_message := 'fir_clm_mas';   
                     rollback;    
   end  
   commit;  
 end if;  
   return(v_err_message);  
   exception  
   when others then   
   return(null);  
 end Update_Master_Dt;  
                
 PROCEDURE conv_insert_all_table(v_clm_no in varchar2,v_pay_no in varchar2,v_prod_type varchar2, v_err_message out varchar2) IS            
    v_prod_grp  varchar2(2);            
 BEGIN              
    IF v_prod_type in ('221','223') then --MRN            
        P_CONVERT_PAYMENT.conv_insert_mrn_table(v_clm_no,v_pay_no,v_prod_type, v_err_message);             
    ELSIF v_prod_type = '222' then --HULL            
        P_CONVERT_PAYMENT.conv_insert_hull_table(v_clm_no,v_pay_no,v_prod_type, v_err_message);            
    ELSE            
        begin            
            select prod_grp into v_prod_grp            
            from prod_type_std            
            where prod_type = v_prod_type and rownum=1 ;            
        exception            
            when no_data_found then            
                v_prod_grp := null;            
            when others then            
                v_prod_grp := null;            
        end;                
        IF v_prod_grp not in ('0','1','2','3' ) THEN            
             P_CONVERT_PAYMENT.CONV_INSERT_MISC_TABLE ( V_CLM_NO, V_PAY_NO, null, V_PROD_TYPE, V_ERR_MESSAGE );             
        Elsif  v_prod_grp in ('1') THEN             
            P_CONVERT_PAYMENT.conv_insert_fire_table(v_clm_no,v_pay_no,v_prod_type, v_err_message) ;            
        ELSE            
            v_err_message := 'not found package for Convert payment!!';            
        END IF;            
    END IF;            
             
 END;               
              
PROCEDURE CONV_INSERT_MISC_TABLE(v_clm_no in varchar2,v_pay_no in varchar2,v_trn_seq in number ,v_prod_type varchar2, v_err_message out varchar2) IS              
    v_pay_amt             nc_payment.pay_amt%type;              
    v_total_pay_total    nc_payment.tot_pay_amt%type;              
    v_deduct_total             mis_cms_paid.deduct_amt%type;              
    v_total_deduct_total    mis_cms_paid.tot_deduct_amt%type;                  
    v_clmsts    varchar2(20);              
    v_closedate date;              
    v_reopendate    date;              
    v_type  varchar2(20);              
    v_paytype varchar2(20);              
    cnt_x1  number:=0;              
    rec_x1  number:=0;              
    x_corr_seq  number:=0;              
    cms_pay_amt mis_cms_paid.pay_amt%type;              
    cms_tot_pay_amt mis_cms_paid.total_pay_amt%type;                 
    cms_deduct_amt mis_cms_paid.deduct_amt%type;              
    cms_tot_deduct_amt mis_cms_paid.tot_deduct_amt%type;                   
    cms_salvage_amt mis_cms_paid.salvage_amt%type;              
    cms_tot_salvage_amt mis_cms_paid.tot_salvage_amt%type;                    
    v_offset1   varchar2(2);              
    v_offset2   varchar2(2);                 
    v_part varchar2(10000);              
    v_remark varchar2(1000);              
    v_attached varchar2(100);              
    v_totpaid   number;              
    v_brname    varchar2(200);              
              
    o_salvage  VARCHAR2(1) ;              
    o_deduct   VARCHAR2(1) ;              
    o_recov   VARCHAR2(1)    ;              
    o_res_rec   number;              
    v_prt_flag  VARCHAR2(1)    ;              
    v_rectype   varchar2(2);              
    v_rec_closedate date;              
    v_rec_sts   varchar2(2);              
    v_rec_maxseq    number:=0;              
    v_rec_cnt   number:=0;              
                  
    v_paysts  VARCHAR2(1) ;              
    v_chkpaysts0    boolean:=false;              
    v_rst  VARCHAR2(500) ;              
    v_lettprt   VARCHAR2(5);              
Begin                 
    v_err_message := null;                 
              
    BEGIN              
        select count(*) into cnt_x1              
        from nc_payee c              
        where  c.clm_no = v_clm_no and c.pay_no = v_pay_no ;              
    EXCEPTION              
        WHEN NO_DATA_FOUND THEN              
            cnt_x1 := 0 ;              
        WHEN OTHERS THEN              
            cnt_x1 := 0;              
    END;               
                  
    IF cnt_x1 = 0 THEN              
        v_err_message := 'not convert!!  wait for NC_Payee Data ';              
        nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: count nc_payee ' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' || '|| v_err_message ,'not found' ,v_rst) ;              
        return ;                   
    END IF;              
              
    BEGIN              
        select count(*) into cnt_x1              
        from nc_payment a ,nc_payment_info b ,nc_payee c              
        where  a.clm_no = v_clm_no and a.pay_no = v_pay_no              
--        and a.trn_seq = v_trn_seq               
        and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no)               
        and a.pay_no = b.pay_no(+) and a.pay_no = c.pay_no(+)              
        and a.trn_seq = b.trn_seq(+) and a.trn_seq = c.trn_seq(+)              
        and nvl(c.payee_seq,1) = 1  ;              
    EXCEPTION              
        WHEN NO_DATA_FOUND THEN              
            cnt_x1 := 0 ;              
        WHEN OTHERS THEN              
            cnt_x1 := 0;              
    END;                  
    v_pay_amt :=0 ;              
    v_total_pay_total :=0 ;              
    v_deduct_total :=0 ;              
    v_total_deduct_total :=0 ;              
    v_paysts := '0';              
                  
    FOR X1 IN                
    (                 
    select a.CLM_NO, a.PAY_NO, a.trn_seq CORR_SEQ,a.amd_date CORR_DATE, '0' PAY_STS,               
    a.pay_amt PAY_AMT, P_CONVERT_PAYMENT.CONVERT_PAYMENT_METHOD(c.SETTLE) SETTLE, a.CLM_MEN ,a.AMD_USER ,a.STS_DATE ,a.AMD_DATE, a.SETTLE_DATE ,              
    a.status PAY_TYPE, 'Y' PRT_FLAG, b.REMARK, a.CURR_CODE PAY_CURR_CODE, a.CURR_RATE PAY_CURR_RATE,               
    a.TOT_PAY_AMT TOTAL_PAY_TOTAL,'0' STATE_FLAG,'' VAT_PERCENT,               
    0 DEDUCT_AMT,a.sts_date REC_PAY_DATE,B.PRINT_BATCH   ,              
    p_non_pa_approve.get_type(a.PROD_GRP,a.OFFSET_FLAG,a.TYPE, a.SUB_TYPE ,prem_code) convert_type,              
    a.SUB_TYPE , b.part ,a.offset_flag ,              
    '' convert_pay_type  ,a.type RAWTYPE --,p_non_pa_approve.get_clmsts(a.STATUS) CLMSTS              
    ,B.INVOICE_NO, B.REF_NO              
    from nc_payment a ,nc_payment_info b ,nc_payee c              
    where  a.clm_no = v_clm_no and a.pay_no = v_pay_no              
--    and a.trn_seq = v_trn_seq               
    and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no)                   
    and a.pay_no = b.pay_no(+) and a.pay_no = c.pay_no(+)              
    and a.trn_seq = b.trn_seq(+) and a.trn_seq = c.trn_seq(+)              
    and nvl(c.payee_seq,1) = 1                
    )               
    LOOP               
        rec_x1 := rec_x1+1;              
        v_clmsts := p_non_pa_approve.get_clmsts(x1.clm_no) ;              
        v_paytype := p_non_pa_approve.get_paytype(x1.PAY_TYPE) ;              
        if  P_CONVERT_PAYMENT.GET_CNT_LINEFEED(substr(x1.part,1,10000)) > 12 then              
            v_prt_flag := 'Y';              
            v_attached := 'ตามรายละเอียดที่แนบ' ;              
        else              
            v_prt_flag := 'N';              
            v_attached := '';              
        end if;              
--        v_part :=  substr(x1.part,1,10000);              
--        v_part := replace(v_part,chr(10),chr(13));              
        v_part := P_CONVERT_PAYMENT.FIX_LINEFEED(substr(x1.part,1,10000)) ;              
        v_remark := P_CONVERT_PAYMENT.FIX_LINEFEED(x1.remark) ;              
                      
        -- === insert Recovery              
        if X1.RAWTYPE like 'NCNATTYPEREC%' and X1.OFFSET_FLAG is null  then              
            v_pay_amt := v_pay_amt + X1.PAY_AMT;               
            v_total_pay_total := v_total_pay_total + X1.TOTAL_PAY_TOTAL;                
            if x1.sub_type like 'NCNATSUBTYPEREC%' then               
                v_paysts := '1';              
            elsif x1.sub_type like 'NCNATSUBTYPESAL%' then               
                v_paysts := '2';              
            elsif x1.sub_type like 'NCNATSUBTYPEDED%' then               
                v_paysts := '3';              
            end if;                                  
        else              
            IF X1.SUB_TYPE like 'NCNATSUBTYPECLM%' THEN              
                v_pay_amt := v_pay_amt + X1.PAY_AMT;               
                v_total_pay_total := v_total_pay_total + X1.TOTAL_PAY_TOTAL;              
            ELSIF X1.SUB_TYPE like 'NCNATSUBTYPEDED%' THEN              
                v_deduct_total := v_deduct_total + X1.PAY_AMT;               
                v_total_deduct_total := v_total_deduct_total + X1.TOTAL_PAY_TOTAL;              
            END IF;                 
            v_paysts := '0';                   
        end if;              
              
        --        v_pay_sts  :=  X1.pay_sts;              
        --        v_curr_code1 := X1.PAY_CURR_CODE;              
        --        v_curr_rate1 := X1.PAY_CURR_RATE;              
        --        v_clm_men := X1.clm_men;              
        --        v_amd_user := X1.amd_user;              
        --        v_pay_amt := X1.PAY_AMT;              
        --        v_sts_date:= X1.sts_date;              
        --        v_amd_date := X1.amd_date;              
        --        v_settle_date := X1.settle_date;              
        FOR Y1 in (              
            select close_date ,reopen_date              
            from nc_mas              
            where clm_no = v_clm_no              
        )LOOP              
            IF v_clmsts in ('2','3') THEN              
                v_closedate := X1.CORR_DATE ;              
                v_reopendate    := Y1.REOPEN_DATE ;              
            ELSIF v_clmsts = '4' THEN              
                v_closedate :=  Y1.CLOSE_DATE ;              
                v_reopendate    := X1.CORR_DATE;                       
            ELSIF v_clmsts in ('6','7') THEN                    
                v_closedate :=  null ;              
                v_reopendate    := Y1.REOPEN_DATE;                           
            END IF;                
        END LOOP;                    
              
        --        dbms_output.put_line('convert_pay_type='||X1.convert_pay_type);              
        if rec_x1 = cnt_x1 then -- last row              
            Begin              
            Insert into ALLCLM.MIS_CLM_PAID              
               (CLM_NO, PAY_NO, PAY_STS,  SETTLE, PART, ATTACHED ,              
                PAY_TYPE, PRT_FLAG, REMARK, PAY_CURR_CODE, PAY_CURR_RATE,               
                PAY_TOTAL ,TOTAL_PAY_TOTAL, CORR_SEQ, CORR_DATE, STATE_FLAG, VAT_PERCENT,               
                DEDUCT_AMT, TOT_DEDUCT_AMT , REC_PAY_DATE, PRINT_BATCH ,              
                INVOICE_NO ,JOB_NO)              
             Values              
               (x1.CLM_NO, x1.PAY_NO, v_paysts , x1.SETTLE, v_part ,v_attached ,              
                v_paytype, v_prt_flag , v_remark, x1.PAY_CURR_CODE, x1.PAY_CURR_RATE,               
                v_pay_amt , v_total_pay_total , x1.CORR_SEQ, x1.CORR_DATE, x1.STATE_FLAG, x1.VAT_PERCENT,               
                v_deduct_total , v_total_deduct_total , x1.REC_PAY_DATE, x1.PRINT_BATCH ,              
                x1.INVOICE_NO ,x1.REF_NO );              
                dbms_output.put_line('convert mis_clm_paid: '||x1.CLM_NO);              
            exception                 
            when  OTHERS  then                 
                 v_err_message := 'MIS_CLM_PAID : '||sqlerrm;                 
                 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: insert MIS_CLM_PAID ' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' || '|| v_err_message ,'error' ,v_rst) ;              
                 rollback;                
                 return ;                
            End;                
        end if;              
    End loop;                 
              
                 
--   v_paysts := '0';                
   Begin              
     FOR X2 IN               
     (               
        SELECT CLM_NO, PAY_NO, '0' PAY_STS, RI_CODE, RI_BR_CODE,               
        RI_TYPE, RI_PAY_AMT PAY_AMT, LETT_NO,  LETT_PRT, LETT_TYPE,               
        TRN_SEQ CORR_SEQ, RI_LF_FLAG, RI_SUB_TYPE  ,TYPE                
       FROM NC_RI_PAID  A              
       WHERE A.CLM_NO = v_clm_no               
       AND A.PAY_NO =v_pay_no              
--       AND A.TRN_SEQ = v_trn_seq               
       and a.trn_seq in (select max(aa.trn_seq) from NC_RI_PAID aa where -- AA.TYPE LIKE 'NCNATTYPECLM%' and               
       aa.clm_no =a.clm_no and aa.pay_no = a.pay_no)               
       --       AND A.TYPE LIKE 'NCNATTYPECLM%'              
      )              
      Loop              
        if X2.LETT_NO is not null then              
            v_lettprt := 'Y' ;              
        else              
             v_lettprt := 'N' ;              
        end if;              
                      
        Begin              
            Insert into ALLCLM.MIS_CRI_PAID                                                                  
               (CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE,               
                RI_TYPE, PAY_AMT, LETT_NO, LETT_PRT, LETT_TYPE,               
                CORR_SEQ, LF_FLAG, RI_SUB_TYPE)              
             Values              
               (X2.CLM_NO, X2.PAY_NO, v_paysts , X2.RI_CODE, X2.RI_BR_CODE,               
                X2.RI_TYPE, X2.PAY_AMT, X2.LETT_NO, v_lettprt, X2.LETT_TYPE,               
                X2.CORR_SEQ, X2.RI_LF_FLAG, X2.RI_SUB_TYPE );                    
             dbms_output.put_line('convert mis_cri_paid: '||x2.CLM_NO);                     
        exception                 
        when  OTHERS  then                 
                 v_err_message := 'MIS_CRI_PAID : '||sqlerrm;                 
                 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: insert MIS_CRI_PAID ' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' || '|| v_err_message ,'error' ,v_rst) ;              
                 rollback;                 
                 return ;                
        End;              
      End Loop;              
                    
    End;                
              
              
    cms_pay_amt := 0;              
    cms_tot_pay_amt := 0;              
    cms_deduct_amt := 0;              
    cms_tot_deduct_amt := 0;              
    cms_salvage_amt := 0;              
    cms_tot_salvage_amt := 0;                
    v_chkpaysts0 := false;                  
   Begin              
     FOR X4 IN               
     (               
        select A.CLM_NO ,A.PAY_NO , '0'  PAY_STS ,nvl(a.CLM_SEQ,1) SECTN, x.cause_code RISK_CODE  ,nvl(a.CLM_SEQ,1)  CLM_SEQ,               
            a.PREM_CODE,p_non_pa_approve.get_type(a.PROD_GRP,a.OFFSET_FLAG,a.TYPE, a.SUB_TYPE ,prem_code) TYPE, a.TRN_SEQ CORR_SEQ, a.PAY_AMT PAY_AMT, 0 DEDUCT_AMT,               
            a.TOT_PAY_AMT TOTAL_PAY_AMT ,a.sub_type ,a.OFFSET_FLAG ,A.STS_DATE ,A.AMD_DATE ,A.STATUS ,a.type RAWTYPE              
        from nc_mas x , nc_payment a               
        where a.clm_no = x.clm_no and  a.clm_no = v_clm_no and a.pay_no =v_pay_no              
--        and a.trn_seq = v_trn_seq               
        and a.trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.type<>'01' and aa.clm_no =a.clm_no and aa.pay_no = a.pay_no)              
      )              
      Loop              
                    
--        if     x4.sub_type in ('NCNATSUBTYPECLM001')  then                 
--             if      x4.prem_code = '1010' then                 
--                     v_type := '01';                 
--             elsif  x4.prem_code in  ('1020','1030','1040','1560')  then                 
--                     v_type := '02';                 
--             elsif  x4.prem_code in  ('1050')  then                 
--                     v_type := '03';                 
--             else                 
--                     v_type := '04';                 
--             end if;                 
--        elsif x4.sub_type in ('NCNATSUBTYPECLM002')  then                 
--             v_type := '05';                 
--        elsif x4.sub_type in ('NCNATSUBTYPECLM003')  then                 
--             v_type := '06';                 
--        elsif x4.sub_type in ('NCNATSUBTYPECLM004')  then                 
--             v_type := '25';                 
--        elsif x4.sub_type in ('NCNATSUBTYPECLM005','NCNATSUBTYPECLM006')  then                 
--             v_type := '04';                 
--        elsif x4.sub_type in ('NCNATSUBTYPECLM010','NCNATSUBTYPECLM011','NCNATSUBTYPECLM012')  then                 
--             v_type := '07';                 
--        elsif x4.sub_type in ('NCNATSUBTYPECLM018')  then         
--             v_type := '08';         
--        elsif x4.sub_type in ('NCNATSUBTYPECLM019')  then         
--             v_type := '36';                    
--        elsif x4.sub_type in ('NCNATSUBTYPECLM013','NCNATSUBTYPECLM014','NCNATSUBTYPECLM015','NCNATSUBTYPECLM016','NCNATSUBTYPECLM017')  then                 
--             v_type := '09';                 
--        elsif x4.sub_type like 'NCNATSUBTYPEDED%' then              
--            v_type := '26';                 
--        elsif x4.sub_type like 'NCNATSUBTYPESAL%' then              
--            v_type := '27';                 
--        else                 
--             v_type := '00';                 
--        end if;                 
--              
        v_type := p_convert_payment.get_cms_type(x4.sub_type ,x4.prem_code );
        
        cms_pay_amt := 0;              
        cms_tot_pay_amt := 0;              
        cms_deduct_amt := 0;              
        cms_tot_deduct_amt := 0;              
        cms_salvage_amt := 0;              
        cms_tot_salvage_amt := 0;                
                         
        -- === insert MIS_REC_MAS_SEQ              
        if x4.RAWTYPE like 'NCNATTYPEREC%' and x4.OFFSET_FLAG is null  then              
            dbms_output.put_line('found recov ');              
            if x4.sub_type like 'NCNATSUBTYPEREC%' then               
                v_rectype := '1';              
                v_paysts := '1';              
            elsif x4.sub_type like 'NCNATSUBTYPESAL%' then               
                v_rectype := '2';              
                v_paysts := '2';              
            elsif x4.sub_type like 'NCNATSUBTYPEDED%' then               
                v_rectype := '3';              
                v_paysts := '3';              
            end if;              
                          
            if x4.STATUS = 'NCPAYMENTSTS02' then              
                v_rec_closedate := X4.amd_date;              
                v_rec_sts := '2';              
            else              
                v_rec_closedate := null;              
                v_rec_sts := '1';              
            end if;              
              
            BEGIN              
                select max(corr_seq)+1 into v_rec_maxseq              
                from MIS_REC_MAS_SEQ a              
                where  a.clm_no = x4.clm_no ;              
            EXCEPTION              
                WHEN NO_DATA_FOUND THEN              
                    v_rec_maxseq := 0 ;              
                WHEN OTHERS THEN              
                    v_rec_maxseq := 0;              
            END;                  
              
            BEGIN              
                select tot_res_rec into o_res_rec              
                from MIS_REC_MAS_SEQ a              
                where clm_no =  x4.clm_no              
                and corr_seq in (select max(aa.corr_seq) from MIS_REC_MAS_SEQ aa where aa.clm_no = a.clm_no)              
                ;              
            EXCEPTION              
                WHEN NO_DATA_FOUND THEN              
                    o_res_rec := 0 ;              
                WHEN OTHERS THEN              
                    o_res_rec := 0;              
            END;                              
              
            Begin              
                Insert into ALLCLM.MIS_REC_MAS_SEQ              
                   (CLM_NO, REC_TYPE, CORR_SEQ, CORR_DATE, REC_DATE, REC_STS ,TOT_REC_REC ,TOT_RES_REC, OFFSET ,CLOSE_DATE)              
                 Values              
                   (x4.clm_no,v_rectype , v_rec_maxseq , x4.amd_date, x4.sts_date ,               
                    v_rec_sts , x4.pay_amt, o_res_rec , '2' ,v_rec_closedate);               
                 dbms_output.put_line('convert MIS_REC_MAS_SEQ: '||x4.CLM_NO);                     
            exception                 
            when  OTHERS  then                 
                     v_err_message := 'MIS_REC_MAS_SEQ : '||sqlerrm;              
                     nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: insert MIS_REC_MAS_SEQ ' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' || '|| v_err_message ,'error' ,v_rst) ;                 
                     rollback;                 
                     return ;                
            End;                          
              
            v_rec_cnt := v_rec_cnt+1;                          
            if v_rec_cnt = 1 then -- do it only one time              
                FOR xx4 in (              
                    select CLM_NO, REC_NO, ITEM_SEQ, REC_SEQ, REC_TYPE, REC_KIND, AMT              
                    from MIS_RECOVERY a              
                    where clm_no = X4.clm_no                  
                    and rec_seq in (select max(aa.rec_seq) from mis_recovery aa where aa.clm_no = a.clm_no)                  
                ) LOOP              
                    Begin              
                        Insert into ALLCLM.MIS_RECOVERY              
                           (CLM_NO, REC_NO, ITEM_SEQ, REC_SEQ, REC_TYPE, REC_KIND, AMT)              
                         Values              
                           (x4.clm_no ,x4.pay_no , xx4.item_seq , xx4.rec_seq+1 , v_rectype ,               
                            '1' ,x4.pay_amt );               
                         dbms_output.put_line('convert MIS_RECOVERY: '||xx4.CLM_NO);                     
                    exception                 
                    when  OTHERS  then                 
                             v_err_message := 'MIS_RECOVERY : '||sqlerrm;                
                             nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: insert MIS_RECOVERY' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' || '|| v_err_message ,'error' ,v_rst) ;               
                             rollback;                 
                             return ;                
                    End;                                           
                END LOOP ; --xx4              
            end if;              
            cms_pay_amt := cms_pay_amt + x4.PAY_AMT;              
            cms_tot_pay_amt := cms_tot_pay_amt + x4.TOTAL_PAY_AMT;                          
            --v_paysts :='3';              
        else              
            if X4.sub_type like  'NCNATSUBTYPECLM%' then              
                cms_pay_amt := cms_pay_amt + x4.PAY_AMT;              
                cms_tot_pay_amt := cms_tot_pay_amt + x4.TOTAL_PAY_AMT;              
            elsif X4.sub_type like  'NCNATSUBTYPESAL%' then              
                cms_salvage_amt := cms_salvage_amt + x4.PAY_AMT;              
                cms_tot_salvage_amt := cms_tot_salvage_amt + x4.TOTAL_PAY_AMT;              
            elsif X4.sub_type like  'NCNATSUBTYPEDED%' then              
                cms_deduct_amt := cms_deduct_amt + x4.PAY_AMT;              
                cms_tot_deduct_amt := cms_tot_deduct_amt + x4.TOTAL_PAY_AMT;              
            end if;                      
            v_paysts :='0';              
            v_chkpaysts0 := true;              
        end if;                    
        --=== End insert MIS_REC_MAS_SEQ              
                                  
        Begin              
            Insert into ALLCLM.MIS_CMS_PAID              
               (CLM_NO, PAY_NO, PAY_STS, SECTN, RISK_CODE, CLM_SEQ ,              
                PREM_CODE, TYPE, CORR_SEQ, PAY_AMT, TOTAL_PAY_AMT ,                              
                DEDUCT_AMT, TOT_DEDUCT_AMT ,              
                SALVAGE_AMT , TOT_SALVAGE_AMT               
                )              
             Values              
               (x4.CLM_NO, x4.PAY_NO, v_paysts , x4.SECTN, x4.RISK_CODE, x4.CLM_SEQ ,              
                x4.PREM_CODE, V_TYPE , x4.CORR_SEQ,  cms_pay_amt , cms_tot_pay_amt,               
                cms_deduct_amt ,cms_tot_deduct_amt ,              
                cms_salvage_amt ,cms_tot_salvage_amt              
                );                    
             dbms_output.put_line('convert mis_cms_paid: '||x4.CLM_NO);                     
        exception                 
        when  OTHERS  then                 
                 v_err_message := 'MIS_CMS_PAID : '||sqlerrm;              
                 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: insert MIS_CMS_PAID' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' || '|| v_err_message ,'error' ,v_rst) ;                 
                 rollback;                 
                 return ;                
        End;              
      End Loop;              
                    
    End;                
              
    v_offset1 := null;              
    v_offset2 := null;              
    BEGIN              
    FOR X3 IN (              
        SELECT CLM_NO, PAY_NO, '0' PAY_STS,TRN_SEQ, AMD_DATE, PAYEE_TYPE,               
            PAYEE_CODE, PAYEE_SEQ PAY_SEQ , PAYEE_NAME, PAYEE_AMT, P_CONVERT_PAYMENT.CONVERT_PAYMENT_METHOD(SETTLE) SETTLE, SEND_TITLE,               
            SEND_ADDR1, SEND_ADDR2 ,ACC_NO ,ACC_NAME ,BANK_CODE ,BANK_BR_CODE ,BR_NAME ,              
            SALVAGE_FLAG ,DEDUCT_FLAG ,SALVAGE_AMT ,DEDUCT_AMT ,CURR_CODE              
        FROM NC_PAYEE A               
       WHERE A.CLM_NO = v_clm_no               
       AND A.PAY_NO =v_pay_no              
--       AND A.TRN_SEQ = v_trn_seq               
       AND a.trn_seq in (select max(aa.trn_seq) from NC_PAYEE aa where aa.clm_no =a.clm_no and aa.pay_no = a.pay_no)               
    )LOOP               
        v_offset2 := null;              
        v_offset1 := null;              
        IF x3.DEDUCT_FLAG = '1' THEN -- offset หัก              
            v_offset2 := 'P' ;                  
        ELSIF x3.DEDUCT_FLAG = '2' THEN -- post นำส่ง              
            v_offset2 := 'M' ;                  
        END IF;              
              
        IF x3.SALVAGE_FLAG = '1' THEN -- offset หัก              
            v_offset1 := 'P' ;                  
        ELSIF x3.SALVAGE_FLAG = '2' THEN -- post นำส่ง              
            v_offset1 := 'M' ;                  
        END IF;              
                      
        begin                     
          select thai_brn_name into v_brname              
             from bank_branch              
             where bank_code =  X3.BANK_CODE  and branch_code = X3.BANK_BR_CODE ;              
        exception                 
        when no_data_found then               
            v_brname := null;              
        when  OTHERS  then                 
            v_brname := null;              
        End;              
                                                           
        dbms_output.put_line('convert mis_clm_payee: '||x3.CLM_NO||' paye_code='||X3.PAYEE_CODE||' PaySeq='|| X3.PAY_SEQ);                 
        Begin              
            if X3.pay_seq=1 then -- update account data for MIS_CLM_PAID              
                UPDATE MIS_CLM_PAID              
                SET acc_no = X3.ACC_NO ,bank_code = X3.BANK_CODE ,bank_br_code = X3.BANK_BR_CODE              
                WHERE CLM_NO = X3.CLM_NO              
                and PAY_NO = X3.PAY_NO              
                and corr_seq = X3.TRN_SEQ ;              
            end if;              
                      
            Insert into MISC.MIS_CLM_PAYEE              
               (CLM_NO, PAY_NO, PAY_STS, PAY_SEQ, PAYEE_TYPE,               
                PAYEE_CODE , PAYEE_NAME, PAYEE_AMT, SETTLE, SEND_TITLE,               
                SEND_ADDR1, SEND_ADDR2                
                ,ACC_NO ,ACC_NAME ,BANK_CODE ,BANK_BR_CODE ,BR_NAME              
                ,CORR_SEQ ,CORR_DATE,              
                PAYEE_OFFSET ,PAYEE_OFFSET2 ,SALVAGE_AMT ,DEDUCT_AMT ,CURR_CODE)              
             Values              
               (X3.CLM_NO, X3.PAY_NO, v_paysts , X3.PAY_SEQ, X3.PAYEE_TYPE,               
                X3.PAYEE_CODE , X3.PAYEE_NAME, X3.PAYEE_AMT, X3.SETTLE, X3.SEND_TITLE,               
                X3.SEND_ADDR1, X3.SEND_ADDR2 ,X3.ACC_NO ,X3.ACC_NAME ,X3.BANK_CODE ,X3.BANK_BR_CODE ,v_brname              
                ,X3.TRN_SEQ ,X3.AMD_DATE,              
--                ,3 ,sysdate,              
                v_offset1 ,v_offset2 ,X3.SALVAGE_AMT ,X3.DEDUCT_AMT ,X3.CURR_CODE              
               );              
             dbms_output.put_line('convert mis_clm_payee: '||x3.CLM_NO||' paye_code='||X3.PAYEE_CODE);                     
        exception                 
        when  OTHERS  then                 
                 v_err_message := 'MIS_CLM_PAYEE : '||sqlerrm;              
                 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: insert MIS_CLM_PAYEE' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' || '|| v_err_message ,'error' ,v_rst) ;                 
                 rollback;                 
                 return ;                
        End;              
    End Loop;              
               
    END;              
                  
   Begin              
              
        begin              
            select sum(pay_total) into v_totpaid              
            from mis_clm_paid a              
            where clm_no = v_clm_no               
            and corr_seq in (select max(aa.corr_seq) from mis_clm_paid aa where aa.clm_no=a.clm_no --and state_flag = '1'              
            );                      
        exception              
        when no_data_found then              
            v_totpaid := 0;              
        when others then              
        dbms_output.put_line('error'||sqlerrm);              
            v_totpaid :=0;              
        end;                  
                  
    P_CONVERT_PAYMENT.GET_SALVAGE_DEDUCT_RECOV_FLAG(v_clm_no ,v_pay_no ,o_salvage  ,o_deduct  ,o_recov)  ;              
     FOR X5 IN               
     (               
        select clm_no ,pol_no ,pol_run ,corr_seq ,channel ,prod_grp ,prod_type ,clm_date ,tot_res ,close_date ,reopen_date ,clm_sts              
        from mis_clm_mas_seq a              
        where clm_no = v_clm_no              
        and corr_seq in (select max(aa.corr_Seq) from mis_clm_mas_seq aa where aa.clm_no = a.clm_no)                  
      )              
      Loop              
--        if v_paysts = '0' then -- update only paid               
        if v_chkpaysts0 then  -- update when has paid               
            Begin              
                Insert into ALLCLM.MIS_CLM_MAS_SEQ              
                   (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE,               
                    CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE, TOT_RES,               
                    TOT_PAID, CLM_STS ,              
                     CLOSE_DATE ,REOPEN_DATE)              
                 Values              
                   (x5.CLM_NO, x5.POL_NO, x5.POL_RUN, x5.CORR_SEQ+1, sysdate,               
                    x5.CHANNEL, x5.PROD_GRP, x5.PROD_TYPE, x5.CLM_DATE, x5.TOT_RES,               
                    v_totpaid, V_CLMSTS,              
                    V_CLOSEDATE ,V_REOPENDATE);               
    --             dbms_output.put_line('convert mis_clm_mas_seq: '||x5.CLM_NO||' seq=' || x5.CORR_SEQ+1);               
                 dbms_output.put_line('convert mis_clm_mas_seq: '||x5.CLM_NO||' STS=' || V_CLMSTS);               
                               
                 update allclm.MIS_CLM_MAS              
                 set tot_paid = v_totpaid              
                 ,clm_sts = V_CLMSTS ,CLOSE_DATE = V_CLOSEDATE ,REOPEN_DATE = V_REOPENDATE              
                 ,deduct_rec_flag =o_deduct ,salvage_rec_flag =o_salvage ,recovery_rec_flag =o_recov              
                 where  clm_no = v_clm_no ;                   
                 dbms_output.put_line('convert mis_clm_mas: '||x5.CLM_NO);               
            exception                 
            when  OTHERS  then                 
                     v_err_message := 'MIS_CLM_MAS_SEQ : '||sqlerrm;              
                     nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: MIS_CLM_MAS' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' || '|| v_err_message ,'error' ,v_rst) ;                 
                     rollback;                 
                     return ;                
            End;              
        end if;              
      End Loop;              
    End;                    
                  
    if v_err_message is null then              
        nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','CONV_INSERT_MISC_TABLE' ,'step: commit ' ,'v_clm_no:'||v_clm_no||' v_pay_no:'||v_pay_no||' ::convert success' ,'success' ,v_rst) ;              
        COMMIT;   -- last commit               
    else              
        ROLLBACK;              
    end if;              
              
End CONV_INSERT_MISC_TABLE;               
                 
FUNCTION CONVERT_PAYMENT_METHOD(inPaidType IN VARCHAR2)  RETURN VARCHAR2 IS                
    v_return  varchar2(2);                
BEGIN                
    begin                
        select remark  into v_return                
        from clm_constant                
        where key like 'PAIDTYPE%'                
--        and key = 'PAIDTYPE'||inPaidType                
        and  remark2 = inPaidType;                
    exception                
        when no_data_found then                
        v_return := inPaidType;                
        when others then                
        dbms_output.put_line('error'||sqlerrm);                
        v_return :=inPaidType;                
    end;                
    return v_return;                
END CONVERT_PAYMENT_METHOD;                
                
PROCEDURE GET_SALVAGE_DEDUCT_RECOV_FLAG(in_clm_no IN VARCHAR2 ,in_pay_no IN VARCHAR2                
,o_salvage  OUT VARCHAR2 ,o_deduct  OUT VARCHAR2 ,o_recov  OUT VARCHAR2) IS                
                
BEGIN                
    FOR X in (                
        select distinct(substr(sub_type,1,15)) sub_type                
        from nc_payment                
        where (sub_type like 'NCNATSUBTYPECLM%'                
        or sub_type like 'NCNATSUBTYPEDED%'                
        or sub_type like 'NCNATSUBTYPESAL%'                
        or sub_type like 'NCNATSUBTYPEREC%')                
        and clm_no = IN_CLM_NO                
        and pay_no = IN_PAY_NO                
        and trn_seq = (select max(z.trn_seq) from nc_payment z where                
                                             (sub_type like 'NCNATSUBTYPECLM%'                
                                             or sub_type like 'NCNATSUBTYPEDED%'                
                                             or sub_type like 'NCNATSUBTYPESAL%'                
                                             or sub_type like 'NCNATSUBTYPEREC%')                
                                             and clm_no = IN_CLM_NO                
                                             and pay_no = IN_PAY_NO))                
    LOOP                
        if x.sub_type = 'NCNATSUBTYPESAL' then                
           o_salvage := 'Y';                
        elsif x.sub_type = 'NCNATSUBTYPEDED' then                
           o_deduct := 'Y';                
        elsif x.sub_type = 'NCNATSUBTYPEREC' then                
           o_recov := 'Y';                
        end if;                
    END LOOP;                
                
END GET_SALVAGE_DEDUCT_RECOV_FLAG;                
                
FUNCTION GET_CNT_LINEFEED(in_txt VARCHAR2) RETURN NUMBER IS                
    cnt number:=0;                
    cntenter number:=0;                
BEGIN                
    for i in 1.. length( in_txt ) loop                
        cnt := cnt+1;                
        if substr(in_txt ,cnt,1) in ( chr(10)  ) then                
            cntenter := cntenter+1;                
        end if;                
--        dbms_output.put_line( substr(l_tmp ,cnt,1) );                
    end loop;                
    return cntenter;                
END GET_CNT_LINEFEED;                
                
FUNCTION FIX_LINEFEED(in_txt VARCHAR2) RETURN VARCHAR2 IS                
    x_tmp VARCHAR2(10000);                
BEGIN                
    x_tmp := substr(in_txt ,1,8000);                
    x_tmp := replace(x_tmp ,  chr(13) , chr(32) );                
    x_tmp := replace(x_tmp ,  chr(10) , chr(35) );                
                
    x_tmp := replace(x_tmp ,  chr(35) , chr(10) );                
    return x_tmp;                
END FIX_LINEFEED;                

FUNCTION GET_CMS_TYPE(In_subtype in varchar2 ,In_prem_code in varchar2) RETURN VARCHAR2 IS
    v_type varchar2(5);
BEGIN

    if     In_subtype in ('NCNATSUBTYPECLM001')  then      
        if      In_prem_code = '1010' then      
        v_type := '01';      
        elsif  In_prem_code in  ('1020')  then      
        v_type := '02';      
        elsif  In_prem_code in  ('1030')  then      
        v_type := '37';      
        elsif  In_prem_code in  ('1040')  then      
        v_type := '38';      
        elsif  In_prem_code in  ('1560')  then      
        v_type := '39';      
        elsif  In_prem_code in  ('1050')  then      
        v_type := '03';      
        else      
        v_type := '04';      
        end if;      
    elsif In_subtype in ('NCNATSUBTYPECLM002')  then      
        v_type := '05';      
    elsif In_subtype in ('NCNATSUBTYPECLM003')  then      
        v_type := '06';      
    elsif In_subtype in ('NCNATSUBTYPECLM004')  then      
        v_type := '25';      
    elsif In_subtype in ('NCNATSUBTYPECLM005')  then      
        v_type := '40';      
    elsif In_subtype in ('NCNATSUBTYPECLM006')  then      
        v_type := '41';      
    elsif In_subtype in ('NCNATSUBTYPECLM010') then      
        v_type := '07';      
    elsif In_subtype in ('NCNATSUBTYPECLM011')  then      
        v_type := '30';      
    elsif In_subtype in ('NCNATSUBTYPECLM012')  then      
        v_type := '31';      
    elsif In_subtype in ('NCNATSUBTYPECLM018')  then      
        v_type := '08';      
    elsif In_subtype in ('NCNATSUBTYPECLM019')  then      
        v_type := '36';      
    elsif In_subtype in ('NCNATSUBTYPECLM017')  then      
        v_type := '09';      
    elsif In_subtype in ('NCNATSUBTYPECLM013')  then      
        v_type := '32';      
    elsif In_subtype in ('NCNATSUBTYPECLM014')  then      
        v_type := '33';      
    elsif In_subtype in ('NCNATSUBTYPECLM015')  then      
        v_type := '34';      
    elsif In_subtype in ('NCNATSUBTYPECLM016')  then      
        v_type := '35';      
    elsif In_subtype in ('NCNATSUBTYPEDED002') then      
        v_type := '28';      
    elsif In_subtype in ('NCNATSUBTYPESAL003') then      
        v_type := '29';      
    else      
        v_type := '00';      
    end if;     

    return v_type;
END GET_CMS_TYPE;
                 
END P_CONVERT_PAYMENT;
/

