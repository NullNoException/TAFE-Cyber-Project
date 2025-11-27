#!/bin/bash
# =============================================================================
# Honeypot Attack Simulation Script
# Simulates various attack patterns to test honeypot detection
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
COWRIE_IP="10.10.20.70"
COWRIE_SSH_PORT="2222"
COWRIE_TELNET_PORT="2223"
DIONAEA_IP="10.10.20.71"
ATTACK_USERNAME="attacker"
ATTACK_PASSWORD="password123"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}\n"
}

print_header "Honeypot Attack Simulation Suite"

# =============================================================================
# SSH BRUTE FORCE ATTACKS
# =============================================================================
print_header "SECTION 1: SSH Brute Force Attack Simulation"

log_info "Attempting SSH connections to Cowrie (port $COWRIE_SSH_PORT)..."

# Simulate multiple SSH attempts
for i in {1..5}; do
    log_info "SSH attempt $i of 5..."
    timeout 2 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=1 -p "$COWRIE_SSH_PORT" \
        "user$i@$COWRIE_IP" &>/dev/null || true
    sleep 0.5
done

log_success "SSH brute force simulation completed"

# =============================================================================
# TELNET ATTACKS
# =============================================================================
print_header "SECTION 2: Telnet Connection Attempt"

log_info "Attempting Telnet connection to Cowrie (port $COWRIE_TELNET_PORT)..."

echo -e "admin\npassword\nquit" | timeout 2 telnet "$COWRIE_IP" "$COWRIE_TELNET_PORT" 2>/dev/null || true

log_success "Telnet connection attempt completed"

# =============================================================================
# HTTP/HTTPS ATTACKS
# =============================================================================
print_header "SECTION 3: HTTP/HTTPS Attack Simulation"

log_info "Simulating HTTP requests to Dionaea..."

# Normal request
curl -s -H "User-Agent: Mozilla/5.0" "http://$DIONAEA_IP/" -o /dev/null
log_success "Normal HTTP request sent"

# Admin panel access attempt
curl -s "http://$DIONAEA_IP/admin" -o /dev/null || true
log_success "Admin panel access attempt"

# SQL injection attempt
curl -s "http://$DIONAEA_IP/search?q=1' OR '1'='1" -o /dev/null || true
log_success "SQL injection attempt"

# Path traversal attempt
curl -s "http://$DIONAEA_IP/../../../etc/passwd" -o /dev/null || true
log_success "Path traversal attempt"

# PHP webshell upload attempt
curl -s -X POST -F "file=@/dev/null" "http://$DIONAEA_IP/upload" -o /dev/null || true
log_success "Webshell upload attempt"

# =============================================================================
# SMB/CIFS ATTACKS
# =============================================================================
print_header "SECTION 4: SMB/CIFS Attack Simulation"

log_info "Simulating SMB connection attempts to Dionaea..."

# Test SMB connectivity
echo "quit" | timeout 2 smbclient -L //"$DIONAEA_IP" -U guest%guest 2>/dev/null || log_warning "SMB connection may require specific credentials"

log_success "SMB connection attempt completed"

# =============================================================================
# FTP ATTACKS
# =============================================================================
print_header "SECTION 5: FTP Attack Simulation"

log_info "Simulating FTP authentication attempts..."

# Anonymous FTP login
echo -e "user anonymous\npassword\nquit" | timeout 2 ftp -n "$DIONAEA_IP" &>/dev/null || true
log_success "Anonymous FTP attempt"

# Brute force FTP attempts
for i in {1..3}; do
    timeout 2 ftp -n "$DIONAEA_IP" <<EOF &>/dev/null || true
user admin
pass password$i
quit
EOF
done

log_success "FTP brute force attempts completed"

# =============================================================================
# SQL DATABASE ATTACKS
# =============================================================================
print_header "SECTION 6: SQL Database Attack Simulation"

log_info "Simulating SQL injection attacks..."

# MySQL connection attempt
timeout 2 bash -c "echo > /dev/tcp/$DIONAEA_IP/3306" 2>/dev/null && \
    log_success "MySQL port is accessible" || \
    log_warning "MySQL port not responding"

# MSSQL connection attempt
timeout 2 bash -c "echo > /dev/tcp/$DIONAEA_IP/1433" 2>/dev/null && \
    log_success "MSSQL port is accessible" || \
    log_warning "MSSQL port not responding"

# =============================================================================
# PORT SCANNING SIMULATION
# =============================================================================
print_header "SECTION 7: Port Scanning Simulation"

log_info "Simulating port scanning activity..."

# Quick port scan
COMMON_PORTS=(21 22 25 53 80 135 139 445 1433 3306 3389)

for port in "${COMMON_PORTS[@]}"; do
    timeout 1 bash -c "echo > /dev/tcp/$DIONAEA_IP/$port" 2>/dev/null || true
done

log_success "Port scanning simulation completed"

# =============================================================================
# SLOW ATTACK SIMULATION (Distributed Low-Rate Attack)
# =============================================================================
print_header "SECTION 8: Low-Rate Attack Simulation"

log_info "Simulating slow, distributed attack pattern..."

for i in {1..10}; do
    # Slow HTTP requests
    curl -s -m 10 "http://$DIONAEA_IP/api/endpoint" -o /dev/null || true
    sleep 1
done

log_success "Low-rate attack simulation completed"

# =============================================================================
# CLEANUP & SUMMARY
# =============================================================================
print_header "Attack Simulation Summary"

log_info "All attack simulations have been completed"
log_info "Honeypots have been exposed to simulated attack patterns:"
log_info "  - SSH brute force attacks"
log_info "  - Telnet connection attempts"
log_info "  - HTTP/HTTPS exploits"
log_info "  - SMB reconnaissance"
log_info "  - FTP authentication attempts"
log_info "  - SQL injection attempts"
log_info "  - Port scanning"
log_info "  - Low-rate distributed attacks"
echo ""
log_success "Check Wazuh dashboard for generated alerts"
log_success "Review honeypot logs at: /infra/honeypot_logs/"

echo -e "\n${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}Attack simulation completed successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}\n"
