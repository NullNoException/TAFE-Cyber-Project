#!/bin/bash
###############################################################################
# DNS Resolution Verification Script for Prometheus & Grafana
###############################################################################

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║    DNS Resolution Verification - Monitoring Stack             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# DNS Server IP
DNS_SERVER="10.10.30.101"
DOMAIN="cyberlab.local"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test DNS resolution
test_dns_resolution() {
    local hostname=$1
    local expected_ip=$2
    
    echo -n "Testing: $hostname → "
    
    result=$(docker exec dns-server dig +short $hostname @127.0.0.1 A | head -1)
    
    if [ "$result" = "$expected_ip" ]; then
        echo -e "${GREEN}✓ $result${NC}"
        return 0
    else
        echo -e "${RED}✗ Expected: $expected_ip, Got: $result${NC}"
        return 1
    fi
}

# Function to test reverse DNS resolution
test_reverse_dns() {
    local ip=$1
    local expected_hostname=$2
    
    echo -n "Reverse: $ip → "
    
    result=$(docker exec dns-server dig +short -x $ip @127.0.0.1 | head -1 | sed 's/\.$//')
    
    if [ "$result" = "$expected_hostname" ]; then
        echo -e "${GREEN}✓ $result${NC}"
        return 0
    else
        echo -e "${RED}✗ Expected: $expected_hostname, Got: $result${NC}"
        return 1
    fi
}

echo "═══════════════════════════════════════════════════════════════"
echo "1. FORWARD RESOLUTION (A Records)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

forward_ok=true
test_dns_resolution "prometheus.$DOMAIN" "10.10.30.50" || forward_ok=false
test_dns_resolution "grafana.$DOMAIN" "10.10.30.60" || forward_ok=false
test_dns_resolution "traefik.$DOMAIN" "10.10.10.5" || forward_ok=false
test_dns_resolution "wazuh.$DOMAIN" "10.10.10.5" || forward_ok=false

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "2. REVERSE RESOLUTION (PTR Records)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

reverse_ok=true
test_reverse_dns "10.10.30.50" "prometheus.$DOMAIN" || reverse_ok=false
test_reverse_dns "10.10.30.60" "grafana.$DOMAIN" || reverse_ok=false

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "3. SERVICE AVAILABILITY CHECK"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check if services are responding
check_service() {
    local hostname=$1
    local port=$2
    
    echo -n "Checking: $hostname:$port ... "
    
    if timeout 2 docker exec traefik curl -s -k https://$hostname:$port/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Responding${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Not responding (may need service restart)${NC}"
        return 1
    fi
}

check_service "prometheus.$DOMAIN" "443"
check_service "grafana.$DOMAIN" "443"
check_service "traefik.$DOMAIN" "443"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "4. ZONE FILE VALIDATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check zone file syntax
echo -n "Validating forward zone: "
if docker exec dns-server named-checkzone cyberlab.local /etc/bind/zones/db.cyberlab.local > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Valid${NC}"
else
    echo -e "${RED}✗ Invalid${NC}"
fi

echo -n "Validating reverse zone: "
if docker exec dns-server named-checkzone 30.10.10.in-addr.arpa /etc/bind/zones/db.10.10.30.rev > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Valid${NC}"
else
    echo -e "${RED}✗ Invalid${NC}"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "5. SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ "$forward_ok" = true ] && [ "$reverse_ok" = true ]; then
    echo -e "${GREEN}✓ ALL DNS RECORDS VERIFIED SUCCESSFULLY${NC}"
    echo ""
    echo "You can now access:"
    echo "  • https://prometheus.cyberlab.local"
    echo "  • https://grafana.cyberlab.local"
    echo ""
    exit 0
else
    echo -e "${RED}✗ SOME DNS RECORDS FAILED VERIFICATION${NC}"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. Restart DNS server: docker-compose restart dns-server"
    echo "  2. Check DNS logs: docker logs dns-server"
    echo "  3. Verify zone files syntax"
    echo "  4. Check network connectivity between services"
    echo ""
    exit 1
fi
