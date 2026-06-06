-- Connect to database (MySQL only)
USE hospital_db;

-- OBJECTIVE 1: ENCOUNTERS OVERVIEW

-- a. How many total encounters occurred each year?
SELECT
    YEAR(START) AS encounter_year,
    COUNT(*) AS total_encounters
FROM encounters
GROUP BY YEAR(START)
ORDER BY encounter_year;

-- b. For each year, what percentage of all encounters belonged to each encounter class
-- (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?
SELECT
    YEAR(START) AS encounter_year,
    ENCOUNTERCLASS,
    COUNT(*) AS encounter_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY YEAR(START)),
        2
    ) AS percentage_of_year
FROM encounters
GROUP BY YEAR(START), ENCOUNTERCLASS
ORDER BY encounter_year, percentage_of_year DESC;

-- c. What percentage of encounters were over 24 hours versus under 24 hours?
SELECT
    CASE
        WHEN TIMESTAMPDIFF(HOUR, START, STOP) > 24 THEN 'Over 24 hours'
        ELSE 'Under 24 hours'
    END AS duration_group,
    COUNT(*) AS encounter_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM encounters
GROUP BY duration_group
ORDER BY encounter_count DESC;

-- OBJECTIVE 2: COST & COVERAGE INSIGHTS

-- a. How many encounters had zero payer coverage, and what percentage of total encounters does this represent?
SELECT
    COUNT(*) AS zero_payer_coverage_encounters,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM encounters), 2) AS percentage_of_total
FROM encounters
WHERE PAYER_COVERAGE = 0;

-- b. What are the top 10 most frequent procedures performed and the average base cost for each?
SELECT
    DESCRIPTION,
    COUNT(*) AS times_performed,
    ROUND(AVG(BASE_COST), 2) AS average_base_cost
FROM procedures
GROUP BY DESCRIPTION
ORDER BY times_performed DESC, average_base_cost DESC
LIMIT 10;

-- c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?
SELECT
    DESCRIPTION,
    COUNT(*) AS times_performed,
    ROUND(AVG(BASE_COST), 2) AS average_base_cost
FROM procedures
GROUP BY DESCRIPTION
ORDER BY average_base_cost DESC, times_performed DESC
LIMIT 10;

-- d. What is the average total claim cost for encounters, broken down by payer?
SELECT
    p.NAME AS payer_name,
    COUNT(e.Id) AS encounter_count,
    ROUND(AVG(e.TOTAL_CLAIM_COST), 2) AS average_total_claim_cost
FROM encounters e
JOIN payers p
    ON e.PAYER = p.Id
GROUP BY p.NAME
ORDER BY average_total_claim_cost DESC;

-- OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS

-- a. How many unique patients were admitted each quarter over time?
SELECT
    YEAR(START) AS encounter_year,
    QUARTER(START) AS encounter_quarter,
    COUNT(DISTINCT PATIENT) AS unique_patients
FROM encounters
GROUP BY YEAR(START), QUARTER(START)
ORDER BY encounter_year, encounter_quarter;

-- b. How many patients were readmitted within 30 days of a previous encounter?
WITH patient_encounters AS (
    SELECT
        Id,
        PATIENT,
        START,
        LAG(STOP) OVER (PARTITION BY PATIENT ORDER BY START) AS previous_stop
    FROM encounters
)
SELECT
    COUNT(DISTINCT PATIENT) AS readmitted_patients
FROM patient_encounters
WHERE previous_stop IS NOT NULL
  AND TIMESTAMPDIFF(DAY, previous_stop, START) BETWEEN 0 AND 30;

-- c. Which patients had the most readmissions?
WITH patient_encounters AS (
    SELECT
        Id,
        PATIENT,
        START,
        LAG(STOP) OVER (PARTITION BY PATIENT ORDER BY START) AS previous_stop
    FROM encounters
),
readmissions AS (
    SELECT
        PATIENT,
        COUNT(*) AS readmission_count
    FROM patient_encounters
    WHERE previous_stop IS NOT NULL
      AND TIMESTAMPDIFF(DAY, previous_stop, START) BETWEEN 0 AND 30
    GROUP BY PATIENT
)
SELECT
    p.Id AS patient_id,
    p.FIRST,
    p.LAST,
    r.readmission_count
FROM readmissions r
JOIN patients p
    ON r.PATIENT = p.Id
ORDER BY r.readmission_count DESC, p.LAST, p.FIRST
LIMIT 10;
