#!/bin/bash
echo "LDAP_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)"
echo "WAZUH_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)"
echo "WAZUH_API_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)"
echo "WAZUH_INDEXER_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)"
echo "NEUVECTOR_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)"
echo "OPENVPN_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)"
echo "POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)"
