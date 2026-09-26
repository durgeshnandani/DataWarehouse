EXEC Silver.load_silver

CREATE OR ALTER PROCEDURE silver.load_silver as
BEGIN
    TRUNCATE TABLE Silver.crm_cust_info;

    INSERT into silver.crm_cust_info (cst_id,cst_key,cst_firstname,cst_lastname,cst_gndr,cst_marital_status,cst_create_date)
    select cst_id,cst_key,TRIM(cst_firstname) as cst_firstname, TRIM(cst_lastname) as cst_lastname,Case 
       when Upper(TRIM(cst_marital_status)) = 'S' THEN 'Single'
       when Upper(TRIM(cst_marital_status)) = 'M' THEN 'Marrried'
       else 'n/a'
     end cst_marital_status,
     Case 
       when Upper(TRIM(cst_gndr)) = 'M' THEN 'Male'
       when Upper(TRIM(cst_gndr)) = 'F' THEN 'Female'
       else 'n/a'
     end cst_gndr,cst_create_date from (select *, ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_last
    from bronze.crm_cust_info 
    where cst_id IS NOT NULL )t 
    where flag_last =1


    TRUNCATE TABLE silver.crm_prd_info;
    INSERT INTO silver.crm_prd_info(prd_id,cat_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)
    select prd_id,replace(substring(prd_key,1,5) , '-' , '_') as cat_id ,
     substring(prd_key,7,len(prd_key)) as prd_key ,
     prd_nm,ISNULL(prd_cost,0) as prd_cost , 
     case 
      when upper(TRIM(prd_line)) = 'M' THEN 'Mountain'
      when upper(TRIM(prd_line)) = 'R' THEN 'Road'
      when upper(TRIM(prd_line)) = 'S' THEN 'Other Sales'
      when upper(TRIM(prd_line)) = 'T' THEN 'Touring'
      else 'n/a' 
    end as prd_line , CAST(prd_start_dt as date) AS prd_start_dt,cast(LEAD(prd_start_dt) over(partition by prd_key order by prd_start_dt) -1 as date) as prd_end_dt
    from bronze.crm_prd_info;


    TRUNCATE TABLE silver.crm_sales_details;
    insert into silver.crm_sales_details(sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price)
    select sls_ord_num,sls_prd_key,sls_cust_id,
    case 
      when sls_order_dt is null or len(sls_order_dt) !=8 then null
      else cast(cast(sls_order_dt as varchar) as date) 
    end as sls_order_dt,
    case 
      when sls_ship_dt is null or len(sls_ship_dt)!=8 then null
        else cast(cast(sls_ship_dt as varchar) as date) 
    end as sls_ship_dt,
       case 
         when sls_due_dt is null or len(sls_due_dt) !=8 then null
         else cast(cast(sls_due_dt as varchar) as date) 
       end as sls_due_dt,
    case
      when sls_sales IS NULL OR sls_sales <=0 or sls_sales != sls_quantity * abs(sls_price) then abs(sls_price)*sls_quantity
      else sls_sales
    end as sls_sales, sls_quantity,
    case 
      when sls_price is null or sls_price <=0 then sls_sales/nullif(sls_quantity,0)
      else sls_price
    end as sls_price from bronze.crm_sales_details


    TRUNCATE TABLE Silver.erp_CUST_AZ12;
    INSERT INTO silver.erp_CUST_AZ12(cid,bdate,gen)
    select 
     case 
      when cid like 'NAS%' THEN substring(cid,4,len(cid))
      else cid
    end as cid , 
    case 
      when bdate>GETDATE() THEN NULL
      ELSE bdate
    end as bdate , 
    case 
     when UPPER(TRIM(gen)) in ('F' , 'FEMALE') THEN 'Female'
     when UPPER(TRIM(gen)) in ('M' , 'MALE') THEN 'Male'
     else 'n/a' 
    end as gen
    from bronze.erp_CUST_AZ12

    TRUNCATE TABLE silver.erp_LOC_A101;
    INSERT INTO Silver.erp_LOC_A101(cid,cntry)
    select REPLACE(cid,'-', '') AS cid,
    case when TRIM(cntry) ='DE' then 'Germany'
         when TRIM(cntry) in ('US','USA') then 'United States'
         when TRIM(cntry) IS NULL OR TRIM(cntry) ='' then 'n/a'
         else TRIM(cntry)
    end as cntry from bronze.erp_LOC_A101;


    TRUNCATE TABLE silver.erp_PX_CAT_G1V2;
    INSERT INTO silver.erp_PX_CAT_G1V2(id,cat,subcat,maintenance)
    select id,cat,subcat,maintenance from bronze.erp_PX_CAT_G1V2;
END
