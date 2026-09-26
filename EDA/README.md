# Job Market Analysis with SQL

SQL analysis of real job posting data to find which skills matter most for data engineers.

## Questions Answered

1. Which skills are most in demand?
2. Which skills pay the most?
3. Which skills give the best balance of both?

## Data Model

A star schema with one fact table and three supporting tables.

```text
  ┌──────────────────┐        ┌────────────────────────┐        ┌──────────────────┐
  │   company_dim    │        │   job_postings_fact    │        │  skills_job_dim  │
  ├──────────────────┤        ├────────────────────────┤        ├──────────────────┤
  │ company_id  PK   │◄───────┤ job_id            PK   ├───────►│ job_id    PK/FK  │
  │ name             │        │ company_id        FK   │        │ skill_id  PK/FK  │
  │ link             │        │ job_title_short        │        └────────┬─────────┘
  │ link_google      │        │ job_title              │                 │
  │ thumbnail        │        │ job_location           │                 │
  └──────────────────┘        │ job_via                │                 ▼
                              │ job_schedule_type      │        ┌──────────────────┐
                              │ job_work_from_home     │        │    skills_dim    │
                              │ search_location        │        ├──────────────────┤
                              │ job_posted_date        │        │ skill_id    PK   │
                              │ job_no_degree_mention  │        │ skills           │
                              │ job_health_insurance   │        │ type             │
                              │ job_country            │        └──────────────────┘
                              │ salary_rate            │
                              │ salary_year_avg        │
                              │ salary_hour_avg        │
                              └────────────────────────┘
```

| Table | Type | Contents |
|---|---|---|
| `job_postings_fact` | Fact | Job titles, locations, salaries, dates |
| `company_dim` | Dimension | Company details |
| `skills_dim` | Dimension | Skill names and types |
| `skills_job_dim` | Bridge | Links jobs to skills (many-to-many) |

## Files

```text
1_EDA/
├── top_demanding_skills.sql    # Most requested skills
├── top_highest_paid.sql      # Highest salaries
├── 03_optimal_skills.sql         # Best demand + salary combination
└── README.md
```

## Findings

- SQL and Python lead by a wide margin, each in roughly 29,000 postings
- AWS and Azure appear in most modern data engineering roles
- Kubernetes, Docker, and Terraform correlate with higher salaries
- Apache Spark combines strong demand with good pay

## Approach

Query 3 ranks skills by an optimal score:

```sql
LN(COUNT(*)) * MEDIAN(salary_year_avg)
```

The natural log compresses demand so a skill with 10,000 postings does not overwhelm salary in the ranking. Without it, the result is just a popularity list.

Only skills with at least 100 postings are included, so a single high-paying outlier cannot reach the top.

## Tech

- **DuckDB** — fast local analytical queries, no server setup
- **SQL** — joins, `GROUP BY`, `HAVING`, `MEDIAN()`, `LN()`
- **Git** — version control

## Running It

```bash
duckdb data_jobs.duckdb
```

```sql
.read top_demanding_skills.sql
```