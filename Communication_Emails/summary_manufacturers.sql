DECLARE   @scld_current_date  AS INT = '20240601'     -- this is the CURRENT date used in landscape
        , @scld_previous_date date = '20240401'  -- this is the PREVIOUS date used in landscape the previous month.. 
		, @Advantage_previous_date date = '2024-04-09' -- this is the PREVIOUS date from ADV.DataFiles
		 ,@valid_contract_date date = '06/01/2024'

		;


with  VPP_current_manufacturers  as (
										  SELECT standardizedManufacturerName
												,COUNT(*) CNT
										  FROM [PPL].[ADV].[Advantage_XSB_Analyzed_Current]
										  where REPLACE(contractNumber,'-','') in (
																		SELECT  
																			REPLACE(contractNumber,'-','') contractNumber 							
																	FROM [PPL].[SCLD].[Landscape_Results] 
																	where timeframe =  @scld_current_date
																	and VPP_Count > 0 
																					)
										  and isauthorizedVendor = 0 
										  GROUP BY
										  standardizedManufacturerName
								),
		VPP_previous_manufacturers as (
											SELECT  
												standardizedManufacturerName
												,COUNT(*) CNT
											FROM [ADV].[Advantage_XSB_Analyzed_Archive]
											where DataFilekey in (SELECT Datafilekey FROM [ADV].[DataFiles] where ReportingDate = @Advantage_previous_date) 
											and isauthorizedVendor = 0 
											and REPLACE(contractNumber,'-','') in (
 																	SELECT  
																		REPLACE(contractNumber,'-','') contractNumber 							
																FROM [PPL].[SCLD].[Landscape_Results] 
																where timeframe =  @scld_previous_date 
																and VPP_Count > 0 
										)
							GROUP BY  standardizedManufacturerName


									),
	merge_manufacturers as (
									SELECT standardizedManufacturerName FROM VPP_current_manufacturers UNION SELECT standardizedManufacturerName FROM VPP_previous_manufacturers
		),
	query4 as (
							SELECT 
								t3.standardizedManufacturerName
								,t2.cnt as previous
								,t1.cnt as current_
								,(ISNULL(t1.cnt ,0) - ISNULL(t2.cnt,0) ) 'Difference' 
								,ROW_NUMBER() OVER( PARTITION BY t3.standardizedManufacturerName ORDER BY t3.standardizedManufacturerName) as 'row_num'
							FROM merge_manufacturers t3
							LEFT JOIN VPP_current_manufacturers   t1
							ON t1.standardizedManufacturerName = t3.standardizedManufacturerName
								LEFT JOIN VPP_previous_manufacturers  t2
							ON t2.standardizedManufacturerName = t3.standardizedManufacturerName
				), 
	catalog_count AS ( -- here we only count contracts that are still valid
							SELECT standardizedManufacturerName, count(*) catalog_cnt
							FROM [PPL].[ADV].[Advantage_XSB_Analyzed_Current]
							where REPLACE(contractNumber, '-','') in	(
												Select replace([GSAM CONT NO],'-','')
												from [AOD_ProjDB].[dbo].[FSS_CMF_M]
												where cast([CONT END DT] AS date) >= @valid_contract_date
												GROUP BY replace([GSAM CONT NO],'-','')
											)
GROUP BY standardizedManufacturerName

	)
							select 
								t1.standardizedManufacturerName
								,t1.previous, t1.current_
								,t1.Difference as VPP_Difference
								,t2.catalog_cnt
							FROM query4 t1
							LEFT JOIN catalog_count t2
							ON t1.standardizedManufacturerName = t2.standardizedManufacturerName
							where row_num = 1
							ORDER BY Difference DESC
;


with  ETS_current_manufacturers  as (
										  SELECT standardizedManufacturerName
												,COUNT(*) CNT
										  FROM [PPL].[ADV].[Advantage_XSB_Analyzed_Current]
										  where REPLACE(contractNumber,'-','') in (
																		SELECT  
																			REPLACE(contractNumber,'-','') contractNumber 							
																	FROM [PPL].[SCLD].[Landscape_Results] 
																	where timeframe =  @scld_current_date
																	and ETS_Count > 0 
																					)
										  and ETS_Discrepancy =1 
										  GROUP BY
										  standardizedManufacturerName
								),
		ETS_previous_manufacturers as (
											SELECT  
												standardizedManufacturerName
												,COUNT(*) CNT
											FROM [ADV].[Advantage_XSB_Analyzed_Archive]
											where DataFilekey in (SELECT Datafilekey FROM [ADV].[DataFiles] where ReportingDate = @Advantage_previous_date) 
											and ETS_Discrepancy =1  
											and REPLACE(contractNumber,'-','') in (
 																	SELECT  
																		REPLACE(contractNumber,'-','') contractNumber 							
																FROM [PPL].[SCLD].[Landscape_Results] 
																where timeframe = @scld_previous_date 
																and ETS_Count > 0 
										)
							GROUP BY  standardizedManufacturerName


									),
	merge_manufacturers as (
									SELECT standardizedManufacturerName FROM ETS_current_manufacturers UNION SELECT standardizedManufacturerName FROM ETS_previous_manufacturers
		),
	query4 as (
							SELECT 
								t3.standardizedManufacturerName
								,t2.cnt as previous
								,t1.cnt as current_
								,(ISNULL(t1.cnt ,0) - ISNULL(t2.cnt,0) ) 'Difference' 
								,ROW_NUMBER() OVER( PARTITION BY t3.standardizedManufacturerName ORDER BY t3.standardizedManufacturerName) as 'row_num'
							FROM merge_manufacturers t3
							LEFT JOIN ETS_current_manufacturers   t1
							ON t1.standardizedManufacturerName = t3.standardizedManufacturerName
								LEFT JOIN ETS_previous_manufacturers  t2
							ON t2.standardizedManufacturerName = t3.standardizedManufacturerName
				),
	catalog_count AS ( -- here we only count contracts that are still valid
							SELECT standardizedManufacturerName, count(*) catalog_cnt
							FROM [PPL].[ADV].[Advantage_XSB_Analyzed_Current]
							where REPLACE(contractNumber, '-','') in	(
												Select replace([GSAM CONT NO],'-','')
												from [AOD_ProjDB].[dbo].[FSS_CMF_M]
												where cast([CONT END DT] AS date) >= @valid_contract_date
												GROUP BY replace([GSAM CONT NO],'-','')
	) GROUP BY standardizedManufacturerName
	)
							select 
								t1.standardizedManufacturerName
								,t1.previous, t1.current_
								,t1.Difference as ETS_Difference
								,t2.catalog_cnt
							FROM query4 t1
							LEFT JOIN catalog_count t2
							ON t1.standardizedManufacturerName = t2.standardizedManufacturerName
							where row_num = 1
							ORDER BY Difference DESC
;


with  MIA_current_manufacturers  as (
										  SELECT standardizedManufacturerName
												,COUNT(*) CNT
										  FROM [PPL].[ADV].[Advantage_XSB_Analyzed_Current]
										  where REPLACE(contractNumber,'-','') in (
																		SELECT  
																			REPLACE(contractNumber,'-','') contractNumber 							
																	FROM [PPL].[SCLD].[Landscape_Results] 
																	where timeframe =  @scld_current_date
																	and MIA_Discrepancy_Count > 0 
																					)
										  and MIA_Discrepancy =1 
										  GROUP BY
										  standardizedManufacturerName
								),
		MIA_previous_manufacturers as (
											SELECT  
												standardizedManufacturerName
												,COUNT(*) CNT
											FROM [ADV].[Advantage_XSB_Analyzed_Archive]
											where DataFilekey in (SELECT Datafilekey FROM [ADV].[DataFiles] where ReportingDate = @Advantage_previous_date) 
											and MIA_Discrepancy =1  
											and REPLACE(contractNumber,'-','') in (
 																	SELECT  
																		REPLACE(contractNumber,'-','') contractNumber 							
																FROM [PPL].[SCLD].[Landscape_Results] 
																where timeframe =  @scld_previous_date 
																and MIA_Discrepancy_Count > 0 
										)
							GROUP BY  standardizedManufacturerName


									),
	merge_manufacturers as (
									SELECT standardizedManufacturerName FROM MIA_current_manufacturers UNION SELECT standardizedManufacturerName FROM MIA_previous_manufacturers
		),
	query4 as (
							SELECT 
								t3.standardizedManufacturerName
								,t2.cnt as previous
								,t1.cnt as current_
								,(ISNULL(t1.cnt ,0) - ISNULL(t2.cnt,0) ) 'Difference' 
								,ROW_NUMBER() OVER( PARTITION BY t3.standardizedManufacturerName ORDER BY t3.standardizedManufacturerName) as 'row_num'
							FROM merge_manufacturers t3
							LEFT JOIN MIA_current_manufacturers   t1
							ON t1.standardizedManufacturerName = t3.standardizedManufacturerName
								LEFT JOIN MIA_previous_manufacturers  t2
							ON t2.standardizedManufacturerName = t3.standardizedManufacturerName
				),
	catalog_count AS ( -- here we only count contracts that are still valid
							SELECT standardizedManufacturerName, count(*) catalog_cnt
							FROM [PPL].[ADV].[Advantage_XSB_Analyzed_Current]
							where REPLACE(contractNumber, '-','') in	(
												Select replace([GSAM CONT NO],'-','')
												from [AOD_ProjDB].[dbo].[FSS_CMF_M]
												where cast([CONT END DT] AS date) >= @valid_contract_date
												GROUP BY replace([GSAM CONT NO],'-','')
	) GROUP BY standardizedManufacturerName
	)
							select 
								t1.standardizedManufacturerName
								,t1.previous, t1.current_
								,t1.Difference as MIA_Difference
								,t2.catalog_cnt
							FROM query4 t1
							LEFT JOIN catalog_count t2
							ON t1.standardizedManufacturerName = t2.standardizedManufacturerName
							where row_num = 1
							ORDER BY Difference DESC

;
with  TAA_current_manufacturers  as (
										  SELECT standardizedManufacturerName
												,COUNT(*) CNT
										  FROM [PPL].[ADV].[Advantage_XSB_Analyzed_Current]
										  where REPLACE(contractNumber,'-','') in (
																		SELECT  
																			REPLACE(contractNumber,'-','') contractNumber 							
																	FROM [PPL].[SCLD].[Landscape_Results] 
																	where timeframe =  @scld_current_date
																	and NON_TAA_Count > 0 
																					)
										  and prohibitionReason LIKE '%52.225-5%'
										  GROUP BY
										  standardizedManufacturerName
								),
		TAA_previous_manufacturers as (
											SELECT  
												standardizedManufacturerName
												,COUNT(*) CNT
											FROM [ADV].[Advantage_XSB_Analyzed_Archive]
											where DataFilekey in (SELECT Datafilekey FROM [ADV].[DataFiles] where ReportingDate = @Advantage_previous_date) 
											and prohibitionReason LIKE '%Non-TAA%' 
											and REPLACE(contractNumber,'-','') in (
 																	SELECT  
																		REPLACE(contractNumber,'-','') contractNumber 							
																FROM [PPL].[SCLD].[Landscape_Results] 
																where timeframe =  @scld_previous_date 
																and  NON_TAA_Count > 0 -- needs to be changed like above next cycle
										)
							GROUP BY  standardizedManufacturerName


									),
	merge_manufacturers as (
									SELECT standardizedManufacturerName FROM TAA_current_manufacturers UNION SELECT standardizedManufacturerName FROM TAA_previous_manufacturers
		),
	query4 as (
							SELECT 
								t3.standardizedManufacturerName
								,t2.cnt as previous
								,t1.cnt as current_
								,(ISNULL(t1.cnt ,0) - ISNULL(t2.cnt,0) ) 'Difference' 
								,ROW_NUMBER() OVER( PARTITION BY t3.standardizedManufacturerName ORDER BY t3.standardizedManufacturerName) as 'row_num'
							FROM merge_manufacturers t3
							LEFT JOIN TAA_current_manufacturers   t1
							ON t1.standardizedManufacturerName = t3.standardizedManufacturerName
								LEFT JOIN TAA_previous_manufacturers  t2
							ON t2.standardizedManufacturerName = t3.standardizedManufacturerName
				),
	catalog_count AS ( -- here we only count contracts that are still valid
							SELECT standardizedManufacturerName, count(*) catalog_cnt
							FROM [PPL].[ADV].[Advantage_XSB_Analyzed_Current]
							where REPLACE(contractNumber, '-','') in	(
												Select replace([GSAM CONT NO],'-','')
												from [AOD_ProjDB].[dbo].[FSS_CMF_M]
												where cast([CONT END DT] AS date) >= @valid_contract_date
												GROUP BY replace([GSAM CONT NO],'-','')
	) GROUP BY standardizedManufacturerName
	)
							select 
								t1.standardizedManufacturerName
								,t1.previous, t1.current_
								,t1.Difference as TAA_Difference
								,t2.catalog_cnt
							FROM query4 t1
							LEFT JOIN catalog_count t2
							ON t1.standardizedManufacturerName = t2.standardizedManufacturerName
							where row_num = 1
							ORDER BY Difference DESC