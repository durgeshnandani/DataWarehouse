-- data cleaning silver layer
select * from bronze.crm_cust_info; ----first check the data and analyze it what is wrong -> any duplicates, null value

select cst_id,count(*) from bronze.crm_cust_info group by cst_id having count(*)>1;  ---check the duplicates

--remove the duplicates

select * from (select *, ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_last from bronze.crm_cust_info 
where cst_id IS NOT NULL )t 
where flag_last =1

-- check the string if it has space

select cst_firstname from bronze.crm_cust_info
where cst_firstname !=TRIM(cst_firstname);     ----- result data shows field that has extra space
--check like this for last_name, gender 

---removing that extra space 
select cst_id,cst_key,TRIM(cst_firstname) as cst_firstname, TRIM(cst_lastname) as cst_lastname,cst_marital_status,
cst_gndr,cst_create_date from (select *, ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_last
from bronze.crm_cust_info 
where cst_id IS NOT NULL )t 
where flag_last =1

---In this project we don't give abbreviation so for 's' or 'm' we will write whole single and married

select distinct cst_marital_status from bronze.crm_cust_info; ---first check the 
 -- remove 'm' and 's' with married and single to make data more meaningful

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

--Data is cleaned now so can insert it in the silver layer

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

----See the data in silver layer

select * from silver.crm_cust_info;


---same data cleaning for crm_prd_info

select *  from bronze.crm_prd_info;
--- check for duplicates and and unwanted space 
--- always remembber we have to split the column prd_key as it has 2 info mapping to sales details and erp_PX_CAT_G1V2

select prd_id, count(*) from bronze.crm_prd_info 
group by prd_id
having count(*)>1 or prd_id is null; ---seems like there is no duplicates 
 ---lets split the column, replace null with 0 for cost and check if any cost is negavite then replace it with 0
 -- and remove abbreviation, check that start date is less than end date if not fix it , remove timestamp also 

 select prd_id,replace(substring(prd_key,1,5) , '-' , '_') as cat_id ,
 substring(prd_key,7,len(prd_key)) as prd_key , prd_nm,
 ISNULL(prd_cost,0) as prd_cost , 
 case 
  when upper(TRIM(prd_line)) = 'M' THEN 'Mountain'
  when upper(TRIM(prd_line)) = 'R' THEN 'Road'
  when upper(TRIM(prd_line)) = 'S' THEN 'Other Sales'
  when upper(TRIM(prd_line)) = 'T' THEN 'Touring'
  else 'n/a' 
end as prd_line , CAST(prd_start_dt as date) AS prd_start_dt,cast(LEAD(prd_start_dt) over(partition by prd_key order by prd_start_dt) -1 as date) as prd_end_dt
from bronze.crm_prd_info;

--- data is clean  now so insert it in the silver layer

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

--check the data
select * from silver.crm_prd_info;

--check for null value or duplicates for sls_ord_num and check that sls_prd_key do not contain extra space and sls_cust_id is not negative 
-- for sls_order_dt is int convert it to varchar then to date same with sls_ship_dt and due_dt and checkthat order dt is less than ship or due date
-- then check that sls_sales and quantity,price is not null zero or negative and sales=quantity*price
-- change the schema of sales table for order_dt which is int change it to date

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


--data is clean now insert in silver layer
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

-- lets clean the cust_AZ12 table
-- check the data first where u will get that cid is not matching with cid of cust table it has extra 'NAS' in the starting
--need to remove it so that in the case of joining the cid is same in both table , then with bdate column check if bdate is greater than today's date
---it is bad data bdate can't be in future and then check for gender and normalize it with male,female,n/a (earlier there was 'F' ,'M' ,'Male' ,'Female' ,'NULL'
--- and blank space normalize it

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

---data is clean now so load it in silver layer

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

 
--- check for LOC_A101 there are 2 columns check for cid which is linked with prod_key of another table that do not have '-' so remove it
---for country check the standarization as names as short form and blank space and null values

select REPLACE(cid,'-', '') AS cid,
case when TRIM(cntry) ='DE' then 'Germany'
     when TRIM(cntry) in ('US','USA') then 'United States'
     when TRIM(cntry) IS NULL OR TRIM(cntry) ='' then 'n/a'
     else TRIM(cntry)
end as cntry from bronze.erp_LOC_A101;

---Load in silver layer
INSERT INTO Silver.erp_LOC_A101(cid,cntry)
select REPLACE(cid,'-', '') AS cid,
case when TRIM(cntry) ='DE' then 'Germany'
     when TRIM(cntry) in ('US','USA') then 'United States'
     when TRIM(cntry) IS NULL OR TRIM(cntry) ='' then 'n/a'
     else TRIM(cntry)
end as cntry from bronze.erp_LOC_A101;

----CHECK DATA IN SILVER LAYER
select * from silver.erp_LOC_A101;

--- CHECK FOR TABLE PX_CAT_G1V2 , as checked the data quality is good and we need to just load in silver laye
-- I checked if c_id is same as cust_key from customer table so I need to remove somethings, then check for blank space for any string in all 3 columns
---then checked for standarization as no short form null or blank space , so everything looks fine

INSERT INTO silver.erp_PX_CAT_G1V2(id,cat,subcat,maintenance)
select id,cat,subcat,maintenance from bronze.erp_PX_CAT_G1V2;

--check data in silver layer

select * from silver.erp_PX_CAT_G1V2;


