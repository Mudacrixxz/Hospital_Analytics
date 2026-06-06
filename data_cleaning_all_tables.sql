USE hospital_db;

-- DATA CLEANING FOR ANALYSIS
-- This script prepares the hospital dataset for analysis without changing the raw source tables.
-- Instead of updating or deleting rows from patients, payers, encounters, or procedures, it creates
-- clean views. A view works like a saved SELECT query, so the original imported data remains available
-- for checking, auditing, or rebuilding the analysis.
--
-- Main cleaning decisions used in this file:
-- 1. TRIM() removes extra spaces from text fields.
-- 2. NULLIF(value, '') changes blank text values into real NULL values.
-- 3. LOWER() and UPPER() standardize category values like race, ethnicity, gender, and encounter class.
-- 4. REPLACE() removes double spaces found in birthplace text.
-- 5. Invalid event rows where STOP is before START are excluded from clean event views.
-- 6. Derived analysis fields are added, such as age, encounter_hours, duration_group, and payer_coverage_group.
-- 7. Data quality checks at the end help identify missing IDs, invalid dates, and broken table relationships.

-- Clean payer records
-- Purpose:
-- The payer table stores insurance company or payment source information.
-- For analysis, payer names and location fields should not contain accidental leading/trailing spaces.
-- Blank address, city, state, ZIP, or phone values are converted to NULL so missing data is easier to count.
CREATE OR REPLACE VIEW clean_payers AS
SELECT
    Id,
    NULLIF(TRIM(NAME), '') AS payer_name,
    NULLIF(TRIM(ADDRESS), '') AS address,
    NULLIF(TRIM(CITY), '') AS city,
    NULLIF(TRIM(STATE_HEADQUARTERED), '') AS state_headquartered,
    NULLIF(TRIM(ZIP), '') AS zip,
    NULLIF(TRIM(PHONE), '') AS phone
FROM payers;

-- Clean patient demographic records
-- Purpose:
-- The patient table contains demographic information used for grouping and patient-level analysis.
-- Text fields are trimmed, empty strings are converted to NULL, and category values are standardized.
-- Race and ethnicity are made lowercase so values like 'White' and 'white' would group together.
-- Gender is made uppercase so values like 'm' and 'M' would group together.
-- Birthplace has double spaces reduced because the source data contains location strings with extra spacing.
-- The age field is calculated from BIRTHDATE to DEATHDATE if the patient died, otherwise to the current date.
-- This calculated age is useful for later analysis, but it does not change the original BIRTHDATE or DEATHDATE.
CREATE OR REPLACE VIEW clean_patients AS
SELECT
    Id,
    BIRTHDATE,
    DEATHDATE,
    NULLIF(TRIM(PREFIX), '') AS prefix,
    NULLIF(TRIM(FIRST), '') AS first_name,
    NULLIF(TRIM(LAST), '') AS last_name,
    NULLIF(TRIM(SUFFIX), '') AS suffix,
    NULLIF(TRIM(MAIDEN), '') AS maiden_name,
    NULLIF(TRIM(MARITAL), '') AS marital_status,
    LOWER(NULLIF(TRIM(RACE), '')) AS race,
    LOWER(NULLIF(TRIM(ETHNICITY), '')) AS ethnicity,
    UPPER(NULLIF(TRIM(GENDER), '')) AS gender,
    REPLACE(NULLIF(TRIM(BIRTHPLACE), ''), '  ', ' ') AS birthplace,
    NULLIF(TRIM(ADDRESS), '') AS address,
    NULLIF(TRIM(CITY), '') AS city,
    NULLIF(TRIM(STATE), '') AS state,
    NULLIF(TRIM(COUNTY), '') AS county,
    NULLIF(TRIM(ZIP), '') AS zip,
    LAT,
    LON,
    TIMESTAMPDIFF(YEAR, BIRTHDATE, COALESCE(DEATHDATE, CURDATE())) AS age
FROM patients;

-- Clean encounter records
-- Purpose:
-- The encounter table is the main activity table for hospital visits.
-- It links patients to payers and contains visit dates, encounter class, cost, claim amount, and payer coverage.
-- Column aliases such as patient_id, payer_id, and encounter_class make the analysis queries easier to read.
-- Encounter class is made lowercase so categories group consistently.
-- Blank reason codes and descriptions are converted to NULL because not every encounter has a reason code.
-- The view excludes encounters where START or STOP is missing, or where STOP is earlier than START.
-- Those rows would make duration calculations incorrect.
-- The encounter_hours field calculates the length of each encounter.
-- duration_group classifies encounters as over or under 24 hours.
-- payer_coverage_group labels whether the encounter had zero payer coverage or some payer coverage.
CREATE OR REPLACE VIEW clean_encounters AS
SELECT
    Id,
    START,
    STOP,
    PATIENT AS patient_id,
    ORGANIZATION AS organization_id,
    PAYER AS payer_id,
    LOWER(NULLIF(TRIM(ENCOUNTERCLASS), '')) AS encounter_class,
    NULLIF(TRIM(CODE), '') AS encounter_code,
    NULLIF(TRIM(DESCRIPTION), '') AS encounter_description,
    BASE_ENCOUNTER_COST,
    TOTAL_CLAIM_COST,
    PAYER_COVERAGE,
    NULLIF(TRIM(REASONCODE), '') AS reason_code,
    NULLIF(TRIM(REASONDESCRIPTION), '') AS reason_description,
    TIMESTAMPDIFF(HOUR, START, STOP) AS encounter_hours,
    CASE
        WHEN TIMESTAMPDIFF(HOUR, START, STOP) > 24 THEN 'Over 24 hours'
        ELSE 'Under 24 hours'
    END AS duration_group,
    CASE
        WHEN PAYER_COVERAGE = 0 THEN 'Zero coverage'
        ELSE 'Has coverage'
    END AS payer_coverage_group
FROM encounters
WHERE START IS NOT NULL
  AND STOP IS NOT NULL
  AND STOP >= START;

-- Clean procedure records
-- Purpose:
-- The procedure table stores procedures performed during patient encounters.
-- It links each procedure back to a patient and an encounter.
-- Procedure codes, descriptions, and reason fields are trimmed and blank values are converted to NULL.
-- The view excludes procedures where START or STOP is missing, or where STOP is earlier than START.
-- Those rows would make procedure duration analysis unreliable.
-- procedure_minutes calculates the length of each procedure in minutes.
CREATE OR REPLACE VIEW clean_procedures AS
SELECT
    START,
    STOP,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    NULLIF(TRIM(CODE), '') AS procedure_code,
    NULLIF(TRIM(DESCRIPTION), '') AS procedure_description,
    BASE_COST,
    NULLIF(TRIM(REASONCODE), '') AS reason_code,
    NULLIF(TRIM(REASONDESCRIPTION), '') AS reason_description,
    TIMESTAMPDIFF(MINUTE, START, STOP) AS procedure_minutes
FROM procedures
WHERE START IS NOT NULL
  AND STOP IS NOT NULL
  AND STOP >= START;

-- Data quality checks
-- Purpose:
-- These checks do not clean the data directly. They summarize possible issues so the analyst can understand
-- the condition of the dataset before interpreting results.
--
-- The first check compares total rows to distinct IDs for tables that have an ID field.
-- If total_rows is greater than unique_ids, the table may contain duplicate IDs.
SELECT 'patients' AS table_name, COUNT(*) AS total_rows, COUNT(DISTINCT Id) AS unique_ids
FROM patients
UNION ALL
SELECT 'payers', COUNT(*), COUNT(DISTINCT Id)
FROM payers
UNION ALL
SELECT 'encounters', COUNT(*), COUNT(DISTINCT Id)
FROM encounters;

-- The second check counts common data quality problems:
-- patients_missing_required_values: patients missing important identity or birth fields.
-- encounters_invalid_dates: encounters with missing dates or STOP before START.
-- procedures_invalid_dates: procedures with missing dates or STOP before START.
-- encounters_missing_patient: encounters linked to patient IDs not found in patients.
-- procedures_missing_patient: procedures linked to patient IDs not found in patients.
-- procedures_missing_encounter: procedures linked to encounter IDs not found in encounters.
SELECT
    'patients_missing_required_values' AS check_name,
    COUNT(*) AS issue_count
FROM patients
WHERE Id IS NULL
   OR BIRTHDATE IS NULL
   OR FIRST IS NULL
   OR LAST IS NULL
UNION ALL
SELECT
    'encounters_invalid_dates',
    COUNT(*)
FROM encounters
WHERE START IS NULL
   OR STOP IS NULL
   OR STOP < START
UNION ALL
SELECT
    'procedures_invalid_dates',
    COUNT(*)
FROM procedures
WHERE START IS NULL
   OR STOP IS NULL
   OR STOP < START
UNION ALL
SELECT
    'encounters_missing_patient',
    COUNT(*)
FROM encounters e
LEFT JOIN patients p
    ON e.PATIENT = p.Id
WHERE p.Id IS NULL
UNION ALL
SELECT
    'procedures_missing_patient',
    COUNT(*)
FROM procedures pr
LEFT JOIN patients p
    ON pr.PATIENT = p.Id
WHERE p.Id IS NULL
UNION ALL
SELECT
    'procedures_missing_encounter',
    COUNT(*)
FROM procedures pr
LEFT JOIN encounters e
    ON pr.ENCOUNTER = e.Id
WHERE e.Id IS NULL;
