# DynU Certbot Home Assistant Add-on

## Features
- DynU DNS-01 automation
- Full FQDN support (no stripping bug)
- DNS propagation verification
- Auto renewal
- HA SSL integration
- Notifications

## Install

1. Go to Add-on Store
2. Click ⋮ → Repositories
3. Add:

https://github.com/YOUR_USERNAME/ha-dynu-certbot

4. Install "DynU Certbot Pro"

## Config Example

email: you@email.com
api_key: YOUR_KEY
domains:
  - sub.example.com
propagation_seconds: 120
enable_dns_check: true
restart_homeassistant: true
staging: false
dry_run: false
debug: false
