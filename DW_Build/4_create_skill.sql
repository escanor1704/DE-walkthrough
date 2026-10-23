-- step 4
drop schema if exists skills_mart cascade;

create schema skills_mart;

create table skills_mart.dim_skill(
    skill_id integer primary key,
    skills varchar,
    type varchar
);

insert into skills_mart.dim_skill(
    skill_id,
    skills,
    type
)
select
    skill_id,
    skills,
    type
from skill_dim;


SELECT '=== loading skill fact for skill mart ===' AS info;
create table skills_mart.dim_date_month(
    month_start date primary key,
    year integer,
    month integer,
    quarter integer,
    quarter_name varchar,
    year_quarter varchar
);

insert into skills_mart.dim_date_month(
    month_start,
    year,
    month,
    quarter,
    quarter_name,
    year_quarter
)
select distinct
    date_trunc('month', job_posted_date) as month_start,
    extract(year from job_posted_date) as year,
    extract(month from job_posted_date) as month,
    extract(quarter from job_posted_date) as quarter,
    'Q-' || extract(quarter from job_posted_date):: varchar as quarter_name,
    extract(year from job_posted_date) || '-Q' || extract(quarter from job_posted_date):: varchar as year_quarter
from job_postings_fact
order by month_start;




CREATE TABLE skills_mart.fact_skill_demand_monthly (
    skill_id INTEGER,
    month_start DATE,
    job_title_short VARCHAR,
    postings_count INTEGER,
    remote_postings_count INTEGER,
    health_insurance_postings_count INTEGER,
    no_degree_mention_postings_count INTEGER,
    PRIMARY KEY (skill_id, month_start, job_title_short),
    FOREIGN KEY (skill_id) REFERENCES skills_mart.dim_skill(skill_id),
    FOREIGN KEY (month_start) REFERENCES skills_mart.dim_date_month(month_start)
);

INSERT INTO skills_mart.fact_skill_demand_monthly (
    skill_id,
    month_start,
    job_title_short,
    postings_count,
    remote_postings_count,
    health_insurance_postings_count,
    no_degree_mention_postings_count
)

with job_postings_prep as(
    select
    sjd.skill_id,
    date_trunc('month', jpf.job_posted_date) as month_start,
    jpf.job_title_short,
    -- convert boolean
    case when jpf.job_work_from_home = true then 1 else 0 end as is_remote,
    case when jpf.job_health_insurance = true then 1 else 0 end as has_health_insurance,
    case when jpf.job_no_degree_mention = true then 1 else 0 end as no_degree_required
    from job_postings_fact as jpf
    inner join skills_job_dim as sjd
    on sjd.job_id = jpf.job_id
)
select
skill_id,
month_start,
job_title_short,
count(*),
sum(is_remote) as remote_count,
sum(has_health_insurance) as health_insurance_count,
sum(no_degree_required) as no_degree_count
from job_postings_prep
group by all
order by skill_id, month_start, job_title_short;

select 'skill dimension' as table_name, count(*) as record_count from skills_mart.dim_skill
union all
select 'date month dimension', count(*) from skills_mart.dim_date_month
union all
select 'skill demand', count(*) from skills_mart.fact_skill_demand_monthly;


SELECT '=== Skill Dimension Sample ===' AS info;
SELECT * FROM skills_mart.dim_skill LIMIT 5;

SELECT '=== Date Month Dimension Sample ===' AS info;
SELECT * FROM skills_mart.dim_date_month ORDER BY month_start DESC LIMIT 5;

select '==== skill demand fact sample ====' as info;
select * from skills_mart.fact_skill_demand_monthly limit 5;
