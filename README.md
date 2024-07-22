# Background

This dashboard provides an overarching view of the Multiple Award Schedule (MAS) program in terms of overall market competitiveness at the schedule and contract levels. While the Price Point Plus Portal (4P) addresses these risks on a pre-award basis, there has historically been limited insight into the products that are currently on Advantage. This dashboard is meant to be a resource to assist stakeholders in the remediation of existing supply chain risks as it pertains to:

MiA (Made in America)
ETS (Essentially the Same)
TAA (Trade Agreements Act)
VPP (Potential Unauthorized Items)
Pricing. The metrics pulled can be represented in the following flow chart:

 ![image](https://github.helix.gsa.gov/AEAD/Industrial_Supplier_Compliance_Dashboard/blob/master/images/editting_stored_procedure.JPG.jpg)
 
 [Supplier's Compliance Dashboard Methodology, Metadata, and Source Tables](https://docs.google.com/document/d/1qkxMVAiIIXm9je3m9Rnvw4R5orVLQkVe5oIaIi8cCr4/edit) document provides details into the soruce data driving the table that is being generated. 

# Execution

A stored procedure in the PPL schema that pocesses the XSB table ([ADV].[Advantage_XSB_Analyzed_Crrent]) the generates the necessary output file with a file name following this format: [SCLD].[Landscape_Dashboard_YYYY_MM] where YYYY = year and MM = two digit month. For every XSB table release and post processing from CMO (Dan Skilton daniel.skelton@gsa.gov) the user needs to edit the stored program and make changes to row number 770 and update the [SCLD].[Landscape_Dashboard_YYYY_MM] to the appropriate date as such: 

 ![image](https://github.helix.gsa.gov/AEAD/Industrial_Supplier_Compliance_Dashboard/blob/master/images/editting_stored_procedure.JPG)
 
 Once that's updated click on the "Execute" to save changes. To execute the file right click on the 'dbo.LANDSCAPE_SP' file and click on 'Execute Stored Procedure...'. After executing the procedure without errors a new file will be created in the database. After refreshing the table (right click on Databases and click on 'Refresh'). Once complete the following view must also be manually updated:
 
 `SCLD.Landscape_Results`
 
Copy and paste the same SQL syntax below the code and update th edate in three places as highlighted in image below:

  ![image](https://github.helix.gsa.gov/AEAD/Industrial_Supplier_Compliance_Dashboard/blob/master/images/editting_scld_file.JPG)
 
 Once the changes are manually complete click on the 'Execute' button above. 
 
 
 # Dashboard
 
 Once the necessary files are generated on the SQL server follow these steps to update the dashboard:

 1. Refresh the data from the dashboard (Data Source --> Data --> Refresh Data Source)
 2. Right click on "Time Period" on the left side pane, when opening any worksheet, and select "Edit".
 
  ![image](https://github.helix.gsa.gov/AEAD/Industrial_Supplier_Compliance_Dashboard/blob/master/images/editting_stored_procedure.JPG.jpg)
  
  3. Add an additional line with the date of the latest data release. For example, if the latest data update is June 2024 we'll add: WHEN '20240601 THEN '06/2024' 
  
    ![image](https://github.helix.gsa.gov/AEAD/Industrial_Supplier_Compliance_Dashboard/blob/master/images/TimePeriod_update.JPG)
	
4. Right click on "MY(Time Period):MMYYYY" from the filters and select "Edit Filter" as such: 

     ![image](https://github.helix.gsa.gov/AEAD/Industrial_Supplier_Compliance_Dashboard/blob/master/images/step4_edit_MyTimePeriod.jpg)

5. Select the latest date: 	 
	 

     ![image](https://github.helix.gsa.gov/AEAD/Industrial_Supplier_Compliance_Dashboard/blob/master/images/filter_latestDate.jpg)

6. On the worksheet showing timeline make sure to open the "Month" filter and click on latest date to include
	 
	  ![image](https://github.helix.gsa.gov/AEAD/Industrial_Supplier_Compliance_Dashboard/blob/master/images/update_trend_dates.jpg) 
	
	 
   ka view was created in SQL Server to pull in all the necessary data and generate a master table with the data. The view can be found here and is stored in the Microsoft SQL Server as: 

`[PPL].[Vendor_profile].[SZG_Vendor_Base_Dashboard_Data]`
SQL Server Agent is used to automatically run the above view the second week of every month (8th day of the month). A job is currently set up under the name "Monthly_Vendor_Base_Dashboard_Data_tbl" with the following commands: 

```
DROP TABLE IF EXISTS [PPL].[EBVA].[Vendor_Base_Dashboard_Data_tbl]	  
SELECT * 	
INTO  [PPL].[EBVA].[Vendor_Base_Dashboard_Data_tbl]	
FROM [PPL].[Vendor_profile].[SZG_Vendor_Base_Dashboard_Data]	
```

The PPL].[Vendor_profile].[SZG_Vendor_Base_Dashboard_Data] view is executed and the results are stored in [PPL].[EBVA].[Vendor_Base_Dashboard_Data_tbl]. For each monthly table generated there is a header ("Timeframe") for each run (YYYYMM). The generated table is then appended to a second table to capture the monthly tables over time. Therefore, right after the above commands are run, the following is then run:

```
DROP TABLE IF EXISTS #tempunion_supplier_compliance
SELECT * INTO #tempunion_supplier_compliance FROM [PPL].[dbo].[Supplier_Compliance_historical]
DROP TABLE IF EXISTS [PPL].[dbo].[Supplier_Compliance_historical]
SELECT * 
INTO [PPL].[dbo].[Supplier_Compliance_historical]
FROM 
( 
	SELECT * FROM [PPL].[EBVA].[Vendor_Base_Dashboard_Data_tbl]
	UNION all
	SELECT * FROM #tempunion_supplier_compliance
) a
;
```

The [PPL].[dbo].[Supplier_Compliance_historical] tables stores all the monthly generated data into a single file. This table is used for the dashboard to track results over time. 

This is how the SQL Server Agent job looks like: 

 ![image](https://github.helix.gsa.gov/AEAD/Industrial_Supplier_Compliance_Dashboard/blob/master/images/SQLAgent.JPG)

# POCs:
```
Shadi Ghrayeb
347-224-0501
shadi.ghrayeb@gsa.gov
```

# Dashboard

[Suppliers' Compliance Scorecard](https://d2d.gsa.gov/report/suppliers%E2%80%99-compliance-scorecard)

