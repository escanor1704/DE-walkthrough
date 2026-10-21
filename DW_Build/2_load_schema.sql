-- load schema
select '==== Loading company_dim ====' as info;

insert into company_dim (company_id, name)
select company_id, name
from read_csv('https://storage.googleapis.com/sql_de/company_dim.csv',
auto_detect=true);

select '==== Loading skill_dim ====' as info;

insert into skill_dim(skill_id,skills,type)
select skill_id, skills, type
from read_csv('https://storage.googleapis.com/sql_de/skills_dim.csv',
auto_detect = true);


select '==== Loading job_postings_fact ====' as info;

INSERT INTO job_postings_fact (
    job_id, company_id, job_title_short, job_title, job_location,
    job_via, job_schedule_type, job_work_from_home, search_location,
    job_posted_date, job_no_degree_mention, job_health_insurance,
    job_country, salary_rate, salary_year_avg, salary_hour_avg
)
SELECT
    job_id, company_id, job_title_short, job_title, job_location,
    job_via, job_schedule_type, job_work_from_home, search_location,
    job_posted_date, job_no_degree_mention, job_health_insurance,
    job_country, salary_rate, salary_year_avg, salary_hour_avg
FROM read_csv('https://storage.googleapis.com/sql_de/job_postings_fact.csv',
    AUTO_DETECT=true);


select '==== Loading skills_job_dim ====' as info;

insert into skills_job_dim(skill_id, job_id)
select skill_id, job_id
from read_csv('https://storage.googleapis.com/sql_de/skills_job_dim.csv',
auto_detect = true);


select '==== no.of records in each table ====' as info;

select 'company dim' as table_name, count(*) as records from company_dim
union all
select 'skill dim', count(*) from skill_dim
union all
select 'skills job dim', count(*) from skills_job_dim
union all
select 'job posting fact', count(*) from job_postings_fact;


select '==== company dimensions sample ====' as info;
select * from company_dim
limit 5;
select * from skill_dim
limit 5;
select * from skills_job_dim
limit 5;
select * from job_postings_fact
limit 5;