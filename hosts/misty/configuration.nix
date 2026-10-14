{
  config,
  lib,
  pkgs,
  ...
}: let
  keys = import ../../keys.nix;
  alysWelcome = pkgs.writeText "alys-welcome.md" ''
    # Welcome to Misty

    Connect from your local network with:

        ssh alys@192.168.1.174

    Your files live in `/home/alys`; `nano` and `git` are installed. Misty is
    declarative NixOS, so do not edit `/etc` or `/nix/store`. System changes are
    made in the `halo-nixos` repository on an administrator workstation, checked
    with `nix fmt` and `nix flake check`, then deployed by an administrator.

    The `opencode` coding agent is installed and preconfigured with the
    route.daze.lol models. Start it with:

        opencode

    Your route.daze.lol key is available only to your account. To use the
    OpenAI-compatible API in a shell:

        export ROUTE_API_KEY="$(cat /run/secrets/alys-route-api-key)"
        export OPENAI_BASE_URL="https://route.daze.lol/v1"

    List available models with:

        curl -sS "$OPENAI_BASE_URL/models" -H "Authorization: Bearer $ROUTE_API_KEY"
  '';
in {
  imports = [
    ./hardware-configuration.nix
    ./storage.nix
    ./media.nix
    ./invidious.nix
    ./jade.nix
    ./opencode.nix
    ./jellyfin-sso.nix
    ./arr-bootstrap.nix
    ./nextcloud.nix
    ./nix-cache.nix
    ./agent-browser.nix
    ./users.nix
    ../../modules/common.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "misty";

  # Present the music library as /music in the LAN FileBrowser while keeping
  # it physically on the movies disk for the existing storage layout.
  fileSystems."/srv/music" = {
    device = "/srv/movies/media/music";
    fsType = "none";
    options = ["bind"];
  };

  # Wired DHCP on the onboard NIC; reserve this address on the router.
  networking.useNetworkd = true;
  systemd.network.networks."10-eno1" = {
    matchConfig.Name = "eno1";
    networkConfig.DHCP = "ipv4";
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  sops.secrets."filebrowser/upload-password" = {
    sopsFile = ../../secrets/misty.yaml;
    owner = "filebrowser";
    group = "media";
    mode = "0400";
    restartUnits = ["filebrowser-init.service"];
  };

  services.filebrowser = {
    enable = true;
    user = "filebrowser";
    group = "media";
    openFirewall = true;
    settings = {
      address = "0.0.0.0";
      port = 8088;
      root = "/srv";
      database = "/var/lib/filebrowser/database.db";
      auth.method = "json";
      disableExec = true;
      branding.name = "Misty Media Uploads";
    };
  };

  # FileBrowser's module creates its root as 0700 filebrowser:media, which
  # blocks the media services from traversing /srv and overrides the intended
  # 2775 root:media (filebrowser.conf sorts after 00-nixos.conf). Force the
  # media-friendly ownership on FileBrowser's own root rule.
  systemd.tmpfiles.settings.filebrowser."/srv".d = lib.mkForce {
    user = "root";
    group = "media";
    mode = "2775";
  };

  systemd.tmpfiles.rules = lib.mkAfter [
    "d /var/lib/misty-tv 0750 tv tv -"
    "L+ /home/alys/WELCOME.md - - - - ${alysWelcome}"
  ];

  # Initialize FileBrowser's local database and its LAN upload account once.
  systemd.services.filebrowser-init = {
    description = "Initialize Misty Media FileBrowser";
    before = ["filebrowser.service"];
    requiredBy = ["filebrowser.service"];
    unitConfig.ConditionPathExists = "!/var/lib/filebrowser/database.db";
    serviceConfig = {
      Type = "oneshot";
      User = "filebrowser";
      Group = "media";
      StateDirectory = "filebrowser";
    };
    script = ''
      ${pkgs.filebrowser}/bin/filebrowser config init \
        --database /var/lib/filebrowser/database.db \
        --address 0.0.0.0 \
        --port 8088 \
        --root /srv \
        --auth.method json \
        --disableExec
      ${pkgs.filebrowser}/bin/filebrowser users add upload \
        "$(cat ${config.sops.secrets."filebrowser/upload-password".path})" \
        --database /var/lib/filebrowser/database.db \
        --scope / \
        --perm.admin=false \
        --perm.execute=false \
        --perm.share=false
    '';
  };
  users.users.root.openssh.authorizedKeys.keys = [keys.molly];

  services.fail2ban = {
    enable = true;
    jails.sshd.settings = {
      enabled = true;
      maxretry = 5;
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # SSD maintenance and disk health.
  services.fstrim.enable = true;
  services.smartd.enable = true;

  hardware.graphics.enable = true;

  # Quadro K620 (Maxwell) — needs the 580 legacy driver; the default
  # 595 driver dropped Maxwell support.
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    modesetting.enable = true;
    open = false;
    nvidiaSettings = false;
  };

  # Full-screen Navidrome browser on the TV connected to DP-1.
  services.cage = {
    enable = true;
    user = "tv";
    restartIfChanged = true;
    environment = {
      WLR_BACKENDS = "drm";
      WLR_DRM_DEVICES = "/dev/dri/card1";
    };
    program = pkgs.writeShellScript "misty-tv" ''
      exec ${pkgs.chromium}/bin/chromium \
        --ozone-platform=wayland \
        --kiosk \
        --no-first-run \
        --disable-session-crashed-bubble \
        --user-data-dir=/var/lib/misty-tv \
        https://video.daze.lol
    '';
  };
  systemd.defaultUnit = "graphical.target";

  environment.systemPackages = with pkgs; [
    git
    sops
    age
    smartmontools
    nvme-cli
    htop
  ];

  nix.settings.trusted-users = ["root" "molly"];

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 5 --keep-since 7d";
    };
  };
}
