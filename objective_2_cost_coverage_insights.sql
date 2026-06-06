USE hospital_db;

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
