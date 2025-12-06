# Network Attack Scenarios (1-5)

## Overview

Network attack scenarios focus on testing detection of network-level attacks and reconnaissance activities.

## Scenarios in This Category

### Scenario 1: SYN Flood Attack
- **File:** `01_syn_flood.py`
- **Type:** DoS/DDoS Attack
- **Target:** Network traffic
- **Detection:** Suricata, Prometheus, Wazuh
- **Run:** `python 01_syn_flood.py --target web.cyberlab.local --duration 30`

### Scenario 2: Port Scanning
- **File:** `02_port_scan.py`
- **Type:** Network Reconnaissance
- **Target:** Port enumeration
- **Detection:** Suricata, Wazuh
- **Run:** `python 02_port_scan.py --target web.cyberlab.local --ports 1-1024`

### Scenario 3: DNS Query Flood
- **File:** `03_dns_flood.py`
- **Type:** DDoS Attack
- **Target:** DNS server
- **Detection:** Suricata, Prometheus, Wazuh
- **Run:** `python 03_dns_flood.py --target ns1.cyberlab.local --duration 45`

### Scenario 4: ICMP Echo Flood
- **File:** `04_icmp_flood.py`
- **Type:** DoS Attack
- **Target:** Network bandwidth
- **Detection:** Suricata, Netdata
- **Run:** `python 04_icmp_flood.py --target web.cyberlab.local --duration 60`

### Scenario 5: DNS Exfiltration
- **File:** `05_dns_exfiltration.py`
- **Type:** Covert Channel / Data Exfiltration
- **Target:** DNS queries
- **Detection:** Wazuh, Suricata
- **Run:** `python 05_dns_exfiltration.py --target ns1.cyberlab.local --data "secret_data"`

## Quick Start

```bash
# Run all network attack scenarios
cd /Users/ziaparvaresh/Library/CloudStorage/OneDrive-TAFENSW/CyberSecurity-Diploma/Project
python infra/scripts/pro-scenarios/utils/scenario_manager.py --category network

# Run specific scenario
python 1_network_attacks/01_syn_flood.py --target web.cyberlab.local --verbose

# View detailed monitoring
# Wazuh: https://wazuh.cyberlab.local
# Prometheus: http://prometheus.cyberlab.local
# Grafana: http://grafana.cyberlab.local
# Netdata: http://netdata.cyberlab.local
```

## Monitoring Tips

1. **For DoS/DDoS Attacks (1, 3, 4):**
   - Watch Prometheus: `rate(tcp_connections[1m])` or `dns_query_rate`
   - Monitor Grafana Network Traffic dashboard
   - Check Netdata bandwidth metrics

2. **For Port Scan (2):**
   - Review Suricata alerts for port scan signatures
   - Check Wazuh for reconnaissance detection
   - Monitor connection attempts in Prometheus

3. **For DNS Exfiltration (5):**
   - Look for unusual DNS query patterns in Wazuh
   - Check for suspicious subdomains in query logs
   - Monitor DNS query rate anomalies

## Expected Alerts

| Scenario | Alert Type | Tool | Expected Message |
|----------|-----------|------|------------------|
| 1 | Network DoS | Suricata/Wazuh | "Potential SYN flood detected" |
| 2 | Reconnaissance | Suricata | "Port scan detected" |
| 3 | Network DoS | Suricata | "DNS flood detected" |
| 4 | Network DoS | Suricata | "ICMP flood detected" |
| 5 | Exfiltration | Wazuh | "Suspicious DNS pattern" |

## Troubleshooting

**Scenario won't connect:**
```bash
# Check if target is reachable
ping web.cyberlab.local
nslookup ns1.cyberlab.local
```

**No alerts appearing:**
```bash
# Check Wazuh agent status
# Go to Wazuh > Management > Agents

# Verify Suricata is running
docker ps | grep suricata

# Check DNS server
docker logs bind9
```

## Documentation

- Full details: See [PRO_SCENARIOS.md](../../PRO_SCENARIOS.md)
- Monitoring guide: See [MONITORING_GUIDE.md](../../MONITORING_GUIDE.md)
- All scenarios: See [README.md](../README.md)
