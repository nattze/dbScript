CREATE OR REPLACE PACKAGE BODY ALLCLM.NC_HEALTH_PACKAGE IS

 PROCEDURE generate_email(v_from IN VARCHAR2 ,v_to IN VARCHAR2 ,v_subject IN VARCHAR2 ,v_body IN VARCHAR2 ,v_cc IN VARCHAR2 ,v_bcc IN VARCHAR2 ) IS
 BEGIN
 p_acc_package.SEND_EMAIL(v_from, rtrim(v_to,';') ,
 v_subject, 
 v_body 
 ,rtrim(v_cc,';')
 ,rtrim(v_bcc,';') ); 
 EXCEPTION
 WHEN OTHERS THEN
 null;
 END ; --generate_email
 
 PROCEDURE email_pack_error(v_subject IN VARCHAR2 , v_body IN VARCHAR2) IS
 v_to varchar2(1000);
 v_cc varchar2(1000);
 v_bcc varchar2(1000);
 v_from varchar2(50):= 'BKI_MED_ADMIN@bangkokinsurance.com' ; 
 v_dbins varchar2(10);
 x_body varchar2(1000);
 x_subject varchar2(1000);
 BEGIN
 FOR X in (
 select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail ,(select UPPER(substr(instance_name,1,8)) instance_name from v$instance) ins_name
 from nc_med_email a
 where module = 'PACK_LOG' 
 and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
 and direction = 'TO' and CANCEL is null 
 ) LOOP
 v_to := v_to || x.ldap_mail ||';' ;
 v_dbins := x.ins_name ; -- get DB Instant 
 END LOOP;
 
 FOR X2 in (
 select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail 
 from nc_med_email a
 where module = 'PACK_LOG' 
 and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
 and direction = 'CC' and CANCEL is null 
 ) LOOP
 v_cc := v_cc || x2.ldap_mail ||';' ;
 END LOOP; 

 FOR X3 in (
 select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail 
 from nc_med_email a
 where module = 'PACK_LOG' 
 and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
 and direction = 'BCC' and CANCEL is null 
 ) LOOP
 v_bcc := v_bcc || x3.ldap_mail ||';' ;
 END LOOP; 

 x_body := '<h2>'||v_subject||'</h2></br>'; 
 x_body := x_body||v_body; 
 x_subject := v_subject||' ['||v_dbins||'] ' ; 
 
 if v_to is not null then
 ALLCLM.nc_health_package.generate_email(v_from, v_to ,
 x_subject, 
 x_body 
 ,v_cc
 ,v_bcc); 
 end if;
 
 EXCEPTION
 WHEN OTHERS THEN
 null;
 END ; --email_pack_error 
 
 PROCEDURE email_notice_bancas(v_subject IN VARCHAR2 , v_body IN VARCHAR2) IS
 v_to varchar2(1000);
 v_cc varchar2(1000);
 v_bcc varchar2(1000);
 v_from varchar2(50):= 'BKI_MED_ADMIN@bangkokinsurance.com' ; 
 v_dbins varchar2(10);
 x_body varchar2(1000);
 x_subject varchar2(1000);
 v_logrst varchar2(200);
 BEGIN
 --ALLCLM.NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail Bancas' ,'Start: '||v_body ,v_logrst);
 FOR X in (
 select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail ,(select UPPER(substr(instance_name,1,8)) instance_name from v$instance) ins_name
 from nc_med_email a
 where module = 'BANCAS' 
 and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
 and direction = 'TO' and CANCEL is null 
 ) LOOP
 v_to := v_to || x.ldap_mail ||';' ;
 v_dbins := x.ins_name ; -- get DB Instant 
 END LOOP;
 
 FOR X2 in (
 select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail 
 from nc_med_email a
 where module = 'BANCAS' 
 and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
 and direction = 'CC' and CANCEL is null 
 ) LOOP
 v_cc := v_cc || x2.ldap_mail ||';' ;
 END LOOP; 

 FOR X3 in (
 select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail 
 from nc_med_email a
 where module = 'BANCAS' 
 and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)
 and direction = 'BCC' and CANCEL is null 
 ) LOOP
 v_bcc := v_bcc || x3.ldap_mail ||';' ;
 END LOOP; 

 x_body := '<h2>'||v_subject||'</h2></br>'; 
 x_body := x_body||v_body; 
 x_subject := v_subject||' ['||v_dbins||'] ' ; 
 
 if v_to is not null then
 ALLCLM.nc_health_package.generate_email(v_from, v_to ,
 x_subject, 
 x_body 
 ,v_cc
 ,v_bcc); 
 end if;
 --ALLCLM.NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail Bancas' ,'END' ,v_logrst);
 EXCEPTION
 WHEN OTHERS THEN
 ALLCLM.NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail Bancas' ,'Error: '||sqlerrm ,v_logrst);
 END ; --email_notice bancas 
 
 
 PROCEDURE list_med(P_MED OUT v_ref_cursor2) IS
 TYPE cur_typ IS REF CURSOR;
 c cur_typ;
 job VARCHAR2(20):='H0%'; 
 query_str VARCHAR2(1000);
 emp_name VARCHAR2(1000);
 emp_num VARCHAR2(10);
 BEGIN
 query_str := 'SELECT user_name , user_id FROM med_staff ' || ' WHERE user_id like :job_title '
 ||'order by USER_NAME ';
 -- find employees who perform the specified job
 
 OPEN P_MED FOR query_str USING job;
 --RETURN;

 END;

 PROCEDURE test_incursor(IN_C in v_ref_cursor1) IS
 BEGIN
 null;

 END;

 FUNCTION LIST_MED_HOSPITAL(P_HOSP OUT v_ref_cursor1) RETURN VARCHAR2 IS
 
 BEGIN
 
 OPEN P_HOSP FOR 
 select distinct hosp_id , name_t ,name_e
 from med_hospital_list 
 ;
 return 'Y';
 EXCEPTION
 WHEN OTHERS THEN 
 OPEN P_HOSP FOR 
 select '' hosp_id ,'' name_t ,'' name_e
 from dual ;
 return 'E';
 END;

 FUNCTION GET_BKI_HPTCODE(xCode IN VARCHAR2) RETURN VARCHAR2 IS
 vHpt_code varchar2(20);
 BEGIN
 begin
 select (select hosp_id from MED_HOSPITAL_LIST where payee_code = a.payee_code ) into vHpt_code
 from NC_HOSPITAL_MAPPING a
 where tpa_code = xCode and rownum=1;
 exception 
 when no_data_found then
 begin
 select hosp_id into vHpt_code
 from MED_HOSPITAL_LIST a
 where payee_code = xCode and rownum=1;
 exception 
 when no_data_found then
 begin
 select hosp_id into vHpt_code
 from MED_HOSPITAL_LIST a
 where user_id = xCode and rownum=1;
 exception 
 when no_data_found then
 vHpt_code := xCode ;
 when others then
 vHpt_code := xCode ;
 end; 
 when others then
 vHpt_code := xCode ;
 end;
 
 when others then
 begin 
 select MED_code into vHpt_code 
 from NC_HOSPITAL_MAPPING a 
 where tpa_code = xCode and rownum=1; 
 exception 
 when no_data_found then 
 vHpt_code := xCode ; 
 when others then 
 vHpt_code := xCode ; 
 end; 
 end;
 
 return vHpt_code;
 END; -- GET_BKI_HPTCODE
 
 PROCEDURE get_customer_name(vcust_code IN VARCHAR2 , vTH_ENG IN VARCHAR2 ,vTITLE OUT VARCHAR2 ,vNAME OUT VARCHAR2 ,vSURNAME OUT VARCHAR2 ) IS
 
 BEGIN
 
 select title ,substr(name,1, instr(name ,' ')-1 ) name1, ltrim(substr(name, instr(name ,' ') )) surname 
 into vTITLE ,vNAME ,vSurname
 from cust_name_std 
 where cus_code =vcust_code
 and th_eng = vTH_ENG ; 
 
 EXCEPTION
 WHEN NO_DATA_FOUND THEN
 vTITLE := null;
 vNAME := null;
 vSurname := null;
 WHEN OTHERS THEN
 vTITLE := null;
 vNAME := null;
 vSurname := null; 
 END;
 
 FUNCTION GET_BKI_FAXCLM(vKey IN NUMBER, P_CLM_MAS OUT v_ref_cursor1 ,P_CLM_DETAIL OUT v_ref_cursor2 ,
 RST OUT VARCHAR2) RETURN VARCHAR2 IS
 
 v_SID number(10);
 v_Tmp1 VARCHAR2(20);
 cnt NUMBER:=0; 
 v_title VARCHAR2(100); 
 v_name VARCHAR2(200); 
 v_surname VARCHAR2(200); 
 
 vPolType varchar2(10); 
 BEGIN

 FOR P1 in (
 select a.sts_key ,clm_no ,'' ost_clm_no ,pol_no , pol_run ,fleet_seq ,mas_cus_code ,mas_cus_name 
 ,cus_code ,'' title ,cus_name name ,'' surname , id_no idcard_no , hn_no ,invoice_no , loss_date ,loss_detail 
 ,dis_code icd_code ,tr_date_fr ,tr_date_to ,cause_code risk_code ,'00' status ,1 revision ,clm_date ,clm_user clm_user_code ,'' clm_user_name 
 ,hpt_code hospital_code ,'' hospital_name ,a.remark 
 from nc_mas a ,nc_status b
 where a.sts_key = B.STS_KEY 
 and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type='MEDSTS' )
 and a.sts_key = vKey
 and sts_sub_type = 'MEDSTS00'
 ) LOOP 
-- begin
-- select title ,name ,surname into v_title ,v_name ,v_surname
-- from cust_name_std
-- where cus_code = P1.cus_code
-- and th_eng = 'T' ; 
-- exception
-- when no_data_found then
-- v_title := '';
-- v_name := P1.name ;
-- v_surname := '';
-- when others then
-- v_title := '';
-- v_name := P1.name ;
-- v_surname := ''; 
-- end; 
-- get_customer_name(P1.cus_code , 'T' , v_title ,v_name , v_surname );
 begin
 select title , name ,surname
 into v_title ,v_name , v_surname
 from mis_pa_prem
 where pol_no =P1.pol_no and pol_run = P1.POL_RUN 
 and fleet_seq = P1.FLEET_SEQ 
 and END_SEQ = (SELECT MAX(END_SEQ) FROM mis_pa_prem
 WHERE POL_NO =P1.pol_no AND 
 nvl(pol_run,0) = P1.POL_RUN and fleet_seq = P1.FLEET_SEQ and
 (P1.LOSS_DATE BETWEEN FR_DATE AND TO_DATE))
 AND recpt_seq in (select min(x.recpt_seq) from mis_pa_prem x where x.pol_no=P1.pol_no and pol_run = P1.POL_RUN and fleet_seq= P1.FLEET_SEQ
 and (P1.LOSS_DATE BETWEEN FR_DATE AND TO_DATE)
 --and x.end_seq = vEND_SEQ
 and rownum=1
 ); 
 exception
 when no_data_found then
 v_title := null;
 v_name := null;
 v_surname := null;
 when others then
 v_title := null;
 v_name := null;
 v_surname := null;
 end; 
 END LOOP;

 begin 
 INSERT INTO NC_FAXDATA_MAS a
 (
 a.sts_key ,clm_no , ost_clm_no ,policyno ,fleet_seq ,mas_cus_code ,mas_cus_name 
 ,cus_code ,title , name , surname , idcard_no , hn_no ,invoice_no , loss_date ,loss_detail 
 , icd_code ,tr_date_fr ,tr_date_to , risk_code , status , revision ,clm_date , clm_user_code ,clm_user_name 
 , hospital_code , hospital_name ,corr_date ,remark
 ) --VALUES
 ( 
 select a.sts_key ,clm_no ,'' ost_clm_no ,pol_no||pol_run policyno ,fleet_seq ,mas_cus_code ,mas_cus_name 
 ,cus_code ,v_title title ,v_name name ,v_surname surname , nvl(id_no,'nothave') idcard_no , hn_no ,invoice_no ,to_char(loss_date,'rrrrmmdd') loss_date ,loss_detail 
 ,nvl(dis_code,'9999') icd_code ,to_char(tr_date_fr,'rrrrmmdd') tr_date_fr ,to_char(tr_date_to,'rrrrmmdd') tr_date_to ,cause_code risk_code ,'00' status ,1 revision ,to_char(clm_date,'rrrrmmdd') clm_date ,clm_user clm_user_code ,'' clm_user_name 
 ,nvl(hpt_code ,'9999') hospital_code ,GET_HOSPITAL_NAME(hpt_code ,'T') hospital_name ,sysdate ,a.remark
 from nc_mas a ,nc_status b
 where a.sts_key = B.STS_KEY 
 and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type='MEDSTS' )
 and a.sts_key = vKey
 and sts_sub_type = 'MEDSTS00'
 );
 exception
 when others then
 dbms_output.put_line('error insert NC_FAXDATA_MAS: '||sqlerrm);
 ROLLBACK;
 RST := 'error insert NC_FAXDATA_MAS: '||sqlerrm;
 return 'E'; 
 end; 

 begin 
 INSERT INTO NC_FAXDATA_DETAIL a
-- (
-- sts_key , clm_no ,ost_clm_no , bene_code ,descr 
-- , request_amt , reserve_amt , disc_amt , paid_amt ,revision ,corr_date
-- )VALUES
 ( 
 select sts_key , clm_no ,'' ost_clm_no ,prem_code bene_code ,ALLCLM.NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(prem_code ,'T') descr 
 ,req_amt request_amt ,res_amt reserve_amt , disc_amt ,0 paid_amt ,1 revision ,sysdate
 from nc_reserved
 where sts_key = vKey
 );
 exception
 when others then
 dbms_output.put_line('error insert NC_FAXDATA_DETAIL: '||sqlerrm);
 ROLLBACK;
 RST := 'error insert NC_FAXDATA_DETAIL: '||sqlerrm;
 return 'E'; 
 end; 
 
 if RST is null then -- Success 
 COMMIT;
 
 OPEN P_CLM_MAS FOR 
 SELECT A.STS_KEY, A.CLM_NO, A.OST_CLM_NO, A.POLICYNO, A.FLEET_SEQ, A.MAS_CUS_CODE, A.MAS_CUS_NAME, A.CUS_CODE, A.TITLE, A.NAME, A.SURNAME,
 A.IDCARD_NO, A.HN_NO, A.INVOICE_NO, A.LOSS_DATE, A.LOSS_DETAIL, A.ICD_CODE, A.TR_DATE_FR, A.TR_DATE_TO, A.RISK_CODE,
 A.STATUS, A.REVISION, A.CLM_DATE, A.CLM_USER_CODE, A.CLM_USER_NAME, A.HOSPITAL_CODE, A.HOSPITAL_NAME ,REMARK
 FROM NC_FAXDATA_MAS A WHERE A.STS_KEY = vKey 
 and revision in (select max(x.revision) from NC_FAXDATA_MAS x where x.sts_key = a.sts_key and trunc(x.corr_date) = trunc(sysdate) )
 and trunc(a.corr_date) = trunc(sysdate) 
 ;

 OPEN P_CLM_DETAIL FOR 
 SELECT A.STS_KEY, A.CLM_NO, A.OST_CLM_NO, A.BENE_CODE, A.DESCR,
 A.REQUEST_AMT, A.RESERVE_AMT, A.DISC_AMT, A.PAID_AMT, A.REVISION
 FROM NC_FAXDATA_DETAIL A WHERE A.STS_KEY = vKey 
 and revision in (select max(x.revision) from NC_FAXDATA_DETAIL x where x.sts_key = a.sts_key and trunc(x.corr_date) = trunc(sysdate) )
 and trunc(a.corr_date) = trunc(sysdate) 
 ; 
 
 return 'Y'; 
 else

 OPEN P_CLM_MAS FOR 
 select 0 STS_KEY , '' CLM_NO ,'' OST_CLM_NO ,'' POLICYNO ,0 FLEET_SEQ ,'' MAS_CUS_CODE , '' MAS_CUS_NAME ,
 '' CUS_CODE ,'' TITLE ,'' NAME ,'' SURNAME ,
 '' IDCARD_NO , '' HN_NO , '' INVOICE_NO , '' LOSS_DATE ,'' LOSS_DETAIL ,'' ICDS_CODE , '' TR_DATE_FR , '' TR_DATE_TO ,
 '' RISK_CODE , '' STATUS , 0 REVISION , '' CLM_DATE , '' CLM_USER_CODE , '' CLM_USER_NAME ,
 '' HOSPITAL_CODE , '' HOSPITAL_NAME , '' CORR_DATE ,'' REMARK
 from dual;
 OPEN P_CLM_DETAIL FOR 
 select 0 STS_KEY ,'' CLM_NO ,'' OST_CLM_NO ,'' BENE_CODE ,'' DESCR ,
 0 REQUEST_AMT ,0 RESERVE_AMT , 0 DISC_AMT ,0 PAID_AMT ,0 REVISION ,
 '' CORR_DATE 
 from dual; 
 RST := 'error in GET_BKI_FAXCLM :'||sqlerrm;
 return 'E'; 
 end if; 
 
 EXCEPTION
 WHEN OTHERS THEN
 ROLLBACK;
 OPEN P_CLM_MAS FOR 
 select 0 STS_KEY , '' CLM_NO ,'' OST_CLM_NO ,'' POLICYNO ,0 FLEET_SEQ ,'' MAS_CUS_CODE , '' MAS_CUS_NAME ,
 '' CUS_CODE ,'' TITLE ,'' NAME ,'' SURNAME ,
 '' IDCARD_NO , '' HN_NO , '' INVOICE_NO , '' LOSS_DATE ,'' LOSS_DETAIL ,'' ICDS_CODE , '' TR_DATE_FR , '' TR_DATE_TO ,
 '' RISK_CODE , '' STATUS , 0 REVISION , '' CLM_DATE , '' CLM_USER_CODE , '' CLM_USER_NAME ,
                  '' HOSPITAL_CODE ,  '' HOSPITAL_NAME , '' CORR_DATE  ,'' REMARK
                from dual;
            OPEN P_CLM_DETAIL FOR 
                select   0 STS_KEY ,'' CLM_NO ,'' OST_CLM_NO ,'' BENE_CODE ,'' DESCR ,
                  0 REQUEST_AMT ,0  RESERVE_AMT , 0 DISC_AMT ,0  PAID_AMT ,0 REVISION ,
                  '' CORR_DATE 
                from dual;   
            
        RST := 'error in GET_BKI_FAXCLM :'||sqlerrm;
        return 'E';
    END;         --END GET_BKI_FAXCLM 

  FUNCTION UPDATE_BKI_FAXCLM (vKey IN NUMBER ,BKI_CLMNO IN VARCHAR2  ,RST OUT VARCHAR2) RETURN VARCHAR2 IS
  
  BEGIN
          UPDATE NC_FAXDATA_MAS A 
          SET CLM_NO = BKI_CLMNO
          WHERE A.STS_KEY = vKey 
          and revision in (select max(x.revision) from NC_FAXDATA_MAS x where x.sts_key = a.sts_key );

          UPDATE NC_FAXDATA_DETAIL a
          SET CLM_NO = BKI_CLMNO
          WHERE A.STS_KEY = vKey 
          and revision in (select max(x.revision) from NC_FAXDATA_DETAIL x where x.sts_key = a.sts_key  )     ;     
          
          COMMIT;
          return 'Y'; 

  EXCEPTION 
  
    WHEN OTHERS THEN
        ROLLBACK;
        RST := 'error in UPDATE TPA FAX ostclmno :'||sqlerrm;
        return 'E';    
  END; -- UPDATE_BKI_FAXCLM   update BKI CLM_NO to TPA first CLM
    
  FUNCTION UPDATE_TPA_FAXCLM (vKey IN NUMBER ,OST_CLMNO IN VARCHAR2  ,RST OUT VARCHAR2) RETURN VARCHAR2 IS
  
  BEGIN
          UPDATE NC_FAXDATA_MAS A 
          SET OST_CLM_NO = OST_CLMNO
          WHERE A.STS_KEY = vKey 
          and revision in (select max(x.revision) from NC_FAXDATA_MAS x where x.sts_key = a.sts_key );

          UPDATE NC_FAXDATA_DETAIL a
          SET OST_CLM_NO = OST_CLMNO
          WHERE A.STS_KEY = vKey 
          and revision in (select max(x.revision) from NC_FAXDATA_DETAIL x where x.sts_key = a.sts_key  )     ;     
          
          COMMIT;
          return 'Y'; 

  EXCEPTION 
  
    WHEN OTHERS THEN
        ROLLBACK;
        RST := 'error in UPDATE TPA FAX ostclmno :'||sqlerrm;
        return 'E';    
  END; -- UPDATE_TPA_FAXCLM   OST CLMNo Update
                              
  FUNCTION UPDATE_TPA_FAXCLM (vKey IN NUMBER  ,RST OUT VARCHAR2) RETURN VARCHAR2 IS
    c3   NC_HEALTH_PACKAGE.v_ref_cursor3;
    TYPE t_data3 IS RECORD
    (
    STS_KEY    NUMBER,
    NOTICE_NO  NUMBER,
    CLM_NO NUMBER
    ); 
    j_rec3 t_data3;          

    P_MASTER   NC_HEALTH_PACKAGE.v_ref_cursor1;        
    P_DETAIL   NC_HEALTH_PACKAGE.v_ref_cursor2;    
            
    v_step1_rst varchar2(300);
    v_clmno varchar2(20);
    tmp_status  varchar2(20);
    send_status varchar2(20);
  BEGIN

        FOR P1 in (
        SELECT A.STS_KEY,  A.CLM_NO, A.OST_CLM_NO, A.POLICYNO, decode(A.FLEET_SEQ,0,1,A.FLEET_SEQ) FLEET_SEQ, A.MAS_CUS_CODE, A.MAS_CUS_NAME, A.CUS_CODE, A.TITLE,  A.NAME, A.SURNAME,
        A.IDCARD_NO, A.HN_NO, A.INVOICE_NO, A.LOSS_DATE, A.LOSS_DETAIL, A.ICD_CODE, A.TR_DATE_FR, A.TR_DATE_TO, A.RISK_CODE,
        A.STATUS, A.REVISION, A.CLM_DATE, nvl(A.CLM_USER_CODE,'BK002') CLM_USER_CODE, A.CLM_USER_NAME, A.HOSPITAL_CODE, A.HOSPITAL_NAME, A.CORR_DATE
        FROM NC_FAXDATA_MAS A WHERE A.STS_KEY = vKey 
        and revision in (select max(x.revision) from NC_FAXDATA_MAS x where x.sts_key = a.sts_key and trunc(x.corr_date) = trunc(sysdate) )
        and trunc(a.corr_date) = trunc(sysdate)
        ) LOOP        
            tmp_status := P1.STATUS ;
            v_CLMNO := P1.CLM_NO ;
--            INSERT INTO  NC_MASTER_TMP  A
--            (A.STS_KEY,       A.INVOICE,       A.CLM_TYPE,       A.POLICY_NO,       A.FLEET_SEQ,  A.RECPT_SEQ ,       A.NAME,       A.SURNAME,       A.HN,
--            A.ICD10,       A.CAUSE_CODE,       A.RISK_DESC,       A.LOSS_DATE,       A.FR_LOSS_DATE,       A.TO_LOSS_DATE,       A.HPT_CODE,       A.DAY,       A.HPT_USER
--            ,A.Remark  ,A.EVN_DESC  ) VALUES
--            (P1.STS_KEY ,P1.INVOICE_NO,       'I' ,       P1.POLICYNO,       P1.FLEET_SEQ,  null  ,       P1.NAME,       P1.SURNAME,       P1.HN_NO,
--            P1.ICD_CODE,       P1.RISK_CODE,       P1.LOSS_DETAIL,       to_date(P1.LOSS_DATE,'rrrrmmdd'),       to_date(P1.TR_DATE_FR,'rrrrmmdd') ,       to_date(P1.TR_DATE_TO,'rrrrmmdd') ,       P1.HOSPITAL_CODE,       to_number(P1.TR_DATE_TO - P1.TR_DATE_FR+1) ,       P1.CLM_USER_CODE
--            ,null  ,null
--            ) ;  
            dbms_output.put_line('FAX_MAS ==+ '||
            ' POLICY: '||P1.POLICYNO ||
            ' LOSS_DATE: '||P1.LOSS_DATE ||
            ' DAY: '||to_char( to_date(P1.TR_DATE_TO,'yyyymmdd') -  to_date(P1.TR_DATE_FR,'yyyymmdd') ));
            
        END LOOP;

        FOR P2 in (
        SELECT A.STS_KEY, A.CLM_NO, A.OST_CLM_NO, A.BENE_CODE, A.DESCR,
        A.REQUEST_AMT, A.RESERVE_AMT, A.DISC_AMT, A.PAID_AMT, A.REVISION, A.CORR_DATE
        FROM NC_FAXDATA_DETAIL A WHERE A.STS_KEY = vKey 
        and revision in (select max(x.revision) from NC_FAXDATA_DETAIL x where x.sts_key = a.sts_key and trunc(x.corr_date) = trunc(sysdate) )
        and trunc(a.corr_date) = trunc(sysdate)
        ) LOOP        
            
--            INSERT INTO  NC_DETAIL_TMP  B
--            ( STS_KEY ,B.PREMCODE, B.REQUEST_AMT, B.REMAIN_AMT
--            ) VALUES
--            ( P2.STS_KEY ,P2.BENE_CODE, P2.REQUEST_AMT, 0
--            ) ;  
            dbms_output.put_line('FAX_MAS ==+ '||
            ' PREMCODE: '||P2.BENE_CODE ||
            ' REQUEST_AMT: '||P2.REQUEST_AMT ||
            ' REMAIN_AMT: '||'');
            
        END LOOP;
          
--        COMMIT;

        OPEN P_MASTER FOR
        SELECT A.STS_KEY,   CLM_NO ,    INVOICE_NO INVOICE,       'I' CLM_TYPE,    A.POLICYNO POLICY_NO,      decode(A.FLEET_SEQ,0,1,A.FLEET_SEQ) FLEET_SEQ, RECPT_SEQ ,       A.NAME,       A.SURNAME,    A.HN_NO HN,
        A.ICD_CODE ICD10,        A.RISK_CODE CAUSE_CODE, LOSS_DETAIL RISK_DESC,  to_date(LOSS_DATE,'rrrrmmdd') LOSS_DATE,    to_date(TR_DATE_FR,'rrrrmmdd') FR_LOSS_DATE ,  to_date(TR_DATE_TO,'rrrrmmdd') TO_LOSS_DATE
        ,HOSPITAL_CODE HPT_CODE, to_number( to_date(TR_DATE_TO,'yyyymmdd') -  to_date(TR_DATE_FR,'yyyymmdd') )  xDAY, nvl(A.CLM_USER_CODE,'BK002') HPT_USER
        ,REMARK ,null  ,IDCARD_NO ,null ,null ,null ,null ,null
        FROM NC_FAXDATA_MAS A WHERE A.STS_KEY = vKey 
        and revision in (select max(x.revision) from NC_FAXDATA_MAS x where x.sts_key = a.sts_key and trunc(x.corr_date) = trunc(sysdate) )
        and trunc(a.corr_date) = trunc(sysdate)
        ;

--STS_KEY ,B.PREMCODE, B.REQUEST_AMT, B.REMAIN_AMT
        OPEN P_DETAIL FOR
        SELECT  A.BENE_CODE PREMCODE, 
        A.REQUEST_AMT, decode(A.PAID_AMT,0,A.RESERVE_AMT ,A.PAID_AMT)  REMAIN_AMT
        FROM NC_FAXDATA_DETAIL A WHERE A.STS_KEY = vKey 
        and revision in (select max(x.revision) from NC_FAXDATA_DETAIL x where x.sts_key = a.sts_key and trunc(x.corr_date) = trunc(sysdate) )
        and trunc(a.corr_date) = trunc(sysdate)
        ;  
        
        
        IF tmp_status in ('00','01') THEN
            send_status := 'MEDSTS00';  -- รับแจ้ง Fax Claim
        ELSIF tmp_status in ('10') THEN
            send_status := 'MEDSTS01';  -- ตรวจสอบเอกสาร (ส่วนแรก)
        ELSIF tmp_status in ('30') THEN
            send_status := 'MEDSTS02';  -- ปฏิเสธ Fax Claim
        ELSIF tmp_status in ('31') THEN
            send_status := 'MEDSTS31';  -- ปฏิเสธ จ่าย Fax Claim
        ELSIF tmp_status in ('40') THEN
            send_status := 'MEDSTS32';  -- ยกเลิก Fax Claim
        ELSIF tmp_status in ('20') THEN
            send_status := 'MEDSTS11';  -- อนุมัติจ่าย Fax Claim            
        ELSIF tmp_status in ('90') THEN  -- TPA send Final Claim
            send_status := 'MEDSTS14';  -- ตรวจสอบเอกสารวางบิล                     
        END IF;
        
         dbms_output.put_line('b4 start SAVE_UPDATE_CLAIM');
        SAVE_UPDATE_CLAIM(P_MASTER  ,P_DETAIL ,send_status,v_CLMNO , v_step1_rst) ;
                                    
        dbms_output.put_line('UPDATE TPA FAX==>'||v_step1_rst);

        if v_step1_rst is null then
            RST := '';
            return 'Y'; 
        else -- Save ไม่ผ่าน
            RST := 'UPDATE TPA FAX==>'||v_step1_rst;
            return 'N';         
        end if;            

  EXCEPTION 
    WHEN OTHERS THEN
        ROLLBACK;
        RST := 'error in UPDATE TPA FAX :'||sqlerrm;
        return 'E';  
  END; -- UPDATE_TPA_FAXCLM
  
  FUNCTION GET_TPA_FAXCLM (vKey IN NUMBER  ,RST OUT VARCHAR2) RETURN VARCHAR2 IS
    c3   NC_HEALTH_PACKAGE.v_ref_cursor3;
    TYPE t_data3 IS RECORD
    (
    STS_KEY    NUMBER,
    NOTICE_NO  NUMBER,
    CLM_NO NUMBER
    ); 
    j_rec3 t_data3;          
    
    v_step1_rst varchar2(300);
    v_clmno varchar2(20);
    rt_return varchar2(200);
    rt_rst varchar2(200);
  BEGIN
        FOR P1 in (
        SELECT A.STS_KEY,  A.CLM_NO, A.OST_CLM_NO, A.POLICYNO, decode(A.FLEET_SEQ,0,1,A.FLEET_SEQ) FLEET_SEQ, A.MAS_CUS_CODE, A.MAS_CUS_NAME, A.CUS_CODE, A.TITLE,  A.NAME, A.SURNAME,
        A.IDCARD_NO, A.HN_NO, A.INVOICE_NO, A.LOSS_DATE, A.LOSS_DETAIL, A.ICD_CODE, A.TR_DATE_FR, A.TR_DATE_TO, A.RISK_CODE,
        A.STATUS, A.REVISION, A.CLM_DATE,nvl(A.CLM_USER_CODE,'BK002') CLM_USER_CODE, A.CLM_USER_NAME, A.HOSPITAL_CODE, A.HOSPITAL_NAME, A.CORR_DATE ,A.REMARK ,A.RECPT_SEQ
        FROM NC_FAXDATA_MAS A WHERE A.STS_KEY = vKey 
        ) LOOP        
            
            INSERT INTO  NC_MASTER_TMP  A
            (A.STS_KEY,       A.INVOICE,       A.CLM_TYPE,       A.POLICY_NO,       A.FLEET_SEQ,  A.RECPT_SEQ ,       A.NAME,       A.SURNAME,       A.HN,
            A.ICD10,       A.CAUSE_CODE,       A.RISK_DESC,       A.LOSS_DATE,       A.FR_LOSS_DATE,       A.TO_LOSS_DATE,       A.HPT_CODE,       A.DAY,       A.HPT_USER
            ,A.Remark  ,A.EVN_DESC  ) VALUES
            (P1.STS_KEY ,P1.INVOICE_NO,       'I' ,       P1.POLICYNO,       P1.FLEET_SEQ, nvl(P1.RECPT_SEQ,1)  ,       P1.NAME,       P1.SURNAME,       P1.HN_NO,
            P1.ICD_CODE,       P1.RISK_CODE,       P1.LOSS_DETAIL,       to_date(P1.LOSS_DATE,'rrrrmmdd'),       to_date(P1.TR_DATE_FR,'rrrrmmdd') ,       to_date(P1.TR_DATE_TO,'rrrrmmdd') ,       P1.HOSPITAL_CODE,       to_number(P1.TR_DATE_TO - P1.TR_DATE_FR+1) ,       P1.CLM_USER_CODE
            ,P1.REMARK  ,null
            ) ;  
            dbms_output.put_line('FAX_MAS ==+ '||
            ' POLICY: '||P1.POLICYNO ||
            ' LOSS_DATE: '||P1.LOSS_DATE ||
            ' DAY: '||to_char(P1.TR_DATE_TO - P1.TR_DATE_FR+1));
            
        END LOOP;

        FOR P2 in (
        SELECT A.STS_KEY, A.CLM_NO, A.OST_CLM_NO, A.BENE_CODE, A.DESCR,
        A.REQUEST_AMT, A.RESERVE_AMT, A.DISC_AMT, A.PAID_AMT, A.REVISION, A.CORR_DATE
        FROM NC_FAXDATA_DETAIL A WHERE A.STS_KEY = vKey 
        ) LOOP        
            
            INSERT INTO  NC_DETAIL_TMP  B
            ( STS_KEY ,B.PREMCODE, B.REQUEST_AMT, B.REMAIN_AMT
            ) VALUES
            ( P2.STS_KEY ,P2.BENE_CODE, P2.REQUEST_AMT, P2.RESERVE_AMT
            ) ;  
            dbms_output.put_line('FAX_MAS ==+ '||
            ' PREMCODE: '||P2.BENE_CODE ||
            ' REQUEST_AMT: '||P2.REQUEST_AMT ||
            ' REMAIN_AMT: '||'');
            
        END LOOP;
          
        COMMIT;
        
        SAVE_STEP1('Y' ,vKey  ,c3 ,v_step1_rst);     
        
        dbms_output.put_line('SAVE_STEP1==>'||v_step1_rst);

        if v_step1_rst is null then
            LOOP
               FETCH  c3 INTO j_rec3;
                EXIT WHEN c3%NOTFOUND;
                    dbms_output.put_line('STS_KEY==>'|| 
                     j_rec3.sts_key||
                     ' NOTICE_NO:'||
                      j_rec3.notice_no||
                     ' CLM_NO:'||
                      j_rec3.clm_no                                   
                    );   
                    v_clmno :=  j_rec3.clm_no  ;
            END LOOP;   
            
            RST := v_clmno;
            
            rt_return :=  UPDATE_BKI_FAXCLM (vKey ,v_clmno  ,rt_rst);
            dbms_output.put_line('return UPDATE_BKI_FAXCLM= '||rt_return||' rst:'||rt_rst);
            
            return 'Y'; 
        else -- Save ไม่ผ่าน
            RST := 'SAVE_STEP1==>'||v_step1_rst;
            return 'N';         
        end if;            

  EXCEPTION 
    WHEN OTHERS THEN
        ROLLBACK;
        RST := 'error in GET_TPA_FAXCLM :'||sqlerrm;
        return 'E';  
  END; -- GET_TPA_FAXCLM

  FUNCTION GET_FINANCE_STATUS(v_POLICY IN VARCHAR2,
                                                        v_LOSSDATE IN VARCHAR2,
                            RST OUT VARCHAR2)  RETURN VARCHAR2 IS -- Y = คุ้มครอง N = ไม่คุ้มครอง
        c1   account.p_actr_package.v_ref_cursor;  
        v_POLNO     VARCHAR2(20);
        v_POLRUN    NUMBER(20);
        v_LOSS_DATE DATE;
        TYPE t_data1 IS RECORD
        (
              POLICY_NUMBER VARCHAR2(30),
              END_SEQ NUMBER,
              AGENT_CODE VARCHAR2(30),
              AGENT_SEQ VARCHAR2(30),
              RECPT_NO VARCHAR2(30),
              PROD_GRP VARCHAR2(30),
              PROD_TYPE VARCHAR2(30),
              INST_NO NUMBER,
              AR_FLAG VARCHAR2(30),
              AR_VOU_DATE DATE,
             CUST_NAME VARCHAR2(300),
             DATE_FROM DATE,
             DATE_TO DATE
        ); 
        j_rec1 t_data1;                                 
         
       chk_ar   VARCHAR2(20):='N';  
       count_period NUMBER:=0; 
       count_all NUMBER:=0; 
       cursor_cnt   NUMBER:=0;  
       t_date_fr    DATE;         t_date_to    DATE;     
       is_equl_date   BOOLEAN:=false;
       flag_period  VARCHAR2(1); -- M  monthly เดือน , P  period งวด , Y Yearly
       v_prodtype   VARCHAR2(10);
       v_endseq number(5);
       chk_bancas    VARCHAR2(10);
  BEGIN
        p_acc_package.read_pol(v_POLICY ,v_POLNO ,v_POLRUN);

        IF V_LOSSDATE is not null THEN
            v_LOSS_DATE  := to_date(V_LOSSDATE ,'dd/mm/yyyy');
        END IF;
                
        for p1 in (
            select prod_type ,end_seq from mis_mas where pol_no = v_POLNO and pol_run = v_POLRUN and prod_type is not null 
            and v_LOSS_DATE between fr_date and to_date
            and rownum =1 
        ) loop
            v_prodtype := p1.prod_type;
            v_endseq := p1.end_seq;
            dbms_output.put_line('get prod = '||v_prodtype||' endseq= '||v_endseq);
        end loop; 
        if  v_prodtype not in ('002') THEN  dbms_output.put_line('**Prod not 002 **'); chk_ar := 'Y' ; return chk_ar;  end if; -- ระบบตรวจเบี้ย ตรวจเฉพาะงาน prod_type 002 ที่เหลือผ่านหมด 
        chk_bancas := miscutil.chk_in_banc( v_POLNO ,v_POLRUN , nvl(v_endseq,0) );
        --dbms_output.put_line('==?> check BANCAS: '||chk_bancas);
        if  chk_bancas = 'Y' then dbms_output.put_line('**BANCAS Pol.**'); chk_ar := 'Y' ; return chk_ar;  end if; -- ระบบตรวจเบี้ย ไม่ตรวจงาน BANCAS
        
       /*  START count period */ 
       account.p_actr_package.get_pcm_data_cursor(v_POLNO,v_POLRUN,C1);
        LOOP
           FETCH  c1 INTO j_rec1;
            EXIT WHEN c1%NOTFOUND;
                dbms_output.put_line('POLICY_NUMBER==>'|| 
                 j_rec1.POLICY_NUMBER||
                 ' AR_FLAG:'||
                  j_rec1.AR_FLAG||
                 ' AR_VOU_DATE:'||
                  j_rec1.AR_VOU_DATE ||
                 ' DATE_FROM:'||
                  j_rec1.DATE_FROM||
                 ' DATE_TO:'||
                  j_rec1.DATE_TO                                                                      
                );    
                count_all := count_all+1 ;
                if count_all = 1 then -- เตรียม compare DATE แต่ละงวด --
                    t_date_fr := j_rec1.DATE_FROM;
                else
                    if     t_date_fr = j_rec1.DATE_FROM then -- วันที่เริ่มต้นเท่ากันทุกงวด --
                        is_equl_date := true;
                    else
                        is_equl_date := false;
                    end if;
                    t_date_fr := j_rec1.DATE_FROM;
                end if;
                
                IF v_LOSS_DATE between j_rec1.DATE_FROM AND j_rec1.DATE_TO THEN
                    count_period := count_period +1 ;
                END IF;
        END LOOP;          
        dbms_output.put_line('count_period LossDate IN = '|| count_period);
        
        if count_period = 0 then RST := 'ไม่พบข้อมูล PCM ที่คุ้มครองในช่วงวันที่ '||v_LOSS_DATE ;return 'N'; end if;
        /*  END count period */
        
       account.p_actr_package.get_pcm_data_cursor(v_POLNO,v_POLRUN,C1);           
        LOOP
           FETCH  c1 INTO j_rec1;
            EXIT WHEN c1%NOTFOUND;
                
                IF v_LOSS_DATE between j_rec1.DATE_FROM AND j_rec1.DATE_TO THEN
                    cursor_cnt := cursor_cnt +1 ;
                    -- แยก period 
                    if count_all = 1  then -- เช็ครายปี  /เดือน 
                        if (to_char(j_rec1.DATE_FROM , 'ddmm') = to_char(j_rec1.DATE_TO , 'ddmm')) and 
                            ( to_char(j_rec1.DATE_TO , 'yyyy') = to_char(j_rec1.DATE_FROM , 'yyyy')+1) then
                            dbms_output.put_line('**รายปี**');
                            if  j_rec1.AR_FLAG is null THEN  chk_ar := 'Y' ; return chk_ar; end if;
                            if  j_rec1.AR_FLAG = 'UP' THEN  chk_ar := 'N' ;  RST := 'Unpaid Period!' ; return chk_ar; end if; 
                        else 
                            dbms_output.put_line('**รายเดือน**');
                            if  j_rec1.AR_FLAG is null THEN  chk_ar := 'Y' ; return chk_ar; end if;
                            if  j_rec1.AR_FLAG = 'UP' THEN  chk_ar := 'N' ;  RST := 'Unpaid Period!' ; return chk_ar; end if;                             
                        end if;                   
                    else  -- เช็ค งวด / เดือน 
                        if is_equl_date then -- รายงวด 
                            if (to_char(j_rec1.DATE_FROM , 'ddmm') = to_char(j_rec1.DATE_TO , 'ddmm')) and 
                                ( to_char(j_rec1.DATE_TO , 'yyyy') = to_char(j_rec1.DATE_FROM , 'yyyy')+1) then
                                dbms_output.put_line('**รายปี แบบหลายรายรายการ**');
                                if  j_rec1.AR_FLAG is null THEN  chk_ar := 'Y' ; return chk_ar; end if;
                                if  j_rec1.AR_FLAG = 'UP' THEN  chk_ar := 'N' ;  RST := 'Unpaid Period!' ; end if;                 
                            else
                                if v_LOSS_DATE <= j_rec1.DATE_FROM+30 then -- ช่วงเครดิตเทอม ให้สำรองจ่าย 
                                    chk_ar := 'N' ;  RST := 'Credit Term Period!' ; 
                                else
                                    if  j_rec1.AR_FLAG is null THEN  chk_ar := 'Y' ; return chk_ar; end if;
                                    if  j_rec1.AR_FLAG = 'UP' THEN  chk_ar := 'N' ;  RST := 'Unpaid Period!' ; end if; 
                                end if;
                            end if;                               
                        else  -- รายเดือน 
                            if  j_rec1.AR_FLAG is null THEN  chk_ar := 'Y' ; return chk_ar;  end if;
                            if  j_rec1.AR_FLAG = 'UP' THEN  chk_ar := 'N' ;  RST := 'Unpaid Period!' ; end if;                        
                        end if;
                    end if;
                    
                END IF;
        END LOOP;    
        
        return chk_ar;          
  EXCEPTION 
    WHEN OTHERS THEN
        RST := 'error in GET_FINANCE_STATUS :'||sqlerrm;
        return 'N';  
          
  END ;   -- GET_FINANCE_STATUS
  FUNCTION GET_HISTORY_CLM_BY_POL(vPOLICY IN VARCHAR2,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_CLM_MAS OUT v_ref_cursor1 ,P_CLM_DETAIL OUT v_ref_cursor2 ,
                            RST OUT VARCHAR2)  RETURN VARCHAR2 IS

    P_POL_NO  VARCHAR2(20);
    P_POL_RUN  NUMBER;
--    P_FLEET_SEQ  NUMBER:=1;
--    P_LOSSDATE  DATE:='15-SEP-11';
    V_KEY  NUMBER;
        
    v_SID number(10);
    v_Tmp1 VARCHAR2(20);
    cnt NUMBER:=0;                    
    
    vPolType varchar2(10);  
    
    v_cntmas    number:=0;
    vOldPol     VARCHAR2(30);
    BEGIN
        --dbms_output.put_line('POLICY='||vPOLICY);
        p_acc_package.read_pol(vPOLICY ,P_POL_NO ,P_POL_RUN);
        dbms_output.put_line('P_POL_NO='||P_POL_NO||' P_POL_RUN:'||P_POL_RUN);
        vPolType := 'XX';         
        if P_POL_NO is not null and P_POL_RUN is not null then
            HEALTHUTIL.get_pa_health_type(P_POL_NO ,P_POL_RUN ,vPolType) ; 
            dbms_output.put_line('PolType='||vPolType);
        end if;
        
        IF vPolType not in ('PI','PG') THEN
            OPEN P_CLM_MAS FOR 
                select '' clm_no ,'' policyno ,0 fleet_seq ,'' mas_cus_code ,'' mas_cus_name
                ,'' title 
                ,'' name 
                ,'' surname 
                ,'' cus_code 
                ,'' idcard_no 
                ,'' loss_date ,''loss_detail ,''clm_sts ,'' icd_code 
                ,'' tr_date_fr ,'' tr_date_to ,''risk_code 
                ,'' clm_type 
                from dual      
            ;
            OPEN P_CLM_DETAIL FOR 
                select ''clm_no ,'' bene_code ,'' descr , 0 reserve_amt , 0 paid_amt 
                from dual
            ;          
            dbms_output.put_line('Exit');
            RST := 'ไม่พบข้อมูลกรมธรรม์นี้ในกลุ่มงาน PA';
            RETURN 'E';
        END IF;
                    
        NC_HEALTH_PACKAGE.GET_HISTORY_CLM2(P_POL_NO,P_POL_RUN,P_FLEET_SEQ, V_KEY) ;  
        dbms_output.put_line('Key='||V_KEY);
        
        IF V_KEY = 0 THEN
            OPEN P_CLM_MAS FOR 
                select '' clm_no ,'' policyno ,0 fleet_seq ,'' mas_cus_code ,'' mas_cus_name
                ,'' title 
                ,'' name 
                ,'' surname 
                ,'' cus_code 
                ,'' idcard_no 
                ,'' loss_date ,''loss_detail ,''clm_sts ,'' icd_code 
                ,'' tr_date_fr ,'' tr_date_to ,''risk_code 
                ,'' clm_type 
                from dual      
            ;
            OPEN P_CLM_DETAIL FOR 
                select ''clm_no ,'' bene_code ,'' descr , 0 reserve_amt , 0 paid_amt 
                from dual
            ;              
            RST := 'ไม่พบประวัติเคลม ';
            RETURN 'N';            
        ELSE
            FOR P1 IN (
                    select x.clm_no ,pol_no||pol_run policyno ,y.fleet_seq ,mas_cus_code ,mas_cus_enq mas_cus_name
                    ,(select title from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq ) title 
                    ,(select name from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq ) name 
                    ,(select surname from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq ) surname 
                    ,cus_code 
                    ,(select id from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq ) idcard_no 
                    ,x.loss_date ,loss_detail ,nc_health_package.CONVERT_CLM_STATUS(clm_sts) clm_sts ,dis_code icd_code 
                    ,loss_date_fr tr_date_fr ,loss_date_to tr_date_to ,risk_code 
                    from mis_clm_mas x ,mis_cpa_res y
                    where x.clm_no in 
                    (
                    select distinct a.clm_no
                    from NC_H_HISTORY_TMP a
                    where  sid=V_KEY
                    )
                    and x.clm_no = y.clm_no
                    and y.revise_seq = (select max(xx.revise_seq) from mis_cpa_res xx where xx.clm_no = y.clm_no)        
                    UNION
                    select a.clm_no ,pol_no||pol_run policyno ,a.fleet_seq ,mas_cus_code , mas_cus_name
                    ,(select title from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq ) title 
                    ,(select name  from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq ) name 
                    ,(select surname from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq ) surname 
                    ,cus_code ,a.id_no idcard_no
                    ,a.loss_date ,loss_detail ,nc_health_package.GET_CLM_STATUS(a.sts_key) clm_sts ,dis_code icd_code 
                    , tr_date_fr , tr_date_to ,cause_code risk_code 
                    from nc_mas a , nc_reserved b
                    where a.sts_key = b.sts_key
                    and a.clm_no not in (select x.clm_no from mis_clm_mas x where x.clm_no = a.clm_no)
                    and b.trn_seq in (select max(bb.trn_seq) from nc_reserved bb where bb.sts_key = b.sts_key)
                    and a.clm_no in 
                    (
                    select distinct x.clm_no
                    from NC_H_HISTORY_TMP x
                    where  sid=V_KEY
                    )           
            )
            LOOP
                v_cntmas := v_cntmas+1;
            END LOOP;
            
            IF v_cntmas = 0 THEN -- ไม่พบ clm_mas บน BKI APP
                NC_HEALTH_PACKAGE.REMOVE_HISTORY_CLM(V_KEY);             
                OPEN P_CLM_MAS FOR 
                    select '' clm_no ,'' policyno ,0 fleet_seq ,'' mas_cus_code ,'' mas_cus_name
                    ,'' title 
                    ,'' name 
                    ,'' surname 
                    ,'' cus_code 
                    ,'' idcard_no 
                    ,'' loss_date ,''loss_detail ,''clm_sts ,'' icd_code 
                    ,'' tr_date_fr ,'' tr_date_to ,''risk_code
                    ,'' clm_type --,'' old_policy
                    from dual      
                ;
                OPEN P_CLM_DETAIL FOR 
                    select ''clm_no ,'' bene_code ,'' descr , 0 reserve_amt , 0 paid_amt 
                    from dual
                ;                 
                RST := 'ไม่พบประวัติเคลม ';
                RETURN 'N';      
   
            END IF;
            
            OPEN P_CLM_MAS FOR 
                select x.clm_no ,pol_no||pol_run policyno ,y.fleet_seq ,mas_cus_code ,mas_cus_enq mas_cus_name
                ,(select title from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq ) title 
                ,(select name from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq ) name 
                ,(select surname from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq ) surname 
                ,cus_code 
                ,(select id from mis_pa_prem a where a.pol_no = x.pol_no and a.pol_run = x.pol_run and x.loss_date between a.fr_date and a.to_date and a.recpt_seq = x.recpt_seq and a.fleet_seq = y.fleet_seq ) idcard_no 
                ,to_char(x.loss_date,'yyyyddmm')  loss_date ,loss_detail ,nc_health_package.CONVERT_CLM_STATUS(clm_sts) clm_sts ,dis_code icd_code 
                ,to_char(loss_date_fr,'yyyyddmm')  tr_date_fr ,to_char(loss_date_to,'yyyyddmm')  tr_date_to ,risk_code 
                ,decode(nvl(x.ipd_flag,'N/A'),'I','IPD' ,decode(nvl(x.ipd_flag,'N/A'),'O','OPD',nvl(x.ipd_flag,'N/A')) ) clm_type
                --, (select old_pol_no||old_pol_run from mis_mas mm where mm.pol_no = x.pol_no and mm.pol_run = x.pol_run and mm.end_seq = (select max(mx.end_seq) from mis_mas mx where mx.pol_no = mm.pol_no and mx.pol_run = mm.pol_run) ) old_policy
                from mis_clm_mas x ,mis_cpa_res y
                where x.clm_no in 
                (
                select distinct a.clm_no
                from NC_H_HISTORY_TMP a
                where  sid=V_KEY
                )
                and x.clm_no = y.clm_no
                and y.revise_seq = (select max(xx.revise_seq) from mis_cpa_res xx where xx.clm_no = y.clm_no)    
                UNION
                select a.clm_no ,pol_no||pol_run policyno ,a.fleet_seq ,mas_cus_code , mas_cus_name
                ,(select title from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq ) title 
                ,(select name  from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq ) name 
                ,(select surname from mis_pa_prem y where a.pol_no = y.pol_no and a.pol_run = y.pol_run and a.loss_date between y.fr_date and y.to_date and a.recpt_seq = y.recpt_seq and a.fleet_seq = y.fleet_seq ) surname 
                ,cus_code ,a.id_no idcard_no
                , to_char(a.loss_date,'yyyyddmm') loss_date ,loss_detail ,nc_health_package.CONVERT_CLM_STATUS( nc_health_package.GET_CLM_STATUS(a.sts_key)) clm_sts ,dis_code icd_code 
                ,to_char(tr_date_fr,'yyyyddmm') tr_date_fr ,to_char(tr_date_to,'yyyyddmm') tr_date_to ,cause_code risk_code 
                ,decode(nvl(a.ipd_flag,'N/A'),'I','IPD' ,decode(nvl(a.ipd_flag,'N/A'),'O','OPD',nvl(a.ipd_flag,'N/A')) ) clm_type
                --, (select old_pol_no||old_pol_run from mis_mas mm where mm.pol_no = a.pol_no and mm.pol_run = a.pol_run and mm.end_seq = (select max(mx.end_seq) from mis_mas mx where mx.pol_no = mm.pol_no and mx.pol_run = mm.pol_run) ) old_policy
                from nc_mas a , nc_reserved b
                where a.sts_key = b.sts_key
                and a.clm_no not in (select x.clm_no from mis_clm_mas x where x.clm_no = a.clm_no)
                and b.trn_seq in (select max(bb.trn_seq) from nc_reserved bb where bb.sts_key = b.sts_key)
                and a.clm_no in 
                (
                select distinct x.clm_no
                from NC_H_HISTORY_TMP x
                where  sid=V_KEY
                )                                 
            ;
            OPEN P_CLM_DETAIL FOR 
                select clm_no ,prem_code bene_code ,NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(prem_code ,'T') descr , amount reserve_amt , 0 paid_amt 
                from NC_H_HISTORY_TMP a
                where sid=V_KEY and TYPE in ('X','R')
                and (select chk_accum from nc_h_premcode where premcode = a.prem_code and rownum =1 ) = 'Y'
                UNION
                select clm_no ,prem_code bene_code ,NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(prem_code ,'T') descr, 0 reserve_amt ,amount paid_amt
                from NC_H_HISTORY_TMP a
                where sid=V_KEY and TYPE in ('P')
                and (select chk_accum from nc_h_premcode where premcode = a.prem_code and rownum =1 ) = 'Y'
                order by clm_no    
            ;          
            
            NC_HEALTH_PACKAGE.REMOVE_HISTORY_CLM(V_KEY);
            
            return   'Y'; 
            
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
        NC_HEALTH_PACKAGE.REMOVE_HISTORY_CLM(V_KEY);
            OPEN P_CLM_MAS FOR 
                select '' clm_no ,'' policyno ,0 fleet_seq ,'' mas_cus_code ,'' mas_cus_name
                ,'' title 
                ,'' name 
                ,'' surname 
                ,'' cus_code 
                ,'' idcard_no 
                ,'' loss_date ,''loss_detail ,''clm_sts ,'' icd_code 
                ,'' tr_date_fr ,'' tr_date_to ,''risk_code 
                ,'' clm_type 
                from dual      
            ;
            OPEN P_CLM_DETAIL FOR 
                select ''clm_no ,'' bene_code ,'' descr , 0 reserve_amt , 0 paid_amt 
                from dual
            ;              
        RST := 'error in GET_HISTORY_CLM_BY_POL :'||sqlerrm;
        return 'E';
    END;         --END GET_HISTORY_CLM_BY_POL 

    FUNCTION GET_POLICY_BY_POL(vPOLICY IN VARCHAR2 ,vLOSS_DATE IN VARCHAR2 ,vRecpt IN VARCHAR2 ,vFLEET IN VARCHAR2 ,vFlag IN VARCHAR2 ,rSID OUT NUMBER) RETURN VARCHAR2 IS -- Y = คุ้มครอง N = ไม่คุ้มครอง , E = ไม่พบหรืออื่นๆ , M = many  Policy 
        o_name   HEALTHUTIL.sys_refcursor;  
        --cnt_covername   number:=0;
        TYPE t_data1 IS RECORD
        (
            NAME VARCHAR2(200) ,
            FLEET_SEQ NUMBER ,
            RECPT_SEQ NUMBER 
        ); 
        j_rec1 t_data1; 
        cnt_covername   number:=1;
        
        c2   NC_HEALTH_PACKAGE.v_ref_cursor1;  
        
        tSts1 varchar2(200):=null;
        TYPE t_data2 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        SUMINS  NUMBER,
        PREMCOL NUMBER
        ); 
        j_rec2 t_data2;  
                 
        rst varchar2(200);
        v_return    varchar2(1);
        v_SID number;
        v_cus_code  varchar2(30);
        v_mascus_code  varchar2(30);
        v_mascus_name  varchar2(200);
        v_polno varchar2(20);
        v_polrun    number(20);
        v_lossdate  date:=to_date(vLOSS_DATE , 'dd/mm/rrrr');
        r_chk_pol   varchar2(3);
        rst_chk_pol varchar2(200);    
        vPolType varchar2(10);
        
        x_recpt_seq number;
        x_fleet_seq number;
        x_chkmotor  boolean := false;
        x_cover_flag    varchar2(10);
        x_cover_remark    varchar2(200);
        v_old_pol varchar2(50);  
        m_cnt number:=0;
        new_flag varchar2(10);
        is_telep    varchar2(10);
        qry_str  varchar2(1000);
--        qry_str2  varchar2(1000);   
        
        TYPE t_datax IS RECORD
        (
        POL_NO  VARCHAR2(20),
        POL_RUN  VARCHAR2(20),
        RECPT_SEQ    NUMBER,    
        FLEET_SEQ    NUMBER, 
        END_SEQ NUMBER,
        ID  VARCHAR2(20),
        TITLE   VARCHAR2(200),
        NAME   VARCHAR2(200),
        SURNAME   VARCHAR2(200),
        FR_DATE DATE ,
        TO_DATE DATE
        ); 
        v1 t_datax;       
        x1 t_datax;      
        TYPE cur_typ IS REF CURSOR;
        P_V1     cur_typ;  
        P_X1     cur_typ;            
    BEGIN
        
        new_flag := vFlag ;
        IF vFlag= 'M' THEN
            p_acc_package.read_pol(vPOLICY ,v_polno ,v_polrun);
--========
            v_SID := NC_HEALTH_PACKAGE.GEN_SID;    
            HEALTHUTIL.get_pa_health_type(v_polno ,v_polrun ,vPolType) ; 
            
--            HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,vFLEET , v_lossdate  ,o_name) ;
            dbms_output.put_line('Flag M v_polno :'||v_polno||v_polrun||' fleet:'||vFleet||' Tloss_date:'||vLOSS_DATE||' recpt_seq:'||vRecpt );
                                
            HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,vFleet ,v_lossdate ,o_name) ;
            --HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,0 ,v_lossdate ,o_name) ;
            x_recpt_seq := 0;
            LOOP
            FETCH  o_name INTO j_rec1;
            EXIT WHEN o_name%NOTFOUND;
--                if x_recpt_seq < j_rec1.RECPT_SEQ then
                    x_recpt_seq :=  j_rec1.RECPT_SEQ ;
--                end if;
                x_fleet_seq := j_rec1.FLEET_SEQ ;
                if vRecpt is not null then
                    x_recpt_seq := vRecpt ;
                    qry_str := 'select pol_no ,pol_run ,recpt_seq ,fleet_seq ,min(end_seq) end_seq ,id ,title ,name ,surname ,fr_date ,to_date  '||    
                    '   from mis_pa_prem a  where pol_no ='''||v_polno ||''' '||
                    ' and pol_run= '||v_polrun ||
                    ' and to_date('''|| v_lossdate||''' ,''DD/MM/RRRR'')  between fr_date and to_date ' ||
                    ' and recpt_seq = '||x_recpt_seq||
                    ' and fleet_seq = '||x_fleet_seq ||
                    ' and cancel is null  group by pol_no ,pol_run ,recpt_seq ,fleet_seq  ,id ,title ,name ,surname ,fr_date ,to_date' ;
                    dbms_output.put_line('query ระบุ recpt: '||qry_str);       
                else -- กรณี many Policy 
                    if vFleet > 0  and  vRecpt is null and  HEALTHUTIL.GET_COUNT_NAME(v_polno ,v_polrun ,vFleet) > 1 then -- Dupp Fleet_seq 
                        qry_str := 'select pol_no ,pol_run ,recpt_seq ,fleet_seq , min(end_seq) end_seq ,id ,title ,name ,surname ,fr_date ,to_date  '||    
                            '   from mis_pa_prem a  where pol_no ='''||v_polno ||''' '||
                            ' and pol_run= '||v_polrun ||
                            ' and to_date('''|| v_lossdate||''' ,''DD/MM/RRRR'')  between fr_date and to_date ' ||
                            ' and recpt_seq = '||x_recpt_seq||
                            ' and fleet_seq = '||x_fleet_seq  ||
                            'and cancel is null group by pol_no ,pol_run ,recpt_seq ,fleet_seq  ,id ,title ,name ,surname ,fr_date ,to_date' ;    
                            dbms_output.put_line('query ไม่ระบุ recpt dupp_fleet: '||qry_str);       
                    else
                        qry_str := 'select pol_no ,pol_run ,recpt_seq ,fleet_seq , min(end_seq) end_seq ,id ,title ,name ,surname ,fr_date ,to_date  '||    
                        '   from mis_pa_prem a  where pol_no ='''||v_polno ||''' '||
                        ' and pol_run= '||v_polrun ||
                        ' and to_date('''|| v_lossdate||''' ,''DD/MM/RRRR'')  between fr_date and to_date ' ||
                        ' and recpt_seq = '||x_recpt_seq||
                        ' and fleet_seq = '||x_fleet_seq  ||
                        'and cancel is null group by pol_no ,pol_run ,recpt_seq ,fleet_seq  ,id ,title ,name ,surname ,fr_date ,to_date' ;           
                        dbms_output.put_line('query ไม่ระบุ recpt ไม่ระบุ fleet: '||qry_str);              
                    end if;                      
           
                end if;
            OPEN P_V1 FOR qry_str ;
            LOOP  -- นำข้อมูลมาสร้าง Draft 
               FETCH  P_V1 INTO V1;
                EXIT WHEN P_V1%NOTFOUND;                
                    m_cnt := m_cnt +1;                    
                    v_cus_code := null;
                    FOR v2 in (
                        select cus_code
                        from mis_recpt
                        where pol_no =v1.pol_no
                        and pol_run=v1.pol_run
                        and v_lossdate  between fr_date and to_date
                        and rownum=1
                    ) LOOP
                        v_cus_code := v2.cus_code ;
                    END LOOP; --v2

                    v_mascus_code := null;
                    v_mascus_name := null;
                    FOR v3 in (
                        select cus_code , cus_enq ,old_pol_no||old_pol_run old_policy
                        from mis_mas
                        where pol_no =v1.pol_no
                        and pol_run=v1.pol_run
                        and v_lossdate  between fr_date and to_date
                        and rownum=1
                    ) LOOP
                        v_mascus_code := v3.cus_code ;
                        v_mascus_name := v3.cus_enq ;
                        v_old_pol := v3.old_policy ; 
                    END LOOP; --v3
                                    
                    BEGIN
                    INSERT INTO NC_GET_POLICY_TMP (  SID , POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME ,
                      CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE ,old_policy  )
                    VALUES (    V_SID ,vPOLICY ,j_rec1.fleet_seq ,v_mascus_code , v_mascus_name, v1.title ,v1.name ,v1.surname ,
                   --     v_cus_code ,v1.id ,v1.end_seq, x_recpt_seq ,v1.fr_date ,v1.to_date  ,v_old_pol 
                        v_cus_code ,v1.id ,v1.end_seq, j_rec1.recpt_seq ,v1.fr_date ,v1.to_date  ,v_old_pol                         
                    )           ;
                    EXCEPTION
                        WHEN OTHERS THEN
                        dbms_output.put_line('error insert NC_GET_POLICY_TMP :: '||sqlerrm);     
                        return 'E'; 
                    END;     

                   IF vFleet <>0 THEN  --กรณี PolType เป็น PI แต่กรมธรรม์เก็บเป็นกลุ่ม 
                    dbms_output.put_line('GET GET_COUNT_NAME ACTIVE==>'||HEALTHUTIL.GET_COUNT_NAME(v_polno ,v_polrun ,vFleet) );
                    if vFleet > 0  and  vRecpt is null then
                        if HEALTHUTIL.GET_COUNT_NAME(v_polno ,v_polrun ,vFleet) > 0 then -- Dupp Fleet_seq 
                            new_flag :=  'M'; 
                        end if;
                    end if;        
                    
                    if  new_flag <> 'M' then        -- not dupp fleet_seq      
                   
                           NC_HEALTH_PACKAGE.GET_COVER_PA (v1.pol_no,v1.pol_run,v1.fleet_seq ,v1.recpt_seq ,v_lossdate, null ,
                                                              c2 ,tSts1 );   
                                  
                            if tSts1 is null then
                                x_chkmotor := false;     
                                LOOP
                                   FETCH  c2 INTO j_rec2;
                                    EXIT WHEN c2%NOTFOUND;
                                        --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                                        if IS_CHECK_MOTORCYCLE(j_rec2.premcode) then
                                            x_chkmotor := true;                                                 
                                        end if;
                                END LOOP;  
                            end if;

                           NC_HEALTH_PACKAGE.GET_COVER_PA (v1.pol_no,v1.pol_run,v1.fleet_seq ,v1.recpt_seq ,v_lossdate , null ,
                                                              c2 ,tSts1 );                       
                           dbms_output.put_line('Msg==>'||tSts1);
                            if tSts1 is null then
                            
                                LOOP
                                   FETCH  c2 INTO j_rec2;
                                    EXIT WHEN c2%NOTFOUND;
                                        --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                                        x_cover_flag   := null;
                                        x_cover_remark := null;
                                        if 1=1 then
                                            dbms_output.put_line('Prem==>'|| 
                                             j_rec2.premcode||' '||NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec2.premcode ,'T')||
                                             ' SUMINS:'||
                                              j_rec2.sumins||
                                              ' COL:'||
                                              j_rec2.premcol
                                            );
                                                if x_chkmotor and IS_CHECK_ACCUM(j_rec2.premcode) then
                                                    x_cover_flag := 'MC' ;
                                                    x_cover_remark := 'คุ้มครองมอเตอร์ไซ';
                                                else
                                                    x_cover_flag   := null;
                                                    x_cover_remark := null;
                                                end if;
                                                
                                                if MISC.HEALTHUTIL.is_45plus(v1.pol_no,v1.pol_run) and IS_CHECK_ACCUM(j_rec2.premcode)  then
                                                    dbms_output.put_line('45Plus Remark happen.') ;
                                                    x_cover_remark := x_cover_remark ||' ; '||replace(replace(MISC.HEALTHUTIL.get_benefit_card_45plus(v1.pol_no,v1.pol_run,v1.fleet_seq,v1.recpt_seq),'<br />',''),'-','') ;
                                                end if;     
                                                                                           
                                                BEGIN
                                                INSERT INTO NC_GET_COVER_TMP ( SID ,BENE_CODE ,DESCR ,REMARK ,FLAG ,AMOUNT )
                                                VALUES (    V_SID ,j_rec2.premcode ,NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec2.premcode ,'T') , x_cover_remark , x_cover_flag 
                                                ,j_rec2.sumins
                                                )           ;
                                                EXCEPTION
                                                    WHEN OTHERS THEN
                                                    dbms_output.put_line('error insert NC_GET_COVER_TMP :: '||sqlerrm);     
                                                    return 'E'; 
                                                END;                                             
                                        end if;
                                END LOOP;    
                            HEALTHUTIL.GET_STATUS_ACTIVE(v1.pol_no,v1.pol_run,v1.fleet_seq , x_recpt_seq ,v_lossdate ,new_flag) ;
                            dbms_output.put_line('RE GET STATUS ACTIVE==>'||new_flag);
                            end if;                                     
                     end if ; -- จบตรวจสอบ dupp fleet_seq    
                   END IF;           -- จบ กรณี PolType เป็น PI แต่กรมธรรม์เก็บเป็นกลุ่ม                 
                END LOOP;    -- V1 
                dbms_output.put_line('m_cnt:'||m_cnt||' x_recpt_seq:='||x_recpt_seq||' x_fleet_seq='||x_fleet_seq);      
            END LOOP;          
            
            IF m_cnt =0 then
                return 'N'; 
            END IF;
              COMMIT;
              rSID := v_SID;     return new_flag;
        END IF;

        IF vFlag in ('N') THEN
            p_acc_package.read_pol(vPOLICY ,v_polno ,v_polrun);
--========
            v_SID := NC_HEALTH_PACKAGE.GEN_SID;    
            HEALTHUTIL.get_pa_health_type(v_polno ,v_polrun ,vPolType) ; 
               
            --HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,vFleet ,v_lossdate ,o_name) ;
            if vPolType = 'PI' then -- ถ้าเป็นเดี่ยวแล้วใส่ fleet_seq = 1 ไป จะฉิบหาย
                dbms_output.put_line('?????? v_polno :'||v_polno||v_polrun||' fleet:'||0||' Tloss_date:'||vLOSS_DATE );
                HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,0 ,v_lossdate ,o_name) ;
            else
                dbms_output.put_line('?????? v_polno :'||v_polno||v_polrun||' fleet:'||vFleet||' Tloss_date:'||vLOSS_DATE );
                HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,vFleet ,v_lossdate ,o_name) ;
            end if;                 
            
            x_recpt_seq := 0;
            LOOP
            FETCH  o_name INTO j_rec1;
            EXIT WHEN o_name%NOTFOUND;
                if x_recpt_seq < j_rec1.RECPT_SEQ then
                    x_recpt_seq :=  j_rec1.RECPT_SEQ ;
                end if;
                --x_recpt_seq :=  j_rec1.RECPT_SEQ ;
                x_fleet_seq := j_rec1.FLEET_SEQ ;
            END LOOP;         
            if vRecpt is not null then
                x_recpt_seq := vRecpt ;
            end if;
                
            dbms_output.put_line('v_polno==>'||v_polno||v_polrun||' v_lossdate:'||v_lossdate||'  x_recpt_seq:'||x_recpt_seq);        
            FOR x1 in (
                select pol_no ,pol_run ,recpt_seq ,fleet_seq , end_seq ,id ,title ,name ,surname ,fr_date ,to_date 
                from mis_pa_prem a
                where pol_no =v_polno
                and pol_run=v_polrun
                --and v_lossdate  between fr_date and to_date
                --and id = vIDNO
                and recpt_seq =x_recpt_seq
                and fleet_seq = x_fleet_seq
                and rownum=1
                ) LOOP
                                    
                v_cus_code := null;
                FOR x2 in (
                    select cus_code
                    from mis_recpt
                    where pol_no =x1.pol_no
                    and pol_run=x1.pol_run
                    --and v_lossdate  between fr_date and to_date
                    and rownum=1
                ) LOOP
                    v_cus_code := x2.cus_code ;
                END LOOP; --x2

                v_mascus_code := null;
                v_mascus_name := null;
                FOR x3 in (
                    select cus_code , cus_enq ,old_pol_no||old_pol_run old_policy
                    from mis_mas
                    where pol_no =x1.pol_no
                    and pol_run=x1.pol_run
                    --and v_lossdate  between fr_date and to_date
                    and rownum=1
                ) LOOP
                    v_mascus_code := x3.cus_code ;
                    v_mascus_name := x3.cus_enq ;
                    v_old_pol := x3.old_policy ; 
                END LOOP; --x3
                                                            
                BEGIN
                INSERT INTO NC_GET_POLICY_TMP (  SID , POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME ,
                  CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE ,OLD_POLICY )
                VALUES (    V_SID ,x1.pol_no||x1.pol_run ,x1.fleet_seq ,v_mascus_code , v_mascus_name, x1.title ,x1.name ,x1.surname ,
                    v_cus_code ,x1.id ,x1.end_seq, x1.recpt_seq ,x1.fr_date ,x1.to_date  ,v_old_pol
                )           ;
                EXCEPTION
                    WHEN OTHERS THEN
                    dbms_output.put_line('error insert NC_GET_POLICY_TMP :: '||sqlerrm);     
                    return 'E'; 
                END;               
                        
               /*  get Coverage*/ 
               IF vFlag in ('Y','N') THEN
               NC_HEALTH_PACKAGE.GET_COVER_PA (x1.pol_no,x1.pol_run,x1.fleet_seq, x1.recpt_seq ,v_lossdate, null ,
                                                  c2 ,tSts1 );   
                      
                if tSts1 is null then
                    x_chkmotor := false;     
                    LOOP
                       FETCH  c2 INTO j_rec2;
                        EXIT WHEN c2%NOTFOUND;
                            --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                            if IS_CHECK_MOTORCYCLE(j_rec2.premcode) then
                                x_chkmotor := true;                                                 
                            end if;
                    END LOOP;  
                end if;

               NC_HEALTH_PACKAGE.GET_COVER_PA (x1.pol_no,x1.pol_run,x1.fleet_seq ,x1.recpt_seq ,v_lossdate, null ,
                                                  c2 ,tSts1 );                       
               dbms_output.put_line('Msg==>'||tSts1);
                if tSts1 is null then
                
                    LOOP
                       FETCH  c2 INTO j_rec2;
                        EXIT WHEN c2%NOTFOUND;
                            --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                            x_cover_flag   := null;
                            x_cover_remark := null;
                            if 1=1 then
                                dbms_output.put_line('Prem==>'|| 
                                 j_rec2.premcode||' '||NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec2.premcode ,'T')||
                                 ' SUMINS:'||
                                  j_rec2.sumins||
                                  ' COL:'||
                                  j_rec2.premcol
                                );
                                    if x_chkmotor and IS_CHECK_ACCUM(j_rec2.premcode) then
                                        x_cover_flag := 'MC' ;
                                        x_cover_remark := 'คุ้มครองมอเตอร์ไซ';
                                    else
                                        x_cover_flag   := null;
                                        x_cover_remark := null;
                                    end if;
                                    
                                    if MISC.HEALTHUTIL.is_45plus(x1.pol_no,x1.pol_run) and IS_CHECK_ACCUM(j_rec2.premcode)  then
                                        dbms_output.put_line('45Plus Remark happen.') ;
                                        x_cover_remark := x_cover_remark ||' ; '||replace(replace(MISC.HEALTHUTIL.get_benefit_card_45plus(x1.pol_no,x1.pol_run,x1.fleet_seq,x1.recpt_seq),'<br />',''),'-','') ;
                                    end if;
                                                                                    
                                    BEGIN
                                    INSERT INTO NC_GET_COVER_TMP ( SID ,BENE_CODE ,DESCR ,REMARK ,FLAG ,AMOUNT )
                                    VALUES (    V_SID ,j_rec2.premcode ,NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec2.premcode ,'T') , x_cover_remark , x_cover_flag 
                                    ,j_rec2.sumins
                                    )           ;
                                    EXCEPTION
                                        WHEN OTHERS THEN
                                        dbms_output.put_line('error insert NC_GET_COVER_TMP :: '||sqlerrm);     
                                        return 'E'; 
                                    END;                                             
                            end if;
                    END LOOP;    
                  end if;   
               ELSE
                   null;                                   
               END IF; 
                                              
            END LOOP; -- x1

            --dbms_output.put_line('=======v_SID := '||v_SID);       
              COMMIT;
              rSID := v_SID;     return vFlag;
        END IF; -- Flag N
              
        IF vFlag in ('Y','M' ,'N') THEN
            p_acc_package.read_pol(vPOLICY ,v_polno ,v_polrun);
--========
            v_SID := NC_HEALTH_PACKAGE.GEN_SID;    
            HEALTHUTIL.get_pa_health_type(v_polno ,v_polrun ,vPolType) ; 
               
            --HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,vFleet ,v_lossdate ,o_name) ;
            if vPolType = 'PI' then -- ถ้าเป็นเดี่ยวแล้วใส่ fleet_seq = 1 ไป จะฉิบหาย
                dbms_output.put_line(' v_polno :'||v_polno||v_polrun||' fleet:'||0||' Tloss_date:'||vLOSS_DATE );
                HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,0 ,v_lossdate ,o_name) ;
            else
                dbms_output.put_line(' v_polno :'||v_polno||v_polrun||' fleet:'||vFleet||' Tloss_date:'||vLOSS_DATE );
                HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,vFleet ,v_lossdate ,o_name) ;
            end if;                 
            
            x_recpt_seq := 0;
            LOOP
            FETCH  o_name INTO j_rec1;
            EXIT WHEN o_name%NOTFOUND;
                if x_recpt_seq < j_rec1.RECPT_SEQ then
                    x_recpt_seq :=  j_rec1.RECPT_SEQ ;
                end if;
                --x_recpt_seq :=  j_rec1.RECPT_SEQ ;
                x_fleet_seq := j_rec1.FLEET_SEQ ;
            END LOOP;         

--            if vRecpt is not null then
--                x_recpt_seq := vRecpt ;
--            end if;
                
            dbms_output.put_line('v_polno==>'||v_polno||v_polrun||' v_lossdate:'||v_lossdate||'  x_recpt_seq:'||x_recpt_seq);        
                if vRecpt is not null then
                    x_recpt_seq := vRecpt ;
                    qry_str := 'select pol_no ,pol_run ,recpt_seq ,fleet_seq ,min(end_seq) end_seq ,id ,title ,name ,surname ,fr_date ,to_date  '||    
                    '   from mis_pa_prem a  where pol_no ='''||v_polno ||''' '||
                    ' and pol_run= '||v_polrun ||
                    ' and to_date('''|| v_lossdate||''' ,''DD/MM/RRRR'')  between fr_date and to_date ' ||
                    ' and recpt_seq = '||x_recpt_seq||
                    ' and fleet_seq = '||x_fleet_seq ||
                    ' and cancel is null and rownum=1 group by pol_no ,pol_run ,recpt_seq ,fleet_seq  ,id ,title ,name ,surname ,fr_date ,to_date' ;
                else -- กรณี many Policy 
                    qry_str := 'select pol_no ,pol_run ,recpt_seq ,fleet_seq ,min(end_seq) end_seq ,id ,title ,name ,surname ,fr_date ,to_date  '||    
                    '   from mis_pa_prem a  where pol_no ='''||v_polno ||''' '||
                    ' and pol_run= '||v_polrun ||
                    ' and to_date('''|| v_lossdate||''' ,''DD/MM/RRRR'')  between fr_date and to_date ' ||
                    ' and recpt_seq = '||x_recpt_seq||
                    ' and fleet_seq = '||x_fleet_seq ||
                    ' and cancel is null group by pol_no ,pol_run ,recpt_seq ,fleet_seq  ,id ,title ,name ,surname ,fr_date ,to_date' ;                
                end if;
                
            OPEN P_X1 FOR qry_str ;
            LOOP  -- นำข้อมูลมาสร้าง Draft 
               FETCH  P_X1 INTO X1;
                EXIT WHEN P_X1%NOTFOUND;         
                                    
                v_cus_code := null;
                FOR x2 in (
                    select cus_code
                    from mis_recpt
                    where pol_no =x1.pol_no
                    and pol_run=x1.pol_run
                    and v_lossdate  between fr_date and to_date
                    and rownum=1
                ) LOOP
                    v_cus_code := x2.cus_code ;
                END LOOP; --x2

                v_mascus_code := null;
                v_mascus_name := null;
                FOR x3 in (
                    select cus_code , cus_enq ,old_pol_no||old_pol_run old_policy
                    from mis_mas
                    where pol_no =x1.pol_no
                    and pol_run=x1.pol_run
                    and v_lossdate  between fr_date and to_date
                    and rownum=1
                ) LOOP
                    v_mascus_code := x3.cus_code ;
                    v_mascus_name := x3.cus_enq ;
                    v_old_pol := x3.old_policy ; 
                END LOOP; --x3
                                                            
                BEGIN
                INSERT INTO NC_GET_POLICY_TMP (  SID , POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME ,
                  CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE ,OLD_POLICY )
                VALUES (    V_SID ,x1.pol_no||x1.pol_run ,x1.fleet_seq ,v_mascus_code , v_mascus_name, x1.title ,x1.name ,x1.surname ,
                    v_cus_code ,x1.id ,x1.end_seq, x1.recpt_seq ,x1.fr_date ,x1.to_date  ,v_old_pol
                )           ;
                EXCEPTION
                    WHEN OTHERS THEN
                    dbms_output.put_line('error insert NC_GET_POLICY_TMP :: '||sqlerrm);     
                    return 'E'; 
                END;               
                        
               /*  get Coverage*/ 
               IF vFlag in ('Y','N') THEN
               NC_HEALTH_PACKAGE.GET_COVER_PA (x1.pol_no,x1.pol_run,x1.fleet_seq ,x1.recpt_seq ,v_lossdate, null ,
                                                  c2 ,tSts1 );   
                      
                if tSts1 is null then
                    x_chkmotor := false;     
                    LOOP
                       FETCH  c2 INTO j_rec2;
                        EXIT WHEN c2%NOTFOUND;
                            --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                            if IS_CHECK_MOTORCYCLE(j_rec2.premcode) then
                                x_chkmotor := true;                                                 
                            end if;
                    END LOOP;  
                end if;

               NC_HEALTH_PACKAGE.GET_COVER_PA (x1.pol_no,x1.pol_run,x1.fleet_seq ,x1.recpt_seq ,v_lossdate, null ,
                                                  c2 ,tSts1 );                       
               dbms_output.put_line('Msg==>'||tSts1);
                if tSts1 is null then
                
                    LOOP
                       FETCH  c2 INTO j_rec2;
                        EXIT WHEN c2%NOTFOUND;
                            --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                            x_cover_flag   := null;
                            x_cover_remark := null;
                            if 1=1 then
                                dbms_output.put_line('Prem==>'|| 
                                 j_rec2.premcode||' '||NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec2.premcode ,'T')||
                                 ' SUMINS:'||
                                  j_rec2.sumins||
                                  ' COL:'||
                                  j_rec2.premcol
                                );
                                    if x_chkmotor and IS_CHECK_ACCUM(j_rec2.premcode) then
                                        x_cover_flag := 'MC' ;
                                        x_cover_remark := 'คุ้มครองมอเตอร์ไซ';
                                    else
                                        x_cover_flag   := null;
                                        x_cover_remark := null;
                                    end if;

                                    if MISC.HEALTHUTIL.is_45plus(x1.pol_no,x1.pol_run) and IS_CHECK_ACCUM(j_rec2.premcode)  then
                                        dbms_output.put_line('45Plus Remark happen.') ;
                                        x_cover_remark := x_cover_remark ||' ; '||replace(replace(MISC.HEALTHUTIL.get_benefit_card_45plus(x1.pol_no,x1.pol_run,x1.fleet_seq,x1.recpt_seq),'<br />',''),'-','') ;
                                    end if;
                                                                        
                                    BEGIN
                                    INSERT INTO NC_GET_COVER_TMP ( SID ,BENE_CODE ,DESCR ,REMARK ,FLAG ,AMOUNT )
                                    VALUES (    V_SID ,j_rec2.premcode ,NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec2.premcode ,'T') , x_cover_remark , x_cover_flag 
                                    ,j_rec2.sumins
                                    )           ;
                                    EXCEPTION
                                        WHEN OTHERS THEN
                                        dbms_output.put_line('error insert NC_GET_COVER_TMP :: '||sqlerrm);     
                                        return 'E'; 
                                    END;                                             
                            end if;
                    END LOOP;    
                  end if;   
               ELSE
                   null;                                   
               END IF; --END vFlag in ('Y')
                                              
            END LOOP; -- x1

            --dbms_output.put_line('=======v_SID := '||v_SID);       
              COMMIT;
              rSID := v_SID;     return vFlag;
              
        ELSIF vFlag in ('E') THEN --****  Flag E for check TELE      
            p_acc_package.read_pol(vPOLICY ,v_polno ,v_polrun);
            is_telep := HEALTHUTIL.IS_TELE(v_polno ,v_polrun); 
            
            IF nvl(is_telep ,'N') <> 'Y' THEN --** ถ้าไม่ใช่งาน TELE ให้คง process เดิม
                return vFlag ;
            END IF; 
            --** หาข้อมูลความคุ้มครอง tele ไปแสดง
            
            v_SID := NC_HEALTH_PACKAGE.GEN_SID;    
            HEALTHUTIL.get_pa_health_type(v_polno ,v_polrun ,vPolType) ; 
               
            --HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,vFleet ,v_lossdate ,o_name) ;
            if vPolType = 'PI' then -- ถ้าเป็นเดี่ยวแล้วใส่ fleet_seq = 1 ไป จะฉิบหาย
                dbms_output.put_line('?????? v_polno :'||v_polno||v_polrun||' fleet:'||0||' Tloss_date:'||vLOSS_DATE );
                HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,0 ,v_lossdate ,o_name) ;
            else
                dbms_output.put_line('?????? v_polno :'||v_polno||v_polrun||' fleet:'||vFleet||' Tloss_date:'||vLOSS_DATE );
                HEALTHUTIL.get_name_cover(v_polno ,v_polrun ,vFleet ,v_lossdate ,o_name) ;
            end if;                 
            
            x_recpt_seq := 0;
            LOOP
            FETCH  o_name INTO j_rec1;
            EXIT WHEN o_name%NOTFOUND;
                if x_recpt_seq < j_rec1.RECPT_SEQ then
                    x_recpt_seq :=  j_rec1.RECPT_SEQ ;
                end if;
                --x_recpt_seq :=  j_rec1.RECPT_SEQ ;
                x_fleet_seq := j_rec1.FLEET_SEQ ;
            END LOOP;         

            if vRecpt is not null then
                x_recpt_seq := vRecpt ;
            end if;
                
            dbms_output.put_line('v_polno==>'||v_polno||v_polrun||' v_lossdate:'||v_lossdate||'  x_recpt_seq:'||x_recpt_seq);        
            FOR x1 in (
                select pol_no ,pol_run ,recpt_seq ,fleet_seq ,min(end_seq) end_seq ,id ,title ,name ,surname ,fr_date ,to_date 
                from mis_pa_prem a
                where pol_no =v_polno
                and pol_run=v_polrun
                and v_lossdate  between fr_date and to_date /* งาน tele ตอ้งใช้ loss_date หา recpt*/
                --and id = vIDNO
                --and recpt_seq =x_recpt_seq
                and fleet_seq = x_fleet_seq 
                and cancel is null 
                group by pol_no ,pol_run ,recpt_seq ,fleet_seq  ,id ,title ,name ,surname ,fr_date ,to_date
                ) LOOP
                                    
                v_cus_code := null;
                FOR x2 in (
                    select cus_code
                    from mis_recpt
                    where pol_no =x1.pol_no
                    and pol_run=x1.pol_run
                    --and v_lossdate  between fr_date and to_date
                    and rownum=1
                ) LOOP
                    v_cus_code := x2.cus_code ;
                END LOOP; --x2

                v_mascus_code := null;
                v_mascus_name := null;
                FOR x3 in (
                    select cus_code , cus_enq ,old_pol_no||old_pol_run old_policy
                    from mis_mas
                    where pol_no =x1.pol_no
                    and pol_run=x1.pol_run
                    --and v_lossdate  between fr_date and to_date
                    and rownum=1
                ) LOOP
                    v_mascus_code := x3.cus_code ;
                    v_mascus_name := x3.cus_enq ;
                    v_old_pol := x3.old_policy ; 
                END LOOP; --x3
                                                            
                BEGIN
                INSERT INTO NC_GET_POLICY_TMP (  SID , POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME ,
                  CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE ,OLD_POLICY )
                VALUES (    V_SID ,x1.pol_no||x1.pol_run ,x1.fleet_seq ,v_mascus_code , v_mascus_name, x1.title ,x1.name ,x1.surname ,
                    v_cus_code ,x1.id ,x1.end_seq, x1.recpt_seq ,x1.fr_date ,x1.to_date  ,v_old_pol
                )           ;
                EXCEPTION
                    WHEN OTHERS THEN
                    dbms_output.put_line('error insert NC_GET_POLICY_TMP :: '||sqlerrm);     
                    return 'E'; 
                END;               
                        
               /*  get Coverage*/ 
               IF vFlag in ('Y','E') THEN
               NC_HEALTH_PACKAGE.GET_COVER_PA (x1.pol_no,x1.pol_run,x1.fleet_seq ,x1.recpt_seq ,v_lossdate, null ,
                                                  c2 ,tSts1 );   
                      
                if tSts1 is null then
                    x_chkmotor := false;     
                    LOOP
                       FETCH  c2 INTO j_rec2;
                        EXIT WHEN c2%NOTFOUND;
                            --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                            if IS_CHECK_MOTORCYCLE(j_rec2.premcode) then
                                x_chkmotor := true;                                                 
                            end if;
                    END LOOP;  
                end if;

               NC_HEALTH_PACKAGE.GET_COVER_PA (x1.pol_no,x1.pol_run,x1.fleet_seq ,x1.recpt_seq ,v_lossdate, null ,
                                                  c2 ,tSts1 );                       
               dbms_output.put_line('Msg==>'||tSts1);
                if tSts1 is null then
                
                    LOOP
                       FETCH  c2 INTO j_rec2;
                        EXIT WHEN c2%NOTFOUND;
                            --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                            x_cover_flag   := null;
                            x_cover_remark := null;
                            if 1=1 then
                                dbms_output.put_line('Prem==>'|| 
                                 j_rec2.premcode||' '||NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec2.premcode ,'T')||
                                 ' SUMINS:'||
                                  j_rec2.sumins||
                                  ' COL:'||
                                  j_rec2.premcol
                                );
                                    if x_chkmotor and IS_CHECK_ACCUM(j_rec2.premcode) then
                                        x_cover_flag := 'MC' ;
                                        x_cover_remark := 'คุ้มครองมอเตอร์ไซ';
                                    else
                                        x_cover_flag   := null;
                                        x_cover_remark := null;
                                    end if;

                                    if MISC.HEALTHUTIL.is_45plus(x1.pol_no,x1.pol_run) and IS_CHECK_ACCUM(j_rec2.premcode)  then
                                        dbms_output.put_line('45Plus Remark happen.') ;
                                        x_cover_remark := x_cover_remark ||' ; '||replace(replace(MISC.HEALTHUTIL.get_benefit_card_45plus(x1.pol_no,x1.pol_run,x1.fleet_seq,x1.recpt_seq),'<br />',''),'-','') ;
                                    end if;
                                                                        
                                    BEGIN
                                    INSERT INTO NC_GET_COVER_TMP ( SID ,BENE_CODE ,DESCR ,REMARK ,FLAG ,AMOUNT )
                                    VALUES (    V_SID ,j_rec2.premcode ,NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec2.premcode ,'T') , x_cover_remark , x_cover_flag 
                                    ,j_rec2.sumins
                                    )           ;
                                    EXCEPTION
                                        WHEN OTHERS THEN
                                        dbms_output.put_line('error insert NC_GET_COVER_TMP :: '||sqlerrm);     
                                        return 'E'; 
                                    END;                                             
                            end if;
                    END LOOP;    
                  end if;   
               ELSE
                   null;                                   
               END IF; 
                                              
            END LOOP; -- x1

            --dbms_output.put_line('=======v_SID := '||v_SID);       
              COMMIT;
              rSID := v_SID;     return vFlag;            
        --****** End Flag E for check TELE         
        ELSE
            return vFlag;
        END IF; -- check Result check Policy  vFlag 
        dbms_output.put_line('==========================');    
    END; -- GET_POLICY_BY_POL
                                
    FUNCTION GET_POLICY_BY_ID(vIDNO IN VARCHAR2 ,vLOSS_DATE IN VARCHAR2  ,vFlag IN VARCHAR2 ,rSID OUT NUMBER) RETURN VARCHAR2 IS -- Y = คุ้มครอง N = ไม่คุ้มครอง , E = ไม่พบหรืออื่นๆ , M = many  Policy 
         c1   HEALTHUTIL.sys_refcursor;
        TYPE t_data1 IS RECORD
        (
            POLICY_NO VARCHAR2(30) ,
            PROD_TYPE VARCHAR2(200) 
        ); 
        j_rec1 t_data1; 

        c2   NC_HEALTH_PACKAGE.v_ref_cursor1;  
        
        tSts1 varchar2(200):=null;
        TYPE t_data2 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        SUMINS  NUMBER,
        PREMCOL NUMBER
        ); 
        j_rec2 t_data2;  
                 
        rst varchar2(200);
        v_return    varchar2(1);
        v_SID number;
        v_cus_code  varchar2(30);
        v_mascus_code  varchar2(30);
        v_mascus_name  varchar2(200);
        v_polno varchar2(20);
        v_polrun    number(20);
        v_lossdate  date:=to_date(vLOSS_DATE , 'dd/mm/rrrr');
        r_chk_pol   varchar2(3);
        rst_chk_pol varchar2(200);    
        x_chkmotor  boolean := false;
        x_cover_flag    varchar2(10);
        x_cover_remark    varchar2(200);      
        v_old_pol varchar2(50);  
    BEGIN
       -- r_chk_pol := NC_HEALTH_PACKAGE.CHECK_POLICY_COVER(null ,vLOSS_DATE ,'X' ,null  ,vIDNO  ,rst_chk_pol);   
        
        --dbms_output.put_line('CheckPol sts:'||r_chk_pol||' result:'||rst_chk_pol);     
        
        IF vFlag in ('Y','M') THEN
        
            MISC.HEALTHUTIL.get_policy_by_id(vIDNO ,v_lossdate ,c1);
                                 
            v_SID := NC_HEALTH_PACKAGE.GEN_SID;    
            dbms_output.put_line('SID:'||v_SID);       
            dbms_output.put_line('ID:'||vIDNO||' lossDate:'||vLOSS_DATE);
            
            LOOP
               FETCH  c1 INTO j_rec1;
                EXIT WHEN c1%NOTFOUND;
                    dbms_output.put_line('POLICY_NO==>'|| 
                     j_rec1.POLICY_NO||
                     ' PROD_TYPE: '||
                     j_rec1.PROD_TYPE                                                               
                    );    
                                
                    p_acc_package.read_pol(j_rec1.policy_no ,v_polno ,v_polrun);

                    --if x_type in ('PI','PG') then -- check is disallow for open claim e.g. CTA
                        if nc_health_package.is_disallow_policy(v_polno,v_polrun) then
                             return 'E'; 
                        end if;    
                    --end if;
                                
                    FOR x1 in (
                        select pol_no ,pol_run ,recpt_seq ,fleet_seq ,min(end_seq) end_seq ,id ,title ,name ,surname ,fr_date ,to_date 
                        from mis_pa_prem a
                        where pol_no =v_polno
                        and pol_run=v_polrun
                        and v_lossdate  between fr_date and to_date
                        and id = vIDNO
                        and cancel is null
                        and recpt_seq in (select max(aa.recpt_seq) from mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run =a.pol_run
                        and v_lossdate between aa.fr_date and aa.to_date and id= vIDNO and cancel is null)
                        group by pol_no ,pol_run ,recpt_seq ,fleet_seq  ,id ,title ,name ,surname ,fr_date ,to_date 
                        ) LOOP
                                    
                        v_cus_code := null;
                        FOR x2 in (
                            select cus_code
                            from mis_recpt
                            where pol_no =x1.pol_no
                            and pol_run=x1.pol_run
                            and v_lossdate  between fr_date and to_date
                            and rownum=1
                        ) LOOP
                            v_cus_code := x2.cus_code ;
                        END LOOP; --x2

                        v_mascus_code := null;
                        v_mascus_name := null;
                        FOR x3 in (
                            select cus_code , cus_enq ,old_pol_no||old_pol_run old_policy
                            from mis_mas
                            where pol_no =x1.pol_no
                            and pol_run=x1.pol_run
                            and v_lossdate  between fr_date and to_date
                            and rownum=1
                        ) LOOP
                            v_mascus_code := x3.cus_code ;
                            v_mascus_name := x3.cus_enq ;
                            v_old_pol := x3.old_policy ;
                        END LOOP; --x3
                                                            
                        BEGIN
                        INSERT INTO NC_GET_POLICY_TMP (  SID , POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME ,
                          CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE ,OLD_POLICY )
                        VALUES (    V_SID ,x1.pol_no||x1.pol_run ,x1.fleet_seq ,v_mascus_code , v_mascus_name, x1.title ,x1.name ,x1.surname ,
                            v_cus_code ,x1.id ,x1.end_seq, x1.recpt_seq ,x1.fr_date ,x1.to_date ,v_old_pol
                        )           ;
                        EXCEPTION
                            WHEN OTHERS THEN
                            dbms_output.put_line('error insert NC_GET_POLICY_TMP :: '||sqlerrm);     
                            return 'E'; 
                        END;               
                        
                       /*  get Coverage*/ 
                       IF vFlag in ('Y') THEN
                       NC_HEALTH_PACKAGE.GET_COVER_PA (x1.pol_no,x1.pol_run,x1.fleet_seq,x1.recpt_seq ,v_lossdate , null ,
                                                          c2 ,tSts1 );   
                              
                        if tSts1 is null then
                            x_chkmotor := false;     
                            LOOP
                               FETCH  c2 INTO j_rec2;
                                EXIT WHEN c2%NOTFOUND;
                                    --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                                    if IS_CHECK_MOTORCYCLE(j_rec2.premcode) then
                                        x_chkmotor := true;                                                 
                                    end if;
                            END LOOP;  
                        end if;
                
                       NC_HEALTH_PACKAGE.GET_COVER_PA (x1.pol_no,x1.pol_run,x1.fleet_seq ,x1.recpt_seq ,v_lossdate , null ,
                                                          c2 ,tSts1 );   

                              dbms_output.put_line('Msg==>'||tSts1);
                        if tSts1 is null then
                            
                            LOOP
                               FETCH  c2 INTO j_rec2;
                                EXIT WHEN c2%NOTFOUND;
                                    --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                                    x_cover_flag   := null;
                                    x_cover_remark := null;
                                    if 1=1 then
                                        dbms_output.put_line('Prem==>'|| 
                                         j_rec2.premcode||' '||NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec2.premcode ,'T')||
                                         ' SUMINS:'||
                                          j_rec2.sumins||
                                          ' COL:'||
                                          j_rec2.premcol
                                        );
                                            if x_chkmotor and IS_CHECK_ACCUM(j_rec2.premcode) then
                                                x_cover_flag := 'MC' ;
                                                x_cover_remark := 'คุ้มครองมอเตอร์ไซ';
                                            else
                                                x_cover_flag   := null;
                                                x_cover_remark := null;
                                            end if;
                                            BEGIN
                                            INSERT INTO NC_GET_COVER_TMP ( SID ,BENE_CODE ,DESCR ,REMARK ,FLAG ,AMOUNT )
                                            VALUES (    V_SID ,j_rec2.premcode ,NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec2.premcode ,'T') , x_cover_remark , x_cover_flag 
                                            ,j_rec2.sumins
                                            )           ;
                                            EXCEPTION
                                                WHEN OTHERS THEN
                                                dbms_output.put_line('error insert NC_GET_COVER_TMP :: '||sqlerrm);     
                                                return 'E'; 
                                            END;                                             
                                    end if;
                              end loop;    
                          end if;   
                       ELSE
                           null;                                   
                       END IF; --END vFlag in ('Y')
                                              
                    END LOOP; -- x1
              END LOOP;    
            --dbms_output.put_line('=======v_SID := '||v_SID);       
              COMMIT;
              rSID := v_SID;     return vFlag;
        ELSE
            return vFlag;
        END IF; -- check Result check Policy  vFlag 
        dbms_output.put_line('==========================');    
    END; -- GET_POLICY_BY_ID

    FUNCTION GET_POLICY_BANCAS(vIDNO IN VARCHAR2 ,vLOSS_DATE IN VARCHAR2 ,rSID OUT NUMBER) RETURN VARCHAR2 IS -- Y = คุ้มครอง N = ไม่คุ้มครอง , E = ไม่พบหรืออื่นๆ , M = many  Policy 
        c1   HEALTHUTIL.sys_refcursor;  
        c2   HEALTHUTIL.sys_refcursor;
        
        TYPE t_data1 IS RECORD
        (
        CODE    VARCHAR2(10),
        DESCR  VARCHAR2(200),
        MAX_DAY NUMBER ,
        SUB_AGR_AMT NUMBER ,
        MAX_AMT NUMBER
        ); 
        j_rec1 t_data1;         
        
        TYPE t_data2 IS RECORD
        (
        ID_CARD    VARCHAR2(30),
        CUS_NAME  VARCHAR2(200),
        PREM NUMBER ,
        FR_DATE DATE ,
        TO_DATE DATE 
        ); 
        j_rec2 t_data2; 
                  
        v_idcard    varchar2(30):= vIDNO ; --'3650800965140' ;
        v_lossdate  date:= to_date(vLOSS_DATE , 'dd/mm/rrrr'); 
        i_prem  number;
        v_SID   number;
        v_cusname   varchar2(200);
        v_fr_date   date;
        v_to_date   date;
        x_chkmotor  boolean := false;
        x_cover_flag    varchar2(10);
        x_cover_remark    varchar2(200);        
    BEGIN
        dbms_output.put_line('============ begin get BANCAS POL =========');
    
        dbms_output.put_line('ID:'||vIDNO||' lossDate:'||vLOSS_DATE);    
        if  HEALTHUTIL.GET_COUNT_POLICY_BY_ID_BANCAS (v_idcard,v_lossdate )  <1 then
            dbms_output.put_line('not found bancas Policy');
            
            rSID := 0;
            return 'N';
        end if;
            
        begin
            HEALTHUTIL.GET_POLICY_BY_ID_BANCAS (v_idcard , v_lossdate ,c2 );
        LOOP
           FETCH  c2 INTO j_rec2;
            EXIT WHEN c2%NOTFOUND;
                dbms_output.put_line('ID_CARD==>'|| 
                 j_rec2.ID_CARD||
                 ' CUS_NAME:'||
                  j_rec2.CUS_NAME||
                 ' PREM:'||
                  j_rec2.PREM                                 
                );    
                i_prem := j_rec2.PREM ; 
                v_cusname := j_rec2.cus_name ;
          END LOOP;             
        exception
            when others then
            dbms_output.put_line('error GET_POLICY_BY_ID_BANCAS : '||sqlerrm);
            rSID := 0;
            return 'E';
        end;
        
        FOR x2 in (
            select distinct a.ref_no1 id_card,  a.cus_name ,a.amount prem
            , pay_date +1 fr_date ,pay_date + 366 to_date
            from acc_file_data a  -- table ที่ทางการเงินรับข้อมูลของ bancas มาก่อนออก Policy -- 
            where file_type = '02' and file_format = '002' and receive_from = '04'
            and  v_idcard =  ref_no1
            and  nvl(v_lossdate,trunc(sysdate)) between  pay_date + 1  and pay_date + 366
        ) LOOP
            v_fr_date := x2.fr_date ; 
            v_to_date := x2.to_date ; 
        END LOOP; --x2        
        
        v_SID := NC_HEALTH_PACKAGE.GEN_SID;    
        dbms_output.put_line('SID:'||v_SID);   
        rSID := v_SID;
        BEGIN
        INSERT INTO NC_GET_POLICY_TMP (  SID , POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME ,
          CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE )
        VALUES (    V_SID ,'BANCAS_NOPOLICY' ,0 ,0 , null, null ,v_cusname ,null ,
            null , v_idcard  , 0 , 0 , v_fr_date , v_to_date
        )           ;
        EXCEPTION
            WHEN OTHERS THEN
            dbms_output.put_line('error insert NC_GET_POLICY_TMP :: '||sqlerrm);     
            ROLLBACK;
            rSID := 0;
            return 'E'; 
        END;          

        HEALTHUTIL.GET_COVERAGE_BANCAS (i_prem ,c1) ;

        x_chkmotor := false;     
        LOOP
           FETCH  c1 INTO j_rec1;
            EXIT WHEN c1%NOTFOUND;
                if IS_CHECK_MOTORCYCLE(j_rec1.code) then
                    x_chkmotor := true;                                                 
                end if;
        END LOOP;  
       
        HEALTHUTIL.GET_COVERAGE_BANCAS (i_prem ,c1) ;                         
        LOOP
           FETCH  c1 INTO j_rec1;
            EXIT WHEN c1%NOTFOUND;
                dbms_output.put_line('Prem==>'|| 
                 j_rec1.code||
                 ' DESCR:'||
                  j_rec1.DESCR||
                 ' SUB_AGR_AMT:'||
                  j_rec1.SUB_AGR_AMT||
                 ' MAX_AMT:'||
                  j_rec1.MAX_AMT                                   
                );   
                if x_chkmotor and IS_CHECK_ACCUM(j_rec1.code) then
                    x_cover_flag := 'MC' ;
                    x_cover_remark := 'คุ้มครองมอเตอร์ไซ';
                else
                    x_cover_flag   := null;
                    x_cover_remark := null;
                end if;
                
                BEGIN
                INSERT INTO NC_GET_COVER_TMP ( SID ,BENE_CODE ,DESCR ,REMARK ,FLAG ,AMOUNT )
                VALUES (    V_SID ,j_rec1.code ,j_rec1.DESCR , x_cover_remark , x_cover_flag 
                ,j_rec1.SUB_AGR_AMT
                )           ;
                EXCEPTION
                    WHEN OTHERS THEN
                    dbms_output.put_line('error insert NC_GET_COVER_TMP :: '||sqlerrm);     
                    ROLLBACK;
                    return 'E'; 
                END;                      
          END LOOP;      
          COMMIT;
          
          return 'Y';
        dbms_output.put_line('==========================');    
    exception
        when others then
            dbms_output.put_line('error GET_POLICY_BANCAS: '||sqlerrm);        
            rSID := 0;
            ROLLBACK;
            return 'E';
    END; -- GET_POLICY_BANCAS
        
    FUNCTION CHECK_POLICY_MAIN(vPOLICY IN VARCHAR2 ,vLOSS_DATE IN VARCHAR2 ,vRecpt IN VARCHAR2 ,vFLEET IN VARCHAR2  ,vIDNO IN VARCHAR2  ,P_POLICY OUT v_ref_cursor1 ,P_COVER OUT v_ref_cursor2 ,RST OUT VARCHAR2) RETURN VARCHAR2 IS
        r_chk_main  varchar2(2);
        rst_chk_main  varchar2(200);
        r_chk_pol  varchar2(2);
        r_chk_bancas varchar2(2);
        r_SID   NUMBER;
        v_polno varchar2(20);
        v_polrun    number(20);
        is_telep    varchar2(10);                
    BEGIN
        --dbms_output.put_line('pol:'||vPOLICY||' fleet:'||vFLEET||' Tloss_date:'||vLOSS_DATE );
        --vFLEET := nvl(vFLEET ,0);
        if vPOLICY is not null then
            r_chk_main := NC_HEALTH_PACKAGE.CHECK_POLICY_COVER(vPOLICY  ,vLOSS_DATE  ,vRecpt , nvl(vFLEET ,0) ,null  ,rst_chk_main ); 
            dbms_output.put_line('check by Policy CHECK_POLICY_COVER ==> return:'||r_chk_main||' result:'||rst_chk_main); 
            r_chk_pol := NC_HEALTH_PACKAGE.GET_POLICY_BY_POL(vPOLICY ,vLOSS_DATE  ,vRecpt , nvl(vFLEET ,0) ,r_chk_main ,r_SID);
            dbms_output.put_line('check by Policy GET_POLICY_BY_POL ==> return:'||r_chk_pol||' SID='||r_SID);
            
            p_acc_package.read_pol(vPOLICY ,v_polno ,v_polrun);
            is_telep := HEALTHUTIL.IS_TELE(v_polno ,v_polrun); 
            
            dbms_output.put_line('is_tele: '||is_telep);
--            IF nvl(is_telep ,'N') <> 'Y' THEN --** ถ้าไม่ใช่งาน TELE ให้คง process เดิม
--                return vFlag ;
--            END IF; 
                        
            IF r_chk_pol in ('M') THEN
                OPEN P_POLICY FOR
                SELECT DISTINCT POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME , CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE ,OLD_POLICY
                FROM NC_GET_POLICY_TMP WHERE SID = r_SID ;       
                
                OPEN P_COVER FOR
                SELECT '' BENE_CODE ,'' DESCR ,'' REMARK ,'' FLAG ,null AMOUNT
                FROM DUAL ;                                      
                
                DELETE NC_GET_POLICY_TMP WHERE SID = r_SID ;
                COMMIT; 
                
                return r_chk_pol;     
            ELSIF r_chk_pol in ('Y','N') THEN
                OPEN P_POLICY FOR
                SELECT DISTINCT POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME , CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE ,OLD_POLICY
                FROM NC_GET_POLICY_TMP WHERE SID = r_SID ;
                                          
                OPEN P_COVER FOR
                SELECT BENE_CODE ,DESCR ,REMARK ,FLAG ,AMOUNT
                FROM NC_GET_COVER_TMP WHERE SID = r_SID ;     
                
                DELETE NC_GET_POLICY_TMP WHERE SID = r_SID ;
                DELETE NC_GET_COVER_TMP WHERE SID = r_SID ;       
                COMMIT;
                
                return r_chk_pol;     
            ELSIF   r_chk_pol in ('E')  and nvl(is_telep ,'N') = 'Y' THEN
                OPEN P_POLICY FOR
                SELECT DISTINCT POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME , CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE ,OLD_POLICY
                FROM NC_GET_POLICY_TMP WHERE SID = r_SID ;
                                          
                OPEN P_COVER FOR
                SELECT BENE_CODE ,DESCR ,REMARK ,FLAG ,AMOUNT
                FROM NC_GET_COVER_TMP WHERE SID = r_SID ;     
                
                DELETE NC_GET_POLICY_TMP WHERE SID = r_SID ;
                DELETE NC_GET_COVER_TMP WHERE SID = r_SID ;       
                COMMIT;
                
                return r_chk_pol;                
            ELSE -- not found or error
                OPEN P_POLICY FOR
                SELECT '' POLICY_NO , null FLEET_SEQ , '' MAS_CUS_CODE , '' MAS_CUS_NAME,  '' TITLE ,'' NAME , '' SURNAME , '' CUS_CODE , '' IDCARD_NO  , null END_SEQ , null RECPT_SEQ , null EFF_DATE , null EXP_DATE ,null OLD_POLICY
                FROM DUAL ;
                                          
                OPEN P_COVER FOR
                SELECT '' BENE_CODE ,'' DESCR ,'' REMARK ,'' FLAG ,null AMOUNT
                FROM DUAL ;                 
                
                RST := rst_chk_main;
                return r_chk_pol; 
            END IF;
        elsif vIDNO  is not null then
            r_chk_main := NC_HEALTH_PACKAGE.CHECK_POLICY_COVER(null  ,vLOSS_DATE  ,vRecpt , nvl(vFLEET ,0) ,vIDNO  ,rst_chk_main ); 
            
            r_chk_pol := NC_HEALTH_PACKAGE.GET_POLICY_BY_ID(vIDNO ,vLOSS_DATE ,r_chk_main ,r_SID);
            IF r_chk_pol in ('M') THEN
                OPEN P_POLICY FOR
                SELECT DISTINCT POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME , CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE ,OLD_POLICY
                FROM NC_GET_POLICY_TMP WHERE SID = r_SID ;       
                
                OPEN P_COVER FOR
                SELECT '' BENE_CODE ,'' DESCR ,'' REMARK ,'' FLAG ,null AMOUNT
                FROM DUAL ;                                      
                
                DELETE NC_GET_POLICY_TMP WHERE SID = r_SID ;
                COMMIT; 
                
                return r_chk_pol;     
            ELSIF r_chk_pol in ('Y') THEN
                OPEN P_POLICY FOR
                SELECT DISTINCT POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME , CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE ,OLD_POLICY
                FROM NC_GET_POLICY_TMP WHERE SID = r_SID ;
                                          
                OPEN P_COVER FOR
                SELECT BENE_CODE ,DESCR ,REMARK ,FLAG ,AMOUNT
                FROM NC_GET_COVER_TMP WHERE SID = r_SID ;     
                
                DELETE NC_GET_POLICY_TMP WHERE SID = r_SID ;
                DELETE NC_GET_COVER_TMP WHERE SID = r_SID ;       
                COMMIT;
                
                return r_chk_pol;     
            ELSE -- not found or error  == เตรียม BANCAS ต่อ 
                dbms_output.put_line('::::: in check BANCAS :::::::::');
                r_chk_bancas := NC_HEALTH_PACKAGE.GET_POLICY_BANCAS(vIDNO ,vLOSS_DATE , r_sid);

                if r_chk_bancas = 'Y' then
                    OPEN P_POLICY FOR
                    SELECT DISTINCT POLICY_NO , FLEET_SEQ , MAS_CUS_CODE , MAS_CUS_NAME,  TITLE ,NAME , SURNAME , CUS_CODE , IDCARD_NO  , END_SEQ , RECPT_SEQ , EFF_DATE , EXP_DATE ,OLD_POLICY
                    FROM NC_GET_POLICY_TMP WHERE SID = r_SID ;
                                              
                    OPEN P_COVER FOR
                    SELECT BENE_CODE ,DESCR ,REMARK ,FLAG ,AMOUNT
                    FROM NC_GET_COVER_TMP WHERE SID = r_SID ;     
                    
                    DELETE NC_GET_POLICY_TMP WHERE SID = r_SID ;
                    DELETE NC_GET_COVER_TMP WHERE SID = r_SID ;       
                    COMMIT;                
                else
                    OPEN P_POLICY FOR
                    SELECT '' POLICY_NO , null FLEET_SEQ , '' MAS_CUS_CODE , '' MAS_CUS_NAME,  '' TITLE ,'' NAME , '' SURNAME , '' CUS_CODE , '' IDCARD_NO  , null END_SEQ , null RECPT_SEQ , null EFF_DATE , null EXP_DATE , null OLD_POLICY
                    FROM DUAL ;
                                              
                    OPEN P_COVER FOR
                    SELECT '' BENE_CODE ,'' DESCR ,'' REMARK ,'' FLAG ,null AMOUNT
                    FROM DUAL ;                              
                end if;    
                
                RST := null;
                return r_chk_bancas; 
            END IF;
            
        else
            OPEN P_POLICY FOR
            SELECT '' POLICY_NO , null FLEET_SEQ , '' MAS_CUS_CODE , '' MAS_CUS_NAME,  '' TITLE ,'' NAME , '' SURNAME , '' CUS_CODE , '' IDCARD_NO  , null END_SEQ , null RECPT_SEQ , null EFF_DATE , null EXP_DATE ,null OLD_POLICY
            FROM DUAL ;
                                          
            OPEN P_COVER FOR
            SELECT '' BENE_CODE ,'' DESCR ,'' REMARK ,'' FLAG ,null AMOUNT
            FROM DUAL ;                
            RST := 'กรุณาระบุ Policy หรือ ID Card No.'; return 'E';
        end if;
        
        
    END; --CHECK_POLICY_MAIN
      
    FUNCTION CHECK_POLICY_COVER(vPOLICY IN VARCHAR2 ,vLOSS_DATE IN VARCHAR2 ,vRecpt IN VARCHAR2 ,vFLEET IN VARCHAR2 ,vIDNO IN VARCHAR2  ,RST OUT VARCHAR2) RETURN VARCHAR2 IS  
    -- Y = คุ้มครอง N = ไม่คุ้มครอง , E = ไม่พบหรืออื่นๆ , M = พบมากกว่า 1 policy
        vPOl_no varchar2(20);
        vPOL_RUN    number;
        TLoss_date  Date;
        vPolType    varchar2(10);
        Trecpt  number;
        v_status_active varchar2(10);
        cnt_id_pol  number;
        
        o_name   HEALTHUTIL.sys_refcursor;  
        cnt_covername   number:=1;
        TYPE t_data1 IS RECORD
        (
            NAME VARCHAR2(200) ,
            FLEET_SEQ NUMBER ,
            RECPT_SEQ NUMBER 
        ); 
        j_rec1 t_data1; 
        
        x_fleet number;
        pi_fleet    number;
        is_fleet_many boolean:= false;
    BEGIN
        IF vIDNO is not null THEN -- ตรวจสอบจาก ID CARD
            if vIDNO is null then
                RST := 'กรุณาระบุ ID Card No.'; return 'E';
            end if;   
            if vLoss_date is not null then
                Tloss_date  := to_date(vLoss_date ,'dd/mm/yyyy');
            else
                RST := 'กรุณาระบุ Loss Date'; return 'E';            
            end if;        
            cnt_id_pol := HEALTHUTIL.get_count_policy_by_id(vIDNO ,Tloss_date);
            
            if cnt_id_pol = 1 then
                 return 'Y';  
            elsif   cnt_id_pol > 1 then
                 RST := 'พบ ID Card No. มากกว่า 1 policy '; return 'M'; 
            else
                 RST := 'ไม่พบ ID Card No. ในช่วงความคุ้มครองนี้'; return 'E';
            end if;
            
        ELSE    --  ตรวจจาก policy
            if vPOLICY is not null then
                p_acc_package.read_pol(vPOLICY ,vPol_no ,vPol_run);
            else
                RST := 'กรุณาระบุ Policy No.'; return 'E';
            end if;   
            if vLoss_date is not null then
                Tloss_date  := to_date(vLoss_date ,'dd/mm/yyyy');
            else
                RST := 'กรุณาระบุ Loss Date'; return 'E';            
            end if;
            HEALTHUTIL.get_pa_health_type(vPol_no ,vPol_run ,vPolType) ; 
            dbms_output.put_line('PolType='||vPolType);
            
            if vPolType in ('PI','PG') then -- check is disallow for open claim e.g. CTA
                if nc_health_package.is_disallow_policy(vPol_no,vPol_run) then
                     vPolType := 'XX' ;
                end if;    
                if nc_health_package.is_watchlist_policy(vPol_no,vPol_run) then
                     vPolType := 'XX' ;
                end if;                  
            end if;            
            
            IF vPolType in ('PI','PG') THEN
                Trecpt := 0;
                if vPolType = 'PI' then -- ถ้าเป็นเดี่ยวแล้วใส่ fleet_seq = 1 ไป จะไม่พบข้อมูลแปลกมั่กๆ 
--                    dbms_output.put_line('pol:'||vPol_no||vPol_run||' fleet:'||0||' Tloss_date:'||Tloss_date||' recpt_seq:'||vRecpt );
--                    HEALTHUTIL.get_name_cover(vPol_no ,vPol_run ,0 ,Tloss_date ,o_name) ;                
                    dbms_output.put_line('pol:'||vPol_no||vPol_run||' fleet:'||vFleet||' Tloss_date:'||Tloss_date||' recpt_seq:'||vRecpt );
                    HEALTHUTIL.get_name_cover(vPol_no ,vPol_run ,vFleet ,Tloss_date ,o_name) ;
                else
                    dbms_output.put_line('pol:'||vPol_no||vPol_run||' fleet:'||vFleet||' Tloss_date:'||Tloss_date||' recpt_seq:'||vRecpt );
                    HEALTHUTIL.get_name_cover(vPol_no ,vPol_run ,vFleet ,Tloss_date ,o_name) ;
                end if;     
                
                LOOP
                FETCH  o_name INTO j_rec1;
                EXIT WHEN o_name%NOTFOUND;
                    if cnt_covername = 1 then x_fleet := j_rec1.FLEET_SEQ; end if;
                    cnt_covername := cnt_covername+1;
                    dbms_output.put_line('x NAME==>'|| 
                     j_rec1.NAME||
                     ' FLEET: '||
                     j_rec1.FLEET_SEQ||
                     ' RECPT:'||
                      j_rec1.RECPT_SEQ                                                             
                    );    
                    if  x_fleet <> j_rec1.FLEET_SEQ then 
                        is_fleet_many := true; 
                    end if;
                    
                    if Trecpt < j_rec1.RECPT_SEQ then
                        Trecpt :=  j_rec1.RECPT_SEQ ;
                    end if;
                END LOOP;    

                if vRecpt is not null then
                    Trecpt := vRecpt ;
                end if;
                                                  
                if cnt_covername > 1 then 
                    if is_fleet_many then
                        RST := 'found many policy' ; return 'M'; 
                    end if;
                    dbms_output.put_line('GET GET_COUNT_NAME ACTIVE==>'||HEALTHUTIL.GET_COUNT_NAME(vPol_no ,vPol_run ,vFleet) );
                    if vFleet > 0 and  vRecpt is null  then
                        if HEALTHUTIL.GET_COUNT_NAME(vPol_no ,vPol_run ,vFleet) > 1 then
                            RST := 'found many policy' ; return 'M'; 
                        end if;
                    end if;
                end if;
                              
                HEALTHUTIL.GET_STATUS_ACTIVE(vPol_no ,vPol_run ,vFLEET , Trecpt ,Tloss_date ,v_status_active) ;
                dbms_output.put_line('Param: fleet='||vFLEET||' Trecpt='||Trecpt||' Tloss_date='||Tloss_date);
                dbms_output.put_line('GET STATUS ACTIVE==>'||v_status_active);
                return v_status_active;
            ELSIF vPolType = 'XX' THEN
                RST := 'ไม่พบข้อมูล '; return 'E';  
            ELSE
                RST := 'กรมธรรม์ที่ระบุ ไม่อยู่ในกลุ่มงาน PA '; return 'E';  
            END IF;
        END IF;

        --RETURN 'Y';
    EXCEPTION               
           when others then 
            --dbms_output.put_line('error==>'||sqlerrm);
            RST := 'ERROR ';
            --OPEN P_NOTICE_DATA  FOR SELECT 0 sts_key ,'' clm_no ,'' pol_no ,0 pol_run ,0 fleet_seq , '' reg_date ,'' loss_date ,'' hpt_code FROM DUAL;
            return 'E';         
    END; -- END CHECK_POLICY_COVER  ,FAX TPA
    
    FUNCTION GET_NOTICE_DATA(vSTS_KEY IN NUMBER, vHPT_CODE IN VARCHAR2 ,P_NOTICE_DATA OUT v_ref_cursor4) RETURN VARCHAR2 is  -- 0 Complete , 5 Error or not found
        c1   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data1 IS RECORD
        (
        STS_KEY  NC_MAS.STS_KEY%TYPE ,
        CLM_NO NC_MAS.CLM_NO%TYPE ,
        POL_NO NC_MAS.POL_NO%TYPE ,
        POL_RUN NC_MAS.POL_RUN%TYPE ,
        FLEET_SEQ NC_MAS.FLEET_SEQ%TYPE ,
        REG_DATE NC_MAS.REG_DATE%TYPE ,
        LOSS_DATE VARCHAR2(10) ,
        HPT_CODE NC_MAS.HPT_CODE%TYPE 
        ); 
        j_rec1 t_data1; 
        v_rst   varchar2(100);
    BEGIN
        v_rst :=  NC_HEALTH_PACKAGE.CHECK_NOTICE_DATA(vSTS_KEY,vHPT_CODE);
        --dbms_output.put_line('CHECK_NOTICE==>'||V_RST||':::  length='|| length(v_rst) );
        if nvl(v_rst,'0') = '0' then
           OPEN P_NOTICE_DATA  FOR 
                select a.sts_key ,a.clm_no ,a.pol_no ,a.pol_run ,a.fleet_seq , a.reg_date ,to_char(a.loss_date,'dd/mm/rrrr') loss_date ,a.hpt_code,
                       a.pol_no||a.pol_run policy_no, a.recpt_seq, a.id_no
                from nc_mas a ,nc_status b
                where a.sts_key = B.STS_KEY 
                and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type='MEDSTS' )
                and a.sts_key = vSTS_KEY
                and a.hpt_code = vHPT_CODE
                and sts_sub_type = 'MEDSTS04';        
             --dbms_output.put_line('found==>');   
             return '0';       
        else
            --dbms_output.put_line('not found notice==>');
            OPEN P_NOTICE_DATA  FOR SELECT 0 sts_key ,'' clm_no ,'' pol_no ,0 pol_run ,0 fleet_seq , '' reg_date ,'' loss_date ,'' hpt_code 
                 ,'' policy_no, '' recpt_seq, '' id_no FROM DUAL;
            return '5';
        end if;             
    EXCEPTION
           when no_data_found then 
            OPEN P_NOTICE_DATA  FOR SELECT 0 sts_key ,'' clm_no ,'' pol_no ,0 pol_run ,0 fleet_seq , '' reg_date ,'' loss_date ,'' hpt_code
                 ,'' policy_no, '' recpt_seq, '' id_no FROM DUAL;
            return '5';                  
           when others then 
            dbms_output.put_line('error==>'||sqlerrm);
            OPEN P_NOTICE_DATA  FOR SELECT 0 sts_key ,'' clm_no ,'' pol_no ,0 pol_run ,0 fleet_seq , '' reg_date ,'' loss_date ,'' hpt_code
                 ,'' policy_no, '' recpt_seq, '' id_no FROM DUAL;
            return '5';              
    END;  -- END GET_NOTICE_DATA
    
    FUNCTION CHECK_NOTICE_DATA(vSTS_KEY IN NUMBER, vHPT_CODE IN VARCHAR2) RETURN VARCHAR2 IS    
        --vReturn VARCHAR2(1000);
    BEGIN
        if NC_HEALTH_PACKAGE.IS_EXISTING_NOTICE (VSTS_KEY,vHPT_CODE) then
            if NC_HEALTH_PACKAGE.IS_NOT_EXPIRED_NOTICE (VSTS_KEY,vHPT_CODE) then
                return '';
            else
                return 'เลขรับแจ้ง:'||VSTS_KEY||' หมดอายุ กรุณาเปิดเรื่อง/เคลมใหม่ ';    
            end if;
        else
            return 'ไม่พบเลขรับแจ้ง:'||VSTS_KEY||' รอเปิดเคลม';    
        end if;     
    EXCEPTION
           when others then 
            return 'เกิดข้อผิดพลาด  กรุณาเปิดเรื่อง/เคลมใหม่ ';                  
    END;   -- CHECK_NOTICE_DATA
    
    FUNCTION GET_MED_REMARK(vSTS_KEY IN NUMBER,vTYPE  IN VARCHAR2) RETURN VARCHAR2 IS    -- vTYPE  D = Disapprove Fax 
        vRemark VARCHAR2(1000);
        vStatus  VARCHAR2(20);
    BEGIN
        if vTYPE = 'D' then
            begin
            select remark  into vRemark
            from nc_status a
            where sts_key=vSTS_KEY
            and sts_type = 'MEDSTS' and sts_sub_type in ( 'MEDSTS02' , 'MEDSTS32' )
            and sts_seq in ( select max(sts_seq) 
            from nc_status x
            where x.sts_key=a.sts_key
            and sts_type = 'MEDSTS' and sts_sub_type in ( 'MEDSTS02' , 'MEDSTS32' )
            )        ;
            exception
                when no_data_found then
                    vRemark := '';
                when others then 
                     vRemark := '';
            end;
            
            vStatus := GET_CLM_STATUS(vSTS_KEY) ;
            dbms_output.put_line('vStatus ==>'||vStatus);  
            if substr(vStatus,7,1) in ('1','2') then
                select a.paid_remark  into vRemark
                from mis_cpa_paid a
                where clm_no in (
                select x.clm_no from nc_mas x where x.sts_key = vSTS_KEY
                )   ;     
            end if;
            dbms_output.put_line('remark ==>'||vRemark);             
            return vRemark ;
        else
            return '';    
        end if;     
    EXCEPTION
           when no_data_found then 
            return '';                  
           when others then 
            return '';             
    END;   -- GET_MED_REMARK

    FUNCTION GET_LIST_CLM_ORDERBY(P_ORDERBY_LIST OUT v_ref_cursor4 ) RETURN VARCHAR2 is  -- 0 Complete , 5 Error or not found
        c1   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data1 IS RECORD
        (
        NAME    VARCHAR2(20) ,
        VALUE  VARCHAR2(20)
        ); 
        j_rec1 t_data1; 

    BEGIN
        --dbms_output.put_line('Search Name ==>'||v_searchname);  
           OPEN P_ORDERBY_LIST  FOR 
            select 'วันที่เปิดเคลม' NAME, 'REG_DATE' VALUE , 0 SEQ  from dual 
            union 
             select 'สถานะ' NAME, 'STS_SUB_TYPE' VALUE , 2 SEQ from dual 
            union 
            select 'วันที่รักษา' NAME, 'TR_DATE_FR' VALUE , 1 SEQ from dual 
            union 
            select 'ชื่อผู้เอาประกัน' NAME, 'CUS_NAME' VALUE , 3 SEQ from dual 
            union 
            select 'Invoice no.' NAME, 'INVOICE_NO' VALUE, 4 SEQ from dual 
            order by seq;   
                
            return '0';       
             CLOSE P_ORDERBY_LIST; 
    EXCEPTION
           when no_data_found then 
            OPEN P_ORDERBY_LIST  FOR SELECT '' NAME , '' VALUE FROM DUAL;
            return '5';           
            CLOSE P_ORDERBY_LIST;        
           when others then 
            OPEN P_ORDERBY_LIST  FOR SELECT '' NAME , '' VALUE FROM DUAL;
            return '5';  
            CLOSE P_ORDERBY_LIST;                        
    END;
          
    FUNCTION GET_HOSPITAL_LIST(vName IN VARCHAR2 ,P_HOSP_LIST OUT v_ref_cursor4 ) RETURN VARCHAR2 is  -- 0 Complete , 5 Error or not found
        c1   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data1 IS RECORD
        (
        HPT_CODE  acc_payee_detail.PAYEE_CODE%TYPE ,
        NAME_TH acc_payee_detail.NAME_TH%TYPE ,
        NAME_ENG acc_payee_detail.NAME_ENG%TYPE 
        ); 
        j_rec1 t_data1; 
        v_searchname varchar2(100);
    BEGIN
        v_searchname := NC_HEALTH_PACKAGE.UPDATE_SEARCH_NAME(vName) ;
        dbms_output.put_line('Search Name ==>'||v_searchname);  
           OPEN P_HOSP_LIST  FOR 
            select (select hosp_id  from med_hospital_list x  where x.payee_code =  a.payee_code and x.hosp_seq = a.payee_seq   and rownum =1) HPT_CODE ,NAME_TH ,NAME_ENG --,PAYEE_CODE
             from acc_payee_detail a
             --where (a.payee_code , a.payee_seq ) in (select x.payee_code ,max(x.payee_seq) from acc_payee_detail x where x.payee_code = a.payee_code and cancel_flag is null group by x.payee_code)
             where a.payee_seq>=1 
             and search_name like '%'||v_searchname||'%'
             and a.payee_code in (select x.payee_code from acc_payee x where x.payee_code = a.payee_code and payee_type = '06' and cancel is null);       
             return '0';       
             CLOSE P_HOSP_LIST; 
    EXCEPTION
           when no_data_found then 
            OPEN P_HOSP_LIST  FOR SELECT '' HPT_CODE , '' NAME_TH, '' NAME_ENG FROM DUAL;
            return '5';           
            CLOSE P_HOSP_LIST;        
           when others then 
            OPEN P_HOSP_LIST  FOR SELECT '' HPT_CODE , '' NAME_TH, '' NAME_ENG FROM DUAL;
            return '5';  
            CLOSE P_HOSP_LIST;                        
    END;
    
   FUNCTION GET_HOSPITAL_NAME(vPAYEECODE IN VARCHAR2 ,vTH_ENG IN VARCHAR2 ,vHPTCODE IN VARCHAR2 default null ) RETURN VARCHAR2 IS
    v_name varchar2(200);
   BEGIN
        if nvl(vTH_ENG ,'T') = 'T'  then 
            select name_t into v_name
            from MED_HOSPITAL_LIST a
            where payee_code = vPAYEECODE or nvl(vHPTCODE ,'%') like HOSP_ID;
        else
            select name_e into v_name
            from MED_HOSPITAL_LIST a
            where payee_code = vPAYEECODE or nvl(vHPTCODE ,'%') like HOSP_ID;        
        end if;
        
        return v_name ;
   EXCEPTION
           when no_data_found then 
            return '';               
           when others then    
            return '';      
   END;  -- GET_HOSPITAL_NAME

   FUNCTION GET_HOSPITAL_PAYEE(vHPTCODE IN VARCHAR2 , vHPTUSER IN VARCHAR2 default null) RETURN VARCHAR2 IS
    r_payee_code varchar2(200);
   BEGIN
        if vHPTUSER is null  then 
            select payee_code into r_payee_code
            from MED_HOSPITAL_LIST a
            where nvl(vHPTCODE ,'%') like HOSP_ID;
        else
            select payee_code into r_payee_code
            from MED_HOSPITAL_LIST a
            where  a.HOSP_ID in (
            select hosp_id
            from med_staff b
            where user_id = vHPTUSER);        
        end if;
        
        return r_payee_code ;
   EXCEPTION
           when no_data_found then 
            return '';               
           when others then    
            return '';      
   END;  -- GET_HOSPITAL_PAYEE
       
     FUNCTION get_new_benefit_code(i_bene_code IN VARCHAR2,i_th_eng  IN VARCHAR2) RETURN VARCHAR2 is
         o_new_bene_code  VARCHAR2(100);
     Begin
           if HEALTHUTIL.chk_cancel_benefit_code (i_bene_code,i_th_eng) is not null then  -- มีการ Cancel --
               begin
                   select new_bene_code 
                   into o_new_bene_code
                   from medical_ben_std
                   where bene_code = i_bene_code  and
                         th_eng    = i_th_eng;
               exception 
                   when no_data_found then 
                        o_new_bene_code := i_bene_code;                   
                   when others then 
                        o_new_bene_code := i_bene_code;           
               end;  
           else
              o_new_bene_code := i_bene_code;
           end if;     
           if o_new_bene_code is null then o_new_bene_code := i_bene_code; end if;
           return o_new_bene_code;         
     End; -- get_new_benefit_code;  

     FUNCTION get_benefit_descr(i_bene_code IN VARCHAR2,i_th_eng  IN VARCHAR2) RETURN VARCHAR2 is
         o_new_bene_code  VARCHAR2(200);
     Begin

           begin
               select descr 
               into o_new_bene_code
               from medical_ben_std
               where bene_code = i_bene_code  and
                     th_eng    = i_th_eng;
           exception 
               when no_data_found then 
                    o_new_bene_code := 'Not found benefit code';                   
               when others then 
                    o_new_bene_code := 'Not found benefit code';          
           end;  

           return o_new_bene_code;         
     End; -- get_benefit_descr;  

    FUNCTION CONVERT_CLM_STATUS(vSTATUS IN VARCHAR2) RETURN VARCHAR2 IS    
    
    BEGIN
        IF vSTATUS  in ('MEDSTS00','MEDSTS01','MEDSTS03','MEDSTS11')  THEN
            --return GET_CLM_STATUS_DESC(vSTATUS ,1 ) ;
            return 'Pending';
        ELSIF substr(vSTATUS , 1,6) = 'MEDSTS' THEN -- อื่นๆ นอกจากการเปิดเคลมบน MED 
            return GET_CLM_STATUS_DESC(vSTATUS ,1 ) ;
        ELSE
            IF vSTATUS in ('0','1') THEN
                --return 'เปิดเคลม';
                return 'Pending';
            ELSIF vSTATUS in ('6') THEN
                --return 'พิจารณาจ่ายเคลม';
                return 'Pending';
            ELSIF vSTATUS in ('2') THEN
                --return 'ปิดเคลม (จ่าย)';
                return 'Approved';
            ELSIF vSTATUS in ('3') THEN
                --return 'ปิดเคลม (ไม่จ่าย)';
                return 'Rejected';
            ELSIF vSTATUS in ('4') THEN
                --return 'reOpen claim';
                return 'Pending';
            ELSE
                return vSTATUS;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            return vSTATUS;
    END;    -- END CONVERT_CLM_STATUS for TPA

    FUNCTION GET_P_APPRV_FLAG(vSTS_KEY IN NUMBER, vPAY_NO IN VARCHAR2 ) RETURN VARCHAR2 IS
        v_sts   VARCHAR2(100);
    BEGIN
        select apprv_flag into v_sts
        from nc_payment a
        where sts_key =vSTS_KEY and pay_no = vPAY_NO
        and trn_seq in (select max(b.trn_seq) from nc_payment b where b.sts_key =a.sts_key and b.pay_no = a.pay_no );
        
        return v_sts;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return '';
        WHEN OTHERS THEN
            return '';
    END;    -- END GET_P_APPRV_FLAG
              
    FUNCTION GET_CLM_STATUS(vSTS_KEY IN NUMBER) RETURN VARCHAR2 IS
        v_sts   VARCHAR2(100);
    BEGIN
        select sts_sub_type into v_sts
        from nc_status b
        where B.STS_KEY = vSTS_KEY and b.sts_type = 'MEDSTS'
        and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type = 'MEDSTS');
        
        return v_sts;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return 'NOT FOUND STATUS';
        WHEN OTHERS THEN
            return 'NOT FOUND STATUS';
    END;    -- END Get status by STS_KEY

    FUNCTION GET_CLM_STATUS(vCLM_NO IN VARCHAR2) RETURN VARCHAR2 IS
        v_sts   VARCHAR2(100);
    BEGIN
        select sts_sub_type into v_sts
        from nc_mas a ,nc_status b
        where a.clm_no = vClm_no
        and a.sts_key = B.STS_KEY 
        and b.sts_type = 'MEDSTS'
        and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type = 'MEDSTS');
        
        return v_sts;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return 'NOT FOUND STATUS';
        WHEN OTHERS THEN
            return 'NOT FOUND STATUS';
    END;    -- END Get status by CLM_NO
    
    FUNCTION GET_CLM_STATUS_DESC(MED_STS IN VARCHAR2 ,SIDE IN NUMBER) RETURN VARCHAR2 IS
        v_sts   VARCHAR2(200);
    BEGIN  -- side 0 = BKI ,1 = HPT 
        IF SIDE = 0 THEN
            select remark into v_sts
            from clm_constant a
            where key = MED_STS ;
        ELSIF SIDE = 2 THEN
            select descr into v_sts
            from clm_constant a
            where key = MED_STS ;            
        ELSE
            select remark2 into v_sts
            from clm_constant a
            where key = MED_STS ;
        END IF;            
        return v_sts;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return 'NOT FOUND STATUS';
        WHEN OTHERS THEN
            return 'NOT FOUND STATUS';
    END;    -- END GET_CLM_STATUS_DESC      

    FUNCTION IS_EXISTING_STSKEY(vSTS_KEY IN NUMBER) RETURN BOOLEAN IS
        v_flag  varchar2(1):='N' ;
    BEGIN
        select 'Y' flag into v_flag
        from nc_status a
        where a.sts_key = vSTS_KEY and rownum=1;
        
        if v_flag = 'Y' then return true; else return false; end if;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return false;
        WHEN OTHERS THEN
            return false;
    END;    -- END IS_EXISTING_STSKEY
    
    FUNCTION IS_EXISTING_NOTICE(vSTS_KEY IN NUMBER, vHPT_CODE IN VARCHAR2) RETURN BOOLEAN IS
        v_flag  varchar2(1):='N' ;
    BEGIN
        select 'Y' flag into v_flag
        from nc_mas a ,nc_status b
        where a.sts_key = B.STS_KEY 
        and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type='MEDSTS' )
        and sts_sub_type = 'MEDSTS04'
        and a.hpt_code = vHPT_CODE
        and a.sts_key = vSTS_KEY;
        
        if v_flag = 'Y' then return true; else return false; end if;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return false;
        WHEN OTHERS THEN
            return false;
    END;    -- END IS_EXISTING_NOTICE

    FUNCTION IS_EXISTING_CLAIM(vSTS_KEY IN NUMBER) RETURN VARCHAR2 IS
        v_flag  varchar2(1):='N' ;
    BEGIN
        select 'Y' flag into v_flag
        from nc_mas a ,nc_status b
        where a.sts_key = B.STS_KEY 
        and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type='MEDSTS' )
        and sts_sub_type  in ( 'MEDSTS00' , 'MEDSTS11' , 'MEDSTS12') 
        and a.sts_key = vSTS_KEY;
        
        if v_flag = 'Y' then return  'Y'; else return 'N'; end if;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return  'N';
        WHEN OTHERS THEN
            return  'N';
    END;    -- END IS_EXISTING_CLAIM
    
    FUNCTION IS_NOT_EXPIRED_NOTICE(vSTS_KEY IN NUMBER, vHPT_CODE IN VARCHAR2) RETURN BOOLEAN IS
        v_regdate   date;
    BEGIN
        IF NOT NC_HEALTH_PACKAGE.IS_EXISTING_NOTICE(vSTS_KEY,vHPT_CODE) THEN
            return false;
        END IF;
        
        select trunc(a.reg_date) into v_regdate
        from nc_mas a ,nc_status b
        where a.sts_key = B.STS_KEY 
        and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type='MEDSTS' )
        and sts_sub_type = 'MEDSTS04'
        and a.hpt_code = vHPT_CODE
        and a.sts_key = vSTS_KEY;
        
        if (v_regdate+3) >= trunc(sysdate) then return true; else return false; end if;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return false;
        WHEN OTHERS THEN
            return false;
    END;    -- END IS_NOT_EXPIRED_NOTICE
        
    FUNCTION IS_CHECK_ACCUM(P_PREMCODE IN VARCHAR2) RETURN BOOLEAN IS
        v_flag  varchar2(1):='N' ;
    BEGIN
        select chk_accum into v_flag
        from nc_h_premcode
        where premcode = P_PREMCODE;
        
        if v_flag = 'Y' then return true; else return false; end if;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return false;
        WHEN OTHERS THEN
            return false;
    END;    -- END IS_CHECK_ACCUM

    FUNCTION IS_CHECK_PERTIME(P_PREMCODE IN VARCHAR2) RETURN BOOLEAN IS
        v_flag  varchar2(1):='N' ;
    BEGIN
    
        select chk_pertime into v_flag
        from nc_h_premcode
        where premcode = P_PREMCODE;
   /**/     
        if v_flag = 'Y' then return true; else return false; end if;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return false;
        WHEN OTHERS THEN
            return false;
    END;    -- END IS_CHECK_PERTIME
    
    FUNCTION IS_CHECK_TOTLOSS(P_PREMCODE IN VARCHAR2) RETURN BOOLEAN IS
        v_flag  varchar2(1):='N' ;
    BEGIN
    
        select chk_totloss into v_flag
        from nc_h_premcode
        where premcode = P_PREMCODE;
   /**/     
        if v_flag = 'Y' then return true; else return false; end if;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return false;
        WHEN OTHERS THEN
            return false;
    END;    -- END IS_CHECK_TOTLOSS    

    FUNCTION IS_CHECK_MOTORCYCLE(P_PREMCODE IN VARCHAR2) RETURN BOOLEAN IS
        v_flag  varchar2(1):='N' ;
    BEGIN
    
        select CHK_MOTORCYCLE_COVER into v_flag
        from nc_h_premcode
        where premcode = P_PREMCODE;
   /**/     
        if v_flag = 'Y' then return true; else return false; end if;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return false;
        WHEN OTHERS THEN
            return false;
    END;    -- END IS_CHECK_MOTORCYCLE    
    
    FUNCTION GET_MAXDAY(P_PREMCODE IN VARCHAR2) RETURN NUMBER IS
        v_max  number(5):=0;
    BEGIN
    
        select nvl(max_time ,0)  into v_max
        from nc_h_premcode
        where premcode = P_PREMCODE;
    /**/    
        if v_max  > 0 then return v_max; else return 0; end if;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            return 0;
        WHEN OTHERS THEN
            return 0;
    END;    -- END GET_MAXDAY
        
    FUNCTION GEN_STSKEY(PROD_TYPE IN VARCHAR2) RETURN NUMBER IS
        /* Prod_type ยังไม่ใช้ตอนนี้ เผื่ออนาคตแยกชุด key  */
        v_key  NUMBER;
    BEGIN    
--            BEGIN
--                select run_no+1 into v_key
--                from clm_control_std a
--                where key = 'NCSTSKEY' FOR UPDATE OF KEY ,RUN_NO;
--            EXCEPTION
--                WHEN  NO_DATA_FOUND THEN
--                    v_key := 0;            
--                WHEN  OTHERS THEN
--                    v_key := 0;
--            END;       
--                    
--           if v_key >0 then  
--            BEGIN
--                update clm_control_std a
--                set run_no = v_key
--                where key = 'NCSTSKEY' ;
--            EXCEPTION
--                WHEN  OTHERS THEN
--                    ROLLBACK;
--                    v_key := 0;
--            END;  
--            COMMIT;
--            end if;    
            BEGIN
                SELECT CLM_STS_KEY.NEXTVAL into v_key
                FROM dual;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_key := 0;            
                WHEN  OTHERS THEN
                    v_key := 0;
            END;       
            Return v_key;
    END;    --End GEN_STSKEY 

    FUNCTION GEN_SID RETURN NUMBER IS
        v_SID  NUMBER;
    BEGIN    
            --*** GET SID ***
            BEGIN
            SELECT sys_context('USERENV', 'SID') into v_SID
            FROM DUAL;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
            v_SID := 0; 
            WHEN OTHERS THEN
            v_SID := 0;
            END; 
            Return v_SID;
    END;    --End GEN_SID
    
    FUNCTION GEN_CLMNO(v_PROD_TYPE IN VARCHAR2 ,v_CHANNEL IN VARCHAR2) RETURN VARCHAR2 IS
        v_clmno  VARCHAR2(20);
        v_current_year  VARCHAR2(4);
    BEGIN    


            BEGIN
                select remark current_year into V_CURRENT_YEAR
                from clm_constant a
                where key = 'FIXCLMYEAR'
                and nvl(eff_date,trunc(sysdate)) <= trunc(sysdate)
                and nvl(exp_date,trunc(sysdate+1))  >  trunc(sysdate);
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    V_CURRENT_YEAR := TO_CHAR(SYSDATE  ,'YYYY');            
                WHEN  OTHERS THEN
                    V_CURRENT_YEAR := TO_CHAR(SYSDATE  ,'YYYY');
            END;     
                
            BEGIN
              
               if V_CURRENT_YEAR >='2017' then
                    select substr(run_no ,1,7)||TO_CHAR(TO_NUMBER(substr(run_no ,8)) + 1) runno into v_clmno
                    from clm_control_std a
                    where key = 'CMSC'||V_CURRENT_YEAR||'01'||v_PROD_TYPE||v_CHANNEL
                    FOR UPDATE OF KEY ,RUN_NO;
                else
                    select TO_CHAR(TO_NUMBER(RUN_NO) + 1) into v_clmno
                    from clm_control_std a
                    where key = 'CMSC'||V_CURRENT_YEAR||'01'||v_PROD_TYPE||v_CHANNEL
                    FOR UPDATE OF KEY ,RUN_NO;                
                end if;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_clmno := null;            
                WHEN  OTHERS THEN
                    v_clmno := null;
            END;       
                    
           if v_clmno is not null  then  
            BEGIN
                update clm_control_std a
                set run_no = v_clmno
                where key = 'CMSC'||V_CURRENT_YEAR||'01'||v_PROD_TYPE||v_CHANNEL ;
            EXCEPTION
                WHEN  OTHERS THEN
                    ROLLBACK;
                    v_clmno := null;
            END;  
            COMMIT;
            end if;    
            Return v_clmno;
    END;    --End GEN_CLMNO

    FUNCTION GEN_CLMNO(v_PROD_TYPE IN VARCHAR2 ,v_CHANNEL IN VARCHAR2 ,v_Branch IN VARCHAR2) RETURN VARCHAR2 IS
        v_clmno  VARCHAR2(20);
        v_current_year  VARCHAR2(4);
    BEGIN    


            BEGIN
                select remark current_year into V_CURRENT_YEAR
                from clm_constant a
                where key = 'FIXCLMYEAR'
                and nvl(eff_date,trunc(sysdate)) <= trunc(sysdate)
                and nvl(exp_date,trunc(sysdate+1))  >  trunc(sysdate);
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    V_CURRENT_YEAR := TO_CHAR(SYSDATE  ,'YYYY');            
                WHEN  OTHERS THEN
                    V_CURRENT_YEAR := TO_CHAR(SYSDATE  ,'YYYY');
            END;     
                
            BEGIN
              
               if V_CURRENT_YEAR >='2017' then
                    select substr(run_no ,1,7)||TO_CHAR(TO_NUMBER(substr(run_no ,8)) + 1) runno into v_clmno
                    from clm_control_std a
                    where key = 'CMSC'||V_CURRENT_YEAR||nvl(v_Branch,'01')||v_PROD_TYPE||v_CHANNEL
                    FOR UPDATE OF KEY ,RUN_NO;
                else
                    select TO_CHAR(TO_NUMBER(RUN_NO) + 1) into v_clmno
                    from clm_control_std a
                    where key = 'CMSC'||V_CURRENT_YEAR||nvl(v_Branch,'01')||v_PROD_TYPE||v_CHANNEL
                    FOR UPDATE OF KEY ,RUN_NO;                
                end if;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_clmno := null;            
                WHEN  OTHERS THEN
                    v_clmno := null;
            END;       
                    
           if v_clmno is not null  then  
            BEGIN
                update clm_control_std a
                set run_no = v_clmno
                where key = 'CMSC'||V_CURRENT_YEAR||nvl(v_Branch,'01')||v_PROD_TYPE||v_CHANNEL ;
            EXCEPTION
                WHEN  OTHERS THEN
                    ROLLBACK;
                    v_clmno := null;
            END;  
            COMMIT;
            end if;    
            Return v_clmno;
    END;    --End GEN_CLMNO

    FUNCTION GEN_PAYNO(v_PROD_TYPE IN VARCHAR2 ) RETURN VARCHAR2 IS
        v_payno  VARCHAR2(20);
    BEGIN    
            BEGIN
                select TO_CHAR(TO_NUMBER(RUN_NO) + 1) into v_payno
                from clm_control_std a
                where key ='CMSP'||TO_CHAR(SYSDATE,'YYYY')||v_PROD_TYPE
                FOR UPDATE OF KEY ,RUN_NO;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_payno := null;            
                WHEN  OTHERS THEN
                    v_payno := null;
            END;       
                    
           if v_payno is not null  then  
            BEGIN
                update clm_control_std a
                set run_no = v_payno
                where key = 'CMSP'||TO_CHAR(SYSDATE,'YYYY')||v_PROD_TYPE ;
            EXCEPTION
                WHEN  OTHERS THEN
                    ROLLBACK;
                    v_payno := null;
            END;  
            COMMIT;
           else
            ROLLBACK;
           end if;    
            Return v_payno;
    END;    --End GEN_PAYNO
    
    FUNCTION GEN_LETTNO(v_PROD_TYPE IN VARCHAR2 ) RETURN VARCHAR2 IS
        v_lettno  VARCHAR2(20); 
        v_prod_key  VARCHAR2(10); 
    BEGIN
   
            BEGIN
                  select prod_key into v_prod_key
              from   clm_grp_prod
              where  prod_type = v_PROD_TYPE;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_lettno := null;            
                WHEN  OTHERS THEN
                    v_lettno := null;
            END;     
              
            BEGIN
                select TO_CHAR(TO_NUMBER(RUN_NO) + 1) into v_lettno
                from clm_control_std a
                where key = 'CMSPLA'||TO_CHAR(SYSDATE,'YYYY')||v_prod_key
                FOR UPDATE OF KEY ,RUN_NO;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_lettno := null;            
                WHEN  OTHERS THEN
                    v_lettno := null;
            END;       
                    
           if v_lettno is not null  then  
            BEGIN
                update clm_control_std a
                set run_no = v_lettno
                where key = 'CMSPLA'||TO_CHAR(SYSDATE,'YYYY')||v_prod_key ;
            EXCEPTION
                WHEN  OTHERS THEN
                    ROLLBACK;
                    v_lettno := null;
            END;  
            COMMIT;
            end if;    
            Return v_lettno;    
    END;    --End GEN_LETTNO

    FUNCTION GEN_LETTNO(v_PROD_TYPE IN VARCHAR2  ,V_KEY IN VARCHAR2) RETURN VARCHAR2 IS
        v_lettno  VARCHAR2(20); 
        v_prod_key  VARCHAR2(10); 
    BEGIN
   
            BEGIN
                  select prod_key into v_prod_key
              from   clm_grp_prod
              where  prod_type = v_PROD_TYPE;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_lettno := null;            
                WHEN  OTHERS THEN
                    v_lettno := null;
            END;     
            
            dbms_output.put_line('prod_key='||v_prod_key);   
            BEGIN
                select TO_CHAR(TO_NUMBER(RUN_NO) + 1) into v_lettno
                from clm_control_std a
                where key = V_KEY||TO_CHAR(SYSDATE,'YYYY')||v_prod_key
                FOR UPDATE OF KEY ,RUN_NO;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_lettno := null;            
                WHEN  OTHERS THEN
                    v_lettno := null;
            END;       
           dbms_output.put_line('v_lettno='||v_lettno);            
           if v_lettno is not null  then  
            BEGIN
                update clm_control_std a
                set run_no = v_lettno
                where key = V_KEY||TO_CHAR(SYSDATE,'YYYY')||v_prod_key ;
            EXCEPTION
                WHEN  OTHERS THEN
                    ROLLBACK;
                    v_lettno := null;
            END;  
            COMMIT;
            end if;    
            Return v_lettno;    
    END;    --End GEN_LETTNO2

    FUNCTION GEN_xRUNNO(v_PROD IN VARCHAR2  ,V_KEY IN VARCHAR2) RETURN VARCHAR2 IS
        v_lettno  VARCHAR2(20); 
        v_prod_key  VARCHAR2(10); 
    BEGIN
            
            --dbms_output.put_line('prod_key='||v_prod_key);   
            BEGIN
                select TO_CHAR(TO_NUMBER(RUN_NO) + 1) into v_lettno
                from clm_control_std a
                where key = V_KEY||TO_CHAR(SYSDATE,'YYYY')||v_PROD
                FOR UPDATE OF KEY ,RUN_NO;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_lettno := null;            
                WHEN  OTHERS THEN
                    v_lettno := null;
            END;       
           dbms_output.put_line('v_lettno='||v_lettno);            
           if v_lettno is not null  then  
            BEGIN
                update clm_control_std a
                set run_no = v_lettno
                where key = V_KEY||TO_CHAR(SYSDATE,'YYYY')||v_PROD ;
            EXCEPTION
                WHEN  OTHERS THEN
                    ROLLBACK;
                    v_lettno := null;
            END;  
            COMMIT;
            end if;    
            Return v_lettno;    
    END;    --End GEN_xRUNNO
        
    FUNCTION GEN_MEDREFNO(V_GROUP IN VARCHAR2 /* 000 ร.พ. 001 broker*/ ) RETURN VARCHAR2 IS     
        v_refno  VARCHAR2(20):=null;
        v_run   number;
        x_group VARCHAR2(20);
    BEGIN    
        x_group := nvl(V_GROUP,'000');
            BEGIN
                select TO_CHAR(SYSDATE  ,'YYYYMM')||x_group||lpad(TO_CHAR(TO_NUMBER(RUN_NO) + 1) ,6,'0') ,TO_NUMBER(RUN_NO) + 1 
                into v_refno ,v_run
                from clm_control_std a
                where key = 'MEDREF'||x_group||TO_CHAR(SYSDATE  ,'YYYY')
                FOR UPDATE OF KEY ,RUN_NO;
            EXCEPTION
                WHEN  NO_DATA_FOUND THEN
                    v_refno := null;            
                WHEN  OTHERS THEN
                    v_refno := null;
            END;       
                    
           if v_refno is not null  then  
                BEGIN
                    update clm_control_std a
                    set run_no = v_run
                    where key = 'MEDREF'||x_group||TO_CHAR(SYSDATE  ,'YYYY');
                EXCEPTION
                    WHEN  OTHERS THEN
                        ROLLBACK;
                        v_refno := null;
                END;  
                COMMIT;
            else
                ROLLBACK;
                Return v_refno;                
            end if;    
            Return v_refno;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            Return v_refno;
    END ; --GEN_MEDREFNO
                 
    FUNCTION GET_ACCUM_AMT(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_PREMCODE IN VARCHAR2,
                                                         P_LOSS_DATE IN DATE) RETURN NUMBER IS
        v_accum NUMBER(10,2);       
        v_accum2 NUMBER(10,2);       
        v_accum3 NUMBER(10,2);                              
        /*
            ต้องหาวิธีตรวจสอบยอดจ่ายสะสมโดยอ่าน mis_cpa_paid ออกมาเป็นแบบ row ให้ได้ 
        */                 
    BEGIN
        IF IS_CHECK_ACCUM(P_PREMCODE) THEN -- ตรวจสอบยอดจ่ายสะสมวันที่รักษาเดียวกัน
            IF P_PREMCODE = '0006' THEN -- as of AUG12 ตอนนี้ยังตรวจสอบแบบ fix ค่าอยู่ที่ prem_code 0006 
                BEGIN
                        select nvl(sum(b.prem_pay6),0) into v_accum
                        from mis_clm_mas a ,mis_cpa_paid b
                        where a.pol_no = P_POL_NO and a.pol_run = P_POL_RUN
                        and a.clm_sts ='2' 
                        and a.clm_no = b.clm_no
                        and b.corr_seq = (select max(x.corr_seq) from mis_cpa_paid x where x.clm_no = b.clm_no)
                        and nvl(b.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
                        and nvl(prem_pay6,0) > 0 
                        and a.loss_date = P_LOSS_DATE;        
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_accum := 0;
                    WHEN OTHERS THEN
                        v_accum := 0;
                END;     
                --dbms_output.put_line('Accum1 :'||v_accum);
                BEGIN
                        select nvl(sum(res_amt) ,0) into v_accum2
                        from nc_reserved x
                        where x.sts_key in (
                        select a.sts_key
                        from nc_mas a ,nc_status b
                        where A.STS_KEY = b.sts_key
                        and a.pol_no = P_POL_NO and a.pol_run = P_POL_RUN
                        and a.loss_date = P_LOSS_DATE
                        and nvl(a.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
                        and b.sts_type = 'MEDSTS'
                        and b.sts_sub_type in ('MEDSTS00','MEDSTS01','MEDSTS03','MEDSTS11') 
                        and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type = 'MEDSTS')
                        )
                        and prem_code =P_PREMCODE ;                            
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_accum2 := 0;
                    WHEN OTHERS THEN
                        v_accum2 := 0;
                END;        
                --dbms_output.put_line('Accum2 :'||v_accum2);
                BEGIN
                        select nvl(sum(b.prem_pay6),0) into v_accum3
                        from mis_clm_mas a ,mis_cpa_res b
                        where a.pol_no = P_POL_NO and a.pol_run = P_POL_RUN
                        and a.clm_sts in ('0' ,'6')
                        and a.clm_no = b.clm_no
                        and b.revise_seq = (select max(x.revise_seq) from mis_cpa_res x where x.clm_no = b.clm_no)
                        and nvl(b.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
                        and nvl(prem_pay6,0) > 0 
                        and a.loss_date = P_LOSS_DATE;        
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_accum3 := 0;
                    WHEN OTHERS THEN
                        v_accum3 := 0;
                END;                
                --dbms_output.put_line('Accum3 :'||v_accum3);                
            ELSE
                v_accum := 0; 
                v_accum2 := 0; 
                v_accum3 := 0;  
            END IF;       
        ELSE
            v_accum := 0;
            v_accum2 := 0;
            v_accum3 := 0;
        END IF;
        return (v_accum+v_accum2+v_accum3);
    END;           -- END GET_ACCUM_AMT                                            

    FUNCTION GET_ACCUM_AMT(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_PREMCODE IN VARCHAR2,
                                                        P_LOSS_DATE IN DATE ,
                                                        P_CLMNO IN VARCHAR2 ) RETURN NUMBER IS
        v_accum NUMBER(10,2);       
        v_accum2 NUMBER(10,2);       
        v_accum3 NUMBER(10,2);                              
        /*
            ต้องหาวิธีตรวจสอบยอดจ่ายสะสมโดยอ่าน mis_cpa_paid ออกมาเป็นแบบ row ให้ได้ 
        */                 
    BEGIN
        IF IS_CHECK_ACCUM(P_PREMCODE) THEN -- ตรวจสอบยอดจ่ายสะสมวันที่รักษาเดียวกัน
            IF P_PREMCODE = '0006' THEN -- as of AUG12 ตอนนี้ยังตรวจสอบแบบ fix ค่าอยู่ที่ prem_code 0006 
                BEGIN
                        select nvl(sum(b.prem_pay6),0) into v_accum
                        from mis_clm_mas a ,mis_cpa_paid b
                        where a.pol_no = P_POL_NO and a.pol_run = P_POL_RUN
                        and a.clm_sts ='2' 
                        and a.clm_no = b.clm_no
                        and b.corr_seq = (select max(x.corr_seq) from mis_cpa_paid x where x.clm_no = b.clm_no)
                        and nvl(b.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
                        and nvl(prem_pay6,0) > 0 
                        and a.loss_date = P_LOSS_DATE
                        and a.clm_no <>nvl(P_CLMNO, 'x') ;        
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_accum := 0;
                    WHEN OTHERS THEN
                        v_accum := 0;
                END;     
                dbms_output.put_line('Accum1 :'||v_accum);
                BEGIN
                        select nvl(sum(res_amt) ,0) into v_accum2
                        from nc_reserved x
                        where x.sts_key in (
                        select a.sts_key
                        from nc_mas a ,nc_status b
                        where A.STS_KEY = b.sts_key
                        and a.pol_no = P_POL_NO and a.pol_run = P_POL_RUN
                        and a.loss_date = P_LOSS_DATE
                        and nvl(a.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
                        and b.sts_type = 'MEDSTS'
                        and b.sts_sub_type in ('MEDSTS00','MEDSTS01','MEDSTS03','MEDSTS11') 
                        and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type = 'MEDSTS')
                        )
                        and x.clm_no <>  nvl(P_CLMNO, 'x')
                        and prem_code =P_PREMCODE ;                            
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_accum2 := 0;
                    WHEN OTHERS THEN
                        v_accum2 := 0;
                END;        
                dbms_output.put_line('Accum2 :'||v_accum2);
                BEGIN
                        select nvl(sum(b.prem_pay6),0) into v_accum3
                        from mis_clm_mas a ,mis_cpa_res b
                        where a.pol_no = P_POL_NO and a.pol_run = P_POL_RUN
                        and a.clm_sts  in ('0' ,'6')
                        and a.clm_no = b.clm_no
                        and b.revise_seq = (select max(x.revise_seq) from mis_cpa_res x where x.clm_no = b.clm_no)
                        and nvl(b.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
                        and nvl(prem_pay6,0) > 0 
                        and a.loss_date = P_LOSS_DATE
                        and a.clm_no <> nvl(P_CLMNO, 'x')
                        ;        
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_accum3 := 0;
                    WHEN OTHERS THEN
                        v_accum3 := 0;
                END;                
                dbms_output.put_line('Accum3 :'||v_accum3);                
            ELSE
                v_accum := 0; 
                v_accum2 := 0; 
                v_accum3 := 0;  
            END IF;       
        ELSE
            v_accum := 0;
            v_accum2 := 0;
            v_accum3 := 0;
        END IF;
        return (v_accum+v_accum2+v_accum3);
    END;           -- END GET_ACCUM_AMT    
    
    FUNCTION GET_ACCUM_AMT2(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_PREMCODE IN VARCHAR2,
                                                        P_LOSS_DATE IN DATE ,
                                                        P_CLMNO IN VARCHAR2 ) RETURN NUMBER IS
        v_accum NUMBER(14,2) := 0;       
        v_accum2 NUMBER(14,2) := 0;          
        v_accum3 NUMBER(14,2) := 0;           
        v_key   NUMBER;                        
        /*
            ต้องหาวิธีตรวจสอบยอดจ่ายสะสมโดยอ่าน mis_cpa_paid ออกมาเป็นแบบ row ให้ได้ 
        */                 
    BEGIN
        NC_HEALTH_PACKAGE.GET_HISTORY_CLM( P_POL_NO ,P_POL_RUN , P_FLEET_SEQ ,P_LOSS_DATE , v_key);
        -- กวาดข้อมูล clm มาลง table แบบ row ใช้ sql sum  ยอดได้เลย
        IF IS_CHECK_ACCUM(P_PREMCODE) THEN -- ตรวจสอบยอดจ่ายสะสมวันที่รักษาเดียวกัน
            BEGIN
                SELECT nvl(sum(amount),0) into v_accum2
                FROM NC_H_HISTORY_TMP a    
                where sid= v_key
                and prem_code =P_PREMCODE 
                and a.clm_no <>  nvl(P_CLMNO, 'x')
                ;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_accum2:= 0;
                WHEN OTHERS THEN
                    v_accum2 := 0;
            END;       
       ELSIF IS_CHECK_PERTIME(P_PREMCODE) THEN -- ตรวจสอบยอดจ่ายสะสมต่อครั้ง กรณีชดเชยรายได้
            BEGIN
                SELECT  nvl(sum(amount),0)  into v_accum3
                FROM NC_H_HISTORY_TMP a    
                where sid= v_key
                and prem_code =P_PREMCODE 
                and a.clm_no <>  nvl(P_CLMNO, 'x')
                ;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_accum3 := 0;
                WHEN OTHERS THEN
                    v_accum3 := 0;
            END;      
       ELSE
            v_accum := 0;
            v_accum2 := 0;
            v_accum3 := 0;
        END IF;
        
        NC_HEALTH_PACKAGE.REMOVE_HISTORY_CLM( v_key);
        
        return (v_accum+v_accum2+v_accum3);
    END;           -- END GET_ACCUM_AMT2    
        
  FUNCTION GET_RI_RES(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_RECPT_SEQ IN NUMBER,
                                                        P_LOC_SEQ IN NUMBER,
                                                        P_LOSS_DATE IN DATE,
                                                        P_END_SEQ IN NUMBER,
                                                        P_CRI_RES OUT v_ref_cursor4 ) RETURN NUMBER IS -- return Count Record
        c1   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data1 IS RECORD
        (
        POL_NO  MIS_RI_MAS.POL_NO%TYPE ,
        POL_RUN MIS_RI_MAS.POL_RUN%TYPE ,
        RI_CODE MIS_RI_MAS.RI_CODE%TYPE ,
        RI_BR_CODE MIS_RI_MAS.RI_BR_CODE%TYPE ,
        RI_TYPE MIS_RI_MAS.RI_TYPE%TYPE ,
        LF_FLAG MIS_RI_MAS.LF_FLAG%TYPE ,
        RI_SUB_TYPE MIS_RI_MAS.RI_SUB_TYPE%TYPE ,
        --RI_SUM  MIS_RI_MAS.RI_SUM_INS%TYPE ,
        --RI_SUM  NUMBER(20,2),
        RI_SUM_SHR   NUMBER
        ); 
        j_rec1 t_data1;    
        
        v_rstlog    varchar2(200);
        v_count  number:=0;
    BEGIN
        dbms_output.put_line('POL:'||P_POL_NO||P_POL_RUN ||'RECPT :'||P_RECPT_SEQ||' END_SEQ : '||P_END_SEQ);
        BEGIN
           OPEN P_CRI_RES  FOR 
              SELECT POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE,
                     --SUM(RI_SUM_INS) RI_SUM ,
                      SUM(RI_SHARE) RI_SUM_SHR
              FROM MIS_RI_MAS
              WHERE POL_NO     = P_POL_NO   AND
                    nvl(pol_run,0) = nvl(P_POL_RUN,0) and  
                    RECPT_SEQ  = P_RECPT_SEQ AND
                    LOC_SEQ    = P_LOC_SEQ   AND
                    --END_SEQ = 0 AND 
                    END_SEQ = P_END_SEQ AND 
                    P_LOSS_DATE BETWEEN FR_DATE AND TO_DATE
              GROUP BY POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE
              ORDER BY RI_CODE, RI_BR_CODE, RI_TYPE;            
               dbms_output.put_line('step1:');
               NC_HEALTH_PACKAGE.WRITE_LOG  ('Package' ,'GET_RI_RES' ,'debug' ,'P_POL_NO='||P_POL_NO||' P_POL_RUN==>'||
                     P_POL_RUN||' P_RECPT_SEQ==>'||P_RECPT_SEQ||' P_END_SEQ==>'||P_END_SEQ||' P_LOSS_DATE==>'||to_char(P_LOSS_DATE,'dd/mm/rr')||
                     ' step1==>',v_rstlog );
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
                dbms_output.put_line('not found step1');
                BEGIN
                   OPEN P_CRI_RES  FOR 
                      SELECT POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE,
                             --SUM(RI_SUM_INS) RI_SUM ,
                              SUM(RI_SHARE) RI_SUM_SHR
                      FROM MIS_RI_MAS
                      WHERE POL_NO     = P_POL_NO   AND
                            nvl(pol_run,0) = nvl(P_POL_RUN,0) and  
                            RECPT_SEQ  = P_RECPT_SEQ AND
                            LOC_SEQ    = P_LOC_SEQ   AND
                            --END_SEQ = 0 AND 
                            --END_SEQ = P_END_SEQ AND 
                            P_LOSS_DATE BETWEEN FR_DATE AND TO_DATE
                      GROUP BY POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE
                      ORDER BY RI_CODE, RI_BR_CODE, RI_TYPE;            
                     dbms_output.put_line('stepRECPT :'||P_RECPT_SEQ||' END_SEQ : '||0);
                   NC_HEALTH_PACKAGE.WRITE_LOG  ('Package' ,'GET_RI_RES' ,'debug' ,'P_POL_NO='||P_POL_NO||' P_POL_RUN==>'||
                         P_POL_RUN||' P_RECPT_SEQ==>'||P_RECPT_SEQ||' P_END_SEQ==>'||P_END_SEQ||' P_LOSS_DATE==>'||to_char(P_LOSS_DATE,'dd/mm/rr')||
                         ' step2==>',v_rstlog );                     
                EXCEPTION
                  WHEN  NO_DATA_FOUND THEN
                        BEGIN
                           OPEN P_CRI_RES  FOR 
                              SELECT POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE,
                                     --SUM(RI_SUM_INS) RI_SUM ,
                                      SUM(RI_SHARE) RI_SUM_SHR
                              FROM MIS_RI_MAS
                              WHERE POL_NO     = P_POL_NO   AND
                                    nvl(pol_run,0) = nvl(P_POL_RUN,0) and  
                                    --RECPT_SEQ  = P_RECPT_SEQ AND
                                    LOC_SEQ    = P_LOC_SEQ   AND
                                    END_SEQ = P_END_SEQ AND 
                                    P_LOSS_DATE BETWEEN FR_DATE AND TO_DATE
                              GROUP BY POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE
                              ORDER BY RI_CODE, RI_BR_CODE, RI_TYPE;            
                              dbms_output.put_line('step RECPT : null '||' END_SEQ : '||P_END_SEQ);
                               NC_HEALTH_PACKAGE.WRITE_LOG  ('Package' ,'GET_RI_RES' ,'debug' ,'P_POL_NO='||P_POL_NO||' P_POL_RUN==>'||
                                     P_POL_RUN||' P_RECPT_SEQ==>'||P_RECPT_SEQ||' P_END_SEQ==>'||P_END_SEQ||' P_LOSS_DATE==>'||to_char(P_LOSS_DATE,'dd/mm/rr')||
                                     ' step3==>',v_rstlog );                              
                        EXCEPTION
                          WHEN  NO_DATA_FOUND THEN
                            OPEN P_CRI_RES  FOR SELECT '' POL_NO, '' pol_run, '' RI_CODE, '' RI_BR_CODE,'' RI_TYPE,'' LF_FLAG,'' RI_SUB_TYPE,
                                     --0 RI_SUM,
                                      0 RI_SUM_SHR FROM DUAL;
                            return 0;         
                          WHEN  OTHERS THEN
                            OPEN P_CRI_RES  FOR SELECT '' POL_NO, '' pol_run, '' RI_CODE, '' RI_BR_CODE,'' RI_TYPE,'' LF_FLAG,'' RI_SUB_TYPE,
                                    -- 0 RI_SUM,
                                     0 RI_SUM_SHR FROM DUAL;
                            return 0;     
                        END;         
                  WHEN  OTHERS THEN
                    OPEN P_CRI_RES  FOR SELECT '' POL_NO, '' pol_run, '' RI_CODE, '' RI_BR_CODE,'' RI_TYPE,'' LF_FLAG,'' RI_SUB_TYPE,
                            -- 0 RI_SUM,
                             0 RI_SUM_SHR FROM DUAL;
                    return 0;     
                END;       
          WHEN  OTHERS THEN
            dbms_output.put_line('error step1');
            OPEN P_CRI_RES  FOR SELECT '' POL_NO, '' pol_run, '' RI_CODE, '' RI_BR_CODE,'' RI_TYPE,'' LF_FLAG,'' RI_SUB_TYPE,
                    -- 0 RI_SUM,
                     0 RI_SUM_SHR FROM DUAL;
            dbms_output.put_line('error : '||SQLERRM);         
            return 0;     
        END;  
        
        dbms_output.put_line('pass step1');
        BEGIN
              SELECT nvl(SUM(COUNT(*)),0) into v_count
              FROM MIS_RI_MAS
              WHERE POL_NO     = P_POL_NO   AND
                    nvl(pol_run,0) = nvl(P_POL_RUN,0) and  
                    RECPT_SEQ  = P_RECPT_SEQ AND
                    LOC_SEQ    = P_LOC_SEQ   AND
                    --END_SEQ = 0 AND 
                    END_SEQ = P_END_SEQ AND 
                    P_LOSS_DATE BETWEEN FR_DATE AND TO_DATE
              GROUP BY POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE
              ORDER BY RI_CODE, RI_BR_CODE, RI_TYPE;         
              dbms_output.put_line(' step count 1 cnt:'||v_count);
               OPEN P_CRI_RES  FOR 
                  SELECT POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE,
                         --SUM(RI_SUM_INS) RI_SUM ,
                          SUM(RI_SHARE) RI_SUM_SHR
                  FROM MIS_RI_MAS
                  WHERE POL_NO     = P_POL_NO   AND
                        nvl(pol_run,0) = nvl(P_POL_RUN,0) and  
                        RECPT_SEQ  = P_RECPT_SEQ AND
                        LOC_SEQ    = P_LOC_SEQ   AND
                        --END_SEQ = 0 AND 
                        END_SEQ = P_END_SEQ AND 
                        P_LOSS_DATE BETWEEN FR_DATE AND TO_DATE
                  GROUP BY POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE
                  ORDER BY RI_CODE, RI_BR_CODE, RI_TYPE;            
                   NC_HEALTH_PACKAGE.WRITE_LOG  ('Package' ,'GET_RI_RES' ,'debug' ,'P_POL_NO='||P_POL_NO||' P_POL_RUN==>'||
                         P_POL_RUN||' P_RECPT_SEQ==>'||P_RECPT_SEQ||' P_END_SEQ==>'||P_END_SEQ||' P_LOSS_DATE==>'||to_char(P_LOSS_DATE,'dd/mm/rr')||
                         ' step4==>',v_rstlog );           
              if v_count = 0 then
                    BEGIN
                          SELECT nvl(SUM(COUNT(*)),0) into v_count
                          FROM MIS_RI_MAS
                          WHERE POL_NO     = P_POL_NO   AND
                                nvl(pol_run,0) = nvl(P_POL_RUN,0) and  
                                RECPT_SEQ  = P_RECPT_SEQ AND
                                LOC_SEQ    = P_LOC_SEQ   AND
                                --END_SEQ = 0 AND 
                                P_LOSS_DATE BETWEEN FR_DATE AND TO_DATE
                          GROUP BY POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE
                          ORDER BY RI_CODE, RI_BR_CODE, RI_TYPE;            
                          --dbms_output.put_line(' step count 1.1 cnt:'||v_count);
                          OPEN P_CRI_RES  FOR 
                          SELECT POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE,
                                 --SUM(RI_SUM_INS) RI_SUM ,
                                  SUM(RI_SHARE) RI_SUM_SHR         
                          FROM MIS_RI_MAS
                          WHERE POL_NO     = P_POL_NO   AND
                                nvl(pol_run,0) = nvl(P_POL_RUN,0) and  
                                RECPT_SEQ  = P_RECPT_SEQ AND
                                LOC_SEQ    = P_LOC_SEQ   AND
                                --END_SEQ = 0 AND 
                                P_LOSS_DATE BETWEEN FR_DATE AND TO_DATE
                          GROUP BY POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE
                          ORDER BY RI_CODE, RI_BR_CODE, RI_TYPE;  
                       NC_HEALTH_PACKAGE.WRITE_LOG  ('Package' ,'GET_RI_RES' ,'debug' ,'P_POL_NO='||P_POL_NO||' P_POL_RUN==>'||
                             P_POL_RUN||' P_RECPT_SEQ==>'||P_RECPT_SEQ||' P_END_SEQ==>'||P_END_SEQ||' P_LOSS_DATE==>'||to_char(P_LOSS_DATE,'dd/mm/rr')||
                             ' step5==>',v_rstlog );                                                                               
                          if v_count = 0 then
                                BEGIN
                                      SELECT nvl(SUM(COUNT(*)),0) into v_count
                                      FROM MIS_RI_MAS
                                      WHERE POL_NO     = P_POL_NO   AND
                                            nvl(pol_run,0) = nvl(P_POL_RUN,0) and  
                                            --RECPT_SEQ  = P_RECPT_SEQ AND
                                            LOC_SEQ    = P_LOC_SEQ   AND
                                            END_SEQ = P_END_SEQ AND 
                                            P_LOSS_DATE BETWEEN FR_DATE AND TO_DATE
                                      GROUP BY POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE
                                      ORDER BY RI_CODE, RI_BR_CODE, RI_TYPE;            
                                        --dbms_output.put_line(' step count 1.2 cnt:'||v_count);
                                      OPEN P_CRI_RES  FOR 
                                      SELECT POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE,
                                             --SUM(RI_SUM_INS) RI_SUM ,
                                              SUM(RI_SHARE) RI_SUM_SHR         
                                      FROM MIS_RI_MAS      
                                      WHERE POL_NO     = P_POL_NO   AND
                                            nvl(pol_run,0) = nvl(P_POL_RUN,0) and  
                                            --RECPT_SEQ  = P_RECPT_SEQ AND
                                            LOC_SEQ    = P_LOC_SEQ   AND
                                            END_SEQ = P_END_SEQ AND 
                                            P_LOSS_DATE BETWEEN FR_DATE AND TO_DATE
                                      GROUP BY POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE
                                      ORDER BY RI_CODE, RI_BR_CODE, RI_TYPE;    
                                       NC_HEALTH_PACKAGE.WRITE_LOG  ('Package' ,'GET_RI_RES' ,'debug' ,'P_POL_NO='||P_POL_NO||' P_POL_RUN==>'||
                                             P_POL_RUN||' P_RECPT_SEQ==>'||P_RECPT_SEQ||' P_END_SEQ==>'||P_END_SEQ||' P_LOSS_DATE==>'||to_char(P_LOSS_DATE,'dd/mm/rr')||
                                             ' step6==>',v_rstlog );                                                                                                                
                                EXCEPTION
                                  WHEN  NO_DATA_FOUND THEN
                                    v_count := 0;         
                                  WHEN  OTHERS THEN
                                    v_count := 0;        
                                END;                               
                          end if;
                    EXCEPTION
                      WHEN  NO_DATA_FOUND THEN
                        v_count := 0;         
                      WHEN  OTHERS THEN
                        v_count := 0;        
                    END;                   
              end if;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
                --dbms_output.put_line(' step count 1 not found ');
                BEGIN
                      SELECT nvl(SUM(COUNT(*)),0) into v_count
                      FROM MIS_RI_MAS
                      WHERE POL_NO     = P_POL_NO   AND
                            nvl(pol_run,0) = nvl(P_POL_RUN,0) and  
                            RECPT_SEQ  = P_RECPT_SEQ AND
                            LOC_SEQ    = P_LOC_SEQ   AND
                            END_SEQ = 0 AND 
                            --END_SEQ = P_END_SEQ AND 
                            P_LOSS_DATE BETWEEN FR_DATE AND TO_DATE
                      GROUP BY POL_NO, pol_run, RI_CODE, RI_BR_CODE, RI_TYPE, LF_FLAG, RI_SUB_TYPE
                      ORDER BY RI_CODE, RI_BR_CODE, RI_TYPE;            
                  
                EXCEPTION
                  WHEN  NO_DATA_FOUND THEN 
                    v_count := 0;
                  WHEN  OTHERS THEN
                    v_count := 0;        
                END;    
          WHEN  OTHERS THEN
           --dbms_output.put_line(' step count 1 error '||sqlerrm);
            v_count := 0;        
        END;  
                    
        return v_count;
    END ;       -- END get RI _RES  
    
    FUNCTION GET_PREMCODE_DESCR(v_prem in varchar2 , v_th_eng in VARCHAR2) RETURN VARCHAR2 IS
        v_descr VARCHAR2(150);
    BEGIN
        select descr into v_descr
        from prem_std a
        where prem_code  =v_prem
        and TH_ENG = v_th_eng
        and prod_type = 'PA' and rownum=1;  
        return v_descr;
    EXCEPTION
        WHEN no_data_found THEN
           return '';
        WHEN OTHERS THEN
           return '';    
    END;        -- END GET_PREMCODE_DESCR
    
    FUNCTION RI_NAME ( In_ri_code VARCHAR2,
                       In_ri_br_code VARCHAR2  ) RETURN varchar2 IS
       w_name varchar2(100);
    BEGIN
       SELECT name INTO w_name
       FROM RI_CODE_STD
       WHERE ri_code = In_ri_code and
             ri_br_code = In_ri_br_code;

       RETURN ( w_name );
    EXCEPTION
       WHEN OTHERS THEN
            return(null);
    END;    -- END RI_NAME
    
    FUNCTION UPDATE_SEARCH_NAME(in_name IN varchar2) RETURN varchar2 IS
        out_name  varchar2(120);
    BEGIN
            out_name := replace(
                       replace(replace(replace(replace(replace(replace(
                      replace(replace(replace(replace(replace(replace(
                      replace(replace(replace(replace(replace(replace(
                        replace(replace(replace(replace(replace(
                        replace(in_name
                   ,'้',null)
                   ,'่',null)
                   ,'๊',null)
                   ,'๋',null)
                   ,'ิ',null)
                   ,'ี',null)
                   ,'ึ',null)
                   ,'ื',null)
                   ,'ุ',null)
                   ,'ู',null)
                   ,'ั',null)
                   ,'์',null)
                   ,'.',null)
                   ,',',null)
                   ,'(',null)
                   ,')',null)
                   ,'#',null)
                   ,'*',null)
                   ,'?',null)
                   ,'@',null)
                   ,'/',null)
                   ,'!',null)
                   ,'&',null)
                   ,'-',null)
                   ,' ',null);
            return out_name;       
    END;    -- Update Search Name    

    FUNCTION GET_ACR_PAIDDATE(vCLMNo IN VARCHAR2) RETURN DATE IS
        o_paid_date  DATE;
        o_vou_date DATE;
        o_amount NUMBER;
        o_pay_method VARCHAR2(50);
        o_chq_no VARCHAR2(50);
        vPayNo  VARCHAR2(20);
    BEGIN
        FOR X IN (
            select PAY_NO from mis_clm_paid x
            where clm_no = vCLMNo 
            and corr_seq in (select max(xx.corr_seq) from mis_clm_paid xx where xx.clm_no = x.clm_no and xx.pay_total > 0)
            and pay_total > 0 and rownum =1
        ) LOOP 
            ACCOUNT.P_ACTR_PACKAGE.GET_PAYMENT_PAID_INFO(x.pay_no,
            o_vou_date, o_paid_date ,
            o_amount, o_pay_method,
            o_chq_no) ;
        END LOOP;
        
        /*
        account.p_actr_package.get_payment_paid_info(vPayNo,
                                                   o_vou_date ,
                                                   o_paid_date,
                                                   o_amount ,
                                                   o_pay_method ,
                                                   o_chq_no);     */
        return o_paid_date ;                                               
    END ; --GET_ACR_PAIDDATE
 
    FUNCTION GET_ACR_PAIDAMT(vCLMNo IN VARCHAR2) RETURN NUMBER IS
        o_paid_date  DATE;
        o_vou_date DATE;
        o_amount NUMBER;
        o_pay_method VARCHAR2(50);
        o_chq_no VARCHAR2(50);
        vPayNo  VARCHAR2(20);
    BEGIN
        FOR X IN (
            select PAY_NO from mis_clm_paid x
            where clm_no = vCLMNo 
            and corr_seq in (select max(xx.corr_seq) from mis_clm_paid xx where xx.clm_no = x.clm_no and xx.pay_total > 0)
            and pay_total > 0 and rownum =1
        ) LOOP 
            ACCOUNT.P_ACTR_PACKAGE.GET_PAYMENT_PAID_INFO(x.pay_no,
            o_vou_date, o_paid_date ,
            o_amount, o_pay_method,
            o_chq_no) ;
        END LOOP;
        
        /*
        account.p_actr_package.get_payment_paid_info(vPayNo,
                                                   o_vou_date ,
                                                   o_paid_date,
                                                   o_amount ,
                                                   o_pay_method ,
                                                   o_chq_no);     */
        return o_amount ;                                               
    END ; --GET_ACR_PAIDAMT

    FUNCTION GET_BATCHNO(vCLMNo IN VARCHAR2) RETURN VARCHAR2 IS
        vBatchNo  VARCHAR2(20);
    BEGIN
        FOR X IN (
            select BATCH_NO from mis_clm_paid x
            where clm_no = vCLMNo 
            and corr_seq in (select max(xx.corr_seq) from mis_clm_paid xx where xx.clm_no = x.clm_no and xx.pay_total > 0)
            and pay_total > 0 and rownum =1
        ) LOOP 
            vBatchNo := X.BATCH_NO ;
        END LOOP;
        
        return vBatchNo ;                                               
    END ; --GET_BATCHNO    
    
    FUNCTION GET_BILLDATE(vCLMNo IN VARCHAR2) RETURN DATE IS
        o_bill_date  DATE;
    BEGIN
        FOR X IN (
            select sts_key from nc_mas x
            where clm_no = vCLMNo  and rownum =1
        ) LOOP 
            begin
                select trunc(cdate) into o_bill_date
                from nc_status d
                where sts_key = X.STS_KEY
                and sts_type='MEDSTS' and sts_sub_type = 'MEDSTS12'
                and sts_seq in (select max(dd.sts_seq) from nc_status dd where dd.sts_key = d.sts_key and  sts_type='MEDSTS' and sts_sub_type = 'MEDSTS12')    
                and rownum=1;        
            exception
                when no_data_found then
                    o_bill_date := null; 
                when others then
                    o_bill_date := null; 
            end ;                
        END LOOP;
        
        return o_bill_date ;                                               
    END ; --GET_BILLDATE
           

    FUNCTION GET_BKI_CLMUSER(vCLMNo IN VARCHAR2 ,OUTTYPE IN NUMBER) RETURN VARCHAR2 IS-- outtype:: 0 = name ,1 = user_id ,2 = user_id + name
        v_clmmen    varchar2(10);
        o_id    varchar2(10);
        o_name varchar2(200);
        o_fname varchar2(200);
    BEGIN
        begin
            select clm_men into v_clmmen
            from mis_clm_mas
            where clm_no = vCLMNo ; 
        exception
            when no_data_found then
                v_clmmen := null;
            when others then
                v_clmmen := null; 
         end;
        
        if v_clmmen is null then
            return 'N/A';
        else
            begin
                select user_id , title||' ' ||name name ,user_id||': '||title||' ' ||name  fullname
                into o_id , o_name ,o_fname
                from clm_user_std
                where user_id =v_clmmen    ; 
            exception
                when no_data_found then
                    return v_clmmen;
                when others then
                    return v_clmmen;
             end;         
             
             if OUTTYPE = 0 then
                return v_clmmen;
             elsif OUTTYPE = 1 then
                return o_name;
             elsif OUTTYPE = 2 then
                return o_fname;
             else
                return v_clmmen;
             end if;
        end if;              
         
    END ; -- GET_BKI_CLMUSER

    PROCEDURE WRITE_LOG  ( V_USER in  VARCHAR2 ,V_USER_NAME in VARCHAR2 ,V_LOG_TEXT in VARCHAR2 ,
                                  V_RST  OUT VARCHAR2) IS
    BEGIN
/* Formatted on 05/01/2013 11:15:57 (QP5 v5.149.1003.31008) */
    V_RST := null;
        INSERT INTO NC_WS_LOG
        (SYS_ID,USER_ID,USER_NAME,FUNC,LOG_TEXT,STATUS,TIMESTAMP,
        SESSIONID,TERMINAL,SID)
        values
        ('med_clm_ws',V_USER ,V_USER_NAME,'SAVE_STEP1',V_LOG_TEXT,'error',sysdate,
        '','','');
        
        COMMIT;   
    EXCEPTION
      WHEN OTHERS THEN
           V_RST := 'error insert log: '||sqlerrm ;
    END;

    PROCEDURE WRITE_LOG  ( V_USER in  VARCHAR2 ,V_USER_NAME in VARCHAR2 ,V_FUNC IN VARCHAR2 ,V_LOG_TEXT in VARCHAR2 ,
                                  V_RST  OUT VARCHAR2) IS
    BEGIN
/* Formatted on 05/01/2013 11:15:57 (QP5 v5.149.1003.31008) */
    V_RST := null;
        INSERT INTO NC_WS_LOG
        (SYS_ID,USER_ID,USER_NAME,FUNC,LOG_TEXT,STATUS,TIMESTAMP,
        SESSIONID,TERMINAL,SID)
        values
        ('med_clm_ws',V_USER ,V_USER_NAME,V_FUNC ,V_LOG_TEXT,'error',sysdate,
        '','','');
        
        COMMIT;   
    EXCEPTION
      WHEN OTHERS THEN
           V_RST := 'error insert log: '||sqlerrm ;
    END;
        
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
                                  Out_yourpol  OUT VARCHAR) IS
    BEGIN
      SELECT YOURPOL_NO INTO Out_yourpol
      FROM MIS_RI_MAS
      WHERE POL_NO =  In_pol_no AND
            pol_run = nvl(In_pol_run,0) and 
            END_SEQ = 0 and
            RECPT_SEQ = In_recpt_seq AND
            LOC_SEQ = In_loc_seq AND
            RI_CODE = In_ri_code AND
            RI_BR_CODE = In_ri_br_code AND
            LF_FLAG = In_lf_flag AND
            RI_TYPE = In_ri_type AND
            RI_SUB_TYPE = In_ri_sub_type AND 
            In_date BETWEEN FR_DATE AND TO_DATE;
           
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
           --MESSAGE('Your policy not found !');
           Out_yourpol := NULL;
      WHEN OTHERS THEN
           Out_yourpol := NULL;
    END;

    PROCEDURE GET_LIST_CLM_DATA(DATE_FR                 IN    VARCHAR2, 
                                DATE_TO                 IN    VARCHAR2,
                                DATE_TYPE           IN    VARCHAR2,
                                P_HNNO                 IN    VARCHAR2, 
                                P_CUSNAME               IN    VARCHAR2,
                                P_INVOICE               IN    VARCHAR2, 
                                P_STATUS               IN    VARCHAR2,
                                P_HPT_CODE           IN    VARCHAR2,
                                P_ORDER_BY           IN    VARCHAR2, /* STATUS,DATE */
                                P_SORT                 IN    VARCHAR2, /*ASC ,DESC*/
                                P_ROW_CLM_DATA   OUT    v_ref_cursor1,
                                RST                       OUT VARCHAR2) IS
            select_str   VARCHAR2(30000);    
            query_str   VARCHAR2(10000);
            t_cond      VARCHAR2(10000);    
            t_order      VARCHAR2(10000);    
            dumm    NUMBER:=1;        
            V_DATE_FR    DATE:= TO_DATE(DATE_FR,'DD/MM/RRRR') ;
            V_DATE_TO    DATE:= TO_DATE(DATE_TO,'DD/MM/RRRR') ;                    
    BEGIN
        RST := null;
        
        select_str := 'select a.sts_key ,a.clm_no ,a.pol_no ,a.pol_run ,a.fleet_seq , a.reg_date ,nvl(a.loss_date,c.loss_date) loss_date ,nvl(tr_date_fr,fr_loss_date)  tr_date_fr ,nvl(tr_date_to,to_loss_date) tr_date_to ,a.hpt_code  '
        ||', nvl(a.hn_no,c.hn) hn_no ,nvl(a.invoice_no ,c.invoice) invoice_no ,a.clm_user    '
        ||',a.cus_name ,b.sts_sub_type ,NC_HEALTH_PACKAGE.GET_CLM_STATUS_DESC(b.sts_sub_type ,0 ) status '
        ||',nvl((select sum(cc.res_amt) from nc_reserved cc where cc.sts_key = a.sts_key and cc.trn_seq in (select max(cx.trn_seq) from nc_reserved cx where cx.sts_key = cc.sts_key) group by cc.sts_key) ,(select  sum(amount) from nc_res_bancas dd where dd.sts_key = a.sts_key) ) res_amt  '
        ||',nc_health_package.get_med_remark(a.sts_key ,''D'') remark'
        ||',null bill_flag'
        ||',nc_health_package.GET_BATCHNO(a.clm_no) batch_no'
        ||',nc_health_package.GET_ACR_PAIDDATE(a.clm_no) paid_date'                
        ||' from nc_mas a ,nc_status b ,nc_mas_bancas c  where a.sts_key = B.STS_KEY and a.sts_key = c.sts_key(+) and 1=:dumm '
        ||'and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type=''MEDSTS'' ) and b.sts_type = ''MEDSTS'' '
        ||'and substr(a.CLM_USER ,1,2) <>''BK'' '
--        ||'and sts_sub_type  not in( ''MEDSTS04'') '
        ;
        t_cond := '';
        t_order := '';
        
        --=== HPT CODE ===--
        if P_HPT_CODE is not null then
            t_cond := t_cond || ' and a.hpt_code = '''||P_HPT_CODE||''' ';
        else
            RST := 'HPT CODE ไม่มีค่า';
        end if;
        
        --=== STATUS ===--
        if P_STATUS is not null then
            t_cond := t_cond || ' and b.sts_sub_type = '''||P_STATUS||''' ';
        end if;     
            
        --=== INV NO ===--
        if P_INVOICE is not null then
--            t_cond := t_cond || ' and UPPER(a.invoice_no) like ''%'||UPPER(P_INVOICE)||'%'' ';
            t_cond := t_cond || ' and ( UPPER(a.invoice_no) like ''%'||UPPER(P_INVOICE)||'%'' OR  UPPER(c.invoice) like ''%'||UPPER(P_INVOICE)||'%'' ) ';
        end if;        

        --=== HN NO ===--
        if P_HNNO is not null then
--            t_cond := t_cond || ' and UPPER(a.HN_NO) like ''%'||UPPER(P_HNNO)||'%'' ';
            t_cond := t_cond || ' and ( UPPER(a.HN_NO) like ''%'||UPPER(P_HNNO)||'%'' OR  UPPER(c.HN) like ''%'||UPPER(P_HNNO)||'%'' ) ';
        end if;  

        --=== CUSNAME ===--
        if P_CUSNAME is not null then
            t_cond := t_cond || ' and UPPER(a.CUS_NAME) like ''%'||UPPER(P_CUSNAME)||'%'' ';
        end if;  

        --=== REG DATE ===--
        /*if V_REGDATE_FR is null and V_REGDATE_TO is null   then
        t_cond := t_cond;    
        else 
            if V_REGDATE_FR is not null and V_REGDATE_TO is null then
                t_cond := t_cond || ' and trunc(a.reg_date) = to_date('''||V_REGDATE_FR||''',''DD/MM/RRRR'') ';    
            else
                if V_REGDATE_FR > V_REGDATE_TO then
                    RST := 'ช่วงของ วันที่บันทึกเคลมไม่ถูกต้อง!' ;     
                elsif V_REGDATE_FR is null and V_REGDATE_TO is not null then
                    RST := 'วันที่บันทึกเคลมเริ่มต้น มากกว่า วันที่สิ้นสุด!' ;                            
                else                    
                    t_cond := t_cond || ' and trunc(a.reg_date) between to_date('''||V_REGDATE_FR||''' ,''DD/MM/RRRR'') and to_date('''||V_REGDATE_TO||''',''DD/MM/RRRR'') ';
                end if;            
            end if;            
        end if;*/     
                
        --=== TREATMENT DATE ===--
        /*if V_LOSSDATE_FR is null and V_LOSSDATE_TO is null   then
        t_cond := t_cond;    
        else 
            if V_LOSSDATE_FR is not null and V_LOSSDATE_TO is null then
                t_cond := t_cond || ' and trunc(a.tr_date_fr) = to_date('''||V_LOSSDATE_FR||''',''DD/MM/RRRR'') ';    
            else
                if V_LOSSDATE_FR > V_LOSSDATE_TO then
                    RST := 'ช่วงของ วันที่รักษาไม่ถูกต้อง!' ;     
                elsif V_LOSSDATE_FR is null and V_LOSSDATE_TO is not null then
                    RST := 'วันที่รักษาเริ่มต้น มากกว่า วันที่สิ้นสุด!' ;                            
                else                    
                    t_cond := t_cond || ' and trunc(a.tr_date_fr) between to_date('''||V_LOSSDATE_FR||''' ,''DD/MM/RRRR'') and to_date('''||V_LOSSDATE_TO||''',''DD/MM/RRRR'') ';
                end if;            
            end if;            
        end if;*/   
        
        --=== DATE_TYPE ===--
        if DATE_TYPE is not null then
            if V_DATE_FR is null and V_DATE_TO is null   then
                t_cond := t_cond;    
            else 
                if V_DATE_FR is not null and V_DATE_TO is null then
                    t_cond := t_cond || ' and trunc('||DATE_TYPE||') = '''||V_DATE_FR||'''';    
                else
                    if V_DATE_FR > V_DATE_TO then
                        RST := 'ช่วงของวันที่ไม่ถูกต้อง!' ;     
                    elsif V_DATE_FR is null and V_DATE_TO is not null then
                        RST := 'วันที่เริ่มต้น มากกว่า วันที่สิ้นสุด!' ;                            
                    else                    
                        t_cond := t_cond || ' and trunc('||DATE_TYPE||') between '''||V_DATE_FR||''' and '''||V_DATE_TO||'''';
                    end if;            
                end if;            
            end if;
        end if;

        --=== ORDER BY ===--
        if P_ORDER_BY is not null then
           t_order := t_order || ' ORDER BY '||P_ORDER_BY ;
          CASE UPPER(P_SORT)
            WHEN 'ASC' THEN  t_order := t_order||' ASC' ;
            WHEN 'DESC' THEN  t_order := t_order||' DESC' ;
            ELSE null;
         END CASE;

        end if;  
        
        IF RST is not null THEN
            OPEN P_ROW_CLM_DATA FOR select 0 sts_key ,'' clm_no ,'' pol_no ,'' pol_run ,'' fleet_seq , '' reg_date ,'' loss_date ,'' tr_date_fr ,'' tr_date_to ,'' hpt_code ,'' clm_user 
            ,'' cus_name ,'' sts_sub_type ,'' status ,0 res_amt, '' remark, '' bill_flag
            FROM dual ;
            RETURN;        
        END IF;
                
        query_str := select_str||t_cond||t_order;
        dbms_output.put_line('sql1 :'||select_str);
        dbms_output.put_line('sql2 :'||t_cond);
        dbms_output.put_line('sql3 :'||t_order);
        OPEN P_ROW_CLM_DATA FOR query_str USING dumm;
        RST := null;
        --RETURN;
        
    EXCEPTION
      WHEN  OTHERS THEN
        OPEN P_ROW_CLM_DATA FOR select 0 sts_key ,'' clm_no ,'' pol_no ,'' pol_run ,'' fleet_seq , '' reg_date ,'' loss_date ,'' tr_date_fr ,'' tr_date_to ,'' hpt_code ,'' clm_user 
        ,'' cus_name ,'' sts_sub_type ,'' status ,0 res_amt, '' remark, '' bill_flag
        FROM dual ;
        RST := 'error main :'||sqlerrm;
    END;         --END GET_LIST_CLM_DATA     

PROCEDURE GET_SINGLE_CLM_DATA(V_STSKEY NUMBER, V_CLM_NO VARCHAR2,
                            P_MASTER_DATA  OUT v_ref_cursor1 ,P_DETAIL_DATA  OUT v_ref_cursor2 ,
                            P_COVERAGE_DATA  OUT v_ref_cursor3 ,
                            RST OUT VARCHAR2) IS --RST null คือสำเร็จ 

            select_str    VARCHAR2(2000);    
            select_str2   VARCHAR2(2000);    
            query_str     VARCHAR2(2000);
            dumm          NUMBER:=1;  
            x_sts_key     nc_mas.sts_key%type;      
            x_pol_no      nc_mas.pol_no%type;
            x_pol_run     nc_mas.pol_run%type;
            x_fleet_seq   nc_mas.fleet_seq%type;
            x_recpt_seq   nc_mas.recpt_seq%type;
            x_type        varchar2(2);  
            x_name1       varchar2(250);
            x_name2       varchar2(250);
            x_fr_date     date;
            x_to_date     date;
            x_cov_amt     nc_reserved.res_amt%type;
            x_self_amt     nc_reserved.req_amt%type;  
            x_loss_date   nc_mas.loss_date%type;   
    BEGIN
        RST := null;
        
        x_sts_key := V_STSKEY;
        
        if x_sts_key = 0 then
           select a.sts_key
           into x_sts_key
           from nc_mas a
           where a.clm_no = V_CLM_NO;
        end if;
        
        -- +++ check Get Claim BANCAS
        IF IS_BANCAS_CLAIM(x_sts_key) THEN
            GET_SINGLE_CLM_DATA_BANCAS(x_sts_key, null,
                            P_MASTER_DATA ,P_DETAIL_DATA,
                            P_COVERAGE_DATA ,
                            RST) ;
             RETURN;                       
        END IF;
        -- +++ end Sub Module get Claim BANCAS 
        
        /*select a.pol_no,a.pol_run,a.fleet_seq,a.recpt_seq,b.res_amt,b.req_amt - b.res_amt,a.loss_date
        into x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_cov_amt,x_self_amt,x_loss_date
        from nc_mas a, nc_reserved b
        where a.sts_key = x_sts_key
        and b.sts_key = a.sts_key
        and b.trn_seq = 1;*/
        
        select a.pol_no,a.pol_run,a.fleet_seq,a.recpt_seq
               ,sum(nvl(b.res_amt,0)) ,sum(nvl(b.req_amt,0)) - sum(nvl(b.res_amt,0)) ,a.loss_date
        into x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_cov_amt,x_self_amt,x_loss_date
        from nc_mas a, nc_reserved b
        where a.sts_key = x_sts_key
        and b.sts_key = a.sts_key
        and b.trn_seq in (select max(bb.trn_seq) from nc_reserved bb where bb.sts_key = b.sts_key)
        group by a.sts_key ,a.pol_no,a.pol_run,a.fleet_seq,a.recpt_seq ,a.loss_date
        ;
        
        MISC.HEALTHUTIL.get_pa_health_type(x_pol_no,x_pol_run,x_type); --Get type
        
        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_type,
                                          x_name1,x_name2,x_fr_date,x_to_date);
        
        select_str := 'select  sts_key , type ,sub_type ,trn_seq ,prem_code ,prem_seq ,res_amt ,disc_amt ,deduct_amt '
        ||'from  NC_RESERVED a  '
        ||'where sts_key=:x_sts_key '
        ||'and trn_seq in (select max(aa.trn_seq) from NC_RESERVED aa where aa.sts_key = a.sts_key) '
        ;
        
        select_str2 := 'select a.sts_key ,a.clm_no ,a.pol_no ,a.pol_run ,a.fleet_seq , a.reg_date ,loss_date ,a.hpt_code, a.cus_name '
        ||',dis_code ,cause_code ,cause_seq ,loss_detail ,invoice_no , hn_no , a.remark ,ipd_flag '
        ||',NC_HEALTH_PACKAGE.GET_CLM_STATUS_DESC(b.sts_sub_type ,0 ) status '
        ||',a.id_no, a.tr_date_fr, a.tr_date_to, a.tot_tr_day, b.sts_sub_type, a.sub_cause_code '
        ||','''||to_char(x_fr_date,'dd/mm/yyyy')||''' fr_date,'''||to_char(x_to_date,'dd/mm/yyyy')||''' to_date '
        ||','||x_cov_amt||' cov_amt,'||x_self_amt||' self_amt ,a.recpt_seq '
        ||'from nc_mas a ,nc_status b '
        ||'where a.sts_key = B.STS_KEY '
        ||'and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type=''MEDSTS'' ) '        
        ||'and a.sts_key=:x_sts_key '
        ;        
        
--        IF RST is not null THEN
--            OPEN P_DETAIL_DATA FOR select 0 sts_key , '' type ,'' sub_type ,0 trn_seq ,'' prem_code ,0 prem_seq ,0 res_amt ,0 disc_amt ,0 deduct_amt
--            FROM dual ;
--            RETURN;        
--        END IF;
                
        --query_str := select_str||t_cond||t_order;
        dbms_output.put_line('sql1 :'||select_str);
        dbms_output.put_line('sql2 :'||select_str2);
        OPEN P_DETAIL_DATA FOR select_str USING x_sts_key;
        OPEN P_MASTER_DATA FOR select_str2 USING x_sts_key;
        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,P_COVERAGE_DATA);
        web_clm_pahealth.claim_coverage(x_pol_no||x_pol_run,x_fleet_seq,x_recpt_seq,P_COVERAGE_DATA,P_COVERAGE_DATA);
        RST := null;
        
    EXCEPTION
      WHEN  OTHERS THEN
        OPEN P_DETAIL_DATA FOR select 0 sts_key , '' type ,'' sub_type ,0 trn_seq ,'' prem_code ,0 prem_seq ,0 res_amt ,0 disc_amt ,0 deduct_amt
        FROM dual ;
        OPEN P_MASTER_DATA FOR select 0 sts_key ,'' clm_no ,'' pol_no ,0 pol_run ,0 fleet_seq , '' reg_date ,'' loss_date ,'' hpt_code
        ,'' dis_code ,'' cause_code ,0 cause_seq ,'' loss_detail ,'' invoice_no ,''  hn_no , '' remark ,'' ipd_flag
        , '' status, '' id_no, '' tr_date_fr, '' tr_date_to, '' tot_tr_day, '' sts_sub_type, '' sub_cause_code,'' fr_date,'' to_date
        ,'' cov_amt, '' self_amt ,0 recpt_seq
        FROM dual ;   
        open P_COVERAGE_DATA for
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;     
        RST := 'error main :'||sqlerrm;
    END;    -- END GET_SINGLE_CLM_DATA

    PROCEDURE GET_SINGLE_CLM_DATA_BANCAS(V_STSKEY NUMBER, V_CLM_NO VARCHAR2,
                            P_MASTER_DATA  OUT v_ref_cursor1 ,P_DETAIL_DATA  OUT v_ref_cursor2 ,
                            P_COVERAGE_DATA  OUT v_ref_cursor3 ,
                            RST OUT VARCHAR2) IS  --RST null คือสำเร็จ 
            select_str    VARCHAR2(2000);    
            select_str2   VARCHAR2(2000);    
            query_str     VARCHAR2(2000);
            dumm          NUMBER:=1;  
            x_sts_key     nc_mas.sts_key%type;      
            x_pol_no      nc_mas.pol_no%type;
            x_pol_run     nc_mas.pol_run%type;
            x_fleet_seq   nc_mas.fleet_seq%type;
            x_recpt_seq   nc_mas.recpt_seq%type;
            x_type        varchar2(2);  
            x_name1       varchar2(250);
            x_name2       varchar2(250);
            x_fr_date     date;
            x_to_date     date;
            x_cov_amt     nc_reserved.res_amt%type;
            x_self_amt     nc_reserved.req_amt%type;  
            x_loss_date   nc_mas.loss_date%type;   
            x_id_no     varchar2(20);  
            v_bancas_sts     varchar2(250);
            r_sid   number;
    BEGIN
        RST := null;
        
        x_sts_key := V_STSKEY;
        
        if x_sts_key = 0 then
           select a.sts_key
           into x_sts_key
           from nc_mas a
           where a.clm_no = V_CLM_NO;
        end if;
        
--        select a.pol_no,a.pol_run,a.fleet_seq,a.recpt_seq
--               ,sum(nvl(b.res_amt,0)) ,sum(nvl(b.req_amt,0)) - sum(nvl(b.res_amt,0)) ,a.loss_date
--        into x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_cov_amt,x_self_amt,x_loss_date
--        from nc_mas a, nc_reserved b
--        where a.sts_key = x_sts_key
--        and b.sts_key = a.sts_key
--        and b.trn_seq in (select max(bb.trn_seq) from nc_reserved bb where bb.sts_key = b.sts_key)
--        group by a.sts_key ,a.pol_no,a.pol_run,a.fleet_seq,a.recpt_seq ,a.loss_date
--        ; 
        
         select id_no ,sum(nvl(b.amount,0)) ,sum(nvl(b.amount,0)) - sum(nvl(b.amount,0)) ,a.loss_date
         into x_id_no ,x_cov_amt,x_self_amt,x_loss_date
        from nc_mas_bancas a , nc_res_bancas b 
        where a.sts_key = b.sts_key
        and a.sts_key = x_sts_key
        and a.sts_key not in (
            select x.sts_key from nc_mas x where x.sts_key = a.sts_key and substr(x.clm_no,1,1) <>'N' and rownum=1
        )
        group by id_no, a.sts_key ,a.loss_date        ;
        
        --MISC.HEALTHUTIL.get_pa_health_type(x_pol_no,x_pol_run,x_type); --Get type
        
--        MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_type,
--                                          x_name1,x_name2,x_fr_date,x_to_date);
                                          
        v_bancas_sts := nc_health_package.get_policy_bancas(x_id_no, x_loss_date,r_sid);
        
        if v_bancas_sts = 'Y' then
            FOR X1 IN (
                SELECT EFF_DATE , EXP_DATE  FROM NC_GET_POLICY_TMP 
                WHERE SID = r_sid
            )    LOOP
                x_fr_date := X1.EFF_DATE ;
                x_to_date := X1.EXP_DATE ;
            END LOOP;            
        end if;
        
        select_str := 'select  sts_key , '''' type ,'''' sub_type ,1 trn_seq ,prem_code ,'''' prem_seq ,amount res_amt ,0 disc_amt ,0 deduct_amt  '
        ||'from  NC_RES_BANCAS a  '
        ||'where sts_key=:x_sts_key '
        --||'and trn_seq in (select max(aa.trn_seq) from NC_RESERVED aa where aa.sts_key = a.sts_key) '
        ;
        
        select_str2 := 'select a.sts_key ,a.clm_no ,a.pol_no ,a.pol_run ,a.fleet_seq , a.reg_date ,c.loss_date ,a.hpt_code, a.cus_name '
        ||',c.icd10 dis_code ,c.cause_code ,cause_seq ,c.risk_desc loss_detail ,c.invoice invoice_no ,c.hn  hn_no , c.remark ,c.clm_type ipd_flag '
        ||',NC_HEALTH_PACKAGE.GET_CLM_STATUS_DESC(b.sts_sub_type ,0 ) status '
        ||',a.id_no, c.fr_loss_date tr_date_fr, c.to_loss_date tr_date_to ,c.day tot_tr_day, b.sts_sub_type, c.sub_cause_code '
        ||', '''||to_char(x_fr_date,'dd/mm/yyyy')||''' fr_date,'''||to_char(x_to_date,'dd/mm/yyyy')||''' to_date '
        ||','||x_cov_amt||' cov_amt,'||x_self_amt||' self_amt '
        ||',a.recpt_seq        '
        ||',nc_health_package.GET_HOSPITAL_NAME(null,''T'',a.hpt_code) hpt_name '
        ||' ,a.grp_seq '
        ||'from nc_mas a ,nc_status b  ,nc_mas_bancas c '
        ||'where a.sts_key = B.STS_KEY and A.STS_KEY = c.sts_key  '
        ||'and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type=''MEDSTS'' ) '        
        ||'and a.sts_key=:x_sts_key '
        ;        
        
        --query_str := select_str||t_cond||t_order;
        dbms_output.put_line('sql1 :'||select_str);
        dbms_output.put_line('sql2 :'||select_str2);
        OPEN P_DETAIL_DATA FOR select_str USING x_sts_key;
        OPEN P_MASTER_DATA FOR select_str2 USING x_sts_key;
--        MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,P_COVERAGE_DATA);
--        web_clm_pahealth.claim_coverage(x_pol_no||x_pol_run,x_fleet_seq,x_recpt_seq,P_COVERAGE_DATA,P_COVERAGE_DATA);
        open P_COVERAGE_DATA for
                select bene_code code, descr,null max_day,amount max_amt,null sub_agr_amt
                from NC_GET_COVER_TMP a
                where sid = r_sid
                and (select chk_accum from nc_h_premcode where premcode = a.bene_code and rownum =1 ) = 'Y'   ;
                
        DELETE NC_GET_POLICY_TMP WHERE SID = r_SID ;
        DELETE NC_GET_COVER_TMP WHERE SID = r_SID ;       
        COMMIT;                                     
        
        RST := null;
        
    EXCEPTION
      WHEN  OTHERS THEN
        ROLLBACK;
        OPEN P_DETAIL_DATA FOR select 0 sts_key , '' type ,'' sub_type ,0 trn_seq ,'' prem_code ,0 prem_seq ,0 res_amt ,0 disc_amt ,0 deduct_amt
        FROM dual ;
        OPEN P_MASTER_DATA FOR select 0 sts_key ,'' clm_no ,'' pol_no ,0 pol_run ,0 fleet_seq , '' reg_date ,'' loss_date ,'' hpt_code
        ,'' dis_code ,'' cause_code ,0 cause_seq ,'' loss_detail ,'' invoice_no ,''  hn_no , '' remark ,'' ipd_flag
        , '' status, '' id_no, '' tr_date_fr, '' tr_date_to, '' tot_tr_day, '' sts_sub_type, '' sub_cause_code,'' fr_date,'' to_date
        ,'' cov_amt, '' self_amt ,0 recpt_seq, '' hpt_name, null grp_seq
        FROM dual ;   
        open P_COVERAGE_DATA for
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;     
        RST := 'error main :'||sqlerrm;
    END;    -- END GET_SINGLE_CLM_DATA_BANCAS                            
                            
    PROCEDURE GET_LIST_CLM_DATA_BROK(DATE_FR                 IN    VARCHAR2, 
                              DATE_TO                 IN    VARCHAR2,
                              DATE_TYPE           IN    VARCHAR2,
                              P_POLICY_NO                 IN    VARCHAR2, 
                              P_CUSNAME               IN    VARCHAR2,
                              P_CLM_NO               IN    VARCHAR2, 
                              P_STATUS               IN    VARCHAR2,
                              P_CLMUSER           IN    VARCHAR2,
                              P_ORDER_BY           IN    VARCHAR2, /* STATUS,DATE */
                              P_SORT                 IN    VARCHAR2, /*ASC ,DESC*/
                              P_ROW_CLM_DATA   OUT    v_ref_cursor1,
                              RST                       OUT VARCHAR2) IS
            select_str   VARCHAR2(30000);    
            query_str   VARCHAR2(10000);
            t_cond      VARCHAR2(10000);    
            t_order      VARCHAR2(10000);    
            dumm    NUMBER:=1;        
            V_DATE_FR    DATE:= TO_DATE(DATE_FR,'DD/MM/RRRR') ;
            V_DATE_TO    DATE:= TO_DATE(DATE_TO,'DD/MM/RRRR') ;    
            x_pol_no       nc_mas.Pol_no%type;
            x_pol_run      nc_mas.Pol_run%type;                
    BEGIN
        RST := null;
        
        select_str := 'select a.sts_key ,a.clm_no ,a.pol_no ,a.pol_run ,a.fleet_seq , a.reg_date ,nvl(a.loss_date,c.loss_date) loss_date ,nvl(tr_date_fr,fr_loss_date)  tr_date_fr ,nvl(tr_date_to,to_loss_date) tr_date_to ,a.hpt_code '
        ||', nvl(a.hn_no,c.hn) hn_no ,nvl(a.invoice_no ,c.invoice) invoice_no ,a.clm_user  '
        ||',a.cus_name ,b.sts_sub_type ,NC_HEALTH_PACKAGE.GET_CLM_STATUS_DESC(b.sts_sub_type ,0 ) status '
        ||',nvl((select sum(cc.res_amt) from nc_reserved cc where cc.sts_key = a.sts_key and cc.trn_seq in (select max(cx.trn_seq) from nc_reserved cx where cx.sts_key = cc.sts_key) group by cc.sts_key) ,(select  sum(amount) from nc_res_bancas dd where dd.sts_key = a.sts_key) ) res_amt  '
        ||',nc_health_package.get_med_remark(a.sts_key ,''D'') remark'
        ||',null bill_flag'
        ||',nc_health_package.GET_BATCHNO(a.clm_no) batch_no '
        ||',nc_health_package.GET_ACR_PAIDDATE(a.clm_no) paid_date '       
        ||', nc_health_package.get_bki_clmuser(a.clm_no,1) clm_officer ' 
        ||', a.pol_no||a.pol_run policy_no '        
        ||' from nc_mas a ,nc_status b, nc_mas_bancas c  where a.sts_key = B.STS_KEY and a.sts_key = c.sts_key(+) and 1=:dumm '
        ||'and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type=''MEDSTS'' ) and b.sts_type = ''MEDSTS'' '
--        ||'and sts_sub_type  not in( ''MEDSTS04'') '
        ;
        t_cond := '';
        t_order := '';
        
        --=== CLM_USER ===--
        if P_CLMUSER is not null then
            t_cond := t_cond || ' and a.clm_user = '''||P_CLMUSER||''' ';
        else
            --RST := 'CLM_USER ไม่มีค่า';
            null;
        end if;
                
        p_acc_package.read_pol(P_POLICY_NO,x_pol_no,x_pol_run);
        --=== P_POLICY_NO ===--
        if P_POLICY_NO is not null then
            t_cond := t_cond || ' and a.pol_no = '''||x_pol_no||''' ';
            t_cond := t_cond || ' and a.pol_run = '||x_pol_run;
        end if;
        
        --=== CUSNAME ===--
        if P_CUSNAME is not null then
            t_cond := t_cond || ' and UPPER(a.CUS_NAME) like ''%'||UPPER(P_CUSNAME)||'%'' ';
        end if; 
        
        --=== P_CLM_NO ===--
        if P_CLM_NO is not null then
            t_cond := t_cond || ' and a.clm_no like '''||P_CLM_NO||''' ';
        end if; 
        
        --=== STATUS ===--
        if P_STATUS is not null then
            t_cond := t_cond || ' and b.sts_sub_type = '''||P_STATUS||''' ';
        end if;     
        
        --=== REG DATE ===--
        /*if V_REGDATE_FR is null and V_REGDATE_TO is null   then
        t_cond := t_cond;    
        else 
            if V_REGDATE_FR is not null and V_REGDATE_TO is null then
                t_cond := t_cond || ' and trunc(a.reg_date) = to_date('''||V_REGDATE_FR||''',''DD/MM/RRRR'') ';    
            else
                if V_REGDATE_FR > V_REGDATE_TO then
                    RST := 'ช่วงของ วันที่บันทึกเคลมไม่ถูกต้อง!' ;     
                elsif V_REGDATE_FR is null and V_REGDATE_TO is not null then
                    RST := 'วันที่บันทึกเคลมเริ่มต้น มากกว่า วันที่สิ้นสุด!' ;                            
                else                    
                    t_cond := t_cond || ' and trunc(a.reg_date) between to_date('''||V_REGDATE_FR||''' ,''DD/MM/RRRR'') and to_date('''||V_REGDATE_TO||''',''DD/MM/RRRR'') ';
                end if;            
            end if;            
        end if;*/     
                
        --=== TREATMENT DATE ===--
        /*if V_LOSSDATE_FR is null and V_LOSSDATE_TO is null   then
        t_cond := t_cond;    
        else 
            if V_LOSSDATE_FR is not null and V_LOSSDATE_TO is null then
                t_cond := t_cond || ' and trunc(a.tr_date_fr) = to_date('''||V_LOSSDATE_FR||''',''DD/MM/RRRR'') ';    
            else
                if V_LOSSDATE_FR > V_LOSSDATE_TO then
                    RST := 'ช่วงของ วันที่รักษาไม่ถูกต้อง!' ;     
                elsif V_LOSSDATE_FR is null and V_LOSSDATE_TO is not null then
                    RST := 'วันที่รักษาเริ่มต้น มากกว่า วันที่สิ้นสุด!' ;                            
                else                    
                    t_cond := t_cond || ' and trunc(a.tr_date_fr) between to_date('''||V_LOSSDATE_FR||''' ,''DD/MM/RRRR'') and to_date('''||V_LOSSDATE_TO||''',''DD/MM/RRRR'') ';
                end if;            
            end if;            
        end if;*/   
        
        --=== DATE_TYPE ===--
        if DATE_TYPE is not null then
            if V_DATE_FR is null and V_DATE_TO is null   then
                t_cond := t_cond;    
            else 
                if V_DATE_FR is not null and V_DATE_TO is null then
                    t_cond := t_cond || ' and trunc('||DATE_TYPE||') = '''||V_DATE_FR||'''';    
                else
                    if V_DATE_FR > V_DATE_TO then
                        RST := 'ช่วงของวันที่ไม่ถูกต้อง!' ;     
                    elsif V_DATE_FR is null and V_DATE_TO is not null then
                        RST := 'วันที่เริ่มต้น มากกว่า วันที่สิ้นสุด!' ;                            
                    else                    
                        t_cond := t_cond || ' and trunc('||DATE_TYPE||') between '''||V_DATE_FR||''' and '''||V_DATE_TO||'''';
                    end if;            
                end if;            
            end if;
        end if;

        --=== ORDER BY ===--
        if P_ORDER_BY is not null then
           t_order := t_order || ' ORDER BY '||P_ORDER_BY ;
          CASE UPPER(P_SORT)
            WHEN 'ASC' THEN  t_order := t_order||' ASC' ;
            WHEN 'DESC' THEN  t_order := t_order||' DESC' ;
            ELSE null;
         END CASE;

        end if;  
        
        IF RST is not null THEN
            OPEN P_ROW_CLM_DATA FOR select 0 sts_key ,'' clm_no ,'' pol_no ,'' pol_run ,'' fleet_seq , '' reg_date ,'' loss_date ,'' tr_date_fr ,'' tr_date_to ,'' hpt_code ,'' clm_user 
            ,'' cus_name ,'' sts_sub_type ,'' status ,0 res_amt, '' remark, '' bill_flag
            FROM dual ;
            RETURN;        
        END IF;
                
        query_str := select_str||t_cond||t_order;
        dbms_output.put_line('sql1 :'||select_str);
        dbms_output.put_line('sql2 :'||t_cond);
        dbms_output.put_line('sql3 :'||t_order);
        OPEN P_ROW_CLM_DATA FOR query_str USING dumm;
        RST := null;
        --RETURN;
        
    EXCEPTION
      WHEN  OTHERS THEN
        OPEN P_ROW_CLM_DATA FOR select 0 sts_key ,'' clm_no ,'' pol_no ,'' pol_run ,'' fleet_seq , '' reg_date ,'' loss_date ,'' tr_date_fr ,'' tr_date_to ,'' hpt_code ,'' clm_user 
        ,'' cus_name ,'' sts_sub_type ,'' status ,0 res_amt, '' remark, '' bill_flag
        FROM dual ;
        RST := 'error main :'||sqlerrm;
    END;         --END GET_LIST_CLM_DATA_BROK

PROCEDURE GET_SINGLE_CLM_DATA_BROK(V_STSKEY NUMBER, V_CLM_NO VARCHAR2,
                            P_MASTER_DATA  OUT v_ref_cursor1 ,P_DETAIL_DATA  OUT v_ref_cursor2 ,
                            P_COVERAGE_DATA  OUT v_ref_cursor3 ,
                            RST OUT VARCHAR2) IS --RST null คือสำเร็จ 

            select_str    VARCHAR2(2000);    
            select_str2   VARCHAR2(2000);    
            query_str     VARCHAR2(2000);
            dumm          NUMBER:=1;  
            x_sts_key     nc_mas.sts_key%type;      
            x_pol_no      nc_mas.pol_no%type;
            x_pol_run     nc_mas.pol_run%type;
            x_fleet_seq   nc_mas.fleet_seq%type;
            x_recpt_seq   nc_mas.recpt_seq%type;
            x_type        varchar2(2);  
            x_name1       varchar2(250);
            x_name2       varchar2(250);
            x_fr_date     date;
            x_to_date     date;
            x_cov_amt     nc_reserved.res_amt%type;
            x_self_amt     nc_reserved.req_amt%type;  
            x_loss_date   nc_mas.loss_date%type;   
            x_grp_seq   number;
            x_rst   varchar2(200);
    BEGIN
        RST := null;
        
        x_sts_key := V_STSKEY;
        
        if x_sts_key = 0 then
           select a.sts_key
           into x_sts_key
           from nc_mas a
           where a.clm_no = V_CLM_NO;
        end if;
        
        -- +++ check Get Claim BANCAS
        IF IS_BANCAS_CLAIM(x_sts_key) THEN
            GET_SINGLE_CLM_DATA_BANCAS(x_sts_key, null,
                            P_MASTER_DATA ,P_DETAIL_DATA,
                            P_COVERAGE_DATA ,
                            RST) ;
             RETURN;                       
        END IF;
        
        select a.pol_no,a.pol_run,a.fleet_seq,a.recpt_seq
               ,sum(nvl(b.res_amt,0)) ,sum(nvl(b.req_amt,0)) - sum(nvl(b.res_amt,0)) ,a.loss_date ,max(grp_seq) ,max(fr_date) ,max(to_date)
        into x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_cov_amt,x_self_amt,x_loss_date ,x_grp_seq ,x_fr_date ,x_to_date
        from nc_mas a, nc_reserved b
        where a.sts_key = x_sts_key
        and b.sts_key = a.sts_key
        and b.trn_seq in (select max(bb.trn_seq) from nc_reserved bb where bb.sts_key = b.sts_key)
        group by a.sts_key ,a.pol_no,a.pol_run,a.fleet_seq,a.recpt_seq ,a.loss_date
        ;
        
        MISC.HEALTHUTIL.get_pa_health_type(x_pol_no,x_pol_run,x_type); --Get type

        IF IS_UNNAME_POLICY(x_pol_no ,x_pol_run) THEN
            null;
        ELSE
            MISC.HEALTHUTIL.get_name_cover_in(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_type,
                                              x_name1,x_name2,x_fr_date,x_to_date);
        END IF;   
                
        select_str := 'select  sts_key , type ,sub_type ,trn_seq ,prem_code ,prem_seq ,res_amt ,disc_amt ,deduct_amt '
        ||'from  NC_RESERVED a  '
        ||'where sts_key=:x_sts_key '
        ||'and trn_seq in (select max(aa.trn_seq) from NC_RESERVED aa where aa.sts_key = a.sts_key) '
        ;
        
        select_str2 := 'select a.sts_key ,a.clm_no ,a.pol_no ,a.pol_run ,a.fleet_seq ,a.reg_date ,loss_date ,a.hpt_code, a.cus_name '
        ||',dis_code ,cause_code ,cause_seq ,loss_detail ,invoice_no , hn_no , a.remark ,ipd_flag '
        ||',NC_HEALTH_PACKAGE.GET_CLM_STATUS_DESC(b.sts_sub_type ,0 ) status '
        ||',a.id_no, a.tr_date_fr, a.tr_date_to, a.tot_tr_day, b.sts_sub_type, a.sub_cause_code '
        ||','''||to_char(x_fr_date,'dd/mm/yyyy')||''' fr_date,'''||to_char(x_to_date,'dd/mm/yyyy')||''' to_date '
        ||','||x_cov_amt||' cov_amt,'||x_self_amt||' self_amt ,a.recpt_seq '
        ||', nc_health_package.get_bki_clmuser(a.clm_no,1) clm_officer '
        ||' ,nc_health_package.GET_HOSPITAL_NAME(null,''T'',a.hpt_code) hpt_name '
        ||' ,a.grp_seq '
        ||'from nc_mas a ,nc_status b '
        ||'where a.sts_key = B.STS_KEY '
        ||'and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type=''MEDSTS'' ) '        
        ||'and a.sts_key=:x_sts_key '
        ;        
                
        --query_str := select_str||t_cond||t_order;
        dbms_output.put_line('sql1 :'||select_str);
        dbms_output.put_line('sql2 :'||select_str2);
        OPEN P_DETAIL_DATA FOR select_str USING x_sts_key;
        OPEN P_MASTER_DATA FOR select_str2 USING x_sts_key;
        
        IF IS_UNNAME_POLICY(x_pol_no ,x_pol_run) THEN
            GET_COVER_PA_UNNAME(x_pol_no,x_pol_run ,null , null ,x_grp_seq, null ,P_COVERAGE_DATA ,x_rst);  
        ELSE
            MISC.HEALTHUTIL.get_coverage(x_pol_no,x_pol_run,x_fleet_seq,x_recpt_seq,x_loss_date,P_COVERAGE_DATA);  
        END IF;      

        RST := null;
        
    EXCEPTION
      WHEN  OTHERS THEN
        OPEN P_DETAIL_DATA FOR select 0 sts_key , '' type ,'' sub_type ,0 trn_seq ,'' prem_code ,0 prem_seq ,0 res_amt ,0 disc_amt ,0 deduct_amt
        FROM dual ;
        OPEN P_MASTER_DATA FOR select 0 sts_key ,'' clm_no ,'' pol_no ,0 pol_run ,0 fleet_seq , '' reg_date ,'' loss_date ,'' hpt_code
        ,'' dis_code ,'' cause_code ,0 cause_seq ,'' loss_detail ,'' invoice_no ,''  hn_no , '' remark ,'' ipd_flag
        , '' status, '' id_no, '' tr_date_fr, '' tr_date_to, '' tot_tr_day, '' sts_sub_type, '' sub_cause_code,'' fr_date,'' to_date
        ,'' cov_amt, '' self_amt ,0 recpt_seq ,null grp_seq
        FROM dual ;   
        open P_COVERAGE_DATA for
                select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;     
        RST := 'error main :'||sqlerrm;
    END;
    -- END GET_SINGLE_CLM_DATA_BROK

    FUNCTION GET_LIST_CLM_ORDERBY_BROK(P_ORDERBY_LIST OUT v_ref_cursor4 ) RETURN VARCHAR2 is  -- 0 Complete , 5 Error or not found
        c1   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data1 IS RECORD
        (
        NAME    VARCHAR2(20) ,
        VALUE  VARCHAR2(20)
        ); 
        j_rec1 t_data1; 

    BEGIN
        --dbms_output.put_line('Search Name ==>'||v_searchname);  
           OPEN P_ORDERBY_LIST  FOR 
            select 'วันที่เปิดเคลม' NAME, 'REG_DATE' VALUE , 0 SEQ  from dual 
            union 
             select 'สถานะ' NAME, 'STS_SUB_TYPE' VALUE , 2 SEQ from dual 
            union 
            select 'วันที่รักษา' NAME, 'TR_DATE_FR' VALUE , 1 SEQ from dual 
            union 
            select 'ชื่อผู้เอาประกัน' NAME, 'CUS_NAME' VALUE , 3 SEQ from dual 
            union 
            select 'Invoice no.' NAME, 'INVOICE_NO' VALUE, 4 SEQ from dual 
            order by seq;   
                
            return '0';       
             CLOSE P_ORDERBY_LIST; 
    EXCEPTION
           when no_data_found then 
            OPEN P_ORDERBY_LIST  FOR SELECT '' NAME , '' VALUE FROM DUAL;
            return '5';           
            CLOSE P_ORDERBY_LIST;        
           when others then 
            OPEN P_ORDERBY_LIST  FOR SELECT '' NAME , '' VALUE FROM DUAL;
            return '5';  
            CLOSE P_ORDERBY_LIST;                        
    END;
   
     
  PROCEDURE GET_COVER_PA(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_PREMCODE IN VARCHAR2, -- null คือดึงทั้งหมด 
                            P_COVER_PA  OUT v_ref_cursor1  ,RST OUT VARCHAR2)  IS
/*     cursor c1 is SELECT a.pol_no, a.pol_run, a.recpt_seq, a.fleet_seq, a.end_seq, a.title,
                   a.NAME, a.surname, a.fr_date, a.TO_DATE, a.prem_code1, a.sum_ins1,
                   a.prem_code2, a.sum_ins2, a.prem_code3, a.sum_ins3, a.prem_code4,
                   a.sum_ins4, a.prem_code5, a.sum_ins5, a.prem_code6, a.sum_ins6,
                   a.prem_code7, a.sum_ins7, a.prem_code8, a.sum_ins8, a.prem_code9,
                   a.sum_ins9, a.prem_code10, a.sum_ins10, a.prem_code11, a.sum_ins11,
                   a.prem_code12, a.sum_ins12, a.prem_code13, a.sum_ins13, a.prem_code14,
                   a.sum_ins14, a.prem_code15, a.sum_ins15, a.prem_code16, a.sum_ins16,
                   a.prem_code17, a.sum_ins17, a.prem_code18, a.sum_ins18, a.prem_code19,
                   a.sum_ins19, a.prem_code20, a.sum_ins20, a.prem_code21, a.sum_ins21,
                   a.prem_code22, a.sum_ins22, a.prem_code23, a.sum_ins23, a.prem_code24,
                   a.sum_ins24, a.prem_code25, a.sum_ins25
              FROM misc.mis_pa_prem a
                where pol_no = P_POL_NO
                and pol_run = P_POL_RUN
                and fleet_seq = P_FLEET_SEQ 
                and recpt_seq = (select max(x.recpt_seq) from mis_pa_prem x where x.pol_no = a.pol_no and x.pol_run = a.pol_run and x.fleet_seq = a.fleet_seq)  ; 
*/
     cursor c1 is SELECT min(a.prem_code1) prem_code1, sum(a.sum_ins1) sum_ins1,
                min(a.prem_code2) prem_code2, sum(a.sum_ins2) sum_ins2,
                min(a.prem_code3) prem_code3, sum(a.sum_ins3) sum_ins3,
                min(a.prem_code4) prem_code4, sum(a.sum_ins4) sum_ins4,
                min(a.prem_code5) prem_code5, sum(a.sum_ins5) sum_ins5,
                min(a.prem_code6) prem_code6, sum(a.sum_ins6) sum_ins6,
                min(a.prem_code7) prem_code7, sum(a.sum_ins7) sum_ins7,
                min(a.prem_code8) prem_code8, sum(a.sum_ins8) sum_ins8,
                min(a.prem_code9) prem_code9, sum(a.sum_ins9) sum_ins9,
                min(a.prem_code10) prem_code10, sum(a.sum_ins10) sum_ins10,
                min(a.prem_code11) prem_code11, sum(a.sum_ins11) sum_ins11,
                min(a.prem_code12) prem_code12, sum(a.sum_ins12) sum_ins12,
                min(a.prem_code13) prem_code13, sum(a.sum_ins13) sum_ins13,
                min(a.prem_code14) prem_code14, sum(a.sum_ins14) sum_ins14,
                min(a.prem_code15) prem_code15, sum(a.sum_ins15) sum_ins15,
                min(a.prem_code16) prem_code16, sum(a.sum_ins16) sum_ins16,
                min(a.prem_code17) prem_code17, sum(a.sum_ins17) sum_ins17,
                min(a.prem_code18) prem_code18, sum(a.sum_ins18) sum_ins18,
                min(a.prem_code19) prem_code19, sum(a.sum_ins19) sum_ins19,
                min(a.prem_code20) prem_code20, sum(a.sum_ins20) sum_ins20,
                min(a.prem_code21) prem_code21, sum(a.sum_ins21) sum_ins21,
                min(a.prem_code22) prem_code22, sum(a.sum_ins22) sum_ins22,
                min(a.prem_code23) prem_code23, sum(a.sum_ins23) sum_ins23,
                min(a.prem_code24) prem_code24, sum(a.sum_ins24) sum_ins24,
                min(a.prem_code25) prem_code25, sum(a.sum_ins25) sum_ins25
              FROM misc.mis_pa_prem a
                where pol_no = P_POL_NO
                and pol_run = P_POL_RUN
                and fleet_seq = P_FLEET_SEQ --:cpa_paid_blk.fleet_seq
                and recpt_seq = (select max(x.recpt_seq) from mis_pa_prem x where x.pol_no = a.pol_no and x.pol_run = a.pol_run and x.fleet_seq = a.fleet_seq)  ; 
   
    c_rec c1%rowtype;

    TYPE DEFINE_PREMCODE IS VARRAY(25) OF VARCHAR2(20);
    t_premcode   DEFINE_PREMCODE ;
    TYPE DEFINE_SUMINS IS VARRAY(25) OF NUMBER;
    t_sumins   DEFINE_SUMINS ;    
    TYPE DEFINE_PREMCOL IS VARRAY(25) OF NUMBER;
    t_premcol   DEFINE_PREMCOL ;    
        
    v_SID number(10);
    v_Tmp1 VARCHAR2(20);
    cnt NUMBER:=0;                      
    BEGIN
       RST := null; 
       t_premcode := DEFINE_PREMCODE(); --create empty varray 
       t_sumins := DEFINE_SUMINS(); --create empty varray 
       t_premcol := DEFINE_PREMCOL(); --create empty varray        
       OPEN C1;
       LOOP
          FETCH C1 INTO C_REC;
          EXIT WHEN C1%NOTFOUND;
            if c_rec.prem_code1 is not null and c_rec.sum_ins1 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code1 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins1 ;

                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 1 ;                
            end if;
              
            if c_rec.prem_code2 is not null and c_rec.sum_ins2 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code2 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins2 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 2;
            end if;
            if c_rec.prem_code3 is not null and c_rec.sum_ins3 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code3 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins3 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 3 ;
            end if;
        
            if c_rec.prem_code4 is not null and c_rec.sum_ins4 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code4 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins4 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 4 ;
            end if;        

            if c_rec.prem_code5 is not null and c_rec.sum_ins5 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code5 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins5 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 5 ;
            end if;                
        
            if c_rec.prem_code6 is not null and c_rec.sum_ins6 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code6 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins6 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 6 ;
            end if;        
        
            if c_rec.prem_code7 is not null and c_rec.sum_ins7 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code7 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins7 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 7 ;
            end if;        

            if c_rec.prem_code8 is not null and c_rec.sum_ins8 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code8 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins8 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 8 ;
            end if;       
        
            if c_rec.prem_code9 is not null and c_rec.sum_ins9 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code9 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins9 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 9 ;
            end if;         
        
            if c_rec.prem_code10 is not null and c_rec.sum_ins10 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code10 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins10 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 10 ;
            end if;        
        
            if c_rec.prem_code11 is not null and c_rec.sum_ins11 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code11 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins11 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 11 ;
            end if;
        
            if c_rec.prem_code12 is not null and c_rec.sum_ins12 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code12 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins12 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 12 ;
            end if;        
        
            if c_rec.prem_code13 is not null and c_rec.sum_ins13 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code13 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins13 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 13 ;
            end if;        
        
            if c_rec.prem_code14 is not null and c_rec.sum_ins14 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code14 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins14 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 14 ;
            end if;        
        
            if c_rec.prem_code15 is not null and c_rec.sum_ins15 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code15 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins15 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 15 ;
            end if;        
                
            if c_rec.prem_code16 is not null and c_rec.sum_ins16 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code16 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins16 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 16 ;
            end if;
        
            if c_rec.prem_code17 is not null and c_rec.sum_ins17 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code17 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins17 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 17 ;
            end if;        
                
            if c_rec.prem_code18 is not null and c_rec.sum_ins18 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code18 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins18 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 18 ;
            end if;
                
            if c_rec.prem_code19 is not null and c_rec.sum_ins19 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code19 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins19 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 19 ;
            end if;        
        
            if c_rec.prem_code20 is not null and c_rec.sum_ins20 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code20 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins20 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 20 ;
            end if;
        
            if c_rec.prem_code21 is not null and c_rec.sum_ins21 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code21 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins21 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 21 ;
            end if;        
        
            if c_rec.prem_code22 is not null and c_rec.sum_ins22 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code22 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins22 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 22 ;
            end if;        

            if c_rec.prem_code23 is not null and c_rec.sum_ins23 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code23 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins23 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 23 ;
            end if;                
        
            if c_rec.prem_code24 is not null and c_rec.sum_ins24 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code24 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins24 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 24 ;
            end if;        
        
            if c_rec.prem_code25 is not null and c_rec.sum_ins25 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code25 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins25 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 25 ;
            end if;        
        
       END LOOP;
       --DBMS_OUTPUT.PUT_LINE('COUNT='||t_premcode.COUNT);
       
       --*** GET SID ***
        BEGIN
            SELECT sys_context('USERENV', 'SID') into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;         
       
       FOR I in 1..t_premcode.COUNT LOOP
            cnt := cnt+1;            
            --DBMS_OUTPUT.PUT_LINE('PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_sumins(cnt));
             BEGIN 
                insert into nc_prem_tmp(SID,  PREMCODE, SUMINS ,PREMCOL)
                values (v_SID ,t_premcode(cnt) ,t_sumins(cnt) ,t_premcol(cnt));
             EXCEPTION
               WHEN  OTHERS THEN
               OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
               RST := 'error 1: '||sqlerrm; 
               rollback;
             END;     
       END LOOP;
        commit;

        BEGIN  -- check found
           
           SELECT max(PREMCODE) into v_Tmp1
           FROM   NC_PREM_TMP
           WHERE   SID = V_SID
           AND PREMCODE like nvl(P_PREMCODE,'%');              
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            RST := 'not found coverage';         
          WHEN  OTHERS THEN
            RST := 'error 2: '||sqlerrm; 
        END;   -- end check found
                
        BEGIN
           OPEN P_COVER_PA  FOR 
               SELECT PREMCODE, SUMINS ,PREMCOL
               FROM   NC_PREM_TMP
               WHERE   SID = V_SID
               AND PREMCODE like nvl(P_PREMCODE,'%');              
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
            RST := 'not found coverage';         
          WHEN  OTHERS THEN
            OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
            RST := 'error 3: '||sqlerrm; 
        END;  
        
        BEGIN
               DELETE NC_PREM_TMP
               WHERE   SID = V_SID;              
          
        EXCEPTION
          WHEN  OTHERS THEN
            --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS FROM DUAL;
            rollback;
        END;          
        
        commit;
    END;         --END GET_COVER_PA          

  PROCEDURE GET_COVER_PA(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_RECPT_SEQ IN NUMBER,
                                                        P_PREMCODE IN VARCHAR2, -- null คือดึงทั้งหมด 
                            P_COVER_PA  OUT v_ref_cursor1  ,RST OUT VARCHAR2)  IS

/*     cursor c1 is SELECT a.pol_no, a.pol_run, a.recpt_seq, a.fleet_seq, a.end_seq, a.title,
                   a.NAME, a.surname, a.fr_date, a.TO_DATE, a.prem_code1, a.sum_ins1,
                   a.prem_code2, a.sum_ins2, a.prem_code3, a.sum_ins3, a.prem_code4,
                   a.sum_ins4, a.prem_code5, a.sum_ins5, a.prem_code6, a.sum_ins6,
                   a.prem_code7, a.sum_ins7, a.prem_code8, a.sum_ins8, a.prem_code9,
                   a.sum_ins9, a.prem_code10, a.sum_ins10, a.prem_code11, a.sum_ins11,
                   a.prem_code12, a.sum_ins12, a.prem_code13, a.sum_ins13, a.prem_code14,
                   a.sum_ins14, a.prem_code15, a.sum_ins15, a.prem_code16, a.sum_ins16,
                   a.prem_code17, a.sum_ins17, a.prem_code18, a.sum_ins18, a.prem_code19,
                   a.sum_ins19, a.prem_code20, a.sum_ins20, a.prem_code21, a.sum_ins21,
                   a.prem_code22, a.sum_ins22, a.prem_code23, a.sum_ins23, a.prem_code24,
                   a.sum_ins24, a.prem_code25, a.sum_ins25
              FROM misc.mis_pa_prem a
                where pol_no = P_POL_NO
                and pol_run = P_POL_RUN
                and fleet_seq = P_FLEET_SEQ 
                and recpt_seq = P_RECPT_SEQ ; */
     cursor c1 is SELECT min(a.prem_code1) prem_code1, sum(a.sum_ins1) sum_ins1,
                min(a.prem_code2) prem_code2, sum(a.sum_ins2) sum_ins2,
                min(a.prem_code3) prem_code3, sum(a.sum_ins3) sum_ins3,
                min(a.prem_code4) prem_code4, sum(a.sum_ins4) sum_ins4,
                min(a.prem_code5) prem_code5, sum(a.sum_ins5) sum_ins5,
                min(a.prem_code6) prem_code6, sum(a.sum_ins6) sum_ins6,
                min(a.prem_code7) prem_code7, sum(a.sum_ins7) sum_ins7,
                min(a.prem_code8) prem_code8, sum(a.sum_ins8) sum_ins8,
                min(a.prem_code9) prem_code9, sum(a.sum_ins9) sum_ins9,
                min(a.prem_code10) prem_code10, sum(a.sum_ins10) sum_ins10,
                min(a.prem_code11) prem_code11, sum(a.sum_ins11) sum_ins11,
                min(a.prem_code12) prem_code12, sum(a.sum_ins12) sum_ins12,
                min(a.prem_code13) prem_code13, sum(a.sum_ins13) sum_ins13,
                min(a.prem_code14) prem_code14, sum(a.sum_ins14) sum_ins14,
                min(a.prem_code15) prem_code15, sum(a.sum_ins15) sum_ins15,
                min(a.prem_code16) prem_code16, sum(a.sum_ins16) sum_ins16,
                min(a.prem_code17) prem_code17, sum(a.sum_ins17) sum_ins17,
                min(a.prem_code18) prem_code18, sum(a.sum_ins18) sum_ins18,
                min(a.prem_code19) prem_code19, sum(a.sum_ins19) sum_ins19,
                min(a.prem_code20) prem_code20, sum(a.sum_ins20) sum_ins20,
                min(a.prem_code21) prem_code21, sum(a.sum_ins21) sum_ins21,
                min(a.prem_code22) prem_code22, sum(a.sum_ins22) sum_ins22,
                min(a.prem_code23) prem_code23, sum(a.sum_ins23) sum_ins23,
                min(a.prem_code24) prem_code24, sum(a.sum_ins24) sum_ins24,
                min(a.prem_code25) prem_code25, sum(a.sum_ins25) sum_ins25
              FROM misc.mis_pa_prem a
                where pol_no = P_POL_NO
                and pol_run = P_POL_RUN
                and fleet_seq = P_FLEET_SEQ 
                and recpt_seq = P_RECPT_SEQ ; 
                   
    c_rec c1%rowtype;

    TYPE DEFINE_PREMCODE IS VARRAY(25) OF VARCHAR2(20);
    t_premcode   DEFINE_PREMCODE ;
    TYPE DEFINE_SUMINS IS VARRAY(25) OF NUMBER;
    t_sumins   DEFINE_SUMINS ;    
    TYPE DEFINE_PREMCOL IS VARRAY(25) OF NUMBER;
    t_premcol   DEFINE_PREMCOL ;    
        
    v_SID number(10);
    v_Tmp1 VARCHAR2(20);
    cnt NUMBER:=0;                      
    BEGIN
       RST := null; 
       t_premcode := DEFINE_PREMCODE(); --create empty varray 
       t_sumins := DEFINE_SUMINS(); --create empty varray 
       t_premcol := DEFINE_PREMCOL(); --create empty varray        
       OPEN C1;
       LOOP
          FETCH C1 INTO C_REC;
          EXIT WHEN C1%NOTFOUND;
            if c_rec.prem_code1 is not null and c_rec.sum_ins1 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code1 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins1 ;

                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 1 ;                
            end if;
              
            if c_rec.prem_code2 is not null and c_rec.sum_ins2 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code2 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins2 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 2;
            end if;
            if c_rec.prem_code3 is not null and c_rec.sum_ins3 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code3 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins3 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 3 ;
            end if;
        
            if c_rec.prem_code4 is not null and c_rec.sum_ins4 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code4 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins4 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 4 ;
            end if;        

            if c_rec.prem_code5 is not null and c_rec.sum_ins5 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code5 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins5 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 5 ;
            end if;                
        
            if c_rec.prem_code6 is not null and c_rec.sum_ins6 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code6 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins6 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 6 ;
            end if;        
        
            if c_rec.prem_code7 is not null and c_rec.sum_ins7 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code7 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins7 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 7 ;
            end if;        

            if c_rec.prem_code8 is not null and c_rec.sum_ins8 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code8 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins8 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 8 ;
            end if;       
        
            if c_rec.prem_code9 is not null and c_rec.sum_ins9 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code9 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins9 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 9 ;
            end if;         
        
            if c_rec.prem_code10 is not null and c_rec.sum_ins10 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code10 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins10 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 10 ;
            end if;        
        
            if c_rec.prem_code11 is not null and c_rec.sum_ins11 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code11 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins11 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 11 ;
            end if;
        
            if c_rec.prem_code12 is not null and c_rec.sum_ins12 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code12 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins12 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 12 ;
            end if;        
        
            if c_rec.prem_code13 is not null and c_rec.sum_ins13 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code13 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins13 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 13 ;
            end if;        
        
            if c_rec.prem_code14 is not null and c_rec.sum_ins14 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code14 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins14 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 14 ;
            end if;        
        
            if c_rec.prem_code15 is not null and c_rec.sum_ins15 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code15 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins15 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 15 ;
            end if;        
                
            if c_rec.prem_code16 is not null and c_rec.sum_ins16 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code16 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins16 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 16 ;
            end if;
        
            if c_rec.prem_code17 is not null and c_rec.sum_ins17 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code17 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins17 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 17 ;
            end if;        
                
            if c_rec.prem_code18 is not null and c_rec.sum_ins18 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code18 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins18 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 18 ;
            end if;
                
            if c_rec.prem_code19 is not null and c_rec.sum_ins19 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code19 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins19 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 19 ;
            end if;        
        
            if c_rec.prem_code20 is not null and c_rec.sum_ins20 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code20 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins20 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 20 ;
            end if;
        
            if c_rec.prem_code21 is not null and c_rec.sum_ins21 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code21 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins21 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 21 ;
            end if;        
        
            if c_rec.prem_code22 is not null and c_rec.sum_ins22 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code22 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins22 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 22 ;
            end if;        

            if c_rec.prem_code23 is not null and c_rec.sum_ins23 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code23 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins23 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 23 ;
            end if;                
        
            if c_rec.prem_code24 is not null and c_rec.sum_ins24 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code24 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins24 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 24 ;
            end if;        
        
            if c_rec.prem_code25 is not null and c_rec.sum_ins25 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code25 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins25 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 25 ;
            end if;        
        
       END LOOP;
       --DBMS_OUTPUT.PUT_LINE('COUNT='||t_premcode.COUNT);
       
       --*** GET SID ***
        BEGIN
            SELECT sys_context('USERENV', 'SID') into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;         
       
       FOR I in 1..t_premcode.COUNT LOOP
            cnt := cnt+1;            
            --DBMS_OUTPUT.PUT_LINE('PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_sumins(cnt));
             BEGIN 
                insert into nc_prem_tmp(SID,  PREMCODE, SUMINS ,PREMCOL)
                values (v_SID ,t_premcode(cnt) ,t_sumins(cnt) ,t_premcol(cnt));
             EXCEPTION
               WHEN  OTHERS THEN
               OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
               RST := 'error 1: '||sqlerrm; 
               rollback;
             END;     
       END LOOP;
        commit;

        BEGIN  -- check found
           
           SELECT max(PREMCODE) into v_Tmp1
           FROM   NC_PREM_TMP
           WHERE   SID = V_SID
           AND PREMCODE like nvl(P_PREMCODE,'%');              
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            RST := 'not found coverage';         
          WHEN  OTHERS THEN
            RST := 'error 2: '||sqlerrm; 
        END;   -- end check found
                
        BEGIN
           OPEN P_COVER_PA  FOR 
               SELECT PREMCODE, SUMINS ,PREMCOL
               FROM   NC_PREM_TMP
               WHERE   SID = V_SID
               AND PREMCODE like nvl(P_PREMCODE,'%');              
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
            RST := 'not found coverage';         
          WHEN  OTHERS THEN
            OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
            RST := 'error 3: '||sqlerrm; 
        END;  
        
        BEGIN
               DELETE NC_PREM_TMP
               WHERE   SID = V_SID;              
          
        EXCEPTION
          WHEN  OTHERS THEN
            --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS FROM DUAL;
            rollback;
        END;          
        
        commit;
    END;         --END GET_COVER_PA   2


  PROCEDURE GET_COVER_PA(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_RECPT_SEQ IN NUMBER,
                                                        P_LOSSDATE IN DATE,
                                                        P_PREMCODE IN VARCHAR2, -- null คือดึงทั้งหมด 
                            P_COVER_PA  OUT v_ref_cursor1  ,RST OUT VARCHAR2)  IS

     cursor c1 is SELECT min(a.prem_code1) prem_code1, sum(a.sum_ins1) sum_ins1,
                min(a.prem_code2) prem_code2, sum(a.sum_ins2) sum_ins2,
                min(a.prem_code3) prem_code3, sum(a.sum_ins3) sum_ins3,
                min(a.prem_code4) prem_code4, sum(a.sum_ins4) sum_ins4,
                min(a.prem_code5) prem_code5, sum(a.sum_ins5) sum_ins5,
                min(a.prem_code6) prem_code6, sum(a.sum_ins6) sum_ins6,
                min(a.prem_code7) prem_code7, sum(a.sum_ins7) sum_ins7,
                min(a.prem_code8) prem_code8, sum(a.sum_ins8) sum_ins8,
                min(a.prem_code9) prem_code9, sum(a.sum_ins9) sum_ins9,
                min(a.prem_code10) prem_code10, sum(a.sum_ins10) sum_ins10,
                min(a.prem_code11) prem_code11, sum(a.sum_ins11) sum_ins11,
                min(a.prem_code12) prem_code12, sum(a.sum_ins12) sum_ins12,
                min(a.prem_code13) prem_code13, sum(a.sum_ins13) sum_ins13,
                min(a.prem_code14) prem_code14, sum(a.sum_ins14) sum_ins14,
                min(a.prem_code15) prem_code15, sum(a.sum_ins15) sum_ins15,
                min(a.prem_code16) prem_code16, sum(a.sum_ins16) sum_ins16,
                min(a.prem_code17) prem_code17, sum(a.sum_ins17) sum_ins17,
                min(a.prem_code18) prem_code18, sum(a.sum_ins18) sum_ins18,
                min(a.prem_code19) prem_code19, sum(a.sum_ins19) sum_ins19,
                min(a.prem_code20) prem_code20, sum(a.sum_ins20) sum_ins20,
                min(a.prem_code21) prem_code21, sum(a.sum_ins21) sum_ins21,
                min(a.prem_code22) prem_code22, sum(a.sum_ins22) sum_ins22,
                min(a.prem_code23) prem_code23, sum(a.sum_ins23) sum_ins23,
                min(a.prem_code24) prem_code24, sum(a.sum_ins24) sum_ins24,
                min(a.prem_code25) prem_code25, sum(a.sum_ins25) sum_ins25
              FROM misc.mis_pa_prem a
                where pol_no = P_POL_NO
                and pol_run = P_POL_RUN
                and fleet_seq = P_FLEET_SEQ 
                and recpt_seq = P_RECPT_SEQ 
                and P_LOSSDATE between fr_date and to_date;
                
--                and end_seq in (select nvl(max(aa.end_seq),0) from misc.mis_pa_prem aa where aa.pol_no = a.pol_no and aa.pol_run = a.pol_run and aa.fleet_seq = a.fleet_seq 
--                    and aa.recpt_seq =a.recpt_seq
--                        and P_LOSSDATE between fr_date and to_date); 
                   
    c_rec c1%rowtype;

    TYPE DEFINE_PREMCODE IS VARRAY(25) OF VARCHAR2(20);
    t_premcode   DEFINE_PREMCODE ;
    TYPE DEFINE_SUMINS IS VARRAY(25) OF NUMBER;
    t_sumins   DEFINE_SUMINS ;    
    TYPE DEFINE_PREMCOL IS VARRAY(25) OF NUMBER;
    t_premcol   DEFINE_PREMCOL ;    
        
    v_SID number(10);
    v_Tmp1 VARCHAR2(20);
    cnt NUMBER:=0;                      
    BEGIN
       RST := null; 
       t_premcode := DEFINE_PREMCODE(); --create empty varray 
       t_sumins := DEFINE_SUMINS(); --create empty varray 
       t_premcol := DEFINE_PREMCOL(); --create empty varray        
       OPEN C1;
       LOOP
          FETCH C1 INTO C_REC;
          EXIT WHEN C1%NOTFOUND;
            if c_rec.prem_code1 is not null and c_rec.sum_ins1 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code1 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins1 ;

                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 1 ;                
            end if;
              
            if c_rec.prem_code2 is not null and c_rec.sum_ins2 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code2 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins2 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 2;
            end if;
            if c_rec.prem_code3 is not null and c_rec.sum_ins3 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code3 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins3 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 3 ;
            end if;
        
            if c_rec.prem_code4 is not null and c_rec.sum_ins4 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code4 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins4 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 4 ;
            end if;        

            if c_rec.prem_code5 is not null and c_rec.sum_ins5 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code5 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins5 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 5 ;
            end if;                
        
            if c_rec.prem_code6 is not null and c_rec.sum_ins6 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code6 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins6 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 6 ;
            end if;        
        
            if c_rec.prem_code7 is not null and c_rec.sum_ins7 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code7 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins7 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 7 ;
            end if;        

            if c_rec.prem_code8 is not null and c_rec.sum_ins8 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code8 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins8 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 8 ;
            end if;       
        
            if c_rec.prem_code9 is not null and c_rec.sum_ins9 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code9 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins9 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 9 ;
            end if;         
        
            if c_rec.prem_code10 is not null and c_rec.sum_ins10 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code10 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins10 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 10 ;
            end if;        
        
            if c_rec.prem_code11 is not null and c_rec.sum_ins11 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code11 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins11 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 11 ;
            end if;
        
            if c_rec.prem_code12 is not null and c_rec.sum_ins12 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code12 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins12 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 12 ;
            end if;        
        
            if c_rec.prem_code13 is not null and c_rec.sum_ins13 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code13 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins13 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 13 ;
            end if;        
        
            if c_rec.prem_code14 is not null and c_rec.sum_ins14 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code14 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins14 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 14 ;
            end if;        
        
            if c_rec.prem_code15 is not null and c_rec.sum_ins15 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code15 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins15 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 15 ;
            end if;        
                
            if c_rec.prem_code16 is not null and c_rec.sum_ins16 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code16 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins16 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 16 ;
            end if;
        
            if c_rec.prem_code17 is not null and c_rec.sum_ins17 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code17 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins17 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 17 ;
            end if;        
                
            if c_rec.prem_code18 is not null and c_rec.sum_ins18 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code18 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins18 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 18 ;
            end if;
                
            if c_rec.prem_code19 is not null and c_rec.sum_ins19 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code19 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins19 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 19 ;
            end if;        
        
            if c_rec.prem_code20 is not null and c_rec.sum_ins20 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code20 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins20 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 20 ;
            end if;
        
            if c_rec.prem_code21 is not null and c_rec.sum_ins21 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code21 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins21 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 21 ;
            end if;        
        
            if c_rec.prem_code22 is not null and c_rec.sum_ins22 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code22 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins22 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 22 ;
            end if;        

            if c_rec.prem_code23 is not null and c_rec.sum_ins23 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code23 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins23 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 23 ;
            end if;                
        
            if c_rec.prem_code24 is not null and c_rec.sum_ins24 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code24 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins24 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 24 ;
            end if;        
        
            if c_rec.prem_code25 is not null and c_rec.sum_ins25 is not null then
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code25 ;
                        
                t_sumins.EXTEND(1);
                t_sumins(t_sumins.LAST) := c_rec.sum_ins25 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 25 ;
            end if;        
        
       END LOOP;
       --DBMS_OUTPUT.PUT_LINE('COUNT='||t_premcode.COUNT);
       
       --*** GET SID ***
        BEGIN
            SELECT sys_context('USERENV', 'SID') into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;         
       
       FOR I in 1..t_premcode.COUNT LOOP
            cnt := cnt+1;            
            --DBMS_OUTPUT.PUT_LINE('PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_sumins(cnt));
             BEGIN 
                insert into nc_prem_tmp(SID,  PREMCODE, SUMINS ,PREMCOL)
                values (v_SID ,t_premcode(cnt) ,t_sumins(cnt) ,t_premcol(cnt));
             EXCEPTION
               WHEN  OTHERS THEN
               OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
               RST := 'error 1: '||sqlerrm; 
               rollback;
             END;     
       END LOOP;
        commit;

        BEGIN  -- check found
           
           SELECT max(PREMCODE) into v_Tmp1
           FROM   NC_PREM_TMP
           WHERE   SID = V_SID
           AND PREMCODE like nvl(P_PREMCODE,'%');              
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            RST := 'not found coverage';         
          WHEN  OTHERS THEN
            RST := 'error 2: '||sqlerrm; 
        END;   -- end check found
                
        BEGIN
           OPEN P_COVER_PA  FOR 
               SELECT PREMCODE, SUMINS ,PREMCOL
               FROM   NC_PREM_TMP
               WHERE   SID = V_SID
               AND PREMCODE like nvl(P_PREMCODE,'%');              
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
            RST := 'not found coverage';         
          WHEN  OTHERS THEN
            OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
            RST := 'error 3: '||sqlerrm; 
        END;  
        
        BEGIN
               DELETE NC_PREM_TMP
               WHERE   SID = V_SID;              
          
        EXCEPTION
          WHEN  OTHERS THEN
            --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS FROM DUAL;
            rollback;
        END;          
        
        commit;
    END;         --END GET_COVER_PA   3

  PROCEDURE GET_COVER_PA_UNNAME(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_END_SEQ IN NUMBER, -- null ไว้เผื่ออนาคต
                                                        P_RECPT_SEQ IN NUMBER, -- null ไว้เผื่ออนาคต
                                                        P_GROUP_SEQ IN NUMBER, -- ไม่รู้ใส่ null ; กรณีมากกว่า 1 group ระบุ group ด้วย 
                                                        P_PREMCODE IN VARCHAR2, -- null คือดึงทั้งหมด 
                            P_COVER_PA  OUT v_ref_cursor1 ,RST OUT VARCHAR2) IS
    cnt NUMBER:=0;      
    X_END_SEQ  NUMBER:=0 ;
    X_RECPT_SEQ   NUMBER:=1 ;             
    BEGIN 
       RST := null; 
        BEGIN  -- check found
           
           select count(prem_code) into cnt
            FROM pa_cov a
            where pol_no = P_POL_NO
            and pol_run = P_POL_RUN
            and end_seq = X_END_SEQ
            and recpt_seq = X_RECPT_SEQ 
            and grp_seq = P_GROUP_SEQ 
            AND prem_code like nvl(P_PREMCODE,'%');   
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            RST := 'not found coverage';     
            cnt := 0 ;    
--            OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
            OPEN P_COVER_PA  FOR select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;
            RETURN;
          WHEN  OTHERS THEN
            RST := 'error 1: '||sqlerrm; 
            cnt := 0 ; 
            OPEN P_COVER_PA  FOR select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;
            RETURN;
        END;   -- end check found
                
        BEGIN
           OPEN P_COVER_PA  FOR 
               SELECT PREM_CODE CODE, NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(prem_code ,'T') DESCR,null MAX_DAY ,SUM_INS MAX_AMT ,null SUB_AGR_AMT
                FROM pa_cov a
                where pol_no = P_POL_NO
                and pol_run = P_POL_RUN
                and end_seq = X_END_SEQ
                and recpt_seq = X_RECPT_SEQ 
                and grp_seq = P_GROUP_SEQ 
                AND prem_code like nvl(P_PREMCODE,'%');               
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            OPEN P_COVER_PA  FOR select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;
            RST := 'not found coverage';         
          WHEN  OTHERS THEN
            OPEN P_COVER_PA  FOR select null code,null descr,null max_day,null max_amt,null sub_agr_amt from dual;
            RST := 'error 2: '||sqlerrm; 
        END;  

    END GET_COVER_PA_UNNAME;         --END GET_COVER_PA UNNAME

    PROCEDURE GET_MC_REMARK(P_POL_NO IN VARCHAR2,
                                                    P_POL_RUN IN NUMBER,
                                                    P_FLEET_SEQ IN NUMBER,
                                                    RST OUT VARCHAR2) IS -- คุ้มครองอุบัติเหตุจากมอเตอไซด์ ,ไม่คุ้มครองอุบัติเหตุจากมอเตอไซด์                            
        tSts1 varchar2(200):=null;
        TYPE t_data2 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        SUMINS  NUMBER,
        PREMCOL NUMBER
        ); 
        j_rec2 t_data2;  
        c2   NC_HEALTH_PACKAGE.v_ref_cursor1;                  
        x_chkmotor boolean:=false;
        v_fleet number; 
    BEGIN
        if nvl(P_FLEET_SEQ,0)  = 0 then
            -- v_fleet := 1 ;  fix problem SiriRaj load data have no fleet_seq =1
            begin
                select min(fleet_seq) into v_fleet
                from mis_pa_prem
                where pol_no = P_POL_NO and pol_run =P_POL_RUN
                and rownum =1;            
            exception
                when no_data_found then
                    v_fleet := 1 ;
                when others then
                    v_fleet := 1 ;
            end;
        else
            v_fleet := P_FLEET_SEQ ;
        end if;
        NC_HEALTH_PACKAGE.GET_COVER_PA (P_POL_NO,P_POL_RUN,v_fleet, null ,
                                          c2 ,tSts1 );   
                                  
        if tSts1 is null then
            x_chkmotor := false;     
            LOOP
               FETCH  c2 INTO j_rec2;
                EXIT WHEN c2%NOTFOUND;
                    --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                    if IS_CHECK_MOTORCYCLE(j_rec2.premcode) then
                        x_chkmotor := true;                                                 
                    end if;
            END LOOP;  
                    
            IF x_chkmotor THEN
                RST := '- คุ้มครองอุบัติเหตุจากมอเตอร์ไซค์';
            ELSE
                RST := '- ไม่คุ้มครองอุบัติเหตุจากมอเตอร์ไซค์';
            END IF;
        else
            RST := null ;
        end if;        
    END ; --- GET_MC_REMARK

    PROCEDURE GET_MC_REMARK(P_SQL IN VARCHAR2,
                                                    RST OUT VARCHAR2) IS -- คุ้มครองอุบัติเหตุจากมอเตอไซด์ ,ไม่คุ้มครองอุบัติเหตุจากมอเตอไซด์                            
        tSts1 varchar2(200):=null;
        TYPE t_data2 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        SUMINS  NUMBER,
        PREMCOL NUMBER
        ); 
        j_rec2 t_data2;  
        c2   NC_HEALTH_PACKAGE.v_ref_cursor1;                  
        x_chkmotor boolean:=false;
        v_fleet number; 
    BEGIN
                                          
        NC_HEALTH_PAID.GEN_CURSOR(P_SQL , c2 );                                   
                                  
        if tSts1 is null then
            x_chkmotor := false;     
            LOOP
               FETCH  c2 INTO j_rec2;
                EXIT WHEN c2%NOTFOUND;
                    --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                    if IS_CHECK_MOTORCYCLE(j_rec2.premcode) then
                        x_chkmotor := true;                                                 
                    end if;
            END LOOP;  
                    
            IF x_chkmotor THEN
                RST := '- คุ้มครองอุบัติเหตุจากมอเตอร์ไซค์';
            ELSE
                RST := '- ไม่คุ้มครองอุบัติเหตุจากมอเตอร์ไซค์';
            END IF;
        else
            RST := null ;
        end if;        
    EXCEPTION
        WHEN OTHERS THEN
            RST := null ;
    END ; --- GET_MC_REMARK SQL
        
PROCEDURE GET_HISTORY_CLM(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_LOSSDATE IN DATE, 
                           V_KEY OUT NUMBER)  IS
     cursor c1 is                
                SELECT  b.clm_no ,a.prem_code1, a.prem_pay1,
                a.prem_code2, a.prem_pay2, a.prem_code3, a.prem_pay3, a.prem_code4,
                a.prem_pay4, a.prem_code5, a.prem_pay5, a.prem_code6, a.prem_pay6,
                a.prem_code7, a.prem_pay7, a.prem_code8, a.prem_pay8, a.prem_code9,
                a.prem_pay9, a.prem_code10, a.prem_pay10, a.prem_code11, a.prem_pay11,
                a.prem_code12, a.prem_pay12, a.prem_code13, a.prem_pay13, a.prem_code14,
                a.prem_pay14, a.prem_code15, a.prem_pay15, a.prem_code16, a.prem_pay16,
                a.prem_code17, a.prem_pay17, a.prem_code18, a.prem_pay18, a.prem_code19,
                a.prem_pay19, a.prem_code20, a.prem_pay20, a.prem_code21, a.prem_pay21,
                a.prem_code22, a.prem_pay22, a.prem_code23, a.prem_pay23, a.prem_code24,
                a.prem_pay24, a.prem_code25, a.prem_pay25
                from mis_clm_mas b ,mis_cpa_paid a
                where b.pol_no = P_POL_NO and b.pol_run = P_POL_RUN
                and b.clm_sts ='2' 
                and a.clm_no = b.clm_no
                and a.corr_seq = (select max(x.corr_seq) from mis_cpa_paid x where x.clm_no = a.clm_no)
                and nvl(a.fleet_seq,1) = decode(nvl(P_FLEET_SEQ,1),0,1,nvl(P_FLEET_SEQ,1)) 
                and b.loss_date =P_LOSSDATE           ; 
 
     cursor c2 is                
                SELECT  b.clm_no ,a.prem_code1, a.prem_pay1,
                a.prem_code2, a.prem_pay2, a.prem_code3, a.prem_pay3, a.prem_code4,
                a.prem_pay4, a.prem_code5, a.prem_pay5, a.prem_code6, a.prem_pay6,
                a.prem_code7, a.prem_pay7, a.prem_code8, a.prem_pay8, a.prem_code9,
                a.prem_pay9, a.prem_code10, a.prem_pay10, a.prem_code11, a.prem_pay11,
                a.prem_code12, a.prem_pay12, a.prem_code13, a.prem_pay13, a.prem_code14,
                a.prem_pay14, a.prem_code15, a.prem_pay15, a.prem_code16, a.prem_pay16,
                a.prem_code17, a.prem_pay17, a.prem_code18, a.prem_pay18, a.prem_code19,
                a.prem_pay19, a.prem_code20, a.prem_pay20, a.prem_code21, a.prem_pay21,
                a.prem_code22, a.prem_pay22, a.prem_code23, a.prem_pay23, a.prem_code24,
                a.prem_pay24, a.prem_code25, a.prem_pay25
                from mis_clm_mas b ,mis_cpa_res a
                where b.pol_no = P_POL_NO and b.pol_run = P_POL_RUN
                and b.clm_sts  in ('0' ,'6')
                and a.clm_no = b.clm_no
                and a.revise_seq = (select max(x.revise_seq) from mis_cpa_res x where x.clm_no = a.clm_no)
                and nvl(a.fleet_seq,1) =  decode(nvl(P_FLEET_SEQ,1),0,1,nvl(P_FLEET_SEQ,1)) 
                and b.loss_date =P_LOSSDATE           ; 

     cursor c3 is                  
                select clm_no ,prem_code ,nvl(sum(res_amt) ,0) res_amt
                from nc_reserved x
                where x.sts_key in (
                select a.sts_key
                from nc_mas a ,nc_status b
                where A.STS_KEY = b.sts_key
                and a.pol_no = P_POL_NO and a.pol_run = P_POL_RUN
                and a.loss_date = P_LOSSDATE
                and nvl(a.fleet_seq,1) =  decode(nvl(P_FLEET_SEQ,1),0,1,nvl(P_FLEET_SEQ,1)) 
                and b.sts_type = 'MEDSTS'
                and b.sts_sub_type in ('MEDSTS00','MEDSTS01','MEDSTS03','MEDSTS11','MEDSTS12') 
                and a.clm_no not in (select aa.clm_no from mis_clm_mas aa where aa.clm_no = a.clm_no)
                and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type = 'MEDSTS')
                )  and x.trn_seq in (select max(xx.trn_seq) from nc_reserved xx where XX.STS_KEY = x.sts_key ) 
                group by x.clm_no ,X.PREM_CODE;                
                  
    c_rec c1%rowtype;
    c_rec2 c2%rowtype; 
    c_rec3 c3%rowtype;    
    TYPE DEFINE_CLMNO IS VARRAY(500) OF VARCHAR2(20);
    t_clmno   DEFINE_CLMNO ;    
    TYPE DEFINE_PREMCODE IS VARRAY(500) OF VARCHAR2(20);
    t_premcode   DEFINE_PREMCODE ;
    TYPE DEFINE_AMT IS VARRAY(500) OF NUMBER;
    t_amt   DEFINE_AMT ;    
    TYPE DEFINE_PREMCOL IS VARRAY(500) OF NUMBER;
    t_premcol   DEFINE_PREMCOL ;    
        
    v_SID number(10);
    v_Tmp1 VARCHAR2(20);
    cnt NUMBER:=0;                      
    BEGIN
    
       --*** GET SID ***
        BEGIN
            SELECT sys_context('USERENV', 'SID') into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;        
            
       t_clmno := DEFINE_CLMNO(); --create empty varray 
       t_premcode := DEFINE_PREMCODE(); --create empty varray 
       t_amt := DEFINE_AMT(); --create empty varray 
       t_premcol := DEFINE_PREMCOL(); --create empty varray        
       OPEN C1;
       LOOP
          FETCH C1 INTO C_REC;
          EXIT WHEN C1%NOTFOUND;
            if c_rec.prem_code1 is not null and c_rec.prem_pay1 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;            
            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code1 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay1 ;

                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 1 ;                
            end if;
              
            if c_rec.prem_code2 is not null and c_rec.prem_pay2 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code2 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay2 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 2;
            end if;
            if c_rec.prem_code3 is not null and c_rec.prem_pay3 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code3 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay3 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 3 ;
            end if;
        
            if c_rec.prem_code4 is not null and c_rec.prem_pay4 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code4 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay4 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 4 ;
            end if;        

            if c_rec.prem_code5 is not null and c_rec.prem_pay5 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code5 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay5 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 5 ;
            end if;                
        
            if c_rec.prem_code6 is not null and c_rec.prem_pay6 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code6 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay6 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 6 ;
            end if;        
        
            if c_rec.prem_code7 is not null and c_rec.prem_pay7 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code7 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay7 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 7 ;
            end if;        

            if c_rec.prem_code8 is not null and c_rec.prem_pay8 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code8 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay8 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 8 ;
            end if;       
        
            if c_rec.prem_code9 is not null and c_rec.prem_pay9 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code9 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay9 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 9 ;
            end if;         
        
            if c_rec.prem_code10 is not null and c_rec.prem_pay10 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code10 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay10 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 10 ;
            end if;        
        
            if c_rec.prem_code11 is not null and c_rec.prem_pay11 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code11 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay11 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 11 ;
            end if;
        
            if c_rec.prem_code12 is not null and c_rec.prem_pay12 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code12 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay12 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 12 ;
            end if;        
        
            if c_rec.prem_code13 is not null and c_rec.prem_pay13 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code13 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay13 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 13 ;
            end if;        
        
            if c_rec.prem_code14 is not null and c_rec.prem_pay14 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code14 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay14 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 14 ;
            end if;        
        
            if c_rec.prem_code15 is not null and c_rec.prem_pay15 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code15 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay15 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 15 ;
            end if;        
                
            if c_rec.prem_code16 is not null and c_rec.prem_pay16 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code16 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay16 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 16 ;
            end if;
        
            if c_rec.prem_code17 is not null and c_rec.prem_pay17 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code17 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay17 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 17 ;
            end if;        
                
            if c_rec.prem_code18 is not null and c_rec.prem_pay18 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code18 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay18 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 18 ;
            end if;
                
            if c_rec.prem_code19 is not null and c_rec.prem_pay19 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code19 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay19 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 19 ;
            end if;        
        
            if c_rec.prem_code20 is not null and c_rec.prem_pay20 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code20 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay20 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 20 ;
            end if;
        
            if c_rec.prem_code21 is not null and c_rec.prem_pay21 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code21 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay21 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 21 ;
            end if;        
        
            if c_rec.prem_code22 is not null and c_rec.prem_pay22 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code22 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay22 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 22 ;
            end if;        

            if c_rec.prem_code23 is not null and c_rec.prem_pay23 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code23 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay23 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 23 ;
            end if;                
        
            if c_rec.prem_code24 is not null and c_rec.prem_pay24 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code24 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay24 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 24 ;
            end if;        
        
            if c_rec.prem_code25 is not null and c_rec.prem_pay25 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code25 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay25 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 25 ;
            end if;        
        
       END LOOP;
       --DBMS_OUTPUT.PUT_LINE('COUNT='||t_premcode.COUNT);
       
       cnt:=0;
       FOR I in 1..t_premcode.COUNT LOOP
            cnt := cnt+1;            
            --DBMS_OUTPUT.PUT_LINE('C1 CLMNO='||t_clmno(cnt)||' PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_amt(cnt));
             BEGIN   --NC_H_HISTORY_TMP  
                insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
                values (v_SID ,t_clmno(cnt) ,t_premcode(cnt) ,t_amt(cnt) ,'P');
                
             EXCEPTION
               WHEN  OTHERS THEN
               --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
               V_KEY := 0 ; 
               rollback;
             END;     
       END LOOP;

        t_premcode.DELETE;
        t_amt.DELETE;
        t_clmno.DELETE;
        t_premcol.DELETE;
       
/*
       t_clmno := DEFINE_CLMNO(); --create empty varray 
       t_premcode := DEFINE_PREMCODE(); --create empty varray 
       t_amt := DEFINE_AMT(); --create empty varray 
       t_premcol := DEFINE_PREMCOL(); --create empty varray      */   
       OPEN C2;
       LOOP
          FETCH C2 INTO C_REC2;
          EXIT WHEN C2%NOTFOUND;
            if c_rec2.prem_code1 is not null and c_rec2.prem_pay1 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;            
            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code1 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay1 ;

                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 1 ;                
            end if;
              
            if c_rec2.prem_code2 is not null and c_rec2.prem_pay2 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code2 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay2 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 2;
            end if;
            if c_rec2.prem_code3 is not null and c_rec2.prem_pay3 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code3 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay3 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 3 ;
            end if;
        
            if c_rec2.prem_code4 is not null and c_rec2.prem_pay4 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code4 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay4 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 4 ;
            end if;        

            if c_rec2.prem_code5 is not null and c_rec2.prem_pay5 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code5 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay5 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 5 ;
            end if;                
        
            if c_rec2.prem_code6 is not null and c_rec2.prem_pay6 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code6 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay6 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 6 ;
            end if;        
        
            if c_rec2.prem_code7 is not null and c_rec2.prem_pay7 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code7 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay7 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 7 ;
            end if;        

            if c_rec2.prem_code8 is not null and c_rec2.prem_pay8 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code8 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay8 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 8 ;
            end if;       
        
            if c_rec2.prem_code9 is not null and c_rec2.prem_pay9 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code9 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay9 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 9 ;
            end if;         
        
            if c_rec2.prem_code10 is not null and c_rec2.prem_pay10 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code10 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay10 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 10 ;
            end if;        
        
            if c_rec2.prem_code11 is not null and c_rec2.prem_pay11 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code11 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay11 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 11 ;
            end if;
        
            if c_rec2.prem_code12 is not null and c_rec2.prem_pay12 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code12 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay12 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 12 ;
            end if;        
        
            if c_rec2.prem_code13 is not null and c_rec2.prem_pay13 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code13 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay13 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 13 ;
            end if;        
        
            if c_rec2.prem_code14 is not null and c_rec2.prem_pay14 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code14 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay14 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 14 ;
            end if;        
        
            if c_rec2.prem_code15 is not null and c_rec2.prem_pay15 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code15 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay15 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 15 ;
            end if;        
                
            if c_rec2.prem_code16 is not null and c_rec2.prem_pay16 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code16 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay16 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 16 ;
            end if;
        
            if c_rec2.prem_code17 is not null and c_rec2.prem_pay17 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code17 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay17 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 17 ;
            end if;        
                
            if c_rec2.prem_code18 is not null and c_rec2.prem_pay18 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code18 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay18 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 18 ;
            end if;
                
            if c_rec2.prem_code19 is not null and c_rec2.prem_pay19 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code19 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay19 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 19 ;
            end if;        
        
            if c_rec2.prem_code20 is not null and c_rec2.prem_pay20 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code20 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay20 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 20 ;
            end if;
        
            if c_rec2.prem_code21 is not null and c_rec2.prem_pay21 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code21 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay21 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 21 ;
            end if;        
        
            if c_rec2.prem_code22 is not null and c_rec2.prem_pay22 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code22 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay22 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 22 ;
            end if;        

            if c_rec2.prem_code23 is not null and c_rec2.prem_pay23 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code23 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay23 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 23 ;
            end if;                
        
            if c_rec2.prem_code24 is not null and c_rec2.prem_pay24 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code24 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay24 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 24 ;
            end if;        
        
            if c_rec2.prem_code25 is not null and c_rec2.prem_pay25 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code25 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay25 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 25 ;
            end if;        
        
       END LOOP;
        
       cnt:=0;
       FOR I in 1..t_premcode.COUNT LOOP
            cnt := cnt+1;            
            --DBMS_OUTPUT.PUT_LINE('C2 CLMNO='||t_clmno(cnt)||' PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_amt(cnt));
             BEGIN   --NC_H_HISTORY_TMP  
                insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
                values (v_SID ,t_clmno(cnt) ,t_premcode(cnt) ,t_amt(cnt) ,'R');
             EXCEPTION
               WHEN  OTHERS THEN
               --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
               V_KEY := 0 ; 
               rollback;
             END;     
       END LOOP;

       OPEN C3;
       LOOP
          FETCH C3 INTO C_REC3;
          EXIT WHEN C3%NOTFOUND;
             BEGIN   --NC_H_HISTORY_TMP  
                insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
                values (v_SID ,c_rec3.clm_no , c_rec3.prem_code ,c_rec3.res_amt ,'X');
             EXCEPTION
               WHEN  OTHERS THEN
               --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
               V_KEY := 0 ; 
               rollback;
             END;              
       END LOOP;
                 
       COMMIT;        
       
        BEGIN  -- check found
           
           SELECT max(PREM_CODE) into v_Tmp1
           FROM   NC_H_HISTORY_TMP
           WHERE   SID = V_SID
           AND ROWNUM=1;              
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            V_KEY :=0 ;
          WHEN  OTHERS THEN
            V_KEY :=0 ;
        END;   -- end check found
        
        IF   nvl(v_Tmp1,'N') <> 'N' THEN              
            commit;
            V_KEY := v_SID ;
        ELSE
            V_KEY :=0 ;
        END IF;
        
    END;         --END GET_HISTORY_CLM          

PROCEDURE GET_HISTORY_CLM2(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                           V_KEY OUT NUMBER)  IS
     cursor c1 is                
                SELECT  b.clm_no ,a.prem_code1, a.prem_pay1,
                a.prem_code2, a.prem_pay2, a.prem_code3, a.prem_pay3, a.prem_code4,
                a.prem_pay4, a.prem_code5, a.prem_pay5, a.prem_code6, a.prem_pay6,
                a.prem_code7, a.prem_pay7, a.prem_code8, a.prem_pay8, a.prem_code9,
                a.prem_pay9, a.prem_code10, a.prem_pay10, a.prem_code11, a.prem_pay11,
                a.prem_code12, a.prem_pay12, a.prem_code13, a.prem_pay13, a.prem_code14,
                a.prem_pay14, a.prem_code15, a.prem_pay15, a.prem_code16, a.prem_pay16,
                a.prem_code17, a.prem_pay17, a.prem_code18, a.prem_pay18, a.prem_code19,
                a.prem_pay19, a.prem_code20, a.prem_pay20, a.prem_code21, a.prem_pay21,
                a.prem_code22, a.prem_pay22, a.prem_code23, a.prem_pay23, a.prem_code24,
                a.prem_pay24, a.prem_code25, a.prem_pay25
                from mis_clm_mas b ,mis_cpa_paid a
                where b.pol_no = P_POL_NO and b.pol_run = P_POL_RUN
                and b.clm_sts ='2' 
                and a.clm_no = b.clm_no
                and a.corr_seq = (select max(x.corr_seq) from mis_cpa_paid x where x.clm_no = a.clm_no)
                and nvl(a.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
                --and b.loss_date =P_LOSSDATE           
                ; 
 
     cursor c2 is                
                SELECT  b.clm_no ,a.prem_code1, a.prem_pay1,
                a.prem_code2, a.prem_pay2, a.prem_code3, a.prem_pay3, a.prem_code4,
                a.prem_pay4, a.prem_code5, a.prem_pay5, a.prem_code6, a.prem_pay6,
                a.prem_code7, a.prem_pay7, a.prem_code8, a.prem_pay8, a.prem_code9,
                a.prem_pay9, a.prem_code10, a.prem_pay10, a.prem_code11, a.prem_pay11,
                a.prem_code12, a.prem_pay12, a.prem_code13, a.prem_pay13, a.prem_code14,
                a.prem_pay14, a.prem_code15, a.prem_pay15, a.prem_code16, a.prem_pay16,
                a.prem_code17, a.prem_pay17, a.prem_code18, a.prem_pay18, a.prem_code19,
                a.prem_pay19, a.prem_code20, a.prem_pay20, a.prem_code21, a.prem_pay21,
                a.prem_code22, a.prem_pay22, a.prem_code23, a.prem_pay23, a.prem_code24,
                a.prem_pay24, a.prem_code25, a.prem_pay25
                from mis_clm_mas b ,mis_cpa_res a
                where b.pol_no = P_POL_NO and b.pol_run = P_POL_RUN
                and b.clm_sts  in ('0' ,'6')
                and a.clm_no = b.clm_no
                and a.revise_seq = (select max(x.revise_seq) from mis_cpa_res x where x.clm_no = a.clm_no)
                and nvl(a.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
                --and b.loss_date =P_LOSSDATE           
                ; 

     cursor c3 is                  
                --select clm_no ,prem_code ,nvl(sum(res_amt) ,0) res_amt
                select clm_no ,prem_code ,sum( decode(nvl(res_amt ,nvl(req_amt,0)) ,0 ,req_amt ,res_amt)  ) res_amt
                from nc_reserved x
                where x.sts_key in (
                select a.sts_key
                from nc_mas a ,nc_status b
                where A.STS_KEY = b.sts_key
                and a.pol_no = P_POL_NO and a.pol_run = P_POL_RUN
                --and a.loss_date = P_LOSSDATE
                and nvl(a.fleet_seq,1) = nvl(P_FLEET_SEQ,1)
                and b.sts_type = 'MEDSTS'
                and b.sts_sub_type in ('MEDSTS00','MEDSTS01','MEDSTS03','MEDSTS11','MEDSTS12') 
                and a.clm_no not in (select aa.clm_no from mis_clm_mas aa where aa.clm_no = a.clm_no)
                and b.sts_seq in (select max(bb.sts_seq) from nc_status bb where bb.sts_key = b.sts_key and bb.sts_type = 'MEDSTS')
                )  and x.trn_seq in (select max(xx.trn_seq) from nc_reserved xx where XX.STS_KEY = x.sts_key ) 
                group by x.clm_no ,X.PREM_CODE;                
                  
    c_rec c1%rowtype;
    c_rec2 c2%rowtype; 
    c_rec3 c3%rowtype;    
    TYPE DEFINE_CLMNO IS VARRAY(500) OF VARCHAR2(20);
    t_clmno   DEFINE_CLMNO ;    
    TYPE DEFINE_PREMCODE IS VARRAY(500) OF VARCHAR2(20);
    t_premcode   DEFINE_PREMCODE ;
    TYPE DEFINE_AMT IS VARRAY(500) OF NUMBER;
    t_amt   DEFINE_AMT ;    
    TYPE DEFINE_PREMCOL IS VARRAY(500) OF NUMBER;
    t_premcol   DEFINE_PREMCOL ;    
        
    v_SID number(10);
    v_Tmp1 VARCHAR2(20);
    cnt NUMBER:=0;                      
    BEGIN
    
       --*** GET SID ***
        BEGIN
            SELECT sys_context('USERENV', 'SID') into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;        
            
       t_clmno := DEFINE_CLMNO(); --create empty varray 
       t_premcode := DEFINE_PREMCODE(); --create empty varray 
       t_amt := DEFINE_AMT(); --create empty varray 
       t_premcol := DEFINE_PREMCOL(); --create empty varray        
       OPEN C1;
       LOOP
          FETCH C1 INTO C_REC;
          EXIT WHEN C1%NOTFOUND;
            if c_rec.prem_code1 is not null and c_rec.prem_pay1 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;            
            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code1 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay1 ;

                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 1 ;                
            end if;
              
            if c_rec.prem_code2 is not null and c_rec.prem_pay2 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code2 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay2 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 2;
            end if;
            if c_rec.prem_code3 is not null and c_rec.prem_pay3 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code3 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay3 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 3 ;
            end if;
        
            if c_rec.prem_code4 is not null and c_rec.prem_pay4 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code4 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay4 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 4 ;
            end if;        

            if c_rec.prem_code5 is not null and c_rec.prem_pay5 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code5 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay5 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 5 ;
            end if;                
        
            if c_rec.prem_code6 is not null and c_rec.prem_pay6 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code6 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay6 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 6 ;
            end if;        
        
            if c_rec.prem_code7 is not null and c_rec.prem_pay7 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code7 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay7 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 7 ;
            end if;        

            if c_rec.prem_code8 is not null and c_rec.prem_pay8 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code8 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay8 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 8 ;
            end if;       
        
            if c_rec.prem_code9 is not null and c_rec.prem_pay9 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code9 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay9 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 9 ;
            end if;         
        
            if c_rec.prem_code10 is not null and c_rec.prem_pay10 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code10 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay10 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 10 ;
            end if;        
        
            if c_rec.prem_code11 is not null and c_rec.prem_pay11 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code11 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay11 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 11 ;
            end if;
        
            if c_rec.prem_code12 is not null and c_rec.prem_pay12 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code12 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay12 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 12 ;
            end if;        
        
            if c_rec.prem_code13 is not null and c_rec.prem_pay13 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code13 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay13 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 13 ;
            end if;        
        
            if c_rec.prem_code14 is not null and c_rec.prem_pay14 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code14 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay14 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 14 ;
            end if;        
        
            if c_rec.prem_code15 is not null and c_rec.prem_pay15 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code15 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay15 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 15 ;
            end if;        
                
            if c_rec.prem_code16 is not null and c_rec.prem_pay16 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code16 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay16 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 16 ;
            end if;
        
            if c_rec.prem_code17 is not null and c_rec.prem_pay17 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code17 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay17 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 17 ;
            end if;        
                
            if c_rec.prem_code18 is not null and c_rec.prem_pay18 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code18 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay18 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 18 ;
            end if;
                
            if c_rec.prem_code19 is not null and c_rec.prem_pay19 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code19 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay19 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 19 ;
            end if;        
        
            if c_rec.prem_code20 is not null and c_rec.prem_pay20 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code20 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay20 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 20 ;
            end if;
        
            if c_rec.prem_code21 is not null and c_rec.prem_pay21 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code21 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay21 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 21 ;
            end if;        
        
            if c_rec.prem_code22 is not null and c_rec.prem_pay22 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code22 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay22 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 22 ;
            end if;        

            if c_rec.prem_code23 is not null and c_rec.prem_pay23 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code23 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay23 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 23 ;
            end if;                
        
            if c_rec.prem_code24 is not null and c_rec.prem_pay24 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code24 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay24 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 24 ;
            end if;        
        
            if c_rec.prem_code25 is not null and c_rec.prem_pay25 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec.prem_code25 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec.prem_pay25 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 25 ;
            end if;        
        
       END LOOP;
       --DBMS_OUTPUT.PUT_LINE('COUNT='||t_premcode.COUNT);
       
       cnt:=0;
       FOR I in 1..t_premcode.COUNT LOOP
            cnt := cnt+1;            
            --DBMS_OUTPUT.PUT_LINE('C1 CLMNO='||t_clmno(cnt)||' PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_amt(cnt));
             BEGIN   --NC_H_HISTORY_TMP  
                insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
                values (v_SID ,t_clmno(cnt) ,t_premcode(cnt) ,t_amt(cnt) ,'P');
                
             EXCEPTION
               WHEN  OTHERS THEN
               --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
               V_KEY := 0 ; 
               rollback;
             END;     
       END LOOP;

        t_premcode.DELETE;
        t_amt.DELETE;
        t_clmno.DELETE;
        t_premcol.DELETE;
       
/*
       t_clmno := DEFINE_CLMNO(); --create empty varray 
       t_premcode := DEFINE_PREMCODE(); --create empty varray 
       t_amt := DEFINE_AMT(); --create empty varray 
       t_premcol := DEFINE_PREMCOL(); --create empty varray      */   
       OPEN C2;
       LOOP
          FETCH C2 INTO C_REC2;
          EXIT WHEN C2%NOTFOUND;
            if c_rec2.prem_code1 is not null and c_rec2.prem_pay1 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;            
            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code1 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay1 ;

                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 1 ;                
            end if;
              
            if c_rec2.prem_code2 is not null and c_rec2.prem_pay2 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                            
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code2 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay2 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 2;
            end if;
            if c_rec2.prem_code3 is not null and c_rec2.prem_pay3 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code3 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay3 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 3 ;
            end if;
        
            if c_rec2.prem_code4 is not null and c_rec2.prem_pay4 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code4 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay4 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 4 ;
            end if;        

            if c_rec2.prem_code5 is not null and c_rec2.prem_pay5 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code5 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay5 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 5 ;
            end if;                
        
            if c_rec2.prem_code6 is not null and c_rec2.prem_pay6 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code6 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay6 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 6 ;
            end if;        
        
            if c_rec2.prem_code7 is not null and c_rec2.prem_pay7 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code7 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay7 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 7 ;
            end if;        

            if c_rec2.prem_code8 is not null and c_rec2.prem_pay8 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code8 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay8 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 8 ;
            end if;       
        
            if c_rec2.prem_code9 is not null and c_rec2.prem_pay9 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code9 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay9 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 9 ;
            end if;         
        
            if c_rec2.prem_code10 is not null and c_rec2.prem_pay10 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code10 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay10 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 10 ;
            end if;        
        
            if c_rec2.prem_code11 is not null and c_rec2.prem_pay11 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code11 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay11 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 11 ;
            end if;
        
            if c_rec2.prem_code12 is not null and c_rec2.prem_pay12 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code12 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay12 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 12 ;
            end if;        
        
            if c_rec2.prem_code13 is not null and c_rec2.prem_pay13 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code13 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay13 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 13 ;
            end if;        
        
            if c_rec2.prem_code14 is not null and c_rec2.prem_pay14 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code14 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay14 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 14 ;
            end if;        
        
            if c_rec2.prem_code15 is not null and c_rec2.prem_pay15 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code15 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay15 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 15 ;
            end if;        
                
            if c_rec2.prem_code16 is not null and c_rec2.prem_pay16 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code16 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay16 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 16 ;
            end if;
        
            if c_rec2.prem_code17 is not null and c_rec2.prem_pay17 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code17 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay17 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 17 ;
            end if;        
                
            if c_rec2.prem_code18 is not null and c_rec2.prem_pay18 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code18 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay18 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 18 ;
            end if;
                
            if c_rec2.prem_code19 is not null and c_rec2.prem_pay19 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code19 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay19 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 19 ;
            end if;        
        
            if c_rec2.prem_code20 is not null and c_rec2.prem_pay20 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code20 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay20 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 20 ;
            end if;
        
            if c_rec2.prem_code21 is not null and c_rec2.prem_pay21 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code21 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay21 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 21 ;
            end if;        
        
            if c_rec2.prem_code22 is not null and c_rec2.prem_pay22 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code22 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay22 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 22 ;
            end if;        

            if c_rec2.prem_code23 is not null and c_rec2.prem_pay23 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code23 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay23 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 23 ;
            end if;                
        
            if c_rec2.prem_code24 is not null and c_rec2.prem_pay24 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code24 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay24 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 24 ;
            end if;        
        
            if c_rec2.prem_code25 is not null and c_rec2.prem_pay25 is not null then
                t_clmno.EXTEND(1);
                t_clmno(t_clmno.LAST) := c_rec2.clm_no ;      
                  
                t_premcode.EXTEND(1);
                t_premcode(t_premcode.LAST) := c_rec2.prem_code25 ;
                        
                t_amt.EXTEND(1);
                t_amt(t_amt.LAST) := c_rec2.prem_pay25 ;
                
                t_premcol.EXTEND(1);
                t_premcol(t_premcol.LAST) := 25 ;
            end if;        
        
       END LOOP;
        
       cnt:=0;
       FOR I in 1..t_premcode.COUNT LOOP
            cnt := cnt+1;            
            --DBMS_OUTPUT.PUT_LINE('C2 CLMNO='||t_clmno(cnt)||' PREMCODE'||cnt||' '||t_premcode(cnt)||' SUM_INS= '||t_amt(cnt));
             BEGIN   --NC_H_HISTORY_TMP  
                insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
                values (v_SID ,t_clmno(cnt) ,t_premcode(cnt) ,t_amt(cnt) ,'R');
             EXCEPTION
               WHEN  OTHERS THEN
               --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
               V_KEY := 0 ; 
               rollback;
             END;     
       END LOOP;

       OPEN C3;
       LOOP
          FETCH C3 INTO C_REC3;
          EXIT WHEN C3%NOTFOUND;
             BEGIN   --NC_H_HISTORY_TMP  
                insert into NC_H_HISTORY_TMP(SID, CLM_NO, PREM_CODE, AMOUNT ,TYPE)
                values (v_SID ,c_rec3.clm_no , c_rec3.prem_code ,c_rec3.res_amt ,'X');
             EXCEPTION
               WHEN  OTHERS THEN
               --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS ,'' PREMCOL FROM DUAL;
               V_KEY := 0 ; 
               rollback;
             END;              
       END LOOP;
                 
       COMMIT;        
       
        BEGIN  -- check found
           
           SELECT max(PREM_CODE) into v_Tmp1
           FROM   NC_H_HISTORY_TMP
           WHERE   SID = V_SID
           AND ROWNUM=1;              
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            V_KEY :=0 ;
          WHEN  OTHERS THEN
            V_KEY :=0 ;
        END;   -- end check found
        
        IF   nvl(v_Tmp1,'N') <> 'N' THEN              
            commit;
            V_KEY := v_SID ;
        ELSE
            V_KEY :=0 ;
        END IF;
        
    END;         --END GET_HISTORY_CLM  2        
    
    PROCEDURE REMOVE_HISTORY_CLM (V_KEY IN NUMBER) IS
    
    BEGIN
        BEGIN  -- check found
           
           DELETE   NC_H_HISTORY_TMP
           WHERE   SID = V_KEY ;              
          
        EXCEPTION
          WHEN  OTHERS THEN
            null ;
        END;   -- end check found        
        
        COMMIT;
    END; --END REMOVE_HISTORY_CLM 

    PROCEDURE CHECK_LIMIT(POLICY_NO  IN  VARCHAR2 ,FLEET_SEQ IN  NUMBER , LOSSDATE IN   VARCHAR2, PREMCODE  IN  VARCHAR2,REQUEST_AMT IN NUMBER 
     ,REMAIN_AMT OUT NUMBER) IS
        c1   NC_HEALTH_PACKAGE.v_ref_cursor1;  

        TYPE t_data1 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        SUMINS  NUMBER,
        PREMCOL NUMBER
        ); 
        j_rec1 t_data1;   
                
        V_RST VARCHAR2(100);   
        V_accum NUMBER;
        V_remain NUMBER;
        V_sumins NUMBER;
        PAYABLE_AMT NUMBER;
                
        v_SID number(10);
        v_cnt   number(4);    
        POL_NO  VARCHAR2(20); 
        POL_RUN   NUMBER;
        x_fleet_seq NUMBER;
    BEGIN
        PAYABLE_AMT := 0;
        p_acc_package.read_pol(POLICY_NO,POL_NO,POL_RUN);
        
        if nvl(FLEET_SEQ,1) = 0 then
            x_fleet_seq := 1;
        else
            x_fleet_seq :=  nvl(FLEET_SEQ,1) ;
        end if;
       --*** GET SID ***
        BEGIN
            SELECT sys_context('USERENV', 'SID')+1 into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;         
        
        NC_HEALTH_PACKAGE.GET_COVER_PA (pol_no ,pol_run ,  x_fleet_seq  , premcode ,   c1 ,V_RST);   
        dbms_output.put_line('pol==>'|| pol_no||pol_run||  ' CLAIMAMT:'|| REQUEST_AMT||' Rst:'||v_rst );   
                   
        IF V_RST is null THEN
                    
            LOOP
               FETCH  c1 INTO j_rec1;
                EXIT WHEN c1%NOTFOUND;
                    dbms_output.put_line('Prem==>'||  j_rec1.premcode||  ' SUMINS:'||  j_rec1.sumins );  

                    if not nc_health_package.IS_CHECK_TOTLOSS(j_rec1.premcode) then  -- hide TOTLOSS Prem_code
                        V_accum := GET_ACCUM_AMT2( pol_no , pol_run , x_fleet_seq ,premcode , to_date(lossdate,'dd/mm/rrrr') ,null);
                    else
                        V_accum := 0;                     
                    end if;
                        
                    dbms_output.put_line('get Accum Amount :'||v_accum);
                    
                    if nc_health_package.IS_CHECK_PERTIME(j_rec1.premcode) then  -- check Claim per Time ??
                        v_sumins := j_rec1.sumins * nvl(nc_health_package.GET_MAXDAY(j_rec1.premcode),1);
                    else
                        v_sumins := j_rec1.sumins;
                    end if;
                    
                    dbms_output.put_line('get Sum ins :'||v_sumins);
                    
                    V_remain :=  (v_sumins - v_accum ); 
                    if v_remain<0 then v_remain := 0 ; end if;
                    
                    if v_remain >= REQUEST_AMT then
                        PAYABLE_AMT := REQUEST_AMT;
                    else
                        PAYABLE_AMT := v_remain;                    
                    end if;
            END LOOP;      -- End    Get Cover_PA 
            REMAIN_AMT := PAYABLE_AMT;
    
        END IF;               
    END;    --  CHECK_LIMIT no Cursor

    PROCEDURE CHECK_LIMIT(POLICY_NO  IN  VARCHAR2 ,FLEET_SEQ IN  NUMBER ,RECPT_SEQ IN  NUMBER , LOSSDATE IN   VARCHAR2, PREMCODE  IN  VARCHAR2,REQUEST_AMT IN NUMBER 
     ,REMAIN_AMT OUT NUMBER) IS
        c1   NC_HEALTH_PACKAGE.v_ref_cursor1;  

        TYPE t_data1 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        SUMINS  NUMBER,
        PREMCOL NUMBER
        ); 
        j_rec1 t_data1;   
                
        V_RST VARCHAR2(100);   
        V_accum NUMBER;
        V_remain NUMBER;
        V_sumins NUMBER;
        PAYABLE_AMT NUMBER;
                
        v_SID number(10);
        v_cnt   number(4);    
        POL_NO  VARCHAR2(20); 
        POL_RUN   NUMBER;
        x_fleet_seq NUMBER;
    BEGIN
        PAYABLE_AMT := 0;
        p_acc_package.read_pol(POLICY_NO,POL_NO,POL_RUN);
        
        if nvl(FLEET_SEQ,1) = 0 then
            x_fleet_seq := 1;
        else
            x_fleet_seq :=  nvl(FLEET_SEQ,1) ;
        end if;
       --*** GET SID ***
        BEGIN
            SELECT sys_context('USERENV', 'SID')+1 into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;         
        
        NC_HEALTH_PACKAGE.GET_COVER_PA (pol_no ,pol_run ,  x_fleet_seq ,RECPT_SEQ ,to_date(lossdate,'dd/mm/rrrr') , premcode ,   c1 ,V_RST);   
        dbms_output.put_line('pol==>'|| pol_no||pol_run||  ' CLAIMAMT:'|| REQUEST_AMT||' Rst:'||v_rst );   
                   
        IF V_RST is null THEN
                    
            LOOP
               FETCH  c1 INTO j_rec1;
                EXIT WHEN c1%NOTFOUND;
                    dbms_output.put_line('Prem==>'||  j_rec1.premcode||  ' SUMINS:'||  j_rec1.sumins );  

                    if not nc_health_package.IS_CHECK_TOTLOSS(j_rec1.premcode) then  -- hide TOTLOSS Prem_code
                        V_accum := GET_ACCUM_AMT2( pol_no , pol_run , x_fleet_seq ,premcode , to_date(lossdate,'dd/mm/rrrr') ,null);
                    else
                        V_accum := 0;                     
                    end if;
                        
                    dbms_output.put_line('get Accum Amount :'||v_accum);
                    
                    if nc_health_package.IS_CHECK_PERTIME(j_rec1.premcode) then  -- check Claim per Time ??
                        v_sumins := j_rec1.sumins * nvl(nc_health_package.GET_MAXDAY(j_rec1.premcode),1);
                    else
                        v_sumins := j_rec1.sumins;
                    end if;
                    
                    dbms_output.put_line('get Sum ins :'||v_sumins);
                    
                    V_remain :=  (v_sumins - v_accum ); 
                    if v_remain<0 then v_remain := 0 ; end if;
                    
                    if v_remain >= REQUEST_AMT then
                        PAYABLE_AMT := REQUEST_AMT;
                    else
                        PAYABLE_AMT := v_remain;                    
                    end if;
            END LOOP;      -- End    Get Cover_PA 
            REMAIN_AMT := PAYABLE_AMT;
    
        END IF;               
    END;    --  CHECK_LIMIT no Cursor add Recpt
        
    PROCEDURE CHECK_LIMIT(P_DATA  IN v_ref_cursor2 , P_CHK_LIMIT  OUT v_ref_cursor3 ,RST OUT VARCHAR2 )  IS
        c1   NC_HEALTH_PACKAGE.v_ref_cursor1;      
        c2   NC_HEALTH_PACKAGE.v_ref_cursor2; 
        c3   NC_HEALTH_PACKAGE.v_ref_cursor3;
        --tnum number;
        TYPE t_data1 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        SUMINS  NUMBER,
        PREMCOL NUMBER
        ); 
        j_rec1 t_data1;   

        TYPE t_data2 IS RECORD
        (
        POL_NO    VARCHAR2(20),
        POL_RUN  NUMBER ,
        FLEET_SEQ  NUMBER ,
        PLAN    VARCHAR2(2),
        LOSSDATE    VARCHAR2(10), --dd/mm/rrrr
        PREMCODE    VARCHAR2(10),
        REQUEST_AMT  NUMBER 
        ); 
        j_rec2 t_data2;        

        TYPE t_data3 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        SUMINS  NUMBER,
        REQUEST_AMT NUMBER ,
        MAX_COVER_AMT NUMBER ,
        REMAIN_AMT NUMBER
        ); 
        j_rec3 t_data3;   
                   
        V_RST VARCHAR2(100);   
        V_accum NUMBER;
        V_remain NUMBER;
        v_SID number(10);
        v_cnt   number(4);
        --check_limit_data(pol_no ,pol_run ,fleet_seq  ,plan ,loss_date ,prem_code ,claim_amt)        
    BEGIN
        RST := null;v_cnt := 0;
       --*** GET SID ***
        BEGIN
            SELECT sys_context('USERENV', 'SID')+1 into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;            
        
        LOOP  -- นำข้อมูลมาตรวจสอบความคุ้มครอง
           FETCH  P_DATA INTO j_rec2;
            EXIT WHEN P_DATA%NOTFOUND;

               
                NC_HEALTH_PACKAGE.GET_COVER_PA ( j_rec2.pol_no , j_rec2.pol_run ,  j_rec2.fleet_seq , j_rec2.premcode ,   c1 ,V_RST);   
                dbms_output.put_line('pol==>'||  j_rec2.pol_no||j_rec2.pol_run||  ' CLAIMAMT:'||  j_rec2.REQUEST_AMT||' Rst:'||v_rst );   
                   
                IF V_RST is null THEN
                    
                    LOOP
                       FETCH  c1 INTO j_rec1;
                        EXIT WHEN c1%NOTFOUND;
                            dbms_output.put_line('Prem==>'||  j_rec1.premcode||  ' SUMINS:'||  j_rec1.sumins );  
                            --V_accum := 0; 
                            V_accum := NC_HEALTH_PACKAGE.GET_ACCUM_AMT( j_rec2.pol_no , j_rec2.pol_run ,  j_rec2.fleet_seq , j_rec2.premcode , to_date(j_rec2.lossdate,'dd/mm/rrrr') ,null);    
                            dbms_output.put_line('get Accum Amount :'||v_accum);
                            V_remain :=  (j_rec1.sumins - v_accum ); 
                            if v_remain<0 then v_remain := 0 ; end if;
                            if v_remain >= j_rec2.REQUEST_AMT then
                                V_REMAIN := j_rec2.REQUEST_AMT;
                            else
                                V_REMAIN := v_remain;                    
                            end if;                 
                                       
                             BEGIN 
                              --  insert into nc_prem_tmp(SID,  PREMCODE, SUMINS, REQUEST_AMT ,MAX_COVER_AMT ,REMAIN_AMT)
                              --  values (555 , j_rec2.premcode ,  j_rec1.sumins , j_rec2.claim_amt , j_rec1.sumins ,v_remain );
                                
                                insert into nc_prem_tmp(SID,  PREMCODE, SUMINS, REQUEST_AMT ,MAX_COVER_AMT ,REMAIN_AMT)
                                values (v_SID ,  j_rec2.premcode , j_rec1.sumins , j_rec2.REQUEST_AMT , j_rec1.sumins , v_remain  );
                                v_cnt:=v_cnt+1;
                                dbms_output.put_line('cnt :'||v_cnt||' SID=:'||v_sid);
                             EXCEPTION
                               WHEN  OTHERS THEN
                               OPEN P_CHK_LIMIT  FOR SELECT '' PREMCODE ,'' SUMINS ,'' REQUEST_AMT ,'' MAX_COVER_AMT ,'' REMAIN_AMT FROM DUAL;
                               RST := 'error 1: '||sqlerrm; 
                               dbms_output.put_line('error insert :'||sqlerrm);
                               --rollback;
                             END;                        
                    END LOOP;      -- End    Get Cover_PA 
                    COMMIT;      
                END IF;                   
        END LOOP;         

        BEGIN
           OPEN P_CHK_LIMIT  FOR 
               SELECT PREMCODE, SUMINS , REQUEST_AMT ,MAX_COVER_AMT ,REMAIN_AMT
               FROM   NC_PREM_TMP
               WHERE   SID =V_SID;              
          
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
            OPEN P_CHK_LIMIT  FOR SELECT '' PREMCODE ,'' SUMINS ,'' REQUEST_AMT ,'' MAX_COVER_AMT ,'' REMAIN_AMT FROM DUAL;
            RST := 'not found coverage';         
          WHEN  OTHERS THEN
            OPEN P_CHK_LIMIT  FOR SELECT '' PREMCODE ,'' SUMINS ,'' REQUEST_AMT ,'' MAX_COVER_AMT ,'' REMAIN_AMT FROM DUAL;
            RST := 'error 2: '||sqlerrm; 
        END;  
    /**/ 
        BEGIN
               DELETE NC_PREM_TMP
               WHERE   SID = V_SID;              
          
        EXCEPTION
          WHEN  OTHERS THEN
            --OPEN P_COVER_PA  FOR SELECT '' PREMCODE ,'' SUMINS FROM DUAL;
            rollback;
            return;
        END;                       
                            
        COMMIT;       
    
    END;        -- END   CHECK_LIMIT  

    PROCEDURE CHECK_LIMIT(POLICY_NO  IN  VARCHAR2 ,FLEET_SEQ IN  NUMBER , LOSSDATE IN   VARCHAR2, PREMCODE  IN  VARCHAR2,REQUEST_AMT IN NUMBER
    , CLM_NO  IN  VARCHAR2   ,REMAIN_AMT OUT NUMBER) IS
        c1   NC_HEALTH_PACKAGE.v_ref_cursor1;  

        TYPE t_data1 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        SUMINS  NUMBER,
        PREMCOL NUMBER
        ); 
        j_rec1 t_data1;   
                
        V_RST VARCHAR2(100);   
        V_accum NUMBER;
        V_remain NUMBER;
        V_sumins NUMBER;
        PAYABLE_AMT NUMBER;
        
        v_SID number(10);
        v_cnt   number(4);    
        POL_NO  VARCHAR2(20); 
        POL_RUN   NUMBER;
        x_fleet_seq NUMBER;
    BEGIN
        PAYABLE_AMT := 0;
        p_acc_package.read_pol(POLICY_NO,POL_NO,POL_RUN);
        if nvl(FLEET_SEQ,1) = 0 then
            x_fleet_seq := 1;
        else
            x_fleet_seq :=  nvl(FLEET_SEQ,1) ;
        end if;    
       --*** GET SID ***
        BEGIN
            SELECT sys_context('USERENV', 'SID')+1 into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;         
        
        NC_HEALTH_PACKAGE.GET_COVER_PA (pol_no ,pol_run ,  x_fleet_seq , premcode ,   c1 ,V_RST);   
        dbms_output.put_line('pol==>'|| pol_no||pol_run||  ' CLAIMAMT:'|| REQUEST_AMT||' Rst:'||v_rst );   
                   
        IF V_RST is null THEN
                    
            LOOP
               FETCH  c1 INTO j_rec1;
                EXIT WHEN c1%NOTFOUND;
                    dbms_output.put_line('Prem==>'||  j_rec1.premcode||  ' SUMINS:'||  j_rec1.sumins );  

                    if not nc_health_package.IS_CHECK_TOTLOSS(j_rec1.premcode) then  -- hide TOTLOSS Prem_code
                        V_accum := GET_ACCUM_AMT2( pol_no , pol_run , x_fleet_seq ,premcode , to_date(lossdate,'dd/mm/rrrr') ,CLM_NO);
                    else
                        V_accum := 0;                     
                    end if;
                        
                    dbms_output.put_line('get Accum Amount :'||v_accum);
                    
                    if nc_health_package.IS_CHECK_PERTIME(j_rec1.premcode) then  -- check Claim per Time ??
                        v_sumins := j_rec1.sumins * nvl(nc_health_package.GET_MAXDAY(j_rec1.premcode),1);
                    else
                        v_sumins := j_rec1.sumins;
                    end if;
                    
                    dbms_output.put_line('get Sum ins :'||v_sumins);
                    
                    V_remain :=  (v_sumins - v_accum ); 
                    if v_remain<0 then v_remain := 0 ; end if;
                    
                    if v_remain >= REQUEST_AMT then
                        PAYABLE_AMT := REQUEST_AMT;
                    else
                        PAYABLE_AMT := v_remain;                    
                    end if;
            END LOOP;      -- End    Get Cover_PA 
            REMAIN_AMT := PAYABLE_AMT;
    
        END IF;           
    END;    --  CHECK_LIMIT *new  no Cursor + Clm_no     
    
    PROCEDURE CHECK_LIMIT(POLICY_NO  IN  VARCHAR2 ,FLEET_SEQ IN  NUMBER ,RECPT_SEQ IN  NUMBER , LOSSDATE IN   VARCHAR2, PREMCODE  IN  VARCHAR2,REQUEST_AMT IN NUMBER
    , CLM_NO  IN  VARCHAR2   ,REMAIN_AMT OUT NUMBER) IS
        c1   NC_HEALTH_PACKAGE.v_ref_cursor1;  

        TYPE t_data1 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        SUMINS  NUMBER,
        PREMCOL NUMBER
        ); 
        j_rec1 t_data1;   
                
        V_RST VARCHAR2(100);   
        V_accum NUMBER;
        V_remain NUMBER;
        V_sumins NUMBER;
        PAYABLE_AMT NUMBER;
        
        v_SID number(10);
        v_cnt   number(4);    
        POL_NO  VARCHAR2(20); 
        POL_RUN   NUMBER;
        x_fleet_seq NUMBER;
    BEGIN
        PAYABLE_AMT := 0;
        p_acc_package.read_pol(POLICY_NO,POL_NO,POL_RUN);
        if nvl(FLEET_SEQ,1) = 0 then
            x_fleet_seq := 1;
        else
            x_fleet_seq :=  nvl(FLEET_SEQ,1) ;
        end if;    
       --*** GET SID ***
        BEGIN
            SELECT sys_context('USERENV', 'SID')+1 into v_SID
            FROM DUAL;
        EXCEPTION
          WHEN  NO_DATA_FOUND THEN
          v_SID := 0;        
          WHEN  OTHERS THEN
          v_SID := 0;
        END;         
        
        NC_HEALTH_PACKAGE.GET_COVER_PA (pol_no ,pol_run ,  x_fleet_seq , RECPT_SEQ ,to_date(lossdate,'dd/mm/rrrr') , premcode ,   c1 ,V_RST);   
        dbms_output.put_line('pol==>'|| pol_no||pol_run||  ' CLAIMAMT:'|| REQUEST_AMT||' Rst:'||v_rst );   
                   
        IF V_RST is null THEN
                    
            LOOP
               FETCH  c1 INTO j_rec1;
                EXIT WHEN c1%NOTFOUND;
                    dbms_output.put_line('Prem==>'||  j_rec1.premcode||  ' SUMINS:'||  j_rec1.sumins );  

                    if not nc_health_package.IS_CHECK_TOTLOSS(j_rec1.premcode) then  -- hide TOTLOSS Prem_code
                        V_accum := GET_ACCUM_AMT2( pol_no , pol_run , x_fleet_seq ,premcode , to_date(lossdate,'dd/mm/rrrr') ,CLM_NO);
                    else
                        V_accum := 0;                     
                    end if;
                        
                    dbms_output.put_line('get Accum Amount :'||v_accum);
                    
                    if nc_health_package.IS_CHECK_PERTIME(j_rec1.premcode) then  -- check Claim per Time ??
                        v_sumins := j_rec1.sumins * nvl(nc_health_package.GET_MAXDAY(j_rec1.premcode),1);
                    else
                        v_sumins := j_rec1.sumins;
                    end if;
                    
                    dbms_output.put_line('get Sum ins :'||v_sumins);
                    
                    V_remain :=  (v_sumins - v_accum ); 
                    if v_remain<0 then v_remain := 0 ; end if;
                    
                    if v_remain >= REQUEST_AMT then
                        PAYABLE_AMT := REQUEST_AMT;
                    else
                        PAYABLE_AMT := v_remain;                    
                    end if;
            END LOOP;      -- End    Get Cover_PA 
            REMAIN_AMT := PAYABLE_AMT;
    
        END IF;           
    END;    --  CHECK_LIMIT *new  no Cursor + Clm_no     add recpt_seq
        
    PROCEDURE SAVE_STEP1(P_FAX IN VARCHAR2 ,vSTS_KEY IN NUMBER  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2) IS   -- Bypass CURSOR input
        P_MASTER   NC_HEALTH_PACKAGE.v_ref_cursor1;        
        P_DETAIL   NC_HEALTH_PACKAGE.v_ref_cursor2;    
        P_RST2  NC_HEALTH_PACKAGE.v_ref_cursor3;
        --P_JOB   NC_HEALTH_PA\
        x_polno VARCHAR2(100);
        v_polno VARCHAR2(20);
        v_pol_run number;
        v_user  VARCHAR2(20);
        v_sid   number;
    BEGIN
            begin
                   SELECT A.POLICY_NO ,A.HPT_USER  into x_polno ,v_user
                    FROM NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY AND ROWNUM=1;                  
            exception
                when no_data_found then
                    x_polno := null ;
                when others then
                    x_polno := null ;
            end;
            
            IF  x_polno is null  THEN
                RST := 'Not Found MASTER Data for save!!';
                
                OPEN P_JOBNO FOR
                SELECT  0  STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;   
                       
                return;                       
            END IF;
              
            OPEN P_MASTER FOR
            SELECT A.STS_KEY,       A.INVOICE,       A.CLM_TYPE,       A.POLICY_NO,       A.FLEET_SEQ,  A.RECPT_SEQ ,       A.NAME,       A.SURNAME,       A.HN,
            A.ICD10,       A.CAUSE_CODE,       A.RISK_DESC,       A.LOSS_DATE,       A.FR_LOSS_DATE,       A.TO_LOSS_DATE,       A.HPT_CODE,       A.DAY,       A.HPT_USER
            ,A.Remark  ,A.EVN_DESC ,A.SUB_CAUSE_CODE ,GRP_SEQ
            FROM NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY AND ROWNUM=1;  
            
            OPEN P_DETAIL FOR
            SELECT B.PREMCODE, B.REQUEST_AMT, B.REMAIN_AMT
            FROM NC_DETAIL_TMP B WHERE B.STS_KEY = vSTS_KEY ; 
          
            BEGIN
            DELETE NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY;
            DELETE NC_DETAIL_TMP A WHERE A.STS_KEY = vSTS_KEY;
            EXCEPTION
                WHEN OTHERS THEN
                    null;
            END;
/*             */
            COMMIT;
         /*    */
         
            p_acc_package.read_pol(x_polno ,v_polno ,v_pol_run);
            
            IF IS_UNNAME_POLICY(v_polno ,v_pol_run) THEN
                NC_HEALTH_PACKAGE.SAVE_UNNAME_CLAIM( P_MASTER ,P_DETAIL ,P_JOBNO ,RST) ;
            ELSE
                NC_HEALTH_PACKAGE.SAVE_STEP1(P_FAX ,P_MASTER ,P_DETAIL ,P_JOBNO ,RST) ;            
            END IF;         
            
            IF RST is null THEN -- for MEDSTS12
                if substr(nvl(v_user,'H'),1,1) not in ('H','B') then -- BKI Staff keyin Job
                    IF NOT IS_UNNAME_POLICY(v_polno ,v_pol_run) THEN -- exception case UNNAME do not send bill process
                        v_sid := gen_sid();
                        Insert into ALLCLM.NC_MASTER_TMP
                        (STS_KEY, CLM_NO , HPT_USER ,HPT_CODE ,SID )
                        (select A.STS_KEY ,A.CLM_NO ,clm_user ,hpt_code  ,v_sid from nc_mas a                
                        where sts_key =vSTS_KEY
                        ) ;                 
                        
                        COMMIT;
                        NC_HEALTH_PACKAGE.SAVE_STEP3(v_sid ,P_RST2) ;  
                    END IF;   
                end if;
            END IF;
            
            IF RST is null THEN     -- update Clm_no MM
                p_clm_mm.NMC_INS_UPD_MASTER(vSTS_KEY,'U_MED_CLM' ,v_user);
            END IF;                        
        
    END;  -- END SAVE STEP1 byPass CURSOR 
                            
    PROCEDURE SAVE_STEP1(P_FAX IN VARCHAR2 ,P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2) IS
        TYPE t_data4 IS RECORD
        (
        STS_KEY  NUMBER,
        INVOICE    VARCHAR2(20),
        CLM_TYPE    VARCHAR2(3),
        POLICY_NO    VARCHAR2(50),
        FLEET_SEQ  NUMBER ,
        RECPT_SEQ  NUMBER ,
        NAME    VARCHAR2(200),
        SURNAME    VARCHAR2(200),
        HN    VARCHAR2(20),
        ICD10    VARCHAR2(20),
        CAUSE_CODE    VARCHAR2(20),
        RISK_DESC    VARCHAR2(200),
        LOSS_DATE    VARCHAR2(10), --dd/mm/rrrr
        FR_LOSS_DATE    VARCHAR2(10),
        TO_LOSS_DATE    VARCHAR2(10),
        HPT_CODE   VARCHAR2(20), 
        DAY   NUMBER,
        HPT_USER    VARCHAR2(10),
        REMARK      VARCHAR2(200),
        EVN_DESC    VARCHAR2(200),
        SUB_CAUSE_CODE VARCHAR2(10),
        GRP_SEQ NUMBER
        ); 
        j_rec4 t_data4;     
    
        TYPE t_data1 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        REQUEST_AMT  NUMBER,
        REMAIN_AMT NUMBER
        ); 
        j_rec1 t_data1;            
        
        C2   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data2 IS RECORD
        (
        POL_NO  MIS_RI_MAS.POL_NO%TYPE ,
        POL_RUN MIS_RI_MAS.POL_RUN%TYPE ,
        RI_CODE MIS_RI_MAS.RI_CODE%TYPE ,
        RI_BR_CODE MIS_RI_MAS.RI_BR_CODE%TYPE ,
        RI_TYPE MIS_RI_MAS.RI_TYPE%TYPE ,
        LF_FLAG MIS_RI_MAS.LF_FLAG%TYPE ,
        RI_SUB_TYPE MIS_RI_MAS.RI_SUB_TYPE%TYPE ,
        --RI_SUM  MIS_RI_MAS.RI_SUM_INS%TYPE ,
        --RI_SUM  NUMBER(20,2),
        RI_SUM_SHR   NUMBER     
        ); 
        j_rec2 t_data2;      
                
        v_key   number;     
        v_cnt_res   number;      
        v_tot_res   number:= 0;           
        v_shr_amt   number(13,2);
        v_sum_res   number:=0;
        v_rec   number:=0;     
        v_logrst    varchar2(200);        
        
        vSTS_KEY NC_MAS.STS_KEY%TYPE ;
        vCLM_NO NC_MAS.CLM_NO%TYPE ;
        vREG_NO NC_MAS.REG_NO%TYPE ;
        vPOL_NO NC_MAS.POL_NO%TYPE ;
        vPOL_RUN NC_MAS.POL_RUN%TYPE ;
        vEND_SEQ NC_MAS.END_SEQ%TYPE := 0;
        vRECPT_SEQ NC_MAS.RECPT_SEQ%TYPE :=1;
        vALC_RE NC_MAS.ALC_RE%TYPE ;
        vCLM_YR NC_MAS.CLM_YR%TYPE ;
        vPOL_YR NC_MAS.POL_YR%TYPE ;
        vPROD_GRP NC_MAS.PROD_GRP%TYPE ;
        vPROD_TYPE     NC_MAS.PROD_TYPE%TYPE ;
        vINVOICE_NO NC_MAS.INVOICE_NO%TYPE ;
        vHN_NO NC_MAS.HN_NO%TYPE ;
        vHPT_CODE NC_MAS.HPT_CODE%TYPE ;
        vMAS_CUS_CODE NC_MAS.MAS_CUS_CODE%TYPE ;
        vMAS_CUS_SEQ NC_MAS.MAS_CUS_SEQ%TYPE ;
        vMAS_CUS_NAME NC_MAS.MAS_CUS_NAME%TYPE ;
        vCUS_CODE NC_MAS.CUS_CODE%TYPE ;
        vCUS_SEQ NC_MAS.CUS_SEQ%TYPE ;
        vCUS_NAME   NC_MAS.CUS_NAME%TYPE ;
        vFAX_CLM NC_MAS.FAX_CLM%TYPE ;
        vFAX_CLM_DATE NC_MAS.FAX_CLM_DATE%TYPE ;
        vREG_DATE NC_MAS.REG_DATE%TYPE ;
        vCLM_DATE NC_MAS.CLM_DATE%TYPE ;
        vLOSS_DATE NC_MAS.LOSS_DATE%TYPE ;
        vFR_DATE NC_MAS.FR_DATE%TYPE ;
        vTO_DATE NC_MAS.TO_DATE%TYPE ;
        vTR_DATE_FR NC_MAS.TR_DATE_FR%TYPE ;
        vTR_DATE_TO NC_MAS.TR_DATE_TO%TYPE ;
        vADD_TR_DAY NC_MAS.ADD_TR_DAY%TYPE ;
        vTOT_TR_DAY NC_MAS.TOT_TR_DAY%TYPE ;
        vLOSS_DETAIL NC_MAS.LOSS_DETAIL%TYPE ; 
        vIPD_FLAG NC_MAS.IPD_FLAG%TYPE ;
        vDIS_CODE NC_MAS.DIS_CODE%TYPE ;
        vCAUSE_CODE   NC_MAS.CAUSE_CODE%TYPE ;
        vFLEET_SEQ    NC_MAS.FLEET_SEQ%TYPE ;
        vRUN_FLEET_SEQ       NC_MAS.RUN_FLEET_SEQ%TYPE ;
        vMAS_SUM_INS   NC_MAS.MAS_SUM_INS%TYPE ;
        vCLM_USER   NC_MAS.CLM_USER%TYPE ;
        vRemark     NC_MAS.REMARK%TYPE ;
        --vEvndesc    NC_MAS.EVN_DESC%TYPE ;
        vIDNO    NC_MAS.ID_NO%TYPE ;
        vSub_Cause  NC_MAS.SUB_CAUSE_CODE%TYPE ;
        vGRP_SEQ    NC_MAS.GRP_SEQ%TYPE ;
        
        vYour_Pol   MIS_CRI_RES.YOUR_POL%TYPE;
        vLett_Prt   MIS_CRI_RES.LETT_PRT%TYPE;
        vLett_no   MIS_CRI_RES.LETT_NO%TYPE;
        
        vMax_Sts_seq    number(3);
        vExist    varchar2(5);        
    BEGIN
        RST := null;
        LOOP  -- get Master Data
           FETCH  P_MASTER INTO j_rec4;
            EXIT WHEN P_MASTER%NOTFOUND;
            dbms_output.put_line('Invoice==>'||  j_rec4.invoice||  ' ClmType:'||  j_rec4.clm_type|| ' Pol_no/Run:'||  j_rec4.policy_no|| ' LossDate:'||  j_rec4.loss_date); 
            
            if nvl(j_rec4.sts_key,0) = 0 then
            v_key := gen_stskey(''); -- สร้าง STS_KEY
            else 
            v_key := j_rec4.sts_key;             
            end if;
            
            begin
                select  nvl(max(sts_seq),0) into vMax_Sts_seq
                from nc_status
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_Sts_seq := 0;
                when others then
                    vMax_Sts_seq := 0;
            end;
            
            p_acc_package.read_pol(j_rec4.policy_no ,vPOL_NO ,vPOL_RUN);
            
            begin
                  SELECT POL_YR,  PROD_TYPE, prod_grp, to_char(sysdate,'rrrr') clm_yr ,
                         CUS_CODE, CUS_SEQ, substr(CUS_ENQ,1,90), ALC_RE ,SUM_INS ,END_SEQ
                  INTO
                         vPOL_YR, vPROD_TYPE, vprod_grp, vCLM_YR ,
                         vMAS_CUS_CODE, vMAS_CUS_SEQ, vMAS_CUS_NAME  , vALC_RE ,vMAS_SUM_INS ,vEND_SEQ
                    FROM MIS_MAS
                    WHERE POL_NO = vPOL_NO AND
                            nvl(pol_run,0) = vPOL_RUN and
                              END_SEQ = (SELECT MAX(END_SEQ) FROM MIS_MAS
                                         WHERE POL_NO =vPOL_NO AND 
                                               nvl(pol_run,0) = vPOL_RUN and
                                               (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE));                  
            exception
                when no_data_found then
                    RST :='not found policy no :'||j_rec4.policy_no;
                when others then
                    RST :='not found policy no :'||j_rec4.policy_no;
            end;
                                
            BEGIN
            SELECT MIN(FR_DATE),MAX(TO_DATE)
            INTO vFR_DATE,vTO_DATE
            FROM MIS_MAS
            WHERE POL_NO =vPOL_NO AND
                  nvl(pol_run,0) = to_number(vPOL_RUN) and
                  (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE);
                                  
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
              null;
              WHEN OTHERS THEN null;
            END;       
                  
            begin
                select recpt_seq ,cus_code ,cus_seq ,cus_enq 
                into vRECPT_SEQ ,vCUS_CODE ,vCUS_SEQ , vCUS_NAME
                from mis_recpt
                where pol_no =vPOL_NO and pol_run =vPOL_RUN    
                and end_seq = vEND_SEQ
                --and recpt_seq in (select min(x.recpt_seq) from mis_recpt x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  
                --and x.end_seq = vEND_SEQ and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)               
                --)
                and recpt_seq = j_rec4.recpt_seq ;            
            exception
                when no_data_found then
                    --RST :='not found mis_recpt  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
                    begin
                        select recpt_seq ,cus_code ,cus_seq ,cus_enq 
                        into vRECPT_SEQ ,vCUS_CODE ,vCUS_SEQ , vCUS_NAME
                        from mis_recpt a
                        where pol_no =vPOL_NO and pol_run =vPOL_RUN   
                        --and end_seq = 0 
                        --and end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
                        --and recpt_seq in (select min(x.recpt_seq) from mis_recpt x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  
                            --and x.end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
                            --and x.end_seq =0 
                          --  and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)
                        --)
                         and recpt_seq = j_rec4.recpt_seq;            
                    exception
                        when no_data_found then
                            begin
                                select recpt_seq ,cus_code ,cus_seq ,cus_enq 
                                into vRECPT_SEQ ,vCUS_CODE ,vCUS_SEQ , vCUS_NAME
                                from mis_recpt a
                                where pol_no =vPOL_NO and pol_run =vPOL_RUN   
                                and end_seq = vEND_SEQ
                                --and end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
                                and recpt_seq in (select min(x.recpt_seq) from mis_recpt x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  
                                    --and x.end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
                                    and x.end_seq =vEND_SEQ 
                                    --and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)
                                );            
                            exception
                                when no_data_found then
                                    RST :='in not found mis_recpt1  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
                                when others then
                                    RST :='in other mis_recpt1  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
                            end;                                 
                            --RST :='in not found mis_recpt2  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
                        when others then
                            RST :='in other mis_recpt2  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
                    end;                    
                when others then
                    RST :='in other mis_recpt3 :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
            end;
                       
            vREG_DATE := trunc(sysdate);
            vCLM_DATE := trunc(sysdate);
            vHN_NO := j_rec4.HN;
            --vHPT_CODE := j_rec4.HPT_CODE;
            vHPT_CODE := nc_health_package.GET_BKI_HPTCODE(j_rec4.HPT_CODE);
            vCAUSE_CODE := j_rec4.CAUSE_CODE; 
            vDIS_CODE :=  j_rec4.ICD10; 
            vIPD_FLAG :=  j_rec4.CLM_TYPE; 
            vLOSS_DETAIL := j_rec4.RISK_DESC ;
            vFLEET_SEQ := j_rec4.FLEET_SEQ;
            vRECPT_SEQ := j_rec4.RECPT_SEQ; -- รับ recpt โดยตรงจาก web med เลย
            vINVOICE_NO :=  j_rec4.INVOICE;
            vLOSS_DATE := to_date(j_rec4.LOSS_DATE,'dd/mm/rrrr'); 
            vCLM_USER := j_rec4.HPT_USER;   
            vTR_DATE_FR :=  to_date(j_rec4.FR_LOSS_DATE,'dd/mm/rrrr'); 
            vTR_DATE_TO :=  to_date(j_rec4.TO_LOSS_DATE,'dd/mm/rrrr'); 
            vTOT_TR_DAY := j_rec4.DAY;   
            vRemark := j_rec4.Remark;   -- เก็บ free text สถานพยาบาล 
            --vEvndesc := j_rec4.Evn_desc;
            vSub_Cause := j_rec4.SUB_CAUSE_CODE ;
            vGRP_SEQ    := j_rec4.GRP_SEQ;
            
            IF vDIS_CODE is null THEN  -- กรณีไม่ระบุ icd จะนำ free text มาบันทึกแทน
                vLOSS_DETAIL := j_rec4.Evn_desc;
            END IF;
            

            begin
                select  title||' '||name||' '||surname , id
                into  vCUS_NAME ,vIDNO
                from mis_pa_prem
                where pol_no =vPOL_NO and pol_run =vPOL_RUN    
                and fleet_seq = vFLEET_SEQ  
--                and END_SEQ = (SELECT MAX(END_SEQ) FROM mis_pa_prem
--                                         WHERE POL_NO =vPOL_NO AND 
--                                               nvl(pol_run,0) = vPOL_RUN and fleet_seq = vFLEET_SEQ and
--                                               (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE))
--                 AND recpt_seq in (select min(x.recpt_seq) from mis_pa_prem x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  and fleet_seq= vFLEET_SEQ
--                and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)
--                --and x.end_seq = vEND_SEQ
--                 )
                 and recpt_seq = j_rec4.recpt_seq;            
            exception
                when no_data_found then
                    RST :='not found mis_pa_prem :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ|| ' fleet: '||vFLEET_SEQ;
                when others then
                    RST :='other mis_pa_prem :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ|| ' fleet: '||vFLEET_SEQ;
            end;
/**/            
            IF RST is not null THEN  -- ไม่ทำต่อ เพราะไม่เจอ policy
/*                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      */
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                RST := RST || ' ::ปล่อยทำต่อ แต่ข้อมูลไม่สมบูรณ์' ;
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                email_pack_error('Error From Package' , 'module save_step1</br>'||RST) ;
                RST := null; 
                --return;      
            END IF;
            
            if nvl(P_FAX,'N')  = 'Y' then
                vFax_clm := 'Y';
                vFax_Clm_date := trunc(sysdate);
            end if;
            
            vCLM_NO := gen_clmno(vPROD_TYPE,'0');
            
            -- /// เช็คว่ามีรายการรับแจ้งไว้หรือไม่
            begin
                select  'ex'
                into  vExist
                from nc_mas
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vExist :=null ;
                when others then
                    vExist :=null ;
            end;            
            dbms_output.put_line('key:'||v_key||' clm_no:'||vCLM_NO||' Exist: '||vExist);
            if vExist is  null then -- ยังไม่เคยแจ้ง 
                begin 
                    insert into nc_mas 
                    ( sts_key ,clm_no ,pol_no ,pol_run ,end_seq ,recpt_seq ,alc_re ,clm_yr ,pol_yr ,prod_grp ,prod_type 
                    ,invoice_no ,hn_no ,hpt_code ,mas_cus_code ,mas_cus_seq ,mas_cus_name ,cus_code ,cus_seq ,cus_name 
                    ,fax_clm ,fax_clm_date 
                     ,reg_date ,clm_date ,loss_Date ,fr_date ,to_date ,tr_date_fr ,tr_date_to , ADD_TR_DAY ,tot_tr_daY
                    ,loss_detail , ipd_flag ,dis_code ,cause_code
                    ,fleet_seq ,run_fleet_seq ,mas_sum_ins ,clm_user ,remark ,id_no ,SUB_CAUSE_CODE ,GRP_SEQ  )
                    values     
                    (  v_key ,vclm_no ,vpol_no ,vpol_run ,vend_seq ,vrecpt_seq ,valc_re ,vclm_yr ,vpol_yr ,vprod_grp ,vprod_type 
                    ,vinvoice_no ,vhn_no ,vhpt_code ,vmas_cus_code ,vmas_cus_seq ,vmas_cus_name ,vcus_code ,vcus_seq ,vcus_name 
                    ,vfax_clm ,vfax_clm_date 
                     ,vreg_date ,vclm_date ,vloss_Date ,vfr_date ,vto_date ,vtr_date_fr ,vtr_date_to ,vADD_TR_DAY ,vtot_tr_daY
                    ,vloss_detail ,vipd_flag ,vdis_code ,vcause_code
                    ,vfleet_seq ,vrun_fleet_seq  ,vMAS_SUM_INS   ,vCLM_USER  ,vRemark  ,vIDNO ,vSub_Cause ,vGRP_SEQ
                    );
                exception
                    when others then
                        dbms_output.put_line('error insert NC_MAS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error insert NC_MAS: '||sqlerrm;
                end;    
            else
                begin 
                    update nc_mas 
                    set clm_no = vclm_no ,pol_no =vpol_no ,pol_run =vpol_run ,end_seq=vend_seq ,recpt_seq =vrecpt_seq
                    ,alc_re =valc_re ,clm_yr =vclm_yr ,pol_yr =pol_yr ,prod_grp =vprod_grp ,prod_type =vprod_type 
                    ,invoice_no =vinvoice_no ,hn_no =vhn_no ,hpt_code =vhpt_code,mas_cus_code =vmas_cus_code ,mas_cus_seq =vmas_cus_seq 
                    ,mas_cus_name =vmas_cus_name ,cus_code =vcus_code ,cus_seq =vcus_seq ,cus_name =vcus_name
                     ,fax_clm = vfax_clm ,fax_clm_date =vfax_clm_date 
                     ,reg_date =vreg_date ,clm_date =vclm_date ,loss_Date = vloss_Date ,fr_date =vfr_date ,to_date =vto_date  
                     ,tr_date_fr =vtr_date_fr  ,tr_date_to =vtr_date_to , ADD_TR_DAY =vADD_TR_DAY ,tot_tr_daY =vtot_tr_daY
                     ,loss_detail =vloss_detail , ipd_flag =vipd_flag ,dis_code =vdis_code ,cause_code =vcause_code 
                     ,fleet_seq =vfleet_seq ,run_fleet_seq =vrun_fleet_seq ,mas_sum_ins = vMAS_SUM_INS ,clm_user =vCLM_USER ,remark =vRemark       
                     ,id_no = vIDNO  ,SUB_CAUSE_CODE = vSub_Cause  ,GRP_SEQ =  vGRP_SEQ      
                    where sts_key = v_key;
                exception
                    when others then
                        dbms_output.put_line('error update NC_MAS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error update NC_MAS: '||sqlerrm;
                end;              
            end if;
                
            IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
               --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                email_pack_error('Error From Package' , 'module save_step1</br>'||RST) ;
                return;      
            END IF;             
            
            -- check FAX CLM data ---
            IF NVL(P_FAX,'N')  = 'Y' THEN --- Save like send for Approve Fax claim
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  v_key ,vMax_Sts_seq+1 ,'MEDSTS','MEDSTS00' ,'send for Approve FaxClaim ' ,vCLM_USER , sysdate        
                    );
                exception
                    when others then
                        dbms_output.put_line('error insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error insert NC_STATUS: '||sqlerrm;
                end;     
            ELSE    --- Save for Open Claim
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  v_key ,vMax_Sts_seq+1 ,'MEDSTS','MEDSTS11' ,'open claim Phrase2 ' ,vCLM_USER , sysdate        
                    );
                exception
                    when others then
                        dbms_output.put_line('error insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error insert NC_STATUS: '||sqlerrm;
                end;                
            END IF;  -- END check FAX CLM data ---
            
            IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module save_step1</br>'||RST) ;
                return;      
            END IF;                    
                                        
        END LOOP;  -- end get Master Data

        LOOP  -- get detail Data
           FETCH  P_DTL INTO j_rec1;
            EXIT WHEN P_DTL%NOTFOUND;
            dbms_output.put_line('Prem==>'||  j_rec1.PREMCODE||  ' RequestAmt:'||  j_rec1.request_amt|| ' ResAmt:'||  j_rec1.REMAIN_AMT); 
            v_tot_res := v_tot_res +  j_rec1.REMAIN_AMT;
            BEGIN
            insert into nc_reserved (
            sts_key ,clm_no ,prod_grp ,prod_type ,type ,sub_type ,trn_seq ,sts_date 
            ,prem_code ,prem_seq ,req_amt ,res_amt ,disc_amt ,trn_amt ,clm_user            
            ) values (
            v_key ,vClm_no ,vprod_grp ,vprod_type ,'1' ,'01' ,1 ,trunc(sysdate)
            , j_rec1.PREMCODE , 1 , j_rec1.request_amt ,j_rec1.REMAIN_AMT ,0 ,j_rec1.REMAIN_AMT ,vCLM_USER
            ) ;
            exception
                when others then
                    dbms_output.put_line('error insert NC_RESERVED: '||sqlerrm);
                    ROLLBACK;
                    RST := 'error insert NC_RESERVED: '||sqlerrm;
            end;               
            IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module save_step1</br>'||RST) ;
                return;      
            END IF;                    
        END LOOP;  -- end get detail Data        


        if vALC_RE = '1' then
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,0 ,0 ,vloss_Date ,vend_seq ,C2 );
        elsif vALC_RE = '2' then 
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        else
             v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        end if;   
        dbms_output.put_line('count CRI_RES: '||v_cnt_res);
        if v_cnt_res>0 then
            LOOP
               FETCH  C2 INTO j_rec2;
                EXIT WHEN C2%NOTFOUND;
                    v_rec := v_rec+1; 
                    
                    --v_shr_amt   := (v_tot_res* j_rec1.RI_SUM_SHR/100);                
                    if v_rec = v_cnt_res then
                       v_shr_amt := v_tot_res -  v_sum_res;
                    else
                        v_shr_amt   := (v_tot_res* j_rec2.RI_SUM_SHR/100);     
                    end if;
                    v_sum_res := v_sum_res +v_shr_amt;                

                    dbms_output.put_line('RI_CODE==>'|| 
                     j_rec2.ri_code||
                     ' RI_BR_CODE:'||
                      j_rec2.ri_br_code||
                     ' RI_SUM_SHR:'||
                      j_rec2.RI_SUM_SHR|| 
                     ' v_shr_amt:'||v_shr_amt
                    );   
                    
                   -- NC_HEALTH_PACKAGE.YOUR_POL(vpol_no, vpol_run, vrecpt_seq, 0, j_rec2.ri_code, j_rec2.RI_BR_CODE,
                   --    j_rec2.RI_SUB_TYPE, j_rec2.RI_TYPE, j_rec2.LF_FLAG, vLOSS_DATE, vYour_Pol);
                       
                    IF j_rec2.RI_TYPE = '1' THEN
                       IF  v_shr_amt < 50000 THEN
                          vLETT_PRT := 'N';
                       ELSE
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                       END IF;
                    ELSIF j_rec2.RI_TYPE = '0' THEN
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                    ELSE
                          vLETT_PRT := 'N';
                    END IF;                  
                    BEGIN
                      INSERT INTO NC_RI_RESERVED A
                       (
                        A.STS_KEY,  A.CLM_NO, A.PROD_GRP,  A.PROD_TYPE,A.TYPE,A.TRN_SEQ
                        ,A.RI_CODE, A.RI_BR_CODE, A.RI_STS_DATE, A.RI_AMD_DATE     
                        ,A.RI_TYPE, A.RI_RES_AMT ,A.RI_TRN_AMT,A.RI_SHARE          
                        ,A.LETT_NO, A.LETT_PRT, A.LETT_TYPE ,A.RI_LF_FLAG, A.RI_SUB_TYPE        
                        ,A.SUB_TYPE               
                        )
                      VALUES
                       (v_key ,vCLm_no ,vprod_grp ,vprod_type , j_rec2.RI_TYPE ,1,
                        j_rec2.RI_CODE, j_rec2.RI_BR_CODE, trunc(sysdate) , sysdate,
                        j_rec2.RI_TYPE, v_shr_amt , v_shr_amt ,j_rec2.RI_SUM_SHR, 
                        vLETT_NO ,vLETT_PRT, 'P',j_rec2.LF_FLAG,j_rec2.RI_SUB_TYPE
                        ,'NCNATSUBTYPECLM001'); 
                    EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('error insert CRI_RES: '||SQLERRM);
                        ROLLBACK;
                        RST := 'error insert CRI_RES: '||sqlerrm;
                    END;                               

              end loop;    
          end if;      
            IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                email_pack_error('Error From Package' , 'module save_step1</br>'||RST) ;
                return;      
            END IF;        
                                  
        COMMIT;
        
        IF RST is null THEN
            OPEN P_JOBNO FOR
            SELECT  v_key  STS_KEY ,'' NOTICE_NO ,vClm_no CLM_NO FROM DUAL;             
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RST := ' main error :'||sqlerrm;
           -- IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module save_step1</br>'||RST) ;
                return;      
         --   END IF;                    
    END;    -- END    SAVE_STEP1     

    PROCEDURE SAVE_STEP2(vSTS_KEY IN NUMBER  ,
                            RST OUT VARCHAR2) IS   -- Bypass CURSOR input
        P_MASTER   NC_HEALTH_PACKAGE.v_ref_cursor1;        
        P_DETAIL   NC_HEALTH_PACKAGE.v_ref_cursor2;    
        P_JOBNO     NC_HEALTH_PACKAGE.v_ref_cursor3;
        --P_JOB   NC_HEALTH_PA\
        x_polno VARCHAR2(100);
        v_polno VARCHAR2(20);
        v_pol_run number;        
    BEGIN
            begin
                   SELECT A.CLM_NO into x_polno
                    FROM NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY AND ROWNUM=1;                  
            exception
                when no_data_found then
                    x_polno := null ;
                when others then
                    x_polno := null ;
            end;
            
            IF  x_polno is null  THEN
                RST := 'Not Found MASTER Data for save!!';
                       
                return ;                       
            END IF;
            
            OPEN P_MASTER FOR
            SELECT A.STS_KEY,     A.INVOICE,       A.CLM_TYPE,       A.POLICY_NO,       A.FLEET_SEQ,  A.RECPT_SEQ ,       A.NAME,       A.SURNAME,       A.HN,
            A.ICD10,       A.CAUSE_CODE,       A.RISK_DESC,       A.LOSS_DATE,       A.FR_LOSS_DATE,       A.TO_LOSS_DATE,       A.HPT_CODE,       A.DAY,       A.HPT_USER
            ,A.Remark  ,A.EVN_DESC ,A.SUB_CAUSE_CODE ,GRP_SEQ
            FROM NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY AND ROWNUM=1;  
            
            OPEN P_DETAIL FOR
            SELECT B.PREMCODE, B.REQUEST_AMT, B.REMAIN_AMT
            FROM NC_DETAIL_TMP B WHERE B.STS_KEY = vSTS_KEY ; 

            -- +++ check Get Claim BANCAS
            IF IS_BANCAS_CLAIM(vSTS_KEY) THEN
                NC_HEALTH_PACKAGE.UPDATE_BANCAS(null ,vSTS_KEY ,P_JOBNO ,RST) ;
                 RETURN;                       
            ELSE
                begin
                       SELECT A.POLICY_NO into x_polno
                        FROM NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY AND ROWNUM=1;                  
                exception
                    when no_data_found then
                        x_polno := null ;
                    when others then
                        x_polno := null ;
                end;            
                BEGIN
                DELETE NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY;
                DELETE NC_DETAIL_TMP A WHERE A.STS_KEY = vSTS_KEY;
                EXCEPTION
                    WHEN OTHERS THEN
                        null;
                END;
                  
                COMMIT;            
            END IF;
            -- +++ end Sub Module get Claim BANCAS 

            p_acc_package.read_pol(x_polno ,v_polno ,v_pol_run);
            
            IF IS_UNNAME_POLICY(v_polno ,v_pol_run) THEN
                NC_HEALTH_PACKAGE.UPDATE_UNNAME_CLAIM(P_MASTER ,P_DETAIL ,RST) ;      
            ELSE
                NC_HEALTH_PACKAGE.SAVE_STEP2(P_MASTER ,P_DETAIL ,RST) ;            
            END IF;      
                                
    END;  -- END SAVE STEP2 byPass CURSOR     

    PROCEDURE SAVE_STEP2(P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2  ,
                            RST OUT VARCHAR2) IS
        TYPE t_data4 IS RECORD
        (
        STS_KEY  NUMBER,
        INVOICE    VARCHAR2(20),
        CLM_TYPE    VARCHAR2(3),
        POLICY_NO    VARCHAR2(50),
        FLEET_SEQ  NUMBER ,
        RECPT_SEQ  NUMBER ,
        NAME    VARCHAR2(200),
        SURNAME    VARCHAR2(200),
        HN    VARCHAR2(20),
        ICD10    VARCHAR2(20),
        CAUSE_CODE    VARCHAR2(20),
        RISK_DESC    VARCHAR2(200),
        LOSS_DATE    VARCHAR2(10), --dd/mm/rrrr
        FR_LOSS_DATE    VARCHAR2(10),
        TO_LOSS_DATE    VARCHAR2(10),
        HPT_CODE   VARCHAR2(20), 
        DAY   NUMBER,
        HPT_USER    VARCHAR2(10),
        REMARK      VARCHAR2(200),
        EVN_DESC    VARCHAR2(200),
        SUB_CAUSE_CODE VARCHAR2(10),
        GRP_SEQ NUMBER
        ); 
        j_rec4 t_data4;     
    
        TYPE t_data1 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        REQUEST_AMT  NUMBER,
        REMAIN_AMT NUMBER
        ); 
        j_rec1 t_data1;            
        
        C2   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data2 IS RECORD
        (
        POL_NO  MIS_RI_MAS.POL_NO%TYPE ,
        POL_RUN MIS_RI_MAS.POL_RUN%TYPE ,
        RI_CODE MIS_RI_MAS.RI_CODE%TYPE ,
        RI_BR_CODE MIS_RI_MAS.RI_BR_CODE%TYPE ,
        RI_TYPE MIS_RI_MAS.RI_TYPE%TYPE ,
        LF_FLAG MIS_RI_MAS.LF_FLAG%TYPE ,
        RI_SUB_TYPE MIS_RI_MAS.RI_SUB_TYPE%TYPE ,
        --RI_SUM  MIS_RI_MAS.RI_SUM_INS%TYPE ,
        --RI_SUM  NUMBER(20,2),
        RI_SUM_SHR   NUMBER     
        ); 
        j_rec2 t_data2;      
                
        v_key   number;     
        v_cnt_res   number;      
        v_tot_res   number:= 0;           
        v_shr_amt   number(13,2);
        v_sum_res   number:=0;
        v_rec   number:=0;     
        v_logrst    varchar2(200);        
        
        vSTS_KEY NC_MAS.STS_KEY%TYPE ;
        vCLM_NO NC_MAS.CLM_NO%TYPE ;
        vREG_NO NC_MAS.REG_NO%TYPE ;
        vPOL_NO NC_MAS.POL_NO%TYPE ;
        vPOL_RUN NC_MAS.POL_RUN%TYPE ;
        vEND_SEQ NC_MAS.END_SEQ%TYPE := 0;
        vRECPT_SEQ NC_MAS.RECPT_SEQ%TYPE :=1;
        vALC_RE NC_MAS.ALC_RE%TYPE ;
        vCLM_YR NC_MAS.CLM_YR%TYPE ;
        vPOL_YR NC_MAS.POL_YR%TYPE ;
        vPROD_GRP NC_MAS.PROD_GRP%TYPE ;
        vPROD_TYPE     NC_MAS.PROD_TYPE%TYPE ;
        vINVOICE_NO NC_MAS.INVOICE_NO%TYPE ;
        vHN_NO NC_MAS.HN_NO%TYPE ;
        vHPT_CODE NC_MAS.HPT_CODE%TYPE ;
        vMAS_CUS_CODE NC_MAS.MAS_CUS_CODE%TYPE ;
        vMAS_CUS_SEQ NC_MAS.MAS_CUS_SEQ%TYPE ;
        vMAS_CUS_NAME NC_MAS.MAS_CUS_NAME%TYPE ;
        vCUS_CODE NC_MAS.CUS_CODE%TYPE ;
        vCUS_SEQ NC_MAS.CUS_SEQ%TYPE ;
        vCUS_NAME   NC_MAS.CUS_NAME%TYPE ;
        vFAX_CLM NC_MAS.FAX_CLM%TYPE ;
        vFAX_CLM_DATE NC_MAS.FAX_CLM_DATE%TYPE ;
        vREG_DATE NC_MAS.REG_DATE%TYPE ;
        vCLM_DATE NC_MAS.CLM_DATE%TYPE ;
        vLOSS_DATE NC_MAS.LOSS_DATE%TYPE ;
        vFR_DATE NC_MAS.FR_DATE%TYPE ;
        vTO_DATE NC_MAS.TO_DATE%TYPE ;
        vTR_DATE_FR NC_MAS.TR_DATE_FR%TYPE ;
        vTR_DATE_TO NC_MAS.TR_DATE_TO%TYPE ;
        vADD_TR_DAY NC_MAS.ADD_TR_DAY%TYPE ;
        vTOT_TR_DAY NC_MAS.TOT_TR_DAY%TYPE ;
        vLOSS_DETAIL NC_MAS.LOSS_DETAIL%TYPE ; 
        vIPD_FLAG NC_MAS.IPD_FLAG%TYPE ;
        vDIS_CODE NC_MAS.DIS_CODE%TYPE ;
        vCAUSE_CODE   NC_MAS.CAUSE_CODE%TYPE ;
        vFLEET_SEQ    NC_MAS.FLEET_SEQ%TYPE ;
        vRUN_FLEET_SEQ       NC_MAS.RUN_FLEET_SEQ%TYPE ;
        vMAS_SUM_INS   NC_MAS.MAS_SUM_INS%TYPE ;
        vCLM_USER   NC_MAS.CLM_USER%TYPE ;
        vRemark     NC_MAS.REMARK%TYPE ;
        vIDNO   NC_MAS.ID_NO%TYPE ;
        --vEvndesc    NC_MAS.EVN_DESC%TYPE ;
        vSub_Cause   NC_MAS.SUB_CAUSE_CODE%TYPE ;
        vGRP_SEQ    NC_MAS.GRP_SEQ%TYPE ;
        
        vYour_Pol   MIS_CRI_RES.YOUR_POL%TYPE;
        vLett_Prt   MIS_CRI_RES.LETT_PRT%TYPE;
        vLett_no   MIS_CRI_RES.LETT_NO%TYPE;
        
        vMax_Sts_seq    number(3);
        vMax_res_seq    number(3);
        vMax_ri_seq    number(3);
        vExist    varchar2(100);        
        v_RstHISTORY    varchar2(200); 
        x_clmuser   varchar2(10);        
        x_stsdate   date;
    BEGIN
        RST := null;
        LOOP  -- get Master Data
           FETCH  P_MASTER INTO j_rec4;
            EXIT WHEN P_MASTER%NOTFOUND;
            dbms_output.put_line('Invoice==>'||  j_rec4.invoice||  ' ClmType:'||  j_rec4.clm_type|| ' Pol_no/Run:'||  j_rec4.policy_no|| ' LossDate:'||  j_rec4.loss_date); 
            
            if nvl(j_rec4.sts_key,0) = 0 then
            v_key := gen_stskey(''); -- สร้าง STS_KEY
            else 
            v_key := j_rec4.sts_key;             
            end if;
            
            begin
                select  nvl(max(sts_seq),1) into vMax_Sts_seq
                from nc_status
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_Sts_seq := 1;
                when others then
                    vMax_Sts_seq := 1;
            end;
            
            begin
                select  nvl(max(trn_seq),1) into vMax_res_seq
                from nc_reserved
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_res_seq := 1;
                when others then
                    vMax_res_seq := 1;
            end;            

            begin
                select  nvl(max(trn_seq),1) into vMax_ri_seq
                from nc_ri_reserved
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_ri_seq := 1;
                when others then
                    vMax_ri_seq := 1;
            end;                  
            p_acc_package.read_pol(j_rec4.policy_no ,vPOL_NO ,vPOL_RUN);
          
            begin
                  SELECT POL_YR,  PROD_TYPE, prod_grp, to_char(sysdate,'rrrr') clm_yr ,
                         CUS_CODE, CUS_SEQ, substr(CUS_ENQ,1,90), ALC_RE ,SUM_INS ,END_SEQ
                  INTO
                         vPOL_YR, vPROD_TYPE, vprod_grp, vCLM_YR ,
                         vMAS_CUS_CODE, vMAS_CUS_SEQ, vMAS_CUS_NAME  , vALC_RE ,vMAS_SUM_INS ,vEND_SEQ
                    FROM MIS_MAS
                    WHERE POL_NO = vPOL_NO AND
                            nvl(pol_run,0) = vPOL_RUN and
                              END_SEQ = (SELECT MAX(END_SEQ) FROM MIS_MAS
                                         WHERE POL_NO =vPOL_NO AND 
                                               nvl(pol_run,0) = vPOL_RUN and
                                               (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE));                  
            exception
                when no_data_found then
                    RST :='not found policy no :'||j_rec4.policy_no;
                when others then
                    RST :='not found policy no :'||j_rec4.policy_no;
            end;
  /*                                
            BEGIN
            SELECT MIN(FR_DATE),MAX(TO_DATE)
            INTO vFR_DATE,vTO_DATE
            FROM MIS_MAS
            WHERE POL_NO =vPOL_NO AND
                  nvl(pol_run,0) = to_number(vPOL_RUN) and
                  (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE);
                                  
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
              null;
              WHEN OTHERS THEN null;
            END;       
                  
            begin
                select recpt_seq ,cus_code ,cus_seq ,cus_enq 
                into vRECPT_SEQ ,vCUS_CODE ,vCUS_SEQ , vCUS_NAME
                from mis_recpt
                where pol_no =vPOL_NO and pol_run =vPOL_RUN    
                and end_seq = vEND_SEQ
                and recpt_seq in (select min(x.recpt_seq) from mis_recpt x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  
                and x.end_seq = vEND_SEQ and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)
                );            
            exception
                when no_data_found then
                    --RST :='not found mis_recpt  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
                    begin
                        select recpt_seq ,cus_code ,cus_seq ,cus_enq 
                        into vRECPT_SEQ ,vCUS_CODE ,vCUS_SEQ , vCUS_NAME
                        from mis_recpt a
                        where pol_no =vPOL_NO and pol_run =vPOL_RUN   
                        --and end_seq = 0 
                        --and end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
                        and recpt_seq in (select min(x.recpt_seq) from mis_recpt x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  
                            --and x.end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
                            --and x.end_seq =0 
                            and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)
                        );            
                    exception
                        when no_data_found then
                            begin
                                select recpt_seq ,cus_code ,cus_seq ,cus_enq 
                                into vRECPT_SEQ ,vCUS_CODE ,vCUS_SEQ , vCUS_NAME
                                from mis_recpt a
                                where pol_no =vPOL_NO and pol_run =vPOL_RUN   
                                and end_seq = vEND_SEQ
                                --and end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
                                and recpt_seq in (select min(x.recpt_seq) from mis_recpt x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  
                                    --and x.end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
                                    and x.end_seq =vEND_SEQ 
                                    --and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)
                                );            
                            exception
                                when no_data_found then
                                    RST :='in not found mis_recpt1  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
                                when others then
                                    RST :='in other mis_recpt1  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
                            end;                                 
                            --RST :='in not found mis_recpt2  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
                        when others then
                            RST :='in other mis_recpt2  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
                    end;                    
                when others then
                    RST :='in other mis_recpt3 :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
            end;
*/                       
            vREG_DATE := trunc(sysdate);
            vCLM_DATE := trunc(sysdate);
            vHN_NO := j_rec4.HN;
--            vHPT_CODE := j_rec4.HPT_CODE;
            vHPT_CODE := nc_health_package.GET_BKI_HPTCODE(j_rec4.HPT_CODE);
            vCAUSE_CODE := j_rec4.CAUSE_CODE; 
            vDIS_CODE :=  j_rec4.ICD10; 
            vIPD_FLAG :=  j_rec4.CLM_TYPE; 
            vLOSS_DETAIL := j_rec4.RISK_DESC ;
            vFLEET_SEQ := j_rec4.FLEET_SEQ;
            --vRECPT_SEQ := j_rec4.RECPT_SEQ; -- รับ recpt โดยตรงจาก web med เลย
            vINVOICE_NO :=  j_rec4.INVOICE;
            vLOSS_DATE := to_date(j_rec4.LOSS_DATE,'dd/mm/rrrr'); 
            vCLM_USER := j_rec4.HPT_USER;   
            vTR_DATE_FR :=  to_date(j_rec4.FR_LOSS_DATE,'dd/mm/rrrr'); 
            vTR_DATE_TO :=  to_date(j_rec4.TO_LOSS_DATE,'dd/mm/rrrr'); 
            vTOT_TR_DAY := j_rec4.DAY;   
            vRemark := j_rec4.Remark;   -- เก็บ free text สถานพยาบาล 
            --vEvndesc := j_rec4.Evn_desc;
            vSub_Cause := j_rec4.SUB_CAUSE_CODE ;
            vGRP_SEQ    := j_rec4.GRP_SEQ;
            
            IF vDIS_CODE is null THEN  -- กรณีไม่ระบุ icd จะนำ free text มาบันทึกแทน
                vLOSS_DETAIL := j_rec4.Evn_desc;
            END IF;
            
/*
            begin
                select  title||' '||name||' '||surname
                into  vCUS_NAME
                from mis_pa_prem
                where pol_no =vPOL_NO and pol_run =vPOL_RUN    
                and fleet_seq = vFLEET_SEQ  
                and END_SEQ = (SELECT MAX(END_SEQ) FROM mis_pa_prem
                                         WHERE POL_NO =vPOL_NO AND 
                                               nvl(pol_run,0) = vPOL_RUN and fleet_seq = vFLEET_SEQ and
                                               (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE))
                 AND recpt_seq in (select min(x.recpt_seq) from mis_pa_prem x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  and fleet_seq= vFLEET_SEQ
                and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)
                --and x.end_seq = vEND_SEQ
                 );            
            exception
                when no_data_found then
                    RST :='not found mis_pa_prem :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ|| ' fleet: '||vFLEET_SEQ;
                when others then
                    RST :='other mis_pa_prem :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ|| ' fleet: '||vFLEET_SEQ;
            end;
*/            
            
            -- /// เช็คว่ามีรายการรับแจ้งไว้หรือไม่
            begin
                select  'ex' ,clm_no 
                into  vExist ,vClm_no
                from nc_mas
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vExist :=null ;
                when others then
                    vExist :=null ;
            end;            
            dbms_output.put_line('key:'||v_key||' Exist: '||vExist);
            if vExist is  null then -- รายการนี้ยังไม่เคยบันทึกเคลม 
                RST := 'รายการนี้ยังไม่เคยบันทึกเคลม !'; 
            else
            
                begin
                    select  clm_user ,sts_date
                    into  x_clmuser ,x_stsdate
                    from nc_reserved
                    where sts_key = v_key and trn_seq = 1 and rownum=1 ;            
                exception
                    when no_data_found then
                        x_clmuser :=null ;
                    when others then
                        x_clmuser :=null ;
                end;   
                --*** ลง History NC_MAS ***
                NC_HEALTH_PACKAGE.SAVE_NCMAS_HISTORY(v_key , v_RstHISTORY);
                
                if v_RstHISTORY is not null then
                    dbms_output.put_line('v_RstHISTORY: '||v_RstHISTORY);
                    NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,v_RstHISTORY ,v_logrst);
                end if;
                dbms_output.put_line('pass insert History');
                begin 
                    update nc_mas 
                    set 
                     loss_Date = vloss_Date
                     ,tr_date_fr =vtr_date_fr  ,tr_date_to =vtr_date_to , ADD_TR_DAY =vADD_TR_DAY ,tot_tr_daY =vtot_tr_daY
                     ,loss_detail =vloss_detail , ipd_flag =vipd_flag ,dis_code =vdis_code ,cause_code =vcause_code 
                     ,clm_user =vCLM_USER ,remark =vRemark     ,SUB_CAUSE_CODE = vSub_Cause    ,GRP_SEQ =  vGRP_SEQ  
                     ,invoice_no = vINVOICE_NO ,hn_no =    vHN_NO ,hpt_code  = vHPT_CODE         
                    where sts_key = v_key;
                exception
                    when others then
                        dbms_output.put_line('error update NC_MAS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error update NC_MAS: '||sqlerrm;
                end;      
                dbms_output.put_line('pass update NC_MAS');        
            end if;
                
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
               --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                email_pack_error('Error From Package' , 'module save_step2</br>'||RST) ;
                return;      
            END IF;             
            
            -- check FAX CLM data ---
            --IF NVL(P_FAX,'N')  = 'Y' THEN --- Save like send for Approve Fax claim
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  v_key ,vMax_Sts_seq+1 ,'MEDSTS','MEDSTS11' ,'edit Claim Data ' ,vCLM_USER , sysdate        
                    );
                exception
                    when others then
                        dbms_output.put_line('error insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error insert NC_STATUS: '||sqlerrm;
                end;     
            dbms_output.put_line('pass insert NC_STATUS');        
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module save_step2</br>'||RST) ;
                return;      
            END IF;                    
                                        
        END LOOP;  -- end get Master Data

        LOOP  -- get detail Data
           FETCH  P_DTL INTO j_rec1;
            EXIT WHEN P_DTL%NOTFOUND;
            dbms_output.put_line('Prem==>'||  j_rec1.PREMCODE||  ' RequestAmt:'||  j_rec1.request_amt|| ' ResAmt:'||  j_rec1.REMAIN_AMT); 
            v_tot_res := v_tot_res +  j_rec1.REMAIN_AMT;
            BEGIN
            insert into nc_reserved (
            sts_key ,clm_no ,prod_grp ,prod_type ,type ,sub_type ,trn_seq ,amd_date 
            ,prem_code ,prem_seq ,req_amt ,res_amt ,disc_amt ,trn_amt ,amd_user           
            ,sts_date ,clm_user 
            ) values (
            v_key ,vClm_no ,vprod_grp ,vprod_type ,'1' ,'01' ,vMax_res_seq+1 ,trunc(sysdate)
            , j_rec1.PREMCODE , 1 , j_rec1.request_amt ,j_rec1.REMAIN_AMT ,0 ,j_rec1.REMAIN_AMT ,vCLM_USER
            ,x_stsdate , x_clmuser 
            ) ;
            exception
                when others then
                    dbms_output.put_line('error insert NC_RESERVED: '||sqlerrm);
                    ROLLBACK;
                    RST := 'error insert NC_RESERVED: '||sqlerrm;
            end;               
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module save_step2</br>'||RST) ;
                return;      
            END IF;                    
        END LOOP;  -- end get detail Data        

        if vALC_RE = '1' then
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,0 ,0 ,vloss_Date ,vend_seq ,C2 );
        elsif vALC_RE = '2' then 
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        else
             v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        end if;   
        dbms_output.put_line('count CRI_RES: '||v_cnt_res);
        if v_cnt_res>0 then
            LOOP
               FETCH  C2 INTO j_rec2;
                EXIT WHEN C2%NOTFOUND;
                    v_rec := v_rec+1; 
                    
                    --v_shr_amt   := (v_tot_res* j_rec1.RI_SUM_SHR/100);                
                    if v_rec = v_cnt_res then
                       v_shr_amt := v_tot_res -  v_sum_res;
                    else
                        v_shr_amt   := (v_tot_res* j_rec2.RI_SUM_SHR/100);     
                    end if;
                    v_sum_res := v_sum_res +v_shr_amt;                

                    dbms_output.put_line('RI_CODE==>'|| 
                     j_rec2.ri_code||
                     ' RI_BR_CODE:'||
                      j_rec2.ri_br_code||
                     ' RI_SUM_SHR:'||
                      j_rec2.RI_SUM_SHR|| 
                     ' v_shr_amt:'||v_shr_amt
                    );   
                    
                   -- NC_HEALTH_PACKAGE.YOUR_POL(vpol_no, vpol_run, vrecpt_seq, 0, j_rec2.ri_code, j_rec2.RI_BR_CODE,
                   --    j_rec2.RI_SUB_TYPE, j_rec2.RI_TYPE, j_rec2.LF_FLAG, vLOSS_DATE, vYour_Pol);
                       
                    IF j_rec2.RI_TYPE = '1' THEN
                       IF  v_shr_amt < 50000 THEN
                          vLETT_PRT := 'N';
                       ELSE
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                       END IF;
                    ELSIF j_rec2.RI_TYPE = '0' THEN
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                    ELSE
                          vLETT_PRT := 'N';
                    END IF;                  
                    BEGIN
                      INSERT INTO NC_RI_RESERVED A
                       (
                        A.STS_KEY,  A.CLM_NO, A.PROD_GRP,  A.PROD_TYPE,A.TYPE,A.TRN_SEQ
                        ,A.RI_CODE, A.RI_BR_CODE, A.RI_STS_DATE, A.RI_AMD_DATE     
                        ,A.RI_TYPE, A.RI_RES_AMT ,A.RI_TRN_AMT,A.RI_SHARE          
                        ,A.LETT_NO, A.LETT_PRT, A.LETT_TYPE ,A.RI_LF_FLAG, A.RI_SUB_TYPE
                        ,A.SUB_TYPE                      
                        )
                      VALUES
                       (v_key ,vCLm_no ,vprod_grp ,vprod_type , j_rec2.RI_TYPE ,vMax_res_seq+1,
                        j_rec2.RI_CODE, j_rec2.RI_BR_CODE, trunc(sysdate) , sysdate,
                        j_rec2.RI_TYPE, v_shr_amt , v_shr_amt ,j_rec2.RI_SUM_SHR, 
                        vLETT_NO ,vLETT_PRT, 'P',j_rec2.LF_FLAG,j_rec2.RI_SUB_TYPE
                        ,'NCNATSUBTYPECLM001' ); 
                    EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('error insert CRI_RES: '||SQLERRM);
                        ROLLBACK;
                        RST := 'error insert CRI_RES: '||sqlerrm;
                    END;                               

              end loop;    
          end if;      
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                email_pack_error('Error From Package' , 'module save_step2</br>'||RST) ;
                return;      
            END IF;        
                                  
        COMMIT;
        
--        IF RST is null THEN
--            OPEN P_JOBNO FOR
--            SELECT  v_key  STS_KEY ,'' NOTICE_NO ,vClm_no CLM_NO FROM DUAL;             
--        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RST := ' main error :'||sqlerrm;
           -- IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module save_step2</br>'||RST) ;
                return;      
         --   END IF;                    
    END;    -- END    SAVE_STEP2     
    
    PROCEDURE SAVE_STEP3(vSID IN NUMBER  ,
                            P_RST OUT  v_ref_cursor3) IS   -- Bypass CURSOR input
        B_MASTER   NC_HEALTH_PACKAGE.v_ref_cursor1;        
        B_DETAIL   NC_HEALTH_PACKAGE.v_ref_cursor2;    
        P_MASTER   NC_HEALTH_PACKAGE.v_ref_cursor1;        
        P_DETAIL   NC_HEALTH_PACKAGE.v_ref_cursor2;    
        
        --P_RST   NC_HEALTH_PACKAGE.v_ref_cursor3;
        --P_JOB   NC_HEALTH_PA\
        x_polno VARCHAR2(100);
        x_clmno  VARCHAR2(100);

        TYPE t_data1 IS RECORD
        (
        STS_KEY  NUMBER,
        CLM_NO  VARCHAR2(20),
        INVOICE    VARCHAR2(20),
        CLM_TYPE    VARCHAR2(3),
        POLICY_NO    VARCHAR2(50),
        FLEET_SEQ  NUMBER ,
        RECPT_SEQ  NUMBER ,
        NAME    VARCHAR2(200),
        SURNAME    VARCHAR2(200),
        HN    VARCHAR2(20),
        ICD10    VARCHAR2(20),
        CAUSE_CODE    VARCHAR2(20),
        RISK_DESC    VARCHAR2(200),
        LOSS_DATE    VARCHAR2(10), --dd/mm/rrrr
        FR_LOSS_DATE    VARCHAR2(10),
        TO_LOSS_DATE    VARCHAR2(10),
        HPT_CODE   VARCHAR2(20), 
        DAY   NUMBER,
        HPT_USER    VARCHAR2(10),
        REMARK      VARCHAR2(200),
        EVN_DESC    VARCHAR2(200),
        ID_NO   VARCHAR2(20)
        ); 
        j_rec1 t_data1;     
    
        TYPE t_data2 IS RECORD
        (
        STS_KEY  NUMBER,
        CLM_NO  VARCHAR2(20),
        PREMCODE    VARCHAR2(10),
        REQUEST_AMT  NUMBER,
        REMAIN_AMT NUMBER
        ); 
        j_rec2 t_data2;      
    
        TYPE t_data4 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        REQUEST_AMT  NUMBER,
        REMAIN_AMT NUMBER
        ); 
        j_rec4 t_data4;      

        TYPE t_data3 IS RECORD
        (
        STS_KEY   NUMBER ,
        CLM_NO VARCHAR2(20),
        RESULT  VARCHAR2(20) /*  null = สำเร็จ */
        ); 
        j_rec3 t_data3;            
                        
        vSTS_KEY number(10);
        xRst    varchar2(500);
        --query_str  varchar2(2000);
        query_str clob;
        xcnt    number(3);
        RST  varchar2(200);
        mySID   number;
        myREF_no    varchar2(20);
        Ref_Invoice varchar2(50);
        Ref_Hpt varchar2(20);
        RST_Ref   varchar2(200);
        v_logrst      varchar2(200);
    BEGIN
            begin
                   SELECT A.CLM_NO into x_polno  
                    FROM NC_MASTER_TMP A WHERE A.SID = vSID 
                    and CLM_NO is not null
                    AND ROWNUM=1;                  
            exception
                when no_data_found then
                    x_polno := null ;
                when others then
                    x_polno := null ;
            end;
            
            IF  x_polno is null  THEN
                RST := 'Not Found MASTER Data for save!!';
                query_str :=' SELECT 0 sts_key ,'''||'' ||''' clm_no ,'''||RST||''' result  FROM dual ';
                OPEN P_RST FOR query_str ;                       
                return ;                       
            END IF;
            
            mySID := gen_sid ;
            
            OPEN B_MASTER FOR
            SELECT A.STS_KEY ,A.CLM_NO ,     A.INVOICE,       A.CLM_TYPE,       A.POLICY_NO,       A.FLEET_SEQ,  A.RECPT_SEQ ,       A.NAME,       A.SURNAME,       A.HN,
            A.ICD10,       A.CAUSE_CODE,       A.RISK_DESC,       A.LOSS_DATE,       A.FR_LOSS_DATE,       A.TO_LOSS_DATE,       A.HPT_CODE,       A.DAY,       A.HPT_USER
            ,A.Remark  ,A.EVN_DESC ,ID_NO 
            FROM NC_MASTER_TMP A WHERE A.SID = vSID 
            ;  
         /*  update status ส่งวางบิล  */
            xcnt := 0;
            LOOP  -- get Master Data
               FETCH  B_MASTER INTO j_rec1;
                EXIT WHEN B_MASTER%NOTFOUND;
--                xcnt := xcnt +1;
                dbms_output.put_line('cnt:'||xcnt ||'  sts_key: '||j_rec1.sts_key
                ||' invoice: '||j_rec1.invoice );  
                
                begin
                    select nvl(a.invoice_no ,c.invoice) INVOICE_NO ,a.hpt_code  into Ref_Invoice ,Ref_Hpt
                    from nc_mas a ,nc_mas_bancas c
                    where a.sts_key = c.sts_key(+) and  a.sts_key = j_rec1.sts_key ;                    
                exception
                    when no_data_found then
                    Ref_Invoice := null;
                    Ref_Hpt := null;
                    when others then
                    Ref_Invoice := null;
                    Ref_Hpt := null;
                end;      
                    
                OPEN P_MASTER FOR
                select A.STS_KEY ,A.CLM_NO ,     A.INVOICE_NO INVOICE,       A.IPD_FLAG CLM_TYPE,       A.POL_NO||A.POL_RUN POLICY_NO,       A.FLEET_SEQ,  A.RECPT_SEQ ,      '' NAME,       '' SURNAME,       A.HN_NO HN,
                A.DIS_CODE ICD10,       A.CAUSE_CODE,      A.LOSS_DETAIL RISK_DESC,       to_char(A.LOSS_DATE,'dd/mm/yyyy') LOSS_DATE,        to_char(A.TR_DATE_FR,'dd/mm/yyyy') FR_LOSS_DATE,        to_char(A.TR_DATE_TO,'dd/mm/yyyy') TO_LOSS_DATE,    j_rec1.HPT_CODE  HPT_CODE,       A.TOT_TR_DAY xDAY
                ,j_rec1.HPT_USER HPT_USER
                ,A.Remark  ,A.LOSS_DETAIL EVN_DESC  , ID_NO , SUB_CAUSE_CODE , null ,null , null ,null --last 4 columns are DAY_ADD ,PART ,PAID_REMARK ,BKI_CLM_STAFF
                from nc_mas a
                where sts_key = j_rec1.sts_key ;

                OPEN B_DETAIL FOR
                SELECT B.PREM_CODE PREMCODE, B.REQ_AMT REQUEST_AMT, B.RES_AMT REMAIN_AMT
                FROM NC_RESERVED B
                where sts_key =j_rec1.sts_key  
                and b.trn_seq in (select max(bb.trn_seq) from NC_RESERVED bb where bb.sts_key = b.sts_key  ) ;                
                
                -- +++ check Get Claim BANCAS
                IF IS_BANCAS_CLAIM( j_rec1.sts_key) THEN
                    NC_HEALTH_PACKAGE.UPDATE_STATUS_BANCAS( j_rec1.sts_key ,RST) ;
                ELSE
                    xcnt := xcnt +1;
                    NC_HEALTH_PACKAGE.SAVE_UPDATE_CLAIM(P_MASTER ,B_DETAIL , 'MEDSTS12' ,j_rec1.CLM_NO ,RST) ;      
                END IF;
                -- +++ end Sub Module get Claim BANCAS 
                
                BEGIN
                DELETE NC_MASTER_TMP A WHERE A.SID = mySID and STS_KEY = j_rec1.sts_key;
                DELETE NC_DETAIL_TMP A WHERE A.SID = mySID and STS_KEY = j_rec1.sts_key;
                EXCEPTION
                    WHEN OTHERS THEN
                        null;
                END;
                
                COMMIT;                
                
                --+++ เตรียมสร้างกลุ่มงานวางบิล ++++
                if xcnt = 1 then
                    myREF_no := gen_medrefno('000'); 
                    dbms_output.put_line('myREF_no =>'||myREF_no);
                end if;
                
                if RST is null and NOT IS_BANCAS_CLAIM( j_rec1.sts_key)  then -- Update Invoice Complete
                    SAVE_MEDPAYMENT_GROUP(myREF_no , j_rec1.CLM_NO , j_rec1.sts_key ,    Ref_Invoice ,Ref_Hpt , sysdate ,
                            RST_Ref)  ; -- ref_RST=null  = success    
                    dbms_output.put_line('SAVE_MEDPAYMENT_GROUP =>RST:'||RST_Ref||' refno:'||myREF_no||' CLM_NO:'||j_rec1.CLM_NO||' sts_key:'|| j_rec1.sts_key||' Invoice:'||Ref_Invoice);             
                    IF  RST_Ref is not null THEN -- keep Log
                        NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,'save_step3_setRefno' ,
                        'refno:'||myREF_no||' CLM_NO:'||j_rec1.CLM_NO||' sts_key:'|| j_rec1.sts_key||' Invoice:'||Ref_Invoice||' *** '||RST_Ref 
                        ,v_logrst);
                    END IF;                
                end if;
                -- ++++ +++++++ +++++++++ ++++
                
                -- +++ เตรียมสร้าง cursor ส่ง result กลับ +++
--                if xcnt > 1 then
--                    query_str :=query_str||' UNION ' ;
--                end if;
                query_str :=query_str|| ' SELECT '||  j_rec1.STS_KEY ||' sts_key ,'''||j_rec1.CLM_NO ||''' clm_no ,'''||RST||''' result  FROM dual UNION ';
                --+++  ++++++ +++++  ++++++
                            
--                LOOP  -- get Detail Data
--                   FETCH  B_DETAIL INTO j_rec4;
--                    EXIT WHEN B_DETAIL%NOTFOUND;
--
--                        dbms_output.put_line('sts_key: '||j_rec1.sts_key
--                        ||' premcode: '||j_rec4.PREMCODE
--                        ||' remain_amt: '||j_rec4.remain_amt );     
--
--                END LOOP;  
--                
--                CLOSE  B_DETAIL ;
            END LOOP;    
            
            if xcnt > 0 then
                query_str := rtrim(query_str, 'UNION ') ;
                OPEN P_RST FOR query_str ;
            else
                query_str :=' SELECT 0 sts_key ,'''||'' ||''' clm_no ,'''||''||''' result  FROM dual ';
                OPEN P_RST FOR query_str ;
            end if;

            dbms_output.put_line('query str=>'||query_str);

            BEGIN
            DELETE NC_MASTER_TMP A WHERE A.SID = vSID ;
            DELETE NC_DETAIL_TMP A WHERE A.SID = vSID ;
            EXCEPTION
                WHEN OTHERS THEN
                    null;
            END;
            
            COMMIT;
       
        
    END;  -- END SAVE STEP3 byPass CURSOR     

    PROCEDURE SAVE_CANCEL(vSTS_KEY IN NUMBER  ,
                            RST OUT VARCHAR2)    IS 
                            
        P_MASTER   NC_HEALTH_PACKAGE.v_ref_cursor1;        
        P_DETAIL   NC_HEALTH_PACKAGE.v_ref_cursor2;    

        v_clmno VARCHAR2(20);
        send_status VARCHAR2(50);
        v_step1_rst VARCHAR2(200);
    BEGIN

        BEGIN
            select A.CLM_NO into v_clmno
            from nc_mas a
            where sts_key =vSTS_KEY ;        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_clmno := null;
            WHEN OTHERS THEN
                v_clmno := null;
        END;
        
        if v_clmno is null then
            RST := 'not found Claim for Cancel' ;
            return;
        end if;
        
        if substr(v_clmno,1,1) = 'N' then --BANCAS clm
            for x1 in (
                select sts_seq ,cuser 
                from nc_status a
                where sts_key =vSTS_KEY
                and sts_type = 'MEDSTS'
                and sts_seq in (select max(aa.sts_seq) from nc_status aa where aa.sts_key = a.sts_key and aa.sts_type = 'MEDSTS')            
            )loop
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  vSTS_KEY ,x1.sts_seq+1 ,'MEDSTS','MEDSTS32' ,'Cancel Claim Data ' ,x1.cuser , sysdate );
                    COMMIT;
                exception
                    when others then
                        dbms_output.put_line('error insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error insert NC_STATUS: '||sqlerrm;
                end;               
            end loop; --x1       
            return;
        end if;
                 
        OPEN P_MASTER FOR
        select A.STS_KEY ,A.CLM_NO ,     A.INVOICE_NO INVOICE,       A.IPD_FLAG CLM_TYPE,       A.POL_NO||A.POL_RUN POLICY_NO,       A.FLEET_SEQ,  A.RECPT_SEQ ,      '' NAME,       '' SURNAME,       A.HN_NO HN,
        A.DIS_CODE ICD10,       A.CAUSE_CODE,      A.LOSS_DETAIL RISK_DESC,       to_char(A.LOSS_DATE,'dd/mm/yyyy') LOSS_DATE,        to_char(A.TR_DATE_FR,'dd/mm/yyyy') FR_LOSS_DATE,        to_char(A.TR_DATE_TO,'dd/mm/yyyy') TO_LOSS_DATE,  HPT_CODE,       A.TOT_TR_DAY xDAY
        ,CLM_USER HPT_USER
        ,A.Remark  ,A.LOSS_DETAIL EVN_DESC  , ID_NO , SUB_CAUSE_CODE  , null ,null , null ,null --last 4 columns are DAY_ADD ,PART ,PAID_REMARK ,BKI_CLM_STAFF
        from nc_mas a
        where sts_key =vSTS_KEY ;

        OPEN P_DETAIL FOR
        SELECT B.PREM_CODE PREMCODE, B.REQ_AMT REQUEST_AMT, B.RES_AMT REMAIN_AMT
        FROM NC_RESERVED B
        where sts_key =vSTS_KEY  
        and b.trn_seq in (select max(bb.trn_seq) from NC_RESERVED bb where bb.sts_key = b.sts_key  ) ;       
                        
        send_status := 'MEDSTS32';  -- ยกเลิก  Claim
                
         dbms_output.put_line('b4 start SAVE_CANCEL');
        SAVE_UPDATE_CLAIM(P_MASTER  ,P_DETAIL ,send_status,v_CLMNO , v_step1_rst) ;
                                            
        dbms_output.put_line('SAVE_CANCEL==>'||v_step1_rst);

        if v_step1_rst is null then
            RST := null;
        else -- Save ไม่ผ่าน
            RST := 'SAVE_CANCEL==>'||v_step1_rst;        
        end if;            

    EXCEPTION 
    WHEN OTHERS THEN

        RST := 'error in SAVE_CANCEL :'||sqlerrm;
    END;  -- END SAVE_CANCEL  

    PROCEDURE SAVE_OPENBANCAS(P_FAX IN VARCHAR2 ,P_MASTER  IN VARCHAR2  ,P_DTL  IN VARCHAR2  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2) IS
        C_MASTER   NC_HEALTH_PACKAGE.v_ref_cursor1;        
        C_DETAIL   NC_HEALTH_PACKAGE.v_ref_cursor2;          
                                  
        x_polno VARCHAR2(100);
        vSTS_KEY NUMBER;

    BEGIN
    
            NC_HEALTH_PAID.GEN_CURSOR(P_MASTER ,C_MASTER) ;
            NC_HEALTH_PAID.GEN_CURSOR(P_DTL ,C_DETAIL) ;
                        
/*               
            begin
                   SELECT A.POLICY_NO into x_polno
                    FROM NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY AND ROWNUM=1;                  
            exception
                when no_data_found then
                    x_polno := null ;
                when others then
                    x_polno := null ;
            end;
            
            IF  x_polno is null  THEN
                RST := 'Not Found MASTER Data for save!!';
                
                OPEN P_JOBNO FOR
                SELECT  0  STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;   
                       
                return;                       
            END IF;
         
            OPEN C_MASTER FOR
            SELECT A.STS_KEY,       A.INVOICE,       A.CLM_TYPE,       A.POLICY_NO,       A.FLEET_SEQ,  A.RECPT_SEQ ,       A.NAME,       A.SURNAME,       A.HN,
            A.ICD10,       A.CAUSE_CODE,       A.RISK_DESC,       A.LOSS_DATE,       A.FR_LOSS_DATE,       A.TO_LOSS_DATE,       A.HPT_CODE,       A.DAY,       A.HPT_USER
            ,A.Remark  ,A.EVN_DESC ,A.SUB_CAUSE_CODE 
            FROM NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY AND ROWNUM=1;  
            
            OPEN C_DETAIL FOR
            SELECT B.PREMCODE, B.REQUEST_AMT, B.REMAIN_AMT
            FROM NC_DETAIL_TMP B WHERE B.STS_KEY = vSTS_KEY ; 
          
            BEGIN
            DELETE NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY;
            DELETE NC_DETAIL_TMP A WHERE A.STS_KEY = vSTS_KEY;
            EXCEPTION
                WHEN OTHERS THEN
                    null;
            END;
             
            COMMIT; */
         /*    */
            NC_HEALTH_PACKAGE.SAVE_STEP1(P_FAX ,C_MASTER ,C_DETAIL ,P_JOBNO ,RST) ;

            IF RST is null THEN     -- update Clm_no MM
                p_clm_mm.NMC_INS_UPD_MASTER(vSTS_KEY,'U_MED_CLM' );
            END IF;      
    EXCEPTION
        WHEN OTHERS THEN
            RST := 'error SAVE_OPENBANCAS main: '||sqlerrm;
    END;    -- END    SAVE_OPENBANCAS     

    PROCEDURE SAVE_REF_DATA(vSTS_KEY IN NUMBER  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2) IS   -- Record check coverage from Recieption     
        v_cnt1  number:=0;    
        
        vPOL_NO NC_MAS.POL_NO%TYPE ;
        vPOL_RUN NC_MAS.POL_RUN%TYPE ;      
        vCLM_USER   NC_MAS.CLM_USER%TYPE ;    
        vCLM_NO NC_MAS.CLM_NO%TYPE ;
        -- 'N'||to_char(sysdate,'rrrr')||lpad('525' ,11,0) notice_clmno                      
    BEGIN
        
        BEGIN
            SELECT count(sts_key) INTO v_cnt1
            FROM NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY;
        EXCEPTION 
            WHEN NO_DATA_FOUND THEN
                v_cnt1 := 0;
            WHEN OTHERS THEN
                v_cnt1 := 0;
        END;
        IF v_cnt1 = 0 THEN  -- no data found 
            RST := 'Not Found MASTER Data for save!!';
                    
            OPEN P_JOBNO FOR
            SELECT  0  STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;   
                           
            RETURN;                         
        END IF;
        
        vCLM_NO := 'N'||to_char(sysdate,'rrrr')||lpad(vSTS_KEY ,11,0) ;
        FOR P_MASTER in (
        SELECT A.STS_KEY,    A.POLICY_NO,       A.FLEET_SEQ,  A.RECPT_SEQ ,       A.NAME,       A.SURNAME,   A.ID_NO 
         ,A.LOSS_DATE,   A.HPT_CODE,     A.HPT_USER
        FROM NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY AND ROWNUM=1
        ) LOOP
            p_acc_package.read_pol(P_MASTER.policy_no ,vPOL_NO ,vPOL_RUN);
            vCLM_USER := P_MASTER.HPT_USER ;
            begin 
                insert into nc_mas 
                ( sts_key,clm_no ,pol_no ,pol_run  ,recpt_seq ,hpt_code ,cus_name 
                 ,reg_date ,loss_Date ,fleet_seq  ,clm_user ,ID_NO )
                values     
                (  vSTS_KEY ,vCLM_NO  ,vpol_no ,vpol_run  ,P_MASTER.RECPT_SEQ ,P_MASTER.HPT_CODE ,P_MASTER.NAME||' '||P_MASTER.SURNAME 
                 ,sysdate , to_date( P_MASTER.LOSS_DATE,'dd/mm/rrrr')  ,P_MASTER.FLEET_SEQ  ,vCLM_USER ,P_MASTER.ID_NO
                );
            exception
                when others then
                    dbms_output.put_line('error ref_data insert NC_MAS: '||sqlerrm);
                    ROLLBACK;
                    RST := 'error ref_data insert NC_MAS: '||sqlerrm;
            end;                  
            IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
               --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                email_pack_error('Error From Package' , 'module save_ref_data</br>'||RST) ;
                return;      
            END IF;        
                        
            begin 
                insert into nc_status 
                ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                values     
                (  vSTS_KEY ,1 ,'MEDSTS','MEDSTS04' ,'get Notification from HPT Receiption ' ,vCLM_USER , sysdate        
                );
            exception
                when others then
                    dbms_output.put_line('error ref_data insert NC_STATUS: '||sqlerrm);
                    ROLLBACK;
                    RST := 'error ref_data insert NC_STATUS: '||sqlerrm;
            end;                     
            IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
               --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                email_pack_error('Error From Package' , 'module save_ref_data</br>'||RST) ;
                return;      
            END IF;                
        END LOOP;

        BEGIN
        DELETE NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY;
        DELETE NC_DETAIL_TMP A WHERE A.STS_KEY = vSTS_KEY;
        EXCEPTION
            WHEN OTHERS THEN
                null;
        END;
                    
        COMMIT;
        
        IF RST is null THEN
            OPEN P_JOBNO FOR
            SELECT  vSTS_KEY  STS_KEY ,'' NOTICE_NO ,vClm_no CLM_NO FROM DUAL;             
        END IF;        
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
            DELETE NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY;
            DELETE NC_DETAIL_TMP A WHERE A.STS_KEY = vSTS_KEY;
            EXCEPTION
                WHEN OTHERS THEN
                    null;
            END;
            
            COMMIT;
                    
            RST := ' SAVE_REF_DATA main error :'||sqlerrm;
           -- IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module save_ref_data</br>'||RST) ;
                return;          
    END;    -- END    SAVE_REF_DATA          

    PROCEDURE SAVE_UPDATE_CLAIM(P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2  ,NEW_STS IN VARCHAR2, v_CLMNO IN VARCHAR2,
                            RST OUT VARCHAR2) IS
        TYPE t_data4 IS RECORD
        (
        STS_KEY  NUMBER,
        CLM_NO VARCHAR2(20),
        INVOICE    VARCHAR2(20),
        CLM_TYPE    VARCHAR2(3),
        POLICY_NO    VARCHAR2(50),
        FLEET_SEQ  NUMBER ,
        RECPT_SEQ  NUMBER ,
        NAME    VARCHAR2(200),
        SURNAME    VARCHAR2(200),
        HN    VARCHAR2(20),
        ICD10    VARCHAR2(20),
        CAUSE_CODE    VARCHAR2(20),
        RISK_DESC    VARCHAR2(200),
        LOSS_DATE    VARCHAR2(10), --dd/mm/rrrr
        FR_LOSS_DATE    VARCHAR2(10),
        TO_LOSS_DATE    VARCHAR2(10),
        HPT_CODE   VARCHAR2(20), 
        xDAY   NUMBER,
        HPT_USER    VARCHAR2(10),
        REMARK      VARCHAR2(200),
        EVN_DESC    VARCHAR2(200),
        ID_NO   VARCHAR2(20),
        SUB_CAUSE_CODE VARCHAR2(10),
        DAY_ADD NUMBER,
        PART    LONG ,
        PAID_REMARK     VARCHAR2(500) ,
        BKI_CLM_STAFF   VARCHAR2(10)
        ); 
        j_rec4 t_data4;     
    
        TYPE t_data1 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        REQUEST_AMT  NUMBER,
        REMAIN_AMT NUMBER
        ); 
        j_rec1 t_data1;            
        
        C2   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data2 IS RECORD
        (
        POL_NO  MIS_RI_MAS.POL_NO%TYPE ,
        POL_RUN MIS_RI_MAS.POL_RUN%TYPE ,
        RI_CODE MIS_RI_MAS.RI_CODE%TYPE ,
        RI_BR_CODE MIS_RI_MAS.RI_BR_CODE%TYPE ,
        RI_TYPE MIS_RI_MAS.RI_TYPE%TYPE ,
        LF_FLAG MIS_RI_MAS.LF_FLAG%TYPE ,
        RI_SUB_TYPE MIS_RI_MAS.RI_SUB_TYPE%TYPE ,
        --RI_SUM  MIS_RI_MAS.RI_SUM_INS%TYPE ,
        --RI_SUM  NUMBER(20,2),
        RI_SUM_SHR   NUMBER     
        ); 
        j_rec2 t_data2;      
                
        v_key   number;     
        v_cnt_res   number;      
        v_tot_res   number:= 0;           
        v_shr_amt   number(13,2);
        v_sum_res   number:=0;
        v_rec   number:=0;     
        v_logrst    varchar2(200);        
        
        vSTS_KEY NC_MAS.STS_KEY%TYPE ;
        vCLM_NO NC_MAS.CLM_NO%TYPE ;
        vREG_NO NC_MAS.REG_NO%TYPE ;
        vPOL_NO NC_MAS.POL_NO%TYPE ;
        vPOL_RUN NC_MAS.POL_RUN%TYPE ;
        vEND_SEQ NC_MAS.END_SEQ%TYPE := 0;
        vRECPT_SEQ NC_MAS.RECPT_SEQ%TYPE :=1;
        vALC_RE NC_MAS.ALC_RE%TYPE ;
        vCLM_YR NC_MAS.CLM_YR%TYPE ;
        vPOL_YR NC_MAS.POL_YR%TYPE ;
        vPROD_GRP NC_MAS.PROD_GRP%TYPE ;
        vPROD_TYPE     NC_MAS.PROD_TYPE%TYPE ;
        vINVOICE_NO NC_MAS.INVOICE_NO%TYPE ;
        vHN_NO NC_MAS.HN_NO%TYPE ;
        vHPT_CODE NC_MAS.HPT_CODE%TYPE ;
        vMAS_CUS_CODE NC_MAS.MAS_CUS_CODE%TYPE ;
        vMAS_CUS_SEQ NC_MAS.MAS_CUS_SEQ%TYPE ;
        vMAS_CUS_NAME NC_MAS.MAS_CUS_NAME%TYPE ;
        vCUS_CODE NC_MAS.CUS_CODE%TYPE ;
        vCUS_SEQ NC_MAS.CUS_SEQ%TYPE ;
        vCUS_NAME   NC_MAS.CUS_NAME%TYPE ;
        vFAX_CLM NC_MAS.FAX_CLM%TYPE ;
        vFAX_CLM_DATE NC_MAS.FAX_CLM_DATE%TYPE ;
        vREG_DATE NC_MAS.REG_DATE%TYPE ;
        vCLM_DATE NC_MAS.CLM_DATE%TYPE ;
        vLOSS_DATE NC_MAS.LOSS_DATE%TYPE ;
        vFR_DATE NC_MAS.FR_DATE%TYPE ;
        vTO_DATE NC_MAS.TO_DATE%TYPE ;
        vTR_DATE_FR NC_MAS.TR_DATE_FR%TYPE ;
        vTR_DATE_TO NC_MAS.TR_DATE_TO%TYPE ;
        vADD_TR_DAY NC_MAS.ADD_TR_DAY%TYPE ;
        vTOT_TR_DAY NC_MAS.TOT_TR_DAY%TYPE ;
        vLOSS_DETAIL NC_MAS.LOSS_DETAIL%TYPE ; 
        vIPD_FLAG NC_MAS.IPD_FLAG%TYPE ;
        vDIS_CODE NC_MAS.DIS_CODE%TYPE ;
        vCAUSE_CODE   NC_MAS.CAUSE_CODE%TYPE ;
        vFLEET_SEQ    NC_MAS.FLEET_SEQ%TYPE ;
        vRUN_FLEET_SEQ       NC_MAS.RUN_FLEET_SEQ%TYPE ;
        vMAS_SUM_INS   NC_MAS.MAS_SUM_INS%TYPE ;
        vCLM_USER   NC_MAS.CLM_USER%TYPE ;
        vRemark     NC_MAS.REMARK%TYPE ;
        vPART     NC_MAS.PART%TYPE ;
        vPAID_REMARK     NC_MAS.PAID_REMARK%TYPE ;
        vBKI_CLM_STAFF  NC_MAS.BKI_CLM_STAFF%TYPE ;
        --vEvndesc    NC_MAS.EVN_DESC%TYPE ;
        
        vYour_Pol   MIS_CRI_RES.YOUR_POL%TYPE;
        vLett_Prt   MIS_CRI_RES.LETT_PRT%TYPE;
        vLett_no   MIS_CRI_RES.LETT_NO%TYPE;
        
        vMax_Sts_seq    number(3);
        vMax_res_seq    number(3);
        vMax_ri_seq    number(3);
        vExist    varchar2(100);        
        v_RstHISTORY    varchar2(200); 
        tmp_checkclm    varchar2(20);
    BEGIN
        RST := null;
        LOOP  -- get Master Data
           FETCH  P_MASTER INTO j_rec4;
            EXIT WHEN P_MASTER%NOTFOUND;
            dbms_output.put_line('Invoice==>'||  j_rec4.invoice||  ' ClmType:'||  j_rec4.clm_type|| ' Pol_no/Run:'||  j_rec4.policy_no|| ' LossDate:'||  j_rec4.loss_date); 
            
--            if nvl(j_rec4.sts_key,0) = 0 then
--            v_key := gen_stskey(''); -- สร้าง STS_KEY
--            else 
--            v_key := j_rec4.sts_key;             
--            end if;

            begin
                select 'found' , sts_key into tmp_checkclm ,v_key  ---++++ ไว้ใช้ต่อเนื่องทั้ง Procedure
                from nc_mas
                where clm_no =  v_CLMNO;           
            exception
                when no_data_found then
                    tmp_checkclm := null;
                    v_key := 0;
                when others then
                    tmp_checkclm := null;
                    v_key := 0;
            end;
            dbms_output.put_line('tmp_checkclm==>'||tmp_checkclm||' key='||v_key||' clmNo:'||v_clmno);
            
            if tmp_checkclm is  null then -- รายการนี้ยังไม่เคยบันทึกเคลม 
                RST := 'รายการนี้ยังไม่เคยบันทึกเคลม !'; return;
            end if;
                
            begin
                select  nvl(max(sts_seq),1) into vMax_Sts_seq
                from nc_status
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_Sts_seq := 1;
                when others then
                    vMax_Sts_seq := 1;
            end;
            
            begin
                select  nvl(max(trn_seq),1) into vMax_res_seq
                from nc_reserved
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_res_seq := 1;
                when others then
                    vMax_res_seq := 1;
            end;            

            begin
                select  nvl(max(trn_seq),1) into vMax_ri_seq
                from nc_ri_reserved
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_ri_seq := 1;
                when others then
                    vMax_ri_seq := 1;
            end;                  
            p_acc_package.read_pol(j_rec4.policy_no ,vPOL_NO ,vPOL_RUN);
          
            begin
                  SELECT POL_YR,  PROD_TYPE, prod_grp, to_char(sysdate,'rrrr') clm_yr ,
                         CUS_CODE, CUS_SEQ, substr(CUS_ENQ,1,90), ALC_RE ,SUM_INS ,END_SEQ
                  INTO
                         vPOL_YR, vPROD_TYPE, vprod_grp, vCLM_YR ,
                         vMAS_CUS_CODE, vMAS_CUS_SEQ, vMAS_CUS_NAME  , vALC_RE ,vMAS_SUM_INS ,vEND_SEQ
                    FROM MIS_MAS
                    WHERE POL_NO = vPOL_NO AND
                            nvl(pol_run,0) = vPOL_RUN and
                              END_SEQ = (SELECT MAX(END_SEQ) FROM MIS_MAS
                                         WHERE POL_NO =vPOL_NO AND 
                                               nvl(pol_run,0) = vPOL_RUN and
                                               (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE));                  
            exception
                when no_data_found then
                    RST :='not found policy no :'||j_rec4.policy_no;
                when others then
                    RST :='not found policy no :'||j_rec4.policy_no;
            end;       
            vREG_DATE := trunc(sysdate);
            vCLM_DATE := trunc(sysdate);
            vHN_NO := j_rec4.HN;
            --vHPT_CODE := j_rec4.HPT_CODE;
            vHPT_CODE := nc_health_package.GET_BKI_HPTCODE(j_rec4.HPT_CODE);
            vCAUSE_CODE := j_rec4.CAUSE_CODE; 
            vDIS_CODE :=  j_rec4.ICD10; 
            vIPD_FLAG :=  j_rec4.CLM_TYPE; 
            vLOSS_DETAIL := j_rec4.RISK_DESC ;
            vFLEET_SEQ := j_rec4.FLEET_SEQ;
            --vRECPT_SEQ := j_rec4.RECPT_SEQ; -- รับ recpt โดยตรงจาก web med เลย
            vINVOICE_NO :=  j_rec4.INVOICE;
            vLOSS_DATE := to_date(j_rec4.LOSS_DATE,'dd/mm/rrrr'); 
            vCLM_USER := j_rec4.HPT_USER;   
            vTR_DATE_FR :=  to_date(j_rec4.FR_LOSS_DATE,'dd/mm/rrrr'); 
            vTR_DATE_TO :=  to_date(j_rec4.TO_LOSS_DATE,'dd/mm/rrrr'); 
            vTOT_TR_DAY := j_rec4.xDAY;   
            vRemark := j_rec4.Remark;   -- เก็บ free text สถานพยาบาล 
            vADD_TR_DAY := j_rec4.DAY_ADD;
            vPart := j_rec4.part ;
            vPaid_remark := j_rec4.paid_remark ;
            vBKI_CLM_STAFF := j_rec4.bki_clm_staff ;
            --vEvndesc := j_rec4.Evn_desc;
            
            IF vDIS_CODE is null THEN  -- กรณีไม่ระบุ icd จะนำ free text มาบันทึกแทน
                vLOSS_DETAIL := j_rec4.Evn_desc;
            END IF;
            
/*
            begin
                select  title||' '||name||' '||surname
                into  vCUS_NAME
                from mis_pa_prem
                where pol_no =vPOL_NO and pol_run =vPOL_RUN    
                and fleet_seq = vFLEET_SEQ  
                and END_SEQ = (SELECT MAX(END_SEQ) FROM mis_pa_prem
                                         WHERE POL_NO =vPOL_NO AND 
                                               nvl(pol_run,0) = vPOL_RUN and fleet_seq = vFLEET_SEQ and
                                               (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE))
                 AND recpt_seq in (select min(x.recpt_seq) from mis_pa_prem x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  and fleet_seq= vFLEET_SEQ
                and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)
                --and x.end_seq = vEND_SEQ
                 );            
            exception
                when no_data_found then
                    RST :='not found mis_pa_prem :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ|| ' fleet: '||vFLEET_SEQ;
                when others then
                    RST :='other mis_pa_prem :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ|| ' fleet: '||vFLEET_SEQ;
            end;
*/            
            
            -- /// เช็คว่ามีรายการรับแจ้งไว้หรือไม่
            begin
                select  'ex' ,clm_no
                into  vExist ,vClm_no
                from nc_mas
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vExist :=null ;
                when others then
                    vExist :=null ; 
            end;            
            dbms_output.put_line('begin SAVE_UPDATE_CLAIM key:'||v_key||' Exist: '||vExist||' clmno='||vClm_no);
            if vExist is  null then -- รายการนี้ยังไม่เคยบันทึกเคลม 
                RST := 'รายการนี้ยังไม่เคยบันทึกเคลม !'; 
            else
                --*** ลง History NC_MAS ***
                NC_HEALTH_PACKAGE.SAVE_NCMAS_HISTORY(v_key , v_RstHISTORY);
                
                if v_RstHISTORY is not null then
                    dbms_output.put_line('v_RstHISTORY: '||v_RstHISTORY);
                    NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,v_RstHISTORY ,v_logrst);
                end if;
                dbms_output.put_line('pass insert History');
                begin 
                    update nc_mas 
                    set 
                     loss_Date = vloss_Date
                     ,tr_date_fr =vtr_date_fr  ,tr_date_to =vtr_date_to , ADD_TR_DAY =vADD_TR_DAY ,tot_tr_daY =vtot_tr_daY
                     ,loss_detail =vloss_detail , ipd_flag =vipd_flag ,dis_code =vdis_code ,cause_code =vcause_code 
                     ,clm_user =vCLM_USER ,remark =vRemark   ,part = vPart ,paid_remark = vPaid_remark 
                     ,hpt_code = vHPT_CODE ,ID_NO =j_rec4.id_no                 
                     ,Invoice_no = vINVOICE_NO ,BKI_CLM_STAFF = vBKI_CLM_STAFF
                    where sts_key = v_key;
                exception
                    when others then
                        dbms_output.put_line('error update NC_MAS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error update NC_MAS: '||sqlerrm;
                end;      
                dbms_output.put_line('pass update NC_MAS');        
            end if;
                
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
               --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                return;      
            END IF;             
            
            -- check FAX CLM data ---
            --IF NVL(P_FAX,'N')  = 'Y' THEN --- Save like send for Approve Fax claim
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  v_key ,vMax_Sts_seq+1 ,'MEDSTS',NEW_STS ,'update Claim Data ' ,vCLM_USER , sysdate        
                    );
                exception
                    when others then
                        dbms_output.put_line('error insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error insert NC_STATUS: '||sqlerrm;
                end;     
            dbms_output.put_line('pass insert NC_STATUS');        
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                return;      
            END IF;                    
                                        
        END LOOP;  -- end get Master Data

        LOOP  -- get detail Data
           FETCH  P_DTL INTO j_rec1;
            EXIT WHEN P_DTL%NOTFOUND;
            dbms_output.put_line('Prem==>'||  j_rec1.PREMCODE||  ' RequestAmt:'||  j_rec1.request_amt|| ' ResAmt:'||  j_rec1.REMAIN_AMT); 
            v_tot_res := v_tot_res +  j_rec1.REMAIN_AMT;
            BEGIN
            insert into nc_reserved (
            sts_key ,clm_no ,prod_grp ,prod_type ,type ,sub_type ,trn_seq ,sts_date 
            ,prem_code ,prem_seq ,req_amt ,res_amt ,disc_amt ,trn_amt ,clm_user            
            ) values (
            v_key ,vClm_no ,vprod_grp ,vprod_type ,'1' ,'01' ,vMax_res_seq+1 ,trunc(sysdate)
            , j_rec1.PREMCODE , 1 , j_rec1.request_amt ,j_rec1.REMAIN_AMT ,0 ,j_rec1.REMAIN_AMT ,vCLM_USER
            ) ;
            exception
                when others then
                    dbms_output.put_line('error insert NC_RESERVED: '||sqlerrm);
                    ROLLBACK;
                    RST := 'error insert NC_RESERVED: '||sqlerrm;
            end;               
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                return;      
            END IF;                    
        END LOOP;  -- end get detail Data        

        if vALC_RE = '1' then
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,0 ,0 ,vloss_Date ,vend_seq ,C2 );
        elsif vALC_RE = '2' then 
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        else
             v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        end if;   
        dbms_output.put_line('count CRI_RES: '||v_cnt_res);
        if v_cnt_res>0 then
            LOOP
               FETCH  C2 INTO j_rec2;
                EXIT WHEN C2%NOTFOUND;
                    v_rec := v_rec+1; 
                    
                    --v_shr_amt   := (v_tot_res* j_rec1.RI_SUM_SHR/100);                
                    if v_rec = v_cnt_res then
                       v_shr_amt := v_tot_res -  v_sum_res;
                    else
                        v_shr_amt   := (v_tot_res* j_rec2.RI_SUM_SHR/100);     
                    end if;
                    v_sum_res := v_sum_res +v_shr_amt;                

                    dbms_output.put_line('RI_CODE==>'|| 
                     j_rec2.ri_code||
                     ' RI_BR_CODE:'||
                      j_rec2.ri_br_code||
                     ' RI_SUM_SHR:'||
                      j_rec2.RI_SUM_SHR|| 
                     ' v_shr_amt:'||v_shr_amt
                    );   
                    
                   -- NC_HEALTH_PACKAGE.YOUR_POL(vpol_no, vpol_run, vrecpt_seq, 0, j_rec2.ri_code, j_rec2.RI_BR_CODE,
                   --    j_rec2.RI_SUB_TYPE, j_rec2.RI_TYPE, j_rec2.LF_FLAG, vLOSS_DATE, vYour_Pol);
                       
                    IF j_rec2.RI_TYPE = '1' THEN
                       IF  v_shr_amt < 50000 THEN
                          vLETT_PRT := 'N';
                       ELSE
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                       END IF;
                    ELSIF j_rec2.RI_TYPE = '0' THEN
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                    ELSE
                          vLETT_PRT := 'N';
                    END IF;                  
                    BEGIN
                      INSERT INTO NC_RI_RESERVED A
                       (
                        A.STS_KEY,  A.CLM_NO, A.PROD_GRP,  A.PROD_TYPE,A.TYPE,A.TRN_SEQ
                        ,A.RI_CODE, A.RI_BR_CODE, A.RI_STS_DATE, A.RI_AMD_DATE     
                        ,A.RI_TYPE, A.RI_RES_AMT ,A.RI_TRN_AMT,A.RI_SHARE          
                        ,A.LETT_NO, A.LETT_PRT, A.LETT_TYPE ,A.RI_LF_FLAG, A.RI_SUB_TYPE
                        ,A.SUB_TYPE                       
                        )
                      VALUES
                       (v_key ,vCLm_no ,vprod_grp ,vprod_type , j_rec2.RI_TYPE ,vMax_ri_seq+1,
                        j_rec2.RI_CODE, j_rec2.RI_BR_CODE, trunc(sysdate) , sysdate,
                        j_rec2.RI_TYPE, v_shr_amt , v_shr_amt ,j_rec2.RI_SUM_SHR, 
                        vLETT_NO ,vLETT_PRT, 'P',j_rec2.LF_FLAG,j_rec2.RI_SUB_TYPE
                        ,'NCNATSUBTYPECLM001'); 
                    EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('error insert CRI_RES: '||SQLERRM);
                        ROLLBACK;
                        RST := 'error insert CRI_RES: '||sqlerrm;
                    END;                               

              end loop;    
          end if;      
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                return;      
            END IF;        
                                  
        COMMIT;
        
--        IF RST is null THEN
--            OPEN P_JOBNO FOR
--            SELECT  v_key  STS_KEY ,'' NOTICE_NO ,vClm_no CLM_NO FROM DUAL;             
--        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RST := ' main error :'||sqlerrm;
           -- IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                ROLLBACK;
                return;      
         --   END IF;                    
    END;    -- END    SAVE_UPDATE_CLAIM     


    PROCEDURE SAVE_UPDATE_CLAIM2(P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2  ,NEW_STS IN VARCHAR2, v_CLMNO IN VARCHAR2,
                            RST OUT VARCHAR2) IS
        TYPE t_data4 IS RECORD
        (
        STS_KEY  NUMBER,
        CLM_NO VARCHAR2(20),
        INVOICE    VARCHAR2(20),
        CLM_TYPE    VARCHAR2(3),
        POLICY_NO    VARCHAR2(50),
        FLEET_SEQ  NUMBER ,
        RECPT_SEQ  NUMBER ,
        NAME    VARCHAR2(200),
        SURNAME    VARCHAR2(200),
        HN    VARCHAR2(20),
        ICD10    VARCHAR2(20),
        CAUSE_CODE    VARCHAR2(20),
        RISK_DESC    VARCHAR2(200),
        LOSS_DATE    VARCHAR2(10), --dd/mm/rrrr
        FR_LOSS_DATE    VARCHAR2(10),
        TO_LOSS_DATE    VARCHAR2(10),
        HPT_CODE   VARCHAR2(20), 
        xDAY   NUMBER,
        HPT_USER    VARCHAR2(10),
        REMARK      VARCHAR2(200),
        EVN_DESC    VARCHAR2(200),
        ID_NO   VARCHAR2(20),
        SUB_CAUSE_CODE VARCHAR2(10),
        DAY_ADD NUMBER,
        PART    LONG ,
        PAID_REMARK     VARCHAR2(500) ,
        BKI_CLM_STAFF   VARCHAR2(10) ,
        END_SEQ     NUMBER ,
        FR_DATE     VARCHAR2(10),
        TO_DATE     VARCHAR2(10)
        ); 
        j_rec4 t_data4;     
    
        TYPE t_data1 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        REQUEST_AMT  NUMBER,
        REMAIN_AMT NUMBER
        ); 
        j_rec1 t_data1;            
        
        C2   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data2 IS RECORD
        (
        POL_NO  MIS_RI_MAS.POL_NO%TYPE ,
        POL_RUN MIS_RI_MAS.POL_RUN%TYPE ,
        RI_CODE MIS_RI_MAS.RI_CODE%TYPE ,
        RI_BR_CODE MIS_RI_MAS.RI_BR_CODE%TYPE ,
        RI_TYPE MIS_RI_MAS.RI_TYPE%TYPE ,
        LF_FLAG MIS_RI_MAS.LF_FLAG%TYPE ,
        RI_SUB_TYPE MIS_RI_MAS.RI_SUB_TYPE%TYPE ,
        --RI_SUM  MIS_RI_MAS.RI_SUM_INS%TYPE ,
        --RI_SUM  NUMBER(20,2),
        RI_SUM_SHR   NUMBER     
        ); 
        j_rec2 t_data2;      
                
        v_key   number;     
        v_cnt_res   number;      
        v_tot_res   number:= 0;           
        v_shr_amt   number(13,2);
        v_sum_res   number:=0;
        v_rec   number:=0;     
        v_logrst    varchar2(200);        
        
        vSTS_KEY NC_MAS.STS_KEY%TYPE ;
        vCLM_NO NC_MAS.CLM_NO%TYPE ;
        vREG_NO NC_MAS.REG_NO%TYPE ;
        vPOL_NO NC_MAS.POL_NO%TYPE ;
        vPOL_RUN NC_MAS.POL_RUN%TYPE ;
        vEND_SEQ NC_MAS.END_SEQ%TYPE := 0;
        vRECPT_SEQ NC_MAS.RECPT_SEQ%TYPE :=1;
        vALC_RE NC_MAS.ALC_RE%TYPE ;
        vCLM_YR NC_MAS.CLM_YR%TYPE ;
        vPOL_YR NC_MAS.POL_YR%TYPE ;
        vPROD_GRP NC_MAS.PROD_GRP%TYPE ;
        vPROD_TYPE     NC_MAS.PROD_TYPE%TYPE ;
        vINVOICE_NO NC_MAS.INVOICE_NO%TYPE ;
        vHN_NO NC_MAS.HN_NO%TYPE ;
        vHPT_CODE NC_MAS.HPT_CODE%TYPE ;
        vMAS_CUS_CODE NC_MAS.MAS_CUS_CODE%TYPE ;
        vMAS_CUS_SEQ NC_MAS.MAS_CUS_SEQ%TYPE ;
        vMAS_CUS_NAME NC_MAS.MAS_CUS_NAME%TYPE ;
        vCUS_CODE NC_MAS.CUS_CODE%TYPE ;
        vCUS_SEQ NC_MAS.CUS_SEQ%TYPE ;
        vCUS_NAME   NC_MAS.CUS_NAME%TYPE ;
        vFAX_CLM NC_MAS.FAX_CLM%TYPE ;
        vFAX_CLM_DATE NC_MAS.FAX_CLM_DATE%TYPE ;
        vREG_DATE NC_MAS.REG_DATE%TYPE ;
        vCLM_DATE NC_MAS.CLM_DATE%TYPE ;
        vLOSS_DATE NC_MAS.LOSS_DATE%TYPE ;
        vFR_DATE NC_MAS.FR_DATE%TYPE ;
        vTO_DATE NC_MAS.TO_DATE%TYPE ;
        vTR_DATE_FR NC_MAS.TR_DATE_FR%TYPE ;
        vTR_DATE_TO NC_MAS.TR_DATE_TO%TYPE ;
        vADD_TR_DAY NC_MAS.ADD_TR_DAY%TYPE ;
        vTOT_TR_DAY NC_MAS.TOT_TR_DAY%TYPE ;
        vLOSS_DETAIL NC_MAS.LOSS_DETAIL%TYPE ; 
        vIPD_FLAG NC_MAS.IPD_FLAG%TYPE ;
        vDIS_CODE NC_MAS.DIS_CODE%TYPE ;
        vCAUSE_CODE   NC_MAS.CAUSE_CODE%TYPE ;
        vFLEET_SEQ    NC_MAS.FLEET_SEQ%TYPE ;
        vRUN_FLEET_SEQ       NC_MAS.RUN_FLEET_SEQ%TYPE ;
        vMAS_SUM_INS   NC_MAS.MAS_SUM_INS%TYPE ;
        vCLM_USER   NC_MAS.CLM_USER%TYPE ;
        vRemark     NC_MAS.REMARK%TYPE ;
        vPART     NC_MAS.PART%TYPE ;
        vPAID_REMARK     NC_MAS.PAID_REMARK%TYPE ;
        vBKI_CLM_STAFF  NC_MAS.BKI_CLM_STAFF%TYPE ;
        --vEvndesc    NC_MAS.EVN_DESC%TYPE ;
        
        vYour_Pol   MIS_CRI_RES.YOUR_POL%TYPE;
        vLett_Prt   MIS_CRI_RES.LETT_PRT%TYPE;
        vLett_no   MIS_CRI_RES.LETT_NO%TYPE;
        
        vMax_Sts_seq    number(3);
        vMax_res_seq    number(3);
        vMax_ri_seq    number(3);
        vExist    varchar2(100);        
        v_RstHISTORY    varchar2(200); 
        tmp_checkclm    varchar2(20);
    BEGIN
        RST := null;
        LOOP  -- get Master Data
           FETCH  P_MASTER INTO j_rec4;
            EXIT WHEN P_MASTER%NOTFOUND;
            dbms_output.put_line('Invoice==>'||  j_rec4.invoice||  ' ClmType:'||  j_rec4.clm_type|| ' Pol_no/Run:'||  j_rec4.policy_no|| ' LossDate:'||  j_rec4.loss_date); 
            
--            if nvl(j_rec4.sts_key,0) = 0 then
--            v_key := gen_stskey(''); -- สร้าง STS_KEY
--            else 
--            v_key := j_rec4.sts_key;             
--            end if;

            begin
                select 'found' , sts_key into tmp_checkclm ,v_key  ---++++ ไว้ใช้ต่อเนื่องทั้ง Procedure
                from nc_mas
                where clm_no =  v_CLMNO;           
            exception
                when no_data_found then
                    tmp_checkclm := null;
                    v_key := 0;
                when others then
                    tmp_checkclm := null;
                    v_key := 0;
            end;
            dbms_output.put_line('tmp_checkclm==>'||tmp_checkclm||' key='||v_key||' clmNo:'||v_clmno);
            
            if tmp_checkclm is  null then -- รายการนี้ยังไม่เคยบันทึกเคลม 
                RST := 'รายการนี้ยังไม่เคยบันทึกเคลม !'; return;
            end if;
                
            begin
                select  nvl(max(sts_seq),1) into vMax_Sts_seq
                from nc_status
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_Sts_seq := 1;
                when others then
                    vMax_Sts_seq := 1;
            end;
            
            begin
                select  nvl(max(trn_seq),1) into vMax_res_seq
                from nc_reserved
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_res_seq := 1;
                when others then
                    vMax_res_seq := 1;
            end;            

            begin
                select  nvl(max(trn_seq),1) into vMax_ri_seq
                from nc_ri_reserved
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_ri_seq := 1;
                when others then
                    vMax_ri_seq := 1;
            end;                  
            p_acc_package.read_pol(j_rec4.policy_no ,vPOL_NO ,vPOL_RUN);
          
            begin
                  SELECT POL_YR,  PROD_TYPE, prod_grp, to_char(sysdate,'rrrr') clm_yr ,
                         CUS_CODE, CUS_SEQ, substr(CUS_ENQ,1,90), ALC_RE ,SUM_INS ,END_SEQ
                  INTO
                         vPOL_YR, vPROD_TYPE, vprod_grp, vCLM_YR ,
                         vMAS_CUS_CODE, vMAS_CUS_SEQ, vMAS_CUS_NAME  , vALC_RE ,vMAS_SUM_INS ,vEND_SEQ
                    FROM MIS_MAS
                    WHERE POL_NO = vPOL_NO AND
                            nvl(pol_run,0) = vPOL_RUN and
                              END_SEQ = (SELECT MAX(END_SEQ) FROM MIS_MAS
                                         WHERE POL_NO =vPOL_NO AND 
                                               nvl(pol_run,0) = vPOL_RUN and
                                               (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE));                  
            exception
                when no_data_found then
                    RST :='not found policy no :'||j_rec4.policy_no;
                when others then
                    RST :='not found policy no :'||j_rec4.policy_no;
            end;       
            vREG_DATE := trunc(sysdate);
            vCLM_DATE := trunc(sysdate);
            vHN_NO := j_rec4.HN;
            --vHPT_CODE := j_rec4.HPT_CODE;
            vHPT_CODE := nc_health_package.GET_BKI_HPTCODE(j_rec4.HPT_CODE);
            vCAUSE_CODE := j_rec4.CAUSE_CODE; 
            vDIS_CODE :=  j_rec4.ICD10; 
            vIPD_FLAG :=  j_rec4.CLM_TYPE; 
            vLOSS_DETAIL := j_rec4.RISK_DESC ;
            vFLEET_SEQ := j_rec4.FLEET_SEQ;
            vRECPT_SEQ := j_rec4.RECPT_SEQ; -- รับ recpt โดยตรงจาก web med เลย
            vINVOICE_NO :=  j_rec4.INVOICE;
            vLOSS_DATE := to_date(j_rec4.LOSS_DATE,'dd/mm/rrrr'); 
            vCLM_USER := j_rec4.HPT_USER;   
            vTR_DATE_FR :=  to_date(j_rec4.FR_LOSS_DATE,'dd/mm/rrrr'); 
            vTR_DATE_TO :=  to_date(j_rec4.TO_LOSS_DATE,'dd/mm/rrrr'); 
            vTOT_TR_DAY := j_rec4.xDAY;   
            vRemark := j_rec4.Remark;   -- เก็บ free text สถานพยาบาล 
            vADD_TR_DAY := j_rec4.DAY_ADD;
            vPart := j_rec4.part ;
            vPaid_remark := j_rec4.paid_remark ;
            vBKI_CLM_STAFF := j_rec4.bki_clm_staff ;
            vEND_SEQ := j_rec4.END_SEQ;
            vFR_DATE := to_date(j_rec4.FR_DATE,'dd/mm/rrrr'); 
            vTO_DATE := to_date(j_rec4.TO_DATE,'dd/mm/rrrr');
            
            IF vDIS_CODE is null THEN  -- กรณีไม่ระบุ icd จะนำ free text มาบันทึกแทน
                vLOSS_DETAIL := j_rec4.Evn_desc;
            END IF;
            
/*
            begin
                select  title||' '||name||' '||surname
                into  vCUS_NAME
                from mis_pa_prem
                where pol_no =vPOL_NO and pol_run =vPOL_RUN    
                and fleet_seq = vFLEET_SEQ  
                and END_SEQ = (SELECT MAX(END_SEQ) FROM mis_pa_prem
                                         WHERE POL_NO =vPOL_NO AND 
                                               nvl(pol_run,0) = vPOL_RUN and fleet_seq = vFLEET_SEQ and
                                               (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE))
                 AND recpt_seq in (select min(x.recpt_seq) from mis_pa_prem x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  and fleet_seq= vFLEET_SEQ
                and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)
                --and x.end_seq = vEND_SEQ
                 );            
            exception
                when no_data_found then
                    RST :='not found mis_pa_prem :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ|| ' fleet: '||vFLEET_SEQ;
                when others then
                    RST :='other mis_pa_prem :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ|| ' fleet: '||vFLEET_SEQ;
            end;
*/            
            
            -- /// เช็คว่ามีรายการรับแจ้งไว้หรือไม่
            begin
                select  'ex' ,clm_no
                into  vExist ,vClm_no
                from nc_mas
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vExist :=null ;
                when others then
                    vExist :=null ; 
            end;            
            dbms_output.put_line('begin SAVE_UPDATE_CLAIM key:'||v_key||' Exist: '||vExist||' clmno='||vClm_no);
            if vExist is  null then -- รายการนี้ยังไม่เคยบันทึกเคลม 
                RST := 'รายการนี้ยังไม่เคยบันทึกเคลม !'; 
            else
                --*** ลง History NC_MAS ***
                NC_HEALTH_PACKAGE.SAVE_NCMAS_HISTORY(v_key , v_RstHISTORY);
                
                if v_RstHISTORY is not null then
                    dbms_output.put_line('v_RstHISTORY: '||v_RstHISTORY);
                    NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,v_RstHISTORY ,v_logrst);
                end if;
                dbms_output.put_line('pass insert History');
                begin 
                    update nc_mas 
                    set 
                     loss_Date = vloss_Date
                     ,tr_date_fr =vtr_date_fr  ,tr_date_to =vtr_date_to , ADD_TR_DAY =vADD_TR_DAY ,tot_tr_daY =vtot_tr_daY
                     ,loss_detail =vloss_detail , ipd_flag =vipd_flag ,dis_code =vdis_code ,cause_code =vcause_code 
                     ,clm_user =vCLM_USER ,remark =vRemark   ,part = vPart ,paid_remark = vPaid_remark 
                     ,hpt_code = vHPT_CODE ,ID_NO =j_rec4.id_no                 
                     ,Invoice_no = vINVOICE_NO ,BKI_CLM_STAFF = vBKI_CLM_STAFF
                     ,recpt_seq = vRecpt_seq ,end_seq = vEnd_seq ,fr_date = vFR_DATE ,to_date = vTO_DATE 
                    where sts_key = v_key;
                exception
                    when others then
                        dbms_output.put_line('error update NC_MAS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error update NC_MAS: '||sqlerrm;
                end;      
                dbms_output.put_line('pass update NC_MAS');        
            end if;
                
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
               --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                return;      
            END IF;             
            
            -- check FAX CLM data ---
            --IF NVL(P_FAX,'N')  = 'Y' THEN --- Save like send for Approve Fax claim
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  v_key ,vMax_Sts_seq+1 ,'MEDSTS',NEW_STS ,'update Claim Data ' ,vCLM_USER , sysdate        
                    );
                exception
                    when others then
                        dbms_output.put_line('error insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error insert NC_STATUS: '||sqlerrm;
                end;     
            dbms_output.put_line('pass insert NC_STATUS');        
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                return;      
            END IF;                    
                                        
        END LOOP;  -- end get Master Data

        LOOP  -- get detail Data
           FETCH  P_DTL INTO j_rec1;
            EXIT WHEN P_DTL%NOTFOUND;
            dbms_output.put_line('Prem==>'||  j_rec1.PREMCODE||  ' RequestAmt:'||  j_rec1.request_amt|| ' ResAmt:'||  j_rec1.REMAIN_AMT); 
            v_tot_res := v_tot_res +  j_rec1.REMAIN_AMT;
            BEGIN
            insert into nc_reserved (
            sts_key ,clm_no ,prod_grp ,prod_type ,type ,sub_type ,trn_seq ,sts_date 
            ,prem_code ,prem_seq ,req_amt ,res_amt ,disc_amt ,trn_amt ,clm_user            
            ) values (
            v_key ,vClm_no ,vprod_grp ,vprod_type ,'1' ,'01' ,vMax_res_seq+1 ,trunc(sysdate)
            , j_rec1.PREMCODE , 1 , j_rec1.request_amt ,j_rec1.REMAIN_AMT ,0 ,j_rec1.REMAIN_AMT ,vCLM_USER
            ) ;
            exception
                when others then
                    dbms_output.put_line('error insert NC_RESERVED: '||sqlerrm);
                    ROLLBACK;
                    RST := 'error insert NC_RESERVED: '||sqlerrm;
            end;               
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                return;      
            END IF;                    
        END LOOP;  -- end get detail Data        

        if vALC_RE = '1' then
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,0 ,0 ,vloss_Date ,vend_seq ,C2 );
        elsif vALC_RE = '2' then 
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        else
             v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        end if;   
        dbms_output.put_line('count CRI_RES: '||v_cnt_res);
        if v_cnt_res>0 then
            LOOP
               FETCH  C2 INTO j_rec2;
                EXIT WHEN C2%NOTFOUND;
                    v_rec := v_rec+1; 
                    
                    --v_shr_amt   := (v_tot_res* j_rec1.RI_SUM_SHR/100);                
                    if v_rec = v_cnt_res then
                       v_shr_amt := v_tot_res -  v_sum_res;
                    else
                        v_shr_amt   := (v_tot_res* j_rec2.RI_SUM_SHR/100);     
                    end if;
                    v_sum_res := v_sum_res +v_shr_amt;                

                    dbms_output.put_line('RI_CODE==>'|| 
                     j_rec2.ri_code||
                     ' RI_BR_CODE:'||
                      j_rec2.ri_br_code||
                     ' RI_SUM_SHR:'||
                      j_rec2.RI_SUM_SHR|| 
                     ' v_shr_amt:'||v_shr_amt
                    );   
                    NC_HEALTH_PACKAGE.WRITE_LOG  ('Package' ,'SAVE_UPDATE_CLAIM2' ,'debug' ,'vCLm_no='||vCLm_no||' RI_CODE==>'||
                     j_rec2.ri_code||
                     ' RI_BR_CODE:'||
                      j_rec2.ri_br_code||
                     ' RI_SUM_SHR:'||
                      j_rec2.RI_SUM_SHR|| 
                     ' v_shr_amt:'||v_shr_amt||' vALC_RE='||vALC_RE,
                       v_logrst);
                   -- NC_HEALTH_PACKAGE.YOUR_POL(vpol_no, vpol_run, vrecpt_seq, 0, j_rec2.ri_code, j_rec2.RI_BR_CODE,
                   --    j_rec2.RI_SUB_TYPE, j_rec2.RI_TYPE, j_rec2.LF_FLAG, vLOSS_DATE, vYour_Pol);
                       
                    IF j_rec2.RI_TYPE = '1' THEN
                       IF  v_shr_amt < 50000 THEN
                          vLETT_PRT := 'N';
                       ELSE
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                       END IF;
                    ELSIF j_rec2.RI_TYPE = '0' THEN
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                    ELSE
                          vLETT_PRT := 'N';
                    END IF;                  
                    BEGIN
                      INSERT INTO NC_RI_RESERVED A
                       (
                        A.STS_KEY,  A.CLM_NO, A.PROD_GRP,  A.PROD_TYPE,A.TYPE,A.TRN_SEQ
                        ,A.RI_CODE, A.RI_BR_CODE, A.RI_STS_DATE, A.RI_AMD_DATE     
                        ,A.RI_TYPE, A.RI_RES_AMT ,A.RI_TRN_AMT,A.RI_SHARE          
                        ,A.LETT_NO, A.LETT_PRT, A.LETT_TYPE ,A.RI_LF_FLAG, A.RI_SUB_TYPE
                        ,A.SUB_TYPE                       
                        )
                      VALUES
                       (v_key ,vCLm_no ,vprod_grp ,vprod_type , j_rec2.RI_TYPE ,vMax_ri_seq+1,
                        j_rec2.RI_CODE, j_rec2.RI_BR_CODE, trunc(sysdate) , sysdate,
                        j_rec2.RI_TYPE, v_shr_amt , v_shr_amt ,j_rec2.RI_SUM_SHR, 
                        vLETT_NO ,vLETT_PRT, 'P',j_rec2.LF_FLAG,j_rec2.RI_SUB_TYPE
                        ,'NCNATSUBTYPECLM001'); 
                    EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('error insert CRI_RES: '||SQLERRM);
                        ROLLBACK;
                        RST := 'error insert CRI_RES: '||sqlerrm;
                    END;                               

              end loop;    
          end if;      
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                return;      
            END IF;        
                                  
        COMMIT;
        
--        IF RST is null THEN
--            OPEN P_JOBNO FOR
--            SELECT  v_key  STS_KEY ,'' NOTICE_NO ,vClm_no CLM_NO FROM DUAL;             
--        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RST := RST||' main error :'||sqlerrm;
           -- IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                ROLLBACK;
                return;      
         --   END IF;                    
    END;    -- END    SAVE_UPDATE_CLAIM 2    

     PROCEDURE SAVE_NCMAS_HISTORY(vSTS_KEY IN NUMBER  ,
                            RST OUT VARCHAR2)  IS --เรียกใช้ก่อนบันทึกลง NC_MAS ทุกครั้ง  RST=null 
        v_trn_Seq number:=0 ;
        v_found     varchar2(10);
    BEGIN
            begin
                   SELECT 'xx' into v_found
                    FROM NC_MAS
                    WHERE STS_KEY = vSTS_KEY;                  
            exception
                when no_data_found then
                    v_found := null ;
                when others then
                     v_found := null ;
            end;
            
            if v_found is null then
                RST := 'not found NC_MAS' ; return ;
            end if;
                
            begin
                   SELECT nvl(max(trn_seq) ,0) into  v_trn_Seq
                    FROM NC_MAS_HISTORY
                    WHERE STS_KEY = vSTS_KEY;                  
            exception
                when no_data_found then
                    v_trn_Seq := 0 ;
                when others then
                    v_trn_Seq := 0 ;
            end;
            
         
            BEGIN
            INSERT INTO NC_MAS_HISTORY (
                STS_KEY, CLM_NO, REG_NO, POL_NO, POL_RUN, END_NO, END_SEQ, RECPT_SEQ, 
                LOC_SEQ, CLM_YR, POL_YR, PROD_GRP, PROD_TYPE, FLEET_SEQ, 
                RUN_FLEET_SEQ, SUB_SEQ, FAM_STS, PATRONIZE, FAM_SEQ, ID_NO, PLAN, 
                IPD_FLAG, DIS_CODE, CAUSE_CODE, CAUSE_SEQ, REG_DATE, CLM_DATE, 
                LOSS_DATE, LOSS_TIME, FR_DATE, TO_DATE, TR_DATE_FR, CLOSE_DATE, 
                TR_DATE_TO, REOPEN_DATE, ADD_TR_DAY, TOT_TR_DAY, ALC_RE, HN_NO, 
                LOSS_DETAIL, CLM_USER, INVOICE_NO, HPT_CODE, HPT_SEQ, MAS_CUS_CODE, 
                MAS_CUS_SEQ, MAS_CUS_NAME, CUS_CODE, CUS_SEQ, CUS_NAME, FAX_CLM, 
                FAX_CLM_DATE, DEATH_CLAIM, MAS_SUM_INS, RECPT_SUM_INS, LOC_SUM_INS, 
                CLM_STS, REMARK, CLM_PLACE, CLM_PLACE_AMP, CLM_PLACE_JW, CATAS_CODE, 
                PI_CLUB, CARR_AGENT, CONSIGN, NAT_CLM_FLAG, ARRV_DATE, DEL_DATE, 
                TIME_BAR  ,TRN_SEQ ,RECORD_DATE ,SUB_CAUSE_CODE ,PART ,PAID_REMARK ,BKI_CLM_STAFF,
                CARD_ID_TYPE ,CARD_ID_NO ,CARD_OTHER_TYPE ,CARD_OTHER_NO ,CARD_UPDATEDATE ,
                OIC_PROD_TYPE ,OIC_FLAG_POL ,CLAIM_NUMBER   ,CLAIM_RUN  ,
                ADMISSION_TYPE ,CLM_TYPE ,ICD10_2 ,ICD10_3 ,ICD10_4 ,
                CLAIM_STATUS ,APPROVE_STATUS ,AMD_USER ,OTHER_HPT  ,
                CWP_CODE ,CWP_REMARK ,CWP_USER , COMPLETE_CODE, COMPLETE_USER, CONVERT_FLAG 
                ,OUT_CLM_NO, OUT_OPEN_STS, OUT_PAID_STS, OUT_APPROVE_STS
            ) 
            (
                SELECT A.STS_KEY, A.CLM_NO, A.REG_NO, A.POL_NO, A.POL_RUN, A.END_NO, A.END_SEQ, A.RECPT_SEQ, 
                A.LOC_SEQ, A.CLM_YR, A.POL_YR, A.PROD_GRP, A.PROD_TYPE, A.FLEET_SEQ, 
                A.RUN_FLEET_SEQ, A.SUB_SEQ, A.FAM_STS, A.PATRONIZE, A.FAM_SEQ, A.ID_NO, A.PLAN, 
                A.IPD_FLAG, A.DIS_CODE, A.CAUSE_CODE, A.CAUSE_SEQ, A.REG_DATE, A.CLM_DATE, 
                A.LOSS_DATE, A.LOSS_TIME, A.FR_DATE, A.TO_DATE, A.TR_DATE_FR, A.CLOSE_DATE, 
                A.TR_DATE_TO, A.REOPEN_DATE, A.ADD_TR_DAY, A.TOT_TR_DAY, A.ALC_RE, A.HN_NO, 
                A.LOSS_DETAIL, A.CLM_USER, A.INVOICE_NO, A.HPT_CODE, A.HPT_SEQ, A.MAS_CUS_CODE, 
                A.MAS_CUS_SEQ, A.MAS_CUS_NAME, A.CUS_CODE, A.CUS_SEQ, A.CUS_NAME, A.FAX_CLM, 
                A.FAX_CLM_DATE, A.DEATH_CLAIM, A.MAS_SUM_INS, A.RECPT_SUM_INS, A.LOC_SUM_INS, 
                A.CLM_STS, A.REMARK, A.CLM_PLACE, A.CLM_PLACE_AMP, A.CLM_PLACE_JW, A.CATAS_CODE, 
                A.PI_CLUB, A.CARR_AGENT, A.CONSIGN, A.NAT_CLM_FLAG, A.ARRV_DATE, A.DEL_DATE, 
                A.TIME_BAR ,v_trn_Seq+1 ,sysdate ,A.SUB_CAUSE_CODE ,to_lob(A.PART) ,A.PAID_REMARK ,A.BKI_CLM_STAFF,
                A.CARD_ID_TYPE ,A.CARD_ID_NO ,A.CARD_OTHER_TYPE ,A.CARD_OTHER_NO ,A.CARD_UPDATEDATE ,
                 A.OIC_PROD_TYPE , A.OIC_FLAG_POL , A.CLAIM_NUMBER   , A.CLAIM_RUN  ,
                 A.ADMISSION_TYPE , A.CLM_TYPE , A.ICD10_2 , A.ICD10_3 , A.ICD10_4 ,
                 A.CLAIM_STATUS ,A.APPROVE_STATUS  ,A.AMD_USER ,A.OTHER_HPT ,
                 A.CWP_CODE ,A.CWP_REMARK ,A.CWP_USER, A.COMPLETE_CODE, A.COMPLETE_USER, A.CONVERT_FLAG 
                 ,A.OUT_CLM_NO, A.OUT_OPEN_STS, A.OUT_PAID_STS, A.OUT_APPROVE_STS
                FROM NC_MAS A
                WHERE A.STS_KEY = vSTS_KEY 
            );
            EXCEPTION
                WHEN OTHERS THEN
                    RST := 'error insert History:'||sqlerrm ; return ;
            END;
 /*             */
            COMMIT;
         /*    */                 
        
    END;  -- END  SAVE_NCMAS_HISTORY                                                                 

    PROCEDURE SAVE_MEDPAYMENT_GROUP(vref_no IN varchar2 , vclm_no  IN varchar2 , vSTS_KEY IN NUMBER  ,vInvoice IN varchar2 ,vHpt_code IN varchar2 ,vRef_date IN DATE ,
                            RST OUT VARCHAR2)  IS -- RST=null  
        v_trn_Seq number:=0 ;
        v_found     varchar2(10);
    BEGIN
                
            begin
                   SELECT nvl(max(trn_seq) ,0) into  v_trn_Seq
                    FROM MED_PAYMENT_GROUP
                    WHERE INVOICE = vInvoice;                  
            exception
                when no_data_found then
                    v_trn_Seq := 0 ;
                when others then
                    v_trn_Seq := 0 ;
            end;
            
         
            BEGIN
            INSERT INTO MED_PAYMENT_GROUP (
                REF_NO , CLM_NO ,STS_KEY ,INVOICE ,HPT_CODE  ,REF_DATE ,TRN_SEQ ,TRN_DATE
            ) VALUES
            (
                vREF_NO , vCLM_NO ,vSTS_KEY ,vINVOICE, vHpt_code ,vREF_DATE ,v_trn_Seq+1 ,sysdate
            );
            EXCEPTION
                WHEN OTHERS THEN
                    RST := 'error insert MED_PAYMENT_GROUP:'||sqlerrm ; return ;
            END;
 /*             */
            COMMIT;
         /*    */                 
        
    END;  -- END  SAVE_MEDPAYMENT_GROUP           
    
    PROCEDURE SAVE_MEDPAYMENT_GROUP_SEQ(vref_no IN varchar2 , vclm_no  IN varchar2 , vSTS_KEY IN NUMBER  ,vInvoice IN varchar2 ,
                            RST OUT VARCHAR2)  IS -- RST=null  
        v_trn_Seq number:=0 ;
        v_found     varchar2(10);
        vHpt_Code  varchar2(20);
        vREF_DATE date ;
    BEGIN
                
            begin
                   SELECT nvl(max(trn_seq) ,0) into  v_trn_Seq
                    FROM MED_PAYMENT_GROUP
                    WHERE ref_no = vRef_no and clm_no = vClm_no and sts_key = vSts_key
                    group by ref_no ,clm_no,sts_key ;                  
            exception
                when no_data_found then
                    v_trn_Seq := 0 ;
                when others then
                    v_trn_Seq := 0 ;
            end;
            
            IF v_trn_Seq = 0 THEN RST := 'Not Found Ref Group!' ; return; END IF;
         
            FOR x1 in (
                    SELECT HPT_CODE  ,REF_DATE
                    FROM MED_PAYMENT_GROUP a
                    WHERE ref_no = vRef_no and clm_no = vClm_no and sts_key = vSts_key
                    and trn_seq in (select max(x.trn_seq) from MED_PAYMENT_GROUP x where x.ref_no = a.Ref_no and x.clm_no = a.Clm_no and x.sts_key = a.Sts_key)               
            ) LOOP
                vHpt_Code  := x1.HPT_CODE;
                vREF_DATE := x1.REF_DATE ;                      
            END LOOP;
            
            BEGIN
            INSERT INTO MED_PAYMENT_GROUP (
                REF_NO , CLM_NO ,STS_KEY ,INVOICE ,HPT_CODE  ,REF_DATE ,TRN_SEQ ,TRN_DATE
            ) VALUES
            (
                vREF_NO , vCLM_NO ,vSTS_KEY ,vINVOICE, vHpt_code ,vREF_DATE ,v_trn_Seq+1 ,sysdate
            );
            EXCEPTION
                WHEN OTHERS THEN
                    RST := 'error insert MED_PAYMENT_GROUP SEQ:'||sqlerrm ; return ;
            END;
 /*             */
            COMMIT;
         /*    */                 
        
    END;  -- END  SAVE_MEDPAYMENT_GROUP _SEQ 

    PROCEDURE SAVE_BANCAS(P_FAX IN VARCHAR2 ,vSTS_KEY IN NUMBER  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2) IS      -- RST = null คือ สำเร็จ  
        v_hpt_name varchar2(200);
        tmp_CLMNO   varchar2(20);
        vCLM_NO   varchar2(20);
        chk_ncmas   boolean:=false;
        vCLM_USER   varchar2(20);
        vPOL_NO   varchar2(20);
        vPOL_RUN    number(20);
        vBank_code  varchar2(20);
        vBranch_code  varchar2(20);
        vBank_name varchar2(200);
        vBranch_name varchar2(300);
        vCustDetail  varchar2(300);
    BEGIN
        FOR X1 IN (
            SELECT count(*) cnt  FROM NC_MASTER_TMP 
            WHERE STS_KEY = vSTS_KEY
        )    LOOP
            if X1.cnt = 0 then
                RST := 'ไม่พบข้อมูลเปิดเคลม'; return ;
            end if;
        END LOOP;

        FOR X12 IN (
            SELECT count(*) cnt  FROM NC_MAS
            WHERE STS_KEY = vSTS_KEY
        )    LOOP
            if X12.cnt > 0 then
                chk_ncmas := true;
            end if;
        END LOOP;
        
        IF  not CHK_NCMAS   THEN
            vCLM_NO := 'N'||to_char(sysdate,'rrrr')||lpad(vSTS_KEY ,11,0) ;
            FOR P_MASTER in (
            SELECT A.STS_KEY,    A.POLICY_NO,       A.FLEET_SEQ,  A.RECPT_SEQ ,       A.NAME,       A.SURNAME,   A.ID_NO 
             ,A.LOSS_DATE,   A.HPT_CODE,     A.HPT_USER
            FROM NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY AND ROWNUM=1
            ) LOOP
                p_acc_package.read_pol(P_MASTER.policy_no ,vPOL_NO ,vPOL_RUN);
                vCLM_USER := P_MASTER.HPT_USER ;
                begin 
                    insert into nc_mas 
                    ( sts_key,clm_no ,pol_no ,pol_run  ,recpt_seq ,hpt_code ,cus_name 
                     ,reg_date ,loss_Date ,fleet_seq  ,clm_user ,ID_NO )
                    values     
                    (  vSTS_KEY ,vCLM_NO  ,vpol_no ,vpol_run  ,P_MASTER.RECPT_SEQ ,P_MASTER.HPT_CODE ,P_MASTER.NAME||' '||P_MASTER.SURNAME 
                     ,sysdate , to_date( P_MASTER.LOSS_DATE,'dd/mm/rrrr')  ,P_MASTER.FLEET_SEQ  ,vCLM_USER ,P_MASTER.ID_NO
                    );
                exception
                    when others then
                        dbms_output.put_line('error bancas ref_data insert NC_MAS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error bancas ref_data insert NC_MAS: '||sqlerrm;
                        
                end;                  
                IF RST is not null THEN  -- error
                    OPEN P_JOBNO FOR
                    SELECT RST result ,'' CLM_NO FROM DUAL; 
                    email_pack_error('Error From Package' , 'module bancas save_ref_data</br>'||RST) ;
                    return;      
                END IF;        
                            
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  vSTS_KEY ,1 ,'MEDSTS','MEDSTS11' ,'get BANCAS Claim Data ' ,vCLM_USER , sysdate        
                    );
                exception
                    when others then
                        dbms_output.put_line('error babcas ref_data insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error babcas ref_data insert NC_STATUS: '||sqlerrm;
                end;                     
                IF RST is not null THEN  -- error
                    OPEN P_JOBNO FOR
                    SELECT RST result ,'' CLM_NO FROM DUAL; 
                     email_pack_error('Error From Package' , 'module save_babcas_ref_data</br>'||RST) ;
                    return;      
                END IF;                
            END LOOP;                
        END IF;

        FOR X11 IN (
            SELECT CLM_NO FROM NC_MAS 
            WHERE STS_KEY = vSTS_KEY
        )    LOOP
            tmp_CLMNO := x11.clm_no ;
        END LOOP;      
                
        FOR X2 IN (
            SELECT STS_KEY, INVOICE, CLM_TYPE, POLICY_NO, FLEET_SEQ, NAME, SURNAME, HN, 
                   ICD10, CAUSE_CODE, RISK_DESC, 
                   to_date(LOSS_DATE,'dd/mm/rrrr') LOSS_DATE, 
                   to_date(FR_LOSS_DATE,'dd/mm/rrrr') FR_LOSS_DATE, 
                   to_date(TO_LOSS_DATE,'dd/mm/rrrr') TO_LOSS_DATE, 
                   HPT_CODE, DAY, HPT_USER, RECPT_SEQ, REMARK, EVN_DESC, ID_NO, SID, 
                   SUB_CAUSE_CODE, DAY_ADD
            FROM NC_MASTER_TMP 
            WHERE STS_KEY = vSTS_KEY
        )    LOOP
            INSERT INTO NC_MAS_BANCAS (
                STS_KEY, INVOICE, CLM_TYPE, POLICY_NO, FLEET_SEQ, NAME, SURNAME, 
                HN, ICD10, CAUSE_CODE, RISK_DESC, LOSS_DATE, FR_LOSS_DATE, TO_LOSS_DATE, 
                HPT_CODE, DAY, HPT_USER, RECPT_SEQ, REMARK, EVN_DESC, ID_NO, SID, 
                SUB_CAUSE_CODE, DAY_ADD, P_FAX
            ) VALUES (
                X2.STS_KEY, X2.INVOICE, X2.CLM_TYPE, X2.POLICY_NO, X2.FLEET_SEQ, X2.NAME, X2.SURNAME, 
                X2.HN, X2.ICD10, X2.CAUSE_CODE, X2.RISK_DESC, X2.LOSS_DATE, X2.FR_LOSS_DATE, X2.TO_LOSS_DATE, 
                X2.HPT_CODE, X2.DAY, X2.HPT_USER, X2.RECPT_SEQ, X2.REMARK, X2.EVN_DESC, X2.ID_NO, X2.SID, 
                X2.SUB_CAUSE_CODE, X2.DAY_ADD, P_FAX
            );
            v_hpt_name := nc_health_package.get_hospital_name(null,'T' ,X2.HPT_CODE );
            
            FOR B1 in (
                select distinct a.ref_no1 id_card,  a.cus_name , branch_code
                , pay_date +1 fr_date ,pay_date + 366 to_date
                from acc_file_data a  -- table ที่ทางการเงินรับข้อมูลของ bancas มาก่อนออก Policy -- 
                where file_type = '02' and file_format = '002' and receive_from = '04'
                and  X2.ID_NO =  ref_no1
                and  nvl(X2.LOSS_DATE,trunc(sysdate)) between  pay_date + 1  and pay_date + 366
            ) LOOP
                vBranch_code := B1.branch_code ;
                vCustDetail := 'Id-Card: '||B1.id_card||' ชื่อ: '||B1.cus_name||' fr_date: '||B1.fr_date||' to_date: '||B1.to_date ;
                if substr(vBranch_code,1,1) = '0' then
                    vBranch_code := substr(vBranch_code,2) ;
                end if;    
                FOR B2 in (
                    select (select thai_name from bank where bank_code = a.bank_code )||' '||thai_brn_name  bank
                    from bank_branch a
                    where bank_code ='02' 
                    and branch_code = vBranch_code              
                ) LOOP
                    vBranch_name := B2.bank ;    
                END LOOP; --B2
            END LOOP; --B1              
            
            IF  CHK_NCMAS   THEN -- ยังไม่ได้ insert NC_STATUS
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  vSTS_KEY ,1 ,'MEDSTS','MEDSTS11' ,'get BANCAS Claim Data ' ,X2.HPT_USER , sysdate        
                    );
                exception
                    when others then
                        dbms_output.put_line('error babcas ref_data insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error babcas ref_data insert NC_STATUS: '||sqlerrm;
                end;                     
                IF RST is not null THEN  -- error
                    OPEN P_JOBNO FOR
                    SELECT RST result ,'' CLM_NO FROM DUAL; 
                     email_pack_error('Error From Package' , 'module save_babcas_ref_data</br>'||RST) ;
                    return;      
                END IF;                 
            END IF;            
        END LOOP;        
        
        FOR X3 IN (
            SELECT STS_KEY , PREMCODE PREM_CODE ,REMAIN_AMT AMOUNT
            FROM NC_DETAIL_TMP 
            WHERE STS_KEY = vSTS_KEY 
        )    LOOP
            INSERT INTO NC_RES_BANCAS (
                STS_KEY , PREM_CODE, AMOUNT
            ) VALUES (
                X3.STS_KEY , X3.PREM_CODE, X3.AMOUNT
            );
            
        END LOOP;  
        
        
        BEGIN
          DELETE NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY;
          DELETE NC_DETAIL_TMP A WHERE A.STS_KEY = vSTS_KEY;
        EXCEPTION
            WHEN OTHERS THEN
                null;
        END;               
        
        COMMIT;
        RST := null ;
        email_notice_bancas('มีงานเคลม BANCAS ใหม่เข้ามา' , ' '||v_hpt_name||' สร้างเลขอ้างอิงเคลม BANCAS :'||vSTS_KEY||
        '<br/><strong>'||vCustDetail||'</strong>'||
        '<br/>ออกบัตรจาก '||vBranch_name||
        '<br/>กรุณาดำเนินการเปิดเคลมต่อไปด้วย ที่โปรแกรม  CLNMC923 ');
        OPEN P_JOBNO FOR
                SELECT RST result ,tmp_CLMNO CLM_NO FROM DUAL;
                
    EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK; 
        RST :=  'error SAVE_BANCAS : '||sqlerrm ;   
        OPEN P_JOBNO FOR
                SELECT RST result ,tmp_CLMNO CLM_NO FROM DUAL;
    END SAVE_BANCAS ;   -- END SAVE_BANCAS           

    PROCEDURE UPDATE_BANCAS(P_FAX IN VARCHAR2 ,vSTS_KEY IN NUMBER  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2) IS      -- RST = null คือ สำเร็จ  
        v_hpt_name varchar2(200);
        tmp_CLMNO   varchar2(20);
        vCLM_NO   varchar2(20);
        chk_ncmas   boolean:=false;
        vCLM_USER   varchar2(20);
        vPOL_NO   varchar2(20);
        vPOL_RUN    number(20);
        vMax_Sts_seq number(2);
    BEGIN
        FOR X1 IN (
            SELECT count(*) cnt  FROM NC_MASTER_TMP 
            WHERE STS_KEY = vSTS_KEY
        )    LOOP
            if X1.cnt = 0 then
                RST := 'ไม่พบข้อมูลเปิดเคลม'; return ;
            end if;
        END LOOP;

        FOR X12 IN (
            SELECT count(*) cnt ,max(clm_no) xclm FROM NC_MAS
            WHERE STS_KEY = vSTS_KEY
        )    LOOP
            if X12.cnt > 0 then
                chk_ncmas := true;
                vCLM_NO := X12.xclm ;
            end if;
        END LOOP;

        begin
            select  nvl(max(sts_seq),0) into vMax_Sts_seq
            from nc_status
            where sts_key = vSTS_KEY;            
        exception
            when no_data_found then
                vMax_Sts_seq := 0;
            when others then
                vMax_Sts_seq := 0;
        end;
                    
        BEGIN
          DELETE NC_MAS_BANCAS A WHERE A.STS_KEY = vSTS_KEY;
          DELETE NC_RES_BANCAS A WHERE A.STS_KEY = vSTS_KEY;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK; 
                RST :=  'error UPDATE_BANCAS : '||sqlerrm ;   
                OPEN P_JOBNO FOR
                        SELECT RST result ,tmp_CLMNO CLM_NO FROM DUAL;
        END;                
              
        IF  not CHK_NCMAS   THEN
            --vCLM_NO := 'N'||to_char(sysdate,'rrrr')||lpad(vSTS_KEY ,11,0) ;
            FOR P_MASTER in (
            SELECT A.STS_KEY,    A.POLICY_NO,       A.FLEET_SEQ,  A.RECPT_SEQ ,       A.NAME,       A.SURNAME,   A.ID_NO 
             ,A.LOSS_DATE,   A.HPT_CODE,     A.HPT_USER
            FROM NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY AND ROWNUM=1
            ) LOOP
                p_acc_package.read_pol(P_MASTER.policy_no ,vPOL_NO ,vPOL_RUN);
                vCLM_USER := P_MASTER.HPT_USER ;
                begin 
                    insert into nc_mas 
                    ( sts_key,clm_no ,pol_no ,pol_run  ,recpt_seq ,hpt_code ,cus_name 
                     ,reg_date ,loss_Date ,fleet_seq  ,clm_user ,ID_NO )
                    values     
                    (  vSTS_KEY ,vCLM_NO  ,vpol_no ,vpol_run  ,P_MASTER.RECPT_SEQ ,P_MASTER.HPT_CODE ,P_MASTER.NAME||' '||P_MASTER.SURNAME 
                     ,sysdate , to_date( P_MASTER.LOSS_DATE,'dd/mm/rrrr')  ,P_MASTER.FLEET_SEQ  ,vCLM_USER ,P_MASTER.ID_NO
                    );
                exception
                    when others then
                        dbms_output.put_line('error bancas ref_data insert NC_MAS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error bancas ref_data insert NC_MAS: '||sqlerrm;
                        
                end;                  
                IF RST is not null THEN  -- error
                    OPEN P_JOBNO FOR
                    SELECT RST result ,'' CLM_NO FROM DUAL; 
                    email_pack_error('Error From Package' , 'module bancas update_ref_data</br>'||RST) ;
                    return;      
                END IF;        
                            
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  vSTS_KEY ,1 ,'MEDSTS','MEDSTS11' ,'get BANCAS Claim Data ' ,vCLM_USER , sysdate        
                    );
                exception
                    when others then
                        dbms_output.put_line('error babcas ref_data insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'error babcas ref_data insert NC_STATUS: '||sqlerrm;
                end;                     
                IF RST is not null THEN  -- error
                    OPEN P_JOBNO FOR
                    SELECT RST result ,'' CLM_NO FROM DUAL; 
                     email_pack_error('Error From Package' , 'module update_babcas_ref_data</br>'||RST) ;
                    return;      
                END IF;                
            END LOOP;        
        END IF;

        FOR X11 IN (
            SELECT CLM_NO FROM NC_MAS 
            WHERE STS_KEY = vSTS_KEY
        )    LOOP
            tmp_CLMNO := x11.clm_no ;
        END LOOP;      
                
        FOR X2 IN (
            SELECT STS_KEY, INVOICE, CLM_TYPE, POLICY_NO, FLEET_SEQ, NAME, SURNAME, HN, 
                   ICD10, CAUSE_CODE, RISK_DESC, 
                   to_date(LOSS_DATE,'dd/mm/rrrr') LOSS_DATE, 
                   to_date(FR_LOSS_DATE,'dd/mm/rrrr') FR_LOSS_DATE, 
                   to_date(TO_LOSS_DATE,'dd/mm/rrrr') TO_LOSS_DATE, 
                   HPT_CODE, DAY, HPT_USER, RECPT_SEQ, REMARK, EVN_DESC, ID_NO, SID, 
                   SUB_CAUSE_CODE, DAY_ADD
            FROM NC_MASTER_TMP 
            WHERE STS_KEY = vSTS_KEY
        )    LOOP
            vCLM_USER := X2.HPT_USER ;
            INSERT INTO NC_MAS_BANCAS (
                STS_KEY, INVOICE, CLM_TYPE, POLICY_NO, FLEET_SEQ, NAME, SURNAME, 
                HN, ICD10, CAUSE_CODE, RISK_DESC, LOSS_DATE, FR_LOSS_DATE, TO_LOSS_DATE, 
                HPT_CODE, DAY, HPT_USER, RECPT_SEQ, REMARK, EVN_DESC, ID_NO, SID, 
                SUB_CAUSE_CODE, DAY_ADD, P_FAX
            ) VALUES (
                X2.STS_KEY, X2.INVOICE, X2.CLM_TYPE, X2.POLICY_NO, X2.FLEET_SEQ, X2.NAME, X2.SURNAME, 
                X2.HN, X2.ICD10, X2.CAUSE_CODE, X2.RISK_DESC, X2.LOSS_DATE, X2.FR_LOSS_DATE, X2.TO_LOSS_DATE, 
                X2.HPT_CODE, X2.DAY, X2.HPT_USER, X2.RECPT_SEQ, X2.REMARK, X2.EVN_DESC, X2.ID_NO, X2.SID, 
                X2.SUB_CAUSE_CODE, X2.DAY_ADD, P_FAX
            );
            v_hpt_name := nc_health_package.get_hospital_name(null,'T' ,X2.HPT_CODE );
        END LOOP;        
        
        FOR X3 IN (
            SELECT STS_KEY , PREMCODE PREM_CODE ,REMAIN_AMT AMOUNT
            FROM NC_DETAIL_TMP 
            WHERE STS_KEY = vSTS_KEY 
        )    LOOP
            INSERT INTO NC_RES_BANCAS (
                STS_KEY , PREM_CODE, AMOUNT
            ) VALUES (
                X3.STS_KEY , X3.PREM_CODE, X3.AMOUNT
            );
            
        END LOOP;  

        begin 
            insert into nc_status 
            ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
            values     
            (  vSTS_KEY ,vMax_Sts_seq+1 ,'MEDSTS','MEDSTS11' ,'edit BANCAS Claim Data ' ,vCLM_USER , sysdate        
            );
        exception
            when others then
                dbms_output.put_line('error insert BANCAS NC_STATUS: '||sqlerrm);
                ROLLBACK;
                RST := 'error insert BANCAS NC_STATUS: '||sqlerrm;
        end;   
        IF RST is not null THEN  -- error
            OPEN P_JOBNO FOR
            SELECT RST result ,'' CLM_NO FROM DUAL; 
             email_pack_error('Error From Package' , 'module update_babcas_ref_data</br>'||RST) ;
            return;      
        END IF;               
                        
        BEGIN
          DELETE NC_MASTER_TMP A WHERE A.STS_KEY = vSTS_KEY;
          DELETE NC_DETAIL_TMP A WHERE A.STS_KEY = vSTS_KEY;
        EXCEPTION
            WHEN OTHERS THEN
                null;
        END;                
        
        COMMIT;
        RST := null ;
--        email_notice_bancas('มีงานเคลม BANCAS ใหม่เข้ามา' , 'โรงพยาบาล '||v_hpt_name||' สร้างเลขอ้างอิงเคลม BANCAS :'||vSTS_KEY||
--        '<br/>กรุณาดำเนินการเปิดเคลมต่อไปด้วย ที่โปรแกรม  CLNMC923 ');
        OPEN P_JOBNO FOR
                SELECT RST result ,tmp_CLMNO CLM_NO FROM DUAL;
                
    EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK; 
        RST :=  'error UPDATE_BANCAS : '||sqlerrm ;   
        OPEN P_JOBNO FOR
                SELECT RST result ,tmp_CLMNO CLM_NO FROM DUAL;
    END UPDATE_BANCAS ;   -- END UPDATE_BANCAS           


    PROCEDURE UPDATE_STATUS_BANCAS(vSTS_KEY IN NUMBER  ,
                             RST OUT VARCHAR2)      IS     -- RST = null คือ สำเร็จ

        chk_ncmas   boolean:=false;
        vCLM_USER   varchar2(20);
        vMax_Sts_seq number(2);
    BEGIN

        FOR X12 IN (
            SELECT CLM_USER FROM NC_MAS
            WHERE STS_KEY = vSTS_KEY
        )    LOOP
                vCLM_USER := X12.CLM_USER ;
        END LOOP;

        begin
            select  nvl(max(sts_seq),0) into vMax_Sts_seq
            from nc_status
            where sts_key = vSTS_KEY;            
        exception
            when no_data_found then
                vMax_Sts_seq := 0;
            when others then
                vMax_Sts_seq := 0;
        end;

        begin 
            insert into nc_status 
            ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
            values     
            (  vSTS_KEY ,vMax_Sts_seq+1 ,'MEDSTS','MEDSTS12' ,'Billing BANCAS Claim ' ,vCLM_USER , sysdate        
            );
        exception
            when others then
                dbms_output.put_line('error insert BANCAS NC_STATUS: '||sqlerrm);
                ROLLBACK;
                RST := 'error insert BANCAS NC_STATUS: '||sqlerrm;
        end;         
        
        COMMIT;
        RST := null ;
                
    EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK; 
        RST :=  'error UPDATE_STATUS_BANCAS : '||sqlerrm ;   
    END UPDATE_STATUS_BANCAS ;   
                                 
    FUNCTION IS_BANCAS_CLAIM(vSTS_KEY IN NUMBER) RETURN BOOLEAN IS      
        vFound  varchar2(10);
        vFound2  varchar2(10);
    BEGIN
            
        begin
            select 'found' into vFound
            from nc_mas_bancas
            where sts_key = vSTS_KEY        ;
        exception
            when no_data_found then
                vFound := null;
            when others then
                vFound := null;
        end;        
        if vFound is not null then
            begin
                select  substr(clm_no,1,1) into vFound2
                from nc_mas
                where sts_key = vSTS_KEY      
--                and substr(clm_no,1,1) = 'N' 
                ;
            exception
                when no_data_found then
                    vFound2 := null;
                when others then
                    vFound2 := null;
            end;        
            if vFound2 is not null then      
                if vFound2 = 'N' then -- found Dummy Clm 
                    RETURN TRUE;
                else RETURN FALSE; end if; -- Clm was opened policy 
            else
                RETURN TRUE;
            end if; 
        else
            RETURN FALSE;
        end if;
    END; --   IS_BANCAS_CLAIM

    FUNCTION IS_UNNAME_POLICY(P_Pol_no IN VARCHAR2 ,P_Pol_run IN NUMBER) RETURN BOOLEAN IS
        vFound  varchar2(10);
        vFound2  varchar2(10);    
    BEGIN
        begin
            select unname_pol into vFound
            from mis_mas
            where pol_no = P_Pol_no and pol_run = P_Pol_run and unname_pol is not null and rownum=1        ;
        exception
            when no_data_found then
                vFound := null;
            when others then
                vFound := null;
        end;      
        
        if vFound is not null then
            RETURN TRUE;
        else
            RETURN FALSE;
        end if;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END IS_UNNAME_POLICY;    

    PROCEDURE GET_UNNAME_GROUP(P_Pol_no IN VARCHAR2 ,P_Pol_run IN NUMBER  , P_End_seq IN NUMBER  , P_Recpt_seq IN NUMBER  ,
                             RST OUT VARCHAR2 ,group_count OUT NUMBER ,O_GROUP_MEMBER OUT  v_ref_cursor3 )   IS      -- RST = null คือ สำเร็จ    

--        c1   NC_HEALTH_PACKAGE.v_ref_cursor3;  
--
--        TYPE t_data1 IS RECORD
--        (
--        GRP_SEQ  NUMBER,
--        SUM_INS  NUMBER,
--        FLEET_COUNT NUMBER,
--        FR_DATE DATE ,
--        TO_DATE DATE
--        ); 
--        j_rec1 t_data1;           
        xEnd_seq    NUMBER;
        xRecpt_seq NUMBER;
    BEGIN
        /* SET default value */
        xEnd_seq := 0;
        xRecpt_seq := 1 ;
       /* END default value */    
     
        begin
            SELECT count(*) into group_count
            FROM pa_cov_grp 
            WHERE pol_no = P_Pol_no AND pol_run = P_Pol_run and end_seq = xEnd_seq and recpt_seq =  xRecpt_seq
            group by pol_no ,pol_run ,end_seq ,recpt_seq ;
        exception
            when no_data_found then
                group_count := 0;
            when others then
                group_count := 0;
        end;      
        
        if group_count = 0 then -- not found pa_group
            RST :=null;
            group_count := 0;
            OPEN O_GROUP_MEMBER FOR
            select 0 GRP_SEQ , 0 SUM_INS ,0 FLEET_COUNT , null FR_DATE , null TO_DATE
            from dual ;            
        else
            OPEN O_GROUP_MEMBER FOR
            SELECT  GRP_SEQ , SUM_INS ,FLEET_AMT FLEET_COUNT ,  FR_DATE ,  TO_DATE
            FROM pa_cov_grp 
            WHERE pol_no = P_Pol_no AND pol_run = P_Pol_run and end_seq = xEnd_seq and recpt_seq =  xRecpt_seq;
            RST :=null;
        end if;
    EXCEPTION
        WHEN OTHERS THEN
            RST := 'error GET_UNNAME_GROUP :'||sqlerrm;
            group_count := 0;
            OPEN O_GROUP_MEMBER FOR
            select 0 GRP_SEQ , 0 SUM_INS ,0 FLEET_COUNT , null FR_DATE , null TO_DATE
            from dual ;
        
    END GET_UNNAME_GROUP;    

    PROCEDURE GET_UNNAME_STATUS(P_Pol_no IN VARCHAR2 ,P_Pol_run IN NUMBER  , P_LOSS_DATE IN DATE  ,
                             RST OUT VARCHAR2 )    IS     --  Y = คุ้มครอง  ,N =  ไม่คุ้มครอง ,E = อื่นๆ ตรวจสอบ                                 
        cnt_cancel  number:=0;
        
    BEGIN
        RST := 'Y' ;
        
        begin
            SELECT count(*) into cnt_cancel
             from mis_mas
             where pol_no = P_Pol_no AND pol_run = P_Pol_run 
             and unname_pol is not null;
        exception
            when no_data_found then
                cnt_cancel := 0;
            when others then
                cnt_cancel := 0;
        end;     

        if cnt_cancel = 0 then -- ไม่พบเลขกรมธรรม์
            rst := 'E' ; return ;
        end if;
                
        begin
            SELECT count(*) into cnt_cancel
            FROM mis_mas
            WHERE pol_no = P_Pol_no AND pol_run = P_Pol_run 
            and cancel is not null ;
        exception
            when no_data_found then
                cnt_cancel := 0;
            when others then
                cnt_cancel := 0;
        end;      
        
        if cnt_cancel > 0 then
            rst := 'N' ; return ;
        end if;

        begin
            SELECT count(*) into cnt_cancel
             from mis_mas
             where pol_no = P_Pol_no AND pol_run = P_Pol_run 
             and P_LOSS_DATE between fr_date and to_date
             and unname_pol is not null ;
        exception
            when no_data_found then
                cnt_cancel := 0;
            when others then
                cnt_cancel := 0;
        end;                

        if cnt_cancel > 0 then -- พบ เคลม ในช่วงคุ้มครอง
            rst := 'Y' ; return ;
        else
            rst := 'N' ; return ;
        end if;
                                
    END GET_UNNAME_STATUS ; 

    PROCEDURE SAVE_UNNAME_CLAIM(P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2) IS
        TYPE t_data4 IS RECORD
        (
        STS_KEY  NUMBER,
        INVOICE    VARCHAR2(20),
        CLM_TYPE    VARCHAR2(3),
        POLICY_NO    VARCHAR2(50),
        FLEET_SEQ  NUMBER ,
        RECPT_SEQ  NUMBER ,
        NAME    VARCHAR2(200),
        SURNAME    VARCHAR2(200),
        HN    VARCHAR2(20),
        ICD10    VARCHAR2(20),
        CAUSE_CODE    VARCHAR2(20),
        RISK_DESC    VARCHAR2(200),
        LOSS_DATE    VARCHAR2(10), --dd/mm/rrrr
        FR_LOSS_DATE    VARCHAR2(10),
        TO_LOSS_DATE    VARCHAR2(10),
        HPT_CODE   VARCHAR2(20), 
        DAY   NUMBER,
        HPT_USER    VARCHAR2(10),
        REMARK      VARCHAR2(200),
        EVN_DESC    VARCHAR2(200),
        SUB_CAUSE_CODE VARCHAR2(10),
        GRP_SEQ NUMBER
        ); 
        j_rec4 t_data4;     
    
        TYPE t_data1 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        REQUEST_AMT  NUMBER,
        REMAIN_AMT NUMBER
        ); 
        j_rec1 t_data1;            
        
        C2   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data2 IS RECORD
        (
        POL_NO  MIS_RI_MAS.POL_NO%TYPE ,
        POL_RUN MIS_RI_MAS.POL_RUN%TYPE ,
        RI_CODE MIS_RI_MAS.RI_CODE%TYPE ,
        RI_BR_CODE MIS_RI_MAS.RI_BR_CODE%TYPE ,
        RI_TYPE MIS_RI_MAS.RI_TYPE%TYPE ,
        LF_FLAG MIS_RI_MAS.LF_FLAG%TYPE ,
        RI_SUB_TYPE MIS_RI_MAS.RI_SUB_TYPE%TYPE ,
        --RI_SUM  MIS_RI_MAS.RI_SUM_INS%TYPE ,
        --RI_SUM  NUMBER(20,2),
        RI_SUM_SHR   NUMBER     
        ); 
        j_rec2 t_data2;      
                
        v_key   number;     
        v_cnt_res   number;      
        v_tot_res   number:= 0;           
        v_shr_amt   number(13,2);
        v_sum_res   number:=0;
        v_rec   number:=0;     
        v_logrst    varchar2(200);        
        
        vSTS_KEY NC_MAS.STS_KEY%TYPE ;
        vCLM_NO NC_MAS.CLM_NO%TYPE ;
        vREG_NO NC_MAS.REG_NO%TYPE ;
        vPOL_NO NC_MAS.POL_NO%TYPE ;
        vPOL_RUN NC_MAS.POL_RUN%TYPE ;
        vEND_SEQ NC_MAS.END_SEQ%TYPE := 0;
        vRECPT_SEQ NC_MAS.RECPT_SEQ%TYPE :=1;
        vALC_RE NC_MAS.ALC_RE%TYPE ;
        vCLM_YR NC_MAS.CLM_YR%TYPE ;
        vPOL_YR NC_MAS.POL_YR%TYPE ;
        vPROD_GRP NC_MAS.PROD_GRP%TYPE ;
        vPROD_TYPE     NC_MAS.PROD_TYPE%TYPE ;
        vINVOICE_NO NC_MAS.INVOICE_NO%TYPE ;
        vHN_NO NC_MAS.HN_NO%TYPE ;
        vHPT_CODE NC_MAS.HPT_CODE%TYPE ;
        vMAS_CUS_CODE NC_MAS.MAS_CUS_CODE%TYPE ;
        vMAS_CUS_SEQ NC_MAS.MAS_CUS_SEQ%TYPE ;
        vMAS_CUS_NAME NC_MAS.MAS_CUS_NAME%TYPE ;
        vCUS_CODE NC_MAS.CUS_CODE%TYPE ;
        vCUS_SEQ NC_MAS.CUS_SEQ%TYPE ;
        vCUS_NAME   NC_MAS.CUS_NAME%TYPE ;
        vFAX_CLM NC_MAS.FAX_CLM%TYPE ;
        vFAX_CLM_DATE NC_MAS.FAX_CLM_DATE%TYPE ;
        vREG_DATE NC_MAS.REG_DATE%TYPE ;
        vCLM_DATE NC_MAS.CLM_DATE%TYPE ;
        vLOSS_DATE NC_MAS.LOSS_DATE%TYPE ;
        vFR_DATE NC_MAS.FR_DATE%TYPE ;
        vTO_DATE NC_MAS.TO_DATE%TYPE ;
        vTR_DATE_FR NC_MAS.TR_DATE_FR%TYPE ;
        vTR_DATE_TO NC_MAS.TR_DATE_TO%TYPE ;
        vADD_TR_DAY NC_MAS.ADD_TR_DAY%TYPE ;
        vTOT_TR_DAY NC_MAS.TOT_TR_DAY%TYPE ;
        vLOSS_DETAIL NC_MAS.LOSS_DETAIL%TYPE ; 
        vIPD_FLAG NC_MAS.IPD_FLAG%TYPE ;
        vDIS_CODE NC_MAS.DIS_CODE%TYPE ;
        vCAUSE_CODE   NC_MAS.CAUSE_CODE%TYPE ;
        vFLEET_SEQ    NC_MAS.FLEET_SEQ%TYPE ;
        vRUN_FLEET_SEQ       NC_MAS.RUN_FLEET_SEQ%TYPE ;
        vMAS_SUM_INS   NC_MAS.MAS_SUM_INS%TYPE ;
        vCLM_USER   NC_MAS.CLM_USER%TYPE ;
        vRemark     NC_MAS.REMARK%TYPE ;
        --vEvndesc    NC_MAS.EVN_DESC%TYPE ;
        vIDNO    NC_MAS.ID_NO%TYPE ;
        vSub_Cause  NC_MAS.SUB_CAUSE_CODE%TYPE ;
        vGRP_SEQ    NC_MAS.GRP_SEQ%TYPE ;
        
        vYour_Pol   MIS_CRI_RES.YOUR_POL%TYPE;
        vLett_Prt   MIS_CRI_RES.LETT_PRT%TYPE;
        vLett_no   MIS_CRI_RES.LETT_NO%TYPE;
        
        vMax_Sts_seq    number(3);
        vExist    varchar2(5);        
    BEGIN
        RST := null;
        LOOP  -- get Master Data
           FETCH  P_MASTER INTO j_rec4;
            EXIT WHEN P_MASTER%NOTFOUND;
            dbms_output.put_line('Invoice==>'||  j_rec4.invoice||  ' ClmType:'||  j_rec4.clm_type|| ' Pol_no/Run:'||  j_rec4.policy_no|| ' LossDate:'||  j_rec4.loss_date); 
            
            if nvl(j_rec4.sts_key,0) = 0 then
            v_key := gen_stskey(''); -- สร้าง STS_KEY
            else 
            v_key := j_rec4.sts_key;             
            end if;
            
            begin
                select  nvl(max(sts_seq),0) into vMax_Sts_seq
                from nc_status
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_Sts_seq := 0;
                when others then
                    vMax_Sts_seq := 0;
            end;
            
            p_acc_package.read_pol(j_rec4.policy_no ,vPOL_NO ,vPOL_RUN);
            
            begin
                  SELECT POL_YR,  PROD_TYPE, prod_grp, to_char(sysdate,'rrrr') clm_yr ,
                         CUS_CODE, CUS_SEQ, substr(CUS_ENQ,1,90), ALC_RE ,SUM_INS ,END_SEQ
                  INTO
                         vPOL_YR, vPROD_TYPE, vprod_grp, vCLM_YR ,
                         vMAS_CUS_CODE, vMAS_CUS_SEQ, vMAS_CUS_NAME  , vALC_RE ,vMAS_SUM_INS ,vEND_SEQ
                    FROM MIS_MAS
                    WHERE POL_NO = vPOL_NO AND
                            nvl(pol_run,0) = vPOL_RUN and
                              END_SEQ = (SELECT MIN(END_SEQ) FROM MIS_MAS
                                         WHERE POL_NO =vPOL_NO AND 
                                               nvl(pol_run,0) = vPOL_RUN and
                                               (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE));                  
            exception
                when no_data_found then
                    RST :='Save UNNAME: not found policy no :'||j_rec4.policy_no;
                when others then
                    RST :='Save UNNAME: not found policy no :'||j_rec4.policy_no;
            end;
                                
            BEGIN
            SELECT MIN(FR_DATE),MAX(TO_DATE)
            INTO vFR_DATE,vTO_DATE
            FROM MIS_MAS
            WHERE POL_NO =vPOL_NO AND
                  nvl(pol_run,0) = to_number(vPOL_RUN) and
                  (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE);
                                  
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
              null;
              WHEN OTHERS THEN null;
            END;       
                  
--            begin
--                select recpt_seq ,cus_code ,cus_seq ,cus_enq 
--                into vRECPT_SEQ ,vCUS_CODE ,vCUS_SEQ , vCUS_NAME
--                from mis_recpt
--                where pol_no =vPOL_NO and pol_run =vPOL_RUN    
--                and end_seq = vEND_SEQ
--                --and recpt_seq in (select min(x.recpt_seq) from mis_recpt x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  
--                --and x.end_seq = vEND_SEQ and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)               
--                --)
--                and recpt_seq = j_rec4.recpt_seq ;            
--            exception
--                when no_data_found then
--                    --RST :='not found mis_recpt  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
--                    begin
--                        select recpt_seq ,cus_code ,cus_seq ,cus_enq 
--                        into vRECPT_SEQ ,vCUS_CODE ,vCUS_SEQ , vCUS_NAME
--                        from mis_recpt a
--                        where pol_no =vPOL_NO and pol_run =vPOL_RUN   
--                        --and end_seq = 0 
--                        --and end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
--                        --and recpt_seq in (select min(x.recpt_seq) from mis_recpt x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  
--                            --and x.end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
--                            --and x.end_seq =0 
--                          --  and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)
--                        --)
--                         and recpt_seq = j_rec4.recpt_seq;            
--                    exception
--                        when no_data_found then
--                            begin
--                                select recpt_seq ,cus_code ,cus_seq ,cus_enq 
--                                into vRECPT_SEQ ,vCUS_CODE ,vCUS_SEQ , vCUS_NAME
--                                from mis_recpt a
--                                where pol_no =vPOL_NO and pol_run =vPOL_RUN   
--                                and end_seq = vEND_SEQ
--                                --and end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
--                                and recpt_seq in (select min(x.recpt_seq) from mis_recpt x where x.pol_no =vPOL_NO and x.pol_run =vPOL_RUN  
--                                    --and x.end_seq in (select min(xx.end_seq) from mis_recpt xx where xx.pol_no =vPOL_NO and xx.pol_run =vPOL_NO )
--                                    and x.end_seq =vEND_SEQ 
--                                    --and (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE)
--                                );            
--                            exception
--                                when no_data_found then
--                                    RST :='in not found mis_recpt1  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
--                                when others then
--                                    RST :='in other mis_recpt1  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
--                            end;                                 
--                            --RST :='in not found mis_recpt2  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
--                        when others then
--                            RST :='in other mis_recpt2  :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
--                    end;                    
--                when others then
--                    RST :='in other mis_recpt3 :'||vPOL_NO||' run: '||vPOL_RUN||' recpt: '||j_rec4.RECPT_SEQ|| ' endSeq: '||vEND_SEQ;
--            end;
--                       

            vRECPT_SEQ := 1;
            vCUS_CODE := '';
            vCUS_SEQ := null;
            vCUS_NAME := j_rec4.NAME||' '||j_rec4.SURNAME;
            
            vREG_DATE := trunc(sysdate);
            vCLM_DATE := trunc(sysdate);
            vHN_NO := j_rec4.HN;
            vHPT_CODE := nc_health_package.GET_BKI_HPTCODE(j_rec4.HPT_CODE);
            vCAUSE_CODE := j_rec4.CAUSE_CODE; 
            vDIS_CODE :=  j_rec4.ICD10; 
            vIPD_FLAG :=  j_rec4.CLM_TYPE; 
            vLOSS_DETAIL := j_rec4.RISK_DESC ;
            vFLEET_SEQ := nvl(j_rec4.FLEET_SEQ,1);

            vINVOICE_NO :=  j_rec4.INVOICE;
            vLOSS_DATE := to_date(j_rec4.LOSS_DATE,'dd/mm/rrrr'); 
            vCLM_USER := j_rec4.HPT_USER;   
            vTR_DATE_FR :=  to_date(j_rec4.FR_LOSS_DATE,'dd/mm/rrrr'); 
            vTR_DATE_TO :=  to_date(j_rec4.TO_LOSS_DATE,'dd/mm/rrrr'); 
            vTOT_TR_DAY := j_rec4.DAY;   
            vRemark := j_rec4.Remark;   -- เก็บ free text สถานพยาบาล 
            --vEvndesc := j_rec4.Evn_desc;
            vSub_Cause := j_rec4.SUB_CAUSE_CODE ;
            vGRP_SEQ    := j_rec4.GRP_SEQ;
            
            IF vDIS_CODE is null THEN  -- กรณีไม่ระบุ icd จะนำ free text มาบันทึกแทน
                vLOSS_DETAIL := j_rec4.Evn_desc;
            END IF;
            
            if nvl('N','N')  = 'Y' then
                vFax_clm := 'Y';
                vFax_Clm_date := trunc(sysdate);
            end if;
            
            vCLM_NO := gen_clmno(vPROD_TYPE,'0');
            
            -- /// เช็คว่ามีรายการรับแจ้งไว้หรือไม่
            begin
                select  'ex'
                into  vExist
                from nc_mas
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vExist :=null ;
                when others then
                    vExist :=null ;
            end;            
            dbms_output.put_line('key:'||v_key||' clm_no:'||vCLM_NO||' Exist: '||vExist);
            
            if vExist is  null then -- ยังไม่เคยแจ้ง 
                begin 
                    insert into nc_mas 
                    ( sts_key ,clm_no ,pol_no ,pol_run ,end_seq ,recpt_seq ,alc_re ,clm_yr ,pol_yr ,prod_grp ,prod_type 
                    ,invoice_no ,hn_no ,hpt_code ,mas_cus_code ,mas_cus_seq ,mas_cus_name ,cus_code ,cus_seq ,cus_name 
                    ,fax_clm ,fax_clm_date 
                     ,reg_date ,clm_date ,loss_Date ,fr_date ,to_date ,tr_date_fr ,tr_date_to , ADD_TR_DAY ,tot_tr_daY
                    ,loss_detail , ipd_flag ,dis_code ,cause_code
                    ,fleet_seq ,run_fleet_seq ,mas_sum_ins ,clm_user ,remark ,id_no ,SUB_CAUSE_CODE ,GRP_SEQ   )
                    values     
                    (  v_key ,vclm_no ,vpol_no ,vpol_run ,vend_seq ,vrecpt_seq ,valc_re ,vclm_yr ,vpol_yr ,vprod_grp ,vprod_type 
                    ,vinvoice_no ,vhn_no ,vhpt_code ,vmas_cus_code ,vmas_cus_seq ,vmas_cus_name ,vcus_code ,vcus_seq ,vcus_name 
                    ,vfax_clm ,vfax_clm_date 
                     ,vreg_date ,vclm_date ,vloss_Date ,vfr_date ,vto_date ,vtr_date_fr ,vtr_date_to ,vADD_TR_DAY ,vtot_tr_daY
                    ,vloss_detail ,vipd_flag ,vdis_code ,vcause_code
                    ,vfleet_seq ,vrun_fleet_seq  ,vMAS_SUM_INS   ,vCLM_USER  ,vRemark  ,vIDNO ,vSub_Cause ,vGRP_SEQ
                    );
                exception
                    when others then
                        dbms_output.put_line('error insert NC_MAS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'Save UNNAME: error insert NC_MAS: '||sqlerrm;
                end;    
            else
                begin 
                    update nc_mas 
                    set clm_no = vclm_no ,pol_no =vpol_no ,pol_run =vpol_run ,end_seq=vend_seq ,recpt_seq =vrecpt_seq
                    ,alc_re =valc_re ,clm_yr =vclm_yr ,pol_yr =pol_yr ,prod_grp =vprod_grp ,prod_type =vprod_type 
                    ,invoice_no =vinvoice_no ,hn_no =vhn_no ,hpt_code =vhpt_code,mas_cus_code =vmas_cus_code ,mas_cus_seq =vmas_cus_seq 
                    ,mas_cus_name =vmas_cus_name ,cus_code =vcus_code ,cus_seq =vcus_seq ,cus_name =vcus_name
                     ,fax_clm = vfax_clm ,fax_clm_date =vfax_clm_date 
                     ,reg_date =vreg_date ,clm_date =vclm_date ,loss_Date = vloss_Date ,fr_date =vfr_date ,to_date =vto_date  
                     ,tr_date_fr =vtr_date_fr  ,tr_date_to =vtr_date_to , ADD_TR_DAY =vADD_TR_DAY ,tot_tr_daY =vtot_tr_daY
                     ,loss_detail =vloss_detail , ipd_flag =vipd_flag ,dis_code =vdis_code ,cause_code =vcause_code 
                     ,fleet_seq =vfleet_seq ,run_fleet_seq =vrun_fleet_seq ,mas_sum_ins = vMAS_SUM_INS ,clm_user =vCLM_USER ,remark =vRemark       
                     ,id_no = vIDNO  ,SUB_CAUSE_CODE = vSub_Cause  ,GRP_SEQ =  vGRP_SEQ         
                    where sts_key = v_key;
                exception
                    when others then
                        dbms_output.put_line('error update NC_MAS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'Save UNNAME: error update NC_MAS: '||sqlerrm;
                end;              
            end if;
                
            IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
               --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                email_pack_error('Error From Package' , 'module Save UNNAME: </br>'||RST) ;
                return;      
            END IF;             
            
            -- check FAX CLM data ---
            IF NVL('N','N')  = 'Y' THEN --- Save like send for Approve Fax claim
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  v_key ,vMax_Sts_seq+1 ,'MEDSTS','MEDSTS00' ,'send for Approve FaxClaim ' ,vCLM_USER , sysdate        
                    );
                exception
                    when others then
                        dbms_output.put_line('error insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'Save UNNAME: error insert NC_STATUS: '||sqlerrm;
                end;     
            ELSE    --- Save for Open Claim
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  v_key ,vMax_Sts_seq+1 ,'MEDSTS','MEDSTS11' ,'open claim UNNAME Policy ' ,vCLM_USER , sysdate        
                    );
                exception
                    when others then
                        dbms_output.put_line('error insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'Save UNNAME: error insert NC_STATUS: '||sqlerrm;
                end;                
            END IF;  -- END check FAX CLM data ---
            
            IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module save_step1</br>'||RST) ;
                return;      
            END IF;                    
                                        
        END LOOP;  -- end get Master Data

        LOOP  -- get detail Data
           FETCH  P_DTL INTO j_rec1;
            EXIT WHEN P_DTL%NOTFOUND;
            dbms_output.put_line('Prem==>'||  j_rec1.PREMCODE||  ' RequestAmt:'||  j_rec1.request_amt|| ' ResAmt:'||  j_rec1.REMAIN_AMT); 
            v_tot_res := v_tot_res +  j_rec1.REMAIN_AMT;
            BEGIN
            insert into nc_reserved (
            sts_key ,clm_no ,prod_grp ,prod_type ,type ,sub_type ,trn_seq ,sts_date 
            ,prem_code ,prem_seq ,req_amt ,res_amt ,disc_amt ,trn_amt ,clm_user            
            ) values (
            v_key ,vClm_no ,vprod_grp ,vprod_type ,'1' ,'01' ,1 ,trunc(sysdate)
            , j_rec1.PREMCODE , 1 , j_rec1.request_amt ,j_rec1.REMAIN_AMT ,0 ,j_rec1.REMAIN_AMT ,vCLM_USER
            ) ;
            exception
                when others then
                    dbms_output.put_line('error insert NC_RESERVED: '||sqlerrm);
                    ROLLBACK;
                    RST := 'error insert NC_RESERVED: '||sqlerrm;
            end;               
            IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module save_step1</br>'||RST) ;
                return;      
            END IF;                    
        END LOOP;  -- end get detail Data        


        if vALC_RE = '1' then
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,0 ,0 ,vloss_Date ,vend_seq ,C2 );
        elsif vALC_RE = '2' then 
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        else
             v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        end if;   
        dbms_output.put_line('count CRI_RES: '||v_cnt_res);
        if v_cnt_res>0 then
            LOOP
               FETCH  C2 INTO j_rec2;
                EXIT WHEN C2%NOTFOUND;
                    v_rec := v_rec+1; 
                    
                    --v_shr_amt   := (v_tot_res* j_rec1.RI_SUM_SHR/100);                
                    if v_rec = v_cnt_res then
                       v_shr_amt := v_tot_res -  v_sum_res;
                    else
                        v_shr_amt   := (v_tot_res* j_rec2.RI_SUM_SHR/100);     
                    end if;
                    v_sum_res := v_sum_res +v_shr_amt;                

                    dbms_output.put_line('RI_CODE==>'|| 
                     j_rec2.ri_code||
                     ' RI_BR_CODE:'||
                      j_rec2.ri_br_code||
                     ' RI_SUM_SHR:'||
                      j_rec2.RI_SUM_SHR|| 
                     ' v_shr_amt:'||v_shr_amt
                    );   
                    
                   -- NC_HEALTH_PACKAGE.YOUR_POL(vpol_no, vpol_run, vrecpt_seq, 0, j_rec2.ri_code, j_rec2.RI_BR_CODE,
                   --    j_rec2.RI_SUB_TYPE, j_rec2.RI_TYPE, j_rec2.LF_FLAG, vLOSS_DATE, vYour_Pol);
                       
                    IF j_rec2.RI_TYPE = '1' THEN
                       IF  v_shr_amt < 50000 THEN
                          vLETT_PRT := 'N';
                       ELSE
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                       END IF;
                    ELSIF j_rec2.RI_TYPE = '0' THEN
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                    ELSE
                          vLETT_PRT := 'N';
                    END IF;                  
                    BEGIN
                      INSERT INTO NC_RI_RESERVED A
                       (
                        A.STS_KEY,  A.CLM_NO, A.PROD_GRP,  A.PROD_TYPE,A.TYPE,A.TRN_SEQ
                        ,A.RI_CODE, A.RI_BR_CODE, A.RI_STS_DATE, A.RI_AMD_DATE     
                        ,A.RI_TYPE, A.RI_RES_AMT ,A.RI_TRN_AMT,A.RI_SHARE          
                        ,A.LETT_NO, A.LETT_PRT, A.LETT_TYPE ,A.RI_LF_FLAG, A.RI_SUB_TYPE        
                        ,A.SUB_TYPE               
                        )
                      VALUES
                       (v_key ,vCLm_no ,vprod_grp ,vprod_type , j_rec2.RI_TYPE ,1,
                        j_rec2.RI_CODE, j_rec2.RI_BR_CODE, trunc(sysdate) , sysdate,
                        j_rec2.RI_TYPE, v_shr_amt , v_shr_amt ,j_rec2.RI_SUM_SHR, 
                        vLETT_NO ,vLETT_PRT, 'P',j_rec2.LF_FLAG,j_rec2.RI_SUB_TYPE
                        ,'NCNATSUBTYPECLM001'); 
                    EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('error insert CRI_RES: '||SQLERRM);
                        ROLLBACK;
                        RST := 'error insert CRI_RES: '||sqlerrm;
                    END;                               

              end loop;    
          end if;      
            IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                email_pack_error('Error From Package' , 'module save_step1</br>'||RST) ;
                return;      
            END IF;        
                                  
        COMMIT;
        
        IF RST is null THEN
            OPEN P_JOBNO FOR
            SELECT  v_key  STS_KEY ,'' NOTICE_NO ,vClm_no CLM_NO FROM DUAL;             
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RST := ' main error :'||sqlerrm;
           -- IF RST is not null THEN  -- error
                OPEN P_JOBNO FOR
                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module save_step1</br>'||RST) ;
                return;      
         --   END IF;                    
    END SAVE_UNNAME_CLAIM;  

    PROCEDURE UPDATE_UNNAME_CLAIM(P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2  ,
                            RST OUT VARCHAR2) IS
        TYPE t_data4 IS RECORD
        (
        STS_KEY  NUMBER,
        INVOICE    VARCHAR2(20),
        CLM_TYPE    VARCHAR2(3),
        POLICY_NO    VARCHAR2(50),
        FLEET_SEQ  NUMBER ,
        RECPT_SEQ  NUMBER ,
        NAME    VARCHAR2(200),
        SURNAME    VARCHAR2(200),
        HN    VARCHAR2(20),
        ICD10    VARCHAR2(20),
        CAUSE_CODE    VARCHAR2(20),
        RISK_DESC    VARCHAR2(200),
        LOSS_DATE    VARCHAR2(10), --dd/mm/rrrr
        FR_LOSS_DATE    VARCHAR2(10),
        TO_LOSS_DATE    VARCHAR2(10),
        HPT_CODE   VARCHAR2(20), 
        DAY   NUMBER,
        HPT_USER    VARCHAR2(10),
        REMARK      VARCHAR2(200),
        EVN_DESC    VARCHAR2(200),
        SUB_CAUSE_CODE VARCHAR2(10),
        GRP_SEQ NUMBER
        ); 
        j_rec4 t_data4;     
    
        TYPE t_data1 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        REQUEST_AMT  NUMBER,
        REMAIN_AMT NUMBER
        ); 
        j_rec1 t_data1;            
        
        C2   NC_HEALTH_PACKAGE.v_ref_cursor4;
        TYPE t_data2 IS RECORD
        (
        POL_NO  MIS_RI_MAS.POL_NO%TYPE ,
        POL_RUN MIS_RI_MAS.POL_RUN%TYPE ,
        RI_CODE MIS_RI_MAS.RI_CODE%TYPE ,
        RI_BR_CODE MIS_RI_MAS.RI_BR_CODE%TYPE ,
        RI_TYPE MIS_RI_MAS.RI_TYPE%TYPE ,
        LF_FLAG MIS_RI_MAS.LF_FLAG%TYPE ,
        RI_SUB_TYPE MIS_RI_MAS.RI_SUB_TYPE%TYPE ,
        --RI_SUM  MIS_RI_MAS.RI_SUM_INS%TYPE ,
        --RI_SUM  NUMBER(20,2),
        RI_SUM_SHR   NUMBER     
        ); 
        j_rec2 t_data2;      
                
        v_key   number;     
        v_cnt_res   number;      
        v_tot_res   number:= 0;           
        v_shr_amt   number(13,2);
        v_sum_res   number:=0;
        v_rec   number:=0;     
        v_logrst    varchar2(200);        
        
        vSTS_KEY NC_MAS.STS_KEY%TYPE ;
        vCLM_NO NC_MAS.CLM_NO%TYPE ;
        vREG_NO NC_MAS.REG_NO%TYPE ;
        vPOL_NO NC_MAS.POL_NO%TYPE ;
        vPOL_RUN NC_MAS.POL_RUN%TYPE ;
        vEND_SEQ NC_MAS.END_SEQ%TYPE := 0;
        vRECPT_SEQ NC_MAS.RECPT_SEQ%TYPE :=1;
        vALC_RE NC_MAS.ALC_RE%TYPE ;
        vCLM_YR NC_MAS.CLM_YR%TYPE ;
        vPOL_YR NC_MAS.POL_YR%TYPE ;
        vPROD_GRP NC_MAS.PROD_GRP%TYPE ;
        vPROD_TYPE     NC_MAS.PROD_TYPE%TYPE ;
        vINVOICE_NO NC_MAS.INVOICE_NO%TYPE ;
        vHN_NO NC_MAS.HN_NO%TYPE ;
        vHPT_CODE NC_MAS.HPT_CODE%TYPE ;
        vMAS_CUS_CODE NC_MAS.MAS_CUS_CODE%TYPE ;
        vMAS_CUS_SEQ NC_MAS.MAS_CUS_SEQ%TYPE ;
        vMAS_CUS_NAME NC_MAS.MAS_CUS_NAME%TYPE ;
        vCUS_CODE NC_MAS.CUS_CODE%TYPE ;
        vCUS_SEQ NC_MAS.CUS_SEQ%TYPE ;
        vCUS_NAME   NC_MAS.CUS_NAME%TYPE ;
        vFAX_CLM NC_MAS.FAX_CLM%TYPE ;
        vFAX_CLM_DATE NC_MAS.FAX_CLM_DATE%TYPE ;
        vREG_DATE NC_MAS.REG_DATE%TYPE ;
        vCLM_DATE NC_MAS.CLM_DATE%TYPE ;
        vLOSS_DATE NC_MAS.LOSS_DATE%TYPE ;
        vFR_DATE NC_MAS.FR_DATE%TYPE ;
        vTO_DATE NC_MAS.TO_DATE%TYPE ;
        vTR_DATE_FR NC_MAS.TR_DATE_FR%TYPE ;
        vTR_DATE_TO NC_MAS.TR_DATE_TO%TYPE ;
        vADD_TR_DAY NC_MAS.ADD_TR_DAY%TYPE ;
        vTOT_TR_DAY NC_MAS.TOT_TR_DAY%TYPE ;
        vLOSS_DETAIL NC_MAS.LOSS_DETAIL%TYPE ; 
        vIPD_FLAG NC_MAS.IPD_FLAG%TYPE ;
        vDIS_CODE NC_MAS.DIS_CODE%TYPE ;
        vCAUSE_CODE   NC_MAS.CAUSE_CODE%TYPE ;
        vFLEET_SEQ    NC_MAS.FLEET_SEQ%TYPE ;
        vRUN_FLEET_SEQ       NC_MAS.RUN_FLEET_SEQ%TYPE ;
        vMAS_SUM_INS   NC_MAS.MAS_SUM_INS%TYPE ;
        vCLM_USER   NC_MAS.CLM_USER%TYPE ;
        vRemark     NC_MAS.REMARK%TYPE ;
        vIDNO   NC_MAS.ID_NO%TYPE ;
        --vEvndesc    NC_MAS.EVN_DESC%TYPE ;
        vSub_Cause   NC_MAS.SUB_CAUSE_CODE%TYPE ;
        vGRP_SEQ    NC_MAS.GRP_SEQ%TYPE ;
        
        vYour_Pol   MIS_CRI_RES.YOUR_POL%TYPE;
        vLett_Prt   MIS_CRI_RES.LETT_PRT%TYPE;
        vLett_no   MIS_CRI_RES.LETT_NO%TYPE;
        
        vMax_Sts_seq    number(3);
        vMax_res_seq    number(3);
        vMax_ri_seq    number(3);
        vExist    varchar2(100);        
        v_RstHISTORY    varchar2(200); 
        x_clmuser   varchar2(10);        
        x_stsdate   date;
    BEGIN
        RST := null;
        LOOP  -- get Master Data
           FETCH  P_MASTER INTO j_rec4;
            EXIT WHEN P_MASTER%NOTFOUND;
            dbms_output.put_line('UPDATE UNNAME : Invoice==>'||  j_rec4.invoice||  ' ClmType:'||  j_rec4.clm_type|| ' Pol_no/Run:'||  j_rec4.policy_no|| ' LossDate:'||  j_rec4.loss_date); 
            
            if nvl(j_rec4.sts_key,0) = 0 then
            v_key := gen_stskey(''); -- สร้าง STS_KEY
            else 
            v_key := j_rec4.sts_key;             
            end if;
            
            begin
                select  nvl(max(sts_seq),1) into vMax_Sts_seq
                from nc_status
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_Sts_seq := 1;
                when others then
                    vMax_Sts_seq := 1;
            end;
            
            begin
                select  nvl(max(trn_seq),1) into vMax_res_seq
                from nc_reserved
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_res_seq := 1;
                when others then
                    vMax_res_seq := 1;
            end;            

            begin
                select  nvl(max(trn_seq),1) into vMax_ri_seq
                from nc_ri_reserved
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vMax_ri_seq := 1;
                when others then
                    vMax_ri_seq := 1;
            end;                  
            p_acc_package.read_pol(j_rec4.policy_no ,vPOL_NO ,vPOL_RUN);
          
            begin
                  SELECT POL_YR,  PROD_TYPE, prod_grp, to_char(sysdate,'rrrr') clm_yr ,
                         CUS_CODE, CUS_SEQ, substr(CUS_ENQ,1,90), ALC_RE ,SUM_INS ,END_SEQ
                  INTO
                         vPOL_YR, vPROD_TYPE, vprod_grp, vCLM_YR ,
                         vMAS_CUS_CODE, vMAS_CUS_SEQ, vMAS_CUS_NAME  , vALC_RE ,vMAS_SUM_INS ,vEND_SEQ
                    FROM MIS_MAS
                    WHERE POL_NO = vPOL_NO AND
                            nvl(pol_run,0) = vPOL_RUN and
                              END_SEQ = (SELECT MAX(END_SEQ) FROM MIS_MAS
                                         WHERE POL_NO =vPOL_NO AND 
                                               nvl(pol_run,0) = vPOL_RUN and
                                               (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE));                  
            exception
                when no_data_found then
                    RST :='UPDATE UNNAME : not found policy no :'||j_rec4.policy_no;
                when others then
                    RST :='UPDATE UNNAME : not found policy no :'||j_rec4.policy_no;
            end;
                                
            BEGIN
            SELECT MIN(FR_DATE),MAX(TO_DATE)
            INTO vFR_DATE,vTO_DATE
            FROM MIS_MAS
            WHERE POL_NO =vPOL_NO AND
                  nvl(pol_run,0) = to_number(vPOL_RUN) and
                  (to_date(j_rec4.loss_date,'dd/mm/rrrr') BETWEEN FR_DATE AND TO_DATE);
                                  
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
              null;
              WHEN OTHERS THEN null;
            END;       
            
            vRECPT_SEQ := 1;
            vCUS_CODE := '';
            vCUS_SEQ := null;
            vCUS_NAME := j_rec4.NAME||' '||j_rec4.SURNAME;        
                          
            vREG_DATE := trunc(sysdate);
            vCLM_DATE := trunc(sysdate);
            vHN_NO := j_rec4.HN;
--            vHPT_CODE := j_rec4.HPT_CODE;
            vHPT_CODE := nc_health_package.GET_BKI_HPTCODE(j_rec4.HPT_CODE);
            vCAUSE_CODE := j_rec4.CAUSE_CODE; 
            vDIS_CODE :=  j_rec4.ICD10; 
            vIPD_FLAG :=  j_rec4.CLM_TYPE; 
            vLOSS_DETAIL := j_rec4.RISK_DESC ;
            vFLEET_SEQ := j_rec4.FLEET_SEQ;
            --vRECPT_SEQ := j_rec4.RECPT_SEQ; -- รับ recpt โดยตรงจาก web med เลย
            vINVOICE_NO :=  j_rec4.INVOICE;
            vLOSS_DATE := to_date(j_rec4.LOSS_DATE,'dd/mm/rrrr'); 
            vCLM_USER := j_rec4.HPT_USER;   
            vTR_DATE_FR :=  to_date(j_rec4.FR_LOSS_DATE,'dd/mm/rrrr'); 
            vTR_DATE_TO :=  to_date(j_rec4.TO_LOSS_DATE,'dd/mm/rrrr'); 
            vTOT_TR_DAY := j_rec4.DAY;   
            vRemark := j_rec4.Remark;   -- เก็บ free text สถานพยาบาล 
            --vEvndesc := j_rec4.Evn_desc;
            vSub_Cause := j_rec4.SUB_CAUSE_CODE ;
            vGRP_SEQ    := j_rec4.GRP_SEQ;
            
            IF vDIS_CODE is null THEN  -- กรณีไม่ระบุ icd จะนำ free text มาบันทึกแทน
                vLOSS_DETAIL := j_rec4.Evn_desc;
            END IF;
            
           begin
                select  'ex' ,clm_no 
                into  vExist ,vClm_no
                from nc_mas
                where sts_key = v_key;            
            exception
                when no_data_found then
                    vExist :=null ;
                when others then
                    vExist :=null ;
            end;            
            dbms_output.put_line('key:'||v_key||' Exist: '||vExist);
            if vExist is  null then -- รายการนี้ยังไม่เคยบันทึกเคลม 
                RST := 'UPDATE UNNAME : รายการนี้ยังไม่เคยบันทึกเคลม !'; 
            else
            
                begin
                    select  clm_user ,sts_date
                    into  x_clmuser ,x_stsdate
                    from nc_reserved
                    where sts_key = v_key and trn_seq = 1 and rownum=1 ;            
                exception
                    when no_data_found then
                        x_clmuser :=null ;
                    when others then
                        x_clmuser :=null ;
                end;   
                --*** ลง History NC_MAS ***
                NC_HEALTH_PACKAGE.SAVE_NCMAS_HISTORY(v_key , v_RstHISTORY);
                
                if v_RstHISTORY is not null then
                    dbms_output.put_line('v_RstHISTORY: '||v_RstHISTORY);
                    NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,v_RstHISTORY ,v_logrst);
                end if;
                dbms_output.put_line('pass insert History');
                begin 
                    update nc_mas 
                    set 
                     loss_Date = vloss_Date
                     ,tr_date_fr =vtr_date_fr  ,tr_date_to =vtr_date_to , ADD_TR_DAY =vADD_TR_DAY ,tot_tr_daY =vtot_tr_daY
                     ,loss_detail =vloss_detail , ipd_flag =vipd_flag ,dis_code =vdis_code ,cause_code =vcause_code 
                     ,clm_user =vCLM_USER ,remark =vRemark     ,SUB_CAUSE_CODE = vSub_Cause ,GRP_SEQ =  vGRP_SEQ      
                     ,invoice_no = vINVOICE_NO ,hn_no =    vHN_NO         , HPT_CODE = vHPT_CODE
                    where sts_key = v_key;
                exception
                    when others then
                        dbms_output.put_line('error update NC_MAS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'UPDATE UNNAME : error update NC_MAS: '||sqlerrm;
                end;      
                dbms_output.put_line('pass update NC_MAS');        
            end if;
                
            IF RST is not null THEN  -- error
                email_pack_error('Error From Package' , 'module UPDATE UNNAME : </br>'||RST) ;
                return;      
            END IF;             
            
                begin 
                    insert into nc_status 
                    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
                    values     
                    (  v_key ,vMax_Sts_seq+1 ,'MEDSTS','MEDSTS11' ,'edit UNNAME Claim Data ' ,vCLM_USER , sysdate        
                    );
                exception
                    when others then
                        dbms_output.put_line('error insert NC_STATUS: '||sqlerrm);
                        ROLLBACK;
                        RST := 'UPDATE UNNAME : error insert NC_STATUS: '||sqlerrm;
                end;     
            dbms_output.put_line('pass insert NC_STATUS');        
            IF RST is not null THEN  -- error
                email_pack_error('Error From Package' , 'module UPDATE UNNAME : </br>'||RST) ;
                return;      
            END IF;                    
                                        
        END LOOP;  -- end get Master Data

        LOOP  -- get detail Data
           FETCH  P_DTL INTO j_rec1;
            EXIT WHEN P_DTL%NOTFOUND;
            dbms_output.put_line('Prem==>'||  j_rec1.PREMCODE||  ' RequestAmt:'||  j_rec1.request_amt|| ' ResAmt:'||  j_rec1.REMAIN_AMT); 
            v_tot_res := v_tot_res +  j_rec1.REMAIN_AMT;
            BEGIN
            insert into nc_reserved (
            sts_key ,clm_no ,prod_grp ,prod_type ,type ,sub_type ,trn_seq ,amd_date 
            ,prem_code ,prem_seq ,req_amt ,res_amt ,disc_amt ,trn_amt ,amd_user           
            ,sts_date ,clm_user 
            ) values (
            v_key ,vClm_no ,vprod_grp ,vprod_type ,'1' ,'01' ,vMax_res_seq+1 ,trunc(sysdate)
            , j_rec1.PREMCODE , 1 , j_rec1.request_amt ,j_rec1.REMAIN_AMT ,0 ,j_rec1.REMAIN_AMT ,vCLM_USER
            ,x_stsdate , x_clmuser 
            ) ;
            exception
                when others then
                    dbms_output.put_line('error insert NC_RESERVED: '||sqlerrm);
                    ROLLBACK;
                    RST := 'UPDATE UNNAME : error insert NC_RESERVED: '||sqlerrm;
            end;               
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module UPDATE UNNAME : </br>'||RST) ;
                return;      
            END IF;                    
        END LOOP;  -- end get detail Data        

        if vALC_RE = '1' then
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,0 ,0 ,vloss_Date ,vend_seq ,C2 );
        elsif vALC_RE = '2' then 
            v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        else
             v_cnt_res := NC_HEALTH_PACKAGE.GET_RI_RES(vpol_no ,vpol_run ,vrecpt_seq ,0 ,vloss_Date ,vend_seq ,C2 );
        end if;   
        dbms_output.put_line('count CRI_RES: '||v_cnt_res);
        if v_cnt_res>0 then
            LOOP
               FETCH  C2 INTO j_rec2;
                EXIT WHEN C2%NOTFOUND;
                    v_rec := v_rec+1; 
                    
                    --v_shr_amt   := (v_tot_res* j_rec1.RI_SUM_SHR/100);                
                    if v_rec = v_cnt_res then
                       v_shr_amt := v_tot_res -  v_sum_res;
                    else
                        v_shr_amt   := (v_tot_res* j_rec2.RI_SUM_SHR/100);     
                    end if;
                    v_sum_res := v_sum_res +v_shr_amt;                

                    dbms_output.put_line('RI_CODE==>'|| 
                     j_rec2.ri_code||
                     ' RI_BR_CODE:'||
                      j_rec2.ri_br_code||
                     ' RI_SUM_SHR:'||
                      j_rec2.RI_SUM_SHR|| 
                     ' v_shr_amt:'||v_shr_amt
                    );   
                    
                   -- NC_HEALTH_PACKAGE.YOUR_POL(vpol_no, vpol_run, vrecpt_seq, 0, j_rec2.ri_code, j_rec2.RI_BR_CODE,
                   --    j_rec2.RI_SUB_TYPE, j_rec2.RI_TYPE, j_rec2.LF_FLAG, vLOSS_DATE, vYour_Pol);
                       
                    IF j_rec2.RI_TYPE = '1' THEN
                       IF  v_shr_amt < 50000 THEN
                          vLETT_PRT := 'N';
                       ELSE
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                       END IF;
                    ELSIF j_rec2.RI_TYPE = '0' THEN
                          vLETT_PRT := 'Y';
                          vLett_no := NC_HEALTH_PACKAGE.GEN_LETTNO(vProd_type);
                    ELSE
                          vLETT_PRT := 'N';
                    END IF;                  
                    BEGIN
                      INSERT INTO NC_RI_RESERVED A
                       (
                        A.STS_KEY,  A.CLM_NO, A.PROD_GRP,  A.PROD_TYPE,A.TYPE,A.TRN_SEQ
                        ,A.RI_CODE, A.RI_BR_CODE, A.RI_STS_DATE, A.RI_AMD_DATE     
                        ,A.RI_TYPE, A.RI_RES_AMT ,A.RI_TRN_AMT,A.RI_SHARE          
                        ,A.LETT_NO, A.LETT_PRT, A.LETT_TYPE ,A.RI_LF_FLAG, A.RI_SUB_TYPE
                        ,A.SUB_TYPE                      
                        )
                      VALUES
                       (v_key ,vCLm_no ,vprod_grp ,vprod_type , j_rec2.RI_TYPE ,vMax_res_seq+1,
                        j_rec2.RI_CODE, j_rec2.RI_BR_CODE, trunc(sysdate) , sysdate,
                        j_rec2.RI_TYPE, v_shr_amt , v_shr_amt ,j_rec2.RI_SUM_SHR, 
                        vLETT_NO ,vLETT_PRT, 'P',j_rec2.LF_FLAG,j_rec2.RI_SUB_TYPE
                        ,'NCNATSUBTYPECLM001' ); 
                    EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('error insert CRI_RES: '||SQLERRM);
                        ROLLBACK;
                        RST := 'UPDATE UNNAME : error insert CRI_RES: '||sqlerrm;
                    END;                               

              end loop;    
          end if;      
            IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);
                email_pack_error('Error From Package' , 'module UPDATE UNNAME : </br>'||RST) ;
                return;      
            END IF;        
                                  
        COMMIT;
        
--        IF RST is null THEN
--            OPEN P_JOBNO FOR
--            SELECT  v_key  STS_KEY ,'' NOTICE_NO ,vClm_no CLM_NO FROM DUAL;             
--        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RST := 'UPDATE UNNAME :  main error :'||sqlerrm;
           -- IF RST is not null THEN  -- error
--                OPEN P_JOBNO FOR
--                SELECT 1 STS_KEY ,'' NOTICE_NO ,'' CLM_NO FROM DUAL;      
                --NC_HEALTH_PACKAGE.WRITE_LOG('DB' ,'DB Package' ,RST ,v_logrst);
                --p_acc_package.SEND_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com', core_ldap.GET_EMAIL_FUNC('3055')||';'||core_ldap.GET_EMAIL_FUNC('2702'),'Error From Package', RST ,null,null);                
                email_pack_error('Error From Package' , 'module UPDATE UNNAME : </br>'||RST) ;
                return;      
         --   END IF;                    
    END UPDATE_UNNAME_CLAIM;    -- END    UPDATE_UNNAME_CLAIM     
    

    FUNCTION GET_LIST_DATE_TYPE(P_ORDERBY_LIST OUT v_ref_cursor4 ) RETURN VARCHAR2 is  -- 0 Complete , 5 Error or not found
    BEGIN
           OPEN P_ORDERBY_LIST  FOR 
            select '--เลือก--' NAME, null VALUE , 0 SEQ  from dual 
            union 
            select 'วันที่เกิดเหตุ' NAME, 'A.LOSS_DATE' VALUE , 1 SEQ from dual 
            union 
            select 'วันที่รักษา' NAME, 'TR_DATE_FR' VALUE , 2 SEQ from dual 
            union
            select 'วันที่เปิดเคลม' NAME, 'REG_DATE' VALUE , 3 SEQ from dual 
            union 
            select 'วันที่วางบิล' NAME, 'NC_HEALTH_PACKAGE.GET_BILLDATE(a.clm_no)' VALUE , 4 SEQ from dual 
            union 
            select 'วันที่แจ้งโอนเงิน/ส่งเช็ค' NAME, 'NC_HEALTH_PACKAGE.GET_ACR_PAIDDATE(a.clm_no)' VALUE, 5 SEQ from dual 
            order by seq;   
                
            return '0';       
             CLOSE P_ORDERBY_LIST; 
    EXCEPTION
           when no_data_found then 
            OPEN P_ORDERBY_LIST  FOR select '--เลือก--' NAME, null VALUE FROM DUAL;
            return '5';           
            CLOSE P_ORDERBY_LIST;        
           when others then 
            OPEN P_ORDERBY_LIST  FOR select '--เลือก--' NAME, null VALUE FROM DUAL;
            return '5';  
            CLOSE P_ORDERBY_LIST;                        
    END GET_LIST_DATE_TYPE;
    
    FUNCTION IS_DISALLOW_POLICY(P_Pol_no IN VARCHAR2 ,P_Pol_run IN NUMBER) RETURN BOOLEAN IS -- true = disallow ,error , fasle = allow
        v_prod_type VARCHAR2(5);
        v_prod_type2 VARCHAR2(5);
        v_pol   VARCHAR2(30);
    BEGIN
        begin
            select prod_type 
            into v_prod_type
            from mis_mas
            where pol_no = P_Pol_no
            and pol_run = P_Pol_run and prod_type is not null and rownum=1;
        exception
            when no_data_found then
                v_prod_type := null;
                return true;
            when others then
                v_prod_type := null;
                return true;
        end;
        
        begin
            select remark 
            into v_prod_type2
            from clm_constant a
            where key like 'MED_DISALLOW_POL%'
            and remark = v_prod_type;
        exception
            when no_data_found then
                v_prod_type2 := null;
                return false;
            when others then
                v_prod_type2 := null;
                return true;
        end;        
        
        return true;      
        
    END IS_DISALLOW_POLICY;

    FUNCTION IS_WATCHLIST_POLICY(P_Pol_no IN VARCHAR2 ,P_Pol_run IN NUMBER) RETURN BOOLEAN IS -- true = disallow ,error , fasle = allow
        v_prod_type VARCHAR2(5);
        v_prod_type2 VARCHAR2(5);
        v_pol   VARCHAR2(30);
    BEGIN

        begin
            select remark 
            into v_pol
            from clm_constant a
            where key like 'MEDWATCH%'
            and remark = P_Pol_no||P_Pol_run;
            if v_pol is not null then return true; end if;
        exception
            when no_data_found then
                return false;
            when others then
                return true;
        end; 

        return true;      
        
    END IS_WATCHLIST_POLICY;
        
    PROCEDURE GET_MED_REMARK(i_pol_no in varchar2 ,i_pol_run in number ,i_fleet_seq in number ,o_remark out varchar2) IS
        v_remark varchar2(500);
        tSts1 varchar2(200):=null;
        TYPE t_data2 IS RECORD
        (
        PREMCODE    VARCHAR2(10),
        SUMINS  NUMBER,
        PREMCOL NUMBER
        ); 
        j_rec2 t_data2;  
        c2   NC_HEALTH_PACKAGE.v_ref_cursor1;                  
        x_chkmotor boolean:=false;
        x_chkaccum boolean:=false;
        v_fleet number; 
        x_curr  varchar2(100);
    BEGIN
        
        begin
            select curr_code into x_curr
            from mis_mas a
            where  pol_no = i_pol_no and pol_run =i_pol_run
            and end_seq in (select max(aa.end_seq) from mis_mas aa where aa.pol_no = a.pol_no and aa.pol_run = a.pol_run);
        exception
            when no_data_found then
                x_curr := null;
            when others then
                x_curr := null;
        end;              
        
        if x_curr = 'USD' then
            x_curr := '*** กรมธรรม์นี้ต้องบันทึกยอดจ่ายเป็นสกุลเงิน USD ***'||chr(10);
        else
            x_curr := null;
        end if;
        
        o_remark := x_curr;   
         
        NC_HEALTH_PACKAGE.GET_COVER_PA (i_pol_no,i_pol_run,i_fleet_seq, null ,
                                          c2 ,tSts1 );   
                                          
        if tSts1 is null then
            x_chkmotor := false;     
            LOOP
               FETCH  c2 INTO j_rec2;
                EXIT WHEN c2%NOTFOUND;
                    --if  not nc_health_package.IS_CHECK_TOTLOSS(j_rec2.premcode) then  -- hide TOTLOSS Prem_code
                    if IS_CHECK_MOTORCYCLE(j_rec2.premcode) then
                        x_chkmotor := true;                                                 
                    end if;
                    if IS_CHECK_ACCUM(j_rec2.premcode) then
                        x_chkaccum := true;                                                 
                    end if;                    
            END LOOP;  
                            
            IF x_chkmotor THEN
                o_remark := o_remark||'- คุ้มครองอุบัติเหตุจากมอเตอร์ไซค์';
            ELSE
                o_remark := o_remark||'- ไม่คุ้มครองอุบัติเหตุจากมอเตอร์ไซค์';
            END IF;
        else
            o_remark := null ;
        end if;  
        
--        nc_health_package.get_mc_remark(i_pol_no,i_pol_run,i_fleet_seq,o_remark);
        if  x_chkaccum then
            o_remark := o_remark||chr(10);         
        else
            o_remark := '';         
        end if;
                               
        if misc.healthutil.is_45plus(i_pol_no,i_pol_run) then
          v_remark := misc.healthutil.get_benefit_card_45plus(i_pol_no ,
                                                         i_pol_run,
                                                         i_fleet_seq,
                                                         1);
        o_remark := o_remark||' '||replace(v_remark ,'<br />' ,null)  ;                                                
        else 
          o_remark := o_remark;
        end if;
    END GET_MED_REMARK;    
END;
/

