DECLARE   @scld_current_date  AS INT = '20240601'     -- this is the CURRENT date used in landscape
        , @scld_previous_date date = '20240401'  -- this is the PREVIOUS date used in landscape the previous month.. 
		, @Advantage_previous_date date = '2024-04-09' -- this is the PREVIOUS date from ADV.DataFiles
		, @valid_contract_date date = '06/01/2024'

;

SELECT 
(SELECT SUM(catalog_count) FROM [PPL].[SCLD].[Landscape_Results] where Timeframe = @scld_previous_date) as 'previous_items'
,(SELECT SUM(catalog_count) FROM [PPL].[SCLD].[Landscape_Results] where Timeframe = @scld_current_date) as 'current_items'
,FORMAT(((SELECT SUM(catalog_count) FROM [PPL].[SCLD].[Landscape_Results] where Timeframe = @scld_current_date)) * 1.  / ((SELECT SUM(catalog_count) FROM [PPL].[SCLD].[Landscape_Results] where Timeframe = @scld_previous_date) ) -1.,'P')   as Pct_difference


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
	
								select  DISTINCT t1.contractNumber, t2.vendorName, t1.items_previous, t1.items_current, t1.diff as "Items Added"
								FROM largest_delta t1
								LEFT JOIN [ADV].[Advantage_XSB_Analyzed_Current] t2
								ON t1.contractNumber = t2.contractNumber
--								ORDER BY t1.diff DESC 
						)
			SELECT TOP(20) *, ROW_NUMBER() OVER( PARTITION BY contractNumber ORDER BY vendorName) as 'row_num [tot_new_items_added]'
			FROM get_Vendor_name
--			where row_num = 1
			order by "Items Added" DESC
				; 
/*

Here we look at VPP, MIA, TAA, ETS data grouped by contractnumber, vendorname, dunsnumber (UEI)

*/
		


-- pullin gin current VPPs
WITH current_VPPs AS   (
							SELECT  
								REPLACE(contractNumber,'-','') contractNumber 
								,vendorname
								,VPP_Count as CNT
								,DUNS as dunsnumber
							FROM [PPL].[SCLD].[Landscape_Results] 
							where timeframe = @scld_current_date
							and VPP_Count > 0 
							GROUP by REPLACE(contractNumber,'-','') , VPP_Count, DUNS, vendorname
						),
-- pulling in the VPP data from last cycle from SCLD table
previous_VPPs as		(

							SELECT  
								REPLACE(contractNumber,'-','') contractNumber 
								,vendorname
								,VPP_Count as CNT
								,DUNS as dunsnumber
							FROM [PPL].[SCLD].[Landscape_Results] 
							where timeframe = @scld_previous_date
							and VPP_Count > 0 
							GROUP by REPLACE(contractNumber,'-','') , VPP_Count, DUNS, vendorname
						),
-- merging the contract numbers from the current VPP table and the previous cycle
merge_CNs as			(
							select 
								contractnumber
								,vendorname
								,dunsnumber 
							from current_VPPs 
							UNION 
							select  
							contractnumber
							,vendorname
							,dunsnumber from previous_VPPs
	),
-- calculating the difference in VPP counts from current XSB release compared to previous release
	query4 as (
							SELECT 
								t3.contractnumber
								,t3.vendorname
								,t3.dunsnumber
								,t2.cnt as previous
								,t1.cnt as current_
								,(ISNULL(t1.cnt ,0) - ISNULL(t2.cnt,0) ) 'Difference' 
								,ROW_NUMBER() OVER( PARTITION BY t3.contractNumber ORDER BY t3.vendorName) as 'row_num'
							FROM merge_CNs t3
							LEFT JOIN current_VPPs t1
							ON t1.contractNumber = t3.contractNumber
								LEFT JOIN previous_VPPs t2
							ON t2.contractNumber = t3.contractNumber
				)
							select 
								contractnumber
								,vendorname
								,dunsnumber
								,previous, current_
								,Difference as VPP_Difference
							FROM query4 
							where row_num = 1
							ORDER BY Difference DESC
;



-- pullin gin current MIAs
WITH current_MIAs AS   (
							SELECT  
								REPLACE(contractNumber,'-','') contractNumber 
								,vendorname
								,[MIA_Discrepancy_Count] as CNT
								,DUNS as dunsnumber
							FROM [PPL].[SCLD].[Landscape_Results] 
							where timeframe = @scld_current_date
							and [MIA_Discrepancy_Count] > 0 
							GROUP by REPLACE(contractNumber,'-','') , [MIA_Discrepancy_Count], DUNS, vendorname
						),
-- pulling in the VPP data from last cycle from SCLD table
previous_MIAs as		(

							SELECT  
								REPLACE(contractNumber,'-','') contractNumber 
								,vendorname
								,[MIA_Discrepancy_Count] as CNT
								,DUNS as dunsnumber
							FROM [PPL].[SCLD].[Landscape_Results] 
							where timeframe = @scld_previous_date
							and [MIA_Discrepancy_Count] > 0 
							GROUP by REPLACE(contractNumber,'-','') , [MIA_Discrepancy_Count], DUNS, vendorname
						),
-- merging the contract numbers from the current VPP table and the previous cycle
merge_CNs as			(
							select 
								contractnumber
								,vendorname
								,dunsnumber 
							from current_MIAs 
							UNION 
							select  
							contractnumber
							,vendorname
							,dunsnumber from previous_MIAs
	),
-- calculating the difference in VPP counts from current XSB release compared to previous release
	query4 as (
							SELECT 
								t3.contractnumber
								,t3.vendorname
								,t3.dunsnumber
								,t2.cnt as previous
								,t1.cnt as current_
								,(ISNULL(t1.cnt ,0) - ISNULL(t2.cnt,0) ) 'Difference' 
								,ROW_NUMBER() OVER( PARTITION BY t3.contractNumber ORDER BY t3.vendorName) as 'row_num'
							FROM merge_CNs t3
							LEFT JOIN current_MIAs t1
							ON t1.contractNumber = t3.contractNumber
								LEFT JOIN previous_MIAs t2
							ON t2.contractNumber = t3.contractNumber
				)
							select 
								contractnumber
								,vendorname
								,dunsnumber
								,previous, current_
								,Difference as MIA_Difference
							FROM query4 
							where row_num = 1
							ORDER BY Difference DESC
;



WITH current_TAAs AS   (
							SELECT  
								REPLACE(contractNumber,'-','') contractNumber 
								,vendorname
								,[Non_TAA_Count] as CNT
								,DUNS as dunsnumber
							FROM [PPL].[SCLD].[Landscape_Results] 
							where timeframe = @scld_current_date
							and [Non_TAA_Count] > 0 
							GROUP by REPLACE(contractNumber,'-','') , [Non_TAA_Count], DUNS, vendorname
						),
-- pulling in the VPP data from last cycle from SCLD table
previous_TAAs as		(

							SELECT  
								REPLACE(contractNumber,'-','') contractNumber 
								,vendorname
								,[Non_TAA_Count] as CNT
								,DUNS as dunsnumber
							FROM [PPL].[SCLD].[Landscape_Results] 
							where timeframe = @scld_previous_date
							and [Non_TAA_Count] > 0 
							GROUP by REPLACE(contractNumber,'-','') , [Non_TAA_Count], DUNS, vendorname
						),
-- merging the contract numbers from the current VPP table and the previous cycle
merge_CNs as			(
							select 
								contractnumber
								,vendorname
								,dunsnumber 
							from current_TAAs 
							UNION 
							select  
							contractnumber
							,vendorname
							,dunsnumber from previous_TAAs
	),
-- calculating the difference in VPP counts from current XSB release compared to previous release
	query4 as (
							SELECT 
								t3.contractnumber
								,t3.vendorname
								,t3.dunsnumber
								,t2.cnt as previous
								,t1.cnt as current_
								,(ISNULL(t1.cnt ,0) - ISNULL(t2.cnt,0) ) 'Difference' 
								,ROW_NUMBER() OVER( PARTITION BY t3.contractNumber ORDER BY t3.vendorName) as 'row_num'
							FROM merge_CNs t3
							LEFT JOIN current_TAAs t1
							ON t1.contractNumber = t3.contractNumber
								LEFT JOIN previous_TAAs t2
							ON t2.contractNumber = t3.contractNumber
				)
							select 
								contractnumber
								,vendorname
								,dunsnumber
								,previous, current_
								,Difference as TAA_Difference
							FROM query4 
							where row_num = 1
							ORDER BY Difference DESC
;				


WITH current_ETS AS   (
							SELECT  
								REPLACE(contractNumber,'-','') contractNumber 
								,vendorname
								,[ETS_Count] as CNT
								,DUNS as dunsnumber
							FROM [PPL].[SCLD].[Landscape_Results] 
							where timeframe = @scld_current_date
							and [ETS_Count] > 0 
							GROUP by REPLACE(contractNumber,'-','') , [ETS_Count], DUNS, vendorname
						),
-- pulling in the VPP data from last cycle from SCLD table
previous_ETS as		(

							SELECT  
								REPLACE(contractNumber,'-','') contractNumber 
								,vendorname
								,[ETS_Count] as CNT
								,DUNS as dunsnumber
							FROM [PPL].[SCLD].[Landscape_Results] 
							where timeframe = @scld_previous_date
							and [ETS_Count] > 0 
							GROUP by REPLACE(contractNumber,'-','') , [ETS_Count], DUNS, vendorname
						),
-- merging the contract numbers from the current VPP table and the previous cycle
merge_CNs as			(
							select 
								contractnumber
								,vendorname
								,dunsnumber 
							from current_ETS 
							UNION 
							select  
							contractnumber
							,vendorname
							,dunsnumber from previous_ETS
	),
-- calculating the difference in VPP counts from current XSB release compared to previous release
	query4 as (
							SELECT 
								t3.contractnumber
								,t3.vendorname
								,t3.dunsnumber
								,t2.cnt as previous
								,t1.cnt as current_
								,(ISNULL(t1.cnt ,0) - ISNULL(t2.cnt,0) ) 'Difference' 
								,ROW_NUMBER() OVER( PARTITION BY t3.contractNumber ORDER BY t3.vendorName) as 'row_num'
							FROM merge_CNs t3
							LEFT JOIN current_ETS t1
							ON t1.contractNumber = t3.contractNumber
								LEFT JOIN previous_ETS t2
							ON t2.contractNumber = t3.contractNumber
				)
							select 
								contractnumber
								,vendorname
								,dunsnumber
								,previous, current_
								,Difference as ETS_Difference
							FROM query4 
							where row_num = 1
							ORDER BY Difference DESC
;				