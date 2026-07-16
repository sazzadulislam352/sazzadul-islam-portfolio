"""
Automated Employee Reporting System
-------------------------------------
Cleans and standardizes raw employee performance exports, then
generates the recurring monthly report automatically instead of
building it by hand each cycle.

Input : data.csv (sample dataset - 200 rows / 50 employees x 4 months)
Output: monthly_report.csv, department_summary.csv, console KPIs

Usage:
    pip install pandas
    python analysis.py
"""

import pandas as pd

DATA_PATH = "data.csv"


def load_and_clean(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    df.columns = [c.strip().lower() for c in df.columns]

    # Standardize text fields (this is the "standardization" step
    # referenced in the project summary)
    df["employee_name"] = df["employee_name"].str.strip().str.title()
    df["department"] = df["department"].str.strip().str.title()

    # Basic sanity cleaning
    df = df.drop_duplicates(subset=["employee_id", "month"])
    df = df.dropna(subset=["employee_id", "month", "performance_score"])

    numeric_cols = ["sales_target", "sales_achieved", "attendance_rate", "performance_score", "review_rating"]
    for col in numeric_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce")
    df = df.dropna(subset=numeric_cols)

    df["target_attainment_pct"] = (df["sales_achieved"] / df["sales_target"] * 100).round(1)
    return df


def build_monthly_report(df: pd.DataFrame) -> pd.DataFrame:
    report = df.groupby(["department", "month"]).agg(
        employees=("employee_id", "nunique"),
        avg_performance_score=("performance_score", "mean"),
        avg_attendance_rate=("attendance_rate", "mean"),
        total_sales_achieved=("sales_achieved", "sum"),
        total_sales_target=("sales_target", "sum"),
    ).reset_index()
    report["avg_performance_score"] = report["avg_performance_score"].round(2)
    report["avg_attendance_rate"] = report["avg_attendance_rate"].round(2)
    return report


def build_department_summary(df: pd.DataFrame) -> pd.DataFrame:
    summary = df.groupby("department").agg(
        employees=("employee_id", "nunique"),
        avg_performance_score=("performance_score", "mean"),
        avg_review_rating=("review_rating", "mean"),
    ).reset_index().sort_values("avg_performance_score", ascending=False)
    summary["avg_performance_score"] = summary["avg_performance_score"].round(2)
    summary["avg_review_rating"] = summary["avg_review_rating"].round(2)
    return summary


def compute_kpis(df: pd.DataFrame) -> dict:
    return {
        "total_employees": int(df["employee_id"].nunique()),
        "avg_performance_score": round(df["performance_score"].mean(), 2),
        "avg_attendance_rate": round(df["attendance_rate"].mean(), 2),
        "avg_target_attainment_pct": round(df["target_attainment_pct"].mean(), 1),
    }


def main():
    df = load_and_clean(DATA_PATH)

    kpis = compute_kpis(df)
    print("=== Automated Employee Reporting: KPIs ===")
    for k, v in kpis.items():
        print(f"{k}: {v}")

    monthly_report = build_monthly_report(df)
    monthly_report.to_csv("monthly_report.csv", index=False)

    dept_summary = build_department_summary(df)
    dept_summary.to_csv("department_summary.csv", index=False)

    print("\nWrote monthly_report.csv and department_summary.csv")
    print("\nTop departments by avg performance score:")
    print(dept_summary.to_string(index=False))


if __name__ == "__main__":
    main()
