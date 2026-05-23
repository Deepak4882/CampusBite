-- ========================
-- CampusBite DDL
-- Drop existing tables first
-- ========================

DROP TABLE IF EXISTS StaffAlert CASCADE;
DROP TABLE IF EXISTS RestockLog CASCADE;
DROP TABLE IF EXISTS FeedbackDetail CASCADE;
DROP TABLE IF EXISTS Feedback CASCADE;
DROP TABLE IF EXISTS OrderItem CASCADE;
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS TimeSlot CASCADE;
DROP TABLE IF EXISTS DailyMenu CASCADE;
DROP TABLE IF EXISTS MenuItem CASCADE;
DROP TABLE IF EXISTS Canteen CASCADE;
DROP TABLE IF EXISTS Student CASCADE;
DROP TABLE IF EXISTS College CASCADE;

-- ========================
-- Create tables fresh
-- ========================

-- 1. College
CREATE TABLE College (
    college_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100)
);

-- 2. Student
CREATE TABLE Student (
    student_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    college_id INT REFERENCES College(college_id) ON DELETE SET NULL,
    join_date DATE DEFAULT CURRENT_DATE
);

-- 3. Canteen
CREATE TABLE Canteen (
    canteen_id SERIAL PRIMARY KEY,
    college_id INT REFERENCES College(college_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    opening_time TIME,
    closing_time TIME
);

-- 4. MenuItem
CREATE TABLE MenuItem (
    item_id SERIAL PRIMARY KEY,
    canteen_id INT REFERENCES Canteen(canteen_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) CHECK (category IN ('Breakfast', 'Lunch', 'Snacks', 'Dinner', 'Beverages')),
    base_price DECIMAL(8,2) CHECK (base_price > 0),
    prepare_time_minutes INT CHECK (prepare_time_minutes > 0),
    reorder_threshold INT DEFAULT 20
);

-- 5. DailyMenu
CREATE TABLE DailyMenu (
    daily_menu_id SERIAL PRIMARY KEY,
    item_id INT REFERENCES MenuItem(item_id) ON DELETE CASCADE,
    canteen_id INT REFERENCES Canteen(canteen_id) ON DELETE CASCADE,
    date DATE DEFAULT CURRENT_DATE,
    available_quantity INT CHECK (available_quantity >= 0),
    is_available BOOLEAN DEFAULT TRUE
);

-- 6. TimeSlot
CREATE TABLE TimeSlot (
    slot_id SERIAL PRIMARY KEY,
    canteen_id INT REFERENCES Canteen(canteen_id) ON DELETE CASCADE,
    slot_time TIME NOT NULL,
    capacity INT CHECK (capacity > 0)
);

-- 7. Orders
CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES Student(student_id) ON DELETE SET NULL,
    canteen_id INT REFERENCES Canteen(canteen_id) ON DELETE SET NULL,
    slot_id INT REFERENCES TimeSlot(slot_id) ON DELETE SET NULL,
    order_date DATE DEFAULT CURRENT_DATE,
    order_type VARCHAR(20) CHECK (order_type IN ('preorder', 'walkin')),
    status VARCHAR(20) CHECK (status IN ('pending', 'preparing', 'ready', 'picked_up', 'cancelled')),
    total_amount DECIMAL(8,2) CHECK (total_amount >= 0)
);

-- 8. OrderItem
CREATE TABLE OrderItem (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES Orders(order_id) ON DELETE CASCADE,
    item_id INT REFERENCES MenuItem(item_id) ON DELETE SET NULL,
    quantity INT CHECK (quantity > 0),
    subtotal DECIMAL(8,2) CHECK (subtotal >= 0)
);

-- 9. Feedback
CREATE TABLE Feedback (
    feedback_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES Student(student_id) ON DELETE SET NULL,
    order_id INT REFERENCES Orders(order_id) ON DELETE CASCADE,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. FeedbackDetail
CREATE TABLE FeedbackDetail (
    detail_id SERIAL PRIMARY KEY,
    feedback_id INT REFERENCES Feedback(feedback_id) ON DELETE CASCADE,
    aspect VARCHAR(50) CHECK (aspect IN ('taste', 'portion', 'temperature', 'speed', 'hygiene')),
    rating INT CHECK (rating BETWEEN 1 AND 5)
);

-- 11. RestockLog
CREATE TABLE RestockLog (
    restock_id SERIAL PRIMARY KEY,
    item_id INT REFERENCES MenuItem(item_id) ON DELETE CASCADE,
    restock_date DATE DEFAULT CURRENT_DATE,
    quantity_added INT CHECK (quantity_added > 0),
    requested_by VARCHAR(100)
);

-- 12. StaffAlert
CREATE TABLE StaffAlert (
    alert_id SERIAL PRIMARY KEY,
    item_id INT REFERENCES MenuItem(item_id) ON DELETE CASCADE,
    alert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    alert_type VARCHAR(50) CHECK (alert_type IN ('low_stock', 'bad_feedback', 'overbooking')),
    message TEXT,
    is_resolved BOOLEAN DEFAULT FALSE
);