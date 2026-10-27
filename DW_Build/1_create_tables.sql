-- 1-create star schema

-- drop the tables if they are exists
drop table if exists skills_job_dim;
drop table if exists job_postings_fact;
drop table if exists skill_dim;
drop table if exists company_dim;



create table company_dim(
    company_id integer primary key,
    name varchar
);

create table skill_dim(
    skill_id integer primary key,
    skills varchar,
    type varchar
);

CREATE TABLE job_postings_fact (
    job_id INTEGER PRIMARY KEY,
    company_id INTEGER,
    job_title_short VARCHAR,
    job_title VARCHAR,
    job_location VARCHAR,
    job_via VARCHAR,
    job_schedule_type VARCHAR,
    job_work_from_home BOOLEAN,
    search_location VARCHAR,
    job_posted_date TIMESTAMP,
    job_no_degree_mention BOOLEAN,
    job_health_insurance BOOLEAN,
    job_country VARCHAR,
    salary_rate VARCHAR,
    salary_year_avg DOUBLE,
    salary_hour_avg DOUBLE,
    FOREIGN KEY (company_id) REFERENCES company_dim(company_id)
);

create table skills_job_dim(
    skill_id integer,
    job_id integer,
    primary key (skill_id, job_id),
    foreign key (skill_id) references skill_dim(skill_id),
    foreign key (job_id) references  job_postings_fact(job_id)
);

SELECT table_name
FROM information_schema.tables
WHERE table_catalog = 'dw_build'
  AND table_schema  = 'main'
ORDER BY table_name;
