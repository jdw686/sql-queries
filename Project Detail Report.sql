SELECT DISTINCT
pa_transact_detail.a_project,
CASE WHEN jl_source_code = 'PAJ' THEN jl_transaction_amt ELSE 0 END AS 'Project Budget',
CASE WHEN jl_source_code IN ('API', 'PAC') THEN jl_transaction_amt ELSE 0 END AS 'Project Actual',
CASE WHEN jl_comment = '' AND jl_effective_dt <= '12/31/2017' THEN 'Prior Year Balance from Springbrook' ELSE jl_comment END AS 'Transaction Description',
jl_effective_dt,
jl_source_code,
jl_gl_obj,
a_object_desc,
a_vendor_name,
pa_project_master.ma_project_title
FROM [munprod].[dbo].[pa_transact_detail]
LEFT OUTER JOIN [munprod].[dbo].[gl_object]
ON gl_object.a_object = pa_transact_detail.jl_gl_obj
LEFT OUTER JOIN [munprod].[dbo].[ap_vendor]
ON ap_vendor.a_vendor_number = pa_transact_detail.jl_jnl_ref1
LEFT OUTER JOIN [munprod].[dbo].[pa_project_master]
ON pa_project_master.a_project = pa_transact_detail.a_project
WHERE pa_transact_detail.a_project = @Project
AND NOT jl_source_code IN('COE', 'COM', 'POE', 'POM', 'POL', 'COL', 'BUA', 'BUC')
AND pa_transact_detail.jl_effective_dt <= '12/31/18'
ORDER BY pa_transact_detail.jl_effective_dt