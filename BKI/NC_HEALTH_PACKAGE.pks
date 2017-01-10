CREATE OR REPLACE PACKAGE ALLCLM.NC_HEALTH_PACKAGE IS

  TYPE v_ref_cursor1 IS REF CURSOR;
  TYPE v_ref_cursor2 IS REF CURSOR;
  TYPE v_ref_cursor3 IS REF CURSOR;
  TYPE v_ref_cursor4 IS REF CURSOR;
  TYPE cur_typ IS REF CURSOR;
     
  PROCEDURE generate_email(v_from IN VARCHAR2 ,v_to IN VARCHAR2 ,v_subject IN VARCHAR2 ,v_body IN VARCHAR2 ,v_cc IN VARCHAR2 ,v_bcc IN VARCHAR2 ) ;
  
  PROCEDURE email_pack_error(v_subject IN VARCHAR2 , v_body IN VARCHAR2);
  
  PROCEDURE email_notice_bancas(v_subject IN VARCHAR2 , v_body IN VARCHAR2); 
    
  PROCEDURE list_med(P_MED OUT v_ref_cursor2) ; -- ������ҧ����� Dynamic SQL 
  
  PROCEDURE test_incursor(IN_C in v_ref_cursor1) ; 
  
  FUNCTION LIST_MED_HOSPITAL(P_HOSP OUT v_ref_cursor1) RETURN VARCHAR2 ;

  FUNCTION GET_BKI_FAXCLM(vKey IN NUMBER, P_CLM_MAS OUT v_ref_cursor1 ,P_CLM_DETAIL OUT v_ref_cursor2 ,
                            RST OUT VARCHAR2)  RETURN VARCHAR2;  -- Y = ������ͧ N = ��������ͧ , E = ��辺�������� 
                            
  FUNCTION GET_BKI_HPTCODE(xCode IN VARCHAR2) RETURN VARCHAR2;
  
  PROCEDURE GET_CUSTOMER_NAME(vcust_code IN VARCHAR2 , vTH_ENG IN VARCHAR2 ,vTITLE OUT VARCHAR2 ,vNAME  OUT VARCHAR2 ,vSURNAME  OUT VARCHAR2  ) ;                            

  FUNCTION UPDATE_BKI_FAXCLM (vKey IN NUMBER ,BKI_CLMNO IN VARCHAR2  ,RST OUT VARCHAR2) RETURN VARCHAR2;
  
  FUNCTION UPDATE_TPA_FAXCLM (vKey IN NUMBER ,OST_CLMNO IN VARCHAR2  ,RST OUT VARCHAR2) RETURN VARCHAR2;
  
  FUNCTION UPDATE_TPA_FAXCLM (vKey IN NUMBER  ,RST OUT VARCHAR2) RETURN VARCHAR2;
    
  FUNCTION GET_TPA_FAXCLM (vKey IN NUMBER  ,RST OUT VARCHAR2) RETURN VARCHAR2;
  
  FUNCTION GET_FINANCE_STATUS(v_POLICY IN VARCHAR2,
                                                        v_LOSSDATE IN VARCHAR2,
                            RST OUT VARCHAR2)  RETURN VARCHAR2; -- Y = ������ͧ N = ��������ͧ

  FUNCTION GET_HISTORY_CLM_BY_POL(vPOLICY IN VARCHAR2,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_CLM_MAS OUT v_ref_cursor1 ,P_CLM_DETAIL OUT v_ref_cursor2 ,
                            RST OUT VARCHAR2)  RETURN VARCHAR2; -- Y = ������ͧ N = ��������ͧ , E = ��辺�������� , M = many  Policy ;      
                            
  FUNCTION GET_POLICY_BY_POL(vPOLICY IN VARCHAR2 ,vLOSS_DATE IN VARCHAR2 ,vRecpt IN VARCHAR2 ,vFLEET IN VARCHAR2 ,vFlag IN VARCHAR2 ,rSID OUT NUMBER) RETURN VARCHAR2; -- Y = ������ͧ N = ��������ͧ , E = ��辺�������� , M = many  Policy 

  FUNCTION GET_POLICY_BY_ID(vIDNO IN VARCHAR2 ,vLOSS_DATE IN VARCHAR2 ,vFlag IN VARCHAR2 ,rSID OUT NUMBER) RETURN VARCHAR2; -- Y = ������ͧ N = ��������ͧ , E = ��辺�������� , M = many  Policy 

  FUNCTION GET_POLICY_BANCAS(vIDNO IN VARCHAR2 ,vLOSS_DATE IN VARCHAR2 ,rSID OUT NUMBER) RETURN VARCHAR2; -- Y = ������ͧ N = ��������ͧ , E = ��辺�������� , M = many  Policy 

  FUNCTION CHECK_POLICY_MAIN(vPOLICY IN VARCHAR2 ,vLOSS_DATE IN VARCHAR2 ,vRecpt IN VARCHAR2 ,vFLEET IN VARCHAR2  ,vIDNO IN VARCHAR2   ,P_POLICY OUT v_ref_cursor1 ,P_COVER OUT v_ref_cursor2 ,RST OUT VARCHAR2) RETURN VARCHAR2;  -- Y = ������ͧ N = ��������ͧ , E = ��辺��������
  
  FUNCTION CHECK_POLICY_COVER(vPOLICY IN VARCHAR2 ,vLOSS_DATE IN VARCHAR2 ,vRecpt IN VARCHAR2 ,vFLEET IN VARCHAR2  ,vIDNO IN VARCHAR2  ,RST OUT VARCHAR2) RETURN VARCHAR2;  -- Y = ������ͧ N = ��������ͧ , E = ��辺��������
  -- ,vRecpt =X ��������� recpt_seq ,fleet_seq = 0 �������к� fleet
  
  FUNCTION GET_NOTICE_DATA(vSTS_KEY IN NUMBER, vHPT_CODE IN VARCHAR2 ,P_NOTICE_DATA OUT v_ref_cursor4) RETURN VARCHAR2;  -- 0 Complete , 5 Error or not found
    
  FUNCTION CHECK_NOTICE_DATA(vSTS_KEY IN NUMBER, vHPT_CODE IN VARCHAR2) RETURN VARCHAR2 ;    
  
  FUNCTION GET_MED_REMARK(vSTS_KEY IN NUMBER,vTYPE  IN VARCHAR2) RETURN VARCHAR2 ;    -- vTYPE  D = Disapprove Remark
  
  FUNCTION GET_LIST_CLM_ORDERBY(P_ORDERBY_LIST OUT v_ref_cursor4 ) RETURN VARCHAR2;  -- 0 Complete , 5 Error or not found
  
  FUNCTION GET_HOSPITAL_LIST(vName IN VARCHAR2 ,P_HOSP_LIST OUT v_ref_cursor4 ) RETURN VARCHAR2;  -- 0 Complete , 5 Error or not found
  
  FUNCTION GET_HOSPITAL_NAME(vPAYEECODE IN VARCHAR2  ,vTH_ENG IN VARCHAR2 ,vHPTCODE IN VARCHAR2 default null) RETURN VARCHAR2; --vTH_ENG =T, E

  FUNCTION GET_HOSPITAL_PAYEE(vHPTCODE IN VARCHAR2 , vHPTUSER IN VARCHAR2 default null) RETURN VARCHAR2; 

  FUNCTION get_new_benefit_code(i_bene_code IN VARCHAR2,i_th_eng  IN VARCHAR2) RETURN VARCHAR2 ;  
  
  FUNCTION get_benefit_descr(i_bene_code IN VARCHAR2,i_th_eng  IN VARCHAR2) RETURN VARCHAR2 ;    

  FUNCTION CONVERT_CLM_STATUS(vSTATUS IN VARCHAR2) RETURN VARCHAR2;

  FUNCTION GET_P_APPRV_FLAG(vSTS_KEY IN NUMBER, vPAY_NO IN VARCHAR2) RETURN VARCHAR2;
    
  FUNCTION GET_CLM_STATUS(vSTS_KEY IN NUMBER) RETURN VARCHAR2;
  
  FUNCTION GET_CLM_STATUS(vCLM_NO IN VARCHAR2) RETURN VARCHAR2;
  
  FUNCTION GET_CLM_STATUS_DESC(MED_STS IN VARCHAR2 ,SIDE IN NUMBER) RETURN VARCHAR2;  -- side 0 = BKI ,1 = HPT 

  FUNCTION IS_EXISTING_STSKEY(vSTS_KEY IN NUMBER) RETURN BOOLEAN; -- �� key ��к������ѧ

  FUNCTION IS_EXISTING_NOTICE(vSTS_KEY IN NUMBER, vHPT_CODE IN VARCHAR2) RETURN BOOLEAN; -- ����¡�ù�����Ѻ��������� 

  FUNCTION IS_EXISTING_CLAIM(vSTS_KEY IN NUMBER) RETURN VARCHAR2; -- �ա�úѹ�֡�������������� (��ͧ�ѹ��á� back �����Դ������)
    
  FUNCTION IS_NOT_EXPIRED_NOTICE(vSTS_KEY IN NUMBER, vHPT_CODE IN VARCHAR2) RETURN BOOLEAN;  -- �Ţ�Ѻ���������������� 3 �ѹ
      
  FUNCTION IS_CHECK_ACCUM(P_PREMCODE IN VARCHAR2) RETURN BOOLEAN;
  
  FUNCTION IS_CHECK_PERTIME(P_PREMCODE IN VARCHAR2) RETURN BOOLEAN;  
  
  FUNCTION IS_CHECK_TOTLOSS(P_PREMCODE IN VARCHAR2) RETURN BOOLEAN;    

  FUNCTION IS_CHECK_MOTORCYCLE(P_PREMCODE IN VARCHAR2) RETURN BOOLEAN;    
    
  FUNCTION GET_MAXDAY(P_PREMCODE IN VARCHAR2) RETURN NUMBER;    
  
  FUNCTION GEN_STSKEY(PROD_TYPE IN VARCHAR2) RETURN NUMBER ;
  
  FUNCTION GEN_SID RETURN NUMBER ;  
  
  FUNCTION GEN_CLMNO(v_PROD_TYPE IN VARCHAR2 ,v_CHANNEL IN VARCHAR2) RETURN VARCHAR2;  

  FUNCTION GEN_CLMNO(v_PROD_TYPE IN VARCHAR2 ,v_CHANNEL IN VARCHAR2 ,v_Branch IN VARCHAR2) RETURN VARCHAR2;  
  
  FUNCTION GEN_PAYNO(v_PROD_TYPE IN VARCHAR2 ) RETURN VARCHAR2;  
    
  FUNCTION GEN_LETTNO(v_PROD_TYPE IN VARCHAR2 ) RETURN VARCHAR2;    
  
  FUNCTION GEN_LETTNO(v_PROD_TYPE IN VARCHAR2 ,V_KEY IN VARCHAR2) RETURN VARCHAR2;     

  FUNCTION GEN_xRUNNO(v_PROD IN VARCHAR2 ,V_KEY IN VARCHAR2) RETURN VARCHAR2; 
    
  FUNCTION GEN_MEDREFNO(V_GROUP IN VARCHAR2 /* 000 �.�. 001 broker*/ ) RETURN VARCHAR2;      
  
  FUNCTION GET_ACCUM_AMT(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_PREMCODE IN VARCHAR2,
                                                         P_LOSS_DATE IN DATE) RETURN NUMBER;

  FUNCTION GET_ACCUM_AMT(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_PREMCODE IN VARCHAR2,
                                                        P_LOSS_DATE IN DATE,
                                                        P_CLMNO IN VARCHAR2 ) RETURN NUMBER;
                                                        
  FUNCTION GET_ACCUM_AMT2(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_PREMCODE IN VARCHAR2,
                                                        P_LOSS_DATE IN DATE,
                                                        P_CLMNO IN VARCHAR2 ) RETURN NUMBER;                                                        
                                                         
  FUNCTION GET_RI_RES(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_RECPT_SEQ IN NUMBER,
                                                        P_LOC_SEQ IN NUMBER,
                                                        P_LOSS_DATE IN DATE,
                                                        P_END_SEQ IN NUMBER,
                                                        P_CRI_RES OUT v_ref_cursor4 ) RETURN NUMBER;      
                                                        
    FUNCTION GET_PREMCODE_DESCR(v_prem in varchar2 ,v_th_eng in VARCHAR2) RETURN VARCHAR2;        
    
    FUNCTION RI_NAME ( In_ri_code VARCHAR2,
                       In_ri_br_code VARCHAR2  ) RETURN varchar2   ;                 
                       
    FUNCTION UPDATE_SEARCH_NAME(in_name IN varchar2) RETURN varchar2 ;                                               

    FUNCTION GET_ACR_PAIDDATE(vCLMNo IN VARCHAR2) RETURN DATE ;  -- call ACR Package for query Paid Amount and transfer status

    FUNCTION GET_ACR_PAIDAMT(vCLMNo IN VARCHAR2) RETURN NUMBER ;  -- call ACR Package for query Paid Amount and transfer status

    FUNCTION GET_BATCHNO(vCLMNo IN VARCHAR2) RETURN VARCHAR2 ;  -- query BATCH_NO 
    
    FUNCTION GET_BILLDATE(vCLMNo IN VARCHAR2) RETURN DATE ;  -- call ACR Package for query Paid Amount and transfer status    
    
     FUNCTION GET_BKI_CLMUSER(vCLMNo IN VARCHAR2 ,OUTTYPE IN NUMBER) RETURN VARCHAR2 ; -- outtype:: 0 = name ,1 = user_id ,2 = user_id + name
             
    PROCEDURE WRITE_LOG  ( V_USER in  VARCHAR2 ,V_USER_NAME in VARCHAR2 ,V_LOG_TEXT in VARCHAR2 ,
                                  V_RST  OUT VARCHAR2)  ;
                                  
    PROCEDURE WRITE_LOG  ( V_USER in  VARCHAR2 ,V_USER_NAME in VARCHAR2 ,V_FUNC IN VARCHAR2 ,V_LOG_TEXT in VARCHAR2 ,
                                  V_RST  OUT VARCHAR2)  ;                                  
                                                                                       
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
                              RST                       OUT VARCHAR2);

  PROCEDURE GET_SINGLE_CLM_DATA(V_STSKEY NUMBER, V_CLM_NO VARCHAR2,
                            P_MASTER_DATA  OUT v_ref_cursor1 ,P_DETAIL_DATA  OUT v_ref_cursor2 ,
                            P_COVERAGE_DATA  OUT v_ref_cursor3 ,
                            RST OUT VARCHAR2);  --RST null ��������                            

  PROCEDURE GET_SINGLE_CLM_DATA_BANCAS(V_STSKEY NUMBER, V_CLM_NO VARCHAR2,
                            P_MASTER_DATA  OUT v_ref_cursor1 ,P_DETAIL_DATA  OUT v_ref_cursor2 ,
                            P_COVERAGE_DATA  OUT v_ref_cursor3 ,
                            RST OUT VARCHAR2);  --RST null ��������
                            
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
                              RST                       OUT VARCHAR2);

  PROCEDURE GET_SINGLE_CLM_DATA_BROK(V_STSKEY NUMBER, V_CLM_NO VARCHAR2,
                            P_MASTER_DATA  OUT v_ref_cursor1 ,P_DETAIL_DATA  OUT v_ref_cursor2 ,
                            P_COVERAGE_DATA  OUT v_ref_cursor3 ,
                            RST OUT VARCHAR2);  --RST null ��������         
        

  FUNCTION GET_LIST_CLM_ORDERBY_BROK(P_ORDERBY_LIST OUT v_ref_cursor4 ) RETURN VARCHAR2;  -- 0 Complete , 5 Error or not found
 
                                                          
  PROCEDURE GET_COVER_PA(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_PREMCODE IN VARCHAR2, -- null ��ʹ֧������ 
                            P_COVER_PA  OUT v_ref_cursor1 ,RST OUT VARCHAR2);

  PROCEDURE GET_COVER_PA(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_RECPT_SEQ IN NUMBER,
                                                        P_PREMCODE IN VARCHAR2, -- null ��ʹ֧������ 
                            P_COVER_PA  OUT v_ref_cursor1 ,RST OUT VARCHAR2);

  PROCEDURE GET_COVER_PA(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_RECPT_SEQ IN NUMBER,
                                                        P_LOSSDATE IN DATE,
                                                        P_PREMCODE IN VARCHAR2, -- null ��ʹ֧������ 
                            P_COVER_PA  OUT v_ref_cursor1 ,RST OUT VARCHAR2);
                            
  PROCEDURE GET_COVER_PA_UNNAME(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_END_SEQ IN NUMBER, -- null �������͹Ҥ�
                                                        P_RECPT_SEQ IN NUMBER, -- null �������͹Ҥ�
                                                        P_GROUP_SEQ IN NUMBER, -- ��������� null ; �ó��ҡ���� 1 group �к� group ���� 
                                                        P_PREMCODE IN VARCHAR2, -- null ��ʹ֧������ 
                            P_COVER_PA  OUT v_ref_cursor1 ,RST OUT VARCHAR2);
                                                                                    
   PROCEDURE GET_MC_REMARK(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        RST OUT VARCHAR2); -- ������ͧ�غѵ��˵بҡ����䫴� ,��������ͧ�غѵ��˵بҡ����䫴�                            

   PROCEDURE GET_MC_REMARK(P_SQL IN VARCHAR2 ,
                                                        RST OUT VARCHAR2); -- ������ͧ�غѵ��˵بҡ����䫴� ,��������ͧ�غѵ��˵بҡ����䫴�                            
                            
  PROCEDURE GET_HISTORY_CLM(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                                                        P_LOSSDATE IN DATE, 
                            V_KEY OUT NUMBER) ;         
                            
  PROCEDURE GET_HISTORY_CLM2(P_POL_NO IN VARCHAR2,
                                                        P_POL_RUN IN NUMBER,
                                                        P_FLEET_SEQ IN NUMBER,
                            V_KEY OUT NUMBER) ;                                   
                            
  PROCEDURE REMOVE_HISTORY_CLM (V_KEY IN NUMBER) ;                                           

  PROCEDURE CHECK_LIMIT(POLICY_NO  IN  VARCHAR2 ,FLEET_SEQ IN  NUMBER , LOSSDATE IN   VARCHAR2, PREMCODE  IN  VARCHAR2,REQUEST_AMT IN NUMBER 
     ,REMAIN_AMT OUT NUMBER);            -- **New            
     
  PROCEDURE CHECK_LIMIT(POLICY_NO  IN  VARCHAR2 ,FLEET_SEQ IN  NUMBER  ,RECPT_SEQ IN  NUMBER , LOSSDATE IN   VARCHAR2, PREMCODE  IN  VARCHAR2,REQUEST_AMT IN NUMBER 
     ,REMAIN_AMT OUT NUMBER);            -- **New  add Recpt_seq                 
                                
  PROCEDURE CHECK_LIMIT(P_DATA  IN v_ref_cursor2  ,
                            P_CHK_LIMIT  OUT v_ref_cursor3 ,RST OUT VARCHAR2);       
                            
  PROCEDURE CHECK_LIMIT(POLICY_NO  IN  VARCHAR2 ,FLEET_SEQ IN  NUMBER , LOSSDATE IN   VARCHAR2, PREMCODE  IN  VARCHAR2,REQUEST_AMT IN NUMBER 
   , CLM_NO  IN  VARCHAR2  ,REMAIN_AMT OUT NUMBER);            -- **New         
   
  PROCEDURE CHECK_LIMIT(POLICY_NO  IN  VARCHAR2 ,FLEET_SEQ IN  NUMBER ,RECPT_SEQ IN  NUMBER , LOSSDATE IN   VARCHAR2, PREMCODE  IN  VARCHAR2,REQUEST_AMT IN NUMBER 
   , CLM_NO  IN  VARCHAR2  ,REMAIN_AMT OUT NUMBER);            -- **New   dd Recpt_seq                         

  PROCEDURE SAVE_STEP1(P_FAX IN VARCHAR2 ,vSTS_KEY IN NUMBER  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2);   -- Bypass CURSOR input
                                                        
  PROCEDURE SAVE_STEP1(P_FAX IN VARCHAR2 ,P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2);        
                            
  PROCEDURE SAVE_STEP2(vSTS_KEY IN NUMBER  ,
                            RST OUT VARCHAR2)       ;      -- RST = null ��� �����                
                            
  PROCEDURE SAVE_STEP2(P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2 ,
                             RST OUT VARCHAR2);  

  PROCEDURE SAVE_STEP3(vSID IN NUMBER  ,    -- �Ѻ�Ţ�����ش�ҹ������ҧ���
                            P_RST OUT  v_ref_cursor3)       ;      -- RST = null ��� �����  

  PROCEDURE SAVE_CANCEL(vSTS_KEY IN NUMBER  ,    
                            RST OUT VARCHAR2)       ;      -- RST = null ��� �����  
                            
  PROCEDURE SAVE_OPENBANCAS(P_FAX IN VARCHAR2 ,P_MASTER  IN VARCHAR2  ,P_DTL  IN VARCHAR2  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2);                                 
                                                                                                                
  PROCEDURE SAVE_REF_DATA(vSTS_KEY IN NUMBER  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2);   -- Record check coverage from Recieption              
                            
  PROCEDURE SAVE_UPDATE_CLAIM(P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2 , NEW_STS IN VARCHAR2, v_CLMNO IN VARCHAR2,
                             RST OUT VARCHAR2);       

  PROCEDURE SAVE_UPDATE_CLAIM2(P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2 , NEW_STS IN VARCHAR2, v_CLMNO IN VARCHAR2,
                             RST OUT VARCHAR2);    
                                                                                      
  PROCEDURE SAVE_NCMAS_HISTORY(vSTS_KEY IN NUMBER  ,
                            RST OUT VARCHAR2);   --���¡���͹�ѹ�֡ŧ NC_MAS �ء����  RST=null ��� �����                                                                             

  PROCEDURE SAVE_MEDPAYMENT_GROUP(vref_no IN varchar2 , vclm_no  IN varchar2 , vSTS_KEY IN NUMBER  ,vInvoice IN varchar2 ,vHpt_code IN varchar2 ,vRef_date IN DATE ,
                            RST OUT VARCHAR2);   --RST=null ��� �����                                                                             

  PROCEDURE SAVE_MEDPAYMENT_GROUP_SEQ(vref_no IN varchar2 , vclm_no  IN varchar2 , vSTS_KEY IN NUMBER  ,vInvoice IN varchar2 ,
                            RST OUT VARCHAR2);   --RST=null ��� ����� 

  PROCEDURE SAVE_BANCAS(P_FAX IN VARCHAR2 ,vSTS_KEY IN NUMBER  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2)       ;      -- RST = null ��� �����

  PROCEDURE UPDATE_BANCAS(P_FAX IN VARCHAR2 ,vSTS_KEY IN NUMBER  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2)       ;      -- RST = null ��� �����

  PROCEDURE UPDATE_STATUS_BANCAS(vSTS_KEY IN NUMBER  ,
                             RST OUT VARCHAR2)       ;      -- RST = null ��� �����
                                                        
  FUNCTION IS_BANCAS_CLAIM(vSTS_KEY IN NUMBER) RETURN BOOLEAN;                                          

  FUNCTION IS_UNNAME_POLICY(P_Pol_no IN VARCHAR2 ,P_Pol_run IN NUMBER) RETURN BOOLEAN;          
  
  PROCEDURE GET_UNNAME_GROUP(P_Pol_no IN VARCHAR2 ,P_Pol_run IN NUMBER  , P_End_seq IN NUMBER  , P_Recpt_seq IN NUMBER  ,
                             RST OUT VARCHAR2 ,group_count OUT NUMBER ,O_GROUP_MEMBER OUT  v_ref_cursor3 )       ;      -- RST = null ��� �����  

  PROCEDURE GET_UNNAME_STATUS(P_Pol_no IN VARCHAR2 ,P_Pol_run IN NUMBER  , P_LOSS_DATE IN DATE  ,
                             RST OUT VARCHAR2 )       ;      --  Y = ������ͧ  ,N =  ��������ͧ ,E = ���� ��Ǩ�ͺ

  PROCEDURE SAVE_UNNAME_CLAIM(P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2  ,
                            P_JOBNO  OUT v_ref_cursor3 ,RST OUT VARCHAR2) ;
                            
  PROCEDURE UPDATE_UNNAME_CLAIM(P_MASTER  IN v_ref_cursor1  ,P_DTL  IN v_ref_cursor2 ,
                             RST OUT VARCHAR2);   -- Clone from SAVE_STEP2                           
                                
  FUNCTION GET_LIST_DATE_TYPE(P_ORDERBY_LIST OUT v_ref_cursor4 ) RETURN VARCHAR2;  -- 0 Complete , 5 Error or not found

  FUNCTION IS_DISALLOW_POLICY(P_Pol_no IN VARCHAR2 ,P_Pol_run IN NUMBER) RETURN BOOLEAN; -- true = disallow ,error , fasle = allow

  FUNCTION IS_WATCHLIST_POLICY(P_Pol_no IN VARCHAR2 ,P_Pol_run IN NUMBER) RETURN BOOLEAN; -- true = disallow ,error , fasle = allow

  PROCEDURE GET_MED_REMARK(i_pol_no in varchar2 ,i_pol_run in number ,i_fleet_seq in number ,o_remark out varchar2) ;
  
END;
/

