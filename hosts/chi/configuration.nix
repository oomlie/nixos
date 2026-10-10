{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./desktop.nix
    ./hardware-configuration.nix
  ];

  nixpkgs.overlays = [inputs.niri.overlays.niri];

  # Noctalia binary cache
  nix.settings.extra-substituters = ["https://noctalia.cachix.org"];
  nix.settings.extra-trusted-public-keys = ["noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="];

  # Use misty for x86_64-linux builds. chi and misty are on different LANs, so
  # the builder is reached over the tailnet; root logs in by key (misty has no
  # dedicated builder account) and is a trusted user there.
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "100.64.0.4";
        sshUser = "root";
        sshKey = "/home/mollyw/.ssh/mol";
        system = "x86_64-linux";
        maxJobs = 12;
        supportedFeatures = ["benchmark" "big-parallel" "kvm" "nixos-test"];
        publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSU1uK3c4bW9ObEVJeFJCMXZQTmU1QTFmK2VpUENjMjAySWpSUktOT3l6V1kgcm9vdEBtaXN0eQo=";
      }
    ];
    settings.builders-use-substitutes = true;
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = "chi";

  # Join the private Headscale tailnet (control plane on vista,
  # https://head.daze.lol). Enrolment uses a short-lived pre-auth key via
  # `tailscale up`; see TAILNET.md. DNS is not overridden.
  services.tailscale.enable = true;

  # User account
  users.users.mollyw = {
    isNormalUser = true;
    description = "Molly Wunderlich";
    shell = pkgs.zsh;
    # The input group lets the user gesture service read the internal touchscreen.
    extraGroups = ["input" "networkmanager" "wheel" "dialout"];
  };

  # Passwordless sudo is deliberate: this user administers the host and drives
  # non-interactive remote deploys (`nixos-rebuild --use-remote-sudo`). It does
  # make the account root-equivalent, so treat its SSH key accordingly.
  security.sudo.extraRules = [
    {
      users = ["mollyw"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  programs.zsh.enable = true;
  # HM's compinit in ~/.zshrc owns the fpath; skip the duplicate run in /etc/zshrc
  programs.zsh.enableGlobalCompInit = false;
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [freetype fontconfig libpng];
  };

  # Desktop integration
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
  programs.nix-index.enable = true;
  services.gvfs.enable = true;

  # Rootless Docker for mollyw; expose its user socket to normal CLI use.
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # doas alongside sudo for users in the wheel group
  security.doas = {
    enable = true;
    extraRules = [
      {
        groups = ["wheel"];
        keepEnv = true;
        persist = true;
      }
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    nix-output-monitor
    powertop
    age
    sops
    cloudflared
  ];

  # Skip default system packages (nano, perl, rsync, strace)
  environment.defaultPackages = lib.mkForce [];

  # Skip the NixOS manual (rebuilds on every config change, rarely read)
  documentation.nixos.enable = false;

  # Laptop power management (Framework 12, Intel)
  # Apply peripheral and device power-saving tunables at boot. PPD continues
  # to manage the selectable CPU energy profiles at runtime.
  powerManagement.powertop.enable = true;
  services.thermald.enable = true;
  services.fwupd.enable = true;
  # Nix Helper (nh) — readable rebuild diffs + scheduled cleanup
  programs.nh = {
    enable = true;
    flake = "/home/mollyw/nixos";
    clean = {
      enable = true;
      extraArgs = "--keep 5 --keep-since 14d";
    };
  };

  # Steam + gamemode
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
  programs.gamemode.enable = true;

  # Sunshine game streaming host (Moonlight); niri uses the Wayland capture backend.
  services.sunshine = {
    enable = true;
    openFirewall = true;
  };

  # System state version
  system.stateVersion = "26.05";
}
