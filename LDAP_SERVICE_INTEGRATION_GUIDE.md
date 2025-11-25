# LDAP Service Integration Guide - CyberLab Infrastructure

## Overview

This guide provides comprehensive instructions for integrating services with the OpenLDAP directory service in the CyberLab security infrastructure. All services use standardized authentication and authorization patterns.

## LDAP Server Details

### Connection Information

| Parameter | Value |
|-----------|-------|
| **Service Name** | OpenLDAP |
| **Container Hostname** | `openldap` |
| **Container IP** | `10.10.20.40` (internal_net) |
| **FQDN** | `ldap.cyberlab.local` |
| **LDAP Port** | `389` (unencrypted) |
| **LDAPS Port** | `636` (encrypted) |
| **Base DN** | `dc=cyberlab,dc=local` |
| **Admin DN** | `cn=admin,dc=cyberlab,dc=local` |
| **Admin Password** | `${LDAP_ADMIN_PASSWORD}` (from `.env`) |
| **Organization** | `CyberLab` |

### Network Configuration

The OpenLDAP service is available on the **internal_net** (10.10.20.0/24) and can be accessed from:

- **Internal Services**: Direct container-to-container communication via Docker DNS
- **Management Interfaces**: Via Traefik reverse proxy on FQDN: `ldap.cyberlab.local`
- **External Hosts**: Via port mappings (389 and 636)

---

## Service Integration Examples

### 1. **Rocket.Chat LDAP Integration**

#### Configuration Steps

1. **Access Rocket.Chat Admin Panel**
   - URL: `https://chat.cyberlab.local`
   - Login with admin credentials

2. **Navigate to LDAP Settings**
   - Path: `Administration` → `Workspace` → `LDAP`

3. **Configure LDAP Connection**

```yaml
Enable LDAP: Yes
LDAP Server: openldap  # or 10.10.20.40
Port: 389
Bind DN: cn=admin,dc=cyberlab,dc=local
Bind Password: ${LDAP_ADMIN_PASSWORD}
Base DN: dc=cyberlab,dc=local
User Search Filter: (&(objectClass=inetOrgPerson)(uid=#{username}))
User Search Scope: sub
Username Field: uid
Name Field: cn
Email Field: mail
```

4. **Test Connection**
   - Click "Test Connection" to verify
   - Ensure firewall allows 389/tcp between Rocket.Chat and OpenLDAP

#### Environment Variables (docker-compose)

```yaml
environment:
  - LDAP_ENABLED=true
  - LDAP_URL=ldap://openldap:389
  - LDAP_BIND_DN=cn=admin,dc=cyberlab,dc=local
  - LDAP_BIND_PASSWORD=${LDAP_ADMIN_PASSWORD}
  - LDAP_BASE_DN=dc=cyberlab,dc=local
  - LDAP_USER_SEARCH_FILTER=(&(objectClass=inetOrgPerson)(uid=#{username}))
```

#### Rocket.Chat Service Configuration

```yaml
rocketchat:
  environment:
    - LDAP_ENABLED=true
    - LDAP_URL=ldap://openldap:389
    - LDAP_BIND_DN=cn=admin,dc=cyberlab,dc=local
    - LDAP_BIND_PASSWORD=${LDAP_ADMIN_PASSWORD}
    - LDAP_BASE_DN=dc=cyberlab,dc=local
    - LDAP_USERNAME_FIELD=uid
    - LDAP_NAME_FIELD=cn
    - LDAP_EMAIL_FIELD=mail
    - LDAP_USER_SEARCH_FILTER=(&(objectClass=inetOrgPerson)(uid=#{username}))
    - LDAP_USER_SEARCH_SCOPE=sub
  depends_on:
    - openldap
```

---

### 2. **Nginx (Web Server) LDAP Integration**

#### Using nginx-ldap-module

```nginx
# /etc/nginx/conf.d/ldap-auth.conf

ldap_server ldap_backend {
  url ldap://openldap:389/dc=cyberlab,dc=local?uid?sub?(objectClass=inetOrgPerson);
  binddn "cn=admin,dc=cyberlab,dc=local";
  binddn_passwd "${LDAP_ADMIN_PASSWORD}";
  group_attribute uniqueMember;
  group_attribute_is_dn on;
  ssl_check_cert off;
  connection_timeout 10000;
  bind_timeout 10000;
  request_timeout 10000;
}

# Apply LDAP authentication to location
server {
  listen 80;
  server_name web.cyberlab.local;

  location /protected {
    auth_ldap "LDAP Authentication";
    auth_ldap_servers ldap_backend;
    proxy_pass http://upstream_backend;
  }
}
```

#### Docker Compose Configuration

```yaml
nginx:
  environment:
    - LDAP_SERVER=openldap
    - LDAP_PORT=389
    - LDAP_BIND_DN=cn=admin,dc=cyberlab,dc=local
    - LDAP_BIND_PASSWORD=${LDAP_ADMIN_PASSWORD}
    - LDAP_BASE_DN=dc=cyberlab,dc=local
  depends_on:
    - openldap
```

---

### 3. **PostgreSQL LDAP Integration**

#### Configuration Steps

PostgreSQL uses LDAP for authentication. Add to `postgresql.conf`:

```conf
# Enable LDAP authentication
ldap_host = openldap
ldap_port = 389
ldap_prefix = uid=
ldap_suffix = ,dc=cyberlab,dc=local
ldap_bind_dn = cn=admin,dc=cyberlab,dc=local
ldap_bind_passwd = ${LDAP_ADMIN_PASSWORD}
ldap_search_attr = uid
ldap_search_filter = (objectClass=inetOrgPerson)
```

#### PostgreSQL pg_hba.conf Configuration

```conf
# LDAP authentication method
host    all     all     10.10.20.0/24   ldap ldapserver=openldap ldapport=389 ldapbasedn="dc=cyberlab,dc=local" ldapbinddn="cn=admin,dc=cyberlab,dc=local" ldapbindpasswd="${LDAP_ADMIN_PASSWORD}" ldapsearchattribute=uid

# Example for specific user
host    testdb  cyberlab_user   10.10.20.0/24   ldap ldapserver=openldap ldapport=389
```

#### Docker Compose Configuration

```yaml
postgresql:
  environment:
    - POSTGRES_INITDB_ARGS=-c ldap_host=openldap -c ldap_port=389 -c ldap_prefix='uid=' -c ldap_suffix=',dc=cyberlab,dc=local'
  depends_on:
    - openldap
```

---

### 4. **Traefik LDAP Authentication**

#### Using Forward Auth with LDAP Provider

```yaml
# configs/traefik/dynamic.yml

http:
  middlewares:
    ldap-auth:
      forwardAuth:
        address: http://ldap-auth-service:8080/auth
        trustForwardHeader: true
        authResponseHeaders:
          - X-Remote-User
          - X-Remote-Groups

  routers:
    protected-service:
      rule: Host(`secure.cyberlab.local`)
      middlewares:
        - ldap-auth
      service: backend-service
      entryPoints:
        - websecure
      tls: {}
```

#### Alternative: Using External LDAP Auth Service

Deploy an LDAP authentication service that Traefik can forward requests to:

```yaml
ldap-auth-service:
  image: eryajf/ldap-auth:latest
  container_name: ldap-auth
  networks:
    - internal_net
  environment:
    - LDAP_HOST=openldap
    - LDAP_PORT=389
    - LDAP_BIND_DN=cn=admin,dc=cyberlab,dc=local
    - LDAP_BIND_PASSWORD=${LDAP_ADMIN_PASSWORD}
    - LDAP_BASE_DN=dc=cyberlab,dc=local
    - LDAP_FILTER=(&(objectClass=inetOrgPerson)(uid={0}))
  depends_on:
    - openldap
```

---

### 5. **Wazuh LDAP Integration**

#### Configuration Steps

1. **Edit Wazuh Configuration** (`/var/ossec/etc/ossec.conf`):

```xml
<ossec_config>
  <auth>
    <auth_method>ldap</auth_method>
    <auth_server>openldap</auth_server>
    <auth_port>389</auth_port>
    <auth_bind_dn>cn=admin,dc=cyberlab,dc=local</auth_bind_dn>
    <auth_bind_passwd>${LDAP_ADMIN_PASSWORD}</auth_bind_passwd>
    <auth_base_dn>dc=cyberlab,dc=local</auth_base_dn>
    <auth_user_attr>uid</auth_user_attr>
  </auth>
</ossec_config>
```

2. **Mount LDAP Configuration in Docker**:

```yaml
wazuh.manager:
  volumes:
    - ./configs/wazuh/ossec.conf:/var/ossec/etc/ossec.conf:ro
  environment:
    - LDAP_HOST=openldap
    - LDAP_PORT=389
    - LDAP_BIND_DN=cn=admin,dc=cyberlab,dc=local
    - LDAP_BIND_PASSWORD=${LDAP_ADMIN_PASSWORD}
    - LDAP_BASE_DN=dc=cyberlab,dc=local
  depends_on:
    - openldap
```

---

### 6. **Workstation LDAP Integration (Linux Desktop)**

#### Configure LDAP Authentication on Ubuntu Desktop

```bash
# Install LDAP utilities
sudo apt-get install -y libnss-ldap libpam-ldap ldap-utils nscd

# Configure LDAP connection (interactive setup)
sudo dpkg-reconfigure ldap-auth-config

# During setup, provide:
# - LDAP server URI: ldap://openldap:389
# - LDAP search base: dc=cyberlab,dc=local
# - LDAP version: 3
```

#### Manual Configuration Files

**`/etc/ldap.conf` or `/etc/ldap/ldap.conf`:**

```conf
URI ldap://openldap:389
BASE dc=cyberlab,dc=local
BINDDN cn=admin,dc=cyberlab,dc=local
BINDPW ${LDAP_ADMIN_PASSWORD}
BIND_TIMELIMIT 10
TIMELIMIT 15
IDLE_TIMELIMIT 3600
nss_connect_timeout 5000
pam_password md5
```

**Enable LDAP in PAM (`/etc/pam.d/common-session`):**

```bash
session required pam_unix.so
session required pam_mkhomedir.so skel=/etc/skel/ umask=0022
session optional pam_ldap.so
```

**Enable LDAP in NSS (`/etc/nsswitch.conf`):**

```conf
passwd:         files ldap
group:          files ldap
shadow:         files ldap
```

---

## Security Best Practices

### 1. **Use LDAPS (Encrypted Connection)**

Always use LDAPS (port 636) in production environments:

```yaml
environment:
  - LDAP_URL=ldaps://openldap:636
  - LDAP_STARTTLS=true
  - LDAP_VERIFY_CERTIFICATE=true
```

### 2. **Bind DN Best Practice**

Use a dedicated service account instead of admin account:

```ldif
dn: cn=service-account,dc=cyberlab,dc=local
objectClass: inetOrgPerson
cn: service-account
sn: Account
userPassword: {SHA}...GeneratedHash...
```

Then reference:

```yaml
LDAP_BIND_DN: cn=service-account,dc=cyberlab,dc=local
LDAP_BIND_PASSWORD: ${SERVICE_ACCOUNT_PASSWORD}
```

### 3. **Network Isolation**

- LDAP service runs on `internal_net` (10.10.20.0/24)
- Only services on the internal network can connect directly
- External access goes through Traefik with authentication

### 4. **Enable LDAP Logging**

Configure OpenLDAP to log authentication attempts:

```conf
# /etc/ldap/slapd.d/cn=config.ldif
olcLogLevel: stats sync

# In Wazuh - monitor LDAP logs for failed logins
```

### 5. **Password Policies**

Enforce strong password policies in LDAP:

```ldif
# ppolicy configuration
dn: cn=pwddefault,ou=policies,dc=cyberlab,dc=local
objectClass: device
objectClass: pwdPolicy
cn: pwddefault
pwdAttribute: userPassword
pwdMaxAge: 7776000
pwdInHistory: 5
pwdMinLength: 14
pwdMinCategories: 3
pwdLockout: TRUE
pwdLockoutDuration: 600
pwdMaxFailure: 5
```

### 6. **Rate Limiting**

Configure rate limiting in Traefik for LDAP auth endpoints:

```yaml
middlewares:
  ldap-ratelimit:
    rateLimit:
      average: 10
      burst: 20
      period: 1m
```

---

## Troubleshooting

### Connection Failures

**Test LDAP connectivity from container:**

```bash
docker exec openldap ldapwhoami -H ldap://localhost:389 -D "cn=admin,dc=cyberlab,dc=local" -w admin -v
```

**From another container:**

```bash
docker exec nginx ldapsearch -x -H ldap://openldap:389 -D "cn=admin,dc=cyberlab,dc=local" -w admin -b "dc=cyberlab,dc=local" "uid=*"
```

### Authentication Issues

**Check LDAP user exists:**

```bash
ldapsearch -x -H ldap://10.10.20.40:389 -D "cn=admin,dc=cyberlab,dc=local" -w admin -b "dc=cyberlab,dc=local" "(uid=username)"
```

**Verify bind credentials:**

```bash
docker logs openldap | grep -i "auth\|bind\|error"
```

### Common Issues

| Issue | Solution |
|-------|----------|
| **Connection Refused** | Verify OpenLDAP is running: `docker ps \| grep openldap` |
| **Invalid Credentials** | Check BIND_DN and password in environment variables |
| **User Not Found** | Verify LDAP_BASE_DN and search filter match user structure |
| **TLS Errors** | Disable certificate verification for lab environment: `LDAP_VERIFY_CERTIFICATE=false` |
| **Timeouts** | Increase connection timeout: `LDAP_TIMEOUT=30` |

---

## LDAP Data Structure

### Default User Organization Unit

```ldif
dn: ou=users,dc=cyberlab,dc=local
objectClass: organizationalUnit
ou: users

dn: uid=john.doe,ou=users,dc=cyberlab,dc=local
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
objectClass: top
uid: john.doe
cn: John Doe
sn: Doe
mail: john.doe@cyberlab.local
userPassword: {SSHA}...HashedPassword...

dn: ou=groups,dc=cyberlab,dc=local
objectClass: organizationalUnit
ou: groups

dn: cn=admins,ou=groups,dc=cyberlab,dc=local
objectClass: groupOfUniqueNames
cn: admins
uniqueMember: uid=john.doe,ou=users,dc=cyberlab,dc=local
```

---

## Monitoring & Logging

### Monitor LDAP Connections in Wazuh

```conf
# /var/ossec/etc/ossec.conf
<localfile>
  <location>/var/log/slapd.log</location>
  <log_format>slapd</log_format>
</localfile>
```

### View LDAP Logs

```bash
docker exec openldap tail -f /var/log/slapd.log
```

### Monitor Failed Authentications

Configure Wazuh to alert on multiple failed LDAP auth attempts:

```xml
<rule id="110001" level="5">
  <decoded_as>slapd</decoded_as>
  <match>err=49</match>
  <description>LDAP Authentication Failure Detected</description>
</rule>

<rule id="110002" level="10">
  <if_matched_sid>110001</if_matched_sid>
  <same_source_user />
  <frequency>5</frequency>
  <timeframe>600</timeframe>
  <description>Multiple LDAP Authentication Failures</description>
</rule>
```

---

## Advanced Configuration

### Using TLS/SSL

```yaml
openldap:
  environment:
    - LDAP_TLS=true
    - LDAP_TLS_CA_CRT_FILENAME=ca.crt
    - LDAP_TLS_CRT_FILENAME=ldap.crt
    - LDAP_TLS_KEY_FILENAME=ldap.key
    - LDAP_TLS_CIPHER_SUITE=HIGH
    - LDAP_TLS_VERIFY_CLIENT=try
  volumes:
    - ./configs/ldap/certs/ca.crt:/container/service/slapd/assets/certs/ca.crt:ro
    - ./configs/ldap/certs/ldap.crt:/container/service/slapd/assets/certs/ldap.crt:ro
    - ./configs/ldap/certs/ldap.key:/container/service/slapd/assets/certs/ldap.key:ro
```

### Implementing Replication

For high-availability LDAP setup, implement multi-master replication:

```yaml
openldap:
  environment:
    - LDAP_REPLICATION=true
    - LDAP_REPLICATION_MODE=syncprov
    - LDAP_REPLICATION_PROVIDER=ldap://openldap:389
```

---

## Additional Resources

- [OpenLDAP Administrator Guide](https://www.openldap.org/doc/admin/)
- [LDAP Authentication in Applications](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol)
- [Rocket.Chat LDAP Integration](https://docs.rocket.chat/setup-and-configure/workspace-administration/settings/ldap)
- [PostgreSQL LDAP Authentication](https://www.postgresql.org/docs/current/auth-methods.html#AUTH-LDAP)

---

**Last Updated**: 2025-11-25
**Documentation Version**: 1.0
**Status**: Production Ready
