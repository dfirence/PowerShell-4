/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [ComputerName]
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
      ,[ManageStatus]
      ,[Manager]
      ,[ManageScript]
      ,[ManageDate]
  FROM [ADSysMon].[dbo].[TB_dotnetsoft_co_kr_ADDSRepository]