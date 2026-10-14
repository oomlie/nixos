{
  pkgs,
  lib,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;

  # Shared by Firefox and Zen: hardening, search, bookmarks, containers, and
  # extensions live here so the two browsers cannot drift apart.
  browserProfile = {
    id = 0;
    isDefault = true;

    search = {
      force = true;
      default = "ddg";
    };

    bookmarks = {
      force = true;
      settings = [
        {
          name = "SearXNG";
          url = "https://search.daze.lol/";
          keyword = "s";
        }
        {
          name = "NixOS Search";
          url = "https://search.nixos.org/packages";
          keyword = "np";
        }
        {
          name = "NixOS Wiki";
          url = "https://wiki.nixos.org/";
          keyword = "nw";
        }
        "separator"
        {
          name = "Tangled";
          url = "https://tangled.org/molly.computer";
        }
        {
          name = "Gitea";
          url = "https://git.purplish.blue/molly";
        }
      ];
    };

    containersForce = true;
    containers = {
      personal = {
        name = "Personal";
        color = "blue";
        icon = "fingerprint";
        id = 1;
      };
      work = {
        name = "Work";
        color = "orange";
        icon = "briefcase";
        id = 2;
      };
      shopping = {
        name = "Shopping";
        color = "green";
        icon = "cart";
        id = 3;
      };
    };

    settings = {
      # Use regular default fonts instead of the system-wide
      # ComicShannsMono nerd font
      "font.name.sans-serif.x-western" = lib.mkForce "Noto Sans";
      "font.name.serif.x-western" = lib.mkForce "Noto Serif";
      "font.name.monospace.x-western" = lib.mkForce "Noto Sans Mono";

      # Privacy: telemetry & studies
      "toolkit.telemetry.enabled" = false;
      "toolkit.telemetry.unified" = false;
      "toolkit.telemetry.archive.enabled" = false;
      "datareporting.healthreport.uploadEnabled" = false;
      "datareporting.policy.dataSubmissionEnabled" = false;
      "app.shield.optoutstudies.enabled" = false;
      "browser.newtabpage.activity-stream.feeds.telemetry" = false;
      "browser.newtabpage.activity-stream.telemetry" = false;
      "browser.discovery.enabled" = false;

      # Privacy: tracking protection
      "browser.contentblocking.category" = "strict";
      "privacy.globalprivacycontrol.enabled" = true;
      "privacy.donottrackheader.enabled" = true;
      "privacy.query_stripping.enabled" = true;
      "privacy.query_stripping.enabled.pbmode" = true;
      "privacy.fingerprintingProtection" = true;

      # Privacy: network leakage
      "dom.security.https_only_mode" = true;
      "network.dns.disablePrefetch" = true;
      "network.prefetch-next" = false;
      "network.predictor.enabled" = false;
      "network.http.speculative-parallel-limit" = 0;
      "browser.send_pings" = false;
      "beacon.enabled" = false;
      "dom.battery.enabled" = false;
      "geo.enabled" = false;

      # Privacy: credentials & autofill (Proton Pass handles this)
      "signon.rememberSignons" = false;
      "signon.autofillForms" = false;
      "browser.formfill.enable" = false;
      "extensions.formautofill.addresses.enabled" = false;
      "extensions.formautofill.creditCards.enabled" = false;

      # UI
      "browser.newtabpage.activity-stream.showSponsored" = false;
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      "extensions.pocket.enabled" = false;
      "browser.toolbars.bookmarks.visibility" = "always";
      "browser.startup.homepage" = "about:blank";
    };

    extensions.packages = with inputs.firefox-addons.packages.${system}; [
      ublock-origin
      proton-pass
      vimium
    ];
  };
in {
  imports = [
    ./apps.nix
    ./foot.nix
    ./niri.nix
    ./cloudflare-backup.nix
    ./fleet-status-collector.nix
    ./noctalia.nix
    ./opencode.nix
    ./qutebrowser.nix
    ./shell.nix
    ./satty.nix
    ./stylix.nix
    ./tablet.nix
    ./zen.nix
  ];

  _module.args = {
    wallpaper = ../wallpapers/wp2002041.jpg;
    inherit browserProfile;

    # Shared credential helper for git.purplish.blue (git + the agent-wiki pull).
    giteaCredentialHelper = pkgs.writeShellScript "git-credential-purplish" ''
      if [[ "''${1:-}" != get ]]; then
        exit 0
      fi

      token="$(${pkgs.libsecret}/bin/secret-tool lookup service gitea host git.purplish.blue user molly)"
      if [[ -z "$token" ]]; then
        exit 1
      fi

      printf '%s\n' "username=molly" "password=$token"
    '';
  };

  home = {
    username = "mollyw";
    homeDirectory = "/home/mollyw";

    packages = with pkgs; [
      libsecret
      github-cli

      # Niri ecosystem
      xwayland-satellite
      equibop

      # Game development
      godot_4
    ];

    # stateVersion is a compatibility pin — do not change on every upgrade
    stateVersion = "26.05";

    sessionPath = ["$HOME/.bun/bin" "$HOME/.npm-global/bin"];
  };

  programs.home-manager.enable = true;
}
