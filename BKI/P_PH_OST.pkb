CREATE OR REPLACE PACKAGE BODY P_PH_OST AS
/******************************************************************************
   NAME:       P_PH_OST
   PURPOSE:     For Manage Ost Claim Data
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/4/2017      2702       1. Created this package.
******************************************************************************/
    FUNCTION TEST   RETURN VARCHAR2 IS
    
    BEGIN
        return 'Hello';
    END TEST;
    
    FUNCTION CAN_OPEN_CLAIM(v_notno  IN VARCHAR2 ,o_RST OUT VARCHAR2) RETURN BOOLEAN IS
        dumm_clm    varchar2(20);
    BEGIN
        select clm_no into dumm_clm
        from nc_mas
        where out_clm_no = v_notno ;
        
        if dumm_clm is not null then
            o_RST := 'Not_No นี้เปิดเคลม ได้เลข :'||dumm_clm||' แล้ว';
            return false;
        end if;

        select clm_no into dumm_clm
        from mis_clm_mas
        where out_clm_no = v_notno;
        
        if dumm_clm is not null then
            o_RST := 'Not_No นี้เปิดเคลม ได้เลข :'||dumm_clm||' แล้ว บน bkiapp';
            return false;
        end if;        
        
    EXCEPTION
        WHEN no_data_found THEN
            return true;   
        WHEN Others THEN       
            return true;    
    END CAN_OPEN_CLAIM;
        
    PROCEDURE GET_OSTCLM(v_date IN DATE ,v_notno IN VARCHAR2 ,o_RST OUT VARCHAR2) IS
        v_rst   varchar2(250);
    BEGIN
        FOR x in (
            select distinct not_no
            from clm_outservice_log a
            where trunc(trn_date) = v_date
            and not_no like nvl(  v_notno ,'%' ) 
        )LOOP
            dbms_output.put_line('not_no:'||x.not_no);
            if not p_ph_ost.CAN_OPEN_CLAIM(x.not_no ,v_rst) then dbms_output.put_line(v_rst); 
            else
                p_ph_ost.OPEN_CLM(v_date ,x.not_no ,v_rst);
            end if;
            
        END LOOP; -- X
    EXCEPTION
        WHEN OTHERS THEN
            o_Rst := 'error: '||sqlerrm;
    END GET_OSTCLM;
    
    PROCEDURE OPEN_CLM(v_date IN DATE ,v_notno IN VARCHAR2 ,o_RST OUT VARCHAR2) IS
        v_POLNO varchar2(20);
        v_POLRUN    number;
    BEGIN
        FOR mas IN (
            select not_no ,revision ,batch_no ,bki_clm_no ,pol_no ,fleet_seq ,reg_date ,not_date ,doc_date ,ret_date
            ,cus_code ,cus_name , sub_seq ,fam_seq ,id_no ,title ,name ,surname ,eff_date ,exp_date ,plan ,clm_type ,type_clm 
            ,acc_date ,admit ,disc ,hosp_amt ,disc_amt ,benf_covr ,non_cover ,benf_paid 
            ,hosp_code ,hosp_name ,ill_name ,icd_10 ,icd10_2 ,icd10_3 ,clm_pstat ,indication,treatment ,remark ,clm_decline ,fax_clm
            ,pay_mode ,payee_name ,payee_addr1 ,payee_addr2 ,bank_code ,bank_br_code ,bank_acc_no 
            ,claim_status
            from clm_outservice_mas a
            where a.not_no = v_notno
            and revision in (select max(aa.revision) from clm_outservice_mas aa where aa.not_no = a.not_no and trunc(created_date) = v_date )        
        )LOOP
            p_acc_package.read_pol(mas.pol_no ,v_POLNO ,v_POLRUN);
            dbms_output.put_line('not_no:'||mas.not_no||' pol_no:'||v_POLNO||' pol_run:'||v_POLRUN||' fleet:'||mas.fleet_seq||' inure:'||mas.title||' '||mas.name||' '||mas.surname||' reg_date:'||mas.reg_date
            ||' not_date:'||mas.not_date||' ret_date:'||mas.ret_date||' clm_sts:'||mas.claim_status);
            
            
        END LOOP; --mas
    EXCEPTION
        WHEN OTHERS THEN
            o_Rst := 'error OPEN_CLM: '||sqlerrm;    
    END OPEN_CLM;
END P_PH_OST;
/
