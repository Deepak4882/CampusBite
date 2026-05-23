# 🍱 CampusBite — College Canteen Pre-Order System

A full-stack relational database application for managing college canteen operations — built as a DBMS mini-project with a live REST API, interactive web dashboard, and cloud PostgreSQL database.

## 🌐 Live Demo
- **Frontend:** https://deepak4882.github.io/CampusBite
- **API Docs:** https://campusbite-l2gr.onrender.com/docs

## 🧠 What Makes This Different
- Implements the **Fractional Knapsack algorithm** (from Algorithm Design & Analysis) as a live budget-based food recommender
- Auto-generates **staff alerts** via PostgreSQL triggers when stock hits zero or feedback drops
- **Wait time estimation** function using average prepare time and real-time queue length
- Full normalization documentation (1NF → 3NF) with before/after examples

## 🏗️ Tech Stack
| Layer | Technology |
|---|---|
| Database | PostgreSQL 18 (Neon cloud) |
| Backend | FastAPI (Python) |
| Frontend | HTML, CSS, Vanilla JS |
| Deployment | Render (backend), GitHub Pages (frontend) |

## 📁 Project Structure
campusbite/
├── backend/
│   ├── main.py          # FastAPI REST API
│   ├── database.py      # PostgreSQL connection
│   └── requirements.txt
├── frontend/
│   ├── index.html       # Main UI
│   ├── style.css        # Styling
│   └── app.js           # API calls and rendering
├── sql/
│   ├── 01_ddl.sql       # Table creation with constraints
│   ├── 02_dml.sql       # Sample data
│   ├── 03_queries.sql   # 6 complex SQL queries
│   └── 04_advanced_objects.sql  # Trigger, Procedure, View, Function
└── docs/
└── normalization.md # 1NF → 3NF documentation

## 🗄️ Database Design
- **12 tables** — College, Student, Canteen, MenuItem, DailyMenu, TimeSlot, Orders, OrderItem, Feedback, FeedbackDetail, RestockLog, StaffAlert
- **Fully normalized to 3NF**
- **4 advanced objects** — trigger, stored procedure, view, function

## 📊 Complex SQL Queries
1. Top 3 most ordered items today (JOIN + aggregate)
2. Students who ordered but never gave feedback (NOT EXISTS subquery)
3. Average rating per feedback aspect per canteen (multiple JOINs + GROUP BY)
4. Time slots with more than 50% capacity filled (HAVING + percentage)
5. Items below restock threshold with no restock today (NOT IN subquery)
6. Greedy budget recommender — Fractional Knapsack via SQL (ADA integration)

## ⚙️ Advanced Database Objects
- **Trigger** — auto-reduces stock and raises StaffAlert when item sells out
- **Stored Procedure** — daily revenue summary for canteen staff
- **View** — live order dashboard joining 4 tables
- **Function** — wait time estimator based on queue length and prepare time

## 🚀 Run Locally
```bash
# Clone the repo
git clone https://github.com/Deepak4882/CampusBite.git

# Backend
cd CampusBite/backend
pip install -r requirements.txt
# Create .env with your DATABASE_URL
python -m uvicorn main:app --reload

# Frontend
# Open frontend/index.html in browser
```

## 📚 Academic Context
Built as a DBMS mini-project (4th semester, CSE) at BLDEA's VP Dr. PG Halakatti College of Engineering. Demonstrates practical implementation of database design, normalization, SQL querying, and algorithmic thinking (ADA — Fractional Knapsack).