{
  pkgs,
  lib,
  myceliumAddresses,
  ...
}: let
  systemctl = "${pkgs.systemd}/bin/systemctl";
in {
  imports = [
    ./hardware-configuration.nix
    ./users.nix
  ];

  # Allow the admin user to copy locally-built (unsigned) closures during
  # `nixos-rebuild --target-host` deployments.
  nix.settings = {
    trusted-users = ["root" "molly"];
    substituters = ["https://tranquil.cachix.org"];
    trusted-public-keys = [
      "tranquil.cachix.org-1:PoO+mGL6a6LcJiPakMDHN4E218/ei/7v2sxeDtNkSRg="
    ];
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Strix Halo: allocate up to 124 GiB unified memory for the iGPU.
  boot.kernelParams = [
    "amd_iommu=off"
    "amdgpu.gttsize=126976"
    "ttm.pages_limit=32505856"
    "ttm.page_pool_size=32505856"
  ];

  hardware.graphics.enable = true;

  # vsock device for spindle microVM guest-agent communication
  boot.kernelModules = ["vsock"];

  networking.hostName = "halo";
  networking.networkmanager.enable = true;

  # Resolve `misty` over Mycelium for root (borgbackup runs as root).
  networking.hosts = {
    "${myceliumAddresses.misty}" = ["misty"];
  };

  networking.wireless.enable = lib.mkForce false;
  hardware.bluetooth.enable = false;
  systemd.services.ModemManager.enable = false;

  # Clan networking connects as root; keep it key-only.
  services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [(import ../../keys.nix).molly];

  # Podman for the container-shaped services (route, pds-operator, hold). Real
  # dockerd is enabled by the tangled spindle module.
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Local system monitoring.
  services.netdata = {
    enable = true;
    config.web."bind to" = "127.0.0.1";
  };

  # Navidrome retired on halo; misty now serves music.daze.lol over Mycelium.

  systemd.tmpfiles.rules = ["d /srv/music 0755 molly users - -"];

  # Reticulum Network Stack daemon (overlay network).
  systemd.services.rnsd = {
    description = "Reticulum Network Stack Daemon";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      User = "molly";
      Group = "users";
      ExecStart = "${pkgs.rns}/bin/rnsd --config /home/molly/.reticulum";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # Persistent service state, backed up to misty by Clan borgbackup. Services
  # holding live SQLite/Postgres data are stopped for the backup and restarted
  # afterwards so the archived files are crash-consistent. Large reproducible
  # data (romm media, model weights, Docker layers, CI caches) is intentionally
  # excluded.
  clan.core.state.services = {
    folders = [
      "/var/lib/forgejo"
      "/var/lib/private/vikunja"
      "/var/lib/ratlogin"
      "/var/lib/pds-operator"
      "/var/lib/tranquil-pds"
      "/var/lib/cliproxyapi"
      "/var/lib/private/open-webui"
      "/var/lib/private/garage"
      "/var/lib/postgresql"
      "/var/lib/containers/storage/volumes/hold-data"
      "/home/molly/.reticulum"
    ];
    preBackupScript = ''
      ${systemctl} stop podman-hold podman-cli-proxy-api open-webui garage \
        pds-operator ratlogin vikunja forgejo tranquil-pds romm postgresql
    '';
    postBackupScript = ''
      ${systemctl} start postgresql romm tranquil-pds forgejo vikunja \
        ratlogin pds-operator garage podman-hold podman-cli-proxy-api open-webui
    '';
  };

  environment.systemPackages = with pkgs; [
    git
    sops
    age
    rns
    lxmf
    nomadnet
    podman
    jq
  ];

  # Nix Helper (nh) — readable rebuild diffs + scheduled cleanup.
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 5 --keep-since 7d";
    };
  };
}
