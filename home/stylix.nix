{
  pkgs,
  wallpaper,
  ...
}: let
  fontPkg = pkgs.nerd-fonts.comic-shanns-mono;
  uiFont = "ComicShannsMono Nerd Font";
in {
  # Stylix auto-generated theme from wallpaper
  stylix = {
    enable = true;
    # useGlobalPkgs forbids HM-level nixpkgs.overlays; stylix's overlays only
    # patch the nixos-icons and gtksourceview packages, which are unused here
    overlays.enable = false;
    polarity = "dark";
    image = wallpaper;
    fonts = {
      serif = {
        package = fontPkg;
        name = uiFont;
      };
      sansSerif = {
        package = fontPkg;
        name = uiFont;
      };
      monospace = {
        package = fontPkg;
        name = "ComicShannsMono Nerd Font Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
    targets = {
      helix.enable = true;
      foot.enable = true;
      btop.enable = true;
      vscode.enable = true;
      firefox = {
        enable = true;
        profileNames = ["mollyw"];
      };
      niri.enable = true;
      gtk.enable = true;
    };
  };
}
