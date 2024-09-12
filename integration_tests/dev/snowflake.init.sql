use role sysadmin;
use warehouse wh_compute;
create or replace database audit_helper_ext with comment = 'Database for audit_helper_ext';

use role accountadmin;
create or replace resource monitor rm_audit_helper_ext with
  credit_quota = 1
  frequency = daily
  start_timestamp = immediately
  notify_users = ("<YOUR_USER>")
  triggers
    on 100 percent do suspend_immediate
;

create or replace warehouse wh_audit_helper_ext with
  warehouse_type = 'standard'
  warehouse_size = 'xsmall'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true
  resource_monitor = rm_audit_helper_ext
  comment = 'Warehouse for audit_helper_ext';

use role securityadmin;
create or replace role role_audit_helper_ext with comment = 'Role for audit_helper_ext';

grant usage on warehouse wh_audit_helper_ext to role role_audit_helper_ext;
grant usage on database audit_helper_ext to role role_audit_helper_ext;
grant all privileges on database audit_helper_ext to role role_audit_helper_ext;
grant all privileges on all schemas in database audit_helper_ext to role role_audit_helper_ext;
grant all privileges on future schemas in database audit_helper_ext to role role_audit_helper_ext;
grant all privileges on all tables in database audit_helper_ext to role role_audit_helper_ext;
grant all privileges on future tables in database audit_helper_ext to role role_audit_helper_ext;
grant all privileges on all views in database audit_helper_ext to role role_audit_helper_ext;
grant all privileges on future views in database audit_helper_ext to role role_audit_helper_ext;
grant usage, create schema on database audit_helper_ext to role role_audit_helper_ext;
grant role role_audit_helper_ext to role sysadmin;

use role role_audit_helper_ext;
use database audit_helper_ext;
