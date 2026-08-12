# molly's nixos config

NixOS configuration for my Framework 12 laptop aka chi. Everything here is subject to change, and is for my own personal use.

The Framework hardware module, accelerometer-driven Niri rotation, on-screen keyboard, and optional touchscreen edge gestures make the convertible hardware usable outside a full desktop environment.

It's widely vibe coded togther, but seems to be stable. I'm not doing anything that difficult here, and goes to show that anyone can waste electricity.

## structure

```
hosts/chi/          — host-specific config (chi, a Framework 12 laptop)
modules/common.nix  — shared settings (locale, firewall, fonts, nix settings)
home/               — Home Manager modules, one file per topic
                      (shell, apps, emacs, niri, waybar, foot, khal, stylix, opencode)
wallpapers/         — wallpapers (wp2002041.jpg also generates the stylix theme)
```

## notes

See [`notes.md`](notes.md) for setup details, the opencode + kimi integration, and other misc notes about this machine.

## updating inputs

```bash
nix flake update
sudo nixos-rebuild switch --flake .#chi
```
