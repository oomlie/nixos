# Secrets (agenix)

This directory holds [agenix](https://github.com/ryantm/agenix)-encrypted secrets.

## Workflow

1. Generate an age keypair if you don't have one:
   ```bash
   mkdir -p ~/.config/agenix
   age-keygen -o ~/.config/agenix/key.txt
   ```

2. Add your public key to `secrets.nix`:
   ```nix
   let
     yourKey = "age1...";
   in
   {
     "my-secret.txt".publicKeys = [ yourKey ];
   }
   ```

3. Edit/create the secret:
   ```bash
   agenix -e my-secret.txt
   ```

4. Reference the decrypted secret in your NixOS config:
   ```nix
   age.secrets.my-secret = {
     file = ./my-secret.txt;
     owner = "mollyw";
   };
   ```

5. Access at runtime via `/run/secrets/my-secret`

No secrets are configured yet — this is scaffolding for future use.
