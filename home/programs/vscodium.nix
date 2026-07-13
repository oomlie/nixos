{pkgs, ...}: {
  programs.vscodium = {
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
}
