# The fleet-status Gatekeeper's ingest route sits behind Access (the router is the Access-protected
# origin), so a collector on the fleet needs a service token to reach it. The token and the app
# policy that admits it are managed here together: were the policy created by hand, the next
# `tofu apply` would see it as drift on the `os` application and drop it.
resource "cloudflare_zero_trust_access_service_token" "fleet_collector" {
  account_id = var.account_id
  name       = "cloudflare-os fleet collector"
}

# Read into the sops secret the collector uses:
#   ./tofu.sh output -raw fleet_collector_client_id
#   ./tofu.sh output -raw fleet_collector_client_secret
output "fleet_collector_client_id" {
  value = cloudflare_zero_trust_access_service_token.fleet_collector.client_id
}

output "fleet_collector_client_secret" {
  value     = cloudflare_zero_trust_access_service_token.fleet_collector.client_secret
  sensitive = true
}
