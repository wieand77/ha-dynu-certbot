#!/bin/bash

MSG=$1

curl -s -X POST http://supervisor/core/api/services/persistent_notification/create \
  -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"DynU Certbot\",
    \"message\": \"$MSG\"
  }"
