# Credential & Authentication Scenarios (11-15)

## Overview

Authentication and credential scenarios test detection of attacks targeting identity and access systems.

## Scenarios in This Category

### Scenario 11: LDAP Injection Attack
- **File:** `11_ldap_injection.py`
- **Type:** Directory Service Attack
- **Target:** OpenLDAP server
- **Detection:** Wazuh, LDAP logs
- **Run:** `python 11_ldap_injection.py --target ldap.cyberlab.local --port 389`

### Scenario 12: VPN Brute Force (Template)
- **File:** `12_vpn_brute_force.py`
- **Type:** Remote Access Attack
- **Target:** OpenVPN
- **Detection:** Wazuh, VPN logs
- **Implementation:** Use template in [REMAINING_SCENARIOS.md](../../infra/scripts/pro-scenarios/REMAINING_SCENARIOS.md)

### Scenario 13: MITM Certificate Attack (Template)
- **File:** `13_mitm_certificate.py`
- **Type:** Network Interception
- **Target:** SSL/TLS connections
- **Detection:** Suricata, Browser warnings
- **Implementation:** Use template in [REMAINING_SCENARIOS.md](../../infra/scripts/pro-scenarios/REMAINING_SCENARIOS.md)

### Scenario 14: Credential Spray Attack (Template)
- **File:** `14_credential_spray.py`
- **Type:** Distributed Credential Attack
- **Target:** Multiple accounts
- **Detection:** Wazuh, Application logs
- **Implementation:** Use template in [REMAINING_SCENARIOS.md](../../infra/scripts/pro-scenarios/REMAINING_SCENARIOS.md)

### Scenario 15: Session Hijacking / Token Theft (Template)
- **File:** `15_session_hijacking.py`
- **Type:** Session Management Attack
- **Target:** User sessions
- **Detection:** Wazuh, Application logs
- **Implementation:** Use template in [REMAINING_SCENARIOS.md](../../infra/scripts/pro-scenarios/REMAINING_SCENARIOS.md)

## Quick Start

```bash
# Run LDAP injection scenario
cd /Users/ziaparvaresh/Library/CloudStorage/OneDrive-TAFENSW/CyberSecurity-Diploma/Project
python 3_credential_auth/11_ldap_injection.py --target ldap.cyberlab.local --verbose

# View all available scenarios in this category
python infra/scripts/pro-scenarios/utils/scenario_manager.py --list
```

## Implementation Status

| Scenario | Status | Details |
|----------|--------|---------|
| 11 | ✅ Complete | Ready to run |
| 12-15 | 📋 Template | Implement using REMAINING_SCENARIOS.md |

## Monitoring Tips

1. **For LDAP Injection (11):**
   - Monitor LDAP operation logs
   - Check for syntax errors in queries
   - Review Wazuh authentication anomaly alerts

2. **For VPN Brute Force (12):**
   - Monitor failed authentication attempts
   - Check VPN client logs
   - Watch for rapid connection attempts

3. **For MITM Certificate (13):**
   - Monitor SSL/TLS certificate validation
   - Check for certificate warnings
   - Review Suricata SSL alerts

4. **For Credential Spray (14):**
   - Monitor multiple failed logins from same IP
   - Check account lockout patterns
   - Review authentication distribution

5. **For Session Hijacking (15):**
   - Look for simultaneous logins from different IPs
   - Monitor token validation failures
   - Review user behavior anomalies

## Expected Alerts

| Scenario | Alert Type | Tool | Expected Message |
|----------|-----------|------|------------------|
| 11 | LDAP Attack | Wazuh | "LDAP injection pattern detected" |
| 12 | Auth Failure | Wazuh | "Failed VPN authentication" |
| 13 | SSL Warning | Browser | "Certificate validation failed" |
| 14 | Credential Attack | Wazuh | "Distributed login attempts" |
| 15 | Session Attack | Wazuh | "Concurrent session from different IP" |

## Services & Credentials

### LDAP Directory (OpenLDAP)
```
URL: ldap://ldap.cyberlab.local:389
DC: dc=cyberlab,dc=local
Admin DN: cn=admin,dc=cyberlab,dc=local
Admin Password: See environment variables
```

### LDAP Admin UI (phpLDAPadmin)
```
URL: https://ldapadmin.cyberlab.local
Username: cn=admin,dc=cyberlab,dc=local
Password: See environment variables
```

## Customizing Scenarios

Copy the templates for scenarios 12-15:

```bash
# Copy template
cp /Users/ziaparvaresh/Library/CloudStorage/OneDrive-TAFENSW/CyberSecurity-Diploma/Project/infra/scripts/pro-scenarios/utils/scenario_template.py 12_vpn_brute_force.py

# Edit template
nano 12_vpn_brute_force.py

# Test it
python 12_vpn_brute_force.py --target vpn.cyberlab.local --verbose
```

## NIST Mapping

This category tests controls related to:

- **IA-2** - Authentication (Scenarios 11-15)
- **IA-3** - Device Authentication (Scenario 13)
- **IA-4** - Identifier Management (Scenarios 14-15)
- **AC-3** - Access Control Enforcement (Scenarios 14-15)

## Documentation

- Full details: See [PRO_SCENARIOS.md](../../PRO_SCENARIOS.md)
- Monitoring guide: See [MONITORING_GUIDE.md](../../MONITORING_GUIDE.md)
- Implementation guide: See [REMAINING_SCENARIOS.md](../../REMAINING_SCENARIOS.md)
- All scenarios: See [README.md](../README.md)
