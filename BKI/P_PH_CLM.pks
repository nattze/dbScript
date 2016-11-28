CREATE OR REPLACE PACKAGE P_PH_CLM AS
/******************************************************************************
   NAME:       P_PH_CLM
   PURPOSE:     สำหรับ Projetc PH system
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        18/11/2016      2702       1. Created this package.
******************************************************************************/
    TYPE v_curr IS REF CURSOR;    
    
    FUNCTION GET_CLMTYPE_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2; 
    
    FUNCTION GET_CLMSTS_DESCR(v_code IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION GET_BENE_DESCR(v_benecode IN VARCHAR2 ,v_lang IN VARCHAR2) RETURN VARCHAR2; --v_lang : T ,E

    FUNCTION MAPP_BENECODE(v_bill IN VARCHAR2 ,v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2) RETURN VARCHAR2 ; -- Return null = Not found or Error
    
    FUNCTION GET_PH_BENEFIT(v_polno IN VARCHAR2 ,v_polrun IN NUMBER ,v_plan IN VARCHAR2 ,v_type IN VARCHAR2 ,v_benecode IN VARCHAR2 
    ,O_Benefit Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; -- Return null = success ,not null = show error
    
    FUNCTION GET_LIST_CLMTYPE(O_CLMTYPE_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; 
    -- ดึง Clm Type เตรียมแสดงใน DropdownList -- Return null = success ,not null = show error

    FUNCTION GET_LIST_CLMSTS(O_CLMSTS_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; 
    -- ดึง Clm Status เตรียมแสดงใน DropdownList -- Return null = success ,not null = show error    
    
    FUNCTION GET_LIST_BENETYPE(O_BENETYPE_LIST Out P_PH_CLM.v_curr) RETURN VARCHAR2 ; 
    -- ดึง Benefit Type เตรียมแสดงใน DropdownList -- Return null = success ,not null = show error    
    
    FUNCTION GET_LIST_HOSPITAL (vName IN VARCHAR2 ,O_HOSP_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
    -- ดึง รายชื่อโรงพยาบาล เตรียมแสดงใน DropdownList -- Return null = success ,not null = show error    

    FUNCTION GET_LIST_ICD10 (vName IN VARCHAR2 ,O_ICD10_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
    -- ดึง รายชื่อโรงพยาบาล เตรียมแสดงใน DropdownList -- Return null = success ,not null = show error    

    FUNCTION GET_LIST_ADMISSION (O_ADM_LIST Out P_PH_CLM.v_curr ) RETURN VARCHAR2 ;
    -- ดึง รายประเภทการรักษา เตรียมแสดงใน DropdownList -- Return null = success ,not null = show error    
            
END P_PH_CLM; 

/
