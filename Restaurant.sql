-- 1. Create Database and Switch to It
CREATE DATABASE
IF NOT EXISTS RestaurantManagementDB;
USE RestaurantManagementDB;

-- 2. Core Tables

-- 2.1 Owner
CREATE TABLE
IF NOT EXISTS Owner
(
  CPR VARCHAR
(20) PRIMARY KEY,
  FirstName VARCHAR
(50),
  LastName VARCHAR
(50),
  TelephoneNumber VARCHAR
(20)
);

-- 2.2 Restaurant
CREATE TABLE
IF NOT EXISTS Restaurant
(
  ID INT AUTO_INCREMENT PRIMARY KEY,
  Name VARCHAR
(100) NOT NULL,
  Type VARCHAR
(50),
  Location VARCHAR
(100),
  OwnerCPR VARCHAR
(20),
  FOREIGN KEY
(OwnerCPR) REFERENCES Owner
(CPR)
);

-- 2.3 Branches
CREATE TABLE
IF NOT EXISTS Branches
(
  BranchNO INT AUTO_INCREMENT PRIMARY KEY,
  CityName VARCHAR
(100),
  TelephoneNumber VARCHAR
(20),
  NumberOfEmployees INT DEFAULT 0,
  RestaurantID INT,
  FOREIGN KEY
(RestaurantID) REFERENCES Restaurant
(ID)
);

-- 2.4 Employee (with Password)
CREATE TABLE
IF NOT EXISTS Employee
(
  CPR VARCHAR
(20) PRIMARY KEY,
  FirstName VARCHAR
(50),
  LastName VARCHAR
(50),
  JobRole VARCHAR
(50),
  BranchNO INT,
  Password VARCHAR
(255),
  FOREIGN KEY
(BranchNO) REFERENCES Branches
(BranchNO)
);

-- 2.5 Dishes (no CHECK, triggers enforce positive price)

DROP TABLE IF EXISTS Dishes;
CREATE TABLE
IF NOT EXISTS Dishes
(
  ID          INT AUTO_INCREMENT PRIMARY KEY,
  Name        VARCHAR
(100)   NOT NULL,
  Ingredients TEXT,
  Price       DECIMAL
(10,2)  NOT NULL
);

DELIMITER $$
-- BEFORE INSERT: enforce Price > 0
CREATE TRIGGER trg_dishes_price_insert
BEFORE
INSERT ON
Dishes
FOR
EACH
ROW
BEGIN
    IF NEW.Price <= 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT
    = 'Dishes.Price must be > 0';
END
IF;
END$$

-- BEFORE UPDATE: enforce Price > 0
CREATE TRIGGER trg_dishes_price_update
BEFORE
UPDATE ON Dishes
FOR EACH ROW
BEGIN
    IF NEW.Price <= 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT
    = 'Dishes.Price must be > 0';
END
IF;
END$$
DELIMITER ;

-- 2.6 OfferedDishes (Junction)
CREATE TABLE
IF NOT EXISTS OfferedDishes
(
  BranchNO INT,
  DishID INT,
  PRIMARY KEY
(BranchNO, DishID),
  FOREIGN KEY
(BranchNO) REFERENCES Branches
(BranchNO),
  FOREIGN KEY
(DishID)   REFERENCES Dishes
(ID)
);

-- 2.7 Customer
CREATE TABLE
IF NOT EXISTS Customer
(
  ID INT AUTO_INCREMENT PRIMARY KEY,
  Name VARCHAR
(100),
  EmailAddress VARCHAR
(100) UNIQUE NOT NULL,
  Password VARCHAR
(255) NOT NULL,
  TelephoneNumber VARCHAR
(20)
);

-- 2.8 Orders
CREATE TABLE
IF NOT EXISTS Orders
(
  OrderNO INT AUTO_INCREMENT PRIMARY KEY,
  CustomerID INT,
  Date DATE NOT NULL,
  Time TIME NOT NULL,
  DeliveryTime TIME,
  OnTime BOOLEAN,
  Comment TEXT,
  Price DECIMAL
(10,2) DEFAULT 0,
  FOREIGN KEY
(CustomerID) REFERENCES Customer
(ID),
  CONSTRAINT chk_price_positive CHECK
(Price >= 0)
);

-- 2.9 OrderDetails (Junction)
CREATE TABLE
IF NOT EXISTS OrderDetails
(
  OrderNO INT,
  DishID INT,
  Quantity INT DEFAULT 1,
  PRIMARY KEY
(OrderNO, DishID),
  FOREIGN KEY
(OrderNO) REFERENCES Orders
(OrderNO),
  FOREIGN KEY
(DishID)   REFERENCES Dishes
(ID)
);

-- 3. RBAC Tables

CREATE TABLE
IF NOT EXISTS Role
(
  RoleID   INT AUTO_INCREMENT PRIMARY KEY,
  RoleName VARCHAR
(50) UNIQUE NOT NULL
);

CREATE TABLE
IF NOT EXISTS Permission
(
  PermID   INT AUTO_INCREMENT PRIMARY KEY,
  PermName VARCHAR
(50) UNIQUE NOT NULL
);

CREATE TABLE
IF NOT EXISTS RolePermission
(
  RoleID INT,
  PermID INT,
  PRIMARY KEY
(RoleID,PermID),
  FOREIGN KEY
(RoleID)   REFERENCES Role
(RoleID),
  FOREIGN KEY
(PermID)   REFERENCES Permission
(PermID)
);

CREATE TABLE
IF NOT EXISTS UserRole
(
  UserType ENUM
('customer','employee','owner') NOT NULL,
  UserID   VARCHAR
(20)            NOT NULL,
  RoleID   INT,
  PRIMARY KEY
(UserType,UserID,RoleID),
  FOREIGN KEY
(RoleID) REFERENCES Role
(RoleID)
);

-- 4. Seed Roles & Permissions

INSERT IGNORE
INTO Role
(RoleName) VALUES
('owner'),
('manager'),
('chef'),
('customer');

INSERT IGNORE
INTO Permission
(PermName) VALUES
('view_orders'),
('place_orders'),
('edit_menu'),
('assign_staff');

INSERT IGNORE
INTO RolePermission
SELECT r.RoleID, p.PermID
FROM Role r
    CROSS JOIN Permission p
WHERE r.RoleName = 'owner';

-- 5. Default Admin Employee

-- 5.1 Insert a manager user with bcrypt-hashed password ("admin123")
INSERT IGNORE
INTO Employee
(CPR, FirstName, LastName, JobRole, BranchNO, Password)
VALUES
('admin001', 'Admin', 'User', 'Manager', 1, '$2a$10$8dZG5zkU7WOSQFZP/HEDme1xE1sxWjfqj9GPNsUqtWh2UVXdsdvMi');

-- 5.2 Assign the "manager" role
INSERT IGNORE
INTO UserRole
(UserType, UserID, RoleID)
SELECT 'employee', 'admin001', RoleID
FROM Role
WHERE RoleName = 'manager';

-- 6. Views

CREATE OR REPLACE VIEW v_OrderSummary AS
SELECT
    o.OrderNO,
    c.Name       AS CustomerName,
    o.Date,
    o.Price,
    SUM(od.Quantity) AS TotalItems
FROM Orders o
    JOIN Customer c ON o.CustomerID = c.ID
    JOIN OrderDetails od ON o.OrderNO    = od.OrderNO
GROUP BY o.OrderNO, c.Name, o.Date, o.Price;

CREATE OR REPLACE VIEW v_BranchMenu AS
SELECT
    b.BranchNO,
    b.CityName,
    d.ID      AS DishID,
    d.Name    AS DishName,
    d.Price
FROM Branches b
    JOIN OfferedDishes od ON b.BranchNO = od.BranchNO
    JOIN Dishes d ON od.DishID   = d.ID;

CREATE OR REPLACE VIEW v_TopDishes AS
SELECT
    d.Name,
    SUM(od.Quantity) AS TotalSold
FROM OrderDetails od
    JOIN Dishes d ON od.DishID = d.ID
GROUP BY od.DishID
ORDER BY TotalSold DESC
LIMIT 10;

CREATE OR REPLACE
VIEW v_BranchPerformance AS
SELECT
    b.BranchNO,
    b.CityName,
    COUNT(DISTINCT o.OrderNO) AS OrdersHandled,
    SUM(o.Price)             AS TotalRevenue
FROM
    Branches b
    LEFT JOIN
    OfferedDishes odf ON b.BranchNO = odf.BranchNO
    LEFT JOIN
    OrderDetails od ON odf.DishID   = od.DishID
    LEFT JOIN
    Orders o ON o.OrderNO    = od.OrderNO
GROUP BY
  b.BranchNO,
  b.CityName;

-- 7. Stored Procedures

DELIMITER $$
CREATE PROCEDURE PlaceOrder(
  IN p_CustID   INT,
  IN p_Date     DATE,
  IN p_Time     TIME,
  IN p_Delivery TIME,
  IN p_OnTime   BOOLEAN,
  IN p_Comment  TEXT,
  IN p_Price    DECIMAL
(10,2)
)
BEGIN
    INSERT INTO Orders
        (CustomerID, Date, Time, DeliveryTime, OnTime, Comment, Price)
    VALUES
        (p_CustID, p_Date, p_Time, p_Delivery, p_OnTime, p_Comment, p_Price);
    SELECT LAST_INSERT_ID() AS NewOrderNO;
END
$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PlaceFullOrder(
  IN p_CustID   INT,
  IN p_Date     DATE,
  IN p_Time     TIME,
  IN p_Delivery TIME,
  IN p_OnTime   BOOLEAN,
  IN p_Comment  TEXT,
  IN p_Price    DECIMAL
(10,2),
  IN p_DishID   INT,
  IN p_Quantity INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

INSERT INTO Orders
    (CustomerID, Date, Time, DeliveryTime, OnTime, Comment, Price)
VALUES
    (p_CustID, p_Date, p_Time, p_Delivery, p_OnTime, p_Comment, p_Price);

SET @order_id = LAST_INSERT_ID();

INSERT INTO OrderDetails
    (OrderNO, DishID, Quantity)
VALUES
    (@order_id, p_DishID, p_Quantity);

COMMIT;
END $$
DELIMITER ;

-- 8. Triggers

DELIMITER $$
CREATE TRIGGER trg_after_employee_insert
AFTER
INSERT ON
Employee
FOR
EACH
ROW
BEGIN
    UPDATE Branches
  SET NumberOfEmployees = NumberOfEmployees + 1
  WHERE BranchNO = NEW.BranchNO;
END
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_prevent_dish_delete
BEFORE
DELETE ON Dishes
FOR EACH
ROW
BEGIN
    IF EXISTS (SELECT 1
    FROM OrderDetails
    WHERE DishID = OLD.ID) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT
    = 'Cannot delete dish linked to orders';
END
IF;
END $$
DELIMITER ;

-- 9. Event Scheduler (Auto-cleanup)

SET GLOBAL event_scheduler
= ON;

CREATE EVENT
IF NOT EXISTS auto_clean_null_orders
ON SCHEDULE EVERY 1 DAY
DO
DELETE FROM Orders
  WHERE Price IS NULL
    AND Date < CURDATE();

-- 10. Indexes & Constraints (remaining)

CREATE INDEX
IF NOT EXISTS idx_orders_date    ON Orders
(Date);
CREATE INDEX
IF NOT EXISTS idx_customer_email ON Customer
(EmailAddress);
CREATE INDEX
IF NOT EXISTS idx_offered_branch ON OfferedDishes
(BranchNO);
CREATE INDEX
IF NOT EXISTS idx_offered_dish   ON OfferedDishes
(DishID);

-- 11. MySQL Users & Grants

CREATE USER
IF NOT EXISTS 'app_customer'@'localhost' IDENTIFIED BY 'cust_pass';
CREATE USER
IF NOT EXISTS 'app_employee'@'localhost' IDENTIFIED BY 'emp_pass';
CREATE USER
IF NOT EXISTS 'app_manager'@'localhost'  IDENTIFIED BY 'mgr_pass';

GRANT SELECT, INSERT ON RestaurantManagementDB.Customer     TO 'app_customer'@'localhost';
GRANT SELECT, INSERT ON RestaurantManagementDB.Orders       TO 'app_customer'@'localhost';

GRANT SELECT, INSERT, UPDATE ON RestaurantManagementDB.Dishes       TO 'app_employee'@'localhost';
GRANT SELECT, INSERT, UPDATE ON RestaurantManagementDB.OrderDetails TO 'app_employee'@'localhost';

GRANT ALL PRIVILEGES ON RestaurantManagementDB.* TO 'app_manager'@'localhost';

FLUSH PRIVILEGES;
