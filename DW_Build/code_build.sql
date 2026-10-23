-- duckdb dw_build.duckdb -c ".read code_build.sql"

-- 1st
.read 1_create_tables.sql

-- 2nd
.read 2_load_schema.sql

-- 3rd
.read 3_flat_mart.sql

-- 4th
.read 4_create_skill.sql

-- 5th
.read 5_create_priority.sql

-- 6th
.read 6_update_priority.sql