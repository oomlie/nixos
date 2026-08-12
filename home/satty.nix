{
  config,
  pkgs,
  ...
}: {
  programs.satty = {
    enable = true;
    settings = {
      general = {
        corner-roundness = 12;
        initial-tool = "brush";
        copy-command = "${pkgs.wl-clipboard}/bin/wl-copy";
        output-filename = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
        early-exit = true;
      };
      color-palette.palette = map (color: "#${color}") (with config.lib.stylix.colors; [
        base08
        base09
        base0A
        base0B
        base0C
        base0D
        base0E
      ]);
    };
  };

  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
  ];

  programs.niri.settings.binds."Mod+Print" = {
    repeat = false;
    hotkey-overlay.title = "Annotate Screenshot Region";
    action.spawn-sh = ''
      geometry="$(${pkgs.slurp}/bin/slurp)" || exit 0
      ${pkgs.grim}/bin/grim -g "$geometry" - | ${pkgs.satty}/bin/satty --filename -
    '';
  };
}
