# CyberLab Pro-Scenarios: Security Testing Framework

**Version:** 1.0 | **Last Updated:** December 7, 2025 | **Status:** Ready for Testing

A comprehensive Python-based security scenario framework for testing and validating detection capabilities across your CyberLab infrastructure.

---

## 📋 Quick Start

### Prerequisites

```bash
# Install dependencies
pip install -r requirements.txt

# Verify Python version (3.8+ required)
python --version
```

### First Scenario Run

```bash
# List all available scenarios
python scenario_manager.py --list

# Run your first scenario
python scenario_manager.py --scenario 1 --verbose

# Check Wazuh for alerts while running
# https://wazuh.cyberlab.local (admin/admin)
```

---

## 📂 Directory Structure

```
infra/scripts/pro-scenarios/
├── README.md                        # This file
├── requirements.txt                 # Python dependencies
├── PRO_SCENARIOS.md                # Detailed scenario documentation (main doc)
├── REMAINING_SCENARIOS.md          # Implementation guide for scenarios 12-25
├── scenario_manager.py             # Main scenario executor
├── scenario_template.py            # Template for creating custom scenarios
│
├── Network Attacks (Scenarios 1-5)
├── 01_syn_flood.py                # SYN flood DoS attack
├── 02_port_scan.py                # Port scanning reconnaissance
├── 03_dns_flood.py                # DNS query flood
├── 04_icmp_flood.py               # ICMP echo flood
├── 05_dns_exfiltration.py         # DNS covert channel exfiltration
│
├── Web Application (Scenarios 6-10)
├── 06_sql_injection.py            # SQL injection attack
├── 07_xss_attack.py               # Cross-Site Scripting (XSS)
├── 08_brute_force_login.py        # Brute force authentication
├── 09_slowloris_ddos.py           # Slowloris HTTP DoS
├── 10_api_abuse.py                # API rate limiting abuse
│
├── Credential & Auth (Scenarios 11-15)
├── 11_ldap_injection.py           # LDAP injection
├── 12_vpn_brute_force.py          # VPN credential attack [TEMPLATE]
├── 13_mitm_certificate.py         # MITM certificate attack [TEMPLATE]
├── 14_credential_spray.py         # Credential spray attack [TEMPLATE]
├── 15_session_hijacking.py        # Session token theft [TEMPLATE]
│
├── Malware & Intrusion (Scenarios 16-20)
├── 16_reverse_shell.py            # Reverse shell exploitation [TEMPLATE]
├── 17_malicious_process.py        # Malicious process spawning [TEMPLATE]
├── 18_privilege_escalation.py     # Privilege escalation [TEMPLATE]
├── 19_file_integrity_violation.py # File modification [TEMPLATE]
├── 20_memory_malware.py           # Memory-based malware [TEMPLATE]
│
└── Data Exfiltration (Scenarios 21-25)
    ├── 21_ftp_exfiltration.py     # FTP data transfer [TEMPLATE]
    ├── 22_ssh_tunnel_exfil.py     # SSH tunnel exfiltration [TEMPLATE]
    ├── 23_cloud_exfiltration.py   # Cloud storage upload [TEMPLATE]
    ├── 24_email_exfiltration.py   # Email data transfer [TEMPLATE]
    └── 25_database_exfiltration.py # SQL database dump [TEMPLATE]

[TEMPLATE] = Implementation template provided; customize for your environment
```

---

## 🚀 Usage Examples

### Using Scenario Manager (Recommended)

```bash
# List all scenarios
python scenario_manager.py --list

# Run single scenario
python scenario_manager.py --scenario 1

# Run with verbose output
python scenario_manager.py --scenario 1 --verbose

# Run multiple scenarios
python scenario_manager.py --scenarios 1,2,3,4,5 --delay 60

# Run by category
python scenario_manager.py --category network  # Scenarios 1-5
python scenario_manager.py --category web     # Scenarios 6-10
python scenario_manager.py --category auth    # Scenarios 11-15
python scenario_manager.py --category malware # Scenarios 16-20
python scenario_manager.py --category exfil   # Scenarios 21-25

# Run all scenarios
python scenario_manager.py --run-all --output results.json

# Custom arguments
python scenario_manager.py --scenario 1 --args "--target 10.10.10.10 --duration 30"
```

### Running Individual Scenarios

```bash
# Scenario 1: SYN Flood
python 01_syn_flood.py --target 10.10.10.10 --port 80 --duration 30 --intensity 5

# Scenario 2: Port Scan
python 02_port_scan.py --target 10.10.10.10 --ports 1-1024 --threads 10

# Scenario 3: DNS Flood
python 03_dns_flood.py --target 10.10.10.1 --duration 45 --intensity 8

# Scenario 6: SQL Injection
python 06_sql_injection.py --target 10.10.10.10:8080 --endpoint /api/login --verbose

# Scenario 8: Brute Force
python 08_brute_force_login.py --target http://10.10.10.10 --username admin
```

---

## 📊 Monitoring While Scenarios Run

### Access Monitoring Systems

| System | URL | Credentials | Use For |
|--------|-----|-------------|---------|
| **Wazuh** | https://wazuh.cyberlab.local | admin/admin | Security events & alerts |
| **Prometheus** | http://prometheus.cyberlab.local | N/A | Metrics & alerting |
| **Grafana** | http://grafana.cyberlab.local | admin/admin | Dashboard visualization |
| **Netdata** | http://netdata.cyberlab.local | N/A | Real-time monitoring |
| **Suricata** | Docker logs | N/A | IDS/IPS alerts |

### Real-time Monitoring Workflow

```bash
# Terminal 1: Run scenario
python scenario_manager.py --scenario 1 --verbose

# Terminal 2: Monitor Wazuh (in browser)
# https://wazuh.cyberlab.local > Security Events > Search for alerts

# Terminal 3: Check Docker logs (optional)
docker logs suricata -f  # IDS alerts
docker logs wazuh -f    # Wazuh agent logs

# Terminal 4: Prometheus metrics (in browser)
# http://prometheus.cyberlab.local > Graph > Enter metric name
# Examples: tcp_connections, dns_query_rate, http_errors
```

### Key Monitoring Queries

```
Wazuh:
- Search for attack type: rule.description:"(SYN|flood|DDoS)"
- Auth failures: rule.groups:"Authentication" AND action:"failed"
- SQL injection: rule.description:"(SQL|injection)"

Prometheus:
- Connection rate: rate(tcp_connections[1m])
- DNS queries: dns_query_rate
- HTTP errors: rate(http_errors[1m])
- Failed auth: authentication_failures

Suricata (Docker logs):
docker logs suricata | grep "ALERT\|Classification"
```

---

## 🎯 Scenario Quick Reference

### Network Attacks (1-5)
| # | Name | Difficulty | Duration | Detection |
|---|------|-----------|----------|-----------|
| 1 | SYN Flood | Beginner | 30s | Suricata, Prometheus |
| 2 | Port Scan | Beginner | 60s | Suricata, Wazuh |
| 3 | DNS Flood | Intermediate | 45s | Suricata, Prometheus |
| 4 | ICMP Flood | Intermediate | 60s | Suricata, Netdata |
| 5 | DNS Exfil | Intermediate | 120s | Wazuh, Suricata |

### Web Application (6-10)
| # | Name | Difficulty | Duration | Detection |
|---|------|-----------|----------|-----------|
| 6 | SQL Injection | Intermediate | 30s | WAF, Wazuh |
| 7 | XSS Attack | Intermediate | 45s | WAF, Web logs |
| 8 | Brute Force | Intermediate | 120s | Wazuh, App logs |
| 9 | Slowloris | Advanced | 180s | WAF, Prometheus |
| 10 | API Abuse | Advanced | 90s | WAF, API logs |

### Other Categories
- **Auth (11-15):** LDAP, VPN, MITM, Credential spray, Session hijacking
- **Malware (16-20):** Reverse shell, Malicious process, Escalation, FIM, Memory malware
- **Exfil (21-25):** FTP, SSH tunnel, Cloud, Email, Database dump

---

## 📈 Expected Detection Timeline

Most scenarios follow this timeline:

```
T+0s    : Scenario executes
T+5-15s : IDS detects (Suricata)
T+10-20s: Metrics spike (Prometheus)
T+15-30s: Wazuh alert triggered
T+20-40s: Dashboard updates (Grafana)
T+30-60s: Human review possible
```

---

## 🔧 Common Commands

### Install & Setup
```bash
# Install dependencies
pip install -r requirements.txt

# Verify Scapy is installed (for network scenarios)
python -c "from scapy.all import *; print('Scapy OK')"

# Verify requests library
python -c "import requests; print('Requests OK')"
```

### Run Scenarios
```bash
# Dry run (test connection)
python 02_port_scan.py --target 10.10.10.10 --ports 80-85

# Run with intense settings
python 01_syn_flood.py --target 10.10.10.10 --duration 60 --intensity 10

# Run multiple in sequence with delays
python scenario_manager.py --scenarios 1,2,3 --delay 120 --verbose

# Run and export results
python scenario_manager.py --scenario 1 --output results.json
```

### Monitor Results
```bash
# Check results JSON
cat results.json | python -m json.tool

# View Wazuh alerts
curl -k -u admin:admin https://wazuh.cyberlab.local/api/security/events

# Check Prometheus metrics
curl http://prometheus.cyberlab.local/api/v1/query?query=tcp_connections

# Monitor in real-time
watch -n 1 'curl http://prometheus.cyberlab.local/api/v1/query?query=tcp_connections'
```

---

## 🛠️ Customization

### Creating Your Own Scenario

1. **Copy Template**
   ```bash
   cp scenario_template.py 99_my_scenario.py
   ```

2. **Edit Script**
   ```python
   class MyScenario:
       def __init__(self, target, duration=60, ...):
           # Your implementation
           pass

       def execute_attack(self):
           # Your attack logic
           pass
   ```

3. **Add to Manager**
   - Scenario manager auto-discovers scripts named `XX_*.py`
   - Number must be 00-99

4. **Test It**
   ```bash
   python scenario_manager.py --list  # Should appear
   python 99_my_scenario.py --target 10.10.10.10
   ```

### Modifying Attack Parameters

```python
# Adjust intensity calculation
requests_per_second = 1000 * self.intensity / 5  # More aggressive

# Customize timing
time.sleep(0.1)  # Faster attacks

# Add more payloads
payloads.extend([...])  # Expand attack surface

# Change targeting
endpoints = ['/api/v1/', '/api/v2/', ...]  # Multiple endpoints
```

---

## 📝 Results and Reporting

### Save Results
```bash
# JSON format
python scenario_manager.py --scenario 1 --output results.json

# View results
cat results.json

# Parse results
python -c "import json; data = json.load(open('results.json')); print(data['scenarios_executed'][0])"
```

### Metrics to Collect

For each scenario, collect:
1. **Before:** Baseline metrics (connections, errors, CPU)
2. **During:** Peak metrics during attack
3. **After:** Return to baseline metrics
4. **Alerts:** Wazuh alerts triggered and latency

### Analysis Checklist

- [ ] Attack executed successfully
- [ ] Wazuh alert triggered within 30s
- [ ] Metrics spike in Prometheus
- [ ] Grafana dashboard reflects activity
- [ ] Netdata shows anomaly (if applicable)
- [ ] Alert severity matches expected level
- [ ] False positives minimal
- [ ] Detection latency acceptable

---

## 🐛 Troubleshooting

### "Connection refused" Error
```bash
# Verify service is running
docker-compose ps | grep [service]

# Check if port is open
nc -zv 10.10.10.10 80

# Restart service
docker-compose restart [service]
```

### Scenario Doesn't Trigger Alerts
```bash
# Check if monitoring agent is connected
# Wazuh > Management > Agents

# Verify rule is enabled
# Wazuh > Management > Rules

# Check data flow to monitoring
docker logs wazuh-agent
```

### Performance Issues
```bash
# Reduce intensity
python 01_syn_flood.py --target 10.10.10.10 --intensity 2

# Reduce threads
python 02_port_scan.py --target 10.10.10.10 --threads 5

# Check system resources
top -b -n 1 | head -15
```

### Scapy Permission Issues
```bash
# May need elevated privileges
sudo python 01_syn_flood.py --target 10.10.10.10

# Or run container with elevated privileges
docker run --privileged -it python:3.9 python /path/to/script.py
```

---

## 📚 Documentation

- **PRO_SCENARIOS.md:** Full documentation of all 25 scenarios
- **REMAINING_SCENARIOS.md:** Implementation guide for scenarios 12-25
- **scenario_template.py:** Template for creating custom scenarios
- **README.md:** This file

---

## ⚠️ Important Notes

### Legal & Ethical

- **Use Only in Authorized Environments:** Run only on infrastructure you own or have explicit permission to test
- **Notify Stakeholders:** Alert IT/Security team before running scenarios
- **Document Testing:** Keep records of all security testing activities
- **Compliance:** Ensure testing aligns with organizational policies

### Safety Practices

- **Isolated Testing:** Use dedicated test environment
- **Backup First:** Backup critical systems before testing
- **Gradual Intensity:** Start with low intensity (1-3) and increase
- **Monitor Closely:** Watch impact on production systems
- **Kill-Switch:** Be ready to stop scenarios if needed

### System Impact

- **Network Scenarios (1-5):** May impact network connectivity
- **Web Scenarios (6-10):** May cause brief service interruption
- **Brute Force (8):** May trigger account lockout
- **Slowloris (9):** Can exhaust server resources
- **Exfil (21-25):** May trigger DLP/firewall rules

---

## 📞 Support & Feedback

For issues, questions, or scenario suggestions:

1. Check [PRO_SCENARIOS.md](./PRO_SCENARIOS.md) for detailed documentation
2. Review troubleshooting section above
3. Check Docker logs: `docker logs [container]`
4. Review Wazuh agent status: Wazuh > Management > Agents

---

## 🎓 Learning Path

**Beginner:** Start with scenarios 1-5 (Network Attacks)
**Intermediate:** Progress to 6-15 (Web App & Auth)
**Advanced:** Test scenarios 16-25 (Malware & Exfiltration)
**Expert:** Create custom scenarios and integrate with your SOC

---

## 🔄 Version History

- **v1.0 (Dec 7, 2025):** Initial release with 10 complete scenarios + 15 templates
- **Planned:** Additional scenarios, CI/CD integration, cloud scenarios

---

**Last Updated:** December 7, 2025
**Status:** Production Ready
**Tested On:** CyberLab v2.1+
