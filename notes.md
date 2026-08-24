# notes

## Framework 12 tablet support

The `nixos-hardware` Framework 12 module loads `pinctrl_tigerlake` in the initrd before `soc_button_array`, enables IIO sensors, installs `framework_tool`, and keeps firmware updates available through `fwupd`. `services.iio-niri` forwards accelerometer orientation to Niri for the internal `eDP-1` panel.

`home/tablet.nix` provides two user services:

- `tablet-keyboard.service` keeps `wvkbd` hidden and ready to toggle with `Mod+Shift+K`. It intentionally does not open automatically when entering tablet mode.
- `tablet-gestures.service` reads the internal ILIT2901 touchscreen, maps two-finger swipes from the left/right edges to column navigation, and maps a two-finger swipe from the bottom edge to Niri's overview. It follows accelerometer events and restarts `lisgd` with the matching orientation after the screen rotates.

The gestures are experimental and can interfere with multi-touch drawing applications. Disable them with:

```bash
systemctl --user disable --now tablet-gestures.service
```

Useful diagnostics after a reboot:

```bash
sudo libinput debug-events | grep SWITCH_TOGGLE
monitor-sensor --accel
framework_tool --sensors
systemctl status iio-sensor-proxy.service
systemctl --user status iio-niri.service tablet-keyboard.service tablet-gestures.service
```

The host enables NixOS's Powertop service, which applies `powertop --auto-tune` once at boot. `power-profiles-daemon` remains enabled for switching CPU energy profiles. If a peripheral develops autosuspend problems, test without the tunings using `sudo systemctl stop powertop.service` before disabling `powerManagement.powertop.enable`.

Sources used for this setup:

- [Niri switch events](https://niri-wm.github.io/niri/Configuration%3A-Switch-Events.html) documents tablet-mode hooks. They are not used to show the keyboard automatically here.
- [Niri touchscreen gestures discussion](https://github.com/niri-wm/niri/discussions/463) covers `lisgd`, rotation handling, Roland, and experimental native gesture work.
- [Framework 12 Sway tips](https://community.frame.work/t/sway-on-the-framework-laptop-12/73173) demonstrates the practical `wvkbd`, rotation, and touch-sized bar-control pattern.
- [Framework 12 tablet requirements](https://community.frame.work/t/what-are-the-linux-system-requirements-for-tablet-mode/71466) and the [tablet-mode recovery tracking thread](https://community.frame.work/t/fw12-problems-returning-from-tablet-mode-tracking-thread/71631) cover kernel module ordering and hardware failure modes.
- [The Tangled repository](https://tangled.org/molly.computer/nixos/tree/master) is the primary remote for this configuration. Tangled's public search currently exposes few comparable Framework 12 configurations.

### software to investigate

- `rnote`: touch-first handwritten notes and sketching.
- `xournalpp`: handwriting and PDF annotation.
- `krita`: mature pressure-sensitive drawing and painting.
- `foliate`: touch-friendly ebook reader.
- `papers`: document and PDF reader with a compact GTK interface.
- `kdeconnect` or `localsend`: phone integration and local file transfer.
- `kooha`: simple Wayland screen recording.
- `powerstat`: compare actual battery use before and after Powertop tuning; `sudo powertop` provides interactive wakeup and device diagnostics.
- `zramSwap`: compressed memory fallback during heavy builds or games; less urgent while the system has ample disk swap.
- Framework EC charge limits: cap charging around 80% for battery longevity after confirming support and preferred travel behavior.
- `unl0kr`: touchscreen initrd unlock if disk encryption is added later.
- `roland`: Niri-focused edge gesture daemon with better edge detection than `lisgd`, but it is lightly maintained and not packaged in nixpkgs.
- `sysboard`: another Niri-compatible on-screen keyboard worth comparing with `wvkbd`.
- `squeekboard`: richer input-method behavior if its standalone compositor integration improves.

## pulling this config to a new system

1. Install NixOS and make sure flakes are enabled:
   ```bash
   nix-shell -p git
   ```

2. Clone the repo:
   ```bash
   git clone https://github.com/oomlie/nixos nixos-config
   cd nixos-config
   ```

3. If the target hardware differs from `chi`, regenerate the hardware config:
   ```bash
   sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/chi/hardware-configuration.nix
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

- Home Manager's `programs.opencode` module installs OpenCode and writes its configuration.
- `home/opencode.nix` pins `opencode-kimi-full` 1.4.0 and defines the full
  `kimi-for-coding-oauth` provider block.
- OpenCode resolves the pinned plugin from its normal package cache; rebuilds do not run an
  imperative plugin-install activation step.

After running `sudo nixos-rebuild switch --flake .#chi`, the only remaining step is:

```bash
opencode auth login -p kimi-for-coding-oauth
```

Then select `kimi-for-coding-oauth/kimi-for-coding` in opencode.

### pre-configured provider block

The `~/.config/opencode/opencode.json` written by Home Manager contains:

- `plugin`: `["opencode-kimi-full@1.4.0"]`
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

The user environment is managed by Home Manager in `home/`.

### Editor: Helix

- Package: `pkgs.helix`
- Default editor (`EDITOR=hx`)
- Theme: generated by Stylix from the wallpaper
- Line numbers: relative

### Git

Git is fully configured through `programs.git`:

- User: `molly.computer <molly@molly.computer>`
- Default branch: `main`
- `push.autoSetupRemote = true`
- `pull.rebase = false`
- Core editor: Helix (`hx`)
- `git hdiff` / `git hshow`: review changes with Hunk
- `git dft`: structural diffs with Difftastic

### Agent review tools

- Hunk 0.18.0 is pinned through its upstream flake and configured as Jujutsu's pager.
- Jujutsu is enabled with the same identity as Git.
- Difftastic is installed from nixpkgs and exposed through `git dft`.
- OpenCode's built-in `general`, `explore`, and `scout` subagents use
  `openai/gpt-5.6-luna-fast`; its lightweight internal tasks use the same model.
- OpenCode includes focused `nix` and read-only `review` agents, reusable commands, and the
  Hunk live-review skill.

### Future agent tooling

- Add `sops-nix` or `agenix` and rotate credentials found in old local backup files.
- Evaluate colocated Jujutsu repositories after learning its change-based workflow.
- Evaluate OpenCode references for shared documentation repositories.
- Package the Kimi plugin and custom tool dependencies fully in Nix if runtime package caching
  becomes unreliable.
- Evaluate a local Ollama utility model for non-subscription background work.

### IDE: VSCodium

VSCodium is installed and managed through `programs.vscodium`. The default profile is themed by Stylix (wallpaper-generated) and comes with the following extensions:

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

## Post-rebuild manual steps

### Firefox profile cleanup

After the first rebuild with the declarative Firefox profile active, consolidate or remove any old orphaned profile directories under `~/.mozilla/firefox/` on `chi` itself.

### nh flake path

Confirm the `programs.nh.flake` path in `hosts/chi/configuration.nix` matches where this repo is cloned on `chi` (default: `/home/mollyw/nixos`).

### Fonts

ComicShannsMono Nerd Font is set as the system-wide default via Stylix and `modules/common.nix`; Firefox uses Noto fonts instead (see `home/apps.nix`). Point sizes may need tweaking on the real laptop.
