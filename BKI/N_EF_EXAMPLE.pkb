CREATE OR REPLACE PACKAGE BODY ALLCLM.N_EF_EXAMPLE AS
/******************************************************************************
   NAME:       N_EF_EXAMPLE
   PURPOSE:     For example case to call Store/Function
   

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/10/2016      2702       1. Created this package.
******************************************************************************/

    FUNCTION func_ret_vc2(v_param1 IN VARCHAR2) RETURN VARCHAR2 IS
        ret_vc2   varchar2(15);
    BEGIN
        if v_param1 is null then
            ret_vc2 := 'Input is Null';
        else
            ret_vc2 := 'Input = '||v_param1;
        end if;
        
        return ret_vc2;
        EXCEPTION
            WHEN OTHERS THEN
            return null;
    END func_ret_vc2;
    
    FUNCTION func_ret_number(v_param1  IN VARCHAR2) RETURN NUMBER  IS
        ret_num  number;
    BEGIN
        if v_param1 is null then
            ret_num := 0;
        else
            ret_num := 100000000;
        end if;
            
        return ret_num;
        EXCEPTION
            WHEN OTHERS THEN
            return 0;            
    END func_ret_number;

    FUNCTION func_ret_boo_out_vc2(v_param1  IN VARCHAR2 ,o_param1 OUT VARCHAR2) RETURN BOOLEAN IS
    
    BEGIN
        if v_param1 is null then
            o_param1 := 'Input is Null';
            return true;
        else
            o_param1 := 'Input ='||v_param1;
            return false;
        end if;  
    
        EXCEPTION
            WHEN OTHERS THEN
            o_param1 := 'Error '||sqlerrm;
            return false;        
    END func_ret_boo_out_vc2;
    
    FUNCTION func_ret_Cursor(v_param1  IN VARCHAR2) RETURN N_EF_EXAMPLE.v_curr IS
        V_CUR1 N_EF_EXAMPLE.v_curr;
        V_CUR2 N_EF_EXAMPLE.v_curr;
    BEGIN
        OPEN V_CUR1  FOR 
            SELECT User_id MyID ,Name_T MyName FROM med_hospital_list;
            Return V_CUR1;
        EXCEPTION
            WHEN OTHERS THEN
                OPEN V_CUR2  FOR 
                    SELECT 0 MyID ,'Empty Row' MyName FROM DUAL;
                Return V_CUR2;    
    END func_ret_Cursor;    
    
    PROCEDURE proc_out2_with_Cursor(v_param1  IN VARCHAR2 ,o_cursor OUT N_EF_EXAMPLE.v_curr ,o_param1  OUT VARCHAR2) IS

        V_CUR1 N_EF_EXAMPLE.v_curr;
        V_CUR2 N_EF_EXAMPLE.v_curr;
    BEGIN
        OPEN o_cursor  FOR 
            SELECT User_id MyID ,Name_T MyName FROM med_hospital_list;
--            o_cursor :=  V_CUR1;
            
        if v_param1 is null then
            o_param1 := 'Input is Null';
        else
            o_param1 := 'Input = '||v_param1;
        end if;
        
        EXCEPTION
            WHEN OTHERS THEN
                OPEN o_cursor  FOR 
                    SELECT 0 MyID ,'Empty Row' MyName FROM DUAL;
--                o_cursor :=   V_CUR2;    
    END func_ret_Cursor;    
        
END N_EF_EXAMPLE;
/
