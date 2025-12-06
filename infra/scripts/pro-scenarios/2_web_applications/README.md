# Web Application Scenarios (6-10)

## Overview

Web application scenarios test detection of common OWASP vulnerabilities and web-based attacks.

## Scenarios in This Category

### Scenario 6: SQL Injection Attack
- **File:** `06_sql_injection.py`
- **Type:** Database Attack / OWASP A03:2021
- **Target:** Web application forms
- **Detection:** WAF, Wazuh, Suricata
- **Run:** `python 06_sql_injection.py --target http://web.cyberlab.local:8080 --endpoint /api/login`

### Scenario 7: Cross-Site Scripting (XSS)
- **File:** `07_xss_attack.py`
- **Type:** Client-Side Attack / OWASP A07:2021
- **Target:** Web forms and input fields
- **Detection:** WAF, Application logs
- **Run:** `python 07_xss_attack.py --target http://web.cyberlab.local:8080 --endpoint /api/search`

### Scenario 8: Brute Force Login
- **File:** `08_brute_force_login.py`
- **Type:** Credential Attack
- **Target:** Authentication endpoint
- **Detection:** Wazuh, Application logs
- **Run:** `python 08_brute_force_login.py --target http://web.cyberlab.local --username admin`

### Scenario 9: Slowloris DDoS Attack
- **File:** `09_slowloris_ddos.py`
- **Type:** Application Layer DoS
- **Target:** HTTP server
- **Detection:** WAF, Prometheus, Grafana
- **Run:** `python 09_slowloris_ddos.py --target web.cyberlab.local --duration 180 --connections 50`

### Scenario 10: API Abuse / Rate Limiting
- **File:** `10_api_abuse.py`
- **Type:** API Misuse / Denial of Service
- **Target:** REST API endpoints
- **Detection:** WAF, API Gateway logs
- **Run:** `python 10_api_abuse.py --target http://web.cyberlab.local:8080 --endpoint /api/data --duration 90`

## Quick Start

```bash
# Run all web application scenarios
cd /Users/ziaparvaresh/Library/CloudStorage/OneDrive-TAFENSW/CyberSecurity-Diploma/Project
python infra/scripts/pro-scenarios/utils/scenario_manager.py --category web

# Run specific scenario
python 2_web_applications/06_sql_injection.py --target http://web.cyberlab.local:8080 --verbose

# Monitor results
# Wazuh: https://wazuh.cyberlab.local
# Grafana: http://grafana.cyberlab.local
```

## Monitoring Tips

1. **For SQL/XSS (6, 7):**
   - Check WAF block events
   - Review application error logs
   - Look for payload patterns in Wazuh

2. **For Brute Force (8):**
   - Monitor failed login attempts in Wazuh
   - Check for account lockout events
   - Review authentication dashboard

3. **For Slowloris (9):**
   - Watch Prometheus: `http_connections_active`
   - Monitor CPU/Memory on web server in Netdata
   - Check response time increase in Grafana

4. **For API Abuse (10):**
   - Monitor API request rate: `api_requests_per_second`
   - Check for 429 (Too Many Requests) responses
   - Review API gateway logs

## Expected Alerts

| Scenario | Alert Type | Tool | Expected Message |
|----------|-----------|------|------------------|
| 6 | SQL Injection | WAF/Wazuh | "SQL injection detected" |
| 7 | XSS | WAF | "Script injection detected" |
| 8 | Brute Force | Wazuh | "Multiple failed logins" |
| 9 | Slowloris | WAF | "Slow HTTP detected" |
| 10 | Rate Limit | API Gateway | "Rate limit exceeded" |

## Testing Web Applications

### Using Juice Shop (if available)
```bash
# Juice Shop is a vulnerable web app for testing
# URL: http://juice-shop.cyberlab.local (if configured)

# Test SQL Injection:
python 06_sql_injection.py --target http://juice-shop.cyberlab.local
```

### Using WebGoat (if available)
```bash
# WebGoat is another OWASP vulnerable app
# URL: http://webgoat.cyberlab.local (if configured)

python 07_xss_attack.py --target http://webgoat.cyberlab.local
```

## Troubleshooting

**Web server not responding:**
```bash
# Check if service is running
docker ps | grep nginx
docker ps | grep traefik

# Verify DNS resolves
nslookup web.cyberlab.local

# Test connectivity
curl -v http://web.cyberlab.local:8080
```

**No WAF alerts:**
```bash
# Check WAF is enabled in Traefik
docker-compose logs traefik | grep -i "rule\|block"

# Verify rules are loaded
docker exec traefik curl http://localhost:8080/api/dashboard
```

**Brute force not triggering account lockout:**
```bash
# Check application configuration
# Adjust scenario parameters to match app settings

# Run with longer duration
python 08_brute_force_login.py --target http://web.cyberlab.local --username admin --duration 180
```

## OWASP Mapping

This category tests the following OWASP Top 10 (2021):

- **A01:2021** - Broken Access Control (Scenario 8)
- **A03:2021** - Injection (Scenario 6)
- **A05:2021** - Broken Access Control (Scenario 8)
- **A07:2021** - Cross-Site Scripting (XSS) (Scenario 7)
- **A04:2021** - Insecure Design (Scenario 9, 10)

## Documentation

- Full details: See [PRO_SCENARIOS.md](../../PRO_SCENARIOS.md)
- Monitoring guide: See [MONITORING_GUIDE.md](../../MONITORING_GUIDE.md)
- All scenarios: See [README.md](../README.md)
