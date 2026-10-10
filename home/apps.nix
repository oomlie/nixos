{
  lib,
  pkgs,
  config,
  giteaCredentialHelper,
  browserProfile,
  ...
}: let
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
  signalDesktop = pkgs.symlinkJoin {
    name = "signal-desktop";
    paths = [pkgs.signal-desktop];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/signal-desktop" --add-flags "--password-store=kwallet6"
    '';
  };
  # Zed reads the OpenAI-compatible edit-prediction key from this env var.
  # Zeta 2.1 runs on halo, proxied at route.daze.lol/zeta; the key is the
  # halo gateway key kept in the login keyring.
  zedEditor = pkgs.symlinkJoin {
    name = "zed-editor";
    paths = [pkgs.zed-editor];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram "$out/bin/zeditor" \
        --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.libsecret]} \
        --run 'ZED_OPEN_AI_COMPATIBLE_EDIT_PREDICTION_API_KEY="$(secret-tool lookup service halo host halo.daze.lol user molly)"; export ZED_OPEN_AI_COMPATIBLE_EDIT_PREDICTION_API_KEY'
    '';
  };
in {
  programs = {
    helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        editor.line-number = "relative";
        editor.cursorline = true;
        editor.indent-guides.render = true;
        editor.bufferline = "multiple";
        editor.lsp.display-inlay-hints = true;
      };
      ignores = [".direnv/" "result"];
      languages.language = [
        {
          name = "nix";
          language-servers = ["nil"];
          formatter = {command = "alejandra";};
          auto-format = true;
        }
        {
          name = "rust";
          formatter = {command = "rustfmt";};
          auto-format = true;
        }
        {
          name = "bash";
          formatter = {command = "shfmt";};
          auto-format = true;
        }
        {
          name = "toml";
          formatter = {
            command = "taplo";
            args = ["format" "-"];
          };
          auto-format = true;
        }
        {
          name = "markdown";
          formatter = {
            command = "prettier";
            args = ["--parser=markdown"];
          };
          auto-format = true;
        }
        {
          name = "typescript";
          formatter = {command = "prettier";};
          auto-format = true;
        }
        {
          name = "tsx";
          formatter = {command = "prettier";};
          auto-format = true;
        }
        {
          name = "javascript";
          formatter = {command = "prettier";};
          auto-format = true;
        }
      ];
      extraPackages = with pkgs; [
        nil
        alejandra
        rust-analyzer
        rustfmt
        bash-language-server
        shfmt
        taplo
        yaml-language-server
        vscode-langservers-extracted
        marksman
        prettier
        typescript-language-server
        pyright
      ];
    };

    git = {
      enable = true;
      lfs.enable = true;
      signing = {
        format = "ssh";
        key = "~/.ssh/mol.pub";
        signer = "${pkgs.openssh}/bin/ssh-keygen";
        signByDefault = true;
      };
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
        merge.conflictStyle = "zdiff3";
        diff.algorithm = "histogram";
        diff.colorMoved = "zebra";
        rerere.enabled = true;
        fetch.prune = true;
        rebase.autoStash = true;
        column.ui = "auto";
        branch.sort = "-committerdate";
        alias = {
          hdiff = "!hunk diff";
          hshow = "!hunk show";
          dft = "difftool --no-prompt --tool=difftastic";
        };
        difftool.difftastic.cmd = "difft \"$LOCAL\" \"$REMOTE\"";
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        features = "line-numbers";
        navigate = true;
        side-by-side = true;
      };
    };

    jujutsu = {
      enable = true;
      ediff = false;
      settings = {
        user = {
          name = "molly.computer";
          email = "molly@molly.computer";
        };
        aliases = {
          l = "log -r '::@'";
          ll = "log -r 'all()'";
        };
        signing = {
          behavior = "own";
          backend = "ssh";
          key = "~/.ssh/mol.pub";
        };
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
          "editor.formatOnSave" = true;
          "editor.tabSize" = 2;
          "editor.minimap.enabled" = false;
          "editor.renderWhitespace" = "boundary";
          "files.autoSave" = "onFocusChange";
          "telemetry.telemetryLevel" = "off";
          "update.mode" = "none";
          "extensions.autoUpdate" = false;
          "workbench.startupEditor" = "none";
        };
      };
    };

    firefox = {
      enable = true;
      profiles.mollyw = browserProfile;
    };

    btop = {
      enable = true;
      settings = {
        vim_keys = true;
        update_ms = 1000;
        proc_sorting = "cpu lazy";
        shown_boxes = "cpu mem net proc";
      };
    };

    thunderbird = {
      enable = true;
      profiles.default = {
        isDefault = true;
        settings = {
          "mail.spellcheck.inline" = true;
          "datareporting.healthreport.uploadEnabled" = false;
          "toolkit.telemetry.enabled" = false;
        };
      };
    };

    zed-editor = {
      enable = true;
      package = zedEditor;
      userSettings = {
        edit_predictions = {
          provider = "open_ai_compatible_api";
          open_ai_compatible_api = {
            api_url = "https://route.daze.lol/zeta/v1/completions";
            model = "zeta2.1";
            prompt_format = "zeta2_1";
            max_output_tokens = 512;
          };
        };
      };
    };
  };

  home.packages = [
    pkgs.difftastic
    pkgs.proton-authenticator
    pkgs.proton-pass
    pkgs.proton-vpn
    pkgs.prismlauncher
    pkgs.kdePackages.kwallet
    signalDesktop
    pkgs.unzip
    pkgs.rns
    pkgs.lxmf
    pkgs.nomadnet
    pkgs.sideband
    pkgs.xclip
    tea
  ];
}
