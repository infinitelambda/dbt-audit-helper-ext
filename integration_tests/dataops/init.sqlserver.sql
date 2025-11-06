-- Initialize SQL Server database for dbt audit helper testing
-- This script runs after the container starts

-- Create database if not exists
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'audit_helper_ext')
BEGIN
    CREATE DATABASE audit_helper_ext;
END
GO

USE audit_helper_ext;
GO

-- Create login and user
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'dbt_user')
BEGIN
    CREATE LOGIN dbt_user WITH PASSWORD = 'YourStrong@Passw0rd';
END
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'dbt_user')
BEGIN
    CREATE USER dbt_user FOR LOGIN dbt_user;
END
GO

-- Grant permissions to dbt_user
ALTER ROLE db_owner ADD MEMBER dbt_user;
GO

-- Create schemas
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'audit_helper_ext')
BEGIN
    EXEC('CREATE SCHEMA audit_helper_ext');
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'audit_helper_ext_log')
BEGIN
    EXEC('CREATE SCHEMA audit_helper_ext_log');
END
GO

-- Grant schema permissions
GRANT CONTROL ON SCHEMA::audit_helper_ext TO dbt_user;
GRANT CONTROL ON SCHEMA::audit_helper_ext_log TO dbt_user;
GO
