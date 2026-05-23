-- ========================
-- CampusBite Complex Queries
-- Phase 5: Data Retrieval
-- ========================

-- Query 1: Top 3 most ordered menu items today
-- Uses: JOIN, GROUP BY, ORDER BY, LIMIT, aggregate
SELECT 
    mi.name AS item_name,
    mi.category,
    SUM(oi.quantity) AS total_ordered,
    SUM(oi.subtotal) AS total_revenue
FROM OrderItem oi
JOIN MenuItem mi ON oi.item_id = mi.item_id
JOIN Orders o ON oi.order_id = o.order_id
WHERE o.order_date = CURRENT_DATE
GROUP BY mi.item_id, mi.name, mi.category
ORDER BY total_ordered DESC
LIMIT 3;

-- Query 2: Students who placed orders but never gave feedback
-- Uses: Subquery with NOT EXISTS
SELECT 
    s.student_id,
    s.name,
    s.email,
    COUNT(o.order_id) AS total_orders
FROM Student s
JOIN Orders o ON s.student_id = o.student_id
WHERE NOT EXISTS (
    SELECT 1 FROM Feedback f
    WHERE f.student_id = s.student_id
)
GROUP BY s.student_id, s.name, s.email
ORDER BY total_orders DESC;

-- Query 3: Average rating per feedback aspect per canteen
-- Uses: Multiple JOINs, GROUP BY, AVG aggregate, ROUND
SELECT 
    c.name AS canteen_name,
    fd.aspect,
    ROUND(AVG(fd.rating), 2) AS avg_rating,
    COUNT(fd.detail_id) AS total_responses
FROM FeedbackDetail fd
JOIN Feedback f ON fd.feedback_id = f.feedback_id
JOIN Orders o ON f.order_id = o.order_id
JOIN Canteen c ON o.canteen_id = c.canteen_id
GROUP BY c.name, fd.aspect
ORDER BY c.name, avg_rating DESC;

-- Query 4: Time slots with more than 50% capacity filled today
-- Uses: Subquery, JOIN, HAVING, aggregate, percentage calculation
SELECT 
    ts.slot_id,
    ts.slot_time,
    c.name AS canteen_name,
    ts.capacity AS max_capacity,
    COUNT(o.order_id) AS current_orders,
    ROUND((COUNT(o.order_id) * 100.0 / ts.capacity), 2) AS fill_percentage
FROM TimeSlot ts
JOIN Canteen c ON ts.canteen_id = c.canteen_id
LEFT JOIN Orders o ON ts.slot_id = o.slot_id 
    AND o.order_date = CURRENT_DATE
    AND o.status != 'cancelled'
GROUP BY ts.slot_id, ts.slot_time, c.name, ts.capacity
HAVING COUNT(o.order_id) > (ts.capacity * 0.5)
ORDER BY fill_percentage DESC;

-- Query 5: Menu items with below-threshold stock that have no restock today
-- Uses: Subquery with NOT IN, JOIN, comparison
SELECT 
    mi.item_id,
    mi.name AS item_name,
    c.name AS canteen_name,
    dm.available_quantity,
    mi.reorder_threshold,
    (mi.reorder_threshold - dm.available_quantity) AS shortage
FROM MenuItem mi
JOIN DailyMenu dm ON mi.item_id = dm.item_id
JOIN Canteen c ON mi.canteen_id = c.canteen_id
WHERE dm.date = CURRENT_DATE
    AND dm.available_quantity < mi.reorder_threshold
    AND mi.item_id NOT IN (
        SELECT item_id FROM RestockLog
        WHERE restock_date = CURRENT_DATE
    )
ORDER BY shortage DESC;

-- Query 6 (ADA - Greedy): Given a budget, find the best combination
-- of items that maximizes total portions within budget
-- Greedy approach: sort by value (quantity per rupee) descending
-- This mirrors the Fractional Knapsack algorithm from ADA
SELECT 
    mi.name AS item_name,
    mi.category,
    mi.base_price,
    dm.available_quantity,
    ROUND(dm.available_quantity / mi.base_price, 4) AS value_per_rupee,
    ROUND(mi.base_price * dm.available_quantity, 2) AS cost_to_buy_all
FROM MenuItem mi
JOIN DailyMenu dm ON mi.item_id = dm.item_id
WHERE dm.is_available = TRUE
    AND dm.date = CURRENT_DATE
ORDER BY value_per_rupee DESC;