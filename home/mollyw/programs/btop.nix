{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "catppuccin_mocha";
    };
  };

  # btop looks up color_theme by name in ~/.config/btop/themes — the theme
  # isn't shipped with btop itself, so install the official catppuccin file
  xdg.configFile."btop/themes/catppuccin_mocha.theme".source = ../themes/btop-catppuccin-mocha.theme;
}
