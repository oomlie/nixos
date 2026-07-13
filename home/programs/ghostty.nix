{
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
      font-family = "ComicShannsMono Nerd Font Mono";
      font-size = 11;

      cursor-style = "bar";
      window-padding-x = "4,4";
      window-inherit-working-directory = false;
      gtk-titlebar = true;

      keybind = [
        "super+u=copy_url_to_clipboard"
      ];
    };
  };
}
