# molly's nixos config

NixOS configuration for my Framework 12 laptop aka chi. Everything here is subject to change, and is for my own personal use.

It's widely vibe coded togther, but seems to be stable. I'm not doing anything that difficult here, and goes to show that anyone can waste electricity.

## structure

```
hosts/chi/          — host-specific config (chi, a Framework 12 laptop)
modules/common.nix  — shared settings (locale, firewall, fonts, nix settings)
home/mollyw.nix     — Home Manager config (shell, editors, apps, dotfiles)
secrets/            — agenix secrets scaffolding (empty, for future use)
wallpapers/         — catppuccin-mocha gradient wallpaper
```

## notes

See [`notes.md`](notes.md) for setup details, the opencode + kimi integration, and other misc notes about this machine.

## updating inputs

```bash
nix flake update
sudo nixos-rebuild switch --flake .#chi
```
