# CyberLab Infrastructure - Network Access Control Policy

## Overview

All service access is controlled through **Traefik** reverse proxy using IP whitelisting middlewares. This document defines the network access control policies for all services in the infrastructure.

## Network Architecture

```
External Network       (10.10.0.0/24)  - VPN/Remote Access Entry Point
├─ OpenVPN           (10.10.0.20)
├─ NeuVector         (10.10.0.10)
└─ Traefik           (10.10.0.30)

DMZ Network           (10.10.10.0/24)  - Public-Facing Services
├─ Traefik           (10.10.10.5)
├─ Nginx             (10.10.10.10)
├─ DNS Server        (10.10.10.50)
├─ Suricata          (10.10.10.70)
└─ Wazuh Manager     (10.10.10.60)

Internal Network      (10.10.20.0/24)  - Protected Services & Data
├─ PostgreSQL        (10.10.20.30)
├─ OpenLDAP          (10.10.20.40)
├─ MongoDB           (10.10.20.51)
├─ Rocket.Chat       (10.10.20.52)
├─ Workstation       (10.10.20.100)
├─ Traefik           (10.10.20.5)
└─ Wazuh Manager     (10.10.20.60)

Security Network      (10.10.30.0/24)  - Monitoring & Analysis (ISOLATED)
├─ Wazuh Indexer     (10.10.30.10)
├─ Wazuh Manager     (10.10.30.20)
├─ Wazuh Dashboard   (10.10.30.21)
├─ NeuVector         (10.10.30.254)
├─ Suricata          (10.10.30.70)
├─ OpenLDAP          (10.10.30.40)
├─ phpLDAPadmin      (10.10.30.41)
├─ Rocket.Chat       (10.10.30.52)
├─ DNS Server        (10.10.30.50)
└─ Traefik           (10.10.30.5)

Management Network    (10.10.40.0/24)  - Admin Interfaces
├─ Traefik           (10.10.40.5)
├─ Wazuh Indexer     (10.10.40.10)
├─ Wazuh Manager     (10.10.40.20)
├─ Wazuh Dashboard   (10.10.40.21)
├─ NeuVector         (10.10.40.254)
├─ OpenVPN           (10.10.40.60)
└─ DNS Server        (10.10.40.50)
```

## Access Control Policies

### 1. **Admin-Only Access** (`admin-only-access` middleware)

Restricted to **Management Network (10.10.40.0/24)** and **Security Network (10.10.30.0/24)** monitoring

**Allowed Source IPs:**
- 10.10.40.0/24 (Management Network)
- 10.10.30.0/24 (Security Network)
- 127.0.0.1/32 (Localhost Docker)

**Services Using This Policy:**
- **Traefik Dashboard** (`traefik.cyberlab.local`) - Admin monitoring
- **OpenVPN Admin** (`vpn.cyberlab.local`, `openvpn.cyberlab.local`) - VPN administration
- **DNS Console** (`dns.cyberlab.local`, `dns-console.cyberlab.local`) - DNS management

---

### 2. **Security Network Access** (`security-net-access` middleware)

Restricted to **Security Network (10.10.30.0/24)** and **Management Network (10.10.40.0/24)**

**Allowed Source IPs:**
- 10.10.30.0/24 (Security Network)
- 10.10.40.0/24 (Management Network)
- 127.0.0.1/32 (Localhost Docker)

**Services Using This Policy:**
- **NeuVector Console** (`neuvector.cyberlab.local`, `security.cyberlab.local`) - Container security monitoring
- **Wazuh Dashboard** (`wazuh.cyberlab.local`, `dashboard.cyberlab.local`) - SIEM monitoring
- **Wazuh Manager API** (`wazuh-api.cyberlab.local`) - SIEM API access
- **Wazuh Indexer** (`indexer.cyberlab.local`, `opensearch.cyberlab.local`) - Log search interface
- **Suricata IDS/IPS** (`suricata.cyberlab.local`, `ids.cyberlab.local`) - Network monitoring

---

### 3. **Internal Network Access** (`internal-net-access` middleware)

Accessible from **Internal Network (10.10.20.0/24)**, **Security Network (10.10.30.0/24)**, and **Management Network (10.10.40.0/24)**

**Allowed Source IPs:**
- 10.10.20.0/24 (Internal Network)
- 10.10.30.0/24 (Security Network)
- 10.10.40.0/24 (Management Network)
- 127.0.0.1/32 (Localhost Docker)

**Services Using This Policy:**
- **LDAP Admin** (`ldap.cyberlab.local`, `ldapadmin.cyberlab.local`, `directory.cyberlab.local`) - Directory management
- **Rocket.Chat** (`chat.cyberlab.local`, `rocketchat.cyberlab.local`) - Team communication
- **Workstation Desktop** (`workstation.cyberlab.local`, `desktop.cyberlab.local`) - GUI desktop access

---

### 4. **Public Services Access** (`public-services-access` middleware)

Accessible from **all internal networks** (External, DMZ, Internal, Security, Management)

**Allowed Source IPs:**
- 10.10.0.0/24 (External Network - VPN)
- 10.10.10.0/24 (DMZ Network)
- 10.10.20.0/24 (Internal Network)
- 10.10.30.0/24 (Security Network)
- 10.10.40.0/24 (Management Network)
- 127.0.0.1/32 (Localhost Docker)

**Services Using This Policy:**
- **Nginx Web Server** (`web.cyberlab.local`, `www.cyberlab.local`) - Public website

---

## Service Access Matrix

| Service | Type | Access Level | Allowed Networks | Port(s) | Transport |
|---------|------|--------------|------------------|---------|-----------|
| Traefik Dashboard | Admin | **Restricted** | Management, Security | 443 | HTTPS |
| NeuVector Console | Security | **Restricted** | Security, Management | 443 | HTTPS |
| Wazuh Dashboard | Monitoring | **Restricted** | Security, Management | 443 | HTTPS |
| Wazuh Manager API | Monitoring | **Restricted** | Security, Management | 443 | HTTPS |
| Wazuh Indexer | Monitoring | **Restricted** | Security, Management | 443 | HTTPS |
| Suricata IDS/IPS | Monitoring | **Restricted** | Security, Management | 443 | HTTPS |
| OpenVPN Admin | Admin | **Restricted** | Management, Security | 443 | HTTPS |
| DNS Console | Admin | **Restricted** | Management, Security | 443 | HTTPS |
| LDAP Admin | Management | **Internal** | Internal, Security, Management | 443 | HTTPS |
| Rocket.Chat | Service | **Internal** | Internal, Security, Management | 443 | HTTPS |
| Workstation | Client | **Internal** | Internal, Security, Management | 443 | HTTPS |
| Nginx Web | Public | **Open** | All Networks | 443 | HTTPS |

---

## Traefik Configuration Details

### Middleware Definitions (configs/traefik/dynamic.yml)

```yaml
middlewares:
  admin-only-access:
    ipWhiteList:
      sourceRange:
        - "10.10.40.0/24"  # Management Network
        - "10.10.30.0/24"  # Security Network
        - "127.0.0.1/32"   # Localhost

  security-net-access:
    ipWhiteList:
      sourceRange:
        - "10.10.30.0/24"  # Security Network
        - "10.10.40.0/24"  # Management Network
        - "127.0.0.1/32"   # Localhost

  internal-net-access:
    ipWhiteList:
      sourceRange:
        - "10.10.20.0/24"  # Internal Network
        - "10.10.30.0/24"  # Security Network
        - "10.10.40.0/24"  # Management Network
        - "127.0.0.1/32"   # Localhost

  public-services-access:
    ipWhiteList:
      sourceRange:
        - "10.10.0.0/24"   # External Network
        - "10.10.10.0/24"  # DMZ Network
        - "10.10.20.0/24"  # Internal Network
        - "10.10.30.0/24"  # Security Network
        - "10.10.40.0/24"  # Management Network
        - "127.0.0.1/32"   # Localhost
```

### Router Configuration (configs/traefik/dynamic.yml)

Each router applies appropriate middleware for network access control:

```yaml
routers:
  # Restricted Admin Services
  traefik-dashboard:
    middlewares:
      - admin-only-access

  openvpn:
    middlewares:
      - admin-only-access

  dns-console:
    middlewares:
      - admin-only-access

  # Security Monitoring Services
  neuvector:
    middlewares:
      - security-net-access

  wazuh-dashboard:
    middlewares:
      - security-net-access

  wazuh-manager-api:
    middlewares:
      - security-net-access

  wazuh-indexer:
    middlewares:
      - security-net-access

  suricata:
    middlewares:
      - security-net-access

  # Internal Services
  phpldapadmin:
    middlewares:
      - internal-net-access

  rocketchat:
    middlewares:
      - internal-net-access

  workstation:
    middlewares:
      - internal-net-access

  # Public Services
  nginx:
    middlewares:
      - public-services-access
```

---

## Access Control Implementation

### How It Works

1. **Request Flow:**
   - Client connects to Traefik reverse proxy (port 80/443)
   - Traefik checks router rules and middleware chain
   - IP whitelist middleware validates source IP
   - Request either forwarded or rejected with 403 Forbidden

2. **Error Handling:**
   - If source IP not in whitelist: **403 Forbidden** response
   - Access denied log entries in Traefik access logs

3. **Docker Network Integration:**
   - Services communicate directly via Docker networks (no whitelist enforcement)
   - Whitelist only applies to traffic through Traefik reverse proxy
   - Direct service-to-service communication (internal) not restricted

---

## Security Considerations

### Network Isolation

- **Security Network (10.10.30.0/24)** is isolated for SIEM/monitoring tools
- Critical services (Wazuh, NeuVector) only accessible from Security & Management networks
- Public services only accessible from DMZ/Internal networks

### Defense in Depth

1. **Layer 1:** Network segmentation via Docker bridge networks
2. **Layer 2:** IP whitelist at Traefik ingress
3. **Layer 3:** Service-level authentication (LDAP, API tokens)
4. **Layer 4:** TLS/HTTPS encryption for all traffic

### Bypass Prevention

- Direct port access to services disabled (security network isolation)
- All external access funneled through Traefik
- Docker host firewall should block direct service port access

---

## Testing Access Control

### Test from Management Network (10.10.40.0/24)

```bash
# Should succeed
curl -k https://traefik.cyberlab.local
curl -k https://wazuh.cyberlab.local
curl -k https://openvpn.cyberlab.local

# Should succeed (internal is superset of management)
curl -k https://ldap.cyberlab.local
```

### Test from Internal Network (10.10.20.0/24)

```bash
# Should succeed
curl -k https://ldap.cyberlab.local
curl -k https://chat.cyberlab.local

# Should FAIL (403 Forbidden)
curl -k https://traefik.cyberlab.local
curl -k https://wazuh.cyberlab.local
```

### Test from External Network (10.10.0.0/24)

```bash
# Should succeed
curl -k https://web.cyberlab.local

# Should FAIL (403 Forbidden)
curl -k https://traefik.cyberlab.local
curl -k https://ldap.cyberlab.local
curl -k https://wazuh.cyberlab.local
```

---

## Modifying Access Policies

### To Allow Additional IP Ranges

Edit `infra/configs/traefik/dynamic.yml`:

```yaml
middlewares:
  security-net-access:
    ipWhiteList:
      sourceRange:
        - "10.10.30.0/24"  # Security Network
        - "10.10.40.0/24"  # Management Network
        - "192.168.1.0/24" # Add: New Network
        - "127.0.0.1/32"   # Localhost
```

Then reload Traefik:

```bash
docker-compose -f infra/docker-compose.yml restart traefik
```

### To Change Service Access Level

1. Find service router in `infra/configs/traefik/dynamic.yml`
2. Update `middlewares` list with desired access control policy
3. Reload Traefik (no restart required - file provider auto-reloads)

---

## Monitoring & Logging

### Access Attempts

Review Traefik access logs:

```bash
docker-compose -f infra/docker-compose.yml logs -f traefik | grep "403"
```

### By Network

- **Syslog:** Sent to Wazuh Manager (`udp://10.10.30.20:514`)
- **Log rotation:** Managed by Docker syslog driver
- **Access metrics:** Available at Traefik dashboard (`traefik.cyberlab.local`)

---

## Related Documentation

- [Docker Compose Configuration](./infra/docker-compose.yml)
- [Traefik Dynamic Configuration](./infra/configs/traefik/dynamic.yml)
- [Traefik Static Configuration](./infra/configs/traefik/traefik.yml)
- [Network Architecture](./DEPLOYMENT_SUMMARY.md)

---

## Maintenance Checklist

- [ ] Review access logs monthly for unauthorized attempts
- [ ] Update network ranges when infrastructure changes
- [ ] Test access control policies after modifications
- [ ] Document any custom policies not in this file
- [ ] Review Traefik logs for configuration errors
- [ ] Verify security network isolation at deployment
