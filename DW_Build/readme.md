# Data Warehouse & Mart Build

A SQL pipeline that loads job posting data into a DuckDB star schema and builds three analytical marts on top of it. The same scripts run against a local DuckDB file or against MotherDuck.

## What this builds

**Warehouse** — normalized star schema in the `main` schema.

| Table | Rows | Grain |
|---|---|---|
| `company_dim` | 215,940 | One company |
| `skill_dim` | 262 | One skill, with its category |
| `job_postings_fact` | 1,615,930 | One job posting |
| `skills_job_dim` | 7,193,426 | One posting-skill pair |

**Marts** — one schema per use case, so each can be rebuilt without touching the others.

| Schema | Table | Rows | Grain |
|---|---|---|---|
| `flat_mart` | `<flat table>` | 1,615,930 | One posting, dimensions joined, skills as an array of structs |
| `skills_mart` | `dim_skill` | 262 | One skill |
| `skills_mart` | `dim_date_month` | 30 | One month |
| `skills_mart` | `fact_skill_demand_monthly` | 52,520 | `skill_id` + `month_start` + `job_title_short` |
| `priority_mart` | `<roles table>` | 4 | One tracked role |
| `priority_mart` | `<snapshot table>` | 906,525 | One posting in a priority role |

Every measure in `fact_skill_demand_monthly` is a count, so the numbers stay correct when re-aggregated to quarter, year, or across skills. That was the point of choosing counts over ratios — a stored percentage cannot be summed later.

## Running it

Local:

```bash
duckdb dw_build.duckdb -c ".read code_build.sql"
```

MotherDuck:

```bash
duckdb md:dw_build -c ".read code_build.sql"
```

`code_build.sql` runs every step in order. It is re-runnable: each step drops and rebuilds its own tables, so running it twice gives the same result as running it once.

## Files

```text
DW_Build/
├── 1_create_tables.sql   # Star schema DDL
├── code_build.sql        # Master script, runs all steps
└── README.md
```

## Decisions and the reasons behind them

**Drops go in reverse dependency order.** Foreign keys mean DuckDB will not drop a parent table while a child still points at it. `1_create_tables.sql` drops `skills_job_dim`, then `job_postings_fact`, then `skill_dim`, then `company_dim` — children first, the mirror of the creation order.

I started with `CREATE OR REPLACE TABLE` and it does not work here. `OR REPLACE` is a drop followed by a create, and the drop half runs into the same foreign key constraint. The error only appears on the second run, because the first run has nothing to drop yet.

**Loads go the other way: dimensions first.** DuckDB enforces foreign keys on insert, not just on drop. A fact row whose `company_id` has no parent is rejected:

```
Constraint Error: Violates foreign key constraint because key "company_id: 999" does not exist in the referenced table
```

So `company_dim` and `skill_dim` load before `job_postings_fact`, and `skills_job_dim` loads last.

**The flat mart aggregates skills before joining them.** Joining `skills_job_dim` straight onto the fact table multiplies rows — a posting with four skills becomes four rows, and the one-row-per-posting grain is gone. Aggregating the skills in a CTE first, then left joining the result, keeps the grain.

The left join also needs a guard. A posting with no skills still produces one joined row with NULLs in both skill columns, and `ARRAY_AGG` packs that into `[{'type': NULL, 'name': NULL}]` — an array of length one, not zero. Anything downstream counting array length then reports that posting as having a skill. `COALESCE(..., [])` fixes it.

**`dim_date_month` filters out NULL posting dates.** `month_start` is the primary key, which means NOT NULL, and `DATE_TRUNC('month', NULL)` returns NULL. One row with a missing date would fail the whole build:

```
Constraint Error: NOT NULL constraint failed: dim_date_month.month_start
```

There are none in the data today. The `WHERE job_posted_date IS NOT NULL` filter is there so one bad upstream row cannot break the pipeline later.

## MotherDuck differences

**Set the catalog once at the top.** MotherDuck attaches several databases to a session — your own, its sample data, and its service catalog. An unqualified schema name can then match more than one thing:

```
Binder Error: Ambiguous reference to catalog or schema "skills_mart"
```

```sql
USE dw_build;
```

Writing `dw_build.skills_mart.<table>` instead works for most statements but not for foreign keys. DuckDB rejects a catalog-qualified FK target:

```
Parser Error: FOREIGN KEY constraints cannot be defined cross-database
```

Since `fact_skill_demand_monthly` has two foreign keys into its own schema, `USE` is the only fix that covers every statement in the file.

The local file is named `dw_build.duckdb`, so DuckDB calls its catalog `dw_build` — the same name as the MotherDuck database. One `USE dw_build;` is therefore correct in both environments.

**Verification queries need a catalog filter.** On MotherDuck, `information_schema.tables` spans every attached database. Without the filter the same query that returns 4 tables locally returns 22, most of them MotherDuck's own:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_catalog = 'dw_build'
  AND table_schema  = 'main'
ORDER BY table_name;
```

## Checks worth running after a build

The flat mart has to stay at one row per posting. This is the check that catches an accidental fan-out:

```sql
SELECT (SELECT COUNT(*) FROM flat_mart.<flat table>)
     = (SELECT COUNT(*) FROM job_postings_fact) AS grain_preserved;
```

Row counts per table, to compare against the numbers at the top of this file:

```sql
SELECT 'company_dim' AS table_name, COUNT(*) AS records FROM company_dim
UNION ALL SELECT 'skill_dim',         COUNT(*) FROM skill_dim
UNION ALL SELECT 'job_postings_fact', COUNT(*) FROM job_postings_fact
UNION ALL SELECT 'skills_job_dim',    COUNT(*) FROM skills_job_dim;
```

## The database file is not in this repo

`dw_build.duckdb` is a build artifact. It is 477 MB, well past GitHub's 100 MB per-file limit, and it is fully reproducible from these scripts — so `.gitignore` excludes `*.duckdb` and `*.duckdb.wal`.

Git LFS would technically store it, but a regenerable file does not belong in version control at all: it would consume quota, slow every clone, and be stale as soon as anyone re-ran the build. Cloning this repo and running `code_build.sql` is also a real test that the scripts work from nothing, which is worth keeping honest.
