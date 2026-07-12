# notes

## pulling this config to a new system

1. Install NixOS and make sure flakes are enabled:
   ```bash
   nix-shell -p git
   ```

2. Clone the repo:
   ```bash
   git clone https://tangled.org/did:plc:n3llrvji3acb32lmu424ujqy nixos-config
   cd nixos-config
   ```

3. If the target hardware differs from `chi`, regenerate the hardware config:
   ```bash
   sudo nixos-generate-config --root /mnt --show-hardware-config > hardware-configuration.nix
   ```
   On an already-running NixOS system, you can also copy the generated file from `/etc/nixos/hardware-configuration.nix`.

4. Optional: link it into `/etc/nixos`:
   ```bash
   sudo ln -s $(pwd) /etc/nixos
   ```

5. Apply the configuration:
   ```bash
   sudo nixos-rebuild switch --flake .#chi
   ```

## opencode-kimi-full

URL: https://github.com/lemon07r/opencode-kimi-full

An opencode plugin that makes the Kimi Code path work like the official `kimi-cli`.
Instead of a generic OpenAI-compatible provider, it uses Kimi's OAuth device flow and Kimi-specific request behavior.

### what it does

- Authenticates via official Kimi OAuth against `https://auth.kimi.com`
- Talks to `https://api.kimi.com/coding/v1` using `@ai-sdk/openai-compatible`
- Sends the same `User-Agent` / `X-Msh-*` fingerprint headers as `kimi-cli`
- Reuses `~/.kimi/device_id` for `X-Msh-Device-Id`
- Adds `prompt_cache_key`, `thinking`, and `reasoning_effort` for `kimi-for-coding` requests
- Discovers the authoritative model slug, display name, context length, and media-input capabilities from `/coding/v1/models`
- Stores tokens in opencode's auth store and mirrors `kimi-cli`'s refresh / retry behavior
- Provides a `/kimi:usage` TUI command to check subscription usage

### quick start (manual)

1. Install the plugin: `opencode plugin opencode-kimi-full --global`
2. Log in: `opencode auth login -p kimi-for-coding-oauth`
3. Add the provider block from the repo's README to `~/.config/opencode/opencode.json`
4. Select `kimi-for-coding-oauth/kimi-for-coding` in opencode

### nixos integration in this config

This NixOS config handles steps 1 and 3 automatically:

- `configuration.nix` installs `pkgs.opencode` as a system package.
- `home.nix` writes `~/.config/opencode/opencode.json` with the `opencode-kimi-full`
  plugin entry and the full `kimi-for-coding-oauth` provider block.
- A Home Manager activation script runs `opencode plugin opencode-kimi-full --global`
  on each activation, so the plugin is installed without manual intervention.
  The script is best-effort (`|| true`) so network issues during rebuild do not
  break the system build.

After running `sudo nixos-rebuild switch --flake .#chi`, the only remaining step is:

```bash
opencode auth login -p kimi-for-coding-oauth
```

Then select `kimi-for-coding-oauth/kimi-for-coding` in opencode.

### pre-configured provider block

The `~/.config/opencode/opencode.json` written by Home Manager contains:

- `plugin`: `["opencode-kimi-full"]`
- `provider.kimi-for-coding-oauth`:
  - `name`: "Kimi For Coding (OAuth)"
  - `npm`: "@ai-sdk/openai-compatible"
  - `options.baseURL`: "https://api.kimi.com/coding/v1"
  - `models.kimi-for-coding`:
    - `attachment`: true
    - `reasoning`: true
    - `modalities.input`: ["text", "image"]
    - `modalities.output`: ["text"]
    - variants: `off`, `auto`, `low`, `medium`, `high`

### requirements

- `opencode` >= 1.4.6
- Active **Kimi For Coding** subscription

### license

MIT

---

## Development environment

The user environment is managed by Home Manager in `home.nix`.

### Editor: Helix

- Package: `pkgs.helix`
- Default editor (`EDITOR=hx`)
- Theme: `catppuccin_mocha`
- Line numbers: relative

### Git

Git is fully configured through `programs.git`:

- User: `molly.computer <molly@molly.computer>`
- Default branch: `main`
- `push.autoSetupRemote = true`
- `pull.rebase = false`
- Core editor: Helix (`hx`)

### IDE: VSCodium

VSCodium is installed and managed through `programs.vscodium`. The default profile uses the **Catppuccin Mocha** theme and comes with the following extensions:

**Language / dev support**
- rust-analyzer
- nix-ide
- Even Better TOML
- YAML
- Markdown All in One
- ESLint
- Prettier

**Quality of life**
- Error Lens
- Todo Tree
- Better Comments
- Git Graph

**Theme**
- Catppuccin for VSCode

**AI**
- Kimi Code (`moonshot-ai.kimi-code`)

### Custom Open VSX extensions

Some extensions are not packaged in nixpkgs, so they are built from VSIX files downloaded from Open VSX:

- `moonshot-ai.kimi-code` 0.5.10
- `mhutchie.git-graph` 1.30.0

The `@` character in the upstream filenames is avoided by renaming the downloads in the `fetchurl` calls.

### Backup behavior

`flake.nix` sets `home-manager.backupFileExtension = "hm-backup"`, so any existing dotfiles that Home Manager wants to overwrite are backed up instead of causing the activation to fail.

---

## chi / framework 12 — notes to expand later

This section is a placeholder for things to document as the setup settles.

### hardware

- Framework 12 laptop specs (CPU, RAM, storage, display, expansion cards)
- What works out of the box under NixOS
- Any manual tweaks needed for sleep, suspend, power profiles, etc.

### performance with apps and gaming

- General desktop smoothness under KDE Plasma 6
- Specific games and how they run
  - Team Fortress 2: currently needs a config to run well
- Emulators / Proton / native Linux games worth noting

### current difficulties (assumed temporary)

- TF2 performance without a config
- Any other apps or games that need workarounds at time of writing
- Things likely to improve with driver/kernel/proton updates

### misc

- Anything else worth remembering about this machine's NixOS setup
