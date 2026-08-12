{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [./hardware-configuration.nix];

  nixpkgs.overlays = [inputs.niri.overlays.niri];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = "chi";

  # Networking
  networking.networkmanager.enable = true;

  # Greetd login manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # Niri compositor
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  # Rotate the internal display from the Framework's accelerometer data.
  services.iio-niri = {
    enable = true;
    extraArgs = ["--monitor" "eDP-1"];
  };

  # XWayland support for X11 apps under niri
  programs.xwayland.enable = true;

  # Sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # User account
  users.users.mollyw = {
    isNormalUser = true;
    description = "Molly Wunderlich";
    shell = pkgs.zsh;
    # The input group lets the user gesture service read the internal touchscreen.
    extraGroups = ["input" "networkmanager" "wheel"];
  };

  programs.zsh.enable = true;
  # HM's compinit in ~/.zshrc owns the fpath; skip the duplicate run in /etc/zshrc
  programs.zsh.enableGlobalCompInit = false;
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [freetype fontconfig libpng];
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

  # XDG desktop portal for native file dialogs under Wine/Ableton
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common.default = "*";
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    proton-vpn
    proton-pass
    signal-desktop
    proton-authenticator
    prismlauncher
    nix-output-monitor
    powertop
    age
    unzip
  ];

  # Skip default system packages (nano, perl, rsync, strace)
  environment.defaultPackages = lib.mkForce [];

  # Skip the NixOS manual (rebuilds on every config change, rarely read)
  documentation.nixos.enable = false;

  # Laptop power management (Framework 12, Intel)
  services.power-profiles-daemon.enable = true;
  # Apply peripheral and device power-saving tunables at boot. PPD continues
  # to manage the selectable CPU energy profiles at runtime.
  powerManagement.powertop.enable = true;
  services.thermald.enable = true;
  services.fwupd.enable = true;
  # UPower daemon — ironbar's battery module reads battery state over zbus
  services.upower.enable = true;

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

  # System state version
  system.stateVersion = "26.05";
}
