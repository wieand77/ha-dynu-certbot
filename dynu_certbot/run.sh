#!/bin/bash
set -e

CONFIG=/data/options.json

EMAIL=$(jq -r '.email' $CONFIG)
API_KEY=$(jq -r '.api_key' $CONFIG)
PROPAGATION=$(jq -r '.propagation_seconds' $CONFIG)
DNS_CHECK=$(jq -r '.enable_dns_check' $CONFIG)
RESTART_HA=$(jq -r '.restart_homeassistant' $CONFIG)
STAGING=$(jq -r '.staging' $CONFIG)
DRY_RUN=$(jq -r '.dry_run' $CONFIG)
DEBUG=$(jq -r '.debug' $CONFIG)

DOMAINS=$(jq -r '.domains[]' $CONFIG)

export DYNU_API_KEY="$API_KEY"
export PROPAGATION_SECONDS="$PROPAGATION"
export ENABLE_DNS_CHECK="$DNS_CHECK"
export DEBUG="$DEBUG"

DOMAIN_ARGS=""
PRIMARY_DOMAIN=""

for d in $DOMAINS; do
  DOMAIN_ARGS="$DOMAIN_ARGS -d $d"
  [ -z "$PRIMARY_DOMAIN" ] && PRIMARY_DOMAIN="$d"
done

LE_ENV=""
[ "$STAGING" = "true" ] && LE_ENV="--staging"

log() {
  [ "$DEBUG" = "true" ] && echo "[DEBUG] $1"
}

run_certbot() {
  certbot certonly \
    --manual \
    --preferred-challenges dns \
    --manual-auth-hook /dynu-auth.sh \
    --manual-cleanup-hook /dynu-cleanup.sh \
    --non-interactive \
    --agree-tos \
    -m "$EMAIL" \
    $LE_ENV \
    $DOMAIN_ARGS
}

echo "Starting Certbot..."

if ! run_certbot; then
  echo "Certbot failed"
  /notify.sh "DynU Certbot Failed"
  exit 1
fi

OLD_HASH=$(sha256sum /ssl/fullchain.pem 2>/dev/null || echo "none")

mkdir -p /ssl
cp /etc/letsencrypt/live/$PRIMARY_DOMAIN/fullchain.pem /ssl/fullchain.pem
cp /etc/letsencrypt/live/$PRIMARY_DOMAIN/privkey.pem /ssl/privkey.pem

NEW_HASH=$(sha256sum /ssl/fullchain.pem)

if [ "$OLD_HASH" != "$NEW_HASH" ]; then
  echo "Certificate updated"

  if [ "$RESTART_HA" = "true" ]; then
    curl -s -X POST http://supervisor/core/restart
  fi
fi

# Renewal loop
while true; do
  sleep 86400

  echo "Running renewal..."

  if certbot renew \
    --manual \
    --preferred-challenges dns \
    --manual-auth-hook /dynu-auth.sh \
    --manual-cleanup-hook /dynu-cleanup.sh \
    --non-interactive $LE_ENV; then

    cp /etc/letsencrypt/live/$PRIMARY_DOMAIN/fullchain.pem /ssl/fullchain.pem
    cp /etc/letsencrypt/live/$PRIMARY_DOMAIN/privkey.pem /ssl/privkey.pem

    /notify.sh "Certificate renewed successfully"
  else
    /notify.sh "Certificate renewal failed"
  fi

done
