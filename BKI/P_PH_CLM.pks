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

    FUNCTION GEN_NOTEKEY RETURN NUMBER;    
    
    FUNCTION GET_CLMTYPE_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2; 
    
    FUNCTION GET_CLMSTS_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION GET_ADMISS_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION GET_BENE_DESCR(v_benecode IN VARCHAR2 ,v_lang IN VARCHAR2) RETURN VARCHAR2; --v_lang : T ,E
    
    FUNCTION GET_HOSPITAL_NAME(v_code IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION GET_ICD10_DESCR(v_code IN VARCHAR2  ,v_lang IN VARCHAR2) RETURN VARCHAR2; --v_lang : T ,E
    
    FUNCTION GET_PAIDBY_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION GET_BANK_BRNAME(v_bank IN VARCHAR2 ,v_branch IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION MAPP_BENECODE(v_bill IN VARCHAR2 ,v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2) RETURN VARCHAR2 ; -- Return null = Not found or Error
    
    FUNCTION GET_PH_BENEFIT(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_type IN VARCHAR2 ,v_benecode IN VARCHAR2 
    ,O_Benefit Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; -- Return null = success ,not null = show error
    
    FUNCTION GET_LIST_CLMTYPE(O_CLMTYPE_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; 
    -- �֧ Clm Type ������ʴ�� DropdownList -- Return null = success ,not null = show error

    FUNCTION GET_LIST_CLMSTS(O_CLMSTS_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; 
    -- �֧ Clm Status ������ʴ�� DropdownList -- Return null = success ,not null = show error    
    
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
    */

    FUNCTION getRI_PAID(v_clmno IN VARCHAR2 ,v_payno IN VARCHAR2  ,v_amt IN NUMBER ,O_RI OUT P_PH_CLM.v_curr) RETURN VARCHAR2 ;

    FUNCTION validate_RI_RES(v_clmno IN VARCHAR2) RETURN VARCHAR2 ;
    -- return Null ��ͼ�ҹ ,not null ��� �բ�ͼԴ��Ҵ
    
    FUNCTION GET_MAPPING_ACTION(v_code IN VARCHAR2 ,v_mode IN VARCHAR2) RETURN VARCHAR2 ;
    -- �֧ status claim ��� mapping �Ѻ Action ���� // mode D = clm status detail ,O = nonpa status
    
    FUNCTION IS_BILLING_STEP(v_clmno IN VARCHAR2 ,v_rst OUT VARCHAR2)  RETURN VARCHAR2 ;
    -- ����� �����ʶҹ� Billing �ѧ�����ѹ�֡�Ż���ª�� 0 = false ,1 = true 

    FUNCTION IS_CLOSED_CLAIM(v_clmno IN VARCHAR2)  RETURN VARCHAR2 ;
    -- ����� �����ʶҹ� Billing �ѧ�����ѹ�֡�Ż���ª�� 0 = false ,1 = true 
        
END P_PH_CLM; 

/
