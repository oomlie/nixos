{
  pkgs,
  inputs,
  ...
}: {
  imports = [./hardware-configuration.nix];

  nixpkgs.overlays = [inputs.niri.overlays.niri];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
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
    package = pkgs.niri-stable;
  };

  # XWayland support for X11 apps under niri
  programs.xwayland.enable = true;

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

  # doas alongside sudo for users in the wheel group
  security.doas = {
    enable = true;
    extraRules = [{
      groups = ["wheel"];
      keepEnv = true;
      persist = true;
    }];
  };

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

  # Agenix secrets directory
  age.secretsDir = "/run/secrets";

  # System state version
  system.stateVersion = "26.05";
}
