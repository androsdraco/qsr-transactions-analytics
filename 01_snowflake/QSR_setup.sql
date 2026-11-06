-- ============================================================
--  QSR Transactions Analytics — Snowflake Environment Setup
-- ============================================================
--  Purpose:  Prepare Snowflake so dbt can read the Marketplace
--            share and write its models to a database we own.
--
--  Run as:   SECURITYADMIN  (inherits SYSADMIN, so it can
--            create databases *and* issue grants)
--  Idempotent: safe to re-run. Nothing will error or duplicate.
--
--  Assumptions:
--    • Warehouse  compute_wh            already exists
--    • User       Your User                 already exists
--    • Database   CREDITDEBIT_...       already mounted from
--                 Snowflake Marketplace (read-only share)
-- ============================================================


-- ── 1. ROLE & WAREHOUSE ACCESS ──────────────────────────────

USE ROLE SECURITYADMIN;

-- Create a dedicated, least-privilege role for the data pipeline.
-- Using a scoped role instead of ACCOUNTADMIN means:
--   • Power BI cannot accidentally alter source data
--   • Git history documents *exactly* what the pipeline needs
CREATE ROLE IF NOT EXISTS database_viewer;

-- Warehouse USAGE = permission to run queries on compute_wh.
-- Without this, the role can log in but every query fails.
GRANT USAGE ON WAREHOUSE compute_wh TO ROLE database_viewer;

-- Attach the role to the human user who will:
--   • run `dbt build`
--   • authenticate Power BI
-- (User must already exist — created separately, not in this script.)
GRANT ROLE database_viewer TO USER your_user;


-- ── 2. SOURCE ACCESS (Marketplace share, read-only) ─────────
--
-- IMPORTED PRIVILEGES is the *only* database-level grant that
-- works on a Snowflake Marketplace share. It grants read access
-- to every object the provider included in the share.
--
-- Notably: SELECT is NOT granted per-table. That is normal —
-- shares do not expose table-level grants, only IMPORTED PRIVILEGES.
-- Granting this also makes all shared schemas visible, so no
-- separate USAGE ON SCHEMA is required (a common misconception).
GRANT IMPORTED PRIVILEGES
    ON DATABASE CREDITDEBIT_TRANSACTIONS_FAST_FOOD_AND_QUICK_SERVICE_RESTAURANTS
    TO ROLE database_viewer;


-- ── 3. TARGET DATABASE (where dbt writes) ───────────────────
--
-- dbt must materialize models somewhere writable. The Marketplace
-- database is read-only, so we need a separate database we own.
-- This is the central design decision of the pipeline:
--   source  → read  from CREDITDEBIT_...     (shared, RO)
--   target  → write to   DBT_CREDIT_CARD     (ours, RW)
CREATE DATABASE IF NOT EXISTS DBT_CREDIT_CARD;

-- Single schema for all dbt output — models, tables, views.
-- Named to mirror the source schema for clarity, but it is
-- a different object in a different database.
CREATE SCHEMA IF NOT EXISTS DBT_CREDIT_CARD.SNOWFLAKE_MARKETPLACE;

-- Give the role permission to:
--   USAGE          → see the database and navigate into it
--   CREATE SCHEMA  → create additional schemas if dbt needs them
--                    (e.g. custom schemas via +schema: config)
GRANT USAGE, CREATE SCHEMA
    ON DATABASE DBT_CREDIT_CARD
    TO ROLE database_viewer;

-- Give the role permission to:
--   USAGE          → see this schema
--   CREATE TABLE   → materialize dbt models / snapshots
--   CREATE VIEW    → materialize dbt views (staging layer)
GRANT USAGE, CREATE TABLE, CREATE VIEW
    ON SCHEMA DBT_CREDIT_CARD.SNOWFLAKE_MARKETPLACE
    TO ROLE database_viewer;


-- ── 4. VERIFICATION ─────────────────────────────────────────
--
-- Confirm the role has what it needs before running dbt.
-- Expected output: three blocks — warehouse, database, schema —
-- plus one IMPORTED PRIVILEGES block on the source database.
SHOW GRANTS TO ROLE database_viewer;