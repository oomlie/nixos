{pkgs, ...}: {
  programs.bat = {
    enable = true;
    config = {
      theme = "Catppuccin Mocha";
      style = "plain";
      map-syntax = [
        "*.ignore:.gitignore"
        "*.rc:ini"
        "*.conf:ini"
        "*.service:ini"
      ];
    };
    themes = {
      "Catppuccin Mocha" = {
        src = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/catppuccin/bat/6810349b28055dce54076712fc05fc68da4b8ec0/themes/Catppuccin%20Mocha.tmTheme";
          sha256 = "sha256-OVVm8IzrMBuTa5HAd2kO+U9662UbEhVT8gHJnCvUqnc=";
        };
      };
    };
  };
}
