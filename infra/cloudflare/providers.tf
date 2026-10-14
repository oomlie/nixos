terraform {
  required_version = ">= 1.8"

  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }

  # The key provider (with the passphrase) comes from TF_ENCRYPTION, set by ./tofu.sh from the login
  # keyring, so the committed state file is ciphertext and no secret is in this repository.
  encryption {
    method "aes_gcm" "main" {
      keys = key_provider.pbkdf2.main
    }
    state {
      method   = method.aes_gcm.main
      enforced = true
    }
    plan {
      method   = method.aes_gcm.main
      enforced = true
    }
  }
}

# Credentials come from CLOUDFLARE_API_TOKEN (see tofu.sh).
provider "cloudflare" {}
