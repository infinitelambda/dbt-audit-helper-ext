-- Initialize PostgreSQL database for dbt audit helper testing
-- This script runs automatically when the container starts

-- Create schemas
CREATE SCHEMA IF NOT EXISTS audit_helper_ext;
CREATE SCHEMA IF NOT EXISTS audit_helper_ext_log;

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA audit_helper_ext TO dbt_user;
GRANT ALL PRIVILEGES ON SCHEMA audit_helper_ext_log TO dbt_user;
GRANT ALL PRIVILEGES ON DATABASE audit_helper_ext TO dbt_user;

-- Set default schema search path
ALTER DATABASE audit_helper_ext SET search_path TO audit_helper_ext, public;
