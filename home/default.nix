{pkgs, ...}: {
  imports = [
    ./apps.nix
    ./emacs.nix
    ./foot.nix
    ./khal.nix
    ./niri.nix
    ./oh-my-pi.nix
    ./opencode.nix
    ./scripts.nix
    ./shell.nix
    ./swayidle.nix
    ./stylix.nix
    ./tablet.nix
    ./ironbar.nix
  ];

  _module.args.wallpaper = ../wallpapers/wp2002041.jpg;

  home = {
    username = "mollyw";
    homeDirectory = "/home/mollyw";

    packages = with pkgs; [
      # Niri ecosystem
      mako
      swaylock
      xwayland-satellite
      swaybg
      brightnessctl
      playerctl
      equibop

      # Network management
      networkmanagerapplet

      # Terminal calendar app
      khal

      # Game engine
      godot_4

      # RuneScape launcher
      (pkgs.callPackage ../pkgs/jagex-launcher/package.nix {})
    ];

    # stateVersion is a compatibility pin — do not change on every upgrade
    stateVersion = "26.05";

    sessionPath = ["$HOME/.bun/bin" "$HOME/.npm-global/bin"];
  };

  programs.home-manager.enable = true;
}
