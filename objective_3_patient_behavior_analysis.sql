USE hospital_db;

-- OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS

-- a. How many unique patients were admitted each quarter over time?
SELECT
    YEAR(START) AS encounter_year,
    QUARTER(START) AS encounter_quarter,
    COUNT(DISTINCT patient_id) AS unique_patients
FROM clean_encounters
GROUP BY YEAR(START), QUARTER(START)
ORDER BY encounter_year, encounter_quarter;

-- b. How many patients were readmitted within 30 days of a previous encounter?
WITH patient_encounters AS (
    SELECT
        Id,
        patient_id,
        START,
        LAG(STOP) OVER (PARTITION BY patient_id ORDER BY START) AS previous_stop
    FROM clean_encounters
)
SELECT
    COUNT(DISTINCT patient_id) AS readmitted_patients
FROM patient_encounters
WHERE previous_stop IS NOT NULL
  AND TIMESTAMPDIFF(DAY, previous_stop, START) BETWEEN 0 AND 30;

-- c. Which patients had the most readmissions?
WITH patient_encounters AS (
    SELECT
        Id,
        patient_id,
        START,
        LAG(STOP) OVER (PARTITION BY patient_id ORDER BY START) AS previous_stop
    FROM clean_encounters
),
readmissions AS (
    SELECT
        patient_id,
        COUNT(*) AS readmission_count
    FROM patient_encounters
    WHERE previous_stop IS NOT NULL
      AND TIMESTAMPDIFF(DAY, previous_stop, START) BETWEEN 0 AND 30
    GROUP BY patient_id
)
SELECT
    p.Id AS patient_id,
    p.first_name,
    p.last_name,
    r.readmission_count
FROM readmissions r
JOIN clean_patients p
    ON r.patient_id = p.Id
ORDER BY r.readmission_count DESC, p.last_name, p.first_name
LIMIT 10;
