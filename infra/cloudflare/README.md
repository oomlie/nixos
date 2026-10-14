# infra/cloudflare

OpenTofu for the Cloudflare account's **Zero Trust Access** configuration (applications and
reusable policies) and, as it is added, account notifications.

```sh
nix develop -c ./infra/cloudflare/tofu.sh plan     # always plan first; expect "No changes"
nix develop -c ./infra/cloudflare/tofu.sh apply
```

`tofu.sh` reads two things from the login keyring and passes them to OpenTofu:

| keyring `service` / `user` | use |
| --- | --- |
| `cloudflare` / `token` | `CLOUDFLARE_API_TOKEN` (needs Access: Apps and Policies, Notifications) |
| `opentofu-state` / `molly` | passphrase for the state encryption (see below) |

## State

`terraform.tfstate` is committed but **encrypted** (OpenTofu native state encryption, AES-GCM with a
PBKDF2 key). If the keyring passphrase is lost the state is unreadable; recover by re-importing,
because every resource here already exists in Cloudflare. Do not commit a plaintext state or plan.

## What is deliberately not managed here

- **DNS.** The account portal creates per-user ATProto and vanity records at runtime, so managing the
  zone here would fight it. DNS stays in the dashboard and Caddy/cloudflared.
- **The tunnel's routes.** `modules/tunnel.nix` owns the ingress rules; the tunnel is configured
  locally, not through the API.
- **The per-app `allow-owner` policies.** They are app-scoped, not reusable, so the provider cannot
  import them as resources; `access_applications.tf` references them by id. Converting them to a
  reusable policy would change live authorization and needs its own reviewed plan.

## Adding or importing a resource

Add an `import { to = ... id = "accounts/<account>/<id>" }` block (policies use `<account>/<id>`),
run `tofu plan -generate-config-out=generated.tf`, move the result into a tidy file, delete the
`import` block after the apply, and require `tofu plan` to report no changes.
