{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # System configuration
  networking.hostName = "chi";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Networking
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "America/New_York";

  # Localization
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # X11 and Desktop
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = { layout = "us"; variant = ""; };

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
  users.users."mollyw" = {
    isNormalUser = true;
    description = "Molly Wunderlich";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # Add user-specific packages here
    ];
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    pkgs.proton-vpn
    pkgs.proton-pass
    pkgs.signal-desktop
    pkgs.discord
    pkgs.btop
    pkgs.protonmail-desktop
    pkgs.proton-authenticator
    pkgs.opencode
    pkgs.prismlauncher
  ];

  # Applications
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = "26.05";
}
