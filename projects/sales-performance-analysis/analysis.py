"""
Sales Performance Analysis
-----------------------------
Cleans raw sales export data and builds the repeatable reporting
workflow described in the portfolio project (originally combining
Excel, SQL, and Tableau over a 50,000-record sales dataset).

This script handles the Python/Pandas side of that workflow: it
cleans the data and produces an Excel workbook (multiple sheets)
that can be dropped straight into Excel or connected to Tableau.

Input : data.csv (sample dataset - 260 sales records)
Output: sales_report.xlsx (Summary, By Region, By Rep, By Month sheets)

Usage:
    pip install pandas openpyxl
    python analysis.py
"""

import pandas as pd

DATA_PATH = "data.csv"
OUTPUT_PATH = "sales_report.xlsx"


def load_and_clean(path: str) -> pd.DataFrame:
    df = pd.read_csv(path, parse_dates=["sale_date"])
    df.columns = [c.strip().lower() for c in df.columns]
    df = df.drop_duplicates(subset=["sale_id"])
    df["sales_rep"] = df["sales_rep"].str.strip()
    df["region"] = df["region"].str.strip().str.title()
    df["revenue"] = df["units_sold"] * df["unit_price"]
    return df


def summary_kpis(df: pd.DataFrame) -> pd.DataFrame:
    return pd.DataFrame([{
        "total_sales": len(df),
        "total_revenue": round(df["revenue"].sum(), 2),
        "avg_sale_value": round(df["revenue"].mean(), 2),
        "active_reps": df["sales_rep"].nunique(),
    }])


def by_region(df: pd.DataFrame) -> pd.DataFrame:
    return df.groupby("region").agg(
        orders=("sale_id", "count"),
        revenue=("revenue", "sum"),
    ).reset_index().sort_values("revenue", ascending=False)


def by_rep(df: pd.DataFrame) -> pd.DataFrame:
    return df.groupby("sales_rep").agg(
        orders=("sale_id", "count"),
        revenue=("revenue", "sum"),
    ).reset_index().sort_values("revenue", ascending=False)


def by_month(df: pd.DataFrame) -> pd.DataFrame:
    monthly = df.set_index("sale_date").resample("M")["revenue"].sum().reset_index()
    monthly["sale_date"] = monthly["sale_date"].dt.strftime("%Y-%m")
    monthly.columns = ["month", "revenue"]
    return monthly


def main():
    df = load_and_clean(DATA_PATH)

    kpis = summary_kpis(df)
    print("=== Sales Performance Analysis: KPIs ===")
    print(kpis.to_string(index=False))

    with pd.ExcelWriter(OUTPUT_PATH, engine="openpyxl") as writer:
        kpis.to_excel(writer, sheet_name="Summary", index=False)
        by_region(df).to_excel(writer, sheet_name="By Region", index=False)
        by_rep(df).to_excel(writer, sheet_name="By Rep", index=False)
        by_month(df).to_excel(writer, sheet_name="By Month", index=False)

    print(f"\nReport workbook written to {OUTPUT_PATH}")
    print("Import this file into Tableau/Power BI, or open directly in Excel.")


if __name__ == "__main__":
    main()
