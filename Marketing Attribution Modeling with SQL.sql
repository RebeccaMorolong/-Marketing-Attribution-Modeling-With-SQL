--Marketing Attribution Modeling (SQL Portfolio Project)
--Project Goal
--to analyze multi-channel marketing touchpoints and assign credit for conversions to channels to understand their impact on sales or leads.


--1. First-Touch Attribution (Credit to First Channel)
SELECT 
  mc.channel_name,
  COUNT(DISTINCT c.customer_id) AS conversions,
  ROUND(COUNT(DISTINCT c.customer_id) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS conversion_pct
FROM customers c
JOIN touchpoints t ON c.customer_id = t.customer_id
JOIN marketing_channels mc ON t.channel_id = mc.channel_id
WHERE t.touch_order = 1
GROUP BY mc.channel_name
ORDER BY conversions DESC;

--2. Last-Touch Attribution (Credit to Last Channel)
SELECT 
  mc.channel_name,
  COUNT(DISTINCT c.customer_id) AS conversions,
  ROUND(COUNT(DISTINCT c.customer_id) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS conversion_pct
FROM customers c
JOIN touchpoints t ON c.customer_id = t.customer_id
JOIN marketing_channels mc ON t.channel_id = mc.channel_id
WHERE t.touch_order = (
  SELECT MAX(t2.touch_order) 
  FROM touchpoints t2 
  WHERE t2.customer_id = c.customer_id
)
GROUP BY mc.channel_name
ORDER BY conversions DESC;

--3. Linear Attribution (Equal Credit to All Channels)
WITH touch_counts AS (
  SELECT 
    customer_id,
    COUNT(*) AS total_touches
  FROM touchpoints
  GROUP BY customer_id
),
channel_credits AS (
  SELECT 
    t.channel_id,
    t.customer_id,
    1.0 / tc.total_touches AS credit
  FROM touchpoints t
  JOIN touch_counts tc ON t.customer_id = tc.customer_id
)
SELECT 
  mc.channel_name,
  ROUND(SUM(cc.credit), 2) AS total_credit
FROM channel_credits cc
JOIN marketing_channels mc ON cc.channel_id = mc.channel_id
GROUP BY mc.channel_name
ORDER BY total_credit DESC;

--4. Time Decay Attribution (Credit Weighted by Recency)
WITH max_touch AS (
  SELECT customer_id, MAX(touch_date) AS last_touch_date
  FROM touchpoints
  GROUP BY customer_id
),
weighted_credits AS (
  SELECT 
    t.customer_id,
    t.channel_id,
    EXP(-0.5 * DATE_PART('day', mt.last_touch_date - t.touch_date)) AS weight
  FROM touchpoints t
  JOIN max_touch mt ON t.customer_id = mt.customer_id
)
SELECT 
  mc.channel_name,
  ROUND(SUM(wc.weight), 2) AS weighted_credit
FROM weighted_credits wc
JOIN marketing_channels mc ON wc.channel_id = mc.channel_id
GROUP BY mc.channel_name
ORDER BY weighted_credit DESC;


