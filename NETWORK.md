# Clan Network Runbook

## Topology

| Machine | Mycelium IPv6 | Management |
| --- | --- | --- |
| `chi` | `5ec:6edc:7495:220e:6f58:1bae:13be:cbf5` | Local activation |
| `halo` | `517:1053:3359:7f4a:8994:c16:4241:e900` | Iroh, then Mycelium |
| `misty` | `45a:adb:d00f:1128:b131:a28:551b:c1da` | Iroh, then Mycelium |

Mycelium carries normal host-to-host traffic without a controller. Iroh is an
independent SSH transport used by Clan when the machines are behind NAT.

## Operations

```bash
nix develop -c clan network list
nix develop -c clan network ping halo
nix develop -c clan network ping misty
nix develop -c clan ssh halo
nix develop -c clan ssh misty

nix develop -c clan machines update halo
nix develop -c clan machines update misty
sudo nixos-rebuild switch --flake .#chi
```

chi uses misty as its remote Nix builder and binary cache over Mycelium.
Generated addresses and encrypted keys live under `vars/per-machine/`; Nix
configuration reads the addresses directly from those generated values.

## Adding A Machine

1. Add the machine to `inventory.nix` and assign the Mycelium peer role.
2. Register a SOPS machine recipient under `sops/machines/<name>/key.json`.
3. Run `nix develop -c clan vars generate <name>`.
4. Deploy once through an existing bootstrap route.
5. Verify with `clan network ping <name> --network mycelium`.

Use an Iroh server role only for machines that need remote administration.
Iroh forwards SSH and relies on SSH key authentication; passwords stay disabled.

## Recovery

- halo LAN: `molly@192.168.0.169`
- misty LAN: `molly@192.168.1.174`
- Clan emergency override: `clan ssh <machine> --target-host user@address`
- Both servers retain normal OpenSSH and bootable previous NixOS generations.

Never store private age keys, Iroh secrets, provider tokens, or temporary
bootstrap credentials in this file.
