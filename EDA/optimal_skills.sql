/*
Question: What are the most optimal skills for data engineers—balancing both demand and salary?
- Create a ranking column that combines demand count and median salary to identify the most valuable skills.
- Focus only on remote Data Engineer positions with specified annual salaries.
- Why?
    - This approach highlights skills that balance market demand and financial reward. It weights core skills appropriately instead of letting rare, outlier skills distort the results.
    - The natural log transformation ensures that both high-salary and widely in-demand skills surface as the most practical and valuable to learn for data engineering careers.
*/


select
sd.skills,
round(median(jpf.salary_year_avg),1) as avg_salary,
count(jpf.*) as demand_count,
round(ln(count(jpf.*)),2) as demand_log,
round((ln(count(jpf.*)) * median(jpf.salary_year_avg)) / 1000000, 2) as ranking
from job_postings_fact as jpf
inner join skills_job_dim as sjd
on jpf.job_id = sjd.job_id
inner join skills_dim as sd
on sjd.skill_id = sd.skill_id
where
jpf.job_title_short ='Data Engineer'
and
jpf.job_work_from_home = 'True'
and
jpf.salary_year_avg is not null
group by sd.skills
having count(sjd.job_id) >= 100
order by ranking desc
limit 10;


-- output
┌───────────┬────────────┬──────────────┬────────────┬─────────┐
│  skills   │ avg_salary │ demand_count │ demand_log │ ranking │
│  varchar  │   double   │    int64     │   double   │ double  │
├───────────┼────────────┼──────────────┼────────────┼─────────┤
│ terraform │   184000.0 │          193 │       5.26 │    0.97 │
│ python    │   135000.0 │         1133 │       7.03 │    0.95 │
│ aws       │   137320.3 │          783 │       6.66 │    0.91 │
│ sql       │   130000.0 │         1128 │       7.03 │    0.91 │
│ airflow   │   150000.0 │          386 │       5.96 │    0.89 │
│ spark     │   140000.0 │          503 │       6.22 │    0.87 │
│ kafka     │   145000.0 │          292 │       5.68 │    0.82 │
│ snowflake │   135500.0 │          438 │       6.08 │    0.82 │
│ azure     │   128000.0 │          475 │       6.16 │    0.79 │
│ java      │   135000.0 │          303 │       5.71 │    0.77 │
└───────────┴────────────┴──────────────┴────────────┴─────────┘
  10 rows                                            5 columns