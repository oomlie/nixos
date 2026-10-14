# Secrets

Service secrets are managed with `sops-nix` and age. Clan-generated machine
variables live encrypted under `vars/per-machine/` and are managed by
`clan vars`.

## Keys

- Admin key on chi: `~/.config/sops/age/keys.txt`
- Chi machine key: `/var/lib/clan-sops/key.txt`
- Halo and misty machine identities: `/etc/ssh/ssh_host_ed25519_key`

Keep private age and SSH host keys backed up outside this repository. Only
public recipients under `sops/`, recipient rules in `.sops.yaml`, and encrypted
files under `secrets/` and `vars/` belong in Git.

## Editing

From chi:

```bash
sops secrets/halo.yaml
sops secrets/misty.yaml
```

After changing a secret, deploy the affected machine before restarting anything
that consumes it:

```bash
nix develop -c clan machines update halo
nix develop -c clan machines update misty
```

Use `nix develop -c clan vars check chi halo misty` to validate Clan variables.

## Current pilot

`secrets/halo.yaml` contains the encrypted PDS environment and halo
materializes it as `/run/secrets/halo/pds-env` with mode `0400`.

The PDS Compose definition under `/home/molly/pds/` now uses
`/run/secrets/halo/pds-env`. The former plaintext `pds.env` was removed after
the container was recreated and its health endpoint verified. Container
definitions are intentionally still outside this repository for now; they are
planned to move here after the runtime cutover.
