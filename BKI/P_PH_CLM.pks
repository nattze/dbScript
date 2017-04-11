CREATE OR REPLACE PACKAGE P_PH_CLM AS
/******************************************************************************
   NAME:       P_PH_CLM
   PURPOSE:     ����Ѻ Projetc PH system
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        18/11/2016      2702       1. Created this package.
******************************************************************************/
    TYPE v_curr IS REF CURSOR;    
    
    FUNCTION PH_SIGNIN(v_user IN VARCHAR2 ,v_pass IN VARCHAR2) RETURN VARCHAR2 ; --Y ,N
    
    FUNCTION GEN_NOTEKEY RETURN NUMBER;    
    
    FUNCTION GET_CLMTYPE_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2; 
    
    FUNCTION GET_CLMSTS_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION GET_ADMISS_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION GET_BENE_DESCR(v_benecode IN VARCHAR2 ,v_lang IN VARCHAR2) RETURN VARCHAR2; --v_lang : T ,E
    
    FUNCTION GET_APPRVSTS_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION GET_HOSPITAL_NAME(v_code IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION GET_ICD10_DESCR(v_code IN VARCHAR2  ,v_lang IN VARCHAR2) RETURN VARCHAR2; --v_lang : T ,E
    
    FUNCTION GET_PAIDBY_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION GET_BANK_BRNAME(v_bank IN VARCHAR2 ,v_branch IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION MAPP_BENECODE(v_bill IN VARCHAR2 ,v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2) RETURN VARCHAR2 ; -- Return null = Not found or Error

    FUNCTION MAPP_BENECODE(v_bill IN VARCHAR2 ,v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_flag IN VARCHAR2) RETURN VARCHAR2 ; -- Return null = Not found or Error

    FUNCTION CONV_BENEFIT(v_clmno IN VARCHAR2 ,v_user IN VARCHAR2 ,O_RST OUT VARCHAR2) RETURN VARCHAR2 ; -- Y ,N
    
    FUNCTION GET_BENE_TYPE(v_code IN VARCHAR2) RETURN VARCHAR2 ;
    -- �֧�������Ż���ª�� �� Doctor Visit ,�ѹ�����

    FUNCTION GET_BENETYPE_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION GET_CLMPDFLAG(v_code IN VARCHAR2) RETURN VARCHAR2 ;
           
    FUNCTION GET_PH_BENEFIT(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_type IN VARCHAR2 ,v_benecode IN VARCHAR2 
    ,O_Benefit Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; -- Return null = success ,not null = show error
    
    FUNCTION GET_PH_BENEFIT_4search(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_type IN VARCHAR2 ,v_benecode IN VARCHAR2 
    ,O_Benefit Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; -- Return null = success ,not null = show error    
    
    FUNCTION GET_WAITING_PERIOD(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_fleet IN NUMBER  
    ,O_Wait Out P_PH_CLM.v_curr) RETURN VARCHAR2; -- Return null = success ,not null = show error
    
    FUNCTION GET_ONECLAIM_HISTORY(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_fleet IN NUMBER) RETURN  VARCHAR2;
    
    FUNCTION GET_MAJOR_SUMINS(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN NUMBER) RETURN  NUMBER;
    
    FUNCTION GET_LIST_CLMTYPE(O_CLMTYPE_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; 
    -- �֧ Clm Type ������ʴ�� DropdownList -- Return null = success ,not null = show error
    
    FUNCTION GET_LIST_CARDTYPE(O_CARDTYPE_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; 
    -- �֧ Card Type ������ʴ�� DropdownList -- Return null = success ,not null = show error    

    FUNCTION GET_LIST_CLMSTS(O_CLMSTS_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; 
    -- �֧ Clm Status ������ʴ�� DropdownList -- Return null = success ,not null = show error    
    
    FUNCTION GET_LIST_APPRVSTS(O_APPRVSTS_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 ;
     -- �֧ Approve Status ������ʴ�� DropdownList -- Return null = success ,not null = show error    
     
    FUNCTION GET_LIST_BENETYPE(O_BENETYPE_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; 
    -- �֧ Benefit Type ������ʴ�� DropdownList -- Return null = success ,not null = show error    
    
    FUNCTION GET_LIST_HOSPITAL (vName IN VARCHAR2 ,O_HOSP_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
    -- �֧ ��ª����ç��Һ�� ������ʴ�� DropdownList -- Return null = success ,not null = show error    

    FUNCTION GET_LIST_ICD10 (vName IN VARCHAR2 ,O_ICD10_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
    -- �֧ ��ª����ç��Һ�� ������ʴ�� DropdownList -- Return null = success ,not null = show error    

    FUNCTION GET_LIST_ADMISSION (O_ADM_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
    -- �֧ ��»���������ѡ�� ������ʴ�� DropdownList -- Return null = success ,not null = show error    

    FUNCTION GET_LIST_BILLSTD (vName IN VARCHAR2 ,O_BILLSTD_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
    -- �֧ standard billing ������ʴ�� DropdownList -- Return null = success ,not null = show er

    FUNCTION GET_LIST_PAIDBY (O_PAIDBY Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
    -- �֧ ��������è��� Payee ������ʴ�� DropdownList -- Return null = success ,not null = show er         
    
    FUNCTION GET_SPECIAL_FLAG (O_SPECIAL Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
    -- �֧ Special Flag ������ʴ�� DropdownList -- Return null = success ,not null = show er           

    FUNCTION GET_INVALID_PAYEE (O_INV_PAYEE Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
    -- �֧ Invalid Payee Type ������ʴ�� DropdownList -- Return null = success ,not null = show er           

    FUNCTION SAVE_CLAIM_STATUS(v_action IN VARCHAR2 ,v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN VARCHAR2 ;
    -- update claim_status ��� action ������ǹ
    /*
        v_action  :
        claim_info_res  ˹�� KeyIn tab ClaimInfo
        billing     ˹�� KeyIn tab Billing
        benefit     ˹�� KeyIn tab Benefit
        ri_reserved     ˹�� KeyIn tab ReInsurance
        claim_info_paid
        payment
        payee
        ri_paid
        reopen
        cancel
        cwp
    */

    FUNCTION getRI_PAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,v_amt IN NUMBER ,O_RI OUT P_PH_CLM.v_curr) RETURN VARCHAR2 ;

    FUNCTION getRI_RES(v_clmno IN VARCHAR2 ,v_amt IN NUMBER ,O_RI OUT P_PH_CLM.v_curr) RETURN VARCHAR2 ;

    FUNCTION validate_RI_RES(v_clmno IN VARCHAR2) RETURN VARCHAR2 ;
    -- return Null ��ͼ�ҹ ,not null ��� �բ�ͼԴ��Ҵ
    
    FUNCTION validate_RI_PAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN VARCHAR2 ;
    -- return Null ��ͼ�ҹ ,not null ��� �բ�ͼԴ��Ҵ
        
    FUNCTION GET_MAPPING_ACTION(v_code IN VARCHAR2 ,v_mode IN VARCHAR2) RETURN VARCHAR2 ;
    -- �֧ status claim ��� mapping �Ѻ Action ���� // mode D = clm status detail ,O = nonpa status
    
    FUNCTION IS_BILLING_STEP(v_clmno IN VARCHAR2 ,v_rst OUT VARCHAR2)  RETURN VARCHAR2 ;
    -- ����� �����ʶҹ� Billing �ѧ�����ѹ�֡�Ż���ª�� 0 = false ,1 = true 

    FUNCTION IS_CLOSED_CLAIM(v_clmno IN VARCHAR2)  RETURN VARCHAR2 ;
    -- ����� �����ʶҹ� Billing �ѧ�����ѹ�֡�Ż���ª�� 0 = false ,1 = true 

    FUNCTION UPD_PAYMENTAPPRV(v_key IN number ,v_clmno IN varchar2 ,v_payno IN varchar2 ,v_sts IN varchar2  
    ,v_apprv_flag IN varchar2 ,v_user IN varchar2 ,v_amd_user IN varchar2 ,v_apprv_user IN varchar2 ,v_res_amt IN NUMBER ,v_accum_amt IN NUMBER ,v_remark IN VARCHAR2 ,v_rst OUT VARCHAR2) RETURN VARCHAR2 ;  
    -- ����Ѻ insert ����������ͧ͹��ѵԧҹ return 0 = false , 1 = true

    FUNCTION IS_ADVANCE_POLICY(v_polno IN VARCHAR2 ,v_polrun IN NUMBER)  RETURN VARCHAR2 ;
    -- ��ǡ�����������ö advance ���������   0 = false ,1 = true             
    
    FUNCTION CAN_SEND_APPROVE(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N

    FUNCTION CAN_GO_APPROVE(i_clmno IN varchar2 ,i_payno IN varchar2 ,i_userid IN varchar2 ,i_status IN varchar2 ,i_sys IN VARCHAR2 ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N 
    
    FUNCTION CAN_GO_RESERVED(v_clmno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N
 
    FUNCTION CAN_SAVE_BILLING(v_clmno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N
       
    FUNCTION GET_APPROVE_AMT(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN NUMBER;
    
    FUNCTION IS_NEW_PAYMENT(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N   
    
    FUNCTION GEN_RI_PAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2 ,v_amt IN NUMBER  ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N 

    FUNCTION get_SUM_RES(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN NUMBER ;
    
    FUNCTION get_SUM_RIPAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN NUMBER ;
    
    FUNCTION get_SUM_PAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN NUMBER ;
    
    FUNCTION get_SUM_PAYEE(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN NUMBER ;
    
    FUNCTION get_PAYEENAME(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2) RETURN VARCHAR2 ;
    -- �֧������ nc_payee.payee_name
    
    FUNCTION UPD_PAYMENT_STS(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,v_status IN VARCHAR2 ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N

    FUNCTION CAN_UPDATE_PAYMENT(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 ;  --Y ,N   
    
    FUNCTION GET_CLAIM_STATUS(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2 ,v_mode IN VARCHAR2)  RETURN VARCHAR2 ; --v_mode A approve,C = Claim

    FUNCTION GET_USER_LIST (v_user IN VARCHAR2 ,O_USER Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
 
    FUNCTION GET_PAID_TO(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2)  RETURN VARCHAR2 ; -- I ,H ,B 
    
    PROCEDURE GET_HOSP_PAYEE(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2 ,o_payee_code OUT VARCHAR2 ,o_payee_seq OUT VARCHAR2) ; 
   
    PROCEDURE GET_PAYEE_ACC(v_clmno IN VARCHAR2 ,v_payee IN VARCHAR2 
    ,O_ACC_NO  OUT VARCHAR2, O_ACC_NAME_TH OUT VARCHAR2,  O_ACC_NAME_EN  OUT VARCHAR2, O_BANK_CODE  OUT VARCHAR2, O_BANK_BR_CODE  OUT VARCHAR2, O_DEPOSIT OUT VARCHAR2
    );
    
    PROCEDURE GET_PAYEE_DETAIL(v_clmno IN VARCHAR2 ,v_payee IN VARCHAR2 ,v_payee_seq IN VARCHAR2 
     , o_contact_name OUT VARCHAR2 , o_addr1 OUT VARCHAR2  , o_addr2 OUT VARCHAR2  , o_mobile OUT VARCHAR2  , o_email OUT VARCHAR2
     ,o_agent_mobile  OUT VARCHAR2 ,o_agent_email  OUT VARCHAR2);  
    
    FUNCTION IS_BKIPOLICY (vPolNo IN VARCHAR2 ,vPolRun IN NUMBER ) RETURN BOOLEAN ;   
    
    FUNCTION GET_BKISTAFF_EMAIL (vUser IN VARCHAR2 ) RETURN VARCHAR2 ;  

    FUNCTION GET_PH_HISTORY(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_fleet IN NUMBER ,v_clmno IN VARCHAR2  
    ,O_History Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; -- Return null = success ,not null = show error    
    
    FUNCTION CAN_GO_CWP(v_clmno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 ;
    
    FUNCTION GET_CWP_LIST (v_type IN VARCHAR2 ,O_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2;
    
    FUNCTION SET_CWP_CLM(v_clmno IN VARCHAR2  ,v_code IN VARCHAR2  ,v_remark IN VARCHAR2 ,v_user IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION CAN_REOPEN(v_clmno IN VARCHAR2  ,o_rst OUT varchar2) RETURN VARCHAR2 ;
    
    FUNCTION SET_REOPEN(v_clmno IN VARCHAR2  ,v_code IN VARCHAR2  ,v_remark IN VARCHAR2 ,v_user IN VARCHAR2) RETURN VARCHAR2;
    
    PROCEDURE GET_APPROVE_USER(i_clmno IN varchar2 ,i_payno IN varchar2 ,o_apprv_id OUT varchar2 ,o_apprv_sts OUT varchar2);
    
    FUNCTION IS_NEW_PHCLM(v_clmno IN VARCHAR2 ,O_RST OUT VARCHAR2) RETURN BOOLEAN;
END P_PH_CLM; 

/
