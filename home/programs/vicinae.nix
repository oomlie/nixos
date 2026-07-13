{
  # App launcher + clipboard-history UI for the niri session
  programs.vicinae = {
    enable = true;
    systemd.enable = true;

    themes.catppuccin-mocha = {
      meta = {
        version = 1;
        name = "Catppuccin Mocha";
        description = "Cozy feeling with color-rich accents";
        variant = "dark";
        inherits = "vicinae-dark";
      };

      colors = {
        core = {
          background = "#1E1E2E";
          foreground = "#CDD6F4";
          secondary_background = "#181825";
          border = "#313244";
          accent = "#89B4FA";
        };
        accents = {
          blue = "#89B4FA";
          green = "#A6E3A1";
          magenta = "#F5C2E7";
          orange = "#FAB387";
          purple = "#CBA6F7";
          red = "#F38BA8";
          yellow = "#F9E2AF";
          cyan = "#94E2D5";
        };
      };
    };

    settings = {
      window.opacity = 0.85;
      theme = {
        dark.name = "catppuccin-mocha";
        light.name = "catppuccin-mocha";
      };
    };
  };
}
