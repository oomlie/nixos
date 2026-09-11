{pkgs, ...}: {
  imports = [
    ./apps.nix
    ./emacs.nix
    ./foot.nix
    ./niri.nix
    ./noctalia.nix
    ./opencode.nix
    ./polytoken.nix
    ./qutebrowser.nix
    ./shell.nix
    ./satty.nix
    ./stylix.nix
    ./tablet.nix
  ];

  _module.args.wallpaper = ../wallpapers/wp2002041.jpg;

  home = {
    username = "mollyw";
    homeDirectory = "/home/mollyw";

    packages = with pkgs; [
      # Niri ecosystem
      xwayland-satellite
      equibop

      # Game development
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
