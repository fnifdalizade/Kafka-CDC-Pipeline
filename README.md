# SQL Server → Debezium → Kafka CDC Pipeline

This project implements a real-time Change Data Capture (CDC) pipeline
that streams **INSERT**, **UPDATE**, and **DELETE** events from
**Microsoft SQL Server** to **Apache Kafka** using **Debezium** and
**Kafka Connect**. Docker is used to build a reproducible local
streaming environment with a Kafka UI for monitoring.


## Objective

Enable SQL Server CDC and build a production-style streaming pipeline
that captures database changes and publishes them to Kafka topics in
real time.

This simulates enterprise-grade data integration for:

-   Event-driven systems\
-   Analytics pipelines\
-   Microservices communication


## Architecture

    SQL Server (CDC Enabled)
            ↓
    Debezium (Kafka Connect)
            ↓
    Kafka Topics
            ↓
    Kafka UI / Stream Consumers


## Requirements

-   Docker & Docker Compose
-   SQL Server

### Required Ports

  Service         Port
  --------------- --------------
  SQL Server      1433
  Kafka           9092 / 29092
  Zookeeper       2181
  Kafka Connect   7083
  Kafka UI        8081


## SQL Server Setup

### Enable CDC at DB level

``` sql
IF DB_ID('DemoDB') IS NULL
  CREATE DATABASE DemoDB;
GO

USE DemoDB;
EXEC sys.sp_cdc_enable_db;
```

### Create table & enable CDC

``` sql
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
```

### Test insert

``` sql
INSERT INTO dbo.Customers(Name, Email) VALUES ('Test2', 'Test2@example.com');
```


## Docker Environment

The following services run in Docker:

-   Zookeeper
-   Kafka Broker
-   Kafka Connect (Debezium)
-   Kafka UI

Run:

``` bash
docker-compose up -d
```


## Debezium Connector Setup

``` bash
curl -X POST http://localhost:7083/connectors -H "Content-Type: application/json" -d @connector.json
```

### `connector.json`

``` json
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
```


## Verifying CDC Events

Open Kafka UI:\
`http://localhost:8081`

Topic:\
`DESKTOP-TTTT.dbo.Customers`

### Sample event

``` json
{
  "op": "c",
  "after": {
    "Id": 5,
    "Name": "Test2",
    "Email": "Test2@example.com"
  }
}
```

  op    Meaning
  ----- ---------
  `c`   Create
  `u`   Update
  `d`   Delete




## Future Improvements

-   Kafka → PostgreSQL sink connector
-   Kafka Streams / Flink
-   Prometheus & Grafana monitoring
-   Kubernetes deployment
-   S3 / Delta Lake / Iceberg integration

## Repository Structure

    /cdc-sqlserver-kafka/
     ├─ docker-compose.yml
     ├─ connector.json
     ├─ sql/
     │   └─ mssql_cdc_setup.sql
     ├─ screenshots/
     └─ README.md
