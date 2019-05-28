SELECT DISTINCT
-- overall note: for assertions that give a specific year and date, this is replaced in Mirosoft SSRS Report Builder as as a parameter, which allows the user to run a report in the year of their choice.
-- for example, instead of gl_detail.j_transact_year = 2018, the SSRS Report Builder would read gl_detail.j_transact_year = @Year
ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project, gl_detail.j_transact_year ORDER BY gl_master.a_object) as row1,
--This line is the first test of the sorting I did for budget items, it is not used in the code below.
ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) as row2,
--This line, used in the budget code below, assigns a row number, sequenced by org, object, and project number. It is used in the budget code below.
CASE WHEN gl_detail.j_transact_year = 2018 AND gl_detail.j_transact_period <= 13 AND gl_master.a_object >= 640000 AND gl_master.a_fund_seg1 = 104 AND NOT gl_detail.j_jnl_source IN ('COE', 'COM', 'POE', 'POM', 'POL', 'COL', 'BUA', 'BUC', 'GEN') THEN gl_detail.j_debit_amount - gl_detail.j_credit_amount ELSE
CASE WHEN gl_detail.j_transact_year = 2018 AND gl_detail.j_transact_period <= 13 AND gl_master.a_object < 640000 AND gl_master.a_fund_seg1 = 104 AND NOT gl_detail.j_jnl_source IN ('COE', 'COM', 'POE', 'POM', 'POL', 'COL', 'BUA', 'BUC') THEN gl_detail.j_debit_amount - gl_detail.j_credit_amount
	ELSE 0 END END AS cy_net_amount,
--This line deals with a specific case in the Surface Water Management Fund (or Equipment Replacement Fund if = 107) where capital expenses and debt service are capitalized and their transaction amounts are reversed. If the object number is greater than the indicated above (debt service starts with 7), then generated journal entries are zeroed out. Any transaction detail which object/account is below the indicated number includes generated journal entries (which is mostly for salaries and benefits)
--These lines exclude a list of journal source types, namely contract entry, amendments, and liquidation entries, purchase order entries, amendments and liquidations, and budget entries and amendments.
CASE WHEN gl_detail.j_transact_year = 2018 - 1 AND gl_detail.j_transact_period <= 13 AND gl_master.a_object >= 640000 AND gl_master.a_fund_seg1 = 104 AND NOT gl_detail.j_jnl_source IN ('COE', 'COM', 'POE', 'POM', 'POL', 'COL', 'BUA', 'BUC', 'GEN') THEN gl_detail.j_debit_amount - gl_detail.j_credit_amount ELSE
CASE WHEN gl_detail.j_transact_year = 2018 - 1 AND gl_detail.j_transact_period <= 13 AND gl_master.a_object < 640000 AND gl_master.a_fund_seg1 = 104 AND NOT gl_detail.j_jnl_source IN ('COE', 'COM', 'POE', 'POM', 'POL', 'COL', 'BUA', 'BUC') THEN gl_detail.j_debit_amount - gl_detail.j_credit_amount
	ELSE 0 END END AS ly_net_amount,
--This line is the same as above, but for the prior year
CASE WHEN gl_detail.j_transact_year = 2018 - 1 AND gl_master.a_object >= 640000 AND gl_master.a_fund_seg1 = 104 AND NOT gl_detail.j_jnl_source IN ('COE', 'COM', 'POE', 'POM', 'POL', 'COL', 'BUA', 'BUC', 'GEN') THEN gl_detail.j_debit_amount - gl_detail.j_credit_amount ELSE
CASE WHEN gl_detail.j_transact_year = 2018 - 1 AND gl_master.a_object < 640000 AND gl_master.a_fund_seg1 = 104 AND NOT gl_detail.j_jnl_source IN ('COE', 'COM', 'POE', 'POM', 'POL', 'COL', 'BUA', 'BUC') THEN gl_detail.j_debit_amount - gl_detail.j_credit_amount
	ELSE 0 END END AS ly_net_amount_ye,
--This is the same as the prior year code above, but does not have a period parameter, which provides the year end transaction sum for the prior year
CASE WHEN ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) = 1 AND 2018 = gl_master.gp_curr_year + 1 THEN gl_master.d_ny_rev_bud
	WHEN ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) = 1 AND 2018 = gl_master.gp_curr_year THEN gl_master.d_cy_revised_bud
	WHEN ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) = 1 AND 2018 = gl_master.gp_curr_year - 1 THEN gl_master.d_ly1_rev_bud
	ELSE 0 END AS 'Current Year Budget',
--using the row sequencing described above, the case statement determines which user inputted year matches to the year defined as the current year in the financial system (it is the prior calendar year until the year is closed). If the row number = 1, it returns the budget figure for the object that corresponds to the user inputted year.
CASE WHEN ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) = 1 AND (2018 - 1) = gl_master.gp_curr_year + 1 THEN gl_master.d_ny_rev_bud
	WHEN ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) = 1 AND (2018 - 1) = gl_master.gp_curr_year THEN gl_master.d_cy_revised_bud
	WHEN ROW_NUMBER() OVER (PARTITION BY gl_master.a_org, gl_master.a_object, gl_master.a_project ORDER BY gl_master.a_object) = 1 AND (2018 - 1) = gl_master.gp_curr_year - 1 THEN gl_master.d_ly1_rev_bud
	ELSE 0 END AS 'Prior Year Budget',
--same as the budget code above, but returns the prior year budget amount
gl_detail.j_jnl_source, -- this column identifies the type of transaction in the financial system. For this report, we focus on API (A/P Invoices) or CRP (Customer Receipts for fees paid to the City)
gl_master.a_account_type, -- this column identifies whether an account is a revenue, expense, or balance sheet account
gl_master.a_fund_seg1, --
gl_master.a_org, -- this is the number for each organizational unit, a.k.a. cost center
gl_master.a_object, -- the 'object' is the name used in the financial system to denote an account
gl_master.a_charcode, -- character code are broad categories similar accounts. For example, all objects starting with a 4 belong to character code 40 (all expenses the City pays for a service it receives)
gl_detail.j_transact_year, -- the year the transaction was recorded
gl_master.gp_deflt_year, -- the calendar year in the accounting system. this is not to be confused with the gl_master.gp_curr_year, which is the year which the financial system operates until the books are closed and ready for the State audit.
--below provides the categories in the quarterly financial report, which is used as a group in Microsoft SSRS report builder. The report is sequenced by character code, and then these category numbers.
quarterly_report_orgs = CASE
	WHEN gl_master.a_object BETWEEN '311100' AND '311104' AND gl_master.a_account_type = 'R' THEN 311
	WHEN gl_master.a_object BETWEEN 313110 AND 313710 AND gl_master.a_account_type = 'R' THEN 313
	WHEN gl_master.a_object = 316100 AND gl_master.a_account_type = 'R' THEN 316.1
	WHEN gl_master.a_object BETWEEN 316401 AND 316470 AND gl_master.a_account_type = 'R' AND gl_master.a_fund_seg1 = 001 THEN 316.41
	WHEN gl_master.a_object BETWEEN 316401 AND 316470 AND gl_master.a_account_type = 'R' AND gl_master.a_fund_seg1 = 101 THEN 316.42
	WHEN gl_master.a_object BETWEEN 316800 AND 318110 AND gl_master.a_account_type = 'R' AND gl_master.a_fund_seg1 = 001 THEN 316.8
	WHEN gl_master.a_object = 317600 THEN 317
	WHEN gl_master.a_object = 318120 THEN 318.1
	WHEN gl_master.a_object BETWEEN 318340 AND 318350 AND gl_master.a_account_type = 'R' THEN 318.3
	WHEN gl_master.a_object IN (321700, 321991, 322300) THEN 321
	WHEN gl_master.a_object BETWEEN 321910 AND 321912 THEN 321.91
	WHEN gl_master.a_object = 321990 THEN 321.99
	WHEN gl_master.a_object BETWEEN 322101 AND 322104 THEN 322.1
	WHEN gl_master.a_object = 322106 THEN 322.2
	WHEN gl_master.a_object = 322400 THEN 322.4
	WHEN gl_master.a_object BETWEEN 331000 AND 333999 THEN 333
	WHEN gl_master.a_object BETWEEN 334000 AND 334999 THEN 334
	WHEN gl_master.a_object = 336060 AND gl_master.a_project BETWEEN 21 AND 93 THEN 336.1
	WHEN gl_master.a_object = 336060 AND gl_master.a_project BETWEEN 94 AND 95 THEN 336.2
	WHEN gl_master.a_object BETWEEN 337100 AND 337220 AND gl_master.a_object != 337110 THEN 337
	WHEN gl_master.a_object = 337110 THEN 337.1
	WHEN gl_master.a_object BETWEEN 341000 AND 342999 THEN 341
	WHEN gl_master.a_object BETWEEN 343000 AND 343999 THEN 343
	WHEN gl_master.a_object IN (345830, 345892, 345893, 345894) THEN 345.1
	WHEN gl_master.a_object IN (345810, 345831, 345832, 345833, 345834) THEN 345.2
	WHEN gl_master.a_object IN (345811, 345820, 345850, 345851) THEN 345.8
	WHEN gl_master.a_object BETWEEN 347000 AND 347999 THEN 347
	WHEN gl_master.a_charcode = '35' THEN 35
	WHEN gl_master.a_object BETWEEN 361000 AND 361410 AND NOT gl_master.a_object IN (361402, 361403) THEN 361
	WHEN gl_master.a_object BETWEEN 362000 AND 362999 THEN 362
	WHEN gl_master.a_object BETWEEN 367000 AND 393100 AND NOT gl_master.a_object IN (361402, 361403, 368100, 368102) THEN 363
	WHEN gl_master.a_object IN (361402, 361403, 368100, 368102) THEN 368
	WHEN gl_master.a_object = 395100 THEN 395.1
	WHEN gl_master.a_object = 395200 THEN 395.2
	WHEN gl_master.a_object IN (344100, 348000, 397000) THEN 397
	WHEN gl_master.a_object = 398000 THEN 395.2
	WHEN gl_master.a_object BETWEEN 110000 AND 120000 THEN 10
	WHEN gl_master.a_object BETWEEN 210000 AND 299999 THEN 20
	WHEN gl_master.a_object BETWEEN 300000 AND 399999 AND gl_master.a_account_type = 'E' THEN 30
	WHEN gl_master.a_object BETWEEN 410000 AND 419999 THEN 41
	WHEN gl_master.a_object BETWEEN 420000 AND 429999 THEN 42
	WHEN gl_master.a_object BETWEEN 430000 AND 439999 THEN 43
	WHEN gl_master.a_object = 440000 THEN 44
	WHEN gl_master.a_object = 450000 THEN 45
	WHEN gl_master.a_object = 460000 THEN 46
	WHEN gl_master.a_object = 470000 THEN 47
	WHEN gl_master.a_object BETWEEN 480000 AND 489999 THEN 48
	WHEN gl_master.a_object = 494900 THEN 49
	WHEN gl_master.a_object = 494910 THEN 49.1
	WHEN gl_master.a_object = 494920 THEN 49.2
	WHEN gl_master.a_object = 494930 THEN 49.3
	WHEN gl_master.a_object = 494940 THEN 49.4
	WHEN gl_master.a_object IN (494010, 494020, 494030, 494950, 494960, 494970, 494980, 494990, 494995) THEN 49.5
	WHEN gl_master.a_object BETWEEN 500000 AND 589999 AND NOT gl_master.a_object IN (510100, 510300, 510350) THEN 50
	WHEN gl_master.a_object = 510100 THEN 50.1
	WHEN gl_master.a_object = 510300 THEN 50.2
	WHEN gl_master.a_object = 510350 THEN 50.3
	WHEN gl_master.a_object BETWEEN 600000 AND 699999 THEN 60
	WHEN gl_master.a_object BETWEEN 700000 AND 799999 THEN 70
	WHEN gl_master.a_object BETWEEN 800000 AND 899999 THEN 80
	WHEN gl_master.a_object IN(590000, 597000) THEN 90
	END,
--the titles below provides names to the categories already defined above, using the same criteria
quarterly_report_orgs_names = CASE WHEN gl_master.a_object BETWEEN 311100 AND 311104 AND gl_master.a_account_type = 'R' THEN 'Property Tax'
	WHEN gl_master.a_object BETWEEN 313110 AND 313710 AND gl_master.a_account_type = 'R' THEN 'Sales Tax'
	WHEN gl_master.a_object = 316100 AND gl_master.a_account_type = 'R' THEN 'Business and Occupation Tax'
	WHEN gl_master.a_object BETWEEN 316401 AND 316470 AND gl_master.a_account_type = 'R' AND gl_master.a_fund_seg1 = 001 THEN 'Utility Tax'
	WHEN gl_master.a_object BETWEEN 316401 AND 316470 AND gl_master.a_account_type = 'R' AND gl_master.a_fund_seg1 = 101 THEN 'Solid Waste Utility Tax'
	WHEN gl_master.a_object BETWEEN 316800 AND 318110 AND gl_master.a_account_type = 'R' AND gl_master.a_fund_seg1 = 001 THEN 'Other Taxes'
	WHEN gl_master.a_object = 317600 THEN 'TBD Vehicle Fee'
	WHEN gl_master.a_object = 318120 THEN 'Parking Tax'
	WHEN gl_master.a_object BETWEEN 318340 AND 318350 AND gl_master.a_account_type = 'R' THEN 'Real Estate Excise Tax'
	WHEN gl_master.a_object IN (321700, 321991, 322300) THEN 'Miscellaneous Licenses and Receipts'
	WHEN gl_master.a_object BETWEEN 321910 AND 321912 THEN 'Franchise Fees'
	WHEN gl_master.a_object = 321990 THEN 'Business Licenses'
	WHEN gl_master.a_object BETWEEN 322101 AND 322104 THEN 'Permits - Building Related'
	WHEN gl_master.a_object = 322106 THEN 'Permits - Electrical'
	WHEN gl_master.a_object = 322400 THEN 'Permits - Right of Way'
	WHEN gl_master.a_object BETWEEN 331000 AND 333999 THEN 'Federal Grants'
	WHEN gl_master.a_object BETWEEN 334000 AND 334999 THEN 'State Grants'
	WHEN gl_master.a_object = 336060 AND gl_master.a_project BETWEEN 21 AND 93 THEN 'State Shared Revenues'
	WHEN gl_master.a_object = 336060 AND gl_master.a_project BETWEEN 94 AND 95 THEN 'Liquor Tax and Profits'
	WHEN gl_master.a_object BETWEEN 337100 AND 337220 AND gl_master.a_object != 337110 THEN 'Intergovernmental Revenues'
	WHEN gl_master.a_object = 337110 THEN 'Seattle City Light Franchise Fee'
	WHEN gl_master.a_object BETWEEN 341000 AND 342999 THEN 'Government and Public Safety Fees'
	WHEN gl_master.a_object BETWEEN 343000 AND 343999 THEN 'Storm Drainage Fees and Charges'
	WHEN gl_master.a_object IN (345830, 345892, 345893, 345894) THEN 'Planning and Development Fees'
	WHEN gl_master.a_object IN (345810, 345831, 345832, 345833, 345834) THEN 'Building Plan Review Fees'
	WHEN gl_master.a_object IN (345811, 345820, 345850, 345851) THEN 'Mitigation Fees'
	WHEN gl_master.a_object BETWEEN 347000 AND 347999 THEN 'Recreation Fees'
	WHEN gl_master.a_object BETWEEN 350000 AND 359999 THEN 'Fines and Penalties'
	WHEN gl_master.a_object BETWEEN 361000 AND 361410 AND NOT gl_master.a_object IN (361402, 361403) THEN 'Investment Income'
	WHEN gl_master.a_object BETWEEN 362000 AND 362999 THEN 'Rental Income'
	WHEN gl_master.a_object BETWEEN 367000 AND 393100 AND NOT gl_master.a_object IN (361402, 361403, 368100, 368102) THEN 'Miscellaneous Revenue'
	WHEN gl_master.a_object IN (361402, 361403, 368100, 368102) THEN 'Special Assessment LID Revenue'
	WHEN gl_master.a_object = 395100 THEN 'Sale of Capital Assets'
	WHEN gl_master.a_object = 395200 THEN 'Compensation for Loss of Assets'
	WHEN gl_master.a_object IN (344100, 348000, 397000) THEN 'Transfers In'
	WHEN gl_master.a_object = 398000 THEN 'Insurance Recoveries'
	WHEN gl_master.a_object BETWEEN 110000 AND 120000 THEN 'Salaries and Wages'
	WHEN gl_master.a_object BETWEEN 210000 AND 299999 THEN 'Personnel Benefits'
	WHEN gl_master.a_object BETWEEN 300000 AND 399999 AND gl_master.a_account_type = 'E' THEN 'Supplies'
	WHEN gl_master.a_object BETWEEN 410000 AND 419999 THEN 'Professional Services'
	WHEN gl_master.a_object BETWEEN 420000 AND 429999 THEN 'Telephone/Internet'
	WHEN gl_master.a_object BETWEEN 430000 AND 439999 THEN 'Travel'
	WHEN gl_master.a_object = 440000 THEN 'Taxes and Assessments'
	WHEN gl_master.a_object = 450000 THEN 'Operating Rents and Leases'
	WHEN gl_master.a_object = 460000 THEN 'Insurance'
	WHEN gl_master.a_object = 470000 THEN 'Utilities'
	WHEN gl_master.a_object BETWEEN 480000 AND 489999 THEN 'Repairs and Maintenance'
	WHEN gl_master.a_object = 494900 THEN 'Admissions and Trips'
	WHEN gl_master.a_object = 494910 THEN 'Memberships and Dues'
	WHEN gl_master.a_object = 494920 THEN 'Printing/Binding/Copying'
	WHEN gl_master.a_object = 494930 THEN 'Registration and Training'
	WHEN gl_master.a_object = 494940 THEN 'Subscriptions and Publications'
	WHEN gl_master.a_object IN (494010, 494020, 494030, 494950, 494960, 494970, 494980, 494990, 494995) THEN 'Miscellaneous Services'
	WHEN gl_master.a_object BETWEEN 500000 AND 589999 AND NOT gl_master.a_object IN (510100, 510300, 510350) THEN 'Intergovernmental Services'
	WHEN gl_master.a_object = 510100 THEN 'Police Services'
	WHEN gl_master.a_object = 510300 THEN 'Jail Services'
	WHEN gl_master.a_object = 510350 THEN 'Municipal Court Services'
	WHEN gl_master.a_object BETWEEN 600000 AND 699999 THEN 'Capital Outlay'
	WHEN gl_master.a_object BETWEEN 700000 AND 799999 THEN 'Debt Service Principal'
	WHEN gl_master.a_object BETWEEN 800000 AND 899999 THEN 'Debt Service Interest'
	WHEN gl_master.a_object IN(590000, 597000) THEN 'Transfers Out'
	END
FROM [munprod].[dbo].[gl_master]
LEFT OUTER JOIN [munprod].[dbo].[gl_detail]
ON (gl_detail.a_org + gl_detail.a_object) = (gl_master.a_org + gl_master.a_object)
--this join combines org and object numbers to provide a unique field to prevent duplicating transaction detail. the left outer join is to ensure that budgeted amounts for accounts that have transaction detail AND never had a budget allocation to appear in the report
WHERE gl_master.a_account_type != 'B'
--this condition above excludes all balance sheet accounts from the query
AND NOT gl_master.a_charcode IN('00')
-- the above condition excludes all depreciation expense, which is not required to be reported for governmental or business-type funds.
ORDER BY gl_master.a_object
