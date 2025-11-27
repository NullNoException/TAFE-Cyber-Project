#!/bin/bash
# =============================================================================
# Honeypot Verification & Testing Script
# Tests health checks, network connectivity, and Wazuh integration
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INFRA_DIR="$PROJECT_DIR/infra"
HONEYPOT_IPS=("10.10.20.70" "10.10.20.71")
COWRIE_IP="10.10.20.70"
DIONAEA_IP="10.10.20.71"
WAZUH_MANAGER="wazuh.manager"
WAZUH_MANAGER_IP="10.10.30.20"

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"
}

echo "Checking Wazuh Manager container..."
if docker ps | grep -q "wazuh.manager"; then
    log_success "Wazuh Manager container is running"
else
    log_error "Wazuh Manager container is NOT running"
fi

# Check Traefik
if docker ps | grep -q traefik; then
    log_success "Traefik container is running"
else
    log_error "Traefik container is NOT running"
fi
}

# =============================================================================
# NETWORK CONNECTIVITY TESTS
# =============================================================================

check_network_connectivity() {
    print_header "SECTION 2: Network Connectivity Tests"

    log_info "Testing network connectivity to honeypots..."

    # Test Cowrie SSH port
    if nc -zv -w 2 "$COWRIE_IP" 2222 &>/dev/null; then
        log_success "Cowrie SSH port (2222) is accessible"
    else
        log_error "Cowrie SSH port (2222) is NOT accessible"
    fi

    # Test Cowrie Telnet port
    if nc -zv -w 2 "$COWRIE_IP" 2223 &>/dev/null; then
        log_success "Cowrie Telnet port (2223) is accessible"
    else
        log_error "Cowrie Telnet port (2223) is NOT accessible"
    fi

    # Test Dionaea SMB port
    if nc -zv -w 2 "$DIONAEA_IP" 445 &>/dev/null; then
        log_success "Dionaea SMB port (445) is accessible"
    else
        log_error "Dionaea SMB port (445) is NOT accessible"
    fi

    # Test Dionaea FTP port
    if nc -zv -w 2 "$DIONAEA_IP" 21 &>/dev/null; then
        log_success "Dionaea FTP port (21) is accessible"
    else
        log_error "Dionaea FTP port (21) is NOT accessible"
    fi

    # Test Dionaea HTTP port
    if curl -s -m 2 "http://$DIONAEA_IP:80" &>/dev/null; then
        log_success "Dionaea HTTP port (80) is accessible"
    else
        log_error "Dionaea HTTP port (80) is NOT accessible"
    fi

    # Test Dionaea MSSQL port
    if nc -zv -w 2 "$DIONAEA_IP" 1433 &>/dev/null; then
        log_success "Dionaea MSSQL port (1433) is accessible"
    else
        log_error "Dionaea MSSQL port (1433) is NOT accessible"
    fi

    # Test Dionaea MySQL port
    if nc -zv -w 2 "$DIONAEA_IP" 3306 &>/dev/null; then
        log_success "Dionaea MySQL port (3306) is accessible"
    else
        log_error "Dionaea MySQL port (3306) is NOT accessible"
    fi
}

# =============================================================================
# CONTAINER LOGS INSPECTION
# =============================================================================

check_container_logs() {
    print_header "SECTION 3: Container Logs Inspection"

    log_info "Inspecting honeypot container logs..."

    # Check Cowrie logs
    if docker logs cowrie 2>&1 | head -20 | grep -q "cowrie"; then
        log_success "Cowrie logs are being generated"
    else
        log_warning "Cowrie logs may still be initializing"
    fi

    # Check Dionaea logs
    if docker logs dionaea 2>&1 | head -20 | grep -q "dionaea\|listening\|Started"; then
        log_success "Dionaea logs are being generated"
    else
        log_warning "Dionaea logs may still be initializing"
    fi

    # Display recent logs
    log_info "\n--- Last 5 lines of Cowrie logs ---"
    docker logs cowrie 2>&1 | tail -5 || log_warning "Unable to retrieve Cowrie logs"

    log_info "\n--- Last 5 lines of Dionaea logs ---"
    docker logs dionaea 2>&1 | tail -5 || log_warning "Unable to retrieve Dionaea logs"
}

# =============================================================================
# WAZUH INTEGRATION TESTS
# =============================================================================

check_wazuh_integration() {
    print_header "SECTION 4: Wazuh SIEM Integration Tests"

    log_info "Testing Wazuh integration and alert configuration..."

    # Check if Wazuh Manager is accessible
    if docker exec wazuh.manager test -f /var/ossec/etc/ossec.conf; then
        log_success "Wazuh Manager configuration accessible"
    else
        log_error "Unable to access Wazuh Manager configuration"
    fi

    # Check for honeypot logs in Wazuh alerts
    log_info "Checking for honeypot alerts in Wazuh..."
    if docker exec wazuh.manager grep -r "cowrie\|dionaea" /var/ossec/logs/alerts/ 2>/dev/null | head -1 | grep -q "cowrie\|dionaea"; then
        log_success "Honeypot alerts are appearing in Wazuh"
    else
        log_warning "Honeypot alerts may not be generated yet (awaiting attacks)"
    fi
}

# =============================================================================
# FILE SYSTEM CHECKS
# =============================================================================

check_file_system() {
    print_header "SECTION 5: File System & Log Directory Checks"

    log_info "Checking log directories and files..."

    # Check if log directories exist
    if [ -d "$INFRA_DIR/honeypot_logs" ]; then
        log_success "Honeypot logs directory exists"
    else
        log_error "Honeypot logs directory does NOT exist"
    fi

    # Check if Cowrie log subdirectory exists
    if [ -d "$INFRA_DIR/honeypot_logs/cowrie" ]; then
        log_success "Cowrie logs subdirectory exists"
    else
        log_error "Cowrie logs subdirectory does NOT exist"
    fi

    # Check if Dionaea log subdirectory exists
    if [ -d "$INFRA_DIR/honeypot_logs/dionaea" ]; then
        log_success "Dionaea logs subdirectory exists"
    else
        log_error "Dionaea logs subdirectory does NOT exist"
    fi

    # Check if configuration files exist
    if [ -f "$INFRA_DIR/configs/honeypot/cowrie.cfg" ]; then
        log_success "Cowrie configuration file exists"
    else
        log_error "Cowrie configuration file does NOT exist"
    fi

    if [ -f "$INFRA_DIR/configs/honeypot/dionaea.cfg" ]; then
        log_success "Dionaea configuration file exists"
    else
        log_error "Dionaea configuration file does NOT exist"
    fi

    # Check if Wazuh decoders and rules exist
    if [ -f "$INFRA_DIR/configs/wazuh/honeypot_decoders.xml" ]; then
        log_success "Wazuh honeypot decoders file exists"
    else
        log_error "Wazuh honeypot decoders file does NOT exist"
    fi

    if [ -f "$INFRA_DIR/configs/wazuh/honeypot_rules.xml" ]; then
        log_success "Wazuh honeypot rules file exists"
    else
        log_error "Wazuh honeypot rules file does NOT exist"
    fi
}

# =============================================================================
# TRAEFIK ROUTING CHECKS
# =============================================================================

check_traefik_routing() {
    print_header "SECTION 6: Traefik Routing Configuration"

    log_info "Verifying Traefik routing configuration..."

    # Check if dynamic.yml contains honeypot routers
    if grep -q "cowrie.cyberlab.local\|dionaea.cyberlab.local" "$INFRA_DIR/configs/traefik/dynamic.yml"; then
        log_success "Traefik honeypot routers are configured"
    else
        log_error "Traefik honeypot routers are NOT configured"
    fi

    # Check if honeypot services are in Traefik config
    if grep -q "cowrie-svc\|dionaea-svc" "$INFRA_DIR/configs/traefik/dynamic.yml"; then
        log_success "Traefik honeypot service entries exist"
    else
        log_error "Traefik honeypot service entries NOT found"
    fi
}

# =============================================================================
# SIMULATION & ATTACK DETECTION TESTS
# =============================================================================

test_ssh_honeypot() {
    print_header "SECTION 7: SSH Honeypot Attack Simulation"

    log_info "Simulating SSH attack on Cowrie..."

    # Test SSH connection attempt with timeout
    if timeout 2 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p 2222 testuser@"$COWRIE_IP" 2>&1 | grep -q "Permission denied\|refused\|closed\|banner"; then
        log_success "SSH honeypot responded to connection attempt"
    else
        log_warning "SSH honeypot connection attempt did not complete (may require credentials)"
    fi

    log_info "Waiting 5 seconds for logs to be written..."
    sleep 5
}

test_http_honeypot() {
    print_header "SECTION 8: HTTP Honeypot Attack Simulation"

    log_info "Simulating HTTP request to Dionaea..."

    # Test HTTP request
    if curl -s -m 3 "http://$DIONAEA_IP" -H "User-Agent: curl-attacker/1.0" | grep -q "html\|HTTP\|<\|Server"; then
        log_success "HTTP honeypot responded to request"
    else
        log_warning "HTTP honeypot did not return expected response"
    fi

    log_info "Waiting 5 seconds for logs to be written..."
    sleep 5
}

test_ftp_honeypot() {
    print_header "SECTION 9: FTP Honeypot Attack Simulation"

    log_info "Simulating FTP connection to Dionaea..."

    # Test FTP connection attempt
    if echo "quit" | timeout 2 nc "$DIONAEA_IP" 21 2>&1 | grep -q "220\|FTP\|Welcome"; then
        log_success "FTP honeypot responded to connection attempt"
    else
        log_warning "FTP honeypot may not be responding as expected"
    fi

    log_info "Waiting 5 seconds for logs to be written..."
    sleep 5
}

# =============================================================================
# SUMMARY REPORT
# =============================================================================

print_summary() {
    print_header "TEST SUMMARY REPORT"

    total_tests=$((TESTS_PASSED + TESTS_FAILED))

    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo -e "Total Tests: $total_tests\n"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✓ ALL TESTS PASSED - HONEYPOT DEPLOYMENT SUCCESSFUL${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════${NC}\n"
        return 0
    else
        echo -e "${RED}════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}✗ SOME TESTS FAILED - REVIEW ERRORS ABOVE${NC}"
        echo -e "${RED}════════════════════════════════════════════════════════${NC}\n"
        return 1
    fi
}

print_next_steps() {
    print_header "NEXT STEPS & RECOMMENDATIONS"

    echo "1. Monitor Wazuh Dashboard: https://wazuh.cyberlab.local"
    echo "   - Check for honeypot alerts (Rule IDs: 100200-100299)"
    echo ""
    echo "2. Access Honeypot Dashboards:"
    echo "   - Cowrie: https://cowrie.cyberlab.local"
    echo "   - Dionaea: https://dionaea.cyberlab.local"
    echo ""
    echo "3. View Honeypot Logs:"
    echo "   - Local logs: $INFRA_DIR/honeypot_logs/"
    echo "   - Docker logs: docker logs cowrie / docker logs dionaea"
    echo ""
    echo "4. Test Honeypot Responses:"
    echo "   - SSH: ssh -p 2222 testuser@$COWRIE_IP"
    echo "   - Telnet: telnet $COWRIE_IP 2223"
    echo "   - HTTP: curl http://$DIONAEA_IP"
    echo "   - SMB: smbclient -L //$DIONAEA_IP"
    echo ""
    echo "5. Review Wazuh Integration:"
    echo "   - Check decoders: docker exec wazuh.manager ls /var/ossec/etc/decoders/"
    echo "   - Check rules: docker exec wazuh.manager ls /var/ossec/etc/rules/"
    echo ""
    echo "6. Monitor Performance:"
    echo "   - Watch CPU/Memory usage: docker stats cowrie dionaea"
    echo "   - Check disk usage: df -h $INFRA_DIR/honeypot_logs/"
    echo ""
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   HONEYPOT SERVICES VERIFICATION & TESTING SUITE       ║${NC}"
    echo -e "${BLUE}║   Cowrie SSH/Telnet & Dionaea Multi-Protocol           ║${NC}"
    echo -e "${BLUE}║   Deployment: $(date '+%Y-%m-%d %H:%M:%S')                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Run all checks
    check_docker_containers
    check_network_connectivity
    check_container_logs
    check_file_system
    check_traefik_routing
    check_wazuh_integration

    # Run optional attack simulations (if flag provided)
    if [ "${1:-}" == "--test-attacks" ]; then
        test_ssh_honeypot
        test_http_honeypot
        test_ftp_honeypot
    else
        log_info "Skipping attack simulations (use --test-attacks flag to enable)"
    fi

    # Print summary and next steps
    print_summary
    if [ $? -eq 0 ]; then
        print_next_steps
    fi

    return $([ $TESTS_FAILED -eq 0 ] && echo 0 || echo 1)
}

# Execute main function
main "$@"
echo "  3. Review honeypot logs and Wazuh alerts"
echo "  4. Verify rule IDs 100200-100299 are firing"
echo ""
echo -e "${GREEN}Honeypot deployment verification complete!${NC}"
