{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  tea = pkgs.writeShellApplication {
    name = "tea";
    runtimeInputs = [pkgs.libsecret];
    text = ''
      config_dir="$(mktemp -d "''${XDG_RUNTIME_DIR:-/tmp}/tea.XXXXXX")"
      trap 'rm -rf "$config_dir"' EXIT
      mkdir -p "$config_dir/tea"

      token="$(secret-tool lookup service gitea host git.purplish.blue user molly)"
      if [[ -z "$token" ]]; then
        echo "tea: Gitea token not found in the keyring" >&2
        exit 1
      fi

      umask 077
      cat >"$config_dir/tea/config.yml" <<EOF
      logins:
        - name: purplish
          url: https://git.purplish.blue
          token: $token
          default: true
          user: molly
      EOF

      XDG_CONFIG_HOME="$config_dir" ${pkgs.tea}/bin/tea "$@"
    '';
  };
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
        credential."https://git.purplish.blue".helper = "${giteaCredentialHelper}";
        core.editor = "hx";
        alias = {
          hdiff = "!hunk diff";
          hshow = "!hunk show";
          dft = "difftool --no-prompt --tool=difftastic";
        };
        difftool.difftastic.cmd = "difft \"$LOCAL\" \"$REMOTE\"";
      };
    };

    jujutsu = {
      enable = true;
      ediff = false;
      settings.user = {
        name = "molly.computer";
        email = "molly@molly.computer";
      };
    };

    hunk = {
      enable = true;
      enableJujutsuIntegration = true;
      settings = {
        mode = "auto";
        line_numbers = true;
        exclude_untracked = false;
        transparent_background = true;
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
  };

  home.packages = [
    pkgs.difftastic
    pkgs.proton-authenticator
    pkgs.proton-pass
    pkgs.proton-vpn
    pkgs.prismlauncher
    pkgs.signal-desktop
    pkgs.thunderbird
    pkgs.unzip
    pkgs.rns
    pkgs.lxmf
    pkgs.nomadnet
    pkgs.sideband
    pkgs.xclip
    tea
  ];
}
