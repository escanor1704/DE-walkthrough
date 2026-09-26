select distinct
job_title_short
from job_postings_fact;

-- print column names
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'job_postings_fact'
ORDER BY ordinal_position;