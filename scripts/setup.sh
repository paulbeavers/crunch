#!/usr/bin/env bash
# One-time setup: create .env with a random dashboard password and a local cert.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -f .env ]; then
  PASS=$(openssl rand -base64 12)
  HASH=$(openssl passwd -apr1 "$PASS")
  cat > .env <<ENV
DOMAIN=localhost
ACME_EMAIL=you@example.com
DASHBOARD_AUTH='admin:${HASH}'
ENV
  echo "Created .env — dashboard login: admin / $PASS"
fi
[ -f certs/local.crt ] || ./scripts/gen-local-cert.sh
