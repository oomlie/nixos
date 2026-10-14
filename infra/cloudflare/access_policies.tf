# Reusable Access policies. The per-app "allow-owner" style policies are app-scoped and are
# referenced by id from access_applications.tf.

resource "cloudflare_zero_trust_access_policy" "daze_users" {
  account_id = var.account_id
  decision   = "allow"
  include = [
    {
      email = {
        email = "mwund@proton.me"
      }
    },
  ]
  name = "Cloudflare OS daze users ba4e64a1"
}

resource "cloudflare_zero_trust_access_policy" "os_users" {
  account_id = var.account_id
  decision   = "allow"
  include = [
    {
      email = {
        email = "mwund@proton.me"
      }
    },
  ]
  name = "Cloudflare OS cloudflareos users 4ab11d03"
}
