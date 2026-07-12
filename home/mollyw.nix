{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [ ];

  home = {
    username = "mollyw";
    homeDirectory = "/home/mollyw";
  };

  home.packages = [
    inputs.agenic-journal.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs = {
    home-manager.enable = true;

    helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = "catppuccin_mocha";
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
          catppuccin.catppuccin-vsc
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
          "workbench.colorTheme" = "Catppuccin Mocha";
          "editor.fontFamily" = "'ComicShannsMono Nerd Font Mono'";
        };
      };
    };

    # Part H: Firefox declarative profile
    firefox = {
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

    # Part J: zsh + starship
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = { size = 50000; ignoreDups = true; share = true; };
    };
    starship.enable = true;

    # Part J: direnv + nix-direnv
    direnv = { enable = true; nix-direnv.enable = true; };

    # Part J: Shell QoL
    fzf.enable = true;
    zoxide.enable = true;
    bat.enable = true;
    eza = { enable = true; icons = "auto"; };

    # Part J: btop
    btop = {
      enable = true;
      settings = {
        color_theme = "catppuccin_mocha";
      };
    };

    # Part J: Ghostty
    ghostty = {
      enable = true;
      settings = {
        theme = "catppuccin-mocha";
        font-family = "ComicShannsMono Nerd Font Mono";
        font-size = 11;
      };
    };
  };

  # Part I: Plasma fonts (plasma-manager)
  programs.plasma = {
    enable = true;
    fonts = {
      general = { family = "ComicShannsMono Nerd Font"; pointSize = 10; };
      fixedWidth = { family = "ComicShannsMono Nerd Font Mono"; pointSize = 10; };
      toolbar = { family = "ComicShannsMono Nerd Font"; pointSize = 10; };
      menu = { family = "ComicShannsMono Nerd Font"; pointSize = 10; };
      windowTitle = { family = "ComicShannsMono Nerd Font"; pointSize = 10; };
    };
    workspace.wallpaper = "${../wallpapers/catppuccin-mocha.png}";
    configFile.kdeglobals.General.TerminalApplication = "ghostty";
  };

  # opencode configuration with Kimi OAuth plugin
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    plugin = [ "opencode-kimi-full" ];
    provider = {
      "kimi-for-coding-oauth" = {
        name = "Kimi For Coding (OAuth)";
        npm = "@ai-sdk/openai-compatible";
        options = {
          baseURL = "https://api.kimi.com/coding/v1";
        };
        models = {
          "kimi-for-coding" = {
            name = "Kimi For Coding";
            attachment = true;
            reasoning = true;
            modalities = {
              input = [ "text" "image" ];
              output = [ "text" ];
            };
            options = {};
            variants = {
              off = { reasoning_effort = "off"; };
              auto = { reasoning_effort = "auto"; };
              low = { reasoning_effort = "low"; };
              medium = { reasoning_effort = "medium"; };
              high = { reasoning_effort = "high"; };
            };
          };
        };
      };
    };
  };

  # Improved Kimi plugin activation script
  home.activation.installOpencodeKimiPlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v opencode >/dev/null 2>&1 && [ ! -d "$HOME/.config/opencode/plugin/opencode-kimi-full" ]; then
      echo "Installing opencode-kimi-full plugin..."
      opencode plugin opencode-kimi-full --global || echo "warning: opencode-kimi-full install failed, run manually later"
    fi
  '';

  # stateVersion is a compatibility pin — do not change on every upgrade
  home.stateVersion = "26.05";
}
