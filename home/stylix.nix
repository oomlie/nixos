{
  pkgs,
  wallpaper,
  ...
}: let
  fontPkg = pkgs.nerd-fonts.comic-shanns-mono;
  uiFont = "ComicShannsMono Nerd Font";
in {
  stylix = {
    enable = true;
    # useGlobalPkgs forbids HM-level nixpkgs.overlays; stylix's overlays only
    # patch the nixos-icons and gtksourceview packages, which are unused here
    overlays.enable = false;
    autoEnable = false;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
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
      sizes = {
        applications = 12;
        desktop = 10;
        popups = 10;
        terminal = 12;
      };
    };
    targets = {
      bat.enable = true;
      helix.enable = true;
      foot.enable = true;
      btop.enable = true;
      emacs.enable = true;
      fish.enable = true;
      fontconfig.enable = true;
      fzf.enable = true;
      opencode.enable = true;
      qt.enable = true;
      starship.enable = true;
      vscodium.enable = true;
      firefox = {
        enable = true;
        profileNames = ["mollyw"];
      };
      niri.enable = true;
      noctalia.enable = true;
      gtk.enable = true;
    };
  };
}
