{
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

  # User account
  users.users.molly = {
    isNormalUser = true;
    description = "molly";
    extraGroups = ["networkmanager" "wheel" "video" "render" "docker"];
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
  ];

  # Services
  services.openssh.enable = true;

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

  system.stateVersion = "26.05";
}
