# Secrets

Secrets are managed with `sops-nix` and age.

## Keys

- chi key: `~/.config/sops/age/keys.txt`
- halo key: `/var/lib/sops-nix/keys.txt`

Keep both private key files backed up outside this repository. Only the age
recipients in `.sops.yaml` and encrypted files under `secrets/` belong in Git.

## Editing

From chi:

```bash
sops secrets/halo.yaml
```

After changing a secret, deploy halo before restarting anything that consumes
it:

```bash
sudo nixos-rebuild switch --flake .#halo \
  --target-host halo \
  --use-remote-sudo
```

## Current pilot

`secrets/halo.yaml` contains the encrypted PDS environment and halo
materializes it as `/run/secrets/halo/pds-env` with mode `0400`.

The PDS Compose definition under `/home/molly/pds/` now uses
`/run/secrets/halo/pds-env`. The former plaintext `pds.env` was removed after
the container was recreated and its health endpoint verified. Container
definitions are intentionally still outside this repository for now; they are
planned to move here after the runtime cutover.
