# Product Retention & Cohort Analysis

## Project Overview

This project examines how users return to a digital product after signup using synthetic user and product-event data. The analysis measures user activity, compares retention across signup cohorts, and explores differences by acquisition channel and platform.

SQL is used for data preparation and analysis, while Power BI is used to present interactive dashboards.

> **Disclaimer:** This project uses synthetic data for portfolio and learning purposes. It does not represent the performance of a real company or product.

## Business Problem

A digital product team wants to understand whether newly acquired users return after signup and how retention changes over time. The analysis focuses on monthly active users, cohort-based retention, and retention differences across acquisition channels and platforms.

## Tools Used

- **SQL (SQLite):** Data preparation, deduplication, aggregations, monthly active users, cohort analysis, and retention comparisons.
- **Power BI:** KPI cards, monthly activity trends, cohort retention heatmaps, and segmentation dashboards.
- **Excel:** Dataset inspection and validation.

## Dataset

The project uses two raw synthetic datasets:

- `users_raw.csv` — user-level information, including user ID, signup date, cohort month, acquisition channel, and platform.
- `user_events_raw.csv` — product event records, including event ID, user ID, timestamp, event name, acquisition channel, and platform.

The supplied raw files contain duplicate records and incomplete or inconsistent fields. The SQL script creates standardized views and derives activity month and months since signup. The cohort definition uses the supplied `cohort_month` field.

## Key Findings

The Power BI report shows the following results for the supplied dataset:

- Approximately **8,500 total users**.
- Approximately **44,700 product events**.
- **403 monthly active users** in the latest activity month shown in the report.
- **71.16% Month 1 cohort retention** in the overall cohort view.
- **95.40% repeat activity rate**, based on users active in at least two distinct calendar months divided by users with observed event activity.
- Month 1 retention differs across acquisition channels and platforms. Organic-acquired users show the highest channel-level Month 1 retention in the dashboard, while Social is the lowest.

These results describe the supplied synthetic dataset. Differences between segments are associations and do not establish why users return or stop using the product.

## Analysis Approach

1. Reviewed the raw user and event datasets.
2. Used SQL to deduplicate user and event identifiers and standardize channel and platform labels.
3. Derived event date, activity month, and months since signup.
4. Calculated total users, distinct active users, total events, monthly active users, and repeat activity rate.
5. Grouped users by cohort month and calculated cohort size.
6. Calculated monthly cohort retention using distinct active users divided by the original cohort size.
7. Compared Month 1 retention across acquisition channels and platforms.
8. Built Power BI dashboards to present executive metrics, cohort retention, and segment comparisons.

## Dashboard

### Executive Overview

Presents total users, monthly active users, total events, repeat activity rate, monthly active user trends, and user distribution by acquisition channel and platform.

### Cohort Retention Analysis

Presents cohort size, Month 1 retention, and a cohort retention heatmap showing the share of each signup cohort active in each month since signup.

### Retention Segmentation

Compares cohort retention patterns across platforms and acquisition channels, including Month 1 retention comparisons.

## Recommendations for Further Investigation

1. Investigate why Month 1 retention differs across acquisition channels, including differences in campaign targeting, user intent, and onboarding experience.
2. Review the first-month user journey to identify where new users fail to reach meaningful product value.
3. Compare key event sequences by platform to understand whether the onboarding and core experience differ across iOS, Android, and Web.
4. Examine later-month cohort retention to identify when engagement declines most sharply.
5. Validate retention patterns with a larger and longer observation window before making product or acquisition investment decisions.

These are proposed investigation steps, not confirmed causes.

## Limitations

- The dataset is synthetic and does not represent real product behaviour.
- The observation window contains a limited number of signup cohorts, so later-month retention is not equally observable for every cohort.
- The supplied `cohort_month` field is used as the cohort definition; signup-date values are not used to reconstruct cohorts.
- Repeat activity rate is a separate metric from cohort retention and should not be interpreted as the percentage of all acquired users retained.
- Event counts measure recorded activity, not necessarily meaningful engagement or successful product outcomes.
- Segment differences do not establish causation.

## Project Structure

```text
product-retention-cohort-analysis/
├── data/
│   ├── users_raw.csv
│   └── user_events_raw.csv
├── sql/
│   └── product_retention_cohort_analysis.sql
├── powerbi/
│   └── product_retention_cohort_analysis.pbix
├── docs/
│   └── dashboard-screenshots/
│       ├── executive_overview.png
│       ├── cohort_retention_analysis.png
│       └── retention_segmentation.png
└── README.md
```

## Skills Demonstrated

SQL data preparation, data deduplication, monthly active user analysis, cohort analysis, retention measurement, customer segmentation, KPI development, Power BI dashboard development, and evidence-based product recommendations.
