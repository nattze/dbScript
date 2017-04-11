CREATE OR REPLACE PACKAGE BODY RVP_CLAIM_PACKAGE AS
 
PROCEDURE 
REQUEST_POLICY(i_searchno IN VARCHAR2 ,i_logid IN VARCHAR2 ,o_rst OUT VARCHAR2) IS 
-- === o_rst = null คือสำเร็จ 
 v_policyno varchar2(50);
 v_idcard varchar2(30);
 v_prefix varchar2(30);
 v_fname varchar2(50);
 v_lname varchar2(50);
 v_accdate date;
 
 chk_dup_req varchar2(50); -- find from Response Table
BEGIN
 begin
 SELECT A.POLICYNO,A.IDCARD,A.PREFIX, A.FNAME, A.LNAME, to_date(A.ACCDATE ,'yyyy/mm/dd')
 INTO v_policyno ,v_idcard ,v_prefix ,v_fname ,v_lname ,v_accdate
 FROM RVP_ENQ_REQ A
 WHERE SEARCHNO = i_searchno and LogID = i_logid ;
 
 IF v_policyno is null and v_idcard is null and v_prefix is null and v_fname is null and v_lname is null and v_accdate is null THEN
 -- not found seach criteria --
 INSERT_BLANK_RESPONSE(i_searchno ,i_logid ,'FALSE' ,'9001' ,'Not found Search Criteria!');
 ELSE
 begin
 select searchno into chk_dup_req
 from rvp_enq_rep
 where searchno = i_searchno and logid = i_logid ;
 
 if chk_dup_req is not null then -- มีการร้องขอซ้ำ
 --INSERT_BLANK_RESPONSE(i_searchno ,i_logid ,'FALSE' ,'9001' ,'Dupplicate SearchNo and LogId!');
 o_rst := 'Dupplicate SearchNo and LogId!' ; 
 
 return;
 end if; 
 exception
 when no_data_found then 
 null;
 when others then
 null;
 end; 
 --=== Validate Criteria ===-
 if v_accdate is null then
 INSERT_BLANK_RESPONSE(i_searchno ,i_logid ,'FALSE' ,'8001' ,'Please identify Accident Date for enquiry!');
 else
 if v_policyno is null and v_idcard is null and v_fname is null and v_lname is null then
 INSERT_BLANK_RESPONSE(i_searchno ,i_logid ,'FALSE' ,'8001' ,'have hot enough criteria for enquiry!'); 
 end if;
 end if;
 --===End Validate Criteria ===-
 
 
 -- go to Search Policy and Coverage
 GET_POLICY_COVERAGE2(i_searchno ,i_logid ,
 v_policyno ,v_idcard ,v_prefix ,v_fname ,v_lname ,
 v_accdate ,o_rst) ;
 if o_rst is not null then
 INSERT_BLANK_RESPONSE(i_searchno ,i_logid ,'FALSE' ,'' ,'no search result');
 o_rst := null;
 end if;
 END IF;
 
-- dbms_output.put_line('acc date = '||v_accdate);
 exception
 when no_data_found then
 o_rst := 'not found searchno: '||i_searchno||' logid: '||i_logid;
 dbms_output.put_line('not found searchno: '||i_searchno||' logid: '||i_logid);
-- INSERT_BLANK_RESPONSE(i_searchno ,i_logid);
 return;
 when others then
 dbms_output.put_line('error'||sqlerrm);
 o_rst := 'error main :'||sqlerrm;
-- INSERT_BLANK_RESPONSE(i_searchno ,i_logid);
 return;
 end; 
EXCEPTION
 WHEN OTHERS THEN
 o_rst := 'error main :'||sqlerrm;
-- INSERT_BLANK_RESPONSE(i_searchno ,i_logid);
 return;
END REQUEST_POLICY;

PROCEDURE GET_RVP_ENQ(i_searchno IN VARCHAR2 ,i_logid IN VARCHAR2,
 out_rvp_enq_rep OUT sys_refcursor,out_rvp_enq_rep_policy OUT sys_refcursor,out_rvp_enq_rep_benefit OUT sys_refcursor) is
 w_message varchar2(20);
BEGIN
 BEGIN
 OPEN out_rvp_enq_rep For
 SELECT ACCDATE, ADMISSIONDATE, CARDTYPE, CODE, DESCR, FNAME, HOSPITALID, HOSPITALNAME, IDCARD, INSURERID, INSURERNAME, 
 LNAME, LOGID, PATIENTTYPE, POLICYNO, PREFIX, REF1, REF2, RESPONSEDATE, SEARCHNO, SUBPOLICY1, SUBPOLICY2, SUCCESS, TREATMENTTYPE
 FROM RVP_ENQ_REP
 WHERE SEARCHNO =i_searchno
 AND LOGID = i_logid;
 EXCEPTION
 WHEN OTHERS THEN
 w_message := 'ERROR RVP_ENQ_REP :'||sqlerrm;
 END;
 
 BEGIN
 OPEN out_rvp_enq_rep_policy For
 SELECT AMOUNT, BALANCE, CARDTYPE, ENDDATE, EXCLUSION, FNAME, IDCARD, LNAME, LOGID, PLANDESCRIPTION, PLANID, POLICYNO, 
 POLICYSTATUS, POLICYSTATUSDESC, PREFIX, SEARCHNO, STARTDATE, SUBPOLICY1, SUBPOLICY2
 FROM RVP_ENQ_REP_POLICY
 WHERE SEARCHNO =i_searchno
 AND LOGID = i_logid;
 EXCEPTION
 WHEN OTHERS THEN
 w_message := 'ERROR RVP_ENQ_POLICY :'||sqlerrm;
 END;
 
 BEGIN
 OPEN out_rvp_enq_rep_benefit For 
 SELECT AMOUNT, BALANCE, ITEMCODE, ITEMDETAIL, ITEMNO, LOGID, POLICYNO, SEARCHNO
 FROM RVP_ENQ_REP_BENEFIT
 WHERE SEARCHNO =i_searchno
 AND LOGID = i_logid;
 EXCEPTION
 WHEN OTHERS THEN
 w_message := 'ERROR RVP_ENQ_REP_BENEFIT'||sqlerrm;
 END;
 EXCEPTION 
 WHEN OTHERS THEN 
 OPEN out_rvp_enq_rep For 
 SELECT NULL ACCDATE, NULL ADMISSIONDATE, NULL CARDTYPE, NULL CODE, NULL DESCR, NULL FNAME, NULL HOSPITALID, NULL HOSPITALNAME, NULL IDCARD, NULL INSURERID, NULL INSURERNAME, 
 NULL LNAME, NULL LOGID, NULL PATIENTTYPE, NULL POLICYNO,NULL PREFIX, NULL REF1, NULL REF2, NULL RESPONSEDATE, NULL SEARCHNO, NULL SUBPOLICY1, NULL SUBPOLICY2, NULL SUCCESS, NULL TREATMENTTYPE 
 from dual; 
 OPEN out_rvp_enq_rep_policy For
 SELECT NULL AMOUNT,NULL BALANCE,NULL CARDTYPE,NULL ENDDATE,NULL EXCLUSION,NULL FNAME,NULL IDCARD,NULL LNAME,NULL LOGID,NULL PLANDESCRIPTION,NULL PLANID,NULL POLICYNO, 
 NULL POLICYSTATUS,NULL POLICYSTATUSDESC,NULL PREFIX,NULL SEARCHNO,NULL STARTDATE,NULL SUBPOLICY1,NULL SUBPOLICY2 
 from dual; 
 OPEN out_rvp_enq_rep_benefit For 
 SELECT NULL AMOUNT,NULL BALANCE,NULL ITEMCODE,NULL ITEMDETAIL,NULL ITEMNO,NULL LOGID,NULL POLICYNO,NULL SEARCHNO
 from dual; 
END GET_RVP_ENQ;

PROCEDURE R_INSET_RVP_ENQ_REQ 
 (SearchNo IN varchar2, 
 LogId IN varchar2,
 InsurerID IN varchar2, 
 InsurerName IN varchar2,
 HospitalID IN varchar2,
 HospitalName IN varchar2,
 PolicyNo IN varchar2,
 SubPolicy1 IN varchar2,
 SubPolicy2 IN varchar2,
 IDCard IN varchar2,
 CardType IN varchar2,
 Prefix IN varchar2,
 Fname IN varchar2,
 Lname IN varchar2,
 PatientType IN varchar2,
 TreatmentType IN varchar2,
 AccDate IN varchar2,
 AdmissionDate IN varchar2,
 REF1 IN varchar2,
 REF2 IN varchar2 ) IS
 w_message varchar2(20);
BEGIN
 INSERT INTO RVP_ENQ_REQ(ACCDATE, ADMISSIONDATE, CARDTYPE, FNAME, HOSPITALID, HOSPITALNAME, IDCARD, INSURERID, INSURERNAME, LNAME, LOGID, PATIENTTYPE, POLICYNO, PREFIX, REF1, REF2, REQUESTDATE, SEARCHNO, SUBPOLICY1, SUBPOLICY2, TREATMENTTYPE) 
 VALUES(AccDate, AdmissionDate, CardType, Fname, HospitalID, HospitalName, IDCard, InsurerID, InsurerName, Lname, LogId, PatientType, PolicyNo, Prefix, REF1, REF2,SYSDATE, SearchNo, SubPolicy1, SubPolicy2, TreatmentType);
 COMMIT;
EXCEPTION
WHEN OTHERS THEN
 w_message := 'ERROR INSERT RVP_ENQ_REQ :'||sqlerrm;
 ROLLBACK;
END R_INSET_RVP_ENQ_REQ;

PROCEDURE INSERT_BLANK_RESPONSE(i_searchno IN VARCHAR2 ,i_logid IN VARCHAR2 ,i_return IN VARCHAR2 ,i_err IN VARCHAR2 ,i_err_desc IN VARCHAR2) IS
 v_insurerid varchar2(10);
 v_insurername varchar2(100);
 v_hospitalid varchar2(10);
 v_hospitalname varchar2(150);
 v_policyno varchar2(50); 
 v_idcard varchar2(20); 
 v_cardtype varchar2(5); 
 v_prefix varchar2(20); 
 v_fname varchar2(150); 
 v_lname varchar2(150); 
 v_patienttype varchar2(10); 
 v_accdate varchar2(10); 
 v_treatmenttype varchar2(10); 
BEGIN

 begin
 SELECT INSURERID ,INSURERNAME ,HOSPITALID ,HOSPITALNAME , POLICYNO, IDCARD, CARDTYPE, PREFIX, FNAME, LNAME, PATIENTTYPE, ACCDATE,TREATMENTTYPE
 INTO v_insurerid ,v_insurername ,v_hospitalid ,v_hospitalname ,v_policyno ,v_idcard ,v_cardtype ,v_prefix ,v_fname ,v_lname ,v_patienttype ,v_accdate,v_treatmenttype
 FROM RVP_ENQ_REQ A
 WHERE SEARCHNO = i_searchno and LogID = i_logid and rownum=1;
 exception
 when no_data_found then
 null ;
 when others then
 null;
 end; 
 
 Insert into ALLCLM.RVP_ENQ_REP
 (SEARCHNO, LOGID, INSURERID, INSURERNAME, HOSPITALID, HOSPITALNAME
 , POLICYNO, IDCARD, CARDTYPE, PREFIX, FNAME, LNAME, PATIENTTYPE, ACCDATE
 , SUCCESS ,CODE ,DESCR ,RESPONSEDATE ,TREATMENTTYPE )
 Values
 (i_searchno, i_logid, v_insurerid , v_insurername , v_hospitalid , v_hospitalname
 , v_policyno ,v_idcard ,v_cardtype ,v_prefix ,v_fname ,v_lname ,v_patienttype ,v_accdate
 , i_return ,i_err ,i_err_desc ,sysdate,v_treatmenttype);
 COMMIT;
EXCEPTION
WHEN OTHERS THEN
 ROLLBACK;
END INSERT_BLANK_RESPONSE;

PROCEDURE GET_POLICY_COVERAGE(i_searchno IN VARCHAR2 ,i_logid IN VARCHAR2,
i_policyno IN VARCHAR2 ,i_idcard IN VARCHAR2 ,i_prefix IN VARCHAR2 ,i_fname IN VARCHAR2 ,i_lname IN VARCHAR2 ,
i_accdate IN DATE ,o_rst OUT VARCHAR2) IS
 select_str VARCHAR2(30000); 
 query_str VARCHAR2(10000);
 t_cond VARCHAR2(10000); 
 t_order VARCHAR2(10000); 
 dumm NUMBER:=1; 
 
 P_ROW_CLM_DATA ALLCLM.RVP_CLAIM_PACKAGE.v_ref_cursor1; 

 TYPE t_data1 IS RECORD
 (
 SEARCHNO VARCHAR2(36 BYTE),
 LOGID VARCHAR2(3 BYTE),
 POLICYNO VARCHAR2(50 BYTE),
 SUBPOLICY1 VARCHAR2(50 BYTE),
 SUBPOLICY2 VARCHAR2(50 BYTE),
 STARTDATE VARCHAR2(10 BYTE),
 ENDDATE VARCHAR2(10 BYTE),
 IDCARD VARCHAR2(30 BYTE),
 CARDTYPE VARCHAR2(1 BYTE),
 PREFIX VARCHAR2(10 BYTE),
 FNAME VARCHAR2(50 BYTE),
 LNAME VARCHAR2(50 BYTE),
 AMOUNT NUMBER(8,2),
 BALANCE NUMBER(8,2),
 PLANID VARCHAR2(50 BYTE),
 PLANDESCRIPTION VARCHAR2(255 BYTE),
 EXCLUSION VARCHAR2(500 BYTE),
 POLICYSTATUS VARCHAR2(1 BYTE),
 POLICYSTATUSDESC VARCHAR2(500 BYTE)
 ); 
 j_rec1 t_data1; 
 
-- TYPE t_data2 IS RECORD(
-- SEARCHNO VARCHAR2(36 BYTE),
-- LOGID VARCHAR2(3 BYTE),
-- POLICYNO VARCHAR2(50 BYTE),
-- ITEMNO VARCHAR2(2 BYTE),
-- ITEMCODE VARCHAR2(5 BYTE),
-- ITEMDETAIL VARCHAR2(500 BYTE),
-- AMOUNT NUMBER(8,2),
-- BALANCE NUMBER(8,2)
-- );
-- 

 cnt_pol number:=0;
 cnt_ben number:=0;
BEGIN
 -- for dummy test connection 

 select_str := 'select a.searchno ,a.logid ,a.policyno,a.subpolicy1,a.subpolicy2,a.startdate,a.enddate,a.idcard,a.cardtype,a.prefix,a.fname,a.lname,a.amount,a.balance,a.planid,a.plandescription,a.exclusion,a.policystatus,a.policystatusdesc ' 
 ||' from rvp_enq_rep_policy a where rownum=:dumm '
 ;
 t_cond := '';
 t_order := '';
 
 --=== SEARCH ===--
 if i_policyno is not null then
 t_cond := t_cond || ' and a.policyno = '''||i_policyno||''' ';
 end if;

 if i_idcard is not null then
 t_cond := t_cond || ' and a.idcard = '''||i_idcard||''' ';
 end if;

 if i_prefix is not null then
 t_cond := t_cond || ' and a.prefix = '''||i_prefix||''' ';
 end if;

 if i_fname is not null then
        t_cond := t_cond || ' and a.fname = '''||i_fname||''' ';
    end if;

    if i_lname is not null then
        t_cond := t_cond || ' and a.lname = '''||i_lname||''' ';
    end if;

    if i_accdate is not null then
        t_cond := t_cond || ' and a.accdate = '''||i_accdate||''' ';
    end if;    
                        
    query_str := select_str||t_cond||t_order;
    dbms_output.put_line('sql1 :'||select_str);
    dbms_output.put_line('sql2 :'||t_cond);
    dbms_output.put_line('sql3 :'||t_order);
    OPEN P_ROW_CLM_DATA FOR query_str USING dumm;

    LOOP
       FETCH  P_ROW_CLM_DATA INTO j_rec1;
        EXIT WHEN P_ROW_CLM_DATA%NOTFOUND;
            dbms_output.put_line('Policy==>'||  j_rec1.policyno||  ' Name:'||  j_rec1.fname );  
            cnt_pol := cnt_pol+1;

            for r1 in (select INSURERID, INSURERNAME, HOSPITALID, HOSPITALNAME, POLICYNO, IDCARD, CARDTYPE, PREFIX, FNAME, LNAME, PATIENTTYPE, ACCDATE
                from rvp_enq_req  a
                where searchno = i_searchno and logid = i_logid 
            ) loop
                BEGIN
                    Insert into RVP_ENQ_REP
                       (SEARCHNO, LOGID, INSURERID, INSURERNAME, HOSPITALID, HOSPITALNAME, POLICYNO, IDCARD, CARDTYPE, PREFIX, FNAME, LNAME, PATIENTTYPE, ACCDATE, SUCCESS, CODE, DESCR ,RESPONSEDATE)
                     Values
                       (i_searchno, i_logid, r1.insurerid, r1.insurername, r1.hospitalid, r1.hospitalname, r1.policyno, r1.idcard, r1.cardtype, r1.prefix, r1.fname, r1.lname, r1.patienttype, r1.accdate, 
                       'TRUE', '', '' ,sysdate);            
                EXCEPTION
                WHEN OTHERS THEN
                    o_rst := 'error insert RVP_ENQ_REP :'||sqlerrm;
                    ROLLBACK;
                    return;
                END;                
            end loop;

            BEGIN
                Insert into ALLCLM.RVP_ENQ_REP_POLICY
                   (SEARCHNO, LOGID, POLICYNO, STARTDATE, ENDDATE, IDCARD, CARDTYPE, PREFIX, FNAME, LNAME, AMOUNT, BALANCE, POLICYSTATUS, POLICYSTATUSDESC)
                 Values
                   (i_searchno ,i_logid ,j_rec1.policyno , 
                    j_rec1.startdate, j_rec1.enddate, j_rec1.idcard, j_rec1.cardtype, j_rec1.prefix, j_rec1.fname, j_rec1.lname, 
                    j_rec1.amount, j_rec1.balance, j_rec1.policystatus, j_rec1.policystatusdesc); 
            EXCEPTION
            WHEN OTHERS THEN
                o_rst := 'error insert policy :'||sqlerrm;
                ROLLBACK;
                return;
            END;    
                            
            for b1 in (select itemno ,itemcode ,itemdetail ,amount ,balance
                from rvp_enq_rep_benefit  a
                where searchno = j_rec1.searchno and logid = j_rec1.logid 
            ) loop
                BEGIN
                    Insert into RVP_ENQ_REP_BENEFIT
                       (SEARCHNO, LOGID, POLICYNO, ITEMNO, ITEMCODE, ITEMDETAIL, AMOUNT, BALANCE)
                     Values
                       (i_searchno, i_logid ,j_rec1.policyno , b1.itemno ,b1.itemcode, 
                        b1.itemdetail , b1.amount , b1.balance);                
                EXCEPTION
                WHEN OTHERS THEN
                    o_rst := 'error insert benefit :'||sqlerrm;
                    ROLLBACK;
                    return;
                END;                
            end loop;
    END LOOP ;      -- End    P_ROW_CLM_DATA
    
    if cnt_pol >0 then                     
        COMMIT;  
    else
        o_rst := 'NoData';
        return;
    end if;    
--    select_str := null;    t_cond := null;  t_order :=null;
    
EXCEPTION
WHEN OTHERS THEN
    o_rst := 'error main :'||sqlerrm;
    return;
END GET_POLICY_COVERAGE;

PROCEDURE GET_POLICY_COVERAGE2(i_searchno IN VARCHAR2 ,i_logid IN VARCHAR2,
i_policyno  IN VARCHAR2 ,i_idcard  IN VARCHAR2 ,i_prefix  IN VARCHAR2 ,i_fname  IN VARCHAR2 ,i_lname  IN VARCHAR2 ,
i_accdate  IN DATE ,o_rst OUT VARCHAR2) IS
    select_str   VARCHAR2(30000);    
    query_str   VARCHAR2(10000);
    t_cond      VARCHAR2(10000);    
    t_order      VARCHAR2(10000);    
    dumm    NUMBER:=1;        
    
    P_ROW_CLM_DATA   RVP_CLAIM_PACKAGE.v_ref_cursor1;  
    c2   NC_HEALTH_PACKAGE.v_ref_cursor1;

    TYPE t_data1 IS RECORD
    (
        SEARCHNO          VARCHAR2(36 BYTE),
        LOGID             VARCHAR2(3 BYTE),
        POLICYNO          VARCHAR2(50 BYTE),
        SUBPOLICY1        VARCHAR2(50 BYTE),
        SUBPOLICY2        VARCHAR2(50 BYTE),
        STARTDATE         VARCHAR2(10 BYTE),
        ENDDATE           VARCHAR2(10 BYTE),
        IDCARD            VARCHAR2(30 BYTE),
        CARDTYPE          VARCHAR2(1 BYTE),
        PREFIX            VARCHAR2(10 BYTE),
        FNAME             VARCHAR2(50 BYTE),
        LNAME             VARCHAR2(50 BYTE),
        AMOUNT            NUMBER(10,2),
        BALANCE           NUMBER(10,2),
        PLANID            VARCHAR2(50 BYTE),
        PLANDESCRIPTION   VARCHAR2(255 BYTE),
        EXCLUSION         VARCHAR2(500 BYTE),
        POLICYSTATUS      VARCHAR2(1 BYTE),
        POLICYSTATUSDESC  VARCHAR2(500 BYTE)
    ); 
    j_rec1 t_data1;      
    
    P_POL_DATA   RVP_CLAIM_PACKAGE.v_ref_cursor1;
    TYPE t_data2 IS RECORD
    (
        POLICYNO          VARCHAR2(50 BYTE),
        FLEET_SEQ        NUMBER(10),
        RECPT_SEQ        NUMBER(10),        
        FR_DATE        DATE,
        TO_DATE        DATE,
        ID            VARCHAR2(30 BYTE),
        TITLE            VARCHAR2(10 BYTE),
        NAME             VARCHAR2(150 BYTE),
        SURNAME             VARCHAR2(150 BYTE),
        SUM_INS1            NUMBER(10,2),
        BALANCE           NUMBER(10,2),
        PLAN            VARCHAR2(100 BYTE)
    ); 
    j_rec2 t_data2;     
    
    TYPE t_data3 IS RECORD
    (
    PREMCODE    VARCHAR2(10),
    SUMINS  NUMBER,
    PREMCOL NUMBER
    ); 
    j_rec3 t_data3;      
--    TYPE t_data2 IS RECORD(
--      SEARCHNO    VARCHAR2(36 BYTE),
--      LOGID       VARCHAR2(3 BYTE),
--      POLICYNO    VARCHAR2(50 BYTE),
--      ITEMNO      VARCHAR2(2 BYTE),
--      ITEMCODE    VARCHAR2(5 BYTE),
--      ITEMDETAIL  VARCHAR2(500 BYTE),
--      AMOUNT      NUMBER(8,2),
--      BALANCE     NUMBER(8,2)
--    );
--        
    cnt_pol number:=0;
    cnt_ben number:=0;
    
    tSts1   varchar(200);
    x_cover_remark   varchar(200);
    
    v_polno varchar2(30);
    v_polrun    number(15);
--    x_chkmotor  boolean;
    x_status    varchar2(2);
    x_status_descr  varchar2(200);
BEGIN
    -- for dummy test connection 

    select_str := 'select pol_no||pol_run policyno ,fleet_seq ,recpt_seq ,fr_date ,to_date ,id ,title ,name ,surname ,sum_ins1 ,sum_ins1 balance  '           
    ||',(select patn_code||'' Plan:''||package_plan plan from mis_mas x where x.pol_no = a.pol_no and x.pol_run = a.pol_run and end_seq=0) plan '
    ||' from mis_pa_prem a  where 1=:dumm '
    ;
    t_cond := '';
    t_order := '';
        
    --=== SEARCH ===--
    if i_policyno is not null then
        p_acc_package.read_pol(i_policyno ,v_polno ,v_polrun);
        t_cond := t_cond || ' and a.pol_no = '''||v_polno||''' and a.pol_run = '||v_polrun;
    end if;

    if i_idcard is not null then
        t_cond := t_cond || ' and a.id = '''||i_idcard||''' ';
    end if;

--    if i_prefix is not null then
--        t_cond := t_cond || ' and a.title like ''%'||i_prefix||'%'' ';
--    end if;

    if i_fname is not null then
        t_cond := t_cond || ' and a.name like ''%'||i_fname||'%'' ';
    end if;

    if i_lname is not null then
        t_cond := t_cond || ' and a.suname like ''%'||i_lname||'%'' ';
    end if;

    if i_accdate is not null then
        t_cond := t_cond || ' and '''||i_accdate||''' between fr_date and to_date ';
    end if;    
                        
    query_str := select_str||t_cond||t_order;
    dbms_output.put_line('sql1 :'||select_str);
    dbms_output.put_line('sql2 :'||t_cond);
    dbms_output.put_line('sql3 :'||t_order);
    dbms_output.put_line('*******************');
    OPEN P_POL_DATA FOR query_str USING dumm;

    LOOP
       FETCH  P_POL_DATA INTO j_rec2;
        EXIT WHEN P_POL_DATA%NOTFOUND;
            dbms_output.put_line('Policy==>'||  j_rec2.policyno||' fleet==>'||  j_rec2.fleet_seq||' recpt==>'||  j_rec2.recpt_seq||  ' Plan:'||  j_rec2.plan||' Name: '||j_rec2.title||' '||j_rec2.name||' '||j_rec2.surname );  
            dbms_output.put_line('FrDate: '||j_rec2.fr_date||' ToDate: '||j_rec2.to_date||' id:'||j_rec2.id);
            cnt_pol := cnt_pol+1;
            
            if cnt_pol = 1 then -- set Response Data only 1 time
                for r1 in (select INSURERID, INSURERNAME, HOSPITALID, HOSPITALNAME, POLICYNO, IDCARD, CARDTYPE, PREFIX, FNAME, LNAME, PATIENTTYPE, ACCDATE,TREATMENTTYPE
                    from rvp_enq_req  a
                    where searchno = i_searchno and logid = i_logid 
                ) loop
                    BEGIN
                        Insert into RVP_ENQ_REP
                           (SEARCHNO, LOGID, INSURERID, INSURERNAME, HOSPITALID, HOSPITALNAME, POLICYNO, IDCARD, CARDTYPE, PREFIX, FNAME, LNAME, PATIENTTYPE, ACCDATE,TREATMENTTYPE ,SUCCESS, CODE, DESCR ,RESPONSEDATE)
                         Values
                           (i_searchno, i_logid, r1.insurerid, r1.insurername, r1.hospitalid, r1.hospitalname, r1.policyno, r1.idcard, r1.cardtype, r1.prefix, r1.fname, r1.lname, r1.patienttype, r1.accdate, r1.treatmenttype,
                           'TRUE', '', '' ,sysdate);            
                    EXCEPTION
                    WHEN OTHERS THEN
                        o_rst := 'error insert RVP_ENQ_REP :'||sqlerrm;
                        ROLLBACK;
                        return;
                    END;                
                end loop;
            end if; -- set Response Data only 1 time
                                    
            p_acc_package.read_pol(j_rec2.policyno ,v_polno ,v_polrun);
            GET_MED_REMARK(v_polno ,v_polrun ,j_rec2.fleet_seq ,x_cover_remark) ;
            
            NC_HEALTH_PACKAGE.GET_COVER_PA (v_polno,v_polrun,j_rec2.fleet_seq ,j_rec2.recpt_seq, null ,
                                              c2 ,tSts1 );
            if tSts1 is null then
                cnt_ben := 0;   
                LOOP
                   FETCH  c2 INTO j_rec3;
                    EXIT WHEN c2%NOTFOUND;
                        dbms_output.put_line('Prem==>'|| 
                         j_rec3.premcode||' '||NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec3.premcode ,'T')||
                         ' SUMINS:'||
                          j_rec3.sumins||
                          ' COL:'||
                          j_rec3.premcol
                        );
                        IF NC_HEALTH_PACKAGE.IS_CHECK_ACCUM(j_rec3.premcode) THEN --insert to show Coverage
                            cnt_ben := cnt_ben+1;
                            BEGIN
                                Insert into RVP_ENQ_REP_BENEFIT
                                   (SEARCHNO, LOGID, POLICYNO, ITEMNO, ITEMCODE, ITEMDETAIL, AMOUNT, BALANCE)
                                 Values
                                   (i_searchno, i_logid ,j_rec2.policyno , cnt_ben ,j_rec3.premcode, 
                                    NC_HEALTH_PACKAGE.GET_PREMCODE_DESCR(j_rec3.premcode ,'T') ,  j_rec3.sumins ,  j_rec3.sumins);                
                            EXCEPTION
                            WHEN OTHERS THEN
                                o_rst := 'error insert benefit :'||sqlerrm;
                                ROLLBACK;
                                return;
                            END;     
                        END IF;
                END LOOP;  
            end if;   
            HEALTHUTIL.GET_STATUS_ACTIVE(v_polno,v_polrun,j_rec2.fleet_seq ,j_rec2.recpt_seq ,i_accdate ,x_status) ;
            if x_status = 'Y' then
                x_status_descr := 'คุ้มครอง';
            elsif x_status = 'N' then
                x_status_descr := 'ไม่คุ้มครอง';
            elsif x_status = 'E' then
                x_status_descr := 'ไม่พบข้อมูล/กรุณาตรวจสอบ';
            end if;    
            if cnt_ben = 0 and x_status in ('Y','N') then -- ไม่มีคุ้มครองค่ารักษาพยาบาล
                x_status_descr := x_status_descr||' :: ไม่มีผลประโยชน์เรื่องค่ารักษาพยาบาล';
            end if;
            dbms_output.put_line('GET STATUS ACTIVE==>'||x_status||' :: '||x_status_descr);      
            dbms_output.put_line('++++++++++++++++++++++++++++++++++');dbms_output.put_line(' ');  
            BEGIN
                Insert into ALLCLM.RVP_ENQ_REP_POLICY 
                   (SEARCHNO, LOGID, POLICYNO, STARTDATE, ENDDATE, IDCARD, CARDTYPE, PREFIX, FNAME, LNAME, AMOUNT, BALANCE, POLICYSTATUS, POLICYSTATUSDESC,
                   PLANID ,PLANDESCRIPTION ,EXCLUSION,
                   SUBPOLICY1 ,SUBPOLICY2)
                 Values
                   (i_searchno ,i_logid ,j_rec2.policyno , 
                    to_char(j_rec2.fr_date,'yyyy/mm/dd'),to_char(j_rec2.to_date,'yyyy/mm/dd'), j_rec2.id, null, j_rec2.title, j_rec2.name, j_rec2.surname, 
                    j_rec2.sum_ins1, j_rec2.balance, x_status,x_status_descr ,
                    j_rec2.plan ,'' ,x_cover_remark ,
                    j_rec2.fleet_seq ,j_rec2.recpt_seq
                    ); 
            EXCEPTION
            WHEN OTHERS THEN
                o_rst := 'error insert policy :'||sqlerrm;
                ROLLBACK;
                return;
            END;                                                                                                                       
    END LOOP ;      -- End    P_POL_DATA

    if cnt_pol >0 then                     
        COMMIT;  
        dbms_output.put_line('cnt_pol='||cnt_pol);
    else
        o_rst := 'NoData';
        return;
    end if;    
--    select_str := null;    t_cond := null;  t_order :=null;
    
EXCEPTION
WHEN OTHERS THEN
    o_rst := 'error main :'||sqlerrm;
    return;
END GET_POLICY_COVERAGE2;

PROCEDURE GET_MED_REMARK(i_pol_no in varchar2 ,i_pol_run in number ,i_fleet_seq in number ,o_remark out varchar2) IS
    v_remark varchar2(500);
BEGIN
    
    nc_health_package.get_mc_remark(i_pol_no,i_pol_run,i_fleet_seq,o_remark);
    
  o_remark := o_remark||chr(10);                                
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
        
        
END CHECK_POLICY_MAIN; 
           
END RVP_CLAIM_PACKAGE;
/

