# CyberLab Pro: 25+ Advanced Security Scenarios

**Version:** 1.0 | **Last Updated:** December 7, 2025 | **Target Audience:** Security Professionals & Incident Responders

---

## Table of Contents

1. [Introduction](#introduction)
2. [Quick Start Guide](#quick-start-guide)
3. [Scenario Categories](#scenario-categories)
4. [Detailed Scenarios (1-25+)](#detailed-scenarios)
5. [Running Scripts](#running-scripts)
6. [Monitoring & Analysis](#monitoring--analysis)
7. [Result Interpretation](#result-interpretation)

---

## Introduction

This document provides 25+ professional-grade security scenarios designed to test your CyberLab infrastructure's detection, prevention, and response capabilities. Each scenario includes:

- **Scenario Description:** What attack/event is being simulated
- **Difficulty Level:** Beginner, Intermediate, Advanced, Expert
- **Expected Detection:** How systems should respond
- **Script Name:** Python script to execute
- **Monitoring Points:** Where to observe the event

### Prerequisites

- CyberLab infrastructure running (docker-compose up)
- Python 3.8+ installed
- VPN connection to the lab (optional for some scenarios)
- Access to monitoring dashboards (Wazuh, Prometheus, Grafana, Netdata)

---

## Quick Start Guide

### 1. Setup Python Scripts

```bash
# Navigate to scripts directory
cd infra/scripts/pro-scenarios

# Install dependencies
pip install -r requirements.txt
```

### 2. Run a Scenario

```bash
# List all scenarios
python scenario_manager.py --list

# Run a specific scenario
python scenario_manager.py --scenario 1 --verbose

# Run with monitoring enabled
python scenario_manager.py --scenario 1 --monitor --duration 300
```

### 3. Check Results

- **Wazuh:** https://wazuh.cyberlab.local (Security Events & Alerts)
- **Prometheus:** http://prometheus.cyberlab.local (Metrics & Graphs)
- **Grafana:** http://grafana.cyberlab.local (Dashboards)
- **Netdata:** http://netdata.cyberlab.local (Real-time Monitoring)

---

## Scenario Categories

| Category | Scenarios | Difficulty | Detection Tools |
|----------|-----------|-----------|-----------------|
| **Network Attacks** | 1-5 | Beginner-Intermediate | Suricata, Prometheus, Netdata |
| **Web Application** | 6-10 | Intermediate-Advanced | Wazuh, WAF, Web App Honeypot |
| **Credential/Auth** | 11-15 | Intermediate | Wazuh, LDAP Logs, OpenVPN |
| **Malware/Intrusion** | 16-20 | Advanced-Expert | Suricata, Wazuh, Container Security |
| **Data Exfiltration** | 21-25 | Advanced-Expert | DLP, Network Analysis, Wazuh |
| **Compliance/Forensics** | 26-30 | Expert | Wazuh, Wireshark, Logs |

---

## Detailed Scenarios

### NETWORK ATTACKS (1-5)

---

#### **Scenario 1: SYN Flood Attack**
- **Difficulty:** Beginner
- **Category:** Network Attack / DoS
- **Description:** Simulates a SYN flood (TCP half-open connections) against web server
- **Duration:** 30 seconds
- **Expected Detection:**
  - Suricata: "Potential SYN flood detected"
  - Prometheus: CPU spike on target, connection queue increase
  - Wazuh: DOS pattern alerts
- **Script:** `01_syn_flood.py`
- **Monitoring Points:**
  - Grafana: Network Traffic dashboard
  - Prometheus: `rate(tcp_connections[1m])`
  - Wazuh: DOS Detection rules
- **Business Impact:** Website unavailability, resource exhaustion
- **Remediation:** Firewall rate limiting, SYN cookies, WAF blocking

---

#### **Scenario 2: Port Scanning (Network Reconnaissance)**
- **Difficulty:** Beginner
- **Category:** Network Reconnaissance
- **Description:** Performs stealth port scan (Nmap-style) to map network services
- **Duration:** 60 seconds
- **Expected Detection:**
  - Suricata: Port scan detection
  - Prometheus: Unusual connection patterns
  - Wazuh: Multiple connection attempts to different ports
- **Script:** `02_port_scan.py`
- **Monitoring Points:**
  - Suricata alert logs
  - Prometheus: `count(tcp_connections) by (dst_port)`
  - Wazuh Dashboard: Network Reconnaissance
- **Business Impact:** Asset discovery, potential prelude to attack
- **Remediation:** Network segmentation, port whitelisting, IDS monitoring

---

#### **Scenario 3: DNS Query Flood (DNS Amplification)**
- **Difficulty:** Intermediate
- **Category:** Network Attack / DDoS
- **Description:** Floods DNS server with recursive queries to amplify attack
- **Duration:** 45 seconds
- **Expected Detection:**
  - Suricata: DNS flood pattern
  - Prometheus: Query rate spike (>10k/min)
  - Wazuh: Anomalous DNS traffic
  - Netdata: Network bandwidth spike
- **Script:** `03_dns_flood.py`
- **Monitoring Points:**
  - Grafana: DNS Monitoring Dashboard
  - Prometheus: `dns_query_rate`
  - Wazuh: DNS anomaly alerts
- **Business Impact:** DNS service degradation, network congestion
- **Remediation:** Rate limiting, DNS firewall, query validation

---

#### **Scenario 4: ICMP Echo Flood (Ping of Death)**
- **Difficulty:** Intermediate
- **Category:** Network Attack / DoS
- **Description:** Sends massive ICMP echo requests to exhaust bandwidth
- **Duration:** 60 seconds
- **Expected Detection:**
  - Suricata: ICMP flood detection
  - Prometheus: Packet rate anomaly
  - Netdata: Bandwidth utilization spike
- **Script:** `04_icmp_flood.py`
- **Monitoring Points:**
  - Prometheus: `icmp_packets_per_second`
  - Netdata: Network interface stats
  - Wazuh: Protocol anomaly alerts
- **Business Impact:** Network congestion, potential outage
- **Remediation:** ICMP rate limiting, firewall rules, network filtering

---

#### **Scenario 5: DNS Exfiltration (Covert Channel)**
- **Difficulty:** Intermediate
- **Category:** Data Exfiltration / Covert Channels
- **Description:** Encodes and exfiltrates data through DNS queries (data hiding)
- **Duration:** 120 seconds
- **Expected Detection:**
  - Suricata: Suspicious DNS pattern
  - Wazuh: DNS tunneling detection
  - Prometheus: Large DNS query volume
- **Script:** `05_dns_exfiltration.py`
- **Monitoring Points:**
  - Suricata DNS logs
  - Wazuh: Log4j/suspicious patterns
  - Prometheus: Query size analysis
- **Business Impact:** Unauthorized data exfiltration, IP theft
- **Remediation:** DNS monitoring, query inspection, DLP integration

---

### WEB APPLICATION ATTACKS (6-10)

---

#### **Scenario 6: SQL Injection Attack**
- **Difficulty:** Intermediate
- **Category:** Web Application / OWASP
- **Description:** Injects SQL payloads into web form to access database
- **Duration:** 30 seconds
- **Expected Detection:**
  - WAF: SQL injection signature match
  - Wazuh: Database access anomaly
  - Suricata: SQL keyword detection in HTTP payload
- **Script:** `06_sql_injection.py`
- **Monitoring Points:**
  - Wazuh: Web application attack logs
  - Prometheus: Database query patterns
  - Application logs (Juice Shop/WebGoat)
- **Business Impact:** Unauthorized data access, data breach
- **Remediation:** Input validation, parameterized queries, WAF rules

---

#### **Scenario 7: Cross-Site Scripting (XSS) Attack**
- **Difficulty:** Intermediate
- **Category:** Web Application / OWASP
- **Description:** Injects JavaScript to hijack user sessions
- **Duration:** 45 seconds
- **Expected Detection:**
  - WAF: Script tag detection
  - Wazuh: Session hijacking attempt
  - Suricata: JavaScript payload in HTTP response
- **Script:** `07_xss_attack.py`
- **Monitoring Points:**
  - Application security logs
  - WAF block events
  - Wazuh: User behavior anomaly
- **Business Impact:** Account compromise, credential theft
- **Remediation:** Output encoding, CSP headers, WAF protection

---

#### **Scenario 8: Brute Force Login Attack**
- **Difficulty:** Intermediate
- **Category:** Authentication / Credential Attack
- **Description:** Attempts multiple login credentials against web application
- **Duration:** 120 seconds
- **Expected Detection:**
  - Wazuh: Failed login pattern (>5 failures/min)
  - Web App: Account lockout trigger
  - Prometheus: Authentication failure spike
- **Script:** `08_brute_force_login.py`
- **Monitoring Points:**
  - Wazuh: Authentication dashboard
  - Application logs: login attempts
  - Prometheus: `auth_failures_per_minute`
- **Business Impact:** Account takeover, unauthorized access
- **Remediation:** Account lockout, MFA, rate limiting, IP blocking

---

#### **Scenario 9: HTTP DDoS / Slowloris Attack**
- **Difficulty:** Advanced
- **Category:** Web Application / DoS
- **Description:** Sends slow HTTP requests to exhaust server resources
- **Duration:** 180 seconds
- **Expected Detection:**
  - WAF: Slowloris signature
  - Prometheus: Open connection spike
  - Netdata: CPU/memory increase on web server
- **Script:** `09_slowloris_ddos.py`
- **Monitoring Points:**
  - Prometheus: Active connections count
  - Grafana: Server resource dashboard
  - Wazuh: Web server anomaly
- **Business Impact:** Website unavailability, resource exhaustion
- **Remediation:** HTTP timeout tuning, connection limits, WAF protection

---

#### **Scenario 10: API Abuse / Rate Limiting Bypass**
- **Difficulty:** Advanced
- **Category:** Web Application / API Security
- **Description:** Abuses API endpoints with excessive requests or token manipulation
- **Duration:** 90 seconds
- **Expected Detection:**
  - WAF: Rate limit breach
  - Prometheus: API request spike
  - Wazuh: API abuse pattern
- **Script:** `10_api_abuse.py`
- **Monitoring Points:**
  - API gateway logs
  - Prometheus: `api_requests_per_second`
  - Wazuh: API anomaly detection
- **Business Impact:** Service degradation, data exfiltration via API
- **Remediation:** API rate limiting, token validation, request logging

---

### CREDENTIAL & AUTHENTICATION ATTACKS (11-15)

---

#### **Scenario 11: LDAP Injection Attack**
- **Difficulty:** Intermediate
- **Category:** Directory Service / OWASP
- **Description:** Injects LDAP filters to bypass authentication or enumerate users
- **Duration:** 60 seconds
- **Expected Detection:**
  - Wazuh: LDAP injection pattern
  - OpenLDAP logs: Syntax error
  - Prometheus: LDAP query anomaly
- **Script:** `11_ldap_injection.py`
- **Monitoring Points:**
  - OpenLDAP access logs
  - Wazuh: Authentication anomaly
  - Prometheus: LDAP operation rates
- **Business Impact:** Authentication bypass, directory enumeration
- **Remediation:** Input validation, LDAP query parameterization

---

#### **Scenario 12: VPN Brute Force (OpenVPN)**
- **Difficulty:** Intermediate
- **Category:** VPN / Remote Access Security
- **Description:** Attempts to crack OpenVPN credentials
- **Duration:** 120 seconds
- **Expected Detection:**
  - OpenVPN logs: Failed auth attempts
  - Wazuh: Authentication failure pattern
  - Prometheus: Connection spike on VPN port
- **Script:** `12_vpn_brute_force.py`
- **Monitoring Points:**
  - OpenVPN logs (VPN container)
  - Wazuh: Failed login dashboard
  - Prometheus: `openvpn_failed_auth_per_minute`
- **Business Impact:** VPN compromise, remote access breach
- **Remediation:** MFA on VPN, IP whitelisting, connection monitoring

---

#### **Scenario 13: Certificate Impersonation / MITM Attack**
- **Difficulty:** Advanced
- **Category:** Encryption/PKI
- **Description:** Attempts to intercept HTTPS traffic with invalid certificate
- **Duration:** 45 seconds
- **Expected Detection:**
  - Suricata: Certificate validation failure
  - Browser certificate warning
  - Wazuh: SSL/TLS anomaly
- **Script:** `13_mitm_certificate.py`
- **Monitoring Points:**
  - Suricata SSL logs
  - Wazuh: Protocol anomaly
  - Prometheus: Connection handshake failures
- **Business Impact:** Data interception, credential theft
- **Remediation:** HSTS headers, certificate pinning, HTTPS enforcement

---

#### **Scenario 14: Credential Stuffing / Spray Attack**
- **Difficulty:** Intermediate
- **Category:** Authentication / Credential Attack
- **Description:** Tests compromised credentials across multiple accounts
- **Duration:** 180 seconds
- **Expected Detection:**
  - Wazuh: Multiple failed logins from same IP
  - App logs: Distributed login attempts
  - Prometheus: Authentication spike pattern
- **Script:** `14_credential_spray.py`
- **Monitoring Points:**
  - Wazuh: Failed login distribution
  - Application logs: Login patterns
  - Prometheus: Failed auth by source IP
- **Business Impact:** Mass account compromise, data breach
- **Remediation:** Credential monitoring, login throttling, SIEM correlation

---

#### **Scenario 15: Session Hijacking / Token Theft**
- **Difficulty:** Advanced
- **Category:** Authentication / Session Management
- **Description:** Steals valid session token and uses it for unauthorized access
- **Duration:** 90 seconds
- **Expected Detection:**
  - Wazuh: Simultaneous login from different IPs
  - App logs: Token replay detection
  - Prometheus: Unusual session pattern
- **Script:** `15_session_hijacking.py`
- **Monitoring Points:**
  - Application session logs
  - Wazuh: User behavior anomaly
  - Prometheus: Session validation failures
- **Business Impact:** Account takeover, unauthorized actions
- **Remediation:** Session binding, token rotation, IP-based validation

---

### MALWARE & INTRUSION (16-20)

---

#### **Scenario 16: Reverse Shell Exploitation**
- **Difficulty:** Advanced
- **Category:** Remote Code Execution / Intrusion
- **Description:** Exploits vulnerability to establish reverse shell connection
- **Duration:** 60 seconds
- **Expected Detection:**
  - Suricata: Reverse shell pattern (unusual outbound connection)
  - Wazuh: Process execution anomaly
  - Prometheus: Unexpected network connection
- **Script:** `16_reverse_shell.py`
- **Monitoring Points:**
  - Suricata Network logs
  - Wazuh: Process execution dashboard
  - Prometheus: Outbound connection analysis
- **Business Impact:** System compromise, data theft
- **Remediation:** Outbound firewall rules, process monitoring, EDR tools

---

#### **Scenario 17: Malicious Process Spawning**
- **Difficulty:** Advanced
- **Category:** Malware / Endpoint Security
- **Description:** Simulates malicious process creation pattern (e.g., suspicious parent-child)
- **Duration:** 45 seconds
- **Expected Detection:**
  - Wazuh: Suspicious process creation
  - NeuVector: Container process anomaly
  - Prometheus: Process execution spike
- **Script:** `17_malicious_process.py`
- **Monitoring Points:**
  - Wazuh: Process monitoring dashboard
  - NeuVector: Container alerts
  - System process logs
- **Business Impact:** System compromise, code execution
- **Remediation:** Process whitelisting, behavior monitoring, EDR

---

#### **Scenario 18: Privilege Escalation Attempt**
- **Difficulty:** Advanced
- **Category:** Post-Exploitation / Privilege Escalation
- **Description:** Attempts to escalate privileges from regular user to root/admin
- **Duration:** 60 seconds
- **Expected Detection:**
  - Wazuh: Privilege escalation detection
  - System audit logs: sudo/su usage
  - Prometheus: User permission change event
- **Script:** `18_privilege_escalation.py`
- **Monitoring Points:**
  - Wazuh: Privilege escalation dashboard
  - System audit logs
  - Prometheus: `privileged_process_execution`
- **Business Impact:** Full system compromise, admin access
- **Remediation:** Least privilege principle, sudo auditing, capability restrictions

---

#### **Scenario 19: File Integrity Violation (FIM)**
- **Difficulty:** Intermediate
- **Category:** Endpoint Security / File Integrity
- **Description:** Modifies critical system files to test File Integrity Monitoring
- **Duration:** 30 seconds
- **Expected Detection:**
  - Wazuh: File integrity alert (FIM trigger)
  - File hash change detection
  - Prometheus: File modification event
- **Script:** `19_file_integrity_violation.py`
- **Monitoring Points:**
  - Wazuh: File Integrity Monitoring dashboard
  - System audit logs
  - Prometheus: File change metrics
- **Business Impact:** System integrity compromise
- **Remediation:** File integrity monitoring, read-only filesystems, audit logging

---

#### **Scenario 20: Memory-Based Malware / Shellcode Execution**
- **Difficulty:** Expert
- **Category:** Advanced Malware / EDR Detection
- **Description:** Injects code directly into memory without file I/O (fileless malware)
- **Duration:** 120 seconds
- **Expected Detection:**
  - NeuVector: Memory access anomaly
  - Wazuh: Suspicious memory pattern
  - Prometheus: Process memory spike
- **Script:** `20_memory_malware.py`
- **Monitoring Points:**
  - NeuVector: Runtime protection alerts
  - Wazuh: Memory access logs
  - Prometheus: Process memory usage
- **Business Impact:** Advanced persistent threat, difficult to detect
- **Remediation:** Behavioral monitoring, memory scanning, EDR tools

---

### DATA EXFILTRATION (21-25)

---

#### **Scenario 21: FTP Data Exfiltration**
- **Difficulty:** Intermediate
- **Category:** Data Loss Prevention / Exfiltration
- **Description:** Exfiltrates files via FTP to external server
- **Duration:** 120 seconds
- **Expected Detection:**
  - Suricata: Large FTP data transfer
  - Wazuh: Data transfer anomaly
  - Prometheus: FTP traffic spike
  - DLP: Sensitive file detection
- **Script:** `21_ftp_exfiltration.py`
- **Monitoring Points:**
  - Suricata FTP logs
  - Wazuh: Data transfer dashboard
  - Prometheus: `ftp_bytes_transferred`
- **Business Impact:** Intellectual property theft, regulatory breach
- **Remediation:** FTP monitoring, egress filtering, DLP rules

---

#### **Scenario 22: SSH Tunneling for Data Exfiltration**
- **Difficulty:** Advanced
- **Category:** Data Loss Prevention / Covert Channels
- **Description:** Hides exfiltration traffic inside SSH encrypted tunnel
- **Duration:** 180 seconds
- **Expected Detection:**
  - Wazuh: SSH tunnel pattern detection
  - Prometheus: SSH traffic anomaly (high volume)
  - Behavioral: Unusual SSH usage time/pattern
- **Script:** `22_ssh_tunnel_exfil.py`
- **Monitoring Points:**
  - Wazuh: SSH behavior analysis
  - Prometheus: `ssh_bytes_transferred`
  - Netdata: SSH connection patterns
- **Business Impact:** Stealthy data theft, difficult to detect
- **Remediation:** SSH monitoring, traffic baseline, behavior analysis

---

#### **Scenario 23: Cloud Storage Data Exfiltration**
- **Difficulty:** Advanced
- **Category:** Data Loss Prevention / Cloud Security
- **Description:** Exfiltrates data to cloud storage (Dropbox/OneDrive simulation)
- **Duration:** 90 seconds
- **Expected Detection:**
  - Wazuh: Cloud API activity anomaly
  - Prometheus: HTTP to cloud provider spike
  - DLP: Cloud upload detection
- **Script:** `23_cloud_exfiltration.py`
- **Monitoring Points:**
  - Wazuh: Cloud activity logs
  - Prometheus: `http_requests_to_cloud_providers`
  - Web proxy logs (if applicable)
- **Business Impact:** Data loss, regulatory violation (GDPR/HIPAA)
- **Remediation:** Cloud access controls, DLP, shadow IT detection

---

#### **Scenario 24: Email-Based Data Exfiltration**
- **Difficulty:** Intermediate
- **Category:** Data Loss Prevention / Email Security
- **Description:** Sends sensitive files via email to external address
- **Duration:** 60 seconds
- **Expected Detection:**
  - Wazuh: Email with attachment anomaly
  - Email gateway: Suspicious recipient/content
  - Prometheus: SMTP traffic spike
  - DLP: Sensitive data attachment detection
- **Script:** `24_email_exfiltration.py`
- **Monitoring Points:**
  - Email gateway logs
  - Wazuh: Email anomaly detection
  - Prometheus: `smtp_emails_sent_per_minute`
- **Business Impact:** Data leak, regulatory violation
- **Remediation:** Email filtering, DLP rules, recipient restrictions

---

#### **Scenario 25: Database Data Exfiltration (SQL Dump)**
- **Difficulty:** Advanced
- **Category:** Data Loss Prevention / Database Security
- **Description:** Dumps entire database and exfiltrates via network
- **Duration:** 180 seconds
- **Expected Detection:**
  - Wazuh: Large database query anomaly
  - Prometheus: Database bytes transferred spike
  - DLP: Database export detection
  - Suricata: Unusual SQL pattern
- **Script:** `25_database_exfiltration.py`
- **Monitoring Points:**
  - Database audit logs
  - Wazuh: Database anomaly detection
  - Prometheus: `db_query_bytes_transferred`
  - Network traffic analysis
- **Business Impact:** Complete database breach, massive data loss
- **Remediation:** Database monitoring, query auditing, network egress filtering

---

## Running Scripts

### Prerequisites Installation

```bash
# Navigate to pro-scenarios directory
cd infra/scripts/pro-scenarios

# Install all dependencies
pip install -r requirements.txt

# Or install individually:
pip install requests
pip install scapy
pip install paramiko
pip install pexpect
pip install dnspython
```

### Individual Scenario Execution

Each scenario can be run independently from its category folder:

```bash
# Run Scenario 1 (SYN Flood) - Network Attacks
cd infra/scripts/pro-scenarios/1_network_attacks
python 01_syn_flood.py --target 10.10.10.10 --duration 30 --verbose

# Run Scenario 6 (SQL Injection) - Web Applications
cd infra/scripts/pro-scenarios/2_web_applications
python 06_sql_injection.py --target 10.10.10.10:8080 --payloads default --verbose

# Run Scenario 11 (LDAP Injection) - Credential & Auth
cd infra/scripts/pro-scenarios/3_credential_auth
python 11_ldap_injection.py --target 10.10.10.10 --verbose

# Run Scenario 21 (FTP Exfiltration) - Data Exfiltration
cd infra/scripts/pro-scenarios/5_data_exfiltration
python 21_ftp_exfiltration.py --source-file /path/to/file --target 10.10.20.30 --verbose
```

### Batch Execution (Using Scenario Manager)

The scenario_manager automatically discovers scenarios from all category folders:

```bash
# Navigate to utils directory
cd infra/scripts/pro-scenarios/utils

# List all available scenarios
python scenario_manager.py --list

# Run multiple scenarios in sequence (with 60s delay between each)
python scenario_manager.py --scenarios 1,2,3,4,5 --delay 60

# Run all scenarios with monitoring and export results
python scenario_manager.py --run-all --monitor --output results.json

# Run all scenarios by category
python scenario_manager.py --category network   # Scenarios 1-5
python scenario_manager.py --category web      # Scenarios 6-10
python scenario_manager.py --category auth     # Scenarios 11-15
python scenario_manager.py --category malware  # Scenarios 16-20
python scenario_manager.py --category exfil    # Scenarios 21-25

# Run single scenario via manager
python scenario_manager.py --scenario 1 --verbose

# Run scenarios and export to JSON
python scenario_manager.py --scenarios 1,6,11,21 --output test_results.json
```

### Script Parameters

All scripts support common parameters:

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `--target` | string | Target hostname/IP | web.cyberlab.local |
| `--port` | int | Target port | Scenario-specific |
| `--duration` | int | Attack duration (seconds) | Scenario-specific |
| `--intensity` | int | Attack intensity (1-10) | 5 |
| `--verbose` | flag | Enable verbose logging | False |
| `--monitor` | flag | Enable real-time monitoring | False |
| `--webhook` | string | Send results to webhook | None |
| `--delay` | int | Delay before attack (seconds) | 0 |

---

## Monitoring & Analysis

### 1. Wazuh Dashboard (Primary SIEM)

**URL:** https://wazuh.cyberlab.local
**Credentials:** admin / admin

#### Key Sections for Scenario Monitoring:

- **Security Events:** Real-time alerts for all detections
  - Search: `rule.groups:"(Authentication|Network|Web application)"`
  - Filter by rule ID for specific scenario

- **Integrity Monitoring:** File changes and modifications
  - Dashboard: "File Integrity Monitoring"
  - Useful for: Scenario 19 (File Integrity Violation)

- **System Audit:** Process execution and privilege changes
  - Dashboard: "Linux Audit"
  - Useful for: Scenarios 16-20 (Malware/Intrusion)

- **Authentication:** Failed logins and session anomalies
  - Dashboard: "Authentication"
  - Useful for: Scenarios 8, 11-15 (Credential Attacks)

**Alert Search Examples:**
```
# SYN Flood Detection
rule.description:"(SYN|flood|DoS)"

# SQL Injection
rule.description:"(SQL|injection|database attack)"

# Brute Force
rule.groups:"Authentication" AND action:"failed"

# Privilege Escalation
rule.description:"(privilege|escalation|sudo)"
```

---

### 2. Prometheus (Metrics & Alerting)

**URL:** http://prometheus.cyberlab.local

#### Key Metrics for Scenario Monitoring:

| Scenario | Metric | Query |
|----------|--------|-------|
| 1-4 (DoS/DDoS) | Connection rate | `rate(tcp_connections[1m])` |
| 5 (DNS Exfil) | DNS query volume | `dns_query_rate` |
| 6-10 (Web App) | HTTP errors | `rate(http_errors[1m])` |
| 11-15 (Auth) | Failed auth | `authentication_failures` |
| 16-20 (Malware) | Process execution | `process_creation_rate` |
| 21-25 (Exfil) | Network bytes out | `bytes_sent_total` |

#### Creating Custom Alerts:

```yaml
# Navigate to http://prometheus.cyberlab.local > Alerts
# Example: Alert when connection spike detected

ALERT DoSDetected
  IF rate(tcp_connections[1m]) > 10000
  FOR 1m
  ANNOTATIONS {
    summary: "DoS attack detected"
  }
```

---

### 3. Grafana Dashboards (Visualization)

**URL:** http://grafana.cyberlab.local
**Credentials:** admin / admin

#### Pre-built Dashboards:

- **Network Traffic Dashboard:** Monitor Scenario 1-5
  - Panels: TCP connections, DNS queries, ICMP packets
  - Filter by source IP to track attack origin

- **Web Application Dashboard:** Monitor Scenario 6-10
  - Panels: HTTP errors, response times, request rate
  - Correlate with error logs

- **System Performance Dashboard:** Monitor Scenario 16-20
  - Panels: Process execution, memory usage, CPU
  - Identify anomalous process behavior

- **Data Exfiltration Dashboard:** Monitor Scenario 21-25
  - Panels: Network bytes out, database queries, FTP transfers
  - Set baseline and identify spikes

#### Custom Dashboard Creation:

```json
{
  "dashboard": {
    "title": "Scenario Analysis - Real-time",
    "panels": [
      {
        "title": "Network Connections per Second",
        "targets": [{"expr": "rate(tcp_connections[1m])"}]
      },
      {
        "title": "Failed Authentications",
        "targets": [{"expr": "authentication_failures"}]
      },
      {
        "title": "Data Transferred (Bytes)",
        "targets": [{"expr": "bytes_sent_total"}]
      }
    ]
  }
}
```

---

### 4. Netdata (Real-time Monitoring)

**URL:** http://netdata.cyberlab.local

Real-time system monitoring with minimal latency:

- **Network Dashboard:** Inbound/outbound traffic, connections
  - Useful for: All network-based scenarios
  - Alarm: Connection spike, bandwidth anomaly

- **System Dashboard:** CPU, memory, disk I/O
  - Useful for: Scenarios 16-20 (Malware/Intrusion)
  - Track process resource usage

- **DNS Dashboard:** Query rate, response time
  - Useful for: Scenarios 3, 5 (DNS-based)

#### Custom Alarms:

```conf
# /etc/netdata/health.d/scenario_detection.conf

alarm: network_connection_spike
  on: netstat.connections_total
  every: 10s
  crit: $this > 10000
```

---

### 5. Suricata (IDS/IPS)

**Log Location:** Container logs or `/var/log/suricata/`

```bash
# View Suricata alerts in Docker
docker logs suricata | grep "ALERT"

# Search for specific scenario alerts
docker logs suricata | grep -E "(SYN|DDoS|SQL|XSS|Brute)"
```

---

### 6. NeuVector (Container Security)

**URL:** https://10.10.30.11:8443

For Scenario 17 (Malicious Process) and container-based attacks:

- **Network Activity:** Monitor container connections
- **Process Activity:** Track suspicious process execution
- **File Access:** Monitor file access patterns
- **Vulnerability Scan:** Detect vulnerable containers

---

## Result Interpretation

### Alert Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| Critical | Confirmed attack/breach in progress | Immediate incident response |
| High | Strong indicators of compromise | Alert security team |
| Medium | Suspicious activity detected | Investigate and monitor |
| Low | Minor anomalies or policy violations | Log and review |
| Info | Normal security events | Archive for audit trail |

### Expected Timeline

Most scenarios follow this timeline:

1. **T+0s:** Attack initiates
2. **T+5-15s:** IDS detects (Suricata)
3. **T+10-20s:** Metrics spike (Prometheus)
4. **T+15-30s:** Wazuh alert triggered
5. **T+20-40s:** Dashboard visualization updates
6. **T+30-60s:** Human analyst reviews

### False Positives

To minimize false positives:

- **Baseline Metrics:** Establish normal behavior first
  - Run scenarios during isolated test windows
  - Compare with baseline metrics

- **Alert Tuning:** Adjust thresholds based on environment
  - Review Wazuh rule sensitivity
  - Modify Prometheus alert thresholds

- **Context Analysis:** Correlate multiple indicators
  - Single DNS query ≠ exfiltration
  - Multiple indicators + process anomaly = likely threat

### Analysis Checklist

For each scenario, verify:

- [ ] Alert appears in Wazuh within 30 seconds
- [ ] Metrics change in Prometheus
- [ ] Grafana dashboards reflect activity
- [ ] Netdata shows resource usage spike (if applicable)
- [ ] Suricata logs contain relevant detection (network scenarios)
- [ ] Alert severity matches expected level
- [ ] No unrelated systems triggered
- [ ] Timeline aligns with attack execution

---

## Troubleshooting

### Script Issues

**"Connection refused" error:**
```bash
# Verify service is running
docker-compose ps

# Check port is accessible
telnet target-ip target-port

# Restart service
docker-compose restart [service-name]
```

**"Permission denied" error:**
```bash
# Run with appropriate privileges
sudo python [scenario-script]

# Or use Docker directly
docker exec -it [container-name] python [scenario-script]
```

### Monitoring Issues

**Wazuh alerts not appearing:**
- Check Wazuh agent status: `systemctl status wazuh-agent`
- Verify rule is enabled: Wazuh > Management > Rules
- Check agent is configured for source

**Prometheus metrics missing:**
- Verify exporter is running: `docker ps | grep exporter`
- Check scrape configuration: `http://localhost:9090/config`
- Review metrics endpoint: `http://target:9090/metrics`

**Grafana dashboard not updating:**
- Refresh datasource: Settings > Data Sources > Test
- Check Prometheus connectivity
- Verify time range matches data

---

## Advanced Usage

### Scenario Chaining

Run scenarios in sequence to simulate multi-stage attacks:

```bash
# Stage 1: Reconnaissance (Scenario 2 - Port Scan)
python 02_port_scan.py --target 10.10.10.10

# Stage 2: Exploitation (Scenario 6 - SQL Injection)
python 06_sql_injection.py --target 10.10.10.10

# Stage 3: Post-Exploitation (Scenario 16 - Reverse Shell)
python 16_reverse_shell.py --target 10.10.10.10
```

### Distributed Attack Simulation

Run scenarios from multiple sources:

```bash
# Source 1: Port Scan
python 02_port_scan.py --target 10.10.10.10 &

# Source 2: Brute Force
python 08_brute_force_login.py --target 10.10.10.10 &

# Source 3: Data Exfiltration
python 21_ftp_exfiltration.py --target 10.10.20.30 &
```

### Metrics Export

Export results for further analysis:

```bash
# JSON export
python scenario_manager.py --scenario 1 --output json --file results.json

# CSV export
python scenario_manager.py --scenario 1 --output csv --file results.csv

# Prometheus format
python scenario_manager.py --scenario 1 --output prometheus
```

---

## Security Notes

- **Use in Isolated Environment:** Only run in dedicated test infrastructure
- **Alert IT/Security Team:** Notify stakeholders before running scenarios
- **Baseline Metrics:** Capture before/after for comparison
- **Regulatory Compliance:** Ensure testing aligns with policy
- **Incident Response Validation:** Use for tabletop exercises and drills

---

## Conclusion

This document provides comprehensive guidance for 25+ security scenarios to validate your CyberLab infrastructure's detection and response capabilities. Regular execution of these scenarios ensures your security monitoring tools remain effective and your team stays prepared for real-world threats.

For questions or scenario suggestions, refer to the CyberLab documentation or contact your security operations team.

**Last Updated:** December 7, 2025
**Version:** 1.0
**Status:** Ready for Production Testing
