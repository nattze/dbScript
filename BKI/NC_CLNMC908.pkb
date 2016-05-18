CREATE OR REPLACE PACKAGE BODY ALLCLM.NC_CLNMC908 AS
/******************************************************************************
   NAME:       NC_CLNMC908
   PURPOSE: USE for Approve payment Program

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        17/03/2014      2702       1. Created this package.
******************************************************************************/

PROCEDURE GEN_CURSOR(qry_str IN CLOB ,P_CUR OUT v_ref_cursor1) IS
    --TYPE cur_typ IS REF CURSOR;
    --c           cur_typ;
BEGIN
              
    OPEN P_CUR FOR qry_str ;
    --RETURN;

END;

FUNCTION GEN_DRAFT(qry_str IN  LONG , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 IS -- null สำเร็จ
--**** byPass Cursor from 6i 
    TMP_C   NC_HEALTH_PACKAGE.v_ref_cursor1;   
    m_rst   VARCHAR2(200);
BEGIN
    GEN_CURSOR(qry_str ,TMP_C );
    m_rst := GEN_DRAFT(TMP_C , P_DRAFTNO) ;
    
    return m_rst;
END GEN_DRAFT;    

FUNCTION GEN_DRAFT(P_DATA  IN v_ref_cursor1 , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 IS
    c1   NC_HEALTH_PACKAGE.v_ref_cursor1;      

    TYPE t_data1 IS RECORD
    (
    STS_KEY    NUMBER,
    CLM_NO  VARCHAR2(20),
    PAY_NO  VARCHAR2(20),
    REF_NO   VARCHAR2(20),
    PAYEE_CODE  VARCHAR2(20)
    ); 
    r1 t_data1;     

--***
    v_pay_no    varchar2(20);
    v_CORR_SEQ NUMBER (2) ;
    v_PAY_DATE DATE ;
    v_PAY_AMT    NUMBER;
    v_REC_AMT    NUMBER;
    v_DEDUCT_AMT NUMBER    ;
    v_RES_AMT   NUMBER;
    v_TITLE     VARCHAR (15) ;
    v_NAME      VARCHAR (60) ;
    v_FR_DATE   DATE ;
    v_TO_DATE   DATE ;
    v_LOSS_DATE DATE     ;
    v_ADV_AMT number;    
    V_GM_PAY number;
    V_TOTAL_PAY number;
    V_TOTAL_REC number;    
    V_PROD_GRP  VARCHAR (10) ;
--***        
    vRST    VARCHAR2(200);
    m_rst    VARCHAR2(200);
    dummy_drf   VARCHAR2(10);
    dummy_fnew  VARCHAR2(10);
    M_DRAFTNO   VARCHAR2(20);
    M_REFNO   VARCHAR2(20);
    v_SID    NUMBER:= NC_HEALTH_PACKAGE.GEN_SID;
BEGIN

    dbms_output.put_line('vSID='||v_SID);
    LOOP  -- นำข้อมูลมาสร้าง Draft 
       FETCH  P_DATA INTO r1;
        EXIT WHEN P_DATA%NOTFOUND;
            dbms_output.put_line('ref: '||r1.ref_no
            ||' clm_no: '||r1.clm_no
            ||' pay_no: '||r1.pay_no);
            if  r1.clm_no is null  or r1.pay_no is null  or r1.payee_code is null  then
                vRST := 'ข้อมูลที่ทำ Draft ไม่สมบูรณ์' ;
                NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'GEN_DRAFT' ,vRST,
                              m_rst)   ;      
            end if;     
            INSERT INTO ALLCLM.MED_DRAFT_TMP
            ( VSID , REF_NO   , CLM_NO , STS_KEY , PAYEE_CODE ,PAY_NO )   VALUES
            ( v_SID ,r1.ref_no ,r1.clm_no ,r1.sts_key ,r1.payee_code , r1.pay_no)  ;      
            M_REFNO := r1.REF_NO ;                        
    END LOOP;     
               
    IF vRST is not null THEN
        ROLLBACK;
        return vRST;    
    ELSE
        COMMIT;  --** Submit MED_DRAFT_TMP 
    END IF; 
    --*** pass validate null INPUT
    
--    --*** Validate Payment 
--    dummy_drf := CHECK_DRAFT('');
--    if dummy_drf = 'D' then    -- Case Batch Print
--        vRST := ('พิมพ์ Draft แล้ว ต้องเคลียร์ Draft ก่อน!');
--    elsif dummy_drf = 'B' then    
--        vRST := ('พิมพ์ BATCH แล้ว ไม่สามารถเรียก Draft ได้!');       
--    elsif dummy_drf = 'N' then    
--          dummy_fnew := CHECK_PENDING_APPRV(''); -- check payment waiting for approve
--          if dummy_fnew = 'Y' then
--                vRST := ('พบเลขจ่ายในข้อมูลชุดนี้ มีการขออนุมัติวงเงินอยู่ ไม่สามารถพิมพ์ Draft ได้ !');                      
--          elsif dummy_fnew = 'N' then
--                vRST := null ;    /* success */
--            end if;
--    end if;       
--    
--    IF vRST is not null THEN
--        ROLLBACK;
--        return vRST;    
--    END IF;        
--    --**** * ** * ** * *  *
    
    -- *** gen Draft *******
    M_DRAFTNO := NC_HEALTH_PAID.GET_BATCHNO('D');
    for p1 in (select  b.clm_no ,'' advance_no ,c.pol_no ,c.pol_run ,c.clm_men ,c.mas_cus_enq , b.payee_code ,b.pay_no ,c.prod_type
            from mis_clm_paid a, mis_clm_payee b ,mis_clm_mas c ,mis_clm_mas_seq d
            where a.clm_no = b.clm_no and b.clm_no = c.clm_no and c.clm_no = d.clm_no 
            and d.corr_seq in (select max(x.corr_seq) from mis_clm_mas_seq x where  x.clm_no = d.clm_no)  
            and a.pay_no = b.pay_no
            and a.pay_no in (
                    select yy.pay_no
                    from MED_DRAFT_TMP yy   where vSID = v_SID
            )                                     
            and a.print_type is null and a.pay_date is null
            and c.clm_sts in ('6','7') and d.close_date is null
      and pay_seq in (select max(e.pay_seq) from mis_clm_payee e where e.pay_no = b.pay_no )
      and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
                      where b.pay_no = a.pay_no
                      group by b.pay_no)                
            and a.pay_total >0
            and a.pay_no not like '01'||substr(A.CLM_NO,7,3)||'%'
            order by b.clm_no desc)
    loop       
    
        for p2 in (select pay_no ,corr_seq ,pay_date ,pay_total ,0 rec_total
            from mis_clm_paid a 
            where a.clm_no = p1.clm_no
            and a.pay_no =   p1.pay_no       
            and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no) )                
        loop
            v_pay_no := p2.pay_no;
            v_CORR_SEQ := p2.corr_seq;
            v_PAY_DATE := p2.pay_date;            
            V_TOTAL_PAY := p2.pay_total;
            V_TOTAL_REC := nvl(p2.rec_total,0);
        end loop;
        
        for p3 in (select sum(pay_total) pay_amt ,sum(0) rec_amt ,sum(0) deduct_amt
            from mis_clm_paid a
            where a.clm_no = p1.clm_no
            and a.pay_no = p1.pay_no                
            and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no) )                    
        loop
            V_GM_PAY := p3.pay_amt;
            v_REC_AMT := p3.rec_amt;
            v_DEDUCT_AMT := p3.deduct_amt;            
        end loop;
        
        if v_DEDUCT_AMT is not null or v_DEDUCT_AMT > 0 then
            v_DEDUCT_AMT := v_DEDUCT_AMT;    
        end if;    
        
        begin
            select payee_amt into v_PAY_AMT
            from mis_clm_payee
            where clm_no = p1.clm_no
            and pay_no = p1.pay_no
            and pay_seq in (select max(b.pay_seq) from mis_clm_payee b where b.clm_no = p1.clm_no    and b.pay_no = p1.pay_no);
        exception
            when no_data_found then
            v_PAY_AMT := null;
            when others then
            v_PAY_AMT := null;
        end;        
        
        for p4 in (select tot_res res_amt ,'' title ,loss_name name ,fr_date ,to_date ,b.loss_date ,prod_grp 
                from mis_clm_mas a ,mis_cpa_res b
                where a.clm_no = b.clm_no 
                and a.clm_no = p1.clm_no
                and b.res_seq in (select max(z.res_seq) from mis_cpa_res z where z.clm_no = b.clm_no) )        
        loop
            v_RES_AMT := p4.res_amt;
            v_TITLE := p4.title;
            v_NAME  := p4.name;
            v_FR_DATE := p4.fr_date;
            v_TO_DATE := p4.to_date;
            v_LOSS_DATE := p4.loss_date;            
            V_PROD_GRP := p4.prod_grp;
        end loop;        
        
        v_ADV_AMT := nvl(v_PAY_AMT,0) - (nvl(V_GM_PAY,0) -nvl(v_REC_AMT,0)) - nvl(v_DEDUCT_AMT,0);

        begin
            Insert into clm_batch_tmp
               (BATCH_NO, CLM_NO, PAY_NO, CORR_SEQ, PAID_DATE, P_VOU_NO, P_VOU_DATE, ADVANCE_NO, POL_NO, POL_RUN
               , PAYEE_CODE, CLM_MEN, CUS_ENQ, TITLE, NAME, FR_DATE, TO_DATE, LOSS_DATE
               , RES_AMT, PAY_AMT, ADV_AMT ,DEDUCT_AMT ,PROD_TYPE
               , REF_NO , DRAFT_NO ,REAL_PROD_TYPE ,PROD_GRP
               )
             Values
               (null, p1.clm_no, v_pay_no, v_CORR_SEQ, v_PAY_DATE, null, null, p1.advance_no, p1.pol_no, p1.pol_run
               , p1.payee_code, p1.clm_men, p1.mas_cus_enq, v_TITLE, v_NAME, v_FR_DATE, v_TO_DATE, v_LOSS_DATE
               , v_RES_AMT, v_PAY_AMT, v_ADV_AMT ,v_DEDUCT_AMT ,'001'
               ,M_REFNO ,M_DRAFTNO ,p1.prod_type ,V_PROD_GRP
               );
               
--            update mis_clm_paid a
--            set print_type = '0' 
--            where a.clm_no = p1.clm_no
--            and pay_no = p1.pay_no
--            and  (a.pay_no,a.corr_seq) in (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
--            where b.pay_no = a.pay_no
--            group by b.pay_no)    ;
        exception
            when others then
            --rollback; raise form_trigger_failure;
            vRST := 'error Script Draft :'||sqlerrm; 
        end;
        
    end loop;        
    -- *** * END gen draft * *  * *
    
    --**** Final Step ****
    IF vRST is not null THEN
        ROLLBACK;
        DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
        COMMIT;        
        return vRST;    
    ELSE
        P_DRAFTNO := M_DRAFTNO;
        DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
        COMMIT;
    END IF; 
        
    return vRST;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
    COMMIT;    
    return 'error main GEN_DRAFT: '||sqlerrm ;    
END GEN_DRAFT;

FUNCTION  CLEAR_DRAFT(P_DRAFTNO IN  VARCHAR2) RETURN VARCHAR2 IS -- null สำเร็จ
    m_rst   VARCHAR2(200);
    v_batch_no VARCHAR2(20);
BEGIN
    
    DELETE from clm_batch_tmp  WHERE  draft_no = P_DRAFTNO ;
    
    COMMIT;
    return null;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    return 'error clear Draftno.: '||P_DRAFTNO ;
END CLEAR_DRAFT;    

FUNCTION GEN_DRAFT_GM(qry_str IN  LONG , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 IS -- null สำเร็จ
--**** byPass Cursor from 6i 
    TMP_C   NC_HEALTH_PACKAGE.v_ref_cursor1;   
    m_rst   VARCHAR2(200);
BEGIN
    GEN_CURSOR(qry_str ,TMP_C );
    m_rst := GEN_DRAFT_GM(TMP_C , P_DRAFTNO) ;
    
    return m_rst;
END GEN_DRAFT_GM;    

FUNCTION GEN_DRAFT_GM(P_DATA  IN v_ref_cursor1 , P_DRAFTNO OUT VARCHAR2) RETURN VARCHAR2 IS
    c1   NC_HEALTH_PACKAGE.v_ref_cursor1;      

    TYPE t_data1 IS RECORD
    (
    STS_KEY    NUMBER,
    CLM_NO  VARCHAR2(20),
    PAY_NO  VARCHAR2(20),
    REF_NO   VARCHAR2(20),
    PAYEE_CODE  VARCHAR2(20)
    ); 
    r1 t_data1;     

--***
    v_pay_no    varchar2(20);
    v_CORR_SEQ NUMBER (2) ;
    v_PAY_DATE DATE ;
    v_PAY_AMT    NUMBER;
    v_REC_AMT    NUMBER;
    v_DEDUCT_AMT NUMBER    ;
    v_RES_AMT   NUMBER;
    v_TITLE     VARCHAR (15) ;
    v_NAME      VARCHAR (60) ;
    v_FR_DATE   DATE ;
    v_TO_DATE   DATE ;
    v_LOSS_DATE DATE     ;
    v_ADV_AMT number;    
    V_GM_PAY number;
    V_TOTAL_PAY number;
    V_TOTAL_REC number;    
    V_PROD_GRP  VARCHAR (10) ;
--***        
    vRST    VARCHAR2(200);
    m_rst    VARCHAR2(200);
    dummy_drf   VARCHAR2(10);
    dummy_fnew  VARCHAR2(10);
    M_DRAFTNO   VARCHAR2(20);
    M_REFNO   VARCHAR2(20);
    v_SID    NUMBER:= NC_HEALTH_PACKAGE.GEN_SID;
BEGIN

    dbms_output.put_line('vSID='||v_SID);
    LOOP  -- นำข้อมูลมาสร้าง Draft 
       FETCH  P_DATA INTO r1;
        EXIT WHEN P_DATA%NOTFOUND;
            dbms_output.put_line('ref: '||r1.ref_no
            ||' clm_no: '||r1.clm_no
            ||' pay_no: '||r1.pay_no);
            if  r1.clm_no is null  or r1.pay_no is null  or r1.payee_code is null  then
                vRST := 'ข้อมูลที่ทำ Draft ไม่สมบูรณ์' ;
                NC_HEALTH_PACKAGE.WRITE_LOG  ( 'PACKAGE' ,'NC_HEALTH_PAID' ,'GEN_DRAFT' ,vRST,
                              m_rst)   ;      
            end if;     
            INSERT INTO ALLCLM.MED_DRAFT_TMP
            ( VSID , REF_NO   , CLM_NO , STS_KEY , PAYEE_CODE ,PAY_NO )   VALUES
            ( v_SID ,r1.ref_no ,r1.clm_no ,r1.sts_key ,r1.payee_code , r1.pay_no)  ;      
            M_REFNO := r1.REF_NO ;                        
    END LOOP;     
               
    IF vRST is not null THEN
        ROLLBACK;
        return vRST;    
    ELSE
        COMMIT;  --** Submit MED_DRAFT_TMP 
    END IF; 
    --*** pass validate null INPUT
    
--    --*** Validate Payment 
--    dummy_drf := CHECK_DRAFT('');
--    if dummy_drf = 'D' then    -- Case Batch Print
--        vRST := ('พิมพ์ Draft แล้ว ต้องเคลียร์ Draft ก่อน!');
--    elsif dummy_drf = 'B' then    
--        vRST := ('พิมพ์ BATCH แล้ว ไม่สามารถเรียก Draft ได้!');       
--    elsif dummy_drf = 'N' then    
--          dummy_fnew := CHECK_PENDING_APPRV(''); -- check payment waiting for approve
--          if dummy_fnew = 'Y' then
--                vRST := ('พบเลขจ่ายในข้อมูลชุดนี้ มีการขออนุมัติวงเงินอยู่ ไม่สามารถพิมพ์ Draft ได้ !');                      
--          elsif dummy_fnew = 'N' then
--                vRST := null ;    /* success */
--            end if;
--    end if;       
--    
--    IF vRST is not null THEN
--        ROLLBACK;
--        return vRST;    
--    END IF;        
--    --**** * ** * ** * *  *
    
    -- *** gen Draft *******
    M_DRAFTNO := NC_HEALTH_PAID.GET_BATCHNO('GD');
    for p1 in (select  b.clm_no ,'' advance_no ,c.pol_no ,c.pol_run ,c.clm_men ,c.mas_cus_enq ,replace(b.payee_code,' ','') payee_code ,b.pay_no
            from mis_clmgm_paid a, clm_gm_payee b ,mis_clm_mas c
            where a.clm_no = b.clm_no and b.clm_no = c.clm_no 
            and a.print_type is null and a.pay_date is null
            and c.clm_sts = '6' and c.close_date is null
      and pay_seq = (select max(e.pay_seq) from clm_gm_payee e where e.pay_no = b.pay_no )
      and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from mis_clmgm_paid b
                      where b.clm_no = a.clm_no
                      group by b.clm_no)                
            and a.pay_no in (
                    select yy.pay_no
                    from MED_DRAFT_TMP yy   where vSID = v_SID
            )      
            and a.pay_total >0
            and a.pay_no not like '01'||c.prod_type||'%'
            order by b.clm_no desc    
    )        
    loop       
    
        for p2 in (select pay_no ,corr_seq ,pay_date ,pay_total ,rec_total
            from mis_clmgm_paid a where a.clm_no = p1.clm_no
            and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from mis_clmgm_paid b
            where b.clm_no = a.clm_no
            group by b.clm_no) )                
        loop
            v_pay_no := p2.pay_no;
            v_CORR_SEQ := p2.corr_seq;
            v_PAY_DATE := p2.pay_date;            
            V_TOTAL_PAY := p2.pay_total;
            V_TOTAL_REC := nvl(p2.rec_total,0);
        end loop;
        
        for p3 in (select sum(pay_amt) pay_amt ,sum(rec_amt) rec_amt ,sum(deduct_amt) deduct_amt
            from clm_gm_paid a
            where a.clm_no = p1.clm_no
            and  (a.clm_no,a.corr_seq) = (select b.clm_no,max(b.corr_seq) from clm_gm_paid b
            where b.clm_no = a.clm_no
            group by b.clm_no) )                    
        loop
            V_GM_PAY := p3.pay_amt;
            v_REC_AMT := p3.rec_amt;
            v_DEDUCT_AMT := p3.deduct_amt;            
        end loop;
        
        if v_DEDUCT_AMT is not null or v_DEDUCT_AMT > 0 then
            v_DEDUCT_AMT := v_DEDUCT_AMT;    
        end if;    
        
        begin
            select payee_amt into v_PAY_AMT
            from clm_gm_payee
            where clm_no = p1.clm_no
            and pay_no = p1.pay_no
            and pay_seq = (select max(b.pay_seq) from clm_gm_payee b where b.clm_no = p1.clm_no    and b.pay_no = p1.pay_no);
        exception
            when no_data_found then
            v_PAY_AMT := null;
            when others then
            v_PAY_AMT := null;
        end;      
        
        for p4 in (select sum(res_amt) res_amt ,max(title) title ,max(name) name ,max(a.fr_date) fr_date ,max(a.to_date) to_date ,max(a.loss_date) loss_date ,max(m.prod_grp) prod_grp
                from mis_clm_mas m, clm_medical_res a 
                where m.clm_no = a.clm_no 
                and a.clm_no = p1.clm_no
                and  (a.state_no,a.state_seq) = (select b.state_no,max(b.state_seq) from clm_medical_res b
                where b.clm_no = a.clm_no and b.state_no = a.state_no
                group by b.state_no)         )
        loop
            v_RES_AMT := p4.res_amt;
            v_TITLE := p4.title;
            v_NAME  := p4.name;
            v_FR_DATE := p4.fr_date;
            v_TO_DATE := p4.to_date;
            v_LOSS_DATE := p4.loss_date;            
            V_PROD_GRP := p4.prod_grp;
        end loop;        
        
        v_ADV_AMT := nvl(v_PAY_AMT,0) - (nvl(V_GM_PAY,0) -nvl(v_REC_AMT,0)) - nvl(v_DEDUCT_AMT,0);

--        begin
--            Insert into clm_batch_tmp
--               (BATCH_NO, CLM_NO, PAY_NO, CORR_SEQ, PAID_DATE, P_VOU_NO, P_VOU_DATE, ADVANCE_NO, POL_NO, POL_RUN
--               , PAYEE_CODE, CLM_MEN, CUS_ENQ, TITLE, NAME, FR_DATE, TO_DATE, LOSS_DATE
--               , RES_AMT, PAY_AMT, ADV_AMT ,DEDUCT_AMT ,PROD_TYPE
--               , REF_NO , DRAFT_NO ,REAL_PROD_TYPE ,PROD_GRP
--               )
--             Values
--               (null, p1.clm_no, v_pay_no, v_CORR_SEQ, v_PAY_DATE, null, null, p1.advance_no, p1.pol_no, p1.pol_run
--               , p1.payee_code, p1.clm_men, p1.mas_cus_enq, v_TITLE, v_NAME, v_FR_DATE, v_TO_DATE, v_LOSS_DATE
--               , v_RES_AMT, v_PAY_AMT, v_ADV_AMT ,v_DEDUCT_AMT ,'001'
--               ,M_REFNO ,M_DRAFTNO ,p1.prod_type ,V_PROD_GRP
--               );
--        exception
--            when others then
--            --rollback; raise form_trigger_failure;
--            vRST := 'error Script Draft :'||sqlerrm; 
--        end;
        begin
            Insert into clmgm_batch_tmp
               (BATCH_NO, CLM_NO, PAY_NO, CORR_SEQ, PAID_DATE, P_VOU_NO, P_VOU_DATE, ADVANCE_NO, POL_NO, POL_RUN
               , PAYEE_CODE, CLM_MEN, CUS_ENQ, TITLE, NAME, FR_DATE, TO_DATE, LOSS_DATE
               , RES_AMT, PAY_AMT, ADV_AMT ,DEDUCT_AMT
               ,DRAFT_NO)
             Values
               (null, p1.clm_no, v_pay_no, v_CORR_SEQ, v_PAY_DATE, null, null, p1.advance_no, p1.pol_no, p1.pol_run
               , p1.payee_code, p1.clm_men, p1.mas_cus_enq, v_TITLE, v_NAME, v_FR_DATE, v_TO_DATE, v_LOSS_DATE
               , v_RES_AMT, v_PAY_AMT, v_ADV_AMT ,v_DEDUCT_AMT
               ,M_DRAFTNO);
               
        exception
            when others then
            vRST := 'error Script Draft :'||sqlerrm; 
        end;        
        
    end loop;        
    -- *** * END gen draft * *  * *
    
    --**** Final Step ****
    IF vRST is not null THEN
        ROLLBACK;
        DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
        COMMIT;        
        return vRST;    
    ELSE
        P_DRAFTNO := M_DRAFTNO;
        DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
        COMMIT;
    END IF; 
        
    return vRST;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    DELETE MED_DRAFT_TMP WHERE VSID = v_SID; 
    COMMIT;    
    return 'error main GEN_DRAFT: '||sqlerrm ;    
END GEN_DRAFT_GM;

FUNCTION  CLEAR_DRAFT_GM(P_DRAFTNO IN  VARCHAR2) RETURN VARCHAR2 IS -- null สำเร็จ
    m_rst   VARCHAR2(200);
    v_batch_no VARCHAR2(20);
BEGIN
    
    DELETE from clmgm_batch_tmp  WHERE  draft_no = P_DRAFTNO ;
    
    COMMIT;
    return null;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    return 'error clear Draftno.: '||P_DRAFTNO ;
END CLEAR_DRAFT_GM;    

PROCEDURE  CLEAR_ACR_TMP(P_PAYNO IN  VARCHAR2) IS -- null สำเร็จ

BEGIN
    
    DELETE from acc_clm_tmp  WHERE  payment_no  = P_PAYNO ;
    
    DELETE from acc_clm_payee_tmp  WHERE  payment_no  = P_PAYNO ;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
END CLEAR_ACR_TMP;    

FUNCTION Validate_main(vClmno IN VARCHAR2 ,vPayno IN VARCHAR2 ,vPolno IN VARCHAR2 ,vPolrun IN Number,vLossDate IN Date ,vFleet IN Number ,vRecpt IN Number
,vRST OUT VARCHAR2) RETURN BOOLEAN /* false = not pass */ IS
    vPass boolean:=true;
    --==== local variable ===
    RST_get_status VARCHAR2(10);
    RST_RI VARCHAR2(50);
    RST_CLM VARCHAR2(50);
    
    vStsKey    NUMBER;
BEGIN
    -- validate Reserve , ReInsuance
    if Validate_RI_AND_PAID(vClmno ,vPayno ,GET_PRODUCTID(vClmno) , RST_RI) then
        vRST := null;             
    else
        vRST := 'Validate_RI: '||RST_RI ; 
        return false;    
    end if;
    
--    if Validate_ClmDetail(vStsKey, RST_CLM) then
--        vRST := null;             
--    else
--        vRST := 'Validate_ClmDetail: '||RST_CLM ; 
--        return false;    
--    end if;
--
--    if Validate_Cancel(vStsKey, RST_CLM) then
--        vRST := null;             
--    else
--        vRST := 'Validate_Cancel: '||RST_CLM ; 
--        return false;    
--    end if;    
    
    return vPass; 
END Validate_main;

FUNCTION Validate_RI_AND_PAID (vClmno IN VARCHAR2 ,vPayno IN VARCHAR2 ,vProd IN VARCHAR2, vRST OUT VARCHAR2) 
    RETURN BOOLEAN /* false = not pass */IS
    vPass boolean:=true;
    --==== local variable ===
    l_totpaid_amt    Number;
    l_clmpaid_amt    Number;
    l_ripaid_amt    Number;
BEGIN
    if vProd = 'PA' then
        --=== TOTAL PAID PA ====
        begin 
            select tot_paid into l_totpaid_amt
            from mis_clm_mas a
            where clm_no = vClmno;        
        exception
            when no_data_found then
                l_totpaid_amt := 0;
            when others then
                l_totpaid_amt := 0;
        end;
        
        if l_totpaid_amt <= 0 then
            vRst := 'not found PAID Amount!'; return false;    
        end if;

        --=== CLM PAID PA ====
        begin 
            select pay_total into l_clmpaid_amt
            from mis_clm_paid a
            where pay_no = vPayno
            and (a.pay_no ,a.corr_seq) in (
            select aa.pay_no ,max(aa.corr_seq) from mis_clm_paid aa where aa.pay_no = a.pay_no group by pay_no
            );        
        exception
            when no_data_found then
                l_clmpaid_amt := 0;
            when others then
                l_clmpaid_amt := 0;
        end;
        
        if l_clmpaid_amt <= 0 then
            vRst := 'not found Clm PAID Amount!'; return false;    
        else
            if l_totpaid_amt <> l_clmpaid_amt then
                vRst := 'ยอด Paid บน Master กับ Summary ไม่เท่ากัน!'; return false;    
            end if;
        end if;
        
        --=== Re Insurance ===
        begin 
            select sum(pay_amt) into l_ripaid_amt
            from mis_cri_paid a
            where pay_no = vPayno
            and corr_seq in (select max(x.corr_seq) from mis_cpa_paid x where x.pay_no = a.pay_no );     
        exception
            when no_data_found then
                l_ripaid_amt := 0;
            when others then
                l_ripaid_amt := 0;
        end;
    
        if l_ripaid_amt <= 0 then
            vRst := 'not found RI Amount!'; return false;    
        else
            if l_totpaid_amt <> l_ripaid_amt then
                vRst := 'ยอด Paid บน RI PAID ไม่ถูกต้อง!'; return false;    
            end if;            
        end if;
        
        return true;        
    elsif vProd = 'GM' then -- GM
        --=== TOTAL PAID GM ====
        begin 
            select tot_paid into l_totpaid_amt
            from mis_clm_mas a
            where clm_no = vClmno;        
        exception
            when no_data_found then
                l_totpaid_amt := 0;
            when others then
                l_totpaid_amt := 0;
        end;
        
--        if l_totpaid_amt <= 0 then  -- can Advance 100%
--            vRst := 'not found PAID Amount!'; return false;    
--        end if;

        --=== CLM PAID GM ====
        begin 
            select nvl(pay_total,0)-nvl(rec_total,0) into l_clmpaid_amt
             from mis_clmgm_paid e
             where clm_no = vClmno and pay_no = vPayno
             and (e.pay_no ,e.corr_seq) in (select ee.pay_no ,max(ee.corr_seq) from mis_clmgm_paid ee where ee.clm_no = e.clm_no and ee.pay_no = e.pay_no group by ee.pay_no )
             ;        
        exception
            when no_data_found then
                l_clmpaid_amt := 0;
            when others then
                l_clmpaid_amt := 0;
        end;
        
--        if l_clmpaid_amt <= 0 then
--            vRst := 'not found Clm PAID Amount!'; return false;    
--        else
--            if l_totpaid_amt <> l_clmpaid_amt then
--                vRst := 'ยอด Paid บน Master กับ Summary ไม่เท่ากัน!'; return false;    
--            end if;
--        end if;
        
        --=== Re Insurance ===
        begin 
            select sum(pay_amt) into l_ripaid_amt
            from mis_cri_paid a
            where pay_no = vPayno
            and corr_seq in (select max(x.corr_seq) from mis_cpa_paid x where x.pay_no = a.pay_no );     
        exception
            when no_data_found then
                l_ripaid_amt := 0;
            when others then
                l_ripaid_amt := 0;
        end;
    
        if l_ripaid_amt <= 0 then
            vRst := 'not found RI Amount!'; return false;    
        else
            if l_clmpaid_amt <> l_ripaid_amt then
                vRst := 'ยอด Paid บน RI PAID ไม่ถูกต้อง!'; return false;    
            end if;            
        end if;
        
        return true;     
    end if; -- === END PA and GM

END Validate_RI_AND_PAID;

FUNCTION Validate_Advance_Amt (vClmno IN VARCHAR2 ,vPayno IN VARCHAR2 ,vProd IN VARCHAR2, vRST OUT VARCHAR2) 
    RETURN BOOLEAN /* false = not pass */IS
    vPass boolean:=true;
    --==== local variable ===
    total_paid    Number;
    total_pay    Number;
--    l_ripaid_amt    Number;
BEGIN
    if vProd = 'PA' then
        return true;        
    elsif vProd = 'GM' then -- GM
        --=== TOTAL PAID  ====
        begin 
            select sum(nvl(max_amt_clm,0)) + sum(nvl(max_agr_amt,0)) total_paid
            into total_paid
            from clm_medical_paid a
            where clm_no =vClmno ;

        exception
            when no_data_found then
                total_paid := 0;
                vRst := 'มีการเกิดบัญชีพัก แบบผิดปกติ กรุณาติดต่อ IT!'; return false;    
            when others then
                total_paid := 0;
                vRst := 'มีการเกิดบัญชีพัก แบบผิดปกติ กรุณาติดต่อ IT!'; return false;    
        end;
       
        begin 
            select sum(nvl(pay_amt ,0)) tot_pay
            into total_pay
            from clm_gm_paid a
            where clm_no = vClmno 
            and pay_no = vPayno
            and corr_seq in (select max(aa.corr_seq) from clm_gm_paid aa where aa.pay_no = a.pay_no )   ;
        exception
            when no_data_found then
                total_pay := 0;
                vRst := 'มีการเกิดบัญชีพัก แบบผิดปกติ กรุณาติดต่อ IT!'; return false;    
            when others then
                total_pay := 0;
                vRst := 'มีการเกิดบัญชีพัก แบบผิดปกติ กรุณาติดต่อ IT!'; return false;    
        end; 
        
        if total_pay <> total_paid then
            vRst := 'มีการเกิดบัญชีพัก แบบผิดปกติ กรุณาติดต่อ IT!'; return false; 
        end if;
        
        return true;     
    end if; -- === END PA and GM

END Validate_Advance_Amt;

FUNCTION GET_PRODUCTID(vCLMno IN VARCHAR2) RETURN VARCHAR2 IS
    vProd    VARCHAR2(10);
BEGIN
  select sysid into vProd
    from clm_grp_prod
    where prod_type in (select x.prod_type from mis_clm_mas x where x.clm_no = vCLMno);
    return vProd;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        return null;
    WHEN OTHERS THEN
        return null;
END GET_PRODUCTID;

FUNCTION GET_PRODUCTID2(vProdtype IN VARCHAR2) RETURN VARCHAR2 IS
    vProd    VARCHAR2(10);
BEGIN
  select sysid into vProd
    from clm_grp_prod
    where prod_type = vProdtype ;
    return vProd;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        return null;
    WHEN OTHERS THEN
        return null;
END GET_PRODUCTID2;

FUNCTION GET_PRODUCT_TYPE(vPayno IN VARCHAR2) RETURN VARCHAR2 IS
    vProd    VARCHAR2(10);
BEGIN
  select prod_type into vProd
    from mis_clm_mas
    where clm_no in (select x.clm_no from mis_cri_paid x where x.pay_no = vPayno and rownum=1) ;
    return vProd;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        return null;
    WHEN OTHERS THEN
        return null;
END GET_PRODUCT_TYPE;

FUNCTION Validate_Cancel (vClmno IN VARCHAR2 , vRST OUT VARCHAR2)
    RETURN BOOLEAN /* false = not pass */IS
    vPass boolean:=true;
    --==== local variable ===
    l_res_amt    Number;
    l_ri_res_amt    Number; 
BEGIN
    --=== check Claim Data ====
  FOR X in (
    select clm_sts 
        from mis_clm_mas a
        where clm_no =vClmno 
  ) LOOP
      if x.clm_sts in ('2' ,'3') then
          vRST := 'Claim was Canceled!'; return false;
      elsif  x.clm_sts not in ('6')  then 
          vRST := 'Claim Status not PAID!'; return false;
      end if;
      
  END LOOP;
    
    return true;
END Validate_Cancel;

FUNCTION Validate_Approve_Cancel (vKey IN NUMBER ,vPayNo IN VARCHAR2 , vRST OUT VARCHAR2)
    RETURN BOOLEAN /* false = not pass */IS
    vPass boolean:=true;
    --==== local variable ===
    oApprv  varchar2(10);
    oStatus  varchar2(10);
    vClmNo  varchar2(20);
    
    V_VOUNO acr_mas.setup_vou_no%type;
    V_VOUDATE acr_mas.setup_vou_date%type;
BEGIN
    --=== check Pending Approve===
    if IS_PENDING_APPRV(vKey ,vPayNo,oApprv) then
        vRST := 'เลขจ่ายนี้อยู่ระหว่างขออนุมัติ'; return false;
    end if;    

    --=== check Last  Approve Status===
    chk_last_apprv_status(vKey ,vPayNo ,oStatus ,oApprv);
    if oStatus in ('NCPAYSTS10','NCPAYSTS09','NCPAYSTS12') then
        vRST := 'เลขจ่ายนี้ พิมพ์ statement แล้วไม่สามารถยกเลิกการอนุมัติได้ ต้องทำE-Approve!!'; return false;
    elsif oStatus in ('NCPAYSTS01','NCPAYSTS04','NCPAYSTS08') then
        vRST := 'เลขจ่ายนี้ ยังไม่มีการอนุมัติงาน!!'; return false;        
    elsif oStatus is null then
        vRST := 'ไม่พบสถานะในระบบอนุมัติจ่าย!!'; return false;
    end if;   
    
    --==== check ACR Voucher
    p_acc_claim.get_acr_voucher ( '0' /* p_prod_grp in acr_tmp.prod_grp%type */,

    NC_CLNMC908.GET_PRODUCT_TYPE(vPayNo) /* p_prod_type in acr_tmp.prod_type%type */,

    vPayNo /* p_number in varchar2 */,   -- payment no or batch no

    'P' /* p_flag in varchar2 */,  -- 'P' = Payment, 'B' = Batch

    V_VOUNO /* p_vou_no out acr_mas.setup_vou_no%type */,

    V_VOUDATE /* p_vou_date out acr_mas.setup_vou_date%type */);
    
    if V_VOUNO is not null then -- Post ACR Voucher already
        vRST := 'เลขจ่ายนี้ มีการทำ Voucher แล้ว :: vou_no= '||V_VOUNO||' !!'; return false;        
    end if;
                 
    --=== check Claim Status ====
    for c1 in (
        select clm_no from mis_clm_paid
        where pay_no = vPayNo and rownum=1
    )loop
        vClmNo := c1.clm_no;
    end loop;
    if not Validate_Cancel(vClmNo ,vRST) then
        return false;
    end if;
    
    return true;
EXCEPTION
    WHEN OTHERS THEN
        vRST := 'error Validate_Approve_Cancel :'||sqlerrm ; return false;        
END Validate_Approve_Cancel;

PROCEDURE CHK_LAST_APPRV_STATUS(v_key IN NUMBER ,v_payno IN VARCHAR2 
, O_STATUS OUT VARCHAR2 , O_APPRV_FLAG OUT VARCHAR2 ) IS

BEGIN
    FOR C1 in (
        select PAY_STS , apprv_flag
        from nc_payment a
        where sts_key = v_key and pay_no = v_payno
        and trn_seq = (select max(b.trn_seq) from nc_payment b where b.sts_key = a.sts_key and b.pay_no = a.pay_no)             
    )            
    LOOP    
        O_STATUS := C1.PAY_STS;
        O_APPRV_FLAG := C1.apprv_flag ;
    END LOOP;      
    
END CHK_LAST_APPRV_STATUS;

FUNCTION CHK_OWN_APPRV(v_user IN VARCHAR2 ,v_amt IN NUMBER ,v_sys IN VARCHAR2 ,v_apprv IN VARCHAR2) RETURN BOOLEAN IS

    tSts1 varchar2(20000):=null; 
    tSts2 varchar2(20000);    
    c1   NMTR_PACKAGE.v_ref_cursor2;  
    
    tnum number;
    TYPE t_data1 IS RECORD
    (
    SUBSYSID varchar2(5)  ,
    USER_ID  varchar2(5) ,
    NAME varchar2(200) ,
    MIN_LIMIT number,
    MAX_LIMIT number,
    APPROVE_FLAG varchar2(1)
    ); 
    j_rec1 t_data1;  

    b_rst    boolean:=false;
BEGIN 
    
   NMTR_PACKAGE.NC_WAIT_FOR_APPROVE2 (v_user,nvl(v_sys, 'PA'),v_amt,
                                      c1 );   

    LOOP
       FETCH  c1 INTO j_rec1;
        EXIT WHEN c1%NOTFOUND;
        
        if j_rec1.user_id = v_user and j_rec1.APPROVE_FLAG = nvl(v_apprv , 'Y') then
            b_rst := true;    
        end if;    

    END LOOP;    
    return b_rst;
EXCEPTION
    WHEN OTHERS THEN
        return false;        
END CHK_OWN_APPRV;

FUNCTION IS_PENDING_APPRV(v_key IN NUMBER ,v_payno IN VARCHAR2 ,o_apprv OUT VARCHAR2) RETURN BOOLEAN IS
    m_status    VARCHAR2(20);
    m_apprv    VARCHAR2(5);
BEGIN
    CHK_LAST_APPRV_STATUS(v_key,v_payno    ,m_status , m_apprv ) ;
    
    IF m_status in ('NCPAYSTS07','NCPAYSTS02') THEN -- wait approve 
        o_apprv := nvl(m_apprv,'Y');
        return true;
    ELSE
        return false;
    END IF;
END IS_PENDING_APPRV;

PROCEDURE GET_CHK_APPRV(v_key IN NUMBER ,v_payno IN VARCHAR2 ,o_send_apprv OUT VARCHAR2 ,o_apprv OUT VARCHAR2) IS
  m_apprv    varchar2(10);
  m_last_status varchar2(20);
  dummy_payno varchar2(20);
  m_is_pend    boolean;
  m_found_approved boolean;
  c_cur number;
  m_real_payno    varchar2(20);
BEGIN
    m_is_pend    := IS_PENDING_APPRV(v_key ,v_payno ,m_apprv);
    if m_is_pend then  -- งานอยู่ช่วง ขออนุมัติ 
      o_send_apprv := 'Y'; o_apprv := null;
      --:nc_mas_blk.apprv_user := :nc_mas_blk.approve_id;    --** ???????????? ?????????                      
    else
      CHK_LAST_APPRV_STATUS(v_key ,v_payno, m_last_status , m_apprv );
      m_found_approved := false;
      FOR V1 in (
            select key
            from clm_constant a
            where key like '%NCPAYSTS%' and remark2 = 'APPRV'              
      ) LOOP
          if m_last_status = V1.KEY then m_found_approved := true; end if;
      END LOOP;    
      if m_found_approved then     
          o_send_apprv :=null; o_apprv :=  'Y'; 
      else
          o_send_apprv := null; o_apprv := null;
      end if;
    end if;    
END GET_CHK_APPRV;
    
FUNCTION GET_SUM_RI_PAID_TEXT(vPayno IN VARCHAR2) RETURN VARCHAR2 IS    
    R_TEXT  VARCHAR2(1000);
    V_SHR   NUMBER;
    V_Total  NUMBER:=0;
BEGIN
    R_TEXT := null;
    for p2 in (
            select corr_seq trn_seq, ri_code ,ri_br_code ,ri_type ,lf_flag ri_lf_flag ,ri_sub_type 
            ,pay_amt ,lett_no ,lett_prt ,lett_type ,clm_no
            from mis_cri_paid a
            where pay_no =vPayno             
            and corr_seq in (select max(x.corr_seq) from mis_cri_paid x where x.pay_no = a.pay_no )        
     )
    loop
            FOR p3 IN (select ri_shr 
                from mis_cri_res r
                where clm_no = p2.CLM_NO and ri_code = p2.RI_CODE and ri_br_code = p2.RI_BR_CODE and ri_type = p2.RI_TYPE and lf_flag = p2.RI_LF_FLAG
                and ri_sub_type = p2.RI_SUB_TYPE
                and corr_seq in (select max(x.corr_seq) from mis_cri_paid x where x.clm_no = r.clm_no ) )
            LOOP               
                V_SHR := p3.ri_shr;        
            END LOOP;
            
            R_TEXT := R_TEXT||'RI_CODE: '||p2.RI_CODE||' | '||p2.RI_BR_CODE||
            ' '||NC_HEALTH_PACKAGE.RI_NAME(p2.RI_CODE ,p2.RI_BR_CODE)||
            ' SHARE: '||V_SHR||'% Amount: '||to_char(p2.PAY_AMT,'9,999,990.00') ||chr(10);   
            V_Total :=   V_Total + p2.PAY_AMT;
    end loop;      
    return 'Total: '||to_char(V_Total,'9,999,990.00')||chr(10)||RTRIM(R_TEXT,chr(10)) ;
EXCEPTION
    WHEN OTHERS THEN
        return 'Error RI '||sqlerrm;
END GET_SUM_RI_PAID_TEXT ;

FUNCTION GET_SUM_RI_PAID(vPayno IN VARCHAR2) RETURN NUMBER IS    
    V_SHR   NUMBER;
    V_Total  NUMBER(14,2):=0;
BEGIN
    for p2 in (
            select corr_seq trn_seq, ri_code ,ri_br_code ,ri_type ,lf_flag ri_lf_flag ,ri_sub_type 
            ,pay_amt ,lett_no ,lett_prt ,lett_type ,clm_no
            from mis_cri_paid a
            where pay_no =vPayno             
            and corr_seq in (select max(x.corr_seq) from mis_cri_paid x where x.pay_no = a.pay_no )        
     )
    loop
            FOR p3 IN (select ri_shr 
                from mis_cri_res r
                where clm_no = p2.CLM_NO and ri_code = p2.RI_CODE and ri_br_code = p2.RI_BR_CODE and ri_type = p2.RI_TYPE and lf_flag = p2.RI_LF_FLAG
                and ri_sub_type = p2.RI_SUB_TYPE
                and corr_seq in (select max(x.corr_seq) from mis_cri_paid x where x.clm_no = r.clm_no ) )
            LOOP               
                V_SHR := p3.ri_shr;        
            END LOOP;
            V_Total :=   V_Total + p2.PAY_AMT;
    end loop;      
    return V_Total;
    --return 'Total: '||to_char(V_Total,'9,999,990.00')||chr(10)||RTRIM(R_TEXT,chr(10)) ;
EXCEPTION
    WHEN OTHERS THEN
        return 0;
END GET_SUM_RI_PAID;

PROCEDURE GET_CURSOR_APPROVE_DATA(vWhere IN LONG ,pOut OUT NC_CLNMC908.v_ref_cursor1 ,pRST OUT VARCHAR2)  IS

    TYPE t_data1 IS RECORD
    (
    CLM_NO    VARCHAR2(20),
    PAY_NO    VARCHAR2(20),
    CLM_DATE    DATE,
    LOSS_DATE    DATE,
    PAYEE_CODE    VARCHAR2(20),
    PAYEE_NAME    VARCHAR2(250),
    PAY_TYPE    VARCHAR2(20),
    ACC_NO    VARCHAR2(20),
    ACC_NAME    VARCHAR2(250),
    BANK_NAME    VARCHAR2(250),
    HOSPITAL_NAME    VARCHAR2(250),
    PAID_AMT  NUMBER,
    PAYEE_AMT NUMBER,
    RE_TXT    VARCHAR2(500),
    SEND_TITLE    VARCHAR2(250),
    ADDR1    VARCHAR2(250),
    ADDR2    VARCHAR2(250)
    ); 
    j_rec1 t_data1; 
    
    C0 v_ref_cursor1;
    TYPE t_data0 IS RECORD
    (
    PAY_NO    VARCHAR2(20)
    ); 
    j_rec0 t_data0; 

    vCLM_NO    VARCHAR2(20);
    vPAY_NO    VARCHAR2(20);
    vCLM_DATE    DATE;
    vLOSS_DATE    DATE;
    vPAYEE_CODE    VARCHAR2(20);
    vPAYEE_NAME    VARCHAR2(250);
    vPAY_TYPE    VARCHAR2(20);
    vACC_NO    VARCHAR2(20);
    vACC_NAME    VARCHAR2(250);
    vBANK_NAME    VARCHAR2(250);
    vHOSPITAL_NAME    VARCHAR2(250);
    vPAID_AMT  NUMBER;
    vPAYEE_AMT NUMBER;
    vRE_TXT    VARCHAR2(500);
    vSEND_TITLE    VARCHAR2(250);
    vADDR1    VARCHAR2(250);
    vADDR2    VARCHAR2(250);
    vSettle     VARCHAR2(20);
    vBank_code  VARCHAR2(20);
    v_Bank_Name  VARCHAR2(250);
    vBranch_Name  VARCHAR2(250);
        
    qry_str CLOB;
    qry_where LONG;    
    qry_return  CLOB;
BEGIN
    if vWhere is null then
        qry_where := ' ''X'' ' ;
        
        qry_return := '  SELECT  '''' CLM_NO ,'''' PAY_NO , ''''  CLM_DATE  ,''''  LOSS_DATE ,''''  PAYEE_CODE  ,''''  PAYEE_NAME  ,''''  PAY_TYPE  , '
           ||' '''' ACC_NO  , ''''  ACC_NAME  , ''''  BANK_NAME  ,''''   HOSPITAL_NAME , 0  PAID_AMT  ,0 PAYEE_AMT ,''''    RE_TXT  ,'
           ||' '''' SEND_TITLE  , ''''  ADDR1  , ''''  ADDR2  from DUAL ';
        NC_CLNMC908.GEN_CURSOR(qry_return , pOut);   
        pRST :=  'NOT Found Data'; return ;
    else
        qry_where :=  vWhere ;    
    end if;
    qry_return := null;
    qry_str := 'select pay_no from mis_clm_paid a
                    where  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
                    where b.pay_no = a.pay_no
                    group by b.pay_no) and a.pay_no in ( '
                    ||qry_where
                    ||' ) ' ;
      
     NC_CLNMC908.GEN_CURSOR(qry_str , C0);
     
    LOOP  -- get Master Data
    FETCH  C0 INTO j_rec0;
    EXIT WHEN C0%NOTFOUND;
        vCLM_NO    := null;
        vPAY_NO    := null;
        vCLM_DATE    := null;
        vLOSS_DATE    := null;
        vPAYEE_CODE    := null;
        vPAYEE_NAME    := null;
        vPAY_TYPE    := null;
        vACC_NO    := null;
        vACC_NAME    := null;
        vBANK_NAME    := null;
        vHOSPITAL_NAME    := null;
        vPAID_AMT  := null;
        vPAYEE_AMT := null;
        vRE_TXT    := null;
        vSEND_TITLE    := null;
        vADDR1    := null;
        vADDR2    := null;
        vSettle     := null;
        vBank_code  := null;
        v_Bank_Name  := null;
        vBranch_Name  := null;
    
        FOR X1 IN (
            select b.clm_no ,b.Pay_no ,b.payee_code ,b.payee_name ,b.payee_amt ,a.send_title ,a.send_addr1 ,a.send_addr2 
            ,a.settle, A.acc_name ,a.acc_no ,a.bank_code ,a.br_name  
            ,c.loss_date  ,c.clm_date ,a.pay_total 
            from mis_clm_paid a ,mis_clm_payee b  ,mis_clm_mas c
            where a.pay_no = b.pay_no  and a.clm_no = c.clm_no
            and a.pay_no = j_rec0.PAY_NO
            and  (a.pay_no,a.corr_seq) = (select b.pay_no,max(b.corr_seq) from mis_clm_paid b
            where b.pay_no = a.pay_no
            group by b.pay_no) and rownum=1 )
         LOOP
            vCLM_NO    := X1.clm_no;
            vPAY_NO    :=  X1.pay_no;
            vCLM_DATE    :=  X1.clm_date;
            vLOSS_DATE    := X1.loss_date;
            vPAYEE_CODE    := X1.payee_code;
            vPAYEE_NAME    := X1.payee_name;
            vSettle    := X1.settle;
            vACC_NO    := X1.acc_no;
            vACC_NAME    := X1.acc_name;
            vBank_code    := X1.bank_code;
            vBranch_Name    := X1.br_name;
--            vHOSPITAL_NAME    := X1.clm_date;
            vPAID_AMT  := X1.pay_total;
            vPAYEE_AMT := X1.payee_amt;
--            vRE_TXT    := X1.clm_date;
            vSEND_TITLE    := X1.send_title;
            vADDR1    := X1.send_addr1;
            vADDR2    := X1.send_addr2;         

            if vSettle = '1' then
                vPAY_TYPE := 'เงินสด';
            elsif vSettle = '2' then
                vPAY_TYPE := 'เช็ค';
            elsif vSettle = '3' then
                vPAY_TYPE := 'โอน';
            else
                vPAY_TYPE := 'error';
            end if;              

            if    vACC_NO is null then
                vACC_NAME := vPAYEE_NAME;
            end if;              

            FOR p3 IN (select thai_name from bank where bank_code =vBank_code and rownum=1)
            LOOP               
                v_Bank_Name := p3.thai_name;        
            END LOOP;
                        
            vBANK_NAME := v_Bank_Name||' '||vBranch_Name;
                                    
            vRE_TXT := NC_CLNMC908.GET_SUM_RI_PAID_TEXT(j_rec0.PAY_NO) ;
--            vRE_TXT := '';
                            
         END LOOP;
         
         qry_return := qry_return||'  SELECT  '''||vCLM_NO||''' CLM_NO ,  '''||vPAY_NO||''' PAY_NO , '''||vCLM_DATE||'''  CLM_DATE  ,'''||vLOSS_DATE||'''  LOSS_DATE '
           ||', '''||vPAYEE_CODE||'''  PAYEE_CODE  ,'''||vPAYEE_NAME||'''  PAYEE_NAME  ,'''||vPAY_TYPE||'''  PAY_TYPE  , '
           ||' '''||vACC_NO||''' ACC_NO  , '''||vACC_NAME||'''  ACC_NAME  , '''||vBANK_NAME||'''  BANK_NAME  ,''''   HOSPITAL_NAME '
           ||', '||vPAID_AMT||'  PAID_AMT  ,'||vPAYEE_AMT||' PAYEE_AMT ,'''||vRE_TXT||'''    RE_TXT  ,'
           ||' '''||vSEND_TITLE||''' SEND_TITLE  , '''||vADDR1||'''  ADDR1  , '''||vADDR2||'''  ADDR2  '
           ||' from DUAL UNION ';                       
    END LOOP;
    
    qry_return := rtrim(qry_return, 'UNION ') ;
--        qry_return := '  SELECT  '''' CLM_NO ,'''' PAY_NO , ''''  CLM_DATE  ,''''  LOSS_DATE ,''''  PAYEE_CODE  ,''''  PAYEE_NAME  ,''''  PAY_TYPE  , '
--           ||' '''' ACC_NO  , ''''  ACC_NAME  , ''''  BANK_NAME  ,''''   HOSPITAL_NAME , 0  PAID_AMT  ,0 PAYEE_AMT ,''''    RE_TXT  ,'
--           ||' '''' SEND_TITLE  , ''''  ADDR1  , ''''  ADDR2  from DUAL ';
    NC_CLNMC908.GEN_CURSOR(qry_return , pOut);  
    pRST :=  '';
EXCEPTION
    WHEN OTHERS THEN
        qry_return := '  SELECT  '''' CLM_NO ,'''' PAY_NO , ''''  CLM_DATE  ,''''  LOSS_DATE ,''''  PAYEE_CODE  ,''''  PAYEE_NAME  ,''''  PAY_TYPE  , '
           ||' '''' ACC_NO  , ''''  ACC_NAME  , ''''  BANK_NAME  ,''''   HOSPITAL_NAME , 0  PAID_AMT  ,0 PAYEE_AMT ,''''    RE_TXT  ,'
           ||' '''' SEND_TITLE  , ''''  ADDR1  , ''''  ADDR2  from DUAL ';
        NC_CLNMC908.GEN_CURSOR(qry_return , pOut);   
        pRST :=  'Error GET_CURSOR_APPROVE_DATA '||sqlerrm;
END GET_CURSOR_APPROVE_DATA;

FUNCTION UPDATE_STATUS(v_key IN number ,v_sys IN varchar2 ,v_sts IN varchar2 ,v_clmmen IN varchar2 ,v_remark IN varchar2 ,v_rst OUT VARCHAR2) RETURN boolean IS
    v_max_seq number:=1;
BEGIN
    
    begin
        select nvl(max(sts_seq),0)+1 into v_max_seq 
        from nc_status
        where sts_key = v_key
        and  sts_type= v_sys;            
    exception
        when no_data_found then
            v_max_seq :=1;
        when others then
            v_max_seq :=1;
    end;
            
    insert into nc_status 
    ( sts_key ,sts_seq ,sts_type ,sts_sub_type ,remark ,cuser ,cdate  )
    values     
    (  v_key ,v_max_seq ,v_sys,v_sts ,v_remark ,v_clmmen , sysdate        
    );    
         
    COMMIT;     
    return true;
         
EXCEPTION
    WHEN OTHERS THEN
        v_rst := 'error insert status:'||sqlerrm;  
        ROLLBACK;
        return false;      
END UPDATE_STATUS;

FUNCTION UPDATE_NCPAYMENT(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2  ,v_remark IN varchar2
,v_apprv_flag IN varchar2 ,v_user IN varchar2 ,v_amd_user IN varchar2 ,v_apprv_user IN varchar2 ,v_res_amt IN NUMBER ,v_rst OUT VARCHAR2) RETURN boolean IS
    v_max_seq number:=1;
    m_prodgrp    varchar2(10);
    m_prodtype    varchar2(10);
    dummy_payno        varchar2(20);
    v_send  varchar2(10);
    v_apprv_date    date;
BEGIN
        if v_sts in ('NCPAYSTS03','NCPAYSTS08','NCPAYSTS04') then
            v_apprv_date := sysdate;
        else
            v_apprv_date := null;
        end if;
        BEGIN
            select nvl(max(trn_seq),0) + 1  into v_max_seq 
            from nc_payment a
            where sts_key = v_key and pay_no = v_payno ;
                        
        exception
        when no_data_found then
            v_max_seq    := 1;
        when others then
            v_max_seq    := 1;
        END;

        BEGIN
            select amd_user into v_send
            from nc_payment a
            where pay_no = v_payno
            and trn_seq in (select max(aa.trn_seq) from nc_payment aa where aa.pay_no = a.pay_no);
                        
        exception
        when no_data_found then
            v_send    := null;
        when others then
            v_send    := null;
        END;
        
        FOR X1 in (
            select prod_grp ,prod_type -- ,'BHT'  ,1 
            from nc_mas a
            where sts_key = v_key        
        )            
        LOOP    
            m_prodgrp := x1.prod_grp ;
            m_prodtype := x1.prod_type ;
                        
        END LOOP;
        
        IF m_prodgrp is null THEN
            FOR XX1 in (
                select prod_grp ,prod_type -- ,'BHT'  ,1 
                from mis_clm_mas a
                where clm_no = v_clmno        
            )            
            LOOP    
                m_prodgrp := xx1.prod_grp ;
                m_prodtype := xx1.prod_type ;
                            
            END LOOP;
        END IF; 
       
                
            INSERT into nc_payment(clm_no ,pay_no ,clm_seq ,trn_seq ,Pay_sts ,pay_amt ,Trn_amt ,Curr_code ,Curr_rate 
            ,Sts_date ,Amd_date ,Clm_men ,Amd_user, APPROVE_ID ,approve_date , Prod_grp ,Prod_type ,SUBSYSID ,Sts_key ,Sub_type ,Type ,apprv_flag)        
             VALUES (v_clmno , v_payno ,1 ,v_max_seq, v_sts ,v_res_amt ,v_res_amt,
          'BHT',    1 ,sysdate ,sysdate  ,v_user ,v_amd_user ,v_apprv_user ,v_apprv_date
      ,m_prodgrp,m_prodtype, GET_PRODUCTID(v_clmno)  ,v_key ,'01' ,'01' ,v_apprv_flag) ; 
       
        if v_sts in ('NCPAYSTS04') then
            EMAIL_DISAPPRV_LETTER( v_clmno ,v_payno ,v_send ,v_apprv_user) ;
        end if;
        
        COMMIT;
        return true;
         
EXCEPTION
    WHEN OTHERS THEN
        v_rst := 'error insert ncpayment:'||sqlerrm;  
        ROLLBACK;
        return false;      
END UPDATE_NCPAYMENT;

FUNCTION GET_SEND_APPRV_USER(v_key IN varchar2 ,v_payno IN varchar2 ) RETURN varchar2 IS
    o_clmuser  varchar2(10);
BEGIN
            FOR C1 in (
                select clm_men
                from nc_payment a
                where sts_key = v_key and pay_no = v_payno
                and trn_seq = (select max(b.trn_seq) from nc_payment b where b.sts_key = a.sts_key and b.pay_no = a.pay_no)             
            )            
            LOOP      
                o_clmuser := C1.CLM_MEN ;
            END LOOP;
            
            return o_clmuser ;
END GET_SEND_APPRV_USER;

PROCEDURE UPDATE_MASTER_STSKEY(v_key IN number ,v_clmno IN varchar2 ,v_rst  out VARCHAR2) IS

BEGIN
    UPDATE MIS_CLM_MAS
    SET sts_key = v_key
    WHERE clm_no = v_clmno ;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        v_rst := 'error UPDATE_MASTER_STSKEY:'||sqlerrm; 
        rollback;    
END UPDATE_MASTER_STSKEY;

FUNCTION CAN_SELF_APPROVE_STATUS(vPaySTS IN VARCHAR2) RETURN BOOLEAN IS
    vApprv  varchar2(10);
BEGIN
    FOR C1 in (
        select remark2
        from clm_constant
        where key =vPaySTS
    )            
    LOOP    
        vApprv := C1.remark2;
    END LOOP;      
    IF vApprv = 'SEND' THEN
        return true;
    ELSE
        return false;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
    return false;   
END CAN_SELF_APPROVE_STATUS;

PROCEDURE UPDATE_GMCLM908(v_pay_no in VARCHAR2 , v_send_title  in VARCHAR2 , v_send_addr1  in VARCHAR2 ,v_send_addr2  in VARCHAR2 
,v_settle  in VARCHAR2 ,v_special_flag  in VARCHAR2 ,v_special_remark  in VARCHAR2 ,v_urgent_flag  in VARCHAR2 
,v_agent_mail  in VARCHAR2 ,v_agent_mail_flag  in VARCHAR2 ,v_agent_mobile_number in VARCHAR2 ,v_agent_sms_flag  in VARCHAR2 
,v_cust_mail  in VARCHAR2 ,v_cust_mail_flag  in VARCHAR2 ,v_mobile_number  in VARCHAR2 ,v_sms_flag  in VARCHAR2
,v_acc_no  in VARCHAR2 ,v_acc_name  in VARCHAR2 ,v_bank_code  in VARCHAR2 ,v_bank_br_code in VARCHAR2
) IS

BEGIN
    update clm_gm_payee a
    set send_title =v_send_title , send_addr1 = v_send_addr1 , send_addr2 = v_send_addr2
    ,paid_type = v_settle ,special_flag = v_special_flag ,special_remark = v_special_remark ,urgent_flag = v_urgent_flag
    ,agent_mail = v_agent_mail ,agent_mail_flag = v_agent_mail_flag ,agent_mobile_number = v_agent_mobile_number ,agent_sms_flag = v_agent_sms_flag
    ,cust_mail = v_cust_mail ,cust_mail_flag = v_cust_mail_flag ,mobile_number = v_mobile_number ,sms_flag = v_sms_flag
    ,acc_no =v_acc_no ,acc_name = v_acc_name
    ,bank_code  =  v_bank_code ,bank_br_code = v_bank_br_code 
    ,settle = v_settle 
    where a.pay_no = v_pay_no;                       
                    
    update mis_clmgm_paid a
    set acc_no =v_acc_no 
    ,acc_name = v_acc_name
    ,bank_code  =  v_bank_code 
    ,branch_code = v_bank_br_code 
    ,settle = v_settle
    ,paid_type = v_settle ,special_flag = v_special_flag ,special_remark = v_special_remark ,urgent_flag = v_urgent_flag
    ,agent_mail = v_agent_mail ,agent_mail_flag = v_agent_mail_flag ,agent_mobile_number = v_agent_mobile_number ,agent_sms_flag = v_agent_sms_flag
    ,cust_mail = v_cust_mail ,cust_mail_flag = v_cust_mail_flag ,mobile_number = v_mobile_number ,sms_flag = v_sms_flag
    where a.pay_no = v_pay_no; 
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    dbms_output.put_line('error '||sqlerrm);
END UPDATE_GMCLM908;

PROCEDURE UPDATE_CLCPA913(v_pay_no in VARCHAR2 , v_invalid  in VARCHAR2 , v_invalid_remark  in VARCHAR2 ) IS

BEGIN
    UPDATE MIS_CLM_PAYEE
    SET INVALID_PAYEE = v_invalid
    ,INVALID_PAYEE_REMARK = v_invalid_remark
    WHERE PAY_NO = v_pay_no ;
    COMMIT;
    
    FixMultiPayeeACC(v_pay_no);
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;    
END UPDATE_CLCPA913;

PROCEDURE UPDATE_MED_ADDR(vsts_key in NUMBER , v_send_title  in VARCHAR2 , v_send_addr1  in VARCHAR2 ,v_send_addr2  in VARCHAR2 
    ,v_special_flag  in VARCHAR2 ,v_special_remark  in VARCHAR2 
    ,v_agent_mail  in VARCHAR2 ,v_agent_mail_flag  in VARCHAR2 ,v_agent_mobile_number in VARCHAR2 ,v_agent_sms_flag  in VARCHAR2 
    ,v_cust_mail  in VARCHAR2 ,v_cust_mail_flag  in VARCHAR2 ,v_mobile_number  in VARCHAR2 ,v_sms_flag  in VARCHAR2
    ) IS
    p_trnseq    NUMBER(2);
BEGIN
    BEGIN
        SELECT nvl(max(trn_seq),0)+1
        INTO p_trnseq
        FROM NC_MED_ADDR
        WHERE STS_KEy = vsts_key ;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_trnseq := 0;
    END;
    
        insert into NC_MED_ADDR (
        STS_KEY ,TRN_SEQ ,TRN_DATE ,send_title  , send_addr1   ,send_addr2   
        ,special_flag   ,special_remark   
        ,agent_mail   ,agent_mail_flag   ,agent_mobile_number  ,agent_sms_flag   
        ,cust_mail   ,cust_mail_flag   ,mobile_number   ,sms_flag            
        ) VALUES (
        vsts_key ,p_trnseq ,SYSDATE ,v_send_title  , v_send_addr1   ,v_send_addr2   
        ,v_special_flag   ,v_special_remark   
        ,v_agent_mail   ,v_agent_mail_flag   ,v_agent_mobile_number  ,v_agent_sms_flag   
        ,v_cust_mail   ,v_cust_mail_flag   ,v_mobile_number   ,v_sms_flag
        );                    
                    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    dbms_output.put_line('error '||sqlerrm);
END UPDATE_MED_ADDR;
    
FUNCTION GET_ACR_PAIDDATE(vPayNo IN VARCHAR2) RETURN DATE IS
    o_paid_date  DATE;
    o_vou_date DATE;
    o_amount NUMBER;
    o_pay_method VARCHAR2(50);
    o_chq_no VARCHAR2(50);
BEGIN
--    FOR X IN (
--        select PAY_NO from mis_clm_paid x
--        where clm_no = vCLMNo 
--        and corr_seq in (select max(xx.corr_seq) from mis_clm_paid xx where xx.clm_no = x.clm_no and xx.pay_total > 0)
--        and pay_total > 0 and rownum =1
--    ) LOOP 
--        ACCOUNT.P_ACTR_PACKAGE.GET_PAYMENT_PAID_INFO(vPayNo,
--        o_vou_date, o_paid_date ,
--        o_amount, o_pay_method,
--        o_chq_no) ;
--    END LOOP;
    ACCOUNT.P_ACTR_PACKAGE.GET_PAYMENT_PAID_INFO(vPayNo,
    o_vou_date, o_paid_date ,
    o_amount, o_pay_method,
    o_chq_no) ;        
    /*
    account.p_actr_package.get_payment_paid_info(vPayNo,
                                               o_vou_date ,
                                               o_paid_date,
                                               o_amount ,
                                               o_pay_method ,
                                               o_chq_no);     */
    return o_paid_date ;                                               
END ; --GET_ACR_PAIDDATE

PROCEDURE Dupplicate_CLM(p_clm IN VARCHAR2 ,x_clmno OUT VARCHAR2) IS
 -- script Dupplicate test case for ACR_POST
    v_clmno varchar2(20):='201401002000113';
    v_payno varchar2(20);
    v_prodtype  varchar2(5);
    n_clmno varchar2(20);
    n_payno varchar2(20);
    n_stskey    number;
BEGIN
    v_clmno := p_clm;
    begin
        select prod_type ,pay_no 
        into v_prodtype ,v_payno
        from mis_clm_mas a ,mis_clm_paid b
        where a.clm_no = b.clm_no(+) and a.clm_no = v_clmno
        and (b.pay_no,corr_seq) in (select bb.pay_no ,max(bb.corr_seq) from mis_clm_paid bb where bb.pay_no=b.pay_no group by bb.pay_no);
        n_clmno :=  nc_health_package.gen_clmno(v_prodtype,'0');
        n_payno := nc_health_package.gen_payno(v_prodtype);
        n_stskey := nc_health_package.gen_stskey(v_prodtype);
    exception
        when no_data_found then
            v_prodtype := null;
        when others then
            v_prodtype := null;
    end; 
    dbms_output.put_line('clm_no= '||n_clmno||' pay_no= '||n_payno);

    Insert into MISC.MIS_CLM_MAS
   (CLM_NO
   , MAIN_CLASS, POL_NO, RECPT_SEQ, CLM_YR, POL_YR, BR_CODE, MAS_CUS_CODE, MAS_CUS_SEQ, MAS_CUS_ENQ, CUS_CODE, CUS_SEQ, CUS_ENQ, MAS_SUM_INS, RECPT_SUM_INS, TOT_RES, TOT_PAID, TOT_DEDUCT, TOT_RECOV, FR_DATE, TO_DATE, CURR_CODE, CURR_RATE, CO_TYPE, CO_RE, BKI_SHR, AGENT_CODE, TH_ENG, REG_DATE, CLM_DATE, LOSS_DATE, CLM_MEN, RECOV_STS, POL_COV, CLM_STS, ALC_RE, CLM_CURR_CODE, CLM_CURR_RATE, SHR_TYPE, AGENT_SEQ, END_SEQ, POL_RUN, CHANNEL, PROD_GRP, PROD_TYPE, CLM_BR_CODE, FAX_CLM_DATE, INVOICE, CLM_STAFF, PAID_STAFF, STS_KEY, IPD_FLAG)
   (SELECT n_clmno CLM_NO 
   , MAIN_CLASS, POL_NO, RECPT_SEQ, CLM_YR, POL_YR, BR_CODE, MAS_CUS_CODE, MAS_CUS_SEQ, MAS_CUS_ENQ, CUS_CODE, CUS_SEQ, CUS_ENQ, MAS_SUM_INS, RECPT_SUM_INS, TOT_RES, TOT_PAID, TOT_DEDUCT, TOT_RECOV, FR_DATE, TO_DATE, CURR_CODE, CURR_RATE, CO_TYPE, CO_RE, BKI_SHR, AGENT_CODE, TH_ENG, REG_DATE, CLM_DATE, LOSS_DATE, CLM_MEN, RECOV_STS, POL_COV, CLM_STS, ALC_RE, CLM_CURR_CODE, CLM_CURR_RATE, SHR_TYPE, AGENT_SEQ, END_SEQ, POL_RUN, CHANNEL, PROD_GRP, PROD_TYPE, CLM_BR_CODE, FAX_CLM_DATE, INVOICE, CLM_STAFF, PAID_STAFF, n_stskey STS_KEY, IPD_FLAG
   FROM MIS_CLM_MAS
   WHERE CLM_NO = v_clmno
   )
    ;
    dbms_output.put_line('pass MIS_CLM_MAS');
    
    Insert into ALLCLM.MIS_CLM_MAS_SEQ
       (CLM_NO, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE, TOT_RES, TOT_PAID, CLM_STS)
      (SELECT n_clmno, POL_NO, POL_RUN, CORR_SEQ, CORR_DATE, CHANNEL, PROD_GRP, PROD_TYPE, CLM_DATE, TOT_RES, TOT_PAID, CLM_STS
      FROM MIS_CLM_MAS_SEQ 
      WHERE CLM_NO = v_clmno)
        ;
    dbms_output.put_line('pass MIS_CLM_MAS_SEQ');
    
    Insert into MISC.MIS_CPA_RES
       (CLM_NO, FLEET_SEQ, RES_SEQ, RES_DATE, LOSS_NAME, LOSS_DATE, RISK_CODE, PREM_CODE1, PREM_CODE4, PREM_CODE6, PREM_CODE7, PREM_CODE8, PREM_CODE9, PREM_PAY6, RES_TYPE, RES_STS, RES_FLAG, REVISE_SEQ, CORR_DATE, DIS_CODE, HPT_CODE, RES_REMARK, HPT_SEQ)
       (SELECT n_clmno, FLEET_SEQ, RES_SEQ, RES_DATE, LOSS_NAME, LOSS_DATE, RISK_CODE, PREM_CODE1, PREM_CODE4, PREM_CODE6, PREM_CODE7, PREM_CODE8, PREM_CODE9, PREM_PAY6, RES_TYPE, RES_STS, RES_FLAG, REVISE_SEQ, CORR_DATE, DIS_CODE, HPT_CODE, RES_REMARK, HPT_SEQ
       FROM MIS_CPA_RES 
      WHERE CLM_NO = v_clmno
       )
       ;

    dbms_output.put_line('pass MIS_CPA_RES');    
    
Insert into MISC.MIS_CRI_RES
   (CLM_NO, RI_CODE, RI_BR_CODE, RI_TYPE, RI_RES_DATE, RI_RES_AMT, RI_SHR, LETT_NO, LETT_PRT, LETT_TYPE, RES_STS, CORR_SEQ, LF_FLAG, RI_SUB_TYPE)
   (SELECT n_clmno, RI_CODE, RI_BR_CODE, RI_TYPE, RI_RES_DATE, RI_RES_AMT, RI_SHR, LETT_NO, LETT_PRT, LETT_TYPE, RES_STS, CORR_SEQ, LF_FLAG, RI_SUB_TYPE
   FROM MIS_CRI_RES
   WHERE CLM_NO = v_clmno);

    dbms_output.put_line('pass MIS_CRI_RES');        
    

Insert into MISC.MIS_CPA_PAID
   (CLM_NO, PAY_NO, PAY_STS, FLEET_SEQ, LOSS_NAME, LOSS_DATE, PAID_REMARK, PREM_CODE1, PREM_CODE4, PREM_CODE6, PREM_CODE7, PREM_CODE8, PREM_CODE9, PREM_PAY6, RISK_CODE, RUN_SEQ, CORR_SEQ, DIS_CODE, HPT_CODE, HPT_SEQ)
   (SELECT n_clmno, n_payno, PAY_STS, FLEET_SEQ, LOSS_NAME, LOSS_DATE, PAID_REMARK, PREM_CODE1, PREM_CODE4, PREM_CODE6, PREM_CODE7, PREM_CODE8, PREM_CODE9, PREM_PAY6, RISK_CODE, RUN_SEQ, CORR_SEQ, DIS_CODE, HPT_CODE, HPT_SEQ
   FROM MIS_CPA_PAID
   WHERE CLM_NO = v_clmno )
    ;
    dbms_output.put_line('pass MIS_CPA_PAID');        
    
   Insert into MISC.MIS_CLM_PAID
   (CLM_NO, PAY_NO
   , PAY_STS, PAY_TOTAL, PART, SETTLE, PAY_TYPE, PRT_FLAG, CORR_SEQ, CORR_DATE, STATE_FLAG, REC_PAY_DATE, SEND_TITLE, SEND_ADDR1, SEND_ADDR2
   ,CUST_MAIL_FLAG ,CUST_MAIL ,MOBILE_NUMBER ,SMS_FLAG
              ,AGENT_MAIL_FLAG ,AGENT_MAIL ,AGENT_SMS_FLAG ,AGENT_MOBILE_NUMBER
              ,SPECIAL_FLAG ,SPECIAL_REMARK ,URGENT_FLAG)
   (
   SELECT n_clmno, n_payno
   , PAY_STS, PAY_TOTAL,'' PART, SETTLE, PAY_TYPE, PRT_FLAG, CORR_SEQ, CORR_DATE, STATE_FLAG, REC_PAY_DATE, SEND_TITLE, SEND_ADDR1, SEND_ADDR2
   ,CUST_MAIL_FLAG ,CUST_MAIL ,MOBILE_NUMBER ,SMS_FLAG
              ,AGENT_MAIL_FLAG ,AGENT_MAIL ,AGENT_SMS_FLAG ,AGENT_MOBILE_NUMBER
              ,SPECIAL_FLAG ,SPECIAL_REMARK ,URGENT_FLAG
   FROM MIS_CLM_PAID
   WHERE CLM_NO = v_clmno
   );
    dbms_output.put_line('pass MIS_CLM_PAID');


Insert into MISC.MIS_CLM_PAYEE
   (CLM_NO, PAY_NO, PAY_STS, PAY_SEQ, PAYEE_TYPE, PAYEE_CODE, PAYEE_NAME, PAYEE_AMT, SETTLE, SEND_TITLE, SEND_ADDR1, SEND_ADDR2   ,CUST_MAIL_FLAG ,CUST_MAIL ,MOBILE_NUMBER ,SMS_FLAG
              ,AGENT_MAIL_FLAG ,AGENT_MAIL ,AGENT_SMS_FLAG ,AGENT_MOBILE_NUMBER
              ,SPECIAL_FLAG ,SPECIAL_REMARK ,URGENT_FLAG)
   (SELECT n_clmno, n_payno, PAY_STS, PAY_SEQ, PAYEE_TYPE, PAYEE_CODE, PAYEE_NAME, PAYEE_AMT, SETTLE, SEND_TITLE, SEND_ADDR1, SEND_ADDR2   ,CUST_MAIL_FLAG ,CUST_MAIL ,MOBILE_NUMBER ,SMS_FLAG
              ,AGENT_MAIL_FLAG ,AGENT_MAIL ,AGENT_SMS_FLAG ,AGENT_MOBILE_NUMBER
              ,SPECIAL_FLAG ,SPECIAL_REMARK ,URGENT_FLAG
              FROM MIS_CLM_PAYEE 
              WHERE  CLM_NO = v_clmno) ;
    dbms_output.put_line('pass MIS_CLM_PAYEE');

Insert into MISC.MIS_CRI_PAID
   (CLM_NO, PAY_NO, PAY_STS, RI_CODE, RI_BR_CODE, RI_TYPE, PAY_AMT, LETT_PRT, LETT_TYPE, CORR_SEQ, LF_FLAG, RI_SUB_TYPE)
   (SELECT n_clmno, n_payno, PAY_STS, RI_CODE, RI_BR_CODE, RI_TYPE, PAY_AMT, LETT_PRT, LETT_TYPE, CORR_SEQ, LF_FLAG, RI_SUB_TYPE
   FROM MIS_CRI_PAID
   WHERE  CLM_NO = v_clmno)
   ;
    dbms_output.put_line('pass MIS_CRI_PAID');


Insert into PCM.ACC_CLM_TMP
   (PROD_GRP, PROD_TYPE, PAYMENT_NO, APPOINT_DATE, CLM_NO, POL_NO, POL_RUN, POLICY_NUMBER, POL_REF, CUS_CODE, TH_ENG, AGENT_CODE, AGENT_SEQ, POST_BY, POST_DATE, BRN_CODE, DEPT_NO, DEPT_ID, DIV_ID, TEAM_ID)
   (SELECT PROD_GRP, PROD_TYPE, n_payno, APPOINT_DATE, n_clmno, POL_NO, POL_RUN, POLICY_NUMBER, POL_REF, CUS_CODE, TH_ENG, AGENT_CODE, AGENT_SEQ, POST_BY, POST_DATE, BRN_CODE, DEPT_NO, DEPT_ID, DIV_ID, TEAM_ID
   FROM ACC_CLM_TMP
   WHERE CLM_NO = v_clmno)
    ;
    dbms_output.put_line('pass ACC_CLM_TEMP');


Insert into PCM.ACC_CLM_PAYEE_TMP
   (PROD_GRP, PROD_TYPE, PAYMENT_NO, SEQ, DOC_TYPE, CURR_CODE, PAYEE_AMT, PAYEE_CODE, TITLE, NAME, DEPT_NO, DEDUCT_AMT, ADV_AMT, PAID_TYPE
   ,CUST_MAIL_FLAG ,CUST_MAIL ,MOBILE_NUMBER ,SMS_FLAG
              ,AGENT_MAIL_FLAG ,AGENT_MAIL ,AGENT_SMS_FLAG ,AGENT_MOBILE_NUMBER
              ,SPECIAL_FLAG ,SPECIAL_REMARK )
   (SELECT PROD_GRP, PROD_TYPE, n_payno, SEQ, DOC_TYPE, CURR_CODE, PAYEE_AMT, PAYEE_CODE, TITLE, NAME, DEPT_NO, DEDUCT_AMT, ADV_AMT, PAID_TYPE
   ,CUST_MAIL_FLAG ,CUST_MAIL ,MOBILE_NUMBER ,SMS_FLAG
              ,AGENT_MAIL_FLAG ,AGENT_MAIL ,AGENT_SMS_FLAG ,AGENT_MOBILE_NUMBER
              ,SPECIAL_FLAG ,SPECIAL_REMARK 
              FROM ACC_CLM_PAYEE_TMP
              WHERE PAYMENT_NO =v_payno ) ;

    dbms_output.put_line('pass ACC_CLM_PAYEE_TEMP');



Insert into ALLCLM.NC_PAYMENT
   (CLM_NO, PAY_NO, CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, PROD_GRP, PROD_TYPE, SUBSYSID, STS_KEY, TYPE, SUB_TYPE)
   (SELECT n_clmno, n_payno , CLM_SEQ, TRN_SEQ, PAY_STS, PAY_AMT, TRN_AMT, CURR_CODE, CURR_RATE, STS_DATE, AMD_DATE, CLM_MEN, AMD_USER, PROD_GRP, PROD_TYPE, SUBSYSID, n_stskey, TYPE, SUB_TYPE
   FROM NC_PAYMENT WHERE CLM_NO = v_clmno);


Insert into ALLCLM.NC_STATUS
   (STS_KEY, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE)
   (SELECT n_stskey, STS_SEQ, STS_TYPE, STS_SUB_TYPE, REMARK, CUSER, CDATE
   FROM NC_STATUS 
   WHERE sts_key  in (select sts_key from nc_payment x where x.clm_no = v_clmno  )
and sts_type = 'NCPAYSTS');
        
    COMMIT;
    
    dbms_output.put_line('complete');
    x_clmno := n_clmno;
EXCEPTION
    WHEN OTHERS THEN
    dbms_output.put_line('error '||sqlerrm);
END;

PROCEDURE FixPOST_ACR IS
    vrst1   boolean;
    vrst2   boolean;
    v_return boolean;
    v_clm_men   varchar2(5);
    v_rst   varchar2(200);
    cnt number:=0;
    v_body varchar2(3000);
BEGIN
   
    -- == Update Post ACR PA 
    for p1 in ( select b.pol_no||b.pol_run policy_no ,a.clm_no ,a.pay_no  ,b.tot_paid paid_amt ,approve_date ,approve_id ,b.clm_sts 
         from nc_payment a   , mis_clm_mas b
         WHERE a.clm_no =b.clm_no(+)  
         and (a.clm_no,a.pay_no,a.trn_seq) = (select  b.clm_no,b.pay_no,max(b.trn_seq) From  nc_payment b Where  b.clm_no = a.clm_no And b.pay_no = a.pay_no group by b.clm_no,b.pay_no) 
         and subsysid = 'PA' --and a.clm_no like '2013%'  
         and a.pay_sts in ('','NCPAYSTS03')  
         and b.tot_paid > 0 and clm_sts = '6'
         and trunc(approve_date) >= trunc(sysdate)-5 )    
    loop    
        vrst2 := true;
        cnt := cnt +1;
        vrst1 := NC_HEALTH_PAID.POST_ACR_PA(p1.clm_no ,p1.pay_no ,'0000' ,v_rst);
        
        if vrst2 and vrst1 then
            dbms_output.put_line('no. '||cnt||' success clm: '||p1.clm_no);
            v_body := v_body||'update PA clm: '||p1.clm_no||'<br/>';
        else
            dbms_output.put_line('clm: '||p1.clm_no||' '||v_rst);
        end if;
    end loop;        
    
    if cnt > 0 then
    v_body := v_body||'Count: '||cnt;
    NC_HEALTH_PACKAGE.GENERATE_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com' ,'taywin.s@bangkokinsurance.com' ,'script FixPOST_ACR PA '||TO_CHAR(sysdate, 'dd/mm/yy HH:MI:SS') ,v_body ,null ,null );
    end if;
    
    cnt := 0;
    v_body:=null;
    
    -- == Update Post ACR GM 
    for p1 in ( select b.pol_no||b.pol_run policy_no ,a.clm_no ,a.pay_no  ,b.tot_paid paid_amt ,approve_date ,approve_id ,b.clm_sts 
         from nc_payment a   , mis_clm_mas b
         WHERE a.clm_no =b.clm_no(+)  
         and (a.clm_no,a.pay_no,a.trn_seq) = (select  b.clm_no,b.pay_no,max(b.trn_seq) From  nc_payment b Where  b.clm_no = a.clm_no And b.pay_no = a.pay_no group by b.clm_no,b.pay_no) 
         and subsysid = 'GM' --and a.clm_no like '2013%'  
         and a.pay_sts in ('','NCPAYSTS03')  
         and b.tot_paid > 0 and clm_sts = '6'
         and trunc(approve_date) >= trunc(sysdate)-5 )    
    loop    
        vrst2 := true;
        cnt := cnt +1;
        vrst1 := NC_HEALTH_PAID.POST_ACR_GM(p1.clm_no ,p1.pay_no ,'0000' ,v_rst);
        
        if vrst2 and vrst1 then
            dbms_output.put_line('no. '||cnt||' success clm: '||p1.clm_no);
            v_body := v_body||'update GM clm: '||p1.clm_no||'<br/>';
        else
            dbms_output.put_line('clm: '||p1.clm_no||' '||v_rst);
        end if;
    end loop;        
    
    if cnt > 0 then
    v_body := v_body||'Count: '||cnt;
    NC_HEALTH_PACKAGE.GENERATE_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com' ,'taywin.s@bangkokinsurance.com' ,'script FixPOST_ACR GM '||TO_CHAR(sysdate, 'dd/mm/yy HH:MI:SS') ,v_body ,null ,null );
    end if;
    
END FixPOST_ACR;

PROCEDURE FixPOST_ACR_PAIDTYPE IS
    vrst1   boolean;
    vrst2   boolean;
    v_clm_men   varchar2(5);
    v_payeetype varchar2(5);
    v_rst   varchar2(200);
    o_contact_name varchar2(200);
    o_addr1 varchar2(200);
    o_addr2 varchar2(200);
    o_mobile varchar2(200);
    o_email varchar2(200);
    mail_flag    varchar2(5);
    v_paid_type  varchar2(5);
BEGIN
    for px in (select payment_no ,payee_code ,title||' '||name payee_name ,acc_no ,cust_mail ,cust_mail_flag
        from acc_clm_payee_tmp a 
        where prod_grp = '0'
        and prod_type in (select prod_type from clm_grp_prod where sysid in ('GM','PA') )
        and substr(payment_no,1,4) = to_char(sysdate , 'YYYY')
        and paid_type is null )    
    loop    
        dbms_output.put_line('payno: '||px.payment_no||' payee= '||px.payee_name);
        begin 
            select payee_type into v_payeetype
            from acc_payee
            where payee_code = px.payee_code ;
        exception 
            when no_data_found then
                v_payeetype := null;
            when others then
                v_payeetype := null;
        end;
        
        if  v_payeetype = '06' then
          nc_health_paid.get_hospital_contact(px.payee_code,
                                              null,
                                              null,
                                              o_contact_name,
                                              o_addr1 ,
                                              o_addr2 ,
                                              o_mobile ,
                                              o_email);        
            if  o_email is not null then  mail_flag  := 'Y'; else     mail_flag := null; end if;
            if px.acc_no is not null then v_paid_type := '3'; else  v_paid_type := '2'; end if;
            
            begin
                update acc_clm_payee_tmp a
                set paid_type = v_paid_type
                ,cust_mail = o_email ,cust_mail_flag = mail_flag
                where prod_grp = '0'
                and prod_type in (select prod_type from clm_grp_prod where sysid in ('GM','PA') )
                and substr(payment_no,1,4) = to_char(sysdate , 'YYYY')
                --and b.clm_no between '201401008026171' and '201401008026173'
                and payment_no= px.payment_no
                and a.paid_type is null ;       
            exception
                when others then
                rollback;
                dbms_output.put_line('error: '||sqlerrm);
                return;
            end;        
            dbms_output.put_line('fix payno: '||px.payment_no);
        end if;
        
    end loop;    
    dbms_output.put_line('success step Hospital ');
    commit;
    for p1 in (select payment_no ,payee_code ,title||' '||name payee_name ,acc_no ,cust_mail ,cust_mail_flag
        from acc_clm_payee_tmp a 
        where prod_grp = '0'
        and prod_type in (select prod_type from clm_grp_prod where sysid in ('GM') )
        and substr(payment_no,1,4) = to_char(sysdate , 'YYYY')
        and paid_type is null )    
    loop    
        dbms_output.put_line('payno: '||p1.payment_no||' payee= '||p1.payee_name);

        for p2 in (select agent_mail ,agent_mail_flag ,mobile_number ,sms_flag 
            ,cust_mail ,cust_mail_flag ,special_flag ,special_remark
                from mis_clmgm_paid a
                where  pay_no = p1.payment_no
                and corr_seq in (select max(x.corr_seq) from mis_clmgm_paid x where x.pay_no = a.pay_no)
         )    
        loop       
            --if  o_email is not null then  mail_flag  := 'Y'; else     mail_flag := null; end if;
            if p1.acc_no is not null then v_paid_type := '3'; else  v_paid_type := '2'; end if;
            
            begin
                update acc_clm_payee_tmp a
                set paid_type = v_paid_type
                ,cust_mail = p2.cust_mail ,cust_mail_flag = p2.cust_mail_flag
                ,agent_mail = p2.agent_mail ,agent_mail_flag = p2.agent_mail_flag
                ,mobile_number = p2.mobile_number , sms_flag = p2.sms_flag
                ,special_flag = p2.special_flag , special_remark = p2.special_remark
                where prod_grp = '0'
                and prod_type in (select prod_type from clm_grp_prod where sysid in ('GM','PA') )
                and substr(payment_no,1,4) = to_char(sysdate , 'YYYY')
                --and b.clm_no between '201401008026171' and '201401008026173'
                and payment_no= p1.payment_no
                and a.paid_type is null ;       
            exception
                when others then
                rollback;
                dbms_output.put_line('error: '||sqlerrm);
                return;
            end;        
            dbms_output.put_line('fix payno: '||p1.payment_no);
        end loop;
    end loop;    
    dbms_output.put_line('success not Hosp.');
    commit;
END FixPOST_ACR_PAIDTYPE;
    
PROCEDURE FixPOST_SUBSYSID IS
BEGIN
    -- update subsysid NULL --
    BEGIN
         UPDATE nc_payment
         set subsysid = 'PA'
         where subsysid is null
         and prod_type in (select prod_type from clm_grp_prod where sysid = 'PA')   ; 
         
        update acc_clm_tmp a
        set agent_seq = (select x.agent_seq from mis_mas x where x.pol_no = a.pol_no and x.pol_run = a.pol_run and rownum=1)
        where prod_grp = '0'
        and prod_type in (select prod_type from clm_grp_prod where sysid in ('GM','PA') )
        and substr(payment_no,1,4)= to_char(sysdate , 'YYYY') 
        and length(agent_seq) <2 ;
         
         COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
        dbms_output.put_line('error UPDATE nc_payment  '||sqlerrm);
    END;
    
END FixPOST_SUBSYSID;

PROCEDURE FixPOST_ACR_CUST_EMAIL IS
    v_body  varchar2(3000);
    cnt number:=0;
BEGIN
    --=== fix for Cust_mail PA
    for px in ( select payment_no ,payee_code ,name
     from acc_clm_payee_tmp a
     where substr(payment_no,1,4) =  to_char(sysdate , 'YYYY')
     and  prod_grp = '0' 
     and payee_code in (select x.payee_code from acc_payee x where payee_type = '06' )
     and cust_mail is null and paid_type is not null and acc_no is not null
     and prod_type in (select prod_type from clm_grp_prod where sysid = 'PA')
    and payment_no in (
        select pay_no from mis_clm_paid b where pay_no = a.payment_no 
        and corr_seq in (select max(bb.corr_seq) from mis_clm_paid bb where bb.pay_no = b.pay_no)
        and cust_mail is not null
     ) )    
    loop    
        dbms_output.put_line('payno: '||px.payment_no||' payee= '||px.payee_code);
        v_body := v_body||'update CustMail payno: '||px.payment_no||' payee= '||px.payee_code||' '||px.name||'<br/>';
        begin
            update acc_clm_payee_tmp a
            set cust_mail_flag = 'Y'
            ,cust_mail = (select cust_mail from mis_clm_paid b where pay_no = a.payment_no 
                                    and corr_seq in (select max(bb.corr_seq) from mis_clm_paid bb where bb.pay_no = b.pay_no)
                                    and cust_mail is not null )
            where prod_grp = '0'
            and substr(payment_no,1,4) = to_char(sysdate , 'YYYY')
            and payment_no= px.payment_no ;       
        exception
            when others then
            rollback;
            dbms_output.put_line('error: '||sqlerrm);
            NC_HEALTH_PACKAGE.GENERATE_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com' ,'taywin.s@bangkokinsurance.com' ,'error FixPOST_ACR_CUST_EMAIL PA '||TO_CHAR(sysdate, 'dd/mm/yy HH:MI:SS') ,sqlerrm ,null ,null );            
            return;
        end;           
        cnt := cnt+1;
    end loop;
    
    if cnt > 0 then
    v_body := v_body||'Count: '||cnt;
    NC_HEALTH_PACKAGE.GENERATE_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com' ,'taywin.s@bangkokinsurance.com' ,'script FixPOST_ACR_CUST_EMAIL PA '||TO_CHAR(sysdate, 'dd/mm/yy HH:MI:SS') ,v_body ,null ,null );
    end if;
    cnt := 0;
    v_body := null;

    for px in ( select payment_no ,payee_code ,name
         from acc_clm_payee_tmp a
         where substr(payment_no,1,4) =  to_char(sysdate , 'YYYY')
         and  prod_grp = '0' 
         and payee_code in (select x.payee_code from acc_payee x where payee_type = '06' )
         and cust_mail is null and paid_type is not null and acc_no is not null
         and prod_type in (select prod_type from clm_grp_prod where sysid = 'GM')
        and payment_no in (
            select pay_no from mis_clmgm_paid b where pay_no = a.payment_no 
            and corr_seq in (select max(bb.corr_seq) from mis_clmgm_paid bb where bb.pay_no = b.pay_no)
            and cust_mail is not null
         )
    )    
    loop    
        dbms_output.put_line('payno: '||px.payment_no||' payee= '||px.payee_code);
        v_body := v_body||'update CustMail payno: '||px.payment_no||' payee= '||px.payee_code||' '||px.name||'<br/>';
        begin
            update acc_clm_payee_tmp a
            set cust_mail_flag = 'Y'
            ,cust_mail = (select cust_mail  from mis_clmgm_paid b where pay_no = a.payment_no 
                                and corr_seq in (select max(bb.corr_seq) from mis_clmgm_paid bb where bb.pay_no = b.pay_no)
                                and cust_mail is not null )
            where prod_grp = '0'
            and substr(payment_no,1,4) = to_char(sysdate , 'YYYY')
            and payment_no= px.payment_no ;       
        exception
            when others then
            rollback;
            dbms_output.put_line('error: '||sqlerrm);
            NC_HEALTH_PACKAGE.GENERATE_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com' ,'taywin.s@bangkokinsurance.com' ,'error FixPOST_ACR_CUST_EMAIL GM '||TO_CHAR(sysdate, 'dd/mm/yy HH:MI:SS') ,sqlerrm ,null ,null );            
            return;
        end;           
        cnt := cnt+1;
    end loop;
    
    if cnt > 0 then
    v_body := v_body||'Count: '||cnt;
    NC_HEALTH_PACKAGE.GENERATE_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com' ,'taywin.s@bangkokinsurance.com' ,'script FixPOST_ACR_CUST_EMAIL PA '||TO_CHAR(sysdate, 'dd/mm/yy HH:MI:SS') ,v_body ,null ,null );
    end if;
    cnt := 0;
    v_body := null;

    --=== Case Agent Email
    for px in ( select payment_no ,payee_code ,name
         from acc_clm_payee_tmp a
        where substr(payment_no,1,4) =  to_char(sysdate , 'YYYY')
         and  prod_grp = '0' 
         and payee_code in (select x.payee_code from acc_payee x where payee_type <> '06' )
        -- and cust_mail is null and paid_type is not null and acc_no is not null
         and agent_mail is null
         and prod_type in (select prod_type from clm_grp_prod where sysid = 'PA')
        and payment_no in (
            select pay_no from mis_clm_paid b where pay_no = a.payment_no 
            and corr_seq in (select max(bb.corr_seq) from mis_clm_paid bb where bb.pay_no = b.pay_no)
            and agent_mail is not null
         )
    )    
    loop    
        dbms_output.put_line('payno: '||px.payment_no||' payee= '||px.payee_code);
        v_body := v_body||'update CustMail payno: '||px.payment_no||' payee= '||px.payee_code||' '||px.name||'<br/>';
        begin
            update acc_clm_payee_tmp a
            set agent_mail_flag = 'Y'
            ,agent_mail = (select agent_mail   from mis_clm_paid b where pay_no = a.payment_no 
                        and corr_seq in (select max(bb.corr_seq) from mis_clm_paid bb where bb.pay_no = b.pay_no)
                        and agent_mail is not null)
            where prod_grp = '0'
            and substr(payment_no,1,4) = to_char(sysdate , 'YYYY')
            and payment_no= px.payment_no ;       
        exception
            when others then
            rollback;
            dbms_output.put_line('error: '||sqlerrm);
            NC_HEALTH_PACKAGE.GENERATE_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com' ,'taywin.s@bangkokinsurance.com' ,'error FixPOST_ACR_AGT_EMAIL PA '||TO_CHAR(sysdate, 'dd/mm/yy HH:MI:SS') ,sqlerrm ,null ,null );            
            return;
        end;           
        cnt := cnt+1;
    end loop;
    
    if cnt > 0 then
    v_body := v_body||'Count: '||cnt;
    NC_HEALTH_PACKAGE.GENERATE_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com' ,'taywin.s@bangkokinsurance.com' ,'script FixPOST_ACR_AGT_EMAIL PA '||TO_CHAR(sysdate, 'dd/mm/yy HH:MI:SS') ,v_body ,null ,null );
    end if;
    
    commit;
    dbms_output.put_line('finish....');     
END FixPOST_ACR_CUST_EMAIL;

PROCEDURE FixPOST_ACR_INSERTLOSS_EMAIL IS
    vrst1   boolean;
    vrst2   boolean;
    v_clm_men   varchar2(5);
    v_payeetype varchar2(5);
    v_rst   varchar2(200);
    o_contact_name varchar2(200);
    o_addr1 varchar2(200);
    o_addr2 varchar2(200);
    o_mobile varchar2(200);
    o_email varchar2(200);
    tmp_email  varchar2(200);
    mail_flag    varchar2(5);
    v_paid_type  varchar2(5);
    cnt number:=0;
    v_body  varchar2(3000);
BEGIN
    for p1 in (select payment_no ,payee_code ,title||' '||name payee_name ,acc_no ,cust_mail ,cust_mail_flag
         from acc_clm_payee_tmp a
         where substr(payment_no,1,4) =  to_char(sysdate , 'YYYY')
         and  prod_grp = '0' 
        -- and prod_type in (select prod_type from clm_grp_prod where sysid = 'PA')
         and payee_code in (select x.payee_code from acc_payee x where payee_type = '06' )
         and cust_mail is null and paid_type is not null )    
    loop    
        cnt := cnt+1;
        dbms_output.put_line(cnt||' payno: '||p1.payment_no||' payee= '||p1.payee_name);
        nc_health_paid.get_hospital_contact(p1.payee_code,
                                          null,
                                          null,
                                          o_contact_name,
                                          o_addr1 ,
                                          o_addr2 ,
                                          o_mobile ,
                                          o_email);        
        IF o_email is null THEN -- user dummy email      
            BEGIN       
                select remark into tmp_email      
                from clm_constant      
                where key like 'NC_DUMMYEMAIL%' ;      
                      
                o_email := tmp_email;      
            EXCEPTION      
                WHEN NO_DATA_FOUND THEN      
                    null;      
                WHEN OTHERS THEN      
                    null;      
           END;              
        END IF;                               
        if  o_email is not null then  mail_flag  := 'Y'; else     mail_flag := null; end if;
        v_body := v_body||' no. '||cnt||' payno: '||p1.payment_no||' payee= '||p1.payee_name||' email: '||o_email||'<br/>';                    
        begin
            update acc_clm_payee_tmp a
            set cust_mail = o_email ,cust_mail_flag = mail_flag
            where prod_grp = '0'
            and prod_type in (select prod_type from clm_grp_prod where sysid in ('GM','PA') )
            and substr(payment_no,1,4) =  to_char(sysdate , 'YYYY')
            and payment_no= p1.payment_no
            and payee_code = p1.payee_code ;       
        exception
            when others then
            rollback;
            dbms_output.put_line('error: '||sqlerrm);
        end;        
        dbms_output.put_line('fix payno: '||p1.payment_no);
        
    end loop;    
    
    commit;
    dbms_output.put_line('success');
    if cnt > 0 then
    v_body := v_body||'Count: '||cnt;
    NC_HEALTH_PACKAGE.GENERATE_EMAIL('BKI_MED_ADMIN@bangkokinsurance.com' ,'taywin.s@bangkokinsurance.com' ,'script FixPOST_ACR_INSERTLOSS_EMAIL '||TO_CHAR(sysdate, 'dd/mm/yy HH:MI:SS') ,v_body ,null ,null );
    end if;    
END FixPOST_ACR_INSERTLOSS_EMAIL;  

PROCEDURE FixMultiPayeeACC(i_pay_no IN VARCHAR2 ) IS
    v_cnt   number(5);
    v_accno varchar2(20);
    v_accname varchar2(250);
    v_bank varchar2(20);
    v_branch varchar2(20);
    v_brname varchar2(250);
BEGIN
    begin
        select count(*) into v_cnt
        from mis_clm_payee a
        where pay_no = i_pay_no
        and nvl(corr_seq,0) in (select nvl(max(aa.corr_seq),0) from mis_clm_payee aa where aa.pay_no = a.pay_no);    
    exception
        when no_data_found then
            v_cnt := 0;
        when others then
            v_cnt := 0;
    end;
    
    if v_cnt > 1 then
        for x in (
            select payee_code ,settle 
            from mis_clm_payee a
            where pay_no = i_pay_no
            and nvl(corr_seq,0) in (select nvl(max(aa.corr_seq),0) from mis_clm_payee aa where aa.pay_no = a.pay_no) 
            and settle ='3'       
        ) loop
            begin
              SELECT BANK_CODE, BRANCH_CODE, ACCOUNT_NO, DECODE(ACCOUNT_NAME_TH,NULL,ACCOUNT_NAME_ENG,ACCOUNT_NAME_TH) -- ,e_mail ,mobile_sms
              into v_bank ,v_branch ,v_accno ,v_accname
              FROM  ACC_PAYEE
              WHERE PAYEE_CODE =x.payee_code;   
            exception
                when no_data_found then
                    null;
                when others then
                    null;
            end;    

            begin
                select substr(thai_brn_name,1,50)  into v_brname
                from   bank_branch
                where  bank_code =  v_bank 
                and    branch_code = v_branch;
            exception
                when no_data_found then
                    null;
                when others then
                    null;
            end;              

            begin
                update mis_clm_payee
                set acc_no = v_accno
                ,acc_name = v_accname
                ,bank_code = v_bank
                ,bank_br_code = v_branch
                ,br_name =v_brname
                where pay_no = i_pay_no and payee_code =x.payee_code;
            exception
                when others then
                    rollback; return;
            end;                    
        end loop;  
        commit;
    end if;
END FixMultiPayeeACC;

PROCEDURE EMAIL_CWP_LETTER(i_clm IN VARCHAR2 ,i_pay IN VARCHAR2 ) IS  
 v_to varchar2(1000);  
 v_cc varchar2(1000);  
 v_bcc varchar2(1000);  
 v_allcc varchar2(2000);  
 v_from varchar2(50):= 'AdminClm@bangkokinsurance.com' ;   
 v_dbins varchar2(10);  
 v_whatsys varchar2(30);  
 x_body varchar2(3000);  
 x_subject varchar2(1000);  
 x_listmail varchar2(1000);  
   
 v_logrst varchar2(200);  
 v_link varchar2(200);  
 v_clmmen varchar2(10);  
 v_remark varchar2(500);  
 v_cwpcode  varchar2(250);  
 v_clmmen_name varchar2(250);  
 v_cwp_name varchar2(250); 
 v_polno    varchar2(20);  
 v_polrun   number(10);  
 v_policy   varchar2(50);  
 v_cusname  varchar2(250);  
 v_sumins   number;  
 v_frdate   date;  
 v_todate   date;  
 v_lossdate date;  
 v_lossdetail   varchar2(500);  
 v_clmplace   varchar2(500);  
 v_cause  varchar2(250);  
 v_deptid   varchar2(5);  
 v_divid   varchar2(5);  
 v_team   varchar2(5);  
 v_position_grp   varchar2(5);  
      
 v_rst varchar2(1000);  
   
 v_cnt1 number:=0;  
   
 i_sts varchar2(10);  
BEGIN  
   
    FOR X in (  
        select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail   
        from nc_med_email a  
        where module = 'PAPH-CWP'   
        and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)  
        and direction = 'BCC' and CANCEL is null   
    ) LOOP  
        v_bcc := v_bcc || x.ldap_mail ||';' ;  
    END LOOP;  
       
    begin   
        select UPPER(substr(instance_name,1,8)) instance_name   
        into v_dbins  
        from v$instance;
           
        if v_dbins='UATBKIIN' then  
            v_whatsys := '[ระบบทดสอบ]';  
            v_link := p_claim_send_mail.get_link_bkiapp('UAT') ;  
        else   
            v_whatsys := null;  
            v_link := p_claim_send_mail.get_link_bkiapp('PROD') ;  
        end if;   
    exception   
        when no_data_found then   
            v_dbins := null;  
        when others then   
            v_dbins := null;  
    end;   
       
    BEGIN   
--        select pol_no ,pol_run , cus_name ,    mas_sum_ins ,fr_date ,to_date ,    loss_date ,loss_detail ,clm_place ,    cwp_remark ,clm_user   
--        ,(select name_th from CLM_CAUSE_STD a where a.cause_code = x.cause_code and a.cause_seq = x.cause_seq)   
--        ,(select descr from clm_constant where key = cwp_code) cwpcode   
--        into v_polno ,v_polrun , v_cusname ,v_sumins ,v_frdate ,v_todate ,v_lossdate ,v_lossdetail ,v_clmplace ,v_remark ,v_clmmen  
--        ,v_cause ,v_cwpcode  
--        from nc_mas x  
--        where clm_no = i_clm--and cwp_remark is not null   
--        ;   
        select pol_no ,pol_run , cus_enq cus_name ,    mas_sum_ins ,fr_date ,to_date ,    loss_date ,risk_descr loss_detail ,'' clm_place ,    cwp_remark ,clm_men clm_user   
        ,'' cause
        ,rem_close cwpcode   
        ,P_claim_send_mail.get_bkiuser_name(cwp_user)
        into v_polno ,v_polrun , v_cusname ,v_sumins ,v_frdate ,v_todate ,v_lossdate ,v_lossdetail ,v_clmplace ,v_remark ,v_clmmen  
        ,v_cause ,v_cwpcode  ,v_cwp_name         
        from mis_clm_mas x  
        where clm_no =i_clm--and cwp_remark is not null   
        ;                     
    --    p_acc_package.write_pol(v_policy ,v_polno ,v_polrun);  
        v_policy := v_polno||v_polrun ;  
            
        begin  
            select dept_id ,div_id ,team_id ,position_grp_id    
            into v_deptid ,v_divid ,v_team ,v_position_grp  
            from bkiuser  
            where user_id =v_clmmen ;          
                 
            v_cc := core_ldap.GET_EMAIL_FUNC(P_NON_PA_APPROVE.Get_Special_email('CC',v_clmmen)) ;  
            if  instr(v_cc,'@') = 0 then -- case not found Email from LDAP
                v_cc := '';
            end if;       
                 
            if v_position_grp >42 then -- Case Staff  
                for c1 in (select core_ldap.GET_EMAIL_FUNC(P_NON_PA_APPROVE.Get_Special_email('TO',user_id)) tl_email  
                from bkiuser  
                where dept_id = v_deptid  
                and  div_id = v_divid  
                and team_id = v_team  
                and position_grp_id in ('41','42')) loop  
                    v_to := v_to || c1.tl_email ||';' ;      
                end loop;  
            else -- Case TL up  
                v_to :=   v_cc ;      
            end if;  
        exception   
            when no_data_found then   
                null;  
            when others then   
                null;   
        end;       
        --v_cc := core_ldap.GET_EMAIL_FUNC(P_NON_PA_APPROVE.Get_Special_email('CC',v_clmmen)) ;  
        v_clmmen_name := P_claim_send_mail.get_bkiuser_name(v_clmmen);
         
    EXCEPTION   
        WHEN NO_DATA_FOUND THEN   
            NULL;  
        WHEN OTHERS THEN   
            NULL;   
    END;   
       
    if v_polno is not null then  
       
    if v_dbins='UATBKIIN' then  
        x_listmail := '<tr><td colspan=2>'||  
        '<br/>'||'<br/>'||'<br/>'||'<br/>'||'<br/>'||  
        '<p style="color:red">ถ้าเป็นระบบจริง email นี้จะส่งไปที่รายชื่อตามด้านล่าง </p><br/>'||  
        'to: '||v_to||'<br/>'||  
        'cc: '||v_cc||'<br/>'||  
        '</td></tr>';  
    end if;  
          
    x_subject := 'ใบสรุปปิดเคลมอุบัติเหตุ/สุขภาพ (CWP) เลขที่ '||i_clm||' '||v_whatsys;   
    X_BODY := '<!DOCTYPE html>'||  
    '<html lang="en">'||'<head><meta charset="utf-8">'||  
    '<title>จดหมาย CWP</title>'||'</head>'||  
    '<body bgcolor="#FFFFCC" style="font-family:''Angsana New'' ">'||  
    '<h2 align="center">ใบสรุปปิดเคลมที่ไม่มีการชดใช้ค่าสินไหมทดแทน (CWP)</h2>'||  
    '<div>'||  
    '<table align="left"><tr><td>หมายเลขกรมธรรม์'||'</td>'||  
    '<td>'||v_policy||'</td></tr>'||  
    '<tr><td>หมายเลขเรียกร้อง'||'</td>'||  
    '<td>'||i_clm||'</td></tr>'||  
    '<tr><td>ผู้เอาประกันภัย'||'</td><td>'||v_cusname||'</td>    </tr>'||  
    '<tr><td>ทุนประกันภัย/เงินจำกัดความรับผิด(บาท)'||'</td><td>'||to_char(v_sumins,'9,999,999,999,990.00')||'</td></tr>'||      
    '<tr><td>ระยะเวลาประกันภัย'||'</td><td>'||v_frdate||'  -  '||v_todate||'</td></tr>'||  
    '<tr><td>วันที่เกิดเหตุ'||'</td><td>'||v_lossdate||'</td></tr>'||  
    '<tr><td colspan="2">รายละเอียด'||'</td></tr>'||  
    '<tr><td colspan="2">'||  
    --   '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||  
     '<table align="left"><tr><td style="font-weight:bold">ลักษณะความเสียหาย'||'</td><td>'||v_lossdetail||'</td></tr>'||  
--    '<tr><td style="font-weight:bold">สาเหตุความเสียหาย'||'</td><td>'||v_cause||'</td></tr>'||  
--    '<tr><td style="font-weight:bold">สถานที่เกิดเหตุ'||'</td><td>'||v_clmplace||'</td>    </tr>'||  
    '<tr><td style="font-weight:bold">CLOSED WITHOUT PAYMENT DUE TO'||'</td><td>'||v_cwpcode||' : '||v_remark||  
    '</td></tr>'||  
    '<tr><td colspan=2>'||  
    '<br/>'||'<br/>'||
    '<p style="color:green">เจ้าของเรื่อง : '||v_clmmen_name||'</p>'||  
    '<p style="color:green">ผู้ทำ cwp : '||v_cwp_name||'</p>'||  
    '</td></tr>'||    
    x_listmail||  
    '</table>'||     
    '</td></tr></table>'||  
    '<br/>'||  
    '</div>'||   
    '</body></html>' ;  
    -- v_to := core_ldap.GET_EMAIL_FUNC(v_apprv);  
    -- v_cc := core_ldap.GET_EMAIL_FUNC(v_clmmen);   
    --    dbms_output.put_line('to: '||v_to );   
    --    dbms_output.put_line('cc: '||v_cc );   
    --    v_bcc := 'taywin.s@bangkokinsurance.com' ||';' ;  
    --    v_to :=  'taywin.s@bangkokinsurance.com' ||';' ;  
    end if;   

    dbms_output.put_line('dummy to: '||v_to );   
    dbms_output.put_line('dummy cc: '||v_cc );  
           
    if v_dbins='DBBKIINS' then  
    null;   
    else   
    v_to := v_bcc; -- for test  
    v_cc := ''; -- for test  
    end if;   
       
    dbms_output.put_line(x_body);  
       
    dbms_output.put_line('to: '||v_to );   
    dbms_output.put_line('allcc: '||v_allcc );   
    dbms_output.put_line('bcc: '||v_bcc );   
    if v_to is not null then  
    nc_health_package.generate_email(v_from, v_to ,  
    x_subject,   
    x_body   
    ,v_cc  
    ,v_bcc);   
    -- nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_NOTICE_APPRV' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_pay:'||I_pay||' success::' ,'success' ,v_rst) ;  
    end if;  
  
EXCEPTION  
 WHEN OTHERS THEN  
 --NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail Bancas' ,'Error: '||sqlerrm ,v_logrst);  
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_CWP' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_clm:'||I_clm||' error::'||sqlerrm ,'error' ,v_rst) ;  
 dbms_output.put_line('Error: '||sqlerrm );  
END EMAIL_CWP_LETTER; --email_notice bancas   
          

PROCEDURE EMAIL_DISAPPRV_LETTER(i_clm IN VARCHAR2 ,i_pay IN VARCHAR2 ,i_send IN VARCHAR  ,i_apprv IN VARCHAR2) IS  
 v_to varchar2(1000);  
 v_cc varchar2(1000);  
 v_bcc varchar2(1000);  
 v_allcc varchar2(2000);  
 v_from varchar2(50):= 'AdminClm@bangkokinsurance.com' ;   
 v_dbins varchar2(10);  
 v_whatsys varchar2(30);  
 x_body varchar2(3000);  
 x_subject varchar2(1000);  
 x_listmail varchar2(1000);  
 i_sendemail varchar2(250);  
 i_clm_men  varchar2(100);  
   
 v_logrst varchar2(200);  
 v_link varchar2(200);  
 v_clmmen varchar2(10);  
 v_remark varchar2(500);  
 v_cwpcode  varchar2(250);  
 v_clmmen_name varchar2(250);  
 v_apprv_name  varchar2(250);  
 v_cwp_name varchar2(250); 
 v_pay_descr varchar2(100); 
 v_polno    varchar2(20);  
 v_polrun   number(10);  
 v_policy   varchar2(50);  
 v_cusname  varchar2(250);  
 v_sumins   number;  
 v_frdate   date;  
 v_todate   date;  
 v_lossdate date;  
 v_lossdetail   varchar2(500);  
 v_clmplace   varchar2(500);  
 v_cause  varchar2(250);  
 v_deptid   varchar2(5);  
 v_divid   varchar2(5);  
 v_team   varchar2(5);  
 v_position_grp   varchar2(5);  
      
 v_rst varchar2(1000);  
   
 v_cnt1 number:=0;  
   
 i_sts varchar2(10);  
BEGIN  
   
    FOR X in (  
        select decode(user_id ,null ,email,core_ldap.GET_EMAIL_FUNC(user_id)) ldap_mail   
        from nc_med_email a  
        where module = 'PAPH-DISAPPRV'   
        and sub_module = (select UPPER(substr(instance_name,1,8)) instance_name from v$instance)  
        and direction = 'BCC' and CANCEL is null   
    ) LOOP  
        v_bcc := v_bcc || x.ldap_mail ||';' ;  
    END LOOP;  
       
    begin   
        select UPPER(substr(instance_name,1,8)) instance_name   
        into v_dbins  
        from v$instance;
           
        if v_dbins='UATBKIIN' then  
            v_whatsys := '[ระบบทดสอบ]';  
            v_link := p_claim_send_mail.get_link_bkiapp('UAT') ;  
        else   
            v_whatsys := null;  
            v_link := p_claim_send_mail.get_link_bkiapp('PROD') ;  
        end if;   
    exception   
        when no_data_found then   
            v_dbins := null;  
        when others then   
            v_dbins := null;  
    end;   
       
    BEGIN   

        begin 
            select remark into v_remark
            from nc_status a 
            where sts_key  in (select sts_key from nc_payment x where x.clm_no = i_clm  )
            and sts_seq in (select max(aa.sts_seq) from nc_status aa where aa.sts_key = a.sts_key)
            and sts_type = 'NCPAYSTS'
            and sts_sub_type = 'NCPAYSTS04';
        exception 
        when no_data_found then 
        null;
        when others then 
        null; 
        end; 
        i_sendemail := core_ldap.GET_EMAIL_FUNC(i_send)  ;
        if  instr(i_sendemail,'@') = 0 then -- case not found Email from LDAP
            i_sendemail := '';
            FOR Xx in (  
                select remark2 ldap_mail   
                from clm_constant a
                where key like 'APPRVPH-EMAIL%'
                and remark = i_send
                and nvl(exp_date,sysdate-1) < sysdate
            ) LOOP  
--                if  instr(xx.ldap_mail,'@') = 0 then
--                    i_sendemail := '';
--                else
--                    i_sendemail :=xx.ldap_mail ||';' ;
--                end if;
                i_sendemail :=xx.ldap_mail ||';' ;
            END LOOP;              
        else
            i_sendemail := i_sendemail||';';
        end if;              
        
        begin
            select clm_men into v_clmmen
            from mis_clm_mas
            where clm_no = i_clm ;
        exception
            when no_data_found then
                null;
            when others then
                null;
        end;  
        --v_cc := core_ldap.GET_EMAIL_FUNC(P_NON_PA_APPROVE.Get_Special_email('CC',v_clmmen)) ;  
        i_clm_men :=core_ldap.GET_EMAIL_FUNC(v_clmmen);
        if  instr(i_clm_men,'@') = 0 then
            i_clm_men := '';
        else
            i_clm_men :=i_clm_men ||';' ;
        end if;        
        v_clmmen_name := P_claim_send_mail.get_bkiuser_name(v_clmmen);
        v_apprv_name   := P_claim_send_mail.get_bkiuser_name(i_apprv);
    EXCEPTION   
        WHEN NO_DATA_FOUND THEN   
            NULL;  
        WHEN OTHERS THEN   
            NULL;   
    END;   
       
    if 1=1 then  
    
    v_pay_descr := 'ไม่อนุมัติการจ่ายค่าสินไหม'; 
    v_to := i_sendemail||''||i_clm_men;
    v_cc := core_ldap.GET_EMAIL_FUNC(i_apprv);        
    if v_dbins='UATBKIIN' then  
        x_listmail := '<tr><td colspan=2>'||  
        '<br/>'||'<br/>'||'<br/>'||'<br/>'||'<br/>'||  
        '<p style="color:red">ถ้าเป็นระบบจริง email นี้จะส่งไปที่รายชื่อตามด้านล่าง </p><br/>'||  
        'to: '||v_to||'<br/>'||  
        'cc: '||v_cc||'<br/>'||  
        'i_send: '||i_send||'<br/>'||
        '</td></tr>';  
    end if;  
          
    x_subject := 'เรื่องผลการอนุมัติการจ่ายค่าสินไหม เลขที่ '||I_clm||' '||v_whatsys; 
    x_body := '<HTML>'|| 
    '<HEAD>'|| 
    '<TITLE>Approval Non PA Claim Payment</TITLE>'|| 
    '</HEAD>'|| 
    '<BODY bgcolor=''#FFFFCC''>'|| 
    ' <font color=#0000CC><h3>ระบบ Approval PA GM Claim Payment </h3></font>'|| 
    '<P>'|| 
    ' ถึง คุณ '||v_clmmen_name ||'<br />'|| 
    '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'|| 
    'ตามที่ท่านได้ขออนุมัติงานผ่านทางระบบ '||'<font color=#009900>'||' Approval PA GM Claim Payment '||'</font>'||' ขณะนี้ '||'<br />'|| 
    'ผลการขออนุมัติของท่าน คือ '||'<font color=#FF0000>'||v_pay_descr||'</font>'||' <br/>'|| 
    'ซึ่งส่งมาจาก คุณ '||v_apprv_name||' <br/>'|| 
    'หมายเหตุ : '||v_remark||' <br/>'|| 
    'ท่านสามารถตรวจสอบได้ที่ ระบบ Approval PA GM Claim Payment'|| 
    '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp; <br/>'|| 
    '<font color=#0033CC >'||'Claim No. : '||'</font>'||'<font color=#CC0000>'||I_clm||'</font>'|| 
    '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'|| 
    '<font color=#0033CC>'||'Payment No. : '||'</font>'||'<font color=#CC0000>'||I_pay||'</font>'|| 
    '</P>'|| 
    '<hr/>'|| 
    '<P>'|| 
    x_listmail||
--    '&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'&'||'nbsp;'||'กรุณาเข้าระบบ Approval Non PA Claim Payment '||' บน '||'&'||'nbsp;'||'&'||'nbsp;'|| 
--    '<span style ="color=#0033CC; font-weight=bold">'||'<A HREF="'||v_link||'">BKI App On Web'||'</A>'||'</span>'|| '&'||'nbsp;'||'&'||'nbsp;'||'เพื่อรับทราบผลการพิจารณา'|| 
--    '</P>'|| 
    '</BODY>'|| 
    '</HTML>'; 

    end if;
       
    if v_dbins='DBBKIINS' then  
    null;   
    else   
    v_to := v_bcc; -- for test  
    v_cc := ''; -- for test  
    end if;   
       
    dbms_output.put_line(x_body);  
       
    dbms_output.put_line('dummy to: '||v_to );   
    dbms_output.put_line('allcc: '||v_allcc );   
    dbms_output.put_line('dummy cc: '||v_cc );   
    dbms_output.put_line('bcc: '||v_bcc );   
    if v_to is not null then  
    nc_health_package.generate_email(v_from, v_to ,  
    x_subject,   
    x_body   
    ,v_cc  
    ,v_bcc);   
    -- nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_NOTICE_APPRV' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_pay:'||I_pay||' success::' ,'success' ,v_rst) ;  
    end if;  
  
EXCEPTION  
 WHEN OTHERS THEN  
 --NC_HEALTH_PACKAGE.WRITE_LOG('EMAIL' ,'DB Package mail Bancas' ,'Error: '||sqlerrm ,v_logrst);  
 nc_health_paid.WRITE_LOG('NC_APPROVE' ,'PACK','EMAIL_DISAPP' ,'step: send email ' ,'v_to:'||v_to||' v_cc:'||v_cc||' I_clm:'||I_clm||' error::'||sqlerrm ,'error' ,v_rst) ;  
 dbms_output.put_line('Error: '||sqlerrm );  
END EMAIL_DISAPPRV_LETTER; --email_notice bancas   
          
END NC_CLNMC908;
/

