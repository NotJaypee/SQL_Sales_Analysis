CREATE VIEW public.cohort_analysis AS
WITH customer_revenue AS(    
    SELECT
        s.customerkey,
        s.orderdate,
        SUM( s.quantity * s.netprice / s.exchangerate) AS total_net_revenue,
        COUNT(s.orderkey) AS num_orders,
        c.countryfull,
        c.age,
        c.givenname,
        c.surname
    FROM 
        sales AS s
    LEFT JOIN customer c ON c.customerkey = s.customerkey
    GROUP BY
        s.customerkey,
        s.orderdate,
        c.countryfull,
        c.age,
        c.givenname,
        c.surname
)

SELECT 
    customerkey,
    orderdate,
    total_net_revenue,
    num_orders,
    countryfull,
    age,
    CONCAT(TRIM(givenname), ' ',TRIM(surname)) AS cleaned_name,
    MIN(cr.orderdate) OVER(PARTITION BY cr.customerkey) AS first_purchased_date,
    EXTRACT(YEAR FROM MIN(cr.orderdate) OVER(
        PARTITION BY cr.customerkey
    ))AS cohort_year
FROM customer_revenue cr;



