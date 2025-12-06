# Remaining Scenarios Implementation Guide (12-25)

This file provides template implementations for scenarios 12-25. Use the `scenario_template.py` file as a base and customize for each scenario.

## Quick Reference for Scenarios 12-25

### Scenario 12: VPN Brute Force (OpenVPN)
**File:** `12_vpn_brute_force.py`
**Key Elements:**
- Target OpenVPN port (typically 1194 UDP)
- Test common credentials
- Detect authentication failures
- Monitor with Wazuh failed login rules

**Monitoring:**
```bash
# Check OpenVPN logs
docker logs openvpn | grep "AUTH\|TLS\|failed"

# Wazuh query
rule.description:"(authentication|OpenVPN|VPN)"
```

---

### Scenario 13: Certificate Impersonation / MITM Attack
**File:** `13_mitm_certificate.py`
**Key Elements:**
- Send SSL/TLS handshake with invalid certificate
- Test certificate validation
- Trigger certificate warning logs

**Monitoring:**
```bash
# Check Suricata SSL alerts
docker logs suricata | grep "SSL\|certificate\|TLS"

# Prometheus SSL query
ssl_handshake_failures
```

---

### Scenario 14: Credential Spray Attack
**File:** `14_credential_spray.py`
**Key Elements:**
- Test multiple credentials across multiple accounts
- Distribute from single IP (unlike credential stuffing)
- Monitor failed login distribution

**Monitoring:**
```
Wazuh: Search for "failed login" grouped by source IP
Expected: Multiple accounts with failures from same IP
```

---

### Scenario 15: Session Hijacking / Token Theft
**File:** `15_session_hijacking.py`
**Key Elements:**
- Extract valid session tokens
- Replay tokens from different IP/location
- Monitor simultaneous login detection

**Monitoring:**
```
Wazuh: rule.description:"(session|token|hijack)"
App logs: Look for duplicate session access from different IPs
```

---

### Scenario 16: Reverse Shell Exploitation
**File:** `16_reverse_shell.py`
**Key Elements:**
- Establish outbound connection to attacker-controlled IP
- Simulate process spawning from web server
- Monitor network connections

**Monitoring:**
```
Suricata: Detect outbound connection to non-standard ports
Wazuh: Process execution anomaly
Prometheus: network_outbound_connections spike
```

---

### Scenario 17: Malicious Process Spawning
**File:** `17_malicious_process.py`
**Key Elements:**
- Create suspicious parent-child process relationships
- Monitor with NeuVector container security
- Check process execution patterns

**Monitoring:**
```
NeuVector: Monitor container process alerts
Wazuh: Suspicious process creation rules
Prometheus: process_creation_rate
```

---

### Scenario 18: Privilege Escalation
**File:** `18_privilege_escalation.py`
**Key Elements:**
- Attempt to escalate from user to root/sudo
- Generate sudo/su commands
- Monitor privilege changes

**Monitoring:**
```
Wazuh: Privilege escalation detection rules
System audit: sudo command logging
Prometheus: privileged_process_execution metric
```

---

### Scenario 19: File Integrity Violation (FIM)
**File:** `19_file_integrity_violation.py`
**Key Elements:**
- Modify critical system files
- Trigger File Integrity Monitoring
- Log hash changes

**Monitoring:**
```
Wazuh: File Integrity Monitoring (FIM) dashboard
Alert: File hash mismatch
Check: /var/ossec/logs/ossec.log for FIM events
```

---

### Scenario 20: Memory-Based Malware
**File:** `20_memory_malware.py`
**Key Elements:**
- Inject code into memory (simulated)
- No file I/O (fileless attack)
- Memory access anomaly detection

**Monitoring:**
```
NeuVector: Runtime protection - memory anomalies
Wazuh: Suspicious memory patterns
Prometheus: process memory usage spike
```

---

### Scenario 21: FTP Data Exfiltration
**File:** `21_ftp_exfiltration.py`
**Key Elements:**
- Establish FTP connection
- Transfer files/data
- Monitor data volume and patterns

**Monitoring:**
```
Suricata: FTP data transfer logs
Wazuh: Data exfiltration detection
Prometheus: ftp_bytes_transferred
DLP: Sensitive file detection
```

---

### Scenario 22: SSH Tunneling for Exfiltration
**File:** `22_ssh_tunnel_exfil.py`
**Key Elements:**
- Establish SSH tunnel
- Hide exfiltration in encrypted traffic
- Large volume of SSH data transfer

**Monitoring:**
```
Wazuh: SSH behavior analysis (unusual volume/time)
Prometheus: ssh_bytes_transferred spike
Netdata: SSH connection patterns
```

---

### Scenario 23: Cloud Storage Exfiltration
**File:** `23_cloud_exfiltration.py`
**Key Elements:**
- Simulate upload to cloud storage (Dropbox/OneDrive)
- HTTP requests to cloud API endpoints
- DLP detection for cloud uploads

**Monitoring:**
```
Wazuh: Cloud API activity anomaly
Prometheus: http_requests_to_cloud_providers
DLP: Cloud storage upload detection
Proxy logs: Cloud service requests
```

---

### Scenario 24: Email-Based Exfiltration
**File:** `24_email_exfiltration.py`
**Key Elements:**
- Send email with attachments
- Test DLP email filtering
- Monitor SMTP traffic

**Monitoring:**
```
Email gateway logs: Review attachments and recipients
Wazuh: Email anomaly detection
Prometheus: smtp_emails_sent_per_minute
DLP: Sensitive data attachment detection
```

---

### Scenario 25: Database Exfiltration (SQL Dump)
**File:** `25_database_exfiltration.py`
**Key Elements:**
- Execute large database query
- Dump entire tables/database
- High volume data transfer from DB

**Monitoring:**
```
Database audit logs: Large query detection
Wazuh: Database anomaly detection
Prometheus: db_query_bytes_transferred
Network: Database traffic analysis
```

---

## Implementation Guide

### Creating a Custom Scenario Script

```python
#!/usr/bin/env python3
"""
Scenario XX: [Name]
- Difficulty: [Level]
- Detection: [Tools]
- Expected Alert: [What to look for]
"""

import sys
import argparse
import logging
import time
from scapy.all import *  # or requests, socket, etc.

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ScenarioName:
    def __init__(self, target, duration=60, intensity=5, verbose=False):
        self.target = target
        self.duration = duration
        self.intensity = intensity
        self.verbose = verbose
        self.execution_count = 0
        self.results = {
            'scenario': 'SCENARIO_NAME',
            'target': target,
            'executions': 0,
            'status': 'pending'
        }

    def execute(self):
        """Main attack execution"""
        logger.info(f"[*] Starting attack against {self.target}")
        start_time = time.time()

        try:
            while time.time() - start_time < self.duration:
                self.execution_count += 1
                # TODO: Add attack logic
                logger.info(f"[+] Execution {self.execution_count}...")
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("\n[!] Attack interrupted")
        except Exception as e:
            logger.error(f"[-] Error: {e}")
            return

        self.results['executions'] = self.execution_count
        self.results['status'] = 'completed'
        self.log_results()

    def log_results(self):
        """Log results"""
        logger.info("\n" + "="*60)
        logger.info("SCENARIO RESULTS")
        logger.info("="*60)
        logger.info(f"Target: {self.target}")
        logger.info(f"Executions: {self.execution_count}")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - [System]: Look for [Alert Type]")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(description='Scenario XX - [Name]')
    parser.add_argument('--target', required=True, help='Target address')
    parser.add_argument('--duration', type=int, default=60, help='Duration in seconds')
    parser.add_argument('--intensity', type=int, default=5, help='Intensity 1-10')
    parser.add_argument('--verbose', action='store_true', help='Verbose logging')
    args = parser.parse_args()

    scenario = ScenarioName(target=args.target, duration=args.duration, intensity=args.intensity, verbose=args.verbose)
    scenario.execute()

if __name__ == '__main__':
    main()
```

---

## Running Scenario Scripts

### Individual Execution

```bash
# Scenario 12: VPN Brute Force
python 12_vpn_brute_force.py --target 10.10.0.20 --verbose

# Scenario 21: FTP Exfiltration
python 21_ftp_exfiltration.py --target 10.10.20.30 --file /path/to/file

# Scenario 25: Database Dump
python 25_database_exfiltration.py --target 10.10.20.30 --db postgres
```

### Using Scenario Manager

```bash
# Run scenarios 12-15 (Auth category)
python scenario_manager.py --scenarios 12,13,14,15 --delay 60

# Run all malware scenarios (16-20)
python scenario_manager.py --category malware --verbose

# Run all exfiltration scenarios (21-25)
python scenario_manager.py --category exfil --output results.json
```

---

## Monitoring During Execution

### Real-time Monitoring Approach

1. **Open Monitoring Dashboards**
   - Wazuh: https://wazuh.cyberlab.local
   - Prometheus: http://prometheus.cyberlab.local
   - Grafana: http://grafana.cyberlab.local
   - Netdata: http://netdata.cyberlab.local

2. **Run Scenario**
   ```bash
   python scenario_XX.py --target [target] --duration 120 --verbose
   ```

3. **Observe Alerts**
   - Watch Wazuh for security events
   - Monitor Prometheus metrics
   - Check Grafana dashboards
   - Review Netdata real-time metrics

4. **Collect Evidence**
   - Take screenshots of alerts
   - Export metrics from Prometheus
   - Save Wazuh alert summaries
   - Document detection timeline

---

## Customization Tips

### Adjusting Attack Intensity

```python
# Calculate requests based on intensity
requests_per_second = 100 * self.intensity / 5  # 500 RPS at intensity 5
delay = 1.0 / requests_per_second if requests_per_second > 0 else 0
```

### Adding Custom Payloads

```python
def create_custom_payloads(self):
    """Add your own payloads here"""
    return [
        "your_payload_1",
        "your_payload_2",
        "your_payload_3",
    ]
```

### Integrating with External Tools

```python
# Call external tools via subprocess
import subprocess
result = subprocess.run(['external_tool', 'args'], capture_output=True)
```

---

## Troubleshooting

### Script Fails to Connect
- Verify target is reachable: `ping [target]`
- Check firewall rules: `sudo iptables -L`
- Ensure service is running: `docker-compose ps`

### No Alerts Detected
- Verify monitoring rules are enabled
- Check rule sensitivity levels
- Ensure data is flowing to monitoring system
- Check agent connectivity: Wazuh > Agents

### Performance Issues
- Reduce intensity level
- Decrease number of threads
- Use fewer concurrent connections
- Check system resources with `top`

---

## Next Steps

1. **Implement Missing Scripts:** Use templates for scenarios 12-25
2. **Test Scenarios:** Run in isolated environment first
3. **Validate Detection:** Verify each scenario triggers expected alerts
4. **Tune Rules:** Adjust alert thresholds based on your baseline
5. **Document Findings:** Create playbooks for response
6. **Automate Execution:** Create scheduled test runs

---

**Version:** 1.0
**Last Updated:** December 7, 2025
