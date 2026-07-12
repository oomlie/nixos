# NixOS config cleanup + agenic-journal flake integration

## Context

`oomlie/nixos` is a single-host flake (`chi`, a Framework 12 laptop) with everything flat
at the repo root: `flake.nix`, `configuration.nix`, `home.nix`, `hardware-configuration.nix`.
It works but has accumulated some rough edges (stateVersion mismatch, no GC, no explicit
firewall/power management, a risky network-fetching activation script) and has no room to
grow to a second host.

Separately, the user wants to use their `oomlie/agenic-journal` CLI (a Bash/git-backed
daily journaling tool) as a proper Nix package on `chi` instead of running it out of a manual
clone. Investigation found **agenic-journal has no `flake.nix` at all** — it's pure Bash
(`scripts/journal`, ~700 lines, deps: `git`, `python3`, GNU coreutils/sed/grep) plus two git
hooks. "Integrating the flake" therefore means authoring one there first, then consuming it
as a flake input from `oomlie/nixos`.

This plan does both: (1) restructure + harden the nixos config, (2) package agenic-journal
as a flake output and wire it in as an installed CLI for `mollyw`.

Both repos develop on branch `claude/nixos-config-improvements-9l3kgy` (created fresh from
each repo's `main`, since it doesn't exist yet in either).

## Part A — `oomlie/agenic-journal`: add `flake.nix`

Add a flake at the repo root exposing the CLI as a package:

```nix
{
  description = "agenic-journal: text-based, git-backed daily journaling CLI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "agenic-journal";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          installPhase = ''
            mkdir -p $out/bin $out/share/agenic-journal
            install -Dm755 scripts/journal $out/bin/journal
            cp -r templates .githooks $out/share/agenic-journal/
            wrapProgram $out/bin/journal --prefix PATH : ${pkgs.lib.makeBinPath [
              pkgs.git pkgs.python3 pkgs.gnused pkgs.gnugrep pkgs.coreutils pkgs.findutils
            ]}
          '';
        };
        apps.default = { type = "app"; program = "${self.packages.${system}.default}/bin/journal"; };
        devShells.default = pkgs.mkShell { packages = [ pkgs.git pkgs.python3 ]; };
      });
}
```

Packaging notes:
- Use `stdenv.mkDerivation` + `wrapProgram`, **not** `writeShellApplication` — the latter
  runs a strict `shellcheck` pass at build time and `scripts/journal` has multiple
  SC2155-style warnings (`local x=$(...)`) that would fail the build. Wrapping the script
  as-is avoids touching agenic-journal's source just to satisfy a packaging tool.
- `wrapProgram` pins `git`/`python3`/GNU utils onto `PATH` so the installed binary works
  regardless of what's in the caller's environment (the script relies on GNU `date -d`,
  which is what `pkgs.coreutils`/system default provides on NixOS).
- The script does `git rev-parse --show-toplevel` and operates relative to that — this is
  unchanged; it still expects to be run from inside a journal git repo (the user's private
  entries repo), the package just makes the `journal` command globally available instead of
  requiring `./scripts/journal` from a clone.
- No NixOS/home-manager module is needed — this is a stateless CLI, not a service.

Commit to `claude/nixos-config-improvements-9l3kgy` in `oomlie/agenic-journal`, push.

## Part B — `oomlie/nixos`: restructure

Split the flat repo into hosts/modules so it can support a second machine later, without
overengineering (only one host exists today):

```
/
├── flake.nix
├── flake.lock
├── hosts/
│   └── chi/
│       ├── configuration.nix          # host-specific: hostName, user, desktop, packages
│       └── hardware-configuration.nix # moved as-is, untouched
├── modules/
│   └── common.nix                     # shared: nix settings, locale, gc, firewall
├── home/
│   └── mollyw.nix                     # was home.nix, moved as-is + fixes below
├── README.md
└── notes.md
```

`modules/common.nix` pulls out settings that would apply to any future host: nix
experimental-features, locale/i18n block, `nixpkgs.config.allowUnfree`, GC settings, and
explicit firewall enable. `hosts/chi/configuration.nix` keeps only what's chi-specific:
bootloader, hostName, desktop (Plasma6/SDDM), sound, user account, system packages, power
management.

`flake.nix` updates its `modules` list to `./modules/common.nix ./hosts/chi/configuration.nix`
and imports home-manager from `./home/mollyw.nix`, and adds the `agenic-journal` input:

```nix
inputs.agenic-journal = {
  url = "github:oomlie/agenic-journal";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

plus `home-manager.extraSpecialArgs = { inherit inputs; };` in the home-manager block —
**this is currently missing**, and `home.nix` already declares `inputs` as a required
function argument that home-manager has no way to supply without it. It's needed both to
fix that latent issue and to reference `inputs.agenic-journal` from `home/mollyw.nix`.

## Part C — practical fixes

- **stateVersion mismatch**: `home.stateVersion` is `"25.11"` while `system.stateVersion` is
  `"26.05"`. Align `home.stateVersion` to `"26.05"` (a comment will note stateVersion is a
  compatibility pin, not a version to bump on every upgrade).
- **Garbage collection**: handled by `programs.nh.clean` in Part G — do **not** also set
  `nix.gc.automatic`; the nh module asserts the two are mutually exclusive. Only
  `nix.settings.auto-optimise-store = true;` goes in `modules/common.nix`.
- **Explicit firewall**, in `modules/common.nix`: `networking.firewall.enable = true;` (makes
  the current implicit default explicit and documented).
- **Laptop power management**, in `hosts/chi/configuration.nix` (Framework 12, Intel CPU):
  `services.power-profiles-daemon.enable = true;` (integrates with Plasma6's battery
  widget), `services.thermald.enable = true;` (Intel thermal management), and
  `services.fwupd.enable = true;` (Framework laptops rely on this for BIOS/EC firmware
  updates) — addresses the "sleep/suspend/power profiles" TODO already sitting in `notes.md`.
- **Style**: drop the redundant `pkgs.` prefix in `environment.systemPackages` now that it's
  already inside `with pkgs; [ ... ]`.
- **`notes.md`**: remove the empty "notes to expand later" placeholder bullets (Framework 12
  specs, TF2 workarounds) rather than leaving unfilled TODO scaffolding in the repo; keep the
  useful bootstrap/opencode-plugin documentation as-is.
- **Kimi plugin activation script** (`home/mollyw.nix`): keep the network install (it's
  inherently impure — an OAuth-based plugin fetch — so it can't become a pure flake input),
  but stop silently swallowing all failures. Check whether the plugin is already installed
  before re-attempting network I/O on every activation, and echo a visible warning (not just
  `|| true`) if the install fails:
  ```nix
  home.activation.installOpencodeKimiPlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v opencode >/dev/null 2>&1 && [ ! -d "$HOME/.config/opencode/plugin/opencode-kimi-full" ]; then
      echo "Installing opencode-kimi-full plugin..."
      opencode plugin opencode-kimi-full --global || echo "warning: opencode-kimi-full install failed, run manually later"
    fi
  '';
  ```
  (Exact marker path to be confirmed against what `opencode plugin install` actually creates;
  falls back to always attempting if the check can't be verified.)

## Part D — install agenic-journal on chi

In `home/mollyw.nix`, add the packaged CLI to the user's environment:

```nix
home.packages = [
  inputs.agenic-journal.packages.${pkgs.stdenv.hostPlatform.system}.default
];
```

This makes `journal` available globally for `mollyw` once agenic-journal's flake input is
added and `extraSpecialArgs` wires `inputs` through (Part B). No further glue needed — the
user still runs `journal setup` once inside their private journal-entries git repo, same as
documented in agenic-journal's README.

## Verification

No `nix` binary is available in this sandbox, so full evaluation/build can't be done here.
Instead:
- Manually re-read every moved/edited file for syntax correctness and correct relative paths
  after the `hosts/`/`modules/`/`home/` split (imports, `./hardware-configuration.nix`
  references, etc.).
- Push and let the new CI workflow (Part F) run `nix flake check` + build the packaged CLI
  and the `chi` toplevel — this is the real evaluation/build verification, since it runs on
  a real Nix installation unlike this sandbox. Treat a green CI run as the signal the changes
  are structurally sound.
- Leave clear instructions in the commit/PR for the user to run on the laptop itself before
  merging/rebasing, since CI can't catch hardware-specific issues:
  - `nix flake check` and `nix fmt` locally
  - `nixos-rebuild build --flake .#chi` (build-only, no switch) as a final check
  - confirm the `programs.nh.flake` path actually matches where the repo is cloned on `chi`
- Note in the PR description that `nixos-rebuild switch` itself should only be run by the
  user on the real laptop, since this session cannot verify hardware-level behavior (display
  manager, power management, etc.) at all.

## Part E — formatting/linting: treefmt-nix + alejandra + statix + deadnix

Both repos get a `treefmt.nix`:

```nix
{ ... }: {
  projectRootFile = "flake.nix";
  programs.alejandra.enable = true;   # Nix formatter
  programs.statix.enable = true;      # Nix antipattern linter
  programs.deadnix.enable = true;     # dead Nix code finder
}
```

Scoped to `*.nix` files only — `scripts/journal` in agenic-journal is Bash, and running
shellcheck/shfmt over it risks unrelated noisy reformatting/failures on a script this plan
otherwise leaves untouched. Bash formatting is out of scope here.

- `oomlie/agenic-journal`: already restructured around `flake-utils.lib.eachDefaultSystem`
  in Part A, so add `treefmt-nix` as an input and add `formatter = treefmtEval.config.build.wrapper;`
  plus `checks.formatting = treefmtEval.config.build.check self;` alongside the existing
  `packages`/`apps`/`devShells` outputs.
- `oomlie/nixos`: has no per-system `eachDefaultSystem` wrapper (just a single
  `nixosConfigurations.chi` output) — rather than restructuring the whole flake around
  flake-utils for this, add `treefmt-nix` as an input and hardcode the one architecture
  that matters (`x86_64-linux`, confirmed by `hardware-configuration.nix`'s `kvm-intel`):
  `formatter.x86_64-linux = ...` and `checks.x86_64-linux.formatting = ...`.

Usage after this: `nix fmt` formats everything; `nix flake check` runs statix/deadnix/format
checks as part of the standard check suite.

## Part F — CI: GitHub Actions running `nix flake check`

Since this sandbox has no local `nix` to verify any of the above, CI becomes the actual
safety net. Add `.github/workflows/ci.yml` to both repos:

```yaml
name: CI
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - run: nix flake check
```

No cache action: `magic-nix-cache-action` broke when GitHub retired the old cache API
(early 2025) and its revival rides an undocumented reverse-engineered API — not worth the
flakiness for repos this small; substitution from cache.nixos.org covers it.

Plus a repo-specific sanity step:
- `oomlie/agenic-journal`: `nix build .#default && nix run .#default -- help` — confirms the
  packaged CLI actually builds and runs (trivially small build).
- `oomlie/nixos`: `nix eval --raw .#nixosConfigurations.chi.config.system.build.toplevel.drvPath`
  — full evaluation of the system config (catches module typos, bad option names, missing
  files) **without** downloading/building the closure. A full toplevel build of a
  Plasma6 + Discord + VSCodium system can blow past a GitHub runner's ~14GB disk, so
  eval-only is the reliable choice here; the real build happens on the laptop via
  `nixos-rebuild build`.

## Part G — additional tools: nh, nix-output-monitor, agenix

- **nh** (Nix Helper) and **nix-output-monitor**: add to `hosts/chi/configuration.nix`.
  `nh` gives readable rebuild diffs, scheduled cleanup, `nh search`; it auto-detects and
  shells out to `nom` for nicer build output if present.
  ```nix
  programs.nh = {
    enable = true;
    flake = "/home/mollyw/nixos";  # path where this repo is cloned on chi — confirm/adjust
    clean = {
      enable = true;                          # replaces nix.gc.automatic (mutually exclusive
      extraArgs = "--keep 5 --keep-since 14d"; # by module assertion — see Part C)
    };
  };
  environment.systemPackages = with pkgs; [ nix-output-monitor ... ];
  ```
- **agenix**: adds the plumbing for encrypted secrets, for if/when a static credential
  (e.g. a future non-OAuth API key) needs to live in the repo. No secret is being created
  now — the current opencode/Kimi setup is OAuth-based per `notes.md`, not a static token —
  this just wires the module up so adding one later is a five-minute job instead of a new
  integration.
  - Add `inputs.agenix = { url = "github:ryantm/agenix"; inputs.nixpkgs.follows = "nixpkgs"; };`
  - Import `agenix.nixosModules.default` into the flake's module list for `chi`, and add the
    CLI from the flake — `inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default`
    plus `pkgs.age` — to system packages. (**Not** `pkgs.agenix`, which doesn't exist; and
    nixpkgs' `agenix-cli` is an unrelated project — avoid it.)
  - Add `secrets/secrets.nix` (empty rule set) plus a short `secrets/README.md` explaining
    the workflow, since actually encrypting something requires the user's own age/SSH public
    key, which isn't available here — this step only prepares the scaffolding.

## Part H — Firefox: move to declarative home-manager profile

Replace the bare `programs.firefox.enable = true;` in `hosts/chi/configuration.nix` with a
single declaratively-managed profile in `home/mollyw.nix`. This is the actual fix for
"profile sprawl" going forward — profile settings and extensions become reproducible instead
of accumulating ad hoc state across manual `about:profiles` edits.

For the extension, use rycee's `firefox-addons` flake directly rather than pulling in all of
NUR (much lighter eval, same packages — this is the standard modern approach):

```nix
inputs.firefox-addons = {
  url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

In `home/mollyw.nix`:

```nix
programs.firefox = {
  enable = true;
  profiles.mollyw = {
    id = 0;
    isDefault = true;
    settings = {
      "toolkit.telemetry.enabled" = false;
      "toolkit.telemetry.unified" = false;
      "datareporting.healthreport.uploadEnabled" = false;
      "browser.newtabpage.activity-stream.showSponsored" = false;
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      "extensions.pocket.enabled" = false;
      "browser.toolbars.bookmarks.visibility" = "always";
    };
    extensions.packages = [
      inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}.ublock-origin
    ];
  };
};
```

`hosts/chi/configuration.nix` drops `programs.firefox.enable = true;` entirely — home-manager
owns Firefox now, avoids the two config paths disagreeing.

One-time manual step for the user (documented in the commit, not scriptable from here): after
the first rebuild with this profile active, consolidate/remove any old orphaned profile
directories under `~/.mozilla/firefox/` on `chi` itself, since this session has no access to
the real machine's disk.

## Part I — System font: Comic Mono Nerd Font, everywhere

Confirmed nixpkgs package: `pkgs.nerd-fonts.comic-shanns-mono` (Nerd Fonts patched variant of
Comic Mono — Comic Mono's own license didn't permit the patched redistribution, so the Nerd
Fonts project ships it under the name "ComicShannsMono"). Family names it provides:
`"ComicShannsMono Nerd Font"` (proportional icons) and `"ComicShannsMono Nerd Font Mono"`
(icons forced to true monospace width — the correct choice for terminals so glyphs don't
break alignment).

In `modules/common.nix` (applies fontconfig system-wide, covers terminal apps, GTK apps, and
VSCodium):

```nix
fonts.packages = with pkgs; [
  nerd-fonts.comic-shanns-mono
  noto-fonts-emoji  # fallback so emoji still render in color — Comic Mono has no emoji glyphs
];
fonts.fontconfig.defaultFonts = {
  serif = [ "ComicShannsMono Nerd Font" ];
  sansSerif = [ "ComicShannsMono Nerd Font" ];
  monospace = [ "ComicShannsMono Nerd Font Mono" ];
  emoji = [ "Noto Color Emoji" ];
};
```

fontconfig alone doesn't reach Plasma's own chrome (window titles, menus, panel widgets) —
KDE reads font settings from `kdeglobals`, not fontconfig fallback. The correct declarative
tool for that is **plasma-manager** (`nix-community/plasma-manager`), a well-established
home-manager module for KDE Plasma settings — adding it here is a new flake input/module,
flagged explicitly since it's beyond what Parts A–G already introduced:

```nix
inputs.plasma-manager = {
  url = "github:nix-community/plasma-manager";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.follows = "home-manager";
};
```

added via `home-manager.sharedModules = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];`
in the flake's home-manager block, then in `home/mollyw.nix`:

```nix
programs.plasma = {
  enable = true;
  fonts = {
    general = { family = "ComicShannsMono Nerd Font"; pointSize = 10; };
    fixedWidth = { family = "ComicShannsMono Nerd Font Mono"; pointSize = 10; };
    toolbar = { family = "ComicShannsMono Nerd Font"; pointSize = 10; };
    menu = { family = "ComicShannsMono Nerd Font"; pointSize = 10; };
    windowTitle = { family = "ComicShannsMono Nerd Font"; pointSize = 10; };
  };
};
```

Also set VSCodium's editor font in the existing `programs.vscodium.profiles.default.userSettings`
block in `home/mollyw.nix`:

```nix
"editor.fontFamily" = "'ComicShannsMono Nerd Font Mono'";
```

Exact point sizes and whether the icon-heavy Nerd Font glyphs look right in Plasma's small UI
chrome (panel, menu) are cosmetic judgment calls best made on the real laptop — call this out
as a follow-up tweak for the user rather than guessing precise sizes here.

## Part J — bring more programs under home-manager

All in `home/mollyw.nix`, using home-manager's built-in modules (each ships its own zsh
integration, so enabling the program + `enableZshIntegration`-style options is the whole job):

- **zsh + starship**: the shell is zsh (set system-side in `configuration.nix`) but has zero
  user config today — biggest gap in the setup.
  ```nix
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = { size = 50000; ignoreDups = true; share = true; };
  };
  programs.starship.enable = true;  # prompt icons render in the new Nerd Font
  ```
  (Keep `programs.zsh.enable = true;` at the system level too — NixOS needs it there for
  zsh to be a valid login shell; home-manager layers user config on top.)
- **direnv + nix-direnv**: auto-loads flake devShells when cd-ing into a project (pairs with
  agenic-journal's new devShell).
  ```nix
  programs.direnv = { enable = true; nix-direnv.enable = true; };
  ```
  (direnv's zsh hook is enabled by default when programs.zsh is managed by hm.)
- **Shell QoL**: `programs.fzf.enable`, `programs.zoxide.enable`, `programs.bat.enable`
  (catppuccin-adjacent theme via `config.theme` if a built-in matches, else default),
  `programs.eza = { enable = true; icons = "auto"; }` — icons render via the Nerd Font.
- **btop**: replace the bare `btop` entry in `environment.systemPackages` with
  `programs.btop = { enable = true; settings.color_theme = "..."; }` in hm — remove it from
  the system package list to avoid double-managing.
- **Ghostty** (replaces Konsole, which gets excluded from Plasma in Part K):
  ```nix
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";        # built-in Ghostty theme, matches Helix/VSCodium
      font-family = "ComicShannsMono Nerd Font Mono";
      font-size = 11;
    };
  };
  ```
  Also register it as Plasma's default terminal (what Meta+Enter / "Open Terminal" launches)
  via plasma-manager's raw config escape hatch:
  ```nix
  programs.plasma.configFile.kdeglobals.General.TerminalApplication = "ghostty";
  ```

## Part K — Steam + gamemode, wallpaper, KDE debloat

**Steam + gamemode**, in `hosts/chi/configuration.nix` (notes.md already flags TF2 as a
target; `allowUnfree` is already on):

```nix
programs.steam = {
  enable = true;
  remotePlay.openFirewall = true;  # only if remote play is actually wanted; harmless default
};
programs.gamemode.enable = true;   # launch options: gamemoderun %command%
```

The NixOS steam module handles 32-bit libraries/driver plumbing itself — no manual
`hardware.graphics` additions needed beyond what hardware-configuration.nix already enables.

**Wallpaper**, shipped in the repo and set declaratively:
- Generate a catppuccin-mocha gradient wallpaper PNG at 2256×1504 (Framework 12 panel
  resolution) with a local Python script (pure-Python PNG writing, no network), committed as
  `wallpapers/catppuccin-mocha.png`.
- Reference it via a Nix store path so rebuilds are self-contained regardless of where the
  repo is cloned — in `home/mollyw.nix`:
  ```nix
  programs.plasma.workspace.wallpaper = "${../wallpapers/catppuccin-mocha.png}";
  ```
  (relative-path interpolation copies the file to the store; plasma-manager points Plasma at
  it). User can swap the image file and rebuild anytime.

**KDE debloat**, in `hosts/chi/configuration.nix` — removes preinstalled Plasma apps that
are unused (kate/konsole redundant with Helix/VSCodium/Ghostty; krdp/krfb remote-desktop
servers unwanted):

```nix
environment.plasma6.excludePackages = with pkgs.kdePackages; [
  elisa        # music player
  khelpcenter  # help browser
  kate         # text editor — Helix/VSCodium cover this
  konsole      # terminal — replaced by Ghostty (Part J)
  krdp         # RDP server
  krfb         # VNC/desktop-sharing server
];
```

`excludePackages` filters the Plasma default package set, so listing something not present
in the set is harmless — no risk if e.g. krfb isn't in the default install.

## Commits / PRs

- `oomlie/agenic-journal`: commit(s) adding `flake.nix`, `treefmt.nix`, and
  `.github/workflows/ci.yml`, pushed to `claude/nixos-config-improvements-9l3kgy`.
- `oomlie/nixos`: commit(s) for the restructure, practical fixes, agenic-journal
  integration, treefmt/CI, nh/nom/agenix additions, the Firefox home-manager migration, and
  the Comic Mono Nerd Font rollout (fontconfig + plasma-manager + VSCodium), and the new
  home-manager program configs (zsh/starship, direnv, fzf/zoxide/bat/eza, btop, Ghostty),
  plus Steam/gamemode, the repo-shipped wallpaper, and the Plasma debloat list, pushed to
  `claude/nixos-config-improvements-9l3kgy`.
- Do not open PRs unless the user asks.
