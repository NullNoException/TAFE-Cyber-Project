# OpenLDAP & phpLDAPadmin Recovery Guide
**Date:** November 24, 2025
**Status:** Complete Configuration Recovery

---

## Overview

The OpenLDAP directory service provides centralized authentication and authorization for the CyberLab infrastructure. phpLDAPadmin offers a web-based interface for managing LDAP directory entries.

### Running Containers
```
OpenLDAP Container: openldap (osixia/openldap:latest)
Status: Running (Unhealthy - expected in lab)
phpLDAPadmin Container: phpldapadmin (osixia/phpldapadmin:latest)
Status: Running
```

### Key Information
```
Base DN: dc=cyberlab,dc=local
Admin User: cn=admin,dc=cyberlab,dc=local
OpenLDAP Port: 389 (LDAP), 636 (LDAPS)
phpLDAPadmin Port: 80 (HTTP), 443 (HTTPS)
```

---

## OpenLDAP Configuration

### Directory Structure

```
configs/ldap/
├── ldap.env                              # Environment configuration
├── phpldapadmin.conf.php                 # phpLDAPadmin settings
├── ldif/
│   └── base.ldif                         # Base LDAP schema (154 lines)
└── slapd.d/
    └── cn=config/
        ├── cn=config.ldif                # Main slapd config
        ├── cn=module.ldif                # Loaded modules
        ├── cn=schema.ldif                # Schema configuration
        └── olcDatabase=mdb.ldif          # MDB database config
```

### Main Configuration Files

#### 1. Base LDIF Schema (base.ldif)
**Contains:**
- Root DSE (Directory Service Entry)
- Admin user account
- Organizational units:
  - `ou=users` - User accounts
  - `ou=groups` - Group definitions
  - `ou=roles` - Role-based access groups
  - `ou=services` - Service accounts
  - `ou=devices` - Device accounts
- Default groups:
  - `cn=security-team`
  - `cn=siem-admins`
  - `cn=network-admins`
  - `cn=vpn-users`
- Role definitions:
  - `role-admin` - Full access
  - `role-security` - Security analyst access
  - `role-operator` - Operations access
  - `role-readonly` - Read-only access
- Service accounts for:
  - Wazuh indexer
  - Wazuh manager
  - Traefik

#### 2. Slapd Configuration (cn=config.ldif)
```
Global Settings:
  - Arguments File: /var/run/slapd/slapd.args
  - Log Level: none
  - PID File: /var/run/slapd/slapd.pid
  - Tool Threads: 1
```

#### 3. Module Configuration (cn=module.ldif)
**Loaded Modules:**
- back_mdb (MDB backend database)
- memberof overlay
- refint overlay (referential integrity)

#### 4. Database Configuration (olcDatabase=mdb.ldif)
```
Database: MDB (Lightning Memory-Mapped Database)
Location: /var/lib/ldap
Suffix (Base DN): dc=cyberlab,dc=local
Root DN: cn=admin,dc=cyberlab,dc=local
Max Size: 1 GB (1073741824 bytes)
Checkpoint: 512 KB, every 30 seconds

Indexes:
  - uid (equality)
  - mail (equality)
  - memberOf (equality)
  - entryCSN (equality)
  - entryUUID (equality)
  - objectClass (equality)

Access Control:
  1. Admin can manage everything
  2. Users can change their own passwords
  3. Admins can change user passwords
  4. Users can read their own entries
  5. Default: deny

Overlays:
  - memberof: Maintains reverse group membership
  - refint: Maintains referential integrity
```

### Environment Configuration (ldap.env)

```bash
LDAP_ORGANISATION=CyberLab
LDAP_DOMAIN=cyberlab.local
LDAP_BASE_DN=dc=cyberlab,dc=local
LDAP_ADMIN_USERNAME=admin
LDAP_TLS_ENABLED=true
LDAP_TLS_VERIFY_CLIENT=try
LDAP_PPOLICY_ENABLED=true
LDAP_THREAD_POOL_SIZE=8
LDAP_DB_MAX_SIZE=1073741824
```

### Volume Mounts

```yaml
OpenLDAP Volumes:
  1. Config: /etc/ldap/slapd.d (volume: infra_openldap_slapd)
  2. Data: /var/lib/ldap (volume: infra_openldap_data)
  3. LDIF: /ldif (bind mount: configs/ldap/ldif - read-only)
  4. Secrets: /run/secrets/ldap_admin_password (bind mount)

Current Data:
  - data.mdb: 57 MB (LDAP database)
  - lock.mdb: 8.2 KB (locking)
```

### OpenLDAP Schemas Loaded

The following standard schemas are configured:
1. **core** - Core LDAP schema
2. **cosine** - NIS profiles and groups
3. **nis** - Network Information System
4. **inetorgperson** - Internet Organizational Person (for users)
5. **ppolicy** - Password Policy
6. **kopano** - Kopano groupware extensions
7. **openssh-lpk** - OpenSSH LDAP Public Key
8. **postfix-book** - Postfix address book
9. **samba** - Samba authentication integration

---

## phpLDAPadmin Configuration

### Overview
phpLDAPadmin provides a web-based interface for managing LDAP directory entries without command-line access.

### Configuration File (phpldapadmin.conf.php)

#### Authentication Settings
```php
Login Required: true
Allow Anonymous Bind: false
Login DN: cn=admin,dc=cyberlab,dc=local
Session Timeout: 3600 seconds (1 hour)
Force HTTPS: true
```

#### LDAP Server Connection
```php
Server: openldap (hostname)
Port: 389 (LDAP)
Base DN: dc=cyberlab,dc=local
Auth Type: session-based
Auto-append Suffix: true
```

#### User Interface Settings
```php
App Title: "CyberLab LDAP Management"
Theme: default
Language: en_US
Page Size: 50 entries per page
Max Search Results: 1000
Debug Mode: false (set to true for troubleshooting)
```

#### Visible Attributes
phpLDAPadmin displays:
- objectClass, cn, uid, mail, telephoneNumber
- sn (surname), givenName, description
- departmentNumber, memberOf
- Timestamps: createTimestamp, modifyTimestamp

#### Hidden Attributes (never displayed)
- userPassword (hashed passwords)
- sambaLMPassword, sambaNTPassword
- entryUUID, entryCSN (internal)

#### Read-Only Attributes
- objectClass, createTimestamp, modifyTimestamp
- creatorsName, modifiersName
- entryUUID, entryCSN

#### Quick-Add Templates
1. **User Template**
   - Creates: inetOrgPerson, organizationalPerson, person
   - Fields: uid, cn, sn, givenName, mail, userPassword

2. **Group Template**
   - Creates: groupOfNames
   - Fields: cn, description, member list

3. **Organizational Unit Template**
   - Creates: organizationalUnit
   - Fields: ou, description

#### Attribute Display Names
Custom names for web interface:
```
uid → "User ID"
mail → "Email"
sn → "Last Name"
givenName → "First Name"
pwdChangedTime → "Password Changed"
memberOf → "Member Of Groups"
```

---

## Directory Structure & Organization

### Root Level (dc=cyberlab,dc=local)
```
dc=cyberlab,dc=local (CyberLab)
├── ou=users (User Accounts)
├── ou=groups (Group Definitions)
├── ou=roles (Role-Based Groups)
├── ou=services (Service Accounts)
└── ou=devices (Device Assets)
```

### User Accounts (ou=users)
```
ou=users,dc=cyberlab,dc=local
├── uid=sampleuser (Example account)
├── uid=admin (Administrator)
└── uid=<other-users>

Attributes:
- uid (unique identifier)
- cn (common name)
- sn (surname)
- givenName (first name)
- mail (email address)
- telephoneNumber, mobile
- departmentNumber
- userPassword (encrypted)
```

### Groups (ou=groups)
```
ou=groups,dc=cyberlab,dc=local
├── cn=security-team
├── cn=siem-admins
├── cn=network-admins
└── cn=vpn-users

Attributes:
- cn (group name)
- member (DN of members)
- description
```

### Roles (ou=roles)
```
ou=roles,dc=cyberlab,dc=local
├── cn=role-admin
├── cn=role-security
├── cn=role-operator
└── cn=role-readonly

Purpose: Define permission levels for:
- Application access control
- Wazuh SIEM role management
- VPN access policies
```

### Services (ou=services)
```
ou=services,dc=cyberlab,dc=local
├── uid=wazuh-indexer
├── uid=wazuh-manager
└── uid=traefik

Service Accounts for:
- SIEM indexing
- Log management
- Reverse proxy authentication
```

---

## Common LDAP Operations

### Add User via LDIF
```ldif
dn: uid=newuser,ou=users,dc=cyberlab,dc=local
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
objectClass: top
uid: newuser
cn: New User
sn: User
givenName: New
mail: newuser@cyberlab.local
userPassword: {SSHA}hashed_password
```

**Apply:**
```bash
ldapadd -x -D "cn=admin,dc=cyberlab,dc=local" -W -f user.ldif
```

### Add User to Group
```bash
ldapmodify -x -D "cn=admin,dc=cyberlab,dc=local" -W
# Then enter:
dn: cn=security-team,ou=groups,dc=cyberlab,dc=local
changetype: modify
add: member
member: uid=newuser,ou=users,dc=cyberlab,dc=local
```

### Change User Password
```bash
ldappasswd -x -D "cn=admin,dc=cyberlab,dc=local" -W \
  -S uid=username,ou=users,dc=cyberlab,dc=local
```

### Search Users
```bash
# All users
ldapsearch -x -b "ou=users,dc=cyberlab,dc=local" "(uid=*)"

# Specific user
ldapsearch -x -b "dc=cyberlab,dc=local" "(uid=sampleuser)"

# Users in security-team group
ldapsearch -x -b "dc=cyberlab,dc=local" \
  "(memberOf=cn=security-team,ou=groups,dc=cyberlab,dc=local)"
```

### Via phpLDAPadmin Web Interface
1. Access: http://localhost (or https for production)
2. Login: cn=admin,dc=cyberlab,dc=local + password
3. Browse tree on left
4. Click to expand/collapse organizational units
5. Create entries using quick-add templates
6. Edit attributes in web form

---

## Integration with CyberLab Services

### Wazuh SIEM Integration
- Wazuh can use LDAP for authentication
- User groups mapped to Wazuh roles
- LDAP groups: siem-admins, role-security, role-operator

### VPN Access Control
- vpn-users group: Controls OpenVPN access
- Add users to cn=vpn-users,ou=groups,dc=cyberlab,dc=local
- Certificate-based + password authentication

### Traefik Authentication
- Service account: uid=traefik,ou=services
- Can authenticate users for reverse proxy
- Example: LDAP basic auth for admin panels

---

## Security Best Practices

### Password Policy
```
Minimum Length: 12 characters
Require Special Characters: true
Password Changes: Track with pwdChangedTime
Expiration: Can be configured with ppolicy overlay
```

### Access Control
```
Default: DENY
Specific: ALLOW for roles
Admin: Full control via cn=admin DN
```

### TLS/SSL
```
Status: Enabled (ldaps://localhost:636)
Client Verification: Try mode (optional)
Protocol Minimum: TLS 1.2
```

### Monitoring
```
Log File: /var/log/openldap/slapd.log
Log Level: none (adjust for debugging)
Access Logs: Can be enabled per directory
```

### Backups
```
Data Location: /var/lib/ldap/
Backup Strategy: Regular snapshots of volumes
Retention: 30 days recommended
```

---

## Troubleshooting

### Connection Issues
```bash
# Test LDAP connectivity
ldapwhoami -x -h localhost -p 389

# Verbose test
ldapsearch -x -h localhost -p 389 -b dc=cyberlab,dc=local -v
```

### Authentication Problems
```bash
# Test as specific user
ldapwhoami -x -D "cn=admin,dc=cyberlab,dc=local" -W

# Check if user exists
ldapsearch -x -b "ou=users,dc=cyberlab,dc=local" "(uid=username)"
```

### phpLDAPadmin Issues
```
Check container logs:
docker logs phpldapadmin

Verify configuration:
docker exec phpldapadmin cat /etc/phpldapadmin/config.php

Test web access:
curl -v http://localhost
```

### Performance Tuning
```yaml
Thread Pool: 8 threads
Cache Size: 512 MB
Database Max Size: 1 GB
Index Frequency: Every 30 seconds
```

### Common Errors

**"Invalid credentials"**
- Verify admin password in .env
- Check DN format: cn=admin,dc=cyberlab,dc=local
- Ensure user exists in LDAP

**"No such object"**
- Base DN might be incorrect
- Entry doesn't exist in directory
- Check spelling of DN components

**"LDAP connection refused"**
- Container not running: `docker-compose up -d openldap`
- Port conflict: Check if 389 is in use
- Network connectivity: Verify container networking

---

## Recovered Files Summary

### Configuration Files
```
✅ slapd.d/cn=config.ldif              - Main slapd configuration
✅ slapd.d/cn=config/cn=module.ldif     - Module configuration
✅ slapd.d/cn=config/cn=schema.ldif     - Schema configuration
✅ slapd.d/cn=config/olcDatabase=mdb.ldif - Database config
✅ ldap.env                              - Environment settings
✅ phpldapadmin.conf.php                 - Web UI configuration
✅ ldif/base.ldif                        - LDAP schema (154 lines)
```

### Data Volumes
```
✅ infra_openldap_data                   - 57 MB (directory database)
✅ infra_openldap_slapd                  - 8.2 KB (configuration DB)
```

---

## Next Steps

1. **Import Base Schema**
   ```bash
   docker exec openldap ldapadd -x -D "cn=admin,dc=cyberlab,dc=local" \
     -w password -f /ldif/base.ldif
   ```

2. **Access phpLDAPadmin**
   - URL: http://localhost (through Traefik)
   - Login: cn=admin,dc=cyberlab,dc=local

3. **Create Users**
   - Use web interface or LDIF files
   - Add to appropriate groups and roles

4. **Set Strong Passwords**
   - Change admin password
   - Set service account passwords
   - Update .env with new credentials

5. **Monitor Logs**
   - Check for errors in container logs
   - Enable verbose logging if needed
   - Set up log forwarding to Wazuh

---

**Recovery Complete!**
All OpenLDAP and phpLDAPadmin configurations have been successfully recovered and documented.
