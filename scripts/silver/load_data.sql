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
