{pkgs, ...}: {
  imports = [
    ./apps.nix
    ./emacs.nix
    ./foot.nix
    ./khal.nix
    ./niri.nix
    ./noctalia.nix
    ./oh-my-pi.nix
    ./opencode.nix
    ./scripts.nix
    ./shell.nix
    ./satty.nix
    ./swayidle.nix
    ./swayosd.nix
    ./stylix.nix
    ./tablet.nix
    ./wlsunset.nix
  ];

  _module.args.wallpaper = ../wallpapers/wp2002041.jpg;

  home = {
    username = "mollyw";
    homeDirectory = "/home/mollyw";

    packages = with pkgs; [
      # Niri ecosystem
      xwayland-satellite
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
