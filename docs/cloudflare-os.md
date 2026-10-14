# Cloudflare OS + GitHub integration

Design doc. Status: proposed — nothing here is implemented yet.

## Goal

Drive agent-assisted changes to this repository from a Cloudflare OS dashboard,
with GitHub as the canonical host, the PR surface, and the CI.

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Git host | **GitHub, canonical** | Does PRs, CI, and builds in one place |
| CI | GitHub Actions, hosted runners | Free and unlimited on a public repo |
| Caching | Cachix (free for open source) + magic-nix-cache | Real binary cache that the fleet can also substitute from |
| Dashboard | Cloudflare OS, self-deployed from `cloudflare-os-starter` | The hosted `os.cloudflare.app/deploy` flow cannot host custom Gatekeepers |
| Agent authoring | Built-in GitHub Gatekeeper | Zero custom code |
| Deploy bridge | Custom Gatekeeper + runner on chi | The only custom piece that remains |

This flips the earlier assumption that Tangled was canonical. GitHub was already
the only host with working CI, and it becomes the PR and build surface too.
Tangled is kept as a mirror; the research done for a Tangled-native flow is
retained below under [Deferred: Tangled](#deferred-tangled).

## Architecture

```
Cloudflare OS (os.daze.lol)
  ├─ GitHub Gatekeeper   → agent opens PRs on oomlie/nixos
  │     └─ GitHub Actions: nix flake check + 3 host evals, Cachix-backed
  └─ gatekeeper-daze     → job queue → daze-runner on chi          (Phase 3)
                          (clan machines update)
```

## Phase 1 — CI and caching

1. Create a Cachix cache and add `cachix/cachix-action` to `.github/workflows/ci.yml`.
2. Add `DeterminateSystems/magic-nix-cache-action` for per-run speed.
3. Add the cache as a substituter on chi, halo, and misty.
4. Address the dead misty substituter in `modules/common.nix:13`.

Cachix makes CI fast and also gives the fleet a working cache while misty is
unreachable. That last point pays off outside this project and is worth doing
regardless of Cloudflare OS.

**This does not enable closure builds.** GitHub-hosted runners have roughly a
14 GB disk, which is why `ci.yml:18-19` deliberately evaluates rather than
builds. Real closure builds need larger runners (paid) or a self-hosted runner —
and a self-hosted runner must not be used while this repository is public, since
pull requests can execute arbitrary code on it.

## Phase 2 — Cloudflare OS

Deploy `cloudflare-os-starter` to the Cloudflare account on `os.daze.lol`:

1. Clone the starter, `pnpm install`, `pnpm --dir cloudflare-os install`,
   `pnpm exec wrangler login`.
2. Create a self-hosted Cloudflare Access application on `os.daze.lol` and copy
   its audience tag.
3. Fill in `deployment.jsonc`: account ID, the six `daze-os-*` Worker names,
   the Access issuer/audience/admins, and AI Gateway `default` on Workers AI
   (no API token required).
4. `pnpm check && pnpm deploy`.
5. Open `/admin` and set the site name, logo, and accent colour.

## Phase 3 — Deploy bridge

1. Create a dedicated GitHub account with write access to `oomlie/nixos` only.
   This bounds the broad `repo` OAuth scope to a single repository.
2. Connect the repository through the built-in GitHub Gatekeeper so the agent
   can propose pull requests.
3. Write a custom Gatekeeper plus a `daze-runner` systemd service on chi that
   runs `clan machines update`. Give it `status` / `propose` / `deploy`
   capability bindings and human-in-the-loop approval on the write steps.

Anything targeting misty is blocked until misty is reachable again.

## Canonical flip

Three places asserted that Tangled was canonical and now say GitHub:

- `README.md` (the "canonical repository" line)
- `notes.md` (the "primary remote" line)
- the private `agent-wiki` entry for this project

`origin` is now primary; `tangled` and `purplish` remain mirrors. Pushing to the
mirrors stays a deliberate step rather than an automatic one.

## Deferred: Tangled

Not implemented. Recorded so the research is not repeated.

- spindles read `.tangled/workflows/*.yaml` from the repository root and support
  `pull_request` triggers, so Tangled CI is a configuration file away rather
  than unavailable.
- The self-hosted spindle on halo is active, but its `workflowTimeout` defaults
  to `5m`, which is far too short for any Nix build. It also limits concurrent
  jobs to 2 and would compete for RAM with halo's resident llama models.
- Both engines are present (`nixery`, and `microvm` with a NixOS image already
  built). Pull requests are ATProto records read via `tngl.sh` XRPC, and spindle
  handles branch-based pull requests only.
- The blocker to revisit: spindle has never ingested `molly.computer/nixos`, and
  it is unverified whether a third-party spindle can subscribe to the event
  stream of the hosted knot the repository lives on.

## Open items (unrelated to this project)

- Rotate the leaked OpenRouter key.
- Recover misty; `borgbackup-job-misty` is failing, so chi and halo are not
  currently backed up.
- Confirm the `vista` VPS is destroyed: `51.81.22.34` now answers with a
  different host key and hosts a different Raff VM.
