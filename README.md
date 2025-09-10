# SQL - Sales Analysis

## Overview
Analysis of customer behavior, retention, and lifetime value for an e-commerce company to improve customer retention and maximize revenue.

## Business Questions
1. **Customer Segmentation:** Who are our most valuable customers?
2. **Cohort Analysis:** How do different customer
groups generate revenue?
3. **Retention Analysis:** Which customers haven't purchased recently?

## Analysis Approach
### Clean Up Data
**🔎Query:** [create_views.sql](create_views.sql)

- Aggregated sales and customer data into revenue metrics
- Calculated first purchase dates for cohort analysis
- Created view combining transactions and customer details

### 1. Customer Segmentation
```sql

WITH customer_ltv AS(
SELECT
    customerkey,
    cleaned_name,
    SUM(total_net_revenue) AS total_ltv
FROM   
    cohort_analysis
GROUP BY
    customerkey,
    cleaned_name
), customer_segments AS(
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY total_ltv) AS ltv_25th_percentile,
        PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY total_ltv) AS ltv_75th_percentile
    FROM
        customer_ltv
), segment_values AS(
    SELECT
        c.*,
        CASE 
            WHEN c.total_ltv <= cs.ltv_25th_percentile THEN '1 - Low-Value'
            WHEN c.total_ltv <= cs.ltv_75th_percentile THEN '2 - Mid-Value'
            ELSE '3 - High-Value'
        END AS customer_segment
    FROM
        customer_ltv c,
        customer_segments cs
)
SELECT
    customer_segment,
    SUM(total_ltv) AS total_ltv,
    COUNT(customerkey) AS customer_count,
    SUM(total_ltv) / COUNT(customerkey) AS avg_ltv
FROM
    segment_values
GROUP BY
    customer_segment
ORDER BY
    customer_segment DESC
```
**📈 Visualization:**

<img src="/assets/customer_segmentation.png" alt="Cohort Analysis" width="50%">



📊 Key Findings

- High-Value customers make up the smallest share of customers but contribute the majority of total LTV (over 60%).
- Mid-Value customers represent the largest segment by count, with a solid contribution to overall LTV.
- Low-Value customers are equal in number to High-Value customers but generate only a fraction of the revenue.

💡 Business Insights

- Revenue is heavily concentrated in a relatively small group of high-value customers, making them critical to retention strategies.
- Mid-value customers represent the best growth opportunity, as improving their engagement could significantly increase total LTV.
- Low-value customers require a different approach — either cost-efficient engagement or strategies to move them up into higher-value tiers.

### 2. Cohort Analysis
- Monitored revenue and customer counts across cohorts
- Grouped cohorts based on the year of initial purchase
- Evaluated customer retention trends at the cohort level

**🔎Query:**
```sql
SELECT
    cohort_year,
    COUNT(DISTINCT customerkey) AS total_customers,
    SUM(total_net_revenue) AS total_revenue,
    SUM(total_net_revenue) / COUNT(DISTINCT customerkey) AS customer_revenue
FROM
    cohort_analysis
WHERE
    orderdate = first_purchased_date
GROUP BY
    cohort_year;
```
**📈 Visualization:**

<img src="/assets/cohort_analysis.png" alt="Cohort Analysis" width="50%">

📊 Key Findings

- The customer base and total revenue showed strong growth up to 2019, but both experienced volatility afterward, including a sharp decline in 2020.
- Average revenue per customer peaked around 2016–2017 and has steadily decreased through 2024, signaling reduced spending power.
- Recent cohorts are larger in size but generate lower revenue per customer compared to earlier cohorts.

💡 Business Insight
- Revenue growth is being driven more by acquiring customers in volume rather than by maximizing individual customer value.
- Newer customers appear less profitable, pointing to challenges in retention or increased price sensitivity.
- To sustain long-term growth, the company should prioritize strategies that increase customer lifetime value, such as upselling, loyalty programs, and targeted engagement initiatives.

### 3. Customer Retention
- Identified customers at risk of churning
- Analyzed last purchase patterns
- Calculated customer-specific metrics

**🔎Query:**
```sql

WITH customer_last_purchase AS(
    SELECT 
        customerkey,
        cleaned_name,
        orderdate,
        ROW_NUMBER() OVER(PARTITION BY customerkey ORDER BY orderdate DESC) AS rn,
        first_purchased_date,
        cohort_year
    FROM cohort_analysis
), churned_customers AS(
    SELECT
        customerkey,
        cleaned_name,
        orderdate AS last_purchase_date,
        CASE
            WHEN orderdate < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 months' THEN 'Churned'
            ELSE 'Active'
        END AS customer_status,
        cohort_year
    FROM customer_last_purchase
    WHERE rn = 1 AND
        first_purchased_date < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 months' 
)
SELECT
    cohort_year,
    customer_status,
    COUNT(customerkey) AS num_customers,
    SUM(COUNT(customerkey)) OVER(PARTITION BY cohort_year) AS total_customers,
    ROUND(COUNT(customerkey) / SUM(COUNT(customerkey)) OVER(PARTITION BY cohort_year),2) AS status_percentage
FROM
    churned_customers
GROUP BY
    cohort_year,
    customer_status
```
**📈 Visualization:**

<img src="/assets/customer_retention.png" alt="Cohort Analysis" width="50%">

📊 Key Findings

- High Churn Across Cohorts: Around 90–92% of customers churned within each cohort year, leaving only 8–10% retained.
- Retention Slightly Improving: Recent cohorts (2022–2023) show a small increase in retention (10%) compared to earlier cohorts (8–9%).
- Growing Cohort Sizes: Total customer acquisition increased significantly over time, but the absolute number of churned customers grew alongside it.

💡 Business Insights

- The business is successfully acquiring more customers, but retention remains a critical weakness most customers disengage after their initial purchase year.
- The slight improvement in recent years indicates that newer strategies may be helping, but retention is still far below sustainable levels.
- To maximize customer lifetime value, the company should prioritize retention strategies such as personalized offers, loyalty programs, and re-engagement campaigns rather than relying mainly on new customer acquisition.
## Strategic Recommendations
1. **Customer Value Growth (Segmentation Focus)**

- Introduce an exclusive VIP program for the 12,372 high-value customers driving 66% of revenue.
- Develop tailored upgrade journeys for mid-value customers to unlock the $66.6M → $135.4M growth potential.
- Offer budget-friendly promotions for low-value customers to encourage higher purchase frequency.
2. **Cohort Revenue Strategy (Cohort Analysis)**
- Re-engage 2022–2024 cohorts with personalized offers to boost activity.
- Launch loyalty or subscription programs to reduce revenue volatility across cohorts.
- Replicate successful tactics from the strong-spending 2016–2018 cohorts for newer customer groups.
3. **Retention & Churn Reduction (Customer Lifecycle)**
- Enhance early-stage engagement with onboarding perks and loyalty rewards during the first 1–2 years.
- Run targeted win-back campaigns to recover churned high-value customers.
- Deploy proactive monitoring to identify and intervene with at-risk customers before churn occurs.
## Technical Details

- **Database:** PostgreSQL
- **Database:** PostgreSQL
- **Visualization:** ChatGPT