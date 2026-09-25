{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.tangled.nixosModules.knot
    inputs.tangled.nixosModules.spindle
  ];

  # Allow the admin user to copy locally-built (unsigned) closures during
  # `nixos-rebuild --target-host` deployments from chi.
  nix.settings = {
    trusted-users = ["root" "molly"];
    # Prebuilt tranquil-pds artifacts from upstream CI.
    substituters = ["https://tranquil.cachix.org"];
    trusted-public-keys = ["tranquil.cachix.org-1:PoO+mGL6a6LcJiPakMDHN4E218/ei/7v2sxeDtNkSRg="];
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

  # Networking
  networking.hostName = "halo";
  networking.networkmanager.enable = true;

  # Disable unused wireless/modem/bluetooth services
  networking.wireless.enable = lib.mkForce false;
  hardware.bluetooth.enable = false;
  systemd.services.ModemManager.enable = false;

  # Podman (rootless containers: deepseek-harness, cloudflared, firecrawl, etc.)
  # Real dockerd is enabled by the tangled spindle module and owns /var/run/docker.sock.
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Tangled knot (git server)
  services.tangled.knot = {
    enable = true;
    server = {
      hostname = "knot.daze.lol";
      owner = "did:plc:vtdq3y23vehztw33eohawmpz";
      listenAddr = "127.0.0.1:5555";
    };
  };

  # Tangled spindle (CI runner)
  services.tangled.spindle = {
    enable = true;
    server = {
      hostname = "spindle.daze.lol";
      owner = "did:plc:vtdq3y23vehztw33eohawmpz";
      listenAddr = "127.0.0.1:6555";
    };
  };

  # SearXNG (private metasearch; expose through the existing Cloudflare tunnel)
  services.searx = {
    enable = true;
    environmentFile = config.sops.secrets."halo/searx-env".path;
    settings = {
      general.instance_name = "daze search";
      search.formats = [
        "html"
        "json"
      ];
      server = {
        bind_address = "127.0.0.1";
        port = 3016;
        base_url = "https://search.daze.lol/";
        secret_key = "$SEARX_SECRET_KEY";
        limiter = true;
      };
    };
    redisCreateLocally = true;
    limiterSettings.botdetection = {
      trusted_proxies = [
        "127.0.0.0/8"
        "::1"
      ];
      ip_lists.pass_ip = [
        "127.0.0.0/8"
        "::1"
      ];
    };
  };

  # Netdata (local system monitoring; bound to localhost, exposed via Cloudflare)
  services.netdata = {
    enable = true;
    config.web."bind to" = "127.0.0.1";
  };

  # Gonic (Subsonic-compatible music server). Library lives in /srv/music,
  # owned by molly so tracks can be uploaded over SSH/scp. Bound to
  # localhost; add a tunnel hostname in the Cloudflare dashboard for
  # remote streaming.
  services.gonic = {
    enable = true;
    settings = {
      listen-addr = "127.0.0.1:4747";
      music-path = ["/srv/music"];
      podcast-path = "/var/lib/gonic/podcasts";
      playlists-path = "/var/lib/gonic/playlists";
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/music 0755 molly users - -"
    "d /var/lib/gonic/podcasts 0755 root root - -"
    "d /var/lib/gonic/playlists 0755 root root - -"
  ];

  # Tranquil PDS (Rust). Replaces the reference Bluesky PDS container.
  services.tranquil-pds = {
    enable = true;
    database.createLocally = true;
    environmentFiles = [config.sops.secrets."halo/tranquil-env".path];
    settings = {
      server = {
        hostname = "pds.daze.lol";
        host = "127.0.0.1";
        user_handle_domains = ["daze.lol"];
      };
      frontend.enabled = true;
    };
  };

  # User account
  users.users.molly = {
    isNormalUser = true;
    description = "molly";
    extraGroups = ["networkmanager" "wheel" "video" "render" "docker" "dialout"];
  };

  # Home Manager
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.molly = import ./home.nix;

  # Packages
  environment.systemPackages = with pkgs; [
    git
    docker-compose
    sops
    age
    rns
    lxmf
    nomadnet
  ];

  # Reticulum Network Stack daemon
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

  networking.firewall.allowedUDPPorts = [2965 29665];
  networking.firewall.allowedTCPPorts = [4242];

  # Services
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Swap (zram for OOM protection under heavy iGPU workloads)
  zramSwap.enable = true;
  zramSwap.memoryPercent = 25;

  # Sudo
  security.sudo.extraRules = [
    {
      users = ["molly"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # Nix Helper (nh) — readable rebuild diffs + scheduled cleanup
  programs.nh = {
    enable = true;
    flake = "/home/molly/nixos";
    clean = {
      enable = true;
      extraArgs = "--keep 5 --keep-since 7d";
    };
  };

  # Secrets are encrypted in this repository and materialized at activation.
  # Container Compose definitions remain outside Nix for now; the PDS pilot
  # secret will be wired into its runtime after this foundation is deployed.
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";
  sops.secrets."halo/pds-env" = {
    sopsFile = ../../secrets/halo.yaml;
    owner = "molly";
    group = "users";
    mode = "0400";
  };
  sops.secrets."halo/searx-env" = {
    sopsFile = ../../secrets/halo.yaml;
    owner = "searx";
    group = "searx";
    mode = "0400";
    restartUnits = ["searx.service"];
  };
  sops.secrets."halo/tranquil-env" = {
    sopsFile = ../../secrets/halo.yaml;
    mode = "0400";
    restartUnits = ["tranquil-pds.service"];
  };
  system.stateVersion = "26.05";
}
