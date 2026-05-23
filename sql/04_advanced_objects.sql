-- ========================
-- Object 1: Trigger
-- Auto-reduce stock and raise alert when item sells out
-- ========================

CREATE OR REPLACE FUNCTION update_stock_on_order()
RETURNS TRIGGER AS $$
BEGIN
    -- Reduce available quantity in DailyMenu
    UPDATE DailyMenu
    SET available_quantity = available_quantity - NEW.quantity
    WHERE item_id = NEW.item_id
        AND date = CURRENT_DATE;

    -- Check if stock has hit zero and mark unavailable
    UPDATE DailyMenu
    SET is_available = FALSE
    WHERE item_id = NEW.item_id
        AND date = CURRENT_DATE
        AND available_quantity <= 0;

    -- If stock is now zero, insert a StaffAlert
    IF EXISTS (
        SELECT 1 FROM DailyMenu
        WHERE item_id = NEW.item_id
            AND date = CURRENT_DATE
            AND available_quantity <= 0
    ) THEN
        INSERT INTO StaffAlert (item_id, alert_type, message, is_resolved)
        VALUES (
            NEW.item_id,
            'low_stock',
            'Item sold out. Quantity reached zero.',
            FALSE
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock
AFTER INSERT ON OrderItem
FOR EACH ROW
EXECUTE FUNCTION update_stock_on_order();


-- ========================
-- Object 2: Stored Procedure
-- Daily revenue summary for a canteen
-- ========================

CREATE OR REPLACE PROCEDURE daily_revenue_summary(
    p_canteen_id INT,
    p_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    total_orders INT;
    total_revenue DECIMAL(10,2);
    top_item VARCHAR(100);
BEGIN
    -- Count total completed orders
    SELECT COUNT(*) INTO total_orders
    FROM Orders
    WHERE canteen_id = p_canteen_id
        AND order_date = p_date
        AND status = 'picked_up';

    -- Sum total revenue
    SELECT COALESCE(SUM(total_amount), 0) INTO total_revenue
    FROM Orders
    WHERE canteen_id = p_canteen_id
        AND order_date = p_date
        AND status = 'picked_up';

    -- Find top selling item by quantity
    SELECT mi.name INTO top_item
    FROM OrderItem oi
    JOIN Orders o ON oi.order_id = o.order_id
    JOIN MenuItem mi ON oi.item_id = mi.item_id
    WHERE o.canteen_id = p_canteen_id
        AND o.order_date = p_date
        AND o.status = 'picked_up'
    GROUP BY mi.name
    ORDER BY SUM(oi.quantity) DESC
    LIMIT 1;

    -- Print summary
    RAISE NOTICE '========== Daily Summary ==========';
    RAISE NOTICE 'Canteen ID  : %', p_canteen_id;
    RAISE NOTICE 'Date        : %', p_date;
    RAISE NOTICE 'Total Orders: %', total_orders;
    RAISE NOTICE 'Total Revenue: Rs. %', total_revenue;
    RAISE NOTICE 'Top Item    : %', COALESCE(top_item, 'No sales today');
    RAISE NOTICE '===================================';
END;
$$;


-- ========================
-- Object 3: View
-- Live order dashboard for today
-- ========================

CREATE OR REPLACE VIEW order_dashboard AS
SELECT
    o.order_id,
    s.name AS student_name,
    c.name AS canteen_name,
    ts.slot_time,
    o.order_type,
    o.status,
    o.total_amount,
    o.order_date,
    COUNT(oi.order_item_id) AS total_items
FROM Orders o
JOIN Student s ON o.student_id = s.student_id
JOIN Canteen c ON o.canteen_id = c.canteen_id
JOIN TimeSlot ts ON o.slot_id = ts.slot_id
JOIN OrderItem oi ON o.order_id = oi.order_id
WHERE o.order_date = CURRENT_DATE
GROUP BY
    o.order_id, s.name, c.name,
    ts.slot_time, o.order_type,
    o.status, o.total_amount, o.order_date;


-- ========================
-- Object 4: Function
-- Estimate wait time for a menu item
-- ========================

CREATE OR REPLACE FUNCTION estimate_wait_time(p_item_id INT)
RETURNS INT AS $$
DECLARE
    avg_prepare_time INT;
    queue_length INT;
    estimated_wait INT;
BEGIN
    -- Get average prepare time for this item
    SELECT COALESCE(AVG(mi.prepare_time_minutes), 5) INTO avg_prepare_time
    FROM MenuItem mi
    WHERE mi.item_id = p_item_id;

    -- Count how many pending/preparing orders contain this item right now
    SELECT COUNT(*) INTO queue_length
    FROM OrderItem oi
    JOIN Orders o ON oi.order_id = o.order_id
    WHERE oi.item_id = p_item_id
        AND o.order_date = CURRENT_DATE
        AND o.status IN ('pending', 'preparing');

    -- Estimate: prepare time + 2 minutes per order ahead in queue
    estimated_wait := avg_prepare_time + (queue_length * 2);

    RETURN estimated_wait;
END;
$$ LANGUAGE plpgsql;