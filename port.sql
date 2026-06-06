-- HOSPITAL DATA INSIGHTS: ENCOUNTERS, COST & PATIENT BEHAVIOR

-- OBJECTIVE 1: ENCOUNTERS OVERVIEW

-- a. How many total encounters occurred each year?
SELECT
    YEAR(START) AS year,
    COUNT(*) AS total_encounters
FROM encounters
GROUP BY YEAR(START)
ORDER BY YEAR(START); 

-- b. For each year, what percentage of all encounters belonged to each encounter class
-- (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?
SELECT
    YEAR(START) AS year,
    ENCOUNTERCLASS,
    COUNT(*) * 100.0 / SUM(COUNT(*))
OVER (PARTITION BY YEAR(START)) AS percentage
FROM encounters
GROUP BY YEAR(START), ENCOUNTERCLASS;


-- c. What percentage of encounters were over 24 hours versus under 24 hours?
SELECT
    CASE 
        WHEN TIMESTAMPDIFF(HOUR, START, STOP) > 24  THEN 'Over 24 hrs'  
        ELSE  'Under 24 hrs'
    END AS duration_group,
    COUNT(*) * 100.0 / SUM(COUNT(*))
OVER () AS percentage
FROM encounters
GROUP BY duration_group;


-- OBJECTIVE 2: COST & COVERAGE INSIGHTS

-- a. How many encounters had zero payer coverage, and what percentage of total encounters does this represent?

SELECT
    COUNT(*) AS zero_payer_coverage,
    COUNT(*) * 100 / (SELECT COUNT(*) FROM encounters) AS percentage
    FROM encounters
    WHERE `PAYER_COVERAGE` = 0;

-- b. What are the top 10 most frequent procedures performed and the average base cost for each?

SELECT 
    pr.`DESCRIPTION`,
    COUNT (*) AS frequency,
    AVG(pr.`BASE_COST`) AS avg_cost
FROM procedures as pr
GROUP BY pr.`DESCRIPTION`
ORDER BY frequency DESC
LIMIT 10;

-- c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?

SELECT 
    pr.`DESCRIPTION`,
    COUNT(*) AS times_performed,
    AVG(pr.`BASE_COST`) AS avg_cost
FROM procedures as pr
GROUP BY pr.`DESCRIPTION`
ORDER BY avg_cost DESC
LIMIT 10;

-- d. What is the average total claim cost for encounters, broken down by payer?

SELECT
    py.NAME AS payer_name,
    AVG(e.TOTAL_CLAIM_COST)
avg_claim_cost
FROM encounters e
JOIN payers py ON e.`PAYER` = py.Id
GROUP BY py.`NAME`;


-- OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS

-- a. How many unique patients were admitted each quarter over time?

SELECT
    YEAR(START) AS year,
    QUARTER(START) AS quarter,
    COUNT(DISTINCT `PATIENT`) AS unique_patients
FROM encounters
GROUP BY year, quarter;

-- b. How many patients were readmitted within 30 days of a previous encounter?

SELECT
    COUNT(DISTINCT e1.`PATIENT`) AS readmitted_patient
FROM encounters e1
JOIN encounters e2
    ON e1.`PATIENT` = e2.`PATIENT` AND e2.`START` > e1.`START` 
    AND TIMESTAMPDIFF(DAY, e1.`START`, e2.`START`) <= 30;

-- c. Which patients had the most readmissions?

SELECT
    p.FIRST,
    p.LAST,
    COUNT(*) AS readmission_count
FROM encounters e1
JOIN encounters e2
    ON e1.`PATIENT` = e2.`PATIENT` AND e2.`START` > e1.`START` 
    AND TIMESTAMPDIFF(DAY, e1.`START`, e2.`START`) <= 30
JOIN patients p ON e1.`PATIENT` = p.`Id`
GROUP BY p.`FIRST`, p.`LAST`
ORDER BY readmission_count DESC;






