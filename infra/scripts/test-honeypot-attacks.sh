#!/bin/bash
# =============================================================================
# Honeypot Attack Simulation Script
# Simulates controlled attacks against honeypots for testing
# =============================================================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
COWRIE_IP="10.10.20.70"
COWRIE_SSH_PORT=2222
COWRIE_TELNET_PORT=2223
DIONAEA_IP="10.10.20.71"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Honeypot Attack Simulation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# =============================================================================
# TEST 1: SSH BRUTE-FORCE ATTACK (Cowrie)
# =============================================================================
echo -e "${YELLOW}[1] SSH Brute-Force Attack Simulation${NC}"
echo "---"
echo "Simulating SSH login attempts against Cowrie..."
echo ""

# Create a list of test credentials
TEST_CREDS=(
    "root:password123"
    "admin:admin123"
    "test:test123"
    "guest:guest123"
    "user:12345678"
)

# Attempt SSH connections with various credentials
for cred in "${TEST_CREDS[@]}"; do
    username="${cred%:*}"
    password="${cred#*:}"
    
    echo "Attempting SSH login: $username@$COWRIE_IP:$COWRIE_SSH_PORT"
    
    # Non-interactive SSH attempt (will fail, which is expected)
    (echo "$password" | timeout 5 sshpass -p "$password" ssh -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=3 \
        "$username@$COWRIE_IP" -p "$COWRIE_SSH_PORT" \
        "ls -la" 2>/dev/null || true)
    
    sleep 1
done

echo -e "${GREEN}✓ SSH brute-force simulation complete${NC}"
echo ""

# =============================================================================
# TEST 2: TELNET CONNECTION (Cowrie)
# =============================================================================
echo -e "${YELLOW}[2] Telnet Connection Simulation${NC}"
echo "---"
echo "Attempting Telnet connection to Cowrie..."

# Attempt telnet connection (will fail, which is expected)
(timeout 5 telnet "$COWRIE_IP" "$COWRIE_TELNET_PORT" < /dev/null 2>&1 || true) | head -5

echo -e "${GREEN}✓ Telnet connection attempt complete${NC}"
echo ""

# =============================================================================
# TEST 3: HTTP REQUESTS (Dionaea)
# =============================================================================
echo -e "${YELLOW}[3] HTTP Request Simulation${NC}"
echo "---"
echo "Sending HTTP requests to Dionaea..."
echo ""

# Normal HTTP GET
echo "HTTP GET request..."
(timeout 5 curl -v "http://$DIONAEA_IP/" 2>&1 | head -10 || true)

# HTTP request with SQL injection payload
echo ""
echo "HTTP request with SQL injection payload..."
(timeout 5 curl -v "http://$DIONAEA_IP/?id=1' OR '1'='1" 2>&1 | head -10 || true)

# HTTP POST request
echo ""
echo "HTTP POST request..."
(timeout 5 curl -X POST "http://$DIONAEA_IP/login" \
    -d "username=admin&password=admin123" 2>&1 | head -10 || true)

echo -e "${GREEN}✓ HTTP request simulation complete${NC}"
echo ""

# =============================================================================
# TEST 4: SMB CONNECTION (Dionaea)
# =============================================================================
echo -e "${YELLOW}[4] SMB Connection Simulation${NC}"
echo "---"
echo "Attempting SMB connection to Dionaea..."

# Check if smbclient is available
if command -v smbclient &> /dev/null; then
    (timeout 5 smbclient -L "//$DIONAEA_IP" -U "admin%password" 2>&1 | head -10 || true)
    echo -e "${GREEN}✓ SMB connection attempt complete${NC}"
else
    echo -e "${YELLOW}⚠ smbclient not installed, skipping SMB test${NC}"
    echo "  Install with: apt-get install samba-client"
fi

echo ""

# =============================================================================
# TEST 5: FTP CONNECTION (Dionaea)
# =============================================================================
echo -e "${YELLOW}[5] FTP Connection Simulation${NC}"
echo "---"
echo "Attempting FTP connection to Dionaea..."

# Create FTP commands
(timeout 5 bash -c 'exec 3<>/dev/tcp/'$DIONAEA_IP'/21; cat <&3' 2>&1 | head -5 || true)

echo -e "${GREEN}✓ FTP connection attempt complete${NC}"
echo ""

# =============================================================================
# TEST 6: PORT SCANNING (Dionaea)
# =============================================================================
echo -e "${YELLOW}[6] Port Scanning Simulation${NC}"
echo "---"
echo "Performing port scan against Dionaea..."

# Check if nmap is available
if command -v nmap &> /dev/null; then
    echo "Running nmap scan against $DIONAEA_IP..."
    nmap -p 21,22,80,443,445,1433,3306,3389 "$DIONAEA_IP" 2>/dev/null || true
    echo -e "${GREEN}✓ Port scan simulation complete${NC}"
else
    echo -e "${YELLOW}⚠ nmap not installed, using manual port checks${NC}"
    
    PORTS=(21 80 443 445 1433 3306 3389)
    for port in "${PORTS[@]}"; do
        if timeout 2 bash -c "echo > /dev/tcp/$DIONAEA_IP/$port" 2>/dev/null; then
            echo "  Port $port: OPEN"
        else
            echo "  Port $port: CLOSED/FILTERED"
        fi
    done
fi

echo ""

# =============================================================================
# TEST 7: CHECK LOGS AFTER ATTACK SIMULATION
# =============================================================================
echo -e "${YELLOW}[7] Log Generation Verification${NC}"
echo "---"
echo "Checking if attacks were logged by honeypots..."
echo ""

# Check Cowrie logs
echo "Cowrie logs (last 10 lines):"
docker logs --tail 10 cowrie 2>/dev/null | tail -5 || echo "  (No logs available)"

echo ""

echo "Dionaea logs (last 10 lines):"
docker logs --tail 10 dionaea 2>/dev/null | tail -5 || echo "  (No logs available)"

echo ""

# =============================================================================
# SUMMARY
# =============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Attack Simulation Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Attacks simulated:"
echo "  ✓ SSH brute-force against Cowrie"
echo "  ✓ Telnet connection against Cowrie"
echo "  ✓ HTTP requests against Dionaea"
echo "  ✓ SMB connection attempt against Dionaea"
echo "  ✓ FTP connection attempt against Dionaea"
echo "  ✓ Port scanning against Dionaea"
echo ""
echo "Next steps:"
echo "  1. Wait 30 seconds for logs to be processed"
echo "  2. Check Wazuh dashboard for alerts"
echo "  3. Review honeypot logs in:"
echo "     - ./honeypot_logs/cowrie/"
echo "     - ./honeypot_logs/dionaea/"
echo "  4. Verify rule IDs 100200-100299 are firing in Wazuh"
echo ""
echo -e "${GREEN}Attack simulation complete!${NC}"
echo ""
echo "To view honeypot logs:"
echo "  docker logs -f cowrie"
echo "  docker logs -f dionaea"
echo ""
echo "To view Wazuh alerts:"
echo "  docker exec wazuh.manager tail -f /var/ossec/logs/alerts/alerts.json | grep -E 'cowrie|dionaea'"
