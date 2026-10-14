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

## Notifications

`workers-issues-alert.sh` creates (or updates) the email notification for Workers Issues
(`workers_observability_real_time_issue`). It is a script, not a resource, because the cloudflare
provider (checked through 5.28) has no such alert type yet. Issues itself is switched on per Worker by
`observability.issues` in `cloudflare-os-daze/deployment.jsonc`. The end-to-end email has not been
observed: trigger a deliberate error on a Worker and confirm one arrives.

## Backups of Cloudflare OS state

`home/cloudflare-backup.nix` installs `cloudflare-state-backup` and a daily user timer on chi. It
writes `~/.local/share/cloudflare-state/latest/` (KV keys and values for every `daze-os-*` namespace,
plus the blueprint R2 bucket), which `hosts/chi/configuration.nix` adds to chi's borg state. A run
replaces `latest` only after it completes. It reuses the keyring token, so nothing new is stored.

- **Not covered:** the Workshop's Durable Object (SQLite) storage -- users, gadgets and workspaces.
  Cloudflare has no export for it, so that is an accepted risk.
- **Restore** a KV value with `wrangler kv key put --namespace-id <id> <key> --path <file>`
  (filenames are the percent-encoded key). The Context key contains a NUL byte and has to be
  restored through the bulk API.
- **Borg to misty is currently failing** (misty is unreachable), so until it is back this is a local
  copy only.
