/*
Question: What are the highest-paying skills for data engineers?
- Calculate the median salary for each skill required in data engineer positions
- Focus on remote positions with specified salaries
- Include skill frequency to identify both salary and demand
- Why? Helps identify which skills command the highest compensation while also showing 
    how common those skills are, providing a more complete picture for skill development priorities
*/

select
sd.skills,
round(median(jpf.salary_year_avg),1) as avg_salary,
count(jpf.*) as demand_count
from job_postings_fact as jpf
inner join skills_job_dim as sjd
on jpf.job_id = sjd.job_id
inner join skills_dim as sd
on sjd.skill_id = sd.skill_id
where
jpf.job_title_short ='Data Engineer'
and
jpf.job_work_from_home = 'True'
group by sd.skills
having count(sd.skills) > 100
order by avg_salary desc
limit 10;

-- output
┌───────────┬────────────┬──────────────┐
│  skills   │ avg_salary │ demand_count │
│  varchar  │   double   │    int64     │
├───────────┼────────────┼──────────────┤
│ rust      │   210000.0 │          232 │
│ golang    │   184000.0 │          912 │
│ terraform │   184000.0 │         3248 │
│ spring    │   175500.0 │          364 │
│ neo4j     │   170000.0 │          277 │
│ gdpr      │   169615.5 │          582 │
│ zoom      │   168437.5 │          127 │
│ graphql   │   167500.0 │          445 │
│ mongo     │   162250.0 │          265 │
│ fastapi   │   157500.0 │          204 │
└───────────┴────────────┴──────────────┘
  10 rows                     3 columns