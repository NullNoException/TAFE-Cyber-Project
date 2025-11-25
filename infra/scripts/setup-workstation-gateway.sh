#!/bin/bash
# Script to configure workstation as VPN gateway
# This enables VPN users to access all internal services through the workstation

set -euo pipefail

CONTAINER_NAME="workstation"

echo "Configuring workstation as VPN gateway..."

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container '$CONTAINER_NAME' is not running. Start it first:"
  echo "  cd infra && docker compose up -d workstation"
  exit 1
fi

echo "Installing required packages in workstation..."
docker exec "$CONTAINER_NAME" bash -c "apt-get update && apt-get install -y iptables iproute2 iputils-ping dnsutils curl" 2>/dev/null || true

echo "Enabling IP forwarding..."
docker exec "$CONTAINER_NAME" bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

echo "Configuring iptables NAT rules..."
# Clear existing NAT rules
docker exec "$CONTAINER_NAME" bash -c "iptables -t nat -F" 2>/dev/null || true

# Enable MASQUERADE for VPN traffic
docker exec "$CONTAINER_NAME" bash -c "iptables -t nat -A POSTROUTING -s 172.27.232.0/24 -j MASQUERADE"

# Allow forwarding
docker exec "$CONTAINER_NAME" bash -c "iptables -P FORWARD ACCEPT"
docker exec "$CONTAINER_NAME" bash -c "iptables -A FORWARD -i eth0 -j ACCEPT"
docker exec "$CONTAINER_NAME" bash -c "iptables -A FORWARD -o eth0 -j ACCEPT"

# Allow forwarding between all network interfaces
docker exec "$CONTAINER_NAME" bash -c "iptables -A FORWARD -i eth1 -j ACCEPT"
docker exec "$CONTAINER_NAME" bash -c "iptables -A FORWARD -i eth2 -j ACCEPT"
docker exec "$CONTAINER_NAME" bash -c "iptables -A FORWARD -i eth3 -j ACCEPT"

cat <<EOF

✓ Workstation configured as VPN gateway successfully!

Workstation IP addresses:
  Internal Network (10.10.20.0/24): 10.10.20.100
  DMZ Network (10.10.10.0/24):      10.10.10.100
  Security Network (10.10.30.0/24): 10.10.30.100
  Management Network (10.10.40.0/24): 10.10.40.100

VPN users will route through this workstation to access all services.

Verify NAT rules:
  docker exec workstation iptables -t nat -L -n -v

Verify IP forwarding:
  docker exec workstation cat /proc/sys/net/ipv4/ip_forward

EOF
