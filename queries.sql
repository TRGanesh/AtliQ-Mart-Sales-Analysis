-- 1.Provide alist of products with a base price greater than 500 and that are featured in promo type of 'BOGOF' (Buy One Get One Free).
SELECT
    dp.product_code,
    dp.product_name,
    fe.base_price,
    fe.promo_type
FROM
    dim_products dp
JOIN
    fact_events fe ON dp.product_code = fe.product_code
WHERE
    fe.base_price > 500
    AND fe.promo_type = 'BOGOF';

-- 2. Number of Stores in each City
SELECT city, COUNT(store_id) as store_count
FROM dim_stores
GROUP BY city
ORDER BY store_count DESC;

-- 3. Each campaign along with the total revenue generated before and after the campaign
SELECT
    dc.campaign_name,
    CONCAT(SUM(fe.base_price * fe.quantity_sold_before_promo) / 1000000, ' M') as total_revenue_before_promo,
    CONCAT(SUM(fe.base_price * fe.quantity_sold_after_promo) / 1000000, ' M') as total_revenue_after_promo
FROM
    dim_campaigns dc
JOIN
    fact_events fe ON dc.campaign_id = fe.campaign_id
GROUP BY
    dc.campaign_name
ORDER BY
    dc.campaign_name;
    
-- 4. Calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign,, along with Rankings 
WITH CampaignSales AS (
    SELECT
        dp.category,
        SUM(fe.quantity_sold_after_promo - fe.quantity_sold_before_promo) as incremental_sold_quantity
    FROM
        dim_products dp
    JOIN
        fact_events fe ON dp.product_code = fe.product_code
    JOIN
        dim_campaigns dc ON fe.campaign_id = dc.campaign_id
    WHERE
        dc.campaign_name = 'Diwali'  -- Replace 'Diwali' with the actual Diwali campaign name
    GROUP BY
        dp.category
)

SELECT
    category,
    ROUND((incremental_sold_quantity / NULLIF(SUM(incremental_sold_quantity) OVER (), 0)) * 100, 2) as isu_percentage,
    RANK() OVER (ORDER BY incremental_sold_quantity DESC) as rank_order
FROM
    CampaignSales
ORDER BY
    rank_order;

-- 5. Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns
WITH ProductSales AS (
    SELECT
        dp.product_name,
        dp.category,
        SUM(fe.base_price * (fe.quantity_sold_after_promo - fe.quantity_sold_before_promo)) as incremental_revenue
    FROM
        dim_products dp
    JOIN
        fact_events fe ON dp.product_code = fe.product_code
    GROUP BY
        dp.product_name, dp.category
)

SELECT
    product_name,
    category,
    ROUND((incremental_revenue / NULLIF(SUM(incremental_revenue) OVER (), 0)) * 100, 2) as ir_percentage
FROM
    ProductSales
ORDER BY
    ir_percentage DESC
LIMIT 5;

