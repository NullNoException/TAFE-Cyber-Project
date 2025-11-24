#!/bin/bash
set -euo pipefail

LDIF_SRC="./configs/ldap/ldif/initial.ldif"
CONTAINER_NAME="openldap"
ADMIN_PW_FILE="./secrets/ldap_admin_password"

if [ ! -f "$LDIF_SRC" ]; then
  echo "LDIF file not found: $LDIF_SRC"
  exit 1
fi

if [ ! -f "$ADMIN_PW_FILE" ]; then
  echo "LDAP admin password not found: $ADMIN_PW_FILE"
  exit 1
fi

ADMIN_PW=$(cat "$ADMIN_PW_FILE")

echo "Waiting for OpenLDAP to accept connections (rootDSE check)..."
until docker exec "$CONTAINER_NAME" ldapsearch -x -H ldap://127.0.0.1:389 -s base -b "" "+" >/dev/null 2>&1; do
  sleep 2
done

echo "Generating password hash inside container..."
PASSHASH=$(docker exec "$CONTAINER_NAME" slappasswd -s 'Password123')

echo "Preparing LDIF with hashed passwords..."
TMP_LDIF="/tmp/initial.ldif.$(date +%s)"
sed "s|<PASSHASH>|$PASSHASH|g" "$LDIF_SRC" > /tmp/initial.ldif

echo "Copying LDIF to container and applying..."
docker cp "/tmp/initial.ldif" "$CONTAINER_NAME:$TMP_LDIF"
docker exec -i "$CONTAINER_NAME" ldapadd -x -D "cn=admin,dc=cyberlab,dc=local" -w "$ADMIN_PW" -f "$TMP_LDIF"

echo "Cleaning up..."
rm -f /tmp/initial.ldif
docker exec -i "$CONTAINER_NAME" rm -f "$TMP_LDIF"

echo "✓ LDAP seeded with initial entries"
