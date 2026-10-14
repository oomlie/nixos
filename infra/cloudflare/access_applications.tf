# Zero Trust Access applications (imported from the dashboard). Attributes left at their
# defaults are omitted; run `tofu plan` to confirm a change is intentional.

resource "cloudflare_zero_trust_access_application" "agentic_inbox" {
  account_id                = var.account_id
  app_launcher_visible      = true
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "inbox.daze.lol"
    },
    {
      l4_protocol = null
      type        = "public"
      uri         = "agentic-inbox.mwund.workers.dev"
    },
  ]
  domain                     = "inbox.daze.lol"
  enable_binding_cookie      = false
  http_only_cookie_attribute = true
  name                       = "agentic-inbox"
  options_preflight_bypass   = false
  policies = [
    {
      id         = "afa06d96-9b17-4940-851c-ae77250bf2ee"
      precedence = 1
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  type                      = "self_hosted"
}

resource "cloudflare_zero_trust_access_application" "cpa_helper" {
  account_id                = var.account_id
  app_launcher_visible      = true
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "cpa-helper.daze.lol"
    },
  ]
  domain                     = "cpa-helper.daze.lol"
  enable_binding_cookie      = false
  http_only_cookie_attribute = true
  name                       = "cpa-helper"
  options_preflight_bypass   = false
  policies = [
    {
      id         = "f81f20d0-5a57-4dc1-9110-71c6f2a907b8"
      precedence = 1
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  type                      = "self_hosted"
}

resource "cloudflare_zero_trust_access_application" "crawl_firecrawl" {
  account_id                = var.account_id
  app_launcher_visible      = true
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "crawl.daze.lol"
    },
  ]
  domain                     = "crawl.daze.lol"
  enable_binding_cookie      = false
  http_only_cookie_attribute = true
  name                       = "crawl-firecrawl"
  options_preflight_bypass   = false
  policies = [
    {
      id         = "91d5d132-da25-465d-b45e-422fe8240dcf"
      precedence = 1
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  type                      = "self_hosted"
}

resource "cloudflare_zero_trust_access_application" "deepseek_harness" {
  account_id                = var.account_id
  app_launcher_visible      = true
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "harness.daze.lol"
    },
  ]
  domain                     = "harness.daze.lol"
  enable_binding_cookie      = false
  http_only_cookie_attribute = true
  name                       = "deepseek-harness"
  options_preflight_bypass   = false
  policies = [
    {
      id         = "b3fbfdc1-883a-4017-8a31-55ce3d8daeaf"
      precedence = 1
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  type                      = "self_hosted"
}

resource "cloudflare_zero_trust_access_application" "halo_deepseek" {
  account_id                = var.account_id
  app_launcher_visible      = true
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "halo.daze.lol"
    },
  ]
  domain                     = "halo.daze.lol"
  enable_binding_cookie      = false
  http_only_cookie_attribute = true
  name                       = "halo-deepseek"
  options_preflight_bypass   = false
  policies = [
    {
      id         = "070ac077-fe10-4747-a4e4-7bb961061231"
      precedence = 1
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  type                      = "self_hosted"
}

resource "cloudflare_zero_trust_access_application" "lurker" {
  account_id                = var.account_id
  app_launcher_visible      = true
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "lurker.daze.lol"
    },
  ]
  domain                     = "lurker.daze.lol"
  enable_binding_cookie      = false
  http_only_cookie_attribute = true
  name                       = "lurker"
  options_preflight_bypass   = false
  policies = [
    {
      id         = "3ca63bfb-0bd5-4953-9ce2-d7c42662f5fd"
      precedence = 1
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  type                      = "self_hosted"
}

resource "cloudflare_zero_trust_access_application" "netdata" {
  account_id                = var.account_id
  app_launcher_visible      = true
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "netdata.daze.lol"
    },
  ]
  domain                     = "netdata.daze.lol"
  enable_binding_cookie      = false
  http_only_cookie_attribute = true
  name                       = "netdata"
  options_preflight_bypass   = false
  policies = [
    {
      id         = "80f1258c-2edf-480a-8da2-b3514fa710d5"
      precedence = 1
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  type                      = "self_hosted"
}

resource "cloudflare_zero_trust_access_application" "niri" {
  account_id                = var.account_id
  app_launcher_visible      = false
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "niri.daze.lol"
    },
  ]
  domain                     = "niri.daze.lol"
  enable_binding_cookie      = true
  http_only_cookie_attribute = true
  name                       = "niri"
  options_preflight_bypass   = false
  policies = [
    {
      id         = "5e12ea80-9eb0-46f0-b3ee-fc696202f5a9"
      precedence = 1
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  type                      = "self_hosted"
}

resource "cloudflare_zero_trust_access_application" "os" {
  account_id                = var.account_id
  app_launcher_visible      = true
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "os.daze.lol"
    },
  ]
  domain                     = "os.daze.lol"
  enable_binding_cookie      = false
  http_only_cookie_attribute = false
  name                       = "os"
  options_preflight_bypass   = false
  policies = [
    {
      id         = cloudflare_zero_trust_access_policy.os_users.id
      precedence = 1
    },
    # Admits the fleet collector's service token (non_identity = no user login). Scoped to the whole
    # app rather than the ingest path; the token is a machine credential held only in sops, and an
    # identity-less request still fails the Workshop's own admin check.
    {
      decision   = "non_identity"
      name       = "Cloudflare OS fleet collector"
      precedence = 2
      include = [{
        service_token = {
          token_id = cloudflare_zero_trust_access_service_token.fleet_collector.id
        }
      }]
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  skip_interstitial         = true
  type                      = "self_hosted"
}

resource "cloudflare_zero_trust_access_application" "searxng" {
  account_id                = var.account_id
  app_launcher_visible      = false
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "search.daze.lol"
    },
  ]
  domain                     = "search.daze.lol"
  enable_binding_cookie      = false
  http_only_cookie_attribute = true
  name                       = "searxng"
  options_preflight_bypass   = false
  policies = [
    {
      id         = "7d34e6bc-a135-4b32-888d-e8f703ae2805"
      precedence = 1
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  type                      = "self_hosted"
}

resource "cloudflare_zero_trust_access_application" "trueforge" {
  account_id                = var.account_id
  app_launcher_visible      = false
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "forge.daze.lol"
    },
  ]
  domain                     = "forge.daze.lol"
  enable_binding_cookie      = true
  http_only_cookie_attribute = true
  name                       = "trueforge"
  options_preflight_bypass   = false
  policies = [
    {
      id         = "213444b8-73ee-4766-8fdd-2b57842e4462"
      precedence = 1
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  type                      = "self_hosted"
}

resource "cloudflare_zero_trust_access_application" "voicebox" {
  account_id                = var.account_id
  app_launcher_visible      = true
  auto_redirect_to_identity = false
  destinations = [
    {
      l4_protocol = null
      type        = "public"
      uri         = "voicebox.daze.lol"
    },
  ]
  domain                     = "voicebox.daze.lol"
  enable_binding_cookie      = false
  http_only_cookie_attribute = true
  name                       = "voicebox"
  options_preflight_bypass   = false
  policies = [
    {
      id         = "cc4e8e10-657b-4d80-a151-beecdfcb6cd6"
      precedence = 1
    },
  ]
  service_auth_401_redirect = null
  session_duration          = "24h"
  type                      = "self_hosted"
}
