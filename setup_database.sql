-- Oracle 19c Enterprise Edition Database and User Creation Script
-- Run this script as SYSDBA user

-- Variables (modify these as needed)
DEFINE pdb_name = 'NEWPDB'
DEFINE pdb_admin_user = 'PDBADMIN'
DEFINE pdb_admin_password = 'SecurePassword123'
DEFINE app_user = 'APPUSER'
DEFINE app_user_password = 'AppPassword123'
DEFINE datafile_path = '/opt/oracle/oradata/XE'

-- Connect as SYSDBA to the root container
CONNECT sys/oracle@localhost:1521/XE as sysdba

-- Show current container
SELECT name, con_id FROM v$database;
SHOW con_name;

-- Create a new Pluggable Database
CREATE PLUGGABLE DATABASE &pdb_name
ADMIN USER &pdb_admin_user IDENTIFIED BY &pdb_admin_password
FILE_NAME_CONVERT = ('pdbseed', '&pdb_name')
STORAGE (MAXSIZE 2G MAX_SHARED_TEMP_SIZE 100M);

-- Open the new PDB
ALTER PLUGGABLE DATABASE &pdb_name OPEN;

-- Set the PDB to automatically start
ALTER PLUGGABLE DATABASE &pdb_name SAVE STATE;

-- Verify PDB creation
SELECT pdb_name, status FROM dba_pdbs WHERE pdb_name = UPPER('&pdb_name');

-- Connect to the new PDB
ALTER SESSION SET CONTAINER = &pdb_name;

-- Verify we're in the correct container
SHOW con_name;

-- Create tablespace for application data
CREATE TABLESPACE app_data
DATAFILE '&datafile_path/&pdb_name/app_data01.dbf' 
SIZE 100M 
AUTOEXTEND ON 
NEXT 10M 
MAXSIZE 1G;

-- Create temporary tablespace for application
CREATE TEMPORARY TABLESPACE app_temp
TEMPFILE '&datafile_path/&pdb_name/app_temp01.dbf'
SIZE 50M
AUTOEXTEND ON
NEXT 5M
MAXSIZE 500M;

-- Create the application user
CREATE USER &app_user
IDENTIFIED BY &app_user_password
DEFAULT TABLESPACE app_data
TEMPORARY TABLESPACE app_temp
QUOTA UNLIMITED ON app_data;

-- Grant basic privileges to the application user
GRANT CREATE SESSION TO &app_user;
GRANT CREATE TABLE TO &app_user;
GRANT CREATE VIEW TO &app_user;
GRANT CREATE PROCEDURE TO &app_user;
GRANT CREATE SEQUENCE TO &app_user;
GRANT CREATE TRIGGER TO &app_user;
GRANT CREATE TYPE TO &app_user;
GRANT CREATE SYNONYM TO &app_user;

-- Grant additional useful privileges
GRANT SELECT_CATALOG_ROLE TO &app_user;
GRANT CONNECT TO &app_user;
GRANT RESOURCE TO &app_user;

-- Optional: Grant specific system privileges if needed
-- GRANT CREATE ANY TABLE TO &app_user;
-- GRANT ALTER ANY TABLE TO &app_user;
-- GRANT DROP ANY TABLE TO &app_user;

-- Verify user creation
SELECT username, default_tablespace, temporary_tablespace, account_status
FROM dba_users 
WHERE username = UPPER('&app_user');

-- Show granted privileges
SELECT grantee, privilege, admin_option
FROM dba_sys_privs 
WHERE grantee = UPPER('&app_user')
ORDER BY privilege;

-- Show granted roles
SELECT grantee, granted_role, admin_option, default_role
FROM dba_role_privs 
WHERE grantee = UPPER('&app_user')
ORDER BY granted_role;

-- Test connection (optional - uncomment to test)
-- CONNECT &app_user/&app_user_password@localhost:1521/&pdb_name

-- Create a sample table to verify everything works
-- CREATE TABLE test_table (
--     id NUMBER PRIMARY KEY,
--     name VARCHAR2(100),
--     created_date DATE DEFAULT SYSDATE
-- );

-- INSERT INTO test_table (id, name) VALUES (1, 'Test Record');
-- COMMIT;

-- SELECT * FROM test_table;

PROMPT
PROMPT ========================================
PROMPT Database Setup Complete!
PROMPT ========================================
PROMPT PDB Name: &pdb_name
PROMPT PDB Admin User: &pdb_admin_user
PROMPT Application User: &app_user
PROMPT 
PROMPT Connection String Examples:
PROMPT - Application User: &app_user/&app_user_password@localhost:1521/&pdb_name
PROMPT - PDB Admin: &pdb_admin_user/&pdb_admin_password@localhost:1521/&pdb_name
PROMPT 
PROMPT Remember to:
PROMPT 1. Change default passwords
PROMPT 2. Configure network access if needed
PROMPT 3. Set up backup strategy
PROMPT 4. Configure additional security as required
PROMPT ========================================
