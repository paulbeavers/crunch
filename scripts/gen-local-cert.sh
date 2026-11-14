#!/usr/bin/env bash
# Generate a local TLS cert for *.localhost. Uses mkcert (browser-trusted) if installed,
# otherwise a self-signed cert via openssl (browsers will warn; curl needs -k).
set -euo pipefail
cd "$(dirname "$0")/.."
DOMAIN="${DOMAIN:-localhost}"
NAMES=("$DOMAIN" "*.$DOMAIN" "app1.$DOMAIN" "app2.$DOMAIN" "traefik.$DOMAIN")
mkdir -p certs
if command -v mkcert >/dev/null 2>&1; then
  mkcert -install
  mkcert -cert-file certs/local.crt -key-file certs/local.key "${NAMES[@]}"
else
  SAN=$(printf 'DNS:%s,' "${NAMES[@]}"); SAN=${SAN%,}
  openssl req -x509 -newkey rsa:2048 -nodes -days 825 \
    -keyout certs/local.key -out certs/local.crt \
    -subj "/CN=$DOMAIN" -addext "subjectAltName=$SAN"
  echo "Self-signed cert created. Install mkcert (brew install mkcert) for browser-trusted certs."
fi
chmod 600 certs/local.key
