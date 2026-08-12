{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  programs = {
    helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        editor.line-number = "relative";
      };
    };

    git = {
      enable = true;
      settings = {
        user = {
          name = "molly.computer";
          email = "molly@molly.computer";
        };
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = false;
        core.editor = "hx";
      };
    };

    vscodium = {
      enable = true;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          rust-lang.rust-analyzer
          jnoortheen.nix-ide
          tamasfe.even-better-toml
          redhat.vscode-yaml
          yzhang.markdown-all-in-one
          dbaeumer.vscode-eslint
          esbenp.prettier-vscode
          usernamehw.errorlens
          gruntfuggly.todo-tree
          aaron-bond.better-comments
          (pkgs.vscode-utils.buildVscodeExtension {
            pname = "kimi-code";
            version = "0.5.10";
            vscodeExtPublisher = "moonshot-ai";
            vscodeExtName = "kimi-code";
            vscodeExtUniqueId = "moonshot-ai.kimi-code";
            src = pkgs.fetchurl {
              name = "kimi-code.vsix";
              url = "https://open-vsx.org/api/moonshot-ai/kimi-code/linux-x64/0.5.10/file/moonshot-ai.kimi-code-0.5.10@linux-x64.vsix";
              sha256 = "1pfdhbcvbb344mvdmmbymzlw8kzgkw6sxl9frmd9jx76pbgx3w9l";
            };
          })
          (pkgs.vscode-utils.buildVscodeExtension {
            pname = "git-graph";
            version = "1.30.0";
            vscodeExtPublisher = "mhutchie";
            vscodeExtName = "git-graph";
            vscodeExtUniqueId = "mhutchie.git-graph";
            src = pkgs.fetchurl {
              name = "git-graph.vsix";
              url = "https://open-vsx.org/api/mhutchie/git-graph/1.30.0/file/mhutchie.git-graph-1.30.0.vsix";
              sha256 = "0bsmvcxl5jg2qzhxx3mm2ki5xqp79mp2hf333m1ka413nvas7fm6";
            };
          })
        ];
        userSettings = {
          "editor.fontFamily" = lib.mkForce "'${config.stylix.fonts.monospace.name}'";
        };
      };
    };

    firefox = {
      enable = true;
      profiles.mollyw = {
        id = 0;
        isDefault = true;
        settings = {
          # Use regular Firefox default fonts instead of the system-wide
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
    };

    btop.enable = true;

    # Application launcher
    vicinae = {
      enable = true;
      systemd = {
        enable = true;
        autoStart = true;
      };
      settings = {
        close_on_focus_loss = true;
        pop_to_root_on_close = true;
        launcher_window = {
          layer_shell = {
            enabled = true;
          };
        };
      };
    };
  };
}
