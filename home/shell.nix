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
      # Make the current defaults explicit before Home Manager removes them.
      enableDefaultConfig = false;
      settings = {
        "*" = {
          ForwardAgent = false;
          AddKeysToAgent = "no";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };
        halo = {
          HostName = "192.168.0.169";
          User = "molly";
        };
        chi = {
          HostName = "192.168.0.216";
          User = "mollyw";
        };
        "knot-ssh.daze.lol" = {
          User = "git";
          IdentityFile = "~/.ssh/mol";
          ProxyCommand = "cloudflared access ssh --hostname %h";
        };
        "tangled.org" = {
          User = "git";
          IdentityFile = "~/.ssh/mol";
          AddressFamily = "inet";
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
