USE hospital_db;

-- OBJECTIVE 2: COST & COVERAGE INSIGHTS

-- a. How many encounters had zero payer coverage, and what percentage of total encounters does this represent?
SELECT
    COUNT(*) AS zero_payer_coverage_encounters,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clean_encounters), 2) AS percentage_of_total
FROM clean_encounters
WHERE PAYER_COVERAGE = 0;

-- b. What are the top 10 most frequent procedures performed and the average base cost for each?
SELECT
    procedure_description,
    COUNT(*) AS times_performed,
    ROUND(AVG(BASE_COST), 2) AS average_base_cost
FROM clean_procedures
GROUP BY procedure_description
ORDER BY times_performed DESC, average_base_cost DESC
LIMIT 10;

-- c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?
SELECT
    procedure_description,
    COUNT(*) AS times_performed,
    ROUND(AVG(BASE_COST), 2) AS average_base_cost
FROM clean_procedures
GROUP BY procedure_description
ORDER BY average_base_cost DESC, times_performed DESC
LIMIT 10;

-- d. What is the average total claim cost for encounters, broken down by payer?
SELECT
    p.payer_name,
    COUNT(e.Id) AS encounter_count,
    ROUND(AVG(e.TOTAL_CLAIM_COST), 2) AS average_total_claim_cost
FROM clean_encounters e
JOIN clean_payers p
    ON e.payer_id = p.Id
GROUP BY p.payer_name
ORDER BY average_total_claim_cost DESC;
