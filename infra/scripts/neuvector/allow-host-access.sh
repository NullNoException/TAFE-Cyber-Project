#!/usr/bin/env bash
# Allow host access to selected containers via NeuVector API (template)
# Usage: source infra/.env && infra/scripts/neuvector/allow-host-access.sh allow|deny nginx|wireguard [CIDR]

set -euo pipefail
command -v curl >/dev/null 2>&1 || { echo "curl is required. Install it first." >&2; exit 1; }
if command -v jq >/dev/null 2>&1; then
  PARSE_WITH_JQ=1
else
  PARSE_WITH_JQ=0
fi

# Load environment defaults
ENV_FILE="$(dirname "$0")/../.env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

NEUVECTORSERVER=${NEUVECTOR_HOST:-localhost}
NEU_PORT=${NEUVECTOR_PORT:-8443}
USER=${NEUVECTOR_ADMIN_USER:-admin}
PASS=${NEUVECTOR_ADMIN_PASSWORD:-admin}
NEUVECTOR_API_BASE=${NEUVECTOR_API_BASE:-/api/v1}

ACTION=${1:-help}
TARGET=${2:-nginx}
CIDR_ARG=${3:-${HOST_ACCESS_CIDR:-127.0.0.1/32}}

if ! docker ps --filter "name=neuvector.allinone" --format "{{.Names}}" | grep -q "neuvector.allinone"; then
  echo "NeuVector container not running or not named 'neuvector.allinone'"
  echo "Run: docker ps | grep neuvector"
  exit 1
fi

if [[ "$ACTION" != "allow" && "$ACTION" != "deny" ]]; then
  cat <<EOF
Usage: $0 allow|deny nginx|wireguard [CIDR]

Example:
  source infra/.env
  $0 allow nginx 192.168.1.100/32 # allow a host IP to reach nginx
  $0 deny nginx 192.168.1.100/32  # deny

When run, the script will authenticate with NeuVector and create (or revoke)
an example network policy that permits or denies traffic from the source CIDR
to the selected target container.
EOF
  exit 1
fi

# Authenticate
TOKEN=""
for ep in "/auth/login" "/auth" "/login"; do
  url="https://$NEUVECTORSERVER:$NEU_PORT${NEUVECTOR_API_BASE}${ep}"
  echo "Attempting login at $url"
  LOGIN_RESP=$(curl -skS -X POST "$url" -H 'Content-Type: application/json' -d "{\"user\": \"$USER\", \"password\": \"$PASS\"}") || true
  if [[ -n "$LOGIN_RESP" ]]; then
    if [[ $PARSE_WITH_JQ -eq 1 ]]; then
      TOKEN=$(echo "$LOGIN_RESP" | jq -r '.token // .data.token // .access_token // .data.access_token' 2>/dev/null || true)
    else
      TOKEN=$(echo "$LOGIN_RESP" | grep -o '"token"\s*:\s*"[^"]*"' | head -n1 | sed -E 's/.*:\s*"([^"]+)"/\1/' || true)
    fi
  fi
  if [[ -n "$TOKEN" && "$TOKEN" != "null" ]]; then
    break
  fi
done

if [[ -z "$TOKEN" ]]; then
  echo "Could not authenticate with NeuVector — open UI at https://$NEUVECTORSERVER:$NEU_PORT and configure manually."
  exit 1
fi

echo "Authenticated with NeuVector..."

case "$TARGET" in
  nginx)
    DEST_MATCH="nginx"
    DEST_TYPE="container"
    PROTOCOL="TCP"
    PORTS="80,443"
    ;;
  wireguard)
    DEST_MATCH="wireguard"
    DEST_TYPE="container"
    PROTOCOL="UDP"
    PORTS="51820"
    ;;
  *)
    echo "Unknown target: $TARGET" >&2
    exit 1
    ;;
esac

if [[ "$ACTION" == "allow" ]]; then
  ACTION_TYPE="ALLOW"
else
  ACTION_TYPE="DENY"
fi

# Build policy payload -- NeuVector API versions differ so this is a template.
read -r -d '' POLICY_JSON <<JSON || true
{
  "policy_name": "host-${ACTION}-${TARGET}-${CIDR_ARG}",
  "action": "$ACTION_TYPE",
  "source": {"type":"external","match":"$CIDR_ARG"},
  "destination": {"type":"$DEST_TYPE","match":"$DEST_MATCH"},
  "ports": "$PORTS",
  "protocol": "$PROTOCOL"
}
JSON

echo "Policy payload:"
echo "$POLICY_JSON"

if [[ "$ACTION" == "allow" ]]; then
  url="https://$NEUVECTORSERVER:$NEU_PORT${NEUVECTOR_API_BASE}/policy/"
  RESP=$(curl -skS -X POST "$url" -H "Authorization: Bearer $TOKEN" -H "X-Auth-Token: $TOKEN" -H "Content-Type: application/json" -d "$POLICY_JSON") || true
  echo "Create response: $RESP"
else
  # We will attempt to find a matching policy by name and delete it
  url="https://$NEUVECTORSERVER:$NEU_PORT${NEUVECTOR_API_BASE}/policy"
  POLS=$(curl -skS -H "Authorization: Bearer $TOKEN" "$url" || true)
  if [[ $PARSE_WITH_JQ -eq 1 ]]; then
    ID=$(echo "$POLS" | jq -r ".[] | select(.policy_name==\"host-${ACTION}-${TARGET}-${CIDR_ARG}\") | .id" 2>/dev/null || true)
  else
    ID=$(echo "$POLS" | grep -B2 "host-${ACTION}-${TARGET}-${CIDR_ARG}" | grep -o '"id":"[^"]*"' | sed -E 's/"id":"([^"]*)"/\1/' || true)
  fi
  if [[ -n "$ID" ]]; then
    DELURL="https://$NEUVECTORSERVER:$NEU_PORT${NEUVECTOR_API_BASE}/policy/$ID"
    DR=$(curl -skS -X DELETE "$DELURL" -H "Authorization: Bearer $TOKEN" -H "X-Auth-Token: $TOKEN" || true)
    echo "Deleted: $DR"
  else
    echo "No matching policy found for host-${ACTION}-${TARGET}-${CIDR_ARG}."
  fi
fi

echo "Done. Verify policy in NeuVector UI if you need advanced matching or adjustments."
