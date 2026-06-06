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
