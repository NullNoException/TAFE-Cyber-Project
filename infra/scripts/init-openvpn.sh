#!/bin/bash
set -euo pipefail

# Initialise OpenVPN Access Server for this lab using sacli:
# - Reset admin password (user 'openvpn') from ./secrets/openvpn_admin_password
# - Set host.name and sa.server.ip to HOST_IP
# - Generate a client profile for 'openvpn' to ./openvpn-admin.ovpn

CONTAINER_NAME="${CONTAINER_NAME:-openvpn}"
ADMIN_USER="${ADMIN_USER:-openvpn}"
ADMIN_PW_FILE="${ADMIN_PW_FILE:-./secrets/openvpn_admin_password}"
PROFILE_OUT="${PROFILE_OUT:-./openvpn-admin.ovpn}"

# Read admin password from secret
if [ ! -f "$ADMIN_PW_FILE" ]; then
  echo "OpenVPN admin password not found: $ADMIN_PW_FILE"
  echo "Create it, e.g.:"
  echo "  ./scripts/generate-passwords.sh | grep OPENVPN_ADMIN_PASSWORD | cut -d= -f2 > $ADMIN_PW_FILE"
  exit 1
fi
ADMIN_PW="$(cat "$ADMIN_PW_FILE")"

# Detect host IP on macOS (prefer en0, then en1), fallback to 127.0.0.1
HOST_IP="${HOST_IP:-$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo '127.0.0.1')}"

echo "Using host IP: $HOST_IP"
echo "Checking OpenVPN-AS container: $CONTAINER_NAME"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container '$CONTAINER_NAME' is not running. Start it first, e.g.:"
  echo "  cd infra && docker compose up -d openvpn"
  exit 1
fi

OAS_SCRIPTS_DIR="/usr/local/openvpn_as/scripts"

echo "Waiting for OpenVPN-AS services inside container..."
until docker exec "$CONTAINER_NAME" test -x "$OAS_SCRIPTS_DIR/sacli" >/dev/null 2>&1; do
  sleep 3
done

echo "Resetting admin password for user '$ADMIN_USER' via sacli..."
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" \
  --user "$ADMIN_USER" \
  --new_pass "$ADMIN_PW" \
  SetLocalPassword

echo "Configuring host.name and sa.server.ip via sacli..."
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" \
  --key "host.name" --value "$HOST_IP" ConfigPut
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" \
  --key "sa.server.ip" --value "$HOST_IP" ConfigPut

echo "Applying configuration and restarting OpenVPN-AS..."
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" start || true

cat <<EOF

✓ OpenVPN-AS initialised via sacli.

Admin UI: https://$HOST_IP:943/admin
  Username: $ADMIN_USER
  Password: (from $ADMIN_PW_FILE)

You can override HOST_IP, ADMIN_USER, ADMIN_PW_FILE, or PROFILE_OUT, e.g.:
  HOST_IP=192.168.0.84 ADMIN_USER=openvpn ./infra/scripts/init-openvpn.sh
EOF

echo "Configuring OpenVPN-AS to use RADIUS auth against Daloradius..."

# RADIUS settings
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "auth.module.type" --value "radius" ConfigPut
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "auth.radius.0.server.0.host" --value "10.10.20.45" ConfigPut
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "auth.radius.0.server.0.secret" --value "testing123" ConfigPut

# Fix for "Message-Authenticator" missing in FreeRADIUS 2.x reply
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "auth.radius.0.server.0.verify_reply_authenticator" --value "false" ConfigPut

# Configure Ports (TCP 443 fallback for macOS/Docker compatibility)
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "vpn.server.daemon.udp.port" --value "1194" ConfigPut
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "vpn.server.daemon.tcp.port" --value "443" ConfigPut

echo "Applying RADIUS auth configuration and restarting OpenVPN-AS..."
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" start || true

echo
echo "Configuring Daloradius database connection..."

# Wait for Daloradius container to be ready
DALORADIUS_CONTAINER="daloradius"
if docker ps --format '{{.Names}}' | grep -q "^${DALORADIUS_CONTAINER}$"; then
  echo "Waiting for Daloradius to be ready..."
  sleep 5
  
  # Fix Daloradius database configuration
  DALORADIUS_CONFIG="/var/www/daloradius/library/daloradius.conf.php"
  
  echo "Updating Daloradius database configuration..."
  docker exec "$DALORADIUS_CONTAINER" sed -i "s/\$configValues\['CONFIG_DB_HOST'\] = '';/\$configValues['CONFIG_DB_HOST'] = 'mariadb';/" "$DALORADIUS_CONFIG" || true
  docker exec "$DALORADIUS_CONTAINER" sed -i "s/\$configValues\['CONFIG_DB_PASS'\] = 'radpass';/\$configValues['CONFIG_DB_PASS'] = 'radiuspassword123';/" "$DALORADIUS_CONFIG" || true
  
  echo "✓ Daloradius database connection configured"
else
  echo "⚠ Daloradius container not running, skipping database configuration"
  echo "  You can run './infra/scripts/fix-daloradius-db.sh' later if needed"
fi

echo
echo "Configuring VPN routing through workstation..."

# Configure VPN to push routes to internal networks via workstation gateway
# VPN clients will route through 10.10.20.100 (workstation) to access all services

echo "Setting VPN network configuration..."
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "vpn.client.routing.reroute_gw" --value "false" ConfigPut
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "vpn.server.routing.private_network.0" --value "10.10.10.0/24" ConfigPut
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "vpn.server.routing.private_network.1" --value "10.10.20.0/24" ConfigPut
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "vpn.server.routing.private_network.2" --value "10.10.30.0/24" ConfigPut
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "vpn.server.routing.private_network.3" --value "10.10.40.0/24" ConfigPut

# Set workstation as the gateway for VPN clients
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" --key "vpn.server.routing.gateway_access" --value "true" ConfigPut

# Enable IP forwarding in workstation
echo "Enabling IP forwarding in workstation container..."
docker exec workstation bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward" 2>/dev/null || true

# Add iptables rules in workstation for NAT/forwarding
echo "Configuring NAT rules in workstation..."
docker exec workstation bash -c "iptables -t nat -A POSTROUTING -s 172.27.232.0/24 -o eth0 -j MASQUERADE" 2>/dev/null || true
docker exec workstation bash -c "iptables -A FORWARD -i eth0 -j ACCEPT" 2>/dev/null || true
docker exec workstation bash -c "iptables -A FORWARD -o eth0 -j ACCEPT" 2>/dev/null || true

echo "Restarting OpenVPN-AS to apply routing configuration..."
docker exec "$CONTAINER_NAME" "$OAS_SCRIPTS_DIR/sacli" start || true

echo
echo "✓ VPN routing configured successfully!"
echo
echo "Next steps:"
echo "  1) Add hosts entries on your LOCAL machine (not in containers):"
echo "       10.10.10.5       traefik.cyberlab.local"
echo "       10.10.10.5       vpn.cyberlab.local"
echo "       10.10.10.5       radius.cyberlab.local"
echo "       10.10.30.25      wazuh.cyberlab.local"
echo "       10.10.0.10       neuvector.cyberlab.local"
echo "       10.10.10.50      dns.cyberlab.local"
echo
echo "  2) Open the OpenVPN-AS admin UI:"
echo "       https://$HOST_IP:943/admin"
echo "     Login with:"
echo "       Username: $ADMIN_USER"
echo "       Password: contents of $ADMIN_PW_FILE"
echo
echo "  3) Create RADIUS users in Daloradius:"
echo "       URL: https://radius.cyberlab.local"
echo "       Default Admin: administrator / radius"
echo
echo "  4) Download VPN client profile:"
echo "       https://vpn.cyberlab.local/"
echo "       (Login with RADIUS user credentials)"
echo
echo "  5) Once connected via VPN, access services at:"
echo "       https://traefik.cyberlab.local (only accessible through VPN)"
echo "       https://wazuh.cyberlab.local (only accessible through VPN)"
echo "       https://neuvector.cyberlab.local (only accessible through VPN)"