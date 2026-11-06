# QSR Transactions Analytics

An end-to-end data pipeline that ingests 5M QSR (Quick Service Restaurant)
credit/debit transactions from the **Snowflake Marketplace**, transforms
them through a **layered dbt project** (staging → intermediate → marts),
and serves three executive dashboards in **Power BI**.

The project demonstrates a full modern-data-stack workflow — from
warehouse setup and role-based access control, through dimensional
modeling and testing, to BI consumption — built as production-grade
infrastructure rather than a tutorial exercise.

![Architecture](docs/architecture.png)

---

## What it answers

Three dashboards cover the questions QSR operations and marketing teams
actually ask:

| Dashboard | Business question |
|-----------|-------------------|
| **1. Executive Overview** | Total revenue, trend, consumer-vs-anonymous split, top merchants, geographic footprint |
| **2. Merchant Intelligence** | Which brands and categories drive revenue, how concentrated is it, where do they win |
| **3. Consumer Behavior** | Who spends, when, and how it differs by generation and payment method |

---

## Architecture
