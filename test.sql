SELECT
    cohort_year,
    SUM(total_net_revenue)
FROM
    cohort_analysis
GROUP BY
    cohort_year
ORDER BY
    cohort_year DESC

SELECT *
FROM cohort_analysis;


SELECT *
FROM 
product
