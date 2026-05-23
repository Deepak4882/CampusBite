from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from database import get_connection
from datetime import date

app = FastAPI(
    title="CampusBite API",
    description="College Canteen Pre-Order System API",
    version="1.0.0"
)

# Allow frontend to talk to backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Root ──────────────────────────────────────────
@app.get("/")
def root():
    return {"message": "CampusBite API is running"}

# ── Menu ──────────────────────────────────────────
@app.get("/menu/{canteen_id}")
def get_menu(canteen_id: int):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT mi.item_id, mi.name, mi.category, mi.base_price,
               dm.available_quantity, dm.is_available,
               estimate_wait_time(mi.item_id) AS wait_minutes
        FROM MenuItem mi
        JOIN DailyMenu dm ON mi.item_id = dm.item_id
        WHERE mi.canteen_id = %s AND dm.date = CURRENT_DATE
        ORDER BY mi.category, mi.name
    """, (canteen_id,))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [
        {
            "item_id": r[0],
            "name": r[1],
            "category": r[2],
            "price": float(r[3]),
            "available_quantity": r[4],
            "is_available": r[5],
            "wait_minutes": r[6]
        } for r in rows
    ]

# ── Orders ────────────────────────────────────────
@app.get("/orders/dashboard")
def get_order_dashboard():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM order_dashboard ORDER BY slot_time")
    rows = cur.fetchall()
    cols = [desc[0] for desc in cur.description]
    cur.close()
    conn.close()
    return [dict(zip(cols, row)) for row in rows]

@app.get("/orders/student/{student_id}")
def get_student_orders(student_id: int):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT o.order_id, o.order_date, o.order_type,
               o.status, o.total_amount, c.name AS canteen_name,
               ts.slot_time
        FROM Orders o
        JOIN Canteen c ON o.canteen_id = c.canteen_id
        JOIN TimeSlot ts ON o.slot_id = ts.slot_id
        WHERE o.student_id = %s
        ORDER BY o.order_date DESC
    """, (student_id,))
    rows = cur.fetchall()
    cols = [desc[0] for desc in cur.description]
    cur.close()
    conn.close()
    return [dict(zip(cols, row)) for row in rows]

# ── Analytics ─────────────────────────────────────
@app.get("/analytics/top-items/{canteen_id}")
def get_top_items(canteen_id: int):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT mi.name, mi.category,
               SUM(oi.quantity) AS total_ordered,
               SUM(oi.subtotal) AS total_revenue
        FROM OrderItem oi
        JOIN MenuItem mi ON oi.item_id = mi.item_id
        JOIN Orders o ON oi.order_id = o.order_id
        WHERE o.canteen_id = %s AND o.order_date = CURRENT_DATE
        GROUP BY mi.item_id, mi.name, mi.category
        ORDER BY total_ordered DESC
        LIMIT 5
    """, (canteen_id,))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [
        {
            "name": r[0],
            "category": r[1],
            "total_ordered": r[2],
            "total_revenue": float(r[3])
        } for r in rows
    ]

@app.get("/analytics/greedy-recommender/{budget}")
def greedy_recommender(budget: float):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT mi.name, mi.category, mi.base_price,
               dm.available_quantity,
               ROUND(dm.available_quantity / mi.base_price, 4) AS value_per_rupee
        FROM MenuItem mi
        JOIN DailyMenu dm ON mi.item_id = dm.item_id
        WHERE dm.is_available = TRUE AND dm.date = CURRENT_DATE
        ORDER BY value_per_rupee DESC
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()

    # Greedy selection within budget
    selected = []
    remaining = budget
    for r in rows:
        price = float(r[2])
        if price <= remaining:
            selected.append({
                "name": r[0],
                "category": r[1],
                "price": price,
                "value_per_rupee": float(r[4])
            })
            remaining -= price

    return {
        "budget": budget,
        "remaining": round(remaining, 2),
        "selected_items": selected
    }

# ── Alerts ────────────────────────────────────────
@app.get("/alerts/unresolved")
def get_unresolved_alerts():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT sa.alert_id, mi.name AS item_name,
               sa.alert_type, sa.message,
               sa.alert_time, sa.is_resolved
        FROM StaffAlert sa
        JOIN MenuItem mi ON sa.item_id = mi.item_id
        WHERE sa.is_resolved = FALSE
        ORDER BY sa.alert_time DESC
    """)
    rows = cur.fetchall()
    cols = [desc[0] for desc in cur.description]
    cur.close()
    conn.close()
    return [dict(zip(cols, row)) for row in rows]

# ── Canteens ──────────────────────────────────────
@app.get("/canteens")
def get_canteens():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT canteen_id, name, location FROM Canteen")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [
        {"canteen_id": r[0], "name": r[1], "location": r[2]}
        for r in rows
    ]

# ── Students ──────────────────────────────────────
@app.get("/students")
def get_students():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT student_id, name, email FROM Student")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [
        {"student_id": r[0], "name": r[1], "email": r[2]}
        for r in rows
    ]