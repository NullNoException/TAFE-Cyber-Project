#!/bin/bash
# =============================================================================
# Specific Detection Simulation Script
# Simulates Signal, Trigger, and Operator Action events
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
COWRIE_IP="10.10.20.72"
DIONAEA_IP="10.10.20.71"
WAZUH_MANAGER_CONTAINER="wazuh.manager"

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

# =============================================================================
# PRE-CHECK: PACKET CAPTURE
# =============================================================================
print_header "PRE-CHECK: Packet Capture Status"

if docker ps | grep -q "tcpdump-collector"; then
    log_success "tcpdump-collector is running"
    
    # Check if pcap file is growing
    PCAP_FILE=$(docker exec tcpdump-collector ls -t /pcap | head -1)
    if [ -n "$PCAP_FILE" ]; then
        log_success "Found PCAP file: $PCAP_FILE"
        INITIAL_SIZE=$(docker exec tcpdump-collector stat -c%s "/pcap/$PCAP_FILE")
        log_info "Initial size: $INITIAL_SIZE bytes"
    else
        log_warning "No PCAP file found in /pcap"
    fi
else
    log_warning "tcpdump-collector is NOT running. Packet capture may not be active."
fi

# =============================================================================
# 1. SIGNAL DETECTION SIMULATION
# Goal: Trigger Rule 110001 (Signal Detected)
# Methods: Port Scanning, Failed Login
# =============================================================================
print_header "1. SIGNAL DETECTION SIMULATION"
log_info "Simulating reconnaissance and failed access attempts..."

# Port Scan on Dionaea
log_info "Performing port scan on Dionaea ($DIONAEA_IP)..."
for port in 21 80 443 445 1433 3306; do
    timeout 1 bash -c "echo > /dev/tcp/$DIONAEA_IP/$port" 2>/dev/null || true
done
log_success "Port scan completed"

# Failed SSH Login on Cowrie
log_info "Attempting failed SSH login on Cowrie ($COWRIE_IP)..."
timeout 5 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=2 -p 2222 \
    "fakeuser@$COWRIE_IP" "wrongpassword" &>/dev/null || true
log_success "Failed SSH login attempt completed"

log_info "Waiting 5 seconds for logs to process..."
sleep 5

# =============================================================================
# 2. TRIGGER DETECTION SIMULATION
# Goal: Trigger Rule 110002 (Trigger Detected)
# Methods: SQL Injection, HTTP Exploit
# =============================================================================
print_header "2. TRIGGER DETECTION SIMULATION"
log_info "Simulating exploitation attempts..."

# SQL Injection on Dionaea HTTP
log_info "Sending SQL Injection payload to Dionaea..."
curl -s "http://$DIONAEA_IP/login.php?user=admin' OR '1'='1" -o /dev/null || true
log_success "SQL Injection payload sent"

# HTTP Exploit Attempt
log_info "Sending HTTP exploit payload..."
curl -s "http://$DIONAEA_IP/cgi-bin/test-cgi" -o /dev/null || true
log_success "HTTP exploit payload sent"

log_info "Waiting 5 seconds for logs to process..."
sleep 5

# =============================================================================
# 3. OPERATOR ACTION DETECTION SIMULATION
# Goal: Trigger Rule 110003 (Operator Action Detected)
# Methods: Command Execution, File Download
# =============================================================================
print_header "3. OPERATOR ACTION DETECTION SIMULATION"
log_info "Simulating post-exploitation actions..."

# Simulate Command Execution (via Cowrie SSH if possible, or HTTP command injection on Dionaea)
# Since we can't easily login to Cowrie without valid creds in this script, we'll use Dionaea HTTP command injection patterns
log_info "Simulating command execution attempt..."
curl -s "http://$DIONAEA_IP/cmd.php?cmd=cat+/etc/passwd" -o /dev/null || true
log_success "Command execution simulation sent"

# Simulate File Download (Malware download attempt)
log_info "Simulating malware download attempt..."
curl -s -X POST -F "file=@/dev/null" "http://$DIONAEA_IP/upload.php" -o /dev/null || true
log_success "File download simulation sent"

# =============================================================================
# POST-CHECK: PACKET CAPTURE VERIFICATION
# =============================================================================
print_header "POST-CHECK: Packet Capture Verification"

if [ -n "$PCAP_FILE" ]; then
    FINAL_SIZE=$(docker exec tcpdump-collector stat -c%s "/pcap/$PCAP_FILE")
    log_info "Final size: $FINAL_SIZE bytes"
    
    if [ "$FINAL_SIZE" -gt "$INITIAL_SIZE" ]; then
        log_success "Packet capture verified: File size increased by $((FINAL_SIZE - INITIAL_SIZE)) bytes"
    else
        log_warning "Packet capture file size did not increase. Check tcpdump configuration."
    fi
fi

# =============================================================================
# SUMMARY
# =============================================================================
print_header "Simulation Complete"
log_info "Please check Wazuh Dashboard for the following alerts:"
echo -e "  - ${YELLOW}Rule 110001: SIGNAL DETECTED${NC}"
echo -e "  - ${RED}Rule 110002: TRIGGER DETECTED${NC}"
echo -e "  - ${RED}Rule 110003: OPERATOR ACTION DETECTED${NC}"
echo ""
log_info "You can view the captured packets in the Wireshark UI at https://localhost:3000 (via Traefik) or http://localhost:3000"
