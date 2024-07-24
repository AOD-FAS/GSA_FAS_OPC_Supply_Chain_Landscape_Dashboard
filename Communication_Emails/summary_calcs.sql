--three places to change line 2,3,12
DECLARE   @scld_current_date  AS INT = '20240601'     -- this is the CURRENT date used in landscape
        , @scld_previous_date date = '20240601'  -- this is the PREVIOUS date used in landscape the previous month.. 
		, @Advantage_previous_date date = '2024-04-09' -- this is the PREVIOUS date from ADV.DataFiles

;

SELECT  
        (SELECT COUNT(*) as 'previous' FROM [ADV].[Advantage_XSB_Analyzed_Archive] where DataFileKey in (SELECT DataFileKey FROM [ADV].[DataFiles] where ReportingDate =  @Advantage_previous_date ) ) as 'previous'
		,(SELECT COUNT(*) as 'Current'  FROM [ADV].[Advantage_XSB_Analyzed_Current]  ) as 'current'
		,((SELECT COUNT(*) as 'Current'  FROM [ADV].[Advantage_XSB_Analyzed_Current]  ) * 1. / (SELECT COUNT(*) as 'previous' FROM [ADV].[Advantage_XSB_Analyzed_Archive] where DataFileKey in (SELECT DataFileKey FROM [ADV].[DataFiles] where ReportingDate =  @Advantage_previous_date ) ) - 1) * 100. AS 'Pct_difference'

/**
Summary of Results. THe delta in MIA, TAA, ETS, UAV, between current release and last cycle

**/

SELECT		   'MIA' as metric
			  ,(SELECT SUM(MIA_Discrepancy_Count) FROM [SCLD].[Landscape_Results] where Timeframe =  @scld_previous_date  ) as previous
			  ,(SELECT SUM(MIA_Discrepancy_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date) as 'current'
			  ,(SELECT SUM(MIA_Discrepancy_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date  ) - (SELECT SUM(MIA_Discrepancy_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date ) as delta 
			  ,(((SELECT SUM(MIA_Discrepancy_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date) - (SELECT SUM(MIA_Discrepancy_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date) ) * 100. / ((SELECT SUM(MIA_Discrepancy_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date )) ) as Pct_difference
UNION ALL
SELECT 
			  'TAA' as metric 
			   ,(SELECT SUM(Non_TAA_Count) FROM [SCLD].[Landscape_Results] where Timeframe =  @scld_previous_date ) as previous
			  ,(SELECT SUM(Non_TAA_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date) as 'current'
			  ,(SELECT SUM(Non_TAA_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date  ) - (SELECT SUM(Non_TAA_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date ) as delta 
			  ,(((SELECT SUM(Non_TAA_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date) - (SELECT SUM(Non_TAA_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date) ) * 100. / ((SELECT SUM(Non_TAA_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date )) ) as Pct_difference
UNION ALL			
SELECT		  'ETS'  as metric
			  ,(SELECT SUM(ETS_Count) FROM [SCLD].[Landscape_Results] where Timeframe =  @scld_previous_date  ) as previous
			  ,(SELECT SUM(ETS_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date) as 'current'
			  ,(SELECT SUM(ETS_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date  ) - (SELECT SUM(ETS_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date ) as delta 
			  ,(((SELECT SUM(ETS_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date) - (SELECT SUM(ETS_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date) ) * 100. / ((SELECT SUM(ETS_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date )) ) as Pct_difference 
UNION ALL
SELECT
			   'UAV'  
			  ,(SELECT SUM(VPP_Count) FROM [SCLD].[Landscape_Results] where Timeframe =  @scld_previous_date  ) as previous
			  ,(SELECT SUM(VPP_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date) as 'current'
			  ,(SELECT SUM(VPP_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date  ) - (SELECT SUM(VPP_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date ) as delta 
			  ,(((SELECT SUM(VPP_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_current_date) - (SELECT SUM(VPP_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date) ) * 100. / ((SELECT SUM(VPP_Count) FROM [SCLD].[Landscape_Results] where Timeframe = @scld_previous_date )) ) as Pct_difference
			   			  
;


WITH top_MIA_current AS	 (
							SELECT  contractNumber,  MIA_Discrepancy_Count AS MIA_current
							FROM [SCLD].[Landscape_Results]
							where Timeframe = @scld_current_date
						 ),
						 
   MIA_previous AS	 (
							SELECT  contractNumber,  MIA_Discrepancy_Count AS MIA_previous
							FROM [SCLD].[Landscape_Results]
							where Timeframe = @scld_previous_date
						 ),			 
						 
largest_delta as (						 SELECT t1.contractNumber,  t2.MIA_previous, t1.MIA_current, (t1.MIA_current - t2.MIA_previous ) AS  diff, cast((t1.MIA_current  - t2.MIA_previous ) * 1. as numeric)  / NULLIF(t2.MIA_previous,0)    AS pct_diff
						 FROM top_MIA_current t1 
						 LEFT JOIN MIA_previous  t2 
						 ON t1.contractNumber = t2.contractNumber
				)
				select top(20) t1.contractNumber, t2.VendorName, t1.MIA_previous, t1.MIA_current, t1.diff, t1.pct_diff
				FROM largest_delta t1
				LEFT JOIN [SCLD].[Landscape_Results] t2
				ON t1.contractNumber = t2.contractNumber
				where t2.timeframe =  @scld_current_date
				ORDER by t1.diff DESC

				;
				

WITH MIA_pct_previous AS (SELECT contractNumber, vendorname, MIA_Discrepancy_Count *1. / (SELECT SUM(MIA_Discrepancy_Count) FROM  [SCLD].[Landscape_Results] where Timeframe =  @scld_previous_date) MIA_pct_past
FROM [SCLD].[Landscape_Results]
where Timeframe =  @scld_previous_date)


SELECT top(20)  t1.contractNumber,  t1.vendorname, t2.MIA_pct_past, t1.MIA_Discrepancy_Count *1. / (SELECT SUM(MIA_Discrepancy_Count) FROM  [SCLD].[Landscape_Results] where Timeframe =  @scld_current_date) MIA_pct_current
FROM [SCLD].[Landscape_Results] t1
LEFT JOIN MIA_Pct_previous t2
ON t1.contractNumber = t2.contractNumber 
where t1.Timeframe =  @scld_current_date
ORDER BY MIA_pct_current desc

;



				
WITH top_TAA_current AS	 (
							SELECT  contractNumber,  Non_TAA_Count AS TAA_current
							FROM [SCLD].[Landscape_Results]
							where Timeframe = @scld_current_date
						 ),
						 
   TAA_previous AS	 (
							SELECT  contractNumber,  Non_TAA_Count AS TAA_previous
							FROM [SCLD].[Landscape_Results]
							where Timeframe = @scld_previous_date
						 ),			 
						 
largest_delta as (						 SELECT t1.contractNumber,  t2.TAA_previous, t1.TAA_current, (t1.TAA_current - t2.TAA_previous ) AS  diff, cast((t1.TAA_current  - t2.TAA_previous ) * 1. as numeric)  / NULLIF(t2.TAA_previous,0)    AS pct_diff
						 FROM top_TAA_current t1 
						 LEFT JOIN TAA_previous  t2 
						 ON t1.contractNumber = t2.contractNumber
				)
				select TOP(20)  t1.contractNumber, t2.VendorName, t1.TAA_previous, t1.TAA_current, t1.diff, t1.pct_diff
				FROM largest_delta t1
				LEFT JOIN [SCLD].[Landscape_Results] t2
				ON t1.contractNumber = t2.contractNumber
				where t2.timeframe =  @scld_current_date
				ORDER by t1.diff DESC

				; 

WITH TAA_pct_previous AS (SELECT contractNumber, vendorname, Non_TAA_Count *1. / (SELECT SUM(Non_TAA_Count) FROM  [SCLD].[Landscape_Results] where Timeframe =  @scld_previous_date) TAA_pct_past
FROM [SCLD].[Landscape_Results]
where Timeframe =  @scld_previous_date)


SELECT top(20)  t1.contractNumber,  t1.vendorname, t2.TAA_pct_past, t1.Non_TAA_Count *1. / (SELECT SUM(NON_TAA_Count) FROM  [SCLD].[Landscape_Results] where Timeframe =  @scld_current_date) TAA_pct_current
FROM [SCLD].[Landscape_Results] t1
LEFT JOIN TAA_Pct_previous t2
ON t1.contractNumber = t2.contractNumber 
where t1.Timeframe =  @scld_current_date
ORDER BY TAA_pct_current desc

;




				
WITH top_ETS_current AS	 (
							SELECT  contractNumber,  ETS_Count AS ETS_current
							FROM [SCLD].[Landscape_Results]
							where Timeframe = @scld_current_date
						 ),
						 
   ETS_previous AS	 (
							SELECT  contractNumber,  ETS_Count AS ETS_previous
							FROM [SCLD].[Landscape_Results]
							where Timeframe = @scld_previous_date
						 ),			 
						 
largest_delta as (						 SELECT t1.contractNumber,  t2.ETS_previous, t1.ETS_current, (t1.ETS_current - t2.ETS_previous ) AS  diff, cast((t1.ETS_current  - t2.ETS_previous ) * 1. as numeric)  / NULLIF(t2.ETS_previous,0)    AS pct_diff
						 FROM top_ETS_current t1 
						 LEFT JOIN ETS_previous  t2 
						 ON t1.contractNumber = t2.contractNumber
				)
				select TOP(20)  t1.contractNumber, t2.VendorName, t1.ETS_previous, t1.ETS_current, t1.diff, t1.pct_diff
				FROM largest_delta t1
				LEFT JOIN [SCLD].[Landscape_Results] t2
				ON t1.contractNumber = t2.contractNumber
				where t2.timeframe =  @scld_current_date
				ORDER by t1.diff DESC

				; 

WITH ETS_pct_previous AS (SELECT contractNumber, vendorname, ETS_Count *1. / (SELECT SUM(ETS_Count) FROM  [SCLD].[Landscape_Results] where Timeframe =  @scld_previous_date) ETS_pct_past
FROM [SCLD].[Landscape_Results]
where Timeframe =  @scld_previous_date)


SELECT top(20)  t1.contractNumber,  t1.vendorname, t2.ETS_pct_past, t1.ETS_Count *1. / (SELECT SUM(ETS_Count) FROM  [SCLD].[Landscape_Results] where Timeframe =  @scld_current_date) ETS_pct_current
FROM [SCLD].[Landscape_Results] t1
LEFT JOIN ETS_Pct_previous t2
ON t1.contractNumber = t2.contractNumber 
where t1.Timeframe =  @scld_current_date
ORDER BY ETS_pct_current desc

;


WITH top_VPP_current AS	 (
							SELECT  contractNumber,  VPP_Count AS VPP_current
							FROM [SCLD].[Landscape_Results]
							where Timeframe = @scld_current_date
						 ),
						 
   VPP_previous AS	 (
							SELECT  contractNumber,  VPP_Count AS VPP_previous
							FROM [SCLD].[Landscape_Results]
							where Timeframe = @scld_previous_date
						 ),			 
						 
largest_delta as (	 SELECT t1.contractNumber,  t2.VPP_previous, t1.VPP_current, (t1.VPP_current - t2.VPP_previous ) AS  diff, cast((t1.VPP_current  - t2.VPP_previous ) * 1. as numeric)  / NULLIF(t2.VPP_previous,0)    AS pct_diff
						 FROM top_VPP_current t1 
						 LEFT JOIN VPP_previous  t2 
						 ON t1.contractNumber = t2.contractNumber
				)
				select TOP(20)   t1.contractNumber, t2.VendorName, t1.VPP_previous, t1.VPP_current, t1.diff, t1.pct_diff
				FROM largest_delta t1
				LEFT JOIN [SCLD].[Landscape_Results] t2
				ON t1.contractNumber = t2.contractNumber
				where t2.timeframe =  @scld_current_date
				ORDER by t1.diff DESC

				; 

WITH VPP_pct_previous AS (SELECT contractNumber, vendorname, VPP_Count *1. / (SELECT SUM(VPP_Count) FROM  [SCLD].[Landscape_Results] where Timeframe =  @scld_previous_date) VPP_pct_past
FROM [SCLD].[Landscape_Results]
where Timeframe =  @scld_previous_date)


SELECT top(20)  t1.contractNumber,  t1.vendorname, t2.VPP_pct_past, t1.VPP_Count *1. / (SELECT SUM(VPP_Count) FROM  [SCLD].[Landscape_Results] where Timeframe =  @scld_current_date) VPP_pct_current
FROM [SCLD].[Landscape_Results] t1
LEFT JOIN VPP_Pct_previous t2
ON t1.contractNumber = t2.contractNumber 
where t1.Timeframe =  @scld_current_date
ORDER BY VPP_pct_current desc
;

WITH top_vendors_current AS	 (
							SELECT  contractNumber,  COUNT(*) AS items_current
							FROM [ADV].[Advantage_XSB_Analyzed_Current]
							GROUP BY contractNumber
						 ),
						 
   vendors_previous AS	 (
							SELECT  contractNumber,  count(*) AS items_previous
							FROM [ADV].[Advantage_XSB_Analyzed_Archive]
							where DataFileKey in (SELECT DataFileKey FROM ADV.DataFiles where ReportingDate = @Advantage_previous_date) 
							GROUP BY contractNumber
						 ),			 
						 
largest_delta as (		 SELECT t1.contractNumber,   t2.items_previous, t1.items_current, (t1.items_current - t2.items_previous ) as diff 
						 FROM top_vendors_current t1 
						 LEFT JOIN vendors_previous  t2 
						 ON t1.contractNumber = t2.contractNumber
				),
	get_vendor_name AS (
	
								select  DISTINCT t1.contractNumber, t2.vendorName, t1.items_previous, t1.items_current, t1.diff
								FROM largest_delta t1
								LEFT JOIN [ADV].[Advantage_XSB_Analyzed_Current] t2
								ON t1.contractNumber = t2.contractNumber
--								ORDER BY t1.diff DESC 
						)
			SELECT TOP(20) *, ROW_NUMBER() OVER( PARTITION BY contractNumber ORDER BY vendorName) as 'row_num'
			FROM get_Vendor_name
--			where row_num = 1
			order by diff DESC
				; 

