#!/bin/bash

###############################################################################
# DNS Server Testing Script for CyberLab Infrastructure
# Tests DNS functionality across all network segments
# Usage: ./test-dns.sh [option]
# Options: all, external, internal, security, management, dns-console
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DNS_CONTAINER="dns-server"
DNS_IP_EXTERNAL="10.10.0.50"
DNS_IP_DMZ="10.10.10.50"
DNS_IP_INTERNAL="10.10.20.50"
DNS_IP_SECURITY="10.10.30.50"
DNS_IP_MANAGEMENT="10.10.40.50"
DNS_CONSOLE_PORT="5380"
DNS_SERVICE_PORT="53"

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}\n"
}

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS:${NC} $2"
    else
        echo -e "${RED}✗ FAIL:${NC} $2"
    fi
}

# Function to test DNS resolution from a container
test_dns_from_container() {
    local container_name=$1
    local dns_ip=$2
    local network_name=$3

    print_header "Testing DNS from $container_name ($network_name)"

    # Test if container is running
    if ! docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -q "$container_name"; then
        echo -e "${YELLOW}⚠ Container $container_name is not running${NC}"
        return 1
    fi

    echo "Testing DNS resolution from $container_name..."

    # Test DNS queries
    echo -e "\n${YELLOW}1. Testing DNS query to dns-server:${NC}"
    docker exec "$container_name" nslookup dns-server 2>/dev/null || echo "nslookup not available, trying dig..."
    docker exec "$container_name" dig @"$dns_ip" dns-server +short 2>/dev/null || echo "dig not available in container"

    echo -e "\n${YELLOW}2. Testing DNS query to localhost:${NC}"
    docker exec "$container_name" nslookup localhost "$dns_ip" 2>/dev/null || echo "localhost query failed"

    echo -e "\n${YELLOW}3. Testing DNS query to google.com (if recursion enabled):${NC}"
    docker exec "$container_name" dig @"$dns_ip" google.com +short 2>/dev/null || echo "google.com query failed"

    echo -e "\n${YELLOW}4. Testing DNS query to cyberlab.local domain:${NC}"
    docker exec "$container_name" dig @"$dns_ip" cyberlab.local +short 2>/dev/null || echo "cyberlab.local query failed"
}

# Function to test DNS console accessibility
test_dns_console() {
    print_header "Testing DNS Console Accessibility"

    echo "DNS Console URL: http://dns.cyberlab.local:$DNS_CONSOLE_PORT"
    echo "Direct Access: http://localhost:$DNS_CONSOLE_PORT"

    echo -e "\n${YELLOW}Testing direct port access:${NC}"

    # Test if DNS console port is accessible
    if timeout 5 bash -c "</dev/tcp/localhost/$DNS_CONSOLE_PORT" 2>/dev/null; then
        print_result 0 "DNS Console port $DNS_CONSOLE_PORT is accessible"
    else
        print_result 1 "DNS Console port $DNS_CONSOLE_PORT is not accessible"
    fi

    echo -e "\n${YELLOW}Testing HTTP connectivity:${NC}"
    if command -v curl &> /dev/null; then
        response=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "http://localhost:$DNS_CONSOLE_PORT" 2>/dev/null || echo "000")
        if [ "$response" = "200" ] || [ "$response" = "301" ] || [ "$response" = "302" ]; then
            print_result 0 "DNS Console HTTP response: $response"
        else
            print_result 1 "DNS Console HTTP response: $response"
        fi
    else
        echo "curl not available, skipping HTTP test"
    fi
}

# Function to test DNS port accessibility
test_dns_ports() {
    print_header "Testing DNS Port Accessibility"

    echo -e "${YELLOW}Testing UDP port 53:${NC}"
    if timeout 2 bash -c "</dev/udp/127.0.0.1/53" 2>/dev/null; then
        print_result 0 "DNS UDP port 53 is accessible"
    else
        print_result 1 "DNS UDP port 53 is not directly accessible (might be blocked by host firewall)"
    fi

    echo -e "\n${YELLOW}Testing TCP port 53:${NC}"
    if timeout 2 bash -c "</dev/tcp/127.0.0.1/53" 2>/dev/null; then
        print_result 0 "DNS TCP port 53 is accessible"
    else
        print_result 1 "DNS TCP port 53 is not directly accessible (might be blocked by host firewall)"
    fi
}

# Function to test DNS service health
test_dns_health() {
    print_header "Testing DNS Service Health"

    echo "Checking DNS container status..."
    if docker ps | grep -q "$DNS_CONTAINER"; then
        print_result 0 "DNS container is running"

        # Get container details
        echo -e "\n${YELLOW}Container Details:${NC}"
        docker inspect "$DNS_CONTAINER" --format='IP Address: {{.NetworkSettings.IPAddress}}'
        docker inspect "$DNS_CONTAINER" --format='Status: {{.State.Status}}'
        docker inspect "$DNS_CONTAINER" --format='Memory Usage: {{.HostConfig.Memory}} bytes'

    else
        print_result 1 "DNS container is not running"
    fi

    echo -e "\n${YELLOW}Checking DNS container logs:${NC}"
    docker logs "$DNS_CONTAINER" --tail=20 2>/dev/null | head -20
}

# Function to test DNS from all container networks
test_all_networks() {
    print_header "Testing DNS from All Networks"

    # Test from various containers
    local containers=("traefik" "nginx" "openldap" "wazuh.manager" "postgresql" "rocketchat" "mongodb")

    for container in "${containers[@]}"; do
        if docker ps --filter "name=^$container$" --format "{{.Names}}" | grep -q "^$container$"; then
            echo -e "\n${YELLOW}Testing from $container:${NC}"
            # Simple DNS test
            docker exec "$container" sh -c "echo 'Attempting DNS query...' && nslookup dns-server 2>/dev/null || echo 'DNS query may have failed'" || echo "Container $container test skipped"
        fi
    done
}

# Function to display DNS configuration
display_dns_config() {
    print_header "DNS Server Configuration"

    echo -e "${YELLOW}DNS Server Details:${NC}"
    echo "Container Name: $DNS_CONTAINER"
    echo "Image: technitium/dns-server:latest"
    echo ""
    echo -e "${YELLOW}Network Configuration:${NC}"
    echo "  External Network: $DNS_IP_EXTERNAL (10.10.0.0/24)"
    echo "  DMZ Network: $DNS_IP_DMZ (10.10.10.0/24)"
    echo "  Internal Network: $DNS_IP_INTERNAL (10.10.20.0/24)"
    echo "  Security Network: $DNS_IP_SECURITY (10.10.30.0/24)"
    echo "  Management Network: $DNS_IP_MANAGEMENT (10.10.40.0/24)"
    echo ""
    echo -e "${YELLOW}Port Configuration:${NC}"
    echo "  DNS Service Port: $DNS_SERVICE_PORT (TCP/UDP)"
    echo "  Web Console Port: $DNS_CONSOLE_PORT (HTTP)"
    echo ""
    echo -e "${YELLOW}Access Points:${NC}"
    echo "  Web Console: http://dns.cyberlab.local:$DNS_CONSOLE_PORT"
    echo "  Alternative: http://dns-console.cyberlab.local:$DNS_CONSOLE_PORT"
    echo "  Direct Local: http://localhost:$DNS_CONSOLE_PORT"
    echo "  Via Traefik: https://dns.cyberlab.local"
}

# Function to show quick test summary
quick_test() {
    print_header "Quick DNS Test Summary"

    echo -e "${YELLOW}1. DNS Service Health:${NC}"
    if docker ps | grep -q "$DNS_CONTAINER"; then
        echo -e "${GREEN}✓${NC} DNS container is running"
    else
        echo -e "${RED}✗${NC} DNS container is not running"
    fi

    echo -e "\n${YELLOW}2. DNS Network Connectivity:${NC}"
    docker inspect "$DNS_CONTAINER" --format='Networks: {{range $k := .NetworkSettings.Networks}}{{$k}} {{end}}' 2>/dev/null || echo "Unable to get network info"

    echo -e "\n${YELLOW}3. DNS Console Accessibility:${NC}"
    if command -v curl &> /dev/null; then
        response=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "http://localhost:5380" 2>/dev/null || echo "000")
        if [ "$response" != "000" ]; then
            echo -e "${GREEN}✓${NC} DNS Console is accessible (HTTP $response)"
        else
            echo -e "${YELLOW}⚠${NC} DNS Console not directly accessible (try via Traefik)"
        fi
    fi

    echo -e "\n${YELLOW}4. Test Commands:${NC}"
    echo "   From Host: dig @127.0.0.1 dns-server"
    echo "   From Container: docker exec <container> dig @10.10.20.50 dns-server"
    echo "   From Console: http://localhost:5380"
}

# Main script logic
main() {
    case "${1:-all}" in
        all)
            display_dns_config
            test_dns_health
            test_dns_ports
            test_dns_console
            test_all_networks
            ;;
        external)
            test_dns_from_container "openvpn" "$DNS_IP_EXTERNAL" "External Network"
            ;;
        internal)
            test_dns_from_container "nginx" "$DNS_IP_INTERNAL" "Internal Network"
            test_dns_from_container "openldap" "$DNS_IP_INTERNAL" "Internal Network"
            ;;
        security)
            test_dns_from_container "wazuh.manager" "$DNS_IP_SECURITY" "Security Network"
            ;;
        management)
            test_dns_from_container "traefik" "$DNS_IP_MANAGEMENT" "Management Network"
            ;;
        dns-console)
            test_dns_console
            ;;
        health)
            test_dns_health
            ;;
        quick)
            quick_test
            ;;
        *)
            echo "Usage: $0 {all|external|internal|security|management|dns-console|health|quick}"
            echo ""
            echo "Options:"
            echo "  all          - Run all DNS tests"
            echo "  external     - Test DNS from external network"
            echo "  internal     - Test DNS from internal network"
            echo "  security     - Test DNS from security network"
            echo "  management   - Test DNS from management network"
            echo "  dns-console  - Test DNS web console accessibility"
            echo "  health       - Test DNS service health"
            echo "  quick        - Quick test summary"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
