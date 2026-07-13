{
  programs.plasma = {
    enable = true;
    fonts = {
      general = {
        family = "ComicShannsMono Nerd Font";
        pointSize = 10;
      };
      fixedWidth = {
        family = "ComicShannsMono Nerd Font Mono";
        pointSize = 10;
      };
      toolbar = {
        family = "ComicShannsMono Nerd Font";
        pointSize = 10;
      };
      menu = {
        family = "ComicShannsMono Nerd Font";
        pointSize = 10;
      };
      windowTitle = {
        family = "ComicShannsMono Nerd Font";
        pointSize = 10;
      };
    };
    workspace.wallpaper = "${../../../wallpapers/catppuccin-mocha.png}";
    configFile.kdeglobals.General.TerminalApplication = "ghostty";
  };
}
