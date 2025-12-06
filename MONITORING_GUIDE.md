# CyberLab Pro-Scenarios: Complete Monitoring Guide

**Version:** 1.0 | **Last Updated:** December 7, 2025

Complete guide to monitoring, analyzing, and interpreting results from pro-scenario security tests.

---

## 🎯 Monitoring Objectives

For each security scenario, you should verify:

1. **Detection:** System detects the attack/event
2. **Timeliness:** Alert generated within acceptable timeframe
3. **Accuracy:** No false positives or false negatives
4. **Severity:** Alert severity matches threat level
5. **Actionability:** Alert contains enough info to respond
6. **Correlation:** Related events are correlated together

---

## 📊 Monitoring Stack Overview

```
┌─────────────────────────────────────────────────────────┐
│ SCENARIO EXECUTION (Python Scripts)                     │
│ infra/scripts/pro-scenarios/XX_*.py                     │
└──────────────┬──────────────────────────────────────────┘
               │
        ┌──────┴────────┬──────────────┬──────────────┐
        │               │              │              │
┌───────▼──────┐ ┌──────▼────┐ ┌──────▼────┐ ┌──────▼────┐
│   Network    │ │    Web    │ │  System   │ │ Database  │
│   Traffic    │ │  Traffic  │ │  Activity │ │  Activity │
└───────┬──────┘ └──────┬────┘ └──────┬────┘ └──────┬────┘
        │               │             │            │
        └───────────────┼─────────────┼────────────┘
                        │
        ┌───────────────┴────────────────┐
        │                                │
┌───────▼────────────────┐  ┌───────────▼──────────┐
│  DATA COLLECTORS       │  │  AGENTS & EXPORTERS  │
│                        │  │                      │
│ - Suricata (IDS/IPS)   │  │ - Wazuh Agent        │
│ - Wireshark (PCAP)     │  │ - Prometheus         │
│ - TCPDump              │  │ - Netdata            │
│ - syslog               │  │ - Custom exporters   │
└───────┬────────────────┘  └───────────┬──────────┘
        │                               │
        └───────────────┬───────────────┘
                        │
        ┌───────────────▼───────────────────────┐
        │      CENTRAL MONITORING SYSTEMS       │
        │                                       │
        │  ┌─────────────────────────────────┐ │
        │  │ WAZUH (SIEM)                    │ │
        │  │ - Security Events & Alerts      │ │
        │  │ - Log Analysis                  │ │
        │  │ - Threat Detection              │ │
        │  │ https://wazuh.cyberlab.local    │ │
        │  └─────────────────────────────────┘ │
        │                                       │
        │  ┌─────────────────────────────────┐ │
        │  │ PROMETHEUS (Metrics)            │ │
        │  │ - Time-series data              │ │
        │  │ - Performance metrics           │ │
        │  │ - Alerting rules                │ │
        │  │ http://prometheus.cyberlab.local │ │
        │  └─────────────────────────────────┘ │
        │                                       │
        │  ┌─────────────────────────────────┐ │
        │  │ GRAFANA (Dashboards)            │ │
        │  │ - Metric visualization          │ │
        │  │ - Custom dashboards             │ │
        │  │ - Multi-panel analysis          │ │
        │  │ http://grafana.cyberlab.local   │ │
        │  └─────────────────────────────────┘ │
        │                                       │
        │  ┌─────────────────────────────────┐ │
        │  │ NETDATA (Real-time)             │ │
        │  │ - Live system metrics           │ │
        │  │ - Network activity              │ │
        │  │ - Process monitoring            │ │
        │  │ http://netdata.cyberlab.local   │ │
        │  └─────────────────────────────────┘ │
        │                                       │
        └───────────────────────────────────────┘
```

---

## 🔍 System-by-System Monitoring Guide

### 1. WAZUH (Primary SIEM)

**URL:** https://wazuh.cyberlab.local
**Default Creds:** admin / admin
**Purpose:** Centralized security event monitoring

#### Access Wazuh Dashboard

```
1. Open browser: https://wazuh.cyberlab.local
2. Login: admin / admin
3. Navigate to: Security Events > All events
```

#### Key Sections for Scenarios

**Security Events (Main Alert Dashboard)**
- Shows all detected security events
- Filter by rule group, severity, agent
- Search syntax:
  ```
  rule.groups:"Authentication"
  rule.description:"(SYN|flood)"
  agent.name:"[agent-name]"
  severity:"high"
  ```

**Integrity Monitoring (FIM)**
- Monitor file changes
- Useful for: Scenarios 19-20 (File modifications)
- Path: Modules > File Integrity Monitoring

**System Audit**
- Process execution, permission changes
- Useful for: Scenarios 16-18, 25 (Privilege escalation, process anomalies)
- Path: Modules > System Audit

**Authentication**
- Failed/successful logins
- Useful for: Scenarios 8, 11-15 (Authentication attacks)
- Path: Modules > Audit > Authentication

**Network Activity**
- Network traffic patterns
- Useful for: Scenarios 1-5, 21-25 (Network/exfil)
- Path: Dashboard > Network Activity (if configured)

#### Wazuh Alert Search Examples

```
# Scenario 1-4 (Network Attacks/DoS)
rule.description:"(SYN|DDoS|flood|reconnaissance)"
severity:"high" OR severity:"critical"

# Scenario 6 (SQL Injection)
rule.description:"SQL" AND rule.description:"inject"

# Scenario 8 (Brute Force)
rule.groups:"Authentication" AND action:"failed"
AND rule.level:"high"

# Scenario 16-20 (Malware)
rule.description:"(malware|suspicious|process)"
AND severity:"high"

# Scenario 21-25 (Exfiltration)
rule.description:"(exfil|tunnel|transfer)"
OR rule.groups:"Data Loss Prevention"
```

#### Creating Custom Wazuh Dashboard

1. **Go to:** Modules > Management > Alerts
2. **Create Alert Search:**
   - Filter: `rule.description:"[attack-type]"`
   - Time range: Last 1 hour
   - Save as: "Scenario X Monitoring"

3. **Add to Dashboard:**
   - Create new dashboard
   - Add visualization from saved searches
   - Add by scenario number

---

### 2. PROMETHEUS (Metrics & Alerting)

**URL:** http://prometheus.cyberlab.local
**Purpose:** Time-series metrics collection and analysis

#### Accessing Prometheus

```
1. Open browser: http://prometheus.cyberlab.local
2. Go to Graph tab
3. Enter metric name or PromQL query
4. Set time range (15m, 1h, etc.)
```

#### Key Metrics by Scenario

**Network Attacks (1-5)**
```
# Connection rate
rate(tcp_connections[1m])

# TCP connections by destination port
count(tcp_connections) by (dst_port)

# DNS query rate
dns_query_rate

# ICMP packets per second
rate(icmp_packets[1m])
```

**Web Application (6-10)**
```
# HTTP errors
rate(http_errors[1m])

# HTTP requests per second
rate(http_requests[1m])

# Active HTTP connections
http_connections_active

# API request rate
api_requests_per_second
```

**Authentication (11-15)**
```
# Failed authentication attempts
rate(auth_failures[1m])

# SSH authentication failures
ssh_auth_failures

# VPN connection attempts
openvpn_auth_failures
```

**Malware (16-20)**
```
# Process creation rate
process_creation_rate

# Process memory usage
process_memory_bytes

# Suspicious process execution
suspicious_processes
```

**Exfiltration (21-25)**
```
# Outbound data transfer
rate(bytes_sent[1m])

# FTP bytes transferred
ftp_bytes_transferred

# Database query bytes
db_query_bytes_transferred
```

#### Creating PromQL Queries

**Basic Query Structure:**
```
metric_name{label="value"} [range]

# Examples:
tcp_connections{dst_ip="10.10.10.10"}[5m]
rate(http_errors[1m])
sum(bytes_sent) by (dst_ip)
```

**Common PromQL Operations:**
```
# Rate of change
rate(metric[5m])

# Percentage increase
(metric - metric offset 5m) / (metric offset 5m) * 100

# Group by label
sum by (label) (metric)

# Aggregate across all
sum(metric)

# Top N results
topk(5, metric)

# Simple threshold
metric > 1000
```

#### Setting up Prometheus Alerts

**File:** `/path/to/prometheus/alert-rules.yml`

```yaml
groups:
- name: scenario_alerts
  interval: 30s
  rules:
  - alert: SynFloodDetected
    expr: rate(tcp_connections[1m]) > 10000
    for: 1m
    annotations:
      summary: "Potential SYN flood detected"

  - alert: AuthFailureSpike
    expr: rate(auth_failures[1m]) > 100
    for: 2m
    annotations:
      summary: "Authentication failure spike detected"

  - alert: DataExfiltrationDetected
    expr: rate(bytes_sent[1m]) > 100000
    for: 5m
    annotations:
      summary: "Large data outbound transfer detected"
```

---

### 3. GRAFANA (Dashboards)

**URL:** http://grafana.cyberlab.local
**Default Creds:** admin / admin
**Purpose:** Visualize metrics and create custom dashboards

#### Pre-built Dashboards

1. **Network Traffic Dashboard**
   - TCP connections over time
   - DNS query volume
   - Inbound/outbound traffic
   - Source/destination IP analysis

2. **Web Application Dashboard**
   - HTTP requests and errors
   - Response time analysis
   - Request distribution by endpoint
   - Error status codes

3. **System Performance Dashboard**
   - CPU and memory usage
   - Disk I/O
   - Network interface stats
   - Process resource usage

4. **Data Exfiltration Dashboard**
   - Bytes transferred over time
   - Protocol distribution (FTP, SSH, HTTP)
   - Destination IP analysis
   - Transfer rate alerts

#### Creating Custom Dashboard

```
1. Click "+" > Dashboard > New Dashboard
2. Add panels:
   - Query: rate(tcp_connections[1m])
   - Title: "TCP Connection Rate"
   - Visualization: Graph
3. Add multiple panels for scenario monitoring
4. Set refresh interval: 5s or 10s
5. Save dashboard with scenario name
```

#### Panel Configuration Example

```json
{
  "title": "Scenario 1 - SYN Flood Detection",
  "targets": [
    {
      "expr": "rate(tcp_connections[1m])",
      "legendFormat": "Connections/sec",
      "refId": "A"
    }
  ],
  "alert": {
    "conditions": [
      {
        "evaluator": {"type": "gt", "params": [10000]},
        "operator": {"type": "and"},
        "query": {"params": ["A", "5m", "now"]}
      }
    ],
    "frequency": "1m",
    "handler": 1,
    "message": "SYN Flood Detected"
  }
}
```

#### Dashboard Time Controls

- **Relative time:** Last 5m, 15m, 1h, 6h, 24h
- **Absolute time:** Specific date/time range
- **Auto-refresh:** 5s, 10s, 30s, 1m, 5m
- **Timezone:** Set to your local timezone

---

### 4. NETDATA (Real-time Monitoring)

**URL:** http://netdata.cyberlab.local
**Purpose:** Real-time system and network monitoring with low latency

#### Accessing Netdata

```
1. Open browser: http://netdata.cyberlab.local
2. Explore system metrics in real-time
3. Click on charts for detailed view
4. Set collection interval: 1s to 10s
```

#### Key Monitoring Sections

**Network Monitoring**
- Bandwidth per interface (Mbps)
- Connection states (established, TIME_WAIT, etc.)
- TCP/UDP packet rates
- Drop rates and errors

**System Monitoring**
- CPU usage per core
- Memory and swap usage
- Disk I/O read/write rates
- Load average

**Process Monitoring**
- Top processes by CPU
- Top processes by memory
- Process creation rate
- Suspicious process detection (if configured)

**DNS Monitoring (if enabled)**
- Query rate per second
- Response time analysis
- Query types (A, CNAME, MX, etc.)

#### Netdata Alarms

**View Alarms:**
```
1. Netdata dashboard > Alarms
2. Active alarms in red/orange
3. Clear alarms in green
```

**Configure Custom Alarms:**
```
File: /etc/netdata/health.d/scenario.conf

alarm: tcp_connection_spike
  on: netstat.connections_total
  every: 10s
  warn: $this > 1000
  crit: $this > 5000
  alarm: Potential SYN flood detected
```

---

### 5. SURICATA (IDS/IPS)

**Purpose:** Network-level threat detection

#### Accessing Suricata Logs

**Docker:**
```bash
# Real-time alerts
docker logs suricata -f | grep "ALERT"

# Count alerts by classification
docker logs suricata | grep "Classification" | sort | uniq -c

# Search for specific pattern
docker logs suricata | grep -i "SQL\|DDoS\|exploit"
```

**File-based (if applicable):**
```bash
# View Suricata alerts file
cat /var/log/suricata/eve.json | jq '.[] | select(.event_type=="alert")'

# Count by signature
cat /var/log/suricata/eve.json | jq -r '.[] | select(.event_type=="alert") | .alert.signature' | sort | uniq -c | sort -rn
```

#### Key Alert Fields

- **timestamp:** When alert triggered
- **src_ip/dst_ip:** Source and destination
- **src_port/dst_port:** Port numbers
- **alert.signature:** Attack/pattern description
- **alert.severity:** Threat level
- **action:** Allowed/blocked

#### Suricata Alert Example

```json
{
  "timestamp": "2025-12-07T12:34:56.123456+0000",
  "event_type": "alert",
  "src_ip": "10.10.0.50",
  "src_port": 12345,
  "dst_ip": "10.10.10.10",
  "dst_port": 80,
  "proto": "TCP",
  "alert": {
    "action": "alert",
    "gid": 1,
    "signature_id": 2013028,
    "rev": 5,
    "signature": "Potential SYN flood attack",
    "category": "Attempted Denial of Service",
    "severity": 2
  }
}
```

---

## 📈 Scenario-Specific Monitoring

### Network Attack Scenarios (1-5)

**Setup:**
1. Open Grafana: http://grafana.cyberlab.local
2. Open Wazuh: https://wazuh.cyberlab.local
3. Open Netdata: http://netdata.cyberlab.local in another tab

**During Execution:**
- **Monitor Grafana:** Watch TCP connection rate spike
- **Monitor Wazuh:** Wait for DoS/DDoS alerts
- **Monitor Netdata:** Check network bandwidth utilization
- **Monitor Suricata:** Watch for port scan or flood alerts

**Expected Results (within 30 seconds):**
- TCP connections rate jumps to 500+ per second
- Wazuh alert: "Potential SYN flood detected"
- Prometheus metric spike: `tcp_connections`
- Netdata shows bandwidth spike
- Suricata alert: "Potential Denial of Service"

**Verification Checklist:**
- [ ] Alert triggered in Wazuh
- [ ] Metric spike visible in Prometheus/Grafana
- [ ] Netdata shows bandwidth increase
- [ ] Alert severity is High/Critical
- [ ] Timeline is reasonable (30s or less)

---

### Web Application Scenarios (6-10)

**Setup:**
1. Open Wazuh: https://wazuh.cyberlab.local
2. Monitor application logs if available
3. Open Grafana for HTTP metrics: http://grafana.cyberlab.local

**During Execution:**
- **Scenario 6 (SQL Injection):**
  - Wazuh search: `rule.description:"SQL"`
  - Check application error logs
  - HTTP 200 vs 500 responses

- **Scenario 8 (Brute Force):**
  - Wazuh search: `rule.groups:"Authentication"`
  - Count failed logins: `auth_failures > 5`
  - Check for account lockout

- **Scenario 9 (Slowloris):**
  - Monitor: `http_connections_active`
  - Check CPU/memory on web server
  - Watch response time increase

**Expected Results:**
- Failed requests in application logs
- Spike in HTTP error codes (401, 403, 500)
- Database query anomalies
- Account lockout event

---

### Data Exfiltration Scenarios (21-25)

**Setup:**
1. Open Wazuh: https://wazuh.cyberlab.local
2. Open Prometheus: http://prometheus.cyberlab.local
3. Monitor network traffic: http://netdata.cyberlab.local

**During Execution:**
- **Monitor Prometheus:**
  - `bytes_sent` (total bytes outbound)
  - `rate(bytes_sent[1m])` (bytes per second)
  - Compare with baseline

- **Monitor Wazuh:**
  - Search: `rule.description:"exfil"`
  - Check for DLP alerts
  - Look for suspicious protocol usage (FTP on port 21)

- **Monitor Netdata:**
  - Check network interface statistics
  - Monitor destination IPs
  - Track protocol usage

**Expected Results:**
- Significant increase in outbound data volume
- Wazuh exfiltration alert
- FTP/SSH/HTTP unusual protocol usage
- External IP connection attempts

---

## 📊 Data Analysis & Interpretation

### Alert Severity Mapping

| Wazuh Level | Severity | Action |
|-------------|----------|--------|
| 0-3 | Informational | Log and archive |
| 4-6 | Low/Medium | Review and monitor |
| 7-9 | High | Alert security team |
| 10-15 | Critical | Immediate incident response |

### False Positive Analysis

**Legitimate traffic that may trigger alerts:**
- Legitimate port scans (network assessment)
- Large file transfers (backup operations)
- Legitimate authentication attempts
- System maintenance scripts

**Tuning to reduce false positives:**
1. Establish baseline metrics
2. Adjust alert thresholds
3. Add exceptions for known activities
4. Correlate multiple indicators

### Timeline Analysis

**Typical detection timeline:**
```
T+0s    Scenario starts
T+5s    IDS sees suspicious traffic (Suricata)
T+10s   Metrics change (Prometheus)
T+20s   Log ingested by Wazuh
T+30s   Alert threshold triggered in Wazuh
T+40s   Dashboard updates (Grafana)
T+60s   Human analyst reviews alert
```

**Optimize detection latency:**
- Reduce Prometheus scrape interval (but watch CPU)
- Enable real-time Suricata alerts
- Increase log ingestion frequency in Wazuh

---

## 🛠️ Advanced Monitoring

### Creating Correlation Rules

**Wazuh Correlation Example:**
```xml
<rule id="100050" level="9">
  <if_sid>2501</if_sid>  <!-- Failed login attempt -->
  <if_sid>2502</if_sid>  <!-- Another failed login -->
  <frequency>5</frequency>
  <timeframe>60</timeframe>
  <description>Multiple failed login attempts from same IP (Brute force)</description>
  <group>brute_force</group>
</rule>
```

### Custom Metrics Export

**Prometheus Remote Write:**
```yaml
# prometheus.yml
global:
  external_labels:
    cluster: 'cyberlab'

remote_write:
  - url: "http://influxdb:8086/api/v1/prom/write?db=prometheus"
```

**Query Custom Metrics:**
```
SELECT value FROM tcp_connections
WHERE time > now() - 1h
AND tags['dst_ip'] = '10.10.10.10'
```

---

## 📋 Monitoring Checklist

For each scenario execution:

**Pre-Execution (5 min before)**
- [ ] Monitoring systems are running
- [ ] Dashboards are open and refreshing
- [ ] Baseline metrics are recorded
- [ ] Alert rules are enabled
- [ ] Team is ready to observe

**During Execution**
- [ ] Attack executing successfully
- [ ] Metrics are changing in real-time
- [ ] Alerts appearing in monitoring systems
- [ ] No system crashes or errors
- [ ] Screenshots captured of alerts

**Post-Execution (5 min after)**
- [ ] Metrics return to baseline
- [ ] All alerts logged
- [ ] Results exported/saved
- [ ] Timeline documented
- [ ] Analysis completed

---

## 🔄 Continuous Improvement

### Metrics to Track

For each scenario:
1. **Detection Rate:** % scenarios detected
2. **Detection Latency:** Time from attack start to alert
3. **False Positive Rate:** Legitimate alerts vs noise
4. **Alert Quality:** Alerts with actionable data

### Optimization Goals

```
Detection Rate:    > 95%
Detection Latency: < 60 seconds
False Positive:    < 5%
Alert Actionability: > 90%
```

### Quarterly Reviews

- Compare baseline metrics year-over-year
- Identify trending weaknesses
- Update detection rules
- Train analysts on new attack patterns
- Expand scenario coverage

---

## 📚 Quick Reference

### System URLs

| System | URL | Domain |
|--------|-----|--------|
| Wazuh | https://wazuh.cyberlab.local | wazuh.cyberlab.local |
| Prometheus | http://prometheus.cyberlab.local | prometheus.cyberlab.local |
| Grafana | http://grafana.cyberlab.local | grafana.cyberlab.local |
| Netdata | http://netdata.cyberlab.local | netdata.cyberlab.local |

### Useful Commands

```bash
# Check all services running
docker-compose ps

# View Wazuh alerts
curl -k -u admin:admin https://wazuh.cyberlab.local/api/security/events

# Query Prometheus
curl http://prometheus.cyberlab.local/api/v1/query?query=tcp_connections

# Check Suricata alerts
docker logs suricata | grep ALERT | tail -20

# Monitor Netdata in real-time
watch -n 1 'curl http://netdata.cyberlab.local/api/v1/info'
```

### Metric Query Templates

**Find metric name:**
```
http://prometheus.cyberlab.local > Status > Targets > Up > Click metric
```

**Common queries:**
```
# Top talkers
topk(5, rate(bytes_sent[1m]))

# Network anomalies
rate(tcp_connections[1m]) > 1000

# Error rate percentage
(rate(http_errors[1m]) / rate(http_requests[1m])) * 100 > 5
```

---

## 📞 Troubleshooting Monitoring

### No Alerts in Wazuh
```
1. Check Wazuh agent status: Management > Agents
2. Verify rule is enabled: Management > Rules
3. Check rule level threshold
4. View agent logs: docker logs wazuh-agent
```

### Prometheus Metrics Missing
```
1. Check scrape targets: Prometheus > Status > Targets
2. Verify exporter is running: docker ps | grep exporter
3. Test metrics endpoint: curl http://exporter:port/metrics
4. Check scrape configuration
```

### Grafana Dashboard Not Updating
```
1. Refresh datasource: Settings > Data Sources > Test
2. Verify time range is current
3. Check dashboard refresh interval
4. Reload page (Ctrl+Shift+R)
```

### Netdata Performance Issues
```
1. Reduce update frequency: Settings > update every 10s
2. Disable unused plugins
3. Check system CPU/memory
4. Restart Netdata: docker-compose restart netdata
```

---

**Last Updated:** December 7, 2025
**Version:** 1.0
**Status:** Complete
