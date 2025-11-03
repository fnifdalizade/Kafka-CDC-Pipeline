SQL Server → Debezium → Kafka CDC Pipeline

This project implements a real-time Change Data Capture (CDC) pipeline that streams INSERT, UPDATE, and DELETE events from Microsoft SQL Server to Apache Kafka using Debezium and Kafka Connect. Docker is used to build a reproducible local streaming environment with a Kafka UI for monitoring.

Objective

Enable SQL Server CDC and build a production-style streaming pipeline that captures database changes and publishes them to Kafka topics in real time. This simulates enterprise-grade data integration for event-driven systems, analytics pipelines, and microservices communication.

Architecture
SQL Server (CDC Enabled)
        ↓
Debezium (Kafka Connect)
        ↓
Kafka Topics
        ↓
Kafka UI / Stream Consumers

Requirements

Docker & Docker Compose

SQL Server (local or network)

Required ports:

1433 – SQL Server

9092 / 29092 – Kafka

2181 – Zookeeper

7083 – Kafka Connect API

8081 – Kafka UI

SQL Server Setup
Enable CDC at DB level
IF DB_ID('DemoDB') IS NULL
  CREATE DATABASE DemoDB;
GO

USE DemoDB;
EXEC sys.sp_cdc_enable_db;

Create table & enable CDC
CREATE TABLE dbo.Customers(
  Id INT IDENTITY PRIMARY KEY,
  Name NVARCHAR(100) NOT NULL,
  Email NVARCHAR(200) UNIQUE,
  CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME(),
  UpdatedAt DATETIME2 NULL
);

EXEC sys.sp_cdc_enable_table
  @source_schema = 'dbo',
  @source_name = 'Customers',
  @supports_net_changes = 1;


Test insert:

INSERT INTO dbo.Customers(Name, Email) VALUES ('Test2', 'Test2@example.com');

Docker Environment

A multi-container environment is deployed using Docker Compose, including:

Zookeeper

Kafka broker

Kafka Connect (Debezium)

Kafka UI

Start services:

docker-compose up -d

Debezium Connector Setup

Create connector via Kafka Connect REST API:

curl -X POST http://localhost:7083/connectors \
-H "Content-Type: application/json" \
-d @connector.json


connector.json

{
  "name": "sql-server-cdc-connector",
  "config": {
    "connector.class": "io.debezium.connector.sqlserver.SqlServerConnector",
    "database.hostname": "192.168.0.43",
    "database.port": "1433",
    "database.user": "cdc",
    "database.password": "Strong_Passw0rd!2025",
    "database.dbname": "DemoDB",
    "database.server.name": "DESKTOP-TTTT",
    "table.include.list": "dbo.Customers",
    "snapshot.mode": "initial"
  }
}

Verifying CDC Events

Kafka UI:

http://localhost:8081


Topic example:
DESKTOP-TTTT.dbo.Customers

Sample event
{
  "op": "c",
  "after": {
    "Id": 5,
    "Name": "Test2",
    "Email": "Test2@example.com"
  }
}

op	Meaning
c	Create
u	Update
d	Delete
Cleanup (optional)
EXEC sys.sp_cdc_cleanup_change_table 
  @capture_instance = 'dbo_Customers',
  @low_water_mark = NULL;

Results

The pipeline successfully:

Captures SQL Server changes using CDC

Streams events to Kafka topics via Debezium

Displays them in Kafka UI in real time

Supports snapshot and incremental streaming

Key Learnings

SQL Server CDC internals

Debezium connector configuration

Kafka Connect operations

Real-time streaming architecture

Docker-based data pipeline deployment

Future Improvements

Kafka → PostgreSQL sink connector

Kafka Streams / Flink data processing

Monitoring with Prometheus & Grafana

Kubernetes deployment

Data Lake integration (S3 / Delta Lake / Iceberg)

Repository Structure
/cdc-sqlserver-kafka/
 ├─ docker-compose.yml
 ├─ connector.json
 ├─ sql/
 │   └─ mssql_cdc_setup.sql
 ├─ screenshots/
 └─ README.md
