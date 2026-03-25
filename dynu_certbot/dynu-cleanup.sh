#!/bin/bash
set -e

DOMAIN="$CERTBOT_DOMAIN"
BASE_DOMAIN=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')

DOMAIN_ID=$(curl -s -X GET "https://api.dynu.com/v2/dns" \
  -H "API-Key: $DYNU_API_KEY" | jq -r \
  ".domains[] | select(.name==\"$BASE_DOMAIN\") | .id")

RECORDS=$(curl -s -X GET "https://api.dynu.com/v2/dns/$DOMAIN_ID/record" \
  -H "API-Key: $DYNU_API_KEY")

echo "$RECORDS" | jq -c '.dnsRecords[]' | while read rec; do
  ID=$(echo "$rec" | jq -r '.id')
  NODE=$(echo "$rec" | jq -r '.nodeName')

  if echo "$NODE" | grep -q "_acme-challenge"; then
    curl -s -X DELETE "https://api.dynu.com/v2/dns/$DOMAIN_ID/record/$ID" \
      -H "API-Key: $DYNU_API_KEY"
  fi
done
