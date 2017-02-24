CREATE OR REPLACE PACKAGE BODY ALLCLM."NMTR_PACKAGE" IS

/******************************************************************************
   NAME:       NMTR_PAPERLESS
   PURPOSE: Get Authurized NonMotorClaim User for Approve payment

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        14/6/2011   Taywin          1. Created this package.
******************************************************************************/
PROCEDURE SET_CLM_GM_RECOV(P_CLM_NO IN VARCHAR2 ,P_PAY_NO IN VARCHAR2 ,P_REC_AMT IN NUMBER
,V_RESULT OUT VARCHAR2 ) IS  /* V_RESULT = null ??? complete */
    v_fleet_seq number(4);
    v_sub_seq   number(4);
    v_fam_seq     number(4);
BEGIN
    V_RESULT := null;
    BEGIN
        select fleet_seq ,sub_seq ,fam_seq
        into   v_fleet_seq ,v_sub_seq ,v_fam_seq
        from clm_gm_paid a
        where clm_no = P_CLM_NO and pay_no = P_PAY_NO
        and corr_seq = (select max(corr_seq) from clm_gm_paid x where x.clm_no = a.clm_no group by x.clm_no)
        and rownum=1 ;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_fleet_seq := 0; v_sub_seq := 0; v_fam_seq := 0;
        WHEN OTHERS THEN
            v_fleet_seq := 0; v_sub_seq := 0; v_fam_seq := 0;
    END;

    BEGIN
       insert into clm_gm_recov(clm_no,fleet_seq,sub_seq,fam_seq,seq,rec_amt,trn_date,
                                     due_date,recv_sts,close_flag,prt_sts,lett_type,pay_no)
       values
                                    (P_CLM_NO ,v_fleet_seq,v_sub_seq,
                                    v_fam_seq ,1,P_REC_AMT ,
                                    sysdate , sysdate+15,'0','N','1','1',P_PAY_NO);
    EXCEPTION
        WHEN OTHERS THEN
        V_RESULT := 'error insert clm_gm_recov: '||sqlerrm;
        ROLLBACK;
    END;

    BEGIN
       update mis_clm_mas
       set tot_recov = P_REC_AMT
       where  clm_no = P_CLM_NO ;
    EXCEPTION
        WHEN OTHERS THEN
        V_RESULT := 'error update tot_recov: '||sqlerrm;
        ROLLBACK;
    END;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
    V_RESULT := 'error: '||sqlerrm;
    ROLLBACK;
END; -- END SET_CLM_GM_RECOV


PROCEDURE NC_WAIT_FOR_APPROVE(P_POSITION IN VARCHAR2,
                                                        P_SUBSYSID IN VARCHAR2,
                                                        P_LOSS_AMT IN NUMBER,
                            P_USER_ID  OUT v_ref_cursor1)  IS
   WS_LOSS_AMT number;
BEGIN
/*
    WS_LOSS_AMT := 50000;
    OPEN P_USER_ID  FOR
       SELECT  DISTINCT USER_ID
       FROM   CLM_LIMIT_STD
       WHERE  WS_LOSS_AMT BETWEEN MIN_LIMIT AND MAX_LIMIT
       AND    SUBSYSID = P_SUBSYSID;
*/
  IF P_POSITION = 'STAFF' AND P_LOSS_AMT > 50000 THEN
     WS_LOSS_AMT := 50000;
     BEGIN
    OPEN P_USER_ID  FOR
       SELECT  DISTINCT USER_ID
       FROM   CLM_LIMIT_STD
       WHERE  WS_LOSS_AMT BETWEEN MIN_LIMIT AND MAX_LIMIT
       AND    SUBSYSID = P_SUBSYSID;

     EXCEPTION
       WHEN  OTHERS THEN
       OPEN P_USER_ID  FOR SELECT '' USER_ID FROM DUAL;
     END;
  ELSIF P_POSITION = 'STAFF' AND P_LOSS_AMT <= 50000 THEN
    BEGIN
    OPEN P_USER_ID  FOR
       SELECT  DISTINCT USER_ID
       FROM   CLM_LIMIT_STD
       WHERE   (P_LOSS_AMT BETWEEN MIN_LIMIT AND MAX_LIMIT OR P_LOSS_AMT <= MIN_LIMIT)
       AND    SUBSYSID = P_SUBSYSID;

    EXCEPTION
      WHEN  OTHERS THEN
        OPEN P_USER_ID  FOR SELECT '' USER_ID FROM DUAL;
    END;
  ELSIF P_POSITION = 'NSTAFF' THEN
    BEGIN
    OPEN P_USER_ID  FOR
       SELECT  DISTINCT USER_ID
       FROM   CLM_LIMIT_STD
       WHERE  P_LOSS_AMT BETWEEN MIN_LIMIT AND MAX_LIMIT
       AND    SUBSYSID = P_SUBSYSID;
    EXCEPTION
      WHEN  OTHERS THEN
      OPEN P_USER_ID  FOR SELECT '' USER_ID FROM DUAL;
    END;
  END IF;


END;


PROCEDURE NC_WAIT_FOR_APPROVE2 (P_USERID     IN     VARCHAR2,
                                P_SUBSYSID   IN     VARCHAR2,
                                P_LOSS_AMT   IN     NUMBER,
                                P_USER_ID       OUT v_ref_cursor2)
IS
   WS_LOSS_AMT   NUMBER;
   cnt_y         NUMBER := 0;
BEGIN
   BEGIN
        SELECT COUNT (*)
          INTO cnt_y
          FROM CLM_LIMIT_STD a
         WHERE     P_LOSS_AMT BETWEEN MIN_LIMIT AND MAX_LIMIT
               AND SUBSYSID = P_SUBSYSID
               --and user_id = '1728'
               --and 20000 >= (select min(m.min_limit) from clm_limit_std m where m.user_id = '1728' and m.approve_flag='Y')
               AND NVL (expire_date, TRUNC (SYSDATE)) >= TRUNC (SYSDATE)
               AND P_LOSS_AMT <=
                      (SELECT MAX (m.max_limit)
                         FROM clm_limit_std m
                        WHERE m.user_id = P_USERID AND m.approve_flag = 'Y')
               AND approve_flag = 'Y'
      ORDER BY approve_flag, max_limit, min_limit;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cnt_y := 0;
      WHEN OTHERS
      THEN
         cnt_y := 0;
   END;

   IF CNT_Y > 0
   THEN                                              -- show ????? approve = Y
      BEGIN
         OPEN P_USER_ID FOR
              SELECT distinct subsysid,
                     user_id,
                     (SELECT name || ' (' || nmtr_package.GET_ABBNAME( a.user_id) || ')'
                        FROM clm_user_std d
                       WHERE d.user_id = a.user_id)
                        name,
                     min_limit,
                     max_limit,
                     approve_flag
                FROM CLM_LIMIT_STD a
               WHERE     P_LOSS_AMT BETWEEN MIN_LIMIT AND MAX_LIMIT
                     AND SUBSYSID = P_SUBSYSID
                     --and user_id = '1728'
                     --and 20000 >= (select min(m.min_limit) from clm_limit_std m where m.user_id = '1728' and m.approve_flag='Y')
                     AND NVL (expire_date, TRUNC (SYSDATE)) >= TRUNC (SYSDATE)
                     AND P_LOSS_AMT <=
                            (SELECT MAX (m.max_limit)
                               FROM clm_limit_std m
                              WHERE m.user_id = P_USERID
                                    AND m.approve_flag = 'Y')
                     AND approve_flag = 'Y'
            ORDER BY approve_flag,
                     max_limit,
                     min_limit,
                     user_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            OPEN P_USER_ID FOR
               SELECT '' subsysid,
                      '' USER_ID,
                      '' name,
                      0 min_limit,
                      0 max_limit,
                      '' approve_flag
                 FROM DUAL;
      END;
   ELSE
      BEGIN
         OPEN P_USER_ID FOR
              SELECT distinct subsysid,
                     user_id,
                     (SELECT name || ' (' || nmtr_package.GET_ABBNAME( a.user_id) || ')'
                        FROM clm_user_std d
                       WHERE d.user_id = a.user_id)
                        name,
                     min_limit,
                     max_limit,
                     approve_flag
                FROM CLM_LIMIT_STD a
               WHERE     P_LOSS_AMT BETWEEN MIN_LIMIT AND MAX_LIMIT
                     AND SUBSYSID = P_SUBSYSID
                     AND NVL (expire_date, TRUNC (SYSDATE)) >= TRUNC (SYSDATE)
            --and user_id = '1728'
            --and 20000 >= (select min(m.min_limit) from clm_limit_std m where m.user_id = '1728' and m.approve_flag='Y')
            --and P_LOSS_AMT  <= (select max(m.max_limit) from clm_limit_std m where m.user_id = P_USERID and m.approve_flag='Y')
            --AND approve_flag = 'Y'
            ORDER BY approve_flag,
                     max_limit,
                     min_limit,
                     user_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            OPEN P_USER_ID FOR
               SELECT '' subsysid,
                      '' USER_ID,
                      '' name,
                      0 min_limit,
                      0 max_limit,
                      '' approve_flag
                 FROM DUAL;
      END;
   END IF;
END;

PROCEDURE UPDATE_OPEN_CLM(P_REG_NO IN VARCHAR2  ,V_RESULT OUT VARCHAR2) IS

BEGIN
    IF P_REG_NO is not null THEN
       if  GET_STS_OPEN(P_REG_NO) then
        UPDATE NC_REG_MAS
        SET REG_STS = '2'
        WHERE REG_NO = P_REG_NO ;

        V_RESULT := null;
        --COMMIT;
      else
         V_RESULT := 'REG_NO must have value' ;
      end if;
    ELSE
        V_RESULT := 'REG_NO must have value' ;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
    V_RESULT := 'UPDATE_OPEN_CLM error: '||sqlerrm;
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
FUNCTION nc_get_co_sumins(i_no IN VARCHAR2, i_run IN NUMBER, i_date IN DATE, i_flag IN VARCHAR2)   RETURN NUMBER IS
                v_co_sum   NUMBER := 0;
                v_end_seq  NUMBER := 0;
BEGIN
  Begin
    SELECT end_seq
       INTO  v_end_seq
      FROM mis_mas
    WHERE pol_no = i_no
        AND pol_run = i_run
    -- AND end_seq BETWEEN :sel_blk.first_end_seq AND :sel_blk.last_end_seq
       AND (((to_char(i_date, 'yyyymmdd') BETWEEN to_char(fr_date, 'yyyymmdd') AND
       to_char(to_date, 'yyyymmdd')) OR
      (to_char(i_date, 'yyyymmdd') BETWEEN to_char(nvl(fr_maint, fr_date), 'yyyymmdd') AND
        to_char(nvl(to_maint, to_date), 'yyyymmdd')) AND i_flag = 'C') OR
       (to_char(trn_date, 'yyyymmdd') <= to_char(i_date, 'yyyymmdd') AND i_flag = 'T'))
        ORDER BY end_seq;
  Exception
       when others then
                v_end_seq := 0;
  End;
  Begin
    Select sum(nvl(co_sum_ins,0))
       into  v_co_sum
      from  mis_mas
    where pol_no = i_no
       and  pol_run = i_run
       and  end_seq <= v_end_seq;
  Exception
       when others then
                v_co_sum := 0;
  End;
     RETURN (v_co_sum);
END;
FUNCTION GET_STS_OPEN(P_REG_NO IN VARCHAR2) RETURN BOOLEAN IS
   v_cnt_clm      number(3);
BEGIN
    begin
       select count(*)
          into v_cnt_clm
          from nc_mas
        where reg_no = P_REG_NO;
    exception
       when others then
                v_cnt_clm := 0;
    end;
  if v_cnt_clm = 0 then
               return(FALSE);
  else
               return(TRUE);
  end if;
EXCEPTION
  when others then
         return(FALSE);
END GET_STS_OPEN;

FUNCTION nc_get_ri_name (in_ri_code varchar2, in_br_code varchar2) RETURN varchar2 IS
                out_name  varchar2(100);
BEGIN
    begin
        select name
        into out_name
        from ri_code_std
        where ri_code = in_ri_code
        and    ri_br_code = in_br_code;
     exception
       when NO_DATA_FOUND then
                out_name := null;
       when OTHERS then
                out_name := null;
     end;
     RETURN(out_name);
END;
FUNCTION get_first_close ( v_clm_no VARCHAR2 ) RETURN date IS
      v_first_close  date := null;
    BEGIN
     begin
      select min(close_date)
        into  v_first_close
        from mis_clm_mas_seq
       where clm_no = v_clm_no
       and    close_date is not null;
     exception
       when  others   then
                 v_first_close  := null;
     end;
     return(v_first_close);
    END;

PROCEDURE nc_get_pla_no (p_pla_no out varchar2,p_message out varchar2 ) IS
BEGIN
    Begin
       select to_char(to_number(run_no) + 1)
          into p_pla_no
        from clm_control_std
      where key = 'NCPLA'||to_char(sysdate,'YYYY')  for update of key,run_no;
    exception
      when  OTHERS  then
         p_pla_no := null;
         p_message := 'Pla No. key not found';
    End;
    if   p_pla_no is not null  then
         Begin
             update clm_control_std
                   set run_no = p_pla_no
             where key = 'NCPLA'||to_char(sysdate,'YYYY') ;
         exception
             when  others  then
                       rollback;
                       p_pla_no := null;
         End;
         commit;
     end if;
END;
PROCEDURE nc_get_lsa_no (p_lsa_no out varchar2,p_message out varchar2 ) IS
BEGIN
    Begin
       select to_char(to_number(run_no) + 1)
          into p_lsa_no
        from clm_control_std
      where key = 'NCLSA'||to_char(sysdate,'YYYY')  for update of key,run_no;
    exception
      when  OTHERS  then
         p_lsa_no := null;
         p_message := 'Pla No. key not found';
    End;
    if   p_lsa_no is not null  then
         Begin
             update clm_control_std
                   set run_no = p_lsa_no
             where key = 'NCLSA'||to_char(sysdate,'YYYY') ;
         exception
             when  others  then
                       rollback;
                       p_lsa_no := null;
         End;
         commit;
     end if;
END;
PROCEDURE nc_get_cashcall (p_pol_yr in varchar2, p_clm_yr in varchar2, p_ri_code in varchar2, p_ri_br_code in varchar2, p_lf_flag in varchar2, p_ri_type1 in varchar2,
                                           p_ri_type2 in varchar2, p_ri_reserve_amt in number, p_curr_rate in number, p_out_cashcall out varchar2, p_out_lines out number) IS
                   c_cash_clm   number;
                   c_ay_uy_oy   varchar2(2);
                   c_lett_prt      varchar2(2);
                   c_ri_reserve_amt  number;
 BEGIN
    c_ri_reserve_amt := p_ri_reserve_amt * p_curr_rate;
    if  p_ri_type1 = '1'  then
       Begin
          select cash_clm,ay_uy_oy,no_of_lines
             into c_cash_clm,c_ay_uy_oy,p_out_lines
           from ri_tty
         where ri_code = p_ri_code
             and ri_br_code = p_ri_br_code
             and lf_flag = p_lf_flag
             and ri_type = p_ri_type1
             and ri_sub_type = p_ri_type2
             and year = p_pol_yr;
       exception
             when others then
                      c_cash_clm := null;
                      c_ay_uy_oy := null;
                      p_out_lines := null;
       End;       
       if (c_ay_uy_oy ='U') then
          if  c_cash_clm is null  then
              p_out_cashcall := null;       
          elsif (c_ri_reserve_amt  >=  c_cash_clm)  then
              p_out_cashcall := 'Y';
          else
              p_out_cashcall := null;
          end if;
      elsif (c_ay_uy_oy ='A') then
         Begin
            select cash_clm,ay_uy_oy,no_of_lines
               into c_cash_clm,c_ay_uy_oy,p_out_lines
              from ri_tty
            where ri_code = p_ri_code
                and ri_br_code = p_ri_br_code
                and lf_flag = p_lf_flag
                and ri_type = p_ri_type1
                and ri_sub_type = p_ri_type2
                and year in (select max(year)
                                    from ri_tty
                                  where ri_code = p_ri_code
                                      and ri_br_code = p_ri_br_code
                                      and lf_flag = p_lf_flag
                                      and ri_type = p_ri_type1
                                      and ri_sub_type = p_ri_type2);
         exception
             when others then
                      c_cash_clm := null;
                      c_ay_uy_oy := null;
                      p_out_lines := null;
         End;
         if   c_cash_clm is null  then
              p_out_cashcall := null;   
         elsif (c_ri_reserve_amt >= c_cash_clm) then
              p_out_cashcall := 'Y';
         else
             p_out_cashcall := null;
         end if;
      else
          p_out_cashcall := null;
      end if;
   elsif p_ri_type1 = '0' then
          if (c_ri_reserve_amt  >= 2000000)  then
              p_out_cashcall := 'Y';
         else
             p_out_cashcall := null;
         end if;
   else
         p_out_cashcall := null;
   end if;
 END;

PROCEDURE nc_get_ri_share (p_lossclm in number, p_lossri in number, p_rishr out number ) IS
BEGIN
  if p_lossclm > 0 and p_lossri > 0 then
       p_rishr := round((p_lossri/p_lossclm)*100,3);
  else
       p_rishr := null;
  end if;
END;

PROCEDURE nc_get_block_limit (In_blk in varchar2, out_blk_limit out number, out_fqs_limit out number) IS
BEGIN
    select blk_limit,fqs_limit
       into out_blk_limit,out_fqs_limit
     from fir_block_control
   where blk_no = In_blk;
EXCEPTION
    when no_data_found then
             out_blk_limit := 0;
             out_fqs_limit := 0;
    when others then
             out_blk_limit := 0;
             out_fqs_limit := 0;
END;
PROCEDURE nc_update_clm_sts (p_clm_no in varchar2, p_prod_grp in varchar2, p_prod_type in varchar2, p_close_type in varchar2, p_err_message out varchar2) IS
      v_close_date          date;
      v_clm_sts              varchar2(20);
      v_state_seq           number;

Begin
    p_err_message := null;
    Begin
        For nc_mas_rec in
        (
        select close_date,clm_sts
         from nc_mas
       where clm_no = p_clm_no
        ) loop

        v_clm_sts := nc_mas_rec.clm_sts;
        v_close_date := nc_mas_rec.close_date;
        if   p_prod_grp in ('2') and p_prod_type in ('222')  then
              Begin
                 update hull_clm_mas  set close_date = decode(nc_mas_rec.clm_sts,'NCCLMSTS01',null,'NCCLMSTS04',null,nc_mas_rec.close_date),
                                                      clm_sts = decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','3','NCCLMSTS03','4','NCCLMSTS04','5','1')
                 where clm_no = p_clm_no;
              exception
                 when  OTHERS  then
                           p_err_message := 'hull_clm_mas';
                           rollback;
              End;
        elsif   p_prod_grp in ('2') and p_prod_type in ('221','223')  then
                Begin
                   update mrn_clm_mas  set close_date = decode(nc_mas_rec.clm_sts,'NCCLMSTS01',null,'NCCLMSTS04',null,nc_mas_rec.close_date),
                                                         clm_sts = decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','3','NCCLMSTS04','4','1')
                  where clm_no = p_clm_no;
                exception
                when  OTHERS  then
                          p_err_message := 'mrn_clm_mas';
                         rollback;
                End;
        elsif  p_prod_grp in ('1')  then
                Begin
                   update fir_clm_mas  set close_date = decode(nc_mas_rec.clm_sts,'NCCLMSTS01',null,'NCCLMSTS04',null,nc_mas_rec.close_date),
                                                         clm_sts = decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','4','NCCLMSTS03','5','NCCLMSTS04','6','1')
                   where clm_no = p_clm_no;
                exception
                when  OTHERS  then
                          p_err_message := 'fir_clm_mas';
                          rollback;
                End;
        end if;
        End loop;
      commit;
    End;
    if   p_prod_grp in ('2') and p_prod_type in ('222')  then
         Begin
             For hull_out_rec in
             (
             select a.clm_no,a.pay_type,a.state_no,a.state_seq,a.type,a.out_date,a.out_agt,a.out_sign,out_for_amt,out_rte,out_amt,out_agt_sts
              from hull_clm_out a
            where a.clm_no = p_clm_no
               and  a.type = '01'
               and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                              from hull_clm_out b
                                                                            where b.clm_no = a.clm_no
                                                                               and  b.state_no = a.state_no
                                                                               and  b.type = a.type
                                                                               and  b.type = '01'
                                                                         group by b.clm_no,b.state_no)
             ) loop
                 v_state_seq := hull_out_rec.state_seq;
                 Begin
                       insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_agt,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                        values (hull_out_rec.clm_no,hull_out_rec.pay_type,hull_out_rec.state_no,v_state_seq+1,hull_out_rec.type,v_close_date,hull_out_rec.out_agt,
                                   hull_out_rec.out_sign,hull_out_rec.out_for_amt,hull_out_rec.out_rte,hull_out_rec.out_amt,hull_out_rec.out_agt_sts );
                        exception
                               when  OTHERS  then
                                         p_err_message := 'hull_clm_out';
                                         rollback;
                 End;
             End loop;
         commit;
         End;
    elsif  p_prod_grp in ('2') and p_prod_type in ('221','223')  then
            Begin
                For clm_out_rec in
                (
               select a.clm_no,a.out_type,a.state_no,a.state_seq,a.type,a.out_date,a.out_agt,a.out_sign,out_for_amt,out_rte,out_amt,out_agt_sts
               from mrn_clm_out a
               where a.clm_no = p_clm_no
               and  a.type = '01'
               and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                              from mrn_clm_out b
                                                                            where b.clm_no = a.clm_no
                                                                               and  b.state_no = a.state_no
                                                                               and  b.type = a.type
                                                                               and  b.type = '01'
                                                                         group by b.clm_no,b.state_no)
              ) loop
                 v_state_seq := clm_out_rec.state_seq;
                 Begin
                       insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_agt,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                        values (clm_out_rec.clm_no,clm_out_rec.out_type,clm_out_rec.state_no,v_state_seq+1,clm_out_rec.type,v_close_date,clm_out_rec.out_agt,
                                   clm_out_rec.out_sign,clm_out_rec.out_for_amt,clm_out_rec.out_rte,clm_out_rec.out_amt,clm_out_rec.out_agt_sts );
                        exception
                               when  OTHERS  then
                                         p_err_message := 'mrn_clm_out';
                                         rollback;
                 End;
              End loop;
            commit;
            End;
    elsif  p_prod_grp in ('1')  then
            Begin
                For fir_out_rec in
                (
               select a.clm_no,a.out_type,a.state_no,a.state_seq,a.type,a.out_date,a.out_sign,out_for_amt,out_rte,out_amt
               from fir_clm_out a
               where a.clm_no = p_clm_no
               and  a.type = '01'
               and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                              from fir_clm_out b
                                                                            where b.clm_no = a.clm_no
                                                                               and  b.state_no = a.state_no
                                                                               and  b.type = a.type
                                                                               and  b.type = '01'
                                                                         group by b.clm_no,b.state_no)
              ) loop
                 v_state_seq := fir_out_rec.state_seq;
                 Begin
                       insert into fir_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                        values (fir_out_rec.clm_no,fir_out_rec.out_type,fir_out_rec.state_no,v_state_seq+1,fir_out_rec.type,v_close_date,
                                   fir_out_rec.out_sign,fir_out_rec.out_for_amt,fir_out_rec.out_rte,fir_out_rec.out_amt );
                        exception
                               when  OTHERS  then
                                         p_err_message := 'fir_clm_out';
                                         rollback;
                 End;
              End loop;
            commit;
            End;
    end if;
    if      p_prod_grp in ('2') and p_prod_type in ('222')  then
            Begin
            For hull_stat_rec in
            (
                 select a.clm_no,a.state_no,a.state_seq,a.type,a.state_date,a.corr_date,a.res_amt,a.close_date,a.close_code,a.close_mark,typ_flag
                 from hull_out_stat a
               where a.clm_no = p_clm_no
                 and  a.type = '01'
                 and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                               from hull_out_stat b
                                                                             where b.clm_no = a.clm_no
                                                                                and  b.state_no = a.state_no
                                                                                and  b.type = a.type
                                                                                and  b.type = '01'
                                                                          group by b.clm_no,b.state_no)
             ) loop
             v_state_seq := hull_stat_rec.state_seq;
             Begin
                 insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,corr_date,res_amt,close_date,close_code,close_mark,typ_flag)
                  values (hull_stat_rec.clm_no,hull_stat_rec.state_no,v_state_seq+1,hull_stat_rec.type,hull_stat_rec.state_date,v_close_date,
                             hull_stat_rec.res_amt,v_close_date,'17','Y','0' );
             exception
                 when  OTHERS  then
                            p_err_message := 'hull_out_stat';
                           rollback;
             End;
         End loop;
         commit;
         End;
   elsif   p_prod_grp in ('2') and p_prod_type in ('221','223')  then
            Begin
            For out_stat_rec in
            (
                 select a.clm_no,a.state_no,a.state_seq,a.type,a.state_date,a.pa_amt,a.sur_amt,a.set_amt,a.rec_amt,a.exp_amt,a.tot_amt,a.typ_flag,a.corr_date,a.close_date,a.reopen_date
                 from mrn_out_stat a
               where a.clm_no = p_clm_no
                 and  a.type = '01'
                 and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                               from mrn_out_stat b
                                                                             where b.clm_no = a.clm_no
                                                                                and  b.state_no = a.state_no
                                                                                and  b.type = a.type
                                                                                and  b.type = '01'
                                                                          group by b.clm_no,b.state_no)
             ) loop
             v_state_seq := out_stat_rec.state_seq;
             Begin
                 insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,pa_amt,sur_amt,set_amt,rec_amt,exp_amt,tot_amt,typ_flag,corr_date,close_date,reopen_date)
                  values (out_stat_rec.clm_no,out_stat_rec.state_no,v_state_seq+1,out_stat_rec.type,out_stat_rec.state_date,out_stat_rec.pa_amt,out_stat_rec.sur_amt,out_stat_rec.set_amt,
                             out_stat_rec.rec_amt,out_stat_rec.exp_amt,out_stat_rec.tot_amt,out_stat_rec.typ_flag,v_close_date,v_close_date,out_stat_rec.reopen_date  );
             exception
                 when  OTHERS  then
                            p_err_message := 'mrn_out_stat';
                           rollback;
             End;
         End loop;
         commit;
        End;
   elsif   p_prod_grp in ('1')  then
            Begin
            For fir_stat_rec in
            (
                 select a.clm_no,a.state_no,a.state_seq,a.type,a.state_date,a.state_sts,a.corr_date,a.build_tot_sum,a.build_our_sum,a.build_tot_loss,a.build_our_loss,
                          a.mach_tot_sum,a.mach_our_sum,a.mach_tot_loss,a.mach_our_loss,a.stock_tot_sum,a.stock_our_sum,a.stock_tot_loss,a.stock_our_loss,
                          a.furn_tot_sum,a.furn_our_sum,a.furn_tot_loss,a.furn_our_loss,a.other_tot_sum,a.other_our_sum,a.other_tot_loss,a.other_our_loss,
                          a.sur_tot_loss,a.sur_our_loss,a.rec_tot_loss,a.rec_our_loss,a.set_tot_loss,a.set_our_loss,a.tot_tot_sum,a.tot_our_sum,a.tot_tot_loss,a.tot_our_loss,
                          a.close_date,a.close_code
                 from fir_out_stat a
               where a.clm_no = p_clm_no
                 and  a.type = '01'
                 and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                               from fir_out_stat b
                                                                             where b.clm_no = a.clm_no
                                                                                and  b.state_no = a.state_no
                                                                                and  b.type = a.type
                                                                                and  b.type = '01'
                                                                          group by b.clm_no,b.state_no)
             ) loop
             v_state_seq := fir_stat_rec.state_seq;
             Begin
                 insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,build_tot_sum,build_our_sum,build_tot_loss,build_our_loss,
                                mach_tot_sum,mach_our_sum,mach_tot_loss,mach_our_loss,stock_tot_sum,stock_our_sum,stock_tot_loss,stock_our_loss,
                                furn_tot_sum,furn_our_sum,furn_tot_loss,furn_our_loss,other_tot_sum,other_our_sum,other_tot_loss,other_our_loss,
                                sur_tot_loss,sur_our_loss,rec_tot_loss,rec_our_loss,set_tot_loss,set_our_loss,tot_tot_sum,tot_our_sum,tot_tot_loss,tot_our_loss,close_date,close_code)
                  values (fir_stat_rec.clm_no,fir_stat_rec.state_no,v_state_seq+1,fir_stat_rec.type,fir_stat_rec.state_date,'2',v_close_date,fir_stat_rec.build_tot_sum,fir_stat_rec.build_our_sum,
                             fir_stat_rec.build_tot_loss,fir_stat_rec.build_our_loss,fir_stat_rec.mach_tot_sum,fir_stat_rec.mach_our_sum,fir_stat_rec.mach_tot_loss,fir_stat_rec.mach_our_loss,
                             fir_stat_rec.stock_tot_sum,fir_stat_rec.stock_our_sum,fir_stat_rec.stock_tot_loss,fir_stat_rec.stock_our_loss,fir_stat_rec.furn_tot_sum,fir_stat_rec.furn_our_sum,
                             fir_stat_rec.furn_tot_loss,fir_stat_rec.furn_our_loss,fir_stat_rec.other_tot_sum,fir_stat_rec.other_our_sum,fir_stat_rec.other_tot_loss,fir_stat_rec.other_our_loss,
                             fir_stat_rec.sur_tot_loss,fir_stat_rec.sur_our_loss,fir_stat_rec.rec_tot_loss,fir_stat_rec.rec_our_loss,fir_stat_rec.set_tot_loss,fir_stat_rec.set_our_loss,
                             fir_stat_rec.tot_tot_sum,fir_stat_rec.tot_our_sum,fir_stat_rec.tot_tot_loss,fir_stat_rec.tot_our_loss,v_close_date,'10' );
             exception
                 when  OTHERS  then
                            p_err_message := 'fir_out_stat';
                           rollback;
             End;
         End loop;
         commit;
        End;
   end if;
   if   p_prod_grp in ('2') and p_prod_type in ('222')  then
        Begin
        For hull_ri_rec in
        (
            select a.clm_no,a.state_no,a.state_seq,a.type,a.ri_code,a.ri_br_code,a.ri_type1,a.lf_flag,a.ri_type2,a.ri_out_amt,a.ri_shr
             from hull_ri_out a
           where a.clm_no = p_clm_no
              and  a.type = '01'
              and  (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                             from hull_ri_out b
                                                                           where b.clm_no = a.clm_no
                                                                              and  b.state_no = a.state_no
                                                                              and  b.type = '01'
                                                                        group by b.clm_no,b.state_no)
         ) loop
             v_state_seq := hull_ri_rec.state_seq;
             Begin
                 insert into hull_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_type1,lf_flag,ri_type2,ri_out_amt,ri_shr)
                 values (hull_ri_rec.clm_no,hull_ri_rec.state_no,v_state_seq+1,hull_ri_rec.type,hull_ri_rec.ri_code,hull_ri_rec.ri_br_code,hull_ri_rec.ri_type1,
                            hull_ri_rec.lf_flag,hull_ri_rec.ri_type2,hull_ri_rec.ri_out_amt,hull_ri_rec.ri_shr);
              exception
                 when  OTHERS  then
                           p_err_message := 'hull_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    elsif  p_prod_grp in ('2') and p_prod_type in ('221','223')  then
        Begin
        For ri_out_rec in
        (
            select a.clm_no,a.state_no,a.state_seq,a.type,a.ri_code,a.ri_br_code,a.ri_type1,a.lf_flag,a.ri_type2,a.ri_out_amt
             from mrn_ri_out a
           where a.clm_no = p_clm_no
              and  a.type = '01'
              and  (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                             from mrn_ri_out b
                                                                           where b.clm_no = a.clm_no
                                                                              and  b.state_no = a.state_no
                                                                              and  b.type = '01'
                                                                        group by b.clm_no,b.state_no)
         ) loop
             v_state_seq := ri_out_rec.state_seq;
             Begin
                 insert into mrn_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_type1,lf_flag,ri_type2,ri_out_amt)
                 values (ri_out_rec.clm_no,ri_out_rec.state_no,v_state_seq+1,ri_out_rec.type,ri_out_rec.ri_code,ri_out_rec.ri_br_code,ri_out_rec.ri_type1,
                            ri_out_rec.lf_flag,ri_out_rec.ri_type2,ri_out_rec.ri_out_amt);
              exception
                 when  OTHERS  then
                           p_err_message := 'mrn_ri_out';
                           rollback;
              End;
         End loop;
         commit;
        End;
   elsif  p_prod_grp in ('1')  then
        Begin
        For fir_ri_rec in
        (
            select a.clm_no,a.state_no,a.state_seq,a.type,a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_res_amt,a.lett_no,a.lett_prt,a.cash_call
             from fir_ri_out a
           where a.clm_no = p_clm_no
              and  a.type = '01'
              and  (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                             from fir_ri_out b
                                                                           where b.clm_no = a.clm_no
                                                                              and  b.state_no = a.state_no
                                                                              and  b.type = '01'
                                                                        group by b.clm_no,b.state_no)
         ) loop
             v_state_seq := fir_ri_rec.state_seq;
             Begin
                 insert into fir_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_type,ri_lf_flag,ri_sub_type,ri_share,ri_res_amt,lett_no,lett_prt,cash_call)
                 values (fir_ri_rec.clm_no,fir_ri_rec.state_no,v_state_seq+1,fir_ri_rec.type,fir_ri_rec.ri_code,fir_ri_rec.ri_br_code,fir_ri_rec.ri_type,
                            fir_ri_rec.ri_lf_flag,fir_ri_rec.ri_sub_type,fir_ri_rec.ri_share,fir_ri_rec.ri_res_amt,fir_ri_rec.lett_no,fir_ri_rec.lett_prt,fir_ri_rec.cash_call);
              exception
                 when  OTHERS  then
                           p_err_message := 'fir_ri_out';
                           rollback;
              End;
         End loop;
         commit;
        End;
   end if;
End;
PROCEDURE nc_update_reopen_sts (p_clm_no in varchar2, p_prod_grp in varchar2, p_prod_type in varchar2, p_err_message out varchar2) IS
    v_state_seq  number;
BEGIN
    if  p_prod_grp in ('4','5','9')  then
        Begin
            For clm_mas_rec in
            (
            select a.clm_no,a.pol_no,a.pol_run,a.corr_seq,a.channel,a.prod_grp,a.prod_type,a.clm_date,a.tot_res,a.tot_paid,a.close_date
              from mis_clm_mas_seq a
              where a.clm_no = p_clm_no
              and   (a.clm_no,a.corr_seq) = (select a1.clm_no,max(a1.corr_seq) from mis_clm_mas_seq a1
                                                             where a1.clm_no = a.clm_no
                                                             group by a1.clm_no)
             ) loop
             Begin
                 update mis_clm_mas set reopen_date = sysdate, clm_sts = '4'
                 where clm_no = p_clm_no;
                 insert into mis_clm_mas_seq (clm_no,pol_no,pol_run,corr_seq,corr_date,channel,prod_grp,prod_type,clm_date,tot_res,tot_paid,close_date,reopen_date,clm_sts)
                 values (clm_mas_rec.clm_no,clm_mas_rec.pol_no,clm_mas_rec.pol_run,clm_mas_rec.corr_seq+1,sysdate,clm_mas_rec.channel,clm_mas_rec.prod_grp,
                             clm_mas_rec.prod_type,clm_mas_rec.clm_date,clm_mas_rec.tot_res,clm_mas_rec.tot_paid,clm_mas_rec.close_date,sysdate,'4');
             exception
             when  OTHERS  then
                       p_err_message := 'Misc - Error';
                       rollback;
             End;
             End loop;
        commit;
        End;
    elsif  p_prod_grp in ('1')  then
            Begin
                begin
                   update fir_clm_mas set reopen_date = sysdate, clm_sts = '6'
                   where clm_no = p_clm_no;
                exception
                   when  OTHERS  then
                             p_err_message := 'fir_clm_mas';
                             rollback;
                end;

                For fir_stat_rec in
                (
                 select a.clm_no,a.state_no,a.state_seq,a.type,a.state_date,a.state_sts,a.corr_date,a.build_tot_sum,a.build_our_sum,a.build_tot_loss,a.build_our_loss,
                          a.mach_tot_sum,a.mach_our_sum,a.mach_tot_loss,a.mach_our_loss,a.stock_tot_sum,a.stock_our_sum,a.stock_tot_loss,a.stock_our_loss,
                          a.furn_tot_sum,a.furn_our_sum,a.furn_tot_loss,a.furn_our_loss,a.other_tot_sum,a.other_our_sum,a.other_tot_loss,a.other_our_loss,
                          a.sur_tot_loss,a.sur_our_loss,a.rec_tot_loss,a.rec_our_loss,a.set_tot_loss,a.set_our_loss,a.tot_tot_sum,a.tot_our_sum,a.tot_tot_loss,a.tot_our_loss
                 from fir_out_stat a
               where a.clm_no = p_clm_no
                 and  a.type = '01'
                 and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                               from fir_out_stat b
                                                                             where b.clm_no = a.clm_no
                                                                                and  b.state_no = a.state_no
                                                                                and  b.type = a.type
                                                                                and  b.type = '01'
                                                                          group by b.clm_no,b.state_no)
                ) loop
                   v_state_seq := fir_stat_rec.state_seq;
                   Begin
                   insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,build_tot_sum,build_our_sum,build_tot_loss,build_our_loss,
                                  mach_tot_sum,mach_our_sum,mach_tot_loss,mach_our_loss,stock_tot_sum,stock_our_sum,stock_tot_loss,stock_our_loss,
                                  furn_tot_sum,furn_our_sum,furn_tot_loss,furn_our_loss,other_tot_sum,other_our_sum,other_tot_loss,other_our_loss,
                                  sur_tot_loss,sur_our_loss,rec_tot_loss,rec_our_loss,set_tot_loss,set_our_loss,tot_tot_sum,tot_our_sum,tot_tot_loss,tot_our_loss,reopen_date)
                   values (fir_stat_rec.clm_no,fir_stat_rec.state_no,v_state_seq+1,fir_stat_rec.type,fir_stat_rec.state_date,'1',sysdate,fir_stat_rec.build_tot_sum,fir_stat_rec.build_our_sum,
                             fir_stat_rec.build_tot_loss,fir_stat_rec.build_our_loss,fir_stat_rec.mach_tot_sum,fir_stat_rec.mach_our_sum,fir_stat_rec.mach_tot_loss,fir_stat_rec.mach_our_loss,
                             fir_stat_rec.stock_tot_sum,fir_stat_rec.stock_our_sum,fir_stat_rec.stock_tot_loss,fir_stat_rec.stock_our_loss,fir_stat_rec.furn_tot_sum,fir_stat_rec.furn_our_sum,
                             fir_stat_rec.furn_tot_loss,fir_stat_rec.furn_our_loss,fir_stat_rec.other_tot_sum,fir_stat_rec.other_our_sum,fir_stat_rec.other_tot_loss,fir_stat_rec.other_our_loss,
                             fir_stat_rec.sur_tot_loss,fir_stat_rec.sur_our_loss,fir_stat_rec.rec_tot_loss,fir_stat_rec.rec_our_loss,fir_stat_rec.set_tot_loss,fir_stat_rec.set_our_loss,
                             fir_stat_rec.tot_tot_sum,fir_stat_rec.tot_our_sum,fir_stat_rec.tot_tot_loss,fir_stat_rec.tot_our_loss,sysdate);
                   exception
                   when  OTHERS  then
                            p_err_message := 'fir_out_stat';
                           rollback;
                   End;
                End loop;

                For fir_out_rec in
                (
               select a.clm_no,a.out_type,a.state_no,a.state_seq,a.type,a.out_date,a.out_sign,out_for_amt,out_rte,out_amt
               from fir_clm_out a
               where a.clm_no = p_clm_no
               and  a.type = '01'
               and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                              from fir_clm_out b
                                                                            where b.clm_no = a.clm_no
                                                                               and  b.state_no = a.state_no
                                                                               and  b.type = a.type
                                                                               and  b.type = '01'
                                                                         group by b.clm_no,b.state_no)
              ) loop
                 v_state_seq := fir_out_rec.state_seq;
                 Begin
                       insert into fir_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                        values (fir_out_rec.clm_no,fir_out_rec.out_type,fir_out_rec.state_no,v_state_seq+1,fir_out_rec.type,sysdate,
                                   fir_out_rec.out_sign,fir_out_rec.out_for_amt,fir_out_rec.out_rte,fir_out_rec.out_amt );
                        exception
                               when  OTHERS  then
                                         p_err_message := 'fir_clm_out';
                                         rollback;
                 End;
              End loop;

              For fir_ri_rec in
              (
              select a.clm_no,a.state_no,a.state_seq,a.type,a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_res_amt,a.lett_no,a.lett_prt,a.cash_call
               from fir_ri_out a
              where a.clm_no = p_clm_no
              and  a.type = '01'
              and  (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                             from fir_ri_out b
                                                                           where b.clm_no = a.clm_no
                                                                              and  b.state_no = a.state_no
                                                                              and  b.type = '01'
                                                                        group by b.clm_no,b.state_no)
              ) loop
               v_state_seq := fir_ri_rec.state_seq;
               Begin
                   insert into fir_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_type,ri_lf_flag,ri_sub_type,ri_share,ri_res_amt,lett_no,lett_prt,cash_call)
                   values (fir_ri_rec.clm_no,fir_ri_rec.state_no,v_state_seq+1,fir_ri_rec.type,fir_ri_rec.ri_code,fir_ri_rec.ri_br_code,fir_ri_rec.ri_type,
                              fir_ri_rec.ri_lf_flag,fir_ri_rec.ri_sub_type,fir_ri_rec.ri_share,fir_ri_rec.ri_res_amt,fir_ri_rec.lett_no,fir_ri_rec.lett_prt,fir_ri_rec.cash_call);
                exception
                   when  OTHERS  then
                            p_err_message := 'fir_ri_out';
                            rollback;
                End;
               End loop;
             commit;
            End;
    elsif  p_prod_grp in ('2')  and p_prod_type in ('221','223')  then
            Begin
               begin
                  update mrn_clm_mas  set reopen_date = sysdate, clm_sts = '4'
                  where clm_no = p_clm_no;
               exception
               when  OTHERS  then
                      p_err_message := 'mrn_clm_mas';
                      rollback;
               end;

               For clm_out_rec in
                (
               select a.clm_no,a.out_type,a.state_no,a.state_seq,a.type,a.out_date,a.out_agt,a.out_sign,out_for_amt,out_rte,out_amt,out_agt_sts
               from mrn_clm_out a
               where a.clm_no = p_clm_no
               and  a.type = '01'
               and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                              from mrn_clm_out b
                                                                            where b.clm_no = a.clm_no
                                                                               and  b.state_no = a.state_no
                                                                               and  b.type = a.type
                                                                               and  b.type = '01'
                                                                         group by b.clm_no,b.state_no)
              ) loop
                 v_state_seq := clm_out_rec.state_seq;
                 Begin
                       insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_agt,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                        values (clm_out_rec.clm_no,clm_out_rec.out_type,clm_out_rec.state_no,v_state_seq+1,clm_out_rec.type,sysdate,clm_out_rec.out_agt,
                                   clm_out_rec.out_sign,clm_out_rec.out_for_amt,clm_out_rec.out_rte,clm_out_rec.out_amt,clm_out_rec.out_agt_sts );
                        exception
                               when  OTHERS  then
                                         p_err_message := 'mrn_clm_out';
                                         rollback;
                 End;
              End loop;

              For out_stat_rec in
              (
                 select a.clm_no,a.state_no,a.state_seq,a.type,a.state_date,a.pa_amt,a.sur_amt,a.set_amt,a.rec_amt,a.exp_amt,a.tot_amt,a.typ_flag,a.corr_date,a.close_date,a.reopen_date
                 from mrn_out_stat a
               where a.clm_no = p_clm_no
                 and  a.type = '01'
                 and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                               from mrn_out_stat b
                                                                             where b.clm_no = a.clm_no
                                                                                and  b.state_no = a.state_no
                                                                                and  b.type = a.type
                                                                                and  b.type = '01'
                                                                          group by b.clm_no,b.state_no)
               ) loop
               v_state_seq := out_stat_rec.state_seq;
               Begin
                 insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,pa_amt,sur_amt,set_amt,rec_amt,exp_amt,tot_amt,typ_flag,corr_date,reopen_date)
                  values (out_stat_rec.clm_no,out_stat_rec.state_no,v_state_seq+1,out_stat_rec.type,out_stat_rec.state_date,out_stat_rec.pa_amt,out_stat_rec.sur_amt,out_stat_rec.set_amt,
                             out_stat_rec.rec_amt,out_stat_rec.exp_amt,out_stat_rec.tot_amt,'0',sysdate,sysdate );
               exception
                 when  OTHERS  then
                            p_err_message := 'mrn_out_stat';
                           rollback;
               End;
               End loop;

               For ri_out_rec in
               (
               select a.clm_no,a.state_no,a.state_seq,a.type,a.ri_code,a.ri_br_code,a.ri_type1,a.lf_flag,a.ri_type2,a.ri_out_amt
               from mrn_ri_out a
               where a.clm_no = p_clm_no
               and  a.type = '01'
               and  (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                             from mrn_ri_out b
                                                                           where b.clm_no = a.clm_no
                                                                              and  b.state_no = a.state_no
                                                                              and  b.type = '01'
                                                                        group by b.clm_no,b.state_no)
               ) loop
               v_state_seq := ri_out_rec.state_seq;
               Begin
                 insert into mrn_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_type1,lf_flag,ri_type2,ri_out_amt)
                 values (ri_out_rec.clm_no,ri_out_rec.state_no,v_state_seq+1,ri_out_rec.type,ri_out_rec.ri_code,ri_out_rec.ri_br_code,ri_out_rec.ri_type1,
                            ri_out_rec.lf_flag,ri_out_rec.ri_type2,ri_out_rec.ri_out_amt);
               exception
                 when  OTHERS  then
                           p_err_message := 'mrn_ri_out';
                           rollback;
               End;
               End loop;
               commit;
             End;
    elsif  p_prod_grp in ('2')  and p_prod_type in ('222')  then
            Begin
              begin
                 update hull_clm_mas  set reopen_date = sysdate, clm_sts = '5'
                 where clm_no = p_clm_no;
              exception
                 when  OTHERS  then
                           p_err_message := 'hull_clm_mas';
                           rollback;
              end;

              For hull_out_rec in
              (
              select a.clm_no,a.pay_type,a.state_no,a.state_seq,a.type,a.out_date,a.out_agt,a.out_sign,out_for_amt,out_rte,out_amt,out_agt_sts
              from hull_clm_out a
              where a.clm_no = p_clm_no
               and  a.type = '01'
               and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                              from hull_clm_out b
                                                                            where b.clm_no = a.clm_no
                                                                               and  b.state_no = a.state_no
                                                                               and  b.type = a.type
                                                                               and  b.type = '01'
                                                                         group by b.clm_no,b.state_no)
               ) loop
                 v_state_seq := hull_out_rec.state_seq;
                 Begin
                       insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_agt,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                        values (hull_out_rec.clm_no,hull_out_rec.pay_type,hull_out_rec.state_no,v_state_seq+1,hull_out_rec.type,sysdate,hull_out_rec.out_agt,
                                   hull_out_rec.out_sign,hull_out_rec.out_for_amt,hull_out_rec.out_rte,hull_out_rec.out_amt,hull_out_rec.out_agt_sts );
                        exception
                               when  OTHERS  then
                                         p_err_message := 'hull_clm_out';
                                         rollback;
                 End;
               End loop;

               For hull_stat_rec in
               (
                 select a.clm_no,a.state_no,a.state_seq,a.type,a.state_date,a.corr_date,a.res_amt,a.close_date,a.close_code,a.close_mark,typ_flag
                 from hull_out_stat a
                 where a.clm_no = p_clm_no
                 and  a.type = '01'
                 and (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                               from hull_out_stat b
                                                                             where b.clm_no = a.clm_no
                                                                                and  b.state_no = a.state_no
                                                                                and  b.type = a.type
                                                                                and  b.type = '01'
                                                                          group by b.clm_no,b.state_no)
              ) loop
                v_state_seq := hull_stat_rec.state_seq;
                Begin
                 insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,corr_date,res_amt,reopen_date,close_mark,typ_flag)
                  values (hull_stat_rec.clm_no,hull_stat_rec.state_no,v_state_seq+1,hull_stat_rec.type,hull_stat_rec.state_date,sysdate,
                             hull_stat_rec.res_amt,sysdate,'N','0' );
                exception
                 when  OTHERS  then
                            p_err_message := 'hull_out_stat';
                           rollback;
                End;
             End loop;

             For hull_ri_rec in
             (
              select a.clm_no,a.state_no,a.state_seq,a.type,a.ri_code,a.ri_br_code,a.ri_type1,a.lf_flag,a.ri_type2,a.ri_out_amt,a.ri_shr
              from hull_ri_out a
              where a.clm_no = p_clm_no
              and  a.type = '01'
              and  (a.clm_no,a.state_no,a.state_seq) = (select b.clm_no,b.state_no,max(b.state_seq)
                                                                             from hull_ri_out b
                                                                           where b.clm_no = a.clm_no
                                                                              and  b.state_no = a.state_no
                                                                              and  b.type = '01'
                                                                        group by b.clm_no,b.state_no)
             ) loop
             v_state_seq := hull_ri_rec.state_seq;
             Begin
                 insert into hull_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_type1,lf_flag,ri_type2,ri_out_amt,ri_shr)
                 values (hull_ri_rec.clm_no,hull_ri_rec.state_no,v_state_seq+1,hull_ri_rec.type,hull_ri_rec.ri_code,hull_ri_rec.ri_br_code,hull_ri_rec.ri_type1,
                            hull_ri_rec.lf_flag,hull_ri_rec.ri_type2,hull_ri_rec.ri_out_amt,hull_ri_rec.ri_shr);
              exception
                 when  OTHERS  then
                           p_err_message := 'hull_ri_out';
                           rollback;
              End;
             End loop;
             commit;
            End;
    End if;
END;
PROCEDURE nc_allclm_table (p_clm_no in varchar2, p_prod_grp in varchar2, p_prod_type in varchar2, p_co_type in varchar2, p_co_re in varchar2, p_bki_shr in number,
                                           p_agent_code in varchar2, p_agent_seq in varchar2, p_insert_flag in varchar2, p_err_message out varchar2)  IS
 BEGIN
     if  p_insert_flag = 'I'  then
         if      p_prod_grp = '1'  then
                 NMTR_PACKAGE.nc_insert_fire_table (p_clm_no,p_err_message);
         elsif  p_prod_grp =  '2'  and p_prod_type in ('221','223')  then
                 NMTR_PACKAGE.nc_insert_mrn_table (p_clm_no,p_err_message);
        elsif  p_prod_grp =  '2'  and p_prod_type in ('222')  then
                 NMTR_PACKAGE.nc_insert_hull_table (p_clm_no,p_err_message);
         elsif  p_prod_grp in ('4','5','9') then
                 NMTR_PACKAGE.nc_insert_misc_table (p_clm_no, p_co_type, p_co_re, p_bki_shr, p_agent_code, p_agent_seq,p_err_message);
         end if;
     elsif  p_insert_flag = 'U'  then
              if      p_prod_grp = '1'  then
                      NMTR_PACKAGE.nc_update_fire_table (p_clm_no,p_err_message);
              elsif  p_prod_grp =  '2'  and p_prod_type in ('221','223')  then
                      NMTR_PACKAGE.nc_update_mrn_table (p_clm_no,p_err_message);
              elsif  p_prod_grp =  '2'  and p_prod_type in ('222')  then
                      NMTR_PACKAGE.nc_update_hull_table (p_clm_no,p_err_message);
              elsif  p_prod_grp in ('4','5','9') then
                      NMTR_PACKAGE.nc_update_misc_table (p_clm_no,p_err_message);
              end if;
     end if;
 END;
PROCEDURE nc_allclm_mas (p_clm_no in varchar2, p_prod_grp in varchar2, p_prod_type in varchar2, p_err_message out varchar2)  IS
 BEGIN
     if      p_prod_grp = '1'  then
             NMTR_PACKAGE.nc_update_fire_mas (p_clm_no,p_err_message);
     elsif  p_prod_grp =  '2'  and p_prod_type in ('221','223')  then
             NMTR_PACKAGE.nc_update_mrn_mas (p_clm_no,p_err_message);
     elsif  p_prod_grp =  '2'  and p_prod_type in ('222')  then
             NMTR_PACKAGE.nc_update_hull_mas (p_clm_no,p_err_message);
     elsif  p_prod_grp in ('4','5','9') then
             NMTR_PACKAGE.nc_update_misc_mas (p_clm_no,p_err_message);
     end if;
 END;
 PROCEDURE nc_insert_fire_table (v_clm_no in varchar2, v_err_message out varchar2) IS
      v_contact               varchar2(30);
      v_res_amt             number;
      v_tot_res_amt        number;
      v_fir_code              varchar2(4);
      v_state_no             varchar2(16);
      v_rec_state_no       varchar2(16);
      v_sal_state_no       varchar2(16);
      v_ded_state_no      varchar2(16);
      v_pol_te                varchar2(1);
      v_pol_br                varchar2(3);
      v_loc1                   varchar2(50);
      v_loc2                   varchar2(50);
      v_loc3                   varchar2(50);
      v_loc_am               varchar2(2);
      v_loc_jw                varchar2(2);
      v_agent_code1       varchar2(5);
      v_agent_seq1         varchar2(2);
      v_agent_code2       varchar2(5);
      v_agent_seq2         varchar2(2);
      v_agent_code3       varchar2(5);
      v_agent_seq3         varchar2(2);
      v_class1                 varchar2(1);
      v_class2                 varchar2(1);
      v_risk_exp              varchar2(4);
      v_ext_exp               varchar2(4);
      v_pol_type              varchar2(2);
      v_cus_te                 varchar2(1);
      v_co_type               varchar2(1);
      v_leader                 varchar2(1);
      v_your_pol_no        varchar2(30);
      v_your_end_no       varchar2(30);
      v_ben_code            varchar2(4);
      v_ben_descr           varchar2(100);
      v_type                    varchar2(2);
      v_out_type              varchar2(2);
      v_co_shr                number(6,3) := 0;
      v_tot_sum_bld        number(14,2) := 0;
      v_our_sum_bld       number(14,2) := 0;
      v_tot_sum_mac       number(14,2) := 0;
      v_our_sum_mac      number(14,2) := 0;
      v_tot_sum_stk         number(14,2) := 0;
      v_our_sum_stk        number(14,2) := 0;
      v_tot_sum_fur         number(14,2) := 0;
      v_our_sum_fur        number(14,2) := 0;
      v_tot_sum_oth        number(14,2) := 0;
      v_our_sum_oth       number(14,2) := 0;
      v_sum_rec_clm       number(14,2) := 0;
      v_tot_rec_clm         number(14,2) := 0;
      v_sum_rec             number(14,2) := 0;
      v_tot_rec               number(14,2) := 0;
      v_sum_sal             number(14,2) := 0;
      v_tot_sal               number(14,2) := 0;
      v_sum_ded            number(14,2) := 0;
      v_tot_ded              number(14,2) := 0;
      v_sum_bld             number(14,2) := 0;
      v_tot_bld               number(14,2) := 0;
      v_sum_mac           number(14,2) := 0;
      v_tot_mac             number(14,2) := 0;
      v_sum_stk             number(14,2) := 0;
      v_tot_stk               number(14,2) := 0;
      v_sum_fur             number(14,2) := 0;
      v_tot_fur               number(14,2) := 0;
      v_sum_oth             number(14,2) := 0;
      v_tot_oth               number(14,2) := 0;
      v_sum_sur             number(14,2) := 0;
      v_tot_sur               number(14,2) := 0;
      v_sum_set             number(14,2) := 0;
      v_tot_set               number(14,2) := 0;
      v_nc_close_date    date := null;

Begin
    v_err_message := null;
    Begin
        select sum(nvl(a.res_amt,0)),sum(nvl(a.tot_res_amt,0))
           into v_res_amt, v_tot_res_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
           and a.type like 'NCNATTYPECLM%'
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                       from nc_reserved b
                                                     where b.clm_no = a.clm_no
                                                        and  b.type like 'NCNATTYPECLM%'
                                                  group by b.clm_no);
    exception
          when no_data_found then
             v_res_amt := 0;
             v_tot_res_amt := 0;
          when  others  then
             v_res_amt := 0;
             v_tot_res_amt := 0;
    End;
    Begin
        select to_char(to_number(run_no) + 1)
           into v_state_no
         from clm_control_std
       where key =  'CFIROCLM'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no for update of key, run_no;
    exception
          when no_data_found then
             v_state_no := null;
          when  others  then
             v_state_no := null;
    End;
    if  v_state_no is not null  then
        BEGIN
            update clm_control_std a
            set run_no = v_state_no
            where key =  'CFIROCLM'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_state_no := null;
        END;
        COMMIT;
    else
        ROLLBACK;
    end if;

    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,end_no,end_run,end_seq,recpt_seq,loc_seq,reg_no,clm_yr,pol_yr,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,
                 bki_shr,loc_sum_ins,cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,reg_date,clm_date,loss_date,loss_time,clm_place,surv_code,surv_date,clm_user,loss_detail,your_clm_no,
                 prod_grp,prod_type,channel,fir_source,catas_code,fax_clm_date,remark,block,sts_key,complete_date,clm_sts,close_date,reopen_date
         from nc_mas
       where clm_no = v_clm_no
        ) loop
        Begin
            select substr(full_name,1,30)
               into v_contact
             from survey_std
           where surv_code = nc_mas_rec.surv_code;
        exception
          when no_data_found then
             v_contact := null;
          when  others  then
            v_contact := null;
        End;

        Begin
            select fir_code
               into v_fir_code
             from clm_cause_map
           where cause_code = nc_mas_rec.cause_code
               and cause_seq =  nc_mas_rec.cause_seq;
        exception
          when no_data_found then
             v_fir_code := '2112';
          when  others  then
             v_fir_code := '2112';
        End;
        v_nc_close_date := nc_mas_rec.close_date;
        CLFIR.fir_inward_your_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.end_seq,v_your_pol_no,v_your_end_no);
        CLFIR.fir_text_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.end_seq,v_ben_code,v_ben_descr);
        CLFIR.co_shr_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.end_seq,v_co_shr);
        v_tot_sum_bld := nvl(clfir.bld_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.loss_date),0);
        v_our_sum_bld := (nvl(v_tot_sum_bld,0) * nvl(v_co_shr,0))/100;
        v_tot_sum_mac := nvl(clfir.mac_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.loss_date),0);
        v_our_sum_mac := (nvl(v_tot_sum_mac,0) * nvl(v_co_shr,0))/100;
        v_tot_sum_stk := nvl(clfir.stk_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.loss_date),0);
        v_our_sum_stk := (nvl(v_tot_sum_stk,0) * nvl(v_co_shr,0))/100;
        v_tot_sum_fur := nvl(clfir.fur_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.loss_date),0);
        v_our_sum_fur := (nvl(v_tot_sum_fur,0) * nvl(v_co_shr,0))/100;
        v_tot_sum_oth := nvl(clfir.oth_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.loss_date),0);
        v_our_sum_oth := (nvl(v_tot_sum_oth,0) * nvl(v_co_shr,0))/100;
        Begin
            select a.pol_te,a.pol_br,a.loc1,a.loc2,a.loc3,a.loc_am,a.loc_jw,a.agent_code1,a.agent_seq1,a.agent_code2,a.agent_seq2,a.agent_code3,a.agent_seq3,
                     a.class1,a.class2,a.risk_exp,a.ext_exp,a.pol_type,a.cus_te,b.co_type,b.leader
               into v_pol_te,v_pol_br,v_loc1,v_loc2,v_loc3,v_loc_am,v_loc_jw,v_agent_code1,v_agent_seq1,v_agent_code2,v_agent_seq2,v_agent_code3,v_agent_seq3,
                     v_class1,v_class2,v_risk_exp,v_ext_exp,v_pol_type,v_cus_te,v_co_type,v_leader
             from fir_pol_mas a,fir_pol_seq b
           where a.pol_no   = nc_mas_rec.pol_no
              and  a.pol_run  = nc_mas_rec.pol_run
              and  (to_char(nc_mas_rec.loss_date,'YYYY/MM/DD') between to_char(b.fr_date,'YYYY/MM/DD') and to_char(b.to_date,'YYYY/MM/DD')) and
                     b.end_seq  = (select max(s.end_seq)
                                            from fir_pol_seq s
                                          where s.pol_no  = nc_mas_rec.pol_no
                                             and  s.pol_run = nc_mas_rec.pol_run
                                             and  (to_char(nc_mas_rec.loss_date,'YYYY/MM/DD') >= to_char(s.fr_date,'YYYY/MM/DD')))
              and a.pol_no   = b.pol_no
              and a.pol_run  = b.pol_run;
        exception
          when no_data_found then
             v_pol_te := null;
             v_pol_br := null;
             v_loc1 := null;
             v_loc2 := null;
             v_loc3 := null;
             v_loc_am := null;
             v_loc_jw := null;
             v_agent_code1 := null;
             v_agent_seq1 := null;
             v_agent_code2 := null;
             v_agent_seq2 := null;
             v_agent_code3 := null;
             v_agent_seq3 := null;
             v_class1 := null;
             v_class2 := null;
             v_risk_exp := null;
             v_ext_exp := null;
             v_pol_type := null;
             v_cus_te := null;
             v_co_type := null;
             v_leader := null;
          when  others  then
             v_pol_te := null;
             v_pol_br := null;
             v_loc1 := null;
             v_loc2 := null;
             v_loc3 := null;
             v_loc_am := null;
             v_loc_jw := null;
             v_agent_code1 := null;
             v_agent_seq1 := null;
             v_agent_code2 := null;
             v_agent_seq2 := null;
             v_agent_code3 := null;
             v_agent_seq3 := null;
             v_class1 := null;
             v_class2 := null;
             v_risk_exp := null;
             v_ext_exp := null;
             v_pol_type := null;
             v_cus_te := null;
             v_co_type := null;
             v_leader := null;
        End;
        Begin
           insert into fir_clm_mas (clm_no,bic_no,pol_no,pol_run,end_no,end_seq,pol_cov,pol_yr,clm_yr,pol_cat,pol_type,pol_te,branch,your_pol_no,your_end_no,your_clm_no,cus_code,cus_seq,cus_te,cus_enq,
                                              block,co_type,leader,bki_shr,fr_date,to_date,agent_code1,agent_seq1,agent_code2,agent_seq2,agent_code3,agent_seq3,tot_sum_ins,sum_ins,tot_res,curr_code,curr_rate,loc1,
                                              loc2,loc3,loc_am,loc_jw,class1,class2,risk_exp,ext_exp,cause,damg_descr,surv_code,clm_men,corr_date,surv_date,loss_date,clm_rec_date,rec_sts,rec_exp_sts,sal_sts,dec_sts,
                                              remark,contact,ben_code,ben_descr,gen_risk,risk_loc,co_shr,loss_time,end_run,channel,prod_grp,prod_type,clm_br_code,catas_code,fax_clm_date,sts_key,complete_date,
                                              close_date,reopen_date,clm_sts)
            values (v_clm_no,nc_mas_rec.reg_no,substr(nc_mas_rec.pol_no,1,13),nc_mas_rec.pol_run,substr(nc_mas_rec.end_no,1,13),nc_mas_rec.end_seq,'P',nc_mas_rec.pol_yr,nc_mas_rec.clm_yr,decode(nc_mas_rec.channel,'9','9','0'),
                       v_pol_type,v_pol_te,v_pol_br,v_your_pol_no,v_your_end_no,nc_mas_rec.your_clm_no,nc_mas_rec.mas_cus_code,nc_mas_rec.mas_cus_seq,v_cus_te,substr(nc_mas_rec.mas_cus_name,1,60),nc_mas_rec.block,
                       v_co_type,v_leader,nc_mas_rec.bki_shr,nc_mas_rec.fr_date,nc_mas_rec.to_date,v_agent_code1,v_agent_seq1,v_agent_code2,v_agent_seq2,v_agent_code3,v_agent_seq3,nc_mas_rec.mas_sum_ins,
                       nc_mas_rec.recpt_sum_ins,v_res_amt,nc_mas_rec.curr_code,nc_mas_rec.curr_rate,v_loc1,v_loc2,v_loc3,v_loc_am,v_loc_jw,v_class1,v_class2,v_risk_exp,v_ext_exp,v_fir_code,nc_mas_rec.loss_detail,
                       nc_mas_rec.surv_code,nc_mas_rec.clm_user,nc_mas_rec.clm_date,nc_mas_rec.surv_date,nc_mas_rec.loss_date,nc_mas_rec.clm_date,'0','0','0','0',substr(nc_mas_rec.remark,1,200),v_contact,v_ben_code,
                       v_ben_descr,nc_mas_rec.fir_source,substr(nc_mas_rec.clm_place,1,100),nc_mas_rec.bki_shr,nc_mas_rec.loss_time,nc_mas_rec.end_run,nc_mas_rec.channel,nc_mas_rec.prod_grp,nc_mas_rec.prod_type,'01',
                       nc_mas_rec.catas_code,nc_mas_rec.fax_clm_date,nc_mas_rec.sts_key,nc_mas_rec.complete_date,nc_mas_rec.close_date,nc_mas_rec.reopen_date,
                       decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','4','NCCLMSTS03','5','NCCLMSTS04','6','1'));

            insert into fir_correct_clm (tran_date,clm_no,pol_no,state_no,state_seq,pol_cat,type,status,amt,pol_type,pol_run,prod_type)
            values (sysdate,v_clm_no,nc_mas_rec.pol_no,v_state_no,0,decode(nc_mas_rec.channel,'9','9','0'),'01','1',v_res_amt,v_pol_type,nc_mas_rec.pol_run,nc_mas_rec.prod_type);
        exception
        when  OTHERS  then
                 v_err_message := 'fir_clm_mas';
                 rollback;
        End;
        End loop;
      commit;
    End;
    Begin
        For nc_reserved_rec in
        (
        select clm_no,prem_code,type,sub_type,sts_date,amd_date,res_amt,tot_res_amt,offset_flag
          from nc_reserved
        where clm_no = v_clm_no
         ) loop
              if      nc_reserved_rec.type in ('NCNATTYPECLM001','NCNATTYPECLM002')  then
                      v_type := '01';
              elsif  nc_reserved_rec.type in ('NCNATTYPEREC001','NCNATTYPEREC002') then
                      if      nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC001') then
                              if   nc_reserved_rec.offset_flag = 'Y'  then
                                   v_type := '01';
                                   v_out_type := '09';
                                   v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                                   v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                              else
                                   v_type := '02';
                                   v_out_type := '11';
                                   v_sum_rec := v_sum_rec + nvl(nc_reserved_rec.res_amt,0);
                                   v_tot_rec := v_tot_rec + nvl(nc_reserved_rec.tot_res_amt,0);
                              end if;
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC002') then
                              v_type := '02';
                              v_out_type := '41';
                              v_sum_rec := v_sum_rec - nvl(nc_reserved_rec.res_amt,0);
                              v_tot_rec := v_tot_rec - nvl(nc_reserved_rec.tot_res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC003') then
                              v_type := '01';
                              v_out_type := '09';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL001') then
                              if    nc_reserved_rec.offset_flag = 'Y'   then
                                    v_type := '01';
                                    v_out_type := '07';
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                                    v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                              else
                                    v_type := '03';
                                    v_out_type := '10';
                                    v_sum_sal := v_sum_sal + nvl(nc_reserved_rec.res_amt,0);
                                    v_tot_sal := v_tot_sal + nvl(nc_reserved_rec.tot_res_amt,0);
                              end if;
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL002') then
                              v_type := '03';
                              v_out_type := '42';
                              v_sum_sal := v_sum_sal - nvl(nc_reserved_rec.res_amt,0);
                              v_tot_sal := v_tot_sal - nvl(nc_reserved_rec.tot_res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL003') then
                              v_type := '01';
                              v_out_type := '07';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED001') then
                              if   nc_reserved_rec.offset_flag = 'Y'  then
                                   v_type := '01';
                                   v_out_type := '15';
                                   v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                                   v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                              else
                                   v_type := '04';
                                   v_out_type := '16';
                                   v_sum_ded := v_sum_ded + nvl(nc_reserved_rec.res_amt,0);
                                   v_tot_ded := v_tot_ded + nvl(nc_reserved_rec.tot_res_amt,0);
                              end if;
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED002') then
                              v_type := '01';
                              v_out_type := '09';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                      else
                              v_type := '01';
                      end if;
              end if;
              if     nc_reserved_rec.type in ('NCNATTYPECLM001')  then
                     if      nc_reserved_rec.prem_code in ('1010') then
                             v_out_type := '01';
                             v_sum_bld := v_sum_bld + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_bld   := v_tot_bld + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1560') then
                             v_out_type := '02';
                             v_sum_mac := v_sum_mac + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_mac := v_tot_mac + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1050') then
                             v_out_type := '03';
                             v_sum_stk := v_sum_stk + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_stk := v_tot_stk + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1020')  then
                             v_out_type := '04';
                             v_sum_fur := v_sum_fur + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_fur := v_tot_fur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1030')  then
                             v_out_type := '38';
                             v_sum_fur := v_sum_fur + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_fur := v_tot_fur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1040')  then
                             v_out_type := '17';
                             v_sum_fur := v_sum_fur + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_fur := v_tot_fur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1060')  then
                             v_out_type := '18';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1070')  then
                             v_out_type := '19';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1090')  then
                             v_out_type := '20';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('2001')  then
                             v_out_type := '21';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('2002')  then
                             v_out_type := '22';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('3010')  then
                             v_out_type := '23';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('3040')  then
                             v_out_type := '24';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('5010')  then
                             v_out_type := '25';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('5020')  then
                             v_out_type := '26';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('5030')  then
                             v_out_type := '27';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('5040')  then
                             v_out_type := '28';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('6050')  then
                             v_out_type := '29';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('A099')  then
                             v_out_type := '05';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     else
                             v_out_type := '05';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     end if;
              elsif nc_reserved_rec.type in ('NCNATTYPECLM002')  then
                     if     nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM010')   then
                            v_out_type := '06';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_sur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM011')   then
                            v_out_type := '30';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_sur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM012')   then
                            v_out_type := '31';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_sur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM013')   then
                            v_out_type := '32';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM014')   then
                            v_out_type := '12';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM015')   then
                            v_out_type := '33';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM016')   then
                            v_out_type := '34';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM017')   then
                            v_out_type := '35';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM018')   then
                            v_out_type := '36';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM019')   then
                            v_out_type := '37';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM020')   then
                            v_out_type := '39';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM021')   then
                            v_out_type := '40';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     else
                            v_out_type := '08';
                            v_sum_set := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_set := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     end if;
              end if;
              if   v_type = '01'   then
                   Begin
                       insert into fir_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                       values (v_clm_no,v_out_type,v_state_no,0,v_type,trunc(nc_reserved_rec.sts_date),'BHT',nc_reserved_rec.res_amt,1,nc_reserved_rec.res_amt);
                   exception
                    when  OTHERS  then
                              v_err_message := 'fir_clm_out';
                              rollback;
                   End;
              end if;
         End loop;
         commit;
    End;
    Begin
        insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,build_tot_sum,build_our_sum,build_tot_loss,build_our_loss,mach_tot_sum,mach_our_sum,mach_tot_loss,mach_our_loss,
                                          stock_tot_sum,stock_our_sum,stock_tot_loss,stock_our_loss,furn_tot_sum,furn_our_sum,furn_tot_loss,furn_our_loss,other_tot_sum,other_our_sum,other_tot_loss,other_our_loss,
                                          sur_tot_loss,sur_our_loss,rec_tot_loss,rec_our_loss,set_tot_loss,set_our_loss,tot_tot_sum,tot_our_sum,tot_tot_loss,tot_our_loss,close_date)
        values (v_clm_no,v_state_no,0,'01',trunc(sysdate),'1',trunc(sysdate),v_tot_sum_bld,v_our_sum_bld,v_tot_bld,v_sum_bld,v_tot_sum_mac,v_our_sum_mac,v_tot_mac,v_sum_mac,v_tot_sum_stk,v_our_sum_stk,v_tot_stk,v_sum_stk,
                   v_tot_sum_fur,v_our_sum_fur,v_tot_fur,v_sum_fur,v_tot_sum_oth,v_our_sum_oth,v_tot_oth,v_sum_oth,v_tot_sur,v_sum_sur,v_tot_rec_clm,v_sum_rec_clm,v_tot_set,v_sum_set,
                   nvl(v_tot_sum_bld,0)+nvl(v_tot_sum_mac,0)+nvl(v_tot_sum_stk,0)+nvl(v_tot_sum_fur,0)+nvl(v_tot_sum_oth,0),
                   nvl(v_our_sum_bld,0)+nvl(v_our_sum_mac,0)+nvl(v_our_sum_stk,0)+nvl(v_our_sum_fur,0)+nvl(v_our_sum_oth,0),
                   nvl(v_tot_bld,0)+nvl(v_tot_mac,0)+nvl(v_tot_stk,0)+nvl(v_tot_fur,0)+nvl(v_tot_oth,0)+nvl(v_tot_sur,0)+nvl(v_tot_set,0)-nvl(v_tot_rec_clm,0),
                   nvl(v_sum_bld,0)+nvl(v_sum_mac,0)+nvl(v_sum_stk,0)+nvl(v_sum_fur,0)+nvl(v_sum_oth,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0),v_nc_close_date);
        commit;
    exception
        when  OTHERS  then
                  v_err_message := 'fir_out_stat';
                  rollback;
    End;
    if   nvl(v_sum_rec,0) > 0  then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_rec_state_no
              from clm_control_std
            where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_rec_state_no := null;
          when  others  then
             v_rec_state_no := null;
         End;
         if  v_rec_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_rec_state_no
               where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_rec_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into fir_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
             values (v_clm_no,'11',v_rec_state_no,0,'02',trunc(sysdate),'BHT',nvl(v_sum_rec,0),1,nvl(v_sum_rec,0));

             insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss)
             values (v_clm_no,v_rec_state_no,0,'02',trunc(sysdate),'1',trunc(sysdate),nvl(v_tot_rec,0),nvl(v_sum_rec,0),nvl(v_tot_rec,0),nvl(v_sum_rec,0));
            commit;
         exception
            when  OTHERS  then
                     v_err_message := 'fir_clm_out';
                     rollback;
         End;
    end if;
    if   nvl(v_sum_sal,0) > 0  then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_sal_state_no
              from clm_control_std
            where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_sal_state_no := null;
          when  others  then
             v_sal_state_no := null;
         End;
         if  v_sal_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_sal_state_no
               where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_sal_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into fir_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
             values (v_clm_no,'10',v_rec_state_no,0,'03',trunc(sysdate),'BHT',nvl(v_sum_sal,0),1,nvl(v_sum_sal,0));

             insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss)
             values (v_clm_no,v_sal_state_no,0,'03',trunc(sysdate),'1',trunc(sysdate),nvl(v_tot_sal,0),nvl(v_sum_sal,0),nvl(v_tot_sal,0),nvl(v_sum_sal,0));
            commit;
         exception
            when  OTHERS  then
                      v_err_message := 'fir_clm_out';
                     rollback;
         End;
    end if;
     if   nvl(v_sum_ded,0) > 0  then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_ded_state_no
              from clm_control_std
            where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_ded_state_no := null;
          when  others  then
             v_ded_state_no := null;
         End;
         if  v_ded_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_ded_state_no
               where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_ded_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into fir_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
             values (v_clm_no,'16',v_ded_state_no,0,'04',trunc(sysdate),'BHT',nvl(v_sum_ded,0),1,nvl(v_sum_ded,0));

             insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss)
             values (v_clm_no,v_ded_state_no,0,'04',trunc(sysdate),'1',trunc(sysdate),nvl(v_tot_ded,0),nvl(v_sum_ded,0),nvl(v_tot_ded,0),nvl(v_sum_ded,0));
            commit;
         exception
            when  OTHERS  then
                     v_err_message := 'fir_clm_out';
                     rollback;
         End;
    end if;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.type like 'NCNATTYPECLM%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.type like 'NCNATTYPECLM%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into fir_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_lf_flag,ri_type,ri_sub_type,ri_share,ri_res_amt,lett_no,lett_prt,cash_call)
                 values (v_clm_no,v_state_no,0,'01',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,
                            nc_ri_rec.lett_no,decode(nc_ri_rec.lett_no,null,'N','Y'),nc_ri_rec.cashcall);
              exception
                 when  OTHERS  then
                           v_err_message := 'fir_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPEREC%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPEREC%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into fir_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_lf_flag,ri_type,ri_sub_type,ri_share,ri_res_amt,lett_no,lett_prt,cash_call)
                 values (v_clm_no,v_rec_state_no,0,'02',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,
                            nc_ri_rec.lett_no,decode(nc_ri_rec.lett_no,null,'N','Y'),nc_ri_rec.cashcall);
              exception
                 when  OTHERS  then
                           v_err_message := 'fir_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPESAL%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPESAL%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into fir_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_lf_flag,ri_type,ri_sub_type,ri_share,ri_res_amt,lett_no,lett_prt,cash_call)
                 values (v_clm_no,v_sal_state_no,0,'03',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,
                            nc_ri_rec.lett_no,decode(nc_ri_rec.lett_no,null,'N','Y'),nc_ri_rec.cashcall);
              exception
                 when  OTHERS  then
                           v_err_message := 'fir_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
End;
PROCEDURE nc_update_fire_table (v_clm_no in varchar2, v_err_message out varchar2) IS
      v_res_amt             number := 0;
      v_rec_amt             number := 0;
      v_tot_res_amt        number := 0;
      v_tot_paid              number := 0;
      v_clm_seq              number := 0;
      v_rec_seq              number := 0;
      v_sal_seq              number := 0;
      v_ded_seq             number := 0;
      v_clm_sts               varchar2(1) := null;
      v_rec_sts               varchar2(1) := null;
      v_fir_code              varchar2(4) := null;
      v_state_no             varchar2(16) := null;
      v_rec_no                varchar2(16) := null;
      v_sal_no                varchar2(16) := null;
      v_ded_no               varchar2(16) := null;
      v_rec_state_no       varchar2(16) := null;
      v_sal_state_no       varchar2(16) := null;
      v_ded_state_no       varchar2(16) := null;
      v_pol_te                varchar2(1);
      v_pol_br                varchar2(3);
      v_loc1                   varchar2(50);
      v_loc2                   varchar2(50);
      v_loc3                   varchar2(50);
      v_loc_am               varchar2(2);
      v_loc_jw                varchar2(2);
      v_class1                 varchar2(1);
      v_class2                 varchar2(1);
      v_risk_exp              varchar2(4);
      v_ext_exp               varchar2(4);
      v_pol_type              varchar2(2);
      v_cus_te                 varchar2(1);
      v_co_type               varchar2(1);
      v_leader                 varchar2(1);
      v_contact               varchar2(30);
      v_your_pol_no        varchar2(30);
      v_your_end_no       varchar2(30);
      v_ben_code            varchar2(4);
      v_ben_descr           varchar2(100);
      v_type                    varchar2(2);
      v_out_type              varchar2(2);
      v_co_shr                number(6,3) := 0;
      v_tot_sum_bld        number(14,2) := 0;
      v_our_sum_bld       number(14,2) := 0;
      v_tot_sum_mac       number(14,2) := 0;
      v_our_sum_mac      number(14,2) := 0;
      v_tot_sum_stk         number(14,2) := 0;
      v_our_sum_stk        number(14,2) := 0;
      v_tot_sum_fur         number(14,2) := 0;
      v_our_sum_fur        number(14,2) := 0;
      v_tot_sum_oth        number(14,2) := 0;
      v_our_sum_oth       number(14,2) := 0;
      v_sum_rec_clm       number(14,2) := 0;
      v_tot_rec_clm         number(14,2) := 0;
      v_sum_rec             number(14,2) := 0;
      v_tot_rec               number(14,2) := 0;
      v_sum_sal             number(14,2) := 0;
      v_tot_sal               number(14,2) := 0;
      v_sum_ded            number(14,2) := 0;
      v_tot_ded              number(14,2) := 0;
      v_sum_bld             number(14,2) := 0;
      v_tot_bld               number(14,2) := 0;
      v_sum_mac           number(14,2) := 0;
      v_tot_mac             number(14,2) := 0;
      v_sum_stk             number(14,2) := 0;
      v_tot_stk               number(14,2) := 0;
      v_sum_fur             number(14,2) := 0;
      v_tot_fur               number(14,2) := 0;
      v_sum_oth             number(14,2) := 0;
      v_tot_oth               number(14,2) := 0;
      v_sum_sur             number(14,2) := 0;
      v_tot_sur               number(14,2) := 0;
      v_sum_set             number(14,2) := 0;
      v_tot_set               number(14,2) := 0;
      v_clm_date            date := null;
      v_rec_date            date := null;
      v_sal_date            date := null;
      v_ded_date           date := null;
      v_nc_status           varchar2(10) := null;
      v_nc_close_date    date := null;
      v_nc_reopen_date  date := null;

Begin
    v_err_message := null;
    Begin
        select sum(nvl(a.res_amt,0)),sum(nvl(a.tot_res_amt,0))
           into v_res_amt, v_tot_res_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
           and a.type like 'NCNATTYPECLM%'
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                       from nc_reserved b
                                                     where b.clm_no = a.clm_no
                                                        and  b.type like 'NCNATTYPECLM%'
                                                  group by b.clm_no);
    exception
          when no_data_found then
             v_res_amt := 0;
             v_tot_res_amt := 0;
          when  others  then
             v_res_amt := 0;
             v_tot_res_amt := 0;
    End;
    Begin
        select sum(nvl(a.res_amt,0))
           into v_rec_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
           and a.type like 'NCNATTYPEREC%'
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                       from nc_reserved b
                                                     where b.clm_no = a.clm_no
                                                        and  b.type like 'NCNATTYPEREC%'
                                                  group by b.clm_no);
    exception
          when no_data_found then
             v_rec_amt := 0;
          when  others  then
             v_rec_amt := 0;
    End;
    Begin
       select  nvl(a.tot_our_loss,0)
          into  v_tot_paid
        from  fir_paid_stat a
      where  a.clm_no = v_clm_no
         and   a.type = '01'
         and   (a.state_no,a.state_seq) in (select a1.state_no,max(a1.state_seq) from fir_paid_stat a1
                                                         where a1.clm_no = a.clm_no
                                                             and a1.state_no = a.state_no
                                                             and a1.type = '01'
                                                      group by a1.state_no);
    exception
          when no_data_found then
             v_tot_paid := 0;
          when  others  then
             v_tot_paid := 0;
    End;
    if   nvl(v_tot_paid,0) > 0  then
         v_clm_sts := '3';
    else
         v_clm_sts := '2';
    end if;
     if  nvl(v_rec_amt,0) > 0  then
         v_rec_sts := '1';
    else
         v_rec_sts := '0';
    end if;

    Begin
       select state_no,max(state_seq) + 1
          into v_state_no,v_clm_seq
        from fir_out_stat
      where clm_no = v_clm_no
         and type = '01'
    group by state_no;
    exception
          when no_data_found then
             v_state_no := null;
             v_clm_seq := 0;
          when  others  then
             v_state_no := null;
             v_clm_seq := 0;
    End;
    if  v_state_no is null  then
        v_state_no := '0000000000000000';
    end if;
    Begin
       select state_no,max(state_seq) + 1
          into v_rec_no,v_rec_seq
        from fir_out_stat
      where clm_no = v_clm_no
         and type = '02'
    group by state_no;
    exception
          when no_data_found then
             v_rec_no := null;
             v_rec_seq := null;
          when  others  then
             v_rec_no := null;
             v_rec_seq := null;
    End;
    Begin
       select state_no,max(state_seq) + 1
          into v_sal_no,v_sal_seq
        from fir_out_stat
      where clm_no = v_clm_no
         and type = '03'
    group by state_no;
    exception
          when no_data_found then
             v_sal_no := null;
             v_sal_seq := null;
          when  others  then
             v_sal_no := null;
             v_sal_seq := null;
    End;
    Begin
       select state_no,max(state_seq) + 1
          into v_ded_no,v_ded_seq
        from fir_out_stat
      where clm_no = v_clm_no
         and type = '04'
    group by state_no;
    exception
          when no_data_found then
             v_ded_no := null;
             v_ded_seq := null;
          when  others  then
             v_ded_no := null;
             v_ded_seq := null;
    End;
    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,end_no,end_run,end_seq,recpt_seq,loc_seq,reg_no,clm_yr,pol_yr,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,
                 bki_shr,loc_sum_ins,cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,reg_date,clm_date,loss_date,loss_time,clm_place,surv_code,surv_date,clm_user,loss_detail,your_clm_no,
                 prod_grp,prod_type,channel,fir_source,catas_code,fax_clm_date,remark,block,sts_key,clm_sts,close_date,reopen_date,complete_date
         from nc_mas
       where clm_no = v_clm_no
        ) loop
        Begin
            select fir_code
               into v_fir_code
             from clm_cause_map
           where cause_code = nc_mas_rec.cause_code
               and cause_seq =  nc_mas_rec.cause_seq;
        exception
          when no_data_found then
             v_fir_code := '2112';
          when  others  then
             v_fir_code := '2112';
        End;
        Begin
            select substr(full_name,1,30)
               into v_contact
             from survey_std
           where surv_code = nc_mas_rec.surv_code;
        exception
          when no_data_found then
             v_contact := null;
          when  others  then
            v_contact := null;
        End;
        v_nc_status := nc_mas_rec.clm_sts;
        v_nc_close_date := nc_mas_rec.close_date;
        v_nc_reopen_date := nc_mas_rec.reopen_date;
        CLFIR.fir_inward_your_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.end_seq,v_your_pol_no,v_your_end_no);
        CLFIR.fir_text_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.end_seq,v_ben_code,v_ben_descr);
        CLFIR.co_shr_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.end_seq,v_co_shr);
        v_tot_sum_bld := nvl(clfir.bld_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.loss_date),0);
        v_our_sum_bld := (nvl(v_tot_sum_bld,0) * nvl(v_co_shr,0))/100;
        v_tot_sum_mac := nvl(clfir.mac_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.loss_date),0);
        v_our_sum_mac := (nvl(v_tot_sum_mac,0) * nvl(v_co_shr,0))/100;
        v_tot_sum_stk := nvl(clfir.stk_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.loss_date),0);
        v_our_sum_stk := (nvl(v_tot_sum_stk,0) * nvl(v_co_shr,0))/100;
        v_tot_sum_fur := nvl(clfir.fur_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.loss_date),0);
        v_our_sum_fur := (nvl(v_tot_sum_fur,0) * nvl(v_co_shr,0))/100;
        v_tot_sum_oth := nvl(clfir.oth_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.loss_date),0);
        v_our_sum_oth := (nvl(v_tot_sum_oth,0) * nvl(v_co_shr,0))/100;
        Begin
            select a.pol_te,a.pol_br,a.loc1,a.loc2,a.loc3,a.loc_am,a.loc_jw,a.class1,a.class2,a.risk_exp,a.ext_exp,a.pol_type,a.cus_te,b.co_type,b.leader
               into v_pol_te,v_pol_br,v_loc1,v_loc2,v_loc3,v_loc_am,v_loc_jw,v_class1,v_class2,v_risk_exp,v_ext_exp,v_pol_type,v_cus_te,v_co_type,v_leader
             from fir_pol_mas a,fir_pol_seq b
           where a.pol_no   = nc_mas_rec.pol_no
              and  a.pol_run  = nc_mas_rec.pol_run
              and  (to_char(nc_mas_rec.loss_date,'YYYY/MM/DD') between to_char(b.fr_date,'YYYY/MM/DD') and to_char(b.to_date,'YYYY/MM/DD')) and
                     b.end_seq  = (select max(s.end_seq)
                                            from fir_pol_seq s
                                          where s.pol_no  = nc_mas_rec.pol_no
                                             and  s.pol_run = nc_mas_rec.pol_run
                                             and  (to_char(nc_mas_rec.loss_date,'YYYY/MM/DD') >= to_char(s.fr_date,'YYYY/MM/DD')))
              and a.pol_no   = b.pol_no
              and a.pol_run  = b.pol_run;
        exception
          when no_data_found then
             v_pol_te := null;
             v_pol_br := null;
             v_loc1 := null;
             v_loc2 := null;
             v_loc3 := null;
             v_loc_am := null;
             v_loc_jw := null;
             v_class1 := null;
             v_class2 := null;
             v_risk_exp := null;
             v_ext_exp := null;
             v_pol_type := null;
             v_cus_te := null;
             v_co_type := null;
             v_leader := null;
          when  others  then
             v_pol_te := null;
             v_pol_br := null;
             v_loc1 := null;
             v_loc2 := null;
             v_loc3 := null;
             v_loc_am := null;
             v_loc_jw := null;
             v_class1 := null;
             v_class2 := null;
             v_risk_exp := null;
             v_ext_exp := null;
             v_pol_type := null;
             v_cus_te := null;
             v_co_type := null;
             v_leader := null;
        End;
        Begin
           update fir_clm_mas set end_no = substr(nc_mas_rec.end_no,1,13), end_seq = nc_mas_rec.end_seq, your_pol_no = v_your_pol_no, your_end_no = v_your_end_no, your_clm_no = nc_mas_rec.your_clm_no,
                                              block = nc_mas_rec.block, co_type = v_co_type, leader = v_leader, bki_shr = nc_mas_rec.bki_shr,  fr_date = nc_mas_rec.fr_date, to_date = nc_mas_rec.to_date,
                                              tot_sum_ins = nc_mas_rec.mas_sum_ins, sum_ins = nc_mas_rec.recpt_sum_ins, tot_res = v_res_amt, tot_paid = v_tot_paid, tot_rec = v_rec_amt, loc1 = v_loc1, loc2 = v_loc2,
                                              loc3 = v_loc3, loc_am = v_loc_am, loc_jw = v_loc_jw, class1 = v_class1, class2 = v_class2, risk_exp = v_risk_exp, ext_exp = v_ext_exp, cause = v_fir_code,
                                              damg_descr = nc_mas_rec.loss_detail, surv_code = nc_mas_rec.surv_code, clm_men = nc_mas_rec.clm_user, corr_date = sysdate, surv_date = nc_mas_rec.surv_date,
                                              loss_date = nc_mas_rec.loss_date, clm_rec_date = nc_mas_rec.clm_date, rec_sts = v_rec_sts, remark = substr(nc_mas_rec.remark,1,200), ben_code = v_ben_code,
                                              ben_descr =  v_ben_descr, gen_risk = nc_mas_rec.fir_source, risk_loc = substr(nc_mas_rec.clm_place,1,100), co_shr = nc_mas_rec.bki_shr,  loss_time = nc_mas_rec.loss_time,
                                              end_run = nc_mas_rec.end_run, catas_code = nc_mas_rec.catas_code, fax_clm_date = nc_mas_rec.fax_clm_date, contact = v_contact , close_date = trunc(nc_mas_rec.close_date),
                                              reopen_date = trunc(nc_mas_rec.reopen_date), clm_sts = decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','4','NCCLMSTS03','5','NCCLMSTS04','6','1'),
                                              complete_date = trunc(nc_mas_rec.complete_date)
            where clm_no = v_clm_no;

            insert into fir_correct_clm (tran_date,clm_no,pol_no,state_no,state_seq,pol_cat,type,status,amt,pol_type,pol_run,prod_type) values
            (sysdate,v_clm_no,nc_mas_rec.pol_no,v_state_no,v_clm_seq,decode(nc_mas_rec.channel,'9','9','0'),'02','1',v_res_amt,v_pol_type,nc_mas_rec.pol_run,nc_mas_rec.prod_type);

        exception
        when  OTHERS  then
                 v_err_message := 'fir_clm_mas';
                 rollback;
        End;
        End loop;
      commit;
    End;
    Begin
        For nc_reserved_rec in
        (
        select a.clm_no,a.prem_code,a.type,a.sub_type,a.sts_date,a.amd_date,a.res_amt,a.tot_res_amt,a.offset_flag,a.close_date,a.status
          from nc_reserved a
        where a.clm_no = v_clm_no
            and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                        from nc_reserved b
                                                    where b.clm_no = a.clm_no
                                                 group by b.clm_no)
         ) loop
              if      nc_reserved_rec.type in ('NCNATTYPECLM001','NCNATTYPECLM002')  then
                      v_type := '01';
                      v_clm_date := nc_reserved_rec.sts_date;
              elsif  nc_reserved_rec.type in ('NCNATTYPEREC001','NCNATTYPEREC002') then
                      if      nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC001') then
                              if   nc_reserved_rec.offset_flag = 'Y'  then
                                   v_type := '01';
                                   v_out_type := '09';
                                   v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                                   v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                              else
                                   v_type := '02';
                                   v_out_type := '11';
                                   v_rec_date := nc_reserved_rec.sts_date;
                                   v_sum_rec := v_sum_rec + nvl(nc_reserved_rec.res_amt,0);
                                   v_tot_rec := v_tot_rec + nvl(nc_reserved_rec.tot_res_amt,0);
                              end if;
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC002') then
                              v_type := '02';
                              v_out_type := '41';
                              v_rec_date := nc_reserved_rec.sts_date;
                              v_sum_rec := v_sum_rec - nvl(nc_reserved_rec.res_amt,0);
                              v_tot_rec := v_tot_rec - nvl(nc_reserved_rec.tot_res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC003') then
                              v_type := '01';
                              v_out_type := '09';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL001') then
                              if    nc_reserved_rec.offset_flag = 'Y'   then
                                    v_type := '01';
                                    v_out_type := '07';
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                                    v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                              else
                                    v_type := '03';
                                    v_out_type := '10';
                                    v_sal_date := nc_reserved_rec.sts_date;
                                    v_sum_sal := v_sum_sal + nvl(nc_reserved_rec.res_amt,0);
                                    v_tot_sal := v_tot_sal + nvl(nc_reserved_rec.tot_res_amt,0);
                              end if;
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL002') then
                              v_type := '03';
                              v_out_type := '42';
                              v_sal_date := nc_reserved_rec.sts_date;
                              v_sum_sal := v_sum_sal - nvl(nc_reserved_rec.res_amt,0);
                              v_tot_sal := v_tot_sal - nvl(nc_reserved_rec.tot_res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL003') then
                              v_type := '01';
                              v_out_type := '07';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED001') then
                              if   nc_reserved_rec.offset_flag = 'Y'  then
                                   v_type := '01';
                                   v_out_type := '15';
                                   v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                                   v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                              else
                                   v_type := '04';
                                   v_out_type := '16';
                                   v_ded_date := nc_reserved_rec.sts_date;
                                   v_sum_ded := v_sum_ded + nvl(nc_reserved_rec.res_amt,0);
                                   v_tot_ded := v_tot_ded + nvl(nc_reserved_rec.tot_res_amt,0);
                              end if;
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED002') then
                              v_type := '01';
                              v_out_type := '09';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              v_tot_rec_clm := v_tot_rec_clm + nvl(nc_reserved_rec.tot_res_amt,0);
                      else
                              v_type := '01';
                      end if;
              end if;
              if     nc_reserved_rec.type in ('NCNATTYPECLM001')  then
                     if      nc_reserved_rec.prem_code in ('1010') then
                             v_out_type := '01';
                             v_sum_bld := v_sum_bld + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_bld   := v_tot_bld + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1560') then
                             v_out_type := '02';
                             v_sum_mac := v_sum_mac + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_mac := v_tot_mac + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1050') then
                             v_out_type := '03';
                             v_sum_stk := v_sum_stk + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_stk := v_tot_stk + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1020')  then
                             v_out_type := '04';
                             v_sum_fur := v_sum_fur + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_fur := v_tot_fur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1030')  then
                             v_out_type := '38';
                             v_sum_fur := v_sum_fur + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_fur := v_tot_fur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1040')  then
                             v_out_type := '17';
                             v_sum_fur := v_sum_fur + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_fur := v_tot_fur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1060')  then
                             v_out_type := '18';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1070')  then
                             v_out_type := '19';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('1090')  then
                             v_out_type := '20';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('2001')  then
                             v_out_type := '21';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('2002')  then
                             v_out_type := '22';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('3010')  then
                             v_out_type := '23';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('3040')  then
                             v_out_type := '24';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('5010')  then
                             v_out_type := '25';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('5020')  then
                             v_out_type := '26';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('5030')  then
                             v_out_type := '27';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('5040')  then
                             v_out_type := '28';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('6050')  then
                             v_out_type := '29';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.prem_code in  ('A099')  then
                             v_out_type := '05';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     else
                             v_out_type := '05';
                             v_sum_oth := v_sum_oth + nvl(nc_reserved_rec.res_amt,0);
                             v_tot_oth := v_tot_oth + nvl(nc_reserved_rec.tot_res_amt,0);
                     end if;
              elsif nc_reserved_rec.type in ('NCNATTYPECLM002')  then
                    if     nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM010')   then
                            v_out_type := '06';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_sur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM011')   then
                            v_out_type := '30';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_sur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM012')   then
                            v_out_type := '31';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_sur + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM013')   then
                            v_out_type := '32';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM014')   then
                            v_out_type := '12';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM015')   then
                            v_out_type := '33';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM016')   then
                            v_out_type := '34';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM017')   then
                            v_out_type := '35';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM018')   then
                            v_out_type := '36';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM019')   then
                            v_out_type := '37';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM020')   then
                            v_out_type := '39';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM021')   then
                            v_out_type := '40';
                            v_sum_sur := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_sur := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     else
                            v_out_type := '08';
                            v_sum_set := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                            v_tot_set := v_tot_set + nvl(nc_reserved_rec.tot_res_amt,0);
                     end if;
              end if;
              Begin
                  if      v_type = '01'  and (v_nc_status in ('NCCLMSTS01','NCCLMSTS04')  or (v_nc_status in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_nc_close_date) = trunc(sysdate)))  then
                          insert into fir_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                          values (v_clm_no,v_out_type,v_state_no,nvl(v_clm_seq,0),v_type,trunc(nc_reserved_rec.amd_date),'BHT',nc_reserved_rec.res_amt,1,nc_reserved_rec.res_amt);
                  elsif  v_type = '02'   then
                          insert into fir_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                          values (v_clm_no,v_out_type,v_rec_no,nvl(v_rec_seq,0),v_type,trunc(nc_reserved_rec.amd_date),'BHT',nc_reserved_rec.res_amt,1,nc_reserved_rec.res_amt);
                  elsif  v_type = '03'   then
                          insert into fir_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                          values (v_clm_no,v_out_type,v_sal_no,nvl(v_sal_seq,0),v_type,trunc(nc_reserved_rec.amd_date),'BHT',nc_reserved_rec.res_amt,1,nc_reserved_rec.res_amt);
                  elsif  v_type = '04'   then
                          insert into fir_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                          values (v_clm_no,v_out_type,v_ded_no,nvl(v_ded_seq,0),v_type,trunc(nc_reserved_rec.amd_date),'BHT',nc_reserved_rec.res_amt,1,nc_reserved_rec.res_amt);
                  end if;
              exception
                 when  OTHERS  then
                           v_err_message := 'fir_clm_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    if   v_nc_status in ('NCCLMSTS01','NCCLMSTS04')  or (v_nc_status in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_nc_close_date) = trunc(sysdate))  then
        Begin
            insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,build_tot_sum,build_our_sum,build_tot_loss,build_our_loss,mach_tot_sum,mach_our_sum,mach_tot_loss,mach_our_loss,
                                              stock_tot_sum,stock_our_sum,stock_tot_loss,stock_our_loss,furn_tot_sum,furn_our_sum,furn_tot_loss,furn_our_loss,other_tot_sum,other_our_sum,other_tot_loss,other_our_loss,
                                              sur_tot_loss,sur_our_loss,rec_tot_loss,rec_our_loss,set_tot_loss,set_our_loss,tot_tot_sum,tot_our_sum,tot_tot_loss,tot_our_loss,close_date,reopen_date)
            values (v_clm_no,v_state_no,nvl(v_clm_seq,0),'01',trunc(v_clm_date),'1',trunc(sysdate),v_tot_sum_bld,v_our_sum_bld,v_tot_bld,v_sum_bld,v_tot_sum_mac,v_our_sum_mac,v_tot_mac,v_sum_mac,v_tot_sum_stk,v_our_sum_stk,v_tot_stk,v_sum_stk,
                       v_tot_sum_fur,v_our_sum_fur,v_tot_fur,v_sum_fur,v_tot_sum_oth,v_our_sum_oth,v_tot_oth,v_sum_oth,v_tot_sur,v_sum_sur,v_tot_rec_clm,v_sum_rec_clm,v_tot_set,v_sum_set,
                       nvl(v_tot_sum_bld,0)+nvl(v_tot_sum_mac,0)+nvl(v_tot_sum_stk,0)+nvl(v_tot_sum_fur,0)+nvl(v_tot_sum_oth,0),
                       nvl(v_our_sum_bld,0)+nvl(v_our_sum_mac,0)+nvl(v_our_sum_stk,0)+nvl(v_our_sum_fur,0)+nvl(v_our_sum_oth,0),
                       nvl(v_tot_bld,0)+nvl(v_tot_mac,0)+nvl(v_tot_stk,0)+nvl(v_tot_fur,0)+nvl(v_tot_oth,0)+nvl(v_tot_sur,0)+nvl(v_tot_set,0)-nvl(v_tot_rec_clm,0),
                       nvl(v_sum_bld,0)+nvl(v_sum_mac,0)+nvl(v_sum_stk,0)+nvl(v_sum_fur,0)+nvl(v_sum_oth,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0),
                       v_nc_close_date,v_nc_reopen_date);
            commit;
        exception
            when  OTHERS  then
                      v_err_message := 'fir_out_stat';
                      rollback;
        End;
    end if;
    if   nvl(v_sum_rec,0) > 0  then
    if   v_rec_no is null   then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_rec_state_no
              from clm_control_std
            where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_rec_state_no := null;
          when  others  then
             v_rec_state_no := null;
         End;
         if  v_rec_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_rec_state_no
               where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_rec_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss)
             values (v_clm_no,v_rec_state_no,0,'02',trunc(sysdate),'1',trunc(sysdate),nvl(v_tot_rec,0),nvl(v_sum_rec,0),nvl(v_tot_rec,0),nvl(v_sum_rec,0)
             );
            commit;
         exception
            when  OTHERS  then
                     v_err_message := 'fir_out_stat';
                     rollback;
         End;
    else
         Begin
             insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss)
             values (v_clm_no,v_rec_no,nvl(v_rec_seq,0),'02',trunc(v_rec_date),'1',trunc(sysdate),nvl(v_tot_rec,0),nvl(v_sum_rec,0),nvl(v_tot_rec,0),nvl(v_sum_rec,0)
             );
            commit;
         exception
            when  OTHERS  then
                     v_err_message := 'fir_out_stat';
                     rollback;
         End;
    end if;
    end if;

    if   nvl(v_sum_sal,0) > 0  then
    if   v_sal_no is null   then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_sal_state_no
              from clm_control_std
            where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_sal_state_no := null;
          when  others  then
             v_sal_state_no := null;
         End;
         if  v_sal_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_sal_state_no
               where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_sal_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss)
             values (v_clm_no,v_sal_state_no,0,'03',trunc(sysdate),'1',trunc(sysdate),nvl(v_tot_sal,0),nvl(v_sum_sal,0),nvl(v_tot_sal,0),nvl(v_sum_sal,0)
             );
            commit;
         exception
            when  OTHERS  then
                     v_err_message := 'fir_out_stat';
                     rollback;
         End;
    else
         Begin
             insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss)
             values (v_clm_no,v_sal_no,nvl(v_sal_seq,0),'03',trunc(v_sal_date),'1',trunc(sysdate),nvl(v_tot_sal,0),nvl(v_sum_sal,0),nvl(v_tot_sal,0),nvl(v_sum_sal,0)
             );
            commit;
         exception
            when  OTHERS  then
                     v_err_message := 'fir_out_stat';
                     rollback;
         End;
    end if;
    end if;

     if   nvl(v_sum_ded,0) > 0  then
    if   v_ded_no is null   then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_ded_state_no
              from clm_control_std
            where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_ded_state_no := null;
          when  others  then
             v_ded_state_no := null;
         End;
         if  v_ded_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_ded_state_no
               where key =  'CFIRR'||to_char(sysdate,'yyyy')||'010'  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_ded_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss)
             values (v_clm_no,v_ded_state_no,0,'04',trunc(sysdate),'1',trunc(sysdate),nvl(v_tot_ded,0),nvl(v_sum_ded,0),nvl(v_tot_ded,0),nvl(v_sum_ded,0)
             );
            commit;
         exception
            when  OTHERS  then
                     v_err_message := 'fir_out_stat';
                     rollback;
         End;
    else
         Begin
             insert into fir_out_stat (clm_no,state_no,state_seq,type,state_date,state_sts,corr_date,rec_tot_loss,rec_our_loss,tot_tot_loss,tot_our_loss)
             values (v_clm_no,v_ded_no,nvl(v_ded_seq,0),'04',trunc(v_ded_date),'1',trunc(sysdate),nvl(v_tot_ded,0),nvl(v_sum_ded,0),nvl(v_tot_ded,0),nvl(v_sum_ded,0)
             );
            commit;
         exception
            when  OTHERS  then
                     v_err_message := 'fir_out_stat';
                     rollback;
         End;
    end if;
    end if;

    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.type like 'NCNATTYPECLM%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.type like 'NCNATTYPECLM%'
                                                     group by b.clm_no)
         ) loop
             if  v_nc_status in ('NCCLMSTS01','NCCLMSTS04')  or  (v_nc_status in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_nc_close_date) = trunc(sysdate))  then
                Begin
                    insert into fir_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_lf_flag,ri_type,ri_sub_type,ri_share,ri_res_amt,lett_no,lett_prt,cash_call)
                    values (v_clm_no,v_state_no,nvl(v_clm_seq,0),'01',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,
                               nc_ri_rec.lett_no,decode(nc_ri_rec.lett_no,null,'N','Y'),nc_ri_rec.cashcall);
                 exception
                    when  OTHERS  then
                              v_err_message := 'fir_ri_out';
                              rollback;
                 End;
              end if;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPEREC%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPEREC%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 if  v_rec_no is null  then
                     insert into fir_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_lf_flag,ri_type,ri_sub_type,ri_share,ri_res_amt,lett_no,lett_prt,cash_call)
                     values (v_clm_no,v_rec_state_no,0,'02',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,
                                nc_ri_rec.lett_no,decode(nc_ri_rec.lett_no,null,'N','Y'),nc_ri_rec.cashcall);
                 else
                     insert into fir_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_lf_flag,ri_type,ri_sub_type,ri_share,ri_res_amt,lett_no,lett_prt,cash_call)
                     values (v_clm_no,v_rec_no,nvl(v_rec_seq,0),'02',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,
                                nc_ri_rec.lett_no,decode(nc_ri_rec.lett_no,null,'N','Y'),nc_ri_rec.cashcall);
                 end if;
              exception
                 when  OTHERS  then
                           v_err_message := 'fir_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPESAL%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPESAL%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 if  v_sal_no is null  then
                     insert into fir_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_lf_flag,ri_type,ri_sub_type,ri_share,ri_res_amt,lett_no,lett_prt,cash_call)
                     values (v_clm_no,v_sal_state_no,0,'03',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,
                                nc_ri_rec.lett_no,decode(nc_ri_rec.lett_no,null,'N','Y'),nc_ri_rec.cashcall);
                 else
                     insert into fir_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,ri_lf_flag,ri_type,ri_sub_type,ri_share,ri_res_amt,lett_no,lett_prt,cash_call)
                     values (v_clm_no,v_sal_no,nvl(v_sal_seq,0),'03',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,
                                nc_ri_rec.lett_no,decode(nc_ri_rec.lett_no,null,'N','Y'),nc_ri_rec.cashcall);
                 end if;
              exception
                 when  OTHERS  then
                           v_err_message := 'fir_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
End;
PROCEDURE nc_insert_mrn_table (v_clm_no in varchar2, v_err_message out varchar2) IS
      v_res_amt             number;
      v_mrn_code           varchar2(4);
      v_state_no             varchar2(16);
      v_rec_state_no       varchar2(16);
      v_sal_state_no       varchar2(16);
      v_ded_state_no      varchar2(16);
      v_pol_te                varchar2(1);
      v_pol_br                varchar2(3);
      v_agent_code         varchar2(5);
      v_agent_seq           varchar2(2);
       v_vessel_code         varchar2(7);
      v_vessel_seq           number;
      v_vessel_enq           varchar2(35);
      v_sailing_date         varchar2(10);
      v_pack_code           varchar2(3);
      v_surv_agent          varchar2(6);
      v_sett_agent          varchar2(6);
      v_curr_code           varchar2(3);
      v_curr_rate            number(8,5);
      v_fr_port                varchar2(4);
      v_to_port               varchar2(4);
      v_i_e                     varchar2(1);
      v_int_code             varchar2(5);
      v_flight_no             varchar2(7);
      v_cond_code          varchar2(4);
      v_fgn_sum_ins       number(12);
      v_sum_ded            number(14,2) := 0;
      v_sum_pa              number(14,2) := 0;
      v_sum_exp            number(14,2) := 0;
      v_pol_type              varchar2(2);
      v_cus_te                 varchar2(1);
      v_co_type               varchar2(1);
      v_leader                 varchar2(1);
      v_your_pol_no        varchar2(30);
      v_your_end_no       varchar2(30);
      v_ben_code            varchar2(4);
      v_ben_descr           varchar2(100);
      v_type                    varchar2(2);
      v_out_type              varchar2(2);
      v_pa_flag               varchar2(1) := 'N';
      v_co_shr                number(6,3) := 0;
      v_sum_rec_clm       number(14,2) := 0;
      v_tot_rec_clm         number(14,2) := 0;
      v_sum_rec             number(14,2) := 0;
      v_tot_rec               number(14,2) := 0;
      v_sum_sal             number(14,2) := 0;
      v_tot_sal               number(14,2) := 0;
      v_sum_sur             number(14,2) := 0;
      v_tot_sur               number(14,2) := 0;
      v_sum_set             number(14,2) := 0;
      v_tot_set               number(14,2) := 0;
      v_nc_close_date     date := null;
      v_flag                   boolean;

Begin
    v_err_message := null;
    Begin
        select sum(nvl(a.res_amt,0))
           into v_res_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
           and a.type like 'NCNATTYPECLM%'
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                       from nc_reserved b
                                                     where b.clm_no = a.clm_no
                                                        and  b.type like 'NCNATTYPECLM%'
                                                  group by b.clm_no);
    exception
          when no_data_found then
             v_res_amt := 0;
          when  others  then
             v_res_amt := 0;
    End;
    Begin
        select to_char(to_number(run_no) + 1)
           into v_state_no
         from clm_control_std
       where key =  'CMRNOCLM'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
    exception
          when no_data_found then
             v_state_no := null;
          when  others  then
             v_state_no := null;
    End;
    if  v_state_no is not null  then
        BEGIN
            update clm_control_std a
            set run_no = v_state_no
            where key =  'CMRNOCLM'||to_char(sysdate,'yyyy')  and run_no <= max_no;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_state_no := null;
        END;
        COMMIT;
    else
        ROLLBACK;
    end if;

    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,pol_seq,end_no,end_run,end_seq,recpt_seq,loc_seq,reg_no,clm_yr,pol_yr,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,
                 bki_shr,loc_sum_ins,cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,reg_date,clm_date,loss_date,loss_time,clm_place,surv_code,surv_date,clm_user,loss_detail,your_clm_no,
                 prod_grp,prod_type,channel,fir_source,catas_code,fax_clm_date,remark,block,sts_key,carr_agent,consign,nat_clm_flag,arrv_date,del_date,time_bar,pi_club,complete_date,close_date,
                 reopen_date,clm_sts
         from nc_mas
       where clm_no = v_clm_no
        ) loop
        Begin
            select mrn_code
               into v_mrn_code
             from clm_cause_map
           where cause_code = nc_mas_rec.cause_code
               and cause_seq =  nc_mas_rec.cause_seq;
        exception
          when no_data_found then
             v_mrn_code := '2112';
          when  others  then
             v_mrn_code := '2112';
        End;
        Begin
           select a.vessel_code,a.vessel_seq,a.sailing_dd||'/'||a.sailing_mm||'/'||a.sailing_yy,a.pack_code,a.surv_agent,a.sett_agent,a.curr_code,a.fr_port,a.to_port,a.i_e,a.int_code,
                    a.agent_code,a.agent_seq,a.curr_rate,a.flight_no,a.cond_code
              into v_vessel_code,v_vessel_seq,v_sailing_date,v_pack_code,v_surv_agent,v_sett_agent,v_curr_code,v_fr_port,v_to_port,v_i_e,v_int_code,v_agent_code,v_agent_seq,
                    v_curr_rate,v_flight_no,v_cond_code
             from mrn_pol a
           where a.pol_no  = nc_mas_rec.pol_no
               and a.pol_run = nc_mas_rec.pol_run
               and a.pol_seq = nc_mas_rec.pol_seq
               and (a.flag_cancel is null or a.end_type <> '8')
               and a.end_seq = (select max(b.end_seq)
                                           from mrn_pol b
                                         where b.pol_no  = a.pol_no
                                             and b.pol_run = a.pol_run
                                             and b.pol_seq = a.pol_seq
                                             and (b.flag_cancel is null or b.end_type <> '8'));
        exception
          when no_data_found then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_sailing_date := null;
                   v_pack_code := null;
                   v_surv_agent := null;
                   v_sett_agent := null;
                   v_curr_code := null;
                   v_fr_port := null;
                   v_to_port := null;
                   v_i_e := null;
                   v_int_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_flight_no := null;
                   v_cond_code := null;
          when others  then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_sailing_date := null;
                   v_pack_code := null;
                   v_surv_agent := null;
                   v_sett_agent := null;
                   v_curr_code := null;
                   v_fr_port := null;
                   v_to_port := null;
                   v_i_e := null;
                   v_int_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_flight_no := null;
                   v_cond_code := null;
        End;
        Begin
           select  sum(fgn_sum_ins)
              into  v_fgn_sum_ins
             from mrn_pol
           where pol_no  =  nc_mas_rec.pol_no
              and  pol_run =  nc_mas_rec.pol_run
              and  vessel_code <> 'TBC';
        exception
        when no_data_found then
                 v_fgn_sum_ins := 0;
        end;
        v_nc_close_date := nc_mas_rec.close_date;
        v_vessel_enq  := substr(clmn_new.vessel_name(v_vessel_code,v_vessel_seq,v_flag),1,35);
        v_curr_code := nc_mas_rec.curr_code;
        v_curr_rate := nc_mas_rec.curr_rate;
        Begin
           insert into mrn_clm_mas (clm_no,bic_no,pol_no,pol_seq,end_no,end_seq,pol_yr,clm_yr,pol_cat,type_pol,your_pol,your_clm,cus_code,cus_seq,cus_enq,vessel_code,vessel_seq,vessel_enq,flight_no,
                                                fr_port,to_port,sett_agent,surv_agent,carr_agent,pi_club,time_bar,i_e,int_code,pack_code,cond_code,curr_code,curr_rate,fgn_sum_ins,sum_ins,tot_sum_ins, tot_out,tot_paid,
                                                agent_code,agent_seq,surv_code,del_date,sailing_date,loss_date,arrv_date,clm_rec_date,surv_date,consign,cause,nat_clm,clm_men,remark,damg_descr,
                                                t_e,pol_run,channel,prod_grp,prod_type,end_run,catas_code,fax_clm_date,sts_key,complete_date,close_date,reopen_date,clm_sts)
            values (v_clm_no,nc_mas_rec.reg_no,nc_mas_rec.pol_no,nc_mas_rec.pol_seq,nc_mas_rec.end_no,nc_mas_rec.end_seq,nc_mas_rec.pol_yr,nc_mas_rec.clm_yr,decode(nc_mas_rec.channel,'9','9','0'),'1',
                       v_your_pol_no,substr(nc_mas_rec.your_clm_no,1,25),nc_mas_rec.mas_cus_code,nc_mas_rec.mas_cus_seq,substr(nc_mas_rec.mas_cus_name,1,35),v_vessel_code,v_vessel_seq,v_vessel_enq,v_flight_no,v_fr_port,v_to_port,
                       v_sett_agent,v_surv_agent,nc_mas_rec.carr_agent,nc_mas_rec.pi_club,nc_mas_rec.time_bar,v_i_e,v_int_code,v_pack_code,v_cond_code,nc_mas_rec.curr_code,nc_mas_rec.curr_rate,v_fgn_sum_ins,
                       nc_mas_rec.recpt_sum_ins,nc_mas_rec.mas_sum_ins,v_res_amt,0,v_agent_code,v_agent_seq,nc_mas_rec.surv_code,nc_mas_rec.del_date,v_sailing_date,nc_mas_rec.loss_date,nc_mas_rec.arrv_date,
                       nc_mas_rec.clm_date,nc_mas_rec.surv_date,nc_mas_rec.consign,v_mrn_code,nc_mas_rec.nat_clm_flag,nc_mas_rec.clm_user,substr(nc_mas_rec.remark,1,200),nc_mas_rec.loss_detail,nc_mas_rec.t_e,
                       nc_mas_rec.pol_run,nc_mas_rec.channel,nc_mas_rec.prod_grp,nc_mas_rec.prod_type,nc_mas_rec.end_run,nc_mas_rec.catas_code,nc_mas_rec.fax_clm_date,nc_mas_rec.sts_key,nc_mas_rec.complete_date,
                       nc_mas_rec.close_date,nc_mas_rec.reopen_date,decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','3','NCCLMSTS04','4','1'));
        exception
        when  OTHERS  then
                 v_err_message := 'mrn_clm_mas';
                 rollback;
        End;
        End loop;
      commit;
    End;
    Begin
        For nc_reserved_rec in
        (
        select clm_no,prem_code,type,sub_type,sts_date,amd_date,res_amt,tot_res_amt,offset_flag
          from nc_reserved
        where clm_no = v_clm_no
         ) loop
              if      rtrim(nc_reserved_rec.type) in ('NCNATTYPECLM001','NCNATTYPECLM002')  then
                      v_type := '01';
              elsif  rtrim(nc_reserved_rec.type) in ('NCNATTYPEREC001','NCNATTYPEREC002') then
                      if      rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEREC001') then
                              if   nc_reserved_rec.offset_flag = 'Y'  then
                                   v_type := '01';
                                   v_out_type := '07';
                                   v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                   v_type := '02';
                                   v_out_type := '15';
                                   v_sum_rec := v_sum_rec + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEREC002') then
                              v_type := '02';
                              v_out_type := '24';
                              v_sum_rec := v_sum_rec - nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC003') then
                              v_type := '01';
                              v_out_type := '07';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPESAL001') then
                              if    nc_reserved_rec.offset_flag = 'Y'   then
                                    v_type := '01';
                                    v_out_type := '06';
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                    v_type := '03';
                                    v_out_type := '16';
                                    v_sum_sal := v_sum_sal + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL002') then
                              v_type := '03';
                              v_out_type := '26';
                              v_sum_sal := v_sum_sal - nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL003') then
                              v_type := '01';
                              v_out_type := '06';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEDED001') then
                              if    nc_reserved_rec.offset_flag = 'Y'   then
                                    v_type := '01';
                                    v_out_type := '05';
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                    v_type := '04';
                                    v_out_type := '17';
                                    v_sum_ded := v_sum_ded + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEDED002') then
                              v_type := '01';
                              v_out_type := '05';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      else
                              v_type := '01';
                      end if;
              end if;
              if     rtrim(nc_reserved_rec.type) in ('NCNATTYPECLM001')  then
                     v_out_type := '01';
                     v_pa_flag   := 'Y';
                     v_sum_pa := v_sum_pa + nvl(nc_reserved_rec.res_amt,0);
              elsif rtrim(nc_reserved_rec.type) in ('NCNATTYPECLM002')  then
                     if     rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM010')   then
                            v_out_type := '30';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM011')   then
                            v_out_type := '03';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM012')   then
                            v_out_type := '04';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM013')   then
                            v_out_type := '08';
                            v_sum_set := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM014')   then
                            v_out_type := '31';
                            v_sum_set := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM015')   then
                            v_out_type := '09';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM016')   then
                            v_out_type := '10';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM017')   then
                            v_out_type := '10';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM018')   then
                            v_out_type := '12';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM019')   then
                            v_out_type := '13';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM020')   then
                            v_out_type := '14';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM021')   then
                            v_out_type := '28';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     end if;
              end if;
         --     if    v_out_type  not in  ('01','04')   then
              if    v_out_type  not in  ('01')   then
                    Begin
                       insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                       values (v_clm_no,v_out_type,v_state_no,0,v_type,nc_reserved_rec.sts_date,decode(v_curr_code,null,'BHT',v_curr_code),nc_reserved_rec.res_amt,decode(v_curr_rate,null,1,0,1,v_curr_rate),nc_reserved_rec.res_amt,'4');
                    exception
                       when  OTHERS  then
                                 v_err_message := 'mrn_clm_out';
                                 rollback;
                    End;
               end if;
         End loop;
         commit;
    End;
    if    v_pa_flag = 'Y'   then
          Begin
             insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
             values (v_clm_no,'01',v_state_no,0,'01',sysdate,decode(v_curr_code,null,'BHT',v_curr_code),v_sum_pa,decode(v_curr_rate,null,1,0,1,v_curr_rate),v_sum_pa,'1');
          exception
             when  OTHERS  then
                       v_err_message := 'mrn_clm_out';
                       rollback;
          End;
    end if;
 --    if    nvl(v_sum_sur,0) > 0   then
 --         Begin
 --            insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
 --            values (v_clm_no,'04',v_state_no,0,'01',sysdate,'BHT',v_sum_sur,1,v_sum_sur,'2');
 --         exception
 --            when  OTHERS  then
 --                      v_err_message := 'mrn_clm_out';
 --                      rollback;
 --         End;
 --   end if;
    Begin
        insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,pa_amt,sur_amt,set_amt,rec_amt,exp_amt,tot_amt,typ_flag,corr_date,close_date)
        values (v_clm_no,v_state_no,0,'01',sysdate,nvl(v_sum_pa,0),nvl(v_sum_sur,0),nvl(v_sum_set,0),nvl(v_sum_rec_clm,0),nvl(v_sum_exp,0),
                   nvl(v_sum_pa,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0)+nvl(v_sum_exp,0),'0',sysdate,v_nc_close_date);
        commit;
    exception
        when  OTHERS  then
                  v_err_message := 'mrn_out_stat';
                  rollback;
    End;
    if   nvl(v_sum_rec,0) > 0  then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_rec_state_no
              from clm_control_std
            where key =  'CMRNOREC'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_rec_state_no := null;
          when  others  then
             v_rec_state_no := null;
         End;
         if  v_rec_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_rec_state_no
               where key =  'CMRNOREC'||to_char(sysdate,'yyyy')  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_rec_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,rec_amt,tot_amt,corr_date)
             values (v_clm_no,v_rec_state_no,0,'02',sysdate,nvl(v_sum_rec,0),nvl(v_sum_rec,0),sysdate);
             insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
             values (v_clm_no,'15',v_rec_state_no,0,'02',sysdate,decode(v_curr_code,null,'BHT',v_curr_code),nvl(v_sum_rec,0),decode(v_curr_rate,null,1,0,1,v_curr_rate),nvl(v_sum_rec,0));
             update mrn_clm_mas set recov_sts = '1' where clm_no = v_clm_no;
            commit;
         exception
            when  OTHERS  then
                      v_err_message := 'mrn_out_stat';
                     rollback;
         End;
    end if;
    if   nvl(v_sum_sal,0) > 0  then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_sal_state_no
              from clm_control_std
            where key =  'CMRNOSAL'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_sal_state_no := null;
          when  others  then
             v_sal_state_no := null;
         End;
         if  v_sal_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_sal_state_no
               where key =  'CMRNOSAL'||to_char(sysdate,'yyyy')  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_sal_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,rec_amt,tot_amt,corr_date)
             values (v_clm_no,v_sal_state_no,0,'03',sysdate,nvl(v_sum_sal,0),nvl(v_sum_sal,0),sysdate);
             insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
             values (v_clm_no,'16',v_sal_state_no,0,'03',sysdate,decode(v_curr_code,null,'BHT',v_curr_code),nvl(v_sum_sal,0),decode(v_curr_rate,null,1,0,1,v_curr_rate),nvl(v_sum_sal,0));
             update mrn_clm_mas set salvage_sts = '1' where clm_no = v_clm_no;
            commit;
         exception
            when  OTHERS  then
                      v_err_message := 'mrn_out_stat';
                     rollback;
         End;
    end if;
    if   nvl(v_sum_ded,0) > 0  then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_ded_state_no
              from clm_control_std
            where key =  'CMRNODED'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_ded_state_no := null;
          when  others  then
             v_ded_state_no := null;
         End;
         if  v_ded_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_ded_state_no
               where key =  'CMRNODED'||to_char(sysdate,'yyyy')  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_ded_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,rec_amt,tot_amt,corr_date)
             values (v_clm_no,v_ded_state_no,0,'04',sysdate,nvl(v_sum_ded,0),nvl(v_sum_ded,0),sysdate);
             insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
             values (v_clm_no,'17',v_ded_state_no,0,'04',sysdate,decode(v_curr_code,null,'BHT',v_curr_code),nvl(v_sum_ded,0),decode(v_curr_rate,null,1,0,1,v_curr_rate),nvl(v_sum_ded,0));
             update mrn_clm_mas set deduct_sts = '1' where clm_no = v_clm_no;
            commit;
         exception
            when  OTHERS  then
                     v_err_message := 'mrn_out_stat';
                     rollback;
         End;
    end if;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.type like 'NCNATTYPECLM%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.type like 'NCNATTYPECLM%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into mrn_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_out_amt)
                 values (v_clm_no,v_state_no,0,'01',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.org_ri_res_amt);
              exception
                 when  OTHERS  then
                           v_err_message := 'mrn_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPEREC%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPEREC%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into mrn_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_out_amt)
                 values (v_clm_no,v_rec_state_no,0,'02',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.org_ri_res_amt);
              exception
                 when  OTHERS  then
                           v_err_message := 'mrn_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPESAL%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPESAL%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into mrn_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_out_amt)
                 values (v_clm_no,v_sal_state_no,0,'03',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.org_ri_res_amt);
              exception
                 when  OTHERS  then
                           v_err_message := 'mrn_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
End;
PROCEDURE nc_update_mrn_table (v_clm_no in varchar2, v_err_message out varchar2) IS
      v_res_amt             number;
      v_clm_seq             number;
      v_rec_seq              number;
      v_sal_seq              number;
      v_ded_seq             number;
      v_mrn_code           varchar2(4);
      v_state_no             varchar2(16);
      v_rec_state_no       varchar2(16);
      v_sal_state_no       varchar2(16);
      v_ded_state_no      varchar2(16);
      v_rec_state_date    date;
      v_sal_state_date     date;
      v_ded_state_date    date;
      v_pol_te                 varchar2(1);
      v_pol_br                varchar2(3);
      v_agent_code         varchar2(5);
      v_agent_seq           varchar2(2);
      v_pol_type              varchar2(2);
      v_cus_te                 varchar2(1);
      v_co_type               varchar2(1);
      v_vessel_code         varchar2(7);
      v_vessel_seq           number;
      v_vessel_enq           varchar2(35);
      v_sailing_date         varchar2(10);
      v_pack_code           varchar2(3);
      v_surv_agent          varchar2(6);
      v_sett_agent          varchar2(6);
      v_curr_code           varchar2(3);
      v_curr_rate            number(13,10);
      v_fr_port                varchar2(4);
      v_to_port               varchar2(4);
      v_i_e                     varchar2(1);
      v_int_code             varchar2(5);
      v_flight_no             varchar2(7);
      v_cond_code          varchar2(4);
      v_fgn_sum_ins       number(12);
      v_clm_date            date;
      v_close_date          date;
      v_reopen_date       date;
      v_rec_close_date    date;
      v_sal_close_date    date;
      v_ded_close_date   date;
      v_clm_sts              varchar2(20);
      v_sum_ded            number(14,2) := 0;
      v_sum_pa              number(14,2) := 0;
      v_sum_exp            number(14,2) := 0;
      v_your_pol_no        varchar2(30);
      v_your_end_no       varchar2(30);
      v_ben_code            varchar2(4);
      v_ben_descr           varchar2(100);
      v_type                    varchar2(2);
      v_out_type              varchar2(2);
      v_pa_flag                varchar2(1) := 'N';
      v_co_shr                number(6,3) := 0;
      v_sum_rec_clm       number(14,2) := 0;
      v_tot_rec_clm         number(14,2) := 0;
      v_sum_rec             number(14,2) := 0;
      v_tot_rec               number(14,2) := 0;
      v_sum_sal             number(14,2) := 0;
      v_tot_sal               number(14,2) := 0;
      v_sum_sur             number(14,2) := 0;
      v_tot_sur               number(14,2) := 0;
      v_sum_set             number(14,2) := 0;
      v_tot_set               number(14,2) := 0;
      v_flag                    boolean;
Begin
    v_err_message := null;
    Begin
        select sum(nvl(a.res_amt,0))
           into v_res_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
           and a.type like 'NCNATTYPECLM%'
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                       from nc_reserved b
                                                     where b.clm_no = a.clm_no
                                                        and  b.type like 'NCNATTYPECLM%'
                                                  group by b.clm_no);
    exception
          when no_data_found then
             v_res_amt := 0;
          when  others  then
             v_res_amt := 0;
    End;
     Begin
       select state_no,max(state_seq) + 1
          into v_state_no,v_clm_seq
        from mrn_out_stat
      where clm_no = v_clm_no
         and type = '01'
    group by state_no;
    exception
          when no_data_found then
             v_state_no := null;
             v_clm_seq := 0;
          when  others  then
             v_state_no := null;
             v_clm_seq := 0;
    End;
    if    v_state_no is null   then
          v_state_no := '0000000000000000';
    end if;
    Begin
       select state_no,state_date,max(state_seq) + 1
          into v_rec_state_no,v_rec_state_date,v_rec_seq
        from mrn_out_stat
      where clm_no = v_clm_no
         and type = '02'
    group by state_no,state_date;
    exception
          when no_data_found then
             v_rec_state_no := null;
             v_rec_state_date := null;
             v_rec_seq := 0;
          when  others  then
             v_rec_state_no := null;
             v_rec_state_date := null;
             v_rec_seq := 0;
    End;
    Begin
       select state_no,state_date,max(state_seq) + 1
          into v_sal_state_no,v_sal_state_date,v_sal_seq
        from mrn_out_stat
      where clm_no = v_clm_no
         and type = '03'
    group by state_no,state_date;
    exception
          when no_data_found then
             v_sal_state_no := null;
             v_sal_state_date := null;
             v_sal_seq := 0;
          when  others  then
             v_sal_state_no := null;
             v_sal_state_date := null;
             v_sal_seq := 0;
    End;
    Begin
       select state_no,state_date,max(state_seq) + 1
          into v_ded_state_no,v_ded_state_date,v_ded_seq
        from mrn_out_stat
      where clm_no = v_clm_no
         and type = '04'
    group by state_no,state_date;
    exception
          when no_data_found then
             v_ded_state_no := null;
             v_ded_state_date := null;
             v_ded_seq := 0;
          when  others  then
             v_ded_state_no := null;
             v_ded_state_date := null;
             v_ded_seq := 0;
    End;
    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,pol_seq,end_no,end_run,end_seq,recpt_seq,loc_seq,reg_no,clm_yr,pol_yr,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,
                 bki_shr,loc_sum_ins,cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,reg_date,clm_date,loss_date,loss_time,clm_place,surv_code,surv_date,clm_user,loss_detail,your_clm_no,
                 prod_grp,prod_type,channel,fir_source,catas_code,fax_clm_date,remark,block,sts_key,carr_agent,consign,nat_clm_flag,arrv_date,del_date,time_bar,pi_club,reopen_date,close_date,clm_sts,
                 complete_date
         from nc_mas
       where clm_no = v_clm_no
        ) loop
        Begin
            select mrn_code
               into v_mrn_code
             from clm_cause_map
           where cause_code = nc_mas_rec.cause_code
               and cause_seq =  nc_mas_rec.cause_seq;
        exception
          when no_data_found then
             v_mrn_code := '2112';
          when  others  then
             v_mrn_code := '2112';
        End;
        Begin
           select a.vessel_code,a.vessel_seq,a.sailing_dd||'/'||a.sailing_mm||'/'||a.sailing_yy,a.pack_code,a.surv_agent,a.sett_agent,a.curr_code,a.fr_port,a.to_port,a.i_e,a.int_code,
                    a.agent_code,a.agent_seq,a.curr_rate,a.flight_no,a.cond_code
              into v_vessel_code,v_vessel_seq,v_sailing_date,v_pack_code,v_surv_agent,v_sett_agent,v_curr_code,v_fr_port,v_to_port,v_i_e,v_int_code,v_agent_code,v_agent_seq,
                    v_curr_rate,v_flight_no,v_cond_code
             from mrn_pol a
           where a.pol_no  = nc_mas_rec.pol_no
               and a.pol_run = nc_mas_rec.pol_run
               and a.pol_seq = nc_mas_rec.pol_seq
               and (a.flag_cancel is null or a.end_type <> '8')
               and a.end_seq = (select max(b.end_seq)
                                           from mrn_pol b
                                         where b.pol_no  = a.pol_no
                                             and b.pol_run = a.pol_run
                                             and b.pol_seq = a.pol_seq
                                             and (b.flag_cancel is null or b.end_type <> '8'));
        exception
          when no_data_found then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_sailing_date := null;
                   v_pack_code := null;
                   v_surv_agent := null;
                   v_sett_agent := null;
                   v_curr_code := null;
                   v_fr_port := null;
                   v_to_port := null;
                   v_i_e := null;
                   v_int_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_flight_no := null;
                   v_cond_code := null;
          when others  then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_sailing_date := null;
                   v_pack_code := null;
                   v_surv_agent := null;
                   v_sett_agent := null;
                   v_curr_code := null;
                   v_fr_port := null;
                   v_to_port := null;
                   v_i_e := null;
                   v_int_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_flight_no := null;
                   v_cond_code := null;
        End;
        Begin
           select  sum(fgn_sum_ins)
              into  v_fgn_sum_ins
             from mrn_pol
           where pol_no  =  nc_mas_rec.pol_no
              and  pol_run =  nc_mas_rec.pol_run
              and  vessel_code <> 'TBC';
        exception
        when no_data_found then
                 v_fgn_sum_ins := 0;
        end;
        v_vessel_enq  := substr(clmn_new.vessel_name(v_vessel_code,v_vessel_seq,v_flag),1,35);
        v_clm_sts := nc_mas_rec.clm_sts;
        v_close_date := nc_mas_rec.close_date;
        v_reopen_date := nc_mas_rec.reopen_date;
        v_curr_code := nc_mas_rec.curr_code;
        v_curr_rate := nc_mas_rec.curr_rate;
        Begin
           update mrn_clm_mas  set end_no = substr(nc_mas_rec.end_no,1,13), end_seq = nc_mas_rec.end_seq, your_clm = substr(nc_mas_rec.your_clm_no,1,25), cus_code = nc_mas_rec.mas_cus_code, cus_seq = nc_mas_rec.mas_cus_seq,
                                                 cus_enq = substr(nc_mas_rec.mas_cus_name,1,35), vessel_code = v_vessel_code, vessel_seq = v_vessel_seq, vessel_enq = v_vessel_enq, flight_no = v_flight_no, fr_port = v_fr_port,
                                                 to_port = v_to_port, sett_agent = v_sett_agent, surv_agent = v_surv_agent, carr_agent = nc_mas_rec.carr_agent, pi_club = nc_mas_rec.pi_club, time_bar = nc_mas_rec.time_bar,
                                                 i_e = v_i_e, int_code = v_int_code, pack_code = v_pack_code, cond_code = v_cond_code, curr_code = nc_mas_rec.curr_code, curr_rate = nc_mas_rec.curr_rate,
                                                 fgn_sum_ins = v_fgn_sum_ins, sum_ins = nc_mas_rec.recpt_sum_ins, tot_sum_ins = nc_mas_rec.mas_sum_ins, tot_out = v_res_amt, surv_code = substr(nc_mas_rec.surv_code,1,4),
                                                 del_date = nc_mas_rec.del_date, sailing_date = v_sailing_date, loss_date = nc_mas_rec.loss_date, arrv_date = nc_mas_rec.arrv_date, clm_rec_date = nc_mas_rec.clm_date,
                                                 surv_date = nc_mas_rec.surv_date, consign = nc_mas_rec.consign, cause = v_mrn_code,nat_clm = nc_mas_rec.nat_clm_flag, clm_men = nc_mas_rec.clm_user,
                                                 remark = substr(nc_mas_rec.remark,1,200), damg_descr = nc_mas_rec.loss_detail, t_e = nc_mas_rec.t_e, end_run = nc_mas_rec.end_run, catas_code = nc_mas_rec.catas_code,
                                                 fax_clm_date = nc_mas_rec.fax_clm_date,close_date = nc_mas_rec.close_date, reopen_date = nc_mas_rec.reopen_date,
                                                 clm_sts = decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','3','NCCLMSTS04','4','1'),
                                                 complete_date = nc_mas_rec.complete_date
             where clm_no = v_clm_no;
        exception
        when  OTHERS  then
                 v_err_message := 'mrn_clm_mas';
                 rollback;
        End;
        End loop;
      commit;
    End;
    Begin
        For nc_reserved_rec in
        (
        select a.clm_no,a.prem_code,a.type,a.sub_type,a.sts_date,a.amd_date,a.res_amt,a.tot_res_amt,a.offset_flag,a.close_date
          from nc_reserved a
        where a.clm_no = v_clm_no
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                      from nc_reserved b
                                                    where b.clm_no = a.clm_no
                                                 group by b.clm_no)
         ) loop
              if      nc_reserved_rec.type in ('NCNATTYPECLM001','NCNATTYPECLM002')  then
                      v_type := '01';
                      v_clm_date := nc_reserved_rec.sts_date;
              elsif  nc_reserved_rec.type in ('NCNATTYPEREC001','NCNATTYPEREC002') then
                      if      nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC001') then
                              if   nc_reserved_rec.offset_flag = 'Y'  then
                                   v_type := '01';
                                   v_out_type := '07';
                                   v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                   v_type := '02';
                                   v_out_type := '15';
                                   v_rec_close_date := nc_reserved_rec.close_date;
                                   v_sum_rec := v_sum_rec + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEREC002') then
                              v_type := '02';
                              v_out_type := '24';
                              v_sum_rec := v_sum_rec - nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC003') then
                              v_type := '01';
                              v_out_type := '07';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL001') then
                              if    nc_reserved_rec.offset_flag = 'Y'   then
                                    v_type := '01';
                                    v_out_type := '06';
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                    v_type := '03';
                                    v_out_type := '16';
                                    v_sal_close_date := nc_reserved_rec.close_date;
                                    v_sum_sal := v_sum_sal + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL002') then
                              v_type := '03';
                              v_out_type := '26';
                              v_sum_sal := v_sum_sal - nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL003') then
                              v_type := '01';
                              v_out_type := '06';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED001') then
                              if    nc_reserved_rec.offset_flag = 'Y'   then
                                    v_type := '01';
                                    v_out_type := '05';
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                    v_type := '04';
                                    v_out_type := '17';
                                    v_ded_close_date := nc_reserved_rec.close_date;
                                    v_sum_ded := v_sum_ded + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEDED002') then
                              v_type := '01';
                              v_out_type := '05';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      else
                              v_type := '01';
                      end if;
              end if;
              if     nc_reserved_rec.type in ('NCNATTYPECLM001')  then
                     v_out_type := '01';
                     v_pa_flag  := 'Y';
                     v_sum_pa := v_sum_pa + nvl(nc_reserved_rec.res_amt,0);
              elsif nc_reserved_rec.type in ('NCNATTYPECLM002')  then
                     if     rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM010')   then
                            v_out_type := '30';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM011')   then
                            v_out_type := '03';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM012')   then
                            v_out_type := '04';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM013')   then
                            v_out_type := '08';
                            v_sum_set := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM014')   then
                            v_out_type := '31';
                            v_sum_set := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM015')   then
                            v_out_type := '09';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM016')   then
                            v_out_type := '10';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM017')   then
                            v_out_type := '10';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM018')   then
                            v_out_type := '12';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM019')   then
                            v_out_type := '13';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM020')   then
                            v_out_type := '14';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM021')   then
                            v_out_type := '28';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     end if;
              end if;
         --     if    v_out_type  not in  ('01','04')   then
              if    v_type = '01'  then
                    if   v_clm_sts in ('NCCLMSTS01','NCCLMSTS04')  or (v_clm_sts in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_close_date) = trunc(sysdate)) then
                         if    v_out_type  not in  ('01')   then
                               Begin
                                  insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                                  values (v_clm_no,v_out_type,v_state_no,nvl(v_clm_seq,0),v_type,nc_reserved_rec.amd_date,decode(v_curr_code,null,'BHT',v_curr_code),
                                              nc_reserved_rec.res_amt,decode(v_curr_rate,null,1,0,1,v_curr_rate),nc_reserved_rec.res_amt,'4');
                               exception
                                  when  OTHERS  then
                                            v_err_message := 'mrn_clm_out';
                                           rollback;
                               End;
                         end if;
                    end if;
              else
                    Begin
                        insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                        values (v_clm_no,v_out_type,v_state_no,nvl(v_clm_seq,0),v_type,nc_reserved_rec.amd_date,decode(v_curr_code,null,'BHT',v_curr_code),
                                    nc_reserved_rec.res_amt,decode(v_curr_rate,null,1,0,1,v_curr_rate),nc_reserved_rec.res_amt,'4');
                        exception
                            when  OTHERS  then
                                      v_err_message := 'mrn_clm_out';
                                      rollback;
                        End;
              end if;
         End loop;
         commit;
    End;
    if   v_clm_sts in ('NCCLMSTS01','NCCLMSTS04')  or (v_clm_sts in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_close_date) = trunc(sysdate)) then
         if    v_pa_flag = 'Y'   then
               Begin
                   insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                   values (v_clm_no,'01',v_state_no,nvl(v_clm_seq,0),'01',sysdate,decode(v_curr_code,null,'BHT',v_curr_code),v_sum_pa,decode(v_curr_rate,null,1,0,1,v_curr_rate),v_sum_pa,'1');
               exception
                   when  OTHERS  then
                             v_err_message := 'mrn_clm_out';
                             rollback;
               End;
         end if;
    end if;
 --    if    nvl(v_sum_sur,0) > 0   then
 --         Begin
 --            insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
 --            values (v_clm_no,'04',v_state_no,nvl(v_clm_seq,0),'01',sysdate,'BHT',v_sum_sur,1,v_sum_sur,'2');
 --         exception
 --            when  OTHERS  then
 --                      v_err_message := 'mrn_clm_out';
 --                      rollback;
 --         End;
 --   end if;
    if   v_clm_sts in ('NCCLMSTS01','NCCLMSTS04')  or (v_clm_sts in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_close_date) = trunc(sysdate)) then
         Begin
             insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,pa_amt,sur_amt,set_amt,rec_amt,exp_amt,tot_amt,typ_flag,corr_date,close_date,reopen_date)
             values (v_clm_no,v_state_no,nvl(v_clm_seq,0),'01',v_clm_date,nvl(v_sum_pa,0),nvl(v_sum_sur,0),nvl(v_sum_set,0),nvl(v_sum_rec_clm,0),nvl(v_sum_exp,0),
                        nvl(v_sum_pa,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0)+nvl(v_sum_exp,0),'0',sysdate,
                        decode(v_clm_sts,'NCCLMSTS01',null,'NCCLMSTS04',null,v_close_date), v_reopen_date);
             commit;
         exception
             when  OTHERS  then
                       v_err_message := 'mrn_out_stat';
                       rollback;
         End;
    end if;
    if   nvl(v_sum_rec,0) > 0   then
         if  v_rec_state_no is null  then
             Begin
                select to_char(to_number(run_no) + 1)
                   into v_rec_state_no
                 from clm_control_std
               where key =  'CMRNOREC'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
             exception
               when no_data_found then
                v_rec_state_no := null;
               when  others  then
                v_rec_state_no := null;
             End;
             if  v_rec_state_no is not null  then
               BEGIN
                  update clm_control_std a
                  set run_no = v_rec_state_no
                  where key =  'CMRNOREC'||to_char(sysdate,'yyyy')  and run_no <= max_no;
               EXCEPTION
               WHEN OTHERS THEN
                   ROLLBACK;
                   v_rec_state_no := null;
               END;
               COMMIT;
             else
               ROLLBACK;
             end if;
             Begin
                insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,rec_amt,tot_amt,corr_date,close_date)
                values (v_clm_no,v_rec_state_no,0,'02',sysdate,nvl(v_sum_rec,0),nvl(v_sum_rec,0),sysdate,v_rec_close_date);
                insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                values (v_clm_no,'15',v_rec_state_no,0,'02',sysdate,decode(v_curr_code,null,'BHT',v_curr_code),nvl(v_sum_rec,0),decode(v_curr_rate,null,1,0,1,v_curr_rate),nvl(v_sum_rec,0));
                update mrn_clm_mas set recov_sts = '1' where clm_no = v_clm_no;
               commit;
             exception
               when  OTHERS  then
                         v_err_message := 'mrn_out_stat';
                        rollback;
             End;
         else
             Begin
                insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,rec_amt,tot_amt,corr_date,close_date)
                values (v_clm_no,v_rec_state_no,nvl(v_rec_seq,0),'02',v_rec_state_date,nvl(v_sum_rec,0),nvl(v_sum_rec,0),sysdate,v_rec_close_date);
                insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                values (v_clm_no,'15',v_rec_state_no,nvl(v_rec_seq,0),'02',sysdate,decode(v_curr_code,null,'BHT',v_curr_code),nvl(v_sum_rec,0),decode(v_curr_rate,null,1,0,1,v_curr_rate),nvl(v_sum_rec,0));
                update mrn_clm_mas set recov_sts = '1' where clm_no = v_clm_no;
               commit;
             exception
               when  OTHERS  then
                        v_err_message := 'mrn_out_stat';
                        rollback;
             End;
         end if;
    end if;
    if   nvl(v_sum_sal,0) > 0  then
           if  v_sal_state_no is null  then
               Begin
                  select to_char(to_number(run_no) + 1)
                     into v_sal_state_no
                    from clm_control_std
                  where key =  'CMRNOSAL'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
               exception
                 when no_data_found then
                          v_sal_state_no := null;
                 when  others  then
                          v_sal_state_no := null;
               End;
               if  v_sal_state_no is not null  then
                   BEGIN
                      update clm_control_std a
                            set run_no = v_sal_state_no
                       where key =  'CMRNOSAL'||to_char(sysdate,'yyyy')  and run_no <= max_no;
                   EXCEPTION
                       WHEN OTHERS THEN
                                ROLLBACK;
                                v_sal_state_no := null;
                   END;
                   COMMIT;
               else
                   ROLLBACK;
               end if;
               Begin
                  insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,rec_amt,tot_amt,corr_date,close_date)
                  values (v_clm_no,v_sal_state_no,0,'03',sysdate,nvl(v_sum_sal,0),nvl(v_sum_sal,0),sysdate,v_sal_close_date);
                  insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                  values (v_clm_no,'16',v_sal_state_no,0,'03',sysdate,decode(v_curr_code,null,'BHT',v_curr_code),nvl(v_sum_sal,0),decode(v_curr_rate,null,1,0,1,v_curr_rate),nvl(v_sum_sal,0));
                  update mrn_clm_mas set recov_sts = '1' where clm_no = v_clm_no;
                 commit;
               exception
                when  OTHERS  then
                          v_err_message := 'mrn_out_stat';
                          rollback;
               End;
          else
               Begin
                  insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,rec_amt,tot_amt,corr_date,close_date)
                  values (v_clm_no,v_sal_state_no,nvl(v_sal_seq,0),'03',v_sal_state_date,nvl(v_sum_sal,0),nvl(v_sum_sal,0),sysdate,v_sal_close_date);
                  insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                  values (v_clm_no,'16',v_sal_state_no,nvl(v_sal_seq,0),'03',sysdate,decode(v_curr_code,null,'BHT',v_curr_code),nvl(v_sum_sal,0),decode(v_curr_rate,null,1,0,1,v_curr_rate),nvl(v_sum_sal,0));
                  update mrn_clm_mas set recov_sts = '1' where clm_no = v_clm_no;
                 commit;
               exception
                when  OTHERS  then
                          v_err_message := 'mrn_out_stat';
                          rollback;
               End;
          end if;
    end if;
    if   nvl(v_sum_ded,0) > 0  then
          if  v_ded_state_no is null  then
             Begin
                 select to_char(to_number(run_no) + 1)
                    into v_ded_state_no
                   from clm_control_std
                 where key =  'CMRNODED'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
             exception
              when no_data_found then
                 v_ded_state_no := null;
              when  others  then
                 v_ded_state_no := null;
             End;
             if  v_ded_state_no is not null  then
                 BEGIN
                    update clm_control_std a
                         set run_no = v_ded_state_no
                    where key =  'CMRNODED'||to_char(sysdate,'yyyy')  and run_no <= max_no;
                 EXCEPTION
                    WHEN OTHERS THEN
                         ROLLBACK;
                         v_ded_state_no := null;
                 END;
                 COMMIT;
             else
                 ROLLBACK;
             end if;
             Begin
                 insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,rec_amt,tot_amt,corr_date,close_date)
                 values (v_clm_no,v_ded_state_no,0,'04',sysdate,nvl(v_sum_ded,0),nvl(v_sum_ded,0),sysdate,v_ded_close_date);
                  insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                  values (v_clm_no,'17',v_ded_state_no,0,'04',sysdate,decode(v_curr_code,null,'BHT',v_curr_code),nvl(v_sum_ded,0),decode(v_curr_rate,null,1,0,1,v_curr_rate),nvl(v_sum_ded,0));
                  update mrn_clm_mas set recov_sts = '1' where clm_no = v_clm_no;
                commit;
             exception
                when  OTHERS  then
                      v_err_message := 'mrn_out_stat';
                     rollback;
             End;
        else
             Begin
                 insert into mrn_out_stat (clm_no,state_no,state_seq,type,state_date,rec_amt,tot_amt,corr_date,close_date)
                 values (v_clm_no,v_ded_state_no,nvl(v_ded_seq,0),'04',v_ded_state_date,nvl(v_sum_ded,0),nvl(v_sum_ded,0),sysdate,v_ded_close_date);
                 insert into mrn_clm_out (clm_no,out_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                 values (v_clm_no,'17',v_ded_state_no,nvl(v_ded_seq,0),'04',sysdate,decode(v_curr_code,null,'BHT',v_curr_code),nvl(v_sum_ded,0),decode(v_curr_rate,null,1,0,1,v_curr_rate),nvl(v_sum_ded,0));
                 update mrn_clm_mas set recov_sts = '1' where clm_no = v_clm_no;
                commit;
             exception
                when  OTHERS  then
                          v_err_message := 'mrn_out_stat';
                          rollback;
             End;
        end if;
    end if;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.type like 'NCNATTYPECLM%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.type like 'NCNATTYPECLM%'
                                                     group by b.clm_no)
         ) loop
            if   v_clm_sts in ('NCCLMSTS01','NCCLMSTS04')  or (v_clm_sts in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_close_date) = trunc(sysdate)) then
             Begin
                 insert into mrn_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_out_amt)
                 values (v_clm_no,v_state_no,nvl(v_clm_seq,0),'01',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.org_ri_res_amt);
              exception
                 when  OTHERS  then
                           v_err_message := 'mrn_ri_out';
                           rollback;
              End;
            end if;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPEREC%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPEREC%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into mrn_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_out_amt)
                 values (v_clm_no,v_rec_state_no,nvl(v_rec_seq,0),'02',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.org_ri_res_amt);
              exception
                 when  OTHERS  then
                            v_err_message := 'mrn_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPESAL%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPESAL%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into mrn_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_out_amt)
                 values (v_clm_no,v_sal_state_no,nvl(v_sal_seq,0),'03',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.org_ri_res_amt);
              exception
                 when  OTHERS  then
                            v_err_message := 'mrn_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPEDED%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPEDED%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into mrn_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_out_amt)
                 values (v_clm_no,v_ded_state_no,nvl(v_ded_seq,0),'04',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,nc_ri_rec.org_ri_res_amt);
              exception
                 when  OTHERS  then
                            v_err_message := 'mrn_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
End;
PROCEDURE nc_insert_hull_table (v_clm_no in varchar2, v_err_message out varchar2) IS
      v_res_amt             number;
      v_mrn_code           varchar2(4);
      v_state_no             varchar2(16);
      v_rec_state_no       varchar2(16);
      v_sal_state_no       varchar2(16);
      v_ded_state_no      varchar2(16);
      v_pol_te                varchar2(1);
      v_pol_br                varchar2(3);
      v_agent_code         varchar2(5);
      v_agent_seq           varchar2(2);
       v_vessel_code         varchar2(7);
      v_vessel_seq           number;
      v_vessel_enq           varchar2(35);
      v_clm_user              varchar2(10);
  --    v_sailing_date         varchar2(10);
  --    v_pack_code           varchar2(3);
  --    v_surv_agent          varchar2(6);
  --    v_sett_agent          varchar2(6);
      v_curr_code           varchar2(3);
      v_curr_rate            number(8,5);
  --    v_fr_port                varchar2(4);
  --    v_to_port               varchar2(4);
  --    v_i_e                     varchar2(1);
  --    v_int_code             varchar2(5);
  --   v_flight_no             varchar2(7);
      v_cond_code          varchar2(4);
  --    v_fgn_sum_ins       number(12);
      v_sum_ded            number(14,2) := 0;
      v_sum_pa              number(14,2) := 0;
      v_sum_exp            number(14,2) := 0;
      v_pol_type              varchar2(2);
      v_cus_te                 varchar2(1);
      v_co_type               varchar2(1);
      v_leader                 varchar2(1);
      v_your_pol_no        varchar2(30);
      v_your_end_no       varchar2(30);
      v_ben_code            varchar2(4);
      v_ben_descr           varchar2(100);
      v_type                    varchar2(2);
      v_out_type              varchar2(2);
      v_pa_flag                varchar2(1) := 'N';
      v_co_shr                number(6,3) := 0;
      v_sum_rec_clm       number(14,2) := 0;
      v_tot_rec_clm         number(14,2) := 0;
      v_sum_rec             number(14,2) := 0;
      v_tot_rec               number(14,2) := 0;
      v_sum_sal             number(14,2) := 0;
      v_tot_sal               number(14,2) := 0;
      v_sum_sur             number(14,2) := 0;
      v_tot_sur               number(14,2) := 0;
      v_sum_set             number(14,2) := 0;
      v_tot_set               number(14,2) := 0;
      v_nc_close_date    date := null;
      v_flag                   boolean;

Begin
    v_err_message := null;
    Begin
        select sum(nvl(a.res_amt,0))
           into v_res_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
           and a.type like 'NCNATTYPECLM%'
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                       from nc_reserved b
                                                     where b.clm_no = a.clm_no
                                                        and  b.type like 'NCNATTYPECLM%'
                                                  group by b.clm_no);
    exception
          when no_data_found then
             v_res_amt := 0;
          when  others  then
             v_res_amt := 0;
    End;
    Begin
        select clm_user
           into v_clm_user
         from nc_mas a
       where a.clm_no = v_clm_no;
    exception
          when no_data_found then
             v_clm_user := null;
          when  others  then
             v_clm_user := null;
    End;
    Begin
        select to_char(to_number(run_no) + 1)
           into v_state_no
         from clm_control_std
       where key =  'CHULLOCLM'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
    exception
          when no_data_found then
             v_state_no := null;
          when  others  then
             v_state_no := null;
    End;
    if  v_state_no is not null  then
        BEGIN
            update clm_control_std a
            set run_no = v_state_no
            where key =  'CHULLOCLM'||to_char(sysdate,'yyyy')  and run_no <= max_no;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_state_no := null;
        END;
        COMMIT;
    else
        ROLLBACK;
    end if;

    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,pol_seq,end_no,end_run,end_seq,recpt_seq,loc_seq,reg_no,clm_yr,pol_yr,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,
                 bki_shr,loc_sum_ins,cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,reg_date,clm_date,loss_date,loss_time,clm_place,surv_code,surv_date,clm_user,loss_detail,your_clm_no,
                 prod_grp,prod_type,channel,fir_source,catas_code,fax_clm_date,remark,block,sts_key,carr_agent,consign,nat_clm_flag,arrv_date,del_date,time_bar,pi_club,close_date,reopen_date,clm_sts
         from nc_mas
       where clm_no = v_clm_no
        ) loop
        Begin
            select mrn_code
               into v_mrn_code
             from clm_cause_map
           where cause_code = nc_mas_rec.cause_code
               and cause_seq =  nc_mas_rec.cause_seq;
        exception
          when no_data_found then
             v_mrn_code := '2112';
          when  others  then
             v_mrn_code := '2112';
        End;
        Begin
           select a.vessel_code,a.vessel_seq,a.curr_code,a.agent_code,a.agent_seq,a.curr_rate,a.cond_code
              into v_vessel_code,v_vessel_seq,v_curr_code,v_agent_code,v_agent_seq,v_curr_rate,v_cond_code
             from hull_pol a
           where a.pol_no  = nc_mas_rec.pol_no
               and a.pol_run = nc_mas_rec.pol_run
               and (a.flag_cancel is null or a.end_type <> '8')
               and a.end_seq = (select max(b.end_seq)
                                           from hull_pol b
                                         where b.pol_no  = a.pol_no
                                             and b.pol_run = a.pol_run
                                             and (b.flag_cancel is null or b.end_type <> '8'));
        exception
          when no_data_found then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_curr_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_cond_code := null;
          when others  then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_curr_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_cond_code := null;
        End;
   --     Begin
   --        select  sum(fgn_sum_ins)
   --           into  v_fgn_sum_ins
   --          from hull_pol
   --        where pol_no  =  nc_mas_rec.pol_no
   --           and  pol_run =  nc_mas_rec.pol_run
   --           and  vessel_code <> 'TBC';
   --     exception
   --     when no_data_found then
   --              v_fgn_sum_ins := 0;
   --     end;
        v_nc_close_date := nc_mas_rec.close_date;
        v_vessel_enq  := substr(clmn_new.vessel_hull_name(v_vessel_code,v_vessel_seq,v_flag),1,35);
        Begin
           insert into hull_clm_mas (clm_no,bic_no,pol_no,end_no,end_seq,pol_yr,clm_yr,pol_cat,your_clm,cus_code,cus_seq,cus_enq,vessel_code,vessel_seq,vessel_enq,th_eng,
                                                pi_club,cond_code,curr_code,curr_rate,tot_sum_ins,tot_res,tot_paid,agent_code,agent_seq,surv_code,loss_date,clm_rec_date,surv_date,
                                                recp_date,cause,clm_men,remark,damg_descr,recov_sts,location,pol_run,end_run,channel,prod_grp,prod_type,catas_code,fax_clm_date,sts_key,
                                                carr_agent,close_date,reopen_date,clm_sts)
            values (v_clm_no,nc_mas_rec.reg_no,nc_mas_rec.pol_no,nc_mas_rec.end_no,nc_mas_rec.end_seq,nc_mas_rec.pol_yr,nc_mas_rec.clm_yr,'0',substr(nc_mas_rec.your_clm_no,1,25),
                       nc_mas_rec.mas_cus_code,nc_mas_rec.mas_cus_seq,substr(nc_mas_rec.mas_cus_name,1,80),v_vessel_code,v_vessel_seq,v_vessel_enq,'E',nc_mas_rec.pi_club,v_cond_code,
                       nc_mas_rec.curr_code,nc_mas_rec.curr_rate,nc_mas_rec.mas_sum_ins,v_res_amt,0,v_agent_code,v_agent_seq,nc_mas_rec.surv_code,nc_mas_rec.loss_date,nc_mas_rec.clm_date,
                       nc_mas_rec.surv_date,nc_mas_rec.reg_date,v_mrn_code,nc_mas_rec.clm_user,substr(nc_mas_rec.remark,1,200),nc_mas_rec.loss_detail,'0',substr(nc_mas_rec.clm_place,1,50),
                       nc_mas_rec.pol_run,nc_mas_rec.end_run,nc_mas_rec.channel,nc_mas_rec.prod_grp,nc_mas_rec.prod_type,nc_mas_rec.catas_code,nc_mas_rec.fax_clm_date,nc_mas_rec.sts_key,
                       nc_mas_rec.carr_agent,nc_mas_rec.close_date,nc_mas_rec.reopen_date,decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','3','NCCLMSTS03','4','NCCLMSTS04','5','1'));
        exception
        when  OTHERS  then
                 v_err_message := 'hull_clm_mas';
                 rollback;
        End;
        End loop;
      commit;
    End;
    Begin
        For nc_reserved_rec in
        (
        select clm_no,prem_code,type,sub_type,sts_date,amd_date,res_amt,tot_res_amt,offset_flag
          from nc_reserved
        where clm_no = v_clm_no
         ) loop
              if      rtrim(nc_reserved_rec.type) in ('NCNATTYPECLM001','NCNATTYPECLM002')  then
                      v_type := '01';
              elsif  rtrim(nc_reserved_rec.type) in ('NCNATTYPEREC001','NCNATTYPEREC002') then
                      if      rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEREC001') then
                              if   nc_reserved_rec.offset_flag = 'Y'  then
                                   v_type := '01';
                                   v_out_type := '07';
                                   v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                   v_type := '02';
                                   v_out_type := '15';
                                   v_sum_rec := v_sum_rec + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEREC002') then
                              v_type := '02';
                              v_out_type := '24';
                              v_sum_rec := v_sum_rec - nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC003') then
                              v_type := '01';
                              v_out_type := '07';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPESAL001') then
                              if    nc_reserved_rec.offset_flag = 'Y'   then
                                    v_type := '01';
                                    v_out_type := '06';
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                    v_type := '03';
                                    v_out_type := '16';
                                    v_sum_sal := v_sum_sal + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL002') then
                              v_type := '03';
                              v_out_type := '26';
                              v_sum_sal := v_sum_sal - nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL003') then
                              v_type := '01';
                              v_out_type := '06';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEDED001') then
                              if    nc_reserved_rec.offset_flag = 'Y'   then
                                    v_type := '01';
                                    v_out_type := '05';
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                    v_type := '04';
                                    v_out_type := '17';
                                    v_sum_ded := v_sum_ded + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEDED002') then
                              v_type := '01';
                              v_out_type := '05';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      else
                              v_type := '01';
                      end if;
              end if;
              if     rtrim(nc_reserved_rec.type) in ('NCNATTYPECLM001')  then
                     v_out_type := '01';
                     v_pa_flag   := 'Y';
                     v_sum_pa := v_sum_pa + nvl(nc_reserved_rec.res_amt,0);
              elsif rtrim(nc_reserved_rec.type) in ('NCNATTYPECLM002')  then
                     if     rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM010')   then
                            v_out_type := '30';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM011')   then
                            v_out_type := '03';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM012')   then
                            v_out_type := '04';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM013')   then
                            v_out_type := '08';
                            v_sum_set := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM014')   then
                            v_out_type := '31';
                            v_sum_set := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM015')   then
                            v_out_type := '09';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM016')   then
                            v_out_type := '10';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM017')   then
                            v_out_type := '10';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM018')   then
                            v_out_type := '12';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM019')   then
                            v_out_type := '13';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM020')   then
                            v_out_type := '14';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM021')   then
                            v_out_type := '28';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     end if;
              end if;
     --         if    v_out_type  not in  ('01','04')   then
              if    v_out_type  not in  ('01')   then
                    Begin
                       insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                       values (v_clm_no,v_out_type,v_state_no,0,v_type,nc_reserved_rec.sts_date,'BHT',nc_reserved_rec.res_amt,1,nc_reserved_rec.res_amt,'4');
                    exception
                       when  OTHERS  then
                                 v_err_message := 'hull_clm_out';
                                 rollback;
                    End;
              end if;
         End loop;
         commit;
    End;
     if   v_pa_flag = 'Y'   then
          Begin
             insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
             values (v_clm_no,'01',v_state_no,0,'01',sysdate,'BHT',v_sum_pa,1,v_sum_pa,'1');
          exception
             when  OTHERS  then
                       v_err_message := 'hull_clm_out';
                       rollback;
          End;
    end if;
--     if    nvl(v_sum_sur,0) > 0   then
--          Begin
--             insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
--             values (v_clm_no,'04',v_state_no,0,'01',sysdate,'BHT',v_sum_sur,1,v_sum_sur,'2');
--          exception
--             when  OTHERS  then
--                       v_err_message := 'hull_clm_out';
--                       rollback;
--          End;
--    end if;
    Begin
        insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,res_amt,typ_flag,corr_date,user_id,close_date,close_mark)
        values (v_clm_no,v_state_no,0,'01',sysdate,nvl(v_sum_pa,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0)+nvl(v_sum_exp,0),'0',sysdate,v_clm_user,v_nc_close_date,decode(v_nc_close_date,null,'N','Y'));
        commit;
    exception
        when  OTHERS  then
                  v_err_message := 'hull_out_stat';
                  rollback;
    End;
    if   nvl(v_sum_rec,0) > 0  then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_rec_state_no
              from clm_control_std
            where key =  'CHULLOREC'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_rec_state_no := null;
          when  others  then
             v_rec_state_no := null;
         End;
         if  v_rec_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_rec_state_no
               where key =  'CHULLOREC'||to_char(sysdate,'yyyy')  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_rec_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,res_amt,typ_flag,corr_date,user_id)
             values (v_clm_no,v_rec_state_no,0,'02',sysdate,nvl(v_sum_rec,0),'0',sysdate,v_clm_user);
             insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
             values (v_clm_no,'15',v_rec_state_no,0,'02',sysdate,'BHT',nvl(v_sum_rec,0),1,nvl(v_sum_rec,0));
             update hull_clm_mas set recov_sts = '1' where clm_no = v_clm_no;
            commit;
         exception
            when  OTHERS  then
                      v_err_message := 'hull_out_stat';
                     rollback;
         End;
    end if;
    if   nvl(v_sum_sal,0) > 0  then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_sal_state_no
              from clm_control_std
            where key =  'CHULLOSAL'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_sal_state_no := null;
          when  others  then
             v_sal_state_no := null;
         End;
         if  v_sal_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_sal_state_no
               where key =  'CHULLOSAL'||to_char(sysdate,'yyyy')  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_sal_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,res_amt,typ_flag,corr_date,user_id)
             values (v_clm_no,v_sal_state_no,0,'03',sysdate,nvl(v_sum_sal,0),'0',sysdate,v_clm_user);
             insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
             values (v_clm_no,'16',v_sal_state_no,0,'03',sysdate,'BHT',nvl(v_sum_sal,0),1,nvl(v_sum_sal,0));
     --        update hull_clm_mas set salvage_sts = '1' where clm_no = v_clm_no;
            commit;
         exception
            when  OTHERS  then
                      v_err_message := 'hull_out_stat';
                     rollback;
         End;
    end if;
    if   nvl(v_sum_ded,0) > 0  then
         Begin
             select to_char(to_number(run_no) + 1)
                into v_ded_state_no
              from clm_control_std
            where key =  'CHULLODED'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
         exception
          when no_data_found then
             v_ded_state_no := null;
          when  others  then
             v_ded_state_no := null;
         End;
         if  v_ded_state_no is not null  then
            BEGIN
               update clm_control_std a
               set run_no = v_ded_state_no
               where key =  'CHULLODED'||to_char(sysdate,'yyyy')  and run_no <= max_no;
            EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                v_ded_state_no := null;
            END;
            COMMIT;
        else
            ROLLBACK;
        end if;
         Begin
             insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,res_amt,typ_flag,corr_date,user_id)
             values (v_clm_no,v_ded_state_no,0,'04',sysdate,nvl(v_sum_ded,0),'0',sysdate,v_clm_user);
             insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
             values (v_clm_no,'17',v_ded_state_no,0,'04',sysdate,'BHT',nvl(v_sum_ded,0),1,nvl(v_sum_ded,0));
      --       update hull_clm_mas set deduct_sts = '1' where clm_no = v_clm_no;
            commit;
         exception
            when  OTHERS  then
                     v_err_message := 'hull_out_stat';
                     rollback;
         End;
    end if;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.type like 'NCNATTYPECLM%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.type like 'NCNATTYPECLM%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into hull_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_shr,ri_out_amt,cess_no)
                 values (v_clm_no,v_state_no,0,'01',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,
                            nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,nc_ri_rec.lett_no);
              exception
                 when  OTHERS  then
                           v_err_message := 'hull_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPEREC%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPEREC%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into hull_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_shr,ri_out_amt,cess_no)
                 values (v_clm_no,v_rec_state_no,0,'02',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,
                            nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,nc_ri_rec.lett_no);
              exception
                 when  OTHERS  then
                           v_err_message := 'hull_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPESAL%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPESAL%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into hull_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_shr,ri_out_amt,cess_no)
                 values (v_clm_no,v_sal_state_no,0,'03',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,nc_ri_rec.ri_sub_type,
                            nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,nc_ri_rec.lett_no);
              exception
                 when  OTHERS  then
                           v_err_message := 'hull_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
End;
PROCEDURE nc_update_hull_table (v_clm_no in varchar2, v_err_message out varchar2) IS
      v_res_amt             number;
      v_clm_seq             number;
      v_rec_seq              number;
      v_sal_seq              number;
      v_ded_seq             number;
      v_mrn_code           varchar2(4);
      v_state_no             varchar2(16);
      v_rec_state_no       varchar2(16);
      v_sal_state_no       varchar2(16);
      v_ded_state_no      varchar2(16);
      v_rec_state_date    date;
      v_sal_state_date     date;
      v_ded_state_date    date;
      v_clm_sts               varchar2(1);
      v_rec_sts               varchar2(1);
      v_pol_te                 varchar2(1);
      v_pol_br                varchar2(3);
      v_agent_code         varchar2(5);
      v_agent_seq           varchar2(2);
      v_pol_type              varchar2(2);
      v_cus_te                 varchar2(1);
      v_co_type               varchar2(1);
      v_vessel_code         varchar2(7);
      v_vessel_seq           number;
      v_vessel_enq           varchar2(35);
      v_clm_user             varchar2(10);
  --    v_sailing_date         varchar2(10);
  --    v_pack_code           varchar2(3);
  --    v_surv_agent          varchar2(6);
  --    v_sett_agent          varchar2(6);
      v_curr_code           varchar2(3);
      v_curr_rate            number(8,5);
  --    v_fr_port                varchar2(4);
  --    v_to_port               varchar2(4);
  --    v_i_e                     varchar2(1);
  --    v_int_code             varchar2(5);
  --    v_flight_no             varchar2(7);
      v_cond_code          varchar2(4);
  --    v_fgn_sum_ins       number(12);
      v_clm_date            date;
      v_sum_ded            number(14,2) := 0;
      v_sum_pa              number(14,2) := 0;
      v_sum_exp            number(14,2) := 0;
      v_your_pol_no        varchar2(30);
      v_your_end_no       varchar2(30);
      v_ben_code            varchar2(4);
      v_ben_descr           varchar2(100);
      v_type                    varchar2(2);
      v_out_type              varchar2(2);
      v_pa_flag                varchar2(1) := 'N';
      v_co_shr                number(6,3) := 0;
      v_sum_rec_clm       number(14,2) := 0;
      v_tot_rec_clm         number(14,2) := 0;
      v_sum_rec             number(14,2) := 0;
      v_tot_rec               number(14,2) := 0;
      v_sum_sal             number(14,2) := 0;
      v_tot_sal               number(14,2) := 0;
      v_sum_sur             number(14,2) := 0;
      v_tot_sur               number(14,2) := 0;
      v_sum_set             number(14,2) := 0;
      v_tot_set               number(14,2) := 0;
      v_close_date          date := null;
      v_rec_close_date    date := null;
      v_sal_close_date    date := null;
      v_ded_close_date   date := null;
      v_reopen_date       date := null;
      v_flag                    boolean;
Begin
    v_err_message := null;
    Begin
        select sum(nvl(a.res_amt,0))
           into v_res_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
           and a.type like 'NCNATTYPECLM%'
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                       from nc_reserved b
                                                     where b.clm_no = a.clm_no
                                                        and  b.type like 'NCNATTYPECLM%'
                                                  group by b.clm_no);
    exception
          when no_data_found then
             v_res_amt := 0;
          when  others  then
             v_res_amt := 0;
    End;

    Begin
        select clm_user
           into v_clm_user
         from nc_mas a
       where a.clm_no = v_clm_no;
    exception
          when no_data_found then
             v_clm_user := null;
          when  others  then
             v_clm_user := null;
    End;
     Begin
       select state_no,max(state_seq) + 1
          into v_state_no,v_clm_seq
        from hull_out_stat
      where clm_no = v_clm_no
         and type = '01'
    group by state_no;
    exception
          when no_data_found then
             v_state_no := null;
             v_clm_seq := 0;
          when  others  then
             v_state_no := null;
             v_clm_seq := 0;
    End;
    if    v_state_no is null   then
          v_state_no := '0000000000000000';
    end if;
    Begin
       select state_no,state_date,max(state_seq) + 1
          into v_rec_state_no,v_rec_state_date,v_rec_seq
        from hull_out_stat
      where clm_no = v_clm_no
         and type = '02'
    group by state_no,state_date;
    exception
          when no_data_found then
             v_rec_state_no := null;
             v_rec_state_date := null;
             v_rec_seq := 0;
          when  others  then
             v_rec_state_no := null;
             v_rec_state_date := null;
             v_rec_seq := 0;
    End;
    Begin
       select state_no,state_date,max(state_seq) + 1
          into v_sal_state_no,v_sal_state_date,v_sal_seq
        from hull_out_stat
      where clm_no = v_clm_no
         and type = '03'
    group by state_no,state_date;
    exception
          when no_data_found then
             v_sal_state_no := null;
             v_sal_state_date := null;
             v_sal_seq := 0;
          when  others  then
             v_sal_state_no := null;
             v_sal_state_date := null;
             v_sal_seq := 0;
    End;
    Begin
       select state_no,state_date,max(state_seq) + 1
          into v_ded_state_no,v_ded_state_date,v_ded_seq
        from hull_out_stat
      where clm_no = v_clm_no
         and type = '04'
    group by state_no,state_date;
    exception
          when no_data_found then
             v_ded_state_no := null;
             v_ded_state_date := null;
             v_ded_seq := 0;
          when  others  then
             v_ded_state_no := null;
             v_ded_state_date := null;
             v_ded_seq := 0;
    End;
    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,pol_seq,end_no,end_run,end_seq,recpt_seq,loc_seq,reg_no,clm_yr,pol_yr,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,
                 bki_shr,loc_sum_ins,cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,reg_date,clm_date,loss_date,loss_time,clm_place,surv_code,surv_date,clm_user,loss_detail,your_clm_no,
                 prod_grp,prod_type,channel,fir_source,catas_code,fax_clm_date,remark,block,sts_key,carr_agent,consign,nat_clm_flag,arrv_date,del_date,time_bar,pi_club,close_date,reopen_date,clm_sts
         from nc_mas
       where clm_no = v_clm_no
        ) loop
        Begin
            select mrn_code
               into v_mrn_code
             from clm_cause_map
           where cause_code = nc_mas_rec.cause_code
               and cause_seq =  nc_mas_rec.cause_seq;
        exception
          when no_data_found then
             v_mrn_code := '2112';
          when  others  then
             v_mrn_code := '2112';
        End;
        Begin
           select a.vessel_code,a.vessel_seq,a.curr_code,a.agent_code,a.agent_seq,a.curr_rate,a.cond_code
              into v_vessel_code,v_vessel_seq,v_curr_code,v_agent_code,v_agent_seq,v_curr_rate,v_cond_code
             from hull_pol a
           where a.pol_no  = nc_mas_rec.pol_no
               and a.pol_run = nc_mas_rec.pol_run
               and (a.flag_cancel is null or a.end_type <> '8')
               and a.end_seq = (select max(b.end_seq)
                                           from mrn_pol b
                                         where b.pol_no  = a.pol_no
                                             and b.pol_run = a.pol_run
                                             and (b.flag_cancel is null or b.end_type <> '8'));
        exception
          when no_data_found then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_curr_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_cond_code := null;
          when others  then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_curr_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_cond_code := null;
        End;
    if nc_mas_rec.clm_sts in ('NCCLMSTS01') then
          v_clm_sts := '1';
    elsif nc_mas_rec.clm_sts in ('NCCLMSTS02') then
          v_clm_sts := '3';
    elsif nc_mas_rec.clm_sts in ('NCCLMSTS03') then
          v_clm_sts := '4';
    elsif nc_mas_rec.clm_sts in ('NCCLMSTS04') then
          v_clm_sts := '5';
    else
          v_clm_sts := '1';
    end if;
    if v_rec_state_no is not null or v_sal_state_no is not null or v_ded_state_no is not null  then
       v_rec_sts := '1';
    else
       v_rec_sts := '0';
    end if;
    --    Begin
    --       select  sum(fgn_sum_ins)
    --          into  v_fgn_sum_ins
    --         from mrn_pol
    --       where pol_no  =  nc_mas_rec.pol_no
    --          and  pol_run =  nc_mas_rec.pol_run
    --          and  vessel_code <> 'TBC';
    --    exception
    --    when no_data_found then
    --             v_fgn_sum_ins := 0;
    --    end;
        v_vessel_enq  := substr(clmn_new.vessel_hull_name(v_vessel_code,v_vessel_seq,v_flag),1,35);
        v_close_date  := nc_mas_rec.close_date;
        v_reopen_date  := nc_mas_rec.reopen_date;
        Begin
           update hull_clm_mas  set end_no = substr(nc_mas_rec.end_no,1,13), end_seq = nc_mas_rec.end_seq, your_clm = substr(nc_mas_rec.your_clm_no,1,25), cus_code = nc_mas_rec.mas_cus_code, cus_seq = nc_mas_rec.mas_cus_seq,
                                                 cus_enq = substr(nc_mas_rec.mas_cus_name,1,80), vessel_code = v_vessel_code, vessel_seq = v_vessel_seq, vessel_enq = v_vessel_enq,
                                                 carr_agent = nc_mas_rec.carr_agent, pi_club = nc_mas_rec.pi_club, cond_code = v_cond_code, curr_code = nc_mas_rec.curr_code, curr_rate = nc_mas_rec.curr_rate, tot_res = v_res_amt,
                                                 surv_code = substr(nc_mas_rec.surv_code,1,4), loss_date = nc_mas_rec.loss_date, clm_rec_date = nc_mas_rec.clm_date, surv_date = nc_mas_rec.surv_date, cause = v_mrn_code,
                                                 clm_men = nc_mas_rec.clm_user, remark = substr(nc_mas_rec.remark,1,200), damg_descr = nc_mas_rec.loss_detail, location = substr(nc_mas_rec.clm_place,1,50), end_run = nc_mas_rec.end_run,
                                                 catas_code = nc_mas_rec.catas_code, fax_clm_date = nc_mas_rec.fax_clm_date, clm_sts = v_clm_sts, recov_sts = v_rec_sts,
                                                 close_date = nc_mas_rec.close_date, reopen_date = nc_mas_rec.reopen_date
             where clm_no = v_clm_no;
        exception
        when  OTHERS  then
                 v_err_message := 'hull_clm_mas';
                 rollback;
        End;
        End loop;
      commit;
    End;
    Begin
        For nc_reserved_rec in
        (
        select a.clm_no,a.prem_code,a.type,a.sub_type,a.sts_date,a.amd_date,a.res_amt,a.tot_res_amt,a.offset_flag,a.close_date
          from nc_reserved a
        where a.clm_no = v_clm_no
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                      from nc_reserved b
                                                    where b.clm_no = a.clm_no
                                                 group by b.clm_no)
         ) loop
              if      nc_reserved_rec.type in ('NCNATTYPECLM001','NCNATTYPECLM002')  then
                      v_type := '01';
                      v_clm_date := nc_reserved_rec.sts_date;
              elsif  nc_reserved_rec.type in ('NCNATTYPEREC001','NCNATTYPEREC002') then
                      if      nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC001') then
                              if   nc_reserved_rec.offset_flag = 'Y'  then
                                   v_type := '01';
                                   v_out_type := '07';
                                   v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                   v_type := '02';
                                   v_out_type := '15';
                                   v_rec_close_date := nc_reserved_rec.close_date;
                                   v_sum_rec := v_sum_rec + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEREC002') then
                              v_type := '02';
                              v_out_type := '24';
                              v_sum_rec := v_sum_rec - nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC003') then
                              v_type := '01';
                              v_out_type := '07';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL001') then
                              if    nc_reserved_rec.offset_flag = 'Y'   then
                                    v_type := '01';
                                    v_out_type := '06';
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                    v_type := '03';
                                    v_out_type := '16';
                                    v_sal_close_date := nc_reserved_rec.close_date;
                                    v_sum_sal := v_sum_sal + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL002') then
                              v_type := '03';
                              v_out_type := '26';
                              v_sum_sal := v_sum_sal - nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL003') then
                              v_type := '01';
                              v_out_type := '06';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED001') then
                              if    nc_reserved_rec.offset_flag = 'Y'   then
                                    v_type := '01';
                                    v_out_type := '05';
                                    v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                              else
                                    v_type := '04';
                                    v_out_type := '17';
                                    v_ded_close_date := nc_reserved_rec.close_date;
                                    v_sum_ded := v_sum_ded + nvl(nc_reserved_rec.res_amt,0);
                              end if;
                      elsif  rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPEDED002') then
                              v_type := '01';
                              v_out_type := '05';
                              v_sum_rec_clm := v_sum_rec_clm + nvl(nc_reserved_rec.res_amt,0);
                      else
                              v_type := '01';
                      end if;
              end if;
              if     nc_reserved_rec.type in ('NCNATTYPECLM001')  then
                     v_out_type := '01';
                     v_pa_flag  := 'Y';
                     v_sum_pa := v_sum_pa + nvl(nc_reserved_rec.res_amt,0);
              elsif nc_reserved_rec.type in ('NCNATTYPECLM002')  then
                     if     rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM010')   then
                            v_out_type := '30';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM011')   then
                            v_out_type := '03';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM012')   then
                            v_out_type := '04';
                            v_sum_sur := v_sum_sur + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM013')   then
                            v_out_type := '08';
                            v_sum_set := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM014')   then
                            v_out_type := '31';
                            v_sum_set := v_sum_set + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM015')   then
                            v_out_type := '09';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM016')   then
                            v_out_type := '10';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM017')   then
                            v_out_type := '10';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM018')   then
                            v_out_type := '12';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM019')   then
                            v_out_type := '13';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM020')   then
                            v_out_type := '14';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     elsif rtrim(nc_reserved_rec.sub_type) in ('NCNATSUBTYPECLM021')   then
                            v_out_type := '28';
                            v_sum_exp := v_sum_exp + nvl(nc_reserved_rec.res_amt,0);
                     end if;
              end if;
          --    if    v_out_type  not in  ('01','04')   then
              if    v_type = '01'  then
                    if   v_clm_sts in ('NCCLMSTS01','NCCLMSTS04')  or (v_clm_sts in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_close_date) = trunc(sysdate)) then
                         if    v_out_type  not in  ('01')   then
                               Begin
                                  insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                                  values (v_clm_no,v_out_type,v_state_no,nvl(v_clm_seq,0),v_type,nc_reserved_rec.amd_date,'BHT',nc_reserved_rec.res_amt,1,nc_reserved_rec.res_amt,'4');
                               exception
                                  when  OTHERS  then
                                      v_err_message := 'hull_clm_out';
                                      rollback;
                               End;
                         end if;
                    end if;
              else
                    Begin
                        insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                        values (v_clm_no,v_out_type,v_state_no,nvl(v_clm_seq,0),v_type,nc_reserved_rec.amd_date,'BHT',nc_reserved_rec.res_amt,1,nc_reserved_rec.res_amt,'4');
                    exception
                        when  OTHERS  then
                                  v_err_message := 'hull_clm_out';
                                  rollback;
                    End;
              end if;
         End loop;
         commit;
    End;
    if   v_clm_sts in ('NCCLMSTS01','NCCLMSTS04')  or (v_clm_sts in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_close_date) = trunc(sysdate)) then
       if    v_pa_flag = 'Y'   then
             Begin
                insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
                values (v_clm_no,'01',v_state_no,nvl(v_clm_seq,0),'01',sysdate,'BHT',v_sum_pa,1,v_sum_pa,'1');
             exception
                when  OTHERS  then
                          v_err_message := 'hull_clm_out';
                          rollback;
             End;
       end if;
    end if;
   --  if    nvl(v_sum_sur,0) > 0   then
   --       Begin
   --          insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt,out_agt_sts)
   --          values (v_clm_no,'04',v_state_no,nvl(v_clm_seq,0),'01',sysdate,'BHT',v_sum_sur,1,v_sum_sur,'2');
   --       exception
   --          when  OTHERS  then
   --                    v_err_message := 'hull_clm_out';
   --                    rollback;
   --       End;
   -- end if;
   if   v_clm_sts in ('NCCLMSTS01','NCCLMSTS04')  or (v_clm_sts in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_close_date) = trunc(sysdate)) then
        Begin
            insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,res_amt,typ_flag,corr_date,user_id,close_date,reopen_date,close_mark)
            values (v_clm_no,v_state_no,nvl(v_clm_seq,0),'01',v_clm_date,
                       nvl(v_sum_pa,0)+nvl(v_sum_sur,0)+nvl(v_sum_set,0)-nvl(v_sum_rec_clm,0)+nvl(v_sum_exp,0),'0',sysdate,v_clm_user,
                       decode(v_clm_sts,'NCCLMSTS01',null,'NCCLMSTS04',null,v_close_date), v_reopen_date,decode(v_close_date,null,'N','Y'));
            commit;
        exception
            when  OTHERS  then
                      v_err_message := 'hull_out_stat';
                      rollback;
        End;
    end if;
    if   nvl(v_sum_rec,0) > 0   then
         if  v_rec_state_no is null  then
             Begin
                select to_char(to_number(run_no) + 1)
                   into v_rec_state_no
                 from clm_control_std
               where key =  'CHULLOREC'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
             exception
               when no_data_found then
                v_rec_state_no := null;
               when  others  then
                v_rec_state_no := null;
             End;
             if  v_rec_state_no is not null  then
               BEGIN
                  update clm_control_std a
                  set run_no = v_rec_state_no
                  where key =  'CHULLOREC'||to_char(sysdate,'yyyy')  and run_no <= max_no;
               EXCEPTION
               WHEN OTHERS THEN
                   ROLLBACK;
                   v_rec_state_no := null;
               END;
               COMMIT;
             else
               ROLLBACK;
             end if;
             Begin
                insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,res_amt,typ_flag,corr_date,user_id,close_date,close_mark)
                values (v_clm_no,v_rec_state_no,0,'02',sysdate,nvl(v_sum_rec,0),'0',sysdate,v_clm_user,v_rec_close_date,decode(v_rec_close_date,null,'N','Y'));
                insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                values (v_clm_no,'15',v_rec_state_no,0,'02',sysdate,'BHT',nvl(v_sum_rec,0),1,nvl(v_sum_rec,0));
               commit;
             exception
               when  OTHERS  then
                         v_err_message := 'hull_out_stat';
                        rollback;
             End;
         else
             Begin
                insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,res_amt,typ_flag,corr_date,user_id,close_date,close_mark)
                values (v_clm_no,v_rec_state_no,nvl(v_rec_seq,0),'02',v_rec_state_date,nvl(v_sum_rec,0),'0',sysdate,v_clm_user,v_rec_close_date,decode(v_rec_close_date,null,'N','Y'));
                insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                values (v_clm_no,'15',v_rec_state_no,nvl(v_rec_seq,0),'02',sysdate,'BHT',nvl(v_sum_rec,0),1,nvl(v_sum_rec,0));
               commit;
             exception
               when  OTHERS  then
                        v_err_message := 'hull_out_stat';
                        rollback;
             End;
         end if;
    end if;
    if   nvl(v_sum_sal,0) > 0  then
           if  v_sal_state_no is null  then
               Begin
                  select to_char(to_number(run_no) + 1)
                     into v_sal_state_no
                    from clm_control_std
                  where key =  'CHULLOSAL'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
               exception
                 when no_data_found then
                          v_sal_state_no := null;
                 when  others  then
                          v_sal_state_no := null;
               End;
               if  v_sal_state_no is not null  then
                   BEGIN
                      update clm_control_std a
                            set run_no = v_sal_state_no
                       where key =  'CHULLOSAL'||to_char(sysdate,'yyyy')  and run_no <= max_no;
                   EXCEPTION
                       WHEN OTHERS THEN
                                ROLLBACK;
                                v_sal_state_no := null;
                   END;
                   COMMIT;
               else
                   ROLLBACK;
               end if;
               Begin
                  insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,res_amt,typ_flag,corr_date,user_id,close_date,close_mark)
                  values (v_clm_no,v_sal_state_no,0,'03',sysdate,nvl(v_sum_sal,0),'0',sysdate,v_clm_user,v_sal_close_date,decode(v_sal_close_date,null,'N','Y'));
                  insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                  values (v_clm_no,'16',v_sal_state_no,0,'03',sysdate,'BHT',nvl(v_sum_sal,0),1,nvl(v_sum_sal,0));
                 commit;
               exception
                when  OTHERS  then
                          v_err_message := 'hull_out_stat';
                          rollback;
               End;
          else
               Begin
                  insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,res_amt,typ_flag,corr_date,user_id,close_date,close_mark)
                  values (v_clm_no,v_sal_state_no,nvl(v_sal_seq,0),'03',v_sal_state_date,nvl(v_sum_sal,0),'0',sysdate,v_clm_user,v_sal_close_date,decode(v_sal_close_date,null,'N','Y'));
                  insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                  values (v_clm_no,'16',v_sal_state_no,nvl(v_sal_seq,0),'03',sysdate,'BHT',nvl(v_sum_sal,0),1,nvl(v_sum_sal,0));
                 commit;
               exception
                when  OTHERS  then
                          v_err_message := 'hull_out_stat';
                          rollback;
               End;
          end if;
    end if;
    if   nvl(v_sum_ded,0) > 0  then
          if  v_ded_state_no is null  then
             Begin
                 select to_char(to_number(run_no) + 1)
                    into v_ded_state_no
                   from clm_control_std
                 where key =  'CHULLODED'||to_char(sysdate,'yyyy')  and run_no <= max_no for update of key, run_no;
             exception
              when no_data_found then
                 v_ded_state_no := null;
              when  others  then
                 v_ded_state_no := null;
             End;
             if  v_ded_state_no is not null  then
                 BEGIN
                    update clm_control_std a
                         set run_no = v_ded_state_no
                    where key =  'CHULLODED'||to_char(sysdate,'yyyy')  and run_no <= max_no;
                 EXCEPTION
                    WHEN OTHERS THEN
                         ROLLBACK;
                         v_ded_state_no := null;
                 END;
                 COMMIT;
             else
                 ROLLBACK;
             end if;
             Begin
                 insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,res_amt,typ_flag,corr_date,user_id,close_date,close_mark)
                 values (v_clm_no,v_ded_state_no,0,'04',sysdate,nvl(v_sum_ded,0),'0',sysdate,v_clm_user,v_ded_close_date,decode(v_ded_close_date,null,'N','Y'));
                  insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                  values (v_clm_no,'17',v_ded_state_no,0,'04',sysdate,'BHT',nvl(v_sum_ded,0),1,nvl(v_sum_ded,0));
                commit;
             exception
                when  OTHERS  then
                      v_err_message := 'hull_out_stat';
                     rollback;
             End;
        else
             Begin
                 insert into hull_out_stat (clm_no,state_no,state_seq,type,state_date,res_amt,typ_flag,corr_date,user_id,close_date,close_mark)
                 values (v_clm_no,v_ded_state_no,nvl(v_ded_seq,0),'04',v_ded_state_date,nvl(v_sum_ded,0),'0',sysdate,v_clm_user,v_ded_close_date,decode(v_ded_close_date,null,'N','Y'));
                 insert into hull_clm_out (clm_no,pay_type,state_no,state_seq,type,out_date,out_sign,out_for_amt,out_rte,out_amt)
                 values (v_clm_no,'17',v_ded_state_no,nvl(v_ded_seq,0),'04',sysdate,'BHT',nvl(v_sum_ded,0),1,nvl(v_sum_ded,0));
                commit;
             exception
                when  OTHERS  then
                          v_err_message := 'hull_out_stat';
                          rollback;
             End;
        end if;
    end if;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.type like 'NCNATTYPECLM%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.type like 'NCNATTYPECLM%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into hull_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_shr,ri_out_amt,cess_no)
                 values (v_clm_no,v_state_no,nvl(v_clm_seq,0),'01',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,
                 nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,nc_ri_rec.lett_no);
              exception
                 when  OTHERS  then
                           v_err_message := 'hull_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPEREC%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPEREC%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into hull_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_shr,ri_out_amt,cess_no)
                 values (v_clm_no,v_rec_state_no,nvl(v_rec_seq,0),'02',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,
                 nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,nc_ri_rec.lett_no);
              exception
                 when  OTHERS  then
                            v_err_message := 'hull_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPESAL%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPESAL%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into hull_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_shr,ri_out_amt,cess_no)
                 values (v_clm_no,v_sal_state_no,nvl(v_sal_seq,0),'03',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,
                 nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,nc_ri_rec.lett_no);
              exception
                 when  OTHERS  then
                            v_err_message := 'hull_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
    Begin
        For nc_ri_rec in
        (
            select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  a.sub_type like 'NCNATSUBTYPEDED%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_ri_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.sub_type like 'NCNATSUBTYPEDED%'
                                                     group by b.clm_no)
         ) loop
             Begin
                 insert into hull_ri_out (clm_no,state_no,state_seq,type,ri_code,ri_br_code,lf_flag,ri_type1,ri_type2,ri_shr,ri_out_amt,cess_no)
                 values (v_clm_no,v_ded_state_no,nvl(v_ded_seq,0),'04',nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_type,
                 nc_ri_rec.ri_sub_type,nc_ri_rec.ri_share,nc_ri_rec.org_ri_res_amt,nc_ri_rec.lett_no);
              exception
                 when  OTHERS  then
                            v_err_message := 'hull_ri_out';
                           rollback;
              End;
         End loop;
         commit;
    End;
End;
PROCEDURE nc_insert_misc_table (v_clm_no in varchar2, v_co_type in varchar2, v_co_re in varchar2, v_bki_shr in number, v_agent_code in varchar2, v_agent_seq in varchar2, v_err_message out varchar2) IS
      v_informer             varchar2(60);
      v_contact               varchar2(60);
      v_contact_tel          varchar2(20);
      v_loc_text              varchar2(60);
      v_res_amt             number;
      v_tot_res_amt        number;
      v_mis_code           varchar2(4);
      v_risk_descr          varchar2(60);
      v_res_sts              varchar2(1);
      v_type                  varchar2(2);
      v_rec_no              varchar2(20) := null;
      v_sal_no               varchar2(20) := null;
      v_ded_no              varchar2(20) := null;
      v_cwp_remark      varchar2(80) := null;

BEGIN
     v_err_message := null;
    Begin
            select sum(nvl(a.res_amt,0)),sum(nvl(a.tot_res_amt,0))
               into v_res_amt, v_tot_res_amt
             from nc_reserved a
           where a.clm_no = v_clm_no
              and  a.type like 'NCNATTYPECLM%'
              and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                          from nc_reserved b
                                                        where b.clm_no = a.clm_no
                                                           and  b.type like 'NCNATTYPECLM%'
                                                     group by b.clm_no);
    exception
          when no_data_found then
             v_res_amt := 0;
             v_tot_res_amt := 0;
          when  others  then
             v_res_amt := 0;
             v_tot_res_amt := 0;
    End;
    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,end_seq,recpt_seq,loc_seq,reg_no,clm_yr,pol_yr,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,
                 loc_sum_ins,cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,reg_date,clm_date,loss_date,loss_time,clm_place,surv_code,clm_user,alc_re,loss_detail,
                 prod_grp,prod_type,channel,remark,block,sts_key,catas_code,fax_clm_date,recov_user,cwp_code,cwp_remark,complete_date,clm_sts,close_date
         from nc_mas
       where clm_no = v_clm_no
        ) loop
        Begin
            select informer, contact, contact_tel
               into v_informer, v_contact, v_contact_tel
             from nc_reg_mas
           where reg_no = nc_mas_rec.reg_no;
        exception
          when no_data_found then
             v_informer := null;
             v_contact := null;
             v_contact_tel := null;
          when  others  then
            v_informer := null;
            v_contact := null;
            v_contact_tel := null;
        End;
        Begin
           select substr(loc_text,1,60)
              into v_loc_text
            from mis_loc
          where pol_no = nc_mas_rec.pol_no
             and  pol_run = nc_mas_rec.pol_run
             and  recpt_seq = nc_mas_rec.recpt_seq
             and  end_seq = nc_mas_rec.end_seq
             and  loc_seq = nc_mas_rec.loc_seq;
        exception
             when others then
                v_loc_text := null;
        end;
        Begin
            select mis_code
               into v_mis_code
             from clm_cause_map
           where cause_code = nc_mas_rec.cause_code
               and cause_seq =  nc_mas_rec.cause_seq;
        exception
          when no_data_found then
             v_mis_code := '2112';
          when  others  then
             v_mis_code := '2112';
        End;
        if   v_mis_code is null   then
            v_mis_code := '2112';
        end if;
        Begin
            select descr
               into v_risk_descr
             from risk_descr_std
           where risk_code = v_mis_code
               and th_eng = nc_mas_rec.t_e;
        exception
          when no_data_found then
             v_risk_descr := null;
          when  others  then
             v_risk_descr := null;
        End;
        Begin
           select rtrim(descr)
              into v_cwp_remark
            from clm_constant
          where key = nc_mas_rec.cwp_code;
        exception
             when no_data_found then
                v_cwp_remark := null;
             when  others  then
                v_cwp_remark := null;
        End;
        Begin
           insert into mis_clm_mas (clm_no,main_class,pol_no,pol_run,recpt_seq,loc_seq,ord_no,clm_yr,pol_yr,br_code,mas_cus_code,mas_cus_seq,mas_cus_enq,cus_code,cus_seq,cus_enq,loc_text,
                                                mas_sum_ins,recpt_sum_ins,loc_sum_ins,tot_res,tot_paid,fr_date,to_date,curr_code,curr_rate,co_type,co_re,bki_shr,agent_code,agent_seq,th_eng,reg_date,clm_date,
                                                loss_date,loss_time,risk_descr,location,surv_code,clm_men,pol_cov,first_close,close_date,clm_sts,alc_re,part,clm_curr_code,clm_curr_rate,tot_res_tot,tot_paid_tot,shr_type,end_seq,channel,
                                                prod_grp,prod_type,clm_br_code,risk_descr_part,risk_descr_code,remark,call_name,cont_name,cont_tel,block,sts_key,catas_code,fax_clm_date,rec_men,remark_cwp,complete_date)
            values (v_clm_no,decode(nc_mas_rec.prod_grp,'4','E','5','G','9','S'),nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.recpt_seq,nc_mas_rec.loc_seq,nc_mas_rec.reg_no,nc_mas_rec.clm_yr,nc_mas_rec.pol_yr,
                       '01',nc_mas_rec.mas_cus_code,nc_mas_rec.mas_cus_seq,nc_mas_rec.mas_cus_name,nc_mas_rec.cus_code,nc_mas_rec.cus_seq,nc_mas_rec.cus_name,v_loc_text,nc_mas_rec.mas_sum_ins,
                       nc_mas_rec.recpt_sum_ins,nc_mas_rec.loc_sum_ins,v_res_amt,0,nc_mas_rec.fr_date,nc_mas_rec.to_date,nc_mas_rec.curr_code,nc_mas_rec.curr_rate,v_co_type,v_co_re,v_bki_shr,v_agent_code,
                       v_agent_seq,nc_mas_rec.t_e,nc_mas_rec.reg_date,nc_mas_rec.clm_date,nc_mas_rec.loss_date,nc_mas_rec.loss_time,v_risk_descr,nc_mas_rec.clm_place,nc_mas_rec.surv_code,nc_mas_rec.clm_user,
                       'P',nc_mas_rec.close_date,nc_mas_rec.close_date,decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','3','NCCLMSTS04','4','1'),
                       nc_mas_rec.alc_re,nc_mas_rec.loss_detail,nc_mas_rec.curr_code,nc_mas_rec.curr_rate,v_tot_res_amt,0,v_bki_shr,nc_mas_rec.end_seq,nc_mas_rec.channel,nc_mas_rec.prod_grp,nc_mas_rec.prod_type,
                       '01',nc_mas_rec.loss_detail,v_mis_code,nc_mas_rec.remark,v_informer,v_contact,v_contact_tel,nc_mas_rec.block,nc_mas_rec.sts_key,nc_mas_rec.catas_code,nc_mas_rec.fax_clm_date,rtrim(nc_mas_rec.recov_user),
                       rtrim(v_cwp_remark)||' '||rtrim(nc_mas_rec.cwp_remark),nc_mas_rec.complete_date);

            insert into mis_clm_mas_seq (clm_no,pol_no,pol_run,corr_seq,corr_date,channel,prod_grp,prod_type,clm_date,tot_res,tot_paid,clm_sts,close_date)
            values (v_clm_no,nc_mas_rec.pol_no,nc_mas_rec.pol_run,0,nc_mas_rec.clm_date,nc_mas_rec.channel,nc_mas_rec.prod_grp,nc_mas_rec.prod_type,nc_mas_rec.clm_date,nvl(v_res_amt,0),0,
                       decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','3','NCCLMSTS04','4','1'),nc_mas_rec.close_date);
        exception
        when  OTHERS  then
                  v_err_message := 'mis_clm_mas';
                 rollback;
        End;
        End loop;
      commit;
    End;
        Begin
            For nc_reserved_rec in
            (
            select clm_no,prem_code,type,sub_type,sts_date,amd_date,res_amt,tot_res_amt,offset_flag
             from nc_reserved
           where clm_no = v_clm_no
            ) loop
              if      nc_reserved_rec.type in ('NCNATTYPECLM001','NCNATTYPECLM002')  then
                      v_res_sts := '0';
              elsif  nc_reserved_rec.type in ('NCNATTYPEREC001','NCNATTYPEREC002')   then
                      if      nc_reserved_rec.offset_flag  is null  then
                              if      nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC001','NCNATSUBTYPEREC002') then
                                      v_res_sts := '1';
                              elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL001','NCNATSUBTYPESAL002') then
                                      v_res_sts := '2';
                              elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED001') then
                                      v_res_sts := '3';
                              else
                                      v_res_sts := '1';
                              end if;
                      else
                              v_res_sts := '0';     --- offset
                      end if;
              end if;
              if     nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM001')  then
                     if      nc_reserved_rec.prem_code = '1010' then
                             v_type := '01';
                     elsif  nc_reserved_rec.prem_code in  ('1020')  then
                             v_type := '02';
                     elsif  nc_reserved_rec.prem_code in  ('1030')  then
                             v_type := '37';
                     elsif  nc_reserved_rec.prem_code in  ('1040')  then
                             v_type := '38';
                     elsif  nc_reserved_rec.prem_code in  ('1560')  then
                             v_type := '39';
                     elsif  nc_reserved_rec.prem_code in  ('1050')  then
                             v_type := '03';
                     else
                             v_type := '04';
                     end if;
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM002')  then
                     v_type := '05';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM003')  then
                     v_type := '06';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM004')  then
                     v_type := '25';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM005')  then
                     v_type := '40';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM006')  then
                     v_type := '41';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM010') then
                     v_type := '07';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM011')  then
                     v_type := '30';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM012')  then
                     v_type := '31';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM018')  then
                     v_type := '08';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM019')  then
                     v_type := '36';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM017')  then
                     v_type := '09';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM013')  then
                     v_type := '32';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM014')  then
                     v_type := '33';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM015')  then
                     v_type := '34';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM016')  then
                     v_type := '35';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM020')  then
                     v_type := '42';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM021')  then
                     v_type := '43';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED002') then
                     v_type := '28';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL003') then
                     v_type := '29';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC003') then
                     v_type := '00';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC001') then
                     v_type := '00';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL001') then
                     v_type := '29';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED001') then
                     v_type := '28';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC002') then
                     v_type := '42';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL002') then
                     v_type := '43';
              else
                     v_type := '00';
              end if;

              if   v_res_sts in ('0')  then
                  Begin
                      insert into mis_cms_res (clm_no,sectn,risk_code,prem_code,type,res_seq,res_date,res_amt,res_type,res_sts,res_flag,tot_res_amt,corr_date,res_no)
                      values (v_clm_no,1,v_mis_code,rtrim(nc_reserved_rec.prem_code),v_type,0,nc_reserved_rec.sts_date,nc_reserved_rec.res_amt,'O',v_res_sts,'0',nc_reserved_rec.tot_res_amt,
                                 nc_reserved_rec.sts_date,'0000000000');
                  exception
                       when  OTHERS  then
                                 v_err_message := 'mis_cms_res';
                                 rollback;
                  End;
              end if;
              if   v_res_sts  in ('1','2','3')  then
                   if   v_res_sts  in  ('1')  and  v_rec_no is null   then
                        Begin
                           select to_char(to_number(run_no) + 1)
                              into v_rec_no
                            from clm_control_std
                          where key =  'CMSR'||to_char(sysdate,'YYYY')  and run_no <= max_no for update of key, run_no;
                        exception
                          when no_data_found then
                                   v_rec_no := null;
                          when  others  then
                                   v_rec_no := null;
                        End;
                        if  v_rec_no is not null  then
                            Begin
                               update clm_control_std a
                                     set run_no = v_rec_no
                                where key =  'CMSR'||to_char(sysdate,'yyyy')  and run_no <= max_no;
                            exception
                                when others then
                                         rollback;
                                         v_rec_no := null;
                            End;
                            commit;
                            Begin
                                insert into mis_cms_res (clm_no,sectn,risk_code,prem_code,type,res_seq,res_date,res_amt,res_type,res_sts,res_flag,tot_res_amt,corr_date,res_no)
                                values (v_clm_no,1,v_mis_code,rtrim(nc_reserved_rec.prem_code),v_type,0,nc_reserved_rec.sts_date,nc_reserved_rec.res_amt,'O',v_res_sts,'0',nc_reserved_rec.tot_res_amt,
                                            nc_reserved_rec.sts_date,v_rec_no);
                               insert into mis_recovery (clm_no,rec_no,item_seq,rec_seq,rec_type,rec_kind,amt)
                               values (v_clm_no,v_rec_no,1,0,v_res_sts,'0',nc_reserved_rec.res_amt);
                            exception
                               when  OTHERS  then
                                          v_err_message := 'mis_recovery';
                                         rollback;
                            End;
                        else
                            rollback;
                        end if;
                   end if;
                   if   v_res_sts  in  ('2')  and  v_sal_no is null   then
                        Begin
                           select to_char(to_number(run_no) + 1)
                              into v_sal_no
                            from clm_control_std
                          where key =  'CMSS'||to_char(sysdate,'YYYY')  and run_no <= max_no for update of key, run_no;
                        exception
                          when no_data_found then
                                   v_sal_no := null;
                          when  others  then
                                   v_sal_no := null;
                        End;
                        if  v_sal_no is not null  then
                            Begin
                               update clm_control_std a
                                     set run_no = v_sal_no
                                where key =  'CMSS'||to_char(sysdate,'yyyy')  and run_no <= max_no;
                            exception
                                when others then
                                         rollback;
                                         v_sal_no := null;
                            End;
                            commit;
                            Begin
                                insert into mis_cms_res (clm_no,sectn,risk_code,prem_code,type,res_seq,res_date,res_amt,res_type,res_sts,res_flag,tot_res_amt,corr_date,res_no)
                                values (v_clm_no,1,v_mis_code,rtrim(nc_reserved_rec.prem_code),v_type,0,nc_reserved_rec.sts_date,nc_reserved_rec.res_amt,'O',v_res_sts,'0',nc_reserved_rec.tot_res_amt,
                                           nc_reserved_rec.sts_date,v_sal_no);
                               insert into mis_recovery (clm_no,rec_no,item_seq,rec_seq,rec_type,rec_kind,amt)
                               values (v_clm_no,v_sal_no,1,0,v_res_sts,'0',nc_reserved_rec.res_amt);
                            exception
                               when  OTHERS  then
                                          v_err_message := 'mis_recovery';
                                         rollback;
                            End;
                        else
                            rollback;
                        end if;
                   end if;
                   if   v_res_sts  in  ('3')  and  v_ded_no is null   then
                        Begin
                           select to_char(to_number(run_no) + 1)
                              into v_ded_no
                            from clm_control_std
                          where key =  'CMSD'||to_char(sysdate,'YYYY')  and run_no <= max_no for update of key, run_no;
                        exception
                          when no_data_found then
                                   v_ded_no := null;
                          when  others  then
                                   v_ded_no := null;
                        End;
                        if  v_ded_no is not null  then
                            Begin
                               update clm_control_std a
                                     set run_no = v_ded_no
                                where key =  'CMSD'||to_char(sysdate,'yyyy')  and run_no <= max_no;
                            exception
                                when others then
                                         rollback;
                                         v_ded_no := null;
                            End;
                            commit;
                            Begin
                                insert into mis_cms_res (clm_no,sectn,risk_code,prem_code,type,res_seq,res_date,res_amt,res_type,res_sts,res_flag,tot_res_amt,corr_date,res_no)
                                values (v_clm_no,1,v_mis_code,rtrim(nc_reserved_rec.prem_code),v_type,0,nc_reserved_rec.sts_date,nc_reserved_rec.res_amt,'O',v_res_sts,'0',nc_reserved_rec.tot_res_amt,
                                            nc_reserved_rec.sts_date,v_ded_no);
                               insert into mis_recovery (clm_no,rec_no,item_seq,rec_seq,rec_type,rec_kind,amt)
                               values (v_clm_no,v_ded_no,1,0,v_res_sts,'0',nc_reserved_rec.res_amt);
                            exception
                               when  OTHERS  then
                                          v_err_message := 'mis_recovery';
                                         rollback;
                            End;
                        else
                            rollback;
                        end if;
                   end if;
                   Begin
                       insert into mis_rec_mas_seq (clm_no,rec_type,corr_seq,corr_date,rec_date,rec_sts,tot_res_rec,offset)
                       values (v_clm_no,v_res_sts,0,sysdate,sysdate,'1',nc_reserved_rec.res_amt,'2');
                   exception
                    when  OTHERS  then
                               v_err_message := 'mis_rec_mas_seq';
                             rollback;
                   End;
              End if;
            End loop;
            commit;
        End;
        Begin
            For nc_ri_rec in
            (
            select a.clm_no,a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.sub_type,a.type,a.trn_seq
             from nc_ri_reserved a
           where a.clm_no = v_clm_no
              and  (a.clm_no,a.type,a.trn_seq) = (select b.clm_no,b.type,max(b.trn_seq)
                                                                    from nc_ri_reserved b
                                                                  where b.clm_no = a.clm_no
                                                                     and  b.type = a.type
                                                                group by b.clm_no,b.type)
             ) loop
             Begin
                 insert into mis_cri_res (clm_no,ri_code,ri_br_code,ri_type,ri_res_date,ri_res_amt,ri_shr,lett_no,lett_prt,lett_type,res_sts,corr_seq,lf_flag,ri_sub_type)
                 values (v_clm_no,nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_type,nc_ri_rec.ri_amd_date,nc_ri_rec.org_ri_res_amt,nc_ri_rec.ri_share,nc_ri_rec.lett_no,decode(nc_ri_rec.lett_no,null,'N','Y'),
                            nc_ri_rec.lett_type,decode(nc_ri_rec.sub_type,'NCNATSUBTYPECLM001','0','NCNATSUBTYPEREC001','1','NCNATSUBTYPESAL001','2','NCNATSUBTYPEDED001','3','0'),0,nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_sub_type);
              exception
                 when  OTHERS  then
                            v_err_message := 'mis_cri_res';
                           rollback;
              End;
            End loop;
            commit;
        End;
END;
PROCEDURE nc_update_misc_table (v_clm_no in varchar2, v_err_message out varchar2) IS
      v_res_amt             number := 0;
      v_paid_amt           number := 0;
      v_tot_res_amt       number := 0;
      v_mas_seq            number := 0;
      v_res_seq             number := 0;
      v_rec_rec             number := 0;
      v_rec_sal              number := 0;
      v_rec_ded             number := 0;
      v_rec_seq             number := null;
      v_sal_seq             number := null;
      v_ded_seq            number := null;
      v_mis_code           varchar2(4) := null;
      v_risk_descr          varchar2(60) := null;
       v_loc_text            varchar2(60) := null;
      v_res_sts              varchar2(1) := null;
      v_type                  varchar2(2) := null;
      v_rec_no              varchar2(20) := null;
      v_sal_no               varchar2(20) := null;
      v_ded_no              varchar2(20) := null;
      v_chk_mas_seq     varchar2(1) := null;
      v_cwp_remark       varchar2(80) := null;
      v_nc_status           varchar2(20) := null;
      v_nc_close_date     date := null;

BEGIN
     v_err_message := null;
    Begin
        select sum(nvl(a.res_amt,0)),sum(nvl(a.tot_res_amt,0))
           into v_res_amt, v_tot_res_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
          and  a.type like 'NCNATTYPECLM%'
          and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                      from nc_reserved b
                                                    where b.clm_no = a.clm_no
                                                       and  b.type like 'NCNATTYPECLM%'
                                                 group by b.clm_no);
    exception
          when no_data_found then
     --        v_chk_mas_seq := 'N';
             v_res_amt := 0;
             v_tot_res_amt := 0;
          when  others  then
     --        v_chk_mas_seq := 'N';
             v_res_amt := 0;
             v_tot_res_amt := 0;
    End;
  --  if   v_chk_mas_seq is null   then
  --       v_chk_mas_seq := 'Y';
  --  end if;
    Begin
       select sum(nvl(a.pay_total,0))
          into v_paid_amt
        from  mis_clm_paid a
      where  a.clm_no = v_clm_no
         and  (a.clm_no,a.pay_no,a.corr_seq) = (select a2.clm_no,a2.pay_no,max(a2.corr_seq)
                                                                      from mis_clm_paid a2
                                                                    where a2.clm_no = a.clm_no
                                                                       and  a2.pay_no = a.pay_no
                                                                       and  a2.pay_sts = a.pay_sts
                                                                       and  a2.pay_sts = '0'
                                                                       and  a2.state_flag = '1'
                                                                 group by a2.clm_no,a2.pay_no)
         and  a.pay_sts = '0'
         and  a.state_flag = '1'
         group by a.clm_no;
    exception
          when no_data_found then
             v_paid_amt := 0;
          when  others  then
             v_paid_amt := 0;
    End;
    Begin
       select max(nvl(corr_seq,0)) + 1
          into v_mas_seq
         from mis_clm_mas_seq
      where clm_no = v_clm_no;
    exception
      when no_data_found then
             v_mas_seq := 0;
        --     v_chk_mas_seq := null;
      when  others  then
             v_mas_seq := 0;
        --     v_chk_mas_seq := null;
    End;
    Begin
       select max(res_seq) + 1
          into v_res_seq
        from mis_cms_res
      where clm_no = v_clm_no;
    exception
          when no_data_found then
             v_res_seq := 0;
          when  others  then
             v_res_seq := 0;
    End;
    Begin
       select rec_no,max(rec_seq) + 1
          into v_rec_no,v_rec_seq
        from mis_recovery
      where clm_no = v_clm_no
         and  rec_type = '1'
         and  rec_kind = '0'
      group by rec_no;
    exception
          when no_data_found then
             v_rec_no := null;
             v_rec_seq := null;
          when  others  then
             v_rec_no := null;
             v_rec_seq :=null;
    End;
    Begin
       select rec_no,max(rec_seq) + 1
          into v_sal_no,v_sal_seq
        from mis_recovery
      where clm_no = v_clm_no
         and  rec_type = '2'
         and  rec_kind = '0'
     group by rec_no;
    exception
          when no_data_found then
             v_sal_no := null;
             v_sal_seq := null;
          when  others  then
             v_sal_no := null;
             v_sal_seq := null;
    End;
    Begin
       select rec_no,max(rec_seq) + 1
          into v_ded_no,v_ded_seq
        from mis_recovery
      where clm_no = v_clm_no
         and  rec_type = '3'
         and  rec_kind = '0'
     group by rec_no;
    exception
          when no_data_found then
             v_ded_no := null;
             v_ded_seq := null;
          when  others  then
             v_ded_no := null;
             v_ded_seq := null;
    End;
    Begin
        select a.tot_rec_rec
           into v_rec_rec
         from mis_rec_mas_seq a
       where a.clm_no = v_clm_no
          and  a.rec_type = '1'
          and  (a.clm_no,a.rec_type,a.corr_seq) = (select b.clm_no,b.rec_type,max(b.corr_seq)
                                                                        from mis_rec_mas_seq b
                                                                      where b.clm_no = a.clm_no
                                                                         and  b.rec_type = a.rec_type
                                                                         and b.rec_type = '1'
                                                                  group by b.clm_no,b.rec_type);
    exception
          when no_data_found then
             v_rec_rec := 0;
          when  others  then
             v_rec_rec := 0;
    End;
     Begin
        select a.tot_rec_rec
           into v_rec_sal
         from mis_rec_mas_seq a
       where a.clm_no = v_clm_no
          and  a.rec_type = '2'
          and  (a.clm_no,a.rec_type,a.corr_seq) = (select b.clm_no,b.rec_type,max(b.corr_seq)
                                                                        from mis_rec_mas_seq b
                                                                      where b.clm_no = a.clm_no
                                                                         and  b.rec_type = a.rec_type
                                                                         and b.rec_type = '2'
                                                                  group by b.clm_no,b.rec_type);
    exception
          when no_data_found then
             v_rec_sal := 0;
          when  others  then
             v_rec_sal := 0;
    End;
     Begin
        select a.tot_rec_rec
           into v_rec_ded
         from mis_rec_mas_seq a
       where a.clm_no = v_clm_no
          and  a.rec_type = '3'
          and  (a.clm_no,a.rec_type,a.corr_seq) = (select b.clm_no,b.rec_type,max(b.corr_seq)
                                                                        from mis_rec_mas_seq b
                                                                      where b.clm_no = a.clm_no
                                                                         and  b.rec_type = a.rec_type
                                                                         and b.rec_type = '3'
                                                                  group by b.clm_no,b.rec_type);
    exception
          when no_data_found then
             v_rec_ded := 0;
          when  others  then
             v_rec_ded := 0;
    End;
    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,end_seq,recpt_seq,loc_seq,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,loc_sum_ins,
                  cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,clm_date,loss_date,loss_time,clm_place,surv_code,clm_user,alc_re,loss_detail,remark,block,
                  channel,prod_grp,prod_type,catas_code,fax_clm_date,recov_user,close_date,reopen_date,clm_sts,cwp_remark,cwp_code,complete_date
         from nc_mas
       where clm_no = v_clm_no
        ) loop
         Begin
           select mis_code
              into v_mis_code
            from clm_cause_map
          where cause_code = nc_mas_rec.cause_code
              and cause_seq =  nc_mas_rec.cause_seq;
        exception
             when no_data_found then
                v_mis_code := '2112';
             when  others  then
                v_mis_code := '2112';
        End;
        if   v_mis_code is null   then
            v_mis_code := '2112';
        end if;
        Begin
            select descr
               into v_risk_descr
             from risk_descr_std
           where risk_code = v_mis_code
               and th_eng = nc_mas_rec.t_e;
        exception
              when no_data_found then
                 v_risk_descr := null;
              when  others  then
                 v_risk_descr := null;
        End;
        Begin
           select substr(loc_text,1,60)
              into v_loc_text
            from mis_loc
          where pol_no = nc_mas_rec.pol_no
             and  pol_run = nc_mas_rec.pol_run
             and  recpt_seq = nc_mas_rec.recpt_seq
             and  end_seq = nc_mas_rec.end_seq
             and  loc_seq = nc_mas_rec.loc_seq;
        exception
             when others then
                v_loc_text := null;
        end;
        Begin
           select rtrim(descr)
              into v_cwp_remark
            from clm_constant
          where key = nc_mas_rec.cwp_code;
        exception
             when no_data_found then
                v_cwp_remark := null;
             when  others  then
                v_cwp_remark := null;
        End;
        v_nc_status := rtrim(nc_mas_rec.clm_sts);
        v_nc_close_date := trunc(nc_mas_rec.close_date);
        Begin
           update  mis_clm_mas  set  end_seq = nc_mas_rec.end_seq, recpt_seq = nc_mas_rec.recpt_seq, loc_seq = nc_mas_rec.loc_seq, mas_cus_code = nc_mas_rec.mas_cus_code,
                                                  mas_cus_seq = nc_mas_rec.mas_cus_seq, mas_cus_enq = nc_mas_rec.mas_cus_name, cus_code = nc_mas_rec.cus_code, cus_seq = nc_mas_rec.cus_seq,
                                                  cus_enq = nc_mas_rec.cus_name, mas_sum_ins = nc_mas_rec.mas_sum_ins, recpt_sum_ins = nc_mas_rec.recpt_sum_ins, loc_sum_ins = nc_mas_rec.loc_sum_ins,
                                                  risk_descr_code = v_mis_code, fr_date = nc_mas_rec.fr_date, to_date = nc_mas_rec.to_date, clm_curr_code = nc_mas_rec.curr_code, risk_descr = v_risk_descr, loc_text = v_loc_text,
                                                  clm_curr_rate = nc_mas_rec.curr_rate, th_eng = nc_mas_rec.t_e, clm_date = nc_mas_rec.clm_date, loss_date = nc_mas_rec.loss_date, loss_time = nc_mas_rec.loss_time,
                                                  location = nc_mas_rec.clm_place, surv_code = nc_mas_rec.surv_code, clm_men = nc_mas_rec.clm_user, alc_re = nc_mas_rec.alc_re, part = nc_mas_rec.loss_detail,
                                                  risk_descr_part = nc_mas_rec.loss_detail,remark = nc_mas_rec.remark, block = nc_mas_rec.block, tot_res = v_res_amt, tot_res_tot = v_tot_res_amt, tot_paid = v_paid_amt,
                                                  catas_code = nc_mas_rec.catas_code, fax_clm_date = nc_mas_rec.fax_clm_date, rec_men = rtrim(nc_mas_rec.recov_user),
                                                  close_date = nc_mas_rec.close_date,  reopen_date = nc_mas_rec.reopen_date,
                                                  clm_sts = decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','3','NCCLMSTS04','4','1'),
                                                  first_close = decode(first_close,null,nc_mas_rec.close_date,first_close),
                                                  remark_cwp = rtrim(v_cwp_remark)||' '||rtrim(nc_mas_rec.cwp_remark),complete_date = nc_mas_rec.complete_date

            where clm_no = v_clm_no;
        exception
        when  OTHERS  then
                   v_err_message := 'mis_clm_mas';
                  rollback;
        End;
        if   nc_mas_rec.clm_sts in ('NCCLMSTS01','NCCLMSTS04')  or (nc_mas_rec.clm_sts in ('NCCLMSTS02','NCCLMSTS03')  and trunc(nc_mas_rec.close_date) = trunc(sysdate)) then
             Begin
                 insert into mis_clm_mas_seq (clm_no,pol_no,pol_run,corr_seq,corr_date,channel,prod_grp,prod_type,clm_date,tot_res,tot_paid,clm_sts,close_date,reopen_date)
                 values (v_clm_no,nc_mas_rec.pol_no,nc_mas_rec.pol_run,v_mas_seq,sysdate,nc_mas_rec.channel,nc_mas_rec.prod_grp,nc_mas_rec.prod_type,
                             nc_mas_rec.clm_date,v_res_amt,v_paid_amt,decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','3','NCCLMSTS04','4','1'),
                             decode(nc_mas_rec.clm_sts,'NCCLMSTS01',null,nc_mas_rec.close_date), nc_mas_rec.reopen_date);
             exception
             when  OTHERS  then
                       v_err_message := 'mis_clm_mas_seq';
                       rollback;
             End;
        end if;
        End loop;
      commit;
    End;
    Begin
        For nc_reserved_rec in
        (
        select a.clm_no,a.prem_code,a.type,a.sub_type,a.sts_date,a.amd_date,a.res_amt,a.tot_res_amt,a.offset_flag,a.trn_seq,a.status,a.close_date
          from nc_reserved a
        where a.clm_no = v_clm_no
           and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                         from nc_reserved b
                                                       where b.clm_no = a.clm_no
                                                   group by b.clm_no)
        ) loop
              if      nc_reserved_rec.type in ('NCNATTYPECLM001','NCNATTYPECLM002')  then
                      v_res_sts := '0';
              elsif  nc_reserved_rec.type in ('NCNATTYPEREC001','NCNATTYPEREC002') then
                      if      nc_reserved_rec.offset_flag  is null  then
                              if      nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC001','NCNATSUBTYPEREC002') then
                                      v_res_sts := '1';
                              elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL001','NCNATSUBTYPESAL002') then
                                      v_res_sts := '2';
                              elsif  nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED001') then
                                      v_res_sts := '3';
                              else
                                      v_res_sts := '1';
                              end if;
                      else
                              v_res_sts := '0';     --- offset
                      end if;
              end if;
              if     nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM001')  then
                     if      nc_reserved_rec.prem_code = '1010' then
                             v_type := '01';
                     elsif  nc_reserved_rec.prem_code in  ('1020')  then
                             v_type := '02';
                     elsif  nc_reserved_rec.prem_code in  ('1030')  then
                             v_type := '37';
                     elsif  nc_reserved_rec.prem_code in  ('1040')  then
                             v_type := '38';
                     elsif  nc_reserved_rec.prem_code in  ('1560')  then
                             v_type := '39';
                     elsif  nc_reserved_rec.prem_code in  ('1050')  then
                             v_type := '03';
                     else
                             v_type := '04';
                     end if;
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM002')  then
                     v_type := '05';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM003')  then
                     v_type := '06';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM004')  then
                     v_type := '25';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM005')  then
                     v_type := '40';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM006')  then
                     v_type := '41';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM010') then
                     v_type := '07';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM011')  then
                     v_type := '30';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM012')  then
                     v_type := '31';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM018')  then
                     v_type := '08';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM019')  then
                     v_type := '36';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM017')  then
                     v_type := '09';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM013')  then
                     v_type := '32';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM014')  then
                     v_type := '33';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM015')  then
                     v_type := '34';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM016')  then
                     v_type := '35';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM020')  then
                     v_type := '42';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPECLM021')  then
                     v_type := '43';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED002') then
                     v_type := '28';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL003') then
                     v_type := '29';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC003') then
                     v_type := '00';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC001') then
                     v_type := '00';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL001') then
                     v_type := '29';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPEDED001') then
                     v_type := '28';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPEREC002') then
                     v_type := '42';
              elsif nc_reserved_rec.sub_type in ('NCNATSUBTYPESAL002') then
                     v_type := '43';
              else
                     v_type := '00';
              end if;
              if   v_res_sts  in ('1','2','3')  then
                   if   v_res_sts  in  ('1')  and  v_rec_no is null   then
                        Begin
                           select to_char(to_number(run_no) + 1)
                              into v_rec_no
                            from clm_control_std
                          where key =  'CMSR'||to_char(sysdate,'YYYY')  and run_no <= max_no for update of key, run_no;
                        exception
                          when no_data_found then
                                   v_rec_no := null;
                          when  others  then
                                   v_rec_no := null;
                        End;
                        if  v_rec_no is not null  then
                            Begin
                               update clm_control_std a
                                     set run_no = v_rec_no
                                where key =  'CMSR'||to_char(sysdate,'yyyy')  and run_no <= max_no;
                            exception
                                when others then
                                         rollback;
                                         v_rec_no := null;
                            End;
                            commit;
                            Begin
                               insert into mis_rec_mas_seq (clm_no,rec_type,corr_seq,corr_date,rec_date,rec_sts,tot_res_rec,offset,close_date,tot_rec_rec)
                               values (v_clm_no,v_res_sts,0,sysdate,nc_reserved_rec.sts_date,decode(nc_reserved_rec.status,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','2','NCCLMSTS04','1','1'),
                                          nc_reserved_rec.res_amt,'2',nc_reserved_rec.close_date,v_rec_rec);

                               insert into mis_recovery (clm_no,rec_no,item_seq,rec_seq,rec_type,rec_kind,amt)
                               values (v_clm_no,v_rec_no,1,0,v_res_sts,'0',nc_reserved_rec.res_amt);
                            exception
                               when  OTHERS  then
                                          v_err_message := 'mis_rec_mas_seq';
                                         rollback;
                            End;
                        else
                            rollback;
                        end if;
                   elsif   v_res_sts  in  ('1')  and  v_rec_no is not null   then
                            Begin
                               insert into mis_rec_mas_seq (clm_no,rec_type,corr_seq,corr_date,rec_date,rec_sts,tot_res_rec,offset,close_date,tot_rec_rec)
                               values (v_clm_no,v_res_sts,nvl(v_rec_seq,0),sysdate,nc_reserved_rec.sts_date,decode(nc_reserved_rec.status,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','2','NCCLMSTS04','1','1'),
                                          nc_reserved_rec.res_amt,'2',nc_reserved_rec.close_date,v_rec_rec);

                               insert into mis_recovery (clm_no,rec_no,item_seq,rec_seq,rec_type,rec_kind,amt)
                               values (v_clm_no,v_rec_no,1,nvl(v_rec_seq,0),v_res_sts,'0',nc_reserved_rec.res_amt);
                            exception
                               when  OTHERS  then
                                          v_err_message := 'mis_rec_mas_seq';
                                         rollback;
                            End;
                   end if;
                   if   v_res_sts  in  ('2')  and  v_sal_no is null   then
                        Begin
                           select to_char(to_number(run_no) + 1)
                              into v_sal_no
                            from clm_control_std
                          where key =  'CMSS'||to_char(sysdate,'YYYY')  and run_no <= max_no for update of key, run_no;
                        exception
                          when no_data_found then
                                   v_sal_no := null;
                          when  others  then
                                   v_sal_no := null;
                        End;
                        if  v_sal_no is not null  then
                            Begin
                               update clm_control_std a
                                     set run_no = v_sal_no
                                where key =  'CMSS'||to_char(sysdate,'yyyy')  and run_no <= max_no;
                            exception
                                when others then
                                         rollback;
                                         v_sal_no := null;
                            End;
                            commit;
                            Begin
                               insert into mis_rec_mas_seq (clm_no,rec_type,corr_seq,corr_date,rec_date,rec_sts,tot_res_rec,offset,close_date,tot_rec_rec)
                               values (v_clm_no,v_res_sts,0,sysdate,nc_reserved_rec.sts_date,decode(nc_reserved_rec.status,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','2','NCCLMSTS04','1','1'),
                               nc_reserved_rec.res_amt,'2',nc_reserved_rec.close_date,v_rec_sal);

                               insert into mis_recovery (clm_no,rec_no,item_seq,rec_seq,rec_type,rec_kind,amt)
                               values (v_clm_no,v_sal_no,1,0,v_res_sts,'0',nc_reserved_rec.res_amt);
                            exception
                               when  OTHERS  then
                                          v_err_message := 'mis_rec_mas_seq';
                                         rollback;
                            End;
                        else
                            rollback;
                        end if;
                   elsif   v_res_sts  in  ('2')  and  v_sal_no is not null   then
                            Begin
                               insert into mis_rec_mas_seq (clm_no,rec_type,corr_seq,corr_date,rec_date,rec_sts,tot_res_rec,offset,close_date,tot_rec_rec)
                               values (v_clm_no,v_res_sts,nvl(v_sal_seq,0),sysdate,nc_reserved_rec.sts_date,decode(nc_reserved_rec.status,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','2','NCCLMSTS04','1','1'),
                                          nc_reserved_rec.res_amt,'2',nc_reserved_rec.close_date,v_rec_sal);

                               insert into mis_recovery (clm_no,rec_no,item_seq,rec_seq,rec_type,rec_kind,amt)
                               values (v_clm_no,v_sal_no,1,nvl(v_sal_seq,0),v_res_sts,'0',nc_reserved_rec.res_amt);
                            exception
                               when  OTHERS  then
                                          v_err_message := 'mis_rec_mas_seq';
                                         rollback;
                            End;
                   end if;
                    if   v_res_sts  in  ('3')  and  v_ded_no is null   then
                        Begin
                           select to_char(to_number(run_no) + 1)
                              into v_ded_no
                            from clm_control_std
                          where key =  'CMSD'||to_char(sysdate,'YYYY')  and run_no <= max_no for update of key, run_no;
                        exception
                          when no_data_found then
                                   v_ded_no := null;
                          when  others  then
                                   v_ded_no := null;
                        End;
                        if  v_ded_no is not null  then
                            Begin
                               update clm_control_std a
                                     set run_no = v_ded_no
                                where key =  'CMSD'||to_char(sysdate,'yyyy')  and run_no <= max_no;
                            exception
                                when others then
                                         rollback;
                                         v_ded_no := null;
                            End;
                            commit;
                            Begin
                               insert into mis_rec_mas_seq (clm_no,rec_type,corr_seq,corr_date,rec_date,rec_sts,tot_res_rec,offset,close_date,tot_rec_rec)
                               values (v_clm_no,v_res_sts,0,sysdate,nc_reserved_rec.sts_date,decode(nc_reserved_rec.status,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','2','NCCLMSTS04','1','1'),
                                          nc_reserved_rec.res_amt,'2',nc_reserved_rec.close_date,v_rec_ded);

                               insert into mis_recovery (clm_no,rec_no,item_seq,rec_seq,rec_type,rec_kind,amt)
                               values (v_clm_no,v_ded_no,1,0,v_res_sts,'0',nc_reserved_rec.res_amt);
                            exception
                               when  OTHERS  then
                                          v_err_message := 'mis_rec_mas_seq';
                                         rollback;
                            End;
                        else
                            rollback;
                        end if;
                   elsif   v_res_sts  in  ('3')  and  v_ded_no is not null   then
                            Begin
                               insert into mis_rec_mas_seq (clm_no,rec_type,corr_seq,corr_date,rec_date,rec_sts,tot_res_rec,offset,close_date,tot_rec_rec)
                               values (v_clm_no,v_res_sts,nvl(v_ded_seq,0),sysdate,nc_reserved_rec.sts_date,decode(nc_reserved_rec.status,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','2','NCCLMSTS04','1','1'),
                                          nc_reserved_rec.res_amt,'2',nc_reserved_rec.close_date,v_rec_ded);

                               insert into mis_recovery (clm_no,rec_no,item_seq,rec_seq,rec_type,rec_kind,amt)
                               values (v_clm_no,v_ded_no,1,nvl(v_ded_seq,0),v_res_sts,'0',nc_reserved_rec.res_amt);
                            exception
                               when  OTHERS  then
                                          v_err_message := 'mis_rec_mas_seq';
                                         rollback;
                            End;
                   end if;
              End if;
              if   v_res_sts  = '0'   then
                   if  v_nc_status in ('NCCLMSTS01','NCCLMSTS04')  or (v_nc_status in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_nc_close_date) = trunc(sysdate))   then
                       Begin
                          insert into mis_cms_res (clm_no,sectn,risk_code,prem_code,type,res_seq,res_date,res_amt,res_type,res_sts,res_flag,tot_res_amt,corr_date,res_no)
                          values (v_clm_no,1,v_mis_code,rtrim(nc_reserved_rec.prem_code),v_type,nvl(v_res_seq,0),nc_reserved_rec.sts_date,nc_reserved_rec.res_amt,'O',v_res_sts,'0',nc_reserved_rec.tot_res_amt,
                                     nc_reserved_rec.amd_date,decode(v_res_sts,'0','0000000000','1',v_rec_no,'2',v_sal_no,'3',v_ded_no,'0000000000'));
                       exception
                          when  OTHERS  then
                                   v_err_message := 'mis_cms_res';
                                  rollback;
                       End;
                   end if;
              elsif  v_res_sts in ('1','2','3')  then
                      Begin
                          insert into mis_cms_res (clm_no,sectn,risk_code,prem_code,type,res_seq,res_date,res_amt,res_type,res_sts,res_flag,tot_res_amt,corr_date,res_no)
                          values (v_clm_no,1,v_mis_code,rtrim(nc_reserved_rec.prem_code),v_type,decode(v_res_sts,'0',nvl(v_res_seq,0),'1',nvl(v_rec_seq,0),'2',nvl(v_sal_seq,0),'3',nvl(v_ded_seq,0),nvl(v_res_seq,0)),
                                     nc_reserved_rec.sts_date,nc_reserved_rec.res_amt,'O',v_res_sts,'0',nc_reserved_rec.tot_res_amt,
                                     nc_reserved_rec.amd_date,decode(v_res_sts,'0','0000000000','1',v_rec_no,'2',v_sal_no,'3',v_ded_no,'0000000000'));
                      exception
                          when  OTHERS  then
                                   v_err_message := 'mis_cms_res';
                                  rollback;
                      End;
              end if;
        End loop;
       commit;
    End;
    Begin
        For nc_ri_rec in
        (
        select a.clm_no,a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.ri_amd_date,a.org_ri_res_amt,a.lett_no,a.lett_type,a.cashcall,a.lett_prt,a.type,a.sub_type,a.trn_seq,a.status
         from nc_ri_reserved a
       where a.clm_no = v_clm_no
          and  (a.clm_no,a.type,a.trn_seq) = (select b.clm_no,b.type,max(b.trn_seq)
                                                                from nc_ri_reserved b
                                                              where b.clm_no = a.clm_no
                                                                  and b.type = a.type
                                                           group by b.clm_no,b.type)
         ) loop
           if      nc_ri_rec.type in ('NCNATTYPECLM001','NCNATTYPECLM002')  then
                      v_res_sts := '0';
           elsif  nc_ri_rec.type in ('NCNATTYPEREC001') then
                   if      nc_ri_rec.sub_type in ('NCNATSUBTYPEREC001') then
                           v_res_sts := '1';
                   elsif  nc_ri_rec.sub_type in ('NCNATSUBTYPESAL001') then
                           v_res_sts := '2';
                   elsif  nc_ri_rec.sub_type in ('NCNATSUBTYPEDED001') then
                           v_res_sts := '3';
                   else
                           v_res_sts := '1';
                   end if;
           end if;
           if   v_res_sts  = '0'   then
                if  v_nc_status in ('NCCLMSTS01','NCCLMSTS04')  or (v_nc_status in ('NCCLMSTS02','NCCLMSTS03')  and trunc(v_nc_close_date) = trunc(sysdate))   then
                   Begin
                      insert into mis_cri_res (clm_no,ri_code,ri_br_code,ri_type,ri_res_date,ri_res_amt,ri_shr,lett_no,lett_prt,lett_type,res_sts,corr_seq,lf_flag,ri_sub_type)
                      values (v_clm_no,nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_type,nc_ri_rec.ri_amd_date,nc_ri_rec.org_ri_res_amt,nc_ri_rec.ri_share,nc_ri_rec.lett_no,decode(nc_ri_rec.lett_no,null,'N','Y'),
                                 nc_ri_rec.lett_type,v_res_sts,nvl(v_res_seq,0),nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_sub_type);
                   exception
                   when  OTHERS  then
                              v_err_message := 'mis_cri_res';
                             rollback;
                   End;
                end if;
            elsif   v_res_sts = '1'  then
                     Begin
                        insert into mis_cri_res (clm_no,ri_code,ri_br_code,ri_type,ri_res_date,ri_res_amt,ri_shr,lett_no,lett_prt,lett_type,res_sts,corr_seq,lf_flag,ri_sub_type)
                        values (v_clm_no,nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_type,nc_ri_rec.ri_amd_date,nc_ri_rec.org_ri_res_amt,nc_ri_rec.ri_share,nc_ri_rec.lett_no,nc_ri_rec.lett_prt,nc_ri_rec.lett_type,
                                   v_res_sts,nvl(v_rec_seq,0),nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_sub_type);
                     exception
                     when  OTHERS  then
                               v_err_message := 'mis_cri_res';
                              rollback;
                     End;
            elsif   v_res_sts = '2'  then
                     Begin
                         insert into mis_cri_res (clm_no,ri_code,ri_br_code,ri_type,ri_res_date,ri_res_amt,ri_shr,lett_no,lett_prt,lett_type,res_sts,corr_seq,lf_flag,ri_sub_type)
                         values (v_clm_no,nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_type,nc_ri_rec.ri_amd_date,nc_ri_rec.org_ri_res_amt,nc_ri_rec.ri_share,nc_ri_rec.lett_no,nc_ri_rec.lett_prt,nc_ri_rec.lett_type,
                                    v_res_sts,nvl(v_sal_seq,0),nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_sub_type);
                     exception
                     when  OTHERS  then
                                v_err_message := 'mis_cri_res';
                               rollback;
                     End;
            elsif   v_res_sts = '3'  then
                     Begin
                         insert into mis_cri_res (clm_no,ri_code,ri_br_code,ri_type,ri_res_date,ri_res_amt,ri_shr,lett_no,lett_prt,lett_type,res_sts,corr_seq,lf_flag,ri_sub_type)
                         values (v_clm_no,nc_ri_rec.ri_code,nc_ri_rec.ri_br_code,nc_ri_rec.ri_type,nc_ri_rec.ri_amd_date,nc_ri_rec.org_ri_res_amt,nc_ri_rec.ri_share,nc_ri_rec.lett_no,nc_ri_rec.lett_prt,nc_ri_rec.lett_type,
                                    v_res_sts,nvl(v_ded_seq,0),nc_ri_rec.ri_lf_flag,nc_ri_rec.ri_sub_type);
                     exception
                     when  OTHERS  then
                                v_err_message := 'mis_cri_res';
                               rollback;
                     End;
            end if;
            End loop;
            commit;
        End;
END;
PROCEDURE nc_update_fire_mas (v_clm_no in varchar2, v_err_message out varchar2) IS
      v_res_amt             number := 0;
      v_rec_amt             number := 0;
      v_tot_res_amt        number := 0;
      v_tot_paid              number := 0;
      v_clm_seq              number := 0;
      v_rec_sts               varchar2(1) := null;
      v_fir_code              varchar2(4) := null;
      v_state_no             varchar2(16) := null;
      v_pol_te                varchar2(1);
      v_pol_br                varchar2(3);
      v_loc1                   varchar2(50);
      v_loc2                   varchar2(50);
      v_loc3                   varchar2(50);
      v_loc_am               varchar2(2);
      v_loc_jw                varchar2(2);
      v_class1                 varchar2(1);
      v_class2                 varchar2(1);
      v_risk_exp              varchar2(4);
      v_ext_exp               varchar2(4);
      v_pol_type              varchar2(2);
      v_cus_te                 varchar2(1);
      v_co_type               varchar2(1);
      v_leader                 varchar2(1);
      v_contact               varchar2(30);
      v_your_pol_no        varchar2(30);
      v_your_end_no       varchar2(30);
      v_ben_code            varchar2(4);
      v_ben_descr           varchar2(100);
      v_type                    varchar2(2);
      v_out_type              varchar2(2);
      v_co_shr                number(6,3) := 0;
      v_clm_date            date := null;
      v_rec_date            date := null;
      v_sal_date            date := null;
Begin
    v_err_message := null;
    Begin
        select sum(nvl(a.res_amt,0)),sum(nvl(a.tot_res_amt,0))
           into v_res_amt, v_tot_res_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
           and a.type like 'NCNATTYPECLM%'
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                       from nc_reserved b
                                                     where b.clm_no = a.clm_no
                                                        and  b.type like 'NCNATTYPECLM%'
                                                  group by b.clm_no);
    exception
          when no_data_found then
             v_res_amt := 0;
             v_tot_res_amt := 0;
          when  others  then
             v_res_amt := 0;
             v_tot_res_amt := 0;
    End;
    Begin
        select sum(nvl(a.res_amt,0))
           into v_rec_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
           and a.type like 'NCNATTYPEREC%'
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                       from nc_reserved b
                                                     where b.clm_no = a.clm_no
                                                        and  b.type like 'NCNATTYPEREC%'
                                                  group by b.clm_no);
    exception
          when no_data_found then
             v_rec_amt := 0;
          when  others  then
             v_rec_amt := 0;
    End;
    if  nvl(v_rec_amt,0) > 0  then
         v_rec_sts := '1';
    else
         v_rec_sts := '0';
    end if;
    Begin
       select  nvl(a.tot_our_loss,0)
          into  v_tot_paid
        from  fir_paid_stat a
      where  a.clm_no = v_clm_no
         and   a.type = '01'
         and   (a.state_no,a.state_seq) in (select a1.state_no,max(a1.state_seq) from fir_paid_stat a1
                                                         where a1.clm_no = a.clm_no
                                                             and a1.state_no = a.state_no
                                                             and a1.type = '01'
                                                      group by a1.state_no);
    exception
          when no_data_found then
             v_tot_paid := 0;
          when  others  then
             v_tot_paid := 0;
    End;
    Begin
       select state_no,max(state_seq) + 1
          into v_state_no,v_clm_seq
        from fir_out_stat
      where clm_no = v_clm_no
         and type = '01'
    group by state_no;
    exception
          when no_data_found then
             v_state_no := null;
             v_clm_seq := 0;
          when  others  then
             v_state_no := null;
             v_clm_seq := 0;
    End;
    if  v_state_no is null  then
        v_state_no := '0000000000000000';
    end if;
    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,end_no,end_run,end_seq,recpt_seq,loc_seq,reg_no,clm_yr,pol_yr,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,
                 bki_shr,loc_sum_ins,cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,reg_date,clm_date,loss_date,loss_time,clm_place,surv_code,surv_date,clm_user,loss_detail,your_clm_no,
                 prod_grp,prod_type,channel,fir_source,catas_code,fax_clm_date,remark,block,sts_key,clm_sts,close_date,reopen_date,complete_date
         from nc_mas
       where clm_no = v_clm_no
        ) loop
        Begin
            select fir_code
               into v_fir_code
             from clm_cause_map
           where cause_code = nc_mas_rec.cause_code
               and cause_seq =  nc_mas_rec.cause_seq;
        exception
          when no_data_found then
             v_fir_code := '2112';
          when  others  then
             v_fir_code := '2112';
        End;
        Begin
            select substr(full_name,1,30)
               into v_contact
             from survey_std
           where surv_code = nc_mas_rec.surv_code;
        exception
          when no_data_found then
             v_contact := null;
          when  others  then
            v_contact := null;
        End;
        CLFIR.fir_inward_your_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.end_seq,v_your_pol_no,v_your_end_no);
        CLFIR.fir_text_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.end_seq,v_ben_code,v_ben_descr);
        CLFIR.co_shr_lib(nc_mas_rec.pol_no,nc_mas_rec.pol_run,nc_mas_rec.end_seq,v_co_shr);

        Begin
            select a.pol_te,a.pol_br,a.loc1,a.loc2,a.loc3,a.loc_am,a.loc_jw,a.class1,a.class2,a.risk_exp,a.ext_exp,a.pol_type,a.cus_te,b.co_type,b.leader
               into v_pol_te,v_pol_br,v_loc1,v_loc2,v_loc3,v_loc_am,v_loc_jw,v_class1,v_class2,v_risk_exp,v_ext_exp,v_pol_type,v_cus_te,v_co_type,v_leader
             from fir_pol_mas a,fir_pol_seq b
           where a.pol_no   = nc_mas_rec.pol_no
              and  a.pol_run  = nc_mas_rec.pol_run
              and  (to_char(nc_mas_rec.loss_date,'YYYY/MM/DD') between to_char(b.fr_date,'YYYY/MM/DD') and to_char(b.to_date,'YYYY/MM/DD')) and
                     b.end_seq  = (select max(s.end_seq)
                                            from fir_pol_seq s
                                          where s.pol_no  = nc_mas_rec.pol_no
                                             and  s.pol_run = nc_mas_rec.pol_run
                                             and  (to_char(nc_mas_rec.loss_date,'YYYY/MM/DD') >= to_char(s.fr_date,'YYYY/MM/DD')))
              and a.pol_no   = b.pol_no
              and a.pol_run  = b.pol_run;
        exception
          when no_data_found then
             v_pol_te := null;
             v_pol_br := null;
             v_loc1 := null;
             v_loc2 := null;
             v_loc3 := null;
             v_loc_am := null;
             v_loc_jw := null;
             v_class1 := null;
             v_class2 := null;
             v_risk_exp := null;
             v_ext_exp := null;
             v_pol_type := null;
             v_cus_te := null;
             v_co_type := null;
             v_leader := null;
          when  others  then
             v_pol_te := null;
             v_pol_br := null;
             v_loc1 := null;
             v_loc2 := null;
             v_loc3 := null;
             v_loc_am := null;
             v_loc_jw := null;
             v_class1 := null;
             v_class2 := null;
             v_risk_exp := null;
             v_ext_exp := null;
             v_pol_type := null;
             v_cus_te := null;
             v_co_type := null;
             v_leader := null;
        End;
        Begin
           update fir_clm_mas set end_no = substr(nc_mas_rec.end_no,1,13), end_seq = nc_mas_rec.end_seq, your_pol_no = v_your_pol_no, your_end_no = v_your_end_no, your_clm_no = nc_mas_rec.your_clm_no,
                                              block = nc_mas_rec.block, co_type = v_co_type, leader = v_leader, bki_shr = nc_mas_rec.bki_shr,  fr_date = nc_mas_rec.fr_date, to_date = nc_mas_rec.to_date,
                                              tot_sum_ins = nc_mas_rec.mas_sum_ins, sum_ins = nc_mas_rec.recpt_sum_ins, tot_res = v_res_amt, tot_paid = v_tot_paid, tot_rec = v_rec_amt, loc1 = v_loc1, loc2 = v_loc2,
                                              loc3 = v_loc3, loc_am = v_loc_am, loc_jw = v_loc_jw, class1 = v_class1, class2 = v_class2, risk_exp = v_risk_exp, ext_exp = v_ext_exp, cause = v_fir_code,
                                              damg_descr = nc_mas_rec.loss_detail, surv_code = nc_mas_rec.surv_code, clm_men = nc_mas_rec.clm_user, corr_date = sysdate, surv_date = nc_mas_rec.surv_date,
                                              loss_date = nc_mas_rec.loss_date, clm_rec_date = nc_mas_rec.clm_date, rec_sts = v_rec_sts, remark = substr(nc_mas_rec.remark,1,200), ben_code = v_ben_code,
                                              ben_descr =  v_ben_descr, gen_risk = nc_mas_rec.fir_source, risk_loc = substr(nc_mas_rec.clm_place,1,100), co_shr = nc_mas_rec.bki_shr,  loss_time = nc_mas_rec.loss_time,
                                              end_run = nc_mas_rec.end_run, catas_code = nc_mas_rec.catas_code, fax_clm_date = nc_mas_rec.fax_clm_date, contact = v_contact ,
                                              clm_sts = decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','4','NCCLMSTS03','5','NCCLMSTS04','6','1'),
                                              complete_date = trunc(nc_mas_rec.complete_date)
            where clm_no = v_clm_no;

            insert into fir_correct_clm (tran_date,clm_no,pol_no,state_no,state_seq,pol_cat,type,status,amt,pol_type,pol_run,prod_type) values
            (sysdate,v_clm_no,nc_mas_rec.pol_no,v_state_no,v_clm_seq,decode(nc_mas_rec.channel,'9','9','0'),'02','1',v_res_amt,v_pol_type,nc_mas_rec.pol_run,nc_mas_rec.prod_type);

        exception
        when  OTHERS  then
                 v_err_message := 'fir_clm_mas';
                 rollback;
        End;
        End loop;
      commit;
    End;
END;
PROCEDURE nc_update_mrn_mas (v_clm_no in varchar2, v_err_message out varchar2) IS
      v_res_amt             number;
      v_mrn_code           varchar2(4);
      v_pol_te                 varchar2(1);
      v_pol_br                varchar2(3);
      v_agent_code         varchar2(5);
      v_agent_seq           varchar2(2);
      v_pol_type              varchar2(2);
      v_cus_te                 varchar2(1);
      v_co_type               varchar2(1);
      v_vessel_code         varchar2(7);
      v_vessel_seq           number;
      v_vessel_enq           varchar2(35);
      v_sailing_date         varchar2(10);
      v_pack_code           varchar2(3);
      v_surv_agent          varchar2(6);
      v_sett_agent          varchar2(6);
      v_curr_code           varchar2(3);
      v_curr_rate            number(13,10);
      v_fr_port                varchar2(4);
      v_to_port               varchar2(4);
      v_i_e                     varchar2(1);
      v_int_code             varchar2(5);
      v_flight_no             varchar2(7);
      v_cond_code          varchar2(4);
      v_fgn_sum_ins       number(12);
      v_clm_date            date;
      v_close_date          date;
      v_reopen_date       date;
      v_rec_close_date    date;
      v_sal_close_date    date;
      v_ded_close_date   date;
      v_clm_sts              varchar2(20);
      v_sum_ded            number(14,2) := 0;
      v_sum_pa              number(14,2) := 0;
      v_sum_exp            number(14,2) := 0;
      v_your_pol_no        varchar2(30);
      v_your_end_no       varchar2(30);
      v_ben_code            varchar2(4);
      v_ben_descr           varchar2(100);
      v_type                    varchar2(2);
      v_out_type              varchar2(2);
      v_pa_flag                varchar2(1) := 'N';
      v_co_shr                number(6,3) := 0;
      v_flag                    boolean;
Begin
    v_err_message := null;
    Begin
        select sum(nvl(a.res_amt,0))
           into v_res_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
           and a.type like 'NCNATTYPECLM%'
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                       from nc_reserved b
                                                     where b.clm_no = a.clm_no
                                                        and  b.type like 'NCNATTYPECLM%'
                                                  group by b.clm_no);
    exception
          when no_data_found then
             v_res_amt := 0;
          when  others  then
             v_res_amt := 0;
    End;
    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,pol_seq,end_no,end_run,end_seq,recpt_seq,loc_seq,reg_no,clm_yr,pol_yr,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,
                 bki_shr,loc_sum_ins,cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,reg_date,clm_date,loss_date,loss_time,clm_place,surv_code,surv_date,clm_user,loss_detail,your_clm_no,
                 prod_grp,prod_type,channel,fir_source,catas_code,fax_clm_date,remark,block,sts_key,carr_agent,consign,nat_clm_flag,arrv_date,del_date,time_bar,pi_club,reopen_date,close_date,clm_sts,
                 complete_date
         from nc_mas
       where clm_no = v_clm_no
        ) loop
        Begin
            select mrn_code
               into v_mrn_code
             from clm_cause_map
           where cause_code = nc_mas_rec.cause_code
               and cause_seq =  nc_mas_rec.cause_seq;
        exception
          when no_data_found then
             v_mrn_code := '2112';
          when  others  then
             v_mrn_code := '2112';
        End;
        Begin
           select a.vessel_code,a.vessel_seq,a.sailing_dd||'/'||a.sailing_mm||'/'||a.sailing_yy,a.pack_code,a.surv_agent,a.sett_agent,a.curr_code,a.fr_port,a.to_port,a.i_e,a.int_code,
                    a.agent_code,a.agent_seq,a.curr_rate,a.flight_no,a.cond_code
              into v_vessel_code,v_vessel_seq,v_sailing_date,v_pack_code,v_surv_agent,v_sett_agent,v_curr_code,v_fr_port,v_to_port,v_i_e,v_int_code,v_agent_code,v_agent_seq,
                    v_curr_rate,v_flight_no,v_cond_code
             from mrn_pol a
           where a.pol_no  = nc_mas_rec.pol_no
               and a.pol_run = nc_mas_rec.pol_run
               and a.pol_seq = nc_mas_rec.pol_seq
               and (a.flag_cancel is null or a.end_type <> '8')
               and a.end_seq = (select max(b.end_seq)
                                           from mrn_pol b
                                         where b.pol_no  = a.pol_no
                                             and b.pol_run = a.pol_run
                                             and b.pol_seq = a.pol_seq
                                             and (b.flag_cancel is null or b.end_type <> '8'));
        exception
          when no_data_found then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_sailing_date := null;
                   v_pack_code := null;
                   v_surv_agent := null;
                   v_sett_agent := null;
                   v_curr_code := null;
                   v_fr_port := null;
                   v_to_port := null;
                   v_i_e := null;
                   v_int_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_flight_no := null;
                   v_cond_code := null;
          when others  then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_sailing_date := null;
                   v_pack_code := null;
                   v_surv_agent := null;
                   v_sett_agent := null;
                   v_curr_code := null;
                   v_fr_port := null;
                   v_to_port := null;
                   v_i_e := null;
                   v_int_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_flight_no := null;
                   v_cond_code := null;
        End;
        Begin
           select  sum(fgn_sum_ins)
              into  v_fgn_sum_ins
             from mrn_pol
           where pol_no  =  nc_mas_rec.pol_no
              and  pol_run =  nc_mas_rec.pol_run
              and  vessel_code <> 'TBC';
        exception
        when no_data_found then
                 v_fgn_sum_ins := 0;
        end;
        v_vessel_enq  := substr(clmn_new.vessel_name(v_vessel_code,v_vessel_seq,v_flag),1,35);
        Begin
           update mrn_clm_mas  set end_no = substr(nc_mas_rec.end_no,1,13), end_seq = nc_mas_rec.end_seq, your_clm = substr(nc_mas_rec.your_clm_no,1,25), cus_code = nc_mas_rec.mas_cus_code, cus_seq = nc_mas_rec.mas_cus_seq,
                                                 cus_enq = substr(nc_mas_rec.mas_cus_name,1,35), vessel_code = v_vessel_code, vessel_seq = v_vessel_seq, vessel_enq = v_vessel_enq, flight_no = v_flight_no, fr_port = v_fr_port,
                                                 to_port = v_to_port, sett_agent = v_sett_agent, surv_agent = v_surv_agent, carr_agent = nc_mas_rec.carr_agent, pi_club = nc_mas_rec.pi_club, time_bar = nc_mas_rec.time_bar,
                                                 i_e = v_i_e, int_code = v_int_code, pack_code = v_pack_code, cond_code = v_cond_code, curr_code = nc_mas_rec.curr_code, curr_rate = nc_mas_rec.curr_rate,
                                                 fgn_sum_ins = v_fgn_sum_ins, sum_ins = nc_mas_rec.recpt_sum_ins, tot_sum_ins = nc_mas_rec.mas_sum_ins, tot_out = v_res_amt, surv_code = substr(nc_mas_rec.surv_code,1,4),
                                                 del_date = nc_mas_rec.del_date, sailing_date = v_sailing_date, loss_date = nc_mas_rec.loss_date, arrv_date = nc_mas_rec.arrv_date, clm_rec_date = nc_mas_rec.clm_date,
                                                 surv_date = nc_mas_rec.surv_date, consign = nc_mas_rec.consign, cause = v_mrn_code,nat_clm = nc_mas_rec.nat_clm_flag, clm_men = nc_mas_rec.clm_user,
                                                 remark = substr(nc_mas_rec.remark,1,200), damg_descr = nc_mas_rec.loss_detail, t_e = nc_mas_rec.t_e, end_run = nc_mas_rec.end_run, catas_code = nc_mas_rec.catas_code,
                                                 fax_clm_date = nc_mas_rec.fax_clm_date, clm_sts = decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','3','NCCLMSTS04','4','1'),
                                                 complete_date = nc_mas_rec.complete_date
             where clm_no = v_clm_no;
        exception
        when  OTHERS  then
                 v_err_message := 'mrn_clm_mas';
                 rollback;
        End;
        End loop;
      commit;
    End;
END;
PROCEDURE nc_update_hull_mas (v_clm_no in varchar2, v_err_message out varchar2) IS
      v_res_amt             number;
      v_mrn_code           varchar2(4);
      v_clm_sts               varchar2(1);
      v_rec_sts               varchar2(1);
      v_pol_te                 varchar2(1);
      v_pol_br                varchar2(3);
      v_agent_code         varchar2(5);
      v_agent_seq           varchar2(2);
      v_pol_type              varchar2(2);
      v_cus_te                 varchar2(1);
      v_co_type               varchar2(1);
      v_rec_state_no       varchar2(16);
      v_sal_state_no       varchar2(16);
      v_ded_state_no      varchar2(16);
      v_rec_state_date    date;
      v_sal_state_date     date;
      v_ded_state_date    date;
      v_rec_seq              number;
      v_sal_seq              number;
      v_ded_seq             number;
      v_vessel_code         varchar2(7);
      v_vessel_seq           number;
      v_vessel_enq           varchar2(35);
      v_clm_user             varchar2(10);
      v_curr_code           varchar2(3);
      v_curr_rate            number(8,5);
      v_cond_code          varchar2(4);
      v_clm_date            date;
      v_your_pol_no        varchar2(30);
      v_your_end_no       varchar2(30);
      v_ben_code            varchar2(4);
      v_ben_descr           varchar2(100);
      v_type                    varchar2(2);
      v_out_type              varchar2(2);
      v_co_shr                number(6,3) := 0;
      v_flag                    boolean;
Begin
    v_err_message := null;
    Begin
        select sum(nvl(a.res_amt,0))
           into v_res_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
           and a.type like 'NCNATTYPECLM%'
           and (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                       from nc_reserved b
                                                     where b.clm_no = a.clm_no
                                                        and  b.type like 'NCNATTYPECLM%'
                                                  group by b.clm_no);
    exception
          when no_data_found then
             v_res_amt := 0;
          when  others  then
             v_res_amt := 0;
    End;

    Begin
        select clm_user
           into v_clm_user
         from nc_mas a
       where a.clm_no = v_clm_no;
    exception
          when no_data_found then
             v_clm_user := null;
          when  others  then
             v_clm_user := null;
    End;
    Begin
       select state_no,state_date,max(state_seq) + 1
          into v_rec_state_no,v_rec_state_date,v_rec_seq
        from hull_out_stat
      where clm_no = v_clm_no
         and type = '02'
    group by state_no,state_date;
    exception
          when no_data_found then
             v_rec_state_no := null;
             v_rec_state_date := null;
             v_rec_seq := 0;
          when  others  then
             v_rec_state_no := null;
             v_rec_state_date := null;
             v_rec_seq := 0;
    End;
    Begin
       select state_no,state_date,max(state_seq) + 1
          into v_sal_state_no,v_sal_state_date,v_sal_seq
        from hull_out_stat
      where clm_no = v_clm_no
         and type = '03'
    group by state_no,state_date;
    exception
          when no_data_found then
             v_sal_state_no := null;
             v_sal_state_date := null;
             v_sal_seq := 0;
          when  others  then
             v_sal_state_no := null;
             v_sal_state_date := null;
             v_sal_seq := 0;
    End;
    Begin
       select state_no,state_date,max(state_seq) + 1
          into v_ded_state_no,v_ded_state_date,v_ded_seq
        from hull_out_stat
      where clm_no = v_clm_no
         and type = '04'
    group by state_no,state_date;
    exception
          when no_data_found then
             v_ded_state_no := null;
             v_ded_state_date := null;
             v_ded_seq := 0;
          when  others  then
             v_ded_state_no := null;
             v_ded_state_date := null;
             v_ded_seq := 0;
    End;
    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,pol_seq,end_no,end_run,end_seq,recpt_seq,loc_seq,reg_no,clm_yr,pol_yr,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,
                 bki_shr,loc_sum_ins,cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,reg_date,clm_date,loss_date,loss_time,clm_place,surv_code,surv_date,clm_user,loss_detail,your_clm_no,
                 prod_grp,prod_type,channel,fir_source,catas_code,fax_clm_date,remark,block,sts_key,carr_agent,consign,nat_clm_flag,arrv_date,del_date,time_bar,pi_club,clm_sts,close_date,reopen_date
         from nc_mas
       where clm_no = v_clm_no
        ) loop
        Begin
            select mrn_code
               into v_mrn_code
             from clm_cause_map
           where cause_code = nc_mas_rec.cause_code
               and cause_seq =  nc_mas_rec.cause_seq;
        exception
          when no_data_found then
             v_mrn_code := '2112';
          when  others  then
             v_mrn_code := '2112';
        End;
        Begin
           select a.vessel_code,a.vessel_seq,a.curr_code,a.agent_code,a.agent_seq,a.curr_rate,a.cond_code
              into v_vessel_code,v_vessel_seq,v_curr_code,v_agent_code,v_agent_seq,v_curr_rate,v_cond_code
             from hull_pol a
           where a.pol_no  = nc_mas_rec.pol_no
               and a.pol_run = nc_mas_rec.pol_run
               and (a.flag_cancel is null or a.end_type <> '8')
               and a.end_seq = (select max(b.end_seq)
                                           from mrn_pol b
                                         where b.pol_no  = a.pol_no
                                             and b.pol_run = a.pol_run
                                             and (b.flag_cancel is null or b.end_type <> '8'));
        exception
          when no_data_found then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_curr_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_cond_code := null;
          when others  then
                   v_vessel_code := null;
                   v_vessel_seq := null;
                   v_curr_code := null;
                   v_agent_code := null;
                   v_agent_seq := null;
                   v_curr_rate := null;
                   v_cond_code := null;
        End;
    if nc_mas_rec.clm_sts in ('NCCLMSTS01') then
          v_clm_sts := '1';
    elsif nc_mas_rec.clm_sts in ('NCCLMSTS02') then
          v_clm_sts := '3';
    elsif nc_mas_rec.clm_sts in ('NCCLMSTS03') then
          v_clm_sts := '4';
    elsif nc_mas_rec.clm_sts in ('NCCLMSTS04') then
          v_clm_sts := '5';
    else
          v_clm_sts := '1';
    end if;
    if v_rec_state_no is not null or v_sal_state_no is not null or v_ded_state_no is not null  then
       v_rec_sts := '1';
    else
       v_rec_sts := '0';
    end if;
    v_vessel_enq  := substr(clmn_new.vessel_hull_name(v_vessel_code,v_vessel_seq,v_flag),1,35);
        Begin
           update hull_clm_mas  set end_no = substr(nc_mas_rec.end_no,1,13), end_seq = nc_mas_rec.end_seq, your_clm = substr(nc_mas_rec.your_clm_no,1,25), cus_code = nc_mas_rec.mas_cus_code, cus_seq = nc_mas_rec.mas_cus_seq,
                                                 cus_enq = substr(nc_mas_rec.mas_cus_name,1,80), vessel_code = v_vessel_code, vessel_seq = v_vessel_seq, vessel_enq = v_vessel_enq,
                                                 carr_agent = nc_mas_rec.carr_agent, pi_club = nc_mas_rec.pi_club, cond_code = v_cond_code, curr_code = nc_mas_rec.curr_code, curr_rate = nc_mas_rec.curr_rate, tot_res = v_res_amt,
                                                 surv_code = substr(nc_mas_rec.surv_code,1,4), loss_date = nc_mas_rec.loss_date, clm_rec_date = nc_mas_rec.clm_date, surv_date = nc_mas_rec.surv_date, cause = v_mrn_code,
                                                 clm_men = nc_mas_rec.clm_user, remark = substr(nc_mas_rec.remark,1,200), damg_descr = nc_mas_rec.loss_detail, location = substr(nc_mas_rec.clm_place,1,50), end_run = nc_mas_rec.end_run,
                                                 catas_code = nc_mas_rec.catas_code, fax_clm_date = nc_mas_rec.fax_clm_date, clm_sts = v_clm_sts, recov_sts = v_rec_sts
             where clm_no = v_clm_no;
        exception
        when  OTHERS  then
                 v_err_message := 'hull_clm_mas';
                 rollback;
        End;
        End loop;
      commit;
    End;
END;
PROCEDURE nc_update_misc_mas (v_clm_no in varchar2, v_err_message out varchar2) IS
      v_mis_code           varchar2(4) := null;
      v_paid_amt           number := 0;
      v_res_amt            number := 0;
      v_tot_res_amt       number := 0;
      v_risk_descr          varchar2(60) := null;
      v_loc_text             varchar2(60) := null;
      v_cwp_remark       varchar2(80) := null;
Begin
    Begin
        select sum(nvl(a.res_amt,0)),sum(nvl(a.tot_res_amt,0))
           into v_res_amt, v_tot_res_amt
         from nc_reserved a
       where a.clm_no = v_clm_no
          and  a.type like 'NCNATTYPECLM%'
          and  (a.clm_no,a.trn_seq) = (select b.clm_no,max(b.trn_seq)
                                                      from nc_reserved b
                                                    where b.clm_no = a.clm_no
                                                       and  b.type like 'NCNATTYPECLM%'
                                                 group by b.clm_no);
    exception
          when no_data_found then
             v_res_amt := 0;
             v_tot_res_amt := 0;
          when  others  then
             v_res_amt := 0;
             v_tot_res_amt := 0;
    End;
    Begin
       select sum(nvl(a.pay_total,0))
          into v_paid_amt
        from  mis_clm_paid a
      where  a.clm_no = v_clm_no
         and  (a.clm_no,a.pay_no,a.corr_seq) = (select a2.clm_no,a2.pay_no,max(a2.corr_seq)
                                                                      from mis_clm_paid a2
                                                                    where a2.clm_no = a.clm_no
                                                                       and  a2.pay_no = a.pay_no
                                                                       and  a2.pay_sts = a.pay_sts
                                                                       and  a2.pay_sts = '0'
                                                                       and  a2.state_flag = '1'
                                                                 group by a2.clm_no,a2.pay_no)
         and  a.pay_sts = '0'
         and  a.state_flag = '1'
         group by a.clm_no;
    exception
          when no_data_found then
             v_paid_amt := 0;
          when  others  then
             v_paid_amt := 0;
    End;
    Begin
        For nc_mas_rec in
        (
        select pol_no,pol_run,end_seq,recpt_seq,loc_seq,mas_cus_code,mas_cus_seq,mas_cus_name,cus_code,cus_seq,cus_name,mas_sum_ins,recpt_sum_ins,loc_sum_ins,
                  cause_code,cause_seq,fr_date,to_date,curr_code,curr_rate,t_e,clm_date,loss_date,loss_time,clm_place,surv_code,clm_user,alc_re,loss_detail,remark,block,
                  channel,prod_grp,prod_type,catas_code,fax_clm_date,recov_user,close_date,reopen_date,clm_sts,cwp_remark,cwp_code,complete_date
         from nc_mas
       where clm_no = v_clm_no
        ) loop
         Begin
           select mis_code
              into v_mis_code
            from clm_cause_map
          where cause_code = nc_mas_rec.cause_code
              and cause_seq =  nc_mas_rec.cause_seq;
        exception
             when no_data_found then
                v_mis_code := '2112';
             when  others  then
                v_mis_code := '2112';
        End;
        if   v_mis_code is null   then
            v_mis_code := '2112';
        end if;
        Begin
            select descr
               into v_risk_descr
             from risk_descr_std
           where risk_code = v_mis_code
               and th_eng = nc_mas_rec.t_e;
        exception
              when no_data_found then
                 v_risk_descr := null;
              when  others  then
                 v_risk_descr := null;
        End;
        Begin
           select substr(loc_text,1,60)
              into v_loc_text
            from mis_loc
          where pol_no = nc_mas_rec.pol_no
             and  pol_run = nc_mas_rec.pol_run
             and  recpt_seq = nc_mas_rec.recpt_seq
             and  end_seq = nc_mas_rec.end_seq
             and  loc_seq = nc_mas_rec.loc_seq;
        exception
             when others then
                v_loc_text := null;
        end;
        Begin
           select rtrim(descr)
              into v_cwp_remark
            from clm_constant
          where key = nc_mas_rec.cwp_code;
        exception
             when no_data_found then
                v_cwp_remark := null;
             when  others  then
                v_cwp_remark := null;
        End;
        Begin
           update  mis_clm_mas  set  end_seq = nc_mas_rec.end_seq, recpt_seq = nc_mas_rec.recpt_seq, loc_seq = nc_mas_rec.loc_seq, mas_cus_code = nc_mas_rec.mas_cus_code,
                                                  mas_cus_seq = nc_mas_rec.mas_cus_seq, mas_cus_enq = nc_mas_rec.mas_cus_name, cus_code = nc_mas_rec.cus_code, cus_seq = nc_mas_rec.cus_seq,
                                                  cus_enq = nc_mas_rec.cus_name, mas_sum_ins = nc_mas_rec.mas_sum_ins, recpt_sum_ins = nc_mas_rec.recpt_sum_ins, loc_sum_ins = nc_mas_rec.loc_sum_ins,
                                                  risk_descr_code = v_mis_code, fr_date = nc_mas_rec.fr_date, to_date = nc_mas_rec.to_date, clm_curr_code = nc_mas_rec.curr_code, risk_descr = v_risk_descr, loc_text = v_loc_text,
                                                  clm_curr_rate = nc_mas_rec.curr_rate, th_eng = nc_mas_rec.t_e, clm_date = nc_mas_rec.clm_date, loss_date = nc_mas_rec.loss_date, loss_time = nc_mas_rec.loss_time,
                                                  location = nc_mas_rec.clm_place, surv_code = nc_mas_rec.surv_code, clm_men = nc_mas_rec.clm_user, alc_re = nc_mas_rec.alc_re, part = nc_mas_rec.loss_detail,
                                                  risk_descr_part = nc_mas_rec.loss_detail,remark = nc_mas_rec.remark, block = nc_mas_rec.block, tot_res = v_res_amt, tot_res_tot = v_tot_res_amt, tot_paid = v_paid_amt,
                                                  catas_code = nc_mas_rec.catas_code, fax_clm_date = nc_mas_rec.fax_clm_date, rec_men = rtrim(nc_mas_rec.recov_user),
                                                  clm_sts = decode(nc_mas_rec.clm_sts,'NCCLMSTS01','1','NCCLMSTS02','2','NCCLMSTS03','3','NCCLMSTS04','4','1'),
                                                  remark_cwp = rtrim(v_cwp_remark)||' '||rtrim(nc_mas_rec.cwp_remark),complete_date = nc_mas_rec.complete_date
            where clm_no = v_clm_no;

        exception
        when  OTHERS  then
                   v_err_message := 'mis_clm_mas';
                 rollback;
        End;
        End loop;
        commit;
   End;
End;
PROCEDURE nc_insert_reinsurance_tmp (p_sts_key in number, p_pla_no in varchar2, p_cashcall in varchar2, p_ri_type1 in varchar2, p_ri_code in varchar2, p_ri_br_code in varchar2, p_ri_type2 in varchar2, p_lf_flag in varchar2,
                                                            p_ri_share in number, pri_res_amt in number, p_lines in number)  IS
 BEGIN
     Begin
         insert into  nc_reinsurance_tmp (sts_key, pla_no, cashcall, ri_code, ri_br_code, lf_flag, ri_type1, ri_type2, ri_share, ri_reserve_amt, lines)
         values (p_sts_key, p_pla_no, p_cashcall, p_ri_code, p_ri_br_code, p_lf_flag, p_ri_type1, p_ri_type2, p_ri_share, pri_res_amt, p_lines);
         commit;
     exception
     when  OTHERS  then
              rollback;
     End;
  END;
PROCEDURE nc_insert_fir_block_reloss_tmp (p_pol_no in varchar2, p_sts_key in number, p_block in varchar2, p_block_limit in number, p_first in number, p_second in number, p_fpre in number, p_ret in number,
                                                                 p_mfp in number, p_frqs in number, p_tgr in number, p_sum_ins in number, p_pol_run in number, p_fqs_limit in number, p_fqs in number, p_ffs in number) IS
BEGIN
    Begin
        insert into  nc_fir_block_reloss_tmp (pol_no, pol_run, sts_key, block, block_limit, first, second, fpre, ret, mfp, frqs, tgr, sumins, fqs_limit, fqs, ffs)
        values (p_pol_no, p_pol_run, p_sts_key, p_block, p_block_limit, p_first, p_second, p_fpre, p_ret, p_mfp, p_frqs, p_tgr, p_sum_ins, p_fqs_limit, p_fqs, p_ffs );
        commit;
    exception
    when  OTHERS  then
        rollback;
    End;
END;
PROCEDURE nc_block_reloss_fire (p_loss_date in date, p_pol_no in varchar2, p_pol_run in number, p_block in varchar2, p_channel in varchar2,
                                                  Out_f1st out number, Out_f2nd out number, Out_mfp out number, Out_fpre out number,
                                                  Out_frqs out number, Out_rent out number, Out_tgr  out number, Out_sumins  out number) IS
          F1ST   NUMBER(15) := 0;
          F2ND   NUMBER(15) := 0;
          FPRE   NUMBER(15) := 0;
          RENT   NUMBER(15) := 0;
          FRQS   NUMBER(15) := 0;
          MFP    NUMBER(15) := 0;
          TGR    NUMBER(15) := 0;
         SUM_INS NUMBER(15,2) := 0;
BEGIN
 ----------------  pol_no ??????????????? Cover note ??? ?????????? ----------------
   declare
          CURSOR c1 IS SELECT distinct a.pol_no,a.pol_run,max(b.end_seq) end_seq
                         from fir_pol_mas a,fir_pol_seq b
                        where b.prod_type <> '116'             and   -- ??????? Cover Note --
                              (to_char(p_loss_date,'YYYY/MM/DD') between to_char(b.fr_date,'YYYY/MM/DD') and to_char(b.to_date,'YYYY/MM/DD'))  and
                              a.pol_no||to_char(a.pol_run)  <> p_pol_no||to_char(p_pol_run) and
                              nvl(a.rem_pol,'Z') <> 'R'       and   -- ?????????? --
                              a.blk_no  = p_block   and
                              b.end_seq <= (select max(end_seq)
                                              from fir_pol_seq c
                                             where (to_char(p_loss_date,'YYYY/MM/DD') >= to_char(c.fr_date,'YYYY/MM/DD'))
                                               and c.pol_no  = a.pol_no
                                               and c.pol_run = a.pol_run)  and
                              a.pol_no  = b.pol_no            and
                              a.pol_run = b.pol_run
                       GROUP BY a.pol_no,a.pol_run
  ----------   pol_no ?????????????????    -------------------------
                UNION
                        SELECT distinct a.pol_no,a.pol_run,max(b.end_seq) end_seq
                         from fir_pol_mas a,fir_pol_seq b
                        where (to_char(p_loss_date,'YYYY/MM/DD') between to_char(b.fr_date,'YYYY/MM/DD') and to_char(b.to_date,'YYYY/MM/DD'))   and
                              a.pol_no||to_char(a.pol_run)  = p_pol_no||to_char(p_pol_run) and
                              a.blk_no  = p_block  and
                              b.end_seq <= (select max(end_seq)
                                              from fir_pol_seq c
                                             where (to_char(p_loss_date,'YYYY/MM/DD') >= to_char(c.fr_date,'YYYY/MM/DD'))
                                               and c.pol_no  = a.pol_no
                                               and c.pol_run = a.pol_run)  and
                              a.pol_no  = b.pol_no   and
                              a.pol_run = b.pol_run
                        GROUP BY a.pol_no,a.pol_run
----------------  pol_no ??????????????? Cover note ??? ??????? ----------------
               UNION
                        SELECT distinct a.pol_no,a.pol_run,max(b.end_seq) end_seq
                         from fir_pol_mas a,fir_pol_seq b
                        where b.prod_type <> '116'  and
                              (to_char(p_loss_date,'YYYY/MM/DD') between to_char(b.fr_date,'YYYY/MM/DD') and to_char(b.to_date,'YYYY/MM/DD')) and
                              a.pol_no||to_char(a.pol_run)  <> p_pol_no||to_char(p_pol_run) and
                              a.rem_pol = 'R'         and
                              a.blk_no  = p_block    and
                              (a.pol_no,a.pol_run)  not in ( SELECT a.old_pol,a.old_pol_run
                                                   from fir_pol_mas a,fir_pol_seq b
                                                   where b.prod_type <> '116'  and
                                                         (to_char(p_loss_date,'YYYY/MM/DD') between to_char(a.fr_date,'YYYY/MM/DD') and to_char(a.to_date,'YYYY/MM/DD')) and
                                              --           a.pol_no||to_char(a.pol_run)  <> In_pol_no||to_char(In_pol_run) and
                                                         nvl(a.rem_pol,' ') <> 'R'          and
                                                         a.blk_no  = p_block     and
                                                         a.old_pol is not null     and
                                                         a.old_pol_run is not null and
                                                         b.end_seq = (select max(end_seq)
                                                                        from fir_pol_seq c
                                                                       where (to_char(p_loss_date,'YYYY/MM/DD') >= to_char(c.fr_date,'YYYY/MM/DD'))
                                                                         and c.pol_no  = a.pol_no
                                                                         and c.pol_run = a.pol_run )  and
                              a.pol_no  = b.pol_no     and
                              a.pol_run = b.pol_run)   and
                              b.end_seq <= (select max(end_seq)
                                              from fir_pol_seq c
                                             where to_char(p_loss_date,'YYYY/MM/DD') >= to_char(c.fr_date,'YYYY/MM/DD')
                                               and c.pol_no  = a.pol_no
                                               and c.pol_run = a.pol_run)  and
                              a.pol_no  = b.pol_no     and
                              a.pol_run = b.pol_run
                      GROUP BY a.pol_no,a.pol_run;
           my_rec c1%ROWTYPE;
           t_f1st number(15)     := 0;
           t_f2nd number(15)     := 0;
           t_mfp  number(15)     := 0;
           t_fpre number(15)     := 0;
           t_rent number(15)     := 0;
           t_frqs number(15)     := 0;
           t_sumins number(15,0) := 0;
           dummy   number;
  Begin
     open c1;
     loop
       fetch c1 into my_rec;
       exit when c1%NOTFOUND;
                 nc_block_reloss_fire_f1st(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_f1st);
                 nc_block_reloss_fire_f2nd(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_f2nd);
                 nc_block_reloss_fire_frqs(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_frqs);
                 nc_block_reloss_fire_sumins(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_sumins);
                 if p_channel <> '9' then
                    nc_block_reloss_fire_mfp(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_mfp);
                    nc_block_reloss_fire_pre(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_fpre);
                    nc_block_reloss_fire_rent(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_rent);
                 else
                    t_mfp  := 0;
                    t_fpre := 0;
                    t_rent := 0;
                 end if;
                 f1st := nvl(f1st,0) + nvl(t_f1st,0) ;
                 f2nd := nvl(f2nd,0) + nvl(t_f2nd,0) ;
                 mfp  := nvl(mfp,0)  + nvl(t_mfp,0)  ;
                 fpre := nvl(fpre,0) + nvl(t_fpre,0) ;
                 frqs := nvl(frqs,0) + nvl(t_frqs,0) ;
                 rent := nvl(rent,0) + nvl(t_rent,0) ;
                 sum_ins := nvl(sum_ins,0) + nvl(t_sumins,0) ;
       end loop;
    end;
       Out_f1st := f1st;
       Out_f2nd := f2nd;
       Out_mfp  := mfp;
       Out_fpre := fpre;
       Out_frqs := frqs;
       Out_rent := rent;
       Out_tgr  := Out_f1st + Out_f2nd + Out_mfp + Out_fpre + Out_frqs + Out_rent;
       Out_sumins := sum_ins;
END;

PROCEDURE nc_block_reloss_accum (p_block in varchar2, p_pol_no in varchar2, p_pol_run in varchar2, p_loss_date in date, p_loc_seq in number,
                                                      Out_f1st  out number, Out_f2nd  out number, Out_fpre  out number, Out_rent  out number,
                                                      Out_fqs   out number, Out_ffs     out number, Out_sumins out number, Out_tgr  out number) IS
          F1ST   NUMBER(15) := 0;
          F2ND   NUMBER(15) := 0;
          FPRE   NUMBER(15) := 0;
          RENT   NUMBER(15) := 0;
          FQS    NUMBER(15) := 0;
          FFS    NUMBER(15) := 0;
          TGR    NUMBER(15) := 0;
         SUM_INS NUMBER(15,2) := 0;
BEGIN
    declare
        cursor c1 IS  select distinct a.pol_no,a.pol_run,a.prod_grp,b.loc_seq,max(a.end_seq) end_seq
                             from mis_mas a, mis_iar_det b
                           where a.pol_no = b.pol_no
                               and nvl(a.pol_run,0) = nvl(b.pol_run,0)
                               and rtrim(b.block_id) = rtrim(p_block)
                               and a.end_seq = b.end_seq
                               and a.pol_yr >= '2012'
                               and (to_char(p_loss_date,'yyyymmdd') BETWEEN to_char(a.fr_date,'yyyymmdd') AND to_char(a.to_date,'yyyymmdd') OR
                                       to_char(p_loss_date,'yyyymmdd') BETWEEN to_char(a.fr_date,'yyyymmdd') AND to_char(a.to_maint,'yyyymmdd'))
                               and a.end_seq <= (select max(a1.end_seq)
                                                             from mis_mas a1
                                                           where a1.pol_no = a.pol_no
                                                               and nvl(a1.pol_run,0) = nvl(a.pol_run,0)
                                                               and to_char(p_loss_date,'YYYYMMDD') >= to_char(a1.fr_date,'YYYYMMDD'))
                        group by a.pol_no,a.pol_run,a.prod_grp,b.loc_seq
                 UNION
                       SELECT distinct a.pol_no,a.pol_run,a.prod_grp,0,max(b.end_seq) end_seq
                         from fir_pol_mas a,fir_pol_seq b
                        where b.prod_type <> '116'             and
                              (to_char(p_loss_date,'yyyymmdd') between to_char(b.fr_date,'yyyymmdd') and to_char(b.to_date,'yyyymmdd'))  and
                              a.pol_no||to_char(a.pol_run)  <> p_pol_no||to_char(p_pol_run) and
                              nvl(a.rem_pol,'Z') <> 'R'       and
                              a.blk_no  = p_block  and
                              a.pol_year >= '2012'  and
                              b.end_seq <= (select max(end_seq)
                                                       from fir_pol_seq c
                                                     where (to_char(p_loss_date,'yyyymmdd') >= to_char(c.fr_date,'yyyymmdd'))
                                                         and c.pol_no  = a.pol_no
                                                         and c.pol_run = a.pol_run)
                              and a.pol_no  = b.pol_no
                              and a.pol_run = b.pol_run
                        GROUP BY a.pol_no,a.pol_run,a.prod_grp
                 UNION
                       SELECT distinct a.pol_no,a.pol_run,a.prod_grp,0,max(b.end_seq) end_seq
                         from fir_pol_mas a,fir_pol_seq b
                        where (to_char(p_loss_date,'yyyymmdd') between to_char(b.fr_date,'yyyymmdd') and to_char(b.to_date,'yyyymmdd'))   and
                              a.pol_no||to_char(a.pol_run)  = p_pol_no||to_char(p_pol_run) and
                              a.blk_no  = p_block  and
                              a.pol_year >= '2012'  and
                              b.end_seq <= (select max(end_seq)
                                              from fir_pol_seq c
                                             where (to_char(p_loss_date,'yyyymmdd') >= to_char(c.fr_date,'yyyymmdd'))
                                               and c.pol_no  = a.pol_no
                                               and c.pol_run = a.pol_run)  and
                              a.pol_no  = b.pol_no   and
                              a.pol_run = b.pol_run
                        GROUP BY a.pol_no,a.pol_run,a.prod_grp
                 UNION
                       SELECT distinct a.pol_no,a.pol_run,a.prod_grp,0,max(b.end_seq) end_seq
                         from fir_pol_mas a,fir_pol_seq b
                        where b.prod_type <> '116'  and
                              (to_char(p_loss_date,'yyyymmdd') between to_char(b.fr_date,'yyyymmdd') and to_char(b.to_date,'yyyymmdd')) and
                              a.pol_no||to_char(a.pol_run)  <> p_pol_no||to_char(p_pol_run) and
                              a.rem_pol = 'R'         and
                              a.blk_no  = p_block    and
                              a.pol_year >= '2012'    and
                              (a.pol_no,a.pol_run)  not in ( SELECT a.old_pol,a.old_pol_run
                                                               from fir_pol_mas a,fir_pol_seq b
                                                              where b.prod_type <> '116'  and
                                                             (to_char(p_loss_date,'yyyymmdd') between to_char(a.fr_date,'yyyymmdd') and to_char(a.to_date,'yyyymmdd')) and
                                                              nvl(a.rem_pol,' ') <> 'R'          and
                                                              a.blk_no  = p_block      and
                                                              a.old_pol is not null     and
                                                              a.old_pol_run is not null and
                                                              b.end_seq = (select max(end_seq)
                                                                             from fir_pol_seq c
                                                                            where (to_char(p_loss_date,'yyyymmdd') >= to_char(c.fr_date,'yyyymmdd'))
                                                                              and c.pol_no  = a.pol_no
                                                                              and c.pol_run = a.pol_run )  and
                              a.pol_no  = b.pol_no     and
                              a.pol_run = b.pol_run)   and
                              b.end_seq <= (select max(end_seq)
                                              from fir_pol_seq c
                                             where to_char(p_loss_date,'yyyymmdd') >= to_char(c.fr_date,'yyyymmdd')
                                               and c.pol_no  = a.pol_no
                                               and c.pol_run = a.pol_run)  and
                              a.pol_no  = b.pol_no     and
                              a.pol_run = b.pol_run
                      GROUP BY a.pol_no,a.pol_run,a.prod_grp;

        my_rec c1%ROWTYPE;
           t_mis_f1st number(15)     := 0;
           t_mis_f2nd number(15)     := 0;
           t_mis_fpre number(15)     := 0;
           t_mis_rent number(15)     := 0;
           t_mis_fqs  number(15)     := 0;
           t_mis_ffs  number(15)     := 0;
           t_mis_sumins number(15,0) := 0;
           t_fir_f1st number(15)     := 0;
           t_fir_f2nd number(15)     := 0;
           t_fir_fpre number(15)     := 0;
           t_fir_rent number(15)     := 0;
           t_fir_fqs  number(15)     := 0;
           t_fir_ffs  number(15)     := 0;
           t_fir_sumins number(15,0) := 0;
        Begin
          open c1;
          loop
            fetch c1 into my_rec;
            exit when c1%NOTFOUND;
              if my_rec.prod_grp = '1'  then
                 nc_block_reloss_fire_f1st(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_fir_f1st);
                 nc_block_reloss_fire_f2nd(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_fir_f2nd);
                 nc_block_reloss_fire_pre(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_fir_fpre);
                 nc_block_reloss_fire_rent(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_fir_rent);
                 nc_block_reloss_fire_fqs(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_fir_fqs);
                 nc_block_reloss_fire_ffs(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_fir_ffs);
                 nc_block_reloss_fire_sumins(my_rec.pol_no,my_rec.pol_run,my_rec.end_seq,p_loss_date,t_fir_sumins);
                 f1st := nvl(f1st,0) + nvl(t_fir_f1st,0);
                 f2nd := nvl(f2nd,0) + nvl(t_fir_f2nd,0);
                 fpre := nvl(fpre,0) + nvl(t_fir_fpre,0);
                 rent := nvl(rent,0) + nvl(t_fir_rent,0);
                 fqs  := nvl(fqs,0)  + nvl(t_fir_fqs,0);
                 ffs  := nvl(ffs,0)  + nvl(t_fir_ffs,0);
                 sum_ins := nvl(sum_ins,0) + nvl(t_fir_sumins,0);
              else
                 nc_block_reloss_misc_rent(my_rec.pol_no,my_rec.pol_run,nvl(my_rec.loc_seq,0),my_rec.end_seq,p_loss_date,t_mis_rent);
                 nc_block_reloss_misc_fqs(my_rec.pol_no,my_rec.pol_run,nvl(my_rec.loc_seq,0),my_rec.end_seq,p_loss_date,t_mis_fqs);
                 nc_block_reloss_misc_ffs(my_rec.pol_no,my_rec.pol_run,nvl(my_rec.loc_seq,0),my_rec.end_seq,p_loss_date,t_mis_ffs);
                 nc_block_reloss_misc_sumins(my_rec.pol_no,my_rec.pol_run,nvl(my_rec.loc_seq,0),my_rec.end_seq,p_loss_date,t_mis_sumins);
                 f1st := nvl(f1st,0) + nvl(t_mis_f1st,0);
                 f2nd := nvl(f2nd,0) + nvl(t_mis_f2nd,0);
                 fpre := nvl(fpre,0) + nvl(t_mis_fpre,0);
                 rent := nvl(rent,0) + nvl(t_mis_rent,0);
                 fqs  := nvl(fqs,0)  + nvl(t_mis_fqs,0);
                 ffs  := nvl(ffs,0)  + nvl(t_mis_ffs,0);
                 sum_ins := nvl(sum_ins,0) + nvl(t_mis_sumins,0);
              end if;
          end loop;
        end;
        Out_f1st := f1st;
        Out_f2nd := f2nd;
        Out_fpre := fpre;
        Out_rent := rent;
        Out_fqs  := fqs;
        Out_ffs  := ffs;
        Out_sumins := sum_ins;
        Out_tgr  := Out_f1st + Out_f2nd + Out_fpre + Out_rent + Out_fqs + Out_ffs ;
END;

PROCEDURE nc_block_reloss_fire_f1st  (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_f1st out number) IS
BEGIN
     select sum(ri_sum_ins)
        into Out_f1st
      from  fir_reinsurance
    where  pol_no     = p_pol_no
       and   pol_run   = p_pol_run
       and   end_seq between 0 and p_end_seq
       and   end_seq in (select a.end_seq
                                   from fir_pol_seq a
                                 where (p_loss_date between a.fr_date and a.to_date or a.end_seq = 0)
                                     and  a.pol_no = p_pol_no
                                     and  a.pol_run = p_pol_run)
       and  ri_code       = '911'
       and  ri_br_code  = '00'
       and  ri_type        = '1'
       and  ri_sub_type  = '00'
       and  ri_lf_flag     = 'N' ;
EXCEPTION
     when no_data_found then
          Out_f1st := 0;
     when others then
          Out_f1st := 0;
END;

PROCEDURE nc_block_reloss_fire_f2nd (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_f2nd out number) IS
BEGIN
     select sum(ri_sum_ins)
        into Out_f2nd
      from fir_reinsurance
    where pol_no     = p_pol_no
       and pol_run    =  p_pol_run
       and end_seq between 0 and p_end_seq
       and end_seq in (select a.end_seq
                                 from fir_pol_seq a
                               where (p_loss_date between a.fr_date and a.to_date or a.end_seq = 0)
                                   and a.pol_no  = p_pol_no
                                   and a.pol_run = p_pol_run)
       and ri_code        = '912'
       and ri_br_code   = '00'
       and ri_type         = '1'
       and ri_sub_type  = '01'
       and ri_lf_flag      = 'N';
EXCEPTION
     when no_data_found then
          Out_f2nd := 0;
     when others then
          Out_f2nd := 0;
END;

PROCEDURE nc_block_reloss_fire_frqs  (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_frqs out number) IS
BEGIN
     select sum(ri_sum_ins)
        into Out_frqs
       from fir_reinsurance
      where pol_no     =  p_pol_no
          and pol_run    = p_pol_run
          and end_seq between 0 and p_end_seq
          and end_seq in (select a.end_seq
                                    from fir_pol_seq a
                                  where (p_loss_date between a.fr_date and a.to_date or a.end_seq = 0)
                                      and  a.pol_no  = p_pol_no
                                      and  a.pol_run = p_pol_run)
          and ri_code       = '913'
          and ri_br_code  = '00'
          and ri_type        = '1'
          and ri_sub_type = '04'
          and ri_lf_flag     = 'N';
EXCEPTION
     when no_data_found then
          Out_frqs := 0;
     when others then
          Out_frqs := 0;
END;

PROCEDURE nc_block_reloss_fire_sumins (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_sumins out number) IS
BEGIN
       begin
        select sum(sum_ins)
           into Out_sumins
         from fir_pol_seq
       where pol_no    = p_pol_no
          and  pol_run   = p_pol_run
          and  ((end_seq <= p_end_seq and p_loss_date between fr_date and to_date) or end_seq = 0);
         EXCEPTION
         when others then
              Out_sumins := 0;
       end;
END;

PROCEDURE nc_block_reloss_fire_mfp (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_mfp out number) IS
BEGIN
       begin
        select sum(ri_sum_ins)
           into Out_mfp
         from fir_reinsurance
       where pol_no     = p_pol_no
           and pol_run   = p_pol_run
           and end_seq between 0 and p_end_seq
           and end_seq in (select a.end_seq
                                    from fir_pol_seq a
                                  where (p_loss_date between a.fr_date and a.to_date or a.end_seq = 0)
                                      and a.pol_no = p_pol_no
                                      and a.pol_run = p_pol_run)
           and ri_code       = '367'
           and ri_br_code   = '00'
           and ri_type        = '1'
           and ri_sub_type  = '06'
           and ri_lf_flag      = 'L';
       EXCEPTION
         when no_data_found then
              Out_mfp := 0;
         when others then
              Out_mfp := 0;
       end;
END;

PROCEDURE nc_block_reloss_fire_pre  (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_pre out number) IS
BEGIN
    begin
     select sum(ri_sum_ins)
        into Out_pre
      from fir_reinsurance
    where pol_no     =  p_pol_no
        and pol_run   =   p_pol_run
        and end_seq between 0 and p_end_seq
        and end_seq in (select a.end_seq
                                  from fir_pol_seq a
                                where (p_loss_date between a.fr_date and a.to_date or a.end_seq = 0)
                                   and a.pol_no = p_pol_no
                                   and a.pol_run = p_pol_run)
        and ri_code       = '999'
        and ri_br_code  = '98'
        and ri_type        = '2'
        and ri_sub_type = '01'
        and ri_lf_flag     = 'N';
     EXCEPTION
     when no_data_found then
          Out_pre := 0;
     when others then
          Out_pre := 0;
    end;
END;

PROCEDURE nc_block_reloss_fire_rent  ( p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loss_date in date, Out_rent out number) IS
BEGIN
    begin
     select sum(ri_sum_ins)
        into Out_rent
      from fir_reinsurance
    where pol_no     = p_pol_no
        and pol_run    = p_pol_run
        and end_seq between 0 and p_end_seq
        and end_seq in (select a.end_seq
                                  from fir_pol_seq a
                                where (p_loss_date between a.fr_date and a.to_date or a.end_seq = 0)
                                    and a.pol_no  = p_pol_no
                                    and a.pol_run = p_pol_run)
        and ri_code       = '999'
        and ri_br_code  = '99'
        and ri_type        = '2'
        and ri_sub_type = '00'
        and ri_lf_flag     = 'N';
     EXCEPTION
     when no_data_found then
          Out_rent := 0;
     when others then
          Out_rent := 0;
    end;
END;
PROCEDURE nc_block_reloss_fire_fqs  (p_pol_no in  varchar2, p_pol_run  in  number, p_end_seq  in  number, p_loss_date  in  date, Out_fqs  out  number) IS
  BEGIN
      select sum(ri_sum_ins)
        into Out_fqs
        from fir_reinsurance
       where pol_no    = p_pol_no
         and pol_run    = p_pol_run
         and end_seq between 0 and p_end_seq
         and end_seq in (select a.end_seq from fir_pol_seq a
                                 where (p_loss_date between a.fr_date and a.to_date or a.end_seq = 0)
                                    and a.pol_no = p_pol_no
                                    and a.pol_run = p_pol_run)
         and ri_code       = '915'
         and ri_br_code  = '00'
         and ri_type        = '1'
         and ri_sub_type = '02'
         and ri_lf_flag     = 'N' ;
  EXCEPTION
      when no_data_found then
           Out_fqs := 0;
      when others then
           Out_fqs := 0;
  END;
PROCEDURE nc_block_reloss_fire_ffs  (p_pol_no  in  varchar2, p_pol_run  in  number, p_end_seq  in  number, p_loss_date  in  date, Out_ffs  out  number) IS
    BEGIN
      select sum(ri_sum_ins)
        into Out_ffs
        from fir_reinsurance
       where pol_no    = p_pol_no
         and pol_run    = p_pol_run
         and end_seq between 0 and p_end_seq
         and end_seq in (select a.end_seq from fir_pol_seq a
                                 where (p_loss_date between a.fr_date and a.to_date or a.end_seq = 0)
                                     and a.pol_no = p_pol_no
                                     and a.pol_run = p_pol_run)
         and ri_code       = '915'
         and ri_br_code  = '00'
         and ri_type        = '1'
         and ri_sub_type = '60'
         and ri_lf_flag     = 'N' ;
    EXCEPTION
      when no_data_found then
           Out_ffs := 0;
      when others then
           Out_ffs := 0;
    END;
PROCEDURE nc_block_reloss_misc_rent  (p_pol_no  in  varchar2, p_pol_run  in  number, p_loc_seq  in  number, p_end_seq  in  number, p_loss_date  in  date, Out_rent  out  number) IS
  BEGIN
      select nvl(SUM(nvl(a.ri_sum_ins,0)),0)
        into out_rent
        from mis_ri_mas a, mis_mas b
       where a.pol_no     = p_pol_no
         and a.pol_run     = p_pol_run
         and a.pol_no      = b.pol_no
         and a.pol_run     = b.pol_run
     --    and a.end_seq    = In_end_seq
         and a.end_seq    = b.end_seq
         and a.loc_seq     = p_loc_seq
         and (p_loss_date BETWEEN  a.fr_date  AND  a.to_date OR
              to_char(p_loss_date,'yyyymmdd') BETWEEN to_char(a.fr_date,'yyyymmdd') AND to_char(b.to_maint,'yyyymmdd'))
         and a.ri_code       =  '999'
         and a.ri_br_code  =  '99'
         and a.ri_type        =  '2'
         and a.ri_sub_type =  '00'
         and a.lf_flag         =  'N';
  EXCEPTION
         when no_data_found then
              Out_rent := 0;
         when others then
              Out_rent := 0;
  END;

PROCEDURE nc_block_reloss_misc_fqs  (p_pol_no in  varchar2, p_pol_run  in  number, p_loc_seq  in  number, p_end_seq  in number,  p_loss_date  in  date, Out_fqs  out  number) IS
  BEGIN
      select nvl(SUM(nvl(a.ri_sum_ins,0)),0)
        into out_fqs
        from mis_ri_mas a, mis_mas b
       where a.pol_no     = p_pol_no
         and a.pol_run     = p_pol_run
         and a.pol_no      = b.pol_no
         and a.pol_run    = b.pol_run
     --    and a.end_seq    = In_end_seq
         and a.end_seq    = b.end_seq
         and a.loc_seq     = p_loc_seq
         and (p_loss_date BETWEEN  a.fr_date  AND  a.to_date OR
              to_char(p_loss_date,'yyyymmdd') BETWEEN to_char(a.fr_date,'yyyymmdd') AND to_char(b.to_maint,'yyyymmdd'))
         and a.ri_code       =  '945'
         and a.ri_br_code  =  '00'
         and a.ri_type        =  '1'
         and a.ri_sub_type =  '02'
         and a.lf_flag         =  'N';
  EXCEPTION
         when no_data_found then
              Out_fqs := 0;
         when others then
              Out_fqs := 0;
  END;
PROCEDURE nc_block_reloss_misc_ffs  (p_pol_no  in  varchar2, p_pol_run  in  number, p_loc_seq  in  number, p_end_seq  in  number, p_loss_date in  date, Out_ffs  out  number) IS
    BEGIN
      select nvl(SUM(nvl(a.ri_sum_ins,0)),0)
        into out_ffs
        from mis_ri_mas a, mis_mas b
       where a.pol_no     = p_pol_no
         and a.pol_run     = p_pol_run
         and a.pol_no     = b.pol_no
         and a.pol_run    = b.pol_run
    --     and a.end_seq    = In_end_seq
         and a.end_seq    = b.end_seq
         and a.loc_seq     = p_loc_seq
         and (p_loss_date BETWEEN  a.fr_date  AND  a.to_date OR
              to_char(p_loss_date,'yyyymmdd') BETWEEN to_char(a.fr_date,'yyyymmdd') AND to_char(b.to_maint,'yyyymmdd'))
         and a.ri_code       =  '945'
         and a.ri_br_code  =  '00'
         and a.ri_type        =  '1'
         and a.ri_sub_type =  '60'
         and a.lf_flag         =  'N';
    EXCEPTION
         when no_data_found then
              Out_ffs := 0;
         when others then
              Out_ffs := 0;
    END;
PROCEDURE nc_block_reloss_misc_sumins  (p_pol_no  in  varchar2, p_pol_run  in  number, p_loc_seq  in  number, p_end_seq  in  number, p_loss_date  in  date, Out_sumins  out  number) IS
    BEGIN
      select nvl(SUM(nvl(a.ri_sum_ins,0)),0)
        into out_sumins
        from mis_ri_mas a, mis_mas b
       where a.pol_no    = p_pol_no
         and a.pol_run    = p_pol_run
         and a.pol_no     = b.pol_no
         and a.pol_run    = b.pol_run
    --     and a.end_seq    = In_end_seq
         and a.end_seq    = b.end_seq
         and a.loc_seq    = p_loc_seq
         and (p_loss_date BETWEEN  a.fr_date  AND  a.to_date OR
              to_char(p_loss_date,'yyyymmdd') BETWEEN to_char(a.fr_date,'yyyymmdd') AND to_char(b.to_maint,'yyyymmdd'));
    EXCEPTION
         when no_data_found then
              Out_sumins := 0;
         when others then
              Out_sumins := 0;
    END;
FUNCTION nc_fire_fac_ri_share (p_pol_no in varchar2, p_pol_run in number, p_end_seq in number, p_loc_seq in number, p_loss_date in date,
                                                p_ri_code in  varchar2, p_ri_br_code in  varchar2, p_lf_flag in  varchar2, p_ri_type1 in  varchar2, p_ri_type2 in varchar2 ) RETURN number IS

                ri_share    number;
BEGIN
  Begin
  select sum(ri_share)
     into ri_share
   from fir_reinsurance
 where pol_no    = p_pol_no
     and pol_run   = p_pol_run
     and loc_seq   = nvl(p_loc_seq,0)                                      ---   varit 19-feb-16
     and end_seq  between 0 and p_end_seq
     and end_seq  in (select a.end_seq
                                from fir_pol_seq a
                              where (p_loss_date between a.fr_date and a.to_date or a.end_seq = 0)
                                 and  a.pol_no = p_pol_no
                                 and  a.pol_run = p_pol_run)
     and ri_code       = p_ri_code
     and ri_br_code  = p_ri_br_code
     and ri_lf_flag     = p_lf_flag
     and ri_type        = p_ri_type1
     and ri_sub_type = p_ri_type2;
  EXCEPTION
     when no_data_found then
              ri_share := 0;
  End;
  return (ri_share);
END;

FUNCTION nc_mrn_ri_share (p_pol_no  in varchar2, p_pol_run  in  number, p_pol_seq  in number, p_end_seq  in number,
                                           p_ri_code  in varchar2, p_ri_br_code  in  varchar2, p_lf_flag  in  varchar2, p_ri_type1 in varchar2, p_ri_type2 in  varchar2  ) RETURN number IS

     ri_share  number;
BEGIN
  if p_ri_type1 = '0' then
    ri_share := P_RI_UTIL.get_Mrn_FAC_RI_Share(p_pol_no, p_pol_run, p_pol_seq,
                                           p_ri_code, p_ri_br_code , p_lf_flag, p_ri_type1, p_ri_type2);
  else
          Begin
             select  sum(share_rate)
               into  ri_share
             from  mrn_redata
           where pol_no  = p_pol_no
               and pol_run = p_pol_run
               and pol_seq = p_pol_seq
              /* and end_seq = (select max(end_seq)
                                         from mrn_redata
                                       where pol_no  = p_pol_no
                                           and pol_run = p_pol_run) */ /*revise by pornpen 23/12/2015*/
              and ri_code      = p_ri_code
              and ri_br_code = p_ri_br_code
              and lf_flag        = p_lf_flag
              and ri_type1     = p_ri_type1
              and ri_type2     = p_ri_type2;
        EXCEPTION
          WHEN others THEN
               ri_share := 0;
        End;
    end if;
   return (ri_share);
END;

PROCEDURE nc_misc_ri_reserve1 (p_pol_no in varchar2, p_pol_run in number, p_alc_re in varchar2, p_loss_date in date, p_recpt_seq in number, p_loc_seq in number,
                                                  p_tot_sum_ins out number, p_sum_shr out number, w_recpt out number, w_loc out number, p_message out varchar2 ) IS
           w_cnt_rent      number(3)    := 0;

BEGIN
    if      p_alc_re = '1'   then
            w_recpt    := 0;
            w_loc       := 0;
    elsif  p_alc_re = '2'   then
            w_recpt    := p_recpt_seq;
            w_loc       := 0;
    elsif  p_alc_re = '3'  then
            if  p_recpt_seq  = 0 then
                 w_recpt := 1;
            else
                 w_recpt := p_recpt_seq;
             end if;
             if  p_loc_seq  = 0 then
                 w_loc := 1;
             else
                 w_loc := p_loc_seq;
             end if;
     --       w_recpt    := p_recpt_seq;
     --       w_loc       := p_loc_seq;
    end if;
    begin
       select count(*) into w_cnt_rent
        from  mis_ri_mas
      where  pol_no     = p_pol_no
          and  pol_run    = p_pol_run
          and  recpt_seq = w_recpt
          and  loc_seq    = w_loc
          and (ri_code = '999' and ri_br_code = '99')
          and  p_loss_date between  fr_date and to_date ;
    exception
           when others then
                    w_cnt_rent := 0;
    end;
    begin
        if  w_cnt_rent = 0 then
           begin
              select sum(nvl(sum_ins,0)) into p_tot_sum_ins
               from mis_ri_mas
             where pol_no      = p_pol_no
                 and pol_run     = p_pol_run
                 and recpt_seq  = w_recpt
                 and loc_seq     = w_loc
                 and p_loss_date between  fr_date and to_date ;
           exception
                when others then
                         p_tot_sum_ins := 0;
           end;
       else
           begin
              select sum(nvl(sum_ins,0)) into p_tot_sum_ins
               from mis_ri_mas
             where pol_no       =  p_pol_no
                 and pol_run     =   p_pol_run
                 and recpt_seq  =  w_recpt
                 and loc_seq     =  w_loc
                 and (ri_code = '999' and ri_br_code = '99')
                 and p_loss_date between  fr_date and to_date ;
           exception
                when others then
                         p_tot_sum_ins := 0;
           end;
       end if;
       if  nvl(p_tot_sum_ins,0) = 0  then
           begin
               select  nvl(sum(nvl(a.ri_sum_ins,0)),0) into p_sum_shr
                from  mis_ri_mas a, mis_mas b
              where  a.pol_no      = p_pol_no
                 and   a.pol_run    =  p_pol_run
                 and   a.pol_no     =  b.pol_no
                 and   a.pol_run    =  b.pol_run
                 and   a.end_seq   =  b.end_seq
                 and   a.recpt_seq =  w_recpt
                 and   a.loc_seq    =  w_loc
                 and   (p_loss_date between  a.fr_date  and  a.to_date or
                           p_loss_date between  a.fr_date  and  b.to_maint);
           exception
                when  no_data_found  then
                          p_message := 'R/I Sum-Insured not found';
                when  others  then
                          p_message := 'R/I Sum-Insured error';
           end;
       end if;
    end;
END;
PROCEDURE nc_misc_ri_reserve1_loc (p_pol_no in varchar2, p_pol_run in number, p_alc_re in varchar2, p_loss_date in date, p_recpt_seq in number, p_loc_seq in number,
                                                        p_tot_sum_ins out number, p_sum_shr out number, w_recpt out number, w_loc out number, p_message out varchar2 ) IS
           w_cnt_rent      number(3)    := 0;

BEGIN
    begin
       select count(*) into w_cnt_rent
        from  mis_ri_mas
      where  pol_no     = p_pol_no
          and  pol_run    = p_pol_run
          and  loc_seq    = p_loc_seq
          and (ri_code = '999' and ri_br_code = '99')
          and  p_loss_date between  fr_date and to_date ;
    exception
           when others then
                    w_cnt_rent := 0;
    end;
    begin
        if  w_cnt_rent = 0 then
           begin
              select sum(nvl(sum_ins,0)) into p_tot_sum_ins
               from mis_ri_mas
             where pol_no      = p_pol_no
                 and pol_run     = p_pol_run
                 and loc_seq     = p_loc_seq
                 and p_loss_date between  fr_date and to_date ;
           exception
                when others then
                         p_tot_sum_ins := 0;
           end;
       else
           begin
              select sum(nvl(sum_ins,0)) into p_tot_sum_ins
               from mis_ri_mas
             where pol_no       =  p_pol_no
                 and pol_run     =   p_pol_run
                 and loc_seq     =   p_loc_seq
                 and (ri_code = '999' and ri_br_code = '99')
                 and p_loss_date between  fr_date and to_date ;
           exception
                when others then
                         p_tot_sum_ins := 0;
           end;
       end if;
       if  nvl(p_tot_sum_ins,0) = 0  then
           begin
               select  nvl(sum(nvl(a.ri_sum_ins,0)),0) into p_sum_shr
                from  mis_ri_mas a, mis_mas b
              where  a.pol_no      = p_pol_no
                 and   a.pol_run    =  p_pol_run
                 and   a.pol_no     =  b.pol_no
                 and   a.pol_run    =  b.pol_run
                 and   a.end_seq   =  b.end_seq
                 and   a.loc_seq    =  p_loc_seq
                 and   (p_loss_date between  a.fr_date  and  a.to_date or
                           p_loss_date between  a.fr_date  and  b.to_maint);
           exception
                when  no_data_found  then
                          p_message := 'R/I Sum-Insured not found';
                when  others  then
                          p_message := 'R/I Sum-Insured error';
           end;
       end if;
    end;
END;
PROCEDURE nc_misc_ri_reserve2 (p_pol_no in varchar2, p_pol_run in number, p_alc_re in varchar2, p_loss_date in date, p_recpt_seq in number, p_loc_seq in number,
                                                  p_tot_sum_ins out number, p_sum_shr out number, p_ext_seq out number, p_message out varchar2 ) IS

BEGIN
   begin
      select nvl(max(end_seq),0)
         into p_ext_seq
       from mis_mas
     where pol_no       = p_pol_no
        and  pol_run     = p_pol_run
        and  end_type   = '7'
        and  trn_date  <= p_loss_date;
   end;
   begin
       select sum(sum_ins)
          into p_tot_sum_ins
        from mis_ri_mas
      where pol_no    = p_pol_no
          and pol_run  = p_pol_run
          and (ri_code  = '999' and ri_br_code = '99')
          and trn_date  <= p_loss_date
          and  end_seq  >= p_ext_seq;
   exception
          when no_data_found then
                   p_tot_sum_ins  := 0;
   end;
    if  nvl(p_tot_sum_ins,0) = 0  then
           begin
               select  nvl(sum(nvl(a.ri_sum_ins,0)),0) into p_sum_shr
                from  mis_ri_mas a, mis_mas b
              where  a.pol_no     = p_pol_no
                 and   a.pol_run    =  p_pol_run
                 and   a.pol_no     = b.pol_no
                 and   a.pol_run    =  b.pol_run
                 and   a.end_seq   =  b.end_seq
                 and   a.recpt_seq =  p_recpt_seq
                 and   a.loc_seq    =  p_loc_seq
                 and   (p_loss_date  between a.fr_date and a.to_date or
                           p_loss_date  between a.fr_date and b.to_maint );
           exception
                when  no_data_found  then
                          p_message := 'R/I Sum-Insured not found';
                when  others  then
                          p_message := 'R/I Sum-Insured error';
           end;
    end if;

END;

PROCEDURE nc_misc_ri_reserve3 (p_pol_no in varchar2, p_pol_run in number, p_alc_re in varchar2, p_loss_date in date, p_recpt_seq in number, p_loc_seq in number,
                                                  p_tot_sum_ins out number, p_sum_shr out number, p_ext_seq out number, p_message out varchar2 ) IS

BEGIN
   begin
      select nvl(max(end_seq),0)
         into p_ext_seq
       from mis_mas
     where pol_no    = p_pol_no
        and  pol_run  = p_pol_run
        and  p_loss_date between fr_maint and to_maint;
   end;
   begin
       select sum(sum_ins)
          into p_tot_sum_ins
        from mis_ri_mas
      where pol_no    = p_pol_no
          and pol_run  = p_pol_run
          and (ri_code  = '999' and ri_br_code = '99')
          and  end_seq  <= p_ext_seq;
   exception
          when no_data_found then
                   p_tot_sum_ins  := 0;
   end;
    if  nvl(p_tot_sum_ins,0) = 0  then
           begin
               select  nvl(sum(nvl(a.ri_sum_ins,0)),0) into p_sum_shr
                from  mis_ri_mas a, mis_mas b
              where  a.pol_no     = p_pol_no
                 and   a.pol_run    =  p_pol_run
                 and   a.pol_no     = b.pol_no
                 and   a.pol_run    =  b.pol_run
                 and   a.end_seq   =  b.end_seq
                 and   a.recpt_seq =  p_recpt_seq
                 and   a.loc_seq    =  p_loc_seq
                 and   a.end_seq   =  p_ext_seq;
           exception
                when  no_data_found  then
                          p_message := 'R/I Sum-Insured not found';
                when  others  then
                          p_message := 'R/I Sum-Insured error';
           end;
    end if;
END;


PROCEDURE nc_fire_fac_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_end_seq in varchar2, p_loc_seq in varchar2, p_loss_date in date, p_block in varchar2,
                                                       p_ri_cursor out v_ref_cursor3, p_message out varchar2 ) IS

BEGIN
        OPEN  p_ri_cursor  for
                 select ri_type, ri_code, ri_br_code, ri_sub_type, ri_lf_flag, sum(ri_sum_ins) s_ri_sum,max(end_seq) "m_end_seq",
                          NMTR_PACKAGE.nc_fire_fac_ri_share (p_pol_no, p_pol_run, p_end_seq, p_loc_seq, p_loss_date, ri_code, ri_br_code, ri_lf_flag, ri_type, ri_sub_type) "ri_share"
                 from  fir_reinsurance
              where pol_no = p_pol_no
                 and  pol_run = p_pol_run
                 and  ri_section = 1                          -- varit  26-jan-16
                 and  end_seq <= (select max(a.end_seq) from fir_reinsurance a
                                           where a.pol_no  =  p_pol_no
                                             and  a.pol_run =  p_pol_run
                                             and  a.end_seq <= p_end_seq
                                             and  a.ri_code||a.ri_br_code||a.ri_lf_flag||a.ri_type||a.ri_sub_type not in
                                                    ('36700L106','91100N100','91200N101','91300N104','99998N201','99999N200','91500N102','91500N160','94500N102','94500N160','99993N200','99999N230','91900N130') )
                 and ri_code||ri_br_code||ri_lf_flag||ri_type||ri_sub_type not in ('36700L106','91100N100','91200N101','91300N104','99998N201','99999N200','91500N102','91500N160','94500N102','94500N160','99993N200','99999N230','91900N130')
         group by ri_type,ri_code,ri_br_code,ri_sub_type,ri_lf_flag
         order by ri_type,ri_code ,ri_br_code,ri_sub_type,ri_lf_flag;
          if not p_ri_cursor%ISOPEN then
              p_message := 'Not Found Data Claim';
          end if;
EXCEPTION
  when others then
       p_message := 'Error Reinsurance';
END;
PROCEDURE nc_fire_all_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_end_seq in varchar2, p_loc_seq in varchar2, p_loss_date in date, p_block in varchar2,
                                                       p_ri_cursor out v_ref_cursor7, p_message out varchar2 ) IS

BEGIN
        OPEN  p_ri_cursor  for
                 select ri_type, ri_code, ri_br_code, ri_sub_type, ri_lf_flag, sum(ri_sum_ins) s_ri_sum,max(end_seq) "m_end_seq",
                          NMTR_PACKAGE.nc_fire_fac_ri_share (p_pol_no, p_pol_run, p_end_seq, p_loc_seq, p_loss_date, ri_code, ri_br_code, ri_lf_flag, ri_type, ri_sub_type) "ri_share"
                 from  fir_reinsurance
              where pol_no = p_pol_no
                 and  pol_run = p_pol_run
                 and  ri_section = 1                          -- varit  26-jan-16
                 and  end_seq <= (select max(a.end_seq) from fir_reinsurance a
                                           where a.pol_no  =  p_pol_no
                                             and  a.pol_run =  p_pol_run
                                             and  a.end_seq <= p_end_seq
                                             and  a.ri_code||a.ri_br_code||a.ri_lf_flag||a.ri_type||a.ri_sub_type not in ('91500N102','91500N160','94500N102','94500N160') )
                 and ri_code||ri_br_code||ri_lf_flag||ri_type||ri_sub_type not in ('91500N102','91500N160','94500N102','94500N160')
         group by ri_type,ri_code,ri_br_code,ri_sub_type,ri_lf_flag
         order by ri_type,ri_code ,ri_br_code,ri_sub_type,ri_lf_flag;
          if not p_ri_cursor%ISOPEN then
              p_message := 'Not Found Data Claim';
          end if;
EXCEPTION
  when others then
       p_message := 'Error Reinsurance';
END;
PROCEDURE nc_fire_catas_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_end_seq in varchar2, p_loc_seq in varchar2, p_loss_date in date, p_block in varchar2,
                                                          p_ri_cursor out v_ref_cursor8, p_message out varchar2 ) IS
    w_cnt            number;
    w_section      number;
BEGIN
    begin
        select count (distinct ri_code)
           into w_cnt
         from  fir_reinsurance
         where pol_no = p_pol_no
            and  pol_run = p_pol_run
            and  ri_section = 2
            and  end_seq <= (select max(a.end_seq) from fir_reinsurance a
                                       where a.pol_no  =  p_pol_no
                                          and  a.pol_run =  p_pol_run
                                          and  a.end_seq <= p_end_seq );
    exception
           when no_data_found then
                    w_cnt := 0;
           when others then
                    w_cnt := 0;
    end;
    if  w_cnt = 0  then
        w_section  :=  1;
    else
       w_section  :=   2;
    end if;
    OPEN  p_ri_cursor  for
              select ri_type, ri_code, ri_br_code, ri_sub_type, ri_lf_flag, sum(ri_sum_ins) s_ri_sum,max(end_seq) "m_end_seq",
                       NMTR_PACKAGE.nc_fire_fac_ri_share (p_pol_no, p_pol_run, p_end_seq, p_loc_seq, p_loss_date, ri_code, ri_br_code, ri_lf_flag, ri_type, ri_sub_type) "ri_share"
              from  fir_reinsurance
              where pol_no = p_pol_no
                 and  pol_run = p_pol_run
                 and  ri_section = w_section
                 and  end_seq <= (select max(a.end_seq) from fir_reinsurance a
                                           where a.pol_no  =  p_pol_no
                                             and  a.pol_run =  p_pol_run
                                             and  a.end_seq <= p_end_seq )
         group by ri_type,ri_code,ri_br_code,ri_sub_type,ri_lf_flag
         order by ri_type,ri_code ,ri_br_code,ri_sub_type,ri_lf_flag;
          if not p_ri_cursor%ISOPEN then
              p_message := 'Not Found Data Claim';
          end if;
EXCEPTION
  when others then
       p_message := 'Error Reinsurance';
END;
 PROCEDURE nc_iar_fac_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_prod_type in varchar2, p_alc_re in varchar2, p_recpt_seq in number,
                                                       p_loc_seq in number, p_loss_date in date, p_ri_fac_cursor out v_ref_cursor5, p_message out varchar2 ) IS
                    w_cnt_loc    number;
                    w_recpt       number;
                    w_loc          number;
 BEGIN
    begin
        select count (distinct loc_seq)
           into w_cnt_loc
         from mis_ri_mas
       where pol_no     = p_pol_no
           and pol_run   =  p_pol_run
           and p_loss_date  between fr_date and to_date;
    exception
           when others then
                    w_cnt_loc := 0;
    end;
    if      p_alc_re = '1'   then
            w_recpt    := 0;
            w_loc       := 0;
    elsif  p_alc_re = '2'   then
            w_recpt    := p_recpt_seq;
            w_loc       := 0;
    else
            w_recpt    := p_recpt_seq;
            w_loc       := p_loc_seq;
    end if;
    if     p_alc_re  in  ('1','2')  and  w_cnt_loc > 1   then
           p_message := 'Reinsurance is not complete - please contact to U/W';
   elsif  p_alc_re  in  ('1','2')  and  w_cnt_loc = 1  then
           OPEN  p_ri_fac_cursor  for
                     select ri_type, ri_code, ri_br_code, ri_sub_type, lf_flag, sum(nvl(sum_ins,0)) s_sum_ins, sum(nvl(ri_sum_ins,0)) s_ri_sum
                      from mis_ri_mas
                    where pol_no = p_pol_no
                        and pol_run = p_pol_run
                        and recpt_seq = w_recpt
                        and loc_seq = w_loc
                        and ri_type in ('0','1','2','3')          -- Varit  03-nov-15  add retention
                        and ri_code not in ('945')
                        and p_loss_date between fr_date and to_date
                 group by ri_type,ri_code,ri_br_code,ri_sub_type,lf_flag
                 order by ri_type,ri_code ,ri_br_code,ri_sub_type,lf_flag;
            if not p_ri_fac_cursor%ISOPEN then
               p_message := 'Not Found Reinsurance Data';
            end if;
   elsif  p_alc_re in ('3') and  p_prod_type in  ('540','541','551')  then
           OPEN  p_ri_fac_cursor  for
                     select ri_type, ri_code, ri_br_code, ri_sub_type, lf_flag, sum(nvl(sum_ins,0)) s_sum_ins, sum(nvl(ri_sum_ins,0)) s_ri_sum
                      from mis_ri_mas
                    where pol_no = p_pol_no
                        and pol_run = p_pol_run
                        and loc_seq = w_loc
                        and ri_type in ('0','1','2','3')           --  Varit  03-nov-15   add retention
                        and ri_code not in ('945')
                        and p_loss_date between fr_date and to_date
                 group by ri_type,ri_code,ri_br_code,ri_sub_type,lf_flag
                 order by ri_type,ri_code ,ri_br_code,ri_sub_type,lf_flag;
            if not p_ri_fac_cursor%ISOPEN then
               p_message := 'Not Found Reinsurance Data';
            end if;
   elsif  p_alc_re in ('3') and  p_prod_type not in  ('540','541','551')  then
           OPEN  p_ri_fac_cursor  for
                     select ri_type, ri_code, ri_br_code, ri_sub_type, lf_flag, sum(nvl(sum_ins,0)) s_sum_ins, sum(nvl(ri_sum_ins,0)) s_ri_sum
                      from mis_ri_mas
                    where pol_no = p_pol_no
                        and pol_run = p_pol_run
                        and recpt_seq = w_recpt
                        and loc_seq = w_loc
                        and ri_type in ('0','1','2','3')          --  Varit  03-nov-15   add retention
                        and ri_code not in ('945')
                        and p_loss_date between fr_date and to_date
                 group by ri_type,ri_code,ri_br_code,ri_sub_type,lf_flag
                 order by ri_type,ri_code ,ri_br_code,ri_sub_type,lf_flag;
            if not p_ri_fac_cursor%ISOPEN then
               p_message := 'Not Found Reinsurance Data';
            end if;
   end if;
END;
PROCEDURE nc_iar_chk_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_prod_type in varchar2, p_alc_re in varchar2, p_recpt_seq in number,
                                                       p_loc_seq in number, p_loss_date in date, p_chk_re out varchar2, p_message out varchar2 ) IS
                    w_cnt_loc    number;
                    w_recpt       number;
                    w_loc          number;
                    w_ri_code    varchar2(3) := null;
 BEGIN
    begin
        select count (distinct loc_seq)
           into w_cnt_loc
         from mis_ri_mas
       where pol_no     = p_pol_no
           and pol_run   =  p_pol_run
           and p_loss_date  between fr_date and to_date;
    exception
           when others then
                    w_cnt_loc := 0;
    end;
    if      p_alc_re = '1'   then
            w_recpt    := 0;
            w_loc       := 0;
    elsif  p_alc_re = '2'   then
            w_recpt    := p_recpt_seq;
            w_loc       := 0;
    else
            w_recpt    := p_recpt_seq;
            w_loc       := p_loc_seq;
    end if;
    if     p_alc_re  in  ('1','2')  and  w_cnt_loc > 1   then
           p_message := 'Reinsurance is not complete - please contact to U/W';
   elsif  p_alc_re  in  ('1','2')  and  w_cnt_loc = 1  then
           Begin
               select distinct ri_code
                  into w_ri_code
                from mis_ri_mas
              where pol_no = p_pol_no
                  and pol_run = p_pol_run
                  and recpt_seq = w_recpt
                  and loc_seq = w_loc
                  and ri_type in ('0','1','2','3')          -- Varit  03-nov-15  add retention
                  and ri_code in ('945')
                  and nvl(ri_share,0) > 0
                  and p_loss_date between fr_date and to_date;
          exception
                when  no_data_found  then
                          p_chk_re := 'N';         ---  no data ri_code = 945 then normal reinsurance
                when  others  then
                          p_chk_re := 'Y';
           end;
           if   w_ri_code = '945'   then
                p_chk_re := 'Y';
           else
                p_chk_re := 'N';
           end if;
   elsif  p_alc_re in ('3') and  p_prod_type in  ('540','541','551')  then
           Begin
              select distinct ri_code
                 into w_ri_code
               from mis_ri_mas
             where pol_no = p_pol_no
                 and pol_run = p_pol_run
                 and loc_seq = w_loc
                 and ri_type in ('0','1','2','3')           --  Varit  03-nov-15   add retention
                 and ri_code in ('945')
                 and nvl(ri_share,0) > 0
                 and p_loss_date between fr_date and to_date;
           exception
                when  no_data_found  then
                          p_chk_re := 'N';         ---  no data ri_code = 945 then normal reinsurance
                when  others  then
                          p_chk_re := 'Y';
           end;
           if   w_ri_code = '945'   then
                p_chk_re := 'Y';
           else
                p_chk_re := 'N';
           end if;
   elsif  p_alc_re in ('3') and  p_prod_type not in  ('540','541','551')  then
           Begin
               select distinct ri_code
                  into w_ri_code
                from mis_ri_mas
              where pol_no = p_pol_no
                  and pol_run = p_pol_run
                  and recpt_seq = w_recpt
                  and loc_seq = w_loc
                  and ri_type in ('0','1','2','3')          --  Varit  03-nov-15   add retention
                  and ri_code in ('945')
                  and nvl(ri_share,0) > 0
                  and p_loss_date between fr_date and to_date;
           exception
                when  no_data_found  then
                          p_chk_re := 'N';         ---  no data ri_code = 945 then normal reinsurance
                when  others  then
                          p_chk_re := 'Y';
           end;
           if   w_ri_code = '945'   then
                p_chk_re := 'Y';
           else
                p_chk_re := 'N';
           end if;
   end if;
END;
 PROCEDURE nc_fire_trty_reinsurance (p_trty in number, p_balance in number, p_reserve_amt in number, p_tgr in number, p_ri_share out number, p_ri_reserve_amt out number) IS
 BEGIN
     p_ri_reserve_amt := round((floor(p_trty) * floor(p_balance)) / p_tgr,4);
     p_ri_share := round((p_ri_reserve_amt * 100) / p_reserve_amt,5);
  EXCEPTION
     when others then
              p_ri_reserve_amt := 0;
              p_ri_share := 0;
  END;

 PROCEDURE nc_hull_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_ret out number, p_ret1 out number, p_ret2 out number, p_ri_cursor out v_ref_cursor3, p_message out varchar2 ) IS
 BEGIN
  OPEN  p_ri_cursor  for
                 select ri_type, ri_code, ri_br_code, ri_sub_type, ri_lf_flag, sum(ri_sum_ins) s_ri_sum,max(end_seq) "m_end_seq", ri_share
                  from hull_ri_mas
                where pol_no = p_pol_no
                   and pol_run = p_pol_run
                   and end_seq = (select  max(end_seq)
                                           from hull_ri_mas
                                           where pol_no    = p_pol_no
                                           and     pol_run  =  p_pol_run)
           group by ri_type,ri_code,ri_br_code,ri_sub_type,ri_lf_flag,ri_share
           order by  ri_type,ri_code ,ri_br_code,ri_sub_type,ri_lf_flag;
           if not p_ri_cursor%ISOPEN then
              p_message := 'Not Found Data Claim';
           end if;
   Begin
      select count(decode(ri_code||ri_br_code||ri_lf_flag||ri_type||ri_sub_type,'99999N200','Y')) ret, count(decode(ri_code||ri_br_code||ri_lf_flag||ri_type||ri_sub_type,'99996N202','Y')) ret1,
               count(decode(ri_code||ri_br_code||ri_lf_flag||ri_type||ri_sub_type,'99999N201','Y')) ret2
         into p_ret, p_ret1, p_ret2
      from hull_ri_mas
      where pol_no = p_pol_no
          and pol_run = p_pol_run
          and end_seq = (select  max(end_seq)
                                   from   hull_ri_mas
                                 where   pol_no    =  p_pol_no
                                     and   pol_run  =  p_pol_run);
       exception
       when others then
           p_ret   := 0;
           p_ret1 := 0;
           p_ret2 := 0;
       End ;

  EXCEPTION
  when others then
       p_message := 'Error Reinsurance';
END;

 PROCEDURE nc_mrn_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_pol_seq in number, p_sailing_date in varchar2,p_vessel_code in varchar2, p_I_E in varchar2, p_flight_no in varchar2,
                                                   p_trc out number,p_ret out number,p_first out number,p_second out number,p_binder out number,p_reserve_fac out number,p_pret out number,
                                                   p_sum_ins out number, p_sum_ins_ret2 out number, p_ri_cursor out v_ref_cursor3, p_message out varchar2 ) IS

     w_mrn_re_by         varchar2(1);
     w_ri_share             number;

BEGIN
    Begin
        select re_by
        into w_mrn_re_by
        from mrn_pol
        where pol_no  = p_pol_no
           and pol_run = p_pol_run
           and pol_seq = p_pol_seq
           and end_seq = (select max(end_seq)
                                    from mrn_pol
                                  where pol_no  = p_pol_no
                                     and pol_run = p_pol_run
                                     and pol_seq = p_pol_seq
                                     and (flag_cancel is null or end_type <> '8')
                                     and re_by   is not null);
    End;

    if w_mrn_re_by = 'P' then
       Begin
          select tot_sum_ins
             into p_sum_ins
            from mrn_pol_control
          where pol_no  = p_pol_no
             and pol_run = p_pol_run
             and pol_seq = p_pol_seq;
       exception
       when others then
           p_message := 'not found re_by(P)';
       End ;

       Begin
           select sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'26100L102',ri_sum,0)) trc,
                    sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'99999N200',ri_sum,0)) ret,
                    sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'92100N100',ri_sum,0)) first,
                    sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'92200N101',ri_sum,0)) second,
                    sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'08000F104',ri_sum,0)) binder,
                    sum(decode(ri_type1,'0',ri_sum,0)) reserve_fac,
                    sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'99997N200',ri_sum,0)) ret2
             into  p_trc,p_ret,p_first,p_second,p_binder,p_reserve_fac,p_pret
            from mrn_redata
         where pol_no  = p_pol_no
            and pol_run = p_pol_run
            and pol_seq = p_pol_seq;
       exception
            when others then
               p_message := 'No data R/I sum insured';
       End ;

       p_sum_ins_ret2 := nvl(p_ret,0) + nvl(p_first,0) + nvl(p_second,0) + nvl(p_binder,0); -- exclude ret2

       OPEN  p_ri_cursor  for
                 select ri_type1,ri_code ,ri_br_code,ri_type2,lf_flag,sum(ri_sum) s_ri_sum,max(end_seq) "m_end_seq",
                          NMTR_PACKAGE.nc_mrn_ri_share (p_pol_no,p_pol_run,p_pol_seq,max(end_seq),ri_code,ri_br_code,lf_flag,ri_type1,ri_type2) "ri_share"
                  from mrn_redata
               where pol_no = p_pol_no
                   and pol_run = p_pol_run
                   and pol_seq = p_pol_seq
           group by ri_type1,ri_code,ri_br_code,ri_type2,lf_flag
           order by  ri_type1,ri_code ,ri_br_code,ri_type2,lf_flag;
           if not p_ri_cursor%ISOPEN then
              p_message := 'Not Found Data Claim';
           end if;
   else
       Begin
          select tot_sum_ins
             into p_sum_ins
            from mrn_vessel_control
          where vessel_code  = p_vessel_code
             and  I_E   = p_I_E
             and  sailing_dd = substr(p_sailing_date,1,2)
             and  sailing_mm = substr(p_sailing_date,4,2)
             and  sailing_yy = substr(p_sailing_date,7,4)
             and  ( (flight  = p_flight_no) or (flight  is null));
       exception
       when others then
          p_message := 'not found re_by(V)';
       End ;

       Begin
           select   sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'99999N200',ri_sum,0)) ret,
                      sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'92100N100',ri_sum,0)) first,
                      sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'92200N101',ri_sum,0)) second,
                      sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'08000F104',ri_sum,0)) binder,
                      sum(decode(ri_type1,'0',ri_sum,0)) reserve_fac,
                      sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'99997N200',ri_sum,0)) ret2
           into p_ret,p_first,p_second,p_binder,p_reserve_fac,p_pret
           from mrn_redata
           where (pol_no,pol_seq,pol_run) in (select pol_no,pol_seq,pol_run
                                                               from mrn_pol
                                                             where vessel_code  = p_vessel_code
                                                                 and I_E   = p_I_E
                                                                 and sailing_dd = substr(p_sailing_date,1,2)
                                                                 and sailing_mm = substr(p_sailing_date,4,2)
                                                                 and sailing_yy = substr(p_sailing_date,7,4)
                                                                 and ( (flight_no  = p_flight_no) or (flight_No  is null)) ) ;
       exception
       when others then
          p_message := 'No data R/I sum insured';
       End ;

       Begin
           select sum(decode(ri_code||ri_br_code||lf_flag||ri_type1||ri_type2,'26100L102',ri_sum,0)) trc
              into p_trc
            from mrn_redata
          where pol_no  = p_pol_no
              and pol_run = p_pol_run
              and pol_seq = p_pol_seq;
        exception
        when others then
                p_message := 'No data R/I sum insured';
        End ;

        p_sum_ins_ret2 := nvl(p_ret,0) + nvl(p_first,0) + nvl(p_second,0) + nvl(p_binder,0); -- exclude ret2

        OPEN  p_ri_cursor  for
                  select ri_type1,ri_code ,ri_br_code,ri_type2,lf_flag,sum(ri_sum) s_ri_sum,max(end_seq) "m_end_seq",
                           NMTR_PACKAGE.nc_mrn_ri_share (p_pol_no,p_pol_run,p_pol_seq,max(end_seq),ri_code,ri_br_code,lf_flag,ri_type1,ri_type2) "ri_share"
                   from mrn_redata
                 where pol_no = p_pol_no
                     and pol_run = p_pol_run
                     and pol_seq = p_pol_seq
                     and ri_code||ri_br_code|| lf_flag||ri_type1||ri_type2 not in ('08000F104','92100N100','92200N101','99999N200','99997N200')
              group by ri_type1,ri_code ,ri_br_code,ri_type2,lf_flag
                   union
                  select ri_type1,ri_code ,ri_br_code,ri_type2,lf_flag,sum(ri_sum) s_ri_sum,max(end_seq) "m_end_seq",
                           NMTR_PACKAGE.nc_mrn_ri_share (p_pol_no,p_pol_run,p_pol_seq,max(end_seq),ri_code,ri_br_code,lf_flag,ri_type1,ri_type2)  "ri_share"
                   from mrn_redata
                 where (pol_no,pol_seq,pol_run) in (select pol_no,pol_seq,pol_run
                                                                    from mrn_pol
                                                                  where vessel_code  = p_vessel_code
                                                                     and  I_E   = p_I_E
                                                                     and  sailing_dd = substr(p_sailing_date,1,2)
                                                                     and  sailing_mm = substr(p_sailing_date,4,2)
                                                                     and  sailing_yy = substr(p_sailing_date,7,4)
                                                                     and ( (flight_no  = p_flight_no) or (flight_no  is null)) )
                                                                     and  ri_code||ri_br_code|| lf_flag||ri_type1||ri_type2  in ('92100N100','92200N101','99999N200','99997N200')
                                                             group by ri_type1,ri_code ,ri_br_code,ri_type2,lf_flag;
         if not p_ri_cursor%ISOPEN then
           p_message := 'Not Found Data Claim';
        end if;
    end if;

EXCEPTION
  when others then
       p_message := 'error re_by_proc';
END;

PROCEDURE nc_misc_reinsurance (p_pol_no in varchar2, p_pol_run in number, p_pol_yr in varchar2, p_prod_type in varchar2, p_loss_date in date, p_recpt_seq in number, p_loc_seq in number,
                                                   p_alc_re in varchar2, p_end in number, p_ri_end in varchar2, p_tot_sum_ins out number, p_sum_shr out number, p_ri_cursor out  v_ref_cursor3, p_message out varchar2) IS

                   w_recpt           number;
                   w_loc              number;
                   w_cnt_loc        number;
                   p_ext_seq        number;
                   w_maint_flg     varchar2(1);
BEGIN
    Begin
        select  'Y'
           into  w_maint_flg
          from  mis_mas
        where  pol_no  = p_pol_no
            and  nvl(pol_run,0) = nvl(p_pol_run,0)
            and  end_seq = (select max(end_seq)
                                      from mis_mas
                                    where pol_no = p_pol_no
                                        and nvl(pol_run,0) = nvl(p_pol_run,0)
                                        and p_loss_date between fr_maint and to_maint);
    exception
        when others  then
                 w_maint_flg := null;
    end;

    if      p_alc_re = '1'   then
            w_recpt    := 0;
            w_loc       := 0;
    elsif  p_alc_re = '2'   then
            w_recpt    := p_recpt_seq;
            w_loc       := 0;
    else
            w_recpt    := p_recpt_seq;
            w_loc       := p_loc_seq;
    end if;

    if  p_ri_end <> 'N'  then
        if    p_end is not null and w_maint_flg is null then
           if     p_alc_re in ('1','2')  or  (p_alc_re in ('3') and p_prod_type  not in ('540','541','551')) then
                  NMTR_PACKAGE.nc_misc_ri_reserve1 (p_pol_no, p_pol_run, p_alc_re, p_loss_date, p_recpt_seq, p_loc_seq, p_tot_sum_ins, p_sum_shr, w_recpt, w_loc, p_message) ;
                  OPEN  p_ri_cursor  for
                            select ri_type, ri_code, ri_br_code, ri_sub_type, lf_flag, sum(ri_sum_ins) s_ri_sum,max(end_seq) "m_end_seq", sum(ri_share) ri_share
                             from mis_ri_mas
                           where pol_no = p_pol_no
                               and pol_run = p_pol_run
                               and recpt_seq = w_recpt
                               and loc_seq = w_loc
                               and p_loss_date between fr_date and to_date
                        group by ri_type,ri_code,ri_br_code,ri_sub_type,lf_flag
                        order by  ri_type,ri_code ,ri_br_code,ri_sub_type,lf_flag;
                  if not p_ri_cursor%ISOPEN then
                     p_message := 'Not Found Reinsurance Data';
                  end if;
           elsif p_alc_re in ('3') and p_prod_type in ('540','541','551')  then
                  NMTR_PACKAGE.nc_misc_ri_reserve1_loc (p_pol_no, p_pol_run, p_alc_re, p_loss_date, p_recpt_seq, p_loc_seq, p_tot_sum_ins, p_sum_shr, w_recpt, w_loc, p_message) ;
                  OPEN  p_ri_cursor  for
                            select ri_type, ri_code, ri_br_code, ri_sub_type, lf_flag, sum(ri_sum_ins) s_ri_sum,max(end_seq) "m_end_seq", sum(ri_share) ri_share
                             from mis_ri_mas
                           where pol_no = p_pol_no
                               and pol_run = p_pol_run
                               and loc_seq = p_loc_seq
                               and p_loss_date between fr_date and to_date
                        group by ri_type,ri_code,ri_br_code,ri_sub_type,lf_flag
                        order by  ri_type,ri_code ,ri_br_code,ri_sub_type,lf_flag;
                  if not p_ri_cursor%ISOPEN then
                     p_message := 'Not Found Reinsurance Data';
                  end if;
           end if;
        elsif  p_end is not null and w_maint_flg = 'Y' then
                  NMTR_PACKAGE.nc_misc_ri_reserve3 (p_pol_no, p_pol_run, p_alc_re, p_loss_date, p_recpt_seq, p_loc_seq, p_tot_sum_ins, p_sum_shr, p_ext_seq, p_message) ;
                  OPEN  p_ri_cursor  for
                           select ri_type, ri_code, ri_br_code, ri_sub_type, lf_flag, sum(ri_sum_ins) s_ri_sum,max(end_seq) "m_end_seq", sum(ri_share) ri_share
                            from mis_ri_mas
                          where pol_no      = p_pol_no
                              and pol_run     = p_pol_run
                              and end_seq <= p_ext_seq
                       group by ri_type,ri_code,ri_br_code,ri_sub_type,lf_flag
                      order by  ri_type,ri_code ,ri_br_code,ri_sub_type,lf_flag;
                  if not p_ri_cursor%ISOPEN then
                     p_message := 'Not Found Reinsurance Data';
                  end if;
        else
                  NMTR_PACKAGE.nc_misc_ri_reserve2 (p_pol_no, p_pol_run, p_alc_re, p_loss_date, p_recpt_seq, p_loc_seq, p_tot_sum_ins, p_sum_shr, p_ext_seq, p_message) ;
                  OPEN  p_ri_cursor  for
                            select ri_type, ri_code, ri_br_code, ri_sub_type, lf_flag, sum(ri_sum_ins) s_ri_sum,max(end_seq) "m_end_seq", sum(ri_share) ri_share
                             from mis_ri_mas
                           where pol_no      = p_pol_no
                               and pol_run     = p_pol_run
                               and trn_date  <= p_loss_date
                               and end_seq  >= p_ext_seq
                        group by ri_type,ri_code,ri_br_code,ri_sub_type,lf_flag
                       order by  ri_type,ri_code ,ri_br_code,ri_sub_type,lf_flag;
                   if not p_ri_cursor%ISOPEN then
                      p_message := 'Not Found Reinsurance Data';
                   end if;
        end if;
    end if;
END;
PROCEDURE nc_misc_reinsurance_initial (p_sts_key in number, p_ri_cursor out  v_ref_cursor6, p_message out varchar2) IS
BEGIN
     OPEN  p_ri_cursor  for
               select a.ri_code,a.ri_br_code,a.ri_type,a.ri_lf_flag,a.ri_sub_type,a.ri_share,a.lett_no
               from nc_ri_reserved a
               where a.sts_key = p_sts_key
               and   a.type = 'NCNATTYPECLM001'
               and  (a.clm_no,a.type,a.trn_seq) = (select b.clm_no,b.type,max(b.trn_seq)
                                                                        from nc_ri_reserved b
                                                                     where b.clm_no = a.clm_no
                                                                         and b.type = a.type
                                                                  group by b.clm_no,b.type);

      if not p_ri_cursor%ISOPEN then
               p_message := 'Not Found Reinsurance Data';
      end if;
END;
PROCEDURE nc_misc_reinsurance_ret (p_sts_key in number, p_99999 out  number, p_99998 out number, p_99993 out number) IS
BEGIN
     Begin
             select  count(*)
             into     p_99999
             from    nc_ri_reserved a
             where a.sts_key = p_sts_key
             and   a.type = 'NCNATTYPECLM001'
             and   a.ri_code||a.ri_br_code||a.ri_lf_flag||a.ri_type||a.ri_sub_type = '99999N200'
             and  (a.clm_no,a.type,a.trn_seq) = (select b.clm_no,b.type,max(b.trn_seq)
                                                                        from nc_ri_reserved b
                                                                     where b.clm_no = a.clm_no
                                                                         and b.type = a.type
                                                                         and b.ri_code||b.ri_br_code||b.ri_lf_flag||b.ri_type||b.ri_sub_type = '99999N200'
                                                                  group by b.clm_no,b.type);
         Exception
             when  no_data_found  then
                       p_99999 := 0;
             when  others   then
                       p_99999 := 0;
         End;
         Begin
             select  count(*)
             into     p_99998
             from    nc_ri_reserved a
             where a.sts_key = p_sts_key
             and   a.type = 'NCNATTYPECLM001'
             and   a.ri_code||a.ri_br_code||a.ri_lf_flag||a.ri_type||a.ri_sub_type = '99998N201'
             and  (a.clm_no,a.type,a.trn_seq) = (select b.clm_no,b.type,max(b.trn_seq)
                                                                        from nc_ri_reserved b
                                                                     where b.clm_no = a.clm_no
                                                                         and b.type = a.type
                                                                         and b.ri_code||b.ri_br_code||b.ri_lf_flag||b.ri_type||b.ri_sub_type = '99998N201'
                                                                  group by b.clm_no,b.type);
         Exception
             when  no_data_found  then
                       p_99998 := 0;
             when  others   then
                       p_99998 := 0;
         End;
         Begin
             select  count(*)
             into     p_99993
             from    nc_ri_reserved a
             where a.sts_key = p_sts_key
             and   a.type = 'NCNATTYPECLM001'
             and   a.ri_code||a.ri_br_code||a.ri_lf_flag||a.ri_type||a.ri_sub_type = '99993N200'
             and  (a.clm_no,a.type,a.trn_seq) = (select b.clm_no,b.type,max(b.trn_seq)
                                                                        from nc_ri_reserved b
                                                                     where b.clm_no = a.clm_no
                                                                         and b.type = a.type
                                                                         and b.ri_code||b.ri_br_code||b.ri_lf_flag||b.ri_type||b.ri_sub_type = '99993N200'
                                                                  group by b.clm_no,b.type);
         Exception
             when  no_data_found  then
                       p_99993 := 0;
             when  others   then
                       p_99993 := 0;
         End;
END;
PROCEDURE nc_get_ri_reserved     (p_pol_no in varchar2,
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
                                                    p_message2 out varchar2) IS

     c3   NMTR_PACKAGE.v_ref_cursor3;

     TYPE ri_data3 IS RECORD
    (
     ri_type1       VARCHAR2(100) ,
     ri_code        VARCHAR2(100) ,
     ri_br_code   VARCHAR2(100) ,
     ri_type2       VARCHAR2(100) ,
     lf_flag          VARCHAR2(100) ,
     ri_sum         NUMBER,
     end_seq       NUMBER,
     ri_share       NUMBER
    );
    ri_rec3 ri_data3;

    c5   NMTR_PACKAGE.v_ref_cursor5;

     TYPE ri_data5 IS RECORD
    (
     ri_type1       VARCHAR2(100) ,
     ri_code        VARCHAR2(100) ,
     ri_br_code   VARCHAR2(100) ,
     ri_type2       VARCHAR2(100) ,
     lf_flag          VARCHAR2(100) ,
     sum_ins       NUMBER,
     ri_sum_ins   NUMBER
    );
    ri_rec5 ri_data5;

    c6   NMTR_PACKAGE.v_ref_cursor6;

     TYPE ri_data6 IS RECORD
    (
     ri_code        VARCHAR2(100) ,
     ri_br_code   VARCHAR2(100) ,
     ri_type1       VARCHAR2(100) ,
     lf_flag          VARCHAR2(100) ,
     ri_type2       VARCHAR2(100) ,
     ri_share       NUMBER ,
     pla_no         VARCHAR2(100)
    );
    ri_rec6 ri_data6;

    c7   NMTR_PACKAGE.v_ref_cursor7;

     TYPE ri_data7 IS RECORD
    (
     ri_type1       VARCHAR2(100) ,
     ri_code        VARCHAR2(100) ,
     ri_br_code   VARCHAR2(100) ,
     ri_type2       VARCHAR2(100) ,
     lf_flag          VARCHAR2(100) ,
     ri_sum         NUMBER,
     end_seq       NUMBER,
     ri_share       NUMBER
    );
    ri_rec7 ri_data7;

    c8   NMTR_PACKAGE.v_ref_cursor8;

     TYPE ri_data8 IS RECORD
    (
     ri_type1       VARCHAR2(100) ,
     ri_code        VARCHAR2(100) ,
     ri_br_code   VARCHAR2(100) ,
     ri_type2       VARCHAR2(100) ,
     lf_flag          VARCHAR2(100) ,
     ri_sum         NUMBER,
     end_seq       NUMBER,
     ri_share       NUMBER
    );
    ri_rec8 ri_data8;

    frac                                 number;
    frac_amt                          number;
    sum_ri_fac                       number(14,2) := 0;
    sum_ri_trc                       number(14,2) := 0;
    sum_ri_font                     number(14,2) := 0;
    sum_ri_ret2                     number := 0;
    sum_ri_first                     number(14,2) := 0;
    sum_ri_second                number(14,2) := 0;
    sum_ri_binder                 number(14,2) := 0;
    sum_ri_share                  number := 0;
    sum_shr_fac                   number := 0;
    sum_ri_reserve_amt        number := 0;    
    tot_sum_trc                    number := 0;
    cnt_ret1                         number := 0;
    cnt_ret2                         number := 0;
    v_count                          number := 0;
    v_99999                         number := 0;
    v_99998                         number := 0;
    v_99993                         number := 0;
    p_balance                      number;
    p_trc                             number;
    p_ret                             number;
    p_ret1                           number;
    p_ret2                           number;
    p_first                           number;
    p_second                       number;
    p_binder                        number;
    p_reserve_fac                number;
    p_pret                           number;
    p_mfp                           number;
    p_fpre                           number;
    p_frqs                           number;
    p_fqs                            number;
    p_ffs                             number;
    p_tgr                             number;
    p_sum_ins                     number;
    p_sum_ins_ret2             number;
    ri_share                        number;
    ri_reserve_amt              number;
    ri_share_fpre                 number;
    ri_reserve_amt_fpre       number;
    ri_share_ret                   number;
    ri_reserve_amt_ret        number;
    w_ri_shr                       number;
    w_sum_block                number;
    p_tot_sum_ins               number;
    p_sum_shr                    number;
    p_block_limit                 number;
    p_fqs_limit                    number;
    p_end                           number;
    p_lines                          number;
    v_amt_quota                 number;
    v_amt_surplus               number;
    v_lines                          number;
  --  ws_recpt_seq               number;
  --  ws_loc_seq                   number;
    p_ri_end                       varchar2(1);
    p_pla_no                       varchar2(20);
    p_cashcall                     varchar2(2);
    v_nat_peril_flag             varchar2(1);
    p_fronting                      varchar2(1);
    w_message                   varchar2(100);
    v_catas_code                 varchar2(3);
    p_chk_re                       varchar2(1);
    w_ri_code                     varchar2(3);
    sum_ri_share_nat_cat                  number := 0;
    sum_ri_reserve_amt_nat_cat        number := 0;

BEGIN
  if   nvl(p_reserve_amt,0) = 0  then
         Begin
             select count(*)
             into     v_count
             from   nc_reinsurance_tmp
             where sts_key = p_sts_key;
         Exception
             when  no_data_found  then
                       v_count := 0;
             when  others   then
                       v_count := 0;
         End;
         if  v_count = 0  then
             NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null,'2','999','99','00','N',100,0,0) ;
         else
             Begin
                 update nc_reinsurance_tmp set ri_reserve_amt = 0
                 where  sts_key = p_sts_key;
             Exception
                 when  OTHERS  then
                         rollback;
             End;
         end if;
  else
    Begin
        delete from nc_reinsurance_tmp where sts_key = p_sts_key;
        Exception
           when  OTHERS  then
           rollback;
    End;
    commit;
    Begin
        delete from nc_fir_block_reloss_tmp where sts_key = p_sts_key;
        Exception
           when  OTHERS  then
           rollback;
    End;
    commit;
    p_message   := null;
    p_message2 := null;

    if p_prod_grp = '2'  and p_prod_type in ('221','223')  then
       NMTR_PACKAGE.nc_mrn_reinsurance (p_pol_no, p_pol_run, p_pol_seq, p_sailing_date, p_vessel_code, p_I_E, p_flight_no,
                                                               p_trc, p_ret, p_first, p_second, p_binder, p_reserve_fac, p_pret, p_sum_ins, p_sum_ins_ret2, c3, p_message );
    --   frac := nvl(p_reserve_amt,0) - floor(nvl(p_reserve_amt,0));       varit 8-oct-15  cancel round up

       -- *** GET SID ***
    --    Begin
    --        select sys_context('USERENV', 'SID') into v_sid
    --        from DUAL;
    --    Exception
    --        when  NO_DATA_FOUND  then
    --                  v_sid := 0;
    --        when  OTHERS  then
    --                  v_sid := 0;
    --    End;

        LOOP
           FETCH  c3  INTO ri_rec3;
            EXIT WHEN c3%NOTFOUND;
                if  ri_rec3.ri_type1 = '0'  then
          --          ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_rec3.ri_share)/100,0);       varit  8-oct-15
                    ri_reserve_amt  :=  trunc((nvl(p_reserve_amt,0) * ri_rec3.ri_share) / 100,2);      -- varit 8-oct-15
                    NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                    NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                    NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_rec3.ri_share,ri_reserve_amt,0) ;
                    sum_ri_fac       :=  sum_ri_fac + ri_reserve_amt;
                    sum_ri_share   :=  sum_ri_share + ri_rec3.ri_share;
                end if;

                if  ri_rec3.ri_type1 = '1' and ri_rec3.ri_type2 = '02'  then
                    if  p_sum_ins <= 200000000 then
             --           ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_rec3.ri_share)/100,0);       varit  8-oct-15
                        ri_reserve_amt  :=  trunc((nvl(p_reserve_amt,0) * ri_rec3.ri_share) / 100,2);      -- varit 8-oct-15
                        NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                        p_pla_no := null;
                        if  p_cashcall = 'Y'   then
                            NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                        end if;
                        NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_rec3.ri_share,ri_reserve_amt,0) ;
                        sum_ri_share   :=  sum_ri_share + ri_rec3.ri_share;
                    else
                        begin
                           select  sum(sum_ins)
                              into  tot_sum_trc
                            from   mrn_pol
                          where   pol_no  = p_pol_no
                              and   pol_run = p_pol_run
                              and   pol_seq = p_pol_seq;
                        end;
                  --      ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * nvl(p_trc,0))/tot_sum_trc,0);       Varit  8-oct-15
                        ri_reserve_amt  := (nvl(p_reserve_amt,0) * nvl(p_trc,0)) / tot_sum_trc;    -- varit 8-oct-15
                        NMTR_PACKAGE.nc_get_ri_share (nvl(p_reserve_amt,0), ri_reserve_amt, ri_share) ;
                        NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                        p_pla_no := null;
                        if  p_cashcall = 'Y'   then
                            NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                        end if;
                        ri_reserve_amt  :=  trunc((nvl(p_reserve_amt,0) * ri_share) / 100,2);
                        NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_share,ri_reserve_amt,0) ;
                         sum_ri_share   :=  sum_ri_share + ri_share;
                    end if;
                    sum_ri_trc      :=  sum_ri_trc + ri_reserve_amt;
                end if;

                if  ri_rec3.ri_type1 = '1' and ri_rec3.ri_type2 in ('08','98') then
                    if  p_sum_ins <= 200000000 then
                  --      ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_rec3.ri_share)/100,0);       varit 8-oct-15
                        ri_reserve_amt  := trunc((nvl(p_reserve_amt,0) * ri_rec3.ri_share) / 100,2);                 -- varit 8-oct-15
                        NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                        p_pla_no := null;
                        if  p_cashcall = 'Y'   then
                            NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                        end if;
                        NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_rec3.ri_share,ri_reserve_amt,0) ;
                         sum_ri_share   :=  sum_ri_share + ri_rec3.ri_share;
                    else
                        begin
                           select  sum(sum_ins)
                              into  tot_sum_trc
                             from  mrn_pol
                           where  pol_no  = p_pol_no
                               and  pol_run = p_pol_run
                               and  pol_seq = p_pol_seq;
                        end;
                   --     ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * nvl(ri_rec3.ri_sum,0))/tot_sum_trc,0);       varit 8-oct-15
                        ri_reserve_amt  := (nvl(p_reserve_amt,0) * nvl(ri_rec3.ri_sum,0)) / tot_sum_trc;      -- varit 8-oct-15
                        NMTR_PACKAGE.nc_get_ri_share (nvl(p_reserve_amt,0), ri_reserve_amt, ri_share) ;
                        NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                        p_pla_no := null;
                        if  p_cashcall = 'Y'   then
                            NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                        end if;
                        ri_reserve_amt  :=  trunc((nvl(p_reserve_amt,0) * ri_share) / 100,2);
                        NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_share,ri_reserve_amt,0) ;
                         sum_ri_share   :=  sum_ri_share + ri_share;
                    end if;
                    sum_ri_font      :=  sum_ri_font + ri_reserve_amt;
                end if;

                 if     ri_rec3.ri_type1 = '1' and ri_rec3.ri_type2 = '00' then
                  --       ri_reserve_amt  := Round(((floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_fac,0) -  nvl(sum_ri_trc,0)  - nvl(sum_ri_font,0)) * nvl(p_first,0)) / (nvl(p_first,0) + nvl(p_ret,0) + nvl(p_pret,0)),0);   varit  8-oct-15
                         ri_reserve_amt  :=   ((nvl(p_reserve_amt,0) - nvl(sum_ri_fac,0) -  nvl(sum_ri_trc,0)  - nvl(sum_ri_font,0)) * nvl(p_first,0)) / (nvl(p_first,0) + nvl(p_ret,0) + nvl(p_pret,0));   -- varit 8-oct-15
                  --       ri_reserve_amt  :=  (nvl(p_reserve_amt,0) * ri_rec3.ri_share) / 100;   -- varit  13-oct-15
                         NMTR_PACKAGE.nc_get_ri_share (nvl(p_reserve_amt,0), ri_reserve_amt, ri_share) ;
                         NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                         p_pla_no := null;
                         if  p_cashcall = 'Y'   then
                            NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                         end if;
                         ri_reserve_amt  :=  trunc((nvl(p_reserve_amt,0) * ri_share) / 100,2);
                         sum_ri_first       :=   sum_ri_first + ri_reserve_amt ;
                         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_share,ri_reserve_amt,0) ;
                         sum_ri_share   :=  sum_ri_share + ri_share;
                 elsif  ri_rec3.ri_type1 = '1' and ri_rec3.ri_type2 = '01' then
                  --       ri_reserve_amt  := Round(((floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_fac,0) -  nvl(sum_ri_trc,0)) * nvl(p_second,0)) / (nvl(p_sum_ins_ret2,0)),0);       varit 8-oct-15
                         ri_reserve_amt  :=  ((nvl(p_reserve_amt,0) - nvl(sum_ri_fac,0) -  nvl(sum_ri_trc,0)) * nvl(p_second,0)) / nvl(p_sum_ins_ret2,0);      -- varit 8-oct-15
                  --       ri_reserve_amt  :=  (nvl(p_reserve_amt,0) * ri_rec3.ri_share) / 100;   -- varit  13-oct-15
                         NMTR_PACKAGE.nc_get_ri_share (nvl(p_reserve_amt,0), ri_reserve_amt, ri_share) ;
                         NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                         p_pla_no := null;
                         if  p_cashcall = 'Y'   then
                            NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                         end if;
                         ri_reserve_amt  :=  trunc((nvl(p_reserve_amt,0) * ri_share) / 100,2);
                         sum_ri_second  :=  sum_ri_second + ri_reserve_amt ;
                         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_share,ri_reserve_amt,0) ;
                         sum_ri_share   :=  sum_ri_share + ri_share;
                 elsif  ri_rec3.ri_type1 = '1' and ri_rec3.ri_type2 = '04' then
                    --     ri_reserve_amt  := Round(((floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_fac,0) -  nvl(sum_ri_trc,0)) * nvl(p_binder,0)) / (nvl(p_sum_ins_ret2,0)),0);       varit  8-oct-15
                         ri_reserve_amt  := ((nvl(p_reserve_amt,0) - nvl(sum_ri_fac,0) -  nvl(sum_ri_trc,0)) * nvl(p_binder,0)) / nvl(p_sum_ins_ret2,0);    -- varit 8-oct-15
                    --     ri_reserve_amt  :=  (nvl(p_reserve_amt,0) * ri_rec3.ri_share) / 100;   -- varit  13-oct-15
                         NMTR_PACKAGE.nc_get_ri_share (nvl(p_reserve_amt,0), ri_reserve_amt, ri_share) ;
                         NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                         p_pla_no := null;
                         if  p_cashcall = 'Y'   then
                            NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                         end if;
                         ri_reserve_amt  := trunc((nvl(p_reserve_amt,0) * ri_share) / 100,2);
                         sum_ri_binder   :=  sum_ri_binder + ri_reserve_amt ;
                         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_share,ri_reserve_amt,0) ;
                          sum_ri_share   :=  sum_ri_share + ri_share;
                 elsif  ri_rec3.ri_code||ri_rec3.ri_br_code||ri_rec3.lf_flag||ri_rec3.ri_type1||ri_rec3.ri_type2 = '99997N200'  and p_ret = 0 then
                   --       ri_reserve_amt  := floor(nvl(p_reserve_amt,0)) + nvl(frac,0) - nvl(sum_ri_fac,0) - nvl(sum_ri_trc,0) - nvl(sum_ri_font,0) - nvl(sum_ri_first,0) - nvl(sum_ri_second,0) - nvl(sum_ri_binder,0) ;    varit 8-oct-15
                          ri_reserve_amt  := nvl(p_reserve_amt,0) - nvl(sum_ri_fac,0) - nvl(sum_ri_trc,0) - nvl(sum_ri_font,0) - nvl(sum_ri_first,0) - nvl(sum_ri_second,0) - nvl(sum_ri_binder,0) ;     -- varit 8-oct-15
                          w_ri_shr := 100 - sum_ri_share;
                    --   NMTR_PACKAGE.nc_get_ri_share (nvl(p_reserve_amt,0), ri_reserve_amt, ri_share) ;
                          NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,w_ri_shr,ri_reserve_amt,0) ;
                 elsif  ri_rec3.ri_code||ri_rec3.ri_br_code||ri_rec3.lf_flag||ri_rec3.ri_type1||ri_rec3.ri_type2 = '99997N200'  and p_ret > 0 then
                    --     ri_reserve_amt  := round(((floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_fac,0) - nvl(sum_ri_trc,0) - nvl(sum_ri_font,0)) * p_pret)/(p_pret + p_ret + p_first),0) ;
                          ri_reserve_amt  := ((nvl(p_reserve_amt,0) - nvl(sum_ri_fac,0) - nvl(sum_ri_trc,0) - nvl(sum_ri_font,0)) * p_pret)/(p_pret + p_ret + p_first) ;    -- varit  8-oct-15
                          NMTR_PACKAGE.nc_get_ri_share (nvl(p_reserve_amt,0), ri_reserve_amt, ri_share) ;
                          ri_reserve_amt  :=  trunc((nvl(p_reserve_amt,0) * ri_share) / 100,2);
                          sum_ri_ret2     := sum_ri_ret2 + ri_reserve_amt;
                          NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_share,ri_reserve_amt,0) ;
                          sum_ri_share   :=  sum_ri_share + ri_share;
                 elsif  ri_rec3.ri_code||ri_rec3.ri_br_code||ri_rec3.lf_flag||ri_rec3.ri_type1||ri_rec3.ri_type2 = '99999N200' then
                  --        ri_reserve_amt  := floor(nvl(p_reserve_amt,0)) + nvl(frac,0) - nvl(sum_ri_fac,0) - nvl(sum_ri_trc,0) - nvl(sum_ri_font,0) - nvl(sum_ri_first,0) - nvl(sum_ri_second,0) - nvl(sum_ri_binder,0) - nvl(sum_ri_ret2,0);   varit 8-oct-15
                          ri_reserve_amt  := nvl(p_reserve_amt,0) - nvl(sum_ri_fac,0) - nvl(sum_ri_trc,0) - nvl(sum_ri_font,0) - nvl(sum_ri_first,0) - nvl(sum_ri_second,0) - nvl(sum_ri_binder,0) - nvl(sum_ri_ret2,0);                            -- varit 8-oct-15
                    --   NMTR_PACKAGE.nc_get_ri_share (nvl(p_reserve_amt,0), ri_reserve_amt, ri_share) ;
                          w_ri_shr := 100 - sum_ri_share;
                          NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,w_ri_shr,nvl(ri_reserve_amt,0),0) ;
                 end if;

       END LOOP;


  --      LOOP
  --         FETCH  c3  INTO ri_rec3;
  --          EXIT WHEN c3%NOTFOUND;
  --              if  ri_rec3.ri_code||ri_rec3.ri_br_code||ri_rec3.lf_flag||ri_rec3.ri_type1||ri_rec3.ri_type2 = '99997N200' then
  --                  ri_reserve_amt  := round(((floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_fac,0) - nvl(sum_ri_trc,0) - nvl(sum_ri_font,0)) * p_pret)/(p_pret + p_ret + p_first),0);
  --                  sum_ri_ret2     := sum_ri_ret2 + ri_reserve_amt;
  --                  cnt_ret2  := 1;
  --              elsif ri_rec3.ri_code||ri_rec3.ri_br_code||ri_rec3.lf_flag||ri_rec3.ri_type1||ri_rec3.ri_type2 = '99999N200'   then
  --                     cnt_ret1  := 1;
  --              end if;
  --       END LOOP;

    elsif  p_prod_grp = '2' and p_prod_type = '222'  then
            NMTR_PACKAGE.nc_hull_reinsurance (p_pol_no, p_pol_run, p_ret, p_ret1, p_ret2, c3, p_message );
            frac := nvl(p_reserve_amt,0) - floor(nvl(p_reserve_amt,0));
            LOOP
                FETCH  c3  INTO ri_rec3;
                EXIT WHEN c3%NOTFOUND;
                    if       ri_rec3.ri_code||ri_rec3.ri_br_code||ri_rec3.lf_flag||ri_rec3.ri_type1||ri_rec3.ri_type2 = '99996N202'  and  p_ret = 0 and p_ret2 = 0 then
                             ri_reserve_amt := floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_reserve_amt,0) + nvl(frac,0);
                             w_ri_shr := 100 - sum_ri_share;
                             sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                             sum_ri_share := sum_ri_share + nvl(w_ri_shr,0);
                             NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,w_ri_shr,ri_reserve_amt,0) ;
                    elsif   ri_rec3.ri_code||ri_rec3.ri_br_code||ri_rec3.lf_flag||ri_rec3.ri_type1||ri_rec3.ri_type2 = '99999N201'  and  p_ret = 0  then
                             ri_reserve_amt := floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_reserve_amt,0) + nvl(frac,0);
                             w_ri_shr := 100 - sum_ri_share;
                             sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                             sum_ri_share := sum_ri_share + nvl(w_ri_shr,0);
                             NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,w_ri_shr,ri_reserve_amt,0) ;
                    elsif   ri_rec3.ri_code||ri_rec3.ri_br_code||ri_rec3.lf_flag||ri_rec3.ri_type1||ri_rec3.ri_type2 = '99999N200'  then
                             ri_reserve_amt := floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_reserve_amt,0) + nvl(frac,0);
                             w_ri_shr := 100 - sum_ri_share;
                             sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                             sum_ri_share := sum_ri_share + nvl(w_ri_shr,0);
                             NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,w_ri_shr,ri_reserve_amt,0) ;
                    else   ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_rec3.ri_share)/100,0);
                             sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                             sum_ri_share := sum_ri_share + nvl(ri_rec3.ri_share,0);
                             if   ri_rec3.ri_type1 = '0'  then
                                  NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                                  NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                                  NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_rec3.ri_share,ri_reserve_amt,0) ;
                             elsif   ri_rec3.ri_type1 = '1'  then
                                      NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                                      p_pla_no := null;
                                      if  p_cashcall = 'Y'   then
                                          NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                                      end if;
                                      NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_rec3.ri_share,ri_reserve_amt,0) ;
                             end if;
                    end if;
            END LOOP;
            Begin
               if  sum_ri_share <> 100 or nvl(sum_ri_reserve_amt,0) <> nvl(p_reserve_amt,0)  then
                   p_message := 'R/I %Share is not equal to 100% or Sum of R/I Reserve Amount is not equal to Reserve Amount';
               end if;
            end;
    elsif  p_prod_grp  in  ('4','5','9')   then
            if  p_loss_date_flag = 'N' and p_cause_flag = 'N'  then
                frac := nvl(p_reserve_amt,0) - floor(nvl(p_reserve_amt,0));
                NMTR_PACKAGE.nc_misc_reinsurance_ret (p_sts_key, v_99999, v_99998, v_99993) ;
                NMTR_PACKAGE.nc_misc_reinsurance_initial (p_sts_key, c6, p_message );
                LOOP
                        FETCH  c6  INTO ri_rec6;
                        EXIT WHEN c6%NOTFOUND;

                        if  v_99999 = '1'  and ri_rec6.ri_code||ri_rec6.ri_br_code||ri_rec6.lf_flag||ri_rec6.ri_type1||ri_rec6.ri_type2 = '99999N200'  then
                            ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_rec6.ri_share)/100,4) + nvl(frac,0) ;
                            NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, ri_rec6.pla_no, p_cashcall, ri_rec6.ri_type1,ri_rec6.ri_code,ri_rec6.ri_br_code,ri_rec6.ri_type2,ri_rec6.lf_flag,ri_rec6.ri_share,ri_reserve_amt,0) ;
                            p_pla_no         := null;
                            p_cashcall       := null;
                        elsif v_99999 = '0' and v_99998 = '1' and ri_rec6.ri_code||ri_rec6.ri_br_code||ri_rec6.lf_flag||ri_rec6.ri_type1||ri_rec6.ri_type2 = '99998N201'  then
                               ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_rec6.ri_share)/100,4) + nvl(frac,0) ;
                               NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, ri_rec6.pla_no, p_cashcall, ri_rec6.ri_type1,ri_rec6.ri_code,ri_rec6.ri_br_code,ri_rec6.ri_type2,ri_rec6.lf_flag,ri_rec6.ri_share,ri_reserve_amt,0) ;
                               p_pla_no         := null;
                               p_cashcall       := null;
                        elsif v_99999 = '0' and v_99998 = '0' and v_99993 = '1' and ri_rec6.ri_code||ri_rec6.ri_br_code||ri_rec6.lf_flag||ri_rec6.ri_type1||ri_rec6.ri_type2 = '99993N200'  then
                               ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_rec6.ri_share)/100,4) + nvl(frac,0) ;
                               NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, ri_rec6.pla_no, p_cashcall, ri_rec6.ri_type1,ri_rec6.ri_code,ri_rec6.ri_br_code,ri_rec6.ri_type2,ri_rec6.lf_flag,ri_rec6.ri_share,ri_reserve_amt,0) ;
                               p_pla_no         := null;
                               p_cashcall       := null;
                        elsif v_99999 = '0' and v_99998 = '0' and v_99993 = '0' and ri_rec6.ri_code||ri_rec6.ri_br_code||ri_rec6.lf_flag||ri_rec6.ri_type1||ri_rec6.ri_type2 = '94500N160'  then
                               ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_rec6.ri_share)/100,4) + nvl(frac,0) ;
                               NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, ri_rec6.pla_no, p_cashcall, ri_rec6.ri_type1,ri_rec6.ri_code,ri_rec6.ri_br_code,ri_rec6.ri_type2,ri_rec6.lf_flag,ri_rec6.ri_share,ri_reserve_amt,0) ;
                               p_pla_no         := null;
                               p_cashcall       := null;
                        else
                              ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_rec6.ri_share)/100,4) ;
                              if  ri_rec6.ri_type1 = '0'  then
                                   NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec6.ri_code, ri_rec6.ri_br_code, ri_rec6.lf_flag, ri_rec6.ri_type1, ri_rec6.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                              end if;
                              if  ri_rec6.ri_type1 = '1'  then
                                   NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec6.ri_code, ri_rec6.ri_br_code, ri_rec6.lf_flag, ri_rec6.ri_type1, ri_rec6.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                                   if  p_cashcall = 'Y' and nvl(ri_rec6.pla_no,'N') = 'N'  then
                                       NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                                       ri_rec6.pla_no := p_pla_no;
                                   end if;
                              end if;
                              NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, ri_rec6.pla_no, p_cashcall, ri_rec6.ri_type1,ri_rec6.ri_code,ri_rec6.ri_br_code,ri_rec6.ri_type2,ri_rec6.lf_flag,ri_rec6.ri_share,ri_reserve_amt,0) ;
                              p_pla_no         := null;
                              p_cashcall       := null;
                        end if;
                END LOOP;
            else
             Begin
                select nvl(alc_re,'1'), nvl(ri_end,'N'), end_seq , nvl(fronting,'N')
                   into p_alc_re, p_ri_end, p_end , p_fronting
                  from mis_mas
                where pol_no = p_pol_no
                    and nvl(pol_run,0) = nvl(p_pol_run,0)
                    and end_seq = (select max(end_seq)
                                             from mis_mas
                                           where pol_no = p_pol_no
                                               and nvl(pol_run,0) = nvl(p_pol_run,0)
                                               and (p_loss_date between fr_date and to_date or
                                                       p_loss_date between fr_date and to_maint or
                                                       p_loss_date between fr_maint and to_date));
             exception
              when too_many_rows then
                       p_message := 'Error Reinsurance End (Too many rows)';
                       p_end := null;
              when no_data_found  then
                       p_ri_end := 'N';
                       p_end := null;
                       p_message := 'Reinsurance is not already';
              when others  then
                       p_end := null;
             End;
             
             Begin
                 select nat_peril_flag
                    into v_nat_peril_flag
                  from clm_cause_std
                where cause_code = p_cause_code
                    and cause_seq  = p_cause_seq;
             exception
                  when others then
                           v_nat_peril_flag  := null;
             End;                    

             NMTR_PACKAGE.nc_iar_chk_reinsurance (p_pol_no, p_pol_run, p_prod_type, p_alc_re, p_recpt_seq, p_loc_seq, p_loss_date, p_chk_re, p_message ) ;     --- varit 7 mar 16

             if  p_ri_end <> 'N'  then
                 frac := nvl(p_reserve_amt,0) - floor(nvl(p_reserve_amt,0));
                 if  p_pol_yr >= '2012'  and  p_prod_type in ('551')  and p_fronting = 'N' and p_chk_re = 'Y'  then
                     NMTR_PACKAGE.nc_iar_fac_reinsurance (p_pol_no, p_pol_run, p_prod_type, p_alc_re, p_recpt_seq, p_loc_seq, p_loss_date, c5, p_message );
                     LOOP
                        FETCH  c5  INTO ri_rec5;
                        EXIT WHEN c5%NOTFOUND;
                        if  nvl(ri_rec5.sum_ins,0) <= 0  then
                            Begin
                                select  sum(nvl(b.sum_ins,0))
                                   into  ri_rec5.sum_ins
                                  from mis_mas a, mis_loc b
                                where a.pol_no = p_pol_no
                                    and a.poL_run = p_pol_run
                                    and p_loss_date  between a.fr_date and a.to_date
                                    and a.pol_no = b.pol_no
                                    and a.pol_run = b.pol_run
                                    and a.end_seq = b.end_seq
                                    and b.loc_seq = p_loc_seq;
                                    ri_share := round((nvl(ri_rec5.ri_sum_ins,0) / nvl(ri_rec5.sum_ins,0)) * 100,5);
                                    ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_share)/100,4);
                                    if  ri_rec5.ri_type1 = '0'  then
                                        NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                                        NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec5.ri_code, ri_rec5.ri_br_code, ri_rec5.lf_flag, ri_rec5.ri_type1, ri_rec5.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                                    end if;
                                    NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec5.ri_type1,ri_rec5.ri_code,ri_rec5.ri_br_code,ri_rec5.ri_type2,ri_rec5.lf_flag,ri_share,ri_reserve_amt,0) ;
                                    p_pla_no         := null;
                                    p_cashcall       := null;
                             --       sum_ri_fac       :=  sum_ri_fac + ri_reserve_amt;          varit  5-nov-15
                             --       sum_shr_fac    :=  sum_shr_fac + ri_share;                  varit  5-nov-15
                                    sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                                    sum_ri_share := sum_ri_share + nvl(ri_share,0);
                            Exception
                            when others then
                                   ri_share := 0;
                                   ri_reserve_amt := 0;
                                   p_message := 'No data sum_ins';
                            End;
                        else
                            ri_share := round((nvl(ri_rec5.ri_sum_ins,0) / nvl(ri_rec5.sum_ins,0)) * 100,5);
                            ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_share)/100,4);
                            if  ri_rec5.ri_type1 = '0'  then
                                NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                                NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec5.ri_code, ri_rec5.ri_br_code, ri_rec5.lf_flag, ri_rec5.ri_type1, ri_rec5.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                            end if;
                            NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec5.ri_type1,ri_rec5.ri_code,ri_rec5.ri_br_code,ri_rec5.ri_type2,ri_rec5.lf_flag,ri_share,ri_reserve_amt,0) ;
                            p_pla_no         := null;
                            p_cashcall       := null;
                     --       sum_ri_fac      :=  sum_ri_fac + ri_reserve_amt;          varit  5-nov-15
                     --       sum_shr_fac    :=  sum_shr_fac + ri_share;                 varit  5-nov-15
                            sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                            sum_ri_share := sum_ri_share + nvl(ri_share,0);
                        end if;
                     END LOOP;
                  --   p_balance := floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_fac,0);                       varit  5-nov-15
                     p_balance := floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_reserve_amt,0);      --   varit  5-nov-15
                     NMTR_PACKAGE.nc_get_block_limit (p_block, p_block_limit, p_fqs_limit);
                     NMTR_PACKAGE.nc_block_reloss_accum  (p_block, p_pol_no, p_pol_run, p_loss_date, p_loc_seq, p_first, p_second, p_fpre, p_ret, p_fqs, p_ffs, p_sum_ins, p_tgr);
                  --   w_sum_block := nvl(p_fpre,0) + nvl(p_ret,0) + nvl(p_fqs,0) + nvl(p_ffs,0);          varit  03-nov-15
                     w_sum_block :=  nvl(p_fqs,0) + nvl(p_ffs,0);                                                  --  varit  03-nov-15
                     if  w_sum_block = 0  then
                         w_sum_block := 1;
                     end if;
                     NMTR_PACKAGE.nc_insert_fir_block_reloss_tmp (p_pol_no, p_sts_key, p_block, p_block_limit, p_first, p_second, p_fpre, p_ret, 0, 0, p_tgr, p_sum_ins, p_pol_run, p_fqs_limit, p_fqs, p_ffs);
                     begin
                        select nat_peril_flag
                           into v_nat_peril_flag
                         from clm_cause_std
                       where cause_code = p_cause_code
                           and cause_seq  = p_cause_seq;
                     exception
                     when others then
                              v_nat_peril_flag  := null;
                     end;
                     if   v_nat_peril_flag = 'Y'  then
                     --     if  nvl(p_fpre,0)  = 0  and nvl(p_ret,0) = 0  then                                                                                                                                    varit  03-nov-15
                     --         ri_reserve_amt :=  floor(nvl(p_reserve_amt,0)) - sum_ri_reserve_amt;                                                                                              varit  03-nov-15
                     --         ri_share           :=  100 - sum_ri_share;                                                                                                                                          varit  03-nov-15
                     --         ri_reserve_amt := nvl(ri_reserve_amt,0) + nvl(frac,0) ;                                                                                                                    varit  03-nov-15
                     --     else                                                                                                                                                                                                 varit  03-nov-15
                        --      ri_share             :=  round(round(((nvl(p_fqs,0) + nvl(p_ffs,0)) / w_sum_block)*100,5)* round((100 - sum_shr_fac)/100,5));               varit  03-nov-15
                     --         ri_share             :=  round(((nvl(p_fqs,0) + nvl(p_ffs,0)) / w_sum_block)*100,4)* round((100 - sum_shr_fac)/100,4);                         varit  03-nov-15
                     --         ri_reserve_amt   := round((p_balance * ri_share)/100,2);                                                                                                               varit  03-nov-15
                        --      ri_reserve_amt   := (p_balance * ri_share)/100,4;                                                                                                                          varit  03-nov-15
                     --        sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);                                                                                               varit  03-nov-15
                     --         sum_ri_share := sum_ri_share + nvl(ri_share,0);                                                                                                                            varit  03-nov-15
                     --     end if;                                                                                                                                                                                              varit  03-nov-15
                          ri_reserve_amt :=  floor(nvl(p_reserve_amt,0)) - sum_ri_reserve_amt;                                                                                  --  varit   03-nov-15
                          ri_share           :=  100 - sum_ri_share;                                                                                                                              --  varit   03-nov-15
                          ri_reserve_amt := nvl(ri_reserve_amt,0) + nvl(frac,0) ;                                                                                                        --  varit   03-nov-15
                          NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, '999', '93', 'N', '2', '00', ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                          if  p_cashcall = 'Y'   then
                              NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                             end if;
                         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '93', '00', 'N', ri_share, ri_reserve_amt,0) ;
                     else
                       --  ri_share             :=  round(round((nvl(p_fqs,0)  / w_sum_block)*100,5)* round((100 - sum_shr_fac)/100,5));
                     --    ri_share             :=  round((nvl(p_fqs,0)  / w_sum_block)*100,4)* round((100 - sum_shr_fac)/100,4);                                 varit  5-nov-15
                         ri_share             :=  round((nvl(p_fqs,0)  / w_sum_block)*100,4)* round((100 - sum_ri_share)/100,4);                              --  varit  5-nov-15
                       --  ri_reserve_amt   := round((p_balance * ri_share)/100,2);                                                                                                 varit  21-jan-15
                         ri_reserve_amt   := Round((floor(nvl(p_reserve_amt,0)) * ri_share)/100,2);                                                                     --  varit  21-jan-15
                       -- ri_reserve_amt   := ((p_balance * ri_share)/100,4);
                         NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, '945', '00', 'N', '1', '02', ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                        if  p_cashcall = 'Y'   then
                             NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                        else
                             p_pla_no := null;
                        end if;
                        NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, '1', '945', '00', '02', 'N', ri_share, ri_reserve_amt,0) ;
                        sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                        sum_ri_share := sum_ri_share + nvl(ri_share,0);
                 --       if  nvl(p_fpre,0)  = 0  and nvl(p_ret,0) = 0  then                                                                                                                varit  5-nov-15
                 --           ri_reserve_amt :=  floor(nvl(p_reserve_amt,0)) - sum_ri_reserve_amt;                                                                          varit  5-nov-15
                 --           ri_share           :=  100 - sum_ri_share;                                                                                                                      varit  5-nov-15
                 --           ri_reserve_amt := nvl(ri_reserve_amt,0) + nvl(frac,0) ;                                                                                                varit  5-nov-15
                 --       else                                                                                                                                                                             varit  5-nov-15
                         --   ri_share             :=  round(round((nvl(p_ffs,0)  / w_sum_block)*100,5)* round((100 - sum_shr_fac)/100,5));
                 --           ri_share             :=  round((nvl(p_ffs,0)  / w_sum_block)*100,4)* round((100 - sum_shr_fac)/100,4);                            varit  5-nov-15
                 --           ri_reserve_amt   := round((p_balance * ri_share)/100,2);                                                                                            varit 5-nov-15
                         --   ri_reserve_amt   := ((p_balance * ri_share)/100,4);
                 --           sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);                                                                          varit  5-nov-15
                 --          sum_ri_share := sum_ri_share + nvl(ri_share,0);                                                                                                         varit  5-nov-15
                 --    end if;                                                                                                                                                                            varit  5-nov-15
                        ri_reserve_amt :=  floor(nvl(p_reserve_amt,0)) - sum_ri_reserve_amt;              -- varit  5-nov-15
                        ri_share           :=  100 - sum_ri_share;                                                           -- varit 5-nov-15
                        ri_reserve_amt := nvl(ri_reserve_amt,0) + nvl(frac,0) ;                                      -- varit 5-nov-15
                        NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, '945', '00', 'N', '1', '60', ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                        if  p_cashcall = 'Y'   then
                            NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                        else
                            p_pla_no := null;
                        end if;
                        NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, '1', '945', '00', '60', 'N', ri_share, ri_reserve_amt, p_lines) ;

                     end if;

                     Begin                                                                              --    varit  8-jan-16
                        select   ri_reserve_amt                                                  --    varit  8-jan-16
                           into   v_amt_quota                                                     --    varit  8-jan-16
                         from   nc_reinsurance_tmp                                           --    varit  8-jan-16
                       where   sts_key = p_sts_key                                           --    varit  8-jan-16
                          and    ri_code = '945'                                                  --    varit  8-jan-16
                          and    ri_br_code = '00'                                               --    varit  8-jan-16
                          and    lf_flag = 'N'                                                       --    varit  8-jan-16
                          and    ri_type1 = '1'                                                     --    varit  8-jan-16
                          and    ri_type2 = '02';                                                  --    varit  8-jan-16
                     Exception                                                                         --    varit  8-jan-16
                        when  no_data_found  then                                            --    varit  8-jan-16
                                  v_amt_quota := 0;                                               --    varit  8-jan-16
                        when  others   then                                                        --    varit  8-jan-16
                                  v_amt_quota := 0;                                               --    varit  8-jan-16
                     End;                                                                                 --    varit  8-jan-16

                      Begin                                                                              --    varit  8-jan-16
                        select   ri_reserve_amt, lines                                          --    varit  8-jan-16
                           into   v_amt_surplus, v_lines                                       --    varit  8-jan-16
                         from   nc_reinsurance_tmp                                           --    varit  8-jan-16
                       where   sts_key = p_sts_key                                           --    varit  8-jan-16
                          and    ri_code = '945'                                                  --    varit  8-jan-16
                          and    ri_br_code = '00'                                               --    varit  8-jan-16
                          and    lf_flag = 'N'                                                       --    varit  8-jan-16
                          and    ri_type1 = '1'                                                     --    varit  8-jan-16
                          and    ri_type2 = '60';                                                  --    varit  8-jan-16
                      Exception                                                                        --    varit  8-jan-16
                        when  no_data_found  then                                            --    varit  8-jan-16
                                  v_amt_surplus := 0;                                            --    varit  8-jan-16
                                  v_lines := 0;                                                       --    varit  8-jan-16
                        when  others   then                                                        --    varit  8-jan-16
                                  v_amt_surplus := 0;                                             --    varit  8-jan-16
                                  v_lines := 0;                                                        --    varit  8-jan-16
                      End;                                                                                --    varit  8-jan-16

                     if   (nvl(v_amt_quota,0) <= 0 and nvl(v_amt_surplus,0) > 0) or ((nvl(v_amt_quota,0) > 0 and nvl(v_amt_surplus,0) > 0)
                           and (nvl(v_amt_quota,0) * nvl(v_lines,0)  <  nvl(v_amt_surplus,0)))    then                                         --    varit  8-jan-16
                     --     Begin                                                                                                                                              --    varit  8-jan-16
                     --        delete from nc_reinsurance_tmp where sts_key = p_sts_key;                                                           --    varit  8-jan-16
                     --     Exception                                                                                                                                        --    varit  8-jan-16
                     --        when  OTHERS  then                                                                                                                     --    varit  8-jan-16
                     --        rollback;                                                                                                                                       --    varit  8-jan-16
                     --     End;                                                                                                                                                --    varit  8-jan-16
                     --     commit;                                                                                                                                           --    varit  8-jan-16
                     --     Begin                                                                                                                                               --    varit  8-jan-16
                     --        delete from nc_fir_block_reloss_tmp where sts_key = p_sts_key;                                                       --    varit  8-jan-16
                     --     Exception                                                                                                                                          --    varit  8-jan-16
                     --        when  OTHERS  then                                                                                                                      --    varit  8-jan-16
                     --        rollback;                                                                                                                                        --    varit  8-jan-16
                     --     End;                                                                                                                                                 --    varit  8-jan-16
                     --     commit;                                                                                                                                            --    varit  8-jan-16
                          p_message := 'Due to Quota Share is less than No. of lines of First Surplus - Please contact U/W';      --    varit  8-jan-16
                     end if;                                                                                                                                                    --    varit  8-jan-16

                --     if  nvl(p_fpre,0)  > 0  then                                                                                                                                                          varit  5-nov-15
                --         if  nvl(p_ret,0) = 0  then                                                                                                                                                        varit  5-nov-15
                --             ri_reserve_amt :=  floor(nvl(p_reserve_amt,0)) - sum_ri_reserve_amt;                                                                                 varit  5-nov-15
                --             ri_share           :=  100 - sum_ri_share;                                                                                                                             varit  5-nov-15
                --             ri_reserve_amt := nvl(ri_reserve_amt,0) + nvl(frac,0) ;                                                                                                       varit  5-nov-15
                --         else                                                                                                                                                                                    varit  5-nov-15
                --             NMTR_PACKAGE.nc_fire_trty_reinsurance (p_fpre, p_balance, p_reserve_amt, p_tgr, ri_share, ri_reserve_amt);                     varit   5-nov-15
                --         end if;                                                                                                                                                                                varit   5-nov-15
                --         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '98', '01', 'N', ri_share, ri_reserve_amt) ;                 varit   5-nov-15
                --         sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);                                                                                    varit   5-nov-15
                --         sum_ri_share := sum_ri_share + nvl(ri_share,0);                                                                                                                  varit   5-nov-15
                --     end if;                                                                                                                                                                                   varit  5 -nov-15
                --     if  nvl(p_ret,0)  > 0  then                                                                                                                                                         varit  5-nov-15
                --         --NMTR_PACKAGE.nc_fire_trty_reinsurance (p_ret, p_balance, p_reserve_amt, p_tgr, ri_share, ri_reserve_amt);                        varit  5-nov-15
                --         ri_reserve_amt :=  floor(nvl(p_reserve_amt,0)) - sum_ri_reserve_amt;                                                                                   varit  5-nov-15
                --         ri_share           :=  100 - sum_ri_share;                                                                                                                                varit  5-nov-15
                --         ri_reserve_amt := nvl(ri_reserve_amt,0) + nvl(frac,0) ;                                                                                                          varit  5-nov-15
                --         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '99', '00', 'N', ri_share, ri_reserve_amt) ;                 varit  5-nov-15
                --         sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0) ;                                                                                   varit  5-nov-15
                --         sum_ri_share := sum_ri_share + nvl(ri_share,0);                                                                                                                  varit  5-nov-15
                --     end if;                                                                                                                                                                                    varit  5-nov-15
                 else
                     NMTR_PACKAGE.nc_misc_reinsurance (p_pol_no, p_pol_run, p_pol_yr, p_prod_type, p_loss_date, p_recpt_seq, p_loc_seq, p_alc_re, p_end, p_ri_end, p_tot_sum_ins, p_sum_shr, c3, p_message );
                     frac := nvl(p_reserve_amt,0) - floor(nvl(p_reserve_amt,0));
                     LOOP
                          FETCH  c3  INTO ri_rec3;
                          EXIT WHEN c3%NOTFOUND;
                          p_pla_no   := null;
                          p_cashcall := null;
                          if     nvl(p_tot_sum_ins,0) = 0 and p_alc_re = '1'  then
                                 w_ri_shr := 0;
                                 NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,w_ri_shr,0,0) ;
                          elsif  ri_rec3.ri_type1 = '0'  then
                                  if  nvl(p_tot_sum_ins,0) > 0  then
                                      w_ri_shr := round((ri_rec3.ri_sum / p_tot_sum_ins) * 100,5);
                                  else
                                      w_ri_shr := round((nvl(ri_rec3.ri_share,0) / nvl(p_sum_shr,1)) * 100,5);
                                  end if;
                                  ri_reserve_amt  := round((floor(nvl(p_reserve_amt,0)) * w_ri_shr)/100,4);
                                  NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                                  NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                                  NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,w_ri_shr,ri_reserve_amt,0) ;
                                  sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                                  sum_ri_share := sum_ri_share + nvl(w_ri_shr,0);
                          elsif  ri_rec3.ri_type1 = '3'  then
                                  if  nvl(p_tot_sum_ins,0) > 0  then
                                      w_ri_shr := round((ri_rec3.ri_sum / p_tot_sum_ins) * 100,5);
                                  else
                                      w_ri_shr := round((nvl(ri_rec3.ri_share,0) / nvl(p_sum_shr,1)) * 100,5);
                                  end if;
                                  ri_reserve_amt  := round((floor(nvl(p_reserve_amt,0)) * w_ri_shr)/100,4);
                                  NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,w_ri_shr,ri_reserve_amt,0) ;
                                  sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                                  sum_ri_share := sum_ri_share + nvl(w_ri_shr,0);
                          elsif  ri_rec3.ri_type1 = '1'  then
                                  if  p_pol_yr >= '2012' and p_prod_type in ('441','442','443','444','445','446','553','556','559','560','561') and v_nat_peril_flag  = 'Y'  and
                                      ri_rec3.ri_code||ri_rec3.ri_br_code||ri_rec3.lf_flag||ri_rec3.ri_type1||ri_rec3.ri_type2 in ('94300N100','94300N102','94200N160')   then
                                      if  nvl(p_tot_sum_ins,0) > 0  then
                                          w_ri_shr := round((ri_rec3.ri_sum / p_tot_sum_ins) * 100,5);
                                      else
                                          w_ri_shr := round((nvl(ri_rec3.ri_share,0) / nvl(p_sum_shr,1)) * 100,5);                                          
                                      end if;
                                      ri_reserve_amt  := round((floor(nvl(p_reserve_amt,0)) * w_ri_shr)/100,4);
                                      sum_ri_reserve_amt_nat_cat := sum_ri_reserve_amt_nat_cat + nvl(ri_reserve_amt,0);
                                      sum_ri_share_nat_cat := sum_ri_share_nat_cat + nvl(w_ri_shr,0);
                                      sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                                      sum_ri_share := sum_ri_share + nvl(w_ri_shr,0);
                                  else
                                      if  nvl(p_tot_sum_ins,0) > 0  then
                                          w_ri_shr := round((ri_rec3.ri_sum / p_tot_sum_ins) * 100,5);
                                      else
                                          w_ri_shr := round((nvl(ri_rec3.ri_share,0) / nvl(p_sum_shr,1)) * 100,5);
                                      end if;
                                      ri_reserve_amt  := round((floor(nvl(p_reserve_amt,0)) * w_ri_shr)/100,4);
                                      NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                                      if  p_cashcall = 'Y'   then
                                          NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                                      else
                                          p_pla_no := null;
                                      end if;
                                      NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,w_ri_shr,ri_reserve_amt,0) ;
                                      sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                                      sum_ri_share := sum_ri_share + nvl(w_ri_shr,0);
                                  end if;
                          elsif  ri_rec3.ri_type1 = '2'  then
                                  if  ri_rec3.ri_code = '999' and ri_rec3.ri_br_code = '99'  then
                                      ri_reserve_amt :=  floor(nvl(p_reserve_amt,0)) - sum_ri_reserve_amt;
                                      w_ri_shr          :=  100 - sum_ri_share;
                                      ri_reserve_amt := nvl(ri_reserve_amt,0) + nvl(frac,0) ;
                                  else
                                      if  nvl(p_tot_sum_ins,0) > 0  then
                                          w_ri_shr := round((ri_rec3.ri_sum / p_tot_sum_ins) * 100,5);
                                      else
                                          w_ri_shr := round((nvl(ri_rec3.ri_share,0) / nvl(p_sum_shr,1)) * 100,5);
                                      end if;
                                      ri_reserve_amt  := round((floor(nvl(p_reserve_amt,0)) * w_ri_shr)/100,4);
                                  end if;
                                  NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,w_ri_shr,ri_reserve_amt,0) ;
                                  sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                                  sum_ri_share := sum_ri_share + nvl(w_ri_shr,0);
                          end if;
                     END LOOP;
                     if  nvl(sum_ri_reserve_amt_nat_cat,0) > 0  then
                         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '93', '00', 'N', sum_ri_share_nat_cat, sum_ri_reserve_amt_nat_cat, 0) ;
                     end if;
                 end if;
              --   Begin
              --       if  sum_ri_share <> 100 or nvl(sum_ri_reserve_amt,0) <> nvl(p_reserve_amt,0)  then
              --           p_message := 'R/I %Share is not equal to 100% or Sum of R/I Reserve Amount is not equal to Reserve Amount';
              --       end if;
              --  end;
             else
                    p_message := 'Due to reinsurance allocation is incomplete - please contact U/W';
             end if;
            end if;
    elsif  p_prod_grp  in  ('1')   then
            Begin
               select  catas_code                                          --    varit  26-jan-16
                  into  v_catas_code                                       --    varit  26-jan-16
                from  nc_mas                                                --    varit  26-jan-16
              where  sts_key = p_sts_key ;                            --    varit  26-jan-16
            Exception                                                           --    varit  26-jan-16
               when  no_data_found  then                               --    varit  26-jan-16
                         v_catas_code := null;                              --    varit  26-jan-16
               when  others   then                                           --    varit  26-jan-16
                         v_catas_code := null;                              --    varit  26-jan-16
            End;                                                                   --    varit  26-jan-16
            p_chk_re := 'Y';                                                   --   varit  17-mar-16
            Begin
                select ri_code
                   into w_ri_code
                 from  fir_reinsurance
              where pol_no = p_pol_no
                 and  pol_run = p_pol_run
                 and  ri_section = 1
                 and  ri_code = '915'
                 and  nvl(ri_share,0) > 0
                 and  end_seq <= (select max(a.end_seq) from fir_reinsurance a
                                           where a.pol_no  =  p_pol_no
                                             and  a.pol_run =  p_pol_run
                                             and  a.end_seq <= p_end_seq ) ;
             exception
                when  no_data_found  then
                          p_chk_re := 'N';         ---  no data ri_code = 915 then normal reinsurance
                when  others  then
                          p_chk_re := 'Y';
             end;

            if  v_catas_code is not null    then
                begin
                  select nat_peril_flag
                     into v_nat_peril_flag
                   from clm_cause_std
                where cause_code = p_cause_code
                   and cause_seq  = p_cause_seq;
                exception
                   when others then
                           v_nat_peril_flag  := null;
                end;
                if   v_nat_peril_flag = 'Y'  then
                    ri_reserve_amt :=  nvl(p_reserve_amt,0);
                    ri_share           :=  100;
                    sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                    sum_ri_share := sum_ri_share + nvl(ri_share,0);
                    NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, '999', '93', 'N', '2', '00', ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                    if  p_cashcall = 'Y'   then
                       NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                   end if;
                   NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '93', '00', 'N', ri_share, ri_reserve_amt,0) ;
                else
                   NMTR_PACKAGE.nc_fire_catas_reinsurance (p_pol_no, p_pol_run, p_end_seq, p_loc_seq, p_loss_date, p_block, c8, p_message );
                   LOOP
                      FETCH  c8  INTO ri_rec8;
                      EXIT WHEN c8%NOTFOUND;
                          ri_reserve_amt  := Round((nvl(p_reserve_amt,0) * ri_rec8.ri_share)/100,2);
                          if  ri_rec8.ri_type1 = '1'  then
                              NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec8.ri_code, ri_rec8.ri_br_code, ri_rec8.lf_flag, ri_rec8.ri_type1, ri_rec8.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                              p_pla_no := null;
                              if  p_cashcall = 'Y'   then
                                  NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                              end if;
                          end if;
                          NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec8.ri_type1,ri_rec8.ri_code,ri_rec8.ri_br_code,ri_rec8.ri_type2,ri_rec8.lf_flag,ri_rec8.ri_share,ri_reserve_amt,0) ;
                          sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                          sum_ri_share := sum_ri_share + nvl(ri_rec8.ri_share,0);
                   END LOOP;
                end if;
            elsif  p_prod_type not in ('112','113')  and  p_pol_yr <  '2012'   then
                NMTR_PACKAGE.nc_fire_fac_reinsurance (p_pol_no, p_pol_run, p_end_seq, p_loc_seq, p_loss_date, p_block, c3, p_message );
                frac := nvl(p_reserve_amt,0) - floor(nvl(p_reserve_amt,0));
                LOOP
                   FETCH  c3  INTO ri_rec3;
                   EXIT WHEN c3%NOTFOUND;
                       ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_rec3.ri_share)/100,2);
                       NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                       NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec3.ri_code, ri_rec3.ri_br_code, ri_rec3.lf_flag, ri_rec3.ri_type1, ri_rec3.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                       NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec3.ri_type1,ri_rec3.ri_code,ri_rec3.ri_br_code,ri_rec3.ri_type2,ri_rec3.lf_flag,ri_rec3.ri_share,ri_reserve_amt,0) ;
                       sum_ri_fac       :=  sum_ri_fac + nvl(ri_reserve_amt,0);
                       sum_shr_fac    :=   sum_shr_fac + nvl(ri_rec3.ri_share,0);
                       sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                       sum_ri_share := sum_ri_share + nvl(ri_rec3.ri_share,0);
                END LOOP;
                NMTR_PACKAGE.nc_get_block_limit (p_block, p_block_limit, p_fqs_limit);
                p_balance := floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_fac,0);
            elsif  p_prod_type in ('112','113') or  (p_prod_type not in ('112','113')  and  p_pol_yr >=  '2012')  or  p_chk_re = 'N'   then                            -- varit  9-feb-16
                   NMTR_PACKAGE.nc_fire_all_reinsurance (p_pol_no, p_pol_run, p_end_seq, p_loc_seq, p_loss_date, p_block, c7, p_message );
                   frac := nvl(p_reserve_amt,0) - floor(nvl(p_reserve_amt,0));
                LOOP
                   FETCH  c7  INTO ri_rec7;
                   EXIT WHEN c7%NOTFOUND;
                       ri_reserve_amt  := Round((floor(nvl(p_reserve_amt,0)) * ri_rec7.ri_share)/100,2);
                       if  ri_rec7.ri_type1 = '0'  then
                           NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                       else
                           NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, ri_rec7.ri_code, ri_rec7.ri_br_code, ri_rec7.lf_flag, ri_rec7.ri_type1, ri_rec7.ri_type2, ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                           p_pla_no := null;
                           if  p_cashcall = 'Y'   then
                               NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                           end if;
                       end if;
                       NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, ri_rec7.ri_type1,ri_rec7.ri_code,ri_rec7.ri_br_code,ri_rec7.ri_type2,ri_rec7.lf_flag,ri_rec7.ri_share,ri_reserve_amt,0) ;
                       sum_ri_fac       :=  sum_ri_fac + nvl(ri_reserve_amt,0);
                       sum_shr_fac    :=   sum_shr_fac + nvl(ri_rec7.ri_share,0);
                       sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                       sum_ri_share := sum_ri_share + nvl(ri_rec7.ri_share,0);
                END LOOP;
                NMTR_PACKAGE.nc_get_block_limit (p_block, p_block_limit, p_fqs_limit);
                p_balance := floor(nvl(p_reserve_amt,0)) - nvl(sum_ri_fac,0);
            end if;
            if   v_catas_code is null    then
       --      if  p_prod_type in ('112','113')   then                                                                                                                                                                                                              varit  9-feb-16
       --          NMTR_PACKAGE.nc_block_reloss_fire (p_loss_date, p_pol_no, p_pol_run, p_block, p_channel, p_first, p_second, p_mfp, p_fpre, p_frqs, p_ret, p_tgr, p_sum_ins);
       --          NMTR_PACKAGE.nc_insert_fir_block_reloss_tmp (p_pol_no, p_sts_key, p_block, p_block_limit, p_first, p_second, p_fpre, p_ret, p_mfp, p_frqs, p_tgr, p_sum_ins, p_pol_run, p_fqs_limit, 0, 0);
       --          ri_reserve_amt_ret :=  nvl(p_reserve_amt,0) - nvl(sum_ri_reserve_amt,0);
       --          ri_share_ret  := 100 - nvl(sum_ri_share,0);
       --          sum_ri_reserve_amt := sum_ri_reserve_amt + ri_reserve_amt_ret;
       --          sum_ri_share := sum_ri_share + ri_share_ret;
       --          NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '99', '00', 'N', ri_share_ret, ri_reserve_amt_ret,0 ) ;
               if  p_prod_type not in ('112','113')  and  p_pol_yr <  '2012'   then
                     NMTR_PACKAGE.nc_block_reloss_fire (p_loss_date, p_pol_no, p_pol_run, p_block, p_channel, p_first, p_second, p_mfp, p_fpre, p_frqs, p_ret, p_tgr, p_sum_ins);
                     NMTR_PACKAGE.nc_insert_fir_block_reloss_tmp (p_pol_no, p_sts_key, p_block, p_block_limit, p_first, p_second, p_fpre, p_ret, p_mfp, p_frqs, p_tgr, p_sum_ins, p_pol_run, p_fqs_limit, 0, 0);
                     if  nvl(p_mfp,0)  > 0  then
                         NMTR_PACKAGE.nc_fire_trty_reinsurance (p_mfp, p_balance, p_reserve_amt, p_tgr, ri_share, ri_reserve_amt);
                         NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, '367', '00', 'L', '1', '06', ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                         p_pla_no := null;
                         if  p_cashcall = 'Y'   then
                             NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                         end if;
                         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, '1', '367', '00', '06', 'L', ri_share, ri_reserve_amt,0) ;
                         sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                         sum_ri_share := sum_ri_share + nvl(ri_share,0);
                     end if;
                     if  nvl(p_first,0)  > 0  then
                         NMTR_PACKAGE.nc_fire_trty_reinsurance (p_first, p_balance, p_reserve_amt, p_tgr, ri_share, ri_reserve_amt);
                         NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, '911', '00', 'N', '1', '00', ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                         p_pla_no := null;
                         if  p_cashcall = 'Y'   then
                             NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                         end if;
                         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, '1', '911', '00', '00', 'N', ri_share, ri_reserve_amt,0) ;
                         sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                         sum_ri_share := sum_ri_share + nvl(ri_share,0);
                     end if;
                     if  nvl(p_second,0)  > 0  then
                         NMTR_PACKAGE.nc_fire_trty_reinsurance (p_second, p_balance, p_reserve_amt, p_tgr, ri_share, ri_reserve_amt);
                         NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, '912', '00', 'N', '1', '01', ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                         p_pla_no := null;
                         if  p_cashcall = 'Y'   then
                             NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                         end if;
                         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, '1', '912', '00', '01', 'N', ri_share, ri_reserve_amt,0) ;
                         sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                         sum_ri_share := sum_ri_share + nvl(ri_share,0);
                     end if;
                     if  nvl(p_frqs,0)  > 0  then
                         NMTR_PACKAGE.nc_fire_trty_reinsurance (p_frqs, p_balance, p_reserve_amt, p_tgr, ri_share, ri_reserve_amt);
                         NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, '913', '00', 'N', '1', '04', ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                         p_pla_no := null;
                         if  p_cashcall = 'Y'   then
                             NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                         end if;
                         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, '1', '913', '00', '04', 'N', ri_share, ri_reserve_amt,0) ;
                         sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                         sum_ri_share := sum_ri_share + nvl(ri_share,0);
                     end if;
                     if  nvl(p_fpre,0)  > 0  then
                         if  nvl(p_ret,0) = 0  then
                             ri_reserve_amt_fpre :=  nvl(p_reserve_amt,0) - nvl(sum_ri_reserve_amt,0);
                             ri_share_fpre  := 100 - nvl(sum_ri_share,0);
                             sum_ri_reserve_amt := sum_ri_reserve_amt + ri_reserve_amt_fpre;
                             sum_ri_share := sum_ri_share + ri_share_fpre;
                             NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '98', '01', 'N', ri_share_fpre, ri_reserve_amt_fpre,0) ;
                         else
                             NMTR_PACKAGE.nc_fire_trty_reinsurance (p_fpre, p_balance, p_reserve_amt, p_tgr, ri_share, ri_reserve_amt);
                             sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                             sum_ri_share := sum_ri_share + nvl(ri_share,0);
                             NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '98', '01', 'N', ri_share, ri_reserve_amt,0) ;
                         end if;
                     end if;
                     if  nvl(p_ret,0)  > 0  then
                         ri_reserve_amt_ret :=  nvl(p_reserve_amt,0) - nvl(sum_ri_reserve_amt,0);
                         ri_share_ret  := 100 - nvl(sum_ri_share,0);
                         sum_ri_reserve_amt := sum_ri_reserve_amt + ri_reserve_amt_ret;
                         sum_ri_share := sum_ri_share + ri_share_ret;
                         NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '99', '00', 'N', ri_share_ret, ri_reserve_amt_ret,0 ) ;
                     end if;
             elsif  p_prod_type not in ('112','113')  and  p_pol_yr >=  '2012'  and  p_chk_re = 'Y'  then
               NMTR_PACKAGE.nc_block_reloss_accum  (p_block, p_pol_no, p_pol_run, p_loss_date, 0, p_first, p_second, p_fpre, p_ret, p_fqs, p_ffs, p_sum_ins, p_tgr);
               NMTR_PACKAGE.nc_insert_fir_block_reloss_tmp (p_pol_no, p_sts_key, p_block, p_block_limit, p_first, p_second, p_fpre, p_ret, 0, 0, p_tgr, p_sum_ins, p_pol_run, p_fqs_limit, p_fqs, p_ffs);
          --     w_sum_block := nvl(p_fpre,0) + nvl(p_ret,0) + nvl(p_fqs,0) + nvl(p_ffs,0);                              varit  9-nov-15
                w_sum_block :=  nvl(p_fqs,0) + nvl(p_ffs,0);                                                                     --  varit  9-nov-15
                if  w_sum_block = 0  then
                         w_sum_block := 1;
                     end if;
               begin
                  select nat_peril_flag
                     into v_nat_peril_flag
                   from clm_cause_std
                where cause_code = p_cause_code
                   and cause_seq  = p_cause_seq;
               exception
                   when others then
                           v_nat_peril_flag  := null;
               end;
               if   v_nat_peril_flag = 'Y'  then
               --    if  nvl(p_fpre,0)  = 0  and nvl(p_ret,0) = 0  then                                                                                                                                varit  10-nov-15
               --         ri_reserve_amt :=  floor(nvl(p_reserve_amt,0)) - sum_ri_reserve_amt;                                                                                         varit  10-nov-15
               --         ri_share           :=  100 - sum_ri_share;                                                                                                                                     varit  10-nov-15
               --         ri_reserve_amt := nvl(ri_reserve_amt,0) + nvl(frac,0) ;                                                                                                               varit  10-nov-15
               --         sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);                                                                                         varit  10-nov-15
               --         sum_ri_share := sum_ri_share + nvl(ri_share,0);                                                                                                                       varit  10-nov-15
               --     else                                                                                                                                                                                            varit  10-nov-15
                 --       ri_share             :=  round(round(((nvl(p_fqs,0) + nvl(p_ffs,0)) / w_sum_block)*100,5)* round((100 - sum_shr_fac)/100,5));          varit  10-nov-15
               --        ri_share             :=  round(((nvl(p_fqs,0) + nvl(p_ffs,0)) / w_sum_block)*100,4)* round((100 - sum_shr_fac)/100,4);                      varit  10-nov-15
               --         ri_reserve_amt   :=  round((floor(nvl(p_reserve_amt,0))  * ri_share)/100,2);                                                                                varit  10-nov-15
               --         sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);                                                                                         varit  10-nov-15
               --         sum_ri_share := sum_ri_share + nvl(ri_share,0);                                                                                                                       varit  10-nov-15
               --     end if;                                                                                                                                                                                         varit  10-nov-15
                    ri_reserve_amt :=  floor(nvl(p_reserve_amt,0)) - sum_ri_reserve_amt;                                                                                          --  varit  10-nov-15
                    ri_share           :=  100 - sum_ri_share;                                                                                                                                       --  varit  10-nov-15
                    ri_reserve_amt := nvl(ri_reserve_amt,0) + nvl(frac,0) ;                                                                                                                 --  varit  10-nov-15
                    sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);                                                                                            --  varit  10-nov-15
                    sum_ri_share := sum_ri_share + nvl(ri_share,0);                                                                                                                          --  varit  10-nov-15
                    NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, '999', '93', 'N', '2', '00', ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                    if  p_cashcall = 'Y'   then
                       NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                   end if;
                   NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '93', '00', 'N', ri_share, ri_reserve_amt,0) ;
              else
               --    ri_share             :=  round(round((nvl(p_fqs,0)  / w_sum_block)*100,5)* round((100 - sum_shr_fac)/100,5));
               --    ri_reserve_amt   := round((floor(nvl(p_reserve_amt,0)) * ri_share)/100,2);
                   ri_share             :=  round((nvl(p_fqs,0)  / w_sum_block)*100,4)* round((100 - sum_shr_fac)/100,4);
                   ri_reserve_amt   := round((floor(nvl(p_reserve_amt,0)) * ri_share)/100,2);
                   NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, '915', '00', 'N', '1', '02', ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                   p_pla_no := null;
                   if  p_cashcall = 'Y'   then
                       NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                   end if;
                   NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, '1', '915', '00', '02', 'N', ri_share, ri_reserve_amt,0) ;
                   sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);
                   sum_ri_share := sum_ri_share + nvl(ri_share,0);
               --     if  nvl(p_fpre,0)  = 0  and nvl(p_ret,0) = 0  then                                                                                                         varit   10-nov-15
               --         ri_reserve_amt :=  floor(nvl(p_reserve_amt,0)) - sum_ri_reserve_amt;                                                                   varit  10-nov-15
               --         ri_share           :=  100 - sum_ri_share;                                                                                                                varit  10-nov-15
               --         ri_reserve_amt := nvl(ri_reserve_amt,0) + nvl(frac,0) ;                                                                                          varit  10-nov-15
               --         sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);                                                                    varit  10-nov-15
               --         sum_ri_share := sum_ri_share + nvl(ri_share,0);                                                                                                  varit  10-nov-15
               --     else                                                                                                                                                                       varit  10-nov-15
                   --     ri_share             :=  round(round((nvl(p_ffs,0)  / w_sum_block)*100,5)* round((100 - sum_shr_fac)/100,5));           varit  10-nov-15
                   --     ri_reserve_amt   := round((floor(nvl(p_reserve_amt,0))  * ri_share)/100,2);                                                           varit  10-nov-15
               --         ri_share             :=  round((nvl(p_ffs,0)  / w_sum_block)*100,5)* round((100 - sum_shr_fac)/100,5);                      varit  10-nov-15
               --         ri_reserve_amt   := round((floor(nvl(p_reserve_amt,0))  * ri_share)/100,2);                                                           varit  10-nov-15
               --         sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);                                                                    varit  10-nov-15
               --         sum_ri_share := sum_ri_share + nvl(ri_share,0);                                                                                                  varit  10-nov-15
               --     end if;
                   ri_reserve_amt :=  floor(nvl(p_reserve_amt,0)) - sum_ri_reserve_amt;                                                                   --     varit  10-nov-15
                   ri_share           :=  100 - sum_ri_share;                                                                                                                --    varit  10-nov-15
                   ri_reserve_amt := nvl(ri_reserve_amt,0) + nvl(frac,0) ;                                                                                          --    varit  10-nov-15
                   sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);                                                                     --    varit  10-nov-15
                   sum_ri_share := sum_ri_share + nvl(ri_share,0);                                                                                                   --    varit  10-nov-15                                                                                                                                               varit  10-nov-15
                   NMTR_PACKAGE.nc_get_cashcall (p_pol_yr, p_clm_yr, '915', '00', 'N', '1', '60', ri_reserve_amt, p_curr_rate, p_cashcall, p_lines);
                   p_pla_no := null;
                   if  p_cashcall = 'Y'   then
                       NMTR_PACKAGE.nc_get_pla_no (p_pla_no ,p_message );
                   end if;
                   NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, p_pla_no, p_cashcall, '1', '915', '00', '60', 'N', ri_share, ri_reserve_amt, p_lines) ;
              end if;

              Begin                                                                              --    varit  8-jan-16
                        select   ri_reserve_amt                                                  --    varit  8-jan-16
                           into   v_amt_quota                                                     --    varit  8-jan-16
                         from   nc_reinsurance_tmp                                           --    varit  8-jan-16
                       where   sts_key = p_sts_key                                           --    varit  8-jan-16
                          and    ri_code = '915'                                                  --    varit  8-jan-16
                          and    ri_br_code = '00'                                               --    varit  8-jan-16
                          and    lf_flag = 'N'                                                       --    varit  8-jan-16
                          and    ri_type1 = '1'                                                     --    varit  8-jan-16
                          and    ri_type2 = '02';                                                  --    varit  8-jan-16
                     Exception                                                                         --    varit  8-jan-16
                        when  no_data_found  then                                            --    varit  8-jan-16
                                  v_amt_quota := 0;                                               --    varit  8-jan-16
                        when  others   then                                                        --    varit  8-jan-16
                                  v_amt_quota := 0;                                               --    varit  8-jan-16
                     End;                                                                                 --    varit  8-jan-16

                      Begin                                                                              --    varit  8-jan-16
                        select   ri_reserve_amt, lines                                          --    varit  8-jan-16
                           into   v_amt_surplus, v_lines                                       --    varit  8-jan-16
                         from   nc_reinsurance_tmp                                           --    varit  8-jan-16
                       where   sts_key = p_sts_key                                           --    varit  8-jan-16
                          and    ri_code = '915'                                                  --    varit  8-jan-16
                          and    ri_br_code = '00'                                               --    varit  8-jan-16
                          and    lf_flag = 'N'                                                       --    varit  8-jan-16
                          and    ri_type1 = '1'                                                     --    varit  8-jan-16
                          and    ri_type2 = '60';                                                  --    varit  8-jan-16
                      Exception                                                                        --    varit  8-jan-16
                        when  no_data_found  then                                            --    varit  8-jan-16
                                  v_amt_surplus := 0;                                            --    varit  8-jan-16
                                  v_lines := 0;                                                       --    varit  8-jan-16
                        when  others   then                                                        --    varit  8-jan-16
                                  v_amt_surplus := 0;                                             --    varit  8-jan-16
                                  v_lines := 0;                                                        --    varit  8-jan-16
                      End;                                                                                --    varit  8-jan-16

                      if   (nvl(v_amt_quota,0) <= 0 and nvl(v_amt_surplus,0) > 0) or ((nvl(v_amt_quota,0) > 0 and nvl(v_amt_surplus,0) > 0)
                           and (nvl(v_amt_quota,0) * nvl(v_lines,0)  <  nvl(v_amt_surplus,0)))    then                                         --    varit  8-jan-16
                      --    Begin                                                                                                                                              --    varit  8-jan-16
                      --       delete from nc_reinsurance_tmp where sts_key = p_sts_key;                                                           --    varit  8-jan-16
                      --    Exception                                                                                                                                        --    varit  8-jan-16
                      --      when  OTHERS  then                                                                                                                     --    varit  8-jan-16
                      --      rollback;                                                                                                                                       --    varit  8-jan-16
                      --    End;                                                                                                                                                --    varit  8-jan-16
                      --    commit;                                                                                                                                           --    varit  8-jan-16
                      --    Begin                                                                                                                                               --    varit  8-jan-16
                      --       delete from nc_fir_block_reloss_tmp where sts_key = p_sts_key;                                                       --    varit  8-jan-16
                      --    Exception                                                                                                                                          --    varit  8-jan-16
                      --       when  OTHERS  then                                                                                                                      --    varit  8-jan-16
                      --       rollback;                                                                                                                                        --    varit  8-jan-16
                      --    End;                                                                                                                                                 --    varit  8-jan-16
                      --    commit;                                                                                                                                            --    varit  8-jan-16
                          p_message := 'Due to Quota Share is less than No. of lines of First Surplus - Please contact U/W';      --    varit  8-jan-16
                     end if;                                                                                                                                                    --    varit  8-jan-16

          --    if  nvl(p_fpre,0)  > 0  then                                                                                                                                                                         varit  10-nov-15
          --           if  nvl(p_ret,0) = 0  then                                                                                                                                                                     varit  10-nov-15
          --             ri_reserve_amt_fpre :=  nvl(p_reserve_amt,0) - nvl(sum_ri_reserve_amt,0);                                                                                        varit  10-nov-15
          --             ri_share_fpre  := 100 - nvl(sum_ri_share,0);                                                                                                                                      varit  10-nov-15
          --             sum_ri_reserve_amt := sum_ri_reserve_amt + ri_reserve_amt_fpre;                                                                                                   varit  10-nov-15
          --             sum_ri_share := sum_ri_share + ri_share_fpre;                                                                                                                                 varit  10-nov-15
          --             NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '98', '01', 'N', ri_share_fpre, ri_reserve_amt_fpre) ;               varit  10-nov-15
          --         else                                                                                                                                                                                                     varit  10-nov-15
          --              NMTR_PACKAGE.nc_fire_trty_reinsurance (p_fpre, p_balance, p_reserve_amt, p_tgr, ri_share, ri_reserve_amt);                                      varit  10-nov-15
          --              sum_ri_reserve_amt := sum_ri_reserve_amt + nvl(ri_reserve_amt,0);                                                                                                 varit  10-nov-15
          --              sum_ri_share := sum_ri_share + nvl(ri_share,0);                                                                                                                               varit  10-nov-15
          --              NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '98', '01', 'N', ri_share, ri_reserve_amt) ;                              varit  10-nov-15
          --         end if;                                                                                                                                                                                                  varit  10-nov-15
          --    end if;                                                                                                                                                                                                       varit  10-nov-15
          --    if  nvl(p_ret,0)  > 0  then                                                                                                                                                                             varit  10-nov15
          --        ri_reserve_amt_ret :=  nvl(p_reserve_amt,0) - nvl(sum_ri_reserve_amt,0);                                                                                                varit  10-nov-15
          --        ri_share_ret  := 100 - nvl(sum_ri_share,0);                                                                                                                                              varit  10-nov-15
          --        sum_ri_reserve_amt := sum_ri_reserve_amt + ri_reserve_amt_ret;                                                                                                           varit  10-nov-15
          --        sum_ri_share := sum_ri_share + ri_share_ret;                                                                                                                                         varit  10-nov-15
          --        NMTR_PACKAGE.nc_insert_reinsurance_tmp (p_sts_key, null, null, '2', '999', '99', '00', 'N', ri_share_ret, ri_reserve_amt_ret ) ;                        varit  10-nov-15
          --    end if;                                                                                                                                                                                                       varit  10-nov-15
             end if;
         end if;
        Begin
               if  round(sum_ri_share,3)  <  99.98  or  round(sum_ri_share,3)  > 100.02   then   --  or nvl(sum_ri_reserve_amt,0) <> nvl(p_reserve_amt,0)  then
                   p_message := 'R/I %Share is not equal to 100% or Sum of R/I Reserve Amount is not equal to Reserve Amount';
               end if;
        end;
    end if;
  end if;
    Begin
     OPEN p_re_cursor FOR
        select  pla_no,cashcall,ri_code||ri_br_code||lf_flag||ri_type1||ri_type2 re_code,
                  NMTR_PACKAGE.nc_get_ri_name (ri_code,ri_br_code) "ri_name",
                  ri_share,ri_reserve_amt
        from  nc_reinsurance_tmp
        where  sts_key = p_sts_key;
    End;
END;

FUNCTION nc_get_hide_flag(i_no IN VARCHAR2, i_run IN NUMBER, i_end_seq IN NUMBER)   RETURN VARCHAR2 IS
                 v_hide_flag   varchar2(2) := null;
BEGIN
  Begin
    SELECT hide_flag
       INTO  v_hide_flag
      FROM mis_mas
    WHERE pol_no = i_no
        AND pol_run = i_run
        AND end_seq = i_end_seq;
  Exception
       when others then
                v_hide_flag := null;
  End;
  RETURN (v_hide_flag);
END nc_get_hide_flag;

FUNCTION GET_ABBNAME(V_USERID IN VARCHAR2) RETURN VARCHAR2 IS
    v_abb   varchar2(10);
BEGIN
    select abb_name_eng into v_abb
    from position_grp_std a
    where a.position_grp_id in (
    select position_grp_id 
    from bkiuser
    where user_id = V_USERID
    );
    return v_abb;
Exception
    when no_data_found then
        return null;
    when others then
        return null;
END GET_ABBNAME;

END NMTR_PACKAGE;
/

