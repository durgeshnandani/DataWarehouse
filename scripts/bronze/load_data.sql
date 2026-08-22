--INSERT THE DATA IN EACH 6 TABLES AND WRAP IT WITH A PROCEDURE SO THAT EACH DAY WHEN DATA WILL COME TO WAREHOUSE WE WILL RUN THIS SCRIPT

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME , @end_time DATETIME @batch_start_time DATETIME , @batch_end_time DATETIME;     ----THIS START TIME AND END TIME WILL LET US KNOW THAT HOW MUCH TIME IT TOOK TO LOAD THE TABLE 
    BEGIN TRY
    SET @batch_start_time = GETDATE();   ----TO KNOW THE TOTAL TIME TAKEN TO LOAD WHOLE TABLE INTO BRONZE LAYER
	SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_cust_info;
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\kashy\OneDrive\Documents\Data Warehouse Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		With(
		FIRSTROW = 2 ,
		FIELDTERMINATOR = ',',
		TABLOCK);
		SET @end_time = GETDATE();
		PRINT 'TIME TAKEN TO LOAD CUST_INFO TABLE IS: ' +CAST(DATEDIFF(second ,@start_time ,@end_time) AS NVARCHAR ) +' SECONDS';  ---DATEDIFF IS USED TO FIND DIFFERENCE AND CAST IS USED TO CONVERT IT TO VARCHAR AS IT WILL GIVE ANS IN INTEGER
		--SELECT * from bronze.crm_cust_info;
		SET @start_time =GETDATE();
		TRUNCATE TABLE bronze.crm_prd_info; 
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\kashy\OneDrive\Documents\Data Warehouse Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		With(
		FIRSTROW = 2 ,
		FIELDTERMINATOR = ',',
		TABLOCK);
		SET @end_time =GETDATE();
		PRINT 'TIME TAKEN TO LOAD PRD_INFO TABLE IS: ' +CAST(DATEDIFF(second ,@start_time ,@end_time) AS NVARCHAR ) +' SECONDS';

		SET @start_time =GETDATE();
		TRUNCATE TABLE bronze.crm_sales_details; 
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\kashy\OneDrive\Documents\Data Warehouse Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		With(
		FIRSTROW = 2 ,
		FIELDTERMINATOR = ',',
		TABLOCK);
		SET @end_time = GETDATE();
		PRINT 'TIME TAKEN TO LOAD SALES_DETAILS TABLE IS: ' +CAST(DATEDIFF(second ,@start_time ,@end_time) AS NVARCHAR ) +' SECONDS';


		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_CUST_AZ12; 
		BULK INSERT bronze.erp_CUST_AZ12
		FROM 'C:\Users\kashy\OneDrive\Documents\Data Warehouse Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		With(
		FIRSTROW = 2 ,
		FIELDTERMINATOR = ',',
		TABLOCK);
		SET @end_time = GETDATE();
		PRINT 'TIME TAKEN TO LOAD CUST_AZ12 TABLE IS: ' +CAST(DATEDIFF(second ,@start_time ,@end_time) AS NVARCHAR ) +' SECONDS';


		SET @start_time = GETDATE();
		BULK INSERT bronze.erp_LOC_A101
		FROM 'C:\Users\kashy\OneDrive\Documents\Data Warehouse Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		With(
		FIRSTROW = 2 ,
		FIELDTERMINATOR = ',',
		TABLOCK);
		SET @end_time = GETDATE();
		PRINT 'TIME TAKEN TO LOAD LOC_A101 TABLE IS: ' +CAST(DATEDIFF(second ,@start_time ,@end_time) AS NVARCHAR ) +' SECONDS';

		SET  @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_PX_CAT_G1V2; 
		BULK INSERT bronze.erp_PX_CAT_G1V2
		FROM 'C:\Users\kashy\OneDrive\Documents\Data Warehouse Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		With(
		FIRSTROW = 2 ,
		FIELDTERMINATOR = ',',
		TABLOCK);
		SET @end_time = GETDATE();
		PRINT 'TIME TAKEN TO LOAD PX_CAT_G1V2 TABLE IS: ' +CAST(DATEDIFF(second ,@start_time ,@end_time) AS NVARCHAR ) +' SECONDS';

       SET @batch_end_time = getdate();
       PRINT 'TIME TAKEN TO LOAD WHOLE TABLE IS: ' +CAST(DATEDIFF(second ,@start_time ,@end_time) AS NVARCHAR ) +' SECONDS';
	END TRY
	BEGIN CATCH 
	    PRINT 'ERROR OCCURED IN THE BRONZE LAYER'       ------TRY AND CATCH BLOCK IS USED TO FIND ANY ERROR IN LOADING THE DATA TO BRONZE LAYER
		PRINT 'ERROR MESSAGE:' +ERROR_MESSAGE();
		PRINT 'ERROR MESSAGE:' +CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE:' +CAST(ERROR_STATE() AS NVARCHAR);
	END CATCH

END
