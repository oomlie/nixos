#!/usr/bin/env bash
# Ensure the "new or recurring Workers issue" email notification exists.
#
# This is the one resource here that OpenTofu does not manage: the cloudflare provider (checked
# through 5.28) cannot express the `workers_observability_real_time_issue` alert type yet. Replace
# this script with a `cloudflare_notification_policy` once it can.
#
#   nix develop -c ./infra/cloudflare/workers-issues-alert.sh
set -euo pipefail

account="${CLOUDFLARE_ACCOUNT_ID:-ab50bec72354666a941823793fef426a}"
email="${ALERT_EMAIL:-mwund@proton.me}"
name="Workers: new or recurring issue"
token="${CLOUDFLARE_API_TOKEN:-$(secret-tool lookup service cloudflare user token)}"
api="https://api.cloudflare.com/client/v4/accounts/$account/alerting/v3/policies"

body="$(jq -n --arg name "$name" --arg email "$email" '{
  name: $name,
  description: "Email when Workers Issues detects a new or recurring failure.",
  enabled: true,
  alert_type: "workers_observability_real_time_issue",
  mechanisms: { email: [{ id: $email }] }
}')"

call() { curl -fsS -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$@"; }

id="$(call "$api" | jq -r --arg n "$name" '.result[] | select(.name == $n) | .id' | head -n1)"
if [ -n "$id" ]; then
  call -X PUT "$api/$id" --data "$body" | jq -r '"updated " + .result.id'
else
  call -X POST "$api" --data "$body" | jq -r '"created " + .result.id'
fi
