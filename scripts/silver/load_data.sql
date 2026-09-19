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
