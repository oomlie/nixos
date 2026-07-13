# Plan: application TODOs from sekoia's config + zram swapping

## Context

sekoia.dev's nix-config carries `TODO:` markers in its per-application modules. The ones
worth implementing here (adapted to chi, not ported verbatim) are the Discord client mods
and the mpv script stack, plus the memory/"swapping" setup from its `configuration.nix`
(zram swap + kernel vm tuning + earlyoom), which chi currently lacks entirely — chi has
only the disk swap partition from `hardware-configuration.nix` and default swappiness.

Everything lands in the existing structure: per-program files under
`home/mollyw/programs/`, host/memory config in `hosts/chi/configuration.nix`.

## Part 1 — Discord: OpenASAR + moonlight + privacy URL cleanup

Sekoia's TODO: "port moonlight mod, openasar, privacy URL replacers".

Today discord is a bare entry in `environment.systemPackages`. Move it to
`home/mollyw/programs/discord.nix` using home-manager's `programs.discord` module:

```nix
{pkgs, ...}: {
  programs.discord = {
    enable = true;
    package = pkgs.discord.override {
      withOpenASAR = true;   # rewritten app.asar: 2-4x faster startup, less telemetry
      withMoonlight = true;  # moonlight client mod (extension ecosystem)
    };
    settings = {
      SKIP_HOST_UPDATE = true;  # nix owns the binary; stop self-update nagging
    };
  };
}
```

- Remove `discord` from `environment.systemPackages` in `hosts/chi/configuration.nix`.
- Add `./programs/discord.nix` to the imports list in `home/mollyw/default.nix`.
- Constraint verified in nixpkgs: `withMoonlight` / `withVencord` / `withEquicord` are
  **mutually exclusive** (assertion in the package). Moonlight chosen to follow the TODO;
  swap one flag to change ecosystems later.
- **Privacy URL replacers**: this is a moonlight *extension*, not a nix option. After the
  first launch, enable the URL-cleaning extension from moonlight's in-app extension
  manager (state lives in `~/.config/moonlight-mod/`). If it proves worth pinning, a
  follow-up can seed that config declaratively via `xdg.configFile`.

## Part 2 — mpv: modernz UI + sponsorblock + videoclip (optional)

Sekoia's TODO: "port old mpv config (modernz UI, sponsorblock, videoclip, image viewer
mode)". chi has no media player configured at all; new file
`home/mollyw/programs/mpv.nix`:

```nix
{pkgs, ...}: {
  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      modernz       # modern OSC replacement UI
      sponsorblock  # auto-skip sponsored segments in YouTube content
      videoclip     # clip/export segments  (verify attr name at impl time)
    ];
  };
}
```

- modernz requires disabling the built-in OSC (`programs.mpv.config.osc = "no";` plus its
  documented `script-opts`) — copy the minimal recommended block from the modernz README
  at implementation time.
- "image viewer mode" from the TODO is skipped — it's sekoia's personal workflow; add
  later if wanted.

## Part 3 — swapping: zram + vm tuning + earlyoom

Adapted from sekoia's `configuration.nix`, into `hosts/chi/configuration.nix`:

```nix
zramSwap = {
  enable = true;
  algorithm = "zstd";
  memoryPercent = 90;
};

boot.kernel.sysctl = {
  "vm.swappiness" = 180;              # zram swap is cheap — prefer it aggressively
  "vm.watermark_boost_factor" = 0;
  "vm.watermark_scale_factor" = 125;
  "vm.page-cluster" = 0;              # zram is RAM — readahead is pointless
};

services.earlyoom = {
  enable = true;                       # kill the worst offender before total stall
  freeMemThreshold = 5;
  freeSwapThreshold = 5;
};
```

- The existing disk swap partition in `hardware-configuration.nix` **stays**: NixOS gives
  zram devices higher priority automatically, so the disk partition becomes overflow (and
  remains available for future hibernation support). No hardware file changes.
- The sysctl values are the upstream zram-generator recommendations sekoia uses; they only
  make sense together with zram, so they land in the same commit.

## Verification

- CI (`nix flake check` + full `chi` toplevel eval) must stay green — catches any bad
  option/attr names (`withMoonlight` on nixos-26.05, `mpvScripts.videoclip`,
  `programs.discord` availability in home-manager release-26.05; if any is missing on the
  26.05 branches, fall back: discord override flags direct in `home.packages`, drop the
  missing mpv script).
- On the laptop after `nixos-rebuild switch`:
  - `swapon --show` → `/dev/zram0` listed with higher priority than the disk partition.
  - `sysctl vm.swappiness` → 180.
  - `systemctl status earlyoom` → active.
  - Launch Discord once; confirm moonlight's mod UI appears and startup feels snappier
    (OpenASAR); enable the URL-cleaning extension in its extension manager.
  - `mpv <some video>` shows the modernz OSC.

## Out of scope

Sekoia's other app TODOs ("port old X config if desired" for beets, jujutsu, gh, lazygit,
chromium, obs) reference their private old dotfiles and apps chi doesn't use — nothing to
implement. Firefox is already fully declarative here.
