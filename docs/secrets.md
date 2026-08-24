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

The PDS Compose definition still lives under `/home/molly/pds/` and currently
uses its existing `pds.env`. The next step is to change that Compose file to
use `/run/secrets/halo/pds-env`, verify the PDS container, and then remove the
plaintext copy. Container definitions are intentionally still outside this
repository for now; they are planned to move here after the runtime cutover.
