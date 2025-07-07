# 🍽️ Restaurant Management Database System

A comprehensive SQL-based database system for managing a restaurant business, supporting owners, managers, employees, and customers. It covers restaurant registration, branches, employees, menus, customers, orders, RBAC (Role-Based Access Control), and more.

---

## 📌 Key Features

- 📂 Multi-entity schema (Owner, Restaurant, Branch, Employee, Customer, etc.)
- 🍛 Menu management with price validation (using triggers)
- 🛒 Order placement and tracking
- 🧾 Detailed order summaries and performance views
- 🛑 Role-based access control (RBAC) with permissions
- 🔐 Secure user authentication structure (bcrypt-ready)
- 🧠 Business logic via stored procedures and triggers
- 🧹 Auto-cleanup with scheduled events

---

## 🧱 Schema Structure

### 1. Core Tables
- **Owner**: Stores owner info
- **Restaurant**: Linked to owners
- **Branches**: Multiple branches per restaurant
- **Employee**: Linked to branches, includes passwords
- **Dishes**: Menu items with enforced positive pricing (via triggers)
- **OfferedDishes**: Junction table between branches and dishes
- **Customer**: Includes login credentials
- **Orders**: Linked to customers
- **OrderDetails**: Junction between orders and dishes

### 2. Views
- `v_OrderSummary`: Total orders per customer
- `v_BranchMenu`: Menu of each branch
- `v_TopDishes`: Top-selling dishes
- `v_BranchPerformance`: Orders and revenue by branch

### 3. Stored Procedures
- `PlaceOrder`: Places a simple order
- `PlaceFullOrder`: Places an order and fills order details in one transaction

### 4. Triggers
- Price validation for dishes (`BEFORE INSERT`, `BEFORE UPDATE`)
- Prevent deleting dishes in active orders
- Auto-update employee count in branches

### 5. Events
- Auto-cleanup for orders with NULL prices (runs daily)

### 6. RBAC (Role-Based Access Control)
- Tables: `Role`, `Permission`, `RolePermission`, `UserRole`
- Pre-seeded roles: Owner, Manager, Chef, Customer
- Permissions like `view_orders`, `place_orders`, `edit_menu`, `assign_staff`

---

## 🧪 Seeding

### ✅ Roles and Permissions
```sql
INSERT INTO Role (RoleName) VALUES ('owner'), ('manager'), ('chef'), ('customer');
INSERT INTO Permission (PermName) VALUES ('view_orders'), ('place_orders'), ('edit_menu'), ('assign_staff');
