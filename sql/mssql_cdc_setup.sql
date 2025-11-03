IF DB_ID('DemoDB') IS NULL
BEGIN
  CREATE DATABASE DemoDB;
END
GO

USE DemoDB
GO

SELECT 1 FROM sys.databases WHERE name = 'DemoDB' AND is_cdc_enabled = 1;
-- Enable CDC
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DemoDB' AND is_cdc_enabled = 1)
BEGIN
  EXEC sys.sp_cdc_enable_db;
END
GO

  CREATE TABLE dbo.Customers(
    Id            INT IDENTITY(1,1) PRIMARY KEY,
    Name          NVARCHAR(100) NOT NULL,
    Email         NVARCHAR(200) UNIQUE NULL,
    CreatedAt     DATETIME2      DEFAULT SYSUTCDATETIME(),
    UpdatedAt     DATETIME2      NULL
  );

  INSERT INTO dbo.Customers(Name, Email) VALUES
  (N'Test2',  N'Test2@example.com');
GO

select * from dbo.Customers;

delete from dbo.Customers where id = 4;

-- Enable CDC on table level
IF NOT EXISTS (SELECT 1 FROM sys.tables t 
               JOIN sys.schemas s ON t.schema_id=s.schema_id
               WHERE t.name='Customers' AND s.name='dbo'
                 AND t.is_tracked_by_cdc = 1)
BEGIN
  EXEC sys.sp_cdc_enable_table
       @source_schema = N'dbo',
       @source_name   = N'Customers',
       @role_name     = NULL,                -- istəsəniz rol verə bilərsiniz
       @supports_net_changes = 1;
END
GO


IF OBJECT_ID('dbo.debezium_signal','U') IS NULL
BEGIN
  CREATE TABLE dbo.debezium_signal (
    id        NVARCHAR(64) PRIMARY KEY,
    type      NVARCHAR(32) NOT NULL,
    data      NVARCHAR(2048) NULL
  );
END
GO

