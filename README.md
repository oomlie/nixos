# molly's nixos config

NixOS configurations for two machines, managed from a single flake.

- **chi** — Framework 12 laptop (desktop, Niri compositor, Noctalia shell)
- **halo** — Strix Halo server (headless, Tangled knot/spindle, Podman containers)

## structure

```
hosts/chi/          — chi-specific config (Framework 12 laptop, desktop)
hosts/halo/         — halo-specific config (Strix Halo server, headless)
modules/common.nix  — shared settings (locale, firewall, nix settings)
home/               — Home Manager modules for chi (shell, apps, emacs, niri, etc.)
wallpapers/         — wallpapers (wp2002041.jpg also generates the stylix theme)
```

## deploying

```bash
# chi (local)
sudo nixos-rebuild switch --flake .#chi

# halo (remote)
nixos-rebuild switch --flake .#halo \
  --target-host molly@192.168.0.169 \
  --use-remote-sudo
```

## updating inputs

```bash
nix flake update
sudo nixos-rebuild switch --flake .#chi
```

## notes

See [`notes.md`](notes.md) for setup details, the opencode + kimi integration, and other misc notes.

Container runtime definitions (Firecrawl, Plane, etc.) currently live on halo
under `/home/molly/`. These are planned to be moved into this repository as
declarative modules once secrets management (sops-nix) is in place.
