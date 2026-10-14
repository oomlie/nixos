{
  pkgs,
  tildeSiteTools,
  ...
}: let
  dcss = pkgs.writeShellApplication {
    name = "dcss";
    runtimeInputs = [
      pkgs.curl
      pkgs.openssh
    ];
    text = ''
      if [ ! -f "$HOME/.ssh/dcss" ]; then
        umask 077
        curl -fsSo "$HOME/.ssh/dcss" https://crawl.tildeverse.org/dcss.key
        ssh-keygen -y -f "$HOME/.ssh/dcss" >"$HOME/.ssh/dcss.pub" 2>/dev/null || true
      fi
      exec ssh -i "$HOME/.ssh/dcss" -o VerifyHostKeyDNS=yes dcss@crawl.tildeverse.org
    '';
  };
  tildeHelp = pkgs.writeShellApplication {
    name = "tilde-help";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      cat <<'EOF'
      daze.lol pubnix

      Website:       https://$USER.daze.lol/ or https://tilde.daze.lol/~$USER/
      Web files:     ~/public_html
      Gemini:        gemini://gemini.daze.lol/~$USER/ from ~/public_gemini
      Gopher:        gopher://gopher.daze.lol/1/~$USER/ from ~/public_gopher
      Profile:       edit ~/.plan and ~/.project; view with `finger $USER`
      Shell:         chsh -s /run/current-system/sw/bin/zsh  (or fish/bash)
      Cron:          crontab -e
      Nix package:   nix profile install nixpkgs#<package>
      Temporary app: nix shell nixpkgs#<package>
      IRC:           irc.daze.lol:6697 or https://irc.daze.lol/
      Pastebin:      https://paste.daze.lol/
       RSSHub:        https://rsshub.daze.lol/
      Roguelike:     dcss          (shared tildeverse crawl server)

      Keep public files in the public_* directories. Home directories are not
      listable by other users. Run `tilde-help` whenever you need this list.
      EOF
    '';
  };
  tildeUserLayout = pkgs.writeShellApplication {
    name = "tilde-user-layout";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.getent
    ];
    text = ''
      members="$(getent group tilde | cut -d: -f4)"
      old_ifs="$IFS"
      IFS=,
      for user in $members; do
        [ -n "$user" ] || continue
        home="/home/$user"
        [ -d "$home" ] || continue

        chmod 0711 "$home"
        install -d -m 0755 -o "$user" -g "$user" \
          "$home/public_html" "$home/public_gemini" "$home/public_gopher"
        touch "$home/.plan" "$home/.project"
        chown "$user:$user" "$home/.plan" "$home/.project"
        chmod 0644 "$home/.plan" "$home/.project"
        ln -sfn "$home/public_gemini" "/var/lib/agate/content/~$user"
        ln -sfn "$home/public_gopher" "/var/lib/gopher/~$user"
      done
      IFS="$old_ifs"
    '';
  };
  tildeAddUser = pkgs.writeShellApplication {
    name = "tilde-add-user";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.getent
      pkgs.gnugrep
      pkgs.shadow
    ];
    text = ''
      set -euo pipefail

      if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
        echo "usage: tilde-add-user <username> <ssh-public-key-file> [shell]" >&2
        exit 2
      fi

      user="$1"
      keyfile="$2"
      shell="''${3:-bash}"

      case "$shell" in
        bash|zsh|fish) shell="/run/current-system/sw/bin/$shell" ;;
      esac

      if ! printf '%s' "$user" | grep -Eq '^[a-z][a-z0-9_]{0,30}$'; then
        echo "invalid username: $user" >&2
        exit 1
      fi

      if [ ! -r "$keyfile" ]; then
        echo "cannot read key file: $keyfile" >&2
        exit 1
      fi

      if ! grep -Fxq "$shell" /etc/shells; then
        echo "shell is not listed in /etc/shells: $shell" >&2
        exit 1
      fi

      if getent passwd "$user" >/dev/null; then
        echo "user already exists: $user" >&2
        exit 1
      fi

      useradd -m -G tilde,radio -s "$shell" "$user"
      chmod 0711 "/home/$user"
      install -d -m 0755 -o "$user" -g "$user" "/home/$user/public_html"
      install -d -m 0755 -o "$user" -g "$user" "/home/$user/public_gemini"
      install -d -m 0755 -o "$user" -g "$user" "/home/$user/public_gopher"
      install -d -m 0700 -o "$user" -g "$user" "/home/$user/.ssh"
      install -m 0600 -o "$user" -g "$user" "$keyfile" "/home/$user/.ssh/authorized_keys"
      printf '%s\n' "welcome to tilde" >"/home/$user/public_html/index.html"
      printf '%s\n' "# $user on daze.lol" >"/home/$user/public_gemini/index.gmi"
      printf '%s\n' "Welcome to $user's gopher hole." >"/home/$user/public_gopher/index.gph"
      printf '%s\n' "New here. More soon." >"/home/$user/.plan"
      printf '%s\n' "Personal projects on daze.lol" >"/home/$user/.project"
      chown "$user:$user" \
        "/home/$user/public_html/index.html" \
        "/home/$user/public_gemini/index.gmi" \
        "/home/$user/public_gopher/index.gph" \
        "/home/$user/.plan" \
        "/home/$user/.project"
      chmod 0644 "/home/$user/.plan" "/home/$user/.project"

      ln -sfn "/home/$user/public_gemini" "/var/lib/agate/content/~$user"
      ln -sfn "/home/$user/public_gopher" "/var/lib/gopher/~$user"

      echo "created $user; site: https://$user.daze.lol/" >&2
    '';
  };
in {
  # Accounts are created with `tilde-add-user` at runtime, not declared here,
  # so an admin approval survives Nix rebuilds.
  users.mutableUsers = true;
  users.groups.tilde = {};

  # Let approved pubnix users use the multi-user Nix daemon without making
  # them trusted users. Builds remain sandboxed and cannot add binary caches.
  nix.settings.allowed-users = [
    "root"
    "molly"
    "@tilde"
  ];

  # Shells available to users via `chsh` (added to /etc/shells by the modules).
  programs.zsh.enable = true;
  programs.fish.enable = true;

  services.cron.enable = true;

  users.motd = ''
    Welcome to daze.lol.
    Run `tilde-help` for publishing, shells, cron, profiles, and Nix packages.
  '';

  environment.systemPackages = with pkgs; [
    tildeAddUser
    tildeHelp
    bsd-finger
    cargo
    cmatrix
    cowsay
    curl
    dcss
    fd
    figlet
    file
    fortune
    gcc
    git
    gnumake
    go
    jq
    less
    lolcat
    mosh
    nano
    neovim
    nodejs
    pkg-config
    python3
    ripgrep
    rsync
    rustc
    sl
    tmux
    tree
    wget
  ];

  # New homes get publishing/profile directories automatically. The shared
  # roots contain only symlinks into explicitly public user directories.
  systemd.tmpfiles.rules = [
    "d /etc/skel/public_html 0755 root root - -"
    "d /etc/skel/public_gemini 0755 root root - -"
    "d /etc/skel/public_gopher 0755 root root - -"
    "d /var/lib/agate 0755 root root - -"
    "d /var/lib/agate/content 0755 root root - -"
    "d /var/lib/gopher 0755 gopher gopher - -"
    "d /var/www/tilde/users 0755 root root - -"
    "d /var/www/planet 0755 root root - -"
  ];

  systemd.services.tilde-user-layout = {
    description = "Create private pubnix home layouts and publishing links";
    after = ["systemd-tmpfiles-setup.service"];
    before = [
      "agate.service"
      "geomyidae.service"
    ];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${tildeUserLayout}/bin/tilde-user-layout";
    };
  };

  systemd.services.tilde-members = {
    description = "Regenerate the daze.lol member directory";
    after = ["tilde-user-layout.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${tildeSiteTools}/bin/tilde-site-tools members --output /var/www/tilde/users/index.html";
    };
  };
  systemd.timers.tilde-members = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  systemd.services.tilde-planet = {
    description = "Regenerate the daze.lol planet";
    after = ["tilde-user-layout.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${tildeSiteTools}/bin/tilde-site-tools planet --output /var/www/planet";
    };
  };
  systemd.timers.tilde-planet = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  security.pam.loginLimits = [
    {
      domain = "@users";
      type = "hard";
      item = "nproc";
      value = "512";
    }
    {
      domain = "@users";
      type = "hard";
      item = "nofile";
      value = "4096";
    }
    {
      domain = "@users";
      type = "hard";
      item = "memlock";
      value = "262144";
    }
  ];
}
