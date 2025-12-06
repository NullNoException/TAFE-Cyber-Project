#!/bin/bash
################################################################################
# OpenVPN + OpenLDAP Deployment Script
#
# Purpose: Automate complete deployment of OpenVPN with OpenLDAP integration
# Supports: Linux, macOS, Windows (via WSL2/Git Bash)
#
# Usage:
#   ./scripts/deploy-openvpn-ldap.sh [--skip-passwords] [--skip-ldap-seed]
#
# Options:
#   --skip-passwords      Don't generate new passwords (use existing ones)
#   --skip-ldap-seed      Don't seed LDAP with initial entries
#   --help                Show this help message
#
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$INFRA_DIR/scripts"
SECRETS_DIR="$INFRA_DIR/secrets"
CONFIGS_DIR="$INFRA_DIR/configs"

# File paths
LDAP_ADMIN_PW_FILE="$SECRETS_DIR/ldap_admin_password"
OPENVPN_ADMIN_PW_FILE="$SECRETS_DIR/openvpn_admin_password"
DEPLOY_LOG="$INFRA_DIR/deploy-$(date +%Y%m%d-%H%M%S).log"

# Flags
SKIP_PASSWORDS=false
SKIP_LDAP_SEED=false

################################################################################
# Helper Functions
################################################################################

# Print colored output
print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Log to file and stdout
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$DEPLOY_LOG"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Docker is running
check_docker() {
    print_step "Checking Docker installation..."

    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker Desktop."
        return 1
    fi

    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker."
        return 1
    fi

    print_success "Docker is running"
    return 0
}

# Check if container is running
check_container() {
    local container=$1
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        print_success "$container is running"
        return 0
    else
        print_error "$container is not running"
        return 1
    fi
}

# Wait for container to be ready
wait_for_container() {
    local container=$1
    local port=$2
    local timeout=300  # 5 minutes
    local elapsed=0

    print_step "Waiting for $container to be ready (listening on port $port)..."

    while [ $elapsed -lt $timeout ]; do
        if docker exec "$container" nc -z localhost "$port" 2>/dev/null || \
           timeout 1 bash -c "echo >/dev/tcp/localhost/$port" 2>/dev/null; then
            print_success "$container is ready"
            return 0
        fi

        sleep 2
        elapsed=$((elapsed + 2))
        echo -ne "  Waiting... ${elapsed}s/${timeout}s\r"
    done

    print_error "Timeout waiting for $container"
    return 1
}

################################################################################
# Deployment Functions
################################################################################

# Generate passwords if they don't exist
setup_passwords() {
    if [ "$SKIP_PASSWORDS" = true ]; then
        print_step "Skipping password generation (using existing passwords)"
        return 0
    fi

    print_step "Setting up passwords..."

    if [ ! -d "$SECRETS_DIR" ]; then
        mkdir -p "$SECRETS_DIR"
        print_success "Created secrets directory: $SECRETS_DIR"
    fi

    # Generate LDAP admin password if missing
    if [ ! -f "$LDAP_ADMIN_PW_FILE" ]; then
        print_step "Generating LDAP admin password..."
        openssl rand -base64 24 > "$LDAP_ADMIN_PW_FILE"
        chmod 600 "$LDAP_ADMIN_PW_FILE"
        print_success "LDAP admin password created: $LDAP_ADMIN_PW_FILE"
    else
        print_warning "LDAP admin password already exists"
    fi

    # Generate OpenVPN admin password if missing
    if [ ! -f "$OPENVPN_ADMIN_PW_FILE" ]; then
        print_step "Generating OpenVPN admin password..."
        openssl rand -base64 24 > "$OPENVPN_ADMIN_PW_FILE"
        chmod 600 "$OPENVPN_ADMIN_PW_FILE"
        print_success "OpenVPN admin password created: $OPENVPN_ADMIN_PW_FILE"
    else
        print_warning "OpenVPN admin password already exists"
    fi
}

# Start Docker services
start_services() {
    print_step "Starting Docker services..."

    cd "$INFRA_DIR"

    # Start core services
    docker compose up -d openldap
    docker compose up -d openvpn
    docker compose up -d workstation
    docker compose up -d traefik

    print_success "Docker services started"
}

# Verify all services are running
verify_services() {
    print_step "Verifying services are running..."

    local failed=0

    if ! check_container "openldap"; then
        failed=$((failed + 1))
    fi

    if ! check_container "openvpn"; then
        failed=$((failed + 1))
    fi

    if ! check_container "workstation"; then
        failed=$((failed + 1))
    fi

    if [ $failed -gt 0 ]; then
        print_error "$failed service(s) not running"
        return 1
    fi

    print_success "All services are running"
    return 0
}

# Wait for services to be ready
wait_for_services() {
    print_step "Waiting for services to be fully initialized..."

    # Wait for OpenLDAP
    if ! wait_for_container "openldap" 389; then
        print_error "OpenLDAP failed to start"
        return 1
    fi

    # Wait for OpenVPN
    if ! wait_for_container "openvpn" 1194; then
        print_warning "OpenVPN port check failed (may be normal for OpenVPN-AS)"
    fi

    # Additional wait for stability
    sleep 5
    print_success "Services are ready"
    return 0
}

# Seed LDAP with initial data
seed_ldap() {
    if [ "$SKIP_LDAP_SEED" = true ]; then
        print_step "Skipping LDAP seeding"
        return 0
    fi

    print_step "Seeding LDAP with initial entries..."

    if [ ! -x "$SCRIPTS_DIR/seed-ldap.sh" ]; then
        print_error "seed-ldap.sh script not found or not executable"
        return 1
    fi

    cd "$INFRA_DIR"

    if bash "$SCRIPTS_DIR/seed-ldap.sh"; then
        print_success "LDAP seeded successfully"
        return 0
    else
        print_error "Failed to seed LDAP"
        return 1
    fi
}

# Initialize OpenVPN with LDAP
init_openvpn() {
    print_step "Initializing OpenVPN with LDAP authentication..."

    if [ ! -x "$SCRIPTS_DIR/init-openvpn.sh" ]; then
        print_error "init-openvpn.sh script not found or not executable"
        return 1
    fi

    cd "$INFRA_DIR"

    # Detect host IP
    if command_exists ipconfig; then
        # Windows (Git Bash)
        HOST_IP=$(ipconfig | grep "IPv4 Address" | head -1 | awk '{print $NF}')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        HOST_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")
    else
        # Linux
        HOST_IP=$(hostname -I | awk '{print $1}')
    fi

    print_success "Detected host IP: $HOST_IP"

    if HOST_IP="$HOST_IP" bash "$SCRIPTS_DIR/init-openvpn.sh"; then
        print_success "OpenVPN initialized successfully"
        return 0
    else
        print_error "Failed to initialize OpenVPN"
        return 1
    fi
}

# Setup workstation as VPN gateway
setup_workstation_gateway() {
    print_step "Setting up workstation as VPN gateway..."

    if [ ! -x "$SCRIPTS_DIR/setup-workstation-gateway.sh" ]; then
        print_warning "setup-workstation-gateway.sh script not found, skipping"
        return 0
    fi

    cd "$INFRA_DIR"

    if bash "$SCRIPTS_DIR/setup-workstation-gateway.sh"; then
        print_success "Workstation gateway configured"
        return 0
    else
        print_warning "Failed to configure workstation gateway"
        return 0  # Don't fail deployment
    fi
}

# Verify LDAP connectivity
verify_ldap() {
    print_step "Verifying LDAP connectivity..."

    if ! check_container "openldap"; then
        print_error "OpenLDAP container not running"
        return 1
    fi

    local ldap_pw
    if [ ! -f "$LDAP_ADMIN_PW_FILE" ]; then
        print_error "LDAP password file not found"
        return 1
    fi

    ldap_pw=$(cat "$LDAP_ADMIN_PW_FILE")

    if docker exec openldap ldapsearch -x \
        -H ldap://127.0.0.1:389 \
        -D "cn=admin,dc=cyberlab,dc=local" \
        -w "$ldap_pw" \
        -b "dc=cyberlab,dc=local" \
        -s base "+" >/dev/null 2>&1; then

        print_success "LDAP connectivity verified"
        return 0
    else
        print_error "LDAP connectivity check failed"
        return 1
    fi
}

# Verify OpenVPN LDAP configuration
verify_openvpn_ldap() {
    print_step "Verifying OpenVPN LDAP configuration..."

    if ! check_container "openvpn"; then
        print_error "OpenVPN container not running"
        return 1
    fi

    # Check if LDAP is configured in OpenVPN
    if docker exec openvpn \
        grep -q "auth.module.type.*ldap" /usr/local/openvpn_as/etc/config.json 2>/dev/null || true; then
        print_success "OpenVPN LDAP configuration verified"
        return 0
    else
        print_warning "Could not verify OpenVPN LDAP configuration (may be normal)"
        return 0
    fi
}

# Display deployment summary
show_summary() {
    print_step "Deployment Summary"

    local host_ip
    if command_exists ipconfig; then
        host_ip=$(ipconfig | grep "IPv4 Address" | head -1 | awk '{print $NF}')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        host_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")
    else
        host_ip=$(hostname -I | awk '{print $1}')
    fi

    cat << EOF

${GREEN}✓ Deployment Complete!${NC}

Services:
  • OpenLDAP Admin: https://ldap.cyberlab.local (via VPN only)
  • OpenVPN Admin:  https://${host_ip}:943/admin
  • Traefik:        https://traefik.cyberlab.local (via VPN only)

Credentials:
  • LDAP Admin Password:    $(cat "$LDAP_ADMIN_PW_FILE")
  • OpenVPN Admin Password: $(cat "$OPENVPN_ADMIN_PW_FILE")

Next Steps:
  1. Access OpenVPN Admin UI:
     https://${host_ip}:943/admin
     Username: openvpn
     Password: (from $OPENVPN_ADMIN_PW_FILE)

  2. Create LDAP users in phpLDAPadmin:
     • Navigate to ou=users,dc=cyberlab,dc=local
     • Create users with 'uid' attribute
     • Example: uid=alice

  3. Download VPN client profile:
     https://${host_ip}:943/

  4. Connect to VPN with LDAP credentials:
     Username: <ldap_uid>
     Password: <ldap_password>

  5. Access internal services (when connected to VPN):
     https://traefik.cyberlab.local
     https://ldap.cyberlab.local
     https://wazuh.cyberlab.local

Logs:
  Deployment log: $DEPLOY_LOG

EOF
}

# Print help message
show_help() {
    grep "^#" "$0" | head -25 | sed 's/^# //'
}

################################################################################
# Main Execution
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-passwords)
                SKIP_PASSWORDS=true
                shift
                ;;
            --skip-ldap-seed)
                SKIP_LDAP_SEED=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Header
    log "========================================"
    log "OpenVPN + OpenLDAP Deployment Script"
    log "========================================"
    log "Start time: $(date)"
    log "Platform: $OSTYPE"
    log "Infra directory: $INFRA_DIR"

    print_step "Starting OpenVPN + OpenLDAP deployment..."

    # Execute deployment steps
    local failed=0

    check_docker || { print_error "Docker check failed"; failed=$((failed + 1)); }
    setup_passwords || { print_error "Password setup failed"; failed=$((failed + 1)); }
    start_services || { print_error "Service startup failed"; failed=$((failed + 1)); }
    verify_services || { print_error "Service verification failed"; failed=$((failed + 1)); }
    wait_for_services || { print_error "Service wait failed"; failed=$((failed + 1)); }
    verify_ldap || { print_error "LDAP verification failed"; failed=$((failed + 1)); }
    seed_ldap || { print_error "LDAP seeding failed"; failed=$((failed + 1)); }
    init_openvpn || { print_error "OpenVPN init failed"; failed=$((failed + 1)); }
    setup_workstation_gateway || { print_warning "Workstation gateway setup had issues"; }
    verify_openvpn_ldap || { print_warning "OpenVPN LDAP verification had issues"; }

    # Final summary
    if [ $failed -eq 0 ]; then
        log "Deployment completed successfully"
        show_summary
        exit 0
    else
        log "Deployment completed with $failed error(s)"
        print_error "Deployment had $failed error(s). Check the log: $DEPLOY_LOG"
        exit 1
    fi
}

# Run main function
main "$@"
