#!/bin/bash
# =============================================================================
# Configure OpenVPN AS for RADIUS Authentication
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Configuration
RADIUS_IP="10.10.20.45"
RADIUS_SECRET="testing123"

log_info "Configuring OpenVPN AS for RADIUS..."

# Execute commands inside OpenVPN container
docker exec openvpn /usr/local/openvpn_as/scripts/sacli --key "auth.module.type" --value "radius" ConfigPut
docker exec openvpn /usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.acct_port" --value "1813" ConfigPut
docker exec openvpn /usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.auth_port" --value "1812" ConfigPut
docker exec openvpn /usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.ip" --value "$RADIUS_IP" ConfigPut
docker exec openvpn /usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.name" --value "FreeRADIUS" ConfigPut
docker exec openvpn /usr/local/openvpn_as/scripts/sacli --key "auth.radius.0.shared_secret" --value "$RADIUS_SECRET" ConfigPut

log_info "Applying changes and restarting OpenVPN service..."
docker exec openvpn /usr/local/openvpn_as/scripts/sacli start

log_success "OpenVPN AS configured for RADIUS authentication"
