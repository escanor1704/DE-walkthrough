-- step 6

select '==== Updating roles for priority mart ====';
-- update data engineer to priority1
update priority_mart.priority_roles
set priority_lvl = 1
where role_name='Data Engineer';

-- add data science to level3
insert into priority_mart.priority_roles(role_id, role_name, priority_lvl)
values(4, 'Data Scientist', 3);

select * from priority_mart.priority_roles;

select '==== creating temp source table for priority mart ====';

CREATE OR REPLACE TEMP TABLE src_priority_jobs AS 
SELECT 
  jpf.job_id,
  jpf.job_title_short,
  cd.name AS company_name,
  jpf.job_posted_date,
  jpf.salary_year_avg,
  r.priority_lvl,
  CURRENT_TIMESTAMP AS updated_at
FROM
    job_postings_fact AS jpf                        
LEFT JOIN company_dim AS cd                           
    ON jpf.company_id = cd.company_id
INNER JOIN priority_mart.priority_roles AS r               
    ON jpf.job_title_short = r.role_name;

SELECT '=== Batch Updating priority_jobs_snapshot Priority Mart ===' AS info;
MERGE INTO priority_mart.priority_jobs_snapshot AS tgt     -- updated to use priority_mart schema
USING src_priority_jobs AS src
ON tgt.job_id = src.job_id

WHEN MATCHED AND tgt.priority_lvl IS DISTINCT FROM src.priority_lvl THEN
    UPDATE SET
        priority_lvl = src.priority_lvl,
        updated_at = src.updated_at

WHEN NOT MATCHED THEN
    INSERT (
        job_id,
        job_title_short,
        company_name,
        job_posted_date,
        salary_year_avg,
        priority_lvl,
        updated_at
    )
    VALUES (
        src.job_id,
        src.job_title_short,
        src.company_name,
        src.job_posted_date,
        src.salary_year_avg,
        src.priority_lvl,
        src.updated_at
    )

WHEN NOT MATCHED BY SOURCE THEN DELETE;

-- Verify mart was updated
SELECT 'Priority Roles Dimension' AS table_name, COUNT(*) as record_count FROM priority_mart.priority_roles
UNION ALL
SELECT 'Priority Jobs Snapshot', COUNT(*) FROM priority_mart.priority_jobs_snapshot;

-- Show sample data from each table
SELECT '=== Priority Roles Dimension Sample ===' AS info;
SELECT * FROM priority_mart.priority_roles;

SELECT '=== Priority Jobs Snapshot Sample ===' AS info;
SELECT 
    job_title_short,
    COUNT(*) AS job_count,
    MIN(priority_lvl) AS priority_lvl,
    MIN(updated_at) AS updated_at
FROM priority_mart.priority_jobs_snapshot          -- updated to use priority_mart schema
GROUP BY job_title_short
ORDER BY job_count DESC;