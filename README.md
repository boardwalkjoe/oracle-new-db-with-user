# oracle-new-db-with-user
c# Oracle 19c Database Setup Instructions

This guide explains how to use the `setup_database.sql` script to create a new Pluggable Database (PDB) and application user in Oracle 19c Enterprise Edition running on Docker.

## Prerequisites

- Oracle 19c Enterprise Edition running in Docker
- Access to the container with SYSDBA privileges
- Basic knowledge of SQL*Plus commands

## Quick Setup

### 1. Prepare the Script

First, customize the variables at the top of `setup_database.sql` to match your requirements:

```sql
DEFINE pdb_name = 'NEWPDB'                    -- Your database name
DEFINE pdb_admin_user = 'PDBADMIN'            -- PDB administrator username
DEFINE pdb_admin_password = 'SecurePassword123' -- PDB admin password
DEFINE app_user = 'APPUSER'                   -- Application user name
DEFINE app_user_password = 'AppPassword123'   -- Application user password
DEFINE datafile_path = '/opt/oracle/oradata/XE' -- Database files location
```

### 2. Copy Script to Docker Container

```bash
# Copy the SQL script to your Oracle container
docker cp setup_database.sql <container_name>:/tmp/

# Example:
docker cp setup_database.sql oracle19c:/tmp/
```

### 3. Execute the Script

#### Option A: Direct Execution
```bash
# Execute the script directly
docker exec -it <container_name> sqlplus sys/oracle@localhost:1521/XE as sysdba @/tmp/setup_database.sql

# Example:
docker exec -it oracle19c sqlplus sys/oracle@localhost:1521/XE as sysdba @/tmp/setup_database.sql
```

#### Option B: Interactive Session
```bash
# Start an interactive SQL*Plus session
docker exec -it <container_name> sqlplus sys/oracle@localhost:1521/XE as sysdba

# Then run the script from within SQL*Plus
SQL> @/tmp/setup_database.sql
```

## What the Script Does

The script performs these operations in sequence:

1. **Connects to Root Container** - Establishes connection as SYSDBA
2. **Creates Pluggable Database** - Creates a new PDB with specified name
3. **Opens the PDB** - Makes the database available for use
4. **Sets Auto-Start** - Configures PDB to start automatically
5. **Creates Tablespaces** - Sets up dedicated data and temp tablespaces
6. **Creates Application User** - Creates user with appropriate privileges
7. **Grants Permissions** - Assigns necessary roles and privileges
8. **Verifies Setup** - Runs validation queries to confirm success

## Expected Output

You should see output similar to this:

```
Connected.

NAME      CON_ID
--------- ----------
XE             1

CON_NAME
------------------------------
CDB$ROOT

Pluggable database created.

Pluggable database altered.

Pluggable database altered.

PDB_NAME    STATUS
----------- ----------
NEWPDB      NORMAL

Session altered.

CON_NAME
------------------------------
NEWPDB

Tablespace created.

Tablespace created.

User created.

Grant succeeded.
[... additional grant messages ...]

USERNAME    DEFAULT_TABLESPACE    TEMPORARY_TABLESPACE    ACCOUNT_STATUS
----------- -------------------- ----------------------- --------------
APPUSER     APP_DATA             APP_TEMP                OPEN

========================================
Database Setup Complete!
========================================
PDB Name: NEWPDB
PDB Admin User: PDBADMIN
Application User: APPUSER

Connection String Examples:
- Application User: APPUSER/AppPassword123@localhost:1521/NEWPDB
- PDB Admin: PDBADMIN/SecurePassword123@localhost:1521/NEWPDB
```

## Testing the Setup

### 1. Test Application User Connection

```bash
# Connect as the application user
docker exec -it <container_name> sqlplus APPUSER/AppPassword123@localhost:1521/NEWPDB
```

### 2. Create a Test Table

```sql
-- Once connected as APPUSER, test table creation
CREATE TABLE test_table (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    created_date DATE DEFAULT SYSDATE
);

-- Insert test data
INSERT INTO test_table (id, name) VALUES (1, 'Test Record');
COMMIT;

-- Query the data
SELECT * FROM test_table;
```

### 3. Verify Privileges

```sql
-- Check granted system privileges
SELECT privilege FROM user_sys_privs ORDER BY privilege;

-- Check granted roles
SELECT granted_role FROM user_role_privs ORDER BY granted_role;
```

## Customization Options

### Database Sizing

Modify tablespace sizes based on your needs:

```sql
-- In the script, adjust these values:
SIZE 100M           -- Initial size (change to 500M for larger apps)
AUTOEXTEND ON 
NEXT 10M            -- Growth increment (change to 50M for faster growth)
MAXSIZE 1G          -- Maximum size (change to 10G for larger capacity)
```

### Additional Privileges

Add more privileges for advanced applications:

```sql
-- Add these grants after the existing ones:
GRANT CREATE MATERIALIZED VIEW TO &app_user;
GRANT CREATE DATABASE LINK TO &app_user;
GRANT CREATE JOB TO &app_user;
GRANT EXECUTE ON DBMS_STATS TO &app_user;
```

### Multiple Users

To create additional users, add these sections:

```sql
-- Create additional application user
DEFINE app_user2 = 'APPUSER2'
DEFINE app_user2_password = 'AppPassword2'

CREATE USER &app_user2
IDENTIFIED BY &app_user2_password
DEFAULT TABLESPACE app_data
TEMPORARY TABLESPACE app_temp
QUOTA UNLIMITED ON app_data;

-- Grant same privileges as first user
GRANT CREATE SESSION TO &app_user2;
GRANT CONNECT TO &app_user2;
GRANT RESOURCE TO &app_user2;
```

## Troubleshooting

### Common Errors

#### 1. "ORA-01031: insufficient privileges"
```bash
# Ensure you're connecting as SYSDBA
docker exec -it <container_name> sqlplus sys/oracle@localhost:1521/XE as sysdba
```

#### 2. "ORA-00959: tablespace does not exist"
```bash
# Check if datafile path exists in container
docker exec <container_name> ls -la /opt/oracle/oradata/XE/
```

#### 3. "ORA-65011: Pluggable database does not exist"
```sql
-- Check existing PDBs
SELECT pdb_name, status FROM dba_pdbs;
```

#### 4. Script hangs or fails
```bash
# Check container logs
docker logs <container_name>

# Ensure database is fully started
docker exec <container_name> lsnrctl status
```

### Cleanup (if needed)

If you need to remove the created database:

```sql
-- Connect as SYSDBA to root container
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Close and drop the PDB
ALTER PLUGGABLE DATABASE NEWPDB CLOSE;
DROP PLUGGABLE DATABASE NEWPDB INCLUDING DATAFILES;
```

## Connection Information

After successful setup, use these connection details:

| User Type | Username | Password | Connect String |
|-----------|----------|----------|----------------|
| Application User | `APPUSER` | `AppPassword123` | `APPUSER/AppPassword123@localhost:1521/NEWPDB` |
| PDB Admin | `PDBADMIN` | `SecurePassword123` | `PDBADMIN/SecurePassword123@localhost:1521/NEWPDB` |
| System Admin | `sys` | `oracle` | `sys/oracle@localhost:1521/XE as sysdba` |

## Security Notes

⚠️ **Important**: Change default passwords before using in production!

1. Update passwords in the script before running
2. Use strong passwords (minimum 12 characters, mixed case, numbers, special characters)
3. Grant only necessary privileges for your application
4. Consider using Oracle Wallet for password management in production

## Next Steps

1. **Test your application** - Connect using your preferred database client
2. **Create application schema** - Add your tables, indexes, and procedures
3. **Set up monitoring** - Configure Oracle Enterprise Manager or similar tools
4. **Plan backups** - Implement regular backup strategy
5. **Security hardening** - Review and implement additional security measures
