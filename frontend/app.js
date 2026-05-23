const API = "http://127.0.0.1:8000";

// ── Navigation ────────────────────────────────────
function showSection(name) {
    document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
    document.querySelectorAll(".nav-link").forEach(l => l.classList.remove("active"));
    document.getElementById(name).classList.add("active");
    document.querySelector(`[onclick="showSection('${name}')"]`).classList.add("active");
}

// ── Load Canteens into dropdowns ──────────────────
async function loadCanteens() {
    const res = await fetch(`${API}/canteens`);
    const canteens = await res.json();

    const menuSelect = document.getElementById("canteen-select");
    const analyticsSelect = document.getElementById("analytics-canteen");

    canteens.forEach(c => {
        const opt1 = new Option(c.name, c.canteen_id);
        const opt2 = new Option(c.name, c.canteen_id);
        menuSelect.add(opt1);
        analyticsSelect.add(opt2);
    });
}

// ── Menu ──────────────────────────────────────────
async function loadMenu() {
    const canteen_id = document.getElementById("canteen-select").value;
    if (!canteen_id) return;

    const grid = document.getElementById("menu-grid");
    grid.innerHTML = `<div class="loading">Loading menu...</div>`;

    const res = await fetch(`${API}/menu/${canteen_id}`);
    const items = await res.json();

    if (items.length === 0) {
        grid.innerHTML = `<div class="empty-state">No items available today.</div>`;
        return;
    }

    grid.innerHTML = items.map(item => `
        <div class="menu-card ${!item.is_available ? 'unavailable' : ''}">
            <div class="menu-card-name">${item.name}</div>
            <div class="menu-card-category">${item.category}</div>
            <div class="menu-card-price">₹${item.price.toFixed(2)}</div>
            <div class="menu-card-meta">
                <span class="badge ${item.is_available ? 'badge-available' : 'badge-unavailable'}">
                    ${item.is_available ? `${item.available_quantity} left` : 'Sold Out'}
                </span>
                <span class="badge badge-wait">⏱ ${item.wait_minutes} min</span>
            </div>
        </div>
    `).join("");
}

// ── Orders ────────────────────────────────────────
async function loadOrders() {
    const wrapper = document.getElementById("orders-table-wrapper");
    wrapper.innerHTML = `<div class="loading">Loading orders...</div>`;

    const res = await fetch(`${API}/orders/dashboard`);
    const orders = await res.json();

    if (orders.length === 0) {
        wrapper.innerHTML = `<div class="empty-state">No orders today.</div>`;
        return;
    }

    wrapper.innerHTML = `
        <div class="table-wrapper">
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Student</th>
                        <th>Canteen</th>
                        <th>Slot</th>
                        <th>Type</th>
                        <th>Items</th>
                        <th>Amount</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    ${orders.map(o => `
                        <tr>
                            <td>${o.order_id}</td>
                            <td>${o.student_name}</td>
                            <td>${o.canteen_name}</td>
                            <td>${o.slot_time}</td>
                            <td>${o.order_type}</td>
                            <td>${o.total_items}</td>
                            <td>₹${parseFloat(o.total_amount).toFixed(2)}</td>
                            <td><span class="status-badge status-${o.status}">${o.status}</span></td>
                        </tr>
                    `).join("")}
                </tbody>
            </table>
        </div>
    `;
}

// ── Top Items ─────────────────────────────────────
async function loadTopItems() {
    const canteen_id = document.getElementById("analytics-canteen").value;
    if (!canteen_id) return;

    const list = document.getElementById("top-items-list");
    list.innerHTML = `<div class="loading">Loading...</div>`;

    const res = await fetch(`${API}/analytics/top-items/${canteen_id}`);
    const items = await res.json();

    if (items.length === 0) {
        list.innerHTML = `<div class="empty-state">No data yet.</div>`;
        return;
    }

    list.innerHTML = items.map((item, i) => `
        <div class="top-item-row">
            <div class="top-item-rank">${i + 1}</div>
            <div class="top-item-name">${item.name}</div>
            <div class="top-item-qty">${item.total_ordered} orders · ₹${item.total_revenue.toFixed(2)}</div>
        </div>
    `).join("");
}

// ── Greedy Recommender ────────────────────────────
async function loadGreedy() {
    const budget = document.getElementById("budget-input").value;
    if (!budget || budget <= 0) {
        alert("Please enter a valid budget.");
        return;
    }

    const result = document.getElementById("greedy-result");
    result.innerHTML = `<div class="loading">Calculating...</div>`;

    const res = await fetch(`${API}/analytics/greedy-recommender/${budget}`);
    const data = await res.json();

    if (data.selected_items.length === 0) {
        result.innerHTML = `<div class="empty-state">Budget too low for any item.</div>`;
        return;
    }

    result.innerHTML = `
        ${data.selected_items.map(item => `
            <div class="greedy-item">
                <span>${item.name} <small style="color:#aaa">(${item.category})</small></span>
                <span>₹${item.price.toFixed(2)}</span>
            </div>
        `).join("")}
        <div class="greedy-summary">
            Budget: ₹${data.budget} &nbsp;|&nbsp;
            Spent: ₹${(data.budget - data.remaining).toFixed(2)} &nbsp;|&nbsp;
            Remaining: ₹${data.remaining.toFixed(2)}
        </div>
    `;
}

// ── Alerts ────────────────────────────────────────
async function loadAlerts() {
    const list = document.getElementById("alerts-list");
    list.innerHTML = `<div class="loading">Loading alerts...</div>`;

    const res = await fetch(`${API}/alerts/unresolved`);
    const alerts = await res.json();

    if (alerts.length === 0) {
        list.innerHTML = `<div class="empty-state">No unresolved alerts.</div>`;
        return;
    }

    list.innerHTML = alerts.map(a => `
        <div class="alert-card">
            <div class="alert-info">
                <h4>${a.item_name}</h4>
                <p>${a.message}</p>
                <p style="font-size:0.78rem;color:#aaa;margin-top:0.3rem">
                    ${new Date(a.alert_time).toLocaleString()}
                </p>
            </div>
            <div class="alert-type">${a.alert_type.replace('_', ' ')}</div>
        </div>
    `).join("");
}

// ── Init ──────────────────────────────────────────
document.addEventListener("DOMContentLoaded", () => {
    loadCanteens();
    loadOrders();
    loadAlerts();
});