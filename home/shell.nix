{pkgs, ...}: {
  programs = {
    zsh = {
      enable = true;
      # Skip compaudit security scan (~15ms/shell); keep dump freshness check
      completionInit = "autoload -U compinit && compinit -u";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      historySubstringSearch.enable = true;
      setOptions = ["HIST_VERIFY" "NO_BEEP" "COMPLETE_ALIASES"];
      shellGlobalAliases = {
        G = "| grep";
        L = "| less";
      };
      initContent = ''
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' menu select
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      '';
      history = {
        size = 50000;
        ignoreDups = true;
        share = true;
      };
      shellAliases = {
        halo = "ssh halo";
        chi = "ssh chi";
        misty = "ssh misty";
        dsh = "ssh dsh";
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
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "auto";
          ControlPath = "~/.ssh/cm-%r@%h:%p";
          ControlPersist = "10m";
        };
        halo = {
          HostName = "100.64.0.1";
          User = "molly";
          # chi and halo sit on different LANs (192.168.1.0/24 vs
          # 192.168.0.0/24); reach halo over the tailnet via misty.
          ProxyJump = "molly@192.168.1.174";
        };
        chi = {
          HostName = "192.168.0.216";
          User = "mollyw";
        };
        misty = {
          HostName = "192.168.1.174";
          User = "molly";
        };
        dsh = {
          HostName = "100.64.0.1";
          User = "molly";
          ProxyJump = "molly@192.168.1.174";
          RequestTTY = "force";
          RemoteCommand = "/home/molly/dsh-tui/ssh-entry.sh";
          ControlPath = "~/.ssh/cm-dsh-%r@%h:%p";
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

    fzf = {
      enable = true;
      defaultOptions = [
        "--height=~40%"
        "--layout=reverse"
        "--border"
        "--info=inline"
        "--bind=ctrl-j:down,ctrl-k:up"
      ];
    };
    zoxide.enable = true;
    bat = {
      enable = true;
      config = {
        pager = "less -FR";
        style = "numbers,changes,header";
      };
    };
    eza = {
      enable = true;
      icons = "auto";
      git = true;
      extraOptions = ["--group-directories-first" "--header" "--git-ignore"];
    };
    nnn = {
      enable = true;
      package = pkgs.nnn.override {withNerdIcons = true;};
      quitcd = true;
      bookmarks = {
        d = "~/Documents";
        D = "~/Downloads";
        p = "~/Pictures";
        v = "~/Videos";
        n = "~/nixos";
        c = "~/.config";
        P = "~/Projects";
      };
      # -a sets up NNN_FIFO for preview-tui; -d detail, -H hidden, -e open text in $EDITOR, -U user/group
      options = {
        a = true;
        d = true;
        H = true;
        e = true;
        U = true;
      };
      plugins = {
        src = "${pkgs.nnn}/share/plugins";
        mappings = {
          c = "fzcd";
          f = "finder";
          p = "preview-tui";
          v = "imgview";
          d = "dups";
          g = "gitroot";
          m = "nmount";
          n = "bulknew";
          r = "renamer";
        };
      };
      extraPackages = with pkgs; [
        fzf
        findutils
        imv
        chafa
        bat
        less
        ffmpegthumbnailer
        poppler-utils
        mediainfo
        unzip
        gnutar
        file
        exiftool
        man
        udisks2
        trash-cli
      ];
    };
  };

  home.sessionVariables = {
    NNN_TERMINAL = "foot";
    NNN_TRASH = "1";
  };
}
