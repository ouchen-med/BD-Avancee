# BD-Avancee



# 🎬 The Pagila Sample Database for PostgreSQL

This repository contains the essential resources and step-by-step instructions for setting up and exploring the **Pagila** sample database on PostgreSQL. Pagila is a port of the classic Sakila database, designed to simulate a DVD rental store, making it an excellent tool for practicing complex SQL queries and understanding relational database concepts.

---

## ⚙️ 1. Prerequisites and Installation

To get started, you'll need to have PostgreSQL installed on your system.

### 1.1. Installing PostgreSQL on Windows

For a comprehensive guide on setting up PostgreSQL on a Windows machine, please refer to the attached document:

* [**PostgreSQL on Windows Installation Guide.pdf**](PostgreSQL%20on%20Windows%20Installation%20Guide.pdf)

### 1.2. Pagila Files

Ensure that the main Pagila files (`pagila-schema.sql` and `pagila-data.sql`) are available in your repository or local working directory.

---

## 🚀 2. Setting Up the Pagila Database

Once PostgreSQL is installed, you can create and populate the database using the `psql` command-line utility.

### Step 1: Create the Database

Open your terminal or `psql` interface and create a new database named `pagila`:

```bash
CREATE DATABASE pagila;