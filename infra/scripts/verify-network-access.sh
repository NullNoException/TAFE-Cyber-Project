#!/bin/bash

###############################################################################
# CyberLab Network Access Control Verification Script
#
# This script tests the Traefik IP whitelist access control policies
# Run from any container in the infrastructure
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
PASSED=0
FAILED=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     CyberLab Network Access Control Verification                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to test access
test_access() {
    local service="$1"
    local expected_status="$2"
    local description="$3"

    echo -n "Testing: $description... "

    # Use curl to test, ignoring certificate errors
    local http_code=$(curl -s -k -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 \
        "https://$service" 2>/dev/null || echo "000")

    if [ "$http_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC} (Expected HTTP $expected_status, got $http_code)"
        ((FAILED++))
    fi
}

# Function to get current container network
get_container_network() {
    # Get this container's IP and determine which network it's on
    local my_ip=$(hostname -I | awk '{print $1}')

    if [[ $my_ip == 10.10.0.* ]]; then
        echo "External"
    elif [[ $my_ip == 10.10.10.* ]]; then
        echo "DMZ"
    elif [[ $my_ip == 10.10.20.* ]]; then
        echo "Internal"
    elif [[ $my_ip == 10.10.30.* ]]; then
        echo "Security"
    elif [[ $my_ip == 10.10.40.* ]]; then
        echo "Management"
    else
        echo "Unknown"
    fi
}

MY_NETWORK=$(get_container_network)
MY_IP=$(hostname -I | awk '{print $1}')

echo -e "${YELLOW}Container Information:${NC}"
echo "  Network: $MY_NETWORK"
echo "  IP Address: $MY_IP"
echo ""

# Test based on current network
case "$MY_NETWORK" in
    "External")
        echo -e "${YELLOW}Testing from External Network (10.10.0.0/24)${NC}"
        echo ""
        test_access "web.cyberlab.local" "301" "Public Service - Nginx (should redirect)"
        test_access "traefik.cyberlab.local" "403" "Admin Service - Traefik Dashboard (should be blocked)"
        test_access "wazuh.cyberlab.local" "403" "Security Service - Wazuh (should be blocked)"
        test_access "ldap.cyberlab.local" "403" "Internal Service - LDAP Admin (should be blocked)"
        ;;

    "DMZ")
        echo -e "${YELLOW}Testing from DMZ Network (10.10.10.0/24)${NC}"
        echo ""
        test_access "web.cyberlab.local" "301" "Public Service - Nginx (should redirect)"
        test_access "traefik.cyberlab.local" "403" "Admin Service - Traefik Dashboard (should be blocked)"
        test_access "wazuh.cyberlab.local" "403" "Security Service - Wazuh (should be blocked)"
        test_access "ldap.cyberlab.local" "403" "Internal Service - LDAP Admin (should be blocked)"
        ;;

    "Internal")
        echo -e "${YELLOW}Testing from Internal Network (10.10.20.0/24)${NC}"
        echo ""
        test_access "web.cyberlab.local" "301" "Public Service - Nginx (should redirect)"
        test_access "ldap.cyberlab.local" "301" "Internal Service - LDAP Admin (should redirect)"
        test_access "chat.cyberlab.local" "301" "Internal Service - Rocket.Chat (should redirect)"
        test_access "workstation.cyberlab.local" "301" "Internal Service - Workstation (should redirect)"
        test_access "traefik.cyberlab.local" "403" "Admin Service - Traefik Dashboard (should be blocked)"
        test_access "wazuh.cyberlab.local" "403" "Security Service - Wazuh (should be blocked)"
        test_access "neuvector.cyberlab.local" "403" "Security Service - NeuVector (should be blocked)"
        ;;

    "Security")
        echo -e "${YELLOW}Testing from Security Network (10.10.30.0/24)${NC}"
        echo ""
        test_access "web.cyberlab.local" "301" "Public Service - Nginx (should redirect)"
        test_access "ldap.cyberlab.local" "301" "Internal Service - LDAP Admin (should redirect)"
        test_access "chat.cyberlab.local" "301" "Internal Service - Rocket.Chat (should redirect)"
        test_access "wazuh.cyberlab.local" "301" "Security Service - Wazuh (should redirect)"
        test_access "neuvector.cyberlab.local" "301" "Security Service - NeuVector (should redirect)"
        test_access "suricata.cyberlab.local" "301" "Security Service - Suricata (should redirect)"
        test_access "traefik.cyberlab.local" "403" "Admin Service - Traefik Dashboard (should be blocked)"
        test_access "openvpn.cyberlab.local" "403" "Admin Service - OpenVPN (should be blocked)"
        ;;

    "Management")
        echo -e "${YELLOW}Testing from Management Network (10.10.40.0/24)${NC}"
        echo ""
        echo -e "${GREEN}Note: Management network has access to all services${NC}"
        echo ""
        test_access "traefik.cyberlab.local" "301" "Admin Service - Traefik Dashboard (should be accessible)"
        test_access "openvpn.cyberlab.local" "301" "Admin Service - OpenVPN (should be accessible)"
        test_access "dns.cyberlab.local" "301" "Admin Service - DNS Console (should be accessible)"
        test_access "neuvector.cyberlab.local" "301" "Security Service - NeuVector (should be accessible)"
        test_access "wazuh.cyberlab.local" "301" "Security Service - Wazuh (should be accessible)"
        test_access "ldap.cyberlab.local" "301" "Internal Service - LDAP Admin (should be accessible)"
        test_access "chat.cyberlab.local" "301" "Internal Service - Rocket.Chat (should be accessible)"
        test_access "web.cyberlab.local" "301" "Public Service - Nginx (should be accessible)"
        ;;

    *)
        echo -e "${RED}Unknown network for IP: $MY_IP${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Test Results                                                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Check Traefik configuration.${NC}"
    exit 1
fi
