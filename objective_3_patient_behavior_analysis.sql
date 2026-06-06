USE hospital_db;

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
