#!/usr/bin/env bash
# Register the ratlogin OIDC auth source in Forgejo (idempotent).
#
# Run once after the first Forgejo boot:
#   sudo bash scripts/forgejo-oidc.sh
#
# Alternative: create the first admin and an equivalent source through the
# Forgejo web UI (Site Administration > Authentication Sources), using
#   Client ID:        forgejo
#   Client Secret:    contents of /run/secrets/oidc/forgejo
#   Discovery URL:    https://auth.daze.lol/.well-known/openid-configuration
set -euo pipefail

name="ratlogin"
db="/var/lib/forgejo/data/gitea.db"

if [ ! -e "$db" ]; then
  echo "Forgejo database not found at $db; has Forgejo finished first boot?" >&2
  exit 1
fi

if sqlite3 "$db" "SELECT 1 FROM login_source WHERE name = '$name' LIMIT 1;" 2>/dev/null | grep -q 1; then
  echo "auth source '$name' already exists" >&2
  exit 0
fi

secret="$(cat /run/secrets/oidc/forgejo)"

sudo -u forgejo forgejo admin auth add-oauth \
  --name "$name" \
  --provider openidConnect \
  --key forgejo \
  --secret "$secret" \
  --auto-discover-url https://auth.daze.lol/.well-known/openid-configuration

echo "registered ratlogin auth source" >&2
