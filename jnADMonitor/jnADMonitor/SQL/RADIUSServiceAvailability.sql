/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [ComputerName]
      ,[OperatingSystem]
      ,[OperatingSystemServicePack]
      ,[RADIUSstatus]
      ,[UTCMonitored]
      ,[IsError]
      ,[ManageStatus]
      ,[Manager]
      ,[ManageScript]
      ,[ManageDate]
  FROM [ADSysMon].[dbo].[TB_dotnetsoft_co_kr_RADIUSServiceAvailability]