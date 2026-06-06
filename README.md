# Hospital Patient Records Analytics

This project analyzes synthetic hospital patient records using SQL. The analysis focuses on encounter trends, cost and payer coverage, and patient readmission behavior.

## Project Overview

The dataset contains hospital records for patients, encounters, procedures, payers, and hospital organization information. The SQL analysis answers business and clinical questions such as:

- How encounter volume changes over time
- Which encounter classes are most common each year
- How many encounters last over 24 hours
- How often payer coverage is zero
- Which procedures are most frequent or most expensive
- Which payers have the highest average claim costs
- How patient visits and readmissions change over time

## Dataset Files

The main CSV files are stored in the `CSV` folder:

- `patients.csv`: patient demographic records
- `encounters.csv`: hospital encounter records
- `procedures.csv`: procedure records linked to patients and encounters
- `payers.csv`: insurance payer records
- `organizations.csv`: hospital organization record
- `data_dictionary.csv`: column descriptions for the dataset

## SQL Analysis Files

The analysis is separated by objective:

- `objective_1_encounters_overview.sql`: encounter volume, encounter class percentages, and encounter duration groups
- `objective_2_cost_coverage_insights.sql`: payer coverage, procedure frequency, procedure costs, and average claim cost by payer
- `objective_3_patient_behavior_analysis.sql`: quarterly patient activity and readmission analysis

The combined analysis file is:

- `hospital_analytics_questions.sql`

The data cleaning file is:

- `data_cleaning_all_tables.sql`: creates cleaned analysis views for patients, payers, encounters, and procedures while keeping the original tables unchanged

The original full database script is:

- `create_hospital_db.sql`

## Analysis Objectives

### Objective 1: Encounters Overview

This section measures hospital activity over time by counting yearly encounters, calculating encounter class percentages, and comparing encounters over 24 hours versus under 24 hours.

### Objective 2: Cost and Coverage Insights

This section explores financial patterns by identifying zero payer coverage encounters, common procedures, expensive procedures, and average claim costs by payer.

### Objective 3: Patient Behavior Analysis

This section studies patient activity by counting unique patients per quarter and identifying patients readmitted within 30 days of a previous encounter.
