# molly's nixos config

NixOS configuration for my Framework 12 laptop aka chi. Everything here is subject to change, and is for my own personal use.

It's widely vibe coded togther, but seems to be stable. I'm not doing anything that difficult here, and goes to show that anyone can waste electricity. 

## notes

See [`notes.md`](notes.md) for setup details, the opencode + kimi integration, and other misc notes about this machine.

## updating inputs

```bash
nix flake update
sudo nixos-rebuild switch --flake .#chi
```
