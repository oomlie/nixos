# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
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
          # Language / dev support
          rust-lang.rust-analyzer
          jnoortheen.nix-ide
          tamasfe.even-better-toml
          redhat.vscode-yaml
          yzhang.markdown-all-in-one
          dbaeumer.vscode-eslint
          esbenp.prettier-vscode

          # Quality of life
          usernamehw.errorlens
          gruntfuggly.todo-tree
          aaron-bond.better-comments

          # Theme
          catppuccin.catppuccin-vsc

          # Custom extensions from Open VSX
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
        };
      };
    };
  };

  # opencode configuration with Kimi OAuth plugin pre-configured
  # Run `opencode plugin opencode-kimi-full --global` once to install the plugin,
  # or let the activation script below attempt it automatically.
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

  # Attempt to install the opencode-kimi-full plugin automatically.
  # This requires network access during activation. Failures are ignored
  # so they do not break rebuilds; you can always install manually with:
  #   opencode plugin opencode-kimi-full --global
  home.activation.installOpencodeKimiPlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v opencode >/dev/null 2>&1; then
      echo "Ensuring opencode-kimi-full plugin is installed..."
      opencode plugin opencode-kimi-full --global || true
    fi
  '';

  home.stateVersion = "25.11";
}
