_: {
  programs = {
    zsh = {
      enable = true;
      # Skip compaudit security scan (~15ms/shell); keep dump freshness check
      completionInit = "autoload -U compinit && compinit -u";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        size = 50000;
        ignoreDups = true;
        share = true;
      };
      shellAliases = {
        halo = "ssh halo";
        chi = "ssh chi";
      };
    };

    ssh = {
      enable = true;
      matchBlocks = {
        halo = {
          hostname = "192.168.0.169";
          user = "molly";
        };
        chi = {
          hostname = "192.168.0.216";
          user = "mollyw";
        };
        "knot-ssh.daze.lol" = {
          user = "git";
          identityFile = "~/.ssh/mol";
          proxyCommand = "cloudflared access ssh --hostname %h";
        };
      };
    };

    starship.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fzf.enable = true;
    zoxide.enable = true;
    bat.enable = true;
    eza = {
      enable = true;
      icons = "auto";
    };
    nnn.enable = true;
  };
}
