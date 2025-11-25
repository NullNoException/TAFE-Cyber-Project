# DNS/Hosts Configuration for CyberLab
**Date:** November 24, 2025
**Purpose:** Local DNS resolution for web services via Traefik

---

## Hosts File Entry

Add these entries to your system's **hosts file** to resolve domain names to Traefik:

### macOS/Linux
**File:** `/etc/hosts`

### Windows
**File:** `C:\Windows\System32\drivers\etc\hosts`

### Hosts File Entries

```
###############################################################################
# CyberLab Security Infrastructure - Traefik Service Resolution
# Add to /etc/hosts (macOS/Linux) or C:\Windows\System32\drivers\etc\hosts
# All services route through Traefik on 127.0.0.1 (localhost)
###############################################################################

# Local Machine IP (Traefik reverse proxy)
127.0.0.1 localhost

# =========================================================================
# Core Infrastructure
# =========================================================================

# Traefik Dashboard
127.0.0.1 traefik.cyberlab.local

# Nginx Web Server
127.0.0.1 web.cyberlab.local
127.0.0.1 www.cyberlab.local

# NeuVector Container Security Platform
127.0.0.1 neuvector.cyberlab.local
127.0.0.1 security.cyberlab.local

# =========================================================================
# Wazuh SIEM (Security Information and Event Management)
# =========================================================================

# Wazuh Dashboard (Web UI)
127.0.0.1 wazuh.cyberlab.local
127.0.0.1 dashboard.cyberlab.local

# Wazuh Manager API
127.0.0.1 wazuh-api.cyberlab.local
127.0.0.1 api.wazuh.local

# Wazuh Indexer (OpenSearch)
127.0.0.1 indexer.cyberlab.local
127.0.0.1 opensearch.cyberlab.local
127.0.0.1 search.cyberlab.local

# =========================================================================
# LDAP Directory Service
# =========================================================================

# phpLDAPadmin - LDAP Management Interface
127.0.0.1 ldap.cyberlab.local
127.0.0.1 ldapadmin.cyberlab.local
127.0.0.1 directory.cyberlab.local

# =========================================================================
# Network Security Services
# =========================================================================

# Suricata IDS/IPS
127.0.0.1 suricata.cyberlab.local
127.0.0.1 ids.cyberlab.local
127.0.0.1 ips.cyberlab.local

# OpenVPN VPN Gateway
127.0.0.1 vpn.cyberlab.local
127.0.0.1 openvpn.cyberlab.local

# =========================================================================
# Optional Future Services
# =========================================================================

# Prometheus Metrics (when enabled)
# 127.0.0.1 prometheus.cyberlab.local
# 127.0.0.1 metrics.cyberlab.local

# Grafana Monitoring Dashboard (when enabled)
# 127.0.0.1 grafana.cyberlab.local
# 127.0.0.1 monitoring.cyberlab.local

# TheHive Incident Response Platform (when enabled)
# 127.0.0.1 thehive.cyberlab.local
# 127.0.0.1 incidents.cyberlab.local

# Cortex Observable Analysis (when enabled)
# 127.0.0.1 cortex.cyberlab.local
# 127.0.0.1 analysis.cyberlab.local

# Rocket.Chat Team Communication (when enabled)
# 127.0.0.1 chat.cyberlab.local
# 127.0.0.1 rocketchat.cyberlab.local
```

---

## How to Apply Hosts File Changes

### macOS / Linux
```bash
# Edit hosts file with sudo
sudo nano /etc/hosts

# Or use vi/vim
sudo vi /etc/hosts

# Copy and paste the entries above, then save (Ctrl+O, Enter, Ctrl+X in nano)

# Flush DNS cache to apply changes immediately
# macOS
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Linux (Ubuntu/Debian)
sudo systemctl restart systemd-resolved

# Or on some Linux systems
sudo /etc/init.d/nscd restart
```

### Windows

#### Method 1: Using Notepad
1. Open **Notepad** as Administrator
2. File → Open → `C:\Windows\System32\drivers\etc\hosts`
3. Paste the entries above at the end of the file
4. File → Save
5. Flush DNS cache:
   ```cmd
   ipconfig /flushdns
   ```

#### Method 2: Using PowerShell
```powershell
# Run as Administrator
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$entry = "127.0.0.1 traefik.cyberlab.local`r`n127.0.0.1 wazuh.cyberlab.local"
Add-Content -Path $hostsPath -Value $entry
ipconfig /flushdns
```

---

## DNS Resolution Testing

### Test Domain Resolution
```bash
# Linux/macOS
nslookup wazuh.cyberlab.local
nslookup traefik.cyberlab.local
nslookup neuvector.cyberlab.local

# Or use ping
ping traefik.cyberlab.local
ping wazuh.cyberlab.local

# Or use dig for more details
dig wazuh.cyberlab.local
```

### Windows
```cmd
# Test DNS resolution
nslookup wazuh.cyberlab.local
nslookup traefik.cyberlab.local

# Or ping
ping traefik.cyberlab.local
ping wazuh.cyberlab.local

# Or use Resolve-DnsName in PowerShell
Resolve-DnsName wazuh.cyberlab.local
```

### Verify Traefik Routing
```bash
# Test HTTP redirect to HTTPS
curl -v http://wazuh.cyberlab.local

# Test HTTPS (may fail with self-signed cert, but proves routing works)
curl -k -v https://wazuh.cyberlab.local
```

---

## Service URLs After Hosts File Configuration

Once hosts file is updated, access services via:

### Web Interfaces
| Service | URL | Port |
|---------|-----|------|
| Traefik Dashboard | https://traefik.cyberlab.local | 443 |
| NeuVector Console | https://neuvector.cyberlab.local | 443 |
| Nginx Web Server | https://web.cyberlab.local | 443 |
| Wazuh Dashboard | https://wazuh.cyberlab.local | 443 |
| Wazuh Indexer | https://indexer.cyberlab.local | 443 |
| phpLDAPadmin | https://ldap.cyberlab.local | 443 |
| Suricata IDS | https://suricata.cyberlab.local | 443 |
| OpenVPN Admin | https://vpn.cyberlab.local | 443 |

### API Endpoints
| Service | URL | Port |
|---------|-----|------|
| Wazuh API | https://wazuh-api.cyberlab.local | 443 |

---

## Network Flow Diagram

```
User Browser
    ↓
127.0.0.1 (localhost)
    ↓
Traefik (Port 80/443)
    ↓ (Host header matching)
   / | \ \ \
  /  |  \ \ \
 ↙   ↓   ↓ ↓ ↓
nginx traefik neuvector wazuh ldap openvpn suricata
```

---

## Traefik Routing Rules

### Active Routes
```yaml
neuvector.cyberlab.local    → https://neuvector-allinone:10443
security.cyberlab.local     → https://neuvector-allinone:10443
web.cyberlab.local          → http://nginx:80
www.cyberlab.local          → http://nginx:80
traefik.cyberlab.local      → Traefik API (internal)
wazuh.cyberlab.local        → https://wazuh.dashboard:5601
dashboard.cyberlab.local    → https://wazuh.dashboard:5601
wazuh-api.cyberlab.local    → https://wazuh.manager:55000
indexer.cyberlab.local      → https://wazuh.indexer:9200
opensearch.cyberlab.local   → https://wazuh.indexer:9200
ldap.cyberlab.local         → http://phpldapadmin:80
ldapadmin.cyberlab.local    → http://phpldapadmin:80
directory.cyberlab.local    → http://phpldapadmin:80
suricata.cyberlab.local     → http://suricata
ids.cyberlab.local          → http://suricata
vpn.cyberlab.local          → https://openvpn:943
openvpn.cyberlab.local      → https://openvpn:943
```

---

## SSL/TLS Certificate Handling

### Self-Signed Certificates (Lab Environment)
- Traefik uses self-signed certificates by default
- Browsers will show security warnings
- Accept warnings to proceed (safe in lab environment)

### Accessing via Browser
1. Enter URL: `https://wazuh.cyberlab.local`
2. Browser shows certificate warning
3. Click "Advanced" or "Proceed Anyway"
4. Accept and continue to website

### Accessing via Command Line (curl)
```bash
# Skip certificate validation (lab only!)
curl -k https://wazuh.cyberlab.local

# Or use verbose to see certificate details
curl -kv https://wazuh.cyberlab.local
```

---

## Troubleshooting DNS Resolution

### Issue: Domain Not Resolving

**Symptom:** `Cannot reach wazuh.cyberlab.local`

**Solutions:**
1. Verify hosts file entry exists
2. Check file format (no extra spaces or characters)
3. Flush DNS cache:
   ```bash
   # macOS
   sudo dscacheutil -flushcache

   # Linux
   sudo systemctl restart systemd-resolved

   # Windows
   ipconfig /flushdns
   ```
4. Test with `ping` or `nslookup`

### Issue: Connection Refused

**Symptom:** Domain resolves but connection fails

**Solutions:**
1. Verify Traefik is running:
   ```bash
   docker-compose ps | grep traefik
   ```
2. Check Traefik logs:
   ```bash
   docker logs traefik
   ```
3. Verify service is running:
   ```bash
   docker-compose ps
   ```

### Issue: Wrong Service Responds

**Symptom:** Domain routes to wrong service

**Solutions:**
1. Check Traefik routing rules in `dynamic.yml`
2. Verify backend service is configured correctly
3. Check Host() rule matches the domain exactly
4. Restart Traefik:
   ```bash
   docker-compose restart traefik
   ```

---

## Backup and Recovery

### Backup Current Hosts File
```bash
# macOS/Linux
sudo cp /etc/hosts /etc/hosts.backup

# Windows (PowerShell as Admin)
Copy-Item C:\Windows\System32\drivers\etc\hosts C:\Windows\System32\drivers\etc\hosts.backup
```

### Restore from Backup
```bash
# macOS/Linux
sudo cp /etc/hosts.backup /etc/hosts

# Windows
Copy-Item C:\Windows\System32\drivers\etc\hosts.backup C:\Windows\System32\drivers\etc\hosts
```

---

## Production Deployment Notes

For production environments, use proper DNS instead of hosts file:

1. **Internal DNS Server:** Configure BIND or Dnsmasq
2. **DNS Resolution:** Add A records pointing to Traefik IP
3. **TLS Certificates:** Use Let's Encrypt or internal CA
4. **Load Balancer:** Use DNS round-robin or health checks

---

## Hosts File Entries Summary

**Total Entries:** 19 primary + 8 commented future entries

**Categories:**
- Core Infrastructure: 3 entries
- Wazuh SIEM: 5 entries
- LDAP Services: 3 entries
- Network Security: 4 entries
- Optional Services: 8 entries (commented)

---

**Configuration Complete!**

All domain names now resolve through Traefik for centralized routing and security policy enforcement.
