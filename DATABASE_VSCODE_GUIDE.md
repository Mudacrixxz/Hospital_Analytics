# Hospital Database Setup in VS Code

This folder already has the data needed for a hospital database:

- `patients.csv`: 974 patient records
- `organizations.csv`: 1 hospital record
- `payers.csv`: 10 insurance payer records
- `encounters.csv`: 27,891 encounter records
- `procedures.csv`: 47,701 procedure records

The original `create_hospital_db.sql` file is a large MySQL script with data inserts, but it is missing the `organizations` table. The cleaner setup file is:

```text
database_schema_mysql.sql
```

## Manual VS Code Method

1. Install a VS Code database extension.
   Good choices are **SQLTools** plus the **SQLTools MySQL/MariaDB driver**, or the official **MySQL Shell for VS Code** extension.

2. Create/connect to your MySQL server from VS Code.

3. Open `database_schema_mysql.sql`.

4. Run the whole file.
   This creates the `hospital_db` database and the five tables.

5. Import the CSV files in this order:

```text
organizations.csv
payers.csv
patients.csv
encounters.csv
procedures.csv
```

Use that order because `encounters` depends on patients, organizations, and payers. `procedures` depends on patients and encounters.

6. After importing, open `hospital_analytics_questions.sql`.
   That file contains the analysis questions you can answer with SQL queries.

## Recommended Table Design

```text
organizations
payers
patients
encounters
procedures
```

Important relationships:

```text
encounters.PATIENT      -> patients.Id
encounters.ORGANIZATION -> organizations.Id
encounters.PAYER        -> payers.Id
procedures.PATIENT      -> patients.Id
procedures.ENCOUNTER    -> encounters.Id
```

