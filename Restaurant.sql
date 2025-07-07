-- 1. Create Database
CREATE DATABASE University;
USE University;

-- 2. Drop Table Example
-- DROP TABLE Employees;

-- 3. Truncate Table Example
-- TRUNCATE TABLE Employees;

-- 4. Alter Table Examples
-- Add a column
-- ALTER TABLE Employees ADD hire_date DATE;

-- Modify a column
-- ALTER TABLE Employees MODIFY name VARCHAR(100);

-- Drop a column
-- ALTER TABLE Employees DROP COLUMN hire_date;

-- Rename a column
-- ALTER TABLE Employees RENAME COLUMN emp_name TO full_name;

-- Add a constraint
-- ALTER TABLE Employees ADD CONSTRAINT unique_email UNIQUE (email);

-- Drop a constraint
-- ALTER TABLE Employees DROP CONSTRAINT unique_email;

-- Rename a table
-- ALTER TABLE Employees RENAME TO Staff;

-- 5. Table Creation with Constraints

-- Students Table
CREATE TABLE Students (
    student_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    age INT CHECK (age >= 18)
);

-- Departments Table
CREATE TABLE  Departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
);

-- Courses Table
CREATE TABLE Courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(100),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id)
);

-- 6. Constraint Examples

-- NOT NULL Example
CREATE TABLE  Users (
    user_id INT,
    username VARCHAR(50) NOT NULL
);

-- UNIQUE Constraint Example
CREATE TABLE  Customers (
    customer_id INT,
    email VARCHAR(100) UNIQUE
);

-- PRIMARY KEY Example
CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100)
);

-- FOREIGN KEY Example
CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- CHECK Constraint Example
CREATE TABLE Employees (
    emp_id INT,
    age INT CHECK (age >= 18)
);

-- DEFAULT Constraint Example
CREATE TABLE  Accounts (
    acc_id INT,
    status VARCHAR(20) DEFAULT 'active'
);

-- 7. Relationships / Mapping

-- One-to-One Example: Persons ↔ Passports
CREATE TABLE  Persons (
    person_id INT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE  Passports (
    passport_id INT PRIMARY KEY,
    person_id INT UNIQUE,
    FOREIGN KEY (person_id) REFERENCES Persons(person_id)
);

-- One-to-Many & Many-to-One Example: Departments → Employees
CREATE TABLE Employees_Relational (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id)
);

-- Many-to-Many Example: Students ↔ Courses through Enrollments
CREATE TABLE  Enrollments (
    student_id INT,
    course_id INT,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);
