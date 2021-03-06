/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [Domain]
      ,[ServiceFlag]
      ,[ComputerName]
      ,[IPAddress]
      ,[UTCMonitored]
  FROM [ADSysMon].[dbo].[TB_SERVERS]
--  where domain = 'dotnetsoft.co.kr' and serviceflag = 'ADCS'
  order by Domain, ServiceFlag
  
-- dotnetsoft.co.kr	RADIUS	DNPROD05	211.232.158.253	2015-01-20 07:10:16.697

/*

USE ADSysMon
go

INSERT INTO [dbo].[TB_SERVERS]
		( [Domain]
		,[ServiceFlag]
		,[ComputerName]
		,[IPAddress]
		,[UTCMonitored]
		)
		VALUES
		( 'dotnetsoft.co.kr' 
		, 'ADCS'
		, 'DNPROD01'
		, '211.232.158.244'
		, GETUTCDATE()
		)
*/

/*
USE ADSysMon
go

DELETE FROM [dbo].[TB_SERVERS]
WHERE domain = 'dotnetsoft.co.kr' and serviceflag = 'ADCS'
GO

*/
