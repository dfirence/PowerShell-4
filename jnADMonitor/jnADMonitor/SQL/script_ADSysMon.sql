USE [ADSysMon]
GO
/****** Object:  FullTextCatalog [FTC_ProblemScript]    Script Date: 8/20/2018 1:25:52 PM ******/
CREATE FULLTEXT CATALOG [FTC_ProblemScript] WITH ACCENT_SENSITIVITY = OFF
AS DEFAULT
GO
/****** Object:  FullTextCatalog [FTI_ProblemScript]    Script Date: 8/20/2018 1:25:52 PM ******/
CREATE FULLTEXT CATALOG [FTI_ProblemScript] WITH ACCENT_SENSITIVITY = OFF
GO
/****** Object:  FullTextCatalog [TextProblem]    Script Date: 8/20/2018 1:25:52 PM ******/
CREATE FULLTEXT CATALOG [TextProblem] WITH ACCENT_SENSITIVITY = ON
GO
/****** Object:  UserDefinedFunction [dbo].[UFN_GET_COMPANY_CODES]    Script Date: 8/20/2018 1:25:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 임윤철
-- 작성일 : 2014.12.24  
-- 수정일 : 
-- 설  명 : DASH 보드에서 서비스 목록에는 없는 고객사 도메인을 조회하고
--          고객사 도메인을 구분자가 있는 한개의 문자열로 반환하는 함수
-- 실  행 : SELECT [dbo].[UFN_GET_COMPANY_CODES]('ADDS', 'DS01', '2014-12-18 15:30:00.000')

-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  
CREATE FUNCTION [dbo].[UFN_GET_COMPANY_CODES]
(
	@TEMP_ADSERVICE  nvarchar(10),
	@TEMP_SUB_CODE   nvarchar(10),
	@TEMP_QueryDateTime datetime
)
RETURNS nvarchar(1000)
AS
BEGIN 

	DECLARE @RETURN_LinkCompanyCodes nvarchar(1000)
	DECLARE @ADD_LinkCompanyCodes nvarchar(50)

	DECLARE SUB_CURSOR CURSOR FOR SELECT Distinct Company 
									FROM [ADSysMon].[dbo].[TB_ProblemManagement]
								   WHERE ADService = @TEMP_ADSERVICE AND Serviceitem = @TEMP_SUB_CODE AND MonitoredTime > @TEMP_QueryDateTime

	SET @RETURN_LinkCompanyCodes = ''

	OPEN SUB_CURSOR
	FETCH NEXT FROM SUB_CURSOR INTO @ADD_LinkCompanyCodes

	WHILE (@@FETCH_STATUS = 0)
	BEGIN


		SET @RETURN_LinkCompanyCodes = @RETURN_LinkCompanyCodes + '^' + (SELECT [SUB_CODE] FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] WHERE CLASS_CODE = '0001' AND [VALUE2] = @ADD_LinkCompanyCodes)-- @ADD_LinkCompanyCodes

		FETCH NEXT FROM SUB_CURSOR INTO @ADD_LinkCompanyCodes
	END


	RETURN RIGHT(@RETURN_LinkCompanyCodes, LEN(@RETURN_LinkCompanyCodes) -1 )
 
 END



GO
/****** Object:  UserDefinedFunction [dbo].[UFN_GET_DOMAIN_NAME]    Script Date: 8/20/2018 1:25:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 임윤철
-- 작성일 : 2014.12.10  
-- 수정일 : 
-- 설  명 : 회사 도메인 또는 코드 입력시 회사 도메인을 반환함.
-- 실  행 : SELECT [dbo].[UFN_GET_MONITOR_DATE]('LGD', 'ADCS')

-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  
CREATE FUNCTION [dbo].[UFN_GET_DOMAIN_NAME]
(
	@COMPANY_NAME	NVARCHAR(50)
)
RETURNS nvarchar(20)
AS
BEGIN 
	
	--DECLARE @COMPANY_NAME	NVARCHAR(50)
	DECLARE @TEMP_NAME	 nvarchar(50)
	
	--SET @COMPANY_NAME = 'LGE'


	SET @TEMP_NAME  = (SELECT VALUE2 FROM [dbo].[TB_COMMON_CODE_SUB] WHERE CLASS_CODE = '0001' AND SUB_CODE = @COMPANY_NAME)

	IF (@TEMP_NAME IS NULL) 
	BEGIN
		SET @TEMP_NAME  = (SELECT VALUE2 FROM [dbo].[TB_COMMON_CODE_SUB] WHERE CLASS_CODE = '0001' AND VALUE2 = @COMPANY_NAME)
	END

	--SELECT @TEMP_NAME
	

	RETURN @TEMP_NAME
 
 END







GO
/****** Object:  UserDefinedFunction [dbo].[UFN_GET_MONITOR_DATE]    Script Date: 8/20/2018 1:25:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 임윤철
-- 작성일 : 2014.12.10  
-- 수정일 : 
-- 설  명 : TB_MonitoringTaskLogs 에서 최근 모니터링한 시간을 가져온다.
-- 실  행 : SELECT [dbo].[UFN_GET_MONITOR_DATE]('LGE', 'ADCS')

-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  
CREATE FUNCTION [dbo].[UFN_GET_MONITOR_DATE]
(
	@COMPANY_NAME	NVARCHAR(50),
	@ADSERVICE      NVARCHAR(10)
)
RETURNS nvarchar(16)
AS
BEGIN 

	DECLARE @END_DATE    DATETIME
	DECLARE @LAST_DATE	 NVARCHAR(16)
	
	--SET @LAST_DATE = '2014-12-16 02:00' --'2014-12-09 09:16'
	SET @COMPANY_NAME = (SELECT [dbo].[UFN_GET_DOMAIN_NAME](@COMPANY_NAME))

	SET @END_DATE = (
		SELECT MAX(TaskDate)
		FROM [ADSysMon].[dbo].[TB_MonitoringTaskLogs] 
		WHERE Company = @COMPANY_NAME
			AND ADService = @ADSERVICE
			AND TaskType = 'END' 
		GROUP BY Company, ADService, TaskType
	)

	SET @LAST_DATE = (
		SELECT CONVERT(NVARCHAR(16),MAX(TaskDate),120)
		FROM [ADSysMon].[dbo].[TB_MonitoringTaskLogs] 
		WHERE Company = @COMPANY_NAME
			AND ADService = @ADSERVICE
			AND TaskType = 'BEGIN' --'START' 
			AND TaskDate <= @END_DATE
		GROUP BY Company, ADService, TaskType
	)

	-- mwjin7@dotnetsoft.co.kr 추가 : BEGIN 과 END 시간차이로 이하여 Web 화면에 데이터가 안보이는 시점이 존재하는 문제 수정
	DECLARE @BeforeBeginDate NVARCHAR(16)
	SET @BeforeBeginDate = (
		SELECT CONVERT(NVARCHAR(16),MAX(TaskDate),120)
		FROM [ADSysMon].[dbo].[TB_MonitoringTaskLogs] 
		WHERE Company = @COMPANY_NAME
			AND ADService = @ADSERVICE
			AND TaskType = 'BEGIN' 
			AND TaskDate < @END_DATE
		GROUP BY Company, ADService, TaskType
	)

	--SET @LAST_DATE = '2014-12-15 15:00'
	--RETURN @LAST_DATE
	RETURN @BeforeBeginDate
 END
GO
/****** Object:  UserDefinedFunction [dbo].[UFN_GET_SPLIT_BigSize]    Script Date: 8/20/2018 1:25:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		(주)닷넷소프트 임윤철 
-- Create date: 2013.11.25
-- Description:	문자열을 SplitChar기준으로 테이블로 반환한다. BigSize SPLIT용 
-- SELECT * FROM [dbo].[UFN_GET_SPLIT_BigSize] ('Event^Service^PerLog^Replication', '^')
-- =============================================
CREATE FUNCTION [dbo].[UFN_GET_SPLIT_BigSize] 
(
	@String varchar(max), 
	@Delimiter char(1))

   RETURNS @temptable TABLE (items varchar(max)
)   
AS
   BEGIN
       DECLARE @idx INT        
        DECLARE @slice VARCHAR(8000)        

        SELECT @idx = 1        
            IF len(@String)<1 or @String is null  RETURN        

       WHILE @idx!= 0        
       BEGIN        
           SET @idx = charindex(@Delimiter,@String)        
           IF @idx!=0        
               SET @slice = left(@String,@idx - 1)        
           ELSE        
              SET @slice = @String        

           IF(len(@slice)>0)   
               INSERT INTO @temptable(Items) values(@slice)        

           SET @String = right(@String,len(@String) - @idx)        
           IF len(@String) = 0 BREAK        
       END    
   RETURN  
   END   



GO
/****** Object:  UserDefinedFunction [dbo].[UFN_GET_TABLE_COLUMNS_STR]    Script Date: 8/20/2018 1:25:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 박항록
-- 작성일 : 2014.11.06  
-- 수정일 : 2014.11.06  
-- 설   명 : 
-- 실   행 :  SELECT [dbo].[UFN_GET_TABLE_COLUMNS_STR]('TB_LGE_NET_ADDSSysvolShares')

-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  
CREATE FUNCTION [dbo].[UFN_GET_TABLE_COLUMNS_STR]
(
	@TABLE_NAME	NVARCHAR(50)
)
RETURNS nvarchar(2000)
AS
BEGIN 

	DECLARE @COLUMN_NAME varchar(50)
	DECLARE @DATA_TYPE	 varchar(50)
	DECLARE @IS_NULLABLE varchar(3)
	
	DECLARE @DTO_CODE	 varchar(8000)
	SET @DTO_CODE = ''

	DECLARE @TMP_CODE	 varchar(1000)

	DECLARE CUR_COLUMNS CURSOR FOR	
		SELECT COLUMN_NAME 
		  FROM INFORMATION_SCHEMA.COLUMNS
		 WHERE TABLE_NAME = @TABLE_NAME
		 ORDER BY ORDINAL_POSITION
	OPEN CUR_COLUMNS
	FETCH NEXT FROM CUR_COLUMNS
	INTO @COLUMN_NAME 
	WHILE @@FETCH_STATUS = 0 
	BEGIN
 	
		IF ( LEN(@DTO_CODE) = 0 )
		BEGIN 
			SET @DTO_CODE =   '['+ @COLUMN_NAME+ ']'
		END
		ELSE
		BEGIN
			SET @DTO_CODE = @DTO_CODE +', ' +  '['+ @COLUMN_NAME+ ']'
		END

		FETCH NEXT FROM CUR_COLUMNS INTO @COLUMN_NAME 
	END
	CLOSE CUR_COLUMNS
	DEALLOCATE CUR_COLUMNS

	RETURN @DTO_CODE
 
 END


GO
/****** Object:  UserDefinedFunction [dbo].[UFN_ProblemManagement]    Script Date: 8/20/2018 1:25:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.08.14
-- Description:	Problem Management Base Data Return
-- =============================================
CREATE FUNCTION [dbo].[UFN_ProblemManagement]
(
	-- Add the parameters for the function here
)
RETURNS @ReturnTable TABLE
(
	[IDX] INT
	,[MonitoredTime] DATETIME
	,[Company] NVARCHAR(20)
	,[ADService] NVARCHAR(10)
	,[Serviceitem] NVARCHAR(50)
	,[ComputerName] NVARCHAR(100)
	,[ProblemScript] NVARCHAR(MAX)
	,[ManageStatus] NVARCHAR(20)
	,[Manager] NVARCHAR(50)
	,[ManageScript] NVARCHAR(MAX)
	,[ManageDate] DATETIME
	,[ManageIDX] INT
	,[SMSSendYN] NVARCHAR(1)
)
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	DECLARE @TriggerCycle INT
	DECLARE @TriggerCount INT

	-- Connect : Ping Fault => 점검 기간(5분) 중 1회 이상 실패
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'CONNECT')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'CONNECT')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'CONNECT'
			AND T1.[MonitoredTime] > DATEADD(MINUTE, @TriggerCycle, (SELECT T2.[LastDate] FROM [dbo].[UFN_MonitoringTaskLogs]() T2 WHERE T2.[Company] = T1.[Company] AND T2.[ADService] = 'CONNECT'))
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'CONNECT'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount
		AND T1.[IDX] NOT IN ( -- Alert Snooze
				SELECT TOP 1 T3.[IDX]
				FROM [dbo].[TB_ProblemManagement] T3
				INNER JOIN  [dbo].[TB_ALERT_SNOOZE] T2 ON (T2.[CompanyCode] = '' OR T3.[Company] = T2.[CompanyCode])
					AND (T2.[ADService] = '' OR T3.[ADService] = T2.[ADService])
					AND (T2.[ServiceItem] = '' OR T3.[ServiceItem] = T2.[ServiceItem])
					AND (T2.[ComputerName] = '' OR T3.[ComputerName] = T2.[ComputerName])
					AND (T3.[ProblemScript] LIKE '%' + T2.[ProblemScript] + '%')
			)

	-- ADCS : Service Availability (Service interface Down 여부 (certutil -ping)) => 점검 기간 중 1회 이상 실패
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'ADCS')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'ADCS')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'ADCS' AND T1.[Serviceitem] = 'CS04'
			AND T1.[MonitoredTime] > DATEADD(MINUTE, @TriggerCycle, (SELECT T2.[LastDate] FROM [dbo].[UFN_MonitoringTaskLogs]() T2 WHERE T2.[Company] = T1.[Company] AND T2.[ADService] = 'CONNECT'))
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'ADCS' AND T1.[Serviceitem] = 'CS04'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount
		AND T1.[IDX] NOT IN ( -- Alert Snooze
				SELECT TOP 1 T3.[IDX]
				FROM [dbo].[TB_ProblemManagement] T3
				INNER JOIN  [dbo].[TB_ALERT_SNOOZE] T2 ON (T2.[CompanyCode] = '' OR T3.[Company] = T2.[CompanyCode])
					AND (T2.[ADService] = '' OR T3.[ADService] = T2.[ADService])
					AND (T2.[ServiceItem] = '' OR T3.[ServiceItem] = T2.[ServiceItem])
					AND (T2.[ComputerName] = '' OR T3.[ComputerName] = T2.[ComputerName])
					AND (T3.[ProblemScript] LIKE '%' + T2.[ProblemScript] + '%')
			)

	-- ADDS : Replication (복제 실패 여부) => 점검 기간 중 2회 이상 실패
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'ADDS')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'ADDS')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'ADDS' AND T1.[Serviceitem] = 'DS04'
			AND T1.[MonitoredTime] > DATEADD(MINUTE, @TriggerCycle, (SELECT T2.[LastDate] FROM [dbo].[UFN_MonitoringTaskLogs]() T2 WHERE T2.[Company] = T1.[Company] AND T2.[ADService] = 'CONNECT'))
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'ADDS' AND T1.[Serviceitem] = 'DS04'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount
		AND T1.[IDX] NOT IN ( -- Alert Snooze
				SELECT TOP 1 T3.[IDX]
				FROM [dbo].[TB_ProblemManagement] T3
				INNER JOIN  [dbo].[TB_ALERT_SNOOZE] T2 ON (T2.[CompanyCode] = '' OR T3.[Company] = T2.[CompanyCode])
					AND (T2.[ADService] = '' OR T3.[ADService] = T2.[ADService])
					AND (T2.[ServiceItem] = '' OR T3.[ServiceItem] = T2.[ServiceItem])
					AND (T2.[ComputerName] = '' OR T3.[ComputerName] = T2.[ComputerName])
					AND (T3.[ProblemScript] LIKE '%' + T2.[ProblemScript] + '%')
			)

	-- DNS : Service Availability (lookup 실패 여부) => 점검 기간 중 2회 이상 실패
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'DNS')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'DNS')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'DNS' AND T1.[Serviceitem] = 'DN04'
			AND T1.[MonitoredTime] > DATEADD(MINUTE, @TriggerCycle, (SELECT T2.[LastDate] FROM [dbo].[UFN_MonitoringTaskLogs]() T2 WHERE T2.[Company] = T1.[Company] AND T2.[ADService] = 'CONNECT'))
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'DNS' AND T1.[Serviceitem] = 'DN04'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount
		AND T1.[IDX] NOT IN ( -- Alert Snooze
				SELECT TOP 1 T3.[IDX]
				FROM [dbo].[TB_ProblemManagement] T3
				INNER JOIN  [dbo].[TB_ALERT_SNOOZE] T2 ON (T2.[CompanyCode] = '' OR T3.[Company] = T2.[CompanyCode])
					AND (T2.[ADService] = '' OR T3.[ADService] = T2.[ADService])
					AND (T2.[ServiceItem] = '' OR T3.[ServiceItem] = T2.[ServiceItem])
					AND (T2.[ComputerName] = '' OR T3.[ComputerName] = T2.[ComputerName])
					AND (T3.[ProblemScript] LIKE '%' + T2.[ProblemScript] + '%')
			)

	-- RADIUS : Service Availability (인증 실패 여부) => 점검 기간 중 Event ID 6273/6274(인증실패) 메시지만 있는 경우
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'RADIUS')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'RADIUS')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'RADIUS' AND T1.[Serviceitem] = 'RD04'
			AND T1.[MonitoredTime] > DATEADD(MINUTE, @TriggerCycle, (SELECT T2.[LastDate] FROM [dbo].[UFN_MonitoringTaskLogs]() T2 WHERE T2.[Company] = T1.[Company] AND T2.[ADService] = 'RADIUS'))
			AND (T1.[ProblemScript] LIKE 'EventID(6273%' OR T1.[ProblemScript] LIKE 'EventID(6274%')
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'RADIUS' AND T1.[Serviceitem] = 'RD04'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount
		AND T1.[IDX] NOT IN ( -- Alert Snooze
				SELECT TOP 1 T3.[IDX]
				FROM [dbo].[TB_ProblemManagement] T3
				INNER JOIN  [dbo].[TB_ALERT_SNOOZE] T2 ON (T2.[CompanyCode] = '' OR T3.[Company] = T2.[CompanyCode])
					AND (T2.[ADService] = '' OR T3.[ADService] = T2.[ADService])
					AND (T2.[ServiceItem] = '' OR T3.[ServiceItem] = T2.[ServiceItem])
					AND (T2.[ComputerName] = '' OR T3.[ComputerName] = T2.[ComputerName])
					AND (T3.[ProblemScript] LIKE '%' + T2.[ProblemScript] + '%')
			)

	-- DHCP : Service Availability (DHCP Offer에 대한 응답 실패 여부) => 점검 기간 중 1회 이상 실패
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'DHCP')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'DHCP')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'DHCP' AND T1.[Serviceitem] = 'DH04'
			AND T1.[MonitoredTime] > DATEADD(MINUTE, @TriggerCycle, (SELECT T2.[LastDate] FROM [dbo].[UFN_MonitoringTaskLogs]() T2 WHERE T2.[Company] = T1.[Company] AND T2.[ADService] = 'CONNECT'))
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'DHCP' AND T1.[Serviceitem] = 'DH04'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount
		AND T1.[IDX] NOT IN ( -- Alert Snooze
				SELECT TOP 1 T3.[IDX]
				FROM [dbo].[TB_ProblemManagement] T3
				INNER JOIN  [dbo].[TB_ALERT_SNOOZE] T2 ON (T2.[CompanyCode] = '' OR T3.[Company] = T2.[CompanyCode])
					AND (T2.[ADService] = '' OR T3.[ADService] = T2.[ADService])
					AND (T2.[ServiceItem] = '' OR T3.[ServiceItem] = T2.[ServiceItem])
					AND (T2.[ComputerName] = '' OR T3.[ComputerName] = T2.[ComputerName])
					AND (T3.[ProblemScript] LIKE '%' + T2.[ProblemScript] + '%')
			)

	-- Other Data
	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[MonitoredTime] > DATEADD(MONTH, - 1, GETUTCDATE())
		AND T1.[ADService] != 'CONNECT' -- CONNECT 쿼리에 존재하므로 제외...
		AND T1.[ADService] != 'RADIUS' -- RADIUS 쿼리에 존재하므로 제외...
		AND ((T1.[ADService] = 'ADCS' AND T1.[Serviceitem] != 'CS04')
			OR (T1.[ADService] = 'ADDS' AND T1.[Serviceitem] != 'DS04')
			OR (T1.[ADService] = 'DNS' AND T1.[Serviceitem] != 'DN04')
			--OR (T1.[ADService] = 'RADIUS' AND T1.[Serviceitem] != 'RD04') -- mwjin7@dotnetsoft.co.kr 2018.08.01 기존 SP 에 4 항목만 체크하고 있음...
			OR (T1.[ADService] = 'DHCP' AND T1.[Serviceitem] != 'DH04')
			OR T1.[ADService] = 'TASK'
			)
		AND T1.[IDX] NOT IN ( -- Alert Snooze
				SELECT TOP 1 T3.[IDX]
				FROM [dbo].[TB_ProblemManagement] T3
				INNER JOIN  [dbo].[TB_ALERT_SNOOZE] T2 ON (T2.[CompanyCode] = '' OR T3.[Company] = T2.[CompanyCode])
					AND (T2.[ADService] = '' OR T3.[ADService] = T2.[ADService])
					AND (T2.[ServiceItem] = '' OR T3.[ServiceItem] = T2.[ServiceItem])
					AND (T2.[ComputerName] = '' OR T3.[ComputerName] = T2.[ComputerName])
					AND (T3.[ProblemScript] LIKE '%' + T2.[ProblemScript] + '%')
			)

	RETURN 
END
GO
/****** Object:  UserDefinedFunction [dbo].[UFN_TEMP]    Script Date: 8/20/2018 1:25:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[UFN_TEMP]
(
	-- Add the parameters for the function here
)
RETURNS @ReturnTable TABLE
(
	[IDX] INT
	,[MonitoredTime] DATETIME
	,[Company] NVARCHAR(20)
	,[ADService] NVARCHAR(10)
	,[Serviceitem] NVARCHAR(50)
	,[ComputerName] NVARCHAR(100)
	,[ProblemScript] NVARCHAR(MAX)
	,[ManageStatus] NVARCHAR(20)
	,[Manager] NVARCHAR(50)
	,[ManageScript] NVARCHAR(MAX)
	,[ManageDate] DATETIME
	,[ManageIDX] INT
	,[SMSSendYN] NVARCHAR(1)
)
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	DECLARE @TriggerCycle INT
	DECLARE @TriggerCount INT

	-- Connect : Ping Fault => 점검 기간(5분) 중 1회 이상 실패
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'CONNECT')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'CONNECT')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'CONNECT'
			AND T1.[MonitoredTime] > DATEADD(MINUTE, @TriggerCycle, (SELECT T2.[LastDate] FROM [dbo].[UFN_MonitoringTaskLogs]() T2 WHERE T2.[Company] = T1.[Company] AND T2.[ADService] = 'CONNECT'))
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'CONNECT'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount

	-- ADCS : Service Availability (Service interface Down 여부 (certutil -ping)) => 점검 기간 중 1회 이상 실패
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'ADCS')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'ADCS')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'ADCS' AND T1.[Serviceitem] = 'CS04'
			AND T1.[MonitoredTime] > DATEADD(MINUTE, @TriggerCycle, (SELECT T2.[LastDate] FROM [dbo].[UFN_MonitoringTaskLogs]() T2 WHERE T2.[Company] = T1.[Company] AND T2.[ADService] = 'CONNECT'))
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'ADCS' AND T1.[Serviceitem] = 'CS04'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount

	-- ADDS : Replication (복제 실패 여부) => 점검 기간 중 2회 이상 실패
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'ADDS')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'ADDS')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'ADDS' AND T1.[Serviceitem] = 'DS04'
			AND T1.[MonitoredTime] > DATEADD(MINUTE, @TriggerCycle, (SELECT T2.[LastDate] FROM [dbo].[UFN_MonitoringTaskLogs]() T2 WHERE T2.[Company] = T1.[Company] AND T2.[ADService] = 'CONNECT'))
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'ADDS' AND T1.[Serviceitem] = 'DS04'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount

	-- DNS : Service Availability (lookup 실패 여부) => 점검 기간 중 2회 이상 실패
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'DNS')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'DNS')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'DNS' AND T1.[Serviceitem] = 'DN04'
			AND T1.[MonitoredTime] > DATEADD(MINUTE, @TriggerCycle, (SELECT T2.[LastDate] FROM [dbo].[UFN_MonitoringTaskLogs]() T2 WHERE T2.[Company] = T1.[Company] AND T2.[ADService] = 'CONNECT'))
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'DNS' AND T1.[Serviceitem] = 'DN04'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount

	-- RADIUS : Service Availability (인증 실패 여부) => 점검 기간 중 Event ID 6273/6274(인증실패) 메시지만 있는 경우
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'RADIUS')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'RADIUS')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'RADIUS' AND T1.[Serviceitem] = 'RD04'
			AND (T1.[ProblemScript] LIKE 'EventID(6273%' OR T1.[ProblemScript] LIKE 'EventID(6274%')
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'RADIUS' AND T1.[Serviceitem] = 'RD04'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount

	-- DHCP : Service Availability (DHCP Offer에 대한 응답 실패 여부) => 점검 기간 중 1회 이상 실패
	SET @TriggerCycle = -1 * (SELECT ISNULL([TriggerCycle], 0) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'DHCP')
	SET @TriggerCount = (SELECT ISNULL([TriggerCount], 1) FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] WHERE [ADService] = 'DHCP')

	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	INNER JOIN 
	(
		SELECT T1.[ComputerName], COUNT(*) AS Cnt
		FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
		WHERE T1.[ManageStatus] = 'NOTSTARTED'
			AND T1.[ADService] = 'DHCP' AND T1.[Serviceitem] = 'DH04'
			AND T1.[MonitoredTime] > DATEADD(MINUTE, @TriggerCycle, (SELECT T2.[LastDate] FROM [dbo].[UFN_MonitoringTaskLogs]() T2 WHERE T2.[Company] = T1.[Company] AND T2.[ADService] = 'CONNECT'))
		GROUP BY T1.[ComputerName]
	) T2 ON T1.[ComputerName] = T2.[ComputerName]
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[ADService] = 'DHCP' AND T1.[Serviceitem] = 'DH04'
		AND T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
		AND T2.[Cnt] >= @TriggerCount

	-- Other Data
	INSERT INTO @ReturnTable
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
		,T1.[ManageIDX]
		,T1.[SMSSendYN]
	FROM [dbo].[TB_ProblemManagement] T1 WITH(NOLOCK)
	WHERE T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[MonitoredTime] > DATEADD(MONTH, - 1, GETUTCDATE())
		AND T1.[ADService] != 'CONNECT' -- CONNECT 쿼리에 존재하므로 제외...
		AND T1.[ADService] != 'RADIUS' -- RADIUS 쿼리에 존재하므로 제외...
		AND ((T1.[ADService] = 'ADCS' AND T1.[Serviceitem] != 'CS04')
			OR (T1.[ADService] = 'ADDS' AND T1.[Serviceitem] != 'DS04')
			OR (T1.[ADService] = 'DNS' AND T1.[Serviceitem] != 'DN04')
			--OR (T1.[ADService] = 'RADIUS' AND T1.[Serviceitem] != 'RD04') -- mwjin7@dotnetsoft.co.kr 2018.08.01 기존 SP 에 4 항목만 체크하고 있음...
			OR (T1.[ADService] = 'DHCP' AND T1.[Serviceitem] != 'DH04')
			OR T1.[ADService] = 'TASK'
			)
		AND T1.[IDX] NOT IN ( -- Alert Snooze
				SELECT TOP 1 T3.[IDX]
				FROM [dbo].[TB_ProblemManagement] T3
				INNER JOIN  [dbo].[TB_ALERT_SNOOZE] T2 ON (T2.[CompanyCode] = '' OR T3.[Company] = T2.[CompanyCode])
					AND (T2.[ADService] = '' OR T3.[ADService] = T2.[ADService])
					AND (T2.[ServiceItem] = '' OR T3.[ServiceItem] = T2.[ServiceItem])
					AND (T2.[ComputerName] = '' OR T3.[ComputerName] = T2.[ComputerName])
					AND (T3.[ProblemScript] LIKE '%' + T2.[ProblemScript] + '%')
			)

	RETURN 
END
GO
/****** Object:  Table [dbo].[TB__ADDSW32TimeSync]    Script Date: 8/20/2018 1:25:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB__ADDSW32TimeSync](
	[ComputerName] [nvarchar](100) NULL,
	[LastSuccessfulSyncedTime] [nvarchar](50) NOT NULL,
	[TimeSource] [nvarchar](50) NOT NULL,
	[IsGlobalCatalog] [nvarchar](20) NOT NULL,
	[IsRODC] [nvarchar](20) NOT NULL,
	[OperationMasterRoles] [nvarchar](max) NOT NULL,
	[OperatingSystemServicePack] [nvarchar](50) NOT NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[OperatingSystem] [nvarchar](200) NOT NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_ALERT_SNOOZE]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_ALERT_SNOOZE](
	[IDX] [int] IDENTITY(1,1) NOT NULL,
	[CompanyCode] [nvarchar](10) NULL,
	[ADService] [nvarchar](10) NULL,
	[ServiceItem] [nvarchar](50) NULL,
	[ComputerName] [nvarchar](100) NULL,
	[ProblemScript] [nvarchar](100) NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[CreateUserID] [nvarchar](10) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
 CONSTRAINT [PK_TB_ALARM_SNOOZE_IDX] PRIMARY KEY CLUSTERED 
(
	[IDX] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_COMMON_CODE_CLASS]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_COMMON_CODE_CLASS](
	[CLASS_CODE] [varchar](4) NOT NULL,
	[CODE_NAME] [nvarchar](100) NOT NULL,
	[USE_YN] [char](1) NOT NULL,
	[CREATOR_ID] [varchar](10) NOT NULL,
	[CREATE_DATE] [smalldatetime] NOT NULL,
	[UPDATER_ID] [varchar](10) NULL,
	[UPDATE_DATE] [smalldatetime] NULL,
 CONSTRAINT [PK_TB_COMMON_CODE_CLASS] PRIMARY KEY CLUSTERED 
(
	[CLASS_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_COMMON_CODE_SUB]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_COMMON_CODE_SUB](
	[CLASS_CODE] [varchar](4) NOT NULL,
	[SUB_CODE] [nvarchar](10) NOT NULL,
	[USE_YN] [char](1) NOT NULL,
	[CODE_NAME] [nvarchar](100) NOT NULL,
	[SORT_SEQ] [int] NULL,
	[VALUE1] [nvarchar](30) NULL,
	[CREATOR_ID] [varchar](10) NOT NULL,
	[CREATE_DATE] [smalldatetime] NOT NULL,
	[UPDATER_ID] [varchar](10) NULL,
	[UPDATE_DATE] [smalldatetime] NULL,
	[VALUE2] [nvarchar](30) NULL,
 CONSTRAINT [PK_TB_CD_SUB] PRIMARY KEY CLUSTERED 
(
	[CLASS_CODE] ASC,
	[SUB_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_EVENTID]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_EVENTID](
	[IDX] [int] IDENTITY(1,1) NOT NULL,
	[ID] [nvarchar](30) NOT NULL,
	[ServiceFlag] [nvarchar](10) NOT NULL,
	[Detail] [nvarchar](500) NULL,
	[Reason] [nvarchar](500) NULL,
	[CreateUserID] [nvarchar](10) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
 CONSTRAINT [PK_TB_EXCEPTED_EVENT] PRIMARY KEY CLUSTERED 
(
	[IDX] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_ADCSEnrollmentPolicy]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_ADCSEnrollmentPolicy](
	[ComputerName] [nvarchar](100) NULL,
	[OperatingSystem] [nvarchar](100) NULL,
	[OperatingSystemServicePack] [nvarchar](100) NULL,
	[CAName] [nvarchar](30) NOT NULL,
	[DNSName] [nvarchar](30) NOT NULL,
	[CAType] [nvarchar](200) NOT NULL,
	[CertEnrollPolicyTemplates] [nvarchar](max) NOT NULL,
	[CATemplates] [nvarchar](max) NOT NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_ADCSServiceAvailability]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_ADCSServiceAvailability](
	[ComputerName] [nvarchar](100) NULL,
	[OperatingSystem] [nvarchar](100) NULL,
	[OperatingSystemServicePack] [nvarchar](100) NULL,
	[CAName] [nvarchar](30) NOT NULL,
	[DNSName] [nvarchar](30) NOT NULL,
	[CAType] [nvarchar](200) NOT NULL,
	[PingAdmin] [nvarchar](200) NOT NULL,
	[Ping] [nvarchar](200) NOT NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[CrlPublishStatus] [nvarchar](max) NOT NULL,
	[DeltaCrlPublishStatus] [nvarchar](max) NOT NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL,
	[Subject] [nvarchar](200) NOT NULL,
	[Thumbprint] [nvarchar](100) NOT NULL,
	[NotAfter] [datetime] NOT NULL,
	[CrlState] [nvarchar](20) NOT NULL,
	[CrlPeriod] [nvarchar](20) NOT NULL,
	[CrlDeltaPeriod] [nvarchar](20) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_ADDSAdvertisement]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_ADDSAdvertisement](
	[ComputerName] [nvarchar](100) NULL,
	[IsGlobalCatalog] [nvarchar](10) NULL,
	[IsRODC] [nvarchar](10) NULL,
	[OperationMasterRoles] [nvarchar](max) NULL,
	[OperatingSystemServicePack] [nvarchar](30) NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[OperatingSystem] [nvarchar](50) NULL,
	[dcdiag_advertising] [nvarchar](max) NOT NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_ADDSReplication]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_ADDSReplication](
	[ComputerName] [nvarchar](100) NULL,
	[repadmin] [nvarchar](300) NULL,
	[OperatingSystem] [nvarchar](100) NULL,
	[OperatingSystemServicePack] [nvarchar](100) NULL,
	[IsGlobalCatalog] [nvarchar](10) NOT NULL,
	[IsRODC] [nvarchar](10) NOT NULL,
	[OperationMasterRoles] [nvarchar](max) NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_ADDSRepository]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_ADDSRepository](
	[ComputerName] [nvarchar](100) NULL,
	[SysvolPath] [nvarchar](200) NOT NULL,
	[LogFileSize] [nvarchar](20) NOT NULL,
	[IsGlobalCatalog] [nvarchar](20) NULL,
	[DataBaseSize] [nvarchar](200) NOT NULL,
	[IsRODC] [nvarchar](20) NULL,
	[LogFilePath] [nvarchar](200) NOT NULL,
	[DataBasePath] [nvarchar](200) NOT NULL,
	[DatabaseDriveFreeSpace] [nvarchar](50) NOT NULL,
	[OperatingSystemServicePack] [nvarchar](50) NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[OperatingSystem] [nvarchar](200) NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_ADDSSysvolShares]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_ADDSSysvolShares](
	[ComputerName] [nvarchar](100) NULL,
	[frssysvol] [nvarchar](max) NOT NULL,
	[OperatingSystem] [nvarchar](100) NULL,
	[OperatingSystemServicePack] [nvarchar](100) NULL,
	[IsGlobalCatalog] [nvarchar](10) NOT NULL,
	[IsRODC] [nvarchar](10) NOT NULL,
	[OperationMasterRoles] [nvarchar](max) NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_ADDSTopology]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_ADDSTopology](
	[ComputerName] [nvarchar](100) NULL,
	[adtopology] [nvarchar](max) NOT NULL,
	[OperatingSystem] [nvarchar](100) NOT NULL,
	[OperatingSystemServicePack] [nvarchar](100) NOT NULL,
	[IsGlobalCatalog] [nvarchar](10) NOT NULL,
	[IsRODC] [nvarchar](10) NOT NULL,
	[OperationMasterRoles] [nvarchar](max) NOT NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_ADDSW32TimeSync]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_ADDSW32TimeSync](
	[ComputerName] [nvarchar](100) NULL,
	[LastSuccessfulSyncedTime] [nvarchar](50) NOT NULL,
	[TimeSource] [nvarchar](50) NOT NULL,
	[IsGlobalCatalog] [nvarchar](20) NULL,
	[IsRODC] [nvarchar](20) NOT NULL,
	[OperationMasterRoles] [nvarchar](max) NOT NULL,
	[OperatingSystemServicePack] [nvarchar](50) NOT NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[OperatingSystem] [nvarchar](200) NOT NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_CONNECTIVITY]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_CONNECTIVITY](
	[ComputerName] [nvarchar](100) NOT NULL,
	[CanPing] [nvarchar](5) NOT NULL,
	[CanPort135] [nvarchar](5) NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[CanPort5985] [nvarchar](5) NULL,
 CONSTRAINT [PK__TB_LGE_N__A3651FB40D66F1C6] PRIMARY KEY CLUSTERED 
(
	[ComputerName] ASC,
	[UTCMonitored] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_DHCPServiceAvailability]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_DHCPServiceAvailability](
	[ComputerName] [nvarchar](100) NULL,
	[OperatingSystem] [nvarchar](100) NULL,
	[OperatingSystemServicePack] [nvarchar](100) NULL,
	[serverstatus] [nvarchar](300) NOT NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[DatabaseName] [nvarchar](100) NULL,
	[DatabasePath] [nvarchar](100) NULL,
	[DatabaseBackupPath] [nvarchar](100) NULL,
	[DatabaseBackupInterval] [nvarchar](20) NULL,
	[DatabaseLoggingFlag] [nvarchar](20) NULL,
	[DatabaseRestoreFlag] [nvarchar](20) NULL,
	[DatabaseCleanupInterval] [nvarchar](20) NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL,
	[IsAvailableByClient] [nvarchar](10) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_DNSServiceAvailability]    Script Date: 8/20/2018 1:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_DNSServiceAvailability](
	[ComputerName] [nvarchar](100) NULL,
	[OperatingSystem] [nvarchar](100) NULL,
	[OperatingSystemServicePack] [nvarchar](100) NULL,
	[dnsstatus] [nvarchar](300) NOT NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_EVENT]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_EVENT](
	[LogName] [nvarchar](30) NOT NULL,
	[TimeCreated] [datetime] NOT NULL,
	[Id] [nvarchar](30) NOT NULL,
	[ProviderName] [nvarchar](100) NULL,
	[LevelDisplayName] [nvarchar](30) NOT NULL,
	[Message] [nvarchar](max) NOT NULL,
	[ComputerName] [nvarchar](100) NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[ServiceFlag] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_PERFORMANCE]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_PERFORMANCE](
	[TimeStamp] [datetime] NOT NULL,
	[TimeStamp100NSec] [nvarchar](18) NOT NULL,
	[Value] [float] NOT NULL,
	[Path] [nvarchar](100) NOT NULL,
	[InstanceName] [nvarchar](100) NULL,
	[ComputerName] [nvarchar](100) NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[ServiceFlag] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_RADIUSServiceAvailability]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_RADIUSServiceAvailability](
	[LogName] [nvarchar](30) NOT NULL,
	[TimeCreated] [datetime] NOT NULL,
	[Id] [nvarchar](30) NOT NULL,
	[ProviderName] [nvarchar](100) NOT NULL,
	[LevelDisplayName] [nvarchar](30) NOT NULL,
	[Message] [nvarchar](max) NOT NULL,
	[ComputerName] [nvarchar](100) NOT NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[ServiceFlag] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_LGE_NET_SERVICE]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_LGE_NET_SERVICE](
	[ServiceStatus] [nvarchar](30) NOT NULL,
	[Name] [nvarchar](30) NOT NULL,
	[DisplayName] [nvarchar](50) NOT NULL,
	[ComputerName] [nvarchar](100) NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[ServiceFlag] [nvarchar](10) NOT NULL,
	[IsError] [nvarchar](10) NOT NULL,
	[ManageStatus] [nvarchar](2) NULL,
	[Manager] [nvarchar](20) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_MANAGE_COMPANY_USER]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MANAGE_COMPANY_USER](
	[USERID] [nvarchar](10) NOT NULL,
	[COMPANYCODE] [nvarchar](6) NOT NULL,
	[CREATE_ID] [nvarchar](10) NOT NULL,
	[CREATE_DATE] [datetime] NOT NULL,
	[USEYN] [char](1) NOT NULL,
 CONSTRAINT [PK_TB_MANAGE_COMPANY_USER] PRIMARY KEY CLUSTERED 
(
	[USERID] ASC,
	[COMPANYCODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_MAP_AREA]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MAP_AREA](
	[AreaID] [int] IDENTITY(1,1) NOT NULL,
	[AreaName] [nvarchar](50) NOT NULL,
	[AreaLatitude] [float] NOT NULL,
	[AreaLongitude] [float] NOT NULL,
 CONSTRAINT [PK_TB_MAP_AREA] PRIMARY KEY CLUSTERED 
(
	[AreaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_MAP_CITY]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MAP_CITY](
	[CityID] [int] IDENTITY(1,1) NOT NULL,
	[CityName] [nvarchar](50) NOT NULL,
	[CountryID] [int] NOT NULL,
	[CityLatitude] [float] NOT NULL,
	[CityLongitude] [float] NOT NULL,
 CONSTRAINT [PK_TB_MAP_CITY] PRIMARY KEY CLUSTERED 
(
	[CityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_MAP_CORP]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MAP_CORP](
	[CorpID] [int] IDENTITY(1,1) NOT NULL,
	[CorpName] [nvarchar](50) NOT NULL,
	[CityID] [int] NOT NULL,
	[CorpLatitude] [float] NOT NULL,
	[CorpLongitude] [float] NOT NULL,
 CONSTRAINT [PK_TB_MAP_CORP] PRIMARY KEY CLUSTERED 
(
	[CorpID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_MAP_COUNTRY]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MAP_COUNTRY](
	[CountryID] [int] IDENTITY(1,1) NOT NULL,
	[CountryName] [nvarchar](50) NOT NULL,
	[AreaID] [int] NOT NULL,
 CONSTRAINT [PK_TB_MAP_COUNTRY] PRIMARY KEY CLUSTERED 
(
	[CountryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_MonitoringTaskLogs]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MonitoringTaskLogs](
	[TaskDate] [datetime] NOT NULL,
	[TaskType] [nvarchar](10) NOT NULL,
	[Company] [nvarchar](50) NOT NULL,
	[ADService] [nvarchar](10) NULL,
	[Serviceitem] [nvarchar](50) NULL,
	[ComputerName] [nvarchar](100) NULL,
	[TaskScript] [nvarchar](max) NULL,
	[CreateDate] [datetime] NOT NULL,
 CONSTRAINT [PK_TB_MonitoringTaskLogs] PRIMARY KEY CLUSTERED 
(
	[TaskDate] DESC,
	[TaskType] ASC,
	[Company] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_ProblemManagement]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_ProblemManagement](
	[IDX] [int] IDENTITY(1,1) NOT NULL,
	[MonitoredTime] [datetime] NOT NULL,
	[Company] [nvarchar](20) NOT NULL,
	[ADService] [nvarchar](10) NOT NULL,
	[Serviceitem] [nvarchar](50) NOT NULL,
	[ComputerName] [nvarchar](100) NULL,
	[ProblemScript] [nvarchar](max) NULL,
	[ManageStatus] [nvarchar](20) NULL,
	[Manager] [nvarchar](50) NULL,
	[ManageScript] [nvarchar](max) NULL,
	[ManageDate] [datetime] NULL,
	[ManageIDX] [int] NULL,
	[SMSSendYN] [nvarchar](1) NULL,
 CONSTRAINT [PK_TB_ProblemManagement] PRIMARY KEY CLUSTERED 
(
	[IDX] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_SERVERS]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_SERVERS](
	[Domain] [nvarchar](30) NOT NULL,
	[ServiceFlag] [nvarchar](10) NOT NULL,
	[ComputerName] [nvarchar](100) NOT NULL,
	[IPAddress] [nvarchar](15) NULL,
	[UTCMonitored] [datetime] NOT NULL,
	[ServerFQDN] [nvarchar](100) NULL,
	[CorpID] [int] NULL,
 CONSTRAINT [PK__TB_SERVE__5B58420FD848EACC] PRIMARY KEY CLUSTERED 
(
	[Domain] ASC,
	[ServiceFlag] ASC,
	[ComputerName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_SMS_FILTER]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_SMS_FILTER](
	[IDX] [int] IDENTITY(1,1) NOT NULL,
	[SERVICE] [nvarchar](10) NOT NULL,
	[SERVICEITEM] [nvarchar](10) NULL,
	[FILTERTEXT] [nvarchar](100) NULL,
	[USEYN] [char](1) NULL,
	[CREATEDATE] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_SYSTEM_LOG]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_SYSTEM_LOG](
	[IDX] [int] IDENTITY(1,1) NOT NULL,
	[TYPE] [nvarchar](5) NOT NULL,
	[EVENT_NAME] [nvarchar](30) NOT NULL,
	[MESSAGE] [nvarchar](max) NULL,
	[CREATE_DATE] [datetime] NOT NULL,
	[CREATER_ID] [varchar](10) NULL,
 CONSTRAINT [PK_TB_ERROR_LOG] PRIMARY KEY CLUSTERED 
(
	[IDX] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_TestOnDemand]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_TestOnDemand](
	[IDX] [int] IDENTITY(1,1) NOT NULL,
	[DemandDate] [datetime] NOT NULL,
	[Company] [nvarchar](20) NOT NULL,
	[TOD_Code] [nvarchar](5) NOT NULL,
	[TOD_Demander] [nvarchar](50) NOT NULL,
	[TOD_Result] [nvarchar](1) NULL,
	[TOD_ResultScript] [nvarchar](max) NULL,
	[CompleteDate] [datetime] NULL,
 CONSTRAINT [PK_TB_TestOnDemand] PRIMARY KEY CLUSTERED 
(
	[IDX] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TB_USER]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_USER](
	[USERID] [nvarchar](10) NOT NULL,
	[USERNAME] [nvarchar](50) NULL,
	[PASSWORD] [nvarchar](1000) NOT NULL,
	[MAILADDRESS] [nvarchar](50) NULL,
	[MOBILEPHONE] [nvarchar](15) NULL,
	[USEYN] [char](1) NOT NULL,
	[CREATE_DATE] [datetime] NULL,
 CONSTRAINT [PK_TB_USER] PRIMARY KEY CLUSTERED 
(
	[USERID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[UFN_Manage_Company_User]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.07.30
-- Description:	사용자-관리회사 목록 Return
-- =============================================
CREATE FUNCTION [dbo].[UFN_Manage_Company_User]
(	
	-- Add the parameters for the function here
	@USERID NVARCHAR(10)
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT T1.[USERID] AS UserID, T1.[COMPANYCODE] AS CompanyCode, T2.[SUB_CODE], T2.[VALUE2] AS [Company], T2.[SORT_SEQ] AS [SortSeq]
	FROM [dbo].[TB_MANAGE_COMPANY_USER] T1 WITH(NOLOCK)
	INNER JOIN [dbo].[TB_COMMON_CODE_SUB] T2 WITH(NOLOCK) ON (T1.[COMPANYCODE] = T2.[SUB_CODE] AND T2.[CLASS_CODE] = '0001')
	WHERE (@USERID = '' OR T1.[USERID] = @USERID) AND T1.[USEYN] = 'Y'
)
GO
/****** Object:  UserDefinedFunction [dbo].[UFN_MonitoringTaskLogs]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.07.30
-- Description:	마지막 수집시간 목록 Return
-- =============================================
CREATE FUNCTION [dbo].[UFN_MonitoringTaskLogs]
(	
	-- Add the parameters for the function here
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT T1.Company, T1.ADService, CONVERT(NVARCHAR(16), MAX(T1.TaskDate), 120) AS LastDate
	FROM [ADSysMon].[dbo].[TB_MonitoringTaskLogs] T1 WITH(NOLOCK)
	INNER JOIN (
		SELECT Company, ADService, MAX(TaskDate) AS EndDate
		FROM [ADSysMon].[dbo].[TB_MonitoringTaskLogs] WITH(NOLOCK)
		WHERE TaskType = 'END'
		GROUP BY Company, ADService
	) AS T2 ON T1.Company = T2.Company AND T1.ADService = T2.ADService AND T1.TaskDate <= T2.EndDate
	WHERE T1.[TaskDate] > DATEADD(MONTH, -1, GETDATE()) AND T1.TaskType = 'BEGIN'
	GROUP BY T1.Company, T1.ADService
)
GO
/****** Object:  View [dbo].[View_MapLocation]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[View_MapLocation]
AS
SELECT T1.[AreaID]
	,T1.[AreaName]
	,T1.[AreaLatitude]
	,T1.[AreaLongitude]
	,T2.[CountryID]
	,T2.[CountryName]
	,T3.[CityID]
	,T3.[CityName]
	,T3.[CityLatitude]
	,T3.[CityLongitude]
	,T4.[CorpID]
	,T4.[CorpName]
	,T4.[CorpLatitude]
	,T4.[CorpLongitude]
FROM [dbo].[TB_MAP_AREA] T1 WITH(NOLOCK)
LEFT OUTER JOIN [dbo].[TB_MAP_COUNTRY] T2 WITH(NOLOCK) ON T2.[AreaID] = T1.[AreaID]
LEFT OUTER JOIN [dbo].[TB_MAP_CITY] T3 WITH(NOLOCK) ON T3.[CountryID] = T2.[CountryID]
LEFT OUTER JOIN [dbo].[TB_MAP_CORP] T4 WITH(NOLOCK) ON T4.[CityID] = T3.[CityID]
GO
/****** Object:  View [dbo].[View_MapServerLocation]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE VIEW [dbo].[View_MapServerLocation]
AS
SELECT T1.[Domain]
	--,T1.[ServiceFlag]
	,T1.[ComputerName]
	,T1.[HostName]
	--,T1.[IPAddress]
	--,T1.[UTCMonitored]
	,T2.[CorpID]
	,T2.[CorpName]
	,T2.[CorpLatitude]
	,T2.[CorpLongitude]
	,T3.[CityID]
	,T3.[CityName]
	,T3.[CityLatitude]
	,T3.[CityLongitude]
	,T4.[CountryID]
	,T4.[CountryName]
	,T5.[AreaID]
	,T5.[AreaName]
	,T5.[AreaLatitude]
	,T5.[AreaLongitude]
FROM (
	SELECT [Domain], [ComputerName], [HostName], [CorpID]
	FROM [dbo].[TB_SERVERS2] WITH(NOLOCK)
	GROUP BY [Domain], [ComputerName], [HostName], [CorpID]
) AS T1
INNER JOIN [dbo].[TB_MAP_CORP] T2 WITH(NOLOCK) ON T1.[CorpID] = T2.[CorpID]
INNER JOIN [dbo].[TB_MAP_CITY] T3 WITH(NOLOCK) ON T2.[CityID] = T3.[CityID] -- City Info
INNER JOIN [dbo].[TB_MAP_COUNTRY] T4 WITH(NOLOCK) ON T3.[CountryID] = T4.[CountryID] -- Country Info
INNER JOIN [dbo].[TB_MAP_AREA] T5 WITH(NOLOCK) ON T4.[AreaID] = T5.[AreaID] -- Area Info
GO
/****** Object:  View [dbo].[View_ServersTable]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[View_ServersTable]
AS
SELECT TOP (100) PERCENT Domain
	,ComputerName
	,IPAddress
FROM dbo.TB_SERVERS
GROUP BY Domain
	,ComputerName
	,IPAddress
GO
ALTER TABLE [dbo].[TB_LGE_NET_ADCSServiceAvailability] ADD  DEFAULT ('') FOR [Subject]
GO
ALTER TABLE [dbo].[TB_LGE_NET_ADCSServiceAvailability] ADD  DEFAULT ('') FOR [Thumbprint]
GO
ALTER TABLE [dbo].[TB_LGE_NET_ADCSServiceAvailability] ADD  DEFAULT ('2024-01-17 04:48:24') FOR [NotAfter]
GO
ALTER TABLE [dbo].[TB_LGE_NET_ADCSServiceAvailability] ADD  DEFAULT ('') FOR [CrlState]
GO
ALTER TABLE [dbo].[TB_LGE_NET_ADCSServiceAvailability] ADD  DEFAULT ('') FOR [CrlPeriod]
GO
ALTER TABLE [dbo].[TB_LGE_NET_ADCSServiceAvailability] ADD  DEFAULT ('') FOR [CrlDeltaPeriod]
GO
ALTER TABLE [dbo].[TB_LGE_NET_DHCPServiceAvailability] ADD  DEFAULT ('') FOR [IsAvailableByClient]
GO
ALTER TABLE [dbo].[TB_MANAGE_COMPANY_USER] ADD  DEFAULT (getdate()) FOR [CREATE_DATE]
GO
ALTER TABLE [dbo].[TB_MANAGE_COMPANY_USER] ADD  DEFAULT ('Y') FOR [USEYN]
GO
ALTER TABLE [dbo].[TB_MonitoringTaskLogs] ADD  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[TB_ProblemManagement] ADD  DEFAULT ('') FOR [ProblemScript]
GO
ALTER TABLE [dbo].[TB_ProblemManagement] ADD  DEFAULT ('NotStarted') FOR [ManageStatus]
GO
ALTER TABLE [dbo].[TB_ProblemManagement] ADD  DEFAULT ('') FOR [Manager]
GO
ALTER TABLE [dbo].[TB_ProblemManagement] ADD  DEFAULT ('') FOR [ManageScript]
GO
ALTER TABLE [dbo].[TB_ProblemManagement] ADD  DEFAULT (getdate()) FOR [ManageDate]
GO
ALTER TABLE [dbo].[TB_SMS_FILTER] ADD  CONSTRAINT [DF_TB_SMS_FILTER_CREATEDATE]  DEFAULT (getutcdate()) FOR [CREATEDATE]
GO
ALTER TABLE [dbo].[TB_TestOnDemand] ADD  DEFAULT (getdate()) FOR [DemandDate]
GO
ALTER TABLE [dbo].[TB_TestOnDemand] ADD  DEFAULT ('N') FOR [TOD_Result]
GO
ALTER TABLE [dbo].[TB_USER] ADD  DEFAULT ('Y') FOR [USEYN]
GO
ALTER TABLE [dbo].[TB_USER] ADD  DEFAULT (getdate()) FOR [CREATE_DATE]
GO
ALTER TABLE [dbo].[TB_EVENTID]  WITH CHECK ADD  CONSTRAINT [FK_TB_EXCEPTED_EVENT_USERID] FOREIGN KEY([CreateUserID])
REFERENCES [dbo].[TB_USER] ([USERID])
GO
ALTER TABLE [dbo].[TB_EVENTID] CHECK CONSTRAINT [FK_TB_EXCEPTED_EVENT_USERID]
GO
ALTER TABLE [dbo].[TB_MAP_CITY]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAP_CITY_COUNTRYID] FOREIGN KEY([CountryID])
REFERENCES [dbo].[TB_MAP_COUNTRY] ([CountryID])
GO
ALTER TABLE [dbo].[TB_MAP_CITY] CHECK CONSTRAINT [FK_TB_MAP_CITY_COUNTRYID]
GO
ALTER TABLE [dbo].[TB_MAP_CORP]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAP_CORP_CITYID] FOREIGN KEY([CityID])
REFERENCES [dbo].[TB_MAP_CITY] ([CityID])
GO
ALTER TABLE [dbo].[TB_MAP_CORP] CHECK CONSTRAINT [FK_TB_MAP_CORP_CITYID]
GO
ALTER TABLE [dbo].[TB_MAP_COUNTRY]  WITH CHECK ADD  CONSTRAINT [FK_TB_MAP_COUNTRY_AREAID] FOREIGN KEY([AreaID])
REFERENCES [dbo].[TB_MAP_AREA] ([AreaID])
GO
ALTER TABLE [dbo].[TB_MAP_COUNTRY] CHECK CONSTRAINT [FK_TB_MAP_COUNTRY_AREAID]
GO
ALTER TABLE [dbo].[TB_SERVERS]  WITH CHECK ADD  CONSTRAINT [FK_TB_SERVERS_CORPID] FOREIGN KEY([CorpID])
REFERENCES [dbo].[TB_MAP_CORP] ([CorpID])
GO
ALTER TABLE [dbo].[TB_SERVERS] CHECK CONSTRAINT [FK_TB_SERVERS_CORPID]
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_ADCSEnrollmentPolicy]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_ADCSEnrollmentPolicy]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@CAName NVARCHAR(30)
	,@DNSName NVARCHAR(30)
	,@CAType NVARCHAR(200)
	,@CertEnrollPolicyTemplates NVARCHAR(max)
	,@CATemplates NVARCHAR(max)
	,@UTCMonitored DATETIME
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_ADCSEnrollmentPolicy] (
		[ComputerName]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[CAName]
		,[DNSName]
		,[CAType]
		,[CertEnrollPolicyTemplates]
		,[CATemplates]
		,[UTCMonitored]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@CAName
		,@DNSName
		,@CAType
		,@CertEnrollPolicyTemplates
		,@CATemplates
		,@UTCMonitored
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_ADCSServiceAvailability]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_ADCSServiceAvailability]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@CAName NVARCHAR(30)
	,@DNSName NVARCHAR(30)
	,@CAType NVARCHAR(200)
	,@PingAdmin NVARCHAR(200)
	,@Ping NVARCHAR(200)
	,@UTCMonitored DATETIME
	,@CrlPublishStatus NVARCHAR(MAX)
	,@DeltaCrlPublishStatus NVARCHAR(MAX)
	,@IsError NVARCHAR(10)
	,@Subject NVARCHAR(200) = ''
	,@Thumbprint NVARCHAR(100) = ''
	,@NotAfter DATETIME = '2024-01-17 04:48:24'
	,@CrlState NVARCHAR(20) = ''
	,@CrlPeriod NVARCHAR(20) = ''
	,@CrlDeltaPeriod NVARCHAR(20) = ''
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_ADCSServiceAvailability] (
		[ComputerName]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[CAName]
		,[DNSName]
		,[CAType]
		,[PingAdmin]
		,[Ping]
		,[UTCMonitored]
		,[CrlPublishStatus]
		,[DeltaCrlPublishStatus]
		,[IsError]
		,[Subject]
		,[Thumbprint]
		,[NotAfter]
		,[CrlState]
		,[CrlPeriod]
		,[CrlDeltaPeriod]
		)
	VALUES (
		@ComputerName
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@CAName
		,@DNSName
		,@CAType
		,@PingAdmin
		,@Ping
		,@UTCMonitored
		,@CrlPublishStatus
		,@DeltaCrlPublishStatus
		,@IsError
		,@Subject
		,@Thumbprint
		,@NotAfter
		,@CrlState
		,@CrlPeriod
		,@CrlDeltaPeriod
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_ADDSAdvertisement]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_ADDSAdvertisement]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@IsGlobalCatalog NVARCHAR(10)
	,@IsRODC NVARCHAR(10)
	,@OperationMasterRoles NVARCHAR(max)
	,@OperatingSystemServicePack NVARCHAR(30)
	,@UTCMonitored DATETIME
	,@OperatingSystem NVARCHAR(50)
	,@dcdiag_advertising NVARCHAR(max)
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_ADDSAdvertisement] (
		[ComputerName]
		,[IsGlobalCatalog]
		,[IsRODC]
		,[OperationMasterRoles]
		,[OperatingSystemServicePack]
		,[UTCMonitored]
		,[OperatingSystem]
		,[dcdiag_advertising]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@IsGlobalCatalog
		,@IsRODC
		,@OperationMasterRoles
		,@OperatingSystemServicePack
		,@UTCMonitored
		,@OperatingSystem
		,@dcdiag_advertising
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_ADDSReplication]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_ADDSReplication]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@repadmin NVARCHAR(300)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@IsGlobalCatalog NVARCHAR(10)
	,@IsRODC NVARCHAR(10)
	,@OperationMasterRoles NVARCHAR(max)
	,@UTCMonitored DATETIME
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_ADDSReplication] (
		[ComputerName]
		,[repadmin]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[IsGlobalCatalog]
		,[IsRODC]
		,[OperationMasterRoles]
		,[UTCMonitored]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@repadmin
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@IsGlobalCatalog
		,@IsRODC
		,@OperationMasterRoles
		,@UTCMonitored
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_ADDSRepository]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_ADDSRepository]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@SysvolPath NVARCHAR(200)
	,@LogFileSize NVARCHAR(20)
	,@IsGlobalCatalog NVARCHAR(20)
	,@DataBaseSize NVARCHAR(200)
	,@IsRODC NVARCHAR(20)
	,@LogFilePath NVARCHAR(200)
	,@DataBasePath NVARCHAR(200)
	,@DatabaseDriveFreeSpace NVARCHAR(50)
	,@OperatingSystemServicePack NVARCHAR(50)
	,@UTCMonitored DATETIME
	,@OperatingSystem NVARCHAR(200)
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_ADDSRepository] (
		[ComputerName]
		,[SysvolPath]
		,[LogFileSize]
		,[IsGlobalCatalog]
		,[DataBaseSize]
		,[IsRODC]
		,[LogFilePath]
		,[DataBasePath]
		,[DatabaseDriveFreeSpace]
		,[OperatingSystemServicePack]
		,[UTCMonitored]
		,[OperatingSystem]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@SysvolPath
		,@LogFileSize
		,@IsGlobalCatalog
		,@DataBaseSize
		,@IsRODC
		,@LogFilePath
		,@DataBasePath
		,@DatabaseDriveFreeSpace
		,@OperatingSystemServicePack
		,@UTCMonitored
		,@OperatingSystem
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_ADDSSysvolShares]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_ADDSSysvolShares]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@frssysvol NVARCHAR(max)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@IsGlobalCatalog NVARCHAR(10)
	,@IsRODC NVARCHAR(10)
	,@OperationMasterRoles NVARCHAR(max)
	,@UTCMonitored DATETIME
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_ADDSSysvolShares] (
		[ComputerName]
		,[frssysvol]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[IsGlobalCatalog]
		,[IsRODC]
		,[OperationMasterRoles]
		,[UTCMonitored]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@frssysvol
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@IsGlobalCatalog
		,@IsRODC
		,@OperationMasterRoles
		,@UTCMonitored
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_ADDSTopology]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_ADDSTopology]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@adtopology NVARCHAR(max)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@IsGlobalCatalog NVARCHAR(10)
	,@IsRODC NVARCHAR(10)
	,@OperationMasterRoles NVARCHAR(max)
	,@UTCMonitored DATETIME
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_ADDSTopology] (
		[ComputerName]
		,[adtopology]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[IsGlobalCatalog]
		,[IsRODC]
		,[OperationMasterRoles]
		,[UTCMonitored]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@adtopology
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@IsGlobalCatalog
		,@IsRODC
		,@OperationMasterRoles
		,@UTCMonitored
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_ADDSW32TimeSync]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_ADDSW32TimeSync]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@LastSuccessfulSyncedTime NVARCHAR(50)
	,@TimeSource NVARCHAR(50)
	,@IsGlobalCatalog NVARCHAR(20)
	,@IsRODC NVARCHAR(20)
	,@OperationMasterRoles NVARCHAR(max)
	,@OperatingSystemServicePack NVARCHAR(50)
	,@UTCMonitored DATETIME
	,@OperatingSystem NVARCHAR(200)
	,@IsError [nvarchar] (10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_ADDSW32TimeSync] (
		[ComputerName]
		,[LastSuccessfulSyncedTime]
		,[TimeSource]
		,[IsGlobalCatalog]
		,[IsRODC]
		,[OperationMasterRoles]
		,[OperatingSystemServicePack]
		,[UTCMonitored]
		,[OperatingSystem]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@LastSuccessfulSyncedTime
		,@TimeSource
		,@IsGlobalCatalog
		,@IsRODC
		,@OperationMasterRoles
		,@OperatingSystemServicePack
		,@UTCMonitored
		,@OperatingSystem
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_CONNECTIVITY]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_CONNECTIVITY]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@CanPing NVARCHAR(5)
	,@CanPort135 NVARCHAR(5) = NULL
	,@CanPort5985 NVARCHAR(5) = NULL
	,@UTCMonitored DATETIME
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_CONNECTIVITY] (
		[ComputerName]
		,[CanPing]
		,[CanPort135]
		,[CanPort5985]
		,[UTCMonitored]
		)
	VALUES (
		@ComputerName
		,@CanPing
		,@CanPort135
		,@CanPort5985
		,@UTCMonitored
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_DHCPServiceAvailability]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_DHCPServiceAvailability]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@serverstatus NVARCHAR(300)
	,@UTCMonitored DATETIME
	,@DatabaseName NVARCHAR(100)
	,@DatabasePath NVARCHAR(100)
	,@DatabaseBackupPath NVARCHAR(100)
	,@DatabaseBackupInterval NVARCHAR(20)
	,@DatabaseLoggingFlag NVARCHAR(20)
	,@DatabaseRestoreFlag NVARCHAR(20)
	,@DatabaseCleanupInterval NVARCHAR(20)
	,@IsError NVARCHAR(10)
	,@IsAvailableByClient NVARCHAR(10) = ''
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_DHCPServiceAvailability] (
		[ComputerName]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[serverstatus]
		,[UTCMonitored]
		,[DatabaseName]
		,[DatabasePath]
		,[DatabaseBackupPath]
		,[DatabaseBackupInterval]
		,[DatabaseLoggingFlag]
		,[DatabaseRestoreFlag]
		,[DatabaseCleanupInterval]
		,[IsError]
		,[IsAvailableByClient]
		)
	VALUES (
		@ComputerName
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@serverstatus
		,@UTCMonitored
		,@DatabaseName
		,@DatabasePath
		,@DatabaseBackupPath
		,@DatabaseBackupInterval
		,@DatabaseLoggingFlag
		,@DatabaseRestoreFlag
		,@DatabaseCleanupInterval
		,@IsError
		,@IsAvailableByClient
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_DNSServiceAvailability]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_DNSServiceAvailability]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@dnsstatus NVARCHAR(300)
	,@UTCMonitored DATETIME
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_DNSServiceAvailability] (
		[ComputerName]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[dnsstatus]
		,[UTCMonitored]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@dnsstatus
		,@UTCMonitored
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_EVENT]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_EVENT]
	-- Add the parameters for the stored procedure here
	@LogName NVARCHAR(30)
	,@TimeCreated DATETIME
	,@Id NVARCHAR(30)
	,@ProviderName NVARCHAR(100)
	,@LevelDisplayName NVARCHAR(30)
	,@Message NVARCHAR(max)
	,@ComputerName NVARCHAR(100)
	,@UTCMonitored DATETIME
	,@ServiceFlag NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_EVENT] (
		[LogName]
		,[TimeCreated]
		,[Id]
		,[ProviderName]
		,[LevelDisplayName]
		,[Message]
		,[ComputerName]
		,[UTCMonitored]
		,[ServiceFlag]
		)
	VALUES (
		@LogName
		,@TimeCreated
		,@Id
		,@ProviderName
		,@LevelDisplayName
		,@Message
		,@ComputerName
		,@UTCMonitored
		,@ServiceFlag
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_PERFORMANCE]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_PERFORMANCE]
	-- Add the parameters for the stored procedure here
	@TimeStamp DATETIME
	,@TimeStamp100NSec NVARCHAR(18)
	,@Value FLOAT
	,@Path NVARCHAR(100)
	,@InstanceName NVARCHAR(100)
	,@ComputerName NVARCHAR(100)
	,@UTCMonitored DATETIME
	,@ServiceFlag NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_PERFORMANCE] (
		[TimeStamp]
		,[TimeStamp100NSec]
		,[Value]
		,[Path]
		,[InstanceName]
		,[ComputerName]
		,[UTCMonitored]
		,[ServiceFlag]
		)
	VALUES (
		@TimeStamp
		,@TimeStamp100NSec
		,@Value
		,@Path
		,@InstanceName
		,@ComputerName
		,@UTCMonitored
		,@ServiceFlag
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_RADIUSServiceAvailability]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_RADIUSServiceAvailability]
	-- Add the parameters for the stored procedure here
	@LogName NVARCHAR(30)
	,@TimeCreated DATETIME
	,@Id NVARCHAR(30)
	,@ProviderName NVARCHAR(30)
	,@LevelDisplayName NVARCHAR(30)
	,@Message NVARCHAR(max)
	,@ComputerName NVARCHAR(100)
	,@UTCMonitored DATETIME
	,@ServiceFlag NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_RADIUSServiceAvailability] (
		[LogName]
		,[TimeCreated]
		,[Id]
		,[ProviderName]
		,[LevelDisplayName]
		,[Message]
		,[ComputerName]
		,[UTCMonitored]
		,[ServiceFlag]
		)
	VALUES (
		@LogName
		,@TimeCreated
		,@Id
		,@ProviderName
		,@LevelDisplayName
		,@Message
		,@ComputerName
		,@UTCMonitored
		,@ServiceFlag
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_dotnetsoft_co_kr_SERVICE]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_dotnetsoft_co_kr_SERVICE]
	-- Add the parameters for the stored procedure here
	@ServiceStatus NVARCHAR(30)
	,@Name NVARCHAR(30)
	,@DisplayName NVARCHAR(50)
	,@ComputerName NVARCHAR(100)
	,@UTCMonitored DATETIME
	,@ServiceFlag NVARCHAR(10)
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_dotnetsoft_co_kr_SERVICE] (
		[ServiceStatus]
		,[Name]
		,[DisplayName]
		,[ComputerName]
		,[UTCMonitored]
		,[ServiceFlag]
		,[IsError]
		)
	VALUES (
		@ServiceStatus
		,@Name
		,@DisplayName
		,@ComputerName
		,@UTCMonitored
		,@ServiceFlag
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_ADCSEnrollmentPolicy]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_ADCSEnrollmentPolicy]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@CAName NVARCHAR(30)
	,@DNSName NVARCHAR(30)
	,@CAType NVARCHAR(200)
	,@CertEnrollPolicyTemplates NVARCHAR(max)
	,@CATemplates NVARCHAR(max)
	,@UTCMonitored DATETIME
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_ADCSEnrollmentPolicy] (
		[ComputerName]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[CAName]
		,[DNSName]
		,[CAType]
		,[CertEnrollPolicyTemplates]
		,[CATemplates]
		,[UTCMonitored]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@CAName
		,@DNSName
		,@CAType
		,@CertEnrollPolicyTemplates
		,@CATemplates
		,@UTCMonitored
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_ADCSServiceAvailability]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_ADCSServiceAvailability]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@CAName NVARCHAR(30)
	,@DNSName NVARCHAR(30)
	,@CAType NVARCHAR(200)
	,@PingAdmin NVARCHAR(200)
	,@Ping NVARCHAR(200)
	,@UTCMonitored DATETIME
	,@CrlPublishStatus NVARCHAR(MAX)
	,@DeltaCrlPublishStatus NVARCHAR(MAX)
	,@IsError NVARCHAR(10)
	,@Subject NVARCHAR(200) = ''
	,@Thumbprint NVARCHAR(100) = ''
	,@NotAfter DATETIME = '2024-01-17 04:48:24'
	,@CrlState NVARCHAR(20) = ''
	,@CrlPeriod NVARCHAR(20) = ''
	,@CrlDeltaPeriod NVARCHAR(20) = ''
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_ADCSServiceAvailability] (
		[ComputerName]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[CAName]
		,[DNSName]
		,[CAType]
		,[PingAdmin]
		,[Ping]
		,[UTCMonitored]
		,[CrlPublishStatus]
		,[DeltaCrlPublishStatus]
		,[IsError]
		,[Subject]
		,[Thumbprint]
		,[NotAfter]
		,[CrlState]
		,[CrlPeriod]
		,[CrlDeltaPeriod]
		)
	VALUES (
		@ComputerName
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@CAName
		,@DNSName
		,@CAType
		,@PingAdmin
		,@Ping
		,@UTCMonitored
		,@CrlPublishStatus
		,@DeltaCrlPublishStatus
		,@IsError
		,@Subject
		,@Thumbprint
		,@NotAfter
		,@CrlState
		,@CrlPeriod
		,@CrlDeltaPeriod
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_ADDSAdvertisement]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_ADDSAdvertisement]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@IsGlobalCatalog NVARCHAR(10)
	,@IsRODC NVARCHAR(10)
	,@OperationMasterRoles NVARCHAR(max)
	,@OperatingSystemServicePack NVARCHAR(30)
	,@UTCMonitored DATETIME
	,@OperatingSystem NVARCHAR(50)
	,@dcdiag_advertising NVARCHAR(max)
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_ADDSAdvertisement] (
		[ComputerName]
		,[IsGlobalCatalog]
		,[IsRODC]
		,[OperationMasterRoles]
		,[OperatingSystemServicePack]
		,[UTCMonitored]
		,[OperatingSystem]
		,[dcdiag_advertising]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@IsGlobalCatalog
		,@IsRODC
		,@OperationMasterRoles
		,@OperatingSystemServicePack
		,@UTCMonitored
		,@OperatingSystem
		,@dcdiag_advertising
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_ADDSReplication]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_ADDSReplication]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@repadmin NVARCHAR(300)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@IsGlobalCatalog NVARCHAR(10)
	,@IsRODC NVARCHAR(10)
	,@OperationMasterRoles NVARCHAR(max)
	,@UTCMonitored DATETIME
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_ADDSReplication] (
		[ComputerName]
		,[repadmin]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[IsGlobalCatalog]
		,[IsRODC]
		,[OperationMasterRoles]
		,[UTCMonitored]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@repadmin
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@IsGlobalCatalog
		,@IsRODC
		,@OperationMasterRoles
		,@UTCMonitored
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_ADDSRepository]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_ADDSRepository]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@SysvolPath NVARCHAR(200)
	,@LogFileSize NVARCHAR(20)
	,@IsGlobalCatalog NVARCHAR(20)
	,@DataBaseSize NVARCHAR(200)
	,@IsRODC NVARCHAR(20)
	,@LogFilePath NVARCHAR(200)
	,@DataBasePath NVARCHAR(200)
	,@DatabaseDriveFreeSpace NVARCHAR(50)
	,@OperatingSystemServicePack NVARCHAR(50)
	,@UTCMonitored DATETIME
	,@OperatingSystem NVARCHAR(200)
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_ADDSRepository] (
		[ComputerName]
		,[SysvolPath]
		,[LogFileSize]
		,[IsGlobalCatalog]
		,[DataBaseSize]
		,[IsRODC]
		,[LogFilePath]
		,[DataBasePath]
		,[DatabaseDriveFreeSpace]
		,[OperatingSystemServicePack]
		,[UTCMonitored]
		,[OperatingSystem]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@SysvolPath
		,@LogFileSize
		,@IsGlobalCatalog
		,@DataBaseSize
		,@IsRODC
		,@LogFilePath
		,@DataBasePath
		,@DatabaseDriveFreeSpace
		,@OperatingSystemServicePack
		,@UTCMonitored
		,@OperatingSystem
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_ADDSSysvolShares]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_ADDSSysvolShares]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@frssysvol NVARCHAR(max)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@IsGlobalCatalog NVARCHAR(10)
	,@IsRODC NVARCHAR(10)
	,@OperationMasterRoles NVARCHAR(max)
	,@UTCMonitored DATETIME
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_ADDSSysvolShares] (
		[ComputerName]
		,[frssysvol]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[IsGlobalCatalog]
		,[IsRODC]
		,[OperationMasterRoles]
		,[UTCMonitored]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@frssysvol
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@IsGlobalCatalog
		,@IsRODC
		,@OperationMasterRoles
		,@UTCMonitored
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_ADDSTopology]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_ADDSTopology]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@adtopology NVARCHAR(max)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@IsGlobalCatalog NVARCHAR(10)
	,@IsRODC NVARCHAR(10)
	,@OperationMasterRoles NVARCHAR(max)
	,@UTCMonitored DATETIME
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_ADDSTopology] (
		[ComputerName]
		,[adtopology]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[IsGlobalCatalog]
		,[IsRODC]
		,[OperationMasterRoles]
		,[UTCMonitored]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@adtopology
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@IsGlobalCatalog
		,@IsRODC
		,@OperationMasterRoles
		,@UTCMonitored
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_ADDSW32TimeSync]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_ADDSW32TimeSync]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@LastSuccessfulSyncedTime NVARCHAR(50)
	,@TimeSource NVARCHAR(50)
	,@IsGlobalCatalog NVARCHAR(20)
	,@IsRODC NVARCHAR(20)
	,@OperationMasterRoles NVARCHAR(max)
	,@OperatingSystemServicePack NVARCHAR(50)
	,@UTCMonitored DATETIME
	,@OperatingSystem NVARCHAR(200)
	,@IsError [nvarchar] (10)
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_ADDSW32TimeSync] (
		[ComputerName]
		,[LastSuccessfulSyncedTime]
		,[TimeSource]
		,[IsGlobalCatalog]
		,[IsRODC]
		,[OperationMasterRoles]
		,[OperatingSystemServicePack]
		,[UTCMonitored]
		,[OperatingSystem]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@LastSuccessfulSyncedTime
		,@TimeSource
		,@IsGlobalCatalog
		,@IsRODC
		,@OperationMasterRoles
		,@OperatingSystemServicePack
		,@UTCMonitored
		,@OperatingSystem
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_CONNECTIVITY]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_CONNECTIVITY]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@CanPing NVARCHAR(5)
	,@CanPort135 NVARCHAR(5) = NULL
	,@CanPort5985 NVARCHAR(5) = NULL
	,@UTCMonitored DATETIME
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_CONNECTIVITY] (
		[ComputerName]
		,[CanPing]
		,[CanPort135]
		,[CanPort5985]
		,[UTCMonitored]
		)
	VALUES (
		@ComputerName
		,@CanPing
		,@CanPort135
		,@CanPort5985
		,@UTCMonitored
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_DHCPServiceAvailability]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_DHCPServiceAvailability]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@serverstatus NVARCHAR(300)
	,@UTCMonitored DATETIME
	,@DatabaseName NVARCHAR(100)
	,@DatabasePath NVARCHAR(100)
	,@DatabaseBackupPath NVARCHAR(100)
	,@DatabaseBackupInterval NVARCHAR(20)
	,@DatabaseLoggingFlag NVARCHAR(20)
	,@DatabaseRestoreFlag NVARCHAR(20)
	,@DatabaseCleanupInterval NVARCHAR(20)
	,@IsError NVARCHAR(10)
	,@IsAvailableByClient NVARCHAR(10) = ''
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_DHCPServiceAvailability] (
		[ComputerName]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[serverstatus]
		,[UTCMonitored]
		,[DatabaseName]
		,[DatabasePath]
		,[DatabaseBackupPath]
		,[DatabaseBackupInterval]
		,[DatabaseLoggingFlag]
		,[DatabaseRestoreFlag]
		,[DatabaseCleanupInterval]
		,[IsError]
		,[IsAvailableByClient]
		)
	VALUES (
		@ComputerName
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@serverstatus
		,@UTCMonitored
		,@DatabaseName
		,@DatabasePath
		,@DatabaseBackupPath
		,@DatabaseBackupInterval
		,@DatabaseLoggingFlag
		,@DatabaseRestoreFlag
		,@DatabaseCleanupInterval
		,@IsError
		,@IsAvailableByClient
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_DNSServiceAvailability]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_DNSServiceAvailability]
	-- Add the parameters for the stored procedure here
	@ComputerName NVARCHAR(100)
	,@OperatingSystem NVARCHAR(100)
	,@OperatingSystemServicePack NVARCHAR(100)
	,@dnsstatus NVARCHAR(300)
	,@UTCMonitored DATETIME
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_DNSServiceAvailability] (
		[ComputerName]
		,[OperatingSystem]
		,[OperatingSystemServicePack]
		,[dnsstatus]
		,[UTCMonitored]
		,[IsError]
		)
	VALUES (
		@ComputerName
		,@OperatingSystem
		,@OperatingSystemServicePack
		,@dnsstatus
		,@UTCMonitored
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_EVENT]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_EVENT]
	-- Add the parameters for the stored procedure here
	@LogName NVARCHAR(30)
	,@TimeCreated DATETIME
	,@Id NVARCHAR(30)
	,@ProviderName NVARCHAR(100)
	,@LevelDisplayName NVARCHAR(30)
	,@Message NVARCHAR(max)
	,@ComputerName NVARCHAR(100)
	,@UTCMonitored DATETIME
	,@ServiceFlag NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_EVENT] (
		[LogName]
		,[TimeCreated]
		,[Id]
		,[ProviderName]
		,[LevelDisplayName]
		,[Message]
		,[ComputerName]
		,[UTCMonitored]
		,[ServiceFlag]
		)
	VALUES (
		@LogName
		,@TimeCreated
		,@Id
		,@ProviderName
		,@LevelDisplayName
		,@Message
		,@ComputerName
		,@UTCMonitored
		,@ServiceFlag
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_PERFORMANCE]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_PERFORMANCE]
	-- Add the parameters for the stored procedure here
	@TimeStamp DATETIME
	,@TimeStamp100NSec NVARCHAR(18)
	,@Value FLOAT
	,@Path NVARCHAR(100)
	,@InstanceName NVARCHAR(100)
	,@ComputerName NVARCHAR(100)
	,@UTCMonitored DATETIME
	,@ServiceFlag NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_PERFORMANCE] (
		[TimeStamp]
		,[TimeStamp100NSec]
		,[Value]
		,[Path]
		,[InstanceName]
		,[ComputerName]
		,[UTCMonitored]
		,[ServiceFlag]
		)
	VALUES (
		@TimeStamp
		,@TimeStamp100NSec
		,@Value
		,@Path
		,@InstanceName
		,@ComputerName
		,@UTCMonitored
		,@ServiceFlag
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_RADIUSServiceAvailability]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_RADIUSServiceAvailability]
 @LogName nvarchar(30)
,@TimeCreated datetime
,@Id nvarchar(30)
,@ProviderName nvarchar(100)
,@LevelDisplayName nvarchar(30)
,@Message nvarchar(max)
,@computername nvarchar(100)
,@UTCMonitored datetime
,@ServiceFlag nvarchar(10)
AS
BEGIN
INSERT INTO [dbo].[TB_LGE_NET_RADIUSServiceAvailability]
   ([LogName]
   ,[TimeCreated]
   ,[Id]
   ,[ProviderName]
   ,[LevelDisplayName]
   ,[Message]
   ,[ComputerName]
   ,[UTCMonitored]
   ,[ServiceFlag])
 VALUES
   (@LogName,
@TimeCreated,
@Id,
@ProviderName,
@LevelDisplayName,
@Message,
@ComputerName,
@UTCMonitored,
@ServiceFlag)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_LGE_NET_SERVICE]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_LGE_NET_SERVICE]
	-- Add the parameters for the stored procedure here
	@ServiceStatus NVARCHAR(30)
	,@Name NVARCHAR(30)
	,@DisplayName NVARCHAR(50)
	,@ComputerName NVARCHAR(100)
	,@UTCMonitored DATETIME
	,@ServiceFlag NVARCHAR(10)
	,@IsError NVARCHAR(10)
AS
BEGIN
	INSERT INTO [dbo].[TB_LGE_NET_SERVICE] (
		[ServiceStatus]
		,[Name]
		,[DisplayName]
		,[ComputerName]
		,[UTCMonitored]
		,[ServiceFlag]
		,[IsError]
		)
	VALUES (
		@ServiceStatus
		,@Name
		,@DisplayName
		,@ComputerName
		,@UTCMonitored
		,@ServiceFlag
		,@IsError
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_ProblemManagement]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_ProblemManagement]
	-- Add the parameters for the stored procedure here
	@MonitoredTime DATETIME
	,@Company NVARCHAR(20)
	,@ADService NVARCHAR(10)
	,@ServiceItem NVARCHAR(50)
	,@ComputerName NVARCHAR(100)
	,@ProblemScript NVARCHAR(max)
AS
BEGIN
	INSERT INTO [dbo].[TB_ProblemManagement] (
		[MonitoredTime]
		,[Company]
		,[ADService]
		,[ServiceItem]
		,[ComputerName]
		,[ProblemScript]
		)
	VALUES (
		@MonitoredTime
		,@Company
		,@ADService
		,@ServiceItem
		,@ComputerName
		,@ProblemScript
		)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_SERVERS]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IF_SERVERS]
	-- Add the parameters for the stored procedure here
	@Domain NVARCHAR(30)
	,@ServiceFlag NVARCHAR(10)
	,@ComputerName NVARCHAR(100)
	,@IPAddress NVARCHAR(15)
	,@UTCMonitored DATETIME
AS
BEGIN
	--INSERT INTO [dbo].[TB_SERVERS] (
	--	[Domain]
	--	,[ServiceFlag]
	--	,[ComputerName]
	--	,[IPAddress]
	--	,[UTCMonitored]
	--	)
	--VALUES (
	--	@Domain
	--	,@ServiceFlag
	--	,@ComputerName
	--	,@IPAddress
	--	,@UTCMonitored
	--	)
	-- 2018.08.14 mwjin7@dotnetsoft.co.kr PowerShell V2 => V3 전환과정 상의 이유로 TB_SERVERS2  생성하고 사용
	INSERT INTO [dbo].[TB_SERVERS2]
           ([Domain]
           ,[ServiceFlag]
           ,[ComputerName]
           ,[HostName]
           ,[FQDN]
           ,[IPAddress]
           ,[UTCMonitored]
           ,[CorpID])
     VALUES
           (@Domain
           ,@ServiceFlag
           ,@ComputerName + '.' + @Domain
           ,@ComputerName
           ,@ComputerName + '.' + @Domain
           ,@IPAddress
           ,@UTCMonitored
           ,NULL)
END
GO
/****** Object:  StoredProcedure [dbo].[IF_USP_INSERT_MMS_MSG]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* =============================================
	[IF_USP_INSERT_MMS_MSG]
	  
 
	DELETE FROM dbo.MMS_MSG

 	UPDATE A SET
		SMSSendYN = 'N'
	FROM dbo.TB_ProblemManagement A
	  
	EXEC [dbo].[IF_USP_INSERT_MMS_MSG]  
-- =============================================*/
CREATE PROCEDURE [dbo].[IF_USP_INSERT_MMS_MSG]
AS
BEGIN
	DECLARE @COMPANYCODE NVARCHAR(20)
		,@ADSERVICE NVARCHAR(16)
		,@DATETIME DATETIME
		,@SMS_SUBJECT NVARCHAR(120)
		,@SMS_MSG NVARCHAR(160)
		,@SENDER_PHONE_NUMBER NVARCHAR(20)
	DECLARE @mCompany NVARCHAR(20)
		,@mADService NVARCHAR(10)
		,@mServiceitem NVARCHAR(50)
		,@mComputerName NVARCHAR(100)
		,@mCnt INT
		,@pScript NVARCHAR(4000)
		,@mMonitoredTime DATETIME
	DECLARE @mFServiceItem NVARCHAR(10)
		,@mFilterText NVARCHAR(100)

	SET @SENDER_PHONE_NUMBER = '0220995933'

	CREATE TABLE #TMP_MMS_MSG (
		COMPANY NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS
		,SUBJECT VARCHAR(120) -- Á¦¸ñ
		,PHONE VARCHAR(15) -- ¼öÁøÀÚ¹øÈ£
		,CALLBACK VARCHAR(15) -- ¼Û½ÅÀÚ ¹øÈ£
		,STATUS VARCHAR(2) DEFAULT '0' -- Àü¼Û»óÅÂ ( ´ë±â : 0, ¿Ï·á : 2, °á°ú¼ö½Å : 3 )			 
		,REQDATE DATETIME -- ¸Þ½ÃÁö¸¦ Àü¼ÛÇÒ ½Ã°£
		,MSG VARCHAR(4000) COLLATE Korean_Wansung_CI_AS -- Àü¼ÛÇÒ ¸Þ½ÃÁö
		,[TYPE] VARCHAR(2) NOT NULL DEFAULT '0'
		)

	CREATE TABLE #TMP_SEND_SEQ (SEQ INT)

	DECLARE SMS_CURSOR CURSOR
	FOR
	SELECT VALUE2
	FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB]
	WHERE CLASS_CODE = '0001'
	ORDER BY SORT_SEQ ASC

	OPEN SMS_CURSOR

	FETCH NEXT
	FROM SMS_CURSOR
	INTO @COMPANYCODE

	-- »çÀÌÆ® Á¤º¸ Á¶È¸ Loop ¹®
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		PRINT @COMPANYCODE

		-- ADDS Service SMS Data Filter
		SET @ADSERVICE = 'ADDS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		--SET @DATETIME = '2015-01-23 02:33:01.000'
		DECLARE CURSOR_ADDS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_ADDS_FILTER

		FETCH NEXT
		FROM CURSOR_ADDS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_ADDS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime --  COUNT(*) as Cnt 
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					)
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				--GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_ADDS

			FETCH NEXT
			FROM CURSOR_ADDS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime --, @mCnt			

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				-- mms -> sms message change
				--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_ADDS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_ADDS

			DEALLOCATE CURSOR_ADDS

			FETCH NEXT
			FROM CURSOR_ADDS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_ADDS_FILTER

		DEALLOCATE CURSOR_ADDS_FILTER

		-- ADCS Service SMS Data Filter
		SET @ADSERVICE = 'ADCS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_ADCS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_ADCS_FILTER

		FETCH NEXT
		FROM CURSOR_ADCS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_ADCS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				-- GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_ADCS

			FETCH NEXT
			FROM CURSOR_ADCS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				-- mms -> sms message change
				--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_ADCS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_ADCS

			DEALLOCATE CURSOR_ADCS

			FETCH NEXT
			FROM CURSOR_ADCS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_ADCS_FILTER

		DEALLOCATE CURSOR_ADCS_FILTER

		-- DNS Service SMS Data Filter
		SET @ADSERVICE = 'DNS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_DNS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_DNS_FILTER

		FETCH NEXT
		FROM CURSOR_DNS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_DNS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				-- GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_DNS

			FETCH NEXT
			FROM CURSOR_DNS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				-- mms -> sms message change
				--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_DNS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_DNS

			DEALLOCATE CURSOR_DNS

			FETCH NEXT
			FROM CURSOR_DNS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_DNS_FILTER

		DEALLOCATE CURSOR_DNS_FILTER

		-- DHCP Service SMS Data Filter
		SET @ADSERVICE = 'DHCP'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_DHCP_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_DHCP_FILTER

		FETCH NEXT
		FROM CURSOR_DHCP_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_DHCP CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				--	 GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_DHCP

			FETCH NEXT
			FROM CURSOR_DHCP
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				-- mms -> sms message change
				--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_DHCP
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_DHCP

			DEALLOCATE CURSOR_DHCP

			FETCH NEXT
			FROM CURSOR_DHCP_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_DHCP_FILTER

		DEALLOCATE CURSOR_DHCP_FILTER

		-- RADIUS Service SMS Data Filter
		SET @ADSERVICE = 'RADIUS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_RADIUS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_RADIUS_FILTER

		FETCH NEXT
		FROM CURSOR_RADIUS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_RADIUS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					)
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				--             GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_RADIUS

			FETCH NEXT
			FROM CURSOR_RADIUS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
					-- mms -> sms message change
					--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_RADIUS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_RADIUS

			DEALLOCATE CURSOR_RADIUS

			FETCH NEXT
			FROM CURSOR_RADIUS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_RADIUS_FILTER

		DEALLOCATE CURSOR_RADIUS_FILTER

		-- TASK Service SMS Data Filter (Added on 2018-08-22 by antonio.jeong
		SET @ADSERVICE = 'TASK'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_TASK_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_TASK_FILTER

		FETCH NEXT
		FROM CURSOR_TASK_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_TASK CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					)
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				--             GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_TASK

			FETCH NEXT
			FROM CURSOR_TASK
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
					-- mms -> sms message change
					--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_TASK
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_TASK

			DEALLOCATE CURSOR_TASK

			FETCH NEXT
			FROM CURSOR_TASK_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_TASK_FILTER

		DEALLOCATE CURSOR_TASK_FILTER

		---- CONNECT Service SMS Data Filter
		--SET @ADSERVICE = 'CONNECT'
		--SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
		--PRINT @COMPANYCODE + ' , ' +  @ADSERVICE + ' , ' +  CAST ( @DATETIME AS NVARCHAR(20) )
		--INSERT INTO #TMP_MMS_MSG (COMPANY, SUBJECT, PHONE, CALLBACK, STATUS, REQDATE, MSG, TYPE)  
		--SELECT 
		--	A.Company
		--	, 'ADAMS - Active Directory pro-Active Monitoring System' --  '[' + A.Company +  ' Connect Error]' 
		--	,@SENDER_PHONE_NUMBER, '', '0',GETDATE(), A.ProblemScript,'0'
		--FROM ADSysMon.dbo.TB_ProblemManagement A LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON ( A.Serviceitem = B.SUB_CODE AND B.CLASS_CODE = '0003' )
		--WHERE  Company = @COMPANYCODE AND  ADService = @ADSERVICE
		--AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED' AND SMSSendYN is Null -- = 'N'
		--	INSERT INTO #TMP_SEND_SEQ  ( SEQ) 
		--SELECT A.IDX
		--FROM ADSysMon.dbo.TB_ProblemManagement A
		--WHERE  Company = @COMPANYCODE AND  ADService = @ADSERVICE
		--AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED' AND SMSSendYN is Null -- = 'N'
		FETCH NEXT
		FROM SMS_CURSOR
		INTO @COMPANYCODE
	END

	CLOSE SMS_CURSOR

	DEALLOCATE SMS_CURSOR

	-- SMS Å×ÀÌºí¿¡ INSERT
	-- 2015. 3. 18 MMS -> SMS change Request
	INSERT INTO dbo.SC_TRAN (
		TR_SENDDATE
		,TR_SENDSTAT
		,TR_MSGTYPE
		,TR_PHONE
		,TR_CALLBACK
		,TR_MSG
		)
	SELECT REQDATE
		,'0'
		,TYPE
		,REPLACE(B.MOBILEPHONE, '-', '')
		,PHONE
		,MSG
	FROM #TMP_MMS_MSG A
	INNER JOIN (
		SELECT M.USERID
			,U.MOBILEPHONE
			,C.VALUE2 AS COMPANY
		FROM dbo.TB_MANAGE_COMPANY_USER M
		LEFT OUTER JOIN dbo.TB_USER U ON (M.USERID = U.USERID)
		LEFT OUTER JOIN dbo.TB_COMMON_CODE_SUB C ON (
				M.COMPANYCODE = C.SUB_CODE
				AND C.CLASS_CODE = '0001'
				)
		--WHERE M.USEYN = 'Y' ) B
		WHERE M.USEYN = 'Y'
			AND M.USERID IN (
				'jeongcy'
				,'bksuh'
				,'jaejkim'
				,'pooice'
				,'suboklee'
				,'xphile24'
				,'sait7kim'
				,'choihjin'
				,'nmc_admin'
				)
		) B
		--WHERE M.USEYN = 'Y' AND M.USERID in ('jeongcy', 'bksuh', 'iyamus', 'jaejkim', 'pooice', 'suboklee', 'xphile24', 'sait7kim', 'sangbumjun', 'NMC1', 'NMC2') ) B
		ON A.COMPANY = B.COMPANY
	WHERE (
			B.MOBILEPHONE IS NOT NULL
			AND LEN(B.MOBILEPHONE) > 0
			)

	/*
	INSERT INTO dbo.MMS_MSG  (SUBJECT, PHONE, CALLBACK, STATUS, REQDATE, MSG, TYPE) 
	SELECT 
		SUBJECT  , 
		REPLACE(B.MOBILEPHONE,'-',''), --B.MOBILEPHONE, -- 		PHONE colum seq. change
		PHONE, 
		STATUS, 
		REQDATE, 
		MSG   , 
		TYPE
	FROM 
		#TMP_MMS_MSG A
		INNER JOIN
			( SELECT 
				M.USERID, U.MOBILEPHONE, C.VALUE2 AS COMPANY
				FROM dbo.TB_MANAGE_COMPANY_USER M
					LEFT OUTER JOIN dbo.TB_USER U ON ( M.USERID = U.USERID )
					LEFT OUTER JOIN dbo.TB_COMMON_CODE_SUB C ON ( M.COMPANYCODE = C.SUB_CODE AND C.CLASS_CODE = '0001' )
				--WHERE M.USEYN = 'Y' ) B
				WHERE M.USEYN = 'Y' AND M.USERID in ('admin', 'jeongcy', 'bksuh', 'iyamus', 'jaejkim', 'pigobae', 'pooice', 'suboklee', 'xphile24') ) B
				--WHERE M.USEYN = 'Y' AND M.USERID in ('admin', 'jeongcy') ) B
			ON A.COMPANY = B.COMPANY
	WHERE ( B.MOBILEPHONE IS NOT NULL AND LEN(B.MOBILEPHONE) > 0)
	*/
	-- ¹ß¼Û »óÅÂ ¾÷µ¥ÀÌÆ® 
	UPDATE A
	SET SMSSendYN = 'Y'
	FROM dbo.TB_ProblemManagement A
	WHERE IDX IN (
			SELECT SEQ
			FROM #TMP_SEND_SEQ
			)

	--SELECT * FROM dbo.TB_ProblemManagement A where IDX IN ( SELECT SEQ FROM #TMP_SEND_SEQ )
	--SELECT * FROM #TMP_MMS_MSG
	--SELECT * FROM #TMP_SEND_SEQ
	DROP TABLE #TMP_MMS_MSG

	DROP TABLE #TMP_SEND_SEQ
END
GO
/****** Object:  StoredProcedure [dbo].[IF_USP_INSERT_MMS_MSG_BACKUP_20150318]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* =============================================
	[IF_USP_INSERT_MMS_MSG]
	  
 
	DELETE FROM dbo.MMS_MSG

 	UPDATE A SET
		SMSSendYN = 'N'
	FROM dbo.TB_ProblemManagement A
	  
	EXEC [dbo].[IF_USP_INSERT_MMS_MSG]  
-- =============================================*/
CREATE PROCEDURE [dbo].[IF_USP_INSERT_MMS_MSG_BACKUP_20150318]
AS
BEGIN
	DECLARE @COMPANYCODE NVARCHAR(20)
		,@ADSERVICE NVARCHAR(16)
		,@DATETIME DATETIME
		,@SMS_SUBJECT NVARCHAR(120)
		,@SMS_MSG NVARCHAR(4000)
		,@SENDER_PHONE_NUMBER NVARCHAR(20)
	DECLARE @mCompany NVARCHAR(20)
		,@mADService NVARCHAR(10)
		,@mServiceitem NVARCHAR(50)
		,@mComputerName NVARCHAR(100)
		,@mCnt INT
		,@pScript NVARCHAR(4000)
	DECLARE @mFServiceItem NVARCHAR(10)
		,@mFilterText NVARCHAR(100)

	SET @SENDER_PHONE_NUMBER = '021148282'

	CREATE TABLE #TMP_MMS_MSG (
		COMPANY NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS
		,SUBJECT VARCHAR(120) -- Á¦¸ñ
		,PHONE VARCHAR(15) -- ¼öÁøÀÚ¹øÈ£
		,CALLBACK VARCHAR(15) -- ¼Û½ÅÀÚ ¹øÈ£
		,STATUS VARCHAR(2) DEFAULT '0' -- Àü¼Û»óÅÂ ( ´ë±â : 0, ¿Ï·á : 2, °á°ú¼ö½Å : 3 )			 
		,REQDATE DATETIME -- ¸Þ½ÃÁö¸¦ Àü¼ÛÇÒ ½Ã°£
		,MSG VARCHAR(4000) COLLATE Korean_Wansung_CI_AS -- Àü¼ÛÇÒ ¸Þ½ÃÁö
		,[TYPE] VARCHAR(2) NOT NULL DEFAULT '0'
		)

	CREATE TABLE #TMP_SEND_SEQ (SEQ INT)

	DECLARE SMS_CURSOR CURSOR
	FOR
	SELECT VALUE2
	FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB]
	WHERE CLASS_CODE = '0001'
	ORDER BY SORT_SEQ ASC

	OPEN SMS_CURSOR

	FETCH NEXT
	FROM SMS_CURSOR
	INTO @COMPANYCODE

	-- »çÀÌÆ® Á¤º¸ Á¶È¸ Loop ¹®
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		PRINT @COMPANYCODE

		-- ADDS Service SMS Data Filter
		SET @ADSERVICE = 'ADDS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		--SET @DATETIME = '2015-01-23 02:33:01.000'
		DECLARE CURSOR_ADDS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_ADDS_FILTER

		FETCH NEXT
		FROM CURSOR_ADDS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_ADDS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript --  COUNT(*) as Cnt 
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					)
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				--GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_ADDS

			FETCH NEXT
			FROM CURSOR_ADDS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript --, @mCnt			

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				SET @SMS_MSG = @pScript --- @mComputerName + N' ¼­¹ö¿¡ ' + @mServiceitem + N' ¼­ºñ½º ¹®Á¦°¡ ' + CAST(@mCnt AS NVARCHAR(5)) + N'°Ç ¹ß°ßµÇ¾ú½À´Ï´Ù.'

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_ADDS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript --@mCnt	
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_ADDS

			DEALLOCATE CURSOR_ADDS

			FETCH NEXT
			FROM CURSOR_ADDS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_ADDS_FILTER

		DEALLOCATE CURSOR_ADDS_FILTER

		-- ADCS Service SMS Data Filter
		SET @ADSERVICE = 'ADCS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_ADCS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_ADCS_FILTER

		FETCH NEXT
		FROM CURSOR_ADCS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_ADCS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript --	  COUNT(*) as Cnt 
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				-- GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_ADCS

			FETCH NEXT
			FROM CURSOR_ADCS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript --@mCnt			

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				SET @SMS_MSG = @pScript -- @mComputerName + N' ¼­¹ö¿¡ ' + @mServiceitem + N' ¼­ºñ½º ¹®Á¦°¡ ' + CAST(@mCnt AS NVARCHAR(5)) + N'°Ç ¹ß°ßµÇ¾ú½À´Ï´Ù.'

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_ADCS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript --@mCnt	
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_ADCS

			DEALLOCATE CURSOR_ADCS

			FETCH NEXT
			FROM CURSOR_ADCS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_ADCS_FILTER

		DEALLOCATE CURSOR_ADCS_FILTER

		-- DNS Service SMS Data Filter
		SET @ADSERVICE = 'DNS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_DNS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_DNS_FILTER

		FETCH NEXT
		FROM CURSOR_DNS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_DNS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript --  COUNT(*) as Cnt 
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				-- GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_DNS

			FETCH NEXT
			FROM CURSOR_DNS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript --@mCnt			

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				SET @SMS_MSG = @pScript -- @mComputerName + N' ¼­¹ö¿¡ ' + @mServiceitem + N' ¼­ºñ½º ¹®Á¦°¡ ' + CAST(@mCnt AS NVARCHAR(5)) + N'°Ç ¹ß°ßµÇ¾ú½À´Ï´Ù.'

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_DNS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript --@mCnt	
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_DNS

			DEALLOCATE CURSOR_DNS

			FETCH NEXT
			FROM CURSOR_DNS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_DNS_FILTER

		DEALLOCATE CURSOR_DNS_FILTER

		-- DHCP Service SMS Data Filter
		SET @ADSERVICE = 'DHCP'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_DHCP_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_DHCP_FILTER

		FETCH NEXT
		FROM CURSOR_DHCP_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_DHCP CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript --  COUNT(*) as Cnt 
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				--	 GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_DHCP

			FETCH NEXT
			FROM CURSOR_DHCP
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript --@mCnt			

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				SET @SMS_MSG = @pScript -- @mComputerName + N' ¼­¹ö¿¡ ' + @mServiceitem + N' ¼­ºñ½º ¹®Á¦°¡ ' + CAST(@mCnt AS NVARCHAR(5)) + N'°Ç ¹ß°ßµÇ¾ú½À´Ï´Ù.'

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_DHCP
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript --@mCnt	
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_DHCP

			DEALLOCATE CURSOR_DHCP

			FETCH NEXT
			FROM CURSOR_DHCP_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_DHCP_FILTER

		DEALLOCATE CURSOR_DHCP_FILTER

		-- RADIUS Service SMS Data Filter
		SET @ADSERVICE = 'RADIUS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_RADIUS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_RADIUS_FILTER

		FETCH NEXT
		FROM CURSOR_RADIUS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_RADIUS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript --  COUNT(*) as Cnt 
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					)
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				--             GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_RADIUS

			FETCH NEXT
			FROM CURSOR_RADIUS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript --@mCnt                                            

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				SET @SMS_MSG = @pScript

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_RADIUS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript --@mCnt             
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_RADIUS

			DEALLOCATE CURSOR_RADIUS

			FETCH NEXT
			FROM CURSOR_RADIUS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_RADIUS_FILTER

		DEALLOCATE CURSOR_RADIUS_FILTER

		---- CONNECT Service SMS Data Filter
		--SET @ADSERVICE = 'CONNECT'
		--SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
		--PRINT @COMPANYCODE + ' , ' +  @ADSERVICE + ' , ' +  CAST ( @DATETIME AS NVARCHAR(20) )
		--INSERT INTO #TMP_MMS_MSG (COMPANY, SUBJECT, PHONE, CALLBACK, STATUS, REQDATE, MSG, TYPE)  
		--SELECT 
		--	A.Company
		--	, 'ADAMS - Active Directory pro-Active Monitoring System' --  '[' + A.Company +  ' Connect Error]' 
		--	,@SENDER_PHONE_NUMBER, '', '0',GETDATE(), A.ProblemScript,'0'
		--FROM ADSysMon.dbo.TB_ProblemManagement A LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON ( A.Serviceitem = B.SUB_CODE AND B.CLASS_CODE = '0003' )
		--WHERE  Company = @COMPANYCODE AND  ADService = @ADSERVICE
		--AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED' AND SMSSendYN is Null -- = 'N'
		--	INSERT INTO #TMP_SEND_SEQ  ( SEQ) 
		--SELECT A.IDX
		--FROM ADSysMon.dbo.TB_ProblemManagement A
		--WHERE  Company = @COMPANYCODE AND  ADService = @ADSERVICE
		--AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED' AND SMSSendYN is Null -- = 'N'
		FETCH NEXT
		FROM SMS_CURSOR
		INTO @COMPANYCODE
	END

	CLOSE SMS_CURSOR

	DEALLOCATE SMS_CURSOR

	-- SMS Å×ÀÌºí¿¡ INSERT
	INSERT INTO dbo.MMS_MSG (
		SUBJECT
		,PHONE
		,CALLBACK
		,STATUS
		,REQDATE
		,MSG
		,TYPE
		)
	SELECT SUBJECT
		,REPLACE(B.MOBILEPHONE, '-', '')
		,--B.MOBILEPHONE, -- 		PHONE colum seq. change
		PHONE
		,STATUS
		,REQDATE
		,MSG
		,TYPE
	FROM #TMP_MMS_MSG A
	INNER JOIN (
		SELECT M.USERID
			,U.MOBILEPHONE
			,C.VALUE2 AS COMPANY
		FROM dbo.TB_MANAGE_COMPANY_USER M
		LEFT OUTER JOIN dbo.TB_USER U ON (M.USERID = U.USERID)
		LEFT OUTER JOIN dbo.TB_COMMON_CODE_SUB C ON (
				M.COMPANYCODE = C.SUB_CODE
				AND C.CLASS_CODE = '0001'
				)
		--WHERE M.USEYN = 'Y' ) B
		WHERE M.USEYN = 'Y'
			AND M.USERID IN (
				'admin'
				,'jeongcy'
				,'bksuh'
				,'iyamus'
				,'jaejkim'
				,'pigobae'
				,'pooice'
				,'suboklee'
				,'xphile24'
				)
		) B
		--WHERE M.USEYN = 'Y' AND M.USERID in ('admin', 'jeongcy') ) B
		ON A.COMPANY = B.COMPANY
	WHERE (
			B.MOBILEPHONE IS NOT NULL
			AND LEN(B.MOBILEPHONE) > 0
			)

	-- ¹ß¼Û »óÅÂ ¾÷µ¥ÀÌÆ® 
	UPDATE A
	SET SMSSendYN = 'Y'
	FROM dbo.TB_ProblemManagement A
	WHERE IDX IN (
			SELECT SEQ
			FROM #TMP_SEND_SEQ
			)

	--SELECT * FROM dbo.TB_ProblemManagement A where IDX IN ( SELECT SEQ FROM #TMP_SEND_SEQ )
	--SELECT * FROM #TMP_MMS_MSG
	--SELECT * FROM #TMP_SEND_SEQ
	DROP TABLE #TMP_MMS_MSG

	DROP TABLE #TMP_SEND_SEQ
END
GO
/****** Object:  StoredProcedure [dbo].[IF_USP_INSERT_MMS_MSG_BACKUP_20180809]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* =============================================
	[IF_USP_INSERT_MMS_MSG]
	  
 
	DELETE FROM dbo.MMS_MSG

 	UPDATE A SET
		SMSSendYN = 'N'
	FROM dbo.TB_ProblemManagement A
	  
	EXEC [dbo].[IF_USP_INSERT_MMS_MSG]  
-- =============================================*/
CREATE PROCEDURE [dbo].[IF_USP_INSERT_MMS_MSG_BACKUP_20180809]
AS
BEGIN
	DECLARE @COMPANYCODE NVARCHAR(20)
		,@ADSERVICE NVARCHAR(16)
		,@DATETIME DATETIME
		,@SMS_SUBJECT NVARCHAR(120)
		,@SMS_MSG NVARCHAR(160)
		,@SENDER_PHONE_NUMBER NVARCHAR(20)
	DECLARE @mCompany NVARCHAR(20)
		,@mADService NVARCHAR(10)
		,@mServiceitem NVARCHAR(50)
		,@mComputerName NVARCHAR(100)
		,@mCnt INT
		,@pScript NVARCHAR(4000)
		,@mMonitoredTime DATETIME
	DECLARE @mFServiceItem NVARCHAR(10)
		,@mFilterText NVARCHAR(100)

	SET @SENDER_PHONE_NUMBER = '0220995933'

	CREATE TABLE #TMP_MMS_MSG (
		COMPANY NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS
		,SUBJECT VARCHAR(120) -- Á¦¸ñ
		,PHONE VARCHAR(15) -- ¼öÁøÀÚ¹øÈ£
		,CALLBACK VARCHAR(15) -- ¼Û½ÅÀÚ ¹øÈ£
		,STATUS VARCHAR(2) DEFAULT '0' -- Àü¼Û»óÅÂ ( ´ë±â : 0, ¿Ï·á : 2, °á°ú¼ö½Å : 3 )			 
		,REQDATE DATETIME -- ¸Þ½ÃÁö¸¦ Àü¼ÛÇÒ ½Ã°£
		,MSG VARCHAR(4000) COLLATE Korean_Wansung_CI_AS -- Àü¼ÛÇÒ ¸Þ½ÃÁö
		,[TYPE] VARCHAR(2) NOT NULL DEFAULT '0'
		)

	CREATE TABLE #TMP_SEND_SEQ (SEQ INT)

	DECLARE SMS_CURSOR CURSOR
	FOR
	SELECT VALUE2
	FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB]
	WHERE CLASS_CODE = '0001'
	ORDER BY SORT_SEQ ASC

	OPEN SMS_CURSOR

	FETCH NEXT
	FROM SMS_CURSOR
	INTO @COMPANYCODE

	-- »çÀÌÆ® Á¤º¸ Á¶È¸ Loop ¹®
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		PRINT @COMPANYCODE

		-- ADDS Service SMS Data Filter
		SET @ADSERVICE = 'ADDS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		--SET @DATETIME = '2015-01-23 02:33:01.000'
		DECLARE CURSOR_ADDS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_ADDS_FILTER

		FETCH NEXT
		FROM CURSOR_ADDS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_ADDS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime --  COUNT(*) as Cnt 
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					)
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				--GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_ADDS

			FETCH NEXT
			FROM CURSOR_ADDS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime --, @mCnt			

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				-- mms -> sms message change
				--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_ADDS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_ADDS

			DEALLOCATE CURSOR_ADDS

			FETCH NEXT
			FROM CURSOR_ADDS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_ADDS_FILTER

		DEALLOCATE CURSOR_ADDS_FILTER

		-- ADCS Service SMS Data Filter
		SET @ADSERVICE = 'ADCS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_ADCS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_ADCS_FILTER

		FETCH NEXT
		FROM CURSOR_ADCS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_ADCS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				-- GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_ADCS

			FETCH NEXT
			FROM CURSOR_ADCS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				-- mms -> sms message change
				--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_ADCS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_ADCS

			DEALLOCATE CURSOR_ADCS

			FETCH NEXT
			FROM CURSOR_ADCS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_ADCS_FILTER

		DEALLOCATE CURSOR_ADCS_FILTER

		-- DNS Service SMS Data Filter
		SET @ADSERVICE = 'DNS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_DNS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_DNS_FILTER

		FETCH NEXT
		FROM CURSOR_DNS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_DNS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				-- GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_DNS

			FETCH NEXT
			FROM CURSOR_DNS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				-- mms -> sms message change
				--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_DNS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_DNS

			DEALLOCATE CURSOR_DNS

			FETCH NEXT
			FROM CURSOR_DNS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_DNS_FILTER

		DEALLOCATE CURSOR_DNS_FILTER

		-- DHCP Service SMS Data Filter
		SET @ADSERVICE = 'DHCP'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_DHCP_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_DHCP_FILTER

		FETCH NEXT
		FROM CURSOR_DHCP_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_DHCP CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				--	 GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_DHCP

			FETCH NEXT
			FROM CURSOR_DHCP
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
				-- mms -> sms message change
				--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_DHCP
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_DHCP

			DEALLOCATE CURSOR_DHCP

			FETCH NEXT
			FROM CURSOR_DHCP_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_DHCP_FILTER

		DEALLOCATE CURSOR_DHCP_FILTER

		-- RADIUS Service SMS Data Filter
		SET @ADSERVICE = 'RADIUS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_RADIUS_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_RADIUS_FILTER

		FETCH NEXT
		FROM CURSOR_RADIUS_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_RADIUS CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					)
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				--             GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_RADIUS

			FETCH NEXT
			FROM CURSOR_RADIUS
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
					-- mms -> sms message change
					--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_RADIUS
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_RADIUS

			DEALLOCATE CURSOR_RADIUS

			FETCH NEXT
			FROM CURSOR_RADIUS_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_RADIUS_FILTER

		DEALLOCATE CURSOR_RADIUS_FILTER

		-- TASK Service SMS Data Filter (Added on 2018-08-22 by antonio.jeong
		SET @ADSERVICE = 'TASK'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		DECLARE CURSOR_TASK_FILTER CURSOR
		FOR
		SELECT SERVICEITEM
			,FILTERTEXT
		FROM ADSysMon.dbo.TB_SMS_FILTER F
		WHERE [SERVICE] = @ADSERVICE

		OPEN CURSOR_TASK_FILTER

		FETCH NEXT
		FROM CURSOR_TASK_FILTER
		INTO @mFServiceItem
			,@mFilterText

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE CURSOR_TASK CURSOR
			FOR
			SELECT A.Company
				,A.ADService
				,B.CODE_NAME Serviceitem
				,A.ComputerName
				,A.ProblemScript
				,A.MonitoredTime
			FROM ADSysMon.dbo.TB_ProblemManagement A
			LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON (
					A.Serviceitem = B.SUB_CODE
					AND B.CLASS_CODE = '0003'
					)
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					)
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'
				AND SMSSendYN IS NULL -- = 'N'
				--             GROUP BY A.Company,  A.ADService, B.CODE_NAME , A.ComputerName

			OPEN CURSOR_TASK

			FETCH NEXT
			FROM CURSOR_TASK
			INTO @mCompany
				,@mADService
				,@mServiceitem
				,@mComputerName
				,@pScript
				,@mMonitoredTime

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @SMS_SUBJECT = 'ADAMS - Active Directory pro-Active Monitoring System' -- '[' + @mCompany +  ' ' + @mADService + ' Service Error]'
					-- mms -> sms message change
					--SET @SMS_MSG = @pScript  
				SET @SMS_MSG = @mCompany + ' ' + @mComputerName + ' ' + @mADService + ' ' + @mServiceitem + ' error detected ' + convert(VARCHAR(20), @mMonitoredTime, 120)

				INSERT INTO #TMP_MMS_MSG (
					COMPANY
					,SUBJECT
					,PHONE
					,CALLBACK
					,STATUS
					,REQDATE
					,MSG
					,TYPE
					)
				VALUES (
					@mCompany
					,@SMS_SUBJECT
					,@SENDER_PHONE_NUMBER
					,''
					,'0'
					,GetDate()
					,@SMS_MSG
					,'0'
					);

				FETCH NEXT
				FROM CURSOR_TASK
				INTO @mCompany
					,@mADService
					,@mServiceitem
					,@mComputerName
					,@pScript
					,@mMonitoredTime
			END

			INSERT INTO #TMP_SEND_SEQ (SEQ)
			SELECT A.IDX
			FROM ADSysMon.dbo.TB_ProblemManagement A
			WHERE Company = @COMPANYCODE
				AND Serviceitem = @mFServiceItem
				AND (
					@mFilterText = '""'
					OR CONTAINS (
						ProblemScript
						,@mFilterText
						)
					) --AND  CONTAINS( ProblemScript, @mFilterText) 
				AND MonitoredTime > @DATETIME
				AND ManageStatus = 'NOTSTARTED'

			CLOSE CURSOR_TASK

			DEALLOCATE CURSOR_TASK

			FETCH NEXT
			FROM CURSOR_TASK_FILTER
			INTO @mFServiceItem
				,@mFilterText
		END

		CLOSE CURSOR_TASK_FILTER

		DEALLOCATE CURSOR_TASK_FILTER

		---- CONNECT Service SMS Data Filter
		--SET @ADSERVICE = 'CONNECT'
		--SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
		--PRINT @COMPANYCODE + ' , ' +  @ADSERVICE + ' , ' +  CAST ( @DATETIME AS NVARCHAR(20) )
		--INSERT INTO #TMP_MMS_MSG (COMPANY, SUBJECT, PHONE, CALLBACK, STATUS, REQDATE, MSG, TYPE)  
		--SELECT 
		--	A.Company
		--	, 'ADAMS - Active Directory pro-Active Monitoring System' --  '[' + A.Company +  ' Connect Error]' 
		--	,@SENDER_PHONE_NUMBER, '', '0',GETDATE(), A.ProblemScript,'0'
		--FROM ADSysMon.dbo.TB_ProblemManagement A LEFT OUTER JOIN ADSysMon.dbo.TB_COMMON_CODE_SUB B ON ( A.Serviceitem = B.SUB_CODE AND B.CLASS_CODE = '0003' )
		--WHERE  Company = @COMPANYCODE AND  ADService = @ADSERVICE
		--AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED' AND SMSSendYN is Null -- = 'N'
		--	INSERT INTO #TMP_SEND_SEQ  ( SEQ) 
		--SELECT A.IDX
		--FROM ADSysMon.dbo.TB_ProblemManagement A
		--WHERE  Company = @COMPANYCODE AND  ADService = @ADSERVICE
		--AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED' AND SMSSendYN is Null -- = 'N'
		FETCH NEXT
		FROM SMS_CURSOR
		INTO @COMPANYCODE
	END

	CLOSE SMS_CURSOR

	DEALLOCATE SMS_CURSOR

	-- SMS Å×ÀÌºí¿¡ INSERT
	-- 2015. 3. 18 MMS -> SMS change Request
	INSERT INTO dbo.SC_TRAN (
		TR_SENDDATE
		,TR_SENDSTAT
		,TR_MSGTYPE
		,TR_PHONE
		,TR_CALLBACK
		,TR_MSG
		)
	SELECT REQDATE
		,'0'
		,TYPE
		,REPLACE(B.MOBILEPHONE, '-', '')
		,PHONE
		,MSG
	FROM #TMP_MMS_MSG A
	INNER JOIN (
		SELECT M.USERID
			,U.MOBILEPHONE
			,C.VALUE2 AS COMPANY
		FROM dbo.TB_MANAGE_COMPANY_USER M
		LEFT OUTER JOIN dbo.TB_USER U ON (M.USERID = U.USERID)
		LEFT OUTER JOIN dbo.TB_COMMON_CODE_SUB C ON (
				M.COMPANYCODE = C.SUB_CODE
				AND C.CLASS_CODE = '0001'
				)
		--WHERE M.USEYN = 'Y' ) B
		WHERE M.USEYN = 'Y'
			AND M.USERID IN (
				'jeongcy'
				,'bksuh'
				,'iyamus'
				,'jaejkim'
				,'pooice'
				,'suboklee'
				,'xphile24'
				,'sait7kim'
				,'nmc_admin'
				)
		) B
		--WHERE M.USEYN = 'Y' AND M.USERID in ('jeongcy', 'bksuh', 'iyamus', 'jaejkim', 'pooice', 'suboklee', 'xphile24', 'sait7kim', 'sangbumjun', 'NMC1', 'NMC2') ) B
		ON A.COMPANY = B.COMPANY
	WHERE (
			B.MOBILEPHONE IS NOT NULL
			AND LEN(B.MOBILEPHONE) > 0
			)

	/*
	INSERT INTO dbo.MMS_MSG  (SUBJECT, PHONE, CALLBACK, STATUS, REQDATE, MSG, TYPE) 
	SELECT 
		SUBJECT  , 
		REPLACE(B.MOBILEPHONE,'-',''), --B.MOBILEPHONE, -- 		PHONE colum seq. change
		PHONE, 
		STATUS, 
		REQDATE, 
		MSG   , 
		TYPE
	FROM 
		#TMP_MMS_MSG A
		INNER JOIN
			( SELECT 
				M.USERID, U.MOBILEPHONE, C.VALUE2 AS COMPANY
				FROM dbo.TB_MANAGE_COMPANY_USER M
					LEFT OUTER JOIN dbo.TB_USER U ON ( M.USERID = U.USERID )
					LEFT OUTER JOIN dbo.TB_COMMON_CODE_SUB C ON ( M.COMPANYCODE = C.SUB_CODE AND C.CLASS_CODE = '0001' )
				--WHERE M.USEYN = 'Y' ) B
				WHERE M.USEYN = 'Y' AND M.USERID in ('admin', 'jeongcy', 'bksuh', 'iyamus', 'jaejkim', 'pigobae', 'pooice', 'suboklee', 'xphile24') ) B
				--WHERE M.USEYN = 'Y' AND M.USERID in ('admin', 'jeongcy') ) B
			ON A.COMPANY = B.COMPANY
	WHERE ( B.MOBILEPHONE IS NOT NULL AND LEN(B.MOBILEPHONE) > 0)
	*/
	-- ¹ß¼Û »óÅÂ ¾÷µ¥ÀÌÆ® 
	UPDATE A
	SET SMSSendYN = 'Y'
	FROM dbo.TB_ProblemManagement A
	WHERE IDX IN (
			SELECT SEQ
			FROM #TMP_SEND_SEQ
			)

	--SELECT * FROM dbo.TB_ProblemManagement A where IDX IN ( SELECT SEQ FROM #TMP_SEND_SEQ )
	--SELECT * FROM #TMP_MMS_MSG
	--SELECT * FROM #TMP_SEND_SEQ
	DROP TABLE #TMP_MMS_MSG

	DROP TABLE #TMP_SEND_SEQ
END
GO
/****** Object:  StoredProcedure [dbo].[IF_USP_INSERT_MMS_MSG_V2]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.08.10
-- Description:	SMS Send SP 수정
-- =============================================
CREATE PROCEDURE [dbo].[IF_USP_INSERT_MMS_MSG_V2]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @SENDER_PHONE_NUMBER NVARCHAR(20)
	SET @SENDER_PHONE_NUMBER = '0220995933'

	CREATE TABLE #TMP_MMS_MSG (
		[IDX] INT
		,[COMPANY] NVARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS
		,[SUBJECT] VARCHAR(120)
		,[PHONE] VARCHAR(15)
		,[CALLBACK] VARCHAR(15)
		,[STATUS] VARCHAR(2) DEFAULT '0'
		,[REQDATE] DATETIME
		,[MSG] VARCHAR(4000) COLLATE Korean_Wansung_CI_AS
		,[TYPE] VARCHAR(2) NOT NULL DEFAULT '0'
	)

	INSERT INTO #TMP_MMS_MSG ([IDX], [COMPANY], [SUBJECT], [PHONE], [CALLBACK], [STATUS], [REQDATE], [MSG], [TYPE])
	SELECT T1.[IDX]
		,T1.[Company]
		,'ADAMS - Active Directory pro-Active Monitoring System' AS [SUBJECT]
		, @SENDER_PHONE_NUMBER AS [PHONE]
		,'' AS [CALLBACK]
		,'0' AS [STATUS]
		,GETDATE() AS [REQDATE]
		,T1.[Company] + ' ' + T1.[ComputerName] + ' ' + T1.[ADService] + ' ' + (SELECT [CODE_NAME] FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] WHERE [CLASS_CODE] = '0003' AND [SUB_CODE] = T1.[Serviceitem]) + ' error detected ' + CONVERT(VARCHAR(20), T1.[MonitoredTime], 120) AS [MSG]
		,'0' AS [TYPE]
	--FROM [ADSysMon].[dbo].[View_ProblemManagement] T1
	FROM [ADSysMon].[dbo].[UFN_ProblemManagement]() T1
	INNER JOIN  [dbo].[TB_SMS_FILTER] T4 ON T1.[ADService] = T4.[SERVICE] AND T1.[Serviceitem] = T4.[SERVICEITEM] AND T4.[USEYN] = 'Y' AND (T4.[FILTERTEXT] = '' OR T1.[ProblemScript] LIKE '%' + REPLACE(T4.[FILTERTEXT], '*', '%') + '%')
	WHERE T1.[MonitoredTime] > [dbo].[UFN_GET_MONITOR_DATE](T1.[Company], T1.[ADService])
		AND T1.[ManageStatus] = 'NOTSTARTED'
		AND T1.[SMSSendYN] IS NULL

	INSERT INTO dbo.SC_TRAN (
		TR_SENDDATE
		,TR_SENDSTAT
		,TR_MSGTYPE
		,TR_PHONE
		,TR_CALLBACK
		,TR_MSG
		)
	SELECT [REQDATE] AS [TR_SENDDATE]
		,'0' AS [TR_SENDSTAT]
		,[TYPE] AS [TR_MSGTYPE]
		,REPLACE(B.[MOBILEPHONE], '-', '') AS [TR_PHONE]
		,[PHONE] AS [TR_CALLBACK]
		,[MSG] AS [TR_MSG]
	FROM #TMP_MMS_MSG A
	INNER JOIN (
		SELECT M.USERID
			,U.MOBILEPHONE
			,C.VALUE2 AS COMPANY
		FROM dbo.TB_MANAGE_COMPANY_USER M
		LEFT OUTER JOIN dbo.TB_USER U ON (M.USERID = U.USERID)
		LEFT OUTER JOIN dbo.TB_COMMON_CODE_SUB C ON M.COMPANYCODE = C.SUB_CODE AND C.CLASS_CODE = '0001'
		WHERE M.USEYN = 'Y'
			AND M.USERID IN (
				'jeongcy'
				,'bksuh'
				,'iyamus'
				,'jaejkim'
				,'pooice'
				,'suboklee'
				,'xphile24'
				,'sait7kim'
				,'nmc_admin'
				)
		) B ON A.COMPANY = B.COMPANY
	WHERE B.MOBILEPHONE IS NOT NULL AND LEN(B.MOBILEPHONE) > 0

	UPDATE A
	SET [SMSSendYN] = 'Y'
	FROM [dbo].[TB_ProblemManagement] A
	WHERE [IDX] IN (SELECT [IDX] FROM #TMP_MMS_MSG)

	DROP TABLE #TMP_MMS_MSG
END
GO
/****** Object:  StoredProcedure [dbo].[USP_ALERT_SNOOZE_DEL]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.08.06
-- Description:	Alert Snooze Del
-- =============================================
CREATE PROCEDURE [dbo].[USP_ALERT_SNOOZE_DEL]
	-- Add the parameters for the stored procedure here
	@IDX INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DELETE FROM [dbo].[TB_ALERT_SNOOZE] WHERE IDX = @IDX
END
GO
/****** Object:  StoredProcedure [dbo].[USP_ALERT_SNOOZE_GET]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.08.06
-- Description:	Alert Snooze List Return
-- =============================================
CREATE PROCEDURE [dbo].[USP_ALERT_SNOOZE_GET]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT T1.[IDX]
		,T1.[CompanyCode]
		,ISNULL(T2.[CODE_NAME], '') AS [CompanyName]
		,ISNULL(T2.[VALUE2], '') AS [Domain]
		,T1.[ADService]
		,T1.[ServiceItem]
		,ISNULL(T3.[CODE_NAME], '') AS [ServiceName]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[StartDate]
		,T1.[EndDate]
		,T1.[CreateUserID]
		,ISNULL(T4.[USERNAME], '') AS [CreateUserName]
		,T1.[CreateDate]
	FROM [dbo].[TB_ALERT_SNOOZE] T1
	LEFT OUTER JOIN [dbo].[TB_COMMON_CODE_SUB] T2 ON T1.[CompanyCode] = T2.[VALUE2] AND T2.[CLASS_CODE] = '0001'
	LEFT OUTER JOIN [dbo].[TB_COMMON_CODE_SUB] T3 ON T1.[ServiceItem] = T3.[SUB_CODE] AND T3.[CLASS_CODE] = '0003'
	INNER JOIN [dbo].[TB_USER] T4 ON T1.[CreateUserID] = T4.[USERID]
	ORDER BY T1.[EndDate] DESC
END
GO
/****** Object:  StoredProcedure [dbo].[USP_ALERT_SNOOZE_SET]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.08.07
-- Description:	Alert Snooze Insert
-- =============================================
CREATE PROCEDURE [dbo].[USP_ALERT_SNOOZE_SET]
	-- Add the parameters for the stored procedure here
	@CompanyCode NVARCHAR(10)
	,@ADService NVARCHAR(10)
	,@ServiceFlag NVARCHAR(50)
	,@ComputerName NVARCHAR(100)
	,@ProblemScript NVARCHAR(100)
	,@StartDate DATETIME
	,@EndDate DATETIME
	,@CreateUserID NVARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	MERGE [dbo].[TB_ALERT_SNOOZE] AS T1
	USING (
		SELECT @CompanyCode AS [CompanyCode]
			,@ADService AS [ADService]
			,@ServiceFlag AS [ServiceItem]
			,@ComputerName AS [ComputerName]
		) AS T2
		ON T1.[CompanyCode] = T2.[CompanyCode]
			AND T1.[ADService] = T2.[ADService]
			AND T1.[ServiceItem] = T2.[ServiceItem]
			AND T1.[ComputerName] = T2.[ComputerName]
	WHEN MATCHED
		THEN
			UPDATE
			SET [ProblemScript] = @ProblemScript
			, [StartDate] = @StartDate
			, [EndDate] = @EndDate
	WHEN NOT MATCHED
		THEN
			INSERT 
			   ([CompanyCode]
			   ,[ADService]
			   ,[ServiceItem]
			   ,[ComputerName]
			   ,[ProblemScript]
			   ,[StartDate]
			   ,[EndDate]
			   ,[CreateUserID]
			   ,[CreateDate])
		 VALUES
			   (@CompanyCode
			   ,@ADService
			   ,@ServiceFlag
			   ,@ComputerName
			   ,@ProblemScript
			   ,@StartDate
			   ,@EndDate
			   ,@CreateUserID
			   ,GETDATE());
END
GO
/****** Object:  StoredProcedure [dbo].[USP_COMMON_CODE_SUB_SET]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.08.03
-- Description:	CODE_SUB 입력...
-- =============================================
CREATE PROCEDURE [dbo].[USP_COMMON_CODE_SUB_SET]
	-- Add the parameters for the stored procedure here
	@CLASS_CODE VARCHAR(4)
	,@SUB_CODE NVARCHAR(10)
	,@CODE_NAME NVARCHAR(100)
	,@VALUE1 NVARCHAR(30)
	,@VALUE2 NVARCHAR(30)
	,@CREATOR_ID VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	INSERT INTO [dbo].[TB_COMMON_CODE_SUB] (
		[CLASS_CODE]
		,[SUB_CODE]
		,[USE_YN]
		,[CODE_NAME]
		,[SORT_SEQ]
		,[VALUE1]
		,[VALUE2]
		,[CREATOR_ID]
		,[CREATE_DATE]
		,[UPDATER_ID]
		,[UPDATE_DATE]
		)
	VALUES (
		@CLASS_CODE
		,@SUB_CODE
		,'Y'
		,@CODE_NAME
		,(SELECT MAX([SORT_SEQ]) + 1 FROM [dbo].[TB_COMMON_CODE_SUB] WHERE [CLASS_CODE] = @CLASS_CODE)
		,@VALUE1
		,@VALUE2
		,@CREATOR_ID
		,GETDATE()
		,NULL
		,NULL
		)
END
GO
/****** Object:  StoredProcedure [dbo].[USP_CREATE_DTO_CODE]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[USP_CREATE_DTO_CODE]  
	 @TABLE_NAME		varchar(50)
AS  
/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 
-- 작성일 : 2014.10.08  
-- 수정일 : 2014.10.08  
-- 설   명 : Dto클래스 코드생성
-- 실   행 :  EXEC [dbo].[USP_CREATE_DTO_CODE] 'TB_DOC_TRAVEL_MANAGEMENT'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  
  
SET NOCOUNT ON  

BEGIN
	
	DECLARE @COLUMN_NAME varchar(50)
	DECLARE @DATA_TYPE	 varchar(50)
	DECLARE @IS_NULLABLE varchar(3)
	
	DECLARE @DTO_CODE	 varchar(8000)
	SET @DTO_CODE = ''

	DECLARE @TMP_CODE	 varchar(1000)

	DECLARE CUR_COLUMNS CURSOR FOR	
	SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
	  FROM INFORMATION_SCHEMA.COLUMNS
	 WHERE TABLE_NAME = @TABLE_NAME
	 ORDER BY ORDINAL_POSITION
	OPEN CUR_COLUMNS
	FETCH NEXT FROM CUR_COLUMNS
	INTO @COLUMN_NAME, @DATA_TYPE, @IS_NULLABLE
	WHILE @@FETCH_STATUS = 0 
	BEGIN

		SET @TMP_CODE = '/// <summary>' + char(13) + char(10) + '/// ' + char(13) + char(10) + '/// </summary> ' + char(13) + char(10)
		SET @TMP_CODE = @TMP_CODE + 'public '
		IF @DATA_TYPE = 'int' 
			SET @TMP_CODE = @TMP_CODE + 'int ' + @COLUMN_NAME 
		ELSE IF (@DATA_TYPE = 'money' OR @DATA_TYPE = 'numeric')
		BEGIN
			IF @IS_NULLABLE = 'YES'
				SET @TMP_CODE = @TMP_CODE + 'decimal? ' + @COLUMN_NAME 
			ELSE 
				SET @TMP_CODE = @TMP_CODE + 'decimal ' + @COLUMN_NAME 
		END
		ELSE IF (@DATA_TYPE = 'date' OR @DATA_TYPE = 'smalldatetime')
		BEGIN
			IF @IS_NULLABLE = 'YES'
				SET @TMP_CODE = @TMP_CODE + 'DateTime? ' + @COLUMN_NAME 
			ELSE
				SET @TMP_CODE = @TMP_CODE + 'DateTime ' + @COLUMN_NAME 
		END		
		ELSE
			SET @TMP_CODE = @TMP_CODE + 'string ' + @COLUMN_NAME
			
		SET @TMP_CODE = @TMP_CODE + ' { get; set; }'
		
		--Append Dto Code		
		SET @DTO_CODE = @DTO_CODE + @TMP_CODE + char(13) + char(10) + char(13) + char(10)

		FETCH NEXT FROM CUR_COLUMNS INTO @COLUMN_NAME, @DATA_TYPE, @IS_NULLABLE
	END
	CLOSE CUR_COLUMNS
	DEALLOCATE CUR_COLUMNS

	SELECT @DTO_CODE

END  
 




GO
/****** Object:  StoredProcedure [dbo].[USP_CREATE_GENERICCURSOR]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[USP_CREATE_GENERICCURSOR]
    /* Parameters */
    @vQuery        NVARCHAR(MAX)
    ,@Cursor    CURSOR VARYING OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE 
        @vSQL        AS NVARCHAR(MAX)
    
    SET @vSQL = 'SET @Cursor = CURSOR FORWARD_ONLY STATIC FOR ' + @vQuery + ' OPEN @Cursor;'
    
   
    EXEC sp_executesql
         @vSQL
         ,N'@Cursor cursor output'  
         ,@Cursor OUTPUT;
END 

GO
/****** Object:  StoredProcedure [dbo].[USP_CREATE_PROC_PARAMETER]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[USP_CREATE_PROC_PARAMETER]  
	 @PROCEDURE_NAME		varchar(50)
AS  
/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 
-- 작성일 : 2014.10.08  
-- 수정일 : 2014.10.08  
-- 설   명 : Dto클래스 코드생성
-- 실   행 :  EXEC [dbo].[USP_CREATE_PROC_PARAMETER] 'USP_DELETE_SAMPLE_REQUEST_ITEMS_ALL'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  
  
SET NOCOUNT ON  

BEGIN
	
	DECLARE @PARAM_NAME varchar(50)
	
	DECLARE @PARAMETER	 varchar(8000)
	SET @PARAMETER = ''

	DECLARE CUR_PARAMS CURSOR FOR	
	SELECT PARAMETER_NAME 
	  FROM information_schema.parameters
	 WHERE specific_name= @PROCEDURE_NAME
	 ORDER BY ORDINAL_POSITION
	OPEN CUR_PARAMS
	FETCH NEXT FROM CUR_PARAMS
	INTO @PARAM_NAME
	WHILE @@FETCH_STATUS = 0 
	BEGIN

		--Append Paremeter		
		SET @PARAMETER = @PARAMETER + @PARAM_NAME + ', '

		FETCH NEXT FROM CUR_PARAMS INTO @PARAM_NAME
	END
	CLOSE CUR_PARAMS
	DEALLOCATE CUR_PARAMS

	SELECT @PARAMETER

END  
 




GO
/****** Object:  StoredProcedure [dbo].[USP_CREATE_TABLE_PARAMETER]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트   
-- 작성일 : 2014.10.08  
-- 수정일 : 2014.10.08  
-- 설   명 : Table
-- 실   행 :  EXEC [dbo].[USP_CREATE_TABLE_PARAMETER] 'TB_LGE_NET_PERFORMANCE'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  
CREATE PROCEDURE [dbo].[USP_CREATE_TABLE_PARAMETER]  
	 @TABLE_NAME		varchar(50)
AS  
  
SET NOCOUNT ON  

BEGIN
	
	DECLARE @PARAM_NAME varchar(50)
	
	DECLARE @PARAMETER	 varchar(8000)
	SET @PARAMETER = ''

	SELECT ',@' + COLUMN_NAME + char(9) + CASE WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN DATA_TYPE + '(' + CONVERT(varchar(10), CHARACTER_MAXIMUM_LENGTH) + ')' ELSE DATA_TYPE END
	  FROM INFORMATION_SCHEMA.COLUMNS
	 WHERE TABLE_NAME = @TABLE_NAME
	 ORDER BY ORDINAL_POSITION

END  
 




GO
/****** Object:  StoredProcedure [dbo].[USP_DASHBOARD_GET]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.07.30
-- Description:	Dashboard Row Data Return
-- EXEC [dbo].[USP_DASHBOARD_GET] 'admin', '', '0'
-- =============================================
CREATE PROCEDURE [dbo].[USP_DASHBOARD_GET]
	-- Add the parameters for the stored procedure here
	@USERID NVARCHAR(10)
	,@COMPCD NVARCHAR(10)
	,@AreaID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT  T1.[ComputerName] 
		,T1.[ADService]
		,T1.[Serviceitem]
		,COUNT(*) AS [ErrorCount]
		,CONVERT(VARCHAR(16), MAX(T1.[MonitoredTime]), 120) AS [MonitoredTime]
	INTO #TMP_Problem_Management
	--FROM [ADSysMon].[dbo].[TB_ProblemManagement] T1
	--FROM [ADSysMon].[dbo].[View_ProblemManagement] T1 WITH(NOLOCK)
	FROM [ADSysMon].[dbo].[UFN_ProblemManagement]() T1
	INNER JOIN [dbo].[UFN_Manage_Company_User](@USERID) T2 ON T1.[Company] = T2.[Company]
	INNER JOIN [dbo].[UFN_MonitoringTaskLogs]() T3 ON T1.[Company] = T3.[Company] AND T1.[ADService] = T3.[ADService]
	WHERE T1.[MonitoredTime] > T3.[LastDate]
		--AND T1.[ManageStatus] = 'NOTSTARTED'
		--AND T1.[ADService] IN ('ADDS', 'ADCS', 'DNS', 'DHCP') -- mwjin7@dotnetsoft.co.kr 2018.08.01 기존 SP 에 4 항목만 체크하고 있음...
		AND (@COMPCD = '' OR T2.[CompanyCode] = @COMPCD)
	GROUP BY T1.[ComputerName], T1.[ADService], T1.[Serviceitem]

	SELECT T2.[ComputerName]
		,T2.[ADService]
		,T1.[CODE_NAME] AS [ADServiceName]
		,ISNULL(T2.[ErrorCount], 0) AS [ErrorCount]
		,T2.[MonitoredTime]
		,ISNULL(T3.[Domain], '') AS [Domain]
		,ISNULL(T3.[AreaID], 0) AS [AreaID]
		,ISNULL(T3.[AreaName], '') AS [AreaName]
		,ISNULL(T3.[AreaLatitude], 0.0) AS [AreaLatitude]
		,ISNULL(T3.[AreaLongitude], 0.0) AS [AreaLongitude]
		,ISNULL(T3.[CountryID], 0) AS [CountryID]
		,ISNULL(T3.[CountryName], '') AS [CountryName]
		,ISNULL(T3.[CityID], 0) AS [CityID]
		,ISNULL(T3.[CityName], '') AS [CityName]
		,ISNULL(T3.[CityLatitude], 0.0) AS [CityLatitude]
		,ISNULL(T3.[CityLongitude], 0.0) AS [CityLongitude]
		,ISNULL(T3.[CorpID], 0) AS [CorpID]
		,ISNULL(T3.[CorpName], '') AS [CorpName]
		,ISNULL(T3.[CorpLatitude], 0.0) AS [CorpLatitude]
		,ISNULL(T3.[CorpLongitude], 0.0) AS [CorpLongitude]
	FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS T1 WITH(NOLOCK)
	INNER JOIN #TMP_Problem_Management AS T2 ON T1.[SUB_CODE] = T2.[Serviceitem]
	--LEFT OUTER JOIN [dbo].[View_MapServerLocation] T3 ON T2.[ComputerName] = T3.[ComputerName] AND (@AreaID = 0 OR T3.[AreaID] = @AreaID)
	--LEFT OUTER JOIN [dbo].[View_MapServerLocation] T3 ON (T2.[ComputerName] = T3.[ComputerName] OR T2.[ComputerName] = T3.[ServerFQDN]) AND (@AreaID = 0 OR T3.[AreaID] = @AreaID)
	--INNER JOIN [dbo].[View_MapServerLocation] T3 ON (T2.[ComputerName] = T3.[ComputerName] OR T2.[ComputerName] = T3.[HostName]) AND (@AreaID = 0 OR T3.[AreaID] = @AreaID)
	INNER JOIN [dbo].[View_MapServerLocation] T3 ON (T2.[ComputerName] = T3.[ComputerName]) AND (@AreaID = 0 OR T3.[AreaID] = @AreaID)
	WHERE T1.[CLASS_CODE] = '0003'
	--ORDER BY T1.[SORT_SEQ]

	DROP TABLE #TMP_Problem_Management
END
GO
/****** Object:  StoredProcedure [dbo].[USP_DELETE_SERVER_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.22  
-- 수정일 : 2014.12.22  
-- 설   명 : 서버 리스트 삭제
-- 실   행 : EXEC [dbo].[USP_DELETE_SERVER_LIST] 'LGE.NET','ADCS','TESTTEST'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_DELETE_SERVER_LIST]
	-- Add the parameters for the stored procedure here
	@DOMAIN NVARCHAR(30)
	,@SERVICEFLAG NVARCHAR(10)
	,@COMPUTERNAME NVARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	DELETE
	--FROM [dbo].[TB_SERVERS]
	FROM [dbo].[TB_SERVERS2] -- 2018.08.14 mwjin7@dotnetsoft.co.kr PowerShell V2 => V3 전환과정 상의 이유로 TB_SERVERS2  생성하고 사용
	WHERE [Domain] = @DOMAIN
		AND [ServiceFlag] = @SERVICEFLAG
		AND [ComputerName] = @COMPUTERNAME
END
GO
/****** Object:  StoredProcedure [dbo].[USP_DELETE_USER_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.23  
-- 수정일 : 2014.12.23  
-- 설   명 : 유저 논리 삭제
-- 실   행 : EXEC [dbo].[USP_DELETE_USER_LIST] 'test2'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_DELETE_USER_LIST] 
	@USERID			NVARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;

UPDATE [dbo].[TB_USER]
   SET [USEYN] = 'N'
      ,[CREATE_DATE] = GETUTCDATE()
 WHERE [USERID] = @USERID
END



GO
/****** Object:  StoredProcedure [dbo].[USP_EXCEPTED_EVENTID_DEL]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.07.24
-- Description:	점검 제외할 EventID 삭제
-- =============================================
CREATE PROCEDURE [dbo].[USP_EXCEPTED_EVENTID_DEL]
	-- Add the parameters for the stored procedure here
	@IDX INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DELETE FROM [dbo].[TB_EVENTID] WHERE IDX = @IDX
END
GO
/****** Object:  StoredProcedure [dbo].[USP_EXCEPTED_EVENTID_GET]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.07.24
-- Description:	점검 제외할 EventID 목록 Return
-- =============================================
CREATE PROCEDURE [dbo].[USP_EXCEPTED_EVENTID_GET]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT
		T1.[IDX]
		,T1.[ID]
		,T1.[ServiceFlag]
		,T1.[Detail]
		,T1.[Reason]
		,T1.[CreateUserID]
		,T2.[USERNAME] AS [CreateUserName]
		,T1.[CreateDate]
	FROM [dbo].[TB_EVENTID] T1
	LEFT OUTER JOIN [dbo].[TB_USER] T2 ON T1.[CreateUserID] = T2.[USERID]
	ORDER BY T1.[CreateDate] DESC
END
GO
/****** Object:  StoredProcedure [dbo].[USP_EXCEPTED_EVENTID_SET]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.07.24
-- Description:	점검 제외할 EventID 등록
-- =============================================
CREATE PROCEDURE [dbo].[USP_EXCEPTED_EVENTID_SET]
	-- Add the parameters for the stored procedure here
	@ID NVARCHAR(30)
	, @ServiceFlag NVARCHAR(10)
	, @Detail NVARCHAR(500)
	, @Reason NVARCHAR(500)
	, @CreateUserID NVARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	MERGE [dbo].[TB_EVENTID] AS T1
	USING (
		SELECT
			@ID AS [ID]
			,@ServiceFlag AS [ServiceFlag]
			,@Detail AS [Detail]
			,@Reason AS [Reason]
			,@CreateUserID AS [CreateUserID]
	) AS T2 ON T1.[ID] = T2.[ID] AND T1.[ServiceFlag] = T2.[ServiceFlag]
	WHEN MATCHED THEN 
		 UPDATE SET  T1.[ServiceFlag] = T2.[ServiceFlag]
	WHEN NOT MATCHED THEN 
		 INSERT ([ID], [ServiceFlag], [Detail], [Reason], [CreateUserID], [CreateDate]) VALUES(T2.[ID], T2.[ServiceFlag], T2.[Detail], T2.[Reason], T2.[CreateUserID], GETDATE());
END
GO
/****** Object:  StoredProcedure [dbo].[USP_INSERT_MANAGE_COMPANY_USER]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.19  
-- 수정일 : 2014.12.19  
-- 설   명 : 회사 담당 목록 추가
-- 실   행 : EXEC [dbo].[USP_INSERT_MANAGE_COMPANY_USER] 'admin', 'LGE', 'system'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_INSERT_MANAGE_COMPANY_USER] 
	@USERID			NVARCHAR(10),
	@COMPANYCODE	NVARCHAR(10),
	@CREATE_ID		NVARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;	

	INSERT INTO [dbo].[TB_MANAGE_COMPANY_USER]
           ([USERID]
           ,[COMPANYCODE]
           ,[CREATE_ID]
           ,[CREATE_DATE]
           ,[USEYN])
     VALUES
           (@USERID
           ,@COMPANYCODE
           ,@CREATE_ID
           ,GETUTCDATE()
           ,'Y')
END






GO
/****** Object:  StoredProcedure [dbo].[USP_INSERT_SYSTEM_LOG]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 
-- 작성일 : 2014.11.13  
-- 수정일 : 2014.11.13  
-- 설   명 : TB_SYSTEM_LOG 저장
-- 실   행 : 
[dbo].[USP_CREATE_DTO_CODE] 'TB_SYSTEM_LOG'
[dbo].[USP_CREATE_TABLE_PARAMETER] 'TB_SYSTEM_LOG'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_INSERT_SYSTEM_LOG]
	 @TYPE			nvarchar(5)
	,@EVENT_NAME	nvarchar(30)
	,@MESSAGE		nvarchar(MAX)
	,@CREATE_DATE	datetime
	,@CREATER_ID	varchar(10)
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO TB_SYSTEM_LOG 
			( [TYPE]
			, EVENT_NAME
			, [MESSAGE]
			, CREATE_DATE
			, CREATER_ID 
			)
	VALUES	( @TYPE			
			,@EVENT_NAME	
 			,@MESSAGE		
			,@CREATE_DATE	
			,@CREATER_ID	
			)

END


GO
/****** Object:  StoredProcedure [dbo].[USP_MAP_CITY_SET]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.08.03
-- Description:	Map City Info Update/Insert
-- =============================================
CREATE PROCEDURE [dbo].[USP_MAP_CITY_SET]
	-- Add the parameters for the stored procedure here
	@CityName NVARCHAR(50)
	, @CountryID INT
	, @CityLatitude FLOAT
	, @CityLongitude FLOAT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	MERGE [dbo].[TB_MAP_CITY] AS T1
	USING (
		SELECT @CityName AS [CityName]
			,@CountryID AS [CountryID]
			,@CityLatitude AS [CityLatitude]
			,@CityLongitude AS [CityLongitude]
		) AS T2
		ON T1.[CityName] = T2.[CityName]
			AND T1.[CountryID] = T2.[CountryID]
	WHEN MATCHED
		THEN
			UPDATE
			SET [CityName] = @CityName
				,[CityLatitude] = @CityLatitude
				,[CityLongitude] = @CityLongitude
	WHEN NOT MATCHED
		THEN
			INSERT (
				[CityName]
				,[CountryID]
				,[CityLatitude]
				,[CityLongitude]
				)
			VALUES (
				@CityName
				,@CountryID
				,@CityLatitude
				,@CityLongitude
				);
END
GO
/****** Object:  StoredProcedure [dbo].[USP_MAP_CORP_SET]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.08.03
-- Description:	Map Corp Info Update/Insert
-- =============================================
CREATE PROCEDURE [dbo].[USP_MAP_CORP_SET]
	-- Add the parameters for the stored procedure here
	@CorpName NVARCHAR(50)
	, @CityID INT
	, @CorpLatitude FLOAT
	, @CorpLongitude FLOAT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	MERGE [dbo].[TB_MAP_CORP] AS T1
	USING (
		SELECT @CorpName AS [CorpName]
			,@CityID AS [CityID]
			,@CorpLatitude AS [CorpLatitude]
			,@CorpLongitude AS [CorpLongitude]
		) AS T2
		ON T1.[CorpName] = T2.[CorpName]
			AND T1.[CityID] = T2.[CityID]
	WHEN MATCHED
		THEN
			UPDATE
			SET [CorpName] = @CorpName
				,[CorpLatitude] = @CorpLatitude
				,[CorpLongitude] = @CorpLongitude
	WHEN NOT MATCHED
		THEN
			INSERT (
				[CorpName]
				,[CityID]
				,[CorpLatitude]
				,[CorpLongitude]
				)
			VALUES (
				@CorpName
				,@CityID
				,@CorpLatitude
				,@CorpLongitude
				);
END
GO
/****** Object:  StoredProcedure [dbo].[USP_MAP_LOCATION_GET]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.07.31
-- Description:	Map Location Return
-- =============================================
CREATE PROCEDURE [dbo].[USP_MAP_LOCATION_GET]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	--SELECT [AreaID]
	--	,[AreaName]
	--	,[AreaLatitude]
	--	,[AreaLongitude]
	--	,[CountryID]
	--	,[CountryName]
	--	,[CityID]
	--	,[CityName]
	--	,[CityLatitude]
	--	,[CityLongitude]
	--	,[CorpID]
	--	,[CorpName]
	--	,[CorpLatitude]
	--	,[CorpLongitude]
	--FROM [dbo].[View_MapLocation]
	SELECT [Domain]
		,[ComputerName]
		,[CorpID]
		,[CorpName]
		,[CorpLatitude]
		,[CorpLongitude]
		,[CityID]
		,[CityName]
		,[CityLatitude]
		,[CityLongitude]
		,[CountryID]
		,[CountryName]
		,[AreaID]
		,[AreaName]
		,[AreaLatitude]
		,[AreaLongitude]
	FROM [dbo].[View_MapServerLocation]
END
GO
/****** Object:  StoredProcedure [dbo].[USP_MERGE_MANAGE_COMPANY_USER]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



 /*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.19  
-- 수정일 : 2014.12.19  
-- 설  명 :  
-- 실  행 : 

[dbo].[USP_MERGE_MANAGE_COMPANY_USER] 'test', 'HIP','system', 'Y'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  

CREATE PROCEDURE  [dbo].[USP_MERGE_MANAGE_COMPANY_USER] 
	@USERID			NVARCHAR(10),
	@COMPANYCODE	NVARCHAR(MAX),
	@CREATEID		NVARCHAR(10),
	@USEYN			VARCHAR(1)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @TEMP_COMPANY table (
		USERID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		COMPANYCODE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS
	)
	INSERT INTO @TEMP_COMPANY

	SELECT @USERID, items FROM [dbo].[UFN_GET_SPLIT_BigSize] (@COMPANYCODE,'^')


	MERGE dbo.TB_MANAGE_COMPANY_USER AS TB1
	USING (SELECT userid , companycode  from @TEMP_COMPANY ) AS TB2
	   ON TB1.USERID = TB2.USERID AND TB1.COMPANYCODE = TB2.COMPANYCODE
	 WHEN matched THEN
	 UPDATE
	    SET USEYN = @USEYN,
			CREATE_ID = @CREATEID,
			CREATE_DATE = GETUTCDATE()
	 WHEN not matched THEN
	 INSERT (   [USERID]
			   ,[COMPANYCODE]
			   ,[CREATE_ID]
			   ,[CREATE_DATE]
			   ,[USEYN]		
			)
	 VALUES (  @USERID
			  ,@COMPANYCODE
              ,@CREATEID
              ,GETUTCDATE()
              ,'Y');	

 
END



GO
/****** Object:  StoredProcedure [dbo].[USP_MERGE_SERVER_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.22  
-- 수정일 : 2014.12.22  
-- 설   명 : SERVER LIST MARGE
-- 실   행 : EXEC [dbo].[USP_MERGE_SERVER_LIST] 'LGE.NET','ADCS','TESTTEST','10.0.0.1'
-------------------------------------------------------------------------------------  
-- 수   정   일 : 
-- 수   정   자 : 
-- 수 정  내 용 : 
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_MERGE_SERVER_LIST]
	-- Add the parameters for the stored procedure here
	@DOMAIN NVARCHAR(30)
	,@SERVICEFLAG NVARCHAR(10)
	,@COMPUTERNAME NVARCHAR(100)
	,@IPADDRESS NVARCHAR(15)
	,@CorpID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	--MERGE [dbo].[TB_SERVERS] AS TB1
	MERGE [dbo].[TB_SERVERS2] AS TB1 -- 2018.08.14 mwjin7@dotnetsoft.co.kr PowerShell V2 => V3 전환과정 상의 이유로 TB_SERVERS2  생성하고 사용
	USING (
		SELECT @DOMAIN AS [Domain]
			,@SERVICEFLAG AS [ServiceFlag]
			,@COMPUTERNAME AS [ComputerName]
		) AS TB2
		ON TB1.[Domain] = TB2.[Domain]
			AND TB1.[ServiceFlag] = TB2.[ServiceFlag]
			AND TB1.[ComputerName] = TB2.[ComputerName]
	WHEN MATCHED
		THEN
			UPDATE
			SET --[Domain] = @DOMAIN,
				--[ServiceFlag] = @SERVICEFLAG,
				[ComputerName] = @COMPUTERNAME + '.' + @DOMAIN
				,[HostName] = @COMPUTERNAME
				,[FQDN] = @COMPUTERNAME + '.' + @DOMAIN
				,[IPAddress] = @IPADDRESS
				,[UTCMonitored] = GETUTCDATE()
	WHEN NOT MATCHED
		THEN
			INSERT
			   ([Domain]
			   ,[ServiceFlag]
			   ,[ComputerName]
			   ,[HostName]
			   ,[FQDN]
			   ,[IPAddress]
			   ,[UTCMonitored]
			   ,[CorpID])
		 VALUES
			   (@Domain
			   ,@ServiceFlag
			   ,@ComputerName + '.' + @Domain
			   ,@ComputerName
			   ,@ComputerName + '.' + @Domain
			   ,@IPAddress
			   ,GETUTCDATE()
			   ,@CorpID);
END
GO
/****** Object:  StoredProcedure [dbo].[USP_MERGE_TEST_ON_DEMAND]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 /*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHR
-- 작성일 : 2014.12.12  
-- 수정일 : 2014.12.12  
-- 설  명 :  
-- 실  행 : [dbo].[USP_CREATE_TABLE_PARAMETER] 'TB_TestOnDemand'
[dbo].[USP_CREATE_PROC_PARAMETER] 'USP_MERGE_TEST_ON_DEMAND'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  

CREATE PROCEDURE  [dbo].[USP_MERGE_TEST_ON_DEMAND] 
	@IDX	int
	,@DemandDate		datetime
	,@Company			nvarchar(20)
	,@TOD_Code			nvarchar(5)
	,@TOD_Demander		nvarchar(50)
	,@TOD_Result		nvarchar(1)
	,@TOD_ResultScript	nvarchar(MAX)
	,@CompleteDate		datetime
AS
BEGIN

	SET NOCOUNT ON;
	
	MERGE dbo.TB_TestOnDemand AS TB1
	USING (SELECT @IDX AS  IDX  ) AS TB2
	   ON TB1.IDX = TB2.IDX 
	 WHEN matched THEN
	 UPDATE
	    SET   
			TOD_Result = @TOD_Result, 
			TOD_ResultScript = @TOD_ResultScript, 
			CompleteDate = GETUTCDATE()
	 WHEN not matched THEN
	 INSERT (  DemandDate		
	 		  ,Company			
	 		  ,TOD_Code			
			  ,TOD_Demander		
			  ,TOD_Result		
	 		  ,TOD_ResultScript	
	 		  ,CompleteDate		
			)
	 VALUES (  GETUTCDATE() --@DemandDate		 
			  ,@Company			
			  ,@TOD_Code			
			  ,@TOD_Demander		
			  ,@TOD_Result		
			  ,@TOD_ResultScript	
			  ,@CompleteDate	);	

  SELECT ISNULL(CAST(SCOPE_IDENTITY() AS INT),@IDX) AS IDX 
END


GO
/****** Object:  StoredProcedure [dbo].[USP_MERGE_USER_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.23  
-- 수정일 : 2014.12.23  
-- 설   명 : USER LIST MARGE
-- 실   행 : EXEC [dbo].[USP_MERGE_USER_LIST] 'twkim',N'김태원','nf3j54XWVGk=','','','Y'
-------------------------------------------------------------------------------------  
-- 수   정   일 : 
-- 수   정   자 : 
-- 수 정  내 용 : 
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_MERGE_USER_LIST] 
	@USERID			NVARCHAR(10),
	@USERNAME		NVARCHAR(50),
	@PASSWORD		NVARCHAR(1000),
	@MAILADDRESS	NVARCHAR(50),
	@MOBILEPHONE	NVARCHAR(15),
	@USEYN			CHAR(1)
AS
BEGIN
	SET NOCOUNT ON;
	
	MERGE	[dbo].[TB_USER] AS TB1
	USING	(SELECT	@USERID	AS [USERID])	AS TB2
	   ON	TB1.[USERID] = TB2.[USERID]

	 WHEN	MATCHED THEN
   UPDATE
      SET	[USERID] = @USERID,
			[USERNAME] = @USERNAME,
			[PASSWORD] = @PASSWORD,
			[MAILADDRESS] = @MAILADDRESS,
			[MOBILEPHONE] = @MOBILEPHONE,
			[USEYN] = @USEYN,
			[CREATE_DATE] = GETUTCDATE()
	 WHEN	NOT MATCHED THEN
   INSERT	(	[USERID],
				[USERNAME],
				[PASSWORD],
				[MAILADDRESS],
				[MOBILEPHONE],
				[USEYN],
				[CREATE_DATE]
			)
	VALUES	(	@USERID,
				@USERNAME,
				@PASSWORD,
				@MAILADDRESS,
				@MOBILEPHONE,
				@USEYN,
				GETUTCDATE()
			);
END


GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_ADVERTISEMENT_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.11
-- 수정일 : 2014.12.11  
-- 설   명 : AD DS Advertisement List
-- 실   행 : EXEC [dbo].[USP_SELECT_ADVERTISEMENT_LIST] 'LGE','ADDS'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_ADVERTISEMENT_LIST] 
	@COMPANYCODE NVARCHAR(10)  
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_' + @ADSERVICE + 'Advertisement';

 
	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

 
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLENAME + ']'
 
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..
 
	SET @PARAM = N' @MonitorTime nvarchar(25)'

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME
 
END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_ANY_TABLE]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- [UP_SELECT_ANY_TABLE]
-- 동적쿼리, 입력받은 테이블명으로 SELECT 결과를 반환
-- EXEC USP_SELECT_ANY_TABLE 'TB_LGE_NET_DHCPServiceAvailability', '2014-12-09 16:50'
-- =============================================
CREATE PROCEDURE [dbo].[USP_SELECT_ANY_TABLE]
(
	@TABLE_NAME nvarchar(100)
   ,@MON_TIME nvarchar(25) 
)
AS
BEGIN

	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

	--SET @TABLE_NAME = 'TB_LGE_NET_PERFORMANCE'
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLE_NAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLE_NAME + ']'

	--SET @SQL = @SQL + 'WHERE TimeStamp > ''2014-12-09 16:50'''
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..

	--SELECT @SQL

	SET @PARAM = N' @MonitorTime nvarchar(25) '

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @MON_TIME --'2014-12-09 16:50'

END





GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_CODE_SUB]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHL
-- 작성일 : 2014.12.09  
-- 수정일 : 2014.12.09  
-- 설   명 : Common SUB CODE 목록조회
-- 실   행 : EXEC [dbo].[USP_SELECT_CODE_SUB] 'S005'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_CODE_SUB]
	-- Add the parameters for the stored procedure here
	@CLASS_CODE VARCHAR(4)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT [CLASS_CODE]
		,[SUB_CODE]
		,[USE_YN]
		,[CODE_NAME]
		,[SORT_SEQ]
		,[VALUE1]
		,[VALUE2]
		,[CREATOR_ID]
		,[CREATE_DATE]
		,[UPDATER_ID]
		,[UPDATE_DATE]
	FROM dbo.TB_COMMON_CODE_SUB
	WHERE CLASS_CODE = @CLASS_CODE
		AND USE_YN = 'Y'
	ORDER BY [SORT_SEQ]
END
GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_CONNECTIVITY_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHR
-- 작성일 : 2014.12.10
-- 수정일 : 2014.12.10  
-- 설   명 : 회사별 서비스 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_CONNECTIVITY_LIST] 'LGE','CONNECTIVITY'

exec sp_executesql N'[dbo].[USP_SELECT_CONNECTIVITY_LIST] @COMPANYCODE, @ADSERVICE',N'@COMPANYCODE nvarchar(3),@ADSERVICE nvarchar(12)',@COMPANYCODE=N'LGE',@ADSERVICE=N'CONNECTIVITY'
[dbo].[USP_CREATE_DTO_CODE] 'TB_LGE_NET_CONNECTIVITY'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_CONNECTIVITY_LIST]
	-- Add the parameters for the stored procedure here
	@COMPANYCODE NVARCHAR(10)
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @TABLENAME NVARCHAR(50)
		,@CTABLE NVARCHAR(50)
	DECLARE @DATETIME DATETIME

	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

	SELECT @CTABLE = VALUE1
	FROM TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
		AND SUB_CODE = @COMPANYCODE

	SET @TABLENAME = 'TB_' + @CTABLE + '_CONNECTIVITY';

	DECLARE @SQL NVARCHAR(max)
	DECLARE @COLUMNS_NAME NVARCHAR(max)
	DECLARE @PARAM NVARCHAR(100)

	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)
	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' ,  REPLACE(B.IPAddress,''Null'','''')  AS IPAddress FROM [ADSysMon].[dbo].[' + @TABLENAME + '] A LEFT OUTER JOIN  ( SELECT DISTINCT ComputerName AS Computer, IPAddress FROM [dbo].[TB_SERVERS] ) B ON ( A.ComputerName = B.Computer ) '
	SET @SQL = @SQL + ' WHERE A.UTCMonitored > @MonitorTime '
	SET @PARAM = N' @MonitorTime nvarchar(25), @pADSERVICE nvarchar(10)'

	EXEC SP_EXECUTESQL @SQL
		,@PARAM
		,@MonitorTime = @DATETIME
		,@pADSERVICE = @ADSERVICE
END
GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_DASHBOARD_COM]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =============================================
-- [USP_SELECT_DASHBOARD_COM]
-- DASH BOARD Lv0 회사별 Service Error Count 
-- EXEC [dbo].[USP_SELECT_DASHBOARD_COM] 'ADadmin'
-- =============================================
CREATE PROCEDURE [dbo].[USP_SELECT_DASHBOARD_COM]
(
	@USERID nvarchar(10)
)
AS
BEGIN


	DECLARE @COMPANYCODE NVARCHAR(20)  
	DECLARE @ADSERVICE NVARCHAR(16)
	DECLARE @DATETIME DATETIME


	IF OBJECT_ID('tempdb..#TMP_TB_BYCOMPANY') IS NOT NULL
		DROP TABLE #TMP_TB_BYCOMPANY

	CREATE TABLE #TMP_TB_BYCOMPANY (COMPANY nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS, ADSERVICE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS, MonitoredTime datetime, CHK_CNT int)

	DECLARE ADM_CURSOR_COM CURSOR FOR --SELECT VALUE2 FROM TB_MANAGE_COMPANY_USER U INNER JOIN TB_COMMON_CODE_SUB B 
									  --	                ON ( U.COMPANYCODE = B.SUB_CODE AND B.CLASS_CODE = '0001' AND U.USERID = @USERID ) 
									  --         ORDER BY SORT_SEQ ASC

									  -- 해당 company 만 조회할 경우 위에 쿼리로 변경
									  SELECT VALUE2 FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] 
									   WHERE CLASS_CODE = '0001' --AND VALUE2 IN ( SELECT [VALUE2] FROM TB_MANAGE_COMPANY_USER U INNER JOIN TB_COMMON_CODE_SUB B ON ( U.COMPANYCODE = B.SUB_CODE AND B.CLASS_CODE = '0001' AND U.USERID = @USERID ) )
									   ORDER BY SORT_SEQ ASC
 
	OPEN ADM_CURSOR_COM

	FETCH NEXT FROM ADM_CURSOR_COM INTO @COMPANYCODE

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--SELECT @COMPANYCODE
			SET @ADSERVICE = 'ADDS'
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)

			INSERT INTO #TMP_TB_BYCOMPANY
			SELECT Company, ADService, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem 
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement]  -- SELECT * FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANYCODE AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService


			SET @ADSERVICE = 'ADCS'
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)

			INSERT INTO #TMP_TB_BYCOMPANY
			SELECT Company, ADService, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem 
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANYCODE AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService


			SET @ADSERVICE = 'DNS'
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)

			INSERT INTO #TMP_TB_BYCOMPANY
			SELECT Company, ADService, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem 
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANYCODE AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService

			SET @ADSERVICE = 'DHCP'
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)

			INSERT INTO #TMP_TB_BYCOMPANY
			SELECT Company, ADService, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem 
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANYCODE AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService

			SET @ADSERVICE = 'RADIUS'
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)

			INSERT INTO #TMP_TB_BYCOMPANY
			SELECT Company, ADService, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem 
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANYCODE AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService

		FETCH NEXT FROM ADM_CURSOR_COM INTO @COMPANYCODE
	END 

	CLOSE ADM_CURSOR_COM
	DEALLOCATE ADM_CURSOR_COM



	--SELECT COMPANY, ADSERVICE, CHK_CNT FROM #TMP_TB_BYCOMPANY

	--SELECT COM.VALUE2, SVC.SUB_CODE 
	--  FROM (SELECT VALUE2, SORT_SEQ FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] WHERE CLASS_CODE = '0001') COM
	--	 , (SELECT SUB_CODE, SORT_SEQ FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] WHERE CLASS_CODE = '0002') SVC
	-- ORDER BY COM.SORT_SEQ, SVC.SORT_SEQ 


	--SELECT  LST.VALUE2, LST.SUB_CODE, CHK.COMPANY, CHK.ADSERVICE, CHK.CHK_CNT
	--SELECT  LST.VALUE2 as COMPANY, LST.SUB_CODE as ADSERVICE, CHK.CHK_CNT


	SELECT ST.CODE_NAME as COMPANY, ST.SUB_CODE as COMPANY_SUBCODE
	    , IIF(ORD.ADDS        IS NULL, 0, ORD.ADDS)        AS ADDS
		, IIF(ORD.ADCS        IS NULL, 0, ORD.ADCS)        AS ADCS
		, IIF(ORD.DNS         IS NULL, 0, ORD.DNS)         AS DNS
		, IIF(ORD.DHCP        IS NULL, 0, ORD.DHCP)        AS DHCP
		, IIF(ORD.RADIUS        IS NULL, 0, ORD.RADIUS)        AS RADIUS
		, TM.MonitoredTime AS MonitoredTime 
	  FROM (

		SELECT PVT.COMPANY, PVT.ADDS, PVT.ADCS, PVT.DNS, PVT.DHCP,  PVT.RADIUS
		  FROM (

			SELECT  LST.VALUE2 as COMPANY, LST.SUB_CODE as ADSERVICE, CHK.CHK_CNT
			  FROM (SELECT COM.VALUE2, SVC.SUB_CODE, COM.SORT_SEQ
					  FROM (SELECT VALUE2, SORT_SEQ FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] WHERE CLASS_CODE = '0001'
							 --AND VALUE2 IN ( SELECT [VALUE2] FROM TB_MANAGE_COMPANY_USER U INNER JOIN TB_COMMON_CODE_SUB B ON ( U.COMPANYCODE = B.SUB_CODE AND B.CLASS_CODE = '0001' ) )
						   ) COM
						 , (SELECT SUB_CODE, SORT_SEQ FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] WHERE CLASS_CODE = '0002') SVC
				   ) AS LST
				   LEFT OUTER JOIN
				   (SELECT COMPANY, ADSERVICE, CHK_CNT, MonitoredTime FROM #TMP_TB_BYCOMPANY) AS CHK
				   ON LST.VALUE2 = CHK.COMPANY AND LST.SUB_CODE = CHK.ADSERVICE
			 ) AS MST
			 PIVOT (SUM(CHK_CNT) FOR ADSERVICE IN ([ADDS],[ADCS],[DNS],[DHCP], [RADIUS])) AS PVT
		 ) ORD 
		 LEFT JOIN (SELECT SUB_CODE, CODE_NAME, VALUE2, SORT_SEQ FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] WHERE CLASS_CODE = '0001') ST ON ST.VALUE2 = ORD.COMPANY 
		 LEFT JOIN (SELECT COMPANY, MAX(MonitoredTime) as MonitoredTime FROM #TMP_TB_BYCOMPANY GROUP BY COMPANY) TM ON TM.COMPANY = ORD.COMPANY  -- 이 부분은 TaskLog 에서 가져와야함 추후 수정

	 -- 해당 company 만 조회할 경우 아래 조건을 포함한다.
	 --WHERE ORD.COMPANY IN (SELECT VALUE2 FROM TB_MANAGE_COMPANY_USER U INNER JOIN TB_COMMON_CODE_SUB B ON ( U.COMPANYCODE = B.SUB_CODE AND B.CLASS_CODE = '0001' AND U.USERID = @USERID ) )

	 ORDER BY ST.SORT_SEQ

	 

END








GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_DASHBOARD_COM_DIV]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
/* =============================================
-- [USP_SELECT_DASHBOARD_COM]
-- DASH BOARD Lv1 고객사별 Service Error Count 
 --EXEC [dbo].[USP_SELECT_DASHBOARD_COM_DIV] 'HIP', 'ADDS'
 --EXEC [dbo].[USP_SELECT_DASHBOARD_COM_DIV] 'LGE.NET', 'ADCS'
 --EXEC [dbo].[USP_SELECT_DASHBOARD_COM_DIV] 'LGE.NET', 'DNS'
 EXEC [dbo].[USP_SELECT_DASHBOARD_COM_DIV] 'dotnetsoft', 'RADIUS'
-- =============================================*/
CREATE PROCEDURE [dbo].[USP_SELECT_DASHBOARD_COM_DIV]
(
	@COMPANYCODE nvarchar(50),
	@ADSERVICE nvarchar(6)
)
AS
BEGIN

	DECLARE @COM_CODE nvarchar(50)
	DECLARE @DATETIME DATETIME
	DECLARE @COMPANY_NAME NVARCHAR(50)

		 
	SET @COMPANY_NAME = (SELECT [dbo].[UFN_GET_DOMAIN_NAME](@COMPANYCODE))

	IF OBJECT_ID('tempdb..#TMP_TB_BYSERVICE') IS NOT NULL
		DROP TABLE #TMP_TB_BYSERVICE

	CREATE TABLE #TMP_TB_BYSERVICE (COMPANY nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS, ADSERVICE nvarchar(10), Serviceitem nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS, MonitoredTime datetime, CHK_CNT int)

	DECLARE ADM_CURSOR_COM CURSOR FOR SELECT VALUE2 FROM TB_COMMON_CODE_SUB WHERE CLASS_CODE = '0001' AND SUB_CODE = @COMPANYCODE
 
	OPEN ADM_CURSOR_COM

 
	FETCH NEXT FROM ADM_CURSOR_COM INTO @COM_CODE
 

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COM_CODE, @ADSERVICE)
			--SELECT @COM_CODE, @DATETIME, @ADSERVICE
			
			INSERT INTO #TMP_TB_BYSERVICE
			SELECT Company, ADService, Serviceitem, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem 
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANY_NAME AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService, Serviceitem

		FETCH NEXT FROM ADM_CURSOR_COM INTO @COM_CODE
	END 

	CLOSE ADM_CURSOR_COM
	DEALLOCATE ADM_CURSOR_COM

	--SELECT * FROM #TMP_TB_BYSERVICE

	IF @ADSERVICE = 'ADDS'
	BEGIN
		SELECT PVT.[Event],PVT.[Service],PVT.[Performance Data] as PerformanceData,PVT.[Replication],PVT.[Sysvol Shares] as SysvolShares
		      ,PVT.[Topology And Intersite Messaging] as TopologyAndIntersiteMessaging,PVT.[Repository],PVT.[Advertisement],PVT.[W32TimeSync]
		  FROM (
				SELECT VALUE2 AS ADService,  IIF(TMP.CHK_CNT IS NULL, 0, TMP.CHK_CNT) AS ErrorCount, SUB.CODE_NAME AS ADServiceName
				  FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS SUB 
				  LEFT OUTER JOIN (SELECT ADSERVICE, Serviceitem, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE	GROUP BY ADSERVICE, Serviceitem)
					AS TMP ON SUB.SUB_CODE = TMP.Serviceitem
				 WHERE CLASS_CODE = '0003'
				   AND VALUE2 = @ADSERVICE
				) MST
		 PIVOT (SUM(ErrorCount) FOR ADServiceName IN ([Event],[Service],[Performance Data],[Replication],[Sysvol Shares],[Topology And Intersite Messaging],[Repository],[Advertisement],[W32TimeSync])) AS PVT
	END

	IF @ADSERVICE = 'ADCS'
	BEGIN
		SELECT PVT.[Event],PVT.[Service],PVT.[Performance Data] as PerformanceData,PVT.[Service Availability] as ServiceAvailability,PVT.[Enrollment Policy Templates] as EnrollmentPolicyTemplates
		  FROM (
				SELECT VALUE2 AS ADService,  IIF(TMP.CHK_CNT IS NULL, 0, TMP.CHK_CNT) AS ErrorCount, SUB.CODE_NAME AS ADServiceName
				  FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS SUB 
				  LEFT OUTER JOIN (SELECT ADSERVICE, Serviceitem, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE	GROUP BY ADSERVICE, Serviceitem)
					AS TMP ON SUB.SUB_CODE = TMP.Serviceitem
				 WHERE CLASS_CODE = '0003'
				   AND VALUE2 = @ADSERVICE
				) MST
		 PIVOT (SUM(ErrorCount) FOR ADServiceName IN ([Event],[Service],[Performance Data],[Service Availability],[Enrollment Policy Templates])) AS PVT
	END

	IF @ADSERVICE = 'DNS'
	BEGIN
		SELECT PVT.[Event],PVT.[Service],PVT.[Performance Data] as PerformanceData,PVT.[Service Availability] as ServiceAvailability
		  FROM (
				SELECT VALUE2 AS ADService,  IIF(TMP.CHK_CNT IS NULL, 0, TMP.CHK_CNT) AS ErrorCount, SUB.CODE_NAME AS ADServiceName
				  FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS SUB 
				  LEFT OUTER JOIN (SELECT ADSERVICE, Serviceitem, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE	GROUP BY ADSERVICE, Serviceitem)
					AS TMP ON SUB.SUB_CODE = TMP.Serviceitem
				 WHERE CLASS_CODE = '0003'
				   AND VALUE2 = @ADSERVICE
				) MST
		 PIVOT (SUM(ErrorCount) FOR ADServiceName IN ([Event],[Service],[Performance Data],[Service Availability])) AS PVT
	END


	IF @ADSERVICE = 'DHCP'
	BEGIN
		SELECT PVT.[Event],PVT.[Service],PVT.[Performance Data] as PerformanceData,PVT.[Service Availability] as ServiceAvailability
		  FROM (
				SELECT VALUE2 AS ADService,  IIF(TMP.CHK_CNT IS NULL, 0, TMP.CHK_CNT) AS ErrorCount, SUB.CODE_NAME AS ADServiceName
				  FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS SUB 
				  LEFT OUTER JOIN (SELECT ADSERVICE, Serviceitem, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE	GROUP BY ADSERVICE, Serviceitem)
					AS TMP ON SUB.SUB_CODE = TMP.Serviceitem
				 WHERE CLASS_CODE = '0003'
				   AND VALUE2 = @ADSERVICE
				) MST
		 PIVOT (SUM(ErrorCount) FOR ADServiceName IN ([Event],[Service],[Performance Data],[Service Availability])) AS PVT
	END

	IF @ADSERVICE = 'RADIUS'
	BEGIN
		SELECT PVT.[Event],PVT.[Service],PVT.[Performance Data] as PerformanceData,PVT.[Service Availability] as ServiceAvailability
		  FROM (
				SELECT VALUE2 AS ADService,  IIF(TMP.CHK_CNT IS NULL, 0, TMP.CHK_CNT) AS ErrorCount, SUB.CODE_NAME AS ADServiceName
				  FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS SUB 
				  LEFT OUTER JOIN (SELECT ADSERVICE, Serviceitem, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE	GROUP BY ADSERVICE, Serviceitem)
					AS TMP ON SUB.SUB_CODE = TMP.Serviceitem
				 WHERE CLASS_CODE = '0003'
				   AND VALUE2 = @ADSERVICE
				) MST
		 PIVOT (SUM(ErrorCount) FOR ADServiceName IN ([Event],[Service],[Performance Data],[Service Availability])) AS PVT
	END




 


--SELECT * FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB]  WHERE CLASS_CODE = '0003'




	--SELECT VALUE2 AS ADService, SUB.CODE_NAME AS ADServiceName, IIF(TMP.CHK_CNT IS NULL, 0, TMP.CHK_CNT) AS ErrorCount, SUB.SUB_CODE, TMP.MonitoredTime, SUB.SORT_SEQ
	--  FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS SUB 
	--  LEFT OUTER JOIN (SELECT ADSERVICE, Serviceitem, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE	GROUP BY ADSERVICE, Serviceitem)
 --       AS TMP ON SUB.SUB_CODE = TMP.Serviceitem
	-- WHERE CLASS_CODE = '0003'
	--   AND VALUE2 = @ADSERVICE
 --	 ORDER BY SORT_SEQ



END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_DASHBOARD_CONNECTIVITY]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHR
-- 작성일 : 2014.12.10
-- 수정일 : 2014.12.10  
-- 설   명 : 회사별 서비스 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_DASHBOARD_CONNECTIVITY] 'LGE' 

exec sp_executesql N'[dbo].[USP_SELECT_CONNECTIVITY_LIST] @COMPANYCODE, @ADSERVICE',N'@COMPANYCODE nvarchar(3),@ADSERVICE nvarchar(12)',@COMPANYCODE=N'LGE',@ADSERVICE=N'CONNECTIVITY'
[dbo].[USP_CREATE_DTO_CODE] 'TB_LGE_NET_CONNECTIVITY'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_DASHBOARD_CONNECTIVITY] 
	@COMPANYCODE NVARCHAR(10)  
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME =  [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, 'CONNECT')
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_CONNECTIVITY';
 


  
	IF EXISTS 
	(
		SELECT   '*'
		FROM     sys.objects 
		WHERE    object_id = OBJECT_ID(@TABLENAME) 
				 AND 
				 type in (N'U')
	)
	BEGIN
	 
		DECLARE @SQL nvarchar(max)
		DECLARE @COLUMNS_NAME nvarchar(max)
		DECLARE @PARAM nvarchar(100)

 
		SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

		SET @SQL = 'SELECT ISNULL(CanPing, 9999) AS CanPing, ISNULL(CanPort135, 9999) AS CanPort135, ISNULL(CanPort5985, 9999) AS CanPort5985 FROM
					(
						SELECT 
							SUM(CASE CanPing WHEN ''True'' THEN 0 ELSE 1 END) CanPing
							, SUM(CASE CanPort135 WHEN ''True'' THEN 0 ELSE 1 END) CanPort135
							, SUM(CASE CanPort5985 WHEN ''True'' THEN 0 ELSE 1 END) CanPort5985
						FROM [ADSysMon].[dbo].[' + @TABLENAME + ']  '
 
		SET @SQL = @SQL + ' WHERE  UTCMonitored > @MonitorTime  ) A'
 
		SET @PARAM = N' @MonitorTime DATETIME '

		--select @SQL, @DATETIME
		EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME  
  
	END
	ELSE
	BEGIN
		SELECT 0 AS CanPing, 0 AS CanPort135, 0 AS CanPort5985
	END
END
GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_DASHBOARD_SVC]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- [USP_SELECT_DASHBOARD_COM]
-- DASH BOARD Lv0 서비스별 Service Error Count 
-- EXEC [dbo].[USP_SELECT_DASHBOARD_SVC_DIV] 'ADadmin', 'DHCP'
-- EXEC [dbo].[USP_SELECT_DASHBOARD_SVC] 'ADadmin'
-- USP_SELECT_DASHBOARD_SVC 는 전체 ADService 모두 조회
-- USP_SELECT_DASHBOARD_SVC_DIV 는 ADService 를 파라미터로 받아 해당 ADService 만 조회한다.
-- =============================================
CREATE PROCEDURE [dbo].[USP_SELECT_DASHBOARD_SVC]
(
	@USERID nvarchar(10)
)
AS
BEGIN


	DECLARE @COMPANYCODE NVARCHAR(20)  
	DECLARE @ADSERVICE NVARCHAR(16)
	DECLARE @DATETIME DATETIME


	IF OBJECT_ID('tempdb..#TMP_TB_BYSERVICE') IS NOT NULL
		DROP TABLE #TMP_TB_BYSERVICE

	CREATE TABLE #TMP_TB_BYSERVICE (COMPANY nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS, ADSERVICE nvarchar(10), Serviceitem nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS, MonitoredTime datetime, CHK_CNT int)

	DECLARE ADM_CURSOR_COM CURSOR FOR --SELECT VALUE2 FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] WHERE CLASS_CODE = '0001' ORDER BY SORT_SEQ ASC
										SELECT VALUE2 FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] 
										 WHERE CLASS_CODE = '0001' -- AND VALUE2 IN ( SELECT [VALUE2] FROM TB_MANAGE_COMPANY_USER U INNER JOIN TB_COMMON_CODE_SUB B ON ( U.COMPANYCODE = B.SUB_CODE AND B.CLASS_CODE = '0001' ) )
										 ORDER BY SORT_SEQ ASC
 
	OPEN ADM_CURSOR_COM

	FETCH NEXT FROM ADM_CURSOR_COM INTO @COMPANYCODE

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--SELECT @COMPANYCODE
			SET @ADSERVICE = 'ADDS'
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)

			INSERT INTO #TMP_TB_BYSERVICE
			SELECT Company, ADService, Serviceitem, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem 
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANYCODE AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService, Serviceitem


			SET @ADSERVICE = 'ADCS'
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)

			INSERT INTO #TMP_TB_BYSERVICE
			SELECT Company, ADService, Serviceitem, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem 
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANYCODE AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService, Serviceitem


			SET @ADSERVICE = 'DNS'
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)

			INSERT INTO #TMP_TB_BYSERVICE
			SELECT Company, ADService, Serviceitem, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem 
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANYCODE AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService, Serviceitem

			SET @ADSERVICE = 'DHCP'
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)

			INSERT INTO #TMP_TB_BYSERVICE
			SELECT Company, ADService, Serviceitem, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem 
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANYCODE AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService, Serviceitem


		FETCH NEXT FROM ADM_CURSOR_COM INTO @COMPANYCODE
	END 

	CLOSE ADM_CURSOR_COM
	DEALLOCATE ADM_CURSOR_COM

	--SELECT COMPANY, ADSERVICE, Serviceitem, MonitoredTime, CHK_CNT FROM #TMP_TB_BYSERVICE



	--SELECT ADSERVICE, Serviceitem, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE
	--GROUP BY ADSERVICE, Serviceitem


	SELECT LEFT(SUB.SUB_CODE,2) AS ADService, SUB.CODE_NAME AS ADServiceName, IIF(TMP.CHK_CNT IS NULL, 0, TMP.CHK_CNT) AS ErrorCount, SUB.SUB_CODE, TMP.MonitoredTime, SUB.SORT_SEQ
	  FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS SUB 
	  LEFT OUTER JOIN (SELECT ADSERVICE, Serviceitem, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE	GROUP BY ADSERVICE, Serviceitem)
        AS TMP ON SUB.SUB_CODE = TMP.Serviceitem
	 WHERE CLASS_CODE = '0003' 
 	 ORDER BY SORT_SEQ


-- EXEC [dbo].[USP_SELECT_DASHBOARD_SVC] 'ADadmin'	

	--SELECT COMPANY, ADSERVICE, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE
	--GROUP BY COMPANY, ADSERVICE

END


--SELECT * FROM [ADSysMon].[dbo].[TB_ProblemManagement] 


GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_DASHBOARD_SVC_DIV]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =============================================
-- [USP_SELECT_DASHBOARD_COM]
-- DASH BOARD Lv0 서비스별 Service Error Count 
-- EXEC [dbo].[USP_SELECT_DASHBOARD_SVC_DIV] 'admin', 'RADIUS'
-- EXEC [dbo].[USP_SELECT_DASHBOARD_SVC] 'ADadmin'
-- USP_SELECT_DASHBOARD_SVC 는 전체 ADService 모두 조회
-- USP_SELECT_DASHBOARD_SVC_DIV 는 ADService 를 파라미터로 받아 해당 ADService 만 조회한다.
-- =============================================
CREATE PROCEDURE [dbo].[USP_SELECT_DASHBOARD_SVC_DIV]
(
	@USERID nvarchar(10),
	@ADSERVICE nvarchar(6)
)
AS
BEGIN


	DECLARE @COMPANYCODE NVARCHAR(20)  
	--DECLARE @ADSERVICE NVARCHAR(16)
	DECLARE @DATETIME DATETIME, @LASTDATETIME DATETIME


	IF OBJECT_ID('tempdb..#TMP_TB_BYSERVICE') IS NOT NULL
		DROP TABLE #TMP_TB_BYSERVICE

	CREATE TABLE #TMP_TB_BYSERVICE (COMPANY nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS, ADSERVICE nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS, Serviceitem nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS, MonitoredTime datetime, CHK_CNT int)

	DECLARE ADM_CURSOR_COM CURSOR FOR SELECT VALUE2 FROM TB_MANAGE_COMPANY_USER U INNER JOIN TB_COMMON_CODE_SUB B 
										                ON ( U.COMPANYCODE = B.SUB_CODE AND B.CLASS_CODE = '0001' AND U.USERID = @USERID ) ORDER BY SORT_SEQ ASC
 
	OPEN ADM_CURSOR_COM

	FETCH NEXT FROM ADM_CURSOR_COM INTO @COMPANYCODE

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--SELECT @COMPANYCODE
		--	SET @ADSERVICE = 'ADDS'
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE]( @COMPANYCODE, @ADSERVICE)

			INSERT INTO #TMP_TB_BYSERVICE
			SELECT Company, ADService, Serviceitem, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem 
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANYCODE AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService, Serviceitem

			IF ( @DATETIME IS NOT NULL)
			BEGIN
				SET @LASTDATETIME = @DATETIME
			END

		FETCH NEXT FROM ADM_CURSOR_COM INTO @COMPANYCODE
	END 

	CLOSE ADM_CURSOR_COM
	DEALLOCATE ADM_CURSOR_COM

	--SELECT COMPANY, ADSERVICE, Serviceitem, MonitoredTime, CHK_CNT FROM #TMP_TB_BYSERVICE



	--SELECT ADSERVICE, Serviceitem, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE
	--GROUP BY ADSERVICE, Serviceitem


	SELECT VALUE2 AS ADService, SUB.CODE_NAME AS ADServiceName, IIF(TMP.CHK_CNT IS NULL, 0, TMP.CHK_CNT) AS ErrorCount, SUB.SUB_CODE, ISNULL(TMP.MonitoredTime, @LASTDATETIME) AS MonitoredTime, SUB.SORT_SEQ
	  FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS SUB 
	  LEFT OUTER JOIN (SELECT ADSERVICE, Serviceitem, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE	GROUP BY ADSERVICE, Serviceitem)
        AS TMP ON SUB.SUB_CODE = TMP.Serviceitem
	 WHERE CLASS_CODE = '0003'
	   AND VALUE2 = @ADSERVICE
 	 ORDER BY SORT_SEQ


-- EXEC [dbo].[USP_SELECT_DASHBOARD_SVC] 'ADadmin'	

	--SELECT COMPANY, ADSERVICE, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT FROM #TMP_TB_BYSERVICE
	--GROUP BY COMPANY, ADSERVICE

END

 
GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_DASHBOARD_SVC_DIV_V2]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
-- =============================================
-- [USP_SELECT_DASHBOARD_COM]
-- DASH BOARD Lv0 서비스별 Service Error Count 
-- EXEC [dbo].[USP_SELECT_DASHBOARD_SVC_DIV_V2] 'admin', 'ADDS'
-- =============================================
CREATE PROCEDURE [dbo].[USP_SELECT_DASHBOARD_SVC_DIV_V2]
(
	@USERID nvarchar(10),
	@ADSERVICE nvarchar(6)
)
AS
BEGIN


	DECLARE @COMPANYCODE NVARCHAR(20)  
	--DECLARE @ADSERVICE NVARCHAR(16)
	DECLARE @DATETIME DATETIME, @LASTDATETIME DATETIME


	IF OBJECT_ID('tempdb..#TMP_TB_BYSERVICE') IS NOT NULL
		DROP TABLE #TMP_TB_BYSERVICE

	CREATE TABLE #TMP_TB_BYSERVICE (COMPANY nvarchar(20) collate SQL_Latin1_General_CP1_CI_AS, ADSERVICE nvarchar(10) collate SQL_Latin1_General_CP1_CI_AS , Serviceitem nvarchar(50)  collate SQL_Latin1_General_CP1_CI_AS , MonitoredTime datetime, CHK_CNT int,
 QueryDateTime datetime)

	DECLARE ADM_CURSOR_COM CURSOR FOR SELECT VALUE2 FROM TB_MANAGE_COMPANY_USER U INNER JOIN TB_COMMON_CODE_SUB B 
										                ON ( U.COMPANYCODE = B.SUB_CODE AND B.CLASS_CODE = '0001' AND U.USERID = @USERID ) ORDER BY SORT_SEQ ASC
 
	OPEN ADM_CURSOR_COM

	FETCH NEXT FROM ADM_CURSOR_COM INTO @COMPANYCODE

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--SELECT @COMPANYCODE
		--	SET @ADSERVICE = 'ADDS'
			SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

			INSERT INTO #TMP_TB_BYSERVICE
			SELECT Company, ADService, Serviceitem, CONVERT(varchar(16),Max(MonitoredTime),120) as LastMonitored, COUNT(*) as CntByServiceItem, @DATETIME
			  FROM [ADSysMon].[dbo].[TB_ProblemManagement] 
			 WHERE Company = @COMPANYCODE AND ADService = @ADSERVICE
			   AND MonitoredTime > @DATETIME AND ManageStatus = 'NOTSTARTED'
			 GROUP BY Company, ADService, Serviceitem

			IF ( @DATETIME IS NOT NULL)
			BEGIN
				SET @LASTDATETIME = @DATETIME
			END

		FETCH NEXT FROM ADM_CURSOR_COM INTO @COMPANYCODE
	END 

	CLOSE ADM_CURSOR_COM
	DEALLOCATE ADM_CURSOR_COM


	-- 서비스별 DASH BOARD 에서 각 고객사별로 링크 정보 컬럼 추가
	-- 각 고객사별(company) Code 를 조회하기 위하여 FETCH 를 한번 더 돌린다. LinkCompanyCodes (예: 'LGE^LGC^LGD^... )
	DECLARE @TEMP_TABLE TABLE(ADSERVICE nvarchar(10), ADServiceName nvarchar(100), ErrorCount int, SUB_CODE nvarchar(10), MonitoredTime datetime, SORT_SEQ int, QueryDateTime datetime) 
	DECLARE @OUTPUT_TEMP TABLE(ADSERVICE nvarchar(10), ADServiceName nvarchar(100), ErrorCount int, SUB_CODE nvarchar(10), MonitoredTime datetime, SORT_SEQ int, QueryDateTime datetime, LinkCompanyCodes nvarchar(1000)) 

	INSERT INTO @TEMP_TABLE
	SELECT VALUE2 AS ADService, SUB.CODE_NAME AS ADServiceName, IIF(TMP.CHK_CNT IS NULL, 0, TMP.CHK_CNT) AS ErrorCount, SUB.SUB_CODE, ISNULL(TMP.MonitoredTime, @LASTDATETIME) AS MonitoredTime, SUB.SORT_SEQ, TMP.QueryDateTime
	  FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS SUB 
	  LEFT OUTER JOIN (SELECT ADSERVICE, Serviceitem, MAX(MonitoredTime) as MonitoredTime, SUM(CHK_CNT) as CHK_CNT, MAX(QueryDateTime) as QueryDateTime FROM #TMP_TB_BYSERVICE	GROUP BY ADSERVICE, Serviceitem)
        AS TMP ON SUB.SUB_CODE = TMP.Serviceitem
	 WHERE CLASS_CODE = '0003'
	   AND VALUE2 = @ADSERVICE
	   AND USE_YN = 'Y'
 	 ORDER BY SORT_SEQ

	INSERT INTO @OUTPUT_TEMP
	SELECT ADSERVICE, ADServiceName, ErrorCount, SUB_CODE, MonitoredTime, SORT_SEQ, QueryDateTime, '' 
	  FROM @TEMP_TABLE




	DECLARE @TEMP_ADSERVICE  nvarchar(10)
	DECLARE @TEMP_ErrorCount int
	DECLARE @TEMP_SUB_CODE   nvarchar(10)
	DECLARE @TEMP_QueryDateTime datetime
	DECLARE @TEMP_LinkCompanyCodes nvarchar(50)
	DECLARE @ADD_LinkCompanyCodes nvarchar(1100)

	DECLARE TEMP_CURSOR CURSOR FOR SELECT ADSERVICE, ErrorCount, SUB_CODE, QueryDateTime FROM @TEMP_TABLE 
 
	OPEN TEMP_CURSOR

	FETCH NEXT FROM TEMP_CURSOR INTO @TEMP_ADSERVICE, @TEMP_ErrorCount, @TEMP_SUB_CODE, @TEMP_QueryDateTime

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF @TEMP_ErrorCount > 0
		BEGIN

			SET @TEMP_LinkCompanyCodes = (SELECT [ADSysMon].[dbo].[UFN_GET_COMPANY_CODES](@TEMP_ADSERVICE, @TEMP_SUB_CODE, @TEMP_QueryDateTime))
			--SET @TEMP_LinkCompanyCodes = 'LGE.NET'

			UPDATE @OUTPUT_TEMP SET LinkCompanyCodes = @TEMP_LinkCompanyCodes 
			WHERE ADSERVICE = @TEMP_ADSERVICE AND SUB_CODE = @TEMP_SUB_CODE 

		END

		FETCH NEXT FROM TEMP_CURSOR INTO @TEMP_ADSERVICE, @TEMP_ErrorCount, @TEMP_SUB_CODE, @TEMP_QueryDateTime
	END 

	CLOSE TEMP_CURSOR
	DEALLOCATE TEMP_CURSOR

	SELECT ADSERVICE, ADServiceName, ErrorCount, SUB_CODE, MonitoredTime, SORT_SEQ, QueryDateTime, LinkCompanyCodes FROM @OUTPUT_TEMP


 

END


--SELECT * FROM [ADSysMon].[dbo].[TB_ProblemManagement] 





GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_ENROLLMENT_POLICY_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.11
-- 수정일 : 2014.12.11  
-- 설   명 : AD CS Enrollment Policy Templates
-- 실   행 : EXEC [dbo].[USP_SELECT_ENROLLMENT_POLICY_LIST] 'LGE','ADCS'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_ENROLLMENT_POLICY_LIST] 
	@COMPANYCODE NVARCHAR(10)  
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_' + @ADSERVICE + 'EnrollmentPolicy';

 
	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

 
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLENAME + ']'
 
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..
 
	SET @PARAM = N' @MonitorTime nvarchar(25)'

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME
 
END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_EVENT_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHL
-- 작성일 : 2014.12.09  
-- 수정일 : 2014.12.09  
-- 설   명 : 회사 담당 목록 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_EVENT_LIST] 'LGE','ADDS'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_EVENT_LIST] 
	@COMPANYCODE NVARCHAR(10)  
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_EVENT';

 
	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

 
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLENAME + ']'
 
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime AND ServiceFlag = @pADSERVICE'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) AND ServiceFlag = @pADSERVICE ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..
 
	SET @PARAM = N' @MonitorTime nvarchar(25), @pADSERVICE nvarchar(10)'

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME , @pADSERVICE = @ADSERVICE 
 
 
END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_MANAGE_COMPANY_USER]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHL
-- 작성일 : 2014.12.09  
-- 수정일 : 2014.12.09  
-- 설   명 : 회사 담당 목록 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_MANAGE_COMPANY_USER] 'test'
-------------------------------------------------------------------------------------  
-- 수   정   일 : 2014.12.22
-- 수   정   자 : KTW  
-- 수 정  내 용 : [USEYN]이 'Y' 이것만 가져오도록 수정.
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_MANAGE_COMPANY_USER] 
	@USERID NVARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT 
		USERID,
		COMPANYCODE,
		B.CODE_NAME AS COMPANYNAME,
	    B.VALUE1 AS	TABLENAME,
		B.VALUE2 AS DOMAINNAME
	  FROM dbo.TB_MANAGE_COMPANY_USER A
	  LEFT OUTER JOIN dbo.TB_COMMON_CODE_SUB B ON ( A.COMPANYCODE = B.SUB_CODE AND B.CLASS_CODE = '0001' )
	 WHERE USERID = @USERID
	   AND A.USEYN = 'Y'
 
END





GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_MONITORING_TASK_LOG_DASHBOARD]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 /*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트
-- 작성일 : 2014.12.09  
-- 수정일 : 2014.12.09  
-- 설   명 : 고객사별 DASHBOARD TASKLOG LIST 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_MONITORING_TASK_LOG_DASHBOARD]  'LGE'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_MONITORING_TASK_LOG_DASHBOARD] 
	@COMPANY NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DOMAIN NVARCHAR(50)

	SET @DOMAIN = (SELECT [dbo].[UFN_GET_DOMAIN_NAME](@COMPANY))

	SELECT IIF(ST.ADService = 'CONNECT', 'ZCONNECT', ST.ADService) AS IDX,
		   ST.Company, IIF(ST.ADService = 'CONNECT', 'CONNECTIVITY', ST.ADService) AS TaskName, 
		   ST.TaskType AS START, 
		   CONVERT(nvarchar(16),ST.TaskDate,120) AS STARTDATE, 
		   IIF(ED.TaskType IS NULL, 'END', 'END') AS [END], 
		   CONVERT(nvarchar(16),IIF(ED.TaskDate IS NULL, '', ED.TaskDate),120) AS ENDDATE
			 FROM (SELECT MAX([TaskDate]) AS TaskDate, Company, ADService, TaskType 
					   FROM [ADSysMon].[dbo].[TB_MonitoringTaskLogs] WHERE TaskType = 'BEGIN'
					   AND Company = @DOMAIN
					  GROUP BY Company, ADService, TaskType
					) ST
			 LEFT JOIN 
				  (SELECT MAX([TaskDate]) AS TaskDate, Company, ADService, TaskType 
					   FROM [ADSysMon].[dbo].[TB_MonitoringTaskLogs] WHERE TaskType = 'END'
						AND Company = @DOMAIN
					  GROUP BY Company, ADService, TaskType
				  ) ED
			   ON (ST.Company = ED.Company AND ST.ADService = ED.ADService AND ST.TaskDate <= ED.TaskDate)
	ORDER BY IDX
END






GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_MONITORING_TASK_LOG_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.12
-- 수정일 : 2014.12.12  
-- 설   명 : Monitoring Task Log List 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_MONITORING_TASK_LOG_LIST] 'admin'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_MONITORING_TASK_LOG_LIST]
	-- Add the parameters for the stored procedure here
	@USERID NVARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;

	--SELECT [TaskDate]
	--	,[TaskType]
	--	,[Company]
	--	,[ADService]
	--	,[Serviceitem]
	--	,[ComputerName]
	--	,[TaskScript]
	--	,[CreateDate]
	--FROM [ADSysMon].[dbo].[TB_MonitoringTaskLogs] A
	--LEFT OUTER JOIN TB_COMMON_CODE_SUB S ON (
	--		A.Serviceitem = S.SUB_CODE
	--		AND S.CLASS_CODE = '0003'
	--		)
	--WHERE Company IN (
	--		SELECT [VALUE2]
	--		FROM TB_MANAGE_COMPANY_USER U
	--		INNER JOIN TB_COMMON_CODE_SUB B ON (
	--				U.COMPANYCODE = B.SUB_CODE
	--				AND B.CLASS_CODE = '0001'
	--				AND U.USERID = @USERID
	--				)
	--		)

	-- mwjin7@dotnetsoft.co.kr 2018.08.07 수정...
	SELECT T1.[TaskDate]
		,T1.[TaskType]
		,T1.[Company]
		,T1.[ADService]
		,T1.[Serviceitem]
		,T1.[ComputerName]
		,T1.[TaskScript]
		,T1.[CreateDate]
	FROM [dbo].[TB_MonitoringTaskLogs] T1
	INNER JOIN [dbo].[UFN_Manage_Company_User](@USERID) T2 ON T1.[Company] = T2.[Company]
	WHERE T1.[TaskDate] > DATEADD(MONTH, -1, GETDATE())
	ORDER BY T1.[TaskDate] DESC
END
GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_PERFORMANCE_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.10
-- 수정일 : 2014.12.10  
-- 설   명 : 회사별 퍼포먼스 데이터 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_PERFORMANCE_LIST] 'LGE','ADDS'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_PERFORMANCE_LIST] 
	@COMPANYCODE NVARCHAR(10)  
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_PERFORMANCE';

 
	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

 
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLENAME + ']'
 
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime AND ServiceFlag = @pADSERVICE'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) AND ServiceFlag = @pADSERVICE ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..
 
	SET @PARAM = N' @MonitorTime nvarchar(25), @pADSERVICE nvarchar(10)'

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME , @pADSERVICE = @ADSERVICE  
 
END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_PROBLEM_MANAGEMENT_DASHBOARD]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트
-- 작성일 : 2014.12.09  
-- 수정일 : 2014.12.09  
-- 설   명 : 고객사별 DASHBOARD 오류 관리 LIST 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_PROBLEM_MANAGEMENT_DASHBOARD]  'LGE'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_PROBLEM_MANAGEMENT_DASHBOARD] @COMPANY NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DOMAIN NVARCHAR(50)

	SET @DOMAIN = (
			SELECT [dbo].[UFN_GET_DOMAIN_NAME](@COMPANY)
			)

	SELECT CODE.SUB_CODE AS ManageName
		,ISNULL(MNG.CNT, 0) AS ManageCount
	FROM (
		SELECT SUB_CODE
		FROM [dbo].[TB_COMMON_CODE_SUB]
		WHERE CLASS_CODE = '0005'
		) AS CODE
	LEFT JOIN (
		SELECT Company
			,ManageStatus
			,COUNT([IDX]) AS CNT
		FROM [ADSysMon].[dbo].[TB_ProblemManagement] AS PManage
		WHERE Company = @DOMAIN
			AND MonitoredTime > (CONVERT(VARCHAR(10), DATEADD(day, - 1, GETUTCDATE()), 120) + ' 12:00')
		GROUP BY Company
			,ManageStatus
		) AS MNG ON CODE.SUB_CODE = MNG.ManageStatus
	ORDER BY MNG.ManageStatus
END
GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_PROBLEM_MANAGEMENT_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.12
-- 수정일 : 2015.02.12  
-- 설   명 : ProblemManagement 테이블 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_PROBLEM_MANAGEMENT_LIST] 'test2','dotnetsoft'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   2015.02.12
-- 수   정   자 :   김태원	
-- 수 정  내 용 :   @COMPCD 조건 추가
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_PROBLEM_MANAGEMENT_LIST]
	-- Add the parameters for the stored procedure here
	@USERID NVARCHAR(10)
	,@COMPCD NVARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;

	--SELECT A.[IDX]
	--	,A.[MonitoredTime]
	--	,A.[Company]
	--	,A.[ADService]
	--	,S.CODE_NAME AS [Serviceitem]
	--	,A.[ComputerName]
	--	,A.[ProblemScript]
	--	,A.[ManageStatus]
	--	,A.[Manager]
	--	,A.[ManageScript]
	--	,A.[ManageDate]
	--FROM [dbo].[TB_ProblemManagement] A
	--LEFT OUTER JOIN [dbo].[TB_COMMON_CODE_SUB] S ON (
	--		A.[Serviceitem] = S.[SUB_CODE]
	--		AND S.[CLASS_CODE] = '0003'
	--		)
	--WHERE A.[Company] IN (
	--		SELECT [VALUE2]
	--		FROM [dbo].[TB_MANAGE_COMPANY_USER] U
	--		INNER JOIN [dbo].[TB_COMMON_CODE_SUB] B ON (
	--				U.[COMPANYCODE] = B.[SUB_CODE]
	--				AND B.[CLASS_CODE] = '0001'
	--				AND (@COMPCD = '' OR B.[SUB_CODE] = @COMPCD)
	--				AND U.[USERID] = @USERID
	--				)
	--		WHERE U.USEYN = 'Y'
	--		)
	--ORDER BY IDX DESC

	-- mwjin7 2018.07.30
	SELECT T1.[IDX]
		,T1.[MonitoredTime]
		,T1.[Company]
		,T1.[ADService]
		,T3.CODE_NAME AS [Serviceitem]
		,T1.[ComputerName]
		,T1.[ProblemScript]
		,T1.[ManageStatus]
		,T1.[Manager]
		,T1.[ManageScript]
		,T1.[ManageDate]
	FROM [dbo].[TB_ProblemManagement] T1
	INNER JOIN [dbo].[UFN_Manage_Company_User](@USERID) T2 ON T1.[Company] = T2.[Company] AND (@COMPCD = '' OR T2.[SUB_CODE] = @COMPCD)
	LEFT OUTER JOIN [dbo].[TB_COMMON_CODE_SUB] T3 ON ( T1.[Serviceitem] = T3.[SUB_CODE] AND T3.[CLASS_CODE] = '0003')
	WHERE T1.[MonitoredTime] > DATEADD(MONTH, -1, GETUTCDATE())
	ORDER BY T1.[IDX] DESC
END
GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_REPLICATION_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.11
-- 수정일 : 2014.12.11  
-- 설   명 : AD DS Replication List
-- 실   행 : EXEC [dbo].[USP_SELECT_REPLICATION_LIST] 'LGE','ADDS'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_REPLICATION_LIST] 
	@COMPANYCODE NVARCHAR(10)  
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_' + @ADSERVICE + 'Replication';

 
	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

 
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLENAME + ']'
 
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..
 
	SET @PARAM = N' @MonitorTime nvarchar(25)'

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME
 
END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_REPOSITORY_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.11
-- 수정일 : 2014.12.11  
-- 설   명 : AD DS Repository List
-- 실   행 : EXEC [dbo].[USP_SELECT_REPOSITORY_LIST] 'LGE','ADDS'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_REPOSITORY_LIST] 
	@COMPANYCODE NVARCHAR(10)  
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_' + @ADSERVICE + 'Repository';

 
	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

 
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLENAME + ']'
 
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..
 
	SET @PARAM = N' @MonitorTime nvarchar(25)'

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME
 
END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_SERVER_CHART_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 
-- 작성일 : 2014.12.22
-- 수정일 : 2014.12.22  
-- 설   명 : 서버별 CPU, Memory, Disk 차트 데이터 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_SERVER_CHART_LIST] 'LGE'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_SERVER_CHART_LIST]
	-- Add the parameters for the stored procedure here
	@COMPANYCODE NVARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @TABLENAME NVARCHAR(50)
		,@CTABLE NVARCHAR(50)

	SELECT @CTABLE = VALUE1
	FROM TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
		AND SUB_CODE = @COMPANYCODE

	SET @TABLENAME = 'TB_' + @CTABLE + '_PERFORMANCE';

	DECLARE @SQL NVARCHAR(MAX)

	--mwjin7@dotnetsoft.co.kr 2018.08.06 쿼리 수정...
	SET @SQL = ' SELECT DISTINCT T1.ComputerName
					,T2.ProcessTotal
					,T2.ProcessUTCDate
					,T3.MemoryMB
					,T3.MemoryUTCDate
					,T4.DiskQueue
					,T4.DiskUTCDate
					,T1.IPAddress
				FROM [ADSysMon].[dbo].[TB_SERVERS] T1
				INNER JOIN (
					SELECT A.[ComputerName]
						,A.[UTCMonitored] AS ProcessUTCDate
						,A.[VALUE] AS ProcessTotal
					FROM [ADSysMon].[dbo].[' + @TABLENAME + '] A
					WHERE [InstanceName] = ''_total''
						AND [UTCMonitored] = (
							SELECT MAX([UTCMonitored])
							FROM [ADSysMon].[dbo].[' + @TABLENAME + '] B
							WHERE A.[ComputerName] = B.[ComputerName]
								AND [InstanceName] = ''_total''
								AND [PATH] LIKE ''%\Processor(_Total)\%''
							GROUP BY [ComputerName]
							)
						AND [PATH] LIKE ''%\Processor(_Total)\%''
					) T2 ON (T1.[ComputerName] = T2.[ComputerName])
				INNER JOIN (
					SELECT A.[ComputerName]
						,A.[UTCMonitored] AS MemoryUTCDate
						,A.[VALUE] AS MemoryMB
					FROM [ADSysMon].[dbo].[' + @TABLENAME + '] A
					WHERE (
							[InstanceName] = ''Null''
							OR [InstanceName] IS NULL
							)
						AND [UTCMonitored] = (
							SELECT MAX([UTCMonitored])
							FROM [ADSysMon].[dbo].[' + @TABLENAME + '] B
							WHERE A.[ComputerName] = B.[ComputerName]
								AND (
									[InstanceName] = ''Null''
									OR [InstanceName] IS NULL
									)
								AND [PATH] LIKE ''%\Memory\Available MBytes''
							GROUP BY [ComputerName]
							)
						AND [PATH] LIKE ''%\Memory\Available MBytes''
					) T3 ON (T1.[ComputerName] = T3.[ComputerName])
				INNER JOIN (
					SELECT A.[ComputerName]
						,A.[UTCMonitored] AS DiskUTCDate
						,A.[VALUE] AS DiskQueue
					FROM [ADSysMon].[dbo].[' + @TABLENAME + '] A
					WHERE [InstanceName] = ''_total''
						AND [UTCMonitored] = (
							SELECT MAX([UTCMonitored])
							FROM [ADSysMon].[dbo].[' + @TABLENAME + '] B
							WHERE A.[ComputerName] = B.[ComputerName]
								AND [InstanceName] = ''_total''
								AND [PATH] LIKE ''%\PhysicalDisk(_Total)\Avg. Disk Queue Length''
							GROUP BY [ComputerName]
							)
						AND [PATH] LIKE ''%\PhysicalDisk(_Total)\Avg. Disk Queue Length''
					) T4 ON (T1.[ComputerName] = T4.[ComputerName])
				ORDER BY T1.[ComputerName] '

	/*
	SET @SQL = ' SELECT  
			DISTINCT  T1.ComputerName ,  
			T2.ProcessTotal, ProcessUTCDate,
			T3.MemoryMB, MemoryUTCDate,
			T4.DiskQueue, DiskUTCDate,
			S.IPAddress  
		FROM 
			[ADSysMon].[dbo].[' + @TABLENAME + '] T1
			LEFT OUTER JOIN (
				SELECT   A.ComputerName , UTCMonitored AS ProcessUTCDate, Value AS ProcessTotal
				FROM [ADSysMon].[dbo].[' + @TABLENAME + '] A
				WHERE [PATH] LIKE ''%\Processor(_Total)\% Processor Time%''  
				and UTCMonitored = ( SELECT MAX(UTCMonitored) 
						FROM [ADSysMon].[dbo].[' + @TABLENAME + '] B
						WHERE A.ComputerName = B.ComputerName
							AND PATH LIKE ''%\Processor(_Total)\% Processor Time%''  
						GROUP BY ComputerName  )
				GROUP BY ComputerName , UTCMonitored, VALUE
				) T2 ON ( T1.ComputerName = T2.ComputerName )
			LEFT OUTER JOIN (
				SELECT   A.ComputerName , UTCMonitored AS MemoryUTCDate, Value AS MemoryMB
				FROM [ADSysMon].[dbo].[' + @TABLENAME + '] A
				WHERE [PATH] LIKE ''%\Memory\Available MBytes%''  
				and UTCMonitored = ( SELECT MAX(UTCMonitored) 
						FROM [ADSysMon].[dbo].[' + @TABLENAME + '] B
						WHERE A.ComputerName = B.ComputerName
							AND PATH LIKE ''%\Memory\Available MBytes%''  
						GROUP BY ComputerName  )
				GROUP BY ComputerName , UTCMonitored, VALUE
				) T3 ON ( T1.ComputerName = T3.ComputerName )
			LEFT OUTER JOIN ( 
				SELECT   A.ComputerName , UTCMonitored  AS DiskUTCDate, Value AS DiskQueue
				FROM [ADSysMon].[dbo].[' + @TABLENAME + '] A
				WHERE [PATH] LIKE ''%\PhysicalDisk(_Total)\Avg. Disk Queue Length%''  
				and UTCMonitored = ( SELECT MAX(UTCMonitored) 
					FROM [ADSysMon].[dbo].[' + @TABLENAME + '] B
					WHERE A.ComputerName = B.ComputerName
						AND PATH LIKE ''%\PhysicalDisk(_Total)\Avg. Disk Queue Length%'' 
					GROUP BY ComputerName  )
				GROUP BY ComputerName , UTCMonitored, VALUE
				) T4 ON ( T1.ComputerName = T4.ComputerName )
			 LEFT OUTER JOIN (
					SELECT DISTINCT [ComputerName]
					,[IPAddress] 
					FROM [ADSysMon].[dbo].[TB_SERVERS]  ) S  ON ( T1.ComputerName = S.ComputerName )
		ORDER BY T1.ComputerName '
	*/




	/* 
	SELECT  
		DISTINCT  T1.ComputerName ,  ProcessTotal, MemoryMB, DiskQueue  , IPAddress
	FROM 
		[ADSysMon].[dbo].[TB_LGE_NET_PERFORMANCE] T1
		LEFT OUTER JOIN (
			SELECT   A.ComputerName , UTCMonitored, Value AS ProcessTotal
			FROM [ADSysMon].[dbo].[TB_LGE_NET_PERFORMANCE] A
			WHERE [PATH] LIKE '%\Processor(_Total)\% Processor Time%'  
			and UTCMonitored = ( SELECT MAX(UTCMonitored) 
					FROM [ADSysMon].[dbo].[TB_LGE_NET_PERFORMANCE] B
					WHERE A.ComputerName = B.ComputerName
						AND PATH LIKE '%\Processor(_Total)\% Processor Time%'  
					GROUP BY ComputerName  )
			GROUP BY ComputerName , UTCMonitored, VALUE
			) T2 ON ( T1.ComputerName = T2.ComputerName )
		LEFT OUTER JOIN (
			SELECT   A.ComputerName , UTCMonitored, Value AS MemoryMB
			FROM [ADSysMon].[dbo].[TB_LGE_NET_PERFORMANCE] A
			WHERE [PATH] LIKE '%\Memory\Available MBytes%'  
			and UTCMonitored = ( SELECT MAX(UTCMonitored) 
					FROM [ADSysMon].[dbo].[TB_LGE_NET_PERFORMANCE] B
					WHERE A.ComputerName = B.ComputerName
						AND PATH LIKE '%\Memory\Available MBytes%'  
					GROUP BY ComputerName  )
			GROUP BY ComputerName , UTCMonitored, VALUE
			) T3 ON ( T1.ComputerName = T3.ComputerName )
		LEFT OUTER JOIN ( 
			SELECT   A.ComputerName , UTCMonitored, Value AS DiskQueue
			FROM [ADSysMon].[dbo].[TB_LGE_NET_PERFORMANCE] A
			WHERE [PATH] LIKE '%\PhysicalDisk(_Total)\Avg. Disk Queue Length%'  
			and UTCMonitored = ( SELECT MAX(UTCMonitored) 
				FROM [ADSysMon].[dbo].[TB_LGE_NET_PERFORMANCE] B
				WHERE A.ComputerName = B.ComputerName
					AND PATH LIKE '%\PhysicalDisk(_Total)\Avg. Disk Queue Length%'  
				GROUP BY ComputerName  )
			GROUP BY ComputerName , UTCMonitored, VALUE
			) T4 ON ( T1.ComputerName = T4.ComputerName )
		 LEFT OUTER JOIN (
				SELECT DISTINCT [ComputerName]
				,[IPAddress] 
				FROM [ADSysMon].[dbo].[TB_SERVERS]  ) S  ON ( T1.ComputerName = S.ComputerName )
	ORDER BY T1.ComputerName
	*/
	EXEC SP_EXECUTESQL @SQL
END
GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_SERVER_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHL
-- 작성일 : 2014.12.11
-- 수정일 : 2014.12.11  
-- 설   명 :  
-- 실   행 : EXEC [dbo].[USP_SELECT_SERVER_LIST] 
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_SERVER_LIST]
	-- Add the parameters for the stored procedure here
	@USERID NVARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;

	--SELECT DISTINCT [Domain]
	--	,[ServiceFlag]
	--	,[ComputerName]
	--	,[IPAddress]
	--FROM [ADSysMon].[dbo].[TB_SERVERS]
	--WHERE Domain IN (
	--		SELECT VALUE2
	--		FROM TB_MANAGE_COMPANY_USER U
	--		INNER JOIN TB_COMMON_CODE_SUB B ON (
	--				U.COMPANYCODE = B.SUB_CODE
	--				AND B.CLASS_CODE = '0001'
	--				AND U.USERID = @USERID
	--				)
	--		)
	--ORDER BY Domain
	--	,ServiceFlag
	--	,ComputerName

	-- mwjin7@dotnetsoft.co.kr 2018.08.02 수정
	SELECT DISTINCT T1.[Domain]
		,T1.[ServiceFlag]
		,T1.[ComputerName]
		,T1.[IPAddress]
		,T3.[CorpName]
	--FROM [ADSysMon].[dbo].[TB_SERVERS] T1
	FROM [ADSysMon].[dbo].[TB_SERVERS2] T1 -- 2018.08.14 mwjin7@dotnetsoft.co.kr PowerShell V2 => V3 전환과정 상의 이유로 TB_SERVERS2  생성하고 사용
	INNER JOIN [dbo].[UFN_Manage_Company_User](@USERID) T2 ON T1.[Domain] = T2.[Company]
	LEFT OUTER JOIN [dbo].[TB_MAP_CORP] T3 ON T1.[CorpID] = T3.[CorpID]
	ORDER BY Domain, ServiceFlag, ComputerName
END
GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_SERVICE_AVAILABILITY_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.10
-- 수정일 : 2014.12.10  
-- 설   명 : 회사별 서비스 가용성 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_SERVICE_AVAILABILITY_LIST] 'LGE','DHCP'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_SERVICE_AVAILABILITY_LIST] 
	@COMPANYCODE NVARCHAR(10)  
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_' + @ADSERVICE + 'ServiceAvailability';

 
	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

 
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLENAME + ']'
 
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..
 
	SET @PARAM = N' @MonitorTime nvarchar(25)'

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME
 
END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_SERVICE_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.10
-- 수정일 : 2014.12.10  
-- 설   명 : 회사별 서비스 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_SERVICE_LIST] 'LGE','ADDS'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_SERVICE_LIST] 
	@COMPANYCODE NVARCHAR(10)  
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_SERVICE';

 
	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

 
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLENAME + ']'
 
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime AND ServiceFlag = @pADSERVICE'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) AND ServiceFlag = @pADSERVICE ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..
 
	SET @PARAM = N' @MonitorTime nvarchar(25), @pADSERVICE nvarchar(10)'

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME , @pADSERVICE = @ADSERVICE 
 
 
END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_SERVICE_STATUS]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- [USP_SELECT_DASHBOARD_COM]
-- DASH BOARD Lv0 서비스별 Service Error Count 
-- EXEC [dbo].[USP_SELECT_SERVICE_STATUS] 'admin'
-- =============================================
CREATE PROCEDURE [dbo].[USP_SELECT_SERVICE_STATUS]
	-- Add the parameters for the stored procedure here
	@USERID NVARCHAR(10)
AS
BEGIN
	DECLARE @COMPANYCODE NVARCHAR(20)
	DECLARE @ADSERVICE NVARCHAR(16)
	DECLARE @DATETIME DATETIME

	CREATE TABLE #TMP_TB_BYSERVICE_STATUS (
		COMPANY NVARCHAR(20)
		,ADSERVICE NVARCHAR(10)
		,Serviceitem NVARCHAR(50)
		,MonitoredTime DATETIME
		,CHK_CNT INT
		)

	DECLARE ADM_CURSOR_COM CURSOR
	FOR
	SELECT VALUE2
	FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB]
	WHERE CLASS_CODE = '0001'
		AND VALUE2 IN (
			SELECT [VALUE2]
			FROM TB_MANAGE_COMPANY_USER U
			INNER JOIN TB_COMMON_CODE_SUB B ON (
					U.COMPANYCODE = B.SUB_CODE
					AND B.CLASS_CODE = '0001'
					AND U.USERID = @USERID
					)
			)
	ORDER BY SORT_SEQ ASC

	OPEN ADM_CURSOR_COM

	FETCH NEXT
	FROM ADM_CURSOR_COM
	INTO @COMPANYCODE

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--SELECT @COMPANYCODE
		SET @ADSERVICE = 'ADDS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		INSERT INTO #TMP_TB_BYSERVICE_STATUS
		SELECT Company
			,ADService
			,Serviceitem
			,CONVERT(VARCHAR(16), Max(MonitoredTime), 120) AS LastMonitored
			,COUNT(*) AS CntByServiceItem
		FROM [ADSysMon].[dbo].[TB_ProblemManagement]
		WHERE Company = @COMPANYCODE
			AND ADService = @ADSERVICE
			AND MonitoredTime > @DATETIME
			AND ManageStatus = 'NOTSTARTED'
		GROUP BY Company
			,ADService
			,Serviceitem

		SET @ADSERVICE = 'ADCS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		INSERT INTO #TMP_TB_BYSERVICE_STATUS
		SELECT Company
			,ADService
			,Serviceitem
			,CONVERT(VARCHAR(16), Max(MonitoredTime), 120) AS LastMonitored
			,COUNT(*) AS CntByServiceItem
		FROM [ADSysMon].[dbo].[TB_ProblemManagement]
		WHERE Company = @COMPANYCODE
			AND ADService = @ADSERVICE
			AND MonitoredTime > @DATETIME
			AND ManageStatus = 'NOTSTARTED'
		GROUP BY Company
			,ADService
			,Serviceitem

		SET @ADSERVICE = 'DNS'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		INSERT INTO #TMP_TB_BYSERVICE_STATUS
		SELECT Company
			,ADService
			,Serviceitem
			,CONVERT(VARCHAR(16), Max(MonitoredTime), 120) AS LastMonitored
			,COUNT(*) AS CntByServiceItem
		FROM [ADSysMon].[dbo].[TB_ProblemManagement]
		WHERE Company = @COMPANYCODE
			AND ADService = @ADSERVICE
			AND MonitoredTime > @DATETIME
			AND ManageStatus = 'NOTSTARTED'
		GROUP BY Company
			,ADService
			,Serviceitem

		SET @ADSERVICE = 'DHCP'
		SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE](@COMPANYCODE, @ADSERVICE)

		INSERT INTO #TMP_TB_BYSERVICE_STATUS
		SELECT Company
			,ADService
			,Serviceitem
			,CONVERT(VARCHAR(16), Max(MonitoredTime), 120) AS LastMonitored
			,COUNT(*) AS CntByServiceItem
		FROM [ADSysMon].[dbo].[TB_ProblemManagement]
		WHERE Company = @COMPANYCODE
			AND ADService = @ADSERVICE
			AND MonitoredTime > @DATETIME
			AND ManageStatus = 'NOTSTARTED'
		GROUP BY Company
			,ADService
			,Serviceitem

		FETCH NEXT
		FROM ADM_CURSOR_COM
		INTO @COMPANYCODE
	END

	CLOSE ADM_CURSOR_COM

	DEALLOCATE ADM_CURSOR_COM

	SELECT TMP.ADService
		,SUB.CODE_NAME AS ADServiceName
		,IIF(TMP.CHK_CNT IS NULL, 0, TMP.CHK_CNT) AS ErrorCount
		,CONVERT(CHAR(20), TMP.MonitoredTime, 120) AS MonitoredTime
	FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS SUB
	INNER JOIN (
		SELECT ADSERVICE
			,Serviceitem
			,MAX(MonitoredTime) AS MonitoredTime
			,SUM(CHK_CNT) AS CHK_CNT
		FROM #TMP_TB_BYSERVICE_STATUS
		GROUP BY ADSERVICE
			,Serviceitem
		) AS TMP ON SUB.SUB_CODE = TMP.Serviceitem
	WHERE CLASS_CODE = '0003'
	ORDER BY SORT_SEQ

	DROP TABLE #TMP_TB_BYSERVICE_STATUS
END
GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_SERVICE_STATUS_2]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.07.30
-- Description:	Dashboard 서비스별 Error Count Return
-- EXEC [dbo].[USP_SELECT_SERVICE_STATUS_2] 'admin'
-- =============================================
CREATE PROCEDURE [dbo].[USP_SELECT_SERVICE_STATUS_2]
	-- Add the parameters for the stored procedure here
	@USERID NVARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT T1.[ADService]
		,T1.[Serviceitem]
		,COUNT(*) AS [ErrorCount]
		,CONVERT(VARCHAR(16), MAX(T1.[MonitoredTime]), 120) AS [MonitoredTime]
	INTO #TMP_Problem_Management
	--FROM [ADSysMon].[dbo].[TB_ProblemManagement] T1
	--FROM [ADSysMon].[dbo].[View_ProblemManagement] T1 WITH(NOLOCK)
	FROM [ADSysMon].[dbo].[UFN_ProblemManagement]() T1
	INNER JOIN [dbo].[UFN_Manage_Company_User](@USERID) T2 ON T1.[Company] = T2.[Company]
	INNER JOIN [dbo].[UFN_MonitoringTaskLogs]() T3 ON T1.[Company] = T3.[Company] AND T1.[ADService] = T3.[ADService]
	WHERE T1.[MonitoredTime] > T3.[LastDate]
		--AND T1.[ManageStatus] = 'NOTSTARTED'
		--AND T1.[ADService] IN ('ADDS', 'ADCS', 'DNS', 'DHCP') -- mwjin7@dotnetsoft.co.kr 2018.08.01 기존 SP 에 4 항목만 체크하고 있음...
	GROUP BY T1.[ADService], T1.[Serviceitem]

	SELECT T2.[ADService]
		,T1.[CODE_NAME] AS [ADServiceName]
		,ISNULL(T2.[ErrorCount], 0) AS [ErrorCount]
		,T2.[MonitoredTime]
	FROM [ADSysMon].[dbo].[TB_COMMON_CODE_SUB] AS T1 WITH(NOLOCK)
	INNER JOIN #TMP_Problem_Management AS T2 ON T1.[SUB_CODE] = T2.[Serviceitem]
	WHERE T1.[CLASS_CODE] = '0003'
	ORDER BY T1.[SORT_SEQ]

	DROP TABLE #TMP_Problem_Management
END
GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_SYSVOL_SHARES_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.11
-- 수정일 : 2014.12.11  
-- 설   명 : AD DS Sysvol Shares List
-- 실   행 : EXEC [dbo].[USP_SELECT_SYSVOL_SHARES_LIST] 'LGE','ADDS'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_SYSVOL_SHARES_LIST] 
	@COMPANYCODE NVARCHAR(10)  
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_' + @ADSERVICE + 'SysvolShares';

 
	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

 
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLENAME + ']'
 
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..
 
	SET @PARAM = N' @MonitorTime nvarchar(25)'

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME
 
END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_TEST_ON_DEMAND_DATA]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 /*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHR
-- 작성일 : 2014.12.12  
-- 수정일 : 2014.12.12  
-- 설  명 : Test On-Demand PS1 실행 후 완료 업데이트
-- 실  행 :  USP_UPDATE_TEST_ON_DEMAND_COMPLETED @IDX=2, @TOD_Result='Y', @TOD_ResultScript='test<br/>test completed'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  

CREATE PROCEDURE  [dbo].[USP_SELECT_TEST_ON_DEMAND_DATA] 
	@IDX	int	 
AS
BEGIN

	SET NOCOUNT ON;
	 
	 
	SELECT 
		IDX,
		DemandDate, 
		Company, 
		TOD_Code, 
		S.CODE_NAME AS TOD_NAME,
		TOD_Demander, 
		TOD_Result, 
		TOD_ResultScript, 
		CompleteDate
	FROM	
		dbo.TB_TestOnDemand A
		LEFT OUTER JOIN TB_COMMON_CODE_SUB S ON ( A.TOD_Code = S.SUB_CODE AND S.CLASS_CODE = '0004' )
	 WHERE  IDX = @IDX
	
END


GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_TEST_ON_DEMAND_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHL
-- 작성일 : 2014.12.11
-- 수정일 : 2014.12.11  
-- 설   명 : TestOnDemand 테이블 조회
-- 실   행 : EXEC [dbo].[USP_SELECT_TEST_ON_DEMAND_LIST] 'admin'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_TEST_ON_DEMAND_LIST] 
	@USERID NVARCHAR(10)  
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT 
		IDX,
		DemandDate, 
		Company, 
		TOD_Code, 
		S.CODE_NAME AS TOD_NAME,
		TOD_Demander, 
		TOD_Result, 
		TOD_ResultScript, 
		CompleteDate
	FROM	
		dbo.TB_TestOnDemand A
		LEFT OUTER JOIN TB_COMMON_CODE_SUB S ON ( A.TOD_Code = S.SUB_CODE AND S.CLASS_CODE = '0004' )
	WHERE Company IN ( SELECT 
						   [VALUE2] 
	                    FROM TB_MANAGE_COMPANY_USER U INNER JOIN TB_COMMON_CODE_SUB B ON ( U.COMPANYCODE = B.SUB_CODE AND B.CLASS_CODE = '0001' AND U.USERID = @USERID ) 
						)
	

END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_TEST_ON_DEMAND_PROCESSING_ITEM]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 /*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHR
-- 작성일 : 2014.12.12  
-- 수정일 : 2014.12.12  
-- 설  명 :  
-- 실  행 :  EXEC [dbo].[USP_SELECT_TEST_ON_DEMAND_PROCESSING_ITEM]  
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  

CREATE PROCEDURE  [dbo].[USP_SELECT_TEST_ON_DEMAND_PROCESSING_ITEM] 
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT 
		IDX,
		DemandDate, 
		Company, 
		TOD_Code, 
		S.CODE_NAME AS TOD_NAME,
		TOD_Demander, 
		TOD_Result, 
		TOD_ResultScript, 
		CompleteDate
	FROM	
		dbo.TB_TestOnDemand A
		LEFT OUTER JOIN TB_COMMON_CODE_SUB S ON ( A.TOD_Code = S.SUB_CODE AND S.CLASS_CODE = '0004' )
	WHERE IDX = (SELECT MAX(IDX) FROM dbo.TB_TestOnDemand A )
  
END


GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_TEST_ON_DEMAND_RUN]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 /*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHR
-- 작성일 : 2014.12.12  
-- 수정일 : 2014.12.12  
-- 설  명 :  
-- 실  행 :  EXEC [dbo].[USP_SELECT_TEST_ON_DEMAND_RUN]  
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  

CREATE PROCEDURE  [dbo].[USP_SELECT_TEST_ON_DEMAND_RUN] 
AS
BEGIN

	SET NOCOUNT ON;
	
	IF ( EXISTS ( SELECT 'x' FROM dbo.TB_TestOnDemand WHERE TOD_Result = 'N' ) )
	BEGIN
		SELECT 'TRUE'
	END
	ELSE
	BEGIN
		SELECT 'FALSE'
	END

   
END


GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_TOPOLOGY_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.11
-- 수정일 : 2014.12.11  
-- 설   명 : AD DS Topology And Intersite Messaging List
-- 실   행 : EXEC [dbo].[USP_SELECT_TOPOLOGY_LIST] 'LGE','ADDS'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_TOPOLOGY_LIST] 
	@COMPANYCODE NVARCHAR(10)  
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_' + @ADSERVICE + 'Topology';

 
	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

 
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLENAME + ']'
 
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..
 
	SET @PARAM = N' @MonitorTime nvarchar(25)'

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME
 
END




GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_USER_INFO]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHL
-- 작성일 : 2014.12.09  
-- 수정일 : 2014.12.09  
-- 설   명 : 사용자 정보조회
-- 실   행 : EXEC [dbo].[USP_SELECT_USER_INFO] 'admin'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_USER_INFO] 
	@USERID NVARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT 
		USERID,
		USERNAME,
		[PASSWORD],
		MAILADDRESS,
		MOBILEPHONE,
		CREATE_DATE
	  FROM dbo.TB_USER
	 WHERE USERID = @USERID
	   AND USEYN = 'Y' 
END





GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_USER_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHL
-- 작성일 : 2014.12.09  
-- 수정일 : 2014.12.09  
-- 설   명 : 사용자 정보조회
-- 실   행 : EXEC [dbo].[USP_SELECT_USER_INFO] 'admin'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_USER_LIST]  
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT 
		USERID,
		USERNAME,
		[PASSWORD],
		MAILADDRESS,
		MOBILEPHONE,
		CREATE_DATE
	  FROM dbo.TB_USER
	 WHERE USEYN = 'Y' 
END





GO
/****** Object:  StoredProcedure [dbo].[USP_SELECT_W32TIMESYNC_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.11
-- 수정일 : 2014.12.11  
-- 설   명 : AD DS Advertisement List
-- 실   행 : EXEC [dbo].[USP_SELECT_W32TIMESYNC_LIST] 'LGE','ADDS'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_SELECT_W32TIMESYNC_LIST] 
	@COMPANYCODE NVARCHAR(10)  
	,@ADSERVICE NVARCHAR(16)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TABLENAME nvarchar(50), @CTABLE nvarchar(50)
	
	DECLARE @DATETIME DATETIME
	SET @DATETIME = [dbo].[UFN_GET_MONITOR_DATE] ( @COMPANYCODE, @ADSERVICE)
	
	SELECT 
		@CTABLE = VALUE1
	FROM
	TB_COMMON_CODE_SUB S
	WHERE CLASS_CODE = '0001'
	AND SUB_CODE = @COMPANYCODE
	SET @TABLENAME = 'TB_' + @CTABLE + '_' + @ADSERVICE + 'W32TIMESYNC';

 
	DECLARE @SQL nvarchar(max)
	DECLARE @COLUMNS_NAME nvarchar(max)
	DECLARE @PARAM nvarchar(100)

 
	SET @COLUMNS_NAME = [dbo].[UFN_GET_TABLE_COLUMNS_STR](@TABLENAME)

	SET @SQL = 'SELECT ' + @COLUMNS_NAME + ' FROM [ADSysMon].[dbo].[' + @TABLENAME + ']'
 
	--SET @SQL = @SQL + ' WHERE UTCMonitored > @MonitorTime'
	SET @SQL = @SQL + ' WHERE [UTCMonitored] > DATEADD(HOUR, -2, GETUTCDATE()) ' -- mwjin7@dotnetsoft.co.kr : TB_MonitoringTaskLogs 에 쌓이는 정보와 Row Data 간 시간차이가 발생할 수 있어, 조건 수정함..
 
	SET @PARAM = N' @MonitorTime nvarchar(25)'

	EXEC SP_EXECUTESQL @SQL, @PARAM, @MonitorTime = @DATETIME
 
END




GO
/****** Object:  StoredProcedure [dbo].[USP_Server_Availability_Trigger_Get]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.08.09
-- Description:	Server Availability Trigger 기준 Return
-- =============================================
CREATE PROCEDURE [dbo].[USP_Server_Availability_Trigger_Get]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT T1.[ADService]
		,T1.[ServiceItem]
		,T2.[CODE_NAME] AS [ServiceName]
		,T1.[TriggerCycle]
		,T1.[TriggerCount]
	FROM [dbo].[TB_SERVER_AVAILABILITY_TRIGGER] T1
	INNER JOIN [dbo].[TB_COMMON_CODE_SUB] T2 ON T1.[ServiceItem] = T2.[SUB_CODE]
END
GO
/****** Object:  StoredProcedure [dbo].[USP_Server_Availability_Trigger_Set]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mwjin7@dotnetsoft.co.kr
-- Create date: 2018.08.09
-- Description:	Alert Snooze Insert
-- =============================================
CREATE PROCEDURE [dbo].[USP_Server_Availability_Trigger_Set]
	-- Add the parameters for the stored procedure here
	@ADService NVARCHAR(10)
	, @TriggerCycle INT
	, @TriggerCount INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE [dbo].[TB_SERVER_AVAILABILITY_TRIGGER]
	SET [TriggerCycle] = @TriggerCycle, [TriggerCount] = @TriggerCount
	WHERE [ADService] = @ADService
END
GO
/****** Object:  StoredProcedure [dbo].[USP_UPDATE_CHANGE_PASSWORD]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.18
-- 수정일 : 2014.12.18  
-- 설   명 : 사용자 비밀번호 변경
-- 실   행 : EXEC [dbo].[USP_UPDATE_CHANGE_PASSWORD] 'admin','1'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_UPDATE_CHANGE_PASSWORD]
	@USERID			NVARCHAR(10),
    @NEWPASSWORD	NVARCHAR(1000)
AS 
	BEGIN 
	SET nocount ON;	

	UPDATE [dbo].[TB_USER]
	   SET [PASSWORD] = @NEWPASSWORD
	 WHERE [USERID] = @USERID
END 



 




GO
/****** Object:  StoredProcedure [dbo].[USP_UPDATE_MANAGE_COMPANY_USER]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.19  
-- 수정일 : 2014.12.19  
-- 설   명 : 회사 담당 목록 논리 삭제(수정)
-- 실   행 : EXEC [dbo].[USP_UPDATE_MANAGE_COMPANY_USER] 'admin', 'HIP^LGCNSC^LGE^LGD','system', 'N'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_UPDATE_MANAGE_COMPANY_USER] 
	@USERID			NVARCHAR(10) ,
	@COMPANYCODE	NVARCHAR(MAX),
	@CREATEID		NVARCHAR(10),
	@USEYN			CHAR(1)
AS
BEGIN
	SET NOCOUNT ON;	

	UPDATE [dbo].[TB_MANAGE_COMPANY_USER]
	   SET USEYN = @USEYN,
		   CREATE_ID = @CREATEID,
		   CREATE_DATE = GETUTCDATE()
	 WHERE USERID COLLATE SQL_Latin1_General_CP1_CI_AS = @USERID
	   AND COMPANYCODE COLLATE SQL_Latin1_General_CP1_CI_AS IN (SELECT * FROM [dbo].[UFN_GET_SPLIT_BigSize] (@COMPANYCODE,'^')) 
END


GO
/****** Object:  StoredProcedure [dbo].[USP_UPDATE_PROBLEM_MANAGEMENT_LIST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.12
-- 수정일 : 2014.12.16  
-- 설   명 : ProblemManagement 테이블 처리 사항 등록
-- 실   행 : EXEC [dbo].[USP_UPDATE_PROBLEM_MANAGEMENT_LIST] '11887^11886^11885','ONGOING','system','abc','11887'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_UPDATE_PROBLEM_MANAGEMENT_LIST] 
    @ARRIDX		NVARCHAR(MAX)
   ,@SCODE		NVARCHAR(20)
   ,@MANAGER	NVARCHAR(50)
   ,@SCRIPT		NVARCHAR(MAX)
   ,@MANAGEIDX	INT
AS 
	BEGIN 
	--SET nocount ON;
	
	UPDATE	 [dbo].[TB_ProblemManagement]
	   SET	 [ManageStatus] = @SCODE
			,[Manager] = @MANAGER
			,[ManageScript] = @SCRIPT
			,[ManageDate] = GETUTCDATE()
			,[ManageIDX] = @MANAGEIDX
	 WHERE   [IDX] IN (SELECT * FROM [dbo].[UFN_GET_SPLIT_BigSize] (@ARRIDX, '^'))
END 



 




GO
/****** Object:  StoredProcedure [dbo].[USP_UPDATE_PROBLEM_MANAGEMENT_LIST_TEST]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 KTW
-- 작성일 : 2014.12.12
-- 수정일 : 2014.12.16  
-- 설   명 : ProblemManagement 테이블 처리 사항 등록
-- 실   행 : EXEC [dbo].[USP_UPDATE_PROBLEM_MANAGEMENT_LIST] '11887^11886^11885','ONGOING','system','abc','11887'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[USP_UPDATE_PROBLEM_MANAGEMENT_LIST_TEST] 
    @ARRIDX		NVARCHAR(MAX)
   ,@SCODE		NVARCHAR(20)
   ,@MANAGER	NVARCHAR(50)
   ,@SCRIPT		NVARCHAR(MAX)
   ,@MANAGEIDX	INT
AS 
	BEGIN 
	SET nocount ON;
	
	UPDATE	 [dbo].[TB_ProblemManagement]
	   SET	 [ManageStatus] = @SCODE
			,[Manager] = @MANAGER
			,[ManageScript] = @SCRIPT
			,[ManageDate] = GETUTCDATE()
			,[ManageIDX] = @MANAGEIDX
	 WHERE   [IDX] IN (SELECT * FROM [dbo].[UFN_GET_SPLIT_BigSize] (@ARRIDX, '^'))
END 



 




GO
/****** Object:  StoredProcedure [dbo].[USP_UPDATE_TEST_ON_DEMAND_COMPLETED]    Script Date: 8/20/2018 1:25:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 /*------------------------------------------------------------------------------------  
-- 작성자 : 닷넷소프트 PHR
-- 작성일 : 2014.12.12  
-- 수정일 : 2014.12.12  
-- 설  명 : Test On-Demand PS1 실행 후 완료 업데이트
-- 실  행 :  USP_UPDATE_TEST_ON_DEMAND_COMPLETED @IDX=2, @TOD_Result='Y', @TOD_ResultScript='test<br/>test completed'
-------------------------------------------------------------------------------------  
-- 수   정   일 :   
-- 수   정   자 :   
-- 수 정  내 용 :   
------------------------------------------------------------------------------------*/  

CREATE PROCEDURE  [dbo].[USP_UPDATE_TEST_ON_DEMAND_COMPLETED] 
	@IDX	int							-- IDX 
	,@TOD_Result		nvarchar(1)		-- 처리 완료 ( 'Y')
	,@TOD_ResultScript	nvarchar(MAX)	-- 테스트 결과
AS
BEGIN

	SET NOCOUNT ON;
	
	 
	 UPDATE [dbo].[TB_TestOnDemand]
	    SET   
			TOD_Result = @TOD_Result, 
			TOD_ResultScript = @TOD_ResultScript, 
			CompleteDate = GETUTCDATE()
	 WHERE  IDX = @IDX
	
END


GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'INFO    : 알림 로그
ERROR : 시스템 오류' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TB_SYSTEM_LOG', @level2type=N'COLUMN',@level2name=N'TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[9] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "TB_SERVERS"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 213
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 2115
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ServersTable'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ServersTable'
GO
