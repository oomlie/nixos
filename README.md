# molly's nixos config

NixOS configurations for two machines, managed from a single flake.

The canonical repository is hosted on Tangled:
<https://tangled.org/molly.computer/nixos>.

- **chi** — Framework 12 laptop (desktop, Niri compositor, Noctalia shell)
- **halo** — Strix Halo server (headless, Tangled knot/spindle, Podman containers)

## structure

```
hosts/chi/          — chi-specific config (Framework 12 laptop, desktop)
hosts/halo/         — halo-specific config (Strix Halo server, headless)
modules/common.nix  — shared settings (locale, firewall, nix settings)
home/               — Home Manager modules for chi (shell, apps, emacs, niri, etc.)
secrets/             — SOPS-encrypted credentials; never store plaintext here
docs/secrets.md      — sops-nix setup and rotation notes
wallpapers/         — wallpapers (wp2002041.jpg also generates the stylix theme)
```

## deploying

```bash
# chi (local)
sudo nixos-rebuild switch --flake .#chi

# halo (from chi; SSH host alias is managed by Home Manager)
sudo nixos-rebuild switch --flake .#halo \
  --target-host halo \
  --use-remote-sudo
```

For a safer preview, replace `switch` with `dry-activate` or `build`.

## checks

```bash
nix fmt
nix flake check
nix eval --raw .#nixosConfigurations.chi.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.halo.config.system.build.toplevel.drvPath
```

## updating inputs

Update inputs deliberately, review the lockfile, and test both hosts before
deploying:

```bash
nix flake update
nix flake check
```

## notes

See [`notes.md`](notes.md) for setup details, the opencode + kimi integration, and other misc notes.

Secrets use `sops-nix` with age. Edit encrypted credentials with
`sops secrets/halo.yaml`; see [`docs/secrets.md`](docs/secrets.md) for the key
locations and deployment workflow. Private age keys must remain outside Git.

Container runtime definitions (Firecrawl, Plane, PDS, etc.) currently live on
halo under `/home/molly/`. PDS already consumes its sops-managed environment;
the remaining container definitions are planned to move into this repository
as declarative modules later.
