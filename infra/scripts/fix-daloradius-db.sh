#!/bin/bash
set -euo pipefail

# Fix Daloradius Database Connection
# This script updates the Daloradius PHP configuration file with correct database credentials
# Run this after starting docker-compose to ensure Daloradius can connect to MariaDB

CONTAINER_NAME="${CONTAINER_NAME:-daloradius}"
CONFIG_FILE="/var/www/daloradius/library/daloradius.conf.php"

echo "Fixing Daloradius database connection..."

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Error: Container '$CONTAINER_NAME' is not running."
  echo "Start it first with: cd infra && docker compose up -d daloradius"
  exit 1
fi

# Wait for container to be ready
echo "Waiting for Daloradius container to be ready..."
sleep 3

# Update database configuration using sed
echo "Updating database configuration..."

# Fix CONFIG_DB_HOST (empty to 'mariadb')
docker exec "$CONTAINER_NAME" sed -i "s/\$configValues\['CONFIG_DB_HOST'\] = '';/\$configValues['CONFIG_DB_HOST'] = 'mariadb';/" "$CONFIG_FILE"

# Fix CONFIG_DB_PASS ('radpass' to 'radiuspassword123')
docker exec "$CONTAINER_NAME" sed -i "s/\$configValues\['CONFIG_DB_PASS'\] = 'radpass';/\$configValues['CONFIG_DB_PASS'] = 'radiuspassword123';/" "$CONFIG_FILE"

# Verify the changes
echo ""
echo "Verifying configuration..."
docker exec "$CONTAINER_NAME" grep "CONFIG_DB_HOST\|CONFIG_DB_PASS" "$CONFIG_FILE" | head -2

echo ""
echo "✓ Daloradius database connection fixed!"
echo ""
echo "You can now access Daloradius at: https://radius.cyberlab.local"
echo "Default credentials: administrator / radius"
