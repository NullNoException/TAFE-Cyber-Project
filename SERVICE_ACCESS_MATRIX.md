# CyberLab Service Access Matrix

Quick reference for service accessibility from different networks.

## Network Legend
| Abbreviation | Network | CIDR Range |
|---|---|---|
| **EXT** | External (VPN) | 10.10.0.0/24 |
| **DMZ** | DMZ | 10.10.10.0/24 |
| **INT** | Internal | 10.10.20.0/24 |
| **SEC** | Security | 10.10.30.0/24 |
| **MGT** | Management | 10.10.40.0/24 |

## Service Accessibility Matrix

### Admin Services (Management Network + Security Network Only)
```
Service              | EXT | DMZ | INT | SEC | MGT | Middleware
---------------------|-----|-----|-----|-----|-----|------------------
Traefik Dashboard    |  ❌  |  ❌  |  ❌  |  ✅  |  ✅  | admin-only-access
OpenVPN Admin        |  ❌  |  ❌  |  ❌  |  ✅  |  ✅  | admin-only-access
DNS Console          |  ❌  |  ❌  |  ❌  |  ✅  |  ✅  | admin-only-access
```

### Security/Monitoring (Security Network + Management Network)
```
Service              | EXT | DMZ | INT | SEC | MGT | Middleware
---------------------|-----|-----|-----|-----|-----|------------------
NeuVector Console    |  ❌  |  ❌  |  ❌  |  ✅  |  ✅  | security-net-access
Wazuh Dashboard      |  ❌  |  ❌  |  ❌  |  ✅  |  ✅  | security-net-access
Wazuh Manager API    |  ❌  |  ❌  |  ❌  |  ✅  |  ✅  | security-net-access
Wazuh Indexer        |  ❌  |  ❌  |  ❌  |  ✅  |  ✅  | security-net-access
Suricata IDS/IPS     |  ❌  |  ❌  |  ❌  |  ✅  |  ✅  | security-net-access
```

### Internal Services (Internal + Security + Management Networks)
```
Service              | EXT | DMZ | INT | SEC | MGT | Middleware
---------------------|-----|-----|-----|-----|-----|------------------
LDAP Admin           |  ❌  |  ❌  |  ✅  |  ✅  |  ✅  | internal-net-access
Rocket.Chat          |  ❌  |  ❌  |  ✅  |  ✅  |  ✅  | internal-net-access
Workstation Desktop  |  ❌  |  ❌  |  ✅  |  ✅  |  ✅  | internal-net-access
```

### Public Services (All Networks)
```
Service              | EXT | DMZ | INT | SEC | MGT | Middleware
---------------------|-----|-----|-----|-----|-----|------------------
Nginx Web Server     |  ✅  |  ✅  |  ✅  |  ✅  |  ✅  | public-services-access
```

---

## Access Control Rules (By Source Network)

### From External Network (10.10.0.0/24)
**Only public services accessible:**
- ✅ Nginx Web Server (`web.cyberlab.local`)

**All other services blocked with 403 Forbidden**

### From DMZ Network (10.10.10.0/24)
**Only public services accessible:**
- ✅ Nginx Web Server (`web.cyberlab.local`)

**All other services blocked with 403 Forbidden**

### From Internal Network (10.10.20.0/24)
**Internal + Public services accessible:**
- ✅ LDAP Admin (`ldap.cyberlab.local`, `ldapadmin.cyberlab.local`)
- ✅ Rocket.Chat (`chat.cyberlab.local`)
- ✅ Workstation (`workstation.cyberlab.local`, `desktop.cyberlab.local`)
- ✅ Nginx Web Server (`web.cyberlab.local`)

**Admin & Security services blocked with 403 Forbidden**

### From Security Network (10.10.30.0/24)
**Security + Internal + Public services accessible:**
- ✅ NeuVector Console (`neuvector.cyberlab.local`)
- ✅ Wazuh Dashboard (`wazuh.cyberlab.local`, `dashboard.cyberlab.local`)
- ✅ Wazuh Manager API (`wazuh-api.cyberlab.local`)
- ✅ Wazuh Indexer (`indexer.cyberlab.local`, `opensearch.cyberlab.local`)
- ✅ Suricata (`suricata.cyberlab.local`, `ids.cyberlab.local`)
- ✅ LDAP Admin (`ldap.cyberlab.local`)
- ✅ Rocket.Chat (`chat.cyberlab.local`)
- ✅ Workstation (`workstation.cyberlab.local`)
- ✅ Nginx Web Server (`web.cyberlab.local`)

**Admin services blocked with 403 Forbidden**

### From Management Network (10.10.40.0/24)
**All services accessible:**
- ✅ Traefik Dashboard (`traefik.cyberlab.local`)
- ✅ OpenVPN Admin (`vpn.cyberlab.local`, `openvpn.cyberlab.local`)
- ✅ DNS Console (`dns.cyberlab.local`, `dns-console.cyberlab.local`)
- ✅ NeuVector Console (`neuvector.cyberlab.local`)
- ✅ Wazuh Dashboard (`wazuh.cyberlab.local`)
- ✅ Wazuh Manager API (`wazuh-api.cyberlab.local`)
- ✅ Wazuh Indexer (`indexer.cyberlab.local`)
- ✅ Suricata (`suricata.cyberlab.local`)
- ✅ LDAP Admin (`ldap.cyberlab.local`)
- ✅ Rocket.Chat (`chat.cyberlab.local`)
- ✅ Workstation (`workstation.cyberlab.local`)
- ✅ Nginx Web Server (`web.cyberlab.local`)

---

## Common Use Cases

### Use Case 1: Team Member on Internal Network
**Source:** 10.10.20.x (Internal Network)

**Accessible Services:**
- ✅ Rocket.Chat - Team communication
- ✅ Workstation - GUI desktop
- ✅ LDAP Admin - Directory management (with credentials)
- ✅ Nginx Web - Public website

**Cannot Access:**
- ❌ Wazuh Dashboard - SIEM monitoring
- ❌ NeuVector - Container security
- ❌ Traefik Dashboard - Infrastructure admin
- ❌ OpenVPN Admin - VPN administration

**Why:** Internal network users don't need direct access to security infrastructure

---

### Use Case 2: Security Admin on Management Network
**Source:** 10.10.40.x (Management Network)

**Accessible Services:** ✅ **ALL SERVICES**

**Can Access:**
- ✅ Admin services (Traefik, OpenVPN, DNS)
- ✅ Security services (Wazuh, NeuVector, Suricata)
- ✅ Internal services (LDAP, Rocket.Chat, Workstation)
- ✅ Public services (Nginx)

**Why:** Management network has complete infrastructure access

---

### Use Case 3: Security Analyst on Security Network
**Source:** 10.10.30.x (Security Network)

**Accessible Services:**
- ✅ Wazuh Dashboard - Log analysis
- ✅ NeuVector - Container security monitoring
- ✅ Suricata - IDS/IPS alerts
- ✅ LDAP Admin - User management (if needed)
- ✅ Rocket.Chat - Team communication
- ✅ Workstation - GUI desktop

**Cannot Access:**
- ❌ Traefik Dashboard - Infrastructure admin
- ❌ OpenVPN Admin - VPN administration
- ❌ DNS Console - DNS management

**Why:** Security network focused on monitoring, not administration

---

### Use Case 4: Remote User via VPN
**Source:** 10.10.0.x (External Network)

**Accessible Services:**
- ✅ Nginx Web - Public website

**Cannot Access:**
- ❌ Everything else

**Why:** Must authenticate into internal networks via VPN or other mechanisms

---

## HTTP Status Codes

### 200 OK
Request succeeded - source IP is whitelisted for this service

### 403 Forbidden
Access denied - source IP is not whitelisted for this service

Example response:
```
HTTP/1.1 403 Forbidden
Content-Type: text/plain; charset=utf-8
Content-Length: 9

Forbidden
```

---

## Testing Connectivity

### Test from Docker Container
```bash
# From Internal Network container
docker-compose exec rocketchat curl -k https://traefik.cyberlab.local
# Expected: 403 Forbidden

# From Security Network container
docker-compose exec wazuh.manager curl -k https://wazuh.dashboard:5601
# Expected: 200 OK (direct internal access, no whitelist)
```

### Test from Host Machine
```bash
# Test Nginx (public access)
curl -k https://web.cyberlab.local
# Expected: 200 OK

# Test Wazuh (should fail from host)
curl -k https://wazuh.cyberlab.local
# Expected: 403 Forbidden (or timeout if on wrong network)
```

### Test via VPN
```bash
# Connect VPN to External Network (10.10.0.0/24)
# Then access
curl -k https://web.cyberlab.local
# Expected: 200 OK

# Try to access internal service
curl -k https://ldap.cyberlab.local
# Expected: 403 Forbidden
```

---

## Whitelist IP Ranges Reference

| Network | CIDR | Broadcast | Usable Hosts |
|---------|------|-----------|--------------|
| External | 10.10.0.0/24 | 10.10.0.255 | 254 |
| DMZ | 10.10.10.0/24 | 10.10.10.255 | 254 |
| Internal | 10.10.20.0/24 | 10.10.20.255 | 254 |
| Security | 10.10.30.0/24 | 10.10.30.255 | 254 |
| Management | 10.10.40.0/24 | 10.10.40.255 | 254 |

---

## Related Documentation

- [NETWORK_ACCESS_CONTROL.md](./NETWORK_ACCESS_CONTROL.md) - Detailed access control policies
- [TRAEFIK_SECURITY_UPDATE.md](./TRAEFIK_SECURITY_UPDATE.md) - Implementation summary
- [infra/configs/traefik/dynamic.yml](./infra/configs/traefik/dynamic.yml) - Traefik configuration
- [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md) - Infrastructure overview
