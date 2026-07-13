{
  pkgs,
  inputs,
  ...
}: {
  imports = [./hardware-configuration.nix];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = "chi";

  # Networking
  networking.networkmanager.enable = true;

  # X11 and Desktop
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Printing
  services.printing.enable = true;

  # Sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User account
  users.users.mollyw = {
    isNormalUser = true;
    description = "Molly Wunderlich";
    shell = pkgs.zsh;
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
      # Add user-specific packages here
    ];
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    proton-vpn
    proton-pass
    signal-desktop
    protonmail-desktop
    proton-authenticator
    opencode
    prismlauncher
    nix-output-monitor
    age
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Laptop power management (Framework 12, Intel)
  services.power-profiles-daemon.enable = true;
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

  # KDE debloat — remove unused preinstalled Plasma apps
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    khelpcenter
    kate
    konsole
    krdp
    krfb
  ];

  # Agenix secrets directory
  age.secretsDir = "/run/secrets";

  # System state version
  system.stateVersion = "26.05";
}
