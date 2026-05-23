SELECT 'College' AS table_name, COUNT(*) AS rows FROM College
UNION ALL
SELECT 'Student', COUNT(*) FROM Student
UNION ALL
SELECT 'Canteen', COUNT(*) FROM Canteen
UNION ALL
SELECT 'MenuItem', COUNT(*) FROM MenuItem
UNION ALL
SELECT 'DailyMenu', COUNT(*) FROM DailyMenu
UNION ALL
SELECT 'TimeSlot', COUNT(*) FROM TimeSlot
UNION ALL
SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL
SELECT 'OrderItem', COUNT(*) FROM OrderItem
UNION ALL
SELECT 'Feedback', COUNT(*) FROM Feedback
UNION ALL
SELECT 'FeedbackDetail', COUNT(*) FROM FeedbackDetail
UNION ALL
SELECT 'RestockLog', COUNT(*) FROM RestockLog
UNION ALL
SELECT 'StaffAlert', COUNT(*) FROM StaffAlert;