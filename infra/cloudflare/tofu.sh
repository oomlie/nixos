#!/usr/bin/env bash
# Run OpenTofu in this directory with credentials from the login keyring.
#   nix develop -c ./infra/cloudflare/tofu.sh plan
set -euo pipefail
cd "$(dirname "$0")"

export CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-$(secret-tool lookup service cloudflare user token)}"

passphrase="$(secret-tool lookup service opentofu-state user molly)"
export TF_ENCRYPTION="$(printf 'key_provider "pbkdf2" "main" {\n  passphrase = "%s"\n}\n' "$passphrase")"
unset passphrase

exec tofu "$@"
