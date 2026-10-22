-- duckdb dw_build.duckdb -c ".read code_build.sql"

-- 1st
.read 1_create_tables.sql

-- 2nd
.read 2_load_schema.sql

-- 3rd
.read 3_flat_mart.sql