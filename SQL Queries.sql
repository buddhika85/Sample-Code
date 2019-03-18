USE [BCMY_Stock];

-- GROUP BY Get total incomes by conatct
SELECT [contactId], ([firstName] + ' ' + [lastName]) AS FulName, SUM([total]) AS 'Total' 
	FROM [dbo].[TblContact] INNER JOIN [dbo].[TblOrder] 
	ON [dbo].[TblContact].[id] = [dbo].[TblOrder].[contactId] 
	GROUP BY [contactId], [firstName], [lastName]
	ORDER BY Total DESC;

-----------------------------------------------------------------------------------------------------

-- temp tables creation
SELECT TOP(5) ([firstName] + ' ' + [lastName]) AS fulName, SUM([total]) AS Total INTO #TEMP_TABLE
	FROM [dbo].[TblOrder] INNER JOIN [dbo].[TblContact] 
	ON [dbo].[TblOrder].[contactId] = [dbo].[TblContact].[id] 
	GROUP BY [dbo].[TblOrder].[contactId], [firstName], [lastName]
	ORDER BY Total;

--SELECT * FROM #TEMP_TABLE;

-- create cursor variables
DECLARE @fullname VARCHAR(500) = null;
DECLARE @totalSum DECIMAL = null;

-- create cursor and loop
DECLARE cur CURSOR FOR SELECT fulName, Total FROM #TEMP_TABLE
OPEN cur

-- loop through the temp table
FETCH NEXT FROM cur INTO @fullname, @totalSum
	
WHILE @@FETCH_STATUS = 0 BEGIN
	
	PRINT @fullname +  ' --> £ ' + CONVERT(VARCHAR, @totalSum)

	FETCH NEXT FROM cur INTO @fullname, @totalSum
END

-- destroy cursor
CLOSE cur    
DEALLOCATE cur

-- drop temp table 
DROP TABLE #TEMP_TABLE;

-----------------------------------------------------------------------------------------------------

CREATE DATABASE EmployeeMgmtSystem;
USE EmployeeMgmtSystem;
--DROP TABLE TBL_EMPLOYEE;
CREATE TABLE TBL_EMPLOYEE(
	EMPLOYEE_ID NUMERIC(9) PRIMARY KEY IDENTITY(1,1),
	FIRST_NAME VARCHAR(20),
	LAST_NAME VARCHAR(20) UNIQUE,
	SALARY DECIMAL(9,2),
	DEPARTMENT VARCHAR(10),
	PERMANENT CHAR(1), 
	CONSTRAINT permanentCheck CHECK (PERMANENT = 'Y' OR PERMANENT = 'N')
);

INSERT INTO TBL_EMPLOYEE VALUES ('John', 'Kigston', 4000.50, 'Dev', 'Y');
INSERT INTO TBL_EMPLOYEE VALUES ('Jeff', 'Readman', 4000.50, 'Bus', 'Y');
INSERT INTO TBL_EMPLOYEE VALUES ('Simon', 'GilChrist', 5000.50, 'Mgmt', 'Y');

SELECT * FROM TBL_EMPLOYEE;

-----------------------------------------------------------------------------------------------------

BEGIN TRANSACTION [Tran1]

BEGIN TRY		
				
	DECLARE @templateNameNew NVARCHAR(MAX);	 
	DECLARE @templateCodeNew NVARCHAR(50);	
	DECLARE @letterTypeIdNew INT;
	
	SET @letterTypeIdNew = (SELECT Id FROM LetterTypes WHERE Code = 'KeyplateApplication');
		
	-- get all warranty certificates templates
	SELECT [Id], [Name], [TemplateCode], [CountryId] INTO #TEMP_TABLE FROM [LetterTemplate] l WHERE l.Name = 'Welcome Letter - Main (Dealer)';
	
	DECLARE @welcomeLetterDealerTemplateId INT;
	DECLARE @countryId INT;
	
	DECLARE @templateIdExists INT;
	
	-- create cursor and loop
	DECLARE cur CURSOR FOR SELECT Id, CountryId FROM #TEMP_TABLE
	OPEN cur
	
	-- loop through the temp table
	FETCH NEXT FROM cur INTO @welcomeLetterDealerTemplateId, @countryId
	
	WHILE @@FETCH_STATUS = 0 BEGIN
	
		-- copy records
		SET @templateNameNew = 'Key plate Application';		
		SET @templateCodeNew = 'KeyPlateApplication';
		SET @templateIdExists = (SELECT Id FROM LetterTemplate t WHERE t.TemplateCode = @templateCodeNew AND t.CountryId = @countryId);
		--SELECT @templateIdExists
		
		IF (@templateIdExists IS NULL)
		BEGIN
			INSERT INTO LetterTemplate ([Name], [TemplateCode], [ModifiedBy], [ModifiedDate],  [LetterTypeId],  [CreatedDate]        
			  ,[CompanyImageLogoPath]      ,[ResourceName]
			  ,[IsLogo]      ,[IsSignature]      ,[IsFooter]      ,[Subject]      ,[Body]      ,[Footer]      ,[LanguageId]
			  ,[CountryId]      ,[HTMLBody]      ,[IsActive]      ,[CreatedBy]      ,[PageNo]      
			  ,[TabName]) (SELECT @templateNameNew, @templateCodeNew, NULL, NULL, @letterTypeIdNew, GETDATE(),
			   [CompanyImageLogoPath]      ,[ResourceName]
			  ,[IsLogo]      ,[IsSignature]      ,[IsFooter]      ,[Subject]      ,[Body]      ,[Footer]      ,[LanguageId]
			  ,[CountryId]      ,[HTMLBody]      ,[IsActive]      ,[CreatedBy]      ,[PageNo]      
			  ,'key plate application (main)' FROM LetterTemplate WHERE Id = @welcomeLetterDealerTemplateId);

			PRINT @templateNameNew + ' added. Country Id -'+ CONVERT(NVARCHAR, @countryId); ;
		END
		ELSE
		BEGIN
			PRINT 'Error : Record already there with same name. Country Id - ' + CONVERT(NVARCHAR, @countryId); 
		END

		FETCH NEXT FROM cur INTO @welcomeLetterDealerTemplateId, @countryId
	END

	-- destroy cursor
	CLOSE cur    
	DEALLOCATE cur

	-- drop temp table 
	DROP TABLE #TEMP_TABLE;
		
	COMMIT TRANSACTION [Tran1];

END TRY
BEGIN CATCH
  ROLLBACK TRANSACTION [Tran1];
  
  SELECT  'All record inserts rollebacked' AS CustomMessage
    ,ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure
    ,ERROR_LINE() AS ErrorLine
    ,ERROR_MESSAGE() AS ErrorMessage;  
END CATCH  

GO






