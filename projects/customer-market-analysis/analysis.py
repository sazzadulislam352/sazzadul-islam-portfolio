"""
Customer Market Analysis
-------------------------
Segments customers using RFM (Recency, Frequency, Monetary) analysis
and K-Means clustering, then produces the KPIs and charts that back
the Tableau dashboard described in the portfolio project.

Input : data.csv (sample dataset - 249 transactions / 50 customers)
Output: customer_segments.csv, summary KPIs printed to console,
        and PNG charts saved to ./output/

Usage:
    pip install pandas numpy scikit-learn matplotlib
    python analysis.py
"""

import os
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt

DATA_PATH = "data.csv"
OUTPUT_DIR = "output"
ANALYSIS_DATE = pd.Timestamp("2025-01-01")


def load_and_clean(path: str) -> pd.DataFrame:
    df = pd.read_csv(path, parse_dates=["transaction_date"])
    df.columns = [c.strip().lower() for c in df.columns]
    df = df.drop_duplicates()
    df = df.dropna(subset=["customer_id", "amount", "transaction_date"])
    df["amount"] = df["amount"].astype(float)
    return df


def build_rfm(df: pd.DataFrame) -> pd.DataFrame:
    grouped = df.groupby("customer_id").agg(
        recency_days=("transaction_date", lambda s: (ANALYSIS_DATE - s.max()).days),
        frequency=("transaction_id", "count"),
        monetary=("amount", "sum"),
    ).reset_index()
    return grouped


def segment_customers(rfm: pd.DataFrame, n_clusters: int = 4) -> pd.DataFrame:
    features = rfm[["recency_days", "frequency", "monetary"]]
    scaled = StandardScaler().fit_transform(features)

    model = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    rfm["segment"] = model.fit_predict(scaled)

    # Label segments by average monetary value (highest = Champions)
    order = rfm.groupby("segment")["monetary"].mean().sort_values(ascending=False).index
    labels = ["Champions", "Loyal Customers", "Needs Attention", "At Risk"]
    label_map = {seg: labels[i] for i, seg in enumerate(order)}
    rfm["segment_label"] = rfm["segment"].map(label_map)
    return rfm


def compute_kpis(df: pd.DataFrame, rfm: pd.DataFrame) -> dict:
    return {
        "total_customers": int(df["customer_id"].nunique()),
        "total_transactions": int(len(df)),
        "total_revenue": round(df["amount"].sum(), 2),
        "avg_order_value": round(df["amount"].mean(), 2),
        "segments": rfm["segment_label"].value_counts().to_dict(),
    }


def make_charts(df: pd.DataFrame, rfm: pd.DataFrame, out_dir: str) -> None:
    os.makedirs(out_dir, exist_ok=True)

    # Segment distribution
    plt.figure(figsize=(6, 4))
    rfm["segment_label"].value_counts().plot(kind="bar", color="#00c9a7")
    plt.title("Customers per Segment")
    plt.ylabel("Customers")
    plt.tight_layout()
    plt.savefig(f"{out_dir}/segment_distribution.png")
    plt.close()

    # Revenue by category
    plt.figure(figsize=(6, 4))
    df.groupby("product_category")["amount"].sum().sort_values().plot(kind="barh", color="#0a2540")
    plt.title("Revenue by Product Category")
    plt.xlabel("Revenue ($)")
    plt.tight_layout()
    plt.savefig(f"{out_dir}/revenue_by_category.png")
    plt.close()

    # Monthly revenue trend
    monthly = df.set_index("transaction_date").resample("M")["amount"].sum()
    plt.figure(figsize=(7, 4))
    monthly.plot(marker="o", color="#f7c948")
    plt.title("Monthly Revenue Trend")
    plt.ylabel("Revenue ($)")
    plt.tight_layout()
    plt.savefig(f"{out_dir}/monthly_revenue_trend.png")
    plt.close()


def main():
    df = load_and_clean(DATA_PATH)
    rfm = build_rfm(df)
    rfm = segment_customers(rfm, n_clusters=4)

    kpis = compute_kpis(df, rfm)
    print("=== Customer Market Analysis: KPIs ===")
    for k, v in kpis.items():
        print(f"{k}: {v}")

    rfm.to_csv("customer_segments.csv", index=False)
    make_charts(df, rfm, OUTPUT_DIR)
    print(f"\nSegment file written to customer_segments.csv")
    print(f"Charts written to ./{OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
