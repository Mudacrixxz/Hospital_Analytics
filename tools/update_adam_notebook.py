import json
from pathlib import Path


NOTEBOOK = Path(r"C:\Users\B-Tech\Desktop\PY\Adam.ipynb")
BACKUP = NOTEBOOK.with_name("Adam_backup_before_cleaning.ipynb")


def code_cell(source):
    return {
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": source.splitlines(keepends=True),
    }


def markdown_cell(source):
    return {
        "cell_type": "markdown",
        "metadata": {},
        "source": source.splitlines(keepends=True),
    }


cells = [
    markdown_cell(
        """# CIPTMP Data Cleaning

## Explanation: Notebook Purpose
This notebook cleans the `DHA` and `AKTH` sheets from `Datasets/CIPTMP original.xlsx`.
It standardizes column names and category values, converts numeric/date fields, flags outliers,
and exports cleaned CSV/Excel files for analysis.

The next code cell prepares the notebook by importing the needed libraries, setting display options,
and defining where the raw and cleaned files are located."""
    ),
    code_cell(
        """from pathlib import Path
import re
import warnings

import numpy as np
import pandas as pd

pd.set_option("display.max_columns", 120)
pd.set_option("display.max_rows", 120)
pd.set_option("display.float_format", "{:.2f}".format)

BASE_DIR = Path.cwd()
DATA_DIR = BASE_DIR / "Datasets"
INPUT_FILE = DATA_DIR / "CIPTMP original.xlsx"
OUTPUT_DIR = DATA_DIR / "cleaned"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

INPUT_FILE"""
    ),
    markdown_cell(
        """## Explanation: Load Raw Sheets
The next code cell reads the original Excel workbook into pandas. It loads the two main sheets,
`DHA` and `AKTH`, because these are the sheets that contain the patient records used for cleaning.

The cell also prints the number of rows and columns in each sheet. Any Excel warning is captured and
displayed so problems in the original file, such as invalid date values, can be seen before cleaning."""
    ),
    code_cell(
        """with warnings.catch_warnings(record=True) as caught_warnings:
    warnings.simplefilter("always")
    raw_sheets = pd.read_excel(INPUT_FILE, sheet_name=["DHA", "AKTH "])

raw_dha = raw_sheets["DHA"].copy()
raw_akth = raw_sheets["AKTH "].copy()

print("DHA shape:", raw_dha.shape)
print("AKTH shape:", raw_akth.shape)
print("\\nExcel warnings:")
for warning in caught_warnings:
    print("-", warning.message)"""
    ),
    markdown_cell(
        """## Explanation: Cleaning Rules and Main Cleaning Process
The next code cell contains the main cleaning work. It first defines rules for renaming messy column
names, such as changing `Occoption` and `Occuption` to `Occupation`, and correcting spelling errors
like `Maleria` to `Malaria`.

It then lists the columns that should be treated as numbers and dates, standardizes text categories,
fixes Yes/No values, validates phone numbers, and handles outliers. For example, height values written
as centimeters are converted to meters, and unreasonable blood pressure, weight, pulse, and date values
are flagged.

At the end of the cell, the cleaned `DHA` and `AKTH` sheets are combined into one dataset called
`combined`, while keeping a `Source sheet` column to show where each record came from."""
    ),
    code_cell(
        """COLUMN_RENAMES = {
    "Occoption": "Occupation",
    "Occuption": "Occupation",
    "Any history of Maleria in Previous PG": "History of Malaria in Previous PG",
    "History of Maleria in Previous PG": "History of Malaria in Previous PG",
    "Facility you received ANC ": "Facility you received ANC",
    "At what age did you receive the doses of IPTp ": "At what age did you receive the doses of IPTp",
    "Treatment receive": "Treatment received",
    "Placental Maleria ": "Placental Malaria",
    "Placental Maleria": "Placental Malaria",
    "Mode of delivry": "Mode of delivery",
    "Gestational age at delivey": "Gestational age at delivery",
    "Persistend headache": "Persistent headache",
    "Vomitting or nausea": "Vomiting or nausea",
    "Gst age at enroll": "Gestational age at enroll",
    "Level of Edc": "Level of Education",
    "Thumb print consent sign": "Thumbprint consent sign",
}

NUMERIC_COLUMNS = [
    "S/N",
    "File No",
    "Age",
    "Monthly Income",
    "Gravidity",
    "Parity",
    "Sys",
    "Dis",
    "PR",
    "Weight",
    "Ht",
    "Gestational age at enroll",
    "No of ANC visits during PG",
    "If yes No of episodes",
    "How many days did the fever last",
    "How many days did the anemia last",
    "Gestational age at delivery",
    "Birth weight",
    "APGAR 1",
    "APGAR 2",
    "Maternal Hemoglobin at delivery",
]

DATE_COLUMNS = ["Date of Enroll", "Next visit"]

CATEGORY_REPLACEMENTS = {
    "Level of Education": {
        "Tartiary": "Tertiary",
        "Tertiary": "Tertiary",
        "Secondary": "Secondary",
        "Primary": "Primary",
        "Quranic": "Quranic",
    },
    "Religion": {
        "Islam": "Muslim",
        "Muslim": "Muslim",
        "Christianity": "Christian",
        "Christian": "Christian",
    },
    "Residence": {
        "urban": "Urban",
        "Urban": "Urban",
        "Rural": "Rural",
    },
    "Ethnicity": {
        "kanuri": "Kanuri",
        "katab": "Katab",
        "babur": "Babur",
        "IGBO": "Igbo",
        "igbo": "Igbo",
        "NUPE": "Nupe",
        "IGALA": "Igala",
    },
    "Occupation": {
        "House wife": "Housewife",
        "Civil service": "Civil servant",
        "civil servant": "Civil servant",
        "NURSE": "Nurse",
        "civ": "Civil servant",
        "Coper": "Corper",
        "Serving NYSC": "Corper",
        "Sectory": "Secretary",
        "working": "Working",
    },
    "Facility you received ANC": {
        "General Hosp": "General Hospital",
        "General hosp": "General Hospital",
        "PHC": "PHC",
        "phc": "PHC",
    },
    "where did you obtain the ITN": {
        "Purchase": "Purchased",
        "Free gov distribution": "Free government distribution",
        "NOT USING": "Not using",
    },
    "How often do you sleep under ITN": {
        "Everynight": "Every night",
        "Most night": "Most nights",
        "Occationally": "Occasionally",
        "Rarely": "Rarely or never",
    },
    "If you do not sleep under an ITN regularly, What is the reason": {
        "Too hot": "Too Hot",
        "hot": "Too Hot",
        "Don’t like it": "Dislike",
        "S": pd.NA,
    },
    "Any other Maleria preventive measures used": {
        "Indoor spraying": "Indoor Spraying",
        "indoor spry": "Indoor Spraying",
    },
    "How satisfied were you with the IPTp drug you received": {
        "Very satisfid": "Very satisfied",
        "VERY satisfied": "Very satisfied",
        "SATISFIED": "Satisfied",
        "satisfied": "Satisfied",
        "NEUTRAL": "Neutral",
    },
    "Thumbprint consent sign": {
        "SING": "Sign",
        "sing": "Sign",
    },
}

YES_NO_COLUMNS = [
    "History of Malaria in Previous PG",
    "History of adverse Pg outcome",
    "Known chronic illness",
    "Do you have info on Maleria in PG During ANC",
    "Was the drug administered under direct observation",
    "Did you experience any side after taking IPTp",
    "Do you own an ITN Net",
    "Did you learn anything about using ITNs during this PG",
    "Has the net been re-treated with insecticide in the past 6 month",
    "Have you had Maleria during this PG",
    "Fever in the past 7 days",
    "Clinical signs of anemia",
    "Presence of jaundice (yellow eyes or skin)",
    "History of convulsions or seizures",
    "Persistent headache",
    "Vomiting or nausea",
]

YES_NO_REPLACEMENTS = {
    "YES": "Yes",
    "yes": "Yes",
    "Yes": "Yes",
    "NO": "No",
    "no": "No",
    "No": "No",
    "N": "No",
}


def normalize_column_name(col):
    col = str(col).strip()
    col = re.sub(r"\\s+", " ", col)
    return COLUMN_RENAMES.get(col, col)


def clean_text_values(df):
    text_cols = df.select_dtypes(include="object").columns
    for col in text_cols:
        df[col] = (
            df[col]
            .astype("string")
            .str.strip()
            .replace({"": pd.NA, "nan": pd.NA, "NaN": pd.NA, "None": pd.NA})
        )
    return df


def apply_category_replacements(df):
    for col, replacements in CATEGORY_REPLACEMENTS.items():
        if col in df.columns:
            df[col] = df[col].replace(replacements)
    for col in YES_NO_COLUMNS:
        if col in df.columns:
            df[col] = df[col].replace(YES_NO_REPLACEMENTS)
    return df


def clean_phone_number(value):
    if pd.isna(value):
        return pd.NA
    if isinstance(value, float) and value.is_integer():
        value = int(value)
    digits = re.sub(r"\\D", "", str(value))
    if digits.endswith("0") and len(digits) > 11 and "." in str(value):
        digits = digits[:-1]
    if len(digits) == 10 and digits[0] in "789":
        digits = "0" + digits
    if len(digits) == 13 and digits.startswith("234"):
        digits = "0" + digits[3:]
    return digits if digits else pd.NA


def combine_duplicate_columns(df):
    duplicated = df.columns[df.columns.duplicated()].unique()
    for col in duplicated:
        same_name = df.loc[:, df.columns == col]
        combined = same_name.bfill(axis=1).iloc[:, 0]
        df = df.drop(columns=col)
        df[col] = combined
    return df


def clean_sheet(df, source_sheet):
    df = df.copy()
    df["Source sheet"] = source_sheet.strip()
    df = df.drop(columns=[c for c in df.columns if str(c).startswith("Unnamed:")], errors="ignore")
    df.columns = [normalize_column_name(c) for c in df.columns]
    df = combine_duplicate_columns(df)

    if "Phone No" in df.columns:
        df["Phone No raw"] = df["Phone No"]
        df["Phone No"] = df["Phone No"].apply(clean_phone_number)
        df["Phone No invalid flag"] = df["Phone No"].notna() & ~df["Phone No"].str.match(r"^0\\d{10}$", na=False)

    df = clean_text_values(df)
    df = apply_category_replacements(df)

    for col in DATE_COLUMNS:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], errors="coerce")

    for col in NUMERIC_COLUMNS:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    if "Sys" in df.columns:
        df["Sys outlier flag"] = df["Sys"].where(df["Sys"].between(70, 250) | df["Sys"].isna()).isna() & df["Sys"].notna()
        df.loc[~df["Sys"].between(70, 250), "Sys"] = np.nan

    if "Dis" in df.columns:
        df["Dis outlier flag"] = df["Dis"].where(df["Dis"].between(30, 160) | df["Dis"].isna()).isna() & df["Dis"].notna()
        df.loc[~df["Dis"].between(30, 160), "Dis"] = np.nan

    if "Age" in df.columns:
        df["Age outlier flag"] = df["Age"].where(df["Age"].between(10, 60) | df["Age"].isna()).isna() & df["Age"].notna()
        df.loc[~df["Age"].between(10, 60), "Age"] = np.nan

    if "Ht" in df.columns:
        df["Ht original"] = df["Ht"]
        df.loc[df["Ht"].between(100, 250), "Ht"] = df.loc[df["Ht"].between(100, 250), "Ht"] / 100
        df["Ht outlier flag"] = df["Ht"].notna() & ~df["Ht"].between(1.2, 2.1)
        df.loc[~df["Ht"].between(1.2, 2.1), "Ht"] = np.nan

    if "Weight" in df.columns:
        df["Weight outlier flag"] = df["Weight"].notna() & ~df["Weight"].between(35, 180)
        df.loc[~df["Weight"].between(35, 180), "Weight"] = np.nan

    if "PR" in df.columns:
        df["PR outlier flag"] = df["PR"].notna() & ~df["PR"].between(40, 140)
        df.loc[~df["PR"].between(40, 140), "PR"] = np.nan

    if "Monthly Income" in df.columns:
        df["Monthly Income high flag"] = df["Monthly Income"] > 500000

    if "Date of Enroll" in df.columns:
        df["Date of Enroll outlier flag"] = df["Date of Enroll"].notna() & ~df["Date of Enroll"].between("2025-01-01", "2026-12-31")
        df.loc[df["Date of Enroll outlier flag"], "Date of Enroll"] = pd.NaT

    return df


clean_dha = clean_sheet(raw_dha, "DHA")
clean_akth = clean_sheet(raw_akth, "AKTH")
combined = pd.concat([clean_dha, clean_akth], ignore_index=True, sort=False)
empty_columns = combined.columns[combined.isna().all()].tolist()
clean_dha = clean_dha.drop(columns=[c for c in empty_columns if c in clean_dha.columns])
clean_akth = clean_akth.drop(columns=[c for c in empty_columns if c in clean_akth.columns])
combined = combined.drop(columns=empty_columns)

print("Clean DHA:", clean_dha.shape)
print("Clean AKTH:", clean_akth.shape)
print("Combined:", combined.shape)"""
    ),
    markdown_cell(
        """## Explanation: Cleaning Checks
The next code cell checks the result of the cleaning process. It creates a missing-value report,
checks for duplicate rows, and displays the counts of important category columns.

This step is important because it helps confirm that the cleaning rules worked and also shows which
columns still have many missing values."""
    ),
    code_cell(
        """def missing_report(df):
    report = (
        df.isna()
        .sum()
        .rename("missing_count")
        .to_frame()
        .assign(missing_percent=lambda x: (x["missing_count"] / len(df) * 100).round(2))
        .sort_values("missing_count", ascending=False)
    )
    return report


print("Duplicate rows in combined data:", combined.duplicated().sum())
display(missing_report(combined).head(30))

for col in ["Level of Education", "Religion", "Residence", "Ethnicity", "Occupation", "IPTP regimen received"]:
    if col in combined.columns:
        print(f"\\n{col}")
        display(combined[col].value_counts(dropna=False).head(20))"""
    ),
    markdown_cell(
        """## Explanation: Numeric Summary After Cleaning
The next code cell calculates summary statistics for all useful numeric columns. The statistics include
the count, minimum, maximum, mean, and median.

This is where values such as maximum age are checked. If a value ever appears in scientific notation,
for example `4.500000e+01`, it still means 45. The notebook display setting now makes these numbers
show in normal decimal format, such as `45.00`."""
    ),
    code_cell(
        """summary_cols = [
    col
    for col in NUMERIC_COLUMNS
    if col in combined.columns and combined[col].notna().any()
]

numeric_summary = combined[summary_cols].agg(["count", "min", "max", "mean", "median"]).T
numeric_summary["mean"] = numeric_summary["mean"].round(2)
display(numeric_summary)"""
    ),
    markdown_cell(
        """## Explanation: Export Cleaned Files
The next code cell saves the cleaned data. It exports separate cleaned CSV files for `DHA` and `AKTH`,
a combined cleaned CSV file, and one Excel workbook containing the cleaned sheets and summary reports.

This makes the cleaned data ready for analysis outside the notebook."""
    ),
    code_cell(
        """clean_dha.to_csv(OUTPUT_DIR / "dha_cleaned.csv", index=False)
clean_akth.to_csv(OUTPUT_DIR / "akth_cleaned.csv", index=False)
combined.to_csv(OUTPUT_DIR / "cipt_cleaned_combined.csv", index=False)

with pd.ExcelWriter(OUTPUT_DIR / "cipt_cleaned.xlsx", engine="openpyxl") as writer:
    clean_dha.to_excel(writer, sheet_name="DHA_cleaned", index=False)
    clean_akth.to_excel(writer, sheet_name="AKTH_cleaned", index=False)
    combined.to_excel(writer, sheet_name="Combined_cleaned", index=False)
    missing_report(combined).to_excel(writer, sheet_name="Missing_report")
    numeric_summary.to_excel(writer, sheet_name="Numeric_summary")

print("Saved cleaned files to:", OUTPUT_DIR)"""
    ),
]


def main():
    notebook = json.loads(NOTEBOOK.read_text(encoding="utf-8"))
    if not BACKUP.exists():
        BACKUP.write_text(json.dumps(notebook, indent=1), encoding="utf-8")

    notebook["cells"] = cells
    notebook.setdefault("metadata", {})
    notebook["metadata"].setdefault(
        "kernelspec",
        {"display_name": "Muda (3.13.6)", "language": "python", "name": "python3"},
    )
    notebook["metadata"].setdefault(
        "language_info",
        {"name": "python", "version": "3.13.6", "mimetype": "text/x-python", "file_extension": ".py"},
    )
    NOTEBOOK.write_text(json.dumps(notebook, indent=1), encoding="utf-8")
    print(f"Updated {NOTEBOOK}")
    print(f"Backup: {BACKUP}")


if __name__ == "__main__":
    main()
