# Traefik Service Routing & Web UI Access Guide
**Date:** November 24, 2025
**Version:** Complete Configuration with Domain Names

---

## Overview

All web-based services in CyberLab are now accessible through Traefik reverse proxy using domain names. This provides:
- ✅ Centralized access point
- ✅ TLS/SSL encryption for all services
- ✅ Security headers and middleware
- ✅ Load balancing capabilities
- ✅ Unified authentication points

---

## Service Access Methods

### 1. Add Hosts File Entries
First, add the domains to your system hosts file (see `HOSTS_FILE_ENTRIES.txt` or `DNS_HOSTS_CONFIG.md`)

### 2. Access via HTTPS
All services accessible via secure HTTPS connections through Traefik

### 3. Automatic HTTP → HTTPS Redirect
HTTP connections automatically redirect to HTTPS

---

## Complete Service Routing Map

### Core Infrastructure Services

#### Traefik Dashboard
```
Domain:     traefik.cyberlab.local
URL:        https://traefik.cyberlab.local
Backend:    Traefik API (internal)
Port:       443 (HTTPS)
Protocol:   HTTP/HTTPS
Status:     ✅ Running
```

#### Nginx Web Server
```
Domains:    web.cyberlab.local
            www.cyberlab.local
URLs:       https://web.cyberlab.local
            https://www.cyberlab.local
Backend:    nginx:80
Ports:      443 (HTTPS)
Protocol:   HTTP
Status:     ✅ Running (Healthy)
Use Case:   Static web hosting, reverse proxy target
```

#### NeuVector Container Security
```
Domains:    neuvector.cyberlab.local
            security.cyberlab.local
URLs:       https://neuvector.cyberlab.local
            https://security.cyberlab.local
Backend:    neuvector-allinone:10443
Port:       443 (HTTPS)
Protocol:   HTTPS
Status:     ✅ Running
Auth:       Built-in (default admin/admin)
Use Case:   Container security, network policies, threat detection
Features:   Real-time threat detection, vulnerability scanning
```

---

### Wazuh SIEM Services

#### Wazuh Dashboard (Web UI)
```
Domains:    wazuh.cyberlab.local
            dashboard.cyberlab.local
URLs:       https://wazuh.cyberlab.local
            https://dashboard.cyberlab.local
Backend:    wazuh.dashboard:5601
Port:       443 (HTTPS via Traefik)
Protocol:   HTTPS
Status:     ✅ Running (Unhealthy in lab)
Auth:       Wazuh credentials
  Username: kibanaserver
  Password: kibanaserver
  API User: wazuh-wui
  API Pass: MyS3cr37P450r.*-
Use Case:   SIEM dashboard, security analytics, threat investigation
Features:
  - Real-time security events
  - Alert management
  - Threat intelligence
  - Compliance reporting
```

#### Wazuh Manager API
```
Domains:    wazuh-api.cyberlab.local
            api.wazuh.local
URLs:       https://wazuh-api.cyberlab.local
            https://api.wazuh.local
Backend:    wazuh.manager:55000
Port:       443 (HTTPS via Traefik)
Protocol:   HTTPS
Status:     ✅ Running (Unhealthy in lab)
Auth:       Basic Auth (API credentials required)
  Username: wazuh-wui
  Password: MyS3cr37P450r.*-
Use Case:   RESTful API for SIEM management
Features:
  - Agent management
  - Rule configuration
  - Alert querying
  - Integration control
```

#### Wazuh Indexer (OpenSearch)
```
Domains:    indexer.cyberlab.local
            opensearch.cyberlab.local
            search.cyberlab.local
URLs:       https://indexer.cyberlab.local
            https://opensearch.cyberlab.local
Backend:    wazuh.indexer:9200
Port:       443 (HTTPS via Traefik)
Protocol:   HTTPS
Status:     ✅ Running (Unhealthy in lab)
Auth:       Basic Auth (Indexer credentials)
  Username: admin
  Password: SecurePassword123
Use Case:   Elasticsearch-compatible search and analytics
Features:
  - Event storage
  - Full-text search
  - Aggregations
  - Direct REST API
Endpoint:   https://indexer.cyberlab.local/_cat/indices
```

---

### LDAP Directory Service

#### phpLDAPadmin (LDAP Web Management)
```
Domains:    ldap.cyberlab.local
            ldapadmin.cyberlab.local
            directory.cyberlab.local
URLs:       https://ldap.cyberlab.local
            https://ldapadmin.cyberlab.local
            https://directory.cyberlab.local
Backend:    phpldapadmin:80
Port:       443 (HTTPS via Traefik)
Protocol:   HTTP → HTTPS via Traefik
Status:     ✅ Running
Auth:       LDAP credentials
  Admin DN: cn=admin,dc=cyberlab,dc=local
  Password: (from .env or secrets)
Use Case:   LDAP directory management GUI
Features:
  - User account management
  - Group management
  - LDAP tree browser
  - Bulk operations
  - Password management
```

---

### Network Security Services

#### Suricata IDS/IPS
```
Domains:    suricata.cyberlab.local
            ids.cyberlab.local
            ips.cyberlab.local
URLs:       https://suricata.cyberlab.local
            https://ids.cyberlab.local
Backend:    suricata (host network, no direct web UI)
Status:     ✅ Running (Healthy)
Protocol:   N/A (CLI/API only for now)
Use Case:   Network intrusion detection and prevention
Features:
  - Packet capture
  - Rule-based detection
  - Threat alerting
  - EVE JSON logging
Logs:       /var/log/suricata/eve.json (4.9 GB)
Note:       Direct web UI not available; access via Wazuh integration
```

#### OpenVPN Admin Panel
```
Domains:    vpn.cyberlab.local
            openvpn.cyberlab.local
URLs:       https://vpn.cyberlab.local
            https://openvpn.cyberlab.local
Backend:    openvpn:943
Port:       443 (HTTPS via Traefik)
Protocol:   HTTPS
Status:     ✅ Running (Healthy)
Auth:       OpenVPN Access Server credentials
Use Case:   VPN management and client profile generation
Features:
  - User management
  - Client certificate generation
  - VPN configuration
  - Connection monitoring
  - Usage statistics
Connection: VPN Protocol: UDP 1194
```

---

## Access Patterns

### Pattern 1: Browser Access (Recommended for Web UIs)
```
1. User opens browser
2. Types: https://wazuh.cyberlab.local
3. System resolves via hosts file → 127.0.0.1
4. Traefik receives request on localhost:443
5. Traefik matches Host header → wazuh.cyberlab.local
6. Routes to backend: https://wazuh.dashboard:5601
7. User sees Wazuh Dashboard
```

### Pattern 2: Command-Line API Access
```bash
# Access Wazuh API via curl
curl -k -u wazuh-wui:MyS3cr37P450r.*- \
  https://wazuh-api.cyberlab.local/manager/info

# Access OpenSearch/Indexer
curl -k -u admin:SecurePassword123 \
  https://indexer.cyberlab.local/_cat/indices
```

### Pattern 3: Service-to-Service (Docker)
```yaml
# One container accessing another via Traefik
# (Inside Docker network, use container names)
services:
  analyzer:
    environment:
      WAZUH_URL: https://wazuh.manager:55000  # Direct container access
      OPENSEARCH_URL: https://wazuh.indexer:9200
```

---

## Traefik Routing Rules

### HTTP Routers (Layer 7)
```yaml
# Rules are evaluated in order

1. neuvector
   - Host: neuvector.cyberlab.local || security.cyberlab.local
   - Backend: neuvector-allinone:10443
   - Middlewares: security-headers, compression

2. nginx
   - Host: web.cyberlab.local || www.cyberlab.local
   - Backend: nginx:80
   - Middlewares: security-headers, compression

3. traefik-dashboard
   - Host: traefik.cyberlab.local
   - Backend: api@internal (Traefik itself)
   - Middlewares: security-headers, compression

4. wazuh-dashboard
   - Host: wazuh.cyberlab.local || dashboard.cyberlab.local
   - Backend: wazuh.dashboard:5601
   - Middlewares: security-headers, compression

5. wazuh-manager-api
   - Host: wazuh-api.cyberlab.local
   - Backend: wazuh.manager:55000
   - Middlewares: security-headers, auth-wazuh

6. wazuh-indexer
   - Host: indexer.cyberlab.local || opensearch.cyberlab.local
   - Backend: wazuh.indexer:9200
   - Middlewares: security-headers, auth-wazuh

7. phpldapadmin
   - Host: ldap.cyberlab.local || ldapadmin.cyberlab.local || directory.cyberlab.local
   - Backend: phpldapadmin:80
   - Middlewares: security-headers, compression

8. suricata
   - Host: suricata.cyberlab.local || ids.cyberlab.local
   - Backend: (No direct web UI)
   - Middlewares: security-headers, compression

9. openvpn
   - Host: vpn.cyberlab.local || openvpn.cyberlab.local
   - Backend: openvpn:943
   - Middlewares: security-headers, compression
```

### TLS Configuration
```yaml
# All HTTPS traffic uses TLS 1.2+
# Cipher Suites (in order):
  - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
  - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
  - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
  - TLS_AES_128_GCM_SHA256
  - TLS_AES_256_GCM_SHA384
  - TLS_CHACHA20_POLY1305_SHA256

# Self-signed certificates (lab environment)
# Browsers show security warning - click through to proceed
```

---

## Security Middleware Stack

### Applied to All Services

#### 1. Security Headers
```
X-Frame-Options: SAMEORIGIN
  → Prevent clickjacking (allow same-origin framing)

X-Content-Type-Options: nosniff
  → Prevent MIME type sniffing

X-XSS-Protection: 1; mode=block
  → Enable browser XSS protection

Strict-Transport-Security: max-age=31536000; includeSubDomains
  → Force HTTPS for 1 year

X-Permitted-Cross-Domain-Policies: none
  → Prevent Flash cross-domain attacks

Referrer-Policy: strict-origin-when-cross-origin
  → Control referrer leakage
```

#### 2. Compression
```
gzip compression enabled
→ Reduce bandwidth usage
→ Faster page loads
```

#### 3. Authentication (API Services Only)
```
auth-wazuh middleware:
  - Applied to: Wazuh API, Wazuh Indexer
  - Type: HTTP Basic Auth
  - Credentials required
```

---

## Port Mapping

```
Traefik Ports (External):
  80   → HTTP (auto-redirects to HTTPS)
  443  → HTTPS (all services)
  8082 → Traefik metrics (Prometheus)

Backend Service Ports (Internal):
  neuvector-allinone:10443
  nginx:80
  wazuh.dashboard:5601
  wazuh.manager:55000
  wazuh.indexer:9200
  phpldapadmin:80
  suricata:(no web UI)
  openvpn:943
```

---

## Certificate Management

### Current Setup (Lab)
- Self-signed certificates (default Traefik)
- No certificate validation
- Browsers show warnings (expected)

### For Production
1. Use Let's Encrypt via ACME
2. Configure proper domain certificates
3. Implement certificate renewal
4. Use trusted CA certificates

---

## Service Discovery & Health Checks

### Active Services
```bash
# View running containers
docker-compose ps

# Check service health
docker-compose ps | grep -E "healthy|unhealthy"

# View Traefik dashboard
# Access: https://traefik.cyberlab.local
```

### Monitoring Traefik
```bash
# View Traefik logs
docker logs -f traefik

# Check routing configuration
docker exec traefik traefik version

# View active routes
# Access Traefik API dashboard at: https://traefik.cyberlab.local
```

---

## Common Access Scenarios

### Scenario 1: Security Analyst Reviews Alerts
```
1. Open browser
2. Navigate to https://wazuh.cyberlab.local
3. Login with kibanaserver/kibanaserver
4. View security events in real-time
5. Investigate suspicious activities
6. Create correlation rules
```

### Scenario 2: Network Admin Checks Intrusion Detection
```
1. Open browser to https://wazuh.cyberlab.local
2. Navigate to Suricata integration
3. View IDS/IPS alerts
4. Check flagged traffic patterns
5. Verify rule effectiveness
```

### Scenario 3: System Admin Manages Directory
```
1. Open https://ldap.cyberlab.local
2. Login with cn=admin,dc=cyberlab,dc=local
3. Browse LDAP tree
4. Create/edit user accounts
5. Manage group memberships
6. Assign roles
```

### Scenario 4: VPN Administrator Creates Client
```
1. Access https://vpn.cyberlab.local
2. Login to OpenVPN Access Server
3. Create new user account
4. Generate client certificate
5. Download client profile
6. Share with remote user
```

### Scenario 5: DevOps Engineer Checks Container Security
```
1. Browse to https://neuvector.cyberlab.local
2. View container security posture
3. Check network policies
4. Review vulnerability scans
5. Monitor real-time threats
```

---

## Troubleshooting

### Domain Not Resolving
```bash
# Verify hosts file entry
cat /etc/hosts | grep cyberlab.local

# Flush DNS
sudo dscacheutil -flushcache  # macOS
sudo systemctl restart systemd-resolved  # Linux
ipconfig /flushdns  # Windows
```

### Certificate Warning
```
Expected in lab environment with self-signed certs
- Click "Advanced" in browser
- Click "Proceed to site"
- Or use curl -k flag to bypass verification
```

### Service Not Accessible
```bash
# Check if service is running
docker-compose ps wazuh.dashboard

# Check Traefik logs
docker logs traefik | grep error

# Restart Traefik
docker-compose restart traefik

# Verify routing
curl -k -H "Host: wazuh.cyberlab.local" https://localhost
```

### Wrong Service Responded
```bash
# Verify Host header matching
curl -k -v -H "Host: wazuh.cyberlab.local" https://localhost

# Check Traefik configuration
docker exec traefik cat /etc/traefik/dynamic.yml

# Restart Traefik to reload config
docker-compose restart traefik
```

---

## Performance Optimization

### Recommended Settings
```yaml
# In production, configure:
- Connection pooling
- Compression for text-based services
- Rate limiting for APIs
- Circuit breakers for failing backends
- Health check intervals
- Connection timeouts
```

### Load Balancing
```yaml
# Traefik supports multiple backends per service
# Example (not currently configured):
services:
  wazuh-dashboard-svc:
    loadBalancer:
      servers:
        - url: "https://wazuh.dashboard:5601"
        - url: "https://wazuh.dashboard-backup:5601"
      healthCheck:
        interval: 30s
        timeout: 5s
        unhealthyThreshold: 3
```

---

## Next Steps

1. ✅ Update hosts file with domain names
2. ✅ Test DNS resolution (ping/nslookup)
3. ✅ Access services via browser
4. ✅ Configure security policies in Traefik
5. ✅ Enable monitoring and logging
6. Consider production DNS setup
7. Implement proper certificate management
8. Set up centralized logging

---

**Configuration Complete!**

All web UI services are now accessible through domain names via Traefik reverse proxy.
