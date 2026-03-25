#!/bin/bash
set -e

log() {
  if [ "$DEBUG" = "true" ]; then
    echo "[DEBUG] $1"
  fi
}

DOMAIN="$CERTBOT_DOMAIN"
TOKEN="$CERTBOT_VALIDATION"

BASE_DOMAIN=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')
SUBDOMAIN="${DOMAIN%.$BASE_DOMAIN}"

if [ "$SUBDOMAIN" = "$DOMAIN" ]; then
  NODE="_acme-challenge"
else
  NODE="_acme-challenge.$SUBDOMAIN"
fi

log "Domain: $DOMAIN"
log "Base: $BASE_DOMAIN"
log "Node: $NODE"

DOMAIN_ID=$(curl -s -X GET "https://api.dynu.com/v2/dns" \
  -H "API-Key: $DYNU_API_KEY" | jq -r \
  ".domains[] | select(.name==\"$BASE_DOMAIN\") | .id")

curl -s -X POST "https://api.dynu.com/v2/dns/$DOMAIN_ID/record" \
  -H "API-Key: $DYNU_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"nodeName\": \"$NODE\",
    \"recordType\": \"TXT\",
    \"textData\": \"$TOKEN\",
    \"ttl\": 60
  }"

FULL_RECORD="$NODE.$BASE_DOMAIN"

echo "Verifying DNS propagation for $FULL_RECORD"

if [ "$ENABLE_DNS_CHECK" = "true" ]; then
  for i in $(seq 1 30); do
    RESULT=$(dig TXT $FULL_RECORD +short | tr -d '"')
    if echo "$RESULT" | grep -q "$TOKEN"; then
      echo "DNS propagation verified"
      exit 0
    fi
    sleep 5
  done

  echo "DNS check failed, falling back to sleep"
fi

echo "Sleeping for $PROPAGATION_SECONDS seconds"
sleep $PROPAGATION_SECONDS
