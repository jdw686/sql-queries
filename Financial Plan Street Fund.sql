-- This query is the basis for an internal report made to track revenues, and expenditures by City Department, on a summary level.


SELECT DISTINCT
ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project, gl_detail.j_transact_year ORDER BY gl_master.a_object) as row1,
ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) as row2,
-- The next two lines summarize the transaction totals for current year and prior year revenues and expenditures.
-- The year and month entered are parameterized when this report was created inMicrosoft SSRS
CASE WHEN gl_detail.j_transact_year = '2019' AND gl_detail.j_transact_period <= '3' AND NOT gl_detail.j_jnl_source IN ('COE', 'COM', 'POE', 'POM', 'POL', 'COL', 'BUA', 'BUC') THEN gl_detail.j_debit_amount - gl_detail.j_credit_amount ELSE 0 END AS cy_net_amount,
CASE WHEN gl_detail.j_transact_year = ('2019' - 1) AND gl_detail.j_transact_period <= '3' AND NOT gl_detail.j_jnl_source IN ('COE', 'COM', 'POE', 'POM', 'POL', 'COL', 'BUA', 'BUC') THEN gl_detail.j_debit_amount - gl_detail.j_credit_amount ELSE 0 END AS ly_net_amount,
CASE WHEN ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) = 1 AND gl_master.gp_curr_year != gl_master.gp_deflt_year THEN gl_master.d_bud_ny_level5
	WHEN ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) = 1 AND gl_master.gp_curr_year = gl_master.gp_deflt_year THEN gl_master.d_cy_revised_bud
	ELSE 0 END AS cy_budget3,
CASE WHEN ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) = 1 AND gl_master.gp_curr_year != gl_master.gp_deflt_year THEN gl_master.d_cy_revised_bud
	WHEN ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) = 1 AND gl_master.gp_curr_year = gl_master.gp_deflt_year THEN gl_master.d_ly1_rev_bud
	ELSE 0 END AS ly_budget2,
gl_master.a_account_type,
gl_master.a_fund_seg1,
gl_master.a_org,
gl_master.a_object,
gl_master.a_charcode,
gl_detail.j_transact_year,
gl_master.gp_deflt_year,
monthly_report_orgs = CASE WHEN gl_master.a_object BETWEEN '311100' AND '311104' AND gl_master.a_account_type = 'R' THEN 31.1
	WHEN gl_master.a_object BETWEEN '313110' AND '313710' AND gl_master.a_account_type = 'R' THEN 31.2
	WHEN gl_master.a_object = '316100' AND gl_master.a_account_type = 'R' THEN 31.61
	WHEN gl_master.a_object BETWEEN '316401' AND '316470' AND gl_master.a_account_type = 'R' THEN 31.64
	WHEN gl_master.a_object BETWEEN '316800' AND '316840' AND gl_master.a_account_type = 'R' THEN 31.68
	WHEN gl_master.a_object BETWEEN '317200' AND '318120' AND gl_master.a_account_type = 'R' THEN 31.9
	WHEN gl_master.a_object BETWEEN '318340' AND '318350' AND gl_master.a_account_type = 'R' THEN 31.8
	WHEN gl_master.a_charcode = '32' THEN 32
	WHEN gl_master.a_charcode = '33' THEN 33
	WHEN gl_master.a_charcode = '34' THEN 34
	WHEN gl_master.a_charcode BETWEEN '35' and '39' AND gl_master.a_object != '397000' THEN 36
	WHEN gl_master.a_object = '397000' THEN 397
	WHEN gl_master.a_charcode BETWEEN '10' AND '20' THEN 10
	WHEN gl_master.a_charcode = '30' THEN 30
	WHEN gl_master.a_object BETWEEN '410000' AND '419999' THEN 41
	WHEN gl_master.a_object > '420000' AND gl_master.a_charcode = '40' THEN 40
	WHEN gl_master.a_charcode = '50' AND gl_master.a_object != '590000' THEN 50
	WHEN gl_master.a_charcode = '60' THEN 60
	WHEN gl_master.a_charcode BETWEEN '70' AND '80' THEN 70
	WHEN gl_master.a_charcode = '90' AND gl_master.a_object != '597000' THEN 90
	WHEN gl_master.a_object IN('590000', '597000') THEN 597
	END,
monthly_report_org_names = CASE WHEN gl_master.a_object BETWEEN '311100' AND '311104' AND gl_master.a_account_type = 'R' THEN 'Property Tax'
	WHEN gl_master.a_object BETWEEN '313110' AND '313710' AND gl_master.a_account_type = 'R' THEN 'Sales Taxes'
	WHEN gl_master.a_object = '316100' AND gl_master.a_account_type = 'R' THEN 'Business and Occupation Tax'
	WHEN gl_master.a_object BETWEEN '316401' AND '316470' AND gl_master.a_account_type = 'R' THEN 'Solid Waste Utility Tax'
	WHEN gl_master.a_object BETWEEN '316800' AND '316840' AND gl_master.a_account_type = 'R' THEN 'Gambling Taxes'
	WHEN gl_master.a_object BETWEEN '317200' AND '318120' AND gl_master.a_account_type = 'R' THEN 'Parking Tax'
	WHEN gl_master.a_object BETWEEN '318340' AND '318350' AND gl_master.a_account_type = 'R' THEN 'Real Estate Excise Taxes'
	WHEN gl_master.a_charcode = '32' THEN 'Licenses and Permits'
	WHEN gl_master.a_charcode = '33' THEN 'Intergovernmental Revenue'
	WHEN gl_master.a_charcode = '34' THEN 'Charges for Goods and Services'
	WHEN gl_master.a_charcode BETWEEN '35' and '39' AND gl_master.a_object != '397000' THEN 'Miscellaneous Revenue'
	WHEN gl_master.a_object = '397000' THEN 'Transfers In'
	WHEN gl_master.a_charcode BETWEEN '10' AND '20' THEN 'Salaries and Benefits'
	WHEN gl_master.a_charcode = '30' THEN 'Supplies'
	WHEN gl_master.a_object BETWEEN '410000' AND '419999' THEN 'Professional Services'
	WHEN gl_master.a_object > '420000' AND gl_master.a_charcode = '40' THEN 'Other Services'
	WHEN gl_master.a_charcode = '50' AND gl_master.a_object != '590000' THEN 'Intergovernmental Services'
	WHEN gl_master.a_charcode = '60' THEN 'Capital Outlay'
	WHEN gl_master.a_charcode BETWEEN '70' AND '80' THEN 'Debt Services'
	WHEN gl_master.a_charcode = '90' AND gl_master.a_object != '597000' THEN 'Other Financing Uses'
	WHEN gl_master.a_object IN('590000', '597000') THEN 'Transfers Out'
	END
FROM [munprod].[dbo].[gl_master]
LEFT OUTER JOIN [munprod].[dbo].[gl_detail]
ON (gl_detail.a_org + gl_detail.a_object) = (gl_master.a_org + gl_master.a_object) -- joins on a unique cost center - account string, to avoid duplication of transaction data and inflating summary totals in the SQL query
WHERE gl_master.a_account_type != 'B' -- excludes all asset and liability accounts
AND gl_master.a_fund_seg1 = '101' -- this is to define which fund the report will use. It is parameterized in Microsoft SSRS.
AND NOT gl_master.a_charcode IN('00', 'BF', 'FB') -- excludes depreciation expense, and fund balance (i.e., net equity for government entities)
